import 'dart:math' as math;

import 'business_districts.dart';
import 'business_state.dart';

const businessWorldGeneratorVersion = 3;
const businessMonthlyStatementHistoryLimit = 60;
const businessEventCooldownDays = 10;
const businessPersistentLossClosureMonths = 12;
const businessPersistentLossMinimumWon = 20000000;

enum BusinessInvestmentKind {
  equipment,
  renovation,
  staffTraining,
  marketingCampaign,
  safety,
  capacity,
}

extension BusinessInvestmentKindLabel on BusinessInvestmentKind {
  String get label => switch (this) {
    BusinessInvestmentKind.equipment => '설비 교체',
    BusinessInvestmentKind.renovation => '매장 리모델링',
    BusinessInvestmentKind.staffTraining => '직원 교육',
    BusinessInvestmentKind.marketingCampaign => '집중 홍보',
    BusinessInvestmentKind.safety => '안전·위생 개선',
    BusinessInvestmentKind.capacity => '좌석·수용량 확장',
  };
}

class BusinessIndustryProfile {
  const BusinessIndustryProfile({
    required this.industry,
    required this.unlockYear,
    required this.baseStartupCost,
    required this.baseAcquisitionPrice,
    required this.baseLeaseDeposit,
    required this.baseMonthlyRent,
    required this.baseEquipmentValue,
    required this.averageTicket,
    required this.baseDailyCustomers,
    required this.variableCostRate,
    required this.monthlyPayrollPerEmployee,
    required this.baseDailyUtilities,
    required this.baseMonthlyMarketing,
    required this.capacity,
    required this.defaultEmployees,
    required this.demandVolatility,
    required this.tags,
  });

  final BusinessIndustry industry;
  final int unlockYear;
  final int baseStartupCost;
  final int baseAcquisitionPrice;
  final int baseLeaseDeposit;
  final int baseMonthlyRent;
  final int baseEquipmentValue;
  final int averageTicket;
  final int baseDailyCustomers;
  final double variableCostRate;
  final int monthlyPayrollPerEmployee;
  final int baseDailyUtilities;
  final int baseMonthlyMarketing;
  final int capacity;
  final int defaultEmployees;
  final double demandVolatility;
  final List<String> tags;

  String get id => industry.name;
  String get label => industry.label;
}

