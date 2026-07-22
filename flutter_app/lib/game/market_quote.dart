import 'game_state.dart';
import 'market_clock.dart';
import 'market_data.dart';
import 'market_tick.dart';

class HistoricalTradeQuote {
  const HistoricalTradeQuote({
    required this.asset,
    required this.quoteDate,
    required this.unitPrice,
    required this.marketMinute,
    required this.isTradingDay,
  });

  final HistoricalMarketAsset asset;
  final String quoteDate;
  final double unitPrice;
  final int marketMinute;
  final bool isTradingDay;
}

HistoricalTradeQuote? resolveHistoricalTradeQuote(
  HistoricalMarketUniverse universe,
  GameState state,
  String assetId,
) {
  HistoricalMarketAsset? asset;
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
      ? generatedFullMarketDayPath(
          previousClose: previousClose,
          officialClose: quote.close,
          seed: marketStockSeed(asset.code, state.currentDate),
        )[marketTickForMinute(state.marketMinute)]
      : quote.close;
  return HistoricalTradeQuote(
    asset: asset,
    quoteDate: state.currentDate.toIso8601String().split('T').first,
    unitPrice: unitPrice,
    marketMinute: state.marketMinute,
    isTradingDay: isTradingDay,
  );
}
