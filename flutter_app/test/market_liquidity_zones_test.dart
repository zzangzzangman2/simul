import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_liquidity_zones.dart';
import 'package:millennium_capital/game/market_technical_levels.dart';
import 'package:millennium_capital/game/market_tick.dart';

void main() {
  const worldSeed = 'structural-liquidity-world';
  const assetId = 'high_price_electronics';
  const market = '미래시장';
  const referencePrice = 290000.0;
  const lowerPrice = 203000.0;
  const upperPrice = 377000.0;

  MarketStructuralLiquidityMap buildMap({
    String seed = worldSeed,
    String id = assetId,
    double? sessionLow,
    double? sessionHigh,
  }) => buildMarketStructuralLiquidityMap(
    worldSeed: seed,
    assetId: id,
    market: market,
    referencePrice: referencePrice,
    lowerPrice: lowerPrice,
    upperPrice: upperPrice,
    sessionLow: sessionLow,
    sessionHigh: sessionHigh,
  );

  String signature(MarketStructuralLiquidityMap map) => map.zones
      .map(
        (zone) =>
            '${zone.price.toStringAsFixed(0)}:'
            '${zone.kind.name}:'
            '${zone.isMajor}:'
            '${zone.isActive}:'
            '${zone.strength.toStringAsFixed(8)}:'
            '${zone.holdTicks}:'
            '${zone.vacuumMultiplier.toStringAsFixed(8)}',
      )
      .join('|');

  test('290k main-market structure uses a five-thousand-won grid', () {
    expect(
      marketStructuralLiquidityGridStep(price: referencePrice, market: market),
      5000,
    );

    final map = buildMap();
    expect(map.gridStep, 5000);
    expect(map.zones, isNotEmpty);
    for (final zone in map.zones) {
      expect(zone.price % 5000, 0);
      expect(zone.price, inInclusiveRange(lowerPrice, upperPrice));
      expect(isValidMarketOrderPrice(zone.price, market: market), isTrue);
      expect(map.zoneAtPrice(zone.price), same(zone));
    }
  });

  test('world and asset seed is stable but differs for another asset', () {
    final firstSeed = marketStructuralLiquiditySeed(
      worldSeed: worldSeed,
      assetId: assetId,
    );
    final repeatedSeed = marketStructuralLiquiditySeed(
      worldSeed: worldSeed,
      assetId: assetId,
    );
    final otherAssetSeed = marketStructuralLiquiditySeed(
      worldSeed: worldSeed,
      assetId: 'high_price_battery',
    );

    expect(repeatedSeed, firstSeed);
    expect(otherAssetSeed, isNot(firstSeed));

    final first = buildMap();
    final repeated = buildMap();
    final otherAsset = buildMap(id: 'high_price_battery');
    expect(signature(repeated), signature(first));
    expect(signature(otherAsset), isNot(signature(first)));
  });

  test('only selected candidates are active and major zones are strongest', () {
    final map = buildMap();
    final major = map.zones.where((zone) => zone.isMajor).toList();
    final activeMinor = map.zones
        .where((zone) => zone.isActive && !zone.isMajor)
        .toList();
    final inactive = map.zones.where((zone) => !zone.isActive).toList();

    expect(major, isNotEmpty);
    expect(activeMinor, isNotEmpty);
    expect(inactive, isNotEmpty);
    expect(major.every((zone) => zone.isActive), isTrue);
    expect(inactive.every((zone) => zone.strength == 1), isTrue);
    expect(inactive.every((zone) => zone.holdTicks == 0), isTrue);

    final weakestMajor = major
        .map((zone) => zone.strength)
        .reduce((left, right) => left < right ? left : right);
    final strongestMinor = activeMinor
        .map((zone) => zone.strength)
        .reduce((left, right) => left > right ? left : right);
    expect(weakestMajor, greaterThan(strongestMinor));
  });

  test(
    'broken support stays breached and leaves a thin gap to next support',
    () {
      final calm = buildMap(
        sessionLow: referencePrice,
        sessionHigh: referencePrice,
      );
      final support = calm.zoneAtPrice(referencePrice);
      expect(support, isNotNull);
      expect(support!.kind, MarketLiquidityZoneKind.support);
      expect(support.isMajor, isTrue);
      expect(support.isActive, isTrue);
      expect(support.isBreached, isFalse);

      final oneTickSafe = buildMap(
        sessionLow: support.breachBoundary + support.tickSize,
        sessionHigh: referencePrice,
      ).zoneAtPrice(support.price)!;
      expect(oneTickSafe.isBreached, isFalse);

      final brokenMap = buildMap(
        sessionLow: support.breachBoundary,
        sessionHigh: referencePrice,
      );
      final broken = brokenMap.zoneAtPrice(support.price)!;
      expect(broken.isActive, isTrue);
      expect(broken.isBreached, isTrue);
      expect(
        broken.breachedBy(
          sessionLow: support.breachBoundary,
          sessionHigh: referencePrice,
        ),
        isTrue,
      );

      final nextSupport = brokenMap.nearestActiveZoneBelow(support.price);
      expect(nextSupport, isNotNull);
      expect(nextSupport!.kind, MarketLiquidityZoneKind.support);
      expect(nextSupport.isBreached, isFalse);

      final gapProbe = (support.price + nextSupport.price) / 2;
      expect(brokenMap.vacuumMultiplierAt(gapProbe), lessThan(1));
      expect(
        brokenMap.vacuumMultiplierAt(gapProbe),
        lessThanOrEqualTo(broken.vacuumMultiplier),
      );
      expect(brokenMap.vacuumMultiplierAt(nextSupport.price), 1);

      final rebuilt = buildMap(
        sessionLow: support.breachBoundary - support.tickSize,
        sessionHigh: referencePrice,
      ).zoneAtPrice(support.price)!;
      expect(
        rebuilt.isBreached,
        isTrue,
        reason: '누적 저가가 돌파선 아래인 동안 화면을 다시 만들어도 벽이 부활하면 안 된다.',
      );
    },
  );

  test(
    'broken resistance behaves symmetrically and leaves an upward vacuum',
    () {
      final calm = buildMap(
        sessionLow: referencePrice,
        sessionHigh: referencePrice,
      );
      final resistance = calm.nearestActiveZoneAbove(referencePrice);
      expect(resistance, isNotNull);
      expect(resistance!.kind, MarketLiquidityZoneKind.resistance);
      expect(resistance.isBreached, isFalse);

      final oneTickSafe = buildMap(
        sessionLow: referencePrice,
        sessionHigh: resistance.breachBoundary - resistance.tickSize,
      ).zoneAtPrice(resistance.price)!;
      expect(oneTickSafe.isBreached, isFalse);

      final brokenMap = buildMap(
        sessionLow: referencePrice,
        sessionHigh: resistance.breachBoundary,
      );
      final broken = brokenMap.zoneAtPrice(resistance.price)!;
      expect(broken.isActive, isTrue);
      expect(broken.isBreached, isTrue);

      final nextResistance = brokenMap.nearestActiveZoneAbove(resistance.price);
      expect(nextResistance, isNotNull);
      expect(nextResistance!.kind, MarketLiquidityZoneKind.resistance);
      expect(nextResistance.isBreached, isFalse);

      final gapProbe = (resistance.price + nextResistance.price) / 2;
      expect(brokenMap.vacuumMultiplierAt(gapProbe), lessThan(1));
      expect(
        brokenMap.vacuumMultiplierAt(gapProbe),
        lessThanOrEqualTo(broken.vacuumMultiplier),
      );
      expect(brokenMap.vacuumMultiplierAt(nextResistance.price), 1);
    },
  );

  test('all structural zones obey tick sizes and historical daily bands', () {
    final cases = <({DateTime date, String market, double close})>[
      (date: DateTime(2014, 6, 20), market: '미래시장', close: 99900),
      (date: DateTime(2016, 6, 20), market: '미래시장', close: 100000),
      (date: DateTime(2016, 6, 20), market: '미래시장', close: 499500),
      (date: DateTime(2016, 6, 20), market: '미래시장', close: 500000),
      (date: DateTime(2016, 6, 20), market: '도전시장', close: 290000),
    ];

    for (final testCase in cases) {
      final range = marketDailyPriceRange(
        previousClose: testCase.close,
        date: testCase.date,
        market: testCase.market,
      );
      final map = buildMarketStructuralLiquidityMap(
        worldSeed: worldSeed,
        assetId: 'band-${testCase.market}-${testCase.close.toStringAsFixed(0)}',
        market: testCase.market,
        referencePrice: testCase.close,
        lowerPrice: range.lower,
        upperPrice: range.upper,
      );

      expect(map.zones, isNotEmpty);
      for (final zone in map.zones) {
        expect(zone.price, inInclusiveRange(range.lower, range.upper));
        expect(
          isValidMarketOrderPrice(zone.price, market: testCase.market),
          isTrue,
        );
        expect(
          isValidMarketOrderPrice(zone.breachBoundary, market: testCase.market),
          isTrue,
        );
        expect(zone.breachBoundary, inInclusiveRange(range.lower, range.upper));
        expect(
          zone.tickSize,
          marketTickSize(zone.price, market: testCase.market),
        );
      }

      final edgeSupport = map.activeZones
          .where((zone) => zone.kind == MarketLiquidityZoneKind.support)
          .firstOrNull;
      final edgeResistance = map.activeZones
          .where((zone) => zone.kind == MarketLiquidityZoneKind.resistance)
          .lastOrNull;
      if (edgeSupport != null) {
        final rebuilt = buildMarketStructuralLiquidityMap(
          worldSeed: worldSeed,
          assetId:
              'band-${testCase.market}-${testCase.close.toStringAsFixed(0)}',
          market: testCase.market,
          referencePrice: testCase.close,
          lowerPrice: range.lower,
          upperPrice: range.upper,
          sessionLow: edgeSupport.breachBoundary,
          sessionHigh: testCase.close,
        );
        expect(rebuilt.zoneAtPrice(edgeSupport.price)!.isBreached, isTrue);
      }
      if (edgeResistance != null) {
        final rebuilt = buildMarketStructuralLiquidityMap(
          worldSeed: worldSeed,
          assetId:
              'band-${testCase.market}-${testCase.close.toStringAsFixed(0)}',
          market: testCase.market,
          referencePrice: testCase.close,
          lowerPrice: range.lower,
          upperPrice: range.upper,
          sessionLow: testCase.close,
          sessionHigh: edgeResistance.breachBoundary,
        );
        expect(rebuilt.zoneAtPrice(edgeResistance.price)!.isBreached, isTrue);
      }
    }
  });

  test(
    'active support holds, breaks into a fast vacuum, then catches at next zone',
    () {
      final structure = _structuralTraversalFixture(
        kind: MarketLiquidityZoneKind.support,
      );
      final structured = _fixtureMarketPath(
        seed: 0,
        officialClose: 270000,
        structure: structure,
      );
      final baseline = _fixtureMarketPath(seed: 0, officialClose: 270000);
      final continuous = _continuousPrices(structured);
      final baselineContinuous = _continuousPrices(baseline);

      expect(
        _longestPriceRun(continuous, 285000),
        greaterThanOrEqualTo(2),
        reason: '첫 28만5천원 지지벽은 한 번의 틱으로 즉시 무너지면 안 된다.',
      );
      final breakIndex = _firstBreakAfterTouch(
        continuous,
        zonePrice: 285000,
        direction: -1,
      );
      expect(breakIndex, greaterThanOrEqualTo(0));
      final firstSupport = structure.zoneAtPrice(285000)!;
      expect(
        continuous[breakIndex],
        lessThanOrEqualTo(firstSupport.breachBoundary),
        reason: '가격 경로의 내부 break와 호가 재생성용 sessionLow가 같은 순간 깨져야 한다.',
      );
      final extrema = _prefixExtrema(continuous, breakIndex);
      final rebuilt = _rebuildTraversalMap(
        sessionLow: extrema.low,
        sessionHigh: extrema.high,
      );
      expect(rebuilt.zoneAtPrice(firstSupport.price)!.isBreached, isTrue);
      expect(
        _firstFasterMove(
          continuous,
          baselineContinuous,
          afterIndex: breakIndex,
          direction: -1,
        ),
        greaterThanOrEqualTo(0),
        reason: '지지벽 붕괴 뒤에는 같은 하락 흐름에서 일반 장부보다 빠르게 비어야 한다.',
      );

      final nextZoneHit = continuous.indexOf(280000, breakIndex + 1);
      expect(nextZoneHit, greaterThan(breakIndex));
      expect(
        _longestPriceRun(continuous.sublist(nextZoneHit), 280000),
        greaterThanOrEqualTo(2),
        reason: '얇은 구간을 지난 뒤 다음 28만원 지지벽에서는 다시 체류해야 한다.',
      );
      _expectValidStructuredSession(structured, officialClose: 270000);
    },
  );

  test(
    'active resistance mirrors hold break vacuum and next-zone behavior',
    () {
      final structure = _structuralTraversalFixture(
        kind: MarketLiquidityZoneKind.resistance,
      );
      final structured = _fixtureMarketPath(
        seed: 1,
        officialClose: 310000,
        structure: structure,
      );
      final baseline = _fixtureMarketPath(seed: 1, officialClose: 310000);
      final continuous = _continuousPrices(structured);
      final baselineContinuous = _continuousPrices(baseline);

      expect(
        _longestPriceRun(continuous, 295000),
        greaterThanOrEqualTo(2),
        reason: '첫 29만5천원 저항벽도 매수 압력을 여러 분 흡수해야 한다.',
      );
      final breakIndex = _firstBreakAfterTouch(
        continuous,
        zonePrice: 295000,
        direction: 1,
      );
      expect(breakIndex, greaterThanOrEqualTo(0));
      final firstResistance = structure.zoneAtPrice(295000)!;
      expect(
        continuous[breakIndex],
        greaterThanOrEqualTo(firstResistance.breachBoundary),
        reason: '가격 경로의 내부 break와 호가 재생성용 sessionHigh가 같은 순간 깨져야 한다.',
      );
      final extrema = _prefixExtrema(continuous, breakIndex);
      final rebuilt = _rebuildTraversalMap(
        sessionLow: extrema.low,
        sessionHigh: extrema.high,
      );
      expect(rebuilt.zoneAtPrice(firstResistance.price)!.isBreached, isTrue);
      expect(
        _firstFasterMove(
          continuous,
          baselineContinuous,
          afterIndex: breakIndex,
          direction: 1,
        ),
        greaterThanOrEqualTo(0),
        reason: '저항벽 돌파 뒤 상승 구간도 하락 지지선 붕괴와 대칭으로 빨라야 한다.',
      );

      final nextZoneHit = continuous.indexOf(300000, breakIndex + 1);
      expect(nextZoneHit, greaterThan(breakIndex));
      expect(
        _longestPriceRun(continuous.sublist(nextZoneHit), 300000),
        greaterThanOrEqualTo(2),
        reason: '상승 vacuum 뒤 다음 30만원 저항벽에서 다시 체류해야 한다.',
      );
      _expectValidStructuredSession(structured, officialClose: 310000);
    },
  );

  test('technical confluence changes the path deterministically', () {
    const technicalLevels = <MarketTechnicalLevel>[
      MarketTechnicalLevel(
        periodWeeks: 60,
        price: 285000,
        kind: MarketTechnicalLevelKind.support,
        strength: 4.55,
        holdTicks: 8,
        weeklySamples: 60,
      ),
    ];
    final baselineStructure = _structuralTraversalFixture(
      kind: MarketLiquidityZoneKind.support,
    );
    final reinforcedStructure = _structuralTraversalFixture(
      kind: MarketLiquidityZoneKind.support,
      technicalLevels: technicalLevels,
    );
    final baseline = _fixtureMarketPath(
      seed: 0,
      officialClose: 270000,
      structure: baselineStructure,
    );
    final reinforced = _fixtureMarketPath(
      seed: 0,
      officialClose: 270000,
      structure: reinforcedStructure,
    );
    final repeated = _fixtureMarketPath(
      seed: 0,
      officialClose: 270000,
      structure: reinforcedStructure,
    );
    final baselineWall = baselineStructure.zoneAtPrice(285000)!;
    final reinforcedWall = reinforcedStructure.zoneAtPrice(285000)!;

    expect(baselineWall.technicalPeriods, isEmpty);
    expect(reinforcedWall.technicalPeriods, <int>[60]);
    expect(reinforcedWall.confluenceCount, 2);
    expect(reinforcedWall.strength, greaterThan(baselineWall.strength));
    expect(reinforcedWall.holdTicks, greaterThan(baselineWall.holdTicks));
    expect(repeated, orderedEquals(reinforced));
    expect(
      reinforced,
      isNot(orderedEquals(baseline)),
      reason: '동일 시드라도 60주선 합류 벽의 흡수력은 가격 경로에 반영돼야 한다.',
    );
    expect(
      _longestPriceRun(_continuousPrices(reinforced), 285000),
      greaterThanOrEqualTo(
        _longestPriceRun(_continuousPrices(baseline), 285000),
      ),
    );
    _expectValidStructuredSession(reinforced, officialClose: 270000);
  });
}

