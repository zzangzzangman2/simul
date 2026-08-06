const cohortInvestmentMinBalance = 0;
const cohortInvestmentInitialBalance = 50000;
const cohortInvestmentMaxMoney = 9007199254740991;
const cohortLoanTermDays = 7;
const cohortLoanInterestRateBps = 1200;
const cohortPlayerRecoveryCashThreshold = 10000;
const cohortPlayerBorrowingLimit = 30000;
const cohortNpcEmergencyReserve = 10000;
// Keep a complete leap-year trading tail so the year-end archive never loses
// the first sessions of a 261/262-session year before it is summarized.
const cohortInvestmentHistoryLimit = 270;
// Daily roll call includes weekends, so keep a little more than a full year.
// The current month's total can always be reconstructed without growing saves
// for the entire ten-year campaign.
const cohortRollCallHistoryLimit = 400;

enum CohortLoanDirection { playerLends, playerBorrows }

class CohortInvestorProfile {
  const CohortInvestorProfile({
    required this.id,
    required this.name,
    required this.style,
    required this.investmentRatioBps,
    required this.accentValue,
  });

  final String id;
  final String name;
  final String style;
  final int investmentRatioBps;
  final int accentValue;
}

const cohortNpcInvestorProfiles = <CohortInvestorProfile>[
  CohortInvestorProfile(
    id: 'kim_hakjun',
    name: '김학준',
    style: '규칙과 손실 한도를 먼저 확인',
    investmentRatioBps: 5500,
    accentValue: 0xFF5D7FA3,
  ),
  CohortInvestorProfile(
    id: 'kim_seoa',
    name: '김서아',
    style: '기록이 이어지는 안정적인 회사 선호',
    investmentRatioBps: 4500,
    accentValue: 0xFFF38B96,
  ),
  CohortInvestorProfile(
    id: 'lee_jian',
    name: '이지안',
    style: '제품과 작동 원리를 직접 확인',
    investmentRatioBps: 7000,
    accentValue: 0xFF77BCE8,
  ),
  CohortInvestorProfile(
    id: 'choi_iseo',
    name: '최이서',
    style: '생활에서 체감한 제품과 취향 중시',
    investmentRatioBps: 5000,
    accentValue: 0xFFB58CE8,
  ),
  CohortInvestorProfile(
    id: 'jung_arin',
    name: '정아린',
    style: '계획과 실행력이 분명한 회사 선호',
    investmentRatioBps: 6500,
    accentValue: 0xFFFF9466,
  ),
  CohortInvestorProfile(
    id: 'park_haeun',
    name: '박하은',
    style: '사람과 조직을 오래 지키는 회사 관찰',
    investmentRatioBps: 5000,
    accentValue: 0xFFFF7F9B,
  ),
  CohortInvestorProfile(
    id: 'han_sua',
    name: '한수아',
    style: '새 가능성과 사람들의 반응에 빠르게 진입',
    investmentRatioBps: 7500,
    accentValue: 0xFFFF6F91,
  ),
  CohortInvestorProfile(
    id: 'oh_jiwoo',
    name: '오지우',
    style: '시장 가설을 세우고 반대 사례에 도전',
    investmentRatioBps: 8500,
    accentValue: 0xFF45B7A7,
  ),
  CohortInvestorProfile(
    id: 'yoon_chaea',
    name: '윤채아',
    style: '가격보다 장기 구조와 다음 단계를 계산',
    investmentRatioBps: 6000,
    accentValue: 0xFF727FBE,
  ),
];

CohortInvestorProfile? cohortNpcInvestorProfileById(String id) {
  for (final profile in cohortNpcInvestorProfiles) {
    if (profile.id == id) return profile;
  }
  return null;
}

class CohortInvestorAccount {
  const CohortInvestorAccount({
    required this.investorId,
    required this.balance,
  });

  final String investorId;
  final int balance;

  CohortInvestorAccount copyWith({int? balance}) => CohortInvestorAccount(
    investorId: investorId,
    balance: (balance ?? this.balance).clamp(
      cohortInvestmentMinBalance,
      cohortInvestmentMaxMoney,
    ),
  );

