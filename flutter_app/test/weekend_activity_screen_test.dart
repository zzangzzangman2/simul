import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/main.dart';

void main() {
  const engine = GameEngine();

  GameState weekendState(String seed) {
    final base = engine.createNewGame('주말 화면 테스트', worldSeed: seed);
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

  Future<void> setPhoneSurface(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  testWidgets('weekend schedule shows every action group at 390x844', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    var state = weekendState('weekend-screen-actions');

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
    await tester.pumpAndSettle();

    expect(find.text('주말 자유 일정'), findsOneWidget);
    expect(find.byKey(const Key('weekend-action-work')), findsOneWidget);
    expect(find.byKey(const Key('weekend-action-gift')), findsOneWidget);
    expect(find.byKey(const Key('weekend-action-study')), findsOneWidget);
    expect(find.byKey(const Key('weekend-action-rest')), findsOneWidget);
    expect(find.byKey(const Key('weekend-action-horse-racing')), findsNothing);
    expect(find.text('행동력 2칸 남음'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('newspaper job opens the playable delivery route', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    var state = weekendState('weekend-newspaper-ui');
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
    await tester.pumpAndSettle();
    final newspaperJob = find.byKey(
      const Key('weekend-job-newspaper_delivery'),
    );
    await tester.ensureVisible(newspaperJob);
    await tester.tap(newspaperJob);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('새벽 신문배달'), findsOneWidget);
    expect(find.byKey(const Key('rider-course')), findsOneWidget);
    expect(find.byKey(const Key('newspaper-throw')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rest confirmation and finish fit the 360x800 viewport', (
    tester,
  ) async {
    await setPhoneSurface(tester, size: const Size(360, 800));
    var state = weekendState('weekend-screen-minimum');

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
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('weekend-action-rest')));
    await tester.tap(find.byKey(const Key('weekend-action-rest')));
    await tester.pumpAndSettle();
    expect(find.text('남은 시간을 쉴까?'), findsOneWidget);
    await tester.tap(find.text('쉬기'));
    await tester.pumpAndSettle();

    expect(find.text('낮 일정 완료 · 저녁 시간으로'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('weekend-schedule-finish-button')),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekend recovery screen pays job income into brokerage', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final base = engine.createNewGame(
      '주말 재기 화면',
      worldSeed: 'weekend-recovery-ui',
    );
    var weekendDay = base.day;
    while (base.dateForDay(weekendDay).weekday != DateTime.saturday) {
      weekendDay += 1;
    }
    var state = base.copyWith(
      day: weekendDay,
      marketMinute: marketDayStartMinute,
      cash: 0,
      brokerageCash: 0,
      positions: const [],
      story: base.story.copyWith(
        storyFlags: {
          ...base.story.storyFlags,
          'marketTutorialSeen': true,
          'liveTradingStarted': true,
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WeekendScheduleScreen(
          state: state,
          onComplete: (request) async {
            final result = engine.completeWeekendActivity(state, request);
            state = result.state;
            return result;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weekend-schedule-screen')), findsOneWidget);
    expect(find.text('실전 계좌 재기 필요'), findsOneWidget);
    await tester.tap(find.byKey(const Key('weekend-job-restaurant_dishes')));
    await tester.pumpAndSettle();

    expect(state.brokerageCash, greaterThan(0));
    expect(find.textContaining('행동력 1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
