part of 'main.dart';

enum _MarketSort { turnover, gainers, losers, name }

class _CrtTradingRoomScene extends StatelessWidget {
  const _CrtTradingRoomScene({
    required this.minute,
    required this.child,
    this.onBack,
  });
  final int minute;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 400;
    return Scaffold(
      backgroundColor: const Color(0xFF151A26),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_boy_room_1999.png',
              fit: BoxFit.cover,
            ),
          ),
          const Positioned.fill(child: ColoredBox(color: Color(0xA20E1420))),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  children: [
                    _SceneClockStrip(
                      location: '내 방 · CRT 투자 단말',
                      caption: '모뎀 소리와 함께 2000년 시장 화면이 켜졌다.',
                      minute: minute,
                      costLabel: '장중 시간 연동',
                      onBack: onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.fromLTRB(
                          compact ? 0 : 8,
                          0,
                          compact ? 0 : 8,
                          8,
                        ),
                        padding: EdgeInsets.all(compact ? 3 : 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2F3A),
                          borderRadius: BorderRadius.circular(
                            compact ? 18 : 25,
                          ),
                          border: Border.all(
                            color: const Color(0xFF656E7D),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x99000000),
                              blurRadius: 28,
                              offset: Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: child,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StockMarketScreen extends StatefulWidget {
  const StockMarketScreen({
    super.key,
    required this.state,
    this.onExecuteTrade,
    this.onSetMarketMinute,
    this.universe,
  });

  final GameState state;
  final Future<GameState> Function(int)? onSetMarketMinute;
  final Future<TradeExecutionResult> Function(TradeOrder)? onExecuteTrade;
  final HistoricalMarketUniverse? universe;

  @override
  State<StockMarketScreen> createState() => _StockMarketScreenState();
}

class _StockMarketScreenState extends State<StockMarketScreen> {
  final _searchController = TextEditingController();
  final Map<String, ValueNotifier<_LiveStock>> _live = {};
  List<_StockDefinition> _stocks = const [];
  Timer? _timer;
  final ValueNotifier<int> _minute = ValueNotifier(marketDayStartMinute);
  int _tick = 0;
  late int _marketMinute;
  late GameState _state;
  int _tab = 0;
  _MarketSort _sort = _MarketSort.turnover;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _state = widget.state;
    _marketMinute = _state.marketMinute;
    _minute.value = _marketMinute;
    _tick = marketTickForMinute(_marketMinute);
    _loadHistoricalMarket();
  }

  Future<void> _loadHistoricalMarket() async {
    try {
      final universe = widget.universe ?? await HistoricalMarketUniverse.load();
      final loaded = <_StockDefinition>[];
      for (final asset in universe.assets) {
        final quote = asset.quoteAtOrBefore(_state.currentDate);
        if (quote == null) continue;
        final stock = _StockDefinition.fromAsset(asset);
        final previousClose =
            asset.previousCloseBefore(quote.date) ?? quote.close;
        final closes = asset.closesThrough(_state.currentDate);
        final history = closes.length >= 2
            ? closes
            : <double>[previousClose, quote.close];
        loaded.add(stock);
        final path = quote.isExactDate
            ? generatedFullMarketDayPath(
                previousClose: previousClose,
                officialClose: quote.close,
                seed: _stockSeed(stock.code, _state.currentDate),
              )
            : <double>[quote.close];
        final pathIndex = quote.isExactDate
            ? _tick.clamp(0, path.length - 1)
            : 0;
        final sessionHistory = path.take(pathIndex + 1).toList();
        final startingPrice = sessionHistory.last;
        _live[stock.code] = ValueNotifier(
          _LiveStock(
            price: startingPrice,
            previousClose: previousClose,
            officialClose: quote.close,
            isTradingDay: quote.isExactDate,
            open: sessionHistory.first,
            high: sessionHistory.reduce(math.max),
            low: sessionHistory.reduce(math.min),
            history: history,
            sessionHistory: sessionHistory,
            sessionPath: path,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _stocks = loaded;
        _loading = false;
      });
      if (_live.values.any((notifier) => notifier.value.isTradingDay)) {
        _timer = Timer.periodic(
          const Duration(milliseconds: 900),
          (_) => _update(),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _minute.dispose();
    _searchController.dispose();
    for (final notifier in _live.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  void _update() {
    if (_tick >= generatedSessionTicks) return;
    _tick += 1;
    _marketMinute = marketMinuteForTick(_tick);
    _minute.value = _marketMinute;
    for (var index = 0; index < _stocks.length; index++) {
      final notifier = _live[_stocks[index].code]!;
      final current = notifier.value;
      if (!current.isTradingDay) continue;
      final nextPrice = current.sessionPath[_tick];
      final sessionHistory = <double>[...current.sessionHistory, nextPrice];
      notifier.value = current.copyWith(
        price: nextPrice,
        high: nextPrice > current.high ? nextPrice : current.high,
        low: nextPrice < current.low ? nextPrice : current.low,
        sessionHistory: sessionHistory,
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _closeMarket() async {
    final next = await widget.onSetMarketMinute?.call(_marketMinute);
    if (next != null) _state = next;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _advanceOneHour() async {
    final targetMinute = math.min(_marketMinute + 60, marketDayEndMinute);
    final targetTick = marketTickForMinute(targetMinute);
    _timer?.cancel();
    _tick = targetTick;
    _marketMinute = targetMinute;
    _minute.value = _marketMinute;
    for (final stock in _stocks) {
      final notifier = _live[stock.code]!;
      final current = notifier.value;
      if (!current.isTradingDay) continue;
      final sessionHistory = current.sessionPath.take(_tick + 1).toList();
      notifier.value = current.copyWith(
        price: sessionHistory.last,
        high: sessionHistory.reduce(math.max),
        low: sessionHistory.reduce(math.min),
        sessionHistory: sessionHistory,
      );
    }
    final next = await widget.onSetMarketMinute?.call(_marketMinute);
    if (next != null) _state = next;
    if (!mounted) return;
    setState(() {});
    if (_tick < generatedSessionTicks &&
        _live.values.any((value) => value.value.isTradingDay)) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 900),
        (_) => _update(),
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
    final synced = await widget.onSetMarketMinute?.call(order.marketMinute);
    if (synced != null) _state = synced;
    final result = await callback(order);
    if (result.success && mounted) {
      setState(() => _state = result.state);
    }
    return result;
  }

  List<_StockDefinition> get _visibleStocks {
    final query = _searchController.text.trim().toLowerCase();
    final source = switch (_tab) {
      0 => _stocks.where((stock) => stock.country == 'KR'),
      1 => _stocks.where((stock) => stock.market == 'KOSPI'),
      2 => _stocks.where((stock) => stock.market == 'KOSDAQ'),
      _ => _stocks.where((stock) => stock.country != 'KR'),
    };
    final visible = source
        .where(
          (stock) =>
              query.isEmpty ||
              stock.name.toLowerCase().contains(query) ||
              stock.code.contains(query) ||
              stock.sector.toLowerCase().contains(query) ||
              stock.market.toLowerCase().contains(query),
        )
        .toList();
    visible.sort((left, right) {
      final leftQuote = _live[left.code]!.value;
      final rightQuote = _live[right.code]!.value;
      return switch (_sort) {
        _MarketSort.turnover => _simulatedTurnover(
          right,
          rightQuote,
        ).compareTo(_simulatedTurnover(left, leftQuote)),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '시장 데이터를 불러오지 못했어요.\n$_loadError',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }
    return _CrtTradingRoomScene(
      minute: _marketMinute,
      onBack: _closeMarket,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SafeArea(
              child: Column(
                children: [
                  _MarketClockBar(
                    minute: _marketMinute,
                    tradingDay: _live.values.any(
                      (value) => value.value.isTradingDay,
                    ),
                    onAdvanceHour: _advanceOneHour,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                      children: [
                        _MarketBalanceCard(
                          state: _state,
                          prices: {
                            for (final stock in _stocks)
                              if (stock.currency == 'KRW')
                                stock.id: _live[stock.code]!.value.price,
                          },
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          key: const Key('market-search-input'),
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: '회사명이나 종목코드 검색',
                            prefixIcon: const Icon(Icons.search_rounded),
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
                          onChanged: (value) => setState(() => _tab = value),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _tab == 3 ? '해외 참고 종목' : '2000년 국내 종목',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF202632),
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F8F0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  _LiveDot(),
                                  SizedBox(width: 5),
                                  Text(
                                    '실제 종가 연동',
                                    style: TextStyle(
                                      color: Color(0xFF26845B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          '장중 틱은 자동 생성되며 마지막 값은 실제 일별 종가와 일치합니다.',
                          style: TextStyle(
                            color: Color(0xFF8A919E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _MarketSortBar(
                          selected: _sort,
                          onChanged: (value) => setState(() => _sort = value),
                        ),
                        const SizedBox(height: 10),
                        ..._visibleStocks.map(
                          (stock) => _StockRow(
                            key: Key('stock-row-${stock.code}'),
                            definition: stock,
                            live: _live[stock.code]!,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => _StockDetailScreen(
                                  definition: stock,
                                  live: _live[stock.code]!,
                                  state: _state,
                                  minute: _minute,
                                  onExecuteTrade: _executeTrade,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_visibleStocks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 50),
                            child: Center(
                              child: Text(
                                _searchController.text.trim().isNotEmpty
                                    ? '검색 결과가 없어요.'
                                    : '아직 공개된 종가가 없어요.\n첫 거래일을 기다려 주세요.',
                                textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}

class _StockDetailScreen extends StatefulWidget {
  const _StockDetailScreen({
    required this.definition,
    required this.live,
    required this.state,
    required this.minute,
    required this.onExecuteTrade,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final GameState state;
  final ValueNotifier<int> minute;
  final Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade;

  @override
  State<_StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<_StockDetailScreen> {
  late GameState _state;

  _StockDefinition get definition => widget.definition;
  ValueNotifier<_LiveStock> get live => widget.live;
  GameState get state => _state;
  ValueNotifier<int> get minute => widget.minute;

  @override
  void initState() {
    super.initState();
    _state = widget.state;
  }

  Future<TradeExecutionResult> onExecuteTrade(TradeOrder order) async {
    final result = await widget.onExecuteTrade(order);
    if (result.success && mounted) setState(() => _state = result.state);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: minute,
      builder: (context, currentMinute, _) => _CrtTradingRoomScene(
        minute: currentMinute,
        onBack: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SafeArea(
                child: ValueListenableBuilder<_LiveStock>(
                  valueListenable: live,
                  builder: (context, quote, _) {
                    final change = quote.price - quote.previousClose;
                    final rate = change / quote.previousClose * 100;
                    final color = _priceColor(change);
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
                                      style: const TextStyle(
                                        color: Color(0xFF202632),
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      '${definition.market} · ${definition.code}',
                                      style: const TextStyle(
                                        color: Color(0xFF8A919E),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: '관심 종목',
                                onPressed: () => _showResearchMessage(
                                  context,
                                  '관심 종목에 담았어요.',
                                ),
                                icon: const Icon(Icons.star_border_rounded),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                            children: [
                              Hero(
                                tag: 'stock-${definition.code}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    _displayPrice(
                                      quote.price,
                                      definition.currency,
                                    ),
                                    key: const Key('stock-detail-price'),
                                    style: const TextStyle(
                                      color: Color(0xFF171B24),
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '어제보다 ${change >= 0 ? '+' : '-'}${_displayPrice(change.abs(), definition.currency)}  ${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _TradingStatusRow(quote: quote),
                              const SizedBox(height: 14),
                              _MinuteChartPanel(quote: quote),
                              const SizedBox(height: 24),
                              _QuoteGrid(quote: quote),
                              const SizedBox(height: 28),
                              const Divider(color: Color(0xFFF0F1F3)),
                              const SizedBox(height: 20),
                              const Text(
                                '이 회사를 한 문장으로',
                                style: TextStyle(
                                  color: Color(0xFF202632),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                definition.summary,
                                style: const TextStyle(
                                  color: Color(0xFF5D6572),
                                  fontSize: 14,
                                  height: 1.55,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _HistoricalLeadershipSection(
                                companyCode: definition.code,
                                currentDate: state.currentDate,
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7D8),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '오늘의 조사 질문',
                                      style: TextStyle(
                                        color: Color(0xFF8A6815),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      definition.question,
                                      style: const TextStyle(
                                        color: Color(0xFF403617),
                                        fontSize: 14,
                                        height: 1.45,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '일별 종가는 실제 기록이며, 0.9초 장중 틱과 조사 설명은 DAY ${state.day}의 게임용 재현입니다.',
                                style: const TextStyle(
                                  color: Color(0xFF9A9FA8),
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x16000000),
                                blurRadius: 18,
                                offset: Offset(0, -5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  key: const Key('ask-family-button'),
                                  onPressed: definition.currency == 'KRW'
                                      ? () => _showOrderSheet(
                                          context,
                                          definition: definition,
                                          live: live,
                                          isBuy: false,
                                          state: state,
                                          minute: minute,
                                          onExecuteTrade: onExecuteTrade,
                                        )
                                      : () => _showResearchMessage(
                                          context,
                                          '해외 종목은 실제 환율 원장을 연결하기 전까지 참고용입니다.',
                                        ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    foregroundColor: const Color(0xFF38404D),
                                    side: const BorderSide(
                                      color: Color(0xFFD8DCE2),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    '팔기',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  key: const Key('write-research-note-button'),
                                  onPressed: definition.currency == 'KRW'
                                      ? () => _showOrderSheet(
                                          context,
                                          definition: definition,
                                          live: live,
                                          isBuy: true,
                                          state: state,
                                          minute: minute,
                                          onExecuteTrade: onExecuteTrade,
                                        )
                                      : () => _showResearchMessage(
                                          context,
                                          '해외 종목은 실제 환율 원장을 연결하기 전까지 참고용입니다.',
                                        ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    backgroundColor: const Color(0xFF3182F6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    '사기',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _showOrderSheet(
    BuildContext context, {
    required _StockDefinition definition,
    required ValueNotifier<_LiveStock> live,
    required bool isBuy,
    required GameState state,
    required ValueNotifier<int> minute,
    required Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _OrderSheet(
        definition: definition,
        live: live,
        isBuy: isBuy,
        state: state,
        minute: minute,
        onExecuteTrade: onExecuteTrade,
      ),
    );
  }

  static void _showResearchMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OrderSheet extends StatefulWidget {
  const _OrderSheet({
    required this.definition,
    required this.live,
    required this.isBuy,
    required this.state,
    required this.minute,
    required this.onExecuteTrade,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final bool isBuy;
  final GameState state;
  final ValueNotifier<int> minute;
  final Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade;

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  double _quantity = 1;
  bool _submitting = false;
  TradeExecutionResult? _result;

  @override
  void initState() {
    super.initState();
    widget.live.addListener(_handleMarketUpdate);
    widget.minute.addListener(_handleMarketUpdate);
    if (!widget.isBuy && (_position?.units ?? 0) < 1) {
      _quantity = _position?.units ?? 1;
    }
  }

  @override
  void dispose() {
    widget.live.removeListener(_handleMarketUpdate);
    widget.minute.removeListener(_handleMarketUpdate);
    super.dispose();
  }

  void _handleMarketUpdate() {
    if (mounted) setState(() {});
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
  int get _notional => (_executionPrice * _quantity).round();
  int get _fee => (_notional * 0.0025).round();
  int get _settlement => widget.isBuy ? _notional + _fee : _notional - _fee;
  double get _maxQuantity {
    if (!widget.isBuy) return _position?.units ?? 0;
    if (_executionPrice <= 0) return 0;
    return (widget.state.cash / (_executionPrice * 1.0025)).floorToDouble();
  }

  bool get _tradable {
    final tradingDay =
        _quote.isTradingDay && isMarketTradingDay(widget.state.currentDate);
    return marketClockAt(_marketMinute, tradingDay: tradingDay).tradable;
  }

  Future<void> _submit() async {
    if (_submitting || _result?.success == true) return;
    setState(() {
      _submitting = true;
      _result = null;
    });
    final result = await widget.onExecuteTrade(
      TradeOrder(
        side: widget.isBuy ? TradeSide.buy : TradeSide.sell,
        assetId: widget.definition.id,
        symbol: widget.definition.code,
        name: widget.definition.name,
        market: widget.definition.market,
        currency: widget.definition.currency,
        quantity: _quantity,
        unitPrice: _executionPrice,
        marketMinute: _marketMinute,
        isTradingDay: _quote.isTradingDay,
      ),
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.isBuy ? '사기' : '팔기';
    final actionColor = widget.isBuy
        ? const Color(0xFF3182F6)
        : const Color(0xFFF04452);
    final maxQuantity = _maxQuantity;
    final canSubmit =
        _tradable &&
        _quantity > 0 &&
        _quantity <= maxQuantity &&
        !_submitting &&
        _result?.success != true;
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
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '현재 게임 체결가 ${_displayPrice(_executionPrice, widget.definition.currency)} · 수수료 0.25%',
                style: const TextStyle(
                  color: Color(0xFF5D6572),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                            style: TextStyle(fontWeight: FontWeight.w900),
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
                              fontWeight: FontWeight.w900,
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
                                ? '주문 가능 현금 ${_money(widget.state.cash)}원'
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
                    _OrderSummaryRow(label: '주문 금액', value: _notional),
                    _OrderSummaryRow(label: '수수료', value: _fee),
                    _OrderSummaryRow(
                      label: widget.isBuy ? '총 결제액' : '예상 수령액',
                      value: _settlement,
                      strong: true,
                    ),
                  ],
                ),
              ),
              if (!_tradable || maxQuantity <= 0) ...[
                const SizedBox(height: 10),
                Text(
                  !_tradable
                      ? '현재는 주문 가능한 거래 시간이 아닙니다.'
                      : widget.isBuy
                      ? '1주를 살 현금이 부족합니다.'
                      : '보유 수량이 없습니다.',
                  style: const TextStyle(
                    color: Color(0xFFF04452),
                    fontWeight: FontWeight.w800,
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
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('request-parent-order-approval'),
                onPressed: _result?.success == true
                    ? () => Navigator.of(context).pop()
                    : canSubmit
                    ? _submit
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: actionColor,
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
                        _result?.success == true ? '완료' : '부모님 승인으로 주문 실행',
                        style: const TextStyle(fontWeight: FontWeight.w900),
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
        Text(label),
        const Spacer(),
        Text(
          '${_money(value)}원',
          style: TextStyle(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _HistoricalLeadershipSection extends StatelessWidget {
  const _HistoricalLeadershipSection({
    required this.companyCode,
    required this.currentDate,
  });

  final String companyCode;
  final DateTime currentDate;

  @override
  Widget build(BuildContext context) {
    final executives = executivesForCompany(companyCode, currentDate);
    if (executives.isEmpty) return const SizedBox.shrink();
    final dateLabel =
        '${currentDate.year}.${currentDate.month.toString().padLeft(2, '0')}.${currentDate.day.toString().padLeft(2, '0')}';
    return Column(
      key: const Key('historical-executive-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '그날의 경영진',
                style: TextStyle(
                  color: Color(0xFF202632),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                dateLabel,
                style: const TextStyle(
                  color: Color(0xFF3774C7),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...executives.map(
          (executive) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HistoricalExecutiveCard(executive: executive),
          ),
        ),
        const Text(
          '이름·재임 직책은 실제 기록 기준이며, 초상은 게임용 AI 캐릭터 일러스트입니다. 게임 속 대사와 판단은 창작입니다.',
          style: TextStyle(
            color: Color(0xFF989FAA),
            fontSize: 9,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HistoricalExecutiveCard extends StatelessWidget {
  const _HistoricalExecutiveCard({required this.executive});

  final HistoricalExecutive executive;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('historical-executive-${executive.recordId}'),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFF5F8FC),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE4EAF2)),
    ),
    child: SizedBox(
      height: 148,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 108,
            child: Image.asset(
              executive.portraitAsset,
              key: Key('executive-portrait-${executive.personId}'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              semanticLabel: '${executive.nameKo} 상반신 게임 초상',
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    executive.roleKo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF3774C7),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    executive.nameKo,
                    style: const TextStyle(
                      color: Color(0xFF252B35),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${executive.nameEn} · ${executive.periodLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8A919E),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    executive.roleNote,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF56606E),
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MarketClockBar extends StatelessWidget {
  const _MarketClockBar({
    required this.minute,
    required this.tradingDay,
    required this.onAdvanceHour,
  });
  final int minute;
  final bool tradingDay;
  final VoidCallback onAdvanceHour;

  @override
  Widget build(BuildContext context) {
    final info = marketClockAt(minute, tradingDay: tradingDay);
    final ended = minute >= marketDayEndMinute;
    return Container(
      key: const Key('market-clock-bar'),
      margin: const EdgeInsets.fromLTRB(18, 2, 18, 10),
      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF202632),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(
            marketTimeLabel(minute),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.label,
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  info.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB7BFCD),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('market-advance-hour-button'),
            onPressed: ended ? null : onAdvanceHour,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF35425D),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            child: Text(
              ended ? '종료' : '+1시간',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketBalanceCard extends StatelessWidget {
  const _MarketBalanceCard({required this.state, required this.prices});

  final GameState state;
  final Map<String, double> prices;

  @override
  Widget build(BuildContext context) {
    final date = state.currentDate;
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final portfolioValue = state.portfolioValue(prices);
    final aum = state.totalAum(prices);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${state.companyName} · 가족 투자계좌',
                  key: const Key('market-company-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF5C6B7A),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const _LiveDot(),
                    const SizedBox(width: 6),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Color(0xFF536170),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${_money(state.cash)}원',
            style: const TextStyle(
              color: Color(0xFF171B24),
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  '주식 ${_money(portfolioValue)}원',
                  style: const TextStyle(
                    color: Color(0xFF718092),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '원화 AUM ${_money(aum)}원',
                key: const Key('market-total-aum'),
                style: const TextStyle(
                  color: Color(0xFF405269),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketTabs extends StatelessWidget {
  const _MarketTabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['국내', '코스피', '코스닥', '해외'];
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
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 3,
                      width: selected == index ? 28 : 0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3182F6),
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
  const _MarketSortBar({required this.selected, required this.onChanged});

  final _MarketSort selected;
  final ValueChanged<_MarketSort> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = <_MarketSort, String>{
      _MarketSort.turnover: '거래대금순',
      _MarketSort.gainers: '급상승',
      _MarketSort.losers: '급하락',
      _MarketSort.name: '이름순',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: labels.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(right: 7),
                child: ChoiceChip(
                  key: Key('market-sort-${entry.key.name}'),
                  selected: selected == entry.key,
                  onSelected: (_) => onChanged(entry.key),
                  label: Text(entry.value),
                  showCheckmark: false,
                  selectedColor: const Color(0xFFE8F2FF),
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  labelStyle: TextStyle(
                    color: selected == entry.key
                        ? const Color(0xFF2272D8)
                        : const Color(0xFF697281),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({
    super.key,
    required this.definition,
    required this.live,
    required this.onTap,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<_LiveStock>(
    valueListenable: live,
    builder: (context, quote, _) {
      final change = quote.price - quote.previousClose;
      final rate = _changeRate(quote);
      final color = _priceColor(change);
      final turnover = _simulatedTurnover(definition, quote);
      final volatility = quote.previousClose <= 0
          ? 0.0
          : (quote.high - quote.low) / quote.previousClose * 100;
      final signal = _marketSignal(definition, rate, volatility);
      return Container(
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDF0F3)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: definition.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          definition.name.substring(0, 1),
                          style: TextStyle(
                            color: definition.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              definition.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF252B35),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${definition.market} · ${definition.code} · ${definition.sector}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF9299A3),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 94,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Hero(
                              tag: 'stock-${definition.code}',
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  _displayPrice(
                                    quote.price,
                                    definition.currency,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF252B35),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(2)}%',
                              key: Key('stock-rate-${definition.code}'),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
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
                          '게임 거래대금 ${_compactEok(turnover)} · 변동폭 ${volatility.toStringAsFixed(2)}%',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF626C79),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 66,
                        height: 24,
                        child: CustomPaint(
                          painter: _SparklinePainter(
                            quote.sessionHistory,
                            color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: Color(0xFF7B61D1),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          signal,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF4D5562),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        _QuoteValue(label: '전일 종가', value: quote.previousClose),
        _QuoteValue(label: '틱 시작', value: quote.open),
        _QuoteValue(label: '틱 최고', value: quote.high),
        _QuoteValue(label: '틱 최저', value: quote.low),
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
            color: Color(0xFF353B45),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _MinuteChartPanel extends StatefulWidget {
  const _MinuteChartPanel({required this.quote});

  final _LiveStock quote;

  @override
  State<_MinuteChartPanel> createState() => _MinuteChartPanelState();
}

class _MinuteChartPanelState extends State<_MinuteChartPanel> {
  static const intervals = <int>[1, 3, 5, 10, 15, 30, 60, 120, 240];
  int interval = 1;

  @override
  Widget build(BuildContext context) {
    final candles = aggregateMarketCandles(
      widget.quote.sessionHistory,
      interval,
    );
    return Column(
      children: [
        SizedBox(
          height: 205,
          child: CustomPaint(
            key: const Key('minute-candle-chart'),
            painter: _CandleChartPainter(
              candles: candles,
              previousClose: widget.quote.previousClose,
            ),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            PopupMenuButton<int>(
              key: const Key('minute-interval-selector'),
              initialValue: interval,
              tooltip: '분봉 선택',
              onSelected: (value) => setState(() => interval = value),
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
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const _RangeChip(label: '일', selected: true),
            const _RangeChip(label: '주'),
            const _RangeChip(label: '월'),
            const _RangeChip(label: '년'),
          ],
        ),
        const SizedBox(height: 7),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '$interval분봉 · ${candles.length}개 캔들 · 생성 장중 틱',
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

class _CandleChartPainter extends CustomPainter {
  const _CandleChartPainter({
    required this.candles,
    required this.previousClose,
  });

  final List<MarketCandle> candles;
  final double previousClose;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty || size.isEmpty) return;
    final values = <double>[
      previousClose,
      ...candles.expand((candle) => <double>[candle.high, candle.low]),
    ];
    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);
    if (minValue == maxValue) {
      minValue *= 0.995;
      maxValue *= 1.005;
    }
    final padding = (maxValue - minValue) * 0.08;
    minValue -= padding;
    maxValue += padding;
    final range = maxValue - minValue;
    double yFor(double value) =>
        size.height - ((value - minValue) / range * size.height);

    final gridPaint = Paint()
      ..color = const Color(0xFFEFF1F4)
      ..strokeWidth = 1;
    for (var line = 1; line < 4; line++) {
      final y = size.height * line / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final baselineY = yFor(previousClose);
    final baselinePaint = Paint()
      ..color = const Color(0xFFB8BEC7)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, baselineY),
        Offset(math.min(x + 3, size.width), baselineY),
        baselinePaint,
      );
    }

    final visible = candles.length > 70
        ? candles.sublist(candles.length - 70)
        : candles;
    final slot = size.width / math.max(visible.length, 1);
    final bodyWidth = math.max(2.0, math.min(8.0, slot * 0.58));
    for (var index = 0; index < visible.length; index++) {
      final candle = visible[index];
      final x = slot * index + slot / 2;
      final rising = candle.close >= candle.open;
      final color = rising ? const Color(0xFFF04452) : const Color(0xFF3182F6);
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.2;
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
  }

  @override
  bool shouldRepaint(covariant _CandleChartPainter oldDelegate) =>
      oldDelegate.candles != candles ||
      oldDelegate.previousClose != previousClose;
}

class _TradingStatusRow extends StatelessWidget {
  const _TradingStatusRow({required this.quote});

  final _LiveStock quote;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _LiveDot(),
        const SizedBox(width: 7),
        Text(
          quote.isTradingDay ? '재현 장중 · 0.9초마다 갱신' : '장 마감',
          style: const TextStyle(
            color: Color(0xFF596270),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 18),
        const Text(
          '마지막 값 = 실제 종가',
          style: TextStyle(
            color: Color(0xFF9299A3),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFFEAF2FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: selected ? const Color(0xFF3182F6) : const Color(0xFF9399A3),
        fontSize: 11,
        fontWeight: FontWeight.w800,
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
    required this.id,
    required this.code,
    required this.name,
    required this.market,
    required this.country,
    required this.currency,
    required this.sector,
    required this.summary,
    required this.question,
    required this.accent,
  });

  factory _StockDefinition.fromAsset(HistoricalMarketAsset asset) =>
      _StockDefinition(
        id: asset.id,
        code: asset.code,
        name: asset.name,
        market: asset.market,
        country: asset.country,
        currency: asset.currency,
        sector: asset.sector,
        summary:
            '${asset.name}의 실제 일별 종가와 ${asset.sector} 사업 흐름을 함께 보는 조사 종목입니다.',
        question: '${asset.sector} 시장이 바뀌어도 이 회사의 경쟁력은 유지될까?',
        accent: _hexColor(asset.colorHex),
      );

  final String id;
  final String code;
  final String name;
  final String market;
  final String country;
  final String currency;
  final String sector;
  final String summary;
  final String question;
  final Color accent;
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
  final List<double> history;
  final List<double> sessionHistory;
  final List<double> sessionPath;

  _LiveStock copyWith({
    double? price,
    double? high,
    double? low,
    List<double>? history,
    List<double>? sessionHistory,
    List<double>? sessionPath,
  }) => _LiveStock(
    price: price ?? this.price,
    previousClose: previousClose,
    officialClose: officialClose,
    isTradingDay: isTradingDay,
    open: open,
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

double _simulatedTurnover(_StockDefinition definition, _LiveStock quote) {
  final hash = definition.code.codeUnits.fold<int>(
    17,
    (sum, unit) => sum * 31 + unit,
  );
  final base = 18.0 + (hash.abs() % 340);
  final progress = quote.sessionHistory.length / generatedSessionTicks;
  final volatility = quote.previousClose <= 0
      ? 0.0
      : (quote.high - quote.low).abs() / quote.previousClose;
  return base * (1 + progress * 1.4 + volatility * 18);
}

String _compactEok(double value) => value >= 1000
    ? '${(value / 1000).toStringAsFixed(1)}천억원'
    : '${value.round()}억원';

String _marketSignal(
  _StockDefinition definition,
  double rate,
  double volatility,
) {
  if (rate >= 4) return '매수세가 강해지며 ${definition.sector} 종목 중 상승이 커요';
  if (rate <= -4) return '매도 압력이 커졌어요 · 가격 변동을 확인하세요';
  if (volatility >= 2.2) return '장중 변동성이 확대됐어요 · 고가와 저가 차이를 확인하세요';
  if (rate >= 0.8) return '${definition.sector} 흐름보다 조금 강하게 움직이고 있어요';
  if (rate <= -0.8) return '${definition.sector} 흐름보다 조금 약하게 움직이고 있어요';
  return '현재가가 전일 종가 근처에서 움직이고 있어요';
}

int _stockSeed(String code, DateTime date) {
  var value = date.year * 10000 + date.month * 100 + date.day;
  for (final unit in code.codeUnits) {
    value = ((value * 31) ^ unit) & 0x7fffffff;
  }
  return value;
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

String _displayUnits(double units) => units == units.roundToDouble()
    ? units.toInt().toString()
    : units.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '');

Color _priceColor(double change) =>
    change >= 0 ? const Color(0xFFF04452) : const Color(0xFF3182F6);
