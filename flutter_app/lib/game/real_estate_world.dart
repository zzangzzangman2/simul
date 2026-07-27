import 'dart:collection';
import 'dart:math' as math;

import 'real_estate_market.dart';

/// 저장 게임이 참조할 수 있는 부동산 생성 규칙 버전.
///
/// 생성 공식이 바뀌면 같은 시드의 과거 가격·사건·매물 생애주기도 바뀌므로
/// 반드시 이 값을 올리고 저장 마이그레이션에서 명시적으로 처리해야 한다.
const realEstateWorldGeneratorVersion = 3;
const _maximumCachedRealEstateWorlds = 2;
const _realEstateListingLifecycleDays = 270;
const _realEstateListingPhaseSpacingDays = 90;
const _realEstateEventRevealRampDays = 21;
const _realEstateEventResolutionRampDays = 75;

class _FictionalRealEstateWorldCache {
  final Map<String, List<GeneratedRealEstateListing>> listingsByKey = {};
  final Map<String, List<RealEstateWorldEvent>> regionalEventsByDistrict = {};
  final Map<String, List<RealEstateWorldEvent>> listingEventsByKey = {};
  final Map<String, List<RealEstateWorldEvent>> nearbyEventsByAsset = {};
  final Map<String, List<RealEstateWorldEvent>> combinedEventsByListing = {};
  final Map<String, List<double>> localDeviationLevelsByListing = {};
  bool prewarmed = false;
}

final LinkedHashMap<String, _FictionalRealEstateWorldCache>
_fictionalRealEstateWorldCaches = LinkedHashMap();

String _realEstateWorldCacheKey(String worldSeed, int generatorVersion) =>
    '$generatorVersion::$worldSeed';

void _validateRealEstateWorldGeneratorVersion(int generatorVersion) {
  if (generatorVersion < 1 ||
      generatorVersion > realEstateWorldGeneratorVersion) {
    throw FormatException(
      'Unsupported real-estate world version: $generatorVersion '
      '(supported 1-$realEstateWorldGeneratorVersion)',
    );
  }
}

