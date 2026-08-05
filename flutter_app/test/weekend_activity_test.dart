import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/life_calendar.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/relationship_state.dart';
import 'package:millennium_capital/game/weekend_activity.dart';
import 'package:millennium_capital/main.dart';

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
      cash: base.cash + 20000,
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

  test(
    'newspaper delivery requires a played score and pays for performance',
    () {
      final state = weekendState('weekend-newspaper-performance');
      final blocked = engine.completeWeekendActivity(
        state,
        const WeekendActivityRequest(activityId: 'newspaper_delivery'),
      );
      final low = engine.completeWeekendActivity(
        state,
        const WeekendActivityRequest(
          activityId: 'newspaper_delivery',
          workScore: 45,
          workMaxScore: 100,
        ),
      );
      final high = engine.completeWeekendActivity(
        state,
        const WeekendActivityRequest(
          activityId: 'newspaper_delivery',
          workScore: 95,
          workMaxScore: 100,
        ),
      );

      expect(blocked.success, isFalse);
      expect(blocked.message, contains('코스를 먼저 완주'));
      expect(low.success, isTrue);
      expect(high.success, isTrue);
      expect(high.cashDelta, greaterThan(low.cashDelta));
      expect(
        weekendActivityLogsForDay(high.state, high.state.day).single.body,
        contains('배달 정확도 95점'),
      );
    },
  );

  test('preferred gift spends living cash and becomes a calendar record', () {
    final state = weekendState('weekend-preferred-gift');
    final before = state.relationships.progressFor('han_sua');
    final result = engine.completeWeekendActivity(
      state,
      const WeekendActivityRequest(
        activityId: 'gift',
        girlId: 'han_sua',
        giftId: 'fruity_glow_balm',
      ),
    );
    final after = result.state.relationships.progressFor('han_sua');
    final event = lifeCalendarEventsForState(
      result.state,
    ).where((entry) => entry.markerLabel == '선물').single;

    expect(result.success, isTrue);
    expect(result.state.bankCash, state.bankCash - 6300);
    expect(after.affection, before.affection + 6);
    expect(after.trust, before.trust + 2);
    expect(after.closeness, before.closeness + 1);
    expect(
      result.state.relationships.memories.last.activity,
      RelationshipActivity.gift,
    );
    expect(event.title, contains('한수아'));
  });

  test('same monthly gift loses affection and the daily limit is global', () {
    final state = weekendState('weekend-repeat-gift');
    final first = engine.completeWeekendActivity(
      state,
      const WeekendActivityRequest(
        activityId: 'gift',
        girlId: 'han_sua',
        giftId: 'fruity_glow_balm',
      ),
    );
    final blockedSameDay = engine.completeWeekendActivity(
      first.state,
      const WeekendActivityRequest(
        activityId: 'gift',
        girlId: 'kim_seoa',
        giftId: 'barrier_hand_cream',
      ),
    );
    final secondDay = first.state.copyWith(day: first.state.day + 1);
    final second = engine.completeWeekendActivity(
      secondDay,
      const WeekendActivityRequest(
        activityId: 'gift',
        girlId: 'han_sua',
        giftId: 'fruity_glow_balm',
      ),
    );
    final thirdDay = second.state.copyWith(day: first.state.day + 7);
    final third = engine.completeWeekendActivity(
      thirdDay,
      const WeekendActivityRequest(
        activityId: 'gift',
        girlId: 'han_sua',
        giftId: 'fruity_glow_balm',
      ),
    );

    expect(first.affectionDelta, 6);
    expect(blockedSameDay.success, isFalse);
    expect(blockedSameDay.message, contains('하루에 한 번'));
    expect(second.affectionDelta, 3);
    expect(third.affectionDelta, 1);
  });

  test('phone gift uses the same daily budget without spending chat turns', () {
    final state = weekendState('phone-gift-shared-rule');
    final beforeExchanges = state.phoneMessenger
        .progressFor('kim_seoa')
        .exchangesForDay(state.day);
    final sent = engine.sendPhoneGift(
      state,
      contactId: 'kim_seoa',
      giftId: 'barrier_hand_cream',
    );
    final blocked = engine.sendPhoneGift(
      sent.state,
      contactId: 'lee_jian',
      giftId: 'daily_sun_stick',
    );

    expect(sent.success, isTrue);
    expect(sent.affectionDelta, 6);
    expect(sent.state.phoneMessenger.messages.last.text, contains('고마워'));
    expect(
      sent.state.phoneMessenger
          .progressFor('kim_seoa')
          .exchangesForDay(state.day),
      beforeExchanges,
    );
    expect(blocked.success, isFalse);
  });

  test(
    'recent conflict makes a high-affection gift reaction more cautious',
    () {
      final base = weekendState('gift-conflict-tone');
      final current = base.relationships.progressFor('han_sua');
      final state = base.copyWith(
        relationships: base.relationships.copyWith(
          girls: {
            ...base.relationships.girls,
            'han_sua': current.copyWith(affection: 65),
          },
          memories: [
            RelationshipMemory(
              day: base.day,
              girlId: 'han_sua',
              activity: RelationshipActivity.conversation,
              sceneId: 'recent_conflict',
              choiceId: 'crossed_boundary',
              affectionDelta: -3,
              affectionAfter: 65,
            ),
          ],
        ),
      );
      final gift = weekendGiftById('fruity_glow_balm')!;

      expect(kBeautyGiftRelationshipTier(state, 'han_sua'), 2);
      expect(
        kBeautyGiftReaction(
          state,
          gift: gift,
          girlId: 'han_sua',
          monthlyRepeatCount: 0,
        ),
        contains('우리끼리'),
      );
    },
  );

  testWidgets('weekend outing opens the illustrated K-beauty store flow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var state = weekendState('weekend-kbeauty-screen');
    await tester.pumpWidget(
      MaterialApp(
        home: WeekendScheduleScreen(
          state: state,
          onComplete: (request) async {
            final result = engine.completeWeekendActivity(state, request);
            if (result.success) state = result.state;
            return result;
          },
        ),
      ),
    );

    final giftAction = find.byKey(const Key('weekend-action-gift'));
    await tester.ensureVisible(giftAction);
    await tester.tap(giftAction);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kbeauty-store-screen')), findsOneWidget);
    expect(find.byKey(const Key('kbeauty-clerk-dialogue')), findsOneWidget);
    expect(find.byKey(const Key('kbeauty-product-grid')), findsOneWidget);

    final suaRecipient = find.byKey(const Key('kbeauty-recipient-han_sua'));
    await tester.drag(
      find.byKey(const Key('kbeauty-recipient-list')),
      const Offset(-360, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(suaRecipient);
    final fruityGift = find.byKey(
      const Key('kbeauty-product-fruity_glow_balm'),
    );
    await tester.ensureVisible(fruityGift);
    await tester.pumpAndSettle();
    await tester.tap(fruityGift);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('kbeauty-checkout-button')));
    await tester.pumpAndSettle();

    expect(find.text('선물 전달 완료'), findsOneWidget);
    expect(state.relationships.memories.last.choiceId, 'fruity_glow_balm');
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
