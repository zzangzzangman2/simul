import 'dart:math' as math;

import 'game_state.dart';

const horseRaceBackgroundAsset =
    'assets/images/horse_racing/bg_paddock_parade_softpainted_2000_v4.png';
const horseRacePhotoFinishAsset =
    'assets/images/horse_racing/bg_photo_finish_softpainted_2000_v2.png';
const horseRaceOfficialResultBoardAsset =
    'assets/images/horse_racing/ui_official_result_board_softpainted_v1.png';
const horseRaceTellerWelcomeAsset =
    'assets/images/horse_racing/teller_window_welcome_age20_v1.png';
const horseRaceTellerGuideAsset =
    'assets/images/horse_racing/teller_window_bet_guide_age20_v1.png';
const horseRaceTellerAcceptAsset =
    'assets/images/horse_racing/teller_window_bet_accept_age20_v1.png';
const horseRaceTellerHandoverAsset =
    'assets/images/horse_racing/teller_window_ticket_handover_age20_v1.png';
const horseRaceStraightTrackAsset =
    'assets/images/horse_racing/bg_straight_side_track_finish_panorama_2000_v4.png';
const horseGallopChestnutAsset =
    'assets/images/horse_racing/horse_gallop_chestnut_red_v1.png';
const horseGallopDarkBayAsset =
    'assets/images/horse_racing/horse_gallop_darkbay_blue_v1.png';
const horseGallopGrayAsset =
    'assets/images/horse_racing/horse_gallop_gray_yellow_v1.png';
const horseGallopWhiteAsset =
    'assets/images/horse_racing/horse_gallop_white_navyrose_v2.png';
const horseGallopBlackAsset =
    'assets/images/horse_racing/horse_gallop_black_emerald_v2.png';
const horseGallopPalominoAsset =
    'assets/images/horse_racing/horse_gallop_palomino_violet_v2.png';
const horseGallopPintoAsset =
    'assets/images/horse_racing/horse_gallop_pinto_coral_v2.png';
const horseGallopMahoganyAsset =
    'assets/images/horse_racing/horse_gallop_mahogany_cobalt_v2.png';

const horseRaceGallopAssets = <String>[
  horseGallopChestnutAsset,
  horseGallopDarkBayAsset,
  horseGallopGrayAsset,
  horseGallopWhiteAsset,
  horseGallopBlackAsset,
  horseGallopPalominoAsset,
  horseGallopPintoAsset,
  horseGallopMahoganyAsset,
];

const horseRaceMinStake = 500;
const horseRaceStakeUnit = 500;
const horseRaceStakePercents = <int>[2, 5, 10, 30];
const horseRaceMaximumStakePercent = 30;
const horseRaceDailyBetLimit = 1;
const horseRaceDefaultStateRecoveryRateBps = 2000;

int horseRaceMaximumStakeForCash(int availableCash) {
  if (availableCash <= 0) return 0;
  final proportional = availableCash * horseRaceMaximumStakePercent ~/ 100;
  return proportional ~/ horseRaceStakeUnit * horseRaceStakeUnit;
}

int horseRaceStakeForCashPercent(int availableCash, int percent) {
  if (!horseRaceStakePercents.contains(percent)) return 0;
  final proportional = availableCash * percent ~/ 100;
  final rounded = proportional ~/ horseRaceStakeUnit * horseRaceStakeUnit;
  return rounded >= horseRaceMinStake ? rounded : 0;
}

bool isValidHorseRaceStake(int stake, int availableCash) =>
    stake >= horseRaceMinStake &&
    stake % horseRaceStakeUnit == 0 &&
    stake <= horseRaceMaximumStakeForCash(availableCash);

int horseRaceBetsForDay(GameState state, int day) => state.ledger
    .where(
      (entry) =>
          entry.day == day &&
          entry.counterAccount == 'horse_racing_wager_expense',
    )
    .map((entry) => entry.sourceId)
    .toSet()
    .length;

int horseRaceBetsToday(GameState state) =>
    horseRaceBetsForDay(state, state.day);

bool horseRaceDailyLimitReached(GameState state) =>
    horseRaceBetsToday(state) >= horseRaceDailyBetLimit;

class HorseRaceActionResult {
  const HorseRaceActionResult({
    required this.state,
    required this.success,
    required this.message,
    this.cashDelta = 0,
  });

