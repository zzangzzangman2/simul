enum BusinessIndustry {
  pcBang,
  karaoke,
  cafe,
  bakery,
  koreanRestaurant,
  fastFood,
  convenienceStore,
  studyCafe,
  fitnessCenter,
  coinLaundry,
  hairSalon,
  nailSalon,
  arcade,
  boardGameCafe,
  petGrooming,
  deliveryKitchen,
  photographyStudio,
  usedBookStore,
}

extension BusinessIndustryLabel on BusinessIndustry {
  String get label => switch (this) {
    BusinessIndustry.pcBang => 'PC방',
    BusinessIndustry.karaoke => '노래방',
    BusinessIndustry.cafe => '카페',
    BusinessIndustry.bakery => '베이커리',
    BusinessIndustry.koreanRestaurant => '한식당',
    BusinessIndustry.fastFood => '패스트푸드점',
    BusinessIndustry.convenienceStore => '편의점',
    BusinessIndustry.studyCafe => '스터디카페',
    BusinessIndustry.fitnessCenter => '헬스장',
    BusinessIndustry.coinLaundry => '코인세탁소',
    BusinessIndustry.hairSalon => '미용실',
    BusinessIndustry.nailSalon => '네일숍',
    BusinessIndustry.arcade => '오락실',
    BusinessIndustry.boardGameCafe => '보드게임카페',
    BusinessIndustry.petGrooming => '반려동물 미용실',
    BusinessIndustry.deliveryKitchen => '배달전문 주방',
    BusinessIndustry.photographyStudio => '사진관',
    BusinessIndustry.usedBookStore => '중고서점',
  };
}

enum BusinessListingMode { startup, acquisition }

extension BusinessListingModeLabel on BusinessListingMode {
  String get label => switch (this) {
    BusinessListingMode.startup => '신규 창업',
    BusinessListingMode.acquisition => '기존 점포 인수',
  };
}

enum BusinessPremiseMode { leased, ownedProperty }

enum BusinessStatus { operating, struggling, suspended, closed, sold }

extension BusinessStatusLabel on BusinessStatus {
  String get label => switch (this) {
    BusinessStatus.operating => '영업 중',
    BusinessStatus.struggling => '경영난',
    BusinessStatus.suspended => '영업 중단',
    BusinessStatus.closed => '폐업',
    BusinessStatus.sold => '매각 완료',
  };
}

enum BusinessPolicyAxis {
  pricing,
  quality,
  staffing,
  marketing,
  openingHours,
  maintenance,
}

extension BusinessPolicyAxisLabel on BusinessPolicyAxis {
  String get label => switch (this) {
    BusinessPolicyAxis.pricing => '가격',
    BusinessPolicyAxis.quality => '품질',
    BusinessPolicyAxis.staffing => '인력',
    BusinessPolicyAxis.marketing => '홍보',
    BusinessPolicyAxis.openingHours => '영업시간',
    BusinessPolicyAxis.maintenance => '설비관리',
  };
}

enum BusinessEventStatus { pendingChoice, awaitingOutcome, resolved, expired }

enum BusinessEventOutcome { success, partial, failure }

/// Six management choices that materially affect revenue and operating risk.
///
/// Every axis uses a 0-4 scale. Level 2 is the neutral default. Keeping the
/// representation compact makes it safe to store a policy snapshot with every
/// monthly statement.
class BusinessOperatingPolicy {
  const BusinessOperatingPolicy({
    this.pricing = 2,
    this.quality = 2,
    this.staffing = 2,
    this.marketing = 2,
    this.openingHours = 2,
    this.maintenance = 2,
  }) : assert(pricing >= 0 && pricing <= 4),
       assert(quality >= 0 && quality <= 4),
       assert(staffing >= 0 && staffing <= 4),
       assert(marketing >= 0 && marketing <= 4),
       assert(openingHours >= 0 && openingHours <= 4),
       assert(maintenance >= 0 && maintenance <= 4);

  static const neutral = BusinessOperatingPolicy();

  final int pricing;
  final int quality;
  final int staffing;
  final int marketing;
  final int openingHours;
  final int maintenance;

  int valueFor(BusinessPolicyAxis axis) => switch (axis) {
    BusinessPolicyAxis.pricing => pricing,
    BusinessPolicyAxis.quality => quality,
    BusinessPolicyAxis.staffing => staffing,
    BusinessPolicyAxis.marketing => marketing,
    BusinessPolicyAxis.openingHours => openingHours,
    BusinessPolicyAxis.maintenance => maintenance,
  };

  BusinessOperatingPolicy copyWith({
    int? pricing,
    int? quality,
    int? staffing,
    int? marketing,
    int? openingHours,
    int? maintenance,
  }) => BusinessOperatingPolicy(
    pricing: _policyLevel(pricing ?? this.pricing),
    quality: _policyLevel(quality ?? this.quality),
    staffing: _policyLevel(staffing ?? this.staffing),
    marketing: _policyLevel(marketing ?? this.marketing),
    openingHours: _policyLevel(openingHours ?? this.openingHours),
    maintenance: _policyLevel(maintenance ?? this.maintenance),
  );

  BusinessOperatingPolicy withAxis(BusinessPolicyAxis axis, int value) {
    final level = _policyLevel(value);
    return switch (axis) {
      BusinessPolicyAxis.pricing => copyWith(pricing: level),
      BusinessPolicyAxis.quality => copyWith(quality: level),
      BusinessPolicyAxis.staffing => copyWith(staffing: level),
      BusinessPolicyAxis.marketing => copyWith(marketing: level),
      BusinessPolicyAxis.openingHours => copyWith(openingHours: level),
      BusinessPolicyAxis.maintenance => copyWith(maintenance: level),
    };
  }

