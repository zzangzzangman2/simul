import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/market_data.dart';

void main() {
  group('월드시드 시장 변화', () {
    const seeds = <String>[
      'qa-world-alpha',
      'qa-world-beta',
      'qa-world-gamma',
      'qa-world-delta',
    ];
    late Map<String, FictionalMarketUniverse> worlds;

    setUpAll(() {
      worlds = <String, FictionalMarketUniverse>{
        for (final seed in seeds) seed: buildFictionalMarketUniverse(seed),
      };
    });

    Set<String> hanbitArcStartDates(String seed) {
      final dates = <String>{};
      for (
        var date = DateTime(2000, 1, 1);
        date.isBefore(DateTime(2027, 1, 1));
        date = date.add(const Duration(days: 1))
      ) {
        dates.addAll(
          fictionalMarketEventsForDate(seed, date)
              .where(
                (event) =>
                    event.companyId == 'hanbit_telecom' &&
                    event.id.startsWith('arc-') &&
                    event.stage == 0,
              )
              .map((event) => event.date),
        );
      }
      return dates;
    }

    test('일반 기업 사건 시작일도 월드시드마다 달라진다', () {
      final first = hanbitArcStartDates(seeds[0]);
      final second = hanbitArcStartDates(seeds[1]);
      final repeated = hanbitArcStartDates(seeds[0]);

      expect(first.length, greaterThan(70));
      expect(second.length, greaterThan(70));
      expect(first, repeated);
      expect(first, isNot(second));
      expect(first.intersection(second).length, lessThan(first.length ~/ 2));
    });

    test('다른 월드의 장기 종가는 충분히 다른 경로를 가진다', () {
      final first = worlds[seeds[0]]!.assets.singleWhere(
        (asset) => asset.id == 'hanbit_telecom',
      );
      final second = worlds[seeds[1]]!.assets.singleWhere(
        (asset) => asset.id == 'hanbit_telecom',
      );
      final secondByDate = <String, double>{
        for (final point in second.historyThrough(
          DateTime(2026, 12, 31),
          count: 10000,
        ))
          point.date: point.close,
      };
      var shared = 0;
      var different = 0;
      for (final point in first.historyThrough(
        DateTime(2026, 12, 31),
        count: 10000,
      )) {
        final other = secondByDate[point.date];
        if (other == null) continue;
        shared++;
        if (point.close != other) different++;
      }

      expect(shared, greaterThan(6500));
      expect(different / shared, greaterThan(0.9));
    });

    test('장기 가격은 전역 하한·상한에 과도하게 붙지 않는다', () {
      for (final entry in worlds.entries) {
        final fixedAssets = entry.value.assets.where(
          (asset) => asset.generation == 0,
        );
        var touchedFloor = 0;
        var touchedCeiling = 0;
        final finalCloses = <double>[];
        for (final asset in fixedAssets) {
          final history = asset.historyThrough(
            DateTime(2026, 12, 31),
            count: 10000,
          );
          if (history.any((point) => point.close <= 120)) touchedFloor++;
          if (history.any((point) => point.close >= 2500000)) touchedCeiling++;
          final finalQuote = asset.quoteAtOrBefore(DateTime(2026, 12, 31));
          if (finalQuote != null) finalCloses.add(finalQuote.close);
        }

        expect(touchedFloor, lessThanOrEqualTo(2), reason: entry.key);
        expect(touchedCeiling, lessThanOrEqualTo(1), reason: entry.key);
        expect(
          finalCloses.where((close) => close <= 200),
          isEmpty,
          reason: entry.key,
        );
      }
    });

    test('신상품 핵심 검증은 대부분 같은 날 주가 방향에 반영된다', () {
      for (final entry in worlds.entries) {
        final assets = {
          for (final asset in entry.value.assets) asset.id: asset,
        };
        var resolved = 0;
        var aligned = 0;
        for (
          var date = DateTime(2000, 1, 1);
          date.isBefore(DateTime(2027, 1, 1));
          date = date.add(const Duration(days: 1))
        ) {
          for (final event in fictionalMarketEventsForDate(entry.key, date)) {
            if (!event.id.startsWith('technology-') || event.stage != 2) {
              continue;
            }
            resolved++;
            final asset = assets[event.companyId];
            final quote = asset?.quoteAtOrBefore(date);
            if (asset == null || quote == null || !quote.isExactDate) continue;
            final previous = asset.previousCloseBefore(quote.date);
            if (previous == null || previous <= 0) continue;
            final dailyReturn = quote.close / previous - 1;
            if ((dailyReturn > 0 && event.impactPct > 0) ||
                (dailyReturn < 0 && event.impactPct < 0)) {
              aligned++;
            }
          }
        }

        expect(resolved, 112, reason: entry.key);
        expect(
          aligned / resolved,
          greaterThanOrEqualTo(0.95),
          reason: entry.key,
        );
      }
    });
  });
}
