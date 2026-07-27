import 'dart:math' as math;

import 'market_clock.dart';
import 'market_liquidity_zones.dart';
import 'market_technical_levels.dart';

enum GameOrderBookSide { ask, bid }

/// 화면과 주문 엔진이 공통으로 생성하는 한쪽당 호가 깊이.
const gameOrderBookLevelCount = 10;
const gameOrderBookWallPricePeriod = 5;
const gameOrderBookMinuteTurnoverShare = 0.25;
const gameOrderBookOrderTurnoverShare = 0.02;
const gameOrderBookMinimumAdaptivePulseHz = 0.1;
const gameOrderBookMaximumAdaptivePulseHz = 12.0;
const _gameOrderBookFlatAggressorHoldMinutes = 6;
const _gameOrderBookRegularSessionMinutes =
    krxContinuousEndMinute - krxOpenMinute;
const _gameOrderBookFastMoveTicks = 3;
const _gameOrderBookTrendActivationRate = 0.04;

/// Returns the visible order-book event rate for the currently opened asset.
///
/// The base rate follows expected *full-day* turnover, not cumulative turnover,
/// so an otherwise identical stock does not speed up merely because the clock
/// is later in the session. A fast price move or extreme imbalance can lift
/// any stock into the 10-12 Hz band temporarily.
double gameOrderBookAdaptivePulseHz({
  required double fullDayTurnoverEok,
  required double currentPrice,
  required double previousTradePrice,
  required double previousClose,
  String market = 'main',
  double tradeStrength = 100,
  bool tradingSessionActive = true,
  bool playbackActive = true,
}) {
  if (!tradingSessionActive || !playbackActive) return 0;
  final turnover = fullDayTurnoverEok.isFinite
      ? math.max(0.0, fullDayTurnoverEok)
      : 0.0;
  var rate = switch (turnover) {
    < 20 => 0.1,
    < 75 => 0.2,
    < 200 => 0.3,
    < 1000 => 1.0,
    < 3000 => 2.0,
    < 7000 => 3.0,
    < 12000 => 5.0,
    < 20000 => 7.0,
    _ => 8.0,
  };

  final hasPrices =
      currentPrice.isFinite &&
      currentPrice > 0 &&
      previousTradePrice.isFinite &&
      previousTradePrice > 0;
  var crossedTicks = 0;
  if (hasPrices) {
    final currentLadderIndex = _marketPriceLadderIndex(
      currentPrice,
      market: market,
    );
    final previousLadderIndex = _marketPriceLadderIndex(
      previousTradePrice,
      market: market,
    );
    crossedTicks = (currentLadderIndex - previousLadderIndex).abs();
  }
  final sessionMoveRate =
      currentPrice.isFinite &&
          currentPrice > 0 &&
          previousClose.isFinite &&
          previousClose > 0
      ? ((currentPrice - previousClose) / previousClose).abs()
      : 0.0;
  final imbalance = tradeStrength.isFinite && tradeStrength > 0
      ? math.max(tradeStrength / 100, 100 / tradeStrength)
      : 1.0;
  final fast =
      crossedTicks >= _gameOrderBookFastMoveTicks ||
      sessionMoveRate >= 0.04 ||
      imbalance >= 1.65;
  final extreme =
      crossedTicks >= _gameOrderBookFastMoveTicks * 2 ||
      sessionMoveRate >= 0.08 ||
      imbalance >= 2.1;
  if (extreme) {
    rate = math.max(rate, gameOrderBookMaximumAdaptivePulseHz);
  } else if (fast) {
    rate = math.max(rate, 10.0);
  }
  return rate
      .clamp(
        gameOrderBookMinimumAdaptivePulseHz,
        gameOrderBookMaximumAdaptivePulseHz,
      )
      .toDouble();
}

int gameEstimatedFullDayVolumeUnits({
  required String assetId,
  required int day,
  required double referencePrice,
  String simulationSeed = '',
  int? sharesOutstanding,
}) {
  if (assetId.isEmpty || !referencePrice.isFinite || referencePrice <= 0) {
    return 0;
  }
  final seededAssetId = simulationSeed.isEmpty
      ? assetId
      : '$simulationSeed:$assetId';
  final hash = _orderBookHash(seededAssetId, day, 0);
  if (sharesOutstanding != null && sharesOutstanding > 0) {
    final activity = _orderBookUnit(seededAssetId, day, 8101);
    final baseTurnoverRate = 0.008 + math.pow(activity, 1.65) * 0.22;
    final eventPulse = hash % 41 == 0
        ? 0.18 + _orderBookUnit(seededAssetId, day, 8117) * 0.24
        : 0.0;
    final turnoverRate = (baseTurnoverRate + eventPulse).clamp(0.008, 0.65);
    return math.max(1, (sharesOutstanding * turnoverRate).round());
  }

  // 이전 저장·테스트처럼 발행주식 수가 없는 호출도 결정적으로 동작한다.
  final fallbackTurnoverEok = 24.0 + hash % 760;
  final units = fallbackTurnoverEok * 100000000 / referencePrice;
  if (!units.isFinite || units <= 0) return 0;
  return units.round();
}

double gameEstimatedFullDayTurnoverEok({
  required String assetId,
  required int day,
  required double referencePrice,
  String simulationSeed = '',
  int? sharesOutstanding,
}) {
  final units = gameEstimatedFullDayVolumeUnits(
    assetId: assetId,
    day: day,
    referencePrice: referencePrice,
    simulationSeed: simulationSeed,
    sharesOutstanding: sharesOutstanding,
  );
  return units <= 0 ? 0 : units * referencePrice / 100000000;
}

double gameTurnoverProgressAtMinute(int minute) {
  if (minute < krxOpenMinute) return 0;
  if (minute >= krxCloseMinute) return 1;
  // No trades print during the 14:50~14:59 closing call auction. Keep the
  // cumulative figure at the 14:49 level, then add the auction execution only
  // when the official 15:00 close is published.
  final lastContinuousMinute = krxContinuousEndMinute - 1;
  final completedMinute = math.min(minute, lastContinuousMinute);
  final elapsed = (completedMinute - krxOpenMinute + 1)
      .clamp(1, krxCloseMinute - krxOpenMinute)
      .toDouble();
  final progress = elapsed / (krxCloseMinute - krxOpenMinute);
  return math.sqrt(progress) * 0.72 + progress * 0.28;
}

/// Stable per-transition volume for the continuous session visible so far.
///
/// The first returned value represents all volume accumulated through 09:01
/// because a price chart needs two prints before it can draw its first candle.
/// Every later value is a true cumulative delta. As a result, extending the
/// visible path never rewrites the volume of an already completed candle.
List<int> gameContinuousMinuteVolumes({
  required int fullDayVolume,
  required int visibleThroughMinute,
}) {
  if (fullDayVolume <= 0 || visibleThroughMinute <= krxOpenMinute) {
    return const <int>[];
  }
  final lastVisibleMinute = math.min(
    visibleThroughMinute,
    krxContinuousEndMinute - 1,
  );
  if (lastVisibleMinute <= krxOpenMinute) return const <int>[];

  final volumes = <int>[];
  var allocated = 0;
  for (
    var minute = krxOpenMinute + 1;
    minute <= lastVisibleMinute;
    minute += 1
  ) {
    final cumulative = (fullDayVolume * gameTurnoverProgressAtMinute(minute))
        .round()
        .clamp(allocated, fullDayVolume);
    volumes.add(cumulative - allocated);
    allocated = cumulative;
  }
  return List<int>.unmodifiable(volumes);
}