  Map<String, dynamic> toJson() => {
    'pricing': pricing,
    'quality': quality,
    'staffing': staffing,
    'marketing': marketing,
    'openingHours': openingHours,
    'maintenance': maintenance,
  };

  factory BusinessOperatingPolicy.fromJson(Map<String, dynamic> json) =>
      BusinessOperatingPolicy(
        pricing: _policyLevel((json['pricing'] as num?)?.toInt() ?? 2),
        quality: _policyLevel((json['quality'] as num?)?.toInt() ?? 2),
        staffing: _policyLevel((json['staffing'] as num?)?.toInt() ?? 2),
        marketing: _policyLevel((json['marketing'] as num?)?.toInt() ?? 2),
        openingHours: _policyLevel(
          (json['openingHours'] as num?)?.toInt() ?? 2,
        ),
        maintenance: _policyLevel((json['maintenance'] as num?)?.toInt() ?? 2),
      );
}

/// A snapshotted event choice.
///
/// Choices are copied into the save rather than looked up from the current
/// template catalog. Old saves therefore keep the exact trade-off the player
/// originally saw even after content balancing changes.
class BusinessEventChoice {
  const BusinessEventChoice({
    required this.id,
    required this.label,
    required this.description,
    this.upfrontCost = 0,
    this.immediateDemandDeltaBps = 0,
    this.immediateReputationDelta = 0,
    this.immediateConditionDelta = 0,
    this.immediateStaffMoraleDelta = 0,
    this.immediateRiskDelta = 0,
    this.successChanceBps = 5000,
    this.successCashDelta = 0,
    this.successDemandDeltaBps = 0,
    this.successReputationDelta = 0,
    this.successConditionDelta = 0,
    this.successStaffMoraleDelta = 0,
    this.successRiskDelta = 0,
    this.failureCashDelta = 0,
    this.failureDemandDeltaBps = 0,
    this.failureReputationDelta = 0,
    this.failureConditionDelta = 0,
    this.failureStaffMoraleDelta = 0,
    this.failureRiskDelta = 0,
  }) : assert(upfrontCost >= 0),
       assert(successChanceBps >= 0 && successChanceBps <= 10000);

  final String id;
  final String label;
  final String description;
  final int upfrontCost;

  final int immediateDemandDeltaBps;
  final int immediateReputationDelta;
  final int immediateConditionDelta;
  final int immediateStaffMoraleDelta;
  final int immediateRiskDelta;

  final int successChanceBps;
  final int successCashDelta;
  final int successDemandDeltaBps;
  final int successReputationDelta;
  final int successConditionDelta;
  final int successStaffMoraleDelta;
  final int successRiskDelta;

  final int failureCashDelta;
  final int failureDemandDeltaBps;
  final int failureReputationDelta;
  final int failureConditionDelta;
  final int failureStaffMoraleDelta;
  final int failureRiskDelta;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'description': description,
    'upfrontCost': upfrontCost,
    'immediateDemandDeltaBps': immediateDemandDeltaBps,
    'immediateReputationDelta': immediateReputationDelta,
    'immediateConditionDelta': immediateConditionDelta,
    'immediateStaffMoraleDelta': immediateStaffMoraleDelta,
    'immediateRiskDelta': immediateRiskDelta,
    'successChanceBps': successChanceBps,
    'successCashDelta': successCashDelta,
    'successDemandDeltaBps': successDemandDeltaBps,
    'successReputationDelta': successReputationDelta,
    'successConditionDelta': successConditionDelta,
    'successStaffMoraleDelta': successStaffMoraleDelta,
    'successRiskDelta': successRiskDelta,
    'failureCashDelta': failureCashDelta,
    'failureDemandDeltaBps': failureDemandDeltaBps,
    'failureReputationDelta': failureReputationDelta,
    'failureConditionDelta': failureConditionDelta,
    'failureStaffMoraleDelta': failureStaffMoraleDelta,
    'failureRiskDelta': failureRiskDelta,
  };

  factory BusinessEventChoice.fromJson(Map<String, dynamic> json) =>
      BusinessEventChoice(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        description: json['description'] as String? ?? '',
        upfrontCost: _nonNegativeInt(json['upfrontCost']),
        immediateDemandDeltaBps:
            (json['immediateDemandDeltaBps'] as num?)?.toInt() ?? 0,
        immediateReputationDelta:
            (json['immediateReputationDelta'] as num?)?.toInt() ?? 0,
        immediateConditionDelta:
            (json['immediateConditionDelta'] as num?)?.toInt() ?? 0,
        immediateStaffMoraleDelta:
            (json['immediateStaffMoraleDelta'] as num?)?.toInt() ?? 0,
        immediateRiskDelta: (json['immediateRiskDelta'] as num?)?.toInt() ?? 0,
        successChanceBps: _basisPoints(
          (json['successChanceBps'] as num?)?.toInt() ?? 5000,
        ),
        successCashDelta: (json['successCashDelta'] as num?)?.toInt() ?? 0,
        successDemandDeltaBps:
            (json['successDemandDeltaBps'] as num?)?.toInt() ?? 0,
        successReputationDelta:
            (json['successReputationDelta'] as num?)?.toInt() ?? 0,
        successConditionDelta:
            (json['successConditionDelta'] as num?)?.toInt() ?? 0,
        successStaffMoraleDelta:
            (json['successStaffMoraleDelta'] as num?)?.toInt() ?? 0,
        successRiskDelta: (json['successRiskDelta'] as num?)?.toInt() ?? 0,
        failureCashDelta: (json['failureCashDelta'] as num?)?.toInt() ?? 0,
        failureDemandDeltaBps:
            (json['failureDemandDeltaBps'] as num?)?.toInt() ?? 0,
        failureReputationDelta:
            (json['failureReputationDelta'] as num?)?.toInt() ?? 0,
        failureConditionDelta:
            (json['failureConditionDelta'] as num?)?.toInt() ?? 0,
        failureStaffMoraleDelta:
            (json['failureStaffMoraleDelta'] as num?)?.toInt() ?? 0,
        failureRiskDelta: (json['failureRiskDelta'] as num?)?.toInt() ?? 0,
      );
}