  Map<String, dynamic> toJson() => {
    'investorId': investorId,
    'balance': balance,
  };

  factory CohortInvestorAccount.fromJson(Map<String, dynamic> json) {
    final investorId = json['investorId'] as String? ?? '';
    return CohortInvestorAccount(
      investorId: investorId,
      balance:
          ((json['balance'] as num?)?.toInt() ?? cohortInvestmentInitialBalance)
              .clamp(cohortInvestmentMinBalance, cohortInvestmentMaxMoney),
    );
  }
}

class CohortDailyInvestmentResult {
  const CohortDailyInvestmentResult({
    required this.investorId,
    required this.name,
    required this.assetId,
    required this.assetName,
    required this.investedAmount,
    required this.profitLoss,
    required this.totalAmount,
    required this.traded,
    required this.isPlayer,
    this.cumulativeProfitLoss = 0,
    this.stateRecovery = 0,
  });

  final String investorId;
  final String name;
  final String assetId;
  final String assetName;
  final int investedAmount;
  final int profitLoss;
  final int totalAmount;
  final bool traded;
  final bool isPlayer;
  final int cumulativeProfitLoss;
  final int stateRecovery;

  /// 국가원금 50,000원 대비 누적 수익률이다. 열 명이 같은 분모를 쓰고
  /// `cumulativeProfitLoss`가 증권계좌 입출금을 이미 걸러낸 값이므로, 회사 통장에서
  /// 돈을 옮겨 순위를 사는 일이 생기지 않는다.
  int get returnRateBps =>
      (cumulativeProfitLoss * 10000 / cohortInvestmentInitialBalance).round();

  CohortDailyInvestmentResult copyWith({int? totalAmount}) =>
      CohortDailyInvestmentResult(
        investorId: investorId,
        name: name,
        assetId: assetId,
        assetName: assetName,
        investedAmount: investedAmount,
        profitLoss: profitLoss,
        totalAmount: (totalAmount ?? this.totalAmount).clamp(
          cohortInvestmentMinBalance,
          cohortInvestmentMaxMoney,
        ),
        traded: traded,
        isPlayer: isPlayer,
        cumulativeProfitLoss: cumulativeProfitLoss,
        stateRecovery: stateRecovery,
      );

  Map<String, dynamic> toJson() => {
    'investorId': investorId,
    'name': name,
    'assetId': assetId,
    'assetName': assetName,
    'investedAmount': investedAmount,
    'profitLoss': profitLoss,
    'totalAmount': totalAmount,
    'traded': traded,
    'isPlayer': isPlayer,
    'cumulativeProfitLoss': cumulativeProfitLoss,
    'stateRecovery': stateRecovery,
  };

  factory CohortDailyInvestmentResult.fromJson(Map<String, dynamic> json) =>
      CohortDailyInvestmentResult(
        investorId: json['investorId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        assetId: json['assetId'] as String? ?? '',
        assetName: json['assetName'] as String? ?? '거래 없음',
        investedAmount: ((json['investedAmount'] as num?)?.toInt() ?? 0).clamp(
          0,
          cohortInvestmentMaxMoney,
        ),
        profitLoss: ((json['profitLoss'] as num?)?.toInt() ?? 0).clamp(
          -cohortInvestmentMaxMoney,
          cohortInvestmentMaxMoney,
        ),
        totalAmount: ((json['totalAmount'] as num?)?.toInt() ?? 0).clamp(
          cohortInvestmentMinBalance,
          cohortInvestmentMaxMoney,
        ),
        traded: json['traded'] == true,
        isPlayer: json['isPlayer'] == true,
        cumulativeProfitLoss:
            ((json['cumulativeProfitLoss'] as num?)?.toInt() ??
                    (json['isPlayer'] == true
                        ? 0
                        : ((json['totalAmount'] as num?)?.toInt() ??
                                  cohortInvestmentInitialBalance) -
                              cohortInvestmentInitialBalance))
                .clamp(-cohortInvestmentMaxMoney, cohortInvestmentMaxMoney),
        stateRecovery: ((json['stateRecovery'] as num?)?.toInt() ?? 0).clamp(
          0,
          cohortInvestmentMaxMoney,
        ),
      );
}

class CohortDailyInvestmentReport {
  const CohortDailyInvestmentReport({
    required this.day,
    required this.rows,
    this.repaymentTotal = 0,
    this.borrowingRepaymentTotal = 0,
    this.loanInterestIncome = 0,
    this.loanInterestExpense = 0,
  });