_FictionalRealEstateWorldCache _realEstateWorldCacheFor(
  String worldSeed, {
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  _validateRealEstateWorldGeneratorVersion(generatorVersion);
  final cacheKey = _realEstateWorldCacheKey(worldSeed, generatorVersion);
  final existing = _fictionalRealEstateWorldCaches.remove(cacheKey);
  if (existing != null) {
    _fictionalRealEstateWorldCaches[cacheKey] = existing;
    return existing;
  }
  final created = _FictionalRealEstateWorldCache();
  _fictionalRealEstateWorldCaches[cacheKey] = created;
  while (_fictionalRealEstateWorldCaches.length >
      _maximumCachedRealEstateWorlds) {
    _fictionalRealEstateWorldCaches.remove(
      _fictionalRealEstateWorldCaches.keys.first,
    );
  }
  return created;
}

class FictionalRealEstateWorldSummary {
  const FictionalRealEstateWorldSummary({
    required this.listingCount,
    required this.regionalEventCount,
    required this.listingEventCount,
    this.generatorVersion = realEstateWorldGeneratorVersion,
  });

  final int listingCount;
  final int regionalEventCount;
  final int listingEventCount;
  final int generatorVersion;

  int get eventCount => regionalEventCount + listingEventCount;
}

/// Materializes the deterministic property catalogue and its long-lived
/// regional/listing events before gameplay begins.
FictionalRealEstateWorldSummary prewarmFictionalRealEstateWorld(
  String worldSeed, {
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  _validateRealEstateWorldGeneratorVersion(generatorVersion);
  var listingCount = 0;
  var regionalEventCount = 0;
  var listingEventCount = 0;
  for (final district in realEstateDistrictCatalog) {
    regionalEventCount += _realEstateRegionalEventsForDistrict(
      district,
      worldSeed,
      generatorVersion: generatorVersion,
    ).length;
  }
  for (final asset in realEstateMarketCatalog) {
    final listings = realEstateListingsFor(
      asset,
      worldSeed,
      generatorVersion: generatorVersion,
    );
    listingCount += listings.length;
    _realEstateNearbyWorldEventsFor(
      asset,
      worldSeed,
      generatorVersion: generatorVersion,
    );
    for (final listing in listings) {
      listingEventCount += _realEstateListingEventsFor(
        asset,
        worldSeed,
        listing.index,
        generatorVersion: generatorVersion,
      ).length;
      listing.visibleEventsAt(DateTime(2026, 12, 31));
    }
  }
  _realEstateWorldCacheFor(
    worldSeed,
    generatorVersion: generatorVersion,
  ).prewarmed = true;
  return FictionalRealEstateWorldSummary(
    listingCount: listingCount,
    regionalEventCount: regionalEventCount,
    listingEventCount: listingEventCount,
    generatorVersion: generatorVersion,
  );
}

bool isFictionalRealEstateWorldCached(
  String worldSeed, {
  int generatorVersion = realEstateWorldGeneratorVersion,
}) =>
    _fictionalRealEstateWorldCaches[_realEstateWorldCacheKey(
          worldSeed,
          generatorVersion,
        )]
        ?.prewarmed ??
    false;

/// 날짜 경계가 구조적으로 적용된 읽기 전용 부동산 월드다.
///
/// 화면은 원본 생성 함수 대신 이 뷰를 사용하면 미래 자산·사건·비활성
/// 매물을 실수로 노출할 수 없다.
class FictionalRealEstateWorld {
  const FictionalRealEstateWorld({
    required this.worldSeed,
    this.generatorVersion = realEstateWorldGeneratorVersion,
  });

  final String worldSeed;
  final int generatorVersion;

  FictionalRealEstateWorldView asOf(DateTime date) {
    _validateRealEstateWorldGeneratorVersion(generatorVersion);
    return FictionalRealEstateWorldView._(
      worldSeed: worldSeed,
      date: DateTime(date.year, date.month, date.day),
      generatorVersion: generatorVersion,
    );
  }
}

class FictionalRealEstateWorldView {
  const FictionalRealEstateWorldView._({
    required this.worldSeed,
    required this.date,
    required this.generatorVersion,
  });

  final String worldSeed;
  final DateTime date;
  final int generatorVersion;

  List<RealEstateMarketAsset> get assets => realEstateMarketCatalogAt(date);

  List<GeneratedRealEstateListing> listingsFor(
    RealEstateMarketAsset asset, {
    int count = 3,
  }) => realEstateActiveListingsAt(
    asset,
    worldSeed,
    date,
    count: count,
    generatorVersion: generatorVersion,
  );

  List<RealEstateListingLifecycle> listingLifecyclesFor(
    RealEstateMarketAsset asset, {
    int count = 3,
  }) => realEstateListingLifecyclesAt(
    asset,
    worldSeed,
    date,
    count: count,
    generatorVersion: generatorVersion,
  );

  GeneratedRealEstateListing? listingByRef(RealEstateListingRef ref) =>
      realEstateListingByRefAt(
        ref,
        worldSeed,
        date,
        generatorVersion: generatorVersion,
      );

  List<RealEstateWorldEvent> eventsFor(RealEstateMarketAsset asset) =>
      realEstateVisibleWorldEventsAt(
        asset,
        worldSeed,
        date,
        generatorVersion: generatorVersion,
      );
}

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
  interestRatePolicy,
  housingPolicy,
  tenantPolicy,
  publicFacility,
  commercialCycle,
  environmentalChange,
  safetyChange,
  demographicShift,
}

const _legacyRealEstateWorldEventKinds = <RealEstateWorldEventKind>[
  RealEstateWorldEventKind.transitPlan,
  RealEstateWorldEventKind.redevelopment,
  RealEstateWorldEventKind.supplyWave,
  RealEstateWorldEventKind.employerMove,
  RealEstateWorldEventKind.floodOrDefect,
  RealEstateWorldEventKind.schoolZone,
  RealEstateWorldEventKind.vacancyShock,
];

extension RealEstateWorldEventKindLabel on RealEstateWorldEventKind {
  String get label => switch (this) {
    RealEstateWorldEventKind.transitPlan => '교통 계획',
    RealEstateWorldEventKind.redevelopment => '정비사업',
    RealEstateWorldEventKind.supplyWave => '입주 물량',
    RealEstateWorldEventKind.employerMove => '대형 고용처',
    RealEstateWorldEventKind.floodOrDefect => '하자·재해',
    RealEstateWorldEventKind.schoolZone => '학군 변화',
    RealEstateWorldEventKind.vacancyShock => '공실 충격',
    RealEstateWorldEventKind.interestRatePolicy => '금융 여건',
    RealEstateWorldEventKind.housingPolicy => '정책·세제',
    RealEstateWorldEventKind.tenantPolicy => '임대차 제도',
    RealEstateWorldEventKind.publicFacility => '생활 인프라',
    RealEstateWorldEventKind.commercialCycle => '상권 변화',
    RealEstateWorldEventKind.environmentalChange => '환경·쾌적성',
    RealEstateWorldEventKind.safetyChange => '치안·안전',
    RealEstateWorldEventKind.demographicShift => '인구·수요',
  };

  bool get isPotentialUpside => switch (this) {
    RealEstateWorldEventKind.transitPlan ||
    RealEstateWorldEventKind.redevelopment ||
    RealEstateWorldEventKind.schoolZone ||
    RealEstateWorldEventKind.publicFacility => true,
    _ => false,
  };

  bool get affectsRentalDemand => switch (this) {
    RealEstateWorldEventKind.supplyWave ||
    RealEstateWorldEventKind.employerMove ||
    RealEstateWorldEventKind.vacancyShock ||
    RealEstateWorldEventKind.tenantPolicy ||
    RealEstateWorldEventKind.publicFacility ||
    RealEstateWorldEventKind.commercialCycle ||
    RealEstateWorldEventKind.environmentalChange ||
    RealEstateWorldEventKind.safetyChange ||
    RealEstateWorldEventKind.demographicShift => true,
    _ => false,
  };

  bool get affectsRepairRisk => switch (this) {
    RealEstateWorldEventKind.floodOrDefect ||
    RealEstateWorldEventKind.environmentalChange ||
    RealEstateWorldEventKind.safetyChange => true,
    _ => false,
  };
}

enum RealEstateWorldEventOutcome { completed, delayed, canceled }

extension RealEstateWorldEventOutcomeLabel on RealEstateWorldEventOutcome {
  String labelFor(RealEstateWorldEventKind kind, {bool? potentialUpside}) {
    if (potentialUpside ?? kind.isPotentialUpside) {
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
  const RealEstateWorldEvent._({
    required this.id,
    required this.assetId,
    required this.originDistrictId,
    required this.generatorVersion,
    required this.kind,
    required this.announcedAt,
    required this.resolvedAt,
    required this._outcome,
    required this.announcementImpact,
    required this._resolvedImpact,
    required this.isPotentialUpside,
    required this.title,
    required this.unresolvedDetail,
    required this.impactDurationDays,
  });

  final String id;
  final String assetId;
  final String originDistrictId;
  final int generatorVersion;
  final RealEstateWorldEventKind kind;
  final DateTime announcedAt;
  final DateTime resolvedAt;
  final RealEstateWorldEventOutcome _outcome;
  final double announcementImpact;
  final double _resolvedImpact;
  final bool isPotentialUpside;
  final String title;
  final String unresolvedDetail;
  final int impactDurationDays;

  bool isVisibleAt(DateTime date) => !date.isBefore(announcedAt);

  bool isResolvedAt(DateTime date) => !date.isBefore(resolvedAt);

  RealEstateWorldEventOutcome? outcomeAt(DateTime date) =>
      isResolvedAt(date) ? _outcome : null;

  double impactAt(DateTime date) {
    if (!isVisibleAt(date)) return 0;
    if (generatorVersion == 1) {
      if (!isResolvedAt(date)) return announcementImpact;
      final elapsed = date.difference(resolvedAt).inDays;
      if (elapsed >= impactDurationDays) return 0;
      final decay = 1 - elapsed / impactDurationDays;
      return _resolvedImpact * decay.clamp(0.0, 1.0);
    }
    if (!isResolvedAt(date)) {
      final elapsed = date.difference(announcedAt).inDays;
      final revealProgress = ((elapsed + 1) / _realEstateEventRevealRampDays)
          .clamp(0.0, 1.0);
      return announcementImpact * _smoothStep(revealProgress);
    }
    final elapsed = date.difference(resolvedAt).inDays;
    final permanentImpact =
        _outcome == RealEstateWorldEventOutcome.completed &&
            isPotentialUpside &&
            assetId.startsWith('district:') &&
            (kind == RealEstateWorldEventKind.transitPlan ||
                kind == RealEstateWorldEventKind.redevelopment)
        ? _resolvedImpact * 0.32
        : 0.0;
    if (elapsed < _realEstateEventResolutionRampDays) {
      final resolutionProgress =
          ((elapsed + 1) / _realEstateEventResolutionRampDays).clamp(0.0, 1.0);
      return _lerpDouble(
        announcementImpact,
        _resolvedImpact,
        _smoothStep(resolutionProgress),
      );
    }
    if (elapsed >= impactDurationDays) return permanentImpact;
    final decaySpan = math.max(
      1,
      impactDurationDays - _realEstateEventResolutionRampDays,
    );
    final decayProgress =
        ((elapsed - _realEstateEventResolutionRampDays) / decaySpan).clamp(
          0.0,
          1.0,
        );
    return _lerpDouble(
      _resolvedImpact,
      permanentImpact,
      _smoothStep(decayProgress),
    );
  }

  String statusAt(DateTime date) {
    if (!isVisibleAt(date)) return '미공개';
    if (!isResolvedAt(date)) {
      return isPotentialUpside ? '발표·검토 중' : '위험 신호';
    }
    return _outcome.labelFor(kind, potentialUpside: isPotentialUpside);
  }

  String detailAt(DateTime date) {
    if (!isResolvedAt(date)) {
      return unresolvedDetail;
    }
    return _resolvedEventDetail(this);
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
    this.generatorVersion = realEstateWorldGeneratorVersion,
    required this.areaSquareMeters,
    required this.floor,
    required this.stationWalkMinutes,
    required this.condition,
    required this.priceFactor,
    this.areaPriceFactor = 1.0,
    required this.rentFactor,
    required this.operatingCostFactor,
    required this.downsideExposure,
    required this.riskSummary,
  });

  final String worldSeed;
  final RealEstateMarketAsset asset;
  final int index;
  final int generatorVersion;
  final double areaSquareMeters;
  final int floor;
  final int stationWalkMinutes;
  final RealEstateListingCondition condition;

  /// 기준 매물 면적 대비 실제 생성 면적 비율. 매매가와 임대료 모두 반영한다.
  final double areaPriceFactor;
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

  List<RealEstateWorldEvent> get _events => _realEstateCombinedEventsForListing(
    asset,
    worldSeed,
    index,
    generatorVersion: generatorVersion,
  );

  List<RealEstateWorldEvent> visibleEventsAt(DateTime date) {
    final visible = _events.where((event) => event.isVisibleAt(date)).toList()
      ..sort((a, b) => b.announcedAt.compareTo(a.announcedAt));
    return visible;
  }

  RealEstateWorldEvent? latestVisibleEventAt(DateTime date) {
    final visible = visibleEventsAt(date);
    return visible.isEmpty ? null : visible.first;
  }

  double localDeviationAt(DateTime date) {
    if (generatorVersion == 1) return _legacyLocalDeviationAt(date);
    if (date.isBefore(asset.availableFrom)) return 0;
    final monthStart = DateTime(date.year, date.month);
    final nextMonth = DateTime(date.year, date.month + 1);
    final currentLevel = _localDeviationLevelAtMonth(monthStart);
    final nextLevel = _localDeviationLevelAtMonth(nextMonth);
    final elapsed = date.difference(monthStart).inHours;
    final span = nextMonth.difference(monthStart).inHours;
    final progress = span <= 0 ? 0.0 : (elapsed / span).clamp(0.0, 1.0);
    return _lerpDouble(
      currentLevel,
      nextLevel,
      _smoothStep(progress),
    ).clamp(-0.28, 0.24);
  }

  double _legacyLocalDeviationAt(DateTime date) {
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

  double _localDeviationLevelAtMonth(DateTime targetMonth) {
    final start = DateTime(asset.availableFrom.year, asset.availableFrom.month);
    final normalizedTarget = DateTime(targetMonth.year, targetMonth.month);
    final targetOffset =
        (normalizedTarget.year - start.year) * 12 +
        normalizedTarget.month -
        start.month;
    if (targetOffset < 0) return 0;
    final cache = _realEstateWorldCacheFor(
      worldSeed,
      generatorVersion: generatorVersion,
    );
    final levels = cache.localDeviationLevelsByListing.putIfAbsent(
      '${asset.id}:$index',
      () => <double>[],
    );
    while (levels.length <= targetOffset) {
      final cursor = DateTime(start.year, start.month + levels.length);
      final key =
          '$worldSeed:${asset.id}:listing:$index:month:'
          '${cursor.year}-${cursor.month}';
      var innovation = (_unit('$key:base') - 0.5) * 0.024;
      final tail = _unit('$key:tail');
      if (tail < 0.024) {
        innovation -= 0.040 + _unit('$key:down') * 0.055;
      } else if (tail > 0.985) {
        innovation += 0.030 + _unit('$key:up') * 0.040;
      }
      final previous = levels.isEmpty ? 0.0 : levels.last;
      levels.add((previous * 0.94 + innovation).clamp(-0.28, 0.24));
    }
    return levels[targetOffset];
  }

  double eventImpactAt(DateTime date) {
    if (generatorVersion == 1) {
      var total = 0.0;
      for (final event in _events) {
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
            rawImpact *
            spatialFactor *
            stationSensitivity *
            downsideSensitivity;
      }
      return total.clamp(-0.42, 0.42);
    }
    final contributions = <double>[];
    for (final event in _events) {
      final rawImpact = event.impactAt(date);
      if (rawImpact == 0) continue;
      final spatialFactor = realEstateSpatialSpilloverFactor(asset, event);
      if (spatialFactor == 0) continue;
      final stationSensitivity =
          event.kind == RealEstateWorldEventKind.transitPlan
          ? (1.30 - stationWalkMinutes / 40).clamp(0.72, 1.22)
          : 1.0;
      final downsideSensitivity = rawImpact < 0 ? downsideExposure : 1.0;
      contributions.add(
        rawImpact * spatialFactor * stationSensitivity * downsideSensitivity,
      );
    }
    return _combineDiminishingImpacts(
      contributions,
      minimum: -0.34,
      maximum: 0.34,
    );
  }

  int priceAt(DateTime date) {
    final basePrice = asset.priceAt(date);
    if (generatorVersion == 1) {
      final combined = (localDeviationAt(date) + eventImpactAt(date)).clamp(
        -0.48,
        0.58,
      );
      final raw = basePrice * priceFactor * (1 + combined);
      final lower = basePrice * priceFactor * 0.48;
      final upper = basePrice * priceFactor * 1.62;
      return raw.clamp(lower, upper).round();
    }
    final combined = (localDeviationAt(date) + eventImpactAt(date)).clamp(
      -0.42,
      0.48,
    );
    final effectivePriceFactor = priceFactor * areaPriceFactor;
    final raw = basePrice * effectivePriceFactor * (1 + combined);
    final lower = basePrice * effectivePriceFactor * 0.58;
    final upper = basePrice * effectivePriceFactor * 1.48;
    return raw.clamp(lower, upper).round();
  }

  RealEstatePurchaseQuote quoteAt(DateTime date) =>
      asset.quoteForPrice(date, priceAt(date));

  int monthlyRentAt(DateTime date) {
    if (generatorVersion == 1) {
      final eventRentFactor = 1 + rentEventImpactAt(date);
      return (priceAt(date) *
              asset.annualGrossYield *
              rentFactor *
              eventRentFactor /
              12)
          .round();
    }
    final eventRentFactor = 1 + rentEventImpactAt(date);
    final localRentPressure = math.pow(
      (1 + localDeviationAt(date)).clamp(0.72, 1.24),
      0.18,
    );
    return (asset.monthlyRentAt(date) *
            areaPriceFactor *
            rentFactor *
            eventRentFactor *
            localRentPressure)
        .round();
  }

  double rentEventImpactAt(DateTime date) {
    if (generatorVersion == 1) {
      var factor = 1.0;
      for (final event in _events) {
        if (!event.isVisibleAt(date)) continue;
        if (event.kind.affectsRentalDemand) {
          factor += event.impactAt(date) * 1.35;
        }
      }
      return factor.clamp(0.52, 1.22) - 1;
    }
    final rentEventContributions = <double>[];
    for (final event in _events) {
      final contribution = rentEventImpactContribution(event, date);
      if (contribution != 0) rentEventContributions.add(contribution);
    }
    return _combineDiminishingImpacts(
      rentEventContributions,
      minimum: -0.28,
      maximum: 0.16,
    );
  }

  double rentEventImpactContribution(
    RealEstateWorldEvent event,
    DateTime date,
  ) {
    if (!event.isVisibleAt(date) || !event.kind.affectsRentalDemand) {
      return 0;
    }
    if (generatorVersion == 1) return event.impactAt(date) * 1.35;
    final spatialFactor = realEstateSpatialSpilloverFactor(asset, event);
    return event.impactAt(date) * spatialFactor * 0.90;
  }

  RealEstateListingRiskFactors riskFactorsAt(DateTime date) =>
      realEstateListingRiskFactorsAt(this, date);

  int monthlyOperatingCostAt(DateTime date) =>
      (priceAt(date) * asset.annualOperatingCostRate * operatingCostFactor / 12)
          .round();

  int saleCostsAt(DateTime date) =>
      asset.saleCostsForPrice(date, priceAt(date));
}

class RealEstateListingRiskFactors {
  const RealEstateListingRiskFactors({
    required this.vacancyMultiplier,
    required this.repairProbabilityMultiplier,
    required this.repairCostMultiplier,
  });

  /// 1.0보다 높을수록 세입자 모집기간·공실 확률이 커진다.
  final double vacancyMultiplier;

  /// 1.0보다 높을수록 월별 수리 사건 발생 확률이 커진다.
  final double repairProbabilityMultiplier;

  /// 1.0보다 높을수록 같은 수리 사건의 비용이 커진다.
  final double repairCostMultiplier;
}

/// 매물 상태와 공개된 지역 사건을 실제 운영 위험으로 변환한다.
RealEstateListingRiskFactors realEstateListingRiskFactorsAt(
  GeneratedRealEstateListing listing,
  DateTime date,
) {
  var vacancyMultiplier = switch (listing.condition) {
    RealEstateListingCondition.needsRepair => 1.18,
    RealEstateListingCondition.average => 1.0,
    RealEstateListingCondition.renovated => 0.84,
  };
  var repairProbabilityMultiplier = switch (listing.condition) {
    RealEstateListingCondition.needsRepair => 1.75,
    RealEstateListingCondition.average => 1.0,
    RealEstateListingCondition.renovated => 0.62,
  };
  var repairCostMultiplier = switch (listing.condition) {
    RealEstateListingCondition.needsRepair => 1.30,
    RealEstateListingCondition.average => 1.0,
    RealEstateListingCondition.renovated => 0.78,
  };
  vacancyMultiplier *= (0.90 + listing.stationWalkMinutes / 80).clamp(
    0.94,
    1.20,
  );
  for (final event in listing._events) {
    final rawImpact = event.impactAt(date);
    if (rawImpact == 0) continue;
    final spatial = realEstateSpatialSpilloverFactor(listing.asset, event);
    if (spatial == 0) continue;
    final severity = rawImpact.abs() * spatial;
    if (event.kind.affectsRentalDemand) {
      vacancyMultiplier *= rawImpact < 0
          ? 1 + severity * 3.0
          : 1 - severity * 1.2;
    }
    if (event.kind.affectsRepairRisk) {
      repairProbabilityMultiplier *= rawImpact < 0
          ? 1 + severity * 4.2
          : 1 - severity;
      repairCostMultiplier *= rawImpact < 0
          ? 1 + severity * 2.6
          : 1 - severity * 0.7;
    }
    if (event.kind == RealEstateWorldEventKind.redevelopment &&
        !event.isPotentialUpside &&
        rawImpact < 0) {
      repairCostMultiplier *= 1 + severity * 1.4;
    }
  }
  return RealEstateListingRiskFactors(
    vacancyMultiplier: vacancyMultiplier.clamp(0.65, 2.40),
    repairProbabilityMultiplier: repairProbabilityMultiplier.clamp(0.45, 3.20),
    repairCostMultiplier: repairCostMultiplier.clamp(0.60, 2.50),
  );
}

enum RealEstateListingAvailability {
  notYetAvailable,
  active,
  npcPurchased,
  expired,
}

class RealEstateListingLifecycle {
  const RealEstateListingLifecycle({
    required this.listing,
    required this.asOfDate,
    required this.cycleNumber,
    required this.listedAt,
    required this.expiresAt,
    required this.relistsAt,
    required this.availability,
  });

  final GeneratedRealEstateListing listing;
  final DateTime asOfDate;
  final int cycleNumber;
  final DateTime listedAt;
  final DateTime expiresAt;
  final DateTime relistsAt;
  final RealEstateListingAvailability availability;

  bool get isActive => availability == RealEstateListingAvailability.active;

  /// 같은 실제 매물이 재등록될 때도 거래 인스턴스를 구분할 수 있는 ID.
  String get listingInstanceId => '${listing.optionId}::cycle::$cycleNumber';
}

List<GeneratedRealEstateListing> realEstateListingsFor(
  RealEstateMarketAsset asset,
  String worldSeed, {
  int count = 3,
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  _validateRealEstateWorldGeneratorVersion(generatorVersion);
  final cache = _realEstateWorldCacheFor(
    worldSeed,
    generatorVersion: generatorVersion,
  );
  final cacheKey = '${asset.id}:$count';
  return cache.listingsByKey.putIfAbsent(
    cacheKey,
    () => List<GeneratedRealEstateListing>.unmodifiable(
      List<GeneratedRealEstateListing>.generate(count, (index) {
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
        final areaFactor =
            0.94 + _unit('$worldSeed:${asset.id}:area:$index') * 0.13;
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
          generatorVersion: generatorVersion,
          areaSquareMeters: asset.areaSquareMeters * areaFactor,
          floor: floor,
          stationWalkMinutes: stationWalk,
          condition: condition,
          priceFactor:
              conditionFactor * floorFactor * stationFactor * negotiationFactor,
          areaPriceFactor: generatorVersion == 1 || asset.areaSquareMeters <= 0
              ? 1.0
              : areaFactor,
          rentFactor: 0.90 + _unit('$worldSeed:${asset.id}:rent:$index') * 0.22,
          operatingCostFactor:
              0.86 + _unit('$worldSeed:${asset.id}:cost:$index') * 0.42,
          downsideExposure: downsideExposure,
          riskSummary: riskParts.join(' · '),
        );
      }),
    ),
  );
}

GeneratedRealEstateListing? realEstateListingByRef(
  RealEstateListingRef ref,
  String worldSeed, {
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  final asset = realEstateMarketAssetById(ref.assetId);
  if (asset == null) return null;
  final listings = realEstateListingsFor(
    asset,
    worldSeed,
    generatorVersion: generatorVersion,
  );
  if (ref.listingIndex >= listings.length) return null;
  return listings[ref.listingIndex];
}

List<RealEstateListingLifecycle> realEstateListingLifecyclesAt(
  RealEstateMarketAsset asset,
  String worldSeed,
  DateTime date, {
  int count = 3,
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final listings = realEstateListingsFor(
    asset,
    worldSeed,
    count: count,
    generatorVersion: generatorVersion,
  );
  if (generatorVersion == 1) {
    return List<RealEstateListingLifecycle>.unmodifiable([
      for (final listing in listings)
        RealEstateListingLifecycle(
          listing: listing,
          asOfDate: normalizedDate,
          cycleNumber: 0,
          listedAt: asset.availableFrom,
          expiresAt: DateTime(9999, 12, 31),
          relistsAt: DateTime(9999, 12, 31),
          availability: normalizedDate.isBefore(asset.availableFrom)
              ? RealEstateListingAvailability.notYetAvailable
              : RealEstateListingAvailability.active,
        ),
    ]);
  }
  if (normalizedDate.isBefore(asset.availableFrom)) {
    return List<RealEstateListingLifecycle>.unmodifiable([
      for (final listing in listings)
        RealEstateListingLifecycle(
          listing: listing,
          asOfDate: normalizedDate,
          cycleNumber: 0,
          listedAt: asset.availableFrom,
          expiresAt: asset.availableFrom,
          relistsAt: asset.availableFrom,
          availability: RealEstateListingAvailability.notYetAvailable,
        ),
    ]);
  }
  final daysSinceAvailable = normalizedDate
      .difference(asset.availableFrom)
      .inDays;
  return List<RealEstateListingLifecycle>.unmodifiable([
    for (final listing in listings)
      _realEstateListingLifecycleAt(
        listing,
        normalizedDate,
        daysSinceAvailable,
      ),
  ]);
}

RealEstateListingLifecycle _realEstateListingLifecycleAt(
  GeneratedRealEstateListing listing,
  DateTime date,
  int daysSinceAvailable,
) {
  final shiftedDay =
      daysSinceAvailable + listing.index * _realEstateListingPhaseSpacingDays;
  final cycleNumber = shiftedDay ~/ _realEstateListingLifecycleDays;
  final phase = shiftedDay % _realEstateListingLifecycleDays;
  final cycleStartOffset =
      cycleNumber * _realEstateListingLifecycleDays -
      listing.index * _realEstateListingPhaseSpacingDays;
  final cycleStart = listing.asset.availableFrom.add(
    Duration(days: cycleStartOffset),
  );
  final activeDays =
      195 +
      _stableHash(
            '${listing.worldSeed}:${listing.asset.id}:'
            '${listing.index}:listing-active:$cycleNumber',
          ) %
          46;
  final expiresAt = cycleStart.add(Duration(days: activeDays));
  final relistsAt = cycleStart.add(
    const Duration(days: _realEstateListingLifecycleDays),
  );
  final listedAt = cycleStart.isBefore(listing.asset.availableFrom)
      ? listing.asset.availableFrom
      : cycleStart;
  if (phase < activeDays) {
    return RealEstateListingLifecycle(
      listing: listing,
      asOfDate: date,
      cycleNumber: cycleNumber,
      listedAt: listedAt,
      expiresAt: expiresAt,
      relistsAt: relistsAt,
      availability: RealEstateListingAvailability.active,
    );
  }
  final npcPurchased =
      _unit(
        '${listing.worldSeed}:${listing.asset.id}:${listing.index}:'
        'listing-outcome:$cycleNumber',
      ) <
      0.62;
  return RealEstateListingLifecycle(
    listing: listing,
    asOfDate: date,
    cycleNumber: cycleNumber,
    listedAt: listedAt,
    expiresAt: expiresAt,
    relistsAt: relistsAt,
    availability: npcPurchased
        ? RealEstateListingAvailability.npcPurchased
        : RealEstateListingAvailability.expired,
  );
}

List<GeneratedRealEstateListing> realEstateActiveListingsAt(
  RealEstateMarketAsset asset,
  String worldSeed,
  DateTime date, {
  int count = 3,
  int generatorVersion = realEstateWorldGeneratorVersion,
}) => List<GeneratedRealEstateListing>.unmodifiable(
  realEstateListingLifecyclesAt(
    asset,
    worldSeed,
    date,
    count: count,
    generatorVersion: generatorVersion,
  ).where((state) => state.isActive).map((state) => state.listing),
);

/// 이름을 통해 날짜형 API임을 바로 알 수 있게 한 호환 별칭.
List<GeneratedRealEstateListing> realEstateListingsAt(
  RealEstateMarketAsset asset,
  String worldSeed,
  DateTime date, {
  int count = 3,
  int generatorVersion = realEstateWorldGeneratorVersion,
}) => realEstateActiveListingsAt(
  asset,
  worldSeed,
  date,
  count: count,
  generatorVersion: generatorVersion,
);

GeneratedRealEstateListing? realEstateListingByRefAt(
  RealEstateListingRef ref,
  String worldSeed,
  DateTime date, {
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  final listing = realEstateListingByRef(
    ref,
    worldSeed,
    generatorVersion: generatorVersion,
  );
  if (listing == null || date.isBefore(listing.asset.availableFrom)) {
    return null;
  }
  return realEstateListingLifecyclesAt(
        listing.asset,
        worldSeed,
        date,
        generatorVersion: generatorVersion,
      ).any(
        (state) =>
            state.listing.index == listing.index &&
            state.availability == RealEstateListingAvailability.active,
      )
      ? listing
      : null;
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

List<RealEstateWorldEvent> _realEstateNearbyWorldEventsFor(
  RealEstateMarketAsset asset,
  String worldSeed, {
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  final cache = _realEstateWorldCacheFor(
    worldSeed,
    generatorVersion: generatorVersion,
  );
  return cache.nearbyEventsByAsset.putIfAbsent(asset.id, () {
    final events = <RealEstateWorldEvent>[];
    for (final district in realEstateInfluenceDistrictsFor(asset)) {
      events.addAll(
        _realEstateRegionalEventsForDistrict(
          district,
          worldSeed,
          generatorVersion: generatorVersion,
        ),
      );
    }
    events.sort((a, b) => a.announcedAt.compareTo(b.announcedAt));
    return List<RealEstateWorldEvent>.unmodifiable(events);
  });
}

List<RealEstateWorldEvent> _realEstateCombinedEventsForListing(
  RealEstateMarketAsset asset,
  String worldSeed,
  int listingIndex, {
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  final cache = _realEstateWorldCacheFor(
    worldSeed,
    generatorVersion: generatorVersion,
  );
  final cacheKey = '${asset.id}:$listingIndex';
  return cache.combinedEventsByListing.putIfAbsent(cacheKey, () {
    final combined = <RealEstateWorldEvent>[
      ..._realEstateNearbyWorldEventsFor(
        asset,
        worldSeed,
        generatorVersion: generatorVersion,
      ),
      ..._realEstateListingEventsFor(
        asset,
        worldSeed,
        listingIndex,
        generatorVersion: generatorVersion,
      ),
    ]..sort((a, b) => a.announcedAt.compareTo(b.announcedAt));
    return List<RealEstateWorldEvent>.unmodifiable(combined);
  });
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
  DateTime date, {
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  final visible =
      _realEstateRegionalEventsForDistrict(
          district,
          worldSeed,
          generatorVersion: generatorVersion,
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

List<RealEstateWorldEvent> _realEstateListingEventsFor(
  RealEstateMarketAsset asset,
  String worldSeed,
  int listingIndex, {
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  final cache = _realEstateWorldCacheFor(
    worldSeed,
    generatorVersion: generatorVersion,
  );
  final cacheKey = '${asset.id}:$listingIndex';
  return cache.listingEventsByKey.putIfAbsent(cacheKey, () {
    final events = <RealEstateWorldEvent>[];
    final startYear = math.max(2000, asset.availableFrom.year);
    final kindValues = generatorVersion >= 3
        ? RealEstateWorldEventKind.values
        : _legacyRealEstateWorldEventKinds;
    final availableYears = math.max(0, 2027 - startYear);
    final eventCount = generatorVersion == 1
        ? math.max(0, 2026 - startYear) * 2
        : generatorVersion == 2
        ? availableYears
        : availableYears * 2;
    for (var index = 0; index < eventCount; index += 1) {
      if (generatorVersion == 1 &&
          index.isOdd &&
          _unit(
                '$worldSeed:${asset.id}:listing:$listingIndex:event-skip:$index',
              ) <
              0.45) {
        continue;
      }
      final year = generatorVersion == 1
          ? startYear + 1 + index ~/ 2
          : generatorVersion == 2
          ? startYear + index
          : startYear + index ~/ 2;
      if (year > 2026) continue;
      final key = '$worldSeed:${asset.id}:listing:$listingIndex:event:$index';
      final month = generatorVersion >= 3
          ? 1 + (index.isOdd ? 6 : 0) + (_stableHash('$key:month') % 6)
          : 1 + (_stableHash('$key:month') % 12);
      final announcedAt = generatorVersion == 1
          ? DateTime(year, month)
          : DateTime(year, month, 3 + _stableHash('$key:day') % 25);
      if (announcedAt.isBefore(asset.availableFrom)) continue;
      final durationMonths = generatorVersion == 1
          ? 3 + (_stableHash('$key:duration') % 22)
          : generatorVersion == 2
          ? 2 + (_stableHash('$key:duration') % 8)
          : 1 + (_stableHash('$key:duration') % 5);
      final resolvedAt = DateTime(
        announcedAt.year,
        announcedAt.month + durationMonths,
        generatorVersion == 1 ? 1 : 3 + _stableHash('$key:resolved-day') % 25,
      );
      final kind = kindValues[_stableHash('$key:kind') % kindValues.length];
      final outcomeRoll = _unit('$key:outcome');
      final outcome = outcomeRoll < 0.34
          ? RealEstateWorldEventOutcome.completed
          : outcomeRoll < 0.68
          ? RealEstateWorldEventOutcome.delayed
          : RealEstateWorldEventOutcome.canceled;
      final major =
          _unit('$key:major') <
          (generatorVersion == 1
              ? 0.05
              : generatorVersion == 2
              ? 0.04
              : 0.025);
      final strength = generatorVersion == 1
          ? (major
                ? 0.50 + _unit('$key:strength') * 0.70
                : 0.05 + _unit('$key:strength') * 0.20)
          : generatorVersion == 2
          ? (major
                ? 0.32 + _unit('$key:strength') * 0.38
                : 0.045 + _unit('$key:strength') * 0.14)
          : (major
                ? 0.22 + _unit('$key:strength') * 0.26
                : 0.025 + _unit('$key:strength') * 0.075);
      final narrative = _eventNarrative(
        kind,
        asset.region,
        '$key:title',
        generatorVersion: generatorVersion,
      );
      final title = '${asset.name} ${listingIndex + 1}호 · ${narrative.title}';
      final isPotentialUpside = narrative.isPotentialUpside;
      final announcementImpact =
          _announcementImpact(kind).abs() *
          (isPotentialUpside ? 1 : -1) *
          strength;
      final resolvedImpact = _resolvedImpact(
        kind,
        outcome,
        potentialUpside: isPotentialUpside,
      );
      events.add(
        RealEstateWorldEvent._(
          id: '${asset.id}-listing-$listingIndex-${kind.name}-$index',
          assetId: asset.id,
          originDistrictId: realEstateDistrictFor(asset).id,
          generatorVersion: generatorVersion,
          kind: kind,
          announcedAt: announcedAt,
          resolvedAt: resolvedAt,
          outcome: outcome,
          announcementImpact: generatorVersion == 1
              ? _announcementImpact(kind) * strength
              : announcementImpact,
          resolvedImpact: resolvedImpact * strength,
          isPotentialUpside: isPotentialUpside,
          title: title,
          unresolvedDetail: narrative.unresolvedDetail,
          impactDurationDays:
              365 *
              (generatorVersion == 1
                  ? (major ? 4 : 1)
                  : generatorVersion == 2
                  ? (major ? 3 : 1)
                  : (major ? 2 : 1)),
        ),
      );
    }
    events.sort((a, b) => a.announcedAt.compareTo(b.announcedAt));
    return List<RealEstateWorldEvent>.unmodifiable(events);
  });
}

int realEstateGeneratedEventCount(
  String worldSeed, {
  int listingsPerAsset = 3,
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  var count = 0;
  for (final district in realEstateDistrictCatalog) {
    count += _realEstateRegionalEventsForDistrict(
      district,
      worldSeed,
      generatorVersion: generatorVersion,
    ).length;
  }
  for (final asset in realEstateMarketCatalog) {
    for (var index = 0; index < listingsPerAsset; index += 1) {
      count += _realEstateListingEventsFor(
        asset,
        worldSeed,
        index,
        generatorVersion: generatorVersion,
      ).length;
    }
  }
  return count;
}

List<RealEstateWorldEvent> realEstateVisibleWorldEventsAt(
  RealEstateMarketAsset asset,
  String worldSeed,
  DateTime date, {
  int generatorVersion = realEstateWorldGeneratorVersion,
}) => realEstateVisibleDistrictEventsAt(
  realEstateDistrictFor(asset),
  worldSeed,
  date,
  generatorVersion: generatorVersion,
);

List<RealEstateWorldEvent> realEstateVisibleDistrictEventsAt(
  RealEstateDistrict district,
  String worldSeed,
  DateTime date, {
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  final events = _realEstateRegionalEventsForDistrict(
    district,
    worldSeed,
    generatorVersion: generatorVersion,
  );
  if (events.every((event) => event.isVisibleAt(date))) return events;
  return List<RealEstateWorldEvent>.unmodifiable(
    events.where((event) => event.isVisibleAt(date)),
  );
}

List<RealEstateWorldEvent> realEstateVisibleNearbyWorldEventsAt(
  RealEstateMarketAsset asset,
  String worldSeed,
  DateTime date, {
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  final events = _realEstateNearbyWorldEventsFor(
    asset,
    worldSeed,
    generatorVersion: generatorVersion,
  );
  if (events.every((event) => event.isVisibleAt(date))) return events;
  return List<RealEstateWorldEvent>.unmodifiable(
    events.where((event) => event.isVisibleAt(date)),
  );
}

List<RealEstateWorldEvent> _realEstateRegionalEventsForDistrict(
  RealEstateDistrict district,
  String worldSeed, {
  int generatorVersion = realEstateWorldGeneratorVersion,
}) {
  final cache = _realEstateWorldCacheFor(
    worldSeed,
    generatorVersion: generatorVersion,
  );
  return cache.regionalEventsByDistrict.putIfAbsent(district.id, () {
    final events = <RealEstateWorldEvent>[];
    final kindValues = generatorVersion >= 3
        ? RealEstateWorldEventKind.values
        : _legacyRealEstateWorldEventKinds;
    final eventCount = generatorVersion == 1
        ? 26 * 3
        : generatorVersion == 2
        ? 26
        : 26 * 2;
    for (var index = 0; index < eventCount; index += 1) {
      final year = generatorVersion == 1
          ? 2001 + index ~/ 3
          : generatorVersion == 2
          ? 2001 + index
          : 2001 + index ~/ 2;
      if (year > 2026) continue;
      final key = '$worldSeed:${district.id}:regional:$index';
      final month = generatorVersion >= 3
          ? 1 + (index.isOdd ? 6 : 0) + (_stableHash('$key:month') % 6)
          : 1 + (_stableHash('$key:month') % 12);
      final announcedAt = generatorVersion == 1
          ? DateTime(year, month)
          : DateTime(year, month, 3 + _stableHash('$key:day') % 25);
      final durationMonths = generatorVersion == 1
          ? 9 + (_stableHash('$key:duration') % 31)
          : generatorVersion == 2
          ? 4 + (_stableHash('$key:duration') % 12)
          : 3 + (_stableHash('$key:duration') % 7);
      final resolvedAt = DateTime(
        announcedAt.year,
        announcedAt.month + durationMonths,
        generatorVersion == 1 ? 1 : 3 + _stableHash('$key:resolved-day') % 25,
      );
      final kind = kindValues[_stableHash('$key:kind') % kindValues.length];
      final outcomeRoll = _unit('$key:outcome');
      final outcome = outcomeRoll < 0.34
          ? RealEstateWorldEventOutcome.completed
          : outcomeRoll < 0.66
          ? RealEstateWorldEventOutcome.delayed
          : RealEstateWorldEventOutcome.canceled;
      final major =
          _unit('$key:major') <
          (generatorVersion == 1
              ? 0.10
              : generatorVersion == 2
              ? 0.06
              : 0.035);
      final strength = generatorVersion == 1
          ? (major
                ? 0.72 + _unit('$key:strength') * 0.58
                : 0.08 + _unit('$key:strength') * 0.27)
          : generatorVersion == 2
          ? (major
                ? 0.45 + _unit('$key:strength') * 0.30
                : 0.07 + _unit('$key:strength') * 0.13)
          : (major
                ? 0.30 + _unit('$key:strength') * 0.25
                : 0.035 + _unit('$key:strength') * 0.065);
      final narrative = _eventNarrative(
        kind,
        district.name,
        '$key:title',
        generatorVersion: generatorVersion,
      );
      final title = narrative.title;
      final isPotentialUpside = narrative.isPotentialUpside;
      final announcementImpact =
          _announcementImpact(kind).abs() *
          (isPotentialUpside ? 1 : -1) *
          strength;
      final resolvedImpact =
          _resolvedImpact(kind, outcome, potentialUpside: isPotentialUpside) *
          strength;
      events.add(
        RealEstateWorldEvent._(
          id: '${district.id}-${kind.name}-$index',
          assetId: 'district:${district.id}',
          originDistrictId: district.id,
          generatorVersion: generatorVersion,
          kind: kind,
          announcedAt: announcedAt,
          resolvedAt: resolvedAt,
          outcome: outcome,
          announcementImpact: generatorVersion == 1
              ? _announcementImpact(kind) * strength
              : announcementImpact,
          resolvedImpact: resolvedImpact,
          isPotentialUpside: isPotentialUpside,
          title: title,
          unresolvedDetail: narrative.unresolvedDetail,
          impactDurationDays:
              365 *
              (generatorVersion == 1
                  ? (major ? 5 : 2)
                  : generatorVersion == 2
                  ? (major ? 4 : 2)
                  : (major ? 3 : 2)),
        ),
      );
    }
    events.sort((a, b) => a.announcedAt.compareTo(b.announcedAt));
    return List<RealEstateWorldEvent>.unmodifiable(events);
  });
}

double _announcementImpact(RealEstateWorldEventKind kind) => switch (kind) {
  RealEstateWorldEventKind.transitPlan => 0.09,
  RealEstateWorldEventKind.redevelopment => 0.11,
  RealEstateWorldEventKind.schoolZone => 0.07,
  RealEstateWorldEventKind.supplyWave => -0.06,
  RealEstateWorldEventKind.employerMove => -0.07,
  RealEstateWorldEventKind.floodOrDefect => -0.09,
  RealEstateWorldEventKind.vacancyShock => -0.08,
  RealEstateWorldEventKind.interestRatePolicy => -0.065,
  RealEstateWorldEventKind.housingPolicy => -0.07,
  RealEstateWorldEventKind.tenantPolicy => -0.055,
  RealEstateWorldEventKind.publicFacility => 0.06,
  RealEstateWorldEventKind.commercialCycle => -0.07,
  RealEstateWorldEventKind.environmentalChange => -0.06,
  RealEstateWorldEventKind.safetyChange => -0.055,
  RealEstateWorldEventKind.demographicShift => -0.065,
};

double _resolvedImpact(
  RealEstateWorldEventKind kind,
  RealEstateWorldEventOutcome outcome, {
  bool? potentialUpside,
}) {
  if (potentialUpside ?? kind.isPotentialUpside) {
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

String _legacyEventTitle(
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
    _ => throw StateError('Legacy event kind is unsupported: $kind'),
  };
  return patterns[_stableHash(variantKey) % patterns.length].replaceAll(
    '{region}',
    region,
  );
}

bool _eventIsPotentialUpside(RealEstateWorldEventKind kind, String title) {
  if (!kind.isPotentialUpside) return false;
  if (title.contains('조합 분담금 갈등') ||
      title.contains('학교 통폐합 계획') ||
      title.contains('역사 출입구 위치 논쟁')) {
    return false;
  }
  return true;
}

String _legacyEventUnresolvedDetail(
  RealEstateWorldEventKind kind,
  String title,
) => switch (kind) {
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
  _ => '$title. 아직 조사와 협의가 진행 중이라 결과를 단정할 수 없습니다.',
};

class _RealEstateEventHeadlinePattern {
  const _RealEstateEventHeadlinePattern(
    this.text, {
    required this.isPotentialUpside,
  });

  final String text;
  final bool isPotentialUpside;
}

class _RealEstateEventNarrative {
  const _RealEstateEventNarrative({
    required this.title,
    required this.isPotentialUpside,
    required this.unresolvedDetail,
  });

  final String title;
  final bool isPotentialUpside;
  final String unresolvedDetail;
}

const _eventAnnouncementSources = <String>[
  '구청 검토안',
  '주민설명회 자료',
  '도시계획위원회 안건',
  '사업자 사전공고',
  '현장 실태조사',
  '예산심의 자료',
  '관계기관 협의체',
  '임대차 신고 동향',
  '지역 상인회 브리핑',
  '공공데이터 잠정치',
];

const _accessEventScopes = <String>[
  '역세권',
  '환승거점',
  '간선도로축',
  '외곽 생활권',
  '신도시 연결축',
  '상업지 연결구간',
  '산업단지 배후',
  '대학가 연결축',
  '수변 교통축',
  '광역 통근권',
];

const _residentialEventScopes = <String>[
  '노후 주거지',
  '대단지 밀집권',
  '재개발 경계부',
  '소형주택 밀집지',
  '신축 주거권',
  '학군 인접권',
  '전통시장 배후',
  '수변 주거권',
  '외곽 택지권',
  '도심 생활권',
];

const _commercialEventScopes = <String>[
  '중심 상권',
  '골목상권',
  '오피스 밀집지',
  '산업단지 배후',
  '대학가 상권',
  '전통시장권',
  '관광 동선',
  '역사 연결상가',
  '신도시 상업지',
  '업무지구 경계부',
];

const _buildingEventScopes = <String>[
  '노후 건축물',
  '저지대 주거지',
  '고층 주거동',
  '지하주차장 밀집지',
  '하천 인접권',
  '급경사지 배후',
  '소규모 공동주택',
  '대형 상업시설',
  '공사장 인접권',
  '재난 취약구역',
];

const _communityEventScopes = <String>[
  '초등 통학권',
  '생활SOC 권역',
  '공원 인접권',
  '의료 취약권',
  '야간 생활권',
  '1인 가구 밀집지',
  '고령 인구 밀집지',
  '신혼가구 유입권',
  '다문화 생활권',
  '생활 편의시설권',
];

List<String> _expandedEventScopes(RealEstateWorldEventKind kind) =>
    switch (kind) {
      RealEstateWorldEventKind.transitPlan => _accessEventScopes,
      RealEstateWorldEventKind.redevelopment ||
      RealEstateWorldEventKind.supplyWave ||
      RealEstateWorldEventKind.housingPolicy ||
      RealEstateWorldEventKind.tenantPolicy => _residentialEventScopes,
      RealEstateWorldEventKind.employerMove ||
      RealEstateWorldEventKind.vacancyShock ||
      RealEstateWorldEventKind.commercialCycle => _commercialEventScopes,
      RealEstateWorldEventKind.floodOrDefect => _buildingEventScopes,
      RealEstateWorldEventKind.schoolZone ||
      RealEstateWorldEventKind.publicFacility ||
      RealEstateWorldEventKind.environmentalChange ||
      RealEstateWorldEventKind.safetyChange ||
      RealEstateWorldEventKind.demographicShift => _communityEventScopes,
      RealEstateWorldEventKind.interestRatePolicy => _residentialEventScopes,
    };

List<_RealEstateEventHeadlinePattern> _expandedEventPatterns(
  RealEstateWorldEventKind kind,
) => switch (kind) {
  RealEstateWorldEventKind.transitPlan => const [
    _RealEstateEventHeadlinePattern('신규 역 후보지 발표', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('광역철도 사전타당성 검토', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('환승센터 기본계획 착수', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('급행버스 증편안 공개', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('보행 연결통로 신설 검토', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('도로 지하화 구상 발표', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('역사 출입구 위치 논쟁', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('노선 축소 대안 검토', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('환승센터 예산 삭감안', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('공사 지연 가능성 제기', isPotentialUpside: false),
  ],
  RealEstateWorldEventKind.redevelopment => const [
    _RealEstateEventHeadlinePattern('재건축 안전진단 추진', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('재개발 동의율 조사', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('리모델링 조합 설립', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('정비구역 지정 검토', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('용도지역 상향 논의', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('공공정비 후보지 추천', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('조합 분담금 갈등', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('정비구역 해제 민원', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('시공비 재협상 난항', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('주민 동의율 하락', isPotentialUpside: false),
  ],
  RealEstateWorldEventKind.supplyWave => const [
    _RealEstateEventHeadlinePattern('대단지 입주 물량 예고', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('오피스텔 공급 급증', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('공공주택 착공 발표', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('미분양 물량 증가', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('전세 매물 동시 출회', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('인접 택지 입주 시작', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('준공 후 미입주 증가', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('신규 공급 일정 연기', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('택지 지정 철회 검토', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('입주 물량 조기 소진', isPotentialUpside: true),
  ],
  RealEstateWorldEventKind.employerMove => const [
    _RealEstateEventHeadlinePattern('대기업 연구소 유치 협의', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('공공기관 이전 후보지 선정', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('산업단지 고용 확대 계획', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('대학병원 증원 계획', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('창업 거점 입주 수요 증가', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern(
      '주요 사업장 외곽 이전 검토',
      isPotentialUpside: false,
    ),
    _RealEstateEventHeadlinePattern('대기업 본사 이탈설', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('주요 공장 감원 발표', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('대형 상권 앵커 폐점', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('대학 캠퍼스 이전 검토', isPotentialUpside: false),
  ],
  RealEstateWorldEventKind.floodOrDefect => const [
    _RealEstateEventHeadlinePattern('집중호우 침수 제보', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('외벽 균열 안전점검', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('반복 누수 민원', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('주차장 화재 조사', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('층간소음 집단분쟁', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('토양·악취 민원', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('승강기 결함 조사', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('지반침하 정밀진단', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('배수시설 전면 개선안', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('노후 배관 교체 지원', isPotentialUpside: true),
  ],
  RealEstateWorldEventKind.schoolZone => const [
    _RealEstateEventHeadlinePattern('초등학교 신설 검토', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('학군 경계 개선안', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('학원가 확장 움직임', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('통학로 안전사업', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('과밀학급 해소안', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('돌봄교실 증설 계획', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('명문학교 이전 유치', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('학교 통폐합 계획', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('학군 경계 축소안', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('과밀학급 심화 조사', isPotentialUpside: false),
  ],
  RealEstateWorldEventKind.vacancyShock => const [
    _RealEstateEventHeadlinePattern('원룸 공실률 급등', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('임대료 연체 증가', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('전세보증 사고 확산', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('관리비 급등 민원', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('골목상권 매출 감소', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('상가 임차인 집단 퇴거', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('오피스 공실 장기화', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('임차 문의 회복세', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('상가 공실률 하락', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('전월세 거래량 반등', isPotentialUpside: true),
  ],
  RealEstateWorldEventKind.interestRatePolicy => const [
    _RealEstateEventHeadlinePattern('주택대출 금리 인하 검토', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('장기 고정금리 공급 확대', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('생애최초 금융지원 확대', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('대환대출 조건 완화', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('담보대출 가산금리 인상', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('대출심사 소득기준 강화', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('변동금리 상환부담 확대', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('중도상환 비용 인상안', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('다주택 대출한도 축소', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('전세대출 보증 축소 검토', isPotentialUpside: false),
  ],
  RealEstateWorldEventKind.housingPolicy => const [
    _RealEstateEventHeadlinePattern('취득세 감면안 논의', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('정비사업 규제 완화안', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('실수요 전매제한 완화', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('재산세 부담 완화 검토', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('다주택 취득세 중과안', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('거래허가구역 지정 검토', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('보유세 과표 상향안', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('단기매매 양도세 강화', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('임대사업 규정 강화', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('재건축 부담금 확대안', isPotentialUpside: false),
  ],
  RealEstateWorldEventKind.tenantPolicy => const [
    _RealEstateEventHeadlinePattern('전세보증 보호 확대', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('상가 갱신권 안정화', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('임대차 분쟁조정센터 신설', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('공실 리모델링 지원', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('임대료 인상 제한 강화', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('보증보험 가입비 상승', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('임대소득 신고 확대', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('상가 권리금 분쟁 증가', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('전세보증 심사 강화', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('단기임대 제한안', isPotentialUpside: false),
  ],
  RealEstateWorldEventKind.publicFacility => const [
    _RealEstateEventHeadlinePattern('종합병원 유치 검토', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('도서관 복합화 계획', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('공공체육센터 신설안', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('어린이 돌봄센터 확충', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('문화공연장 조성 검토', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('공영주차장 확충안', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('소방안전센터 신설', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('생활SOC 예산 삭감', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('공공병원 이전 검토', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('주민센터 통폐합안', isPotentialUpside: false),
  ],
  RealEstateWorldEventKind.commercialCycle => const [
    _RealEstateEventHeadlinePattern('대형 유통점 입점 협의', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('야간상권 활성화 사업', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('창업 점포 지원 확대', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('관광객 소비 회복세', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('상권 매출지수 반등', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('핵심 점포 폐업 예고', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('유동인구 감소 조사', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('배달상권 매출 급감', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('오피스 상권 공실 확대', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('전통시장 정비 지연', isPotentialUpside: false),
  ],
  RealEstateWorldEventKind.environmentalChange => const [
    _RealEstateEventHeadlinePattern('도시공원 확장 계획', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('하천 산책로 복원안', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('미세먼지 저감숲 조성', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('소음 차단시설 설치', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('쓰레기 집하장 이전 협의', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('산업 악취 민원 증가', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('도로 소음 측정치 상승', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('일조권 침해 분쟁', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('수질오염 조사 착수', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('열섬 취약구역 지정', isPotentialUpside: false),
  ],
  RealEstateWorldEventKind.safetyChange => const [
    _RealEstateEventHeadlinePattern('안심귀갓길 확대', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('지능형 방범망 설치', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('스쿨존 보행 개선', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('소방차 진입로 정비', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('침수 대피체계 보강', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('야간 범죄 신고 증가', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('빈집 안전사고 우려', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('불법주차 소방위험 조사', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('지하보도 안전등급 하락', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('공사장 낙하물 사고 조사', isPotentialUpside: false),
  ],
  RealEstateWorldEventKind.demographicShift => const [
    _RealEstateEventHeadlinePattern('신혼가구 전입 증가', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('청년 고용인구 유입', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('학령인구 반등 조짐', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('1인 가구 주거수요 증가', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('외국인 근로자 정착 확대', isPotentialUpside: true),
    _RealEstateEventHeadlinePattern('순전출 인구 증가', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('고령화 속도 상승', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('학령인구 급감 전망', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('가구소득 감소 조사', isPotentialUpside: false),
    _RealEstateEventHeadlinePattern('장기 미거주 주택 증가', isPotentialUpside: false),
  ],
};

String _expandedEventUncertainty(
  RealEstateWorldEventKind kind,
) => switch (kind) {
  RealEstateWorldEventKind.transitPlan =>
    '노선, 정차 위치, 예산과 착공 시점이 아직 확정되지 않았습니다.',
  RealEstateWorldEventKind.redevelopment => '주민 동의율, 분담금, 시공비와 인허가가 모두 변수입니다.',
  RealEstateWorldEventKind.supplyWave => '실제 준공·입주율과 전월세 소화 속도를 더 확인해야 합니다.',
  RealEstateWorldEventKind.employerMove =>
    '고용 인원, 이전 범위와 실제 근무 시작일이 아직 유동적입니다.',
  RealEstateWorldEventKind.floodOrDefect =>
    '피해 범위, 보수 책임과 보험 적용 여부를 조사하고 있습니다.',
  RealEstateWorldEventKind.schoolZone => '교육청 결정, 배정 기준과 통학구역 확정이 남아 있습니다.',
  RealEstateWorldEventKind.vacancyShock =>
    '계절 요인과 구조적 수요 감소를 구분할 추가 거래 자료가 필요합니다.',
  RealEstateWorldEventKind.interestRatePolicy =>
    '적용 금리, 소득 심사와 대상 차주 범위가 아직 결정되지 않았습니다.',
  RealEstateWorldEventKind.housingPolicy => '시행 시점, 대상 주택과 경과 규정이 확정되기 전입니다.',
  RealEstateWorldEventKind.tenantPolicy =>
    '계약 갱신, 보증 범위와 임대인 비용의 최종안이 남아 있습니다.',
  RealEstateWorldEventKind.publicFacility =>
    '부지, 예산, 운영 주체와 개관 일정이 모두 검토 단계입니다.',
  RealEstateWorldEventKind.commercialCycle =>
    '단기 매출 변화인지 지속 가능한 상권 회복·침체인지 더 지켜봐야 합니다.',
  RealEstateWorldEventKind.environmentalChange =>
    '측정 기간, 개선 비용과 인접 구역 확산 범위가 아직 불확실합니다.',
  RealEstateWorldEventKind.safetyChange => '신고 통계, 시설 개선 범위와 집행 시점을 확인하고 있습니다.',
  RealEstateWorldEventKind.demographicShift =>
    '전입 지속성, 가구 구성과 실제 주거 수요 전환 여부가 남아 있습니다.',
};

_RealEstateEventNarrative _eventNarrative(
  RealEstateWorldEventKind kind,
  String region,
  String variantKey, {
  required int generatorVersion,
}) {
  if (generatorVersion <= 2) {
    final title = _legacyEventTitle(kind, region, variantKey);
    final isPotentialUpside = generatorVersion == 1
        ? kind.isPotentialUpside
        : _eventIsPotentialUpside(kind, title);
    return _RealEstateEventNarrative(
      title: title,
      isPotentialUpside: isPotentialUpside,
      unresolvedDetail: _legacyEventUnresolvedDetail(kind, title),
    );
  }
  final patterns = _expandedEventPatterns(kind);
  final scopes = _expandedEventScopes(kind);
  final pattern =
      patterns[_stableHash('$variantKey:pattern') % patterns.length];
  final scope = scopes[_stableHash('$variantKey:scope') % scopes.length];
  final source =
      _eventAnnouncementSources[_stableHash('$variantKey:source') %
          _eventAnnouncementSources.length];
  final title = '$region $scope ${pattern.text} · $source';
  return _RealEstateEventNarrative(
    title: title,
    isPotentialUpside: pattern.isPotentialUpside,
    unresolvedDetail:
        '$title. ${_expandedEventUncertainty(kind)} '
        '발표 단계에서는 가격 방향이나 최종 결과를 단정할 수 없습니다.',
  );
}

int realEstateEventNarrativeCombinationCapacity() =>
    RealEstateWorldEventKind.values.fold<int>(
      0,
      (sum, kind) =>
          sum +
          _expandedEventPatterns(kind).length *
              _expandedEventScopes(kind).length *
              _eventAnnouncementSources.length,
    );

String _resolvedEventFocus(RealEstateWorldEventKind kind) => switch (kind) {
  RealEstateWorldEventKind.transitPlan => '통근시간과 역세권 접근성',
  RealEstateWorldEventKind.redevelopment => '사업성·분담금과 노후 주거지 가치',
  RealEstateWorldEventKind.supplyWave => '입주 물량과 전월세 경쟁',
  RealEstateWorldEventKind.employerMove => '배후 고용과 직주근접 수요',
  RealEstateWorldEventKind.floodOrDefect => '수리비·보험료와 건물 신뢰도',
  RealEstateWorldEventKind.schoolZone => '통학 편의와 학령가구 수요',
  RealEstateWorldEventKind.vacancyShock => '임차 문의와 공실 기간',
  RealEstateWorldEventKind.interestRatePolicy => '차입비용과 매수 여력',
  RealEstateWorldEventKind.housingPolicy => '거래비용·세금과 투자수요',
  RealEstateWorldEventKind.tenantPolicy => '임대인 비용과 계약 안정성',
  RealEstateWorldEventKind.publicFacility => '생활 편의와 상시 유동인구',
  RealEstateWorldEventKind.commercialCycle => '점포 매출과 상권 임차수요',
  RealEstateWorldEventKind.environmentalChange => '주거 쾌적성과 환경 비용',
  RealEstateWorldEventKind.safetyChange => '야간 보행과 생활 안전 인식',
  RealEstateWorldEventKind.demographicShift => '가구 구성과 중장기 주거수요',
};

const _resolvedEventEvidence = <String>[
  '실거래와 임대차 신고에는 수개월에 걸쳐 반영됩니다.',
  '인접 권역보다 해당 생활권의 반응이 더 크게 나타납니다.',
  '건물 유형과 역 접근성에 따라 체감 효과가 달라집니다.',
  '가격뿐 아니라 공실·수리·운영비 지표도 함께 확인해야 합니다.',
  '초기 기대감과 실제 현금흐름의 차이를 계속 관찰해야 합니다.',
];

String _resolvedEventDetail(RealEstateWorldEvent event) {
  final focus = _resolvedEventFocus(event.kind);
  final evidence =
      _resolvedEventEvidence[_stableHash('${event.id}:detail') %
          _resolvedEventEvidence.length];
  final result = switch (event._outcome) {
    RealEstateWorldEventOutcome.completed when event.isPotentialUpside =>
      '계획이 확정·집행되며 $focus 개선 기대가 실제 가치로 일부 전환됐습니다.',
    RealEstateWorldEventOutcome.completed => '우려가 현실화되며 $focus 측면의 부담이 커졌습니다.',
    RealEstateWorldEventOutcome.delayed when event.isPotentialUpside =>
      '일정이 장기 지연되어 $focus 개선 기대가 일부 되돌아갔습니다.',
    RealEstateWorldEventOutcome.delayed =>
      '악재의 속도는 늦어졌지만 $focus 불확실성은 남아 있습니다.',
    RealEstateWorldEventOutcome.canceled when event.isPotentialUpside =>
      '계획이 취소되어 $focus에 선반영됐던 기대가 조정됐습니다.',
    RealEstateWorldEventOutcome.canceled =>
      '우려했던 사안이 해소되어 $focus에 붙었던 할인 요인이 줄었습니다.',
  };
  return '$result $evidence';
}

int _stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

double _unit(String key) => (_stableHash(key) % 1000000) / 999999;

double _lerpDouble(double start, double end, double progress) =>
    start + (end - start) * progress;

double _smoothStep(double progress) {
  final value = progress.clamp(0.0, 1.0);
  return value * value * (3 - 2 * value);
}

double _combineDiminishingImpacts(
  Iterable<double> impacts, {
  required double minimum,
  required double maximum,
}) {
  var positiveRetention = 1.0;
  var negativeRetention = 1.0;
  for (final impact in impacts) {
    if (impact > 0) {
      positiveRetention *= 1 - impact.clamp(0.0, 0.55);
    } else if (impact < 0) {
      negativeRetention *= 1 - (-impact).clamp(0.0, 0.55);
    }
  }
  final positive = 1 - positiveRetention;
  final negative = 1 - negativeRetention;
  return (positive - negative).clamp(minimum, maximum);
}
