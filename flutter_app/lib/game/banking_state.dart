import 'dart:math' as math;

const double bankInterestWithholdingTaxRate = 0.154;
const double bankMaximumDsrRate = 0.40;
const int bankMinimumCreditScore = 300;
const int bankMaximumCreditScore = 900;
const int bankInitialCreditScore = 650;
const List<int> bankDepositTermMonths = <int>[6, 12, 24];
const List<int> bankLoanTermMonths = <int>[12, 24, 36];

class BankRateEnvironment {
  const BankRateEnvironment({
    required this.checkingAnnualRate,
    required this.twelveMonthDepositAnnualRate,
    required this.unsecuredLoanBaseAnnualRate,
    required this.label,
  });

  final double checkingAnnualRate;
  final double twelveMonthDepositAnnualRate;
  final double unsecuredLoanBaseAnnualRate;
  final String label;
}

BankRateEnvironment bankRateEnvironmentAt(DateTime date) => switch (date.year) {
  <= 2002 => const BankRateEnvironment(
    checkingAnnualRate: 0.012,
    twelveMonthDepositAnnualRate: 0.055,
    unsecuredLoanBaseAnnualRate: 0.085,
    label: '2000~2002 고금리기',
  ),
  <= 2007 => const BankRateEnvironment(
    checkingAnnualRate: 0.012,
    twelveMonthDepositAnnualRate: 0.042,
    unsecuredLoanBaseAnnualRate: 0.072,
    label: '2003~2007 안정기',
  ),
  2008 => const BankRateEnvironment(
    checkingAnnualRate: 0.015,
    twelveMonthDepositAnnualRate: 0.052,
    unsecuredLoanBaseAnnualRate: 0.090,
    label: '2008 신용경색기',
  ),
  <= 2011 => const BankRateEnvironment(
    checkingAnnualRate: 0.008,
    twelveMonthDepositAnnualRate: 0.035,
    unsecuredLoanBaseAnnualRate: 0.065,
    label: '2009~2011 회복기',
  ),
  <= 2015 => const BankRateEnvironment(
    checkingAnnualRate: 0.004,
    twelveMonthDepositAnnualRate: 0.022,
    unsecuredLoanBaseAnnualRate: 0.052,
    label: '2012~2015 저금리기',
  ),
  <= 2019 => const BankRateEnvironment(
    checkingAnnualRate: 0.005,
    twelveMonthDepositAnnualRate: 0.028,
    unsecuredLoanBaseAnnualRate: 0.050,
    label: '2016~2019 정상화기',
  ),
  <= 2021 => const BankRateEnvironment(
    checkingAnnualRate: 0.001,
    twelveMonthDepositAnnualRate: 0.012,
    unsecuredLoanBaseAnnualRate: 0.042,
    label: '2020~2021 초저금리기',
  ),
  <= 2023 => const BankRateEnvironment(
    checkingAnnualRate: 0.010,
    twelveMonthDepositAnnualRate: 0.040,
    unsecuredLoanBaseAnnualRate: 0.068,
    label: '2022~2023 긴축기',
  ),
  _ => const BankRateEnvironment(
    checkingAnnualRate: 0.008,
    twelveMonthDepositAnnualRate: 0.032,
    unsecuredLoanBaseAnnualRate: 0.058,
    label: '2024~2026 조정기',
  ),
};

double bankCheckingAnnualRateAt(
  DateTime date, {
  bool cashManagementSkill = false,
}) {
  final base = bankRateEnvironmentAt(date).checkingAnnualRate;
  return base + (cashManagementSkill ? 0.0015 : 0);
}

double bankTermDepositAnnualRateAt(
  DateTime date,
  int termMonths, {
  bool cashManagementSkill = false,
}) {
  if (!bankDepositTermMonths.contains(termMonths)) return 0;
  final base = bankRateEnvironmentAt(date).twelveMonthDepositAnnualRate;
  final termAdjustment = switch (termMonths) {
    6 => -0.0025,
    24 => 0.005,
    _ => 0.0,
  };
  return math.max(
    0,
    base + termAdjustment + (cashManagementSkill ? 0.0015 : 0),
  );
}

class BankCreditTier {
  const BankCreditTier({
    required this.label,
    required this.incomeMultiple,
    required this.loanRateSpread,
    required this.eligible,
  });

