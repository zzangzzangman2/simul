import 'dart:math' as math;

/// 08:00~20:00을 실제 게임 시각 1분 단위로 재현하는 전체 틱 수.
const generatedSessionTicks = 720;
const generatedPreOpenTicks = 60;
const generatedRegularSessionTicks = 450;
const generatedRegularTradingTicks =
    generatedRegularSessionTicks - generatedPreOpenTicks;
const generatedPostCloseTicks =
    generatedSessionTicks - generatedRegularSessionTicks;

class MarketCandle {
  const MarketCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.startMinute,
    this.volume = 0,
  });

  final double open;
  final double high;
  final double low;
  final double close;
  final int startMinute;
  final double volume;
}

/// 실제 이전 종가에서 실제 당일 종가로 이어지는 비주기적 게임용 장중 경로.
///
/// 중간 값은 실제 체결가가 아니다. 종목·날짜별 시드로 난수 충격, 단기 모멘텀,
/// 변동성 군집, 드문 급변을 만들고 Brownian bridge 보정으로 마지막 값만 실제
/// 종가에 고정한다. 같은 시드는 재현 가능하지만 사인파 같은 반복 주기는 없다.
List<double> generatedMarketPath({
  required double previousClose,
  required double officialClose,
  int totalTicks = generatedSessionTicks,
  int seed = 0,
}) {
  if (totalTicks <= 0 || previousClose <= 0) {
    return <double>[officialClose];
  }

  final raw = <double>[0];
  var velocity = 0.0;
  var cumulative = 0.0;
  var volatility = 0.85;
  for (var step = 1; step <= totalTicks; step++) {
    final regime = 0.55 + _unit(seed, step ~/ 11 + 701) * 1.25;
    volatility = volatility * 0.84 + regime * 0.16;
    final shock =
        (_unit(seed, step * 7 + 11) +
            _unit(seed, step * 13 + 29) +
            _unit(seed, step * 19 + 47) -
            1.5) *
        1.2;
    velocity = velocity * 0.56 + shock * volatility;

    if (_unit(seed, step * 31 + 97) < 0.035) {
      final sign = _unit(seed, step * 37 + 131) < 0.5 ? -1.0 : 1.0;
      velocity += sign * (1.25 + _unit(seed, step * 41 + 173) * 2.35);
    }

    cumulative += velocity;
    raw.add(cumulative);
  }

  final dayMoveRate = ((officialClose - previousClose) / previousClose).abs();
  final rangeRate = (0.018 + dayMoveRate * 0.38).clamp(0.018, 0.075);
  final corridor = math.max(
    (officialClose - previousClose).abs() * 1.45,
    previousClose * rangeRate * 2.25,
  );
  final lower = math.min(previousClose, officialClose) - corridor;
  final upper = math.max(previousClose, officialClose) + corridor;
  final rawClose = raw.last;
  final scale = previousClose * rangeRate * 0.42 / math.sqrt(totalTicks);
  final result = <double>[previousClose];

  for (var step = 1; step < totalTicks; step++) {
    final progress = step / totalTicks;
    final trend = previousClose + (officialClose - previousClose) * progress;
    final bridge = raw[step] - rawClose * progress;
    final candidate = (trend + bridge * scale).clamp(lower, upper).toDouble();
    final tickSize = _tickSize(candidate);
    var rounded = (candidate / tickSize).roundToDouble() * tickSize;

    final delta = rounded - result.last;
    final moveTickSize = _tickSize(result.last);
    final minimumTicks = _unit(seed, step * 43 + 211) < 0.28 ? 0 : 1;
    final minimumMove = moveTickSize * minimumTicks;
    if (minimumTicks > 0 && delta.abs() < minimumMove) {
      final direction = delta != 0
          ? delta.sign
          : velocityFor(raw, step) +
                    (_unit(seed, step * 47 + 251) - 0.5) * 1.8 >=
                0
          ? 1.0
          : -1.0;
      final preferred = result.last + minimumMove * direction;
      final fallback = result.last - minimumMove * direction;
      if (preferred >= lower && preferred <= upper) {
        rounded = preferred;
      } else if (fallback >= lower && fallback <= upper) {
        rounded = fallback;
      }
    }
    result.add(rounded);
  }

  result.add(officialClose);
  return result;
}

/// 고정된 전일 정규장 경로의 끝부분만 잘라 장 초반 차트 앞에 붙인다.
///
/// [pointCount]가 매분 하나씩 줄어도 남아 있는 값은 그대로 유지되므로,
/// 새 현재 봉이 들어올 때 과거 봉 전체가 다시 그려지는 현상을 막는다.
List<double> generatedPreviousSessionLeadIn({
  required double previousClose,
  required int pointCount,
  int seed = 0,
}) {
  if (pointCount <= 0 || previousClose <= 0) return const <double>[];
  final previousSession = generatedMarketPath(
    previousClose: previousClose,
    officialClose: previousClose,
    totalTicks: generatedRegularTradingTicks,
    seed: seed,
  );
  final completedTicks = previousSession.take(generatedRegularTradingTicks);
  final visibleCount = pointCount
      .clamp(0, generatedRegularTradingTicks)
      .toInt();
  return completedTicks
      .skip(generatedRegularTradingTicks - visibleCount)
      .toList();
}

