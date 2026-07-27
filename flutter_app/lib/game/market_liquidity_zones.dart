import 'market_price_rules.dart';
import 'market_technical_levels.dart';

/// The structural role an absolute price has at the start of a session.
///
/// A price below the reference is support and a price above it is resistance.
/// The role is deliberately separate from an order-book side: after a real
/// break, the same absolute price may later appear on the other side of the
/// spread without receiving a new structural identity.
enum MarketLiquidityZoneKind { support, resistance }

/// A deterministic long-lived liquidity zone attached to an absolute price.
class MarketStructuralLiquidityZone {
  const MarketStructuralLiquidityZone({
    required this.price,
    required this.kind,
    required this.isMajor,
    required this.isActive,
    required this.strength,
    required this.holdTicks,
    required this.tickSize,
    required this.breachBoundary,
    required this.isBreached,
    required this.vacuumMultiplier,
    this.isPsychological = true,
    this.technicalPeriods = const <int>[],
  });

  final double price;
  final MarketLiquidityZoneKind kind;

  /// Major round prices are always active. Seed-selected minor prices and the
  /// nearest minor price on either side of the reference may also be active.
  final bool isMajor;
  final bool isActive;

  /// Target depth multiplier for an intact active structural wall.
  ///
  /// Active zones use a range of roughly 3x to 5x. Inactive grid prices retain
  /// a value of 1 and behave like ordinary order-book levels.
  final double strength;

  /// Number of price ticks the zone can absorb before it is considered broken.
  final int holdTicks;
  final double tickSize;
  final double breachBoundary;

  /// A breach is derived from cumulative session extremes, so rebuilding the
  /// same world/day never resurrects a wall merely because a screen was closed.
  final bool isBreached;

  /// Remaining depth multiplier in the gap behind this zone after a breach.
  final double vacuumMultiplier;
  final bool isPsychological;
  final List<int> technicalPeriods;

  int get confluenceCount =>
      (isPsychological ? 1 : 0) + technicalPeriods.length;

  bool breachedBy({required double sessionLow, required double sessionHigh}) {
    if (!isActive || !sessionLow.isFinite || !sessionHigh.isFinite) {
      return false;
    }
    return switch (kind) {
      MarketLiquidityZoneKind.support =>
        sessionLow <= breachBoundary + 0.000001,
      MarketLiquidityZoneKind.resistance =>
        sessionHigh >= breachBoundary - 0.000001,
    };
  }
}

/// Structural liquidity for one deterministic daily price band.
class MarketStructuralLiquidityMap {
  MarketStructuralLiquidityMap({
    required this.seed,
    required this.referencePrice,
    required this.gridStep,
    required this.lowerPrice,
    required this.upperPrice,
    required List<MarketStructuralLiquidityZone> zones,
  }) : zones = List<MarketStructuralLiquidityZone>.unmodifiable(zones);

  final int seed;
  final double referencePrice;
  final double gridStep;
  final double lowerPrice;
  final double upperPrice;

  /// Every psychological-grid candidate in ascending absolute-price order.
  final List<MarketStructuralLiquidityZone> zones;

  Iterable<MarketStructuralLiquidityZone> get activeZones =>
      zones.where((zone) => zone.isActive);

  MarketStructuralLiquidityZone? zoneAtPrice(double price) {
    if (!price.isFinite) return null;
    for (final zone in zones) {
      final tolerance = zone.tickSize * 0.001 + 0.000001;
      if ((zone.price - price).abs() <= tolerance) return zone;
      if (zone.price > price + tolerance) break;
    }
    return null;
  }

  MarketStructuralLiquidityZone? nearestActiveZoneBelow(
    double price, {
    bool includeBreached = false,
  }) {
    MarketStructuralLiquidityZone? nearest;
    for (final zone in zones) {
      if (zone.price >= price - 0.000001) break;
      if (!zone.isActive || (!includeBreached && zone.isBreached)) continue;
      nearest = zone;
    }
    return nearest;
  }

