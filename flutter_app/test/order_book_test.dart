import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/order_book.dart';

void main() {
  test('displayed order book and limit fills share one liquidity capacity', () {
    final date = DateTime(2016, 6, 20);
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 17,
      currentPrice: 10000,
      previousClose: 9800,
      date: date,
      market: '미래시장',
    );

    expect(snapshot.asks, hasLength(5));
    expect(snapshot.bids, hasLength(5));
    expect(snapshot.asks.any((level) => level.isWall), isTrue);
    expect(snapshot.bids.any((level) => level.isWall), isTrue);
    expect(
      snapshot.executionCapacity,
      gameAvailableLimitFillUnits(
        assetId: 'hanbit_telecom',
        day: 6015,
        minute: 10 * 60 + 17,
        unitPrice: 10000,
      ),
    );
    expect(snapshot.turnoverEok, greaterThan(0));
    expect(snapshot.totalAskQuantity, greaterThan(snapshot.executionCapacity));
    expect(snapshot.totalBidQuantity, greaterThan(snapshot.executionCapacity));
    expect(snapshot.tradeStrength, inInclusiveRange(20, 240));

    final preOpen = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 8 * 60,
      currentPrice: 10000,
      previousClose: 9800,
      date: date,
      market: '미래시장',
    );
    expect(preOpen.turnoverEok, 0);
    expect(preOpen.executionCapacity, 0);

    final postClose = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: krxCloseMinute,
      currentPrice: 10000,
      previousClose: 9800,
      date: date,
      market: '미래시장',
    );
    expect(postClose.turnoverEok, greaterThan(0));
    expect(postClose.executionCapacity, 0);

    final fillPlan = gameOrderBookLimitFillPlan(
      snapshot: snapshot,
      isBuy: true,
      requestedQuantity: snapshot.executionCapacity.toDouble(),
      limitPrice: snapshot.asks[1].price,
    );
    expect(fillPlan.hasFill, isTrue);
    expect(
      fillPlan.filledQuantity,
      lessThanOrEqualTo(snapshot.executionCapacity),
    );
    expect(fillPlan.averagePrice, lessThanOrEqualTo(snapshot.asks[1].price));
    expect(fillPlan.fills, isNotEmpty);

    final holiday = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60,
      currentPrice: 10000,
      previousClose: 9800,
      date: date,
      market: '미래시장',
      tradingDay: false,
    );
    expect(holiday.turnoverEok, 0);
    expect(holiday.executionCapacity, 0);
  });

  test('order-book levels obey historical daily limits and tick sizes', () {
    for (final date in [DateTime(2014, 6, 20), DateTime(2016, 6, 20)]) {
      final range = marketDailyPriceRange(
        previousClose: 10000,
        date: date,
        market: '미래시장',
      );
      final snapshot = buildGameOrderBookSnapshot(
        assetId: 'limit_fixture',
        day: date.difference(DateTime(2000)).inDays,
        minute: 14 * 60 + 45,
        currentPrice: range.upper,
        previousClose: 10000,
        date: date,
        market: '미래시장',
      );

      for (final level in [...snapshot.asks, ...snapshot.bids]) {
        expect(level.price, inInclusiveRange(range.lower, range.upper));
        expect(isValidMarketOrderPrice(level.price, market: '미래시장'), isTrue);
      }
    }
  });

  test('trade pulse moves to asks for buys and bids for sells', () {
    final buyPulse = gameOrderBookTradePulse(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 17,
      previousPrice: 10000,
      currentPrice: 10200,
      executionCapacity: 1200,
      market: '미래시장',
    );
    final sellPulse = gameOrderBookTradePulse(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 18,
      previousPrice: 10200,
      currentPrice: 9950,
      executionCapacity: 1200,
      market: '미래시장',
    );
    final flatPulse = gameOrderBookTradePulse(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 19,
      previousPrice: 10000,
      currentPrice: 10000,
      executionCapacity: 1200,
      market: '미래시장',
    );

    expect(buyPulse, isNotNull);
    expect(buyPulse!.levelSide, GameOrderBookSide.ask);
    expect(buyPulse.isBuyAggressor, isTrue);
    expect(buyPulse.levelIndex, inInclusiveRange(0, 4));
    expect(buyPulse.quantity, inInclusiveRange(1, 1200));

    expect(sellPulse, isNotNull);
    expect(sellPulse!.levelSide, GameOrderBookSide.bid);
    expect(sellPulse.isBuyAggressor, isFalse);
    expect(sellPulse.levelIndex, inInclusiveRange(0, 4));
    expect(sellPulse.quantity, inInclusiveRange(1, 1200));

    expect(flatPulse, isNotNull);
    expect(flatPulse!.levelIndex, inInclusiveRange(0, 1));
    final repeated = gameOrderBookTradePulse(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 19,
      previousPrice: 10000,
      currentPrice: 10000,
      executionCapacity: 1200,
      market: '미래시장',
    );
    expect(repeated!.levelSide, flatPulse.levelSide);
    expect(repeated.levelIndex, flatPulse.levelIndex);
    expect(repeated.quantity, flatPulse.quantity);

    expect(
      gameOrderBookTradePulse(
        assetId: 'hanbit_telecom',
        day: 6015,
        minute: 8 * 60,
        previousPrice: 10000,
        currentPrice: 10000,
        executionCapacity: 0,
        market: '미래시장',
      ),
      isNull,
    );
  });
}
