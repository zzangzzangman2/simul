import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/story_state.dart';
import 'package:millennium_capital/game/weekday_activity.dart';
import 'package:millennium_capital/main.dart';

GameState _afternoonState({bool allFour = false}) {
  const engine = GameEngine();
  final story = StoryState.newDecimalPlayer(
    playerName: '오후 일정 화면',
    introChoice: 'stocks',
    startingTrait: StoryTrait.analysis,
    operatingPrinciple: OperatingPrinciple.reportLosses,
  );
  final base = engine.createNewGame(
    '오후 일정 화면',
    story: story,
    worldSeed: 'weekday-afternoon-screen',
  );
  return base.copyWith(
    day: 3,
    marketMinute: krxCloseMinute,
    decisions: const <DecisionCardData>[],
    story: base.story.copyWith(
      storyFlags: <String, dynamic>{
        ...base.story.storyFlags,
        'nationalNetworkBriefingSeen': true,
        if (allFour) bankAccessUnlockedFlag: true,
        if (allFour) realEstateAccessUnlockedFlag: true,
      },
    ),
  );
}

void main() {
  const engine = GameEngine();

  testWidgets('optional afternoon screen starts with casino, horse and skip', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var state = _afternoonState();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('open-afternoon-schedule'),
                onPressed: () => Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => WeekdayAfternoonScheduleScreen(
                      state: state,
                      onSelect: (activityId) async {
                        final result = engine.completeWeekdayActivity(
                          state,
                          activityId,
                        );
                        if (result.success) state = result.state;
                        return result;
                      },
                    ),
                  ),
                ),
                child: const Text('오후 일정'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-afternoon-schedule')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('weekday-afternoon-schedule-screen')),
      findsOneWidget,
    );
    expect(find.text('오후 일정을 선택하세요'), findsOneWidget);
    expect(find.text('현재 2개 선택 가능 · 최대 4개'), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const Key('weekday-afternoon-choice-casino')),
          )
          .onTap,
      isNotNull,
    );
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const Key('weekday-afternoon-choice-horse_racing')),
          )
          .onTap,
      isNotNull,
    );
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const Key('weekday-afternoon-choice-bank')),
          )
          .onTap,
      isNull,
    );
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const Key('weekday-afternoon-choice-real_estate')),
          )
          .onTap,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('weekday-afternoon-skip-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const Key('weekday-afternoon-skip-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('weekday-afternoon-skip-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('weekday-afternoon-schedule-screen')),
      findsNothing,
    );
    expect(weekdayEveningUsed(state), isTrue);
    expect(state.marketMinute, marketDayEndMinute);
    expect(
      weekdayActivityLogsForDay(state, state.day).single.activityId,
      weekdayAfternoonSkipActivityId,
    );
  });

  testWidgets('bank and real estate expand the afternoon screen to four', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = _afternoonState(allFour: true);

    await tester.pumpWidget(
      MaterialApp(
        home: WeekdayAfternoonScheduleScreen(
          state: state,
          onSelect: (activityId) async => WeekdayActivityResult(
            state: state,
            success: false,
            message: '화면 유지',
            activity: weekdayActivityById(activityId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('현재 4개 선택 가능 · 최대 4개'), findsOneWidget);
    expect(weekdayActivities, hasLength(4));
    for (final activity in weekdayActivities) {
      expect(
        tester
            .widget<InkWell>(
              find.byKey(Key('weekday-afternoon-choice-${activity.id}')),
            )
            .onTap,
        isNotNull,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
