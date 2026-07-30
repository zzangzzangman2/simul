import 'dart:math' as math;

import 'market_clock.dart';
import 'market_liquidity_zones.dart';
import 'market_technical_levels.dart';

enum GameOrderBookSide { ask, bid }

/// 화면과 주문 엔진이 공통으로 생성하는 한쪽당 호가 깊이.
const gameOrderBookLevelCount = 10;

/// 최우선호가 한 단계가 담는 평균 시장분 거래량 배수.
///
/// 분당 체결능력(평온장 중앙값 약 0.30분치)과 1~2 시장분 안에 만나는
/// 두께를 만들며, 체결능력의 0.48 계수와는 독립적으로 유지한다.
const gameOrderBookStandingDepthMinutes = 0.45;

const gameOrderBookMinuteTurnoverShare = 0.25;
const gameOrderBookOrderTurnoverShare = 0.02;
const gameOrderBookVisualCadenceDivisor = 3;
const gameOrderBookMinimumPulsesPerMarketMinute = 1;
const gameOrderBookMaximumOrdinaryPulsesPerMarketMinute = 4;
const gameOrderBookFastPulsesPerMarketMinute = 5;
const gameOrderBookMaximumPulsesPerMarketMinute = 7;
const gameOrderBookPulseFrameStride = 64;
const gameOrderBookSparseFullDayTurnoverEok = 75.0;
const gameOrderBookSeverelySparseFullDayTurnoverEok = 20.0;
const gameOrderBookMinimumDisplayedQuantity = 10;
const gameOrderBookStructuralConsumptionBreachRatio = 0.90;
const gameOrderBookMinimumImbalanceSamplePrints = 3;
const gameOrderBookMinimumImbalanceSampleTurnoverEok = 0.10;
const gameOrderBookMaximumSyntheticPrintsPerPulse = 12;
const _gameOrderBookFlatBoundaryHoldMinutes = 6;

/// Full-day volume includes the 15:00 closing-auction print, so standing depth
/// uses the same 09:00~15:00 denominator as turnover progress.
const _gameOrderBookFullSessionMinutes = krxCloseMinute - krxOpenMinute;
const _gameOrderBookFastMoveTicks = 3;
const _gameOrderBookTrendActivationRate = 0.04;
const gamePlayerMarketImpactDurationMinutes = 6;

/// Returns deterministic microstructure slots assigned to one market minute.
///
/// The result follows expected full-day turnover rather than wall-clock frame
/// rate. Fast price movement or an extreme execution-strength imbalance can
/// temporarily lift a stock from the ordinary 1-4 slots into 5 or 7 slots.
/// Execution imbalance alone is deliberately ignored for sparse books: a few
/// tiny one-sided prints are not enough evidence to animate an inactive stock
/// like a high-turnover issue.
int gameOrderBookPulsesPerMarketMinute({
  required double fullDayTurnoverEok,
  required double currentPrice,
  required double previousTradePrice,
  required double previousClose,
  String market = 'main',
  double executionStrength = 100,
  int executionSamplePrints = 0,
  double executionSampleTurnoverEok = 0,
  bool tradingSessionActive = true,
  bool playbackActive = true,
}) {
  if (!tradingSessionActive || !playbackActive) return 0;
  final turnover = fullDayTurnoverEok.isFinite
      ? math.max(0.0, fullDayTurnoverEok)
      : 0.0;
  final rawSlots = switch (turnover) {
    < 20 => 1,
    < 75 => 1,
    < 200 => 2,
    < 1000 => 3,
    < 3000 => 5,
    < 7000 => 7,
    < 12000 => 9,
    < 20000 => 11,
    _ => 12,
  };
  var slots = math.max(
    gameOrderBookMinimumPulsesPerMarketMinute,
    (rawSlots / gameOrderBookVisualCadenceDivisor).round(),
  );

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
  final executionImbalance = !executionStrength.isFinite
      ? 1.0
      : executionStrength <= 0
      ? double.infinity
      : math.max(executionStrength / 100, 100 / executionStrength);
  final executionAccelerationAllowed =
      turnover >= gameOrderBookSparseFullDayTurnoverEok &&
      executionSamplePrints >= gameOrderBookMinimumImbalanceSamplePrints &&
      executionSampleTurnoverEok.isFinite &&
      executionSampleTurnoverEok >=
          gameOrderBookMinimumImbalanceSampleTurnoverEok;
  final fast =
      crossedTicks >= _gameOrderBookFastMoveTicks ||
      sessionMoveRate >= 0.06 ||
      (executionAccelerationAllowed && executionImbalance >= 1.65);
  final extreme =
      crossedTicks >= _gameOrderBookFastMoveTicks * 2 ||
      sessionMoveRate >= 0.08 ||
      (executionAccelerationAllowed && executionImbalance >= 2.1);
  if (extreme) {
    slots = gameOrderBookMaximumPulsesPerMarketMinute;
  } else if (fast) {
    slots = math.max(slots, gameOrderBookFastPulsesPerMarketMinute);
  }
  return slots.clamp(
    gameOrderBookMinimumPulsesPerMarketMinute,
    gameOrderBookMaximumPulsesPerMarketMinute,
  );
}

/// Stable identity for one `(marketMinute, slotIndex)` microstructure state.
int gameOrderBookLiquidityPulseFrame({
  required int marketMinute,
  required int slotIndex,
}) {
  final minuteOffset = math.max(0, marketMinute - krxOpenMinute);
  final safeSlot = slotIndex.clamp(
    0,
    gameOrderBookMaximumPulsesPerMarketMinute,
  );
  return minuteOffset * gameOrderBookPulseFrameStride + safeSlot;
}

int gameOrderBookPulseSlotForFrame({
  required int marketMinute,
  required int liquidityPulse,
}) {
  final base = gameOrderBookLiquidityPulseFrame(
    marketMinute: marketMinute,
    slotIndex: 0,
  );
  return (liquidityPulse - base).clamp(
    0,
    gameOrderBookMaximumPulsesPerMarketMinute,
  );
}

List<int> gameOrderBookPendingPulseFrames({
  required int marketMinute,
  required int afterLiquidityPulse,
  required int throughSlotIndex,
}) {
  final afterSlot = gameOrderBookPulseSlotForFrame(
    marketMinute: marketMinute,
    liquidityPulse: afterLiquidityPulse,
  );
  final targetSlot = throughSlotIndex.clamp(
    0,
    gameOrderBookMaximumPulsesPerMarketMinute,
  );
  if (targetSlot <= afterSlot) return const <int>[];
  return List<int>.unmodifiable([
    for (var slot = afterSlot + 1; slot <= targetSlot; slot += 1)
      gameOrderBookLiquidityPulseFrame(
        marketMinute: marketMinute,
        slotIndex: slot,
      ),
  ]);
}

/// Cumulative minute-wide flow available through one reduced visual slot.
///
/// The visual cadence is one third of the former schedule, but the final slot
/// must still expose the complete deterministic minute capacity. This makes
/// each visible move consume proportionally more real standing depth instead
/// of thinning or teleporting through the bid/ask walls.
int gameOrderBookCumulativeSlotCapacity({
  required int executionCapacity,
  required int slotIndex,
  required int pulsesPerMarketMinute,
}) {
  final capacity = math.max(0, executionCapacity);
  final pulses = math.max(1, pulsesPerMarketMinute);
  final slot = slotIndex.clamp(0, pulses);
  if (slot <= 0 || capacity <= 0) return 0;
  if (slot >= pulses) return capacity;
  return (capacity * slot / pulses).round().clamp(0, capacity).toInt();
}

double gameOrderBookPriceChangePercent({
  required double price,
  required double previousClose,
}) {
  if (!price.isFinite ||
      price <= 0 ||
      !previousClose.isFinite ||
      previousClose <= 0) {
    return 0;
  }
  return (price - previousClose) / previousClose * 100;
}