  final GameState state;
  final bool success;
  final String message;
  final int cashDelta;

  HorseRaceActionResult withState(GameState next) => HorseRaceActionResult(
    state: next,
    success: success,
    message: message,
    cashDelta: cashDelta,
  );
}

int horseRaceStateProfitFee({
  required int stake,
  required int grossPayout,
  int recoveryRateBps = horseRaceDefaultStateRecoveryRateBps,
}) {
  final confirmedProfit = math.max(0, grossPayout - stake);
  if (confirmedProfit <= 0) return 0;
  final safeRate = recoveryRateBps.clamp(0, 10000);
  return (confirmedProfit * safeRate / 10000).round().clamp(0, confirmedProfit);
}

enum HorseBetType { win, place, quinella }

extension HorseBetTypePresentation on HorseBetType {
  String get label => switch (this) {
    HorseBetType.win => '단승',
    HorseBetType.place => '연승',
    HorseBetType.quinella => '복승',
  };

  String get description => switch (this) {
    HorseBetType.win => '선택한 말이 1위',
    HorseBetType.place => '선택한 말이 3위 안',
    HorseBetType.quinella => '선택한 두 말이 순서 없이 1·2위',
  };
}

class HorseRaceEntrant {
  const HorseRaceEntrant({
    required this.id,
    required this.gate,
    required this.name,
    required this.jockey,
    required this.runningStyle,
    required this.recentForm,
    required this.bodyWeight,
    required this.weightChange,
    required this.accentValue,
    required this.spriteAsset,
    required this.speed,
    required this.acceleration,
    required this.stamina,
    required this.finishingKick,
    required this.consistency,
    required this.compositeScore,
    required this.winProbability,
    required this.winOdds,
    required this.placeOdds,
    required this.finalScore,
  });

  final String id;
  final int gate;
  final String name;
  final String jockey;
  final String runningStyle;
  final String recentForm;
  final int bodyWeight;
  final int weightChange;
  final int accentValue;
  final String spriteAsset;
  final int speed;
  final int acceleration;
  final int stamina;
  final int finishingKick;
  final int consistency;
  final double compositeScore;
  final double winProbability;
  final double winOdds;
  final double placeOdds;
  final double finalScore;
}

class HorseRaceCard {
  const HorseRaceCard({
    required this.id,
    required this.seed,
    required this.entrants,
    required this.finishOrder,
    this.distanceMeters = 1200,
    this.postTime = '15:10',
    this.weather = '맑음',
    this.trackCondition = '양호',
  });

  final String id;
  final int seed;
  final int distanceMeters;
  final String postTime;
  final String weather;
  final String trackCondition;
  final List<HorseRaceEntrant> entrants;
  final List<String> finishOrder;

  HorseRaceEntrant entrantById(String id) =>
      entrants.firstWhere((entrant) => entrant.id == id);

  int finishPosition(String id) => finishOrder.indexOf(id) + 1;
}

class HorseRaceSessionResult {
  const HorseRaceSessionResult({
    required this.raceId,
    required this.betType,
    required this.primaryHorseId,
    required this.stake,
    required this.grossPayout,
    required this.finishOrder,
    this.secondaryHorseId,
    this.stateRecoveryRateBps = horseRaceDefaultStateRecoveryRateBps,
  });

  final String raceId;
  final HorseBetType betType;
  final String primaryHorseId;
  final String? secondaryHorseId;
  final int stake;
  final int grossPayout;
  final List<String> finishOrder;
  final int stateRecoveryRateBps;

  int get stateProfitFee => horseRaceStateProfitFee(
    stake: stake,
    grossPayout: grossPayout,
    recoveryRateBps: stateRecoveryRateBps,
  );

  int get netDelta => grossPayout - stake - stateProfitFee;
}

class _HorseTemplate {
  const _HorseTemplate({
    required this.id,
    required this.name,
    required this.jockey,
    required this.runningStyle,
    required this.recentForm,
    required this.bodyWeight,
    required this.weightChange,
    required this.accentValue,
    required this.spriteAsset,
    required this.speed,
    required this.acceleration,
    required this.stamina,
    required this.finishingKick,
    required this.consistency,
  });

