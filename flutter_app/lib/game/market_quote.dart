import 'dart:math' as math;

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'game_state.dart';
import 'market_clock.dart';
import 'market_data.dart';
import 'market_liquidity_zones.dart';
import 'market_technical_levels.dart';
import 'order_book.dart';
import 'market_tick.dart';

class MarketDatedCandle {
  const MarketDatedCandle({required this.date, required this.candle});

  final String date;
  final MarketCandle candle;
}

enum MarketCandlePeriod { day, week, month, year }

/// Aggregates chronological daily candles without losing intraday extremes.
///
/// A period opens at its first daily open, closes at its last daily close,
/// keeps the highest/lowest daily extremes, and sums daily volume.
List<MarketDatedCandle> aggregateMarketDatedCandles(
  List<MarketDatedCandle> dailyCandles, {
  required MarketCandlePeriod period,
  int? maxBuckets,
}) {
  if (dailyCandles.isEmpty || (maxBuckets != null && maxBuckets <= 0)) {
    return const <MarketDatedCandle>[];
  }
  final buckets = <String, List<MarketDatedCandle>>{};
  for (final item in dailyCandles) {
    final date = DateTime.tryParse(item.date);
    if (date == null) continue;
    final key = switch (period) {
      MarketCandlePeriod.day => marketDateKey(date),
      MarketCandlePeriod.week => marketDateKey(
        date.subtract(Duration(days: date.weekday - DateTime.monday)),
      ),
      MarketCandlePeriod.month =>
        '${date.year}-${date.month.toString().padLeft(2, '0')}',
      MarketCandlePeriod.year => '${date.year}',
    };
    buckets.putIfAbsent(key, () => <MarketDatedCandle>[]).add(item);
  }
  final entries = buckets.entries.toList(growable: false);
  final visible = maxBuckets != null && entries.length > maxBuckets
      ? entries.sublist(entries.length - maxBuckets)
      : entries;
  return List<MarketDatedCandle>.unmodifiable([
    for (var index = 0; index < visible.length; index += 1)
      MarketDatedCandle(
        date: visible[index].value.first.date,
        candle: MarketCandle(
          open: visible[index].value.first.candle.open,
          high: visible[index].value.fold<double>(
            visible[index].value.first.candle.high,
            (high, item) => math.max(high, item.candle.high),
          ),
          low: visible[index].value.fold<double>(
            visible[index].value.first.candle.low,
            (low, item) => math.min(low, item.candle.low),
          ),
          close: visible[index].value.last.candle.close,
          startMinute: index,
          volume: visible[index].value.fold<double>(
            0,
            (volume, item) => volume + item.candle.volume,
          ),
        ),
      ),
  ]);
}

final Map<String, List<MarketDatedCandle>> _dailyCandleCache =
    <String, List<MarketDatedCandle>>{};

@visibleForTesting
int marketDailyCandlePathGenerationCount = 0;

@visibleForTesting
void resetMarketDailyCandleCacheForTesting() {
  _dailyCandleCache.clear();
  marketDailyCandlePathGenerationCount = 0;
}