int gameClosingAuctionVolume({required int fullDayVolume}) {
  if (fullDayVolume <= 0) return 0;
  final continuousVolume =
      (fullDayVolume * gameTurnoverProgressAtMinute(krxContinuousEndMinute - 1))
          .round()
          .clamp(0, fullDayVolume);
  return fullDayVolume - continuousVolume;
}

class GameOrderBookLevel {
  const GameOrderBookLevel({
    required this.side,
    required this.price,
    required this.quantity,
    required this.isWall,
    this.structuralKind,
    this.structuralStrength = 1,
    this.structuralHoldTicks = 0,
    this.isStructuralWall = false,
    this.isStructuralBreached = false,
    this.structuralVacuumMultiplier = 1,
    this.isPsychological = false,
    this.technicalPeriods = const <int>[],
    this.wasLiquidityPulseTouched = false,
  });

  final GameOrderBookSide side;
  final double price;
  final int quantity;
  final bool isWall;
  final MarketLiquidityZoneKind? structuralKind;
  final double structuralStrength;
  final int structuralHoldTicks;
  final bool isStructuralWall;
  final bool isStructuralBreached;
  final double structuralVacuumMultiplier;
  final bool isPsychological;
  final List<int> technicalPeriods;
  final bool wasLiquidityPulseTouched;

  int get confluenceCount =>
      (isPsychological ? 1 : 0) + technicalPeriods.length;
}

class GameOrderBookSnapshot {
  const GameOrderBookSnapshot({
    required this.asks,
    required this.bids,
    required this.turnoverEok,
    required this.executionCapacity,
    required this.totalAskQuantity,
    required this.totalBidQuantity,
    required this.tradeStrength,
    this.liquidityPulse = 0,
    this.adaptiveLiquidityPulses = false,
    this.rememberedLevels = const <double, GameOrderBookLevel>{},
    this.sourceAssetId,
    this.sourceLiquidityDayKey,
    this.sourceDateKey,
    this.sourceMarketMinute,
    this.sourceLastTradePrice,
    this.sourceMarket,
    this.sourceSimulationSeed,
    this.appliedAskConsumptionByPrice = const <double, double>{},
    this.appliedBidConsumptionByPrice = const <double, double>{},
    this.appliedCapacityConsumptionUnits = 0,
  });

  final List<GameOrderBookLevel> asks;
  final List<GameOrderBookLevel> bids;
  final double turnoverEok;
  final int executionCapacity;
  final int totalAskQuantity;
  final int totalBidQuantity;
  final double tradeStrength;
  final int liquidityPulse;
  final bool adaptiveLiquidityPulses;

  /// Identity of the quote inputs that produced this snapshot.
  ///
  /// These fields stay optional so legacy/manual snapshots remain source
  /// compatible. An immediate order that supplies [GameOrderBookSnapshot] as
  /// its displayed book must use a builder-generated snapshot with a complete
  /// identity; the engine rejects missing or stale identity before filling.
  final String? sourceAssetId;
  final int? sourceLiquidityDayKey;
  final String? sourceDateKey;
  final int? sourceMarketMinute;
  final double? sourceLastTradePrice;
  final String? sourceMarket;
  final String? sourceSimulationSeed;

  /// Cumulative per-price ledger depth already subtracted from this snapshot.
  ///
  /// These watermarks make [gameOrderBookSnapshotAfterConsumption] safe to
  /// apply repeatedly. Legacy/raw snapshots use the empty maps, while a netted
  /// snapshot records the exact cumulative quantities represented by its rows.
  final Map<double, double> appliedAskConsumptionByPrice;
  final Map<double, double> appliedBidConsumptionByPrice;
  final int appliedCapacityConsumptionUnits;

  /// Standing liquidity already visited during this asset's current session.
  ///
  /// The visible rows are only a window onto the book. Keeping their latest
  /// state keyed by absolute price prevents a level from being regenerated
  /// when it leaves that window and later returns on screen. Callers naturally
  /// reset this memory for a new session by omitting [previousSnapshot].
  final Map<double, GameOrderBookLevel> rememberedLevels;
}

class GameOrderBookTradePulse {
  const GameOrderBookTradePulse({
    required this.levelSide,
    required this.levelIndex,
    required this.quantity,
    required this.crossedTicks,
  });

  /// 매수자가 매도호가를 먹으면 ask, 매도자가 매수호가를 먹으면 bid다.
  final GameOrderBookSide levelSide;
  final int levelIndex;
  final int quantity;
  final int crossedTicks;

  bool get isBuyAggressor => levelSide == GameOrderBookSide.ask;
  bool get isFastMarket => crossedTicks >= _gameOrderBookFastMoveTicks;
}

class _GameOrderBookRegime {
  const _GameOrderBookRegime({
    required this.direction,
    required this.crossedTicks,
    required this.intensity,
  });

  /// 1은 매수 우위, -1은 매도 우위, 0은 뚜렷한 방향이 없는 상태다.
  final int direction;
  final int crossedTicks;
  final double intensity;

  bool get isFast =>
      crossedTicks >= _gameOrderBookFastMoveTicks || intensity >= 0.45;

  bool consumes(GameOrderBookSide side) =>
      (direction > 0 && side == GameOrderBookSide.ask) ||
      (direction < 0 && side == GameOrderBookSide.bid);
}

class GameOrderBookLevelFill {
  const GameOrderBookLevelFill({
    required this.levelIndex,
    required this.price,
    required this.quantity,
  });

  final int levelIndex;
  final double price;
  final int quantity;
}

class GameOrderBookFillPlan {
  const GameOrderBookFillPlan({
    required this.levelSide,
    required this.fills,
    required this.filledQuantity,
    required this.notional,
    required this.averagePrice,
    required this.worstPrice,
  });

  final GameOrderBookSide levelSide;
  final List<GameOrderBookLevelFill> fills;
  final int filledQuantity;
  final int notional;
  final double averagePrice;
  final double worstPrice;

  bool get hasFill => filledQuantity > 0;
}

/// 현재까지의 가상 거래대금(억원)을 종목·날짜·시각으로 재현한다.
///
/// 같은 월드 상태에서는 같은 값이 나오며, 장중 누적 거래대금이 커질수록
/// 호가 잔량과 한 분에 소화할 수 있는 지정가 수량도 함께 커진다.
double gameEstimatedTurnoverEok({
  required String assetId,
  required int day,
  required int minute,
  required double unitPrice,
  double previousClose = 0,
  String simulationSeed = '',
  int? sharesOutstanding,
}) {
  if (assetId.isEmpty || !unitPrice.isFinite || unitPrice <= 0) return 0;
  if (minute < krxOpenMinute) return 0;
  final stableReference = previousClose.isFinite && previousClose > 0
      ? previousClose
      : unitPrice;
  final fullDayTurnover = gameEstimatedFullDayTurnoverEok(
    assetId: assetId,
    day: day,
    referencePrice: stableReference,
    simulationSeed: simulationSeed,
    sharesOutstanding: sharesOutstanding,
  );
  return fullDayTurnover * gameTurnoverProgressAtMinute(minute);
}

int gameOrderBookMinuteCapacityUnits({
  required double turnoverEok,
  required double unitPrice,
}) {
  if (!turnoverEok.isFinite ||
      turnoverEok <= 0 ||
      !unitPrice.isFinite ||
      unitPrice <= 0) {
    return 0;
  }
  final units =
      turnoverEok * 100000000 * gameOrderBookMinuteTurnoverShare / unitPrice;
  if (units.isNaN || units <= 0) return 0;
  if (units.isInfinite) return 0x7fffffff;
  return units.floor().clamp(0, 0x7fffffff).toInt();
}

