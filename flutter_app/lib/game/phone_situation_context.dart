import 'game_state.dart';
import 'market_clock.dart';
import 'phone_messenger_state.dart';
import 'relationship_state.dart';
import 'weekend_activity.dart';
import 'weekday_activity.dart';

enum PhoneInvitationTiming { none, today, tomorrow, weekend, unspecified }

enum PhoneScheduleDecision {
  notInvitation,
  todayAvailable,
  todayWeekdayBlocked,
  todayAlreadyUsed,
  futureWeekendAvailable,
  futureWeekdayBlocked,
  relationshipLocked,
}

class PhoneSituationContext {
  const PhoneSituationContext({
    required this.dateKey,
    required this.weekdayLabel,
    required this.marketMinute,
    required this.timeLabel,
    required this.phaseLabel,
    required this.currentObligation,
    required this.isWeekend,
    required this.marketClosed,
    required this.pendingDecisionCount,
    required this.weekendActionsRemaining,
    required this.weekdayEveningUsed,
    required this.relationshipTimeUsedToday,
    required this.dateUnlocked,
    required this.invitationDetected,
    required this.requestedTiming,
    required this.scheduleDecision,
    required this.nextValidWindow,
  });

  final String dateKey;
  final String weekdayLabel;
  final int marketMinute;
  final String timeLabel;
  final String phaseLabel;
  final String currentObligation;
  final bool isWeekend;
  final bool marketClosed;
  final int pendingDecisionCount;
  final int weekendActionsRemaining;
  final bool weekdayEveningUsed;
  final bool relationshipTimeUsedToday;
  final bool dateUnlocked;
  final bool invitationDetected;
  final PhoneInvitationTiming requestedTiming;
  final PhoneScheduleDecision scheduleDecision;
  final String nextValidWindow;

  bool get canAcceptToday =>
      scheduleDecision == PhoneScheduleDecision.todayAvailable;

  bool get canAgreeToFutureDate =>
      scheduleDecision == PhoneScheduleDecision.futureWeekendAvailable;

  bool get mustRejectToday =>
      requestedTiming == PhoneInvitationTiming.today && !canAcceptToday;

  bool get mustNotPromiseDate => invitationDetected && !dateUnlocked;

  String get situationSummary =>
      '$dateKey $weekdayLabel $timeLabel · $phaseLabel · $currentObligation';

  String get scheduleRule {
    if (!invitationDetected) {
      return '현재 날짜·시각·진행 단계를 기준으로 답하고, 끝난 일정이나 아직 하지 않은 일을 뒤바꾸지 않는다.';
    }
    if (!dateUnlocked) {
      return '데이트 해금 전이라 약속을 수락하거나 확정하지 않는다. 더 친해진 뒤 다시 이야기하자는 경계를 지킨다.';
    }
    return switch (scheduleDecision) {
      PhoneScheduleDecision.todayAvailable =>
        '오늘은 주말 외출 조건이 맞지만 카톡이 데이트를 실행하지는 않는다. 오늘 20:00 관계 시간에 정할 수 있다고만 답한다.',
      PhoneScheduleDecision.todayWeekdayBlocked =>
        '오늘은 평일이므로 당일 외출·데이트를 수락하거나 지금 나간다고 말하지 않는다. 실제 가능한 가장 가까운 주말로 바꿔 제안한다.',
      PhoneScheduleDecision.todayAlreadyUsed =>
        '오늘 관계 시간을 이미 사용했으므로 당일 외출·데이트를 수락하지 않는다. 다음 가능한 주말을 제안한다.',
      PhoneScheduleDecision.futureWeekendAvailable =>
        '주말 외출 계획에는 동의할 수 있다. 아직 실행된 일처럼 말하지 말고 실제 선택은 해당 날짜의 20:00 관계 시간에 한다.',
      PhoneScheduleDecision.futureWeekdayBlocked =>
        '요청한 날이 평일이라 외출·데이트가 불가능하다. 가장 가까운 주말로 바꿔 제안한다.',
      PhoneScheduleDecision.relationshipLocked =>
        '데이트 해금 전이라 약속을 수락하거나 확정하지 않는다.',
      PhoneScheduleDecision.notInvitation => '현재 날짜·시각·진행 단계에 맞춰 답한다.',
    };
  }

  Map<String, dynamic> toRequestJson() => <String, dynamic>{
    'marketMinute': marketMinute,
    'relationshipTimeUsedToday': relationshipTimeUsedToday,
    'weekdayEveningUsed': weekdayEveningUsed,
    'weekendActionsRemaining': weekendActionsRemaining,
    'pendingDecisionCount': pendingDecisionCount,
  };

