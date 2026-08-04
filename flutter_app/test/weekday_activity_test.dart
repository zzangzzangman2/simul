import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/story_state.dart';
import 'package:millennium_capital/game/weekday_activity.dart';

void main() {
  const engine = GameEngine();

  test('real-estate entry uses the remaining weekday evening', () {
    final state = engine
        .createNewGame('평일 저녁 테스트', worldSeed: 'weekday-evening')
        .copyWith(day: 3, marketMinute: 15 * 60 + 30, decisions: const []);

    final result = engine.completeWeekdayActivity(state, 'real_estate');

    expect(result.success, isTrue);
    expect(result.state.marketMinute, marketDayEndMinute);
    expect(result.state.progression.experience, state.progression.experience);
    expect(
      result.state.progression.counter(weekdayActivityCounterMetric),
      state.progression.counter(weekdayActivityCounterMetric) + 1,
    );
    final log = weekdayActivityLogsForDay(
      result.state,
      result.state.day,
    ).single;
    expect(log.activityId, 'real_estate');
    expect(log.startMinute, 15 * 60 + 30);
    expect(log.endMinute, marketDayEndMinute);
    expect(result.message, contains('15:30 → 20:00'));
  });

  test('bank and real-estate entry are blocked before the market closes', () {
    final state = engine
        .createNewGame('장중 차단 테스트', worldSeed: 'weekday-market-hours')
        .copyWith(day: 3, marketMinute: 14 * 60 + 59, decisions: const []);

    final bank = engine.completeWeekdayActivity(state, 'bank');
    final realEstate = engine.completeWeekdayActivity(state, 'real_estate');

    expect(bank.success, isFalse);
    expect(realEstate.success, isFalse);
    expect(bank.message, contains('15:00까지는 주식장'));
    expect(bank.state.marketMinute, 14 * 60 + 59);
  });

  test(
    'only one practical evening destination can be selected each weekday',
    () {
      final state = engine
          .createNewGame('저녁 양자택일 테스트', worldSeed: 'weekday-one-choice')
          .copyWith(day: 3, marketMinute: krxCloseMinute, decisions: const []);

      final first = engine.completeWeekdayActivity(state, 'bank');
      final second = engine.completeWeekdayActivity(first.state, 'real_estate');

      expect(first.success, isTrue);
      expect(second.success, isFalse);
      expect(
        weekdayActivityLogsForDay(first.state, first.state.day),
        hasLength(1),
      );
    },
  );

  test('weekday evening selection is rejected on weekends', () {
    final state = engine
        .createNewGame('주말 거절 테스트', worldSeed: 'weekday-weekend')
        .copyWith(marketMinute: krxCloseMinute, decisions: const []);

    final result = engine.completeWeekdayActivity(state, 'bank');

    expect(result.success, isFalse);
    expect(result.message, contains('월요일부터 금요일'));
  });

  test(
    'guidance keeps weekdays on stocks until close then offers two choices',
    () {
      final base = engine
          .createNewGame('일정 안내 테스트', worldSeed: 'weekday-guidance')
          .copyWith(day: 3, decisions: const []);

      expect(
        gameDayGuidanceForState(base.copyWith(marketMinute: 8 * 60)).phaseLabel,
        contains('09:00'),
      );
      expect(
        gameDayGuidanceForState(
          base.copyWith(marketMinute: 10 * 60),
        ).phaseLabel,
        contains('14:50'),
      );
      expect(
        gameDayGuidanceForState(
          base.copyWith(marketMinute: 14 * 60 + 55),
        ).phaseLabel,
        contains('15:00'),
      );
      expect(
        gameDayGuidanceForState(
          base.copyWith(marketMinute: krxCloseMinute),
        ).title,
        contains('부동산 또는 은행'),
      );
      final finished = engine.completeWeekdayActivity(
        base.copyWith(marketMinute: krxCloseMinute),
        'bank',
      );
      expect(gameDayGuidanceForState(finished.state).actionLabel, '하루 마무리');
    },
  );

  test(
    'new Decimal story unlocks bank first and realtor after a bank visit',
    () {
      final story = StoryState.newDecimalPlayer(
        playerName: '민재',
        introChoice: 'stocks',
        startingTrait: StoryTrait.analysis,
        operatingPrinciple: OperatingPrinciple.reportLosses,
      );
      final initial = engine
          .createNewGame(
            '시설 해금 테스트',
            story: story,
            worldSeed: 'facility-story-gates',
          )
          .copyWith(day: 3, marketMinute: krxOpenMinute);

      expect(bankAccessUnlocked(initial), isFalse);
      expect(realEstateAccessUnlocked(initial), isFalse);

      final afterTutorial = engine.completeInitialPracticeDay(initial);
      expect(
        afterTutorial.pendingDecisions.single.id,
        'facility-intro-bank-yoon-harin',
      );

      final bankIntroduced = engine.resolveDecision(
        afterTutorial,
        'facility-intro-bank-yoon-harin',
        'meet_bank_clerk_deposit',
      );
      expect(bankAccessUnlocked(bankIntroduced), isTrue);
      expect(realEstateAccessUnlocked(bankIntroduced), isFalse);
      expect(
        bankIntroduced.story.seenStoryEventIds,
        contains('BANK_CLERK_YOON_HARIN_INTRODUCED'),
      );

      final bankEvening = engine.completeWeekdayActivity(
        bankIntroduced.copyWith(marketMinute: krxCloseMinute),
        'bank',
      );
      expect(bankEvening.success, isTrue);

      final nextDay = engine.advanceOneDay(bankEvening.state);
      expect(
        nextDay.pendingDecisions.single.id,
        'facility-intro-realtor-seo-haneul',
      );

      final realtorIntroduced = engine.resolveDecision(
        nextDay,
        'facility-intro-realtor-seo-haneul',
        'meet_realtor_cashflow',
      );
      expect(realEstateAccessUnlocked(realtorIntroduced), isTrue);
      expect(
        realtorIntroduced.story.seenStoryEventIds,
        contains('REALTOR_SEO_HANEUL_INTRODUCED'),
      );
    },
  );
}
