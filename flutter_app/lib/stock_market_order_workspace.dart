part of 'main.dart';

class _InlineOrderWorkspace extends StatelessWidget {
  const _InlineOrderWorkspace({
    required this.definition,
    required this.state,
    required this.live,
    required this.minute,
    required this.playbackSpeed,
    required this.liquidityPulseListenable,
    required this.marketSnapshotReader,
    required this.sweepPacketsReader,
    required this.onSweepPacketsAccepted,
    required this.playerTrade,
    required this.availableHeight,
    required this.section,
    required this.formRevision,
    required this.initialLimitPrice,
    required this.selectedLimitPrice,
    required this.initialQuantity,
    required this.onExecuteTrade,
    required this.onSelectBuy,
    required this.onSelectSell,
    required this.onSelectSection,
    required this.onSelectPrice,
    required this.onSelectedLimitPriceChanged,
    required this.onCancelPendingOrder,
    required this.onAmendPendingOrder,
    required this.onSuccessContinue,
    required this.onUnavailable,
  });

  final _StockDefinition definition;
  final GameState state;
  final ValueNotifier<_LiveStock> live;
  final ValueNotifier<int> minute;
  final ValueListenable<_MarketPlaybackSpeed> playbackSpeed;
  final ValueListenable<int> liquidityPulseListenable;
  final ValueGetter<GameOrderBookSnapshot> marketSnapshotReader;
  final ValueGetter<List<_OrderBookSweepReplayPacket>> sweepPacketsReader;
  final ValueChanged<Iterable<String>> onSweepPacketsAccepted;
  final _PlayerTradeSignal? playerTrade;
  final double availableHeight;
  final _DetailedOrderSection section;
  final int formRevision;
  final double initialLimitPrice;
  final double? selectedLimitPrice;
  final double? initialQuantity;
  final Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade;
  final VoidCallback onSelectBuy;
  final VoidCallback onSelectSell;
  final ValueChanged<_DetailedOrderSection> onSelectSection;
  final ValueChanged<double> onSelectPrice;
  final ValueChanged<double?> onSelectedLimitPriceChanged;
  final Future<void> Function(String orderId)? onCancelPendingOrder;
  final Future<void> Function(PendingTradeOrder order) onAmendPendingOrder;
  final VoidCallback onSuccessContinue;
  final VoidCallback onUnavailable;

