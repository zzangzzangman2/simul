import 'dart:math' as math;

const horseRaceBackgroundAsset =
    'assets/images/horse_racing/bg_seoul_turf_afternoon_2000_v1.png';
const horseRaceStraightTrackAsset =
    'assets/images/horse_racing/bg_straight_side_track_panorama_2000_v2.png';
const horseRaceCurveTrackAsset =
    'assets/images/horse_racing/bg_curve_rear_broadcast_2000_v1.png';
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
const horseCurveChestnutAsset =
    'assets/images/horse_racing/horse_curve_chestnut_red_v1.png';
const horseCurveDarkBayAsset =
    'assets/images/horse_racing/horse_curve_darkbay_blue_v1.png';
const horseCurveGrayAsset =
    'assets/images/horse_racing/horse_curve_gray_yellow_v1.png';
const horseCurveWhiteAsset =
    'assets/images/horse_racing/horse_curve_white_navyrose_v1.png';
const horseCurveBlackAsset =
    'assets/images/horse_racing/horse_curve_black_emerald_v1.png';
const horseCurvePalominoAsset =
    'assets/images/horse_racing/horse_curve_palomino_violet_v1.png';
const horseCurvePintoAsset =
    'assets/images/horse_racing/horse_curve_pinto_coral_v1.png';
const horseCurveMahoganyAsset =
    'assets/images/horse_racing/horse_curve_mahogany_cobalt_v1.png';

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

const horseRaceCurveGallopAssets = <String>[
  horseCurveChestnutAsset,
  horseCurveDarkBayAsset,
  horseCurveGrayAsset,
  horseCurveWhiteAsset,
  horseCurveBlackAsset,
  horseCurvePalominoAsset,
  horseCurvePintoAsset,
  horseCurveMahoganyAsset,
];

String horseRaceCurveGallopAssetFor(String sideAsset) => switch (sideAsset) {
  horseGallopChestnutAsset => horseCurveChestnutAsset,
  horseGallopDarkBayAsset => horseCurveDarkBayAsset,
  horseGallopGrayAsset => horseCurveGrayAsset,
  horseGallopWhiteAsset => horseCurveWhiteAsset,
  horseGallopBlackAsset => horseCurveBlackAsset,
  horseGallopPalominoAsset => horseCurvePalominoAsset,
  horseGallopPintoAsset => horseCurvePintoAsset,
  horseGallopMahoganyAsset => horseCurveMahoganyAsset,
  _ => throw ArgumentError.value(sideAsset, 'sideAsset', 'Unknown horse sheet'),
};

const horseRaceMinStake = 500;
const horseRaceMaxStake = 5000;
const horseRaceDefaultStateRecoveryRateBps = 2000;

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
  if (stake < horseRaceMinStake || stake > horseRaceMaxStake) return 0;
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
