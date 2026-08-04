part of 'main.dart';

class _OrderBookPanel extends StatelessWidget {
  const _OrderBookPanel({
    required this.definition,
    required this.quote,
    required this.state,
    required this.minute,
    required this.playbackSpeed,
    required this.snapshot,
    required this.sweepPackets,
    required this.sweepPacketsReader,
    required this.onSweepPacketsAccepted,
    required this.availableHeight,
    required this.playerTrade,
    required this.tradeTape,
    required this.tapeCursor,
    required this.selectedPrice,
    required this.quantityPreset,
    required this.onQuantityPresetChanged,
    required this.onBuy,
    required this.onSell,
    required this.onAmendCancel,
    required this.onTapLevel,
    this.tutorialHeaderKey,
    this.tutorialBestAskKey,
  });

  final _StockDefinition definition;
  final _LiveStock quote;
  final GameState state;
  final int minute;
  final ValueListenable<_MarketPlaybackSpeed> playbackSpeed;
  final GameOrderBookSnapshot snapshot;
  final List<_OrderBookSweepReplayPacket> sweepPackets;
  final List<_OrderBookSweepReplayPacket> Function() sweepPacketsReader;
  final ValueChanged<Iterable<String>> onSweepPacketsAccepted;
  final double availableHeight;
  final _PlayerTradeSignal? playerTrade;
  final List<_OrderBookTapePrint> tradeTape;
  final ValueNotifier<_OrderBookSweepTapeCursor?> tapeCursor;
  final double? selectedPrice;
  final _QuoteQuantityPreset quantityPreset;
  final ValueChanged<_QuoteQuantityPreset> onQuantityPresetChanged;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final VoidCallback onAmendCancel;
  final ValueChanged<GameOrderBookLevel> onTapLevel;
  final GlobalKey? tutorialHeaderKey;
  final GlobalKey? tutorialBestAskKey;

  List<PendingTradeOrder> _playerOrders(GameOrderBookLevel level) => state
      .pendingOrders
      .where(
        (order) =>
            order.assetId == definition.id &&
            (order.limitPrice - level.price).abs() < 0.000001 &&
            (level.side == GameOrderBookSide.ask
                ? order.side == PendingOrderSide.sell
                : order.side == PendingOrderSide.buy),
      )
      .toList(growable: false);

  double _playerQuantity(GameOrderBookLevel level) => _playerOrders(
    level,
  ).fold<double>(0, (sum, order) => sum + order.remainingQuantity);

  String? _playerOrderLabel(GameOrderBookLevel level) {
    final orders = _playerOrders(level);
    if (orders.isEmpty) return null;
    final remaining = orders.fold<double>(
      0,
      (sum, order) => sum + order.remainingQuantity,
    );
    final original = orders.fold<double>(
      0,
      (sum, order) => sum + order.originalQuantity,
    );
    final side = level.side == GameOrderBookSide.ask ? '◆매도' : '◆매수';
    if (orders.length > 1) {
      return '$side ${_displayUnits(remaining)}주 · ${orders.length}건';
    }
    if (original - remaining > 0.000001) {
      return '$side 잔 ${_displayUnits(remaining)}/${_displayUnits(original)}';
    }
    return '$side ${_displayUnits(remaining)}주';
  }

  @override
  Widget build(BuildContext context) {
    final currentDisplayPrice = marketSnapPrice(
      this.snapshot.sourceLastTradePrice ?? quote.price,
      market: definition.market,
    );

    final snapshot = this.snapshot;
    final playerAskQuantity = snapshot.asks.fold<double>(
      0,
      (sum, level) => sum + _playerQuantity(level),
    );
    final playerBidQuantity = snapshot.bids.fold<double>(
      0,
      (sum, level) => sum + _playerQuantity(level),
    );
    final displayedAskQuantity =
        snapshot.totalAskQuantity + playerAskQuantity.ceil();
    final displayedBidQuantity =
        snapshot.totalBidQuantity + playerBidQuantity.ceil();
    final clock = marketClockAt(
      minute,
      tradingDay: quote.isTradingDay && isMarketTradingDay(state.currentDate),
    );
    final previousTradePrice = quote.sessionHistory.length >= 2
        ? quote.sessionHistory[quote.sessionHistory.length - 2]
        : quote.price;
    final viActive = marketDynamicVolatilityInterruptionActive(
      minute: minute,
      previousTradePrice: previousTradePrice,
      currentPrice: quote.price,
      tradingDay: quote.isTradingDay && isMarketTradingDay(state.currentDate),
    );
    final materialHalt = marketMaterialNewsTradingHaltAt(
      simulationSeed: state.simulationSeed,
      date: state.currentDate,
      assetId: definition.id,
      minute: minute,
    );
    final lastContinuousIndex =
        generatedPreOpenTicks + generatedContinuousTradingTicks - 1;
    final auctionReference = quote.sessionPath.length > lastContinuousIndex
        ? quote.sessionPath[lastContinuousIndex]
        : quote.price;
    final dailyRange = marketDailyPriceRange(
      previousClose: quote.previousClose,
      date: state.currentDate,
      market: definition.market,
      isIpoFirstTradingDay: definition.asset.isIpoFirstTradingDay(
        state.currentDate,
      ),
    );
    final indicativeAuctionPrice =
        clock.phase == MarketSessionPhase.closingAuction
        ? generatedClosingAuctionIndicativePrice(
            referencePrice: auctionReference,
            officialClose: quote.officialClose,
            previousClose: quote.previousClose,
            minute: minute,
            seed: marketStockSeed(
              '${state.simulationSeed}:${definition.code}',
              state.currentDate,
            ),
            dailyLimitRate: marketDailyPriceLimitRate(state.currentDate),
            market: definition.market,
            lowerPriceLimit: dailyRange.lower,
            upperPriceLimit: dailyRange.upper,
          )
        : quote.price;
    final visibleOrderBookLevels = _symmetricVisibleOrderBookLevels(snapshot);
    final generatedTrade = snapshot.lastSyntheticTrade;
    final hasCurrentGeneratedTrade =
        clock.phase == MarketSessionPhase.regular &&
        !viActive &&
        materialHalt == null &&
        generatedTrade != null &&
        generatedTrade.quantity > 0 &&
        generatedTrade.marketMinute == minute &&
        generatedTrade.liquidityPulse == snapshot.liquidityPulse &&
        visibleOrderBookLevels.any(
          (level) => (level.price - generatedTrade.price).abs() < 0.000001,
        );
    final compactPanel = availableHeight < 560;
    final marketSummaryHeight = compactPanel ? 28.0 : 44.0;
    final tapeHeight = compactPanel ? 34.0 : 80.0;
    final orderDockHeight = compactPanel ? 38.0 : 48.0;
    const marketStatusBannerHeight = 36.0;
    final hasMarketStatusBanner =
        materialHalt != null ||
        viActive ||
        clock.phase == MarketSessionPhase.closingAuction;
    final showTradeTape = !compactPanel || !hasMarketStatusBanner;
    final fixedPanelHeight =
        28.0 +
        34.0 +
        42.0 +
        2.0 +
        marketSummaryHeight +
        orderDockHeight +
        (showTradeTape ? tapeHeight : 0);
    var activeTradeSide = !hasCurrentGeneratedTrade
        ? null
        : generatedTrade.levelSide == GameOrderBookSide.ask
        ? TradeSide.buy
        : TradeSide.sell;
    var activeTradePrice = hasCurrentGeneratedTrade
        ? generatedTrade.price
        : null;
    var activeTradeQuantity = hasCurrentGeneratedTrade
        ? generatedTrade.quantity
        : 0;
    var activeTradeLevelSide = hasCurrentGeneratedTrade
        ? generatedTrade.levelSide
        : null;
    final currentPlayerTrade = playerTrade;
    final playerPrint = currentPlayerTrade?.orderBookPrint;
    final hasCurrentPlayerTrade =
        clock.phase == MarketSessionPhase.regular &&
        currentPlayerTrade != null &&
        playerPrint != null &&
        currentPlayerTrade.assetId == definition.id &&
        currentPlayerTrade.marketMinute == minute &&
        currentPlayerTrade.microstructureFrame == snapshot.liquidityPulse &&
        visibleOrderBookLevels.any(
          (level) => (level.price - playerPrint.price).abs() < 0.000001,
        );
    if (hasCurrentPlayerTrade) {
      activeTradeSide = currentPlayerTrade.side;
      activeTradePrice = playerPrint.price;
      activeTradeQuantity = playerPrint.quantity;
      activeTradeLevelSide = playerPrint.levelSide;
    }

    return Container(
      key: const Key('stock-order-book'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFE2E6EC)),
        ),
      ),
      child: Column(
        children: [
          if (materialHalt != null)
            Container(
              key: const Key('market-material-news-halt'),
              width: double.infinity,
              height: marketStatusBannerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              color: const Color(0xFFFFDDE0),
              child: Text(
                '중대공시 거래정지 · '
                '${marketTimeLabel(materialHalt.revealMinute + marketMaterialNewsHaltMinutes)} 재개',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFA52431),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          if (viActive && materialHalt == null)
            Container(
              key: const Key('market-volatility-interruption'),
              width: double.infinity,
              height: marketStatusBannerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              color: const Color(0xFFFFE8D8),
              child: const Text(
                'VI 발동 · 1분 단일가 전환 · 신규 체결 일시정지',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9A4A00),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          if (clock.phase == MarketSessionPhase.closingAuction)
            Container(
              key: const Key('closing-auction-indicative-price'),
              width: double.infinity,
              height: marketStatusBannerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              color: const Color(0xFFFFF6D8),
              child: Text(
                '장마감 동시호가 · 예상체결가 '
                '${_money(indicativeAuctionPrice.round())}원 · 15:00 단일가 체결',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF765C00),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFeatures: _marketNumberFeatures,
                ),
              ),
            ),
          _OrderBookMarketSummary(
            height: marketSummaryHeight,
            compact: compactPanel,
            definition: definition,
            quote: quote,
            state: state,
            minute: minute,
            snapshot: snapshot,
            tradeTape: tradeTape,
          ),
          Container(
            key: const Key('order-book-price-limits'),
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFFFAFBFC),
            child: Row(
              children: [
                Text(
                  '상한가 ${_money(dailyRange.upper.round())}',
                  style: const TextStyle(
                    color: Color(0xFFF04452),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFeatures: _marketNumberFeatures,
                  ),
                ),
                const Spacer(),
                Text(
                  '하한가 ${_money(dailyRange.lower.round())}',
                  style: const TextStyle(
                    color: _marketAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFeatures: _marketNumberFeatures,
                  ),
                ),
              ],
            ),
          ),
          KeyedSubtree(
            key: const Key('market-tutorial-order-book-header-source'),
            child: Container(
              key: tutorialHeaderKey,
              height: 34,
              color: const Color(0xFFF7F8FA),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Row(
                children: [
                  SizedBox(
                    width: 124,
                    child: Text(
                      '매도잔량',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Color(0xFF356FE5),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '가격',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8A919E),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 124,
                    child: Text(
                      '매수잔량',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Color(0xFFF04452),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _OrderBookPriceLadder(
            key: ValueKey(
              'order-book-price-ladder-${definition.id}-'
              '${marketLiquidityDayKey(state.currentDate)}',
            ),
            sweepPackets: sweepPackets,
            onSweepPacketsAccepted: onSweepPacketsAccepted,
            tapeCursor: tapeCursor,
            playbackSpeed: playbackSpeed,
            snapshot: snapshot,
            currentPrice: currentDisplayPrice,
            previousClose: quote.previousClose,
            availableHeight:
                availableHeight -
                fixedPanelHeight -
                (hasMarketStatusBanner ? marketStatusBannerHeight : 0),
            playerQuantityForLevel: _playerQuantity,
            playerOrderLabelForLevel: _playerOrderLabel,
            averageCostPrice: state.positions
                .where((position) => position.assetId == definition.id)
                .firstOrNull
                ?.averageCost,
            selectedPrice: selectedPrice,
            activeTradePrice: activeTradePrice,
            activeTradeSide: activeTradeSide,
            activeTradeLevelSide: activeTradeLevelSide,
            activeTradeQuantity: activeTradeQuantity,
            onTapLevel: definition.currency == 'KRW' ? onTapLevel : null,
            tutorialBestAskKey: tutorialBestAskKey,
          ),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFFFAFBFC),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '매도잔량 ${_money(displayedAskQuantity)}주',
                    style: const TextStyle(
                      color: _marketAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '매수잔량 ${_money(displayedBidQuantity)}주',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFFF04452),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showTradeTape)
            ValueListenableBuilder<_OrderBookSweepTapeCursor?>(
              valueListenable: tapeCursor,
              builder: (context, cursor, _) {
                final livePackets = sweepPacketsReader();
                final presentationCursor = _orderBookTapeCursorForLivePackets(
                  cursor,
                  livePackets,
                );
                final presentationTape =
                    livePackets.isNotEmpty && presentationCursor == null
                    ? const <_OrderBookTapePrint>[]
                    : _orderBookTradeTapeAtCursor(
                        tradeTape,
                        presentationCursor,
                      );
                return _OrderBookTradeTape(
                  height: tapeHeight,
                  compact: compactPanel,
                  prints: presentationTape,
                  currency: definition.currency,
                );
              },
            ),
          _QuoteOrderDock(
            height: orderDockHeight,
            compact: compactPanel,
            selectedPrice: selectedPrice,
            quantityPreset: quantityPreset,
            pendingOrderCount: state.pendingOrders
                .where((order) => order.assetId == definition.id)
                .length,
            onQuantityPresetChanged: onQuantityPresetChanged,
            onBuy: onBuy,
            onSell: onSell,
            onAmendCancel: onAmendCancel,
          ),
        ],
      ),
    );
  }
}

