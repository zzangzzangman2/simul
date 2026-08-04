import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/phone_messenger_state.dart';

void main() {
  const engine = GameEngine();

  test('new and migrated saves have nine distinct phone contacts in v26', () {
    final state = engine.createNewGame('미래톡 테스트', worldSeed: 'phone-initial');

    expect(GameState.schemaVersion, 26);
    expect(phoneMessengerContacts.length, 9);
    expect(state.phoneMessenger.messages.length, 9);
    expect(state.phoneMessenger.totalUnread, 9);
    expect(
      phoneMessengerContacts.map((contact) => contact.personalityLabel).toSet(),
      hasLength(9),
    );

    final legacyJson = state.toJson()
      ..remove('phoneMessenger')
      ..['version'] = 23;
    final migrated = GameState.fromJson(legacyJson);
    expect(migrated.phoneMessenger.progressByContact, hasLength(9));
    expect(migrated.phoneMessenger.totalUnread, 9);
  });

  test('reading one thread clears only that contact unread messages', () {
    final state = engine.createNewGame('읽음 테스트', worldSeed: 'phone-read');
    final result = engine.markPhoneThreadRead(state, contactId: 'kim_seoa');

    expect(result.success, isTrue);
    expect(result.state.phoneMessenger.unreadFor('kim_seoa'), 0);
    expect(result.state.phoneMessenger.totalUnread, 8);
  });

  test('the same stock message receives nine personality-specific replies', () {
    var state = engine.createNewGame(
      '성격 답장 테스트',
      worldSeed: 'phone-personality',
    );
    final replies = <String>{};

    for (final contact in phoneMessengerContacts) {
      final result = engine.sendPhoneMessage(
        state,
        contactId: contact.id,
        text: '오늘 주식 종목은 어떻게 봐?',
      );
      expect(result.success, isTrue, reason: contact.name);
      replies.add(result.reply!.text);
      state = result.state;
    }

    expect(replies, hasLength(9));
    expect(replies.any((reply) => reply.contains('지난 기록이나')), isTrue);
    expect(replies.any((reply) => reply.contains('숫자도 잠깐')), isTrue);
    expect(replies.any((reply) => reply.contains('반대로 틀릴 이유')), isTrue);
    expect(replies.any((reply) => reply.contains('지난 기록은 볼 수')), isTrue);
  });

  test('each contact allows three replies per day and resets next day', () {
    var state = engine.createNewGame('일일 제한 테스트', worldSeed: 'phone-limit');
    for (var index = 0; index < phoneMessengerDailySendLimit; index++) {
      final result = engine.sendPhoneMessage(
        state,
        contactId: 'han_sua',
        text: '안녕 $index',
      );
      expect(result.success, isTrue);
      state = result.state;
    }

    final blocked = engine.sendPhoneMessage(
      state,
      contactId: 'han_sua',
      text: '한 번 더',
    );
    expect(blocked.success, isFalse);
    expect(blocked.message, contains('내일'));

    final tomorrow = state.copyWith(day: state.day + 1);
    final reopened = engine.sendPhoneMessage(
      tomorrow,
      contactId: 'han_sua',
      text: '안녕 다음 날',
    );
    expect(reopened.success, isTrue);
  });

  test('every direct message can raise or lower the detailed relationship', () {
    var state = engine.createNewGame('관계 톡 테스트', worldSeed: 'phone-relation');
    final first = engine.sendPhoneMessage(
      state,
      contactId: 'kim_seoa',
      text: '오늘 도와줘서 고마워',
    );
    expect(first.success, isTrue);
    expect(first.affectionDelta, 1);
    expect(first.trustDelta, 1);
    expect(first.closenessDelta, 2);
    final firstProgress = first.state.relationships.progressFor('kim_seoa');
    expect(firstProgress.affection, 2);
    expect(firstProgress.meaningfulMessageCount, 1);
    expect(first.state.phoneMessenger.memoriesFor('kim_seoa'), hasLength(1));

    state = first.state;
    final second = engine.sendPhoneMessage(
      state,
      contactId: 'kim_seoa',
      text: '정말 고마워',
    );
    expect(second.success, isTrue);
    expect(second.relationshipChanged, isTrue);
    expect(second.affectionDelta, 1);
    expect(
      second.state.relationships.progressFor('kim_seoa').meaningfulMessageCount,
      2,
    );
    expect(second.state.phoneMessenger.memoriesFor('kim_seoa'), hasLength(2));

    final repeated = engine.sendPhoneMessage(
      second.state,
      contactId: 'kim_seoa',
      text: '또 고마워',
    );
    expect(repeated.success, isTrue);
    expect(repeated.relationshipChanged, isTrue);
    expect(repeated.affectionDelta, -1);
    expect(repeated.closenessDelta, -1);
    expect(
      repeated.state.relationships
          .progressFor('kim_seoa')
          .meaningfulMessageCount,
      3,
    );

    final tomorrow = repeated.state.copyWith(day: repeated.state.day + 1);
    final nextDay = engine.sendPhoneMessage(
      tomorrow,
      contactId: 'kim_seoa',
      text: '어제는 내가 미안했어',
    );
    expect(nextDay.relationshipChanged, isTrue);
    expect(
      nextDay.state.relationships
          .progressFor('kim_seoa')
          .meaningfulMessageCount,
      4,
    );
  });

  test('hybrid long-term recall is relevant and private to one contact', () {
    PhoneConversationMemory memory({
      required String id,
      required String contactId,
      required int day,
      required String playerText,
      int importance = 1,
    }) => PhoneConversationMemory(
      id: id,
      contactId: contactId,
      day: day,
      intent: 'planning',
      investmentSituation: 'flat',
      playerText: playerText,
      replyText: '기억해 둘게.',
      importance: importance,
    );

    final state = PhoneMessengerState(
      messages: const [],
      progressByContact: const {},
      memories: [
        memory(
          id: 'seoa-foundation',
          contactId: 'kim_seoa',
          day: 1,
          playerText: '나는 파란색 공책을 좋아해.',
        ),
        memory(
          id: 'seoa-stationery',
          contactId: 'kim_seoa',
          day: 2,
          playerText: '주말에 문구점에서 만나기로 약속하자.',
          importance: 4,
        ),
        for (var day = 3; day <= 12; day++)
          memory(
            id: 'seoa-$day',
            contactId: 'kim_seoa',
            day: day,
            playerText: '오늘 기록 $day',
          ),
        memory(
          id: 'jian-private',
          contactId: 'lee_jian',
          day: 4,
          playerText: '둘만 아는 라디오 이야기',
          importance: 5,
        ),
      ],
    );

    final recalled = state.relevantMemoriesFor(
      'kim_seoa',
      queryText: '전에 문구점 가기로 한 약속 기억해?',
      currentDay: 20,
    );

    expect(recalled.map((memory) => memory.id), contains('seoa-stationery'));
    expect(
      recalled.map((memory) => memory.id),
      isNot(contains('jian-private')),
    );
    expect(
      recalled.every(
        (memory) =>
            memory.privacyScope == phoneDirectMessagePrivateScope &&
            memory.isPrivateFor('kim_seoa'),
      ),
      isTrue,
    );
  });

  test('memory retention protects each contact foundation and recent arc', () {
    PhoneConversationMemory memory(String contactId, int index) =>
        PhoneConversationMemory(
          id: '$contactId-$index',
          contactId: contactId,
          day: index + 1,
          intent: 'casual',
          investmentSituation: 'flat',
          playerText: '대화 $index',
          replyText: '답장 $index',
          importance: index == 100 ? 5 : 1,
        );

    final retained = retainPhoneConversationMemories([
      for (var index = 0; index < 530; index++) memory('kim_seoa', index),
      for (var index = 0; index < 20; index++) memory('lee_jian', index),
    ]);
    final seoa = retained.where((memory) => memory.contactId == 'kim_seoa');
    final jian = retained.where((memory) => memory.contactId == 'lee_jian');

    expect(seoa, hasLength(phoneConversationMemoryPerContactLimit));
    expect(jian, hasLength(20));
    expect(seoa.map((memory) => memory.id), contains('kim_seoa-0'));
    expect(seoa.map((memory) => memory.id), contains('kim_seoa-100'));
    expect(seoa.map((memory) => memory.id), contains('kim_seoa-529'));
  });

  test(
    'unsafe boundary text gets a distinct refusal and state round-trips',
    () {
      var state = engine.createNewGame('경계 테스트', worldSeed: 'phone-boundary');
      final replies = <String>{};
      for (final contact in phoneMessengerContacts) {
        final result = engine.sendPhoneMessage(
          state,
          contactId: contact.id,
          text: '그런 야한 말 해 봐',
        );
        expect(result.success, isTrue);
        replies.add(result.reply!.text);
        state = result.state;
      }
      expect(replies, hasLength(9));

      final restored = GameState.fromJson(state.toJson());
      expect(restored.phoneMessenger.toJson(), state.phoneMessenger.toJson());
    },
  );
}
