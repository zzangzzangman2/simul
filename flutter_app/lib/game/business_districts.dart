import 'dart:math' as math;

import 'business_state.dart';
import 'stable_hash.dart';
import 'world_economy.dart';

const businessDistrictGeneratorVersion = 2;

int businessDistrictVersionForBusinessWorld(int businessGeneratorVersion) =>
    businessGeneratorVersion >= 3 ? businessDistrictGeneratorVersion : 1;

const businessDistrictDemandMultiplierMin = 0.72;
const businessDistrictDemandMultiplierMax = 1.32;
const businessDistrictRentMultiplierMin = 0.70;
const businessDistrictRentMultiplierMax = 1.38;
const businessDistrictCompetitionMultiplierMin = 0.78;
const businessDistrictCompetitionMultiplierMax = 1.28;
const businessDistrictWageMultiplierMin = 0.86;
const businessDistrictWageMultiplierMax = 1.20;
const businessDistrictVacancyMultiplierMin = 0.68;
const businessDistrictVacancyMultiplierMax = 1.45;
const businessDistrictRiskMultiplierMin = 0.72;
const businessDistrictRiskMultiplierMax = 1.50;
const businessDistrictIndustryFitMin = 0.72;
const businessDistrictIndustryFitMax = 1.32;

final DateTime businessDistrictCampaignStart = DateTime.utc(2000);
final DateTime businessDistrictCampaignEnd = DateTime.utc(2026, 12, 31);

enum BusinessDistrictPhase {
  emerging,
  booming,
  mature,
  cooling,
  declining,
  distressed,
  regenerating,
}

extension BusinessDistrictPhaseLabel on BusinessDistrictPhase {
  String get label => switch (this) {
    BusinessDistrictPhase.emerging => '태동',
    BusinessDistrictPhase.booming => '급성장',
    BusinessDistrictPhase.mature => '성숙',
    BusinessDistrictPhase.cooling => '과열 진정',
    BusinessDistrictPhase.declining => '쇠퇴',
    BusinessDistrictPhase.distressed => '위기',
    BusinessDistrictPhase.regenerating => '재생',
  };

  String get description => switch (this) {
    BusinessDistrictPhase.emerging => '수요가 붙기 시작했지만 기반과 단골은 아직 얕습니다.',
    BusinessDistrictPhase.booming => '유동과 매출 기회가 빠르게 늘고 임대료·경쟁도 뒤따릅니다.',
    BusinessDistrictPhase.mature => '수요와 비용이 모두 높은 수준에서 안정된 상권입니다.',
    BusinessDistrictPhase.cooling => '호황의 열기가 식으며 비용 부담이 먼저 드러납니다.',
    BusinessDistrictPhase.declining => '유동 감소와 공실 증가가 이어지는 하강 국면입니다.',
    BusinessDistrictPhase.distressed => '공실·위험이 높아 생존 자체가 중요한 위기 국면입니다.',
    BusinessDistrictPhase.regenerating => '재개발·문화 유입 등으로 회복 중이지만 변동성이 큽니다.',
  };
}

enum BusinessDistrictEventKind {
  nationalShock,
  transitOpening,
  newTownOccupancy,
  officeCluster,
  universityShift,
  onlineConsumption,
  rentSurge,
  redevelopment,
  gentrification,
  regeneration,
  tourism,
  industrialTransition,
  populationShift,
}

extension BusinessDistrictEventKindLabel on BusinessDistrictEventKind {
  String get label => switch (this) {
    BusinessDistrictEventKind.nationalShock => '전국 경기 충격',
    BusinessDistrictEventKind.transitOpening => '교통 개통',
    BusinessDistrictEventKind.newTownOccupancy => '신도시 입주',
    BusinessDistrictEventKind.officeCluster => '업무지구 형성',
    BusinessDistrictEventKind.universityShift => '대학가 변화',
    BusinessDistrictEventKind.onlineConsumption => '온라인 소비 전환',
    BusinessDistrictEventKind.rentSurge => '임대료 급등',
    BusinessDistrictEventKind.redevelopment => '재개발',
    BusinessDistrictEventKind.gentrification => '젠트리피케이션',
    BusinessDistrictEventKind.regeneration => '상권 재생',
    BusinessDistrictEventKind.tourism => '관광 수요 변화',
    BusinessDistrictEventKind.industrialTransition => '산업 전환',
    BusinessDistrictEventKind.populationShift => '인구 이동',
  };
}

class BusinessDistrictLifecycleAnchor {
  const BusinessDistrictLifecycleAnchor({
    required this.year,
    required this.month,
    required this.day,
    required this.phase,
    required this.vitalityScore,
    required this.demandMultiplier,
    required this.rentMultiplier,
    required this.competitionMultiplier,
    required this.wageMultiplier,
    required this.vacancyMultiplier,
    required this.riskMultiplier,
    required this.cause,
  });

  final int year;
  final int month;
  final int day;
  final BusinessDistrictPhase phase;
  final double vitalityScore;
  final double demandMultiplier;
  final double rentMultiplier;
  final double competitionMultiplier;
  final double wageMultiplier;
  final double vacancyMultiplier;
  final double riskMultiplier;
  final String cause;

  DateTime get date => DateTime.utc(year, month, day);
}

class BusinessDistrictProfile {
  const BusinessDistrictProfile({
    required this.id,
    required this.city,
    required this.name,
    required this.summary,
    required this.regionTags,
    required this.industryAffinities,
    required this.baseMonthlyRentPerPyeong,
    required this.baseDailyFootTraffic,
    required this.baseCompetitionIndex,
    required this.baseMonthlyWage,
    required this.baseVacancyRate,
    required this.baseRiskIndex,
    required List<BusinessDistrictLifecycleAnchor> lifecycleAnchors,
    // ignore: prefer_initializing_formals
  }) : _lifecycleAnchors = lifecycleAnchors;

  final String id;
  final String city;
  final String name;
  final String summary;
  final List<String> regionTags;
  final Map<BusinessIndustry, double> industryAffinities;
  final int baseMonthlyRentPerPyeong;
  final int baseDailyFootTraffic;
  final double baseCompetitionIndex;
  final int baseMonthlyWage;
  final double baseVacancyRate;
  final double baseRiskIndex;
  final List<BusinessDistrictLifecycleAnchor> _lifecycleAnchors;

  double industryAffinityFor(BusinessIndustry industry) =>
      (industryAffinities[industry] ?? 1.0).clamp(
        businessDistrictIndustryFitMin,
        businessDistrictIndustryFitMax,
      );

  List<BusinessDistrictLifecycleAnchor> revealedLifecycleAnchors(
    DateTime asOf,
  ) {
    final safeDate = _dateOnlyUtc(asOf);
    return List<BusinessDistrictLifecycleAnchor>.unmodifiable(
      _lifecycleAnchors.where((anchor) => !anchor.date.isAfter(safeDate)),
    );
  }
}

class BusinessDistrictChange {
  const BusinessDistrictChange({
    required this.vitalityPoints,
    required this.demandPercent,
    required this.rentPercent,
    required this.competitionPercent,
    required this.wagePercent,
    required this.vacancyPercent,
    required this.riskPercent,
  });

  const BusinessDistrictChange.zero()
    : vitalityPoints = 0,
      demandPercent = 0,
      rentPercent = 0,
      competitionPercent = 0,
      wagePercent = 0,
      vacancyPercent = 0,
      riskPercent = 0;

  final double vitalityPoints;
  final double demandPercent;
  final double rentPercent;
  final double competitionPercent;
  final double wagePercent;
  final double vacancyPercent;
  final double riskPercent;
}

class BusinessDistrictRevealedEvent {
  const BusinessDistrictRevealedEvent({
    required this.id,
    required this.kind,
    required this.occurredOn,
    required this.revealedOn,
    required this.headline,
    required this.summary,
    required this.isActive,
  });

  final String id;
  final BusinessDistrictEventKind kind;
  final DateTime occurredOn;
  final DateTime revealedOn;
  final String headline;
  final String summary;
  final bool isActive;
}

class BusinessDistrictSnapshot {
  const BusinessDistrictSnapshot({
    required this.generatorVersion,
    required this.districtId,
    required this.city,
    required this.name,
    required this.asOf,
    required this.demandMultiplier,
    required this.rentMultiplier,
    required this.competitionMultiplier,
    required this.wageMultiplier,
    required this.vacancyMultiplier,
    required this.riskMultiplier,
    required this.vitalityScore,
    required this.monthOverMonth,
    required this.yearOverYear,
    required this.phase,
    required this.revealedEvents,
    required this.currentSignals,
  });

