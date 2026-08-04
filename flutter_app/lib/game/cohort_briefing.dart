import 'game_state.dart';
import 'market_clock.dart';
import 'market_data.dart';

/// 08:00 조간신문 직후에 열리는 `오늘의 동기 브리핑`이다.
///
/// 여자 동기 8명이 거래일을 따라 한 명씩 돌아가며 자기 능력으로 오늘 판단에 쓸 관찰을
/// 하나 건넨다. 8명이 8거래일에 정확히 한 바퀴 돌기 때문에 월·화·수·목·금을 가로질러
/// 담당이 이동한다. 평일 저녁의 부동산·은행 실무(`weekday_activity.dart`)와는 다른
/// 슬롯이며 서로 시간을 소모하지 않는다.
///
/// 브리핑은 이미 공개된 사실만 쓴다. 오늘의 숨은 시나리오, 미래 종가, 영향률,
/// 성패 플래그는 입력으로 받지 않는다.
const cohortBriefingLogFlag = 'cohortBriefingLog';
const cohortBriefingLogLimit = 256;
const cohortBriefingRespectGain = 2;
const cohortBriefingResearchCreditGain = 1;
const cohortBriefingResearchCreditCap = 3;

/// 브리핑을 받아들일 때 얻는 것.
enum CohortBriefingReward {
  /// 동기의 방식을 같이 본다. 투자존중이 오른다.
  respect,

  /// 내 방식대로 확인한다. 다음 거래일 무료 조사보고서 이용권이 쌓인다.
  researchCredit,
}

class CohortBriefingChoice {
  const CohortBriefingChoice({
    required this.id,
    required this.label,
    required this.detail,
    required this.reward,
  });

  final String id;
  final String label;
  final String detail;
  final CohortBriefingReward reward;
}

class CohortBriefingDefinition {
  const CohortBriefingDefinition({
    required this.girlId,
    required this.name,
    required this.ability,
    required this.headline,
    required this.fallbackObservation,
    required this.choices,
  });

  final String girlId;
  final String name;

  /// 인물의 판단 출발점. `DECIMAL_WORLD.md`의 데시멀 역할을 그대로 따른다.
  final String ability;
  final String headline;

  /// 시장 데이터가 없을 때만 쓰는 기본 문장이다.
  final String fallbackObservation;
  final List<CohortBriefingChoice> choices;

  CohortBriefingChoice? choiceById(String id) {
    for (final choice in choices) {
      if (choice.id == id) return choice;
    }
    return null;
  }
}