  final String id;
  final String name;
  final String jockey;
  final String runningStyle;
  final String recentForm;
  final int bodyWeight;
  final int weightChange;
  final int accentValue;
  final String spriteAsset;
  final int speed;
  final int acceleration;
  final int stamina;
  final int finishingKick;
  final int consistency;
}

class _HorseRaceDraft {
  const _HorseRaceDraft({
    required this.template,
    required this.bodyWeight,
    required this.weightChange,
    required this.speed,
    required this.acceleration,
    required this.stamina,
    required this.finishingKick,
    required this.consistency,
    required this.compositeScore,
    required this.finalScore,
  });

  final _HorseTemplate template;
  final int bodyWeight;
  final int weightChange;
  final int speed;
  final int acceleration;
  final int stamina;
  final int finishingKick;
  final int consistency;
  final double compositeScore;
  final double finalScore;
}

const _horseTemplates = <_HorseTemplate>[
  _HorseTemplate(
    id: 'dawn_dash',
    name: '새벽질주',
    jockey: '김태성',
    runningStyle: '선행',
    recentForm: '2-1-4',
    bodyWeight: 474,
    weightChange: 2,
    accentValue: 0xFFF5F5F5,
    spriteAsset: horseGallopChestnutAsset,
    speed: 96,
    acceleration: 95,
    stamina: 82,
    finishingKick: 84,
    consistency: 91,
  ),
  _HorseTemplate(
    id: 'blue_comet',
    name: '블루코멧',
    jockey: '이수호',
    runningStyle: '선입',
    recentForm: '1-3-2',
    bodyWeight: 486,
    weightChange: -3,
    accentValue: 0xFF20232A,
    spriteAsset: horseGallopDarkBayAsset,
    speed: 92,
    acceleration: 86,
    stamina: 89,
    finishingKick: 94,
    consistency: 87,
  ),
  _HorseTemplate(
    id: 'silver_wave',
    name: '은빛파도',
    jockey: '박건우',
    runningStyle: '추입',
    recentForm: '5-2-1',
    bodyWeight: 468,
    weightChange: 1,
    accentValue: 0xFFE54848,
    spriteAsset: horseGallopGrayAsset,
    speed: 89,
    acceleration: 82,
    stamina: 88,
    finishingKick: 97,
    consistency: 81,
  ),
  _HorseTemplate(
    id: 'gangnam_storm',
    name: '강남스톰',
    jockey: '최민재',
    runningStyle: '선행',
    recentForm: '3-4-2',
    bodyWeight: 492,
    weightChange: 4,
    accentValue: 0xFF2E68D4,
    spriteAsset: horseGallopChestnutAsset,
    speed: 91,
    acceleration: 93,
    stamina: 78,
    finishingKick: 81,
    consistency: 80,
  ),
  _HorseTemplate(
    id: 'han_river_star',
    name: '한강의별',
    jockey: '정우람',
    runningStyle: '자유',
    recentForm: '4-3-5',
    bodyWeight: 459,
    weightChange: -1,
    accentValue: 0xFFF2C94C,
    spriteAsset: horseGallopDarkBayAsset,
    speed: 84,
    acceleration: 85,
    stamina: 93,
    finishingKick: 88,
    consistency: 92,
  ),
  _HorseTemplate(
    id: 'flying_heaven',
    name: '비상천',
    jockey: '오성민',
    runningStyle: '선입',
    recentForm: '6-1-3',
    bodyWeight: 480,
    weightChange: 0,
    accentValue: 0xFF4CAD68,
    spriteAsset: horseGallopGrayAsset,
    speed: 87,
    acceleration: 89,
    stamina: 83,
    finishingKick: 89,
    consistency: 76,
  ),
  _HorseTemplate(
    id: 'mudeung_range',
    name: '무등산맥',
    jockey: '윤지환',
    runningStyle: '지구력',
    recentForm: '7-5-2',
    bodyWeight: 501,
    weightChange: 3,
    accentValue: 0xFFF18A42,
    spriteAsset: horseGallopChestnutAsset,
    speed: 81,
    acceleration: 76,
    stamina: 97,
    finishingKick: 82,
    consistency: 95,
  ),
  _HorseTemplate(
    id: 'last_wind',
    name: '라스트윈드',
    jockey: '한도윤',
    runningStyle: '추입',
    recentForm: '8-6-1',
    bodyWeight: 465,
    weightChange: -2,
    accentValue: 0xFFF185AD,
    spriteAsset: horseGallopDarkBayAsset,
    speed: 84,
    acceleration: 79,
    stamina: 80,
    finishingKick: 96,
    consistency: 72,
  ),
  _HorseTemplate(
    id: 'snow_queen',
    name: '설원여왕',
    jockey: '서지민',
    runningStyle: '선입',
    recentForm: '1-2-3',
    bodyWeight: 470,
    weightChange: 1,
    accentValue: 0xFFDA6F9B,
    spriteAsset: horseGallopWhiteAsset,
    speed: 92,
    acceleration: 90,
    stamina: 86,
    finishingKick: 91,
    consistency: 89,
  ),
  _HorseTemplate(
    id: 'white_night_dream',
    name: '백야의꿈',
    jockey: '민재호',
    runningStyle: '추입',
    recentForm: '4-1-2',
    bodyWeight: 466,
    weightChange: -2,
    accentValue: 0xFF7D79B8,
    spriteAsset: horseGallopWhiteAsset,
    speed: 88,
    acceleration: 84,
    stamina: 90,
    finishingKick: 96,
    consistency: 84,
  ),
  _HorseTemplate(
    id: 'black_onyx',
    name: '블랙오닉스',
    jockey: '강준혁',
    runningStyle: '선행',
    recentForm: '2-2-1',
    bodyWeight: 493,
    weightChange: 3,
    accentValue: 0xFF238A5D,
    spriteAsset: horseGallopBlackAsset,
    speed: 95,
    acceleration: 94,
    stamina: 81,
    finishingKick: 85,
    consistency: 86,
  ),
  _HorseTemplate(
    id: 'dark_wind_king',
    name: '흑풍제왕',
    jockey: '배도현',
    runningStyle: '지구력',
    recentForm: '3-5-1',
    bodyWeight: 500,
    weightChange: 0,
    accentValue: 0xFF305B4B,
    spriteAsset: horseGallopBlackAsset,
    speed: 86,
    acceleration: 82,
    stamina: 96,
    finishingKick: 87,
    consistency: 93,
  ),
  _HorseTemplate(
    id: 'golden_hour',
    name: '골든아워',
    jockey: '문예찬',
    runningStyle: '자유',
    recentForm: '2-4-2',
    bodyWeight: 478,
    weightChange: -1,
    accentValue: 0xFF8A56BC,
    spriteAsset: horseGallopPalominoAsset,
    speed: 89,
    acceleration: 91,
    stamina: 88,
    finishingKick: 89,
    consistency: 88,
  ),
  _HorseTemplate(
    id: 'gold_meteor',
    name: '금빛유성',
    jockey: '노승우',
    runningStyle: '선입',
    recentForm: '5-2-2',
    bodyWeight: 482,
    weightChange: 2,
    accentValue: 0xFFC59B32,
    spriteAsset: horseGallopPalominoAsset,
    speed: 93,
    acceleration: 88,
    stamina: 84,
    finishingKick: 92,
    consistency: 80,
  ),
  _HorseTemplate(
    id: 'mosaic_run',
    name: '모자이크런',
    jockey: '임도하',
    runningStyle: '추입',
    recentForm: '6-3-1',
    bodyWeight: 469,
    weightChange: -3,
    accentValue: 0xFF35BFC1,
    spriteAsset: horseGallopPintoAsset,
    speed: 86,
    acceleration: 83,
    stamina: 87,
    finishingKick: 98,
    consistency: 79,
  ),
  _HorseTemplate(
    id: 'checkmate',
    name: '체크메이트',
    jockey: '송하준',
    runningStyle: '선행',
    recentForm: '1-5-4',
    bodyWeight: 487,
    weightChange: 4,
    accentValue: 0xFFE15E59,
    spriteAsset: horseGallopPintoAsset,
    speed: 94,
    acceleration: 96,
    stamina: 77,
    finishingKick: 82,
    consistency: 78,
  ),
  _HorseTemplate(
    id: 'red_toma_ru',
    name: '적토마루',
    jockey: '장태오',
    runningStyle: '선행',
    recentForm: '3-1-3',
    bodyWeight: 490,
    weightChange: 1,
    accentValue: 0xFF245FC7,
    spriteAsset: horseGallopMahoganyAsset,
    speed: 93,
    acceleration: 92,
    stamina: 85,
    finishingKick: 87,
    consistency: 85,
  ),
  _HorseTemplate(
    id: 'copper_blaze',
    name: '코퍼블레이즈',
    jockey: '백시윤',
    runningStyle: '추입',
    recentForm: '4-4-1',
    bodyWeight: 476,
    weightChange: -1,
    accentValue: 0xFFD69426,
    spriteAsset: horseGallopMahoganyAsset,
    speed: 87,
    acceleration: 85,
    stamina: 89,
    finishingKick: 95,
    consistency: 82,
  ),
];

