import 'game_state.dart';
import 'market_clock.dart';
import 'market_data.dart';
import 'market_tick.dart';

List<MarketTimedImpact> marketTimedImpactsForAsset({
  required String simulationSeed,
  required DateTime date,
  required FictionalMarketAsset asset,
}) {
  final events = fictionalMarketEventsForDate(simulationSeed, date);
  final impacts = <MarketTimedImpact>[];
  for (final event in events) {
    var impact = 0.0;
    if (event.companyId == fictionalWholeMarketCompanyId) {
      impact += event.impactPct;
      impact += event.sectorImpactPcts[asset.sector] ?? 0;
    } else if (event.companyId == asset.id) {
      impact += event.impactPct;
    } else if (event.sector == asset.sector) {
      impact += event.impactPct * 0.12;
    }
    for (final relation in asset.relations) {
      if (relation.relatedAssetId != event.companyId) continue;
      final factor = relation.type == FictionalCompanyRelationType.competitor
          ? -relation.strength * 0.55
          : relation.type == FictionalCompanyRelationType.parent ||
                relation.type == FictionalCompanyRelationType.subsidiary
          ? relation.strength * 0.7
          : relation.strength * 0.42;
      impact += event.impactPct * factor;
    }
    if (impact.abs() >= 0.0000001) {
      impacts.add(
        MarketTimedImpact(revealMinute: event.revealMinute, impactRate: impact),
      );
    }
  }
  return List.unmodifiable(impacts);
}

List<double> generatedMarketDayPathForAsset({
  required FictionalMarketAsset asset,
  required String simulationSeed,
  required DateTime date,
  required double previousClose,
  required double officialClose,
}) => generatedFullMarketDayPath(
  previousClose: previousClose,
  officialClose: officialClose,
  seed: marketStockSeed('$simulationSeed:${asset.code}', date),
  dailyLimitRate: marketDailyPriceLimitRate(date),
  timedImpacts: marketTimedImpactsForAsset(
    simulationSeed: simulationSeed,
    date: date,
    asset: asset,
  ),
);

class MarketTradeQuote {
  const MarketTradeQuote({
    required this.asset,
    required this.quoteDate,
    required this.unitPrice,
    required this.marketMinute,
    required this.isTradingDay,
  });

  final FictionalMarketAsset asset;
  final String quoteDate;
  final double unitPrice;
  final int marketMinute;
  final bool isTradingDay;
}

MarketTradeQuote? resolveMarketTradeQuote(
  FictionalMarketUniverse universe,
  GameState state,
  String assetId,
) {
  FictionalMarketAsset? asset;
  for (final candidate in universe.assets) {
    if (candidate.id == assetId) {
      asset = candidate;
      break;
    }
  }
  if (asset == null) return null;
  final quote = asset.quoteAtOrBefore(state.currentDate);
  if (quote == null) return null;
  final previousClose = asset.previousCloseBefore(quote.date) ?? quote.close;
  final isTradingDay = quote.isExactDate;
  final unitPrice = isTradingDay
      ? generatedMarketDayPathForAsset(
          asset: asset,
          simulationSeed: state.simulationSeed,
          date: state.currentDate,
          previousClose: previousClose,
          officialClose: quote.close,
        )[marketTickForMinute(state.marketMinute)]
      : quote.close;
  return MarketTradeQuote(
    asset: asset,
    quoteDate: state.currentDate.toIso8601String().split('T').first,
    unitPrice: unitPrice,
    marketMinute: state.marketMinute,
    isTradingDay: isTradingDay,
  );
}
