import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/personal_finance_state.dart';
import 'package:millennium_capital/game/real_estate_financing.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_world.dart';

void main() {
  const engine = GameEngine();

  int dayFor(GameState state, DateTime date) =>
      date.difference(state.campaignStartDate).inDays + 1;

  group('부동산 담보대출', () {
    test('시대와 자산 유형에 따라 최대 LTV와 금리가 달라진다', () {
      final beforeAdult = realEstateFinancingTermsAt(
        DateTime(2009, 12, 31),
        RealEstateAssetType.apartment,
      );
      final easyMoney = realEstateFinancingTermsAt(
        DateTime(2010, 1, 1),
        RealEstateAssetType.apartment,
      );
      final regulated = realEstateFinancingTermsAt(
        DateTime(2021, 1, 1),
        RealEstateAssetType.apartment,
      );
      final commercial = realEstateFinancingTermsAt(
        DateTime(2021, 1, 1),
        RealEstateAssetType.officeBuilding,
      );

      expect(beforeAdult.available, isFalse);
      expect(easyMoney.maxLtvPercent, 70);
      expect(regulated.maxLtvPercent, 40);
      expect(
        commercial.annualInterestRate,
        greaterThan(regulated.annualInterestRate),
      );
    });

    test('대출 옵션 ID는 원래 매물 ID와 LTV를 손실 없이 복원한다', () {
      const base = 'real-estate-listing::uijeongbu_station_officetel_20::1';
      final encoded = realEstateFinancedOptionId(base, 70);
      final parsed = parseRealEstateFinancingRequest(encoded);

      expect(parsed.baseOptionId, base);
      expect(parsed.requestedLtvPercent, 70);
      expect(parseRealEstateListingOptionId(parsed.baseOptionId), isNotNull);
    });

    test('대출 매입은 자기자본만 차감하고 원가와 부채를 함께 저장한다', () {
      final base = engine
          .createNewGame('대출 매입 테스트', initialCash: 200000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      final state = base.copyWith(day: dayFor(base, DateTime(2010, 6, 15)));
      final asset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final listing = realEstateListingsFor(asset, state.simulationSeed).first;
      final quote = listing.quoteAt(state.currentDate);
      final terms = realEstateFinancingTermsAt(state.currentDate, asset.type);
      final plan = terms.planFor(quote, terms.maxLtvPercent);

      final result = engine.purchaseSpendingOption(
        state,
        realEstateFinancedOptionId(listing.optionId, terms.maxLtvPercent),
      );

      expect(result.success, isTrue);
      expect(result.cashDelta, -plan.cashRequired);
      expect(result.state.cash, state.cash - plan.cashRequired);
      final owned = result.state.personalFinance.realEstate.single;
      expect(owned.purchasePrice, quote.totalCash);
      expect(owned.cashInvestedAtPurchase, plan.cashRequired);
      expect(owned.mortgageOriginalPrincipal, plan.principal);
      expect(owned.mortgageBalance, plan.principal);
      expect(owned.monthlyMortgagePayment, plan.monthlyPayment);
      expect(
        result.state.ledger
            .where((entry) => entry.counterAccount == 'mortgage_payable')
            .single
            .notional,
        plan.principal,
      );

      final restored = OwnedRealEstate.fromJson(owned.toJson());
      expect(restored.mortgageBalance, owned.mortgageBalance);
      expect(
        restored.mortgageAnnualInterestRate,
        owned.mortgageAnnualInterestRate,
      );
    });

    test('월 정산에서 원리금이 납부되면 대출 잔액이 감소한다', () {
      final base = engine
          .createNewGame('대출 상환 테스트', initialCash: 200000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      final december = base.copyWith(day: dayFor(base, DateTime(2010, 12, 31)));
      final asset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final listing = realEstateListingsFor(
        asset,
        december.simulationSeed,
      ).first;
      final terms = realEstateFinancingTermsAt(
        december.currentDate,
        asset.type,
      );
      final purchase = engine.purchaseSpendingOption(
        december,
        realEstateFinancedOptionId(listing.optionId, terms.maxLtvPercent),
      );
      final before = purchase.state.personalFinance.realEstate.single;

      final january = engine.advanceOneDay(purchase.state);
      final after = january.personalFinance.realEstate.single;

      expect(after.mortgageBalance, lessThan(before.mortgageBalance));
      expect(after.mortgagePaymentsMade, 1);
      expect(after.mortgageMissedPayments, 0);
      expect(
        january.ledger.any(
          (entry) => entry.counterAccount == 'mortgage_payment',
        ),
        isTrue,
      );
    });

    test('대출 부동산 매각은 잔액을 상환하고 순수 자기자본만 지급한다', () {
      final base = engine
          .createNewGame('대출 매각 테스트', initialCash: 200000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      final state = base.copyWith(day: dayFor(base, DateTime(2010, 6, 15)));
      final marketAsset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final listing = realEstateListingsFor(
        marketAsset,
        state.simulationSeed,
      ).first;
      final terms = realEstateFinancingTermsAt(
        state.currentDate,
        marketAsset.type,
      );
      final purchase = engine.purchaseSpendingOption(
        state,
        realEstateFinancedOptionId(listing.optionId, terms.maxLtvPercent),
      );
      final owned = purchase.state.personalFinance.realEstate.single;
      final eligible = purchase.state.copyWith(day: owned.acquiredDay + 30);
      final gross = owned.estimatedSaleValue(eligible.day);
      final expectedNet = gross - owned.mortgageBalance;

      final sale = engine.sellRealEstate(eligible, owned.id);

      expect(sale.success, isTrue);
      expect(sale.cashDelta, expectedNet);
      expect(sale.state.cash, eligible.cash + expectedNet);
      expect(sale.state.personalFinance.realEstate, isEmpty);
      expect(
        sale.state.ledger.any((entry) => entry.account == 'mortgage_payable'),
        isTrue,
      );
    });

    test('원리금 3회 연속 연체 시 강제매각되고 결손채무가 남는다', () {
      final base = engine
          .createNewGame('대출 연체 테스트')
          .copyWith(cash: 0, brokerageCash: 0, decisions: const []);
      final mortgageAsset = OwnedRealEstate(
        id: 'arrears-property',
        optionId: 'arrears-property',
        name: '연체 시험 매물',
        purchasePrice: 20000000,
        acquiredDay: 1,
        monthlyIncome: 0,
        monthlyCost: 0,
        purchaseDateIso: DateTime(2010, 1, 1).toIso8601String(),
        cashInvestedAtPurchase: 5000000,
        mortgageOriginalPrincipal: 100000000,
        mortgageBalance: 100000000,
        mortgageAnnualInterestRate: 0.12,
        mortgageTermMonths: 120,
      );
      var state = base.copyWith(
        personalFinance: base.personalFinance.copyWith(
          realEstate: [mortgageAsset],
        ),
      );

      for (final monthEnd in [
        DateTime(2010, 12, 31),
        DateTime(2011, 1, 31),
        DateTime(2011, 2, 28),
      ]) {
        state = state.copyWith(
          day: dayFor(state, monthEnd),
          cash: 0,
          brokerageCash: 0,
          decisions: const [],
        );
        state = engine.advanceOneDay(state);
      }

      expect(state.personalFinance.realEstate, isEmpty);
      expect(state.story.flagInt('mortgageForeclosureCount'), 1);
      expect(state.story.flagInt('mortgageDeficiencyDebt'), greaterThan(0));
      expect(
        state.ledger.any(
          (entry) => entry.counterAccount == 'mortgage_foreclosure_sale',
        ),
        isTrue,
      );
      expect(
        state.ledger.where(
          (entry) => entry.counterAccount == 'mortgage_arrears',
        ),
        hasLength(3),
      );
    });
  });
}
