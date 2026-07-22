import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/mission_progression.dart';
import 'package:millennium_capital/game/seed_money_content.dart';

void main() {
  const engine = GameEngine();

  TradeOrder buySamsung() => const TradeOrder(
    side: TradeSide.buy,
    assetId: 'kr-005930',
    symbol: '005930.KS',
    name: '삼성전자',
    market: 'KOSPI',
    currency: 'KRW',
    quantity: 1,
    unitPrice: 10000,
    quoteDate: '2000-01-04',
    marketMinute: 9 * 60,
    isTradingDay: true,
  );

  test(
    'first decision completes a mission and claiming advances the chain',
    () {
      final base = engine.createNewGame('미션 보상 테스트');
      final resolved = engine.resolveDecision(
        base,
        'first-research-note',
        'research_products',
      );
      final progress = engine.missionProgress(resolved)!;
      final claim = engine.claimMission(resolved);

      expect(progress.mission.id, 'first_note');
      expect(progress.complete, isTrue);
      expect(resolved.progression.experience, 25);
      expect(claim.success, isTrue);
      expect(claim.cashReward, 500);
      expect(claim.state.cash, 500);
      expect(claim.state.progression.experience, 105);
      expect(claim.state.progression.activeMission?.id, 'first_work');
      expect(claim.state.progression.claimedMissionIds, contains('first_note'));
      expect(claim.state.ledger.last.counterAccount, 'mission_reward');
    },
  );

  test(
    'work completed before claiming the first mission is still recognized',
    () {
      final base = engine.createNewGame('선행 일거리 미션 테스트');
      final resolved = engine.resolveDecision(
        base,
        'first-research-note',
        'research_products',
      );
      final worked = engine.completeWorkSession(
        resolved,
        const WorkSessionResult(
          activityId: 'dishes',
          score: 100,
          maxScore: 100,
        ),
      );
      final claim = engine.claimMission(worked);
      final nextProgress = engine.missionProgress(claim.state)!;

      expect(claim.success, isTrue);
      expect(nextProgress.mission.id, 'first_work');
      expect(nextProgress.current, greaterThanOrEqualTo(1));
      expect(nextProgress.complete, isTrue);
    },
  );

  test('campaign age stays ten in 2000 and twenty in 2010', () {
    final story = engine.createNewGame('나이 기준 테스트').story;

    expect(story.ageOn(DateTime(2000, 1, 2)), 10);
    expect(story.ageOn(DateTime(2010, 12, 31)), 20);
  });

  test('level skills change work rewards and trading fees', () {
    final base = engine
        .createNewGame('스킬 효과 테스트', initialCash: 200000)
        .copyWith(day: 4, marketMinute: 9 * 60, decisions: const []);
    final skilledWork = base.copyWith(
      progression: base.progression.copyWith(experience: 120),
    );
    const work = WorkSessionResult(
      activityId: 'dishes',
      score: 100,
      maxScore: 100,
    );
    final normalWork = engine.completeWorkSession(base, work);
    final bonusWork = engine.completeWorkSession(skilledWork, work);

    expect(
      bonusWork.cash - skilledWork.cash,
      greaterThan(normalWork.cash - base.cash),
    );
    expect(bonusWork.progression.counter('work_sessions'), 1);

    final feeSkilled = base.copyWith(
      progression: base.progression.copyWith(experience: 300),
    );
    final normalTrade = engine.executeTrade(base, buySamsung());
    final discountedTrade = engine.executeTrade(feeSkilled, buySamsung());
    expect(normalTrade.success, isTrue);
    expect(discountedTrade.success, isTrue);
    expect(discountedTrade.fee, lessThan(normalTrade.fee));
    expect(discountedTrade.state.progression.counter('buy_orders'), 1);
    expect(discountedTrade.state.progression.counter('shares_bought'), 1);
  });

  test('an expired 30-day cash mission restarts without a penalty', () {
    final missionIndex = missionCatalog.indexWhere(
      (mission) => mission.id == 'earn_100k_30d',
    );
    final base = engine
        .createNewGame('30일 미션 테스트', initialCash: 120000)
        .copyWith(day: 31, decisions: const []);
    final state = base.copyWith(
      progression: base.progression.copyWith(
        currentMissionIndex: missionIndex,
        missionStartedDay: 1,
        missionStartCash: 100000,
        missionStartCounter: 0,
      ),
    );

    final next = engine.advanceOneDay(state);

    expect(next.day, 32);
    expect(next.progression.missionStartedDay, 32);
    expect(next.progression.missionStartCash, 120000);
    expect(engine.missionProgress(next)!.remainingDays, 30);
  });

  test('v11 saves migrate to v12 with a safe mission chain', () {
    final legacy = engine.createNewGame('v11 미션 마이그레이션').toJson()
      ..remove('progression')
      ..['version'] = 11;

    final migrated = engine.migrate(legacy);

    expect(migrated.version, GameState.schemaVersion);
    expect(migrated.cash, 0);
    expect(migrated.progression.experience, 0);
    expect(migrated.progression.activeMission?.id, 'first_note');
  });
}
