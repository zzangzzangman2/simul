import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_clock.dart';

FictionalMarketUniverse testMarketUniverse({
  DateTime? tradingDate,
  bool includeKnownPartner = false,
}) {
  final prices = tradingDate == null
      ? const <String, double>{
          '1999-12-30': 5920,
          '2000-01-03': 5920,
          '2000-01-04': 6040,
          '2000-01-05': 6110,
        }
      : <String, double>{
          marketDateKey(_previousTradingDay(tradingDate)): 6040,
          marketDateKey(tradingDate): 6110,
        };
  return FictionalMarketUniverse(
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
        initialSharesOutstanding: 1000000,
        products: const ['광대역망', '휴대통신', '통신 칩'],
        prices: prices,
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
      if (includeKnownPartner)
        FictionalMarketAsset(
          id: 'widget_partner',
          symbol: '1002',
          name: '테스트 부품',
          market: fictionalMainMarket,
          country: 'KR',
          sector: '전자부품',
          colorHex: '#7B61FF',
          currency: 'KRW',
          initialSharesOutstanding: 500000,
          prices: prices,
        ),
    ],
  );
}

DateTime _previousTradingDay(DateTime date) {
  var candidate = date.subtract(const Duration(days: 1));
  while (!isMarketTradingDay(candidate)) {
    candidate = candidate.subtract(const Duration(days: 1));
  }
  return candidate;
}