List<MarketDatedCandle> recentMarketDailyCandles({
  required FictionalMarketAsset asset,
  required String simulationSeed,
  required DateTime throughDate,
  int count = 120,
  int? visibleThroughMinute,
}) {
  if (count <= 0) return const <MarketDatedCandle>[];
  final cacheKey = '$simulationSeed|${asset.id}|${marketDateKey(throughDate)}';
  final history = asset.historyThrough(throughDate, count: count);
  if (history.isEmpty) return const <MarketDatedCandle>[];
  final cached = _dailyCandleCache.remove(cacheKey);
  List<MarketDatedCandle> result;
  List<MarketDatedCandle> cacheValue;
  if (cached != null && _dailyCandleCacheMatchesHistory(cached, history)) {
    if (cached.length == history.length) {
      result = cached;
      cacheValue = cached;
    } else if (cached.length > history.length) {
      result = _reindexDailyCandles(
        cached.sublist(cached.length - history.length),
      );
      cacheValue = cached;
    } else {
      final missingCount = history.length - cached.length;
      result = List<MarketDatedCandle>.unmodifiable([
        for (var index = 0; index < missingCount; index += 1)
          _generateDailyCandle(
            asset: asset,
            simulationSeed: simulationSeed,
            point: history[index],
            index: index,
          ),
        ..._reindexDailyCandles(cached, startIndex: missingCount),
      ]);
      cacheValue = result;
    }
  } else {
    result = List<MarketDatedCandle>.unmodifiable([
      for (var index = 0; index < history.length; index += 1)
        _generateDailyCandle(
          asset: asset,
          simulationSeed: simulationSeed,
          point: history[index],
          index: index,
        ),
    ]);
    cacheValue = result;
  }

  _dailyCandleCache[cacheKey] = cacheValue;
  while (_dailyCandleCache.length > 32) {
    _dailyCandleCache.remove(_dailyCandleCache.keys.first);
  }
  return _dailyCandlesVisibleThroughMinute(
    result,
    asset: asset,
    simulationSeed: simulationSeed,
    throughDate: throughDate,
    visibleThroughMinute: visibleThroughMinute,
  );
}

bool _dailyCandleCacheMatchesHistory(
  List<MarketDatedCandle> cached,
  List<MarketPoint> history,
) {
  final overlap = math.min(cached.length, history.length);
  for (var index = 0; index < overlap; index += 1) {
    if (cached[cached.length - overlap + index].date !=
        history[history.length - overlap + index].date) {
      return false;
    }
  }
  return true;
}

List<MarketDatedCandle> _reindexDailyCandles(
  List<MarketDatedCandle> candles, {
  int startIndex = 0,
}) => List<MarketDatedCandle>.unmodifiable([
  for (var index = 0; index < candles.length; index += 1)
    MarketDatedCandle(
      date: candles[index].date,
      candle: MarketCandle(
        open: candles[index].candle.open,
        high: candles[index].candle.high,
        low: candles[index].candle.low,
        close: candles[index].candle.close,
        startMinute: startIndex + index,
        volume: candles[index].candle.volume,
      ),
    ),
]);

MarketDatedCandle _generateDailyCandle({
  required FictionalMarketAsset asset,
  required String simulationSeed,
  required MarketPoint point,
  required int index,
}) {
  marketDailyCandlePathGenerationCount += 1;
  final date = point.parsedDate;
  final previousClose = asset.unadjustedReferenceCloseFor(point.date);
  final marketReferenceClose = asset.marketReferenceCloseOn(
    date,
    previousClose: previousClose,
  );
  final path = generatedMarketDayPathForAsset(
    asset: asset,
    simulationSeed: simulationSeed,
    date: date,
    previousClose: previousClose,
    officialClose: point.close,
  );
  final continuousEnd = generatedPreOpenTicks + generatedContinuousTradingTicks;
  final session = path.sublist(
    generatedPreOpenTicks,
    continuousEnd.clamp(generatedPreOpenTicks, path.length).toInt(),
  )..add(point.close);
  final marketDay = marketLiquidityDayKey(date);
  return MarketDatedCandle(
    date: point.date,
    candle: MarketCandle(
      open: session.first,
      high: session.fold<double>(session.first, math.max),
      low: session.fold<double>(session.first, math.min),
      close: point.close,
      startMinute: index,
      volume: gameEstimatedFullDayVolumeUnits(
        assetId: asset.id,
        day: marketDay,
        referencePrice: marketReferenceClose,
        simulationSeed: simulationSeed,
        sharesOutstanding: asset.sharesOutstandingAtOrBefore(date),
      ).toDouble(),
    ),
  );
}

