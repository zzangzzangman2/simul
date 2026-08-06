import 'dart:math' as math;

import 'market_liquidity_zones.dart';
import 'market_price_rules.dart';

/// 08:00~20:00을 실제 게임 시각 1분 단위로 재현하는 전체 틱 수.
const generatedSessionTicks = 720;
const generatedPreOpenTicks = 60;
const generatedRegularSessionTicks = 420;
const generatedRegularTradingTicks =
    generatedRegularSessionTicks - generatedPreOpenTicks;
const generatedContinuousTradingTicks = 350;
const generatedPostCloseTicks =
    generatedSessionTicks - generatedRegularSessionTicks;

class MarketTimedImpact {
  const MarketTimedImpact({
    required this.revealMinute,
    required this.impactRate,
  });

  final int revealMinute;
  final double impactRate;
}

class MarketCandle {
  const MarketCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.startMinute,
    this.volume = 0,
  });

  final double open;
  final double high;
  final double low;
  final double close;
  final int startMinute;
  final double volume;
}

/// 실제 이전 종가에서 실제 당일 종가로 이어지는 비주기적 게임용 장중 경로.
///
/// 중간 값은 실제 체결가가 아니다. 종목·날짜별 시드로 난수 충격, 단기 모멘텀,
/// 변동성 군집, 드문 급변을 만들고 Brownian bridge 보정으로 마지막 값만 실제
/// 종가에 고정한다. 같은 시드는 재현 가능하지만 사인파 같은 반복 주기는 없다.
List<double> generatedMarketPath({
  required double previousClose,
  required double officialClose,
  int totalTicks = generatedSessionTicks,
  int seed = 0,
  double dailyLimitRate = 0.15,
  String market = '미래시장',
  double? openingPrice,
  double? lowerPriceLimit,
  double? upperPriceLimit,
}) {
  if (totalTicks <= 0 || previousClose <= 0) {
    return <double>[officialClose];
  }

  final bounds = _resolvedMarketPathBounds(
    previousClose: previousClose,
    dailyLimitRate: dailyLimitRate,
    lowerPriceLimit: lowerPriceLimit,
    upperPriceLimit: upperPriceLimit,
  );
  final dailyLower = bounds.lower;
  final dailyUpper = bounds.upper;
  final boundedOfficialClose = officialClose
      .clamp(dailyLower, dailyUpper)
      .toDouble();
  final rawOpening =
      openingPrice != null && openingPrice.isFinite && openingPrice > 0
      ? openingPrice
      : previousClose;
  final boundedOpening = rawOpening.clamp(dailyLower, dailyUpper).toDouble();
  final openingTick = sharedMarketTickSize(boundedOpening, market: market);
  final sessionOpen =
      (boundedOpening / openingTick).roundToDouble() * openingTick;

  final raw = <double>[0];
  var velocity = 0.0;
  var cumulative = 0.0;
  var volatility = 0.85;
  for (var step = 1; step <= totalTicks; step++) {
    final regime = 0.55 + _unit(seed, step ~/ 11 + 701) * 1.25;
    volatility = volatility * 0.84 + regime * 0.16;
    final shock =
        (_unit(seed, step * 7 + 11) +
            _unit(seed, step * 13 + 29) +
            _unit(seed, step * 19 + 47) -
            1.5) *
        1.2;
    velocity = velocity * 0.56 + shock * volatility;

    if (_unit(seed, step * 31 + 97) < 0.035) {
      final sign = _unit(seed, step * 37 + 131) < 0.5 ? -1.0 : 1.0;
      velocity += sign * (1.25 + _unit(seed, step * 41 + 173) * 2.35);
    }

    cumulative += velocity;
    raw.add(cumulative);
  }

  final dayMoveRate = ((boundedOfficialClose - previousClose) / previousClose)
      .abs();
  final rangeRate = (0.018 + dayMoveRate * 0.38).clamp(0.018, 0.075);
  final corridor = math.max(
    (boundedOfficialClose - previousClose).abs() * 1.45,
    previousClose * rangeRate * 2.25,
  );
  final lower = math.max(
    dailyLower,
    math.min(math.min(previousClose, sessionOpen), boundedOfficialClose) -
        corridor,
  );
  final upper = math.min(
    dailyUpper,
    math.max(math.max(previousClose, sessionOpen), boundedOfficialClose) +
        corridor,
  );
  final rawClose = raw.last;
  final scale = previousClose * rangeRate * 0.42 / math.sqrt(totalTicks);
  final result = <double>[sessionOpen];

  for (var step = 1; step < totalTicks; step++) {
    final progress = step / totalTicks;
    final trend = sessionOpen + (boundedOfficialClose - sessionOpen) * progress;
    final bridge = raw[step] - rawClose * progress;
    final candidate = (trend + bridge * scale).clamp(lower, upper).toDouble();
    final tickSize = sharedMarketTickSize(candidate, market: market);
    var rounded = (candidate / tickSize).roundToDouble() * tickSize;

    final delta = rounded - result.last;
    final moveTickSize = sharedMarketTickSize(result.last, market: market);
    final minimumTicks = _unit(seed, step * 43 + 211) < 0.28 ? 0 : 1;
    final minimumMove = moveTickSize * minimumTicks;
    if (minimumTicks > 0 && delta.abs() < minimumMove) {
      final direction = delta != 0
          ? delta.sign
          : velocityFor(raw, step) +
                    (_unit(seed, step * 47 + 251) - 0.5) * 1.8 >=
                0
          ? 1.0
          : -1.0;
      final preferred = result.last + minimumMove * direction;
      final fallback = result.last - minimumMove * direction;
      if (preferred >= lower && preferred <= upper) {
        rounded = preferred;
      } else if (fallback >= lower && fallback <= upper) {
        rounded = fallback;
      }
    }
    result.add(rounded);
  }

  result.add(boundedOfficialClose);
  return result;
}

