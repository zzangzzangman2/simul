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
      marketClockAt(14 * 60 + 50).phase,
      MarketSessionPhase.closingAuction,
    );
    expect(marketClockAt(15 * 60).phase, MarketSessionPhase.closeSettlement);
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
    expect(isMarketTradingDay(DateTime(2000, 1, 3)), isTrue);
    expect(isMarketTradingDay(DateTime(2000, 1, 4)), isTrue);
  });

  test('corpus trading calendar preserves later exchange holidays', () {
    expect(isMarketTradingDay(DateTime(2022, 9, 8)), isTrue);
    expect(isMarketTradingDay(DateTime(2022, 9, 9)), isFalse);
    expect(isMarketTradingDay(DateTime(2023, 1, 23)), isFalse);
    expect(isMarketTradingDay(DateTime(2026, 7, 23)), isTrue);
    expect(isMarketTradingDay(DateTime(2026, 8, 17)), isFalse);
    expect(isMarketTradingDay(DateTime(2026, 9, 24)), isFalse);
    expect(isMarketTradingDay(DateTime(2026, 9, 25)), isFalse);
    expect(isMarketTradingDay(DateTime(2026, 10, 5)), isFalse);
    expect(isMarketTradingDay(DateTime(2026, 10, 9)), isFalse);
    expect(
      isMarketTradingDay(DateTime(2026, 12, 31)),
      isFalse,
      reason: '캠페인 마지막 날은 연말 휴장으로 평가 가격을 만들면 안 된다.',
    );
  });

  test('market tick advances one game minute per real second', () {
    expect(marketTickMinutes, 1);
    expect(marketRealtimeTickDuration, const Duration(seconds: 1));
    expect(marketTickForMinute(8 * 60), 0);
    expect(marketTickForMinute(8 * 60 + 1), 1);
    expect(marketMinuteForTick(1), 8 * 60 + 1);
  });

  test('calendar liquidity keys are independent of campaign counters', () {
    const engine = GameEngine();
    final state = engine.createNewGame('liquidity-day-key').copyWith(day: 4);

    expect(
      marketLiquidityDayKey(state.currentDate),
      state.currentDate.difference(DateTime(2000, 1, 1)).inDays + 1,
    );
  });

  test(
    'market tick anchors historical close at 15:00 and finishes at 20:00',
    () {
      expect(marketTickForMinute(8 * 60), 0);
      expect(marketTickForMinute(15 * 60), krxCloseTick);
      expect(marketTickForMinute(20 * 60), generatedSessionTicks);
      final path = generatedFullMarketDayPath(
        previousClose: 10000,
        officialClose: 11200,
        seed: 77,
        dailyLimitRate: marketDailyPriceLimitRate(DateTime(2010, 1, 4)),
      );
      expect(path, hasLength(generatedSessionTicks + 1));
      expect(
        path.take(generatedPreOpenTicks).toSet(),
        <double>{10000},
        reason: '08:00~08:59 가격은 이전 종가로 고정되어야 한다.',
      );
      expect(
        path[generatedPreOpenTicks],
        isNot(10000),
        reason: '09:00 시가는 종목·날짜별 오버나이트 갭을 반영해야 한다.',
      );
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
    },
  );

  test('campaign-era price limits and quote units are enforced', () {
    expect(marketDailyPriceLimitRate(DateTime(2010, 12, 31)), 0.15);
    expect(marketDailyPriceLimitRate(DateTime(2026, 12, 31)), 0.30);
    expect(marketDailyPriceLimitRate(DateTime(2015, 6, 15)), 0.30);
    expect(marketTickSize(999), 1);
    expect(marketTickSize(1000), 5);
    expect(marketTickSize(10000), 50);
    expect(
      marketDailyPriceRange(previousClose: 10000, date: DateTime(2008, 1, 2)),
      (lower: 8500, upper: 11500),
    );
    expect(
      marketDailyPriceRange(previousClose: 330, date: DateTime(2008, 1, 2)),
      (lower: 281, upper: 379),
    );
    expect(isValidMarketOrderPrice(10050), isTrue);
    expect(isValidMarketOrderPrice(10025), isFalse);
  });

  test('modern IPO first days use 60 to 400 percent of the offering price', () {
    expect(
      marketDailyPriceRange(
        previousClose: 10000,
        date: DateTime(2023, 6, 26),
        isIpoFirstTradingDay: true,
      ),
      (lower: 6000, upper: 40000),
    );
    expect(
      marketDailyPriceRange(
        previousClose: 10000,
        date: DateTime(2023, 6, 23),
        isIpoFirstTradingDay: true,
      ),
      (lower: 7000, upper: 13000),
      reason: '개편 시행 전 IPO 첫날은 기존 가격제한폭을 유지해야 한다.',
    );
    expect(
      marketDailyPriceRange(previousClose: 10000, date: DateTime(2023, 6, 27)),
      (lower: 7000, upper: 13000),
      reason: '상장 다음 거래일부터는 일반 가격제한폭으로 돌아가야 한다.',
    );
  });

  test(
    'modern IPO opening discovery and intraday path share the wide range',
    () {
      final path = generatedFullMarketDayPath(
        previousClose: 10000,
        officialClose: 25000,
        seed: 20230626,
        dailyLimitRate: 0.30,
        lowerPriceLimit: 6000,
        upperPriceLimit: 40000,
        useIpoOpeningDiscovery: true,
      );

      expect(path.every((price) => price >= 6000 && price <= 40000), isTrue);
      expect(
        path[generatedPreOpenTicks],
        greaterThan(13000),
        reason: 'IPO 시가가 일반 종목의 ±1.2% 갭이나 +30% 상한에 갇히면 안 된다.',
      );
      expect(path[krxCloseTick], 25000);
      expect(path.sublist(krxCloseTick).toSet(), <double>{25000});
    },
  );

  test('post-2015 intraday paths use the 30 percent daily limits', () {
    final date = DateTime(2026, 4, 7);
    final rate = marketDailyPriceLimitRate(date);
    final upperPath = generatedFullMarketDayPath(
      previousClose: 10000,
      officialClose: 13000,
      seed: 17,
      dailyLimitRate: rate,
    );
    final lowerPath = generatedFullMarketDayPath(
      previousClose: 10000,
      officialClose: 7000,
      seed: 31,
      dailyLimitRate: rate,
    );

    expect(upperPath.every((price) => price >= 7000 && price <= 13000), isTrue);
    expect(lowerPath.every((price) => price >= 7000 && price <= 13000), isTrue);
    final upperCandles = aggregateMarketCandles(
      upperPath.sublist(generatedPreOpenTicks, krxCloseTick + 1),
      1,
      seed: 91,
      lowerPriceLimit: 7000,
      upperPriceLimit: 13000,
    );
    expect(
      upperCandles.every(
        (candle) => candle.low >= 7000 && candle.high <= 13000,
      ),
      isTrue,
    );
    expect(
      upperPath[krxCloseTick - 1],
      greaterThan(11500),
      reason: '상한가 종가 직전에 과거 15% 경계에 갇히면 안 된다.',
    );
    expect(
      lowerPath[krxCloseTick - 1],
      lessThan(8500),
      reason: '하한가 종가 직전에 과거 15% 경계에 갇히면 안 된다.',
    );
    expect(upperPath[krxCloseTick], 13000);
    expect(lowerPath[krxCloseTick], 7000);
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
      expect(paper.date, state.currentDate);
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
      advanceGameTime(marketDayStartMinute, academyHelpActionMinutes),
      8 * 60 + 30,
    );
    expect(advanceGameTime(marketDayStartMinute, workActionMinutes), 9 * 60);
    expect(
      advanceGameTime(19 * 60 + 30, workActionMinutes),
      marketDayEndMinute,
    );
  });

  test('timed impacts do not diverge before the earlier public reveal', () {
    final earlier = generatedFullMarketDayPath(
      previousClose: 10000,
      officialClose: 11000,
      seed: 71,
      dailyLimitRate: 0.30,
      timedImpacts: const [
        MarketTimedImpact(revealMinute: 13 * 60, impactRate: 0.08),
      ],
    );
    final later = generatedFullMarketDayPath(
      previousClose: 10000,
      officialClose: 11000,
      seed: 71,
      dailyLimitRate: 0.30,
      timedImpacts: const [
        MarketTimedImpact(revealMinute: 14 * 60, impactRate: 0.08),
      ],
    );
    final earlierRevealTick = marketTickForMinute(13 * 60);

    expect(
      earlier.take(earlierRevealTick),
      orderedEquals(later.take(earlierRevealTick)),
    );
    expect(earlier[earlierRevealTick], isNot(later[earlierRevealTick]));
    expect(earlier.last, 11000);
    expect(later.last, 11000);
  });

  test('large same-direction events use one shared daily impact clamp', () {
    final splitEvents = generatedFullMarketDayPath(
      previousClose: 10000,
      officialClose: 11400,
      seed: 901,
      dailyLimitRate: 0.15,
      timedImpacts: const [
        MarketTimedImpact(revealMinute: 13 * 60, impactRate: 0.10),
        MarketTimedImpact(revealMinute: 13 * 60, impactRate: 0.08),
      ],
    );
    final combinedEvent = generatedFullMarketDayPath(
      previousClose: 10000,
      officialClose: 11400,
      seed: 901,
      dailyLimitRate: 0.15,
      timedImpacts: const [
        MarketTimedImpact(revealMinute: 13 * 60, impactRate: 0.18),
      ],
    );

    expect(splitEvents, orderedEquals(combinedEvent));
  });

  test('post-close event times are normalized before the closing anchor', () {
    final invalid = generatedFullMarketDayPath(
      previousClose: 10000,
      officialClose: 10600,
      seed: 441,
      timedImpacts: const [
        MarketTimedImpact(revealMinute: 15 * 60 + 19, impactRate: 0.12),
      ],
    );
    final normalized = generatedFullMarketDayPath(
      previousClose: 10000,
      officialClose: 10600,
      seed: 441,
      timedImpacts: const [
        MarketTimedImpact(revealMinute: 14 * 60 + 49, impactRate: 0.12),
      ],
    );

    expect(invalid, normalized);
    expect(invalid[krxCloseTick], 10600);
  });

  test(
    'closing auction holds the last continuous price until one close print',
    () {
      final path = generatedFullMarketDayPath(
        previousClose: 10000,
        officialClose: 10800,
        seed: 711,
      );
      final reference = path[marketTickForMinute(krxContinuousEndMinute) - 1];

      for (
        var minute = krxContinuousEndMinute;
        minute < krxCloseMinute;
        minute += 1
      ) {
        expect(path[marketTickForMinute(minute)], reference);
      }
      expect(path[marketTickForMinute(krxCloseMinute)], 10800);
    },
  );

  test('closing-auction indicative price moves and converges before 15:00', () {
    final values = <double>[
      for (
        var minute = krxContinuousEndMinute;
        minute < krxCloseMinute;
        minute += 1
      )
        generatedClosingAuctionIndicativePrice(
          referencePrice: 10000,
          officialClose: 11000,
          previousClose: 10000,
          minute: minute,
          seed: 711,
          dailyLimitRate: 0.30,
        ),
    ];
    final repeated = generatedClosingAuctionIndicativePrice(
      referencePrice: 10000,
      officialClose: 11000,
      previousClose: 10000,
      minute: krxContinuousEndMinute + 4,
      seed: 711,
      dailyLimitRate: 0.30,
    );

    expect(values.toSet().length, greaterThan(2));
    expect((11000 - values.last).abs(), lessThan((11000 - values.first).abs()));
    expect(repeated, values[4]);
    expect(
      generatedClosingAuctionIndicativePrice(
        referencePrice: 10000,
        officialClose: 11000,
        previousClose: 10000,
        minute: krxCloseMinute,
        seed: 711,
        dailyLimitRate: 0.30,
      ),
      11000,
    );
  });

  test('high-priced growth-market paths keep the shared 100-won tick', () {
    final path = generatedFullMarketDayPath(
      previousClose: 120000,
      officialClose: 132000,
      seed: 90210,
      dailyLimitRate: 0.30,
      market: '도전시장',
    );

    for (final price in path) {
      expect(price.round() % 100, 0);
      expect(isValidMarketOrderPrice(price, market: '도전시장'), isTrue);
    }
  });
}
