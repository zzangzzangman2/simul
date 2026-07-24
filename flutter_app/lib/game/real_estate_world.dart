import 'dart:math' as math;

import 'real_estate_market.dart';

class RealEstateDistrict {
  const RealEstateDistrict({
    required this.id,
    required this.name,
    required this.province,
    required this.mapX,
    required this.mapY,
  });

  final String id;
  final String name;
  final String province;
  final double mapX;
  final double mapY;

  String get label => province == '서울특별시' ? '서울 $name' : '경기 $name';

  double distanceTo(RealEstateDistrict other) {
    final dx = mapX - other.mapX;
    final dy = mapY - other.mapY;
    return math.sqrt(dx * dx + dy * dy);
  }
}

const realEstateDistrictCatalog = <RealEstateDistrict>[
  RealEstateDistrict(
    id: 'gyeonggi-uijeongbu',
    name: '의정부시',
    province: '경기도',
    mapX: 0.55,
    mapY: 0.08,
  ),
  RealEstateDistrict(
    id: 'gyeonggi-goyang',
    name: '고양시',
    province: '경기도',
    mapX: 0.27,
    mapY: 0.24,
  ),
  RealEstateDistrict(
    id: 'seoul-nowon',
    name: '노원구',
    province: '서울특별시',
    mapX: 0.61,
    mapY: 0.26,
  ),
  RealEstateDistrict(
    id: 'seoul-jongno',
    name: '종로구',
    province: '서울특별시',
    mapX: 0.49,
    mapY: 0.36,
  ),
  RealEstateDistrict(
    id: 'seoul-seongdong',
    name: '성동구',
    province: '서울특별시',
    mapX: 0.60,
    mapY: 0.45,
  ),
  RealEstateDistrict(
    id: 'seoul-yongsan',
    name: '용산구',
    province: '서울특별시',
    mapX: 0.47,
    mapY: 0.49,
  ),
  RealEstateDistrict(
    id: 'gyeonggi-bucheon',
    name: '부천시',
    province: '경기도',
    mapX: 0.16,
    mapY: 0.55,
  ),
  RealEstateDistrict(
    id: 'seoul-guro',
    name: '구로구',
    province: '서울특별시',
    mapX: 0.34,
    mapY: 0.55,
  ),
  RealEstateDistrict(
    id: 'seoul-seocho',
    name: '서초구',
    province: '서울특별시',
    mapX: 0.54,
    mapY: 0.59,
  ),
  RealEstateDistrict(
    id: 'seoul-gangnam',
    name: '강남구',
    province: '서울특별시',
    mapX: 0.63,
    mapY: 0.58,
  ),
  RealEstateDistrict(
    id: 'seoul-songpa',
    name: '송파구',
    province: '서울특별시',
    mapX: 0.73,
    mapY: 0.57,
  ),
  RealEstateDistrict(
    id: 'gyeonggi-gwacheon',
    name: '과천시',
    province: '경기도',
    mapX: 0.50,
    mapY: 0.70,
  ),
  RealEstateDistrict(
    id: 'gyeonggi-seongnam',
    name: '성남시',
    province: '경기도',
    mapX: 0.66,
    mapY: 0.76,
  ),
  RealEstateDistrict(
    id: 'gyeonggi-suwon',
    name: '수원시',
    province: '경기도',
    mapX: 0.55,
    mapY: 0.91,
  ),
];

RealEstateDistrict realEstateDistrictFor(RealEstateMarketAsset asset) =>
    realEstateDistrictCatalog.firstWhere(
      (district) =>
          district.name == asset.region && district.province == asset.province,
    );

RealEstateDistrict? realEstateDistrictById(String id) {
  for (final district in realEstateDistrictCatalog) {
    if (district.id == id) return district;
  }
  return null;
}

enum RealEstateListingCondition { needsRepair, average, renovated }

extension RealEstateListingConditionLabel on RealEstateListingCondition {
  String get label => switch (this) {
    RealEstateListingCondition.needsRepair => '수리 필요',
    RealEstateListingCondition.average => '보통',
    RealEstateListingCondition.renovated => '관리 우수',
  };
}

