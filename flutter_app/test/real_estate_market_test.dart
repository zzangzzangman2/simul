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
  });
}
