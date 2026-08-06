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

const horseGallopChestnutBlazeAsset =
    'assets/images/horse_racing/horse_gallop_chestnut_blaze_crimson_v3.png';
const horseGallopChestnutStarAsset =
    'assets/images/horse_racing/horse_gallop_chestnut_star_tealgold_v3.png';
const horseGallopDarkBayBlazeAsset =
    'assets/images/horse_racing/horse_gallop_darkbay_blaze_cobalt_v3.png';
const horseGallopDarkBayRavenAsset =
    'assets/images/horse_racing/horse_gallop_darkbay_raven_burgundy_v3.png';
const horseGallopGrayDappleAsset =
    'assets/images/horse_racing/horse_gallop_gray_dapple_purple_v3.png';
const horseGallopGrayFleabittenAsset =
    'assets/images/horse_racing/horse_gallop_gray_fleabitten_amber_v3.png';
const horseGallopWhiteSilverAsset =
    'assets/images/horse_racing/horse_gallop_white_silver_navy_v3.png';
const horseGallopWhiteCreamAsset =
    'assets/images/horse_racing/horse_gallop_white_cream_burgundy_v3.png';
const horseGallopBlackStarAsset =
    'assets/images/horse_racing/horse_gallop_black_star_emerald_v3.png';
const horseGallopBlackBlazeAsset =
    'assets/images/horse_racing/horse_gallop_black_blaze_royalgold_v3.png';
const horseGallopPalominoGoldAsset =
    'assets/images/horse_racing/horse_gallop_palomino_gold_violet_v3.png';
const horseGallopPalominoChampagneAsset =
    'assets/images/horse_racing/horse_gallop_palomino_champagne_turquoise_v3.png';
const horseGallopPintoTobianoAsset =
    'assets/images/horse_racing/horse_gallop_pinto_tobiano_coral_v3.png';
const horseGallopPintoOveroAsset =
    'assets/images/horse_racing/horse_gallop_pinto_overo_forest_v3.png';
const horseGallopMahoganyBloodBayAsset =
    'assets/images/horse_racing/horse_gallop_mahogany_bloodbay_cobalt_v3.png';
const horseGallopMahoganyCopperAsset =
    'assets/images/horse_racing/horse_gallop_mahogany_copper_mustard_v3.png';

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

const horseRaceGallopAssetFamilies = <List<String>>[
  <String>[
    horseGallopChestnutAsset,
    horseGallopChestnutBlazeAsset,
    horseGallopChestnutStarAsset,
  ],
  <String>[
    horseGallopDarkBayAsset,
    horseGallopDarkBayBlazeAsset,
    horseGallopDarkBayRavenAsset,
  ],
  <String>[
    horseGallopGrayAsset,
    horseGallopGrayDappleAsset,
    horseGallopGrayFleabittenAsset,
  ],
  <String>[
    horseGallopWhiteAsset,
    horseGallopWhiteSilverAsset,
    horseGallopWhiteCreamAsset,
  ],
  <String>[
    horseGallopBlackAsset,
    horseGallopBlackStarAsset,
    horseGallopBlackBlazeAsset,
  ],
  <String>[
    horseGallopPalominoAsset,
    horseGallopPalominoGoldAsset,
    horseGallopPalominoChampagneAsset,
  ],
  <String>[
    horseGallopPintoAsset,
    horseGallopPintoTobianoAsset,
    horseGallopPintoOveroAsset,
  ],
  <String>[
    horseGallopMahoganyAsset,
    horseGallopMahoganyBloodBayAsset,
    horseGallopMahoganyCopperAsset,
  ],
];

