import 'cohort_briefing.dart';
import 'game_state.dart';
import 'market_clock.dart';
import 'market_data.dart';
import 'phone_messenger_state.dart';
import 'weekend_activity.dart';

const phoneAbilityHintMinimumAffection = 20;
const phoneAbilityHintMinimumTrust = 10;
const phoneAbilityHintVerificationAffection = 60;
const phoneAbilityHintVerificationTrust = 50;
const phoneAbilityHintVerificationInvestmentRespect = 40;
const phoneAbilityHintDailyStrongLimit = 2;

enum PhoneAbilityHintLevel {
  /// 관계가 아직 얕을 때 인물의 관찰 기준만 알려 준다.
  lens,

  /// 직전 거래일까지 공개된 사실 한 가지를 알려 준다.
  observation,

  /// 공개 관찰과 함께 그 판단이 깨지는 확인 조건까지 알려 준다.
  verification,

  /// 오늘의 강한 힌트 한도를 이미 사용했다.
  dailyLimit,
}

class PhoneAbilityHint {
  const PhoneAbilityHint({
    required this.contactId,
    required this.ability,
    required this.level,
    required this.lensLine,
    required this.blindSpot,
    this.observation = '',
    this.verificationQuestion = '',
    this.focusAssetName = '',
    this.sourceThroughDate = '',
    this.usesResearchCredit = false,
  });

  final String contactId;
  final String ability;
  final PhoneAbilityHintLevel level;
  final String lensLine;
  final String blindSpot;
  final String observation;
  final String verificationQuestion;
  final String focusAssetName;
  final String sourceThroughDate;
  final bool usesResearchCredit;

  bool get isStrong =>
      level == PhoneAbilityHintLevel.observation ||
      level == PhoneAbilityHintLevel.verification;

  bool get mayNameFocusAsset => isStrong && focusAssetName.isNotEmpty;

  String get localReply {
    switch (level) {
      case PhoneAbilityHintLevel.lens:
        return lensLine;
      case PhoneAbilityHintLevel.observation:
        return observation.isEmpty ? lensLine : observation;
      case PhoneAbilityHintLevel.verification:
        return observation.isEmpty
            ? '$lensLine $verificationQuestion'
            : '$observation $verificationQuestion';
      case PhoneAbilityHintLevel.dailyLimit:
        return '오늘은 이미 깊은 힌트를 다 썼어. 정답을 더 얹지는 않을게. $lensLine';
    }
  }

  PhoneAbilityHint asDailyLimit() => PhoneAbilityHint(
    contactId: contactId,
    ability: ability,
    level: PhoneAbilityHintLevel.dailyLimit,
    lensLine: lensLine,
    blindSpot: blindSpot,
  );
}

class _PhoneAbilityCopy {
  const _PhoneAbilityCopy({
    required this.lensLine,
    required this.verificationQuestion,
    required this.blindSpot,
  });

  final String lensLine;
  final String verificationQuestion;
  final String blindSpot;
}

