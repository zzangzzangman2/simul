import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_news.dart';
import 'package:millennium_capital/game/story_state.dart';
import 'package:millennium_capital/main.dart';

import 'support/market_fixture.dart';

Future<void> openHubTimeActions(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('hub-time-actions-button')));
  await tester.pumpAndSettle();
  expect(find.text('시간과 일정'), findsOneWidget);
}

void main() {
  testWidgets('빠르게 진행 메뉴에서 1년 진행을 제거하고 1개월까지만 직접 선택한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const engine = GameEngine();
    final state = engine
        .createNewGame('저개입 진행 테스트', initialCash: 0)
        .copyWith(decisions: const []);
    int? normalDays;

    await tester.pumpWidget(
      MaterialApp(
        home: OfficeScreen(
          state: state,
          engine: engine,
          activeSaveSlot: 1,
          lastSavedAt: null,
          onManualSave: () async {},
          onReturnToTitle: () {},
          onAdvanceDay: () async => state,
          onAdvanceDays: (days) async {
            normalDays = days;
            return state.copyWith(day: state.day + days);
          },
          onSetMarketMinute: (minute) async =>
              state.copyWith(marketMinute: minute),
          onSaveMarketNotebook: (_, _) async => state,
          onResolveDecision: (_, _) async {},
          onRequestAcademyHelp: (_) async => state,
          onCompleteWork: (_) async => state,
          onExecuteTrade: (_) async => TradeExecutionResult(
            state: state,
            success: false,
            message: 'test',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openHubTimeActions(tester);
    await tester.tap(find.byKey(const Key('advance-batch-button')));
    await tester.pumpAndSettle();
    expect(find.text('다음 중요 선택까지 (최대 1년)'), findsNothing);
    expect(find.byKey(const Key('advance-year-quiet-option')), findsNothing);
    expect(find.text('1개월 진행'), findsOneWidget);

    await tester.tap(find.text('1개월 진행'));
    await tester.pumpAndSettle();

    expect(normalDays, 30);
    expect(find.byKey(const Key('fast-forward-summary-title')), findsOneWidget);
    expect(find.textContaining('30일 진행'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'weekday day end offers activities or an explicit optional skip',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const engine = GameEngine();
      final story = StoryState.newDecimalPlayer(
        playerName: '오후 일정 흐름',
        introChoice: 'stocks',
        startingTrait: StoryTrait.analysis,
        operatingPrinciple: OperatingPrinciple.reportLosses,
      );
      final base = engine.createNewGame(
        '오후 일정 흐름',
        story: story,
        worldSeed: 'weekday-afternoon-flow',
      );
      var currentState = base.copyWith(
        day: 3,
        marketMinute: marketDayStartMinute,
        decisions: const <DecisionCardData>[],
        story: base.story.copyWith(
          storyFlags: <String, dynamic>{
            ...base.story.storyFlags,
            'nationalNetworkBriefingSeen': true,
          },
        ),
      );
      late StateSetter updateHarness;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            updateHarness = setState;
            return MaterialApp(
              home: OfficeScreen(
                state: currentState,
                stateReader: () => currentState,
                engine: engine,
                activeSaveSlot: 1,
                lastSavedAt: null,
                onManualSave: () async {},
                onReturnToTitle: () {},
                onAdvanceDay: () async => currentState,
                onSetMarketMinute: (minute) async {
                  currentState = currentState.copyWith(marketMinute: minute);
                  updateHarness(() {});
                  return currentState;
                },
                onSaveMarketNotebook: (_, _) async => currentState,
                onResolveDecision: (_, _) async {},
                onRequestAcademyHelp: (_) async => currentState,
                onCompleteWeekdayActivity: (activityId) async {
                  final result = engine.completeWeekdayActivity(
                    currentState,
                    activityId,
                  );
                  if (result.success) currentState = result.state;
                  updateHarness(() {});
                  return result;
                },
                onCompleteWork: (_) async => currentState,
                onExecuteTrade: (_) async => TradeExecutionResult(
                  state: currentState,
                  success: false,
                  message: 'test',
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await openHubTimeActions(tester);
      await tester.tap(find.byKey(const Key('advance-day-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('weekday-afternoon-schedule-screen')),
        findsOneWidget,
      );
      expect(find.text('오후 일정을 선택하세요'), findsOneWidget);
      expect(find.text('현재 2개 선택 가능 · 최대 4개'), findsOneWidget);
      expect(
        find.byKey(const Key('weekday-afternoon-skip-button')),
        findsOneWidget,
      );
      expect(find.byType(CohortDailyRollCallScreen), findsNothing);
      expect(currentState.marketMinute, krxCloseMinute);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('weekday-afternoon-schedule-screen')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'direct day end settles stock silently and announces once at 20:00',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const engine = GameEngine();
      var currentState = engine
          .createNewGame(
            '마감 결과 순서 테스트',
            initialCash: 50000,
            worldSeed: 'cohort-day-flow',
          )
          .copyWith(
            day: 3,
            decisions: const [],
            marketMinute: marketDayStartMinute,
            ledger: const [
              LedgerEntry(
                id: 'day-flow-trade',
                day: 3,
                amount: -1000,
                account: 'brokerage_cash',
                counterAccount: 'market_security',
                description: '결과 화면 검증용 체결',
                sourceId: 'day-flow-trade',
                assetId: 'hanbit_telecom',
                tradeSide: 'buy',
                tradeQuantity: 1,
                tradeUnitPrice: 1000,
              ),
            ],
          );
      late StateSetter updateHarness;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            updateHarness = setState;
            return MaterialApp(
              home: OfficeScreen(
                state: currentState,
                stateReader: () => currentState,
                engine: engine,
                activeSaveSlot: 1,
                lastSavedAt: null,
                onManualSave: () async {},
                onReturnToTitle: () {},
                onAdvanceDay: () async {
                  currentState = engine.advanceOneDay(currentState);
                  updateHarness(() {});
                  return currentState;
                },
                onSetMarketMinute: (minute) async {
                  currentState = currentState.copyWith(marketMinute: minute);
                  updateHarness(() {});
                  return currentState;
                },
                onSaveMarketNotebook: (_, _) async => currentState,
                onBuildDailyNewspaper: (closingState) async =>
                    DailyMarketNewspaper(
                      date: closingState.currentDate,
                      brief: buildDailyBrief(closingState),
                      total: 0,
                      advancers: 0,
                      decliners: 0,
                      unchanged: 0,
                      topGainers: const [],
                      topLosers: const [],
                      headline: '하루 결산 테스트',
                      summary: '테스트 신문',
                    ),
                onResolveDecision: (_, _) async {},
                onRequestAcademyHelp: (_) async => currentState,
                onSettleCohortInvestmentDay: () async {
                  final result = engine.settleCohortInvestmentDay(
                    currentState,
                    universe: testMarketUniverse(
                      tradingDate: currentState.currentDate,
                    ),
                  );
                  currentState = result.state;
                  updateHarness(() {});
                  return result;
                },
                onLendToCohortInvestor: (borrowerId, amount) async {
                  final result = engine.lendToCohortInvestor(
                    currentState,
                    borrowerId: borrowerId,
                    amount: amount,
                  );
                  currentState = result.state;
                  updateHarness(() {});
                  return result;
                },
                onBorrowFromCohortInvestor: (lenderId, amount) async {
                  final result = engine.borrowFromCohortInvestor(
                    currentState,
                    lenderId: lenderId,
                    amount: amount,
                  );
                  currentState = result.state;
                  updateHarness(() {});
                  return result;
                },
                onAcknowledgeCohortInvestmentReport: () async {
                  final result = engine.acknowledgeCohortInvestmentReport(
                    currentState,
                  );
                  currentState = result.state;
                  updateHarness(() {});
                  return result;
                },
                onSettleCohortDailyRollCall: () async {
                  final result = engine.settleCohortDailyRollCall(currentState);
                  currentState = result.state;
                  updateHarness(() {});
                  return result;
                },
                onMarkPhoneThreadRead: (contactId) async =>
                    PhoneMessengerActionResult(
                      state: currentState,
                      success: true,
                      message: '$contactId 읽음',
                    ),
                onSendPhoneMessage: (contactId, text) async =>
                    PhoneMessengerActionResult(
                      state: currentState,
                      success: true,
                      message: '$contactId 전송',
                    ),
                onCompleteRelationshipEvening:
                    (girlId, activity, choiceId) async {
                      final result = engine.completeRelationshipEvening(
                        currentState,
                        girlId: girlId,
                        activity: activity,
                        choiceId: choiceId,
                      );
                      currentState = result.state;
                      updateHarness(() {});
                      return result;
                    },
                onRestDuringRelationshipEvening: () async {
                  final result = engine.restDuringRelationshipEvening(
                    currentState,
                  );
                  currentState = result.state;
                  updateHarness(() {});
                  return result;
                },
                onCompleteWork: (_) async => currentState,
                onExecuteTrade: (_) async => TradeExecutionResult(
                  state: currentState,
                  success: false,
                  message: 'test',
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await openHubTimeActions(tester);
      await tester.tap(find.byKey(const Key('advance-day-button')));
      await tester.pumpAndSettle();

      expect(find.byType(CohortDailyResultScreen), findsNothing);
      expect(find.byType(CohortDailyRollCallScreen), findsOneWidget);
      expect(find.byType(RelationshipEveningScreen), findsNothing);
      expect(currentState.marketMinute, marketDayEndMinute);
      expect(
        currentState.cohortInvestments.reportForDay(currentState.day),
        isNotNull,
      );
      expect(
        currentState.cohortInvestments.acknowledgedForDay(currentState.day),
        isFalse,
      );

      await tester.tap(
        find.byKey(const Key('cohort-roll-call-finance-button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CohortDailyResultScreen), findsOneWidget);
      expect(
        tester
            .widget<CohortDailyResultScreen>(
              find.byType(CohortDailyResultScreen),
            )
            .loanOnly,
        isTrue,
      );
      expect(
        currentState.cohortInvestments.acknowledgedForDay(currentState.day),
        isFalse,
      );

      final financeFinish = find.byKey(
        const Key('cohort-result-finish-button'),
      );
      final financeFinishRect = tester.getRect(financeFinish);
      await tester.tapAt(
        Offset(financeFinishRect.center.dx, financeFinishRect.top + 8),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CohortDailyResultScreen), findsNothing);
      expect(find.byType(CohortDailyRollCallScreen), findsOneWidget);
      expect(
        currentState.cohortInvestments.acknowledgedForDay(currentState.day),
        isFalse,
      );

      await tester.tap(find.byKey(const Key('cohort-roll-call-finish-button')));
      await tester.pumpAndSettle();

      expect(find.byType(CohortDailyRollCallScreen), findsNothing);
      expect(find.byType(PostRollCallPhoneTimeScreen), findsOneWidget);
      expect(find.byType(DailyWrapUpScreen), findsNothing);
      expect(
        currentState.cohortInvestments.acknowledgedForDay(currentState.day),
        isTrue,
      );

      await tester.tap(
        find.byKey(const Key('post-roll-call-phone-finish-button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PostRollCallPhoneTimeScreen), findsNothing);
      expect(find.byType(DailyWrapUpScreen), findsOneWidget);
      expect(currentState.marketMinute, marketDayStartMinute);
      expect(currentState.cohortInvestments.acknowledgedForDay(3), isTrue);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('newspaper-next-day-button')));
      await tester.pumpAndSettle();
      expect(find.byType(DailyWrapUpScreen), findsNothing);
    },
  );

  testWidgets(
    'daily wrap combines calendar records and newspaper before next-day 08:00',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const engine = GameEngine();
      var currentState = engine
          .createNewGame('다음 날 시각 테스트', initialCash: 0)
          .copyWith(decisions: const [], marketMinute: marketDayStartMinute);
      final initialDay = currentState.day;
      late StateSetter updateHarness;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            updateHarness = setState;
            return MaterialApp(
              home: OfficeScreen(
                state: currentState,
                engine: engine,
                activeSaveSlot: 1,
                lastSavedAt: null,
                onManualSave: () async {},
                onReturnToTitle: () {},
                onAdvanceDay: () async {
                  currentState = engine.advanceOneDay(currentState);
                  updateHarness(() {});
                  return currentState;
                },
                onSetMarketMinute: (minute) async {
                  currentState = currentState.copyWith(marketMinute: minute);
                  updateHarness(() {});
                  return currentState;
                },
                onSaveMarketNotebook: (_, _) async => currentState,
                onBuildDailyNewspaper: (closingState) async =>
                    DailyMarketNewspaper(
                      date: closingState.currentDate,
                      brief: buildDailyBrief(closingState),
                      total: 0,
                      advancers: 0,
                      decliners: 0,
                      unchanged: 0,
                      topGainers: const [],
                      topLosers: const [],
                      headline: '하루 결산 테스트',
                      summary: '테스트 신문',
                    ),
                onResolveDecision: (_, _) async {},
                onRequestAcademyHelp: (_) async => currentState,
                onCompleteRelationshipEvening:
                    (girlId, activity, choiceId) async {
                      final result = engine.completeRelationshipEvening(
                        currentState,
                        girlId: girlId,
                        activity: activity,
                        choiceId: choiceId,
                      );
                      currentState = result.state;
                      updateHarness(() {});
                      return result;
                    },
                onRestDuringRelationshipEvening: () async {
                  final result = engine.restDuringRelationshipEvening(
                    currentState,
                  );
                  currentState = result.state;
                  updateHarness(() {});
                  return result;
                },
                onCompleteWork: (_) async => currentState,
                onExecuteTrade: (_) async => TradeExecutionResult(
                  state: currentState,
                  success: false,
                  message: 'test',
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await openHubTimeActions(tester);
      await tester.tap(find.byKey(const Key('advance-day-button')));
      await tester.pumpAndSettle();
      expect(find.byType(RelationshipEveningScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('relationship-rest-button')));
      for (
        var attempt = 0;
        attempt < 30 && find.byType(DailyWrapUpScreen).evaluate().isEmpty;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump();

      expect(currentState.day, initialDay + 1);
      expect(currentState.marketMinute, marketDayStartMinute);
      final hidden = currentState.story.storyFlags['hiddenMarketScenario'];
      expect(hidden, isA<Map>());
      expect((hidden as Map)['date'], marketDateKey(currentState.currentDate));
      expect(find.byType(LifeCalendarScreen), findsNothing);
      expect(find.byType(KoreaEconomicNewspaperSheet), findsNothing);
      expect(find.byType(DailyWrapUpScreen), findsOneWidget);
      expect(find.text('오늘 기록 · 내일 아침'), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('daily-wrap-up-scroll')),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('테스트 신문'), findsOneWidget);

      await tester.tap(find.byKey(const Key('newspaper-next-day-button')));
      await tester.pumpAndSettle();

      expect(currentState.day, initialDay + 1);
      expect(currentState.marketMinute, marketDayStartMinute);
      expect(find.textContaining('08:00'), findsOneWidget);
      expect(find.byType(DailyWrapUpScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'weekend skips stock settlement but still holds 20:00 roll call',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const engine = GameEngine();
      final base = engine
          .createNewGame(
            '주말 하루 종료',
            initialCash: 50000,
            worldSeed: 'weekend-day-flow',
          )
          .copyWith(decisions: const [], marketMinute: marketDayStartMinute);
      var weekendDay = base.day;
      while (base.dateForDay(weekendDay).weekday < DateTime.saturday) {
        weekendDay += 1;
      }
      var currentState = base.copyWith(day: weekendDay);
      var settlementCalls = 0;
      late StateSetter updateHarness;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            updateHarness = setState;
            return MaterialApp(
              home: OfficeScreen(
                state: currentState,
                engine: engine,
                activeSaveSlot: 1,
                lastSavedAt: null,
                onManualSave: () async {},
                onReturnToTitle: () {},
                onAdvanceDay: () async => currentState,
                onSetMarketMinute: (minute) async {
                  currentState = currentState.copyWith(marketMinute: minute);
                  updateHarness(() {});
                  return currentState;
                },
                onSaveMarketNotebook: (_, _) async => currentState,
                onResolveDecision: (_, _) async {},
                onRequestAcademyHelp: (_) async => currentState,
                onCompleteWeekendActivity: (request) async {
                  final result = engine.completeWeekendActivity(
                    currentState,
                    request,
                  );
                  currentState = result.state;
                  updateHarness(() {});
                  return result;
                },
                onSettleCohortInvestmentDay: () async {
                  settlementCalls += 1;
                  return CohortInvestmentActionResult(
                    state: currentState,
                    success: false,
                    message: '주말에는 호출되면 안 됨',
                  );
                },
                onLendToCohortInvestor: (_, _) async =>
                    CohortInvestmentActionResult(
                      state: currentState,
                      success: false,
                      message: '주말에는 호출되면 안 됨',
                    ),
                onBorrowFromCohortInvestor: (_, _) async =>
                    CohortInvestmentActionResult(
                      state: currentState,
                      success: false,
                      message: '주말에는 호출되면 안 됨',
                    ),
                onAcknowledgeCohortInvestmentReport: () async =>
                    CohortInvestmentActionResult(
                      state: currentState,
                      success: false,
                      message: '주말에는 호출되면 안 됨',
                    ),
                onSettleCohortDailyRollCall: () async {
                  final result = engine.settleCohortDailyRollCall(currentState);
                  currentState = result.state;
                  updateHarness(() {});
                  return result;
                },
                onCompleteWork: (_) async => currentState,
                onExecuteTrade: (_) async => TradeExecutionResult(
                  state: currentState,
                  success: false,
                  message: 'test',
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await openHubTimeActions(tester);
      await tester.tap(find.byKey(const Key('advance-day-button')));
      await tester.pumpAndSettle();

      expect(settlementCalls, 0);
      expect(find.byType(CohortDailyResultScreen), findsNothing);
      expect(find.byType(WeekendScheduleScreen), findsOneWidget);
      expect(find.byType(RelationshipEveningScreen), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('weekend-action-rest')));
      await tester.tap(find.byKey(const Key('weekend-action-rest')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('쉬기'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('weekend-schedule-finish-button')));
      await tester.pumpAndSettle();

      expect(find.byType(CohortDailyRollCallScreen), findsOneWidget);
      expect(find.byType(RelationshipEveningScreen), findsNothing);
      expect(
        currentState.cohortInvestments
            .rollCallReportForDay(currentState.day)
            ?.rows,
        hasLength(10),
      );

      final finishButton = find.byKey(
        const Key('cohort-roll-call-finish-button'),
      );
      final finishButtonRect = tester.getRect(finishButton);
      await tester.tapAt(
        Offset(finishButtonRect.center.dx, finishButtonRect.top + 8),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CohortDailyRollCallScreen), findsNothing);
      expect(find.byType(RelationshipEveningScreen), findsOneWidget);
      expect(find.textContaining('주식시장이 쉬는 주말'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