const horseRaceAllGallopAssets = <String>[
  horseGallopChestnutAsset,
  horseGallopChestnutBlazeAsset,
  horseGallopChestnutStarAsset,
  horseGallopDarkBayAsset,
  horseGallopDarkBayBlazeAsset,
  horseGallopDarkBayRavenAsset,
  horseGallopGrayAsset,
  horseGallopGrayDappleAsset,
  horseGallopGrayFleabittenAsset,
  horseGallopWhiteAsset,
  horseGallopWhiteSilverAsset,
  horseGallopWhiteCreamAsset,
  horseGallopBlackAsset,
  horseGallopBlackStarAsset,
  horseGallopBlackBlazeAsset,
  horseGallopPalominoAsset,
  horseGallopPalominoGoldAsset,
  horseGallopPalominoChampagneAsset,
  horseGallopPintoAsset,
  horseGallopPintoTobianoAsset,
  horseGallopPintoOveroAsset,
  horseGallopMahoganyAsset,
  horseGallopMahoganyBloodBayAsset,
  horseGallopMahoganyCopperAsset,
];

const horseRaceMinStake = 500;
const horseRaceStakeUnit = 500;
const horseRaceStakePercents = <int>[2, 5, 10, 30];
const horseRaceMaximumStakePercent = 30;
const horseRaceLeisureStakeBasisCap = 50000000;
const horseRaceDailyBetLimit = 1;
const horseRaceDefaultStateRecoveryRateBps = 2000;

int horseRaceStakeBasisForCash(int availableCash) =>
    math.min(math.max(0, availableCash), horseRaceLeisureStakeBasisCap);

int horseRaceMaximumStakeForCash(int availableCash) {
  final stakeBasis = horseRaceStakeBasisForCash(availableCash);
  if (stakeBasis <= 0) return 0;
  final proportional = stakeBasis * horseRaceMaximumStakePercent ~/ 100;
  return proportional ~/ horseRaceStakeUnit * horseRaceStakeUnit;
}

int horseRaceStakeForCashPercent(int availableCash, int percent) {
  if (!horseRaceStakePercents.contains(percent)) return 0;
  final proportional =
      horseRaceStakeBasisForCash(availableCash) * percent ~/ 100;
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
    required this.origin,
    required this.sex,
    required this.age,
    required this.jockey,
    required this.trainer,
    required this.assignedWeight,
    required this.runningStyle,
    required this.recentPerformances,
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
  final String origin;
  final String sex;
  final int age;
  final String jockey;
  final String trainer;
  final double assignedWeight;
  final String runningStyle;
  final List<HorseRecentPerformance> recentPerformances;
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

  List<int> get recentFinishes => List<int>.unmodifiable(
    recentPerformances.map((performance) => performance.position),
  );
  String get recentForm => recentFinishes.take(3).join('-');
  int get recentWinCount => recentFinishes.where((rank) => rank == 1).length;
  int get recentTopTwoCount => recentFinishes.where((rank) => rank <= 2).length;
  int get recentTopThreeCount =>
      recentFinishes.where((rank) => rank <= 3).length;
}

class HorseRecentPerformance {
  const HorseRecentPerformance({
    required this.date,
    required this.distanceMeters,
    required this.position,
    required this.fieldSize,
    required this.jockey,
    required this.assignedWeight,
    required this.recordSeconds,
    required this.bodyWeight,
    required this.rating,
  });

