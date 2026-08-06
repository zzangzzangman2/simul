import 'game_state.dart';
import 'market_clock.dart';

const weekdayActivityLogFlag = 'weekdayActivityLog';
const weekdayActivityCounterMetric = 'weekday_evening_actions';
const weekdayActivityHistoryLimit = 260;
const facilityStoryGatesEnabledFlag = 'facilityStoryGatesEnabled';
const bankAccessUnlockedFlag = 'bankAccessUnlocked';
const realEstateAccessUnlockedFlag = 'realEstateAccessUnlocked';
const weekdayAfternoonSkipActivityId = 'skip';

bool facilityStoryGatesEnabled(GameState state) =>
    state.story.flagBool(facilityStoryGatesEnabledFlag);

bool bankAccessUnlocked(GameState state) =>
    !facilityStoryGatesEnabled(state) ||
    state.story.flagBool(bankAccessUnlockedFlag);

bool realEstateAccessUnlocked(GameState state) =>
    !facilityStoryGatesEnabled(state) ||
    state.story.flagBool(realEstateAccessUnlockedFlag);

bool businessMarketAccessUnlocked(GameState state) =>
    !facilityStoryGatesEnabled(state) ||
    state.story.flagBool('businessMarketAccessUnlocked');

bool businessOperationsUnlocked(GameState state) =>
    !facilityStoryGatesEnabled(state) ||
    state.story.flagBool('businessOperationsUnlocked');

bool realEstateTransactionsUnlocked(GameState state) =>
    !facilityStoryGatesEnabled(state) ||
    state.story.flagBool('realEstateTransactionsUnlocked');

bool realEstateOperationsUnlocked(GameState state) =>
    !facilityStoryGatesEnabled(state) ||
    state.story.flagBool('realEstateOperationsUnlocked');

bool propertyBusinessLinkUnlocked(GameState state) =>
    !facilityStoryGatesEnabled(state) ||
    state.story.flagBool('propertyBusinessLinkUnlocked');

bool advancedCorporateActionsUnlocked(GameState state) =>
    !facilityStoryGatesEnabled(state) ||
    state.story.flagBool('advancedCorporateActionsUnlocked');

class WeekdayActivityDefinition {
  const WeekdayActivityDefinition({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

const weekdayActivities = <WeekdayActivityDefinition>[
  WeekdayActivityDefinition(
    id: 'casino',
    title: '데시멀 카지노',
    description: '국가망 테이블을 고르고 장 마감 뒤 오후 시간을 사용합니다.',
  ),
  WeekdayActivityDefinition(
    id: 'horse_racing',
    title: '국가망 경마',
    description: '전자 마권 한 장을 정산하고 장 마감 뒤 오후 시간을 사용합니다.',
  ),
  WeekdayActivityDefinition(
    id: 'real_estate',
    title: '부동산 시장',
    description: '매물·시세·보유 부동산을 검토하고 필요한 거래를 처리합니다.',
  ),
  WeekdayActivityDefinition(
    id: 'bank',
    title: '예금·은행 업무',
    description: '예금·대출·상환 조건과 현재 현금 흐름을 확인합니다.',
  ),
];

const weekdayAfternoonSkipActivity = WeekdayActivityDefinition(
  id: weekdayAfternoonSkipActivityId,
  title: '오늘은 그냥 넘어가기',
  description: '오후 시설을 이용하지 않고 20:00 점호로 넘어갑니다.',
);

WeekdayActivityDefinition? weekdayActivityById(String id) {
  if (id == weekdayAfternoonSkipActivityId) {
    return weekdayAfternoonSkipActivity;
  }
  for (final activity in weekdayActivities) {
    if (activity.id == id) return activity;
  }
  return null;
}

bool weekdayActivityUnlocked(GameState state, String activityId) =>
    switch (activityId) {
      weekdayAfternoonSkipActivityId => true,
      'casino' || 'horse_racing' =>
        !facilityStoryGatesEnabled(state) ||
            state.story.nationalNetworkBriefingSeen,
      'bank' => bankAccessUnlocked(state),
      'real_estate' => realEstateAccessUnlocked(state),
      _ => false,
    };

String weekdayActivityLockReason(GameState state, String activityId) =>
    switch (activityId) {
      weekdayAfternoonSkipActivityId => '',
      'casino' || 'horse_racing' => '한서윤 운영관의 국가망 사전 설명 필요',
      'bank' => '2월 예금·은행 이야기 이후 해금',
      'real_estate' => '5월 부동산 이야기 이후 해금',
      _ => '아직 선택할 수 없음',
    };

List<WeekdayActivityDefinition> unlockedWeekdayActivities(GameState state) =>
    weekdayActivities
        .where((activity) => weekdayActivityUnlocked(state, activity.id))
        .toList(growable: false);

/// Interactive `하루 보내기` stops at this decision gate whenever at least one
/// afternoon destination is available. The player may use one destination or
/// explicitly skip it; fast-forward simulations are not blocked by the UI.
bool weekdayAfternoonScheduleRequired(GameState state) =>
    state.currentDate.weekday < DateTime.saturday &&
    state.marketMinute >= krxCloseMinute &&
    !weekdayEveningUsed(state) &&
    unlockedWeekdayActivities(state).isNotEmpty;

class WeekdayActivityLog {
  const WeekdayActivityLog({
    required this.day,
    required this.activityId,
    required this.title,
    required this.startMinute,
    required this.endMinute,
  });

  final int day;
  final String activityId;
  final String title;
  final int startMinute;
  final int endMinute;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'day': day,
    'activityId': activityId,
    'title': title,
    'startMinute': startMinute,
    'endMinute': endMinute,
  };

  factory WeekdayActivityLog.fromJson(Map<String, dynamic> json) =>
      WeekdayActivityLog(
        day: ((json['day'] as num?)?.toInt() ?? 0).clamp(0, 0x7fffffff),
        activityId: json['activityId'] as String? ?? '',
        title: json['title'] as String? ?? '평일 저녁 업무',
        startMinute:
            ((json['startMinute'] as num?)?.toInt() ?? marketDayStartMinute)
                .clamp(marketDayStartMinute, marketDayEndMinute),
        endMinute: ((json['endMinute'] as num?)?.toInt() ?? marketDayEndMinute)
            .clamp(marketDayStartMinute, marketDayEndMinute),
      );
}

class WeekdayActivityResult {
  const WeekdayActivityResult({
    required this.state,
    required this.success,
    required this.message,
    this.activity,
    this.startMinute,
    this.endMinute,
  });

  final GameState state;
  final bool success;
  final String message;
  final WeekdayActivityDefinition? activity;
  final int? startMinute;
  final int? endMinute;

  WeekdayActivityResult withState(GameState next) => WeekdayActivityResult(
    state: next,
    success: success,
    message: message,
    activity: activity,
    startMinute: startMinute,
    endMinute: endMinute,
  );
}

List<WeekdayActivityLog> weekdayActivityLogsForState(GameState state) =>
    ((state.story.storyFlags[weekdayActivityLogFlag] as List?) ??
            const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) => WeekdayActivityLog.fromJson(item.cast<String, dynamic>()),
        )
        .where((log) => log.day > 0 && log.activityId.isNotEmpty)
        .toList(growable: false);

List<WeekdayActivityLog> weekdayActivityLogsForDay(GameState state, int day) =>
    weekdayActivityLogsForState(
      state,
    ).where((log) => log.day == day).toList(growable: false);

bool weekdayEveningUsed(GameState state) =>
    weekdayActivityLogsForDay(state, state.day).isNotEmpty;

class GameDayGuidance {
  const GameDayGuidance({
    required this.phaseLabel,
    required this.title,
    required this.body,
    required this.actionLabel,
  });

