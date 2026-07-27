import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/personal_finance_state.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_world.dart';

void main() {
  group('시드 기반 서울·경기 부동산 월드', () {
    const worldSeed = 'real-estate-event-test';
    final campaignEnd = DateTime(2026, 12, 31);

    test('전체 부동산 월드 예열은 요약·캐시·재생 결과를 보존한다', () {
      const prewarmSeed = 'real-estate-prewarm-regression';
      final sampleAsset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;

      expect(isFictionalRealEstateWorldCached(prewarmSeed), isFalse);
      final firstSummary = prewarmFictionalRealEstateWorld(prewarmSeed);
      final cachedListings = realEstateListingsFor(sampleAsset, prewarmSeed);
      final cachedRegionalEvents = realEstateVisibleWorldEventsAt(
        sampleAsset,
        prewarmSeed,
        campaignEnd,
      );
      final listingFingerprint = [
        for (final listing in cachedListings)
          '${listing.optionId}:${listing.priceAt(DateTime(2020, 6))}:'
              '${listing.visibleEventsAt(campaignEnd).map((event) => event.id).join(',')}',
      ];
      final regionalFingerprint = [
        for (final event in cachedRegionalEvents)
          '${event.id}:${event.announcedAt.toIso8601String()}:'
              '${event.outcomeAt(campaignEnd)?.name}',
      ];

      expect(isFictionalRealEstateWorldCached(prewarmSeed), isTrue);
      expect(firstSummary.listingCount, realEstateMarketCatalog.length * 3);
      expect(firstSummary.regionalEventCount, greaterThan(0));
      expect(firstSummary.listingEventCount, greaterThan(0));
      expect(
        firstSummary.eventCount,
        realEstateGeneratedEventCount(prewarmSeed),
      );

      final cachedSummary = prewarmFictionalRealEstateWorld(prewarmSeed);
      expect(
        identical(
          cachedListings,
          realEstateListingsFor(sampleAsset, prewarmSeed),
        ),
        isTrue,
      );
      expect(
        identical(
          cachedRegionalEvents,
          realEstateVisibleWorldEventsAt(sampleAsset, prewarmSeed, campaignEnd),
        ),
        isTrue,
      );
      expect(cachedSummary.listingCount, firstSummary.listingCount);
      expect(cachedSummary.eventCount, firstSummary.eventCount);

      prewarmFictionalRealEstateWorld('real-estate-prewarm-eviction-a');
      prewarmFictionalRealEstateWorld('real-estate-prewarm-eviction-b');
      expect(isFictionalRealEstateWorldCached(prewarmSeed), isFalse);

      final regeneratedSummary = prewarmFictionalRealEstateWorld(prewarmSeed);
      final regeneratedListings = realEstateListingsFor(
        sampleAsset,
        prewarmSeed,
      );
      final regeneratedRegionalEvents = realEstateVisibleWorldEventsAt(
        sampleAsset,
        prewarmSeed,
        campaignEnd,
      );
      expect(regeneratedSummary.listingCount, firstSummary.listingCount);
      expect(regeneratedSummary.eventCount, firstSummary.eventCount);
      expect([
        for (final listing in regeneratedListings)
          '${listing.optionId}:${listing.priceAt(DateTime(2020, 6))}:'
              '${listing.visibleEventsAt(campaignEnd).map((event) => event.id).join(',')}',
      ], listingFingerprint);
      expect([
        for (final event in regeneratedRegionalEvents)
          '${event.id}:${event.announcedAt.toIso8601String()}:'
              '${event.outcomeAt(campaignEnd)?.name}',
      ], regionalFingerprint);
    });

    test('단지마다 서로 다른 3개 매물이 생성되고 같은 시드는 재현된다', () {
      final asset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final first = realEstateListingsFor(asset, worldSeed);
      final replay = realEstateListingsFor(asset, worldSeed);
      final other = realEstateListingsFor(asset, 'another-world');
      final date = DateTime(2012, 6);

      expect(first, hasLength(3));
      expect(first.map((listing) => listing.priceAt(date)).toSet().length, 3);
      expect(first.first.priceAt(date), replay.first.priceAt(date));
      expect(
        first.first.visibleEventsAt(campaignEnd).length,
        replay.first.visibleEventsAt(campaignEnd).length,
      );
      expect(first.first.priceAt(date), isNot(other.first.priceAt(date)));
    });

    test('v3는 v2 사건을 두 배로 확장하고 모든 매물에 고유 연표를 남긴다', () {
      final count = realEstateGeneratedEventCount(worldSeed);
      final version2Count = realEstateGeneratedEventCount(
        worldSeed,
        generatorVersion: 2,
      );
      final legacyCount = realEstateGeneratedEventCount(
        worldSeed,
        generatorVersion: 1,
      );

      expect(version2Count, inInclusiveRange(700, 1300));
      expect(count, greaterThan(version2Count * 1.9));
      expect(count, lessThan(version2Count * 2.1));
      expect(legacyCount, greaterThan(0));
      expect(
        realEstateMarketCatalog
            .expand((asset) => realEstateListingsFor(asset, worldSeed))
            .every(
              (listing) => listing.visibleEventsAt(campaignEnd).isNotEmpty,
            ),
        isTrue,
      );
    });

    test('15개 인과군과 1만5천개 문장 조합이 실제 사건에서 고르게 사용된다', () {
      final allEvents = <RealEstateWorldEvent>[
        for (final district in realEstateDistrictCatalog)
          ...realEstateVisibleDistrictEventsAt(
            district,
            worldSeed,
            campaignEnd,
          ),
        for (final asset in realEstateMarketCatalog)
          for (final listing in realEstateListingsFor(asset, worldSeed))
            ...listing
                .visibleEventsAt(campaignEnd)
                .where((event) => event.assetId == asset.id),
      ];
      final eventsById = <String, RealEstateWorldEvent>{
        for (final event in allEvents) event.id: event,
      };
      final uniqueEvents = eventsById.values.toList(growable: false);
      final uniqueTitles = uniqueEvents.map((event) => event.title).toSet();
      final kinds = uniqueEvents.map((event) => event.kind).toSet();

      expect(realEstateWorldGeneratorVersion, 3);
      expect(realEstateEventNarrativeCombinationCapacity(), 15000);
      expect(kinds, containsAll(RealEstateWorldEventKind.values));
      expect(uniqueTitles.length, greaterThan(uniqueEvents.length * 0.90));
      expect(uniqueEvents.any((event) => event.announcementImpact > 0), isTrue);
      expect(uniqueEvents.any((event) => event.announcementImpact < 0), isTrue);
      expect(
        uniqueEvents.every(
          (event) =>
              event.unresolvedDetail.contains('단정할 수 없습니다') &&
              !event.unresolvedDetail.contains('확정·완료') &&
              !event.unresolvedDetail.contains('계획 취소'),
        ),
        isTrue,
      );
    });

    test('14개 서울·경기 권역이 모든 기준 자산에 연결된다', () {
      expect(realEstateDistrictCatalog, hasLength(14));
      for (final asset in realEstateMarketCatalog) {
        final district = realEstateDistrictFor(asset);
        expect(district.name, asset.region);
        expect(district.mapX, inInclusiveRange(0, 1));
        expect(district.mapY, inInclusiveRange(0, 1));
      }
    });

    test('같은 성남 권역 자산은 동일한 지역 사건 연표를 공유한다', () {
      final apartment = realEstateMarketAssetById(
        'pangyo_prugio_granbleu_140',
      )!;
      final building = realEstateMarketAssetById('pangyo_techone')!;
      final apartmentEvents = realEstateVisibleWorldEventsAt(
        apartment,
        worldSeed,
        campaignEnd,
      );
      final buildingEvents = realEstateVisibleWorldEventsAt(
        building,
        worldSeed,
        campaignEnd,
      );

      expect(
        apartmentEvents.map((event) => event.id).toList(),
        buildingEvents.map((event) => event.id).toList(),
      );
      expect(apartmentEvents.first.originDistrictId, 'gyeonggi-seongnam');
    });

    test('지역 사건은 가까운 권역에 약하게 전염되고 먼 권역에는 닿지 않는다', () {
      final origin = realEstateMarketAssetById('hannam_the_hill_243')!;
      final nearby = realEstateMarketAssetById('acro_seoul_forest_160')!;
      final far = realEstateMarketAssetById('gwanggyo_jungheung_129')!;
      final event = realEstateVisibleWorldEventsAt(
        origin,
        worldSeed,
        campaignEnd,
      ).first;
      final nearbyFactor = realEstateSpatialSpilloverFactor(nearby, event);

      expect(realEstateSpatialSpilloverFactor(origin, event), 1);
      expect(nearbyFactor, greaterThan(0));
      expect(nearbyFactor, lessThan(1));
      expect(realEstateSpatialSpilloverFactor(far, event), 0);
      expect(
        realEstateVisibleNearbyWorldEventsAt(
          nearby,
          worldSeed,
          campaignEnd,
        ).any((candidate) => candidate.id == event.id),
        isTrue,
      );
      expect(
        realEstateVisibleNearbyWorldEventsAt(
          far,
          worldSeed,
          campaignEnd,
        ).any((candidate) => candidate.id == event.id),
        isFalse,
      );
    });

    test('역 계획은 발표 때 호재여도 지연·취소 결과가 나중에 드러난다', () {
      final events = realEstateDistrictCatalog
          .expand(
            (district) => realEstateVisibleDistrictEventsAt(
              district,
              worldSeed,
              campaignEnd,
            ),
          )
          .where(
            (event) =>
                event.kind == RealEstateWorldEventKind.transitPlan &&
                event.isPotentialUpside &&
                event.outcomeAt(campaignEnd) ==
                    RealEstateWorldEventOutcome.canceled,
          )
          .toList();

      expect(events, isNotEmpty);
      final event = events.first;
      final beforeResolution = event.resolvedAt.subtract(
        const Duration(days: 1),
      );
      expect(event.outcomeAt(beforeResolution), isNull);
      expect(event.statusAt(beforeResolution), '발표·검토 중');
      expect(event.detailAt(beforeResolution), contains('단정할 수 없습니다'));
      expect(event.impactAt(event.announcedAt), greaterThan(0));
      expect(
        event.impactAt(event.resolvedAt.add(const Duration(days: 75))),
        lessThan(0),
      );
      expect(
        event.outcomeAt(event.resolvedAt),
        RealEstateWorldEventOutcome.canceled,
      );
      expect(event.statusAt(event.resolvedAt), '계획 취소');
    });

    test('상승 일변도가 아니라 연간 10% 이상 하락하는 개별 매물이 존재한다', () {
      var decliningListings = 0;
      for (final asset in realEstateMarketCatalog) {
        for (final listing in realEstateListingsFor(asset, worldSeed)) {
          var previous = listing.priceAt(
            DateTime(asset.availableFrom.year, 12),
          );
          var declined = false;
          for (
            var year = asset.availableFrom.year + 1;
            year <= 2026;
            year += 1
          ) {
            final current = listing.priceAt(DateTime(year, 12));
            if (current < previous * 0.90) declined = true;
            previous = current;
          }
          if (declined) decliningListings += 1;
        }
      }

      expect(decliningListings, greaterThanOrEqualTo(3));
    });

    test('v1·v2 월드는 기존 산식을 보존하고 신규 월드만 v3를 사용한다', () {
      final asset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final legacy = realEstateListingsFor(
        asset,
        worldSeed,
        generatorVersion: 1,
      ).first;
      final version2 = realEstateListingsFor(
        asset,
        worldSeed,
        generatorVersion: 2,
      ).first;
      final current = realEstateListingsFor(asset, worldSeed).first;
      final currentAreaFactor =
          current.areaSquareMeters / current.asset.areaSquareMeters;

      expect(legacy.generatorVersion, 1);
      expect(legacy.areaPriceFactor, 1);
      expect(legacy.priceAt(DateTime(2012, 6)), 37112868);
      expect(legacy.monthlyRentAt(DateTime(2012, 6)), 177057);
      expect(legacy.visibleEventsAt(campaignEnd), hasLength(275));
      expect(version2.generatorVersion, 2);
      expect(
        realEstateGeneratedEventCount(worldSeed, generatorVersion: 2),
        1128,
      );
      expect(current.generatorVersion, realEstateWorldGeneratorVersion);
      expect(current.generatorVersion, 3);
      expect(current.areaPriceFactor, closeTo(currentAreaFactor, 0.0000001));
      expect(
        legacy
            .visibleEventsAt(campaignEnd)
            .every(
              (event) =>
                  event.announcedAt.day == 1 && event.resolvedAt.day == 1,
            ),
        isTrue,
      );
      expect(
        current
            .visibleEventsAt(campaignEnd)
            .every(
              (event) =>
                  event.announcedAt.day >= 3 &&
                  event.announcedAt.day <= 27 &&
                  event.resolvedAt.day >= 3 &&
                  event.resolvedAt.day <= 27,
            ),
        isTrue,
      );
      expect(
        realEstateListingLifecyclesAt(
          asset,
          worldSeed,
          DateTime(2026, 6),
          generatorVersion: 1,
        ).every((state) => state.isActive),
        isTrue,
      );
      expect(
        () => const FictionalRealEstateWorld(
          worldSeed: worldSeed,
          generatorVersion: 999,
        ).asOf(DateTime(2000)),
        throwsFormatException,
      );
    });

    test('생성된 면적 차이가 같은 매물 산식의 실제 가격에 비례 반영된다', () {
      final asset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final listing = realEstateListingsFor(asset, 'area-price-test').first;
      final withoutArea = GeneratedRealEstateListing(
        worldSeed: listing.worldSeed,
        asset: listing.asset,
        index: listing.index,
        generatorVersion: listing.generatorVersion,
        areaSquareMeters: listing.areaSquareMeters,
        floor: listing.floor,
        stationWalkMinutes: listing.stationWalkMinutes,
        condition: listing.condition,
        priceFactor: listing.priceFactor,
        areaPriceFactor: 1,
        rentFactor: listing.rentFactor,
        operatingCostFactor: listing.operatingCostFactor,
        downsideExposure: listing.downsideExposure,
        riskSummary: listing.riskSummary,
      );
      final date = DateTime(2015, 6, 15);

      expect(listing.areaPriceFactor, isNot(closeTo(1, 0.000001)));
      expect(
        listing.priceAt(date),
        closeTo(withoutArea.priceAt(date) * listing.areaPriceFactor, 2),
      );
    });

    test('날짜별 매물은 NPC 매수·만료 뒤 재등록되고 과도하게 사라지지 않는다', () {
      final statuses = <RealEstateListingAvailability>{};
      final instanceIds = <String>{};
      for (final asset in realEstateMarketCatalog) {
        var date = asset.availableFrom;
        while (!date.isAfter(campaignEnd)) {
          final lifecycles = realEstateListingLifecyclesAt(
            asset,
            worldSeed,
            date,
          );
          final active = lifecycles.where((state) => state.isActive).length;
          expect(active, greaterThanOrEqualTo(2));
          statuses.addAll(lifecycles.map((state) => state.availability));
          instanceIds.addAll(
            lifecycles.map((state) => state.listingInstanceId),
          );
          expect(
            realEstateActiveListingsAt(asset, worldSeed, date).length,
            active,
          );
          date = DateTime(date.year, date.month + 3, date.day);
        }
      }

      expect(statuses, contains(RealEstateListingAvailability.active));
      expect(statuses, contains(RealEstateListingAvailability.npcPurchased));
      expect(statuses, contains(RealEstateListingAvailability.expired));
      expect(
        instanceIds.length,
        greaterThan(realEstateMarketCatalog.length * 3),
      );

      final view = const FictionalRealEstateWorld(
        worldSeed: worldSeed,
      ).asOf(DateTime(2000, 1, 2));
      expect(view.assets.any((asset) => asset.id == 'pangyo_techone'), isFalse);
      expect(
        view.listingsFor(view.assets.first),
        hasLength(greaterThanOrEqualTo(2)),
      );
    });

    test('임대료 사건도 가격처럼 거리 감쇠되고 건물 상태가 수리 위험에 반영된다', () {
      final rentKinds = {
        RealEstateWorldEventKind.vacancyShock,
        RealEstateWorldEventKind.supplyWave,
        RealEstateWorldEventKind.employerMove,
      };
      RealEstateWorldEvent? selectedEvent;
      RealEstateMarketAsset? originAsset;
      RealEstateMarketAsset? nearbyAsset;
      for (final candidateOrigin in realEstateMarketCatalog) {
        for (final event in realEstateVisibleWorldEventsAt(
          candidateOrigin,
          worldSeed,
          campaignEnd,
        )) {
          if (!rentKinds.contains(event.kind)) continue;
          for (final candidateNearby in realEstateMarketCatalog) {
            final factor = realEstateSpatialSpilloverFactor(
              candidateNearby,
              event,
            );
            if (factor > 0 && factor < 1) {
              selectedEvent = event;
              originAsset = candidateOrigin;
              nearbyAsset = candidateNearby;
              break;
            }
          }
          if (selectedEvent != null) break;
        }
        if (selectedEvent != null) break;
      }
      expect(selectedEvent, isNotNull);
      final date = selectedEvent!.resolvedAt.add(const Duration(days: 45));
      final originListing = realEstateListingsFor(
        originAsset!,
        worldSeed,
      ).first;
      final nearbyListing = realEstateListingsFor(
        nearbyAsset!,
        worldSeed,
      ).first;
      final originContribution = originListing.rentEventImpactContribution(
        selectedEvent,
        date,
      );
      final nearbyContribution = nearbyListing.rentEventImpactContribution(
        selectedEvent,
        date,
      );
      expect(nearbyContribution.abs(), lessThan(originContribution.abs()));

      final earlyListings = realEstateMarketCatalog
          .where((asset) => asset.availableFrom.year == 2000)
          .expand((asset) => realEstateListingsFor(asset, 'condition-risk'))
          .toList();
      final needsRepair = earlyListings.firstWhere(
        (listing) =>
            listing.condition == RealEstateListingCondition.needsRepair,
      );
      final renovated = earlyListings.firstWhere(
        (listing) => listing.condition == RealEstateListingCondition.renovated,
      );
      final baselineDate = DateTime(2000, 2);
      expect(
        needsRepair.riskFactorsAt(baselineDate).repairProbabilityMultiplier,
        greaterThan(
          renovated.riskFactorsAt(baselineDate).repairProbabilityMultiplier,
        ),
      );
      expect(
        needsRepair.riskFactorsAt(baselineDate).repairCostMultiplier,
        greaterThan(renovated.riskFactorsAt(baselineDate).repairCostMultiplier),
      );
    });

    test('완공 교통·재개발은 일부 가치가 영구 잔존하고 명시적 악재는 하락 방향이다', () {
      final allEvents = realEstateDistrictCatalog
          .expand(
            (district) => realEstateVisibleDistrictEventsAt(
              district,
              worldSeed,
              campaignEnd,
            ),
          )
          .toList();
      final completedInfrastructure = allEvents.firstWhere(
        (event) =>
            event.isPotentialUpside &&
            (event.kind == RealEstateWorldEventKind.transitPlan ||
                event.kind == RealEstateWorldEventKind.redevelopment) &&
            event.outcomeAt(campaignEnd) ==
                RealEstateWorldEventOutcome.completed,
      );
      final afterDecay = completedInfrastructure.resolvedAt.add(
        Duration(days: completedInfrastructure.impactDurationDays + 30),
      );
      expect(completedInfrastructure.impactAt(afterDecay), greaterThan(0));
      expect(
        completedInfrastructure.impactAt(afterDecay),
        lessThan(
          completedInfrastructure.impactAt(
            completedInfrastructure.resolvedAt.add(const Duration(days: 30)),
          ),
        ),
      );

      final explicitBadNews = allEvents.where(
        (event) =>
            event.title.contains('조합 분담금 갈등') ||
            event.title.contains('학교 통폐합 계획') ||
            event.title.contains('역사 출입구 위치 논쟁'),
      );
      expect(explicitBadNews, isNotEmpty);
      expect(
        explicitBadNews.every(
          (event) => !event.isPotentialUpside && event.announcementImpact < 0,
        ),
        isTrue,
      );
    });

    test('여러 시드 27년 회귀에서 월점프·낙폭·CAGR·매물 가용성이 범위 안이다', () {
      const seeds = [
        'real-estate-balance-a',
        'real-estate-balance-b',
        'real-estate-balance-c',
        'real-estate-balance-d',
      ];
      final sampleAssets = [
        for (final tier in RealEstateInvestmentTier.values)
          realEstateMarketCatalog.firstWhere((asset) => asset.tier == tier),
      ];
      final cagrValues = <double>[];
      final drawdowns = <double>[];
      var maximumMonthlyJump = 0.0;
      var maximumMonthBoundaryJump = 0.0;
      var maximumMaterialEventCount = 0;

      for (final seed in seeds) {
        for (final asset in sampleAssets) {
          final listing = realEstateListingsFor(asset, seed).first;
          final prices = <int>[];
          var date = DateTime(
            asset.availableFrom.year,
            asset.availableFrom.month,
            15,
          );
          while (!date.isAfter(campaignEnd)) {
            prices.add(listing.priceAt(date));
            expect(
              realEstateActiveListingsAt(asset, seed, date).length,
              greaterThanOrEqualTo(2),
            );
            maximumMaterialEventCount = math.max(
              maximumMaterialEventCount,
              listing
                  .visibleEventsAt(date)
                  .where(
                    (event) =>
                        event.impactAt(date).abs() >= 0.002 &&
                        realEstateSpatialSpilloverFactor(asset, event) > 0,
                  )
                  .length,
            );
            final monthStart = DateTime(date.year, date.month, 1);
            if (monthStart.isAfter(asset.availableFrom)) {
              final before = listing.priceAt(
                monthStart.subtract(const Duration(days: 1)),
              );
              final after = listing.priceAt(monthStart);
              maximumMonthBoundaryJump = math.max(
                maximumMonthBoundaryJump,
                (after - before).abs() / before,
              );
            }
            date = DateTime(date.year, date.month + 1, 15);
          }
          var peak = prices.first.toDouble();
          var maximumDrawdown = 0.0;
          for (var index = 1; index < prices.length; index += 1) {
            final previous = prices[index - 1];
            final current = prices[index];
            maximumMonthlyJump = math.max(
              maximumMonthlyJump,
              (current - previous).abs() / previous,
            );
            peak = math.max(peak, current.toDouble());
            maximumDrawdown = math.max(
              maximumDrawdown,
              (peak - current) / peak,
            );
          }
          final years =
              campaignEnd.difference(asset.availableFrom).inDays / 365.25;
          cagrValues.add(
            math.pow(prices.last / prices.first, 1 / years).toDouble() - 1,
          );
          drawdowns.add(maximumDrawdown);
        }
      }

      cagrValues.sort();
      drawdowns.sort();
      final medianCagr = cagrValues[cagrValues.length ~/ 2];
      final medianDrawdown = drawdowns[drawdowns.length ~/ 2];
      expect(maximumMonthBoundaryJump, lessThan(0.012));
      expect(maximumMonthlyJump, lessThan(0.16));
      expect(maximumMaterialEventCount, lessThanOrEqualTo(30));
      expect(medianCagr, inInclusiveRange(-0.02, 0.13));
      expect(medianDrawdown, greaterThan(0.05));
      expect(drawdowns.last, lessThan(0.55));
    });

    test('개별 매입은 매물 번호와 월드 시드를 저장하고 다시 복원한다', () {
      const engine = GameEngine();
      final initial = engine
          .createNewGame('개별 부동산 테스트', initialCash: 200000000)
          .copyWith(
            simulationSeed: worldSeed,
            brokerageCash: 0,
            decisions: const [],
          );
      final asset = realEstateMarketAssetById(
        'uijeongbu_station_officetel_20',
      )!;
      final listing = realEstateListingsFor(asset, worldSeed).first;
      final quote = listing.quoteAt(initial.currentDate);

      final result = engine.purchaseSpendingOption(initial, listing.optionId);

      expect(result.success, isTrue);
      expect(result.cashDelta, -quote.totalCash);
      final owned = result.state.personalFinance.realEstate.single;
      expect(owned.marketListingIndex, listing.index);
      expect(owned.realEstateWorldSeed, worldSeed);
      expect(
        owned.estimatedMarketValue(result.state.day),
        listing.priceAt(initial.currentDate),
      );
      final restored = OwnedRealEstate.fromJson(owned.toJson());
      expect(restored.marketListingIndex, listing.index);
      expect(restored.realEstateWorldSeed, worldSeed);
      expect(restored.generatedListing?.optionId, listing.optionId);
    });
  });
}
