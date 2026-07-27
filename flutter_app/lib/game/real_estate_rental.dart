import 'dart:math' as math;

import 'real_estate_market.dart';

enum RealEstateLeaseType { automatic, vacant, monthlyRent, jeonse }

extension RealEstateLeaseTypeLabel on RealEstateLeaseType {
  String get label => switch (this) {
    RealEstateLeaseType.automatic => '기존 자동운영',
    RealEstateLeaseType.vacant => '공실',
    RealEstateLeaseType.monthlyRent => '월세',
    RealEstateLeaseType.jeonse => '전세',
  };
}

enum RealEstateRentalIncident {
  none,
  lateRent,
  tenantDefault,
  minorRepair,
  majorRepair,
}

extension RealEstateRentalIncidentLabel on RealEstateRentalIncident {
  String get label => switch (this) {
    RealEstateRentalIncident.none => '정상 운영',
    RealEstateRentalIncident.lateRent => '월세 연체',
    RealEstateRentalIncident.tenantDefault => '상습 연체·퇴거',
    RealEstateRentalIncident.minorRepair => '경미한 수리',
    RealEstateRentalIncident.majorRepair => '대형 수리',
  };
}

class RealEstateLeaseTerms {
  const RealEstateLeaseTerms({
    required this.type,
    required this.deposit,
    required this.monthlyRent,
    required this.contractMonths,
    required this.placementFee,
  });

  final RealEstateLeaseType type;
  final int deposit;
  final int monthlyRent;
  final int contractMonths;
  final int placementFee;

  int get initialCashDelta => deposit - placementFee;
}

class RealEstateRentalIncidentResult {
  const RealEstateRentalIncidentResult({
    required this.incident,
    required this.repairCost,
    this.legalCost = 0,
    this.forcedEviction = false,
  });

  final RealEstateRentalIncident incident;
  final int repairCost;
  final int legalCost;
  final bool forcedEviction;

  int get totalUnexpectedCost => repairCost + legalCost;
}

double realEstateRentalIncomeTaxRate(DateTime date) => switch (date.year) {
  <= 2007 => 0.06,
  <= 2015 => 0.08,
  <= 2021 => 0.10,
  _ => 0.12,
};

int realEstateRentalIncomeTax({
  required DateTime date,
  required int grossRent,
  required int deductibleOperatingCost,
}) {
  final taxableIncome = math.max(0, grossRent - deductibleOperatingCost);
  return (taxableIncome * realEstateRentalIncomeTaxRate(date)).round();
}

int realEstateMonthlyInsurancePremium(int marketValue) =>
    math.max(20000, (math.max(0, marketValue) * 0.0001).round());

int realEstateMajorRepairInsuranceRecovery({
  required int marketValue,
  required int repairCost,
}) {
  final deductible = math.max(
    100000,
    (math.max(0, marketValue) * 0.0005).round(),
  );
  return (math.max(0, repairCost - deductible) * 0.70).round();
}

int realEstateRenovationCost(int marketValue) =>
    math.max(1000000, (math.max(0, marketValue) * 0.02).round());

int realEstateEarlyLeaseTerminationLegalCost(int monthlyRent) =>
    math.max(300000, math.max(0, monthlyRent) * 2);

bool realEstateSupportsManagedLease(RealEstateAssetType type) =>
    type != RealEstateAssetType.landmarkFund;

bool realEstateSupportsJeonse(RealEstateAssetType type) =>
    type.isHousing || type == RealEstateAssetType.officetel;

double realEstateMaximumCombinedLiabilityRate(
  DateTime date,
  RealEstateAssetType type,
) {
  if (!realEstateSupportsJeonse(type)) return 0.75;
  return date.year >= 2020 ? 0.75 : 0.80;
}

int realEstateMaximumLeaseDeposit({
  required DateTime date,
  required RealEstateAssetType type,
  required int marketValue,
  required int mortgageBalance,
}) {
  final combinedLimit =
      marketValue * realEstateMaximumCombinedLiabilityRate(date, type);
  return math.max(0, combinedLimit.floor() - mortgageBalance);
}

int realEstateTenantSearchMonths({
  required String worldSeed,
  required String assetId,
  double vacancyMultiplier = 1,
}) {
  final baseMonths = 1 + _stableHash('$worldSeed:$assetId:tenant-search') % 3;
  return (baseMonths * vacancyMultiplier).round().clamp(1, 6).toInt();
}

