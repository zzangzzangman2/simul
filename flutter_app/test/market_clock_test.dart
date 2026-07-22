import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_news.dart';
import 'package:millennium_capital/game/market_tick.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('market clock stays closed until the 09:00 KRX open', () {
    expect(marketClockAt(8 * 60).phase, MarketSessionPhase.openingTransition);
    expect(marketClockAt(8 * 60).tradable, isFalse);
    expect(marketClockAt(8 * 60 + 59).tradable, isFalse);
    expect(marketClockAt(9 * 60).phase, MarketSessionPhase.regular);
    expect(marketClockAt(9 * 60).tradable, isTrue);
    expect(
      marketClockAt(15 * 60 + 20).phase,
      MarketSessionPhase.closingAuction,
    );
    expect(
      marketClockAt(15 * 60 + 30).phase,
      MarketSessionPhase.closeSettlement,
    );
    expect(
      marketClockAt(15 * 60 + 40).phase,
      MarketSessionPhase.closeSettlement,
    );
    expect(marketClockAt(15 * 60 + 40).tradable, isFalse);
    expect(marketClockAt(20 * 60).phase, MarketSessionPhase.closed);
  });

  test('weekends and fixed holidays are closed', () {
    expect(isMarketTradingDay(DateTime(2000, 1, 1)), isFalse);
    expect(
      marketClockAt(540, tradingDay: false).phase,
      MarketSessionPhase.holiday,
    );
    expect(isMarketTradingDay(DateTime(2000, 1, 4)), isTrue);
  });

  test('market tick advances one game minute per real second', () {
    expect(marketTickMinutes, 1);
    expect(marketRealtimeTickDuration, const Duration(seconds: 1));
    expect(marketTickForMinute(8 * 60), 0);
    expect(marketTickForMinute(8 * 60 + 1), 1);
    expect(marketMinuteForTick(1), 8 * 60 + 1);
  });

  test('market tick anchors actual close at 15:30 and finishes at 20:00', () {
    expect(marketTickForMinute(8 * 60), 0);
    expect(marketTickForMinute(15 * 60 + 30), krxCloseTick);
    expect(marketTickForMinute(20 * 60), generatedSessionTicks);
    final path = generatedFullMarketDayPath(
      previousClose: 10000,
      officialClose: 11200,
      seed: 77,
    );
    expect(path, hasLength(generatedSessionTicks + 1));
    expect(
      path.take(generatedPreOpenTicks + 1).toSet(),
      <double>{10000},
      reason: '08:00~09:00 가격은 이전 종가로 고정되어야 한다.',
    );
    expect(path[generatedPreOpenTicks + 1], isNot(10000));
    expect(path[krxCloseTick], 11200);
    expect(path.sublist(krxCloseTick).toSet(), <double>{11200});
    expect(path.last, 11200);

    final openingCandles = aggregateMarketCandles(
      path.sublist(generatedPreOpenTicks, generatedPreOpenTicks + 3),
      1,
      tickMinutes: marketTickMinutes,
    );
    expect(openingCandles, hasLength(2));
    expect(openingCandles.first.open, path[generatedPreOpenTicks]);
    expect(openingCandles.first.close, path[generatedPreOpenTicks + 1]);
    expect(openingCandles.last.open, openingCandles.first.close);
    expect(openingCandles.last.close, path[generatedPreOpenTicks + 2]);
  });

  test('saved clock resets to 08:00 after the newspaper advances a day', () {
    const engine = GameEngine();
    final state = engine
        .createNewGame('테스트')
        .copyWith(decisions: const [], marketMinute: marketDayEndMinute);
    final next = engine.advanceOneDay(state);
    expect(next.day, state.day + 1);
    expect(next.marketMinute, marketDayStartMinute);
  });

  test(
    'daily newspaper summarizes actual domestic closes without future leak',
    () async {
      const engine = GameEngine();
      final state = engine.createNewGame('Market Desk').copyWith(day: 5);
      final paper = await buildDailyMarketNewspaper(state);
      expect(paper.date, DateTime(2000, 1, 5));
      expect(paper.total, greaterThan(0));
      expect(paper.advancers + paper.decliners + paper.unchanged, paper.total);
      expect(paper.headline, isNotEmpty);
    },
  );

  test('meaningful actions consume rational chunks of the game day', () {
    expect(
      advanceGameTime(marketDayStartMinute, decisionActionMinutes),
      8 * 60 + 30,
    );
    expect(
      advanceGameTime(marketDayStartMinute, familyHelpActionMinutes),
      8 * 60 + 30,
    );
    expect(advanceGameTime(marketDayStartMinute, workActionMinutes), 9 * 60);
    expect(
      advanceGameTime(19 * 60 + 30, workActionMinutes),
      marketDayEndMinute,
    );
  });
}
