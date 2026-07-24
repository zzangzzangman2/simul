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

enum RealEstateRentalIncident { none, lateRent, minorRepair, majorRepair }

extension RealEstateRentalIncidentLabel on RealEstateRentalIncident {
  String get label => switch (this) {
    RealEstateRentalIncident.none => '정상 운영',
    RealEstateRentalIncident.lateRent => '월세 연체',
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
  });

  final RealEstateRentalIncident incident;
  final int repairCost;
}

bool realEstateSupportsManagedLease(RealEstateAssetType type) =>
    type != RealEstateAssetType.landmarkFund;

bool realEstateSupportsJeonse(RealEstateAssetType type) =>
    type.isHousing || type == RealEstateAssetType.officetel;

RealEstateLeaseTerms realEstateLeaseTermsAt({
  required DateTime date,
  required RealEstateAssetType type,
  required RealEstateLeaseType leaseType,
  required int marketValue,
  required int marketMonthlyRent,
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
    final deposit = (marketValue * depositRate).round();
    return RealEstateLeaseTerms(
      type: leaseType,
      deposit: deposit,
      monthlyRent: 0,
      contractMonths: 24,
      placementFee: math.max(200000, (deposit * 0.003).round()),
    );
  }
  final deposit = (marketValue * 0.10).round();
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
}) {
  final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
  final roll = _stableHash('$worldSeed:$assetId:$monthKey:rental') % 1000;
  final lateRentThreshold = rentBearing
      ? ((100 - tenantReliability).clamp(5, 40) * 2)
      : 0;
  if (roll < lateRentThreshold) {
    return const RealEstateRentalIncidentResult(
      incident: RealEstateRentalIncident.lateRent,
      repairCost: 0,
    );
  }
  if (roll < lateRentThreshold + 18) {
    return RealEstateRentalIncidentResult(
      incident: RealEstateRentalIncident.majorRepair,
      repairCost: math.max(500000, (marketValue * 0.005).round()),
    );
  }
  if (roll < lateRentThreshold + 95) {
    return RealEstateRentalIncidentResult(
      incident: RealEstateRentalIncident.minorRepair,
      repairCost: math.max(50000, baseMonthlyCost * 3),
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