int horseRaceStableSeed(String value) {
  var hash = 0x811C9DC5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  return hash;
}

const _horseRacePaceBreaks = <double>[0, 0.12, 0.30, 0.52, 0.70, 0.86, 1];

/// Returns the runner's deterministic position in the straight-only broadcast.
///
/// The official result still comes from [HorseRaceCard.finishOrder]. Running
/// style, ability and a stable per-runner burst only shape how that result is
/// revealed, so early leaders, midfield moves and late closers all read clearly.
double horseRaceBroadcastProgress({
  required HorseRaceCard race,
  required HorseRaceEntrant entrant,
  required double time,
}) {
  final finishRank = race.finishOrder.indexOf(entrant.id);
  if (finishRank < 0) return 0;

  // Use the same varied margins as the official record sheet. Real fields do
  // not arrive at mechanically even intervals: some places are a nose apart,
  // while a fading runner can finish several lengths behind the horse ahead.
  final finishAt = horseRaceBroadcastFinishAt(race: race, entrant: entrant);
  final raceTime = (time.clamp(0.0, 1.0) / finishAt).clamp(0.0, 1.0);
  if (raceTime <= 0) return 0;
  if (raceTime >= 1) return 1;

  final speeds = switch (entrant.runningStyle) {
    '선행' => <double>[1.70, 1.35, 1.02, 0.90, 1.02, 1.10],
    '선입' => <double>[0.98, 1.12, 1.48, 1.16, 1.03, 1.10],
    '추입' => <double>[0.70, 0.78, 0.88, 1.03, 1.45, 1.82],
    '지구력' => <double>[0.86, 0.98, 1.08, 1.18, 1.23, 1.25],
    _ => <double>[1.02, 1.08, 1.12, 1.08, 1.05, 1.10],
  };
  final profileSeed = horseRaceStableSeed(
    '${race.seed}:${entrant.id}:straight-pace',
  );
  final burstSegment = switch (entrant.runningStyle) {
    '선행' => profileSeed.isEven ? 0 : 1,
    '선입' => 2 + profileSeed % 2,
    '추입' => 4 + profileSeed % 2,
    '지구력' => 3 + profileSeed % 2,
    _ => 1 + profileSeed % 4,
  };

  for (var segment = 0; segment < speeds.length; segment++) {
    final segmentSeed = horseRaceStableSeed('$profileSeed:$segment');
    final variation = ((segmentSeed % 2001) / 1000 - 1) * 0.055;
    final accelerationFit = (entrant.acceleration - 85) / 15;
    final speedFit = (entrant.speed - 85) / 15;
    final staminaFit = (entrant.stamina - 85) / 15;
    final kickFit = (entrant.finishingKick - 85) / 15;
    final abilityFit = switch (segment) {
      0 => accelerationFit * 0.11 + speedFit * 0.03,
      1 => accelerationFit * 0.07 + speedFit * 0.06,
      2 => speedFit * 0.10 + accelerationFit * 0.03,
      3 => speedFit * 0.07 + staminaFit * 0.07,
      4 => staminaFit * 0.07 + kickFit * 0.10,
      _ => kickFit * 0.14 + staminaFit * 0.04,
    };
    final burst = segment == burstSegment
        ? 0.28
        : (segment - burstSegment).abs() == 1
        ? 0.08
        : 0.0;
    speeds[segment] = math.max(
      0.42,
      speeds[segment] + variation + abilityFit + burst,
    );
  }

  var totalDistance = 0.0;
  var coveredDistance = 0.0;
  for (var segment = 0; segment < speeds.length; segment++) {
    final start = _horseRacePaceBreaks[segment];
    final end = _horseRacePaceBreaks[segment + 1];
    final segmentDistance = (end - start) * speeds[segment];
    totalDistance += segmentDistance;
    final coveredTime = (math.min(raceTime, end) - start).clamp(
      0.0,
      end - start,
    );
    coveredDistance += coveredTime * speeds[segment];
  }
  return (coveredDistance / totalDistance).clamp(0.0, 1.0);
}