  final int generatorVersion;
  final String districtId;
  final String city;
  final String name;
  final DateTime asOf;
  final double demandMultiplier;
  final double rentMultiplier;
  final double competitionMultiplier;
  final double wageMultiplier;
  final double vacancyMultiplier;
  final double riskMultiplier;
  final double vitalityScore;
  final BusinessDistrictChange monthOverMonth;
  final BusinessDistrictChange yearOverYear;
  final BusinessDistrictPhase phase;
  final List<BusinessDistrictRevealedEvent> revealedEvents;
  final List<String> currentSignals;
}

class BusinessDistrictRankingEntry {
  const BusinessDistrictRankingEntry({
    required this.rank,
    required this.profile,
    required this.snapshot,
    required this.industryFit,
    required this.opportunityScore,
  });

  final int rank;
  final BusinessDistrictProfile profile;
  final BusinessDistrictSnapshot snapshot;
  final double industryFit;
  final double opportunityScore;
}

double businessDistrictIndustryFit(
  BusinessDistrictProfile profile,
  BusinessIndustry industry,
) => profile.industryAffinityFor(industry);

BusinessDistrictProfile? businessDistrictProfileById(String id) {
  for (final profile in businessDistrictCatalog) {
    if (profile.id == id) return profile;
  }
  return null;
}

List<BusinessDistrictProfile> businessDistrictProfilesForCity(String city) {
  final normalized = city.trim().toLowerCase();
  return List<BusinessDistrictProfile>.unmodifiable(
    businessDistrictCatalog.where(
      (profile) => profile.city.toLowerCase() == normalized,
    ),
  );
}

BusinessDistrictSnapshot businessDistrictSnapshot({
  required String districtId,
  required DateTime asOf,
  required String worldSeed,
  int generatorVersion = businessDistrictGeneratorVersion,
}) {
  final profile = businessDistrictProfileById(districtId);
  if (profile == null) {
    throw ArgumentError.value(districtId, 'districtId', '알 수 없는 상권입니다.');
  }
  return businessDistrictSnapshotFor(
    profile,
    asOf: asOf,
    worldSeed: worldSeed,
    generatorVersion: generatorVersion,
  );
}

BusinessDistrictSnapshot businessDistrictSnapshotFor(
  BusinessDistrictProfile profile, {
  required DateTime asOf,
  required String worldSeed,
  int generatorVersion = businessDistrictGeneratorVersion,
}) {
  final effectiveGeneratorVersion = generatorVersion >= 2
      ? businessDistrictGeneratorVersion
      : 1;
  final date = _validatedAsOf(asOf);
  final current = _calculateDistrictPoint(
    profile,
    asOf: date,
    worldSeed: worldSeed,
    generatorVersion: effectiveGeneratorVersion,
  );
  final previousMonthDate = _previousComparableDate(date, months: 1);
  final previousYearDate = _previousComparableDate(date, months: 12);
  final previousMonth = previousMonthDate == null
      ? current
      : _calculateDistrictPoint(
          profile,
          asOf: previousMonthDate,
          worldSeed: worldSeed,
          generatorVersion: effectiveGeneratorVersion,
        );
  final previousYear = previousYearDate == null
      ? current
      : _calculateDistrictPoint(
          profile,
          asOf: previousYearDate,
          worldSeed: worldSeed,
          generatorVersion: effectiveGeneratorVersion,
        );
  final revealedEvents = _revealedEventsFor(
    profile,
    date,
    worldSeed: worldSeed,
    generatorVersion: effectiveGeneratorVersion,
  );
  return BusinessDistrictSnapshot(
    generatorVersion: effectiveGeneratorVersion,
    districtId: profile.id,
    city: profile.city,
    name: profile.name,
    asOf: date,
    demandMultiplier: current.demand,
    rentMultiplier: current.rent,
    competitionMultiplier: current.competition,
    wageMultiplier: current.wage,
    vacancyMultiplier: current.vacancy,
    riskMultiplier: current.risk,
    vitalityScore: current.vitality,
    monthOverMonth: _changeBetween(current, previousMonth),
    yearOverYear: _changeBetween(current, previousYear),
    phase: current.phase,
    revealedEvents: List<BusinessDistrictRevealedEvent>.unmodifiable(
      revealedEvents,
    ),
    currentSignals: List<String>.unmodifiable(
      _signalsFor(
        point: current,
        yearAgo: previousYear,
        revealedEvents: revealedEvents,
      ),
    ),
  );
}

List<BusinessDistrictRankingEntry> rankBusinessDistricts({
  required DateTime asOf,
  required String worldSeed,
  BusinessIndustry? industry,
  String? city,
  int generatorVersion = businessDistrictGeneratorVersion,
}) {
  final normalizedCity = city?.trim().toLowerCase();
  final candidates =
      businessDistrictCatalog
          .where(
            (profile) =>
                normalizedCity == null ||
                normalizedCity.isEmpty ||
                profile.city.toLowerCase() == normalizedCity,
          )
          .map((profile) {
            final snapshot = businessDistrictSnapshotFor(
              profile,
              asOf: asOf,
              worldSeed: worldSeed,
              generatorVersion: generatorVersion,
            );
            final fit = industry == null
                ? 1.0
                : businessDistrictIndustryFit(profile, industry);
            final fitScore =
                ((fit - businessDistrictIndustryFitMin) /
                    (businessDistrictIndustryFitMax -
                        businessDistrictIndustryFitMin)) *
                18;
            final score =
                snapshot.vitalityScore * 0.62 +
                snapshot.demandMultiplier * 18 +
                fitScore -
                math.max(0, snapshot.rentMultiplier - 1) * 12 -
                math.max(0, snapshot.riskMultiplier - 1) * 10;
            return _UnrankedDistrict(profile, snapshot, fit, score);
          })
          .toList()
        ..sort((a, b) {
          final scoreOrder = b.score.compareTo(a.score);
          return scoreOrder != 0
              ? scoreOrder
              : a.profile.id.compareTo(b.profile.id);
        });

  return List<BusinessDistrictRankingEntry>.unmodifiable([
    for (var index = 0; index < candidates.length; index++)
      BusinessDistrictRankingEntry(
        rank: index + 1,
        profile: candidates[index].profile,
        snapshot: candidates[index].snapshot,
        industryFit: candidates[index].fit,
        opportunityScore: candidates[index].score.clamp(0, 100),
      ),
  ]);
}

List<BusinessDistrictSnapshot> businessDistrictHistory({
  required String districtId,
  required DateTime from,
  required DateTime to,
  required String worldSeed,
  int stepMonths = 12,
  int generatorVersion = businessDistrictGeneratorVersion,
}) {
  if (stepMonths < 1 || stepMonths > 60) {
    throw RangeError.range(stepMonths, 1, 60, 'stepMonths');
  }
  final start = _validatedAsOf(from);
  final end = _validatedAsOf(to);
  if (start.isAfter(end)) {
    throw ArgumentError('from은 to보다 늦을 수 없습니다.');
  }
  final result = <BusinessDistrictSnapshot>[];
  var cursor = start;
  while (!cursor.isAfter(end)) {
    result.add(
      businessDistrictSnapshot(
        districtId: districtId,
        asOf: cursor,
        worldSeed: worldSeed,
        generatorVersion: generatorVersion,
      ),
    );
    cursor = _shiftMonths(cursor, stepMonths);
  }
  if (result.isEmpty || !_sameDate(result.last.asOf, end)) {
    result.add(
      businessDistrictSnapshot(
        districtId: districtId,
        asOf: end,
        worldSeed: worldSeed,
        generatorVersion: generatorVersion,
      ),
    );
  }
  return List<BusinessDistrictSnapshot>.unmodifiable(result);
}

int estimatedDistrictMonthlyRent(
  BusinessDistrictProfile profile,
  BusinessDistrictSnapshot snapshot, {
  required double areaPyeong,
}) {
  if (areaPyeong <= 0) return 0;
  return (profile.baseMonthlyRentPerPyeong *
          areaPyeong *
          snapshot.rentMultiplier)
      .round();
}

int estimatedDistrictDailyFootTraffic(
  BusinessDistrictProfile profile,
  BusinessDistrictSnapshot snapshot,
) => (profile.baseDailyFootTraffic * snapshot.demandMultiplier).round();

String? businessDistrictIdForRealEstateRegion(
  String region, {
  String province = '',
}) => worldEconomyBusinessDistrictIdForRealEstateRegion(
  region,
  province: province,
);

class _DistrictPoint {
  const _DistrictPoint({
    required this.demand,
    required this.rent,
    required this.competition,
    required this.wage,
    required this.vacancy,
    required this.risk,
    required this.vitality,
    required this.phase,
  });