/// 고정된 전일 정규장 경로의 끝부분만 잘라 장 초반 차트 앞에 붙인다.
///
/// [pointCount]가 매분 하나씩 줄어도 남아 있는 값은 그대로 유지되므로,
/// 새 현재 봉이 들어올 때 과거 봉 전체가 다시 그려지는 현상을 막는다.
List<double> generatedPreviousSessionLeadIn({
  required double previousClose,
  required int pointCount,
  int seed = 0,
  String market = '미래시장',
}) {
  if (pointCount <= 0 || previousClose <= 0) return const <double>[];
  final previousSession = generatedMarketPath(
    previousClose: previousClose,
    officialClose: previousClose,
    totalTicks: generatedRegularTradingTicks,
    seed: seed,
    market: market,
  );
  final completedTicks = previousSession.take(generatedRegularTradingTicks);
  final visibleCount = pointCount
      .clamp(0, generatedRegularTradingTicks)
      .toInt();
  return completedTicks
      .skip(generatedRegularTradingTicks - visibleCount)
      .toList();
}

/// 08:00~20:00 게임 하루의 1분 가격 경로.
///
/// 08:00~08:59는 개장 전이라 이전 종가로 고정한다. 09:00부터 정규장
/// 경로를 만들고 15:00(tick 420)에 실제 종가를 고정한다. 정규장 마감 뒤에는
/// 별도 확장장을 만들지 않고 20:00까지 같은 종가를 유지한다.
List<double> generatedFullMarketDayPath({
  required double previousClose,
  required double officialClose,
  int seed = 0,
  double dailyLimitRate = 0.15,
  String market = '미래시장',
  List<MarketTimedImpact> timedImpacts = const <MarketTimedImpact>[],
  MarketStructuralLiquidityMap? structuralLiquidity,
  double? lowerPriceLimit,
  double? upperPriceLimit,
  bool useIpoOpeningDiscovery = false,
}) {
  final bounds = _resolvedMarketPathBounds(
    previousClose: previousClose,
    dailyLimitRate: dailyLimitRate,
    lowerPriceLimit: lowerPriceLimit,
    upperPriceLimit: upperPriceLimit,
  );
  final dailyLower = bounds.lower;
  final dailyUpper = bounds.upper;
  final boundedOfficialClose = officialClose
      .clamp(dailyLower, dailyUpper)
      .toDouble();
  final scaledTimedImpacts = _scaledTimedMarketImpacts(
    timedImpacts,
    dailyLimitRate: dailyLimitRate,
  );
  final totalTimedImpact = scaledTimedImpacts.fold<double>(
    0,
    (sum, impact) => sum + impact.impactRate,
  );
  final rawBaselineClose =
      boundedOfficialClose - previousClose * totalTimedImpact;
  final boundedBaselineClose = rawBaselineClose
      .clamp(dailyLower, dailyUpper)
      .toDouble();
  final baselineTick = sharedMarketTickSize(
    boundedBaselineClose,
    market: market,
  );
  final baselineClose =
      (boundedBaselineClose / baselineTick).roundToDouble() * baselineTick;
  final preOpenImpact = scaledTimedImpacts
      .where(
        (impact) => impact.revealMinute <= 9 * 60 && impact.impactRate.isFinite,
      )
      .fold<double>(0, (sum, impact) => sum + impact.impactRate)
      .clamp(-dailyLimitRate * 0.35, dailyLimitRate * 0.35)
      .toDouble();
  final randomGapRate =
      (_unit(seed, 880301) - 0.5) * 2 * math.min(0.012, dailyLimitRate * 0.08);
  final overnightImbalanceDraw = _unit(seed, 880313);
  final overnightImbalanceRate = overnightImbalanceDraw < 0.012
      ? (_unit(seed, 880319) < 0.5 ? -1.0 : 1.0) *
            (0.025 + _unit(seed, 880321) * 0.045)
      : 0.0;
  final rawOpening = useIpoOpeningDiscovery
      ? previousClose *
            (1 +
                ((boundedOfficialClose - previousClose) / previousClose) *
                    0.82 +
                (_unit(seed, 880307) - 0.5) * 0.08 +
                preOpenImpact * 0.25)
      : previousClose *
            (1 + randomGapRate + overnightImbalanceRate + preOpenImpact * 0.60);
  final openingCandidate = rawOpening.clamp(dailyLower, dailyUpper).toDouble();
  final openingTick = sharedMarketTickSize(openingCandidate, market: market);
  final openingPrice =
      (openingCandidate / openingTick).roundToDouble() * openingTick;
  final regular = generatedMarketPath(
    previousClose: previousClose,
    officialClose: baselineClose,
    totalTicks: generatedRegularTradingTicks,
    seed: seed,
    dailyLimitRate: dailyLimitRate,
    market: market,
    openingPrice: openingPrice,
    lowerPriceLimit: dailyLower,
    upperPriceLimit: dailyUpper,
  );
  var causalRegular = _applyTimedMarketImpacts(
    regular,
    previousClose: previousClose,
    dailyLimitRate: dailyLimitRate,
    timedImpacts: scaledTimedImpacts,
    market: market,
    lowerPriceLimit: dailyLower,
    upperPriceLimit: dailyUpper,
  );
  if (structuralLiquidity != null) {
    causalRegular = _applyStructuralLiquidityTraversal(
      causalRegular,
      previousClose: previousClose,
      seed: seed,
      market: market,
      lowerPriceLimit: dailyLower,
      upperPriceLimit: dailyUpper,
      structure: structuralLiquidity,
    );
  }
  causalRegular[causalRegular.length - 1] = boundedOfficialClose;
  if (causalRegular.length > generatedContinuousTradingTicks + 1) {
    final auctionReference = causalRegular[generatedContinuousTradingTicks - 1];
    for (
      var tick = generatedContinuousTradingTicks;
      tick < causalRegular.length - 1;
      tick += 1
    ) {
      causalRegular[tick] = auctionReference;
    }
  }
  return <double>[
    ...List<double>.filled(generatedPreOpenTicks, previousClose),
    ...causalRegular,
    ...List<double>.filled(generatedPostCloseTicks, boundedOfficialClose),
  ];
}

