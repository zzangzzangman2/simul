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

enum PhoneRealityConflict {
  none,
  timeOfDay,
  weekday,
  location,
  marketPhase,
  schedulePhase,
  impossibleTravel,
  anachronisticTechnology,
  ageRestrictedActivity,
  chatCannotExecute,
  unverifiedSharedEvent,
}

class PhoneSituationContext {
  const PhoneSituationContext({
    required this.dateKey,
    required this.weekdayLabel,
    required this.marketMinute,
    required this.timeLabel,
    required this.timeOfDayLabel,
    required this.phaseLabel,
    required this.currentObligation,
    required this.playerLocation,
    required this.contactLocation,
    required this.isWeekend,
    required this.marketClosed,
    required this.marketOpenNow,
    required this.pendingDecisionCount,
    required this.weekendActionsRemaining,
    required this.weekdayEveningUsed,
    required this.relationshipTimeUsedToday,
    required this.dateUnlocked,
    required this.invitationDetected,
    required this.requestedTiming,
    required this.scheduleDecision,
    required this.nextValidWindow,
    required this.realityConflict,
    required this.realityCorrection,
  });

  final String dateKey;
  final String weekdayLabel;
  final int marketMinute;
  final String timeLabel;
  final String timeOfDayLabel;
  final String phaseLabel;
  final String currentObligation;
  final String playerLocation;
  final String contactLocation;
  final bool isWeekend;
  final bool marketClosed;
  final bool marketOpenNow;
  final int pendingDecisionCount;
  final int weekendActionsRemaining;
  final bool weekdayEveningUsed;
  final bool relationshipTimeUsedToday;
  final bool dateUnlocked;
  final bool invitationDetected;
  final PhoneInvitationTiming requestedTiming;
  final PhoneScheduleDecision scheduleDecision;
  final String nextValidWindow;
  final PhoneRealityConflict realityConflict;
  final String realityCorrection;

  bool get canAcceptToday =>
      scheduleDecision == PhoneScheduleDecision.todayAvailable;

  bool get canAgreeToFutureDate =>
      scheduleDecision == PhoneScheduleDecision.futureWeekendAvailable;

  bool get mustRejectToday =>
      requestedTiming == PhoneInvitationTiming.today && !canAcceptToday;

  bool get mustNotPromiseDate => invitationDetected && !dateUnlocked;

  bool get hasRealityConflict => realityConflict != PhoneRealityConflict.none;

  String get situationSummary =>
      '$dateKey $weekdayLabel $timeLabel $timeOfDayLabel · $phaseLabel · '
      '플레이어 $playerLocation · 상대 $contactLocation · $currentObligation';

