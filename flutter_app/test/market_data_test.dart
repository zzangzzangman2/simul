import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_tick.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'market asset contains domestic main pack and preserved overseas pack',
    () async {
      final universe = await HistoricalMarketUniverse.load();

      expect(universe.schemaVersion, 3);
      expect(universe.assets.length, 28);
      expect(universe.assets.where((asset) => asset.isDomestic).length, 22);
      expect(universe.assets.where((asset) => !asset.isDomestic).length, 6);
      expect(
        universe.assets.map((asset) => asset.market).toSet(),
        containsAll(<String>{'KOSPI', 'KOSDAQ', 'NASDAQ', 'TSE'}),
      );
    },
  );

  test('Samsung does not leak its first quote before 2000-01-04', () async {
    final universe = await HistoricalMarketUniverse.load();
    final samsung = universe.assets.singleWhere(
      (asset) => asset.symbol == '005930.KS',
    );

    expect(samsung.quoteAtOrBefore(DateTime(2000, 1, 3)), isNull);
    final first = samsung.quoteAtOrBefore(DateTime(2000, 1, 4));
    expect(first, isNotNull);
    expect(first!.isExactDate, isTrue);
    expect(first.close, 6110);
  });

  test('generated ticks finish on the exact official close', () {
    final path = generatedMarketPath(
      previousClose: 5900,
      officialClose: 6110,
      seed: 5,
    );
    final anotherPath = generatedMarketPath(
      previousClose: 5900,
      officialClose: 6110,
      seed: 6,
    );
    final middle = path[generatedSessionTicks ~/ 2];
    final close = path.last;

    expect(middle, isNot(6110));
    expect(path.first, 5900);
    expect(close, 6110);
    expect(path.last, 6110);
    expect(path.length, generatedSessionTicks + 1);
    expect(path.toSet().length, greaterThan(45));
    expect(path, isNot(equals(anotherPath)));
    final deltas = List<double>.generate(
      path.length - 1,
      (index) => path[index + 1] - path[index],
    );
    expect(deltas.toSet().length, greaterThan(12));
    expect(
      deltas.map((delta) => delta.abs()).reduce((a, b) => a > b ? a : b),
      lessThan(590),
    );
  });

  test(
    'minute candles aggregate generated ticks into selectable intervals',
    () {
      final candles = aggregateMarketCandles(<double>[
        100,
        103,
        101,
        106,
        104,
        110,
        108,
      ], 3);

      expect(candles.length, 2);
      expect(candles.first.open, 100);
      expect(candles.first.high, 106);
      expect(candles.first.low, 100);
      expect(candles.first.close, 106);
      expect(candles.last.open, 106);
      expect(candles.last.close, 108);
    },
  );
}