int gameOrderBookNotionalLimitForTurnover({
  required double turnoverEok,
  int minimum = 5000000,
  int maximum = 2000000000,
}) {
  if (!turnoverEok.isFinite ||
      turnoverEok <= 0 ||
      minimum < 0 ||
      maximum < minimum) {
    return 0;
  }
  final raw = turnoverEok * 100000000 * gameOrderBookOrderTurnoverShare;
  if (!raw.isFinite || raw <= 0) return 0;
  return raw.round().clamp(minimum, maximum).toInt();
}

/// 현재 호가에서 한 게임 분 동안 실제로 소화 가능한 지정가 수량.
///
/// 호가창과 주문 엔진이 이 함수를 함께 사용하므로 화면의 거래대금·벽 규모와
/// 부분체결 한도가 서로 따로 움직이지 않는다.
int gameOrderBookExecutionCapacity({
  required String assetId,
  required int day,
  required int minute,
  required double unitPrice,
  double previousClose = 0,
  String simulationSeed = '',
  double? cumulativeTurnoverEok,
  int? sharesOutstanding,
}) {
  if (assetId.isEmpty ||
      !unitPrice.isFinite ||
      unitPrice <= 0 ||
      !marketClockAt(minute, tradingDay: true).tradable) {
    return 0;
  }
  final turnoverEok =
      cumulativeTurnoverEok ??
      gameEstimatedTurnoverEok(
        assetId: assetId,
        day: day,
        minute: minute,
        unitPrice: unitPrice,
        previousClose: previousClose,
        simulationSeed: simulationSeed,
        sharesOutstanding: sharesOutstanding,
      );
  if (!turnoverEok.isFinite || turnoverEok <= 0) return 0;
  final elapsed = (minute - krxOpenMinute + 1)
      .clamp(1, krxCloseMinute - krxOpenMinute)
      .toDouble();
  final averageUnitsPerMinute =
      turnoverEok * 100000000 / unitPrice / math.max(15, elapsed);
  final seededAssetId = simulationSeed.isEmpty
      ? assetId
      : '$simulationSeed:$assetId';
  final pulse =
      0.22 + _orderBookUnit(seededAssetId, day, minute * 17 + 31) * 0.78;
  final auctionMultiplier =
      minute < krxOpenMinute + 5 || minute >= krxContinuousEndMinute
      ? 1.6
      : 1.0;
  final moveRate = previousClose.isFinite && previousClose > 0
      ? ((unitPrice - previousClose) / previousClose).abs()
      : 0.0;
  final activityMultiplier = (1 + moveRate * 4).clamp(1.0, 1.8);
  final rawUnits =
      averageUnitsPerMinute *
      pulse *
      0.48 *
      auctionMultiplier *
      activityMultiplier;
  if (!rawUnits.isFinite || rawUnits <= 0) return 0;
  final maximum = gameOrderBookMinuteCapacityUnits(
    turnoverEok: turnoverEok,
    unitPrice: unitPrice,
  );
  if (maximum <= 0) return 0;
  return math.min(rawUnits.round(), maximum);
}

/// 최근 체결이 어느 호가를 소화했는지 표시할 이동 네모를 만든다.
///
/// 가격 상승은 매수자가 매도호가를 먹은 체결, 가격 하락은 매도자가
/// 매수호가를 먹은 체결로 본다. 보합 틱은 매분 방향을 다시 뽑지 않고
/// 몇 분짜리 체결 흐름을 유지해 화면이 위아래로 번쩍이지 않게 한다.
GameOrderBookSide _gameOrderBookAggressorSide({
  required String seededAssetId,
  required int day,
  required int minute,
  required double previousPrice,
  required double currentPrice,
}) {
  final delta = currentPrice - previousPrice;
  if (delta > 0) return GameOrderBookSide.ask;
  if (delta < 0) return GameOrderBookSide.bid;
  final flowBucket = minute ~/ _gameOrderBookFlatAggressorHoldMinutes;
  final flow = _orderBookUnit(seededAssetId, day, flowBucket * 7919 + 2203);
  return flow < 0.5 ? GameOrderBookSide.ask : GameOrderBookSide.bid;
}

_GameOrderBookRegime _gameOrderBookRegime({
  required String seededAssetId,
  required int day,
  required int minute,
  required double previousPrice,
  required double currentPrice,
  required double previousClose,
  required String market,
  required int executionCapacity,
  required int standingBaseDepth,
}) {
  final previousLadderIndex = _marketPriceLadderIndex(
    previousPrice,
    market: market,
  );
  final currentLadderIndex = _marketPriceLadderIndex(
    currentPrice,
    market: market,
  );
  final signedTicks = currentLadderIndex - previousLadderIndex;
  final crossedTicks = signedTicks.abs();
  final dailyMoveRate = previousClose.isFinite && previousClose > 0
      ? (currentPrice - previousClose) / previousClose
      : 0.0;
  final trendDirection =
      dailyMoveRate.abs() >= _gameOrderBookTrendActivationRate
      ? dailyMoveRate.sign.toInt()
      : 0;
  var direction = signedTicks.sign;
  if (trendDirection != 0 &&
      (direction == 0 ||
          (direction != trendDirection &&
              crossedTicks < _gameOrderBookFastMoveTicks))) {
    // A one- or two-tick pullback inside a strong daily trend is ordinary
    // noise. Keeping the trend direction here prevents every shared price
    // level from flipping between depleted and replenished books at once.
    direction = trendDirection;
  }

  // 한두 틱의 일상적인 등락은 기존 호가를 흔들지 않는다. 3틱 이상을
  // 한 번에 통과하거나 당일 추세가 커질수록 앞 호가의 취소·소진이
  // 빨라지는 국면으로 전환한다.
  final tickIntensity = crossedTicks <= 1
      ? 0.0
      : ((crossedTicks - 1) / 6).clamp(0.0, 1.0).toDouble();
  final trendIntensity =
      dailyMoveRate.abs() <= _gameOrderBookTrendActivationRate
      ? 0.0
      : ((dailyMoveRate.abs() - _gameOrderBookTrendActivationRate) / 0.12)
            .clamp(0.0, 1.0)
            .toDouble();
  final flowLoad = standingBaseDepth <= 0
      ? 0.0
      : executionCapacity / standingBaseDepth;
  final hasDirectionalPressure =
      crossedTicks >= 2 ||
      dailyMoveRate.abs() >= _gameOrderBookTrendActivationRate;
  final flowIntensity = !hasDirectionalPressure || flowLoad <= 0.55
      ? 0.0
      : ((flowLoad - 0.55) / 0.75).clamp(0.0, 1.0).toDouble();
  if (direction == 0 && flowIntensity > 0) {
    direction =
        _gameOrderBookAggressorSide(
              seededAssetId: seededAssetId,
              day: day,
              minute: minute,
              previousPrice: currentPrice,
              currentPrice: currentPrice,
            ) ==
            GameOrderBookSide.ask
        ? 1
        : -1;
  }

  // 같은 움직임에도 모든 종목의 호가가 똑같이 얇아지지 않도록 종목별
  // 민감도를 고정한다. 이 값은 날짜 안에서 바뀌지 않아 매분 재추첨처럼
  // 보이지 않으면서도 일부 급등락주는 훨씬 빠르게 반응한다.
  final responsiveness = 0.82 + _orderBookUnit(seededAssetId, day, 9539) * 0.36;
  final rawIntensity = math.max(
    tickIntensity,
    math.max(trendIntensity * 0.82, flowIntensity),
  );
  return _GameOrderBookRegime(
    direction: direction,
    crossedTicks: crossedTicks,
    intensity: (rawIntensity * responsiveness).clamp(0.0, 1.0).toDouble(),
  );
}

