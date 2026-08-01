import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/business_districts.dart';
import 'package:millennium_capital/game/business_simulation.dart';
import 'package:millennium_capital/game/business_state.dart';

OwnedBusiness _business({
  required String id,
  BusinessIndustry industry = BusinessIndustry.pcBang,
  BusinessPremiseMode premiseMode = BusinessPremiseMode.leased,
  int monthlyRent = 0,
  int employeeCount = 2,
  int capacity = 120,
  int averageTicket = 18000,
  int baseDailyCustomers = 90,
  int equipmentBookValue = 12000000,
  int accountsPayable = 0,
  int missedPaymentMonths = 0,
  BusinessOperatingPolicy policy = BusinessOperatingPolicy.neutral,
  String districtId = '',
  int districtRentIndexAtOpenBps = 10000,
  int generatorVersion = 1,
}) {
  return OwnedBusiness(
    id: id,
    name: '$id 점포',
    industry: industry,
    locationId: 'residential',
    districtId: districtId,
    districtRentIndexAtOpenBps: districtRentIndexAtOpenBps,
    listingMode: BusinessListingMode.acquisition,
    premiseMode: premiseMode,
    openedDateIso: '2000-01-01',
    acquiredDay: 1,
    acquisitionPrice: 50000000,
    leaseDeposit: premiseMode == BusinessPremiseMode.leased ? 10000000 : 0,
    monthlyRent: monthlyRent,
    equipmentBookValue: equipmentBookValue,
    goodwillBookValue: 5000000,
    employeeCount: employeeCount,
    capacity: capacity,
    averageTicket: averageTicket,
    baseDailyCustomers: baseDailyCustomers,
    generatorVersion: generatorVersion,
    policy: policy,
    reputation: 72,
    customerLoyalty: 64,
    equipmentCondition: 82,
    staffMorale: 70,
    riskLevel: 24,
    accountsPayable: accountsPayable,
    missedPaymentMonths: missedPaymentMonths,
  );
}