/// Deterministic official elapsed time used by the racecourse result board.
///
/// A 1,200 m winner runs roughly 1:11, with small race-specific variation.
/// Following runners receive stable, strictly increasing gaps so the same race
/// card always produces the same broadcast record sheet.
double horseRaceFinishTimeSeconds({
  required HorseRaceCard race,
  required HorseRaceEntrant entrant,
}) {
  final finishRank = race.finishOrder.indexOf(entrant.id);
  if (finishRank < 0) return 0;

  final recordSeed = horseRaceStableSeed('${race.seed}:${race.id}:record');
  final standardWinnerSeconds = 70.85 + (recordSeed % 136) / 100;
  final conditionAdjustment = switch (race.trackCondition) {
    '불량' => 1.15,
    '포화' => 0.72,
    '다습' => 0.34,
    _ => 0.0,
  };
  var elapsed =
      standardWinnerSeconds * (race.distanceMeters / 1200) +
      conditionAdjustment;
  for (var position = 1; position <= finishRank; position++) {
    elapsed += _horseRaceRecordGapSeconds(race, position);
  }
  return (elapsed * 100).round() / 100;
}

double _horseRaceRecordGapSeconds(HorseRaceCard race, int position) {
  final gapSeed = horseRaceStableSeed(
    '${race.seed}:${race.finishOrder[position]}:record-gap:$position',
  );
  final bucket = gapSeed % 100;
  final jitter = (gapSeed ~/ 100) % 7;
  final gap = switch (bucket) {
    < 12 => 0.07 + jitter * 0.01,
    < 38 => 0.14 + jitter * 0.015,
    < 67 => 0.24 + jitter * 0.02,
    < 86 => 0.38 + jitter * 0.03,
    < 96 => 0.58 + jitter * 0.04,
    < 99 => 0.88 + jitter * 0.05,
    _ => 1.22 + jitter * 0.08,
  };
  return (gap * 100).round() / 100;
}

