import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/phone_dialogue_composer.dart';
import 'package:millennium_capital/game/phone_messenger_state.dart';
import 'package:millennium_capital/game/relationship_state.dart';

const _qualityIntentTexts = <PhonePlayerIntent, String>{
  PhonePlayerIntent.boundary: '멍청하네, 꺼져',
  PhonePlayerIntent.apology: '아까는 내가 잘못했어. 미안해',
  PhonePlayerIntent.gratitude: '오늘 도와줘서 정말 고마워',
  PhonePlayerIntent.lossShare: '오늘 주식으로 돈을 잃었어',
  PhonePlayerIntent.gainShare: '오늘 주식으로 돈을 벌었어',
  PhonePlayerIntent.investmentAdvice: '내일은 뭘 사면 좋을까?',
  PhonePlayerIntent.investmentReflection: '오늘 투자 판단을 같이 복기하자',
  PhonePlayerIntent.emotionalSupport: '투자 손실 때문에 불안하고 힘들어',
  PhonePlayerIntent.planning: '주말에 같이 만날 계획 세울래?',
  PhonePlayerIntent.classHelp: '컴퓨터 실습이 헷갈려',
  PhonePlayerIntent.casual: '안녕, 지금 뭐 해?',
  PhonePlayerIntent.unknown: '그거 있잖아, 아무튼 그거',
};

final _stiffDialogueFragments = RegExp(
  r'일간·누적|판단 보류|관찰 구간|노출도|포지션|계산 범위를 명시|'
  r'항목을 분리|결과 없이 회의|수치 목표|마감 시점|뇌정지|느좋|힙함',
);

PhoneInvestmentConversationContext _qualityInvestment(
  PhoneInvestmentSituation situation,
) => switch (situation) {
  PhoneInvestmentSituation.unavailable =>
    const PhoneInvestmentConversationContext(),
  PhoneInvestmentSituation.marketClosed =>
    const PhoneInvestmentConversationContext(marketClosed: true),
  PhoneInvestmentSituation.flat => const PhoneInvestmentConversationContext(
    hasCurrentReport: true,
  ),
  PhoneInvestmentSituation.thriving => const PhoneInvestmentConversationContext(
    hasCurrentReport: true,
    playerDailyProfitLoss: 1000,
    playerCumulativeProfitLoss: 5000,
  ),
  PhoneInvestmentSituation.recovering =>
    const PhoneInvestmentConversationContext(
      hasCurrentReport: true,
      playerDailyProfitLoss: 1000,
      playerCumulativeProfitLoss: -5000,
    ),
  PhoneInvestmentSituation.protectingGains =>
    const PhoneInvestmentConversationContext(
      hasCurrentReport: true,
      playerDailyProfitLoss: -1000,
      playerCumulativeProfitLoss: 5000,
    ),
  PhoneInvestmentSituation.deepeningLoss =>
    const PhoneInvestmentConversationContext(
      hasCurrentReport: true,
      playerDailyProfitLoss: -1000,
      playerCumulativeProfitLoss: -5000,
    ),
};