class _OrderBookMarketSummary extends StatelessWidget {
  const _OrderBookMarketSummary({
    required this.height,
    required this.compact,
    required this.definition,
    required this.quote,
    required this.state,
    required this.minute,
    required this.snapshot,
    required this.tradeTape,
  });

  final double height;
  final bool compact;
  final _StockDefinition definition;
  final _LiveStock quote;
  final GameState state;
  final int minute;
  final GameOrderBookSnapshot snapshot;
  final List<_OrderBookTapePrint> tradeTape;

  @override
  Widget build(BuildContext context) {
    final fullDayVolume = gameEstimatedFullDayVolumeUnits(
      assetId: definition.id,
      day: marketLiquidityDayKey(state.currentDate),
      referencePrice: quote.previousClose,
      simulationSeed: state.simulationSeed,
      sharesOutstanding: definition.asset.sharesOutstandingAtOrBefore(
        state.currentDate,
      ),
    );
    final cumulativeVolume =
        (fullDayVolume * gameTurnoverProgressAtMinute(minute)).round();
    final executionStrength = _tradeTapeExecutionStrength(tradeTape);
    final depthRatio = snapshot.tradeStrength;
    final bestAsk = snapshot.asks.firstOrNull?.price;
    final bestBid = snapshot.bids.firstOrNull?.price;
    final spread = bestAsk == null || bestBid == null
        ? 0
        : math.max(0, (bestAsk - bestBid).round());
    return Container(
      key: const Key('order-book-market-summary'),
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 1 : 3,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFDFE),
        border: Border(bottom: BorderSide(color: Color(0xFFE4E8EE))),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _OrderBookMetric(
                  key: const Key('order-book-open'),
                  label: '시',
                  value: _money(quote.open.round()),
                  compact: compact,
                ),
                _OrderBookMetric(
                  key: const Key('order-book-high'),
                  label: '고',
                  value: _money(quote.high.round()),
                  compact: compact,
                  valueColor: const Color(0xFFF04452),
                ),
                _OrderBookMetric(
                  key: const Key('order-book-low'),
                  label: '저',
                  value: _money(quote.low.round()),
                  compact: compact,
                  valueColor: _marketAccent,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _OrderBookMetric(
                  key: const Key('order-book-volume'),
                  label: '거래량',
                  value: _compactShareCount(cumulativeVolume),
                  compact: compact,
                ),
                _OrderBookMetric(
                  key: const Key('order-book-turnover'),
                  label: '거래대금',
                  value: _compactEok(snapshot.turnoverEok),
                  compact: compact,
                ),
                _OrderBookMetric(
                  key: const Key('order-book-trade-strength'),
                  label: '체결강도',
                  value: executionStrength.toStringAsFixed(0),
                  compact: compact,
                  valueColor: executionStrength >= 100
                      ? const Color(0xFFF04452)
                      : _marketAccent,
                ),
                _OrderBookMetric(
                  key: const Key('order-book-depth-ratio'),
                  label: '잔량비',
                  value: '${depthRatio.toStringAsFixed(0)} · 차$spread',
                  compact: compact,
                  valueColor: depthRatio >= 100
                      ? const Color(0xFFF04452)
                      : _marketAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderBookMetric extends StatelessWidget {
  const _OrderBookMetric({
    super.key,
    required this.label,
    required this.value,
    required this.compact,
    this.valueColor = _marketInk,
  });

  final String label;
  final String value;
  final bool compact;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label ',
                style: TextStyle(
                  color: _marketMuted,
                  fontSize: compact ? 8 : 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: compact ? 8 : 10,
                  fontWeight: FontWeight.w900,
                  fontFeatures: _marketNumberFeatures,
                ),
              ),
            ],
          ),
          maxLines: 1,
        ),
      ),
    ),
  );
}

class _OrderBookTradeTape extends StatelessWidget {
  const _OrderBookTradeTape({
    required this.height,
    required this.compact,
    required this.prints,
    required this.currency,
  });