/// Normalized moment when [entrant] reaches the broadcast finish stripe.
///
/// One second on the official record is kept close to one second in the
/// shortened 16-second broadcast. The winner is moved earlier when the field
/// is widely spread, so late runners never have to bunch up at the stripe.
double horseRaceBroadcastFinishAt({
  required HorseRaceCard race,
  required HorseRaceEntrant entrant,
}) {
  final finishRank = race.finishOrder.indexOf(entrant.id);
  if (finishRank < 0) return 1;

  var totalGapSeconds = 0.0;
  var entrantGapSeconds = 0.0;
  for (var position = 1; position < race.finishOrder.length; position++) {
    final gap = _horseRaceRecordGapSeconds(race, position);
    totalGapSeconds += gap;
    if (position <= finishRank) entrantGapSeconds += gap;
  }
  const broadcastGapScaleSeconds = 14.0;
  final winnerFinishAt = math.max(
    0.68,
    math.min(0.84, 0.995 - totalGapSeconds / broadcastGapScaleSeconds),
  );
  return math.min(
    0.995,
    winnerFinishAt + entrantGapSeconds / broadcastGapScaleSeconds,
  );
}

String horseRaceMarginLabel(double gapSeconds) {
  if (gapSeconds <= 0.06) return '코';
  if (gapSeconds <= 0.10) return '머리';
  if (gapSeconds <= 0.14) return '목';

  final quarters = math.max(2, (gapSeconds / 0.17 * 4).round());
  if (quarters >= 40) return '대차';
  final whole = quarters ~/ 4;
  final remainder = quarters % 4;
  final fraction = switch (remainder) {
    1 => '1/4',
    2 => '1/2',
    3 => '3/4',
    _ => '',
  };
  if (whole == 0) return fraction;
  return fraction.isEmpty ? '$whole' : '$whole $fraction';
}

