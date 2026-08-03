import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/life_calendar.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/relationship_state.dart';
import 'package:millennium_capital/game/weekend_activity.dart';

void main() {
  const engine = GameEngine();

  GameState weekendState(String seed) {
    final base = engine.createNewGame('주말 시스템 테스트', worldSeed: seed);
    var weekendDay = base.day;
    while (base.dateForDay(weekendDay).weekday != DateTime.saturday) {
      weekendDay += 1;
    }
    return base.copyWith(
      day: weekendDay,
      cash: base.cash + 5000,
      marketMinute: marketDayStartMinute,
    );
  }

  test('two activities spend the weekend budget and a third is rejected', () {
    final state = weekendState('weekend-two-points');
    final first = engine.completeWeekendActivity(
      state,
      const WeekendActivityRequest(activityId: 'restaurant_dishes'),
    );
    final second = engine.completeWeekendActivity(
      first.state,
      const WeekendActivityRequest(activityId: 'stationery_stock'),
    );
    final blocked = engine.completeWeekendActivity(
      second.state,
      const WeekendActivityRequest(activityId: 'market_study'),
    );

    expect(first.success, isTrue);
    expect(second.success, isTrue);
    expect(weekendActivityPointsRemaining(second.state), 0);
    expect(
      weekendActivityLogsForDay(second.state, second.state.day),
      hasLength(2),
    );
    expect(blocked.success, isFalse);
  });

  test('preferred gift spends living cash and becomes a calendar record', () {
    final state = weekendState('weekend-preferred-gift');
    final before = state.relationships.progressFor('han_sua');
    final result = engine.completeWeekendActivity(
      state,
      const WeekendActivityRequest(
        activityId: 'gift',
        girlId: 'han_sua',
        giftId: 'winter_snack_box',
      ),
    );
    final after = result.state.relationships.progressFor('han_sua');
    final event = lifeCalendarEventsForState(
      result.state,
    ).where((entry) => entry.markerLabel == '선물').single;

    expect(result.success, isTrue);
    expect(result.state.bankCash, state.bankCash - 900);
    expect(after.affection, before.affection + 4);
    expect(after.trust, before.trust + 2);
    expect(after.closeness, before.closeness + 1);
    expect(
      result.state.relationships.memories.last.activity,
      RelationshipActivity.gift,
    );
    expect(event.title, contains('한수아'));
  });

  test('market study stacks credits and rest consumes the final point', () {
    final state = weekendState('weekend-study-rest');
    final studied = engine.completeWeekendActivity(
      state,
      const WeekendActivityRequest(activityId: 'market_study'),
    );
    final rested = engine.completeWeekendActivity(
      studied.state,
      const WeekendActivityRequest(activityId: 'rest'),
    );

    expect(studied.success, isTrue);
    expect(studied.state.story.flagInt(weekendMarketResearchCreditsFlag), 1);
    expect(rested.success, isTrue);
    expect(weekendScheduleCompleteForState(rested.state), isTrue);
    expect(rested.state.cash, studied.state.cash);
  });

  test(
    'bankrupt player weekend job deposits pay into live brokerage account',
    () {
      final base = engine.createNewGame(
        '주말 재기 테스트',
        worldSeed: 'weekend-recovery',
      );
      var weekendDay = base.day;
      while (base.dateForDay(weekendDay).weekday != DateTime.saturday) {
        weekendDay += 1;
      }
      final state = base.copyWith(
        day: weekendDay,
        cash: 0,
        brokerageCash: 0,
        positions: const [],
        marketMinute: marketDayStartMinute,
        story: base.story.copyWith(
          storyFlags: {
            ...base.story.storyFlags,
            'marketTutorialSeen': true,
            'liveTradingStarted': true,
          },
        ),
      );

      final worked = engine.completeWeekendActivity(
        state,
        const WeekendActivityRequest(activityId: 'restaurant_dishes'),
      );

      expect(worked.success, isTrue);
      expect(worked.cashDelta, greaterThan(0));
      expect(worked.state.cash, worked.cashDelta);
      expect(worked.state.brokerageCash, worked.cashDelta);
      expect(weekendActivityPointsRemaining(worked.state), 1);
      expect(
        worked.state.ledger.any(
          (entry) =>
              entry.account == 'brokerage_cash' &&
              entry.counterAccount == 'company_bank',
        ),
        isTrue,
      );
    },
  );

  test('weekend activity rejects weekday requests', () {
    final state = engine
        .createNewGame('평일 알바 거절', worldSeed: 'weekday-job')
        .copyWith(day: 3);
    final result = engine.completeWeekendActivity(
      state,
      const WeekendActivityRequest(activityId: 'restaurant_dishes'),
    );

    expect(result.success, isFalse);
    expect(result.message, contains('토요일과 일요일'));
  });
}