  final double demand;
  final double rent;
  final double competition;
  final double wage;
  final double vacancy;
  final double risk;
  final double vitality;
  final BusinessDistrictPhase phase;
}

class _UnrankedDistrict {
  const _UnrankedDistrict(this.profile, this.snapshot, this.fit, this.score);

  final BusinessDistrictProfile profile;
  final BusinessDistrictSnapshot snapshot;
  final double fit;
  final double score;
}

class _BusinessDistrictEvent {
  const _BusinessDistrictEvent({
    required this.id,
    required this.kind,
    required this.year,
    required this.month,
    required this.day,
    required this.headline,
    required this.summary,
    this.revealDelayDays = 0,
    this.durationMonths = 24,
    this.residualStrength = 0,
    this.targetDistrictIds = const [],
    this.targetTags = const [],
    this.demandDelta = 0,
    this.rentDelta = 0,
    this.competitionDelta = 0,
    this.wageDelta = 0,
    this.vacancyDelta = 0,
    this.riskDelta = 0,
    this.vitalityDelta = 0,
  });

  final String id;
  final BusinessDistrictEventKind kind;
  final int year;
  final int month;
  final int day;
  final String headline;
  final String summary;
  final int revealDelayDays;
  final int durationMonths;
  final double residualStrength;
  final List<String> targetDistrictIds;
  final List<String> targetTags;
  final double demandDelta;
  final double rentDelta;
  final double competitionDelta;
  final double wageDelta;
  final double vacancyDelta;
  final double riskDelta;
  final double vitalityDelta;

  DateTime get occurredOn => DateTime.utc(year, month, day);
  DateTime get revealedOn => occurredOn.add(Duration(days: revealDelayDays));

  bool appliesTo(BusinessDistrictProfile profile) {
    if (targetDistrictIds.isNotEmpty &&
        !targetDistrictIds.contains(profile.id)) {
      return false;
    }
    if (targetTags.isNotEmpty && !profile.regionTags.any(targetTags.contains)) {
      return false;
    }
    return true;
  }

  double strengthAt(DateTime asOf) {
    if (asOf.isBefore(occurredOn)) return 0;
    final elapsedMonths = asOf.difference(occurredOn).inDays / 30.436875;
    if (durationMonths <= 0) return residualStrength;
    if (elapsedMonths <= 2) {
      return (0.72 + elapsedMonths * 0.14).clamp(0, 1);
    }
    if (elapsedMonths <= durationMonths) {
      final progress = (elapsedMonths - 2) / math.max(1, durationMonths - 2);
      return 1 - (1 - residualStrength) * progress;
    }
    return residualStrength;
  }

  bool isActiveAt(DateTime asOf) =>
      strengthAt(asOf) > math.max(0.08, residualStrength + 0.04);
}

_DistrictPoint _calculateDistrictPoint(
  BusinessDistrictProfile profile, {
  required DateTime asOf,
  required String worldSeed,
  required int generatorVersion,
}) {
  final anchors = profile._lifecycleAnchors;
  final currentIndex = _latestAnchorIndex(anchors, asOf);
  final currentAnchor = anchors[currentIndex];
  final nextAnchor = currentIndex + 1 < anchors.length
      ? anchors[currentIndex + 1]
      : currentAnchor;
  final spanDays = math.max(
    1,
    nextAnchor.date.difference(currentAnchor.date).inDays,
  );
  final progress = currentAnchor == nextAnchor
      ? 0.0
      : (asOf.difference(currentAnchor.date).inDays / spanDays)
            .clamp(0.0, 1.0)
            .toDouble();
  final eased = progress * progress * (3 - 2 * progress);

  var demand = _lerp(
    currentAnchor.demandMultiplier,
    nextAnchor.demandMultiplier,
    eased,
  );
  var rent = _lerp(
    currentAnchor.rentMultiplier,
    nextAnchor.rentMultiplier,
    eased,
  );
  var competition = _lerp(
    currentAnchor.competitionMultiplier,
    nextAnchor.competitionMultiplier,
    eased,
  );
  var wage = _lerp(
    currentAnchor.wageMultiplier,
    nextAnchor.wageMultiplier,
    eased,
  );
  var vacancy = _lerp(
    currentAnchor.vacancyMultiplier,
    nextAnchor.vacancyMultiplier,
    eased,
  );
  var risk = _lerp(
    currentAnchor.riskMultiplier,
    nextAnchor.riskMultiplier,
    eased,
  );
  var vitality = _lerp(
    currentAnchor.vitalityScore,
    nextAnchor.vitalityScore,
    eased,
  );

  for (final event in _businessDistrictEvents) {
    if (generatorVersion >= 2 && _isLegacyNationalMacroEvent(event)) continue;
    if (!event.appliesTo(profile) || asOf.isBefore(event.occurredOn)) continue;
    final strength = event.strengthAt(asOf);
    demand += event.demandDelta * strength;
    rent += event.rentDelta * strength;
    competition += event.competitionDelta * strength;
    wage += event.wageDelta * strength;
    vacancy += event.vacancyDelta * strength;
    risk += event.riskDelta * strength;
    vitality += event.vitalityDelta * strength;
  }

  if (generatorVersion >= 2) {
    final economy = worldEconomySnapshot(
      worldSeed: worldSeed,
      asOf: asOf,
      regionKeys: _worldEconomyRegionKeys(profile),
    );
    final impact = economy.businessImpact;
    demand += impact.demand;
    rent += impact.rent;
    competition += impact.competition;
    wage += impact.wage;
    vacancy += impact.vacancy;
    risk += impact.risk;
    vitality += impact.vitality * 100;
  }

  final monthIndex = (asOf.year - 2000) * 12 + asOf.month - 1;
  demand *= _microMultiplier(
    worldSeed,
    profile.id,
    'demand',
    monthIndex,
    0.014,
  );
  rent *= _microMultiplier(worldSeed, profile.id, 'rent', monthIndex, 0.009);
  competition *= _microMultiplier(
    worldSeed,
    profile.id,
    'competition',
    monthIndex,
    0.011,
  );
  wage *= _microMultiplier(worldSeed, profile.id, 'wage', monthIndex, 0.006);
  vacancy *= _microMultiplier(
    worldSeed,
    profile.id,
    'vacancy',
    monthIndex,
    0.013,
  );
  risk *= _microMultiplier(worldSeed, profile.id, 'risk', monthIndex, 0.014);
  vitality += _microWave(worldSeed, profile.id, monthIndex) * 1.25;

  return _DistrictPoint(
    demand: demand.clamp(
      businessDistrictDemandMultiplierMin,
      businessDistrictDemandMultiplierMax,
    ),
    rent: rent.clamp(
      businessDistrictRentMultiplierMin,
      businessDistrictRentMultiplierMax,
    ),
    competition: competition.clamp(
      businessDistrictCompetitionMultiplierMin,
      businessDistrictCompetitionMultiplierMax,
    ),
    wage: wage.clamp(
      businessDistrictWageMultiplierMin,
      businessDistrictWageMultiplierMax,
    ),
    vacancy: vacancy.clamp(
      businessDistrictVacancyMultiplierMin,
      businessDistrictVacancyMultiplierMax,
    ),
    risk: risk.clamp(
      businessDistrictRiskMultiplierMin,
      businessDistrictRiskMultiplierMax,
    ),
    vitality: vitality.clamp(0, 100),
    phase: currentAnchor.phase,
  );
}

List<BusinessDistrictRevealedEvent> _revealedEventsFor(
  BusinessDistrictProfile profile,
  DateTime asOf, {
  required String worldSeed,
  required int generatorVersion,
}) {
  final result = <BusinessDistrictRevealedEvent>[];
  for (final event in _businessDistrictEvents) {
    if (generatorVersion >= 2 && _isLegacyNationalMacroEvent(event)) continue;
    if (!event.appliesTo(profile) || event.revealedOn.isAfter(asOf)) continue;
    result.add(
      BusinessDistrictRevealedEvent(
        id: event.id,
        kind: event.kind,
        occurredOn: event.occurredOn,
        revealedOn: event.revealedOn,
        headline: event.headline,
        summary: event.summary,
        isActive: event.isActiveAt(asOf),
      ),
    );
  }
  if (generatorVersion >= 2) {
    final economy = worldEconomySnapshot(
      worldSeed: worldSeed,
      asOf: asOf,
      regionKeys: _worldEconomyRegionKeys(profile),
    );
    final existingIds = result.map((event) => event.id).toSet();
    for (final event in economy.revealedEvents) {
      if (event.revealedOn.isAfter(asOf) || !existingIds.add(event.id)) {
        continue;
      }
      result.add(
        BusinessDistrictRevealedEvent(
          id: event.id,
          kind: _businessEventKindForWorldEconomy(event.kind),
          occurredOn: event.occurredOn,
          revealedOn: event.revealedOn,
          headline: '공통경제 · ${event.title}',
          summary: event.summary,
          isActive: event.isActive,
        ),
      );
    }
  }
  result.sort((a, b) {
    final byRevealDate = b.revealedOn.compareTo(a.revealedOn);
    if (byRevealDate != 0) return byRevealDate;
    return a.id.compareTo(b.id);
  });
  return result;
}

