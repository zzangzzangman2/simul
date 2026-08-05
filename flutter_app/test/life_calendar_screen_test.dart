import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/main.dart';

void main() {
  const engine = GameEngine();

  Future<void> setPhoneSurface(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  testWidgets('daily transition renders a polished month and art slot', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final state = engine.createNewGame(
      '달력 화면 테스트',
      worldSeed: 'life-calendar-screen',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('open-calendar-test'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => LifeCalendarScreen(
                      state: state,
                      transitionTo: state.currentDate.add(
                        const Duration(days: 1),
                      ),
                    ),
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-calendar-test')));
    await tester.pumpAndSettle();

    expect(find.byType(LifeCalendarScreen), findsOneWidget);
    expect(find.text('데시멀 성장 달력'), findsOneWidget);
    expect(find.textContaining('14살'), findsWidgets);
    expect(find.text('2000년 1월'), findsOneWidget);
    expect(find.byKey(const Key('life-calendar-month-grid')), findsOneWidget);
    expect(
      find.byKey(const Key('life-calendar-event-art-slot')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('life-calendar-day-2000-01-03')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('life-calendar-day-2000-01-04')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('life-calendar-continue-button')));
    await tester.pumpAndSettle();
    expect(find.byType(LifeCalendarScreen), findsNothing);
  });

  testWidgets('calendar fits the 360 by 800 minimum viewport', (tester) async {
    await setPhoneSurface(tester, size: const Size(360, 800));
    final base = engine.createNewGame(
      '달력 최소 화면',
      worldSeed: 'life-calendar-360',
    );
    final state = base.copyWith(day: base.day + 40);

    await tester.pumpWidget(
      MaterialApp(home: LifeCalendarScreen(state: state)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('life-calendar-screen')), findsOneWidget);
    expect(find.byKey(const Key('life-calendar-event-card')), findsOneWidget);
    expect(find.byKey(const Key('life-calendar-filter-row')), findsOneWidget);
    expect(
      find.byKey(const Key('life-calendar-filter-keyRecords')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('life-calendar-filter-all')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: find.byKey(const Key('life-calendar-previous-month')),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
}