String horseRaceRecordLabel(double seconds) {
  final hundredths = (seconds * 100).round();
  final minutes = hundredths ~/ 6000;
  final secondsPart = (hundredths % 6000) ~/ 100;
  final fraction = hundredths % 100;
  return '$minutes:${secondsPart.toString().padLeft(2, '0')}.'
      '${fraction.toString().padLeft(2, '0')}';
}

double horseRaceCompositeScore({
  required int speed,
  required int acceleration,
  required int stamina,
  required int finishingKick,
  required int consistency,
}) =>
    speed * 0.30 +
    acceleration * 0.24 +
    stamina * 0.18 +
    finishingKick * 0.18 +
    consistency * 0.10;

double _horseRaceGaussian(math.Random random) {
  final first = math.max(random.nextDouble(), 0.0000001);
  final second = random.nextDouble();
  return math.sqrt(-2 * math.log(first)) * math.cos(2 * math.pi * second);
}

double _roundOdds(double value) => double.parse(value.toStringAsFixed(1));

int _assessedHorseAbility(int base, math.Random random) =>
    math.max(70, math.min(99, base + random.nextInt(5) - 2));

HorseRaceCard buildAfternoonHorseRace({
  required String simulationSeed,
  required int day,
}) {
  final seed = horseRaceStableSeed('$simulationSeed:$day:seoul-turf-1510');
  final random = math.Random(seed);
  final selectedTemplates = <_HorseTemplate>[];
  for (final spriteAsset in horseRaceGallopAssets) {
    final candidates = _horseTemplates
        .where((template) => template.spriteAsset == spriteAsset)
        .toList(growable: false);
    final rotationSeed = horseRaceStableSeed(
      '$simulationSeed:$spriteAsset:roster',
    );
    selectedTemplates.add(candidates[(rotationSeed + day) % candidates.length]);
  }
  selectedTemplates.shuffle(random);

  final drafts = <_HorseRaceDraft>[];
  for (final template in selectedTemplates) {
    final speed = _assessedHorseAbility(template.speed, random);
    final acceleration = _assessedHorseAbility(template.acceleration, random);
    final stamina = _assessedHorseAbility(template.stamina, random);
    final finishingKick = _assessedHorseAbility(template.finishingKick, random);
    final consistency = _assessedHorseAbility(template.consistency, random);
    final bodyWeight = template.bodyWeight + random.nextInt(5) - 2;
    final weightChange = math.max(
      -6,
      math.min(6, template.weightChange + random.nextInt(5) - 2),
    );
    final compositeScore = horseRaceCompositeScore(
      speed: speed,
      acceleration: acceleration,
      stamina: stamina,
      finishingKick: finishingKick,
      consistency: consistency,
    );
    final condition = (random.nextDouble() - 0.5) * 4.0;
    final paceFit = switch (template.runningStyle) {
      '선행' => (random.nextDouble() - 0.5) * 2.2,
      '추입' => (random.nextDouble() - 0.5) * 2.8,
      '지구력' => (random.nextDouble() - 0.5) * 1.8,
      _ => (random.nextDouble() - 0.5) * 2.4,
    };
    final volatility = 1.15 + (100 - consistency) * 0.10;
    final finalScore =
        compositeScore +
        condition +
        paceFit +
        _horseRaceGaussian(random) * volatility;
    drafts.add(
      _HorseRaceDraft(
        template: template,
        bodyWeight: bodyWeight,
        weightChange: weightChange,
        speed: speed,
        acceleration: acceleration,
        stamina: stamina,
        finishingKick: finishingKick,
        consistency: consistency,
        compositeScore: compositeScore,
        finalScore: finalScore,
      ),
    );
  }

  final strongestScore = drafts
      .map((draft) => draft.compositeScore)
      .reduce(math.max);
  final marketWeights = <String, double>{
    for (final draft in drafts)
      draft.template.id: math.exp(
        (draft.compositeScore - strongestScore) / 3.2,
      ),
  };
  final marketWeightTotal = marketWeights.values.reduce((a, b) => a + b);
  final probabilityById = <String, double>{
    for (final draft in drafts)
      draft.template.id: marketWeights[draft.template.id]! / marketWeightTotal,
  };

  final oddsOrder = [...drafts]
    ..sort(
      (left, right) => probabilityById[right.template.id]!.compareTo(
        probabilityById[left.template.id]!,
      ),
    );
  final winOddsById = <String, double>{};
  final placeOddsById = <String, double>{};
  var previousWinOdds = 1.3;
  var previousPlaceOdds = 1.0;
  for (final draft in oddsOrder) {
    final probability = probabilityById[draft.template.id]!;
    var winOdds = _roundOdds((0.84 / probability).clamp(1.4, 99.9));
    if (winOdds <= previousWinOdds) {
      winOdds = _roundOdds(previousWinOdds + 0.1);
    }
    final placeProbability = (1 - math.pow(1 - probability, 3)).clamp(
      0.06,
      0.86,
    );
    var placeOdds = _roundOdds((0.88 / placeProbability).clamp(1.1, 12.0));
    if (placeOdds <= previousPlaceOdds) {
      placeOdds = _roundOdds(previousPlaceOdds + 0.1);
    }
    winOddsById[draft.template.id] = winOdds;
    placeOddsById[draft.template.id] = placeOdds;
    previousWinOdds = winOdds;
    previousPlaceOdds = placeOdds;
  }

  final entrants = <HorseRaceEntrant>[];
  for (var index = 0; index < drafts.length; index++) {
    final draft = drafts[index];
    final template = draft.template;
    entrants.add(
      HorseRaceEntrant(
        id: template.id,
        gate: index + 1,
        name: template.name,
        jockey: template.jockey,
        runningStyle: template.runningStyle,
        recentForm: template.recentForm,
        bodyWeight: draft.bodyWeight,
        weightChange: draft.weightChange,
        accentValue: template.accentValue,
        spriteAsset: template.spriteAsset,
        speed: draft.speed,
        acceleration: draft.acceleration,
        stamina: draft.stamina,
        finishingKick: draft.finishingKick,
        consistency: draft.consistency,
        compositeScore: draft.compositeScore,
        winProbability: probabilityById[template.id]!,
        winOdds: winOddsById[template.id]!,
        placeOdds: placeOddsById[template.id]!,
        finalScore: draft.finalScore,
      ),
    );
  }
  final ordered = [...entrants]
    ..sort((left, right) => right.finalScore.compareTo(left.finalScore));
  return HorseRaceCard(
    id: 'seoul-${day.toString().padLeft(5, '0')}-$seed',
    seed: seed,
    entrants: List<HorseRaceEntrant>.unmodifiable(entrants),
    finishOrder: List<String>.unmodifiable(
      ordered.map((entrant) => entrant.id),
    ),
  );
}

