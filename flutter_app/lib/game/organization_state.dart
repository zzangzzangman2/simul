import 'story_state.dart';

enum EmployeeGrade { s, a, b, c, d, f }

enum EmployeeRole {
  researcher,
  analyst,
  investmentManager,
  tradingOperations,
  officeAccounting,
  mergersAcquisitions,
  legalCompliance,
  operatingPartner,
}

extension EmployeeGradeLabel on EmployeeGrade {
  String get label => name.toUpperCase();
}

extension EmployeeRoleLabel on EmployeeRole {
  String get label => switch (this) {
    EmployeeRole.researcher => '조사원',
    EmployeeRole.analyst => '애널리스트',
    EmployeeRole.investmentManager => '투자심사역',
    EmployeeRole.tradingOperations => '거래·운영',
    EmployeeRole.officeAccounting => '사무·회계',
    EmployeeRole.mergersAcquisitions => 'M&A 담당',
    EmployeeRole.legalCompliance => '법무·준법',
    EmployeeRole.operatingPartner => '운영 파트너',
  };
}

class EmployeeStats {
  const EmployeeStats({
    required this.analysis,
    required this.valuation,
    required this.accounting,
    required this.negotiation,
    required this.operations,
    required this.risk,
    required this.communication,
    required this.leadership,
  });

  final int analysis;
  final int valuation;
  final int accounting;
  final int negotiation;
  final int operations;
  final int risk;
  final int communication;
  final int leadership;

  Map<String, dynamic> toJson() => {
    'analysis': analysis,
    'valuation': valuation,
    'accounting': accounting,
    'negotiation': negotiation,
    'operations': operations,
    'risk': risk,
    'communication': communication,
    'leadership': leadership,
  };

  factory EmployeeStats.fromJson(Map<String, dynamic> json) => EmployeeStats(
    analysis: (json['analysis'] as num?)?.toInt() ?? 50,
    valuation: (json['valuation'] as num?)?.toInt() ?? 50,
    accounting: (json['accounting'] as num?)?.toInt() ?? 50,
    negotiation: (json['negotiation'] as num?)?.toInt() ?? 50,
    operations: (json['operations'] as num?)?.toInt() ?? 50,
    risk: (json['risk'] as num?)?.toInt() ?? 50,
    communication: (json['communication'] as num?)?.toInt() ?? 50,
    leadership: (json['leadership'] as num?)?.toInt() ?? 50,
  );
}