double gameOrderBookExecutionStrength({
  required num buyQuantity,
  required num sellQuantity,
}) {
  final buys = buyQuantity.toDouble();
  final sells = sellQuantity.toDouble();
  final safeBuys = buys.isFinite ? math.max(0.0, buys) : 0.0;
  final safeSells = sells.isFinite ? math.max(0.0, sells) : 0.0;
  if (safeSells <= 0) return safeBuys > 0 ? 999.0 : 100.0;
  return safeBuys / safeSells * 100;
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

/// Deterministic market-wide prints assigned to one continuous-session minute.
///
/// The 09:01 bucket intentionally includes the opening accumulation, matching
/// [gameContinuousMinuteVolumes]. Later minutes are true one-minute deltas.
int gameEstimatedContinuousMinuteVolumeUnits({
  required String assetId,
  required int day,
  required int minute,
  required double referencePrice,
  String simulationSeed = '',
  int? sharesOutstanding,
}) {
  if (minute < krxOpenMinute ||
      minute >= krxContinuousEndMinute ||
      assetId.isEmpty ||
      !referencePrice.isFinite ||
      referencePrice <= 0) {
    return 0;
  }
  final fullDayVolume = gameEstimatedFullDayVolumeUnits(
    assetId: assetId,
    day: day,
    referencePrice: referencePrice,
    simulationSeed: simulationSeed,
    sharesOutstanding: sharesOutstanding,
  );
  if (fullDayVolume <= 0) return 0;
  if (minute == krxOpenMinute) {
    return (fullDayVolume * gameTurnoverProgressAtMinute(minute)).round().clamp(
      0,
      fullDayVolume,
    );
  }
  final volumes = gameContinuousMinuteVolumes(
    fullDayVolume: fullDayVolume,
    visibleThroughMinute: minute,
  );
  return volumes.lastOrNull ?? 0;
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
    this.queueRecoveryTargetQuantity = 0,
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

  /// Original ordinary-queue depth still being rebuilt after real consumption.
  /// Intentionally empty price levels and untouched queues keep this at zero.
  final int queueRecoveryTargetQuantity;

  int get confluenceCount =>
      (isPsychological ? 1 : 0) + technicalPeriods.length;
}

class GameOrderBookSnapshot {
  const GameOrderBookSnapshot({
    required this.asks,
    required this.bids,
    required this.turnoverEok,
    this.fullDayTurnoverEok = 0,
    this.boundaryBidPrice,
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
    this.lastSyntheticTrade,
    this.syntheticTradePrints = const <GameOrderBookSyntheticTrade>[],
    this.sweepSteps = const <GameOrderBookSweepStep>[],
    this.syntheticTradeBudgetUsed = 0,
  });

  final List<GameOrderBookLevel> asks;
  final List<GameOrderBookLevel> bids;
  final double turnoverEok;
  final double fullDayTurnoverEok;
  final double? boundaryBidPrice;
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

  /// Last generated market print already removed from standing depth.
  ///
  /// This state is deliberately separate from the ledger consumption
  /// watermarks above. Generated market activity changes the carried book, but
  /// must never masquerade as a player fill when the engine validates a
  /// displayed snapshot against the persisted ledger.
  final GameOrderBookSyntheticTrade? lastSyntheticTrade;

  /// Individual prints for the latest generated execution batch.
  ///
  /// A normal one-price pulse sums to [lastSyntheticTrade] quantity. A
  /// multi-price minute sweep instead preserves every crossed price and sums to
  /// [syntheticTradeBudgetUsed], while [lastSyntheticTrade] remains the final
  /// price-level aggregate.
  final List<GameOrderBookSyntheticTrade> syntheticTradePrints;

  /// Ordered price-level depletion steps for the latest generated sweep.
  ///
  /// The UI may replay these immediately in [GameOrderBookSweepStep.sequence]
  /// order. Every step in one batch shares `(marketMinute, liquidityPulse)`,
  /// while an empty list means this snapshot crossed no standing price level.
  final List<GameOrderBookSweepStep> sweepSteps;

  /// Generated-only quantity consumed during [sourceMarketMinute].
  ///
  /// The UI pulse owner may use this to cap all sub-minute prints to one finite
  /// budget. It is not part of the player's shared execution-capacity
  /// watermark and resets when the builder advances to a new minute.
  final int syntheticTradeBudgetUsed;

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

/// Splits one logical-slot execution into deterministic individual prints.
///
/// The returned quantities sum exactly to [quantity]. About two thirds are
/// deliberately 1-5 share retail lots, while the remainder carries the finite
/// slot flow as irregular medium and tail prints. No value is rounded to a
/// 10-share boundary.
List<int> gameOrderBookSplitTradeQuantity({
  required String assetId,
  required int day,
  required int minute,
  required int liquidityPulse,
  required int quantity,
  int maxPrints = gameOrderBookMaximumSyntheticPrintsPerPulse,
}) {
  final total = math.max(0, quantity).toInt();
  if (total <= 0 || maxPrints <= 0) return const <int>[];
  if (total == 1 || maxPrints == 1) return <int>[total];

  final seededAssetId = assetId.isEmpty ? 'order-book-print' : assetId;
  final desiredCount =
      7 +
      _orderBookMixedHash(
            seededAssetId,
            day,
            minute * 104729 + liquidityPulse * 13007 + 17011,
          ) %
          6;
  final count = math.min(total, math.min(maxPrints, desiredCount));
  if (count <= 1) return <int>[total];

  final smallCount = math.min(count - 1, (count * 0.65).ceil());
  final prints = <int>[];
  var remaining = total;
  for (var index = 0; index < smallCount; index += 1) {
    final remainingSlots = count - index;
    final maximumSmall = math.min(5, remaining - (remainingSlots - 1));
    final draw = _orderBookMixedHash(
      seededAssetId,
      day,
      minute * 32452843 + liquidityPulse * 49999 + index * 7919 + 19001,
    );
    final print = (1 + draw % math.max(1, maximumSmall).toInt()).toInt();
    prints.add(print);
    remaining -= print;
  }

  final tailSlots = count - smallCount;
  final tailTotal = remaining;
  final tailWeights = <int>[
    for (var index = 0; index < tailSlots; index += 1)
      (() {
        final bucket =
            _orderBookMixedHash(
              seededAssetId,
              day,
              minute * 86028121 +
                  liquidityPulse * 65537 +
                  index * 12289 +
                  21001,
            ) %
            1000;
        final baseWeight = 400 + bucket;
        return baseWeight;
      })(),
  ];
  final totalTailWeight = tailWeights.fold<int>(0, (sum, value) => sum + value);
  for (var index = 0; index < tailSlots; index += 1) {
    final remainingSlots = tailSlots - index;
    if (remainingSlots == 1) {
      prints.add(remaining);
      remaining = 0;
      break;
    }
    final reserved = remainingSlots - 1;
    final proportional =
        (tailTotal * tailWeights[index] + totalTailWeight ~/ 2) ~/
        totalTailWeight;
    final print = proportional.clamp(1, remaining - reserved).toInt();
    prints.add(print);
    remaining -= print;
  }

  for (var index = prints.length - 1; index > 0; index -= 1) {
    final swapIndex =
        _orderBookMixedHash(
          seededAssetId,
          day,
          minute * 67867967 + liquidityPulse * 8191 + index * 313 + 23003,
        ) %
        (index + 1);
    final value = prints[index];
    prints[index] = prints[swapIndex];
    prints[swapIndex] = value;
  }
  return List<int>.unmodifiable(prints);
}

class GameOrderBookSyntheticTrade {
  const GameOrderBookSyntheticTrade({
    required this.marketMinute,
    required this.liquidityPulse,
    required this.levelSide,
    required this.price,
    required this.quantity,
    this.sequence = 0,
  });

  /// `(marketMinute, liquidityPulse)` is the aggregate idempotency key.
  final int marketMinute;
  final int liquidityPulse;

  /// Absolute standing-book side and price consumed by this generated print.
  final GameOrderBookSide levelSide;
  final double price;

  /// Actual quantity removed after row availability and minute-budget caps.
  final int quantity;

  /// Stable order inside one logical-slot execution batch.
  final int sequence;
}

class GameOrderBookPriceTransitionFill {
  const GameOrderBookPriceTransitionFill({
    required this.side,
    required this.price,
    required this.quantity,
    required this.remainingQuantity,
    required this.structuralBreach,
    required this.boundaryCrossed,
  });

  final GameOrderBookSide side;
  final double price;
  final int quantity;
  final int remainingQuantity;
  final bool structuralBreach;
  final bool boundaryCrossed;

  int get consumedQuantity => quantity;
}

class GameOrderBookSweepStep {
  const GameOrderBookSweepStep({
    required this.marketMinute,
    required this.liquidityPulse,
    required this.sequence,
    required this.side,
    required this.price,
    required this.consumedQuantity,
    required this.remainingQuantity,
    required this.structuralBreach,
    required this.boundaryCrossed,
  });

  /// `(marketMinute, liquidityPulse)` identifies the complete sweep batch.
  final int marketMinute;
  final int liquidityPulse;
  final int sequence;
  final GameOrderBookSide side;
  final double price;
  final int consumedQuantity;
  final int remainingQuantity;
  final bool structuralBreach;
  final bool boundaryCrossed;
}

class GameOrderBookPriceTransition {
  const GameOrderBookPriceTransition({
    required this.price,
    required this.consumedAskByPrice,
    required this.consumedBidByPrice,
    required this.consumedUnits,
    required this.targetReached,
    this.orderedFills = const <GameOrderBookPriceTransitionFill>[],
    this.lastFillSide,
    this.lastFillPrice,
    this.lastFillQuantity = 0,
  });

  final double price;
  final Map<double, int> consumedAskByPrice;
  final Map<double, int> consumedBidByPrice;
  final int consumedUnits;
  final bool targetReached;
  final List<GameOrderBookPriceTransitionFill> orderedFills;
  final GameOrderBookSide? lastFillSide;
  final double? lastFillPrice;
  final int lastFillQuantity;
}

/// Moves a last-trade price only through standing depth that was actually
/// executed. A partial fill may move the print onto the current best quote,
/// but the next price level remains unreachable until that quote is empty.
GameOrderBookPriceTransition gameOrderBookPriceTransitionTowardTarget({
  required GameOrderBookSnapshot snapshot,
  required double previousPrice,
  required double targetPrice,
  required int availableUnits,
  required String market,
}) {
  final safePrevious = marketSnapPrice(previousPrice, market: market);
  final safeTarget = marketSnapPrice(targetPrice, market: market);
  if (!safePrevious.isFinite ||
      safePrevious <= 0 ||
      !safeTarget.isFinite ||
      safeTarget <= 0 ||
      (safeTarget - safePrevious).abs() < 0.000001) {
    return GameOrderBookPriceTransition(
      price: safeTarget.isFinite && safeTarget > 0 ? safeTarget : safePrevious,
      consumedAskByPrice: const <double, int>{},
      consumedBidByPrice: const <double, int>{},
      consumedUnits: 0,
      targetReached: (safeTarget - safePrevious).abs() < 0.000001,
    );
  }

  final asks = <double, int>{};
  final bids = <double, int>{};
  final orderedFills = <GameOrderBookPriceTransitionFill>[];
  var remaining = math.max(0, availableUnits);
  var reachedPrice = safePrevious;
  GameOrderBookSide? lastFillSide;
  double? lastFillPrice;
  var lastFillQuantity = 0;

  GameOrderBookPriceTransitionFill transitionFill(
    GameOrderBookLevel level,
    int fill,
  ) {
    final remainingQuantity = math.max(0, level.quantity - fill);
    final recoveryBaseline = math.max(
      level.quantity,
      level.queueRecoveryTargetQuantity,
    );
    final structuralBreach =
        !level.isStructuralBreached &&
        _gameOrderBookStructuralQueueBreached(
          level,
          baselineQuantity: recoveryBaseline,
          remainingQuantity: remainingQuantity,
        );
    return GameOrderBookPriceTransitionFill(
      side: level.side,
      price: level.price,
      quantity: fill,
      remainingQuantity: remainingQuantity,
      structuralBreach: structuralBreach,
      boundaryCrossed: remainingQuantity <= 0 || structuralBreach,
    );
  }

  if (safeTarget > safePrevious) {
    for (final level in snapshot.asks) {
      if (level.price > safeTarget + 0.000001) break;
      if (level.price < safePrevious - 0.000001 || level.quantity <= 0) {
        continue;
      }
      if (remaining <= 0) break;
      final fill = math.min(remaining, level.quantity);
      if (fill <= 0) continue;
      asks[level.price] = fill;
      orderedFills.add(transitionFill(level, fill));
      remaining -= fill;
      reachedPrice = level.price;
      lastFillSide = GameOrderBookSide.ask;
      lastFillPrice = level.price;
      lastFillQuantity = fill;
      if (fill < level.quantity) break;
      if ((level.price - safeTarget).abs() < 0.000001) break;
    }
  } else {
    for (final level in snapshot.bids) {
      if (level.price < safeTarget - 0.000001) break;
      if (level.price > safePrevious + 0.000001 || level.quantity <= 0) {
        continue;
      }
      if (remaining <= 0) break;
      final fill = math.min(remaining, level.quantity);
      if (fill <= 0) continue;
      bids[level.price] = fill;
      orderedFills.add(transitionFill(level, fill));
      remaining -= fill;
      reachedPrice = level.price;
      lastFillSide = GameOrderBookSide.bid;
      lastFillPrice = level.price;
      lastFillQuantity = fill;
      if (fill < level.quantity) break;
      if ((level.price - safeTarget).abs() < 0.000001) break;
    }
  }

  final consumedUnits = math.max(0, availableUnits - remaining);
  return GameOrderBookPriceTransition(
    price: reachedPrice,
    consumedAskByPrice: Map<double, int>.unmodifiable(asks),
    consumedBidByPrice: Map<double, int>.unmodifiable(bids),
    consumedUnits: consumedUnits,
    targetReached: (reachedPrice - safeTarget).abs() < 0.000001,
    orderedFills: List<GameOrderBookPriceTransitionFill>.unmodifiable(
      orderedFills,
    ),
    lastFillSide: lastFillSide,
    lastFillPrice: lastFillPrice,
    lastFillQuantity: lastFillQuantity,
  );
}

List<int> _gameOrderBookSplitTradeQuantityExactly({
  required String assetId,
  required int day,
  required int minute,
  required int liquidityPulse,
  required int quantity,
  required int printCount,
}) {
  final total = math.max(0, quantity).toInt();
  final targetCount = math.min(total, math.max(0, printCount)).toInt();
  if (targetCount <= 0) return const <int>[];
  final prints = gameOrderBookSplitTradeQuantity(
    assetId: assetId,
    day: day,
    minute: minute,
    liquidityPulse: liquidityPulse,
    quantity: total,
    maxPrints: targetCount,
  ).toList(growable: true);
  while (prints.length < targetCount) {
    var splitIndex = -1;
    for (var index = 0; index < prints.length; index += 1) {
      if (prints[index] <= 1) continue;
      if (splitIndex < 0 || prints[index] > prints[splitIndex]) {
        splitIndex = index;
      }
    }
    if (splitIndex < 0) break;
    final value = prints.removeAt(splitIndex);
    final draw = _orderBookMixedHash(
      assetId,
      day,
      minute * 15485863 +
          liquidityPulse * 32452843 +
          prints.length * 7919 +
          splitIndex * 313,
    );
    final left = 1 + draw % (value - 1);
    prints.insert(splitIndex, value - left);
    prints.insert(splitIndex, left);
  }
  return List<int>.unmodifiable(prints);
}

List<GameOrderBookSyntheticTrade> _gameOrderBookTransitionPrints({
  required GameOrderBookPriceTransition transition,
  required String assetId,
  required int day,
  required int minute,
  required int liquidityPulse,
}) {
  final fills = transition.orderedFills
      .where((fill) => fill.quantity > 0)
      .toList(growable: false);
  if (fills.isEmpty) return const <GameOrderBookSyntheticTrade>[];
  final total = fills.fold<int>(0, (sum, fill) => sum + fill.quantity);
  final ordinaryBatchCount = gameOrderBookSplitTradeQuantity(
    assetId: assetId,
    day: day,
    minute: minute,
    liquidityPulse: liquidityPulse,
    quantity: total,
  ).length;
  // Every crossed price needs at least one tape print. Operational 10-level
  // sweeps therefore retain the ordinary 7-12 print batch size; an unusually
  // deep reserve sweep may exceed it rather than hiding a real price fill.
  final targetCount = math.max(fills.length, ordinaryBatchCount).toInt();
  final counts = List<int>.filled(fills.length, 1);
  var remainingPrints = targetCount - fills.length;
  while (remainingPrints > 0) {
    var selected = -1;
    var selectedScore = -1.0;
    for (var index = 0; index < fills.length; index += 1) {
      if (counts[index] >= fills[index].quantity) continue;
      final score = fills[index].quantity / (counts[index] + 1);
      if (score > selectedScore) {
        selected = index;
        selectedScore = score;
      }
    }
    if (selected < 0) break;
    counts[selected] += 1;
    remainingPrints -= 1;
  }

  final prints = <GameOrderBookSyntheticTrade>[];
  for (var fillIndex = 0; fillIndex < fills.length; fillIndex += 1) {
    final fill = fills[fillIndex];
    final quantities = _gameOrderBookSplitTradeQuantityExactly(
      assetId:
          '$assetId:${fill.side.name}:'
          '${fill.price.toStringAsFixed(6)}:$fillIndex',
      day: day,
      minute: minute,
      liquidityPulse: liquidityPulse,
      quantity: fill.quantity,
      printCount: counts[fillIndex],
    );
    for (final quantity in quantities) {
      prints.add(
        GameOrderBookSyntheticTrade(
          marketMinute: minute,
          liquidityPulse: liquidityPulse,
          levelSide: fill.side,
          price: fill.price,
          quantity: quantity,
          sequence: prints.length,
        ),
      );
    }
  }
  return List<GameOrderBookSyntheticTrade>.unmodifiable(prints);
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
  final stableReference = previousClose.isFinite && previousClose > 0
      ? previousClose
      : unitPrice;
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
  var cappedMaximum = maximum;
  // Listed assets always carry a positive share count. Keep the deterministic
  // fallback capped too so legacy/null fixtures cannot exceed that minute's
  // generated tape volume.
  final actualMinuteVolume = gameEstimatedContinuousMinuteVolumeUnits(
    assetId: assetId,
    day: day,
    minute: minute,
    referencePrice: stableReference,
    simulationSeed: simulationSeed,
    sharesOutstanding: sharesOutstanding,
  );
  if (actualMinuteVolume > 0) {
    cappedMaximum = math.min(cappedMaximum, actualMinuteVolume);
  }
  return math.min(rawUnits.round(), cappedMaximum);
}

/// Temporary price pressure caused by a player's unusually large fill.
///
/// Small retail-sized prints do not rewrite the deterministic path. A fill
/// that consumes at least 8% of the minute capacity moves the following quote
/// by 1-6 ticks, depending on participation.
int gamePlayerMarketImpactInitialTicks({
  required double filledQuantity,
  required int executionCapacity,
}) {
  if (!filledQuantity.isFinite ||
      filledQuantity <= 0 ||
      executionCapacity <= 0) {
    return 0;
  }
  final participation = (filledQuantity / executionCapacity)
      .clamp(0.0, 1.0)
      .toDouble();
  if (participation < 0.08) return 0;
  final scaled = ((participation - 0.08) / 0.92).clamp(0.0, 1.0).toDouble();
  return (1 + (scaled * 5).round()).clamp(1, 6);
}

int gamePlayerMarketImpactTicksAtAge({
  required int initialTicks,
  required int ageMinutes,
}) {
  if (initialTicks <= 0 ||
      ageMinutes <= 0 ||
      ageMinutes > gamePlayerMarketImpactDurationMinutes) {
    return 0;
  }
  final remaining = gamePlayerMarketImpactDurationMinutes - ageMinutes + 1;
  return math.max(
    1,
    (initialTicks * remaining / gamePlayerMarketImpactDurationMinutes).ceil(),
  );
}

double gameOrderBookPriceAfterTickImpact({
  required double basePrice,
  required int signedTicks,
  String market = '미래시장',
}) {
  if (!basePrice.isFinite || basePrice <= 0 || signedTicks == 0) {
    return basePrice;
  }
  var price = marketSnapPrice(basePrice, market: market);
  final direction = signedTicks.isNegative ? -1 : 1;
  for (var index = 0; index < signedTicks.abs(); index += 1) {
    final tick = direction > 0
        ? marketTickSize(price, market: market)
        : marketTickSize(math.max(0.000001, price - 0.000001), market: market);
    final next = marketSnapPrice(price + direction * tick, market: market);
    if (next <= 0 || (next - price).abs() < 0.000001) break;
    price = next;
  }
  return price;
}

/// 최근 체결이 어느 호가를 소화했는지 표시할 이동 네모를 만든다.
///
/// 가격 상승은 매수자가 매도호가를 먹은 체결, 가격 하락은 매도자가
/// 매수호가를 먹은 체결로 본다. 보합의 기본 방향은 분 단위로 결정하되
/// 개별 펄스는 아래에서 매수·매도 쌍으로 나눠 한쪽 고정을 막는다.
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
  final flow = _orderBookUnit(seededAssetId, day, minute * 7919 + 2203);
  return flow < 0.5 ? GameOrderBookSide.ask : GameOrderBookSide.bid;
}

GameOrderBookSide _gameOrderBookBoundarySide({
  required String seededAssetId,
  required int day,
  required int minute,
  required double previousPrice,
  required double currentPrice,
}) {
  final delta = currentPrice - previousPrice;
  if (delta > 0) return GameOrderBookSide.ask;
  if (delta < 0) return GameOrderBookSide.bid;
  final flowBucket = minute ~/ _gameOrderBookFlatBoundaryHoldMinutes;
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
  int pulsesPerMarketMinute = 0,
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
    // trade. Directional moves retain that bias, while flat prints are paired
    // into one buy and one sell in a seeded order so a sideways tape cannot
    // remain red or blue for minutes at a time.
    final directional = (currentPrice - previousPrice).abs() > 0.000001;
    if (!directional) {
      final pulses = math.max(1, pulsesPerMarketMinute);
      final localSlot = pulsesPerMarketMinute > 0
          ? gameOrderBookPulseSlotForFrame(
              marketMinute: minute,
              liquidityPulse: liquidityPulse,
            )
          : liquidityPulse;
      final sequence = minute * pulses + localSlot;
      final askFirst = _orderBookMixedHash(
        seededAssetId,
        day,
        (sequence ~/ 2) * 104729 + 7919,
      ).isEven;
      side = sequence.isEven == askFirst
          ? GameOrderBookSide.ask
          : GameOrderBookSide.bid;
    } else {
      final dominantProbability = 0.65 + moveIntensity * 0.20;
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
  }
  final participation = liquidityPulse <= 0
      ? (0.08 +
                (hash % 25) / 100 +
                moveIntensity *
                    (0.38 +
                        _orderBookUnit(seededAssetId, day, minute * 89 + 4099) *
                            0.24))
            .clamp(0.08, 0.92)
            .toDouble()
      : pulsesPerMarketMinute > 0
      ? (() {
          // Spread the finite minute-wide flow over deterministic logical
          // slots. Rendering may skip frames, but catch-up reaches the same
          // slot state without spending the budget early.
          final expectedPulses = math.max(1, pulsesPerMarketMinute);
          final jitter =
              0.72 +
              _orderBookUnit(
                    seededAssetId,
                    day,
                    minute * 89 + liquidityPulse * 313 + 4099,
                  ) *
                  0.56;
          return ((1 / expectedPulses) * jitter * (1 + moveIntensity * 0.28))
              .clamp(0.0001, 0.24)
              .toDouble();
        })()
      : (0.015 +
                (hash % 36) / 1000 +
                moveIntensity *
                    (0.02 +
                        _orderBookUnit(
                              seededAssetId,
                              day,
                              minute * 89 + liquidityPulse * 313 + 4099,
                            ) *
                            0.025))
            .clamp(0.015, 0.08)
            .toDouble();
  final quantity = math.max(1, (executionCapacity * participation).round());
  return GameOrderBookTradePulse(
    levelSide: side,
    levelIndex: index,
    quantity: quantity,
    crossedTicks: crossedTicks,
  );
}

/// Returns the nearest standing row that an aggressor on [side] can consume.
///
/// A partially consumed best row remains the target until its quantity reaches
/// zero. Only then may a same-side print advance to the next price. Callers may
/// still request the opposite side independently, which models the normal
/// last-trade-price bounce between the best ask and best bid.
GameOrderBookLevel? gameOrderBookFirstExecutableLevel({
  required GameOrderBookSnapshot snapshot,
  required GameOrderBookSide side,
}) {
  final levels = side == GameOrderBookSide.ask ? snapshot.asks : snapshot.bids;
  for (final level in levels) {
    if (level.quantity > 0) return level;
  }
  return null;
}

GameOrderBookLevel _gameOrderBookLevelWithQuantity(
  GameOrderBookLevel level,
  int quantity, {
  int? queueRecoveryTargetQuantity,
  bool? isWall,
  bool? isStructuralWall,
  bool? isStructuralBreached,
  double? structuralVacuumMultiplier,
}) {
  return GameOrderBookLevel(
    side: level.side,
    price: level.price,
    quantity: math.max(0, quantity),
    isWall: isWall ?? level.isWall,
    structuralKind: level.structuralKind,
    structuralStrength: level.structuralStrength,
    structuralHoldTicks: level.structuralHoldTicks,
    isStructuralWall: isStructuralWall ?? level.isStructuralWall,
    isStructuralBreached: isStructuralBreached ?? level.isStructuralBreached,
    structuralVacuumMultiplier:
        structuralVacuumMultiplier ?? level.structuralVacuumMultiplier,
    isPsychological: level.isPsychological,
    technicalPeriods: level.technicalPeriods,
    wasLiquidityPulseTouched: level.wasLiquidityPulseTouched,
    queueRecoveryTargetQuantity:
        queueRecoveryTargetQuantity ?? level.queueRecoveryTargetQuantity,
  );
}

int _gameOrderBookStructuralRecoveryCeiling(
  GameOrderBookLevel level, {
  required int baselineQuantity,
}) {
  final ordinaryDepth =
      baselineQuantity / math.max(1.0, level.structuralStrength);
  return math.max(gameOrderBookMinimumDisplayedQuantity, ordinaryDepth.round());
}

bool _gameOrderBookStructuralQueueBreached(
  GameOrderBookLevel level, {
  required int baselineQuantity,
  required int remainingQuantity,
}) {
  if (level.isStructuralBreached) return true;
  if (!level.isStructuralWall || baselineQuantity <= 0) return false;
  final consumedRatio =
      (baselineQuantity - math.max(0, remainingQuantity)) / baselineQuantity;
  return consumedRatio + 0.000001 >=
      gameOrderBookStructuralConsumptionBreachRatio;
}

/// Removes one generated market print from an exact absolute-price row.
///
/// The caller owns pulse scheduling. [buildGameOrderBookSnapshot] never calls
/// this helper automatically, so engine/fallback builders cannot invent an
/// extra print. Reapplying the same `(market minute, liquidity pulse)` returns
/// [snapshot] unchanged.
///
/// [perMinuteBudgetUnits] is a generated-only display-flow budget. It defaults
/// to the snapshot's execution capacity, but does not consume or alter the
/// player's ledger-backed capacity watermark.
///
/// [snapshot] is the standing book currently shown to the player, so every
/// print subtracts from that exact queue. [previousSnapshot] may only cap that
/// quantity when the current builder proposed a same-frame arrival; it can
/// never raise the current quantity or resurrect a wall that was cancelled or
/// reduced. [availableSnapshot] is the ledger-net view used to cap the print.
GameOrderBookSnapshot gameOrderBookSnapshotAfterSyntheticTrade({
  required GameOrderBookSnapshot snapshot,
  required GameOrderBookTradePulse pulse,
  required double absolutePrice,
  GameOrderBookSnapshot? previousSnapshot,
  GameOrderBookSnapshot? availableSnapshot,
  int? perMinuteBudgetUnits,
}) {
  GameOrderBookLevel? sameSideAbsoluteLevel(
    GameOrderBookSnapshot source,
    GameOrderBookSide side,
    double price,
  ) {
    final levels = side == GameOrderBookSide.ask ? source.asks : source.bids;
    for (final level in levels) {
      if ((level.price - price).abs() < 0.000001) return level;
    }
    final exact = source.rememberedLevels[price];
    if (exact != null && exact.side == side) return exact;
    for (final entry in source.rememberedLevels.entries) {
      if ((entry.key - price).abs() < 0.000001 && entry.value.side == side) {
        return entry.value;
      }
    }
    return null;
  }

  final marketMinute = snapshot.sourceMarketMinute;
  if (marketMinute == null || !absolutePrice.isFinite || absolutePrice <= 0) {
    return snapshot;
  }
  final liquidityPulse = snapshot.liquidityPulse;
  final previousTrade = snapshot.lastSyntheticTrade;
  if (previousTrade != null &&
      previousTrade.marketMinute == marketMinute &&
      previousTrade.liquidityPulse == liquidityPulse) {
    return snapshot;
  }

  final sourceLevels = pulse.levelSide == GameOrderBookSide.ask
      ? snapshot.asks
      : snapshot.bids;
  final targetIndex = sourceLevels.indexWhere(
    (level) => (level.price - absolutePrice).abs() < 0.000001,
  );
  if (targetIndex < 0) return snapshot;
  final target = sourceLevels[targetIndex];
  final previousSameSideTarget = previousSnapshot == null
      ? null
      : sameSideAbsoluteLevel(previousSnapshot, pulse.levelSide, target.price);
  var rawQuantity = math.max(0, target.quantity);
  if (previousSameSideTarget != null && previousSameSideTarget.quantity > 0) {
    // A generated arrival and a print may share one UI frame. Do not let that
    // unseen arrival refill the row under the print, but also never use an
    // older, larger queue as the subtraction base.
    rawQuantity = math.min(rawQuantity, previousSameSideTarget.quantity);
  }
  if (target.isStructuralBreached ||
      target.structuralVacuumMultiplier < 0.999999) {
    // A breached support/resistance zone must remain depleted. The raw carry
    // source can predate the breach, so using it without this clamp would
    // resurrect the old wall before subtracting the current print.
    rawQuantity = math.min(rawQuantity, target.quantity);
  }
  final netAvailableTarget = availableSnapshot == null
      ? target
      : sameSideAbsoluteLevel(availableSnapshot, pulse.levelSide, target.price);
  final netAvailableQuantity = math.max(0, netAvailableTarget?.quantity ?? 0);
  final sameBudgetMinute = previousTrade?.marketMinute == marketMinute;
  final used = sameBudgetMinute
      ? math.max(0, snapshot.syntheticTradeBudgetUsed)
      : 0;
  final budget = math.max(
    0,
    perMinuteBudgetUnits ?? snapshot.executionCapacity,
  );
  final remainingBudget = math.max(0, budget - used);
  final actualQuantity = math.min(
    math.max(0, pulse.quantity),
    math.min(rawQuantity, math.min(netAvailableQuantity, remainingBudget)),
  );
  final rawRemainingQuantity = rawQuantity - actualQuantity;
  // Generated queues smaller than the UI's practical minimum are treated as
  // an immediate cancellation of the tiny residual, not exposed as a fake
  // 1-share "wall". The executed quantity and budget still contain only the
  // shares that actually traded.
  final remainingQuantity =
      actualQuantity > 0 &&
          rawRemainingQuantity > 0 &&
          rawRemainingQuantity < gameOrderBookMinimumDisplayedQuantity
      ? 0
      : rawRemainingQuantity;
  final recoveryBaseline = math.max(
    rawQuantity,
    target.queueRecoveryTargetQuantity,
  );
  final structuralQueueBreached = _gameOrderBookStructuralQueueBreached(
    target,
    baselineQuantity: recoveryBaseline,
    remainingQuantity: remainingQuantity,
  );
  final structuralBreach =
      !target.isStructuralBreached && structuralQueueBreached;
  final recoveryCeiling = structuralQueueBreached
      ? _gameOrderBookStructuralRecoveryCeiling(
          target,
          baselineQuantity: recoveryBaseline,
        )
      : 0;
  final ordinaryRecoveryTarget = actualQuantity <= 0
      ? target.queueRecoveryTargetQuantity
      : math.max(target.queueRecoveryTargetQuantity, rawQuantity);
  final recoveryTarget = structuralQueueBreached
      ? remainingQuantity > 0 && remainingQuantity < recoveryCeiling
            ? recoveryCeiling
            : 0
      : ordinaryRecoveryTarget;
  final updatedTarget = _gameOrderBookLevelWithQuantity(
    target,
    remainingQuantity,
    queueRecoveryTargetQuantity: recoveryTarget,
    isWall: structuralQueueBreached ? false : null,
    isStructuralWall: structuralQueueBreached ? false : null,
    isStructuralBreached: structuralQueueBreached ? true : null,
    structuralVacuumMultiplier: structuralQueueBreached
        ? math.min(target.structuralVacuumMultiplier, 0.65)
        : null,
  );
  final promotedTouch = _gameOrderBookPromotedTouchArrival(
    snapshot: snapshot,
    target: updatedTarget,
    remainingQuantity: remainingQuantity,
    actualQuantity: actualQuantity,
  );

  final asks = pulse.levelSide == GameOrderBookSide.ask
      ? <GameOrderBookLevel>[
          for (var index = 0; index < snapshot.asks.length; index += 1)
            if (index != targetIndex || promotedTouch == null)
              index == targetIndex ? updatedTarget : snapshot.asks[index],
        ]
      : promotedTouch == null
      ? snapshot.asks
      : <GameOrderBookLevel>[
          promotedTouch,
          ...snapshot.asks.where(
            (level) => (level.price - promotedTouch.price).abs() >= 0.000001,
          ),
        ];
  final bids = pulse.levelSide == GameOrderBookSide.bid
      ? <GameOrderBookLevel>[
          for (var index = 0; index < snapshot.bids.length; index += 1)
            if (index != targetIndex || promotedTouch == null)
              index == targetIndex ? updatedTarget : snapshot.bids[index],
        ]
      : promotedTouch == null
      ? snapshot.bids
      : <GameOrderBookLevel>[
          promotedTouch,
          ...snapshot.bids.where(
            (level) => (level.price - promotedTouch.price).abs() >= 0.000001,
          ),
        ];
  final totalAsk = asks.fold<int>(0, (sum, level) => sum + level.quantity);
  final totalBid = bids.fold<int>(0, (sum, level) => sum + level.quantity);
  final rememberedLevels = <double, GameOrderBookLevel>{
    ...snapshot.rememberedLevels,
    updatedTarget.price: promotedTouch ?? updatedTarget,
  };
  final syntheticTrade = GameOrderBookSyntheticTrade(
    marketMinute: marketMinute,
    liquidityPulse: liquidityPulse,
    levelSide: pulse.levelSide,
    price: updatedTarget.price,
    quantity: actualQuantity,
  );
  final syntheticTradePrints = <GameOrderBookSyntheticTrade>[
    for (final entry in gameOrderBookSplitTradeQuantity(
      assetId:
          '${snapshot.sourceSimulationSeed ?? ''}:'
          '${snapshot.sourceAssetId ?? 'order-book'}',
      day: snapshot.sourceLiquidityDayKey ?? 0,
      minute: marketMinute,
      liquidityPulse: liquidityPulse,
      quantity: actualQuantity,
    ).asMap().entries)
      GameOrderBookSyntheticTrade(
        marketMinute: marketMinute,
        liquidityPulse: liquidityPulse,
        levelSide: pulse.levelSide,
        price: updatedTarget.price,
        quantity: entry.value,
        sequence: entry.key,
      ),
  ];
  final boundaryBidPrice = promotedTouch == null
      ? snapshot.boundaryBidPrice
      : bids.where((level) => level.quantity > 0).firstOrNull?.price ??
            snapshot.boundaryBidPrice;

  return GameOrderBookSnapshot(
    asks: List<GameOrderBookLevel>.unmodifiable(asks),
    bids: List<GameOrderBookLevel>.unmodifiable(bids),
    turnoverEok: snapshot.turnoverEok,
    fullDayTurnoverEok: snapshot.fullDayTurnoverEok,
    boundaryBidPrice: boundaryBidPrice,
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
    sourceLastTradePrice: actualQuantity > 0
        ? updatedTarget.price
        : snapshot.sourceLastTradePrice,
    sourceMarket: snapshot.sourceMarket,
    sourceSimulationSeed: snapshot.sourceSimulationSeed,
    appliedAskConsumptionByPrice: snapshot.appliedAskConsumptionByPrice,
    appliedBidConsumptionByPrice: snapshot.appliedBidConsumptionByPrice,
    appliedCapacityConsumptionUnits: snapshot.appliedCapacityConsumptionUnits,
    lastSyntheticTrade: syntheticTrade,
    syntheticTradePrints: List<GameOrderBookSyntheticTrade>.unmodifiable(
      syntheticTradePrints,
    ),
    sweepSteps: actualQuantity <= 0
        ? const <GameOrderBookSweepStep>[]
        : List<GameOrderBookSweepStep>.unmodifiable(<GameOrderBookSweepStep>[
            GameOrderBookSweepStep(
              marketMinute: marketMinute,
              liquidityPulse: liquidityPulse,
              sequence: 0,
              side: pulse.levelSide,
              price: updatedTarget.price,
              consumedQuantity: actualQuantity,
              remainingQuantity: remainingQuantity,
              structuralBreach: structuralBreach,
              boundaryCrossed: remainingQuantity <= 0 || structuralBreach,
            ),
          ]),
    syntheticTradeBudgetUsed: used + actualQuantity,
  );
}

GameOrderBookLevel? _gameOrderBookPromotedTouchArrival({
  required GameOrderBookSnapshot snapshot,
  required GameOrderBookLevel target,
  required int remainingQuantity,
  required int actualQuantity,
}) {
  if (actualQuantity <= 0 || remainingQuantity > 0) {
    return null;
  }
  final sameSideLevels = target.side == GameOrderBookSide.ask
      ? snapshot.asks
      : snapshot.bids;
  final sameSideTouch = sameSideLevels
      .where((level) => level.quantity > 0)
      .firstOrNull;
  if (sameSideTouch == null ||
      (sameSideTouch.price - target.price).abs() >= 0.000001) {
    return null;
  }
  return _gameOrderBookOppositeQueueAfterTouchConsumption(
    snapshot: snapshot,
    target: target,
  );
}

GameOrderBookLevel? _gameOrderBookOppositeQueueAfterTouchConsumption({
  required GameOrderBookSnapshot snapshot,
  required GameOrderBookLevel target,
}) {
  if (snapshot.fullDayTurnoverEok <
      gameOrderBookSeverelySparseFullDayTurnoverEok) {
    return null;
  }
  final oppositeLevels = target.side == GameOrderBookSide.ask
      ? snapshot.bids
      : snapshot.asks;
  final oppositeTouch = oppositeLevels
      .where((level) => level.quantity > 0)
      .firstOrNull;
  if (oppositeTouch == null) return null;
  final targetIsBeyondOppositeTouch = target.side == GameOrderBookSide.ask
      ? target.price > oppositeTouch.price
      : target.price < oppositeTouch.price;
  if (!targetIsBeyondOppositeTouch) {
    return null;
  }

  // The consumed wall stays gone. A full ask print moves that absolute price
  // to a fresh bid; a full bid print moves it to a fresh ask. This advances the
  // spread boundary without converting or resurrecting the old standing wall.
  // Do not require the old spread to have been exactly one tick: this reducer
  // must also repair a legacy/sparse snapshot whose hidden zero rows left a
  // wide visible gap (for example 32,150 bid / 32,500 ask).
  // The new ordinary queue must be usable depth, never the visible 1-share
  // artifact produced by the former minimum fallback.
  final originalTarget =
      (target.side == GameOrderBookSide.ask ? snapshot.asks : snapshot.bids)
          .where((level) => (level.price - target.price).abs() < 0.000001)
          .firstOrNull;
  final structuralQueueBreached =
      target.isStructuralBreached ||
      (originalTarget?.isStructuralWall ?? false);
  final recoveryBaseline = math.max(
    target.queueRecoveryTargetQuantity,
    math.max(target.quantity, originalTarget?.quantity ?? 0),
  );
  final structuralRecoveryCeiling = structuralQueueBreached
      ? _gameOrderBookStructuralRecoveryCeiling(
          originalTarget ?? target,
          baselineQuantity: recoveryBaseline,
        )
      : recoveryBaseline;
  final seededAssetId =
      '${snapshot.sourceSimulationSeed ?? ''}:'
      '${snapshot.sourceAssetId ?? 'order-book'}';
  final day = snapshot.sourceLiquidityDayKey ?? 0;
  final priceSalt =
      target.price.round() * 97 +
      (target.side == GameOrderBookSide.ask ? 1907 : 3529);
  final targetVariation =
      0.84 + _orderBookUnit(seededAssetId, day, priceSalt) * 0.32;
  final initialShare =
      0.16 + _orderBookUnit(seededAssetId, day, priceSalt + 811) * 0.12;
  final ordinaryReference = structuralQueueBreached
      ? math.max(
          structuralRecoveryCeiling,
          math.max(
            (oppositeTouch.quantity * 0.35).round(),
            (snapshot.executionCapacity * 0.18).round(),
          ),
        )
      : math.max(
          recoveryBaseline,
          math.max(
            (oppositeTouch.quantity * 0.55).round(),
            (snapshot.executionCapacity * 0.35).round(),
          ),
        );
  final unboundedRecoveryTarget = math.max(
    gameOrderBookMinimumDisplayedQuantity * 2,
    (math.max(1, ordinaryReference) * targetVariation).round(),
  );
  final recoveryTarget = structuralQueueBreached
      ? math.max(
          gameOrderBookMinimumDisplayedQuantity * 2,
          math.min(structuralRecoveryCeiling, unboundedRecoveryTarget),
        )
      : unboundedRecoveryTarget;
  var practicalQuantity = math.max(
    gameOrderBookMinimumDisplayedQuantity,
    math.max(
      (recoveryTarget * initialShare).round(),
      (math.max(1, snapshot.executionCapacity) * 0.05).round(),
    ),
  );
  practicalQuantity = math.min(practicalQuantity, recoveryTarget);
  if (practicalQuantity >= recoveryTarget &&
      recoveryTarget > gameOrderBookMinimumDisplayedQuantity) {
    practicalQuantity = math.max(
      gameOrderBookMinimumDisplayedQuantity,
      recoveryTarget - 1,
    );
  }
  return GameOrderBookLevel(
    side: target.side == GameOrderBookSide.ask
        ? GameOrderBookSide.bid
        : GameOrderBookSide.ask,
    price: target.price,
    quantity: practicalQuantity,
    isWall: false,
    structuralKind: target.structuralKind,
    structuralStrength: 1,
    structuralHoldTicks: 0,
    isStructuralWall: false,
    isStructuralBreached: structuralQueueBreached,
    structuralVacuumMultiplier: structuralQueueBreached
        ? math.min(target.structuralVacuumMultiplier, 0.65)
        : target.structuralVacuumMultiplier,
    isPsychological: target.isPsychological,
    technicalPeriods: target.technicalPeriods,
    wasLiquidityPulseTouched: true,
    queueRecoveryTargetQuantity: recoveryTarget > practicalQuantity
        ? recoveryTarget
        : 0,
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

/// Returns an execution/presentation view after applying absolute-price fills.
/// Depleted rows are omitted unless one exact active trade tombstone is
/// explicitly retained for a non-live diagnostic caller.
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
  GameOrderBookSide? latestConsumedSide,
  double? latestConsumedPrice,
  bool retainSyntheticTombstone = false,
}) {
  double quantityAtPrice(Map<double, double> quantities, double price) {
    final exact = quantities[price];
    if (exact != null) return exact;
    for (final entry in quantities.entries) {
      if ((entry.key - price).abs() < 0.000001) return entry.value;
    }
    return 0;
  }

  int newlyUsedAtPrice(
    GameOrderBookLevel level,
    Map<double, double> consumed,
    Map<double, double> applied,
  ) {
    final cumulative = quantityAtPrice(consumed, level.price);
    final alreadyApplied = quantityAtPrice(applied, level.price);
    final cumulativeWholeUnits = math
        .max(0.0, cumulative.isFinite ? cumulative : 0.0)
        .floor();
    final alreadyAppliedWholeUnits = math
        .max(0.0, alreadyApplied.isFinite ? alreadyApplied : 0.0)
        .floor();
    return math.max(0, cumulativeWholeUnits - alreadyAppliedWholeUnits);
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
    final used = newlyUsedAtPrice(level, consumed, applied);
    final remaining = level.quantity - used;
    final displayedRemaining =
        used > 0 &&
            remaining > 0 &&
            remaining < gameOrderBookMinimumDisplayedQuantity
        ? 0
        : remaining;
    final recoveryBaseline = math.max(
      level.queueRecoveryTargetQuantity,
      level.quantity,
    );
    final structuralQueueBreached =
        level.isStructuralBreached ||
        (used > 0 &&
            _gameOrderBookStructuralQueueBreached(
              level,
              baselineQuantity: recoveryBaseline,
              remainingQuantity: math.max(0, displayedRemaining),
            ));
    final ordinaryRecoveryTarget = used <= 0
        ? level.queueRecoveryTargetQuantity
        : math.max(level.queueRecoveryTargetQuantity, level.quantity);
    final recoveryCeiling = structuralQueueBreached
        ? _gameOrderBookStructuralRecoveryCeiling(
            level,
            baselineQuantity: recoveryBaseline,
          )
        : 0;
    final queueRecoveryTargetQuantity = structuralQueueBreached
        ? math.max(0, displayedRemaining) < recoveryCeiling
              ? math.min(ordinaryRecoveryTarget, recoveryCeiling)
              : 0
        : ordinaryRecoveryTarget;
    return GameOrderBookLevel(
      side: level.side,
      price: level.price,
      quantity: math.max(0, displayedRemaining),
      isWall: structuralQueueBreached ? false : level.isWall,
      structuralKind: level.structuralKind,
      structuralStrength: level.structuralStrength,
      structuralHoldTicks: level.structuralHoldTicks,
      isStructuralWall: structuralQueueBreached
          ? false
          : level.isStructuralWall,
      isStructuralBreached: structuralQueueBreached,
      structuralVacuumMultiplier: structuralQueueBreached
          ? math.min(level.structuralVacuumMultiplier, 0.65)
          : level.structuralVacuumMultiplier,
      isPsychological: level.isPsychological,
      technicalPeriods: level.technicalPeriods,
      wasLiquidityPulseTouched: level.wasLiquidityPulseTouched,
      queueRecoveryTargetQuantity: queueRecoveryTargetQuantity,
    );
  }

  List<GameOrderBookLevel> exhaustedTouchPrefix(
    List<GameOrderBookLevel> original,
    List<GameOrderBookLevel> net,
    Map<double, double> consumed,
    Map<double, double> applied,
  ) {
    final exhausted = <GameOrderBookLevel>[];
    for (var index = 0; index < original.length; index += 1) {
      final used = newlyUsedAtPrice(original[index], consumed, applied);
      if (used <= 0 || net[index].quantity > 0) break;
      exhausted.add(net[index]);
    }
    return exhausted;
  }

  bool keepsActiveSyntheticTombstone(GameOrderBookLevel level) {
    final trade = snapshot.lastSyntheticTrade;
    return retainSyntheticTombstone &&
        level.quantity <= 0 &&
        trade != null &&
        trade.quantity > 0 &&
        trade.marketMinute == snapshot.sourceMarketMinute &&
        trade.liquidityPulse == snapshot.liquidityPulse &&
        trade.levelSide == level.side &&
        (trade.price - level.price).abs() < 0.000001;
  }

  final netAskLevels = snapshot.asks
      .map(
        (level) => netLevel(
          level,
          consumedAskByPrice,
          snapshot.appliedAskConsumptionByPrice,
        ),
      )
      .toList(growable: false);
  final netBidLevels = snapshot.bids
      .map(
        (level) => netLevel(
          level,
          consumedBidByPrice,
          snapshot.appliedBidConsumptionByPrice,
        ),
      )
      .toList(growable: false);
  final exhaustedAsks = exhaustedTouchPrefix(
    snapshot.asks,
    netAskLevels,
    consumedAskByPrice,
    snapshot.appliedAskConsumptionByPrice,
  );
  final exhaustedBids = exhaustedTouchPrefix(
    snapshot.bids,
    netBidLevels,
    consumedBidByPrice,
    snapshot.appliedBidConsumptionByPrice,
  );
  final hasNewAskConsumption = snapshot.asks.any(
    (level) =>
        newlyUsedAtPrice(
          level,
          consumedAskByPrice,
          snapshot.appliedAskConsumptionByPrice,
        ) >
        0,
  );
  final hasNewBidConsumption = snapshot.bids.any(
    (level) =>
        newlyUsedAtPrice(
          level,
          consumedBidByPrice,
          snapshot.appliedBidConsumptionByPrice,
        ) >
        0,
  );
  final selectedConsumedSide =
      latestConsumedSide == GameOrderBookSide.ask && hasNewAskConsumption
      ? GameOrderBookSide.ask
      : latestConsumedSide == GameOrderBookSide.bid && hasNewBidConsumption
      ? GameOrderBookSide.bid
      : null;
  final promotionTarget = selectedConsumedSide == GameOrderBookSide.ask
      ? exhaustedAsks.lastOrNull
      : selectedConsumedSide == GameOrderBookSide.bid
      ? exhaustedBids.lastOrNull
      : null;
  final promotedTouch = promotionTarget == null
      ? null
      : _gameOrderBookOppositeQueueAfterTouchConsumption(
          snapshot: snapshot,
          target: promotionTarget,
        );

  var asks = netAskLevels
      .where(
        (level) => level.quantity > 0 || keepsActiveSyntheticTombstone(level),
      )
      .toList(growable: false);
  var bids = netBidLevels
      .where(
        (level) => level.quantity > 0 || keepsActiveSyntheticTombstone(level),
      )
      .toList(growable: false);
  if (promotedTouch != null && promotedTouch.side == GameOrderBookSide.bid) {
    asks = asks
        .where((level) => (level.price - promotedTouch.price).abs() >= 0.000001)
        .toList(growable: false);
    bids = <GameOrderBookLevel>[
      promotedTouch,
      ...bids.where(
        (level) => (level.price - promotedTouch.price).abs() >= 0.000001,
      ),
    ];
  } else if (promotedTouch != null) {
    bids = bids
        .where((level) => (level.price - promotedTouch.price).abs() >= 0.000001)
        .toList(growable: false);
    asks = <GameOrderBookLevel>[
      promotedTouch,
      ...asks.where(
        (level) => (level.price - promotedTouch.price).abs() >= 0.000001,
      ),
    ];
  }
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
  if (promotedTouch != null) {
    rememberedLevels[promotedTouch.price] = promotedTouch;
  }
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
  final boundaryBidPrice = promotedTouch?.side == GameOrderBookSide.bid
      ? promotedTouch!.price
      : promotedTouch?.side == GameOrderBookSide.ask
      ? bids.where((level) => level.quantity > 0).firstOrNull?.price ??
            snapshot.boundaryBidPrice
      : snapshot.boundaryBidPrice == null
      ? null
      : bids.where((level) => level.quantity > 0).firstOrNull?.price ??
            snapshot.boundaryBidPrice;
  final hasValidLatestConsumedPrice =
      latestConsumedPrice != null &&
      latestConsumedPrice.isFinite &&
      latestConsumedPrice > 0;
  final sourceLastTradePrice =
      selectedConsumedSide != null && hasValidLatestConsumedPrice
      ? latestConsumedPrice
      : promotionTarget?.price ?? snapshot.sourceLastTradePrice;
  return GameOrderBookSnapshot(
    asks: List<GameOrderBookLevel>.unmodifiable(asks),
    bids: List<GameOrderBookLevel>.unmodifiable(bids),
    turnoverEok: snapshot.turnoverEok,
    fullDayTurnoverEok: snapshot.fullDayTurnoverEok,
    boundaryBidPrice: boundaryBidPrice,
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
    sourceLastTradePrice: sourceLastTradePrice,
    sourceMarket: snapshot.sourceMarket,
    sourceSimulationSeed: snapshot.sourceSimulationSeed,
    appliedAskConsumptionByPrice: appliedAskConsumptionByPrice,
    appliedBidConsumptionByPrice: appliedBidConsumptionByPrice,
    appliedCapacityConsumptionUnits: math.max(
      snapshot.appliedCapacityConsumptionUnits,
      math.max(0, consumedCapacityUnits),
    ),
    lastSyntheticTrade: snapshot.lastSyntheticTrade,
    syntheticTradePrints: snapshot.syntheticTradePrints,
    sweepSteps: snapshot.sweepSteps,
    syntheticTradeBudgetUsed: snapshot.syntheticTradeBudgetUsed,
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
  bool holdSameMinuteBoundaryUntilExecution = false,
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
  final elapsedMinutes = previousSnapshotMinute == null
      ? null
      : minute - previousSnapshotMinute;
  final carriesPreviousBook =
      previousSnapshot != null && elapsedMinutes != null && elapsedMinutes >= 0;
  final carriedSourceLastTradePrice =
      carriesPreviousBook &&
          previousSnapshot.sourceLastTradePrice != null &&
          previousSnapshot.sourceLastTradePrice!.isFinite &&
          previousSnapshot.sourceLastTradePrice! > 0
      ? marketSnapPrice(
          previousSnapshot.sourceLastTradePrice!
              .clamp(range.lower, range.upper)
              .toDouble(),
          market: market,
        )
      : null;
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
    final aggressorSide = _gameOrderBookBoundarySide(
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
  final previousSameMinuteBestBidPrice = previousSnapshotMinute == minute
      ? previousSnapshot?.boundaryBidPrice ??
            (holdSameMinuteBoundaryUntilExecution
                ? previousSnapshot?.bids
                      .where((level) => level.quantity > 0)
                      .firstOrNull
                      ?.price
                : null)
      : null;
  if (previousSameMinuteBestBidPrice != null &&
      previousSameMinuteBestBidPrice.isFinite &&
      previousSameMinuteBestBidPrice > 0) {
    final candidate = marketSnapPrice(
      previousSameMinuteBestBidPrice.clamp(range.lower, range.upper).toDouble(),
      market: market,
    );
    if (candidate >= range.lower - 0.000001 &&
        candidate <= range.upper + 0.000001) {
      center = candidate;
    }
  }
  final tradable =
      tradingDay && marketClockAt(minute, tradingDay: true).tradable;
  final fullDayTurnoverEok = gameEstimatedFullDayTurnoverEok(
    assetId: assetId,
    day: day,
    referencePrice: safePreviousClose,
    simulationSeed: simulationSeed,
    sharesOutstanding: sharesOutstanding,
  );
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
  final previousForRegime =
      carriedSourceLastTradePrice ??
      (hasPreviousTrade
          ? marketSnapPrice(
              previousTradePrice.clamp(range.lower, range.upper).toDouble(),
              market: market,
            )
          : lastTradePrice);
  final minuteTransition =
      carriesPreviousBook && elapsedMinutes > 0 && executionCapacity > 0
      ? gameOrderBookPriceTransitionTowardTarget(
          snapshot: previousSnapshot,
          previousPrice: previousForRegime,
          targetPrice: lastTradePrice,
          availableUnits: executionCapacity,
          market: market,
        )
      : null;

  double boundaryCenterAfterTransition(
    GameOrderBookPriceTransition transition,
  ) {
    final fills = transition.orderedFills;
    final previousBook = previousSnapshot;
    if (fills.isEmpty || previousBook == null) return transition.price;
    final lastFill = fills.last;

    if (lastFill.side == GameOrderBookSide.ask) {
      if (lastFill.boundaryCrossed) return lastFill.price;
      double? lastCrossedAskPrice;
      for (final fill in fills) {
        if (fill.side == GameOrderBookSide.ask && fill.boundaryCrossed) {
          lastCrossedAskPrice = fill.price;
        }
      }
      return lastCrossedAskPrice ??
          previousBook.boundaryBidPrice ??
          previousBook.bids
              .where((level) => level.quantity > 0)
              .firstOrNull
              ?.price ??
          previousForRegime;
    }

    if (!lastFill.boundaryCrossed) return lastFill.price;
    final nextStandingBid = previousBook.bids
        .where(
          (level) =>
              level.quantity > 0 && level.price < lastFill.price - 0.000001,
        )
        .firstOrNull;
    if (nextStandingBid != null) return nextStandingBid.price;
    final previousTick = marketTickSize(
      math.max(0.000001, lastFill.price - 0.000001),
      market: market,
    );
    final fallback = marketSnapPrice(
      lastFill.price - previousTick,
      market: market,
    );
    return fallback >= range.lower - 0.000001 && fallback < lastFill.price
        ? fallback
        : lastFill.price;
  }

  if (minuteTransition != null &&
      minuteTransition.consumedUnits > 0 &&
      minuteTransition.price.isFinite &&
      minuteTransition.price > 0) {
    center = marketSnapPrice(
      boundaryCenterAfterTransition(
        minuteTransition,
      ).clamp(range.lower, range.upper).toDouble(),
      market: market,
    );
  } else if (carriesPreviousBook &&
      elapsedMinutes > 0 &&
      carriedSourceLastTradePrice != null &&
      (previousSnapshot.boundaryBidPrice != null ||
          (lastTradePrice - carriedSourceLastTradePrice).abs() >= 0.000001)) {
    // A new deterministic candle target is not itself an execution. If the
    // session is non-tradable or has no capacity, keep the last executed book
    // boundary instead of teleporting back to that target.
    center =
        previousSnapshot.boundaryBidPrice ??
        previousSnapshot.bids
            .where((level) => level.quantity > 0)
            .firstOrNull
            ?.price ??
        carriedSourceLastTradePrice;
  }
  final regime = _gameOrderBookRegime(
    seededAssetId: seededAssetId,
    day: day,
    minute: minute,
    previousPrice: previousForRegime,
    currentPrice: minuteTransition?.lastFillPrice ?? center,
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
  final minimumLevelCount = math.max(0, levelCount);
  final reserveLevelCount = minimumLevelCount;
  final carryContext = carriesPreviousBook
      ? _GameOrderBookCarryContext(
          previousSnapshot: previousSnapshot,
          elapsedMinutes: elapsedMinutes,
          fastMarket: regime.isFast,
          liquidityPulse: safeLiquidityPulse,
          adaptiveLiquidityPulses: adaptiveLiquidityPulses,
          seededAssetId: seededAssetId,
          day: day,
          minute: minute,
          turnoverEok: turnoverEok,
          executionCapacity: executionCapacity,
          standingBaseDepth: baseDepth,
          moveIntensity: regime.intensity,
          continuousDisplayedLadder:
              fullDayTurnoverEok >=
              gameOrderBookSeverelySparseFullDayTurnoverEok,
        )
      : null;
  final asks = <GameOrderBookLevel>[];
  final bids = <GameOrderBookLevel>[];

  GameOrderBookLevel? previousTransitionLevel(
    GameOrderBookPriceTransitionFill fill,
  ) {
    final previousBook = previousSnapshot;
    if (previousBook == null) return null;
    final levels = fill.side == GameOrderBookSide.ask
        ? previousBook.asks
        : previousBook.bids;
    for (final level in levels) {
      if ((level.price - fill.price).abs() < 0.000001) return level;
    }
    final remembered = previousBook.rememberedLevels[fill.price];
    if (remembered != null && remembered.side == fill.side) return remembered;
    return null;
  }

  GameOrderBookPriceTransitionFill? transitionFillAt(double price) {
    final fills = minuteTransition?.orderedFills;
    if (fills == null) return null;
    for (final fill in fills) {
      if ((fill.price - price).abs() < 0.000001) return fill;
    }
    return null;
  }

  GameOrderBookLevel carryLevel(
    GameOrderBookLevel level, {
    required int ticksFromTouch,
  }) {
    final carried =
        carryContext?.carry(level, ticksFromTouch: ticksFromTouch) ?? level;
    final fill = transitionFillAt(level.price);
    if (fill == null || fill.quantity <= 0) return carried;
    final previousLevel = previousTransitionLevel(fill);
    if (previousLevel == null) return carried;
    final recoveryBaseline = math.max(
      previousLevel.quantity,
      previousLevel.queueRecoveryTargetQuantity,
    );
    final structuralQueueBreached = _gameOrderBookStructuralQueueBreached(
      previousLevel,
      baselineQuantity: recoveryBaseline,
      remainingQuantity: fill.remainingQuantity,
    );
    final recoveryCeiling = structuralQueueBreached
        ? _gameOrderBookStructuralRecoveryCeiling(
            previousLevel,
            baselineQuantity: recoveryBaseline,
          )
        : 0;
    if (fill.side != level.side) {
      final promoted = _gameOrderBookOppositeQueueAfterTouchConsumption(
        snapshot: previousSnapshot!,
        target: previousLevel,
      );
      if (promoted != null && promoted.side == level.side) {
        return promoted;
      }
      if (!structuralQueueBreached) return carried;
      final breachedQuantity = math.min(carried.quantity, recoveryCeiling);
      return _gameOrderBookLevelWithQuantity(
        carried,
        breachedQuantity,
        queueRecoveryTargetQuantity: 0,
        isWall: false,
        isStructuralWall: false,
        isStructuralBreached: true,
        structuralVacuumMultiplier: math.min(
          math.min(
            carried.structuralVacuumMultiplier,
            previousLevel.structuralVacuumMultiplier,
          ),
          0.65,
        ),
      );
    }
    final rawRemaining = math.max(0, fill.remainingQuantity);
    final displayedRemaining = rawRemaining;
    final cappedRemaining = structuralQueueBreached
        ? math.min(displayedRemaining, recoveryCeiling)
        : displayedRemaining;
    final recoveryTarget = structuralQueueBreached
        ? cappedRemaining > 0 && cappedRemaining < recoveryCeiling
              ? recoveryCeiling
              : 0
        : math.max(carried.queueRecoveryTargetQuantity, recoveryBaseline);
    return _gameOrderBookLevelWithQuantity(
      carried,
      cappedRemaining,
      queueRecoveryTargetQuantity: recoveryTarget,
      isWall: structuralQueueBreached ? false : null,
      isStructuralWall: structuralQueueBreached ? false : null,
      isStructuralBreached: structuralQueueBreached ? true : null,
      structuralVacuumMultiplier: structuralQueueBreached
          ? math.min(
              math.min(
                carried.structuralVacuumMultiplier,
                previousLevel.structuralVacuumMultiplier,
              ),
              0.65,
            )
          : null,
    );
  }

  bool hasExecutableDepthReserve(List<GameOrderBookLevel> levels) {
    final positiveLevels = levels
        .where((level) => level.quantity > 0)
        .toList(growable: false);
    if (positiveLevels.length < minimumLevelCount) return false;
    if (minimumLevelCount < 6 || executionCapacity <= 0) return true;
    if (positiveLevels.length <= reserveLevelCount) return false;
    final executableDepth = positiveLevels
        .take(positiveLevels.length - reserveLevelCount)
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
          regime: regime,
          currentLadderIndex: currentLadderIndex,
          levelCount: minimumLevelCount,
          structuralLiquidity: structuralLiquidity,
          liquidityPulse: safeLiquidityPulse,
          adaptiveLiquidityPulses: adaptiveLiquidityPulses,
          ticksFromTouch: asks.length,
          fullDayTurnoverEok: fullDayTurnoverEok,
        ),
        ticksFromTouch: asks.length,
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
          regime: regime,
          currentLadderIndex: currentLadderIndex,
          levelCount: minimumLevelCount,
          structuralLiquidity: structuralLiquidity,
          liquidityPulse: safeLiquidityPulse,
          adaptiveLiquidityPulses: adaptiveLiquidityPulses,
          ticksFromTouch: bids.length,
          fullDayTurnoverEok: fullDayTurnoverEok,
        ),
        ticksFromTouch: bids.length,
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

  // Only genuinely ultra-sparse books may retain empty prices as internal
  // gaps. Books above the severe-sparsity threshold generate every operational
  // tick with usable depth, so filtering here cannot turn 32,200...32,450 into
  // a false 32,150 / 32,500 spread. Production snapshots still expose only
  // executable rows instead of the old numeric `0주` bug.
  final displayedAsks = asks
      .where((level) => level.quantity > 0)
      .toList(growable: false);
  final displayedBids = bids
      .where((level) => level.quantity > 0)
      .toList(growable: false);
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
    for (final level in [...asks, ...bids]) level.price: level,
  };
  final sourceLastTradePrice = carriesPreviousBook && elapsedMinutes == 0
      ? previousSnapshot.sourceLastTradePrice ?? lastTradePrice
      : minuteTransition?.lastFillPrice ??
            (carriesPreviousBook
                ? previousSnapshot.sourceLastTradePrice ?? lastTradePrice
                : lastTradePrice);
  final keepsExecutedBoundary =
      previousSnapshot?.boundaryBidPrice != null ||
      (minuteTransition?.lastFillQuantity ?? 0) > 0;
  final carriesSameMinuteBatch = carriesPreviousBook && elapsedMinutes == 0;
  final transitionPrints = minuteTransition == null
      ? const <GameOrderBookSyntheticTrade>[]
      : _gameOrderBookTransitionPrints(
          transition: minuteTransition,
          assetId: seededAssetId,
          day: day,
          minute: minute,
          liquidityPulse: safeLiquidityPulse,
        );
  final transitionSweepSteps = minuteTransition == null
      ? const <GameOrderBookSweepStep>[]
      : List<GameOrderBookSweepStep>.unmodifiable([
          for (final entry in minuteTransition.orderedFills.asMap().entries)
            GameOrderBookSweepStep(
              marketMinute: minute,
              liquidityPulse: safeLiquidityPulse,
              sequence: entry.key,
              side: entry.value.side,
              price: entry.value.price,
              consumedQuantity: entry.value.quantity,
              remainingQuantity: entry.value.remainingQuantity,
              structuralBreach: entry.value.structuralBreach,
              boundaryCrossed: entry.value.boundaryCrossed,
            ),
        ]);
  return GameOrderBookSnapshot(
    asks: List.unmodifiable(displayedAsks),
    bids: List.unmodifiable(displayedBids),
    turnoverEok: turnoverEok,
    fullDayTurnoverEok: fullDayTurnoverEok,
    boundaryBidPrice: keepsExecutedBoundary
        ? displayedBids.firstOrNull?.price ?? center
        : null,
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
    sourceLastTradePrice: sourceLastTradePrice,
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
    lastSyntheticTrade: carriesSameMinuteBatch
        ? previousSnapshot.lastSyntheticTrade
        : minuteTransition?.lastFillSide != null &&
              minuteTransition?.lastFillPrice != null &&
              (minuteTransition?.lastFillQuantity ?? 0) > 0
        ? GameOrderBookSyntheticTrade(
            marketMinute: minute,
            liquidityPulse: safeLiquidityPulse,
            levelSide: minuteTransition!.lastFillSide!,
            price: minuteTransition.lastFillPrice!,
            quantity: minuteTransition.lastFillQuantity,
          )
        : null,
    syntheticTradePrints: carriesSameMinuteBatch
        ? previousSnapshot.syntheticTradePrints
        : transitionPrints,
    sweepSteps: carriesSameMinuteBatch
        ? previousSnapshot.sweepSteps
        : transitionSweepSteps,
    syntheticTradeBudgetUsed: carriesSameMinuteBatch
        ? previousSnapshot.syntheticTradeBudgetUsed
        : minuteTransition?.consumedUnits ?? 0,
  );
}

double gameOrderBookQueueArrivalProximity(int ticksFromTouch) =>
    (1 / (1 + math.max(0, ticksFromTouch) * 0.55)).clamp(0.12, 1.0).toDouble();

class _GameOrderBookQueueArrivalProfile {
  const _GameOrderBookQueueArrivalProfile({
    required this.executionCapacity,
    required this.turnoverEok,
    required this.flowLoad,
    required this.fastMarket,
    required this.moveIntensity,
    required this.institutionalSide,
    required this.institutionalIntensity,
    required this.pensionSide,
    required this.pensionIntensity,
  });

  final int executionCapacity;
  final double turnoverEok;
  final double flowLoad;
  final bool fastMarket;
  final double moveIntensity;
  final GameOrderBookSide institutionalSide;
  final double institutionalIntensity;
  final GameOrderBookSide pensionSide;
  final double pensionIntensity;

  int replenishmentFor(
    GameOrderBookLevel level, {
    required int ticksFromTouch,
  }) {
    if (executionCapacity <= 0 || turnoverEok <= 0 || level.quantity <= 0) {
      return 0;
    }

    // The absolute trickle ceiling comes from the same turnover-derived minute
    // capacity used by the tape and order engine. Queue arrivals are not prints,
    // but a quiet stock still cannot rebuild every price as if it were active.
    final activityMultiplier =
        (0.82 + math.sqrt(flowLoad.clamp(0.20, 3.0)) * 0.18)
            .clamp(0.84, 1.25)
            .toDouble();
    var targetShare = fastMarket ? 0.070 : 0.032;
    var capacityShare = fastMarket ? 0.055 : 0.022;
    if (fastMarket) {
      targetShare += moveIntensity * 0.035;
      capacityShare += moveIntensity * 0.025;
    }
    if (level.wasLiquidityPulseTouched) {
      targetShare += fastMarket ? 0.018 : 0.010;
      capacityShare += fastMarket ? 0.012 : 0.006;
    }
    if (level.side == institutionalSide) {
      targetShare += institutionalIntensity * 0.045;
      capacityShare += institutionalIntensity * 0.035;
    }
    if (level.side == pensionSide) {
      targetShare += pensionIntensity * 0.035;
      capacityShare += pensionIntensity * 0.025;
    }

    // Clamp the activity shares before applying distance. Clamping afterwards
    // would erase most of the intended near/far attenuation at outer quotes.
    targetShare = (targetShare * activityMultiplier).clamp(0.020, 0.180);
    capacityShare = (capacityShare * activityMultiplier).clamp(0.012, 0.120);
    final proximity = gameOrderBookQueueArrivalProximity(ticksFromTouch);
    final targetBound = math.max(
      1,
      (level.quantity * targetShare * proximity).round(),
    );
    final turnoverBound = math.max(
      1,
      (executionCapacity * capacityShare * proximity).round(),
    );
    final trickle = math.min(targetBound, turnoverBound);

    // A normal quote needs a usable starting queue after it is swept. Walls keep
    // only the turnover-bounded trickle so a large level cannot reappear whole.
    var ordinaryFlowMultiplier = activityMultiplier;
    if (fastMarket) {
      ordinaryFlowMultiplier *= 1 + moveIntensity * 0.22;
    }
    if (level.wasLiquidityPulseTouched) {
      ordinaryFlowMultiplier *= 1.04;
    }
    if (level.side == institutionalSide) {
      ordinaryFlowMultiplier *= 1 + institutionalIntensity * 0.18;
    }
    if (level.side == pensionSide) {
      ordinaryFlowMultiplier *= 1 + pensionIntensity * 0.14;
    }
    final seedFloorShare = level.isWall ? 0.0 : 0.28;
    final seedFloor =
        (level.quantity *
                seedFloorShare *
                proximity *
                ordinaryFlowMultiplier.clamp(0.75, 1.45))
            .round();
    return math.min(level.quantity, math.max(seedFloor, trickle));
  }
}

_GameOrderBookQueueArrivalProfile _gameOrderBookQueueArrivalProfile({
  required String seededAssetId,
  required int day,
  required int minute,
  required double turnoverEok,
  required int executionCapacity,
  required int standingBaseDepth,
  required bool fastMarket,
  required double moveIntensity,
}) {
  double concentrated(double signedFlow, double threshold) =>
      ((signedFlow.abs() - threshold) / (1 - threshold))
          .clamp(0.0, 1.0)
          .toDouble();

  // Institution-like demand changes over several minutes; pension-like demand
  // is rarer and slower. Both are independent of the price regime, so a calm
  // stock can still receive a genuine one-sided liquidity wave.
  final institutionalFlow =
      _smoothOrderBookUnit(
            seededAssetId,
            day,
            minute,
            10037,
            windowMinutes: 8,
          ) *
          2 -
      1;
  final pensionFlow =
      _smoothOrderBookUnit(
            seededAssetId,
            day,
            minute,
            12011,
            windowMinutes: 24,
          ) *
          2 -
      1;
  return _GameOrderBookQueueArrivalProfile(
    executionCapacity: executionCapacity,
    turnoverEok: turnoverEok,
    flowLoad: standingBaseDepth <= 0
        ? 1
        : executionCapacity / standingBaseDepth,
    fastMarket: fastMarket,
    moveIntensity: moveIntensity.clamp(0.0, 1.0).toDouble(),
    institutionalSide: institutionalFlow >= 0
        ? GameOrderBookSide.bid
        : GameOrderBookSide.ask,
    institutionalIntensity: concentrated(institutionalFlow, 0.48),
    pensionSide: pensionFlow >= 0
        ? GameOrderBookSide.bid
        : GameOrderBookSide.ask,
    pensionIntensity: concentrated(pensionFlow, 0.62),
  );
}

({double price, double targetMultiplier})? _gameOrderBookWallBreath({
  required GameOrderBookSnapshot previousSnapshot,
  required String seededAssetId,
  required int day,
  required int minute,
  required int liquidityPulse,
  required bool adaptiveLiquidityPulses,
  required bool fastMarket,
}) {
  if (!adaptiveLiquidityPulses ||
      liquidityPulse <= previousSnapshot.liquidityPulse) {
    return null;
  }
  final pulseSlot = gameOrderBookPulseSlotForFrame(
    marketMinute: minute,
    liquidityPulse: liquidityPulse,
  );
  final minuteOffset = math.max(0, minute - krxOpenMinute);
  // One live wall breathes on the first quote pulse of every market minute.
  // Bid and ask alternate, so each side changes once every two minutes without
  // making several rows look regenerated together.
  if (pulseSlot != 1) return null;

  final healthyLevels =
      <GameOrderBookLevel>[...previousSnapshot.asks, ...previousSnapshot.bids]
          .where(
            (level) =>
                level.quantity > 0 &&
                !level.isStructuralBreached &&
                level.structuralVacuumMultiplier >= 0.999999,
          )
          .toList(growable: false);
  if (healthyLevels.isEmpty) return null;

  final sideOffset = _orderBookMixedHash(seededAssetId, day, 15401) & 1;
  final breathCycle = minuteOffset;
  final preferredSide = (breathCycle + sideOffset).isEven
      ? GameOrderBookSide.ask
      : GameOrderBookSide.bid;
  final preferredLevels = healthyLevels
      .where((level) => level.side == preferredSide)
      .toList(growable: false);
  final sideCandidates = preferredLevels.isEmpty
      ? healthyLevels
      : preferredLevels;
  final flaggedWalls = sideCandidates
      .where((level) => level.isWall)
      .toList(growable: false);
  final candidates = flaggedWalls.isNotEmpty
      ? flaggedWalls
      : <GameOrderBookLevel>[
          sideCandidates.reduce(
            (largest, level) =>
                level.quantity > largest.quantity ? level : largest,
          ),
        ];
  final selectionHash = _orderBookMixedHash(
    seededAssetId,
    day,
    liquidityPulse * 12289 + 17431,
  );
  final selected = candidates[selectionHash % candidates.length];
  final breathUnit = _orderBookUnit(
    seededAssetId,
    day,
    liquidityPulse * 24593 + selectionHash + 19301,
  );
  final signedUnit = breathUnit * 2 - 1;
  final signedMagnitude =
      (signedUnit < 0 ? -1.0 : 1.0) * (0.45 + signedUnit.abs() * 0.55);
  final amplitude = fastMarket ? 0.028 : 0.018;
  return (
    price: selected.price,
    targetMultiplier: 1 + signedMagnitude * amplitude,
  );
}

class _GameOrderBookCarryContext {
  _GameOrderBookCarryContext({
    required GameOrderBookSnapshot previousSnapshot,
    required int elapsedMinutes,
    required this.fastMarket,
    required int liquidityPulse,
    required bool adaptiveLiquidityPulses,
    required String seededAssetId,
    required int day,
    required int minute,
    required double turnoverEok,
    required int executionCapacity,
    required int standingBaseDepth,
    required double moveIntensity,
    required this.continuousDisplayedLadder,
  }) : previousByPrice = <double, GameOrderBookLevel>{
         ...previousSnapshot.rememberedLevels,
         for (final level in [
           ...previousSnapshot.asks,
           ...previousSnapshot.bids,
         ])
           level.price: level,
       },
       hasCompetingDepletedRecoveries =
           previousSnapshot.rememberedLevels.values
               .where(
                 (level) =>
                     level.quantity <= 0 &&
                     level.queueRecoveryTargetQuantity > 0,
               )
               .take(2)
               .length >
           1,
       pulseAdvanced =
           adaptiveLiquidityPulses &&
           liquidityPulse > previousSnapshot.liquidityPulse,
       minuteAdvanced = elapsedMinutes > 0,
       noNewAdaptivePulse =
           adaptiveLiquidityPulses &&
           liquidityPulse <= previousSnapshot.liquidityPulse,
       latestSyntheticTrade = previousSnapshot.lastSyntheticTrade,
       currentLiquidityPulse = liquidityPulse,
       wallBreath = _gameOrderBookWallBreath(
         previousSnapshot: previousSnapshot,
         seededAssetId: seededAssetId,
         day: day,
         minute: minute,
         liquidityPulse: liquidityPulse,
         adaptiveLiquidityPulses: adaptiveLiquidityPulses,
         fastMarket: fastMarket,
       ),
       queueArrivalProfile = _gameOrderBookQueueArrivalProfile(
         seededAssetId: seededAssetId,
         day: day,
         minute: minute,
         turnoverEok: turnoverEok,
         executionCapacity: executionCapacity,
         standingBaseDepth: standingBaseDepth,
         fastMarket: fastMarket,
         moveIntensity: moveIntensity,
       ),
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
  final bool minuteAdvanced;
  final bool noNewAdaptivePulse;
  final GameOrderBookSyntheticTrade? latestSyntheticTrade;
  final int currentLiquidityPulse;
  final ({double price, double targetMultiplier})? wallBreath;
  final _GameOrderBookQueueArrivalProfile queueArrivalProfile;
  final double effectiveLimit;
  final bool continuousDisplayedLadder;
  final bool hasCompetingDepletedRecoveries;

  bool _isImmediateLatestDepletion(GameOrderBookLevel level) {
    final trade = latestSyntheticTrade;
    return trade != null &&
        !minuteAdvanced &&
        currentLiquidityPulse == trade.liquidityPulse + 1 &&
        trade.levelSide == level.side &&
        (trade.price - level.price).abs() < 0.000001;
  }

  ({int quantity, int queueRecoveryTargetQuantity}) _carriedQueue(
    GameOrderBookLevel level,
    GameOrderBookLevel previous, {
    required int ticksFromTouch,
  }) {
    final previousRecoveryTarget = math.max(
      0,
      previous.queueRecoveryTargetQuantity,
    );
    final isStructuralVacuum =
        level.isStructuralBreached ||
        previous.isStructuralBreached ||
        level.structuralVacuumMultiplier < 0.999999 ||
        previous.structuralVacuumMultiplier < 0.999999;
    final isRecoveringOrdinaryQueue =
        previousRecoveryTarget > previous.quantity && !previous.isWall;
    final activeWallBreath = wallBreath;
    final isLiveWall =
        previous.isWall && previous.quantity > 0 && !isStructuralVacuum;
    final isBreathingWall =
        previous.quantity > 0 &&
        !isStructuralVacuum &&
        activeWallBreath != null &&
        (activeWallBreath.price - level.price).abs() < 0.000001;
    final isProtectedWall = isLiveWall || isBreathingWall;
    if (previous.quantity <= 0) {
      if (level.quantity <= 0) {
        return (
          quantity: 0,
          queueRecoveryTargetQuantity: previousRecoveryTarget,
        );
      }
      if ((!pulseAdvanced && !minuteAdvanced) ||
          _isImmediateLatestDepletion(level)) {
        return (
          quantity: 0,
          queueRecoveryTargetQuantity: previousRecoveryTarget,
        );
      }
      if (pulseAdvanced &&
          hasCompetingDepletedRecoveries &&
          !level.wasLiquidityPulseTouched) {
        return (
          quantity: 0,
          queueRecoveryTargetQuantity: previousRecoveryTarget,
        );
      }
      // A just-breached wall leaves a real gap around the touch. Once price is
      // at least two rows away, only a heavily suppressed ordinary queue may
      // enter; the structural-wall flag itself never returns.
      if (!continuousDisplayedLadder &&
          isStructuralVacuum &&
          ticksFromTouch < 2) {
        return (quantity: 0, queueRecoveryTargetQuantity: 0);
      }
      var arrival = queueArrivalProfile.replenishmentFor(
        level,
        ticksFromTouch: ticksFromTouch,
      );
      if (continuousDisplayedLadder) {
        arrival = math.max(gameOrderBookMinimumDisplayedQuantity, arrival);
      } else if (arrival > 0) {
        arrival = math.max(
          gameOrderBookMinimumDisplayedQuantity,
          isStructuralVacuum ? (arrival * 0.20).round() : arrival,
        );
      }
      final recoveryTarget = previousRecoveryTarget > 0
          ? previousRecoveryTarget
          : level.quantity;
      final firstArrivalCap =
          recoveryTarget > gameOrderBookMinimumDisplayedQuantity
          ? math.max(
              gameOrderBookMinimumDisplayedQuantity,
              (recoveryTarget * 0.45).round(),
            )
          : recoveryTarget;
      final quantity = math.min(
        level.quantity,
        math.min(arrival, firstArrivalCap),
      );
      return (
        quantity: quantity,
        queueRecoveryTargetQuantity:
            isStructuralVacuum || quantity >= recoveryTarget
            ? 0
            : recoveryTarget,
      );
    }
    if (noNewAdaptivePulse && minuteAdvanced) {
      return (
        quantity: previous.quantity,
        queueRecoveryTargetQuantity: previousRecoveryTarget,
      );
    }
    if (isStructuralVacuum && !isRecoveringOrdinaryQueue) {
      return (
        quantity: math.min(previous.quantity, level.quantity),
        queueRecoveryTargetQuantity: 0,
      );
    }
    if (noNewAdaptivePulse) {
      return (
        quantity: previous.quantity,
        queueRecoveryTargetQuantity: previousRecoveryTarget,
      );
    }
    if (pulseAdvanced &&
        isLiveWall &&
        activeWallBreath != null &&
        !isBreathingWall) {
      return (
        quantity: previous.quantity,
        queueRecoveryTargetQuantity: previousRecoveryTarget,
      );
    }
    if (pulseAdvanced && !level.wasLiquidityPulseTouched && !isBreathingWall) {
      return (
        quantity: previous.quantity,
        queueRecoveryTargetQuantity: previousRecoveryTarget,
      );
    }

    // Close every price to its deterministic path at a minute boundary. Within
    // the minute, near-touch rows move more visibly while outer rows stay calm.
    final proximity = gameOrderBookQueueArrivalProximity(ticksFromTouch);
    final rawBreathingTarget = isBreathingWall
        ? math.max(
            gameOrderBookMinimumDisplayedQuantity,
            (previous.quantity * activeWallBreath.targetMultiplier).round(),
          )
        : level.quantity;
    final targetQuantity =
        isBreathingWall && rawBreathingTarget == previous.quantity
        ? math.max(
            gameOrderBookMinimumDisplayedQuantity,
            previous.quantity +
                (activeWallBreath.targetMultiplier >= 1 ? 1 : -1),
          )
        : rawBreathingTarget;
    final adjustment = isBreathingWall
        ? math.max(
            1,
            (previous.quantity * (fastMarket ? 0.020 : 0.012)).round(),
          )
        : isLiveWall && effectiveLimit > 0
        ? math.max(
            1,
            (previous.quantity *
                    (fastMarket ? 0.035 : 0.018) *
                    (0.65 + proximity * 0.35))
                .round(),
          )
        : isLiveWall
        ? 0
        : (previous.quantity * effectiveLimit * proximity).floor();
    var quantity = targetQuantity
        .clamp(
          math.max(1, previous.quantity - adjustment),
          previous.quantity + adjustment,
        )
        .toInt();
    // Ordinary cancellations may lower the current deterministic target
    // immediately. Live walls instead move inside the small cap above so a
    // single quote pulse cannot make the wall look fully redrawn.
    if (!isProtectedWall) quantity = math.min(quantity, targetQuantity);
    if (isRecoveringOrdinaryQueue && !isBreathingWall) {
      var arrival = queueArrivalProfile.replenishmentFor(
        level,
        ticksFromTouch: ticksFromTouch,
      );
      if (isStructuralVacuum && arrival > 0) {
        arrival = math.max(1, (arrival * 0.35).round());
      }
      final replenishmentTarget = previousRecoveryTarget > 0
          ? isStructuralVacuum
                ? previousRecoveryTarget
                : math.min(previousRecoveryTarget, level.quantity)
          : level.quantity;
      quantity = math.min(
        replenishmentTarget,
        math.max(quantity, previous.quantity + arrival),
      );
    }
    final recoveryGoal = isStructuralVacuum
        ? previousRecoveryTarget
        : math.min(previousRecoveryTarget, level.quantity);
    return (
      quantity: quantity,
      queueRecoveryTargetQuantity: recoveryGoal <= 0 || quantity >= recoveryGoal
          ? 0
          : previousRecoveryTarget,
    );
  }

  GameOrderBookLevel carry(
    GameOrderBookLevel level, {
    required int ticksFromTouch,
  }) {
    final previous = previousByPrice[level.price];
    final carriedStructuralBreach =
        level.isStructuralBreached || (previous?.isStructuralBreached ?? false);
    final carriedStructuralVacuum = math.min(
      level.structuralVacuumMultiplier,
      previous?.structuralVacuumMultiplier ?? 1.0,
    );
    if (previous == null || previous.side != level.side) {
      final isStructuralVacuum =
          carriedStructuralBreach || carriedStructuralVacuum < 0.999999;
      if (!isStructuralVacuum) return level;
      if (ticksFromTouch >= gameOrderBookLevelCount) {
        // Reserve-only rows must not drain remembered depth or force the raw
        // builder to scan the whole daily range. The gate is applied once the
        // price can enter the operational 10-row side.
        return level;
      }

      // Never inherit the old opposite-side queue when price crosses it, but
      // still enforce the breached-zone gap before admitting a new-side queue.
      var quantity = continuousDisplayedLadder
          ? math.min(level.quantity, gameOrderBookMinimumDisplayedQuantity)
          : 0;
      if (continuousDisplayedLadder || ticksFromTouch >= 2) {
        final arrival = queueArrivalProfile.replenishmentFor(
          level,
          ticksFromTouch: ticksFromTouch,
        );
        if (arrival > 0 || continuousDisplayedLadder) {
          quantity = math.min(
            level.quantity,
            math.max(
              gameOrderBookMinimumDisplayedQuantity,
              (arrival * 0.20).round(),
            ),
          );
        }
      }
      return GameOrderBookLevel(
        side: level.side,
        price: level.price,
        quantity: quantity,
        isWall: false,
        structuralKind: level.structuralKind,
        structuralStrength: level.structuralStrength,
        structuralHoldTicks: level.structuralHoldTicks,
        isStructuralWall: carriedStructuralBreach
            ? false
            : level.isStructuralWall,
        isStructuralBreached: carriedStructuralBreach,
        structuralVacuumMultiplier: carriedStructuralBreach
            ? math.min(carriedStructuralVacuum, 0.65)
            : carriedStructuralVacuum,
        isPsychological: level.isPsychological,
        technicalPeriods: level.technicalPeriods,
        wasLiquidityPulseTouched: level.wasLiquidityPulseTouched,
        queueRecoveryTargetQuantity: 0,
      );
    }
    final carriesRecoveringOrdinaryQueue =
        previous.queueRecoveryTargetQuantity > previous.quantity &&
        !previous.isWall;
    final carried = _carriedQueue(
      level,
      previous,
      ticksFromTouch: ticksFromTouch,
    );
    final displayedQuantity = carried.quantity <= 0
        ? 0
        : math.max(gameOrderBookMinimumDisplayedQuantity, carried.quantity);
    return GameOrderBookLevel(
      side: level.side,
      price: level.price,
      quantity: displayedQuantity,
      isWall:
          carriesRecoveringOrdinaryQueue ||
              carriedStructuralBreach ||
              carriedStructuralVacuum < 0.999999
          ? false
          : level.isStructuralWall
          ? true
          : previous.isWall,
      structuralKind: level.structuralKind,
      structuralStrength: level.structuralStrength,
      structuralHoldTicks: level.structuralHoldTicks,
      isStructuralWall:
          carriesRecoveringOrdinaryQueue || carriedStructuralBreach
          ? false
          : level.isStructuralWall,
      isStructuralBreached: carriedStructuralBreach,
      structuralVacuumMultiplier: carriedStructuralBreach
          ? math.min(carriedStructuralVacuum, 0.65)
          : carriedStructuralVacuum,
      isPsychological: level.isPsychological,
      technicalPeriods: level.technicalPeriods,
      wasLiquidityPulseTouched: level.wasLiquidityPulseTouched,
      queueRecoveryTargetQuantity: carried.queueRecoveryTargetQuantity,
    );
  }
}

double gameOrderBookDepthProfileAtDistance(int ticksFromTouch) {
  const profile = <double>[
    0.86,
    0.94,
    0.99,
    1.02,
    1.04,
    1.05,
    1.04,
    1.03,
    1.02,
    1.01,
  ];
  final distance = math.max(0, ticksFromTouch);
  return distance < profile.length ? profile[distance] : 1.0;
}

bool gameOrderBookIsMicroWallPrice({
  required String assetId,
  required int day,
  required double price,
  required String market,
  required double psychologicalGridStep,
}) {
  if (!price.isFinite || price <= 0) return false;
  final snapped = marketSnapPrice(price, market: market);
  final tick = marketTickSize(snapped, market: market);
  final safeGrid = psychologicalGridStep.isFinite && psychologicalGridStep > 0
      ? psychologicalGridStep
      : tick * 10;
  final candidateStep = math.max(tick, safeGrid / 2);
  final nearestCandidate = (snapped / candidateStep).round() * candidateStep;
  final isPsychologicalCandidate =
      (snapped - nearestCandidate).abs() <= tick * 0.12;
  final ladderIndex = _marketPriceLadderIndex(snapped, market: market);
  final draw = _orderBookUnit(assetId, day, ladderIndex * 131 + 5501);
  return draw < (isPsychologicalCandidate ? 0.36 : 0.065);
}

({GameOrderBookSide side, int distance}) gameOrderBookPulseTarget({
  required String assetId,
  required int day,
  required int liquidityPulse,
  required int slot,
  required int levelCount,
}) {
  final count = math.max(1, levelCount);
  final maximumDistance = count - 1;
  final salt = liquidityPulse * 10007 + slot * 7919 + 9029;
  final hash = _orderBookMixedHash(assetId, day, salt);
  final side = hash.isEven ? GameOrderBookSide.ask : GameOrderBookSide.bid;
  if (maximumDistance <= 0) return (side: side, distance: 0);

  final bucket = hash % 10000;
  late final int distance;
  if (bucket < 4600) {
    distance = 0;
  } else if (bucket < 7800) {
    final nearCount = math.min(2, maximumDistance);
    distance = 1 + (hash ~/ 10000) % nearCount;
  } else if (maximumDistance <= 2) {
    distance = (hash ~/ 10000) % (maximumDistance + 1);
  } else {
    distance = 3 + (hash ~/ 10000) % (maximumDistance - 2);
  }
  return (side: side, distance: distance);
}

GameOrderBookLevel _buildLevel({
  required GameOrderBookSide side,
  required String assetId,
  required int day,
  required int minute,
  required double price,
  required int baseDepth,
  required String market,
  required _GameOrderBookRegime regime,
  required int currentLadderIndex,
  required int levelCount,
  required MarketStructuralLiquidityMap structuralLiquidity,
  required int liquidityPulse,
  required bool adaptiveLiquidityPulses,
  required int ticksFromTouch,
  required double fullDayTurnoverEok,
}) {
  final ladderIndex = _marketPriceLadderIndex(price, market: market);
  final safeTicksFromTouch = math.max(0, ticksFromTouch);
  final proximityDecay = gameOrderBookQueueArrivalProximity(safeTicksFromTouch);
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
  final isMicroWall = gameOrderBookIsMicroWallPrice(
    assetId: assetId,
    day: day,
    price: price,
    market: market,
    psychologicalGridStep: structuralLiquidity.gridStep,
  );
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
  // Standing orders belong to an absolute price and one side of the spread.
  // Row movement may preserve the same-side queue, but an ask must never turn
  // into a bid (or vice versa) merely because the last trade crossed it.
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
      // 이 감소는 접근한 대기 주문의 취소·정정까지 포함한 목표 큐 변화다.
      // 합성 체결이나 원장 watermark를 만들지 않으므로 체결 테이프와
      // 체결강도에는 절대 더하지 않는다.
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
  final rawQuantity =
      (baseDepth *
              stableVariation *
              temporalVariation *
              wallMultiplier *
              (pulseTouchesLevel && !isWall
                  ? gameOrderBookDepthProfileAtDistance(safeTicksFromTouch)
                  : 1.0) *
              pulseMultiplier *
              structuralVacuum *
              regimeMultiplier)
          .round();
  final sparseFullDay =
      fullDayTurnoverEok > 0 &&
      fullDayTurnoverEok < gameOrderBookSparseFullDayTurnoverEok;
  final severelySparse =
      sparseFullDay &&
      fullDayTurnoverEok < gameOrderBookSeverelySparseFullDayTurnoverEok;
  final protectsNearTouch = !severelySparse && safeTicksFromTouch < 2;
  final mayBeIntentionallyEmpty =
      severelySparse && !protectsNearTouch && !isWall && structuralZone == null;
  final scarcity = sparseFullDay
      ? ((gameOrderBookSparseFullDayTurnoverEok - fullDayTurnoverEok) /
                gameOrderBookSparseFullDayTurnoverEok)
            .clamp(0.0, 1.0)
            .toDouble()
      : 0.0;
  final emptyProbability = !mayBeIntentionallyEmpty
      ? 0.0
      : severelySparse && safeTicksFromTouch == 0
      ? 0.03 * scarcity
      : (0.35 * (1 - proximityDecay) * (0.65 + scarcity * 0.35))
            .clamp(0.0, 0.45)
            .toDouble();
  final emptyDraw = _orderBookUnit(assetId, day, priceSalt + 8837);
  final isIntentionallyEmpty = emptyDraw < emptyProbability;
  return GameOrderBookLevel(
    side: side,
    price: price,
    quantity: isIntentionallyEmpty
        ? 0
        : math.max(gameOrderBookMinimumDisplayedQuantity, rawQuantity),
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
  final targets = <({GameOrderBookSide side, int distance})>{};
  for (var slot = 0; slot < touchedCount; slot += 1) {
    final selected = gameOrderBookPulseTarget(
      assetId: assetId,
      day: day,
      liquidityPulse: liquidityPulse,
      slot: slot,
      levelCount: levelCount,
    );
    var side = selected.side;
    var distance = selected.distance;
    for (
      var attempt = 0;
      attempt < math.max(2, levelCount * 2) &&
          targets.contains((side: side, distance: distance));
      attempt += 1
    ) {
      distance = (distance + 1) % math.max(1, levelCount);
      if (distance == 0) {
        side = side == GameOrderBookSide.ask
            ? GameOrderBookSide.bid
            : GameOrderBookSide.ask;
      }
    }
    targets.add((side: side, distance: distance));
  }

  for (final target in targets) {
    final offset = target.side == GameOrderBookSide.ask
        ? target.distance + 1
        : -target.distance;
    if (ladderIndex != currentLadderIndex + offset) continue;
    final eventDraw = _orderBookUnit(
      assetId,
      day,
      liquidityPulse * 65537 + ladderIndex * 313 + 27011,
    );
    // A selected row still has a genuine no-order-event state. Recovering queues
    // and minute-boundary closure are handled separately by carry logic.
    return eventDraw < (fastMarket ? 0.78 : 0.55);
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
      fullDayUnits / math.max(1, _gameOrderBookFullSessionMinutes);
  final raw =
      averageMinuteUnits *
      gameOrderBookStandingDepthMinutes *
      dailyDepthFactor *
      sessionFlow;
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