const _fixtureReferencePrice = 290000.0;
const _fixtureLowerPrice = 203000.0;
const _fixtureUpperPrice = 377000.0;
const _fixtureMarket = '미래시장';
const _fixtureWorldSeed = 'structural-traversal-world';
const _fixtureAssetId = 'high_price_electronics';

MarketStructuralLiquidityMap _structuralTraversalFixture({
  required MarketLiquidityZoneKind kind,
  Iterable<MarketTechnicalLevel> technicalLevels =
      const <MarketTechnicalLevel>[],
}) {
  final prices = kind == MarketLiquidityZoneKind.support
      ? const <double>[280000, 285000]
      : const <double>[295000, 300000];
  final generated = _rebuildTraversalMap(technicalLevels: technicalLevels);
  return MarketStructuralLiquidityMap(
    seed: generated.seed,
    referencePrice: _fixtureReferencePrice,
    gridStep: 5000,
    lowerPrice: _fixtureLowerPrice,
    upperPrice: _fixtureUpperPrice,
    zones: [for (final price in prices) generated.zoneAtPrice(price)!],
  );
}

MarketStructuralLiquidityMap _rebuildTraversalMap({
  double? sessionLow,
  double? sessionHigh,
  Iterable<MarketTechnicalLevel> technicalLevels =
      const <MarketTechnicalLevel>[],
}) => buildMarketStructuralLiquidityMap(
  worldSeed: _fixtureWorldSeed,
  assetId: _fixtureAssetId,
  market: _fixtureMarket,
  referencePrice: _fixtureReferencePrice,
  lowerPrice: _fixtureLowerPrice,
  upperPrice: _fixtureUpperPrice,
  sessionLow: sessionLow,
  sessionHigh: sessionHigh,
  technicalLevels: technicalLevels,
);