const businessIndustryCatalog = <BusinessIndustryProfile>[
  BusinessIndustryProfile(
    industry: BusinessIndustry.pcBang,
    unlockYear: 2000,
    baseStartupCost: 68000000,
    baseAcquisitionPrice: 52000000,
    baseLeaseDeposit: 25000000,
    baseMonthlyRent: 2400000,
    baseEquipmentValue: 42000000,
    averageTicket: 6200,
    baseDailyCustomers: 115,
    variableCostRate: 0.14,
    monthlyPayrollPerEmployee: 1650000,
    baseDailyUtilities: 125000,
    baseMonthlyMarketing: 700000,
    capacity: 60,
    defaultEmployees: 3,
    demandVolatility: 0.19,
    tags: ['digital', 'youth', 'lateNight', 'highElectricity', 'equipment'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.karaoke,
    unlockYear: 2000,
    baseStartupCost: 72000000,
    baseAcquisitionPrice: 58000000,
    baseLeaseDeposit: 30000000,
    baseMonthlyRent: 2800000,
    baseEquipmentValue: 35000000,
    averageTicket: 18000,
    baseDailyCustomers: 48,
    variableCostRate: 0.12,
    monthlyPayrollPerEmployee: 1700000,
    baseDailyUtilities: 85000,
    baseMonthlyMarketing: 800000,
    capacity: 42,
    defaultEmployees: 3,
    demandVolatility: 0.23,
    tags: ['music', 'lateNight', 'noise', 'group', 'equipment'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.cafe,
    unlockYear: 2000,
    baseStartupCost: 48000000,
    baseAcquisitionPrice: 38000000,
    baseLeaseDeposit: 22000000,
    baseMonthlyRent: 2200000,
    baseEquipmentValue: 18000000,
    averageTicket: 7200,
    baseDailyCustomers: 92,
    variableCostRate: 0.31,
    monthlyPayrollPerEmployee: 1650000,
    baseDailyUtilities: 42000,
    baseMonthlyMarketing: 600000,
    capacity: 34,
    defaultEmployees: 3,
    demandVolatility: 0.15,
    tags: ['food', 'trend', 'takeout', 'daytime'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.bakery,
    unlockYear: 2000,
    baseStartupCost: 56000000,
    baseAcquisitionPrice: 43000000,
    baseLeaseDeposit: 23000000,
    baseMonthlyRent: 2100000,
    baseEquipmentValue: 25000000,
    averageTicket: 9200,
    baseDailyCustomers: 78,
    variableCostRate: 0.39,
    monthlyPayrollPerEmployee: 1750000,
    baseDailyUtilities: 58000,
    baseMonthlyMarketing: 450000,
    capacity: 40,
    defaultEmployees: 4,
    demandVolatility: 0.13,
    tags: ['food', 'freshness', 'morning', 'inventory'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.koreanRestaurant,
    unlockYear: 2000,
    baseStartupCost: 65000000,
    baseAcquisitionPrice: 52000000,
    baseLeaseDeposit: 28000000,
    baseMonthlyRent: 2600000,
    baseEquipmentValue: 23000000,
    averageTicket: 13500,
    baseDailyCustomers: 76,
    variableCostRate: 0.43,
    monthlyPayrollPerEmployee: 1800000,
    baseDailyUtilities: 72000,
    baseMonthlyMarketing: 500000,
    capacity: 44,
    defaultEmployees: 5,
    demandVolatility: 0.14,
    tags: ['food', 'lunch', 'dinner', 'hygiene'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.fastFood,
    unlockYear: 2000,
    baseStartupCost: 76000000,
    baseAcquisitionPrice: 61000000,
    baseLeaseDeposit: 30000000,
    baseMonthlyRent: 2900000,
    baseEquipmentValue: 28000000,
    averageTicket: 9800,
    baseDailyCustomers: 118,
    variableCostRate: 0.38,
    monthlyPayrollPerEmployee: 1650000,
    baseDailyUtilities: 76000,
    baseMonthlyMarketing: 900000,
    capacity: 46,
    defaultEmployees: 6,
    demandVolatility: 0.16,
    tags: ['food', 'youth', 'delivery', 'highTurnover'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.convenienceStore,
    unlockYear: 2000,
    baseStartupCost: 44000000,
    baseAcquisitionPrice: 36000000,
    baseLeaseDeposit: 18000000,
    baseMonthlyRent: 1900000,
    baseEquipmentValue: 12000000,
    averageTicket: 6100,
    baseDailyCustomers: 205,
    variableCostRate: 0.69,
    monthlyPayrollPerEmployee: 1600000,
    baseDailyUtilities: 50000,
    baseMonthlyMarketing: 250000,
    capacity: 28,
    defaultEmployees: 4,
    demandVolatility: 0.10,
    tags: ['retail', 'lateNight', 'inventory', 'necessity'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.studyCafe,
    unlockYear: 2009,
    baseStartupCost: 62000000,
    baseAcquisitionPrice: 49000000,
    baseLeaseDeposit: 26000000,
    baseMonthlyRent: 2300000,
    baseEquipmentValue: 27000000,
    averageTicket: 10500,
    baseDailyCustomers: 68,
    variableCostRate: 0.08,
    monthlyPayrollPerEmployee: 1700000,
    baseDailyUtilities: 63000,
    baseMonthlyMarketing: 400000,
    capacity: 52,
    defaultEmployees: 2,
    demandVolatility: 0.17,
    tags: ['education', 'quiet', 'youth', 'subscription'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.fitnessCenter,
    unlockYear: 2000,
    baseStartupCost: 105000000,
    baseAcquisitionPrice: 82000000,
    baseLeaseDeposit: 40000000,
    baseMonthlyRent: 3600000,
    baseEquipmentValue: 52000000,
    averageTicket: 11500,
    baseDailyCustomers: 82,
    variableCostRate: 0.09,
    monthlyPayrollPerEmployee: 2100000,
    baseDailyUtilities: 88000,
    baseMonthlyMarketing: 1100000,
    capacity: 70,
    defaultEmployees: 5,
    demandVolatility: 0.18,
    tags: ['health', 'subscription', 'equipment', 'safety'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.coinLaundry,
    unlockYear: 2003,
    baseStartupCost: 78000000,
    baseAcquisitionPrice: 62000000,
    baseLeaseDeposit: 18000000,
    baseMonthlyRent: 1500000,
    baseEquipmentValue: 50000000,
    averageTicket: 8500,
    baseDailyCustomers: 42,
    variableCostRate: 0.13,
    monthlyPayrollPerEmployee: 1650000,
    baseDailyUtilities: 105000,
    baseMonthlyMarketing: 220000,
    capacity: 24,
    defaultEmployees: 1,
    demandVolatility: 0.11,
    tags: ['unmanned', 'equipment', 'highUtilities', 'necessity'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.hairSalon,
    unlockYear: 2000,
    baseStartupCost: 39000000,
    baseAcquisitionPrice: 32000000,
    baseLeaseDeposit: 17000000,
    baseMonthlyRent: 1700000,
    baseEquipmentValue: 9000000,
    averageTicket: 28000,
    baseDailyCustomers: 25,
    variableCostRate: 0.17,
    monthlyPayrollPerEmployee: 2200000,
    baseDailyUtilities: 35000,
    baseMonthlyMarketing: 500000,
    capacity: 10,
    defaultEmployees: 3,
    demandVolatility: 0.14,
    tags: ['service', 'appointment', 'staffSkill', 'repeatCustomer'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.nailSalon,
    unlockYear: 2003,
    baseStartupCost: 32000000,
    baseAcquisitionPrice: 25000000,
    baseLeaseDeposit: 14000000,
    baseMonthlyRent: 1400000,
    baseEquipmentValue: 6000000,
    averageTicket: 36000,
    baseDailyCustomers: 15,
    variableCostRate: 0.19,
    monthlyPayrollPerEmployee: 2100000,
    baseDailyUtilities: 18000,
    baseMonthlyMarketing: 600000,
    capacity: 7,
    defaultEmployees: 2,
    demandVolatility: 0.18,
    tags: ['service', 'appointment', 'trend', 'staffSkill'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.arcade,
    unlockYear: 2000,
    baseStartupCost: 59000000,
    baseAcquisitionPrice: 47000000,
    baseLeaseDeposit: 24000000,
    baseMonthlyRent: 2300000,
    baseEquipmentValue: 33000000,
    averageTicket: 5500,
    baseDailyCustomers: 102,
    variableCostRate: 0.08,
    monthlyPayrollPerEmployee: 1650000,
    baseDailyUtilities: 73000,
    baseMonthlyMarketing: 500000,
    capacity: 55,
    defaultEmployees: 2,
    demandVolatility: 0.22,
    tags: ['youth', 'entertainment', 'equipment', 'trend'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.boardGameCafe,
    unlockYear: 2004,
    baseStartupCost: 43000000,
    baseAcquisitionPrice: 33000000,
    baseLeaseDeposit: 18000000,
    baseMonthlyRent: 1800000,
    baseEquipmentValue: 9000000,
    averageTicket: 11000,
    baseDailyCustomers: 46,
    variableCostRate: 0.22,
    monthlyPayrollPerEmployee: 1700000,
    baseDailyUtilities: 30000,
    baseMonthlyMarketing: 650000,
    capacity: 38,
    defaultEmployees: 3,
    demandVolatility: 0.20,
    tags: ['youth', 'group', 'entertainment', 'food'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.petGrooming,
    unlockYear: 2011,
    baseStartupCost: 41000000,
    baseAcquisitionPrice: 34000000,
    baseLeaseDeposit: 16000000,
    baseMonthlyRent: 1500000,
    baseEquipmentValue: 11000000,
    averageTicket: 47000,
    baseDailyCustomers: 12,
    variableCostRate: 0.18,
    monthlyPayrollPerEmployee: 2250000,
    baseDailyUtilities: 33000,
    baseMonthlyMarketing: 550000,
    capacity: 8,
    defaultEmployees: 2,
    demandVolatility: 0.16,
    tags: ['service', 'appointment', 'pet', 'safety'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.deliveryKitchen,
    unlockYear: 2010,
    baseStartupCost: 36000000,
    baseAcquisitionPrice: 29000000,
    baseLeaseDeposit: 10000000,
    baseMonthlyRent: 1200000,
    baseEquipmentValue: 16000000,
    averageTicket: 17500,
    baseDailyCustomers: 63,
    variableCostRate: 0.46,
    monthlyPayrollPerEmployee: 1800000,
    baseDailyUtilities: 62000,
    baseMonthlyMarketing: 1200000,
    capacity: 36,
    defaultEmployees: 4,
    demandVolatility: 0.21,
    tags: ['food', 'delivery', 'platform', 'hygiene'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.photographyStudio,
    unlockYear: 2000,
    baseStartupCost: 46000000,
    baseAcquisitionPrice: 37000000,
    baseLeaseDeposit: 18000000,
    baseMonthlyRent: 1600000,
    baseEquipmentValue: 21000000,
    averageTicket: 58000,
    baseDailyCustomers: 9,
    variableCostRate: 0.16,
    monthlyPayrollPerEmployee: 2100000,
    baseDailyUtilities: 24000,
    baseMonthlyMarketing: 700000,
    capacity: 7,
    defaultEmployees: 2,
    demandVolatility: 0.24,
    tags: ['service', 'appointment', 'equipment', 'seasonal'],
  ),
  BusinessIndustryProfile(
    industry: BusinessIndustry.usedBookStore,
    unlockYear: 2000,
    baseStartupCost: 28000000,
    baseAcquisitionPrice: 22000000,
    baseLeaseDeposit: 13000000,
    baseMonthlyRent: 1200000,
    baseEquipmentValue: 4000000,
    averageTicket: 12500,
    baseDailyCustomers: 31,
    variableCostRate: 0.47,
    monthlyPayrollPerEmployee: 1700000,
    baseDailyUtilities: 15000,
    baseMonthlyMarketing: 280000,
    capacity: 24,
    defaultEmployees: 2,
    demandVolatility: 0.12,
    tags: ['retail', 'education', 'inventory', 'community'],
  ),
];

BusinessIndustryProfile businessIndustryProfileFor(BusinessIndustry industry) =>
    businessIndustryCatalog.firstWhere(
      (profile) => profile.industry == industry,
    );

class BusinessLocationProfile {
  const BusinessLocationProfile({
    required this.id,
    required this.label,
    required this.description,
    required this.demandMultiplier,
    required this.rentMultiplier,
    required this.competitionMultiplier,
    required this.volatilityMultiplier,
    required this.tags,
  });

  final String id;
  final String label;
  final String description;
  final double demandMultiplier;
  final double rentMultiplier;
  final double competitionMultiplier;
  final double volatilityMultiplier;
  final List<String> tags;
}

const businessLocationCatalog = <BusinessLocationProfile>[
  BusinessLocationProfile(
    id: 'university',
    label: '대학가',
    description: '젊은 손님과 방학 변동이 크고 가격에 민감합니다.',
    demandMultiplier: 1.12,
    rentMultiplier: 1.05,
    competitionMultiplier: 1.18,
    volatilityMultiplier: 1.20,
    tags: ['youth', 'night', 'seasonal'],
  ),
  BusinessLocationProfile(
    id: 'office',
    label: '오피스 상권',
    description: '평일 점심 수요가 강하지만 주말과 경기침체에 약합니다.',
    demandMultiplier: 1.16,
    rentMultiplier: 1.30,
    competitionMultiplier: 1.12,
    volatilityMultiplier: 1.08,
    tags: ['worker', 'weekday', 'lunch'],
  ),
  BusinessLocationProfile(
    id: 'residential',
    label: '주거 밀집지',
    description: '단골과 생활수요가 안정적이며 심야 수요는 작습니다.',
    demandMultiplier: 0.98,
    rentMultiplier: 0.82,
    competitionMultiplier: 0.92,
    volatilityMultiplier: 0.82,
    tags: ['family', 'repeatCustomer', 'stable'],
  ),
  BusinessLocationProfile(
    id: 'station',
    label: '역세권',
    description: '유동인구가 많고 임대료와 경쟁도 함께 높습니다.',
    demandMultiplier: 1.25,
    rentMultiplier: 1.48,
    competitionMultiplier: 1.25,
    volatilityMultiplier: 1.05,
    tags: ['transit', 'highTraffic', 'takeout'],
  ),
  BusinessLocationProfile(
    id: 'traditional_market',
    label: '전통시장',
    description: '임대료가 낮고 생활수요가 있으나 객단가가 낮습니다.',
    demandMultiplier: 0.92,
    rentMultiplier: 0.65,
    competitionMultiplier: 0.88,
    volatilityMultiplier: 0.92,
    tags: ['community', 'value', 'daytime'],
  ),
  BusinessLocationProfile(
    id: 'entertainment',
    label: '번화가',
    description: '야간 소비와 유행 수요가 강한 대신 민원과 임대료 위험이 큽니다.',
    demandMultiplier: 1.31,
    rentMultiplier: 1.58,
    competitionMultiplier: 1.34,
    volatilityMultiplier: 1.32,
    tags: ['night', 'trend', 'group', 'noise'],
  ),
];

BusinessLocationProfile? businessLocationProfileById(String id) {
  for (final location in businessLocationCatalog) {
    if (location.id == id) return location;
  }
  return null;
}

class BusinessListing {
  const BusinessListing({
    required this.id,
    required this.industry,
    required this.mode,
    required this.locationId,
    this.districtId = '',
    this.districtRentIndexBps = 10000,
    required this.title,
    required this.askingPrice,
    required this.leaseDeposit,
    required this.monthlyRent,
    required this.equipmentBookValue,
    required this.goodwill,
    required this.condition,
    required this.reputation,
    required this.priorMonthlySalesEstimate,
    required this.employeeCount,
    required this.capacity,
    required this.averageTicket,
    required this.baseDailyCustomers,
    required this.availableFrom,
    required this.expiresOn,
    required this.riskSignals,
    this.generatorVersion = businessWorldGeneratorVersion,
  });

  final String id;
  final BusinessIndustry industry;
  final BusinessListingMode mode;
  final String locationId;
  final String districtId;
  final int districtRentIndexBps;
  final String title;
  final int askingPrice;
  final int leaseDeposit;
  final int monthlyRent;
  final int equipmentBookValue;
  final int goodwill;
  final int condition;
  final int reputation;
  final int priorMonthlySalesEstimate;
  final int employeeCount;
  final int capacity;
  final int averageTicket;
  final int baseDailyCustomers;
  final DateTime availableFrom;
  final DateTime expiresOn;
  final List<String> riskSignals;
  final int generatorVersion;

  int get totalInitialCashRequired => askingPrice + leaseDeposit;

  bool isAvailableOn(DateTime date) =>
      !date.isBefore(availableFrom) && !date.isAfter(expiresOn);

  Map<String, dynamic> toJson() => {
    'id': id,
    'industry': industry.name,
    'mode': mode.name,
    'locationId': locationId,
    'districtId': districtId,
    'districtRentIndexBps': districtRentIndexBps,
    'title': title,
    'askingPrice': askingPrice,
    'leaseDeposit': leaseDeposit,
    'monthlyRent': monthlyRent,
    'equipmentBookValue': equipmentBookValue,
    'goodwill': goodwill,
    'condition': condition,
    'reputation': reputation,
    'priorMonthlySalesEstimate': priorMonthlySalesEstimate,
    'employeeCount': employeeCount,
    'capacity': capacity,
    'averageTicket': averageTicket,
    'baseDailyCustomers': baseDailyCustomers,
    'availableFrom': _businessDateKey(availableFrom),
    'expiresOn': _businessDateKey(expiresOn),
    'riskSignals': riskSignals,
    'generatorVersion': generatorVersion,
  };

  factory BusinessListing.fromJson(Map<String, dynamic> json) {
    final available =
        DateTime.tryParse(json['availableFrom'] as String? ?? '') ??
        DateTime(2000, 1, 1);
    return BusinessListing(
      id: json['id'] as String? ?? '',
      industry: _enumByName(
        BusinessIndustry.values,
        json['industry'],
        BusinessIndustry.cafe,
      ),
      mode: _enumByName(
        BusinessListingMode.values,
        json['mode'],
        BusinessListingMode.startup,
      ),
      locationId: json['locationId'] as String? ?? 'residential',
      districtId: json['districtId'] as String? ?? '',
      districtRentIndexBps: math.max(
        1,
        (json['districtRentIndexBps'] as num?)?.toInt() ?? 10000,
      ),
      title: json['title'] as String? ?? '',
      askingPrice: _nonNegativeJsonInt(json['askingPrice']),
      leaseDeposit: _nonNegativeJsonInt(json['leaseDeposit']),
      monthlyRent: _nonNegativeJsonInt(json['monthlyRent']),
      equipmentBookValue: _nonNegativeJsonInt(json['equipmentBookValue']),
      goodwill: _nonNegativeJsonInt(json['goodwill']),
      condition: _jsonScore(json['condition'], 70),
      reputation: _jsonScore(json['reputation'], 50),
      priorMonthlySalesEstimate: _nonNegativeJsonInt(
        json['priorMonthlySalesEstimate'],
      ),
      employeeCount: _nonNegativeJsonInt(json['employeeCount']),
      capacity: _nonNegativeJsonInt(json['capacity']),
      averageTicket: _nonNegativeJsonInt(json['averageTicket']),
      baseDailyCustomers: _nonNegativeJsonInt(json['baseDailyCustomers']),
      availableFrom: available,
      expiresOn:
          DateTime.tryParse(json['expiresOn'] as String? ?? '') ??
          available.add(const Duration(days: 60)),
      riskSignals: ((json['riskSignals'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
      generatorVersion: (json['generatorVersion'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Reprices the micro-location archetype while keeping the district quote fixed.
///
/// The listing already contains its month-start district price. Both the UI and
/// engine use this function so changing "역세권/대학가" cannot display one
/// deposit and withdraw another.
BusinessListing repriceBusinessListingForLocation({
  required BusinessListing listing,
  required String locationId,
}) {
  final selected =
      businessLocationProfileById(locationId) ??
      businessLocationProfileById('residential')!;
  final original =
      businessLocationProfileById(listing.locationId) ??
      businessLocationProfileById('residential')!;
  final rentRatio =
      selected.rentMultiplier / math.max(0.01, original.rentMultiplier);
  return BusinessListing(
    id: listing.id,
    industry: listing.industry,
    mode: listing.mode,
    locationId: selected.id,
    districtId: listing.districtId,
    districtRentIndexBps: listing.districtRentIndexBps,
    title: listing.title,
    askingPrice: listing.askingPrice,
    leaseDeposit: (listing.leaseDeposit * rentRatio).round(),
    monthlyRent: (listing.monthlyRent * rentRatio).round(),
    equipmentBookValue: listing.equipmentBookValue,
    goodwill: listing.goodwill,
    condition: listing.condition,
    reputation: listing.reputation,
    priorMonthlySalesEstimate: listing.priorMonthlySalesEstimate,
    employeeCount: listing.employeeCount,
    capacity: listing.capacity,
    averageTicket: listing.averageTicket,
    baseDailyCustomers: listing.baseDailyCustomers,
    availableFrom: listing.availableFrom,
    expiresOn: listing.expiresOn,
    riskSignals: listing.riskSignals,
    generatorVersion: listing.generatorVersion,
  );
}

List<BusinessListing> generateBusinessListings({
  required String worldSeed,
  required DateTime asOfDate,
  int count = 24,
  int generatorVersion = businessWorldGeneratorVersion,
}) {
  final safeCount = count.clamp(2, 120).toInt();
  final monthStart = DateTime(asOfDate.year, asOfDate.month, 1);
  final monthKey =
      '${asOfDate.year}-${asOfDate.month.toString().padLeft(2, '0')}';
  final eligible = businessIndustryCatalog
      .where((profile) => profile.unlockYear <= asOfDate.year)
      .toList(growable: false);
  if (eligible.isEmpty) return const [];
  final profileOffset =
      stableBusinessHash('$worldSeed:$monthKey:profile-offset') %
      eligible.length;
  final locationOffset =
      stableBusinessHash('$worldSeed:$monthKey:location-offset') %
      businessLocationCatalog.length;
  final districtOffset =
      stableBusinessHash('$worldSeed:$monthKey:district-offset') %
      businessDistrictCatalog.length;
  final listings = <BusinessListing>[];
  for (var index = 0; index < safeCount; index += 1) {
    final profile = eligible[(profileOffset + index) % eligible.length];
    final location =
        businessLocationCatalog[(locationOffset + index * 5) %
            businessLocationCatalog.length];
    final districtProfile =
        businessDistrictCatalog[(districtOffset + index * 7) %
            businessDistrictCatalog.length];
    final district = businessDistrictSnapshotFor(
      districtProfile,
      asOf: monthStart,
      worldSeed: worldSeed,
      generatorVersion: businessDistrictVersionForBusinessWorld(
        generatorVersion,
      ),
    );
    final industryFit = businessDistrictIndustryFit(
      districtProfile,
      profile.industry,
    );
    final localDemandFactor =
        (district.demandMultiplier /
                math.max(0.55, district.competitionMultiplier) *
                industryFit)
            .clamp(0.52, 1.72);
    final mode = index.isEven
        ? BusinessListingMode.startup
        : BusinessListingMode.acquisition;
    final key =
        '$worldSeed:$monthKey:${profile.id}:${location.id}:'
        '${districtProfile.id}:$index';
    final priceNoise = _range(key, 'price', 0.84, 1.22);
    final rentNoise = _range(key, 'rent', 0.91, 1.12);
    final condition = mode == BusinessListingMode.startup
        ? 82 + stableBusinessHash('$key:condition') % 15
        : 42 + stableBusinessHash('$key:condition') % 49;
    final reputation = mode == BusinessListingMode.startup
        ? 38 + stableBusinessHash('$key:reputation') % 10
        : 28 + stableBusinessHash('$key:reputation') % 54;
    final equipmentValue =
        (profile.baseEquipmentValue *
                (mode == BusinessListingMode.startup
                    ? 1.0
                    : 0.48 + condition / 180) *
                priceNoise)
            .round();
    final goodwill = mode == BusinessListingMode.acquisition
        ? (profile.baseAcquisitionPrice *
                  (0.12 + reputation / 250) *
                  _range(key, 'goodwill', 0.78, 1.24) *
                  localDemandFactor)
              .round()
        : 0;
    final askingPrice = mode == BusinessListingMode.startup
        ? (profile.baseStartupCost * priceNoise).round()
        : (equipmentValue + goodwill).round();
    final monthlyRent =
        (profile.baseMonthlyRent *
                location.rentMultiplier *
                rentNoise *
                district.rentMultiplier *
                _businessEraCostIndex(asOfDate))
            .round();
    final leaseDeposit =
        (profile.baseLeaseDeposit *
                location.rentMultiplier *
                _range(key, 'deposit', 0.85, 1.18) *
                district.rentMultiplier *
                _businessEraCostIndex(asOfDate))
            .round();
    final salesEstimate = mode == BusinessListingMode.acquisition
        ? (profile.averageTicket *
                  profile.baseDailyCustomers *
                  30 *
                  location.demandMultiplier *
                  localDemandFactor *
                  (0.72 + reputation / 180) *
                  _range(key, 'sales', 0.82, 1.18))
              .round()
        : 0;
    final riskSignals = _listingRiskSignals(
      profile,
      location,
      district,
      key,
      condition,
      mode,
    );
    final expiryDays = 45 + stableBusinessHash('$key:expiry') % 76;
    listings.add(
      BusinessListing(
        id:
            'business-listing-$monthKey-${profile.id}-${location.id}-'
            '${districtProfile.id}-$index',
        industry: profile.industry,
        mode: mode,
        locationId: location.id,
        districtId: districtProfile.id,
        districtRentIndexBps:
            (district.rentMultiplier *
                    businessEraCostIndexAt(monthStart) *
                    10000)
                .round(),
        title: mode == BusinessListingMode.startup
            ? '${district.name}·${location.label} ${profile.label} 신규 창업'
            : '${district.name}·${location.label} ${profile.label} 영업권 인수',
        askingPrice: askingPrice,
        leaseDeposit: leaseDeposit,
        monthlyRent: monthlyRent,
        equipmentBookValue: equipmentValue,
        goodwill: goodwill,
        condition: condition,
        reputation: reputation,
        priorMonthlySalesEstimate: salesEstimate,
        employeeCount: math.max(
          1,
          profile.defaultEmployees +
              (stableBusinessHash('$key:employees') % 3) -
              1,
        ),
        capacity: math.max(
          1,
          (profile.capacity * _range(key, 'capacity', 0.82, 1.22)).round(),
        ),
        averageTicket: math.max(
          1000,
          (profile.averageTicket * _range(key, 'ticket', 0.91, 1.13)).round(),
        ),
        baseDailyCustomers: math.max(
          1,
          (profile.baseDailyCustomers * _range(key, 'customers', 0.84, 1.18))
              .round(),
        ),
        availableFrom: monthStart,
        expiresOn: monthStart.add(Duration(days: expiryDays)),
        riskSignals: riskSignals,
        generatorVersion: generatorVersion,
      ),
    );
  }
  return List<BusinessListing>.unmodifiable(listings);
}

String businessListingsFingerprint({
  required String worldSeed,
  required DateTime asOfDate,
  int count = 24,
  int generatorVersion = businessWorldGeneratorVersion,
}) {
  final listings = generateBusinessListings(
    worldSeed: worldSeed,
    asOfDate: asOfDate,
    count: count,
    generatorVersion: generatorVersion,
  );
  final payload = listings
      .map(
        (listing) =>
            '${listing.id}:${listing.askingPrice}:${listing.monthlyRent}:'
            '${listing.districtId}:${listing.districtRentIndexBps}:'
            '${listing.condition}:${listing.reputation}:'
            '${listing.riskSignals.join(',')}',
      )
      .join('|');
  return stableBusinessHash(payload).toRadixString(16).padLeft(8, '0');
}

OwnedBusiness createOwnedBusinessFromListing({
  required BusinessListing listing,
  required String businessId,
  required String name,
  required int acquiredDay,
  required DateTime openedDate,
  BusinessOperatingPolicy policy = BusinessOperatingPolicy.neutral,
  BusinessPremiseMode premiseMode = BusinessPremiseMode.leased,
  String? linkedRealEstateId,
}) {
  final usesOwnedProperty =
      premiseMode == BusinessPremiseMode.ownedProperty &&
      linkedRealEstateId != null &&
      linkedRealEstateId.isNotEmpty;
  return OwnedBusiness(
    id: businessId,
    name: name.trim().isEmpty ? listing.industry.label : name.trim(),
    industry: listing.industry,
    locationId: listing.locationId,
    districtId: listing.districtId,
    districtRentIndexAtOpenBps: listing.districtRentIndexBps,
    listingMode: listing.mode,
    premiseMode: usesOwnedProperty
        ? BusinessPremiseMode.ownedProperty
        : BusinessPremiseMode.leased,
    openedDateIso: _businessDateKey(openedDate),
    acquiredDay: math.max(1, acquiredDay),
    acquisitionPrice: listing.askingPrice,
    leaseDeposit: usesOwnedProperty ? 0 : listing.leaseDeposit,
    monthlyRent: usesOwnedProperty ? 0 : listing.monthlyRent,
    equipmentBookValue: listing.equipmentBookValue,
    goodwillBookValue: listing.goodwill,
    employeeCount: listing.employeeCount,
    capacity: listing.capacity,
    averageTicket: listing.averageTicket,
    baseDailyCustomers: listing.baseDailyCustomers,
    linkedRealEstateId: usesOwnedProperty ? linkedRealEstateId : null,
    generatorVersion: listing.generatorVersion,
    policy: policy,
    reputation: listing.reputation,
    customerLoyalty: listing.mode == BusinessListingMode.acquisition
        ? (listing.reputation * 0.65).round().clamp(15, 70)
        : 24,
    equipmentCondition: listing.condition,
    staffMorale: listing.mode == BusinessListingMode.acquisition ? 58 : 66,
    riskLevel: (65 - listing.condition ~/ 2).clamp(10, 65),
    totalInvested:
        listing.askingPrice + (usesOwnedProperty ? 0 : listing.leaseDeposit),
  );
}

class BusinessInvestmentPlan {
  const BusinessInvestmentPlan({
    required this.kind,
    required this.cost,
    required this.description,
    required this.conditionDelta,
    required this.reputationDelta,
    required this.staffMoraleDelta,
    required this.riskDelta,
    required this.demandMomentumDeltaBps,
    required this.capacityDelta,
    required this.equipmentValueDelta,
  });

  final BusinessInvestmentKind kind;
  final int cost;
  final String description;
  final int conditionDelta;
  final int reputationDelta;
  final int staffMoraleDelta;
  final int riskDelta;
  final int demandMomentumDeltaBps;
  final int capacityDelta;
  final int equipmentValueDelta;
}

BusinessInvestmentPlan businessInvestmentPlanFor(
  OwnedBusiness business,
  BusinessInvestmentKind kind,
) {
  final scale = (business.acquisitionPrice / 50000000).clamp(0.45, 8.0);
  int cost(int base) => (base * scale).round();
  return switch (kind) {
    BusinessInvestmentKind.equipment => BusinessInvestmentPlan(
      kind: kind,
      cost: cost(7000000),
      description: '노후 핵심 설비를 교체해 고장 위험과 처리 병목을 줄입니다.',
      conditionDelta: 24,
      reputationDelta: 2,
      staffMoraleDelta: 3,
      riskDelta: -14,
      demandMomentumDeltaBps: 250,
      capacityDelta: 0,
      equipmentValueDelta: cost(5600000),
    ),
    BusinessInvestmentKind.renovation => BusinessInvestmentPlan(
      kind: kind,
      cost: cost(11000000),
      description: '동선과 인테리어를 전면 개선해 평판과 신규 방문을 높입니다.',
      conditionDelta: 18,
      reputationDelta: 8,
      staffMoraleDelta: 2,
      riskDelta: -5,
      demandMomentumDeltaBps: 700,
      capacityDelta: 0,
      equipmentValueDelta: cost(5000000),
    ),
    BusinessInvestmentKind.staffTraining => BusinessInvestmentPlan(
      kind: kind,
      cost: cost(1800000),
      description: '응대·안전·운영 교육으로 서비스 편차와 실수를 줄입니다.',
      conditionDelta: 0,
      reputationDelta: 4,
      staffMoraleDelta: 12,
      riskDelta: -7,
      demandMomentumDeltaBps: 180,
      capacityDelta: 0,
      equipmentValueDelta: 0,
    ),
    BusinessInvestmentKind.marketingCampaign => BusinessInvestmentPlan(
      kind: kind,
      cost: cost(3000000),
      description: '지역 쿠폰과 온라인 홍보를 묶어 단기 방문을 크게 늘립니다.',
      conditionDelta: 0,
      reputationDelta: 3,
      staffMoraleDelta: -2,
      riskDelta: 2,
      demandMomentumDeltaBps: 1200,
      capacityDelta: 0,
      equipmentValueDelta: 0,
    ),
    BusinessInvestmentKind.safety => BusinessInvestmentPlan(
      kind: kind,
      cost: cost(4200000),
      description: '소방·위생·방범 설비와 점검 절차를 강화합니다.',
      conditionDelta: 9,
      reputationDelta: 3,
      staffMoraleDelta: 4,
      riskDelta: -18,
      demandMomentumDeltaBps: 80,
      capacityDelta: 0,
      equipmentValueDelta: cost(3000000),
    ),
    BusinessInvestmentKind.capacity => BusinessInvestmentPlan(
      kind: kind,
      cost: cost(9000000),
      description: '좌석·룸·작업대를 늘려 성수기 최대 매출을 높입니다.',
      conditionDelta: -3,
      reputationDelta: 1,
      staffMoraleDelta: -3,
      riskDelta: 6,
      demandMomentumDeltaBps: 280,
      capacityDelta: math.max(2, (business.capacity * 0.18).round()),
      equipmentValueDelta: cost(6500000),
    ),
  };
}

class BusinessInvestmentResult {
  const BusinessInvestmentResult({
    required this.business,
    required this.plan,
    required this.cashDelta,
    required this.message,
  });

  final OwnedBusiness business;
  final BusinessInvestmentPlan plan;
  final int cashDelta;
  final String message;
}

BusinessInvestmentResult applyBusinessInvestment(
  OwnedBusiness business,
  BusinessInvestmentKind kind,
) {
  final plan = businessInvestmentPlanFor(business, kind);
  final updated = business.copyWith(
    equipmentBookValue: business.equipmentBookValue + plan.equipmentValueDelta,
    capacity: business.capacity + plan.capacityDelta,
    equipmentCondition: business.equipmentCondition + plan.conditionDelta,
    reputation: business.reputation + plan.reputationDelta,
    staffMorale: business.staffMorale + plan.staffMoraleDelta,
    riskLevel: business.riskLevel + plan.riskDelta,
    demandMomentumBps: business.demandMomentumBps + plan.demandMomentumDeltaBps,
    totalInvested: business.totalInvested + plan.cost,
  );
  return BusinessInvestmentResult(
    business: updated,
    plan: plan,
    cashDelta: -plan.cost,
    message: '${business.name} ${kind.label} 완료 · ${plan.cost}원 투자',
  );
}

BusinessDailyResult simulateBusinessDay({
  required OwnedBusiness business,
  required String worldSeed,
  required DateTime date,
  List<BusinessEventInstance> events = const [],
}) {
  final dateKey = _businessDateKey(date);
  if (!business.isActive ||
      DateTime.tryParse(business.openedDateIso)?.isAfter(date) == true) {
    return BusinessDailyResult(
      businessId: business.id,
      dateIso: dateKey,
      customerCount: 0,
      demandIndexBps: 0,
      grossSales: 0,
      variableCosts: 0,
      payroll: 0,
      rent: 0,
      utilities: 0,
      marketing: 0,
      maintenance: 0,
      eventCosts: 0,
      taxes: 0,
      netProfit: 0,
    );
  }
  final profile = businessIndustryProfileFor(business.industry);
  final location =
      businessLocationProfileById(business.locationId) ??
      businessLocationProfileById('residential')!;
  final districtProfile =
      business.generatorVersion >= 2 && business.districtId.isNotEmpty
      ? businessDistrictProfileById(business.districtId)
      : null;
  final district = districtProfile == null
      ? null
      : businessDistrictOperatingFactorsFor(
          districtProfile,
          asOf: date,
          worldSeed: worldSeed,
          generatorVersion: businessDistrictVersionForBusinessWorld(
            business.generatorVersion,
          ),
        );
  final districtIndustryFit = districtProfile == null
      ? 1.0
      : businessDistrictIndustryFit(districtProfile, business.industry);
  final districtRiskMultiplier = (district?.riskMultiplier ?? 1.0).clamp(
    0.62,
    1.85,
  );
  final policy = business.policy;
  final activeEvents = events
      .where(
        (event) => event.businessId == business.id && event.isActiveOn(date),
      )
      .toList(growable: false);
  final eventDemandBps = activeEvents.fold<int>(
    0,
    (sum, event) => sum + event.dailyDemandDeltaBps,
  );
  final eventCosts = activeEvents.fold<int>(
    0,
    (sum, event) => sum + event.dailyExtraCost,
  );

  final priceDemandFactor = const [1.25, 1.12, 1.0, 0.88, 0.73][policy.pricing];
  final ticketFactor = const [0.82, 0.92, 1.0, 1.11, 1.24][policy.pricing];
  final qualityDemandFactor = const [
    0.78,
    0.90,
    1.0,
    1.10,
    1.19,
  ][policy.quality];
  final qualityTicketFactor = const [
    0.94,
    0.97,
    1.0,
    1.04,
    1.09,
  ][policy.quality];
  final staffingDemandFactor = const [
    0.66,
    0.84,
    1.0,
    1.11,
    1.17,
  ][policy.staffing];
  final marketingDemandFactor = const [
    0.86,
    0.94,
    1.0,
    1.10,
    1.23,
  ][policy.marketing];
  final hoursDemandFactor = const [
    0.68,
    0.84,
    1.0,
    1.13,
    1.26,
  ][policy.openingHours];
  final conditionFactor = (0.58 + business.equipmentCondition / 165).clamp(
    0.55,
    1.18,
  );
  final reputationFactor = (0.62 + business.reputation / 135).clamp(0.55, 1.34);
  final loyaltyFactor = (0.80 + business.customerLoyalty / 250).clamp(
    0.78,
    1.18,
  );
  final staffMoraleFactor = (0.82 + business.staffMorale / 300).clamp(
    0.76,
    1.16,
  );
  final momentumFactor = (1 + business.demandMomentumBps / 10000).clamp(
    0.50,
    1.50,
  );
  final eventDemandFactor = (1 + eventDemandBps / 10000).clamp(0.45, 1.55);
  final demandSwing =
      profile.demandVolatility *
      location.volatilityMultiplier *
      districtRiskMultiplier;
  final demandNoise = _range(
    '$worldSeed:${business.id}:$dateKey',
    'daily-demand',
    1 - demandSwing,
    1 + demandSwing,
  );
  final demandFactor =
      location.demandMultiplier *
      (district?.demandMultiplier ?? 1.0) *
      districtIndustryFit *
      _businessWeekdayFactor(profile, location, date) *
      _businessSeasonality(profile.industry, date) *
      (district == null ? _businessMacroDemandFactor(date) : 1.0) *
      priceDemandFactor *
      qualityDemandFactor *
      staffingDemandFactor *
      marketingDemandFactor *
      hoursDemandFactor *
      conditionFactor *
      reputationFactor *
      loyaltyFactor *
      staffMoraleFactor *
      momentumFactor *
      eventDemandFactor *
      demandNoise /
      location.competitionMultiplier /
      (district?.competitionMultiplier ?? 1.0);
  final maximumCustomers = math.max(
    1,
    (business.capacity * const [1.4, 2.0, 2.7, 3.5, 4.4][policy.openingHours])
        .round(),
  );
  var customerCount = (business.baseDailyCustomers * demandFactor).round();
  customerCount = customerCount.clamp(0, maximumCustomers).toInt();

  final ticket = math.max(
    100,
    (business.averageTicket * ticketFactor * qualityTicketFactor).round(),
  );
  final grossSales = customerCount * ticket;
  final qualityCostFactor = const [0.76, 0.88, 1.0, 1.13, 1.28][policy.quality];
  final variableCosts =
      (grossSales * profile.variableCostRate * qualityCostFactor).round();
  final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
  final staffingCostFactor = const [
    0.62,
    0.80,
    1.0,
    1.23,
    1.48,
  ][policy.staffing];
  final hoursLaborFactor = const [
    0.74,
    0.87,
    1.0,
    1.15,
    1.34,
  ][policy.openingHours];
  final payroll =
      (profile.monthlyPayrollPerEmployee *
              business.employeeCount *
              staffingCostFactor *
              (district?.wageMultiplier ?? 1.0) *
              hoursLaborFactor /
              daysInMonth)
          .round();
  final districtRentRatio = district == null
      ? 1.0
      : (district.rentMultiplier *
                businessEraCostIndexAt(date) *
                10000 /
                math.max(1, business.districtRentIndexAtOpenBps))
            .clamp(0.55, 2.50);
  final rent = business.premiseMode == BusinessPremiseMode.leased
      ? (business.monthlyRent * districtRentRatio / daysInMonth).round()
      : 0;
  final utilityFactor = const [
    0.70,
    0.84,
    1.0,
    1.20,
    1.46,
  ][policy.openingHours];
  final utilities =
      (profile.baseDailyUtilities * utilityFactor * _businessEraCostIndex(date))
          .round();
  final marketingFactor = const [0.10, 0.50, 1.0, 1.75, 2.80][policy.marketing];
  final marketing =
      (profile.baseMonthlyMarketing *
              marketingFactor *
              _businessEraCostIndex(date) /
              daysInMonth)
          .round();
  final maintenanceFactor = const [
    0.18,
    0.55,
    1.0,
    1.65,
    2.50,
  ][policy.maintenance];
  final maintenance =
      (business.equipmentBookValue * 0.012 * maintenanceFactor / daysInMonth)
          .round();
  final breakdownRiskBps =
      ((100 - business.equipmentCondition) * 4 +
              business.riskLevel * 2 +
              policy.openingHours * 24 -
              policy.maintenance * 34)
          .clamp(5, 1100)
          .toInt();
  final breakdownRoll =
      stableBusinessHash('$worldSeed:${business.id}:$dateKey:breakdown') %
      10000;
  final breakdownCost = breakdownRoll < breakdownRiskBps
      ? math.max(
          20000,
          (business.equipmentBookValue *
                  _range(
                    '$worldSeed:${business.id}:$dateKey',
                    'breakdown-cost',
                    0.003,
                    0.018,
                  ))
              .round(),
        )
      : 0;
  final profitBeforeTax =
      grossSales -
      variableCosts -
      payroll -
      rent -
      utilities -
      marketing -
      maintenance -
      eventCosts -
      breakdownCost;
  final taxes = profitBeforeTax > 0 ? (profitBeforeTax * 0.03).round() : 0;
  final netProfit = profitBeforeTax - taxes;
  final normalizedDemandBps = (demandFactor * 10000)
      .round()
      .clamp(0, 50000)
      .toInt();
  return BusinessDailyResult(
    businessId: business.id,
    dateIso: dateKey,
    customerCount: customerCount,
    demandIndexBps: normalizedDemandBps,
    grossSales: grossSales,
    variableCosts: variableCosts,
    payroll: payroll,
    rent: rent,
    utilities: utilities,
    marketing: marketing,
    maintenance: maintenance + breakdownCost,
    eventCosts: eventCosts,
    taxes: taxes,
    netProfit: netProfit,
    activeEventIds: activeEvents
        .map((event) => event.id)
        .toList(growable: false),
  );
}

class BusinessMonthSimulation {
  const BusinessMonthSimulation({
    required this.statement,
    required this.dailyResults,
  });

  final BusinessMonthlyStatement statement;
  final List<BusinessDailyResult> dailyResults;
}

BusinessMonthSimulation simulateBusinessMonth({
  required OwnedBusiness business,
  required String worldSeed,
  required int year,
  required int month,
  List<BusinessEventInstance> events = const [],
}) {
  final safeMonth = month.clamp(1, 12).toInt();
  final dayCount = DateTime(year, safeMonth + 1, 0).day;
  final results = List<BusinessDailyResult>.generate(
    dayCount,
    (index) => simulateBusinessDay(
      business: business,
      worldSeed: worldSeed,
      date: DateTime(year, safeMonth, index + 1),
      events: events,
    ),
    growable: false,
  );
  return summarizeBusinessDays(
    business: business,
    year: year,
    month: safeMonth,
    dailyResults: results,
  );
}

BusinessMonthSimulation summarizeBusinessDays({
  required OwnedBusiness business,
  required int year,
  required int month,
  required List<BusinessDailyResult> dailyResults,
}) {
  final safeMonth = month.clamp(1, 12).toInt();
  final monthPrefix = '$year-${safeMonth.toString().padLeft(2, '0')}-';
  final results =
      dailyResults
          .where(
            (result) =>
                result.businessId == business.id &&
                result.dateIso.startsWith(monthPrefix),
          )
          .toList(growable: false)
        ..sort((left, right) => left.dateIso.compareTo(right.dateIso));
  int sum(int Function(BusinessDailyResult result) select) =>
      results.fold<int>(0, (total, result) => total + select(result));
  final statement = BusinessMonthlyStatement(
    businessId: business.id,
    year: year,
    month: safeMonth,
    operatingDays: results.where((result) => result.grossSales > 0).length,
    customerCount: sum((result) => result.customerCount),
    grossSales: sum((result) => result.grossSales),
    variableCosts: sum((result) => result.variableCosts),
    payroll: sum((result) => result.payroll),
    rent: sum((result) => result.rent),
    utilities: sum((result) => result.utilities),
    marketing: sum((result) => result.marketing),
    maintenance: sum((result) => result.maintenance),
    eventCosts: sum((result) => result.eventCosts),
    taxes: sum((result) => result.taxes),
    netProfit: sum((result) => result.netProfit),
    policySnapshot: business.policy,
    sourceId:
        'business-month-${business.id}-$year-'
        '${safeMonth.toString().padLeft(2, '0')}',
  );
  return BusinessMonthSimulation(statement: statement, dailyResults: results);
}

class BusinessMonthSettlement {
  const BusinessMonthSettlement({
    required this.business,
    required this.statement,
    required this.cashDelta,
    required this.payableChange,
    required this.debtPayment,
    required this.forcedClosure,
    required this.liquidationEstimate,
    required this.alreadySettled,
  });

  final OwnedBusiness business;
  final BusinessMonthlyStatement statement;
  final int cashDelta;
  final int payableChange;
  final int debtPayment;
  final bool forcedClosure;
  final int liquidationEstimate;
  final bool alreadySettled;
}

BusinessMonthSettlement settleBusinessMonth({
  required OwnedBusiness business,
  required BusinessMonthlyStatement statement,
  required int availableBankCash,
}) {
  final monthKey =
      '${statement.year}-${statement.month.toString().padLeft(2, '0')}';
  if (business.lastSettledMonth == monthKey) {
    return BusinessMonthSettlement(
      business: business,
      statement: statement,
      cashDelta: 0,
      payableChange: 0,
      debtPayment: 0,
      forcedClosure: false,
      liquidationEstimate: 0,
      alreadySettled: true,
    );
  }
  final safeBankCash = math.max(0, availableBankCash);
  final priorPayable = business.accountsPayable;
  var nextPayable = priorPayable;
  var cashDelta = 0;
  var debtPayment = 0;
  if (statement.netProfit >= 0) {
    final availableAfterProfit = safeBankCash + statement.netProfit;
    debtPayment = math.min(priorPayable, availableAfterProfit);
    nextPayable -= debtPayment;
    cashDelta = statement.netProfit - debtPayment;
  } else {
    final required = -statement.netProfit;
    final paid = math.min(required, safeBankCash);
    nextPayable += required - paid;
    cashDelta = -paid;
  }
  final lossMonths = statement.netProfit < 0
      ? business.consecutiveLossMonths + 1
      : 0;
  final profitMonths = statement.netProfit > 0
      ? business.consecutiveProfitMonths + 1
      : 0;
  final missedMonths = nextPayable > 0 ? business.missedPaymentMonths + 1 : 0;
  final cumulativeProfitAfterSettlement =
      business.totalProfit + statement.netProfit;
  final persistentLossThreshold = math.max(
    businessPersistentLossMinimumWon,
    business.bookValue ~/ 2,
  );
  final persistentLossClosure =
      business.generatorVersion >= businessWorldGeneratorVersion &&
      lossMonths >= businessPersistentLossClosureMonths &&
      cumulativeProfitAfterSettlement <= -persistentLossThreshold;
  final forcedClosure = missedMonths >= 3 || persistentLossClosure;
  final status = forcedClosure
      ? BusinessStatus.closed
      : nextPayable > 0 || lossMonths >= 3
      ? BusinessStatus.struggling
      : business.status == BusinessStatus.suspended
      ? BusinessStatus.suspended
      : BusinessStatus.operating;
  final serviceSignal = statement.grossSales <= 0
      ? -2
      : statement.netProfit >= 0
      ? 1
      : -1;
  final maintenanceDelta =
      business.policy.maintenance -
      business.policy.openingHours -
      (statement.operatingDays >= 25 ? 1 : 0);
  final equipmentValueAfterDepreciation = math
      .max(
        0,
        business.equipmentBookValue -
            math.max(1, (business.equipmentBookValue * 0.0035).round()),
      )
      .toInt();
  final statements = <BusinessMonthlyStatement>[
    ...business.statements.where(
      (item) => !(item.year == statement.year && item.month == statement.month),
    ),
    statement,
  ];
  final boundedStatements =
      statements.length <= businessMonthlyStatementHistoryLimit
      ? statements
      : statements.sublist(
          statements.length - businessMonthlyStatementHistoryLimit,
        );
  final updated = business.copyWith(
    equipmentBookValue: equipmentValueAfterDepreciation,
    equipmentCondition: business.equipmentCondition + maintenanceDelta,
    reputation: business.reputation + serviceSignal,
    customerLoyalty:
        business.customerLoyalty +
        (statement.netProfit > 0
            ? 1
            : statement.netProfit < 0
            ? -1
            : 0),
    riskLevel:
        business.riskLevel +
        (nextPayable > 0 ? 8 : -1) -
        business.policy.maintenance,
    demandMomentumBps: (business.demandMomentumBps * 0.72).round(),
    accountsPayable: nextPayable,
    consecutiveLossMonths: lossMonths,
    consecutiveProfitMonths: profitMonths,
    missedPaymentMonths: missedMonths,
    totalSales: business.totalSales + statement.grossSales,
    totalProfit: business.totalProfit + statement.netProfit,
    lastSettledMonth: monthKey,
    statements: boundedStatements,
    status: status,
  );
  final liquidationEstimate = forcedClosure
      ? math.max(
          0,
          updated.leaseDeposit +
              (updated.equipmentBookValue *
                      updated.equipmentCondition /
                      100 *
                      0.55)
                  .round() -
              updated.accountsPayable,
        )
      : 0;
  return BusinessMonthSettlement(
    business: updated,
    statement: statement,
    cashDelta: cashDelta,
    payableChange: nextPayable - priorPayable,
    debtPayment: debtPayment,
    forcedClosure: forcedClosure,
    liquidationEstimate: liquidationEstimate,
    alreadySettled: false,
  );
}

BusinessPortfolioState applyBusinessMonthSettlement(
  BusinessPortfolioState portfolio,
  BusinessMonthSettlement settlement,
) {
  if (settlement.alreadySettled) return portfolio;
  final wasClosed =
      portfolio.businessById(settlement.business.id)?.status ==
      BusinessStatus.closed;
  return portfolio
      .replaceBusiness(settlement.business)
      .copyWith(
        totalSales: portfolio.totalSales + settlement.statement.grossSales,
        totalProfit: portfolio.totalProfit + settlement.statement.netProfit,
        totalClosures:
            portfolio.totalClosures +
            (settlement.forcedClosure && !wasClosed ? 1 : 0),
      );
}

class BusinessEventTemplate {
  const BusinessEventTemplate({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.minimumDelayDays,
    required this.maximumDelayDays,
    required this.dailyDemandDeltaBps,
    required this.dailyExtraCost,
    required this.choices,
    this.positiveOpportunity = false,
  });

  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final int minimumDelayDays;
  final int maximumDelayDays;
  final int dailyDemandDeltaBps;
  final int dailyExtraCost;
  final List<BusinessEventChoice> choices;
  final bool positiveOpportunity;
}

final commonBusinessEventTemplates = <BusinessEventTemplate>[
  _opportunityTemplate(
    'viral_review',
    '동네 커뮤니티에서 입소문이 났다',
    '칭찬 게시물이 빠르게 퍼지고 있습니다. 몰려오는 손님을 감당하면서 단골로 바꿀 방법을 정해야 합니다.',
    ['review', 'marketing'],
    2500000,
  ),
  _incidentTemplate(
    'competitor_opening',
    '바로 맞은편에 경쟁 점포가 들어온다',
    '비슷한 가격과 상품을 내세운 새 점포가 개점 준비를 마쳤습니다.',
    ['competition', 'demand'],
    3200000,
  ),
  _opportunityTemplate(
    'competitor_closure',
    '오래된 경쟁 점포가 폐업한다',
    '인근 고정 손님이 새로 갈 곳을 찾고 있습니다.',
    ['competition', 'demand'],
    1800000,
  ),
  _incidentTemplate(
    'supplier_price_spike',
    '주요 납품업체가 단가 인상을 통보했다',
    '원가를 흡수할지, 거래처를 바꿀지, 가격을 올릴지 결정해야 합니다.',
    ['supplier', 'cost'],
    2800000,
  ),
  _incidentTemplate(
    'equipment_failure',
    '핵심 설비에서 반복 고장이 발견됐다',
    '임시 수리로 버틸 수 있지만 영업 중 재고장 가능성이 있습니다.',
    ['equipment', 'repair'],
    6500000,
  ),
  _incidentTemplate(
    'staff_no_show',
    '주말 핵심 근무자가 갑자기 결근했다',
    '남은 직원의 피로와 손님 대기시간이 동시에 늘고 있습니다.',
    ['staff', 'service'],
    1200000,
  ),
  _opportunityTemplate(
    'star_employee',
    '능숙한 경력자가 입사를 제안했다',
    '급여는 높지만 서비스 품질과 교육 속도를 끌어올릴 수 있는 인재입니다.',
    ['staff', 'training'],
    3600000,
  ),
  _incidentTemplate(
    'inventory_theft',
    '재고와 현금 시재가 맞지 않는다',
    '단순 실수인지 내부 절도인지 아직 확정되지 않았습니다.',
    ['security', 'inventory'],
    1900000,
  ),
  _incidentTemplate(
    'hygiene_inspection',
    '예고 없는 위생 점검이 시작됐다',
    '작은 미비점이 발견되어 즉시 시정과 휴업 중 하나를 검토해야 합니다.',
    ['hygiene', 'regulation'],
    2600000,
  ),
  _incidentTemplate(
    'fire_inspection',
    '소방 설비 보완 명령을 받았다',
    '대피 동선과 감지기 일부가 최신 기준에 미달합니다.',
    ['safety', 'regulation'],
    4200000,
  ),
  _incidentTemplate(
    'noise_complaint',
    '인근 주민의 소음 민원이 접수됐다',
    '영업시간과 방음 개선을 두고 주민과 협의가 필요합니다.',
    ['noise', 'community'],
    3100000,
  ),
  _incidentTemplate(
    'refund_wave',
    '같은 사유의 환불 요청이 연달아 들어온다',
    '전액 보상은 평판을 지키지만 현금 부담이 큽니다.',
    ['customer', 'quality'],
    2300000,
  ),
  _opportunityTemplate(
    'local_festival',
    '동네 축제 상권 참여 제안이 왔다',
    '임시 부스와 연장 영업으로 큰 유동인구를 잡을 수 있습니다.',
    ['festival', 'marketing'],
    3000000,
  ),
  _incidentTemplate(
    'construction_detour',
    '도로 공사로 매장 앞 보행 동선이 막혔다',
    '공사는 몇 주 이어지며 안내판이나 배달 전환이 필요합니다.',
    ['traffic', 'construction'],
    1700000,
  ),
  _incidentTemplate(
    'rainy_week',
    '긴 장마 예보가 발표됐다',
    '방문 수요 감소와 누수 위험을 함께 대비해야 합니다.',
    ['weather', 'repair'],
    1500000,
  ),
  _incidentTemplate(
    'heatwave',
    '폭염으로 냉방비와 실내 수요가 동시에 늘었다',
    '쾌적함을 유지하면 손님을 잡지만 전기료 부담이 커집니다.',
    ['weather', 'utilities'],
    2100000,
  ),
  _incidentTemplate(
    'local_recession',
    '지역 소비심리가 빠르게 얼어붙었다',
    '가격 할인, 품질 유지, 비용 축소 중 무엇을 우선할지 정해야 합니다.',
    ['economy', 'demand'],
    3500000,
  ),
  _incidentTemplate(
    'utility_rate_hike',
    '전기·가스 요금 인상이 확정됐다',
    '효율 설비 투자는 비싸지만 장기 비용을 줄일 수 있습니다.',
    ['utilities', 'cost'],
    4800000,
  ),
  _incidentTemplate(
    'rent_renegotiation',
    '건물주가 임대료 재협상을 요구했다',
    '장기계약, 단기 인상 수용, 이전 검토 중 하나를 골라야 합니다.',
    ['rent', 'negotiation'],
    5200000,
  ),
  _opportunityTemplate(
    'delivery_platform_feature',
    '지역 추천 점포 노출 제안이 들어왔다',
    '수수료를 내면 한 달간 신규 손님에게 우선 노출됩니다.',
    ['platform', 'marketing'],
    2400000,
  ),
  _opportunityTemplate(
    'loyalty_program',
    '단골 적립제 도입 제안이 왔다',
    '즉시 할인 비용을 감수하면 재방문 데이터를 쌓을 수 있습니다.',
    ['customer', 'repeatCustomer'],
    1800000,
  ),
  _incidentTemplate(
    'inventory_waste',
    '유통기한 임박 재고가 예상보다 많이 남았다',
    '할인 판매, 기부, 폐기 중 현금과 평판의 균형을 정해야 합니다.',
    ['inventory', 'waste'],
    1600000,
  ),
  _incidentTemplate(
    'insurance_incident',
    '영업 중 고객 안전사고가 발생했다',
    '치료비 지원과 재발 방지 조치 수준에 따라 결과가 달라집니다.',
    ['insurance', 'safety'],
    5600000,
  ),
  _opportunityTemplate(
    'influencer_visit',
    '지역에서 유명한 창작자가 방문했다',
    '협찬을 제안할지 자연스러운 후기를 기다릴지 선택할 수 있습니다.',
    ['review', 'trend'],
    2700000,
  ),
  _opportunityTemplate(
    'public_facility_opening',
    '근처에 공공시설이 새로 문을 연다',
    '새 유동인구에 맞춘 상품과 영업시간 조정 기회입니다.',
    ['district', 'traffic'],
    2200000,
  ),
];

final pcBangBusinessEventTemplates = <BusinessEventTemplate>[
  _opportunityTemplate(
    'pc_blockbuster_launch',
    '대형 온라인게임 출시일이 확정됐다',
    '사전 설치와 좌석 예약, 심야 인력 배치로 출시 특수를 노릴 수 있습니다.',
    ['pcBang', 'gameLaunch'],
    5200000,
  ),
  _opportunityTemplate(
    'pc_esports_tournament',
    '지역 e스포츠 대회 개최 제안이 왔다',
    '상금과 중계 설비가 필요하지만 매장을 지역 거점으로 만들 수 있습니다.',
    ['pcBang', 'esports'],
    8500000,
  ),
  _incidentTemplate(
    'pc_gpu_shortage',
    '그래픽카드 수급난으로 교체 견적이 급등했다',
    '전면 교체, 일부 좌석 우선 교체, 현상 유지의 장단점이 분명합니다.',
    ['pcBang', 'equipment'],
    14000000,
  ),
  _incidentTemplate(
    'pc_network_outage',
    '회선 장애로 전 좌석 접속이 끊겼다',
    '이중 회선 계약은 비싸지만 재발 피해를 크게 줄입니다.',
    ['pcBang', 'network'],
    6200000,
  ),
  _incidentTemplate(
    'pc_account_hacking',
    '손님 계정 도용 의심 신고가 접수됐다',
    '보안 조사와 피해 지원 수준이 매장 신뢰에 영향을 줍니다.',
    ['pcBang', 'security'],
    4800000,
  ),
  _incidentTemplate(
    'pc_youth_curfew',
    '청소년 심야 출입 단속이 강화됐다',
    '신분 확인 시스템과 영업시간 조정이 필요합니다.',
    ['pcBang', 'regulation'],
    3600000,
  ),
  _incidentTemplate(
    'pc_upgrade_cycle',
    '인기 게임 권장사양이 크게 올랐다',
    '좌석 등급화는 투자비를 줄이지만 손님 간 체감 차이를 만듭니다.',
    ['pcBang', 'equipment'],
    11000000,
  ),
  _opportunityTemplate(
    'pc_publisher_promotion',
    '게임사 전용 혜택 가맹 제안이 왔다',
    '월 가맹비를 내면 접속 보상과 공동 홍보를 받을 수 있습니다.',
    ['pcBang', 'partnership'],
    4200000,
  ),
];

final karaokeBusinessEventTemplates = <BusinessEventTemplate>[
  _opportunityTemplate(
    'karaoke_hit_song',
    '전국적인 히트곡 열풍이 시작됐다',
    '신곡 업데이트와 테마룸 홍보로 단체 손님을 선점할 수 있습니다.',
    ['karaoke', 'hitSong'],
    4200000,
  ),
  _incidentTemplate(
    'karaoke_soundproofing',
    '방음 성능 재검사 통보를 받았다',
    '전면 보강은 비싸지만 심야 영업과 민원 위험을 함께 해결합니다.',
    ['karaoke', 'noise'],
    12000000,
  ),
  _incidentTemplate(
    'karaoke_copyright_audit',
    '음원 사용료 정산 감사를 받게 됐다',
    '전수 정산, 협상, 최소 대응에 따라 비용과 법적 위험이 달라집니다.',
    ['karaoke', 'copyright'],
    6800000,
  ),
  _incidentTemplate(
    'karaoke_microphone_failure',
    '무선 마이크 여러 대에서 잡음이 발생한다',
    '전면 교체는 만족도를 높이지만 즉시 비용이 큽니다.',
    ['karaoke', 'equipment'],
    5600000,
  ),
  _incidentTemplate(
    'karaoke_late_night_rule',
    '심야 영업 규정 변경안이 발표됐다',
    '가족형 낮 영업 전환과 기존 심야 수요 방어 중 선택해야 합니다.',
    ['karaoke', 'regulation'],
    5200000,
  ),
  _opportunityTemplate(
    'karaoke_company_dinner',
    '연말 회식 예약 문의가 몰렸다',
    '단체 패키지를 준비하면 큰 매출을 얻지만 일반 손님 자리가 줄어듭니다.',
    ['karaoke', 'group'],
    3800000,
  ),
  _opportunityTemplate(
    'karaoke_song_contract',
    '신곡 우선 공급 계약을 제안받았다',
    '높은 월 사용료 대신 경쟁점보다 먼저 인기곡을 제공할 수 있습니다.',
    ['karaoke', 'music'],
    6100000,
  ),
  _incidentTemplate(
    'karaoke_ventilation',
    '지하 룸 환기 설비 개선 권고가 나왔다',
    '환기 공사는 휴업 부담이 있지만 안전과 쾌적함을 크게 높입니다.',
    ['karaoke', 'safety'],
    9000000,
  ),
];

List<BusinessEventTemplate> businessEventTemplatesFor(
  BusinessIndustry industry,
) => List<BusinessEventTemplate>.unmodifiable([
  ...commonBusinessEventTemplates,
  if (industry == BusinessIndustry.pcBang) ...pcBangBusinessEventTemplates,
  if (industry == BusinessIndustry.karaoke) ...karaokeBusinessEventTemplates,
]);

BusinessEventInstance? generateBusinessEventForDay({
  required OwnedBusiness business,
  required String worldSeed,
  required DateTime date,
  List<BusinessEventInstance> existingEvents = const [],
}) {
  if (!business.isActive) return null;
  if (existingEvents.any(
    (event) =>
        event.businessId == business.id &&
        event.status != BusinessEventStatus.resolved &&
        event.status != BusinessEventStatus.expired,
  )) {
    return null;
  }
  DateTime? latest;
  for (final event in existingEvents.where(
    (candidate) => candidate.businessId == business.id,
  )) {
    final occurred = event.occurredDate;
    if (occurred != null && (latest == null || occurred.isAfter(latest))) {
      latest = occurred;
    }
  }
  if (latest != null &&
      date.difference(latest).inDays < businessEventCooldownDays) {
    return null;
  }
  final dateKey = _businessDateKey(date);
  final districtProfile =
      business.generatorVersion >= 2 && business.districtId.isNotEmpty
      ? businessDistrictProfileById(business.districtId)
      : null;
  final district = districtProfile == null
      ? null
      : businessDistrictSnapshotFor(
          districtProfile,
          asOf: date,
          worldSeed: worldSeed,
          generatorVersion: businessDistrictVersionForBusinessWorld(
            business.generatorVersion,
          ),
        );
  final districtHazard =
      ((district?.riskMultiplier ?? 1.0) *
              math.sqrt(district?.vacancyMultiplier ?? 1.0))
          .clamp(0.65, 1.85);
  final eventChanceBps =
      ((160 +
                  business.riskLevel * 3 +
                  (business.status == BusinessStatus.struggling ? 90 : 0)) *
              districtHazard)
          .clamp(120, 620)
          .toInt();
  final roll =
      stableBusinessHash('$worldSeed:${business.id}:$dateKey:event-roll') %
      10000;
  if (roll >= eventChanceBps) return null;
  final templates = businessEventTemplatesFor(business.industry);
  final template =
      templates[stableBusinessHash(
            '$worldSeed:${business.id}:$dateKey:event-template',
          ) %
          templates.length];
  final delaySpan = template.maximumDelayDays - template.minimumDelayDays + 1;
  final delay =
      template.minimumDelayDays +
      stableBusinessHash(
            '$worldSeed:${business.id}:$dateKey:${template.id}:delay',
          ) %
          math.max(1, delaySpan).toInt();
  final scale = (business.acquisitionPrice / 50000000).clamp(0.45, 8.0);
  final choices = template.choices
      .map((choice) => _scaledEventChoice(choice, scale))
      .toList(growable: false);
  final eventId = 'business-event-${business.id}-$dateKey-${template.id}';
  return BusinessEventInstance(
    id: eventId,
    templateId: template.id,
    businessId: business.id,
    title: template.title,
    body: template.body,
    occurredDateIso: dateKey,
    choiceDueDateIso: _businessDateKey(date.add(const Duration(days: 2))),
    resolutionDateIso: _businessDateKey(date.add(Duration(days: delay))),
    choices: choices,
    tags: template.tags,
    dailyDemandDeltaBps: template.dailyDemandDeltaBps,
    dailyExtraCost: (template.dailyExtraCost * scale).round(),
  );
}

class BusinessEventChoiceApplication {
  const BusinessEventChoiceApplication({
    required this.business,
    required this.event,
    required this.choice,
    required this.cashDelta,
  });

  final OwnedBusiness business;
  final BusinessEventInstance event;
  final BusinessEventChoice choice;
  final int cashDelta;
}

BusinessEventChoiceApplication applyBusinessEventChoice({
  required OwnedBusiness business,
  required BusinessEventInstance event,
  required String choiceId,
  required DateTime selectedAt,
}) {
  if (event.businessId != business.id) {
    throw ArgumentError('The event does not belong to this business.');
  }
  if (event.status != BusinessEventStatus.pendingChoice) {
    throw StateError('This business event no longer accepts a choice.');
  }
  final due = event.choiceDueDate;
  if (due != null && selectedAt.isAfter(due)) {
    throw StateError('The choice deadline has passed.');
  }
  final choice = event.choices.firstWhere(
    (candidate) => candidate.id == choiceId,
    orElse: () => throw ArgumentError.value(
      choiceId,
      'choiceId',
      'Unknown business event choice',
    ),
  );
  final updatedBusiness = business.copyWith(
    reputation: business.reputation + choice.immediateReputationDelta,
    equipmentCondition:
        business.equipmentCondition + choice.immediateConditionDelta,
    staffMorale: business.staffMorale + choice.immediateStaffMoraleDelta,
    riskLevel: business.riskLevel + choice.immediateRiskDelta,
    demandMomentumBps:
        business.demandMomentumBps + choice.immediateDemandDeltaBps,
    totalInvested: business.totalInvested + choice.upfrontCost,
  );
  final updatedEvent = event.copyWith(
    status: BusinessEventStatus.awaitingOutcome,
    selectedChoiceId: choice.id,
  );
  return BusinessEventChoiceApplication(
    business: updatedBusiness,
    event: updatedEvent,
    choice: choice,
    cashDelta: -choice.upfrontCost,
  );
}

class BusinessEventResolution {
  const BusinessEventResolution({
    required this.business,
    required this.event,
    required this.outcome,
    required this.cashDelta,
    required this.resolved,
  });

  final OwnedBusiness business;
  final BusinessEventInstance event;
  final BusinessEventOutcome? outcome;
  final int cashDelta;
  final bool resolved;
}

BusinessEventResolution resolveBusinessEvent({
  required OwnedBusiness business,
  required BusinessEventInstance event,
  required String worldSeed,
  required DateTime asOfDate,
}) {
  if (event.businessId != business.id) {
    throw ArgumentError('The event does not belong to this business.');
  }
  if (event.status == BusinessEventStatus.resolved) {
    return BusinessEventResolution(
      business: business,
      event: event,
      outcome: event.outcome,
      cashDelta: 0,
      resolved: false,
    );
  }
  if (event.status != BusinessEventStatus.awaitingOutcome) {
    return BusinessEventResolution(
      business: business,
      event: event,
      outcome: null,
      cashDelta: 0,
      resolved: false,
    );
  }
  final resolutionDate = event.resolutionDate;
  if (resolutionDate == null || asOfDate.isBefore(resolutionDate)) {
    return BusinessEventResolution(
      business: business,
      event: event,
      outcome: null,
      cashDelta: 0,
      resolved: false,
    );
  }
  final choice = event.selectedChoice;
  if (choice == null) {
    throw StateError('A scheduled business event has no saved choice.');
  }
  final roll =
      stableBusinessHash(
        '$worldSeed:${event.id}:${choice.id}:delayed-outcome',
      ) %
      10000;
  final partialFloor = (choice.successChanceBps + 1600).clamp(0, 10000);
  final outcome = roll < choice.successChanceBps
      ? BusinessEventOutcome.success
      : roll < partialFloor
      ? BusinessEventOutcome.partial
      : BusinessEventOutcome.failure;
  final successWeight = switch (outcome) {
    BusinessEventOutcome.success => 1.0,
    BusinessEventOutcome.partial => 0.45,
    BusinessEventOutcome.failure => 0.0,
  };
  final failureWeight = 1 - successWeight;
  int weighted(int success, int failure) =>
      (success * successWeight + failure * failureWeight).round();
  final cashDelta = weighted(choice.successCashDelta, choice.failureCashDelta);
  final demandDelta = weighted(
    choice.successDemandDeltaBps,
    choice.failureDemandDeltaBps,
  );
  final reputationDelta = weighted(
    choice.successReputationDelta,
    choice.failureReputationDelta,
  );
  final conditionDelta = weighted(
    choice.successConditionDelta,
    choice.failureConditionDelta,
  );
  final moraleDelta = weighted(
    choice.successStaffMoraleDelta,
    choice.failureStaffMoraleDelta,
  );
  final riskDelta = weighted(choice.successRiskDelta, choice.failureRiskDelta);
  final updatedBusiness = business.copyWith(
    reputation: business.reputation + reputationDelta,
    equipmentCondition: business.equipmentCondition + conditionDelta,
    staffMorale: business.staffMorale + moraleDelta,
    riskLevel: business.riskLevel + riskDelta,
    demandMomentumBps: business.demandMomentumBps + demandDelta,
  );
  final outcomeTitle = switch (outcome) {
    BusinessEventOutcome.success => '${event.title} · 대응 성공',
    BusinessEventOutcome.partial => '${event.title} · 절반의 성과',
    BusinessEventOutcome.failure => '${event.title} · 대응 실패',
  };
  final outcomeBody = switch (outcome) {
    BusinessEventOutcome.success =>
      '${choice.label} 선택이 계획대로 작동해 비용 이상의 운영 개선을 남겼습니다.',
    BusinessEventOutcome.partial =>
      '${choice.label} 선택이 일부 효과를 냈지만 예상하지 못한 비용과 지연도 발생했습니다.',
    BusinessEventOutcome.failure =>
      '${choice.label} 선택이 기대한 효과를 내지 못해 후속 수습이 필요합니다.',
  };
  final updatedEvent = event.copyWith(
    status: BusinessEventStatus.resolved,
    outcome: outcome,
    outcomeTitle: outcomeTitle,
    outcomeBody: outcomeBody,
    realizedCashDelta: cashDelta,
    realizedDemandDeltaBps: demandDelta,
    realizedReputationDelta: reputationDelta,
    realizedConditionDelta: conditionDelta,
    realizedStaffMoraleDelta: moraleDelta,
    realizedRiskDelta: riskDelta,
  );
  return BusinessEventResolution(
    business: updatedBusiness,
    event: updatedEvent,
    outcome: outcome,
    cashDelta: cashDelta,
    resolved: true,
  );
}

BusinessEventInstance expireUnansweredBusinessEvent(
  BusinessEventInstance event,
  DateTime asOfDate,
) {
  final due = event.choiceDueDate;
  if (event.status != BusinessEventStatus.pendingChoice ||
      due == null ||
      !asOfDate.isAfter(due)) {
    return event;
  }
  return event.copyWith(
    status: BusinessEventStatus.expired,
    outcomeTitle: '${event.title} · 대응 기한 경과',
    outcomeBody: '결정을 미루는 동안 상황이 자연 종료되어 기회를 잃었습니다.',
  );
}

String businessSimulationFingerprint({
  required OwnedBusiness business,
  required String worldSeed,
  required int year,
  required int month,
  List<BusinessEventInstance> events = const [],
}) {
  final simulation = simulateBusinessMonth(
    business: business,
    worldSeed: worldSeed,
    year: year,
    month: month,
    events: events,
  );
  final statement = simulation.statement;
  final payload =
      '${statement.sourceId}:${statement.customerCount}:'
      '${statement.grossSales}:${statement.totalOperatingCosts}:'
      '${statement.netProfit}:${business.policy.toJson()}';
  return stableBusinessHash(payload).toRadixString(16).padLeft(8, '0');
}

bool sameSeedBusinessSimulationReproduces({
  required OwnedBusiness business,
  required String worldSeed,
  required int year,
  required int month,
  List<BusinessEventInstance> events = const [],
}) {
  final first = businessSimulationFingerprint(
    business: business,
    worldSeed: worldSeed,
    year: year,
    month: month,
    events: events,
  );
  final replay = businessSimulationFingerprint(
    business: business,
    worldSeed: worldSeed,
    year: year,
    month: month,
    events: events,
  );
  return first == replay;
}

int stableBusinessHash(String value) => stableBusinessDistrictHash(value);

double businessDeterministicUnit(String key) =>
    (stableBusinessHash(key) % 1000000) / 999999;

BusinessEventTemplate _incidentTemplate(
  String id,
  String title,
  String body,
  List<String> tags,
  int fullResponseCost,
) => BusinessEventTemplate(
  id: id,
  title: title,
  body: body,
  tags: tags,
  minimumDelayDays: 7,
  maximumDelayDays: 35,
  dailyDemandDeltaBps: -500,
  dailyExtraCost: math.max(15000, fullResponseCost ~/ 90),
  choices: _incidentChoices(id, fullResponseCost),
);

BusinessEventTemplate _opportunityTemplate(
  String id,
  String title,
  String body,
  List<String> tags,
  int fullResponseCost,
) => BusinessEventTemplate(
  id: id,
  title: title,
  body: body,
  tags: tags,
  minimumDelayDays: 7,
  maximumDelayDays: 30,
  dailyDemandDeltaBps: 420,
  dailyExtraCost: 0,
  choices: _opportunityChoices(id, fullResponseCost),
  positiveOpportunity: true,
);

List<BusinessEventChoice> _incidentChoices(String prefix, int fullCost) => [
  BusinessEventChoice(
    id: '${prefix}_full',
    label: '근본 대응',
    description: '현금을 많이 쓰지만 재발 위험과 평판 손상을 함께 막습니다.',
    upfrontCost: fullCost,
    immediateConditionDelta: 6,
    immediateStaffMoraleDelta: 3,
    immediateRiskDelta: -8,
    successChanceBps: 8200,
    successDemandDeltaBps: 650,
    successReputationDelta: 7,
    successConditionDelta: 7,
    successStaffMoraleDelta: 4,
    successRiskDelta: -10,
    failureCashDelta: -(fullCost ~/ 5),
    failureDemandDeltaBps: -180,
    failureReputationDelta: -2,
    failureConditionDelta: -2,
    failureStaffMoraleDelta: -2,
    failureRiskDelta: 3,
  ),
  BusinessEventChoice(
    id: '${prefix}_balanced',
    label: '단계적 대응',
    description: '비용을 절반가량 쓰고 핵심 문제부터 고칩니다.',
    upfrontCost: (fullCost * 0.48).round(),
    immediateConditionDelta: 2,
    immediateRiskDelta: -3,
    successChanceBps: 6100,
    successDemandDeltaBps: 280,
    successReputationDelta: 3,
    successConditionDelta: 3,
    successStaffMoraleDelta: 1,
    successRiskDelta: -4,
    failureCashDelta: -(fullCost ~/ 8),
    failureDemandDeltaBps: -420,
    failureReputationDelta: -4,
    failureConditionDelta: -5,
    failureStaffMoraleDelta: -3,
    failureRiskDelta: 7,
  ),
  BusinessEventChoice(
    id: '${prefix}_cheap',
    label: '최소 비용으로 버티기',
    description: '당장 현금은 아끼지만 손님 이탈과 재발 위험을 감수합니다.',
    upfrontCost: (fullCost * 0.10).round(),
    immediateDemandDeltaBps: -180,
    immediateReputationDelta: -2,
    immediateStaffMoraleDelta: -2,
    immediateRiskDelta: 5,
    successChanceBps: 2900,
    successDemandDeltaBps: 80,
    successReputationDelta: 1,
    successRiskDelta: -1,
    failureCashDelta: -(fullCost ~/ 3),
    failureDemandDeltaBps: -900,
    failureReputationDelta: -8,
    failureConditionDelta: -9,
    failureStaffMoraleDelta: -7,
    failureRiskDelta: 14,
  ),
];

List<BusinessEventChoice> _opportunityChoices(String prefix, int fullCost) => [
  BusinessEventChoice(
    id: '${prefix}_bold',
    label: '기회를 크게 잡기',
    description: '인력과 홍보를 선투자해 최대 성과를 노립니다.',
    upfrontCost: fullCost,
    immediateDemandDeltaBps: 350,
    immediateStaffMoraleDelta: -2,
    immediateRiskDelta: 4,
    successChanceBps: 6900,
    successCashDelta: (fullCost * 1.85).round(),
    successDemandDeltaBps: 1100,
    successReputationDelta: 9,
    successStaffMoraleDelta: 3,
    successRiskDelta: -2,
    failureCashDelta: -(fullCost ~/ 4),
    failureDemandDeltaBps: -260,
    failureReputationDelta: -3,
    failureStaffMoraleDelta: -5,
    failureRiskDelta: 6,
  ),
  BusinessEventChoice(
    id: '${prefix}_measured',
    label: '한정 운영',
    description: '규모를 제한해 손실 가능성을 낮추고 반응을 확인합니다.',
    upfrontCost: (fullCost * 0.44).round(),
    immediateDemandDeltaBps: 150,
    successChanceBps: 7600,
    successCashDelta: (fullCost * 0.82).round(),
    successDemandDeltaBps: 520,
    successReputationDelta: 4,
    successStaffMoraleDelta: 1,
    successRiskDelta: -2,
    failureCashDelta: -(fullCost ~/ 12),
    failureDemandDeltaBps: -80,
    failureReputationDelta: -1,
    failureRiskDelta: 2,
  ),
  BusinessEventChoice(
    id: '${prefix}_pass',
    label: '평소 영업 유지',
    description: '추가 비용과 운영 혼선을 피하지만 성장 기회는 놓칩니다.',
    upfrontCost: 0,
    immediateDemandDeltaBps: -80,
    successChanceBps: 9200,
    successCashDelta: 0,
    successDemandDeltaBps: 0,
    successReputationDelta: 0,
    failureCashDelta: 0,
    failureDemandDeltaBps: -180,
    failureReputationDelta: -1,
  ),
];

BusinessEventChoice _scaledEventChoice(
  BusinessEventChoice choice,
  double scale,
) => BusinessEventChoice(
  id: choice.id,
  label: choice.label,
  description: choice.description,
  upfrontCost: (choice.upfrontCost * scale).round(),
  immediateDemandDeltaBps: choice.immediateDemandDeltaBps,
  immediateReputationDelta: choice.immediateReputationDelta,
  immediateConditionDelta: choice.immediateConditionDelta,
  immediateStaffMoraleDelta: choice.immediateStaffMoraleDelta,
  immediateRiskDelta: choice.immediateRiskDelta,
  successChanceBps: choice.successChanceBps,
  successCashDelta: (choice.successCashDelta * scale).round(),
  successDemandDeltaBps: choice.successDemandDeltaBps,
  successReputationDelta: choice.successReputationDelta,
  successConditionDelta: choice.successConditionDelta,
  successStaffMoraleDelta: choice.successStaffMoraleDelta,
  successRiskDelta: choice.successRiskDelta,
  failureCashDelta: (choice.failureCashDelta * scale).round(),
  failureDemandDeltaBps: choice.failureDemandDeltaBps,
  failureReputationDelta: choice.failureReputationDelta,
  failureConditionDelta: choice.failureConditionDelta,
  failureStaffMoraleDelta: choice.failureStaffMoraleDelta,
  failureRiskDelta: choice.failureRiskDelta,
);

List<String> _listingRiskSignals(
  BusinessIndustryProfile profile,
  BusinessLocationProfile location,
  BusinessDistrictSnapshot district,
  String key,
  int condition,
  BusinessListingMode mode,
) {
  final pool = <String>[
    if (condition < 58) '노후 설비 수리 가능성',
    if (mode == BusinessListingMode.acquisition) '권리금 산정 근거 확인 필요',
    if (location.rentMultiplier * district.rentMultiplier > 1.35)
      '지역 임대료와 고정비 부담이 높음',
    if (location.volatilityMultiplier * district.riskMultiplier > 1.15)
      '상권 변동성과 성수기·비수기 편차가 큼',
    if (district.vacancyMultiplier > 1.12) '주변 공실 증가 신호',
    if (district.competitionMultiplier > 1.15) '동종업계 경쟁 과열',
    if (district.phase == BusinessDistrictPhase.declining ||
        district.phase == BusinessDistrictPhase.distressed)
      '지역 상권 활력 하락 구간',
    if (district.phase == BusinessDistrictPhase.booming)
      '급성장 뒤 임대료·경쟁 동반 상승 가능성',
    if (district.phase == BusinessDistrictPhase.regenerating)
      '재생 사업 효과와 공사 불편이 공존',
    if (profile.variableCostRate > 0.4) '원재료 가격 민감',
    if (profile.tags.contains('lateNight')) '심야 인력·민원 위험',
    if (profile.tags.contains('equipment')) '설비 교체주기 위험',
    if (profile.tags.contains('hygiene')) '위생 점검 민감',
    if (profile.tags.contains('inventory')) '재고 폐기·도난 위험',
    '인근 경쟁점 신규 입점 가능성',
    '최근 매출은 추정 범위이며 보장되지 않음',
  ];
  if (pool.length <= 3) return List<String>.unmodifiable(pool);
  final start = stableBusinessHash('$key:risk-start') % pool.length;
  return List<String>.unmodifiable([
    pool[start],
    pool[(start + 3) % pool.length],
    pool[(start + 7) % pool.length],
  ]);
}

double _businessWeekdayFactor(
  BusinessIndustryProfile profile,
  BusinessLocationProfile location,
  DateTime date,
) {
  final weekend =
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  if (location.id == 'office') return weekend ? 0.58 : 1.15;
  if (location.id == 'university' && weekend) return 1.08;
  if (profile.tags.contains('group')) {
    return date.weekday == DateTime.friday || date.weekday == DateTime.saturday
        ? 1.28
        : 0.94;
  }
  if (profile.tags.contains('appointment')) return weekend ? 1.18 : 0.96;
  if (profile.tags.contains('necessity')) return weekend ? 1.03 : 1.0;
  return weekend ? 1.10 : 0.98;
}

double _businessSeasonality(BusinessIndustry industry, DateTime date) {
  final month = date.month;
  return switch (industry) {
    BusinessIndustry.pcBang || BusinessIndustry.arcade =>
      const {1: 1.14, 2: 1.12, 7: 1.13, 8: 1.16, 12: 1.08}[month] ?? 0.98,
    BusinessIndustry.karaoke => const {5: 1.08, 12: 1.24}[month] ?? 0.97,
    BusinessIndustry.studyCafe =>
      const {4: 1.12, 5: 1.16, 10: 1.14, 11: 1.20}[month] ?? 0.92,
    BusinessIndustry.fitnessCenter =>
      const {1: 1.23, 2: 1.14, 6: 1.10}[month] ?? 0.97,
    BusinessIndustry.photographyStudio =>
      const {2: 1.18, 5: 1.16, 10: 1.12}[month] ?? 0.94,
    BusinessIndustry.cafe || BusinessIndustry.boardGameCafe =>
      const {7: 1.08, 8: 1.10, 12: 1.08}[month] ?? 0.99,
    BusinessIndustry.coinLaundry =>
      const {6: 1.13, 7: 1.18, 8: 1.13}[month] ?? 0.98,
    _ => 1.0,
  };
}

double _businessMacroDemandFactor(DateTime date) => switch (date.year) {
  2008 || 2009 => 0.91,
  2020 => 0.74,
  2021 => 0.88,
  2002 || 2007 || 2017 || 2024 => 1.05,
  _ => 1.0,
};

/// Shared nominal-cost baseline for authoritative placement and fallback quotes.
double businessEraCostIndexAt(DateTime date) => _businessEraCostIndex(date);

double _businessEraCostIndex(DateTime date) {
  final years = (date.year - 2000).clamp(0, 26);
  return 1 + years * 0.032;
}

double _range(String baseKey, String suffix, double minimum, double maximum) =>
    minimum +
    (maximum - minimum) * businessDeterministicUnit('$baseKey:$suffix');

String _businessDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return fallback;
}

int _nonNegativeJsonInt(Object? value) =>
    math.max(0, (value as num?)?.toInt() ?? 0);

int _jsonScore(Object? value, int fallback) =>
    ((value as num?)?.toInt() ?? fallback).clamp(0, 100).toInt();
