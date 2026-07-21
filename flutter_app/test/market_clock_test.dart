import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_news.dart';
import 'package:millennium_capital/game/market_tick.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('market clock follows KRX boundaries and game extension labels', () {
    expect(marketClockAt(8 * 60).phase, MarketSessionPhase.nxtPre);
    expect(
      marketClockAt(8 * 60 + 50).phase,
      MarketSessionPhase.openingTransition,
    );
    expect(marketClockAt(9 * 60).phase, MarketSessionPhase.regular);
    expect(
      marketClockAt(15 * 60 + 20).phase,
      MarketSessionPhase.closingAuction,
    );
    expect(
      marketClockAt(15 * 60 + 30).phase,
      MarketSessionPhase.closeSettlement,
    );
    expect(marketClockAt(15 * 60 + 40).phase, MarketSessionPhase.nxtAfter);
    expect(marketClockAt(20 * 60).phase, MarketSessionPhase.closed);
    expect(marketClockAt(15 * 60 + 40).isGameExtension, isTrue);
  });

  test('weekends and fixed holidays are closed', () {
    expect(isMarketTradingDay(DateTime(2000, 1, 1)), isFalse);
    expect(
      marketClockAt(540, tradingDay: false).phase,
      MarketSessionPhase.holiday,
    );
    expect(isMarketTradingDay(DateTime(2000, 1, 4)), isTrue);
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
    expect(path[krxCloseTick], 11200);
    expect(path.last, 11200);
    expect(path.sublist(krxCloseTick + 1).toSet().length, greaterThan(2));
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
