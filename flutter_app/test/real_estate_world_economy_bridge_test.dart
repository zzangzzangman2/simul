import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/personal_finance_state.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_world.dart';

void main() {
  const worldSeed = 'real-estate-event-test';
  final asset = realEstateMarketAssetById('uijeongbu_station_officetel_20')!;

  test('v3 price, rent, and risk fingerprint stays frozen', () {
    final listing = realEstateListingsFor(
      asset,
      worldSeed,
      generatorVersion: 3,
    ).first;
    final dates = <DateTime>[
      DateTime(2008, 10, 15),
      DateTime(2012, 6, 15),
      DateTime(2020, 4, 15),
      DateTime(2026, 6, 15),
    ];

    expect(dates.map(listing.priceAt).toList(), <int>[
      49054279,
      49190878,
      68395054,
      64115796,
    ]);
    expect(dates.map(listing.monthlyRentAt).toList(), <int>[
      296508,
      334107,
      429640,
      496302,
    ]);
    final vacancies = dates
        .map((date) => listing.riskFactorsAt(date).vacancyMultiplier)
        .toList();
    expect(vacancies[0], closeTo(0.911456633936, 0.000000000001));
    expect(vacancies[1], closeTo(0.939575574418, 0.000000000001));
    expect(vacancies[2], closeTo(0.933184883343, 0.000000000001));
    expect(vacancies[3], closeTo(0.935504942450, 0.000000000001));
  });

  test(
    'v4 shared-economy projection differs and replays deterministically',
    () {
      final first = realEstateListingsFor(
        asset,
        worldSeed,
        generatorVersion: 4,
      ).first;
      final replay = realEstateListingsFor(
        asset,
        worldSeed,
        generatorVersion: 4,
      ).first;
      final legacy = realEstateListingsFor(
        asset,
        worldSeed,
        generatorVersion: 3,
      ).first;
      final date = DateTime(2008, 10, 15);

      expect(first.priceAt(date), replay.priceAt(date));
      expect(first.monthlyRentAt(date), replay.monthlyRentAt(date));
      expect(
        first.riskFactorsAt(date).vacancyMultiplier,
        replay.riskFactorsAt(date).vacancyMultiplier,
      );
      expect(first.priceAt(date), isNot(legacy.priceAt(date)));
      expect(first.monthlyRentAt(date), isNot(legacy.monthlyRentAt(date)));
      expect(
        first.riskFactorsAt(date).repairProbabilityMultiplier,
        isNot(legacy.riskFactorsAt(date).repairProbabilityMultiplier),
      );
    },
  );

  test('property exposes canonical stock event without future leakage', () {
    final listing = realEstateListingsFor(
      asset,
      worldSeed,
      generatorVersion: 4,
    ).first;
    final before = DateTime(2008, 9, 16);
    final onEvent = DateTime(2008, 9, 17);

    expect(
      listing.visibleWorldEconomyEventsAt(before).map((event) => event.id),
      isNot(contains('historical-2008_global_bank_failure')),
    );
    final visible = listing.visibleWorldEconomyEventsAt(onEvent);
    expect(
      visible.map((event) => event.id),
      contains('historical-2008_global_bank_failure'),
    );
    expect(
      visible.every(
        (event) =>
            !event.occurredOn.isAfter(onEvent) &&
            !event.revealedOn.isAfter(onEvent),
      ),
      isTrue,
    );
    expect(
      realEstateListingsFor(
        asset,
        worldSeed,
        generatorVersion: 3,
      ).first.visibleWorldEconomyEventsAt(onEvent),
      isEmpty,
    );
  });

  test(
    'v4 keeps local commercial and demographic events numerically active',
    () {
      final listing = realEstateListingsFor(
        asset,
        worldSeed,
        generatorVersion: 4,
      ).first;
      final events = listing.visibleEventsAt(DateTime(2026, 12, 31));
      RealEstateWorldEvent? localEvent;
      var contribution = 0.0;
      for (final event in events) {
        if (event.kind != RealEstateWorldEventKind.commercialCycle &&
            event.kind != RealEstateWorldEventKind.demographicShift) {
          continue;
        }
        final date = event.announcedAt.add(const Duration(days: 10));
        contribution = listing.rentEventImpactContribution(event, date);
        if (contribution != 0) {
          localEvent = event;
          break;
        }
      }

      expect(localEvent, isNotNull);
      expect(contribution, isNot(0));

      final observationOnly = events.firstWhere(
        (event) => event.isObservationOnly,
      );
      expect(
        observationOnly.statusAt(observationOnly.announcedAt),
        contains('관측용'),
      );
      expect(
        observationOnly.detailAt(observationOnly.announcedAt),
        contains('참고용'),
      );
    },
  );

  test(
    'v4 liquidity changes active listing duration before the same relist',
    () {
      RealEstateListingLifecycle? version3;
      RealEstateListingLifecycle? version4;
      for (
        var seedIndex = 0;
        seedIndex < 30 && version4 == null;
        seedIndex += 1
      ) {
        final seed = 'liquidity-seed-$seedIndex';
        for (var year = 2001; year <= 2026 && version4 == null; year += 1) {
          final date = DateTime(year, 12, 31);
          final legacy = realEstateListingLifecyclesAt(
            asset,
            seed,
            date,
            generatorVersion: 3,
          );
          final current = realEstateListingLifecyclesAt(
            asset,
            seed,
            date,
            generatorVersion: 4,
          );
          for (var index = 0; index < legacy.length; index += 1) {
            if (legacy[index].expiresAt != current[index].expiresAt &&
                legacy[index].availability != current[index].availability) {
              version3 = legacy[index];
              version4 = current[index];
              break;
            }
          }
        }
      }

      if (version3 == null || version4 == null) {
        fail(
          'Expected at least one deterministic v4 liquidity duration change.',
        );
      }
      expect(version3.expiresAt, isNot(version4.expiresAt));
      expect(version3.relistsAt, version4.relistsAt);
      expect(version3.availability, isNot(version4.availability));
    },
  );

  test(
    'sale wait follows v4 listing-date liquidity while v1-v3 stay frozen',
    () {
      final listedAt = DateTime(2008, 9, 17);
      final liquidity = realEstateWorldLiquidityAt(
        asset,
        worldSeed,
        listedAt,
        generatorVersion: 4,
      );
      expect(liquidity, isNegative);
      expect(
        realEstateWorldLiquidityAt(
          asset,
          worldSeed,
          listedAt,
          generatorVersion: 3,
        ),
        0,
      );

      String? ownedId;
      for (var index = 0; index < 100; index += 1) {
        final candidate = 'owned-liquidity-$index';
        final baseline = realEstateSaleListingDays(
          type: asset.type,
          worldSeed: worldSeed,
          assetId: candidate,
          listedDay: 1,
        );
        final adjusted = realEstateSaleListingDays(
          type: asset.type,
          worldSeed: worldSeed,
          assetId: candidate,
          listedDay: 1,
          liquidity: liquidity,
        );
        if (adjusted != baseline) {
          ownedId = candidate;
          break;
        }
      }
      expect(ownedId, isNotNull);

      final current = OwnedRealEstate(
        id: ownedId!,
        optionId: realEstateListingOptionId(asset.id, 0),
        name: '유동성 연결 매물',
        purchasePrice: 50000000,
        acquiredDay: 1,
        monthlyIncome: 0,
        monthlyCost: 0,
        marketAssetId: asset.id,
        purchaseDateIso: listedAt.toIso8601String(),
        marketListingIndex: 0,
        realEstateWorldSeed: worldSeed,
        realEstateWorldVersion: 4,
        saleListedDay: 1,
      );
      final legacy = current.copyWith(realEstateWorldVersion: 3);
      final baseline = realEstateSaleListingDays(
        type: asset.type,
        worldSeed: worldSeed,
        assetId: current.id,
        listedDay: current.saleListedDay,
      );

      expect(legacy.saleListingDays, baseline);
      expect(
        current.saleListingDays,
        realEstateSaleListingDays(
          type: asset.type,
          worldSeed: worldSeed,
          assetId: current.id,
          listedDay: current.saleListedDay,
          liquidity: liquidity,
        ),
      );
      expect(current.saleListingDays, greaterThan(legacy.saleListingDays));
    },
  );

  test(
    'stored sale offer issue day survives JSON while legacy derives the wait',
    () {
      final current = OwnedRealEstate(
        id: 'owned-sale-wait-snapshot',
        optionId: realEstateListingOptionId(asset.id, 0),
        name: '매각 대기 스냅샷',
        purchasePrice: 50000000,
        acquiredDay: 1,
        monthlyIncome: 0,
        monthlyCost: 0,
        marketAssetId: asset.id,
        marketListingIndex: 0,
        realEstateWorldSeed: worldSeed,
        realEstateWorldVersion: 4,
        saleListedDay: 3200,
      );
      final derivedReadyDay = current.saleListedDay + current.saleListingDays;
      final storedReadyDay = derivedReadyDay + 17;
      final snapshotted = current.copyWith(saleOfferIssuedDay: storedReadyDay);
      final restored = OwnedRealEstate.fromJson(snapshotted.toJson());
      final legacyJson = Map<String, dynamic>.from(snapshotted.toJson())
        ..remove('saleOfferIssuedDay');
      final legacy = OwnedRealEstate.fromJson(legacyJson);

      expect(snapshotted.saleOfferReadyDay, storedReadyDay);
      expect(restored.saleOfferIssuedDay, storedReadyDay);
      expect(restored.saleOfferReadyDay, storedReadyDay);
      expect(legacy.saleOfferIssuedDay, 0);
      expect(legacy.saleOfferReadyDay, derivedReadyDay);
    },
  );
}