RealEstateLeaseTerms realEstateLeaseTermsAt({
  required DateTime date,
  required RealEstateAssetType type,
  required RealEstateLeaseType leaseType,
  required int marketValue,
  required int marketMonthlyRent,
  int mortgageBalance = 0,
}) {
  if (leaseType == RealEstateLeaseType.automatic ||
      leaseType == RealEstateLeaseType.vacant) {
    return RealEstateLeaseTerms(
      type: leaseType,
      deposit: 0,
      monthlyRent: 0,
      contractMonths: 0,
      placementFee: 0,
    );
  }
  if (leaseType == RealEstateLeaseType.jeonse) {
    final depositRate = switch (date.year) {
      <= 2007 => 0.52,
      <= 2014 => 0.60,
      <= 2021 => 0.68,
      _ => 0.58,
    };
    final requestedDeposit = (marketValue * depositRate).round();
    final deposit = math.min(
      requestedDeposit,
      realEstateMaximumLeaseDeposit(
        date: date,
        type: type,
        marketValue: marketValue,
        mortgageBalance: mortgageBalance,
      ),
    );
    return RealEstateLeaseTerms(
      type: leaseType,
      deposit: deposit,
      monthlyRent: 0,
      contractMonths: 24,
      placementFee: math.max(200000, (deposit * 0.003).round()),
    );
  }
  final deposit = math.min(
    (marketValue * 0.10).round(),
    realEstateMaximumLeaseDeposit(
      date: date,
      type: type,
      marketValue: marketValue,
      mortgageBalance: mortgageBalance,
    ),
  );
  return RealEstateLeaseTerms(
    type: leaseType,
    deposit: deposit,
    monthlyRent: marketMonthlyRent,
    contractMonths: 24,
    placementFee: math.max(100000, marketMonthlyRent),
  );
}

int realEstateTenantReliability({
  required String worldSeed,
  required String assetId,
  required DateTime contractDate,
  required RealEstateLeaseType leaseType,
}) =>
    60 +
    _stableHash(
          '$worldSeed:$assetId:${contractDate.year}-${contractDate.month}:${leaseType.name}',
        ) %
        36;

RealEstateRentalIncidentResult realEstateRentalIncidentAt({
  required String worldSeed,
  required String assetId,
  required DateTime date,
  required int tenantReliability,
  required int marketValue,
  required int baseMonthlyCost,
  required bool rentBearing,
  double repairProbabilityMultiplier = 1,
  double repairCostMultiplier = 1,
}) {
  final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
  final roll = _stableHash('$worldSeed:$assetId:$monthKey:rental') % 1000;
  final lateRentThreshold = rentBearing
      ? ((100 - tenantReliability).clamp(5, 40) * 2)
      : 0;
  final defaultThreshold = rentBearing
      ? math.max(1, ((100 - tenantReliability).clamp(5, 40) / 5).round())
      : 0;
  if (roll < defaultThreshold) {
    return RealEstateRentalIncidentResult(
      incident: RealEstateRentalIncident.tenantDefault,
      repairCost: 0,
      legalCost: math.max(150000, baseMonthlyCost * 4),
      forcedEviction: true,
    );
  }
  if (roll < lateRentThreshold) {
    return const RealEstateRentalIncidentResult(
      incident: RealEstateRentalIncident.lateRent,
      repairCost: 0,
    );
  }
  final majorRepairChance = math.max(
    1,
    (18 * repairProbabilityMultiplier).round(),
  );
  final minorRepairChance = math.max(
    1,
    (77 * repairProbabilityMultiplier).round(),
  );
  if (roll < lateRentThreshold + majorRepairChance) {
    return RealEstateRentalIncidentResult(
      incident: RealEstateRentalIncident.majorRepair,
      repairCost:
          (math.max(500000, (marketValue * 0.005).round()) *
                  repairCostMultiplier)
              .round(),
    );
  }
  if (roll < lateRentThreshold + majorRepairChance + minorRepairChance) {
    return RealEstateRentalIncidentResult(
      incident: RealEstateRentalIncident.minorRepair,
      repairCost: (math.max(50000, baseMonthlyCost * 3) * repairCostMultiplier)
          .round(),
    );
  }
  return const RealEstateRentalIncidentResult(
    incident: RealEstateRentalIncident.none,
    repairCost: 0,
  );
}

int _stableHash(String value) {
  var hash = 2166136261;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash;
}