  final DateTime date;
  final int distanceMeters;
  final int position;
  final int fieldSize;
  final String jockey;
  final double assignedWeight;
  final double recordSeconds;
  final int bodyWeight;
  final int rating;
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

const _anchorHorseTemplates = <_HorseTemplate>[
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

const _horseRosterPrefixes = <String>[
  '라온',
  '천지',
  '해피',
  '원더풀',
  '글로벌',
  '드림',
  '로열',
  '스타',
  '블루',
  '골드',
  '실버',
  '파워',
  '스카이',
  '히어로',
  '퀸',
  '킹',
  '챔프',
  '빅토리',
  '다이아',
  '미라클',
  '판타스틱',
  '브라이트',
  '슈퍼',
  '에이스',
  '태양',
  '한강',
  '백두',
  '청룡',
];

const _horseRosterSuffixes = <String>[
  '러시',
  '스톰',
  '웨이브',
  '글로리',
  '오닉스',
  '메테오',
  '체크',
  '블레이즈',
];

const _horseRosterJockeys = <String>[
  '김태성',
  '이수호',
  '박건우',
  '최민재',
  '정우람',
  '오성민',
  '윤지환',
  '한도윤',
  '서지민',
  '민재호',
  '강준혁',
  '배도현',
  '문예찬',
  '노승우',
  '임도하',
  '송하준',
];

const _horseRosterAccentValues = <int>[
  0xFFF5F5F5,
  0xFF20232A,
  0xFFE54848,
  0xFF2E68D4,
  0xFFF2C94C,
  0xFF4CAD68,
  0xFFF18A42,
  0xFFF185AD,
];

final List<_HorseTemplate> _horseTemplates = _buildHorseTemplateRoster();

int _horseVisualFamilyIndex(String spriteAsset) => horseRaceGallopAssetFamilies
    .indexWhere((family) => family.contains(spriteAsset));

List<_HorseTemplate> _buildHorseTemplateRoster() {
  final roster = <_HorseTemplate>[..._anchorHorseTemplates];
  for (
    var familyIndex = 0;
    familyIndex < horseRaceGallopAssetFamilies.length;
    familyIndex++
  ) {
    final family = horseRaceGallopAssetFamilies[familyIndex];
    var generatedIndex = 0;
    while (roster
            .where(
              (template) =>
                  _horseVisualFamilyIndex(template.spriteAsset) == familyIndex,
            )
            .length <
        28) {
      final prefix =
          _horseRosterPrefixes[generatedIndex % _horseRosterPrefixes.length];
      final name = '$prefix${_horseRosterSuffixes[familyIndex]}';
      final id =
          'roster_${familyIndex.toString().padLeft(2, '0')}_${generatedIndex.toString().padLeft(2, '0')}';
      final seed = horseRaceStableSeed('$id:$name');
      final speed = 74 + seed % 26;
      final acceleration = 74 + (seed ~/ 7) % 26;
      final stamina = 74 + (seed ~/ 13) % 26;
      final finishingKick = 74 + (seed ~/ 19) % 26;
      final consistency = 70 + (seed ~/ 23) % 30;
      final recentFirst = 1 + (seed ~/ 29) % 8;
      final recentSecond = 1 + (seed ~/ 31) % 9;
      final recentThird = 1 + (seed ~/ 37) % 10;
      roster.add(
        _HorseTemplate(
          id: id,
          name: name,
          jockey:
              _horseRosterJockeys[(seed ~/ 41) % _horseRosterJockeys.length],
          runningStyle: const <String>[
            '선행',
            '선입',
            '추입',
            '지구력',
            '자유',
          ][(seed ~/ 43) % 5],
          recentForm: '$recentFirst-$recentSecond-$recentThird',
          bodyWeight: 458 + (seed ~/ 47) % 45,
          weightChange: -4 + (seed ~/ 53) % 9,
          accentValue: _horseRosterAccentValues[familyIndex],
          spriteAsset: family[generatedIndex % family.length],
          speed: speed,
          acceleration: acceleration,
          stamina: stamina,
          finishingKick: finishingKick,
          consistency: consistency,
        ),
      );
      generatedIndex += 1;
    }
  }
  return List<_HorseTemplate>.unmodifiable(roster);
}

int horseRaceStableSeed(String value) {
  var hash = 0x811C9DC5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  return hash;
}

const _horseRacePaceBreaks = <double>[0, 0.12, 0.30, 0.52, 0.70, 0.86, 1];

/// The pace segment where this runner makes its strongest deterministic move.
///
/// Keeping this public lets the broadcast presentation fire its sound and
/// visual cue on the exact frame where the underlying pace profile changes.
int horseRaceBroadcastBurstSegment({
  required HorseRaceCard race,
  required HorseRaceEntrant entrant,
}) {
  final profileSeed = horseRaceStableSeed(
    '${race.seed}:${entrant.id}:straight-pace',
  );
  return switch (entrant.runningStyle) {
    '선행' => profileSeed.isEven ? 0 : 1,
    '선입' => 2 + profileSeed % 2,
    '추입' => 4 + profileSeed % 2,
    '지구력' => 3 + profileSeed % 2,
    _ => 1 + profileSeed % 4,
  };
}

/// Normalized official-race time when the runner's strongest move begins.
double horseRaceBroadcastSurgeAt({
  required HorseRaceCard race,
  required HorseRaceEntrant entrant,
}) {
  final segment = horseRaceBroadcastBurstSegment(race: race, entrant: entrant);
  return (_horseRacePaceBreaks[segment] *
          horseRaceBroadcastFinishAt(race: race, entrant: entrant))
      .clamp(0.0, 0.94);
}

String horseRaceBroadcastSurgeLabel(HorseRaceEntrant entrant) =>
    horseRaceSignatureSkill(entrant).name;

class HorseRaceSignatureSkill {
  const HorseRaceSignatureSkill({
    required this.name,
    required this.effectLabel,
    required this.triggerLabel,
    required this.phaseLabel,
    required this.paceBoost,
  });

  final String name;
  final String effectLabel;
  final String triggerLabel;
  final String phaseLabel;
  final double paceBoost;

  String get strengthGrade => paceBoost >= 0.32
      ? 'S'
      : paceBoost >= 0.29
      ? 'A'
      : paceBoost >= 0.26
      ? 'B'
      : 'C';
}

const _horseRaceSkillPrefixes = <String>[
  '새벽',
  '자홍',
  '청명',
  '백야',
  '금빛',
  '은하',
  '유리',
  '여명',
  '낙뢰',
  '질풍',
  '열화',
  '설원',
  '월광',
  '폭풍',
  '흑운',
  '찬란',
];

const _horseRaceSkillCores = <String>[
  '점화',
  '선봉',
  '궤적',
  '맥동',
  '돌파',
  '역전',
  '유성',
  '비상',
  '폭주',
  '숨결',
  '파동',
  '서약',
  '환영',
  '왕관',
];

/// One stable, roster-wide unique signature skill per horse.
///
/// The 16 x 14 name table maps exactly to the 224-horse stable without
/// borrowing names or copy from another game. The condition follows the
/// horse's running style, while its relevant ability changes the real pace
/// boost used by the broadcast simulation.
HorseRaceSignatureSkill horseRaceSignatureSkill(HorseRaceEntrant entrant) {
  final rosterIndex = _horseTemplates.indexWhere(
    (template) => template.id == entrant.id,
  );
  final identityIndex = rosterIndex < 0
      ? horseRaceStableSeed('${entrant.id}:signature-skill') %
            (_horseRaceSkillPrefixes.length * _horseRaceSkillCores.length)
      : rosterIndex;
  final prefix =
      _horseRaceSkillPrefixes[identityIndex % _horseRaceSkillPrefixes.length];
  final core =
      _horseRaceSkillCores[(identityIndex ~/ _horseRaceSkillPrefixes.length) %
          _horseRaceSkillCores.length];
  final relevantAbility = switch (entrant.runningStyle) {
    '선행' => entrant.acceleration,
    '선입' => ((entrant.speed + entrant.acceleration) / 2).round(),
    '추입' => entrant.finishingKick,
    '지구력' => entrant.stamina,
    _ => ((entrant.speed + entrant.consistency) / 2).round(),
  };
  final identityVariation =
      horseRaceStableSeed('${entrant.id}:signature-power') % 5 * 0.005;
  final paceBoost =
      (0.22 +
              (relevantAbility - 74).clamp(0, 25) / 25 * 0.11 +
              identityVariation)
          .clamp(0.22, 0.35)
          .toDouble();
  final effectLabel = switch (entrant.runningStyle) {
    '선행' => '초반 선두권에서 가속·속도 상승',
    '선입' => '중반 추월 구간에서 가속 상승',
    '추입' => '막판 직선에서 최고속도 상승',
    '지구력' => '중후반 지구력을 살려 속도 유지',
    _ => '직선 빈 공간에서 속도·가속 상승',
  };
  final triggerLabel = switch (entrant.runningStyle) {
    '선행' => '출발 후 선두권에 진입하면 발동',
    '선입' => '중반에 앞말을 추월할 때 발동',
    '추입' => '남은 300m에서 후방 추격 시 발동',
    '지구력' => '중후반 페이스를 유지하면 발동',
    _ => '직선에서 앞 공간이 열리면 발동',
  };
  final phaseLabel = switch (entrant.runningStyle) {
    '선행' => '초반',
    '선입' => '중반',
    '추입' => '막판',
    '지구력' => '중후반',
    _ => '전개 대응',
  };
  return HorseRaceSignatureSkill(
    name: '$prefix의 $core',
    effectLabel: effectLabel,
    triggerLabel: triggerLabel,
    phaseLabel: phaseLabel,
    paceBoost: paceBoost,
  );
}

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
  final burstSegment = horseRaceBroadcastBurstSegment(
    race: race,
    entrant: entrant,
  );

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
        ? horseRaceSignatureSkill(entrant).paceBoost
        : (segment - burstSegment).abs() == 1
        ? 0.08
        : 0.0;
    speeds[segment] = math.max(
      0.42,
      speeds[segment] + variation + abilityFit + burst,
    );
  }