  String localPlanningReply(String contactId) {
    if (!invitationDetected) return '';

    if (!dateUnlocked) {
      final timingLine = mustRejectToday
          ? (isWeekend
                ? '오늘이어도 데이트 약속까지는 아직 일러.'
                : '오늘은 평일이라 밖에 나갈 수 없고, 데이트 약속도 아직 일러.')
          : '데이트 약속까지는 아직 조금 일러.';
      final boundary = switch (contactId) {
        'kim_seoa' => '조금 더 친해진 뒤에 다시 이야기해도 될까?',
        'lee_jian' => '좀 더 친해진 뒤에 다시 말해.',
        'choi_iseo' => '서두르지 말고 조금 더 알아가고 싶어.',
        'jung_arin' => '먼저 서로 더 알아가는 게 순서야.',
        'park_haeun' => '우리 조금 더 편해진 다음에 다시 얘기하자.',
        'han_sua' => '우리 좀 더 친해진 다음에 다시 물어봐 줘.',
        'oh_jiwoo' => '친밀도 가설부터 조금 더 쌓고 다시 검토하자.',
        'yoon_chaea' => '관계가 더 가까워진 뒤에 계획하는 편이 맞아.',
        _ => '조금 더 친해진 뒤에 다시 이야기하자.',
      };
      return '$timingLine $boundary';
    }

    return switch (scheduleDecision) {
      PhoneScheduleDecision.todayAvailable => switch (contactId) {
        'kim_seoa' => '오늘은 주말이라 괜찮아. 20시 관계 시간에 같이 정해 볼까?',
        'lee_jian' => '오늘은 주말이라 가능해. 20시에 정하자.',
        'choi_iseo' => '오늘은 주말이니까 좋아. 20시에 조용한 곳으로 골라 보자.',
        'jung_arin' => '오늘은 가능해. 20시 관계 시간에 장소부터 정하자.',
        'park_haeun' => '오늘은 주말이라 괜찮아. 20시에 둘 다 편한 곳을 골라 보자.',
        'han_sua' => '오늘 주말이니까 좋아. 20시에 어디 갈지 같이 고르자.',
        'oh_jiwoo' => '오늘은 주말이라 조건 통과. 20시에 어디가 재밌을지 정하자.',
        'yoon_chaea' => '오늘은 주말이라 가능해. 20시에 일정과 장소를 확정하자.',
        _ => '오늘은 주말이라 가능해. 20시 관계 시간에 정하자.',
      },
      PhoneScheduleDecision.todayWeekdayBlocked => switch (contactId) {
        'kim_seoa' => '오늘은 평일 일정이 끝나서 밖에 나갈 수는 없어. 이번 주말에 시간 맞춰 볼까?',
        'lee_jian' => '오늘은 안 돼. 평일 일정은 끝났으니까 이번 주말에 보자.',
        'choi_iseo' => '오늘은 이미 평일 일정이 끝났어. 주말에 조용히 나가는 건 좋아.',
        'jung_arin' => '오늘 외출은 불가야. 이번 주말 일정으로 옮기자.',
        'park_haeun' => '오늘은 평일 일정이 끝나서 무리야. 이번 주말에 둘 다 괜찮은지 보자.',
        'han_sua' => '오늘은 평일 일정 끝나서 못 나가. 대신 이번 주말은 어때?',
        'oh_jiwoo' => '오늘 외출 가설은 시간표에서 탈락. 이번 주말이면 다시 검토 가능.',
        'yoon_chaea' => '오늘은 평일 일정 종료 후라 불가능해. 가장 가까운 주말로 계획을 옮기자.',
        _ => '오늘은 평일이라 밖에 나갈 수 없어. 이번 주말로 옮기자.',
      },
      PhoneScheduleDecision.todayAlreadyUsed =>
        '오늘 관계 시간은 이미 보냈어. $nextValidWindow에 다시 맞춰 보자.',
      PhoneScheduleDecision.futureWeekendAvailable => switch (contactId) {
        'kim_seoa' => '좋아. $nextValidWindow에 서로 시간 맞는지 다시 확인해 보자.',
        'lee_jian' => '좋아. $nextValidWindow에 보자.',
        'choi_iseo' => '좋아. $nextValidWindow에 조용한 곳이면 좋겠어.',
        'jung_arin' => '좋아. $nextValidWindow 일정으로 잡고 그날 20시에 정하자.',
        'park_haeun' => '좋아. $nextValidWindow에 둘 다 편한 곳으로 가자.',
        'han_sua' => '좋아. $nextValidWindow에 같이 나가자.',
        'oh_jiwoo' => '좋아. $nextValidWindow에 데이트 가설을 실험해 보자.',
        'yoon_chaea' => '좋아. $nextValidWindow 일정으로 생각해 둘게.',
        _ => '좋아. $nextValidWindow에 보자.',
      },
      PhoneScheduleDecision.futureWeekdayBlocked =>
        '그날은 평일이라 밖에 나갈 수 없어. $nextValidWindow로 옮기자.',
      PhoneScheduleDecision.relationshipLocked =>
        '데이트 약속까지는 아직 일러. 조금 더 친해진 뒤에 다시 이야기하자.',
      PhoneScheduleDecision.notInvitation => '',
    };
  }
}

