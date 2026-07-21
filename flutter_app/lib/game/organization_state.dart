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
    salaryMonthly: 0,
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
      salaryMonthly: (json['salaryMonthly'] as num?)?.toInt() ?? 0,
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

class FamilyHelperStatus {
  const FamilyHelperStatus({
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

  FamilyHelperStatus requestHelp(int day) => FamilyHelperStatus(
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

  FamilyHelperStatus recover() => FamilyHelperStatus(
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

  factory FamilyHelperStatus.fromJson(Map<String, dynamic> json) =>
      FamilyHelperStatus(
        id: json['id'] as String? ?? 'family',
        name: json['name'] as String? ?? '가족',
        relation: json['relation'] as String? ?? '가족',
        role: json['role'] as String? ?? '도움',
        specialty: json['specialty'] as String? ?? '생활 경험',
        effect: json['effect'] as String? ?? '조사에 도움을 줍니다.',
        asset: json['asset'] as String? ?? 'assets/images/character_hero.png',
        fatigue: (json['fatigue'] as num?)?.toInt() ?? 0,
        helpCount: (json['helpCount'] as num?)?.toInt() ?? 0,
        lastHelpDay: (json['lastHelpDay'] as num?)?.toInt(),
      );
}

class OrganizationState {
  const OrganizationState({
    required this.employees,
    required this.familyHelpers,
    required this.cultureTags,
    required this.helpLog,
  });

  final List<EmployeeProfile> employees;
  final List<FamilyHelperStatus> familyHelpers;
  final List<String> cultureTags;
  final List<String> helpLog;

  int get familyFatigue {
    if (familyHelpers.isEmpty) return 0;
    return (familyHelpers.fold<int>(0, (sum, item) => sum + item.fatigue) /
            familyHelpers.length)
        .round();
  }

  int get researchHelpCount =>
      familyHelpers.fold<int>(0, (sum, item) => sum + item.helpCount);

  factory OrganizationState.initial(FamilyRule rule) => OrganizationState(
    employees: const [],
    familyHelpers: const [
      FamilyHelperStatus(
        id: 'mother',
        name: '엄마',
        relation: '보호자·계좌 명의자',
        role: '장부 검토와 주문 승인',
        specialty: '회계 · 현금관리',
        effect: '장부 실수 위험을 낮추고 계좌 규칙을 확인합니다.',
        asset: 'assets/images/character_mother.png',
        fatigue: 8,
        helpCount: 0,
        lastHelpDay: null,
      ),
      FamilyHelperStatus(
        id: 'father',
        name: '아빠',
        relation: '현장 조언자',
        role: '공장과 제품 확인',
        specialty: '제조업 · 납품 · 재고',
        effect: '제조업 종목에서 숫자만으로 보이지 않는 현장 단서를 찾습니다.',
        asset: 'assets/images/character_father.png',
        fatigue: 5,
        helpCount: 0,
        lastHelpDay: null,
      ),
      FamilyHelperStatus(
        id: 'sister',
        name: '누나',
        relation: '소비자 조사 파트너',
        role: '유행과 제품 반응 조사',
        specialty: '인터넷 · 게임 · 음악',
        effect: '또래 소비자 반응과 새로운 유행 단서를 발견합니다.',
        asset: 'assets/images/character_sister.png',
        fatigue: 4,
        helpCount: 0,
        lastHelpDay: null,
      ),
      FamilyHelperStatus(
        id: 'grandfather',
        name: '외할아버지',
        relation: '첫 투자금의 주인',
        role: '장기 투자 원칙 조언',
        specialty: '배당 · 부채 · 현금흐름',
        effect: '가격보다 현금과 부채를 먼저 보는 질문을 추가합니다.',
        asset: 'assets/images/character_grandfather.png',
        fatigue: 3,
        helpCount: 0,
        lastHelpDay: null,
      ),
    ],
    cultureTags: [_cultureForRule(rule)],
    helpLog: const [],
  );

  static String _cultureForRule(FamilyRule rule) => switch (rule) {
    FamilyRule.reportLosses => '정직한 보고',
    FamilyRule.noHotTips => '독립 리서치',
    FamilyRule.keepCash => '현금 우선',
  };

  OrganizationState requestFamilyHelp(String helperId, int day) {
    final helper = familyHelpers
        .where((item) => item.id == helperId)
        .firstOrNull;
    if (helper == null || !helper.canHelpOn(day)) return this;
    return OrganizationState(
      employees: employees,
      familyHelpers: familyHelpers
          .map((item) => item.id == helperId ? item.requestHelp(day) : item)
          .toList(growable: false),
      cultureTags: cultureTags,
      helpLog: [...helpLog, 'DAY $day · ${helper.name} · ${helper.effect}'],
    );
  }

  OrganizationState recoverOneDay() => OrganizationState(
    employees: employees,
    familyHelpers: familyHelpers.map((item) => item.recover()).toList(),
    cultureTags: cultureTags,
    helpLog: helpLog,
  );

  Map<String, dynamic> toJson() => {
    'employees': employees.map((item) => item.toJson()).toList(),
    'familyHelpers': familyHelpers.map((item) => item.toJson()).toList(),
    'cultureTags': cultureTags,
    'helpLog': helpLog,
  };

  factory OrganizationState.fromJson(
    Map<String, dynamic> json, {
    required int legacyTeamCount,
    required FamilyRule familyRule,
  }) {
    if (json.isEmpty) {
      final initial = OrganizationState.initial(familyRule);
      if (legacyTeamCount <= 1) return initial;
      return OrganizationState(
        employees: List.generate(
          legacyTeamCount - 1,
          (index) => EmployeeProfile.legacy(index + 1),
        ),
        familyHelpers: initial.familyHelpers,
        cultureTags: initial.cultureTags,
        helpLog: const [],
      );
    }
    return OrganizationState(
      employees: ((json['employees'] as List?) ?? const [])
          .map(
            (item) =>
                EmployeeProfile.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      familyHelpers: ((json['familyHelpers'] as List?) ?? const [])
          .map(
            (item) => FamilyHelperStatus.fromJson(
              (item as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
      cultureTags: ((json['cultureTags'] as List?) ?? const []).cast<String>(),
      helpLog: ((json['helpLog'] as List?) ?? const []).cast<String>(),
    );
  }
}
