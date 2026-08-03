import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/phone_messenger_state.dart';

void main() {
  const engine = GameEngine();

  test('new and migrated saves have nine distinct phone contacts in v25', () {
    final state = engine.createNewGame('미래톡 테스트', worldSeed: 'phone-initial');

    expect(GameState.schemaVersion, 25);
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
    expect(replies.any((reply) => reply.contains('수수료')), isTrue);
    expect(replies.any((reply) => reply.contains('약속')), isTrue);
    expect(replies.any((reply) => reply.contains('반대로')), isFalse);
    expect(replies.any((reply) => reply.contains('속보 정정')), isTrue);
    expect(replies.any((reply) => reply.contains('왜 이 가격')), isTrue);
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

  test(
    'first meaningful talk changes detailed relationship only once a day',
    () {
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
      expect(second.relationshipChanged, isFalse);
      expect(
        second.state.relationships
            .progressFor('kim_seoa')
            .meaningfulMessageCount,
        1,
      );
      expect(second.state.phoneMessenger.memoriesFor('kim_seoa'), hasLength(2));

      final tomorrow = second.state.copyWith(day: second.state.day + 1);
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
        2,
      );
    },
  );

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
