import 'dart:math' as math;

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

String _briefingMoney(num value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer(rounded < 0 ? '-' : '');
  for (var index = 0; index < digits.length; index += 1) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
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

  switch (definition.girlId) {
    // 실행 순서. 보유 종목에 나올 가격이 적혀 있는지 본다.
    case 'jung_arin':
      final held = state.positions.where((p) => p.units > 0).toList()
        ..sort((a, b) => b.totalCost.compareTo(a.totalCost));
      if (held.isNotEmpty) {
        final position = held.first;
        final asset = byId[position.assetId];
        final close = asset?.quoteAtOrBefore(asOf)?.close;
        final average = position.averageCost;
        if (asset != null && close != null && average > 0) {
          final gap = (close - average) / average * 100;
          focus(
            asset,
            '${asset.name} ${position.units.round()}주, 평균 ${_briefingMoney(average)}원이야. '
            '어제 종가 ${_briefingMoney(close)}원이면 ${_briefingSignedPercent(gap)}. '
            '그런데 나올 가격은 아직 어디에도 안 적혀 있어.',
          );
        }
      } else {
        observation =
            '아직 보유 종목이 없네. 그러면 오늘은 살 종목보다 팔 조건을 먼저 정하자. 순서를 정해 두면 급할 때 안 엉켜.';
      }

    // 신뢰 기록. 공개된 실적이 컨센서스 약속을 지켰는지 본다.
    case 'kim_seoa':
      final candidates = <FictionalMarketAsset>[
        for (final position in state.positions)
          if (byId[position.assetId] != null) byId[position.assetId]!,
        ...assets,
      ];
      for (final asset in candidates) {
        final published = asset.financials
            .where((snapshot) => snapshot.consensusOperatingProfit != 0)
            .toList(growable: false);
        if (published.isEmpty) continue;
        final latest = published.last;
        final surprise = latest.earningsSurprisePct;
        final kept = surprise >= 0;
        focus(
          asset,
          '${asset.name}의 ${latest.period} 실적을 공책에 맞춰 봤어. '
          '영업이익이 컨센서스보다 ${_briefingSignedPercent(surprise)}였으니 '
          '${kept ? '말한 만큼은 지킨 쪽' : '말과 결과가 어긋난 쪽'}이야. 한 번으로 정하지는 말고.',
        );
        break;
      }

    // 테마 전조. 어제 크게 오른 종목 중 내가 안 가진 것.
    case 'han_sua':
      final heldIds = state.positions.map((p) => p.assetId).toSet();
      final mover = _sharpestMover(assets, asOf, excludeIds: heldIds);
      final change = mover == null ? null : _dailyChangePercent(mover, asOf);
      if (mover != null && change != null) {
        focus(
          mover,
          '어제 ${mover.name}이 ${_briefingSignedPercent(change)}였는데 우리 중에 아무도 안 들고 있어. '
          '${mover.sector} 쪽에서 이름이 돌기 시작한 것 같아. 아직 숫자로는 안 보이는 단계야.',
        );
      }

    // 반대 가설. 어제 가장 오른 종목이 그 전에도 같은 식으로 올랐다가 되돌았는지.
    case 'oh_jiwoo':
      final mover = _sharpestMover(assets, asOf);
      final change = mover == null ? null : _dailyChangePercent(mover, asOf);
      if (mover != null && change != null) {
        final history = mover.historyThrough(asOf, count: 5);
        var pullbacks = 0;
        for (var index = 1; index < history.length; index += 1) {
          if (history[index].close < history[index - 1].close) pullbacks += 1;
        }
        final pullbackNote = pullbacks == 0
            ? '최근 ${history.length}거래일 동안 한 번도 되돌지 않았어요. 그게 더 수상합니다'
            : '그런데 최근 ${history.length}거래일 중 $pullbacks일은 되돌았어요';
        focus(
          mover,
          '어제 ${mover.name}이 ${_briefingSignedPercent(change)}로 제일 많이 올랐습니다. '
          '$pullbackNote. '
          '오른 이유가 맞더라도, 그 이유가 오늘도 유효한지는 다른 질문입니다.',
        );
      }

    // 구조. 계좌 집중도와 그게 틀렸을 때의 낙폭.
    case 'yoon_chaea':
      final prices = <String, double>{
        for (final asset in assets)
          if (asset.quoteAtOrBefore(asOf) != null)
            asset.id: asset.quoteAtOrBefore(asOf)!.close,
      };
      final holdings = state.portfolioValue(prices);
      final total = holdings + state.brokerageCash;
      if (holdings > 0 && total > 0) {
        PortfolioPosition? top;
        var topValue = 0;
        for (final position in state.positions) {
          final price = prices[position.assetId];
          if (price == null) continue;
          final value = (position.units * price).round();
          if (top == null || value > topValue) {
            top = position;
            topValue = value;
          }
        }
        if (top != null) {
          final share = topValue / total * 100;
          final impact = share * 0.15;
          final asset = byId[top.assetId];
          final text =
              '지금 계좌의 ${share.toStringAsFixed(1)}%가 ${top.name} 하나야. '
              '그게 15% 빠지면 계좌 전체는 ${impact.toStringAsFixed(1)}% 줄어. '
              '수익률보다 이 숫자를 먼저 보는 게 맞아.';
          if (asset != null) {
            focus(asset, text);
          } else {
            observation = text;
          }
        }
      } else {
        observation =
            '보유가 없으니 오늘 낙폭은 0이야. 대신 첫 매수를 얼마로 할지가 그대로 집중도가 돼. '
            '예수금 ${_briefingMoney(state.brokerageCash)}원의 몇 퍼센트를 걸지 먼저 정해.';
      }

    // 정보망. 어제 결과표에서 손실이 컸던 동기.
    case 'park_haeun':
      final report = state.cohortInvestments.reportForDay(state.day - 1);
      final rows = report?.rows
          .where((row) => !row.isPlayer && row.traded)
          .toList();
      if (rows != null && rows.isNotEmpty) {
        rows.sort((a, b) => a.profitLoss.compareTo(b.profitLoss));
        final worst = rows.first;
        if (worst.profitLoss < 0) {
          observation =
              '어제 ${worst.name}이 ${_briefingMoney(worst.profitLoss)}원이었어. '
              '${worst.assetName} 쪽이었는데, 결과표에서는 한 줄이라 아무도 안 물어봤을 거야. '
              '먼저 말 걸어 주면 그 애 판단 이유도 같이 알 수 있어.';
        } else {
          observation =
              '어제는 아홉 명 다 손실이 없었어. 이럴 때가 오히려 위험해. '
              '아무도 반대하지 않은 자리가 어디였는지 같이 짚어 보자.';
        }
      }

    // 체결 구조. 어제 내 주문의 체결가와 그날 종가 차이.
    case 'lee_jian':
      final trades = state.ledger
          .where(
            (entry) =>
                entry.day == state.day - 1 &&
                (entry.tradeSide == 'buy' || entry.tradeSide == 'sell') &&
                entry.assetId.isNotEmpty &&
                entry.tradeUnitPrice > 0,
          )
          .toList(growable: false);
      LedgerEntry? worst;
      var worstGap = 0.0;
      for (final trade in trades) {
        final close = byId[trade.assetId]?.quoteAtOrBefore(asOf)?.close;
        if (close == null) continue;
        final gap = trade.tradeSide == 'buy'
            ? trade.tradeUnitPrice - close
            : close - trade.tradeUnitPrice;
        if (gap > worstGap) {
          worst = trade;
          worstGap = gap;
        }
      }
      if (worst != null) {
        final asset = byId[worst.assetId];
        final close = asset?.quoteAtOrBefore(asOf)?.close ?? 0;
        if (asset != null) {
          focus(
            asset,
            '어제 ${asset.name}을 ${_briefingMoney(worst.tradeUnitPrice)}원에 '
            '${worst.tradeSide == 'buy' ? '샀는데' : '팔았는데'} 그날 종가는 '
            '${_briefingMoney(close)}원이었어. ${_briefingMoney(worstGap)}원 불리했어. '
            '화면에 보인 값이랑 손에 잡힌 값은 달라.',
          );
        }
      } else if (trades.isEmpty) {
        observation =
            '어제 주문이 없었네. 그럼 오늘 첫 주문에서 표시된 호가랑 실제 체결가가 같은지만 봐 줘. 나는 그것만 봐.';
      }

    // 가격의 결. 어제 가장 급하게 꺾인 종목.
    case 'choi_iseo':
      final mover = _sharpestMover(assets, asOf, absolute: true);
      final change = mover == null ? null : _dailyChangePercent(mover, asOf);
      if (mover != null && change != null) {
        final history = mover.historyThrough(asOf, count: 4);
        var quietMoves = 0;
        for (var index = 1; index < history.length - 1; index += 1) {
          final previous = history[index - 1].close;
          if (previous <= 0) continue;
          final step = (history[index].close - previous) / previous * 100;
          if (step.abs() < 2) quietMoves += 1;
        }
        final priorDays = math.max(1, history.length - 2);
        final quietNote = quietMoves >= priorDays
            ? '그 앞 $priorDays거래일은 다 완만했는데'
            : quietMoves == 0
            ? '그 앞도 계속 급했어'
            : '그 앞 $priorDays거래일 중 $quietMoves일은 완만했는데';
        focus(
          mover,
          '${mover.name} 선이 어제 ${_briefingSignedPercent(change)}로 '
          '${change >= 0 ? '급하게 솟았어' : '급하게 꺾였어'}. $quietNote. '
          '결이 갑자기 달라진 자리는 이유가 없어도 티가 나.',
        );
      }
  }

  return CohortBriefing(
    definition: definition,
    observation: observation,
    focusAssetId: focusId,
    focusAssetName: focusName,
  );
}