enum RealEstateWorldEventKind {
  transitPlan,
  redevelopment,
  supplyWave,
  employerMove,
  floodOrDefect,
  schoolZone,
  vacancyShock,
}

extension RealEstateWorldEventKindLabel on RealEstateWorldEventKind {
  String get label => switch (this) {
    RealEstateWorldEventKind.transitPlan => '교통 계획',
    RealEstateWorldEventKind.redevelopment => '정비사업',
    RealEstateWorldEventKind.supplyWave => '입주 물량',
    RealEstateWorldEventKind.employerMove => '대형 고용처',
    RealEstateWorldEventKind.floodOrDefect => '하자·재해',
    RealEstateWorldEventKind.schoolZone => '학군 변화',
    RealEstateWorldEventKind.vacancyShock => '공실 충격',
  };

  bool get isPotentialUpside => switch (this) {
    RealEstateWorldEventKind.transitPlan ||
    RealEstateWorldEventKind.redevelopment ||
    RealEstateWorldEventKind.schoolZone => true,
    _ => false,
  };
}

enum RealEstateWorldEventOutcome { completed, delayed, canceled }

extension RealEstateWorldEventOutcomeLabel on RealEstateWorldEventOutcome {
  String labelFor(RealEstateWorldEventKind kind) {
    if (kind.isPotentialUpside) {
      return switch (this) {
        RealEstateWorldEventOutcome.completed => '확정·완료',
        RealEstateWorldEventOutcome.delayed => '장기 지연',
        RealEstateWorldEventOutcome.canceled => '계획 취소',
      };
    }
    return switch (this) {
      RealEstateWorldEventOutcome.completed => '악재 현실화',
      RealEstateWorldEventOutcome.delayed => '축소·지연',
      RealEstateWorldEventOutcome.canceled => '악재 해소',
    };
  }
}

class RealEstateWorldEvent {
  const RealEstateWorldEvent({
    required this.id,
    required this.assetId,
    required this.originDistrictId,
    required this.kind,
    required this.announcedAt,
    required this.resolvedAt,
    required this.outcome,
    required this.announcementImpact,
    required this.resolvedImpact,
    required this.title,
    required this.unresolvedDetail,
    required this.impactDurationDays,
  });

  final String id;
  final String assetId;
  final String originDistrictId;
  final RealEstateWorldEventKind kind;
  final DateTime announcedAt;
  final DateTime resolvedAt;
  final RealEstateWorldEventOutcome outcome;
  final double announcementImpact;
  final double resolvedImpact;
  final String title;
  final String unresolvedDetail;
  final int impactDurationDays;

  bool isVisibleAt(DateTime date) => !date.isBefore(announcedAt);

  bool isResolvedAt(DateTime date) => !date.isBefore(resolvedAt);

  double impactAt(DateTime date) {
    if (!isVisibleAt(date)) return 0;
    if (!isResolvedAt(date)) return announcementImpact;
    final elapsed = date.difference(resolvedAt).inDays;
    if (elapsed >= impactDurationDays) return 0;
    final decay = 1 - elapsed / impactDurationDays;
    return resolvedImpact * decay.clamp(0.0, 1.0);
  }

  String statusAt(DateTime date) {
    if (!isVisibleAt(date)) return '미공개';
    if (!isResolvedAt(date)) {
      return kind.isPotentialUpside ? '발표·검토 중' : '위험 신호';
    }
    return outcome.labelFor(kind);
  }

