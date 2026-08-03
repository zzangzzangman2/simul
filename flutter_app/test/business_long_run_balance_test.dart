import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/business_districts.dart';
import 'package:millennium_capital/game/business_simulation.dart';
import 'package:millennium_capital/game/business_state.dart';

const _auditPolicies = <BusinessOperatingPolicy>[
  BusinessOperatingPolicy.neutral,
  BusinessOperatingPolicy(
    pricing: 1,
    quality: 3,
    staffing: 3,
    marketing: 3,
    openingHours: 3,
    maintenance: 3,
  ),
  BusinessOperatingPolicy(
    pricing: 2,
    quality: 2,
    staffing: 1,
    marketing: 1,
    openingHours: 2,
    maintenance: 2,
  ),
  BusinessOperatingPolicy(
    pricing: 4,
    quality: 4,
    staffing: 4,
    marketing: 4,
    openingHours: 4,
    maintenance: 0,
  ),
];

class _AuditCase {
  const _AuditCase({
    required this.seed,
    required this.listing,
    required this.opened,
  });

  final String seed;
  final BusinessListing listing;
  final DateTime opened;
}

class _AuditOutcome {
  const _AuditOutcome({
    required this.totalProfit,
    required this.forcedClosure,
    required this.voluntaryClosure,
  });

  final int totalProfit;
  final bool forcedClosure;
  final bool voluntaryClosure;
}

BusinessMonthlyStatement _representativeMonth({
  required OwnedBusiness business,
  required String seed,
  required int year,
  required int month,
}) {
  final dayCount = DateTime(year, month + 1, 0).day;
  final sampleDay =
      1 + stableBusinessHash('$seed:${business.id}:$year-$month') % dayCount;
  final daily = simulateBusinessDay(
    business: business,
    worldSeed: seed,
    date: DateTime(year, month, sampleDay),
  );
  int scale(int value) => value * dayCount;
  return BusinessMonthlyStatement(
    businessId: business.id,
    year: year,
    month: month,
    operatingDays: daily.grossSales > 0 ? dayCount : 0,
    customerCount: scale(daily.customerCount),
    grossSales: scale(daily.grossSales),
    variableCosts: scale(daily.variableCosts),
    payroll: scale(daily.payroll),
    rent: scale(daily.rent),
    utilities: scale(daily.utilities),
    marketing: scale(daily.marketing),
    maintenance: scale(daily.maintenance),
    eventCosts: scale(daily.eventCosts),
    taxes: scale(daily.taxes),
    netProfit: scale(daily.netProfit),
    policySnapshot: business.policy,
    sourceId: 'balance-audit-${business.id}-$year-$month',
  );
}

_AuditOutcome _runCase(_AuditCase auditCase, int index) {
  var business = createOwnedBusinessFromListing(
    listing: auditCase.listing,
    businessId: 'balance-$index-${auditCase.listing.industry.name}',
    name: '장기 감사 ${auditCase.listing.industry.label}',
    acquiredDay: 1,
    openedDate: auditCase.opened,
    policy: _auditPolicies[index % _auditPolicies.length],
  );
  var bankCash = business.totalInvested * 2;
  var forcedClosure = false;
  var voluntaryClosure = false;

  for (
    var year = auditCase.opened.year;
    year <= 2026 && business.isActive && !voluntaryClosure;
    year += 1
  ) {
    final firstMonth = year == auditCase.opened.year
        ? auditCase.opened.month
        : 1;
    for (
      var month = firstMonth;
      month <= 12 && business.isActive && !voluntaryClosure;
      month += 1
    ) {
      final settlement = settleBusinessMonth(
        business: business,
        statement: _representativeMonth(
          business: business,
          seed: auditCase.seed,
          year: year,
          month: month,
        ),
        availableBankCash: bankCash,
      );
      bankCash += settlement.cashDelta;
      business = settlement.business;
      forcedClosure = forcedClosure || settlement.forcedClosure;

      final quarterBookValue = business.bookValue ~/ 4;
      final voluntaryExitThreshold = quarterBookValue > 10000000
          ? quarterBookValue
          : 10000000;
      if (index.isOdd &&
          business.consecutiveLossMonths >= 6 &&
          business.totalProfit <= -voluntaryExitThreshold) {
        voluntaryClosure = true;
      }
    }
  }

  return _AuditOutcome(
    totalProfit: business.totalProfit,
    forcedClosure: forcedClosure,
    voluntaryClosure: voluntaryClosure,
  );
}

