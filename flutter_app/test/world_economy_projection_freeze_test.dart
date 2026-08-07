import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/business_districts.dart';
import 'package:millennium_capital/game/business_simulation.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_world.dart';
import 'package:millennium_capital/game/world_economy.dart';

/// Freezes the shared-economy projection layer.
///
/// The stock exporter owns event identity and the already seeded `impactPct`.
/// This file locks the part that lives in `world_economy.dart`: event
/// lifetimes, active decay, region sensitivity, per-kind coefficients, and the
/// output clamp ranges. Editing any of those changes demand, rent, risk, and
/// monthly profit for business v3 and property v4 saves that already exist, so
/// the goldens below must fail first. The correct response is to bump
/// [worldEconomyProjectionVersion], keep the old coefficients for the mapped
/// generator versions, and give the new projection to a new generator version
/// only — never to edit these numbers in place.
void main() {
  // A projection value is a ratio, so a tolerance this tight still catches a
  // coefficient edit while tolerating VM/Web double formatting.
  const tolerance = 1e-12;

  group('projection version is pinned by the stored generator version', () {
    test('business v1 predates the shared economy and stays neutral', () {
      expect(worldEconomyProjectionVersionForBusinessGenerator(1), 0);
      expect(worldEconomyProjectionVersionForBusinessGenerator(2), 1);
      expect(worldEconomyProjectionVersionForBusinessGenerator(3), 1);
    });

    test('property v1-v3 keep frozen fingerprints and stay neutral', () {
      expect(worldEconomyProjectionVersionForRealEstateGenerator(1), 0);
      expect(worldEconomyProjectionVersionForRealEstateGenerator(2), 0);
      expect(worldEconomyProjectionVersionForRealEstateGenerator(3), 0);
      expect(worldEconomyProjectionVersionForRealEstateGenerator(4), 1);
    });

    test('shipping generators pin the current projection version', () {
      // Bumping worldEconomyProjectionVersion without mapping a new generator
      // version to it would silently recompute existing saves.
      expect(
        worldEconomyProjectionVersionForBusinessGenerator(
          businessWorldGeneratorVersion,
        ),
        worldEconomyProjectionVersion,
      );
      expect(
        worldEconomyProjectionVersionForRealEstateGenerator(
          realEstateWorldGeneratorVersion,
        ),
        worldEconomyProjectionVersion,
      );
    });

    test('projection version 0 returns a neutral snapshot with no events', () {
      final neutral = worldEconomySnapshot(
        worldSeed: 'qa-world-alpha',
        asOf: DateTime(2008, 10, 27),
        regionKeys: const ['seoul_gangnam_station', 'capital', 'office'],
        projectionVersion: 0,
      );

      expect(neutral.businessImpact.isNeutral, isTrue);
      expect(neutral.realEstateImpact.isNeutral, isTrue);
      expect(neutral.revealedEvents, isEmpty);
      expect(neutral.regionKeys, isEmpty);
      expect(neutral.asOf, DateTime(2008, 10, 27));
    });
  });

  group('projection v1 goldens', () {
    const regionKeys = <String>['seoul_gangnam_station', 'capital', 'office'];

    // seed, date, then business demand/rent/competition/wage/vacancy/risk/
    // vitality followed by property price/rent/vacancy/risk/repair/liquidity.
    final cases = <List<Object>>[
      <Object>[
        'qa-world-alpha',
        DateTime(2001, 4, 16),
        -0.0387915471335728,
        -0.01500094240234903,
        -0.010774644439440931,
        -0.006458860234741605,
        0.008088224304020465,
        0.020456222154185303,
        -0.024224622603561195,
        -0.017867953699028515,
        -0.010261873239924032,
        0.005145388546891947,
        0.01641726401867487,
        0.010305682082619358,
        -0.01947316158950393,
      ],
      <Object>[
        'qa-world-alpha',
        DateTime(2008, 10, 27),
        -0.241216183772553,
        -0.08494909573916258,
        -0.06769645947117472,
        -0.028147308129843153,
        0.056365603728233064,
        0.1423810876561682,
        -0.1518933677715805,
        -0.1650874821428166,
        -0.05430244230309127,
        0.04276984391687422,
        0.14324379001060017,
        0.029215281740360997,
        -0.1609708898953641,
      ],
      <Object>[
        'qa-world-alpha',
        DateTime(2020, 3, 19),
        -0.004571255459362275,
        -0.0017133750284398603,
        -0.0012699134362925968,
        -0.0007680088198505704,
        0.0009426945731703203,
        0.002389458319238029,
        -0.0028324128324216844,
        -0.0020559142383215333,
        -0.001189836342430958,
        0.0005960870317013742,
        0.0019037381478895327,
        0.0012529548086693018,
        -0.0022431561433303914,
      ],
      <Object>[
        'freeze-world-beta',
        DateTime(2001, 4, 16),
        -0.04868055178287453,
        -0.019077321085935933,
        -0.01348563436675937,
        -0.008033309848483279,
        0.01017061992418579,
        0.024832973406951533,
        -0.03009685523095596,
        -0.022593627287741776,
        -0.013034334096013941,
        0.006360996595516492,
        0.019598244270189673,
        0.011817512508728202,
        -0.02392323213161707,
      ],
      <Object>[
        'freeze-world-beta',
        DateTime(2008, 10, 27),
        -0.21401129919628464,
        -0.07008882225203603,
        -0.060075552918633014,
        -0.024707458275660902,
        0.04957844794704041,
        0.12450119316774966,
        -0.1325886939357546,
        -0.14467745443855687,
        -0.04613119651764979,
        0.037683654317581916,
        0.12568841112516013,
        0.02634002029898759,
        -0.13994012446219742,
      ],
      <Object>[
        'freeze-world-beta',
        DateTime(2020, 3, 19),
        -0.0017336899859368708,
        0.0019339974131523617,
        -0.0004834332745047669,
        -0.0005955032238657277,
        -0.00006583225617887698,
        -0.00010435243669785783,
        -0.00006801315480265725,
        0.002063618635495647,
        0.0003656277199352094,
        -0.0002090741769969341,
        -0.0008500868859448799,
        0.002378110945043158,
        0.0016924712161918178,
      ],
    ];

    for (final row in cases) {
      final seed = row[0] as String;
      final date = row[1] as DateTime;
      final label = '$seed on ${date.year}-${date.month}-${date.day}';

      test('$label keeps its business and property projection', () {
        final snapshot = worldEconomySnapshot(
          worldSeed: seed,
          asOf: date,
          regionKeys: regionKeys,
        );
        final business = snapshot.businessImpact;
        final property = snapshot.realEstateImpact;

        expect(business.demand, closeTo(row[2] as double, tolerance));
        expect(business.rent, closeTo(row[3] as double, tolerance));
        expect(business.competition, closeTo(row[4] as double, tolerance));
        expect(business.wage, closeTo(row[5] as double, tolerance));
        expect(business.vacancy, closeTo(row[6] as double, tolerance));
        expect(business.risk, closeTo(row[7] as double, tolerance));
        expect(business.vitality, closeTo(row[8] as double, tolerance));
        expect(property.price, closeTo(row[9] as double, tolerance));
        expect(property.rent, closeTo(row[10] as double, tolerance));
        expect(property.vacancy, closeTo(row[11] as double, tolerance));
        expect(property.risk, closeTo(row[12] as double, tolerance));
        expect(property.repairCost, closeTo(row[13] as double, tolerance));
        expect(property.liquidity, closeTo(row[14] as double, tolerance));
      });
    }
  });

  group('projected district multipliers stay frozen', () {
    // The district layer multiplies the projection into the numbers that
    // actually drive daily sales, rent, and monthly profit.
    final cases = <List<Object>>[
      <Object>[
        'qa-world-alpha',
        DateTime(2001, 4, 16),
        1.073426222546187,
        1.1132198946222351,
        0.9414458286272466,
        77.59863095601405,
      ],
      <Object>[
        'qa-world-alpha',
        DateTime(2008, 10, 27),
        0.9698194066597597,
        1.1105575683364182,
        1.128649458813334,
        73.11641588018128,
      ],
      <Object>[
        'qa-world-alpha',
        DateTime(2020, 3, 19),
        0.7832975496214324,
        0.7575293943149736,
        1.4429126510316097,
        52.25297036806575,
      ],
      <Object>[
        'freeze-world-beta',
        DateTime(2001, 4, 16),
        1.0620390682459888,
        1.1115421602743374,
        0.9525882745789092,
        75.15451183058765,
      ],
      <Object>[
        'freeze-world-beta',
        DateTime(2008, 10, 27),
        1.0150026936190752,
        1.1386584934583754,
        1.1263638360112767,
        76.60062172043818,
      ],
      <Object>[
        'freeze-world-beta',
        DateTime(2020, 3, 19),
        0.7993497685504034,
        0.7690183557876147,
        1.4620807822087358,
        51.498834105921986,
      ],
    ];

    for (final row in cases) {
      final seed = row[0] as String;
      final date = row[1] as DateTime;
      final label = '$seed on ${date.year}-${date.month}-${date.day}';

      test('$label keeps demand, rent, risk, and vitality', () {
        final snapshot = businessDistrictSnapshot(
          districtId: 'seoul_gangnam_station',
          asOf: date,
          worldSeed: seed,
        );

        expect(snapshot.demandMultiplier, closeTo(row[2] as double, tolerance));
        expect(snapshot.rentMultiplier, closeTo(row[3] as double, tolerance));
        expect(snapshot.riskMultiplier, closeTo(row[4] as double, tolerance));
        expect(snapshot.vitalityScore, closeTo(row[5] as double, tolerance));
      });
    }
  });

  group('snapshot cache never changes what a caller receives', () {
    const seed = 'cache-safety-world';
    final date = DateTime(2008, 10, 27);
    const regionKeys = <String>['seoul_gangnam_station', 'capital', 'office'];

    setUp(resetWorldEconomySnapshotCache);

    WorldEconomySnapshot take({
      String worldSeed = seed,
      DateTime? asOf,
      Iterable<String> keys = regionKeys,
      int projectionVersion = worldEconomyProjectionVersion,
    }) => worldEconomySnapshot(
      worldSeed: worldSeed,
      asOf: asOf ?? date,
      regionKeys: keys,
      projectionVersion: projectionVersion,
    );

    void expectSameNumbers(
      WorldEconomySnapshot left,
      WorldEconomySnapshot right,
    ) {
      expect(left.businessImpact.demand, right.businessImpact.demand);
      expect(left.businessImpact.rent, right.businessImpact.rent);
      expect(left.businessImpact.risk, right.businessImpact.risk);
      expect(left.realEstateImpact.price, right.realEstateImpact.price);
      expect(left.realEstateImpact.rent, right.realEstateImpact.rent);
      expect(left.realEstateImpact.liquidity, right.realEstateImpact.liquidity);
      expect(
        left.revealedEvents.map((event) => event.id).toList(),
        right.revealedEvents.map((event) => event.id).toList(),
      );
    }

    test('a warm read matches the cold computation', () {
      final cold = take();
      final warm = take();
      expectSameNumbers(cold, warm);

      resetWorldEconomySnapshotCache();
      expectSameNumbers(cold, take());
    });

    test('region key order shares one entry without changing the result', () {
      final sorted = take();
      final shuffled = take(
        keys: const ['office', 'capital', 'seoul_gangnam_station'],
      );
      expectSameNumbers(sorted, shuffled);
      expect(shuffled.regionKeys, sorted.regionKeys);
    });

    test('a legacy caller never receives the projected entry', () {
      // Order matters: the v1 entry is stored first, then v0 asks for the same
      // seed, day, and regions. A key without the version would hand the
      // legacy save a projected snapshot and silently rewrite its numbers.
      final projected = take();
      expect(projected.businessImpact.isNeutral, isFalse);

      final legacy = take(projectionVersion: 0);
      expect(legacy.businessImpact.isNeutral, isTrue);
      expect(legacy.realEstateImpact.isNeutral, isTrue);
      expect(legacy.revealedEvents, isEmpty);

      // And the projected entry is still intact afterwards.
      expectSameNumbers(projected, take());
    });

    test('seed, day, and region set stay separate', () {
      final base = take();
      expect(
        take(worldSeed: 'other-world').businessImpact.demand,
        isNot(base.businessImpact.demand),
      );
      expect(
        take(asOf: DateTime(2020, 3, 19)).businessImpact.demand,
        isNot(base.businessImpact.demand),
      );

      final narrower = take(keys: const ['capital']);
      expect(narrower.regionKeys, isNot(base.regionKeys));
    });

    test('results stay correct after the bound evicts an entry', () {
      final first = take();
      // Push well past the cache bound with distinct days.
      for (var offset = 1; offset <= 600; offset += 1) {
        take(asOf: date.add(Duration(days: offset)));
      }
      expectSameNumbers(first, take());
    });
  });

  test('property liquidity is projected for v4 and neutral for v1-v3', () {
    final asset = realEstateMarketAssetById('uijeongbu_station_officetel_20')!;
    const seed = 'qa-world-alpha';
    final date = DateTime(2008, 10, 27);

    final projected = realEstateWorldLiquidityAt(
      asset,
      seed,
      date,
      generatorVersion: 4,
    );
    expect(projected, isNot(0));

    for (final legacyVersion in const <int>[1, 2, 3]) {
      expect(
        realEstateWorldLiquidityAt(
          asset,
          seed,
          date,
          generatorVersion: legacyVersion,
        ),
        0,
        reason: '부동산 v$legacyVersion 저장은 공통 투영을 받지 않아야 합니다.',
      );
    }
  });
}
