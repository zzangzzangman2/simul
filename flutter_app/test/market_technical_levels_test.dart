import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_liquidity_zones.dart';
import 'package:millennium_capital/game/market_technical_levels.dart';

void main() {
  const market = 'main';

  group('causal calendar-week moving averages', () {
    test('5/20/60-week SMAs use exact Monday-start weekly closes', () {
      final history = _exactMovingAverageHistory();
      final sessionDate = _dateKey(
        DateTime(2024, 1, 1).add(const Duration(days: 60 * 7)),
      );

      final weekly = marketTechnicalWeeklyCloses(
        dailyCloses: history,
        sessionDate: sessionDate,
      );
      final levels = buildMarketTechnicalLevels(
        adjustedDailyCloses: history,
        sessionDate: sessionDate,
        referencePrice: 90000,
        market: market,
      );
      final byPeriod = {for (final level in levels) level.periodWeeks: level};

      expect(weekly, hasLength(60));
      expect(byPeriod.keys, containsAll(<int>[5, 20, 60]));
      expect(byPeriod[5]!.price, 100000);
      expect(byPeriod[20]!.price, 85000);
      expect(byPeriod[60]!.price, 70000);
      expect(byPeriod[5]!.weeklySamples, 5);
      expect(byPeriod[20]!.weeklySamples, 20);
      expect(byPeriod[60]!.weeklySamples, 60);
      expect(byPeriod[5]!.strength, 3.15);
      expect(byPeriod[20]!.strength, 3.85);
      expect(byPeriod[60]!.strength, 4.55);
      expect(byPeriod[60]!.strength, greaterThan(byPeriod[20]!.strength));
      expect(byPeriod[20]!.strength, greaterThan(byPeriod[5]!.strength));
      expect(byPeriod[5]!.holdTicks, 3);
      expect(byPeriod[20]!.holdTicks, 5);
      expect(byPeriod[60]!.holdTicks, 8);
      expect(byPeriod[5]!.kind, MarketTechnicalLevelKind.resistance);
      expect(byPeriod[20]!.kind, MarketTechnicalLevelKind.support);
      expect(byPeriod[60]!.kind, MarketTechnicalLevelKind.support);
    });

    test(
      'holiday-shortened and partial weeks use only the last public close',
      () {
        final monday = DateTime(2025, 1, 6);
        final history = <MarketTechnicalClose>[
          for (var week = 0; week < 4; week += 1)
            MarketTechnicalClose(
              date: _dateKey(monday.add(Duration(days: week * 7 + 4))),
              close: 100000,
            ),
          MarketTechnicalClose(
            date: _dateKey(monday.add(const Duration(days: 4 * 7))),
            close: 95000,
          ),
          MarketTechnicalClose(
            date: _dateKey(monday.add(const Duration(days: 4 * 7 + 1))),
            close: 100000,
          ),
          MarketTechnicalClose(
            date: _dateKey(monday.add(const Duration(days: 4 * 7 + 2))),
            close: 150000,
          ),
          MarketTechnicalClose(
            date: _dateKey(monday.add(const Duration(days: 4 * 7 + 4))),
            close: 900000,
          ),
        ];
        final wednesday = _dateKey(monday.add(const Duration(days: 4 * 7 + 2)));
        final thursday = _dateKey(monday.add(const Duration(days: 4 * 7 + 3)));

        final beforeWednesdayClose = marketTechnicalWeeklyCloses(
          dailyCloses: history,
          sessionDate: wednesday,
        );
        final afterWednesdayClose = marketTechnicalWeeklyCloses(
          dailyCloses: history,
          sessionDate: thursday,
        );
        final beforeLevel = buildMarketTechnicalLevels(
          adjustedDailyCloses: history,
          sessionDate: wednesday,
          referencePrice: 100000,
          market: market,
        ).single;
        final afterLevel = buildMarketTechnicalLevels(
          adjustedDailyCloses: history,
          sessionDate: thursday,
          referencePrice: 110000,
          market: market,
        ).single;

        expect(beforeWednesdayClose, hasLength(5));
        expect(beforeWednesdayClose.last.close, 100000);
        expect(
          beforeWednesdayClose.last.date,
          _dateKey(monday.add(const Duration(days: 4 * 7 + 1))),
        );
        expect(afterWednesdayClose, hasLength(5));
        expect(afterWednesdayClose.last.close, 150000);
        expect(
          afterWednesdayClose.last.date,
          _dateKey(monday.add(const Duration(days: 4 * 7 + 2))),
        );
        expect(beforeLevel.periodWeeks, 5);
        expect(beforeLevel.price, 100000);
        expect(afterLevel.periodWeeks, 5);
        expect(afterLevel.price, 110000);
        expect(
          afterWednesdayClose.last.close,
          isNot(900000),
          reason: '오늘 이후에 기록된 종가는 기술적 레벨에 새면 안 된다.',
        );
      },
    );
  });

  group('technical levels follow the active price regime', () {
    for (final scenario in <({String name, double first, double second})>[
      (name: '50k to 200k', first: 50000, second: 200000),
      (name: '200k to 50k', first: 200000, second: 50000),
    ]) {
      test('${scenario.name} moves levels and grid into the current band', () {
        final start = DateTime(2022, 1, 3);
        final history = _twoRegimeHistory(
          start: start,
          firstPrice: scenario.first,
          secondPrice: scenario.second,
        );
        final firstSession = start.add(const Duration(days: 60 * 7));
        final secondSession = start.add(const Duration(days: 120 * 7));
        final firstLevels = buildMarketTechnicalLevels(
          adjustedDailyCloses: history,
          sessionDate: _dateKey(firstSession),
          referencePrice: scenario.first,
          market: market,
        );
        final secondLevels = buildMarketTechnicalLevels(
          adjustedDailyCloses: history,
          sessionDate: _dateKey(secondSession),
          referencePrice: scenario.second,
          market: market,
        );
        final firstRange = marketDailyPriceRange(
          previousClose: scenario.first,
          date: firstSession,
          market: market,
        );
        final secondRange = marketDailyPriceRange(
          previousClose: scenario.second,
          date: secondSession,
          market: market,
        );
        final firstMap = buildMarketStructuralLiquidityMap(
          worldSeed: 'price-regime',
          assetId: scenario.name,
          market: market,
          referencePrice: scenario.first,
          lowerPrice: firstRange.lower,
          upperPrice: firstRange.upper,
          technicalLevels: firstLevels,
        );
        final secondMap = buildMarketStructuralLiquidityMap(
          worldSeed: 'price-regime',
          assetId: scenario.name,
          market: market,
          referencePrice: scenario.second,
          lowerPrice: secondRange.lower,
          upperPrice: secondRange.upper,
          technicalLevels: secondLevels,
        );

        expect(firstLevels, hasLength(3));
        expect(
          firstLevels.map((level) => level.price),
          everyElement(scenario.first),
        );
        expect(secondLevels, hasLength(3));
        expect(
          secondLevels.map((level) => level.price),
          everyElement(scenario.second),
        );
        expect(
          firstMap.zones.map((zone) => zone.price),
          everyElement(inInclusiveRange(firstRange.lower, firstRange.upper)),
        );
        expect(
          secondMap.zones.map((zone) => zone.price),
          everyElement(inInclusiveRange(secondRange.lower, secondRange.upper)),
        );
        expect(firstMap.zoneAtPrice(scenario.first), isNotNull);
        expect(secondMap.zoneAtPrice(scenario.second), isNotNull);
        expect(firstMap.zoneAtPrice(scenario.second), isNull);
        expect(secondMap.zoneAtPrice(scenario.first), isNull);
        expect(firstMap.gridStep, isNot(secondMap.gridStep));
      });
    }
  });

  group('technical and psychological confluence', () {
    test('aligned 5/20/60-week levels reinforce one round-price wall', () {
      final history = _flatWeeklyHistory(price: 100000, weeks: 60);
      final sessionDate = _dateKey(
        DateTime(2024, 1, 1).add(const Duration(days: 60 * 7)),
      );
      final levels = buildMarketTechnicalLevels(
        adjustedDailyCloses: history,
        sessionDate: sessionDate,
        referencePrice: 102000,
        market: market,
      );
      final baseMap = buildMarketStructuralLiquidityMap(
        worldSeed: 'confluence-world',
        assetId: 'electronics',
        market: market,
        referencePrice: 102000,
        lowerPrice: 70000,
        upperPrice: 130000,
      );
      final reinforcedMap = buildMarketStructuralLiquidityMap(
        worldSeed: 'confluence-world',
        assetId: 'electronics',
        market: market,
        referencePrice: 102000,
        lowerPrice: 70000,
        upperPrice: 130000,
        technicalLevels: levels,
      );
      final base = baseMap.zoneAtPrice(100000)!;
      final reinforced = reinforcedMap.zoneAtPrice(100000)!;

      expect(levels.map((level) => level.price), everyElement(100000));
      expect(base.isPsychological, isTrue);
      expect(base.technicalPeriods, isEmpty);
      expect(reinforced.isPsychological, isTrue);
      expect(reinforced.technicalPeriods, <int>[5, 20, 60]);
      expect(reinforced.confluenceCount, 4);
      expect(reinforced.isActive, isTrue);
      expect(reinforced.strength, greaterThan(base.strength));
      expect(reinforced.holdTicks, greaterThan(base.holdTicks));
    });

    test('the same absolute level changes from support to resistance', () {
      final history = _flatWeeklyHistory(price: 100000, weeks: 60);
      final sessionDate = _dateKey(
        DateTime(2024, 1, 1).add(const Duration(days: 60 * 7)),
      );
      final supportLevels = buildMarketTechnicalLevels(
        adjustedDailyCloses: history,
        sessionDate: sessionDate,
        referencePrice: 105000,
        market: market,
      );
      final resistanceLevels = buildMarketTechnicalLevels(
        adjustedDailyCloses: history,
        sessionDate: sessionDate,
        referencePrice: 95000,
        market: market,
      );
      final supportMap = buildMarketStructuralLiquidityMap(
        worldSeed: 'role-transition',
        assetId: 'electronics',
        market: market,
        referencePrice: 105000,
        lowerPrice: 50000,
        upperPrice: 150000,
        technicalLevels: supportLevels,
      );
      final resistanceMap = buildMarketStructuralLiquidityMap(
        worldSeed: 'role-transition',
        assetId: 'electronics',
        market: market,
        referencePrice: 95000,
        lowerPrice: 50000,
        upperPrice: 150000,
        technicalLevels: resistanceLevels,
      );
      final support = supportMap.zoneAtPrice(100000)!;
      final resistance = resistanceMap.zoneAtPrice(100000)!;

      expect(
        supportLevels.map((level) => level.kind),
        everyElement(MarketTechnicalLevelKind.support),
      );
      expect(
        resistanceLevels.map((level) => level.kind),
        everyElement(MarketTechnicalLevelKind.resistance),
      );
      expect(support.kind, MarketLiquidityZoneKind.support);
      expect(resistance.kind, MarketLiquidityZoneKind.resistance);
      expect(support.technicalPeriods, <int>[5, 20, 60]);
      expect(resistance.technicalPeriods, <int>[5, 20, 60]);
    });

    test('a breached standalone weekly level does not respawn on rebuild', () {
      final history = _flatWeeklyHistory(price: 286500, weeks: 5);
      final sessionDate = _dateKey(
        DateTime(2024, 1, 1).add(const Duration(days: 5 * 7)),
      );
      final levels = buildMarketTechnicalLevels(
        adjustedDailyCloses: history,
        sessionDate: sessionDate,
        referencePrice: 290000,
        market: market,
      );
      final intactMap = buildMarketStructuralLiquidityMap(
        worldSeed: 'technical-breach',
        assetId: 'electronics',
        market: market,
        referencePrice: 290000,
        lowerPrice: 203000,
        upperPrice: 377000,
        technicalLevels: levels,
      );
      final intact = intactMap.zoneAtPrice(286500)!;
      final breachedMap = buildMarketStructuralLiquidityMap(
        worldSeed: 'technical-breach',
        assetId: 'electronics',
        market: market,
        referencePrice: 290000,
        lowerPrice: 203000,
        upperPrice: 377000,
        sessionLow: intact.breachBoundary,
        sessionHigh: 290000,
        technicalLevels: levels,
      );
      final rebuiltMap = buildMarketStructuralLiquidityMap(
        worldSeed: 'technical-breach',
        assetId: 'electronics',
        market: market,
        referencePrice: 290000,
        lowerPrice: 203000,
        upperPrice: 377000,
        sessionLow: intact.breachBoundary,
        sessionHigh: 290000,
        technicalLevels: levels,
      );
      final breached = breachedMap.zoneAtPrice(286500)!;
      final rebuilt = rebuiltMap.zoneAtPrice(286500)!;

      expect(intact.isPsychological, isFalse);
      expect(intact.technicalPeriods, <int>[5]);
      expect(intact.isBreached, isFalse);
      expect(breached.isBreached, isTrue);
      expect(rebuilt.isBreached, isTrue);
      expect(rebuilt.breachBoundary, breached.breachBoundary);
      expect(rebuilt.strength, breached.strength);
      expect(
        rebuiltMap.vacuumMultiplierAt(rebuilt.price - rebuilt.tickSize),
        lessThan(1),
      );
    });
  });
}

List<MarketTechnicalClose> _exactMovingAverageHistory() {
  final monday = DateTime(2024, 1, 1);
  return <MarketTechnicalClose>[
    for (var week = 0; week < 60; week += 1)
      MarketTechnicalClose(
        date: _dateKey(monday.add(Duration(days: week * 7 + 4))),
        close: week < 40
            ? 62500
            : week < 55
            ? 80000
            : 100000,
      ),
  ];
}

List<MarketTechnicalClose> _flatWeeklyHistory({
  required double price,
  required int weeks,
}) {
  final monday = DateTime(2024, 1, 1);
  return <MarketTechnicalClose>[
    for (var week = 0; week < weeks; week += 1)
      MarketTechnicalClose(
        date: _dateKey(monday.add(Duration(days: week * 7 + 4))),
        close: price,
      ),
  ];
}

List<MarketTechnicalClose> _twoRegimeHistory({
  required DateTime start,
  required double firstPrice,
  required double secondPrice,
}) => <MarketTechnicalClose>[
  for (var week = 0; week < 120; week += 1)
    MarketTechnicalClose(
      date: _dateKey(start.add(Duration(days: week * 7 + 4))),
      close: week < 60 ? firstPrice : secondPrice,
    ),
];

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