PhoneSituationContext buildPhoneSituationContext(
  GameState state, {
  required String contactId,
  required String playerText,
}) {
  final date = state.currentDate;
  final relationship = state.relationships.progressFor(contactId);
  final isWeekend = relationshipOutingAvailableOn(date);
  final invitation = _detectInvitation(playerText);
  final requestedTiming = invitation
      ? _invitationTiming(playerText)
      : PhoneInvitationTiming.none;
  final relationshipTimeUsedToday = state.relationships.completedEveningForDay(
    state.day,
  );
  final nextWeekend = _nextWeekendDate(date);
  final requestedDate = requestedTiming == PhoneInvitationTiming.tomorrow
      ? date.add(const Duration(days: 1))
      : null;

  final scheduleDecision = !invitation
      ? PhoneScheduleDecision.notInvitation
      : !relationship.dateUnlocked
      ? PhoneScheduleDecision.relationshipLocked
      : requestedTiming == PhoneInvitationTiming.today
      ? !isWeekend
            ? PhoneScheduleDecision.todayWeekdayBlocked
            : relationshipTimeUsedToday
            ? PhoneScheduleDecision.todayAlreadyUsed
            : PhoneScheduleDecision.todayAvailable
      : requestedTiming == PhoneInvitationTiming.tomorrow &&
            !relationshipOutingAvailableOn(requestedDate!)
      ? PhoneScheduleDecision.futureWeekdayBlocked
      : PhoneScheduleDecision.futureWeekendAvailable;

  final weekendActionsRemaining = isWeekend
      ? weekendActivityPointsRemaining(state)
      : 0;
  final eveningUsed = !isWeekend && weekdayEveningUsed(state);
  final phase = _phaseLabel(
    state,
    isWeekend: isWeekend,
    weekendActionsRemaining: weekendActionsRemaining,
    weekdayEveningUsed: eveningUsed,
  );
  final obligation = _currentObligation(
    state,
    isWeekend: isWeekend,
    weekendActionsRemaining: weekendActionsRemaining,
    relationshipTimeUsedToday: relationshipTimeUsedToday,
  );

  return PhoneSituationContext(
    dateKey: marketDateKey(date),
    weekdayLabel: _weekdayLabel(date.weekday),
    marketMinute: state.marketMinute,
    timeLabel: marketTimeLabel(state.marketMinute),
    phaseLabel: phase,
    currentObligation: obligation,
    isWeekend: isWeekend,
    marketClosed: !isMarketTradingDay(date),
    pendingDecisionCount: state.pendingDecisions.length,
    weekendActionsRemaining: weekendActionsRemaining,
    weekdayEveningUsed: eveningUsed,
    relationshipTimeUsedToday: relationshipTimeUsedToday,
    dateUnlocked: relationship.dateUnlocked,
    invitationDetected: invitation,
    requestedTiming: requestedTiming,
    scheduleDecision: scheduleDecision,
    nextValidWindow: relationship.dateUnlocked
        ? _dateWindowLabel(nextWeekend)
        : '호감도 $relationshipDateUnlockAffection 이후의 주말',
  );
}

bool phoneAiReplyViolatesSituationPolicy(
  String reply, {
  required PhoneSituationContext situation,
}) {
  if (!situation.invitationDetected) return false;
  final compact = reply.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final refusal = RegExp(
    r'안돼|안되|못가|못나가|불가능|어려워|무리|나중|아직|일러|친해진',
  ).hasMatch(compact);
  final refusalOrRedirect = refusal || RegExp(r'주말|다음').hasMatch(compact);
  final affirmative = RegExp(
    r'좋아|그래[,!?.]?가자|콜|만나자|보자|나가자|데이트하자|가능해',
  ).hasMatch(compact);
  final explicitTodayAcceptance =
      RegExp(
        r'(오늘|지금|이따|오늘밤|오늘저녁).{0,16}(좋아|가능|만나|보자|가자|나가|데이트)',
      ).hasMatch(compact) ||
      RegExp(r'(좋아|그래|콜).{0,12}(오늘|지금|이따)').hasMatch(compact);

  if (situation.mustRejectToday &&
      (explicitTodayAcceptance || (affirmative && !refusalOrRedirect))) {
    return true;
  }
  if (situation.mustNotPromiseDate && affirmative && !refusal) {
    return true;
  }
  if (situation.scheduleDecision ==
          PhoneScheduleDecision.futureWeekdayBlocked &&
      affirmative &&
      !refusalOrRedirect) {
    return true;
  }
  return false;
}