  String detailAt(DateTime date) {
    if (!isResolvedAt(date)) {
      return unresolvedDetail;
    }
    return switch (outcome) {
      RealEstateWorldEventOutcome.completed when kind.isPotentialUpside =>
        '계획이 확정되어 기대감 일부가 실제 가치로 전환됐습니다.',
      RealEstateWorldEventOutcome.completed =>
        '우려했던 악재가 현실화되어 가격과 임대수요가 함께 압박받습니다.',
      RealEstateWorldEventOutcome.delayed when kind.isPotentialUpside =>
        '일정이 장기간 밀리며 먼저 올랐던 기대가격이 일부 되돌아갔습니다.',
      RealEstateWorldEventOutcome.delayed => '악재 규모가 줄었지만 불확실성이 남아 있습니다.',
      RealEstateWorldEventOutcome.canceled when kind.isPotentialUpside =>
        '계획이 취소되어 선반영된 기대감보다 큰 가격 조정이 발생했습니다.',
      RealEstateWorldEventOutcome.canceled => '우려했던 악재가 해소되어 할인 요인이 줄었습니다.',
    };
  }
}

class RealEstateListingRef {
  const RealEstateListingRef({
    required this.assetId,
    required this.listingIndex,
  });

  final String assetId;
  final int listingIndex;

  String get optionId => realEstateListingOptionId(assetId, listingIndex);
}

String realEstateListingOptionId(String assetId, int listingIndex) =>
    'real-estate-listing::$assetId::$listingIndex';

RealEstateListingRef? parseRealEstateListingOptionId(String optionId) {
  const prefix = 'real-estate-listing::';
  if (!optionId.startsWith(prefix)) return null;
  final separator = optionId.lastIndexOf('::');
  if (separator <= prefix.length) return null;
  final assetId = optionId.substring(prefix.length, separator);
  final listingIndex = int.tryParse(optionId.substring(separator + 2));
  if (assetId.isEmpty || listingIndex == null || listingIndex < 0) return null;
  return RealEstateListingRef(assetId: assetId, listingIndex: listingIndex);
}

class GeneratedRealEstateListing {
  const GeneratedRealEstateListing({
    required this.worldSeed,
    required this.asset,
    required this.index,
    required this.areaSquareMeters,
    required this.floor,
    required this.stationWalkMinutes,
    required this.condition,
    required this.priceFactor,
    required this.rentFactor,
    required this.operatingCostFactor,
    required this.downsideExposure,
    required this.riskSummary,
  });

  final String worldSeed;
  final RealEstateMarketAsset asset;
  final int index;
  final double areaSquareMeters;
  final int floor;
  final int stationWalkMinutes;
  final RealEstateListingCondition condition;
  final double priceFactor;
  final double rentFactor;
  final double operatingCostFactor;
  final double downsideExposure;
  final String riskSummary;

  String get id => '${asset.id}-$index';

  String get optionId => realEstateListingOptionId(asset.id, index);

  String get displayName {
    final floorLabel = switch (asset.type) {
      RealEstateAssetType.officeBuilding ||
      RealEstateAssetType.landmarkFund => '지분 ${index + 1}호',
      _ => '$floor층',
    };
    return '${asset.name} · $floorLabel';
  }

  List<RealEstateWorldEvent> get events {
    final combined = <RealEstateWorldEvent>[
      ...realEstateNearbyWorldEventsFor(asset, worldSeed),
      ...realEstateListingEventsFor(asset, worldSeed, index),
    ]..sort((a, b) => a.announcedAt.compareTo(b.announcedAt));
    return combined;
  }

  List<RealEstateWorldEvent> visibleEventsAt(DateTime date) {
    final visible = events.where((event) => event.isVisibleAt(date)).toList()
      ..sort((a, b) => b.announcedAt.compareTo(a.announcedAt));
    return visible;
  }

  RealEstateWorldEvent? latestVisibleEventAt(DateTime date) {
    final visible = visibleEventsAt(date);
    return visible.isEmpty ? null : visible.first;
  }

  double localDeviationAt(DateTime date) {
    var deviation = 0.0;
    final firstYear = math.max(2000, asset.availableFrom.year);
    for (var year = firstYear; year <= date.year; year += 1) {
      final fraction = year == date.year ? date.month / 12 : 1.0;
      final unit = _unit('$worldSeed:${asset.id}:listing:$index:year:$year');
      var shock = (unit - 0.5) * 0.18;
      final tail = _unit('$worldSeed:${asset.id}:listing:$index:tail:$year');
      if (tail < 0.10) {
        shock -= 0.10 + _unit('$worldSeed:${asset.id}:down:$year') * 0.16;
      } else if (tail > 0.95) {
        shock += 0.07 + _unit('$worldSeed:${asset.id}:up:$year') * 0.10;
      }
      deviation = deviation * 0.70 + shock * fraction;
    }
    final monthNoise =
        (_unit(
              '$worldSeed:${asset.id}:listing:$index:${date.year}:${date.month}',
            ) -
            0.5) *
        0.05;
    return (deviation + monthNoise).clamp(-0.36, 0.30);
  }

