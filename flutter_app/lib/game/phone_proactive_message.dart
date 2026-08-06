import 'game_state.dart';
import 'phone_messenger_state.dart';
import 'relationship_state.dart';
import 'stable_hash.dart';

const phoneProactiveAffectionThreshold = 40;
const phoneProactiveMinimumGapDays = 3;
const phoneProactiveMaximumGapDays = 4;

class PhoneProactiveCandidate {
  const PhoneProactiveCandidate({
    required this.contactId,
    required this.affection,
    required this.stage,
    required this.reason,
  });

  final String contactId;
  final int affection;
  final RelationshipStage stage;
  final String reason;
}

bool isPhoneProactiveMessage(PhoneMessage message) =>
    message.id.startsWith('phone-proactive-');

int? _lastProactiveDay(GameState state, [String? contactId]) {
  for (final message in state.phoneMessenger.messages.reversed) {
    if (!isPhoneProactiveMessage(message)) continue;
    if (contactId == null || message.contactId == contactId) {
      return message.day;
    }
  }
  return null;
}

int _cooldownDays(GameState state, String scope, int anchorDay) =>
    phoneProactiveMinimumGapDays +
    stableRandomInt(
      '${state.simulationSeed}:phone-proactive:$scope:$anchorDay',
      phoneProactiveMaximumGapDays - phoneProactiveMinimumGapDays + 1,
    );

PhoneProactiveCandidate? selectPhoneProactiveCandidate(GameState state) {
  if (state.phoneMessenger.messages.any(
    (message) => isPhoneProactiveMessage(message) && message.day == state.day,
  )) {
    return null;
  }

  final lastGlobalDay = _lastProactiveDay(state);
  if (lastGlobalDay != null &&
      state.day - lastGlobalDay <
          _cooldownDays(state, 'global', lastGlobalDay)) {
    return null;
  }

  final eligible = <PhoneProactiveCandidate>[];
  for (final profile in cohortGirlProfiles) {
    final relationship = state.relationships.progressFor(profile.id);
    final thread = state.phoneMessenger.progressFor(profile.id);
    if (relationship.affection < phoneProactiveAffectionThreshold ||
        state.phoneMessenger.unreadFor(profile.id) > 0) {
      continue;
    }
    final lastContactProactiveDay = _lastProactiveDay(state, profile.id);
    var anchorDay = relationship.lastInteractionDay;
    if (thread.lastExchangeDay > anchorDay) {
      anchorDay = thread.lastExchangeDay;
    }
    if (lastContactProactiveDay != null &&
        lastContactProactiveDay > anchorDay) {
      anchorDay = lastContactProactiveDay;
    }
    if (anchorDay < 0 ||
        state.day - anchorDay < _cooldownDays(state, profile.id, anchorDay)) {
      continue;
    }
    eligible.add(
      PhoneProactiveCandidate(
        contactId: profile.id,
        affection: relationship.affection,
        stage: relationship.stage,
        reason: anchorDay > 0
            ? '${relationship.stage.label}인 상대에게 마지막 관계 활동이나 대화 후 '
                  '${state.day - anchorDay}일이 지나 먼저 안부를 전할 때가 됨'
            : '${relationship.stage.label}인 상대에게 부담스럽지 않게 먼저 안부를 전할 때가 됨',
      ),
    );
  }
  if (eligible.isEmpty) return null;
  final index = stableRandomInt(
    '${state.simulationSeed}:phone-proactive-pick:${state.day}:'
    '${eligible.map((candidate) => candidate.contactId).join(',')}',
    eligible.length,
  );
  return eligible[index];
}