double horseRaceQuinellaOdds(
  HorseRaceCard race,
  String primaryId,
  String secondaryId,
) {
  if (primaryId == secondaryId) return 0;
  final primary = race.entrantById(primaryId);
  final secondary = race.entrantById(secondaryId);
  final firstThenSecond =
      primary.winProbability *
      secondary.winProbability /
      (1 - primary.winProbability);
  final secondThenFirst =
      secondary.winProbability *
      primary.winProbability /
      (1 - secondary.winProbability);
  final pairProbability = firstThenSecond + secondThenFirst;
  return _roundOdds((0.82 / pairProbability).clamp(2.1, 99.9));
}

int calculateHorseRacePayout({
  required HorseRaceCard race,
  required HorseBetType betType,
  required String primaryHorseId,
  required int stake,
  String? secondaryHorseId,
}) {
  if (stake < horseRaceMinStake || stake % horseRaceStakeUnit != 0) return 0;
  if (!race.entrants.any((entrant) => entrant.id == primaryHorseId)) return 0;
  final position = race.finishPosition(primaryHorseId);
  final primary = race.entrantById(primaryHorseId);
  final multiplier = switch (betType) {
    HorseBetType.win => position == 1 ? primary.winOdds : 0.0,
    HorseBetType.place =>
      position >= 1 && position <= 3 ? primary.placeOdds : 0.0,
    HorseBetType.quinella =>
      secondaryHorseId != null &&
              secondaryHorseId != primaryHorseId &&
              race.entrants.any((entrant) => entrant.id == secondaryHorseId) &&
              <String>{
                ...race.finishOrder.take(2),
              }.containsAll(<String>{primaryHorseId, secondaryHorseId})
          ? horseRaceQuinellaOdds(race, primaryHorseId, secondaryHorseId)
          : 0.0,
  };
  return (stake * multiplier).floor();
}
