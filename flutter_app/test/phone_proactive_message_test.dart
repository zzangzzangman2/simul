import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/phone_messenger_state.dart';
import 'package:millennium_capital/game/phone_proactive_message.dart';

void main() {
  const engine = GameEngine();

  GameState buildState({
    required int affection,
    String seed = 'phone-proactive-schedule',
  }) {
    final base = engine.createNewGame('선톡 일정 테스트', worldSeed: seed);
    final messenger = base.phoneMessenger.copyWith(
      messages: [
        for (final message in base.phoneMessenger.messages)
          message.copyWith(read: true),
      ],
      progressByContact: {
        ...base.phoneMessenger.progressByContact,
        'kim_seoa': const PhoneThreadProgress(
          contactId: 'kim_seoa',
          lastExchangeDay: 1,
          exchangesOnLastDay: 1,
          totalExchanges: 1,
          lastIntent: 'casual',
          sameIntentStreak: 1,
        ),
      },
    );
    return base.copyWith(
      day: 4,
      phoneMessenger: messenger,
      relationships: base.relationships.copyWith(
        girls: {
          ...base.relationships.girls,
          'kim_seoa': base.relationships
              .progressFor('kim_seoa')
              .copyWith(affection: affection, trust: 25, closeness: 20),
        },
      ),
    );
  }

  test(
    'proactive messages unlock at interested stage after three or four days',
    () {
      final setup = buildState(affection: phoneProactiveAffectionThreshold);
      PhoneProactiveCandidate? candidate;
      var scheduled = setup;
      for (final day in [4, 5]) {
        scheduled = scheduled.copyWith(day: day);
        candidate = selectPhoneProactiveCandidate(scheduled);
        if (candidate != null) break;
      }

      expect(candidate, isNotNull);
      expect(candidate!.contactId, 'kim_seoa');
      expect(candidate.stage.name, 'interested');

      final received = engine.receivePhoneProactiveMessage(
        scheduled,
        contactId: candidate.contactId,
        text: '좋은 아침. 어제보다 기분은 좀 괜찮아?',
      );
      expect(received.success, isTrue);
      expect(received.reply?.read, isFalse);
      expect(received.state.phoneMessenger.unreadFor('kim_seoa'), 1);
      expect(selectPhoneProactiveCandidate(received.state), isNull);

      for (var offset = 1; offset < phoneProactiveMinimumGapDays; offset += 1) {
        expect(
          selectPhoneProactiveCandidate(
            received.state.copyWith(day: received.state.day + offset),
          ),
          isNull,
        );
      }
      final nextCandidates = [
        for (
          var offset = phoneProactiveMinimumGapDays;
          offset <= phoneProactiveMaximumGapDays;
          offset += 1
        )
          selectPhoneProactiveCandidate(
            received.state.copyWith(
              day: received.state.day + offset,
              phoneMessenger: received.state.phoneMessenger.copyWith(
                messages: [
                  for (final message in received.state.phoneMessenger.messages)
                    message.copyWith(read: true),
                ],
              ),
            ),
          ),
      ];
      expect(nextCandidates.any((value) => value != null), isTrue);
    },
  );

  test('low affection and unread threads do not create proactive messages', () {
    final low = buildState(
      affection: phoneProactiveAffectionThreshold - 1,
    ).copyWith(day: 30);
    expect(selectPhoneProactiveCandidate(low), isNull);

    final ready = buildState(
      affection: 60,
      seed: 'phone-proactive-unread',
    ).copyWith(day: 30);
    final withUnread = ready.copyWith(
      phoneMessenger: ready.phoneMessenger.copyWith(
        messages: [
          ...ready.phoneMessenger.messages,
          const PhoneMessage(
            id: 'manual-unread',
            contactId: 'kim_seoa',
            senderId: 'kim_seoa',
            text: '아직 안 읽은 메시지',
            day: 29,
            marketMinute: 480,
            read: false,
          ),
        ],
      ),
    );
    expect(selectPhoneProactiveCandidate(withUnread), isNull);
  });
}