bool _isLegacyNationalMacroEvent(_BusinessDistrictEvent event) =>
    event.id.startsWith('national_') ||
    event.kind == BusinessDistrictEventKind.nationalShock;

List<String> _worldEconomyRegionKeys(BusinessDistrictProfile profile) =>
    <String>{
      profile.id,
      profile.city,
      ...profile.regionTags,
    }.toList(growable: false);

BusinessDistrictEventKind _businessEventKindForWorldEconomy(
  WorldEconomyEventKind kind,
) => switch (kind) {
  WorldEconomyEventKind.creditShock ||
  WorldEconomyEventKind.pandemic ||
  WorldEconomyEventKind.geopolitical => BusinessDistrictEventKind.nationalShock,
  WorldEconomyEventKind.policySupport => BusinessDistrictEventKind.regeneration,
  WorldEconomyEventKind.energyCost => BusinessDistrictEventKind.rentSurge,
  WorldEconomyEventKind.demand => BusinessDistrictEventKind.populationShift,
  WorldEconomyEventKind.trade => BusinessDistrictEventKind.industrialTransition,
  WorldEconomyEventKind.technology =>
    BusinessDistrictEventKind.onlineConsumption,
  WorldEconomyEventKind.regulation => BusinessDistrictEventKind.redevelopment,
  WorldEconomyEventKind.other => BusinessDistrictEventKind.populationShift,
};

BusinessDistrictChange _changeBetween(
  _DistrictPoint current,
  _DistrictPoint previous,
) => BusinessDistrictChange(
  vitalityPoints: current.vitality - previous.vitality,
  demandPercent: _percentChange(current.demand, previous.demand),
  rentPercent: _percentChange(current.rent, previous.rent),
  competitionPercent: _percentChange(current.competition, previous.competition),
  wagePercent: _percentChange(current.wage, previous.wage),
  vacancyPercent: _percentChange(current.vacancy, previous.vacancy),
  riskPercent: _percentChange(current.risk, previous.risk),
);

List<String> _signalsFor({
  required _DistrictPoint point,
  required _DistrictPoint yearAgo,
  required List<BusinessDistrictRevealedEvent> revealedEvents,
}) {
  final signals = <String>[
    switch (point.phase) {
      BusinessDistrictPhase.emerging => '초기 유입 증가',
      BusinessDistrictPhase.booming => '매출 기회 급증',
      BusinessDistrictPhase.mature => '높은 수요 정착',
      BusinessDistrictPhase.cooling => '호황 열기 둔화',
      BusinessDistrictPhase.declining => '유동인구 이탈',
      BusinessDistrictPhase.distressed => '폐점·공실 경계',
      BusinessDistrictPhase.regenerating => '재생 수요 유입',
    },
  ];
  final yearlyDemand = _percentChange(point.demand, yearAgo.demand);
  final yearlyRent = _percentChange(point.rent, yearAgo.rent);
  if (yearlyDemand >= 4) {
    signals.add('전년보다 수요 상승');
  } else if (yearlyDemand <= -4) {
    signals.add('전년보다 수요 하락');
  }
  if (yearlyRent >= 5) signals.add('임대료 상승 압력');
  if (point.competition >= 1.13) signals.add('동종업 경쟁 과열');
  if (point.vacancy >= 1.17) signals.add('공실 증가');
  if (point.risk >= 1.22) signals.add('운영 위험 확대');
  final active = revealedEvents.where((event) => event.isActive).firstOrNull;
  if (active != null) signals.add(active.headline);
  return signals.toSet().take(5).toList();
}

int _latestAnchorIndex(
  List<BusinessDistrictLifecycleAnchor> anchors,
  DateTime asOf,
) {
  var result = 0;
  for (var index = 1; index < anchors.length; index++) {
    if (anchors[index].date.isAfter(asOf)) break;
    result = index;
  }
  return result;
}

DateTime _validatedAsOf(DateTime value) {
  final date = _dateOnlyUtc(value);
  if (date.isBefore(businessDistrictCampaignStart) ||
      date.isAfter(businessDistrictCampaignEnd)) {
    throw RangeError('상권 날짜는 2000-01-01부터 2026-12-31 사이여야 합니다: $date');
  }
  return date;
}

DateTime _dateOnlyUtc(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

DateTime? _previousComparableDate(DateTime date, {required int months}) {
  final shifted = _shiftMonths(date, -months);
  return shifted.isBefore(businessDistrictCampaignStart) ? null : shifted;
}

DateTime _shiftMonths(DateTime date, int months) {
  final zeroBased = date.year * 12 + date.month - 1 + months;
  final year = zeroBased ~/ 12;
  final month = zeroBased % 12 + 1;
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(year, month, math.min(date.day, lastDay));
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

double _lerp(double a, double b, double t) => a + (b - a) * t;

double _percentChange(double current, double previous) =>
    previous == 0 ? 0 : (current / previous - 1) * 100;

double _microMultiplier(
  String worldSeed,
  String districtId,
  String metric,
  int monthIndex,
  double amplitude,
) {
  final bias =
      (_deterministicUnit('$worldSeed:$districtId:$metric:bias') - 0.5) *
      amplitude;
  final phase =
      _deterministicUnit('$worldSeed:$districtId:$metric:phase') * math.pi * 2;
  final wave = math.sin(monthIndex * 0.37 + phase) * amplitude * 0.55;
  return 1 + bias + wave;
}

double _microWave(String worldSeed, String districtId, int monthIndex) {
  final phase =
      _deterministicUnit('$worldSeed:$districtId:vitality') * math.pi * 2;
  return math.sin(monthIndex * 0.31 + phase);
}

double _deterministicUnit(String value) =>
    (stableBusinessDistrictHash(value) % 1000000) / 999999;

/// FNV-1a style 31-bit hash with exact multiplication on Dart VM and Web.
///
/// JavaScript numbers cannot exactly represent the direct 32-bit product. The
/// 16-bit limbs keep every intermediate below 2^53 before the final mask.
int stableBusinessDistrictHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = multiplyFnvPrime31Exact(hash);
  }
  return hash;
}

enum _DistrictTrajectory {
  core,
  growth,
  decline,
  regeneration,
  newTown,
  office,
  university,
  residential,
  tourism,
}

class _DistrictSpec {
  const _DistrictSpec(
    this.id,
    this.city,
    this.name,
    this.regionTags,
    this.affinities,
    this.trajectory,
    this.turningYear,
    this.scale,
  );

  final String id;
  final String city;
  final String name;
  final List<String> regionTags;
  final Map<BusinessIndustry, double> affinities;
  final _DistrictTrajectory trajectory;
  final int turningYear;
  final double scale;
}

const _nightFit = <BusinessIndustry, double>{
  BusinessIndustry.pcBang: 1.20,
  BusinessIndustry.karaoke: 1.30,
  BusinessIndustry.cafe: 1.14,
  BusinessIndustry.fastFood: 1.16,
  BusinessIndustry.arcade: 1.20,
  BusinessIndustry.boardGameCafe: 1.18,
};
const _officeFit = <BusinessIndustry, double>{
  BusinessIndustry.cafe: 1.24,
  BusinessIndustry.bakery: 1.16,
  BusinessIndustry.koreanRestaurant: 1.22,
  BusinessIndustry.fastFood: 1.18,
  BusinessIndustry.convenienceStore: 1.14,
  BusinessIndustry.deliveryKitchen: 1.16,
};
const _campusFit = <BusinessIndustry, double>{
  BusinessIndustry.pcBang: 1.28,
  BusinessIndustry.karaoke: 1.20,
  BusinessIndustry.cafe: 1.20,
  BusinessIndustry.fastFood: 1.18,
  BusinessIndustry.studyCafe: 1.30,
  BusinessIndustry.arcade: 1.16,
  BusinessIndustry.boardGameCafe: 1.24,
  BusinessIndustry.usedBookStore: 1.18,
};
const _homeFit = <BusinessIndustry, double>{
  BusinessIndustry.bakery: 1.16,
  BusinessIndustry.convenienceStore: 1.22,
  BusinessIndustry.studyCafe: 1.12,
  BusinessIndustry.fitnessCenter: 1.16,
  BusinessIndustry.coinLaundry: 1.24,
  BusinessIndustry.hairSalon: 1.18,
  BusinessIndustry.petGrooming: 1.22,
  BusinessIndustry.deliveryKitchen: 1.12,
};
const _tourFit = <BusinessIndustry, double>{
  BusinessIndustry.karaoke: 1.12,
  BusinessIndustry.cafe: 1.22,
  BusinessIndustry.bakery: 1.14,
  BusinessIndustry.koreanRestaurant: 1.22,
  BusinessIndustry.photographyStudio: 1.30,
};
const _oldTownFit = <BusinessIndustry, double>{
  BusinessIndustry.bakery: 1.10,
  BusinessIndustry.koreanRestaurant: 1.24,
  BusinessIndustry.convenienceStore: 1.08,
  BusinessIndustry.hairSalon: 1.12,
  BusinessIndustry.usedBookStore: 1.18,
  BusinessIndustry.nailSalon: 0.88,
  BusinessIndustry.boardGameCafe: 0.86,
};

