part of 'main.dart';

enum _MarketSort { turnover, gainers, losers, name }

enum _MarketSection { home, explore, account }

enum _ChartPeriod { minute, day, week, month, year }

/// 모바일 호가창은 최우선 가격에서 매도·매수 각각 7단계만 보여 준다.
///
/// 내부 주문장 깊이는 [gameOrderBookLevelCount]를 그대로 유지하므로 체결과
/// 대기 주문 계산에는 영향을 주지 않는다.
const stockOrderBookVisibleSideRows = 7;
const _visibleOrderBookSideRows = stockOrderBookVisibleSideRows;
const _orderBookMotionDuration = Duration(milliseconds: 144);
const _inlineOrderSlideDuration = Duration(milliseconds: 320);
const _orderBookSweepTotalDuration = Duration(milliseconds: 480);
const _orderBookSweepMinimumStepDuration = Duration(milliseconds: 56);
const _orderBookSweepMaximumStepDuration = Duration(milliseconds: 96);
const _orderBookSweepFinalHoldDuration = Duration(milliseconds: 112);
const _orderBookTapeCapacity = 50;
const _stockTeacherPosePointer =
    'assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png';
const _stockTeacherPoseExplain =
    'assets/images/주식선생님/23_포즈2_주인공그림체_공통슬롯_투명.png';
const _stockTeacherPoseCompare =
    'assets/images/주식선생님/24_포즈3_주인공그림체_공통슬롯_투명.png';
const _stockTeacherPoseBook = 'assets/images/주식선생님/25_포즈4_주인공그림체_공통슬롯_투명.png';
const _stockTeacherPoseListen = 'assets/images/주식선생님/26_포즈5_주인공그림체_공통슬롯_투명.png';
const _stockTeacherPoseEmphasize =
    'assets/images/주식선생님/27_포즈6_주인공그림체_공통슬롯_투명.png';
const _stockTutorialSuaAsset =
    'assets/images/production_soft_painted/han_sua/03_bright_laugh_quality_v2.png';
const _stockTutorialHakjunAsset =
    'assets/images/historical_prologue/character_hakjun_orientation_v2.png';
const _stockTutorialPlayerAsset =
    'assets/images/protagonist_seed01/12_thinking.png';

// 제6기 여학생 8명 튜토리얼 표정 슬롯. 승인된 9종 세트에서 수업 단계에 맞춰 고른다.
const _stockTutorialSeoaRecordAsset =
    'assets/images/production_soft_painted/kim_seoa/08_determined_record_v1.png';
const _stockTutorialJianAsset =
    'assets/images/production_soft_painted/lee_jian/09_explaining_mechanism_v2.png';
const _stockTutorialJianFocusAsset =
    'assets/images/production_soft_painted/lee_jian/03_focused_repair_v2.png';
const _stockTutorialIseoAsset =
    'assets/images/production_soft_painted/choi_iseo/02_gentle_smile_v1.png';
const _stockTutorialArinAsset =
    'assets/images/production_soft_painted/jung_arin/09_counting_explain_v1.png';
const _stockTutorialArinWorriedAsset =
    'assets/images/production_soft_painted/jung_arin/06_schedule_worried_v1.png';
const _stockTutorialJiwooCorrectAsset =
    'assets/images/production_soft_painted/oh_jiwoo/05_surprised_correction_v1.png';
const _stockTutorialChaeaAsset =
    'assets/images/production_soft_painted/yoon_chaea/09_explaining_v1.png';
const _stockTutorialChaeaNeutralAsset =
    'assets/images/production_soft_painted/yoon_chaea/01_neutral_tie_v1.png';

/// 지문 전용 화자. 이 화자는 중앙 전신 슬롯을 비우고 대사창만 사용한다.
const _stockTutorialNarrationSpeaker = '이야기';

class OrderBookSweepIdentityLedger {
  OrderBookSweepIdentityLedger({required this.completedHistoryCapacity})
    : assert(completedHistoryCapacity > 0);

  final int completedHistoryCapacity;
  final Set<String> _inFlight = <String>{};
  final Set<String> _completed = <String>{};
  final List<String> _completedOrder = <String>[];

  bool admit(String identity) {
    if (identity.isEmpty ||
        _inFlight.contains(identity) ||
        _completed.contains(identity)) {
      return false;
    }
    _inFlight.add(identity);
    return true;
  }

  void complete(String identity) {
    if (!_inFlight.remove(identity) || !_completed.add(identity)) return;
    _completedOrder.add(identity);
    while (_completedOrder.length > completedHistoryCapacity) {
      _completed.remove(_completedOrder.removeAt(0));
    }
  }

  void clearInFlight() => _inFlight.clear();

  void clear() {
    _inFlight.clear();
    _completed.clear();
    _completedOrder.clear();
  }
}

({double before, double after}) orderBookSweepDepthTransition({
  required GameOrderBookSweepStep step,
  required int maxDepth,
}) {
  final safeMaxDepth = math.max(1, maxDepth);
  double depthFor(int quantity) =>
      (math.max(0, quantity) / safeMaxDepth).clamp(0.0, 1.0).toDouble();

  return (
    before: depthFor(step.consumedQuantity + step.remainingQuantity),
    after: depthFor(step.remainingQuantity),
  );
}

List<GameOrderBookLevel> orderBookSweepPresentationLevels({
  required GameOrderBookSnapshot snapshot,
  required List<GameOrderBookSweepStep> steps,
  required int activeStepIndex,
  required bool activeStepArrived,
  GameOrderBookSnapshot? previousSnapshot,
  Iterable<OrderBookCancellationNotice> cancellationNotices =
      const <OrderBookCancellationNotice>[],
  int sideRowCount = _visibleOrderBookSideRows,
}) {
  if (steps.isEmpty || activeStepIndex < 0 || activeStepIndex >= steps.length) {
    return _symmetricVisibleOrderBookLevels(snapshot);
  }

  // Non-trade quote changes are canonical immediately and never receive a
  // replay label. Only exact prices reached by the trade border are restored
  // from the before-snapshot so their drain remains synchronized with tape.
  final asks = <double, GameOrderBookLevel>{
    for (final level in snapshot.asks) level.price: level,
  };
  final bids = <double, GameOrderBookLevel>{
    for (final level in snapshot.bids) level.price: level,
  };
  if (previousSnapshot != null) {
    for (final step in steps) {
      final visible =
          (step.side == GameOrderBookSide.ask
                  ? previousSnapshot.asks
                  : previousSnapshot.bids)
              .where((level) => (level.price - step.price).abs() < 0.000001)
              .firstOrNull;
      final remembered = previousSnapshot.rememberedLevels[step.price];
      final previousLevel =
          visible ?? (remembered?.side == step.side ? remembered : null);
      if (previousLevel == null) continue;
      (step.side == GameOrderBookSide.ask ? asks : bids)[step.price] =
          previousLevel;
    }
  }
  final cancellationByLevel = <(GameOrderBookSide, double), int>{};
  for (final notice in cancellationNotices) {
    cancellationByLevel.update(
      (notice.side, notice.price),
      (quantity) => quantity + notice.quantity,
      ifAbsent: () => notice.quantity,
    );
  }

  GameOrderBookLevel levelFor(
    GameOrderBookSweepStep step,
    Map<double, GameOrderBookLevel> sameSideLevels,
  ) {
    final visible = sameSideLevels[step.price];
    if (visible != null) return visible;
    final remembered = snapshot.rememberedLevels[step.price];
    if (remembered != null && remembered.side == step.side) return remembered;
    return GameOrderBookLevel(
      side: step.side,
      price: step.price,
      quantity: 0,
      isWall: false,
      isStructuralBreached: step.structuralBreach,
    );
  }

  final groupedSteps =
      <
        (GameOrderBookSide, double),
        List<MapEntry<int, GameOrderBookSweepStep>>
      >{};
  for (final entry in steps.asMap().entries) {
    groupedSteps
        .putIfAbsent((
          entry.value.side,
          entry.value.price,
        ), () => <MapEntry<int, GameOrderBookSweepStep>>[])
        .add(entry);
  }

  for (final grouped in groupedSteps.values) {
    final step = grouped.first.value;
    final sameSideLevels = step.side == GameOrderBookSide.ask ? asks : bids;
    final oppositeSideLevels = step.side == GameOrderBookSide.ask ? bids : asks;

    // A crossed price can already have been promoted to the opposite side in
    // the canonical after-snapshot. Keep only the actually executed side until
    // the replay finishes so the border cannot appear to consume the new queue.
    oppositeSideLevels.remove(step.price);

    final activeEntry = grouped
        .where((entry) => entry.key == activeStepIndex)
        .firstOrNull;
    final firstFutureEntry = grouped
        .where((entry) => entry.key > activeStepIndex)
        .firstOrNull;
    final lastCompletedEntry = grouped
        .where((entry) => entry.key < activeStepIndex)
        .lastOrNull;
    final reportedQuantity = activeEntry != null
        ? activeStepArrived
              ? activeEntry.value.remainingQuantity
              : activeEntry.value.consumedQuantity +
                    activeEntry.value.remainingQuantity
        : firstFutureEntry != null
        ? firstFutureEntry.value.consumedQuantity +
              firstFutureEntry.value.remainingQuantity
        : lastCompletedEntry?.value.remainingQuantity ?? 0;
    final cancellationQuantity =
        cancellationByLevel[(step.side, step.price)] ?? 0;
    final baseLevel = levelFor(step, sameSideLevels);
    final initialQuantity = baseLevel.quantity > 0
        ? baseLevel.quantity
        : grouped.first.value.consumedQuantity +
              grouped.first.value.remainingQuantity +
              cancellationQuantity;
    final consumedQuantity = grouped
        .where(
          (entry) =>
              entry.key < activeStepIndex ||
              (entry.key == activeStepIndex && activeStepArrived),
        )
        .fold<int>(
          0,
          (quantity, entry) => quantity + entry.value.consumedQuantity,
        );
    final quantity = math.max(
      reportedQuantity + cancellationQuantity,
      math.max(0, initialQuantity - consumedQuantity),
    );
    if (quantity <= 0) {
      // A fully consumed price never occupies a visible slot. The next positive
      // quote replaces it as soon as the border reaches this price.
      sameSideLevels.remove(step.price);
      continue;
    }

    final source = levelFor(step, sameSideLevels);
    sameSideLevels[step.price] = GameOrderBookLevel(
      side: source.side,
      price: source.price,
      quantity: math.max(0, quantity),
      isWall: source.isWall,
      structuralKind: source.structuralKind,
      structuralStrength: source.structuralStrength,
      structuralHoldTicks: source.structuralHoldTicks,
      isStructuralWall: source.isStructuralWall,
      isStructuralBreached: source.isStructuralBreached,
      structuralVacuumMultiplier: source.structuralVacuumMultiplier,
      isPsychological: source.isPsychological,
      technicalPeriods: source.technicalPeriods,
      wasLiquidityPulseTouched: source.wasLiquidityPulseTouched,
      queueRecoveryTargetQuantity: source.queueRecoveryTargetQuantity,
    );
  }

  final orderedAsks = asks.values.toList(growable: false)
    ..sort((left, right) => left.price.compareTo(right.price));
  final orderedBids = bids.values.toList(growable: false)
    ..sort((left, right) => right.price.compareTo(left.price));
  final safeSideRowCount = math.max(1, sideRowCount);
  return <GameOrderBookLevel>[
    ...orderedAsks.take(safeSideRowCount).toList(growable: false).reversed,
    ...orderedBids.take(safeSideRowCount),
  ];
}

String orderBookQuantityDeltaLabel(int delta, {required bool isTrade}) {
  if (delta < 0 && !isTrade) return '';
  return '${delta > 0 ? '+' : ''}${_money(delta)}';
}

typedef OrderBookCancellationNotice = ({
  GameOrderBookSide side,
  double price,
  int quantity,
});

List<OrderBookCancellationNotice> orderBookCancellationNotices({
  required GameOrderBookSnapshot previous,
  required GameOrderBookSnapshot next,
  Iterable<GameOrderBookSweepStep> tradeSteps =
      const <GameOrderBookSweepStep>[],
  int? transitionMarketMinute,
  int? transitionLiquidityPulse,
}) {
  if (previous.sourceAssetId != null &&
      next.sourceAssetId != null &&
      previous.sourceAssetId != next.sourceAssetId) {
    return const <OrderBookCancellationNotice>[];
  }
  if (previous.sourceDateKey != null &&
      next.sourceDateKey != null &&
      previous.sourceDateKey != next.sourceDateKey) {
    return const <OrderBookCancellationNotice>[];
  }

  GameOrderBookLevel? matchingLevel(
    Iterable<GameOrderBookLevel> levels,
    GameOrderBookLevel target,
  ) {
    for (final level in levels) {
      if (level.side == target.side &&
          (level.price - target.price).abs() < 0.000001) {
        return level;
      }
    }
    return null;
  }

  final consumedByLevel = <(GameOrderBookSide, double), int>{};
  for (final step in tradeSteps) {
    if (step.consumedQuantity <= 0 ||
        (transitionMarketMinute != null &&
            step.marketMinute != transitionMarketMinute) ||
        (transitionLiquidityPulse != null &&
            step.liquidityPulse != transitionLiquidityPulse)) {
      continue;
    }
    consumedByLevel.update(
      (step.side, step.price),
      (quantity) => quantity + step.consumedQuantity,
      ifAbsent: () => step.consumedQuantity,
    );
  }

  final visibleNext = <GameOrderBookLevel>[...next.asks, ...next.bids];
  final rememberedNext = next.rememberedLevels.values;
  final allNext = <GameOrderBookLevel>[...visibleNext, ...rememberedNext];
  final notices = <OrderBookCancellationNotice>[];
  for (final previousLevel in <GameOrderBookLevel>[
    ...previous.asks,
    ...previous.bids,
  ]) {
    if (previousLevel.quantity <= 0) continue;
    final consumedQuantity =
        consumedByLevel[(previousLevel.side, previousLevel.price)] ?? 0;
    var current =
        matchingLevel(visibleNext, previousLevel) ??
        matchingLevel(rememberedNext, previousLevel);
    if (current == null) {
      final promotedToOppositeSide =
          consumedQuantity > 0 &&
          allNext.any(
            (level) =>
                level.side != previousLevel.side &&
                (level.price - previousLevel.price).abs() < 0.000001,
          );
      if (!promotedToOppositeSide) {
        // An absent level can simply have moved outside the visible window.
        continue;
      }
    }
    final currentQuantity = math.max(0, current?.quantity ?? 0);
    final totalDecrease = math.max(0, previousLevel.quantity - currentQuantity);
    final cancelledQuantity = math.max(0, totalDecrease - consumedQuantity);
    if (cancelledQuantity <= 0) continue;
    notices.add((
      side: previousLevel.side,
      price: previousLevel.price,
      quantity: cancelledQuantity,
    ));
  }
  return List<OrderBookCancellationNotice>.unmodifiable(notices);
}

List<int> playerOwnedOrderBookRemainingQuantities(
  Iterable<GameOrderBookSweepStep> sourceSteps,
) {
  final steps = sourceSteps.toList(growable: false);
  final remainingPlayerQuantity =
      <(GameOrderBookSide side, double price), int>{};
  for (final step in steps) {
    remainingPlayerQuantity.update(
      (step.side, step.price),
      (quantity) => quantity + step.consumedQuantity,
      ifAbsent: () => step.consumedQuantity,
    );
  }
  return List<int>.unmodifiable([
    for (final step in steps)
      step.remainingQuantity +
          remainingPlayerQuantity.update((
            step.side,
            step.price,
          ), (quantity) => math.max(0, quantity - step.consumedQuantity)),
  ]);
}

double _orderBookPriceChangeRate(double price, double previousClose) =>
    gameOrderBookPriceChangePercent(price: price, previousClose: previousClose);

String _orderBookPriceRateLabel(double price, double previousClose) {
  final rate = _orderBookPriceChangeRate(price, previousClose);
  return '${rate.abs() < 0.005 ? '0.00' : rate.toStringAsFixed(2)}%';
}

Color _orderBookPriceRateColor(double price, double previousClose) {
  final rate = _orderBookPriceChangeRate(price, previousClose);
  if (rate > 0.004999) return const Color(0xFFF04452);
  if (rate < -0.004999) return _marketAccent;
  return const Color(0xFF8A919E);
}

enum _QuoteQuantityPreset { one, ten, quarter, maximum }

List<GameOrderBookLevel> _symmetricVisibleOrderBookLevels(
  GameOrderBookSnapshot snapshot,
) => <GameOrderBookLevel>[
  ...snapshot.asks
      .take(_visibleOrderBookSideRows)
      .toList(growable: false)
      .reversed,
  ...snapshot.bids.take(_visibleOrderBookSideRows),
];

/// Keeps the last complete ladder visible while a FIFO cancellation packet
/// briefly carries no rows of its own.
///
/// A cancellation-only replay is presentation state, not a closed market.
/// Returning an empty list for that intermediate frame collapses the ladder's
/// height and makes the whole order book flash white.
List<GameOrderBookLevel> stableOrderBookPresentationLevels({
  required GameOrderBookSnapshot snapshot,
  GameOrderBookSnapshot? fallbackSnapshot,
}) {
  final current = _symmetricVisibleOrderBookLevels(snapshot);
  if (current.isNotEmpty || fallbackSnapshot == null) return current;
  return _symmetricVisibleOrderBookLevels(fallbackSnapshot);
}

class _MarketCapRanking {
  const _MarketCapRanking({required this.rank, required this.companyCount});

  final int? rank;
  final int companyCount;
}

typedef _DailyMarketCapSnapshot = ({
  Map<String, int> values,
  Map<String, _MarketCapRanking> rankings,
});

typedef _LiveMarketIndex = ({
  String label,
  double level,
  double rate,
  double referenceCapitalization,
});

class _PlayerOrderBookPrint {
  const _PlayerOrderBookPrint({
    required this.levelSide,
    required this.price,
    required this.quantity,
  });

  final GameOrderBookSide levelSide;
  final double price;
  final int quantity;
}

class _PlayerTradeSignal {
  const _PlayerTradeSignal({
    required this.assetId,
    required this.side,
    required this.quantity,
    required this.price,
    required this.marketMinute,
    required this.microstructureFrame,
    this.orderBookPrint,
    this.orderBookSweepSteps = const <GameOrderBookSweepStep>[],
    this.orderBookReplaySnapshot,
    this.replayIdentity = '',
    this.playerOwnedDepthOnly = false,
  });

  final String assetId;
  final TradeSide side;
  final double quantity;
  final double price;
  final int marketMinute;
  final int microstructureFrame;
  final _PlayerOrderBookPrint? orderBookPrint;
  final List<GameOrderBookSweepStep> orderBookSweepSteps;
  final GameOrderBookSnapshot? orderBookReplaySnapshot;
  final String replayIdentity;
  final bool playerOwnedDepthOnly;
}

class _OrderBookTapePrint {
  const _OrderBookTapePrint({
    required this.sessionKey,
    required this.marketMinute,
    required this.microstructureFrame,
    required this.price,
    required this.previousPrice,
    required this.quantity,
    required this.side,
    required this.isPlayer,
    this.sequence = 0,
    this.executionIdentity = '',
  });

  final String sessionKey;
  final int marketMinute;
  final int microstructureFrame;
  final double price;
  final double previousPrice;
  final int quantity;
  final TradeSide side;
  final bool isPlayer;
  final int sequence;
  final String executionIdentity;

  String get identity =>
      '$sessionKey:$marketMinute:$microstructureFrame:$sequence:${side.name}:'
      '${price.toStringAsFixed(6)}:$quantity:${isPlayer ? 'player' : 'market'}:'
      '$executionIdentity';
}

double _tradeTapeExecutionStrength(Iterable<_OrderBookTapePrint> prints) {
  var buyQuantity = 0;
  var sellQuantity = 0;
  for (final print in prints) {
    if (print.side == TradeSide.buy) {
      buyQuantity += print.quantity;
    } else {
      sellQuantity += print.quantity;
    }
  }
  return gameOrderBookExecutionStrength(
    buyQuantity: buyQuantity,
    sellQuantity: sellQuantity,
  );
}

double _tradeTapeTurnoverEok(Iterable<_OrderBookTapePrint> prints) =>
    prints.fold<double>(
      0,
      (sum, print) => sum + (print.price * print.quantity / 100000000),
    );

_PlayerTradeSignal? _playerTradeSignalForLedgerEntry(
  LedgerEntry entry, {
  required int microstructureFrame,
  GameOrderBookSnapshot? orderBookSnapshot,
}) {
  if (entry.assetId.isEmpty ||
      !entry.tradeQuantity.isFinite ||
      entry.tradeQuantity <= 0 ||
      !entry.tradeUnitPrice.isFinite ||
      entry.tradeUnitPrice <= 0 ||
      (entry.tradeSide != TradeSide.buy.name &&
          entry.tradeSide != TradeSide.sell.name)) {
    return null;
  }
  final validFills = entry.orderBookFills
      .where(
        (fill) =>
            fill.price.isFinite &&
            fill.price > 0 &&
            fill.quantity.isFinite &&
            fill.quantity > 0,
      )
      .toList(growable: false);
  final side = entry.tradeSide == TradeSide.buy.name
      ? TradeSide.buy
      : TradeSide.sell;
  var playerOwnedDepthOnly = false;
  GameOrderBookSide? levelSide;
  LedgerOrderBookFill? exactFill;
  if (validFills.isNotEmpty &&
      (entry.orderBookSide == GameOrderBookSide.ask.name ||
          entry.orderBookSide == GameOrderBookSide.bid.name)) {
    levelSide = entry.orderBookSide == GameOrderBookSide.ask.name
        ? GameOrderBookSide.ask
        : GameOrderBookSide.bid;
    exactFill = validFills.last;
  } else if (validFills.isEmpty &&
      entry.orderType == TradeOrderType.limit.name &&
      entry.marketMinute >= krxOpenMinute &&
      entry.marketMinute < krxContinuousEndMinute) {
    playerOwnedDepthOnly = true;
    // A resting limit order is part of the player's own-side displayed depth.
    // When it fills, that same-side row loses the order quantity even though
    // the exchange ledger has no aggressive standing-book fill record.
    levelSide = side == TradeSide.buy
        ? GameOrderBookSide.bid
        : GameOrderBookSide.ask;
    exactFill = LedgerOrderBookFill(
      price: entry.tradeUnitPrice,
      quantity: entry.tradeQuantity,
    );
  }
  final exactQuantity = exactFill?.quantity;
  final hasWholeSharePrint =
      exactQuantity != null &&
      (exactQuantity - exactQuantity.roundToDouble()).abs() < 0.000001;
  GameOrderBookLevel? sourceLevelFor(double price) {
    if (levelSide == null || orderBookSnapshot == null) return null;
    final visibleLevels = levelSide == GameOrderBookSide.ask
        ? orderBookSnapshot.asks
        : orderBookSnapshot.bids;
    final visible = visibleLevels
        .where((level) => (level.price - price).abs() < 0.000001)
        .firstOrNull;
    if (visible != null) return visible;
    final remembered = orderBookSnapshot.rememberedLevels[price];
    return remembered?.side == levelSide ? remembered : null;
  }

  final sweepSteps = <GameOrderBookSweepStep>[];
  final replayFills = validFills.isNotEmpty
      ? validFills
      : exactFill == null
      ? const <LedgerOrderBookFill>[]
      : <LedgerOrderBookFill>[exactFill];
  if (levelSide != null && replayFills.isNotEmpty) {
    final remainingByPrice = <double, int>{};
    for (final fillEntry in replayFills.asMap().entries) {
      final fill = fillEntry.value;
      if ((fill.quantity - fill.quantity.roundToDouble()).abs() >= 0.000001) {
        sweepSteps.clear();
        break;
      }
      final consumedQuantity = fill.quantity.round();
      final sourceLevel = sourceLevelFor(fill.price);
      final sourceQuantity = sourceLevel?.quantity ?? 0;
      final beforeQuantity = playerOwnedDepthOnly
          ? sourceQuantity + consumedQuantity
          : remainingByPrice[fill.price] ??
                sourceQuantity.clamp(consumedQuantity, 1 << 31);
      final remainingQuantity = playerOwnedDepthOnly
          ? sourceQuantity
          : math.max(0, beforeQuantity - consumedQuantity);
      remainingByPrice[fill.price] = remainingQuantity;
      final recoveryBaseline = sourceLevel == null
          ? beforeQuantity
          : math.max(
              sourceLevel.quantity,
              sourceLevel.queueRecoveryTargetQuantity,
            );
      final structuralBreach =
          sourceLevel?.isStructuralBreached == true ||
          (sourceLevel?.isStructuralWall == true &&
              recoveryBaseline > 0 &&
              remainingQuantity <= recoveryBaseline * 0.10);
      sweepSteps.add(
        GameOrderBookSweepStep(
          marketMinute: entry.marketMinute,
          liquidityPulse: math.max(0, microstructureFrame),
          sequence: fillEntry.key,
          side: levelSide,
          price: fill.price,
          consumedQuantity: consumedQuantity,
          remainingQuantity: remainingQuantity,
          structuralBreach: structuralBreach,
          boundaryCrossed:
              !playerOwnedDepthOnly &&
              (remainingQuantity <= 0 || structuralBreach),
        ),
      );
    }
  }
  return _PlayerTradeSignal(
    assetId: entry.assetId,
    side: side,
    quantity: entry.tradeQuantity,
    price: entry.tradeUnitPrice,
    marketMinute: entry.marketMinute,
    microstructureFrame: math.max(0, microstructureFrame),
    orderBookPrint:
        levelSide == null || exactFill == null || !hasWholeSharePrint
        ? null
        : _PlayerOrderBookPrint(
            levelSide: levelSide,
            price: exactFill.price,
            quantity: exactFill.quantity.round(),
          ),
    orderBookSweepSteps: List<GameOrderBookSweepStep>.unmodifiable(sweepSteps),
    orderBookReplaySnapshot: orderBookSnapshot,
    replayIdentity: entry.id,
    playerOwnedDepthOnly: playerOwnedDepthOnly,
  );
}

_PlayerTradeSignal? _latestPlayerTradeSignalForOrder(
  GameState state, {
  required String assetId,
  required TradeSide side,
  required int marketMinute,
  required int microstructureFrame,
  int minimumLedgerIndex = 0,
  GameOrderBookSnapshot? orderBookSnapshot,
}) => state.ledger
    .skip(minimumLedgerIndex.clamp(0, state.ledger.length))
    .toList(growable: false)
    .reversed
    .map(
      (entry) => _playerTradeSignalForLedgerEntry(
        entry,
        microstructureFrame: microstructureFrame,
        orderBookSnapshot: orderBookSnapshot,
      ),
    )
    .whereType<_PlayerTradeSignal>()
    .where(
      (signal) =>
          signal.assetId == assetId &&
          signal.side == side &&
          signal.marketMinute == marketMinute,
    )
    .firstOrNull;

const _marketInk = Color(0xFF191F28);
const _marketMuted = Color(0xFF6B7684);
const _marketLine = Color(0xFFE8EBEF);
const _marketSurface = Color(0xFFF7F8FA);
const _marketAccent = Color(0xFF356FE5);
const _marketNumberFeatures = <ui.FontFeature>[ui.FontFeature.tabularFigures()];

class _CrtTradingRoomScene extends StatelessWidget {
  const _CrtTradingRoomScene({
    required this.minuteListenable,
    required this.child,
  });

  final ValueListenable<int> minuteListenable;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    return Theme(
      data: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(primary: _marketAccent),
        textTheme: baseTheme.textTheme.apply(fontFamily: 'Pretendard'),
        primaryTextTheme: baseTheme.primaryTextTheme.apply(
          fontFamily: 'Pretendard',
        ),
      ),
      child: Scaffold(
        backgroundColor: _marketSurface,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: ColoredBox(
                color: Colors.white,
                child: Column(
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: minuteListenable,
                      builder: (context, minute, _) =>
                          _MarketPhoneStatusBar(minute: minute),
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketPreparingScreen extends StatelessWidget {
  const _MarketPreparingScreen({
    required this.progress,
    required this.stage,
    required this.year,
  });

  final double progress;
  final String stage;
  final int year;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('market-preparing-screen'),
    backgroundColor: const Color(0xFFF3F6FB),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDCE4F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F274A78),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE7A4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.candlestick_chart_rounded,
                    color: Color(0xFF33405F),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '$year년 가상시장을 준비하고 있어요',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF273553),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stage,
                  key: const Key('market-loading-stage'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF66728A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    key: const Key('market-loading-progress'),
                    value: progress.clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE9EDF5),
                    color: const Color(0xFF5B78B8),
                  ),
                ),
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(progress.clamp(0, 1) * 100).round()}%',
                    key: const Key('market-loading-percent'),
                    style: const TextStyle(
                      color: Color(0xFF536A96),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '화면은 멈춘 것이 아니며, 준비가 끝나면 자동으로 첫 주식 수업이 열립니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8A94A8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _MarketPhoneStatusBar extends StatelessWidget {
  const _MarketPhoneStatusBar({required this.minute});

  final int minute;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('market-phone-status-bar'),
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 15),
    color: Colors.white,
    child: Row(
      children: [
        Text(
          marketTimeLabel(minute),
          key: const Key('market-phone-status-time'),
          style: const TextStyle(
            color: _marketInk,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            fontFeatures: _marketNumberFeatures,
          ),
        ),
        const Spacer(),
        const Icon(
          Icons.signal_cellular_alt_rounded,
          size: 15,
          color: Color(0xFF171B24),
        ),
        const SizedBox(width: 5),
        const Icon(Icons.wifi_rounded, size: 16, color: Color(0xFF171B24)),
        const SizedBox(width: 5),
        const Icon(
          Icons.battery_full_rounded,
          size: 17,
          color: Color(0xFF171B24),
        ),
      ],
    ),
  );
}

enum _MarketPlaybackSpeed {
  paused(minutesPerSecond: 0, label: '정지'),
  normal(minutesPerSecond: 1, label: '1배'),
  triple(minutesPerSecond: 3, label: '3배'),
  tenfold(minutesPerSecond: 10, label: '10배');

  const _MarketPlaybackSpeed({
    required this.minutesPerSecond,
    required this.label,
  });

  final int minutesPerSecond;
  final String label;
}

class _MarketHomeAppBar extends StatelessWidget {
  const _MarketHomeAppBar({
    required this.onBack,
    required this.minute,
    required this.tradingDay,
    required this.onAdvanceHour,
    required this.onJumpToOpen,
    required this.onJumpToClose,
  });

  final VoidCallback onBack;
  final int minute;
  final bool tradingDay;
  final VoidCallback? onAdvanceHour;
  final VoidCallback? onJumpToOpen;
  final VoidCallback? onJumpToClose;

