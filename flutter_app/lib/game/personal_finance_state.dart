enum SpendingCategory { family, education, business, realEstate, social }

enum SpendingRepeat { once, monthly, yearly }

class SpendingOption {
  const SpendingOption({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.unlockYear,
    required this.cost,
    this.repeat = SpendingRepeat.once,
    this.requiresEmployee = false,
    this.requiresLegalCompany = false,
    this.isRealEstate = false,
    this.monthlyIncome = 0,
    this.monthlyCost = 0,
    this.researchIncomeBonus = 0,
    this.researchIncomePerEmployeeBonus = 0,
    this.reputationDelta = 0,
    this.familyTrustDelta = 0,
  });

  final String id;
  final String title;
  final String description;
  final SpendingCategory category;
  final int unlockYear;
  final int cost;
  final SpendingRepeat repeat;
  final bool requiresEmployee;
  final bool requiresLegalCompany;
  final bool isRealEstate;
  final int monthlyIncome;
  final int monthlyCost;
  final int researchIncomeBonus;
  final int researchIncomePerEmployeeBonus;
  final int reputationDelta;
  final int familyTrustDelta;
}

const spendingCatalog = <SpendingOption>[
  SpendingOption(
    id: 'family_outing',
    title: '가족과 보내는 하루',
    description: '가족 외식과 나들이 비용입니다. 같은 달에는 한 번만 선택해 가족 신뢰를 높입니다.',
    category: SpendingCategory.family,
    unlockYear: 2000,
    cost: 20000,
    repeat: SpendingRepeat.monthly,
    familyTrustDelta: 4,
  ),
  SpendingOption(
    id: 'research_books',
    title: '회계·투자 서적 묶음',
    description: '한 해에 한 번 구입하며 그해 월 리서치 수입을 1만원 늘립니다.',
    category: SpendingCategory.education,
    unlockYear: 2001,
    cost: 80000,
    repeat: SpendingRepeat.yearly,
    reputationDelta: 1,
    researchIncomeBonus: 10000,
  ),
  SpendingOption(
    id: 'employee_training',
    title: '직원 합동 연수',
    description: '그해 직원 1명당 월 리서치 수입을 1만5천원 늘립니다. 연 1회 가능합니다.',
    category: SpendingCategory.education,
    unlockYear: 2003,
    cost: 300000,
    repeat: SpendingRepeat.yearly,
    requiresEmployee: true,
    reputationDelta: 2,
    researchIncomePerEmployeeBonus: 15000,
  ),
  SpendingOption(
    id: 'data_archive',
    title: '기업자료 아카이브',
    description: '장기 자료 구독권을 구입해 월 리서치 수입을 4만원 늘립니다.',
    category: SpendingCategory.business,
    unlockYear: 2004,
    cost: 500000,
    researchIncomeBonus: 40000,
    reputationDelta: 2,
  ),
  SpendingOption(
    id: 'owner_office',
    title: '자가 사무실',
    description: '법인 명의의 작은 사무실입니다. 월 임대료 대신 유지비 4만원이 듭니다.',
    category: SpendingCategory.realEstate,
    unlockYear: 2006,
    cost: 3000000,
    requiresLegalCompany: true,
    isRealEstate: true,
    monthlyCost: 40000,
    reputationDelta: 3,
  ),
  SpendingOption(
    id: 'commercial_unit',
    title: '소형 상가 지분',
    description: '게임용 가상 부동산입니다. 월 임대수입 11만원, 유지비 2만5천원이 발생합니다.',
    category: SpendingCategory.realEstate,
    unlockYear: 2008,
    cost: 12000000,
    requiresLegalCompany: true,
    isRealEstate: true,
    monthlyIncome: 110000,
    monthlyCost: 25000,
    reputationDelta: 2,
  ),
  SpendingOption(
    id: 'scholarship',
    title: '청소년 금융교육 장학금',
    description: '지역 학생을 지원합니다. 한 해에 한 번 평판과 가족 신뢰를 높입니다.',
    category: SpendingCategory.social,
    unlockYear: 2008,
    cost: 1000000,
    repeat: SpendingRepeat.yearly,
    reputationDelta: 7,
    familyTrustDelta: 2,
  ),
  SpendingOption(
    id: 'family_home_trust',
    title: '가족 주택 신탁',
    description: '보호자와 공동 관리하는 게임용 주거자산입니다. 월 관리비 8만원이 듭니다.',
    category: SpendingCategory.realEstate,
    unlockYear: 2009,
    cost: 25000000,
    requiresLegalCompany: true,
    isRealEstate: true,
    monthlyCost: 80000,
    familyTrustDelta: 8,
  ),
];

SpendingOption? spendingOptionById(String id) {
  for (final option in spendingCatalog) {
    if (option.id == id) return option;
  }
  return null;
}

class OwnedRealEstate {
  const OwnedRealEstate({
    required this.id,
    required this.optionId,
    required this.name,
    required this.purchasePrice,
    required this.acquiredDay,
    required this.monthlyIncome,
    required this.monthlyCost,
  });

  final String id;
  final String optionId;
  final String name;
  final int purchasePrice;
  final int acquiredDay;
  final int monthlyIncome;
  final int monthlyCost;

  int estimatedSaleValue(int currentDay) {
    final heldYears = ((currentDay - acquiredDay).clamp(0, 5000) / 365).floor();
    final valueRate = (90 + heldYears * 2).clamp(90, 115);
    return (purchasePrice * valueRate / 100).round();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'optionId': optionId,
    'name': name,
    'purchasePrice': purchasePrice,
    'acquiredDay': acquiredDay,
    'monthlyIncome': monthlyIncome,
    'monthlyCost': monthlyCost,
  };