  double eventImpactAt(DateTime date) {
    var total = 0.0;
    for (final event in events) {
      final rawImpact = event.impactAt(date);
      if (rawImpact == 0) continue;
      final spatialFactor = realEstateSpatialSpilloverFactor(asset, event);
      if (spatialFactor == 0) continue;
      final stationSensitivity =
          event.kind == RealEstateWorldEventKind.transitPlan
          ? (1.30 - stationWalkMinutes / 40).clamp(0.72, 1.22)
          : 1.0;
      final downsideSensitivity = rawImpact < 0 ? downsideExposure : 1.0;
      total +=
          rawImpact * spatialFactor * stationSensitivity * downsideSensitivity;
    }
    return total.clamp(-0.42, 0.42);
  }

  int priceAt(DateTime date) {
    final basePrice = asset.priceAt(date);
    final combined = (localDeviationAt(date) + eventImpactAt(date)).clamp(
      -0.48,
      0.58,
    );
    final raw = basePrice * priceFactor * (1 + combined);
    final lower = basePrice * priceFactor * 0.48;
    final upper = basePrice * priceFactor * 1.62;
    return raw.clamp(lower, upper).round();
  }

  RealEstatePurchaseQuote quoteAt(DateTime date) =>
      asset.quoteForPrice(date, priceAt(date));

  int monthlyRentAt(DateTime date) {
    var eventRentFactor = 1.0;
    for (final event in events) {
      if (!event.isVisibleAt(date)) continue;
      if (event.kind == RealEstateWorldEventKind.vacancyShock ||
          event.kind == RealEstateWorldEventKind.supplyWave ||
          event.kind == RealEstateWorldEventKind.employerMove) {
        eventRentFactor += event.impactAt(date) * 1.35;
      }
    }
    eventRentFactor = eventRentFactor.clamp(0.52, 1.22);
    return (priceAt(date) *
            asset.annualGrossYield *
            rentFactor *
            eventRentFactor /
            12)
        .round();
  }

  int monthlyOperatingCostAt(DateTime date) =>
      (priceAt(date) * asset.annualOperatingCostRate * operatingCostFactor / 12)
          .round();

  int saleCostsAt(DateTime date) =>
      asset.saleCostsForPrice(date, priceAt(date));
}