GameOrderBookTradePulse? gameOrderBookTradePulse({
  required String assetId,
  required int day,
  required int minute,
  required double previousPrice,
  required double currentPrice,
  required int executionCapacity,
  required String market,
  String simulationSeed = '',
  int levelCount = gameOrderBookLevelCount,
  int liquidityPulse = 0,
}) {
  if (assetId.isEmpty ||
      levelCount <= 0 ||
      executionCapacity <= 0 ||
      !previousPrice.isFinite ||
      !currentPrice.isFinite ||
      previousPrice <= 0 ||
      currentPrice <= 0) {
    return null;
  }
  final seededAssetId = simulationSeed.isEmpty
      ? assetId
      : '$simulationSeed:$assetId';
  final pulseSalt = liquidityPulse <= 0
      ? minute * 73 + 2203
      : minute * 73 + liquidityPulse * 13007 + 2203;
  final hash = _orderBookHash(seededAssetId, day, pulseSalt);
  final dominantSide = _gameOrderBookAggressorSide(
    seededAssetId: seededAssetId,
    day: day,
    minute: minute,
    previousPrice: previousPrice,
    currentPrice: currentPrice,
  );
  final previousLadderIndex = _marketPriceLadderIndex(
    previousPrice,
    market: market,
  );
  final currentLadderIndex = _marketPriceLadderIndex(
    currentPrice,
    market: market,
  );
  final crossedTicks = math.max(
    1,
    (currentLadderIndex - previousLadderIndex).abs(),
  );
  final index = (crossedTicks - 1).clamp(0, levelCount - 1);
  final moveIntensity = ((crossedTicks - 1) / math.max(1, levelCount - 1))
      .clamp(0.0, 1.0)
      .toDouble();
  var side = dominantSide;
  if (liquidityPulse > 0) {
    // A minute candle gives the dominant aggressor, not every individual
    // trade. Sub-minute prints therefore retain a strong directional bias
    // while still allowing realistic counter-side executions.
    final directional = (currentPrice - previousPrice).abs() > 0.000001;
    final dominantProbability = directional
        ? 0.65 + moveIntensity * 0.20
        : 0.72;
    final sideDraw =
        (_orderBookMixedHash(
              seededAssetId,
              day,
              minute * 104729 + liquidityPulse * 15485863 + 7919,
            ) %
            1000000) /
        999999;
    if (sideDraw >= dominantProbability) {
      side = dominantSide == GameOrderBookSide.ask
          ? GameOrderBookSide.bid
          : GameOrderBookSide.ask;
    }
  }
  final participation =
      (0.08 +
              (hash % 25) / 100 +
              moveIntensity *
                  (0.38 +
                      _orderBookUnit(seededAssetId, day, minute * 89 + 4099) *
                          0.24))
          .clamp(0.08, 0.92)
          .toDouble();
  final quantity = math.max(1, (executionCapacity * participation).round());
  return GameOrderBookTradePulse(
    levelSide: side,
    levelIndex: index,
    quantity: quantity,
    crossedTicks: crossedTicks,
  );
}

/// 화면에 표시된 반대편 호가를 가격 순서대로 실제 소모한다.
///
/// 지정가 매수는 지정가 이하 매도호가만, 지정가 매도는 지정가 이상
/// 매수호가만 체결한다. [availableCapacity]는 같은 분에 이미 체결된
/// 수량을 제외한 잔여 분당 소화량이다.
GameOrderBookFillPlan gameOrderBookLimitFillPlan({
  required GameOrderBookSnapshot snapshot,
  required bool isBuy,
  required double requestedQuantity,
  required double limitPrice,
  int? availableCapacity,
  int? maximumNotional,
  Map<double, double> alreadyConsumedByPrice = const <double, double>{},
}) {
  final side = isBuy ? GameOrderBookSide.ask : GameOrderBookSide.bid;
  final capacity = math.min(
    snapshot.executionCapacity,
    availableCapacity ?? snapshot.executionCapacity,
  );
  if (!requestedQuantity.isFinite ||
      requestedQuantity <= 0 ||
      !limitPrice.isFinite ||
      limitPrice <= 0 ||
      capacity <= 0) {
    return GameOrderBookFillPlan(
      levelSide: side,
      fills: const [],
      filledQuantity: 0,
      notional: 0,
      averagePrice: 0,
      worstPrice: 0,
    );
  }

  final levels = isBuy ? snapshot.asks : snapshot.bids;
  final turnoverNotionalLimit = gameOrderBookNotionalLimitForTurnover(
    turnoverEok: snapshot.turnoverEok,
  );
  final notionalLimit = maximumNotional == null
      ? turnoverNotionalLimit
      : math.min(maximumNotional, turnoverNotionalLimit);
  final fills = <GameOrderBookLevelFill>[];
  var remaining = math.min(requestedQuantity.floor(), capacity);
  var filled = 0;
  var notional = 0;
  var worstPrice = 0.0;
  for (var index = 0; index < levels.length && remaining > 0; index++) {
    final level = levels[index];
    final withinLimit = isBuy
        ? level.price <= limitPrice + 0.000001
        : level.price + 0.000001 >= limitPrice;
    if (!withinLimit) break;
    var consumedAtLevel = alreadyConsumedByPrice[level.price] ?? 0;
    if (consumedAtLevel <= 0 && alreadyConsumedByPrice.isNotEmpty) {
      for (final entry in alreadyConsumedByPrice.entries) {
        if ((entry.key - level.price).abs() < 0.000001) {
          consumedAtLevel = entry.value;
          break;
        }
      }
    }
    final availableAtLevel =
        (level.quantity -
                (consumedAtLevel.isFinite
                    ? math.max(0.0, consumedAtLevel)
                    : 0.0))
            .floor();
    var quantity = math.min(math.max(0, availableAtLevel), remaining);
    if (notionalLimit > 0) {
      final remainingBudget = notionalLimit - notional;
      if (remainingBudget <= 0) break;
      quantity = math.min(quantity, (remainingBudget / level.price).floor());
    } else {
      break;
    }
    if (quantity <= 0) continue;
    fills.add(
      GameOrderBookLevelFill(
        levelIndex: index,
        price: level.price,
        quantity: quantity,
      ),
    );
    filled += quantity;
    remaining -= quantity;
    notional += (level.price * quantity).round();
    worstPrice = level.price;
  }
  return GameOrderBookFillPlan(
    levelSide: side,
    fills: List.unmodifiable(fills),
    filledQuantity: filled,
    notional: notional,
    averagePrice: filled <= 0 ? 0 : notional / filled,
    worstPrice: worstPrice,
  );
}