List<MarketTimedImpact> _scaledTimedMarketImpacts(
  List<MarketTimedImpact> timedImpacts, {
  required double dailyLimitRate,
}) {
  final valid = timedImpacts
      .where(
        (impact) =>
            impact.impactRate.isFinite && impact.impactRate.abs() >= 0.0000001,
      )
      .toList(growable: false);
  final positiveTotal = valid.fold<double>(
    0,
    (sum, impact) => impact.impactRate > 0 ? sum + impact.impactRate : sum,
  );
  final negativeTotal = valid.fold<double>(
    0,
    (sum, impact) => impact.impactRate < 0 ? sum + impact.impactRate : sum,
  );
  final positiveScale = positiveTotal <= 0
      ? 0.0
      : math.min(positiveTotal, dailyLimitRate * 0.85) / positiveTotal;
  final negativeScale = negativeTotal >= 0
      ? 0.0
      : math.max(negativeTotal, -dailyLimitRate * 0.85) / negativeTotal;
  return <MarketTimedImpact>[
    for (final impact in valid)
      MarketTimedImpact(
        revealMinute: impact.revealMinute,
        impactRate:
            impact.impactRate *
            (impact.impactRate >= 0 ? positiveScale : negativeScale),
      ),
  ];
}

List<double> _applyTimedMarketImpacts(
  List<double> regular, {
  required double previousClose,
  required double dailyLimitRate,
  required List<MarketTimedImpact> timedImpacts,
  required String market,
  double? lowerPriceLimit,
  double? upperPriceLimit,
}) {
  if (regular.length <= 2 || timedImpacts.isEmpty || previousClose <= 0) {
    return regular;
  }
  final totalTicks = regular.length - 1;
  final bounds = _resolvedMarketPathBounds(
    previousClose: previousClose,
    dailyLimitRate: dailyLimitRate,
    lowerPriceLimit: lowerPriceLimit,
    upperPriceLimit: upperPriceLimit,
  );
  final lower = bounds.lower;
  final upper = bounds.upper;
  final result = List<double>.from(regular);

  for (var step = 1; step < totalTicks; step++) {
    var logAdjustment = 0.0;
    for (final timedImpact in timedImpacts) {
      if (!timedImpact.impactRate.isFinite ||
          timedImpact.impactRate.abs() < 0.0000001) {
        continue;
      }
      final impact = timedImpact.impactRate;
      final lastContinuousTick = math.min(
        totalTicks - 1,
        generatedContinuousTradingTicks - 1,
      );
      final revealTick = (timedImpact.revealMinute - 9 * 60)
          .clamp(0, lastContinuousTick)
          .toInt();
      var disclosedProgress = 0.0;
      if (step >= revealTick) {
        final burstProgress = ((step - revealTick + 1) / 5)
            .clamp(0.0, 1.0)
            .toDouble();
        final remainingTicks = math.max(1, totalTicks - revealTick);
        final tailProgress = ((step - revealTick) / remainingTicks)
            .clamp(0.0, 1.0)
            .toDouble();
        disclosedProgress = burstProgress * 0.75 + tailProgress * 0.25;
      }
      logAdjustment += impact * disclosedProgress;
    }
    final adjusted = (regular[step] * math.exp(logAdjustment))
        .clamp(lower, upper)
        .toDouble();
    final tickSize = sharedMarketTickSize(adjusted, market: market);
    result[step] = (adjusted / tickSize).roundToDouble() * tickSize;
  }
  result
    ..first = regular.first
    ..last = regular.last;
  return result;
}

