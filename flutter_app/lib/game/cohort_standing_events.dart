import 'cohort_investment_state.dart';
import 'game_state.dart';

/// 데시멀 수익률 순위표가 만들어 내는 후속 사건이다.
///
/// 순위표는 지금까지 숫자만 보여 주고 아무것도 촉발하지 않았다. 연속 기록을 붙이면
/// 같은 표가 면담·감사·라이벌이라는 사건으로 이어진다.
///
/// 연속 기록은 저장된 `CohortInvestmentState.reports`(최근 64일)에서 파생하므로 새 저장
/// 필드나 스키마 상향이 필요 없다. 같은 저장에서 항상 같은 결과가 나온다.
const cohortStandingLastPlaceThreshold = 3;
const cohortStandingFirstPlaceThreshold = 3;
const cohortStandingRivalThreshold = 5;
const cohortStandingEventLogFlag = 'cohortStandingEventLog';
const cohortStandingEventLogLimit = 128;

enum CohortStandingEventKind {
  /// 연속 최하위. 한서윤이 중단권을 다시 확인한다. 처벌이 아니라 권리 안내다.
  operatorReview,

  /// 연속 1위. 조민경이 기록을 열람한다. 운인지 판단인지를 본다.
  rightsAudit,

  /// 같은 동기에게 계속 밀렸다. 라이벌 관계가 성립한다.
  rivalDeclared,
}

class CohortStandingStreak {
  const CohortStandingStreak({
    required this.lastPlaceDays,
    required this.firstPlaceDays,
    required this.rivalId,
    required this.rivalName,
    required this.rivalDays,
    required this.settledDays,
  });

  /// 연속으로 꼴등한 거래일 수.
  final int lastPlaceDays;

  /// 연속으로 1위한 거래일 수.
  final int firstPlaceDays;

  /// 가장 오래 나를 이긴 동기.
  final String rivalId;
  final String rivalName;

  /// 그 동기에게 연속으로 밀린 거래일 수.
  final int rivalDays;

  /// 계산에 쓴 결과표 수.
  final int settledDays;

  bool get isEmpty => settledDays == 0;
}

/// 결과표에서 플레이어 순위를 1부터 센다. 결과표가 없으면 0이다.
int playerRankInReport(CohortDailyInvestmentReport report) {
  final rows = report.rankedRows;
  for (var index = 0; index < rows.length; index += 1) {
    if (rows[index].isPlayer) return index + 1;
  }
  return 0;
}

/// 최근 결과표부터 거꾸로 읽어 연속 기록을 만든다.
CohortStandingStreak cohortStandingStreakForState(GameState state) {
  final reports = [...state.cohortInvestments.reports]
    ..sort((left, right) => right.day.compareTo(left.day));
  if (reports.isEmpty) {
    return const CohortStandingStreak(
      lastPlaceDays: 0,
      firstPlaceDays: 0,
      rivalId: '',
      rivalName: '',
      rivalDays: 0,
      settledDays: 0,
    );
  }

  var lastPlace = 0;
  var firstPlace = 0;
  var lastPlaceOpen = true;
  var firstPlaceOpen = true;
  final rivalRun = <String, int>{};
  final rivalName = <String, String>{};
  final rivalOpen = <String, bool>{};

  for (final report in reports) {
    final rows = report.rankedRows;
    if (rows.isEmpty) continue;
    final rank = playerRankInReport(report);
    if (rank == 0) continue;

    if (lastPlaceOpen) {
      if (rank == rows.length) {
        lastPlace += 1;
      } else {
        lastPlaceOpen = false;
      }
    }
    if (firstPlaceOpen) {
      if (rank == 1) {
        firstPlace += 1;
      } else {
        firstPlaceOpen = false;
      }
    }

    final player = report.resultFor('player');
    if (player != null) {
      for (final row in rows) {
        if (row.isPlayer) continue;
        final beatMe = row.returnRateBps > player.returnRateBps;
        final open = rivalOpen[row.investorId] ?? true;
        if (!open) continue;
        if (beatMe) {
          rivalRun[row.investorId] = (rivalRun[row.investorId] ?? 0) + 1;
          rivalName[row.investorId] = row.name;
        } else {
          rivalOpen[row.investorId] = false;
        }
      }
    }
  }

  var rivalId = '';
  var rivalDays = 0;
  for (final entry in rivalRun.entries) {
    if (entry.value > rivalDays ||
        (entry.value == rivalDays && entry.key.compareTo(rivalId) < 0)) {
      rivalId = entry.key;
      rivalDays = entry.value;
    }
  }

  return CohortStandingStreak(
    lastPlaceDays: lastPlace,
    firstPlaceDays: firstPlace,
    rivalId: rivalId,
    rivalName: rivalName[rivalId] ?? '',
    rivalDays: rivalDays,
    settledDays: reports.length,
  );
}