const _districtSpecs = <_DistrictSpec>[
  _DistrictSpec(
    'seoul_gangnam_station',
    '서울',
    '강남역',
    ['capital', 'station', 'office', 'gangnam'],
    _officeFit,
    _DistrictTrajectory.core,
    2007,
    1.00,
  ),
  _DistrictSpec(
    'seoul_hongdae',
    '서울',
    '홍대입구',
    ['capital', 'university', 'nightlife', 'gentrified'],
    _nightFit,
    _DistrictTrajectory.growth,
    2013,
    0.91,
  ),
  _DistrictSpec(
    'seoul_sinchon',
    '서울',
    '신촌 대학가',
    ['capital', 'university', 'oldDowntown'],
    _campusFit,
    _DistrictTrajectory.university,
    2012,
    0.69,
  ),
  _DistrictSpec(
    'seoul_myeongdong',
    '서울',
    '명동',
    ['capital', 'tourism', 'retail', 'oldDowntown'],
    _tourFit,
    _DistrictTrajectory.tourism,
    2010,
    1.00,
  ),
  _DistrictSpec(
    'seoul_seongsu',
    '서울',
    '성수',
    ['capital', 'industrial', 'culture', 'regeneration', 'seongdong'],
    _nightFit,
    _DistrictTrajectory.regeneration,
    2015,
    0.82,
  ),
  _DistrictSpec(
    'seoul_itaewon',
    '서울',
    '이태원',
    ['capital', 'tourism', 'nightlife', 'international', 'yongsan'],
    _nightFit,
    _DistrictTrajectory.tourism,
    2012,
    0.78,
  ),
  _DistrictSpec(
    'seoul_guro_digital',
    '서울',
    '구로디지털단지',
    ['capital', 'office', 'industrialTransition', 'guro'],
    _officeFit,
    _DistrictTrajectory.office,
    2006,
    0.64,
  ),
  _DistrictSpec(
    'seoul_jongno',
    '서울',
    '종로·청계',
    ['capital', 'office', 'traditional', 'oldDowntown', 'jongno'],
    _oldTownFit,
    _DistrictTrajectory.regeneration,
    2014,
    0.70,
  ),
  _DistrictSpec(
    'seoul_euljiro',
    '서울',
    '을지로',
    ['capital', 'industrial', 'culture', 'regeneration', 'oldDowntown'],
    _nightFit,
    _DistrictTrajectory.regeneration,
    2017,
    0.67,
  ),
  _DistrictSpec(
    'seoul_nowon_station',
    '서울',
    '노원역',
    ['capital', 'residential', 'education', 'nowon'],
    _homeFit,
    _DistrictTrajectory.residential,
    2008,
    0.53,
  ),
  _DistrictSpec(
    'seoul_jamsil',
    '서울',
    '잠실',
    ['capital', 'residential', 'tourism', 'songpa'],
    _homeFit,
    _DistrictTrajectory.growth,
    2017,
    0.86,
  ),
  _DistrictSpec(
    'seoul_yongsan_station',
    '서울',
    '용산역',
    ['capital', 'station', 'redevelopment', 'office', 'yongsan'],
    _officeFit,
    _DistrictTrajectory.regeneration,
    2016,
    0.75,
  ),
  _DistrictSpec(
    'gyeonggi_pangyo',
    '성남',
    '판교테크노밸리',
    ['gyeonggi', 'office', 'newTown', 'tech', 'seongnam'],
    _officeFit,
    _DistrictTrajectory.office,
    2011,
    0.79,
  ),
  _DistrictSpec(
    'gyeonggi_gwanggyo',
    '수원',
    '광교신도시',
    ['gyeonggi', 'newTown', 'residential', 'office', 'suwon'],
    _homeFit,
    _DistrictTrajectory.newTown,
    2013,
    0.62,
  ),
  _DistrictSpec(
    'gyeonggi_dongtan',
    '화성',
    '동탄신도시',
    ['gyeonggi', 'newTown', 'residential', 'transit'],
    _homeFit,
    _DistrictTrajectory.newTown,
    2015,
    0.59,
  ),
  _DistrictSpec(
    'gyeonggi_bundang_seohyeon',
    '성남',
    '분당 서현',
    ['gyeonggi', 'newTown', 'residential', 'mature', 'seongnam'],
    _homeFit,
    _DistrictTrajectory.growth,
    2007,
    0.65,
  ),
  _DistrictSpec(
    'gyeonggi_ilsan_lafesta',
    '고양',
    '일산 라페스타',
    ['gyeonggi', 'newTown', 'nightlife', 'declining', 'goyang'],
    _nightFit,
    _DistrictTrajectory.decline,
    2009,
    0.45,
  ),
  _DistrictSpec(
    'gyeonggi_suwon_station',
    '수원',
    '수원역',
    ['gyeonggi', 'station', 'oldDowntown', 'suwon'],
    _nightFit,
    _DistrictTrajectory.regeneration,
    2018,
    0.57,
  ),
  _DistrictSpec(
    'gyeonggi_bucheon_sangdong',
    '부천',
    '상동·중동',
    ['gyeonggi', 'residential', 'education', 'bucheon'],
    _homeFit,
    _DistrictTrajectory.residential,
    2008,
    0.48,
  ),
  _DistrictSpec(
    'gyeonggi_uijeongbu_station',
    '의정부',
    '의정부역',
    ['gyeonggi', 'station', 'oldDowntown', 'regeneration', 'uijeongbu'],
    _oldTownFit,
    _DistrictTrajectory.regeneration,
    2019,
    0.36,
  ),
  _DistrictSpec(
    'gyeonggi_gwacheon_central',
    '과천',
    '과천 중앙',
    ['gyeonggi', 'office', 'residential', 'redevelopment', 'gwacheon'],
    _homeFit,
    _DistrictTrajectory.regeneration,
    2021,
    0.51,
  ),
  _DistrictSpec(
    'incheon_songdo',
    '인천',
    '송도국제도시',
    ['incheon', 'newTown', 'office', 'international'],
    _homeFit,
    _DistrictTrajectory.newTown,
    2014,
    0.63,
  ),
  _DistrictSpec(
    'incheon_bupyeong',
    '인천',
    '부평역',
    ['incheon', 'station', 'nightlife', 'oldDowntown'],
    _nightFit,
    _DistrictTrajectory.decline,
    2013,
    0.50,
  ),
  _DistrictSpec(
    'incheon_guwol',
    '인천',
    '구월 로데오',
    ['incheon', 'office', 'residential', 'nightlife'],
    _nightFit,
    _DistrictTrajectory.growth,
    2014,
    0.55,
  ),
  _DistrictSpec(
    'busan_seomyeon',
    '부산',
    '서면',
    ['busan', 'station', 'office', 'nightlife'],
    _nightFit,
    _DistrictTrajectory.core,
    2008,
    0.72,
  ),
  _DistrictSpec(
    'busan_haeundae',
    '부산',
    '해운대',
    ['busan', 'tourism', 'residential', 'waterfront'],
    _tourFit,
    _DistrictTrajectory.tourism,
    2012,
    0.73,
  ),
  _DistrictSpec(
    'daegu_dongseongno',
    '대구',
    '동성로',
    ['daegu', 'oldDowntown', 'nightlife', 'retail'],
    _nightFit,
    _DistrictTrajectory.decline,
    2012,
    0.49,
  ),
  _DistrictSpec(
    'daejeon_dunsan',
    '대전',
    '둔산',
    ['daejeon', 'office', 'education', 'residential'],
    _officeFit,
    _DistrictTrajectory.residential,
    2008,
    0.47,
  ),
  _DistrictSpec(
    'gwangju_chungjang',
    '광주',
    '충장로',
    ['gwangju', 'oldDowntown', 'traditional', 'regeneration'],
    _oldTownFit,
    _DistrictTrajectory.regeneration,
    2019,
    0.34,
  ),
  _DistrictSpec(
    'ulsan_samsan',
    '울산',
    '삼산',
    ['ulsan', 'office', 'industrial', 'nightlife'],
    _officeFit,
    _DistrictTrajectory.growth,
    2014,
    0.44,
  ),
  _DistrictSpec(
    'sejong_nasung',
    '세종',
    '나성동',
    ['sejong', 'newTown', 'office', 'residential'],
    _homeFit,
    _DistrictTrajectory.newTown,
    2016,
    0.45,
  ),
  _DistrictSpec(
    'jeju_nohyeong',
    '제주',
    '노형',
    ['jeju', 'tourism', 'residential', 'island'],
    _tourFit,
    _DistrictTrajectory.tourism,
    2014,
    0.42,
  ),
];