  final String label;
  final int incomeMultiple;
  final double loanRateSpread;
  final bool eligible;
}

BankCreditTier bankCreditTierForScore(int score) => switch (score) {
  >= 800 => const BankCreditTier(
    label: '최우량',
    incomeMultiple: 12,
    loanRateSpread: 0.008,
    eligible: true,
  ),
  >= 750 => const BankCreditTier(
    label: '우량+',
    incomeMultiple: 9,
    loanRateSpread: 0.015,
    eligible: true,
  ),
  >= 700 => const BankCreditTier(
    label: '우량',
    incomeMultiple: 7,
    loanRateSpread: 0.025,
    eligible: true,
  ),
  >= 650 => const BankCreditTier(
    label: '보통',
    incomeMultiple: 5,
    loanRateSpread: 0.040,
    eligible: true,
  ),
  >= 600 => const BankCreditTier(
    label: '주의',
    incomeMultiple: 3,
    loanRateSpread: 0.065,
    eligible: true,
  ),
  _ => const BankCreditTier(
    label: '대출 제한',
    incomeMultiple: 0,
    loanRateSpread: 0,
    eligible: false,
  ),
};

int bankMonthlyPayment(
  int principal,
  double annualInterestRate,
  int remainingMonths,
) {
  if (principal <= 0 || remainingMonths <= 0) return 0;
  final monthlyRate = annualInterestRate / 12;
  if (monthlyRate <= 0) return (principal / remainingMonths).ceil();
  final growth = math.pow(1 + monthlyRate, remainingMonths).toDouble();
  return (principal * monthlyRate * growth / (growth - 1)).ceil();
}

int bankPrincipalForMonthlyPayment(
  int monthlyPayment,
  double annualInterestRate,
  int termMonths,
) {
  if (monthlyPayment <= 0 || termMonths <= 0) return 0;
  final monthlyRate = annualInterestRate / 12;
  if (monthlyRate <= 0) return monthlyPayment * termMonths;
  final discount = math.pow(1 + monthlyRate, -termMonths).toDouble();
  return (monthlyPayment * (1 - discount) / monthlyRate).floor();
}

class BankLoanOffer {
  const BankLoanOffer({
    required this.eligible,
    required this.maximumPrincipal,
    required this.annualInterestRate,
    required this.termMonths,
    required this.maximumMonthlyPayment,
    required this.qualifyingMonthlyIncome,
    required this.creditLabel,
    required this.reason,
  });

  final bool eligible;
  final int maximumPrincipal;
  final double annualInterestRate;
  final int termMonths;
  final int maximumMonthlyPayment;
  final int qualifyingMonthlyIncome;
  final String creditLabel;
  final String reason;

  int monthlyPaymentFor(int amount) =>
      bankMonthlyPayment(amount, annualInterestRate, termMonths);
}

BankLoanOffer assessUnsecuredLoanOffer({
  required DateTime date,
  required int creditScore,
  required int qualifyingMonthlyIncome,
  required int existingUnsecuredBalance,
  required int existingMonthlyDebtService,
  required int termMonths,
  required bool isAdult,
  required bool hasDelinquency,
}) {
  final tier = bankCreditTierForScore(creditScore);
  final annualInterestRate =
      bankRateEnvironmentAt(date).unsecuredLoanBaseAnnualRate +
      tier.loanRateSpread;
  BankLoanOffer denied(String reason) => BankLoanOffer(
    eligible: false,
    maximumPrincipal: 0,
    annualInterestRate: annualInterestRate,
    termMonths: termMonths,
    maximumMonthlyPayment: 0,
    qualifyingMonthlyIncome: math.max(0, qualifyingMonthlyIncome),
    creditLabel: tier.label,
    reason: reason,
  );

  if (!bankLoanTermMonths.contains(termMonths)) {
    return denied('대출 기간은 12개월, 24개월, 36개월 중에서 선택해야 합니다.');
  }
  if (!isAdult) return denied('만 20세부터 본인 신용대출을 신청할 수 있습니다.');
  if (hasDelinquency) return denied('연체 또는 결손채무를 먼저 정리해야 합니다.');
  if (!tier.eligible) return denied('신용점수 600점부터 신규 대출을 신청할 수 있습니다.');
  if (qualifyingMonthlyIncome <= 0) {
    return denied('확인 가능한 반복 월소득이 없어 대출 한도가 없습니다.');
  }

  final grossCreditLimit = qualifyingMonthlyIncome * tier.incomeMultiple;
  final availableByCredit = math.max(
    0,
    grossCreditLimit - existingUnsecuredBalance,
  );
  final maximumTotalMonthlyDebt =
      (qualifyingMonthlyIncome * bankMaximumDsrRate).floor();
  final availableMonthlyPayment = math.max(
    0,
    maximumTotalMonthlyDebt - existingMonthlyDebtService,
  );
  final availableByDsr = bankPrincipalForMonthlyPayment(
    availableMonthlyPayment,
    annualInterestRate,
    termMonths,
  );
  final maximumPrincipal = math.min(availableByCredit, availableByDsr);
  if (maximumPrincipal <= 0) {
    return denied('기존 원리금을 포함한 DSR 40% 한도에 여유가 없습니다.');
  }
  return BankLoanOffer(
    eligible: true,
    maximumPrincipal: maximumPrincipal,
    annualInterestRate: annualInterestRate,
    termMonths: termMonths,
    maximumMonthlyPayment: availableMonthlyPayment,
    qualifyingMonthlyIncome: qualifyingMonthlyIncome,
    creditLabel: tier.label,
    reason: '',
  );
}