  factory OwnedRealEstate.fromJson(Map<String, dynamic> json) =>
      OwnedRealEstate(
        id: json['id'] as String? ?? '',
        optionId: json['optionId'] as String? ?? '',
        name: json['name'] as String? ?? '부동산',
        purchasePrice: (json['purchasePrice'] as num?)?.toInt() ?? 0,
        acquiredDay: (json['acquiredDay'] as num?)?.toInt() ?? 1,
        monthlyIncome: (json['monthlyIncome'] as num?)?.toInt() ?? 0,
        monthlyCost: (json['monthlyCost'] as num?)?.toInt() ?? 0,
      );
}

class PersonalFinanceState {
  const PersonalFinanceState({
    required this.realEstate,
    required this.permanentPurchases,
    required this.lastPurchasePeriods,
    required this.totalSpent,
    required this.totalPropertyIncome,
    required this.lastChanceMonth,
    required this.chancePlayCount,
    required this.totalChanceStake,
    required this.totalChancePayout,
  });

  factory PersonalFinanceState.initial() => const PersonalFinanceState(
    realEstate: [],
    permanentPurchases: [],
    lastPurchasePeriods: {},
    totalSpent: 0,
    totalPropertyIncome: 0,
    lastChanceMonth: '',
    chancePlayCount: 0,
    totalChanceStake: 0,
    totalChancePayout: 0,
  );

  final List<OwnedRealEstate> realEstate;
  final List<String> permanentPurchases;
  final Map<String, String> lastPurchasePeriods;
  final int totalSpent;
  final int totalPropertyIncome;
  final String lastChanceMonth;
  final int chancePlayCount;
  final int totalChanceStake;
  final int totalChancePayout;

  bool ownsRealEstate(String optionId) =>
      realEstate.any((asset) => asset.optionId == optionId);

  bool hasPermanentPurchase(String optionId) =>
      permanentPurchases.contains(optionId);

  int get propertyBookValue =>
      realEstate.fold<int>(0, (sum, asset) => sum + asset.purchasePrice);

  int estimatedPropertyValueAt(int day) => realEstate.fold<int>(
    0,
    (sum, asset) => sum + asset.estimatedSaleValue(day),
  );

  int get monthlyPropertyIncome =>
      realEstate.fold<int>(0, (sum, asset) => sum + asset.monthlyIncome);

  int get monthlyPropertyCost =>
      realEstate.fold<int>(0, (sum, asset) => sum + asset.monthlyCost);

  int monthlyResearchBonusAt(int year, int employeeCount) {
    var total = 0;
    for (final option in spendingCatalog) {
      final active = option.repeat == SpendingRepeat.once
          ? permanentPurchases.contains(option.id)
          : option.repeat == SpendingRepeat.yearly &&
                lastPurchasePeriods[option.id] == '$year';
      if (!active) continue;
      total += option.researchIncomeBonus;
      total += option.researchIncomePerEmployeeBonus * employeeCount;
    }
    return total;
  }

  int get chanceNet => totalChancePayout - totalChanceStake;

  PersonalFinanceState copyWith({
    List<OwnedRealEstate>? realEstate,
    List<String>? permanentPurchases,
    Map<String, String>? lastPurchasePeriods,
    int? totalSpent,
    int? totalPropertyIncome,
    String? lastChanceMonth,
    int? chancePlayCount,
    int? totalChanceStake,
    int? totalChancePayout,
  }) => PersonalFinanceState(
    realEstate: realEstate ?? this.realEstate,
    permanentPurchases: permanentPurchases ?? this.permanentPurchases,
    lastPurchasePeriods: lastPurchasePeriods ?? this.lastPurchasePeriods,
    totalSpent: totalSpent ?? this.totalSpent,
    totalPropertyIncome: totalPropertyIncome ?? this.totalPropertyIncome,
    lastChanceMonth: lastChanceMonth ?? this.lastChanceMonth,
    chancePlayCount: chancePlayCount ?? this.chancePlayCount,
    totalChanceStake: totalChanceStake ?? this.totalChanceStake,
    totalChancePayout: totalChancePayout ?? this.totalChancePayout,
  );

  Map<String, dynamic> toJson() => {
    'realEstate': realEstate.map((asset) => asset.toJson()).toList(),
    'permanentPurchases': permanentPurchases,
    'lastPurchasePeriods': lastPurchasePeriods,
    'totalSpent': totalSpent,
    'totalPropertyIncome': totalPropertyIncome,
    'lastChanceMonth': lastChanceMonth,
    'chancePlayCount': chancePlayCount,
    'totalChanceStake': totalChanceStake,
    'totalChancePayout': totalChancePayout,
  };

  factory PersonalFinanceState.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return PersonalFinanceState.initial();
    return PersonalFinanceState(
      realEstate: ((json['realEstate'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => OwnedRealEstate.fromJson(item.cast<String, dynamic>()))
          .where((asset) => asset.id.isNotEmpty && asset.purchasePrice >= 0)
          .toList(growable: false),
      permanentPurchases: ((json['permanentPurchases'] as List?) ?? const [])
          .whereType<String>()
          .toSet()
          .toList(growable: false),
      lastPurchasePeriods: ((json['lastPurchasePeriods'] as Map?) ?? const {})
          .map((key, value) => MapEntry(key.toString(), value.toString())),
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      totalPropertyIncome: (json['totalPropertyIncome'] as num?)?.toInt() ?? 0,
      lastChanceMonth: json['lastChanceMonth'] as String? ?? '',
      chancePlayCount: (json['chancePlayCount'] as num?)?.toInt() ?? 0,
      totalChanceStake: (json['totalChanceStake'] as num?)?.toInt() ?? 0,
      totalChancePayout: (json['totalChancePayout'] as num?)?.toInt() ?? 0,
    );
  }
}
