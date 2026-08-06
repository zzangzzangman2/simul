import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/casino_state.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/weekday_activity.dart';

GameState _nationalCasinoState(
  GameEngine engine, {
  String seed = 'casino-engine-test',
}) {
  final day = DateTime(2000, 1, 3).difference(DateTime(2000, 1, 1)).inDays + 1;
  final state = engine
      .createNewGame('카지노 엔진 테스트', initialCash: 10000000, worldSeed: seed)
      .copyWith(day: day, marketMinute: krxCloseMinute, decisions: const []);
  return engine.exchangeCasinoChips(state, 1000000).state;
}

void main() {
  const engine = GameEngine();

  test('national fee is 20 percent of confirmed profit only', () {
    expect(casinoNationalFee(grossPayout: 20000, stake: 10000), 2000);
    expect(casinoNationalFee(grossPayout: 10000, stake: 10000), 0);
    expect(casinoNationalFee(grossPayout: 0, stake: 10000), 0);
  });

  test('casino stake presets use 2 to 30 percent of owned chips', () {
    expect(casinoStakeForChipPercent(100000, 2), 2000);
    expect(casinoStakeForChipPercent(100000, 5), 5000);
    expect(casinoStakeForChipPercent(100000, 10), 10000);
    expect(casinoStakeForChipPercent(100000, 30), 30000);
    expect(casinoMaximumStakeForChips(100000), 30000);
    expect(isValidCasinoChipStake(30000, 100000), isTrue);
    expect(isValidCasinoChipStake(30500, 100000), isFalse);
    expect(isValidCasinoChipStake(1250, 100000), isFalse);
  });

  test('cash is exchanged into persistent casino chips and cashed out', () {
    final day =
        DateTime(2000, 1, 3).difference(DateTime(2000, 1, 1)).inDays + 1;
    final state = engine
        .createNewGame(
          '카지노 칩 테스트',
          initialCash: 1000000,
          worldSeed: 'casino-chip-wallet',
        )
        .copyWith(day: day, marketMinute: krxCloseMinute, decisions: const []);

    final exchanged = engine.exchangeCasinoChips(state, 100000);
    expect(exchanged.success, isTrue);
    expect(exchanged.state.availableBrokerageCash, 900000);
    expect(exchanged.state.bankCash, 0);
    expect(exchanged.state.personalFinance.casino.chipBalance, 100000);
    expect(
      GameState.fromJson(
        exchanged.state.toJson(),
      ).personalFinance.casino.chipBalance,
      100000,
    );
    final keptForNextDay = engine.advanceOneDay(
      exchanged.state.copyWith(marketMinute: marketDayEndMinute),
    );
    expect(keptForNextDay.personalFinance.casino.chipBalance, 100000);

    final cashedOut = engine.cashOutCasinoChips(exchanged.state);
    expect(cashedOut.success, isTrue);
    expect(cashedOut.state.availableBrokerageCash, 1000000);
    expect(cashedOut.state.bankCash, 0);
    expect(cashedOut.state.personalFinance.casino.chipBalance, 0);
    expect(cashedOut.state.ledger.last.counterAccount, 'casino_chips');
  });

  test('classic three-reel paytable has a 97.22 percent theoretical RTP', () {
    var payoutSum = 0;
    for (var first = 0; first < casinoSlotSymbols.length; first++) {
      for (var second = 0; second < casinoSlotSymbols.length; second++) {
        for (var third = 0; third < casinoSlotSymbols.length; third++) {
          payoutSum += casinoSlotPayoutMultiplier([first, second, third]);
        }
      }
    }
    final combinations =
        casinoSlotSymbols.length *
        casinoSlotSymbols.length *
        casinoSlotSymbols.length;
    expect(payoutSum / combinations, casinoSlotsTheoreticalRtp);
    expect(casinoSlotsTheoreticalRtp * 100, closeTo(97.22, 0.01));
  });

  test('casino is online from 2000, afternoon-only, and deterministic', () {
    final online = _nationalCasinoState(engine);
    final early = online.copyWith(marketMinute: krxCloseMinute - 1);
    const bet = CasinoBet(
      game: CasinoGameType.baccarat,
      type: CasinoBetType.baccaratPlayer,
      stake: 10000,
    );

    final locked = engine.playCasinoRound(early, bet);
    final first = engine.playCasinoRound(online, bet);
    final replay = engine.playCasinoRound(online, bet);

    expect(locked.success, isFalse);
    expect(locked.message, contains('15:00'));
    expect(first.success, isTrue);
    expect(first.minutesElapsed, casinoRoundMinutes);
    expect(first.state.personalFinance.casino.totalRounds, 1);
    expect(first.state.personalFinance.casino.history, hasLength(1));
    expect(first.state.ledger.last.sourceId, contains('casino-'));
    expect(replay.state.toJson(), first.state.toJson());
  });

  test('casino is one weekday evening action with 30-minute rounds', () {
    final monday = _nationalCasinoState(engine, seed: 'casino-evening-action');
    const spin = CasinoBet(
      game: CasinoGameType.slots,
      type: CasinoBetType.slotsSpin,
      stake: 10000,
    );

    final saturday = monday.copyWith(day: monday.day + 5);
    final weekendAttempt = engine.playCasinoRound(saturday, spin);
    expect(weekendAttempt.success, isFalse);
    expect(weekendAttempt.message, contains('평일'));

    final tooLate = monday.copyWith(marketMinute: 19 * 60 + 31);
    final lateAttempt = engine.playCasinoRound(tooLate, spin);
    expect(lateAttempt.success, isFalse);
    expect(lateAttempt.message, contains('19:30'));

    final lastStart = monday.copyWith(marketMinute: 19 * 60 + 30);
    final lastRound = engine.playCasinoRound(lastStart, spin);
    expect(lastRound.success, isTrue);
    expect(lastRound.minutesElapsed, 30);
    final atClose = lastRound.state.copyWith(
      marketMinute: advanceGameTime(
        lastStart.marketMinute,
        lastRound.minutesElapsed,
      ),
    );
    expect(atClose.marketMinute, marketDayEndMinute);
    final finished = engine.completeWeekdayActivity(atClose, 'casino');
    expect(finished.success, isTrue);
    expect(finished.endMinute, marketDayEndMinute);
    expect(weekdayActivityLogsForDay(finished.state, monday.day), hasLength(1));
    expect(
      weekdayActivityLogsForDay(finished.state, monday.day).single.activityId,
      'casino',
    );

    final noRoundExit = engine.completeWeekdayActivity(monday, 'casino');
    expect(noRoundExit.success, isTrue);
    expect(noRoundExit.state.marketMinute, marketDayEndMinute);
    expect(weekdayEveningUsed(noRoundExit.state), isTrue);

    final bankEvening = engine.completeWeekdayActivity(monday, 'bank');
    expect(bankEvening.success, isTrue);
    final casinoAfterBank = engine.playCasinoRound(bankEvening.state, spin);
    expect(casinoAfterBank.success, isFalse);
    expect(casinoAfterBank.message, contains('저녁 행동'));

    final firstRound = engine.playCasinoRound(monday, spin);
    expect(firstRound.success, isTrue);
    final bankAfterCasino = engine.completeWeekdayActivity(
      firstRound.state,
      'bank',
    );
    expect(bankAfterCasino.success, isFalse);
    expect(bankAfterCasino.message, contains('카지노'));
  });

  test('casino outcome does not reroll when the bet side changes', () {
    final state = _nationalCasinoState(engine, seed: 'bet-independent-outcome');
    final player = engine.playCasinoRound(
      state,
      const CasinoBet(
        game: CasinoGameType.baccarat,
        type: CasinoBetType.baccaratPlayer,
        stake: 10000,
      ),
    );
    final banker = engine.playCasinoRound(
      state,
      const CasinoBet(
        game: CasinoGameType.baccarat,
        type: CasinoBetType.baccaratBanker,
        stake: 50000,
      ),
    );

    expect(player.success, isTrue);
    expect(banker.success, isTrue);
    expect(
      player.state.personalFinance.casino.history.single.detail,
      banker.state.personalFinance.casino.history.single.detail,
    );
  });

  test('engine rejects a wager above 30 percent of owned chips', () {
    final state = _nationalCasinoState(engine, seed: 'casino-chip-cap');
    final result = engine.playCasinoRound(
      state,
      const CasinoBet(
        game: CasinoGameType.roulette,
        type: CasinoBetType.rouletteRed,
        stake: 300500,
      ),
    );

    expect(result.success, isFalse);
    expect(result.message, contains('보유 칩의 30%'));
    expect(
      result.state.personalFinance.casino.chipBalance,
      state.personalFinance.casino.chipBalance,
    );
  });

  test(
    'winning round separates gross payout, national fee, and net receipt',
    () {
      CasinoActionResult? winning;
      GameState? winningBefore;
      for (var index = 0; index < 200; index++) {
        final before = _nationalCasinoState(engine, seed: 'casino-fee-$index');
        final result = engine.playCasinoRound(
          before,
          const CasinoBet(
            game: CasinoGameType.roulette,
            type: CasinoBetType.rouletteRed,
            stake: 10000,
          ),
        );
        if (result.state.personalFinance.casino.history.single.nationalFee >
            0) {
          winning = result;
          winningBefore = before;
          break;
        }
      }

      expect(winning, isNotNull);
      final result = winning!;
      final before = winningBefore!;
      final record = result.state.personalFinance.casino.history.single;
      expect(record.grossPayout, 20000);
      expect(record.nationalFee, 2000);
      expect(record.payout, 18000);
      expect(record.net, 8000);
      expect(result.cashDelta, 8000);
      expect(
        result.state.personalFinance.casino.chipBalance,
        before.personalFinance.casino.chipBalance + 8000,
      );
      expect(result.state.cash, before.cash);
      expect(result.state.personalFinance.casino.totalNationalFee, 2000);
      expect(result.state.personalFinance.casino.monthlyNationalFee, 2000);
      expect(
        result.state.ledger
            .singleWhere((entry) => entry.counterAccount == 'casino_payout')
            .amount,
        20000,
      );
      expect(
        result.state.ledger
            .singleWhere((entry) => entry.counterAccount == 'state_casino_fee')
            .amount,
        -2000,
      );
      expect(result.message, contains('총지급 20000원'));
      expect(result.message, contains('국가 수수료 2000원'));

      final restored = GameState.fromJson(result.state.toJson());
      expect(
        restored.personalFinance.casino.history.single.toJson(),
        record.toJson(),
      );
      expect(restored.personalFinance.casino.totalNationalFee, 2000);
    },
  );

  test('daily round limit and monthly loss stop are enforced', () {
    var state = _nationalCasinoState(engine, seed: 'casino-limits');
    for (var index = 0; index < casinoDailyRoundLimit; index++) {
      final result = engine.playCasinoRound(
        state,
        const CasinoBet(
          game: CasinoGameType.slots,
          type: CasinoBetType.slotsSpin,
          stake: 10000,
        ),
      );
      expect(result.success, isTrue, reason: 'round ${index + 1}');
      state = result.state;
    }
    final dailyLocked = engine.playCasinoRound(
      state,
      const CasinoBet(
        game: CasinoGameType.slots,
        type: CasinoBetType.slotsSpin,
        stake: 10000,
      ),
    );
    expect(dailyLocked.success, isFalse);
    expect(dailyLocked.message, contains('10판'));

    final fresh = _nationalCasinoState(engine, seed: 'casino-loss-stop');
    final monthKey = casinoMonthKey(fresh.currentDate);
    final basis =
        fresh.availableBrokerageCash + fresh.personalFinance.casino.chipBalance;
    final limit = casinoMonthlyLossLimitForBasis(basis);
    final stopped = fresh.copyWith(
      personalFinance: fresh.personalFinance.copyWith(
        casino: fresh.personalFinance.casino.copyWith(
          monthKey: monthKey,
          monthBankrollBasis: basis,
          monthlyStake: limit,
          monthlyPayout: 0,
        ),
      ),
    );
    final lossLocked = engine.playCasinoRound(
      stopped,
      const CasinoBet(
        game: CasinoGameType.roulette,
        type: CasinoBetType.rouletteRed,
        stake: 10000,
      ),
    );
    expect(lossLocked.success, isFalse);
    expect(lossLocked.message, contains('손실 중단선'));
  });

  test(
    'blackjack persists the hand, settles S17, and survives JSON round-trip',
    () {
      final state = _nationalCasinoState(engine, seed: 'blackjack-persist');
      final deal = engine.startCasinoBlackjack(state, 10000);

      expect(deal.success, isTrue);
      expect(deal.minutesElapsed, 0);
      expect(deal.state.personalFinance.casino.activeBlackjack, isNotNull);
      final restored = GameState.fromJson(deal.state.toJson());
      expect(
        restored.personalFinance.casino.activeBlackjack!.toJson(),
        deal.state.personalFinance.casino.activeBlackjack!.toJson(),
      );

      final settled = engine.actCasinoBlackjack(
        restored,
        BlackjackAction.stand,
      );
      expect(settled.success, isTrue);
      expect(settled.minutesElapsed, casinoRoundMinutes);
      expect(settled.state.personalFinance.casino.activeBlackjack, isNull);
      expect(
        settled.state.personalFinance.casino.history.single.game,
        CasinoGameType.blackjack,
      );
      expect(
        settled.state.personalFinance.casino.history.single.detail,
        contains('딜러'),
      );
    },
  );

  test(
    'craps persists its point and spends 30 minutes only when the contract settles',
    () {
      CasinoActionResult? pointStart;
      for (var index = 0; index < 200; index++) {
        final state = _nationalCasinoState(engine, seed: 'craps-point-$index');
        final result = engine.playCasinoRound(
          state,
          const CasinoBet(
            game: CasinoGameType.craps,
            type: CasinoBetType.crapsPassLine,
            stake: 10000,
          ),
        );
        if (result.state.personalFinance.casino.activeCraps != null) {
          pointStart = result;
          break;
        }
      }

      expect(pointStart, isNotNull);
      final started = pointStart!;
      expect(started.success, isTrue);
      expect(started.minutesElapsed, 0);
      expect(started.state.personalFinance.casino.totalRounds, 1);
      expect(started.state.personalFinance.casino.history, isEmpty);
      final active = started.state.personalFinance.casino.activeCraps!;
      expect(<int>{4, 5, 6, 8, 9, 10}, contains(active.point));
      expect(active.rolls, hasLength(1));

      final restored = GameState.fromJson(started.state.toJson());
      expect(
        restored.personalFinance.casino.activeCraps!.toJson(),
        active.toJson(),
      );

      final otherGame = engine.playCasinoRound(
        restored,
        const CasinoBet(
          game: CasinoGameType.roulette,
          type: CasinoBetType.rouletteRed,
          stake: 10000,
        ),
      );
      expect(otherGame.success, isFalse);
      expect(otherGame.message, contains('크랩스 포인트'));

      GameState settle(GameState initial) {
        var current = initial;
        for (var rollIndex = 0; rollIndex < 100; rollIndex++) {
          final result = engine.rollCasinoCraps(current);
          expect(result.success, isTrue);
          current = result.state;
          if (current.personalFinance.casino.activeCraps == null) {
            expect(result.minutesElapsed, casinoRoundMinutes);
            return current;
          }
          expect(result.minutesElapsed, 0);
        }
        fail('크랩스 포인트가 100회 안에 정산되지 않음');
      }

      final firstSettlement = settle(restored);
      final replaySettlement = settle(restored);
      expect(firstSettlement.toJson(), replaySettlement.toJson());
      final record = firstSettlement.personalFinance.casino.history.single;
      expect(record.game, CasinoGameType.craps);
      expect(record.detail, contains('포인트 ${active.point}'));
      expect(firstSettlement.personalFinance.casino.totalRounds, 1);
      expect(
        record.nationalFee,
        casinoNationalFee(grossPayout: record.grossPayout, stake: record.stake),
      );
    },
  );

  test("craps Don't Pass treats come-out 12 as a fee-free push", () {
    CasinoActionResult? push;
    GameState? before;
    for (var index = 0; index < 500; index++) {
      final state = _nationalCasinoState(
        engine,
        seed: 'craps-bar-twelve-$index',
      );
      final result = engine.playCasinoRound(
        state,
        const CasinoBet(
          game: CasinoGameType.craps,
          type: CasinoBetType.crapsDontPass,
          stake: 10000,
        ),
      );
      if (result.state.personalFinance.casino.history.isNotEmpty &&
          result.state.personalFinance.casino.history.single.outcome.contains(
            '12',
          )) {
        push = result;
        before = state;
        break;
      }
    }

    expect(push, isNotNull);
    final record = push!.state.personalFinance.casino.history.single;
    expect(record.outcome, contains('푸시'));
    expect(record.grossPayout, 10000);
    expect(record.payout, 10000);
    expect(record.nationalFee, 0);
    expect(push.state.cash, before!.cash);
    expect(push.minutesElapsed, casinoRoundMinutes);
  });

  test('unfinished blackjack is forfeited when the day advances', () {
    final state = _nationalCasinoState(engine, seed: 'blackjack-day-boundary');
    final deal = engine.startCasinoBlackjack(state, 10000);
    final closing = deal.state.copyWith(marketMinute: marketDayEndMinute);

    final next = engine.advanceOneDay(closing);

    expect(next.day, closing.day + 1);
    expect(next.personalFinance.casino.activeBlackjack, isNull);
    expect(next.personalFinance.casino.history.last.outcome, contains('몰수'));
  });

  test('unfinished craps point is forfeited when the day advances', () {
    CasinoActionResult? pointStart;
    for (var index = 0; index < 200; index++) {
      final state = _nationalCasinoState(engine, seed: 'craps-forfeit-$index');
      final result = engine.playCasinoRound(
        state,
        const CasinoBet(
          game: CasinoGameType.craps,
          type: CasinoBetType.crapsPassLine,
          stake: 10000,
        ),
      );
      if (result.state.personalFinance.casino.activeCraps != null) {
        pointStart = result;
        break;
      }
    }
    expect(pointStart, isNotNull);
    final closing = pointStart!.state.copyWith(
      marketMinute: marketDayEndMinute,
    );

    final next = engine.advanceOneDay(closing);

    expect(next.day, closing.day + 1);
    expect(next.personalFinance.casino.activeCraps, isNull);
    expect(next.personalFinance.casino.history.last.game, CasinoGameType.craps);
    expect(next.personalFinance.casino.history.last.outcome, contains('몰수'));
  });
}
