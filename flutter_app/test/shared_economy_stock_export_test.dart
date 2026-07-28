import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/market_data.dart';

void main() {
  const seed = 'shared-economy-stock-export';

  bool isSharedEconomyStockEvent(FictionalMarketEvent event) {
    const stockOnlyHistoricalCategories = <String>{
      '세계 증시',
      '투자심리',
      '회계 신뢰',
      '시장 제도',
      '시장 구조',
    };
    if (event.id.startsWith('historical-')) {
      return !stockOnlyHistoricalCategories.contains(event.eyebrow);
    }
    return event.id.startsWith('corpus-') &&
        event.stage == 0 &&
        !event.id.startsWith('corpus-short_sale_ban-') &&
        !event.id.startsWith('corpus-short_sale_resume-') &&
        !event.id.startsWith('corpus-leveraged_liquidation-');
  }

  int compareEvents(FictionalMarketEvent left, FictionalMarketEvent right) {
    final byDate = left.date.compareTo(right.date);
    if (byDate != 0) return byDate;
    final byRevealMinute = left.revealMinute.compareTo(right.revealMinute);
    if (byRevealMinute != 0) return byRevealMinute;
    return left.id.compareTo(right.id);
  }

  test(
    'shared economy stock export is inclusive and never leaks future days',
    () {
      final beforeCatalyst = fictionalSharedEconomyEventsThrough(
        seed,
        DateTime(2000, 5, 15, 23, 59),
      );
      final throughCatalyst = fictionalSharedEconomyEventsThrough(
        seed,
        DateTime(2000, 5, 16),
      );

      expect(
        beforeCatalyst.map((event) => event.id),
        isNot(contains('historical-2000_global_rate_hike')),
      );
      expect(
        throughCatalyst.map((event) => event.id),
        contains('historical-2000_global_rate_hike'),
      );
      expect(
        throughCatalyst.every(
          (event) => !DateTime.parse(event.date).isAfter(DateTime(2000, 5, 16)),
        ),
        isTrue,
      );
      expect(
        fictionalSharedEconomyEventsThrough(seed, DateTime(1999, 12, 31)),
        isEmpty,
      );
    },
  );

  test('shared economy stock export is deterministic and stably sorted', () {
    final first = fictionalSharedEconomyEventsThrough(
      seed,
      DateTime(2002, 12, 31),
    );
    final second = fictionalSharedEconomyEventsThrough(
      seed,
      DateTime(2002, 12, 31),
    );

    expect(first.map((event) => event.id), second.map((event) => event.id));
    expect(
      first.map((event) => event.toJson()),
      second.map((event) => event.toJson()),
    );
    expect(first, isNotEmpty);
    for (var index = 1; index < first.length; index += 1) {
      expect(
        compareEvents(first[index - 1], first[index]),
        lessThanOrEqualTo(0),
      );
    }
  });

  test('export reuses canonical daily stock event objects and IDs', () {
    final through = DateTime(2000, 12, 31);
    final exported = fictionalSharedEconomyEventsThrough(seed, through);
    final expected = <FictionalMarketEvent>[];

    for (
      var date = DateTime(2000, 1, 1);
      !date.isAfter(through);
      date = date.add(const Duration(days: 1))
    ) {
      expected.addAll(
        fictionalMarketEventsForDate(
          seed,
          date,
        ).where(isSharedEconomyStockEvent),
      );
    }
    expected.sort(compareEvents);

    expect(
      exported.map((event) => event.id),
      expected.map((event) => event.id),
    );
    expect(
      exported.every(
        (event) =>
            event.id.startsWith('historical-') ||
            (event.id.startsWith('corpus-') && event.stage == 0),
      ),
      isTrue,
    );
    expect(
      exported.where((event) => event.id.startsWith('corpus-')),
      isNotEmpty,
    );
    for (var index = 0; index < exported.length; index += 1) {
      expect(
        identical(exported[index], expected[index]),
        isTrue,
        reason: exported[index].id,
      );
    }
  });

  test('stock-only market structure shocks do not leak into real economy', () {
    final stockEvents = fictionalMarketEventsForDate(
      seed,
      DateTime(2010, 5, 6),
    );
    expect(
      stockEvents.map((event) => event.id),
      contains('historical-2010_market_liquidity_shock'),
    );

    final shared = fictionalSharedEconomyEventsThrough(
      seed,
      DateTime(2026, 12, 31),
    );
    expect(
      shared.map((event) => event.id),
      isNot(contains('historical-2010_market_liquidity_shock')),
    );
  });
}
