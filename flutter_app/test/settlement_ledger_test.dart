import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/main.dart';

/// The settlement cycle is derived from the ledger rather than stored as a
/// separate settled/unsettled flag.
///
/// That is the whole double-settlement defence: there is no flag to apply
/// twice, so a save restore, a partial fill, or a cancelled order can only
/// change the ledger rows themselves. These tests pin that property together
/// with the buy leg and the unsettled share counts.
void main() {
  const engine = GameEngine();

  GameState stateWith(List<LedgerEntry> ledger, {required int day}) {
    final base = engine.createNewGame('결제 원장', worldSeed: 'settlement-test');
    return base.copyWith(day: day, ledger: ledger);
  }

  LedgerEntry trade({
    required String id,
    required int day,
    required String side,
    required int amount,
    String assetId = 'hanbit_telecom',
    double quantity = 10,
  }) => LedgerEntry(
    id: id,
    day: day,
    amount: amount,
    account: 'brokerage_cash',
    counterAccount: 'market_security',
    description: '$side 체결',
    sourceId: id,
    assetId: assetId,
    tradeSide: side,
    tradeQuantity: quantity,
    tradeUnitPrice: 6000,
  );

  group('settlement cycle', () {
    test('the campaign settles on D+2 trading days', () {
      for (final date in <DateTime>[
        DateTime(2000, 1, 4),
        DateTime(2008, 10, 27),
        DateTime(2026, 6, 15),
      ]) {
        expect(marketSettlementTradingDays(date), 2);
      }
    });

    test('weekends and holidays push the settlement date out', () {
      // Thursday 2026-06-11 settles on Monday 2026-06-15.
      final thursday = DateTime(2026, 6, 11);
      expect(isMarketTradingDay(thursday), isTrue);
      expect(marketSettlementDateFor(thursday), DateTime(2026, 6, 15));

      // A fill straddling a fixed holiday skips it.
      final beforeLiberation = DateTime(2025, 8, 13);
      final settled = marketSettlementDateFor(beforeLiberation);
      expect(isMarketTradingDay(settled), isTrue);
      expect(settled.isAfter(DateTime(2025, 8, 14)), isTrue);
    });

    test('the settlement date only counts trading days', () {
      final settled = marketSettlementDateFor(DateTime(2026, 6, 15));
      var tradingDays = 0;
      var cursor = DateTime(2026, 6, 15);
      while (cursor.isBefore(settled)) {
        cursor = cursor.add(const Duration(days: 1));
        if (isMarketTradingDay(cursor)) tradingDays += 1;
      }
      expect(tradingDays, marketSettlementTradingDays(DateTime(2026, 6, 15)));
    });
  });

  group('pending settlement covers both legs', () {
    test('a fresh buy reports its consideration and shares', () {
      final state = stateWith([
        trade(id: 'buy-1', day: 4, side: 'buy', amount: -60150, quantity: 10),
      ], day: 4);

      expect(state.unsettledBrokerageBuyPayments, 60150);
      expect(state.unsettledBuyUnits('hanbit_telecom'), 10);
      expect(state.unsettledSellUnits('hanbit_telecom'), 0);
      expect(state.assetsAwaitingSettlement, {'hanbit_telecom'});
    });

    test('a fresh sell reports proceeds and blocks withdrawal only', () {
      final state = stateWith([
        trade(id: 'sell-1', day: 4, side: 'sell', amount: 59700, quantity: 10),
      ], day: 4);

      expect(state.unsettledBrokerageSellProceeds, 59700);
      expect(state.unsettledSellUnits('hanbit_telecom'), 10);
      expect(state.unsettledBrokerageBuyPayments, 0);
      // Sell proceeds stay usable for another order.
      expect(state.availableBrokerageCash, state.brokerageCash);
      expect(
        state.withdrawableBrokerageCash,
        state.brokerageCash - 59700 < 0 ? 0 : state.brokerageCash - 59700,
      );
    });

    test('an unsettled buy never reduces buying power twice', () {
      // The cash already left the account at fill time, so reporting the
      // pending buy must not subtract it again.
      final state = stateWith([
        trade(id: 'buy-1', day: 4, side: 'buy', amount: -60150, quantity: 10),
      ], day: 4);

      expect(state.availableBrokerageCash, state.brokerageCash);
      expect(state.withdrawableBrokerageCash, state.brokerageCash);
    });

    test('legs from different assets stay separate', () {
      final state = stateWith([
        trade(id: 'buy-1', day: 4, side: 'buy', amount: -60150, quantity: 10),
        trade(
          id: 'buy-2',
          day: 4,
          side: 'buy',
          amount: -20000,
          assetId: 'mirae_semiconductor',
          quantity: 4,
        ),
      ], day: 4);

      expect(state.unsettledBuyUnits('hanbit_telecom'), 10);
      expect(state.unsettledBuyUnits('mirae_semiconductor'), 4);
      expect(state.unsettledBrokerageBuyPayments, 80150);
      expect(state.assetsAwaitingSettlement, {
        'hanbit_telecom',
        'mirae_semiconductor',
      });
    });
  });

  group('day rollover clears settled rows in order', () {
    test('a leg drops out exactly on its settlement date', () {
      final ledger = [
        trade(id: 'buy-1', day: 4, side: 'buy', amount: -60150, quantity: 10),
      ];
      final tradeDate = stateWith(ledger, day: 4).dateForDay(4);
      final settlesOn = marketSettlementDateFor(tradeDate);

      var day = 4;
      while (true) {
        final state = stateWith(ledger, day: day);
        if (!state.currentDate.isBefore(settlesOn)) {
          expect(state.unsettledBrokerageBuyPayments, 0);
          expect(state.unsettledBuyUnits('hanbit_telecom'), 0);
          expect(state.assetsAwaitingSettlement, isEmpty);
          break;
        }
        expect(state.unsettledBrokerageBuyPayments, 60150);
        day += 1;
        expect(day, lessThan(20), reason: '결제일이 지나도 미결제가 남으면 안 됩니다.');
      }
    });

    test('older legs settle before newer ones', () {
      final ledger = [
        trade(id: 'buy-old', day: 4, side: 'buy', amount: -10000, quantity: 1),
        trade(id: 'buy-new', day: 8, side: 'buy', amount: -20000, quantity: 2),
      ];
      // Far enough for the day 4 leg to settle but not the day 8 leg.
      final state = stateWith(ledger, day: 8);
      expect(state.unsettledBrokerageBuyPayments, 20000);
      expect(state.unsettledBuyUnits('hanbit_telecom'), 2);
    });

    test('a delisted asset still ages out of the cycle', () {
      // Delisting removes the position, not the ledger history. The pending
      // leg must not linger forever just because the asset is gone.
      final ledger = [
        trade(
          id: 'sell-delisted',
          day: 4,
          side: 'sell',
          amount: 5000,
          assetId: 'delisted_co',
          quantity: 3,
        ),
      ];
      expect(stateWith(ledger, day: 4).unsettledSellUnits('delisted_co'), 3);
      expect(stateWith(ledger, day: 12).unsettledSellUnits('delisted_co'), 0);
      expect(stateWith(ledger, day: 12).assetsAwaitingSettlement, isEmpty);
    });

    test('a future-dated row is not counted before its fill day', () {
      final state = stateWith([
        trade(id: 'buy-future', day: 9, side: 'buy', amount: -1000),
      ], day: 4);
      expect(state.unsettledBrokerageBuyPayments, 0);
      expect(state.assetsAwaitingSettlement, isEmpty);
    });
  });

  group('no double settlement', () {
    test('a save round trip reproduces the same pending state', () {
      final state = stateWith([
        trade(id: 'buy-1', day: 4, side: 'buy', amount: -60150, quantity: 10),
        trade(id: 'sell-1', day: 4, side: 'sell', amount: 30000, quantity: 5),
      ], day: 4);

      final restored = GameState.fromJson(state.toJson());
      expect(
        restored.unsettledBrokerageBuyPayments,
        state.unsettledBrokerageBuyPayments,
      );
      expect(
        restored.unsettledBrokerageSellProceeds,
        state.unsettledBrokerageSellProceeds,
      );
      expect(
        restored.unsettledBuyUnits('hanbit_telecom'),
        state.unsettledBuyUnits('hanbit_telecom'),
      );
      expect(
        restored.unsettledSellUnits('hanbit_telecom'),
        state.unsettledSellUnits('hanbit_telecom'),
      );
      expect(
        restored.withdrawableBrokerageCash,
        state.withdrawableBrokerageCash,
      );
    });

    test('partial fills add up to the whole order exactly once', () {
      final whole = stateWith([
        trade(
          id: 'buy-whole',
          day: 4,
          side: 'buy',
          amount: -60000,
          quantity: 10,
        ),
      ], day: 4);
      final split = stateWith([
        trade(
          id: 'buy-part-1',
          day: 4,
          side: 'buy',
          amount: -24000,
          quantity: 4,
        ),
        trade(
          id: 'buy-part-2',
          day: 4,
          side: 'buy',
          amount: -36000,
          quantity: 6,
        ),
      ], day: 4);

      expect(
        split.unsettledBrokerageBuyPayments,
        whole.unsettledBrokerageBuyPayments,
      );
      expect(
        split.unsettledBuyUnits('hanbit_telecom'),
        whole.unsettledBuyUnits('hanbit_telecom'),
      );
    });

    test('reading the state repeatedly never accumulates', () {
      final state = stateWith([
        trade(id: 'buy-1', day: 4, side: 'buy', amount: -60150, quantity: 10),
      ], day: 4);

      final first = state.unsettledBrokerageBuyPayments;
      for (var i = 0; i < 5; i++) {
        expect(state.unsettledBrokerageBuyPayments, first);
        expect(state.unsettledBuyUnits('hanbit_telecom'), 10);
      }
    });

    test('an order with no fill contributes nothing', () {
      // A cancelled or expired order writes no trade row, so the settlement
      // view stays empty even while the order object existed.
      final state = stateWith(const <LedgerEntry>[], day: 4);
      expect(state.unsettledBrokerageBuyPayments, 0);
      expect(state.unsettledBrokerageSellProceeds, 0);
      expect(state.assetsAwaitingSettlement, isEmpty);
    });

    test('the account line adds the buy leg without hiding the cost line', () {
      final both = stateWith([
        trade(id: 'buy-1', day: 4, side: 'buy', amount: -60150, quantity: 10),
        trade(id: 'sell-1', day: 4, side: 'sell', amount: 30000, quantity: 5),
      ], day: 4);
      final line = marketAccountSettlementSummary(both, 1234);
      expect(line, contains('T+2 결제예정 매도대금'));
      expect(line, contains('매수'));
      expect(line, contains('출금 가능'));

      final sellOnly = stateWith([
        trade(id: 'sell-1', day: 4, side: 'sell', amount: 30000, quantity: 5),
      ], day: 4);
      final sellLine = marketAccountSettlementSummary(sellOnly, 1234);
      expect(sellLine, contains('T+2 결제예정 매도대금'));
      expect(sellLine, isNot(contains('매수')));

      // A buy alone keeps the running cost line: its cash already left at fill
      // time, so promoting it would hide a useful line for two trading days.
      final buyOnly = stateWith([
        trade(id: 'buy-1', day: 4, side: 'buy', amount: -60150, quantity: 10),
      ], day: 4);
      expect(buyOnly.unsettledBrokerageBuyPayments, 60150);
      expect(
        marketAccountSettlementSummary(buyOnly, 1234),
        contains('누적 거래비용'),
      );

      final quiet = stateWith(const <LedgerEntry>[], day: 4);
      expect(marketAccountSettlementSummary(quiet, 1234), contains('누적 거래비용'));
    });

    test('non-trade cash rows are never treated as settlement legs', () {
      final state = stateWith([
        LedgerEntry(
          id: 'transfer-1',
          day: 4,
          amount: -50000,
          account: 'brokerage_cash',
          counterAccount: 'bank_cash',
          description: '증권계좌 이체',
          sourceId: 'transfer-1',
        ),
      ], day: 4);

      expect(state.unsettledBrokerageBuyPayments, 0);
      expect(state.unsettledBrokerageSellProceeds, 0);
      expect(state.assetsAwaitingSettlement, isEmpty);
    });
  });
}
