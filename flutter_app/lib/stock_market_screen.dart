part of 'main.dart';

enum _MarketSort { turnover, gainers, losers, name }

enum _MarketSection { home, explore, account }

enum _ChartPeriod { minute, day, week, month, year }

class _CrtTradingRoomScene extends StatelessWidget {
  const _CrtTradingRoomScene({required this.minute, required this.child});

  final int minute;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F8FA),
    body: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              children: [
                _MarketPhoneStatusBar(minute: minute),
                Expanded(child: child),
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
            color: Color(0xFF171B24),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
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
      height: 62,
      padding: const EdgeInsets.fromLTRB(5, 0, 8, 0),
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
                    color: Color(0xFF171B24),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
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
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
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
                      minimumSize: const Size(32, 32),
                      maximumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      backgroundColor: const Color(0xFFE6F0FF),
                      foregroundColor: const Color(0xFF3182F6),
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: const Color(0xFFB3BAC4),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 18),
                  ),
                ),
                Tooltip(
                  message: '1시간 진행',
                  child: TextButton(
                    key: const Key('market-advance-hour-button'),
                    onPressed: onAdvanceHour,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      maximumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                      foregroundColor: const Color(0xFF4C596A),
                      disabledForegroundColor: const Color(0xFFB3BAC4),
                    ),
                    child: const Icon(Icons.more_time_rounded, size: 17),
                  ),
                ),
                Tooltip(
                  message: '장 마감 15:30',
                  child: FilledButton(
                    key: const Key('market-jump-close-button'),
                    onPressed: onJumpToClose,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      maximumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      backgroundColor: const Color(0xFFEAF8F1),
                      foregroundColor: const Color(0xFF168A5B),
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: const Color(0xFFB3BAC4),
                    ),
                    child: const Icon(Icons.stop_rounded, size: 17),
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

class StockMarketScreen extends StatefulWidget {
  const StockMarketScreen({
    super.key,
    required this.state,
    this.onExecuteTrade,
    this.onTransferCash,
    this.onSetMarketMinute,
    this.onSaveMarketNotebook,
    this.onClaimMission,
    this.universe,
  });

  final GameState state;
  final Future<GameState> Function(int)? onSetMarketMinute;
  final Future<GameState> Function(Set<String>, Map<String, String>)?
  onSaveMarketNotebook;
  final Future<MissionClaimResult> Function()? onClaimMission;
  final Future<TradeExecutionResult> Function(TradeOrder)? onExecuteTrade;
  final Future<FinanceActionResult> Function(int amount, bool deposit)?
  onTransferCash;
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
  _MarketSection _section = _MarketSection.home;
  bool _loading = true;
  String? _loadError;
  bool _isClosing = false;
  bool _allowPop = false;
  bool _isAdvancingHour = false;
  bool _closeAfterHourAdvance = false;
  bool _isExecutingTrade = false;
  bool _isTransferringCash = false;
  bool _closeAfterTrade = false;
  bool _isClaimingMission = false;
  bool _isShowingSessionNotice = false;
  bool _isMarketSheetOpen = false;
  final Set<int> _shownSessionNotices = <int>{};
  bool get _hasDomesticTradingSession =>
      isMarketTradingDay(_state.currentDate) &&
      _stocks.any(
        (stock) =>
            stock.country == 'KR' &&
            (_live[stock.code]?.value.isTradingDay ?? false),
      );

  void _resumeTimerIfNeeded() {
    if (_timer != null ||
        _isClosing ||
        _isExecutingTrade ||
        _isTransferringCash ||
        _isMarketSheetOpen ||
        _isShowingSessionNotice ||
        _loading ||
        _marketMinute >= krxCloseMinute ||
        _tick >= krxCloseTick ||
        !_hasDomesticTradingSession) {
      return;
    }
    _timer = Timer.periodic(marketRealtimeTickDuration, (_) => _update());
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
        final history = asset.historyThrough(_state.currentDate);
        loaded.add(stock);
        final path = quote.isExactDate
            ? generatedFullMarketDayPath(
                previousClose: previousClose,
                officialClose: quote.close,
                seed: marketStockSeed(stock.code, _state.currentDate),
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
      _resumeTimerIfNeeded();
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
    if (_isExecutingTrade ||
        _isTransferringCash ||
        _isClosing ||
        _marketMinute >= krxCloseMinute ||
        _tick >= krxCloseTick) {
      return;
    }
    final previousMinute = _marketMinute;
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
    _maybeShowSessionNotice(previousMinute, _marketMinute);
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
      final next = await widget.onSetMarketMinute?.call(minuteToSave);
      if (next != null) _state = next;
      _popMarketAfterSave();
    } catch (_) {
      _isClosing = false;
      if (!mounted) return;
      if (!_loading &&
          _tick < generatedSessionTicks &&
          _live.values.any((value) => value.value.isTradingDay)) {
        _timer = Timer.periodic(marketRealtimeTickDuration, (_) => _update());
      }
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
        _isClosing ||
        _isExecutingTrade ||
        _isTransferringCash) {
      return;
    }
    if (requestedMinute <= _marketMinute) return;
    final previousMinute = _marketMinute;
    final targetMinute = math.min(requestedMinute, krxCloseMinute);
    final targetTick = marketTickForMinute(targetMinute);
    _isAdvancingHour = true;
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
    try {
      final next = await widget.onSetMarketMinute?.call(targetMinute);
      if (next != null) _state = next;
      if (!mounted) return;
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
      _isAdvancingHour = false;
      if (_closeAfterHourAdvance) {
        _closeAfterHourAdvance = false;
        _isClosing = true;
        _popMarketAfterSave();
        return;
      }
      setState(() {});
      _maybeShowSessionNotice(previousMinute, _marketMinute);
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
        order.isTradingDay != current.isTradingDay) {
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
    try {
      final synced = await widget.onSetMarketMinute?.call(order.marketMinute);
      if (synced != null) _state = synced;
      final result = await callback(order);
      if (result.success && mounted) {
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
      final synced = await widget.onSetMarketMinute?.call(_marketMinute);
      if (synced != null) _state = synced;
      final result = await callback(amount, deposit);
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
    final raw = _state.story.storyFlags['marketFavoriteAssetIds'];
    if (raw is! List) return <String>{};
    return raw.whereType<String>().toSet();
  }

  Map<String, String> get _researchNotes {
    final raw = _state.story.storyFlags['marketResearchNotes'];
    if (raw is! Map) return <String, String>{};
    return <String, String>{
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }

  Future<GameState> _persistMarketNotebook(
    Set<String> favorites,
    Map<String, String> notes,
  ) async {
    final callback = widget.onSaveMarketNotebook;
    if (callback == null) return _state;
    final saved = await callback(favorites, notes);
    if (mounted) setState(() => _state = saved);
    return saved;
  }

  Future<GameState> _toggleFavorite(String assetId) {
    final favorites = _favoriteAssetIds;
    if (favorites.contains(assetId)) {
      favorites.remove(assetId);
    } else {
      favorites.add(assetId);
    }
    return _persistMarketNotebook(favorites, _researchNotes);
  }

  Future<GameState> _saveResearchNote(String assetId, String value) {
    final notes = _researchNotes;
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      notes.remove(assetId);
    } else {
      notes[assetId] = trimmed.substring(0, math.min(300, trimmed.length));
    }
    return _persistMarketNotebook(_favoriteAssetIds, notes);
  }

  Future<void> _claimActiveMission() async {
    final callback = widget.onClaimMission;
    if (callback == null || _isClaimingMission) return;
    setState(() => _isClaimingMission = true);
    try {
      final result = await callback();
      if (result.success && mounted) setState(() => _state = result.state);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    } catch (_) {
      if (mounted) _showSaveFailure(context);
    } finally {
      if (mounted) setState(() => _isClaimingMission = false);
    }
  }

  List<_StockDefinition> _sortedStocks(Iterable<_StockDefinition> source) {
    final visible = source.toList();
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

  List<_StockDefinition> get _visibleStocks {
    final query = _searchController.text.trim().toLowerCase();
    final source = switch (_tab) {
      0 => _stocks.where((stock) => stock.country == 'KR'),
      1 => _stocks.where((stock) => stock.market == 'KOSPI'),
      2 => _stocks.where((stock) => stock.market == 'KOSDAQ'),
      3 => _stocks.where((stock) => stock.country != 'KR'),
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

  void _openStock(_StockDefinition stock) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _StockDetailScreen(
          definition: stock,
          live: _live[stock.code]!,
          state: _state,
          minute: _minute,
          onExecuteTrade: _executeTrade,
          onToggleFavorite: _toggleFavorite,
          onSaveResearchNote: _saveResearchNote,
          onMarketSheetOpened: _pauseMarketForSheet,
          onMarketSheetClosed: _resumeMarketAfterSheet,
        ),
      ),
    );
  }

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

  Widget _buildHomeSection() {
    final domestic = _stocks
        .where((stock) => stock.country == 'KR' && stock.currency == 'KRW')
        .toList();
    final ranked = _sortedStocks(domestic);
    return ListView(
      key: const Key('market-home-section'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
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
        _MarketRankingTable(stocks: ranked, live: _live, onOpen: _openStock),
      ],
    );
  }

  Widget _buildAccountSection() {
    final rows = _holdingRows();
    return ListView(
      key: const Key('market-account-section'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        const Text(
          '내 투자',
          style: TextStyle(
            color: Color(0xFF191F28),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 12),
        _BrokerageAccountCard(
          state: _state,
          prices: _currentPrices,
          onDeposit: widget.onTransferCash == null
              ? null
              : () => _openTransferSheet(true),
          onWithdraw: widget.onTransferCash == null
              ? null
              : () => _openTransferSheet(false),
        ),
        const SizedBox(height: 13),
        _MarketMissionCard(
          state: _state,
          onClaim: widget.onClaimMission == null || _isClaimingMission
              ? null
              : _claimActiveMission,
        ),
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
        const Scaffold(
          backgroundColor: Color(0xFFF7F8FA),
          body: Center(child: CircularProgressIndicator()),
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
                child: Text(
                  '시장 데이터를 불러오지 못했어요.\n$_loadError',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }
    final visibleStocks = _visibleStocks;
    final marketListTitle = switch (_tab) {
      3 => '해외 참고 종목',
      4 => '관심 종목',
      _ => '2000년 국내 종목',
    };

    final scene = _CrtTradingRoomScene(
      minute: _marketMinute,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SafeArea(
              child: Column(
                children: [
                  _MarketHomeAppBar(
                    onBack: _closeMarket,
                    minute: _marketMinute,
                    tradingDay: _hasDomesticTradingSession,
                    onAdvanceHour:
                        _isAdvancingHour ||
                            _isClosing ||
                            _isExecutingTrade ||
                            _marketMinute >= krxCloseMinute
                        ? null
                        : _advanceOneHour,
                    onJumpToOpen:
                        _isAdvancingHour ||
                            _isClosing ||
                            _isExecutingTrade ||
                            !_hasDomesticTradingSession ||
                            _marketMinute >= krxOpenMinute
                        ? null
                        : _jumpToMarketOpen,
                    onJumpToClose:
                        _isAdvancingHour ||
                            _isClosing ||
                            _isExecutingTrade ||
                            !_hasDomesticTradingSession ||
                            _marketMinute < krxOpenMinute ||
                            _marketMinute >= krxCloseMinute
                        ? null
                        : _jumpToMarketClose,
                  ),
                  Expanded(
                    child: switch (_section) {
                      _MarketSection.home => _buildHomeSection(),
                      _MarketSection.account => _buildAccountSection(),
                      _MarketSection.explore => ListView(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                        children: [
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
                                  marketListTitle,
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
                          ...visibleStocks.map(
                            (stock) => _StockRow(
                              key: Key('stock-row-${stock.code}'),
                              definition: stock,
                              live: _live[stock.code]!,
                              favorite: _favoriteAssetIds.contains(stock.id),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _StockDetailScreen(
                                    definition: stock,
                                    live: _live[stock.code]!,
                                    state: _state,
                                    minute: _minute,
                                    onExecuteTrade: _executeTrade,
                                    onToggleFavorite: _toggleFavorite,
                                    onSaveResearchNote: _saveResearchNote,
                                    onMarketSheetOpened: _pauseMarketForSheet,
                                    onMarketSheetClosed:
                                        _resumeMarketAfterSheet,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (visibleStocks.isEmpty)
                            Padding(
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
                            ),
                        ],
                      ),
                    },
                  ),
                  _MarketBottomNavigation(
                    selected: _section,
                    onChanged: (value) => setState(() => _section = value),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return _withMarketExitGuard(scene);
  }
}

class _StockDetailScreen extends StatefulWidget {
  const _StockDetailScreen({
    required this.definition,
    required this.live,
    required this.state,
    required this.minute,
    required this.onExecuteTrade,
    required this.onToggleFavorite,
    required this.onSaveResearchNote,
    required this.onMarketSheetOpened,
    required this.onMarketSheetClosed,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final GameState state;
  final ValueNotifier<int> minute;
  final Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade;
  final Future<GameState> Function(String) onToggleFavorite;
  final Future<GameState> Function(String, String) onSaveResearchNote;
  final VoidCallback onMarketSheetOpened;
  final VoidCallback onMarketSheetClosed;

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

  Future<void> _openOrderSheet(bool isBuy) async {
    widget.onMarketSheetOpened();
    try {
      await _showOrderSheet(
        context,
        definition: definition,
        live: live,
        isBuy: isBuy,
        state: state,
        minute: minute,
        onExecuteTrade: onExecuteTrade,
      );
    } finally {
      widget.onMarketSheetClosed();
    }
  }

  bool get _isFavorite {
    final raw = state.story.storyFlags['marketFavoriteAssetIds'];
    return raw is List && raw.whereType<String>().contains(definition.id);
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

  Future<void> _editResearchNote() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResearchNoteEditor(
        companyName: definition.name,
        initialValue: _researchNote,
      ),
    );
    if (value == null || !mounted) return;
    try {
      final saved = await widget.onSaveResearchNote(definition.id, value);
      if (!mounted) return;
      setState(() => _state = saved);
      _showResearchMessage(
        context,
        value.trim().isEmpty ? '조사노트를 지웠어요.' : '조사노트를 저장했어요.',
      );
    } catch (_) {
      if (mounted) _showSaveFailure(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: minute,
      builder: (context, currentMinute, _) => _CrtTradingRoomScene(
        minute: currentMinute,
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
                              _TradingStatusRow(
                                quote: quote,
                                minute: currentMinute,
                              ),
                              const SizedBox(height: 14),
                              _MinuteChartPanel(
                                quote: quote,
                                code: definition.code,
                                minute: currentMinute,
                              ),
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
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            '오늘의 조사 질문',
                                            style: TextStyle(
                                              color: Color(0xFF8A6815),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
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
                                        color: Color(0xFF403617),
                                        fontSize: 14,
                                        height: 1.45,
                                        fontWeight: FontWeight.w800,
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
                              Text(
                                '일별 종가는 실제 기록이며, 시장을 보는 동안 현실 1초마다 게임 시각과 1분 틱이 한 칸씩 진행됩니다. 조사 설명은 DAY ${state.day}의 게임용 재현입니다.',
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
                                  key: const Key('sell-stock-button'),
                                  onPressed: definition.currency == 'KRW'
                                      ? () => _openOrderSheet(false)
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
                                  key: const Key('buy-stock-button'),
                                  onPressed: definition.currency == 'KRW'
                                      ? () => _openOrderSheet(true)
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

  static Future<void> _showOrderSheet(
    BuildContext context, {
    required _StockDefinition definition,
    required ValueNotifier<_LiveStock> live,
    required bool isBuy,
    required GameState state,
    required ValueNotifier<int> minute,
    required Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade,
  }) {
    return showModalBottomSheet<void>(
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
  static const _tradeSaveFailureMessage =
      '주문을 저장하지 못했어요. 저장 공간을 확인하고 다시 시도해 주세요.';

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
  int get _fee => gameTradingFeeForState(widget.state, _notional);
  double get _feeRate => gameTradingFeeRateForState(widget.state);
  int get _settlement => widget.isBuy ? _notional + _fee : _notional - _fee;
  double get _maxQuantity {
    if (!widget.isBuy) return _position?.units ?? 0;
    if (_executionPrice <= 0) return 0;
    var quantity = (widget.state.brokerageCash / _executionPrice).floor();
    while (quantity > 0) {
      final notional = (_executionPrice * quantity).round();
      final fee = gameTradingFeeForState(widget.state, notional);
      if (notional + fee <= widget.state.brokerageCash) {
        return quantity.toDouble();
      }
      quantity -= 1;
    }
    return 0;
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

  @override
  Widget build(BuildContext context) {
    final action = widget.isBuy ? '사기' : '팔기';
    final actionColor = widget.isBuy
        ? const Color(0xFF3182F6)
        : const Color(0xFFF04452);
    final maxQuantity = _maxQuantity;
    final canSubmit =
        _authorityReady &&
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
                '현재 게임 체결가 ${_displayPrice(_executionPrice, widget.definition.currency)} · 증권 수수료 ${(_feeRate * 100).toStringAsFixed(3)}%',
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
                                ? '주문 가능 예수금 ${_money(widget.state.brokerageCash)}원'
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
                    _OrderSummaryRow(label: '증권 수수료', value: _fee),
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
                  !_authorityReady
                      ? '직접 번 종잣돈 10,000원을 먼저 마련해야 보호자 주문 승인을 받을 수 있습니다.'
                      : !_tradable
                      ? '현재는 주문 가능한 거래 시간이 아닙니다.'
                      : widget.isBuy
                      ? '1주를 살 현금이 부족합니다.'
                      : '보유 수량이 없습니다.',
                  key: !_authorityReady
                      ? const Key('order-authority-warning')
                      : null,
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
                        _result?.success == true
                            ? '완료'
                            : !_authorityReady
                            ? '종잣돈 10,000원 달성 후 주문 가능'
                            : '부모님 승인으로 주문 실행',
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
    final time = isOpening ? '09:00' : '15:30';
    final title = isOpening ? '장이 시작되었습니다' : '장이 마감되었습니다';
    final description = isOpening
        ? '정규장이 열렸어요.\n이제 국내 종목의 움직임을 확인해 보세요.'
        : '정규장이 마감됐어요.\n오늘의 15:30 종가가 기준 가격으로 확정됐어요.';
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
                              fontWeight: FontWeight.w900,
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
                        fontWeight: FontWeight.w900,
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
                          style: TextStyle(fontWeight: FontWeight.w900),
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

class _MarketBottomNavigation extends StatelessWidget {
  const _MarketBottomNavigation({
    required this.selected,
    required this.onChanged,
  });

  final _MarketSection selected;
  final ValueChanged<_MarketSection> onChanged;

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
                color: active
                    ? const Color(0xFF3182F6)
                    : const Color(0xFFADB5BD),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? const Color(0xFF3182F6)
                      : const Color(0xFF8B95A1),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
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
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            action!,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
    ],
  );
}

class _MarketRankingTable extends StatelessWidget {
  const _MarketRankingTable({
    required this.stocks,
    required this.live,
    required this.onOpen,
  });

  final List<_StockDefinition> stocks;
  final Map<String, ValueNotifier<_LiveStock>> live;
  final ValueChanged<_StockDefinition> onOpen;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('market-ranking-table'),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7EBF0)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        const _MarketRankingHeader(),
        for (var index = 0; index < stocks.length; index++)
          _MarketRankingRow(
            key: Key('market-ranking-row-${stocks[index].code}'),
            rank: index + 1,
            definition: stocks[index],
            live: live[stocks[index].code]!,
            onTap: () => onOpen(stocks[index]),
          ),
      ],
    ),
  );
}

class _MarketRankingHeader extends StatelessWidget {
  const _MarketRankingHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    color: const Color(0xFFF7F8FA),
    child: const Row(
      children: [
        SizedBox(width: 26, child: Text('순위')),
        Expanded(flex: 5, child: Text('종목')),
        Expanded(flex: 4, child: Text('현재가', textAlign: TextAlign.right)),
        Expanded(flex: 3, child: Text('등락', textAlign: TextAlign.right)),
        Expanded(flex: 4, child: Text('거래대금', textAlign: TextAlign.right)),
      ],
    ),
  );
}

class _MarketRankingRow extends StatelessWidget {
  const _MarketRankingRow({
    super.key,
    required this.rank,
    required this.definition,
    required this.live,
    required this.onTap,
  });

  final int rank;
  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
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
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFEEF0F3), width: 1),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Color(0xFF7B8491),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        definition.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF252B35),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        definition.code,
                        style: const TextStyle(
                          color: Color(0xFF9AA1AB),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    _displayPrice(quote.price, definition.currency),
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF252B35),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(2)}%',
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: change.abs() < 0.005
                          ? const Color(0xFF7B8491)
                          : _priceColor(change),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    _compactEok(_simulatedTurnover(definition, quote)),
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF4D5968),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
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

class _BrokerageAccountCard extends StatelessWidget {
  const _BrokerageAccountCard({
    required this.state,
    required this.prices,
    this.onDeposit,
    this.onWithdraw,
  });

  final GameState state;
  final Map<String, double> prices;
  final VoidCallback? onDeposit;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final evaluation = state.portfolioValue(prices);
    final pnl = evaluation - state.portfolioCost;
    final rate = state.portfolioCost <= 0
        ? 0.0
        : pnl / state.portfolioCost * 100;
    final totalFees = state.ledger.fold<int>(
      0,
      (sum, entry) => sum + entry.tradingFee,
    );
    final realized = state.ledger.fold<int>(
      0,
      (sum, entry) => sum + entry.realizedPnl,
    );
    final pnlColor = _priceColor(pnl.toDouble());
    return Container(
      key: const Key('market-account-summary'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EDF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D101828),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '총 투자자산',
            style: TextStyle(
              color: Color(0xFF6B7684),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_money(state.brokerageCash + evaluation)}원',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '평가손익 ${pnl >= 0 ? '+' : ''}${_money(pnl)}원 · ${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(2)}%',
            key: const Key('market-account-pnl'),
            style: TextStyle(color: pnlColor, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AccountMetric(
                  label: '예수금',
                  value: '${_money(state.brokerageCash)}원',
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
          const Divider(height: 25),
          Text(
            '실현손익 ${realized >= 0 ? '+' : ''}${_money(realized)}원  ·  누적 증권 수수료 ${_money(totalFees)}원',
            key: const Key('market-account-fees'),
            style: const TextStyle(
              color: Color(0xFF6B7684),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '매수·매도 체결 시 기본 증권 수수료 0.250% 적용',
            style: TextStyle(
              color: Color(0xFF8B95A1),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('market-account-deposit'),
                  onPressed: onDeposit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('입금'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: OutlinedButton(
                  key: const Key('market-account-withdraw'),
                  onPressed: onWithdraw,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('출금'),
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
          fontWeight: FontWeight.w900,
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
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: definition.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      definition.name.substring(0, 1),
                      style: TextStyle(
                        color: definition.accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          definition.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_displayUnits(position.units)}주 · 평균 ${_money((position.totalCost / position.units).round())}원',
                          style: const TextStyle(
                            color: Color(0xFF8B95A1),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_money(evaluation)}원',
                        key: Key('position-value-${position.assetId}'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${pnl >= 0 ? '+' : ''}${_money(pnl)}원 · ${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(2)}%',
                        key: Key('position-rate-${position.assetId}'),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
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

class _EmptyPortfolioCard extends StatelessWidget {
  const _EmptyPortfolioCard({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('market-empty-portfolio'),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(Icons.savings_outlined, color: Color(0xFF3182F6), size: 30),
        const SizedBox(height: 8),
        const Text(
          '아직 보유한 주식이 없어요',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
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

  int get _maxAmount =>
      widget.deposit ? widget.state.bankCash : widget.state.brokerageCash;
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
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.deposit
                ? '회사 통장 ${_money(widget.state.bankCash)}원에서 옮겨요.'
                : '출금 가능 예수금은 ${_money(widget.state.brokerageCash)}원이에요.',
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
              backgroundColor: const Color(0xFF3182F6),
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

class _MarketMissionCard extends StatelessWidget {
  const _MarketMissionCard({required this.state, required this.onClaim});

  final GameState state;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final progress = const GameEngine().missionProgress(state);
    if (progress == null) return const SizedBox.shrink();
    final mission = progress.mission;
    return Container(
      key: const Key('market-mission-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: progress.complete ? const Color(0xFF4FA578) : _yellow,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: _coral, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  mission.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (progress.remainingDays != null)
                Text(
                  '${progress.remainingDays}일 남음',
                  style: const TextStyle(
                    color: _coral,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.ratio,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: const Color(0xFFE7E4D7),
            color: progress.complete ? const Color(0xFF4FA578) : _coral,
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${mission.objective} · ${progress.current.clamp(0, mission.target)}/${mission.target}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF626C79),
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (progress.complete) ...[
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('claim-market-mission'),
                  onPressed: onClaim,
                  child: Text(onClaim == null ? '저장 중' : '보상 받기'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ResearchNoteEditor extends StatefulWidget {
  const _ResearchNoteEditor({
    required this.companyName,
    required this.initialValue,
  });

  final String companyName;
  final String initialValue;

  @override
  State<_ResearchNoteEditor> createState() => _ResearchNoteEditorState();
}

class _ResearchNoteEditorState extends State<_ResearchNoteEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              '${widget.companyName}의 근거와 다음 행동을 직접 적어 두세요.',
              style: const TextStyle(color: Color(0xFF68717E), height: 1.4),
            ),
            const SizedBox(height: 14),
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
              onPressed: () => Navigator.of(context).pop(_controller.text),
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
    const labels = ['국내', '코스피', '코스닥', '해외', '관심'];
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
            _MarketSort.turnover: '게임 거래대금순',
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
    required this.favorite,
    required this.onTap,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final bool favorite;
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
                      if (favorite)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Color(0xFFFFB020),
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
  const _MinuteChartPanel({
    required this.quote,
    required this.code,
    required this.minute,
  });

  final _LiveStock quote;
  final String code;
  final int minute;

  @override
  State<_MinuteChartPanel> createState() => _MinuteChartPanelState();
}

class _MinuteChartPanelState extends State<_MinuteChartPanel> {
  static const intervals = <int>[1, 3, 5, 10, 15, 30, 60, 120, 240];
  int interval = 1;

  static const minuteWindows = <int, int>{
    1: 180,
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

  ({List<double> prices, int startMinute}) _visibleMinuteSeries() {
    final targetMinutes = minuteWindows[interval] ?? 60;
    final targetPoints = targetMinutes + 1;
    final sessionHistory = widget.quote.sessionHistory;
    if (!widget.quote.isTradingDay ||
        widget.minute < krxOpenMinute ||
        sessionHistory.length <= generatedPreOpenTicks) {
      return (prices: <double>[sessionHistory.last], startMinute: 0);
    }
    final visibleEnd = math.min(
      sessionHistory.length,
      generatedRegularSessionTicks + 1,
    );
    final prices = sessionHistory.sublist(generatedPreOpenTicks, visibleEnd);
    if (prices.length <= targetPoints) {
      return (prices: prices, startMinute: 0);
    }
    final startMinute = prices.length - targetPoints;
    return (prices: prices.sublist(startMinute), startMinute: startMinute);
  }

  List<double> _historicalCloses() {
    final buckets = <String, double>{};
    for (final point in widget.quote.history) {
      buckets[_historicalBucket(point)] = point.close;
    }
    final values = buckets.values.toList(growable: false);
    final limit = switch (period) {
      _ChartPeriod.day => 60,
      _ChartPeriod.week => 52,
      _ChartPeriod.month => 60,
      _ChartPeriod.year => 12,
      _ChartPeriod.minute => 0,
    };
    if (limit == 0 || values.length <= limit) return values;
    return values.sublist(values.length - limit);
  }

  String _historicalBucket(HistoricalMarketPoint point) {
    final date = point.parsedDate;
    return switch (period) {
      _ChartPeriod.day => point.date,
      _ChartPeriod.week => _chartDateKey(
        date.subtract(Duration(days: date.weekday - DateTime.monday)),
      ),
      _ChartPeriod.month =>
        '${date.year}-${date.month.toString().padLeft(2, '0')}',
      _ChartPeriod.year => '${date.year}',
      _ChartPeriod.minute => point.date,
    };
  }

  String _chartDateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  List<String> _minuteAxisLabels(int visiblePointCount) {
    if (widget.minute < krxOpenMinute) {
      return <String>['', '', '개장 전 ${marketTimeLabel(widget.minute)}'];
    }
    final endMinute = widget.minute.clamp(krxOpenMinute, krxCloseMinute);
    final elapsed = math.max(0, visiblePointCount - 1);
    final startMinute = math.max(krxOpenMinute, endMinute - elapsed);
    final middleMinute = startMinute + (endMinute - startMinute) ~/ 2;
    return <String>[
      marketTimeLabel(startMinute),
      marketTimeLabel(middleMinute),
      marketTimeLabel(endMinute),
    ];
  }

  List<String> _historicalAxisLabels() {
    final keys = <String>[];
    String? lastKey;
    for (final point in widget.quote.history) {
      final key = _historicalBucket(point);
      if (key == lastKey) continue;
      keys.add(key);
      lastKey = key;
    }
    final limit = switch (period) {
      _ChartPeriod.day => 60,
      _ChartPeriod.week => 52,
      _ChartPeriod.month => 60,
      _ChartPeriod.year => 12,
      _ChartPeriod.minute => 0,
    };
    final visible = limit > 0 && keys.length > limit
        ? keys.sublist(keys.length - limit)
        : keys;
    final formatted = visible.map(_formatHistoricalAxisLabel).toList();
    return _axisTriplet(formatted);
  }

  String _formatHistoricalAxisLabel(String key) {
    return switch (period) {
      _ChartPeriod.day || _ChartPeriod.week =>
        key.length >= 10 ? key.substring(5).replaceAll('-', '.') : key,
      _ChartPeriod.month => key.replaceAll('-', '.'),
      _ChartPeriod.year => key,
      _ChartPeriod.minute => key,
    };
  }

  List<String> _axisTriplet(List<String> values) {
    if (values.isEmpty) return const <String>['', '', ''];
    return <String>[values.first, values[values.length ~/ 2], values.last];
  }

  String _windowLabel({
    required int candleCount,
    required int historicalCount,
  }) {
    if (period != _ChartPeriod.minute) {
      return switch (period) {
        _ChartPeriod.day => '일봉 · 최근 $historicalCount거래일 · 실제 종가 기반',
        _ChartPeriod.week => '주봉 · 최근 $historicalCount주 · 실제 종가 기반',
        _ChartPeriod.month => '월봉 · 최근 $historicalCount개월 · 실제 종가 기반',
        _ChartPeriod.year => '년봉 · 최근 $historicalCount년 · 실제 종가 기반',
        _ChartPeriod.minute => '',
      };
    }
    final window = minuteWindows[interval] ?? 60;
    final windowText = switch (window) {
      60 => '최대 최근 1시간',
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
    return '$interval분봉 · $windowText · $candleCount개 캔들';
  }

  @override
  Widget build(BuildContext context) {
    final minuteSeries = _visibleMinuteSeries();
    final minutePrices = minuteSeries.prices;
    final candleSeed = widget.quote.history.isEmpty
        ? widget.code.codeUnits.fold<int>(17, (sum, unit) => sum * 31 + unit)
        : marketStockSeed(widget.code, widget.quote.history.last.parsedDate);
    final candles = period == _ChartPeriod.minute
        ? aggregateMarketCandles(
            minutePrices,
            interval,
            tickMinutes: marketTickMinutes,
            seed: candleSeed,
            startMinuteOffset: minuteSeries.startMinute,
          )
        : const <MarketCandle>[];
    final historicalCloses = period == _ChartPeriod.minute
        ? const <double>[]
        : _historicalCloses();
    final axisLabels = period == _ChartPeriod.minute
        ? _minuteAxisLabels(minutePrices.length)
        : _historicalAxisLabels();
    return Column(
      children: [
        SizedBox(
          height: 268,
          child: CustomPaint(
            key: Key(
              period == _ChartPeriod.minute
                  ? 'minute-candle-chart'
                  : 'historical-close-chart',
            ),
            painter: period == _ChartPeriod.minute
                ? _CandleChartPainter(
                    candles: candles,
                    previousClose: widget.quote.previousClose,
                  )
                : _HistoricalCloseChartPainter(values: historicalCloses),
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
              candleCount: candles.length,
              historicalCount: historicalCloses.length,
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
    required this.previousClose,
  });

  final List<MarketCandle> candles;
  final double previousClose;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty || size.isEmpty) return;
    const axisWidth = 48.0;
    const priceTop = 22.0;
    final chartRight = math.max(1.0, size.width - axisWidth);
    final volumeTop = size.height * 0.79;
    final volumeBottom = size.height - 4;
    final priceBottom = volumeTop - 16;
    final priceHeight = math.max(1.0, priceBottom - priceTop);
    final values = candles
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
    for (var line = 1; line < 5; line++) {
      final x = chartRight * line / 5;
      canvas.drawLine(Offset(x, priceTop), Offset(x, volumeBottom), gridPaint);
    }

    if (previousClose >= minValue && previousClose <= maxValue) {
      final baselineY = yFor(previousClose);
      final baselinePaint = Paint()
        ..color = const Color(0xFFC2C8D0)
        ..strokeWidth = 1;
      for (var x = 0.0; x < chartRight; x += 7) {
        canvas.drawLine(
          Offset(x, baselineY),
          Offset(math.min(x + 3, chartRight), baselineY),
          baselinePaint,
        );
      }
    }

    final visible = candles;
    final slot = chartRight / math.max(visible.length, 1);
    final bodyWidth = math.max(1.6, math.min(6.0, slot * 0.62));
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, priceTop, chartRight, priceBottom));
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

    List<double?> movingAverage(int count) {
      final values = List<double?>.filled(visible.length, null);
      var sum = 0.0;
      for (var index = 0; index < visible.length; index++) {
        sum += visible[index].close;
        if (index >= count) sum -= visible[index - count].close;
        if (index >= count - 1) values[index] = sum / count;
      }
      return values;
    }

    void drawMovingAverage(int count, Color color, double width) {
      final average = movingAverage(count);
      final path = Path();
      var started = false;
      for (var index = 0; index < average.length; index++) {
        final value = average[index];
        if (value == null) continue;
        final point = Offset(slot * index + slot / 2, yFor(value));
        if (!started) {
          path.moveTo(point.dx, point.dy);
          started = true;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      if (!started) return;
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    drawMovingAverage(5, const Color(0xFF00A99D), 1.25);
    drawMovingAverage(20, const Color(0xFFF04452), 1.15);
    drawMovingAverage(60, const Color(0xFFFF8A00), 1.1);
    drawMovingAverage(120, const Color(0xFF8B3FD1), 1.05);
    canvas.restore();

    drawText('이동평균', const Offset(2, 2), fontSize: 8);
    drawText(
      '5',
      const Offset(39, 2),
      color: const Color(0xFF00A99D),
      fontSize: 8,
      fontWeight: FontWeight.w900,
    );
    drawText(
      '20',
      const Offset(50, 2),
      color: const Color(0xFFF04452),
      fontSize: 8,
      fontWeight: FontWeight.w900,
    );
    drawText(
      '60',
      const Offset(67, 2),
      color: const Color(0xFFFF8A00),
      fontSize: 8,
      fontWeight: FontWeight.w900,
    );
    drawText(
      '120',
      const Offset(85, 2),
      color: const Color(0xFF8B3FD1),
      fontSize: 8,
      fontWeight: FontWeight.w900,
    );

    final current = visible.last.close;
    final currentY = yFor(current).clamp(priceTop, priceBottom);
    final currentPaint = Paint()
      ..color = const Color(0xFF3182F6)
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
    canvas.drawRRect(priceLabelRect, Paint()..color = const Color(0xFF3182F6));
    drawText(
      _money(current.round()),
      Offset(chartRight + 4, currentY - 5.5),
      color: Colors.white,
      fontSize: 8,
      fontWeight: FontWeight.w900,
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
      oldDelegate.previousClose != previousClose;
}

class _HistoricalCloseChartPainter extends CustomPainter {
  const _HistoricalCloseChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.isEmpty) return;
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

    final linePath = Path();
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width
          : size.width * index / (values.length - 1);
      final point = Offset(x, yFor(values[index]));
      if (index == 0) {
        linePath.moveTo(point.dx, point.dy);
      } else {
        linePath.lineTo(point.dx, point.dy);
      }
    }
    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x453182F6), Color(0x003182F6)],
        ).createShader(Offset.zero & size),
    );
    final linePaint = Paint()
      ..color = const Color(0xFF3182F6)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);
    canvas.drawCircle(
      Offset(size.width, yFor(values.last)),
      3.5,
      Paint()..color = const Color(0xFF3182F6),
    );
  }

  @override
  bool shouldRepaint(covariant _HistoricalCloseChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _TradingStatusRow extends StatelessWidget {
  const _TradingStatusRow({required this.quote, required this.minute});

  final _LiveStock quote;
  final int minute;

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
          !quote.isTradingDay
              ? '장 마감'
              : minute < krxOpenMinute
              ? '개장 전 · 09:00부터 1분봉 생성'
              : minute >= krxCloseMinute
              ? '정규장 마감 · 15:30 종가 고정'
              : '재현 장중 · 현실 1초마다 게임 1분 진행',
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
              color: selected
                  ? const Color(0xFF3182F6)
                  : const Color(0xFF9399A3),
              fontSize: 11,
              fontWeight: FontWeight.w800,
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
  final List<HistoricalMarketPoint> history;
  final List<double> sessionHistory;
  final List<double> sessionPath;

  _LiveStock copyWith({
    double? price,
    double? high,
    double? low,
    List<HistoricalMarketPoint>? history,
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