List<GeneratedRealEstateListing> realEstateListingsFor(
  RealEstateMarketAsset asset,
  String worldSeed, {
  int count = 3,
}) => List<GeneratedRealEstateListing>.generate(count, (index) {
  final conditionRoll = _unit(
    '$worldSeed:${asset.id}:listing:$index:condition',
  );
  final condition = conditionRoll < 0.30
      ? RealEstateListingCondition.needsRepair
      : conditionRoll < 0.76
      ? RealEstateListingCondition.average
      : RealEstateListingCondition.renovated;
  final conditionFactor = switch (condition) {
    RealEstateListingCondition.needsRepair => 0.90,
    RealEstateListingCondition.average => 0.99,
    RealEstateListingCondition.renovated => 1.07,
  };
  final floor = switch (asset.type) {
    RealEstateAssetType.villa =>
      1 + (_stableHash('$worldSeed:${asset.id}:floor:$index') % 5),
    RealEstateAssetType.officetel || RealEstateAssetType.apartment =>
      2 + (_stableHash('$worldSeed:${asset.id}:floor:$index') % 28),
    _ => index + 1,
  };
  final stationWalk =
      3 + (_stableHash('$worldSeed:${asset.id}:walk:$index') % 21);
  final areaFactor = 0.94 + _unit('$worldSeed:${asset.id}:area:$index') * 0.13;
  final floorFactor = switch (asset.type) {
    RealEstateAssetType.officetel ||
    RealEstateAssetType.apartment => 0.96 + floor.clamp(1, 30) * 0.004,
    RealEstateAssetType.villa => 0.97 + floor * 0.006,
    _ => 1.0,
  };
  final stationFactor = (1.08 - stationWalk * 0.006).clamp(0.91, 1.06);
  final negotiationFactor =
      0.94 + _unit('$worldSeed:${asset.id}:price:$index') * 0.12;
  final downsideExposure =
      0.82 + _unit('$worldSeed:${asset.id}:risk:$index') * 0.54;
  final riskParts = <String>[
    if (condition == RealEstateListingCondition.needsRepair) '수선비 위험',
    if (stationWalk >= 16) '역 접근성 약함',
    if (downsideExposure >= 1.18) '악재 민감도 높음',
    if (condition == RealEstateListingCondition.renovated) '높은 매입 프리미엄',
  ];
  if (riskParts.isEmpty) riskParts.add('평균 수준 개별 위험');
  return GeneratedRealEstateListing(
    worldSeed: worldSeed,
    asset: asset,
    index: index,
    areaSquareMeters: asset.areaSquareMeters * areaFactor,
    floor: floor,
    stationWalkMinutes: stationWalk,
    condition: condition,
    priceFactor:
        conditionFactor * floorFactor * stationFactor * negotiationFactor,
    rentFactor: 0.90 + _unit('$worldSeed:${asset.id}:rent:$index') * 0.22,
    operatingCostFactor:
        0.86 + _unit('$worldSeed:${asset.id}:cost:$index') * 0.42,
    downsideExposure: downsideExposure,
    riskSummary: riskParts.join(' · '),
  );
});

GeneratedRealEstateListing? realEstateListingByRef(
  RealEstateListingRef ref,
  String worldSeed,
) {
  final asset = realEstateMarketAssetById(ref.assetId);
  if (asset == null) return null;
  final listings = realEstateListingsFor(asset, worldSeed);
  if (ref.listingIndex >= listings.length) return null;
  return listings[ref.listingIndex];
}

List<RealEstateDistrict> realEstateInfluenceDistrictsFor(
  RealEstateMarketAsset asset, {
  int maxDistricts = 4,
  double maxDistance = 0.30,
}) {
  final origin = realEstateDistrictFor(asset);
  final districts =
      realEstateDistrictCatalog
          .where((district) => origin.distanceTo(district) <= maxDistance)
          .toList()
        ..sort((a, b) => origin.distanceTo(a).compareTo(origin.distanceTo(b)));
  return districts.take(maxDistricts).toList(growable: false);
}

List<RealEstateWorldEvent> realEstateNearbyWorldEventsFor(
  RealEstateMarketAsset asset,
  String worldSeed,
) {
  final events = <RealEstateWorldEvent>[];
  for (final district in realEstateInfluenceDistrictsFor(asset)) {
    events.addAll(realEstateRegionalEventsForDistrict(district, worldSeed));
  }
  return events..sort((a, b) => a.announcedAt.compareTo(b.announcedAt));
}

double realEstateSpatialSpilloverFactor(
  RealEstateMarketAsset target,
  RealEstateWorldEvent event,
) {
  if (event.assetId == target.id) return 1.0;
  final targetDistrict = realEstateDistrictFor(target);
  final originDistrict = realEstateDistrictById(event.originDistrictId);
  if (originDistrict == null) return 0;
  final distance = targetDistrict.distanceTo(originDistrict);
  if (distance < 0.001) return 1.0;
  if (distance > 0.30) return 0;
  return (0.68 * (1 - distance / 0.30)).clamp(0.10, 0.58);
}

RealEstateWorldEvent? realEstateLatestDistrictEventAt(
  RealEstateDistrict district,
  String worldSeed,
  DateTime date,
) {
  final visible =
      realEstateRegionalEventsForDistrict(
          district,
          worldSeed,
        ).where((event) => event.isVisibleAt(date)).toList()
        ..sort((a, b) => b.announcedAt.compareTo(a.announcedAt));
  return visible.isEmpty ? null : visible.first;
}