  MarketStructuralLiquidityZone? nearestActiveZoneAbove(
    double price, {
    bool includeBreached = false,
  }) {
    for (final zone in zones) {
      if (zone.price <= price + 0.000001 ||
          !zone.isActive ||
          (!includeBreached && zone.isBreached)) {
        continue;
      }
      return zone;
    }
    return null;
  }

  /// Returns the thin-book multiplier between a breached wall and the next
  /// intact active wall. Outside a breached gap the multiplier is 1.
  double vacuumMultiplierAt(double price) {
    if (!price.isFinite || zones.isEmpty) return 1;
    var multiplier = 1.0;
    for (final broken in zones) {
      if (!broken.isActive || !broken.isBreached) continue;
      switch (broken.kind) {
        case MarketLiquidityZoneKind.support:
          if (price >= broken.price - 0.000001) continue;
          final next = _nextIntactSupportBelow(broken.price);
          if (next == null || price > next.price + 0.000001) {
            if (broken.vacuumMultiplier < multiplier) {
              multiplier = broken.vacuumMultiplier;
            }
          }
        case MarketLiquidityZoneKind.resistance:
          if (price <= broken.price + 0.000001) continue;
          final next = _nextIntactResistanceAbove(broken.price);
          if (next == null || price < next.price - 0.000001) {
            if (broken.vacuumMultiplier < multiplier) {
              multiplier = broken.vacuumMultiplier;
            }
          }
      }
    }
    return multiplier.clamp(0.35, 1.0).toDouble();
  }

  MarketStructuralLiquidityZone? _nextIntactSupportBelow(double price) {
    MarketStructuralLiquidityZone? next;
    for (final zone in zones) {
      if (zone.price >= price - 0.000001) break;
      if (zone.kind == MarketLiquidityZoneKind.support &&
          zone.isActive &&
          !zone.isBreached) {
        next = zone;
      }
    }
    return next;
  }

  MarketStructuralLiquidityZone? _nextIntactResistanceAbove(double price) {
    for (final zone in zones) {
      if (zone.price <= price + 0.000001) continue;
      if (zone.kind == MarketLiquidityZoneKind.resistance &&
          zone.isActive &&
          !zone.isBreached) {
        return zone;
      }
    }
    return null;
  }
}

