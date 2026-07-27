import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/personal_finance_state.dart';
import 'package:millennium_capital/game/real_estate_financing.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_rental.dart';
import 'package:millennium_capital/game/real_estate_world.dart';

void main() {
  const engine = GameEngine();

  int dayFor(GameState state, DateTime date) =>
      date.difference(state.campaignStartDate).inDays + 1;

  String seedWithActiveListing(
    RealEstateMarketAsset asset,
    DateTime date,
    String prefix,
  ) {
    for (var index = 0; index < 100; index += 1) {
      final seed = '$prefix-$index';
      if (realEstateActiveListingsAt(asset, seed, date).isNotEmpty) {
        return seed;
      }
    }
    throw StateError('활성 매물 seed를 찾지 못했습니다.');
  }

  GameState withRecurringIncome(GameState state) => state.copyWith(
    company: state.company.copyWith(
      votingOwnershipPct: 55,
      monthlyRevenue: 100000000,
    ),
  );

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
          .createNewGame(
            '대출 매입 테스트',
            initialCash: 200000000,
            worldSeed: seedWithActiveListing(
              realEstateMarketAssetById('uijeongbu_station_officetel_20')!,
              DateTime(2010, 6, 15),
              'mortgage-purchase',
            ),
          )
          .copyWith(brokerageCash: 0, decisions: const []);
      final state = withRecurringIncome(
        base,
      ).copyWith(day: dayFor(base, DateTime(2010, 6, 15)));
      final asset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final listing = realEstateActiveListingsAt(
        asset,
        state.simulationSeed,
        state.currentDate,
      ).first;
      final quote = listing.quoteAt(state.currentDate);
      final terms = realEstateFinancingTermsAt(state.currentDate, asset.type);
      final plan = terms.planFor(quote, terms.maxLtvPercent);
      final netWorthBefore = state.balanceSheetNetWorth();

      final result = engine.purchaseSpendingOption(
        state,
        realEstateFinancedOptionId(listing.optionId, terms.maxLtvPercent),
      );

      expect(result.success, isTrue, reason: result.message);
      expect(result.cashDelta, -plan.cashRequired);
      expect(result.state.cash, state.cash - plan.cashRequired);
      final owned = result.state.personalFinance.realEstate.single;
      expect(owned.purchasePrice, quote.totalCash);
      expect(owned.cashInvestedAtPurchase, plan.cashRequired);
      expect(owned.mortgageOriginalPrincipal, plan.principal);
      expect(owned.mortgageBalance, plan.principal);
      expect(owned.monthlyMortgagePayment, plan.monthlyPayment);
      expect(owned.leaseType, RealEstateLeaseType.vacant);
      expect(
        result.state.balanceSheetNetWorth(),
        netWorthBefore - quote.acquisitionCosts,
        reason: '담보대출 원금은 자산과 부채를 동시에 늘릴 뿐 순자산을 만들지 않는다.',
      );
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
      expect(owned.propertyCondition, switch (listing.condition) {
        RealEstateListingCondition.needsRepair => 45,
        RealEstateListingCondition.average => 70,
        RealEstateListingCondition.renovated => 90,
      });
    });

    test('만료되거나 NPC가 계약한 매물 ref를 직접 호출해도 매입할 수 없다', () {
      final base = engine
          .createNewGame('만료 매물 차단', initialCash: 200000000)
          .copyWith(brokerageCash: 0, decisions: const []);
      final asset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final rawListing = realEstateListingsFor(
        asset,
        base.simulationSeed,
      ).first;
      DateTime? inactiveDate;
      for (var offset = 0; offset < 240; offset += 1) {
        final candidate = DateTime(2010, 1, 1).add(Duration(days: offset));
        if (realEstateListingByRefAt(
              RealEstateListingRef(
                assetId: asset.id,
                listingIndex: rawListing.index,
              ),
              base.simulationSeed,
              candidate,
            ) ==
            null) {
          inactiveDate = candidate;
          break;
        }
      }
      expect(inactiveDate, isNotNull);
      final state = base.copyWith(day: dayFor(base, inactiveDate!));

      final result = engine.purchaseSpendingOption(state, rawListing.optionId);

      expect(result.success, isFalse);
      expect(result.message, contains('만료'));
      expect(result.state.personalFinance.realEstate, isEmpty);
    });

    test('현금만 많고 반복소득이 없으면 담보대출 DSR 심사를 통과하지 못한다', () {
      final base = engine
          .createNewGame(
            '현금 소득 오인 방지',
            initialCash: 200000000,
            worldSeed: seedWithActiveListing(
              realEstateMarketAssetById('uijeongbu_station_officetel_20')!,
              DateTime(2010, 6, 15),
              'mortgage-no-income',
            ),
          )
          .copyWith(brokerageCash: 0, decisions: const []);
      final state = base.copyWith(day: dayFor(base, DateTime(2010, 6, 15)));
      final asset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final listing = realEstateActiveListingsAt(
        asset,
        state.simulationSeed,
        state.currentDate,
      ).first;
      final terms = realEstateFinancingTermsAt(state.currentDate, asset.type);

      final result = engine.purchaseSpendingOption(
        state,
        realEstateFinancedOptionId(listing.optionId, terms.maxLtvPercent),
      );

      expect(gameQualifyingRecurringMonthlyIncome(state), 0);
      expect(result.success, isFalse);
      expect(result.message, contains('DSR'));
    });

    test('매입 30일 이후 첫 정산일부터 원리금이 납부된다', () {
      final base = engine
          .createNewGame(
            '대출 상환 테스트',
            initialCash: 200000000,
            worldSeed: seedWithActiveListing(
              realEstateMarketAssetById('uijeongbu_station_officetel_20')!,
              DateTime(2010, 12, 31),
              'mortgage-schedule',
            ),
          )
          .copyWith(brokerageCash: 0, decisions: const []);
      final december = withRecurringIncome(
        base,
      ).copyWith(day: dayFor(base, DateTime(2010, 12, 31)));
      final asset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final listing = realEstateActiveListingsAt(
        asset,
        december.simulationSeed,
        december.currentDate,
      ).first;
      final terms = realEstateFinancingTermsAt(
        december.currentDate,
        asset.type,
      );
      final purchase = engine.purchaseSpendingOption(
        december,
        realEstateFinancedOptionId(listing.optionId, terms.maxLtvPercent),
      );
      expect(purchase.success, isTrue, reason: purchase.message);
      final before = purchase.state.personalFinance.realEstate.single;

      final january = engine.advanceOneDay(purchase.state);
      final januaryAsset = january.personalFinance.realEstate.single;
      expect(januaryAsset.mortgageBalance, before.mortgageBalance);
      expect(januaryAsset.mortgagePaymentsMade, 0);

      final januaryEnd = january.copyWith(
        day: dayFor(january, DateTime(2011, 1, 31)),
      );
      final february = engine.advanceOneDay(januaryEnd);
      final after = february.personalFinance.realEstate.single;

      expect(after.mortgageBalance, lessThan(before.mortgageBalance));
      expect(after.mortgagePaymentsMade, 1);
      expect(after.mortgageMissedPayments, 0);
      expect(
        february.ledger.any(
          (entry) => entry.counterAccount == 'mortgage_payment',
        ),
        isTrue,
      );
    });

    test('대출 부동산 매각은 잔액을 상환하고 순수 자기자본만 지급한다', () {
      final base = engine
          .createNewGame(
            '대출 매각 테스트',
            initialCash: 200000000,
            worldSeed: seedWithActiveListing(
              realEstateMarketAssetById('uijeongbu_station_officetel_20')!,
              DateTime(2010, 6, 15),
              'mortgage-sale',
            ),
          )
          .copyWith(brokerageCash: 0, decisions: const []);
      final state = withRecurringIncome(
        base,
      ).copyWith(day: dayFor(base, DateTime(2010, 6, 15)));
      final marketAsset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final listing = realEstateActiveListingsAt(
        marketAsset,
        state.simulationSeed,
        state.currentDate,
      ).first;
      final terms = realEstateFinancingTermsAt(
        state.currentDate,
        marketAsset.type,
      );
      final purchase = engine.purchaseSpendingOption(
        state,
        realEstateFinancedOptionId(listing.optionId, terms.maxLtvPercent),
      );
      expect(purchase.success, isTrue, reason: purchase.message);
      final owned = purchase.state.personalFinance.realEstate.single;
      final eligible = purchase.state.copyWith(day: owned.acquiredDay + 30);

      final listingResult = engine.sellRealEstate(eligible, owned.id);
      final listed = listingResult.state.personalFinance.realEstate.single;
      final offerState = listingResult.state.copyWith(
        day: listed.saleOfferReadyDay,
      );
      final gross = listed.estimatedSaleOfferValue(offerState.day);
      final tax = realEstateCapitalGainsTax(
        saleDate: offerState.currentDate,
        type: listed.assetType,
        ownedHousingCount: offerState.personalFinance.ownedHousingCount,
        holdingDays: offerState.day - listed.acquiredDay,
        netSaleBeforeTax: gross,
        purchaseCost: listed.purchasePrice,
      );
      final expectedNet = gross - listed.mortgageBalance - tax;
      final sale = engine.sellRealEstate(offerState, listed.id);

      expect(listingResult.success, isTrue);
      expect(listingResult.cashDelta, 0);
      expect(listed.saleListedDay, eligible.day);
      expect(sale.success, isTrue);
      expect(sale.cashDelta, expectedNet);
      expect(sale.state.cash, offerState.cash + expectedNet);
      expect(sale.state.personalFinance.realEstate, isEmpty);
      expect(
        sale.state.ledger.any((entry) => entry.account == 'mortgage_payable'),
        isTrue,
      );
    });

    test('DSR 45%를 넘는 담보대출은 거절한다', () {
      final quote = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!.quoteAt(DateTime(2015));
      final terms = realEstateFinancingTermsAt(
        DateTime(2015),
        RealEstateAssetType.officetel,
      );
      final plan = terms.planFor(quote, terms.maxLtvPercent);

      final assessment = assessRealEstateBorrowing(
        plan: plan,
        existingMortgageBalance: 0,
        existingMonthlyDebtService: 440000,
        existingPropertyValue: 0,
        targetPropertyValue: quote.marketPrice,
        existingPropertyCount: 0,
        qualifyingMonthlyIncome: 1000000,
      );

      expect(assessment.approved, isFalse);
      expect(assessment.dsr, greaterThan(realEstateMaximumDsrRate));
      expect(assessment.reason, contains('DSR'));
    });

    test('추가 매입은 보증금을 포함한 총부채 60% 한도를 적용한다', () {
      const plan = RealEstateFinancingPlan(
        requestedLtvPercent: 20,
        appliedLtvPercent: 20,
        principal: 100000000,
        cashRequired: 400000000,
        annualInterestRate: 0.04,
        termMonths: 240,
        monthlyPayment: 600000,
      );

      final assessment = assessRealEstateBorrowing(
        plan: plan,
        existingMortgageBalance: 300000000,
        existingNonMortgageDebt: 250000000,
        existingMonthlyDebtService: 1000000,
        existingPropertyValue: 500000000,
        targetPropertyValue: 500000000,
        existingPropertyCount: 1,
        qualifyingMonthlyIncome: 10000000,
      );

      expect(assessment.approved, isFalse);
      expect(assessment.maximumPortfolioDebt, 600000000);
      expect(assessment.reason, contains('총부채'));
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

    test('강제매각에서도 세입자 보증금은 사라지지 않고 반환채무로 남는다', () {
      final base = engine
          .createNewGame('세입자 있는 담보권 실행')
          .copyWith(cash: 0, brokerageCash: 0, decisions: const []);
      final priorDay = DateTime(2012, 1, 31);
      const deposit = 20000000;
      final mortgagedLease = OwnedRealEstate(
        id: 'leased-foreclosure',
        optionId: 'leased-foreclosure',
        name: '세입자 있는 연체 매물',
        purchasePrice: 20000000,
        acquiredDay: 1,
        monthlyIncome: 0,
        monthlyCost: 0,
        purchaseDateIso: '2010-01-01T00:00:00.000',
        mortgageOriginalPrincipal: 100000000,
        mortgageBalance: 100000000,
        mortgageAnnualInterestRate: 0.12,
        mortgageTermMonths: 120,
        mortgageMissedPayments: 2,
        leaseType: RealEstateLeaseType.jeonse,
        leaseDeposit: deposit,
        leaseRemainingMonths: 12,
        tenantReliability: 80,
      );
      final state = base.copyWith(
        day: dayFor(base, priorDay),
        personalFinance: base.personalFinance.copyWith(
          realEstate: [mortgagedLease],
        ),
      );

      final next = engine.advanceOneDay(state);

      expect(next.personalFinance.realEstate, isEmpty);
      expect(next.story.flagInt('mortgageForeclosureCount'), 1);
      expect(next.story.flagInt('tenantDepositDebt'), deposit);
      expect(
        next.ledger.any(
          (entry) =>
              entry.account == 'tenant_deposit_debt' &&
              entry.notional == deposit,
        ),
        isTrue,
      );
      expect(
        next.ledger
            .where(
              (entry) => entry.counterAccount == 'mortgage_foreclosure_sale',
            )
            .first
            .notional,
        lessThan(mortgagedLease.estimatedMarketValue(next.day)),
        reason: '강제매각 가격에는 급매 할인이 적용되어야 한다.',
      );
    });

    test('신용점수 미달·연체·강제매각 이력은 담보대출 심사에서 거절된다', () {
      const plan = RealEstateFinancingPlan(
        requestedLtvPercent: 40,
        appliedLtvPercent: 40,
        principal: 40000000,
        cashRequired: 60000000,
        annualInterestRate: 0.04,
        termMonths: 240,
        monthlyPayment: 250000,
      );

      RealEstateBorrowingAssessment assess({
        int creditScore = 850,
        bool hasDelinquency = false,
        bool hasForeclosureHistory = false,
      }) => assessRealEstateBorrowing(
        plan: plan,
        existingMortgageBalance: 0,
        existingMonthlyDebtService: 0,
        existingPropertyValue: 0,
        targetPropertyValue: 100000000,
        existingPropertyCount: 0,
        qualifyingMonthlyIncome: 5000000,
        creditScore: creditScore,
        hasDelinquency: hasDelinquency,
        hasForeclosureHistory: hasForeclosureHistory,
      );

      expect(assess(creditScore: 599).approved, isFalse);
      expect(assess(hasDelinquency: true).approved, isFalse);
      expect(
        assess(creditScore: 699, hasForeclosureHistory: true).approved,
        isFalse,
      );
      expect(
        assess(creditScore: 700, hasForeclosureHistory: true).approved,
        isTrue,
      );
    });

    test('중도상환과 고정·변동 대환은 잔액·수수료·금리형태를 저장한다', () {
      final base = withRecurringIncome(
        engine.createNewGame('담보대출 관리', initialCash: 200000000),
      ).copyWith(brokerageCash: 0, decisions: const []);
      final state = base.copyWith(
        day: dayFor(base, DateTime(2015, 6, 15)),
        personalFinance: base.personalFinance.copyWith(
          realEstate: const [
            OwnedRealEstate(
              id: 'mortgage-management',
              optionId: 'mortgage-management',
              name: '담보대출 관리 매물',
              purchasePrice: 100000000,
              acquiredDay: 1,
              monthlyIncome: 1000000,
              monthlyCost: 100000,
              mortgageOriginalPrincipal: 40000000,
              mortgageBalance: 40000000,
              mortgageAnnualInterestRate: 0.05,
              mortgageTermMonths: 240,
            ),
          ],
        ),
      );

      final prepaid = engine.prepayRealEstateMortgage(
        state,
        'mortgage-management',
        10000000,
      );
      expect(prepaid.success, isTrue);
      expect(
        prepaid.state.personalFinance.realEstate.single.mortgageBalance,
        30000000,
      );
      expect(
        prepaid.cashDelta,
        -(10000000 + (10000000 * realEstateMortgagePrepaymentFeeRate).round()),
      );

      final refinanced = engine.refinanceRealEstateMortgage(
        prepaid.state,
        'mortgage-management',
        variableRate: true,
        termMonths: 180,
      );
      expect(refinanced.success, isTrue);
      final asset = refinanced.state.personalFinance.realEstate.single;
      expect(asset.mortgageIsVariableRate, isTrue);
      expect(asset.mortgageTermMonths, 180);
      expect(
        asset.mortgageAnnualInterestRate,
        lessThan(
          realEstateFinancingTermsAt(
            refinanced.state.currentDate,
            asset.assetType,
          ).annualInterestRate,
        ),
      );
    });

    test('매수자 제안은 고정·만료되고 취소 후 재등록할 수 있다', () {
      final base = engine
          .createNewGame(
            '매각 제안 수명',
            initialCash: 200000000,
            worldSeed: seedWithActiveListing(
              realEstateMarketAssetById('uijeongbu_station_officetel_20')!,
              DateTime(2010, 6, 15),
              'sale-offer',
            ),
          )
          .copyWith(brokerageCash: 0, decisions: const []);
      final state = base.copyWith(day: dayFor(base, DateTime(2010, 6, 15)));
      final listing = realEstateActiveListingsAt(
        realEstateMarketAssetById('uijeongbu_station_officetel_20')!,
        state.simulationSeed,
        state.currentDate,
      ).first;
      final purchase = engine.purchaseSpendingOption(state, listing.optionId);
      final owned = purchase.state.personalFinance.realEstate.single;
      final eligible = purchase.state.copyWith(day: owned.acquiredDay + 30);

      final listedResult = engine.sellRealEstate(eligible, owned.id);
      final listed = listedResult.state.personalFinance.realEstate.single;
      expect(listed.saleOfferAmount, greaterThan(0));
      expect(
        listed.estimatedSaleOfferValue(listed.saleOfferExpiresDay),
        listed.saleOfferAmount,
      );

      final expired = engine.sellRealEstate(
        listedResult.state.copyWith(day: listed.saleOfferExpiresDay + 1),
        owned.id,
      );
      expect(expired.state.personalFinance.realEstate.single.saleListedDay, 0);

      final relisted = engine.sellRealEstate(expired.state, owned.id);
      final cancelled = engine.cancelRealEstateSaleListing(
        relisted.state,
        owned.id,
      );
      expect(cancelled.success, isTrue);
      expect(
        cancelled.state.personalFinance.realEstate.single.saleOfferAmount,
        0,
      );
    });

    test('투자 메모는 공백을 정리하고 길이를 제한해 JSON에 보존한다', () {
      final initial = engine.createNewGame('부동산 메모');
      final base = initial.copyWith(
        personalFinance: initial.personalFinance.copyWith(
          realEstate: const [
            OwnedRealEstate(
              id: 'memo-asset',
              optionId: 'memo-asset',
              name: '메모 매물',
              purchasePrice: 10000000,
              acquiredDay: 1,
              monthlyIncome: 0,
              monthlyCost: 0,
            ),
          ],
        ),
      );
      final note =
          '  ${List.filled(gameRealEstateInvestmentNoteMaxLength + 20, '가').join()}  ';

      final result = engine.saveRealEstateInvestmentNote(
        base,
        'memo-asset',
        note,
      );

      final saved = result.state.personalFinance.realEstate.single;
      expect(
        saved.investmentNote.length,
        gameRealEstateInvestmentNoteMaxLength,
      );
      expect(
        OwnedRealEstate.fromJson(saved.toJson()).investmentNote,
        saved.investmentNote,
      );
      final legacyJson = Map<String, dynamic>.from(saved.toJson())
        ..['acquiredDay'] = 100
        ..remove('nextMortgagePaymentDay')
        ..remove('nextRentalSettlementDay')
        ..remove('realEstateWorldVersion');
      final migrated = OwnedRealEstate.fromJson(legacyJson);
      expect(migrated.nextMortgagePaymentDay, 130);
      expect(migrated.nextRentalSettlementDay, 130);
      expect(migrated.realEstateWorldVersion, 1);
    });
  });
}