class BankTermDeposit {
  const BankTermDeposit({
    required this.id,
    required this.principal,
    required this.annualInterestRate,
    required this.openedDay,
    required this.maturityDay,
    required this.termMonths,
  });

  final String id;
  final int principal;
  final double annualInterestRate;
  final int openedDay;
  final int maturityDay;
  final int termMonths;

  bool maturedAt(int day) => day >= maturityDay;

  int _interestDaysAt(int day) =>
      (day.clamp(openedDay, maturityDay) - openedDay).clamp(
        0,
        math.max(0, maturityDay - openedDay),
      ).toInt();

  int grossInterestAt(int day) =>
      (principal * annualInterestRate * _interestDaysAt(day) / 365).round();

  int withholdingTaxAt(int day) =>
      (grossInterestAt(day) * bankInterestWithholdingTaxRate).round();

  int netInterestAt(int day) =>
      math.max(0, grossInterestAt(day) - withholdingTaxAt(day));

  int assetValueAt(int day) => principal + netInterestAt(day);

  int earlyRedemptionInterestAt(int day) {
    if (maturedAt(day)) return netInterestAt(day);
    final elapsedDays = math.max(0, day - openedDay);
    if (elapsedDays < 30) return 0;
    final earlyAnnualRate = annualInterestRate * 0.20;
    final gross = (principal * earlyAnnualRate * elapsedDays / 365).round();
    final tax = (gross * bankInterestWithholdingTaxRate).round();
    return math.max(0, gross - tax);
  }

  int redemptionAmountAt(int day) =>
      principal +
      (maturedAt(day) ? netInterestAt(day) : earlyRedemptionInterestAt(day));

  Map<String, dynamic> toJson() => {
    'id': id,
    'principal': principal,
    'annualInterestRate': annualInterestRate,
    'openedDay': openedDay,
    'maturityDay': maturityDay,
    'termMonths': termMonths,
  };

  factory BankTermDeposit.fromJson(Map<String, dynamic> json) =>
      BankTermDeposit(
        id: json['id'] as String? ?? '',
        principal: math.max(0, (json['principal'] as num?)?.toInt() ?? 0),
        annualInterestRate: math.max(
          0,
          (json['annualInterestRate'] as num?)?.toDouble() ?? 0,
        ),
        openedDay: math.max(1, (json['openedDay'] as num?)?.toInt() ?? 1),
        maturityDay: math.max(
          1,
          (json['maturityDay'] as num?)?.toInt() ?? 1,
        ),
        termMonths: (json['termMonths'] as num?)?.toInt() ?? 0,
      );
}

class BankUnsecuredLoan {
  const BankUnsecuredLoan({
    required this.id,
    required this.originalPrincipal,
    required this.balance,
    required this.annualInterestRate,
    required this.termMonths,
    required this.remainingMonths,
    required this.scheduledMonthlyPayment,
    required this.nextPaymentDay,
    required this.consecutiveMissedPayments,
    required this.totalMissedPayments,
  });

