import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/cohort_investment_state.dart';
import 'package:millennium_capital/game/cohort_standing_events.dart';
import 'package:millennium_capital/game/cohort_withdrawal_crisis.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/cohort_event_screens.dart';

CohortDailyInvestmentReport _report({
  required int day,
  required int playerCumulative,
  required int filler,
  Map<String, int> overrides = const <String, int>{},
}) {
  CohortDailyInvestmentResult row(
    String id,
    String name,
    int cumulative, {
    bool isPlayer = false,
  }) => CohortDailyInvestmentResult(
    investorId: id,
    name: name,
    assetId: 'hanbit_telecom',
    assetName: '한빛통신',
    investedAmount: 10000,
    profitLoss: 0,
    totalAmount: cohortInvestmentInitialBalance + cumulative,
    traded: true,
    isPlayer: isPlayer,
    cumulativeProfitLoss: cumulative,
  );

  return CohortDailyInvestmentReport(
    day: day,
    rows: <CohortDailyInvestmentResult>[
      row('player', '나', playerCumulative, isPlayer: true),
      for (final profile in cohortNpcInvestorProfiles)
        row(profile.id, profile.name, overrides[profile.id] ?? filler),
    ],
  );
}

void main() {
  const engine = GameEngine();

  Future<void> phone(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
  }

  testWidgets('the last place review reads as a rights notice', (tester) async {
    await phone(tester);
    final base = engine.createNewGame('사건 UI', worldSeed: 'event-ui-1');
    final state = base.copyWith(
      cohortInvestments: base.cohortInvestments.copyWith(
        reports: <CohortDailyInvestmentReport>[
          for (var day = 4; day <= 6; day += 1)
            _report(day: day, playerCumulative: -5000, filler: 100),
        ],
      ),
    );
    final event = pendingCohortStandingEvent(state);
    expect(event, isNotNull);

    var acknowledged = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CohortStandingEventScreen(
          event: event!,
          onAcknowledge: () async => acknowledged = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('cohort-standing-event-screen')),
      findsOneWidget,
    );
    expect(find.text('중단권 확인 면담'), findsOneWidget);
    expect(find.text('한서윤 운영관'), findsOneWidget);
    expect(find.textContaining('벌이 아니라'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('cohort-standing-event-continue')));
    await tester.pumpAndSettle();
    expect(acknowledged, isTrue);
  });

  testWidgets('the rival event names the peer who kept winning', (
    tester,
  ) async {
    await phone(tester);
    final base = engine.createNewGame('사건 UI', worldSeed: 'event-ui-2');
    final state = base.copyWith(
      cohortInvestments: base.cohortInvestments.copyWith(
        reports: <CohortDailyInvestmentReport>[
          for (var day = 4; day <= 8; day += 1)
            _report(
              day: day,
              playerCumulative: 500,
              filler: -900,
              overrides: const <String, int>{'kim_hakjun': 4000},
            ),
        ],
      ),
    );
    final event = pendingCohortStandingEvent(state);
    expect(event?.kind, CohortStandingEventKind.rivalDeclared);

    await tester.pumpWidget(
      MaterialApp(
        home: CohortStandingEventScreen(
          event: event!,
          onAcknowledge: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('김학준'), findsOneWidget);
    expect(find.textContaining('내 종목을 먼저 공개할게'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the withdrawal screen offers three answers and shows the reply',
    (tester) async {
      await phone(tester);
      final base = engine.createNewGame('위기 UI', worldSeed: 'event-ui-3');
      var state = base.copyWith(
        cohortInvestments: base.cohortInvestments.copyWith(
          reports: <CohortDailyInvestmentReport>[
            for (
              var day = 4;
              day < 4 + cohortWithdrawalStreakThreshold;
              day += 1
            )
              _report(
                day: day,
                playerCumulative: 0,
                filler: 500,
                overrides: <String, int>{
                  'han_sua': cohortWithdrawalLossThreshold - 1000,
                },
              ),
          ],
        ),
      );
      state = openCohortWithdrawalCrisis(state);
      expect(activeCohortWithdrawalCrisis(state)?.girlId, 'han_sua');

      await tester.pumpWidget(
        MaterialApp(
          home: CohortWithdrawalCrisisScreen(
            state: state,
            onRespond: (response) async =>
                respondToCohortWithdrawal(state, response),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('한수아가 먼저 말을 꺼냈다'), findsOneWidget);
      expect(find.textContaining('먼저 말한 게 계속 틀렸어'), findsOneWidget);
      // 응답 셋이 모두 있어야 선택에 의미가 있다.
      for (final response in CohortWithdrawalResponse.values) {
        expect(
          find.byKey(Key('cohort-withdrawal-${response.name}')),
          findsOneWidget,
        );
      }
      expect(find.byKey(const Key('cohort-withdrawal-reply')), findsNothing);

      await tester.tap(
        find.byKey(
          Key('cohort-withdrawal-${CohortWithdrawalResponse.shareLedger.name}'),
        ),
      );
      await tester.pumpAndSettle();

      // 응답하면 그 애의 대답이 나오고 선택지는 닫힌다.
      expect(find.byKey(const Key('cohort-withdrawal-reply')), findsOneWidget);
      expect(
        find.byKey(
          Key('cohort-withdrawal-${CohortWithdrawalResponse.persuade.name}'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const Key('cohort-withdrawal-continue')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('both screens fit the 360 by 800 minimum viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    final base = engine.createNewGame('좁은 화면', worldSeed: 'event-ui-4');
    final standing = base.copyWith(
      cohortInvestments: base.cohortInvestments.copyWith(
        reports: <CohortDailyInvestmentReport>[
          for (var day = 4; day <= 6; day += 1)
            _report(day: day, playerCumulative: 9000, filler: 100),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CohortStandingEventScreen(
          event: pendingCohortStandingEvent(standing)!,
          onAcknowledge: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    var crisis = base.copyWith(
      cohortInvestments: base.cohortInvestments.copyWith(
        reports: <CohortDailyInvestmentReport>[
          for (var day = 4; day < 4 + cohortWithdrawalStreakThreshold; day += 1)
            _report(
              day: day,
              playerCumulative: 0,
              filler: 500,
              overrides: <String, int>{
                'yoon_chaea': cohortWithdrawalLossThreshold - 1000,
              },
            ),
        ],
      ),
    );
    crisis = openCohortWithdrawalCrisis(crisis);
    await tester.pumpWidget(
      MaterialApp(
        home: CohortWithdrawalCrisisScreen(
          state: crisis,
          onRespond: (response) async =>
              respondToCohortWithdrawal(crisis, response),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unresolved crisis renders nothing rather than crashing', (
    tester,
  ) async {
    await phone(tester);
    final base = engine.createNewGame('위기 없음', worldSeed: 'event-ui-5');
    await tester.pumpWidget(
      MaterialApp(
        home: CohortWithdrawalCrisisScreen(
          state: base,
          onRespond: (response) async =>
              respondToCohortWithdrawal(base, response),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cohort-withdrawal-screen')), findsOneWidget);
    expect(find.byKey(const Key('cohort-withdrawal-title')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