  final String phaseLabel;
  final String title;
  final String body;
  final String actionLabel;
}

GameDayGuidance gameDayGuidanceForState(GameState state) {
  if (state.pendingDecisions.isNotEmpty) {
    return GameDayGuidance(
      phaseLabel: '우선 처리',
      title: '새 기록 ${state.pendingDecisions.length}건을 확인하세요',
      body: '기록 보관실에서 결정을 마쳐야 오늘 업무를 계속할 수 있습니다.',
      actionLabel: '기록 확인',
    );
  }
  if (state.currentDate.weekday >= DateTime.saturday) {
    return const GameDayGuidance(
      phaseLabel: '주말 일정',
      title: '주말 행동 두 가지를 선택하세요',
      body: '하루 보내기에서 주말 행동력을 사용한 뒤 저녁 일정으로 이어집니다.',
      actionLabel: '주말 일정 시작',
    );
  }
  if (state.marketMinute < krxOpenMinute) {
    return const GameDayGuidance(
      phaseLabel: '장전 준비 · 다음 09:00',
      title: '공시·신문·관심 종목을 확인하세요',
      body: '08:00부터는 홈 PC에서 오늘 주문과 대응 계획을 준비합니다.',
      actionLabel: '주식 PC 열기',
    );
  }
  if (state.marketMinute < krxContinuousEndMinute) {
    return const GameDayGuidance(
      phaseLabel: '주식 장중 · 다음 14:50',
      title: '시세와 주문을 관리하세요',
      body: '주식 화면의 시계가 실제로 흐르며 주문 체결과 뉴스가 반영됩니다.',
      actionLabel: '주식 PC 열기',
    );
  }
  if (state.marketMinute < krxCloseMinute) {
    return const GameDayGuidance(
      phaseLabel: '마감 동시호가 · 다음 15:00',
      title: '마지막 주문과 보유 현황을 확인하세요',
      body: '15:00 종가가 확정될 때까지 주식 업무를 마무리합니다.',
      actionLabel: '주식 PC 열기',
    );
  }
  if (state.marketMinute < marketDayEndMinute) {
    final available = unlockedWeekdayActivities(state);
    return GameDayGuidance(
      phaseLabel: '15:00 · 장 마감 후',
      title: '오늘 손익을 확인하고 오후 일정을 고르세요',
      body: available.isEmpty
          ? '아직 해금된 오후 일정이 없습니다. 국가망 사전 설명이나 시설 해금 이야기를 먼저 확인합니다.'
          : '해금된 ${available.length}개 일정 중 하나를 이용하거나 오늘은 그냥 넘어갈 수 있습니다.',
      actionLabel: '오후 일정 선택',
    );
  }
  return const GameDayGuidance(
    phaseLabel: '20:00 · 하루 마감',
    title: '오늘 업무를 모두 마쳤습니다',
    body: '하루 보내기를 누르면 결산 후 다음 날 08:00부터 시작합니다.',
    actionLabel: '하루 마무리',
  );
}
