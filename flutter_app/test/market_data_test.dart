import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_tick.dart';

void main() {
  test('market universe reuses the same cached load', () async {
    final cutoff = DateTime(2000, 1, 10);
    final first = FictionalMarketUniverse.load(
      seed: 'cache-identity-test',
      throughDate: cutoff,
      forceRefresh: true,
    );
    final second = FictionalMarketUniverse.load(
      seed: 'cache-identity-test',
      throughDate: cutoff,
    );

    expect(identical(first, second), isTrue);
    expect((await first).assets, isNotEmpty);
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'dated loads share one yearly timeline and reuse a cached superset',
    () async {
      const seed = 'dated-load-test';
      final cutoff = DateTime(2000, 1, 10);
      final buildCountBefore = FictionalMarketUniverse.debugTimelineBuildCount(
        seed,
      );
      final firstFuture = FictionalMarketUniverse.load(
        seed: seed,
        throughDate: cutoff,
        forceRefresh: true,
      );
      final repeatedFuture = FictionalMarketUniverse.load(
        seed: seed,
        throughDate: cutoff,
      );

      expect(identical(firstFuture, repeatedFuture), isTrue);
      final first = await firstFuture;
      expect(
        FictionalMarketUniverse.debugTimelineBuildCount(seed),
        buildCountBefore + 1,
      );
      final hanbit = first.assets.singleWhere(
        (asset) => asset.id == 'hanbit_telecom',
      );
      expect(hanbit.quoteAtOrBefore(cutoff), isNotNull);
      expect(
        first.assets.every(
          (asset) =>
              asset.lastTradeDate == null ||
              !DateTime.parse(asset.lastTradeDate!).isAfter(cutoff),
        ),
        isTrue,
      );

      final later = await FictionalMarketUniverse.load(
        seed: seed,
        throughDate: DateTime(2000, 1, 31),
      );
      final laterHanbit = later.assets.singleWhere(
        (asset) => asset.id == 'hanbit_telecom',
      );
      expect(
        laterHanbit.historyThrough(DateTime(2000, 1, 31)).length,
        greaterThan(hanbit.historyThrough(cutoff).length),
      );
      final yearEnd = await FictionalMarketUniverse.load(
        seed: seed,
        throughDate: DateTime(2000, 12, 31),
      );
      expect(
        FictionalMarketUniverse.debugTimelineBuildCount(seed),
        buildCountBefore + 1,
      );
      expect(
        yearEnd.assets
            .map((asset) => asset.id)
            .toSet()
            .difference(first.assets.map((asset) => asset.id).toSet()),
        isNotEmpty,
      );

      const supersetSeed = 'dated-superset-load-test';
      final supersetBuildCountBefore =
          FictionalMarketUniverse.debugTimelineBuildCount(supersetSeed);
      await FictionalMarketUniverse.load(
        seed: supersetSeed,
        throughDate: DateTime(2001, 1, 8),
        forceRefresh: true,
      );
      await FictionalMarketUniverse.load(
        seed: supersetSeed,
        throughDate: DateTime(2000, 12, 29),
      );
      expect(
        FictionalMarketUniverse.debugTimelineBuildCount(supersetSeed),
        supersetBuildCountBefore + 1,
      );
    },
  );

  test(
    'campaign prewarm survives dated refreshes without leaking future data',
    () async {
      const seed = 'campaign-prewarm-cache-regression';
      final earlyDate = DateTime(2000, 1, 10);
      final earlyDateKey = marketDateKey(earlyDate);
      final buildCountBefore = FictionalMarketUniverse.debugTimelineBuildCount(
        seed,
      );

      await FictionalMarketUniverse.prewarmCampaign(
        seed: seed,
        forceRefresh: true,
      );
      final prewarmBuildCount = FictionalMarketUniverse.debugTimelineBuildCount(
        seed,
      );
      expect(prewarmBuildCount, buildCountBefore + 1);
      expect(FictionalMarketUniverse.isCampaignTimelineCached(seed), isTrue);

      final fullTimeline = await FictionalMarketUniverse.load(seed: seed);
      final futureAsset = fullTimeline.assets.firstWhere(
        (asset) =>
            asset.listedOn != null &&
            asset.listedOn!.compareTo(earlyDateKey) > 0,
      );
      void expectNoFutureData(FictionalMarketUniverse view) {
        final visibleAssetIds = view.assets.map((asset) => asset.id).toSet();
        expect(view.assets.any((asset) => asset.id == futureAsset.id), isFalse);
        for (final asset in view.assets) {
          expect(
            asset.lastTradeDate == null ||
                asset.lastTradeDate!.compareTo(earlyDateKey) <= 0,
            isTrue,
          );
          expect(
            asset.corporateActions.every(
              (action) => marketCorporateActionIsAnnouncedBy(action, earlyDate),
            ),
            isTrue,
          );
          expect(
            asset.appliedEventScales.keys.every(
              (date) => date.compareTo(earlyDateKey) <= 0,
            ),
            isTrue,
          );
          expect(
            asset.relations.every(
              (relation) => visibleAssetIds.contains(relation.relatedAssetId),
            ),
            isTrue,
          );
          expect(
            asset
                    .quoteAtOrBefore(DateTime(2026, 12, 31))
                    ?.date
                    .compareTo(earlyDateKey) ??
                -1,
            lessThanOrEqualTo(0),
          );
        }
      }

      final earlyView = await FictionalMarketUniverse.load(
        seed: seed,
        throughDate: earlyDate,
      );

      expect(
        FictionalMarketUniverse.debugTimelineBuildCount(seed),
        prewarmBuildCount,
      );
      expect(FictionalMarketUniverse.isCampaignTimelineCached(seed), isTrue);
      expectNoFutureData(earlyView);

      final refreshedEarlyView = await FictionalMarketUniverse.load(
        seed: seed,
        throughDate: earlyDate,
        forceRefresh: true,
      );
      final refreshedBuildCount =
          FictionalMarketUniverse.debugTimelineBuildCount(seed);
      expect(refreshedBuildCount, prewarmBuildCount + 1);
      expect(FictionalMarketUniverse.isCampaignTimelineCached(seed), isTrue);
      expectNoFutureData(refreshedEarlyView);

      await FictionalMarketUniverse.load(
        seed: seed,
        throughDate: DateTime(2025, 12, 31),
      );
      expect(
        FictionalMarketUniverse.debugTimelineBuildCount(seed),
        refreshedBuildCount,
        reason: '날짜 제한 뷰가 예열된 전체 캠페인 타임라인을 축소하면 안 된다.',
      );
      expect(FictionalMarketUniverse.isCampaignTimelineCached(seed), isTrue);
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test('as-of views do not leak future market-world state', () {
    final current = FictionalMarketAsset(
      id: 'current',
      symbol: '1001',
      name: 'Current',
      market: fictionalMainMarket,
      country: 'KR',
      sector: 'Test',
      colorHex: '#000000',
      currency: 'KRW',
      initialSharesOutstanding: 1000,
      prices: const {
        '2000-01-03': 1000,
        '2000-01-10': 1100,
        '2000-04-03': 1200,
      },
      appliedEventScales: const {'2000-04-03': 0.8},
      corporateActions: const [
        MarketCorporateAction(
          id: 'future-dividend',
          assetId: 'current',
          type: MarketCorporateActionType.dividend,
          date: '2000-04-03',
          numerator: 1,
          denominator: 1,
          amount: 30,
          currency: 'KRW',
          source: 'test',
        ),
      ],
      delistedOn: '2000-06-01',
      financials: const [
        FictionalFinancialSnapshot(
          period: '1999-12-30',
          revenue: 100,
          operatingProfit: 10,
          consensusOperatingProfit: 9,
          netIncome: 8,
          operatingCashFlow: 11,
          cash: 50,
          debt: 20,
          equity: 80,
          sharesOutstanding: 1000,
          orderBacklog: 40,
        ),
        FictionalFinancialSnapshot(
          period: '2000-03-31',
          revenue: 120,
          operatingProfit: 12,
          consensusOperatingProfit: 11,
          netIncome: 9,
          operatingCashFlow: 13,
          cash: 55,
          debt: 18,
          equity: 88,
          sharesOutstanding: 1000,
          orderBacklog: 45,
        ),
      ],
      relations: const [
        FictionalCompanyRelation(
          relatedAssetId: 'future',
          relatedName: 'Future',
          type: FictionalCompanyRelationType.partner,
          strength: 0.4,
        ),
      ],
    );
    final future = FictionalMarketAsset(
      id: 'future',
      symbol: '2001',
      name: 'Future',
      market: fictionalGrowthMarket,
      country: 'KR',
      sector: 'Test',
      colorHex: '#FFFFFF',
      currency: 'KRW',
      initialSharesOutstanding: 1000,
      prices: const {'2000-04-03': 2000},
      listedOn: '2000-04-03',
    );
    final view = FictionalMarketUniverse(
      schemaVersion: 14,
      sourceName: 'as-of-test',
      assets: [current, future],
    ).asOf(DateTime(2000, 1, 10));

    expect(view.assets.map((asset) => asset.id), ['current']);
    final visible = view.assets.single;
    expect(visible.delistedOn, isNull);
    expect(visible.relations, isEmpty);
    expect(visible.corporateActions, isEmpty);
    expect(visible.appliedEventScales, isEmpty);
    expect(
      visible.financials,
      isEmpty,
      reason:
          '기준일 2000-01-10에는 1999년 결산 잠정치·사업보고서가 '
          '아직 공시되지 않았으므로 미래 실적이 노출되면 안 됩니다.',
    );
    expect(visible.quoteAtOrBefore(DateTime(2000, 12, 31))!.date, '2000-01-10');
    expect(
      visible.quoteAtOrBefore(DateTime(2000, 12, 31))!.isExactDate,
      isFalse,
    );
    expect(visible.corporateActionsOn(DateTime(2000, 4, 3)), isEmpty);
    expect(view.corporateActionsOn(DateTime(2000, 4, 3)), isEmpty);
    final serializedPrices =
        visible.toJson()['prices']! as Map<String, dynamic>;
    expect(serializedPrices.keys, ['2000-01-03', '2000-01-10']);
    expect(identical(view.asOf(DateTime(2001, 1, 1)), view), isTrue);
  });

  test(
    'as-of view exposes a future corporate action only after disclosure',
    () {
      const action = MarketCorporateAction(
        id: 'sample-dividend-2000-02-01',
        assetId: 'sample',
        type: MarketCorporateActionType.dividend,
        date: '2000-02-01',
        amount: 100,
        numerator: 0,
        denominator: 1,
        currency: 'KRW',
        source: 'test',
      );
      final asset = FictionalMarketAsset(
        id: 'sample',
        symbol: '1000',
        name: '샘플',
        market: fictionalMainMarket,
        country: 'KR',
        sector: 'Test',
        colorHex: '#FFFFFF',
        currency: 'KRW',
        initialSharesOutstanding: 1000,
        prices: const {'2000-01-03': 10000, '2000-02-01': 9900},
        corporateActions: const [action],
      );
      final universe = FictionalMarketUniverse(
        schemaVersion: 14,
        sourceName: 'announcement-test',
        assets: [asset],
      );
      final announcementDate = marketCorporateActionAnnouncementDate(action);
      final before = announcementDate.subtract(const Duration(days: 1));

      expect(universe.asOf(before).assets.single.corporateActions, isEmpty);
      final visible = universe.asOf(announcementDate).assets.single;
      expect(visible.corporateActions, const [action]);
      expect(visible.announcedCorporateActionsFrom(announcementDate), const [
        action,
      ]);
    },
  );

  test(
    'corporate calendar covers earnings, audit, AGM, and capital actions',
    () {
      const rightsIssue = MarketCorporateAction(
        id: 'sample-rights-2000-06-30',
        assetId: 'sample',
        type: MarketCorporateActionType.rightsIssue,
        date: '2000-06-30',
        numerator: 1,
        denominator: 5,
        amount: 8000,
        currency: 'KRW',
        source: 'test',
      );
      final asset = FictionalMarketAsset(
        id: 'sample',
        symbol: '1000',
        name: '샘플전자',
        market: fictionalMainMarket,
        country: 'KR',
        sector: '전자',
        colorHex: '#7253C7',
        currency: 'KRW',
        initialSharesOutstanding: 1000000,
        prices: const {'1999-12-30': 10000, '2000-06-30': 9800},
        corporateActions: const [rightsIssue],
        financials: const [
          FictionalFinancialSnapshot(
            period: '1999-12-31',
            revenue: 100000000000,
            operatingProfit: 12000000000,
            consensusOperatingProfit: 11000000000,
            netIncome: 9000000000,
            operatingCashFlow: 13000000000,
            cash: 30000000000,
            debt: 20000000000,
            equity: 70000000000,
            sharesOutstanding: 1000000,
            orderBacklog: 40000000000,
            capex: 8000000000,
          ),
        ],
      );
      final events = buildCorporateDisclosureCalendar(
        asset: asset,
        simulationSeed: 'corporate-calendar-test',
        asOfDate: DateTime(2000, 6, 15),
        pastDays: 180,
        futureDays: 365,
      );

      expect(
        events.map((event) => event.type),
        containsAll(<CorporateDisclosureType>[
          CorporateDisclosureType.preliminaryEarnings,
          CorporateDisclosureType.periodicReport,
          CorporateDisclosureType.earningsCall,
          CorporateDisclosureType.auditReport,
          CorporateDisclosureType.annualGeneralMeeting,
          CorporateDisclosureType.rightsRecord,
          CorporateDisclosureType.exRights,
          CorporateDisclosureType.rightsSubscription,
          CorporateDisclosureType.newShareListing,
        ]),
      );
      expect(
        events.where(
          (event) => event.type == CorporateDisclosureType.rightsRecord,
        ),
        hasLength(1),
      );
      expect(
        events.every(
          (event) =>
              event.title.trim().isNotEmpty && event.summary.trim().isNotEmpty,
        ),
        isTrue,
      );
      expect(
        events.map((event) => (event.date, event.minute)).toList(),
        orderedEquals(
          events.map((event) => (event.date, event.minute)).toList()
            ..sort((left, right) {
              final dateOrder = left.$1.compareTo(right.$1);
              return dateOrder != 0 ? dateOrder : left.$2.compareTo(right.$2);
            }),
        ),
      );
    },
  );

  test(
    'market universe contains 50 fixed fictional firms and later generations',
    () async {
      final universe = await FictionalMarketUniverse.load(seed: 'roster-test');

      expect(universe.schemaVersion, greaterThanOrEqualTo(5));
      expect(
        universe.assets.where((asset) => asset.generation == 0),
        hasLength(50),
      );
      expect(universe.assets.length, greaterThan(90));
      expect(
        universe.assets,
        everyElement(
          predicate<FictionalMarketAsset>((asset) => asset.isDomestic),
        ),
      );
      expect(
        universe.assets.map((asset) => asset.market).toSet(),
        equals(<String>{fictionalMainMarket, fictionalGrowthMarket}),
      );
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test(
    'generated IPO closes follow the 2023 first-day range reform',
    () {
      final universe = buildFictionalMarketUniverse(
        'modern-ipo-official-close-regression',
        throughDate: DateTime(2024, 12, 31),
      );
      final generatedIpos = universe.assets
          .where(
            (asset) =>
                asset.generation > 0 &&
                asset.parentAssetId == null &&
                asset.listedOn != null &&
                asset.firstTradeDate != null,
          )
          .toList(growable: false);
      final modern = generatedIpos
          .where(
            (asset) =>
                asset.listedOn!.compareTo(
                  modernIpoPriceRangeEffectiveDateKey,
                ) >=
                0,
          )
          .toList(growable: false);
      final legacy = generatedIpos
          .where(
            (asset) =>
                asset.listedOn!.compareTo(modernIpoPriceRangeEffectiveDateKey) <
                0,
          )
          .last;

      expect(modern, isNotEmpty);
      var escapedOrdinaryThirtyPercentRange = false;
      for (final asset in modern) {
        final listingDate = DateTime.parse(asset.listedOn!);
        final reference = asset.listingReferencePrice!;
        final firstClose = asset.quoteAtOrBefore(listingDate)!.close;
        final range = marketDailyPriceRange(
          previousClose: reference,
          date: listingDate,
          market: asset.market,
          isIpoFirstTradingDay: true,
        );
        expect(asset.isIpoFirstTradingDay(listingDate), isTrue);
        expect(firstClose, inInclusiveRange(range.lower, range.upper));
        escapedOrdinaryThirtyPercentRange |=
            firstClose < reference * 0.70 || firstClose > reference * 1.30;

        final firstTwo = asset.historyThrough(
          listingDate.add(const Duration(days: 10)),
          count: 2,
        );
        expect(firstTwo, hasLength(2));
        final nextDate = firstTwo.last.parsedDate;
        final nextRange = marketDailyPriceRange(
          previousClose: firstTwo.first.close,
          date: nextDate,
          market: asset.market,
        );
        expect(asset.isIpoFirstTradingDay(nextDate), isFalse);
        expect(
          firstTwo.last.close,
          inInclusiveRange(nextRange.lower, nextRange.upper),
        );
      }
      expect(
        escapedOrdinaryThirtyPercentRange,
        isTrue,
        reason: '공식 종가 생성기가 여전히 일반 ±30%에 묶여 있으면 안 된다.',
      );

      final legacyDate = DateTime.parse(legacy.listedOn!);
      final legacyReference = legacy.listingReferencePrice!;
      final legacyClose = legacy.quoteAtOrBefore(legacyDate)!.close;
      final legacyRange = marketDailyPriceRange(
        previousClose: legacyReference,
        date: legacyDate,
        market: legacy.market,
        isIpoFirstTradingDay: true,
      );
      expect(
        legacyClose,
        inInclusiveRange(legacyRange.lower, legacyRange.upper),
      );
      expect(legacyRange.upper, lessThanOrEqualTo(legacyReference * 1.30));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'seeded companies expose quarterly fundamentals and business relations',
    () {
      final universe = buildFictionalMarketUniverse('fundamental-test-seed');
      final asset = universe.assets.firstWhere(
        (candidate) => candidate.financials.length >= 4,
      );
      final snapshot = asset.financialAtOrBefore(DateTime(2005, 12, 31));

      expect(universe.schemaVersion, greaterThanOrEqualTo(7));
      expect(snapshot, isNotNull);
      expect(snapshot!.revenue, greaterThan(0));
      expect(snapshot.sharesOutstanding, greaterThan(0));
      expect(snapshot.equity, greaterThan(0));
      expect(snapshot.consensusOperatingProfit, isNot(0));
      expect(asset.products, isNotEmpty);
      expect(asset.relations, isNotEmpty);
      expect(
        asset.relations.every(
          (relation) => relation.relatedAssetId != asset.id,
        ),
        isTrue,
      );
    },
  );

  test('financials expose only on the official publication date', () {
    final publicationDate = marketFinancialPublicationDateForPeriod(
      '2005-03-31',
    );
    final beforePublication = buildFictionalMarketUniverse(
      'financial-cutoff-seed',
      throughDate: publicationDate.subtract(const Duration(days: 1)),
    );
    final onPublication = buildFictionalMarketUniverse(
      'financial-cutoff-seed',
      throughDate: publicationDate,
    );
    final before = beforePublication.assets.singleWhere(
      (asset) => asset.id == 'hanbit_telecom',
    );
    final published = onPublication.assets.singleWhere(
      (asset) => asset.id == 'hanbit_telecom',
    );

    expect(
      before.financials.any(
        (snapshot) => snapshot.period.startsWith('2005-03'),
      ),
      isFalse,
    );
    expect(
      published.financials.any(
        (snapshot) => snapshot.period.startsWith('2005-03'),
      ),
      isTrue,
    );
  });

  test('dated universes do not expose companies that have not listed yet', () {
    final universe = buildFictionalMarketUniverse(
      'relation-cutoff-seed',
      throughDate: DateTime(2000, 6, 30),
    );
    final knownAssetIds = universe.assets
        .where(
          (asset) =>
              asset.listedOn == null ||
              asset.listedOn!.compareTo('2000-06-30') <= 0,
        )
        .map((asset) => asset.id)
        .toSet();

    for (final asset in universe.assets.where(
      (asset) => asset.quoteAtOrBefore(DateTime(2000, 6, 30)) != null,
    )) {
      expect(
        asset.relations.map((relation) => relation.relatedAssetId),
        everyElement(isIn(knownAssetIds)),
      );
    }
  });

  test('market parser rejects duplicate assets and invalid prices', () {
    Map<String, dynamic> asset(String id, String symbol, Object price) => {
      'id': id,
      'symbol': symbol,
      'name': id,
      'market': fictionalMainMarket,
      'country': 'KR',
      'currency': 'KRW',
      'initialSharesOutstanding': 1000000,
      'prices': {'2000-01-04': price},
    };
    Map<String, dynamic> universe(List<Map<String, dynamic>> assets) => {
      'schemaVersion': 4,
      'source': {'name': 'test'},
      'assets': assets,
    };

    expect(
      () => FictionalMarketUniverse.fromJson(
        universe([
          asset('same', '000001.KS', 100),
          asset('same', '000002.KS', 200),
        ]),
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => FictionalMarketUniverse.fromJson(
        universe([asset('bad', '000003.KS', -1)]),
      ),
      throwsA(isA<FormatException>()),
    );
    final missingShares = asset('missing-shares', '000004.KS', 100)
      ..remove('initialSharesOutstanding');
    expect(
      () => FictionalMarketUniverse.fromJson(universe([missingShares])),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'fixed fictional firms start together without a pre-campaign quote',
    () async {
      final universe = await FictionalMarketUniverse.load(
        seed: 'listing-test',
        throughDate: DateTime(2000, 1, 4),
      );
      final hanbit = universe.assets.singleWhere(
        (asset) => asset.id == 'hanbit_telecom',
      );

      expect(hanbit.quoteAtOrBefore(DateTime(1999, 12, 29)), isNull);
      final first = hanbit.quoteAtOrBefore(DateTime(1999, 12, 30));
      expect(first, isNotNull);
      expect(first!.isExactDate, isTrue);
      expect(first.close, greaterThan(0));
    },
  );

  test('generated ticks finish on the exact official close', () {
    final path = generatedMarketPath(
      previousClose: 5900,
      officialClose: 6110,
      seed: 5,
    );
    final anotherPath = generatedMarketPath(
      previousClose: 5900,
      officialClose: 6110,
      seed: 6,
    );
    final middle = path[generatedSessionTicks ~/ 2];
    final close = path.last;

    expect(middle, isNot(6110));
    expect(path.first, 5900);
    expect(close, 6110);
    expect(path.last, 6110);
    expect(path.length, generatedSessionTicks + 1);
    expect(path.toSet().length, greaterThan(20));
    expect(path, isNot(equals(anotherPath)));
    final deltas = List<double>.generate(
      path.length - 1,
      (index) => path[index + 1] - path[index],
    );
    final regularDeltas = deltas.take(deltas.length - 1).toList();
    expect(
      regularDeltas.where((delta) => delta == 0),
      isNotEmpty,
      reason: 'A realistic one-minute path should occasionally stay flat.',
    );
    expect(
      regularDeltas.where((delta) => delta.abs() <= 10).length,
      greaterThan(regularDeltas.length * 0.75),
      reason: 'Most minutes should move by no more than one price tick.',
    );

    expect(deltas.toSet().length, greaterThan(3));
    expect(
      deltas.map((delta) => delta.abs()).reduce((a, b) => a > b ? a : b),
      lessThan(590),
    );
  });

  test('generated intraday prices obey the same high-price quote units', () {
    final path = generatedMarketPath(
      previousClose: 252500,
      officialClose: 258000,
      seed: 31,
    );

    for (final price in path) {
      expect(
        isValidMarketOrderPrice(price, market: '미래시장'),
        isTrue,
        reason: '$price must stay on the 500-won quote grid.',
      );
    }
  });

  test('previous-session lead-in only drops its oldest point each minute', () {
    final ninetyPoints = generatedPreviousSessionLeadIn(
      previousClose: 50400,
      pointCount: 90,
      seed: 77,
    );
    final eightyNinePoints = generatedPreviousSessionLeadIn(
      previousClose: 50400,
      pointCount: 89,
      seed: 77,
    );

    expect(ninetyPoints, hasLength(90));
    expect(eightyNinePoints, hasLength(89));
    expect(ninetyPoints.skip(1), orderedEquals(eightyNinePoints));
  });

  test(
    'minute candles aggregate generated ticks into selectable intervals',
    () {
      final candles = aggregateMarketCandles(<double>[
        100,
        103,
        101,
        106,
        104,
        110,
        108,
      ], 3);

      expect(candles.length, 2);
      expect(candles.first.open, 100);
      expect(candles.first.high, 106);
      expect(candles.first.low, 100);
      expect(candles.first.close, 106);
      expect(candles.last.open, 106);
      expect(candles.last.close, 108);
    },
  );

  test('one-minute market ticks produce a true one-minute candle', () {
    expect(marketTickMinutes, 1);
    final candles = aggregateMarketCandles(
      <double>[100, 101, 99, 102],
      1,
      tickMinutes: marketTickMinutes,
    );
    expect(candles, hasLength(3));
    expect(candles.first.startMinute, 0);
    expect(candles.first.open, 100);
    expect(candles.first.close, 101);
    expect(candles.last.startMinute, 2);
    expect(candles.last.close, 102);
  });

  test(
    'seeded one-minute candles use sparse wicks and reproducible volume',
    () {
      final prices = List<double>.generate(
        31,
        (index) => 10000 + <double>[0, 10, -10, 20][index % 4],
      );
      final candles = aggregateMarketCandles(
        prices,
        1,
        seed: 77,
        startMinuteOffset: 45,
      );
      final repeated = aggregateMarketCandles(
        prices,
        1,
        seed: 77,
        startMinuteOffset: 45,
      );

      expect(candles, hasLength(30));
      expect(candles.first.startMinute, 45);
      final wickCount = candles.where((candle) {
        return candle.high > math.max(candle.open, candle.close) ||
            candle.low < math.min(candle.open, candle.close);
      }).length;
      expect(wickCount, inInclusiveRange(1, 24));
      expect(
        candles,
        everyElement(predicate<MarketCandle>((c) => c.volume > 0)),
      );
      expect(
        candles.map((candle) => candle.volume).toSet().length,
        greaterThan(5),
      );
      expect(
        List<Object>.generate(
          candles.length,
          (index) => <double>[
            repeated[index].high,
            repeated[index].low,
            repeated[index].volume,
          ],
        ),
        equals(
          List<Object>.generate(
            candles.length,
            (index) => <double>[
              candles[index].high,
              candles[index].low,
              candles[index].volume,
            ],
          ),
        ),
      );
    },
  );

  test(
    'minute candle volumes normalize to the authoritative session total',
    () {
      final prices = List<double>.generate(
        351,
        (index) => 10000 + (index % 7 - 3) * 10,
      );
      const totalVolume = 1234567.0;

      final oneMinute = aggregateMarketCandles(
        prices,
        1,
        seed: 91,
        totalVolume: totalVolume,
      );
      final thirtyMinute = aggregateMarketCandles(
        prices,
        30,
        seed: 91,
        totalVolume: totalVolume,
      );

      expect(
        oneMinute.fold<double>(0, (sum, candle) => sum + candle.volume),
        totalVolume,
      );
      expect(
        thirtyMinute.fold<double>(0, (sum, candle) => sum + candle.volume),
        totalVolume,
      );
    },
  );

  test(
    'explicit minute volumes survive rebucketing without redistribution',
    () {
      final prices = <double>[100, 101, 99, 102, 103, 104];
      final minuteVolumes = <int>[11, 13, 17, 19, 23];

      final oneMinute = aggregateMarketCandles(
        prices,
        1,
        minuteVolumes: minuteVolumes,
      );
      final fiveMinute = aggregateMarketCandles(
        prices,
        5,
        minuteVolumes: minuteVolumes,
      );

      expect(
        oneMinute.map((candle) => candle.volume),
        minuteVolumes.map((volume) => volume.toDouble()),
      );
      expect(fiveMinute.single.volume, 83);
      expect(
        () => aggregateMarketCandles(
          prices,
          1,
          totalVolume: 83,
          minuteVolumes: minuteVolumes,
        ),
        throwsArgumentError,
      );
    },
  );

  test('candle labels respect the duration of each generated tick', () {
    final candles = aggregateMarketCandles(
      <double>[100, 101, 102, 103, 104],
      6,
      tickMinutes: 3,
    );
    expect(candles, hasLength(2));
    expect(candles.first.open, 100);
    expect(candles.first.close, 102);
    expect(
      () => aggregateMarketCandles(<double>[100, 101], 5, tickMinutes: 3),
      throwsArgumentError,
    );
  });
}