/// 8명의 순번. 거래일 순서를 따라 이동하므로 특정 요일이 특정 인물에 고정되지 않는다.
const cohortBriefingRotation = <CohortBriefingDefinition>[
  CohortBriefingDefinition(
    girlId: 'jung_arin',
    name: '정아린',
    ability: '실행 순서와 마감',
    headline: '오늘 안건부터 정하자',
    fallbackObservation:
        '들어가는 건 쉬워도 나오는 순서가 없으면 끝이 엉킨다. 매수 전에 매도 조건을 먼저 적어 두는 게 오늘 안건이다.',
    choices: <CohortBriefingChoice>[
      CohortBriefingChoice(
        id: 'arin_write_exit',
        label: '매도 조건을 같이 적는다',
        detail: '아린이 목표가와 손절가 칸을 장부에 그려 준다.',
        reward: CohortBriefingReward.respect,
      ),
      CohortBriefingChoice(
        id: 'arin_own_order',
        label: '내 순서대로 간다',
        detail: '오늘은 스스로 정리하고 조사보고서 이용권을 챙긴다.',
        reward: CohortBriefingReward.researchCredit,
      ),
    ],
  ),
  CohortBriefingDefinition(
    girlId: 'kim_seoa',
    name: '김서아',
    ability: '신뢰 기록과 약속 이행',
    headline: '이 회사가 전에 한 말은 지켰어',
    fallbackObservation:
        '공책에 적어 둔 과거 공시와 실제 결과를 맞춰 봤다. 약속을 오래 지킨 쪽과 말만 바꾼 쪽이 갈린다.',
    choices: <CohortBriefingChoice>[
      CohortBriefingChoice(
        id: 'seoa_read_ledger',
        label: '공책을 같이 본다',
        detail: '서아가 기록 대조 방식을 보여 준다.',
        reward: CohortBriefingReward.respect,
      ),
      CohortBriefingChoice(
        id: 'seoa_verify_alone',
        label: '내가 직접 대조한다',
        detail: '기록은 참고만 하고 오늘 조사보고서를 아낀다.',
        reward: CohortBriefingReward.researchCredit,
      ),
    ],
  ),
  CohortBriefingDefinition(
    girlId: 'han_sua',
    name: '한수아',
    ability: '테마와 수요 전조',
    headline: '매출표엔 없는데 이름이 돌아',
    fallbackObservation:
        '어제 사람들이 같은 회사 이름을 서로 다른 자리에서 꺼냈다. 아직 숫자로는 안 보이는 이야기다.',
    choices: <CohortBriefingChoice>[
      CohortBriefingChoice(
        id: 'sua_listen_theme',
        label: '어디서 처음 들었는지 묻는다',
        detail: '수아가 소문 공책의 출처 칸을 보여 준다.',
        reward: CohortBriefingReward.respect,
      ),
      CohortBriefingChoice(
        id: 'sua_check_numbers',
        label: '숫자로 확인될 때까지 둔다',
        detail: '전조는 메모만 하고 이용권을 남긴다.',
        reward: CohortBriefingReward.researchCredit,
      ),
    ],
  ),
  CohortBriefingDefinition(
    girlId: 'oh_jiwoo',
    name: '오지우',
    ability: '반대 가설과 반례',
    headline: '모두 믿는 이야기의 반례입니다',
    fallbackObservation:
        '어제 가장 많이 오른 이유로 다들 같은 문장을 말했다. 그 문장이 틀리는 경우를 하나 준비했다.',
    choices: <CohortBriefingChoice>[
      CohortBriefingChoice(
        id: 'jiwoo_take_counter',
        label: '반례를 받아 적는다',
        detail: '지우가 반증 조건까지 같이 적어 준다.',
        reward: CohortBriefingReward.respect,
      ),
      CohortBriefingChoice(
        id: 'jiwoo_keep_thesis',
        label: '내 가설을 유지한다',
        detail: '반례는 남겨 두고 오늘은 내 근거로 간다.',
        reward: CohortBriefingReward.researchCredit,
      ),
    ],
  ),
  CohortBriefingDefinition(
    girlId: 'yoon_chaea',
    name: '윤채아',
    ability: '구조와 깨지는 조건',
    headline: '지금 계좌의 집중도를 봤어',
    fallbackObservation:
        '한 종목에 얼마가 몰렸고 그게 틀렸을 때 계좌가 어디까지 내려가는지 계산했다. 수익률보다 이 숫자가 먼저다.',
    choices: <CohortBriefingChoice>[
      CohortBriefingChoice(
        id: 'chaea_read_drawdown',
        label: '낙폭 계산을 같이 본다',
        detail: '채아가 깨지는 조건을 장부 옆에 적어 준다.',
        reward: CohortBriefingReward.respect,
      ),
      CohortBriefingChoice(
        id: 'chaea_hold_plan',
        label: '내 배분을 유지한다',
        detail: '계산은 참고만 하고 이용권을 챙긴다.',
        reward: CohortBriefingReward.researchCredit,
      ),
    ],
  ),
  CohortBriefingDefinition(
    girlId: 'park_haeun',
    name: '박하은',
    ability: '정보망과 말하지 못한 이해관계',
    headline: '어제 말이 막힌 쪽이 있었어',
    fallbackObservation:
        '좋은 소식만 위로 올라가는 곳은 숫자가 제일 늦게 망가진다. 어제 회의에서 아무도 반대하지 않은 자리가 있었다.',
    choices: <CohortBriefingChoice>[
      CohortBriefingChoice(
        id: 'haeun_ask_silence',
        label: '누가 말을 못 했는지 묻는다',
        detail: '하은이 사람 이름 대신 구조를 짚어 준다.',
        reward: CohortBriefingReward.respect,
      ),
      CohortBriefingChoice(
        id: 'haeun_focus_numbers',
        label: '숫자만 보고 간다',
        detail: '분위기는 접어 두고 이용권을 남긴다.',
        reward: CohortBriefingReward.researchCredit,
      ),
    ],
  ),
  CohortBriefingDefinition(
    girlId: 'lee_jian',
    name: '이지안',
    ability: '체결 구조와 실제 움직임',
    headline: '화면 숫자랑 실제 체결이 달랐어',
    fallbackObservation:
        '어제 원장을 열어 보니 표시된 잔량보다 적게 체결된 주문이 있었다. 손에 잡히는 결과만 믿는 게 낫다.',
    choices: <CohortBriefingChoice>[
      CohortBriefingChoice(
        id: 'jian_open_ledger',
        label: '원장을 같이 뜯어본다',
        detail: '지안이 체결가와 표시가의 차이를 짚어 준다.',
        reward: CohortBriefingReward.respect,
      ),
      CohortBriefingChoice(
        id: 'jian_trust_screen',
        label: '표시된 값으로 간다',
        detail: '오늘은 화면대로 주문하고 이용권을 아낀다.',
        reward: CohortBriefingReward.researchCredit,
      ),
    ],
  ),
  CohortBriefingDefinition(
    girlId: 'choi_iseo',
    name: '최이서',
    ability: '가격의 결과 감각적 이상치',
    headline: '어제 선 하나가 급했어',
    fallbackObservation:
        '가격선이 급하게 꺾일 때는 이유가 없어도 급한 티가 난다. 어제 그 결이 어긋난 자리가 있었다.',
    choices: <CohortBriefingChoice>[
      CohortBriefingChoice(
        id: 'iseo_read_line',
        label: '어디가 어긋났는지 본다',
        detail: '이서가 앞뒤 움직임을 관찰 문장으로 바꿔 준다.',
        reward: CohortBriefingReward.respect,
      ),
      CohortBriefingChoice(
        id: 'iseo_wait_signal',
        label: '느낌은 접어 둔다',
        detail: '검증되기 전까지 두고 이용권을 남긴다.',
        reward: CohortBriefingReward.researchCredit,
      ),
    ],
  ),
];