void main() {
  group('사업 콘텐츠 카탈로그와 결정론', () {
    test('사업과 상권 해시는 VM과 Web에서 같은 31-bit 골든을 유지한다', () {
      const golden = <String, int>{
        'abc': 440920331,
        'district-json-roundtrip': 1067251050,
        'shared-economy-business-bridge': 65093956,
        '사업테스트': 1840803566,
      };

      for (final entry in golden.entries) {
        expect(stableBusinessHash(entry.key), entry.value);
        expect(stableBusinessDistrictHash(entry.key), entry.value);
      }
    });

    test('18개 업종, PC방·노래방, 6개 입지와 전용 사건을 제공한다', () {
      expect(BusinessIndustry.values, hasLength(18));
      expect(
        BusinessIndustry.values,
        containsAll(<BusinessIndustry>[
          BusinessIndustry.pcBang,
          BusinessIndustry.karaoke,
        ]),
      );
      expect(
        businessIndustryCatalog.map((profile) => profile.industry).toSet(),
        BusinessIndustry.values.toSet(),
      );
      expect(businessLocationCatalog, hasLength(6));
      expect(
        businessLocationCatalog.map((location) => location.id).toSet(),
        hasLength(6),
      );
      expect(businessDistrictCatalog, hasLength(32));

      expect(commonBusinessEventTemplates.length, greaterThanOrEqualTo(25));
      expect(pcBangBusinessEventTemplates.length, greaterThanOrEqualTo(8));
      expect(karaokeBusinessEventTemplates.length, greaterThanOrEqualTo(8));
      expect(
        pcBangBusinessEventTemplates.every(
          (event) => event.tags.contains('pcBang'),
        ),
        isTrue,
      );
      expect(
        karaokeBusinessEventTemplates.every(
          (event) => event.tags.contains('karaoke'),
        ),
        isTrue,
      );
    });

    test('같은 월드시드와 월은 동일한 매물 목록을 만들고 시드가 바뀌면 달라진다', () {
      final date = DateTime(2026, 7, 28);
      final first = generateBusinessListings(
        worldSeed: 'business-listing-seed',
        asOfDate: date,
        count: 54,
      );
      final repeated = generateBusinessListings(
        worldSeed: 'business-listing-seed',
        asOfDate: date,
        count: 54,
      );
      final laterInSameMonth = generateBusinessListings(
        worldSeed: 'business-listing-seed',
        asOfDate: DateTime(2026, 7, 31),
        count: 54,
      );

      expect(
        first.map((listing) => listing.toJson()).toList(),
        repeated.map((listing) => listing.toJson()).toList(),
      );
      expect(
        first.map((listing) => listing.toJson()).toList(),
        laterInSameMonth.map((listing) => listing.toJson()).toList(),
      );
      expect(
        first.map((listing) => listing.industry).toSet(),
        BusinessIndustry.values.toSet(),
      );
      expect(
        first.map((listing) => listing.districtId).toSet(),
        businessDistrictCatalog.map((district) => district.id).toSet(),
      );
      expect(
        first.every((listing) => listing.districtRentIndexBps > 0),
        isTrue,
      );
      expect(
        businessListingsFingerprint(
          worldSeed: 'business-listing-seed',
          asOfDate: date,
          count: 54,
        ),
        isNot(
          businessListingsFingerprint(
            worldSeed: 'different-listing-seed',
            asOfDate: date,
            count: 54,
          ),
        ),
      );
    });
  });

  group('월 손익과 투자', () {
    test('같은 달에도 운영 여건에 따라 흑자와 손실이 뚜렷하게 갈린다', () {
      final profitable = _business(
        id: 'profitable',
        premiseMode: BusinessPremiseMode.ownedProperty,
        monthlyRent: 0,
        employeeCount: 2,
        capacity: 240,
        averageTicket: 36000,
        baseDailyCustomers: 180,
        policy: const BusinessOperatingPolicy(
          pricing: 2,
          quality: 3,
          staffing: 2,
          marketing: 2,
          openingHours: 3,
          maintenance: 3,
        ),
      );
      final failing = _business(
        id: 'failing',
        industry: BusinessIndustry.karaoke,
        monthlyRent: 120000000,
        employeeCount: 14,
        capacity: 1,
        averageTicket: 1000,
        baseDailyCustomers: 1,
        equipmentBookValue: 30000000,
        policy: const BusinessOperatingPolicy(
          pricing: 4,
          quality: 4,
          staffing: 4,
          marketing: 4,
          openingHours: 4,
          maintenance: 0,
        ),
      );

      final goodMonth = simulateBusinessMonth(
        business: profitable,
        worldSeed: 'monthly-profit-loss',
        year: 2000,
        month: 1,
      );
      final repeatedGoodMonth = simulateBusinessMonth(
        business: profitable,
        worldSeed: 'monthly-profit-loss',
        year: 2000,
        month: 1,
      );
      final badMonth = simulateBusinessMonth(
        business: failing,
        worldSeed: 'monthly-profit-loss',
        year: 2000,
        month: 1,
      );

      expect(
        goodMonth.statement.toJson(),
        repeatedGoodMonth.statement.toJson(),
      );
      expect(goodMonth.statement.netProfit, greaterThan(0));
      expect(badMonth.statement.netProfit, lessThan(0));
      expect(
        goodMonth.statement.grossSales,
        greaterThan(badMonth.statement.grossSales),
      );
      expect(
        goodMonth.statement.netProfit,
        greaterThan(badMonth.statement.netProfit),
      );
    });

    test('투자 종류마다 비용과 운영 지표 변화가 함께 저장된다', () {
      final original = _business(id: 'investment');
      final plan = businessInvestmentPlanFor(
        original,
        BusinessInvestmentKind.staffTraining,
      );
      final result = applyBusinessInvestment(
        original,
        BusinessInvestmentKind.staffTraining,
      );

      expect(plan.cost, greaterThan(0));
      expect(result.cashDelta, -plan.cost);
      expect(result.business.staffMorale, greaterThan(original.staffMorale));
      expect(result.business.riskLevel, lessThan(original.riskLevel));
      expect(result.business.totalInvested, original.totalInvested + plan.cost);
    });
  });

  group('사건 선택과 저장', () {
    test('선택 스냅샷은 JSON 왕복 후에도 보존되고 결과는 결정론적이다', () {
      final business = _business(id: 'event-shop');
      const choice = BusinessEventChoice(
        id: 'full-response',
        label: '전면 대응',
        description: '비용을 들여 문제를 바로 해결한다.',
        upfrontCost: 300000,
        immediateReputationDelta: 2,
        immediateRiskDelta: -4,
        successChanceBps: 6200,
        successCashDelta: 1400000,
        successDemandDeltaBps: 500,
        successReputationDelta: 5,
        failureCashDelta: -700000,
        failureDemandDeltaBps: -400,
        failureReputationDelta: -3,
      );
      const event = BusinessEventInstance(
        id: 'event-shop-2000-01-02',
        templateId: 'test-event',
        businessId: 'event-shop',
        title: '단골 이탈 위기',
        body: '대응 수준을 선택해야 한다.',
        occurredDateIso: '2000-01-02',
        choiceDueDateIso: '2000-01-04',
        resolutionDateIso: '2000-01-07',
        choices: [choice],
        tags: ['service'],
        dailyDemandDeltaBps: -300,
        dailyExtraCost: 10000,
      );

      final application = applyBusinessEventChoice(
        business: business,
        event: event,
        choiceId: choice.id,
        selectedAt: DateTime(2000, 1, 3),
      );
      final saved = BusinessPortfolioState(
        businesses: [application.business],
        pendingEvents: [application.event],
        eventHistory: const [],
        totalAcquisitionSpend: 50000000,
        totalSales: 0,
        totalProfit: 0,
        totalClosures: 0,
      );
      final restored = BusinessPortfolioState.fromJson(saved.toJson());

      expect(application.cashDelta, -choice.upfrontCost);
      expect(application.event.status, BusinessEventStatus.awaitingOutcome);
      expect(restored.toJson(), saved.toJson());
      expect(restored.pendingEvents.single.selectedChoice?.id, choice.id);

      final firstResolution = resolveBusinessEvent(
        business: restored.businesses.single,
        event: restored.pendingEvents.single,
        worldSeed: 'event-resolution-seed',
        asOfDate: DateTime(2000, 1, 7),
      );
      final repeatedResolution = resolveBusinessEvent(
        business: restored.businesses.single,
        event: restored.pendingEvents.single,
        worldSeed: 'event-resolution-seed',
        asOfDate: DateTime(2000, 1, 7),
      );

      expect(firstResolution.resolved, isTrue);
      expect(firstResolution.outcome, repeatedResolution.outcome);
      expect(firstResolution.cashDelta, repeatedResolution.cashDelta);
      expect(firstResolution.event.toJson(), repeatedResolution.event.toJson());
    });
  });

  test('3개월째 운영비를 못 내면 강제폐업 정산이 가능하고 중복 정산은 막힌다', () {
    final business = _business(
      id: 'insolvent',
      accountsPayable: 900000,
      missedPaymentMonths: 2,
    );
    const statement = BusinessMonthlyStatement(
      businessId: 'insolvent',
      year: 2000,
      month: 1,
      operatingDays: 31,
      customerCount: 10,
      grossSales: 100000,
      variableCosts: 200000,
      payroll: 2000000,
      rent: 3000000,
      utilities: 200000,
      marketing: 100000,
      maintenance: 100000,
      eventCosts: 0,
      taxes: 0,
      netProfit: -5500000,
      policySnapshot: BusinessOperatingPolicy.neutral,
      sourceId: 'business-month-insolvent-2000-01',
    );

    final settlement = settleBusinessMonth(
      business: business,
      statement: statement,
      availableBankCash: 0,
    );
    final duplicate = settleBusinessMonth(
      business: settlement.business,
      statement: statement,
      availableBankCash: 100000000,
    );

    expect(settlement.forcedClosure, isTrue);
    expect(settlement.business.status, BusinessStatus.closed);
    expect(settlement.business.missedPaymentMonths, 3);
    expect(settlement.business.accountsPayable, 6400000);
    expect(duplicate.alreadySettled, isTrue);
    expect(duplicate.cashDelta, 0);
  });

  test('v2 점포 손익과 임대료는 실제 지역의 성장·쇠퇴와 시대 변화를 따른다', () {
    const seed = 'district-operation-integration';
    final opened = DateTime(2000, 1, 15);
    final current = DateTime(2026, 1, 15);
    final seongsuOpened = businessDistrictSnapshot(
      districtId: 'seoul_seongsu',
      asOf: opened,
      worldSeed: seed,
      generatorVersion: 1,
    );
    final gwacheonOpened = businessDistrictSnapshot(
      districtId: 'gyeonggi_gwacheon_central',
      asOf: opened,
      worldSeed: seed,
      generatorVersion: 1,
    );
    final seongsu = _business(
      id: 'same-store',
      monthlyRent: 2400000,
      capacity: 500,
      baseDailyCustomers: 70,
      districtId: 'seoul_seongsu',
      districtRentIndexAtOpenBps:
          (seongsuOpened.rentMultiplier *
                  businessEraCostIndexAt(opened) *
                  10000)
              .round(),
      generatorVersion: 2,
    );
    final gwacheon = seongsu.copyWith(
      districtId: 'gyeonggi_gwacheon_central',
      districtRentIndexAtOpenBps:
          (gwacheonOpened.rentMultiplier *
                  businessEraCostIndexAt(opened) *
                  10000)
              .round(),
    );

    final seongsuNow = simulateBusinessDay(
      business: seongsu,
      worldSeed: seed,
      date: current,
    );
    final gwacheonNow = simulateBusinessDay(
      business: gwacheon,
      worldSeed: seed,
      date: current,
    );
    final seongsuAtOpen = simulateBusinessDay(
      business: seongsu,
      worldSeed: seed,
      date: opened,
    );

    expect((
      seongsuNow.customerCount,
      seongsuNow.netProfit,
    ), isNot((gwacheonNow.customerCount, gwacheonNow.netProfit)));
    expect(seongsuNow.rent, greaterThan(seongsuAtOpen.rent));
  });
}
