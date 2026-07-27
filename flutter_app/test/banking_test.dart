import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/banking_state.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';

void main() {
  const engine = GameEngine();

  int dayFor(GameState state, DateTime date) =>
      date.difference(state.campaignStartDate).inDays + 1;

  GameState adultState({int cash = 5000000, bool recurringIncome = true}) {
    final base = engine.createNewGame(
      '은행 테스트',
      initialCash: cash,
      worldSeed: 'banking-test-world',
    );
    return base.copyWith(
      day: dayFor(base, DateTime(2010, 2, 15)),
      brokerageCash: 0,
      decisions: const [],
      company: recurringIncome
          ? base.company.copyWith(
              votingOwnershipPct: 55,
              monthlyRevenue: 20000000,
            )
          : base.company,
    );
  }

  test('날짜별 금리와 신용점수가 예금금리·대출한도를 바꾼다', () {
    expect(
      bankCheckingAnnualRateAt(DateTime(2015), cashManagementSkill: true) -
          bankCheckingAnnualRateAt(DateTime(2015)),
      closeTo(0.0015, 0.0000001),
    );
    expect(
      bankTermDepositAnnualRateAt(DateTime(2000), 12),
      greaterThan(bankTermDepositAnnualRateAt(DateTime(2020), 12)),
    );
    final low = assessUnsecuredLoanOffer(
      date: DateTime(2015),
      creditScore: 610,
      qualifyingMonthlyIncome: 1000000,
      existingUnsecuredBalance: 0,
      existingMonthlyDebtService: 0,
      termMonths: 36,
      isAdult: true,
      hasDelinquency: false,
    );
    final high = assessUnsecuredLoanOffer(
      date: DateTime(2015),
      creditScore: 820,
      qualifyingMonthlyIncome: 1000000,
      existingUnsecuredBalance: 0,
      existingMonthlyDebtService: 0,
      termMonths: 36,
      isAdult: true,
      hasDelinquency: false,
    );

    expect(low.eligible, isTrue);
    expect(high.eligible, isTrue);
    expect(high.maximumPrincipal, greaterThan(low.maximumPrincipal));
    expect(high.annualInterestRate, lessThan(low.annualInterestRate));
  });

  test('반복소득이 없거나 미성년이면 신용점수가 높아도 대출할 수 없다', () {
    final noIncome = assessUnsecuredLoanOffer(
      date: DateTime(2015),
      creditScore: 850,
      qualifyingMonthlyIncome: 0,
      existingUnsecuredBalance: 0,
      existingMonthlyDebtService: 0,
      termMonths: 24,
      isAdult: true,
      hasDelinquency: false,
    );
    final minor = assessUnsecuredLoanOffer(
      date: DateTime(2005),
      creditScore: 850,
      qualifyingMonthlyIncome: 1000000,
      existingUnsecuredBalance: 0,
      existingMonthlyDebtService: 0,
      termMonths: 24,
      isAdult: false,
      hasDelinquency: false,
    );

    expect(noIncome.eligible, isFalse);
    expect(noIncome.reason, contains('반복 월소득'));
    expect(minor.eligible, isFalse);
    expect(minor.reason, contains('만 20세'));
  });

  test('정기예금 가입은 유동현금만 예금자산으로 옮겨 순자산을 바꾸지 않는다', () {
    final state = adultState();
    final before = state.balanceSheetNetWorth();

    final result = engine.openTimeDeposit(
      state,
      amount: 500000,
      termMonths: 12,
    );

    expect(result.success, isTrue);
    expect(result.state.cash, state.cash - 500000);
    expect(result.state.banking.termDeposits, hasLength(1));
    expect(result.state.banking.termDeposits.single.principal, 500000);
    expect(result.state.balanceSheetNetWorth(), before);
    expect(result.state.ledger.last.counterAccount, 'bank_time_deposit');
  });

  test('증권 예수금은 정기예금 가입에 사용할 수 없다', () {
    final state = adultState(cash: 1000000).copyWith(brokerageCash: 1000000);

    final result = engine.openTimeDeposit(state, amount: 100000, termMonths: 6);

    expect(state.bankCash, 0);
    expect(result.success, isFalse);
    expect(result.state.toJson(), state.toJson());
  });

  test('정기예금 만기 원리금은 하루 진행에서 정확히 한 번 자동 입금된다', () {
    final base = adultState(cash: 0, recurringIncome: false);
    final deposit = BankTermDeposit(
      id: 'maturity-once',
      principal: 100000,
      annualInterestRate: 0.10,
      openedDay: base.day - 364,
      maturityDay: base.day + 1,
      termMonths: 12,
    );
    final state = base.copyWith(
      banking: base.banking.copyWith(termDeposits: [deposit]),
    );
    final expected = deposit.redemptionAmountAt(state.day + 1);

    final matured = engine.advanceOneDay(state);
    final advancedAgain = engine.advanceOneDay(matured);

    expect(matured.cash, expected);
    expect(matured.banking.termDeposits, isEmpty);
    expect(
      matured.ledger
          .where((entry) => entry.sourceId.contains('maturity-once'))
          .length,
      1,
    );
    expect(
      advancedAgain.ledger
          .where((entry) => entry.sourceId.contains('maturity-once'))
          .length,
      1,
    );
  });

  test('정기예금 중도해지는 약정 만기이자보다 적은 이자를 지급한다', () {
    final opened = engine.openTimeDeposit(
      adultState(),
      amount: 500000,
      termMonths: 12,
    );
    final deposit = opened.state.banking.termDeposits.single;
    final earlyState = opened.state.copyWith(day: opened.state.day + 60);

    final result = engine.redeemTimeDeposit(earlyState, deposit.id);

    expect(result.success, isTrue);
    expect(result.cashDelta, greaterThanOrEqualTo(deposit.principal));
    expect(
      result.cashDelta - deposit.principal,
      lessThan(deposit.netInterestAt(deposit.maturityDay)),
    );
    expect(result.state.banking.termDeposits, isEmpty);
  });

  test('신용대출 실행은 현금과 부채를 함께 늘려 순자산을 만들지 않는다', () {
    final state = adultState();
    final offer = engine.unsecuredLoanOffer(state, termMonths: 24);
    final before = state.balanceSheetNetWorth();

    final result = engine.takeUnsecuredLoan(
      state,
      amount: 1000000,
      termMonths: 24,
    );

    expect(offer.eligible, isTrue);
    expect(offer.maximumPrincipal, greaterThanOrEqualTo(1000000));
    expect(result.success, isTrue);
    expect(result.state.cash, state.cash + 1000000);
    expect(result.state.banking.totalUnsecuredLoanBalance, 1000000);
    expect(
      result.state.totalKnownLiabilities,
      state.totalKnownLiabilities + 1000000,
    );
    expect(result.state.balanceSheetNetWorth(), before);
  });

  test('대출로 늘어난 현금은 반복소득이나 다음 대출한도를 부풀리지 않는다', () {
    final state = adultState(cash: 0, recurringIncome: false);
    final artificialDebt = BankUnsecuredLoan(
      id: 'borrowed-cash',
      originalPrincipal: 10000000,
      balance: 10000000,
      annualInterestRate: 0.10,
      termMonths: 36,
      remainingMonths: 36,
      scheduledMonthlyPayment: 330000,
      nextPaymentDay: state.day + 30,
      consecutiveMissedPayments: 0,
      totalMissedPayments: 0,
    );
    final leveraged = state.copyWith(
      cash: 10000000,
      banking: state.banking.copyWith(unsecuredLoans: [artificialDebt]),
    );

    expect(gameQualifyingRecurringMonthlyIncome(state), 0);
    expect(gameQualifyingRecurringMonthlyIncome(leveraged), 0);
    expect(
      engine.unsecuredLoanOffer(leveraged, termMonths: 36).eligible,
      isFalse,
    );
  });

  test('첫 납부 전 즉시 전액상환은 신용점수를 올리지 않는다', () {
    final borrowed = engine.takeUnsecuredLoan(
      adultState(),
      amount: 600000,
      termMonths: 12,
    );
    final loan = borrowed.state.banking.unsecuredLoans.single;
    final partial = engine.repayUnsecuredLoan(
      borrowed.state,
      loanId: loan.id,
      amount: 100000,
    );
    final afterPartial = partial.state.banking.unsecuredLoans.single;
    final paidOff = engine.repayUnsecuredLoan(
      partial.state,
      loanId: loan.id,
      amount: afterPartial.balance,
    );

    expect(partial.success, isTrue);
    expect(afterPartial.balance, 500000);
    expect(paidOff.success, isTrue);
    expect(paidOff.state.banking.unsecuredLoans, isEmpty);
    expect(
      paidOff.state.banking.creditScore,
      borrowed.state.banking.creditScore,
    );
  });

  test('1원 대출과 당일 상환을 반복해도 신용점수를 파밍할 수 없다', () {
    var state = adultState();
    final initialScore = state.banking.creditScore;

    for (var index = 0; index < 20; index += 1) {
      final borrowed = engine.takeUnsecuredLoan(
        state,
        amount: 1,
        termMonths: 12,
      );
      expect(borrowed.success, isTrue);
      final loan = borrowed.state.banking.unsecuredLoans.single;
      final repaid = engine.repayUnsecuredLoan(
        borrowed.state,
        loanId: loan.id,
        amount: loan.balance,
      );
      expect(repaid.success, isTrue);
      state = repaid.state;
    }

    expect(state.banking.creditScore, initialScore);
    expect(state.banking.unsecuredLoans, isEmpty);
  });

  test('최소 한 달 정상 납부 뒤 전액상환하면 신용점수 보너스를 받는다', () {
    final borrowed = engine.takeUnsecuredLoan(
      adultState(cash: 5000000),
      amount: 600000,
      termMonths: 12,
    );
    final original = borrowed.state.banking.unsecuredLoans.single;
    final paidOnceLoan = original.copyWith(
      balance: original.balance - 50000,
      remainingMonths: original.termMonths - 1,
    );
    final paidOnceState = borrowed.state.copyWith(
      banking: borrowed.state.banking.copyWith(unsecuredLoans: [paidOnceLoan]),
    );

    final paidOff = engine.repayUnsecuredLoan(
      paidOnceState,
      loanId: paidOnceLoan.id,
      amount: paidOnceLoan.balance,
    );

    expect(paidOff.success, isTrue);
    expect(
      paidOff.state.banking.creditScore,
      paidOnceState.banking.creditScore + 5,
    );
  });

  test('현금 잔액은 부동산 담보대출의 반복소득으로 계산하지 않는다', () {
    final noCash = adultState(cash: 0, recurringIncome: false);
    final highCash = noCash.copyWith(cash: 1000000000);

    expect(gameQualifyingRecurringMonthlyIncome(noCash), 0);
    expect(gameQualifyingRecurringMonthlyIncome(highCash), 0);
    expect(
      gameRealEstateQualifyingMonthlyIncome(noCash, targetMonthlyRent: 400000),
      300000,
    );
    expect(
      gameRealEstateQualifyingMonthlyIncome(
        highCash,
        targetMonthlyRent: 400000,
      ),
      300000,
    );
  });

  test('월 원리금 정상 납부는 잔액을 줄이고 신용점수를 올린다', () {
    final base = adultState(cash: 100000, recurringIncome: false);
    final january31 = base.copyWith(
      day: dayFor(base, DateTime(2010, 1, 31)),
      decisions: const [],
    );
    final dueDay = dayFor(january31, DateTime(2010, 2, 1));
    final loan = BankUnsecuredLoan(
      id: 'monthly-payment',
      originalPrincipal: 100000,
      balance: 100000,
      annualInterestRate: 0.12,
      termMonths: 12,
      remainingMonths: 12,
      scheduledMonthlyPayment: bankMonthlyPayment(100000, 0.12, 12),
      nextPaymentDay: dueDay,
      consecutiveMissedPayments: 0,
      totalMissedPayments: 0,
    );
    final state = january31.copyWith(
      banking: january31.banking.copyWith(unsecuredLoans: [loan]),
    );

    final next = engine.advanceOneDay(state);
    final updated = next.banking.unsecuredLoans.single;

    expect(updated.balance, lessThan(loan.balance));
    expect(next.banking.creditScore, state.banking.creditScore + 2);
    expect(next.banking.successfulPaymentMonths, 1);
    expect(
      next.ledger.any(
        (entry) =>
            entry.counterAccount == 'bank_unsecured_loan' && entry.amount < 0,
      ),
      isTrue,
    );
  });

  test('현금 부족으로 신용대출을 연체하면 이자·연체료와 신용하락이 남는다', () {
    final base = adultState(cash: 0, recurringIncome: false);
    final january31 = base.copyWith(
      day: dayFor(base, DateTime(2010, 1, 31)),
      decisions: const [],
    );
    final loan = BankUnsecuredLoan(
      id: 'missed-payment',
      originalPrincipal: 100000,
      balance: 100000,
      annualInterestRate: 0.12,
      termMonths: 12,
      remainingMonths: 12,
      scheduledMonthlyPayment: bankMonthlyPayment(100000, 0.12, 12),
      nextPaymentDay: dayFor(january31, DateTime(2010, 2, 1)),
      consecutiveMissedPayments: 0,
      totalMissedPayments: 0,
    );
    final state = january31.copyWith(
      banking: january31.banking.copyWith(unsecuredLoans: [loan]),
    );

    final next = engine.advanceOneDay(state);
    final updated = next.banking.unsecuredLoans.single;

    expect(updated.balance, greaterThan(loan.balance));
    expect(updated.consecutiveMissedPayments, 1);
    expect(next.banking.creditScore, state.banking.creditScore - 45);
    expect(next.banking.missedPaymentMonths, 1);
    expect(
      next.ledger.any((entry) => entry.counterAccount == 'bank_loan_arrears'),
      isTrue,
    );
  });

  test('은행 계약과 신용점수는 JSON 왕복 보존되고 v16 저장은 안전하게 초기화된다', () {
    final opened = engine.openTimeDeposit(
      adultState(),
      amount: 200000,
      termMonths: 6,
    );
    final restored = engine.migrate(opened.state.toJson());

    expect(restored.banking.toJson(), opened.state.banking.toJson());

    final legacy = opened.state.toJson()
      ..remove('banking')
      ..['version'] = 16;
    final migrated = engine.migrate(legacy);

    expect(migrated.version, GameState.schemaVersion);
    expect(migrated.banking.creditScore, bankInitialCreditScore);
    expect(migrated.banking.termDeposits, isEmpty);
    expect(migrated.banking.unsecuredLoans, isEmpty);
  });
}