CohortBriefingDefinition? cohortBriefingByGirlId(String girlId) {
  for (final definition in cohortBriefingRotation) {
    if (definition.girlId == girlId) return definition;
  }
  return null;
}

/// 캠페인 시작일부터 세어 몇 번째 평일인지 돌려준다. 주말은 순번을 소비하지 않으므로
/// 8명이 8거래일에 한 바퀴 돈다.
int cohortBriefingWeekdayOrdinal(DateTime start, DateTime date) {
  final startDay = DateTime(start.year, start.month, start.day);
  final target = DateTime(date.year, date.month, date.day);
  final elapsed = target.difference(startDay).inDays;
  if (elapsed <= 0) return 0;
  final fullWeeks = elapsed ~/ 7;
  var ordinal = fullWeeks * 5;
  for (var offset = fullWeeks * 7; offset < elapsed; offset += 1) {
    final day = startDay.add(Duration(days: offset));
    if (day.weekday <= DateTime.friday) ordinal += 1;
  }
  return ordinal;
}

/// 오늘 브리핑을 맡은 동기. 휴장일과 주말에는 열지 않는다.
CohortBriefingDefinition? cohortBriefingForState(GameState state) {
  final date = state.currentDate;
  if (date.weekday > DateTime.friday) return null;
  if (!isMarketTradingDay(date)) return null;
  final ordinal = cohortBriefingWeekdayOrdinal(state.dateForDay(1), date);
  return cohortBriefingRotation[ordinal % cohortBriefingRotation.length];
}

class CohortBriefingLog {
  const CohortBriefingLog({
    required this.day,
    required this.girlId,
    required this.choiceId,
    required this.reward,
  });