void main() {
  test('intent classifier separates relationship and investment meanings', () {
    expect(classifyPhoneIntent('미안해. 내가 잘못했어'), PhonePlayerIntent.apology);
    expect(classifyPhoneIntent('오늘 주식으로 돈을 잃었어'), PhonePlayerIntent.lossShare);
    expect(classifyPhoneIntent('오늘 손실을 조금 회복했어'), PhonePlayerIntent.gainShare);
    expect(classifyPhoneIntent('덕분에 실습 끝냈어, 고마워'), PhonePlayerIntent.gratitude);
    expect(classifyPhoneIntent('내일 주말에 같이 만날래?'), PhonePlayerIntent.planning);
    expect(classifyPhoneIntent('이 말은 잘 모르겠어'), PhonePlayerIntent.classHelp);
    expect(
      classifyPhoneIntent('투자 손실 때문에 너무 불안하고 힘들어'),
      PhonePlayerIntent.emotionalSupport,
    );
  });

  test('daily and cumulative profit create four different situations', () {
    PhoneInvestmentSituation situation(int daily, int cumulative) =>
        PhoneInvestmentConversationContext(
          hasCurrentReport: true,
          playerDailyProfitLoss: daily,
          playerCumulativeProfitLoss: cumulative,
        ).situation;

    expect(situation(1000, 3000), PhoneInvestmentSituation.thriving);
    expect(situation(1000, -3000), PhoneInvestmentSituation.recovering);
    expect(situation(-1000, 3000), PhoneInvestmentSituation.protectingGains);
    expect(situation(-1000, -3000), PhoneInvestmentSituation.deepeningLoss);
  });

  test(
    'composer exposes hundreds of thousands of deterministic combinations',
    () {
      expect(phoneDialogueCombinationSpace, greaterThan(100000));
      final replies = <String>{};
      for (final contact in phoneMessengerContacts) {
        final context = PhoneDialogueContext(
          worldSeed: 'composer-personality',
          day: 12,
          marketMinute: 1200,
          contact: contact,
          progress: PhoneThreadProgress(contactId: contact.id),
          relationship: contact.id == 'kim_hakjun'
              ? null
              : const GirlRelationshipProgress(
                  affection: 42,
                  trust: 35,
                  closeness: 47,
                  investmentRespect: 51,
                ),
          investment: const PhoneInvestmentConversationContext(
            hasCurrentReport: true,
            playerDailyProfitLoss: 1200,
            playerCumulativeProfitLoss: -5300,
            playerRank: 6,
          ),
        );
        final first = composePhoneReply(context, '오늘 손실을 조금 회복했어');
        final second = composePhoneReply(context, '오늘 손실을 조금 회복했어');
        expect(second.text, first.text);
        expect(first.investmentSituation, PhoneInvestmentSituation.recovering);
        replies.add(first.text);
      }
      expect(replies, hasLength(phoneMessengerContacts.length));
    },
  );

  test('composer recalls only a past day and does not read future memory', () {
    final contact = phoneContactById('yoon_chaea')!;
    const past = PhoneConversationMemory(
      id: 'past',
      contactId: 'yoon_chaea',
      day: 2,
      intent: 'planning',
      investmentSituation: 'flat',
      playerText: '한 달 계획을 지켜 볼게',
      replyText: '전제를 기록해 둘게.',
    );
    const future = PhoneConversationMemory(
      id: 'future',
      contactId: 'yoon_chaea',
      day: 99,
      intent: 'gainShare',
      investmentSituation: 'thriving',
      playerText: '미래에 대박이 났어',
      replyText: '미래 답변',
    );
    final reply = composePhoneReply(
      PhoneDialogueContext(
        worldSeed: 'memory-filter',
        day: 3,
        marketMinute: 1200,
        contact: contact,
        progress: const PhoneThreadProgress(contactId: 'yoon_chaea'),
        relationship: const GirlRelationshipProgress(affection: 60),
        investment: const PhoneInvestmentConversationContext(),
        recentMemories: const [past, future],
      ),
      '내일 계획을 다시 세울까?',
    );
    expect(reply.text, isNot(contains('미래에 대박')));
  });

  test('all composed samples stay complete and within four sentences', () {
    const stageAffection = <int>[1, 20, 40, 60, 80, 100];
    for (final contact in phoneMessengerContacts) {
      for (final affection in stageAffection) {
        for (final situation in PhoneInvestmentSituation.values) {
          for (final intent in PhonePlayerIntent.values) {
            for (var sequence = 0; sequence < 2; sequence++) {
              final reply = composePhoneReply(
                PhoneDialogueContext(
                  worldSeed: 'quality-$sequence',
                  day: 10,
                  marketMinute: 1200,
                  contact: contact,
                  progress: PhoneThreadProgress(
                    contactId: contact.id,
                    totalExchanges: sequence,
                  ),
                  relationship: contact.id == 'kim_hakjun'
                      ? null
                      : GirlRelationshipProgress(affection: affection),
                  investment: _qualityInvestment(situation),
                  recentMemories: [
                    PhoneConversationMemory(
                      id: 'memory-$sequence',
                      contactId: contact.id,
                      day: 2,
                      intent: 'planning',
                      investmentSituation: 'flat',
                      playerText: '한 달 동안 원칙을 지켜 보기로 했어',
                      replyText: '기억해 둘게.',
                    ),
                  ],
                ),
                _qualityIntentTexts[intent]!,
              );
              final sentenceCount = RegExp(
                r'[.!?](?:\s|$)',
              ).allMatches(reply.text).length;
              expect(
                reply.text,
                isNotEmpty,
                reason: '$contact $intent $situation',
              );
              expect(reply.text.length, lessThanOrEqualTo(240));
              expect(reply.text.endsWith('…'), isFalse);
              expect(sentenceCount, lessThanOrEqualTo(4));
              expect(reply.text, isNot(contains('  ')));
              expect(
                _stiffDialogueFragments.hasMatch(reply.text),
                isFalse,
                reason: reply.text,
              );
            }
          }
        }
      }
    }
  });

  test(
    'a claim contradicting both daily and cumulative results is corrected',
    () {
      final contact = phoneContactById('kim_seoa')!;
      final reply = composePhoneReply(
        PhoneDialogueContext(
          worldSeed: 'claim-conflict',
          day: 10,
          marketMinute: 1200,
          contact: contact,
          progress: const PhoneThreadProgress(contactId: 'kim_seoa'),
          relationship: const GirlRelationshipProgress(affection: 40),
          investment: const PhoneInvestmentConversationContext(
            hasCurrentReport: true,
            playerDailyProfitLoss: -1000,
            playerCumulativeProfitLoss: -5000,
          ),
        ),
        '오늘 주식으로 돈을 벌었어',
      );
      expect(reply.text, contains('손해'));
      expect(reply.text, isNot(contains('번 돈과')));
      expect(reply.affectionDelta, 0);
      expect(reply.trustDelta, -1);
      expect(reply.investmentRespectDelta, -1);
    },
  );

  test('an explicit today claim is checked against the daily result', () {
    final contact = phoneContactById('oh_jiwoo')!;
    final reply = composePhoneReply(
      PhoneDialogueContext(
        worldSeed: 'daily-claim-conflict',
        day: 10,
        marketMinute: 1200,
        contact: contact,
        progress: const PhoneThreadProgress(contactId: 'oh_jiwoo'),
        relationship: const GirlRelationshipProgress(affection: 40),
        investment: const PhoneInvestmentConversationContext(
          hasCurrentReport: true,
          playerDailyProfitLoss: 1000,
          playerCumulativeProfitLoss: -5000,
        ),
      ),
      '오늘 주식으로 돈을 잃었어',
    );
    expect(reply.text, contains('오늘은 수익'));
    expect(reply.text, contains('전체가 아직 마이너스'));
    expect(reply.trustDelta, -1);
  });
}