const _phoneAbilityCopyByContact = <String, _PhoneAbilityCopy>{
  'kim_seoa': _PhoneAbilityCopy(
    lensLine: '정답 대신 기록부터 봐. 회사가 전에 한 말을 실제로 몇 번 지켰는지 확인해 봐.',
    verificationQuestion: '다음 공시에서도 같은 약속을 지키는지 대조하면 돼.',
    blindSpot: '과거의 약속 이행만으로 앞으로의 성과를 보장하지 않는다.',
  ),
  'lee_jian': _PhoneAbilityCopy(
    lensLine: '화면 설명보다 실제로 작동한 걸 봐. 체결가나 제품 결과처럼 손에 잡히는 것부터.',
    verificationQuestion: '표시된 값과 실제 체결·작동 결과가 다시 일치하는지 확인해.',
    blindSpot: '체결과 제품 작동만으로 사업 가치 전체를 단정하지 않는다.',
  ),
  'choi_iseo': _PhoneAbilityCopy(
    lensLine: '가격선의 결이 갑자기 달라진 자리부터 봐. 이상하다는 느낌은 답이 아니라 확인 신호야.',
    verificationQuestion: '다음 움직임에서도 같은 리듬이 이어지는지 보고 판단해.',
    blindSpot: '가격의 이상 징후는 원인이 아니라 추가 확인이 필요한 신호다.',
  ),
  'jung_arin': _PhoneAbilityCopy(
    lensLine: '살 이유보다 나올 조건부터 적어. 실행 순서가 없으면 좋은 계획도 급할 때 엉켜.',
    verificationQuestion: '정한 마감과 철수 조건을 실제로 지킬 수 있는지 먼저 점검해.',
    blindSpot: '실행 계획이 좋아도 수요와 가격이 맞는지는 별도로 확인한다.',
  ),
  'park_haeun': _PhoneAbilityCopy(
    lensLine: '좋은 말보다 누가 말하지 못했는지 봐. 이해관계가 막힌 자리에 빠진 정보가 있을 수 있어.',
    verificationQuestion: '반대 의견을 낼 수 있는 사람에게도 같은 이야기가 나오는지 물어봐.',
    blindSpot: '사람들의 분위기를 확인되지 않은 내부 사실처럼 단정하지 않는다.',
  ),
  'han_sua': _PhoneAbilityCopy(
    lensLine: '사람들이 같은 이름을 다시 꺼내는지 봐. 한 번의 소문보다 반복되는 수요가 중요해.',
    verificationQuestion: '그 관심이 실제 재구매나 매출 숫자로 이어지는지 확인해 봐.',
    blindSpot: '유행의 전조는 일시적인 소문일 수 있으며 매출을 보장하지 않는다.',
  ),
  'oh_jiwoo': _PhoneAbilityCopy(
    lensLine: '지금 믿는 이유가 틀리는 경우를 하나 만들어 봐. 반례가 버티면 가설도 다시 봐야지.',
    verificationQuestion: '어떤 사실이 나오면 네 생각을 바꿀지 먼저 정해 둬.',
    blindSpot: '반례 하나만으로 원래 가설 전체가 틀렸다고 단정하지 않는다.',
  ),
  'yoon_chaea': _PhoneAbilityCopy(
    lensLine: '하루 가격보다 구조를 봐. 네 전제가 무엇이고 언제 깨지는지부터 적어.',
    verificationQuestion: '핵심 전제가 바뀌었을 때 손실 범위가 어디까지인지 다시 계산해.',
    blindSpot: '장기 구조도 전제가 바뀌면 깨지며 미래 결과를 확정하지 않는다.',
  ),
};

bool phoneMessageRequestsResearchCredit(String rawText) {
  final compact = rawText.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  return compact.contains('조사권') || compact.contains('조사보고서권');
}

int phoneStrongAbilityHintsForDay(PhoneMessengerState messenger, int day) =>
    messenger.memories
        .where(
          (memory) =>
              memory.day == day &&
              (memory.abilityHintLevel ==
                      PhoneAbilityHintLevel.observation.name ||
                  memory.abilityHintLevel ==
                      PhoneAbilityHintLevel.verification.name),
        )
        .length;

int phoneResearchCredits(GameState state) =>
    ((state.story.storyFlags[weekendMarketResearchCreditsFlag] as num?)
                ?.toInt() ??
            0)
        .clamp(0, 3);