  final int day;
  final List<CohortDailyInvestmentResult> rows;
  final int repaymentTotal;
  final int borrowingRepaymentTotal;
  final int loanInterestIncome;
  final int loanInterestExpense;

  /// 순위 기준은 국가원금 대비 누적 수익률이다. 총금액으로 세우면 증권계좌 입금액이
  /// 큰 사람이 실력과 무관하게 위로 올라간다.
  List<CohortDailyInvestmentResult> get rankedRows {
    final sorted = [...rows]
      ..sort((left, right) {
        final rateOrder = right.returnRateBps.compareTo(left.returnRateBps);
        if (rateOrder != 0) return rateOrder;
        final profitOrder = right.cumulativeProfitLoss.compareTo(
          left.cumulativeProfitLoss,
        );
        if (profitOrder != 0) return profitOrder;
        return left.investorId.compareTo(right.investorId);
      });
    return List<CohortDailyInvestmentResult>.unmodifiable(sorted);
  }

  CohortDailyInvestmentResult? resultFor(String investorId) {
    for (final row in rows) {
      if (row.investorId == investorId) return row;
    }
    return null;
  }

  CohortDailyInvestmentReport copyWith({
    List<CohortDailyInvestmentResult>? rows,
    int? repaymentTotal,
    int? borrowingRepaymentTotal,
    int? loanInterestIncome,
    int? loanInterestExpense,
  }) => CohortDailyInvestmentReport(
    day: day,
    rows: rows ?? this.rows,
    repaymentTotal: repaymentTotal ?? this.repaymentTotal,
    borrowingRepaymentTotal:
        borrowingRepaymentTotal ?? this.borrowingRepaymentTotal,
    loanInterestIncome: loanInterestIncome ?? this.loanInterestIncome,
    loanInterestExpense: loanInterestExpense ?? this.loanInterestExpense,
  );

  Map<String, dynamic> toJson() => {
    'day': day,
    'rows': rows.map((row) => row.toJson()).toList(),
    'repaymentTotal': repaymentTotal,
    'borrowingRepaymentTotal': borrowingRepaymentTotal,
    'loanInterestIncome': loanInterestIncome,
    'loanInterestExpense': loanInterestExpense,
  };

