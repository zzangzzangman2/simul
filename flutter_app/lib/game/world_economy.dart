import 'dart:math' as math;

import 'market_clock.dart';
import 'market_data.dart';

/// Target number of recent public briefs. All still-active events remain
/// visible even if a dense period temporarily exceeds this number, so every
/// numeric effect has an inspectable cause.
const int worldEconomyRecentEventLimit = 12;

/// Public briefs are intentionally recent as well as bounded.
const int worldEconomyRecentEventWindowDays = 730;

enum WorldEconomyEventKind {
  creditShock,
  policySupport,
  pandemic,
  energyCost,
  demand,
  trade,
  technology,
  regulation,
  geopolitical,
  other,
}

extension WorldEconomyEventKindLabel on WorldEconomyEventKind {
  String get label => switch (this) {
    WorldEconomyEventKind.creditShock => '금융·신용',
    WorldEconomyEventKind.policySupport => '정책 대응',
    WorldEconomyEventKind.pandemic => '감염병',
    WorldEconomyEventKind.energyCost => '에너지·원가',
    WorldEconomyEventKind.demand => '경기·수요',
    WorldEconomyEventKind.trade => '교역·환율',
    WorldEconomyEventKind.technology => '기술 전환',
    WorldEconomyEventKind.regulation => '제도·규제',
    WorldEconomyEventKind.geopolitical => '지정학',
    WorldEconomyEventKind.other => '경제',
  };
}

/// One public cross-asset event, projected from the stock market's canonical
/// macro event object.
///
/// [id], [occurredOn], [title], and [sourceMarketImpact] are copied without
/// regeneration. [revealedOn] is the safe real-economy propagation day:
/// a stock event disclosed after the shared 08:00 day boundary becomes visible
/// to business and property systems on the next calendar day. Consequently the
/// three asset classes keep one event identity without letting a date-only
/// screen expose intraday stock news early.
class WorldEconomyEvent {
  const WorldEconomyEvent({
    required this.id,
    required this.kind,
    required this.occurredOn,
    required this.revealedOn,
    required this.title,
    required this.summary,
    required this.isActive,
    required this.sourceMarketImpact,
  });

  final String id;
  final WorldEconomyEventKind kind;
  final DateTime occurredOn;
  final DateTime revealedOn;
  final String title;
  final String summary;
  final bool isActive;
  final double sourceMarketImpact;
}

/// Additive changes applied to a business-district point.
///
/// Every field is a normalized additive delta. Business districts multiply
/// [vitality] by 100 only because vitality is stored as a 0-100 score; the
/// other district values are stored as multipliers.
class WorldEconomyBusinessImpact {
  const WorldEconomyBusinessImpact({
    this.demand = 0,
    this.rent = 0,
    this.competition = 0,
    this.wage = 0,
    this.vacancy = 0,
    this.risk = 0,
    this.vitality = 0,
  });

  static const zero = WorldEconomyBusinessImpact();

  final double demand;
  final double rent;
  final double competition;
  final double wage;
  final double vacancy;
  final double risk;
  final double vitality;

  bool get isNeutral =>
      demand == 0 &&
      rent == 0 &&
      competition == 0 &&
      wage == 0 &&
      vacancy == 0 &&
      risk == 0 &&
      vitality == 0;
}

/// Additive changes applied to a real-estate market point.
///
/// Every field is a normalized additive delta. Consumers that store risk or
/// liquidity on a 0-100 scale multiply those two fields by 100.
class WorldEconomyRealEstateImpact {
  const WorldEconomyRealEstateImpact({
    this.price = 0,
    this.rent = 0,
    this.vacancy = 0,
    this.risk = 0,
    this.repairCost = 0,
    this.liquidity = 0,
  });

  static const zero = WorldEconomyRealEstateImpact();

  final double price;
  final double rent;
  final double vacancy;
  final double risk;
  final double repairCost;
  final double liquidity;

  bool get isNeutral =>
      price == 0 &&
      rent == 0 &&
      vacancy == 0 &&
      risk == 0 &&
      repairCost == 0 &&
      liquidity == 0;
}

class WorldEconomySnapshot {
  const WorldEconomySnapshot({
    required this.asOf,
    required this.regionKeys,
    required this.businessImpact,
    required this.realEstateImpact,
    required this.revealedEvents,
  });