  @override
  Widget build(BuildContext context) {
    final canTrade = definition.currency == 'KRW';
    final isBuy = section != _DetailedOrderSection.sell;
    final railWidth = (MediaQuery.sizeOf(context).width * 0.39)
        .clamp(138.0, 156.0)
        .toDouble();
    final isOrderForm =
        section == _DetailedOrderSection.buy ||
        section == _DetailedOrderSection.sell;
    return SizedBox(
      key: const Key('inline-order-workspace'),
      height: availableHeight,
      child: Column(
        children: [
          Container(
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFAFBFC),
              border: Border(
                top: BorderSide(color: Color(0xFFE5E8ED)),
                bottom: BorderSide(color: Color(0xFFDDE1E8)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _InlineOrderTab(
                    key: const Key('buy-stock-button'),
                    label: '매수',
                    selected: section == _DetailedOrderSection.buy,
                    color: const Color(0xFFF04452),
                    onTap: canTrade ? onSelectBuy : onUnavailable,
                  ),
                ),
                Expanded(
                  child: _InlineOrderTab(
                    key: const Key('sell-stock-button'),
                    label: '매도',
                    selected: section == _DetailedOrderSection.sell,
                    color: _marketAccent,
                    onTap: canTrade ? onSelectSell : onUnavailable,
                  ),
                ),
                Expanded(
                  child: _InlineOrderTab(
                    key: const Key('inline-amend-cancel-tab'),
                    label: '정정/취소',
                    selected: section == _DetailedOrderSection.amendCancel,
                    onTap: () =>
                        onSelectSection(_DetailedOrderSection.amendCancel),
                  ),
                ),
                Expanded(
                  child: _InlineOrderTab(
                    key: const Key('inline-open-orders-tab'),
                    label: '미체결',
                    selected: section == _DetailedOrderSection.openOrders,
                    onTap: () =>
                        onSelectSection(_DetailedOrderSection.openOrders),
                  ),
                ),
                Expanded(
                  child: _InlineOrderTab(
                    key: const Key('inline-balance-tab'),
                    label: '잔고',
                    selected: section == _DetailedOrderSection.balance,
                    onTap: () => onSelectSection(_DetailedOrderSection.balance),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _InlineOrderSlidingBody(
              railWidth: railWidth,
              orderPanel: isOrderForm
                  ? _OrderSheet(
                      key: ValueKey(
                        'inline-order-${isBuy ? 'buy' : 'sell'}-$formRevision',
                      ),
                      definition: definition,
                      live: live,
                      isBuy: isBuy,
                      state: state,
                      minute: minute,
                      liquidityPulseListenable: liquidityPulseListenable,
                      marketSnapshotReader: marketSnapshotReader,
                      onExecuteTrade: onExecuteTrade,
                      initialOrderType: TradeOrderType.limit,
                      initialLimitPrice: initialLimitPrice,
                      initialQuantity: initialQuantity,
                      submitLabel: isBuy ? '매수 주문' : '매도 주문',
                      successLabel: '다음 주문',
                      onSuccessContinue: onSuccessContinue,
                      onSelectedLimitPriceChanged: onSelectedLimitPriceChanged,
                      compact: true,
                    )
                  : section == _DetailedOrderSection.balance
                  ? _InlineOrderBalancePanel(
                      definition: definition,
                      state: state,
                    )
                  : _InlinePendingOrdersPanel(
                      definition: definition,
                      state: state,
                      correctionMode:
                          section == _DetailedOrderSection.amendCancel,
                      onCancel: onCancelPendingOrder,
                      onAmend: onAmendPendingOrder,
                    ),
              orderBookRail: ValueListenableBuilder<int>(
                valueListenable: liquidityPulseListenable,
                builder: (context, _, _) {
                  final snapshot = marketSnapshotReader();
                  return _CompactOrderBookRail(
                    definition: definition,
                    quote: live.value,
                    state: state,
                    minute: minute.value,
                    playbackSpeed: playbackSpeed,
                    snapshot: snapshot,
                    sweepPackets: sweepPacketsReader(),
                    onSweepPacketsAccepted: onSweepPacketsAccepted,
                    playerTrade: playerTrade,
                    selectedPrice: isOrderForm ? selectedLimitPrice : null,
                    onSelectPrice: onSelectPrice,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineOrderSlidingBody extends StatefulWidget {
  const _InlineOrderSlidingBody({
    required this.railWidth,
    required this.orderPanel,
    required this.orderBookRail,
  });

  final double railWidth;
  final Widget orderPanel;
  final Widget orderBookRail;

  @override
  State<_InlineOrderSlidingBody> createState() =>
      _InlineOrderSlidingBodyState();
}

class _InlineOrderSlidingBodyState extends State<_InlineOrderSlidingBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _inlineOrderSlideDuration,
      vsync: this,
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final workspaceWidth = constraints.maxWidth;
      final railWidth = math.min(widget.railWidth, workspaceWidth).toDouble();
      final panelWidth = math
          .max(0.0, workspaceWidth - railWidth - 1)
          .toDouble();
      return AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          final progress = _progress.value;
          final visiblePanelWidth = panelWidth * progress;
          return Row(
            key: const Key('inline-order-slide-transition'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: visiblePanelWidth,
                child: ClipRect(
                  child: OverflowBox(
                    minWidth: panelWidth,
                    maxWidth: panelWidth,
                    alignment: Alignment.centerRight,
                    child: widget.orderPanel,
                  ),
                ),
              ),
              SizedBox(
                width: progress,
                child: const ColoredBox(color: Color(0x1F000000)),
              ),
              Expanded(child: widget.orderBookRail),
            ],
          );
        },
      );
    },
  );
}

class _InlineOrderTab extends StatelessWidget {
  const _InlineOrderTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = const Color(0xFF353B78),
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: selected ? color : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: selected ? color : const Color(0xFF777F8C),
            fontSize: label.length > 3 ? 9 : 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );
}

class _InlinePendingOrdersPanel extends StatelessWidget {
  const _InlinePendingOrdersPanel({
    required this.definition,
    required this.state,
    required this.correctionMode,
    required this.onCancel,
    required this.onAmend,
  });

  final _StockDefinition definition;
  final GameState state;
  final bool correctionMode;
  final Future<void> Function(String orderId)? onCancel;
  final Future<void> Function(PendingTradeOrder order) onAmend;

  @override
  Widget build(BuildContext context) {
    final orders = state.pendingOrders
        .where((order) => order.assetId == definition.id)
        .toList(growable: false);
    return ListView(
      key: const Key('inline-pending-orders'),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      children: [
        Text(
          correctionMode ? '정정·취소' : '미체결 주문',
          style: const TextStyle(
            color: _marketInk,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          correctionMode ? '가격을 고쳐 다시 내거나 주문을 취소합니다.' : '체결을 기다리는 주문입니다.',
          style: const TextStyle(
            color: _marketMuted,
            fontSize: 10,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (orders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 42),
            child: Text(
              '이 종목의 미체결 주문이 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8A919E),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          for (final order in orders)
            Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                border: Border.all(color: const Color(0xFFE1E5EA)),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        order.side == PendingOrderSide.buy ? '매수' : '매도',
                        style: TextStyle(
                          color: order.side == PendingOrderSide.buy
                              ? const Color(0xFFF04452)
                              : _marketAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_money(order.limitPrice.round())}원',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontFeatures: _marketNumberFeatures,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '미체결 ${_displayUnits(order.remainingQuantity)}주',
                      style: const TextStyle(
                        color: _marketMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (correctionMode) ...[
                        Expanded(
                          child: SizedBox(
                            height: 30,
                            child: OutlinedButton(
                              onPressed: onCancel == null
                                  ? null
                                  : () => unawaited(onAmend(order)),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                '정정',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 30,
                          child: OutlinedButton(
                            onPressed: onCancel == null
                                ? null
                                : () => unawaited(onCancel!(order.id)),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              '취소',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _InlineOrderBalancePanel extends StatelessWidget {
  const _InlineOrderBalancePanel({
    required this.definition,
    required this.state,
  });

  final _StockDefinition definition;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final position = state.positions
        .where((item) => item.assetId == definition.id)
        .firstOrNull;
    final pending = state.pendingOrders
        .where((order) => order.assetId == definition.id)
        .length;
    return ListView(
      key: const Key('inline-order-balance'),
      padding: const EdgeInsets.fromLTRB(9, 10, 9, 12),
      children: [
        const Text(
          '주문 가능 잔고',
          style: TextStyle(
            color: _marketInk,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        _InlineBalanceRow(
          label: '예수금',
          value: '${_money(state.brokerageCash)}원',
        ),
        _InlineBalanceRow(
          label: '주문 가능',
          value: '${_money(state.availableBrokerageCash)}원',
        ),
        _InlineBalanceRow(
          label: '보유',
          value: '${_displayUnits(position?.units ?? 0)}주',
        ),
        _InlineBalanceRow(
          label: '매입 금액',
          value: '${_money(position?.totalCost ?? 0)}원',
        ),
        _InlineBalanceRow(label: '미체결', value: '$pending건'),
      ],
    );
  }
}

class _InlineBalanceRow extends StatelessWidget {
  const _InlineBalanceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE8EAEF))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _marketMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _marketInk,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFeatures: _marketNumberFeatures,
            ),
          ),
        ),
      ],
    ),
  );
}

enum _OrderBookSweepPhase { idle, arriving, draining }

class _OrderBookSweepBatch {
  const _OrderBookSweepBatch({
    required this.snapshot,
    required this.previousSnapshot,
    required this.steps,
    required this.cancellations,
    required this.identity,
    required this.source,
    required this.progress,
  });

  final GameOrderBookSnapshot snapshot;
  final GameOrderBookSnapshot previousSnapshot;
  final List<GameOrderBookSweepStep> steps;
  final List<OrderBookCancellationNotice> cancellations;
  final String identity;
  final String source;
  final _OrderBookSweepReplayProgress progress;
}

class _OrderBookSweepReplayProgress {
  _OrderBookSweepReplayProgress();

  int stepIndex = 0;
  bool arrived = false;
}

class _OrderBookSweepReplayPacket {
  _OrderBookSweepReplayPacket({
    required this.snapshot,
    required this.previousSnapshot,
    required this.steps,
    required this.cancellations,
    required this.source,
    required this.identity,
  }) : progress = _OrderBookSweepReplayProgress();

  final GameOrderBookSnapshot snapshot;
  final GameOrderBookSnapshot previousSnapshot;
  final List<GameOrderBookSweepStep> steps;
  final List<OrderBookCancellationNotice> cancellations;
  final String source;
  final String identity;
  final _OrderBookSweepReplayProgress progress;
}

class _OrderBookSweepJournal {
  _OrderBookSweepJournal(this._sessionKey);

  String _sessionKey;
  final List<_OrderBookSweepReplayPacket> _pendingPackets =
      <_OrderBookSweepReplayPacket>[];
  final OrderBookSweepIdentityLedger _identityLedger =
      OrderBookSweepIdentityLedger(completedHistoryCapacity: 512);

  List<_OrderBookSweepReplayPacket> get pendingPackets =>
      List<_OrderBookSweepReplayPacket>.unmodifiable(_pendingPackets);

  void ensureSession(String sessionKey) {
    if (_sessionKey == sessionKey) return;
    _sessionKey = sessionKey;
    _pendingPackets.clear();
    _identityLedger.clear();
  }

  void enqueue(_OrderBookSweepReplayPacket packet) {
    if (!_identityLedger.admit(packet.identity)) return;
    _pendingPackets.add(packet);
  }

  void accept(Iterable<String> identities) {
    final accepted = identities.toSet();
    if (accepted.isEmpty) return;
    _pendingPackets.removeWhere((packet) {
      if (!accepted.contains(packet.identity)) return false;
      _identityLedger.complete(packet.identity);
      return true;
    });
  }
}

class _OrderBookSweepTapeCursor {
  const _OrderBookSweepTapeCursor({
    required this.snapshot,
    required this.step,
    required this.source,
    required this.identity,
    required this.arrived,
  });

  final GameOrderBookSnapshot snapshot;
  final GameOrderBookSweepStep step;
  final String source;
  final String identity;
  final bool arrived;
}

_OrderBookSweepTapeCursor? _orderBookTapeCursorForLivePackets(
  _OrderBookSweepTapeCursor? cursor,
  List<_OrderBookSweepReplayPacket> packets,
) {
  if (cursor != null &&
      packets.any((packet) => packet.identity == cursor.identity)) {
    return cursor;
  }
  final packet = packets.firstOrNull;
  final step = packet?.steps.firstOrNull;
  if (packet == null || step == null) return null;
  // Packet generation and tape capture happen before the ladder child can
  // publish its playback cursor. Treat that ingest frame as arrival so a
  // canonical future print never flashes before its border starts moving.
  return _OrderBookSweepTapeCursor(
    snapshot: packet.snapshot,
    step: step,
    source: packet.source,
    identity: packet.identity,
    arrived: false,
  );
}

List<_OrderBookTapePrint> _orderBookTradeTapeAtCursor(
  List<_OrderBookTapePrint> latest,
  _OrderBookSweepTapeCursor? cursor,
) {
  if (cursor == null) return latest;
  if (!cursor.arrived) return const <_OrderBookTapePrint>[];
  final step = cursor.step;
  final side = step.side == GameOrderBookSide.ask
      ? TradeSide.buy
      : TradeSide.sell;
  final isPlayer = cursor.source == 'player';
  final matching = latest
      .where(
        (print) =>
            print.marketMinute == step.marketMinute &&
            print.microstructureFrame == step.liquidityPulse &&
            print.sequence == step.sequence &&
            print.side == side &&
            (!isPlayer ||
                (print.executionIdentity.isNotEmpty &&
                    cursor.identity.endsWith(':${print.executionIdentity}'))) &&
            print.isPlayer == isPlayer &&
            (print.price - step.price).abs() < 0.000001 &&
            print.quantity == step.consumedQuantity,
      )
      .firstOrNull;
  final active =
      matching ??
      _OrderBookTapePrint(
        sessionKey:
            '${cursor.snapshot.sourceDateKey}:${cursor.snapshot.sourceAssetId}',
        marketMinute: step.marketMinute,
        microstructureFrame: step.liquidityPulse,
        price: step.price,
        previousPrice: cursor.snapshot.sourceLastTradePrice ?? step.price,
        quantity: step.consumedQuantity,
        side: side,
        isPlayer: isPlayer,
        sequence: step.sequence,
        executionIdentity: cursor.identity,
      );
  // The canonical market can already be several packets ahead at 3x/10x.
  // Expose only the packet currently receiving its border so a future print
  // never appears before its own arrival -> drain playback.
  return <_OrderBookTapePrint>[active];
}

String _orderBookSweepReplayIdentity(
  GameOrderBookSnapshot snapshot,
  List<GameOrderBookSweepStep> steps,
  String source, {
  String? uniqueToken,
  Iterable<OrderBookCancellationNotice> cancellations =
      const <OrderBookCancellationNotice>[],
}) {
  final stepIdentity = steps
      .map(
        (step) =>
            '${step.sequence}:${step.side.name}:'
            '${step.price.toStringAsFixed(6)}:'
            '${step.consumedQuantity}:${step.remainingQuantity}',
      )
      .join('|');
  final cancellationIdentity = cancellations
      .map(
        (notice) =>
            '${notice.side.name}:${notice.price.toStringAsFixed(6)}:'
            '${notice.quantity}',
      )
      .join('|');
  final marketMinute =
      steps.firstOrNull?.marketMinute ?? snapshot.sourceMarketMinute ?? -1;
  final liquidityPulse =
      steps.firstOrNull?.liquidityPulse ?? snapshot.liquidityPulse;
  final transitionIdentity = stepIdentity.isNotEmpty
      ? stepIdentity
      : 'cancel=$cancellationIdentity';
  return '$source:${snapshot.sourceAssetId}:${snapshot.sourceDateKey}:'
      '$marketMinute:$liquidityPulse:'
      '${uniqueToken ?? transitionIdentity}';
}

mixin _OrderBookSweepPlayback<T extends StatefulWidget> on State<T> {
  Timer? _orderBookSweepTimer;
  final List<_OrderBookSweepBatch> _pendingOrderBookSweeps = [];
  final OrderBookSweepIdentityLedger _orderBookSweepIdentityLedger =
      OrderBookSweepIdentityLedger(completedHistoryCapacity: 256);
  _OrderBookSweepBatch? _activeOrderBookSweepBatch;
  int _orderBookSweepIndex = -1;
  Duration _orderBookSweepStepDuration = _orderBookSweepMaximumStepDuration;
  _OrderBookSweepPhase _orderBookSweepPhase = _OrderBookSweepPhase.idle;
  int _orderBookSweepScheduleGeneration = 0;
  int _orderBookSweepPlaybackRate = 1;
  bool _orderBookSweepPlaybackPaused = false;
  bool _orderBookSweepAwaitingCompletion = false;
  GameOrderBookSnapshot? _orderBookPausedPresentationSnapshot;

  void onOrderBookSweepBatchCompleted(String identity);

  void onOrderBookSweepPlaybackChanged({bool deferUntilAfterFrame = false}) {}

  GameOrderBookSweepStep? get _activeOrderBookSweepStep {
    final batch = _activeOrderBookSweepBatch;
    if (batch == null ||
        _orderBookSweepIndex < 0 ||
        _orderBookSweepIndex >= batch.steps.length) {
      return null;
    }
    return batch.steps[_orderBookSweepIndex];
  }

  bool get _activeOrderBookSweepStepArrived =>
      _orderBookSweepPhase == _OrderBookSweepPhase.draining;

  Duration _scaledOrderBookSweepDuration(Duration duration) {
    final microseconds = math
        .max(
          1,
          (duration.inMicroseconds / math.max(1, _orderBookSweepPlaybackRate))
              .round(),
        )
        .toInt();
    return Duration(microseconds: microseconds);
  }

  Duration get _orderBookSweepMotionDuration {
    final scaled = _scaledOrderBookSweepDuration(_orderBookMotionDuration);
    // Even at 10x, keep two 60 Hz frames for each price-row arrival. Faster
    // motion skips visible intermediate rows and looks like a random jump.
    return scaled < const Duration(milliseconds: 36)
        ? const Duration(milliseconds: 36)
        : scaled;
  }

  void _initializeOrderBookSweepPlaybackSpeed(
    _MarketPlaybackSpeed playbackSpeed,
    GameOrderBookSnapshot initialSnapshot,
  ) {
    _orderBookSweepPlaybackPaused =
        playbackSpeed == _MarketPlaybackSpeed.paused;
    _orderBookPausedPresentationSnapshot = _orderBookSweepPlaybackPaused
        ? initialSnapshot
        : null;
    if (playbackSpeed.minutesPerSecond > 0) {
      _orderBookSweepPlaybackRate = playbackSpeed.minutesPerSecond;
    }
  }

  void _setOrderBookSweepPlaybackSpeed(
    _MarketPlaybackSpeed playbackSpeed,
    GameOrderBookSnapshot currentSnapshot,
  ) {
    final paused = playbackSpeed == _MarketPlaybackSpeed.paused;
    final rate = playbackSpeed.minutesPerSecond > 0
        ? playbackSpeed.minutesPerSecond
        : _orderBookSweepPlaybackRate;
    if (_orderBookSweepPlaybackPaused == paused &&
        _orderBookSweepPlaybackRate == rate) {
      return;
    }

    _orderBookSweepScheduleGeneration += 1;
    _orderBookSweepTimer?.cancel();
    _orderBookSweepTimer = null;
    setState(() {
      _orderBookSweepPlaybackPaused = paused;
      _orderBookSweepPlaybackRate = math.max(1, rate);
      _orderBookPausedPresentationSnapshot = paused
          ? _activeOrderBookSweepBatch?.snapshot ?? currentSnapshot
          : null;
      _refreshOrderBookSweepStepDuration();
    });
    if (!paused) _resumeOrderBookSweepPlayback();
  }

  void _refreshOrderBookSweepStepDuration() {
    final stepCount = math.max(
      1,
      _activeOrderBookSweepBatch?.steps.length ?? 1,
    );
    final durationMs = (_orderBookSweepTotalDuration.inMilliseconds / stepCount)
        .round()
        .clamp(
          _orderBookSweepMinimumStepDuration.inMilliseconds,
          _orderBookSweepMaximumStepDuration.inMilliseconds,
        )
        .toInt();
    _orderBookSweepStepDuration = _scaledOrderBookSweepDuration(
      Duration(milliseconds: durationMs),
    );
  }

  void _resumeOrderBookSweepPlayback() {
    if (_orderBookSweepPlaybackPaused) return;
    if (_activeOrderBookSweepBatch == null) {
      if (_pendingOrderBookSweeps.isNotEmpty) {
        _beginNextOrderBookSweep();
      }
      return;
    }
    if (_orderBookSweepAwaitingCompletion) {
      _scheduleOrderBookSweepTimerAfterFrame(
        _scaledOrderBookSweepDuration(_orderBookSweepFinalHoldDuration),
        _completeActiveOrderBookSweep,
      );
    } else if (_orderBookSweepPhase == _OrderBookSweepPhase.draining) {
      _scheduleOrderBookSweepDrain();
    } else if (_orderBookSweepPhase == _OrderBookSweepPhase.arriving) {
      _scheduleOrderBookSweepArrival();
    }
  }

  int get _activeOrderBookSweepStepNumber => _orderBookSweepIndex + 1;

  int get _activeOrderBookSweepStepCount =>
      _activeOrderBookSweepBatch?.steps.length ?? 0;

  GameOrderBookSnapshot _orderBookSweepPresentationSnapshot(
    GameOrderBookSnapshot latest,
  ) =>
      _activeOrderBookSweepBatch?.snapshot ??
      (_orderBookSweepPlaybackPaused
          ? _orderBookPausedPresentationSnapshot
          : null) ??
      latest;

  List<GameOrderBookLevel> _orderBookSweepPresentationLevels(
    GameOrderBookSnapshot latest,
  ) {
    final batch = _activeOrderBookSweepBatch;
    if (batch == null) {
      return _symmetricVisibleOrderBookLevels(
        _orderBookSweepPlaybackPaused
            ? _orderBookPausedPresentationSnapshot ?? latest
            : latest,
      );
    }
    if (batch.steps.isEmpty) {
      return stableOrderBookPresentationLevels(
        snapshot: batch.snapshot,
        fallbackSnapshot: batch.previousSnapshot,
      );
    }
    final levels = orderBookSweepPresentationLevels(
      snapshot: batch.snapshot,
      previousSnapshot: batch.previousSnapshot,
      steps: batch.steps,
      cancellationNotices: batch.cancellations,
      activeStepIndex: _orderBookSweepIndex,
      activeStepArrived: _activeOrderBookSweepStepArrived,
    );
    if (levels.isNotEmpty) return levels;
    return stableOrderBookPresentationLevels(
      snapshot: latest,
      fallbackSnapshot: batch.previousSnapshot,
    );
  }

  String _orderBookSweepBatchId(
    GameOrderBookSnapshot snapshot,
    List<GameOrderBookSweepStep> steps,
    List<OrderBookCancellationNotice> cancellations,
    String source,
    String? identityToken,
  ) =>
      identityToken ??
      _orderBookSweepReplayIdentity(
        snapshot,
        steps,
        source,
        cancellations: cancellations,
      );

  void _syncOrderBookSweep(
    GameOrderBookSnapshot snapshot, {
    GameOrderBookSnapshot? previousSnapshot,
    List<GameOrderBookSweepStep>? explicitSteps,
    List<OrderBookCancellationNotice> cancellations =
        const <OrderBookCancellationNotice>[],
    String source = 'market',
    String? identityToken,
    _OrderBookSweepReplayProgress? replayProgress,
  }) {
    final sourceSteps = explicitSteps ?? snapshot.sweepSteps;
    final steps =
        sourceSteps
            .where((step) => step.consumedQuantity > 0)
            .toList(growable: false)
          ..sort((left, right) => left.sequence.compareTo(right.sequence));
    final replayCancellations = cancellations
        .where((notice) => notice.quantity > 0)
        .toList(growable: false);
    if (steps.isEmpty) return;
    final batchId = _orderBookSweepBatchId(
      snapshot,
      steps,
      replayCancellations,
      source,
      identityToken,
    );
    if (!_orderBookSweepIdentityLedger.admit(batchId)) return;
    final batch = _OrderBookSweepBatch(
      snapshot: snapshot,
      previousSnapshot: previousSnapshot ?? snapshot,
      steps: List<GameOrderBookSweepStep>.unmodifiable(steps),
      cancellations: List<OrderBookCancellationNotice>.unmodifiable(
        replayCancellations,
      ),
      identity: batchId,
      source: source,
      progress: replayProgress ?? _OrderBookSweepReplayProgress(),
    );
    // Never discard an actual fill batch: each transition must
    // reach its own FIFO presentation phase at high playback speed.
    _pendingOrderBookSweeps.add(batch);
    if (!_orderBookSweepPlaybackPaused &&
        _activeOrderBookSweepBatch == null &&
        _orderBookSweepTimer == null) {
      _beginNextOrderBookSweep(deferPresentationUntilAfterFrame: true);
    }
  }

  void _beginNextOrderBookSweep({
    bool deferPresentationUntilAfterFrame = false,
  }) {
    if (_orderBookSweepPlaybackPaused || _pendingOrderBookSweeps.isEmpty) {
      return;
    }
    _activeOrderBookSweepBatch = _pendingOrderBookSweeps.removeAt(0);
    _orderBookSweepAwaitingCompletion = false;
    final progress = _activeOrderBookSweepBatch!.progress;
    _orderBookSweepIndex = progress.stepIndex
        .clamp(0, _activeOrderBookSweepBatch!.steps.length - 1)
        .toInt();
    progress.stepIndex = _orderBookSweepIndex;
    _orderBookSweepPhase = progress.arrived
        ? _OrderBookSweepPhase.draining
        : _OrderBookSweepPhase.arriving;
    onOrderBookSweepPlaybackChanged(
      deferUntilAfterFrame: deferPresentationUntilAfterFrame,
    );
    _refreshOrderBookSweepStepDuration();
    if (_orderBookSweepPhase == _OrderBookSweepPhase.draining) {
      _scheduleOrderBookSweepDrain();
    } else {
      _scheduleOrderBookSweepArrival();
    }
  }

  void _scheduleOrderBookSweepTimerAfterFrame(
    Duration duration,
    VoidCallback callback,
  ) {
    _orderBookSweepTimer?.cancel();
    _orderBookSweepTimer = null;
    final generation = ++_orderBookSweepScheduleGeneration;
    final batchIdentity = _activeOrderBookSweepBatch?.identity;
    final stepIndex = _orderBookSweepIndex;
    final phase = _orderBookSweepPhase;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _orderBookSweepPlaybackPaused ||
          generation != _orderBookSweepScheduleGeneration ||
          _activeOrderBookSweepBatch?.identity != batchIdentity ||
          _orderBookSweepIndex != stepIndex ||
          _orderBookSweepPhase != phase) {
        return;
      }
      _orderBookSweepTimer = Timer(duration, () {
        if (!mounted ||
            _orderBookSweepPlaybackPaused ||
            generation != _orderBookSweepScheduleGeneration ||
            _activeOrderBookSweepBatch?.identity != batchIdentity ||
            _orderBookSweepIndex != stepIndex ||
            _orderBookSweepPhase != phase) {
          return;
        }
        callback();
      });
    });
  }

  void _scheduleOrderBookSweepArrival() {
    _scheduleOrderBookSweepTimerAfterFrame(_orderBookSweepMotionDuration, () {
      final step = _activeOrderBookSweepStep;
      setState(() {
        _orderBookSweepPhase = _OrderBookSweepPhase.draining;
        _activeOrderBookSweepBatch?.progress.arrived = true;
      });
      onOrderBookSweepPlaybackChanged();
      if (step != null && step.remainingQuantity <= 0) {
        _advanceOrderBookSweepAfterCurrentStep(skipFinalHold: true);
        return;
      }
      _scheduleOrderBookSweepDrain();
    });
  }

  void _completeActiveOrderBookSweep() {
    final completedIdentity = _activeOrderBookSweepBatch?.identity;
    if (completedIdentity != null) {
      _orderBookSweepIdentityLedger.complete(completedIdentity);
    }
    setState(() {
      _activeOrderBookSweepBatch = null;
      _orderBookSweepIndex = -1;
      _orderBookSweepPhase = _OrderBookSweepPhase.idle;
      _orderBookSweepAwaitingCompletion = false;
    });
    if (!_orderBookSweepPlaybackPaused && _pendingOrderBookSweeps.isNotEmpty) {
      _beginNextOrderBookSweep();
    } else {
      _orderBookSweepTimer = null;
    }
    onOrderBookSweepPlaybackChanged();
    if (completedIdentity != null) {
      onOrderBookSweepBatchCompleted(completedIdentity);
    }
  }

  void _advanceOrderBookSweepAfterCurrentStep({bool skipFinalHold = false}) {
    final batch = _activeOrderBookSweepBatch;
    if (batch == null) return;
    final nextIndex = _orderBookSweepIndex + 1;
    if (nextIndex < batch.steps.length) {
      setState(() {
        _orderBookSweepIndex = nextIndex;
        _orderBookSweepPhase = _OrderBookSweepPhase.arriving;
        batch.progress
          ..stepIndex = nextIndex
          ..arrived = false;
      });
      onOrderBookSweepPlaybackChanged();
      _scheduleOrderBookSweepArrival();
      return;
    }
    if (skipFinalHold) {
      _completeActiveOrderBookSweep();
      return;
    }
    setState(() => _orderBookSweepAwaitingCompletion = true);
    _scheduleOrderBookSweepTimerAfterFrame(
      _scaledOrderBookSweepDuration(_orderBookSweepFinalHoldDuration),
      _completeActiveOrderBookSweep,
    );
  }

  void _scheduleOrderBookSweepDrain() {
    _scheduleOrderBookSweepTimerAfterFrame(
      _orderBookSweepStepDuration,
      _advanceOrderBookSweepAfterCurrentStep,
    );
  }

  void _resetOrderBookSweepPlayback({bool clearHistory = false}) {
    _orderBookSweepScheduleGeneration += 1;
    _orderBookSweepTimer?.cancel();
    _orderBookSweepTimer = null;
    _pendingOrderBookSweeps.clear();
    _activeOrderBookSweepBatch = null;
    _orderBookSweepIdentityLedger.clearInFlight();
    _orderBookSweepIndex = -1;
    _orderBookSweepPhase = _OrderBookSweepPhase.idle;
    _orderBookSweepAwaitingCompletion = false;
    _orderBookPausedPresentationSnapshot = null;
    onOrderBookSweepPlaybackChanged(deferUntilAfterFrame: true);
    if (clearHistory) _orderBookSweepIdentityLedger.clear();
  }

  void _disposeOrderBookSweepPlayback() => _resetOrderBookSweepPlayback();
}

class _OrderBookSweepRowOverlay extends StatelessWidget {
  const _OrderBookSweepRowOverlay({
    required this.step,
    required this.stepDuration,
    required this.stepNumber,
    required this.stepCount,
    required this.maxDepth,
    this.compact = false,
  });

  final GameOrderBookSweepStep step;
  final Duration stepDuration;
  final int stepNumber;
  final int stepCount;
  final int maxDepth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isAskQueue = step.side == GameOrderBookSide.ask;
    final color = isAskQueue ? _marketAccent : const Color(0xFFF04452);
    final depthTransition = orderBookSweepDepthTransition(
      step: step,
      maxDepth: maxDepth,
    );
    final queueLabel = isAskQueue ? '매도잔량' : '매수잔량';
    final aggressorLabel = isAskQueue ? '매수 체결' : '매도 체결';
    final quantityLabel = step.remainingQuantity <= 0
        ? '$queueLabel ${_money(step.consumedQuantity)}주 소진'
        : '$queueLabel ${_money(step.consumedQuantity)}주 체결 · '
              '잔 ${_money(step.remainingQuantity)}주';
    final eventLabel = step.structuralBreach
        ? '$quantityLabel · 구조 경계 돌파'
        : step.boundaryCrossed
        ? '$quantityLabel · 경계 통과'
        : quantityLabel;

    final priceLabel = '${_money(step.price.round())}원';
    final actionLabel = isAskQueue ? '매수' : '매도';
    final fillLabel = step.remainingQuantity <= 0 ? '소진' : '체결';
    final boundaryLabel = step.structuralBreach
        ? '구조돌파'
        : step.boundaryCrossed
        ? '통과'
        : '';
    final statusLabel =
        '$actionLabel ${_money(step.consumedQuantity)}주 $fillLabel'
        '${boundaryLabel.isEmpty ? '' : '·$boundaryLabel'} '
        '$stepNumber/$stepCount';

    Widget drainBar(Alignment alignment) => TweenAnimationBuilder<double>(
      key: ValueKey((
        'order-book-sweep-drain',
        step.marketMinute,
        step.liquidityPulse,
        step.sequence,
        compact,
      )),
      duration: stepDuration,
      curve: Curves.easeOutCubic,
      tween: Tween<double>(
        begin: depthTransition.before,
        end: depthTransition.after,
      ),
      builder: (context, ratio, _) => Align(
        alignment: alignment,
        child: FractionallySizedBox(
          widthFactor: ratio,
          heightFactor: 1,
          child: ColoredBox(
            color: color.withValues(alpha: compact ? 0.20 : 0.28),
          ),
        ),
      ),
    );

    Widget statusCell() => Container(
      key: const Key('order-book-sweep-status-cell'),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9EDF2))),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          statusLabel,
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            fontFeatures: _marketNumberFeatures,
          ),
        ),
      ),
    );

    return Semantics(
      label:
          '$aggressorLabel ${_money(step.consumedQuantity)}주, '
          '$priceLabel, $eventLabel, $stepNumber/$stepCount',
      child: IgnorePointer(
        child: ClipRect(
          child: Container(
            key: Key(
              compact
                  ? 'inline-order-book-sweep-step'
                  : 'order-book-sweep-step',
            ),
            color: Colors.transparent,
            child: compact
                ? Row(
                    children: [
                      const Expanded(flex: 6, child: SizedBox.shrink()),
                      Expanded(flex: 5, child: drainBar(Alignment.centerRight)),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 124,
                          child: isAskQueue
                              ? drainBar(Alignment.centerRight)
                              : statusCell(),
                        ),
                        const Expanded(child: SizedBox.shrink()),
                        SizedBox(
                          width: 124,
                          child: isAskQueue
                              ? statusCell()
                              : drainBar(Alignment.centerLeft),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CompactOrderBookRail extends StatefulWidget {
  const _CompactOrderBookRail({
    required this.definition,
    required this.quote,
    required this.state,
    required this.minute,
    required this.playbackSpeed,
    required this.snapshot,
    required this.sweepPackets,
    required this.onSweepPacketsAccepted,
    required this.playerTrade,
    required this.selectedPrice,
    required this.onSelectPrice,
  });

  final _StockDefinition definition;
  final _LiveStock quote;
  final GameState state;
  final int minute;
  final ValueListenable<_MarketPlaybackSpeed> playbackSpeed;
  final GameOrderBookSnapshot snapshot;
  final List<_OrderBookSweepReplayPacket> sweepPackets;
  final ValueChanged<Iterable<String>> onSweepPacketsAccepted;
  final _PlayerTradeSignal? playerTrade;
  final double? selectedPrice;
  final ValueChanged<double> onSelectPrice;

  @override
  State<_CompactOrderBookRail> createState() => _CompactOrderBookRailState();
}

class _CompactOrderBookRailState extends State<_CompactOrderBookRail>
    with _OrderBookSweepPlayback<_CompactOrderBookRail> {
  String? _depthScaleAssetId;
  double _depthScale = 0;

  void _syncCurrentOrderBookSweep() {
    for (final packet in widget.sweepPackets) {
      _syncOrderBookSweep(
        packet.snapshot,
        previousSnapshot: packet.previousSnapshot,
        explicitSteps: packet.steps,
        cancellations: packet.cancellations,
        source: packet.source,
        identityToken: packet.identity,
        replayProgress: packet.progress,
      );
    }
  }

  void _handleOrderBookPlaybackSpeedChanged() {
    _setOrderBookSweepPlaybackSpeed(
      widget.playbackSpeed.value,
      widget.snapshot,
    );
  }

  @override
  void onOrderBookSweepBatchCompleted(String identity) {
    widget.onSweepPacketsAccepted(<String>[identity]);
  }

  @override
  void initState() {
    super.initState();
    _initializeOrderBookSweepPlaybackSpeed(
      widget.playbackSpeed.value,
      widget.snapshot,
    );
    widget.playbackSpeed.addListener(_handleOrderBookPlaybackSpeedChanged);
    _syncCurrentOrderBookSweep();
  }

  @override
  void didUpdateWidget(covariant _CompactOrderBookRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playbackSpeed != widget.playbackSpeed) {
      oldWidget.playbackSpeed.removeListener(
        _handleOrderBookPlaybackSpeedChanged,
      );
      widget.playbackSpeed.addListener(_handleOrderBookPlaybackSpeedChanged);
      _setOrderBookSweepPlaybackSpeed(
        widget.playbackSpeed.value,
        widget.snapshot,
      );
    }
    if (oldWidget.snapshot.sourceAssetId != widget.snapshot.sourceAssetId ||
        oldWidget.snapshot.sourceDateKey != widget.snapshot.sourceDateKey) {
      _resetOrderBookSweepPlayback(clearHistory: true);
    }
    _syncCurrentOrderBookSweep();
  }

  @override
  void dispose() {
    widget.playbackSpeed.removeListener(_handleOrderBookPlaybackSpeedChanged);
    _disposeOrderBookSweepPlayback();
    super.dispose();
  }

  bool _matches(double left, double? right) =>
      right != null && (left - right).abs() < 0.000001;

  int _stableDepthScale(int observed) {
    final safeObserved = math.max(1, observed);
    if (_depthScaleAssetId != widget.definition.id || _depthScale <= 0) {
      _depthScaleAssetId = widget.definition.id;
      _depthScale = safeObserved.toDouble();
    } else if (safeObserved > _depthScale * 1.25) {
      _depthScale = safeObserved.toDouble();
    } else if (safeObserved < _depthScale * 0.55) {
      _depthScale = math.max(safeObserved.toDouble(), _depthScale * 0.92);
    }
    return math.max(1, _depthScale.round());
  }

  int _displayQuantity(GameOrderBookLevel level) {
    final playerQuantity = widget.state.pendingOrders
        .where(
          (order) =>
              order.assetId == widget.definition.id &&
              (order.limitPrice - level.price).abs() < 0.000001 &&
              (level.side == GameOrderBookSide.ask
                  ? order.side == PendingOrderSide.sell
                  : order.side == PendingOrderSide.buy),
        )
        .fold<double>(0, (sum, order) => sum + order.remainingQuantity);
    return level.quantity + playerQuantity.ceil();
  }

  @override
  Widget build(BuildContext context) {
    final activeSweepStep = _activeOrderBookSweepStep;
    final snapshot = _orderBookSweepPresentationSnapshot(widget.snapshot);
    final levels = _orderBookSweepPresentationLevels(widget.snapshot);
    final compactSweepHeaderLabel = activeSweepStep == null
        ? '잔량'
        : activeSweepStep.structuralBreach
        ? '구조돌파 $_activeOrderBookSweepStepNumber/'
              '$_activeOrderBookSweepStepCount'
        : activeSweepStep.boundaryCrossed
        ? '통과 $_activeOrderBookSweepStepNumber/'
              '$_activeOrderBookSweepStepCount'
        : '체결 $_activeOrderBookSweepStepNumber/'
              '$_activeOrderBookSweepStepCount';
    final compactSweepHeaderColor = activeSweepStep == null
        ? _marketMuted
        : activeSweepStep.side == GameOrderBookSide.ask
        ? _marketAccent
        : const Color(0xFFF04452);
    final currentPrice = marketSnapPrice(
      snapshot.sourceLastTradePrice ?? widget.quote.price,
      market: widget.definition.market,
    );
    final generatedTrade = snapshot.lastSyntheticTrade;
    final hasCurrentGeneratedTrade =
        generatedTrade != null &&
        generatedTrade.quantity > 0 &&
        generatedTrade.marketMinute == widget.minute &&
        generatedTrade.liquidityPulse == snapshot.liquidityPulse &&
        levels.any((level) => _matches(level.price, generatedTrade.price));
    double? outlinePrice = activeSweepStep?.price;
    GameOrderBookSide? outlineSide = activeSweepStep?.side;
    if (activeSweepStep == null && hasCurrentGeneratedTrade) {
      outlinePrice = generatedTrade.price;
      outlineSide = generatedTrade.levelSide;
    }
    final playerTrade = widget.playerTrade;
    final playerPrint = playerTrade?.orderBookPrint;
    final hasCurrentPlayerTrade =
        playerTrade != null &&
        playerPrint != null &&
        playerTrade.assetId == widget.definition.id &&
        playerTrade.marketMinute == widget.minute &&
        playerTrade.microstructureFrame == snapshot.liquidityPulse &&
        levels.any((level) => _matches(level.price, playerPrint.price));
    if (activeSweepStep == null && hasCurrentPlayerTrade) {
      outlinePrice = playerPrint.price;
      outlineSide = playerPrint.levelSide;
    }
    outlinePrice ??=
        levels
            .where((level) => _matches(level.price, currentPrice))
            .firstOrNull
            ?.price ??
        snapshot.bids.firstOrNull?.price;
    if (activeSweepStep == null) {
      final bestAsk = levels
          .where((level) => level.side == GameOrderBookSide.ask)
          .lastOrNull;
      final bestBid = levels
          .where((level) => level.side == GameOrderBookSide.bid)
          .firstOrNull;
      final outlineIsAtTouch = levels.any(
        (level) =>
            _matches(level.price, outlinePrice) &&
            (outlineSide == null || level.side == outlineSide) &&
            (identical(level, bestAsk) || identical(level, bestBid)),
      );
      if (!outlineIsAtTouch) {
        final touch = outlineSide == GameOrderBookSide.ask
            ? bestAsk
            : outlineSide == GameOrderBookSide.bid
            ? bestBid
            : outlinePrice != null &&
                  bestAsk != null &&
                  outlinePrice >= bestAsk.price
            ? bestAsk
            : bestBid ?? bestAsk;
        outlinePrice = touch?.price;
        outlineSide = touch?.side;
      }
    }
    final observedMaxDepth = levels.fold<int>(
      1,
      (maximum, level) => math.max(maximum, _displayQuantity(level)),
    );
    final maxDepth = _stableDepthScale(observedMaxDepth);
    return TickerMode(
      enabled: !_orderBookSweepPlaybackPaused,
      child: Container(
        key: const Key('inline-order-book'),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6F8),
                border: Border(bottom: BorderSide(color: Color(0xFFDDE2E8))),
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 6,
                    child: Text(
                      '가격',
                      style: TextStyle(
                        color: _marketMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: AnimatedSwitcher(
                      key: const Key('inline-order-book-sweep-status-header'),
                      duration: _orderBookSweepMinimumStepDuration,
                      child: Text(
                        compactSweepHeaderLabel,
                        key: ValueKey((
                          'inline-order-book-sweep-status-header',
                          compactSweepHeaderLabel,
                        )),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        style: TextStyle(
                          color: compactSweepHeaderColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (levels.isEmpty) return const SizedBox.shrink();
                  final rowHeight = constraints.maxHeight / levels.length;
                  final outlineIndex = levels.indexWhere(
                    (level) =>
                        _matches(level.price, outlinePrice) &&
                        (outlineSide == null || level.side == outlineSide),
                  );
                  final sweepIndex = activeSweepStep == null
                      ? -1
                      : levels.indexWhere(
                          (level) =>
                              level.side == activeSweepStep.side &&
                              (level.price - activeSweepStep.price).abs() <
                                  0.000001,
                        );
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      if (activeSweepStep != null)
                        Offstage(
                          child: SizedBox(
                            key: ValueKey((
                              'order-book-sweep-active',
                              _activeOrderBookSweepBatch?.identity,
                              activeSweepStep.sequence,
                              _orderBookSweepPhase.name,
                              'compact',
                            )),
                          ),
                        ),
                      for (final entry in levels.asMap().entries)
                        Positioned(
                          key: ValueKey((
                            'inline-order-book-price',
                            entry.value.side.name,
                            entry.value.price,
                          )),
                          top: entry.key * rowHeight,
                          left: 0,
                          right: 0,
                          height: rowHeight,
                          child: _CompactOrderBookRow(
                            level: entry.value,
                            depthAnimationDuration:
                                activeSweepStep != null &&
                                    _activeOrderBookSweepStepArrived &&
                                    entry.value.side == activeSweepStep.side &&
                                    (entry.value.price - activeSweepStep.price)
                                            .abs() <
                                        0.000001
                                ? _orderBookSweepStepDuration
                                : _orderBookMotionDuration,
                            isTradeDrain:
                                activeSweepStep != null &&
                                _activeOrderBookSweepStepArrived &&
                                entry.value.side == activeSweepStep.side &&
                                (entry.value.price - activeSweepStep.price)
                                        .abs() <
                                    0.000001,
                            quantity: _displayQuantity(entry.value),
                            maxDepth: maxDepth,
                            previousClose: widget.quote.previousClose,
                            isCurrent:
                                _matches(entry.value.price, outlinePrice) &&
                                (outlineSide == null ||
                                    entry.value.side == outlineSide),
                            isSelected: _matches(
                              entry.value.price,
                              widget.selectedPrice,
                            ),
                            onTap: () =>
                                widget.onSelectPrice(entry.value.price),
                          ),
                        ),
                      if (sweepIndex >= 0 &&
                          activeSweepStep != null &&
                          _activeOrderBookSweepStepArrived)
                        Positioned(
                          key: const Key('inline-order-book-sweep-position'),
                          top: sweepIndex * rowHeight,
                          left: 0,
                          right: 0,
                          height: rowHeight,
                          child: _OrderBookSweepRowOverlay(
                            step: activeSweepStep,
                            stepDuration: _orderBookSweepStepDuration,
                            stepNumber: _activeOrderBookSweepStepNumber,
                            stepCount: _activeOrderBookSweepStepCount,
                            maxDepth: maxDepth,
                            compact: true,
                          ),
                        ),
                      if (outlineIndex >= 0)
                        AnimatedPositioned(
                          key: const Key(
                            'inline-order-book-current-price-border',
                          ),
                          duration: activeSweepStep == null
                              ? _orderBookMotionDuration
                              : _orderBookSweepMotionDuration,
                          curve: Curves.easeOutCubic,
                          top: outlineIndex * rowHeight,
                          left: 0,
                          right: constraints.maxWidth * 5 / 11,
                          height: rowHeight,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFF04452),
                                  width: 1.7,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactOrderBookRow extends StatelessWidget {
  const _CompactOrderBookRow({
    required this.level,
    required this.depthAnimationDuration,
    required this.quantity,
    required this.isTradeDrain,
    required this.maxDepth,
    required this.previousClose,
    required this.isCurrent,
    required this.isSelected,
    required this.onTap,
  });

  final GameOrderBookLevel level;
  final Duration depthAnimationDuration;
  final int quantity;
  final bool isTradeDrain;
  final int maxDepth;
  final double previousClose;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAsk = level.side == GameOrderBookSide.ask;
    final color = isAsk ? _marketAccent : const Color(0xFFF04452);
    final tint = isAsk ? const Color(0xFFEAF3FF) : const Color(0xFFFFEEF3);
    final bar = isAsk ? const Color(0x668DB8F3) : const Color(0x66EF9AB7);
    final depth = (quantity / math.max(1, maxDepth)).clamp(0.0, 1.0);
    return Material(
      color: tint.withValues(alpha: isSelected ? 0.90 : 0.58),
      child: InkWell(
        onTap: onTap,
        child: Container(
          key: ValueKey(
            isAsk ? 'inline-order-book-ask-row' : 'inline-order-book-bid-row',
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE8EBF0))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.only(left: 4),
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _money(level.price.round()),
                          maxLines: 1,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: isCurrent || isSelected
                                ? FontWeight.w900
                                : FontWeight.w800,
                            fontFeatures: _marketNumberFeatures,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _orderBookPriceRateLabel(level.price, previousClose),
                          key: const Key('inline-order-book-price-rate'),
                          maxLines: 1,
                          style: TextStyle(
                            color: _orderBookPriceRateColor(
                              level.price,
                              previousClose,
                            ),
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            fontFeatures: _marketNumberFeatures,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TweenAnimationBuilder<double>(
                        duration: depthAnimationDuration,
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: depth, end: depth),
                        builder: (context, animatedDepth, child) =>
                            FractionallySizedBox(
                              widthFactor: animatedDepth,
                              heightFactor: 0.78,
                              child: child,
                            ),
                        child: ColoredBox(color: bar),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: _CompactOrderBookQuantityLabel(
                            quantity: quantity,
                            isTradeDrain: isTradeDrain,
                          ),
                        ),
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
  }
}

class _CompactOrderBookQuantityLabel extends StatefulWidget {
  const _CompactOrderBookQuantityLabel({
    required this.quantity,
    required this.isTradeDrain,
  });

  final int quantity;
  final bool isTradeDrain;

  @override
  State<_CompactOrderBookQuantityLabel> createState() =>
      _CompactOrderBookQuantityLabelState();
}

class _CompactOrderBookQuantityLabelState
    extends State<_CompactOrderBookQuantityLabel> {
  int _quantityDelta = 0;
  bool _quantityDeltaIsTrade = false;
  Timer? _deltaTimer;

  @override
  void didUpdateWidget(covariant _CompactOrderBookQuantityLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final delta = widget.quantity - oldWidget.quantity;
    if (delta == 0) return;
    _quantityDelta = delta;
    _quantityDeltaIsTrade = delta < 0 && widget.isTradeDrain;
    _deltaTimer?.cancel();
    _deltaTimer = Timer(const Duration(milliseconds: 520), () {
      if (!mounted) return;
      setState(() {
        _quantityDelta = 0;
        _quantityDeltaIsTrade = false;
      });
    });
  }

  @override
  void dispose() {
    _deltaTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        _money(widget.quantity),
        key: const Key('inline-order-book-quantity-value'),
        maxLines: 1,
        style: const TextStyle(
          color: Color(0xFF343A45),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          fontFeatures: _marketNumberFeatures,
        ),
      ),
      if (_quantityDelta != 0 &&
          orderBookQuantityDeltaLabel(
            _quantityDelta,
            isTrade: _quantityDeltaIsTrade,
          ).isNotEmpty) ...[
        const SizedBox(width: 2),
        Text(
          orderBookQuantityDeltaLabel(
            _quantityDelta,
            isTrade: _quantityDeltaIsTrade,
          ),
          key: const Key('inline-order-book-quantity-delta'),
          maxLines: 1,
          style: TextStyle(
            color: _quantityDelta < 0 && !_quantityDeltaIsTrade
                ? const Color(0xFF7B5A00)
                : _quantityDelta > 0
                ? const Color(0xFF16794E)
                : const Color(0xFFB42332),
            fontSize: 6,
            height: 1,
            fontWeight: FontWeight.w900,
            fontFeatures: _marketNumberFeatures,
          ),
        ),
      ],
    ],
  );
}

class _StockInfoUnavailable extends StatelessWidget {
  const _StockInfoUnavailable();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('stock-info-unavailable'),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _marketLine),
    ),
    child: const Column(
      children: [
        Icon(Icons.info_outline_rounded, color: _marketMuted, size: 30),
        SizedBox(height: 10),
        Text(
          '이 종목은 아직 기업정보가 준비되지 않았어요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _marketInk, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

enum _QuoteQuickAction { buy, sell, amendCancel }

enum _DetailedOrderSection { buy, sell, amendCancel, openOrders, balance }

class _QuoteQuickActionsDialog extends StatelessWidget {
  const _QuoteQuickActionsDialog({required this.price});

  final double price;

  @override
  Widget build(BuildContext context) {
    const sellColor = Color(0xFF4F75E8);
    const buyColor = Color(0xFFEC5A91);
    return Dialog(
      key: const Key('quote-quick-actions'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 76,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: FilledButton(
                      key: const Key('quote-quick-sell'),
                      onPressed: () =>
                          Navigator.of(context).pop(_QuoteQuickAction.sell),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(76),
                        backgroundColor: sellColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(14),
                          ),
                        ),
                      ),
                      child: const Text(
                        '매도',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    key: const Key('quote-quick-price'),
                    width: 132,
                    alignment: Alignment.center,
                    color: Colors.white,
                    child: Text(
                      _money(price.round()),
                      style: const TextStyle(
                        color: Color(0xFF202632),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFeatures: _marketNumberFeatures,
                      ),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      key: const Key('quote-quick-buy'),
                      onPressed: () =>
                          Navigator.of(context).pop(_QuoteQuickAction.buy),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(76),
                        backgroundColor: buyColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(14),
                          ),
                        ),
                      ),
                      child: const Text(
                        '매수',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('quote-quick-amend-cancel'),
              onPressed: () =>
                  Navigator.of(context).pop(_QuoteQuickAction.amendCancel),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                backgroundColor: const Color(0xFF67CC8D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '정정 / 취소',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailedOrderPage extends StatefulWidget {
  const _DetailedOrderPage({
    required this.definition,
    required this.live,
    required this.marketState,
    required this.minute,
    required this.liquidityPulse,
    required this.marketSnapshotReader,
    required this.onExecuteTrade,
    required this.initialIsBuy,
    this.onCancelPendingOrder,
    this.initialOrderType,
    this.initialLimitPrice,
    this.initialSection,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final ValueListenable<GameState> marketState;
  final ValueNotifier<int> minute;
  final int liquidityPulse;
  final ValueGetter<GameOrderBookSnapshot>? marketSnapshotReader;
  final Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade;
  final Future<void> Function(String orderId)? onCancelPendingOrder;
  final bool initialIsBuy;
  final TradeOrderType? initialOrderType;
  final double? initialLimitPrice;
  final _DetailedOrderSection? initialSection;

  @override
  State<_DetailedOrderPage> createState() => _DetailedOrderPageState();
}

class _DetailedOrderPageState extends State<_DetailedOrderPage> {
  late _DetailedOrderSection _section;
  late TradeOrderType? _prefillOrderType;
  double? _prefillPrice;
  double? _prefillQuantity;
  int _formRevision = 0;

  @override
  void initState() {
    super.initState();
    _section =
        widget.initialSection ??
        (widget.initialIsBuy
            ? _DetailedOrderSection.buy
            : _DetailedOrderSection.sell);
    _prefillOrderType = widget.initialOrderType;
    _prefillPrice = widget.initialLimitPrice;
  }

  bool get _isBuy => _section == _DetailedOrderSection.buy;

  Future<void> _amend(PendingTradeOrder order) async {
    final cancel = widget.onCancelPendingOrder;
    if (cancel == null) return;
    await cancel(order.id);
    if (!mounted) return;
    setState(() {
      _section = order.side == PendingOrderSide.buy
          ? _DetailedOrderSection.buy
          : _DetailedOrderSection.sell;
      _prefillOrderType = TradeOrderType.limit;
      _prefillPrice = order.limitPrice;
      _prefillQuantity = order.remainingQuantity;
      _formRevision += 1;
    });
  }

  void _selectSection(_DetailedOrderSection section) {
    setState(() {
      _section = section;
      if (section == _DetailedOrderSection.buy ||
          section == _DetailedOrderSection.sell) {
        _formRevision += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('detailed-order-screen'),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF353B78),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: const Text(
          '상세 주문',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          ValueListenableBuilder<_LiveStock>(
            valueListenable: widget.live,
            builder: (context, quote, _) => Container(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE6E8EC))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.definition.name,
                          style: const TextStyle(
                            color: Color(0xFF202632),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.definition.code} · ${widget.definition.market}',
                          style: const TextStyle(
                            color: Color(0xFF737B88),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_money(quote.price.round())}원',
                    key: const Key('detailed-order-current-price'),
                    style: TextStyle(
                      color: _priceColor(quote.price - quote.previousClose),
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      fontFeatures: _marketNumberFeatures,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _OrderPageTab(
                  key: const Key('detailed-order-buy-tab'),
                  label: '매수',
                  selected: _section == _DetailedOrderSection.buy,
                  color: const Color(0xFFEC3F7A),
                  onTap: () => _selectSection(_DetailedOrderSection.buy),
                ),
                _OrderPageTab(
                  key: const Key('detailed-order-sell-tab'),
                  label: '매도',
                  selected: _section == _DetailedOrderSection.sell,
                  color: const Color(0xFF416CE5),
                  onTap: () => _selectSection(_DetailedOrderSection.sell),
                ),
                _OrderPageTab(
                  key: const Key('detailed-order-amend-tab'),
                  label: '정정/취소',
                  selected: _section == _DetailedOrderSection.amendCancel,
                  onTap: () =>
                      _selectSection(_DetailedOrderSection.amendCancel),
                ),
                _OrderPageTab(
                  key: const Key('detailed-order-open-tab'),
                  label: '미체결',
                  selected: _section == _DetailedOrderSection.openOrders,
                  onTap: () => _selectSection(_DetailedOrderSection.openOrders),
                ),
                _OrderPageTab(
                  key: const Key('detailed-order-balance-tab'),
                  label: '잔고',
                  selected: _section == _DetailedOrderSection.balance,
                  onTap: () => _selectSection(_DetailedOrderSection.balance),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ValueListenableBuilder<GameState>(
              valueListenable: widget.marketState,
              builder: (context, state, _) {
                if (_section == _DetailedOrderSection.buy ||
                    _section == _DetailedOrderSection.sell) {
                  return _OrderSheet(
                    key: ValueKey('order-form-${_section.name}-$_formRevision'),
                    definition: widget.definition,
                    live: widget.live,
                    isBuy: _isBuy,
                    state: state,
                    minute: widget.minute,
                    liquidityPulse: widget.liquidityPulse,
                    marketSnapshotReader: widget.marketSnapshotReader,
                    onExecuteTrade: widget.onExecuteTrade,
                    initialOrderType: _prefillOrderType,
                    initialLimitPrice: _prefillPrice,
                    initialQuantity: _prefillQuantity,
                    submitLabel: _isBuy ? '매수 주문' : '매도 주문',
                  );
                }
                if (_section == _DetailedOrderSection.balance) {
                  return _OrderBalancePanel(
                    definition: widget.definition,
                    state: state,
                  );
                }
                return _DetailedPendingOrdersPanel(
                  definition: widget.definition,
                  state: state,
                  correctionMode: _section == _DetailedOrderSection.amendCancel,
                  onCancel: widget.onCancelPendingOrder,
                  onAmend: _amend,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderPageTab extends StatelessWidget {
  const _OrderPageTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = const Color(0xFF353B78),
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minWidth: 82),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? color : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? color : const Color(0xFF8A919E),
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _DetailedPendingOrdersPanel extends StatelessWidget {
  const _DetailedPendingOrdersPanel({
    required this.definition,
    required this.state,
    required this.correctionMode,
    required this.onCancel,
    required this.onAmend,
  });

  final _StockDefinition definition;
  final GameState state;
  final bool correctionMode;
  final Future<void> Function(String orderId)? onCancel;
  final Future<void> Function(PendingTradeOrder order) onAmend;

  @override
  Widget build(BuildContext context) {
    final orders = state.pendingOrders
        .where((order) => order.assetId == definition.id)
        .toList(growable: false);
    return ListView(
      key: const Key('detailed-pending-orders'),
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          correctionMode ? '정정하거나 취소할 주문' : '미체결 주문',
          style: const TextStyle(
            color: Color(0xFF202632),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          correctionMode
              ? '정정을 누르면 기존 주문을 취소하고 같은 가격·잔여 수량으로 주문서를 다시 엽니다.'
              : '아직 시장에서 체결되지 않고 기다리는 주문입니다.',
          style: const TextStyle(
            color: Color(0xFF6D7582),
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (orders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 70),
            child: Center(
              child: Text(
                '이 종목의 미체결 주문이 없습니다.',
                style: TextStyle(
                  color: Color(0xFF8A919E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          for (final order in orders)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E6EC)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: order.side == PendingOrderSide.buy
                              ? const Color(0xFFFFEAF1)
                              : const Color(0xFFEAF1FF),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          order.side == PendingOrderSide.buy ? '매수' : '매도',
                          style: TextStyle(
                            color: order.side == PendingOrderSide.buy
                                ? const Color(0xFFDC326C)
                                : const Color(0xFF416CE5),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_money(order.limitPrice.round())}원',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFeatures: _marketNumberFeatures,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '미체결 ${_displayUnits(order.remainingQuantity)}주',
                        style: const TextStyle(
                          color: Color(0xFF606977),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (correctionMode)
                        TextButton(
                          onPressed: onCancel == null
                              ? null
                              : () => onAmend(order),
                          child: const Text('정정'),
                        ),
                      const SizedBox(width: 4),
                      OutlinedButton(
                        onPressed: onCancel == null
                            ? null
                            : () => onCancel!(order.id),
                        child: const Text('취소'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _OrderBalancePanel extends StatelessWidget {
  const _OrderBalancePanel({required this.definition, required this.state});

  final _StockDefinition definition;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final position = state.positions
        .where((item) => item.assetId == definition.id)
        .firstOrNull;
    final pending = state.pendingOrders
        .where((order) => order.assetId == definition.id)
        .length;
    return ListView(
      key: const Key('detailed-order-balance'),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '주문 가능 잔고',
          style: TextStyle(
            color: Color(0xFF202632),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        _OrderBalanceRow(
          label: '예수금',
          value: '${_money(state.brokerageCash)}원',
        ),
        _OrderBalanceRow(
          label: '주문 가능 예수금',
          value: '${_money(state.availableBrokerageCash)}원',
        ),
        _OrderBalanceRow(
          label: '보유 수량',
          value: '${_displayUnits(position?.units ?? 0)}주',
        ),
        _OrderBalanceRow(
          label: '매입 금액',
          value: '${_money(position?.totalCost ?? 0)}원',
        ),
        _OrderBalanceRow(label: '미체결 주문', value: '$pending건'),
      ],
    );
  }
}

class _OrderBalanceRow extends StatelessWidget {
  const _OrderBalanceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 15),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE8EAEF))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF69717E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF202632),
            fontSize: 17,
            fontWeight: FontWeight.w900,
            fontFeatures: _marketNumberFeatures,
          ),
        ),
      ],
    ),
  );
}