final List<BusinessDistrictProfile> businessDistrictCatalog =
    List<BusinessDistrictProfile>.unmodifiable(
      _districtSpecs.map((spec) {
        final vacancyBias = switch (spec.trajectory) {
          _DistrictTrajectory.decline => 0.08,
          _DistrictTrajectory.regeneration => 0.05,
          _DistrictTrajectory.newTown => 0.04,
          _ => 0.0,
        };
        return BusinessDistrictProfile(
          id: spec.id,
          city: spec.city,
          name: spec.name,
          summary: _trajectorySummary(spec),
          regionTags: List<String>.unmodifiable(spec.regionTags),
          industryAffinities: Map<BusinessIndustry, double>.unmodifiable(
            spec.affinities,
          ),
          baseMonthlyRentPerPyeong: (60000 + 190000 * spec.scale).round(),
          baseDailyFootTraffic: (22000 + 120000 * spec.scale).round(),
          baseCompetitionIndex: 48 + 44 * spec.scale,
          baseMonthlyWage: (1980000 + 470000 * spec.scale).round(),
          baseVacancyRate: (0.05 + (1 - spec.scale) * 0.08 + vacancyBias).clamp(
            0.04,
            0.22,
          ),
          baseRiskIndex: (30 + (1 - spec.scale) * 32 + vacancyBias * 100).clamp(
            20,
            85,
          ),
          lifecycleAnchors: _anchorsFor(spec),
        );
      }),
    );

String _trajectorySummary(_DistrictSpec spec) => switch (spec.trajectory) {
  _DistrictTrajectory.core =>
    '${spec.name}은(는) 광역 수요와 높은 비용이 함께 움직이는 핵심 상권입니다.',
  _DistrictTrajectory.growth => '${spec.name}은(는) 빠른 성장 뒤 성숙기로 접어든 상권입니다.',
  _DistrictTrajectory.decline => '${spec.name}은(는) 전성기 뒤 유동 이탈과 공실을 겪는 상권입니다.',
  _DistrictTrajectory.regeneration =>
    '${spec.name}은(는) 노후화 뒤 재개발·문화 유입으로 회복하는 상권입니다.',
  _DistrictTrajectory.newTown =>
    '${spec.name}은(는) 대규모 입주와 교통 공급에 따라 커진 신도시 상권입니다.',
  _DistrictTrajectory.office => '${spec.name}은(는) 기업 입주와 출근 인구가 핵심인 업무 상권입니다.',
  _DistrictTrajectory.university =>
    '${spec.name}은(는) 학령인구와 청년 소비 이동에 민감한 대학가입니다.',
  _DistrictTrajectory.residential =>
    '${spec.name}은(는) 주거·교육·생활 수요가 받치는 안정형 상권입니다.',
  _DistrictTrajectory.tourism =>
    '${spec.name}은(는) 관광 회복과 계절 변화에 민감한 방문형 상권입니다.',
};

List<BusinessDistrictLifecycleAnchor> _anchorsFor(_DistrictSpec spec) {
  final turn = spec.turningYear.clamp(2005, 2021);
  final anchors = switch (spec.trajectory) {
    _DistrictTrajectory.core => [
      _anchor(2000, BusinessDistrictPhase.mature, 78, '광역 핵심 상권 정착'),
      _anchor(2007, BusinessDistrictPhase.booming, 88, '소비·업무 수요 팽창'),
      _anchor(2012, BusinessDistrictPhase.mature, 82, '경기 충격 뒤 회복'),
      _anchor(2020, BusinessDistrictPhase.distressed, 48, '대면 소비 급감'),
      _anchor(2023, BusinessDistrictPhase.regenerating, 72, '재개장과 소비 회복'),
      _anchor(2026, BusinessDistrictPhase.mature, 80, '광역 수요 재정착'),
    ],
    _DistrictTrajectory.growth => [
      _anchor(2000, BusinessDistrictPhase.emerging, 56, '성장 초기'),
      _anchor(turn - 3, BusinessDistrictPhase.booming, 84, '유동 급증'),
      _anchor(turn + 3, BusinessDistrictPhase.mature, 78, '수요 정착'),
      _anchor(2020, BusinessDistrictPhase.distressed, 45, '대면 소비 충격'),
      _anchor(2023, BusinessDistrictPhase.regenerating, 67, '수요 회복'),
      _anchor(2026, BusinessDistrictPhase.mature, 76, '성숙기 재정착'),
    ],
    _DistrictTrajectory.decline => [
      _anchor(2000, BusinessDistrictPhase.booming, 82, '번화가 전성기'),
      _anchor(turn, BusinessDistrictPhase.cooling, 65, '경쟁 상권 분산'),
      _anchor(turn + 5, BusinessDistrictPhase.declining, 48, '온라인 소비·유동 이탈'),
      _anchor(2020, BusinessDistrictPhase.distressed, 32, '공실과 소비 충격'),
      _anchor(2023, BusinessDistrictPhase.declining, 42, '회복 지연'),
      _anchor(2026, BusinessDistrictPhase.regenerating, 53, '재생 사업 유입'),
    ],
    _DistrictTrajectory.regeneration => [
      _anchor(2000, BusinessDistrictPhase.mature, 66, '기존 생활·업무 수요'),
      _anchor(turn - 5, BusinessDistrictPhase.declining, 44, '노후화와 유동 이탈'),
      _anchor(turn, BusinessDistrictPhase.distressed, 34, '공실·개발 불확실성'),
      _anchor(turn + 2, BusinessDistrictPhase.regenerating, 57, '재개발·문화 유입'),
      _anchor(2020, BusinessDistrictPhase.distressed, 40, '대면 소비 충격'),
      _anchor(2023, BusinessDistrictPhase.regenerating, 62, '재생 수요 재가동'),
      _anchor(2026, BusinessDistrictPhase.booming, 74, '신규 수요 확산'),
    ],
    _DistrictTrajectory.newTown => [
      _anchor(2000, BusinessDistrictPhase.distressed, 23, '개발 전 저밀 상권'),
      _anchor(turn - 3, BusinessDistrictPhase.emerging, 48, '첫 대규모 입주'),
      _anchor(turn, BusinessDistrictPhase.booming, 78, '상업·생활 수요 급증'),
      _anchor(turn + 4, BusinessDistrictPhase.cooling, 67, '공급 과잉 조정'),
      _anchor(2020, BusinessDistrictPhase.distressed, 44, '대면 소비 충격'),
      _anchor(2023, BusinessDistrictPhase.regenerating, 66, '입주·교통 효과 재개'),
      _anchor(2026, BusinessDistrictPhase.mature, 75, '생활권 정착'),
    ],
    _DistrictTrajectory.office => [
      _anchor(2000, BusinessDistrictPhase.distressed, 30, '업무 집적 전'),
      _anchor(turn - 3, BusinessDistrictPhase.emerging, 50, '기업 입주 시작'),
      _anchor(turn, BusinessDistrictPhase.booming, 82, '업무 인구 급증'),
      _anchor(turn + 4, BusinessDistrictPhase.mature, 79, '업무지구 정착'),
      _anchor(2020, BusinessDistrictPhase.distressed, 42, '재택근무 충격'),
      _anchor(2023, BusinessDistrictPhase.regenerating, 66, '출근 수요 회복'),
      _anchor(2026, BusinessDistrictPhase.mature, 77, '복합 업무 수요 정착'),
    ],
    _DistrictTrajectory.university => [
      _anchor(2000, BusinessDistrictPhase.booming, 84, '대학가 전성기'),
      _anchor(turn, BusinessDistrictPhase.mature, 72, '수요 정체'),
      _anchor(turn + 4, BusinessDistrictPhase.declining, 52, '청년 소비 이동'),
      _anchor(2020, BusinessDistrictPhase.distressed, 28, '비대면 수업 충격'),
      _anchor(2023, BusinessDistrictPhase.declining, 42, '유동 회복 지연'),
      _anchor(2026, BusinessDistrictPhase.regenerating, 52, '문화·주거 재생'),
    ],
    _DistrictTrajectory.residential => [
      _anchor(2000, BusinessDistrictPhase.emerging, 54, '생활권 형성'),
      _anchor(2008, BusinessDistrictPhase.mature, 69, '주거 수요 정착'),
      _anchor(2015, BusinessDistrictPhase.mature, 72, '단골·교육 수요 안정'),
      _anchor(2020, BusinessDistrictPhase.cooling, 62, '대면 서비스 둔화'),
      _anchor(2023, BusinessDistrictPhase.mature, 70, '생활 소비 회복'),
      _anchor(2026, BusinessDistrictPhase.mature, 72, '안정 생활권 유지'),
    ],
    _DistrictTrajectory.tourism => [
      _anchor(2000, BusinessDistrictPhase.mature, 70, '관광 소비 정착'),
      _anchor(2010, BusinessDistrictPhase.booming, 83, '관광 수요 확대'),
      _anchor(2017, BusinessDistrictPhase.mature, 78, '관광 상권 고도화'),
      _anchor(2020, BusinessDistrictPhase.distressed, 20, '관광·대면 소비 중단'),
      _anchor(2022, BusinessDistrictPhase.regenerating, 55, '관광 재개'),
      _anchor(2024, BusinessDistrictPhase.booming, 78, '방문 수요 반등'),
      _anchor(2026, BusinessDistrictPhase.mature, 76, '관광 수요 정상화'),
    ],
  };
  return List<BusinessDistrictLifecycleAnchor>.unmodifiable(anchors);
}

