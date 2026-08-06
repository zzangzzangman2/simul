import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';

void main() {
  const engine = GameEngine();

  test('same-name new games receive different hidden stock futures', () {
    final first = engine.createNewGame('같은 이름의 회사');
    final second = engine.createNewGame('같은 이름의 회사');

    expect(first.simulationSeed, isNot(second.simulationSeed));
    expect(
      first.story.storyFlags['hiddenMarketScenario'],
      isNot(second.story.storyFlags['hiddenMarketScenario']),
    );

    final throughDate = DateTime(2000, 5, 30);
    final firstWorld = buildFictionalMarketUniverse(
      first.simulationSeed,
      throughDate: throughDate,
    );
    final secondWorld = buildFictionalMarketUniverse(
      second.simulationSeed,
      throughDate: throughDate,
    );
    final firstHanbit = firstWorld.assets.singleWhere(
      (asset) => asset.id == 'hanbit_telecom',
    );
    final secondHanbit = secondWorld.assets.singleWhere(
      (asset) => asset.id == 'hanbit_telecom',
    );
    final firstHistory = firstHanbit.historyThrough(throughDate, count: 100);
    final secondByDate = <String, double>{
      for (final point in secondHanbit.historyThrough(throughDate, count: 100))
        point.date: point.close,
    };
    final sharedDates = firstHistory
        .where((point) => secondByDate.containsKey(point.date))
        .toList(growable: false);
    final differentCloses = sharedDates
        .where((point) => secondByDate[point.date] != point.close)
        .length;
    expect(sharedDates, hasLength(100));
    expect(differentCloses / sharedDates.length, greaterThan(0.85));

    final firstNews = <String>{};
    final secondNews = <String>{};
    for (
      var date = DateTime(2000, 1, 3);
      !date.isAfter(throughDate);
      date = date.add(const Duration(days: 1))
    ) {
      if (!isMarketTradingDay(date)) continue;
      firstNews.addAll(
        fictionalMarketEventsForDate(
          first.simulationSeed,
          date,
        ).map((event) => '${event.date}:${event.companyId}:${event.title}'),
      );
      secondNews.addAll(
        fictionalMarketEventsForDate(
          second.simulationSeed,
          date,
        ).map((event) => '${event.date}:${event.companyId}:${event.title}'),
      );
    }
    expect(firstNews, isNot(secondNews));
  });

  test('save round-trip preserves the generated world seed exactly', () {
    final created = engine.createNewGame('저장할 회사');
    final restored = GameState.fromJson(created.toJson());

    expect(restored.simulationSeed, created.simulationSeed);
    expect(
      restored.story.storyFlags['hiddenMarketScenario'],
      created.story.storyFlags['hiddenMarketScenario'],
    );
    final date = DateTime(2000, 5, 30);
    final originalWorld = buildFictionalMarketUniverse(
      created.simulationSeed,
      throughDate: date,
    );
    final restoredWorld = buildFictionalMarketUniverse(
      restored.simulationSeed,
      throughDate: date,
    );
    expect(
      originalWorld.assets
          .singleWhere((asset) => asset.id == 'hanbit_telecom')
          .historyThrough(date, count: 100)
          .map((point) => point.close),
      orderedEquals(
        restoredWorld.assets
            .singleWhere((asset) => asset.id == 'hanbit_telecom')
            .historyThrough(date, count: 100)
            .map((point) => point.close),
      ),
    );
  });
}
