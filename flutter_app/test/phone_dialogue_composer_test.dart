import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/phone_dialogue_composer.dart';
import 'package:millennium_capital/game/phone_messenger_state.dart';
import 'package:millennium_capital/game/relationship_state.dart';

void main() {
  test('intent classifier separates relationship and investment meanings', () {
    expect(classifyPhoneIntent('미안해. 내가 잘못했어'), PhonePlayerIntent.apology);
    expect(classifyPhoneIntent('오늘 주식으로 돈을 잃었어'), PhonePlayerIntent.lossShare);
    expect(classifyPhoneIntent('덕분에 실습 끝냈어, 고마워'), PhonePlayerIntent.gratitude);
    expect(classifyPhoneIntent('내일 주말에 같이 만날래?'), PhonePlayerIntent.planning);
    expect(classifyPhoneIntent('이 말은 잘 모르겠어'), PhonePlayerIntent.classHelp);
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
}