  final DateTime asOf;
  final List<String> regionKeys;
  final WorldEconomyBusinessImpact businessImpact;
  final WorldEconomyRealEstateImpact realEstateImpact;
  final List<WorldEconomyEvent> revealedEvents;
}

/// The single bridge between the 14 real-estate districts and the 32-district
/// business simulation.
const Map<String, String> worldEconomyBusinessDistrictByRealEstateDistrict =
    <String, String>{
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

String? worldEconomyBusinessDistrictIdForRealEstateDistrict(String id) =>
    worldEconomyBusinessDistrictByRealEstateDistrict[id.trim().toLowerCase()];

const Map<String, String> _businessDistrictByNormalizedRegion =
    <String, String>{
      '의정부': 'gyeonggi_uijeongbu_station',
      '경기의정부': 'gyeonggi_uijeongbu_station',
      '고양': 'gyeonggi_ilsan_lafesta',
      '경기고양': 'gyeonggi_ilsan_lafesta',
      '일산': 'gyeonggi_ilsan_lafesta',
      '노원': 'seoul_nowon_station',
      '서울노원': 'seoul_nowon_station',
      '종로': 'seoul_jongno',
      '서울종로': 'seoul_jongno',
      '성동': 'seoul_seongsu',
      '서울성동': 'seoul_seongsu',
      '성수': 'seoul_seongsu',
      '용산': 'seoul_yongsan_station',
      '서울용산': 'seoul_yongsan_station',
      '부천': 'gyeonggi_bucheon_sangdong',
      '경기부천': 'gyeonggi_bucheon_sangdong',
      '구로': 'seoul_guro_digital',
      '서울구로': 'seoul_guro_digital',
      '서초': 'seoul_gangnam_station',
      '서울서초': 'seoul_gangnam_station',
      '강남': 'seoul_gangnam_station',
      '서울강남': 'seoul_gangnam_station',
      '송파': 'seoul_jamsil',
      '서울송파': 'seoul_jamsil',
      '잠실': 'seoul_jamsil',
      '과천': 'gyeonggi_gwacheon_central',
      '경기과천': 'gyeonggi_gwacheon_central',
      '성남': 'gyeonggi_pangyo',
      '경기성남': 'gyeonggi_pangyo',
      '분당': 'gyeonggi_bundang_seohyeon',
      '경기분당': 'gyeonggi_bundang_seohyeon',
      '수원': 'gyeonggi_suwon_station',
      '경기수원': 'gyeonggi_suwon_station',
    };

/// Name-based fallback for legacy property data that has no district ID.
String? worldEconomyBusinessDistrictIdForRealEstateRegion(
  String region, {
  String province = '',
}) {
  final directId = worldEconomyBusinessDistrictIdForRealEstateDistrict(region);
  if (directId != null) return directId;

  final normalizedRegion = _normalizeRegionName(region);
  if (normalizedRegion.isEmpty) return null;
  final normalizedProvince = _normalizeRegionName(province);
  if (normalizedProvince.isNotEmpty) {
    final combined =
        _businessDistrictByNormalizedRegion['$normalizedProvince$normalizedRegion'];
    if (combined != null) return combined;
  }
  return _businessDistrictByNormalizedRegion[normalizedRegion];
}

/// Builds the dated, deterministic economy view shared by business and
/// real-estate systems.
///
/// This function never hashes [worldSeed]. The stock exporter has already
/// applied the seed to each canonical event's impact; hashing again here would
/// make the three systems disagree about the strength of one event.
WorldEconomySnapshot worldEconomySnapshot({
  required String worldSeed,
  required DateTime asOf,
  Iterable<String> regionKeys = const <String>[],
}) {
  final asOfDay = DateTime(asOf.year, asOf.month, asOf.day);
  final sortedRegionKeys =
      regionKeys
          .map(_normalizeSensitivityKey)
          .where((key) => key.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  final normalizedRegionKeys = List<String>.unmodifiable(sortedRegionKeys);
  final sources = fictionalSharedEconomyEventsThrough(worldSeed, asOfDay);

  var demand = 0.0;
  var businessRent = 0.0;
  var competition = 0.0;
  var wage = 0.0;
  var businessVacancy = 0.0;
  var businessRisk = 0.0;
  var vitality = 0.0;

  var propertyPrice = 0.0;
  var propertyRent = 0.0;
  var propertyVacancy = 0.0;
  var propertyRisk = 0.0;
  var repairCost = 0.0;
  var liquidity = 0.0;

  final publicEvents = <WorldEconomyEvent>[];
  for (final source in sources) {
    final occurredOn = _eventDay(source);
    if (occurredOn == null || occurredOn.isAfter(asOfDay)) continue;
    final revealedOn = _realEconomyRevealDay(source, occurredOn);
    final ageDays = asOfDay.difference(revealedOn).inDays;
    if (ageDays < 0) continue;

    final kind = _eventKind(source);
    final lifetimeDays = _activeDaysFor(kind);
    final isActive = ageDays < lifetimeDays;
    if (ageDays <= worldEconomyRecentEventWindowDays) {
      publicEvents.add(
        WorldEconomyEvent(
          id: source.id,
          kind: kind,
          occurredOn: occurredOn,
          revealedOn: revealedOn,
          title: source.title,
          summary: source.body,
          isActive: isActive,
          sourceMarketImpact: source.impactPct,
        ),
      );
    }

    if (!isActive) continue;
    final decay = _activeDecay(ageDays: ageDays, lifetimeDays: lifetimeDays);
    final businessScale = _businessRegionSensitivity(
      kind,
      normalizedRegionKeys,
    );
    final realEstateScale = _realEstateRegionSensitivity(
      kind,
      normalizedRegionKeys,
    );
    final businessContribution = _businessProjection(
      kind,
      source.impactPct * decay * businessScale,
    );
    demand += businessContribution.demand;
    businessRent += businessContribution.rent;
    competition += businessContribution.competition;
    wage += businessContribution.wage;
    businessVacancy += businessContribution.vacancy;
    businessRisk += businessContribution.risk;
    vitality += businessContribution.vitality;

    final realEstateContribution = _realEstateProjection(
      kind,
      source.impactPct * decay * realEstateScale,
    );
    propertyPrice += realEstateContribution.price;
    propertyRent += realEstateContribution.rent;
    propertyVacancy += realEstateContribution.vacancy;
    propertyRisk += realEstateContribution.risk;
    repairCost += realEstateContribution.repairCost;
    liquidity += realEstateContribution.liquidity;
  }

  publicEvents.sort((left, right) {
    final byDate = right.revealedOn.compareTo(left.revealedOn);
    if (byDate != 0) return byDate;
    return left.id.compareTo(right.id);
  });
  final activeEvents = publicEvents
      .where((event) => event.isActive)
      .toList(growable: false);
  final inactiveSlots = math.max(
    0,
    worldEconomyRecentEventLimit - activeEvents.length,
  );
  final boundedEvents =
      <WorldEconomyEvent>[
        ...activeEvents,
        ...publicEvents.where((event) => !event.isActive).take(inactiveSlots),
      ]..sort((left, right) {
        final byDate = right.revealedOn.compareTo(left.revealedOn);
        return byDate != 0 ? byDate : left.id.compareTo(right.id);
      });

  return WorldEconomySnapshot(
    asOf: asOfDay,
    regionKeys: normalizedRegionKeys,
    businessImpact: WorldEconomyBusinessImpact(
      demand: demand.clamp(-0.35, 0.35),
      rent: businessRent.clamp(-0.20, 0.24),
      competition: competition.clamp(-0.18, 0.18),
      wage: wage.clamp(-0.14, 0.16),
      vacancy: businessVacancy.clamp(-0.12, 0.15),
      risk: businessRisk.clamp(-0.25, 0.30),
      vitality: vitality.clamp(-0.30, 0.30),
    ),
    realEstateImpact: WorldEconomyRealEstateImpact(
      price: propertyPrice.clamp(-0.30, 0.32),
      rent: propertyRent.clamp(-0.18, 0.20),
      vacancy: propertyVacancy.clamp(-0.10, 0.14),
      risk: propertyRisk.clamp(-0.25, 0.30),
      repairCost: repairCost.clamp(-0.15, 0.25),
      liquidity: liquidity.clamp(-0.30, 0.30),
    ),
    revealedEvents: List<WorldEconomyEvent>.unmodifiable(boundedEvents),
  );
}

DateTime? _eventDay(FictionalMarketEvent event) {
  final parsed = DateTime.tryParse(event.date);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime _realEconomyRevealDay(
  FictionalMarketEvent event,
  DateTime occurredOn,
) => event.revealMinute <= marketDayStartMinute
    ? occurredOn
    : occurredOn.add(const Duration(days: 1));

WorldEconomyEventKind _eventKind(FictionalMarketEvent event) {
  final identity = '${event.id} ${event.eyebrow} ${event.title}'.toLowerCase();
  final text = '${event.id} ${event.eyebrow} ${event.title} ${event.body}'
      .toLowerCase();
  if (_containsAny(text, const [
    '감염병',
    '팬데믹',
    'pandemic',
    'sars',
    'h1n1',
    '코로나',
    '보건비상',
  ])) {
    return WorldEconomyEventKind.pandemic;
  }
  // Explicit source identities take priority over generic words such as
  // "liquidity", "financial institutions", or "exchange rates" in body
  // copy. These IDs/categories are stable parts of the stock event corpus.
  if (_containsAny(identity, const [
    'border_tension',
    'military_conflict',
    'political_crisis',
    'geopolitical_test',
    'nuclear_test',
    '한반도 위험',
    '국제 충격',
    '지정학',
    '국지 충돌',
    '국경 긴장',
  ])) {
    return WorldEconomyEventKind.geopolitical;
  }
  if (_containsAny(identity, const [
    'rate_cut',
    'rate_hike',
    'asset_purchase',
    'stimulus',
    '정책 대응',
    '통화정책',
    '금리 인하',
    '금리 인상',
    '자산매입',
    '긴축',
  ])) {
    return WorldEconomyEventKind.policySupport;
  }
  if (_containsAny(identity, const [
    'currency_swap',
    'trade_',
    '교역',
    '무역',
    '외환 안정',
    '통화교환',
    '관세',
  ])) {
    return WorldEconomyEventKind.trade;
  }
  if (_containsAny(text, const [
    '금융',
    '신용',
    '은행',
    'bank',
    'credit',
    'liquidity',
    '유동성',
    '회계',
    '채권',
  ])) {
    return WorldEconomyEventKind.creditShock;
  }
  if (_containsAny(text, const [
    '정책 대응',
    '통화정책',
    '금리',
    '자산매입',
    '부양',
    '긴축',
    'rate',
    'stimulus',
  ])) {
    return WorldEconomyEventKind.policySupport;
  }
  if (_containsAny(text, const [
    '원유',
    '유가',
    '에너지',
    '원자재',
    'oil',
    'energy',
    '연료',
  ])) {
    return WorldEconomyEventKind.energyCost;
  }
  if (_containsAny(text, const [
    '교역',
    '무역',
    '수출',
    '수입',
    '환율',
    '외환',
    '관세',
    'trade',
    'currency',
    '공급망',
  ])) {
    return WorldEconomyEventKind.trade;
  }
  if (_containsAny(text, const [
    '기술',
    '인터넷',
    '반도체',
    '디지털',
    'technology',
    'software',
    '플랫폼',
  ])) {
    return WorldEconomyEventKind.technology;
  }
  if (_containsAny(text, const [
    '전쟁',
    '군사',
    '지정학',
    '국제 충격',
    'geopolitical',
    '안보',
  ])) {
    return WorldEconomyEventKind.geopolitical;
  }
  if (_containsAny(text, const [
    '규제',
    '제도',
    '개혁',
    '환경 정책',
    '공시책임',
    'regulation',
    'reform',
  ])) {
    return WorldEconomyEventKind.regulation;
  }
  if (_containsAny(text, const [
    '경기',
    '소비',
    '수요',
    '고용',
    '침체',
    '회복',
    'recession',
    'demand',
  ])) {
    return WorldEconomyEventKind.demand;
  }
  return WorldEconomyEventKind.other;
}

bool _containsAny(String text, List<String> needles) =>
    needles.any(text.contains);

int _activeDaysFor(WorldEconomyEventKind kind) => switch (kind) {
  WorldEconomyEventKind.creditShock => 240,
  WorldEconomyEventKind.policySupport => 150,
  WorldEconomyEventKind.pandemic => 420,
  WorldEconomyEventKind.energyCost => 150,
  WorldEconomyEventKind.demand => 180,
  WorldEconomyEventKind.trade => 210,
  WorldEconomyEventKind.technology => 300,
  WorldEconomyEventKind.regulation => 300,
  WorldEconomyEventKind.geopolitical => 100,
  WorldEconomyEventKind.other => 120,
};

double _activeDecay({required int ageDays, required int lifetimeDays}) {
  if (ageDays < 0 || ageDays >= lifetimeDays) return 0;
  final remaining = 1 - ageDays / lifetimeDays;
  return math.pow(remaining, 1.35).toDouble();
}

WorldEconomyBusinessImpact _businessProjection(
  WorldEconomyEventKind kind,
  double impact,
) {
  final coefficients = switch (kind) {
    WorldEconomyEventKind.creditShock => const [
      1.00,
      0.42,
      0.28,
      0.12,
      -0.24,
      -0.60,
      0.65,
    ],
    WorldEconomyEventKind.policySupport => const [
      0.65,
      0.55,
      0.18,
      0.08,
      -0.18,
      -0.45,
      0.52,
    ],
    WorldEconomyEventKind.pandemic => const [
      1.10,
      0.40,
      0.30,
      0.10,
      -0.34,
      -0.65,
      0.75,
    ],
    WorldEconomyEventKind.energyCost => const [
      0.42,
      0.08,
      0.12,
      -0.10,
      -0.08,
      -0.30,
      0.32,
    ],
    WorldEconomyEventKind.demand => const [
      1.00,
      0.48,
      0.24,
      0.15,
      -0.22,
      -0.42,
      0.60,
    ],
    WorldEconomyEventKind.trade => const [
      0.72,
      0.28,
      0.20,
      0.12,
      -0.15,
      -0.38,
      0.45,
    ],
    WorldEconomyEventKind.technology => const [
      0.45,
      0.22,
      0.28,
      0.12,
      -0.10,
      -0.28,
      0.36,
    ],
    WorldEconomyEventKind.regulation => const [
      0.30,
      0.18,
      0.12,
      0.12,
      -0.08,
      -0.25,
      0.24,
    ],
    WorldEconomyEventKind.geopolitical => const [
      0.55,
      0.18,
      0.16,
      0.10,
      -0.12,
      -0.48,
      0.42,
    ],
    WorldEconomyEventKind.other => const [
      0.55,
      0.25,
      0.16,
      0.10,
      -0.12,
      -0.32,
      0.38,
    ],
  };
  return WorldEconomyBusinessImpact(
    demand: impact * coefficients[0],
    rent: impact * coefficients[1],
    competition: impact * coefficients[2],
    wage: impact * coefficients[3],
    vacancy: impact * coefficients[4],
    risk: impact * coefficients[5],
    vitality: impact * coefficients[6],
  );
}

WorldEconomyRealEstateImpact _realEstateProjection(
  WorldEconomyEventKind kind,
  double impact,
) {
  final coefficients = switch (kind) {
    WorldEconomyEventKind.creditShock => const [
      0.72,
      0.25,
      -0.18,
      -0.60,
      -0.08,
      0.70,
    ],
    WorldEconomyEventKind.policySupport => const [
      0.55,
      0.25,
      -0.12,
      -0.40,
      0.02,
      0.55,
    ],
    WorldEconomyEventKind.pandemic => const [
      0.28,
      0.35,
      -0.25,
      -0.55,
      -0.15,
      0.65,
    ],
    WorldEconomyEventKind.energyCost => const [
      0.18,
      0.12,
      -0.08,
      -0.28,
      -0.75,
      0.25,
    ],
    WorldEconomyEventKind.demand => const [
      0.48,
      0.34,
      -0.18,
      -0.38,
      0.15,
      0.50,
    ],
    WorldEconomyEventKind.trade => const [
      0.35,
      0.20,
      -0.10,
      -0.32,
      -0.20,
      0.38,
    ],
    WorldEconomyEventKind.technology => const [
      0.28,
      0.15,
      -0.07,
      -0.20,
      0.10,
      0.30,
    ],
    WorldEconomyEventKind.regulation => const [
      0.35,
      0.18,
      -0.08,
      -0.25,
      0.22,
      0.28,
    ],
    WorldEconomyEventKind.geopolitical => const [
      0.22,
      0.12,
      -0.10,
      -0.45,
      -0.35,
      0.40,
    ],
    WorldEconomyEventKind.other => const [0.30, 0.18, -0.10, -0.30, 0.05, 0.35],
  };
  return WorldEconomyRealEstateImpact(
    price: impact * coefficients[0],
    rent: impact * coefficients[1],
    vacancy: impact * coefficients[2],
    risk: impact * coefficients[3],
    repairCost: impact * coefficients[4],
    liquidity: impact * coefficients[5],
  );
}

double _businessRegionSensitivity(
  WorldEconomyEventKind kind,
  List<String> keys,
) {
  if (keys.isEmpty) return 1;
  var sensitivity = 1.0;
  if (_hasRegionKey(keys, const [
    'tourism',
    'nightlife',
    'retail',
    'international',
    'island',
    '관광',
  ])) {
    sensitivity += switch (kind) {
      WorldEconomyEventKind.pandemic => 0.24,
      WorldEconomyEventKind.demand => 0.12,
      WorldEconomyEventKind.geopolitical => 0.10,
      _ => 0,
    };
  }
  if (_hasRegionKey(keys, const [
    'office',
    'industrial',
    'tech',
    'capital',
    '업무',
  ])) {
    sensitivity += switch (kind) {
      WorldEconomyEventKind.creditShock => 0.10,
      WorldEconomyEventKind.trade => 0.08,
      WorldEconomyEventKind.technology => 0.12,
      _ => 0,
    };
  }
  if (_hasRegionKey(keys, const [
    'residential',
    'newtown',
    'education',
    '주거',
    '신도시',
  ])) {
    sensitivity += switch (kind) {
      WorldEconomyEventKind.creditShock => 0.07,
      WorldEconomyEventKind.policySupport => 0.08,
      _ => 0,
    };
  }
  if (_hasRegionKey(keys, const [
    'olddowntown',
    'traditional',
    'declining',
    '구도심',
  ])) {
    sensitivity += switch (kind) {
      WorldEconomyEventKind.demand => 0.08,
      WorldEconomyEventKind.pandemic => 0.08,
      _ => 0,
    };
  }
  return sensitivity.clamp(0.78, 1.30);
}

double _realEstateRegionSensitivity(
  WorldEconomyEventKind kind,
  List<String> keys,
) {
  if (keys.isEmpty) return 1;
  var sensitivity = 1.0;
  if (_hasRegionKey(keys, const [
    'gangnam',
    'seoulgangnam',
    'seoulseocho',
    'capital',
    'office',
    '강남',
    '서초',
  ])) {
    sensitivity += switch (kind) {
      WorldEconomyEventKind.creditShock => 0.10,
      WorldEconomyEventKind.policySupport => 0.08,
      _ => 0.03,
    };
  }
  if (_hasRegionKey(keys, const [
    'newtown',
    'residential',
    'gyeonggi',
    '경기',
    '신도시',
  ])) {
    sensitivity += switch (kind) {
      WorldEconomyEventKind.creditShock => 0.12,
      WorldEconomyEventKind.policySupport => 0.10,
      WorldEconomyEventKind.demand => 0.06,
      _ => 0,
    };
  }
  if (_hasRegionKey(keys, const [
    'tourism',
    'international',
    'waterfront',
    'island',
    '관광',
  ])) {
    sensitivity += switch (kind) {
      WorldEconomyEventKind.pandemic => 0.18,
      WorldEconomyEventKind.geopolitical => 0.10,
      _ => 0,
    };
  }
  return sensitivity.clamp(0.80, 1.30);
}

bool _hasRegionKey(List<String> keys, List<String> needles) {
  for (final key in keys) {
    for (final needle in needles) {
      if (key.contains(_normalizeSensitivityKey(needle))) return true;
    }
  }
  return false;
}

String _normalizeSensitivityKey(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'[\s·,._\-()]'), '');

String _normalizeRegionName(String value) => _normalizeSensitivityKey(value)
    .replaceAll('특별자치도', '')
    .replaceAll('특별자치시', '')
    .replaceAll('특별시', '')
    .replaceAll('광역시', '')
    .replaceAll('경기도', '경기')
    .replaceAll(RegExp(r'(시|구)$'), '');
