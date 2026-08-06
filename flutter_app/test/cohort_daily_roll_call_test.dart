import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/cohort_investment_state.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/story_state.dart';
import 'package:millennium_capital/game/weekday_activity.dart';
import 'package:millennium_capital/main.dart';

void main() {
  const engine = GameEngine();

  test(
    'weekday roll call ranks ten people and records one optional activity',
    () {
      final base = engine
          .createNewGame(
            '점호 테스트',
            initialCash: 50000,
            worldSeed: 'daily-roll-call-seed',
          )
          .copyWith(
            day: 3,
            marketMinute: marketDayEndMinute,
            decisions: const <DecisionCardData>[],
            ledger: const <LedgerEntry>[
              LedgerEntry(
                id: 'horse-wager',
                day: 3,
                amount: -500,
                account: 'brokerage_cash',
                counterAccount: 'horse_racing_wager_expense',
                description: '단승 전자 마권',
                sourceId: 'horse-race-test',
              ),
              LedgerEntry(
                id: 'horse-payout',
                day: 3,
                amount: 1500,
                account: 'brokerage_cash',
                counterAccount: 'horse_racing_payout_income',
                description: '경마 전자 마권 적중 배당',
                sourceId: 'horse-race-test',
              ),
              LedgerEntry(
                id: 'horse-fee',
                day: 3,
                amount: -200,
                account: 'brokerage_cash',
                counterAccount: 'state_horse_racing_fee',
                description: '경마 확정 이익 국가 수수료 20%',
                sourceId: 'horse-race-test',
              ),
              LedgerEntry(
                id: 'work-income',
                day: 3,
                amount: 2000,
                account: 'company_bank',
                counterAccount: 'work_income',
                description: '주말 생활 수입',
                sourceId: 'work-income',
              ),
            ],
          );

      final result = engine.settleCohortDailyRollCall(base);
      expect(result.success, isTrue);
      expect(result.report!.rows, hasLength(10));
      expect(result.report!.rankedRows, hasLength(10));

      final player = result.report!.resultFor('player')!;
      expect(player.leisureActivity, '경마');
      expect(player.leisureProfitLoss, 800);
      expect(player.otherProfitLoss, 2000);
      expect(player.dailyProfitLoss, 2800);

      final npcRows = result.report!.rows
          .where((row) => !row.isPlayer)
          .toList(growable: false);
      expect(
        npcRows.map((row) => row.leisureActivity),
        everyElement(anyOf('카지노', '경마', '예금·은행', '부동산', '그냥 넘어감', '자금 부족')),
      );
      expect(npcRows.every((row) => row.leisureActivity != '카지노·경마'), isTrue);

      final repeated = engine.settleCohortDailyRollCall(result.state);
      expect(repeated.state.toJson(), result.state.toJson());
      expect(repeated.report!.toJson(), result.report!.toJson());
    },
  );

  test(
    'nine NPCs use unlocked activities, sometimes skip, and move real money',
    () {
      final story = StoryState.newDecimalPlayer(
        playerName: '동기 활동 검증',
        introChoice: 'stocks',
        startingTrait: StoryTrait.analysis,
        operatingPrinciple: OperatingPrinciple.reportLosses,
      );
      final base = engine.createNewGame(
        '동기 활동 검증',
        story: story,
        worldSeed: 'npc-afternoon-fairness',
      );
      var state = base.copyWith(
        decisions: const <DecisionCardData>[],
        story: base.story.copyWith(
          storyFlags: <String, dynamic>{
            ...base.story.storyFlags,
            'nationalNetworkBriefingSeen': true,
            bankAccessUnlockedFlag: true,
            realEstateAccessUnlockedFlag: true,
          },
        ),
      );
      final observed = <String>{};
      var changedBalances = 0;
      var gamblingWins = 0;
      var gamblingLosses = 0;

      for (var index = 0; index < 75; index++) {
        final balancesBefore = <String, int>{
          for (final profile in cohortNpcInvestorProfiles)
            profile.id: state.cohortInvestments.accountFor(profile.id).balance,
        };
        final settled = engine.settleCohortDailyRollCall(state);
        expect(settled.success, isTrue);
        final report = settled.report!;
        for (final row in report.rows.where((row) => !row.isPlayer)) {
          observed.add(row.leisureActivity);
          final before = balancesBefore[row.investorId]!;
          final after = settled.state.cohortInvestments
              .accountFor(row.investorId)
              .balance;
          expect(after - before, row.leisureProfitLoss + row.otherProfitLoss);
          if (after != before) changedBalances++;

          if (row.leisureActivity == '카지노' || row.leisureActivity == '경마') {
            expect(row.afternoonStake, greaterThanOrEqualTo(500));
            expect(row.afternoonStake % 500, 0);
            expect(row.afternoonStake, lessThanOrEqualTo(before * 30 ~/ 100));
            final confirmedProfit =
                (row.afternoonGrossPayout - row.afternoonStake).clamp(
                  0,
                  cohortInvestmentMaxMoney,
                );
            expect(
              row.afternoonStateRecovery,
              (confirmedProfit * state.story.stateRecoveryRateBps / 10000)
                  .round(),
            );
            expect(
              row.leisureProfitLoss,
              row.afternoonGrossPayout -
                  row.afternoonStake -
                  row.afternoonStateRecovery,
            );
            if (row.leisureProfitLoss > 0) gamblingWins++;
            if (row.leisureProfitLoss < 0) gamblingLosses++;
          } else {
            expect(row.afternoonStake, 0);
            expect(row.afternoonGrossPayout, 0);
            expect(row.afternoonStateRecovery, 0);
          }
        }
        state = engine
            .advanceOneDay(settled.state)
            .copyWith(decisions: const <DecisionCardData>[]);
      }

      expect(
        observed,
        containsAll(<String>{'카지노', '경마', '예금·은행', '부동산', '그냥 넘어감', '미참여'}),
      );
      expect(changedBalances, greaterThan(0));
      expect(gamblingWins, greaterThan(0));
      expect(gamblingLosses, greaterThan(0));
      expect(
        cohortNpcInvestorProfiles
            .map(
              (profile) =>
                  state.cohortInvestments.accountFor(profile.id).balance,
            )
            .toSet()
            .length,
        greaterThan(1),
      );
    },
  );

  test('roll call save restores and advance creates a weekend report', () {
    var state = engine
        .createNewGame(
          '점호 저장 테스트',
          initialCash: 50000,
          worldSeed: 'roll-call-save',
        )
        .copyWith(decisions: const <DecisionCardData>[]);
    state = engine.settleCohortDailyRollCall(state).state;
    final restored = GameState.fromJson(state.toJson());
    expect(restored.cohortInvestments.rollCallReports, hasLength(1));
    expect(
      restored.cohortInvestments.rollCallReports.single.toJson(),
      state.cohortInvestments.rollCallReports.single.toJson(),
    );

    while (state.currentDate.weekday != DateTime.saturday) {
      state = engine.advanceOneDay(state);
    }
    final saturday = engine
        .advanceOneDay(state)
        .cohortInvestments
        .rollCallReportForDay(state.day)!;
    expect(saturday.rows, hasLength(10));
    expect(
      saturday.rows
          .where((row) => !row.isPlayer)
          .every((row) => row.leisureActivity == '미참여'),
      isTrue,
    );
  });

  testWidgets(
    'roll call screen shows teacher, daily/monthly and Korean colors',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final base = engine
          .createNewGame(
            '점호 화면 테스트',
            initialCash: 50000,
            worldSeed: 'roll-call-screen',
          )
          .copyWith(
            day: 3,
            marketMinute: marketDayEndMinute,
            decisions: const <DecisionCardData>[],
          );
      final settled = engine.settleCohortDailyRollCall(base);

      await tester.pumpWidget(
        MaterialApp(
          home: CohortDailyRollCallScreen(
            state: settled.state,
            report: settled.report!,
            onOpenCohortFinance: () async {},
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(
        find.byKey(const Key('cohort-daily-roll-call-screen')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('cohort-roll-call-teacher-intro')),
        findsOneWidget,
      );
      expect(find.text('저녁 점호 · 오늘의 결과'), findsOneWidget);
      expect(find.textContaining('일간'), findsWidgets);
      expect(find.textContaining('월간'), findsWidgets);
      expect(
        find.byKey(const Key('cohort-roll-call-finance-button')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byKey(const Key('cohort-roll-call-row-player')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(const Key('cohort-roll-call-row-player')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('cohort-roll-call-row-player')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('cohort-investor-detail-player')),
        findsOneWidget,
      );
      expect(find.text('현재 나이'), findsOneWidget);
      expect(find.text('생일'), findsOneWidget);
      expect(find.text('현재 호감도'), findsOneWidget);
      expect(find.text('고유 능력'), findsOneWidget);
      expect(find.text('총자산 · 자금 위치'), findsOneWidget);
      expect(find.text('생활·회사 통장'), findsOneWidget);
      expect(find.text('국가계좌 예수금'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('cohort-investor-detail-close-player')),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('cohort-roll-call-finish-button')),
        450,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(const Key('cohort-roll-call-finish-button')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
