import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/phone_messenger_state.dart';

/// End-to-end guarantees for 데시멀톡 long-term memory.
///
/// `phone_messenger_state_test.dart` covers [retainPhoneConversationMemories]
/// in isolation with hand-built records. This file drives real conversations
/// through [GameEngine] instead, so it catches a send path that forgets to
/// record a memory, a trim that quietly drops another contact's history, or a
/// save round trip that loses fields.
void main() {
  const engine = GameEngine();
  final contactIds = phoneMessengerContacts
      .map((contact) => contact.id)
      .toList(growable: false);

  /// Sends [turnsPerDay] messages to [contactId] on each day up to [days].
  ///
  /// Advancing `day` is enough to reset the per-contact daily allowance, so
  /// this stays cheap compared with a full engine day rollover.
  GameState converse(
    GameState start, {
    required int days,
    required List<String> contacts,
    int turnsPerDay = phoneMessengerDailySendLimit,
    String Function(int day, int turn)? text,
  }) {
    var state = start;
    for (var day = 1; day <= days; day++) {
      state = state.copyWith(day: day, marketMinute: 8 * 60);
      for (final contactId in contacts) {
        for (var turn = 0; turn < turnsPerDay; turn++) {
          final result = engine.sendPhoneMessage(
            state,
            contactId: contactId,
            text: text?.call(day, turn) ?? '$day일차 $turn번째 이야기',
          );
          expect(
            result.success,
            isTrue,
            reason: '$day일 $contactId $turn번째 전송이 거절됐습니다: ${result.message}',
          );
          state = result.state;
        }
      }
    }
    return state;
  }

  test('every conversation records exactly one long-term memory', () {
    final state = converse(
      engine.createNewGame('기억 1:1', worldSeed: 'phone-memory-one-to-one'),
      days: 40,
      contacts: contactIds,
    );

    final expectedPerContact = 40 * phoneMessengerDailySendLimit;
    expect(
      expectedPerContact,
      lessThan(phoneConversationMemoryPerContactLimit),
    );

    for (final contactId in contactIds) {
      expect(
        state.phoneMessenger.memoriesFor(contactId),
        hasLength(expectedPerContact),
        reason: '$contactId의 대화 수와 기억 수가 1:1이어야 합니다.',
      );
    }
    expect(
      state.phoneMessenger.memories,
      hasLength(expectedPerContact * contactIds.length),
    );
  });

  test('per-contact archive fills to the cap without starving others', () {
    // 3 conversations a day reaches the 512 cap around day 171.
    final state = converse(
      engine.createNewGame('기억 상한', worldSeed: 'phone-memory-cap'),
      days: 200,
      contacts: contactIds,
    );

    for (final contactId in contactIds) {
      expect(
        state.phoneMessenger.memoriesFor(contactId),
        hasLength(phoneConversationMemoryPerContactLimit),
        reason: '한 연락처가 다른 연락처의 기억을 밀어내면 안 됩니다.',
      );
    }
    expect(
      state.phoneMessenger.memories,
      hasLength(phoneConversationMemoryPerContactLimit * contactIds.length),
    );
    // The declared global ceiling must stay consistent with the per-contact
    // ceiling times the shipped contact list.
    expect(
      phoneConversationMemoryPerContactLimit * contactIds.length,
      lessThanOrEqualTo(phoneConversationMemoryLimit),
    );
  });

  test('a saved campaign restores every memory field', () {
    final state = converse(
      engine.createNewGame('기억 저장', worldSeed: 'phone-memory-save'),
      days: 200,
      contacts: contactIds,
    );

    final restored = GameState.fromJson(state.toJson());
    expect(
      restored.phoneMessenger.memories,
      hasLength(state.phoneMessenger.memories.length),
    );

    for (final contactId in contactIds) {
      final before = state.phoneMessenger.memoriesFor(contactId);
      final after = restored.phoneMessenger.memoriesFor(contactId);
      expect(
        after.map((memory) => memory.id).toList(),
        before.map((memory) => memory.id).toList(),
        reason: '$contactId 기억의 순서와 구성이 저장 왕복에서 바뀌면 안 됩니다.',
      );
    }

    final origin = state.phoneMessenger.memoriesFor(contactIds.first).last;
    final copy = restored.phoneMessenger.memoriesFor(contactIds.first).last;
    expect(copy.id, origin.id);
    expect(copy.contactId, origin.contactId);
    expect(copy.day, origin.day);
    expect(copy.intent, origin.intent);
    expect(copy.investmentSituation, origin.investmentSituation);
    expect(copy.playerText, origin.playerText);
    expect(copy.replyText, origin.replyText);
    expect(copy.importance, origin.importance);
    expect(copy.marketMinute, origin.marketMinute);
    expect(copy.situationSummary, origin.situationSummary);
    expect(copy.privacyScope, origin.privacyScope);
    expect(copy.isPrivateFor(contactIds.first), isTrue);
  });

  test('past the cap the first talk and important talks survive', () {
    const contactId = 'kim_seoa';
    // Day 2 carries an apology, which the importance table scores at 4.
    final state = converse(
      engine.createNewGame('기억 중요도', worldSeed: 'phone-memory-importance'),
      days: 260,
      contacts: const <String>[contactId],
      text: (day, turn) =>
          day == 2 && turn == 1 ? '아까는 내가 잘못했어 미안해' : '$day일차 $turn번째 그냥 이야기',
    );

    final memories = state.phoneMessenger.memoriesFor(contactId);
    expect(memories, hasLength(phoneConversationMemoryPerContactLimit));

    // Foundation: the opening exchanges stay for continuity.
    expect(memories.first.day, 1);
    // Recent arc: the newest exchange is always present.
    expect(memories.last.day, 260);
    // Importance: the apology is not evicted by ordinary chatter.
    final apologies = memories.where((memory) => memory.intent == 'apology');
    expect(apologies, isNotEmpty, reason: '중요도 4 이상 기억은 일상 대화에 밀려 사라지면 안 됩니다.');
    expect(apologies.every((memory) => memory.importance >= 4), isTrue);
  });

  test('one contact talking a lot never leaks into another thread', () {
    var state = converse(
      engine.createNewGame('기억 격리', worldSeed: 'phone-memory-isolation'),
      days: 200,
      contacts: const <String>['kim_seoa'],
    );
    state = converse(
      state.copyWith(day: 1),
      days: 3,
      contacts: const <String>['lee_jian'],
    );

    expect(
      state.phoneMessenger.memoriesFor('kim_seoa'),
      hasLength(phoneConversationMemoryPerContactLimit),
    );
    expect(
      state.phoneMessenger.memoriesFor('lee_jian'),
      hasLength(3 * phoneMessengerDailySendLimit),
    );
    for (final memory in state.phoneMessenger.memoriesFor('lee_jian')) {
      expect(memory.isPrivateFor('kim_seoa'), isFalse);
    }
    for (final contactId in contactIds) {
      if (contactId == 'kim_seoa' || contactId == 'lee_jian') continue;
      expect(state.phoneMessenger.memoriesFor(contactId), isEmpty);
    }
  });
}