List<double> _fixtureMarketPath({
  required int seed,
  required double officialClose,
  MarketStructuralLiquidityMap? structure,
}) => generatedFullMarketDayPath(
  previousClose: _fixtureReferencePrice,
  officialClose: officialClose,
  seed: seed,
  dailyLimitRate: 0.30,
  market: _fixtureMarket,
  structuralLiquidity: structure,
  lowerPriceLimit: _fixtureLowerPrice,
  upperPriceLimit: _fixtureUpperPrice,
);

List<double> _continuousPrices(List<double> path) => path.sublist(
  generatedPreOpenTicks,
  generatedPreOpenTicks + generatedContinuousTradingTicks,
);

int _longestPriceRun(List<double> values, double price) {
  var longest = 0;
  var current = 0;
  for (final value in values) {
    if (value == price) {
      current += 1;
      if (current > longest) longest = current;
    } else {
      current = 0;
    }
  }
  return longest;
}

int _firstBreakAfterTouch(
  List<double> values, {
  required double zonePrice,
  required int direction,
}) {
  final firstTouch = values.indexOf(zonePrice);
  if (firstTouch < 0) return -1;
  for (var index = firstTouch + 1; index < values.length; index += 1) {
    if ((direction < 0 && values[index] < zonePrice) ||
        (direction > 0 && values[index] > zonePrice)) {
      return index;
    }
  }
  return -1;
}