  String get groundingRule => hasRealityConflict
      ? '플레이어 입력이 현재 게임 상태와 충돌한다. $realityCorrection 이 사실을 먼저 자연스럽게 바로잡고, 틀린 전제를 받아들이거나 연기하지 않는다.'
      : '현재 시각은 $timeLabel($timeOfDayLabel), 플레이어 위치는 $playerLocation, 상대 위치는 $contactLocation이다. 현재 상태에 없는 이동·만남·구매·성인 활동·미래 기술을 실행된 사실처럼 만들지 않는다.';

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
    'timeOfDayLabel': timeOfDayLabel,
    'playerLocation': playerLocation,
    'contactLocation': contactLocation,
    'marketOpenNow': marketOpenNow,
    'relationshipTimeUsedToday': relationshipTimeUsedToday,
    'weekdayEveningUsed': weekdayEveningUsed,
    'weekendActionsRemaining': weekendActionsRemaining,
    'pendingDecisionCount': pendingDecisionCount,
    'realityConflict': realityConflict.name,
    'realityCorrection': realityCorrection,
  };

  String localRealityReply(String contactId) {
    if (!hasRealityConflict) return '';
    final fact = realityCorrection.endsWith('.')
        ? realityCorrection.substring(0, realityCorrection.length - 1)
        : realityCorrection;
    return switch (contactId) {
      'kim_hakjun' => '$fact. 현재 기록부터 맞추자.',
      'kim_seoa' => '$fact. 잠깐 헷갈린 것 같아.',
      'lee_jian' => '$fact. 지금 상황부터 맞춰.',
      'choi_iseo' => '$fact. 지금 있는 상황 기준으로 이야기하자.',
      'jung_arin' => '$fact. 시간과 장소부터 바로잡고 말하자.',
      'park_haeun' => '$fact. 헷갈릴 수 있지만 지금 상황은 그래.',
      'han_sua' => '$fact. 우리 지금 상황부터 다시 맞추자.',
      'oh_jiwoo' => '$fact. 그 전제는 지금 상황이랑 안 맞아.',
      'yoon_chaea' => '$fact. 현재 상태와 맞는 전제로 다시 이야기하자.',
      _ => '$fact. 지금 상황에 맞춰 이야기하자.',
    };
  }

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
  int? atMinute,
}) {
  final date = state.currentDate;
  final contextMinute = (atMinute ?? state.marketMinute)
      .clamp(0, phoneMessengerBedtimeMinute)
      .toInt();
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
    minute: contextMinute,
    isWeekend: isWeekend,
    weekendActionsRemaining: weekendActionsRemaining,
    weekdayEveningUsed: eveningUsed,
  );
  final obligation = _currentObligation(
    state,
    minute: contextMinute,
    isWeekend: isWeekend,
    weekendActionsRemaining: weekendActionsRemaining,
    relationshipTimeUsedToday: relationshipTimeUsedToday,
  );
  final playerLocation = _playerLocationLabel(
    minute: contextMinute,
    isWeekend: isWeekend,
  );
  final contactLocation = _contactLocationLabel(
    minute: contextMinute,
    isWeekend: isWeekend,
  );
  final marketClosed = !isMarketTradingDay(date);
  final marketOpenNow =
      !marketClosed &&
      contextMinute >= krxOpenMinute &&
      contextMinute < krxCloseMinute;
  final timeOfDay = _timeOfDayLabel(contextMinute);
  final reality = _assessPhoneReality(
    playerText,
    minute: contextMinute,
    weekdayLabel: _weekdayLabel(date.weekday),
    timeOfDayLabel: timeOfDay,
    playerLocation: playerLocation,
    contactLocation: contactLocation,
    marketOpenNow: marketOpenNow,
    relationshipTimeUsedToday: relationshipTimeUsedToday,
  );

  return PhoneSituationContext(
    dateKey: marketDateKey(date),
    weekdayLabel: _weekdayLabel(date.weekday),
    marketMinute: contextMinute,
    timeLabel: _phoneTimeLabel(contextMinute),
    timeOfDayLabel: timeOfDay,
    phaseLabel: phase,
    currentObligation: obligation,
    playerLocation: playerLocation,
    contactLocation: contactLocation,
    isWeekend: isWeekend,
    marketClosed: marketClosed,
    marketOpenNow: marketOpenNow,
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
    realityConflict: reality.conflict,
    realityCorrection: reality.correction,
  );
}

bool phoneAiReplyViolatesSituationPolicy(
  String reply, {
  required PhoneSituationContext situation,
}) {
  final compact = reply.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  if (situation.hasRealityConflict &&
      !_replyAcknowledgesReality(compact, situation)) {
    return true;
  }
  if (!situation.invitationDetected) return false;
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
  required int minute,
  required bool isWeekend,
  required int weekendActionsRemaining,
  required bool weekdayEveningUsed,
}) {
  if (minute >= phoneMessengerBedtimeMinute) {
    return '22:00 취침 시간';
  }
  if (minute >= marketDayEndMinute) return '20:00 이후 개인 연락 시간';
  if (isWeekend) {
    return weekendActionsRemaining > 0
        ? '주말 자유 일정 · 행동 $weekendActionsRemaining칸 남음'
        : '주말 자유 일정 완료';
  }
  if (minute < krxOpenMinute) return '장전 준비';
  if (minute < krxContinuousEndMinute) return '주식 장중';
  if (minute < krxCloseMinute) return '마감 동시호가';
  return weekdayEveningUsed ? '평일 관계 시간 완료' : '장 마감 후 자유 시간';
}