BusinessDistrictLifecycleAnchor _anchor(
  int year,
  BusinessDistrictPhase phase,
  double vitality,
  String cause,
) {
  final values = switch (phase) {
    BusinessDistrictPhase.emerging => const [
      0.94,
      0.82,
      0.87,
      0.94,
      1.16,
      1.13,
    ],
    BusinessDistrictPhase.booming => const [1.22, 1.20, 1.19, 1.08, 0.74, 1.02],
    BusinessDistrictPhase.mature => const [1.10, 1.12, 1.10, 1.05, 0.88, 0.91],
    BusinessDistrictPhase.cooling => const [0.98, 1.10, 1.04, 1.03, 1.07, 1.09],
    BusinessDistrictPhase.declining => const [
      0.84,
      0.89,
      0.84,
      0.97,
      1.27,
      1.28,
    ],
    BusinessDistrictPhase.distressed => const [
      0.74,
      0.72,
      0.79,
      0.91,
      1.42,
      1.45,
    ],
    BusinessDistrictPhase.regenerating => const [
      1.01,
      0.94,
      0.98,
      1.01,
      1.09,
      1.16,
    ],
  };
  return BusinessDistrictLifecycleAnchor(
    year: year,
    month: 1,
    day: 1,
    phase: phase,
    vitalityScore: vitality,
    demandMultiplier: values[0],
    rentMultiplier: values[1],
    competitionMultiplier: values[2],
    wageMultiplier: values[3],
    vacancyMultiplier: values[4],
    riskMultiplier: values[5],
    cause: cause,
  );
}