int _firstFasterMove(
  List<double> structured,
  List<double> baseline, {
  required int afterIndex,
  required int direction,
}) {
  final lastProbe = (afterIndex + 5).clamp(1, structured.length - 1);
  for (var index = afterIndex + 1; index <= lastProbe; index += 1) {
    final structuralDelta = structured[index] - structured[index - 1];
    final baselineDelta = baseline[index] - baseline[index - 1];
    if (direction < 0 && baselineDelta < 0 && structuralDelta < baselineDelta) {
      return index;
    }
    if (direction > 0 && baselineDelta > 0 && structuralDelta > baselineDelta) {
      return index;
    }
  }
  return -1;
}

({double low, double high}) _prefixExtrema(
  List<double> values,
  int throughIndex,
) {
  var low = values.first;
  var high = values.first;
  for (var index = 1; index <= throughIndex; index += 1) {
    final value = values[index];
    if (value < low) low = value;
    if (value > high) high = value;
  }
  return (low: low, high: high);
}

void _expectValidStructuredSession(
  List<double> path, {
  required double officialClose,
}) {
  expect(path, hasLength(generatedSessionTicks + 1));
  expect(path[generatedRegularSessionTicks], officialClose);

  final auctionReferenceIndex =
      generatedPreOpenTicks + generatedContinuousTradingTicks - 1;
  final closeIndex = generatedRegularSessionTicks;
  for (var index = auctionReferenceIndex + 1; index < closeIndex; index += 1) {
    expect(
      path[index],
      path[auctionReferenceIndex],
      reason: '14:50~14:59 동시호가에는 연속매매 가격이 더 움직이면 안 된다.',
    );
  }
  for (final price in path) {
    expect(price, inInclusiveRange(_fixtureLowerPrice, _fixtureUpperPrice));
    expect(isValidMarketOrderPrice(price, market: _fixtureMarket), isTrue);
  }
}
