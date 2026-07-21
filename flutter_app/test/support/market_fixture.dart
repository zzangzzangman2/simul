import 'package:millennium_capital/game/market_data.dart';

HistoricalMarketUniverse testMarketUniverse() => HistoricalMarketUniverse(
  schemaVersion: 1,
  sourceName: 'widget-test',
  assets: [
    HistoricalMarketAsset(
      id: 'kr-005930',
      symbol: '005930.KS',
      name: '삼성전자',
      market: 'KOSPI',
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
