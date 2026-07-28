import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_liquidity_zones.dart';
import 'package:millennium_capital/game/market_quote.dart';
import 'package:millennium_capital/game/market_tick.dart';
import 'package:millennium_capital/game/order_book.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('material shock halt is deterministic and lasts five minutes', () {
    const seed = 'material-halt-audit';
    FictionalMarketEvent? target;
    DateTime? targetDate;
    for (var offset = 0; offset < 3650 && target == null; offset += 1) {
      final date = DateTime(2000, 1, 1).add(Duration(days: offset));
      for (final event in fictionalMarketEventsForDate(seed, date)) {
        if (event.tone == NewsTone.shock &&
            event.impactPct <= -marketMaterialNewsHaltImpactRate &&
            event.revealMinute >= krxOpenMinute &&
            event.revealMinute < krxContinuousEndMinute) {
          target = event;
          targetDate = date;
          break;
        }
      }
    }
    expect(target, isNotNull);
    expect(targetDate, isNotNull);
    final event = target!;
    expect(
      marketMaterialNewsTradingHaltAt(
        simulationSeed: seed,
        date: targetDate!,
        assetId: event.companyId,
        minute: event.revealMinute,
      )?.id,
      event.id,
    );
    expect(
      marketMaterialNewsTradingHaltAt(
        simulationSeed: seed,
        date: targetDate,
        assetId: event.companyId,
        minute: event.revealMinute + marketMaterialNewsHaltMinutes - 1,
      ),
      isNotNull,
    );
    expect(
      marketMaterialNewsTradingHaltAt(
        simulationSeed: seed,
        date: targetDate,
        assetId: event.companyId,
        minute: event.revealMinute + marketMaterialNewsHaltMinutes,
      ),
      isNull,
    );
  });

  test('management risk requires insolvency or combined cash-flow stress', () {
    const healthy = FictionalFinancialSnapshot(
      period: '2000-03-31',
      revenue: 1000,
      operatingProfit: 100,
      consensusOperatingProfit: 90,
      netIncome: 80,
      operatingCashFlow: 90,
      cash: 300,
      debt: 200,
      equity: 500,
      sharesOutstanding: 100,
      orderBacklog: 0,
    );
    expect(marketFinancialSnapshotIsManagementRisk(healthy), isFalse);
    expect(
      marketFinancialSnapshotIsManagementRisk(
        FictionalFinancialSnapshot(
          period: healthy.period,
          revenue: healthy.revenue,
          operatingProfit: -100,
          consensusOperatingProfit: healthy.consensusOperatingProfit,
          netIncome: -120,
          operatingCashFlow: -150,
          cash: 10,
          debt: 1200,
          equity: 100,
          sharesOutstanding: healthy.sharesOutstanding,
          orderBacklog: healthy.orderBacklog,
        ),
      ),
      isTrue,
    );
    expect(
      marketFinancialSnapshotIsManagementRisk(
        FictionalFinancialSnapshot(
          period: healthy.period,
          revenue: healthy.revenue,
          operatingProfit: -100,
          consensusOperatingProfit: healthy.consensusOperatingProfit,
          netIncome: -120,
          operatingCashFlow: -150,
          cash: 0,
          debt: 100,
          equity: 0,
          sharesOutstanding: healthy.sharesOutstanding,
          orderBacklog: healthy.orderBacklog,
        ),
      ),
      isTrue,
    );
  });

  test(
    'authoritative quote resolves the exact asset, date, minute, and price',
    () async {
      const engine = GameEngine();
      final universe = await FictionalMarketUniverse.load(
        throughDate: DateTime(2000, 1, 4),
      );
      final state = engine
          .createNewGame('시세 서비스 테스트')
          .copyWith(day: 4, marketMinute: 9 * 60);

      final quote = resolveMarketTradeQuote(universe, state, 'hanbit_telecom');

      expect(quote, isNotNull);
      expect(quote!.asset.code, '1001');
      expect(quote.quoteDate, '2000-01-04');
      expect(quote.marketMinute, 9 * 60);
      expect(quote.unitPrice, greaterThan(0));
      expect(quote.isTradingDay, isTrue);
    },
  );

  test('14:49 to 14:50 has no hidden depth-gate jump across 20 seeds', () {
    for (var seed = 0; seed < 20; seed += 1) {
      final officialClose = 9000 + (seed % 11) * 100.0;
      final path = generatedFullMarketDayPath(
        previousClose: 10000,
        officialClose: officialClose,
        seed: 71000 + seed,
        market: '미래시장',
      );
      final priorRates = <double>[
        for (
          var minute = krxContinuousEndMinute - 30;
          minute < krxContinuousEndMinute;
          minute += 1
        )
          ((path[marketTickForMinute(minute)] -
                      path[marketTickForMinute(minute - 1)]) /
                  path[marketTickForMinute(minute - 1)])
              .abs(),
      ];
      final boundaryRate =
          ((path[marketTickForMinute(krxContinuousEndMinute)] -
                      path[marketTickForMinute(krxContinuousEndMinute - 1)]) /
                  path[marketTickForMinute(krxContinuousEndMinute - 1)])
              .abs();

      expect(
        boundaryRate,
        lessThanOrEqualTo(priorRates.reduce(math.max) + 0.000000001),
        reason: 'seed $seed produced a 14:50 jump',
      );
    }
  });
  test('unknown assets cannot obtain an authoritative quote', () async {
    const engine = GameEngine();
    final universe = await FictionalMarketUniverse.load(
      throughDate: DateTime(2000, 1, 4),
    );
    final state = engine.createNewGame('시세 거부 테스트').copyWith(day: 4);

    expect(resolveMarketTradeQuote(universe, state, 'fake'), isNull);
  });

  test('a listing day starts from its listing reference, not its close', () {
    final asset = FictionalMarketAsset(
      id: 'new_listing',
      symbol: '900001',
      name: '신규 상장사',
      market: fictionalMainMarket,
      country: 'KR',
      sector: '기타',
      colorHex: '#607D8B',
      currency: 'KRW',
      initialSharesOutstanding: 1000000,
      prices: const {'2003-06-02': 5300},
      generation: 1,
      listedOn: '2003-06-02',
      listingReferencePrice: 5000,
    );
    final date = DateTime(2003, 6, 2);

    expect(asset.previousCloseBefore('2003-06-02'), isNull);
    expect(asset.unadjustedReferenceCloseFor('2003-06-02'), 5000);

    final path = generatedMarketDayPathForAsset(
      asset: asset,
      simulationSeed: 'listing-reference-regression',
      date: date,
      previousClose: asset.unadjustedReferenceCloseFor('2003-06-02'),
      officialClose: 5300,
    );

    expect(path.take(generatedPreOpenTicks), everyElement(5000));
    expect(path[marketTickForMinute(marketDayStartMinute)], 5000);
    expect(path[marketTickForMinute(krxCloseMinute)], 5300);
    expect(asset.isIpoFirstTradingDay(date), isTrue);
    expect(
      marketDailyPriceRange(
        previousClose: 5000,
        date: date,
        isIpoFirstTradingDay: true,
      ),
      (lower: 4250, upper: 5750),
    );
  });

  test(
    'modern IPO path uses the offering-price range only on its first day',
    () {
      final asset = FictionalMarketAsset(
        id: 'modern_listing',
        symbol: '900002',
        name: '현대 신규 상장사',
        market: fictionalMainMarket,
        country: 'KR',
        sector: '기타',
        colorHex: '#607D8B',
        currency: 'KRW',
        initialSharesOutstanding: 1000000,
        prices: const {'2023-06-26': 25000, '2023-06-27': 26000},
        generation: 1,
        listedOn: '2023-06-26',
        listingReferencePrice: 10000,
      );
      final listingDate = DateTime(2023, 6, 26);
      final nextDate = DateTime(2023, 6, 27);
      final listingPath = generatedMarketDayPathForAsset(
        asset: asset,
        simulationSeed: 'modern-listing-range-regression',
        date: listingDate,
        previousClose: 10000,
        officialClose: 25000,
      );
      final nextPath = generatedMarketDayPathForAsset(
        asset: asset,
        simulationSeed: 'modern-listing-range-regression',
        date: nextDate,
        previousClose: 25000,
        officialClose: 26000,
      );

      expect(asset.isIpoFirstTradingDay(listingDate), isTrue);
      expect(asset.isIpoFirstTradingDay(nextDate), isFalse);
      expect(
        listingPath.every((price) => price >= 6000 && price <= 40000),
        isTrue,
      );
      expect(listingPath[generatedPreOpenTicks], greaterThan(13000));
      expect(listingPath[krxCloseTick], 25000);
      expect(
        nextPath.every((price) => price >= 17500 && price <= 32500),
        isTrue,
      );
      expect(nextPath[krxCloseTick], 26000);
    },
  );

  test(
    'recent daily candles are deterministic OHLCV with official closes',
    () async {
      final universe = await FictionalMarketUniverse.load(
        seed: 'daily-candle-test-seed',
        throughDate: DateTime(2000, 8, 31),
      );
      final asset = universe.assets.singleWhere(
        (candidate) => candidate.id == 'hanbit_telecom',
      );
      final throughDate = DateTime(2000, 8, 31);
      final candles = recentMarketDailyCandles(
        asset: asset,
        simulationSeed: 'daily-candle-test-seed',
        throughDate: throughDate,
        count: 120,
      );
      final repeated = recentMarketDailyCandles(
        asset: asset,
        simulationSeed: 'daily-candle-test-seed',
        throughDate: throughDate,
        count: 120,
      );

      expect(candles, isNotEmpty);
      expect(candles.length, lessThanOrEqualTo(120));
      expect(identical(candles, repeated), isTrue);
      for (final item in candles) {
        final candle = item.candle;
        final date = DateTime.parse(item.date);
        final reference = asset.marketReferenceCloseOn(
          date,
          previousClose: asset.unadjustedReferenceCloseFor(item.date),
        );
        final marketDay = marketLiquidityDayKey(date);
        expect(candle.high, greaterThanOrEqualTo(candle.open));
        expect(candle.high, greaterThanOrEqualTo(candle.close));
        expect(candle.low, lessThanOrEqualTo(candle.open));
        expect(candle.low, lessThanOrEqualTo(candle.close));
        expect(candle.volume, greaterThan(0));
        expect(
          candle.close,
          asset.quoteAtOrBefore(DateTime.parse(item.date))?.close,
        );
        expect(
          candle.volume,
          gameEstimatedFullDayVolumeUnits(
            assetId: asset.id,
            day: marketDay,
            referencePrice: reference,
            simulationSeed: 'daily-candle-test-seed',
            sharesOutstanding: asset.sharesOutstandingAtOrBefore(date),
          ),
        );
      }
    },
  );

  test('overlapping daily chart windows generate each day path only once', () {
    final prices = <String, double>{};
    var date = DateTime(2000, 1, 3);
    for (var index = 0; index < 320; index += 1) {
      prices[marketDateKey(date)] = 1000 + index.toDouble();
      date = date.add(const Duration(days: 1));
    }
    final asset = FictionalMarketAsset(
      id: 'daily_cache_asset',
      symbol: '900002',
      name: 'Daily cache',
      market: fictionalMainMarket,
      country: 'KR',
      sector: 'Test',
      colorHex: '#607D8B',
      currency: 'KRW',
      initialSharesOutstanding: 1000000,
      prices: prices,
    );
    final throughDate = date.subtract(const Duration(days: 1));

    resetMarketDailyCandleCacheForTesting();
    final shortest = recentMarketDailyCandles(
      asset: asset,
      simulationSeed: 'daily-cache-regression',
      throughDate: throughDate,
      count: 30,
    );
    for (final count in <int>[70, 160, 300]) {
      recentMarketDailyCandles(
        asset: asset,
        simulationSeed: 'daily-cache-regression',
        throughDate: throughDate,
        count: count,
      );
    }
    final longest = recentMarketDailyCandles(
      asset: asset,
      simulationSeed: 'daily-cache-regression',
      throughDate: throughDate,
      count: 300,
    );

    expect(marketDailyCandlePathGenerationCount, 300);
    expect(
      longest.skip(longest.length - shortest.length).map((item) => item.date),
      shortest.map((item) => item.date),
    );
  });

  test('previous-session lead-in reuses the prior asset path and OHLC', () {
    const seed = 'previous-session-asset-path';
    final asset = FictionalMarketAsset(
      id: 'sample',
      symbol: '900001',
      name: 'Sample',
      market: fictionalMainMarket,
      country: 'KR',
      sector: 'Sample',
      colorHex: '#607D8B',
      currency: 'KRW',
      initialSharesOutstanding: 1000000,
      prices: const {
        '2000-01-03': 1000,
        '2000-01-04': 1100,
        '2000-01-05': 1050,
      },
    );
    final previousDate = DateTime(2000, 1, 4);
    final fullLeadIn = marketPreviousSessionLeadInForAsset(
      asset: asset,
      simulationSeed: seed,
      currentDate: DateTime(2000, 1, 5),
      pointCount: generatedRegularTradingTicks,
    );
    final previousSeries = marketPreviousSessionSeriesForAsset(
      asset: asset,
      simulationSeed: seed,
      currentDate: DateTime(2000, 1, 5),
    )!;
    final directPath = generatedMarketDayPathForAsset(
      asset: asset,
      simulationSeed: seed,
      date: previousDate,
      previousClose: 1000,
      officialClose: 1100,
    );
    final expected = <double>[
      ...directPath.sublist(
        generatedPreOpenTicks,
        generatedPreOpenTicks + generatedContinuousTradingTicks,
      ),
      directPath[generatedRegularSessionTicks],
    ];
    final previousCandle = recentMarketDailyCandles(
      asset: asset,
      simulationSeed: seed,
      throughDate: previousDate,
      count: 1,
    ).single.candle;

    expect(fullLeadIn, orderedEquals(expected));
    expect(previousSeries.prices, orderedEquals(expected));
    expect(fullLeadIn.first, previousCandle.open);
    expect(fullLeadIn.reduce(math.max), previousCandle.high);
    expect(fullLeadIn.reduce(math.min), previousCandle.low);
    expect(fullLeadIn.last, previousCandle.close);

    final ninetyPoints = marketPreviousSessionLeadInForAsset(
      asset: asset,
      simulationSeed: seed,
      currentDate: DateTime(2000, 1, 5),
      pointCount: 90,
    );
    final eightyNinePoints = marketPreviousSessionLeadInForAsset(
      asset: asset,
      simulationSeed: seed,
      currentDate: DateTime(2000, 1, 5),
      pointCount: 89,
    );
    expect(ninetyPoints.skip(1), orderedEquals(eightyNinePoints));

    final previousVolume = gameEstimatedFullDayVolumeUnits(
      assetId: asset.id,
      day: marketLiquidityDayKey(previousDate),
      referencePrice: previousSeries.referenceClose,
      simulationSeed: seed,
      sharesOutstanding: asset.sharesOutstandingAtOrBefore(previousDate),
    );
    for (final interval in <int>[3, 5, 10]) {
      final candles = aggregateMarketCandles(
        previousSeries.prices,
        interval,
        seed: marketStockSeed('$seed:${asset.code}', previousDate),
        startMinuteOffset: -previousSeries.prices.length,
        totalVolume: previousVolume.toDouble(),
        market: asset.market,
      );
      expect(
        candles.fold<double>(0, (sum, candle) => sum + candle.volume),
        previousVolume,
      );
      expect(candles.first.startMinute, -previousSeries.prices.length);
      expect(
        candles
            .skip(1)
            .every(
              (candle) =>
                  (candle.startMinute - candles.first.startMinute) % interval ==
                  0,
            ),
        isTrue,
      );
    }
  });

  test('weekly monthly and yearly candles preserve OHLCV semantics', () {
    const daily = <MarketDatedCandle>[
      MarketDatedCandle(
        date: '2000-01-03',
        candle: MarketCandle(
          open: 100,
          high: 120,
          low: 90,
          close: 110,
          startMinute: 0,
          volume: 10,
        ),
      ),
      MarketDatedCandle(
        date: '2000-01-07',
        candle: MarketCandle(
          open: 110,
          high: 130,
          low: 105,
          close: 125,
          startMinute: 1,
          volume: 20,
        ),
      ),
      MarketDatedCandle(
        date: '2000-01-10',
        candle: MarketCandle(
          open: 125,
          high: 140,
          low: 120,
          close: 135,
          startMinute: 2,
          volume: 30,
        ),
      ),
      MarketDatedCandle(
        date: '2000-02-01',
        candle: MarketCandle(
          open: 135,
          high: 150,
          low: 130,
          close: 145,
          startMinute: 3,
          volume: 40,
        ),
      ),
      MarketDatedCandle(
        date: '2001-01-02',
        candle: MarketCandle(
          open: 145,
          high: 160,
          low: 140,
          close: 155,
          startMinute: 4,
          volume: 50,
        ),
      ),
    ];

    final weekly = aggregateMarketDatedCandles(
      daily,
      period: MarketCandlePeriod.week,
    );
    expect(weekly, hasLength(4));
    expect(weekly.first.candle.open, 100);
    expect(weekly.first.candle.high, 130);
    expect(weekly.first.candle.low, 90);
    expect(weekly.first.candle.close, 125);
    expect(weekly.first.candle.volume, 30);

    final monthly = aggregateMarketDatedCandles(
      daily,
      period: MarketCandlePeriod.month,
    );
    expect(monthly, hasLength(3));
    expect(monthly.first.candle.open, 100);
    expect(monthly.first.candle.high, 140);
    expect(monthly.first.candle.low, 90);
    expect(monthly.first.candle.close, 135);
    expect(monthly.first.candle.volume, 60);

    final yearly = aggregateMarketDatedCandles(
      daily,
      period: MarketCandlePeriod.year,
      maxBuckets: 1,
    );
    expect(yearly, hasLength(1));
    expect(yearly.single.candle.open, 145);
    expect(yearly.single.candle.close, 155);
  });

  test(
    'today candle exposes only prices completed by the current minute',
    () async {
      const seed = 'partial-daily-candle-test-seed';
      final universe = await FictionalMarketUniverse.load(
        seed: seed,
        throughDate: DateTime(2000, 8, 31),
      );
      final asset = universe.assets.singleWhere(
        (candidate) => candidate.id == 'hanbit_telecom',
      );
      final throughDate = DateTime(2000, 8, 31);
      final quote = asset.quoteAtOrBefore(throughDate)!;
      final rawPreviousClose = asset.previousCloseBefore(quote.date)!;
      final path = generatedMarketDayPathForAsset(
        asset: asset,
        simulationSeed: seed,
        date: throughDate,
        previousClose: rawPreviousClose,
        officialClose: quote.close,
      );

      final preOpen = recentMarketDailyCandles(
        asset: asset,
        simulationSeed: seed,
        throughDate: throughDate,
        count: 20,
        visibleThroughMinute: marketDayStartMinute,
      );
      final noon = recentMarketDailyCandles(
        asset: asset,
        simulationSeed: seed,
        throughDate: throughDate,
        count: 20,
        visibleThroughMinute: 12 * 60,
      );
      final complete = recentMarketDailyCandles(
        asset: asset,
        simulationSeed: seed,
        throughDate: throughDate,
        count: 20,
        visibleThroughMinute: krxCloseMinute,
      );
      final noonPathIndex = marketTickForMinute(12 * 60);
      final visibleNoonPrices = path.sublist(
        generatedPreOpenTicks,
        noonPathIndex + 1,
      );

      expect(preOpen.last.date, isNot(quote.date));
      expect(noon.last.date, quote.date);
      expect(noon.last.candle.close, path[noonPathIndex]);
      expect(
        noon.last.candle.high,
        visibleNoonPrices.reduce((left, right) => left > right ? left : right),
      );
      expect(
        noon.last.candle.low,
        visibleNoonPrices.reduce((left, right) => left < right ? left : right),
      );
      expect(complete.last.candle.close, quote.close);
    },
  );

  test(
    'event contribution stays out of the path until its public reveal',
    () async {
      const seed = 'event-causality-test-seed';
      final universe = await FictionalMarketUniverse.load(
        seed: seed,
        throughDate: DateTime(2004, 12, 31),
      );
      FictionalMarketAsset? selectedAsset;
      DateTime? selectedDate;
      List<MarketTimedImpact> selectedImpacts = const <MarketTimedImpact>[];
      for (final asset in universe.assets.take(60)) {
        for (
          var date = DateTime(2001, 1, 1);
          date.isBefore(DateTime(2005, 1, 1));
          date = date.add(const Duration(days: 1))
        ) {
          final quote = asset.quoteAtOrBefore(date);
          if (quote == null || !quote.isExactDate) continue;
          final impacts = marketTimedImpactsForAsset(
            simulationSeed: seed,
            date: date,
            asset: asset,
          );
          if (impacts.isEmpty) continue;
          selectedAsset = asset;
          selectedDate = date;
          selectedImpacts = impacts;
          break;
        }
        if (selectedAsset != null) break;
      }

      expect(selectedAsset, isNotNull);
      final asset = selectedAsset!;
      final date = selectedDate!;
      final quote = asset.quoteAtOrBefore(date)!;
      final rawPreviousClose = asset.previousCloseBefore(quote.date)!;
      final previousClose = asset.marketReferenceCloseOn(
        date,
        previousClose: rawPreviousClose,
      );
      final dailyLimitRate = marketDailyPriceLimitRate(date);
      final positiveImpact = selectedImpacts.fold<double>(
        0,
        (sum, impact) => impact.impactRate > 0 ? sum + impact.impactRate : sum,
      );
      final negativeImpact = selectedImpacts.fold<double>(
        0,
        (sum, impact) => impact.impactRate < 0 ? sum + impact.impactRate : sum,
      );
      final positiveScale = positiveImpact <= 0
          ? 0.0
          : math.min(positiveImpact, dailyLimitRate * 0.85) / positiveImpact;
      final negativeScale = negativeImpact >= 0
          ? 0.0
          : math.max(negativeImpact, -dailyLimitRate * 0.85) / negativeImpact;
      final appliedImpact = selectedImpacts.fold<double>(
        0,
        (sum, impact) =>
            sum +
            impact.impactRate *
                (impact.impactRate >= 0 ? positiveScale : negativeScale),
      );
      final baselineClose = marketSnapPrice(
        quote.close - previousClose * appliedImpact,
        market: asset.market,
      );
      final isIpoFirstTradingDay = asset.isIpoFirstTradingDay(date);
      final priceRange = marketDailyPriceRange(
        previousClose: previousClose,
        date: date,
        market: asset.market,
        isIpoFirstTradingDay: isIpoFirstTradingDay,
      );
      final structuralLiquidity = buildMarketStructuralLiquidityMap(
        worldSeed: seed,
        assetId: asset.id,
        market: asset.market,
        referencePrice: previousClose,
        lowerPrice: priceRange.lower,
        upperPrice: priceRange.upper,
        technicalLevels: marketTechnicalLevelsForAsset(
          asset: asset,
          sessionDate: date,
          referencePrice: previousClose,
        ),
      );
      final withEvent = generatedMarketDayPathForAsset(
        asset: asset,
        simulationSeed: seed,
        date: date,
        previousClose: rawPreviousClose,
        officialClose: quote.close,
      );
      final withoutEvent = generatedFullMarketDayPath(
        previousClose: previousClose,
        officialClose: baselineClose,
        seed: marketStockSeed('$seed:${asset.code}', date),
        dailyLimitRate: dailyLimitRate,
        market: asset.market,
        structuralLiquidity: structuralLiquidity,
        lowerPriceLimit: priceRange.lower,
        upperPriceLimit: priceRange.upper,
        useIpoOpeningDiscovery: marketUsesModernIpoFirstDayPriceRange(
          date: date,
          isIpoFirstTradingDay: isIpoFirstTradingDay,
        ),
      );
      final firstReveal = selectedImpacts
          .map((impact) => impact.revealMinute)
          .reduce((first, second) => first < second ? first : second);
      final beforeRevealTick = marketTickForMinute(firstReveal) - 1;

      expect(
        withEvent.take(beforeRevealTick + 1),
        orderedEquals(withoutEvent.take(beforeRevealTick + 1)),
      );
    },
  );
}
