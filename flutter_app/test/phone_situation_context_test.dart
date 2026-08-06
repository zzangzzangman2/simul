import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/phone_situation_context.dart';
import 'package:millennium_capital/game/relationship_state.dart';

GameState _withAffection(GameState state, String contactId, int affection) {
  return state.copyWith(
    relationships: state.relationships.copyWith(
      girls: <String, GirlRelationshipProgress>{
        ...state.relationships.girls,
        contactId: state.relationships
            .progressFor(contactId)
            .copyWith(affection: affection),
      },
    ),
  );
}

void main() {
  const engine = GameEngine();

  test('weekday same-day date is rejected and redirected to the weekend', () {
    final base = engine.createNewGame(
      '평일 일정 테스트',
      worldSeed: 'phone-weekday-schedule',
    );
    final state = _withAffection(
      base.copyWith(day: 3, marketMinute: marketDayEndMinute),
      'kim_seoa',
      35,
    );
    expect(state.currentDate.weekday, DateTime.monday);

    final situation = buildPhoneSituationContext(
      state,
      contactId: 'kim_seoa',
      playerText: '우리 오늘 일 끝나고 데이트 나갈까?',
    );
    expect(situation.weekdayLabel, '월요일');
    expect(situation.timeLabel, '20:00');
    expect(
      situation.scheduleDecision,
      PhoneScheduleDecision.todayWeekdayBlocked,
    );
    expect(situation.mustRejectToday, isTrue);
    expect(situation.nextValidWindow, contains('토요일'));

    final sent = engine.sendPhoneMessage(
      state,
      contactId: 'kim_seoa',
      text: '우리 오늘 일 끝나고 데이트 나갈까?',
    );
    expect(sent.success, isTrue);
    expect(sent.reply?.text, contains('평일'));
    expect(sent.reply?.text, contains('주말'));
    expect(sent.reply?.text, isNot(contains('오늘은 주말이라 괜찮아')));
  });

  test('engine rejects an AI override that accepts an impossible date', () {
    final base = engine.createNewGame(
      'AI 일정 방어 테스트',
      worldSeed: 'phone-schedule-guard',
    );
    final state = _withAffection(
      base.copyWith(day: 3, marketMinute: marketDayEndMinute),
      'lee_jian',
      35,
    );

    final sent = engine.sendPhoneMessage(
      state,
      contactId: 'lee_jian',
      text: '오늘 지금 데이트 나갈까?',
      replyOverride: '좋아, 오늘 지금 바로 만나자.',
    );

    expect(sent.success, isTrue);
    expect(sent.reply?.text, isNot('좋아, 오늘 지금 바로 만나자.'));
    expect(sent.reply?.text, contains('주말'));
  });

  test('an unlocked weekend can discuss today but chat does not spend it', () {
    final base = engine.createNewGame(
      '주말 일정 테스트',
      worldSeed: 'phone-weekend-schedule',
    );
    final state = _withAffection(
      base.copyWith(marketMinute: marketDayEndMinute),
      'han_sua',
      35,
    );
    expect(state.currentDate.weekday, DateTime.saturday);

    final situation = buildPhoneSituationContext(
      state,
      contactId: 'han_sua',
      playerText: '우리 오늘 데이트 나갈까?',
    );
    expect(situation.scheduleDecision, PhoneScheduleDecision.todayAvailable);
    expect(situation.canAcceptToday, isTrue);

    final sent = engine.sendPhoneMessage(
      state,
      contactId: 'han_sua',
      text: '우리 오늘 데이트 나갈까?',
    );
    expect(sent.reply?.text, contains('오늘'));
    expect(sent.reply?.text, contains('20시'));
    expect(sent.state.relationships.completedEveningForDay(state.day), isFalse);
  });

  test('a used relationship time blocks another same-day weekend date', () {
    final base = engine.createNewGame(
      '사용 일정 테스트',
      worldSeed: 'phone-used-schedule',
    );
    final unlocked = _withAffection(base, 'yoon_chaea', 35);
    final state = unlocked.copyWith(
      marketMinute: marketDayEndMinute,
      relationships: unlocked.relationships.copyWith(
        lastEveningEventDay: unlocked.day,
      ),
    );

    final situation = buildPhoneSituationContext(
      state,
      contactId: 'yoon_chaea',
      playerText: '오늘 또 데이트할까?',
    );
    expect(situation.scheduleDecision, PhoneScheduleDecision.todayAlreadyUsed);
    expect(situation.mustRejectToday, isTrue);
  });

  test(
    'future weekend planning is allowed but a locked date is not promised',
    () {
      final base = engine
          .createNewGame('주말 약속 테스트', worldSeed: 'phone-future-weekend')
          .copyWith(day: 3, marketMinute: marketDayEndMinute);
      final unlocked = _withAffection(base, 'park_haeun', 35);
      final available = buildPhoneSituationContext(
        unlocked,
        contactId: 'park_haeun',
        playerText: '이번 주말에 데이트 가자.',
      );
      expect(
        available.scheduleDecision,
        PhoneScheduleDecision.futureWeekendAvailable,
      );
      expect(available.canAgreeToFutureDate, isTrue);

      final locked = buildPhoneSituationContext(
        base,
        contactId: 'park_haeun',
        playerText: '이번 주말에 데이트 가자.',
      );
      expect(locked.scheduleDecision, PhoneScheduleDecision.relationshipLocked);
      expect(locked.mustNotPromiseDate, isTrue);
      expect(
        phoneAiReplyViolatesSituationPolicy(
          '좋아, 이번 주말에 데이트하자.',
          situation: locked,
        ),
        isTrue,
      );
    },
  );

  test('reply-time clock corrects a false time and keeps advancing', () {
    final base = engine
        .createNewGame('연속 시각 인식 테스트', worldSeed: 'phone-live-clock')
        .copyWith(day: 3, marketMinute: 20 * 60);

    final first = engine.sendPhoneMessage(
      base,
      contactId: 'jung_arin',
      text: '좋은 아침, 아침이네',
      replyOverride: '맞아, 좋은 아침이야.',
    );
    expect(first.success, isTrue);
    expect(first.reply?.marketMinute, 20 * 60 + 30);
    expect(first.reply?.text, contains('20:30'));
    expect(first.reply?.text, isNot('맞아, 좋은 아침이야.'));
    expect(first.affectionDelta, 0);
    expect(first.trustDelta, 0);

    final second = engine.sendPhoneMessage(
      first.state,
      contactId: 'jung_arin',
      text: '지금은 20시잖아',
    );
    expect(second.success, isTrue);
    expect(second.reply?.marketMinute, 21 * 60);
    expect(second.reply?.text, contains('21:00'));
  });

  test('current location and closed market claims are grounded', () {
    final base = engine
        .createNewGame('장소 인식 테스트', worldSeed: 'phone-location')
        .copyWith(day: 3, marketMinute: 20 * 60);

    final location = buildPhoneSituationContext(
      base,
      contactId: 'lee_jian',
      playerText: '너 지금 학교야?',
      atMinute: 20 * 60 + 30,
    );
    expect(location.realityConflict, PhoneRealityConflict.location);
    expect(location.playerLocation, contains('생활동'));
    expect(location.contactLocation, contains('숙소'));
    expect(location.localRealityReply('lee_jian'), contains('생활동'));

    final market = buildPhoneSituationContext(
      base,
      contactId: 'yoon_chaea',
      playerText: '지금 장 열렸지? 바로 매수하자.',
      atMinute: 20 * 60 + 30,
    );
    expect(market.marketOpenNow, isFalse);
    expect(market.realityConflict, PhoneRealityConflict.marketPhase);
    expect(market.localRealityReply('yoon_chaea'), contains('열려 있지 않아'));
  });

  test('broader reality rules reject impossible world assumptions', () {
    final state = engine
        .createNewGame('현실성 규칙 테스트', worldSeed: 'phone-grounding')
        .copyWith(day: 3, marketMinute: 20 * 60);

    PhoneRealityConflict conflictFor(String text) => buildPhoneSituationContext(
      state,
      contactId: 'kim_seoa',
      playerText: text,
      atMinute: 20 * 60 + 30,
    ).realityConflict;

    expect(
      conflictFor('지금 당장 제주 공항으로 가자'),
      PhoneRealityConflict.impossibleTravel,
    );
    expect(
      conflictFor('유튜브 같이 보자'),
      PhoneRealityConflict.anachronisticTechnology,
    );
    expect(
      conflictFor('오늘 소주 마시러 가자'),
      PhoneRealityConflict.ageRestrictedActivity,
    );
    expect(conflictFor('내 방으로 지금 와'), PhoneRealityConflict.chatCannotExecute);
    expect(
      conflictFor('우리 오늘 데이트했잖아'),
      PhoneRealityConflict.unverifiedSharedEvent,
    );
  });
}