  final String id;
  final int originalPrincipal;
  final int balance;
  final double annualInterestRate;
  final int termMonths;
  final int remainingMonths;
  final int scheduledMonthlyPayment;
  final int nextPaymentDay;
  final int consecutiveMissedPayments;
  final int totalMissedPayments;

  int get nextInterest {
    if (balance <= 0 || annualInterestRate <= 0) return 0;
    return math.max(1, (balance * annualInterestRate / 12).round());
  }

  int get dueAmount {
    if (balance <= 0) return 0;
    return math.min(
      balance + nextInterest,
      math.max(scheduledMonthlyPayment, nextInterest + 1),
    );
  }

  bool dueAt(int day) => balance > 0 && day >= nextPaymentDay;

  BankUnsecuredLoan recordScheduledPayment(int followingPaymentDay) {
    if (balance <= 0) return this;
    final principalPaid = (dueAmount - nextInterest).clamp(0, balance).toInt();
    return copyWith(
      balance: balance - principalPaid,
      remainingMonths: math.max(0, remainingMonths - 1),
      nextPaymentDay: followingPaymentDay,
      consecutiveMissedPayments: 0,
    );
  }

  BankUnsecuredLoan recordMissedPayment(int followingPaymentDay) {
    if (balance <= 0) return this;
    final lateFee = math.max(1, (balance * 0.005).round());
    return copyWith(
      balance: balance + nextInterest + lateFee,
      nextPaymentDay: followingPaymentDay,
      consecutiveMissedPayments: consecutiveMissedPayments + 1,
      totalMissedPayments: totalMissedPayments + 1,
    );
  }

  BankUnsecuredLoan repayPrincipal(int amount) =>
      copyWith(balance: math.max(0, balance - amount));

  BankUnsecuredLoan copyWith({
    int? balance,
    int? remainingMonths,
    int? nextPaymentDay,
    int? consecutiveMissedPayments,
    int? totalMissedPayments,
  }) => BankUnsecuredLoan(
    id: id,
    originalPrincipal: originalPrincipal,
    balance: balance ?? this.balance,
    annualInterestRate: annualInterestRate,
    termMonths: termMonths,
    remainingMonths: remainingMonths ?? this.remainingMonths,
    scheduledMonthlyPayment: scheduledMonthlyPayment,
    nextPaymentDay: nextPaymentDay ?? this.nextPaymentDay,
    consecutiveMissedPayments:
        consecutiveMissedPayments ?? this.consecutiveMissedPayments,
    totalMissedPayments: totalMissedPayments ?? this.totalMissedPayments,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalPrincipal': originalPrincipal,
    'balance': balance,
    'annualInterestRate': annualInterestRate,
    'termMonths': termMonths,
    'remainingMonths': remainingMonths,
    'scheduledMonthlyPayment': scheduledMonthlyPayment,
    'nextPaymentDay': nextPaymentDay,
    'consecutiveMissedPayments': consecutiveMissedPayments,
    'totalMissedPayments': totalMissedPayments,
  };

  factory BankUnsecuredLoan.fromJson(Map<String, dynamic> json) =>
      BankUnsecuredLoan(
        id: json['id'] as String? ?? '',
        originalPrincipal: math.max(
          0,
          (json['originalPrincipal'] as num?)?.toInt() ?? 0,
        ),
        balance: math.max(0, (json['balance'] as num?)?.toInt() ?? 0),
        annualInterestRate: math.max(
          0,
          (json['annualInterestRate'] as num?)?.toDouble() ?? 0,
        ),
        termMonths: math.max(
          0,
          (json['termMonths'] as num?)?.toInt() ?? 0,
        ),
        remainingMonths: math.max(
          0,
          (json['remainingMonths'] as num?)?.toInt() ?? 0,
        ),
        scheduledMonthlyPayment: math.max(
          0,
          (json['scheduledMonthlyPayment'] as num?)?.toInt() ?? 0,
        ),
        nextPaymentDay: math.max(
          1,
          (json['nextPaymentDay'] as num?)?.toInt() ?? 1,
        ),
        consecutiveMissedPayments: math.max(
          0,
          (json['consecutiveMissedPayments'] as num?)?.toInt() ?? 0,
        ),
        totalMissedPayments: math.max(
          0,
          (json['totalMissedPayments'] as num?)?.toInt() ?? 0,
        ),
      );
}

