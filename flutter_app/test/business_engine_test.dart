import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/business_districts.dart';
import 'package:millennium_capital/game/business_engine.dart';
import 'package:millennium_capital/game/business_simulation.dart';
import 'package:millennium_capital/game/business_state.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/personal_finance_state.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_rental.dart';

const _gameEngine = GameEngine();
const _businessEngine = LocalBusinessEngine();

GameState _newState({
  int cash = 1000000000,
  String seed = 'business-engine-seed',
}) {
  return _gameEngine
      .createNewGame('사업 엔진 테스트', initialCash: cash, worldSeed: seed)
      .copyWith(
        cash: cash,
        brokerageCash: 0,
        decisions: const [],
        processedEventIds: const [],
      );
}

int _dayFor(GameState state, DateTime date) =>
    date.difference(state.campaignStartDate).inDays + 1;

BusinessPortfolioState _portfolioOf(OwnedBusiness business) {
  return const BusinessPortfolioState.initial().replaceBusiness(business);
}

OwnedBusiness _monthlyBusiness({
  required String id,
  required bool profitable,
  int accountsPayable = 0,
  int missedPaymentMonths = 0,
  int generatorVersion = 1,
  int consecutiveLossMonths = 0,
  int totalProfit = 0,
}) {
  return OwnedBusiness(
    id: id,
    name: '$id 점포',
    industry: profitable ? BusinessIndustry.pcBang : BusinessIndustry.karaoke,
    locationId: 'residential',
    listingMode: BusinessListingMode.acquisition,
    premiseMode: BusinessPremiseMode.leased,
    openedDateIso: '2000-01-01',
    acquiredDay: 1,
    acquisitionPrice: 50000000,
    leaseDeposit: 0,
    monthlyRent: profitable ? 0 : 200000000,
    equipmentBookValue: profitable ? 10000000 : 0,
    goodwillBookValue: 0,
    employeeCount: profitable ? 2 : 15,
    capacity: profitable ? 240 : 1,
    averageTicket: profitable ? 35000 : 1000,
    baseDailyCustomers: profitable ? 180 : 1,
    policy: profitable
        ? const BusinessOperatingPolicy(
            quality: 3,
            openingHours: 3,
            maintenance: 3,
          )
        : const BusinessOperatingPolicy(
            pricing: 4,
            quality: 4,
            staffing: 4,
            marketing: 4,
            openingHours: 4,
            maintenance: 0,
          ),
    reputation: profitable ? 80 : 20,
    customerLoyalty: profitable ? 70 : 10,
    equipmentCondition: profitable ? 90 : 20,
    staffMorale: profitable ? 80 : 20,
    riskLevel: profitable ? 10 : 90,
    accountsPayable: accountsPayable,
    missedPaymentMonths: missedPaymentMonths,
    generatorVersion: generatorVersion,
    consecutiveLossMonths: consecutiveLossMonths,
    totalProfit: totalProfit,
  );
}

BusinessLaunchRequest _launchRequest(
  BusinessListing listing, {
  String? linkedRealEstateId,
  BusinessPremiseMode premiseMode = BusinessPremiseMode.leased,
}) {
  return BusinessLaunchRequest(
    listingId: listing.id,
    businessName: '${listing.industry.label} 테스트점',
    locationId: listing.locationId,
    premiseMode: premiseMode,
    linkedRealEstateId: linkedRealEstateId,
    policy: BusinessOperatingPolicy.neutral,
  );
}

