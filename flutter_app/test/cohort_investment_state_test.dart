import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/cohort_investment_state.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';

import 'support/market_fixture.dart';

void main() {
  const engine = GameEngine();

  test('new and migrated games have nine NPC accounts and schema v25', () {
    final state = engine.createNewGame(
      '제6기 결과 테스트',
      worldSeed: 'cohort-result-1',
    );

    expect(GameState.schemaVersion, 25);
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

  test('loan eligibility requires borrower total below the player total', () {
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
    final richerNpc = settled.report!.rankedRows.firstWhere(
      (row) => !row.isPlayer,
    );

    final rejected = engine.lendToCohortInvestor(
      settled.state,
      borrowerId: richerNpc.investorId,
      amount: 100,
    );

    expect(rejected.success, isFalse);
    expect(rejected.message, contains('나보다 적은'));
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
    expect(due.report!.repaymentTotal, 500);
    expect(due.state.cohortInvestments.loans.single.isRepaid, isTrue);
    expect(due.state.cohortInvestments.outstandingLoanReceivables, 0);
    expect(due.report!.resultFor('player')!.profitLoss, 0);
  });

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
}