/// 08:00~20:00 게임 하루의 1분 가격 경로.
///
/// 08:00~08:59는 개장 전이라 이전 종가로 고정한다. 09:00부터 정규장
/// 경로를 만들고 15:30(tick 450)에 실제 종가를 고정한다. 정규장 마감 뒤에는
/// 별도 확장장을 만들지 않고 20:00까지 같은 종가를 유지한다.
List<double> generatedFullMarketDayPath({
  required double previousClose,
  required double officialClose,
  int seed = 0,
}) {
  final regular = generatedMarketPath(
    previousClose: previousClose,
    officialClose: officialClose,
    totalTicks: generatedRegularTradingTicks,
    seed: seed,
  );
  return <double>[
    ...List<double>.filled(generatedPreOpenTicks, previousClose),
    ...regular,
    ...List<double>.filled(generatedPostCloseTicks, officialClose),
  ];
}

double generatedMarketTick({
  required double previousClose,
  required double officialClose,
  required int tickIndex,
  int totalTicks = generatedSessionTicks,
  int seed = 0,
}) {
  final path = generatedMarketPath(
    previousClose: previousClose,
    officialClose: officialClose,
    totalTicks: totalTicks,
    seed: seed,
  );
  return path[tickIndex.clamp(0, path.length - 1)];
}

List<MarketCandle> aggregateMarketCandles(
  List<double> prices,
  int intervalMinutes, {
  int tickMinutes = 1,
  int? seed,
  int startMinuteOffset = 0,
}) {
  if (prices.isEmpty) return const <MarketCandle>[];
  if (intervalMinutes <= 0 || tickMinutes <= 0) {
    throw ArgumentError('Candle and tick intervals must be positive.');
  }
  if (intervalMinutes % tickMinutes != 0) {
    throw ArgumentError(
      '$intervalMinutes-minute candles cannot be built from '
      '$tickMinutes-minute ticks.',
    );
  }
  final interval = math.max(1, intervalMinutes ~/ tickMinutes);
  if (prices.length == 1) return const <MarketCandle>[];

  final candles = <MarketCandle>[];
  for (var start = 0; start < prices.length - 1; start += interval) {
    final end = math.min(start + interval, prices.length - 1);
    final slice = prices.sublist(start, end + 1);
    var high = slice.reduce(math.max);
    var low = slice.reduce(math.min);
    var volume = 0.0;
    if (seed != null) {
      for (var index = start; index < end; index++) {
        final open = prices[index];
        final close = prices[index + 1];
        final absoluteMinute = startMinuteOffset + index * tickMinutes;
        final tickSize = _tickSize(math.max((open + close) / 2, 1).toDouble());
        final body = (close - open).abs();
        final bodyTicks = body / tickSize;
        final wickChance = (0.18 + bodyTicks * 0.07).clamp(0.18, 0.48);
        final upperWick = _unit(seed, absoluteMinute * 17 + 1009) < wickChance
            ? tickSize
            : 0.0;
        final lowerWick = _unit(seed, absoluteMinute * 23 + 2027) < wickChance
            ? tickSize
            : 0.0;
        final minuteHigh = math.max(open, close) + upperWick;
        final minuteLow = math.max(tickSize, math.min(open, close) - lowerWick);
        high = math.max(high, minuteHigh);
        low = math.min(low, minuteLow);

        final activity = 0.16 + math.min(bodyTicks, 8) * 0.18;
        final noise = 0.55 + _unit(seed, absoluteMinute * 31 + 3037) * 0.7;
        final burstRoll = _unit(seed, absoluteMinute * 37 + 4051);
        final burst = burstRoll < 0.045
            ? 3.8 + _unit(seed, absoluteMinute * 41 + 5011) * 3.2
            : 1.0;
        final openingActivity = absoluteMinute >= 0 && absoluteMinute < 15
            ? 1.35
            : 1.0;
        volume +=
            (120 + (seed.abs() % 880)) *
            activity *
            noise *
            burst *
            openingActivity;
      }
    }
    candles.add(
      MarketCandle(
        open: slice.first,
        high: high,
        low: low,
        close: slice.last,
        startMinute: startMinuteOffset + start * tickMinutes,
        volume: volume,
      ),
    );
  }
  return candles;
}

int marketStockSeed(String code, DateTime date) {
  var value = date.year * 10000 + date.month * 100 + date.day;
  for (final unit in code.codeUnits) {
    value = ((value * 31) ^ unit) & 0x7fffffff;
  }
  return value;
}

double velocityFor(List<double> raw, int step) {
  if (step <= 0 || step >= raw.length) return 0;
  return raw[step] - raw[step - 1];
}

double _tickSize(double price) {
  if (price >= 100000) return 100;
  if (price >= 50000) return 50;
  if (price >= 5000) return 10;
  return 1;
}

double _unit(int seed, int index) {
  var value = (seed ^ (index * 0x45d9f3b)) & 0x7fffffff;
  value = ((value ^ (value >> 16)) * 0x45d9f3b) & 0x7fffffff;
  value = ((value ^ (value >> 16)) * 0x45d9f3b) & 0x7fffffff;
  value = (value ^ (value >> 16)) & 0x7fffffff;
  return value / 0x7fffffff;
}