List<RealEstateMarketAsset> realEstateAssetsInDistrict(
  RealEstateDistrict district,
) => realEstateMarketCatalog
    .where(
      (asset) =>
          asset.region == district.name && asset.province == district.province,
    )
    .toList(growable: false);

List<RealEstateWorldEvent> realEstateListingEventsFor(
  RealEstateMarketAsset asset,
  String worldSeed,
  int listingIndex,
) {
  final events = <RealEstateWorldEvent>[];
  final startYear = math.max(2000, asset.availableFrom.year);
  final kindValues = RealEstateWorldEventKind.values;
  final eventCount = math.max(0, 2026 - startYear) * 2;
  for (var index = 0; index < eventCount; index += 1) {
    if (index.isOdd &&
        _unit(
              '$worldSeed:${asset.id}:listing:$listingIndex:event-skip:$index',
            ) <
            0.45) {
      continue;
    }
    final year = startYear + 1 + index ~/ 2;
    if (year > 2026) continue;
    final key = '$worldSeed:${asset.id}:listing:$listingIndex:event:$index';
    final month = 1 + (_stableHash('$key:month') % 12);
    final announcedAt = DateTime(year, month);
    final durationMonths = 3 + (_stableHash('$key:duration') % 22);
    final resolvedAt = DateTime(
      announcedAt.year,
      announcedAt.month + durationMonths,
    );
    final kind = kindValues[_stableHash('$key:kind') % kindValues.length];
    final outcomeRoll = _unit('$key:outcome');
    final outcome = outcomeRoll < 0.34
        ? RealEstateWorldEventOutcome.completed
        : outcomeRoll < 0.68
        ? RealEstateWorldEventOutcome.delayed
        : RealEstateWorldEventOutcome.canceled;
    final major = _unit('$key:major') < 0.05;
    final strength = major
        ? 0.50 + _unit('$key:strength') * 0.70
        : 0.05 + _unit('$key:strength') * 0.20;
    final title = _listingEventTitle(kind, asset, listingIndex, '$key:title');
    events.add(
      RealEstateWorldEvent(
        id: '${asset.id}-listing-$listingIndex-${kind.name}-$index',
        assetId: asset.id,
        originDistrictId: realEstateDistrictFor(asset).id,
        kind: kind,
        announcedAt: announcedAt,
        resolvedAt: resolvedAt,
        outcome: outcome,
        announcementImpact: _announcementImpact(kind) * strength,
        resolvedImpact: _resolvedImpact(kind, outcome) * strength,
        title: title,
        unresolvedDetail: _eventUnresolvedDetail(kind, title),
        impactDurationDays: 365 * (major ? 4 : 1),
      ),
    );
  }
  return events..sort((a, b) => a.announcedAt.compareTo(b.announcedAt));
}

int realEstateGeneratedEventCount(
  String worldSeed, {
  int listingsPerAsset = 3,
}) {
  var count = 0;
  for (final district in realEstateDistrictCatalog) {
    count += realEstateRegionalEventsForDistrict(district, worldSeed).length;
  }
  for (final asset in realEstateMarketCatalog) {
    for (var index = 0; index < listingsPerAsset; index += 1) {
      count += realEstateListingEventsFor(asset, worldSeed, index).length;
    }
  }
  return count;
}

String _listingEventTitle(
  RealEstateWorldEventKind kind,
  RealEstateMarketAsset asset,
  int listingIndex,
  String key,
) {
  final base = _eventTitle(kind, asset.region, key);
  return '${asset.name} ${listingIndex + 1}호 · $base';
}

List<RealEstateWorldEvent> realEstateWorldEventsFor(
  RealEstateMarketAsset asset,
  String worldSeed,
) => realEstateRegionalEventsForDistrict(
  realEstateDistrictFor(asset),
  worldSeed,
);

