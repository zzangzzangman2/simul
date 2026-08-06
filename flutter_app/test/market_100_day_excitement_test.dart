import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_quote.dart';

void main() {
  test(
    '100 trading days contain calm sessions, shocks, trends, and reversals',
    () {
      const seed = 'hundred-day-excitement-audit';
      final tradingDates = <DateTime>[];
      for (
        var date = DateTime(2000, 1, 3);
        tradingDates.length < 100;
        date = date.add(const Duration(days: 1))
      ) {
        if (isMarketTradingDay(date)) tradingDates.add(date);
      }
      final throughDate = tradingDates.last;
      final universe = buildFictionalMarketUniverse(
        seed,
        throughDate: throughDate,
      );
      final assets = universe.assets
          .where((asset) => asset.generation == 0)
          .toList(growable: false);

      var observations = 0;
      var quietCloses = 0;
      var mediumCloses = 0;
      var largeCloses = 0;
      var shockCloses = 0;
      var strongRallies = 0;
      var strongSelloffs = 0;
      var limitCloses = 0;
      var wideSessions = 0;
      var veryWideSessions = 0;
      var gapSessions = 0;
      var fadedMoves = 0;
      var twoSidedWhipsaws = 0;
      var materialNewsDays = 0;
      var newsCounterMoves = 0;
      var longestRisingRun = 0;
      var longestFallingRun = 0;
      final returns = <double>[];
      final ranges = <double>[];
      final largestMoves =
          <
            ({
              String asset,
              String date,
              double dailyReturn,
              double range,
              double news,
            })
          >[];

      for (final asset in assets) {
        final history = asset.historyThrough(throughDate, count: 100);
        final candles = recentMarketDailyCandles(
          asset: asset,
          simulationSeed: seed,
          throughDate: throughDate,
          count: 100,
        );
        expect(history, hasLength(100), reason: asset.id);
        expect(candles, hasLength(100), reason: asset.id);
        var risingRun = 0;
        var fallingRun = 0;

        for (var index = 0; index < history.length; index += 1) {
          final point = history[index];
          final candle = candles[index].candle;
          final previous = asset.previousCloseBefore(point.date);
          if (previous == null || previous <= 0) continue;
          final date = point.parsedDate;
          final dailyReturn = point.close / previous - 1;
          final highReturn = candle.high / previous - 1;
          final lowReturn = candle.low / previous - 1;
          final sessionRange = (candle.high - candle.low) / previous;
          final openingGap = candle.open / previous - 1;
          final newsImpact = marketTimedImpactsForAsset(
            simulationSeed: seed,
            date: date,
            asset: asset,
          ).fold<double>(0, (sum, impact) => sum + impact.impactRate);

          observations += 1;
          returns.add(dailyReturn);
          ranges.add(sessionRange);
          final absoluteReturn = dailyReturn.abs();
          if (absoluteReturn < 0.01) {
            quietCloses += 1;
          } else if (absoluteReturn < 0.05) {
            mediumCloses += 1;
          } else {
            largeCloses += 1;
          }
          if (absoluteReturn >= 0.10) shockCloses += 1;
          if (dailyReturn >= 0.08) strongRallies += 1;
          if (dailyReturn <= -0.08) strongSelloffs += 1;
          if (absoluteReturn >= marketDailyPriceLimitRate(date) - 0.002) {
            limitCloses += 1;
          }
          if (sessionRange >= 0.05) wideSessions += 1;
          if (sessionRange >= 0.10) veryWideSessions += 1;
          if (openingGap.abs() >= 0.03) gapSessions += 1;
          if ((dailyReturn > 0 && highReturn - dailyReturn >= 0.025) ||
              (dailyReturn < 0 && dailyReturn - lowReturn >= 0.025)) {
            fadedMoves += 1;
          }
          if (highReturn >= 0.025 && lowReturn <= -0.025) {
            twoSidedWhipsaws += 1;
          }
          if (newsImpact.abs() >= 0.01) {
            materialNewsDays += 1;
            if (dailyReturn.sign != newsImpact.sign) newsCounterMoves += 1;
          }

          if (dailyReturn > 0) {
            risingRun += 1;
            fallingRun = 0;
          } else if (dailyReturn < 0) {
            fallingRun += 1;
            risingRun = 0;
          } else {
            risingRun = 0;
            fallingRun = 0;
          }
          longestRisingRun = math.max(longestRisingRun, risingRun);
          longestFallingRun = math.max(longestFallingRun, fallingRun);
          largestMoves.add((
            asset: asset.name,
            date: point.date,
            dailyReturn: dailyReturn,
            range: sessionRange,
            news: newsImpact,
          ));
        }
      }

      returns.sort();
      ranges.sort();
      largestMoves.sort(
        (left, right) =>
            right.dailyReturn.abs().compareTo(left.dailyReturn.abs()),
      );
      final strongestRallies =
          largestMoves
              .where((move) => move.dailyReturn > 0)
              .toList(growable: false)
            ..sort(
              (left, right) => right.dailyReturn.compareTo(left.dailyReturn),
            );
      final strongestSelloffs =
          largestMoves
              .where((move) => move.dailyReturn < 0)
              .toList(growable: false)
            ..sort(
              (left, right) => left.dailyReturn.compareTo(right.dailyReturn),
            );
      double percentile(List<double> values, double fraction) =>
          values[((values.length - 1) * fraction).round()];
      String pct(int count) =>
          '${(count / math.max(1, observations) * 100).toStringAsFixed(1)}%';

      // ignore: avoid_print
      print('''
=== 주식시장 100거래일 재미 감사 ===
기간: ${marketDateKey(tradingDates.first)} ~ ${marketDateKey(throughDate)}
종목/관측: ${assets.length}개 / $observations건
종가 |1% 미만|: $quietCloses (${pct(quietCloses)})
종가 |1~5%|: $mediumCloses (${pct(mediumCloses)})
종가 |5% 이상|: $largeCloses (${pct(largeCloses)})
종가 |10% 이상|: $shockCloses (${pct(shockCloses)})
강한 상승 +8% 이상: $strongRallies · 강한 하락 -8% 이하: $strongSelloffs
상·하한 근처 종가: $limitCloses (${pct(limitCloses)})
장중 고저폭 5% 이상: $wideSessions (${pct(wideSessions)})
장중 고저폭 10% 이상: $veryWideSessions (${pct(veryWideSessions)})
시가 갭 3% 이상: $gapSessions (${pct(gapSessions)})
고점/저점 대비 2.5% 이상 되돌림: $fadedMoves (${pct(fadedMoves)})
같은 날 +2.5%/-2.5% 양방향: $twoSidedWhipsaws (${pct(twoSidedWhipsaws)})
중대뉴스 1% 이상: $materialNewsDays · 뉴스 반대 종가: $newsCounterMoves
최장 연속 상승/하락: $longestRisingRun일 / $longestFallingRun일
일간 수익률 P10/P50/P90: ${(percentile(returns, 0.10) * 100).toStringAsFixed(2)}% / ${(percentile(returns, 0.50) * 100).toStringAsFixed(2)}% / ${(percentile(returns, 0.90) * 100).toStringAsFixed(2)}%
장중 고저폭 P50/P90: ${(percentile(ranges, 0.50) * 100).toStringAsFixed(2)}% / ${(percentile(ranges, 0.90) * 100).toStringAsFixed(2)}%
큰 변동 상위 10일:
${largestMoves.take(10).map((move) => '${move.date} ${move.asset}: ${(move.dailyReturn * 100).toStringAsFixed(2)}% · 장중 ${(move.range * 100).toStringAsFixed(2)}% · 뉴스 ${(move.news * 100).toStringAsFixed(2)}%').join('\n')}
상승 상위 5일:
${strongestRallies.take(5).map((move) => '${move.date} ${move.asset}: +${(move.dailyReturn * 100).toStringAsFixed(2)}% · 뉴스 ${(move.news * 100).toStringAsFixed(2)}%').join('\n')}
하락 상위 5일:
${strongestSelloffs.take(5).map((move) => '${move.date} ${move.asset}: ${(move.dailyReturn * 100).toStringAsFixed(2)}% · 뉴스 ${(move.news * 100).toStringAsFixed(2)}%').join('\n')}
===================================
''');

      expect(observations, assets.length * 100);
      expect(quietCloses / observations, inInclusiveRange(0.20, 0.45));
      expect(mediumCloses / observations, inInclusiveRange(0.45, 0.75));
      expect(largeCloses / observations, inInclusiveRange(0.05, 0.18));
      expect(shockCloses / observations, inInclusiveRange(0.001, 0.02));
      expect(strongRallies, greaterThanOrEqualTo(10));
      expect(strongSelloffs, greaterThanOrEqualTo(10));
      expect(limitCloses / observations, lessThan(0.01));
      expect(wideSessions / observations, inInclusiveRange(0.15, 0.45));
      expect(veryWideSessions / observations, inInclusiveRange(0.005, 0.08));
      expect(gapSessions / observations, inInclusiveRange(0.005, 0.03));
      expect(fadedMoves / observations, greaterThanOrEqualTo(0.025));
      expect(twoSidedWhipsaws / observations, greaterThanOrEqualTo(0.015));
      expect(materialNewsDays, greaterThan(0));
      expect(
        newsCounterMoves / materialNewsDays,
        inInclusiveRange(0.08, 0.30),
        reason: '뉴스는 강한 원인이지만 항상 종가 방향을 보장해서는 안 된다.',
      );
      expect(longestRisingRun, inInclusiveRange(5, 15));
      expect(longestFallingRun, inInclusiveRange(5, 15));
    },
  );
}
