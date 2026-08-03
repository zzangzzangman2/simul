import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/business_districts.dart';
import 'package:millennium_capital/game/business_simulation.dart';
import 'package:millennium_capital/game/business_state.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_world.dart';
import 'package:millennium_capital/game/world_economy.dart';

Map<String, Object?> _changeRecord(BusinessDistrictChange change) => {
  'vitalityPoints': change.vitalityPoints,
  'demandPercent': change.demandPercent,
  'rentPercent': change.rentPercent,
  'competitionPercent': change.competitionPercent,
  'wagePercent': change.wagePercent,
  'vacancyPercent': change.vacancyPercent,
  'riskPercent': change.riskPercent,
};

Map<String, Object?> _snapshotRecord(BusinessDistrictSnapshot snapshot) => {
  'generatorVersion': snapshot.generatorVersion,
  'districtId': snapshot.districtId,
  'city': snapshot.city,
  'name': snapshot.name,
  'asOf': snapshot.asOf.toIso8601String(),
  'demandMultiplier': snapshot.demandMultiplier,
  'rentMultiplier': snapshot.rentMultiplier,
  'competitionMultiplier': snapshot.competitionMultiplier,
  'wageMultiplier': snapshot.wageMultiplier,
  'vacancyMultiplier': snapshot.vacancyMultiplier,
  'riskMultiplier': snapshot.riskMultiplier,
  'vitalityScore': snapshot.vitalityScore,
  'monthOverMonth': _changeRecord(snapshot.monthOverMonth),
  'yearOverYear': _changeRecord(snapshot.yearOverYear),
  'phase': snapshot.phase.name,
  'revealedEvents': [
    for (final event in snapshot.revealedEvents)
      {
        'id': event.id,
        'kind': event.kind.name,
        'occurredOn': event.occurredOn.toIso8601String(),
        'revealedOn': event.revealedOn.toIso8601String(),
        'headline': event.headline,
        'summary': event.summary,
        'isActive': event.isActive,
      },
  ],
  'currentSignals': snapshot.currentSignals,
};

void _expectSnapshotWithinBounds(BusinessDistrictSnapshot snapshot) {
  expect(
    snapshot.demandMultiplier,
    inInclusiveRange(
      businessDistrictDemandMultiplierMin,
      businessDistrictDemandMultiplierMax,
    ),
  );
  expect(
    snapshot.rentMultiplier,
    inInclusiveRange(
      businessDistrictRentMultiplierMin,
      businessDistrictRentMultiplierMax,
    ),
  );
  expect(
    snapshot.competitionMultiplier,
    inInclusiveRange(
      businessDistrictCompetitionMultiplierMin,
      businessDistrictCompetitionMultiplierMax,
    ),
  );
  expect(
    snapshot.wageMultiplier,
    inInclusiveRange(
      businessDistrictWageMultiplierMin,
      businessDistrictWageMultiplierMax,
    ),
  );
  expect(
    snapshot.vacancyMultiplier,
    inInclusiveRange(
      businessDistrictVacancyMultiplierMin,
      businessDistrictVacancyMultiplierMax,
    ),
  );
  expect(
    snapshot.riskMultiplier,
    inInclusiveRange(
      businessDistrictRiskMultiplierMin,
      businessDistrictRiskMultiplierMax,
    ),
  );
  expect(snapshot.vitalityScore, inInclusiveRange(0, 100));
}