bool _detectInvitation(String rawText) {
  final text = rawText.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  return const <String>[
    '데이트',
    '만나자',
    '만날래',
    '만날까',
    '볼래',
    '보자',
    '놀러',
    '나갈래',
    '나갈까',
    '나가자',
    '외출',
    '산책',
    '같이가자',
    '같이갈래',
    '같이갈까',
  ].any(text.contains);
}

PhoneInvitationTiming _invitationTiming(String rawText) {
  final text = rawText.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final explicitlyNotToday = const <String>[
    '오늘말고',
    '오늘은말고',
    '오늘안되고',
    '오늘은안되고',
  ].any(text.contains);
  if (!explicitlyNotToday &&
      const <String>[
        '오늘',
        '지금',
        '당장',
        '이따',
        '오늘밤',
        '오늘저녁',
        '끝나고',
      ].any(text.contains)) {
    return PhoneInvitationTiming.today;
  }
  if (text.contains('내일')) return PhoneInvitationTiming.tomorrow;
  if (const <String>['주말', '토요일', '일요일'].any(text.contains)) {
    return PhoneInvitationTiming.weekend;
  }
  return PhoneInvitationTiming.unspecified;
}

String _phaseLabel(
  GameState state, {
  required bool isWeekend,
  required int weekendActionsRemaining,
  required bool weekdayEveningUsed,
}) {
  if (state.marketMinute >= phoneMessengerBedtimeMinute) {
    return '22:00 취침 시간';
  }
  if (state.marketMinute >= marketDayEndMinute) return '20:00 관계 시간';
  if (isWeekend) {
    return weekendActionsRemaining > 0
        ? '주말 자유 일정 · 행동 $weekendActionsRemaining칸 남음'
        : '주말 자유 일정 완료';
  }
  if (state.marketMinute < krxOpenMinute) return '장전 준비';
  if (state.marketMinute < krxContinuousEndMinute) return '주식 장중';
  if (state.marketMinute < krxCloseMinute) return '마감 동시호가';
  return weekdayEveningUsed ? '평일 관계 시간 완료' : '장 마감 후 자유 시간';
}

String _currentObligation(
  GameState state, {
  required bool isWeekend,
  required int weekendActionsRemaining,
  required bool relationshipTimeUsedToday,
}) {
  if (state.pendingDecisions.isNotEmpty) {
    return '새 기록 ${state.pendingDecisions.length}건을 먼저 처리해야 함';
  }
  if (state.marketMinute >= phoneMessengerBedtimeMinute) {
    return '오늘 일과를 마치고 모두 취침 중';
  }
  if (relationshipTimeUsedToday) return '오늘 관계 시간까지 이미 완료';
  if (state.marketMinute >= marketDayEndMinute) return '오늘 관계 상대와 활동을 고르기 전';
  if (isWeekend && weekendActionsRemaining > 0) {
    return '주말 행동 $weekendActionsRemaining칸을 마친 뒤 관계 시간으로 이동';
  }
  if (!isWeekend && state.marketMinute < krxCloseMinute) {
    return '오늘 시장 일정이 아직 진행 중';
  }
  if (!isWeekend) return '장 마감 결과를 확인한 뒤 관계 시간으로 이동';
  return '주말 자유 일정을 마치고 관계 시간으로 이동';
}

DateTime _nextWeekendDate(DateTime date) {
  for (var offset = 1; offset <= 7; offset++) {
    final candidate = date.add(Duration(days: offset));
    if (relationshipOutingAvailableOn(candidate)) return candidate;
  }
  return date.add(const Duration(days: 7));
}

String _dateWindowLabel(DateTime date) =>
    '${date.month}월 ${date.day}일 ${_weekdayLabel(date.weekday)}';

String _weekdayLabel(int weekday) => switch (weekday) {
  DateTime.monday => '월요일',
  DateTime.tuesday => '화요일',
  DateTime.wednesday => '수요일',
  DateTime.thursday => '목요일',
  DateTime.friday => '금요일',
  DateTime.saturday => '토요일',
  _ => '일요일',
};