List<MarketDatedCandle> _dailyCandlesVisibleThroughMinute(
  List<MarketDatedCandle> completeCandles, {
  required FictionalMarketAsset asset,
  required String simulationSeed,
  required DateTime throughDate,
  required int? visibleThroughMinute,
}) {
  if (visibleThroughMinute == null ||
      completeCandles.isEmpty ||
      completeCandles.last.date != marketDateKey(throughDate) ||
      visibleThroughMinute >= krxCloseMinute) {
    return completeCandles;
  }
  final historical = completeCandles.sublist(0, completeCandles.length - 1);
  if (visibleThroughMinute < krxOpenMinute) {
    return List<MarketDatedCandle>.unmodifiable(historical);
  }

  final quote = asset.quoteAtOrBefore(throughDate);
  if (quote == null || !quote.isExactDate) return completeCandles;
  final rawPreviousClose = asset.unadjustedReferenceCloseFor(quote.date);
  final marketReferenceClose = asset.marketReferenceCloseOn(
    throughDate,
    previousClose: rawPreviousClose,
  );
  final path = generatedMarketDayPathForAsset(
    asset: asset,
    simulationSeed: simulationSeed,
    date: throughDate,
    previousClose: rawPreviousClose,
    officialClose: quote.close,
  );
  final continuousEnd = generatedPreOpenTicks + generatedContinuousTradingTicks;
  final visibleEnd = math.min(
    marketTickForMinute(visibleThroughMinute) + 1,
    continuousEnd,
  );
  if (visibleEnd <= generatedPreOpenTicks || visibleEnd > path.length) {
    return List<MarketDatedCandle>.unmodifiable(historical);
  }
  final session = path.sublist(generatedPreOpenTicks, visibleEnd);
  final high = session.fold<double>(session.first, math.max);
  final low = session.fold<double>(session.first, math.min);
  final marketDay = marketLiquidityDayKey(throughDate);
  final fullDayVolume = gameEstimatedFullDayVolumeUnits(
    assetId: asset.id,
    day: marketDay,
    referencePrice: marketReferenceClose,
    simulationSeed: simulationSeed,
    sharesOutstanding: asset.sharesOutstandingAtOrBefore(throughDate),
  );
  final completedFraction = gameTurnoverProgressAtMinute(visibleThroughMinute);
  final volume = fullDayVolume * completedFraction.clamp(0.0, 1.0);
  return List<MarketDatedCandle>.unmodifiable([
    ...historical,
    MarketDatedCandle(
      date: quote.date,
      candle: MarketCandle(
        open: session.first,
        high: high,
        low: low,
        close: session.last,
        startMinute: completeCandles.last.candle.startMinute,
        volume: volume,
      ),
    ),
  ]);
}

List<MarketTimedImpact> marketTimedImpactsForAsset({
  required String simulationSeed,
  required DateTime date,
  required FictionalMarketAsset asset,
}) {
  final events = fictionalMarketEventsForDate(simulationSeed, date);
  final appliedEventScale = asset.appliedEventScaleOn(date);
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
    impact *= appliedEventScale;
    if (impact.abs() >= 0.0000001) {
      impacts.add(
        MarketTimedImpact(revealMinute: event.revealMinute, impactRate: impact),
      );
    }
  }
  return List.unmodifiable(impacts);
}