/// Returns a presentation/execution view with previously consumed absolute
/// prices removed from the visible standing depth.
///
/// Within one market minute, keep the raw generative snapshot cached and derive
/// panel/execution views from it. At the minute boundary, callers may promote
/// the latest net snapshot once as [buildGameOrderBookSnapshot]'s
/// `previousSnapshot`: its reduced absolute-price quantities carry forward,
/// while the builder resets the applied watermarks for the new minute.
GameOrderBookSnapshot gameOrderBookSnapshotAfterConsumption({
  required GameOrderBookSnapshot snapshot,
  Map<double, double> consumedAskByPrice = const <double, double>{},
  Map<double, double> consumedBidByPrice = const <double, double>{},
  int consumedCapacityUnits = 0,
}) {
  double quantityAtPrice(Map<double, double> quantities, double price) {
    final exact = quantities[price];
    if (exact != null) return exact;
    for (final entry in quantities.entries) {
      if ((entry.key - price).abs() < 0.000001) return entry.value;
    }
    return 0;
  }

  Map<double, double> mergedWatermark(
    Map<double, double> applied,
    Map<double, double> consumed,
  ) {
    final merged = <double, double>{};
    for (final entry in [...applied.entries, ...consumed.entries]) {
      if (!entry.key.isFinite ||
          entry.key <= 0 ||
          !entry.value.isFinite ||
          entry.value <= 0) {
        continue;
      }
      final previous = quantityAtPrice(merged, entry.key);
      if (entry.value > previous) merged[entry.key] = entry.value;
    }
    return Map<double, double>.unmodifiable(merged);
  }

  GameOrderBookLevel netLevel(
    GameOrderBookLevel level,
    Map<double, double> consumed,
    Map<double, double> applied,
  ) {
    final cumulative = quantityAtPrice(consumed, level.price);
    final alreadyApplied = quantityAtPrice(applied, level.price);
    final used = math.max(
      0.0,
      (cumulative.isFinite ? cumulative : 0.0) -
          (alreadyApplied.isFinite ? alreadyApplied : 0.0),
    );
    final remaining = (level.quantity - (used.isFinite ? used : 0.0)).floor();
    return GameOrderBookLevel(
      side: level.side,
      price: level.price,
      quantity: math.max(0, remaining),
      isWall: level.isWall,
      structuralKind: level.structuralKind,
      structuralStrength: level.structuralStrength,
      structuralHoldTicks: level.structuralHoldTicks,
      isStructuralWall: level.isStructuralWall,
      isStructuralBreached: level.isStructuralBreached,
      structuralVacuumMultiplier: level.structuralVacuumMultiplier,
      isPsychological: level.isPsychological,
      technicalPeriods: level.technicalPeriods,
      wasLiquidityPulseTouched: level.wasLiquidityPulseTouched,
    );
  }

  final asks = snapshot.asks
      .map(
        (level) => netLevel(
          level,
          consumedAskByPrice,
          snapshot.appliedAskConsumptionByPrice,
        ),
      )
      .where((level) => level.quantity > 0)
      .toList(growable: false);
  final bids = snapshot.bids
      .map(
        (level) => netLevel(
          level,
          consumedBidByPrice,
          snapshot.appliedBidConsumptionByPrice,
        ),
      )
      .where((level) => level.quantity > 0)
      .toList(growable: false);
  final rememberedLevels = <double, GameOrderBookLevel>{
    for (final entry in snapshot.rememberedLevels.entries)
      entry.key: entry.value.side == GameOrderBookSide.ask
          ? netLevel(
              entry.value,
              consumedAskByPrice,
              snapshot.appliedAskConsumptionByPrice,
            )
          : netLevel(
              entry.value,
              consumedBidByPrice,
              snapshot.appliedBidConsumptionByPrice,
            ),
  };
  final totalAsk = asks.fold<int>(0, (sum, level) => sum + level.quantity);
  final totalBid = bids.fold<int>(0, (sum, level) => sum + level.quantity);
  final appliedAskConsumptionByPrice = mergedWatermark(
    snapshot.appliedAskConsumptionByPrice,
    consumedAskByPrice,
  );
  final appliedBidConsumptionByPrice = mergedWatermark(
    snapshot.appliedBidConsumptionByPrice,
    consumedBidByPrice,
  );
  return GameOrderBookSnapshot(
    asks: List<GameOrderBookLevel>.unmodifiable(asks),
    bids: List<GameOrderBookLevel>.unmodifiable(bids),
    turnoverEok: snapshot.turnoverEok,
    executionCapacity: snapshot.executionCapacity,
    totalAskQuantity: totalAsk,
    totalBidQuantity: totalBid,
    tradeStrength: totalAsk <= 0
        ? totalBid > 0
              ? 240
              : 100
        : (totalBid / totalAsk * 100).clamp(20, 240).toDouble(),
    liquidityPulse: snapshot.liquidityPulse,
    adaptiveLiquidityPulses: snapshot.adaptiveLiquidityPulses,
    rememberedLevels: Map<double, GameOrderBookLevel>.unmodifiable(
      rememberedLevels,
    ),
    sourceAssetId: snapshot.sourceAssetId,
    sourceLiquidityDayKey: snapshot.sourceLiquidityDayKey,
    sourceDateKey: snapshot.sourceDateKey,
    sourceMarketMinute: snapshot.sourceMarketMinute,
    sourceLastTradePrice: snapshot.sourceLastTradePrice,
    sourceMarket: snapshot.sourceMarket,
    sourceSimulationSeed: snapshot.sourceSimulationSeed,
    appliedAskConsumptionByPrice: appliedAskConsumptionByPrice,
    appliedBidConsumptionByPrice: appliedBidConsumptionByPrice,
    appliedCapacityConsumptionUnits: math.max(
      snapshot.appliedCapacityConsumptionUnits,
      math.max(0, consumedCapacityUnits),
    ),
  );
}

double gameOrderBookQueueAhead({
  required GameOrderBookSnapshot snapshot,
  required bool isBuy,
  required double limitPrice,
}) {
  final levels = isBuy ? snapshot.bids : snapshot.asks;
  for (final level in levels) {
    if ((level.price - limitPrice).abs() < 0.000001) {
      return level.quantity.toDouble();
    }
  }
  return 0;
}