void main() {
  group('개점 자금과 부동산 연결', () {
    test('증권 예수금은 쓰지 않고 회사 통장 잔액만 개점에 사용한다', () {
      final seedState = _newState(seed: 'company-bank-only');
      final listing = generateBusinessListings(
        worldSeed: seedState.simulationSeed,
        asOfDate: seedState.currentDate,
        count: LocalBusinessEngine.listingCount,
      ).first;
      final requiredCash = listing.totalInitialCashRequired;
      final brokerageOnly = seedState.copyWith(
        cash: requiredCash + 1000000,
        brokerageCash: requiredCash + 1000000,
      );

      final rejected = _businessEngine.openOrAcquire(
        brokerageOnly,
        _launchRequest(listing),
      );
      expect(rejected.success, isFalse);
      expect(rejected.state.businesses.businesses, isEmpty);
      expect(rejected.state.cash, brokerageOnly.cash);

      final bankFunded = brokerageOnly.copyWith(brokerageCash: 0);
      final opened = _businessEngine.openOrAcquire(
        bankFunded,
        _launchRequest(listing),
      );

      expect(opened.success, isTrue);
      expect(opened.cashDelta, -requiredCash);
      expect(opened.state.cash, bankFunded.cash - requiredCash);
      expect(opened.state.brokerageCash, 0);
      expect(
        opened.state.ledger
            .where((entry) => entry.sourceId == 'business-launch-${listing.id}')
            .every((entry) => entry.account == 'company_bank'),
        isTrue,
      );
    });

    test('기존 점포 인수는 요청 location 조작을 무시하고 원 매물 입지를 유지한다', () {
      final state = _newState(seed: 'acquisition-location-trust');
      final listing =
          generateBusinessListings(
            worldSeed: state.simulationSeed,
            asOfDate: state.currentDate,
            count: LocalBusinessEngine.listingCount,
          ).firstWhere(
            (candidate) => candidate.mode == BusinessListingMode.acquisition,
          );
      final alternateLocation = businessLocationCatalog.firstWhere(
        (location) => location.id != listing.locationId,
      );

      final result = _businessEngine.openOrAcquire(
        state,
        BusinessLaunchRequest(
          listingId: listing.id,
          businessName: '입지 조작 방지점',
          locationId: alternateLocation.id,
          premiseMode: BusinessPremiseMode.leased,
          policy: BusinessOperatingPolicy.neutral,
        ),
      );

      expect(result.success, isTrue);
      expect(
        result.state.businesses.businesses.single.locationId,
        listing.locationId,
      );
      expect(result.cashDelta, -listing.totalInitialCashRequired);
    });

    test('지역 정보가 없는 레거시 부동산은 임의 상권 직영점으로 연결하지 않는다', () {
      const legacyCommercial = OwnedRealEstate(
        id: 'legacy-commercial',
        optionId: 'legacy-commercial-unit',
        name: '지역 미상 구형 상가',
        purchasePrice: 300000000,
        acquiredDay: 1,
        monthlyIncome: 0,
        monthlyCost: 300000,
        leaseType: RealEstateLeaseType.vacant,
      );
      final base = _newState(seed: 'legacy-premise-district-guard');
      final listing = generateBusinessListings(
        worldSeed: base.simulationSeed,
        asOfDate: base.currentDate,
        count: LocalBusinessEngine.listingCount,
      ).first;
      final state = base.copyWith(
        personalFinance: base.personalFinance.copyWith(
          realEstate: const [legacyCommercial],
        ),
      );

      final result = _businessEngine.openOrAcquire(
        state,
        _launchRequest(
          listing,
          linkedRealEstateId: legacyCommercial.id,
          premiseMode: BusinessPremiseMode.ownedProperty,
        ),
      );

      expect(result.success, isFalse);
      expect(result.message, contains('지역 정보'));
      expect(result.state.businesses.businesses, isEmpty);
    });

    test('공실 상업부동산에는 직영점 입점이 가능하고 중복·임대 중 연결은 막힌다', () {
      final base = _newState(seed: 'owned-commercial-premise');
      final listings = generateBusinessListings(
        worldSeed: base.simulationSeed,
        asOfDate: base.currentDate,
        count: LocalBusinessEngine.listingCount,
      );
      final commercialAssetsByDistrict = <String, RealEstateMarketAsset>{};
      for (final asset in realEstateMarketCatalog) {
        if (asset.type != RealEstateAssetType.commercialUnit &&
            asset.type != RealEstateAssetType.officeBuilding) {
          continue;
        }
        final districtId = businessDistrictIdForRealEstateRegion(
          asset.region,
          province: asset.province,
        );
        if (districtId != null) {
          commercialAssetsByDistrict.putIfAbsent(districtId, () => asset);
        }
      }
      final listing = listings.firstWhere(
        (candidate) =>
            commercialAssetsByDistrict.containsKey(candidate.districtId),
      );
      final propertyAsset = commercialAssetsByDistrict[listing.districtId]!;
      final vacantCommercial = OwnedRealEstate(
        id: 'commercial-1',
        optionId: 'test-commercial-unit',
        name: '테스트 상가',
        purchasePrice: 300000000,
        acquiredDay: 1,
        monthlyIncome: 0,
        monthlyCost: 300000,
        marketAssetId: propertyAsset.id,
        leaseType: RealEstateLeaseType.vacant,
      );
      final withVacancy = base.copyWith(
        personalFinance: base.personalFinance.copyWith(
          realEstate: [vacantCommercial],
        ),
      );

      final first = _businessEngine.openOrAcquire(
        withVacancy,
        _launchRequest(
          listing,
          linkedRealEstateId: vacantCommercial.id,
          premiseMode: BusinessPremiseMode.ownedProperty,
        ),
      );

      expect(first.success, isTrue);
      final ownedShop = first.state.businesses.businesses.single;
      expect(ownedShop.premiseMode, BusinessPremiseMode.ownedProperty);
      expect(ownedShop.linkedRealEstateId, vacantCommercial.id);
      expect(ownedShop.leaseDeposit, 0);
      expect(ownedShop.monthlyRent, 0);
      expect(first.cashDelta, -listing.askingPrice);
      expect(
        first.state.personalFinance.realEstate.single.lastRentalEvent,
        contains(ownedShop.name),
      );
      final blockedSale = _gameEngine.sellRealEstate(
        first.state,
        vacantCommercial.id,
      );
      final blockedLease = _gameEngine.configureRealEstateLease(
        first.state,
        vacantCommercial.id,
        RealEstateLeaseType.monthlyRent,
      );
      final blockedRenovation = _gameEngine.renovateRealEstate(
        first.state,
        vacantCommercial.id,
      );
      expect(blockedSale.success, isFalse);
      expect(blockedSale.message, contains('직영점'));
      expect(blockedLease.success, isFalse);
      expect(blockedLease.message, contains('직영점'));
      expect(blockedRenovation.success, isFalse);
      expect(blockedRenovation.message, contains('직영점'));

      final duplicate = _businessEngine.openOrAcquire(
        first.state,
        _launchRequest(
          listings[1],
          linkedRealEstateId: vacantCommercial.id,
          premiseMode: BusinessPremiseMode.ownedProperty,
        ),
      );
      expect(duplicate.success, isFalse);
      expect(duplicate.state.businesses.businesses, hasLength(1));

      final occupiedCommercial = vacantCommercial.copyWith(
        leaseType: RealEstateLeaseType.monthlyRent,
        leaseDeposit: 10000000,
        leaseMonthlyRent: 1000000,
        leaseRemainingMonths: 12,
      );
      final occupiedState = base.copyWith(
        personalFinance: base.personalFinance.copyWith(
          realEstate: [occupiedCommercial],
        ),
      );
      final occupied = _businessEngine.openOrAcquire(
        occupiedState,
        _launchRequest(
          listing,
          linkedRealEstateId: occupiedCommercial.id,
          premiseMode: BusinessPremiseMode.ownedProperty,
        ),
      );
      expect(occupied.success, isFalse);
      expect(occupied.message, contains('공실'));
    });

    test('실제 권역이 다른 보유 건물로 사업권을 순간이동시킬 수 없다', () {
      final base = _newState(seed: 'owned-property-district-lock');
      final marketAsset = realEstateMarketCatalog.firstWhere(
        (asset) => asset.type == RealEstateAssetType.officeBuilding,
      );
      final propertyDistrictId = businessDistrictIdForRealEstateRegion(
        marketAsset.region,
        province: marketAsset.province,
      );
      final listing = generateBusinessListings(
        worldSeed: base.simulationSeed,
        asOfDate: base.currentDate,
        count: LocalBusinessEngine.listingCount,
      ).firstWhere((candidate) => candidate.districtId != propertyDistrictId);
      final property = OwnedRealEstate(
        id: 'district-locked-office',
        optionId: 'district-locked-office',
        name: marketAsset.name,
        purchasePrice: marketAsset.priceAt(base.currentDate),
        acquiredDay: 1,
        monthlyIncome: 0,
        monthlyCost: marketAsset.monthlyOperatingCostAt(base.currentDate),
        marketAssetId: marketAsset.id,
        leaseType: RealEstateLeaseType.vacant,
      );
      final withProperty = base.copyWith(
        personalFinance: base.personalFinance.copyWith(realEstate: [property]),
      );

      final result = _businessEngine.openOrAcquire(
        withProperty,
        _launchRequest(
          listing,
          linkedRealEstateId: property.id,
          premiseMode: BusinessPremiseMode.ownedProperty,
        ),
      );

      expect(result.success, isFalse);
      expect(result.message, contains('지역'));
      expect(result.state.businesses.businesses, isEmpty);
    });
  });

  test('6축 운영정책 변경과 추가투자가 현금·점포·원장에 함께 반영된다', () {
    final base = _newState(seed: 'business-policy-investment');
    final listing = generateBusinessListings(
      worldSeed: base.simulationSeed,
      asOfDate: base.currentDate,
      count: LocalBusinessEngine.listingCount,
    ).first;
    final launch = _businessEngine.openOrAcquire(base, _launchRequest(listing));
    expect(launch.success, isTrue);
    final businessId = launch.state.businesses.businesses.single.id;
    const policy = BusinessOperatingPolicy(
      pricing: 1,
      quality: 4,
      staffing: 3,
      marketing: 4,
      openingHours: 2,
      maintenance: 4,
    );

    final updated = _businessEngine.updatePolicy(
      launch.state,
      businessId,
      policy,
    );
    expect(updated.success, isTrue);
    expect(
      updated.state.businesses.businessById(businessId)!.policy.toJson(),
      policy.toJson(),
    );

    final beforeInvestment = updated.state.businesses.businessById(businessId)!;
    final plan = businessInvestmentPlanFor(
      beforeInvestment,
      BusinessInvestmentKind.staffTraining,
    );
    final invested = _businessEngine.invest(
      updated.state,
      businessId,
      BusinessInvestmentKind.staffTraining,
    );
    final afterInvestment = invested.state.businesses.businessById(businessId)!;

    expect(invested.success, isTrue);
    expect(invested.cashDelta, -plan.cost);
    expect(invested.state.cash, updated.state.cash - plan.cost);
    expect(
      afterInvestment.staffMorale,
      greaterThan(beforeInvestment.staffMorale),
    );
    expect(afterInvestment.riskLevel, lessThan(beforeInvestment.riskLevel));
    expect(invested.state.ledger.last.account, 'company_bank');
    expect(
      invested.state.ledger.last.counterAccount,
      'business_investment_asset',
    );
  });

  test('사업 청산 손익은 미지급금 상계 전 총 회수자산을 기준으로 기록한다', () {
    final business =
        _monthlyBusiness(
          id: 'liquidation-accounting',
          profitable: true,
          accountsPayable: 3000000,
        ).copyWith(
          leaseDeposit: 10000000,
          equipmentBookValue: 20000000,
          goodwillBookValue: 5000000,
          equipmentCondition: 80,
        );
    final state = _newState(
      cash: 100000000,
      seed: 'business-liquidation-accounting',
    ).copyWith(businesses: _portfolioOf(business));
    final equipmentRecovery =
        (business.equipmentBookValue * business.equipmentCondition / 100 * 0.55)
            .round();
    final grossRecovery = business.leaseDeposit + equipmentRecovery;
    final payableOffset = business.accountsPayable;
    final netCash = grossRecovery - payableOffset;
    final expectedRealizedPnl = grossRecovery - business.bookValue;
    final netWorthBefore = state.balanceSheetNetWorth();

    final result = _businessEngine.closeOrSell(state, business.id);
    final disposition = result.state.ledger.singleWhere(
      (entry) => entry.id == 'business-disposition-${business.id}',
    );
    final closed = result.state.businesses.businessById(business.id)!;

    expect(result.success, isTrue);
    expect(result.cashDelta, netCash);
    expect(disposition.notional, grossRecovery);
    expect(disposition.realizedPnl, expectedRealizedPnl);
    expect(
      result.state.balanceSheetNetWorth() - netWorthBefore,
      expectedRealizedPnl,
    );
    expect(closed.accountsPayable, 0);
    expect(closed.bookValue, 0);
  });

  group('폐업 후 미지급금', () {
    test('폐업 당일 회사 통장 잔액으로 상계 후 잔존 미지급금을 즉시 상환한다', () {
      final business = _monthlyBusiness(
        id: 'same-day-payable',
        profitable: true,
        accountsPayable: 5000000,
      ).copyWith(leaseDeposit: 0, equipmentBookValue: 0, goodwillBookValue: 0);
      final state = _newState(
        cash: 3000000,
        seed: 'same-day-payable-repayment',
      ).copyWith(businesses: _portfolioOf(business));
      final netWorthBefore = state.balanceSheetNetWorth();
      final repaymentId =
          'business-disposition-${business.id}-remaining-payable-cash';

      final result = _businessEngine.closeOrSell(state, business.id);
      final closed = result.state.businesses.businessById(business.id)!;
      final repayment = result.state.ledger.singleWhere(
        (entry) => entry.id == repaymentId,
      );

      expect(result.success, isTrue);
      expect(result.cashDelta, -3000000);
      expect(result.state.cash, 0);
      expect(result.state.brokerageCash, 0);
      expect(closed.status, BusinessStatus.closed);
      expect(closed.accountsPayable, 2000000);
      expect(repayment.amount, -3000000);
      expect(repayment.notional, 3000000);
      expect(repayment.account, 'company_bank');
      expect(repayment.counterAccount, 'business_accounts_payable');
      expect(result.state.processedEventIds, contains(repaymentId));
      expect(result.state.balanceSheetNetWorth(), netWorthBefore);
    });

    test('여러 폐업점은 저장 순서와 무관하게 ID 순서로 한 번만 상환한다', () {
      final laterId =
          _monthlyBusiness(
            id: 'z-closed-payable',
            profitable: true,
            accountsPayable: 3000000,
          ).copyWith(
            status: BusinessStatus.closed,
            leaseDeposit: 0,
            equipmentBookValue: 0,
            goodwillBookValue: 0,
          );
      final earlierId =
          _monthlyBusiness(
            id: 'a-closed-payable',
            profitable: true,
            accountsPayable: 3000000,
          ).copyWith(
            status: BusinessStatus.closed,
            leaseDeposit: 0,
            equipmentBookValue: 0,
            goodwillBookValue: 0,
          );
      final state = _newState(
        cash: 4000000,
        seed: 'ordered-payable-repayment',
      ).copyWith(businesses: _portfolioOf(laterId).replaceBusiness(earlierId));
      final earlierRepaymentId =
          'business-payable-repayment-${earlierId.id}-${state.day}';
      final laterRepaymentId =
          'business-payable-repayment-${laterId.id}-${state.day}';

      final first = _businessEngine.repayDisposedBusinessPayablesForDay(state);
      final replayFromSameInput = _businessEngine
          .repayDisposedBusinessPayablesForDay(state);
      final repeated = _businessEngine.repayDisposedBusinessPayablesForDay(
        first.state,
      );
      final repaymentEntries = first.state.ledger
          .where(
            (entry) =>
                entry.id == earlierRepaymentId || entry.id == laterRepaymentId,
          )
          .toList(growable: false);

      expect(first.cashDelta, -4000000);
      expect(first.state.cash, 0);
      expect(
        first.state.businesses.businessById(earlierId.id)!.accountsPayable,
        0,
      );
      expect(
        first.state.businesses.businessById(laterId.id)!.accountsPayable,
        2000000,
      );
      expect(repaymentEntries.map((entry) => entry.id), [
        earlierRepaymentId,
        laterRepaymentId,
      ]);
      expect(repaymentEntries.map((entry) => entry.amount), [
        -3000000,
        -1000000,
      ]);
      expect(replayFromSameInput.state.toJson(), first.state.toJson());
      expect(repeated.cashDelta, 0);
      expect(repeated.state.toJson(), first.state.toJson());
      expect(
        repeated.state.processedEventIds.where(
          (sourceId) => sourceId == laterRepaymentId,
        ),
        hasLength(1),
      );
    });

    test('증권 예수금만 있으면 폐업점 미지급금 상환에 사용하지 않는다', () {
      final business =
          _monthlyBusiness(
            id: 'brokerage-isolated-payable',
            profitable: true,
            accountsPayable: 2000000,
          ).copyWith(
            status: BusinessStatus.closed,
            leaseDeposit: 0,
            equipmentBookValue: 0,
            goodwillBookValue: 0,
          );
      final state = _newState(
        cash: 5000000,
        seed: 'brokerage-isolated-payable',
      ).copyWith(brokerageCash: 5000000, businesses: _portfolioOf(business));
      final repaymentId =
          'business-payable-repayment-${business.id}-${state.day}';

      final result = _businessEngine.repayDisposedBusinessPayablesForDay(state);

      expect(result.cashDelta, 0);
      expect(result.state.cash, 5000000);
      expect(result.state.brokerageCash, 5000000);
      expect(
        result.state.businesses.businessById(business.id)!.accountsPayable,
        2000000,
      );
      expect(
        result.state.ledger.where((entry) => entry.id == repaymentId),
        isEmpty,
      );
      expect(result.state.processedEventIds, isNot(contains(repaymentId)));
    });

    test('청산 상환 뒤 하루 진행 후반 유입도 별도 ID로 같은 진행 안에 상환한다', () {
      const eventId = 'late-payable-income';
      final business = _monthlyBusiness(
        id: 'late-income-payable',
        profitable: true,
        accountsPayable: 120000,
      ).copyWith(leaseDeposit: 0, equipmentBookValue: 0, goodwillBookValue: 0);
      final base = _newState(cash: 30000, seed: 'late-payable-0');
      final closingState = base.copyWith(
        day: _dayFor(base, DateTime(2000, 1, 31)),
        businesses: _portfolioOf(business),
      );
      final closeRepaymentId =
          'business-disposition-${business.id}-remaining-payable-cash';

      final closed = _businessEngine.closeOrSell(closingState, business.id);
      final dailyRepaymentId =
          'business-payable-repayment-${business.id}-${closed.state.day + 1}';
      final ready = closed.state.copyWith(
        scheduledEvents: [
          ScheduledGameEvent(
            id: eventId,
            type: 'era_technology_result',
            dueDay: closed.state.day + 1,
          ),
        ],
        story: closed.state.story.copyWith(
          storyFlags: {
            ...closed.state.story.storyFlags,
            'eraPath:$eventId': 'era_partner',
            'eraTitle:$eventId': '후반 현금 유입 테스트',
          },
        ),
      );

      final advanced = _gameEngine.advanceOneDay(ready);
      final finalBusiness = advanced.businesses.businessById(business.id)!;
      final closeEntry = advanced.ledger.singleWhere(
        (entry) => entry.id == closeRepaymentId,
      );
      final incomeEntry = advanced.ledger.singleWhere(
        (entry) => entry.id == '$eventId-income',
      );
      final dailyEntry = advanced.ledger.singleWhere(
        (entry) => entry.id == dailyRepaymentId,
      );

      expect(closed.state.cash, 0);
      expect(
        closed.state.businesses.businessById(business.id)!.accountsPayable,
        90000,
      );
      expect(closeEntry.amount, -30000);
      expect(incomeEntry.amount, 90000);
      expect(dailyEntry.amount, -90000);
      expect(finalBusiness.accountsPayable, 0);
      expect(advanced.cash, 0);
      expect(advanced.brokerageCash, 0);
      expect(closeRepaymentId, isNot(dailyRepaymentId));
      expect(
        advanced.processedEventIds.where(
          (sourceId) => sourceId == closeRepaymentId,
        ),
        hasLength(1),
      );
      expect(
        advanced.processedEventIds.where(
          (sourceId) => sourceId == dailyRepaymentId,
        ),
        hasLength(1),
      );
      final duplicate = _businessEngine.repayDisposedBusinessPayablesForDay(
        advanced,
      );
      expect(duplicate.state.toJson(), advanced.toJson());
    });
  });
  group('월 정산', () {
    test('게임 하루 진행이 사업 월정산과 사건 엔진을 함께 호출한다', () {
      final base = _newState(cash: 50000000, seed: 'game-day-business-hook');
      final business = _monthlyBusiness(
        id: 'game-day-profit',
        profitable: true,
      );
      final januaryLast = base.copyWith(
        day: _dayFor(base, DateTime(2000, 1, 31)),
        businesses: _portfolioOf(business),
      );

      final advanced = _gameEngine.advanceOneDay(januaryLast);
      final settled = advanced.businesses.businessById(business.id)!;

      expect(advanced.currentDate, DateTime(2000, 2, 1));
      expect(settled.lastSettledMonth, '2000-01');
      expect(settled.statements, hasLength(1));
      expect(settled.statements.single.netProfit, greaterThan(0));
      expect(
        advanced.processedEventIds,
        contains('business-month-${business.id}-2000-01'),
      );
    });

    test('완전 영업월은 한 번만 정산되어 현금과 월별 손익이 중복되지 않는다', () {
      final base = _newState(cash: 50000000, seed: 'monthly-idempotency');
      final business = _monthlyBusiness(id: 'monthly-profit', profitable: true);
      final februaryFirst = base.copyWith(
        day: _dayFor(base, DateTime(2000, 2, 1)),
        businesses: _portfolioOf(business),
      );

      final first = _businessEngine.advanceOneDay(februaryFirst);
      final firstBusiness = first.state.businesses.businessById(business.id)!;
      final repeated = _businessEngine.advanceOneDay(first.state);
      final repeatedBusiness = repeated.state.businesses.businessById(
        business.id,
      )!;

      expect(first.success, isTrue);
      expect(firstBusiness.lastSettledMonth, '2000-01');
      expect(firstBusiness.statements, hasLength(1));
      expect(firstBusiness.statements.single.netProfit, greaterThan(0));
      expect(
        first.state.processedEventIds.where(
          (id) => id == 'business-month-${business.id}-2000-01',
        ),
        hasLength(1),
      );
      expect(repeated.state.cash, first.state.cash);
      expect(repeatedBusiness.statements, hasLength(1));
      expect(
        repeated.state.processedEventIds.where(
          (id) => id == 'business-month-${business.id}-2000-01',
        ),
        hasLength(1),
      );
    });

    test('3개월째 자금부족인 적자 점포는 미지급금과 함께 강제폐업한다', () {
      final base = _newState(cash: 10000, seed: 'forced-business-closure');
      final business = _monthlyBusiness(
        id: 'forced-loss',
        profitable: false,
        accountsPayable: 1000000,
        missedPaymentMonths: 2,
      );
      final februaryFirst = base.copyWith(
        day: _dayFor(base, DateTime(2000, 2, 1)),
        cash: 0,
        brokerageCash: 0,
        businesses: _portfolioOf(business),
      );

      final result = _businessEngine.advanceOneDay(februaryFirst);
      final closed = result.state.businesses.businessById(business.id)!;

      expect(result.success, isTrue);
      expect(closed.statements.single.netProfit, lessThan(0));
      expect(closed.status, BusinessStatus.closed);
      expect(closed.missedPaymentMonths, 3);
      expect(closed.accountsPayable, greaterThan(0));
      expect(result.state.businesses.totalClosures, 1);
      expect(
        result.state.processedEventIds,
        contains('business-month-${business.id}-2000-01'),
      );
      expect(
        result.state.processedEventIds,
        contains('business-liquidation-${business.id}'),
      );
    });

    test('신규 v3 점포는 12개월 연속 구조적 적자가 누적되면 현금이 있어도 폐업한다', () {
      final base = _newState(
        cash: 1000000000,
        seed: 'persistent-loss-business-closure',
      );
      final business = _monthlyBusiness(
        id: 'persistent-loss-v3',
        profitable: false,
        generatorVersion: 3,
        consecutiveLossMonths: businessPersistentLossClosureMonths - 1,
        totalProfit: -businessPersistentLossMinimumWon,
      );
      final februaryFirst = base.copyWith(
        day: _dayFor(base, DateTime(2000, 2, 1)),
        businesses: _portfolioOf(business),
      );

      final result = _businessEngine.advanceOneDay(februaryFirst);
      final closed = result.state.businesses.businessById(business.id)!;

      expect(closed.consecutiveLossMonths, businessPersistentLossClosureMonths);
      expect(closed.missedPaymentMonths, 0);
      expect(closed.status, BusinessStatus.closed);
      expect(result.state.businesses.totalClosures, 1);
      expect(
        result.state.processedEventIds,
        contains('business-liquidation-${business.id}'),
      );
    });

    test('같은 장기 적자라도 레거시 v2 점포에는 신규 폐업 규칙을 소급하지 않는다', () {
      final base = _newState(
        cash: 1000000000,
        seed: 'persistent-loss-business-v2',
      );
      final business = _monthlyBusiness(
        id: 'persistent-loss-v2',
        profitable: false,
        generatorVersion: 2,
        consecutiveLossMonths: businessPersistentLossClosureMonths - 1,
        totalProfit: -businessPersistentLossMinimumWon,
      );
      final februaryFirst = base.copyWith(
        day: _dayFor(base, DateTime(2000, 2, 1)),
        businesses: _portfolioOf(business),
      );

      final result = _businessEngine.advanceOneDay(februaryFirst);
      final legacy = result.state.businesses.businessById(business.id)!;

      expect(legacy.consecutiveLossMonths, businessPersistentLossClosureMonths);
      expect(legacy.missedPaymentMonths, 0);
      expect(legacy.status, BusinessStatus.struggling);
      expect(result.state.businesses.totalClosures, 0);
      expect(
        result.state.processedEventIds,
        isNot(contains('business-liquidation-${business.id}')),
      );
    });
  });
}