List<RealEstateWorldEvent> realEstateRegionalEventsForDistrict(
  RealEstateDistrict district,
  String worldSeed,
) {
  final events = <RealEstateWorldEvent>[];
  final kindValues = RealEstateWorldEventKind.values;
  const eventCount = 26 * 3;
  for (var index = 0; index < eventCount; index += 1) {
    final year = 2001 + index ~/ 3;
    if (year > 2026) continue;
    final key = '$worldSeed:${district.id}:regional:$index';
    final month = 1 + (_stableHash('$key:month') % 12);
    final announcedAt = DateTime(year, month);
    final durationMonths = 9 + (_stableHash('$key:duration') % 31);
    final resolvedAt = DateTime(
      announcedAt.year,
      announcedAt.month + durationMonths,
    );
    final kind = kindValues[_stableHash('$key:kind') % kindValues.length];
    final outcomeRoll = _unit('$key:outcome');
    final outcome = outcomeRoll < 0.34
        ? RealEstateWorldEventOutcome.completed
        : outcomeRoll < 0.66
        ? RealEstateWorldEventOutcome.delayed
        : RealEstateWorldEventOutcome.canceled;
    final major = _unit('$key:major') < 0.10;
    final strength = major
        ? 0.72 + _unit('$key:strength') * 0.58
        : 0.08 + _unit('$key:strength') * 0.27;
    final announcementImpact = _announcementImpact(kind) * strength;
    final resolvedImpact = _resolvedImpact(kind, outcome) * strength;
    final title = _eventTitle(kind, district.name, '$key:title');
    events.add(
      RealEstateWorldEvent(
        id: '${district.id}-${kind.name}-$index',
        assetId: 'district:${district.id}',
        originDistrictId: district.id,
        kind: kind,
        announcedAt: announcedAt,
        resolvedAt: resolvedAt,
        outcome: outcome,
        announcementImpact: announcementImpact,
        resolvedImpact: resolvedImpact,
        title: title,
        unresolvedDetail: _eventUnresolvedDetail(kind, title),
        impactDurationDays: 365 * (major ? 5 : 2),
      ),
    );
  }
  return events..sort((a, b) => a.announcedAt.compareTo(b.announcedAt));
}

double _announcementImpact(RealEstateWorldEventKind kind) => switch (kind) {
  RealEstateWorldEventKind.transitPlan => 0.09,
  RealEstateWorldEventKind.redevelopment => 0.11,
  RealEstateWorldEventKind.schoolZone => 0.07,
  RealEstateWorldEventKind.supplyWave => -0.06,
  RealEstateWorldEventKind.employerMove => -0.07,
  RealEstateWorldEventKind.floodOrDefect => -0.09,
  RealEstateWorldEventKind.vacancyShock => -0.08,
};

double _resolvedImpact(
  RealEstateWorldEventKind kind,
  RealEstateWorldEventOutcome outcome,
) {
  if (kind.isPotentialUpside) {
    return switch (outcome) {
      RealEstateWorldEventOutcome.completed => switch (kind) {
        RealEstateWorldEventKind.transitPlan => 0.17,
        RealEstateWorldEventKind.redevelopment => 0.21,
        RealEstateWorldEventKind.schoolZone => 0.12,
        _ => 0.10,
      },
      RealEstateWorldEventOutcome.delayed => -0.04,
      RealEstateWorldEventOutcome.canceled => switch (kind) {
        RealEstateWorldEventKind.transitPlan => -0.21,
        RealEstateWorldEventKind.redevelopment => -0.18,
        _ => -0.13,
      },
    };
  }
  return switch (outcome) {
    RealEstateWorldEventOutcome.completed => switch (kind) {
      RealEstateWorldEventKind.supplyWave => -0.15,
      RealEstateWorldEventKind.employerMove => -0.19,
      RealEstateWorldEventKind.floodOrDefect => -0.18,
      RealEstateWorldEventKind.vacancyShock => -0.16,
      _ => -0.12,
    },
    RealEstateWorldEventOutcome.delayed => -0.05,
    RealEstateWorldEventOutcome.canceled => 0.04,
  };
}