  final double height;
  final bool compact;
  final List<_OrderBookTapePrint> prints;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final visible = prints.take(compact ? 1 : 3).toList(growable: false);
    return Container(
      key: const Key('order-book-trade-tape'),
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E8EE))),
      ),
      child: Column(
        children: [
          if (!compact)
            const SizedBox(
              height: 20,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '최근 체결',
                        style: TextStyle(
                          color: _marketInk,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '시간     가격       수량',
                      style: TextStyle(
                        color: _marketMuted,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: visible.isEmpty
                ? const Center(
                    child: Text(
                      '체결 대기 · 호가가 움직이면 여기에 기록됩니다',
                      key: Key('order-book-trade-tape-empty'),
                      maxLines: 1,
                      style: TextStyle(
                        color: _marketMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (final print in visible)
                        Expanded(
                          child: _OrderBookTradeTapeRow(
                            key: ValueKey('order-book-tape-${print.identity}'),
                            print: print,
                            currency: currency,
                            compact: compact,
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

class _OrderBookTradeTapeRow extends StatelessWidget {
  const _OrderBookTradeTapeRow({
    super.key,
    required this.print,
    required this.currency,
    required this.compact,
  });

  final _OrderBookTapePrint print;
  final String currency;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final change = print.price - print.previousPrice;
    final arrow = change > 0.000001
        ? '▲'
        : change < -0.000001
        ? '▼'
        : '―';
    final color = print.side == TradeSide.buy
        ? const Color(0xFFF04452)
        : _marketAccent;
    return Container(
      key: print.isPlayer ? const Key('order-book-player-tape-print') : null,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF0F2F5))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 42 : 48,
            child: Text(
              marketTimeLabel(print.marketMinute),
              style: const TextStyle(
                color: _marketMuted,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                fontFeatures: _marketNumberFeatures,
              ),
            ),
          ),
          SizedBox(
            width: 16,
            child: Text(
              arrow,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: change.abs() < 0.000001 ? _marketMuted : color,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _displayPrice(print.price, currency),
              key: const Key('order-book-tape-price'),
              textAlign: TextAlign.right,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w900,
                fontFeatures: _marketNumberFeatures,
              ),
            ),
          ),
          SizedBox(
            width: compact ? 70 : 78,
            child: Text(
              '${_money(print.quantity)}주 ${print.side == TradeSide.buy ? '매수' : '매도'}${print.isPlayer ? ' · 나' : ''}',
              key: const Key('order-book-tape-quantity-side'),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: print.isPlayer ? FontWeight.w900 : FontWeight.w700,
                fontFeatures: _marketNumberFeatures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteOrderDock extends StatelessWidget {
  const _QuoteOrderDock({
    required this.height,
    required this.compact,
    required this.selectedPrice,
    required this.quantityPreset,
    required this.pendingOrderCount,
    required this.onQuantityPresetChanged,
    required this.onBuy,
    required this.onSell,
    required this.onAmendCancel,
  });

  final double height;
  final bool compact;
  final double? selectedPrice;
  final _QuoteQuantityPreset quantityPreset;
  final int pendingOrderCount;
  final ValueChanged<_QuoteQuantityPreset> onQuantityPresetChanged;
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final VoidCallback onAmendCancel;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('quote-order-dock'),
    height: height,
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 5 : 7,
      vertical: compact ? 3 : 5,
    ),
    decoration: const BoxDecoration(
      color: Color(0xFFF7F8FA),
      border: Border(top: BorderSide(color: Color(0xFFDDE2E8))),
    ),
    child: Row(
      children: [
        _QuoteDockAction(
          key: const Key('quote-order-dock-sell'),
          label: '매도',
          color: _marketAccent,
          onTap: onSell,
          compact: compact,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Row(
            children: [
              for (final preset in _QuoteQuantityPreset.values)
                Expanded(
                  child: _QuoteQuantityChip(
                    key: ValueKey('quote-quantity-${preset.name}'),
                    preset: preset,
                    selected: quantityPreset == preset,
                    onTap: () => onQuantityPresetChanged(preset),
                    compact: compact,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('quote-order-dock-amend'),
            onTap: onAmendCancel,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              width: compact ? 38 : 44,
              height: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBBC3CE)),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                pendingOrderCount > 0 ? '정정\n$pendingOrderCount' : '정정',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF4E5968),
                  fontSize: compact ? 8 : 9,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        _QuoteDockAction(
          key: const Key('quote-order-dock-buy'),
          label: '매수',
          color: const Color(0xFFF04452),
          onTap: onBuy,
          compact: compact,
        ),
      ],
    ),
  );
}

class _QuoteDockAction extends StatelessWidget {
  const _QuoteDockAction({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(7),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: SizedBox(
        width: compact ? 46 : 54,
        height: double.infinity,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ),
  );
}

class _QuoteQuantityChip extends StatelessWidget {
  const _QuoteQuantityChip({
    super.key,
    required this.preset,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final _QuoteQuantityPreset preset;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  String get label => switch (preset) {
    _QuoteQuantityPreset.one => '1주',
    _QuoteQuantityPreset.ten => '10주',
    _QuoteQuantityPreset.quarter => '25%',
    _QuoteQuantityPreset.maximum => '최대',
  };

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF353B78) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? const Color(0xFF353B78) : const Color(0xFFD8DDE5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF5D6572),
            fontSize: compact ? 8 : 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );
}

class _OrderBookPriceLadder extends StatefulWidget {
  const _OrderBookPriceLadder({
    super.key,
    required this.snapshot,
    required this.sweepPackets,
    required this.onSweepPacketsAccepted,
    required this.tapeCursor,
    required this.playbackSpeed,
    required this.currentPrice,
    required this.previousClose,
    required this.availableHeight,
    required this.playerQuantityForLevel,
    required this.playerOrderLabelForLevel,
    required this.averageCostPrice,
    required this.selectedPrice,
    required this.activeTradePrice,
    required this.activeTradeSide,
    required this.activeTradeLevelSide,
    required this.activeTradeQuantity,
    required this.onTapLevel,
    required this.tutorialBestAskKey,
  });

  final GameOrderBookSnapshot snapshot;
  final List<_OrderBookSweepReplayPacket> sweepPackets;
  final ValueChanged<Iterable<String>> onSweepPacketsAccepted;
  final ValueNotifier<_OrderBookSweepTapeCursor?> tapeCursor;
  final ValueListenable<_MarketPlaybackSpeed> playbackSpeed;
  final double currentPrice;
  final double previousClose;
  final double availableHeight;
  final double Function(GameOrderBookLevel level) playerQuantityForLevel;
  final String? Function(GameOrderBookLevel level) playerOrderLabelForLevel;
  final double? averageCostPrice;
  final double? selectedPrice;
  final double? activeTradePrice;
  final TradeSide? activeTradeSide;
  final GameOrderBookSide? activeTradeLevelSide;
  final int activeTradeQuantity;
  final ValueChanged<GameOrderBookLevel>? onTapLevel;
  final GlobalKey? tutorialBestAskKey;

  @override
  State<_OrderBookPriceLadder> createState() => _OrderBookPriceLadderState();
}

class _OrderBookPriceLadderState extends State<_OrderBookPriceLadder>
    with _OrderBookSweepPlayback<_OrderBookPriceLadder> {
  String? _depthScaleAssetId;
  double _depthScale = 0;
  List<GameOrderBookLevel> _lastNonEmptyLevels = const <GameOrderBookLevel>[];
  final Map<(GameOrderBookSide, double), GlobalKey> _depthAnimationKeys =
      <(GameOrderBookSide, double), GlobalKey>{};
  int _tapeCursorPublishGeneration = 0;

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
  void onOrderBookSweepPlaybackChanged({bool deferUntilAfterFrame = false}) {
    final generation = ++_tapeCursorPublishGeneration;
    final batch = _activeOrderBookSweepBatch;
    final step = _activeOrderBookSweepStep;
    final cursor = batch == null || step == null
        ? null
        : _OrderBookSweepTapeCursor(
            snapshot: batch.snapshot,
            step: step,
            source: batch.source,
            identity: batch.identity,
            arrived: _activeOrderBookSweepStepArrived,
          );
    if (!deferUntilAfterFrame) {
      widget.tapeCursor.value = cursor;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _tapeCursorPublishGeneration) return;
      widget.tapeCursor.value = cursor;
    });
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
  void didUpdateWidget(covariant _OrderBookPriceLadder oldWidget) {
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
      _lastNonEmptyLevels = const <GameOrderBookLevel>[];
    }
    _syncCurrentOrderBookSweep();
  }

  @override
  void dispose() {
    _tapeCursorPublishGeneration += 1;
    widget.playbackSpeed.removeListener(_handleOrderBookPlaybackSpeedChanged);
    _disposeOrderBookSweepPlayback();
    super.dispose();
  }

  bool _matchesPrice(GameOrderBookLevel level, double? price) =>
      price != null && (level.price - price).abs() < 0.000001;

  int _stableDepthScale(int observed) {
    final assetId = widget.snapshot.sourceAssetId;
    final safeObserved = math.max(1, observed);
    if (_depthScaleAssetId != assetId || _depthScale <= 0) {
      _depthScaleAssetId = assetId;
      _depthScale = safeObserved.toDouble();
    } else if (safeObserved > _depthScale * 1.25) {
      _depthScale = safeObserved.toDouble();
    } else if (safeObserved < _depthScale * 0.55) {
      _depthScale = math.max(safeObserved.toDouble(), _depthScale * 0.92);
    }
    return math.max(1, _depthScale.round());
  }

  @override
  Widget build(BuildContext context) {
    final activeSweepStep = _activeOrderBookSweepStep;
    final snapshot = _orderBookSweepPresentationSnapshot(widget.snapshot);
    final candidateLevels = _orderBookSweepPresentationLevels(widget.snapshot);
    if (candidateLevels.isNotEmpty) {
      _lastNonEmptyLevels = List<GameOrderBookLevel>.unmodifiable(
        candidateLevels,
      );
    }
    final levels = candidateLevels.isEmpty
        ? _lastNonEmptyLevels
        : candidateLevels;
    final pausedTrade = _orderBookSweepPlaybackPaused
        ? snapshot.lastSyntheticTrade
        : null;
    final effectiveActiveTradePrice =
        activeSweepStep?.price ??
        (_orderBookSweepPlaybackPaused
            ? pausedTrade?.price ?? snapshot.sourceLastTradePrice
            : widget.activeTradePrice);
    final effectiveActiveTradeSide = activeSweepStep == null
        ? _orderBookSweepPlaybackPaused
              ? pausedTrade == null
                    ? null
                    : pausedTrade.levelSide == GameOrderBookSide.ask
                    ? TradeSide.buy
                    : TradeSide.sell
              : widget.activeTradeSide
        : activeSweepStep.side == GameOrderBookSide.ask
        ? TradeSide.buy
        : TradeSide.sell;
    final effectiveActiveTradeLevelSide =
        activeSweepStep?.side ??
        (_orderBookSweepPlaybackPaused
            ? pausedTrade?.levelSide
            : widget.activeTradeLevelSide);
    final effectiveActiveTradeQuantity = activeSweepStep == null
        ? _orderBookSweepPlaybackPaused
              ? 0
              : widget.activeTradeQuantity
        : _activeOrderBookSweepStepArrived
        ? activeSweepStep.consumedQuantity
        : 0;
    final visibleLevels = levels
        .map((level) => (level.side, level.price))
        .toSet();
    _depthAnimationKeys.removeWhere(
      (identity, _) => !visibleLevels.contains(identity),
    );
    final observedMaxDepth = levels.fold<int>(
      1,
      (maximum, level) => math.max(
        maximum,
        level.quantity + widget.playerQuantityForLevel(level).ceil(),
      ),
    );
    final maxVisibleDepth = _stableDepthScale(observedMaxDepth);
    final rowHeight = levels.isEmpty
        ? 39.0
        : (widget.availableHeight / levels.length).clamp(11.5, 42.0).toDouble();
    final requestedOutlinePrice =
        effectiveActiveTradePrice ??
        levels
            .where((level) => _matchesPrice(level, widget.currentPrice))
            .firstOrNull
            ?.price ??
        snapshot.bids.firstOrNull?.price;
    final bestAskLevel = levels
        .where((level) => level.side == GameOrderBookSide.ask)
        .lastOrNull;
    final bestBidLevel = levels
        .where((level) => level.side == GameOrderBookSide.bid)
        .firstOrNull;
    final requestedOutlineLevel = levels
        .where(
          (level) =>
              _matchesPrice(level, requestedOutlinePrice) &&
              (effectiveActiveTradeLevelSide == null ||
                  level.side == effectiveActiveTradeLevelSide),
        )
        .firstOrNull;
    final requestedOutlineIsAtTouch =
        requestedOutlineLevel != null &&
        (identical(requestedOutlineLevel, bestAskLevel) ||
            identical(requestedOutlineLevel, bestBidLevel));
    final outlineLevel = activeSweepStep != null || requestedOutlineIsAtTouch
        ? requestedOutlineLevel
        : effectiveActiveTradeLevelSide == GameOrderBookSide.ask
        ? bestAskLevel
        : effectiveActiveTradeLevelSide == GameOrderBookSide.bid
        ? bestBidLevel
        : requestedOutlinePrice != null &&
              bestAskLevel != null &&
              requestedOutlinePrice >= bestAskLevel.price
        ? bestAskLevel
        : bestBidLevel ?? bestAskLevel;
    final outlinePrice = outlineLevel?.price;
    final outlineLevelSide = outlineLevel?.side;
    final currentRowIndex = outlineLevel == null
        ? -1
        : levels.indexOf(outlineLevel);
    final fallbackTradeUsesOutline =
        activeSweepStep == null &&
        effectiveActiveTradePrice != null &&
        outlineLevel != null &&
        _matchesPrice(outlineLevel, effectiveActiveTradePrice) &&
        (effectiveActiveTradeLevelSide == null ||
            outlineLevelSide == effectiveActiveTradeLevelSide);
    final sweepRowIndex = activeSweepStep == null
        ? -1
        : levels.indexWhere(
            (level) =>
                level.side == activeSweepStep.side &&
                _matchesPrice(level, activeSweepStep.price),
          );
    final presentationAsks = levels
        .where((level) => level.side == GameOrderBookSide.ask)
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    final presentationBids = levels
        .where((level) => level.side == GameOrderBookSide.bid)
        .toList(growable: false);
    final askIndexByPrice = <double, int>{
      for (final entry in presentationAsks.asMap().entries)
        entry.value.price: entry.key,
    };
    final bidIndexByPrice = <double, int>{
      for (final entry in presentationBids.asMap().entries)
        entry.value.price: entry.key,
    };
    return TickerMode(
      enabled: !_orderBookSweepPlaybackPaused,
      child: SizedBox(
        height: rowHeight * levels.length,
        child: Stack(
          key: const Key('order-book-ladder-stack'),
          clipBehavior: Clip.hardEdge,
          children: [
            Column(
              children: [
                for (final entry in levels.asMap().entries)
                  SizedBox(
                    key: ValueKey((
                      'order-book-price',
                      entry.value.side.name,
                      entry.value.price,
                    )),
                    height: rowHeight,
                    child: Builder(
                      builder: (context) {
                        final level = entry.value;
                        final isAsk = level.side == GameOrderBookSide.ask;
                        final levelIndex =
                            (isAsk
                                ? askIndexByPrice[level.price]
                                : bidIndexByPrice[level.price]) ??
                            0;
                        final isBestAsk =
                            isAsk &&
                            _matchesPrice(
                              level,
                              widget.snapshot.asks.firstOrNull?.price,
                            );
                        Widget row = _OrderBookLevelRow(
                          key: Key(
                            'order-book-${isAsk ? 'ask' : 'bid'}-$levelIndex',
                          ),
                          level: level,
                          depthAnimationDuration:
                              activeSweepStep != null &&
                                  _activeOrderBookSweepStepArrived &&
                                  level.side == activeSweepStep.side &&
                                  _matchesPrice(level, activeSweepStep.price)
                              ? _orderBookSweepStepDuration
                              : _orderBookMotionDuration,
                          previousClose: widget.previousClose,
                          rowHeight: rowHeight,
                          maxDepth: maxVisibleDepth,
                          depthAnimationKey: _depthAnimationKeys.putIfAbsent(
                            (level.side, level.price),
                            () => GlobalKey(
                              debugLabel:
                                  'order-book-depth-${level.side.name}-${level.price}',
                            ),
                          ),
                          playerQuantity: widget.playerQuantityForLevel(level),
                          playerOrderLabel: widget.playerOrderLabelForLevel(
                            level,
                          ),
                          isAverageCost: _matchesPrice(
                            level,
                            widget.averageCostPrice == null
                                ? null
                                : marketSnapPrice(
                                    widget.averageCostPrice!,
                                    market:
                                        widget.snapshot.sourceMarket ?? '미래시장',
                                  ),
                          ),
                          isSelected: _matchesPrice(
                            level,
                            widget.selectedPrice,
                          ),
                          isActive:
                              (!_orderBookSweepPlaybackPaused ||
                                  activeSweepStep != null) &&
                              (activeSweepStep == null
                                  ? _activeOrderBookSweepBatch == null &&
                                        fallbackTradeUsesOutline
                                  : _activeOrderBookSweepStepArrived) &&
                              _matchesPrice(level, outlinePrice) &&
                              (outlineLevelSide == null ||
                                  level.side == outlineLevelSide),
                          isTradeDrain:
                              activeSweepStep != null &&
                              _activeOrderBookSweepStepArrived &&
                              level.side == activeSweepStep.side &&
                              _matchesPrice(level, activeSweepStep.price),
                          activeTradeSide: effectiveActiveTradeSide,
                          activeQuantity: effectiveActiveTradeQuantity,
                          onTap: widget.onTapLevel == null
                              ? null
                              : () => widget.onTapLevel!(level),
                        );
                        if (entry.key == currentRowIndex) {
                          row = KeyedSubtree(
                            key: const Key('order-book-current-price'),
                            child: row,
                          );
                        }
                        if (isBestAsk) {
                          row = KeyedSubtree(
                            key: const Key('order-book-best-ask'),
                            child: row,
                          );
                        }
                        if (!isBestAsk || widget.tutorialBestAskKey == null) {
                          return row;
                        }
                        return RepaintBoundary(
                          key: widget.tutorialBestAskKey,
                          child: row,
                        );
                      },
                    ),
                  ),
              ],
            ),
            if (activeSweepStep != null)
              Offstage(
                child: SizedBox(
                  key: ValueKey((
                    'order-book-sweep-active',
                    _activeOrderBookSweepBatch?.identity,
                    activeSweepStep.sequence,
                    _orderBookSweepPhase.name,
                    'full',
                  )),
                ),
              ),
            if (sweepRowIndex >= 0 &&
                activeSweepStep != null &&
                _activeOrderBookSweepStepArrived)
              Positioned(
                key: const Key('order-book-sweep-position'),
                top: sweepRowIndex * rowHeight,
                left: 0,
                right: 0,
                height: rowHeight,
                child: _OrderBookSweepRowOverlay(
                  step: activeSweepStep,
                  stepDuration: _orderBookSweepStepDuration,
                  stepNumber: _activeOrderBookSweepStepNumber,
                  stepCount: _activeOrderBookSweepStepCount,
                  maxDepth: maxVisibleDepth,
                ),
              ),
            if (currentRowIndex >= 0)
              AnimatedPositioned(
                key: const Key('order-book-current-price-border'),
                duration: activeSweepStep == null
                    ? _orderBookMotionDuration
                    : _orderBookSweepMotionDuration,
                curve: Curves.easeOutCubic,
                top: currentRowIndex * rowHeight,
                left: 132,
                right: 132,
                height: rowHeight,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFF04452),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderBookLevelRow extends StatelessWidget {
  const _OrderBookLevelRow({
    super.key,
    required this.level,
    required this.depthAnimationDuration,
    required this.previousClose,
    required this.rowHeight,
    required this.maxDepth,
    required this.depthAnimationKey,
    required this.playerQuantity,
    required this.playerOrderLabel,
    required this.isAverageCost,
    required this.isSelected,
    required this.isActive,
    required this.isTradeDrain,
    required this.activeTradeSide,
    required this.activeQuantity,
    required this.onTap,
  });

  final GameOrderBookLevel level;
  final Duration depthAnimationDuration;
  final double previousClose;
  final double rowHeight;
  final int maxDepth;
  final GlobalKey depthAnimationKey;
  final double playerQuantity;
  final String? playerOrderLabel;
  final bool isAverageCost;
  final bool isSelected;
  final bool isActive;
  final bool isTradeDrain;
  final TradeSide? activeTradeSide;
  final int activeQuantity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isAsk = level.side == GameOrderBookSide.ask;
    final levelColor = isAsk ? _marketAccent : const Color(0xFFF04452);
    final tradeColor = activeTradeSide == TradeSide.buy
        ? const Color(0xFFF04452)
        : _marketAccent;
    final tint = isAsk ? const Color(0xFFEAF3FF) : const Color(0xFFFFEEF3);
    final barColor = isAsk ? const Color(0x998DB8F3) : const Color(0x99EF9AB7);
    final totalQuantity = level.quantity + playerQuantity.ceil();
    final depth = (totalQuantity / math.max(1, maxDepth)).clamp(0.0, 1.0);
    final showSecondary = rowHeight >= 26;
    return Container(
      key: isActive ? const Key('order-book-active-trade-row') : null,
      decoration: const BoxDecoration(color: Colors.white),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: rowHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 124,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isAsk
                          ? tint.withValues(alpha: 0.20)
                          : Colors.white,
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFFE9EDF2)),
                      ),
                    ),
                    child: isAsk
                        ? _OrderBookQuantityCell(
                            key: ValueKey((
                              'order-book-quantity',
                              level.side.name,
                              level.price,
                            )),
                            isAsk: true,
                            quantity: totalQuantity,
                            depth: depth,
                            animationKey: depthAnimationKey,
                            animationDuration: depthAnimationDuration,
                            isActive: isActive,
                            isTradeDrain: isTradeDrain,
                            activeQuantity: activeQuantity,
                            activeTradeSide: activeTradeSide,
                            playerQuantity: playerQuantity,
                            playerOrderLabel: playerOrderLabel,
                            showSecondary: showSecondary,
                            tradeColor: tradeColor,
                            barColor: barColor,
                          )
                        : null,
                  ),
                  Expanded(
                    child: Container(
                      key: const ValueKey('order-book-price-surface'),
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFF2B8)
                            : tint.withValues(alpha: 0.72),
                        border: Border(
                          bottom: const BorderSide(color: Color(0xFFE9EDF2)),
                          left: isSelected
                              ? const BorderSide(
                                  color: Color(0xFFE0A900),
                                  width: 2,
                                )
                              : BorderSide.none,
                          right: isSelected
                              ? const BorderSide(
                                  color: Color(0xFFE0A900),
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${_money(level.price.round())}원',
                                      key: const ValueKey(
                                        'order-book-price-label',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: levelColor,
                                        fontSize: rowHeight < 15
                                            ? 10
                                            : (rowHeight < 26 ? 13 : 16),
                                        fontWeight: FontWeight.w900,
                                        fontFeatures: _marketNumberFeatures,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _orderBookPriceRateLabel(
                                        level.price,
                                        previousClose,
                                      ),
                                      key: const Key('order-book-price-rate'),
                                      style: TextStyle(
                                        color: _orderBookPriceRateColor(
                                          level.price,
                                          previousClose,
                                        ),
                                        fontSize: rowHeight < 15 ? 6 : 8,
                                        fontWeight: FontWeight.w800,
                                        fontFeatures: _marketNumberFeatures,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (isAverageCost)
                            Positioned(
                              key: const Key('order-book-average-cost-marker'),
                              left: 3,
                              top: 2,
                              child: Text(
                                showSecondary ? '●평단' : '●',
                                style: TextStyle(
                                  color: const Color(0xFF9A7100),
                                  fontSize: showSecondary ? 7 : 6,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          if (isSelected)
                            const Positioned(
                              right: 3,
                              top: 2,
                              child: Text(
                                '선택',
                                key: Key('order-book-selected-price-marker'),
                                style: TextStyle(
                                  color: Color(0xFF8A6500),
                                  fontSize: 6,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 124,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isAsk
                          ? Colors.white
                          : tint.withValues(alpha: 0.20),
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFFE9EDF2)),
                      ),
                    ),
                    child: isAsk
                        ? null
                        : _OrderBookQuantityCell(
                            key: ValueKey((
                              'order-book-quantity',
                              level.side.name,
                              level.price,
                            )),
                            isAsk: false,
                            quantity: totalQuantity,
                            depth: depth,
                            animationKey: depthAnimationKey,
                            animationDuration: depthAnimationDuration,
                            isActive: isActive,
                            isTradeDrain: isTradeDrain,
                            activeQuantity: activeQuantity,
                            activeTradeSide: activeTradeSide,
                            playerQuantity: playerQuantity,
                            playerOrderLabel: playerOrderLabel,
                            showSecondary: showSecondary,
                            tradeColor: tradeColor,
                            barColor: barColor,
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
}

class _OrderBookQuantityCell extends StatefulWidget {
  const _OrderBookQuantityCell({
    super.key,
    required this.isAsk,
    required this.quantity,
    required this.depth,
    required this.animationKey,
    required this.animationDuration,
    required this.isActive,
    required this.isTradeDrain,
    required this.activeQuantity,
    required this.activeTradeSide,
    required this.playerQuantity,
    required this.playerOrderLabel,
    required this.showSecondary,
    required this.tradeColor,
    required this.barColor,
  });

  final bool isAsk;
  final int quantity;
  final double depth;
  final GlobalKey animationKey;
  final Duration animationDuration;
  final bool isActive;
  final bool isTradeDrain;
  final int activeQuantity;
  final TradeSide? activeTradeSide;
  final double playerQuantity;
  final String? playerOrderLabel;
  final bool showSecondary;
  final Color tradeColor;
  final Color barColor;

  @override
  State<_OrderBookQuantityCell> createState() => _OrderBookQuantityCellState();
}

class _OrderBookQuantityCellState extends State<_OrderBookQuantityCell> {
  int _quantityDelta = 0;
  bool _quantityDeltaIsTrade = false;
  Timer? _deltaTimer;

  @override
  void didUpdateWidget(covariant _OrderBookQuantityCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final delta = widget.quantity - oldWidget.quantity;
    if (delta == 0) return;
    _quantityDelta = delta;
    _quantityDeltaIsTrade = delta < 0 && widget.isTradeDrain;
    _deltaTimer?.cancel();
    _deltaTimer = Timer(const Duration(milliseconds: 520), () {
      if (mounted) {
        setState(() {
          _quantityDelta = 0;
          _quantityDeltaIsTrade = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _deltaTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    key: ValueKey(
      widget.isAsk
          ? 'order-book-sell-quantity-cell'
          : 'order-book-buy-quantity-cell',
    ),
    fit: StackFit.expand,
    children: [
      Align(
        alignment: widget.isAsk ? Alignment.centerRight : Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          key: widget.animationKey,
          duration: widget.animationDuration,
          curve: Curves.easeOutCubic,
          // A newly visible side-and-price queue starts at its real depth.
          // Existing same-side prices keep keyed state while an ask that turns
          // into a bid receives a fresh identity and cannot borrow the old wall.
          tween: Tween<double>(begin: widget.depth, end: widget.depth),
          builder: (context, animatedDepth, child) => FractionallySizedBox(
            key: ValueKey(
              widget.isAsk
                  ? 'order-book-sell-depth-bar'
                  : 'order-book-buy-depth-bar',
            ),
            widthFactor: animatedDepth,
            heightFactor: 1,
            child: child,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.barColor,
              borderRadius: BorderRadius.horizontal(
                left: widget.isAsk ? const Radius.circular(6) : Radius.zero,
                right: widget.isAsk ? Radius.zero : const Radius.circular(6),
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(
          left: widget.isAsk ? 4 : 7,
          right: widget.isAsk ? 7 : 4,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: widget.isAsk
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _money(widget.quantity),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF2C3440),
                      fontSize: widget.showSecondary ? 13 : 10,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      fontFeatures: _marketNumberFeatures,
                    ),
                  ),
                ),
                if (_quantityDelta != 0 &&
                    orderBookQuantityDeltaLabel(
                      _quantityDelta,
                      isTrade: _quantityDeltaIsTrade,
                    ).isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Text(
                    orderBookQuantityDeltaLabel(
                      _quantityDelta,
                      isTrade: _quantityDeltaIsTrade,
                    ),
                    key: const Key('order-book-quantity-delta'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _quantityDelta < 0 && !_quantityDeltaIsTrade
                          ? const Color(0xFF7B5A00)
                          : _quantityDelta > 0
                          ? const Color(0xFF16794E)
                          : const Color(0xFFB42332),
                      fontSize: 7,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      fontFeatures: _marketNumberFeatures,
                    ),
                  ),
                ],
              ],
            ),
            if (widget.showSecondary &&
                widget.isActive &&
                widget.activeQuantity > 0)
              Text(
                '${widget.activeTradeSide == TradeSide.buy ? '매수' : '매도'} '
                '체결 ${_money(widget.activeQuantity)}주',
                key: const Key('order-book-active-trade'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.tradeColor,
                  fontSize: 9,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              )
            else if (widget.showSecondary &&
                widget.playerQuantity > 0 &&
                widget.playerOrderLabel != null)
              Text(
                widget.playerOrderLabel!,
                key: const Key('order-book-player-order-marker'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7A5A00),
                  fontSize: 8,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class _OrderSheet extends StatefulWidget {
  const _OrderSheet({
    super.key,
    required this.definition,
    required this.live,
    required this.isBuy,
    required this.state,
    required this.minute,
    required this.onExecuteTrade,
    this.marketSnapshotReader,
    this.liquidityPulse = 0,
    this.liquidityPulseListenable,
    this.initialOrderType,
    this.initialLimitPrice,
    this.initialQuantity,
    this.balanceLabel,
    this.submitLabel,
    this.successLabel = '완료',
    this.onSuccessContinue,
    this.onSelectedLimitPriceChanged,
    this.forceActionHighlight = false,
    this.compact = false,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final bool isBuy;
  final GameState state;
  final ValueNotifier<int> minute;
  final Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade;
  final ValueGetter<GameOrderBookSnapshot>? marketSnapshotReader;
  final int liquidityPulse;
  final ValueListenable<int>? liquidityPulseListenable;
  final TradeOrderType? initialOrderType;
  final double? initialLimitPrice;
  final double? initialQuantity;
  final String? balanceLabel;
  final String? submitLabel;
  final String successLabel;
  final VoidCallback? onSuccessContinue;
  final ValueChanged<double?>? onSelectedLimitPriceChanged;
  final bool forceActionHighlight;
  final bool compact;

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetMarketView {
  const _OrderSheetMarketView({
    required this.snapshot,
    required this.availableCapacity,
    required this.maximumNotional,
  });

  final GameOrderBookSnapshot snapshot;
  final int availableCapacity;
  final int? maximumNotional;
}

class _OrderSheetState extends State<_OrderSheet> {
  static const _tradeSaveFailureMessage =
      '주문을 저장하지 못했어요. 저장 공간을 확인하고 다시 시도해 주세요.';

  double _quantity = 1;
  late TradeOrderType _orderType;
  double? _limitPrice;
  bool _submitting = false;
  TradeExecutionResult? _result;
  List<MarketTechnicalLevel> _technicalLevels = const <MarketTechnicalLevel>[];
  String _technicalLevelsDate = '';
  double _technicalLevelsReference = 0;
  GameState? _marketViewStateKey;
  int _marketViewMinuteKey = -1;
  int _marketViewPulseKey = -1;
  double _marketViewPriceKey = double.nan;
  int _marketViewHistoryLengthKey = -1;
  double _marketViewPreviousTradeKey = double.nan;
  _OrderSheetMarketView? _cachedMarketView;
  _OrderSheetMarketView? _fillPlanViewKey;
  TradeOrderType? _fillPlanTypeKey;
  double _fillPlanQuantityKey = double.nan;
  GameOrderBookFillPlan? _cachedMarketFillPlan;
  bool _hasCachedMarketFillPlan = false;
  _OrderSheetMarketView? _maxQuantityViewKey;
  TradeOrderType? _maxQuantityTypeKey;
  double _maxQuantityPriceKey = double.nan;
  double? _cachedMaxQuantity;

  @override
  void initState() {
    super.initState();
    widget.live.addListener(_handleMarketUpdate);
    widget.minute.addListener(_handleMarketUpdate);
    _quantity = widget.initialQuantity ?? 1;
    _refreshTechnicalLevels();
    _orderType = widget.initialOrderType ?? TradeOrderType.market;
    _limitPrice = marketSnapPrice(
      widget.initialLimitPrice ?? widget.live.value.price,
      market: widget.definition.market,
    );
    if (!widget.isBuy && (_position?.units ?? 0) < 1) {
      _quantity = _position?.units ?? 1;
    }
  }

  @override
  void didUpdateWidget(covariant _OrderSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshTechnicalLevels();
  }

  @override
  void dispose() {
    widget.live.removeListener(_handleMarketUpdate);
    widget.minute.removeListener(_handleMarketUpdate);
    super.dispose();
  }

  void _handleMarketUpdate() {
    if (mounted) {
      setState(_refreshTechnicalLevels);
    }
  }

  void _refreshTechnicalLevels() {
    final quote = widget.live.value;
    final dateKey = marketDateKey(widget.state.currentDate);
    if (_technicalLevelsDate == dateKey &&
        (_technicalLevelsReference - quote.previousClose).abs() < 0.000001) {
      return;
    }
    _technicalLevels = marketTechnicalLevelsForAsset(
      asset: widget.definition.asset,
      sessionDate: widget.state.currentDate,
      referencePrice: quote.previousClose,
    );
    _technicalLevelsDate = dateKey;
    _technicalLevelsReference = quote.previousClose;
  }

  PortfolioPosition? get _position {
    for (final position in widget.state.positions) {
      if (position.assetId == widget.definition.id) return position;
    }
    return null;
  }

  _LiveStock get _quote => widget.live.value;
  int get _marketMinute => widget.minute.value;
  double get _executionPrice => _quote.price;
  _OrderSheetMarketView get _marketView {
    final quote = _quote;
    final marketMinute = _marketMinute;
    final liquidityPulse = _liquidityPulse;
    final previousTradePrice = quote.sessionHistory.length >= 2
        ? quote.sessionHistory[quote.sessionHistory.length - 2]
        : quote.previousClose;
    if (identical(_marketViewStateKey, widget.state) &&
        _marketViewMinuteKey == marketMinute &&
        _marketViewPulseKey == liquidityPulse &&
        (_marketViewPriceKey - quote.price).abs() < 0.000001 &&
        _marketViewHistoryLengthKey == quote.sessionHistory.length &&
        (_marketViewPreviousTradeKey - previousTradePrice).abs() < 0.000001 &&
        _cachedMarketView != null) {
      return _cachedMarketView!;
    }
    final provided = widget.marketSnapshotReader?.call();
    final snapshot =
        provided ??
        _fallbackMarketSnapshot(
          quote: quote,
          previousTradePrice: previousTradePrice,
          marketMinute: marketMinute,
          liquidityPulse: liquidityPulse,
        );
    final consumedCapacity = snapshot.appliedCapacityConsumptionUnits > 0
        ? snapshot.appliedCapacityConsumptionUnits
        : gameConsumedOrderBookFillUnits(
            widget.state,
            assetId: widget.definition.id,
            marketMinute: marketMinute,
            side: widget.isBuy ? TradeSide.buy : TradeSide.sell,
          );
    final maximumNotional = !widget.isBuy
        ? null
        : gameBuyNotionalBudget(
            widget.state,
            maximumNotional: math.min(
              gameMarketOrderNotionalLimit(
                quote.price,
                turnoverEok: snapshot.turnoverEok,
              ),
              gameOrderAuthorityLimit(widget.state),
            ),
          );
    final view = _OrderSheetMarketView(
      snapshot: snapshot,
      availableCapacity: math.max(
        0,
        snapshot.executionCapacity - consumedCapacity,
      ),
      maximumNotional: maximumNotional,
    );
    _marketViewStateKey = widget.state;
    _marketViewMinuteKey = marketMinute;
    _marketViewPulseKey = liquidityPulse;
    _marketViewPriceKey = quote.price;
    _marketViewHistoryLengthKey = quote.sessionHistory.length;
    _marketViewPreviousTradeKey = previousTradePrice;
    _cachedMarketView = view;
    return view;
  }

  GameOrderBookSnapshot _fallbackMarketSnapshot({
    required _LiveStock quote,
    required double previousTradePrice,
    required int marketMinute,
    required int liquidityPulse,
  }) {
    final rawSnapshot = buildGameOrderBookSnapshot(
      assetId: widget.definition.id,
      day: marketLiquidityDayKey(widget.state.currentDate),
      minute: marketMinute,
      currentPrice: quote.price,
      previousClose: quote.previousClose,
      previousTradePrice: previousTradePrice,
      sessionLow: quote.low,
      sessionHigh: quote.high,
      date: widget.state.currentDate,
      market: widget.definition.market,
      simulationSeed: widget.state.simulationSeed,
      tradingDay: quote.isTradingDay,
      sharesOutstanding: _maximumPositionUnits,
      isIpoFirstTradingDay: widget.definition.asset.isIpoFirstTradingDay(
        widget.state.currentDate,
      ),
      technicalLevels: _technicalLevels,
      liquidityPulse: liquidityPulse,
      adaptiveLiquidityPulses: liquidityPulse > 0,
    );
    final consumedCapacityUnits = gameConsumedOrderBookFillUnits(
      widget.state,
      assetId: widget.definition.id,
      marketMinute: marketMinute,
      side: widget.isBuy ? TradeSide.buy : TradeSide.sell,
    );
    return gameOrderBookSnapshotAfterConsumption(
      snapshot: rawSnapshot,
      consumedAskByPrice: gameConsumedOrderBookUnitsByPrice(
        widget.state,
        assetId: widget.definition.id,
        marketMinute: marketMinute,
        bookSide: GameOrderBookSide.ask,
      ),
      consumedBidByPrice: gameConsumedOrderBookUnitsByPrice(
        widget.state,
        assetId: widget.definition.id,
        marketMinute: marketMinute,
        bookSide: GameOrderBookSide.bid,
      ),
      consumedCapacityUnits: consumedCapacityUnits,
      retainSyntheticTombstone: false,
    );
  }

  GameOrderBookSnapshot get _marketSnapshot => _marketView.snapshot;

  int get _liquidityPulse =>
      widget.liquidityPulseListenable?.value ?? widget.liquidityPulse;

  GameOrderBookFillPlan? get _marketFillPlan {
    final view = _marketView;
    if (identical(_fillPlanViewKey, view) &&
        _fillPlanTypeKey == _orderType &&
        _fillPlanQuantityKey == _quantity &&
        _hasCachedMarketFillPlan) {
      return _cachedMarketFillPlan;
    }
    GameOrderBookFillPlan? plan;
    if (_orderType != TradeOrderType.market ||
        _quantity <= 0 ||
        _quantity != _quantity.roundToDouble()) {
      plan = null;
    } else {
      final range = _dailyRange;
      plan = gameOrderBookLimitFillPlan(
        snapshot: view.snapshot,
        isBuy: widget.isBuy,
        requestedQuantity: _quantity,
        limitPrice: widget.isBuy ? range.upper : range.lower,
        availableCapacity: view.availableCapacity,
        maximumNotional: view.maximumNotional,
      );
    }
    _fillPlanViewKey = view;
    _fillPlanTypeKey = _orderType;
    _fillPlanQuantityKey = _quantity;
    _cachedMarketFillPlan = plan;
    _hasCachedMarketFillPlan = true;
    return plan;
  }

  double get _estimatedExecutionPrice {
    if (_orderType != TradeOrderType.market) {
      return _limitPrice ?? _executionPrice;
    }
    final plan = _marketFillPlan;
    if (plan != null && plan.hasFill) return plan.averagePrice;
    final levels = widget.isBuy ? _marketSnapshot.asks : _marketSnapshot.bids;
    return levels.isEmpty ? _executionPrice : levels.first.price;
  }

  double get _orderPrice => _orderType == TradeOrderType.limit
      ? (_limitPrice ?? _executionPrice)
      : _executionPrice;
  int get _rawNotional => (_orderPrice * _quantity).round();
  int get _notional {
    if (_orderType != TradeOrderType.market) return _rawNotional;
    final plan = _marketFillPlan;
    if (plan != null) return plan.notional;
    return (_estimatedExecutionPrice * _quantity).round();
  }

  String get _notionalLabel {
    final plan = _marketFillPlan;
    if (_orderType == TradeOrderType.market && plan != null) {
      return '시장가 IOC 예상 ${plan.filledQuantity}/${_quantity.round()}주';
    }
    return '주문 금액';
  }

  int get _fee => gameTradingFeeForState(widget.state, _notional);
  double get _feeRate => gameTradingFeeRateForState(widget.state);
  int get _transactionTax => widget.isBuy
      ? 0
      : gameSecuritiesTransactionTax(widget.state.currentDate, _notional);
  int get _settlement =>
      widget.isBuy ? _notional + _fee : _notional - _fee - _transactionTax;
  int? get _maximumPositionUnits => widget.definition.asset
      .sharesOutstandingAtOrBefore(widget.state.currentDate);

  double get _ownershipAvailableUnits {
    final maximum = _maximumPositionUnits;
    if (maximum == null || maximum <= 0) return double.infinity;
    final owned = _position?.units ?? 0;
    final reserved = widget.state.pendingBuyReservedUnits(widget.definition.id);
    return math.max(0, maximum - owned - reserved).toDouble();
  }

  double get _maxQuantity {
    final view = _marketView;
    if (identical(_maxQuantityViewKey, view) &&
        _maxQuantityTypeKey == _orderType &&
        _maxQuantityPriceKey == _orderPrice &&
        _cachedMaxQuantity != null) {
      return _cachedMaxQuantity!;
    }
    late final double result;
    if (!widget.isBuy) {
      final held = math.max(
        0.0,
        (_position?.units ?? 0) -
            widget.state.pendingSellReservedUnits(widget.definition.id),
      );
      if (_executionPrice <= 0) {
        result = 0;
      } else {
        final liquidUnits =
            gameMarketOrderNotionalLimit(
              _orderPrice,
              turnoverEok: view.snapshot.turnoverEok,
            ) /
            _orderPrice;
        result = math.min(
          math.min(held, liquidUnits),
          _orderType == TradeOrderType.market
              ? view.availableCapacity.toDouble()
              : double.infinity,
        );
      }
    } else {
      final cashQuantity = gameMaxBuyQuantity(
        widget.state,
        _orderPrice,
        market: widget.definition.market,
      ).toDouble();
      final positionLimitedQuantity = math.min(
        cashQuantity,
        _ownershipAvailableUnits,
      );
      if (_orderType != TradeOrderType.market) {
        result = positionLimitedQuantity;
      } else {
        final range = _dailyRange;
        final capacityPlan = gameOrderBookLimitFillPlan(
          snapshot: view.snapshot,
          isBuy: true,
          requestedQuantity: view.availableCapacity.toDouble(),
          limitPrice: range.upper,
          availableCapacity: view.availableCapacity,
          maximumNotional: view.maximumNotional,
        );
        result = math.min(
          capacityPlan.filledQuantity.toDouble(),
          positionLimitedQuantity,
        );
      }
    }
    _maxQuantityViewKey = view;
    _maxQuantityTypeKey = _orderType;
    _maxQuantityPriceKey = _orderPrice;
    _cachedMaxQuantity = result;
    return result;
  }

  ({double lower, double upper}) get _dailyRange => marketDailyPriceRange(
    previousClose: _quote.previousClose,
    date: widget.state.currentDate,
    market: widget.definition.market,
    isIpoFirstTradingDay: widget.definition.asset.isIpoFirstTradingDay(
      widget.state.currentDate,
    ),
  );

  bool get _validLimitPrice =>
      _orderType == TradeOrderType.market ||
      (_limitPrice != null &&
          isValidMarketOrderPrice(
            _limitPrice!,
            market: widget.definition.market,
          ) &&
          _limitPrice! >= _dailyRange.lower &&
          _limitPrice! <= _dailyRange.upper);

  void _changeLimitPrice(int direction) {
    final current = _limitPrice ?? _executionPrice;
    final tick = marketTickSize(current, market: widget.definition.market);
    setState(() {
      _limitPrice = marketSnapPrice(
        (current + tick * direction).clamp(
          _dailyRange.lower,
          _dailyRange.upper,
        ),
        market: widget.definition.market,
      );
      _result = null;
    });
    widget.onSelectedLimitPriceChanged?.call(_limitPrice);
  }

  bool get _tradable {
    final tradingDay =
        _quote.isTradingDay && isMarketTradingDay(widget.state.currentDate);
    return marketClockAt(_marketMinute, tradingDay: tradingDay).tradable;
  }

  bool get _authorityReady =>
      !widget.isBuy || widget.state.story.accountAuthorityLevel > 0;

  Future<void> _submit() async {
    if (_submitting || _result?.success == true) return;
    setState(() {
      _submitting = true;
      _result = null;
    });
    late TradeExecutionResult result;
    try {
      final displayedSnapshot = _marketSnapshot;
      result = await widget.onExecuteTrade(
        TradeOrder(
          side: widget.isBuy ? TradeSide.buy : TradeSide.sell,
          assetId: widget.definition.id,
          symbol: widget.definition.code,
          name: widget.definition.name,
          market: widget.definition.market,
          currency: widget.definition.currency,
          quantity: _quantity,
          unitPrice: _executionPrice,
          quoteDate: widget.state.currentDate
              .toIso8601String()
              .split('T')
              .first,
          marketMinute: _marketMinute,
          isTradingDay: _quote.isTradingDay,
          type: _orderType,
          limitPrice: _orderType == TradeOrderType.limit ? _limitPrice : null,
          previousClose: _quote.previousClose,
          previousTradePrice: _quote.sessionHistory.length >= 2
              ? _quote.sessionHistory[_quote.sessionHistory.length - 2]
              : _quote.previousClose,
          sessionLow: _quote.low,
          sessionHigh: _quote.high,
          maximumPositionUnits: _maximumPositionUnits,
          isIpoFirstTradingDay: widget.definition.asset.isIpoFirstTradingDay(
            widget.state.currentDate,
          ),
          technicalLevels: _technicalLevels,
          microstructureFrame: _liquidityPulse,
          displayedSnapshot: displayedSnapshot,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _result = TradeExecutionResult(
          state: widget.state,
          success: false,
          message: _tradeSaveFailureMessage,
        );
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(_tradeSaveFailureMessage)));
      return;
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _result = result;
    });
  }

  void _selectOrderType(TradeOrderType type) {
    setState(() {
      _orderType = type;
      _limitPrice ??= marketSnapPrice(
        _executionPrice,
        market: widget.definition.market,
      );
      _result = null;
    });
    widget.onSelectedLimitPriceChanged?.call(
      type == TradeOrderType.limit ? _limitPrice : null,
    );
  }

  Widget _compactStepButton({
    required Key key,
    required IconData icon,
    required VoidCallback? onPressed,
  }) => SizedBox(
    width: 32,
    height: 32,
    child: IconButton(
      key: key,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
    ),
  );

  Widget _compactSummaryRow(String label, int value, {bool strong = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: strong ? _marketInk : _marketMuted,
                  fontSize: 9,
                  fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${_money(value)}원',
              style: TextStyle(
                color: strong ? _marketInk : const Color(0xFF555D69),
                fontSize: strong ? 11 : 9,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                fontFeatures: _marketNumberFeatures,
              ),
            ),
          ],
        ),
      );

  Widget _liquidityPulseAware(Widget Function() builder) {
    final pulse = widget.liquidityPulseListenable;
    if (pulse == null) return builder();
    return ValueListenableBuilder<int>(
      valueListenable: pulse,
      builder: (context, _, _) => builder(),
    );
  }

  bool get _canSubmitWithLatestBook {
    final maxQuantity = _maxQuantity;
    return _authorityReady &&
        _tradable &&
        _quantity > 0 &&
        _quantity <= maxQuantity &&
        _validLimitPrice &&
        !_submitting &&
        _result?.success != true;
  }

  Widget _buildCompactOrder({
    required String action,
    required Color actionColor,
  }) {
    final unavailableMessage = !_tradable
        ? '현재는 주문 가능한 거래 시간이 아닙니다.'
        : !_authorityReady
        ? '종잣돈 10,000원을 먼저 마련해야 주문할 수 있습니다.'
        : widget.isBuy
        ? '1주를 살 예수금이 부족합니다.'
        : '매도 가능한 보유 수량이 없습니다.';
    return Container(
      key: const Key('inline-order-ticket'),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 24,
            child: Row(
              children: [
                Text(
                  '$action 주문',
                  style: TextStyle(
                    color: actionColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    '현재 ${_money(_executionPrice.round())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _marketInk,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      fontFeatures: _marketNumberFeatures,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 32,
            child: SegmentedButton<TradeOrderType>(
              key: const Key('order-type-selector'),
              segments: const [
                ButtonSegment(value: TradeOrderType.market, label: Text('시장가')),
                ButtonSegment(value: TradeOrderType.limit, label: Text('지정가')),
              ],
              selected: {_orderType},
              onSelectionChanged: (value) => _selectOrderType(value.first),
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 5),
                ),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            key: const Key('limit-price-control'),
            height: 37,
            decoration: BoxDecoration(
              color: _orderType == TradeOrderType.limit
                  ? const Color(0xFFF4F6F8)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE1E5EA)),
            ),
            child: Row(
              children: [
                _compactStepButton(
                  key: const Key('limit-price-minus'),
                  icon: Icons.remove_rounded,
                  onPressed:
                      _orderType == TradeOrderType.limit &&
                          (_limitPrice ?? 0) > _dailyRange.lower
                      ? () => _changeLimitPrice(-1)
                      : null,
                ),
                Expanded(
                  child: Text(
                    _orderType == TradeOrderType.limit
                        ? '${_money((_limitPrice ?? 0).round())}원'
                        : '현재가 체결',
                    key: const Key('limit-price-value'),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _orderType == TradeOrderType.limit
                          ? _marketInk
                          : _marketMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFeatures: _marketNumberFeatures,
                    ),
                  ),
                ),
                _compactStepButton(
                  key: const Key('limit-price-plus'),
                  icon: Icons.add_rounded,
                  onPressed:
                      _orderType == TradeOrderType.limit &&
                          (_limitPrice ?? 0) < _dailyRange.upper
                      ? () => _changeLimitPrice(1)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 37,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE1E5EA)),
            ),
            child: Row(
              children: [
                _compactStepButton(
                  key: const Key('order-quantity-minus'),
                  icon: Icons.remove_rounded,
                  onPressed: _quantity > 1
                      ? () => setState(
                          () => _quantity = math.max(1, _quantity - 1),
                        )
                      : null,
                ),
                Expanded(
                  child: Text(
                    '${_displayUnits(_quantity)}주',
                    key: const Key('order-quantity-value'),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _marketInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFeatures: _marketNumberFeatures,
                    ),
                  ),
                ),
                _liquidityPulseAware(() {
                  final maxQuantity = _maxQuantity;
                  return _compactStepButton(
                    key: const Key('order-quantity-plus'),
                    icon: Icons.add_rounded,
                    onPressed: _quantity < maxQuantity
                        ? () => setState(
                            () => _quantity = math.min(
                              maxQuantity,
                              _quantity + 1,
                            ),
                          )
                        : null,
                  );
                }),
              ],
            ),
          ),
          SizedBox(
            height: 29,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.isBuy
                        ? '가능 ${_money(widget.state.availableBrokerageCash)}원'
                        : '보유 ${_displayUnits(_position?.units ?? 0)}주',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _marketMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _liquidityPulseAware(() {
                  final maxQuantity = _maxQuantity;
                  return TextButton(
                    key: const Key('inline-order-maximum'),
                    onPressed: maxQuantity > 0
                        ? () => setState(() => _quantity = maxQuantity)
                        : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 26),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      '최대 ${_displayUnits(maxQuantity)}주',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          _liquidityPulseAware(
            () => Container(
              key: const Key('inline-order-liquidity-preview'),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _compactSummaryRow('주문 금액', _notional),
                  _compactSummaryRow(
                    widget.isBuy ? '수수료' : '수수료·세금',
                    _fee + _transactionTax,
                  ),
                  _compactSummaryRow(
                    widget.isBuy ? '총 결제액' : '예상 수령액',
                    _settlement,
                    strong: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: _result != null
                  ? Container(
                      key: const Key('order-result'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _result!.success
                            ? const Color(0xFFE8F8F0)
                            : const Color(0xFFFFECEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _result!.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _result!.success
                              ? const Color(0xFF18794E)
                              : const Color(0xFFB42332),
                          fontSize: 9,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : _liquidityPulseAware(() {
                      final maxQuantity = _maxQuantity;
                      if (!_authorityReady || !_tradable || maxQuantity <= 0) {
                        return Text(
                          unavailableMessage,
                          key: _tradable && !_authorityReady
                              ? const Key('order-authority-warning')
                              : null,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF04452),
                            fontSize: 9,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }
                      return Text(
                        _orderType == TradeOrderType.limit
                            ? '오른쪽 호가를 누르면 주문 가격이 바뀝니다.'
                            : '시장가는 보이는 호가부터 즉시 체결됩니다.',
                        maxLines: 2,
                        style: const TextStyle(
                          color: _marketMuted,
                          fontSize: 9,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 44,
            child: _liquidityPulseAware(
              () => FilledButton(
                key: const Key('request-state-account-order-approval'),
                onPressed: _result?.success == true
                    ? widget.onSuccessContinue
                    : _canSubmitWithLatestBook
                    ? _submit
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  backgroundColor: actionColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: _submitting
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _result?.success == true
                            ? widget.successLabel
                            : !_tradable
                            ? '거래 시간 아님'
                            : !_authorityReady
                            ? '주문 권한 필요'
                            : widget.submitLabel ?? '$action 주문',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.isBuy ? '매수' : '매도';
    final actionColor = widget.isBuy ? const Color(0xFFF04452) : _marketAccent;
    if (widget.compact) {
      return _buildCompactOrder(action: action, actionColor: actionColor);
    }
    final maxQuantity = _maxQuantity;
    final canSubmit = _canSubmitWithLatestBook;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.definition.name} $action',
                style: const TextStyle(
                  color: Color(0xFF202632),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '현재가 ${_displayPrice(_executionPrice, widget.definition.currency)}'
                ' · 예상 체결가 ${_displayPrice(_estimatedExecutionPrice, widget.definition.currency)}'
                ' · 수수료 ${(_feeRate * 100).toStringAsFixed(3)}%',
                style: const TextStyle(
                  color: Color(0xFF5D6572),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<TradeOrderType>(
                key: const Key('order-type-selector'),
                segments: const [
                  ButtonSegment(
                    value: TradeOrderType.market,
                    label: Text('시장가'),
                  ),
                  ButtonSegment(
                    value: TradeOrderType.limit,
                    label: Text('지정가'),
                  ),
                ],
                selected: {_orderType},
                onSelectionChanged: (value) => _selectOrderType(value.first),
                showSelectedIcon: false,
              ),
              if (_orderType == TradeOrderType.limit) ...[
                const SizedBox(height: 12),
                Container(
                  key: const Key('limit-price-control'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F8),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '지정가',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        key: const Key('limit-price-minus'),
                        onPressed: (_limitPrice ?? 0) > _dailyRange.lower
                            ? () => _changeLimitPrice(-1)
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      SizedBox(
                        width: 92,
                        child: Text(
                          '${_money((_limitPrice ?? 0).round())}원',
                          key: const Key('limit-price-value'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFeatures: _marketNumberFeatures,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('limit-price-plus'),
                        onPressed: (_limitPrice ?? 0) < _dailyRange.upper
                            ? () => _changeLimitPrice(1)
                            : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '오늘 주문 범위 ${_money(_dailyRange.lower.round())}~'
                  '${_money(_dailyRange.upper.round())}원 · 미체결은 장 마감에 자동 취소',
                  style: const TextStyle(
                    color: Color(0xFF7B8491),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '주문 수량',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton.filledTonal(
                          key: const Key('order-quantity-minus'),
                          onPressed: _quantity > 1
                              ? () => setState(
                                  () => _quantity = math.max(1, _quantity - 1),
                                )
                              : null,
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        SizedBox(
                          width: 58,
                          child: Text(
                            '${_displayUnits(_quantity)}주',
                            key: const Key('order-quantity-value'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          key: const Key('order-quantity-plus'),
                          onPressed: _quantity < maxQuantity
                              ? () => setState(
                                  () => _quantity = math.min(
                                    maxQuantity,
                                    _quantity + 1,
                                  ),
                                )
                              : null,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.isBuy
                                ? '${widget.balanceLabel ?? '주문 가능 예수금'} ${_money(widget.state.availableBrokerageCash)}원'
                                : '보유 ${_displayUnits(_position?.units ?? 0)}주',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF69717E),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: maxQuantity > 0
                              ? () => setState(() => _quantity = maxQuantity)
                              : null,
                          child: Text('최대 ${_displayUnits(maxQuantity)}주'),
                        ),
                      ],
                    ),
                    const Divider(),
                    _OrderSummaryRow(label: _notionalLabel, value: _notional),
                    _OrderSummaryRow(label: '증권 수수료', value: _fee),
                    if (!widget.isBuy)
                      _OrderSummaryRow(label: '증권거래세', value: _transactionTax),
                    _OrderSummaryRow(
                      label: widget.isBuy ? '총 결제액' : '예상 수령액',
                      value: _settlement,
                      strong: true,
                    ),
                  ],
                ),
              ),
              if (!_authorityReady || !_tradable || maxQuantity <= 0) ...[
                const SizedBox(height: 10),
                Text(
                  !_tradable
                      ? '현재는 주문 가능한 거래 시간이 아닙니다.'
                      : !_authorityReady
                      ? '종잣돈 10,000원을 먼저 마련해야 국가계좌 주문 승인을 받을 수 있습니다.'
                      : widget.isBuy
                      ? '1주를 살 현금이 부족합니다.'
                      : '보유 수량이 없습니다.',
                  key: _tradable && !_authorityReady
                      ? const Key('order-authority-warning')
                      : null,
                  style: const TextStyle(
                    color: Color(0xFFF04452),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: 12),
                Container(
                  key: const Key('order-result'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: _result!.success
                        ? const Color(0xFFE8F8F0)
                        : const Color(0xFFFFECEE),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    _result!.message,
                    style: TextStyle(
                      color: _result!.success
                          ? const Color(0xFF18794E)
                          : const Color(0xFFB42332),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              KeyedSubtree(
                key: widget.forceActionHighlight
                    ? Key(
                        widget.isBuy
                            ? 'tutorial-buy-action-highlight'
                            : 'tutorial-sell-action-highlight',
                      )
                    : null,
                child: FilledButton(
                  key: const Key('request-state-account-order-approval'),
                  onPressed: _result?.success == true
                      ? (widget.onSuccessContinue ??
                            () => Navigator.of(context).pop())
                      : canSubmit
                      ? _submit
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: actionColor,
                    side: widget.forceActionHighlight
                        ? const BorderSide(color: Color(0xFFFFD85E), width: 4)
                        : null,
                    shadowColor: widget.forceActionHighlight
                        ? const Color(0xFFFFD85E)
                        : null,
                    elevation: widget.forceActionHighlight ? 10 : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _result?.success == true
                              ? widget.successLabel
                              : !_tradable
                              ? '거래 시간에 주문 가능'
                              : !_authorityReady
                              ? '종잣돈 10,000원 달성 후 주문 가능'
                              : widget.submitLabel ?? '부모님 승인으로 주문 실행',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummaryRow extends StatelessWidget {
  const _OrderSummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final int value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Text(
          '${_money(value)}원',
          style: TextStyle(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
