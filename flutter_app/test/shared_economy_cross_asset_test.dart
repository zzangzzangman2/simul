import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/business_districts.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_world.dart';
import 'package:millennium_capital/game/world_economy.dart';

void main() {
  const worldSeed = 'shared-economy-cross-asset';
  const eventId = 'historical-2008_global_bank_failure';
  const businessDistrictId = 'gyeonggi_uijeongbu_station';
  final disclosureDay = DateTime(2008, 9, 16);
  final propagationDay = DateTime(2008, 9, 17);
  final property = realEstateMarketAssetById('uijeongbu_station_officetel_20')!;

  int occurrenceCount(Iterable<String> ids) =>
      ids.where((id) => id == eventId).length;

  void expectUniqueIds(Iterable<String> ids, String source) {
    final values = ids.toList(growable: false);
    expect(
      values.toSet().length,
      values.length,
      reason: '$source must not expose duplicate event IDs.',
    );
  }

  test(
    'one stock event propagates to the mapped business and property next day',
    () {
      final propertyDistrict = realEstateDistrictFor(property);
      expect(propertyDistrict.id, 'gyeonggi-uijeongbu');
      expect(
        worldEconomyBusinessDistrictIdForRealEstateDistrict(
          propertyDistrict.id,
        ),
        businessDistrictId,
      );

      final stockEvents = fictionalMarketEventsForDate(
        worldSeed,
        disclosureDay,
      );
      final exportedEvents = fictionalSharedEconomyEventsThrough(
        worldSeed,
        disclosureDay,
      );
      final stockEvent = stockEvents.singleWhere(
        (event) => event.id == eventId,
      );
      final exportedEvent = exportedEvents.singleWhere(
        (event) => event.id == eventId,
      );

      expect(occurrenceCount(stockEvents.map((event) => event.id)), 1);
      expect(occurrenceCount(exportedEvents.map((event) => event.id)), 1);
      expect(exportedEvent.id, stockEvent.id);
      expect(exportedEvent.date, stockEvent.date);
      expect(exportedEvent.title, stockEvent.title);
      expect(exportedEvent.impactPct, stockEvent.impactPct);
      expectUniqueIds(
        stockEvents.map((event) => event.id),
        'stock daily events',
      );
      expectUniqueIds(
        exportedEvents.map((event) => event.id),
        'stock shared-economy export',
      );

      final worldOnDisclosure = worldEconomySnapshot(
        worldSeed: worldSeed,
        asOf: disclosureDay,
        regionKeys: const [businessDistrictId, 'gyeonggi-uijeongbu'],
      );
      final businessOnDisclosure = businessDistrictSnapshot(
        districtId: businessDistrictId,
        asOf: disclosureDay,
        worldSeed: worldSeed,
        generatorVersion: 2,
      );
      final propertyV4 = realEstateListingsFor(
        property,
        worldSeed,
        generatorVersion: 4,
      ).first;
      final propertyOnDisclosure = propertyV4.visibleWorldEconomyEventsAt(
        disclosureDay,
      );

      expect(
        occurrenceCount(
          worldOnDisclosure.revealedEvents.map((event) => event.id),
        ),
        0,
      );
      expect(
        occurrenceCount(
          businessOnDisclosure.revealedEvents.map((event) => event.id),
        ),
        0,
      );
      expect(occurrenceCount(propertyOnDisclosure.map((event) => event.id)), 0);

      final worldOnPropagation = worldEconomySnapshot(
        worldSeed: worldSeed,
        asOf: propagationDay,
        regionKeys: const [businessDistrictId, 'gyeonggi-uijeongbu'],
      );
      final businessOnPropagation = businessDistrictSnapshot(
        districtId: businessDistrictId,
        asOf: propagationDay,
        worldSeed: worldSeed,
        generatorVersion: 2,
      );
      final propertyOnPropagation = propertyV4.visibleWorldEconomyEventsAt(
        propagationDay,
      );
      final worldEvent = worldOnPropagation.revealedEvents.singleWhere(
        (event) => event.id == eventId,
      );
      final businessEvent = businessOnPropagation.revealedEvents.singleWhere(
        (event) => event.id == eventId,
      );
      final propertyEvent = propertyOnPropagation.singleWhere(
        (event) => event.id == eventId,
      );

      expect(
        occurrenceCount(
          worldOnPropagation.revealedEvents.map((event) => event.id),
        ),
        1,
      );
      expect(
        occurrenceCount(
          businessOnPropagation.revealedEvents.map((event) => event.id),
        ),
        1,
      );
      expect(
        occurrenceCount(propertyOnPropagation.map((event) => event.id)),
        1,
      );
      expect(worldEvent.id, stockEvent.id);
      expect(worldEvent.occurredOn, disclosureDay);
      expect(worldEvent.revealedOn, propagationDay);
      expect(worldEvent.title, stockEvent.title);
      expect(businessEvent.id, stockEvent.id);
      expect(businessEvent.occurredOn, disclosureDay);
      expect(businessEvent.revealedOn, propagationDay);
      expect(businessEvent.headline, contains(stockEvent.title));
      expect(propertyEvent.id, stockEvent.id);
      expect(propertyEvent.occurredOn, disclosureDay);
      expect(propertyEvent.revealedOn, propagationDay);
      expect(propertyEvent.title, stockEvent.title);

      for (final entry in <String, Iterable<String>>{
        'world disclosure day': worldOnDisclosure.revealedEvents.map(
          (event) => event.id,
        ),
        'business disclosure day': businessOnDisclosure.revealedEvents.map(
          (event) => event.id,
        ),
        'property disclosure day': propertyOnDisclosure.map(
          (event) => event.id,
        ),
        'world propagation day': worldOnPropagation.revealedEvents.map(
          (event) => event.id,
        ),
        'business propagation day': businessOnPropagation.revealedEvents.map(
          (event) => event.id,
        ),
        'property propagation day': propertyOnPropagation.map(
          (event) => event.id,
        ),
      }.entries) {
        expectUniqueIds(entry.value, entry.key);
      }

      final legacyBusiness = businessDistrictSnapshot(
        districtId: businessDistrictId,
        asOf: propagationDay,
        worldSeed: worldSeed,
        generatorVersion: 1,
      );
      final legacyProperty = realEstateListingsFor(
        property,
        worldSeed,
        generatorVersion: 3,
      ).first;

      expect(
        occurrenceCount(legacyBusiness.revealedEvents.map((event) => event.id)),
        0,
      );
      expect(
        legacyProperty.visibleWorldEconomyEventsAt(propagationDay),
        isEmpty,
      );
      expect(
        occurrenceCount(
          businessDistrictSnapshot(
            districtId: businessDistrictId,
            asOf: DateTime(2026, 12, 31),
            worldSeed: worldSeed,
            generatorVersion: 1,
          ).revealedEvents.map((event) => event.id),
        ),
        0,
      );
      expect(
        legacyProperty.visibleWorldEconomyEventsAt(DateTime(2026, 12, 31)),
        isEmpty,
      );
    },
  );
}