void main() {
  group('상권 카탈로그', () {
    test('24곳 이상이며 ID가 고유하고 주요 도시를 빠짐없이 포함한다', () {
      expect(businessDistrictCatalog.length, greaterThanOrEqualTo(24));
      expect(
        businessDistrictCatalog.map((profile) => profile.id).toSet(),
        hasLength(businessDistrictCatalog.length),
      );
      expect(
        businessDistrictCatalog.every(
          (profile) =>
              profile.id.isNotEmpty &&
              profile.city.isNotEmpty &&
              profile.name.isNotEmpty &&
              profile.summary.isNotEmpty,
        ),
        isTrue,
      );

      const requiredDistrictIds = <String>{
        'seoul_gangnam_station',
        'gyeonggi_pangyo',
        'incheon_songdo',
        'busan_seomyeon',
        'daegu_dongseongno',
        'daejeon_dunsan',
        'gwangju_chungjang',
        'ulsan_samsan',
        'sejong_nasung',
        'jeju_nohyeong',
      };
      final ids = businessDistrictCatalog.map((profile) => profile.id).toSet();
      expect(ids, containsAll(requiredDistrictIds));
    });

    test('모든 업종 적합도와 기초 수치가 안전한 범위다', () {
      for (final profile in businessDistrictCatalog) {
        expect(profile.baseMonthlyRentPerPyeong, greaterThan(0));
        expect(profile.baseDailyFootTraffic, greaterThan(0));
        expect(profile.baseCompetitionIndex, greaterThan(0));
        expect(profile.baseMonthlyWage, greaterThan(0));
        expect(profile.baseVacancyRate, inInclusiveRange(0, 1));
        expect(profile.baseRiskIndex, inInclusiveRange(0, 100));
        for (final industry in BusinessIndustry.values) {
          expect(
            businessDistrictIndustryFit(profile, industry),
            inInclusiveRange(
              businessDistrictIndustryFitMin,
              businessDistrictIndustryFitMax,
            ),
            reason: '${profile.id}/${industry.name}',
          );
        }
      }
    });
  });

  group('2000~2026 결정론과 구조 변화', () {
    test('2000·2008·2020·2026 스냅샷은 같은 시드와 날짜에 완전히 동일하다', () {
      final dates = <DateTime>[
        DateTime(2000, 1, 1),
        DateTime(2008, 10, 1),
        DateTime(2020, 3, 1),
        DateTime(2026, 12, 31),
      ];
      final vitalityByDate = <double>[];

      for (final date in dates) {
        final first = businessDistrictSnapshot(
          districtId: 'seoul_gangnam_station',
          asOf: date,
          worldSeed: 'district-determinism',
        );
        final repeated = businessDistrictSnapshot(
          districtId: 'seoul_gangnam_station',
          asOf: date,
          worldSeed: 'district-determinism',
        );

        expect(_snapshotRecord(repeated), equals(_snapshotRecord(first)));
        expect(first.asOf.isUtc, isTrue);
        expect(first.asOf.year, date.year);
        expect(first.asOf.month, date.month);
        expect(first.asOf.day, date.day);
        _expectSnapshotWithinBounds(first);
        vitalityByDate.add(first.vitalityScore);
      }

      expect(vitalityByDate.toSet().length, greaterThan(1));
    });

    test('일일 영업용 경량 지표는 전체 상권 스냅샷의 수치와 같다', () {
      final profile = businessDistrictProfileById('seoul_seongsu')!;
      for (final date in <DateTime>[
        DateTime(2000, 1, 3),
        DateTime(2008, 9, 17),
        DateTime(2020, 3, 16),
        DateTime(2026, 12, 31),
      ]) {
        final full = businessDistrictSnapshotFor(
          profile,
          asOf: date,
          worldSeed: 'district-operating-factors',
        );
        final operating = businessDistrictOperatingFactorsFor(
          profile,
          asOf: date,
          worldSeed: 'district-operating-factors',
        );

        expect(operating.demandMultiplier, full.demandMultiplier);
        expect(operating.rentMultiplier, full.rentMultiplier);
        expect(operating.competitionMultiplier, full.competitionMultiplier);
        expect(operating.wageMultiplier, full.wageMultiplier);
        expect(operating.riskMultiplier, full.riskMultiplier);
      }
    });

    test('시드 미세변동이 신도시 성장과 쇠퇴 상권의 구조 방향을 뒤집지 않는다', () {
      for (final seed in <String>[
        'structural-seed-a',
        'structural-seed-b',
        'structural-seed-c',
        'structural-seed-d',
      ]) {
        final pangyoBefore = businessDistrictSnapshot(
          districtId: 'gyeonggi_pangyo',
          asOf: DateTime(2000, 1, 1),
          worldSeed: seed,
        );
        final pangyoAfter = businessDistrictSnapshot(
          districtId: 'gyeonggi_pangyo',
          asOf: DateTime(2015, 12, 31),
          worldSeed: seed,
        );
        expect(
          pangyoAfter.vitalityScore,
          greaterThan(pangyoBefore.vitalityScore + 30),
          reason: '$seed 판교 성장 방향',
        );

        final ilsanPeak = businessDistrictSnapshot(
          districtId: 'gyeonggi_ilsan_lafesta',
          asOf: DateTime(2000, 1, 1),
          worldSeed: seed,
        );
        final ilsanDecline = businessDistrictSnapshot(
          districtId: 'gyeonggi_ilsan_lafesta',
          asOf: DateTime(2019, 12, 31),
          worldSeed: seed,
        );
        expect(
          ilsanDecline.vitalityScore,
          lessThan(ilsanPeak.vitalityScore - 25),
          reason: '$seed 일산 쇠퇴 방향',
        );
      }
    });
  });

  group('as-of 공개와 순위', () {
    test('미래 사건과 생애주기 원인은 공개일 전에는 보이지 않는다', () {
      final gangnam = businessDistrictProfileById('seoul_gangnam_station')!;
      final start = businessDistrictSnapshotFor(
        gangnam,
        asOf: DateTime(2000, 1, 1),
        worldSeed: 'as-of-visibility',
        generatorVersion: 1,
      );
      expect(start.revealedEvents, isEmpty);
      expect(
        gangnam
            .revealedLifecycleAnchors(start.asOf)
            .every((anchor) => !anchor.date.isAfter(start.asOf)),
        isTrue,
      );
      expect(
        start.currentSignals.any(
          (signal) => signal.contains('금융위기') || signal.contains('대면 소비 급감'),
        ),
        isFalse,
      );

      final beforeFinancialShock = businessDistrictSnapshotFor(
        gangnam,
        asOf: DateTime(2008, 9, 14),
        worldSeed: 'as-of-visibility',
        generatorVersion: 1,
      );
      final onFinancialShock = businessDistrictSnapshotFor(
        gangnam,
        asOf: DateTime(2008, 9, 15),
        worldSeed: 'as-of-visibility',
        generatorVersion: 1,
      );
      expect(
        beforeFinancialShock.revealedEvents.any(
          (event) => event.id == 'national_2008_financial_slowdown',
        ),
        isFalse,
      );
      expect(
        onFinancialShock.revealedEvents.any(
          (event) => event.id == 'national_2008_financial_slowdown',
        ),
        isTrue,
      );

      final occurrenceDay = businessDistrictSnapshotFor(
        gangnam,
        asOf: DateTime(2020, 2, 23),
        worldSeed: 'as-of-visibility',
        generatorVersion: 1,
      );
      final revealDay = businessDistrictSnapshotFor(
        gangnam,
        asOf: DateTime(2020, 2, 24),
        worldSeed: 'as-of-visibility',
        generatorVersion: 1,
      );
      expect(
        occurrenceDay.revealedEvents.any(
          (event) => event.id == 'national_2020_contact_shock',
        ),
        isFalse,
      );
      expect(
        revealDay.revealedEvents.any(
          (event) => event.id == 'national_2020_contact_shock',
        ),
        isTrue,
      );

      final history = businessDistrictHistory(
        districtId: gangnam.id,
        from: DateTime(2000, 1, 1),
        to: DateTime(2026, 12, 31),
        worldSeed: 'as-of-visibility',
        stepMonths: 24,
        generatorVersion: 1,
      );
      for (final snapshot in history) {
        expect(
          snapshot.revealedEvents.every(
            (event) => !event.revealedOn.isAfter(snapshot.asOf),
          ),
          isTrue,
          reason: snapshot.asOf.toIso8601String(),
        );
      }
    });

    test('순위는 기회점수 내림차순이며 도시 필터와 연속 순번을 지킨다', () {
      final ranking = rankBusinessDistricts(
        asOf: DateTime(2026, 7, 28),
        worldSeed: 'district-ranking',
        industry: BusinessIndustry.pcBang,
      );
      expect(ranking, hasLength(businessDistrictCatalog.length));
      for (var index = 0; index < ranking.length; index += 1) {
        expect(ranking[index].rank, index + 1);
        expect(ranking[index].snapshot.districtId, ranking[index].profile.id);
        expect(ranking[index].opportunityScore, inInclusiveRange(0, 100));
        if (index > 0) {
          expect(
            ranking[index - 1].opportunityScore,
            greaterThanOrEqualTo(ranking[index].opportunityScore),
          );
        }
      }

      final seoulOnly = rankBusinessDistricts(
        asOf: DateTime(2026, 7, 28),
        worldSeed: 'district-ranking',
        industry: BusinessIndustry.karaoke,
        city: '서울',
      );
      expect(seoulOnly, isNotEmpty);
      expect(seoulOnly.every((entry) => entry.profile.city == '서울'), isTrue);
      expect(
        [
          for (var index = 0; index < seoulOnly.length; index += 1)
            seoulOnly[index].rank == index + 1,
        ].every((value) => value),
        isTrue,
      );
    });
  });

  test('같은 상권도 업종에 따라 적합도가 분명히 달라진다', () {
    final sinchon = businessDistrictProfileById('seoul_sinchon')!;
    final studyCafeFit = businessDistrictIndustryFit(
      sinchon,
      BusinessIndustry.studyCafe,
    );
    final laundryFit = businessDistrictIndustryFit(
      sinchon,
      BusinessIndustry.coinLaundry,
    );

    expect(studyCafeFit, greaterThan(laundryFit));
    expect(
      rankBusinessDistricts(
        asOf: DateTime(2018, 6, 1),
        worldSeed: 'industry-fit',
        industry: BusinessIndustry.studyCafe,
      ).first.industryFit,
      inInclusiveRange(
        businessDistrictIndustryFitMin,
        businessDistrictIndustryFitMax,
      ),
    );
  });

  test('현재 부동산의 모든 지역·권역은 유효한 상권 ID로 안전하게 매핑된다', () {
    for (final asset in realEstateMarketCatalog) {
      final districtId = businessDistrictIdForRealEstateRegion(
        asset.region,
        province: asset.province,
      );
      expect(
        businessDistrictProfileById(districtId ?? ''),
        isNotNull,
        reason: '${asset.province} ${asset.region} (${asset.id})',
      );
    }
    for (final region in realEstateDistrictCatalog) {
      final districtId = businessDistrictIdForRealEstateRegion(
        region.name,
        province: region.province,
      );
      expect(
        businessDistrictProfileById(districtId ?? ''),
        isNotNull,
        reason: region.label,
      );
    }

    expect(
      businessDistrictIdForRealEstateRegion('성남시', province: '경기도'),
      'gyeonggi_pangyo',
    );
    expect(
      businessDistrictIdForRealEstateRegion('성동구', province: '서울특별시'),
      'seoul_seongsu',
    );
    expect(
      businessDistrictIdForRealEstateRegion('송파구', province: '서울특별시'),
      'seoul_jamsil',
    );
  });

  test('v2 상권은 공통 경제 사건을 한 번만 공개하고 legacy 전국 사건을 제거한다', () {
    const seed = 'shared-economy-business-bridge';
    final asOf = DateTime(2026, 7, 28);
    final profile = businessDistrictProfileById('seoul_gangnam_station')!;
    final legacy = businessDistrictSnapshotFor(
      profile,
      asOf: asOf,
      worldSeed: seed,
      generatorVersion: 1,
    );
    final shared = businessDistrictSnapshotFor(
      profile,
      asOf: asOf,
      worldSeed: seed,
      generatorVersion: 2,
    );
    final economy = worldEconomySnapshot(
      worldSeed: seed,
      asOf: asOf,
      regionKeys: [profile.id, profile.city, ...profile.regionTags],
    );
    final sharedIds = shared.revealedEvents.map((event) => event.id).toList();

    expect(legacy.generatorVersion, 1);
    expect(shared.generatorVersion, 2);
    expect(
      legacy.revealedEvents.any((event) => event.id.startsWith('national_')),
      isTrue,
    );
    expect(sharedIds.any((id) => id.startsWith('national_')), isFalse);
    expect(
      sharedIds,
      containsAll(economy.revealedEvents.map((event) => event.id)),
    );
    expect(sharedIds.toSet(), hasLength(sharedIds.length));
    expect(
      shared.revealedEvents.every(
        (event) => !event.revealedOn.isAfter(shared.asOf),
      ),
      isTrue,
    );
  });

  test('새 게임과 사업 필드가 없는 저장은 v3, 기존 사업 저장의 누락 버전은 v1이다', () {
    expect(const BusinessPortfolioState.initial().generatorVersion, 3);
    expect(BusinessPortfolioState.fromJson(const {}).generatorVersion, 3);
    expect(
      GameState.fromJson(const {'version': 18}).businesses.generatorVersion,
      3,
    );

    final missingPortfolioVersion = Map<String, dynamic>.from(
      const BusinessPortfolioState.initial().toJson(),
    )..remove('generatorVersion');
    expect(
      BusinessPortfolioState.fromJson(missingPortfolioVersion).generatorVersion,
      1,
    );
  });

  test('사업 v1·v2 매물은 상권 v1, 새 v3 매물은 상권 v2 가격을 저장한다', () {
    const seed = 'listing-district-version-route';
    final asOf = DateTime(2026, 7, 28);
    final monthStart = DateTime(asOf.year, asOf.month);

    for (final businessVersion in <int>[1, 2, 3]) {
      final listing = generateBusinessListings(
        worldSeed: seed,
        asOfDate: asOf,
        count: 4,
        generatorVersion: businessVersion,
      ).first;
      final expectedDistrictVersion = businessDistrictVersionForBusinessWorld(
        businessVersion,
      );
      final district = businessDistrictSnapshot(
        districtId: listing.districtId,
        asOf: monthStart,
        worldSeed: seed,
        generatorVersion: expectedDistrictVersion,
      );
      final expectedRentIndexBps =
          (district.rentMultiplier * businessEraCostIndexAt(monthStart) * 10000)
              .round();

      expect(listing.generatorVersion, businessVersion);
      expect(district.generatorVersion, expectedDistrictVersion);
      expect(listing.districtRentIndexBps, expectedRentIndexBps);
    }
  });

  test('매물과 보유 사업의 district 정보는 JSON 왕복하고 legacy 기본값도 안전하다', () {
    final listing = generateBusinessListings(
      worldSeed: 'district-json-roundtrip',
      asOfDate: DateTime(2026, 7, 28),
      count: 4,
    ).first;
    expect(listing.districtId, isNotEmpty);
    expect(listing.districtRentIndexBps, greaterThan(0));
    expect(listing.generatorVersion, 3);

    final restoredListing = BusinessListing.fromJson(listing.toJson());
    expect(restoredListing.toJson(), equals(listing.toJson()));
    final missingListingVersion = Map<String, dynamic>.from(listing.toJson())
      ..remove('generatorVersion');
    expect(BusinessListing.fromJson(missingListingVersion).generatorVersion, 1);

    final owned = createOwnedBusinessFromListing(
      listing: listing,
      businessId: 'district-roundtrip-shop',
      name: '지역 저장 테스트점',
      acquiredDay: 1,
      openedDate: DateTime(2026, 7, 28),
    );
    expect(owned.districtId, listing.districtId);
    expect(owned.districtRentIndexAtOpenBps, listing.districtRentIndexBps);

    final restoredOwned = OwnedBusiness.fromJson(owned.toJson());
    expect(restoredOwned.toJson(), equals(owned.toJson()));

    final legacyJson = <String, dynamic>{...owned.toJson()}
      ..remove('districtId')
      ..remove('districtRentIndexAtOpenBps')
      ..['generatorVersion'] = 1;
    final legacy = OwnedBusiness.fromJson(legacyJson);
    expect(legacy.locationId, owned.locationId);
    expect(legacy.districtId, isEmpty);
    expect(legacy.districtRentIndexAtOpenBps, 10000);
    expect(legacy.generatorVersion, 1);
  });
}