/// Causal 5-, 20-, and 60-week moving-average levels for [sessionDate].
///
/// Today's generated official close is excluded by the technical-level
/// builder. Corporate actions effective on or before the session are applied
/// backwards so historical closes share the current ex-date price axis.
List<MarketTechnicalLevel> marketTechnicalLevelsForAsset({
  required FictionalMarketAsset asset,
  required DateTime sessionDate,
  required double referencePrice,
}) {
  final sessionKey = marketDateKey(sessionDate);
  final history = asset.historyThrough(sessionDate, count: 420);
  if (history.isEmpty) return const <MarketTechnicalLevel>[];
  final relevantActions =
      asset.corporateActions
          .where((action) => action.date.compareTo(sessionKey) <= 0)
          .toList(growable: false)
        ..sort((left, right) {
          final dateOrder = left.date.compareTo(right.date);
          if (dateOrder != 0) return dateOrder;
          final typeOrder = marketCorporateActionOrder(
            left.type,
          ).compareTo(marketCorporateActionOrder(right.type));
          if (typeOrder != 0) return typeOrder;
          return left.id.compareTo(right.id);
        });
  final adjusted = <MarketTechnicalClose>[];
  for (final point in history) {
    var close = point.close;
    for (final action in relevantActions) {
      if (point.date.compareTo(action.date) >= 0) continue;
      final factor = switch (action.type) {
        MarketCorporateActionType.split =>
          action.unitFactor.isFinite && action.unitFactor > 0
              ? 1 / action.unitFactor
              : 1.0,
        MarketCorporateActionType.rightsIssue =>
          action.theoreticalExRightsFactor ?? 1.0,
        MarketCorporateActionType.spinoff =>
          action.theoreticalExSpinoffFactor ?? 1.0,
        MarketCorporateActionType.dividend ||
        MarketCorporateActionType.materialSpinoff ||
        MarketCorporateActionType.merger ||
        MarketCorporateActionType.shareExchange ||
        MarketCorporateActionType.tenderOffer ||
        MarketCorporateActionType.delisting => 1.0,
      };
      if (factor.isFinite && factor > 0) close *= factor;
    }
    adjusted.add(MarketTechnicalClose(date: point.date, close: close));
  }
  return buildMarketTechnicalLevels(
    adjustedDailyCloses: adjusted,
    sessionDate: sessionKey,
    referencePrice: referencePrice,
    market: asset.market,
  );
}

List<double> generatedMarketDayPathForAsset({
  required FictionalMarketAsset asset,
  required String simulationSeed,
  required DateTime date,
  // 기업행동 조정 전 실제 직전 종가. 함수 안에서 당일 거래소 기준가로
  // 정확히 한 번 변환하므로 이미 조정한 값을 넘기면 안 된다.
  required double previousClose,
  required double officialClose,
}) {
  final marketReferenceClose = asset.marketReferenceCloseOn(
    date,
    previousClose: previousClose,
  );
  final isIpoFirstTradingDay = asset.isIpoFirstTradingDay(date);
  final priceRange = marketDailyPriceRange(
    previousClose: marketReferenceClose,
    date: date,
    market: asset.market,
    isIpoFirstTradingDay: isIpoFirstTradingDay,
  );
  final technicalLevels = marketTechnicalLevelsForAsset(
    asset: asset,
    sessionDate: date,
    referencePrice: marketReferenceClose,
  );
  final structuralLiquidity = buildMarketStructuralLiquidityMap(
    worldSeed: simulationSeed,
    assetId: asset.id,
    market: asset.market,
    referencePrice: marketReferenceClose,
    lowerPrice: priceRange.lower,
    upperPrice: priceRange.upper,
    technicalLevels: technicalLevels,
  );
  return generatedFullMarketDayPath(
    previousClose: marketReferenceClose,
    officialClose: officialClose,
    seed: marketStockSeed('$simulationSeed:${asset.code}', date),
    dailyLimitRate: marketDailyPriceLimitRate(date),
    market: asset.market,
    timedImpacts: marketTimedImpactsForAsset(
      simulationSeed: simulationSeed,
      date: date,
      asset: asset,
    ),
    structuralLiquidity: structuralLiquidity,
    lowerPriceLimit: priceRange.lower,
    upperPriceLimit: priceRange.upper,
    useIpoOpeningDiscovery: marketUsesModernIpoFirstDayPriceRange(
      date: date,
      isIpoFirstTradingDay: isIpoFirstTradingDay,
    ),
  );
}

