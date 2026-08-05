import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/cohort_investment_state.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';

import 'support/market_fixture.dart';

void main() {
  const engine = GameEngine();

  test('new and migrated games have nine NPC accounts and schema v27', () {
    final state = engine.createNewGame(
      '제6기 결과 테스트',
      worldSeed: 'cohort-result-1',
    );

    expect(GameState.schemaVersion, 27);
    expect(state.cohortInvestments.accounts.length, 9);
    expect(
      state.cohortInvestments.accounts.values
          .map((account) => account.balance)
          .toSet(),
      <int>{cohortInvestmentInitialBalance},
    );

    final legacy = state.toJson()..remove('cohortInvestments');
    final restored = GameState.fromJson(legacy);
    expect(restored.cohortInvestments.accounts.length, 9);
    expect(restored.cohortInvestments.reports, isEmpty);
  });

  test('market close settles exactly ten deterministic result rows once', () {
    final state = engine
        .createNewGame('제6기 결과 테스트', worldSeed: 'cohort-result-2')
        .copyWith(day: 2, marketMinute: krxCloseMinute);
    final universe = testMarketUniverse(tradingDate: state.currentDate);

    final first = engine.settleCohortInvestmentDay(state, universe: universe);
    final second = engine.settleCohortInvestmentDay(
      first.state,
      universe: universe,
    );

    expect(first.success, isTrue);
    expect(first.report!.rows.length, 10);
    expect(first.report!.rows.where((row) => row.isPlayer), hasLength(1));
    expect(first.report!.rows.where((row) => !row.isPlayer), hasLength(9));
    expect(first.report!.rankedRows.length, 10);
    expect(first.state.cohortInvestments.lastSettledDay, state.day);
    expect(second.success, isTrue);
    expect(second.state.toJson(), first.state.toJson());
  });

  test('settlement is rejected before the 15:00 official close', () {
    final state = engine
        .createNewGame('제6기 결과 테스트', worldSeed: 'cohort-result-3')
        .copyWith(day: 2, marketMinute: krxCloseMinute - 1);
    final result = engine.settleCohortInvestmentDay(
      state,
      universe: testMarketUniverse(tradingDate: state.currentDate),
    );

    expect(result.success, isFalse);
    expect(result.message, contains('15:00'));
  });

  test('one daily loan moves investable cash but preserves gross assets', () {
    final state = engine
        .createNewGame(
          '제6기 결과 테스트',
          worldSeed: 'cohort-result-4',
          initialCash: 50000,
        )
        .copyWith(day: 2, marketMinute: krxCloseMinute);
    final settled = engine.settleCohortInvestmentDay(
      state,
      universe: testMarketUniverse(tradingDate: state.currentDate),
    );
    final beforeAssets = settled.state.balanceSheetGrossAssets();
    final loan = engine.lendToCohortInvestor(
      settled.state,
      borrowerId: 'kim_hakjun',
      amount: 500,
    );
    final duplicate = engine.lendToCohortInvestor(
      loan.state,
      borrowerId: 'kim_seoa',
      amount: 100,
    );

    expect(loan.success, isTrue);
    expect(loan.loan!.dueDay, state.day + cohortLoanTermDays);
    expect(loan.loan!.interest, 60);
    expect(loan.loan!.totalDue, 560);
    expect(loan.state.cash, settled.state.cash - 500);
    expect(loan.state.brokerageCash, settled.state.brokerageCash - 500);
    expect(loan.state.cohortInvestments.outstandingLoanReceivables, 500);
    expect(loan.state.balanceSheetGrossAssets(), beforeAssets);
    expect(
      loan.report!.resultFor('kim_hakjun')!.totalAmount,
      settled.report!.resultFor('kim_hakjun')!.totalAmount + 500,
    );
    expect(duplicate.success, isFalse);
    expect(duplicate.message, contains('하루에 한 번'));
  });

  test('peer lending has a daily principal cap', () {
    final state = engine
        .createNewGame(
          '제6기 결과 테스트',
          worldSeed: 'cohort-result-5',
          initialCash: 500,
        )
        .copyWith(day: 2, marketMinute: krxCloseMinute);
    final settled = engine.settleCohortInvestmentDay(
      state,
      universe: testMarketUniverse(tradingDate: state.currentDate),
    );
    final rejected = engine.lendToCohortInvestor(
      settled.state,
      borrowerId: 'kim_hakjun',
      amount: cohortPlayerBorrowingLimit + 1,
    );

    expect(rejected.success, isFalse);
    expect(rejected.message, contains('최대'));
  });

  test('due loan repays automatically without becoming daily stock profit', () {
    var state = engine
        .createNewGame(
          '제6기 결과 테스트',
          worldSeed: 'cohort-result-6',
          initialCash: 50000,
        )
        .copyWith(day: 2, marketMinute: krxCloseMinute);
    final dayTwo = engine.settleCohortInvestmentDay(
      state,
      universe: testMarketUniverse(tradingDate: state.currentDate),
    );
    final loan = engine.lendToCohortInvestor(
      dayTwo.state,
      borrowerId: 'kim_hakjun',
      amount: 500,
    );
    state = loan.state.copyWith(
      day: 2 + cohortLoanTermDays,
      marketMinute: krxCloseMinute,
    );

    final due = engine.settleCohortInvestmentDay(
      state,
      universe: testMarketUniverse(tradingDate: state.currentDate),
    );

    expect(due.success, isTrue);
    expect(due.report!.repaymentTotal, 560);
    expect(due.report!.loanInterestIncome, 60);
    expect(due.state.cohortInvestments.loans.single.isRepaid, isTrue);
    expect(due.state.cohortInvestments.outstandingLoanReceivables, 0);
    expect(due.report!.resultFor('player')!.profitLoss, 60);
  });

  test(
    'bankrupt player can borrow once at high interest and debt survives JSON',
    () {
      var state = engine
          .createNewGame(
            '동기 긴급 차입 테스트',
            worldSeed: 'cohort-borrow-player',
            initialCash: 5000,
          )
          .copyWith(day: 2, marketMinute: krxCloseMinute);
      state = state.copyWith(
        story: state.story.copyWith(
          storyFlags: {
            ...state.story.storyFlags,
            'marketTutorialSeen': true,
            'liveTradingStarted': true,
          },
        ),
      );
      state = engine
          .settleCohortInvestmentDay(
            state,
            universe: testMarketUniverse(tradingDate: state.currentDate),
          )
          .state;

      final borrowed = engine.borrowFromCohortInvestor(
        state,
        lenderId: 'kim_hakjun',
        amount: 5000,
      );
      final duplicate = engine.borrowFromCohortInvestor(
        borrowed.state,
        lenderId: 'kim_seoa',
        amount: 1000,
      );

      expect(borrowed.success, isTrue);
      expect(borrowed.loan!.direction, CohortLoanDirection.playerBorrows);
      expect(borrowed.loan!.interest, 600);
      expect(borrowed.loan!.totalDue, 5600);
      expect(borrowed.state.brokerageCash, state.brokerageCash + 5000);
      expect(borrowed.state.cohortInvestments.outstandingLoanPayables, 5600);
      expect(duplicate.success, isFalse);
      expect(duplicate.message, contains('기존 동기 차입금'));

      final restored = GameState.fromJson(borrowed.state.toJson());
      expect(restored.cohortInvestments.loans.single.totalDue, 5600);
      expect(
        restored.balanceSheetNetWorth(),
        borrowed.state.balanceSheetNetWorth(),
      );
    },
  );

  test('report acknowledgement and JSON round trip preserve daily guards', () {
    final state = engine
        .createNewGame('제6기 결과 테스트', worldSeed: 'cohort-result-7')
        .copyWith(day: 2, marketMinute: krxCloseMinute);
    final settled = engine.settleCohortInvestmentDay(
      state,
      universe: testMarketUniverse(tradingDate: state.currentDate),
    );
    final acknowledged = engine.acknowledgeCohortInvestmentReport(
      settled.state,
    );
    final restored = GameState.fromJson(acknowledged.state.toJson());

    expect(acknowledged.success, isTrue);
    expect(restored.cohortInvestments.settledForDay(state.day), isTrue);
    expect(restored.cohortInvestments.acknowledgedForDay(state.day), isTrue);
    expect(restored.cohortInvestments.reportForDay(state.day)!.rows.length, 10);
  });

  test('every cohort investor pays the same 20% recovery on a winning day', () {
    final state = engine
        .createNewGame('환수 대칭 테스트', worldSeed: 'cohort-recovery-1')
        // 2000-01-04 화요일. 일요일에 정산하면 열 명 모두 휴장으로 거래가 없다.
        .copyWith(day: 4, marketMinute: krxCloseMinute);
    final settled = engine.settleCohortInvestmentDay(
      state,
      universe: testMarketUniverse(
        tradingDate: state.currentDate,
        closeOverride: 6600,
      ),
    );

    expect(settled.success, isTrue);
    final npcRows = settled.report!.rows
        .where((row) => !row.isPlayer)
        .toList(growable: false);
    expect(npcRows, hasLength(9));
    expect(npcRows.where((row) => row.stateRecovery > 0), isNotEmpty);
    for (final row in npcRows) {
      final netProfit = row.profitLoss + row.stateRecovery;
      final expected = netProfit <= 0
          ? 0
          : (netProfit * state.story.stateRecoveryRateBps / 10000).round();
      expect(
        row.stateRecovery,
        expected,
        reason: '${row.name} 환수액이 확정 순이익의 20%와 다릅니다',
      );
      expect(row.totalAmount, cohortInvestmentInitialBalance + row.profitLoss);
    }
  });

  test('ranking follows the return rate and ignores brokerage transfers', () {
    final base = engine
        .createNewGame('수익률 순위 테스트', worldSeed: 'cohort-rank-1')
        .copyWith(day: 4, marketMinute: krxCloseMinute);
    final universe = testMarketUniverse(
      tradingDate: base.currentDate,
      closeOverride: 6600,
    );

    int rankOf(CohortDailyInvestmentReport report, String investorId) =>
        report.rankedRows.indexWhere((row) => row.investorId == investorId);

    final plain = engine.settleCohortInvestmentDay(base, universe: universe);
    // 회사 통장에서 증권계좌로 100만원을 옮긴 하루. 총금액은 뛰지만 투자로 번 돈은
    // 그대로여야 한다.
    const transfer = 1000000;
    final funded = engine.settleCohortInvestmentDay(
      base.copyWith(
        brokerageCash: base.brokerageCash + transfer,
        cash: base.cash + transfer,
        ledger: [
          ...base.ledger,
          LedgerEntry(
            id: 'rank-test-transfer',
            day: base.day,
            amount: transfer,
            account: 'brokerage_cash',
            counterAccount: 'company_bank',
            description: '순위 테스트 증권계좌 입금',
            sourceId: 'rank-test-transfer',
            notional: transfer,
          ),
        ],
      ),
      universe: universe,
    );

    final plainPlayer = plain.report!.resultFor('player')!;
    final fundedPlayer = funded.report!.resultFor('player')!;

    expect(fundedPlayer.totalAmount - plainPlayer.totalAmount, transfer);
    expect(fundedPlayer.profitLoss, plainPlayer.profitLoss);
    expect(fundedPlayer.returnRateBps, plainPlayer.returnRateBps);
    expect(rankOf(funded.report!, 'player'), rankOf(plain.report!, 'player'));

    // 순위는 수익률 내림차순이고, 총금액 내림차순과는 일치하지 않아도 된다.
    final rates = funded.report!.rankedRows
        .map((row) => row.returnRateBps)
        .toList(growable: false);
    expect(rates, orderedEquals(<int>[...rates]..sort((a, b) => b - a)));
  });

  test('borrowing from a peer does not raise the return rate', () {
    var state = engine
        .createNewGame(
          '차입 수익률 테스트',
          worldSeed: 'cohort-rank-2',
          initialCash: 5000,
        )
        .copyWith(day: 4, marketMinute: krxCloseMinute);
    state = state.copyWith(
      story: state.story.copyWith(
        storyFlags: {
          ...state.story.storyFlags,
          'marketTutorialSeen': true,
          'liveTradingStarted': true,
        },
      ),
    );
    state = engine
        .settleCohortInvestmentDay(
          state,
          universe: testMarketUniverse(tradingDate: state.currentDate),
        )
        .state;

    final borrowed = engine.borrowFromCohortInvestor(
      state,
      lenderId: 'kim_hakjun',
      amount: 20000,
    );
    expect(borrowed.success, isTrue);

    // 빌린 돈은 증권계좌에 그대로 두고 다음 거래일을 정산한다. 투자를 하지 않았으므로
    // 차입 여부와 무관하게 수익률이 같아야 한다.
    final nextDay = state.day + 1;
    final withoutLoan = engine.settleCohortInvestmentDay(
      engine
          .acknowledgeCohortInvestmentReport(state)
          .state
          .copyWith(day: nextDay, marketMinute: krxCloseMinute),
      universe: testMarketUniverse(tradingDate: state.dateForDay(nextDay)),
    );
    final withLoan = engine.settleCohortInvestmentDay(
      engine
          .acknowledgeCohortInvestmentReport(borrowed.state)
          .state
          .copyWith(day: nextDay, marketMinute: krxCloseMinute),
      universe: testMarketUniverse(tradingDate: state.dateForDay(nextDay)),
    );

    final plainPlayer = withoutLoan.report!.resultFor('player')!;
    final loanPlayer = withLoan.report!.resultFor('player')!;

    expect(loanPlayer.totalAmount - plainPlayer.totalAmount, 20000);
    expect(loanPlayer.profitLoss, plainPlayer.profitLoss);
    expect(loanPlayer.returnRateBps, plainPlayer.returnRateBps);
  });
}