  @override
  Widget build(BuildContext context) {
    final info = marketClockAt(minute, tradingDay: tradingDay);
    return Container(
      key: const Key('market-home-app-bar'),
      height: 66,
      padding: const EdgeInsets.fromLTRB(4, 0, 7, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F1F3))),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('close-stock-market'),
            tooltip: '주식시장 닫기',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          const SizedBox(width: 1),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '밀레니엄 증권',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _marketInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: info.tradable
                            ? const Color(0xFF00B875)
                            : const Color(0xFF9AA3B1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '${info.label} · ${marketTimeLabel(minute)}',
                        key: const Key('market-header-status'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7B8491),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFeatures: _marketNumberFeatures,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            key: const Key('market-clock-bar'),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: '장 시작 09:00',
                  child: FilledButton(
                    key: const Key('market-jump-open-button'),
                    onPressed: onJumpToOpen,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(43, 38),
                      maximumSize: const Size(43, 38),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      backgroundColor: const Color(0xFFE6F0FF),
                      foregroundColor: _marketAccent,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: const Color(0xFFB3BAC4),
                    ),
                    child: const Text(
                      '09:00',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        fontFeatures: _marketNumberFeatures,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: '1시간 진행',
                  child: TextButton(
                    key: const Key('market-advance-hour-button'),
                    onPressed: onAdvanceHour,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(43, 38),
                      maximumSize: const Size(43, 38),
                      padding: EdgeInsets.zero,
                      foregroundColor: const Color(0xFF4C596A),
                      disabledForegroundColor: const Color(0xFFB3BAC4),
                    ),
                    child: const Text(
                      '+1시간',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: '장 마감 15:00',
                  child: FilledButton(
                    key: const Key('market-jump-close-button'),
                    onPressed: onJumpToClose,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(43, 38),
                      maximumSize: const Size(43, 38),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      backgroundColor: const Color(0xFFEAF8F1),
                      foregroundColor: const Color(0xFF168A5B),
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: const Color(0xFFB3BAC4),
                    ),
                    child: const Text(
                      '15:00',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        fontFeatures: _marketNumberFeatures,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketPlaybackBar extends StatelessWidget {
  const _MarketPlaybackBar({
    required this.speed,
    required this.enabled,
    required this.onChanged,
  });

  final _MarketPlaybackSpeed speed;
  final bool enabled;
  final ValueChanged<_MarketPlaybackSpeed> onChanged;

  Key _keyFor(_MarketPlaybackSpeed value) => switch (value) {
    _MarketPlaybackSpeed.paused => const Key('market-speed-pause'),
    _MarketPlaybackSpeed.normal => const Key('market-speed-1x'),
    _MarketPlaybackSpeed.triple => const Key('market-speed-3x'),
    _MarketPlaybackSpeed.tenfold => const Key('market-speed-10x'),
  };

  String _tooltipFor(_MarketPlaybackSpeed value) => switch (value) {
    _MarketPlaybackSpeed.paused => '시장 시간 일시정지',
    _MarketPlaybackSpeed.normal => '현실 1초에 게임 1분',
    _MarketPlaybackSpeed.triple => '현실 1초에 게임 3분',
    _MarketPlaybackSpeed.tenfold => '현실 1초에 게임 10분',
  };

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('market-speed-controls'),
    height: 44,
    padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFF0F1F3))),
    ),
    child: Row(
      children: [
        const Icon(Icons.speed_rounded, size: 16, color: Color(0xFF687385)),
        const SizedBox(width: 5),
        const Text(
          '시간',
          style: TextStyle(
            color: Color(0xFF687385),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                for (final value in _MarketPlaybackSpeed.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Tooltip(
                        message: _tooltipFor(value),
                        child: Semantics(
                          selected: speed == value,
                          button: true,
                          child: SizedBox(
                            height: 28,
                            child: TextButton(
                              key: _keyFor(value),
                              onPressed: enabled
                                  ? () => onChanged(value)
                                  : null,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: speed == value
                                    ? Colors.white
                                    : const Color(0xFF4C596A),
                                disabledForegroundColor: const Color(
                                  0xFFB3BAC4,
                                ),
                                backgroundColor: speed == value
                                    ? _marketAccent
                                    : Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                value.label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: _marketNumberFeatures,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _MarketNewsTicker extends StatelessWidget {
  const _MarketNewsTicker({required this.event});

  final FictionalMarketEvent event;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('background-news-ticker'),
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      color: Color(0xFFFFF8E3),
      border: Border(bottom: BorderSide(color: Color(0xFFF1E4B8))),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF04452),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Text(
            '속보',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              '${event.companyName} · ${event.title}',
              key: ValueKey<String>(event.id),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF4C4328),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

typedef MarketUniverseLoader =
    Future<FictionalMarketUniverse> Function({
      required String seed,
      required DateTime? throughDate,
      required bool forceRefresh,
    });

typedef _OrderBookSessionSnapshot = ({
  GameOrderBookSnapshot snapshot,
  int minute,
  double price,
  int microstructureFrame,
  String sessionKey,
});

typedef _OrderBookConsumptionView = ({
  Map<double, double> asks,
  Map<double, double> bids,
  int capacityUnits,
  GameOrderBookSide? latestSide,
  double? latestPrice,
});

/// Keeps deterministic order-book continuity while stock-market routes are
/// opened and closed within the same running game.
///
/// The detail screen still validates each snapshot's simulation seed and
/// market date before restoring it, so a cache retained across a day or world
/// change cannot leak stale depth into the new session.
class StockOrderBookSessionCache {
  final Map<String, _OrderBookSessionSnapshot> _snapshots =
      <String, _OrderBookSessionSnapshot>{};
  final Map<String, List<_OrderBookTapePrint>> _tradeTapes =
      <String, List<_OrderBookTapePrint>>{};
  final Map<String, _OrderBookSweepJournal> _sweepJournals =
      <String, _OrderBookSweepJournal>{};

  _OrderBookSessionSnapshot? _snapshotFor(String assetId) =>
      _snapshots[assetId];

  void _remember(String assetId, _OrderBookSessionSnapshot snapshot) {
    _snapshots[assetId] = snapshot;
  }

  List<_OrderBookTapePrint> _tradeTapeFor(String assetId) =>
      _tradeTapes[assetId] ?? const <_OrderBookTapePrint>[];

  void _rememberTradeTape(String assetId, List<_OrderBookTapePrint> tradeTape) {
    _tradeTapes[assetId] = List<_OrderBookTapePrint>.unmodifiable(tradeTape);
  }

  _OrderBookSweepJournal _sweepJournalFor(String assetId, String sessionKey) {
    final journal = _sweepJournals.putIfAbsent(
      assetId,
      () => _OrderBookSweepJournal(sessionKey),
    );
    journal.ensureSession(sessionKey);
    return journal;
  }
}

class StockMarketScreen extends StatefulWidget {
  const StockMarketScreen({
    super.key,
    required this.state,
    this.onExecuteTrade,
    this.onCancelPendingOrder,
    this.onTransferCash,
    this.onSetMarketMinute,
    this.onSaveMarketNotebook,
    this.onSetRightsIssuePreference,
    this.onPurchaseReport,
    this.onCompleteTutorial,
    this.universe,
    this.universeLoader,
    this.orderBookSessionCache,
  });

  final GameState state;
  final Future<GameState> Function(int)? onSetMarketMinute;
  final Future<GameState> Function(Set<String>, Map<String, String>)?
  onSaveMarketNotebook;
  final Future<GameState> Function(bool subscribe)? onSetRightsIssuePreference;
  final Future<FinanceActionResult> Function()? onPurchaseReport;
  final Future<GameState> Function()? onCompleteTutorial;
  final Future<TradeExecutionResult> Function(TradeOrder)? onExecuteTrade;
  final Future<FinanceActionResult> Function(String orderId)?
  onCancelPendingOrder;
  final Future<FinanceActionResult> Function(int amount, bool deposit)?
  onTransferCash;
  final FictionalMarketUniverse? universe;
  final MarketUniverseLoader? universeLoader;
  final StockOrderBookSessionCache? orderBookSessionCache;

  @override
  State<StockMarketScreen> createState() => _StockMarketScreenState();
}

class _StockMarketScreenState extends State<StockMarketScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final Map<String, ValueNotifier<_LiveStock>> _live = {};
  late final StockOrderBookSessionCache _orderBookSessionCache;
  List<_StockDefinition> _stocks = const [];
  Map<String, int> _dailyMarketCaps = const <String, int>{};
  Map<String, _MarketCapRanking> _dailyMarketCapRankings =
      const <String, _MarketCapRanking>{};
  List<LedgerEntry>? _cachedTradeLedgerSource;
  List<LedgerEntry> _cachedTradeLedgerEntries = const <LedgerEntry>[];
  Timer? _timer;
  final ValueNotifier<_MarketPlaybackSpeed> _playbackSpeedNotifier =
      ValueNotifier(_MarketPlaybackSpeed.normal);
  final ValueNotifier<Map<String, _PlayerTradeSignal>> _playerTradeNotifier =
      ValueNotifier(const <String, _PlayerTradeSignal>{});
  final Map<String, int> _playerSweepRemainingByLevel = <String, int>{};
  int _playerTradeReplaySequence = 0;
  Future<void> _marketMutationTail = Future<void>.value();
  bool _isRealtimeBatchUpdating = false;
  bool _isLifecyclePaused = false;
  bool _isLifecycleSaving = false;
  final ValueNotifier<int> _minute = ValueNotifier(marketDayStartMinute);
  // Publishes only after every live quote has settled for the minute. UI
  // sections listen here so the simulation clock cannot rebuild the scene
  // once before and once after its quote batch.
  final ValueNotifier<int> _presentationMinute = ValueNotifier(
    marketDayStartMinute,
  );
  int _tick = 0;
  late int _marketMinute;
  late int _lastPersistedMarketMinute;
  late final ValueNotifier<GameState> _marketStateNotifier;
  GameState get _state => _marketStateNotifier.value;
  set _state(GameState value) => _marketStateNotifier.value = value;

  int _tab = 0;
  _MarketSort _sort = _MarketSort.turnover;
  _MarketSection _section = _MarketSection.home;
  bool _loading = true;
  bool _marketLoadInFlight = false;
  double _loadProgress = 0.08;
  String _loadStage = '가상 기업 명단을 확인하는 중…';
  String? _loadError;
  bool _isClosing = false;
  bool _allowPop = false;
  bool _isAdvancingHour = false;
  bool _closeAfterHourAdvance = false;
  bool _isSavingRightsPreference = false;
  bool _isExecutingTrade = false;
  bool _isTransferringCash = false;
  bool _closeAfterTrade = false;
  bool _isPurchasingReport = false;
  int _marketNotebookSaveCount = 0;
  Set<String>? _favoriteDraft;
  Map<String, String>? _researchNotesDraft;
  bool _isShowingSessionNotice = false;
  bool _isShowingBreakingNews = false;
  final Set<String> _shownBreakingNewsEventIds = <String>{};
  FictionalMarketEvent? _latestBackgroundNews;
  bool _isMarketSheetOpen = false;
  String? _openedAssetId;
  final Set<int> _shownSessionNotices = <int>{};
  final GlobalKey _tutorialExploreKey = GlobalKey();
  final GlobalKey _tutorialStockKey = GlobalKey();
  int? _tutorialStep;

  bool get _tutorialActive => _tutorialStep != null;
  _MarketPlaybackSpeed get _playbackSpeed => _playbackSpeedNotifier.value;

  set _playbackSpeed(_MarketPlaybackSpeed value) {
    _playbackSpeedNotifier.value = value;
  }

  bool get _hasDomesticTradingSession =>
      isMarketTradingDay(_state.currentDate) &&
      _stocks.any(
        (stock) =>
            stock.country == 'KR' &&
            (_live[stock.code]?.value.isTradingDay ?? false),
      );

  void _setPlaybackSpeed(_MarketPlaybackSpeed speed) {
    if (_playbackSpeed == speed) return;
    if (speed != _MarketPlaybackSpeed.paused &&
        (_isLifecyclePaused ||
            _isRealtimeBatchUpdating ||
            _isAdvancingHour ||
            _isClosing ||
            _isExecutingTrade ||
            _isTransferringCash ||
            _isPurchasingReport ||
            _marketNotebookSaveCount > 0 ||
            _isMarketSheetOpen)) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    if (mounted) {
      setState(() => _playbackSpeed = speed);
    } else {
      _playbackSpeed = speed;
    }
    _resumeTimerIfNeeded();
  }

  void _pausePlaybackWithoutRebuild() {
    _playbackSpeed = _MarketPlaybackSpeed.paused;
    _timer?.cancel();
    _timer = null;
  }

  Future<T> _runMarketMutation<T>(Future<T> Function() action) {
    final operation = _marketMutationTail.then((_) => action());
    _marketMutationTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  GameOrderBookSnapshot? _playerReplaySnapshotFor({
    required GameState state,
    required String assetId,
    required int marketMinute,
    required _OrderBookSessionSnapshot? cached,
  }) {
    final expectedSessionKey =
        '${state.simulationSeed}:${marketDateKey(state.currentDate)}';
    if (cached == null ||
        cached.sessionKey != expectedSessionKey ||
        cached.minute > marketMinute) {
      return null;
    }
    // A resting order can fill on the next clock tick before the detail cache
    // publishes that minute. Preserve the last book the player actually saw
    // instead of animating the player-owned depth against an empty 0-row.
    return gameOrderBookSnapshotAfterConsumption(
      snapshot: cached.snapshot,
      consumedAskByPrice: gameConsumedOrderBookUnitsByPrice(
        state,
        assetId: assetId,
        marketMinute: marketMinute,
        bookSide: GameOrderBookSide.ask,
      ),
      consumedBidByPrice: gameConsumedOrderBookUnitsByPrice(
        state,
        assetId: assetId,
        marketMinute: marketMinute,
        bookSide: GameOrderBookSide.bid,
      ),
      consumedCapacityUnits: gameConsumedOrderBookFillUnits(
        state,
        assetId: assetId,
        marketMinute: marketMinute,
        side: TradeSide.buy,
      ),
      retainSyntheticTombstone: false,
    );
  }

  List<_PlayerTradeSignal> _newTradeSignals(GameState before, GameState after) {
    final signals = <_PlayerTradeSignal>[];
    for (final entry in after.ledger.skip(before.ledger.length)) {
      final cached = _orderBookSessionCache._snapshotFor(entry.assetId);
      final hasMatchingFrame =
          cached != null &&
          cached.sessionKey ==
              '${after.simulationSeed}:${marketDateKey(after.currentDate)}' &&
          entry.marketMinute == cached.minute;
      final signal = _playerTradeSignalForLedgerEntry(
        entry,
        microstructureFrame: hasMatchingFrame
            ? cached.microstructureFrame
            : gameOrderBookLiquidityPulseFrame(
                marketMinute: entry.marketMinute,
                slotIndex: 0,
              ),
        orderBookSnapshot: _playerReplaySnapshotFor(
          state: before,
          assetId: entry.assetId,
          marketMinute: entry.marketMinute,
          cached: cached,
        ),
      );
      if (signal != null) signals.add(signal);
    }
    return List<_PlayerTradeSignal>.unmodifiable(signals);
  }

  void _publishPlayerTradeSignals(Iterable<_PlayerTradeSignal> signals) {
    final batch = signals.toList(growable: false);
    final grouped =
        <
          (String assetId, int marketMinute, int frame),
          List<_PlayerTradeSignal>
        >{};
    for (final signal in batch) {
      grouped
          .putIfAbsent((
            signal.assetId,
            signal.marketMinute,
            signal.microstructureFrame,
          ), () => <_PlayerTradeSignal>[])
          .add(signal);
    }
    final next = <String, _PlayerTradeSignal>{..._playerTradeNotifier.value};
    for (final matchingSignals in grouped.values) {
      final latest = matchingSignals.last;
      final latestPrint = latest.orderBookPrint;
      final combinedSweepSteps = <GameOrderBookSweepStep>[];
      final passiveRemainingQuantities =
          playerOwnedOrderBookRemainingQuantities([
            for (final signal in matchingSignals)
              if (signal.playerOwnedDepthOnly) ...signal.orderBookSweepSteps,
          ]);
      var passiveStepIndex = 0;
      for (final signal in matchingSignals) {
        for (final step in signal.orderBookSweepSteps) {
          final levelIdentity =
              '${signal.assetId}:${signal.marketMinute}:'
              '${signal.microstructureFrame}:${step.side.name}:'
              '${step.price.toStringAsFixed(6)}';
          final beforeQuantity =
              _playerSweepRemainingByLevel[levelIdentity] ??
              step.consumedQuantity + step.remainingQuantity;
          final remainingQuantity = signal.playerOwnedDepthOnly
              ? passiveRemainingQuantities[passiveStepIndex++]
              : math.max(0, beforeQuantity - step.consumedQuantity);
          _playerSweepRemainingByLevel[levelIdentity] = remainingQuantity;
          combinedSweepSteps.add(
            GameOrderBookSweepStep(
              marketMinute: step.marketMinute,
              liquidityPulse: step.liquidityPulse,
              sequence: combinedSweepSteps.length,
              side: step.side,
              price: step.price,
              consumedQuantity: step.consumedQuantity,
              remainingQuantity: remainingQuantity,
              structuralBreach: step.structuralBreach,
              boundaryCrossed:
                  !signal.playerOwnedDepthOnly &&
                  (remainingQuantity <= 0 || step.boundaryCrossed),
            ),
          );
        }
      }
      while (_playerSweepRemainingByLevel.length > 512) {
        _playerSweepRemainingByLevel.remove(
          _playerSweepRemainingByLevel.keys.first,
        );
      }
      final replayIdentityParts = matchingSignals
          .map((signal) => signal.replayIdentity)
          .where((identity) => identity.isNotEmpty)
          .toList(growable: false);
      next[latest.assetId] = _PlayerTradeSignal(
        assetId: latest.assetId,
        side: latest.side,
        quantity: latest.quantity,
        price: latest.price,
        marketMinute: latest.marketMinute,
        microstructureFrame: latest.microstructureFrame,
        orderBookReplaySnapshot: matchingSignals
            .map((signal) => signal.orderBookReplaySnapshot)
            .whereType<GameOrderBookSnapshot>()
            .firstOrNull,
        replayIdentity: replayIdentityParts.isEmpty
            ? 'player-${_playerTradeReplaySequence++}'
            : replayIdentityParts.join('|'),
        playerOwnedDepthOnly: matchingSignals.every(
          (signal) => signal.playerOwnedDepthOnly,
        ),
        orderBookSweepSteps: List<GameOrderBookSweepStep>.unmodifiable(
          combinedSweepSteps,
        ),
        orderBookPrint: latestPrint == null
            ? null
            : _PlayerOrderBookPrint(
                levelSide: latestPrint.levelSide,
                price: latestPrint.price,
                quantity: matchingSignals
                    .where(
                      (signal) =>
                          signal.orderBookPrint?.levelSide ==
                              latestPrint.levelSide &&
                          (signal.orderBookPrint!.price - latestPrint.price)
                                  .abs() <
                              0.000001,
                    )
                    .fold<int>(
                      0,
                      (sum, signal) =>
                          sum + (signal.orderBookPrint?.quantity ?? 0),
                    ),
              ),
      );
      _playerTradeNotifier.value = Map<String, _PlayerTradeSignal>.unmodifiable(
        next,
      );
    }
  }

  List<double> _sessionPathWithPlayerMarketImpact({
    required _StockDefinition stock,
    required List<double> sourcePath,
    required double previousClose,
    required Iterable<LedgerEntry> entries,
  }) {
    if (sourcePath.isEmpty || previousClose <= 0) {
      return List<double>.from(sourcePath);
    }
    final impacted = List<double>.from(sourcePath);
    final range = marketDailyPriceRange(
      previousClose: previousClose,
      date: _state.currentDate,
      market: stock.market,
      isIpoFirstTradingDay: stock.asset.isIpoFirstTradingDay(
        _state.currentDate,
      ),
    );
    final sharesOutstanding = stock.asset.sharesOutstandingAtOrBefore(
      _state.currentDate,
    );
    for (final entry in entries) {
      final isBuy = entry.tradeSide == TradeSide.buy.name;
      final isSell = entry.tradeSide == TradeSide.sell.name;
      if (entry.day != _state.day ||
          entry.assetId != stock.id ||
          (!isBuy && !isSell) ||
          !entry.tradeQuantity.isFinite ||
          entry.tradeQuantity <= 0 ||
          entry.marketMinute < krxOpenMinute ||
          entry.marketMinute >= krxContinuousEndMinute) {
        continue;
      }
      final referencePrice =
          entry.tradeUnitPrice.isFinite && entry.tradeUnitPrice > 0
          ? entry.tradeUnitPrice
          : previousClose;
      final executionCapacity = gameOrderBookExecutionCapacity(
        assetId: stock.id,
        day: marketLiquidityDayKey(_state.currentDate),
        minute: entry.marketMinute,
        unitPrice: referencePrice,
        previousClose: previousClose,
        simulationSeed: _state.simulationSeed,
        sharesOutstanding: sharesOutstanding,
      );
      final initialTicks = gamePlayerMarketImpactInitialTicks(
        filledQuantity: entry.tradeQuantity,
        executionCapacity: executionCapacity,
      );
      if (initialTicks <= 0) continue;
      for (
        var ageMinutes = 1;
        ageMinutes <= gamePlayerMarketImpactDurationMinutes;
        ageMinutes += 1
      ) {
        final affectedMinute = entry.marketMinute + ageMinutes;
        if (affectedMinute >= krxContinuousEndMinute) break;
        final pathIndex = marketTickForMinute(affectedMinute);
        if (pathIndex < 0 || pathIndex >= impacted.length) continue;
        final decayedTicks = gamePlayerMarketImpactTicksAtAge(
          initialTicks: initialTicks,
          ageMinutes: ageMinutes,
        );
        final signedTicks = isBuy ? decayedTicks : -decayedTicks;
        final shifted = gameOrderBookPriceAfterTickImpact(
          basePrice: impacted[pathIndex],
          signedTicks: signedTicks,
          market: stock.market,
        );
        impacted[pathIndex] = marketSnapPrice(
          shifted.clamp(range.lower, range.upper).toDouble(),
          market: stock.market,
        );
      }
    }
    return impacted;
  }

  void _applyNewPlayerMarketImpact(Iterable<LedgerEntry> entries) {
    final batch = entries
        .where(
          (entry) =>
              entry.tradeQuantity > 0 &&
              (entry.tradeSide == TradeSide.buy.name ||
                  entry.tradeSide == TradeSide.sell.name),
        )
        .toList(growable: false);
    if (batch.isEmpty) return;
    for (final stock in _stocks) {
      final stockEntries = batch.where((entry) => entry.assetId == stock.id);
      if (stockEntries.isEmpty) continue;
      final notifier = _live[stock.code];
      if (notifier == null || !notifier.value.isTradingDay) continue;
      final current = notifier.value;
      notifier.value = current.copyWith(
        sessionPath: _sessionPathWithPlayerMarketImpact(
          stock: stock,
          sourcePath: current.sessionPath,
          previousClose: current.previousClose,
          entries: stockEntries,
        ),
      );
    }
  }

  int _newExpiredOrderCount(GameState before, GameState after) => after.ledger
      .skip(before.ledger.length)
      .where((entry) => entry.counterAccount == 'day_order_expiry')
      .length;

  void _resumeTimerIfNeeded() {
    if (_timer != null ||
        _playbackSpeed == _MarketPlaybackSpeed.paused ||
        _isLifecyclePaused ||
        _isRealtimeBatchUpdating ||
        _isAdvancingHour ||
        _isClosing ||
        _isExecutingTrade ||
        _isTransferringCash ||
        _isPurchasingReport ||
        _marketNotebookSaveCount > 0 ||
        _isMarketSheetOpen ||
        _isShowingBreakingNews ||
        _isShowingSessionNotice ||
        _tutorialActive ||
        _loading ||
        _marketMinute >= krxCloseMinute ||
        _tick >= krxCloseTick ||
        !_hasDomesticTradingSession) {
      return;
    }
    _timer = Timer.periodic(marketRealtimeTickDuration, (_) {
      unawaited(_advanceRealtimeBatch());
    });
  }

  void _pauseMarketForSheet() {
    _isMarketSheetOpen = true;
    _timer?.cancel();
    _timer = null;
  }

  void _resumeMarketAfterSheet() {
    _isMarketSheetOpen = false;
    if (mounted) _resumeTimerIfNeeded();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _orderBookSessionCache =
        widget.orderBookSessionCache ?? StockOrderBookSessionCache();
    _marketStateNotifier = ValueNotifier(widget.state);
    _marketMinute = _state.marketMinute;
    _lastPersistedMarketMinute = _marketMinute;
    _minute.value = _marketMinute;
    _presentationMinute.value = _marketMinute;
    _tick = marketTickForMinute(_marketMinute);
    _tutorialStep =
        _state.story.marketTutorialEligible &&
            !_state.story.marketTutorialSeen &&
            isMarketTradingDay(_state.currentDate) &&
            widget.onCompleteTutorial != null
        ? 0
        : null;
    _loadFictionalMarket();
  }

  Future<void> _loadFictionalMarket({bool forceRefresh = false}) async {
    if (_marketLoadInFlight) return;
    _marketLoadInFlight = true;
    final stopwatch = Stopwatch()..start();
    try {
      if (forceRefresh) {
        for (final notifier in _live.values) {
          notifier.dispose();
        }
        _live.clear();
        if (mounted) {
          setState(() {
            _stocks = const [];
            _loadError = null;
            _loading = true;
            _loadProgress = 0.08;
            _loadStage = '시장 데이터를 다시 준비하는 중…';
          });
        }
      }
      // Give the browser a chance to paint the progress card before any
      // deterministic market generation begins.
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      setState(() {
        _loadProgress = 0.12;
        _loadStage = '${_state.currentDate.year}년 기업과 거래일을 만드는 중…';
      });
      final loader = widget.universeLoader;
      final loadedUniverse =
          widget.universe ??
          await (loader == null
              ? FictionalMarketUniverse.load(
                  seed: _state.simulationSeed,
                  throughDate: _state.currentDate,
                  forceRefresh: forceRefresh,
                )
              : loader(
                  seed: _state.simulationSeed,
                  throughDate: _state.currentDate,
                  forceRefresh: forceRefresh,
                ));
      final universe = loadedUniverse.asOf(_state.currentDate);
      if (!mounted) return;
      setState(() {
        _loadProgress = 0.62;
        _loadStage = '첫 거래일 시세와 차트를 계산하는 중…';
      });
      await Future<void>.delayed(Duration.zero);

      final loaded = <_StockDefinition>[];
      final assets = universe.assets;
      for (var index = 0; index < assets.length; index++) {
        final asset = assets[index];
        final quote = asset.quoteAtOrBefore(_state.currentDate);
        if (quote != null) {
          final stock = _StockDefinition.fromAsset(asset);
          final rawPreviousClose = asset.unadjustedReferenceCloseFor(
            quote.date,
          );
          final marketReferenceClose = asset.marketReferenceCloseOn(
            DateTime.parse(quote.date),
            previousClose: rawPreviousClose,
          );
          // The live list needs 13 displayed flow rows, their predecessor for
          // the oldest return, and today's possibly hidden pre-open point.
          // Long-range charts query the asset directly.
          final history = asset.historyThrough(_state.currentDate, count: 15);
          loaded.add(stock);
          final rawPath = quote.isExactDate
              ? generatedMarketDayPathForAsset(
                  asset: asset,
                  simulationSeed: _state.simulationSeed,
                  date: _state.currentDate,
                  previousClose: rawPreviousClose,
                  officialClose: quote.close,
                )
              : <double>[quote.close];
          final path = quote.isExactDate
              ? _sessionPathWithPlayerMarketImpact(
                  stock: stock,
                  sourcePath: rawPath,
                  previousClose: marketReferenceClose,
                  entries: _state.ledger,
                )
              : rawPath;
          final pathIndex = quote.isExactDate
              ? _tick.clamp(0, path.length - 1)
              : 0;
          final sessionHistory = path.take(pathIndex + 1).toList();
          final startingPrice = sessionHistory.last;
          late final List<double> tradingHistory;
          if (quote.isExactDate && pathIndex >= generatedPreOpenTicks) {
            tradingHistory = path.sublist(generatedPreOpenTicks, pathIndex + 1);
          } else if (!quote.isExactDate) {
            final settledPath = generatedMarketDayPathForAsset(
              asset: asset,
              simulationSeed: _state.simulationSeed,
              date: DateTime.parse(quote.date),
              previousClose: rawPreviousClose,
              officialClose: quote.close,
            );
            final continuousEnd = math.min(
              settledPath.length,
              generatedPreOpenTicks + generatedContinuousTradingTicks,
            );
            tradingHistory = settledPath.sublist(
              generatedPreOpenTicks,
              continuousEnd,
            )..add(quote.close);
          } else {
            tradingHistory = <double>[marketReferenceClose];
          }
          _live[stock.code] = ValueNotifier(
            _LiveStock(
              price: startingPrice,
              previousClose: marketReferenceClose,
              officialClose: quote.close,
              isTradingDay: quote.isExactDate,
              open: tradingHistory.first,
              high: tradingHistory.reduce(math.max),
              low: tradingHistory.reduce(math.min),
              history: history,
              sessionHistory: sessionHistory,
              sessionPath: path,
            ),
          );
        }
        final processed = index + 1;
        if (processed % 20 == 0 || processed == assets.length) {
          if (!mounted) return;
          setState(() {
            _loadProgress =
                0.62 + (processed / assets.length).clamp(0, 1) * 0.32;
            _loadStage = '종목 $processed/${assets.length} 준비 중…';
          });
          await Future<void>.delayed(Duration.zero);
        }
      }
      if (!mounted) return;
      final dailyMarketCaps = _buildDailyMarketCapSnapshot(loaded);
      setState(() {
        _stocks = loaded;
        _dailyMarketCaps = dailyMarketCaps.values;
        _dailyMarketCapRankings = dailyMarketCaps.rankings;
        _loadProgress = 0.99;
        _loadStage = '주식 수업 화면을 여는 중…';
      });
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      debugPrint(
        'Market prepared through ${marketDateKey(_state.currentDate)} '
        'in ${stopwatch.elapsedMilliseconds}ms',
      );
      setState(() => _loading = false);
      _resumeTimerIfNeeded();
    } catch (error) {
      _marketLoadInFlight = false;
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _loading = false;
      });
    } finally {
      _marketLoadInFlight = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final shouldPause =
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;
    if (shouldPause) {
      _isLifecyclePaused = true;
      _pausePlaybackWithoutRebuild();
      unawaited(_saveMinuteForLifecycle());
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _isLifecyclePaused = false;
      if (mounted) {
        setState(() {});
        _resumeTimerIfNeeded();
      }
    }
  }

  Future<void> _saveMinuteForLifecycle() async {
    final callback = widget.onSetMarketMinute;
    if (callback == null || _isLifecycleSaving || _isClosing) return;
    _isLifecycleSaving = true;
    try {
      final next = await _runMarketMutation(() => callback(_marketMinute));
      if (mounted) _state = next;
    } catch (_) {
      // 백그라운드 전환 중에는 UI를 띄울 수 없으므로 다음 저장에서 재시도한다.
    } finally {
      _isLifecycleSaving = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _minute.dispose();
    _presentationMinute.dispose();
    _playbackSpeedNotifier.dispose();
    _playerTradeNotifier.dispose();
    _marketStateNotifier.dispose();
    _searchController.dispose();
    for (final notifier in _live.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  Future<void> _advanceRealtimeBatch() async {
    final requestedSpeed = _playbackSpeed;
    if (_isRealtimeBatchUpdating ||
        _isAdvancingHour ||
        _isPurchasingReport ||
        _marketNotebookSaveCount > 0 ||
        requestedSpeed == _MarketPlaybackSpeed.paused) {
      return;
    }
    _isRealtimeBatchUpdating = true;
    String? pauseMessage;
    try {
      for (
        var elapsedMinute = 0;
        elapsedMinute < requestedSpeed.minutesPerSecond;
        elapsedMinute++
      ) {
        if (_playbackSpeed != requestedSpeed ||
            _isExecutingTrade ||
            _isTransferringCash ||
            _isPurchasingReport ||
            _marketNotebookSaveCount > 0 ||
            _isClosing ||
            _isMarketSheetOpen ||
            _isShowingBreakingNews ||
            _isShowingSessionNotice ||
            _marketMinute >= krxCloseMinute ||
            _tick >= krxCloseTick) {
          break;
        }
        final stateBeforeMinute = _state;
        final largeMove = _advanceOneMarketMinute();
        final callback = widget.onSetMarketMinute;
        final shouldPersistMinute =
            stateBeforeMinute.pendingOrders.isNotEmpty ||
            _marketMinute - _lastPersistedMarketMinute >= 30 ||
            _marketMinute >= krxCloseMinute;
        if (shouldPersistMinute && callback != null) {
          try {
            final next = await _runMarketMutation(
              () => callback(_marketMinute),
            );
            if (!mounted) return;
            _state = next;
            _lastPersistedMarketMinute = _marketMinute;
            _applyNewPlayerMarketImpact(
              next.ledger.skip(stateBeforeMinute.ledger.length),
            );
            final fills = _newTradeSignals(stateBeforeMinute, next);
            if (fills.isNotEmpty) {
              _publishPlayerTradeSignals(fills);
            } else {
              final expiredCount = _newExpiredOrderCount(
                stateBeforeMinute,
                next,
              );
              if (expiredCount > 0) {
                _pausePlaybackWithoutRebuild();
                pauseMessage = '장 마감으로 미체결 주문 $expiredCount건이 자동 취소됐어요.';
              }
            }
          } catch (_) {
            _pausePlaybackWithoutRebuild();
            pauseMessage = '미체결 주문을 확인하지 못해 시장 시간을 일시정지했어요.';
          }
        }
        _handleMarketTimeCrossed(marketMinuteForTick(_tick - 1), _marketMinute);
        if (pauseMessage != null ||
            _isShowingBreakingNews ||
            _isShowingSessionNotice) {
          break;
        }
        if (largeMove != null) {
          _pausePlaybackWithoutRebuild();
          pauseMessage =
              '${largeMove.name}이(가) 1분 동안 '
              '${largeMove.rate >= 0 ? '+' : ''}'
              '${largeMove.rate.toStringAsFixed(2)}% 움직여 '
              '시장 시간을 일시정지했어요.';
          break;
        }
      }
    } finally {
      _isRealtimeBatchUpdating = false;
    }
    if (pauseMessage != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(pauseMessage)));
    }
  }

  ({String name, double rate})? _advanceOneMarketMinute() {
    if (_isExecutingTrade ||
        _isTransferringCash ||
        _isClosing ||
        _marketMinute >= krxCloseMinute ||
        _tick >= krxCloseTick) {
      return null;
    }
    _tick += 1;
    _marketMinute = marketMinuteForTick(_tick);
    _minute.value = _marketMinute;
    _state = _state.copyWith(marketMinute: _marketMinute);
    final watchedAssetIds = <String>{
      ..._favoriteAssetIds,
      ..._state.positions.map((position) => position.assetId),
      ?_openedAssetId,
    };
    ({String name, double rate})? largeMove;
    for (var index = 0; index < _stocks.length; index++) {
      final stock = _stocks[index];
      final notifier = _live[stock.code]!;
      final current = notifier.value;
      if (!current.isTradingDay) continue;
      final targetPrice = current.sessionPath[_tick];
      // Minute OHLC, valuation, and persistence always settle on the
      // deterministic path. Depth walking belongs only to the sub-minute
      // detail ladder and can never change the market state by being watched.
      final nextPrice = targetPrice;
      current.sessionHistory.add(nextPrice);
      if (current.price > 0 && watchedAssetIds.contains(stock.id)) {
        final rate = (nextPrice - current.price) / current.price * 100;
        if (rate.abs() >= 3 &&
            (largeMove == null || rate.abs() > largeMove.rate.abs())) {
          largeMove = (name: stock.name, rate: rate);
        }
      }
      notifier.value = current.copyWith(
        price: nextPrice,
        open: _marketMinute == krxOpenMinute ? nextPrice : current.open,
        high: _marketMinute == krxOpenMinute
            ? nextPrice
            : nextPrice > current.high
            ? nextPrice
            : current.high,
        low: _marketMinute == krxOpenMinute
            ? nextPrice
            : nextPrice < current.low
            ? nextPrice
            : current.low,
      );
    }
    _presentationMinute.value = _marketMinute;
    return largeMove;
  }

  void _handleMarketTimeCrossed(int previousMinute, int currentMinute) {
    final events =
        fictionalMarketEventsForDate(_state.simulationSeed, _state.currentDate)
            .where(
              (event) =>
                  event.revealMinute > previousMinute &&
                  event.revealMinute <= currentMinute &&
                  !_shownBreakingNewsEventIds.contains(event.id),
            )
            .toList(growable: false);
    if (events.isEmpty || _isShowingBreakingNews) {
      _maybeShowSessionNotice(previousMinute, currentMinute);
      return;
    }
    final watchedAssetIds = <String>{
      ..._favoriteAssetIds,
      ..._state.positions.map((position) => position.assetId),
      ?_openedAssetId,
    };
    final modalEvents = events
        .where(
          (event) =>
              event.companyId == fictionalWholeMarketCompanyId ||
              watchedAssetIds.contains(event.companyId),
        )
        .toList(growable: false);
    final tickerEvents = events
        .where((event) => !modalEvents.contains(event))
        .toList(growable: false);
    if (tickerEvents.isNotEmpty) {
      _shownBreakingNewsEventIds.addAll(tickerEvents.map((event) => event.id));
      if (mounted) {
        setState(() => _latestBackgroundNews = tickerEvents.last);
      } else {
        _latestBackgroundNews = tickerEvents.last;
      }
    }
    if (modalEvents.isEmpty) {
      _maybeShowSessionNotice(previousMinute, currentMinute);
      return;
    }
    unawaited(
      _showBreakingNewsEvents(modalEvents, previousMinute, currentMinute),
    );
  }

  Future<void> _showBreakingNewsEvents(
    List<FictionalMarketEvent> events,
    int previousMinute,
    int currentMinute,
  ) async {
    if (!mounted || _isShowingBreakingNews) return;
    final resumeSpeed = _playbackSpeed;
    _setPlaybackSpeed(_MarketPlaybackSpeed.paused);
    _isShowingBreakingNews = true;
    _timer?.cancel();
    _timer = null;
    for (final event in events) {
      if (!mounted) return;
      _shownBreakingNewsEventIds.add(event.id);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            NewsBulletinSheet(event: event, date: _state.currentDate),
      );
    }
    if (!mounted) return;
    _isShowingBreakingNews = false;
    setState(() => _playbackSpeed = resumeSpeed);
    _maybeShowSessionNotice(previousMinute, currentMinute);
    _resumeTimerIfNeeded();
  }

  void _maybeShowSessionNotice(int previousMinute, int currentMinute) {
    if (!mounted || !_hasDomesticTradingSession) return;
    if (previousMinute < krxOpenMinute && currentMinute >= krxOpenMinute) {
      _showSessionNotice(krxOpenMinute);
      return;
    }
    if (previousMinute < krxCloseMinute && currentMinute >= krxCloseMinute) {
      _showSessionNotice(krxCloseMinute);
    }
  }

  void _showSessionNotice(int minute) {
    if (!mounted ||
        _isShowingSessionNotice ||
        _shownSessionNotices.contains(minute)) {
      return;
    }
    _setPlaybackSpeed(_MarketPlaybackSpeed.paused);
    _shownSessionNotices.add(minute);
    _isShowingSessionNotice = true;
    _timer?.cancel();
    _timer = null;
    final isOpening = minute == krxOpenMinute;
    unawaited(
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: isOpening ? '장 시작 안내 닫기' : '장 마감 안내 닫기',
        barrierColor: const Color(0x660B1220),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, _, _) => _MarketSessionNoticeCard(
          isOpening: isOpening,
          onDismiss: () => Navigator.of(dialogContext).pop(),
        ),
        transitionBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ).whenComplete(() {
        if (!mounted) return;
        _isShowingSessionNotice = false;
        setState(() {});
        _resumeTimerIfNeeded();
      }),
    );
  }

  Future<void> _closeMarket() async {
    if (_isClosing || _allowPop) return;
    if (_tutorialActive) return;
    if (_isExecutingTrade) {
      _closeAfterTrade = true;
      return;
    }
    if (_isAdvancingHour) {
      _closeAfterHourAdvance = true;
      return;
    }
    _isClosing = true;
    _timer?.cancel();
    _timer = null;
    final minuteToSave = _marketMinute;
    try {
      final next = await _runMarketMutation(
        () async => widget.onSetMarketMinute?.call(minuteToSave),
      );
      if (next != null) _state = next;
      _popMarketAfterSave();
    } catch (_) {
      _isClosing = false;
      if (!mounted) return;
      _resumeTimerIfNeeded();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시장 시간을 저장하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  void _popMarketAfterSave() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Widget _withMarketExitGuard(Widget child) {
    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isClosing) return;
        unawaited(_closeMarket());
      },
      child: child,
    );
  }

  Future<void> _advanceOneHour() =>
      _advanceMarketTo(math.min(_marketMinute + 60, krxCloseMinute));

  Future<void> _jumpToMarketOpen() => _advanceMarketTo(krxOpenMinute);

  Future<void> _jumpToMarketClose() => _advanceMarketTo(krxCloseMinute);

  Future<void> _advanceMarketTo(int requestedMinute) async {
    if (_isAdvancingHour ||
        _isRealtimeBatchUpdating ||
        _isPurchasingReport ||
        _marketNotebookSaveCount > 0 ||
        _isClosing ||
        _isExecutingTrade ||
        _isTransferringCash) {
      return;
    }
    if (requestedMinute <= _marketMinute) return;
    final previousMinute = _marketMinute;
    final stateBeforeAdvance = _state;
    final targetMinute = math.min(requestedMinute, krxCloseMinute);
    final targetTick = marketTickForMinute(targetMinute);
    _isAdvancingHour = true;
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
    try {
      final next = await _runMarketMutation(
        () async => widget.onSetMarketMinute?.call(targetMinute),
      );
      if (next != null) _state = next;
      if (!mounted) return;
      String? orderUpdateMessage;
      if (next != null) {
        final fills = _newTradeSignals(stateBeforeAdvance, next);
        _applyNewPlayerMarketImpact(
          next.ledger.skip(stateBeforeAdvance.ledger.length),
        );
        if (fills.isNotEmpty) {
          _publishPlayerTradeSignals(fills);
          orderUpdateMessage = fills.length == 1
              ? '시간 이동 중 미체결 주문 1건이 체결됐어요.'
              : '시간 이동 중 미체결 주문 ${fills.length}건이 체결됐어요.';
        }
        final expiredCount = _newExpiredOrderCount(stateBeforeAdvance, next);
        if (expiredCount > 0) {
          _pausePlaybackWithoutRebuild();
          final expiryMessage = '장 마감으로 미체결 주문 $expiredCount건이 자동 취소됐어요.';
          orderUpdateMessage = orderUpdateMessage == null
              ? expiryMessage
              : '$orderUpdateMessage $expiryMessage';
        }
      }
      _tick = targetTick;
      _marketMinute = targetMinute;
      _minute.value = _marketMinute;
      for (final stock in _stocks) {
        final notifier = _live[stock.code]!;
        final current = notifier.value;
        if (!current.isTradingDay) continue;
        final sessionHistory = current.sessionPath.take(_tick + 1).toList();
        final tradingHistory = sessionHistory.length > generatedPreOpenTicks
            ? sessionHistory.sublist(generatedPreOpenTicks)
            : <double>[current.previousClose];
        notifier.value = current.copyWith(
          price: sessionHistory.last,
          open: tradingHistory.first,
          high: tradingHistory.reduce(math.max),
          low: tradingHistory.reduce(math.min),
          sessionHistory: sessionHistory,
        );
      }
      _presentationMinute.value = _marketMinute;
      _isAdvancingHour = false;
      if (_closeAfterHourAdvance) {
        _closeAfterHourAdvance = false;
        _isClosing = true;
        _popMarketAfterSave();
        return;
      }
      setState(() {});
      _handleMarketTimeCrossed(previousMinute, _marketMinute);
      if (orderUpdateMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(orderUpdateMessage)));
      }
      _resumeTimerIfNeeded();
    } catch (_) {
      _isAdvancingHour = false;
      if (!mounted) return;
      if (_closeAfterHourAdvance) {
        _closeAfterHourAdvance = false;
        await _closeMarket();
        return;
      }
      _resumeTimerIfNeeded();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시장 시간을 저장하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  Future<TradeExecutionResult> _executeTrade(TradeOrder order) async {
    final callback = widget.onExecuteTrade;
    if (callback == null) {
      return TradeExecutionResult(
        state: _state,
        success: false,
        message: '이 화면에서는 주문 저장이 연결되지 않았습니다.',
      );
    }
    if (_isExecutingTrade || _isClosing) {
      return TradeExecutionResult(
        state: _state,
        success: false,
        message: '이전 주문을 처리하고 있어요.',
      );
    }
    _StockDefinition? definition;
    for (final stock in _stocks) {
      if (stock.id == order.assetId) {
        definition = stock;
        break;
      }
    }
    final current = definition == null ? null : _live[definition.code]?.value;
    if (definition == null ||
        current == null ||
        order.symbol != definition.code ||
        order.name != definition.name ||
        order.market != definition.market ||
        order.currency != definition.currency ||
        order.quoteDate !=
            _state.currentDate.toIso8601String().split('T').first ||
        order.marketMinute != _marketMinute ||
        order.unitPrice != current.price ||
        order.isTradingDay != current.isTradingDay ||
        order.isIpoFirstTradingDay !=
            definition.asset.isIpoFirstTradingDay(_state.currentDate)) {
      return TradeExecutionResult(
        state: _state,
        success: false,
        message: '시세가 바뀌었어요. 최신 가격을 다시 확인해 주세요.',
      );
    }

    _isExecutingTrade = true;
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
    final cachedOrderBookBeforeTrade = _orderBookSessionCache._snapshotFor(
      order.assetId,
    );
    try {
      GameOrderBookSnapshot? orderBookReplaySnapshot;
      var ledgerLengthBeforeTrade = _state.ledger.length;
      final result = await _runMarketMutation(() async {
        final synced = await widget.onSetMarketMinute?.call(order.marketMinute);
        if (synced != null) _state = synced;
        ledgerLengthBeforeTrade = _state.ledger.length;
        orderBookReplaySnapshot =
            order.displayedSnapshot ??
            _playerReplaySnapshotFor(
              state: _state,
              assetId: order.assetId,
              marketMinute: order.marketMinute,
              cached: cachedOrderBookBeforeTrade,
            );
        return callback(order);
      });
      if (result.success && result.filledQuantity > 0) {
        final signal = _latestPlayerTradeSignalForOrder(
          result.state,
          assetId: order.assetId,
          side: order.side,
          marketMinute: order.marketMinute,
          microstructureFrame: order.microstructureFrame,
          minimumLedgerIndex: ledgerLengthBeforeTrade,
          orderBookSnapshot: orderBookReplaySnapshot,
        );
        if (signal != null) {
          _publishPlayerTradeSignals(<_PlayerTradeSignal>[signal]);
        }
      }
      if (result.success && mounted) {
        _timer?.cancel();
        _timer = null;
        _applyNewPlayerMarketImpact(
          result.state.ledger.skip(ledgerLengthBeforeTrade),
        );
        setState(() => _state = result.state);
      }
      return result;
    } finally {
      _isExecutingTrade = false;
      if (_closeAfterTrade) {
        _closeAfterTrade = false;
        unawaited(_closeMarket());
      } else {
        _resumeTimerIfNeeded();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _cancelPendingOrder(String orderId) async {
    final callback = widget.onCancelPendingOrder;
    if (callback == null || _isExecutingTrade || _isClosing) return;
    _isExecutingTrade = true;
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
    try {
      final result = await _runMarketMutation(() async {
        final synced = await widget.onSetMarketMinute?.call(_marketMinute);
        if (synced != null) _state = synced;
        return callback(orderId);
      });
      if (result.success && mounted) {
        setState(() => _state = result.state);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    } finally {
      _isExecutingTrade = false;
      _resumeTimerIfNeeded();
      if (mounted) setState(() {});
    }
  }

  Future<FinanceActionResult> _transferCash(int amount, bool deposit) async {
    final callback = widget.onTransferCash;
    if (callback == null) {
      return FinanceActionResult(
        state: _state,
        success: false,
        message: '이 화면에서는 증권계좌 이체가 연결되지 않았습니다.',
      );
    }
    if (_isTransferringCash || _isClosing || _isExecutingTrade) {
      return FinanceActionResult(
        state: _state,
        success: false,
        message: '이전 요청을 처리하고 있어요.',
      );
    }
    _isTransferringCash = true;
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
    try {
      final result = await _runMarketMutation(() async {
        final synced = await widget.onSetMarketMinute?.call(_marketMinute);
        if (synced != null) _state = synced;
        return callback(amount, deposit);
      });
      if (result.success && mounted) setState(() => _state = result.state);
      return result;
    } catch (_) {
      return FinanceActionResult(
        state: _state,
        success: false,
        message: '이체를 저장하지 못했어요. 다시 시도해 주세요.',
      );
    } finally {
      _isTransferringCash = false;
      _resumeTimerIfNeeded();
      if (mounted) setState(() {});
    }
  }

  Future<void> _setRightsIssuePreference(bool subscribe) async {
    final callback = widget.onSetRightsIssuePreference;
    final preference = subscribe
        ? marketRightsIssueSubscribePreference
        : marketRightsIssueAutoSellPreference;
    if (callback == null ||
        _isSavingRightsPreference ||
        _state.story.storyFlags[marketRightsIssuePreferenceFlag] ==
            preference) {
      return;
    }
    _isSavingRightsPreference = true;
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
    try {
      final next = await _runMarketMutation(() => callback(subscribe));
      if (!mounted) return;
      setState(() => _state = next);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              subscribe
                  ? '주주배정 유상증자는 예수금 범위에서 청약해요.'
                  : '주주배정 유상증자의 신주인수권을 자동매도해요.',
            ),
          ),
        );
    } finally {
      _isSavingRightsPreference = false;
      _resumeTimerIfNeeded();
      if (mounted) setState(() {});
    }
  }

  Future<void> _openTransferSheet(bool deposit) async {
    if (_isTransferringCash || _isClosing || _isExecutingTrade) return;
    _pauseMarketForSheet();
    FinanceActionResult? result;
    try {
      result = await showModalBottomSheet<FinanceActionResult>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (sheetContext) => _BrokerageTransferSheet(
          state: _state,
          deposit: deposit,
          onSubmit: _transferCash,
        ),
      );
    } finally {
      _resumeMarketAfterSheet();
    }
    if (result == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Set<String> get _favoriteAssetIds {
    final draft = _favoriteDraft;
    if (draft != null) return Set<String>.of(draft);
    final raw = _state.story.storyFlags['marketFavoriteAssetIds'];
    if (raw is! List) return <String>{};
    return raw.whereType<String>().toSet();
  }

  Map<String, String> get _researchNotes {
    final draft = _researchNotesDraft;
    if (draft != null) return Map<String, String>.of(draft);
    final raw = _state.story.storyFlags['marketResearchNotes'];
    if (raw is! Map) return <String, String>{};
    return <String, String>{
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }

  List<Map<String, dynamic>> get _dailyReportItems {
    final raw = _state.story.storyFlags['dailyMarketReports'];
    if (raw is! Map) return const [];
    final items = raw[marketDateKey(_state.currentDate)];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }

  bool get _canPurchaseDailyReport =>
      isMarketTradingDay(_state.currentDate) &&
      _marketMinute < krxCloseMinute &&
      fictionalMarketEventsForDate(
        _state.simulationSeed,
        _state.currentDate,
      ).any((event) => event.revealMinute > _marketMinute);

  Future<void> _purchaseDailyReport() async {
    final callback = widget.onPurchaseReport;
    if (callback == null || _isPurchasingReport) return;
    _timer?.cancel();
    _timer = null;
    setState(() => _isPurchasingReport = true);
    try {
      final result = await _runMarketMutation(() async {
        final synced = await widget.onSetMarketMinute?.call(_marketMinute);
        if (synced != null) _state = synced;
        return callback();
      });
      if (result.success && mounted) setState(() => _state = result.state);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    } catch (_) {
      if (mounted) _showSaveFailure(context);
    } finally {
      if (mounted) {
        setState(() => _isPurchasingReport = false);
        _resumeTimerIfNeeded();
      }
    }
  }

  Future<GameState> _persistMarketNotebook(
    Set<String> favorites,
    Map<String, String> notes,
  ) async {
    final callback = widget.onSaveMarketNotebook;
    if (callback == null) return _state;
    _marketNotebookSaveCount += 1;
    _timer?.cancel();
    _timer = null;
    try {
      final saved = await _runMarketMutation(() async {
        final synced = await widget.onSetMarketMinute?.call(_marketMinute);
        if (synced != null) _state = synced;
        return callback(favorites, notes);
      });
      if (mounted) setState(() => _state = saved);
      return saved;
    } finally {
      _marketNotebookSaveCount = math.max(0, _marketNotebookSaveCount - 1);
      if (mounted && _marketNotebookSaveCount == 0) {
        _resumeTimerIfNeeded();
      }
    }
  }

  Future<GameState> _toggleFavorite(String assetId) {
    final favorites = _favoriteAssetIds;
    if (favorites.contains(assetId)) {
      favorites.remove(assetId);
    } else {
      favorites.add(assetId);
    }
    _favoriteDraft = Set<String>.of(favorites);
    final notes = _researchNotes;
    _researchNotesDraft = Map<String, String>.of(notes);
    return _persistMarketNotebook(favorites, notes);
  }

  Future<GameState> _saveResearchNote(String assetId, String value) {
    final notes = _researchNotes;
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      notes.remove(assetId);
    } else {
      notes[assetId] = trimmed.substring(0, math.min(300, trimmed.length));
    }
    _researchNotesDraft = Map<String, String>.of(notes);
    final favorites = _favoriteAssetIds;
    _favoriteDraft = Set<String>.of(favorites);
    return _persistMarketNotebook(favorites, notes);
  }

  double _turnoverFor(_StockDefinition definition, _LiveStock quote) {
    if (!quote.isTradingDay || !isMarketTradingDay(_state.currentDate)) {
      return 0;
    }
    return gameEstimatedTurnoverEok(
      assetId: definition.id,
      day: marketLiquidityDayKey(_state.currentDate),
      minute: _state.marketMinute,
      unitPrice: quote.price,
      previousClose: quote.previousClose,
      simulationSeed: _state.simulationSeed,
      sharesOutstanding: definition.asset.sharesOutstandingAtOrBefore(
        _state.currentDate,
      ),
    );
  }

  _LiveMarketIndex _liveMarketIndex(
    String label,
    Iterable<_StockDefinition> source,
  ) {
    var referenceCapitalization = 0.0;
    var currentCapitalization = 0.0;
    for (final stock in source) {
      final quote = _live[stock.code]?.value;
      final sharesOutstanding = stock.asset.sharesOutstandingAtOrBefore(
        _state.currentDate,
      );
      if (quote == null ||
          sharesOutstanding == null ||
          sharesOutstanding <= 0 ||
          quote.previousClose <= 0 ||
          quote.price <= 0) {
        continue;
      }
      referenceCapitalization += quote.previousClose * sharesOutstanding;
      currentCapitalization += quote.price * sharesOutstanding;
    }
    final ratio = referenceCapitalization <= 0
        ? 1.0
        : currentCapitalization / referenceCapitalization;
    return (
      label: label,
      level: 1000 * ratio,
      rate: (ratio - 1) * 100,
      referenceCapitalization: referenceCapitalization,
    );
  }

  List<_LiveMarketIndex> _liveSectorIndices(Iterable<_StockDefinition> source) {
    final grouped = <String, List<_StockDefinition>>{};
    for (final stock in source) {
      grouped.putIfAbsent(stock.sector, () => <_StockDefinition>[]).add(stock);
    }
    final indices =
        <_LiveMarketIndex>[
          for (final entry in grouped.entries)
            _liveMarketIndex(entry.key, entry.value),
        ]..sort((left, right) {
          final sizeOrder = right.referenceCapitalization.compareTo(
            left.referenceCapitalization,
          );
          return sizeOrder != 0 ? sizeOrder : left.label.compareTo(right.label);
        });
    return indices.take(3).toList(growable: false);
  }

  List<_StockDefinition> _sortedStocks(Iterable<_StockDefinition> source) {
    final visible = source.toList();
    visible.sort((left, right) {
      final leftQuote = _live[left.code]!.value;
      final rightQuote = _live[right.code]!.value;
      return switch (_sort) {
        _MarketSort.turnover => _turnoverFor(
          right,
          rightQuote,
        ).compareTo(_turnoverFor(left, leftQuote)),
        _MarketSort.gainers => _changeRate(
          rightQuote,
        ).compareTo(_changeRate(leftQuote)),
        _MarketSort.losers => _changeRate(
          leftQuote,
        ).compareTo(_changeRate(rightQuote)),
        _MarketSort.name => left.name.compareTo(right.name),
      };
    });
    return visible;
  }

  List<_StockDefinition> get _visibleStocks {
    final query = _searchController.text.trim().toLowerCase();
    final source = switch (_tab) {
      0 => _stocks.where((stock) => stock.country == 'KR'),
      1 => _stocks.where((stock) => stock.market == fictionalMainMarket),
      2 => _stocks.where((stock) => stock.market == fictionalGrowthMarket),
      3 => _stocks.where((stock) => stock.generation > 0),
      _ => _stocks.where((stock) => _favoriteAssetIds.contains(stock.id)),
    };
    return _sortedStocks(
      source.where(
        (stock) =>
            query.isEmpty ||
            stock.name.toLowerCase().contains(query) ||
            stock.code.contains(query) ||
            stock.sector.toLowerCase().contains(query) ||
            stock.market.toLowerCase().contains(query),
      ),
    );
  }

  Map<String, double> get _currentPrices => {
    for (final stock in _stocks)
      if (stock.currency == 'KRW') stock.id: _live[stock.code]!.value.price,
  };

  _StockDefinition? _definitionFor(String assetId) {
    for (final stock in _stocks) {
      if (stock.id == assetId) return stock;
    }
    return null;
  }

  _StockDefinition? get _tutorialStock {
    if (_stocks.isEmpty) return null;
    for (final stock in _stocks) {
      if (stock.code == '1001') return stock;
    }
    return _stocks.first;
  }

  void _handleMarketTutorialAction() {
    switch (_tutorialStep) {
      case 0:
        setState(() => _tutorialStep = 1);
        return;
      case 1:
        setState(() {
          _section = _MarketSection.explore;
          _tab = 0;
          _searchController.clear();
          _tutorialStep = 2;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final targetContext = _tutorialStockKey.currentContext;
          if (targetContext != null) {
            Scrollable.ensureVisible(
              targetContext,
              alignment: 0.62,
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
            );
          }
        });
        return;
      case 2:
        final stock = _tutorialStock;
        if (stock != null) unawaited(_openStock(stock, fromTutorial: true));
        return;
      case null:
      default:
        return;
    }
  }

  Future<GameState> _completeMarketTutorial() async {
    final callback = widget.onCompleteTutorial;
    if (callback == null) return _state;
    final saved = await callback();
    if (!mounted) return saved;
    setState(() {
      _state = saved;
      _tutorialStep = null;
    });
    _resumeTimerIfNeeded();
    return saved;
  }

  Future<void> _openStock(
    _StockDefinition stock, {
    bool fromTutorial = false,
  }) async {
    if (_tutorialActive && !fromTutorial) return;
    if (fromTutorial) setState(() => _tutorialStep = 3);
    _openedAssetId = stock.id;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _StockDetailScreen(
            definition: stock,
            live: _live[stock.code]!,
            marketState: _marketStateNotifier,
            playerTrade: _playerTradeNotifier,
            minute: _minute,
            presentationMinute: _presentationMinute,
            playbackSpeed: _playbackSpeedNotifier,
            onPlaybackSpeedChanged: _setPlaybackSpeed,
            onExecuteTrade: _executeTrade,
            onCancelPendingOrder: widget.onCancelPendingOrder == null
                ? null
                : _cancelPendingOrder,
            onToggleFavorite: _toggleFavorite,
            onSaveResearchNote: _saveResearchNote,
            onMarketSheetOpened: _pauseMarketForSheet,
            onMarketSheetClosed: _resumeMarketAfterSheet,
            dailyMarketCap: _dailyMarketCapFor(stock),
            marketCapRanking: _marketCapRankingFor(stock),
            initialOrderBookSnapshot: _orderBookSessionCache._snapshotFor(
              stock.id,
            ),
            orderBookSweepJournal: _orderBookSessionCache._sweepJournalFor(
              stock.id,
              '${_state.simulationSeed}:${marketDateKey(_state.currentDate)}',
            ),
            onOrderBookSnapshotChanged: (snapshot) {
              _orderBookSessionCache._remember(stock.id, snapshot);
            },
            initialTradeTape: _orderBookSessionCache._tradeTapeFor(stock.id),
            onTradeTapeChanged: (tradeTape) {
              _orderBookSessionCache._rememberTradeTape(stock.id, tradeTape);
            },
            tutorialEnabled: fromTutorial,
            onCompleteTutorial: _completeMarketTutorial,
          ),
        ),
      );
    } finally {
      _openedAssetId = null;
    }
    if (!mounted) return;
    if (fromTutorial && !_tutorialActive) {
      await Navigator.of(context).maybePop();
      return;
    }
    if (!_tutorialActive) return;
    setState(() {
      _section = _MarketSection.explore;
      _tutorialStep = 2;
    });
  }

  _DailyMarketCapSnapshot _buildDailyMarketCapSnapshot(
    Iterable<_StockDefinition> stocks,
  ) {
    final values = <String, int>{};
    final entries = <MapEntry<_StockDefinition, int>>[];
    for (final stock in stocks) {
      final quote = _live[stock.code]?.value;
      if (quote == null) continue;
      final sharesOutstanding = stock.asset.sharesOutstandingAtOrBefore(
        _state.currentDate,
      );
      if (sharesOutstanding == null || sharesOutstanding <= 0) continue;
      final referencePrice = quote.isTradingDay
          ? quote.previousClose
          : quote.officialClose;
      final safeReferencePrice = referencePrice.isFinite && referencePrice > 0
          ? referencePrice
          : quote.price;
      final marketCap = (safeReferencePrice * sharesOutstanding).round();
      values[stock.id] = marketCap;
      if (stock.country == 'KR' && stock.currency == 'KRW') {
        entries.add(MapEntry(stock, marketCap));
      }
    }
    entries.sort((left, right) {
      final marketCapOrder = right.value.compareTo(left.value);
      return marketCapOrder != 0
          ? marketCapOrder
          : left.key.code.compareTo(right.key.code);
    });
    final rankings = <String, _MarketCapRanking>{
      for (var index = 0; index < entries.length; index += 1)
        entries[index].key.id: _MarketCapRanking(
          rank: index + 1,
          companyCount: entries.length,
        ),
    };
    return (
      values: Map<String, int>.unmodifiable(values),
      rankings: Map<String, _MarketCapRanking>.unmodifiable(rankings),
    );
  }

  int _dailyMarketCapFor(_StockDefinition stock) =>
      _dailyMarketCaps[stock.id] ?? 0;

  _MarketCapRanking _marketCapRankingFor(_StockDefinition selected) =>
      _dailyMarketCapRankings[selected.id] ??
      _MarketCapRanking(
        rank: null,
        companyCount: _dailyMarketCapRankings.length,
      );

  List<Widget> _holdingRows({int? limit}) {
    final rows = <Widget>[];
    for (final position in _state.positions) {
      final stock = _definitionFor(position.assetId);
      if (stock == null || stock.currency != 'KRW') continue;
      rows.add(
        _PortfolioPositionRow(
          key: Key('market-account-position-${position.assetId}'),
          position: position,
          definition: stock,
          live: _live[stock.code]!,
          onTap: () => _openStock(stock),
        ),
      );
      if (limit != null && rows.length >= limit) break;
    }
    return rows;
  }

  List<LedgerEntry> get _tradeLedgerEntries {
    final ledger = _state.ledger;
    if (identical(ledger, _cachedTradeLedgerSource)) {
      return _cachedTradeLedgerEntries;
    }
    _cachedTradeLedgerSource = ledger;
    _cachedTradeLedgerEntries = ledger
        .where(
          (entry) =>
              entry.assetId.isNotEmpty &&
              entry.tradeQuantity > 0 &&
              entry.tradeUnitPrice > 0 &&
              (entry.tradeSide == TradeSide.buy.name ||
                  entry.tradeSide == TradeSide.sell.name),
        )
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    return _cachedTradeLedgerEntries;
  }

  String _tradeAssetName(String assetId) =>
      _stocks
          .where((definition) => definition.id == assetId)
          .firstOrNull
          ?.name ??
      assetId;

  Future<void> _openTradeJournal() async {
    final entries = _tradeLedgerEntries;
    if (entries.isEmpty || !mounted) return;
    _pauseMarketForSheet();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (_) => _TradeJournalSheet(
          state: _state,
          entries: entries,
          assetNameFor: _tradeAssetName,
        ),
      );
    } finally {
      _resumeMarketAfterSheet();
    }
  }

  Widget _buildHomeSection() {
    final domestic = _stocks
        .where((stock) => stock.country == 'KR' && stock.currency == 'KRW')
        .toList();
    final ranked = _sortedStocks(domestic);
    final reportItems = _dailyReportItems;
    return ListView.builder(
      key: const Key('market-home-section'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      itemCount: ranked.length + 1,
      itemBuilder: (context, index) {
        if (index > 0) {
          final stock = ranked[index - 1];
          return _MarketRankingRow(
            key: Key('market-ranking-row-${stock.code}'),
            rank: index,
            definition: stock,
            live: _live[stock.code]!,
            turnoverFor: _turnoverFor,
            onTap: () => _openStock(stock),
          );
        }
        return Column(
          key: const Key('market-ranking-table'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: _presentationMinute,
              builder: (context, _, _) => _MarketIndexBoard(
                mainIndex: _liveMarketIndex(
                  '미래종합',
                  domestic.where(
                    (stock) => stock.market == fictionalMainMarket,
                  ),
                ),
                growthIndex: _liveMarketIndex(
                  '도전종합',
                  domestic.where(
                    (stock) => stock.market == fictionalGrowthMarket,
                  ),
                ),
                sectorIndices: _liveSectorIndices(domestic),
              ),
            ),
            const SizedBox(height: 12),
            _DailyMarketReportCard(
              items: reportItems,
              cash: _state.bankCash,
              purchasing: _isPurchasingReport,
              canPurchase: _canPurchaseDailyReport,
              onPurchase: widget.onPurchaseReport == null
                  ? null
                  : _purchaseDailyReport,
            ),
            const SizedBox(height: 20),
            _MarketSectionTitle(
              title: '오늘의 종목 순위',
              action: '전체 종목',
              onAction: () => setState(() => _section = _MarketSection.explore),
            ),
            const Text(
              '현재가·등락률·게임 거래대금을 한 줄에서 비교해요.',
              style: TextStyle(
                color: Color(0xFF8A919E),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            _MarketSortBar(
              selected: _sort,
              compact: true,
              onChanged: (value) => setState(() => _sort = value),
            ),
            const SizedBox(height: 9),
          ],
        );
      },
    );
  }

  List<_AnnouncedCorporateAction> _announcedCorporateActions() {
    final rows = <_AnnouncedCorporateAction>[
      for (final stock in _stocks)
        for (final action in stock.asset.announcedCorporateActionsFrom(
          _state.currentDate,
        ))
          _AnnouncedCorporateAction(stock: stock, action: action),
    ];
    rows.sort((left, right) {
      final dateOrder = left.action.date.compareTo(right.action.date);
      if (dateOrder != 0) return dateOrder;
      return left.stock.code.compareTo(right.stock.code);
    });
    return rows.take(6).toList(growable: false);
  }

  Widget _buildAccountSection() {
    final rows = _holdingRows();
    final trades = _tradeLedgerEntries;
    final announcedActions = _announcedCorporateActions();
    final subscribeRights =
        _state.story.storyFlags[marketRightsIssuePreferenceFlag] ==
        marketRightsIssueSubscribePreference;
    return ListView(
      key: const Key('market-account-section'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        const Text(
          '내 투자',
          style: TextStyle(
            color: Color(0xFF191F28),
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 12),
        _BrokerageAccountCard(
          state: _state,
          prices: _currentPrices,
          tradeEntries: trades,
          onDeposit: widget.onTransferCash == null
              ? null
              : () => _openTransferSheet(true),
          onWithdraw: widget.onTransferCash == null
              ? null
              : () => _openTransferSheet(false),
        ),
        const SizedBox(height: 22),
        _CorporateActionScheduleCard(
          actions: announcedActions,
          subscribeRights: subscribeRights,
          savingPreference: _isSavingRightsPreference,
          preferenceEnabled: widget.onSetRightsIssuePreference != null,
          onPreferenceChanged: (value) =>
              unawaited(_setRightsIssuePreference(value)),
        ),
        const SizedBox(height: 22),
        _MarketSectionTitle(
          title: '매매일지 ${trades.length}',
          action: trades.isEmpty ? null : '전체 보기',
          onAction: trades.isEmpty
              ? null
              : () => unawaited(_openTradeJournal()),
        ),
        const SizedBox(height: 8),
        _TradeJournalPreview(
          state: _state,
          entries: trades.take(3).toList(growable: false),
          assetNameFor: _tradeAssetName,
          onOpenAll: trades.isEmpty
              ? null
              : () => unawaited(_openTradeJournal()),
        ),
        if (_state.pendingOrders.isNotEmpty) ...[
          const SizedBox(height: 22),
          _MarketSectionTitle(title: '미체결 주문 ${_state.pendingOrders.length}'),
          const SizedBox(height: 8),
          for (final order in _state.pendingOrders)
            _PendingOrderRow(
              order: order,
              onCancel: widget.onCancelPendingOrder == null
                  ? null
                  : () => _cancelPendingOrder(order.id),
            ),
        ],
        const SizedBox(height: 22),
        _MarketSectionTitle(title: '보유 종목 ${rows.length}'),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          _EmptyPortfolioCard(
            onExplore: () => setState(() => _section = _MarketSection.explore),
          )
        else
          ...rows,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _withMarketExitGuard(
        _MarketPreparingScreen(
          progress: _loadProgress,
          stage: _loadStage,
          year: _state.currentDate.year,
        ),
      );
    }
    if (_loadError != null) {
      return _withMarketExitGuard(
        Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '시장 데이터를 불러오지 못했어요.\n$_loadError',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('market-load-retry'),
                      onPressed: () =>
                          unawaited(_loadFictionalMarket(forceRefresh: true)),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('다시 불러오기'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final visibleStocks = [..._visibleStocks];
    final tutorialStock = _tutorialStock;
    if (_tutorialStep == 2 && tutorialStock != null) {
      visibleStocks
        ..removeWhere((stock) => stock.id == tutorialStock.id)
        ..insert(0, tutorialStock);
    }
    final marketListTitle = switch (_tab) {
      3 => '새로 생긴 기업',
      4 => '관심 종목',
      _ => '가상시장 종목',
    };

    final scene = _CrtTradingRoomScene(
      minuteListenable: _presentationMinute,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SafeArea(
              child: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: _presentationMinute,
                    builder: (context, currentMinute, _) => _MarketHomeAppBar(
                      onBack: _closeMarket,
                      minute: currentMinute,
                      tradingDay: _hasDomesticTradingSession,
                      onAdvanceHour:
                          _isAdvancingHour ||
                              _isRealtimeBatchUpdating ||
                              _isPurchasingReport ||
                              _marketNotebookSaveCount > 0 ||
                              _isClosing ||
                              _isExecutingTrade ||
                              currentMinute >= krxCloseMinute
                          ? null
                          : _advanceOneHour,
                      onJumpToOpen:
                          _isAdvancingHour ||
                              _isRealtimeBatchUpdating ||
                              _isPurchasingReport ||
                              _marketNotebookSaveCount > 0 ||
                              _isClosing ||
                              _isExecutingTrade ||
                              !_hasDomesticTradingSession ||
                              currentMinute >= krxOpenMinute
                          ? null
                          : _jumpToMarketOpen,
                      onJumpToClose:
                          _isAdvancingHour ||
                              _isRealtimeBatchUpdating ||
                              _isPurchasingReport ||
                              _marketNotebookSaveCount > 0 ||
                              _isClosing ||
                              _isExecutingTrade ||
                              !_hasDomesticTradingSession ||
                              currentMinute < krxOpenMinute ||
                              currentMinute >= krxCloseMinute
                          ? null
                          : _jumpToMarketClose,
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: _presentationMinute,
                    builder: (context, currentMinute, _) => _MarketPlaybackBar(
                      speed: _playbackSpeed,
                      enabled:
                          !_isAdvancingHour &&
                          !_isRealtimeBatchUpdating &&
                          !_isPurchasingReport &&
                          _marketNotebookSaveCount == 0 &&
                          !_isLifecyclePaused &&
                          !_isClosing &&
                          !_isExecutingTrade &&
                          !_isTransferringCash &&
                          !_isMarketSheetOpen &&
                          _hasDomesticTradingSession &&
                          currentMinute < krxCloseMinute,
                      onChanged: _setPlaybackSpeed,
                    ),
                  ),
                  if (_latestBackgroundNews case final event?)
                    _MarketNewsTicker(event: event),
                  Expanded(
                    child: switch (_section) {
                      _MarketSection.home => _buildHomeSection(),
                      _MarketSection.account => ValueListenableBuilder<int>(
                        valueListenable: _presentationMinute,
                        builder: (context, _, _) => _buildAccountSection(),
                      ),
                      _MarketSection.explore => ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                        itemCount: visibleStocks.isEmpty
                            ? 2
                            : visibleStocks.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  key: const Key('market-search-input'),
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: '회사명이나 종목코드 검색',
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _MarketTabs(
                                  selected: _tab,
                                  onChanged: (value) =>
                                      setState(() => _tab = value),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        marketListTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF202632),
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _LiveDot(),
                                        SizedBox(width: 5),
                                        Text(
                                          '세계 시드 연동',
                                          style: TextStyle(
                                            color: Color(0xFF26845B),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                const Text(
                                  '오늘의 사건과 세계 시드가 반영되며 15:00에 가상 종가가 확정됩니다.',
                                  style: TextStyle(
                                    color: Color(0xFF8A919E),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _MarketSortBar(
                                  selected: _sort,
                                  onChanged: (value) =>
                                      setState(() => _sort = value),
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          }
                          if (visibleStocks.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 50),
                              child: Center(
                                child: Text(
                                  _searchController.text.trim().isNotEmpty
                                      ? '검색 결과가 없어요.'
                                      : _tab == 4
                                      ? '종목 상세의 별을 눌러 관심 종목을 모아보세요.'
                                      : '아직 공개된 종가가 없어요.\n첫 거래일을 기다려 주세요.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          final stock = visibleStocks[index - 1];
                          final row = _StockRow(
                            key: Key('stock-row-${stock.code}'),
                            definition: stock,
                            live: _live[stock.code]!,
                            turnoverFor: _turnoverFor,
                            favorite: _favoriteAssetIds.contains(stock.id),
                            onTap: () => unawaited(_openStock(stock)),
                          );
                          if (_tutorialStep == 2 &&
                              stock.id == tutorialStock?.id) {
                            return RepaintBoundary(
                              key: _tutorialStockKey,
                              child: row,
                            );
                          }
                          return row;
                        },
                      ),
                    },
                  ),
                  _MarketBottomNavigation(
                    selected: _section,
                    onChanged: (value) => setState(() => _section = value),
                    tutorialExploreKey: _tutorialExploreKey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return _withMarketExitGuard(
      Stack(
        children: [
          Positioned.fill(child: scene),
          if (_tutorialActive)
            Positioned.fill(
              child: _MarketTutorialOverlay(
                step: _tutorialStep!,
                targetKey: switch (_tutorialStep) {
                  1 => _tutorialExploreKey,
                  2 => _tutorialStockKey,
                  _ => null,
                },
                onAction: _handleMarketTutorialAction,
              ),
            ),
        ],
      ),
    );
  }
}

class _StockDetailScreen extends StatefulWidget {
  const _StockDetailScreen({
    required this.definition,
    required this.live,
    required this.marketState,
    required this.playerTrade,
    required this.minute,
    required this.presentationMinute,
    required this.playbackSpeed,
    required this.onPlaybackSpeedChanged,
    required this.onExecuteTrade,
    required this.onCancelPendingOrder,
    required this.onToggleFavorite,
    required this.onSaveResearchNote,
    required this.onMarketSheetOpened,
    required this.onMarketSheetClosed,
    required this.dailyMarketCap,
    required this.marketCapRanking,
    required this.initialOrderBookSnapshot,
    required this.orderBookSweepJournal,
    required this.onOrderBookSnapshotChanged,
    required this.initialTradeTape,
    required this.onTradeTapeChanged,
    this.tutorialEnabled = false,
    this.onCompleteTutorial,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final ValueListenable<GameState> marketState;
  final ValueListenable<Map<String, _PlayerTradeSignal>> playerTrade;
  final ValueNotifier<int> minute;
  final ValueListenable<int> presentationMinute;
  final ValueNotifier<_MarketPlaybackSpeed> playbackSpeed;
  final ValueChanged<_MarketPlaybackSpeed> onPlaybackSpeedChanged;
  final Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade;
  final Future<void> Function(String orderId)? onCancelPendingOrder;
  final Future<GameState> Function(String) onToggleFavorite;
  final Future<GameState> Function(String, String) onSaveResearchNote;
  final VoidCallback onMarketSheetOpened;
  final VoidCallback onMarketSheetClosed;
  final int dailyMarketCap;
  final _MarketCapRanking marketCapRanking;
  final _OrderBookSessionSnapshot? initialOrderBookSnapshot;
  final _OrderBookSweepJournal orderBookSweepJournal;
  final ValueChanged<_OrderBookSessionSnapshot> onOrderBookSnapshotChanged;
  final List<_OrderBookTapePrint> initialTradeTape;
  final ValueChanged<List<_OrderBookTapePrint>> onTradeTapeChanged;
  final bool tutorialEnabled;
  final Future<GameState> Function()? onCompleteTutorial;

  @override
  State<_StockDetailScreen> createState() => _StockDetailScreenState();
}

enum _StockDetailTab { quote, order, chart, info }

class _StockDetailScreenState extends State<_StockDetailScreen>
    with WidgetsBindingObserver {
  late GameState _state;
  final ScrollController _detailScrollController = ScrollController();
  final Map<String, _OrderBookSessionSnapshot> _orderBookSnapshotCache = {};
  _OrderBookSessionSnapshot? _latestOrderBookSnapshot;
  GameState? _visibleOrderBookCacheState;
  GameOrderBookSnapshot? _visibleOrderBookCacheRaw;
  int? _visibleOrderBookCacheMinute;
  _PlayerTradeSignal? _visibleOrderBookCachePlayerTrade;
  GameOrderBookSnapshot? _visibleOrderBookCacheValue;
  GameState? _orderBookConsumptionCacheState;
  int? _orderBookConsumptionCacheMinute;
  _OrderBookConsumptionView? _orderBookConsumptionCacheValue;
  late final ValueNotifier<int> _orderBookPulseFrame;
  late final ValueNotifier<_OrderBookSweepTapeCursor?> _orderBookTapeCursor;
  Timer? _orderBookPulseTimer;
  DateTime? _orderBookPulseDueAt;
  late int _orderBookLogicalMinute;
  int _orderBookLogicalPulseCount = 0;
  late DateTime _orderBookMarketMinuteStartedAt;
  bool _isDetailLifecyclePaused = false;
  bool _isDetailOverlayOpen = false;
  bool _isDetailTradeInFlight = false;
  final GlobalKey _tutorialPriceKey = GlobalKey();
  final GlobalKey _tutorialChartKey = GlobalKey();
  final GlobalKey _tutorialOrderBookHeaderKey = GlobalKey();
  final GlobalKey _tutorialBestAskKey = GlobalKey();
  _StockDetailTab _detailTab = _StockDetailTab.quote;
  _DetailedOrderSection _inlineOrderSection = _DetailedOrderSection.buy;
  bool _inlineOrderIsBuy = true;
  double? _inlineOrderLimitPrice;
  double? _inlineOrderSelectedPrice;
  double? _inlineOrderQuantity;
  int _inlineOrderRevision = 0;
  int? _tutorialStep;
  _PlayerTradeSignal? _lastPlayerTradeSignal;
  List<_OrderBookTapePrint> _tradeTape = const <_OrderBookTapePrint>[];
  final Set<String> _tradeTapeIdentities = <String>{};
  _QuoteQuantityPreset _quoteQuantityPreset = _QuoteQuantityPreset.one;
  double? _quoteSelectedPrice;
  List<MarketTechnicalLevel> _technicalLevels = const <MarketTechnicalLevel>[];
  String _technicalLevelsDate = '';
  double _technicalLevelsReference = 0;

  _StockDefinition get definition => widget.definition;
  ValueNotifier<_LiveStock> get live => widget.live;
  GameState get state => _state;
  ValueNotifier<int> get minute => widget.minute;
  String get _orderBookSessionKey =>
      '${state.simulationSeed}:${marketDateKey(state.currentDate)}';

  List<_OrderBookSweepReplayPacket> _orderBookSweepPackets() =>
      widget.orderBookSweepJournal.pendingPackets;

  void _queueOrderBookSweepPacket(
    GameOrderBookSnapshot snapshot,
    Iterable<GameOrderBookSweepStep> sourceSteps, {
    required String source,
    String? uniqueToken,
    GameOrderBookSnapshot? previousSnapshot,
  }) {
    final steps =
        sourceSteps
            .where((step) => step.consumedQuantity > 0)
            .toList(growable: false)
          ..sort((left, right) => left.sequence.compareTo(right.sequence));
    // A cancellation-only quote update belongs directly to the canonical book.
    // Do not enqueue a fake sweep/hold phase: there is no trade for the border
    // or tape to replay, and delaying it makes route re-entry reveal stale rows.
    if (steps.isEmpty) return;
    final cancellations = source == 'market' && previousSnapshot != null
        ? orderBookCancellationNotices(
            previous: previousSnapshot,
            next: snapshot,
            tradeSteps: steps,
            transitionMarketMinute: snapshot.sourceMarketMinute,
            transitionLiquidityPulse: snapshot.liquidityPulse,
          )
        : const <OrderBookCancellationNotice>[];

    final identity = _orderBookSweepReplayIdentity(
      snapshot,
      steps,
      source,
      uniqueToken: uniqueToken,
      cancellations: cancellations,
    );
    widget.orderBookSweepJournal.enqueue(
      _OrderBookSweepReplayPacket(
        snapshot: snapshot,
        previousSnapshot: previousSnapshot ?? snapshot,
        steps: List<GameOrderBookSweepStep>.unmodifiable(steps),
        cancellations: List<OrderBookCancellationNotice>.unmodifiable(
          cancellations,
        ),
        source: source,
        identity: identity,
      ),
    );
  }

  void _acceptOrderBookSweepPackets(Iterable<String> identities) {
    widget.orderBookSweepJournal.accept(identities);
  }

  void _queuePlayerTradeSweep(_PlayerTradeSignal? signal) {
    if (signal == null || signal.orderBookSweepSteps.isEmpty) return;
    final snapshot =
        signal.orderBookReplaySnapshot ?? _latestOrderBookSnapshot?.snapshot;
    if (snapshot == null) return;
    _queueOrderBookSweepPacket(
      snapshot,
      signal.orderBookSweepSteps,
      source: 'player',
      uniqueToken: signal.replayIdentity.isEmpty ? null : signal.replayIdentity,
    );
  }

  void _refreshTechnicalLevels(_LiveStock quote) {
    final dateKey = marketDateKey(_state.currentDate);
    if (_technicalLevelsDate == dateKey &&
        (_technicalLevelsReference - quote.previousClose).abs() < 0.000001) {
      return;
    }
    _technicalLevels = marketTechnicalLevelsForAsset(
      asset: definition.asset,
      sessionDate: _state.currentDate,
      referencePrice: quote.previousClose,
    );
    _technicalLevelsDate = dateKey;
    _technicalLevelsReference = quote.previousClose;
    _orderBookSnapshotCache.clear();
    _latestOrderBookSnapshot = null;
    widget.orderBookSweepJournal.ensureSession(_orderBookSessionKey);
  }

  GameOrderBookSnapshot _visibleOrderBookSnapshot(
    GameOrderBookSnapshot rawSnapshot,
    int currentMinute,
  ) {
    final playerTrade = _lastPlayerTradeSignal;
    if (identical(_visibleOrderBookCacheState, state) &&
        identical(_visibleOrderBookCacheRaw, rawSnapshot) &&
        _visibleOrderBookCacheMinute == currentMinute &&
        identical(_visibleOrderBookCachePlayerTrade, playerTrade) &&
        _visibleOrderBookCacheValue != null) {
      return _visibleOrderBookCacheValue!;
    }
    final consumption = _orderBookConsumptionAt(currentMinute);
    final visible = gameOrderBookSnapshotAfterConsumption(
      snapshot: rawSnapshot,
      consumedAskByPrice: consumption.asks,
      consumedBidByPrice: consumption.bids,
      consumedCapacityUnits: consumption.capacityUnits,
      latestConsumedSide: consumption.latestSide,
      latestConsumedPrice: consumption.latestPrice,
      retainSyntheticTombstone: false,
    );
    _visibleOrderBookCacheState = state;
    _visibleOrderBookCacheRaw = rawSnapshot;
    _visibleOrderBookCacheMinute = currentMinute;
    _visibleOrderBookCachePlayerTrade = playerTrade;
    _visibleOrderBookCacheValue = visible;
    return visible;
  }

  _OrderBookConsumptionView _orderBookConsumptionAt(int currentMinute) {
    if (identical(_orderBookConsumptionCacheState, state) &&
        _orderBookConsumptionCacheMinute == currentMinute &&
        _orderBookConsumptionCacheValue != null) {
      return _orderBookConsumptionCacheValue!;
    }
    GameOrderBookSide? latestSide;
    double? latestPrice;
    for (final entry in state.ledger.reversed) {
      if (entry.assetId != definition.id ||
          entry.marketMinute != currentMinute ||
          (entry.orderBookSide != GameOrderBookSide.ask.name &&
              entry.orderBookSide != GameOrderBookSide.bid.name)) {
        continue;
      }
      final fill = entry.orderBookFills.reversed
          .where(
            (candidate) =>
                candidate.price.isFinite &&
                candidate.price > 0 &&
                candidate.quantity.isFinite &&
                candidate.quantity > 0,
          )
          .firstOrNull;
      if (fill == null) continue;
      latestSide = entry.orderBookSide == GameOrderBookSide.ask.name
          ? GameOrderBookSide.ask
          : GameOrderBookSide.bid;
      latestPrice = fill.price;
      break;
    }
    final consumption = (
      asks: gameConsumedOrderBookUnitsByPrice(
        state,
        assetId: definition.id,
        marketMinute: currentMinute,
        bookSide: GameOrderBookSide.ask,
      ),
      bids: gameConsumedOrderBookUnitsByPrice(
        state,
        assetId: definition.id,
        marketMinute: currentMinute,
        bookSide: GameOrderBookSide.bid,
      ),
      capacityUnits: gameConsumedOrderBookFillUnits(
        state,
        assetId: definition.id,
        marketMinute: currentMinute,
        side: TradeSide.buy,
      ),
      latestSide: latestSide,
      latestPrice: latestPrice,
    );
    _orderBookConsumptionCacheState = state;
    _orderBookConsumptionCacheMinute = currentMinute;
    _orderBookConsumptionCacheValue = consumption;
    return consumption;
  }

  bool _recordTradeTapePrint({
    required int marketMinute,
    required int microstructureFrame,
    required double price,
    required int quantity,
    required TradeSide side,
    required bool isPlayer,
    required double fallbackPreviousPrice,
    int sequence = 0,
    String executionIdentity = '',
    bool notify = true,
  }) {
    if (!price.isFinite || price <= 0 || quantity <= 0) return false;
    if (_tradeTape.isNotEmpty &&
        _tradeTape.first.sessionKey != _orderBookSessionKey) {
      _tradeTape = const <_OrderBookTapePrint>[];
      _tradeTapeIdentities.clear();
    }
    final print = _OrderBookTapePrint(
      sessionKey: _orderBookSessionKey,
      marketMinute: marketMinute,
      microstructureFrame: math.max(0, microstructureFrame),
      price: price,
      previousPrice: _tradeTape.firstOrNull?.price ?? fallbackPreviousPrice,
      quantity: quantity,
      side: side,
      isPlayer: isPlayer,
      sequence: sequence,
      executionIdentity: executionIdentity,
    );
    if (!_tradeTapeIdentities.add(print.identity)) return false;
    final next = <_OrderBookTapePrint>[print, ..._tradeTape];
    if (next.length > _orderBookTapeCapacity) {
      final removed = next.removeLast();
      _tradeTapeIdentities.remove(removed.identity);
    }
    _tradeTape = List<_OrderBookTapePrint>.unmodifiable(next);
    if (notify) widget.onTradeTapeChanged(_tradeTape);
    return true;
  }

  GameOrderBookSnapshot _captureOrderBookTape(
    GameOrderBookSnapshot snapshot,
    _LiveStock quote,
    int currentMinute,
  ) {
    final generatedTrade = snapshot.lastSyntheticTrade;
    final generatedPrints = snapshot.syntheticTradePrints
        .where(
          (print) =>
              print.quantity > 0 &&
              print.marketMinute == currentMinute &&
              print.liquidityPulse == snapshot.liquidityPulse,
        )
        .toList(growable: false);
    if (generatedPrints.isNotEmpty) {
      var changed = false;
      for (final print in generatedPrints) {
        changed =
            _recordTradeTapePrint(
              marketMinute: print.marketMinute,
              microstructureFrame: print.liquidityPulse,
              price: print.price,
              quantity: print.quantity,
              side: print.levelSide == GameOrderBookSide.ask
                  ? TradeSide.buy
                  : TradeSide.sell,
              isPlayer: false,
              fallbackPreviousPrice: quote.previousClose,
              sequence: print.sequence,
              notify: false,
            ) ||
            changed;
      }
      if (changed) widget.onTradeTapeChanged(_tradeTape);
    } else if (generatedTrade != null &&
        generatedTrade.quantity > 0 &&
        generatedTrade.marketMinute == currentMinute &&
        generatedTrade.liquidityPulse == snapshot.liquidityPulse) {
      _recordTradeTapePrint(
        marketMinute: generatedTrade.marketMinute,
        microstructureFrame: generatedTrade.liquidityPulse,
        price: generatedTrade.price,
        quantity: generatedTrade.quantity,
        side: generatedTrade.levelSide == GameOrderBookSide.ask
            ? TradeSide.buy
            : TradeSide.sell,
        isPlayer: false,
        fallbackPreviousPrice: quote.previousClose,
      );
    }
    final playerTrade = _lastPlayerTradeSignal;
    final playerOrderBookPrint = playerTrade?.orderBookPrint;
    if (playerTrade != null &&
        playerTrade.assetId == definition.id &&
        playerTrade.marketMinute == currentMinute &&
        playerTrade.microstructureFrame == snapshot.liquidityPulse) {
      _recordTradeTapePrint(
        marketMinute: playerTrade.marketMinute,
        microstructureFrame: playerTrade.microstructureFrame,
        price: playerOrderBookPrint?.price ?? playerTrade.price,
        quantity:
            playerOrderBookPrint?.quantity ?? playerTrade.quantity.round(),
        side: playerTrade.side,
        isPlayer: true,
        fallbackPreviousPrice: quote.previousClose,
        executionIdentity: playerTrade.replayIdentity,
      );
    }
    return snapshot;
  }

  GameOrderBookSnapshot _minuteOpeningOrderBookSnapshot(
    _LiveStock quote,
    int currentMinute,
  ) {
    final previousMinutePrice = quote.sessionHistory.length >= 2
        ? quote.sessionHistory[quote.sessionHistory.length - 2]
        : quote.previousClose;
    final priceBeforePrevious = quote.sessionHistory.length >= 3
        ? quote.sessionHistory[quote.sessionHistory.length - 3]
        : quote.previousClose;
    return buildGameOrderBookSnapshot(
      assetId: definition.id,
      day: marketLiquidityDayKey(state.currentDate),
      minute: currentMinute,
      currentPrice: previousMinutePrice,
      previousClose: quote.previousClose,
      previousTradePrice: priceBeforePrevious,
      sessionLow: quote.low,
      sessionHigh: quote.high,
      date: state.currentDate,
      market: definition.market,
      simulationSeed: state.simulationSeed,
      levelCount: gameOrderBookLevelCount,
      tradingDay: quote.isTradingDay,
      sharesOutstanding: definition.asset.sharesOutstandingAtOrBefore(
        state.currentDate,
      ),
      isIpoFirstTradingDay: definition.asset.isIpoFirstTradingDay(
        state.currentDate,
      ),
      technicalLevels: _technicalLevels,
      liquidityPulse: gameOrderBookLiquidityPulseFrame(
        marketMinute: currentMinute,
        slotIndex: 0,
      ),
      adaptiveLiquidityPulses: true,
    );
  }

  double _intraMinuteWalkPrice(
    _LiveStock quote,
    int currentMinute,
    int microstructureFrame,
  ) {
    if (currentMinute < krxOpenMinute ||
        currentMinute >= krxContinuousEndMinute ||
        (quote.price - quote.previousClose).abs() < 0.000001 &&
            quote.sessionHistory.length < 2) {
      return quote.price;
    }
    final previousMinutePrice = quote.sessionHistory.length >= 2
        ? quote.sessionHistory[quote.sessionHistory.length - 2]
        : quote.previousClose;
    final targetPrice = quote.price;
    if ((targetPrice - previousMinutePrice).abs() < 0.000001) {
      return targetPrice;
    }
    final pulsesPerMarketMinute = _logicalOrderBookPulsesPerMinute(quote);
    final slot = gameOrderBookPulseSlotForFrame(
      marketMinute: currentMinute,
      liquidityPulse: microstructureFrame,
    ).clamp(0, pulsesPerMarketMinute);
    if (slot <= 0) return previousMinutePrice;

    final consumption = _orderBookConsumptionAt(currentMinute);
    final openingSnapshot = gameOrderBookSnapshotAfterConsumption(
      snapshot: _minuteOpeningOrderBookSnapshot(quote, currentMinute),
      consumedAskByPrice: consumption.asks,
      consumedBidByPrice: consumption.bids,
      consumedCapacityUnits: consumption.capacityUnits,
      retainSyntheticTombstone: false,
    );
    // The opening depth belongs to the previous minute boundary, while the
    // capacity belongs to the destination minute: it is the flow arriving
    // during this minute. This previous/current split is intentional.
    final capacity = gameOrderBookExecutionCapacity(
      assetId: definition.id,
      day: marketLiquidityDayKey(state.currentDate),
      minute: currentMinute,
      unitPrice: targetPrice,
      previousClose: quote.previousClose,
      simulationSeed: state.simulationSeed,
      sharesOutstanding: definition.asset.sharesOutstandingAtOrBefore(
        state.currentDate,
      ),
    );
    final allocatedUnits = gameOrderBookCumulativeSlotCapacity(
      executionCapacity: capacity,
      slotIndex: slot,
      pulsesPerMarketMinute: pulsesPerMarketMinute,
    );
    final availableUnits = math.max(
      0,
      allocatedUnits - consumption.capacityUnits,
    );
    final transition = gameOrderBookPriceTransitionTowardTarget(
      snapshot: openingSnapshot,
      previousPrice: previousMinutePrice,
      targetPrice: targetPrice,
      availableUnits: availableUnits,
      market: definition.market,
    );
    return marketSnapPrice(transition.price, market: definition.market);
  }

  GameOrderBookSnapshot _continuousOrderBookSnapshot(
    _LiveStock quote,
    int currentMinute,
    int microstructureFrame,
  ) {
    final targetSlot = gameOrderBookPulseSlotForFrame(
      marketMinute: currentMinute,
      liquidityPulse: microstructureFrame,
    );
    final previous = _latestOrderBookSnapshot;
    if (previous != null && previous.minute == currentMinute) {
      final pendingFrames = gameOrderBookPendingPulseFrames(
        marketMinute: currentMinute,
        afterLiquidityPulse: previous.microstructureFrame,
        throughSlotIndex: targetSlot,
      );
      GameOrderBookSnapshot? result;
      for (final frame in pendingFrames) {
        result = _buildContinuousOrderBookSnapshotFrame(
          quote,
          currentMinute,
          frame,
        );
      }
      if (result != null) return result;
    }
    return _buildContinuousOrderBookSnapshotFrame(
      quote,
      currentMinute,
      microstructureFrame,
    );
  }

  GameOrderBookSnapshot _buildContinuousOrderBookSnapshotFrame(
    _LiveStock quote,
    int currentMinute,
    int microstructureFrame,
  ) {
    _refreshTechnicalLevels(quote);
    final day = marketLiquidityDayKey(state.currentDate);
    final cacheKey =
        '${state.simulationSeed}:${definition.id}:$day:'
        '$currentMinute:$microstructureFrame';
    final currentPrice = _intraMinuteWalkPrice(
      quote,
      currentMinute,
      microstructureFrame,
    );
    final cached = _orderBookSnapshotCache[cacheKey];
    if (cached != null && (cached.price - currentPrice).abs() < 0.000001) {
      return _captureOrderBookTape(
        _visibleOrderBookSnapshot(cached.snapshot, currentMinute),
        quote,
        currentMinute,
      );
    }
    final previous = _latestOrderBookSnapshot;
    final canCarryForward =
        previous != null &&
        currentMinute >= previous.minute &&
        microstructureFrame >= previous.microstructureFrame;
    final carrySnapshot = canCarryForward
        ? _visibleOrderBookSnapshot(previous.snapshot, previous.minute)
        : null;
    final previousTradePrice = quote.sessionHistory.length >= 2
        ? quote.sessionHistory[quote.sessionHistory.length - 2]
        : quote.previousClose;
    final generatedSnapshot = buildGameOrderBookSnapshot(
      assetId: definition.id,
      day: day,
      minute: currentMinute,
      currentPrice: currentPrice,
      previousClose: quote.previousClose,
      previousTradePrice: previousTradePrice,
      sessionLow: quote.low,
      sessionHigh: quote.high,
      date: state.currentDate,
      market: definition.market,
      simulationSeed: state.simulationSeed,
      levelCount: gameOrderBookLevelCount,
      tradingDay: quote.isTradingDay,
      sharesOutstanding: definition.asset.sharesOutstandingAtOrBefore(
        state.currentDate,
      ),
      isIpoFirstTradingDay: definition.asset.isIpoFirstTradingDay(
        state.currentDate,
      ),
      previousSnapshot: carrySnapshot,
      previousSnapshotMinute: canCarryForward ? previous.minute : null,
      technicalLevels: _technicalLevels,
      liquidityPulse: microstructureFrame,
      adaptiveLiquidityPulses: true,
      holdSameMinuteBoundaryUntilExecution: true,
    );
    final consumption = _orderBookConsumptionAt(currentMinute);
    var snapshot = _visibleOrderBookSnapshot(generatedSnapshot, currentMinute);
    _queueOrderBookSweepPacket(
      snapshot,
      snapshot.sweepSteps,
      source: 'market',
      previousSnapshot: carrySnapshot,
    );
    final snapshotBeforeSyntheticTrade = snapshot;
    final clock = marketClockAt(
      currentMinute,
      tradingDay: quote.isTradingDay && isMarketTradingDay(state.currentDate),
    );
    final previousMinutePrice = quote.sessionHistory.length >= 2
        ? quote.sessionHistory[quote.sessionHistory.length - 2]
        : quote.price;
    final materialHalt = marketMaterialNewsTradingHaltAt(
      simulationSeed: state.simulationSeed,
      date: state.currentDate,
      assetId: definition.id,
      minute: currentMinute,
    );
    final slotIndex = gameOrderBookPulseSlotForFrame(
      marketMinute: currentMinute,
      liquidityPulse: microstructureFrame,
    );
    if (slotIndex > 0 &&
        clock.phase == MarketSessionPhase.regular &&
        clock.tradable &&
        materialHalt == null &&
        !marketDynamicVolatilityInterruptionActive(
          minute: currentMinute,
          previousTradePrice: previousMinutePrice,
          currentPrice: quote.price,
        )) {
      final pulsesPerMarketMinute = _logicalOrderBookPulsesPerMinute(quote);
      final pulse = gameOrderBookTradePulse(
        assetId: definition.id,
        day: day,
        minute: currentMinute,
        previousPrice: previousTradePrice,
        currentPrice: currentPrice,
        executionCapacity: generatedSnapshot.executionCapacity,
        market: definition.market,
        simulationSeed: state.simulationSeed,
        liquidityPulse: microstructureFrame,
        pulsesPerMarketMinute: pulsesPerMarketMinute,
      );
      final targetLevel = pulse == null
          ? null
          : gameOrderBookFirstExecutableLevel(
              snapshot: snapshot,
              side: pulse.levelSide,
            );
      if (pulse != null && targetLevel != null) {
        snapshot = gameOrderBookSnapshotAfterSyntheticTrade(
          snapshot: snapshot,
          pulse: pulse,
          absolutePrice: targetLevel.price,
          previousSnapshot: carrySnapshot,
          availableSnapshot: snapshot,
          perMinuteBudgetUnits: math.max(
            0,
            generatedSnapshot.executionCapacity - consumption.capacityUnits,
          ),
        );
      }
    }
    _queueOrderBookSweepPacket(
      snapshot,
      snapshot.sweepSteps,
      source: 'market',
      previousSnapshot: snapshotBeforeSyntheticTrade,
    );
    final entry = (
      snapshot: snapshot,
      minute: currentMinute,
      price: currentPrice,
      microstructureFrame: microstructureFrame,
      sessionKey: _orderBookSessionKey,
    );
    _orderBookSnapshotCache[cacheKey] = entry;
    _latestOrderBookSnapshot = entry;
    widget.onOrderBookSnapshotChanged(entry);
    while (_orderBookSnapshotCache.length > 6) {
      _orderBookSnapshotCache.remove(_orderBookSnapshotCache.keys.first);
    }
    return _captureOrderBookTape(
      _visibleOrderBookSnapshot(snapshot, currentMinute),
      quote,
      currentMinute,
    );
  }

  bool get _showsLiveOrderBook =>
      _detailTab == _StockDetailTab.quote ||
      _detailTab == _StockDetailTab.order;

  bool get _canRunOrderBookPulse {
    if (!mounted ||
        _isDetailLifecyclePaused ||
        _isDetailOverlayOpen ||
        _isDetailTradeInFlight ||
        widget.tutorialEnabled ||
        widget.playbackSpeed.value == _MarketPlaybackSpeed.paused ||
        !_showsLiveOrderBook ||
        ModalRoute.of(context)?.isCurrent == false) {
      return false;
    }
    final quote = live.value;
    final tradingDay =
        quote.isTradingDay && isMarketTradingDay(_state.currentDate);
    final clock = marketClockAt(minute.value, tradingDay: tradingDay);
    final previousTradePrice = quote.sessionHistory.length >= 2
        ? quote.sessionHistory[quote.sessionHistory.length - 2]
        : quote.price;
    final materialHalt = marketMaterialNewsTradingHaltAt(
      simulationSeed: _state.simulationSeed,
      date: _state.currentDate,
      assetId: definition.id,
      minute: minute.value,
    );
    return clock.phase == MarketSessionPhase.regular &&
        clock.tradable &&
        materialHalt == null &&
        !marketDynamicVolatilityInterruptionActive(
          minute: minute.value,
          previousTradePrice: previousTradePrice,
          currentPrice: quote.price,
          tradingDay: tradingDay,
        );
  }

  int _logicalOrderBookPulsesPerMinute(_LiveStock quote) {
    if (_orderBookLogicalPulseCount > 0) {
      return _orderBookLogicalPulseCount;
    }
    _orderBookLogicalPulseCount = _calculateOrderBookPulsesPerMinute(quote);
    return _orderBookLogicalPulseCount;
  }

  int _calculateOrderBookPulsesPerMinute(_LiveStock quote) {
    final previousTradePrice = quote.sessionHistory.length >= 2
        ? quote.sessionHistory[quote.sessionHistory.length - 2]
        : quote.previousClose;
    final fullDayTurnoverEok = gameEstimatedFullDayTurnoverEok(
      assetId: definition.id,
      day: marketLiquidityDayKey(_state.currentDate),
      referencePrice: quote.previousClose,
      simulationSeed: _state.simulationSeed,
      sharesOutstanding: definition.asset.sharesOutstandingAtOrBefore(
        _state.currentDate,
      ),
    );
    final recentTape = _tradeTape
        .where((print) => print.marketMinute >= minute.value - 2)
        .toList(growable: false);
    final recentExecutionFrames = recentTape
        .map((print) => (print.marketMinute, print.microstructureFrame))
        .toSet()
        .length;
    return gameOrderBookPulsesPerMarketMinute(
      fullDayTurnoverEok: fullDayTurnoverEok,
      currentPrice: quote.price,
      previousTradePrice: previousTradePrice,
      previousClose: quote.previousClose,
      market: definition.market,
      executionStrength: _tradeTapeExecutionStrength(recentTape),
      executionSamplePrints: recentExecutionFrames,
      executionSampleTurnoverEok: _tradeTapeTurnoverEok(recentTape),
      tradingSessionActive: true,
      playbackActive: true,
    );
  }

  int _elapsedOrderBookSlot(DateTime now, int pulsesPerMarketMinute) {
    if (pulsesPerMarketMinute <= 0) return 0;
    final totalMicros = marketRealtimeTickDuration.inMicroseconds;
    final elapsedMicros = now
        .difference(_orderBookMarketMinuteStartedAt)
        .inMicroseconds
        .clamp(0, totalMicros);
    if (elapsedMicros >= totalMicros) return pulsesPerMarketMinute;
    return (elapsedMicros * pulsesPerMarketMinute ~/ totalMicros).clamp(
      0,
      pulsesPerMarketMinute,
    );
  }

  Duration _delayUntilNextOrderBookSlot(
    DateTime now,
    int currentSlot,
    int pulsesPerMarketMinute,
  ) {
    final totalMicros = marketRealtimeTickDuration.inMicroseconds;
    final nextSlot = (currentSlot + 1).clamp(1, pulsesPerMarketMinute);
    final targetMicros = (totalMicros * nextSlot / pulsesPerMarketMinute)
        .round();
    final elapsedMicros = now
        .difference(_orderBookMarketMinuteStartedAt)
        .inMicroseconds;
    return Duration(microseconds: math.max(1000, targetMicros - elapsedMicros));
  }

  void _cancelOrderBookPulse() {
    _orderBookPulseTimer?.cancel();
    _orderBookPulseTimer = null;
    _orderBookPulseDueAt = null;
  }

  void _handleOrderBookPulseTimer() {
    final dueAt = _orderBookPulseDueAt;
    if (dueAt == null) {
      _orderBookPulseTimer = null;
      return;
    }
    final now = DateTime.now();
    if (now.isBefore(dueAt)) {
      _orderBookPulseTimer = Timer(
        dueAt.difference(now),
        _handleOrderBookPulseTimer,
      );
      return;
    }
    _orderBookPulseTimer = null;
    _orderBookPulseDueAt = null;
    if (!_canRunOrderBookPulse) return;
    if (_orderBookLogicalMinute != minute.value) {
      _handleOrderBookMarketMinuteChanged();
      return;
    }
    final pulsesPerMarketMinute = _logicalOrderBookPulsesPerMinute(live.value);
    final currentSlot = gameOrderBookPulseSlotForFrame(
      marketMinute: _orderBookLogicalMinute,
      liquidityPulse: _orderBookPulseFrame.value,
    );
    if (currentSlot >= pulsesPerMarketMinute) return;
    final elapsedSlot = _elapsedOrderBookSlot(now, pulsesPerMarketMinute);
    final targetSlot = math.min(
      pulsesPerMarketMinute,
      math.max(currentSlot + 1, elapsedSlot),
    );
    _orderBookPulseFrame.value = gameOrderBookLiquidityPulseFrame(
      marketMinute: _orderBookLogicalMinute,
      slotIndex: targetSlot,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureOrderBookPulseTimer();
    });
  }

  void _ensureOrderBookPulseTimer() {
    if (!_canRunOrderBookPulse) {
      _cancelOrderBookPulse();
      return;
    }
    if (_orderBookLogicalMinute != minute.value) {
      _handleOrderBookMarketMinuteChanged();
      return;
    }
    final pulsesPerMarketMinute = _logicalOrderBookPulsesPerMinute(live.value);
    final currentSlot = gameOrderBookPulseSlotForFrame(
      marketMinute: _orderBookLogicalMinute,
      liquidityPulse: _orderBookPulseFrame.value,
    );
    if (currentSlot >= pulsesPerMarketMinute) {
      _cancelOrderBookPulse();
      return;
    }
    final now = DateTime.now();
    final delay = _delayUntilNextOrderBookSlot(
      now,
      currentSlot,
      pulsesPerMarketMinute,
    );
    final nextDueAt = now.add(delay);
    final dueAt = _orderBookPulseDueAt;
    if (_orderBookPulseTimer != null &&
        dueAt != null &&
        !nextDueAt.isBefore(dueAt)) {
      return;
    }
    _cancelOrderBookPulse();
    _orderBookPulseDueAt = nextDueAt;
    _orderBookPulseTimer = Timer(delay, _handleOrderBookPulseTimer);
  }

  void _handleOrderBookMarketMinuteChanged() {
    final nextMinute = minute.value;
    if (_orderBookLogicalMinute == nextMinute) {
      _ensureOrderBookPulseTimer();
      return;
    }
    final previousMinute = _orderBookLogicalMinute;
    final previousQuote = live.value;
    final previousClock = marketClockAt(
      previousMinute,
      tradingDay:
          previousQuote.isTradingDay && isMarketTradingDay(_state.currentDate),
    );
    if (previousClock.phase == MarketSessionPhase.regular &&
        previousClock.tradable) {
      final finalSlot = _logicalOrderBookPulsesPerMinute(previousQuote);
      _continuousOrderBookSnapshot(
        previousQuote,
        previousMinute,
        gameOrderBookLiquidityPulseFrame(
          marketMinute: previousMinute,
          slotIndex: finalSlot,
        ),
      );
    }
    _orderBookLogicalMinute = nextMinute;
    _orderBookLogicalPulseCount = 0;
    _orderBookMarketMinuteStartedAt = DateTime.now();
    _orderBookPulseFrame.value = gameOrderBookLiquidityPulseFrame(
      marketMinute: nextMinute,
      slotIndex: 0,
    );
    // The minute notifier changes before the live quote. Defer slot-count
    // capture until the destination quote has settled so the minute keeps one
    // deterministic cadence for all renderers and dropped-frame catch-up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureOrderBookPulseTimer();
    });
  }

  void _handleOrderBookPulseInput() {
    _ensureOrderBookPulseTimer();
  }

  void _setDetailOverlayOpen(bool value) {
    if (_isDetailOverlayOpen == value) return;
    _isDetailOverlayOpen = value;
    if (value) {
      _cancelOrderBookPulse();
    } else {
      _ensureOrderBookPulseTimer();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = widget.marketState.value;
    _orderBookTapeCursor = ValueNotifier<_OrderBookSweepTapeCursor?>(null);
    _refreshTechnicalLevels(live.value);
    _tradeTape = List<_OrderBookTapePrint>.unmodifiable(
      widget.initialTradeTape
          .where((print) => print.sessionKey == _orderBookSessionKey)
          .take(_orderBookTapeCapacity),
    );
    _tradeTapeIdentities.addAll(_tradeTape.map((print) => print.identity));
    final initialSnapshot = widget.initialOrderBookSnapshot;
    final canRestoreSnapshot =
        initialSnapshot != null &&
        initialSnapshot.sessionKey == _orderBookSessionKey &&
        minute.value >= initialSnapshot.minute;
    _orderBookLogicalMinute = minute.value;
    final restoresCurrentMinute =
        canRestoreSnapshot && initialSnapshot.minute == _orderBookLogicalMinute;
    _orderBookPulseFrame = ValueNotifier<int>(
      restoresCurrentMinute
          ? initialSnapshot.microstructureFrame
          : gameOrderBookLiquidityPulseFrame(
              marketMinute: _orderBookLogicalMinute,
              slotIndex: 0,
            ),
    );
    final now = DateTime.now();
    _orderBookMarketMinuteStartedAt = now;
    if (restoresCurrentMinute) {
      final pulseCount = _logicalOrderBookPulsesPerMinute(live.value);
      final restoredSlot = gameOrderBookPulseSlotForFrame(
        marketMinute: _orderBookLogicalMinute,
        liquidityPulse: initialSnapshot.microstructureFrame,
      ).clamp(0, pulseCount);
      final elapsedMicros =
          marketRealtimeTickDuration.inMicroseconds *
          restoredSlot ~/
          pulseCount;
      _orderBookMarketMinuteStartedAt = now.subtract(
        Duration(microseconds: elapsedMicros),
      );
    }
    if (canRestoreSnapshot) {
      _latestOrderBookSnapshot = initialSnapshot;
      if (minute.value == initialSnapshot.minute) {
        final day = marketLiquidityDayKey(_state.currentDate);
        final cacheKey =
            '${_state.simulationSeed}:${definition.id}:$day:'
            '${initialSnapshot.minute}:${initialSnapshot.microstructureFrame}';
        _orderBookSnapshotCache[cacheKey] = initialSnapshot;
      }
    }
    widget.marketState.addListener(_synchronizeMarketState);
    widget.playerTrade.addListener(_synchronizePlayerTrade);
    widget.playbackSpeed.addListener(_handleOrderBookPulseInput);
    widget.minute.addListener(_handleOrderBookMarketMinuteChanged);
    live.addListener(_handleOrderBookPulseInput);
    _synchronizePlayerTrade();
    _tutorialStep = widget.tutorialEnabled ? 0 : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureOrderBookPulseTimer();
    });
  }

  void _synchronizeMarketState() {
    if (!mounted) return;
    setState(() {
      _state = widget.marketState.value;
      _refreshTechnicalLevels(live.value);
    });
    _ensureOrderBookPulseTimer();
  }

  void _synchronizePlayerTrade() {
    final signal = widget.playerTrade.value[definition.id];
    if (identical(signal, _lastPlayerTradeSignal)) return;
    void synchronize() {
      _lastPlayerTradeSignal = signal;
      _queuePlayerTradeSweep(signal);
    }

    if (mounted) {
      setState(synchronize);
    } else {
      synchronize();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    final paused =
        appState == AppLifecycleState.inactive ||
        appState == AppLifecycleState.paused ||
        appState == AppLifecycleState.hidden ||
        appState == AppLifecycleState.detached;
    _isDetailLifecyclePaused = paused;
    if (paused) {
      _cancelOrderBookPulse();
    } else if (appState == AppLifecycleState.resumed) {
      _ensureOrderBookPulseTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelOrderBookPulse();
    widget.marketState.removeListener(_synchronizeMarketState);
    widget.playerTrade.removeListener(_synchronizePlayerTrade);
    widget.playbackSpeed.removeListener(_handleOrderBookPulseInput);
    widget.minute.removeListener(_handleOrderBookMarketMinuteChanged);
    live.removeListener(_handleOrderBookPulseInput);
    _orderBookPulseFrame.dispose();
    _orderBookTapeCursor.dispose();
    _detailScrollController.dispose();
    super.dispose();
  }

  Future<TradeExecutionResult> onExecuteTrade(TradeOrder order) async {
    _isDetailTradeInFlight = true;
    _cancelOrderBookPulse();
    final orderBookBeforeTrade = _latestOrderBookSnapshot;
    final ledgerLengthBeforeTrade = _state.ledger.length;
    try {
      final result = await widget.onExecuteTrade(order);
      if (result.success && mounted) {
        final publishedSignal = widget.playerTrade.value[order.assetId];
        final hasPublishedSignal =
            publishedSignal != null &&
            publishedSignal.side == order.side &&
            publishedSignal.marketMinute == order.marketMinute &&
            publishedSignal.microstructureFrame == order.microstructureFrame;
        final signal = result.filledQuantity <= 0
            ? null
            : hasPublishedSignal
            ? publishedSignal
            : _latestPlayerTradeSignalForOrder(
                result.state,
                assetId: order.assetId,
                side: order.side,
                marketMinute: order.marketMinute,
                microstructureFrame: order.microstructureFrame,
                minimumLedgerIndex: ledgerLengthBeforeTrade,
                orderBookSnapshot:
                    order.displayedSnapshot ??
                    (orderBookBeforeTrade?.minute == order.marketMinute
                        ? orderBookBeforeTrade?.snapshot
                        : null),
              );
        setState(() {
          _state = result.state;
          if (signal != null) _lastPlayerTradeSignal = signal;
        });
      }
      return result;
    } finally {
      _isDetailTradeInFlight = false;
      if (mounted) _ensureOrderBookPulseTimer();
    }
  }

  Future<void> _openOrderSheet(
    bool isBuy, {
    bool fromTutorial = false,
    double? limitPrice,
    _DetailedOrderSection? initialSection,
  }) async {
    _setDetailOverlayOpen(true);
    widget.onMarketSheetOpened();
    try {
      await _showOrderSheet(
        context,
        definition: definition,
        live: live,
        isBuy: isBuy,
        marketState: widget.marketState,
        minute: minute,
        liquidityPulse: _orderBookPulseFrame.value,
        marketSnapshotReader: () => _continuousOrderBookSnapshot(
          live.value,
          minute.value,
          _orderBookPulseFrame.value,
        ),
        onExecuteTrade: onExecuteTrade,
        onCancelPendingOrder: widget.onCancelPendingOrder,
        initialOrderType: limitPrice == null ? null : TradeOrderType.limit,
        initialLimitPrice: limitPrice,
        initialSection: initialSection,
        tutorialEnabled: fromTutorial,
        onCompleteTutorial: () async {
          final callback = widget.onCompleteTutorial;
          if (callback == null) return;
          final saved = await callback();
          if (!mounted) return;
          setState(() {
            _state = saved;
            _tutorialStep = null;
          });
        },
      );
    } finally {
      widget.onMarketSheetClosed();
      _setDetailOverlayOpen(false);
    }
    if (fromTutorial && _tutorialStep == null && mounted) {
      await Navigator.of(context).maybePop();
    }
  }

  Future<void> _openQuoteQuickActions(GameOrderBookLevel level) async {
    setState(() => _quoteSelectedPrice = level.price);
    _setDetailOverlayOpen(true);
    widget.onMarketSheetOpened();
    try {
      final action = await showDialog<_QuoteQuickAction>(
        context: context,
        barrierColor: const Color(0x990A1020),
        builder: (_) => _QuoteQuickActionsDialog(price: level.price),
      );
      if (!mounted || action == null) return;
      if (action == _QuoteQuickAction.amendCancel) {
        setState(() {
          _detailTab = _StockDetailTab.order;
          _inlineOrderSection = _DetailedOrderSection.amendCancel;
        });
        return;
      }
      _showInlineOrder(
        action == _QuoteQuickAction.buy,
        limitPrice: level.price,
      );
    } finally {
      widget.onMarketSheetClosed();
      _setDetailOverlayOpen(false);
    }
  }

  int _quoteDockMaximumQuantity({required bool isBuy, required double price}) {
    if (!price.isFinite || price <= 0) return 0;
    if (!isBuy) {
      final held =
          state.positions
              .where((position) => position.assetId == definition.id)
              .firstOrNull
              ?.units ??
          0;
      return math.max(
        0,
        (held - state.pendingSellReservedUnits(definition.id)).floor(),
      );
    }
    var maximum = gameMaxBuyQuantity(state, price, market: definition.market);
    final maximumPositionUnits = definition.asset.sharesOutstandingAtOrBefore(
      state.currentDate,
    );
    if (maximumPositionUnits != null && maximumPositionUnits > 0) {
      final owned =
          state.positions
              .where((position) => position.assetId == definition.id)
              .firstOrNull
              ?.units ??
          0;
      final reserved = state.pendingBuyReservedUnits(definition.id);
      maximum = math.min(
        maximum,
        math.max(0, (maximumPositionUnits - owned - reserved).floor()),
      );
    }
    return math.max(0, maximum);
  }

  int _quoteDockQuantity({required bool isBuy, required double price}) {
    final maximum = _quoteDockMaximumQuantity(isBuy: isBuy, price: price);
    if (maximum <= 0) return 0;
    return switch (_quoteQuantityPreset) {
      _QuoteQuantityPreset.one => 1,
      _QuoteQuantityPreset.ten => math.min(10, maximum),
      _QuoteQuantityPreset.quarter => math.max(1, (maximum * 0.25).floor()),
      _QuoteQuantityPreset.maximum => maximum,
    };
  }

  void _openQuoteDockOrder(bool isBuy, GameOrderBookSnapshot snapshot) {
    final fallbackPrice = isBuy
        ? snapshot.asks.firstOrNull?.price
        : snapshot.bids.firstOrNull?.price;
    final price = marketSnapPrice(
      _quoteSelectedPrice ?? fallbackPrice ?? live.value.price,
      market: definition.market,
    );
    final quantity = _quoteDockQuantity(isBuy: isBuy, price: price);
    _showInlineOrder(
      isBuy,
      limitPrice: price,
      quantity: quantity > 0 ? quantity.toDouble() : null,
    );
  }

  void _showInlineOrder(bool isBuy, {double? limitPrice, double? quantity}) {
    setState(() {
      _detailTab = _StockDetailTab.order;
      _inlineOrderSection = isBuy
          ? _DetailedOrderSection.buy
          : _DetailedOrderSection.sell;
      _inlineOrderIsBuy = isBuy;
      _inlineOrderLimitPrice = marketSnapPrice(
        limitPrice ?? _inlineOrderLimitPrice ?? live.value.price,
        market: definition.market,
      );
      _inlineOrderSelectedPrice = _inlineOrderLimitPrice;
      _inlineOrderQuantity = quantity;
      _inlineOrderRevision += 1;
    });
  }

  void _updateInlineOrderSelectedPrice(double? price) {
    if (_inlineOrderSelectedPrice == price) return;
    setState(() => _inlineOrderSelectedPrice = price);
  }

  void _showInlineOrderSection(_DetailedOrderSection section) {
    setState(() => _inlineOrderSection = section);
  }

  Future<void> _amendInlineOrder(PendingTradeOrder order) async {
    final cancel = widget.onCancelPendingOrder;
    if (cancel == null) return;
    await cancel(order.id);
    if (!mounted) return;
    _showInlineOrder(
      order.side == PendingOrderSide.buy,
      limitPrice: order.limitPrice,
      quantity: order.remainingQuantity,
    );
  }

  void _resetInlineOrderForm() {
    setState(() {
      _inlineOrderQuantity = null;
      _inlineOrderRevision += 1;
    });
  }

  void _scrollDetailTutorialTo(double offset) {
    if (!_detailScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollDetailTutorialTo(offset),
      );
      return;
    }
    _detailScrollController.jumpTo(
      math.min(offset, _detailScrollController.position.maxScrollExtent),
    );
  }

  void _selectDetailTab(_StockDetailTab tab) {
    if (_detailTab == tab) return;
    if (_detailTab == _StockDetailTab.quote) {
      _orderBookTapeCursor.value = null;
    }
    setState(() {
      _detailTab = tab;
      if (tab == _StockDetailTab.order) {
        _inlineOrderLimitPrice ??= marketSnapPrice(
          live.value.price,
          market: definition.market,
        );
        _inlineOrderSelectedPrice ??= _inlineOrderLimitPrice;
      }
    });
    _ensureOrderBookPulseTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_detailScrollController.hasClients) return;
      _detailScrollController.jumpTo(0);
    });
  }

  double _tutorialBestAskPrice() {
    final quote = live.value;
    final snapshot = _continuousOrderBookSnapshot(
      quote,
      minute.value,
      _orderBookPulseFrame.value,
    );
    final bestAsk = gameOrderBookFirstExecutableLevel(
      snapshot: snapshot,
      side: GameOrderBookSide.ask,
    );
    return bestAsk?.price ?? quote.price;
  }

  void _handleDetailTutorialAction() {
    switch (_tutorialStep) {
      case 0:
        setState(() {
          _detailTab = _StockDetailTab.chart;
          _tutorialStep = 1;
        });
        _scrollDetailTutorialTo(0);
        return;
      case 1:
        setState(() {
          _detailTab = _StockDetailTab.info;
          _tutorialStep = 2;
        });
        _scrollDetailTutorialTo(0);
        return;
      case 2:
        unawaited(_completeTutorialResearchNote());
        return;
      case 3:
        setState(() => _tutorialStep = 4);
        _scrollDetailTutorialTo(80);
        return;
      case 4:
        final limitPrice = _tutorialBestAskPrice();
        _showInlineOrder(true, limitPrice: limitPrice, quantity: 1);
        setState(() => _tutorialStep = 5);
        _scrollDetailTutorialTo(0);
        return;
      case 5:
        setState(() => _detailTab = _StockDetailTab.quote);
        unawaited(
          _openOrderSheet(
            true,
            fromTutorial: true,
            limitPrice: _inlineOrderLimitPrice ?? _tutorialBestAskPrice(),
          ),
        );
        return;
      case null:
        return;
    }
  }

  bool get _isFavorite {
    final raw = state.story.storyFlags['marketFavoriteAssetIds'];
    return raw is List && raw.whereType<String>().contains(definition.id);
  }

  Future<void> _completeTutorialResearchNote() async {
    final saved = await _editResearchNote(tutorialRequired: true);
    if (!saved || !mounted) return;
    setState(() {
      _detailTab = _StockDetailTab.quote;
      _tutorialStep = 3;
    });
    _scrollDetailTutorialTo(0);
  }

  String get _researchNote {
    final raw = state.story.storyFlags['marketResearchNotes'];
    if (raw is! Map) return '';
    final value = raw[definition.id];
    return value is String ? value : '';
  }

  Future<void> _toggleFavorite() async {
    try {
      final saved = await widget.onToggleFavorite(definition.id);
      if (!mounted) return;
      setState(() => _state = saved);
      _showResearchMessage(
        context,
        _isFavorite ? '관심 종목에 저장했어요.' : '관심 종목에서 뺐어요.',
      );
    } catch (_) {
      if (mounted) _showSaveFailure(context);
    }
  }

  Future<bool> _editResearchNote({bool tutorialRequired = false}) async {
    _setDetailOverlayOpen(true);
    String? value;
    try {
      value = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ResearchNoteEditor(
          companyName: definition.name,
          initialValue: _researchNote,
          tutorialRequired: tutorialRequired,
        ),
      );
    } finally {
      _setDetailOverlayOpen(false);
    }
    if (value == null || !mounted) return false;
    try {
      final saved = await widget.onSaveResearchNote(definition.id, value);
      if (!mounted) return false;
      setState(() => _state = saved);
      _showResearchMessage(
        context,
        value.trim().isEmpty ? '조사노트를 지웠어요.' : '조사노트를 저장했어요.',
      );
      return true;
    } catch (_) {
      if (mounted) _showSaveFailure(context);
      return false;
    }
  }

  double _displayedDetailTradePrice(
    _LiveStock quote,
    GameOrderBookSnapshot snapshot,
    int currentMinute,
  ) {
    final playerSignal = _lastPlayerTradeSignal;
    final playerPrint = playerSignal?.orderBookPrint;
    if (playerSignal != null &&
        playerPrint != null &&
        playerSignal.assetId == definition.id &&
        playerSignal.marketMinute == currentMinute &&
        playerSignal.microstructureFrame == snapshot.liquidityPulse &&
        playerPrint.price.isFinite &&
        playerPrint.price > 0) {
      return playerPrint.price;
    }
    final generatedTrade = snapshot.lastSyntheticTrade;
    if (generatedTrade != null &&
        generatedTrade.quantity > 0 &&
        generatedTrade.marketMinute == currentMinute &&
        generatedTrade.liquidityPulse == snapshot.liquidityPulse &&
        generatedTrade.price.isFinite &&
        generatedTrade.price > 0) {
      return generatedTrade.price;
    }
    return snapshot.sourceLastTradePrice ?? quote.price;
  }

  @override
  Widget build(BuildContext context) {
    final scene = _CrtTradingRoomScene(
      minuteListenable: widget.presentationMinute,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SafeArea(
              child: ValueListenableBuilder<int>(
                valueListenable: widget.presentationMinute,
                builder: (context, currentMinute, _) {
                  final quote = live.value;
                  final financial = definition.financialAt(state.currentDate);
                  final sharesOutstanding =
                      definition.asset.sharesOutstandingAtOrBefore(
                        state.currentDate,
                      ) ??
                      financial?.sharesOutstanding ??
                      0;
                  final ownedShares = state.positions
                      .where((position) => position.assetId == definition.id)
                      .firstOrNull
                      ?.units;
                  final investorFlows = sharesOutstanding <= 0
                      ? const <FictionalInvestorFlowDay>[]
                      : buildFictionalInvestorFlowHistory(
                          simulationSeed: state.simulationSeed,
                          assetId: definition.id,
                          throughDate: state.currentDate,
                          priceHistory: quote.history,
                          currentPrice: quote.price,
                          sharesOutstanding: sharesOutstanding,
                          sharesOutstandingAt:
                              definition.asset.sharesOutstandingAtOrBefore,
                          referenceCloseAt: (date, previousClose) =>
                              definition.asset.marketReferenceCloseOn(
                                date,
                                previousClose: previousClose,
                              ),
                          currentMarketMinute: currentMinute,
                          currentReferencePrice: quote.previousClose,
                        );
                  final detailTradingDay =
                      quote.isTradingDay &&
                      isMarketTradingDay(state.currentDate);
                  final detailClock = marketClockAt(
                    currentMinute,
                    tradingDay: detailTradingDay,
                  );
                  final detailPreviousTradePrice =
                      quote.sessionHistory.length >= 2
                      ? quote.sessionHistory[quote.sessionHistory.length - 2]
                      : quote.price;
                  final detailViActive =
                      marketDynamicVolatilityInterruptionActive(
                        minute: currentMinute,
                        previousTradePrice: detailPreviousTradePrice,
                        currentPrice: quote.price,
                        tradingDay: detailTradingDay,
                      );
                  final detailMaterialHalt = marketMaterialNewsTradingHaltAt(
                    simulationSeed: state.simulationSeed,
                    date: state.currentDate,
                    assetId: definition.id,
                    minute: currentMinute,
                  );
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 14, 4),
                        child: Row(
                          children: [
                            IconButton(
                              key: const Key('close-stock-detail'),
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    definition.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF202632),
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  _StockDetailIdentityLine(
                                    market: definition.market,
                                    code: definition.code,
                                    managementRisk:
                                        marketFinancialSnapshotIsManagementRisk(
                                          financial,
                                        ),
                                    viActive: detailViActive,
                                    materialHalt: detailMaterialHalt != null,
                                    phase: detailClock.phase,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            RepaintBoundary(
                              key: _tutorialPriceKey,
                              child: ValueListenableBuilder<int>(
                                valueListenable: _orderBookPulseFrame,
                                builder: (context, liquidityPulse, _) {
                                  final snapshot = _continuousOrderBookSnapshot(
                                    quote,
                                    currentMinute,
                                    liquidityPulse,
                                  );
                                  final displayPrice =
                                      _displayedDetailTradePrice(
                                        quote,
                                        snapshot,
                                        currentMinute,
                                      );
                                  final change =
                                      displayPrice - quote.previousClose;
                                  final rate =
                                      change / quote.previousClose * 100;
                                  final color = _priceColor(change);
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Hero(
                                        tag: 'stock-${definition.code}',
                                        child: Material(
                                          color: Colors.transparent,
                                          child: Text(
                                            _displayPrice(
                                              displayPrice,
                                              definition.currency,
                                            ),
                                            key: const Key(
                                              'stock-detail-price',
                                            ),
                                            maxLines: 1,
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 20,
                                              height: 1.1,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                              fontFeatures:
                                                  _marketNumberFeatures,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${_signedDisplayPrice(change, definition.currency)}'
                                        ' · ${_signedPercent(rate)}',
                                        key: const Key(
                                          'stock-detail-change-rate',
                                        ),
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 10,
                                          height: 1.1,
                                          fontWeight: FontWeight.w800,
                                          fontFeatures: _marketNumberFeatures,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              key: const Key('toggle-market-favorite'),
                              tooltip: _isFavorite ? '관심 종목 해제' : '관심 종목 저장',
                              onPressed: _toggleFavorite,
                              icon: Icon(
                                _isFavorite
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: const Color(0xFFFFB020),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ValueListenableBuilder<_MarketPlaybackSpeed>(
                        valueListenable: widget.playbackSpeed,
                        builder: (context, speed, _) => _MarketPlaybackBar(
                          speed: speed,
                          enabled:
                              !widget.tutorialEnabled &&
                              quote.isTradingDay &&
                              isMarketTradingDay(state.currentDate) &&
                              currentMinute < krxCloseMinute,
                          onChanged: widget.onPlaybackSpeedChanged,
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, detailConstraints) => ListView(
                            key: ValueKey<_StockDetailTab>(_detailTab),
                            padding:
                                _detailTab == _StockDetailTab.quote ||
                                    _detailTab == _StockDetailTab.order
                                ? EdgeInsets.zero
                                : const EdgeInsets.fromLTRB(20, 16, 20, 28),
                            physics:
                                _detailTab == _StockDetailTab.quote ||
                                    _detailTab == _StockDetailTab.order
                                ? const NeverScrollableScrollPhysics()
                                : null,
                            controller: _detailScrollController,
                            children: switch (_detailTab) {
                              _StockDetailTab.quote => <Widget>[
                                ValueListenableBuilder<int>(
                                  valueListenable: _orderBookPulseFrame,
                                  builder: (context, liquidityPulse, _) {
                                    final snapshot =
                                        _continuousOrderBookSnapshot(
                                          quote,
                                          currentMinute,
                                          liquidityPulse,
                                        );
                                    return _OrderBookPanel(
                                      definition: definition,
                                      quote: quote,
                                      state: state,
                                      minute: currentMinute,
                                      playbackSpeed: widget.playbackSpeed,
                                      snapshot: snapshot,
                                      sweepPackets: _orderBookSweepPackets(),
                                      sweepPacketsReader:
                                          _orderBookSweepPackets,
                                      onSweepPacketsAccepted:
                                          _acceptOrderBookSweepPackets,
                                      availableHeight:
                                          detailConstraints.maxHeight,
                                      playerTrade: _lastPlayerTradeSignal,
                                      tradeTape: _tradeTape,
                                      tapeCursor: _orderBookTapeCursor,
                                      selectedPrice: _quoteSelectedPrice,
                                      quantityPreset: _quoteQuantityPreset,
                                      onQuantityPresetChanged: (preset) {
                                        setState(
                                          () => _quoteQuantityPreset = preset,
                                        );
                                      },
                                      onBuy: () =>
                                          _openQuoteDockOrder(true, snapshot),
                                      onSell: () =>
                                          _openQuoteDockOrder(false, snapshot),
                                      onAmendCancel: () {
                                        setState(() {
                                          _detailTab = _StockDetailTab.order;
                                          _inlineOrderSection =
                                              _DetailedOrderSection.amendCancel;
                                        });
                                      },
                                      tutorialHeaderKey:
                                          _tutorialOrderBookHeaderKey,
                                      tutorialBestAskKey: _tutorialBestAskKey,
                                      onTapLevel: (level) => unawaited(
                                        _openQuoteQuickActions(level),
                                      ),
                                    );
                                  },
                                ),
                              ],
                              _StockDetailTab.order => <Widget>[
                                _InlineOrderWorkspace(
                                  definition: definition,
                                  state: state,
                                  live: live,
                                  minute: minute,
                                  playbackSpeed: widget.playbackSpeed,
                                  liquidityPulseListenable:
                                      _orderBookPulseFrame,
                                  marketSnapshotReader: () =>
                                      _continuousOrderBookSnapshot(
                                        live.value,
                                        minute.value,
                                        _orderBookPulseFrame.value,
                                      ),
                                  sweepPacketsReader: _orderBookSweepPackets,
                                  onSweepPacketsAccepted:
                                      _acceptOrderBookSweepPackets,
                                  playerTrade: _lastPlayerTradeSignal,
                                  availableHeight: detailConstraints.maxHeight,
                                  section: _inlineOrderSection,
                                  formRevision: _inlineOrderRevision,
                                  initialLimitPrice:
                                      _inlineOrderLimitPrice ?? quote.price,
                                  selectedLimitPrice: _inlineOrderSelectedPrice,
                                  initialQuantity: _inlineOrderQuantity,
                                  onExecuteTrade: onExecuteTrade,
                                  onSelectBuy: () => _showInlineOrder(true),
                                  onSelectSell: () => _showInlineOrder(false),
                                  onSelectSection: _showInlineOrderSection,
                                  onSelectPrice: (price) => _showInlineOrder(
                                    _inlineOrderIsBuy,
                                    limitPrice: price,
                                  ),
                                  onSelectedLimitPriceChanged:
                                      _updateInlineOrderSelectedPrice,
                                  onCancelPendingOrder:
                                      widget.onCancelPendingOrder,
                                  onAmendPendingOrder: _amendInlineOrder,
                                  onSuccessContinue: _resetInlineOrderForm,
                                  onUnavailable: () => _showResearchMessage(
                                    context,
                                    '현재 거래할 수 없는 종목입니다.',
                                  ),
                                ),
                              ],
                              _StockDetailTab.chart => <Widget>[
                                RepaintBoundary(
                                  key: _tutorialChartKey,
                                  child: _MinuteChartPanel(
                                    quote: quote,
                                    code: definition.code,
                                    market: definition.market,
                                    minute: currentMinute,
                                    asset: definition.asset,
                                    simulationSeed: state.simulationSeed,
                                    throughDate: state.currentDate,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _QuoteGrid(quote: quote),
                              ],
                              _StockDetailTab.info => <Widget>[
                                if (financial == null)
                                  const _StockInfoUnavailable()
                                else ...[
                                  _InvestorFlowCard(rows: investorFlows),
                                  const SizedBox(height: 18),
                                  _CompanyOverviewCard(
                                    definition: definition,
                                    snapshot: financial,
                                    sharesOutstanding: sharesOutstanding,
                                    marketCap: widget.dailyMarketCap,
                                    ranking: widget.marketCapRanking,
                                    ownedShares: ownedShares ?? 0,
                                  ),
                                  const SizedBox(height: 18),
                                  _CompanyFundamentalsCard(
                                    snapshot: financial,
                                    sharesOutstanding: sharesOutstanding,
                                    price: quote.price,
                                    marketCap: widget.dailyMarketCap,
                                    relations: definition.relations,
                                  ),
                                ],
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F6FA),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _marketLine),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Expanded(
                                            child: Text(
                                              '오늘의 조사 질문',
                                              style: TextStyle(
                                                color: _marketAccent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          TextButton.icon(
                                            key: const Key(
                                              'open-market-research-note',
                                            ),
                                            onPressed: _editResearchNote,
                                            icon: const Icon(
                                              Icons.edit_note_rounded,
                                              size: 18,
                                            ),
                                            label: Text(
                                              _researchNote.isEmpty
                                                  ? '노트 쓰기'
                                                  : '노트 수정',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        definition.question,
                                        style: const TextStyle(
                                          color: _marketInk,
                                          fontSize: 14,
                                          height: 1.45,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_researchNote.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          key: const Key('saved-research-note'),
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.72,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            _researchNote,
                                            style: const TextStyle(
                                              color: Color(0xFF59491B),
                                              fontSize: 12,
                                              height: 1.45,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '일별 종가와 사건은 이 세이브의 세계 시드로 고정됩니다. 같은 세이브에서는 다시 뽑히지 않으며, 새 게임에서는 다른 미래가 펼쳐집니다.',
                                  style: TextStyle(
                                    color: Color(0xFF9A9FA8),
                                    fontSize: 10,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            },
                          ),
                        ),
                      ),
                      _StockDetailBottomNav(
                        selected: _detailTab,
                        onSelected: _selectDetailTab,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    return PopScope<void>(
      canPop: _tutorialStep == null,
      child: Stack(
        children: [
          Positioned.fill(child: scene),
          ValueListenableBuilder<_OrderBookSweepTapeCursor?>(
            valueListenable: _orderBookTapeCursor,
            builder: (context, cursor, _) => Offstage(
              child: SizedBox(
                key: Key(
                  cursor == null
                      ? 'order-book-tape-cursor-clear'
                      : 'order-book-tape-cursor-active',
                ),
              ),
            ),
          ),
          if (_tutorialStep != null)
            Positioned.fill(
              child: _MarketDetailTutorialOverlay(
                step: _tutorialStep!,
                targetKey: switch (_tutorialStep) {
                  0 => _tutorialPriceKey,
                  1 => _tutorialChartKey,
                  3 => _tutorialOrderBookHeaderKey,
                  4 => _tutorialBestAskKey,
                  _ => null,
                },
                onAction: _handleDetailTutorialAction,
              ),
            ),
        ],
      ),
    );
  }

  static Future<void> _showOrderSheet(
    BuildContext context, {
    required _StockDefinition definition,
    required ValueNotifier<_LiveStock> live,
    required bool isBuy,
    required ValueListenable<GameState> marketState,
    required ValueNotifier<int> minute,
    required int liquidityPulse,
    ValueGetter<GameOrderBookSnapshot>? marketSnapshotReader,
    required Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade,
    Future<void> Function(String orderId)? onCancelPendingOrder,
    TradeOrderType? initialOrderType,
    double? initialLimitPrice,
    _DetailedOrderSection? initialSection,
    bool tutorialEnabled = false,
    Future<void> Function()? onCompleteTutorial,
  }) {
    if (!tutorialEnabled) {
      return Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => _DetailedOrderPage(
            definition: definition,
            live: live,
            marketState: marketState,
            minute: minute,
            liquidityPulse: liquidityPulse,
            marketSnapshotReader: marketSnapshotReader,
            onExecuteTrade: onExecuteTrade,
            onCancelPendingOrder: onCancelPendingOrder,
            initialIsBuy: isBuy,
            initialOrderType: initialOrderType,
            initialLimitPrice: initialLimitPrice,
            initialSection: initialSection,
          ),
        ),
      );
    }
    var showingTutorial = tutorialEnabled;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: !tutorialEnabled,
      isScrollControlled: true,
      isDismissible: !tutorialEnabled,
      enableDrag: !tutorialEnabled,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final Widget orderSheet = tutorialEnabled
                ? _PracticalTradeTutorialSheet(
                    definition: definition,
                    sourceLive: live,
                    sourceState: marketState.value,
                    initialBuyLimitPrice: initialLimitPrice,
                    onCompleteTutorial: onCompleteTutorial,
                  )
                : const SizedBox.shrink();
            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.92,
              child: PopScope<void>(
                canPop: !showingTutorial,
                child: Stack(
                  children: [
                    Positioned.fill(child: orderSheet),
                    if (showingTutorial)
                      Positioned.fill(
                        child: _OrderTicketTutorialOverlay(
                          limitPrice: initialLimitPrice,
                          onDone: () async {
                            setSheetState(() => showingTutorial = false);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void _showResearchMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _StockDetailIdentityLine extends StatelessWidget {
  const _StockDetailIdentityLine({
    required this.market,
    required this.code,
    required this.managementRisk,
    required this.viActive,
    required this.materialHalt,
    required this.phase,
  });

  final String market;
  final String code;
  final bool managementRisk;
  final bool viActive;
  final bool materialHalt;
  final MarketSessionPhase phase;

  @override
  Widget build(BuildContext context) {
    final sessionLabel = switch (phase) {
      MarketSessionPhase.closingAuction => '동시호가',
      MarketSessionPhase.openingTransition => '개장전',
      MarketSessionPhase.closeSettlement || MarketSessionPhase.closed => '마감',
      MarketSessionPhase.holiday => '휴장',
      _ => null,
    };
    return SizedBox(
      height: 18,
      child: Row(
        key: const Key('stock-detail-status-strip'),
        children: [
          Flexible(
            child: Text(
              '$market · $code',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8A919E),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (managementRisk)
            const _StockStatusBadge(
              key: Key('stock-status-management'),
              label: '관리',
              foreground: Color(0xFF9B4A00),
              background: Color(0xFFFFE8C7),
            ),
          if (materialHalt)
            const _StockStatusBadge(
              key: Key('stock-status-halt'),
              label: '정지',
              foreground: Color(0xFFA52431),
              background: Color(0xFFFFDDE0),
            )
          else if (viActive)
            const _StockStatusBadge(
              key: Key('stock-status-vi'),
              label: 'VI',
              foreground: Color(0xFF9A4B00),
              background: Color(0xFFFFE8D8),
            ),
          if (sessionLabel != null)
            _StockStatusBadge(
              key: const Key('stock-status-session'),
              label: sessionLabel,
              foreground: const Color(0xFF4B5565),
              background: const Color(0xFFEFF2F6),
            ),
        ],
      ),
    );
  }
}

class _StockStatusBadge extends StatelessWidget {
  const _StockStatusBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 4),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: TextStyle(
        color: foreground,
        fontSize: 8,
        height: 1,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _StockDetailBottomNav extends StatelessWidget {
  const _StockDetailBottomNav({
    required this.selected,
    required this.onSelected,
  });

  final _StockDetailTab selected;
  final ValueChanged<_StockDetailTab> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('stock-detail-bottom-nav'),
    height: 66,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFE1E5EB))),
      boxShadow: [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 14,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: Row(
      children: [
        _StockDetailTabButton(
          key: const Key('stock-detail-tab-quote'),
          label: '호가',
          icon: Icons.format_list_numbered_rounded,
          selected: selected == _StockDetailTab.quote,
          onTap: () => onSelected(_StockDetailTab.quote),
        ),
        _StockDetailTabButton(
          key: const Key('stock-detail-tab-order'),
          label: '주문',
          icon: Icons.receipt_long_rounded,
          selected: selected == _StockDetailTab.order,
          onTap: () => onSelected(_StockDetailTab.order),
        ),
        _StockDetailTabButton(
          key: const Key('stock-detail-tab-chart'),
          label: '차트',
          icon: Icons.candlestick_chart_rounded,
          selected: selected == _StockDetailTab.chart,
          onTap: () => onSelected(_StockDetailTab.chart),
        ),
        _StockDetailTabButton(
          key: const Key('stock-detail-tab-info'),
          label: '정보',
          icon: Icons.domain_rounded,
          selected: selected == _StockDetailTab.info,
          onTap: () => onSelected(_StockDetailTab.info),
        ),
      ],
    ),
  );
}

class _StockDetailTabButton extends StatelessWidget {
  const _StockDetailTabButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selected)
              const Positioned(
                top: 0,
                left: 14,
                right: 14,
                child: SizedBox(
                  height: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _marketAccent,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected ? _marketAccent : const Color(0xFF8A919E),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? _marketAccent : const Color(0xFF747C88),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

enum _InvestorFlowView { aggregate, institutionDetail }

enum _InvestorFlowUnit { shares, amount }

class _InvestorFlowCard extends StatefulWidget {
  const _InvestorFlowCard({required this.rows});

  final List<FictionalInvestorFlowDay> rows;

  @override
  State<_InvestorFlowCard> createState() => _InvestorFlowCardState();
}

class _InvestorFlowCardState extends State<_InvestorFlowCard> {
  _InvestorFlowView _view = _InvestorFlowView.aggregate;
  _InvestorFlowUnit _unit = _InvestorFlowUnit.shares;

  @override
  Widget build(BuildContext context) {
    final latest = widget.rows.isEmpty ? null : widget.rows.first;
    return Container(
      key: const Key('investor-flow-card'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _marketLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.groups_2_outlined,
                      color: _marketAccent,
                      size: 21,
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      '종목투자자',
                      style: TextStyle(
                        color: _marketInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _unit == _InvestorFlowUnit.shares
                          ? '순매수 · 주'
                          : '순매수 · 금액',
                      style: const TextStyle(
                        color: _marketMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  '누가 사고팔았는지 일별 수급을 확인해요. +는 순매수, -는 순매도예요.',
                  style: TextStyle(
                    color: _marketMuted,
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerRight,
                  child: _InvestorFlowUnitToggle(
                    selected: _unit,
                    onChanged: (value) => setState(() => _unit = value),
                  ),
                ),
                if (latest != null) ...[
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: _InvestorSummaryMetric(
                          label: '개인',
                          value: latest.individual,
                          closePrice: latest.closePrice,
                          unit: _unit,
                          background: const Color(0xFFFFE4EF),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _InvestorSummaryMetric(
                          label: '외국인',
                          value: latest.foreign,
                          closePrice: latest.closePrice,
                          unit: _unit,
                          background: const Color(0xFFE1EAFF),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _InvestorSummaryMetric(
                          label: '기관계',
                          value: latest.institution,
                          closePrice: latest.closePrice,
                          unit: _unit,
                          background: const Color(0xFFDDF7E8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _InvestorSummaryMetric(
                          label: '연기금',
                          value: latest.pension,
                          closePrice: latest.closePrice,
                          unit: _unit,
                          background: const Color(0xFFFFF0C7),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 13),
                Container(
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InvestorFlowTab(
                          key: const Key('investor-flow-aggregate-tab'),
                          label: '주체별 수급',
                          selected: _view == _InvestorFlowView.aggregate,
                          onTap: () => setState(
                            () => _view = _InvestorFlowView.aggregate,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _InvestorFlowTab(
                          key: const Key('investor-flow-detail-tab'),
                          label: '기관 세부',
                          selected:
                              _view == _InvestorFlowView.institutionDetail,
                          onTap: () => setState(
                            () => _view = _InvestorFlowView.institutionDetail,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.rows.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: Text(
                '아직 표시할 수급 기록이 없어요.',
                style: TextStyle(
                  color: _marketMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (_view == _InvestorFlowView.aggregate)
            _InvestorAggregateTable(rows: widget.rows, unit: _unit)
          else
            _InvestorInstitutionTable(rows: widget.rows, unit: _unit),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Text(
              '게임 내 가상 거래 수급이며, 같은 세이브·종목·날짜에서는 동일하게 계산됩니다.',
              style: TextStyle(
                color: Color(0xFF929AA7),
                fontSize: 9,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvestorFlowUnitToggle extends StatelessWidget {
  const _InvestorFlowUnitToggle({
    required this.selected,
    required this.onChanged,
  });

  final _InvestorFlowUnit selected;
  final ValueChanged<_InvestorFlowUnit> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F4F7),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(_InvestorFlowUnit.shares, '주'),
        _button(_InvestorFlowUnit.amount, '금액'),
      ],
    ),
  );

  Widget _button(_InvestorFlowUnit value, String label) {
    final active = selected == value;
    return Material(
      key: Key('investor-flow-unit-${value.name}'),
      color: active ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          width: 44,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? _marketInk : _marketMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InvestorFlowTab extends StatelessWidget {
  const _InvestorFlowTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? Colors.white : Colors.transparent,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _marketInk : _marketMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}

class _InvestorSummaryMetric extends StatelessWidget {
  const _InvestorSummaryMetric({
    required this.label,
    required this.value,
    required this.closePrice,
    required this.unit,
    required this.background,
  });

  final String label;
  final int value;
  final double closePrice;
  final _InvestorFlowUnit unit;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _marketMuted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _investorFlowText(value, closePrice: closePrice, unit: unit),
            maxLines: 1,
            style: TextStyle(
              color: _investorFlowColor(value),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFeatures: _marketNumberFeatures,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InvestorAggregateTable extends StatelessWidget {
  const _InvestorAggregateTable({required this.rows, required this.unit});

  final List<FictionalInvestorFlowDay> rows;
  final _InvestorFlowUnit unit;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _InvestorAggregateRow(header: true, unit: unit),
      for (final row in rows)
        _InvestorAggregateRow(
          date: row.date,
          closePrice: row.closePrice,
          unit: unit,
          individual: row.individual,
          foreign: row.foreign,
          institution: row.institution,
        ),
    ],
  );
}

class _InvestorAggregateRow extends StatelessWidget {
  const _InvestorAggregateRow({
    this.header = false,
    this.date,
    this.closePrice = 0,
    required this.unit,
    this.individual = 0,
    this.foreign = 0,
    this.institution = 0,
  });

  final bool header;
  final DateTime? date;
  final double closePrice;
  final _InvestorFlowUnit unit;
  final int individual;
  final int foreign;
  final int institution;

  @override
  Widget build(BuildContext context) => Container(
    height: header ? 38 : 41,
    decoration: BoxDecoration(
      color: header ? const Color(0xFFF7F8FA) : Colors.white,
      border: const Border(top: BorderSide(color: _marketLine)),
    ),
    child: Row(
      children: [
        _InvestorTableCell(
          text: header ? '일자' : _shortInvestorDate(date!),
          flex: 11,
          header: header,
        ),
        _InvestorTableCell(
          text: header
              ? '개인'
              : _investorFlowText(
                  individual,
                  closePrice: closePrice,
                  unit: unit,
                ),
          value: header ? null : individual,
          flex: 10,
          header: header,
          headerColor: const Color(0xFFFFD7E8),
        ),
        _InvestorTableCell(
          text: header
              ? '외국인'
              : _investorFlowText(foreign, closePrice: closePrice, unit: unit),
          value: header ? null : foreign,
          flex: 10,
          header: header,
          headerColor: const Color(0xFFD9E4FF),
        ),
        _InvestorTableCell(
          text: header
              ? '기관계'
              : _investorFlowText(
                  institution,
                  closePrice: closePrice,
                  unit: unit,
                ),
          value: header ? null : institution,
          flex: 10,
          header: header,
          headerColor: const Color(0xFFD8F4E4),
        ),
      ],
    ),
  );
}

class _InvestorTableCell extends StatelessWidget {
  const _InvestorTableCell({
    required this.text,
    required this.flex,
    required this.header,
    this.value,
    this.headerColor,
  });

  final String text;
  final int flex;
  final bool header;
  final int? value;
  final Color? headerColor;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Container(
      height: double.infinity,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: header ? headerColor : null,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: TextStyle(
            color: header
                ? _marketInk
                : value == null
                ? _marketMuted
                : _investorFlowColor(value!),
            fontSize: header ? 10 : 11,
            fontWeight: header ? FontWeight.w800 : FontWeight.w700,
            fontFeatures: _marketNumberFeatures,
          ),
        ),
      ),
    ),
  );
}

class _InvestorInstitutionTable extends StatelessWidget {
  const _InvestorInstitutionTable({required this.rows, required this.unit});

  final List<FictionalInvestorFlowDay> rows;
  final _InvestorFlowUnit unit;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: 650,
      child: Column(
        children: [
          _row(
            header: true,
            cells: const ['일자', '금융투자', '투신', '연기금', '보험', '기타기관', '기타법인'],
          ),
          for (final row in rows)
            _row(
              cells: [
                _shortInvestorDate(row.date),
                _investorFlowText(
                  row.financialInvestment,
                  closePrice: row.closePrice,
                  unit: unit,
                ),
                _investorFlowText(
                  row.investmentTrust,
                  closePrice: row.closePrice,
                  unit: unit,
                ),
                _investorFlowText(
                  row.pension,
                  closePrice: row.closePrice,
                  unit: unit,
                ),
                _investorFlowText(
                  row.insurance,
                  closePrice: row.closePrice,
                  unit: unit,
                ),
                _investorFlowText(
                  row.otherInstitution,
                  closePrice: row.closePrice,
                  unit: unit,
                ),
                _investorFlowText(
                  row.otherCorporation,
                  closePrice: row.closePrice,
                  unit: unit,
                ),
              ],
              values: [
                null,
                row.financialInvestment,
                row.investmentTrust,
                row.pension,
                row.insurance,
                row.otherInstitution,
                row.otherCorporation,
              ],
            ),
        ],
      ),
    ),
  );

  Widget _row({
    required List<String> cells,
    List<int?>? values,
    bool header = false,
  }) => Container(
    height: header ? 38 : 41,
    decoration: BoxDecoration(
      color: header ? const Color(0xFFF7F8FA) : Colors.white,
      border: const Border(top: BorderSide(color: _marketLine)),
    ),
    child: Row(
      children: [
        for (var index = 0; index < cells.length; index += 1)
          SizedBox(
            width: index == 0 ? 82 : 94,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  cells[index],
                  maxLines: 1,
                  style: TextStyle(
                    color: header
                        ? _marketInk
                        : values?[index] == null
                        ? _marketMuted
                        : _investorFlowColor(values![index]!),
                    fontSize: header ? 10 : 11,
                    fontWeight: header ? FontWeight.w800 : FontWeight.w700,
                    fontFeatures: _marketNumberFeatures,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _CompanyOverviewCard extends StatelessWidget {
  const _CompanyOverviewCard({
    required this.definition,
    required this.snapshot,
    required this.sharesOutstanding,
    required this.marketCap,
    required this.ranking,
    required this.ownedShares,
  });

  final _StockDefinition definition;
  final FictionalFinancialSnapshot snapshot;
  final int sharesOutstanding;
  final int marketCap;
  final _MarketCapRanking ranking;
  final double ownedShares;

  @override
  Widget build(BuildContext context) {
    final products = definition.products.isEmpty
        ? <String>[definition.sector]
        : definition.products;
    final rankLabel = ranking.rank == null
        ? '순위 없음'
        : '${ranking.rank}위 / ${ranking.companyCount}개사';
    final facts = <_CompanyFactTile>[
      _CompanyFactTile(
        label: '시가총액',
        value: _compactWonAmount(marketCap),
        valueKey: const Key('company-market-cap-value'),
      ),
      _CompanyFactTile(
        label: '국내 시가총액 순위',
        value: rankLabel,
        valueKey: const Key('company-market-cap-rank-value'),
      ),
      _CompanyFactTile(
        label: '내 보유주식수',
        value: '${_displayUnits(ownedShares)}주',
        valueKey: const Key('company-owned-shares-value'),
        highlighted: true,
      ),
      _CompanyFactTile(
        label: '내 지분율',
        value: _ownershipPercent(ownedShares, sharesOutstanding),
        valueKey: const Key('company-ownership-percent-value'),
        highlighted: true,
      ),
      _CompanyFactTile(label: '발행주식수', value: '${_money(sharesOutstanding)}주'),
      _CompanyFactTile(label: '상장시장', value: definition.market),
      _CompanyFactTile(label: '업종', value: definition.sector),
      _CompanyFactTile(
        label: '상장일',
        value: _companyListingDate(definition.listedOn),
      ),
    ];
    return Container(
      key: const Key('company-overview-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _marketLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.apartment_rounded, color: Color(0xFF7253C7), size: 20),
              SizedBox(width: 7),
              Text(
                '기업정보',
                style: TextStyle(
                  color: _marketInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            definition.summary,
            style: const TextStyle(
              color: Color(0xFF4E5866),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < facts.length; index += 2) ...[
            SizedBox(
              height: 66,
              child: Row(
                children: [
                  Expanded(child: facts[index]),
                  const SizedBox(width: 8),
                  Expanded(child: facts[index + 1]),
                ],
              ),
            ),
            if (index + 2 < facts.length) const SizedBox(height: 8),
          ],
          const SizedBox(height: 13),
          const Text(
            '주요 사업',
            style: TextStyle(
              color: _marketMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final product in products)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EDFC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    product,
                    style: const TextStyle(
                      color: Color(0xFF6448AA),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 11),
          const Text(
            '※ 내 지분율은 보유주식수 ÷ 발행주식수로 계산합니다.\n'
            '국내 순위는 이 세이브의 게임 내 국내 상장사 시가총액 기준입니다.',
            style: TextStyle(
              color: Color(0xFF929AA7),
              fontSize: 9,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyFactTile extends StatelessWidget {
  const _CompanyFactTile({
    required this.label,
    required this.value,
    this.valueKey,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: highlighted ? const Color(0xFFFFF3F7) : const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(11),
      border: highlighted ? Border.all(color: const Color(0xFFF2B8CE)) : null,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: _marketMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            key: valueKey,
            maxLines: 1,
            style: TextStyle(
              color: highlighted ? const Color(0xFFC43E72) : _marketInk,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFeatures: _marketNumberFeatures,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CompanyFundamentalsCard extends StatelessWidget {
  const _CompanyFundamentalsCard({
    required this.snapshot,
    required this.sharesOutstanding,
    required this.price,
    required this.marketCap,
    required this.relations,
  });

  final FictionalFinancialSnapshot snapshot;
  final int sharesOutstanding;
  final double price;
  final int marketCap;
  final List<FictionalCompanyRelation> relations;

  @override
  Widget build(BuildContext context) {
    final eps = sharesOutstanding <= 0
        ? 0.0
        : snapshot.netIncome * 4 / sharesOutstanding;
    final bps = sharesOutstanding <= 0
        ? 0.0
        : snapshot.equity / sharesOutstanding;
    final per = eps <= 0 ? null : price / eps;
    final pbr = bps <= 0 ? null : price / bps;
    final surprise = snapshot.earningsSurprisePct;
    final visibleRelations = relations.take(4).toList(growable: false);
    return Container(
      key: const Key('company-fundamentals-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _marketLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '분기 재무와 시장 기대',
                  style: TextStyle(
                    color: _marketInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                snapshot.period,
                style: const TextStyle(
                  color: _marketMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FundamentalMetric(
                label: '시가총액',
                value: _compactWonAmount(marketCap),
                valueKey: const Key('company-fundamentals-market-cap-value'),
              ),
              _FundamentalMetric(
                label: '매출',
                value: _compactWonAmount(snapshot.revenue),
              ),
              _FundamentalMetric(
                label: '영업이익',
                value: _compactWonAmount(snapshot.operatingProfit),
                tone: snapshot.operatingProfit,
              ),
              _FundamentalMetric(
                label: '영업현금흐름',
                value: _compactWonAmount(snapshot.operatingCashFlow),
                tone: snapshot.operatingCashFlow,
              ),
              _FundamentalMetric(
                label: 'PER',
                value: per == null ? '적자' : '${per.toStringAsFixed(1)}배',
              ),
              _FundamentalMetric(
                label: 'PBR',
                value: pbr == null ? '-' : '${pbr.toStringAsFixed(1)}배',
              ),
              _FundamentalMetric(
                label: 'ROE',
                value: '${snapshot.roe.toStringAsFixed(1)}%',
                tone: snapshot.roe.round(),
              ),
              _FundamentalMetric(
                label: '수주잔고',
                value: _compactWonAmount(snapshot.orderBacklog),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '시장 예상 대비 영업이익 '
            '${surprise >= 0 ? '+' : ''}${surprise.toStringAsFixed(1)}% · '
            '영업이익률 ${snapshot.operatingMargin.toStringAsFixed(1)}% · '
            '현금 ${_compactWonAmount(snapshot.cash)} / '
            '차입금 ${_compactWonAmount(snapshot.debt)}',
            style: TextStyle(
              color: surprise >= 0
                  ? const Color(0xFF18794E)
                  : const Color(0xFFB42332),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (visibleRelations.isNotEmpty) ...[
            const Divider(height: 24, color: _marketLine),
            const Text(
              '사업 관계망',
              style: TextStyle(
                color: _marketInk,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final relation in visibleRelations)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _marketLine),
                    ),
                    child: Text(
                      '${_relationLabel(relation.type)} · '
                      '${relation.relatedName}',
                      style: const TextStyle(
                        color: _marketMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _relationLabel(FictionalCompanyRelationType type) =>
      switch (type) {
        FictionalCompanyRelationType.supplier => '공급사',
        FictionalCompanyRelationType.customer => '고객사',
        FictionalCompanyRelationType.competitor => '경쟁사',
        FictionalCompanyRelationType.partner => '협력사',
        FictionalCompanyRelationType.parent => '모회사',
        FictionalCompanyRelationType.subsidiary => '자회사',
      };
}

class _FundamentalMetric extends StatelessWidget {
  const _FundamentalMetric({
    required this.label,
    required this.value,
    this.valueKey,
    this.tone,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final int? tone;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 112,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _marketMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          key: valueKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: tone == null
                ? _marketInk
                : tone! >= 0
                ? const Color(0xFF18794E)
                : const Color(0xFFB42332),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFeatures: _marketNumberFeatures,
          ),
        ),
      ],
    ),
  );
}

class _MarketSessionNoticeCard extends StatelessWidget {
  const _MarketSessionNoticeCard({
    required this.isOpening,
    required this.onDismiss,
  });

  final bool isOpening;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final accent = isOpening
        ? const Color(0xFF00B875)
        : const Color(0xFF52627A);
    final pale = isOpening ? const Color(0xFFEAFBF4) : const Color(0xFFEEF2F8);
    final time = isOpening ? '09:00' : '15:00';
    final title = isOpening ? '장이 시작되었습니다' : '장이 마감되었습니다';
    final description = isOpening
        ? '정규장이 열렸어요.\n이제 국내 종목의 움직임을 확인해 보세요.'
        : '정규장이 마감됐어요.\n오늘의 15:00 종가가 기준 가격으로 확정됐어요.';
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: Container(
                key: Key(
                  isOpening
                      ? 'market-session-open-dialog'
                      : 'market-session-close-dialog',
                ),
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Colors.white, pale],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: accent.withValues(alpha: 0.24)),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 34,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: accent.withValues(alpha: 0.28),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isOpening
                                ? Icons.notifications_active_rounded
                                : Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              color: accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF171B24),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF596474),
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('market-session-notice-confirm'),
                        onPressed: onDismiss,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketTutorialOverlay extends StatelessWidget {
  const _MarketTutorialOverlay({
    required this.step,
    required this.targetKey,
    required this.onAction,
  });

  final int step;
  final GlobalKey? targetKey;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => _StockTutorialGuideOverlay(
    overlayKey: const Key('market-tutorial-overlay'),
    actionKey: const Key('market-tutorial-next'),
    targetActionKey: const Key('market-tutorial-target'),
    targetKey: targetKey,
    messageId: 'market-$step',
    speakers: switch (step) {
      0 => const <String>['한서윤 선생님', '한서윤 선생님', '한서윤 선생님', '한서윤 선생님'],
      1 => const <String>['한서윤 선생님', '한서윤 선생님', '한서윤 선생님'],
      _ => const <String>['한서윤 선생님', '한서윤 선생님', '한서윤 선생님', '한서윤 선생님'],
    },
    messages: switch (step) {
      0 => const [
        '이 교실이 회사라고 하죠. PC 열 대, 의자 열 개, 칠판 하나. 이걸 열 조각으로 나눈 게 주식이에요. 물건을 자르는 게 아니고 권리를 나누는 겁니다.',
        '이게 홈이에요. 오늘 사람들이 많이 사고판 회사가 위에 있어요. 「거래대금」은 오늘 그 회사 조각을 사고판 돈을 다 더한 겁니다.',
        '옆의 「회전율」은 회사가 낸 조각 전체 중에서 오늘 주인이 바뀐 비율이에요. 열 조각 중 셋이 손을 바꿨으면 30%입니다.',
        '둘 다 활발했다는 뜻일 뿐이에요. 이 표에는 회사가 돈을 벌었는지가 하나도 안 나옵니다. 그걸 알고 보세요.',
      ],
      1 => const [
        '회사를 찾는 방법이 네 가지예요. 이름, 번호, 시장별, 관심 목록. 이름은 바뀔 수 있지만 번호는 잘 안 바뀝니다.',
        '「신규」 딱지는 새로 나왔다는 뜻일 뿐이에요. 싼 것도 비싼 것도 아니고, 아직 확인할 자료가 적다는 뜻입니다.',
        '자료가 적으면 안 사는 것도 판단이에요. 안 사기로 했으면 그 이유도 노트에 적으세요.',
      ],
      _ => const [
        '한 줄에 숫자가 세 개예요. 지금 값, 어제보다 얼마나 움직였는지, 오늘 오간 돈입니다.',
        '빨간 게 오른 것, 파란 게 내린 것이에요. 이건 이유가 없어요. 우리나라가 그렇게 정했으니 외우는 수밖에 없습니다.',
        '한 조각 값이 싸다고 회사가 싼 게 아니에요. 조각을 잘게 나눈 회사는 한 조각이 원래 싸요.',
        '싼 거랑 작은 거는 다른 겁니다. 그 문장 그대로 적어 두세요.',
      ],
    },
    actionLabel: switch (step) {
      0 => '주식 탭 눌러 보기',
      1 => '검색·분류 화면 열기',
      _ => '한빛통신 열기',
    },
    teacherPoseAsset: switch (step) {
      0 => _stockTeacherPosePointer,
      1 => _stockTeacherPoseExplain,
      _ => _stockTeacherPoseBook,
    },
    onAction: onAction,
  );
}

class _MarketDetailTutorialOverlay extends StatelessWidget {
  const _MarketDetailTutorialOverlay({
    required this.step,
    required this.targetKey,
    required this.onAction,
  });

  final int step;
  final GlobalKey? targetKey;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => _StockTutorialGuideOverlay(
    overlayKey: const Key('market-detail-tutorial-overlay'),
    actionKey: const Key('market-detail-tutorial-next'),
    targetActionKey: const Key('market-detail-tutorial-target'),
    targetKey: targetKey,
    messageId: 'market-detail-$step',
    speakers: switch (step) {
      0 => const <String>['한서윤 선생님', '한서윤 선생님', '한서윤 선생님'],
      1 => const <String>['한서윤 선생님', '한서윤 선생님', '한서윤 선생님'],
      2 => const <String>['한서윤 선생님', '한서윤 선생님', '한서윤 선생님'],
      3 => const <String>['한서윤 선생님', '한서윤 선생님', '한서윤 선생님', '한서윤 선생님'],
      4 => const <String>['한서윤 선생님', '한서윤 선생님', '한서윤 선생님', '한서윤 선생님'],
      _ => const <String>['한서윤 선생님', '한서윤 선생님', '한서윤 선생님'],
    },
    messages: switch (step) {
      0 => const [
        '한빛통신이에요. 제일 큰 숫자가 지금 조각 하나 값. 그 아래는 어제 장이 끝났을 때랑 비교한 겁니다.',
        '빨간색은 오늘 올랐다는 기록이에요. 다음 가격 보증서가 아닙니다.',
        '어제 올랐으니 오늘도 오른다는 건 이유가 아니에요. 왜 올랐는지를 알아야 오늘도 될지 압니다.',
      ],
      1 => const [
        '막대기 하나가 하루예요. 가격이 지나온 길입니다.',
        '하루만 보면 올랐고 일 년을 보면 계속 내렸을 수도 있어요. 둘 다 같은 회사고 둘 다 사실입니다.',
        '그러니 자기가 어떤 기간으로 볼지 먼저 정해야 해요. 그걸 정하는 게 투자입니다. 정해 주는 규칙은 없어요.',
      ],
      2 => const [
        '주문 전에 두 칸을 채워야 해요. 왜 사는지, 그리고 언제 팔지.',
        '산 다음에 쓰면 이유가 바뀝니다. 사람은 자기한테 유리하게 기억해요. 그래서 먼저 씁니다.',
        '「오르면 판다」는 조건이 아니에요. 숫자로 안 쓰면 나중에 아무 말이나 할 수 있습니다. 두 칸 다 채우세요.',
      ],
      3 => const [
        '이 표가 호가예요. 부르는 값이라는 뜻입니다. 시장에서 값 깎는 것과 비슷한데, 소리 대신 숫자로 부릅니다.',
        '위는 이 값 주면 팔겠다는 사람들, 아래는 이 값이면 사겠다는 사람들이에요.',
        '둘 사이는 값이 없는 자리입니다. 하나가 양보하면 만나고 그때 거래가 돼요. 양보하는 쪽은 급한 사람입니다.',
        '값이 너무 빨리 움직이면 한 일 분쯤 멈춰요. 그때 종목 이름 옆에 「VI」 배지가 붙고 호가창 위에 안내가 뜹니다. 회사가 뭘 잘못한 게 아니라 사람들이 급했던 거예요. 오늘 실습에서는 안 뜰 수도 있습니다.',
      ],
      4 => const [
        '위쪽 숫자를 누르면 그 값이 주문에 들어와요. 이게 지정가입니다. 이 값까지만 내겠다는 뜻이에요.',
        '반드시 사지는 건 아니에요. 그 값에 팔 사람이 없으면 안 사지고 줄에서 기다립니다. 그날 장이 끝날 때까지 남아 있어요.',
        '몇 개만 사질 수도 있어요. 열 개 주문했는데 셋만 사지면 남은 일곱은 계속 줄에 있습니다. 취소하거나 값을 바꿀 수 있어요.',
        '값을 높게 쓰면 확실히 사지지만 비싸게 삽니다. 빨리 사는 값과 싸게 사는 값은 반대예요. 둘 다는 못 가집니다.',
      ],
      _ => const [
        '주문 탭에는 매수·매도, 정정/취소, 미체결, 잔고가 함께 있어요.',
        '먼저 일부러 실패해 볼게요. 가진 돈보다 많이 주문해 보세요. 안 될 때 화면이 어떻게 생겼는지 지금 봐 두면 나중에 급할 때 안 놀랍니다.',
        '오늘 얻어야 하는 건 돈이 아니에요. 사고 팔았을 때 화면이 어떻게 변하는지에 대한 기억입니다.',
      ],
    },
    actionLabel: switch (step) {
      0 => '현재가 확인하기',
      1 => '정보 탭 확인하기',
      2 => '호가 탭으로 돌아가기',
      3 => '호가 가격과 수량 보기',
      4 => '가장 가까운 매도호가 누르기',
      _ => '1주 지정가 매수 연습 시작',
    },
    teacherPoseAsset: switch (step) {
      0 => _stockTeacherPoseEmphasize,
      1 => _stockTeacherPoseExplain,
      2 => _stockTeacherPoseBook,
      3 => _stockTeacherPoseCompare,
      4 => _stockTeacherPoseEmphasize,
      _ => _stockTeacherPoseListen,
    },
    onAction: onAction,
  );
}

class _OrderTicketTutorialOverlay extends StatelessWidget {
  const _OrderTicketTutorialOverlay({
    required this.limitPrice,
    required this.onDone,
  });

  final double? limitPrice;
  final Future<void> Function() onDone;

  @override
  Widget build(BuildContext context) => _StockTutorialGuideOverlay(
    overlayKey: const Key('market-order-tutorial-overlay'),
    actionKey: const Key('market-order-tutorial-done'),
    targetActionKey: const Key('market-order-tutorial-target'),
    targetKey: null,
    messageId: 'market-order-${limitPrice?.round() ?? 'start'}',
    speakers: const <String>['한서윤 선생님', '한서윤 선생님', '한서윤 선생님'],
    messages: limitPrice == null
        ? const [
            '이건 수업용 계좌예요. 여기서 잃어도 정식 국가계좌의 원금은 그대로 남습니다.',
            '잔액이 부족하면 빚을 지는 게 아니라 주문 자체를 안 받아요. 그것부터 직접 눌러 확인할게요.',
            '보이는 잔량보다 많이 주문하면 있는 만큼만 사지고 나머지는 미체결로 남습니다. 그 차이도 봐 두세요.',
          ]
        : [
            '방금 누른 ${_money(limitPrice!.round())}원이 매수 지정가에 들어왔어요. 이 값까지만 내겠다는 뜻입니다.',
            '같은 값을 쓴 사람이 여럿이면 먼저 줄 선 주문부터 사집니다. 값이 같으면 시간이 순서를 정해요.',
            '주문 전에 두 가지를 확인할게요. 돈이 부족할 때와 일부만 사질 때. 둘 다 실패지만 결과가 다릅니다.',
          ],
    actionLabel: '가격·수량·수수료 확인하기',
    teacherPoseAsset: limitPrice == null
        ? _stockTeacherPoseBook
        : _stockTeacherPoseEmphasize,
    onAction: () => unawaited(onDone()),
  );
}

class _StockTutorialGuideOverlay extends StatefulWidget {
  const _StockTutorialGuideOverlay({
    required this.overlayKey,
    required this.actionKey,
    required this.targetActionKey,
    required this.targetKey,
    required this.messageId,
    required this.speakers,
    required this.messages,
    required this.actionLabel,
    required this.teacherPoseAsset,
    required this.onAction,
    this.characterAssets,
  }) : assert(messages.length > 0),
       assert(speakers.length == messages.length),
       assert(
         characterAssets == null || characterAssets.length == messages.length,
       );

  final Key overlayKey;
  final Key actionKey;
  final Key targetActionKey;
  final GlobalKey? targetKey;
  final Object messageId;
  final List<String> speakers;
  final List<String> messages;
  final String actionLabel;
  final String teacherPoseAsset;
  final List<String?>? characterAssets;
  final VoidCallback onAction;
  @override
  State<_StockTutorialGuideOverlay> createState() =>
      _StockTutorialGuideOverlayState();
}

class _StockTutorialGuideOverlayState
    extends State<_StockTutorialGuideOverlay> {
  final GlobalKey _layoutKey = GlobalKey();
  int _messageIndex = 0;
  int _wrongTapCount = 0;
  String? _wrongTapFeedback;
  Rect? _targetRect;
  Timer? _settleTimer;

  bool get _isLastMessage => _messageIndex >= widget.messages.length - 1;

  GlobalKey? get _activeTargetKey => _isLastMessage ? widget.targetKey : null;

  @override
  void initState() {
    super.initState();
    _scheduleTargetUpdate();
  }

  @override
  void didUpdateWidget(covariant _StockTutorialGuideOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageId != widget.messageId) {
      _messageIndex = 0;
      _wrongTapCount = 0;
      _wrongTapFeedback = null;
      _targetRect = null;
      _scheduleTargetUpdate();
      return;
    }
    if (oldWidget.targetKey != widget.targetKey) {
      _targetRect = null;
      _scheduleTargetUpdate();
    }
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  void _scheduleTargetUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 520), _updateTargetRect);
  }

  void _updateTargetRect() {
    if (!mounted) return;
    final targetBox =
        _activeTargetKey?.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        _layoutKey.currentContext?.findRenderObject() as RenderBox?;
    if (targetBox == null ||
        overlayBox == null ||
        !targetBox.hasSize ||
        !overlayBox.hasSize) {
      return;
    }
    final globalTopLeft = targetBox.localToGlobal(Offset.zero);
    final localTopLeft = overlayBox.globalToLocal(globalTopLeft);
    final next = (localTopLeft & targetBox.size).inflate(5);
    if (_targetRect == next) return;
    setState(() => _targetRect = next);
  }

  void _handleAction() {
    if (_isLastMessage) {
      widget.onAction();
      return;
    }
    final nextIndex = _messageIndex + 1;
    setState(() {
      _messageIndex = nextIndex;
      _wrongTapFeedback = null;
      _targetRect = null;
    });
    if (nextIndex >= widget.messages.length - 1 && widget.targetKey != null) {
      _scheduleTargetUpdate();
    }
  }

  void _handleWrongTap() {
    // 같은 문구가 반복되면 실수가 창피해진다. 같이 틀려 주는 대사를 섞어
    // 오조작이 교실의 일상으로 읽히게 한다.
    final feedback = switch (_wrongTapCount % 8) {
      0 => '수아: 어, 거기 아니야. 나도 방금 딴 데 눌렀어.',
      1 => '이지안: 그거 눌러도 아무 일 안 나. 확인 누르기 전엔 안 사져.',
      2 => '정아린: 노란 거. 노란 거 눌러.',
      3 => '김서아: 괜찮아. 나도 두 번 잘못 눌렀어.',
      4 => '오지우: 속보. 06번 학생, 화면 다른 데를 누름.',
      5 => '박하은: 천천히 해도 돼. 아직 아무도 안 끝났어.',
      6 => '윤채아: 지금 누른 데는 아무 기능 없어.',
      _ => '한서윤 선생님: 노란 테두리로 돌아오세요.',
    };
    setState(() {
      _wrongTapCount += 1;
      _wrongTapFeedback = feedback;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasTarget = _activeTargetKey != null;
    final activeSpeaker = widget.speakers[_messageIndex];
    final isNarration = activeSpeaker == _stockTutorialNarrationSpeaker;
    final isTeacherPage = activeSpeaker == '한서윤 선생님';
    // 지문 페이지는 중앙 전신 슬롯을 비운다. 화자 자산이 없다는 이유로
    // 주인공 스프라이트를 대신 세우면 지문이 주인공 대사로 읽힌다.
    final activeCharacterAsset = isNarration
        ? ''
        : widget.characterAssets?[_messageIndex] ??
              (isTeacherPage
                  ? widget.teacherPoseAsset
                  : _stockTutorialPlayerAsset);
    return LayoutBuilder(
      builder: (context, constraints) {
        final guideWidth = constraints.maxWidth;
        final teacherWidth = (guideWidth * 0.5).clamp(180.0, 250.0).toDouble();
        final speechRight = teacherWidth * 0.78;
        final speechAtTop =
            hasTarget &&
            (_targetRect?.center.dy ?? constraints.maxHeight) >
                constraints.maxHeight * 0.38;
        return KeyedSubtree(
          key: widget.overlayKey,
          child: Stack(
            key: _layoutKey,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('market-tutorial-wrong-tap-area'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleWrongTap,
                  child: const ColoredBox(color: Color(0x990C1424)),
                ),
              ),
              if (_targetRect != null)
                Positioned.fromRect(
                  rect: _targetRect!,
                  child: GestureDetector(
                    key: widget.targetActionKey,
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onAction,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFD85E),
                          width: 4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xAAFFD85E),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.touch_app_rounded,
                          color: Color(0xFFFFE58C),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              if (!isNarration)
                Positioned(
                  right: -6,
                  bottom: 54,
                  child: !isTeacherPage
                      ? _StockTutorialStudent(
                          asset: activeCharacterAsset,
                          speaker: activeSpeaker,
                          width: teacherWidth,
                        )
                      : _StockTutorialTeacher(
                          asset: activeCharacterAsset,
                          width: teacherWidth,
                        ),
                ),
              Positioned(
                left: 12,
                right: isNarration ? 12 : speechRight,
                top: speechAtTop ? 44 : null,
                bottom: speechAtTop ? null : 185,
                child: _StockTutorialSpeechBubble(
                  speaker: activeSpeaker,
                  message: widget.messages[_messageIndex],
                  page: _messageIndex + 1,
                  pageCount: widget.messages.length,
                  actionKey: widget.actionKey,
                  actionLabel: _isLastMessage
                      ? widget.actionLabel
                      : isNarration
                      ? '계속 읽기'
                      : isTeacherPage
                      ? '학생 반응 듣기'
                      : '다음 말 듣기',
                  showAction: !hasTarget,
                  waitingForTarget: hasTarget && _targetRect == null,
                  onAction: _handleAction,
                ),
              ),
              if (_wrongTapFeedback != null)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 116,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const Key('market-tutorial-wrong-tap-feedback'),
                      decoration: BoxDecoration(
                        color: const Color(0xF21E2B44),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFD85E)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        child: Text(
                          _wrongTapFeedback!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StockTutorialStudent extends StatelessWidget {
  const _StockTutorialStudent({
    required this.asset,
    required this.speaker,
    required this.width,
  });

  final String asset;
  final String speaker;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.42;
    return SizedBox(
      key: const Key('market-tutorial-student'),
      width: width,
      height: height,
      child: Image.asset(
        asset,
        key: const Key('market-tutorial-student-upper-body'),
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _StockTutorialTeacher extends StatelessWidget {
  const _StockTutorialTeacher({required this.asset, required this.width});

  final String asset;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.42;
    return SizedBox(
      key: const Key('market-tutorial-teacher'),
      width: width,
      height: height,
      child: Image.asset(
        asset,
        key: const Key('market-tutorial-teacher-upper-body'),
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _StockTutorialSpeechBubble extends StatelessWidget {
  const _StockTutorialSpeechBubble({
    required this.speaker,
    required this.message,
    required this.page,
    required this.pageCount,
    required this.actionKey,
    required this.actionLabel,
    required this.showAction,
    required this.waitingForTarget,
    required this.onAction,
  });

  final String speaker;
  final String message;
  final int page;
  final int pageCount;
  final Key actionKey;
  final String actionLabel;
  final bool showAction;
  final bool waitingForTarget;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 17, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFAFC2F3), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(0, -29),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF536A96),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                speaker,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pageCount > 1) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$page / $pageCount',
                      key: const Key('market-tutorial-page-indicator'),
                      style: const TextStyle(
                        color: Color(0xFF7C8BAA),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    message,
                    key: ValueKey<String>(message),
                    style: const TextStyle(
                      color: Color(0xFF24375A),
                      fontSize: 12,
                      height: 1.48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showAction)
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton(
                key: actionKey,
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF536A96),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Icon(
                  waitingForTarget
                      ? Icons.hourglass_top_rounded
                      : Icons.touch_app_rounded,
                  size: 16,
                  color: const Color(0xFF536A96),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    waitingForTarget
                        ? '강조할 위치를 찾고 있어요…'
                        : '노란 테두리 안을 눌러 계속하세요.',
                    style: const TextStyle(
                      color: Color(0xFF536A96),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class _MarketBottomNavigation extends StatelessWidget {
  const _MarketBottomNavigation({
    required this.selected,
    required this.onChanged,
    this.tutorialExploreKey,
  });

  final _MarketSection selected;
  final ValueChanged<_MarketSection> onChanged;
  final GlobalKey? tutorialExploreKey;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFF0F1F3))),
    ),
    padding: const EdgeInsets.fromLTRB(10, 5, 10, 6),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          _item(_MarketSection.home, Icons.home_rounded, '홈'),
          _item(_MarketSection.explore, Icons.candlestick_chart_rounded, '주식'),
          _item(
            _MarketSection.account,
            Icons.account_balance_wallet_rounded,
            '내 투자',
          ),
        ],
      ),
    ),
  );

  Widget _item(_MarketSection section, IconData icon, String label) {
    final active = selected == section;
    return Expanded(
      child: RepaintBoundary(
        key: section == _MarketSection.explore ? tutorialExploreKey : null,
        child: InkWell(
          key: Key('market-nav-${section.name}'),
          onTap: () => onChanged(section),
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 48,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: active ? _marketAccent : const Color(0xFFADB5BD),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? _marketAccent : const Color(0xFF8B95A1),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketIndexBoard extends StatelessWidget {
  const _MarketIndexBoard({
    required this.mainIndex,
    required this.growthIndex,
    required this.sectorIndices,
  });

  final _LiveMarketIndex mainIndex;
  final _LiveMarketIndex growthIndex;
  final List<_LiveMarketIndex> sectorIndices;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('market-index-board'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _marketLine),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '시장 지수',
          style: TextStyle(
            color: _marketInk,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _MarketIndexTile(
                key: const Key('market-main-index'),
                index: mainIndex,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MarketIndexTile(
                key: const Key('market-growth-index'),
                index: growthIndex,
              ),
            ),
          ],
        ),
        if (sectorIndices.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final index in sectorIndices)
                Container(
                  key: ValueKey('market-sector-index-${index.label}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${index.label} '
                    '${index.rate >= 0 ? '+' : ''}${index.rate.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: _priceColor(index.rate),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFeatures: _marketNumberFeatures,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _MarketIndexTile extends StatelessWidget {
  const _MarketIndexTile({super.key, required this.index});

  final _LiveMarketIndex index;

  @override
  Widget build(BuildContext context) {
    final color = _priceColor(index.rate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index.label,
            style: const TextStyle(
              color: _marketMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            index.level.toStringAsFixed(2),
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFeatures: _marketNumberFeatures,
            ),
          ),
          Text(
            '${index.rate >= 0 ? '+' : ''}${index.rate.toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFeatures: _marketNumberFeatures,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyMarketReportCard extends StatelessWidget {
  const _DailyMarketReportCard({
    required this.items,
    required this.cash,
    required this.purchasing,
    required this.canPurchase,
    required this.onPurchase,
  });

  final List<Map<String, dynamic>> items;
  final int cash;
  final bool purchasing;
  final bool canPurchase;
  final VoidCallback? onPurchase;

  @override
  Widget build(BuildContext context) {
    final purchased = items.isNotEmpty;
    return Container(
      key: const Key('daily-market-report-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: purchased ? const Color(0xFFFFFAEA) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: purchased ? const Color(0xFFF0C24A) : _marketLine,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D101828),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: purchased
                      ? const Color(0xFFFFE7A3)
                      : const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  purchased
                      ? Icons.fact_check_rounded
                      : Icons.manage_search_rounded,
                  color: purchased ? const Color(0xFF9B6800) : _marketAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchased ? '오늘의 조사 보고서' : '오늘의 숨은 시장 조사',
                      style: const TextStyle(
                        color: _marketInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      purchased
                          ? '현장 징후만 정리했습니다. 상승·하락과 최종 결과는 알려주지 않습니다.'
                          : '조간신문은 어제만 말합니다. 오늘의 이상 징후는 별도 조사로만 살펴볼 수 있어요.',
                      style: const TextStyle(
                        color: _marketMuted,
                        fontSize: 11,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (purchased) ...[
            const SizedBox(height: 14),
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const Divider(height: 22, color: _marketLine),
              Text(
                '${items[index]['companyName'] ?? '시장 전체'} · ${items[index]['sector'] ?? '수급'}',
                style: const TextStyle(
                  color: _marketAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${items[index]['hint'] ?? ''}',
                style: const TextStyle(
                  color: _marketInk,
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('purchase-market-report-button'),
                onPressed: purchasing || !canPurchase ? null : onPurchase,
                icon: purchasing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open_rounded, size: 18),
                label: Text(
                  purchasing
                      ? '조사 중…'
                      : canPurchase
                      ? '1,200원에 조사 보고서 구매 · 은행 ${_money(cash)}원'
                      : '현재 시각 이후 조사할 미공개 신호 없음',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _marketAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MarketSectionTitle extends StatelessWidget {
  const _MarketSectionTitle({this.title = '', this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF202632),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            action!,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
    ],
  );
}

class _MarketRankingRow extends StatelessWidget {
  const _MarketRankingRow({
    super.key,
    required this.rank,
    required this.definition,
    required this.live,
    required this.turnoverFor,
    required this.onTap,
  });

  final int rank;
  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final double Function(_StockDefinition, _LiveStock) turnoverFor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<_LiveStock>(
    valueListenable: live,
    builder: (context, quote, _) {
      final rate = _changeRate(quote);
      final change = quote.price - quote.previousClose;
      return Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _marketLine)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    rank.toString(),
                    style: const TextStyle(
                      color: Color(0xFF8B95A1),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: _marketNumberFeatures,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        definition.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _marketInk,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${definition.code} · 거래대금 '
                        '${_compactEok(turnoverFor(definition, quote))}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _marketMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFeatures: _marketNumberFeatures,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 104,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _displayPrice(quote.price, definition.currency),
                        maxLines: 1,
                        style: const TextStyle(
                          color: _marketInk,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFeatures: _marketNumberFeatures,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _signedPercent(rate),
                        style: TextStyle(
                          color: change.abs() < 0.005
                              ? const Color(0xFF7B8491)
                              : _priceColor(change),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: _marketNumberFeatures,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _TradeJournalPreview extends StatelessWidget {
  const _TradeJournalPreview({
    required this.state,
    required this.entries,
    required this.assetNameFor,
    required this.onOpenAll,
  });

  final GameState state;
  final List<LedgerEntry> entries;
  final String Function(String assetId) assetNameFor;
  final VoidCallback? onOpenAll;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        key: const Key('trade-journal-empty'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _marketLine),
        ),
        child: const Text(
          '아직 체결된 매매가 없어요. 첫 거래 뒤 수수료와 실현손익까지 여기에 기록됩니다.',
          style: TextStyle(
            color: _marketMuted,
            fontSize: 11,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Container(
      key: const Key('trade-journal-preview'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _marketLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index += 1) ...[
            _TradeJournalEntryRow(
              state: state,
              entry: entries[index],
              assetName: assetNameFor(entries[index].assetId),
              compact: true,
            ),
            if (index != entries.length - 1)
              const Divider(height: 1, color: _marketLine),
          ],
          if (onOpenAll != null)
            TextButton.icon(
              key: const Key('open-trade-journal'),
              onPressed: onOpenAll,
              icon: const Icon(Icons.receipt_long_rounded, size: 17),
              label: const Text('전체 체결내역과 비용 보기'),
            ),
        ],
      ),
    );
  }
}

class _TradeJournalSheet extends StatelessWidget {
  const _TradeJournalSheet({
    required this.state,
    required this.entries,
    required this.assetNameFor,
  });

  final GameState state;
  final List<LedgerEntry> entries;
  final String Function(String assetId) assetNameFor;

  @override
  Widget build(BuildContext context) {
    final fees = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.tradingFee + entry.transactionTax,
    );
    final realized = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.realizedPnl,
    );
    final turnover = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.notional.abs(),
    );
    return SizedBox(
      key: const Key('trade-journal-sheet'),
      height: MediaQuery.sizeOf(context).height * 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 10, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '매매일지 · 거래내역',
                        style: TextStyle(
                          color: _marketInk,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '체결 시각·평균가·비용·실현손익을 원장 그대로 보여 줍니다.',
                        style: TextStyle(
                          color: _marketMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: _TradeJournalMetric(
                    label: '누적 거래대금',
                    value: _compactWonAmount(turnover),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _TradeJournalMetric(
                    label: '수수료·세금',
                    value: _compactWonAmount(fees),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _TradeJournalMetric(
                    label: '실현손익',
                    value: realized == 0
                        ? '0원'
                        : '${realized > 0 ? '+' : '-'}'
                              '${_compactWonAmount(realized.abs())}',
                    valueColor: _priceColor(realized.toDouble()),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _marketLine),
          Expanded(
            child: ListView.separated(
              key: const Key('trade-journal-list'),
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              itemCount: entries.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: _marketLine),
              itemBuilder: (_, index) {
                final entry = entries[index];
                return _TradeJournalEntryRow(
                  key: Key('trade-journal-entry-${entry.id}'),
                  state: state,
                  entry: entry,
                  assetName: assetNameFor(entry.assetId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeJournalMetric extends StatelessWidget {
  const _TradeJournalMetric({
    required this.label,
    required this.value,
    this.valueColor = _marketInk,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: _marketMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontFeatures: _marketNumberFeatures,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TradeJournalEntryRow extends StatelessWidget {
  const _TradeJournalEntryRow({
    super.key,
    required this.state,
    required this.entry,
    required this.assetName,
    this.compact = false,
  });

  final GameState state;
  final LedgerEntry entry;
  final String assetName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isBuy = entry.tradeSide == TradeSide.buy.name;
    final sideLabel = isBuy ? '매수' : '매도';
    final orderLabel = entry.orderType == TradeOrderType.market.name
        ? '시장가'
        : entry.orderType == TradeOrderType.limit.name
        ? '지정가'
        : '체결';
    final date = state.dateForDay(math.max(1, entry.day));
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}'
        '${entry.marketMinute >= 0 ? ' ${marketTimeLabel(entry.marketMinute)}' : ''}';
    final notional = entry.notional > 0
        ? entry.notional
        : (entry.tradeUnitPrice * entry.tradeQuantity).round();
    final sideColor = isBuy ? const Color(0xFFF04452) : _marketAccent;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 11 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: sideColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  sideLabel,
                  style: TextStyle(
                    color: sideColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  assetName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _marketInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                dateLabel,
                style: const TextStyle(
                  color: _marketMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontFeatures: _marketNumberFeatures,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '$orderLabel · ${_displayUnits(entry.tradeQuantity)}주 · '
            '평균 ${_money(entry.tradeUnitPrice.round())}원 · '
            '${_money(notional)}원',
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _marketInk,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w700,
              fontFeatures: _marketNumberFeatures,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 3,
            children: [
              Text(
                '수수료 ${_money(entry.tradingFee)}원',
                style: const TextStyle(
                  color: _marketMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (entry.transactionTax > 0)
                Text(
                  '거래세 ${_money(entry.transactionTax)}원',
                  style: const TextStyle(
                    color: _marketMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (!isBuy)
                Text(
                  '실현손익 ${entry.realizedPnl > 0 ? '+' : ''}'
                  '${_money(entry.realizedPnl)}원',
                  style: TextStyle(
                    color: _priceColor(entry.realizedPnl.toDouble()),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingOrderRow extends StatelessWidget {
  const _PendingOrderRow({required this.order, this.onCancel});

  final PendingTradeOrder order;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('pending-order-${order.id}'),
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: _marketLine),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${order.name} · '
                '${order.side == PendingOrderSide.buy ? '매수' : '매도'}',
                style: const TextStyle(
                  color: _marketInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_money(order.limitPrice.round())}원 · '
                '${_displayUnits(order.remainingQuantity)}주 대기'
                '${order.filledQuantity > 0 ? ' · ${_displayUnits(order.filledQuantity)}주 체결' : ''}',
                style: const TextStyle(
                  color: _marketMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          key: Key('cancel-pending-order-${order.id}'),
          onPressed: onCancel,
          child: const Text('취소'),
        ),
      ],
    ),
  );
}

class _BrokerageAccountCard extends StatelessWidget {
  const _BrokerageAccountCard({
    required this.state,
    required this.prices,
    required this.tradeEntries,
    this.onDeposit,
    this.onWithdraw,
  });

  final GameState state;
  final Map<String, double> prices;
  final List<LedgerEntry> tradeEntries;
  final VoidCallback? onDeposit;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final evaluation = state.portfolioValue(prices);
    final pnl = evaluation - state.portfolioCost;
    final rate = state.portfolioCost <= 0
        ? 0.0
        : pnl / state.portfolioCost * 100;
    final totalFees = tradeEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.tradingFee + entry.transactionTax,
    );
    final realized = tradeEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.realizedPnl,
    );
    final selfRelianceReserve = state.story.selfRelianceReserve;
    final stateRecoveryTotal = state.story.stateRecoveryTotal;
    final pnlColor = _priceColor(pnl.toDouble());
    return Container(
      key: const Key('market-account-summary'),
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.story.orphanageReboot
                ? '${state.companyName} · 제6기 국가계좌'
                : '${state.companyName} 증권계좌',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _marketMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_money(state.brokerageCash + evaluation + selfRelianceReserve)}원',
            key: const Key('market-account-total-assets'),
            style: const TextStyle(
              color: _marketInk,
              fontSize: 31,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
              fontFeatures: _marketNumberFeatures,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '평가손익 ${pnl >= 0 ? '+' : ''}${_money(pnl)}원 · ${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(2)}%',
            key: const Key('market-account-pnl'),
            style: TextStyle(
              color: pnlColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: _marketNumberFeatures,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _marketSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _AccountMetric(
                        label: '총 매입',
                        value: '${_money(state.portfolioCost)}원',
                      ),
                    ),
                    Expanded(
                      child: _AccountMetric(
                        label: '총 평가',
                        value: '${_money(evaluation)}원',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _AccountMetric(
                        label: '주문 가능',
                        value: '${_money(state.availableBrokerageCash)}원',
                      ),
                    ),
                    Expanded(
                      child: _AccountMetric(
                        label: '회사 통장',
                        value: '${_money(state.bankCash)}원',
                      ),
                    ),
                  ],
                ),
                if (state.story.orphanageReboot) ...[
                  const Divider(height: 25, color: _marketLine),
                  Row(
                    children: [
                      Expanded(
                        child: _AccountMetric(
                          label: '국가 환수 누계',
                          value: '${_money(stateRecoveryTotal)}원',
                        ),
                      ),
                      Expanded(
                        child: _AccountMetric(
                          label: '자립적립금 · 잠금',
                          value: '${_money(selfRelianceReserve)}원',
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 25, color: _marketLine),
                Row(
                  children: [
                    Expanded(
                      child: _AccountMetric(
                        label: '실현손익',
                        value:
                            '${realized >= 0 ? '+' : ''}${_money(realized)}원',
                      ),
                    ),
                    Expanded(
                      child: _AccountMetric(
                        label: '누적 거래비용',
                        value: '${_money(totalFees)}원',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.unsettledBrokerageSellProceeds > 0
                ? 'T+2 결제예정 매도대금 '
                      '${_money(state.unsettledBrokerageSellProceeds)}원 · '
                      '출금 가능 ${_money(state.withdrawableBrokerageCash)}원'
                : state.pendingBuyReservedCash > 0
                ? '미체결 매수 예약 ${_money(state.pendingBuyReservedCash)}원 · '
                      '출금 가능 ${_money(state.withdrawableBrokerageCash)}원'
                : '누적 거래비용 ${_money(totalFees)}원 · 매도 시 시대별 거래세 포함',
            key: const Key('market-account-fees'),
            style: const TextStyle(
              color: Color(0xFF8B95A1),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              fontFeatures: _marketNumberFeatures,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('market-account-deposit'),
                  onPressed: onDeposit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    elevation: 0,
                    backgroundColor: _marketAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '입금',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: OutlinedButton(
                  key: const Key('market-account-withdraw'),
                  onPressed: onWithdraw,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: _marketInk,
                    side: const BorderSide(color: _marketLine),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '출금',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountMetric extends StatelessWidget {
  const _AccountMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8B95A1),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF333D4B),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _PortfolioPositionRow extends StatelessWidget {
  const _PortfolioPositionRow({
    super.key,
    required this.position,
    required this.definition,
    required this.live,
    required this.onTap,
  });

  final PortfolioPosition position;
  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<_LiveStock>(
    valueListenable: live,
    builder: (context, quote, _) {
      final evaluation = (quote.price * position.units).round();
      final pnl = evaluation - position.totalCost;
      final rate = position.totalCost <= 0
          ? 0.0
          : pnl / position.totalCost * 100;
      final color = _priceColor(pnl.toDouble());
      return Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 15),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _marketLine)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        definition.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _marketInk,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_displayUnits(position.units)}주 · 평균 ${_money((position.totalCost / position.units).round())}원',
                        style: const TextStyle(
                          color: _marketMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFeatures: _marketNumberFeatures,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_money(evaluation)}원',
                      key: Key('position-value-${position.assetId}'),
                      style: const TextStyle(
                        color: _marketInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFeatures: _marketNumberFeatures,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pnl >= 0 ? '+' : ''}${_money(pnl)}원 · ${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(2)}%',
                      key: Key('position-rate-${position.assetId}'),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFeatures: _marketNumberFeatures,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _EmptyPortfolioCard extends StatelessWidget {
  const _EmptyPortfolioCard({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('market-empty-portfolio'),
    padding: const EdgeInsets.all(18),

    child: Column(
      children: [
        const Icon(Icons.savings_outlined, color: Color(0xFF3182F6), size: 30),
        const SizedBox(height: 8),
        const Text(
          '아직 보유한 주식이 없어요',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          '예수금을 입금한 뒤 첫 종목을 골라보세요.',
          style: TextStyle(color: Color(0xFF8B95A1), fontSize: 11),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: onExplore, child: const Text('주식 둘러보기')),
      ],
    ),
  );
}

class _BrokerageTransferSheet extends StatefulWidget {
  const _BrokerageTransferSheet({
    required this.state,
    required this.deposit,
    required this.onSubmit,
  });

  final GameState state;
  final bool deposit;
  final Future<FinanceActionResult> Function(int amount, bool deposit) onSubmit;

  @override
  State<_BrokerageTransferSheet> createState() =>
      _BrokerageTransferSheetState();
}

class _BrokerageTransferSheetState extends State<_BrokerageTransferSheet> {
  final _controller = TextEditingController();
  bool _processing = false;
  String? _error;

  int get _maxAmount => widget.deposit
      ? widget.state.bankCash
      : widget.state.withdrawableBrokerageCash;
  int get _amount =>
      int.tryParse(_controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setAmount(int amount) {
    _controller.text = math.min(amount, _maxAmount).toString();
    setState(() => _error = null);
  }

  Future<void> _submit() async {
    final amount = _amount;
    if (amount <= 0 || amount > _maxAmount || _processing) {
      setState(
        () => _error = amount > _maxAmount
            ? '이체 가능한 잔액을 초과했습니다.'
            : '이체할 금액을 입력해 주세요.',
      );
      return;
    }
    setState(() {
      _processing = true;
      _error = null;
    });
    final result = await widget.onSubmit(amount, widget.deposit);
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, result);
      return;
    }
    setState(() {
      _processing = false;
      _error = result.message;
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedPadding(
    duration: const Duration(milliseconds: 180),
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.deposit ? '증권계좌에 입금' : '증권계좌에서 출금',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.deposit
                ? '회사 통장 ${_money(widget.state.bankCash)}원에서 옮겨요.'
                : '출금 가능 예수금은 ${_money(widget.state.withdrawableBrokerageCash)}원이에요.',
            style: const TextStyle(
              color: Color(0xFF6B7684),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            key: const Key('brokerage-transfer-amount'),
            controller: _controller,
            enabled: !_processing,
            keyboardType: TextInputType.number,
            autofocus: true,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: '금액',
              suffixText: '원',
              errorText: _error,
              filled: true,
              fillColor: const Color(0xFFF4F6F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final entry in const <int, String>{
                10000: '1만',
                50000: '5만',
                100000: '10만',
              }.entries)
                ActionChip(
                  label: Text(entry.value),
                  onPressed: _maxAmount <= 0
                      ? null
                      : () => _setAmount(entry.key),
                ),
              ActionChip(
                label: const Text('전액'),
                onPressed: _maxAmount <= 0
                    ? null
                    : () => _setAmount(_maxAmount),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const Key('brokerage-transfer-submit'),
            onPressed: _processing ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _marketAccent,
              minimumSize: const Size.fromHeight(52),
            ),
            child: _processing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(widget.deposit ? '입금하기' : '출금하기'),
          ),
        ],
      ),
    ),
  );
}

class _ResearchNoteEditor extends StatefulWidget {
  const _ResearchNoteEditor({
    required this.companyName,
    required this.initialValue,
    this.tutorialRequired = false,
  });

  final String companyName;
  final String initialValue;
  final bool tutorialRequired;

  @override
  State<_ResearchNoteEditor> createState() => _ResearchNoteEditorState();
}

class _ResearchNoteEditorState extends State<_ResearchNoteEditor> {
  late final TextEditingController _controller;
  late final TextEditingController _buyReasonController;
  late final TextEditingController _sellRuleController;

  bool get _tutorialReady =>
      _buyReasonController.text.trim().isNotEmpty &&
      _sellRuleController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    final buyMatch = RegExp(
      r'(?:^|\n)매수 이유:\s*(.*)',
    ).firstMatch(widget.initialValue);
    final sellMatch = RegExp(
      r'(?:^|\n)매도 조건:\s*(.*)',
    ).firstMatch(widget.initialValue);
    _buyReasonController = TextEditingController(
      text: buyMatch?.group(1) ?? '',
    );
    _sellRuleController = TextEditingController(
      text: sellMatch?.group(1) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _buyReasonController.dispose();
    _sellRuleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedPadding(
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
    padding: EdgeInsets.fromLTRB(
      16,
      12,
      16,
      16 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기업 조사노트',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              widget.tutorialRequired
                  ? '${widget.companyName}을 왜 사는지와 언제 생각을 바꿀지 둘 다 적어야 첫 주문으로 넘어갑니다.'
                  : '${widget.companyName}의 근거와 다음 행동을 직접 적어 두세요.',
              style: const TextStyle(color: Color(0xFF68717E), height: 1.4),
            ),
            const SizedBox(height: 14),
            if (widget.tutorialRequired) ...[
              TextField(
                key: const Key('tutorial-buy-reason-input'),
                controller: _buyReasonController,
                autofocus: true,
                minLines: 2,
                maxLines: 3,
                maxLength: 120,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: '매수 이유',
                  hintText: '예: 통신 가입자가 늘고 있지만 재무도 함께 확인한다.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('tutorial-sell-rule-input'),
                controller: _sellRuleController,
                minLines: 2,
                maxLines: 3,
                maxLength: 120,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: '매도 조건',
                  hintText: '예: 가입자 증가가 꺾이거나 정한 손실선에 닿으면 판다.',
                  border: OutlineInputBorder(),
                ),
              ),
              const Text(
                '수익이 났다는 이유만으로 매도 조건을 바꾸지 않습니다.',
                style: TextStyle(
                  color: Color(0xFF8B6F21),
                  fontSize: 11,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ] else
              TextField(
                key: const Key('market-research-note-input'),
                controller: _controller,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                maxLength: 300,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: '예: 제품은 좋지만 다음 실적을 확인한 뒤 매수한다.',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('save-market-research-note'),
              onPressed: widget.tutorialRequired && !_tutorialReady
                  ? null
                  : () => Navigator.of(context).pop(
                      widget.tutorialRequired
                          ? '매수 이유: ${_buyReasonController.text.trim()}\n'
                                '매도 조건: ${_sellRuleController.text.trim()}'
                          : _controller.text,
                    ),
              icon: const Icon(Icons.save_rounded),
              label: const Text('투자노트에 저장'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MarketTabs extends StatelessWidget {
  const _MarketTabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['전체', '미래시장', '도전시장', '신규·분사', '관심'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9EBEF))),
      ),
      child: Row(
        children: List.generate(
          labels.length,
          (index) => Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  children: [
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: selected == index
                            ? const Color(0xFF171B24)
                            : const Color(0xFF9299A3),
                        fontSize: 13,
                        fontWeight: selected == index
                            ? FontWeight.w700
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 3,
                      width: selected == index ? 28 : 0,
                      decoration: BoxDecoration(
                        color: _marketAccent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketSortBar extends StatelessWidget {
  const _MarketSortBar({
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  final _MarketSort selected;
  final ValueChanged<_MarketSort> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labels = compact
        ? const <_MarketSort, String>{
            _MarketSort.turnover: '거래대금',
            _MarketSort.gainers: '상승',
            _MarketSort.losers: '하락',
            _MarketSort.name: '이름',
          }
        : const <_MarketSort, String>{
            _MarketSort.turnover: '거래대금',
            _MarketSort.gainers: '상승률',
            _MarketSort.losers: '하락률',
            _MarketSort.name: '이름',
          };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: labels.entries.map((entry) {
          final active = selected == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: InkWell(
              key: Key('market-sort-${entry.key.name}'),
              onTap: () => onChanged(entry.key),
              child: Container(
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? _marketAccent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: active ? _marketInk : _marketMuted,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({
    super.key,
    required this.definition,
    required this.live,
    required this.turnoverFor,
    required this.favorite,
    required this.onTap,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final double Function(_StockDefinition, _LiveStock) turnoverFor;
  final bool favorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<_LiveStock>(
    valueListenable: live,
    builder: (context, quote, _) {
      final change = quote.price - quote.previousClose;
      final rate = _changeRate(quote);
      final color = _priceColor(change);
      final turnover = turnoverFor(definition, quote);
      final volatility = quote.previousClose <= 0
          ? 0.0
          : (quote.high - quote.low) / quote.previousClose * 100;
      return Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _marketLine)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  definition.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _marketInk,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (favorite) ...[
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Color(0xFFFFB020),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${definition.market} · ${definition.code} · ${definition.sector}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _marketMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 104,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Hero(
                            tag: 'stock-${definition.code}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                _displayPrice(quote.price, definition.currency),
                                style: const TextStyle(
                                  color: _marketInk,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: _marketNumberFeatures,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _signedPercent(rate),
                            key: Key('stock-rate-${definition.code}'),
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFeatures: _marketNumberFeatures,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '거래대금 ${_compactEok(turnover)} · 변동폭 ${volatility.toStringAsFixed(2)}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _marketMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFeatures: _marketNumberFeatures,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 62,
                      height: 24,
                      child: CustomPaint(
                        painter: _SparklinePainter(quote.sessionHistory, color),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _QuoteGrid extends StatelessWidget {
  const _QuoteGrid({required this.quote});

  final _LiveStock quote;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _marketSurface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        _QuoteValue(label: '전일 종가', value: quote.previousClose),
        _QuoteValue(label: '시가', value: quote.open),
        _QuoteValue(label: '고가', value: quote.high),
        _QuoteValue(label: '저가', value: quote.low),
      ],
    ),
  );
}

class _QuoteValue extends StatelessWidget {
  const _QuoteValue({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF979DA6),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _money(value.round()),
          style: const TextStyle(
            color: _marketInk,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFeatures: _marketNumberFeatures,
          ),
        ),
      ],
    ),
  );
}

class _MinuteChartPanel extends StatefulWidget {
  const _MinuteChartPanel({
    required this.quote,
    required this.code,
    required this.market,
    required this.minute,
    required this.asset,
    required this.simulationSeed,
    required this.throughDate,
  });

  final _LiveStock quote;
  final String code;
  final String market;
  final int minute;
  final FictionalMarketAsset asset;
  final String simulationSeed;
  final DateTime throughDate;

  @override
  State<_MinuteChartPanel> createState() => _MinuteChartPanelState();
}

class _MinuteChartPanelState extends State<_MinuteChartPanel> {
  static const intervals = <int>[1, 3, 5, 10, 15, 30, 60, 120, 240];
  int interval = 1;

  static const minuteWindows = <int, int>{
    1: 90,
    3: 240,
    5: 360,
    10: 480,
    15: 600,
    30: 720,
    60: 1440,
    120: 2880,
    240: 5760,
  };
  _ChartPeriod period = _ChartPeriod.minute;

  ({List<double> prices, int startMinute, int previousSessionPointCount})
  _visibleMinuteSeries() {
    final sessionHistory = widget.quote.sessionHistory;
    if (!widget.quote.isTradingDay ||
        widget.minute < krxOpenMinute ||
        sessionHistory.length <= generatedPreOpenTicks) {
      return (
        prices: <double>[sessionHistory.last],
        startMinute: 0,
        previousSessionPointCount: 0,
      );
    }
    final continuousEnd =
        generatedPreOpenTicks + generatedContinuousTradingTicks;
    final visibleEnd = math.min(sessionHistory.length, continuousEnd);
    final prices = sessionHistory.sublist(generatedPreOpenTicks, visibleEnd);
    if (widget.minute >= krxCloseMinute &&
        sessionHistory.length > generatedRegularSessionTicks) {
      prices.add(sessionHistory[generatedRegularSessionTicks]);
    }
    return (prices: prices, startMinute: 0, previousSessionPointCount: 0);
  }

  List<MarketDatedCandle> _dailyCandles() => recentMarketDailyCandles(
    asset: widget.asset,
    simulationSeed: widget.simulationSeed,
    throughDate: widget.throughDate,
    visibleThroughMinute: widget.minute,
    count: switch (period) {
      _ChartPeriod.day => 120,
      _ChartPeriod.week => 280,
      _ChartPeriod.month => 1380,
      _ChartPeriod.year => 3100,
      _ChartPeriod.minute => 0,
    },
  );

  List<MarketCandle> _currentMinuteCandles({
    required List<double> prices,
    required int candleSeed,
    required int fullDayVolume,
    required double lowerPriceLimit,
    required double upperPriceLimit,
  }) {
    if (prices.length <= 1) return const <MarketCandle>[];
    final includesClosingAuction =
        widget.minute >= krxCloseMinute &&
        prices.length > generatedContinuousTradingTicks;
    final continuousPrices = includesClosingAuction
        ? prices.sublist(0, prices.length - 1)
        : prices;
    final continuousVolumes = gameContinuousMinuteVolumes(
      fullDayVolume: fullDayVolume,
      visibleThroughMinute: widget.minute,
    );
    final candles = <MarketCandle>[
      if (continuousPrices.length > 1)
        ...aggregateMarketCandles(
          continuousPrices,
          interval,
          tickMinutes: marketTickMinutes,
          seed: candleSeed,
          lowerPriceLimit: lowerPriceLimit,
          upperPriceLimit: upperPriceLimit,
          minuteVolumes: continuousVolumes,
          market: widget.market,
        ),
    ];
    if (includesClosingAuction) {
      final auctionOpen = continuousPrices.last;
      final auctionClose = prices.last;
      candles.add(
        MarketCandle(
          open: auctionOpen,
          high: math.max(auctionOpen, auctionClose),
          low: math.min(auctionOpen, auctionClose),
          close: auctionClose,
          startMinute: krxCloseMinute - krxOpenMinute,
          volume: gameClosingAuctionVolume(
            fullDayVolume: fullDayVolume,
          ).toDouble(),
        ),
      );
    }
    return candles;
  }

  List<MarketDatedCandle> _periodCandles() {
    if (period == _ChartPeriod.minute) {
      return const <MarketDatedCandle>[];
    }
    final bucket = switch (period) {
      _ChartPeriod.day => MarketCandlePeriod.day,
      _ChartPeriod.week => MarketCandlePeriod.week,
      _ChartPeriod.month => MarketCandlePeriod.month,
      _ChartPeriod.year => MarketCandlePeriod.year,
      _ChartPeriod.minute => MarketCandlePeriod.day,
    };
    final limit = switch (period) {
      _ChartPeriod.day => 120,
      _ChartPeriod.week => 52,
      _ChartPeriod.month => 60,
      _ChartPeriod.year => 12,
      _ChartPeriod.minute => 0,
    };
    return aggregateMarketDatedCandles(
      _dailyCandles(),
      period: bucket,
      maxBuckets: limit,
    );
  }

  List<String> _minuteAxisLabels(List<MarketCandle> visibleCandles) {
    String labelForOffset(int offset) {
      if (offset >= 0) {
        return '오늘 ${marketTimeLabel((krxOpenMinute + offset).clamp(krxOpenMinute, krxCloseMinute))}';
      }
      final fullPointIndex = generatedContinuousTradingTicks + 1 + offset;
      final minute = fullPointIndex >= generatedContinuousTradingTicks
          ? krxCloseMinute
          : krxOpenMinute +
                fullPointIndex.clamp(0, generatedContinuousTradingTicks - 1);
      return '전일 ${marketTimeLabel(minute)}';
    }

    if (visibleCandles.isEmpty) {
      return <String>['', '', marketTimeLabel(widget.minute)];
    }
    if (widget.minute < krxOpenMinute) {
      return <String>[
        labelForOffset(visibleCandles.first.startMinute),
        labelForOffset(visibleCandles[visibleCandles.length ~/ 2].startMinute),
        '개장 전 ${marketTimeLabel(widget.minute)}',
      ];
    }

    return <String>[
      labelForOffset(visibleCandles.first.startMinute),
      labelForOffset(visibleCandles[visibleCandles.length ~/ 2].startMinute),
      visibleCandles.last.startMinute >= 0
          ? labelForOffset(visibleCandles.last.startMinute)
          : '오늘 ${marketTimeLabel(krxOpenMinute)}',
    ];
  }

  List<String> _dailyAxisLabels(List<MarketDatedCandle> candles) {
    final formatted = candles
        .map((item) => _formatDailyAxisLabel(item.date))
        .toList(growable: false);
    return _axisTriplet(formatted);
  }

  String _formatDailyAxisLabel(String key) {
    final date = DateTime.tryParse(key);
    if (date == null) return key;
    return switch (period) {
      _ChartPeriod.day || _ChartPeriod.week =>
        '${date.month.toString().padLeft(2, '0')}.'
            '${date.day.toString().padLeft(2, '0')}',
      _ChartPeriod.month =>
        '${date.year}.${date.month.toString().padLeft(2, '0')}',
      _ChartPeriod.year => '${date.year}',
      _ChartPeriod.minute => key,
    };
  }

  List<String> _axisTriplet(List<String> values) {
    if (values.isEmpty) return const <String>['', '', ''];
    return <String>[values.first, values[values.length ~/ 2], values.last];
  }

  String _windowLabel({
    required int candleCount,
    required int dailyCount,
    required bool hasPreviousSession,
  }) {
    if (period != _ChartPeriod.minute) {
      return switch (period) {
        _ChartPeriod.day => '일봉 · 최근 $dailyCount거래일 · 5·20·60·120일 이동평균',
        _ChartPeriod.week => '주봉 · 최근 $dailyCount주',
        _ChartPeriod.month => '월봉 · 최근 $dailyCount개월',
        _ChartPeriod.year => '년봉 · 최근 $dailyCount년',
        _ChartPeriod.minute => '',
      };
    }
    final window = minuteWindows[interval] ?? 60;
    final windowText = switch (window) {
      60 => '최대 최근 1시간',
      90 => '최대 최근 90분',
      180 => '최대 최근 3시간',
      240 => '최대 최근 4시간',
      360 => '최대 최근 6시간',
      480 => '최대 최근 8시간',
      600 => '최대 최근 10시간',
      720 => '최대 최근 12시간',
      1440 => '최대 최근 24시간',
      2880 => '최대 최근 48시간',
      5760 => '최대 최근 96시간',
      _ => '최근 $window분',
    };
    final previousSessionLabel = hasPreviousSession ? ' · 전 거래일 포함' : '';
    return '$interval분봉 · $windowText · $candleCount개 캔들'
        '$previousSessionLabel';
  }

  @override
  Widget build(BuildContext context) {
    final displayMinutes = minuteWindows[interval] ?? 60;
    final displayCandleCount = math.max(1, displayMinutes ~/ interval);
    var minuteSeries = _visibleMinuteSeries();
    final candleSeed = widget.quote.history.isEmpty
        ? widget.code.codeUnits.fold<int>(17, (sum, unit) => sum * 31 + unit)
        : marketStockSeed(
            '${widget.simulationSeed}:${widget.asset.code}',
            widget.throughDate,
          );
    MarketPreviousSessionSeries? previousSessionSeries;
    if (period == _ChartPeriod.minute && minuteSeries.startMinute == 0) {
      final targetPoints = displayMinutes + 1;
      final missingPoints = math.min(
        math.max(0, targetPoints + 1 - minuteSeries.prices.length),
        generatedRegularTradingTicks,
      );
      if (missingPoints > 0) {
        previousSessionSeries = marketPreviousSessionSeriesForAsset(
          asset: widget.asset,
          simulationSeed: widget.simulationSeed,
          currentDate: widget.throughDate,
        );
        final previousSession = previousSessionSeries?.prices;
        if (previousSession != null && previousSession.isNotEmpty) {
          minuteSeries = (
            prices: <double>[...previousSession, ...minuteSeries.prices],
            startMinute: -previousSession.length,
            previousSessionPointCount: previousSession.length,
          );
        }
      }
    }
    final minutePrices = minuteSeries.prices;
    final candlePriceRange = marketDailyPriceRange(
      previousClose: widget.quote.previousClose,
      date: widget.throughDate,
      market: widget.market,
      isIpoFirstTradingDay: widget.asset.isIpoFirstTradingDay(
        widget.throughDate,
      ),
    );
    final currentFullDayVolume = widget.quote.isTradingDay
        ? gameEstimatedFullDayVolumeUnits(
            assetId: widget.asset.id,
            day: marketLiquidityDayKey(widget.throughDate),
            referencePrice: widget.quote.previousClose,
            simulationSeed: widget.simulationSeed,
            sharesOutstanding: widget.asset.sharesOutstandingAtOrBefore(
              widget.throughDate,
            ),
          )
        : 0;
    final candles = period == _ChartPeriod.minute
        ? <MarketCandle>[
            if (minuteSeries.previousSessionPointCount > 1)
              ...aggregateMarketCandles(
                minutePrices.sublist(0, minuteSeries.previousSessionPointCount),
                interval,
                tickMinutes: marketTickMinutes,
                seed: previousSessionSeries == null
                    ? null
                    : marketStockSeed(
                        '${widget.simulationSeed}:${widget.asset.code}',
                        previousSessionSeries.date,
                      ),
                startMinuteOffset: -minuteSeries.previousSessionPointCount,
                totalVolume: previousSessionSeries == null
                    ? null
                    : gameEstimatedFullDayVolumeUnits(
                        assetId: widget.asset.id,
                        day: marketLiquidityDayKey(previousSessionSeries.date),
                        referencePrice: previousSessionSeries.referenceClose,
                        simulationSeed: widget.simulationSeed,
                        sharesOutstanding: widget.asset
                            .sharesOutstandingAtOrBefore(
                              previousSessionSeries.date,
                            ),
                      ).toDouble(),
                market: widget.market,
              ),
            if (minutePrices.length - minuteSeries.previousSessionPointCount >
                1)
              ..._currentMinuteCandles(
                prices: minutePrices.sublist(
                  minuteSeries.previousSessionPointCount,
                ),
                candleSeed: candleSeed,
                fullDayVolume: currentFullDayVolume,
                lowerPriceLimit: candlePriceRange.lower,
                upperPriceLimit: candlePriceRange.upper,
              ),
          ]
        : const <MarketCandle>[];
    final datedDailyCandles = _periodCandles();
    final dailyCandles = datedDailyCandles
        .map((item) => item.candle)
        .toList(growable: false);
    final dailyCloses = period == _ChartPeriod.minute
        ? const <double>[]
        : dailyCandles.map((candle) => candle.close).toList(growable: false);
    final visibleCandleCount = math.min(candles.length, displayCandleCount);
    final visibleCandles = candles.isEmpty
        ? const <MarketCandle>[]
        : candles.sublist(candles.length - visibleCandleCount);
    final axisLabels = period == _ChartPeriod.minute
        ? _minuteAxisLabels(visibleCandles)
        : _dailyAxisLabels(datedDailyCandles);
    return Column(
      children: [
        SizedBox(
          height: 268,
          child: CustomPaint(
            key: Key(switch (period) {
              _ChartPeriod.minute => 'minute-candle-chart',
              _ChartPeriod.day => 'daily-candle-chart',
              _ChartPeriod.week => 'weekly-candle-chart',
              _ChartPeriod.month => 'monthly-candle-chart',
              _ChartPeriod.year => 'yearly-candle-chart',
            }),
            painter: period == _ChartPeriod.minute
                ? _CandleChartPainter(
                    candles: candles,
                    maxVisibleCandles: displayCandleCount,
                  )
                : _CandleChartPainter(
                    candles: dailyCandles,
                    maxVisibleCandles: switch (period) {
                      _ChartPeriod.day => 120,
                      _ChartPeriod.week => 52,
                      _ChartPeriod.month => 60,
                      _ChartPeriod.year => 12,
                      _ChartPeriod.minute => 0,
                    },
                    showMovingAverages: period == _ChartPeriod.day,
                  ),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 3),
        _ChartAxisLabels(key: const Key('chart-time-axis'), labels: axisLabels),
        const SizedBox(height: 8),
        Row(
          children: [
            PopupMenuButton<int>(
              key: const Key('minute-interval-selector'),
              initialValue: interval,
              tooltip: '분봉 선택',
              onSelected: (value) => setState(() {
                interval = value;
                period = _ChartPeriod.minute;
              }),
              itemBuilder: (_) => intervals
                  .map(
                    (value) => PopupMenuItem<int>(
                      value: value,
                      child: Text('$value분'),
                    ),
                  )
                  .toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$interval분',
                      style: const TextStyle(
                        color: Color(0xFF202632),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  ],
                ),
              ),
            ),
            const Spacer(),
            _RangeChip(
              key: const Key('chart-range-day'),
              label: '일',
              selected: period == _ChartPeriod.day,
              onTap: () => setState(() => period = _ChartPeriod.day),
            ),
            _RangeChip(
              key: const Key('chart-range-week'),
              label: '주',
              selected: period == _ChartPeriod.week,
              onTap: () => setState(() => period = _ChartPeriod.week),
            ),
            _RangeChip(
              key: const Key('chart-range-month'),
              label: '월',
              selected: period == _ChartPeriod.month,
              onTap: () => setState(() => period = _ChartPeriod.month),
            ),
            _RangeChip(
              key: const Key('chart-range-year'),
              label: '년',
              selected: period == _ChartPeriod.year,
              onTap: () => setState(() => period = _ChartPeriod.year),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _windowLabel(
              candleCount: visibleCandleCount,
              dailyCount: dailyCloses.length,
              hasPreviousSession: minuteSeries.startMinute < 0,
            ),
            key: const Key('chart-window-label'),
            style: const TextStyle(
              color: Color(0xFF979EA8),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartAxisLabels extends StatelessWidget {
  const _ChartAxisLabels({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final safeLabels = labels.length >= 3 ? labels : const <String>['', '', ''];
    return Semantics(
      label: '차트 시간축 ${safeLabels.join(', ')}',
      child: Row(
        children: [
          _ChartAxisText(label: safeLabels[0], alignment: Alignment.centerLeft),
          _ChartAxisText(label: safeLabels[1], alignment: Alignment.center),
          _ChartAxisText(
            label: safeLabels[2],
            alignment: Alignment.centerRight,
          ),
        ],
      ),
    );
  }
}

class _ChartAxisText extends StatelessWidget {
  const _ChartAxisText({required this.label, required this.alignment});

  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Align(
      alignment: alignment,
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: Color(0xFF9AA1AC),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _CandleChartPainter extends CustomPainter {
  const _CandleChartPainter({
    required this.candles,
    required this.maxVisibleCandles,
    this.showMovingAverages = false,
  });

  final List<MarketCandle> candles;
  final int maxVisibleCandles;
  final bool showMovingAverages;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty || size.isEmpty) return;
    const axisWidth = 48.0;
    const priceTop = 8.0;
    final chartRight = math.max(1.0, size.width - axisWidth);
    final volumeTop = size.height * 0.79;
    final volumeBottom = size.height - 4;
    final priceBottom = volumeTop - 16;
    final priceHeight = math.max(1.0, priceBottom - priceTop);
    final visibleStartIndex = math.max(0, candles.length - maxVisibleCandles);
    final visible = candles.sublist(visibleStartIndex);
    final values = visible
        .expand((candle) => <double>[candle.high, candle.low])
        .toList(growable: false);
    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);
    if (minValue == maxValue) {
      minValue *= 0.995;
      maxValue *= 1.005;
    }
    final padding = (maxValue - minValue) * 0.07;
    minValue -= padding;
    maxValue += padding;
    final range = maxValue - minValue;
    double yFor(double value) =>
        priceBottom - ((value - minValue) / range * priceHeight);

    void drawText(
      String text,
      Offset offset, {
      Color color = const Color(0xFF8A919E),
      double fontSize = 8,
      FontWeight fontWeight = FontWeight.w700,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: axisWidth);
      painter.paint(canvas, offset);
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFEFF1F4)
      ..strokeWidth = 1;
    for (var line = 0; line <= 4; line++) {
      final y = priceTop + priceHeight * line / 4;
      canvas.drawLine(Offset(0, y), Offset(chartRight, y), gridPaint);
      final value = maxValue - range * line / 4;
      drawText(
        _money(value.round()),
        Offset(chartRight + 5, y - 5),
        fontSize: 8,
      );
    }
    final slot = chartRight / math.max(visible.length, 1);
    final bodyWidth = math.max(2.0, math.min(6.0, slot * 0.72));
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, priceTop, chartRight, priceBottom));
    for (var index = 0; index < visible.length; index++) {
      final candle = visible[index];
      final x = slot * index + slot / 2;
      final rising = candle.close >= candle.open;
      final color = rising ? const Color(0xFFF04452) : _marketAccent;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x, yFor(candle.high)),
        Offset(x, yFor(candle.low)),
        paint,
      );
      final openY = yFor(candle.open);
      final closeY = yFor(candle.close);
      final top = math.min(openY, closeY);
      final height = math.max(1.5, (openY - closeY).abs());
      canvas.drawRect(
        Rect.fromLTWH(x - bodyWidth / 2, top, bodyWidth, height),
        paint,
      );
    }

    canvas.restore();

    if (showMovingAverages) {
      const averagePeriods = <int>[5, 20, 60, 120];
      const averageColors = <Color>[
        Color(0xFFFF8A00),
        Color(0xFF8B5CF6),
        Color(0xFF16A085),
        Color(0xFF667085),
      ];
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, priceTop, chartRight, priceBottom));
      for (
        var averageIndex = 0;
        averageIndex < averagePeriods.length;
        averageIndex += 1
      ) {
        final averagePeriod = averagePeriods[averageIndex];
        final path = Path();
        var hasPoint = false;
        for (var localIndex = 0; localIndex < visible.length; localIndex += 1) {
          final globalIndex = visibleStartIndex + localIndex;
          if (globalIndex + 1 < averagePeriod) continue;
          var sum = 0.0;
          for (
            var cursor = globalIndex - averagePeriod + 1;
            cursor <= globalIndex;
            cursor += 1
          ) {
            sum += candles[cursor].close;
          }
          final average = sum / averagePeriod;
          final x = slot * localIndex + slot / 2;
          final y = yFor(average);
          if (!hasPoint) {
            path.moveTo(x, y);
            hasPoint = true;
          } else {
            path.lineTo(x, y);
          }
        }
        if (hasPoint) {
          canvas.drawPath(
            path,
            Paint()
              ..color = averageColors[averageIndex]
              ..strokeWidth = 1.15
              ..style = PaintingStyle.stroke,
          );
        }
      }
      canvas.restore();
      for (
        var averageIndex = 0;
        averageIndex < averagePeriods.length;
        averageIndex += 1
      ) {
        drawText(
          'MA${averagePeriods[averageIndex]}',
          Offset(3 + averageIndex * 34, 0),
          color: averageColors[averageIndex],
          fontSize: 7,
          fontWeight: FontWeight.w800,
        );
      }
    }

    final current = visible.last.close;
    final currentY = yFor(current).clamp(priceTop, priceBottom);
    final currentPaint = Paint()
      ..color = _marketAccent
      ..strokeWidth = 1;
    for (var x = 0.0; x < chartRight; x += 5) {
      canvas.drawLine(
        Offset(x, currentY),
        Offset(math.min(x + 2, chartRight), currentY),
        currentPaint,
      );
    }
    final priceLabelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(chartRight, currentY - 9, axisWidth, 18),
      const Radius.circular(3),
    );
    canvas.drawRRect(priceLabelRect, Paint()..color = _marketAccent);
    drawText(
      _money(current.round()),
      Offset(chartRight + 4, currentY - 5.5),
      color: Colors.white,
      fontSize: 8,
      fontWeight: FontWeight.w700,
    );

    final volumeDividerY = volumeTop - 8;
    canvas.drawLine(
      Offset(0, volumeDividerY),
      Offset(size.width, volumeDividerY),
      Paint()
        ..color = const Color(0xFFD8DDE4)
        ..strokeWidth = 1,
    );
    drawText('거래량', Offset(2, volumeTop - 5), fontSize: 8);
    final maxVolume = visible
        .map((candle) => candle.volume)
        .fold<double>(1, math.max);
    final volumeChartTop = volumeTop + 9;
    final volumeHeight = math.max(1.0, volumeBottom - volumeChartTop);
    for (var index = 0; index < visible.length; index++) {
      final candle = visible[index];
      final x = slot * index + slot / 2;
      final barHeight = candle.volume <= 0
          ? 0.8
          : math.max(1.0, candle.volume / maxVolume * volumeHeight);
      final rising = candle.close >= candle.open;
      canvas.drawRect(
        Rect.fromLTWH(
          x - bodyWidth / 2,
          volumeBottom - barHeight,
          bodyWidth,
          barHeight,
        ),
        Paint()
          ..color = rising ? const Color(0xCCF04452) : const Color(0xCC3182F6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CandleChartPainter oldDelegate) =>
      oldDelegate.candles != candles ||
      oldDelegate.maxVisibleCandles != maxVisibleCandles ||
      oldDelegate.showMovingAverages != showMovingAverages;
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 40, minHeight: 42),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF2FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _marketAccent : const Color(0xFF9399A3),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: const BoxDecoration(
      color: Color(0xFF36B37E),
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: Color(0x6636B37E), blurRadius: 5)],
    ),
  );
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.isEmpty) return;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue == minValue ? 1.0 : maxValue - minValue;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y =
          size.height - ((values[index] - minValue) / range * size.height);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _StockDefinition {
  const _StockDefinition({
    required this.asset,
    required this.id,
    required this.code,
    required this.name,
    required this.market,
    required this.country,
    required this.currency,
    required this.sector,
    required this.summary,
    required this.question,
    required this.products,
    required this.listedOn,
    required this.accent,
    required this.generation,
    required this.financials,
    required this.relations,
  });

  factory _StockDefinition.fromAsset(FictionalMarketAsset asset) =>
      _StockDefinition(
        asset: asset,
        id: asset.id,
        code: asset.code,
        name: asset.name,
        market: asset.market,
        country: asset.country,
        currency: asset.currency,
        sector: asset.sector,
        summary: asset.summary.isEmpty
            ? '${asset.name}의 ${asset.sector} 사업과 가상 시장 흐름을 함께 보는 종목입니다.'
            : asset.summary,
        question: asset.question.isEmpty
            ? '${asset.sector} 시장이 바뀌어도 이 회사의 경쟁력은 유지될까?'
            : asset.question,
        products: asset.products,
        listedOn: asset.listedOn ?? asset.firstTradeDate,
        accent: _hexColor(asset.colorHex),
        generation: asset.generation,
        financials: asset.financials,
        relations: asset.relations,
      );

  final FictionalMarketAsset asset;
  final String id;
  final String code;
  final String name;
  final String market;
  final String country;
  final String currency;
  final String sector;
  final String summary;
  final String question;
  final List<String> products;
  final String? listedOn;
  final Color accent;
  final int generation;
  final List<FictionalFinancialSnapshot> financials;
  final List<FictionalCompanyRelation> relations;

  FictionalFinancialSnapshot? financialAt(DateTime date) {
    final key = marketDateKey(date);
    FictionalFinancialSnapshot? result;
    for (final snapshot in financials) {
      if (snapshot.period.compareTo(key) > 0) break;
      result = snapshot;
    }
    return result;
  }
}

class _LiveStock {
  const _LiveStock({
    required this.price,
    required this.previousClose,
    required this.officialClose,
    required this.isTradingDay,
    required this.open,
    required this.high,
    required this.low,
    required this.history,
    required this.sessionHistory,
    required this.sessionPath,
  });

  final double price;
  final double previousClose;
  final double officialClose;
  final bool isTradingDay;
  final double open;
  final double high;
  final double low;
  final List<MarketPoint> history;
  final List<double> sessionHistory;
  final List<double> sessionPath;

  _LiveStock copyWith({
    double? price,
    double? open,
    double? high,
    double? low,
    List<MarketPoint>? history,
    List<double>? sessionHistory,
    List<double>? sessionPath,
  }) => _LiveStock(
    price: price ?? this.price,
    previousClose: previousClose,
    officialClose: officialClose,
    isTradingDay: isTradingDay,
    open: open ?? this.open,
    high: high ?? this.high,
    low: low ?? this.low,
    history: history ?? this.history,
    sessionHistory: sessionHistory ?? this.sessionHistory,
    sessionPath: sessionPath ?? this.sessionPath,
  );
}

double _changeRate(_LiveStock quote) => quote.previousClose <= 0
    ? 0
    : (quote.price - quote.previousClose) / quote.previousClose * 100;

String _compactShareCount(int value) {
  final amount = math.max(0, value);
  if (amount >= 100000000) {
    return '${(amount / 100000000).toStringAsFixed(1)}억주';
  }
  if (amount >= 10000) {
    return '${(amount / 10000).toStringAsFixed(1)}만주';
  }
  return '${_money(amount)}주';
}

String _compactEok(double value) => value >= 1000
    ? '${(value / 1000).toStringAsFixed(1)}천억원'
    : '${value.round()}억원';

String _compactWonAmount(int value) {
  final sign = value < 0 ? '-' : '';
  final amount = value.abs();
  if (amount >= 1000000000000) {
    return '$sign${(amount / 1000000000000).toStringAsFixed(1)}조원';
  }
  if (amount >= 100000000) {
    return '$sign${(amount / 100000000).toStringAsFixed(1)}억원';
  }
  if (amount >= 10000) {
    return '$sign${(amount / 10000).toStringAsFixed(0)}만원';
  }
  return '$sign${_money(amount)}원';
}

String _signedShares(int value) {
  if (value == 0) return '0';
  return '${value > 0 ? '+' : '-'}${_money(value.abs())}';
}

String _investorFlowText(
  int shares, {
  required double closePrice,
  required _InvestorFlowUnit unit,
}) {
  if (unit == _InvestorFlowUnit.shares) return _signedShares(shares);
  if (!closePrice.isFinite || closePrice <= 0 || shares == 0) return '0원';
  final amount = (shares * closePrice).round();
  if (amount == 0) return '0원';
  return '${amount > 0 ? '+' : '-'}${_compactWonAmount(amount.abs())}';
}

Color _investorFlowColor(int value) {
  if (value > 0) return const Color(0xFFE02D70);
  if (value < 0) return const Color(0xFF2563D9);
  return _marketMuted;
}

String _shortInvestorDate(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

String _companyListingDate(String? value) {
  if (value == null || value.isEmpty) return '-';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return '${parsed.year}.${parsed.month.toString().padLeft(2, '0')}.'
      '${parsed.day.toString().padLeft(2, '0')}';
}

Color _hexColor(String value) {
  final normalized = value.replaceFirst('#', '');
  final parsed = int.tryParse(normalized, radix: 16) ?? 0x607D8B;
  return Color(0xFF000000 | parsed);
}

String _displayPrice(double value, String currency) {
  final amount = _money(value.round());
  return switch (currency) {
    'USD' => '\$$amount',
    'JPY' => '¥$amount',
    _ => '$amount원',
  };
}

String _signedDisplayPrice(double value, String currency) {
  final rounded = value.round();
  if (rounded == 0) return _displayPrice(0, currency);
  return '${rounded > 0 ? '+' : '-'}'
      '${_displayPrice(rounded.abs().toDouble(), currency)}';
}

String _signedPercent(double value, {int fractionDigits = 2}) {
  final magnitude = value.abs().toStringAsFixed(fractionDigits);
  final roundsToZero = double.tryParse(magnitude) == 0;
  final sign = roundsToZero ? '' : (value > 0 ? '+' : '-');
  return '$sign$magnitude%';
}

String _ownershipPercent(double ownedShares, int sharesOutstanding) {
  if (ownedShares <= 0 || sharesOutstanding <= 0) return '0%';
  final percent = ownedShares / sharesOutstanding * 100;
  if (percent < 0.0001) return '<0.0001%';
  if (percent < 0.01) return '${percent.toStringAsFixed(4)}%';
  if (percent < 1) return '${percent.toStringAsFixed(3)}%';
  return '${percent.toStringAsFixed(2)}%';
}

String _displayUnits(double units) => units == units.roundToDouble()
    ? units.toInt().toString()
    : units.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '');

Color _priceColor(double change) {
  if (change > 0) return const Color(0xFFF04452);
  if (change < 0) return _marketAccent;
  return _marketInk;
}