GameOrderBookSnapshot buildGameOrderBookSnapshot({
  required String assetId,
  required int day,
  required int minute,
  required double currentPrice,
  required double previousClose,
  required DateTime date,
  required String market,
  String simulationSeed = '',
  double? previousTradePrice,
  int levelCount = gameOrderBookLevelCount,
  bool tradingDay = true,
  int? sharesOutstanding,
  bool isIpoFirstTradingDay = false,
  double? sessionLow,
  double? sessionHigh,
  GameOrderBookSnapshot? previousSnapshot,
  int? previousSnapshotMinute,
  Iterable<MarketTechnicalLevel> technicalLevels =
      const <MarketTechnicalLevel>[],
  int liquidityPulse = 0,
  bool adaptiveLiquidityPulses = false,
}) {
  if (!tradingDay ||
      assetId.isEmpty ||
      !currentPrice.isFinite ||
      currentPrice <= 0) {
    return GameOrderBookSnapshot(
      asks: const [],
      bids: const [],
      turnoverEok: 0,
      executionCapacity: 0,
      totalAskQuantity: 0,
      totalBidQuantity: 0,
      tradeStrength: 100,
      liquidityPulse: math.max(0, liquidityPulse),
      adaptiveLiquidityPulses: adaptiveLiquidityPulses,
      sourceAssetId: assetId,
      sourceLiquidityDayKey: day,
      sourceDateKey: marketDateKey(date),
      sourceMarketMinute: minute,
      sourceMarket: market,
      sourceSimulationSeed: simulationSeed,
    );
  }
  final seededAssetId = simulationSeed.isEmpty
      ? assetId
      : '$simulationSeed:$assetId';
  final safeLiquidityPulse = math.max(0, liquidityPulse);
  final safePreviousClose = previousClose.isFinite && previousClose > 0
      ? previousClose
      : currentPrice;
  final range = marketDailyPriceRange(
    previousClose: safePreviousClose,
    date: date,
    market: market,
    isIpoFirstTradingDay: isIpoFirstTradingDay,
  );
  final lastTradePrice = marketSnapPrice(
    currentPrice.clamp(range.lower, range.upper).toDouble(),
    market: market,
  );
  var center = lastTradePrice;
  final hasPreviousTrade =
      previousTradePrice != null &&
      previousTradePrice.isFinite &&
      previousTradePrice > 0;
  if (hasPreviousTrade) {
    final previous = marketSnapPrice(
      previousTradePrice.clamp(range.lower, range.upper).toDouble(),
      market: market,
    );
    final aggressorSide = _gameOrderBookAggressorSide(
      seededAssetId: seededAssetId,
      day: day,
      minute: minute,
      previousPrice: previous,
      currentPrice: lastTradePrice,
    );
    if (aggressorSide == GameOrderBookSide.ask &&
        lastTradePrice > range.lower + 0.000001) {
      final previousTick = marketTickSize(
        math.max(0.000001, lastTradePrice - 0.000001),
        market: market,
      );
      final candidate = marketSnapPrice(
        lastTradePrice - previousTick,
        market: market,
      );
      if (candidate >= range.lower - 0.000001 && candidate < lastTradePrice) {
        center = candidate;
      }
    }
  }
  final tradable =
      tradingDay && marketClockAt(minute, tradingDay: true).tradable;
  final turnoverEok = gameEstimatedTurnoverEok(
    assetId: assetId,
    day: day,
    minute: minute,
    unitPrice: lastTradePrice,
    previousClose: safePreviousClose,
    simulationSeed: simulationSeed,
    sharesOutstanding: sharesOutstanding,
  );
  final executionCapacity = tradable
      ? gameOrderBookExecutionCapacity(
          assetId: assetId,
          day: day,
          minute: minute,
          unitPrice: lastTradePrice,
          previousClose: safePreviousClose,
          simulationSeed: simulationSeed,
          cumulativeTurnoverEok: turnoverEok,
          sharesOutstanding: sharesOutstanding,
        )
      : 0;
  final baseDepth = _gameOrderBookStandingBaseDepth(
    assetId: seededAssetId,
    day: day,
    minute: minute,
    referencePrice: safePreviousClose,
    sharesOutstanding: sharesOutstanding,
  );
  final previousForRegime = hasPreviousTrade
      ? marketSnapPrice(
          previousTradePrice.clamp(range.lower, range.upper).toDouble(),
          market: market,
        )
      : lastTradePrice;
  final regime = _gameOrderBookRegime(
    seededAssetId: seededAssetId,
    day: day,
    minute: minute,
    previousPrice: previousForRegime,
    currentPrice: lastTradePrice,
    previousClose: safePreviousClose,
    market: market,
    executionCapacity: executionCapacity,
    standingBaseDepth: baseDepth,
  );
  final currentLadderIndex = _marketPriceLadderIndex(center, market: market);
  final fallbackSessionLow = math.min(previousForRegime, lastTradePrice);
  final fallbackSessionHigh = math.max(previousForRegime, lastTradePrice);
  final effectiveSessionLow =
      sessionLow != null && sessionLow.isFinite && sessionLow > 0
      ? math.min(sessionLow, fallbackSessionLow)
      : fallbackSessionLow;
  final effectiveSessionHigh =
      sessionHigh != null && sessionHigh.isFinite && sessionHigh > 0
      ? math.max(sessionHigh, fallbackSessionHigh)
      : fallbackSessionHigh;
  final structuralLiquidity = buildMarketStructuralLiquidityMap(
    worldSeed: simulationSeed,
    assetId: assetId,
    market: market,
    referencePrice: safePreviousClose,
    lowerPrice: range.lower,
    upperPrice: range.upper,
    sessionLow: effectiveSessionLow,
    sessionHigh: effectiveSessionHigh,
    technicalLevels: technicalLevels,
  );
  const wallPeriod = gameOrderBookWallPricePeriod;
  final wallOffset = _orderBookHash(seededAssetId, day, 701) % wallPeriod;
  final minimumLevelCount = math.max(0, levelCount);
  final reserveLevelCount = math.min(6, minimumLevelCount);
  final elapsedMinutes = previousSnapshotMinute == null
      ? null
      : minute - previousSnapshotMinute;
  final carriesPreviousBook =
      previousSnapshot != null && elapsedMinutes != null && elapsedMinutes >= 0;
  final carryContext = carriesPreviousBook
      ? _GameOrderBookCarryContext(
          previousSnapshot: previousSnapshot,
          elapsedMinutes: elapsedMinutes,
          fastMarket: regime.isFast,
          liquidityPulse: safeLiquidityPulse,
          adaptiveLiquidityPulses: adaptiveLiquidityPulses,
        )
      : null;
  final asks = <GameOrderBookLevel>[];
  final bids = <GameOrderBookLevel>[];

  GameOrderBookLevel carryLevel(GameOrderBookLevel level) {
    return carryContext?.carry(level) ?? level;
  }

  bool hasExecutableDepthReserve(List<GameOrderBookLevel> levels) {
    if (levels.length < minimumLevelCount) return false;
    if (minimumLevelCount < 6 || executionCapacity <= 0) return true;
    if (levels.length <= reserveLevelCount) return false;
    final executableDepth = levels
        .take(levels.length - reserveLevelCount)
        .fold<int>(0, (sum, level) => sum + level.quantity);
    return executableDepth >= executionCapacity;
  }

  var askPrice = marketSnapPrice(
    center + marketTickSize(center, market: market),
    market: market,
  );
  while (!hasExecutableDepthReserve(asks)) {
    if (askPrice > range.upper + 0.000001) break;
    asks.add(
      carryLevel(
        _buildLevel(
          side: GameOrderBookSide.ask,
          assetId: seededAssetId,
          day: day,
          minute: minute,
          price: askPrice,
          baseDepth: baseDepth,
          market: market,
          wallOffset: wallOffset,
          wallPeriod: wallPeriod,
          regime: regime,
          currentLadderIndex: currentLadderIndex,
          levelCount: minimumLevelCount,
          structuralLiquidity: structuralLiquidity,
          liquidityPulse: safeLiquidityPulse,
          adaptiveLiquidityPulses: adaptiveLiquidityPulses,
        ),
      ),
    );
    final tick = marketTickSize(askPrice, market: market);
    final next = marketSnapPrice(askPrice + tick, market: market);
    if (next <= askPrice) break;
    askPrice = next;
  }

  var bidPrice = center;
  while (!hasExecutableDepthReserve(bids)) {
    if (bidPrice < range.lower - 0.000001 || bidPrice <= 0) break;
    bids.add(
      carryLevel(
        _buildLevel(
          side: GameOrderBookSide.bid,
          assetId: seededAssetId,
          day: day,
          minute: minute,
          price: bidPrice,
          baseDepth: baseDepth,
          market: market,
          wallOffset: wallOffset,
          wallPeriod: wallPeriod,
          regime: regime,
          currentLadderIndex: currentLadderIndex,
          levelCount: minimumLevelCount,
          structuralLiquidity: structuralLiquidity,
          liquidityPulse: safeLiquidityPulse,
          adaptiveLiquidityPulses: adaptiveLiquidityPulses,
        ),
      ),
    );
    final tick = marketTickSize(
      math.max(0.000001, bidPrice - 0.000001),
      market: market,
    );
    final next = marketSnapPrice(bidPrice - tick, market: market);
    if (next >= bidPrice) break;
    bidPrice = next;
  }

  final displayedAsks = asks;
  final displayedBids = bids;
  final totalAsk = displayedAsks.fold<int>(
    0,
    (sum, level) => sum + level.quantity,
  );
  final totalBid = displayedBids.fold<int>(
    0,
    (sum, level) => sum + level.quantity,
  );
  final strength = totalAsk <= 0
      ? totalBid > 0
            ? 240.0
            : 100.0
      : (totalBid / totalAsk * 100).clamp(20, 240).toDouble();
  final rememberedLevels = <double, GameOrderBookLevel>{
    if (carriesPreviousBook) ...previousSnapshot.rememberedLevels,
    if (carriesPreviousBook)
      for (final level in [...previousSnapshot.asks, ...previousSnapshot.bids])
        level.price: level,
    for (final level in [...displayedAsks, ...displayedBids])
      level.price: level,
  };
  return GameOrderBookSnapshot(
    asks: List.unmodifiable(displayedAsks),
    bids: List.unmodifiable(displayedBids),
    turnoverEok: turnoverEok,
    executionCapacity: executionCapacity,
    totalAskQuantity: totalAsk,
    totalBidQuantity: totalBid,
    tradeStrength: strength,
    liquidityPulse: safeLiquidityPulse,
    adaptiveLiquidityPulses: adaptiveLiquidityPulses,
    rememberedLevels: Map.unmodifiable(rememberedLevels),
    sourceAssetId: assetId,
    sourceLiquidityDayKey: day,
    sourceDateKey: marketDateKey(date),
    sourceMarketMinute: minute,
    sourceLastTradePrice: lastTradePrice,
    sourceMarket: market,
    sourceSimulationSeed: simulationSeed,
    appliedAskConsumptionByPrice: carriesPreviousBook && elapsedMinutes == 0
        ? previousSnapshot.appliedAskConsumptionByPrice
        : const <double, double>{},
    appliedBidConsumptionByPrice: carriesPreviousBook && elapsedMinutes == 0
        ? previousSnapshot.appliedBidConsumptionByPrice
        : const <double, double>{},
    appliedCapacityConsumptionUnits: carriesPreviousBook && elapsedMinutes == 0
        ? previousSnapshot.appliedCapacityConsumptionUnits
        : 0,
  );
}

