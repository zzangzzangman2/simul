import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/world_economy.dart';

void main() {
  const seed = 'world-economy-core';

  test(
    'shared snapshot is deterministic for the same seed, day, and region',
    () {
      final first = worldEconomySnapshot(
        worldSeed: seed,
        asOf: DateTime(2008, 9, 16, 23, 59),
        regionKeys: const ['seoul_gangnam_station', 'capital', 'office'],
      );
      final second = worldEconomySnapshot(
        worldSeed: seed,
        asOf: DateTime(2008, 9, 16),
        regionKeys: const ['office', 'capital', 'seoul_gangnam_station'],
      );

      expect(first.asOf, second.asOf);
      expect(first.regionKeys, second.regionKeys);
      expect(first.businessImpact.demand, second.businessImpact.demand);
      expect(first.businessImpact.rent, second.businessImpact.rent);
      expect(
        first.businessImpact.competition,
        second.businessImpact.competition,
      );
      expect(first.businessImpact.wage, second.businessImpact.wage);
      expect(first.businessImpact.vacancy, second.businessImpact.vacancy);
      expect(first.businessImpact.risk, second.businessImpact.risk);
      expect(first.businessImpact.vitality, second.businessImpact.vitality);
      expect(first.realEstateImpact.price, second.realEstateImpact.price);
      expect(first.realEstateImpact.rent, second.realEstateImpact.rent);
      expect(first.realEstateImpact.vacancy, second.realEstateImpact.vacancy);
      expect(first.realEstateImpact.risk, second.realEstateImpact.risk);
      expect(
        first.realEstateImpact.repairCost,
        second.realEstateImpact.repairCost,
      );
      expect(
        first.realEstateImpact.liquidity,
        second.realEstateImpact.liquidity,
      );
      expect(
        first.revealedEvents.map((event) => event.id),
        second.revealedEvents.map((event) => event.id),
      );
    },
  );

  test('date-only assets receive intraday stock news on the next day', () {
    final stockDisclosureDay = worldEconomySnapshot(
      worldSeed: seed,
      asOf: DateTime(2008, 9, 16, 23, 59),
    );
    final propagatedDay = worldEconomySnapshot(
      worldSeed: seed,
      asOf: DateTime(2008, 9, 17),
    );

    expect(
      stockDisclosureDay.revealedEvents.map((event) => event.id),
      isNot(contains('historical-2008_global_bank_failure')),
    );
    expect(
      propagatedDay.revealedEvents.map((event) => event.id),
      contains('historical-2008_global_bank_failure'),
    );
    final failure = propagatedDay.revealedEvents.singleWhere(
      (event) => event.id == 'historical-2008_global_bank_failure',
    );
    expect(failure.occurredOn, DateTime(2008, 9, 16));
    expect(failure.revealedOn, DateTime(2008, 9, 17));
    expect(
      stockDisclosureDay.revealedEvents.every(
        (event) =>
            !event.occurredOn.isAfter(stockDisclosureDay.asOf) &&
            !event.revealedOn.isAfter(stockDisclosureDay.asOf),
      ),
      isTrue,
    );
    expect(
      stockDisclosureDay.revealedEvents.length,
      lessThanOrEqualTo(worldEconomyRecentEventLimit),
    );
  });

  test(
    'the already-seeded stock impact makes worlds vary without rehashing',
    () {
      final first = worldEconomySnapshot(
        worldSeed: 'world-economy-alpha',
        asOf: DateTime(2008, 9, 17),
      );
      final second = worldEconomySnapshot(
        worldSeed: 'world-economy-beta',
        asOf: DateTime(2008, 9, 17),
      );
      final firstEvent = first.revealedEvents.singleWhere(
        (event) => event.id == 'historical-2008_global_bank_failure',
      );
      final secondEvent = second.revealedEvents.singleWhere(
        (event) => event.id == 'historical-2008_global_bank_failure',
      );

      expect(
        firstEvent.sourceMarketImpact,
        isNot(secondEvent.sourceMarketImpact),
      );
      expect(first.businessImpact.demand, isNot(second.businessImpact.demand));
      expect(
        first.realEstateImpact.price,
        isNot(second.realEstateImpact.price),
      );
    },
  );

  test('2008 event keeps the canonical stock ID, date, title, and impact', () {
    const worldSeed = 'world-economy-event-identity';
    final sourceDate = DateTime(2008, 9, 16);
    final asOf = DateTime(2008, 9, 17);
    final source = fictionalSharedEconomyEventsThrough(
      worldSeed,
      sourceDate,
    ).singleWhere((event) => event.id == 'historical-2008_global_bank_failure');
    final projected = worldEconomySnapshot(
      worldSeed: worldSeed,
      asOf: asOf,
    ).revealedEvents.singleWhere((event) => event.id == source.id);

    expect(projected.id, source.id);
    expect(projected.occurredOn, sourceDate);
    expect(projected.revealedOn, asOf);
    expect(projected.title, source.title);
    expect(projected.summary, source.body);
    expect(projected.sourceMarketImpact, source.impactPct);
    expect(projected.isActive, isTrue);
    expect(projected.kind, WorldEconomyEventKind.creditShock);
  });

  test('explicit policy and currency events keep their economic kind', () {
    final policySnapshot = worldEconomySnapshot(
      worldSeed: seed,
      asOf: DateTime(2008, 10, 9),
    );
    final policy = policySnapshot.revealedEvents.singleWhere(
      (event) => event.id == 'historical-2008_coordinated_rate_cut',
    );
    expect(policy.kind, WorldEconomyEventKind.policySupport);

    final tradeSnapshot = worldEconomySnapshot(
      worldSeed: seed,
      asOf: DateTime(2008, 10, 31),
    );
    final currency = tradeSnapshot.revealedEvents.singleWhere(
      (event) => event.id == 'historical-2008_currency_swap',
    );
    expect(currency.kind, WorldEconomyEventKind.trade);
  });

  test('explicit geopolitical identity outranks finance and FX prose', () {
    final snapshot = worldEconomySnapshot(
      worldSeed: seed,
      asOf: DateTime(2006, 10, 10),
    );
    final event = snapshot.revealedEvents.singleWhere(
      (event) => event.id == 'historical-2006_geopolitical_test',
    );
    expect(event.kind, WorldEconomyEventKind.geopolitical);
  });

  test('business and property projections stay inside their public clamps', () {
    final snapshot = worldEconomySnapshot(
      worldSeed: seed,
      asOf: DateTime(2026, 12, 31),
      regionKeys: const ['tourism', 'office', 'newTown', 'capital'],
    );
    final business = snapshot.businessImpact;
    final property = snapshot.realEstateImpact;

    expect(business.demand, inInclusiveRange(-0.35, 0.35));
    expect(business.rent, inInclusiveRange(-0.20, 0.24));
    expect(business.competition, inInclusiveRange(-0.18, 0.18));
    expect(business.wage, inInclusiveRange(-0.14, 0.16));
    expect(business.vacancy, inInclusiveRange(-0.12, 0.15));
    expect(business.risk, inInclusiveRange(-0.25, 0.30));
    expect(business.vitality, inInclusiveRange(-0.30, 0.30));
    expect(property.price, inInclusiveRange(-0.30, 0.32));
    expect(property.rent, inInclusiveRange(-0.18, 0.20));
    expect(property.vacancy, inInclusiveRange(-0.10, 0.14));
    expect(property.risk, inInclusiveRange(-0.25, 0.30));
    expect(property.repairCost, inInclusiveRange(-0.15, 0.25));
    expect(property.liquidity, inInclusiveRange(-0.30, 0.30));
  });

  test('all 14 property districts and legacy region names map centrally', () {
    const expected = <String, String>{
      'gyeonggi-uijeongbu': 'gyeonggi_uijeongbu_station',
      'gyeonggi-goyang': 'gyeonggi_ilsan_lafesta',
      'seoul-nowon': 'seoul_nowon_station',
      'seoul-jongno': 'seoul_jongno',
      'seoul-seongdong': 'seoul_seongsu',
      'seoul-yongsan': 'seoul_yongsan_station',
      'gyeonggi-bucheon': 'gyeonggi_bucheon_sangdong',
      'seoul-guro': 'seoul_guro_digital',
      'seoul-seocho': 'seoul_gangnam_station',
      'seoul-gangnam': 'seoul_gangnam_station',
      'seoul-songpa': 'seoul_jamsil',
      'gyeonggi-gwacheon': 'gyeonggi_gwacheon_central',
      'gyeonggi-seongnam': 'gyeonggi_pangyo',
      'gyeonggi-suwon': 'gyeonggi_suwon_station',
    };

    expect(worldEconomyBusinessDistrictByRealEstateDistrict, expected);
    for (final entry in expected.entries) {
      expect(
        worldEconomyBusinessDistrictIdForRealEstateDistrict(entry.key),
        entry.value,
      );
    }
    expect(
      worldEconomyBusinessDistrictIdForRealEstateRegion(
        '강남구',
        province: '서울특별시',
      ),
      'seoul_gangnam_station',
    );
    expect(
      worldEconomyBusinessDistrictIdForRealEstateRegion('성남시', province: '경기도'),
      'gyeonggi_pangyo',
    );
    expect(
      worldEconomyBusinessDistrictIdForRealEstateRegion('분당'),
      'gyeonggi_bundang_seohyeon',
    );
    expect(
      worldEconomyBusinessDistrictIdForRealEstateRegion('알 수 없는 지역'),
      isNull,
    );
  });
}
