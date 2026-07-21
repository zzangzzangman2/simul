import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/seed_money_content.dart';
import 'package:millennium_capital/game/story_state.dart';

void main() {
  const engine = GameEngine();

  GameState resolveFirst(GameState state, String optionId) {
    return engine.resolveDecision(
      state,
      state.pendingDecisions.first.id,
      optionId,
    );
  }

  GameState unlockApple(GameState state) {
    state = resolveFirst(state, 'research_products');
    state = state.copyWith(day: 2557, cash: 1000000);
    return engine.advanceOneDay(state);
  }

  GameState advanceUntilDecision(GameState state, {int limit = 30}) {
    var next = state;
    for (var i = 0; i < limit && next.pendingDecisions.isEmpty; i++) {
      next = engine.advanceOneDay(next);
    }
    return next;
  }

  test('new game starts as a guardian-approved family research desk', () {
    final story = StoryState.newPlayer(
      playerName: '민준',
      introChoice: 'computer',
      startingTrait: StoryTrait.analysis,
      familyRule: FamilyRule.reportLosses,
    );
    final state = engine.createNewGame('별빛', story: story);

    expect(state.version, GameState.schemaVersion);
    expect(state.story.playerName, '민준');
    expect(state.cash, 0);
    expect(state.story.guardianAccountHolder, 'mother');
    expect(state.story.storyFlags['guardianConsent'], isTrue);
    expect(state.story.storyFlags['isLegalCompany'], isFalse);
    expect(state.pendingDecisions.first.id, 'first-research-note');
  });

  test('first research choice changes trust and is applied only once', () {
    var state = engine.createNewGame('조사 연구소');
    final decisionId = state.pendingDecisions.first.id;
    final trustBefore = state.story.familyTrust;
    state = engine.resolveDecision(state, decisionId, 'research_cashflow');
    final afterFirst = state;
    state = engine.resolveDecision(state, decisionId, 'research_cashflow');

    expect(afterFirst.story.familyTrust, trustBefore + 1);
    expect(afterFirst.story.storyFlags['firstResearchFocus'], 'cashflow');
    expect(state.toJson(), afterFirst.toJson());
  });

  test('Apple control is gated until 2007 and preserves divergence price', () {
    var state = engine.createNewGame('테스트 연구소');
    state = resolveFirst(state, 'research_products');
    expect(state.pendingDecisions, isEmpty);

    state = state.copyWith(day: 2557, cash: 1000000);
    state = engine.advanceOneDay(state);
    expect(state.pendingDecisions.first.title, contains('Apple'));
    final historical = engine.visiblePrice(state);
    state = resolveFirst(state, 'acquire_control');

    expect(state.company.worldMode, WorldMode.diverged);
    expect(state.company.divergedAtDay, 2558);
    expect(state.company.simulatedPrice, historical);
    expect(state.company.historicalPriceAtDivergence, historical);
  });

  test('same seed and same choices produce the same delayed result', () {
    GameState play(GameState state) {
      state = unlockApple(state);
      state = resolveFirst(state, 'acquire_control');
      state = resolveFirst(state, 'approve_full');
      state = advanceUntilDecision(state);
      state = resolveFirst(state, 'fix_quality');
      state = advanceUntilDecision(state);
      state = resolveFirst(state, 'launch_now');
      state = advanceUntilDecision(state);
      return state;
    }

    final first = play(engine.createNewGame('같은 연구소'));
    final second = play(engine.createNewGame('같은 연구소'));

    expect(first.toJson(), second.toJson());
    expect(first.project?.status, ProjectStatus.completed);
  });

  test('approval and rejection retain different tradeoffs', () {
    var approved = unlockApple(engine.createNewGame('승인 연구소'));
    approved = resolveFirst(approved, 'acquire_control');
    final beforeApproval = approved;
    approved = resolveFirst(approved, 'approve_full');

    expect(approved.cash, lessThan(beforeApproval.cash));
    expect(approved.company.morale, greaterThan(beforeApproval.company.morale));
    expect(approved.company.risk, greaterThan(beforeApproval.company.risk));

    var rejected = unlockApple(engine.createNewGame('거절 연구소'));
    rejected = resolveFirst(rejected, 'acquire_control');
    rejected = resolveFirst(rejected, 'reject_project');

    expect(rejected.cash, greaterThan(approved.cash));
    expect(rejected.company.morale, lessThan(approved.company.morale));
    expect(rejected.project?.status, ProjectStatus.cancelled);
  });

  test('family helper fatigue, daily limit, and recovery are persisted', () {
    var state = engine.createNewGame('가족 연구소');
    state = resolveFirst(state, 'research_products');
    final motherBefore = state.organization.familyHelpers.first;

    state = engine.requestFamilyHelp(state, 'mother');
    final afterHelp = state.organization.familyHelpers.first;
    expect(afterHelp.fatigue, motherBefore.fatigue + 12);
    expect(afterHelp.helpCount, 1);
    expect(state.organization.helpLog, hasLength(1));

    final duplicate = engine.requestFamilyHelp(state, 'mother');
    expect(duplicate.toJson(), state.toJson());

    state = engine.advanceOneDay(state);
    final afterRest = state.organization.familyHelpers.first;
    expect(afterRest.fatigue, afterHelp.fatigue - 3);
  });
  test(
    'work sessions earn period-scale cash, write ledger, and stop at three per day',
    () {
      var state = engine.createNewGame('0원 연구소', initialCash: 0);
      expect(state.cash, 0);

      state = engine.completeWorkSession(
        state,
        const WorkSessionResult(
          activityId: 'dishes',
          score: 100,
          maxScore: 100,
        ),
      );
      expect(state.cash, 800);
      expect(state.ledger.last.counterAccount, 'work_income');
      expect(state.story.storyFlags['earnedSeedMoney'], 800);

      state = engine.completeWorkSession(
        state,
        const WorkSessionResult(
          activityId: 'stationery',
          score: 100,
          maxScore: 100,
        ),
      );
      state = engine.completeWorkSession(
        state,
        const WorkSessionResult(
          activityId: 'flea_market',
          score: 100,
          maxScore: 100,
        ),
      );
      final afterThree = state;
      state = engine.completeWorkSession(
        state,
        const WorkSessionResult(
          activityId: 'dishes',
          score: 100,
          maxScore: 100,
        ),
      );

      expect(state.toJson(), afterThree.toJson());
      expect(state.story.storyFlags['workSessionsToday'], 3);
      expect(state.cash, 3400);
    },
  );
  test('v1 save migrates without deleting company, cash, day, or story', () {
    final state = engine.migrate({
      'version': 1,
      'companyName': '옛 저장 연구소',
      'day': 17,
      'cash': 765432,
      'team': 2,
    });

    expect(state.version, GameState.schemaVersion);
    expect(state.companyName, '옛 저장 연구소');
    expect(state.day, 17);
    expect(state.cash, 765432);
    expect(state.team, 2);
    expect(state.story.playerName, '소년');
    expect(state.story.storyFlags['guardianConsent'], isTrue);
  });
}
