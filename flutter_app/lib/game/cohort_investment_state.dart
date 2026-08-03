const cohortInvestmentMinBalance = 0;
const cohortInvestmentInitialBalance = 10000;
const cohortInvestmentMaxMoney = 9007199254740991;
const cohortLoanTermDays = 7;
const cohortInvestmentHistoryLimit = 64;

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
      );
}

class CohortDailyInvestmentReport {
  const CohortDailyInvestmentReport({
    required this.day,
    required this.rows,
    this.repaymentTotal = 0,
  });

  final int day;
  final List<CohortDailyInvestmentResult> rows;
  final int repaymentTotal;

  List<CohortDailyInvestmentResult> get rankedRows {
    final sorted = [...rows]
      ..sort((left, right) {
        final totalOrder = right.totalAmount.compareTo(left.totalAmount);
        if (totalOrder != 0) return totalOrder;
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
  }) => CohortDailyInvestmentReport(
    day: day,
    rows: rows ?? this.rows,
    repaymentTotal: repaymentTotal ?? this.repaymentTotal,
  );

  Map<String, dynamic> toJson() => {
    'day': day,
    'rows': rows.map((row) => row.toJson()).toList(),
    'repaymentTotal': repaymentTotal,
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
    this.repaidAmount = 0,
  });

  final String id;
  final String borrowerId;
  final String borrowerName;
  final int issuedDay;
  final int dueDay;
  final int principal;
  final int repaidAmount;

  int get outstanding =>
      (principal - repaidAmount).clamp(0, cohortInvestmentMaxMoney);
  bool get isRepaid => outstanding == 0;

  CohortLoan copyWith({int? repaidAmount}) => CohortLoan(
    id: id,
    borrowerId: borrowerId,
    borrowerName: borrowerName,
    issuedDay: issuedDay,
    dueDay: dueDay,
    principal: principal,
    repaidAmount: (repaidAmount ?? this.repaidAmount).clamp(0, principal),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'borrowerId': borrowerId,
    'borrowerName': borrowerName,
    'issuedDay': issuedDay,
    'dueDay': dueDay,
    'principal': principal,
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
      repaidAmount: ((json['repaidAmount'] as num?)?.toInt() ?? 0).clamp(
        0,
        principal,
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
  );

  final Map<String, CohortInvestorAccount> accounts;
  final List<CohortDailyInvestmentReport> reports;
  final List<CohortLoan> loans;
  final int lastSettledDay;
  final int lastAcknowledgedDay;
  final int lastLoanDay;
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

  int get outstandingLoanReceivables => loans.fold<int>(
    0,
    (sum, loan) => (sum + loan.outstanding).clamp(0, cohortInvestmentMaxMoney),
  );

  CohortInvestmentState copyWith({
    Map<String, CohortInvestorAccount>? accounts,
    List<CohortDailyInvestmentReport>? reports,
    List<CohortLoan>? loans,
    int? lastSettledDay,
    int? lastAcknowledgedDay,
    int? lastLoanDay,
    int? previousPlayerCloseTotal,
    int? playerCumulativeProfitLoss,
  }) => CohortInvestmentState(
    accounts: accounts ?? this.accounts,
    reports: reports ?? this.reports,
    loans: loans ?? this.loans,
    lastSettledDay: lastSettledDay ?? this.lastSettledDay,
    lastAcknowledgedDay: lastAcknowledgedDay ?? this.lastAcknowledgedDay,
    lastLoanDay: lastLoanDay ?? this.lastLoanDay,
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