class BusinessEventInstance {
  const BusinessEventInstance({
    required this.id,
    required this.templateId,
    required this.businessId,
    required this.title,
    required this.body,
    required this.occurredDateIso,
    required this.choiceDueDateIso,
    required this.resolutionDateIso,
    required this.choices,
    this.tags = const [],
    this.dailyDemandDeltaBps = 0,
    this.dailyExtraCost = 0,
    this.status = BusinessEventStatus.pendingChoice,
    this.selectedChoiceId,
    this.outcome,
    this.outcomeTitle = '',
    this.outcomeBody = '',
    this.realizedCashDelta = 0,
    this.realizedDemandDeltaBps = 0,
    this.realizedReputationDelta = 0,
    this.realizedConditionDelta = 0,
    this.realizedStaffMoraleDelta = 0,
    this.realizedRiskDelta = 0,
  });

  final String id;
  final String templateId;
  final String businessId;
  final String title;
  final String body;
  final String occurredDateIso;
  final String choiceDueDateIso;
  final String resolutionDateIso;
  final List<String> tags;
  final int dailyDemandDeltaBps;
  final int dailyExtraCost;
  final List<BusinessEventChoice> choices;
  final BusinessEventStatus status;
  final String? selectedChoiceId;
  final BusinessEventOutcome? outcome;
  final String outcomeTitle;
  final String outcomeBody;
  final int realizedCashDelta;
  final int realizedDemandDeltaBps;
  final int realizedReputationDelta;
  final int realizedConditionDelta;
  final int realizedStaffMoraleDelta;
  final int realizedRiskDelta;

  DateTime? get occurredDate => DateTime.tryParse(occurredDateIso);
  DateTime? get choiceDueDate => DateTime.tryParse(choiceDueDateIso);
  DateTime? get resolutionDate => DateTime.tryParse(resolutionDateIso);

  BusinessEventChoice? get selectedChoice {
    final selected = selectedChoiceId;
    if (selected == null) return null;
    for (final choice in choices) {
      if (choice.id == selected) return choice;
    }
    return null;
  }

  bool isActiveOn(DateTime date) {
    final occurred = occurredDate;
    final resolution = resolutionDate;
    if (occurred == null || date.isBefore(occurred)) return false;
    if (status == BusinessEventStatus.expired) return false;
    if (status == BusinessEventStatus.resolved &&
        resolution != null &&
        !date.isBefore(resolution)) {
      return false;
    }
    return resolution == null || !date.isAfter(resolution);
  }

  BusinessEventInstance copyWith({
    BusinessEventStatus? status,
    String? selectedChoiceId,
    bool clearSelectedChoice = false,
    BusinessEventOutcome? outcome,
    bool clearOutcome = false,
    String? outcomeTitle,
    String? outcomeBody,
    int? realizedCashDelta,
    int? realizedDemandDeltaBps,
    int? realizedReputationDelta,
    int? realizedConditionDelta,
    int? realizedStaffMoraleDelta,
    int? realizedRiskDelta,
  }) => BusinessEventInstance(
    id: id,
    templateId: templateId,
    businessId: businessId,
    title: title,
    body: body,
    occurredDateIso: occurredDateIso,
    choiceDueDateIso: choiceDueDateIso,
    resolutionDateIso: resolutionDateIso,
    choices: choices,
    tags: tags,
    dailyDemandDeltaBps: dailyDemandDeltaBps,
    dailyExtraCost: dailyExtraCost,
    status: status ?? this.status,
    selectedChoiceId: clearSelectedChoice
        ? null
        : selectedChoiceId ?? this.selectedChoiceId,
    outcome: clearOutcome ? null : outcome ?? this.outcome,
    outcomeTitle: outcomeTitle ?? this.outcomeTitle,
    outcomeBody: outcomeBody ?? this.outcomeBody,
    realizedCashDelta: realizedCashDelta ?? this.realizedCashDelta,
    realizedDemandDeltaBps:
        realizedDemandDeltaBps ?? this.realizedDemandDeltaBps,
    realizedReputationDelta:
        realizedReputationDelta ?? this.realizedReputationDelta,
    realizedConditionDelta:
        realizedConditionDelta ?? this.realizedConditionDelta,
    realizedStaffMoraleDelta:
        realizedStaffMoraleDelta ?? this.realizedStaffMoraleDelta,
    realizedRiskDelta: realizedRiskDelta ?? this.realizedRiskDelta,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'templateId': templateId,
    'businessId': businessId,
    'title': title,
    'body': body,
    'occurredDateIso': occurredDateIso,
    'choiceDueDateIso': choiceDueDateIso,
    'resolutionDateIso': resolutionDateIso,
    'tags': tags,
    'dailyDemandDeltaBps': dailyDemandDeltaBps,
    'dailyExtraCost': dailyExtraCost,
    'choices': choices.map((choice) => choice.toJson()).toList(),
    'status': status.name,
    'selectedChoiceId': selectedChoiceId,
    'outcome': outcome?.name,
    'outcomeTitle': outcomeTitle,
    'outcomeBody': outcomeBody,
    'realizedCashDelta': realizedCashDelta,
    'realizedDemandDeltaBps': realizedDemandDeltaBps,
    'realizedReputationDelta': realizedReputationDelta,
    'realizedConditionDelta': realizedConditionDelta,
    'realizedStaffMoraleDelta': realizedStaffMoraleDelta,
    'realizedRiskDelta': realizedRiskDelta,
  };

