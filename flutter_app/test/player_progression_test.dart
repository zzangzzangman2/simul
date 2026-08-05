import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/player_progression.dart';
import 'package:millennium_capital/game/seed_money_content.dart';

void main() {
  const engine = GameEngine();

  TradeOrder buyHanbit() => const TradeOrder(
    side: TradeSide.buy,
    assetId: 'hanbit_telecom',
    symbol: '1001',
    name: '한빛통신',
    market: '미래시장',
    currency: 'KRW',
    quantity: 1,
    unitPrice: 10000,
    quoteDate: '2000-01-05',
    marketMinute: 9 * 60,
    isTradingDay: true,
  );

  test('progression persistence contains only experience and counters', () {
    final state = PlayerProgressionState.fromJson(<String, dynamic>{
      'experience': 300,
      'counters': <String, int>{'work_sessions': 2},
      'unusedLegacyValue': 99,
    });

    expect(state.level, 3);
    expect(state.counter('work_sessions'), 2);
    expect(state.toJson().keys, unorderedEquals(['experience', 'counters']));
  });

  test('meaningful actions can add bounded experience independently', () {
    final initial = PlayerProgressionState.initial();
    final progressed = initial.record('research_sessions').gainExperience(125);

    expect(progressed.counter('research_sessions'), 1);
    expect(progressed.experience, 125);
    expect(progressed.level, 2);
    expect(initial.experience, 0);
  });

  test('level skills change work rewards and trading fees', () {
    final base = engine
        .createNewGame('스킬 효과 테스트', initialCash: 200000)
        .copyWith(day: 5, marketMinute: 9 * 60, decisions: const []);
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
    final normalTrade = engine.executeTrade(base, buyHanbit());
    final discountedTrade = engine.executeTrade(feeSkilled, buyHanbit());
    expect(normalTrade.success, isTrue);
    expect(discountedTrade.success, isTrue);
    expect(discountedTrade.fee, lessThan(normalTrade.fee));
    expect(discountedTrade.state.progression.counter('buy_orders'), 1);
    expect(discountedTrade.state.progression.counter('shares_bought'), 1);
  });

  test('Decimal peers use the Korean year-age convention', () {
    final story = engine.createNewGame('나이 기준 테스트').story;

    expect(story.ageOn(DateTime(2000, 1, 2)), 14);
    expect(story.ageOn(DateTime(2010, 12, 31)), 24);
  });
}
