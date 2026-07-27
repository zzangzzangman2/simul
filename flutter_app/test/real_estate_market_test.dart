import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/real_estate_market.dart';

void main() {
  group('서울·경기 부동산 시장', () {
    test('수천만원대 오피스텔부터 6단계까지 모두 존재한다', () {
      final starters = realEstateMarketCatalog
          .where((asset) => asset.tier == RealEstateInvestmentTier.starter)
          .toList(growable: false);

      expect(starters.length, greaterThanOrEqualTo(3));
      expect(
        starters
            .map((asset) => asset.priceAt(DateTime(2000)))
            .reduce((a, b) => a < b ? a : b),
        lessThan(30000000),
      );
      for (final tier in RealEstateInvestmentTier.values) {
        expect(
          realEstateMarketCatalog.any((asset) => asset.tier == tier),
          isTrue,
          reason: '${tier.name} 단계에 자산이 있어야 한다.',
        );
      }
    });

    test('현재 날짜 카탈로그는 아직 등장하지 않은 자산을 노출하지 않는다', () {
      final in2000 = realEstateMarketCatalogAt(DateTime(2000, 1, 2));

      expect(
        in2000.every(
          (asset) => !DateTime(2000, 1, 2).isBefore(asset.availableFrom),
        ),
        isTrue,
      );
      expect(
        in2000.any((asset) => asset.id == 'pangyo_prugio_granbleu_140'),
        isFalse,
      );
      expect(
        realEstateMarketCatalogAt(
          DateTime(2011, 7),
        ).any((asset) => asset.id == 'pangyo_prugio_granbleu_140'),
        isTrue,
      );

      final entryAsset = realEstateMarketAssetById(
        'bucheon_jungdong_officetel_18',
      )!;
      expect(entryAsset.evidenceAt(DateTime(2004)).date, DateTime(2000, 1));
      expect(
        entryAsset.evidenceAt(DateTime(2004)).sourceLabel,
        isNot(contains('2006')),
      );
      expect(entryAsset.evidenceAt(DateTime(2006)).date, DateTime(2006, 1));
    });

    test('매입 총현금에는 세금·중개·등기 비용이 더해진다', () {
      final asset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final quote = asset.quoteAt(DateTime(2000));

      expect(quote.marketPrice, 28000000);
      expect(quote.acquisitionTax, greaterThan(0));
      expect(quote.brokerageFee, greaterThan(0));
      expect(quote.bondLegalAndRegistration, greaterThan(0));
      expect(quote.totalCash, quote.marketPrice + quote.acquisitionCosts);
      expect(
        asset.monthlyRentAt(DateTime(2000)),
        greaterThan(asset.monthlyOperatingCostAt(DateTime(2000))),
      );
    });

    test('오피스텔은 상승 뒤 2026년에 조정되는 흐름도 표현한다', () {
      final asset = realEstateMarketAssetById('bucheon_jungdong_officetel_18')!;

      expect(
        asset.priceAt(DateTime(2021)),
        greaterThan(asset.priceAt(DateTime(2000))),
      );
      expect(
        asset.priceAt(DateTime(2026, 6)),
        lessThan(asset.priceAt(DateTime(2021))),
      );
      expect(
        asset.evidenceAt(DateTime(2000)).evidence,
        RealEstatePriceEvidence.indexBackcast,
      );
      expect(
        asset.evidenceAt(DateTime(2026, 6)).evidence,
        RealEstatePriceEvidence.gameExtension,
      );
    });

    test('실제 유명 아파트의 2025 거래 기준점이 보존된다', () {
      final expected = <String, int>{
        'hannam_the_hill_243': 17500000000,
        'nineone_hannam_244': 15800000000,
        'acro_seoul_forest_160': 13500000000,
        'raemian_one_bailey_134': 9500000000,
        'pangyo_prugio_granbleu_140': 4200000000,
      };

      for (final entry in expected.entries) {
        final asset = realEstateMarketAssetById(entry.key)!;
        expect(
          asset.priceAnchors.any(
            (anchor) =>
                anchor.evidence == RealEstatePriceEvidence.actualTransaction &&
                anchor.price == entry.value,
          ),
          isTrue,
        );
        expect(asset.realNamedAsset, isTrue);
      }
    });

    test('게임 엔진 구매는 표시 매매가가 아니라 취득 총현금을 차감한다', () {
      const engine = GameEngine();
      final asset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final quote = asset.quoteAt(DateTime(2000));
      final initial = engine
          .createNewGame('부동산 테스트', initialCash: 100000000)
          .copyWith(brokerageCash: 0, decisions: const []);

      final result = engine.purchaseSpendingOption(
        initial,
        'market_uijeongbu_station_officetel_20',
      );

      expect(result.success, isTrue);
      expect(result.cashDelta, -quote.totalCash);
      expect(result.state.cash, initial.cash - quote.totalCash);
      expect(result.state.personalFinance.realEstate, hasLength(1));
      final owned = result.state.personalFinance.realEstate.single;
      expect(owned.marketAssetId, asset.id);
      expect(owned.marketPriceAtPurchase, quote.marketPrice);
      expect(owned.acquisitionCosts, quote.acquisitionCosts);
      expect(owned.purchasePrice, quote.totalCash);
      expect(result.state.ledger.last.notional, quote.marketPrice);
      expect(result.state.ledger.last.tradingFee, quote.acquisitionCosts);
    });

    test('다주택 취득세와 보유세는 보유 주택 수에 따라 누진된다', () {
      final apartment = realEstateMarketCatalog.firstWhere(
        (asset) => asset.type == RealEstateAssetType.apartment,
      );
      final date = DateTime(2021, 6, 1);
      final baseQuote = apartment.quoteAt(date);
      final secondHome = realEstatePortfolioAdjustedPurchaseQuote(
        baseQuote: baseQuote,
        date: date,
        type: apartment.type,
        ownedHousingCount: 1,
      );
      final thirdHome = realEstatePortfolioAdjustedPurchaseQuote(
        baseQuote: baseQuote,
        date: date,
        type: apartment.type,
        ownedHousingCount: 2,
      );
      final oneHomeTax = realEstateMonthlyHoldingTax(
        date: date,
        type: apartment.type,
        marketValue: baseQuote.marketPrice,
        ownedHousingCount: 1,
      );
      final threeHomeTax = realEstateMonthlyHoldingTax(
        date: date,
        type: apartment.type,
        marketValue: baseQuote.marketPrice,
        ownedHousingCount: 3,
      );

      expect(
        secondHome.acquisitionCosts,
        greaterThan(baseQuote.acquisitionCosts),
      );
      expect(
        thirdHome.acquisitionCosts,
        greaterThan(secondHome.acquisitionCosts),
      );
      expect(threeHomeTax, greaterThan(oneHomeTax));
    });

    test('단기매매와 다주택 양도차익에는 더 높은 양도세가 붙는다', () {
      final longTerm = realEstateCapitalGainsTax(
        saleDate: DateTime(2021),
        type: RealEstateAssetType.apartment,
        ownedHousingCount: 1,
        holdingDays: 800,
        netSaleBeforeTax: 700000000,
        purchaseCost: 500000000,
      );
      final shortTermMultiHome = realEstateCapitalGainsTax(
        saleDate: DateTime(2021),
        type: RealEstateAssetType.apartment,
        ownedHousingCount: 3,
        holdingDays: 180,
        netSaleBeforeTax: 700000000,
        purchaseCost: 500000000,
      );

      expect(longTerm, 30000000);
      expect(shortTermMultiHome, 120000000);
    });

    test('매각 대기일과 매수자 제안은 시드에 대해 결정론적이다', () {
      final firstWait = realEstateSaleListingDays(
        type: RealEstateAssetType.apartment,
        worldSeed: 'sale-seed',
        assetId: 'apt-1',
        listedDay: 500,
      );
      final secondWait = realEstateSaleListingDays(
        type: RealEstateAssetType.apartment,
        worldSeed: 'sale-seed',
        assetId: 'apt-1',
        listedDay: 500,
      );
      final offerRate = realEstateSaleOfferRate(
        worldSeed: 'sale-seed',
        assetId: 'apt-1',
        listedDay: 500,
      );

      expect(firstWait, secondWait);
      expect(firstWait, inInclusiveRange(14, 44));
      expect(offerRate, inInclusiveRange(0.93, 1.02));
    });

    test('임대료 지수는 매매가와 분리되고 장기 급등 때 수익률이 압축된다', () {
      final asset = realEstateMarketAssetById('hannam_the_hill_243')!;
      final start = asset.availableFrom;
      final end = DateTime(2025, 4);
      final priceGrowth = asset.priceAt(end) / asset.priceAt(start);
      final rentGrowth = asset.monthlyRentAt(end) / asset.monthlyRentAt(start);
      final startYield = asset.monthlyRentAt(start) * 12 / asset.priceAt(start);
      final endYield = asset.monthlyRentAt(end) * 12 / asset.priceAt(end);

      expect(realEstateRentIndexAt(end, asset.type), greaterThan(1));
      expect(rentGrowth, greaterThan(1));
      expect(rentGrowth, lessThan(priceGrowth));
      expect(endYield, lessThan(startYield * 0.75));
    });

    test('상업 임대료 지수는 금융위기 공실 사이클에서 하락할 수 있다', () {
      final before = realEstateRentIndexAt(
        DateTime(2008, 1),
        RealEstateAssetType.officeBuilding,
      );
      final after = realEstateRentIndexAt(
        DateTime(2010, 1),
        RealEstateAssetType.officeBuilding,
      );

      expect(after, lessThan(before));
    });
  });
}
