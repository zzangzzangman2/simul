import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/personal_finance_state.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_rental.dart';
import 'package:millennium_capital/game/real_estate_world.dart';

void main() {
  const engine = GameEngine();

  int dayFor(GameState state, DateTime date) =>
      date.difference(state.campaignStartDate).inDays + 1;

  String seedWithActiveListing(RealEstateMarketAsset asset, DateTime date) {
    for (var index = 0; index < 100; index += 1) {
      final seed = 'rental-active-$index';
      if (realEstateActiveListingsAt(asset, seed, date).isNotEmpty) {
        return seed;
      }
    }
    throw StateError('활성 임대 매물 seed를 찾지 못했습니다.');
  }

  DateTime monthWithIncident(
    String seed,
    RealEstateRentalIncident expected, {
    required bool rentBearing,
  }) {
    for (var year = 2010; year <= 2026; year += 1) {
      for (var month = 1; month <= 12; month += 1) {
        final date = DateTime(year, month);
        final result = realEstateRentalIncidentAt(
          worldSeed: seed,
          assetId: 'rental-test-asset',
          date: date,
          tenantReliability: 60,
          marketValue: 20000000,
          baseMonthlyCost: 20000,
          rentBearing: rentBearing,
        );
        if (result.incident == expected) return date;
      }
    }
    throw StateError('${expected.name} 사건 월을 찾지 못했습니다.');
  }

  OwnedRealEstate rentalAsset({
    required RealEstateLeaseType leaseType,
    required int remainingMonths,
    int deposit = 2000000,
    int monthlyRent = 100000,
    int reliability = 60,
    int purchasePrice = 20000000,
    String worldSeed = '',
    int nextRentalSettlementDay = 0,
    int propertyCondition = 70,
    bool insuranceActive = false,
    String? marketAssetId,
  }) => OwnedRealEstate(
    id: 'rental-test-asset',
    optionId: 'rental-test-asset',
    name: '임대 시험 매물',
    purchasePrice: purchasePrice,
    acquiredDay: 1,
    monthlyIncome: 0,
    monthlyCost: 20000,
    marketAssetId: marketAssetId,
    purchaseDateIso: DateTime(2010, 1, 1).toIso8601String(),
    realEstateWorldSeed: worldSeed,
    leaseType: leaseType,
    leaseDeposit: deposit,
    leaseMonthlyRent: monthlyRent,
    leaseRemainingMonths: remainingMonths,
    nextRentalSettlementDay: nextRentalSettlementDay,
    tenantReliability: reliability,
    propertyCondition: propertyCondition,
    insuranceActive: insuranceActive,
  );

  group('전세·월세 임대 운영', () {
    test('월세와 전세는 보증금·월세 현금흐름이 다르다', () {
      final monthly = realEstateLeaseTermsAt(
        date: DateTime(2021),
        type: RealEstateAssetType.apartment,
        leaseType: RealEstateLeaseType.monthlyRent,
        marketValue: 500000000,
        marketMonthlyRent: 1500000,
      );
      final jeonse = realEstateLeaseTermsAt(
        date: DateTime(2021),
        type: RealEstateAssetType.apartment,
        leaseType: RealEstateLeaseType.jeonse,
        marketValue: 500000000,
        marketMonthlyRent: 1500000,
      );

      expect(monthly.deposit, 50000000);
      expect(monthly.monthlyRent, 1500000);
      expect(jeonse.deposit, 340000000);
      expect(jeonse.monthlyRent, 0);
      expect(
        realEstateSupportsJeonse(RealEstateAssetType.officeBuilding),
        isFalse,
      );
    });

    test('월세 계약은 보증금을 받고 반환부채와 계약 상태를 저장한다', () {
      final base = engine
          .createNewGame(
            '임대 계약 테스트',
            initialCash: 200000000,
            worldSeed: seedWithActiveListing(
              realEstateMarketAssetById('uijeongbu_station_officetel_20')!,
              DateTime(2010, 6, 15),
            ),
          )
          .copyWith(brokerageCash: 0, decisions: const []);
      final state = base.copyWith(day: dayFor(base, DateTime(2010, 6, 15)));
      final marketAsset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final listing = realEstateActiveListingsAt(
        marketAsset,
        state.simulationSeed,
        state.currentDate,
      ).first;
      final purchase = engine.purchaseSpendingOption(state, listing.optionId);
      final owned = purchase.state.personalFinance.realEstate.single;
      final readyOwned = owned.copyWith(
        vacancyMonths: realEstateTenantSearchMonths(
          worldSeed: purchase.state.simulationSeed,
          assetId: owned.id,
        ),
      );
      final readyState = purchase.state.copyWith(
        personalFinance: purchase.state.personalFinance.copyWith(
          realEstate: [readyOwned],
        ),
      );
      final terms = realEstateLeaseTermsAt(
        date: readyState.currentDate,
        type: marketAsset.type,
        leaseType: RealEstateLeaseType.monthlyRent,
        marketValue: readyOwned.estimatedMarketValue(readyState.day),
        marketMonthlyRent:
            (listing.monthlyRentAt(readyState.currentDate) *
                    readyOwned.conditionRentMultiplier)
                .round(),
        mortgageBalance: readyOwned.mortgageBalance,
      );
      final netWorthBeforeLease = readyState.balanceSheetNetWorth();

      final result = engine.configureRealEstateLease(
        readyState,
        readyOwned.id,
        RealEstateLeaseType.monthlyRent,
      );

      expect(result.success, isTrue);
      expect(result.cashDelta, terms.initialCashDelta);
      final leased = result.state.personalFinance.realEstate.single;
      expect(leased.leaseType, RealEstateLeaseType.monthlyRent);
      expect(leased.leaseDeposit, terms.deposit);
      expect(leased.leaseRemainingMonths, 24);
      expect(leased.tenantReliability, inInclusiveRange(60, 95));
      expect(
        result.state.personalFinance.totalTenantDepositLiability,
        terms.deposit,
      );
      expect(
        result.state.ledger.any(
          (entry) => entry.counterAccount == 'tenant_deposit_payable',
        ),
        isTrue,
      );
      expect(
        OwnedRealEstate.fromJson(leased.toJson()).leaseDeposit,
        terms.deposit,
      );
      expect(
        result.state.balanceSheetNetWorth(),
        netWorthBeforeLease - terms.placementFee,
        reason: '받은 보증금은 현금과 반환부채를 동시에 늘리므로 순자산이 아니다.',
      );
    });

    test('담보대출과 전세보증금 합계는 시가의 합산 한도를 넘지 않는다', () {
      final terms = realEstateLeaseTermsAt(
        date: DateTime(2015),
        type: RealEstateAssetType.apartment,
        leaseType: RealEstateLeaseType.jeonse,
        marketValue: 500000000,
        marketMonthlyRent: 1500000,
        mortgageBalance: 350000000,
      );

      expect(terms.deposit, 50000000);
      expect(350000000 + terms.deposit, lessThanOrEqualTo(500000000 * 0.80));
    });

    test('정상 월에는 월세가 입금되고 계약기간이 한 달 줄어든다', () {
      final base = engine
          .createNewGame('정상 월세 테스트')
          .copyWith(cash: 0, brokerageCash: 0, decisions: const []);
      final month = monthWithIncident(
        base.simulationSeed,
        RealEstateRentalIncident.none,
        rentBearing: true,
      );
      final priorDay = month.subtract(const Duration(days: 1));
      final state = base.copyWith(
        day: dayFor(base, priorDay),
        personalFinance: base.personalFinance.copyWith(
          realEstate: [
            rentalAsset(
              leaseType: RealEstateLeaseType.monthlyRent,
              remainingMonths: 24,
            ),
          ],
        ),
      );

      final next = engine.advanceOneDay(state);
      final asset = next.personalFinance.realEstate.single;

      expect(asset.leaseRemainingMonths, 23);
      expect(asset.rentArrearsMonths, 0);
      final holdingTax = realEstateMonthlyHoldingTax(
        date: next.currentDate,
        type: RealEstateAssetType.commercialUnit,
        marketValue: asset.estimatedMarketValue(next.day),
        ownedHousingCount: 0,
      );
      final rentalIncomeTax = realEstateRentalIncomeTax(
        date: next.currentDate,
        grossRent: 100000,
        deductibleOperatingCost: 20000,
      );
      expect(next.cash, 80000 - rentalIncomeTax - holdingTax);
      expect(
        next.ledger.any(
          (entry) =>
              entry.counterAccount == 'property_rent_income' &&
              entry.amount == 100000,
        ),
        isTrue,
      );
    });

    test('기존 자동운영 매물은 다음 정산에 공실로 전환되고 자동수익이 중단된다', () {
      final base = engine
          .createNewGame('자동운영 마이그레이션 테스트')
          .copyWith(cash: 1000000, brokerageCash: 0, decisions: const []);
      final month = monthWithIncident(
        base.simulationSeed,
        RealEstateRentalIncident.none,
        rentBearing: false,
      );
      final state = base.copyWith(
        day: dayFor(base, month.subtract(const Duration(days: 1))),
        personalFinance: base.personalFinance.copyWith(
          realEstate: [
            rentalAsset(
              leaseType: RealEstateLeaseType.automatic,
              remainingMonths: 0,
            ),
          ],
        ),
      );

      final next = engine.advanceOneDay(state);
      final migrated = next.personalFinance.realEstate.single;

      expect(migrated.leaseType, RealEstateLeaseType.vacant);
      expect(migrated.vacancyMonths, 1);
      expect(migrated.totalVacancyMonths, 1);
      expect(next.personalFinance.totalPropertyIncome, 0);
      expect(
        next.ledger.any(
          (entry) => entry.counterAccount == 'property_rent_income',
        ),
        isFalse,
      );
    });

    test('세입자 신뢰도에 따라 월세 연체가 발생하고 미수금으로 기록된다', () {
      final base = engine
          .createNewGame('월세 연체 테스트')
          .copyWith(cash: 0, brokerageCash: 0, decisions: const []);
      final month = monthWithIncident(
        base.simulationSeed,
        RealEstateRentalIncident.lateRent,
        rentBearing: true,
      );
      final state = base.copyWith(
        day: dayFor(base, month.subtract(const Duration(days: 1))),
        personalFinance: base.personalFinance.copyWith(
          realEstate: [
            rentalAsset(
              leaseType: RealEstateLeaseType.monthlyRent,
              remainingMonths: 24,
            ),
          ],
        ),
      );

      final next = engine.advanceOneDay(state);

      expect(next.personalFinance.realEstate.single.rentArrearsMonths, 1);
      expect(
        next.ledger.any(
          (entry) => entry.counterAccount == 'tenant_rent_arrears',
        ),
        isTrue,
      );
    });

    test('공실·전세에서도 수리 사건과 수리비가 누적된다', () {
      final base = engine
          .createNewGame('임대 수리 테스트', initialCash: 10000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      DateTime? repairMonth;
      RealEstateRentalIncident? repairIncident;
      for (final expected in [
        RealEstateRentalIncident.majorRepair,
        RealEstateRentalIncident.minorRepair,
      ]) {
        try {
          repairMonth = monthWithIncident(
            base.simulationSeed,
            expected,
            rentBearing: false,
          );
          repairIncident = expected;
          break;
        } on StateError {
          continue;
        }
      }
      expect(repairMonth, isNotNull);
      final state = base.copyWith(
        day: dayFor(base, repairMonth!.subtract(const Duration(days: 1))),
        personalFinance: base.personalFinance.copyWith(
          realEstate: [
            rentalAsset(
              leaseType: RealEstateLeaseType.jeonse,
              remainingMonths: 24,
              monthlyRent: 0,
            ),
          ],
        ),
      );

      final next = engine.advanceOneDay(state);
      final asset = next.personalFinance.realEstate.single;

      expect(asset.totalRepairCosts, greaterThan(0));
      expect(asset.lastRentalEvent, repairIncident!.label);
      expect(
        next.ledger.any(
          (entry) => entry.counterAccount == 'rental_repair_event',
        ),
        isTrue,
      );
    });

    test('계약 만료 때 현금이 있으면 보증금을 반환하고 공실이 된다', () {
      final base = engine
          .createNewGame('보증금 반환 테스트', initialCash: 10000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      final priorDay = DateTime(2012, 1, 31);
      final state = base.copyWith(
        day: dayFor(base, priorDay),
        personalFinance: base.personalFinance.copyWith(
          realEstate: [
            rentalAsset(
              leaseType: RealEstateLeaseType.jeonse,
              remainingMonths: 1,
              deposit: 5000000,
              monthlyRent: 0,
            ),
          ],
        ),
      );

      final next = engine.advanceOneDay(state);
      final asset = next.personalFinance.realEstate.single;

      expect(asset.leaseType, RealEstateLeaseType.vacant);
      expect(asset.leaseDeposit, 0);
      expect(
        next.ledger.any((entry) => entry.id.contains('deposit-refund')),
        isTrue,
      );
      expect(next.story.flagInt('tenantDepositDebt'), 0);
    });

    test('보증금을 돌려줄 현금이 없으면 매물이 경매되고 부족액이 채무로 남는다', () {
      final base = engine
          .createNewGame('보증금 경매 테스트')
          .copyWith(cash: 0, brokerageCash: 0, decisions: const []);
      final priorDay = DateTime(2012, 1, 31);
      final state = base.copyWith(
        day: dayFor(base, priorDay),
        personalFinance: base.personalFinance.copyWith(
          realEstate: [
            rentalAsset(
              leaseType: RealEstateLeaseType.jeonse,
              remainingMonths: 1,
              deposit: 100000000,
              monthlyRent: 0,
            ),
          ],
        ),
      );

      final next = engine.advanceOneDay(state);

      expect(next.personalFinance.realEstate, isEmpty);
      expect(next.story.flagInt('tenantDepositAuctionCount'), 1);
      expect(next.story.flagInt('tenantDepositDebt'), greaterThan(0));
      expect(
        next.ledger.any(
          (entry) => entry.counterAccount == 'tenant_deposit_auction_sale',
        ),
        isTrue,
      );
    });

    test('보증금 반환 전에는 임대 중인 매물을 일반 매각할 수 없다', () {
      final base = engine
          .createNewGame('임대 중 매각 제한 테스트')
          .copyWith(cash: 0, brokerageCash: 0, decisions: const []);
      final state = base.copyWith(
        day: 100,
        personalFinance: base.personalFinance.copyWith(
          realEstate: [
            rentalAsset(
              leaseType: RealEstateLeaseType.monthlyRent,
              remainingMonths: 12,
            ),
          ],
        ),
      );

      final result = engine.sellRealEstate(state, 'rental-test-asset');

      expect(result.success, isFalse);
      expect(result.message, contains('보증금을 정산'));
      expect(result.state.personalFinance.realEstate, hasLength(1));
    });

    test('월말 직후에는 새 임대자산의 수입·비용·계약기간을 정산하지 않는다', () {
      final base = engine
          .createNewGame('임대 정산일 테스트', initialCash: 10000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      final priorDay = DateTime(2012, 1, 31);
      final firstSettlementDay = dayFor(base, DateTime(2012, 3, 1));
      final state = base.copyWith(
        day: dayFor(base, priorDay),
        personalFinance: base.personalFinance.copyWith(
          realEstate: [
            rentalAsset(
              leaseType: RealEstateLeaseType.monthlyRent,
              remainingMonths: 24,
              nextRentalSettlementDay: firstSettlementDay,
            ),
          ],
        ),
      );

      final next = engine.advanceOneDay(state);
      final asset = next.personalFinance.realEstate.single;

      expect(asset.leaseRemainingMonths, 24);
      expect(next.personalFinance.totalPropertyIncome, 0);
      expect(
        next.ledger.any(
          (entry) => entry.counterAccount == 'property_rent_income',
        ),
        isFalse,
      );
    });

    test('다주택 현금매입 뒤 전세보증금으로 60% 총부채 한도를 우회할 수 없다', () {
      final base = engine
          .createNewGame('현금매입 전세 우회', initialCash: 200000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      final state = base.copyWith(
        day: dayFor(base, DateTime(2021, 6, 15)),
        personalFinance: base.personalFinance.copyWith(
          realEstate: [
            rentalAsset(
              leaseType: RealEstateLeaseType.vacant,
              remainingMonths: 0,
              purchasePrice: 100000000,
              marketAssetId: 'uijeongbu_station_officetel_20',
            ).copyWith(vacancyMonths: 3),
            const OwnedRealEstate(
              id: 'small-cash-property',
              optionId: 'small-cash-property',
              name: '소형 현금 매입 자산',
              purchasePrice: 1000000,
              acquiredDay: 1,
              monthlyIncome: 0,
              monthlyCost: 0,
              leaseType: RealEstateLeaseType.vacant,
              vacancyMonths: 3,
            ),
          ],
        ),
      );

      final result = engine.configureRealEstateLease(
        state,
        'rental-test-asset',
        RealEstateLeaseType.jeonse,
      );

      expect(result.success, isFalse);
      expect(result.message, contains('60%'));
      expect(result.state.personalFinance.totalTenantDepositLiability, 0);
    });

    test('직접사용 자산에는 공실 사건이 없고 랜드마크 지분은 분배금을 준다', () {
      final base = engine
          .createNewGame('직접사용·랜드마크', initialCash: 100000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      final state = base.copyWith(
        day: dayFor(base, DateTime(2018, 1, 31)),
        personalFinance: base.personalFinance.copyWith(
          realEstate: const [
            OwnedRealEstate(
              id: 'owner-office-direct',
              optionId: 'owner_office',
              name: '직접사용 사무실',
              purchasePrice: 50000000,
              acquiredDay: 1,
              monthlyIncome: 0,
              monthlyCost: 100000,
            ),
            OwnedRealEstate(
              id: 'landmark-share',
              optionId: 'landmark-share',
              name: '랜드마크 지분',
              purchasePrice: 100000000,
              acquiredDay: 1,
              monthlyIncome: 500000,
              monthlyCost: 50000,
              marketAssetId: 'jamsil_landmark_fund',
            ),
          ],
        ),
      );

      final next = engine.advanceOneDay(state);
      final direct = next.personalFinance.realEstate.first;
      final landmark = next.personalFinance.realEstate.last;

      expect(direct.vacancyMonths, 0);
      expect(direct.totalVacancyMonths, 0);
      expect(direct.lastRentalEvent, contains('직접 사용'));
      expect(landmark.vacancyMonths, 0);
      expect(next.personalFinance.totalPropertyIncome, greaterThan(0));
    });

    test('리모델링과 보험은 상태·위험·월 보험료에 연결된다', () {
      final base = engine
          .createNewGame('리모델링 보험', initialCash: 100000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      final state = base.copyWith(
        personalFinance: base.personalFinance.copyWith(
          realEstate: [
            rentalAsset(
              leaseType: RealEstateLeaseType.vacant,
              remainingMonths: 0,
              propertyCondition: 40,
            ),
          ],
        ),
      );

      final renovated = engine.renovateRealEstate(state, 'rental-test-asset');
      expect(renovated.success, isTrue);
      final improved = renovated.state.personalFinance.realEstate.single;
      expect(improved.propertyCondition, 65);
      expect(
        improved.conditionRepairProbabilityMultiplier,
        lessThan(
          state
              .personalFinance
              .realEstate
              .single
              .conditionRepairProbabilityMultiplier,
        ),
      );

      final insured = engine.setRealEstateInsurance(
        renovated.state,
        'rental-test-asset',
        true,
      );
      expect(insured.success, isTrue);
      expect(
        insured.state.personalFinance.realEstate.single.insuranceActive,
        isTrue,
      );
      expect(
        OwnedRealEstate.fromJson(
          insured.state.personalFinance.realEstate.single.toJson(),
        ).insuranceActive,
        isTrue,
      );
    });

    test('대형수리 보험은 자기부담금을 남기고 일부 비용을 보상한다', () {
      final base = engine
          .createNewGame('수리 보험 보상', initialCash: 100000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      String? repairSeed;
      DateTime? repairMonth;
      for (
        var seedIndex = 0;
        seedIndex < 100 && repairMonth == null;
        seedIndex += 1
      ) {
        final candidateSeed = 'insured-repair-$seedIndex';
        try {
          repairMonth = monthWithIncident(
            candidateSeed,
            RealEstateRentalIncident.majorRepair,
            rentBearing: false,
          );
          repairSeed = candidateSeed;
        } on StateError {
          continue;
        }
      }
      expect(repairMonth, isNotNull);
      final incident = realEstateRentalIncidentAt(
        worldSeed: repairSeed!,
        assetId: 'rental-test-asset',
        date: repairMonth!,
        tenantReliability: 60,
        marketValue: 18000000,
        baseMonthlyCost: 20000,
        rentBearing: false,
      );
      final state = base.copyWith(
        day: dayFor(base, repairMonth.subtract(const Duration(days: 1))),
        personalFinance: base.personalFinance.copyWith(
          realEstate: [
            rentalAsset(
              leaseType: RealEstateLeaseType.vacant,
              remainingMonths: 0,
              insuranceActive: true,
              worldSeed: repairSeed,
            ),
          ],
        ),
      );

      final next = engine.advanceOneDay(state);
      final owned = next.personalFinance.realEstate.single;

      expect(owned.totalRepairCosts, greaterThan(0));
      expect(owned.totalRepairCosts, lessThan(incident.repairCost));
      expect(
        next.ledger.any(
          (entry) => entry.account == 'insurance_claim_receivable',
        ),
        isTrue,
      );
      expect(
        next.ledger.any(
          (entry) => entry.account == 'property_insurance_expense',
        ),
        isTrue,
      );
    });

    test('월세 계약은 만기 직전 갱신하거나 보증금·법적비용을 내고 중도 종료한다', () {
      final base = engine
          .createNewGame('월세 갱신 종료', initialCash: 20000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      final state = base.copyWith(
        day: dayFor(base, DateTime(2021, 6, 15)),
        personalFinance: base.personalFinance.copyWith(
          realEstate: [
            rentalAsset(
              leaseType: RealEstateLeaseType.monthlyRent,
              remainingMonths: 2,
            ),
          ],
        ),
      );

      final renewed = engine.renewRealEstateMonthlyLease(
        state,
        'rental-test-asset',
      );
      expect(renewed.success, isTrue);
      final lease = renewed.state.personalFinance.realEstate.single;
      expect(lease.leaseRemainingMonths, 24);

      final ended = engine.terminateRealEstateMonthlyLeaseEarly(
        renewed.state,
        'rental-test-asset',
      );
      expect(ended.success, isTrue);
      expect(
        ended.state.personalFinance.realEstate.single.leaseType,
        RealEstateLeaseType.vacant,
      );
      expect(ended.state.personalFinance.totalTenantDepositLiability, 0);
      expect(
        ended.state.ledger.any(
          (entry) => entry.counterAccount == 'tenant_termination_legal_cost',
        ),
        isTrue,
      );
    });

    test('상습 연체는 월세 손실·퇴거 법적비용·보증금 정산으로 이어진다', () {
      String? incidentSeed;
      DateTime? incidentMonth;
      for (
        var seedIndex = 0;
        seedIndex < 100 && incidentMonth == null;
        seedIndex += 1
      ) {
        final seed = 'tenant-default-$seedIndex';
        for (
          var year = 2010;
          year <= 2026 && incidentMonth == null;
          year += 1
        ) {
          for (var month = 1; month <= 12; month += 1) {
            final date = DateTime(year, month);
            if (realEstateRentalIncidentAt(
                  worldSeed: seed,
                  assetId: 'rental-test-asset',
                  date: date,
                  tenantReliability: 60,
                  marketValue: 20000000,
                  baseMonthlyCost: 20000,
                  rentBearing: true,
                ).incident ==
                RealEstateRentalIncident.tenantDefault) {
              incidentSeed = seed;
              incidentMonth = date;
              break;
            }
          }
        }
      }
      expect(incidentMonth, isNotNull);
      final base = engine
          .createNewGame('상습 연체 퇴거', initialCash: 10000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      final state = base.copyWith(
        day: dayFor(base, incidentMonth!.subtract(const Duration(days: 1))),
        personalFinance: base.personalFinance.copyWith(
          realEstate: [
            rentalAsset(
              leaseType: RealEstateLeaseType.monthlyRent,
              remainingMonths: 24,
              worldSeed: incidentSeed!,
            ),
          ],
        ),
      );

      final next = engine.advanceOneDay(state);
      final asset = next.personalFinance.realEstate.single;

      expect(asset.leaseType, RealEstateLeaseType.vacant);
      expect(asset.leaseDeposit, 0);
      expect(
        next.ledger.any(
          (entry) => entry.counterAccount == 'tenant_default_loss',
        ),
        isTrue,
      );
      expect(
        next.ledger.any(
          (entry) => entry.counterAccount == 'tenant_eviction_legal_cost',
        ),
        isTrue,
      );
    });
  });
}
