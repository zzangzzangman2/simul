import 'market_price_rules.dart';

enum MarketTechnicalLevelKind { support, resistance }

/// One publicly known daily close on a single, already comparable price axis.
class MarketTechnicalClose {
  const MarketTechnicalClose({required this.date, required this.close});

  final String date;
  final double close;
}

/// A causal weekly moving-average support or resistance level.
class MarketTechnicalLevel {
  const MarketTechnicalLevel({
    required this.periodWeeks,
    required this.price,
    required this.kind,
    required this.strength,
    required this.holdTicks,
    required this.weeklySamples,
  });

  final int periodWeeks;
  final double price;
  final MarketTechnicalLevelKind kind;
  final double strength;
  final int holdTicks;
  final int weeklySamples;
}

/// Converts daily closes into Monday-start calendar-week closes.
///
/// [sessionDate] is exclusive. This prevents an already-generated official
/// close for the current session from leaking into a path or order book before
/// that session has completed. The current calendar week is still represented
/// by the last public close before [sessionDate], so the line updates causally
/// on each following trading day. Holiday-shortened weeks are valid weeks.
List<MarketTechnicalClose> marketTechnicalWeeklyCloses({
  required Iterable<MarketTechnicalClose> dailyCloses,
  required String sessionDate,
}) {
  final parsedExclusiveDate = DateTime.tryParse(sessionDate);
  if (parsedExclusiveDate == null) return const <MarketTechnicalClose>[];
  final exclusiveDate = DateTime(
    parsedExclusiveDate.year,
    parsedExclusiveDate.month,
    parsedExclusiveDate.day,
  );

  final byDate = <String, MarketTechnicalClose>{};
  for (final item in dailyCloses) {
    final date = DateTime.tryParse(item.date);
    if (date == null ||
        !date.isBefore(exclusiveDate) ||
        !item.close.isFinite ||
        item.close <= 0) {
      continue;
    }
    byDate[_dateKey(date)] = MarketTechnicalClose(
      date: _dateKey(date),
      close: item.close,
    );
  }
  final ordered = byDate.values.toList(growable: false)
    ..sort((left, right) => left.date.compareTo(right.date));
  final byWeek = <String, MarketTechnicalClose>{};
  for (final item in ordered) {
    final date = DateTime.parse(item.date);
    final monday = date.subtract(
      Duration(days: date.weekday - DateTime.monday),
    );
    byWeek[_dateKey(monday)] = item;
  }
  return List<MarketTechnicalClose>.unmodifiable(byWeek.values);
}

/// Builds 5-, 20-, and 60-week SMA levels from causal weekly closes.
///
/// Input closes must already be adjusted onto the current session's corporate
/// action price axis. A period is omitted until enough weekly closes exist.
List<MarketTechnicalLevel> buildMarketTechnicalLevels({
  required Iterable<MarketTechnicalClose> adjustedDailyCloses,
  required String sessionDate,
  required double referencePrice,
  required String market,
}) {
  if (!referencePrice.isFinite || referencePrice <= 0) {
    return const <MarketTechnicalLevel>[];
  }
  final weekly = marketTechnicalWeeklyCloses(
    dailyCloses: adjustedDailyCloses,
    sessionDate: sessionDate,
  );
  if (weekly.isEmpty) return const <MarketTechnicalLevel>[];

  const specifications = <({int weeks, double strength, int holdTicks})>[
    (weeks: 5, strength: 3.15, holdTicks: 3),
    (weeks: 20, strength: 3.85, holdTicks: 5),
    (weeks: 60, strength: 4.55, holdTicks: 8),
  ];
  final levels = <MarketTechnicalLevel>[];
  for (final specification in specifications) {
    if (weekly.length < specification.weeks) continue;
    var total = 0.0;
    for (
      var index = weekly.length - specification.weeks;
      index < weekly.length;
      index += 1
    ) {
      total += weekly[index].close;
    }
    final average = total / specification.weeks;
    final tick = sharedMarketTickSize(average, market: market);
    if (!average.isFinite || tick <= 0 || !tick.isFinite) continue;
    final price = (average / tick).round() * tick;
    if (!price.isFinite || price <= 0) continue;
    levels.add(
      MarketTechnicalLevel(
        periodWeeks: specification.weeks,
        price: price,
        kind: price <= referencePrice + 0.000001
            ? MarketTechnicalLevelKind.support
            : MarketTechnicalLevelKind.resistance,
        strength: specification.strength,
        holdTicks: specification.holdTicks,
        weeklySamples: specification.weeks,
      ),
    );
  }
  return List<MarketTechnicalLevel>.unmodifiable(levels);
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