String _eventTitle(
  RealEstateWorldEventKind kind,
  String region,
  String variantKey,
) {
  final patterns = switch (kind) {
    RealEstateWorldEventKind.transitPlan => const [
      '{region} 신규 역 후보지 발표',
      '{region} 광역철도 예비타당성 검토',
      '{region} 환승센터 기본계획',
      '{region} 노선안 변경 공청회',
      '{region} 급행버스 노선 개편',
      '{region} 역사 출입구 위치 논쟁',
    ],
    RealEstateWorldEventKind.redevelopment => const [
      '{region} 재건축 안전진단 추진',
      '{region} 재개발 동의율 조사',
      '{region} 리모델링 조합 설립',
      '{region} 정비구역 지정 검토',
      '{region} 용도지역 상향 논의',
      '{region} 조합 분담금 갈등',
    ],
    RealEstateWorldEventKind.supplyWave => const [
      '{region} 대단지 입주 물량 예고',
      '{region} 오피스텔 공급 급증',
      '{region} 공공주택 착공 발표',
      '{region} 미분양 물량 증가',
      '{region} 전세 매물 동시 출회',
      '{region} 인접 택지지구 입주 시작',
    ],
    RealEstateWorldEventKind.employerMove => const [
      '{region} 주요 사업장 외곽 이전 검토',
      '{region} 대기업 본사 이탈설',
      '{region} 주요 공장 감원 발표',
      '{region} 대형 상권 앵커 폐점',
      '{region} 대학 캠퍼스 이전 검토',
      '{region} 업무지구 공실 확대',
    ],
    RealEstateWorldEventKind.floodOrDefect => const [
      '{region} 집중호우 침수 제보',
      '{region} 외벽 균열 안전점검',
      '{region} 반복 누수 민원',
      '{region} 주차장 화재 조사',
      '{region} 층간소음 집단분쟁',
      '{region} 토양·악취 민원',
    ],
    RealEstateWorldEventKind.schoolZone => const [
      '{region} 초등학교 신설 검토',
      '{region} 학군 경계 조정안',
      '{region} 학교 통폐합 계획',
      '{region} 학원가 확장 움직임',
      '{region} 통학로 안전사업',
      '{region} 과밀학급 해소안',
    ],
    RealEstateWorldEventKind.vacancyShock => const [
      '{region} 원룸 공실률 급등',
      '{region} 임대료 연체 증가',
      '{region} 전세보증 사고 확산',
      '{region} 관리비 급등 민원',
      '{region} 골목상권 매출 감소',
      '{region} 상가 임차인 집단 퇴거',
    ],
  };
  return patterns[_stableHash(variantKey) % patterns.length].replaceAll(
    '{region}',
    region,
  );
}

String _eventUnresolvedDetail(RealEstateWorldEventKind kind, String title) =>
    switch (kind) {
      RealEstateWorldEventKind.transitPlan =>
        '$title. 노선·역 위치·사업성 검토가 남아 있어 확정으로 볼 수 없습니다.',
      RealEstateWorldEventKind.redevelopment =>
        '$title. 주민 동의율과 분담금, 인허가가 모두 변수입니다.',
      RealEstateWorldEventKind.supplyWave =>
        '$title. 실제 입주율과 전세 물량이 확인되기 전까지 임대료 영향은 불확실합니다.',
      RealEstateWorldEventKind.employerMove =>
        '$title. 고용 규모와 이전 시점이 확인되지 않아 배후수요가 흔들릴 수 있습니다.',
      RealEstateWorldEventKind.floodOrDefect =>
        '$title. 피해 범위와 보수 책임을 조사 중이며 추가 비용이 생길 수 있습니다.',
      RealEstateWorldEventKind.schoolZone =>
        '$title. 교육청 결정과 통학구역 확정 전까지 결과를 알 수 없습니다.',
      RealEstateWorldEventKind.vacancyShock =>
        '$title. 단기 계절 요인인지 장기 수요 감소인지 아직 판단하기 어렵습니다.',
    };

int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

double _unit(String key) => (_stableHash(key) % 1000000) / 999999;
