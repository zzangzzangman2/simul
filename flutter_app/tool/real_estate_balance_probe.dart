import 'dart:math' as math;

import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_world.dart';

void main(List<String> arguments) {
  final seedCount = arguments.isEmpty ? 8 : int.parse(arguments.first);
  final seeds = [
    for (var index = 0; index < seedCount; index += 1)
      'real-estate-balance-probe-$index',
  ];
  final cagrValues = <double>[];
  final seasonedCagrValues = <double>[];
  final anchorCagrValues = <double>[];
  final cagrExcessOverAnchorValues = <double>[];
  final cumulativePriceReturns = <double>[];
  final fullCampaignPriceReturns = <double>[];
  final drawdownValues = <double>[];
  final monthlyJumpValues = <double>[];
  var maximumBoundaryJump = 0.0;
  var maximumMonthlyJump = 0.0;
  var minimumActiveListings = 1 << 30;
  var activeEventPeak = 0;
  var seriesCount = 0;
  var risingSeries = 0;
  var decliningSeries = 0;
  var flatSeries = 0;
  var fullCampaignRisingSeries = 0;
  var fullCampaignDecliningSeries = 0;
  var fullCampaignFlatSeries = 0;
  var maximumJumpSeed = '';
  var maximumJumpAsset = '';
  var maximumJumpListing = -1;
  DateTime? maximumJumpDate;

  for (final seed in seeds) {
    for (final asset in realEstateMarketCatalog) {
      for (final listing in realEstateListingsFor(asset, seed)) {
        final prices = <int>[];
        var date = DateTime(
          asset.availableFrom.year,
          asset.availableFrom.month,
          15,
        );
        while (!date.isAfter(DateTime(2026, 12, 31))) {
          final price = listing.priceAt(date);
          prices.add(price);
          minimumActiveListings = math.min(
            minimumActiveListings,
            realEstateActiveListingsAt(asset, seed, date).length,
          );
          activeEventPeak = math.max(
            activeEventPeak,
            listing
                .visibleEventsAt(date)
                .where(
                  (event) =>
                      event.impactAt(date).abs() >= 0.002 &&
                      realEstateSpatialSpilloverFactor(asset, event) > 0,
                )
                .length,
          );
          final monthStart = DateTime(date.year, date.month);
          if (monthStart.isAfter(asset.availableFrom)) {
            final before = listing.priceAt(
              monthStart.subtract(const Duration(days: 1)),
            );
            final after = listing.priceAt(monthStart);
            maximumBoundaryJump = math.max(
              maximumBoundaryJump,
              (after - before).abs() / before,
            );
          }
          date = DateTime(date.year, date.month + 1, 15);
        }
        if (prices.length < 2) continue;
        var peak = prices.first.toDouble();
        var maximumDrawdown = 0.0;
        for (var index = 1; index < prices.length; index += 1) {
          final previous = prices[index - 1];
          final current = prices[index];
          final jump = (current - previous).abs() / previous;
          monthlyJumpValues.add(jump);
          if (jump >= maximumMonthlyJump) {
            maximumMonthlyJump = jump;
            maximumJumpSeed = seed;
            maximumJumpAsset = asset.id;
            maximumJumpListing = listing.index;
            maximumJumpDate = DateTime(
              asset.availableFrom.year,
              asset.availableFrom.month + index,
              15,
            );
          }
          peak = math.max(peak, current.toDouble());
          maximumDrawdown = math.max(maximumDrawdown, (peak - current) / peak);
        }
        final years =
            DateTime(2026, 12, 31).difference(asset.availableFrom).inDays /
            365.25;
        final cagr =
            math.pow(prices.last / prices.first, 1 / years).toDouble() - 1;
        final anchorStart = asset.priceAt(asset.availableFrom);
        final anchorEnd = asset.priceAt(DateTime(2026, 12, 31));
        final anchorCagr =
            math.pow(anchorEnd / anchorStart, 1 / years).toDouble() - 1;
        final cumulativeReturn = prices.last / prices.first - 1;
        cagrValues.add(cagr);
        if (years >= 5) seasonedCagrValues.add(cagr);
        anchorCagrValues.add(anchorCagr);
        cagrExcessOverAnchorValues.add(cagr - anchorCagr);
        cumulativePriceReturns.add(cumulativeReturn);
        if (asset.availableFrom == DateTime(2000, 1)) {
          fullCampaignPriceReturns.add(cumulativeReturn);
          if (cumulativeReturn > 0.005) {
            fullCampaignRisingSeries += 1;
          } else if (cumulativeReturn < -0.005) {
            fullCampaignDecliningSeries += 1;
          } else {
            fullCampaignFlatSeries += 1;
          }
        }
        if (cumulativeReturn > 0.005) {
          risingSeries += 1;
        } else if (cumulativeReturn < -0.005) {
          decliningSeries += 1;
        } else {
          flatSeries += 1;
        }
        drawdownValues.add(maximumDrawdown);
        seriesCount += 1;
      }
    }
  }

  cagrValues.sort();
  seasonedCagrValues.sort();
  anchorCagrValues.sort();
  cagrExcessOverAnchorValues.sort();
  cumulativePriceReturns.sort();
  fullCampaignPriceReturns.sort();
  drawdownValues.sort();
  monthlyJumpValues.sort();
  final legacySampleAsset = realEstateMarketAssetById(
    'uijeongbu_station_officetel_20',
  )!;
  final legacySample = realEstateListingsFor(
    legacySampleAsset,
    'real-estate-event-test',
    generatorVersion: 1,
  ).first;
  final legacySampleDate = DateTime(2012, 6);
  final summary = <String, Object>{
    'generatorVersion': realEstateWorldGeneratorVersion,
    'seedCount': seedCount,
    'seriesCount': seriesCount,
    'eventCountPerSeed': realEstateGeneratedEventCount(seeds.first),
    'legacyEventCountPerSeed': realEstateGeneratedEventCount(
      seeds.first,
      generatorVersion: 1,
    ),
    'cagrMedian': _percentile(cagrValues, 0.50),
    'cagrP90': _percentile(cagrValues, 0.90),
    'cagrWorst': cagrValues.first,
    'cagrBest': cagrValues.last,
    'seasonedCagrP90': _percentile(seasonedCagrValues, 0.90),
    'anchorOnlyCagrP90': _percentile(anchorCagrValues, 0.90),
    'cagrExcessOverAnchorP90': _percentile(cagrExcessOverAnchorValues, 0.90),
    'priceOnlyCumulativeReturnMedian': _percentile(
      cumulativePriceReturns,
      0.50,
    ),
    'priceOnlyCumulativeReturnP90': _percentile(cumulativePriceReturns, 0.90),
    'full27YearSeriesCount': fullCampaignPriceReturns.length,
    'full27YearPriceOnlyReturnMedian': _percentile(
      fullCampaignPriceReturns,
      0.50,
    ),
    'full27YearPriceOnlyReturnP90': _percentile(fullCampaignPriceReturns, 0.90),
    'full27YearPriceOnlyReturnWorst': fullCampaignPriceReturns.first,
    'full27YearPriceOnlyReturnBest': fullCampaignPriceReturns.last,
    'full27YearRisingSeries': fullCampaignRisingSeries,
    'full27YearDecliningSeries': fullCampaignDecliningSeries,
    'full27YearFlatSeries': fullCampaignFlatSeries,
    'risingSeries': risingSeries,
    'decliningSeries': decliningSeries,
    'flatSeries': flatSeries,
    'mddMedian': _percentile(drawdownValues, 0.50),
    'mddP90': _percentile(drawdownValues, 0.90),
    'monthlyJumpP99': _percentile(monthlyJumpValues, 0.99),
    'monthlyJumpMax': maximumMonthlyJump,
    'monthlyJumpMaxSeries':
        '$maximumJumpSeed/$maximumJumpAsset/$maximumJumpListing/'
        '${maximumJumpDate?.toIso8601String()}',
    'monthBoundaryJumpMax': maximumBoundaryJump,
    'minimumActiveListingsPerAsset': minimumActiveListings,
    'activeMaterialEventPeak': activeEventPeak,
    'legacySamplePrice201206': legacySample.priceAt(legacySampleDate),
    'legacySampleRent201206': legacySample.monthlyRentAt(legacySampleDate),
    'legacySampleEventCount': legacySample
        .visibleEventsAt(DateTime(2026, 12, 31))
        .length,
  };
  for (final entry in summary.entries) {
    // ignore: avoid_print
    print('${entry.key}=${entry.value}');
  }
  if (maximumJumpDate != null) {
    final asset = realEstateMarketAssetById(maximumJumpAsset)!;
    final listing = realEstateListingsFor(
      asset,
      maximumJumpSeed,
    )[maximumJumpListing];
    final currentDate = maximumJumpDate;
    final previousDate = DateTime(
      currentDate.year,
      currentDate.month - 1,
      currentDate.day,
    );
    final changingEvents =
        listing.visibleEventsAt(currentDate).where((event) {
          final before = event.impactAt(previousDate);
          final after = event.impactAt(currentDate);
          return (after - before).abs() >= 0.005;
        }).toList()..sort(
          (left, right) =>
              (right.impactAt(currentDate).abs() -
                      left.impactAt(currentDate).abs())
                  .sign
                  .toInt(),
        );
    for (final event in changingEvents.take(6)) {
      // ignore: avoid_print
      print(
        'maxJumpEvent=${event.title}|'
        '${event.impactAt(previousDate)}->${event.impactAt(currentDate)}',
      );
    }
  }
}

double _percentile(List<double> sorted, double percentile) {
  if (sorted.isEmpty) return 0;
  final index = ((sorted.length - 1) * percentile).round();
  return sorted[index];
}