void main() {
  test(
    '2000~2026 여러 시드·업종·입지·상권·정책에서 결과가 한쪽으로 고정되지 않는다',
    () {
      const baseSeed = 'business-balance-base';
      const laterSeed = 'business-balance-later';
      final cases = <_AuditCase>[
        for (final listing in generateBusinessListings(
          worldSeed: baseSeed,
          asOfDate: DateTime(2000, 1, 1),
          count: 36,
        ))
          _AuditCase(
            seed: baseSeed,
            listing: listing,
            opened: DateTime(2000, 1, 1),
          ),
      ];

      final coveredIndustries = cases
          .map((auditCase) => auditCase.listing.industry)
          .toSet();
      for (final profile in businessIndustryCatalog.where(
        (profile) => !coveredIndustries.contains(profile.industry),
      )) {
        final opened = DateTime(profile.unlockYear, 1, 1);
        final listing = generateBusinessListings(
          worldSeed: laterSeed,
          asOfDate: opened,
          count: 54,
        ).firstWhere((candidate) => candidate.industry == profile.industry);
        cases.add(
          _AuditCase(seed: laterSeed, listing: listing, opened: opened),
        );
        coveredIndustries.add(profile.industry);
      }

      expect(coveredIndustries, BusinessIndustry.values.toSet());
      expect(
        cases.map((auditCase) => auditCase.listing.locationId).toSet(),
        businessLocationCatalog.map((location) => location.id).toSet(),
      );
      expect(
        cases.map((auditCase) => auditCase.listing.districtId).toSet(),
        businessDistrictCatalog.map((district) => district.id).toSet(),
      );
      expect(cases.map((auditCase) => auditCase.seed).toSet().length, 2);
      expect(
        cases.map((auditCase) => auditCase.opened.year).toSet().length,
        greaterThanOrEqualTo(4),
      );

      final outcomes = <_AuditOutcome>[
        for (var index = 0; index < cases.length; index += 1)
          _runCase(cases[index], index),
      ];
      final profitable = outcomes.where((outcome) => outcome.totalProfit > 0);
      final losing = outcomes.where((outcome) => outcome.totalProfit < 0);
      final forced = outcomes.where((outcome) => outcome.forcedClosure);
      final voluntary = outcomes.where((outcome) => outcome.voluntaryClosure);
      final profitableShare = profitable.length / outcomes.length;

      expect(profitable, isNotEmpty);
      expect(losing, isNotEmpty);
      expect(forced, isNotEmpty);
      expect(voluntary, isNotEmpty);
      expect(profitableShare, inInclusiveRange(0.20, 0.80));

      for (
        var policyIndex = 0;
        policyIndex < _auditPolicies.length;
        policyIndex += 1
      ) {
        final policyOutcomes = <_AuditOutcome>[
          for (
            var index = policyIndex;
            index < outcomes.length;
            index += _auditPolicies.length
          )
            outcomes[index],
        ];
        expect(
          policyOutcomes.any((outcome) => outcome.totalProfit > 0),
          isTrue,
          reason: '운영정책 $policyIndex가 모든 표본에서 손실이면 안 됩니다.',
        );
        expect(
          policyOutcomes.any((outcome) => outcome.totalProfit < 0),
          isTrue,
          reason: '운영정책 $policyIndex가 모든 표본에서 확정 수익이면 안 됩니다.',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