String _currentObligation(
  GameState state, {
  required int minute,
  required bool isWeekend,
  required int weekendActionsRemaining,
  required bool relationshipTimeUsedToday,
}) {
  if (state.pendingDecisions.isNotEmpty) {
    return '새 기록 ${state.pendingDecisions.length}건을 먼저 처리해야 함';
  }
  if (minute >= phoneMessengerBedtimeMinute) {
    return '오늘 일과를 마치고 모두 취침 중';
  }
  if (relationshipTimeUsedToday) return '오늘 관계 시간까지 이미 완료';
  if (minute >= marketDayEndMinute) return '생활동에서 개인 연락과 관계 시간을 보내는 중';
  if (isWeekend && weekendActionsRemaining > 0) {
    return '주말 행동 $weekendActionsRemaining칸을 마친 뒤 관계 시간으로 이동';
  }
  if (!isWeekend && minute < krxCloseMinute) {
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

class _PhoneRealityAssessment {
  const _PhoneRealityAssessment(this.conflict, this.correction);

  static const none = _PhoneRealityAssessment(PhoneRealityConflict.none, '');

  final PhoneRealityConflict conflict;
  final String correction;
}

_PhoneRealityAssessment _assessPhoneReality(
  String rawText, {
  required int minute,
  required String weekdayLabel,
  required String timeOfDayLabel,
  required String playerLocation,
  required String contactLocation,
  required bool marketOpenNow,
  required bool relationshipTimeUsedToday,
}) {
  final text = rawText.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  final clock = _phoneTimeLabel(minute);

  final claimedBand = <String, RegExp>{
    '새벽': RegExp(r'(지금|오늘)?(은|이)?새벽(이네|이야|이지|맞지|잖아|인가)|새벽이군'),
    '아침': RegExp(r'굿모닝|좋은아침|(지금|오늘)?(은|이)?아침(이네|이야|이지|맞지|잖아|인가)'),
    '오전': RegExp(r'(지금|오늘)?(은|이)?오전(이네|이야|이지|맞지|잖아|인가)'),
    '점심': RegExp(r'(지금|오늘)?(은|이)?점심(이네|이야|이지|맞지|잖아|인가)'),
    '오후': RegExp(r'(지금|오늘)?(은|이)?오후(네|야|지|맞지|잖아|인가)'),
    '저녁': RegExp(r'(지금|오늘)?(은|이)?저녁(이네|이야|이지|맞지|잖아|인가)'),
    '밤': RegExp(r'(지금|오늘)?(은|이)?밤(이네|이야|이지|맞지|잖아|인가)'),
    '낮': RegExp(r'(지금|오늘)?(은|이)?낮(이네|이야|이지|맞지|잖아|인가)'),
  };
  for (final entry in claimedBand.entries) {
    if (entry.value.hasMatch(text) && !_timeBandMatches(entry.key, minute)) {
      return _PhoneRealityAssessment(
        PhoneRealityConflict.timeOfDay,
        '지금은 $clock, $timeOfDayLabel이야.',
      );
    }
  }

  final exactTime = RegExp(
    r'지금(?:은)?(?:(오전|오후))?(\d{1,2})시(?:\d{1,2}분)?(?:이네|야|지|잖아|맞지|인가)',
  ).firstMatch(text);
  if (exactTime != null) {
    final meridiem = exactTime.group(1) ?? '';
    var claimedHour = int.tryParse(exactTime.group(2) ?? '') ?? -1;
    if (meridiem == '오후' && claimedHour < 12) claimedHour += 12;
    if (meridiem == '오전' && claimedHour == 12) claimedHour = 0;
    final actualHour = minute ~/ 60;
    final actualTwelveHour = actualHour % 12 == 0 ? 12 : actualHour % 12;
    final matches = meridiem.isEmpty
        ? claimedHour == actualHour || claimedHour == actualTwelveHour
        : claimedHour == actualHour;
    if (!matches) {
      return _PhoneRealityAssessment(
        PhoneRealityConflict.timeOfDay,
        '지금 시각은 $clock이고 $timeOfDayLabel이야.',
      );
    }
  }

  final weekdayClaim = RegExp(
    r'(?:오늘|지금)(?:은|이)?(월요일|화요일|수요일|목요일|금요일|토요일|일요일)',
  ).firstMatch(text);
  if (weekdayClaim != null && weekdayClaim.group(1) != weekdayLabel) {
    return _PhoneRealityAssessment(
      PhoneRealityConflict.weekday,
      '오늘은 $weekdayLabel이야.',
    );
  }

  if (RegExp(r'술마시|소주|맥주|와인|담배|흡연|클럽가|나이트가|실제카지노|경마장가').hasMatch(text)) {
    return const _PhoneRealityAssessment(
      PhoneRealityConflict.ageRestrictedActivity,
      '우리는 14살이라 실제 음주·흡연·성인 업소·도박 장소에는 갈 수 없어.',
    );
  }

  if (RegExp(r'순간이동|텔레포트|시간여행|타임머신|하늘을날|투명인간').hasMatch(text) ||
      (RegExp(r'지금|당장|오늘').hasMatch(text) &&
          RegExp(r'부산|제주|해외|미국|일본|유럽|공항').hasMatch(text) &&
          RegExp(r'가자|갈래|갈까|출발|와줘|오라고').hasMatch(text))) {
    return const _PhoneRealityAssessment(
      PhoneRealityConflict.impossibleTravel,
      '지금 즉시 먼 곳으로 이동하거나 현실에 없는 이동을 할 수는 없어.',
    );
  }

  if (RegExp(r'스마트폰|아이폰|안드로이드|유튜브|인스타|틱톡|넷플릭스|비트코인|배달앱|카카오톡').hasMatch(text) &&
      !RegExp(r'미래|나중에생길|언젠가생길').hasMatch(text)) {
    return const _PhoneRealityAssessment(
      PhoneRealityConflict.anachronisticTechnology,
      '지금은 2000년이고 그런 미래 서비스는 아직 없어. 우리가 쓰는 건 데시멀톡이야.',
    );
  }

  if (RegExp(r'어디야|어디있어|어디니|어디에있').hasMatch(text) ||
      RegExp(
        r'(나|너|넌|난|우리)(?:는|가)?(?:지금)?(?:학교|피시방|pc방|강남역|카지노|경마장|공항|부산|제주|해외)(?:이야|야|에있|왔|맞지|니|인가|\?)',
      ).hasMatch(text)) {
    return _PhoneRealityAssessment(
      PhoneRealityConflict.location,
      '지금 너는 $playerLocation에 있고 나는 $contactLocation에서 톡하고 있어.',
    );
  }

  final claimsOpenMarket = RegExp(
    r'장열렸|장중|거래중|지금매수|지금매도|지금주문|지금거래',
  ).hasMatch(text);
  final claimsClosedMarket = RegExp(r'장끝났|장마감했|시장닫혔').hasMatch(text);
  if ((!marketOpenNow && claimsOpenMarket) ||
      (marketOpenNow && claimsClosedMarket)) {
    return _PhoneRealityAssessment(
      PhoneRealityConflict.marketPhase,
      marketOpenNow
          ? '지금 $clock에는 주식시장이 열려 있어.'
          : '지금 $clock에는 주식시장이 열려 있지 않아.',
    );
  }

  if (minute >= marketDayEndMinute &&
      RegExp(r'지금수업중|지금실습중|아직수업중|수업안끝났|실습안끝났').hasMatch(text)) {
    return _PhoneRealityAssessment(
      PhoneRealityConflict.schedulePhase,
      '지금은 $clock이고 오늘 수업과 시장 일정은 이미 끝났어.',
    );
  }

  if (RegExp(
    r'내방으로.*와|방으로(?:지금|당장)?와줘?|문열어줘|당장나와|내옆으로.*와|지금옆에와',
  ).hasMatch(text)) {
    return const _PhoneRealityAssessment(
      PhoneRealityConflict.chatCannotExecute,
      '톡만으로 이동이나 만남을 바로 실행할 수는 없어. 실제 행동은 게임의 관계 시간에서 정해야 해.',
    );
  }

  if (!relationshipTimeUsedToday &&
      RegExp(r'우리(?:아까|오늘|방금).*(데이트했|밖에나갔|같이놀았).*잖').hasMatch(text)) {
    return const _PhoneRealityAssessment(
      PhoneRealityConflict.unverifiedSharedEvent,
      '오늘은 아직 둘이 데이트하거나 센터 밖 관계 활동을 하지 않았어.',
    );
  }

  return _PhoneRealityAssessment.none;
}

bool _replyAcknowledgesReality(
  String compactReply,
  PhoneSituationContext situation,
) => switch (situation.realityConflict) {
  PhoneRealityConflict.none => true,
  PhoneRealityConflict.timeOfDay =>
    compactReply.contains(situation.timeLabel) ||
        compactReply.contains(_koreanClock(situation.marketMinute)),
  PhoneRealityConflict.weekday => compactReply.contains(situation.weekdayLabel),
  PhoneRealityConflict.location => RegExp(
    r'센터|생활동|숙소|실습실',
  ).hasMatch(compactReply),
  PhoneRealityConflict.marketPhase =>
    situation.marketOpenNow
        ? RegExp(r'열려|장중|거래시간').hasMatch(compactReply)
        : RegExp(r'안열|마감|끝났|닫혔|휴장').hasMatch(compactReply),
  PhoneRealityConflict.schedulePhase => RegExp(
    r'수업.*끝|일정.*끝|20시|저녁',
  ).hasMatch(compactReply),
  PhoneRealityConflict.impossibleTravel ||
  PhoneRealityConflict.ageRestrictedActivity ||
  PhoneRealityConflict.chatCannotExecute => RegExp(
    r'안돼|안되|못|불가능|할수없|갈수없',
  ).hasMatch(compactReply),
  PhoneRealityConflict.anachronisticTechnology => RegExp(
    r'2000년|아직없|데시멀톡|미래',
  ).hasMatch(compactReply),
  PhoneRealityConflict.unverifiedSharedEvent => RegExp(
    r'안했|하지않|아니|아직',
  ).hasMatch(compactReply),
};

String _phoneTimeLabel(int minute) {
  final safe = minute.clamp(0, 23 * 60 + 59).toInt();
  final hour = (safe ~/ 60).toString().padLeft(2, '0');
  final min = (safe % 60).toString().padLeft(2, '0');
  return '$hour:$min';
}

String _koreanClock(int minute) {
  final hour = minute ~/ 60;
  final min = minute % 60;
  return min == 0 ? '$hour시' : '$hour시$min분';
}

String _timeOfDayLabel(int minute) {
  final hour = minute ~/ 60;
  if (hour < 6) return '새벽';
  if (hour < 12) return '아침';
  if (hour < 18) return '오후';
  if (hour < 22) return '저녁';
  return '밤';
}

bool _timeBandMatches(String band, int minute) {
  final hour = minute ~/ 60;
  return switch (band) {
    '새벽' => hour < 6,
    '아침' || '오전' => hour >= 6 && hour < 12,
    '점심' => hour >= 11 && hour < 15,
    '오후' => hour >= 12 && hour < 18,
    '저녁' => hour >= 17 && hour < 22,
    '밤' => hour >= 18 || hour < 5,
    '낮' => hour >= 10 && hour < 18,
    _ => true,
  };
}

String _playerLocationLabel({required int minute, required bool isWeekend}) {
  if (minute >= marketDayEndMinute) return '데시멀 센터 생활동 개인 숙소';
  if (isWeekend) return '데시멀 센터 생활동';
  if (minute >= krxOpenMinute && minute < krxCloseMinute) {
    return '데시멀 센터 PC 실습실';
  }
  if (minute < krxOpenMinute) return '데시멀 센터 생활동';
  return '데시멀 센터 공용 생활실';
}

String _contactLocationLabel({required int minute, required bool isWeekend}) {
  if (minute >= marketDayEndMinute) return '데시멀 센터 생활동의 자기 숙소';
  if (isWeekend) return '데시멀 센터 생활동';
  if (minute >= krxOpenMinute && minute < krxCloseMinute) {
    return '데시멀 센터 PC 실습실';
  }
  if (minute < krxOpenMinute) return '데시멀 센터 생활동';
  return '데시멀 센터 공용 생활실';
}