class CohortStandingEvent {
  const CohortStandingEvent({
    required this.kind,
    required this.speaker,
    required this.title,
    required this.body,
    required this.streak,
    this.rivalId = '',
  });

  final CohortStandingEventKind kind;
  final String speaker;
  final String title;
  final String body;

  /// 사건을 촉발한 연속 일수.
  final int streak;
  final String rivalId;

  String get id => '${kind.name}-$streak${rivalId.isEmpty ? '' : '-$rivalId'}';
}

/// 오늘 결과표가 촉발한 사건. 없으면 null이다.
///
/// 우선순위는 연속 최하위 → 연속 1위 → 라이벌이다. 최하위 면담은 중단권 안내이므로
/// 다른 사건보다 먼저 열린다.
CohortStandingEvent? cohortStandingEventForState(GameState state) {
  final streak = cohortStandingStreakForState(state);
  if (streak.isEmpty) return null;

  if (streak.lastPlaceDays >= cohortStandingLastPlaceThreshold) {
    return CohortStandingEvent(
      kind: CohortStandingEventKind.operatorReview,
      speaker: '한서윤 운영관',
      title: '중단권 확인 면담',
      body:
          '${streak.lastPlaceDays}거래일 연속으로 맨 아래였어요. 이건 벌이 아니라 확인이에요. '
          '계약서에 적힌 대로 언제든 그만둘 수 있고, 그만둔다고 생활 조건이 나빠지지 않습니다. '
          '계속한다면 손실을 숨기지 않는 것만 약속해 주세요.',
      streak: streak.lastPlaceDays,
    );
  }

  if (streak.firstPlaceDays >= cohortStandingFirstPlaceThreshold) {
    return CohortStandingEvent(
      kind: CohortStandingEventKind.rightsAudit,
      speaker: '조민경 권익감사관',
      title: '기록 열람',
      body:
          '${streak.firstPlaceDays}거래일 연속 1위입니다. 축하하러 온 게 아니라 기록을 보러 왔습니다. '
          '수익률이 아니라 판단 이유를 봅니다. 운이었다면 그렇게 적으면 되고, '
          '그게 감점 사유가 되지는 않습니다.',
      streak: streak.firstPlaceDays,
    );
  }

  if (streak.rivalDays >= cohortStandingRivalThreshold &&
      streak.rivalId.isNotEmpty) {
    return CohortStandingEvent(
      kind: CohortStandingEventKind.rivalDeclared,
      speaker: streak.rivalName,
      title: '${streak.rivalName}의 제안',
      body:
          '${streak.rivalDays}거래일 연속으로 내가 앞섰네. 자랑하려는 건 아니야. '
          '이제부터 내 종목을 먼저 공개할게. 대신 너도 이유를 적어 줘. '
          '같은 걸 보고 다르게 판단하는지 확인하고 싶어.',
      streak: streak.rivalDays,
      rivalId: streak.rivalId,
    );
  }

  return null;
}

/// 같은 사건을 두 번 열지 않기 위해 처리한 사건 ID를 기록한다.
List<String> cohortStandingEventLog(GameState state) =>
    ((state.story.storyFlags[cohortStandingEventLogFlag] as List?) ??
            const <dynamic>[])
        .whereType<String>()
        .toList(growable: false);

bool cohortStandingEventSeen(GameState state, CohortStandingEvent event) =>
    cohortStandingEventLog(state).contains(event.id);

/// 아직 보지 않은 사건만 돌려준다.
CohortStandingEvent? pendingCohortStandingEvent(GameState state) {
  final event = cohortStandingEventForState(state);
  if (event == null) return null;
  return cohortStandingEventSeen(state, event) ? null : event;
}

/// 사건을 확인한 것으로 기록한다. 같은 연속 길이로는 다시 열리지 않는다.
///
/// 오래된 기록은 앞에서 잘라 낸다. 27년 캠페인 동안 쌓여도 저장이 커지지 않는다.
GameState acknowledgeCohortStandingEvent(
  GameState state,
  CohortStandingEvent event,
) {
  if (cohortStandingEventSeen(state, event)) return state;
  final log = <String>[...cohortStandingEventLog(state), event.id];
  final trimmed = log.length <= cohortStandingEventLogLimit
      ? log
      : log.sublist(log.length - cohortStandingEventLogLimit);
  return state.copyWith(
    story: state.story.copyWith(
      storyFlags: <String, dynamic>{
        ...state.story.storyFlags,
        cohortStandingEventLogFlag: trimmed,
      },
    ),
  );
}