  // Do not let a wide official margin turn into a horse treading in place a
  // few pixels before the stripe. Keep the recorded finish time, but reserve
  // enough distance for a clearly readable final approach. The runner stays
  // farther behind until the last segment and then crosses at a continuous,
  // visible speed instead of waiting beside the finish line.
  final finalSegmentDuration =
      _horseRacePaceBreaks.last -
      _horseRacePaceBreaks[_horseRacePaceBreaks.length - 2];
  var precedingDistance = 0.0;
  for (var segment = 0; segment < speeds.length - 1; segment++) {
    precedingDistance +=
        (_horseRacePaceBreaks[segment + 1] - _horseRacePaceBreaks[segment]) *
        speeds[segment];
  }
  // Once the broadcast camera settles on the finish stripe, a normalized
  // speed near 1.0 reads as a crawl on a phone-sized track. Reserve much more
  // of the distance for the last 14% so trailing runners are already spread
  // out before the line, then make every horse gallop through it at speed.
  const minimumFinalNormalizedSpeed = 3.0;
  final minimumFinalSegmentSpeed =
      minimumFinalNormalizedSpeed *
      precedingDistance /
      (1 - minimumFinalNormalizedSpeed * finalSegmentDuration);
  speeds[speeds.length - 1] = math.max(speeds.last, minimumFinalSegmentSpeed);

