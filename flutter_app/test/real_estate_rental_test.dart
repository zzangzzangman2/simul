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
  }) => OwnedRealEstate(
    id: 'rental-test-asset',
    optionId: 'rental-test-asset',
    name: '임대 시험 매물',
    purchasePrice: purchasePrice,
    acquiredDay: 1,
    monthlyIncome: 0,
    monthlyCost: 20000,
    purchaseDateIso: DateTime(2010, 1, 1).toIso8601String(),
    leaseType: leaseType,
    leaseDeposit: deposit,
    leaseMonthlyRent: monthlyRent,
    leaseRemainingMonths: remainingMonths,
    tenantReliability: reliability,
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
          .createNewGame('임대 계약 테스트', initialCash: 200000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      final state = base.copyWith(day: dayFor(base, DateTime(2010, 6, 15)));
      final marketAsset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final listing = realEstateListingsFor(
        marketAsset,
        state.simulationSeed,
      ).first;
      final purchase = engine.purchaseSpendingOption(state, listing.optionId);
      final owned = purchase.state.personalFinance.realEstate.single;
      final terms = realEstateLeaseTermsAt(
        date: purchase.state.currentDate,
        type: marketAsset.type,
        leaseType: RealEstateLeaseType.monthlyRent,
        marketValue: owned.estimatedMarketValue(purchase.state.day),
        marketMonthlyRent: listing.monthlyRentAt(purchase.state.currentDate),
      );

      final result = engine.configureRealEstateLease(
        purchase.state,
        owned.id,
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
      expect(next.cash, 80000);
      expect(
        next.ledger.any(
          (entry) =>
              entry.counterAccount == 'property_rent_income' &&
              entry.amount == 100000,
        ),
        isTrue,
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
  });
}