  factory BusinessEventInstance.fromJson(
    Map<String, dynamic> json,
  ) => BusinessEventInstance(
    id: json['id'] as String? ?? '',
    templateId: json['templateId'] as String? ?? '',
    businessId: json['businessId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    occurredDateIso: json['occurredDateIso'] as String? ?? '',
    choiceDueDateIso: json['choiceDueDateIso'] as String? ?? '',
    resolutionDateIso: json['resolutionDateIso'] as String? ?? '',
    tags: ((json['tags'] as List?) ?? const []).whereType<String>().toList(
      growable: false,
    ),
    dailyDemandDeltaBps: (json['dailyDemandDeltaBps'] as num?)?.toInt() ?? 0,
    dailyExtraCost: _nonNegativeInt(json['dailyExtraCost']),
    choices: ((json['choices'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (choice) =>
              BusinessEventChoice.fromJson(choice.cast<String, dynamic>()),
        )
        .where((choice) => choice.id.isNotEmpty)
        .toList(growable: false),
    status: _enumByName(
      BusinessEventStatus.values,
      json['status'],
      BusinessEventStatus.pendingChoice,
    ),
    selectedChoiceId: json['selectedChoiceId'] as String?,
    outcome: _nullableEnumByName(BusinessEventOutcome.values, json['outcome']),
    outcomeTitle: json['outcomeTitle'] as String? ?? '',
    outcomeBody: json['outcomeBody'] as String? ?? '',
    realizedCashDelta: (json['realizedCashDelta'] as num?)?.toInt() ?? 0,
    realizedDemandDeltaBps:
        (json['realizedDemandDeltaBps'] as num?)?.toInt() ?? 0,
    realizedReputationDelta:
        (json['realizedReputationDelta'] as num?)?.toInt() ?? 0,
    realizedConditionDelta:
        (json['realizedConditionDelta'] as num?)?.toInt() ?? 0,
    realizedStaffMoraleDelta:
        (json['realizedStaffMoraleDelta'] as num?)?.toInt() ?? 0,
    realizedRiskDelta: (json['realizedRiskDelta'] as num?)?.toInt() ?? 0,
  );
}

class BusinessDailyResult {
  const BusinessDailyResult({
    required this.businessId,
    required this.dateIso,
    required this.customerCount,
    required this.demandIndexBps,
    required this.grossSales,
    required this.variableCosts,
    required this.payroll,
    required this.rent,
    required this.utilities,
    required this.marketing,
    required this.maintenance,
    required this.eventCosts,
    required this.taxes,
    required this.netProfit,
    this.activeEventIds = const [],
  });

  final String businessId;
  final String dateIso;
  final int customerCount;
  final int demandIndexBps;
  final int grossSales;
  final int variableCosts;
  final int payroll;
  final int rent;
  final int utilities;
  final int marketing;
  final int maintenance;
  final int eventCosts;
  final int taxes;
  final int netProfit;
  final List<String> activeEventIds;

  int get totalOperatingCosts =>
      variableCosts +
      payroll +
      rent +
      utilities +
      marketing +
      maintenance +
      eventCosts +
      taxes;

  Map<String, dynamic> toJson() => {
    'businessId': businessId,
    'dateIso': dateIso,
    'customerCount': customerCount,
    'demandIndexBps': demandIndexBps,
    'grossSales': grossSales,
    'variableCosts': variableCosts,
    'payroll': payroll,
    'rent': rent,
    'utilities': utilities,
    'marketing': marketing,
    'maintenance': maintenance,
    'eventCosts': eventCosts,
    'taxes': taxes,
    'netProfit': netProfit,
    'activeEventIds': activeEventIds,
  };

  factory BusinessDailyResult.fromJson(Map<String, dynamic> json) =>
      BusinessDailyResult(
        businessId: json['businessId'] as String? ?? '',
        dateIso: json['dateIso'] as String? ?? '',
        customerCount: _nonNegativeInt(json['customerCount']),
        demandIndexBps: _nonNegativeInt(json['demandIndexBps']),
        grossSales: _nonNegativeInt(json['grossSales']),
        variableCosts: _nonNegativeInt(json['variableCosts']),
        payroll: _nonNegativeInt(json['payroll']),
        rent: _nonNegativeInt(json['rent']),
        utilities: _nonNegativeInt(json['utilities']),
        marketing: _nonNegativeInt(json['marketing']),
        maintenance: _nonNegativeInt(json['maintenance']),
        eventCosts: _nonNegativeInt(json['eventCosts']),
        taxes: _nonNegativeInt(json['taxes']),
        netProfit: (json['netProfit'] as num?)?.toInt() ?? 0,
        activeEventIds: ((json['activeEventIds'] as List?) ?? const [])
            .whereType<String>()
            .toList(growable: false),
      );
}

class BusinessMonthlyStatement {
  const BusinessMonthlyStatement({
    required this.businessId,
    required this.year,
    required this.month,
    required this.operatingDays,
    required this.customerCount,
    required this.grossSales,
    required this.variableCosts,
    required this.payroll,
    required this.rent,
    required this.utilities,
    required this.marketing,
    required this.maintenance,
    required this.eventCosts,
    required this.taxes,
    required this.netProfit,
    required this.policySnapshot,
    required this.sourceId,
  });

  final String businessId;
  final int year;
  final int month;
  final int operatingDays;
  final int customerCount;
  final int grossSales;
  final int variableCosts;
  final int payroll;
  final int rent;
  final int utilities;
  final int marketing;
  final int maintenance;
  final int eventCosts;
  final int taxes;
  final int netProfit;
  final BusinessOperatingPolicy policySnapshot;
  final String sourceId;

  int get totalOperatingCosts =>
      variableCosts +
      payroll +
      rent +
      utilities +
      marketing +
      maintenance +
      eventCosts +
      taxes;

  double get operatingMargin => grossSales <= 0 ? 0 : netProfit / grossSales;

  Map<String, dynamic> toJson() => {
    'businessId': businessId,
    'year': year,
    'month': month,
    'operatingDays': operatingDays,
    'customerCount': customerCount,
    'grossSales': grossSales,
    'variableCosts': variableCosts,
    'payroll': payroll,
    'rent': rent,
    'utilities': utilities,
    'marketing': marketing,
    'maintenance': maintenance,
    'eventCosts': eventCosts,
    'taxes': taxes,
    'netProfit': netProfit,
    'policySnapshot': policySnapshot.toJson(),
    'sourceId': sourceId,
  };

  factory BusinessMonthlyStatement.fromJson(Map<String, dynamic> json) =>
      BusinessMonthlyStatement(
        businessId: json['businessId'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 2000,
        month: ((json['month'] as num?)?.toInt() ?? 1).clamp(1, 12).toInt(),
        operatingDays: _nonNegativeInt(json['operatingDays']),
        customerCount: _nonNegativeInt(json['customerCount']),
        grossSales: _nonNegativeInt(json['grossSales']),
        variableCosts: _nonNegativeInt(json['variableCosts']),
        payroll: _nonNegativeInt(json['payroll']),
        rent: _nonNegativeInt(json['rent']),
        utilities: _nonNegativeInt(json['utilities']),
        marketing: _nonNegativeInt(json['marketing']),
        maintenance: _nonNegativeInt(json['maintenance']),
        eventCosts: _nonNegativeInt(json['eventCosts']),
        taxes: _nonNegativeInt(json['taxes']),
        netProfit: (json['netProfit'] as num?)?.toInt() ?? 0,
        policySnapshot: BusinessOperatingPolicy.fromJson(
          (json['policySnapshot'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        sourceId: json['sourceId'] as String? ?? '',
      );
}

class OwnedBusiness {
  const OwnedBusiness({
    required this.id,
    required this.name,
    required this.industry,
    required this.locationId,
    this.districtId = '',
    this.districtRentIndexAtOpenBps = 10000,
    required this.listingMode,
    required this.premiseMode,
    required this.openedDateIso,
    required this.acquiredDay,
    required this.acquisitionPrice,
    required this.leaseDeposit,
    required this.monthlyRent,
    required this.equipmentBookValue,
    required this.goodwillBookValue,
    required this.employeeCount,
    required this.capacity,
    required this.averageTicket,
    required this.baseDailyCustomers,
    this.linkedRealEstateId,
    this.generatorVersion = 1,
    this.policy = BusinessOperatingPolicy.neutral,
    this.status = BusinessStatus.operating,
    this.reputation = 50,
    this.customerLoyalty = 35,
    this.equipmentCondition = 70,
    this.staffMorale = 60,
    this.riskLevel = 25,
    this.demandMomentumBps = 0,
    this.accountsPayable = 0,
    this.consecutiveLossMonths = 0,
    this.consecutiveProfitMonths = 0,
    this.missedPaymentMonths = 0,
    this.totalSales = 0,
    this.totalProfit = 0,
    this.totalInvested = 0,
    this.lastSettledMonth = '',
    this.statements = const [],
  }) : assert(acquisitionPrice >= 0),
       assert(districtRentIndexAtOpenBps > 0),
       assert(leaseDeposit >= 0),
       assert(monthlyRent >= 0),
       assert(equipmentBookValue >= 0),
       assert(goodwillBookValue >= 0),
       assert(employeeCount >= 0),
       assert(capacity >= 0),
       assert(averageTicket >= 0),
       assert(baseDailyCustomers >= 0),
       assert(accountsPayable >= 0);

  final String id;
  final String name;
  final BusinessIndustry industry;
  final String locationId;

  /// Actual city/commercial district. [locationId] remains the micro-location
  /// archetype (university, office, station, and so on) for save compatibility.
  final String districtId;

  /// Combined district and era rent pressure when this shop opened. Dynamic
  /// rent uses the current/reference ratio so the opening quote is not doubled.
  final int districtRentIndexAtOpenBps;
  final BusinessListingMode listingMode;
  final BusinessPremiseMode premiseMode;
  final String openedDateIso;
  final int acquiredDay;
  final int acquisitionPrice;
  final int leaseDeposit;
  final int monthlyRent;
  final int equipmentBookValue;
  final int goodwillBookValue;
  final int employeeCount;
  final int capacity;
  final int averageTicket;
  final int baseDailyCustomers;
  final String? linkedRealEstateId;
  final int generatorVersion;
  final BusinessOperatingPolicy policy;
  final BusinessStatus status;
  final int reputation;
  final int customerLoyalty;
  final int equipmentCondition;
  final int staffMorale;
  final int riskLevel;
  final int demandMomentumBps;
  final int accountsPayable;
  final int consecutiveLossMonths;
  final int consecutiveProfitMonths;
  final int missedPaymentMonths;
  final int totalSales;
  final int totalProfit;
  final int totalInvested;
  final String lastSettledMonth;
  final List<BusinessMonthlyStatement> statements;

  bool get isActive =>
      status == BusinessStatus.operating || status == BusinessStatus.struggling;

  int get bookValue => leaseDeposit + equipmentBookValue + goodwillBookValue;

  double get trailingOperatingMargin {
    if (statements.isEmpty) return 0;
    final recent = statements.length <= 12
        ? statements
        : statements.sublist(statements.length - 12);
    final sales = recent.fold<int>(
      0,
      (sum, statement) => sum + statement.grossSales,
    );
    final profit = recent.fold<int>(
      0,
      (sum, statement) => sum + statement.netProfit,
    );
    return sales <= 0 ? 0 : profit / sales;
  }

  int get trailingTwelveMonthProfit {
    final recent = statements.length <= 12
        ? statements
        : statements.sublist(statements.length - 12);
    return recent.fold<int>(0, (sum, statement) => sum + statement.netProfit);
  }

  OwnedBusiness copyWith({
    String? name,
    String? districtId,
    int? districtRentIndexAtOpenBps,
    BusinessPremiseMode? premiseMode,
    String? linkedRealEstateId,
    bool clearLinkedRealEstateId = false,
    int? leaseDeposit,
    int? monthlyRent,
    int? equipmentBookValue,
    int? goodwillBookValue,
    int? employeeCount,
    int? capacity,
    int? averageTicket,
    int? baseDailyCustomers,
    BusinessOperatingPolicy? policy,
    BusinessStatus? status,
    int? reputation,
    int? customerLoyalty,
    int? equipmentCondition,
    int? staffMorale,
    int? riskLevel,
    int? demandMomentumBps,
    int? accountsPayable,
    int? consecutiveLossMonths,
    int? consecutiveProfitMonths,
    int? missedPaymentMonths,
    int? totalSales,
    int? totalProfit,
    int? totalInvested,
    String? lastSettledMonth,
    List<BusinessMonthlyStatement>? statements,
  }) => OwnedBusiness(
    id: id,
    name: name ?? this.name,
    industry: industry,
    locationId: locationId,
    districtId: districtId ?? this.districtId,
    districtRentIndexAtOpenBps: _positive(
      districtRentIndexAtOpenBps ?? this.districtRentIndexAtOpenBps,
      fallback: 10000,
    ),
    listingMode: listingMode,
    premiseMode: premiseMode ?? this.premiseMode,
    openedDateIso: openedDateIso,
    acquiredDay: acquiredDay,
    acquisitionPrice: acquisitionPrice,
    leaseDeposit: _nonNegative(leaseDeposit ?? this.leaseDeposit),
    monthlyRent: _nonNegative(monthlyRent ?? this.monthlyRent),
    equipmentBookValue: _nonNegative(
      equipmentBookValue ?? this.equipmentBookValue,
    ),
    goodwillBookValue: _nonNegative(
      goodwillBookValue ?? this.goodwillBookValue,
    ),
    employeeCount: _nonNegative(employeeCount ?? this.employeeCount),
    capacity: _nonNegative(capacity ?? this.capacity),
    averageTicket: _nonNegative(averageTicket ?? this.averageTicket),
    baseDailyCustomers: _nonNegative(
      baseDailyCustomers ?? this.baseDailyCustomers,
    ),
    linkedRealEstateId: clearLinkedRealEstateId
        ? null
        : linkedRealEstateId ?? this.linkedRealEstateId,
    generatorVersion: generatorVersion,
    policy: policy ?? this.policy,
    status: status ?? this.status,
    reputation: _score(reputation ?? this.reputation),
    customerLoyalty: _score(customerLoyalty ?? this.customerLoyalty),
    equipmentCondition: _score(equipmentCondition ?? this.equipmentCondition),
    staffMorale: _score(staffMorale ?? this.staffMorale),
    riskLevel: _score(riskLevel ?? this.riskLevel),
    demandMomentumBps: (demandMomentumBps ?? this.demandMomentumBps)
        .clamp(-5000, 5000)
        .toInt(),
    accountsPayable: _nonNegative(accountsPayable ?? this.accountsPayable),
    consecutiveLossMonths: _nonNegative(
      consecutiveLossMonths ?? this.consecutiveLossMonths,
    ),
    consecutiveProfitMonths: _nonNegative(
      consecutiveProfitMonths ?? this.consecutiveProfitMonths,
    ),
    missedPaymentMonths: _nonNegative(
      missedPaymentMonths ?? this.missedPaymentMonths,
    ),
    totalSales: _nonNegative(totalSales ?? this.totalSales),
    totalProfit: totalProfit ?? this.totalProfit,
    totalInvested: _nonNegative(totalInvested ?? this.totalInvested),
    lastSettledMonth: lastSettledMonth ?? this.lastSettledMonth,
    statements: statements ?? this.statements,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'industry': industry.name,
    'locationId': locationId,
    'districtId': districtId,
    'districtRentIndexAtOpenBps': districtRentIndexAtOpenBps,
    'listingMode': listingMode.name,
    'premiseMode': premiseMode.name,
    'openedDateIso': openedDateIso,
    'acquiredDay': acquiredDay,
    'acquisitionPrice': acquisitionPrice,
    'leaseDeposit': leaseDeposit,
    'monthlyRent': monthlyRent,
    'equipmentBookValue': equipmentBookValue,
    'goodwillBookValue': goodwillBookValue,
    'employeeCount': employeeCount,
    'capacity': capacity,
    'averageTicket': averageTicket,
    'baseDailyCustomers': baseDailyCustomers,
    'linkedRealEstateId': linkedRealEstateId,
    'generatorVersion': generatorVersion,
    'policy': policy.toJson(),
    'status': status.name,
    'reputation': reputation,
    'customerLoyalty': customerLoyalty,
    'equipmentCondition': equipmentCondition,
    'staffMorale': staffMorale,
    'riskLevel': riskLevel,
    'demandMomentumBps': demandMomentumBps,
    'accountsPayable': accountsPayable,
    'consecutiveLossMonths': consecutiveLossMonths,
    'consecutiveProfitMonths': consecutiveProfitMonths,
    'missedPaymentMonths': missedPaymentMonths,
    'totalSales': totalSales,
    'totalProfit': totalProfit,
    'totalInvested': totalInvested,
    'lastSettledMonth': lastSettledMonth,
    'statements': statements.map((statement) => statement.toJson()).toList(),
  };

  factory OwnedBusiness.fromJson(Map<String, dynamic> json) => OwnedBusiness(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '이름 없는 점포',
    industry: _enumByName(
      BusinessIndustry.values,
      json['industry'],
      BusinessIndustry.cafe,
    ),
    locationId: json['locationId'] as String? ?? 'residential',
    districtId: json['districtId'] as String? ?? '',
    districtRentIndexAtOpenBps: _positiveInt(
      json['districtRentIndexAtOpenBps'],
      fallback: 10000,
    ),
    listingMode: _enumByName(
      BusinessListingMode.values,
      json['listingMode'],
      BusinessListingMode.startup,
    ),
    premiseMode: _enumByName(
      BusinessPremiseMode.values,
      json['premiseMode'],
      BusinessPremiseMode.leased,
    ),
    openedDateIso: json['openedDateIso'] as String? ?? '2000-01-02',
    acquiredDay: _positiveInt(json['acquiredDay'], fallback: 1),
    acquisitionPrice: _nonNegativeInt(json['acquisitionPrice']),
    leaseDeposit: _nonNegativeInt(json['leaseDeposit']),
    monthlyRent: _nonNegativeInt(json['monthlyRent']),
    equipmentBookValue: _nonNegativeInt(json['equipmentBookValue']),
    goodwillBookValue: _nonNegativeInt(json['goodwillBookValue']),
    employeeCount: _nonNegativeInt(json['employeeCount']),
    capacity: _nonNegativeInt(json['capacity']),
    averageTicket: _nonNegativeInt(json['averageTicket']),
    baseDailyCustomers: _nonNegativeInt(json['baseDailyCustomers']),
    linkedRealEstateId: json['linkedRealEstateId'] as String?,
    generatorVersion: _positiveInt(json['generatorVersion'], fallback: 1),
    policy: BusinessOperatingPolicy.fromJson(
      (json['policy'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    status: _enumByName(
      BusinessStatus.values,
      json['status'],
      BusinessStatus.operating,
    ),
    reputation: _scoreInt(json['reputation'], fallback: 50),
    customerLoyalty: _scoreInt(json['customerLoyalty'], fallback: 35),
    equipmentCondition: _scoreInt(json['equipmentCondition'], fallback: 70),
    staffMorale: _scoreInt(json['staffMorale'], fallback: 60),
    riskLevel: _scoreInt(json['riskLevel'], fallback: 25),
    demandMomentumBps: ((json['demandMomentumBps'] as num?)?.toInt() ?? 0)
        .clamp(-5000, 5000)
        .toInt(),
    accountsPayable: _nonNegativeInt(json['accountsPayable']),
    consecutiveLossMonths: _nonNegativeInt(json['consecutiveLossMonths']),
    consecutiveProfitMonths: _nonNegativeInt(json['consecutiveProfitMonths']),
    missedPaymentMonths: _nonNegativeInt(json['missedPaymentMonths']),
    totalSales: _nonNegativeInt(json['totalSales']),
    totalProfit: (json['totalProfit'] as num?)?.toInt() ?? 0,
    totalInvested: _nonNegativeInt(json['totalInvested']),
    lastSettledMonth: json['lastSettledMonth'] as String? ?? '',
    statements: ((json['statements'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (statement) => BusinessMonthlyStatement.fromJson(
            statement.cast<String, dynamic>(),
          ),
        )
        .toList(growable: false),
  );
}

/// Saveable aggregate for all directly operated neighborhood businesses.
class BusinessPortfolioState {
  const BusinessPortfolioState({
    required this.businesses,
    required this.pendingEvents,
    required this.eventHistory,
    required this.totalAcquisitionSpend,
    required this.totalSales,
    required this.totalProfit,
    required this.totalClosures,
    this.generatorVersion = 3,
  });

  const BusinessPortfolioState.initial()
    : businesses = const [],
      pendingEvents = const [],
      eventHistory = const [],
      totalAcquisitionSpend = 0,
      totalSales = 0,
      totalProfit = 0,
      totalClosures = 0,
      generatorVersion = 3;

  final List<OwnedBusiness> businesses;
  final List<BusinessEventInstance> pendingEvents;
  final List<BusinessEventInstance> eventHistory;
  final int totalAcquisitionSpend;
  final int totalSales;
  final int totalProfit;
  final int totalClosures;
  final int generatorVersion;

  List<OwnedBusiness> get activeBusinesses =>
      businesses.where((business) => business.isActive).toList(growable: false);

  int get totalBookValue =>
      businesses.fold<int>(0, (sum, business) => sum + business.bookValue);

  int get totalAccountsPayable => businesses.fold<int>(
    0,
    (sum, business) => sum + business.accountsPayable,
  );

  OwnedBusiness? businessById(String id) {
    for (final business in businesses) {
      if (business.id == id) return business;
    }
    return null;
  }

  bool usesRealEstate(String realEstateId) => businesses.any(
    (business) =>
        business.isActive && business.linkedRealEstateId == realEstateId,
  );

  BusinessPortfolioState copyWith({
    List<OwnedBusiness>? businesses,
    List<BusinessEventInstance>? pendingEvents,
    List<BusinessEventInstance>? eventHistory,
    int? totalAcquisitionSpend,
    int? totalSales,
    int? totalProfit,
    int? totalClosures,
    int? generatorVersion,
  }) => BusinessPortfolioState(
    businesses: businesses ?? this.businesses,
    pendingEvents: pendingEvents ?? this.pendingEvents,
    eventHistory: eventHistory ?? this.eventHistory,
    totalAcquisitionSpend: _nonNegative(
      totalAcquisitionSpend ?? this.totalAcquisitionSpend,
    ),
    totalSales: _nonNegative(totalSales ?? this.totalSales),
    totalProfit: totalProfit ?? this.totalProfit,
    totalClosures: _nonNegative(totalClosures ?? this.totalClosures),
    generatorVersion: _positive(
      generatorVersion ?? this.generatorVersion,
      fallback: 1,
    ),
  );

  BusinessPortfolioState replaceBusiness(OwnedBusiness replacement) {
    final index = businesses.indexWhere(
      (business) => business.id == replacement.id,
    );
    if (index < 0) {
      return copyWith(businesses: [...businesses, replacement]);
    }
    final next = [...businesses]..[index] = replacement;
    return copyWith(businesses: next);
  }

  BusinessPortfolioState addPendingEvent(BusinessEventInstance event) {
    if (pendingEvents.any((candidate) => candidate.id == event.id) ||
        eventHistory.any((candidate) => candidate.id == event.id)) {
      return this;
    }
    return copyWith(pendingEvents: [...pendingEvents, event]);
  }

  BusinessPortfolioState archiveEvent(BusinessEventInstance event) {
    final pending = pendingEvents
        .where((candidate) => candidate.id != event.id)
        .toList(growable: false);
    final history = <BusinessEventInstance>[
      ...eventHistory.where((candidate) => candidate.id != event.id),
      event,
    ];
    final boundedHistory = history.length <= 200
        ? history
        : history.sublist(history.length - 200);
    return copyWith(pendingEvents: pending, eventHistory: boundedHistory);
  }

  Map<String, dynamic> toJson() => {
    'generatorVersion': generatorVersion,
    'businesses': businesses.map((business) => business.toJson()).toList(),
    'pendingEvents': pendingEvents.map((event) => event.toJson()).toList(),
    'eventHistory': eventHistory.map((event) => event.toJson()).toList(),
    'totalAcquisitionSpend': totalAcquisitionSpend,
    'totalSales': totalSales,
    'totalProfit': totalProfit,
    'totalClosures': totalClosures,
  };

  factory BusinessPortfolioState.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return const BusinessPortfolioState.initial();
    return BusinessPortfolioState(
      generatorVersion: _positiveInt(json['generatorVersion'], fallback: 1),
      businesses: ((json['businesses'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (business) =>
                OwnedBusiness.fromJson(business.cast<String, dynamic>()),
          )
          .where((business) => business.id.isNotEmpty)
          .toList(growable: false),
      pendingEvents: ((json['pendingEvents'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (event) =>
                BusinessEventInstance.fromJson(event.cast<String, dynamic>()),
          )
          .where((event) => event.id.isNotEmpty)
          .toList(growable: false),
      eventHistory: ((json['eventHistory'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (event) =>
                BusinessEventInstance.fromJson(event.cast<String, dynamic>()),
          )
          .where((event) => event.id.isNotEmpty)
          .toList(growable: false),
      totalAcquisitionSpend: _nonNegativeInt(json['totalAcquisitionSpend']),
      totalSales: _nonNegativeInt(json['totalSales']),
      totalProfit: (json['totalProfit'] as num?)?.toInt() ?? 0,
      totalClosures: _nonNegativeInt(json['totalClosures']),
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return fallback;
}

T? _nullableEnumByName<T extends Enum>(List<T> values, Object? raw) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return null;
}

int _policyLevel(int value) => value.clamp(0, 4).toInt();
int _basisPoints(int value) => value.clamp(0, 10000).toInt();
int _score(int value) => value.clamp(0, 100).toInt();
int _scoreInt(Object? value, {required int fallback}) =>
    ((value as num?)?.toInt() ?? fallback).clamp(0, 100).toInt();
int _nonNegative(int value) => value < 0 ? 0 : value;
int _nonNegativeInt(Object? value) =>
    _nonNegative((value as num?)?.toInt() ?? 0);
int _positive(int value, {required int fallback}) =>
    value <= 0 ? fallback : value;
int _positiveInt(Object? value, {required int fallback}) =>
    _positive((value as num?)?.toInt() ?? fallback, fallback: fallback);