/// Applies the player's real fills to the same deterministic path used by UI,
/// pending-order replay, and headless simulations.
List<double> marketSessionPathWithPlayerImpact({
  required GameState state,
  required FictionalMarketAsset asset,
  required List<double> sourcePath,
  required double previousClose,
  Iterable<LedgerEntry>? entries,
}) {
  if (sourcePath.isEmpty || previousClose <= 0) {
    return List<double>.from(sourcePath);
  }
  final impacted = List<double>.from(sourcePath);
  final range = marketDailyPriceRange(
    previousClose: previousClose,
    date: state.currentDate,
    market: asset.market,
    isIpoFirstTradingDay: asset.isIpoFirstTradingDay(state.currentDate),
  );
  final sharesOutstanding = asset.sharesOutstandingAtOrBefore(
    state.currentDate,
  );
  final playerOwnedUnits = state.positions
      .where((position) => position.assetId == asset.id)
      .fold<double>(0, (sum, position) => sum + position.units);
  final tenderAcquiredUnits =
      state.shareholderGovernance.companyById(asset.id)?.tenderAcquiredShares ??
      0;
  final inventory = gameMarketInventoryProfile(
    assetId: asset.id,
    day: marketLiquidityDayKey(state.currentDate),
    referencePrice: previousClose,
    simulationSeed: state.simulationSeed,
    sharesOutstanding: sharesOutstanding,
    playerOwnedUnits: playerOwnedUnits,
    playerTenderAcquiredUnits: tenderAcquiredUnits,
  );
  for (final entry in entries ?? state.ledger) {
    final isBuy = entry.tradeSide == 'buy';
    final isSell = entry.tradeSide == 'sell';
    if (entry.day != state.day ||
        entry.assetId != asset.id ||
        (!isBuy && !isSell) ||
        !entry.tradeQuantity.isFinite ||
        entry.tradeQuantity <= 0 ||
        entry.marketMinute < krxOpenMinute ||
        entry.marketMinute >= krxContinuousEndMinute) {
      continue;
    }
    final referencePrice =
        entry.tradeUnitPrice.isFinite && entry.tradeUnitPrice > 0
        ? entry.tradeUnitPrice
        : previousClose;
    final executionCapacity = gameOrderBookExecutionCapacity(
      assetId: asset.id,
      day: marketLiquidityDayKey(state.currentDate),
      minute: entry.marketMinute,
      unitPrice: referencePrice,
      previousClose: previousClose,
      simulationSeed: state.simulationSeed,
      sharesOutstanding: sharesOutstanding,
      freeFloatShares: inventory.hasIssuedShareLedger
          ? inventory.turnoverEligibleShares
          : null,
    );
    final initialTicks = gamePlayerMarketImpactInitialTicks(
      filledQuantity: entry.tradeQuantity,
      executionCapacity: executionCapacity,
    );
    if (initialTicks <= 0) continue;
    for (
      var ageMinutes = 1;
      ageMinutes <= gamePlayerMarketImpactDurationMinutes;
      ageMinutes += 1
    ) {
      final affectedMinute = entry.marketMinute + ageMinutes;
      if (affectedMinute >= krxContinuousEndMinute) break;
      final pathIndex = marketTickForMinute(affectedMinute);
      if (pathIndex < 0 || pathIndex >= impacted.length) continue;
      final decayedTicks = gamePlayerMarketImpactTicksAtAge(
        initialTicks: initialTicks,
        ageMinutes: ageMinutes,
      );
      final shifted = gameOrderBookPriceAfterTickImpact(
        basePrice: impacted[pathIndex],
        signedTicks: isBuy ? decayedTicks : -decayedTicks,
        market: asset.market,
      );
      impacted[pathIndex] = marketSnapPrice(
        shifted.clamp(range.lower, range.upper).toDouble(),
        market: asset.market,
      );
    }
  }
  return impacted;
}

class MarketPreviousSessionSeries {
  const MarketPreviousSessionSeries({
    required this.date,
    required this.referenceClose,
    required this.prices,
  });

  final DateTime date;
  final double referenceClose;
  final List<double> prices;
}