/// Applies one causal, forward-only pass over the continuous session.
///
/// The latent market path supplies demand. Intact structural prices absorb
/// that demand for several ticks, then become permanently broken for the rest
/// of the day. Only already-observed movement can trigger the thin-book boost,
/// so a later news reveal cannot rewrite an earlier price.
List<double> _applyStructuralLiquidityTraversal(
  List<double> regular, {
  required double previousClose,
  required int seed,
  required String market,
  required double lowerPriceLimit,
  required double upperPriceLimit,
  required MarketStructuralLiquidityMap structure,
}) {
  if (regular.length <= 2 || structure.activeZones.isEmpty) return regular;

  final zones = structure.activeZones.toList(growable: false)
    ..sort((left, right) => left.price.compareTo(right.price));
  final result = List<double>.from(regular);
  final absorbedPressure = <double, double>{};
  final brokenPrices = <double>{
    for (final zone in zones)
      if (zone.isBreached ||
          _openingCrossedStructuralZone(
            zone,
            previousClose: previousClose,
            openingPrice: regular.first,
          ) ||
          zone.breachedBy(
            sessionLow: math.min(previousClose, regular.first),
            sessionHigh: math.max(previousClose, regular.first),
          ))
        zone.price,
  };
  MarketStructuralLiquidityZone? lastBrokenZone;
  var vacuumDirection = 0;
  final continuousEnd = math.min(
    generatedContinuousTradingTicks,
    regular.length - 1,
  );

  for (var step = 1; step < continuousEnd; step += 1) {
    final previousOutput = result[step - 1];
    final rawPrevious = regular[step - 1];
    final rawTarget = regular[step];
    final rawDirection = _marketMoveDirection(rawTarget - rawPrevious);
    var target = rawTarget;
    final latentDirection = _marketMoveDirection(target - previousOutput);

    final escapedBrokenGap =
        lastBrokenZone != null &&
        (vacuumDirection < 0
            ? previousOutput > lastBrokenZone.price + 0.000001
            : vacuumDirection > 0
            ? previousOutput < lastBrokenZone.price - 0.000001
            : false);
    if (escapedBrokenGap) {
      vacuumDirection = 0;
      lastBrokenZone = null;
    }
    if (vacuumDirection != 0 &&
        rawDirection == vacuumDirection &&
        latentDirection == vacuumDirection &&
        lastBrokenZone != null) {
      // A value below one means less standing depth behind the broken wall.
      // Convert it into a bounded speed multiplier without looking ahead.
      final tickReference = vacuumDirection > 0
          ? previousOutput
          : math.max(0.000001, previousOutput - 0.000001);
      final tick = sharedMarketTickSize(tickReference, market: market);
      final rawTicks = tick <= 0 ? 0.0 : (rawTarget - rawPrevious).abs() / tick;
      final speedMultiplier = (1 / lastBrokenZone.vacuumMultiplier)
          .clamp(1.0, 2.85)
          .toDouble();
      final extraTicks = math
          .max(2, (math.max(1.0, rawTicks) * (speedMultiplier - 1)).round())
          .clamp(2, 5);
      target += vacuumDirection * tick * extraTicks;
    }
    target = _snapStructuralPathPrice(
      target,
      market: market,
      lowerPriceLimit: lowerPriceLimit,
      upperPriceLimit: upperPriceLimit,
    );

    var cursor = previousOutput;
    var resolved = target;
    var searchCount = 0;
    while (searchCount <= zones.length) {
      searchCount += 1;
      final direction = _marketMoveDirection(resolved - cursor);
      if (direction == 0) break;
      final zone = _firstBlockingStructuralZone(
        zones,
        brokenPrices: brokenPrices,
        fromPrice: cursor,
        toPrice: resolved,
        direction: direction,
      );
      if (zone == null) break;

      final rawTickDemand = zone.tickSize <= 0
          ? 1.0
          : (rawTarget - rawPrevious).abs() / zone.tickSize;
      final overshootDemand = zone.tickSize <= 0
          ? 0.0
          : (resolved - zone.price).abs() / zone.tickSize;
      final deterministicFlow =
          0.84 +
          _unit(
                seed ^ structure.seed,
                step * 97 + zone.price.round() * 13 + 0x51A7,
              ) *
              0.32;
      final pressure =
          (0.72 +
              math.min(8.0, rawTickDemand) * 0.48 +
              math.min(10.0, overshootDemand) * 0.18) *
          deterministicFlow;
      final priorPressure = absorbedPressure[zone.price] ?? 0;
      final absorptionCapacity = math
          .max(1.0, zone.holdTicks * math.max(1.0, zone.strength * 0.72))
          .toDouble();
      final nextPressure = priorPressure + pressure;
      absorbedPressure[zone.price] = math.min(absorptionCapacity, nextPressure);

      if (nextPressure + 0.000001 < absorptionCapacity) {
        resolved = _snapStructuralPathPrice(
          zone.price,
          market: market,
          lowerPriceLimit: lowerPriceLimit,
          upperPriceLimit: upperPriceLimit,
        );
        vacuumDirection = 0;
        lastBrokenZone = null;
        break;
      }

      brokenPrices.add(zone.price);
      vacuumDirection = direction;
      lastBrokenZone = zone;
      final breachPrice = _snapStructuralPathPrice(
        zone.breachBoundary,
        market: market,
        lowerPriceLimit: lowerPriceLimit,
        upperPriceLimit: upperPriceLimit,
      );
      // Keep the path's observable extrema in sync with the pure structural
      // map used by the order book. Otherwise a locally broken wall could be
      // rebuilt as intact after a one-tick penetration and screen refresh.
      resolved = direction > 0
          ? math.max(resolved, breachPrice)
          : math.min(resolved, breachPrice);
      cursor = breachPrice;
    }
    result[step] = _snapStructuralPathPrice(
      resolved,
      market: market,
      lowerPriceLimit: lowerPriceLimit,
      upperPriceLimit: upperPriceLimit,
    );
  }
  return result;
}