class EmployeeProfile {
  const EmployeeProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.displayedGrade,
    required this.trueGrade,
    required this.potentialGrade,
    required this.gradeConfidence,
    required this.salaryMonthly,
    required this.morale,
    required this.workload,
    required this.loyalty,
    required this.ethics,
    required this.specialties,
    required this.traits,
    required this.stats,
  });

  final String id;
  final String name;
  final EmployeeRole role;
  final EmployeeGrade displayedGrade;
  final EmployeeGrade trueGrade;
  final EmployeeGrade potentialGrade;
  final int gradeConfidence;
  final int salaryMonthly;
  final int morale;
  final int workload;
  final int loyalty;
  final int ethics;
  final List<String> specialties;
  final List<String> traits;
  final EmployeeStats stats;

  factory EmployeeProfile.legacy(int index) => EmployeeProfile(
    id: 'legacy-team-$index',
    name: '기존 팀원 $index',
    role: EmployeeRole.researcher,
    displayedGrade: EmployeeGrade.c,
    trueGrade: EmployeeGrade.c,
    potentialGrade: EmployeeGrade.b,
    gradeConfidence: 40,
    salaryMonthly: 70000,
    morale: 60,
    workload: 0,
    loyalty: 50,
    ethics: 50,
    specialties: const ['이전 저장에서 복원'],
    traits: const ['정보 확인 필요'],
    stats: const EmployeeStats(
      analysis: 50,
      valuation: 45,
      accounting: 45,
      negotiation: 40,
      operations: 50,
      risk: 45,
      communication: 50,
      leadership: 35,
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.name,
    'displayedGrade': displayedGrade.name,
    'trueGrade': trueGrade.name,
    'potentialGrade': potentialGrade.name,
    'gradeConfidence': gradeConfidence,
    'salaryMonthly': salaryMonthly,
    'morale': morale,
    'workload': workload,
    'loyalty': loyalty,
    'ethics': ethics,
    'specialties': specialties,
    'traits': traits,
    'stats': stats.toJson(),
  };

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    T parseEnum<T extends Enum>(List<T> values, String? name, T fallback) =>
        values.firstWhere(
          (value) => value.name == name,
          orElse: () => fallback,
        );
    return EmployeeProfile(
      id: json['id'] as String? ?? 'employee',
      name: json['name'] as String? ?? '이름 미정',
      role: parseEnum(
        EmployeeRole.values,
        json['role'] as String?,
        EmployeeRole.researcher,
      ),
      displayedGrade: parseEnum(
        EmployeeGrade.values,
        json['displayedGrade'] as String?,
        EmployeeGrade.c,
      ),
      trueGrade: parseEnum(
        EmployeeGrade.values,
        json['trueGrade'] as String?,
        EmployeeGrade.c,
      ),
      potentialGrade: parseEnum(
        EmployeeGrade.values,
        json['potentialGrade'] as String?,
        EmployeeGrade.b,
      ),
      gradeConfidence: (json['gradeConfidence'] as num?)?.toInt() ?? 40,
      salaryMonthly: (json['salaryMonthly'] as num?)?.toInt() ?? 70000,
      morale: (json['morale'] as num?)?.toInt() ?? 60,
      workload: (json['workload'] as num?)?.toInt() ?? 0,
      loyalty: (json['loyalty'] as num?)?.toInt() ?? 50,
      ethics: (json['ethics'] as num?)?.toInt() ?? 50,
      specialties: ((json['specialties'] as List?) ?? const []).cast<String>(),
      traits: ((json['traits'] as List?) ?? const []).cast<String>(),
      stats: EmployeeStats.fromJson(
        (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

const kHiringCandidates = <EmployeeProfile>[
  EmployeeProfile(
    id: 'candidate-hana',
    name: '김하나',
    role: EmployeeRole.researcher,
    displayedGrade: EmployeeGrade.b,
    trueGrade: EmployeeGrade.a,
    potentialGrade: EmployeeGrade.s,
    gradeConfidence: 55,
    salaryMonthly: 80000,
    morale: 72,
    workload: 0,
    loyalty: 64,
    ethics: 88,
    specialties: ['소비재', '현장조사'],
    traits: ['꼼꼼함', '정직함'],
    stats: EmployeeStats(
      analysis: 72,
      valuation: 60,
      accounting: 55,
      negotiation: 62,
      operations: 68,
      risk: 70,
      communication: 76,
      leadership: 52,
    ),
  ),
  EmployeeProfile(
    id: 'candidate-junho',
    name: '박준호',
    role: EmployeeRole.analyst,
    displayedGrade: EmployeeGrade.b,
    trueGrade: EmployeeGrade.b,
    potentialGrade: EmployeeGrade.a,
    gradeConfidence: 70,
    salaryMonthly: 95000,
    morale: 68,
    workload: 0,
    loyalty: 58,
    ethics: 76,
    specialties: ['재무제표', '가치평가'],
    traits: ['수치 중심', '신중함'],
    stats: EmployeeStats(
      analysis: 78,
      valuation: 82,
      accounting: 75,
      negotiation: 48,
      operations: 55,
      risk: 74,
      communication: 57,
      leadership: 51,
    ),
  ),
  EmployeeProfile(
    id: 'candidate-minseo',
    name: '이민서',
    role: EmployeeRole.officeAccounting,
    displayedGrade: EmployeeGrade.c,
    trueGrade: EmployeeGrade.b,
    potentialGrade: EmployeeGrade.a,
    gradeConfidence: 62,
    salaryMonthly: 70000,
    morale: 75,
    workload: 0,
    loyalty: 72,
    ethics: 93,
    specialties: ['회계', '운영'],
    traits: ['원칙주의', '꾸준함'],
    stats: EmployeeStats(
      analysis: 61,
      valuation: 58,
      accounting: 88,
      negotiation: 52,
      operations: 80,
      risk: 81,
      communication: 65,
      leadership: 55,
    ),
  ),
  EmployeeProfile(
    id: 'candidate-doyun',
    name: '최도윤',
    role: EmployeeRole.legalCompliance,
    displayedGrade: EmployeeGrade.a,
    trueGrade: EmployeeGrade.a,
    potentialGrade: EmployeeGrade.s,
    gradeConfidence: 78,
    salaryMonthly: 130000,
    morale: 66,
    workload: 0,
    loyalty: 60,
    ethics: 96,
    specialties: ['준법', '계약'],
    traits: ['독립적', '위험 경계'],
    stats: EmployeeStats(
      analysis: 73,
      valuation: 59,
      accounting: 70,
      negotiation: 75,
      operations: 68,
      risk: 92,
      communication: 71,
      leadership: 63,
    ),
  ),
];

class AcademyHelperStatus {
  const AcademyHelperStatus({
    required this.id,
    required this.name,
    required this.relation,
    required this.role,
    required this.specialty,
    required this.effect,
    required this.asset,
    required this.fatigue,
    required this.helpCount,
    required this.lastHelpDay,
  });

  final String id;
  final String name;
  final String relation;
  final String role;
  final String specialty;
  final String effect;
  final String asset;
  final int fatigue;
  final int helpCount;
  final int? lastHelpDay;

  bool canHelpOn(int day) => fatigue < 80 && lastHelpDay != day;

  AcademyHelperStatus requestHelp(int day) => AcademyHelperStatus(
    id: id,
    name: name,
    relation: relation,
    role: role,
    specialty: specialty,
    effect: effect,
    asset: asset,
    fatigue: (fatigue + 12).clamp(0, 100),
    helpCount: helpCount + 1,
    lastHelpDay: day,
  );

  AcademyHelperStatus recover() => AcademyHelperStatus(
    id: id,
    name: name,
    relation: relation,
    role: role,
    specialty: specialty,
    effect: effect,
    asset: asset,
    fatigue: (fatigue - 3).clamp(0, 100),
    helpCount: helpCount,
    lastHelpDay: lastHelpDay,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relation': relation,
    'role': role,
    'specialty': specialty,
    'effect': effect,
    'asset': asset,
    'fatigue': fatigue,
    'helpCount': helpCount,
    'lastHelpDay': lastHelpDay,
  };

  factory AcademyHelperStatus.fromJson(Map<String, dynamic> json) =>
      AcademyHelperStatus(
        id: json['id'] as String? ?? 'academy-helper',
        name: json['name'] as String? ?? '데시멀 동기 조언자',
        relation: json['relation'] as String? ?? '데시멀 센터 공동체',
        role: json['role'] as String? ?? '도움',
        specialty: json['specialty'] as String? ?? '생활 경험',
        effect: json['effect'] as String? ?? '조사에 도움을 줍니다.',
        asset: json['asset'] as String? ?? '',
        fatigue: (json['fatigue'] as num?)?.toInt() ?? 0,
        helpCount: (json['helpCount'] as num?)?.toInt() ?? 0,
        lastHelpDay: (json['lastHelpDay'] as num?)?.toInt(),
      );
}

class OrganizationState {
  const OrganizationState({
    required this.employees,
    required this.academyHelpers,
    required this.cultureTags,
    required this.helpLog,
  });

  final List<EmployeeProfile> employees;
  final List<AcademyHelperStatus> academyHelpers;
  final List<String> cultureTags;
  final List<String> helpLog;

  int get academyFatigue {
    if (academyHelpers.isEmpty) return 0;
    return (academyHelpers.fold<int>(0, (sum, item) => sum + item.fatigue) /
            academyHelpers.length)
        .round();
  }

  int get researchHelpCount =>
      academyHelpers.fold<int>(0, (sum, item) => sum + item.helpCount);

  int get monthlyPayroll =>
      employees.fold<int>(0, (sum, employee) => sum + employee.salaryMonthly);

  OrganizationState copyWith({
    List<EmployeeProfile>? employees,
    List<AcademyHelperStatus>? academyHelpers,
    List<String>? cultureTags,
    List<String>? helpLog,
  }) => OrganizationState(
    employees: employees ?? this.employees,
    academyHelpers: academyHelpers ?? this.academyHelpers,
    cultureTags: cultureTags ?? this.cultureTags,
    helpLog: helpLog ?? this.helpLog,
  );

  OrganizationState hire(EmployeeProfile candidate, int day) {
    if (employees.any((employee) => employee.id == candidate.id)) return this;
    return copyWith(
      employees: [...employees, candidate],
      helpLog: [...helpLog, 'DAY $day · ${candidate.name} 정식 합류'],
    );
  }

  factory OrganizationState.initial(
    OperatingPrinciple rule,
  ) => OrganizationState(
    employees: const [],
    academyHelpers: const [
      AcademyHelperStatus(
        id: 'hakjun',
        name: '김학준',
        relation: '데시멀 동기',
        role: '규정과 공시 교차검토',
        specialty: '규정 · 위험 · 기록',
        effect: '규정집과 공시를 대조해 빠뜨린 위험 조건을 찾아냅니다.',
        asset:
            'assets/images/production_soft_painted/kim_hakjun/01_neutral_crosscheck_uniform_v4.png',
        fatigue: 8,
        helpCount: 0,
        lastHelpDay: null,
      ),
      AcademyHelperStatus(
        id: 'sua',
        name: '한수아',
        relation: '데시멀 동기',
        role: '고객과 생활 반응 조사',
        specialty: '사람 · 소비 · 인터뷰',
        effect: '숫자 뒤에 있는 고객 표정과 실제 사용 반응을 확인합니다.',
        asset:
            'assets/images/production_soft_painted/han_sua/02_warm_smile_wave_v3.png',
        fatigue: 5,
        helpCount: 0,
        lastHelpDay: null,
      ),
      AcademyHelperStatus(
        id: 'seoyoon',
        name: '한서윤',
        relation: '데시멀 담당 운영관',
        role: '투자노트 점검',
        specialty: '기업분석 · 손실복기 · 준법',
        effect: '매수 이유와 매도 조건이 실제 기록으로 남았는지 점검합니다.',
        asset: 'assets/images/주식선생님/26_포즈5_주인공그림체_공통슬롯_투명.png',
        fatigue: 4,
        helpCount: 0,
        lastHelpDay: null,
      ),
    ],
    cultureTags: [_cultureForRule(rule)],
    helpLog: const [],
  );

  static String _cultureForRule(OperatingPrinciple rule) => switch (rule) {
    OperatingPrinciple.reportLosses => '정직한 보고',
    OperatingPrinciple.noHotTips => '독립 리서치',
    OperatingPrinciple.keepCash => '현금 우선',
  };

  OrganizationState requestAcademyHelp(String helperId, int day) {
    final helper = academyHelpers
        .where((item) => item.id == helperId)
        .firstOrNull;
    if (helper == null || !helper.canHelpOn(day)) return this;
    return OrganizationState(
      employees: employees,
      academyHelpers: academyHelpers
          .map((item) => item.id == helperId ? item.requestHelp(day) : item)
          .toList(growable: false),
      cultureTags: cultureTags,
      helpLog: [...helpLog, 'DAY $day · ${helper.name} · ${helper.effect}'],
    );
  }

  OrganizationState recoverOneDay() => OrganizationState(
    employees: employees,
    academyHelpers: academyHelpers.map((item) => item.recover()).toList(),
    cultureTags: cultureTags,
    helpLog: helpLog,
  );

  Map<String, dynamic> toJson() => {
    'employees': employees.map((item) => item.toJson()).toList(),
    'academyHelpers': academyHelpers.map((item) => item.toJson()).toList(),
    'cultureTags': cultureTags,
    'helpLog': helpLog,
  };

  factory OrganizationState.fromJson(
    Map<String, dynamic> json, {
    required int legacyTeamCount,
    required OperatingPrinciple operatingPrinciple,
  }) {
    if (json.isEmpty) {
      final initial = OrganizationState.initial(operatingPrinciple);
      if (legacyTeamCount <= 1) return initial;
      return OrganizationState(
        employees: List.generate(
          legacyTeamCount - 1,
          (index) => EmployeeProfile.legacy(index + 1),
        ),
        academyHelpers: initial.academyHelpers,
        cultureTags: initial.cultureTags,
        helpLog: const [],
      );
    }
    final academy = OrganizationState.initial(operatingPrinciple);
    return OrganizationState(
      employees: ((json['employees'] as List?) ?? const [])
          .map(
            (item) =>
                EmployeeProfile.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      academyHelpers: academy.academyHelpers,
      cultureTags: ((json['cultureTags'] as List?) ?? const []).cast<String>(),
      helpLog: const [],
    );
  }
}
