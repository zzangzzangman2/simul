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
    ),
  ],
);