/// Stable structural seed for a world and asset.
///
/// Trading day and minute are intentionally absent. Daily session state may
/// weaken a zone, but it cannot redraw which absolute prices are important.
int marketStructuralLiquiditySeed({
  required String worldSeed,
  required String assetId,
}) {
  var hash = 0x811c9dc5;
  for (final unit in '$worldSeed:$assetId'.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

/// Returns a psychologically natural round-price grid near [price].
///
/// The target is about 1.5% of price, rounded to the nearest member of
/// {1, 2, 2.5, 5, 10} x 10^n and never narrower than eight exchange ticks.
/// For example, 290,000 won in the main market produces a 5,000 won grid.
double marketStructuralLiquidityGridStep({
  required double price,
  required String market,
}) {
  final tick = sharedMarketTickSize(price, market: market);
  if (!price.isFinite || price <= 0 || !tick.isFinite || tick <= 0) {
    return 1;
  }
  var target = price * 0.015;
  final minimum = tick * 8;
  if (target < minimum) target = minimum;

  var magnitude = 1.0;
  while (target >= magnitude * 10) {
    magnitude *= 10;
  }
  while (target < magnitude) {
    magnitude /= 10;
  }
  const factors = <double>[1, 2, 2.5, 5, 10];
  var best = factors.first * magnitude;
  var bestDistance = (best - target).abs();
  for (final factor in factors.skip(1)) {
    final candidate = factor * magnitude;
    final distance = (candidate - target).abs();
    if (distance < bestDistance - 0.000001 ||
        ((distance - bestDistance).abs() <= 0.000001 && candidate > best)) {
      best = candidate;
      bestDistance = distance;
    }
  }

  final snappedTicks = (best / tick).round();
  final safeTicks = snappedTicks < 8 ? 8 : snappedTicks;
  return safeTicks * tick;
}

/// Builds the absolute-price structural map for the supplied daily band.
///
/// The map is pure: the same world, asset, reference, band and cumulative
/// session extremes always produce the same zones and breach states.
MarketStructuralLiquidityMap buildMarketStructuralLiquidityMap({
  required String worldSeed,
  required String assetId,
  required String market,
  required double referencePrice,
  required double lowerPrice,
  required double upperPrice,
  double? sessionLow,
  double? sessionHigh,
  Iterable<MarketTechnicalLevel> technicalLevels =
      const <MarketTechnicalLevel>[],
}) {
  final seed = marketStructuralLiquiditySeed(
    worldSeed: worldSeed,
    assetId: assetId,
  );
  if (!referencePrice.isFinite ||
      referencePrice <= 0 ||
      !lowerPrice.isFinite ||
      !upperPrice.isFinite ||
      upperPrice <= 0) {
    return MarketStructuralLiquidityMap(
      seed: seed,
      referencePrice: referencePrice,
      gridStep: 1,
      lowerPrice: lowerPrice,
      upperPrice: upperPrice,
      zones: const <MarketStructuralLiquidityZone>[],
    );
  }

  final safeLower = lowerPrice < upperPrice ? lowerPrice : upperPrice;
  final safeUpper = upperPrice > lowerPrice ? upperPrice : lowerPrice;
  final gridStep = marketStructuralLiquidityGridStep(
    price: referencePrice,
    market: market,
  );
  if (!gridStep.isFinite || gridStep <= 0) {
    return MarketStructuralLiquidityMap(
      seed: seed,
      referencePrice: referencePrice,
      gridStep: 1,
      lowerPrice: safeLower,
      upperPrice: safeUpper,
      zones: const <MarketStructuralLiquidityZone>[],
    );
  }

  final firstGridIndex = (safeLower / gridStep).ceil();
  final lastGridIndex = (safeUpper / gridStep).floor();
  if (lastGridIndex < firstGridIndex) {
    final cumulativeLow = sessionLow != null && sessionLow.isFinite
        ? sessionLow
        : referencePrice;
    final cumulativeHigh = sessionHigh != null && sessionHigh.isFinite
        ? sessionHigh
        : referencePrice;
    final technicalOnly = _mergeTechnicalLiquidityLevels(
      zones: const <MarketStructuralLiquidityZone>[],
      technicalLevels: technicalLevels,
      seed: seed,
      referencePrice: referencePrice,
      gridStep: gridStep,
      market: market,
      lowerPrice: safeLower,
      upperPrice: safeUpper,
      sessionLow: cumulativeLow,
      sessionHigh: cumulativeHigh,
    );
    return MarketStructuralLiquidityMap(
      seed: seed,
      referencePrice: referencePrice,
      gridStep: gridStep,
      lowerPrice: safeLower,
      upperPrice: safeUpper,
      zones: technicalOnly,
    );
  }

  final nearestMinorBelow = _nearestMinorGridIndex(
    referencePrice: referencePrice,
    gridStep: gridStep,
    searchDown: true,
  );
  final nearestMinorAbove = _nearestMinorGridIndex(
    referencePrice: referencePrice,
    gridStep: gridStep,
    searchDown: false,
  );
  final cumulativeLow = sessionLow != null && sessionLow.isFinite
      ? sessionLow
      : referencePrice;
  final cumulativeHigh = sessionHigh != null && sessionHigh.isFinite
      ? sessionHigh
      : referencePrice;
  final zones = <MarketStructuralLiquidityZone>[];

  for (
    var gridIndex = firstGridIndex;
    gridIndex <= lastGridIndex;
    gridIndex += 1
  ) {
    final rawPrice = gridIndex * gridStep;
    final tick = sharedMarketTickSize(rawPrice, market: market);
    if (!tick.isFinite || tick <= 0) continue;
    final price = (rawPrice / tick).round() * tick;
    if (price < safeLower - 0.000001 ||
        price > safeUpper + 0.000001 ||
        price <= 0) {
      continue;
    }

    final isMajor = gridIndex.isEven;
    final isNearestMinor =
        !isMajor &&
        (gridIndex == nearestMinorBelow || gridIndex == nearestMinorAbove);
    final selectionRoll = _structuralHash(seed, gridIndex, 1709) % 100;
    final isSeedSelectedMinor = !isMajor && selectionRoll < 32;
    final isActive = isMajor || isNearestMinor || isSeedSelectedMinor;
    final strengthUnit = _structuralUnit(seed, gridIndex, 2909);
    final strength = !isActive
        ? 1.0
        : isMajor
        ? 4.25 + strengthUnit * 0.75
        : isNearestMinor
        ? 3.45 + strengthUnit * 0.70
        : 3.0 + strengthUnit * 0.80;
    final holdBase = isMajor
        ? 3
        : isNearestMinor
        ? 2
        : 1;
    final holdRange = isMajor
        ? 4
        : isNearestMinor
        ? 4
        : 3;
    final holdTicks = isActive
        ? holdBase + _structuralHash(seed, gridIndex, 3917) % holdRange
        : 0;
    final kind = price <= referencePrice + 0.000001
        ? MarketLiquidityZoneKind.support
        : MarketLiquidityZoneKind.resistance;
    final breachBoundary = _structuralBreachBoundary(
      price: price,
      kind: kind,
      holdTicks: holdTicks,
      market: market,
      lowerPrice: safeLower,
      upperPrice: safeUpper,
    );
    final vacuumMultiplier =
        0.35 + _structuralUnit(seed, gridIndex, 5021) * 0.30;
    final provisional = MarketStructuralLiquidityZone(
      price: price,
      kind: kind,
      isMajor: isMajor,
      isActive: isActive,
      strength: strength,
      holdTicks: holdTicks,
      tickSize: tick,
      breachBoundary: breachBoundary,
      isBreached: false,
      vacuumMultiplier: vacuumMultiplier,
    );
    zones.add(
      MarketStructuralLiquidityZone(
        price: provisional.price,
        kind: provisional.kind,
        isMajor: provisional.isMajor,
        isActive: provisional.isActive,
        strength: provisional.strength,
        holdTicks: provisional.holdTicks,
        tickSize: provisional.tickSize,
        breachBoundary: provisional.breachBoundary,
        isBreached: provisional.breachedBy(
          sessionLow: cumulativeLow,
          sessionHigh: cumulativeHigh,
        ),
        vacuumMultiplier: provisional.vacuumMultiplier,
      ),
    );
  }

  final mergedZones = _mergeTechnicalLiquidityLevels(
    zones: zones,
    technicalLevels: technicalLevels,
    seed: seed,
    referencePrice: referencePrice,
    gridStep: gridStep,
    market: market,
    lowerPrice: safeLower,
    upperPrice: safeUpper,
    sessionLow: cumulativeLow,
    sessionHigh: cumulativeHigh,
  );
  return MarketStructuralLiquidityMap(
    seed: seed,
    referencePrice: referencePrice,
    gridStep: gridStep,
    lowerPrice: safeLower,
    upperPrice: safeUpper,
    zones: mergedZones,
  );
}

List<MarketStructuralLiquidityZone> _mergeTechnicalLiquidityLevels({
  required List<MarketStructuralLiquidityZone> zones,
  required Iterable<MarketTechnicalLevel> technicalLevels,
  required int seed,
  required double referencePrice,
  required double gridStep,
  required String market,
  required double lowerPrice,
  required double upperPrice,
  required double sessionLow,
  required double sessionHigh,
}) {
  final result = List<MarketStructuralLiquidityZone>.from(zones);
  final orderedTechnical =
      technicalLevels
          .where(
            (level) =>
                level.periodWeeks > 0 &&
                level.price.isFinite &&
                level.price > 0 &&
                level.strength.isFinite &&
                level.strength > 0 &&
                level.holdTicks > 0,
          )
          .toList(growable: false)
        ..sort((left, right) => right.periodWeeks.compareTo(left.periodWeeks));

  for (final technical in orderedTechnical) {
    final tick = sharedMarketTickSize(technical.price, market: market);
    if (!tick.isFinite || tick <= 0) continue;
    final technicalPrice = (technical.price / tick).round() * tick;
    if (technicalPrice < lowerPrice - 0.000001 ||
        technicalPrice > upperPrice + 0.000001) {
      continue;
    }
    final gridMergeDistance = gridStep * 0.12;
    final tickMergeDistance = tick * 2;
    final mergeDistance = gridMergeDistance > tickMergeDistance
        ? gridMergeDistance
        : tickMergeDistance;
    final technicalIsSupport = technicalPrice <= referencePrice + 0.000001;
    var nearestIndex = -1;
    var nearestDistance = double.infinity;
    for (var index = 0; index < result.length; index += 1) {
      final candidateIsSupport =
          result[index].price <= referencePrice + 0.000001;
      if (candidateIsSupport != technicalIsSupport) continue;
      final distance = (result[index].price - technicalPrice).abs();
      if (distance <= mergeDistance + 0.000001 && distance < nearestDistance) {
        nearestIndex = index;
        nearestDistance = distance;
      }
    }

    if (nearestIndex >= 0) {
      final current = result[nearestIndex];
      final periods = <int>{
        ...current.technicalPeriods,
        technical.periodWeeks,
      }.toList(growable: false)..sort();
      final stronger = current.strength > technical.strength
          ? current.strength
          : technical.strength;
      final confluenceBonus = current.technicalPeriods.isNotEmpty
          ? 0.35
          : current.isPsychological && current.isActive
          ? 0.65
          : 0.35;
      final combinedStrength = (stronger + confluenceBonus)
          .clamp(3.0, 6.5)
          .toDouble();
      final strongerHold = current.holdTicks > technical.holdTicks
          ? current.holdTicks
          : technical.holdTicks;
      final combinedHold = (strongerHold + 1).clamp(1, 14);
      final kind = current.price <= referencePrice + 0.000001
          ? MarketLiquidityZoneKind.support
          : MarketLiquidityZoneKind.resistance;
      final breachBoundary = _structuralBreachBoundary(
        price: current.price,
        kind: kind,
        holdTicks: combinedHold,
        market: market,
        lowerPrice: lowerPrice,
        upperPrice: upperPrice,
      );
      final provisional = MarketStructuralLiquidityZone(
        price: current.price,
        kind: kind,
        isMajor: current.isMajor,
        isActive: true,
        strength: combinedStrength,
        holdTicks: combinedHold,
        tickSize: current.tickSize,
        breachBoundary: breachBoundary,
        isBreached: false,
        vacuumMultiplier: (current.vacuumMultiplier - 0.04)
            .clamp(0.35, 0.65)
            .toDouble(),
        isPsychological: current.isPsychological,
        technicalPeriods: List<int>.unmodifiable(periods),
      );
      result[nearestIndex] = _withStructuralBreachState(
        provisional,
        sessionLow: sessionLow,
        sessionHigh: sessionHigh,
      );
      continue;
    }

    final kind = technicalPrice <= referencePrice + 0.000001
        ? MarketLiquidityZoneKind.support
        : MarketLiquidityZoneKind.resistance;
    final breachBoundary = _structuralBreachBoundary(
      price: technicalPrice,
      kind: kind,
      holdTicks: technical.holdTicks,
      market: market,
      lowerPrice: lowerPrice,
      upperPrice: upperPrice,
    );
    final absoluteTickIndex = (technicalPrice / tick).round();
    final provisional = MarketStructuralLiquidityZone(
      price: technicalPrice,
      kind: kind,
      isMajor: false,
      isActive: true,
      strength: technical.strength.clamp(3.0, 5.0).toDouble(),
      holdTicks: technical.holdTicks.clamp(1, 14),
      tickSize: tick,
      breachBoundary: breachBoundary,
      isBreached: false,
      vacuumMultiplier:
          0.40 + _structuralUnit(seed, absoluteTickIndex, 6211) * 0.20,
      isPsychological: false,
      technicalPeriods: <int>[technical.periodWeeks],
    );
    result.add(
      _withStructuralBreachState(
        provisional,
        sessionLow: sessionLow,
        sessionHigh: sessionHigh,
      ),
    );
  }
  result.sort((left, right) => left.price.compareTo(right.price));
  return result;
}

MarketStructuralLiquidityZone _withStructuralBreachState(
  MarketStructuralLiquidityZone zone, {
  required double sessionLow,
  required double sessionHigh,
}) => MarketStructuralLiquidityZone(
  price: zone.price,
  kind: zone.kind,
  isMajor: zone.isMajor,
  isActive: zone.isActive,
  strength: zone.strength,
  holdTicks: zone.holdTicks,
  tickSize: zone.tickSize,
  breachBoundary: zone.breachBoundary,
  isBreached: zone.breachedBy(sessionLow: sessionLow, sessionHigh: sessionHigh),
  vacuumMultiplier: zone.vacuumMultiplier,
  isPsychological: zone.isPsychological,
  technicalPeriods: zone.technicalPeriods,
);

double _structuralBreachBoundary({
  required double price,
  required MarketLiquidityZoneKind kind,
  required int holdTicks,
  required String market,
  required double lowerPrice,
  required double upperPrice,
}) {
  final tick = sharedMarketTickSize(price, market: market);
  final rawBoundary = switch (kind) {
    MarketLiquidityZoneKind.support => price - tick * holdTicks,
    MarketLiquidityZoneKind.resistance => price + tick * holdTicks,
  };
  final bounded = switch (kind) {
    MarketLiquidityZoneKind.support =>
      rawBoundary < lowerPrice ? lowerPrice : rawBoundary,
    MarketLiquidityZoneKind.resistance =>
      rawBoundary > upperPrice ? upperPrice : rawBoundary,
  };
  final boundaryTick = sharedMarketTickSize(bounded, market: market);
  return ((bounded / boundaryTick).round() * boundaryTick)
      .clamp(lowerPrice, upperPrice)
      .toDouble();
}

int _nearestMinorGridIndex({
  required double referencePrice,
  required double gridStep,
  required bool searchDown,
}) {
  var index = searchDown
      ? (referencePrice / gridStep).floor()
      : (referencePrice / gridStep).ceil();
  if (searchDown && index * gridStep >= referencePrice - 0.000001) {
    index -= 1;
  }
  if (!searchDown && index * gridStep <= referencePrice + 0.000001) {
    index += 1;
  }
  while (index.isEven) {
    index += searchDown ? -1 : 1;
  }
  return index;
}

int _structuralHash(int seed, int absoluteGridIndex, int salt) {
  var hash =
      (seed ^ (absoluteGridIndex * 0x45d9f3b) ^ (salt * 0x27d4eb2d)) &
      0x7fffffff;
  hash = ((hash ^ (hash >> 16)) * 0x45d9f3b) & 0x7fffffff;
  hash = ((hash ^ (hash >> 16)) * 0x45d9f3b) & 0x7fffffff;
  return (hash ^ (hash >> 16)) & 0x7fffffff;
}

double _structuralUnit(int seed, int absoluteGridIndex, int salt) =>
    (_structuralHash(seed, absoluteGridIndex, salt) % 10000) / 9999;