PhoneAbilityHint? buildPhoneAbilityHint(
  GameState state, {
  required FictionalMarketUniverse universe,
  required String contactId,
  required bool requestsResearchCredit,
}) {
  final definition = cohortBriefingByGirlId(contactId);
  final copy = _phoneAbilityCopyByContact[contactId];
  if (definition == null || copy == null) return null;

  final relationship = state.relationships.progressFor(contactId);
  final canReceiveObservation =
      relationship.affection >= phoneAbilityHintMinimumAffection &&
      relationship.trust >= phoneAbilityHintMinimumTrust;
  if (!canReceiveObservation) {
    return PhoneAbilityHint(
      contactId: contactId,
      ability: definition.ability,
      level: PhoneAbilityHintLevel.lens,
      lensLine: copy.lensLine,
      blindSpot: copy.blindSpot,
    );
  }

  final strongCount = phoneStrongAbilityHintsForDay(
    state.phoneMessenger,
    state.day,
  );
  final mayUseFreeHint = strongCount == 0;
  final mayUseResearchCredit =
      strongCount == phoneAbilityHintDailyStrongLimit - 1 &&
      requestsResearchCredit &&
      phoneResearchCredits(state) > 0;
  if (!mayUseFreeHint && !mayUseResearchCredit) {
    return PhoneAbilityHint(
      contactId: contactId,
      ability: definition.ability,
      level: PhoneAbilityHintLevel.dailyLimit,
      lensLine: copy.lensLine,
      blindSpot: copy.blindSpot,
    );
  }

  final briefing = buildCohortAbilityBriefing(
    state,
    universe: universe,
    girlId: contactId,
  );
  final canReceiveVerification =
      relationship.affection >= phoneAbilityHintVerificationAffection &&
      relationship.trust >= phoneAbilityHintVerificationTrust &&
      relationship.investmentRespect >=
          phoneAbilityHintVerificationInvestmentRespect;
  return PhoneAbilityHint(
    contactId: contactId,
    ability: definition.ability,
    level: canReceiveVerification
        ? PhoneAbilityHintLevel.verification
        : PhoneAbilityHintLevel.observation,
    lensLine: copy.lensLine,
    blindSpot: copy.blindSpot,
    observation: briefing?.observation ?? definition.fallbackObservation,
    verificationQuestion: canReceiveVerification
        ? copy.verificationQuestion
        : '',
    focusAssetName: briefing?.focusAssetName ?? '',
    sourceThroughDate: marketDateKey(
      cohortBriefingPublicThrough(state.currentDate),
    ),
    usesResearchCredit: mayUseResearchCredit,
  );
}

/// The engine applies the final guard even if a caller constructs a hint by
/// hand. A strong hint is free once per day; only the explicitly requested
/// second hint may consume one research credit.
PhoneAbilityHint? enforcePhoneAbilityHintForSend(
  GameState state, {
  required String contactId,
  required String playerIntent,
  PhoneAbilityHint? proposed,
}) {
  if (playerIntent != 'investmentAdvice' ||
      proposed == null ||
      proposed.contactId != contactId) {
    return null;
  }
  if (!proposed.isStrong) return proposed;

  final strongCount = phoneStrongAbilityHintsForDay(
    state.phoneMessenger,
    state.day,
  );
  if (strongCount == 0 && !proposed.usesResearchCredit) return proposed;
  if (strongCount == phoneAbilityHintDailyStrongLimit - 1 &&
      proposed.usesResearchCredit &&
      phoneResearchCredits(state) > 0) {
    return proposed;
  }
  return proposed.asDailyLimit();
}

bool phoneAiReplyViolatesAbilityHintPolicy(
  String rawReply, {
  required PhoneAbilityHint? hint,
  bool enforceInvestmentAdvice = false,
}) {
  if (hint == null && !enforceInvestmentAdvice) return false;
  final reply = rawReply.replaceAll(RegExp(r'\s+'), ' ').trim();
  final forbidden = <RegExp>[
    RegExp(r'(무조건|반드시|확실히).{0,12}(매수|매도|사야|팔아|오른|내린|상승|하락)'),
    RegExp(r'(지금|오늘|당장).{0,8}(매수해|매도해|사야\s*(해|돼)|팔아)'),
    RegExp(r'(몰빵|전량\s*(매수|매도)|매수해|매도해|사라(?:\s|[.!?]|$)|팔아(?:\s|[.!?]|$))'),
    RegExp(r'(오를\s*거야|내릴\s*거야|상승할\s*거야|하락할\s*거야|떨어질\s*거야)'),
    RegExp(r'(목표가|예상가|내일\s*(종가|가격)|미래\s*가격).{0,12}\d[\d,]*\s*원'),
    RegExp(r'(수익|상승|하락).{0,8}(보장|확정)'),
  ];
  return forbidden.any((pattern) => pattern.hasMatch(reply));
}