  final cumulativeDistance = <double>[0.0];
  for (var segment = 0; segment < speeds.length; segment++) {
    final start = _horseRacePaceBreaks[segment];
    final end = _horseRacePaceBreaks[segment + 1];
    final segmentDistance = (end - start) * speeds[segment];
    cumulativeDistance.add(cumulativeDistance.last + segmentDistance);
  }

  // Join the pace sections with a monotone cubic curve. The old piecewise
  // linear distance curve changed velocity on a single frame at every section
  // boundary, which could read as a tiny hitch even though the horse never
  // actually stopped. Harmonic tangents preserve every section distance and
  // the official finish time while keeping both position and velocity smooth.
  final tangents = List<double>.filled(speeds.length + 1, 0);
  tangents.first = speeds.first;
  tangents.last = speeds.last;
  for (var knot = 1; knot < speeds.length; knot++) {
    final previousWidth =
        _horseRacePaceBreaks[knot] - _horseRacePaceBreaks[knot - 1];
    final nextWidth =
        _horseRacePaceBreaks[knot + 1] - _horseRacePaceBreaks[knot];
    final previousSlope = speeds[knot - 1];
    final nextSlope = speeds[knot];
    final previousWeight = 2 * nextWidth + previousWidth;
    final nextWeight = nextWidth + 2 * previousWidth;
    tangents[knot] =
        (previousWeight + nextWeight) /
        (previousWeight / previousSlope + nextWeight / nextSlope);
  }

