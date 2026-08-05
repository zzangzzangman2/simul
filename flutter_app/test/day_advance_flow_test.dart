import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_news.dart';
import 'package:millennium_capital/main.dart';

import 'support/market_fixture.dart';

Future<void> openHubTimeActions(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('hub-time-actions-button')));
  await tester.pumpAndSettle();
  expect(find.text('시간과 일정'), findsOneWidget);
}

void main() {
  testWidgets('1년 저개입 진행은 중요뉴스 정지 없는 전용 콜백을 사용한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const engine = GameEngine();
    final state = engine
        .createNewGame('저개입 진행 테스트', initialCash: 0)
        .copyWith(decisions: const []);
    int? normalDays;
    int? quietDays;

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
          onAdvanceDaysQuiet: (days) async {
            quietDays = days;
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
    expect(find.text('다음 중요 선택까지 (최대 1년)'), findsOneWidget);
    expect(find.textContaining('주간 복기·주말 휴식·관계 휴식'), findsOneWidget);

    await tester.tap(find.byKey(const Key('advance-year-quiet-option')));
    await tester.pumpAndSettle();

    expect(quietDays, 365);
    expect(normalDays, isNull);
    expect(find.byKey(const Key('fast-forward-summary-title')), findsOneWidget);
    expect(find.textContaining('365일 진행'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'direct day end shows ten-person result at 15:00 before evening',
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

      expect(find.byType(CohortDailyResultScreen), findsOneWidget);
      expect(find.byType(RelationshipEveningScreen), findsNothing);
      expect(currentState.marketMinute, krxCloseMinute);
      expect(
        currentState.cohortInvestments.reportForDay(currentState.day),
        isNotNull,
      );

      await tester.tap(find.byKey(const Key('cohort-result-finish-button')));
      await tester.pumpAndSettle();

      expect(find.byType(CohortDailyResultScreen), findsNothing);
      expect(find.byType(RelationshipEveningScreen), findsNothing);
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
  testWidgets('weekend day end skips the closed-market result screen', (
    tester,
  ) async {
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

    expect(find.byType(RelationshipEveningScreen), findsOneWidget);
    expect(find.textContaining('주식시장이 쉬는 주말'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