bool _openingCrossedStructuralZone(
  MarketStructuralLiquidityZone zone, {
  required double previousClose,
  required double openingPrice,
}) {
  return switch (zone.kind) {
    MarketLiquidityZoneKind.support =>
      previousClose >= zone.price - 0.000001 &&
          openingPrice < zone.price - 0.000001,
    MarketLiquidityZoneKind.resistance =>
      previousClose <= zone.price + 0.000001 &&
          openingPrice > zone.price + 0.000001,
  };
}

MarketStructuralLiquidityZone? _firstBlockingStructuralZone(
  List<MarketStructuralLiquidityZone> zones, {
  required Set<double> brokenPrices,
  required double fromPrice,
  required double toPrice,
  required int direction,
}) {
  if (direction > 0) {
    for (final zone in zones) {
      if (zone.price < fromPrice - 0.000001) continue;
      if (zone.price > toPrice + 0.000001) break;
      if (brokenPrices.contains(zone.price) ||
          zone.kind != MarketLiquidityZoneKind.resistance) {
        continue;
      }
      return zone;
    }
    return null;
  }
  for (final zone in zones.reversed) {
    if (zone.price > fromPrice + 0.000001) continue;
    if (zone.price < toPrice - 0.000001) break;
    if (brokenPrices.contains(zone.price) ||
        zone.kind != MarketLiquidityZoneKind.support) {
      continue;
    }
    return zone;
  }
  return null;
}