  final int day;
  final String girlId;
  final String choiceId;
  final CohortBriefingReward reward;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'day': day,
    'girlId': girlId,
    'choiceId': choiceId,
    'reward': reward.name,
  };

  factory CohortBriefingLog.fromJson(Map<String, dynamic> json) =>
      CohortBriefingLog(
        day: ((json['day'] as num?)?.toInt() ?? 0).clamp(0, 0x7fffffff),
        girlId: json['girlId'] as String? ?? '',
        choiceId: json['choiceId'] as String? ?? '',
        reward: CohortBriefingReward.values.firstWhere(
          (value) => value.name == json['reward'],
          orElse: () => CohortBriefingReward.respect,
        ),
      );
}

List<CohortBriefingLog> cohortBriefingLogsForState(GameState state) =>
    ((state.story.storyFlags[cohortBriefingLogFlag] as List?) ??
            const <dynamic>[])
        .whereType<Map>()
        .map((item) => CohortBriefingLog.fromJson(item.cast<String, dynamic>()))
        .where((log) => log.day > 0 && log.girlId.isNotEmpty)
        .toList(growable: false);

/// 같은 날 두 번 받지 않는다.
bool cohortBriefingCompletedForDay(GameState state, int day) =>
    cohortBriefingLogsForState(state).any((log) => log.day == day);

// ---------------------------------------------------------------------------
// 실제 시장에서 생성하는 브리핑
// ---------------------------------------------------------------------------

/// 담당 동기와 그가 오늘 실제로 짚은 관찰 한 줄.
class CohortBriefing {
  const CohortBriefing({
    required this.definition,
    required this.observation,
    this.focusAssetId = '',
    this.focusAssetName = '',
  });

  final CohortBriefingDefinition definition;

  /// 오늘 시장·계좌·원장에서 생성된 문장. 데이터가 없으면 기본 문장을 쓴다.
  final String observation;
  final String focusAssetId;
  final String focusAssetName;

  String get girlId => definition.girlId;
  String get name => definition.name;
  String get headline => definition.headline;
  List<CohortBriefingChoice> get choices => definition.choices;
}

String _briefingSignedPercent(double value) =>
    '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)}%';

/// 브리핑은 08:00에 열리므로 오늘 종가를 쓰지 않는다. 직전 거래일까지만 읽는다.
DateTime cohortBriefingPublicThrough(DateTime date) {
  var probe = date.subtract(const Duration(days: 1));
  for (var guard = 0; guard < 21; guard += 1) {
    if (isMarketTradingDay(probe)) return probe;
    probe = probe.subtract(const Duration(days: 1));
  }
  return probe;
}

double? _dailyChangePercent(FictionalMarketAsset asset, DateTime asOf) {
  final history = asset.historyThrough(asOf, count: 2);
  if (history.length < 2) return null;
  final previous = history[history.length - 2].close;
  final last = history.last.close;
  if (previous <= 0) return null;
  return (last - previous) / previous * 100;
}

List<FictionalMarketAsset> _tradableAssets(
  FictionalMarketUniverse universe,
  DateTime asOf,
) => universe.assets
    .where((asset) => asset.quoteAtOrBefore(asOf) != null)
    .toList(growable: false);

/// 어제 등락률이 가장 큰 종목. [absolute]면 방향과 무관하게 가장 급한 종목을 고른다.
FictionalMarketAsset? _sharpestMover(
  List<FictionalMarketAsset> assets,
  DateTime asOf, {
  bool absolute = false,
  Set<String> excludeIds = const <String>{},
}) {
  FictionalMarketAsset? best;
  var bestScore = 0.0;
  for (final asset in assets) {
    if (excludeIds.contains(asset.id)) continue;
    final change = _dailyChangePercent(asset, asOf);
    if (change == null) continue;
    final score = absolute ? change.abs() : change;
    if (best == null || score > bestScore) {
      best = asset;
      bestScore = score;
    }
  }
  return best;
}

/// 오늘 담당 동기가 실제 시장을 읽고 만든 브리핑. 휴장·주말이면 null이다.
CohortBriefing? buildCohortBriefing(
  GameState state, {
  required FictionalMarketUniverse universe,
}) {
  final definition = cohortBriefingForState(state);
  if (definition == null) return null;
  return _buildCohortBriefingForDefinition(
    state,
    universe: universe,
    definition: definition,
  );
}