final List<_BusinessDistrictEvent>
_businessDistrictEvents = List<_BusinessDistrictEvent>.unmodifiable([
  const _BusinessDistrictEvent(
    id: 'national_2008_financial_slowdown',
    kind: BusinessDistrictEventKind.nationalShock,
    year: 2008,
    month: 9,
    day: 15,
    headline: '금융위기로 소비 심리 위축',
    summary: '신용 경색과 고용 불안으로 전국 상권의 소비와 신규 출점이 줄었습니다.',
    durationMonths: 30,
    demandDelta: -0.13,
    rentDelta: -0.03,
    competitionDelta: -0.03,
    vacancyDelta: 0.12,
    riskDelta: 0.19,
    vitalityDelta: -12,
  ),
  const _BusinessDistrictEvent(
    id: 'national_2010_online_consumption',
    kind: BusinessDistrictEventKind.onlineConsumption,
    year: 2010,
    month: 6,
    day: 1,
    headline: '온라인·모바일 소비 확산',
    summary: '비교 구매가 쉬워지며 구도심 소매 상권의 유동이 장기적으로 분산됐습니다.',
    durationMonths: 72,
    residualStrength: 0.62,
    targetTags: ['oldDowntown', 'retail', 'traditional'],
    demandDelta: -0.07,
    rentDelta: -0.03,
    competitionDelta: -0.02,
    vacancyDelta: 0.07,
    riskDelta: 0.08,
    vitalityDelta: -6,
  ),
  const _BusinessDistrictEvent(
    id: 'national_2020_contact_shock',
    kind: BusinessDistrictEventKind.nationalShock,
    year: 2020,
    month: 2,
    day: 23,
    revealDelayDays: 1,
    headline: '대면 소비 급감',
    summary: '관광·회식·등교가 동시에 줄어 전국 상권의 매출과 유동이 급락했습니다.',
    durationMonths: 28,
    demandDelta: -0.24,
    rentDelta: -0.03,
    competitionDelta: -0.08,
    wageDelta: -0.02,
    vacancyDelta: 0.23,
    riskDelta: 0.31,
    vitalityDelta: -24,
  ),
  const _BusinessDistrictEvent(
    id: 'national_2022_reopening_costs',
    kind: BusinessDistrictEventKind.rentSurge,
    year: 2022,
    month: 4,
    day: 18,
    headline: '재개장 수요와 비용 동반 상승',
    summary: '유동은 회복했지만 인건비·임대료·원재료 부담도 빠르게 늘었습니다.',
    durationMonths: 42,
    residualStrength: 0.30,
    demandDelta: 0.09,
    rentDelta: 0.08,
    competitionDelta: 0.05,
    wageDelta: 0.08,
    vacancyDelta: -0.05,
    riskDelta: 0.04,
    vitalityDelta: 7,
  ),
  const _BusinessDistrictEvent(
    id: 'guro_2003_digital_cluster',
    kind: BusinessDistrictEventKind.industrialTransition,
    year: 2003,
    month: 9,
    day: 1,
    headline: '디지털 업무단지 전환',
    summary: '공장 부지에 IT 기업과 지원 시설이 입주하며 평일 수요가 늘었습니다.',
    durationMonths: 72,
    residualStrength: 0.72,
    targetDistrictIds: ['seoul_guro_digital'],
    demandDelta: 0.13,
    rentDelta: 0.09,
    competitionDelta: 0.09,
    wageDelta: 0.04,
    vacancyDelta: -0.12,
    riskDelta: -0.06,
    vitalityDelta: 14,
  ),
  const _BusinessDistrictEvent(
    id: 'jongno_2005_cheonggye_regeneration',
    kind: BusinessDistrictEventKind.regeneration,
    year: 2005,
    month: 10,
    day: 1,
    headline: '청계천 일대 보행 수요 증가',
    summary: '환경 정비와 관광 동선 변화가 구도심 유동을 다시 끌어들였습니다.',
    durationMonths: 60,
    residualStrength: 0.38,
    targetDistrictIds: ['seoul_jongno'],
    demandDelta: 0.10,
    rentDelta: 0.07,
    competitionDelta: 0.06,
    vacancyDelta: -0.07,
    vitalityDelta: 9,
  ),
  const _BusinessDistrictEvent(
    id: 'songdo_2009_first_occupancy',
    kind: BusinessDistrictEventKind.newTownOccupancy,
    year: 2009,
    month: 8,
    day: 1,
    headline: '송도 대규모 입주 시작',
    summary: '주거와 국제업무 시설의 입주가 생활 상권의 기본 수요를 만들었습니다.',
    durationMonths: 84,
    residualStrength: 0.68,
    targetDistrictIds: ['incheon_songdo'],
    demandDelta: 0.16,
    rentDelta: 0.11,
    competitionDelta: 0.10,
    vacancyDelta: -0.12,
    vitalityDelta: 16,
  ),
  const _BusinessDistrictEvent(
    id: 'gangnam_2011_shinbundang',
    kind: BusinessDistrictEventKind.transitOpening,
    year: 2011,
    month: 10,
    day: 28,
    headline: '신분당선 개통',
    summary: '강남과 판교·분당의 이동 시간이 줄어 역세권 유동이 확대됐습니다.',
    durationMonths: 60,
    residualStrength: 0.45,
    targetDistrictIds: [
      'seoul_gangnam_station',
      'gyeonggi_pangyo',
      'gyeonggi_bundang_seohyeon',
    ],
    demandDelta: 0.08,
    rentDelta: 0.07,
    competitionDelta: 0.05,
    vacancyDelta: -0.05,
    vitalityDelta: 7,
  ),
  const _BusinessDistrictEvent(
    id: 'sejong_2012_government_move',
    kind: BusinessDistrictEventKind.officeCluster,
    year: 2012,
    month: 9,
    day: 14,
    headline: '정부기관 이전 본격화',
    summary: '공무원과 가족의 입주가 업무·생활 서비스 수요를 함께 만들었습니다.',
    durationMonths: 96,
    residualStrength: 0.74,
    targetDistrictIds: ['sejong_nasung'],
    demandDelta: 0.18,
    rentDelta: 0.13,
    competitionDelta: 0.12,
    wageDelta: 0.03,
    vacancyDelta: -0.13,
    vitalityDelta: 18,
  ),
  const _BusinessDistrictEvent(
    id: 'pangyo_2013_tech_cluster',
    kind: BusinessDistrictEventKind.officeCluster,
    year: 2013,
    month: 3,
    day: 1,
    headline: '판교 IT 기업 입주 가속',
    summary: '고임금 업무 인구와 평일 점심·회식 수요가 빠르게 늘었습니다.',
    durationMonths: 84,
    residualStrength: 0.70,
    targetDistrictIds: ['gyeonggi_pangyo'],
    demandDelta: 0.16,
    rentDelta: 0.13,
    competitionDelta: 0.11,
    wageDelta: 0.06,
    vacancyDelta: -0.11,
    vitalityDelta: 15,
  ),
  const _BusinessDistrictEvent(
    id: 'hongdae_2013_gentrification',
    kind: BusinessDistrictEventKind.gentrification,
    year: 2013,
    month: 7,
    day: 1,
    headline: '홍대 임대료 상승과 외연 확장',
    summary: '인기 점포가 밀려나고 상권이 인접 골목으로 넓어졌습니다.',
    durationMonths: 72,
    residualStrength: 0.42,
    targetDistrictIds: ['seoul_hongdae'],
    demandDelta: 0.05,
    rentDelta: 0.16,
    competitionDelta: 0.10,
    vacancyDelta: 0.04,
    riskDelta: 0.10,
    vitalityDelta: -2,
  ),
  const _BusinessDistrictEvent(
    id: 'sinchon_2015_campus_shift',
    kind: BusinessDistrictEventKind.universityShift,
    year: 2015,
    month: 3,
    day: 2,
    headline: '대학가 소비 동선 분산',
    summary: '학생 소비가 역세권·온라인·인접 문화 상권으로 나뉘었습니다.',
    durationMonths: 72,
    residualStrength: 0.58,
    targetDistrictIds: ['seoul_sinchon'],
    demandDelta: -0.10,
    rentDelta: -0.04,
    competitionDelta: -0.04,
    vacancyDelta: 0.11,
    riskDelta: 0.09,
    vitalityDelta: -10,
  ),
  const _BusinessDistrictEvent(
    id: 'seongsu_2016_culture_regeneration',
    kind: BusinessDistrictEventKind.regeneration,
    year: 2016,
    month: 6,
    day: 1,
    headline: '성수 문화·브랜드 공간 유입',
    summary: '낡은 공장과 창고가 카페·전시·브랜드 공간으로 전환됐습니다.',
    durationMonths: 84,
    residualStrength: 0.66,
    targetDistrictIds: ['seoul_seongsu'],
    demandDelta: 0.17,
    rentDelta: 0.14,
    competitionDelta: 0.11,
    vacancyDelta: -0.12,
    riskDelta: 0.04,
    vitalityDelta: 17,
  ),
  const _BusinessDistrictEvent(
    id: 'euljiro_2017_hipjiro',
    kind: BusinessDistrictEventKind.gentrification,
    year: 2017,
    month: 5,
    day: 1,
    headline: '을지로 골목 문화 확산',
    summary: '제조 골목에 야간 문화 수요가 유입됐지만 임대료 갈등도 커졌습니다.',
    durationMonths: 72,
    residualStrength: 0.48,
    targetDistrictIds: ['seoul_euljiro'],
    demandDelta: 0.14,
    rentDelta: 0.13,
    competitionDelta: 0.09,
    vacancyDelta: -0.07,
    riskDelta: 0.07,
    vitalityDelta: 12,
  ),
  const _BusinessDistrictEvent(
    id: 'suwon_2018_station_redevelopment',
    kind: BusinessDistrictEventKind.redevelopment,
    year: 2018,
    month: 11,
    day: 1,
    headline: '수원역 일대 재편',
    summary: '복합 상업시설과 보행 동선 정비가 구도심 유동을 재배치했습니다.',
    durationMonths: 72,
    residualStrength: 0.52,
    targetDistrictIds: ['gyeonggi_suwon_station'],
    demandDelta: 0.10,
    rentDelta: 0.08,
    competitionDelta: 0.07,
    vacancyDelta: -0.07,
    vitalityDelta: 9,
  ),
  const _BusinessDistrictEvent(
    id: 'gwacheon_2019_office_departure',
    kind: BusinessDistrictEventKind.populationShift,
    year: 2019,
    month: 1,
    day: 1,
    headline: '행정 수요 공백',
    summary: '업무 인구 이동과 재건축 공백이 중앙 상권의 평일 수요를 낮췄습니다.',
    durationMonths: 48,
    demandDelta: -0.10,
    rentDelta: -0.06,
    competitionDelta: -0.04,
    vacancyDelta: 0.12,
    riskDelta: 0.11,
    vitalityDelta: -10,
    targetDistrictIds: ['gyeonggi_gwacheon_central'],
  ),
  const _BusinessDistrictEvent(
    id: 'dongtan_2024_gtx',
    kind: BusinessDistrictEventKind.transitOpening,
    year: 2024,
    month: 3,
    day: 30,
    headline: '광역급행철도 연결',
    summary: '수도권 핵심 업무지구 접근성이 개선되며 역 주변 유동 기대가 커졌습니다.',
    durationMonths: 48,
    residualStrength: 0.56,
    targetDistrictIds: ['gyeonggi_dongtan'],
    demandDelta: 0.11,
    rentDelta: 0.09,
    competitionDelta: 0.07,
    vacancyDelta: -0.07,
    vitalityDelta: 10,
  ),
  for (final spec in _districtSpecs)
    _BusinessDistrictEvent(
      id: '${spec.id}_${spec.turningYear}_lifecycle',
      kind: switch (spec.trajectory) {
        _DistrictTrajectory.core => BusinessDistrictEventKind.rentSurge,
        _DistrictTrajectory.growth => BusinessDistrictEventKind.populationShift,
        _DistrictTrajectory.decline =>
          BusinessDistrictEventKind.onlineConsumption,
        _DistrictTrajectory.regeneration =>
          BusinessDistrictEventKind.redevelopment,
        _DistrictTrajectory.newTown =>
          BusinessDistrictEventKind.newTownOccupancy,
        _DistrictTrajectory.office => BusinessDistrictEventKind.officeCluster,
        _DistrictTrajectory.university =>
          BusinessDistrictEventKind.universityShift,
        _DistrictTrajectory.residential =>
          BusinessDistrictEventKind.populationShift,
        _DistrictTrajectory.tourism => BusinessDistrictEventKind.tourism,
      },
      year: spec.turningYear,
      month: 1,
      day: 1,
      headline: '${spec.name} 상권 전환점',
      summary: _trajectorySummary(spec),
      durationMonths: 48,
      residualStrength: 0.24,
      targetDistrictIds: [spec.id],
      demandDelta: spec.trajectory == _DistrictTrajectory.decline
          ? -0.05
          : 0.05,
      rentDelta: spec.trajectory == _DistrictTrajectory.decline ? -0.02 : 0.04,
      competitionDelta: spec.trajectory == _DistrictTrajectory.decline
          ? -0.02
          : 0.03,
      vacancyDelta: spec.trajectory == _DistrictTrajectory.decline
          ? 0.06
          : -0.04,
      riskDelta: spec.trajectory == _DistrictTrajectory.regeneration ? 0.04 : 0,
      vitalityDelta: spec.trajectory == _DistrictTrajectory.decline ? -5 : 5,
    ),
]);