double _snapStructuralPathPrice(
  double price, {
  required String market,
  required double lowerPriceLimit,
  required double upperPriceLimit,
}) {
  final bounded = price.clamp(lowerPriceLimit, upperPriceLimit).toDouble();
  final tick = sharedMarketTickSize(
    math.max(0.000001, bounded),
    market: market,
  );
  if (!tick.isFinite || tick <= 0) return bounded;
  return ((bounded / tick).roundToDouble() * tick)
      .clamp(lowerPriceLimit, upperPriceLimit)
      .toDouble();
}

int _marketMoveDirection(double delta) {
  if (delta > 0.000001) return 1;
  if (delta < -0.000001) return -1;
  return 0;
}

double generatedMarketTick({
  required double previousClose,
  required double officialClose,
  required int tickIndex,
  int totalTicks = generatedSessionTicks,
  int seed = 0,
  double dailyLimitRate = 0.15,
  String market = '미래시장',
}) {
  final path = generatedMarketPath(
    previousClose: previousClose,
    officialClose: officialClose,
    totalTicks: totalTicks,
    seed: seed,
    dailyLimitRate: dailyLimitRate,
    market: market,
  );
  return path[tickIndex.clamp(0, path.length - 1)];
}

List<MarketCandle> aggregateMarketCandles(
  List<double> prices,
  int intervalMinutes, {
  int tickMinutes = 1,
  int? seed,
  int startMinuteOffset = 0,
  double? lowerPriceLimit,
  double? upperPriceLimit,
  double? totalVolume,
  List<int>? minuteVolumes,
  String market = '미래시장',
}) {
  if (prices.isEmpty) return const <MarketCandle>[];
  if (intervalMinutes <= 0 || tickMinutes <= 0) {
    throw ArgumentError('Candle and tick intervals must be positive.');
  }
  if (intervalMinutes % tickMinutes != 0) {
    throw ArgumentError(
      '$intervalMinutes-minute candles cannot be built from '
      '$tickMinutes-minute ticks.',
    );
  }
  final lowerBound = lowerPriceLimit != null && lowerPriceLimit.isFinite
      ? lowerPriceLimit
      : double.negativeInfinity;
  final upperBound = upperPriceLimit != null && upperPriceLimit.isFinite
      ? upperPriceLimit
      : double.infinity;
  final interval = math.max(1, intervalMinutes ~/ tickMinutes);
  if (prices.length == 1) return const <MarketCandle>[];
  if (totalVolume != null && (!totalVolume.isFinite || totalVolume < 0)) {
    throw ArgumentError.value(
      totalVolume,
      'totalVolume',
      'Total volume must be finite and non-negative.',
    );
  }
  if (totalVolume != null && minuteVolumes != null) {
    throw ArgumentError(
      'Provide either totalVolume or minuteVolumes, not both.',
    );
  }
  if (minuteVolumes != null &&
      (minuteVolumes.length != prices.length - 1 ||
          minuteVolumes.any((volume) => volume < 0))) {
    throw ArgumentError.value(
      minuteVolumes,
      'minuteVolumes',
      'Minute volumes must be non-negative and match every price transition.',
    );
  }
  final normalizedMinuteVolumes = minuteVolumes != null
      ? List<int>.unmodifiable(minuteVolumes)
      : totalVolume == null
      ? null
      : _normalizedMarketMinuteVolumes(
          prices,
          totalVolume: totalVolume.round(),
          seed: seed ?? 0,
          startMinuteOffset: startMinuteOffset,
          tickMinutes: tickMinutes,
          market: market,
        );

  final candles = <MarketCandle>[];
  for (var start = 0; start < prices.length - 1; start += interval) {
    final end = math.min(start + interval, prices.length - 1);
    final slice = prices.sublist(start, end + 1);
    var high = slice.reduce(math.max);
    var low = slice.reduce(math.min);
    var volume = 0.0;
    if (seed != null) {
      for (var index = start; index < end; index++) {
        final open = prices[index];
        final close = prices[index + 1];
        final absoluteMinute = startMinuteOffset + index * tickMinutes;
        final tickSize = sharedMarketTickSize(
          math.max((open + close) / 2, 1).toDouble(),
          market: market,
        );
        final body = (close - open).abs();
        final bodyTicks = body / tickSize;
        final wickChance = (0.18 + bodyTicks * 0.07).clamp(0.18, 0.48);
        final upperWick = _unit(seed, absoluteMinute * 17 + 1009) < wickChance
            ? tickSize
            : 0.0;
        final lowerWick = _unit(seed, absoluteMinute * 23 + 2027) < wickChance
            ? tickSize
            : 0.0;
        final minuteHigh = math.min(
          upperBound,
          math.max(open, close) + upperWick,
        );
        final minuteLow = math.max(
          lowerBound,
          math.max(tickSize, math.min(open, close) - lowerWick),
        );
        high = math.max(high, minuteHigh);
        low = math.min(low, minuteLow);

        if (normalizedMinuteVolumes == null) {
          volume +=
              (120 + (seed.abs() % 880)) *
              _marketMinuteVolumeWeight(
                prices,
                index: index,
                seed: seed,
                startMinuteOffset: startMinuteOffset,
                tickMinutes: tickMinutes,
                market: market,
              );
        }
      }
    }
    if (normalizedMinuteVolumes != null) {
      for (var index = start; index < end; index += 1) {
        volume += normalizedMinuteVolumes[index];
      }
    }
    candles.add(
      MarketCandle(
        open: slice.first,
        high: high,
        low: low,
        close: slice.last,
        startMinute: startMinuteOffset + start * tickMinutes,
        volume: volume,
      ),
    );
  }
  return candles;
}

