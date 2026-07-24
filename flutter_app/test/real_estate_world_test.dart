import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/personal_finance_state.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_world.dart';

void main() {
  group('시드 기반 서울·경기 부동산 월드', () {
    const worldSeed = 'real-estate-event-test';

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
      expect(first.first.events.length, replay.first.events.length);
      expect(first.first.priceAt(date), isNot(other.first.priceAt(date)));
    });

    test('카탈로그 전체에서 천 건 이상의 고유 지역·개별 매물 사건이 생성된다', () {
      final count = realEstateGeneratedEventCount(worldSeed);

      expect(count, greaterThan(1000));
      expect(
        realEstateMarketCatalog
            .expand((asset) => realEstateListingsFor(asset, worldSeed))
            .every((listing) => listing.events.isNotEmpty),
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
      final apartmentEvents = realEstateWorldEventsFor(apartment, worldSeed);
      final buildingEvents = realEstateWorldEventsFor(building, worldSeed);

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
      final event = realEstateWorldEventsFor(origin, worldSeed).first;
      final nearbyFactor = realEstateSpatialSpilloverFactor(nearby, event);

      expect(realEstateSpatialSpilloverFactor(origin, event), 1);
      expect(nearbyFactor, greaterThan(0));
      expect(nearbyFactor, lessThan(1));
      expect(realEstateSpatialSpilloverFactor(far, event), 0);
      expect(
        realEstateNearbyWorldEventsFor(
          nearby,
          worldSeed,
        ).any((candidate) => candidate.id == event.id),
        isTrue,
      );
      expect(
        realEstateNearbyWorldEventsFor(
          far,
          worldSeed,
        ).any((candidate) => candidate.id == event.id),
        isFalse,
      );
    });

    test('역 계획은 발표 때 호재여도 지연·취소 결과가 나중에 드러난다', () {
      final events = realEstateDistrictCatalog
          .expand(
            (district) =>
                realEstateRegionalEventsForDistrict(district, worldSeed),
          )
          .where(
            (event) =>
                event.kind == RealEstateWorldEventKind.transitPlan &&
                event.outcome == RealEstateWorldEventOutcome.canceled,
          )
          .toList();

      expect(events, isNotEmpty);
      final event = events.first;
      final beforeResolution = event.resolvedAt.subtract(
        const Duration(days: 1),
      );
      expect(event.statusAt(beforeResolution), '발표·검토 중');
      expect(event.detailAt(beforeResolution), contains('확정으로 볼 수 없습니다'));
      expect(event.impactAt(event.announcedAt), greaterThan(0));
      expect(event.impactAt(event.resolvedAt), lessThan(0));
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