  var activeSegment = speeds.length - 1;
  for (var segment = 0; segment < speeds.length; segment++) {
    if (raceTime <= _horseRacePaceBreaks[segment + 1]) {
      activeSegment = segment;
      break;
    }
  }
  final start = _horseRacePaceBreaks[activeSegment];
  final end = _horseRacePaceBreaks[activeSegment + 1];
  final width = end - start;
  final unit = ((raceTime - start) / width).clamp(0.0, 1.0);
  final unitSquared = unit * unit;
  final unitCubed = unitSquared * unit;
  final startBasis = 2 * unitCubed - 3 * unitSquared + 1;
  final startTangentBasis = unitCubed - 2 * unitSquared + unit;
  final endBasis = -2 * unitCubed + 3 * unitSquared;
  final endTangentBasis = unitCubed - unitSquared;
  final coveredDistance =
      startBasis * cumulativeDistance[activeSegment] +
      startTangentBasis * width * tangents[activeSegment] +
      endBasis * cumulativeDistance[activeSegment + 1] +
      endTangentBasis * width * tangents[activeSegment + 1];
  return (coveredDistance / cumulativeDistance.last).clamp(0.0, 1.0);
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

// Eight-horse thoroughbred markets generally see the public favourite win
// roughly one race in three. Keeping the market and result on the same
// temperature makes the displayed odds honest instead of letting the
// top-rated horse win far more often than its shown probability.
const double _horseRaceMarketTemperature = 3.7;

double _horseRaceGumbel(math.Random random) {
  final uniform = random.nextDouble().clamp(0.000000001, 0.999999999);
  return -math.log(-math.log(uniform));
}

double _roundOdds(double value) => double.parse(value.toStringAsFixed(1));

int _assessedHorseAbility(int base, math.Random random) =>
    math.max(70, math.min(99, base + random.nextInt(5) - 2));

const _horseRaceTrainerNames = <String>[
  '박준호',
  '이경민',
  '최용건',
  '서인석',
  '정호익',
  '김동균',
  '전승규',
  '강환민',
];

List<HorseRecentPerformance> _baselineHorseRecentPerformances(
  _HorseTemplate template,
) {
  final latest = template.recentForm
      .split('-')
      .map(int.parse)
      .toList(growable: true);
  final random = math.Random(
    horseRaceStableSeed('${template.id}:official-recent-ten'),
  );
  final baseAbility = horseRaceCompositeScore(
    speed: template.speed,
    acceleration: template.acceleration,
    stamina: template.stamina,
    finishingKick: template.finishingKick,
    consistency: template.consistency,
  );
  while (latest.length < 10) {
    final fieldSize = 8 + random.nextInt(5);
    final expectedRank =
        1 + ((100 - baseAbility) / 25).clamp(0.0, 1.0) * (fieldSize - 1);
    final volatility = 0.9 + (100 - template.consistency) * 0.055;
    final rank = (expectedRank + _horseRaceGaussian(random) * volatility)
        .round()
        .clamp(1, fieldSize);
    latest.add(rank);
  }
  final performances = <HorseRecentPerformance>[];
  final campaignStartDate = DateTime(2000, 1, 1);
  var daysAgo = 0;
  const distances = <int>[1000, 1200, 1300, 1400, 1600, 1800];
  for (var index = 0; index < latest.length; index++) {
    daysAgo += 15 + random.nextInt(27);
    final position = latest[index];
    final fieldSize = math.max(position, 8 + random.nextInt(7));
    final distance = distances[random.nextInt(distances.length)];
    final baseSeconds = distance * 0.0605;
    final recordSeconds = baseSeconds + position * 0.19 + random.nextDouble();
    performances.add(
      HorseRecentPerformance(
        date: campaignStartDate.subtract(Duration(days: daysAgo)),
        distanceMeters: distance,
        position: position,
        fieldSize: fieldSize,
        jockey: index < 6
            ? template.jockey
            : _horseRosterJockeys[random.nextInt(_horseRosterJockeys.length)],
        assignedWeight: 51.0 + random.nextInt(15) * 0.5,
        recordSeconds: recordSeconds,
        bodyWeight: template.bodyWeight + random.nextInt(13) - 6,
        rating: (baseAbility + random.nextInt(7) - 3).round().clamp(70, 99),
      ),
    );
  }
  return List<HorseRecentPerformance>.unmodifiable(performances);
}

List<_HorseTemplate> _scheduledHorseTemplates({
  required String simulationSeed,
  required int day,
}) {
  final selectedTemplates = <_HorseTemplate>[];
  for (
    var familyIndex = 0;
    familyIndex < horseRaceGallopAssetFamilies.length;
    familyIndex++
  ) {
    final candidates = _horseTemplates
        .where(
          (template) =>
              _horseVisualFamilyIndex(template.spriteAsset) == familyIndex,
        )
        .toList(growable: false);
    final zeroBasedDay = math.max(0, day - 1);
    final fortnightBlock = zeroBasedDay ~/ 14;
    final rosterHalf = fortnightBlock.isEven ? 0 : 14;
    final cycle = fortnightBlock ~/ 2;
    final scheduled = candidates.sublist(rosterHalf, rosterHalf + 14).toList();
    scheduled.shuffle(
      math.Random(
        horseRaceStableSeed(
          '$simulationSeed:${horseRaceGallopAssets[familyIndex]}:cycle:$cycle',
        ),
      ),
    );
    selectedTemplates.add(scheduled[zeroBasedDay % 14]);
  }
  return selectedTemplates;
}

Map<String, List<HorseRecentPerformance>> _horseRecentPerformancesForField({
  required List<_HorseTemplate> selectedTemplates,
  required String simulationSeed,
  required int raceDay,
}) {
  final selectedIds = selectedTemplates.map((template) => template.id).toSet();
  final histories = <String, List<HorseRecentPerformance>>{
    for (final template in selectedTemplates)
      template.id: <HorseRecentPerformance>[],
  };

  // Every world race is deterministic and exists whether the player opened the
  // broadcast or not. Scanning backwards reconstructs exactly the same official
  // results after saving, loading, or fast-forwarding without bloating saves.
  for (var previousDay = raceDay - 1; previousDay >= 1; previousDay--) {
    if (histories.values.every((history) => history.length >= 10)) break;
    final historicalRace = _officialHorseRaceSnapshot(
      simulationSeed: simulationSeed,
      day: previousDay,
    );
    for (final entrant in historicalRace.entrants) {
      if (!selectedIds.contains(entrant.id)) continue;
      final history = histories[entrant.id]!;
      if (history.length >= 10) continue;
      history.add(
        HorseRecentPerformance(
          date: DateTime(2000, 1, 1).add(Duration(days: previousDay - 1)),
          distanceMeters: historicalRace.distanceMeters,
          position: historicalRace.finishPosition(entrant.id),
          fieldSize: historicalRace.entrants.length,
          jockey: entrant.jockey,
          assignedWeight: entrant.assignedWeight,
          recordSeconds: horseRaceFinishTimeSeconds(
            race: historicalRace,
            entrant: entrant,
          ),
          bodyWeight: entrant.bodyWeight,
          rating: entrant.compositeScore.round().clamp(70, 99),
        ),
      );
    }
  }

  for (final template in selectedTemplates) {
    final history = histories[template.id]!;
    history.addAll(_baselineHorseRecentPerformances(template));
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
  }
  return histories;
}

const _horseRaceSnapshotCacheLimit = 512;
final Map<String, HorseRaceCard> _horseRaceSnapshotCache =
    <String, HorseRaceCard>{};

HorseRaceCard _officialHorseRaceSnapshot({
  required String simulationSeed,
  required int day,
}) {
  final key = '$simulationSeed:$day';
  final cached = _horseRaceSnapshotCache.remove(key);
  if (cached != null) {
    _horseRaceSnapshotCache[key] = cached;
    return cached;
  }
  final snapshot = _buildAfternoonHorseRace(
    simulationSeed: simulationSeed,
    day: day,
    includeRecentPerformances: false,
  );
  while (_horseRaceSnapshotCache.length >= _horseRaceSnapshotCacheLimit) {
    _horseRaceSnapshotCache.remove(_horseRaceSnapshotCache.keys.first);
  }
  _horseRaceSnapshotCache[key] = snapshot;
  return snapshot;
}

String _horseOrigin(_HorseTemplate template) {
  final seed = horseRaceStableSeed('${template.id}:origin');
  return seed % 5 == 0 ? '미국' : '한국';
}

String _horseSex(_HorseTemplate template) {
  final seed = horseRaceStableSeed('${template.id}:sex');
  return const <String>['수', '암', '거'][seed % 3];
}

int _horseAge(_HorseTemplate template) =>
    3 + horseRaceStableSeed('${template.id}:age') % 4;

String _horseTrainer(_HorseTemplate template) =>
    _horseRaceTrainerNames[horseRaceStableSeed('${template.id}:trainer') %
        _horseRaceTrainerNames.length];

double _horseAssignedWeight(double compositeScore) =>
    ((52.0 + (compositeScore - 82) * 0.28).clamp(51.0, 58.0) * 2).round() / 2;

HorseRaceCard buildAfternoonHorseRace({
  required String simulationSeed,
  required int day,
}) => _buildAfternoonHorseRace(
  simulationSeed: simulationSeed,
  day: day,
  includeRecentPerformances: true,
);

HorseRaceCard _buildAfternoonHorseRace({
  required String simulationSeed,
  required int day,
  required bool includeRecentPerformances,
}) {
  final seed = horseRaceStableSeed('$simulationSeed:$day:seoul-turf-1510');
  final random = math.Random(seed);
  final selectedTemplates = _scheduledHorseTemplates(
    simulationSeed: simulationSeed,
    day: day,
  );
  selectedTemplates.shuffle(random);

  final recentPerformancesById = includeRecentPerformances
      ? _horseRecentPerformancesForField(
          selectedTemplates: selectedTemplates,
          simulationSeed: simulationSeed,
          raceDay: day,
        )
      : const <String, List<HorseRecentPerformance>>{};

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
    // Gumbel-max sampling gives each runner the same actual winning chance as
    // the probability used by the tote board, while still allowing any runner
    // to win and producing a deterministic result for a saved race day.
    final finalScore =
        compositeScore / _horseRaceMarketTemperature + _horseRaceGumbel(random);
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
        (draft.compositeScore - strongestScore) / _horseRaceMarketTemperature,
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
        origin: _horseOrigin(template),
        sex: _horseSex(template),
        age: _horseAge(template),
        jockey: template.jockey,
        trainer: _horseTrainer(template),
        assignedWeight: _horseAssignedWeight(draft.compositeScore),
        runningStyle: template.runningStyle,
        recentPerformances:
            recentPerformancesById[template.id] ??
            const <HorseRecentPerformance>[],
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
