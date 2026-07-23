import 'package:millennium_capital/game/market_data.dart';

FictionalMarketUniverse testMarketUniverse() => FictionalMarketUniverse(
  schemaVersion: 1,
  sourceName: 'widget-test',
  assets: [
    FictionalMarketAsset(
      id: 'hanbit_telecom',
      symbol: '1001',
      name: '한빛통신',
      market: fictionalMainMarket,
      country: 'KR',
      sector: '반도체',
      colorHex: '#2F7DF4',
      currency: 'KRW',
      prices: const {
        '1999-12-30': 5920,
        '2000-01-03': 6040,
        '2000-01-04': 6110,
      },
      financials: const [
        FictionalFinancialSnapshot(
          period: '1999-12-30',
          revenue: 1200000000,
          operatingProfit: 150000000,
          consensusOperatingProfit: 140000000,
          netIncome: 110000000,
          operatingCashFlow: 165000000,
          cash: 800000000,
          debt: 350000000,
          equity: 1200000000,
          sharesOutstanding: 1000000,
          orderBacklog: 920000000,
        ),
      ],
      relations: const [
        FictionalCompanyRelation(
          relatedAssetId: 'widget_partner',
          relatedName: '테스트 부품',
          type: FictionalCompanyRelationType.supplier,
          strength: 0.35,
        ),
      ],
    ),
  ],
);
