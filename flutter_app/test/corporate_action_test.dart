import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_quote.dart';
import 'package:millennium_capital/game/market_tick.dart';

void main() {
  const seed = 'corporate-action-regression-0';
  final cutoff = DateTime(2012, 12, 31);
  late FictionalMarketUniverse universe;

  setUpAll(() {
    universe = buildFictionalMarketUniverse(seed, throughDate: cutoff);
  });

  test('initial shares persist and exist on every first trading day', () {
    expect(universe.schemaVersion, 14);
    var checkedListings = 0;
    var checkedSpinoffs = 0;
    for (final asset in universe.assets) {
      final firstTradeDate = asset.firstTradeDate;
      if (firstTradeDate == null) continue;
      final firstDate = DateTime.parse(firstTradeDate);
      expect(asset.initialSharesOutstanding, greaterThan(0));
      expect(
        asset.sharesOutstandingAtOrBefore(firstDate),
        asset.initialSharesOutstanding,
      );
      expect(
        asset.sharesOutstandingAtOrBefore(
          firstDate.subtract(const Duration(days: 1)),
        ),
        isNull,
      );

      final parsed = FictionalMarketAsset.fromJson(asset.toJson());
      expect(parsed.initialSharesOutstanding, asset.initialSharesOutstanding);
      expect(
        parsed.sharesOutstandingAtOrBefore(firstDate),
        asset.initialSharesOutstanding,
      );
      if (asset.generation > 0 && asset.parentAssetId == null) {
        checkedListings += 1;
      }
      if (asset.parentAssetId != null) checkedSpinoffs += 1;
    }
    expect(checkedListings, greaterThan(0));
    expect(checkedSpinoffs, greaterThan(0));
  });

  test('cash terms stay proportional from penny to high-priced stocks', () {
    const referencePrices = <double>[
      120,
      130,
      500,
      1000,
      5000,
      40000,
      500000,
      2500000,
    ];
    const discounts = <double>[12, 25, 40];
    const yields = <double>[0.005, 0.017, 0.03];

    for (final market in <String>[fictionalMainMarket, fictionalGrowthMarket]) {
      for (final referencePrice in referencePrices) {
        for (final announcedDiscount in discounts) {
          final subscriptionPrice = fictionalRightsIssueSubscriptionPrice(
            referencePrice: referencePrice,
            announcedDiscountPct: announcedDiscount,
            market: market,
          );
          final actualDiscount = (1 - subscriptionPrice / referencePrice) * 100;
          final subscriptionTick = marketTickSize(
            referencePrice * (1 - announcedDiscount / 100),
            market: market,
          );

          expect(subscriptionPrice, greaterThan(0));
          expect(subscriptionPrice, lessThan(referencePrice));
          expect(actualDiscount, greaterThanOrEqualTo(announcedDiscount));
          expect(
            actualDiscount - announcedDiscount,
            lessThanOrEqualTo(
              subscriptionTick / referencePrice * 100 + 0.000001,
            ),
          );
        }

        for (final targetYield in yields) {
          final dividend = fictionalDividendPerShare(
            referencePrice: referencePrice,
            targetYieldRate: targetYield,
            market: market,
          );
          final actualYield = dividend / referencePrice;
          final referenceTick = marketTickSize(referencePrice, market: market);

          expect(dividend, greaterThan(0));
          expect(dividend, lessThan(referencePrice));
          expect(actualYield, lessThanOrEqualTo(0.04));
          expect(
            (actualYield - targetYield).abs(),
            lessThanOrEqualTo(referenceTick / referencePrice + 0.000001),
          );
        }
      }
    }

    expect(
      fictionalRightsIssueSubscriptionPrice(
        referencePrice: 120,
        announcedDiscountPct: 40,
        market: fictionalMainMarket,
      ),
      72,
    );
    expect(
      fictionalDividendPerShare(
        referencePrice: 120,
        targetYieldRate: 0.005,
        market: fictionalMainMarket,
      ),
      1,
    );
  });

  test('ex-date references may fall below the generation floor', () {
    FictionalMarketAsset assetWith(MarketCorporateAction action) =>
        FictionalMarketAsset(
          id: 'low_price',
          symbol: '0001',
          name: 'Low Price',
          market: fictionalMainMarket,
          country: 'KR',
          sector: 'Test',
          colorHex: '#000000',
          currency: 'KRW',
          initialSharesOutstanding: 1000000,
          prices: const {'2000-01-03': 120, '2000-01-04': 120},
          corporateActions: [action],
        );

    final dividendAsset = assetWith(
      const MarketCorporateAction(
        id: 'dividend-low',
        assetId: 'low_price',
        type: MarketCorporateActionType.dividend,
        date: '2000-01-04',
        numerator: 1,
        denominator: 1,
        amount: 1,
        currency: 'KRW',
        source: 'test',
      ),
    );
    expect(
      dividendAsset.marketReferenceCloseOn(
        DateTime(2000, 1, 4),
        previousClose: 120,
      ),
      119,
    );

    final rightsAsset = assetWith(
      const MarketCorporateAction(
        id: 'rights-low',
        assetId: 'low_price',
        type: MarketCorporateActionType.rightsIssue,
        date: '2000-01-04',
        numerator: 8,
        denominator: 100,
        amount: 72,
        currency: 'KRW',
        source: 'test',
        referencePrice: 120,
        sharesOutstandingBefore: 1000000,
        sharesIssued: 80000,
      ),
    );
    expect(
      rightsAsset.marketReferenceCloseOn(
        DateTime(2000, 1, 4),
        previousClose: 120,
      ),
      116,
    );

    final spinoffAsset = assetWith(
      const MarketCorporateAction(
        id: 'spinoff-low',
        assetId: 'low_price',
        type: MarketCorporateActionType.spinoff,
        date: '2000-01-04',
        numerator: 1,
        denominator: 10,
        amount: 240,
        currency: 'KRW',
        source: 'test',
        relatedAssetId: 'child',
        relatedSymbol: '0002',
        relatedName: 'Child',
        relatedMarket: fictionalGrowthMarket,
        referencePrice: 120,
      ),
    );
    expect(
      spinoffAsset.marketReferenceCloseOn(
        DateTime(2000, 1, 4),
        previousClose: 120,
      ),
      96,
    );
  });

  test('rights issue records exact issuance, dilution, and TERP terms', () {
    final assetsById = <String, FictionalMarketAsset>{
      for (final asset in universe.assets) asset.id: asset,
    };
    final rightsIssues = universe.assets
        .expand((asset) => asset.corporateActions)
        .where((action) => action.type == MarketCorporateActionType.rightsIssue)
        .toList(growable: false);

    expect(rightsIssues.length, greaterThan(30));
    expect(
      rightsIssues.any(
        (action) =>
            action.allocationMethod ==
            MarketRightsIssueAllocationMethod.shareholder,
      ),
      isTrue,
    );
    expect(
      rightsIssues.any(
        (action) =>
            action.allocationMethod ==
            MarketRightsIssueAllocationMethod.thirdParty,
      ),
      isTrue,
    );
    for (final action in rightsIssues) {
      final before = action.sharesOutstandingBefore;
      final issued = action.sharesIssued;
      final after = action.sharesOutstandingAfter;
      final referencePrice = action.referencePrice;
      final theoreticalPrice = action.theoreticalExRightsPrice;

      expect(before, isNotNull);
      expect(issued, isNotNull);
      expect(after, isNotNull);
      expect(referencePrice, isNotNull);
      expect(action.numerator, 8);
      expect(action.denominator, 100);
      final beforeValue = before!;
      final issuedValue = issued!;
      expect(issuedValue, (beforeValue * 1.08).round() - beforeValue);
      expect(after, beforeValue + issuedValue);
      expect(action.rightsIssueRate, closeTo(0.08, 0.000001));
      expect(action.ownershipDilutionRate, closeTo(0.08 / 1.08, 0.000001));
      expect(action.rightsIssueGrossProceeds, issuedValue * action.amount);
      if (action.allocationMethod ==
          MarketRightsIssueAllocationMethod.shareholder) {
        expect(theoreticalPrice, isNotNull);
        expect(
          theoreticalPrice,
          closeTo(
            (referencePrice! + action.rightsIssueRate * action.amount) /
                (1 + action.rightsIssueRate),
            0.000001,
          ),
        );
        expect(theoreticalPrice, lessThanOrEqualTo(referencePrice));
        expect(theoreticalPrice, greaterThanOrEqualTo(action.amount));
      } else {
        expect(theoreticalPrice, isNull);
        expect(
          action.theoreticalExRightsPriceFor(referencePrice!),
          referencePrice,
        );
      }

      final event = fictionalMarketEventsForDate(
        seed,
        DateTime.parse(action.date),
      ).singleWhere((candidate) => candidate.id == action.id);
      final discountMatch = RegExp(r'목표 할인율 약 (\d+)%').firstMatch(event.body);
      expect(discountMatch, isNotNull);
      final announcedDiscount = double.parse(discountMatch!.group(1)!);
      final market = assetsById[action.assetId]!.market;
      expect(
        action.amount,
        fictionalRightsIssueSubscriptionPrice(
          referencePrice: referencePrice,
          announcedDiscountPct: announcedDiscount,
          market: market,
        ),
      );
      final actualDiscountPct = (1 - action.amount / referencePrice) * 100;
      final subscriptionTick = marketTickSize(
        referencePrice * (1 - announcedDiscount / 100),
        market: market,
      );
      expect(
        actualDiscountPct,
        greaterThanOrEqualTo(announcedDiscount - 0.000001),
      );
      expect(
        actualDiscountPct - announcedDiscount,
        lessThanOrEqualTo(subscriptionTick / referencePrice * 100 + 0.000001),
      );
      expect(event.revealMinute, marketDayStartMinute);
      expect(
        event.title.contains('제3자배정'),
        action.allocationMethod == MarketRightsIssueAllocationMethod.thirdParty,
      );

      final parsed = MarketCorporateAction.fromJson(
        action.assetId,
        action.toJson(),
      );
      expect(parsed.toJson(), action.toJson());
      expect(parsed.ownershipDilutionRate, action.ownershipDilutionRate);
      expect(parsed.theoreticalExRightsPrice, action.theoreticalExRightsPrice);
    }
  });

  test('generated dividends never inherit a fixed 10-won floor', () {
    var checked = 0;
    for (final asset in universe.assets) {
      for (final action in asset.corporateActions.where(
        (candidate) => candidate.type == MarketCorporateActionType.dividend,
      )) {
        final referencePrice = action.referencePrice;
        expect(referencePrice, isNotNull);
        final reference = referencePrice!;
        final yieldRate = action.amount / reference;
        final tick = marketTickSize(reference, market: asset.market);

        expect(action.amount, greaterThan(0));
        expect(action.amount, lessThan(reference));
        expect(
          action.amount / tick,
          closeTo((action.amount / tick).round(), 1e-9),
        );
        expect(yieldRate, inInclusiveRange(0.0035, 0.04));
        if (reference <= 130) {
          expect(action.amount, lessThan(10));
        }
        checked += 1;
      }
    }
    expect(checked, greaterThan(50));
  });

  test(
    'financial share count changes on the actual rights date, not Jan 1',
    () {
      var checked = 0;
      for (final asset in universe.assets) {
        final rightsIssues =
            asset.corporateActions
                .where(
                  (action) =>
                      action.type == MarketCorporateActionType.rightsIssue,
                )
                .toList(growable: false)
              ..sort((left, right) => left.date.compareTo(right.date));
        for (final action in rightsIssues) {
          final actionDate = DateTime.parse(action.date);
          expect(
            asset.sharesOutstandingAtOrBefore(
              actionDate.subtract(const Duration(days: 1)),
            ),
            action.sharesOutstandingBefore,
          );
          expect(
            asset.sharesOutstandingAtOrBefore(actionDate),
            action.sharesOutstandingAfter,
          );
          FictionalFinancialSnapshot? firstSnapshotAfter;
          for (final snapshot in asset.financials) {
            if (snapshot.period.compareTo(action.date) >= 0) {
              firstSnapshotAfter = snapshot;
              break;
            }
          }
          if (firstSnapshotAfter == null) continue;
          final snapshotAfter = firstSnapshotAfter;
          final latestApplied = rightsIssues.lastWhere(
            (candidate) => candidate.date.compareTo(snapshotAfter.period) <= 0,
          );
          expect(
            snapshotAfter.sharesOutstanding,
            latestApplied.sharesOutstandingAfter,
          );

          final priorSnapshots = asset.financials.where(
            (snapshot) => snapshot.period.compareTo(action.date) < 0,
          );
          if (priorSnapshots.isNotEmpty) {
            expect(
              priorSnapshots.last.sharesOutstanding,
              action.sharesOutstandingBefore,
            );
          }
          checked += 1;
        }
      }
      expect(checked, greaterThan(20));
    },
  );

  test(
    'rights-day path opens from TERP and obeys the adjusted price limit',
    () {
      FictionalMarketAsset? selectedAsset;
      MarketCorporateAction? selectedAction;
      for (final asset in universe.assets) {
        for (final action in asset.corporateActions) {
          if (action.type != MarketCorporateActionType.rightsIssue ||
              action.allocationMethod !=
                  MarketRightsIssueAllocationMethod.shareholder ||
              (action.referencePrice ?? 0) < 1000) {
            continue;
          }
          selectedAsset = asset;
          selectedAction = action;
          break;
        }
        if (selectedAction != null) break;
      }

      expect(selectedAsset, isNotNull);
      expect(selectedAction, isNotNull);
      final asset = selectedAsset!;
      final action = selectedAction!;
      final date = DateTime.parse(action.date);
      final quote = asset.quoteAtOrBefore(date)!;
      final previousClose = asset.previousCloseBefore(quote.date)!;
      final referenceClose = asset.marketReferenceCloseOn(
        date,
        previousClose: previousClose,
      );
      final first = generatedMarketDayPathForAsset(
        asset: asset,
        simulationSeed: seed,
        date: date,
        previousClose: previousClose,
        officialClose: quote.close,
      );
      final repeated = generatedMarketDayPathForAsset(
        asset: asset,
        simulationSeed: seed,
        date: date,
        previousClose: previousClose,
        officialClose: quote.close,
      );
      final range = marketDailyPriceRange(
        previousClose: referenceClose,
        date: date,
        market: asset.market,
      );

      expect(referenceClose, isNot(previousClose));
      expect(first.take(generatedPreOpenTicks), everyElement(referenceClose));
      expect(first, orderedEquals(repeated));
      expect(first.last, quote.close);
      expect(first, everyElement(inInclusiveRange(range.lower, range.upper)));
      expect(
        first,
        everyElement(
          predicate<double>(
            (price) => isValidMarketOrderPrice(price, market: asset.market),
          ),
        ),
      );
    },
  );

  test(
    'same-day dividend, rights issue, and split use one ordered reference',
    () {
      const date = '2001-04-09';
      const dividend = MarketCorporateAction(
        id: 'dividend',
        assetId: 'sample',
        type: MarketCorporateActionType.dividend,
        date: date,
        numerator: 1,
        denominator: 1,
        amount: 100,
        currency: 'KRW',
        source: 'test',
      );
      const rights = MarketCorporateAction(
        id: 'rights',
        assetId: 'sample',
        type: MarketCorporateActionType.rightsIssue,
        date: date,
        numerator: 8,
        denominator: 100,
        amount: 700,
        currency: 'KRW',
        source: 'test',
        referencePrice: 900,
        sharesOutstandingBefore: 1000000,
        sharesIssued: 80000,
      );
      const split = MarketCorporateAction(
        id: 'split',
        assetId: 'sample',
        type: MarketCorporateActionType.split,
        date: date,
        numerator: 2,
        denominator: 1,
        amount: 0,
        currency: 'KRW',
        source: 'test',
      );
      final asset = FictionalMarketAsset(
        id: 'sample',
        symbol: '000001.KS',
        name: '샘플',
        market: fictionalMainMarket,
        country: 'KR',
        sector: '기타',
        colorHex: '#000000',
        currency: 'KRW',
        initialSharesOutstanding: 1000000,
        prices: const {'2001-04-06': 1000, date: 440},
        corporateActions: const [split, rights, dividend],
      );

      final expectedTerp = (900 + 0.08 * 700) / 1.08;
      final expectedReference = marketSnapPrice(
        expectedTerp / 2,
        market: fictionalMainMarket,
      );
      expect(
        asset.marketReferenceCloseOn(DateTime.parse(date), previousClose: 1000),
        expectedReference,
      );
    },
  );

  test(
    'same-day dividend uses pre-issue shares before rights proceeds and split',
    () {
      const date = '2001-04-09';
      const dividend = MarketCorporateAction(
        id: 'dividend',
        assetId: 'sample',
        type: MarketCorporateActionType.dividend,
        date: date,
        numerator: 1,
        denominator: 1,
        amount: 100,
        currency: 'KRW',
        source: 'test',
      );
      const rights = MarketCorporateAction(
        id: 'rights',
        assetId: 'sample',
        type: MarketCorporateActionType.rightsIssue,
        date: date,
        numerator: 8,
        denominator: 100,
        amount: 700,
        currency: 'KRW',
        source: 'test',
        referencePrice: 900,
        sharesOutstandingBefore: 1000000,
        sharesIssued: 80000,
      );
      const split = MarketCorporateAction(
        id: 'split',
        assetId: 'sample',
        type: MarketCorporateActionType.split,
        date: date,
        numerator: 2,
        denominator: 1,
        amount: 0,
        currency: 'KRW',
        source: 'test',
      );

      final balances = applyFictionalCorporateActionFinancialEffects(
        cash: 2000000000,
        debt: 100000000,
        equity: 3000000000,
        sharesOutstanding: 1000000,
        actions: const [split, rights, dividend],
      );
      final repeated = applyFictionalCorporateActionFinancialEffects(
        cash: 2000000000,
        debt: 100000000,
        equity: 3000000000,
        sharesOutstanding: 1000000,
        actions: const [dividend, split, rights],
      );

      expect(balances, repeated);
      expect(balances.cash, 1936400000);
      expect(balances.debt, 80400000);
      expect(balances.equity, 2956000000);
      expect(balances.sharesOutstanding, 2160000);
    },
  );

  test('personnel spinoff removes the granted child value from parent', () {
    var checked = 0;
    for (final parent in universe.assets) {
      for (final action in parent.corporateActions.where(
        (candidate) => candidate.type == MarketCorporateActionType.spinoff,
      )) {
        final child = universe.assets.singleWhere(
          (candidate) => candidate.id == action.relatedAssetId,
        );
        final date = DateTime.parse(action.date);
        final childQuote = child.quoteAtOrBefore(date);
        final parentQuote = parent.quoteAtOrBefore(date);
        final previousParentClose = parent.previousCloseBefore(action.date);

        expect(childQuote, isNotNull);
        expect(childQuote!.isExactDate, isTrue);
        expect(action.amount, childQuote.close);
        expect(action.referencePrice, isNotNull);
        expect(action.theoreticalExSpinoffPrice, isNotNull);
        expect(
          action.theoreticalExSpinoffPrice! + action.unitFactor * action.amount,
          closeTo(action.referencePrice!, 0.000001),
        );
        expect(parentQuote, isNotNull);
        expect(previousParentClose, isNotNull);
        expect(
          parent.marketReferenceCloseOn(
            date,
            previousClose: previousParentClose!,
          ),
          marketSnapPrice(
            action.theoreticalExSpinoffPrice!,
            market: parent.market,
          ),
        );
        checked += 1;
      }
    }
    expect(checked, greaterThan(0));
  });

  test('every spinoff distribution fits the child share count', () {
    var checked = 0;
    for (final parent in universe.assets) {
      for (final action in parent.corporateActions.where(
        (candidate) =>
            candidate.type == MarketCorporateActionType.spinoff ||
            candidate.type == MarketCorporateActionType.materialSpinoff,
      )) {
        final child = universe.assets.singleWhere(
          (candidate) => candidate.id == action.relatedAssetId,
        );
        final parentShares = parent.sharesOutstandingAtOrBefore(
          DateTime.parse(action.date),
        );
        expect(parentShares, isNotNull);
        final distributedShares = parentShares! * action.unitFactor;
        expect(
          distributedShares,
          closeTo(child.initialSharesOutstanding, 0.000001),
        );
        expect(
          distributedShares,
          lessThanOrEqualTo(child.initialSharesOutstanding + 0.000001),
        );
        expect(
          action.unitFactor * action.amount / action.referencePrice!,
          inInclusiveRange(0.17, 0.36),
        );
        expect(
          action.unitFactor * action.amount,
          lessThan(action.referencePrice!),
        );
        checked += 1;
      }
    }
    expect(checked, greaterThan(0));
  });

  test(
    'dividends and rights issues after a personnel spinoff stay price-adjusted',
    () {
      var checkedDividends = 0;
      var checkedRightsIssues = 0;
      for (final parent in universe.assets) {
        final personnelSpinoffDates = parent.corporateActions
            .where((action) => action.type == MarketCorporateActionType.spinoff)
            .map((action) => action.date)
            .toList(growable: false);
        if (personnelSpinoffDates.isEmpty) continue;
        final postSpinoffDates = parent.corporateActions
            .where(
              (action) =>
                  (action.type == MarketCorporateActionType.dividend ||
                      action.type == MarketCorporateActionType.rightsIssue) &&
                  personnelSpinoffDates.any(
                    (spinoffDate) => action.date.compareTo(spinoffDate) > 0,
                  ),
            )
            .map((action) => action.date)
            .toSet();

        for (final dateKey in postSpinoffDates) {
          final previousClose = parent.previousCloseBefore(dateKey);
          expect(previousClose, isNotNull);
          var reference = previousClose!;
          for (final action in parent.corporateActionsOn(
            DateTime.parse(dateKey),
          )) {
            if (action.type == MarketCorporateActionType.dividend) {
              expect(action.amount / reference, lessThanOrEqualTo(0.10));
              reference = math.max(1, reference - action.amount);
              checkedDividends += 1;
            } else if (action.type == MarketCorporateActionType.rightsIssue) {
              final declaredReference = action.referencePrice;
              expect(declaredReference, isNotNull);
              expect(action.amount, lessThanOrEqualTo(declaredReference!));
              expect(
                (declaredReference - reference).abs() / reference,
                lessThanOrEqualTo(0.02),
              );
              reference = action.theoreticalExRightsPriceFor(reference);
              checkedRightsIssues += 1;
            }
          }
          expect(
            parent.marketReferenceCloseOn(
              DateTime.parse(dateKey),
              previousClose: previousClose,
            ),
            lessThanOrEqualTo(previousClose),
          );
        }
      }
      expect(checkedDividends, greaterThan(0));
      expect(checkedRightsIssues, greaterThan(0));
    },
  );

  test('cutoff, holidays, IPO, and delisting lifecycle never overlap', () {
    final allActionIds = <String>{};
    var checkedDelistings = 0;
    for (final asset in universe.assets) {
      for (final action in asset.corporateActions) {
        final date = DateTime.parse(action.date);
        expect(date.isAfter(cutoff), isFalse);
        expect(isMarketTradingDay(date), isTrue);
        expect(allActionIds.add(action.id), isTrue);
        if (asset.listedOn != null) {
          expect(
            action.date.compareTo(asset.listedOn!),
            greaterThanOrEqualTo(0),
          );
          if (action.type == MarketCorporateActionType.rightsIssue ||
              action.type == MarketCorporateActionType.dividend) {
            expect(
              date.difference(DateTime.parse(asset.listedOn!)).inDays,
              greaterThanOrEqualTo(90),
            );
          }
        }
        if (asset.delistedOn != null) {
          final expectedMaximum =
              action.type == MarketCorporateActionType.delisting ? 0 : -1;
          expect(
            action.date.compareTo(asset.delistedOn!),
            lessThanOrEqualTo(expectedMaximum),
          );
        }
        if (action.type != MarketCorporateActionType.delisting) continue;

        final delistingDate = DateTime.parse(action.date);
        final lastHistory = asset.historyThrough(
          delistingDate.subtract(const Duration(days: 1)),
          count: 1,
        );
        expect(lastHistory, hasLength(1));
        final lastClose = lastHistory.single.close;
        expect(action.referencePrice, lastClose);
        expect(action.amount / lastClose, inInclusiveRange(0.12, 0.55));
        expect(asset.quoteAtOrBefore(delistingDate), isNull);
        checkedDelistings += 1;
      }
    }
    expect(checkedDelistings, greaterThan(0));
  });

  test('parser rejects partial or invalid rights issue share terms', () {
    final malformed = <String, dynamic>{
      'id': 'bad-rights',
      'type': MarketCorporateActionType.rightsIssue.name,
      'date': '2001-01-04',
      'numerator': 8,
      'denominator': 100,
      'amount': 800,
      'currency': 'KRW',
      'source': 'test',
      'referencePrice': 1000,
      'sharesOutstandingBefore': 1000000,
    };

    expect(
      () => MarketCorporateAction.fromJson('sample', malformed),
      throwsA(isA<FormatException>()),
    );
    final legacy = <String, dynamic>{...malformed, 'sharesIssued': 80000};
    expect(
      MarketCorporateAction.fromJson('sample', legacy).allocationMethod,
      MarketRightsIssueAllocationMethod.shareholder,
    );
    expect(
      () => MarketCorporateAction.fromJson('sample', {
        ...legacy,
        'allocationMethod': 'unknown',
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