List<int> _normalizedMarketMinuteVolumes(
  List<double> prices, {
  required int totalVolume,
  required int seed,
  required int startMinuteOffset,
  required int tickMinutes,
  required String market,
}) {
  final weights = <double>[
    for (var index = 0; index < prices.length - 1; index += 1)
      _marketMinuteVolumeWeight(
        prices,
        index: index,
        seed: seed,
        startMinuteOffset: startMinuteOffset,
        tickMinutes: tickMinutes,
        market: market,
      ),
  ];
  final weightSum = weights.fold<double>(0, (sum, weight) => sum + weight);
  if (totalVolume <= 0 || weightSum <= 0) {
    return List<int>.filled(weights.length, 0);
  }
  final result = <int>[];
  var cumulativeWeight = 0.0;
  var allocated = 0;
  for (final weight in weights) {
    cumulativeWeight += weight;
    final cumulativeUnits = (totalVolume * cumulativeWeight / weightSum)
        .round()
        .clamp(allocated, totalVolume);
    result.add(cumulativeUnits - allocated);
    allocated = cumulativeUnits;
  }
  return result;
}

double _marketMinuteVolumeWeight(
  List<double> prices, {
  required int index,
  required int seed,
  required int startMinuteOffset,
  required int tickMinutes,
  required String market,
}) {
  final open = prices[index];
  final close = prices[index + 1];
  final absoluteMinute = startMinuteOffset + index * tickMinutes;
  final tickSize = sharedMarketTickSize(
    math.max((open + close) / 2, 1).toDouble(),
    market: market,
  );
  final bodyTicks = (close - open).abs() / tickSize;
  final activity = 0.16 + math.min(bodyTicks, 8) * 0.18;
  final noise = 0.55 + _unit(seed, absoluteMinute * 31 + 3037) * 0.7;
  final burstRoll = _unit(seed, absoluteMinute * 37 + 4051);
  final burst = burstRoll < 0.045
      ? 3.8 + _unit(seed, absoluteMinute * 41 + 5011) * 3.2
      : 1.0;
  final openingActivity = absoluteMinute >= 0 && absoluteMinute < 15
      ? 1.35
      : 1.0;
  return activity * noise * burst * openingActivity;
}