  factory CohortDailyInvestmentReport.fromJson(
    Map<String, dynamic> json,
  ) => CohortDailyInvestmentReport(
    day: ((json['day'] as num?)?.toInt() ?? 1).clamp(1, 0x7fffffff),
    rows: ((json['rows'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (row) =>
              CohortDailyInvestmentResult.fromJson(row.cast<String, dynamic>()),
        )
        .where((row) => row.investorId.isNotEmpty)
        .toList(growable: false),
    repaymentTotal: ((json['repaymentTotal'] as num?)?.toInt() ?? 0).clamp(
      0,
      cohortInvestmentMaxMoney,
    ),
    borrowingRepaymentTotal:
        ((json['borrowingRepaymentTotal'] as num?)?.toInt() ?? 0).clamp(
          0,
          cohortInvestmentMaxMoney,
        ),
    loanInterestIncome: ((json['loanInterestIncome'] as num?)?.toInt() ?? 0)
        .clamp(0, cohortInvestmentMaxMoney),
    loanInterestExpense: ((json['loanInterestExpense'] as num?)?.toInt() ?? 0)
        .clamp(0, cohortInvestmentMaxMoney),
  );
}

/// One person's whole-day result announced at the 20:00 roll call.
///
/// Stock is kept separate from casino/horse-racing profit, while deposits,
/// property, businesses, work and loan interest are grouped into other funds.
/// The afternoon activity also records a deliberate skip. Principal transfers
/// are not profit.
class CohortDailyRollCallRow {
  const CohortDailyRollCallRow({
    required this.investorId,
    required this.name,
    required this.stockProfitLoss,
    required this.leisureProfitLoss,
    required this.otherProfitLoss,
    required this.leisureActivity,
    required this.isPlayer,
    this.afternoonStake = 0,
    this.afternoonGrossPayout = 0,
    this.afternoonStateRecovery = 0,
  });

  final String investorId;
  final String name;
  final int stockProfitLoss;
  final int leisureProfitLoss;
  final int otherProfitLoss;

  /// `카지노`, `경마`, `예금·은행`, `부동산`, `그냥 넘어감`, `미참여` or
  /// `자금 부족`. A row never contains two activities because everybody gets
  /// the same single afternoon slot.
  final String leisureActivity;
  final bool isPlayer;
  final int afternoonStake;
  final int afternoonGrossPayout;
  final int afternoonStateRecovery;

  int get dailyProfitLoss =>
      (stockProfitLoss + leisureProfitLoss + otherProfitLoss).clamp(
        -cohortInvestmentMaxMoney,
        cohortInvestmentMaxMoney,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'investorId': investorId,
    'name': name,
    'stockProfitLoss': stockProfitLoss,
    'leisureProfitLoss': leisureProfitLoss,
    'otherProfitLoss': otherProfitLoss,
    'leisureActivity': leisureActivity,
    'isPlayer': isPlayer,
    'afternoonStake': afternoonStake,
    'afternoonGrossPayout': afternoonGrossPayout,
    'afternoonStateRecovery': afternoonStateRecovery,
  };

  factory CohortDailyRollCallRow.fromJson(Map<String, dynamic> json) =>
      CohortDailyRollCallRow(
        investorId: json['investorId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        stockProfitLoss: ((json['stockProfitLoss'] as num?)?.toInt() ?? 0)
            .clamp(-cohortInvestmentMaxMoney, cohortInvestmentMaxMoney),
        leisureProfitLoss: ((json['leisureProfitLoss'] as num?)?.toInt() ?? 0)
            .clamp(-cohortInvestmentMaxMoney, cohortInvestmentMaxMoney),
        otherProfitLoss: ((json['otherProfitLoss'] as num?)?.toInt() ?? 0)
            .clamp(-cohortInvestmentMaxMoney, cohortInvestmentMaxMoney),
        leisureActivity: json['leisureActivity'] as String? ?? '미참여',
        isPlayer: json['isPlayer'] == true,
        afternoonStake: ((json['afternoonStake'] as num?)?.toInt() ?? 0).clamp(
          0,
          cohortInvestmentMaxMoney,
        ),
        afternoonGrossPayout:
            ((json['afternoonGrossPayout'] as num?)?.toInt() ?? 0).clamp(
              0,
              cohortInvestmentMaxMoney,
            ),
        afternoonStateRecovery:
            ((json['afternoonStateRecovery'] as num?)?.toInt() ?? 0).clamp(
              0,
              cohortInvestmentMaxMoney,
            ),
      );
}

class CohortDailyRollCallReport {
  const CohortDailyRollCallReport({required this.day, required this.rows});

  final int day;
  final List<CohortDailyRollCallRow> rows;

  /// The evening announcement is deliberately a daily-money ranking. Monthly
  /// profit is shown beside it as context, but does not rewrite today's order.
  List<CohortDailyRollCallRow> get rankedRows {
    final sorted = <CohortDailyRollCallRow>[...rows]
      ..sort((left, right) {
        final dailyOrder = right.dailyProfitLoss.compareTo(
          left.dailyProfitLoss,
        );
        if (dailyOrder != 0) return dailyOrder;
        return left.investorId.compareTo(right.investorId);
      });
    return List<CohortDailyRollCallRow>.unmodifiable(sorted);
  }

  CohortDailyRollCallRow? resultFor(String investorId) {
    for (final row in rows) {
      if (row.investorId == investorId) return row;
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'day': day,
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
  };

  factory CohortDailyRollCallReport.fromJson(Map<String, dynamic> json) =>
      CohortDailyRollCallReport(
        day: ((json['day'] as num?)?.toInt() ?? 1).clamp(1, 0x7fffffff),
        rows: ((json['rows'] as List?) ?? const <dynamic>[])
            .whereType<Map>()
            .map(
              (row) =>
                  CohortDailyRollCallRow.fromJson(row.cast<String, dynamic>()),
            )
            .where((row) => row.investorId.isNotEmpty)
            .toList(growable: false),
      );
}

class CohortLoan {
  const CohortLoan({
    required this.id,
    required this.borrowerId,
    required this.borrowerName,
    required this.issuedDay,
    required this.dueDay,
    required this.principal,
    this.direction = CohortLoanDirection.playerLends,
    this.interestRateBps = cohortLoanInterestRateBps,
    this.repaidAmount = 0,
  });

  final String id;
  final String borrowerId;
  final String borrowerName;
  final int issuedDay;
  final int dueDay;
  final int principal;
  final CohortLoanDirection direction;
  final int interestRateBps;
  final int repaidAmount;

  int get interest => (principal * interestRateBps / 10000).ceil().clamp(
    0,
    cohortInvestmentMaxMoney,
  );
  int get totalDue => (principal + interest).clamp(0, cohortInvestmentMaxMoney);
  int get outstanding =>
      (totalDue - repaidAmount).clamp(0, cohortInvestmentMaxMoney);
  int get outstandingInterest => (interest - repaidAmount).clamp(0, interest);
  int get outstandingPrincipal =>
      (principal - (repaidAmount - interest).clamp(0, principal)).clamp(
        0,
        principal,
      );
  bool get isRepaid => outstanding == 0;

  CohortLoan copyWith({int? repaidAmount}) => CohortLoan(
    id: id,
    borrowerId: borrowerId,
    borrowerName: borrowerName,
    issuedDay: issuedDay,
    dueDay: dueDay,
    principal: principal,
    direction: direction,
    interestRateBps: interestRateBps,
    repaidAmount: (repaidAmount ?? this.repaidAmount).clamp(0, totalDue),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'borrowerId': borrowerId,
    'borrowerName': borrowerName,
    'issuedDay': issuedDay,
    'dueDay': dueDay,
    'principal': principal,
    'direction': direction.name,
    'interestRateBps': interestRateBps,
    'repaidAmount': repaidAmount,
  };

  factory CohortLoan.fromJson(Map<String, dynamic> json) {
    final principal = ((json['principal'] as num?)?.toInt() ?? 0).clamp(
      0,
      cohortInvestmentMaxMoney,
    );
    return CohortLoan(
      id: json['id'] as String? ?? '',
      borrowerId: json['borrowerId'] as String? ?? '',
      borrowerName: json['borrowerName'] as String? ?? '',
      issuedDay: ((json['issuedDay'] as num?)?.toInt() ?? 1).clamp(
        1,
        0x7fffffff,
      ),
      dueDay: ((json['dueDay'] as num?)?.toInt() ?? 1).clamp(1, 0x7fffffff),
      principal: principal,
      direction: CohortLoanDirection.values.firstWhere(
        (value) => value.name == json['direction'],
        orElse: () => CohortLoanDirection.playerLends,
      ),
      interestRateBps: ((json['interestRateBps'] as num?)?.toInt() ?? 0).clamp(
        0,
        10000,
      ),
      repaidAmount: ((json['repaidAmount'] as num?)?.toInt() ?? 0).clamp(
        0,
        cohortInvestmentMaxMoney,
      ),
    );
  }
}

class CohortInvestmentState {
  const CohortInvestmentState({
    required this.accounts,
    required this.reports,
    required this.loans,
    required this.lastSettledDay,
    required this.lastAcknowledgedDay,
    required this.lastLoanDay,
    this.rollCallReports = const <CohortDailyRollCallReport>[],
    this.previousPlayerCloseTotal,
    this.playerCumulativeProfitLoss = 0,
  });

  factory CohortInvestmentState.initial() => CohortInvestmentState(
    accounts: {
      for (final profile in cohortNpcInvestorProfiles)
        profile.id: CohortInvestorAccount(
          investorId: profile.id,
          balance: cohortInvestmentInitialBalance,
        ),
    },
    reports: const [],
    loans: const [],
    lastSettledDay: -1,
    lastAcknowledgedDay: -1,
    lastLoanDay: -1,
    rollCallReports: const <CohortDailyRollCallReport>[],
  );

  final Map<String, CohortInvestorAccount> accounts;
  final List<CohortDailyInvestmentReport> reports;
  final List<CohortLoan> loans;
  final int lastSettledDay;
  final int lastAcknowledgedDay;
  final int lastLoanDay;
  final List<CohortDailyRollCallReport> rollCallReports;
  final int? previousPlayerCloseTotal;
  final int playerCumulativeProfitLoss;

  bool settledForDay(int day) => lastSettledDay == day;
  bool acknowledgedForDay(int day) => lastAcknowledgedDay == day;
  bool loanedForDay(int day) => lastLoanDay == day;

  CohortInvestorAccount accountFor(String investorId) =>
      accounts[investorId] ??
      CohortInvestorAccount(
        investorId: investorId,
        balance: cohortInvestmentInitialBalance,
      );

  CohortDailyInvestmentReport? reportForDay(int day) {
    for (final report in reports.reversed) {
      if (report.day == day) return report;
    }
    return null;
  }

  CohortDailyRollCallReport? rollCallReportForDay(int day) {
    for (final report in rollCallReports.reversed) {
      if (report.day == day) return report;
    }
    return null;
  }

  int get outstandingLoanReceivables => loans.fold<int>(
    0,
    (sum, loan) => loan.direction == CohortLoanDirection.playerLends
        ? (sum + loan.outstandingPrincipal).clamp(0, cohortInvestmentMaxMoney)
        : sum,
  );

  int get outstandingLoanPayables => loans.fold<int>(
    0,
    (sum, loan) => loan.direction == CohortLoanDirection.playerBorrows
        ? (sum + loan.outstanding).clamp(0, cohortInvestmentMaxMoney)
        : sum,
  );

  bool get hasOutstandingPlayerBorrowing => loans.any(
    (loan) =>
        loan.direction == CohortLoanDirection.playerBorrows && !loan.isRepaid,
  );

  CohortInvestmentState copyWith({
    Map<String, CohortInvestorAccount>? accounts,
    List<CohortDailyInvestmentReport>? reports,
    List<CohortLoan>? loans,
    int? lastSettledDay,
    int? lastAcknowledgedDay,
    int? lastLoanDay,
    List<CohortDailyRollCallReport>? rollCallReports,
    int? previousPlayerCloseTotal,
    int? playerCumulativeProfitLoss,
  }) => CohortInvestmentState(
    accounts: accounts ?? this.accounts,
    reports: reports ?? this.reports,
    loans: loans ?? this.loans,
    lastSettledDay: lastSettledDay ?? this.lastSettledDay,
    lastAcknowledgedDay: lastAcknowledgedDay ?? this.lastAcknowledgedDay,
    lastLoanDay: lastLoanDay ?? this.lastLoanDay,
    rollCallReports: rollCallReports ?? this.rollCallReports,
    previousPlayerCloseTotal:
        previousPlayerCloseTotal ?? this.previousPlayerCloseTotal,
    playerCumulativeProfitLoss:
        playerCumulativeProfitLoss ?? this.playerCumulativeProfitLoss,
  );

  Map<String, dynamic> toJson() => {
    'accounts': {
      for (final entry in accounts.entries) entry.key: entry.value.toJson(),
    },
    'reports': reports.map((report) => report.toJson()).toList(),
    'loans': loans.map((loan) => loan.toJson()).toList(),
    'lastSettledDay': lastSettledDay,
    'lastAcknowledgedDay': lastAcknowledgedDay,
    'lastLoanDay': lastLoanDay,
    'rollCallReports': rollCallReports
        .map((report) => report.toJson())
        .toList(growable: false),
    if (previousPlayerCloseTotal != null)
      'previousPlayerCloseTotal': previousPlayerCloseTotal,
    'playerCumulativeProfitLoss': playerCumulativeProfitLoss,
  };

  factory CohortInvestmentState.fromJson(Map<String, dynamic> json) {
    final validIds = cohortNpcInvestorProfiles
        .map((profile) => profile.id)
        .toSet();
    final rawAccounts = (json['accounts'] as Map?) ?? const {};
    final parsedAccounts = <String, CohortInvestorAccount>{};
    for (final entry in rawAccounts.entries) {
      final id = entry.key.toString();
      if (!validIds.contains(id) || entry.value is! Map) continue;
      parsedAccounts[id] = CohortInvestorAccount.fromJson(
        (entry.value as Map).cast<String, dynamic>(),
      );
    }
    for (final profile in cohortNpcInvestorProfiles) {
      parsedAccounts.putIfAbsent(
        profile.id,
        () => CohortInvestorAccount(
          investorId: profile.id,
          balance: cohortInvestmentInitialBalance,
        ),
      );
    }

    final reports = ((json['reports'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (report) => CohortDailyInvestmentReport.fromJson(
            report.cast<String, dynamic>(),
          ),
        )
        .where((report) => report.rows.length == 10)
        .toList(growable: false);
    final trimmedReports = reports.length <= cohortInvestmentHistoryLimit
        ? reports
        : reports.sublist(reports.length - cohortInvestmentHistoryLimit);
    final loans = ((json['loans'] as List?) ?? const [])
        .whereType<Map>()
        .map((loan) => CohortLoan.fromJson(loan.cast<String, dynamic>()))
        .where(
          (loan) =>
              loan.id.isNotEmpty &&
              validIds.contains(loan.borrowerId) &&
              loan.principal > 0,
        )
        .toList(growable: false);
    final rollCallReports =
        ((json['rollCallReports'] as List?) ?? const <dynamic>[])
            .whereType<Map>()
            .map(
              (report) => CohortDailyRollCallReport.fromJson(
                report.cast<String, dynamic>(),
              ),
            )
            .where((report) => report.rows.length == 10)
            .toList(growable: false);
    final trimmedRollCallReports =
        rollCallReports.length <= cohortRollCallHistoryLimit
        ? rollCallReports
        : rollCallReports.sublist(
            rollCallReports.length - cohortRollCallHistoryLimit,
          );
    final previousPlayerCloseTotal = (json['previousPlayerCloseTotal'] as num?)
        ?.toInt();
    final migratedPlayerCumulativeProfitLoss = trimmedReports.fold<int>(
      0,
      (sum, report) => sum + (report.resultFor('player')?.profitLoss ?? 0),
    );
    return CohortInvestmentState(
      accounts: Map<String, CohortInvestorAccount>.unmodifiable(parsedAccounts),
      reports: List<CohortDailyInvestmentReport>.unmodifiable(trimmedReports),
      loans: List<CohortLoan>.unmodifiable(loans),
      lastSettledDay: (json['lastSettledDay'] as num?)?.toInt() ?? -1,
      lastAcknowledgedDay: (json['lastAcknowledgedDay'] as num?)?.toInt() ?? -1,
      lastLoanDay: (json['lastLoanDay'] as num?)?.toInt() ?? -1,
      rollCallReports: List<CohortDailyRollCallReport>.unmodifiable(
        trimmedRollCallReports,
      ),
      previousPlayerCloseTotal: previousPlayerCloseTotal?.clamp(
        0,
        cohortInvestmentMaxMoney,
      ),
      playerCumulativeProfitLoss:
          ((json['playerCumulativeProfitLoss'] as num?)?.toInt() ??
                  migratedPlayerCumulativeProfitLoss)
              .clamp(-cohortInvestmentMaxMoney, cohortInvestmentMaxMoney),
    );
  }
}