class _GameOrderBookCarryContext {
  _GameOrderBookCarryContext({
    required GameOrderBookSnapshot previousSnapshot,
    required int elapsedMinutes,
    required this.fastMarket,
    required int liquidityPulse,
    required bool adaptiveLiquidityPulses,
  }) : previousByPrice = <double, GameOrderBookLevel>{
         ...previousSnapshot.rememberedLevels,
         for (final level in [
           ...previousSnapshot.asks,
           ...previousSnapshot.bids,
         ])
           level.price: level,
       },
       pulseAdvanced =
           adaptiveLiquidityPulses &&
           liquidityPulse > previousSnapshot.liquidityPulse,
       noNewAdaptivePulse =
           adaptiveLiquidityPulses &&
           liquidityPulse <= previousSnapshot.liquidityPulse,
       effectiveLimit =
           adaptiveLiquidityPulses &&
               liquidityPulse > previousSnapshot.liquidityPulse
           ? (fastMarket ? 0.28 : 0.12)
           : elapsedMinutes <= 0
           ? 0.0
           : 1 -
                 math
                     .pow(
                       1 - (fastMarket ? 0.42 : 0.10),
                       math.min(elapsedMinutes, 12),
                     )
                     .toDouble();

  final Map<double, GameOrderBookLevel> previousByPrice;
  final bool fastMarket;
  final bool pulseAdvanced;
  final bool noNewAdaptivePulse;
  final double effectiveLimit;

  int _carriedQuantity(GameOrderBookLevel level, GameOrderBookLevel previous) {
    if (level.isStructuralBreached ||
        level.structuralVacuumMultiplier < 0.999999) {
      return math.min(previous.quantity, level.quantity);
    }
    if (previous.quantity <= 0) {
      if (!pulseAdvanced || !level.wasLiquidityPulseTouched) return 0;
      final replenished = math.max(
        1,
        (level.quantity * (fastMarket ? 0.12 : 0.06)).round(),
      );
      return math.min(level.quantity, replenished);
    }
    if (noNewAdaptivePulse ||
        (pulseAdvanced && !level.wasLiquidityPulseTouched)) {
      return previous.quantity;
    }
    final adjustment = (previous.quantity * effectiveLimit).floor();
    return level.quantity
        .clamp(
          math.max(1, previous.quantity - adjustment),
          previous.quantity + adjustment,
        )
        .toInt();
  }

  GameOrderBookLevel carry(GameOrderBookLevel level) {
    final previous = previousByPrice[level.price];
    if (previous == null) return level;
    return GameOrderBookLevel(
      side: level.side,
      price: level.price,
      quantity: _carriedQuantity(level, previous),
      isWall:
          (level.isStructuralBreached ||
              level.structuralVacuumMultiplier < 0.999999)
          ? false
          : level.isStructuralWall
          ? true
          : previous.isWall,
      structuralKind: level.structuralKind,
      structuralStrength: level.structuralStrength,
      structuralHoldTicks: level.structuralHoldTicks,
      isStructuralWall: level.isStructuralWall,
      isStructuralBreached: level.isStructuralBreached,
      structuralVacuumMultiplier: level.structuralVacuumMultiplier,
      isPsychological: level.isPsychological,
      technicalPeriods: level.technicalPeriods,
      wasLiquidityPulseTouched: level.wasLiquidityPulseTouched,
    );
  }
}