/// 14:50~14:59 장마감 동시호가의 결정론적 예상체결가.
///
/// 실제 체결가는 15:00까지 숨기고, 14:49 마지막 체결가에서 종가 방향으로
/// 점차 수렴하되 남은 갭에 비례한 시드 노이즈를 유지한다.
double generatedClosingAuctionIndicativePrice({
  required double referencePrice,
  required double officialClose,
  required double previousClose,
  required int minute,
  required int seed,
  double dailyLimitRate = 0.15,
  String market = '미래시장',
  double? lowerPriceLimit,
  double? upperPriceLimit,
}) {
  const auctionStartMinute = 14 * 60 + 50;
  const closeMinute = 15 * 60;
  if (referencePrice <= 0 || officialClose <= 0 || previousClose <= 0) {
    return officialClose > 0 ? officialClose : referencePrice;
  }
  if (minute < auctionStartMinute) return referencePrice;
  if (minute >= closeMinute) return officialClose;
  final auctionStep = (minute - auctionStartMinute).clamp(0, 9);
  final convergence = 0.15 + 0.70 * auctionStep / 9;
  final gap = officialClose - referencePrice;
  final residual = gap.abs() * (1 - convergence);
  final noise = (_unit(seed, minute * 97 + 0x5A17) * 2 - 1) * residual * 0.30;
  final bounds = _resolvedMarketPathBounds(
    previousClose: previousClose,
    dailyLimitRate: dailyLimitRate,
    lowerPriceLimit: lowerPriceLimit,
    upperPriceLimit: upperPriceLimit,
  );
  final candidate = (referencePrice + gap * convergence + noise).clamp(
    bounds.lower,
    bounds.upper,
  );
  final tickSize = sharedMarketTickSize(candidate.toDouble(), market: market);
  return (candidate / tickSize).roundToDouble() * tickSize;
}

int marketStockSeed(String code, DateTime date) {
  var value = date.year * 10000 + date.month * 100 + date.day;
  for (final unit in code.codeUnits) {
    value = ((value * 31) ^ unit) & 0x7fffffff;
  }
  return value;
}

double velocityFor(List<double> raw, int step) {
  if (step <= 0 || step >= raw.length) return 0;
  return raw[step] - raw[step - 1];
}

({double lower, double upper}) _resolvedMarketPathBounds({
  required double previousClose,
  required double dailyLimitRate,
  double? lowerPriceLimit,
  double? upperPriceLimit,
}) {
  final normalizedLimit = dailyLimitRate.isFinite
      ? dailyLimitRate.clamp(0.01, 0.99).toDouble()
      : 0.15;
  final fallbackLower = previousClose * (1 - normalizedLimit);
  final fallbackUpper = previousClose * (1 + normalizedLimit);
  final lower =
      lowerPriceLimit != null && lowerPriceLimit.isFinite && lowerPriceLimit > 0
      ? lowerPriceLimit
      : fallbackLower;
  final upper =
      upperPriceLimit != null &&
          upperPriceLimit.isFinite &&
          upperPriceLimit >= lower
      ? upperPriceLimit
      : fallbackUpper;
  if (upper < lower) {
    return (lower: fallbackLower, upper: fallbackUpper);
  }
  return (lower: lower, upper: upper);
}

double _unit(int seed, int index) {
  var value = (seed ^ (index * 0x45d9f3b)) & 0x7fffffff;
  value = ((value ^ (value >> 16)) * 0x45d9f3b) & 0x7fffffff;
  value = ((value ^ (value >> 16)) * 0x45d9f3b) & 0x7fffffff;
  value = (value ^ (value >> 16)) & 0x7fffffff;
  return value / 0x7fffffff;
}