class BankingState {
  const BankingState({
    required this.creditScore,
    required this.nextContractSequence,
    required this.termDeposits,
    required this.unsecuredLoans,
    required this.successfulPaymentMonths,
    required this.missedPaymentMonths,
  });

  factory BankingState.initial({int creditScore = bankInitialCreditScore}) =>
      BankingState(
        creditScore: creditScore.clamp(
          bankMinimumCreditScore,
          bankMaximumCreditScore,
        ).toInt(),
        nextContractSequence: 1,
        termDeposits: const [],
        unsecuredLoans: const [],
        successfulPaymentMonths: 0,
        missedPaymentMonths: 0,
      );

  final int creditScore;
  final int nextContractSequence;
  final List<BankTermDeposit> termDeposits;
  final List<BankUnsecuredLoan> unsecuredLoans;
  final int successfulPaymentMonths;
  final int missedPaymentMonths;

  int termDepositAssetValueAt(int day) => termDeposits.fold<int>(
    0,
    (sum, deposit) => sum + deposit.assetValueAt(day),
  );

  int get totalUnsecuredLoanBalance => unsecuredLoans.fold<int>(
    0,
    (sum, loan) => sum + loan.balance,
  );

  int get monthlyUnsecuredDebtService => unsecuredLoans.fold<int>(
    0,
    (sum, loan) => sum + loan.dueAmount,
  );

  bool get hasDelinquentLoan =>
      unsecuredLoans.any((loan) => loan.consecutiveMissedPayments > 0);

  BankingState copyWith({
    int? creditScore,
    int? nextContractSequence,
    List<BankTermDeposit>? termDeposits,
    List<BankUnsecuredLoan>? unsecuredLoans,
    int? successfulPaymentMonths,
    int? missedPaymentMonths,
  }) => BankingState(
    creditScore: (creditScore ?? this.creditScore).clamp(
      bankMinimumCreditScore,
      bankMaximumCreditScore,
    ).toInt(),
    nextContractSequence:
        nextContractSequence ?? this.nextContractSequence,
    termDeposits: termDeposits ?? this.termDeposits,
    unsecuredLoans: unsecuredLoans ?? this.unsecuredLoans,
    successfulPaymentMonths:
        successfulPaymentMonths ?? this.successfulPaymentMonths,
    missedPaymentMonths: missedPaymentMonths ?? this.missedPaymentMonths,
  );

  Map<String, dynamic> toJson() => {
    'creditScore': creditScore,
    'nextContractSequence': nextContractSequence,
    'termDeposits': termDeposits.map((deposit) => deposit.toJson()).toList(),
    'unsecuredLoans': unsecuredLoans.map((loan) => loan.toJson()).toList(),
    'successfulPaymentMonths': successfulPaymentMonths,
    'missedPaymentMonths': missedPaymentMonths,
  };

  factory BankingState.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return BankingState.initial();
    return BankingState(
      creditScore: ((json['creditScore'] as num?)?.toInt() ??
              bankInitialCreditScore)
          .clamp(bankMinimumCreditScore, bankMaximumCreditScore)
          .toInt(),
      nextContractSequence: math.max(
        1,
        (json['nextContractSequence'] as num?)?.toInt() ?? 1,
      ),
      termDeposits: ((json['termDeposits'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                BankTermDeposit.fromJson(item.cast<String, dynamic>()),
          )
          .where(
            (deposit) =>
                deposit.id.isNotEmpty &&
                deposit.principal > 0 &&
                deposit.maturityDay > deposit.openedDay,
          )
          .toList(growable: false),
      unsecuredLoans: ((json['unsecuredLoans'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                BankUnsecuredLoan.fromJson(item.cast<String, dynamic>()),
          )
          .where((loan) => loan.id.isNotEmpty && loan.balance > 0)
          .toList(growable: false),
      successfulPaymentMonths: math.max(
        0,
        (json['successfulPaymentMonths'] as num?)?.toInt() ?? 0,
      ),
      missedPaymentMonths: math.max(
        0,
        (json['missedPaymentMonths'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