GameOrderBookLevel _buildLevel({
  required GameOrderBookSide side,
  required String assetId,
  required int day,
  required int minute,
  required double price,
  required int baseDepth,
  required String market,
  required int wallOffset,
  required int wallPeriod,
  required _GameOrderBookRegime regime,
  required int currentLadderIndex,
  required int levelCount,
  required MarketStructuralLiquidityMap structuralLiquidity,
  required int liquidityPulse,
  required bool adaptiveLiquidityPulses,
}) {
  final ladderIndex = _marketPriceLadderIndex(price, market: market);
  final structuralZone = structuralLiquidity.zoneAtPrice(price);
  final isStructuralBreached =
      structuralZone != null &&
      structuralZone.isActive &&
      structuralZone.isBreached;
  final isStructuralWall =
      structuralZone != null &&
      structuralZone.isActive &&
      !structuralZone.isBreached;
  final gapVacuum = structuralLiquidity.vacuumMultiplierAt(price);
  final structuralVacuum = isStructuralBreached
      ? math.min(gapVacuum, structuralZone.vacuumMultiplier)
      : gapVacuum;
  final isInStructuralVacuum = structuralVacuum < 0.999999;
  final isMicroWall =
      wallPeriod > 0 &&
      ((ladderIndex - wallOffset) % wallPeriod + wallPeriod) % wallPeriod == 0;
  final isWall =
      isStructuralWall ||
      (isMicroWall && !isStructuralBreached && !isInStructuralVacuum);
  final pulseTouchesLevel =
      adaptiveLiquidityPulses &&
      liquidityPulse > 0 &&
      _gameOrderBookPulseTouchesPrice(
        assetId: assetId,
        day: day,
        liquidityPulse: liquidityPulse,
        ladderIndex: ladderIndex,
        currentLadderIndex: currentLadderIndex,
        levelCount: levelCount,
        fastMarket: regime.isFast,
      );
  // 가격별 기준 잔량은 하루 동안 유지하고, 주문 유입·취소는 완만한
  // 보간값만 더한다. 화면 행 번호나 매분 독립 난수에 수량을 묶지 않는다.
  // Standing liquidity belongs to an absolute price, not to its current row
  // or side of the spread. When a price crosses the center, carry its baseline
  // depth and wall identity forward instead of drawing a brand-new book.
  final priceSalt = ladderIndex * 131 + 1301;
  final stableVariation = 0.76 + _orderBookUnit(assetId, day, priceSalt) * 0.48;
  final temporalVariation =
      0.94 +
      _smoothOrderBookUnit(
            assetId,
            day,
            minute,
            priceSalt + 3109,
            windowMinutes: 12,
          ) *
          0.12;
  final wallPulse =
      0.97 +
      _smoothOrderBookUnit(
            assetId,
            day,
            minute,
            priceSalt + 4253,
            windowMinutes: 18,
          ) *
          0.06;
  final wallMultiplier = isStructuralWall
      ? structuralZone.strength * wallPulse
      : isWall
      ? (1.55 + _orderBookUnit(assetId, day, priceSalt + 1877) * 0.80) *
            wallPulse
      : 1.0;
  var pulseMultiplier = 1.0;
  if (pulseTouchesLevel) {
    final pulseUnit = _orderBookUnit(
      assetId,
      day,
      liquidityPulse * 8191 + ladderIndex * 37 + 7307,
    );
    if (regime.consumes(side)) {
      pulseMultiplier = regime.isFast
          ? 0.72 + pulseUnit * 0.18
          : 0.86 + pulseUnit * 0.10;
    } else if (regime.direction != 0) {
      pulseMultiplier = regime.isFast
          ? 1.08 + pulseUnit * 0.18
          : 1.02 + pulseUnit * 0.10;
    } else {
      pulseMultiplier = 0.90 + pulseUnit * 0.20;
    }
  }
  var regimeMultiplier = 1.0;
  if (regime.direction != 0 && regime.intensity > 0) {
    final distanceFromTrade = (ladderIndex - currentLadderIndex).abs();
    final proximity = (1 - distanceFromTrade / math.max(2, levelCount + 1))
        .clamp(0.12, 1.0)
        .toDouble();
    final flowWave = _smoothOrderBookUnit(
      assetId,
      day,
      minute,
      priceSalt + 6113,
      windowMinutes: regime.isFast ? 2 : 4,
    );
    final wave = 0.45 + flowWave * 1.1;
    if (regime.consumes(side)) {
      // 상승 때는 매도호가, 하락 때는 매수호가가 먼저 소진된다.
      // 벽은 일반 잔량보다 버티지만 강한 국면에서는 빠르게 얇아질 수 있다.
      final wallResistance = isWall ? 0.82 : 1.0;
      final ordinaryDepletion =
          regime.intensity * proximity * wallResistance * (0.28 + wave * 0.70);
      final fastDepletionFloor = regime.isFast
          ? regime.intensity *
                (isWall
                    ? math.max(0.28, proximity * 0.55)
                    : math.max(0.18, proximity * 0.50))
          : 0.0;
      final depletion = math
          .max(ordinaryDepletion, fastDepletionFloor)
          .clamp(0.0, 0.86)
          .toDouble();
      regimeMultiplier = 1 - depletion;
    } else {
      // 반대편에는 추격 주문과 재유입이 쌓여 한쪽으로 몰린 수급이
      // 잔량 막대의 방향성으로도 읽히게 한다.
      final replenishment =
          (regime.intensity * proximity * (0.12 + wave * 0.60))
              .clamp(0.0, 1.15)
              .toDouble();
      regimeMultiplier = 1 + replenishment;
    }
  }
  return GameOrderBookLevel(
    side: side,
    price: price,
    quantity: math.max(
      1,
      (baseDepth *
              stableVariation *
              temporalVariation *
              wallMultiplier *
              pulseMultiplier *
              structuralVacuum *
              regimeMultiplier)
          .round(),
    ),
    isWall: isWall,
    structuralKind: structuralZone?.kind,
    structuralStrength: structuralZone?.strength ?? 1,
    structuralHoldTicks: structuralZone?.holdTicks ?? 0,
    isStructuralWall: isStructuralWall,
    isStructuralBreached: isStructuralBreached,
    structuralVacuumMultiplier: structuralVacuum,
    isPsychological: structuralZone?.isPsychological ?? false,
    technicalPeriods: structuralZone?.technicalPeriods ?? const <int>[],
    wasLiquidityPulseTouched: pulseTouchesLevel,
  );
}

bool _gameOrderBookPulseTouchesPrice({
  required String assetId,
  required int day,
  required int liquidityPulse,
  required int ladderIndex,
  required int currentLadderIndex,
  required int levelCount,
  required bool fastMarket,
}) {
  final touchedCount = fastMarket
      ? 3
      : 1 + _orderBookMixedHash(assetId, day, liquidityPulse * 3571 + 7013) % 2;
  final visibleSpan = math.max(1, levelCount * 2);
  final firstVisibleOffset = -(levelCount - 1);
  for (var slot = 0; slot < touchedCount; slot += 1) {
    final selectedOffset =
        _orderBookMixedHash(
          assetId,
          day,
          liquidityPulse * 10007 + slot * 7919 + 9029,
        ) %
        visibleSpan;
    if (ladderIndex ==
        currentLadderIndex + firstVisibleOffset + selectedOffset) {
      return true;
    }
  }
  return false;
}

int _gameOrderBookStandingBaseDepth({
  required String assetId,
  required int day,
  required int minute,
  required double referencePrice,
  int? sharesOutstanding,
}) {
  final fullDayUnits = gameEstimatedFullDayVolumeUnits(
    assetId: assetId,
    day: day,
    referencePrice: referencePrice,
    sharesOutstanding: sharesOutstanding,
  );
  if (fullDayUnits <= 0) return 20;

  final dailyDepthFactor = 0.78 + _orderBookUnit(assetId, day, 6121) * 0.44;
  final sessionFlow =
      0.94 +
      _smoothOrderBookUnit(assetId, day, minute, 7213, windowMinutes: 24) *
          0.12;
  final averageMinuteUnits =
      fullDayUnits / math.max(1, _gameOrderBookRegularSessionMinutes);
  final raw = averageMinuteUnits * 1.45 * dailyDepthFactor * sessionFlow;
  if (!raw.isFinite || raw <= 0) return 20;
  return raw.round().clamp(20, 0x7fffffff).toInt();
}

double _smoothOrderBookUnit(
  String assetId,
  int day,
  int minute,
  int salt, {
  required int windowMinutes,
}) {
  final safeWindow = math.max(1, windowMinutes);
  final safeMinute = math.max(0, minute);
  final bucket = safeMinute ~/ safeWindow;
  final phase = (safeMinute % safeWindow) / safeWindow;
  final easedPhase = phase * phase * (3 - 2 * phase);
  final start = _orderBookUnit(assetId, day, salt + bucket * 3571);
  final end = _orderBookUnit(assetId, day, salt + (bucket + 1) * 3571);
  return start + (end - start) * easedPhase;
}

int _marketPriceLadderIndex(double price, {required String market}) {
  final snapped = marketSnapPrice(price, market: market).round();
  if (snapped < 1000) return snapped;

  var index = 1000;
  if (snapped < 5000) return index + ((snapped - 1000) ~/ 5);
  index += 800;
  if (snapped < 10000) return index + ((snapped - 5000) ~/ 10);
  index += 500;
  if (snapped < 50000) return index + ((snapped - 10000) ~/ 50);
  index += 800;
  if (snapped < 100000) return index + ((snapped - 50000) ~/ 100);
  index += 500;

  if (market == '도전시장') {
    return index + ((snapped - 100000) ~/ 100);
  }
  if (snapped < 500000) return index + ((snapped - 100000) ~/ 500);
  index += 800;
  return index + ((snapped - 500000) ~/ 1000);
}

int _orderBookHash(String assetId, int day, int salt) {
  var hash = (day * 1009 + salt * 9176) & 0x7fffffff;
  for (final unit in assetId.codeUnits) {
    hash = ((hash * 31) ^ unit) & 0x7fffffff;
  }
  return hash;
}

int _orderBookMixedHash(String assetId, int day, int salt) {
  var value = _orderBookHash(assetId, day, salt);
  value ^= value >> 16;
  value = (value * 0x45d9f3b) & 0x7fffffff;
  value ^= value >> 15;
  value = (value * 0x45d9f3b) & 0x7fffffff;
  value ^= value >> 16;
  return value & 0x7fffffff;
}

double _orderBookUnit(String assetId, int day, int salt) =>
    (_orderBookHash(assetId, day, salt) % 10000) / 9999;