/// Regenerates the asset's full actual previous trading session.
MarketPreviousSessionSeries? marketPreviousSessionSeriesForAsset({
  required FictionalMarketAsset asset,
  required String simulationSeed,
  required DateTime currentDate,
}) {
  final history = asset.historyThrough(currentDate, count: 2);
  if (history.isEmpty) return null;

  // 장 시작 전·장중에는 오늘의 확정 종가가 아직 일별 시세에 없다.
  // 이때는 가장 최근 확정치가 바로 전 거래일이므로 그 항목을 쓴다.
  // 반대로 오늘 확정치까지 있는 장 마감 후에는 한 칸 앞을 쓴다.
  final hasCurrentSessionClose =
      history.last.date == marketDateKey(currentDate);
  if (hasCurrentSessionClose && history.length < 2) return null;
  final previousPoint = hasCurrentSessionClose
      ? history[history.length - 2]
      : history.last;
  final previousDate = previousPoint.parsedDate;
  final rawReferenceClose = asset.unadjustedReferenceCloseFor(
    previousPoint.date,
  );
  final referenceClose = asset.marketReferenceCloseOn(
    previousDate,
    previousClose: rawReferenceClose,
  );
  final previousPath = generatedMarketDayPathForAsset(
    asset: asset,
    simulationSeed: simulationSeed,
    date: previousDate,
    previousClose: rawReferenceClose,
    officialClose: previousPoint.close,
  );
  final continuousEnd = math.min(
    previousPath.length,
    generatedPreOpenTicks + generatedContinuousTradingTicks,
  );
  if (continuousEnd <= generatedPreOpenTicks) {
    return null;
  }
  final previousSession = previousPath.sublist(
    generatedPreOpenTicks,
    continuousEnd,
  );
  if (previousPath.length > generatedRegularSessionTicks) {
    previousSession.add(previousPath[generatedRegularSessionTicks]);
  }
  return MarketPreviousSessionSeries(
    date: previousDate,
    referenceClose: referenceClose,
    prices: List<double>.unmodifiable(previousSession),
  );
}

/// Returns the visible tail of the asset's actual previous trading session.
///
/// The series is regenerated from that session's own reference close, official
/// close, events, and deterministic seed. It uses the same 09:00-14:49
/// continuous segment and single 15:00 auction close as the current-day chart,
/// so its OHLC matches [recentMarketDailyCandles].
List<double> marketPreviousSessionLeadInForAsset({
  required FictionalMarketAsset asset,
  required String simulationSeed,
  required DateTime currentDate,
  required int pointCount,
}) {
  if (pointCount <= 0) return const <double>[];
  final series = marketPreviousSessionSeriesForAsset(
    asset: asset,
    simulationSeed: simulationSeed,
    currentDate: currentDate,
  );
  if (series == null) return const <double>[];
  final previousSession = series.prices;
  final visibleCount = math.min(pointCount, previousSession.length);
  return List<double>.unmodifiable(
    previousSession.sublist(previousSession.length - visibleCount),
  );
}

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
  final previousClose = asset.unadjustedReferenceCloseFor(quote.date);
  final isTradingDay = quote.isExactDate;
  late final double unitPrice;
  if (isTradingDay) {
    final currentMultiplier = state.shareholderGovernance.priceMultiplierFor(
      assetId,
      state.day,
    );
    final previousMultiplier = state.shareholderGovernance.priceMultiplierFor(
      assetId,
      state.day - 1,
    );
    final rawPath = generatedMarketDayPathForAsset(
      asset: asset,
      simulationSeed: state.simulationSeed,
      date: state.currentDate,
      previousClose: previousClose,
      officialClose: quote.close,
    );
    final managementAdjustedPath = rawPath
        .map((price) => price * currentMultiplier)
        .toList(growable: false);
    final marketReferenceClose =
        asset.marketReferenceCloseOn(
          state.currentDate,
          previousClose: previousClose,
        ) *
        previousMultiplier;
    final impactedPath = marketSessionPathWithPlayerImpact(
      state: state,
      asset: asset,
      sourcePath: managementAdjustedPath,
      previousClose: marketReferenceClose,
    );
    unitPrice = impactedPath[marketTickForMinute(state.marketMinute)];
  } else {
    unitPrice = state.shareholderGovernance.adjustedPrice(
      assetId,
      state.day,
      quote.close,
    );
  }
  return MarketTradeQuote(
    asset: asset,
    quoteDate: state.currentDate.toIso8601String().split('T').first,
    unitPrice: unitPrice,
    marketMinute: state.marketMinute,
    isTradingDay: isTradingDay,
  );
}