/// 데시멀톡에서 특정 동기의 능력으로 공개 정보만 읽을 때 사용한다.
/// 일일 브리핑 순번과 무관하지만 정보 기준일은 똑같이 직전 거래일까지다.
CohortBriefing? buildCohortAbilityBriefing(
  GameState state, {
  required FictionalMarketUniverse universe,
  required String girlId,
}) {
  final definition = cohortBriefingByGirlId(girlId);
  if (definition == null) return null;
  return _buildCohortBriefingForDefinition(
    state,
    universe: universe,
    definition: definition,
  );
}

CohortBriefing _buildCohortBriefingForDefinition(
  GameState state, {
  required FictionalMarketUniverse universe,
  required CohortBriefingDefinition definition,
}) {
  final asOf = cohortBriefingPublicThrough(state.currentDate);
  final assets = _tradableAssets(universe, asOf);
  final byId = <String, FictionalMarketAsset>{
    for (final asset in assets) asset.id: asset,
  };

  String observation = definition.fallbackObservation;
  var focusId = '';
  var focusName = '';

  void focus(FictionalMarketAsset asset, String text) {
    focusId = asset.id;
    focusName = asset.name;
    observation = text;
  }

  // 어제 실제로 공개된 사건. 숨은 영향률(impactPct)과 조사보고서 힌트(signal,
  // reportHint)는 유료·비공개이므로 해설에 쓰지 않는다.
  final events = fictionalMarketEventsForDate(
    state.simulationSeed,
    asOf,
  ).where((event) => byId.containsKey(event.companyId)).toList(growable: false);

  // 대표 사건은 어제 가장 크게 움직인 종목의 사건으로 고정한다.
  FictionalMarketEvent? headline;
  var headlineMove = 0.0;
  for (final event in events) {
    final change = _dailyChangePercent(byId[event.companyId]!, asOf);
    if (change == null) continue;
    if (headline == null || change.abs() > headlineMove.abs()) {
      headline = event;
      headlineMove = change;
    }
  }
  final headlineAsset = headline == null ? null : byId[headline.companyId];
  final moveLabel = _briefingSignedPercent(headlineMove);

  switch (definition.girlId) {
    // 신뢰 기록. 어제 소식이 난 회사가 전에도 말을 지켰는지로 설명한다.
    case 'kim_seoa':
      if (headline != null && headlineAsset != null) {
        final published = headlineAsset.financials
            .where((snapshot) => snapshot.consensusOperatingProfit != 0)
            .toList(growable: false);
        final surprise = published.isEmpty
            ? null
            : published.last.earningsSurprisePct;
        final trail = surprise == null
            ? '이 회사는 아직 대조할 실적 기록이 없어. 이번 말이 처음이야'
            : surprise >= 0
            ? '이 회사는 지난 실적에서도 컨센서스를 ${_briefingSignedPercent(surprise)} 넘겼어. 말한 걸 지켜 온 쪽이야'
            : '그런데 이 회사는 지난 실적에서 컨센서스를 ${_briefingSignedPercent(surprise)} 밑돌았어. 말과 결과가 어긋난 적이 있어';
        focus(
          headlineAsset,
          '어제 ${headlineAsset.name}에 「${headline.title}」 소식이 나고 $moveLabel였어. '
          '$trail. 그래서 어제 오른 건 소식보다 기록을 믿은 사람들이야.',
        );
      } else {
        observation = '어제는 공개된 소식이 없었어. 그런데도 가격이 움직였다면 기록이 아니라 분위기가 움직인 거야.';
      }

    // 구조. 어제 움직임이 개별 회사 얘기였는지 업종 전체였는지로 설명한다.
    case 'yoon_chaea':
      if (headline != null && headlineAsset != null) {
        final peers = assets
            .where(
              (asset) =>
                  asset.sector == headlineAsset.sector &&
                  asset.id != headlineAsset.id,
            )
            .toList(growable: false);
        var sameWay = 0;
        for (final peer in peers) {
          final change = _dailyChangePercent(peer, asOf);
          if (change == null) continue;
          if ((change >= 0) == (headlineMove >= 0) && change.abs() >= 1) {
            sameWay += 1;
          }
        }
        focus(
          headlineAsset,
          sameWay >= 2
              ? '어제 움직인 건 ${headlineAsset.name} 하나가 아니야. ${headlineAsset.sector} 쪽에서 $sameWay종목이 같은 방향으로 갔어. 개별 회사 소식이 아니라 업종 구조 얘기라는 뜻이야.'
              : '어제 ${headlineAsset.name}만 $moveLabel 갔고 같은 ${headlineAsset.sector} 종목들은 따라오지 않았어. 업종이 아니라 이 회사 하나의 사정이야. 그러면 소식이 틀렸을 때 되돌 폭도 이 회사만의 몫이야.',
        );
      } else {
        observation =
            '어제 공개된 사건이 없어. 사건 없이 움직인 날은 수급이 움직인 날이야. 이유를 회사에서 찾으면 못 찾아.';
      }

    // 반례. 어제 소식이 결과인지 계획인지 단계로 구분한다.
    case 'oh_jiwoo':
      if (headline != null && headlineAsset != null) {
        final settled = headline.stage >= 2;
        focus(
          headlineAsset,
          settled
              ? '어제 ${headlineAsset.name} 소식은 결과가 나온 단계입니다. $moveLabel 움직인 건 그럴 만해요. 다만 결과 뒤에는 더 나올 소식이 없다는 것도 같이 봐야죠.'
              : '어제 ${headlineAsset.name} 소식은 아직 계획 단계입니다. 「${headline.eyebrow}」라고 적혀 있지만 확정된 게 아니에요. 그런데 가격은 $moveLabel로 결과처럼 반응했습니다. 그게 반례입니다.',
        );
      } else {
        observation =
            '어제 공개된 사건이 하나도 없습니다. 그런데도 다들 이유를 말하고 있어요. 그게 제일 흔한 반례입니다.';
      }

    // 전조. 소식이 가격을 만들었는지, 가격이 소식을 앞질렀는지로 설명한다.
    case 'han_sua':
      if (headline != null && headlineAsset != null) {
        final history = headlineAsset.historyThrough(asOf, count: 5);
        var priorSameWay = 0;
        for (var index = 1; index < history.length - 1; index += 1) {
          final previous = history[index - 1].close;
          if (previous <= 0) continue;
          final step = (history[index].close - previous) / previous * 100;
          if ((step >= 0) == (headlineMove >= 0) && step.abs() >= 0.5) {
            priorSameWay += 1;
          }
        }
        focus(
          headlineAsset,
          priorSameWay >= 2
              ? '어제 ${headlineAsset.name} 소식이 났는데, 가격은 그 전 $priorSameWay거래일부터 이미 같은 방향이었어. 소식이 가격을 만든 게 아니라 누가 먼저 알고 있었다는 얘기야.'
              : '어제 소식이 나고 그때 처음 $moveLabel 움직였어. 이건 진짜로 어제 알려진 소식이야. 이런 건 오늘도 더 번질 수 있어.',
        );
      } else {
        observation =
            '어제는 아무 소식도 없었어. 그런데 사람들이 어떤 이름을 말하기 시작하면 그게 소식보다 먼저 오는 거야.';
      }

    // 체결 구조. 어제 움직임의 크기를 그날 가격제한폭과 대조해 설명한다.
    case 'lee_jian':
      if (headline != null && headlineAsset != null) {
        final limit = asOf.isBefore(DateTime(2015, 6, 15)) ? 15.0 : 30.0;
        final ratio = headlineMove.abs() / limit * 100;
        focus(
          headlineAsset,
          ratio >= 60
              ? '어제 ${headlineAsset.name}은 $moveLabel이야. 그날 가격제한폭의 ${ratio.toStringAsFixed(0)}%까지 간 거야. 이 정도면 중간 호가가 비어서 한 번에 뛴 구간이 있었을 거야. 표시된 값으로 산 사람은 더 비싸게 샀어.'
              : '어제 ${headlineAsset.name} $moveLabel은 제한폭의 ${ratio.toStringAsFixed(0)}% 정도야. 호가를 차례로 밟고 간 움직임이라 표시가랑 체결가가 크게 벌어지지는 않았어.',
        );
      } else {
        observation = '어제 공개된 사건이 없어. 사건 없이 가격만 움직이면 호가가 얇아서 밀린 경우가 많아.';
      }

    // 결. 어제 움직임이 하루에 몰렸는지 여러 날에 걸쳤는지로 설명한다.
    case 'choi_iseo':
      final mover =
          headlineAsset ?? _sharpestMover(assets, asOf, absolute: true);
      final change = mover == null
          ? null
          : (headlineAsset != null
                ? headlineMove
                : _dailyChangePercent(mover, asOf));
      if (mover != null && change != null) {
        final history = mover.historyThrough(asOf, count: 4);
        var quiet = 0;
        for (var index = 1; index < history.length - 1; index += 1) {
          final previous = history[index - 1].close;
          if (previous <= 0) continue;
          if (((history[index].close - previous) / previous * 100).abs() < 2) {
            quiet += 1;
          }
        }
        focus(
          mover,
          quiet >= 2
              ? '${mover.name}은 앞 며칠 조용했는데 어제 하루에 ${_briefingSignedPercent(change)}가 다 몰렸어. 결이 갑자기 달라진 건 사람 손이 급했다는 뜻이야. 급한 선은 되돌기도 급해.'
              : '${mover.name}은 어제 ${_briefingSignedPercent(change)}였는데 그 앞도 계속 같은 결이었어. 이건 하루짜리 놀람이 아니라 이어지는 흐름이야.',
        );
      }

    // 실행 순서. 어제 소식을 오늘 어떻게 다룰지 순서로 바꿔 준다.
    case 'jung_arin':
      if (headline != null && headlineAsset != null) {
        focus(
          headlineAsset,
          '어제 ${headlineAsset.name} 소식이 나고 $moveLabel 움직였어. 어제 난 소식이면 오늘 들어가는 건 이미 한발 늦은 거야. '
          '들어갈지 말지보다 어디서 나올지를 먼저 적어. 그 칸이 비어 있으면 오늘은 손대지 마.',
        );
      } else {
        final held = state.positions.where((p) => p.units > 0).length;
        observation = held > 0
            ? '어제 소식이 없었으니 오늘 새로 살 이유도 없어. 대신 들고 있는 $held종목의 나올 조건부터 채워.'
            : '어제 소식이 없었어. 살 이유가 없는 날은 순서를 정리하는 날이야.';
      }

    // 정보망. 어제 아홉 명이 한 방향으로 몰렸는지로 설명한다.
    case 'park_haeun':
      final report = state.cohortInvestments.reportForDay(state.day - 1);
      final traded = report?.rows
          .where((row) => !row.isPlayer && row.traded && row.assetId.isNotEmpty)
          .toList();
      if (traded != null && traded.isNotEmpty) {
        final counts = <String, int>{};
        final names = <String, String>{};
        for (final row in traded) {
          counts[row.assetId] = (counts[row.assetId] ?? 0) + 1;
          names[row.assetId] = row.assetName;
        }
        var topId = '';
        var topCount = 0;
        for (final entry in counts.entries) {
          if (entry.value > topCount ||
              (entry.value == topCount && entry.key.compareTo(topId) < 0)) {
            topId = entry.key;
            topCount = entry.value;
          }
        }
        observation = topCount >= 3
            ? '어제 아홉 명 중 $topCount명이 ${names[topId]} 하나였어. 좋은 소식이 한 방향으로만 돈 거야. 반대로 본 사람이 없었다는 게 제일 위험한 신호야.'
            : '어제는 아홉 명이 ${counts.length}종목으로 흩어졌어. 같은 소식을 서로 다르게 읽었다는 뜻이야. 이런 날은 누가 맞았는지보다 왜 갈렸는지가 남아.';
      } else if (headline != null && headlineAsset != null) {
        observation =
            '어제 ${headlineAsset.name} 소식은 다들 같은 자리에서 들었을 거야. '
            '같은 데서 들은 얘기는 이미 가격에 들어가 있어.';
      }
  }

  return CohortBriefing(
    definition: definition,
    observation: observation,
    focusAssetId: focusId,
    focusAssetName: focusName,
  );
}
