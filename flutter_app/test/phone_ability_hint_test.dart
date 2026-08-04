import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/cohort_briefing.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/phone_ability_hint.dart';
import 'package:millennium_capital/game/relationship_state.dart';
import 'package:millennium_capital/game/weekend_activity.dart';

import 'support/market_fixture.dart';

void main() {
  const engine = GameEngine();

  GameState withRelationship(
    GameState state,
    String girlId, {
    required int affection,
    required int trust,
    int investmentRespect = 20,
  }) {
    final current = state.relationships.progressFor(girlId);
    return state.copyWith(
      relationships: state.relationships.copyWith(
        girls: <String, GirlRelationshipProgress>{
          ...state.relationships.girls,
          girlId: current.copyWith(
            affection: affection,
            trust: trust,
            investmentRespect: investmentRespect,
          ),
        },
      ),
    );
  }

  test('all eight girls expose only their own lens at low relationship', () {
    final state = engine
        .createNewGame('능력 렌즈', worldSeed: 'phone-hint-lens')
        .copyWith(day: 4);
    final universe = testMarketUniverse(tradingDate: state.currentDate);
    final abilities = <String>{};
    final lines = <String>{};

    for (final definition in cohortBriefingRotation) {
      final hint = buildPhoneAbilityHint(
        state,
        universe: universe,
        contactId: definition.girlId,
        requestsResearchCredit: false,
      );
      expect(hint, isNotNull);
      expect(hint!.level, PhoneAbilityHintLevel.lens);
      expect(hint.isStrong, isFalse);
      expect(hint.observation, isEmpty);
      expect(hint.focusAssetName, isEmpty);
      abilities.add(hint.ability);
      lines.add(hint.lensLine);
    }

    expect(abilities, hasLength(8));
    expect(lines, hasLength(8));
  });

  test(
    'one strong hint is free and an explicit second hint spends one credit',
    () {
      var state = engine
          .createNewGame('능력 일일 제한', worldSeed: 'phone-hint-limit')
          .copyWith(day: 4);
      state = withRelationship(state, 'kim_seoa', affection: 35, trust: 20);
      state = withRelationship(state, 'lee_jian', affection: 35, trust: 20);
      final universe = testMarketUniverse(tradingDate: state.currentDate);

      final firstHint = buildPhoneAbilityHint(
        state,
        universe: universe,
        contactId: 'kim_seoa',
        requestsResearchCredit: false,
      )!;
      expect(firstHint.level, PhoneAbilityHintLevel.observation);
      expect(firstHint.sourceThroughDate, isNotEmpty);
      expect(firstHint.usesResearchCredit, isFalse);

      final first = engine.sendPhoneMessage(
        state,
        contactId: 'kim_seoa',
        text: '기록 힌트 하나 줘',
        abilityHint: firstHint,
      );
      expect(first.success, isTrue);
      expect(first.abilityHint?.isStrong, isTrue);
      expect(
        first.state.phoneMessenger
            .memoriesFor('kim_seoa')
            .last
            .abilityHintLevel,
        PhoneAbilityHintLevel.observation.name,
      );

      state = first.state.copyWith(
        story: first.state.story.copyWith(
          storyFlags: <String, dynamic>{
            ...first.state.story.storyFlags,
            weekendMarketResearchCreditsFlag: 1,
          },
        ),
      );
      final capped = buildPhoneAbilityHint(
        state,
        universe: universe,
        contactId: 'lee_jian',
        requestsResearchCredit: false,
      )!;
      expect(capped.level, PhoneAbilityHintLevel.dailyLimit);

      final paidHint = buildPhoneAbilityHint(
        state,
        universe: universe,
        contactId: 'lee_jian',
        requestsResearchCredit: true,
      )!;
      expect(paidHint.isStrong, isTrue);
      expect(paidHint.usesResearchCredit, isTrue);

      final second = engine.sendPhoneMessage(
        state,
        contactId: 'lee_jian',
        text: '조사권 써서 체결 힌트 하나 줘',
        abilityHint: paidHint,
      );
      expect(second.success, isTrue);
      expect(
        second.state.story.storyFlags[weekendMarketResearchCreditsFlag],
        0,
      );
      expect(
        phoneStrongAbilityHintsForDay(second.state.phoneMessenger, state.day),
        phoneAbilityHintDailyStrongLimit,
      );
    },
  );

  test(
    'high trust unlocks a verification condition but never a trade order',
    () {
      var state = engine
          .createNewGame('능력 확인 조건', worldSeed: 'phone-hint-verification')
          .copyWith(day: 4);
      state = withRelationship(
        state,
        'oh_jiwoo',
        affection: 70,
        trust: 60,
        investmentRespect: 55,
      );
      final universe = testMarketUniverse(tradingDate: state.currentDate);
      final hint = buildPhoneAbilityHint(
        state,
        universe: universe,
        contactId: 'oh_jiwoo',
        requestsResearchCredit: false,
      )!;

      expect(hint.level, PhoneAbilityHintLevel.verification);
      expect(hint.verificationQuestion, isNotEmpty);
      expect(hint.localReply, isNot(contains('매수해')));
      expect(hint.localReply, isNot(contains('매도해')));
    },
  );

  test('AI reply guard rejects direct orders and future target prices', () {
    const hint = PhoneAbilityHint(
      contactId: 'han_sua',
      ability: '테마와 수요 전조',
      level: PhoneAbilityHintLevel.observation,
      lensLine: '반복되는 수요를 봐.',
      blindSpot: '소문은 매출을 보장하지 않는다.',
      observation: '어제 이름이 여러 번 나왔어.',
      sourceThroughDate: '2000-01-03',
    );

    expect(
      phoneAiReplyViolatesAbilityHintPolicy(
        '지금 당장 매수해. 무조건 오를 거야.',
        hint: hint,
      ),
      isTrue,
    );
    expect(
      phoneAiReplyViolatesAbilityHintPolicy('내일 목표가는 12,000원이야.', hint: hint),
      isTrue,
    );
    expect(
      phoneAiReplyViolatesAbilityHintPolicy(
        '이름이 도는 건 사실인데 실제 수요인지는 더 보자.',
        hint: hint,
      ),
      isFalse,
    );
  });
}
