part of 'main.dart';

enum _MarketSort { turnover, gainers, losers, name }

enum _MarketSection { home, explore, account }

enum _ChartPeriod { minute, day, week, month, year }

class _PlayerTradeSignal {
  const _PlayerTradeSignal({
    required this.assetId,
    required this.side,
    required this.quantity,
    required this.price,
    required this.marketMinute,
  });

  final String assetId;
  final TradeSide side;
  final double quantity;
  final double price;
  final int marketMinute;
}

const _marketInk = Color(0xFF191F28);
const _marketMuted = Color(0xFF6B7684);
const _marketLine = Color(0xFFE8EBEF);
const _marketSurface = Color(0xFFF7F8FA);
const _marketAccent = Color(0xFF356FE5);
const _marketNumberFeatures = <ui.FontFeature>[ui.FontFeature.tabularFigures()];

class _CrtTradingRoomScene extends StatelessWidget {
  const _CrtTradingRoomScene({required this.minute, required this.child});

  final int minute;
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
                    _MarketPhoneStatusBar(minute: minute),
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

class StockMarketScreen extends StatefulWidget {
  const StockMarketScreen({
    super.key,
    required this.state,
    this.onExecuteTrade,
    this.onCancelPendingOrder,
    this.onTransferCash,
    this.onSetMarketMinute,
    this.onSaveMarketNotebook,
    this.onPurchaseReport,
    this.onCompleteTutorial,
    this.universe,
  });

  final GameState state;
  final Future<GameState> Function(int)? onSetMarketMinute;
  final Future<GameState> Function(Set<String>, Map<String, String>)?
  onSaveMarketNotebook;
  final Future<FinanceActionResult> Function()? onPurchaseReport;
  final Future<GameState> Function()? onCompleteTutorial;
  final Future<TradeExecutionResult> Function(TradeOrder)? onExecuteTrade;
  final Future<FinanceActionResult> Function(String orderId)?
  onCancelPendingOrder;
  final Future<FinanceActionResult> Function(int amount, bool deposit)?
  onTransferCash;
  final FictionalMarketUniverse? universe;

  @override
  State<StockMarketScreen> createState() => _StockMarketScreenState();
}

class _StockMarketScreenState extends State<StockMarketScreen>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final Map<String, ValueNotifier<_LiveStock>> _live = {};
  List<_StockDefinition> _stocks = const [];
  Timer? _timer;
  final ValueNotifier<_MarketPlaybackSpeed> _playbackSpeedNotifier =
      ValueNotifier(_MarketPlaybackSpeed.normal);
  final ValueNotifier<_PlayerTradeSignal?> _playerTradeNotifier = ValueNotifier(
    null,
  );
  Future<void> _marketMutationTail = Future<void>.value();
  bool _isRealtimeBatchUpdating = false;
  bool _isLifecyclePaused = false;
  bool _isLifecycleSaving = false;
  final ValueNotifier<int> _minute = ValueNotifier(marketDayStartMinute);
  int _tick = 0;
  late int _marketMinute;
  late final ValueNotifier<GameState> _marketStateNotifier;
  GameState get _state => _marketStateNotifier.value;
  set _state(GameState value) => _marketStateNotifier.value = value;

  int _tab = 0;
  _MarketSort _sort = _MarketSort.turnover;
  _MarketSection _section = _MarketSection.home;
  bool _loading = true;
  double _loadProgress = 0.08;
  String _loadStage = '가상 기업 명단을 확인하는 중…';
  String? _loadError;
  bool _isClosing = false;
  bool _allowPop = false;
  bool _isAdvancingHour = false;
  bool _closeAfterHourAdvance = false;
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
  bool _isMarketSheetOpen = false;
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

  List<_PlayerTradeSignal> _newTradeSignals(
    GameState before,
    GameState after,
  ) => after.ledger
      .skip(before.ledger.length)
      .where(
        (entry) =>
            entry.assetId.isNotEmpty &&
            entry.tradeQuantity > 0 &&
            entry.tradeUnitPrice > 0 &&
            (entry.tradeSide == TradeSide.buy.name ||
                entry.tradeSide == TradeSide.sell.name),
      )
      .map(
        (entry) => _PlayerTradeSignal(
          assetId: entry.assetId,
          side: entry.tradeSide == TradeSide.buy.name
              ? TradeSide.buy
              : TradeSide.sell,
          quantity: entry.tradeQuantity,
          price: entry.tradeUnitPrice,
          marketMinute: entry.marketMinute,
        ),
      )
      .toList(growable: false);

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
    _marketStateNotifier = ValueNotifier(widget.state);
    _marketMinute = _state.marketMinute;
    _minute.value = _marketMinute;
    _tick = marketTickForMinute(_marketMinute);
    _tutorialStep =
        _state.story.marketTutorialEligible &&
            !_state.story.marketTutorialSeen &&
            widget.onCompleteTutorial != null
        ? 0
        : null;
    _loadFictionalMarket();
  }

  Future<void> _loadFictionalMarket({bool forceRefresh = false}) async {
    final stopwatch = Stopwatch()..start();
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
    try {
      // Give the browser a chance to paint the progress card before any
      // deterministic market generation begins.
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      setState(() {
        _loadProgress = 0.12;
        _loadStage = '${_state.currentDate.year}년 기업과 거래일을 만드는 중…';
      });
      final universe =
          widget.universe ??
          await FictionalMarketUniverse.load(
            seed: _state.simulationSeed,
            throughDate: _state.currentDate,
            forceRefresh: forceRefresh,
          );
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
          final previousClose =
              asset.previousCloseBefore(quote.date) ?? quote.close;
          final history = asset.historyThrough(_state.currentDate);
          loaded.add(stock);
          final path = quote.isExactDate
              ? generatedMarketDayPathForAsset(
                  asset: asset,
                  simulationSeed: _state.simulationSeed,
                  date: _state.currentDate,
                  previousClose: previousClose,
                  officialClose: quote.close,
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
      setState(() {
        _stocks = loaded;
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
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _loading = false;
      });
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
    if (mounted) setState(() {});
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
        if (stateBeforeMinute.pendingOrders.isNotEmpty && callback != null) {
          try {
            final next = await _runMarketMutation(
              () => callback(_marketMinute),
            );
            if (!mounted) return;
            _state = next;
            final fills = _newTradeSignals(stateBeforeMinute, next);
            if (fills.isNotEmpty) {
              _playerTradeNotifier.value = fills.last;
              _pausePlaybackWithoutRebuild();
              pauseMessage = '내 지정가 주문이 체결되어 시장 시간을 일시정지했어요.';
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
        if (largeMove) {
          _pausePlaybackWithoutRebuild();
          pauseMessage = '1분 급등락이 감지되어 시장 시간을 일시정지했어요.';
          break;
        }
      }
    } finally {
      _isRealtimeBatchUpdating = false;
      if (mounted) setState(() {});
    }
    if (pauseMessage != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(pauseMessage)));
    }
  }

  bool _advanceOneMarketMinute() {
    if (_isExecutingTrade ||
        _isTransferringCash ||
        _isClosing ||
        _marketMinute >= krxCloseMinute ||
        _tick >= krxCloseTick) {
      return false;
    }
    _tick += 1;
    _marketMinute = marketMinuteForTick(_tick);
    _minute.value = _marketMinute;
    var largeMove = false;
    for (var index = 0; index < _stocks.length; index++) {
      final notifier = _live[_stocks[index].code]!;
      final current = notifier.value;
      if (!current.isTradingDay) continue;
      final nextPrice = current.sessionPath[_tick];
      current.sessionHistory.add(nextPrice);
      if (current.price > 0 &&
          ((nextPrice - current.price) / current.price).abs() >= 0.03) {
        largeMove = true;
      }
      notifier.value = current.copyWith(
        price: nextPrice,
        high: nextPrice > current.high ? nextPrice : current.high,
        low: nextPrice < current.low ? nextPrice : current.low,
      );
    }
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
    unawaited(_showBreakingNewsEvents(events, previousMinute, currentMinute));
  }

  Future<void> _showBreakingNewsEvents(
    List<FictionalMarketEvent> events,
    int previousMinute,
    int currentMinute,
  ) async {
    if (!mounted || _isShowingBreakingNews) return;
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
    setState(() {});
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
      _handleMarketTimeCrossed(previousMinute, _marketMinute);
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
      final result = await _runMarketMutation(() async {
        final synced = await widget.onSetMarketMinute?.call(order.marketMinute);
        if (synced != null) _state = synced;
        return callback(order);
      });
      if (result.success && result.filledQuantity > 0) {
        _playerTradeNotifier.value = _PlayerTradeSignal(
          assetId: order.assetId,
          side: order.side,
          quantity: result.filledQuantity,
          price: result.averageFillPrice,
          marketMinute: order.marketMinute,
        );
      }
      if (result.success && mounted) {
        _timer?.cancel();
        _timer = null;
        setState(() {
          _state = result.state;
          _playbackSpeed = _MarketPlaybackSpeed.paused;
        });
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _StockDetailScreen(
          definition: stock,
          live: _live[stock.code]!,
          marketState: _marketStateNotifier,
          playerTrade: _playerTradeNotifier,
          minute: _minute,
          playbackSpeed: _playbackSpeedNotifier,
          onPlaybackSpeedChanged: _setPlaybackSpeed,
          onExecuteTrade: _executeTrade,
          onToggleFavorite: _toggleFavorite,
          onSaveResearchNote: _saveResearchNote,
          onMarketSheetOpened: _pauseMarketForSheet,
          onMarketSheetClosed: _resumeMarketAfterSheet,
          tutorialEnabled: fromTutorial,
          onCompleteTutorial: _completeMarketTutorial,
        ),
      ),
    );
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
    final reportItems = _dailyReportItems;
    return ListView(
      key: const Key('market-home-section'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        _DailyMarketReportCard(
          items: reportItems,
          cash: _state.cash,
          purchasing: _isPurchasingReport,
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
            fontWeight: FontWeight.w700,
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
                            _isRealtimeBatchUpdating ||
                            _isPurchasingReport ||
                            _marketNotebookSaveCount > 0 ||
                            _isClosing ||
                            _isExecutingTrade ||
                            _marketMinute >= krxCloseMinute
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
                            _marketMinute >= krxOpenMinute
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
                            _marketMinute < krxOpenMinute ||
                            _marketMinute >= krxCloseMinute
                        ? null
                        : _jumpToMarketClose,
                  ),
                  _MarketPlaybackBar(
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
                        _marketMinute < krxCloseMinute,
                    onChanged: _setPlaybackSpeed,
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
                            onChanged: (value) => setState(() => _sort = value),
                          ),
                          const SizedBox(height: 10),
                          ...visibleStocks.map((stock) {
                            final row = _StockRow(
                              key: Key('stock-row-${stock.code}'),
                              definition: stock,
                              live: _live[stock.code]!,
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
                          }),
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
    required this.playbackSpeed,
    required this.onPlaybackSpeedChanged,
    required this.onExecuteTrade,
    required this.onToggleFavorite,
    required this.onSaveResearchNote,
    required this.onMarketSheetOpened,
    required this.onMarketSheetClosed,
    this.tutorialEnabled = false,
    this.onCompleteTutorial,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final ValueListenable<GameState> marketState;
  final ValueListenable<_PlayerTradeSignal?> playerTrade;
  final ValueNotifier<int> minute;
  final ValueNotifier<_MarketPlaybackSpeed> playbackSpeed;
  final ValueChanged<_MarketPlaybackSpeed> onPlaybackSpeedChanged;
  final Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade;
  final Future<GameState> Function(String) onToggleFavorite;
  final Future<GameState> Function(String, String) onSaveResearchNote;
  final VoidCallback onMarketSheetOpened;
  final VoidCallback onMarketSheetClosed;
  final bool tutorialEnabled;
  final Future<GameState> Function()? onCompleteTutorial;

  @override
  State<_StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<_StockDetailScreen> {
  late GameState _state;
  final ScrollController _detailScrollController = ScrollController();
  final GlobalKey _tutorialPriceKey = GlobalKey();
  final GlobalKey _tutorialBuyKey = GlobalKey();
  final GlobalKey _tutorialOrderBookHeaderKey = GlobalKey();
  final GlobalKey _tutorialBestAskKey = GlobalKey();
  int? _tutorialStep;
  TradeSide? _lastPlayerTradeSide;
  double _lastPlayerTradeQuantity = 0;
  double _lastPlayerTradePrice = 0;
  int _lastPlayerTradeMinute = -1;

  _StockDefinition get definition => widget.definition;
  ValueNotifier<_LiveStock> get live => widget.live;
  GameState get state => _state;
  ValueNotifier<int> get minute => widget.minute;

  @override
  void initState() {
    super.initState();
    _state = widget.marketState.value;
    widget.marketState.addListener(_synchronizeMarketState);
    widget.playerTrade.addListener(_synchronizePlayerTrade);
    _synchronizePlayerTrade();
    _tutorialStep = widget.tutorialEnabled ? 0 : null;
  }

  void _synchronizeMarketState() {
    if (!mounted) return;
    setState(() => _state = widget.marketState.value);
  }

  void _synchronizePlayerTrade() {
    final signal = widget.playerTrade.value;
    if (signal == null || signal.assetId != definition.id) return;
    void synchronize() {
      _lastPlayerTradeSide = signal.side;
      _lastPlayerTradeQuantity = signal.quantity;
      _lastPlayerTradePrice = signal.price;
      _lastPlayerTradeMinute = signal.marketMinute;
    }

    if (mounted) {
      setState(synchronize);
    } else {
      synchronize();
    }
  }

  @override
  void dispose() {
    widget.marketState.removeListener(_synchronizeMarketState);
    widget.playerTrade.removeListener(_synchronizePlayerTrade);
    _detailScrollController.dispose();
    super.dispose();
  }

  Future<TradeExecutionResult> onExecuteTrade(TradeOrder order) async {
    final result = await widget.onExecuteTrade(order);
    if (result.success && mounted) {
      setState(() {
        _state = result.state;
        if (result.filledQuantity > 0) {
          _lastPlayerTradeSide = order.side;
          _lastPlayerTradeQuantity = result.filledQuantity;
          _lastPlayerTradePrice = result.averageFillPrice;
          _lastPlayerTradeMinute = order.marketMinute;
        }
      });
    }
    return result;
  }

  Future<void> _openOrderSheet(
    bool isBuy, {
    bool fromTutorial = false,
    double? limitPrice,
  }) async {
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
        initialOrderType: limitPrice == null ? null : TradeOrderType.limit,
        initialLimitPrice: limitPrice,
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
    }
    if (fromTutorial && _tutorialStep == null && mounted) {
      await Navigator.of(context).maybePop();
    }
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

  double _tutorialBestAskPrice() {
    final quote = live.value;
    final snapshot = buildGameOrderBookSnapshot(
      assetId: definition.id,
      day: state.day,
      minute: minute.value,
      currentPrice: quote.price,
      previousClose: quote.previousClose,
      date: state.currentDate,
      market: definition.market,
      tradingDay: quote.isTradingDay,
    );
    return snapshot.asks.isEmpty ? quote.price : snapshot.asks.first.price;
  }

  void _handleDetailTutorialAction() {
    switch (_tutorialStep) {
      case 0:
        setState(() => _tutorialStep = 1);
        _scrollDetailTutorialTo(620);
        return;
      case 1:
        setState(() => _tutorialStep = 2);
        _scrollDetailTutorialTo(40);
        return;
      case 2:
        setState(() => _tutorialStep = 3);
        _scrollDetailTutorialTo(170);
        return;
      case 3:
        unawaited(
          _openOrderSheet(
            true,
            fromTutorial: true,
            limitPrice: _tutorialBestAskPrice(),
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
    final scene = ValueListenableBuilder<int>(
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
                    final financial = definition.financialAt(state.currentDate);
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
                                        fontWeight: FontWeight.w700,
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
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                            controller: _detailScrollController,
                            children: [
                              RepaintBoundary(
                                key: _tutorialPriceKey,
                                child: Hero(
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
                                        color: _marketInk,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -1.2,
                                        fontFeatures: _marketNumberFeatures,
                                      ),
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
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: _marketNumberFeatures,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _TradingStatusRow(
                                quote: quote,
                                minute: currentMinute,
                              ),
                              const SizedBox(height: 14),
                              _OrderBookPanel(
                                definition: definition,
                                quote: quote,
                                state: state,
                                minute: currentMinute,
                                playerTradeSide: _lastPlayerTradeSide,
                                playerTradeQuantity: _lastPlayerTradeQuantity,
                                playerTradePrice: _lastPlayerTradePrice,
                                playerTradeMinute: _lastPlayerTradeMinute,
                                tutorialHeaderKey: _tutorialOrderBookHeaderKey,
                                tutorialBestAskKey: _tutorialBestAskKey,
                                onTapLevel: (level) => unawaited(
                                  _openOrderSheet(
                                    level.side == GameOrderBookSide.ask,
                                    limitPrice: level.price,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _MinuteChartPanel(
                                quote: quote,
                                code: definition.code,
                                minute: currentMinute,
                              ),
                              const SizedBox(height: 24),
                              _QuoteGrid(quote: quote),
                              if (financial != null) ...[
                                const SizedBox(height: 18),
                                _CompanyFundamentalsCard(
                                  snapshot: financial,
                                  price: quote.price,
                                  relations: definition.relations,
                                ),
                              ],
                              const SizedBox(height: 28),
                              const Divider(color: Color(0xFFF0F1F3)),
                              const SizedBox(height: 20),
                              const Text(
                                '이 회사를 한 문장으로',
                                style: TextStyle(
                                  color: Color(0xFF202632),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
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

                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F6FA),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _marketLine),
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
                              Text(
                                '일별 종가와 사건은 이 세이브의 세계 시드로 고정됩니다. 같은 세이브에서는 다시 뽑히지 않으며, 새 게임에서는 다른 미래가 펼쳐집니다.',
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
                                          '현재 거래할 수 없는 종목입니다.',
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
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: RepaintBoundary(
                                  key: _tutorialBuyKey,
                                  child: FilledButton(
                                    key: const Key('buy-stock-button'),
                                    onPressed: definition.currency == 'KRW'
                                        ? () => _openOrderSheet(true)
                                        : () => _showResearchMessage(
                                            context,
                                            '현재 거래할 수 없는 종목입니다.',
                                          ),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                      backgroundColor: _marketAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: const Text(
                                      '사기',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
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
    return PopScope<void>(
      canPop: _tutorialStep == null,
      child: Stack(
        children: [
          Positioned.fill(child: scene),
          if (_tutorialStep != null)
            Positioned.fill(
              child: _MarketDetailTutorialOverlay(
                step: _tutorialStep!,
                targetKey: switch (_tutorialStep) {
                  0 => _tutorialPriceKey,
                  2 => _tutorialOrderBookHeaderKey,
                  3 => _tutorialBestAskKey,
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
    required GameState state,
    required ValueNotifier<int> minute,
    required Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade,
    TradeOrderType? initialOrderType,
    double? initialLimitPrice,
    bool tutorialEnabled = false,
    Future<void> Function()? onCompleteTutorial,
  }) {
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
                    sourceState: state,
                    initialBuyLimitPrice: initialLimitPrice,
                    onCompleteTutorial: onCompleteTutorial,
                  )
                : _OrderSheet(
                    definition: definition,
                    live: live,
                    isBuy: isBuy,
                    state: state,
                    minute: minute,
                    onExecuteTrade: onExecuteTrade,
                    initialOrderType: initialOrderType,
                    initialLimitPrice: initialLimitPrice,
                  );
            if (!tutorialEnabled) return orderSheet;
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

class _CompanyFundamentalsCard extends StatelessWidget {
  const _CompanyFundamentalsCard({
    required this.snapshot,
    required this.price,
    required this.relations,
  });

  final FictionalFinancialSnapshot snapshot;
  final double price;
  final List<FictionalCompanyRelation> relations;

  @override
  Widget build(BuildContext context) {
    final marketCap = (price * snapshot.sharesOutstanding).round();
    final per = snapshot.eps <= 0 ? null : price / snapshot.eps;
    final pbr = snapshot.bps <= 0 ? null : price / snapshot.bps;
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
    this.tone,
  });

  final String label;
  final String value;
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

enum _PracticalTradeTutorialPhase {
  buy,
  priceMove,
  sell,
  summary,
  review,
  dismissal,
}

class _PracticalTradeTutorialSheet extends StatefulWidget {
  const _PracticalTradeTutorialSheet({
    required this.definition,
    required this.sourceLive,
    required this.sourceState,
    required this.initialBuyLimitPrice,
    required this.onCompleteTutorial,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> sourceLive;
  final GameState sourceState;
  final double? initialBuyLimitPrice;
  final Future<void> Function()? onCompleteTutorial;

  @override
  State<_PracticalTradeTutorialSheet> createState() =>
      _PracticalTradeTutorialSheetState();
}

class _PracticalTradeTutorialSheetState
    extends State<_PracticalTradeTutorialSheet> {
  static const _practiceSeedMoney = 1000000;
  static const _practiceMinute = krxOpenMinute + 10;
  static const _engine = GameEngine();

  late GameState _practiceState;
  late final ValueNotifier<_LiveStock> _practiceLive;
  late final ValueNotifier<int> _practiceMinuteNotifier;
  _PracticalTradeTutorialPhase _phase = _PracticalTradeTutorialPhase.buy;
  double _buyPrice = 0;
  double _sellPrice = 0;
  int _realizedPnl = 0;
  bool _finishing = false;
  bool _allowPop = false;
  Timer? _priceMoveTimer;
  List<double> _priceMovePath = const <double>[];
  int _priceMoveStep = 0;

  bool get _priceMoveComplete =>
      _priceMovePath.isNotEmpty && _priceMoveStep >= _priceMovePath.length - 1;

  @override
  void initState() {
    super.initState();
    var practiceDay = widget.sourceState.day;
    for (var offset = 0; offset < 14; offset += 1) {
      if (isMarketTradingDay(widget.sourceState.dateForDay(practiceDay))) {
        break;
      }
      practiceDay += 1;
    }
    final sourceQuote = widget.sourceLive.value;
    _practiceLive = ValueNotifier<_LiveStock>(
      _LiveStock(
        price: sourceQuote.price,
        previousClose: sourceQuote.previousClose,
        officialClose: sourceQuote.officialClose,
        isTradingDay: true,
        open: sourceQuote.open,
        high: sourceQuote.high,
        low: sourceQuote.low,
        history: List<MarketPoint>.from(sourceQuote.history),
        sessionHistory: List<double>.from(sourceQuote.sessionHistory),
        sessionPath: List<double>.from(sourceQuote.sessionPath),
      ),
    );
    _practiceMinuteNotifier = ValueNotifier<int>(_practiceMinute);
    _practiceState = widget.sourceState.copyWith(
      day: practiceDay,
      marketMinute: _practiceMinute,
      cash: _practiceSeedMoney,
      brokerageCash: _practiceSeedMoney,
      positions: const <PortfolioPosition>[],
      pendingOrders: const <PendingTradeOrder>[],
      story: widget.sourceState.story.copyWith(accountAuthorityLevel: 5),
      ledger: const <LedgerEntry>[],
    );
  }

  @override
  void dispose() {
    _priceMoveTimer?.cancel();
    _practiceLive.dispose();
    _practiceMinuteNotifier.dispose();
    super.dispose();
  }

  Future<TradeExecutionResult> _executePracticeOrder(TradeOrder order) async {
    final result = _engine.executeTrade(_practiceState, order);
    if (result.success && mounted) {
      setState(() {
        _practiceState = result.state;
        if (order.side == TradeSide.sell) {
          _realizedPnl = result.realizedPnl;
        }
      });
    }
    return result;
  }

  void _showPriceMove() {
    final position = _practiceState.positions
        .where((item) => item.assetId == widget.definition.id)
        .firstOrNull;
    _buyPrice = position?.averageCost ?? _practiceLive.value.price;
    const ratePath = <double>[1.0, 1.012, 1.006, 1.025, 1.041, 1.06];
    _priceMovePath = ratePath
        .map(
          (rate) => marketSnapPrice(
            _buyPrice * rate,
            market: widget.definition.market,
          ),
        )
        .toList(growable: false);
    _priceMoveStep = 0;
    _sellPrice = _priceMovePath.first;
    final openingQuote = _practiceLive.value;
    _practiceLive.value = openingQuote.copyWith(
      price: _sellPrice,
      high: math.max(openingQuote.high, _sellPrice),
      low: math.min(openingQuote.low, _sellPrice),
      sessionHistory: <double>[...openingQuote.sessionHistory, _sellPrice],
    );
    setState(() => _phase = _PracticalTradeTutorialPhase.priceMove);

    _priceMoveTimer?.cancel();
    _priceMoveTimer = Timer.periodic(const Duration(milliseconds: 800), (
      timer,
    ) {
      if (!mounted || _phase != _PracticalTradeTutorialPhase.priceMove) {
        timer.cancel();
        return;
      }
      final nextStep = _priceMoveStep + 1;
      if (nextStep >= _priceMovePath.length) {
        timer.cancel();
        return;
      }
      final nextPrice = _priceMovePath[nextStep];
      final nextMinute = _practiceMinute + nextStep * 5;
      final quote = _practiceLive.value;
      setState(() {
        _priceMoveStep = nextStep;
        _sellPrice = nextPrice;
        _practiceState = _practiceState.copyWith(marketMinute: nextMinute);
        _practiceMinuteNotifier.value = nextMinute;
        _practiceLive.value = quote.copyWith(
          price: nextPrice,
          high: math.max(quote.high, nextPrice),
          low: math.min(quote.low, nextPrice),
          sessionHistory: <double>[...quote.sessionHistory, nextPrice],
        );
      });
      if (_priceMoveComplete) timer.cancel();
    });
  }

  void _openSellPractice() {
    if (!_priceMoveComplete) return;
    _priceMoveTimer?.cancel();
    setState(() => _phase = _PracticalTradeTutorialPhase.sell);
  }

  void _showSummary() {
    setState(() => _phase = _PracticalTradeTutorialPhase.summary);
  }

  void _showReview() {
    setState(() => _phase = _PracticalTradeTutorialPhase.review);
  }

  void _showDismissal() {
    setState(() => _phase = _PracticalTradeTutorialPhase.dismissal);
  }

  Future<void> _finishTutorial() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await widget.onCompleteTutorial?.call();
      if (!mounted) return;
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('튜토리얼 완료 기록을 저장하지 못했어요. 다시 시도해 주세요.')),
        );
    }
  }

  Widget _practiceHeader({
    required String phaseLabel,
    required String description,
  }) => Container(
    key: const Key('tutorial-seed-balance'),
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 2),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: <Color>[Color(0xFFFFF7D6), Color(0xFFFFE49A)],
      ),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE7BE45)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.school_rounded, color: Color(0xFF715716)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phaseLabel,
                style: const TextStyle(
                  color: Color(0xFF715716),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF4E4325),
                  fontSize: 11,
                  height: 1.35,
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
            const Text(
              '연습용',
              style: TextStyle(
                color: Color(0xFF8D762E),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${_money(_practiceState.brokerageCash)}원',
              style: const TextStyle(
                color: Color(0xFF3F351A),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFeatures: _marketNumberFeatures,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _orderPractice({required bool isBuy}) => Column(
    key: Key(isBuy ? 'tutorial-buy-order' : 'tutorial-sell-order'),
    children: [
      _practiceHeader(
        phaseLabel: isBuy ? '실전 연습 1 / 3 · 매수' : '실전 연습 3 / 3 · 매도',
        description: isBuy
            ? widget.initialBuyLimitPrice == null
                  ? '한 주 사 볼까요? 노란 테두리의 매수 버튼만 눌러 보세요.'
                  : '호가창에서 고른 ${_money(widget.initialBuyLimitPrice!.round())}원이 '
                        '입력됐어요. 노란 테두리의 매수 버튼으로 한 주 사 볼까요?'
            : '어맛, 많이 올랐네요! 노란 테두리의 매도 버튼으로 한 주를 팔아 보세요.',
      ),
      Expanded(
        child: _OrderSheet(
          key: ValueKey(isBuy ? 'practice-buy-sheet' : 'practice-sell-sheet'),
          definition: widget.definition,
          live: _practiceLive,
          isBuy: isBuy,
          state: _practiceState,
          minute: _practiceMinuteNotifier,
          onExecuteTrade: _executePracticeOrder,
          balanceLabel: isBuy ? '연습용 주문 가능 예수금' : null,
          submitLabel: isBuy ? '연습 매수 주문 실행' : '연습 매도 주문 실행',
          successLabel: isBuy ? '시간별 계좌 변화 확인하기' : '선생님께 돌아가 결과 보기',
          forceActionHighlight: true,
          initialOrderType: isBuy && widget.initialBuyLimitPrice != null
              ? TradeOrderType.limit
              : null,
          initialLimitPrice: isBuy ? widget.initialBuyLimitPrice : null,
          onSuccessContinue: isBuy ? _showPriceMove : _showSummary,
        ),
      ),
    ],
  );

  Widget _priceMoveView() {
    final position = _practiceState.positions
        .where((item) => item.assetId == widget.definition.id)
        .firstOrNull;
    final units = position?.units ?? 0;
    final currentPrice = _practiceLive.value.price;
    final marketValue = (currentPrice * units).round();
    final totalCost = position?.totalCost ?? 0;
    final estimatedChange = marketValue - totalCost;
    final accountValue = _practiceState.brokerageCash + marketValue;
    final changeRate = _buyPrice <= 0
        ? 0.0
        : (currentPrice / _buyPrice - 1) * 100;
    final progress = _priceMovePath.length <= 1
        ? 1.0
        : _priceMoveStep / (_priceMovePath.length - 1);
    final currentMinute = _practiceMinuteNotifier.value;
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('tutorial-price-change'),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '실전 연습 2 / 3 · 실시간 계좌',
              style: TextStyle(
                color: _marketAccent,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '매수 뒤 가격이 움직였어요',
              style: TextStyle(
                color: _marketInk,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '5분씩 시간이 흐를 때마다 현재가와 내 계좌 평가금이 함께 바뀌는 모습을 지켜보세요.',
              style: TextStyle(
                color: _marketMuted,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              key: const Key('tutorial-live-account-state'),
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _priceMoveComplete
                      ? const Color(0xFFFFC84F)
                      : const Color(0xFF8ED6B7),
                  width: _priceMoveComplete ? 3 : 1.5,
                ),
                boxShadow: _priceMoveComplete
                    ? const [
                        BoxShadow(
                          color: Color(0x66FFD85E),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ]
                    : const [],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF315D57),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          marketTimeLabel(currentMinute),
                          key: const Key('tutorial-live-market-time'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontFeatures: _marketNumberFeatures,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_priceMoveStep + 1} / ${_priceMovePath.length} 시세',
                        style: const TextStyle(
                          color: Color(0xFF52736D),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '현재가',
                        style: TextStyle(
                          color: _marketMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _displayPrice(currentPrice, 'KRW'),
                        key: const Key('tutorial-live-current-price'),
                        style: const TextStyle(
                          color: Color(0xFF168B5E),
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          fontFeatures: _marketNumberFeatures,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${changeRate >= 0 ? '+' : ''}${changeRate.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: changeRate >= 0
                            ? const Color(0xFF168B5E)
                            : const Color(0xFFB42332),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: const Color(0xFFD1E7DD),
                    color: const Color(0xFF20A675),
                  ),
                  const Divider(height: 26),
                  _PracticeSummaryRow(
                    label: '주문 가능 예수금',
                    value: '${_money(_practiceState.brokerageCash)}원',
                  ),
                  _PracticeSummaryRow(
                    label: '보유 주식',
                    value: '${_displayUnits(units)}주',
                  ),
                  _PracticeSummaryRow(
                    label: '현재 평가금',
                    value: '${_money(marketValue)}원',
                  ),
                  _PracticeSummaryRow(
                    label: '평가손익',
                    value:
                        '${estimatedChange >= 0 ? '+' : ''}${_money(estimatedChange)}원',
                    strong: true,
                  ),
                  _PracticeSummaryRow(
                    label: '실시간 내 계좌',
                    value: '${_money(accountValue)}원',
                    strong: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _priceMoveComplete
                  ? const _TutorialDialogueCard(
                      key: Key('tutorial-price-rise-teacher'),
                      speaker: '한서윤 선생님',
                      message: '어맛, 많이 올랐네요! 이제 한 번 팔아 볼까요?',
                      teacher: true,
                    )
                  : _TutorialDialogueCard(
                      key: ValueKey<int>(_priceMoveStep),
                      speaker: '한서윤 선생님',
                      message:
                          '${marketTimeLabel(currentMinute)}이에요. 아직 팔지 말고 내 계좌 숫자가 어떻게 달라지는지 조금 더 지켜봐요.',
                      teacher: true,
                    ),
            ),
            const SizedBox(height: 14),
            Container(
              key: const Key('tutorial-sell-navigation-highlight'),
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: _priceMoveComplete
                      ? const Color(0xFFFFD85E)
                      : const Color(0xFFD5DBE3),
                  width: _priceMoveComplete ? 4 : 1,
                ),
                boxShadow: _priceMoveComplete
                    ? const [
                        BoxShadow(
                          color: Color(0x99FFD85E),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : const [],
              ),
              child: FilledButton(
                key: const Key('tutorial-price-change-continue'),
                onPressed: _priceMoveComplete ? _openSellPractice : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFFF04452),
                  disabledBackgroundColor: const Color(0xFFBCC3CD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _priceMoveComplete ? '선생님 말대로 한 주 팔러 가기' : '가격 움직임 지켜보는 중…',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '보유 중 손익은 화면 속 평가손익이고, 실제로 팔아야 손익이 확정돼요.',
              style: TextStyle(
                color: _marketMuted,
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryView() => SafeArea(
    child: SingleChildScrollView(
      key: const Key('tutorial-trade-summary'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 64,
            color: Color(0xFF20A675),
          ),
          const SizedBox(height: 12),
          const Text(
            '매수부터 매도까지 완료!',
            style: TextStyle(
              color: _marketInk,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '연습금으로 한 주를 사고, 가격이 바뀐 뒤 다시 팔았어요. 팔고 나서야 손익이 확정된다는 것도 확인했어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _marketMuted,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _PracticeSummaryRow(
                  label: '시작 연습금',
                  value: '${_money(_practiceSeedMoney)}원',
                ),
                _PracticeSummaryRow(
                  label: '매도 후 연습금',
                  value: '${_money(_practiceState.brokerageCash)}원',
                ),
                _PracticeSummaryRow(
                  label: '팔아서 확정된 손익',
                  value:
                      '${_realizedPnl >= 0 ? '+' : ''}${_money(_realizedPnl)}원',
                  strong: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '연습금과 주문 기록은 수업이 끝나면 사라져요. 실제 계좌의 돈과 주식은 그대로예요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8B6F21),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('tutorial-summary-continue'),
              onPressed: _showReview,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: _marketAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '선생님과 거래 돌아보기',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _reviewView() {
    final studentName = widget.sourceState.story.playerName.trim().isEmpty
        ? '나'
        : widget.sourceState.story.playerName.trim();
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const Key('tutorial-post-trade-review'),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '첫 거래, 같이 돌아볼까요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _marketInk,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '수익보다 중요한 건 내가 누른 주문을 이해하는 거예요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _marketMuted,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _TutorialDialogueCard(
                    speaker: '한서윤 선생님',
                    message: '처음 직접 사고팔아 보니까 어땠어요? 숫자가 움직일 때 조금 떨렸죠?',
                    teacher: true,
                  ),
                  const SizedBox(height: 10),
                  _TutorialDialogueCard(
                    speaker: studentName,
                    message: '네! 사는 것보다 언제 팔지 정하는 게 더 어려웠어요.',
                  ),
                  const SizedBox(height: 10),
                  const _TutorialDialogueCard(
                    speaker: '한서윤 선생님',
                    message:
                        '맞아요. 그래서 사기 전에 “왜 사는지”와 “언제 다시 볼지”를 한 줄 적는 거예요. 팔기 전 손익은 아직 화면 속 숫자이고, 실제로 팔아야 결과가 확정된다는 것도 기억해요.',
                    teacher: true,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('tutorial-review-continue'),
                onPressed: _showDismissal,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: _marketAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '마지막 인사 듣기',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dismissalView() {
    final studentName = widget.sourceState.story.playerName.trim().isEmpty
        ? '나'
        : widget.sourceState.story.playerName.trim();
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const Key('tutorial-school-dismissal'),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.wb_twilight_rounded,
                    size: 58,
                    color: Color(0xFFF2A93B),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '첫 수업 끝!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _marketInk,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _TutorialDialogueCard(
                    speaker: '한서윤 선생님',
                    message:
                        '오늘은 여기까지! 다음에는 네가 궁금한 회사를 하나 골라 와요. 가격만 보지 말고 무엇을 파는 회사인지도 같이 찾아보는 거예요.',
                    teacher: true,
                  ),
                  const SizedBox(height: 10),
                  _TutorialDialogueCard(
                    speaker: studentName,
                    message: '네! 다음에는 제가 고른 회사로 주문표도 써 볼래요.',
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7DF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEACB7B)),
                    ),
                    child: const Text(
                      '종이 울렸다. 나는 첫 투자노트를 가방에 넣고 선생님께 인사한 뒤 교문을 나섰다. 이제 집에서 내 첫 회사를 찾아볼 차례다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF5D4B21),
                        height: 1.55,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('market-practical-tutorial-complete'),
                onPressed: _finishing ? null : _finishTutorial,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: _marketAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _finishing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.directions_walk_rounded),
                label: Text(
                  _finishing ? '하교 준비 중…' : '인사하고 집으로 돌아가기',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: _allowPop,
    child: KeyedSubtree(
      key: const Key('market-practical-tutorial'),
      child: switch (_phase) {
        _PracticalTradeTutorialPhase.buy => _orderPractice(isBuy: true),
        _PracticalTradeTutorialPhase.priceMove => _priceMoveView(),
        _PracticalTradeTutorialPhase.sell => _orderPractice(isBuy: false),
        _PracticalTradeTutorialPhase.summary => _summaryView(),
        _PracticalTradeTutorialPhase.review => _reviewView(),
        _PracticalTradeTutorialPhase.dismissal => _dismissalView(),
      },
    ),
  );
}

class _PracticeSummaryRow extends StatelessWidget {
  const _PracticeSummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(label),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: strong ? const Color(0xFF168B5E) : _marketInk,
            fontWeight: FontWeight.w900,
            fontFeatures: _marketNumberFeatures,
          ),
        ),
      ],
    ),
  );
}

class _TutorialDialogueCard extends StatelessWidget {
  const _TutorialDialogueCard({
    super.key,
    required this.speaker,
    required this.message,
    this.teacher = false,
  });

  final String speaker;
  final String message;
  final bool teacher;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: teacher ? const Color(0xFFFFF5EE) : const Color(0xFFF2F6FF),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: teacher ? const Color(0xFFF2B49E) : const Color(0xFFAFC3E8),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: teacher
              ? const Color(0xFFF18775)
              : const Color(0xFF6688C7),
          child: Icon(
            teacher ? Icons.school_rounded : Icons.face_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                speaker,
                style: TextStyle(
                  color: teacher
                      ? const Color(0xFFB14F42)
                      : const Color(0xFF405F9B),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                message,
                style: const TextStyle(
                  color: _marketInk,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OrderBookPanel extends StatelessWidget {
  const _OrderBookPanel({
    required this.definition,
    required this.quote,
    required this.state,
    required this.minute,
    required this.playerTradeSide,
    required this.playerTradeQuantity,
    required this.playerTradePrice,
    required this.playerTradeMinute,
    required this.onTapLevel,
    this.tutorialHeaderKey,
    this.tutorialBestAskKey,
  });

  final _StockDefinition definition;
  final _LiveStock quote;
  final GameState state;
  final int minute;
  final TradeSide? playerTradeSide;
  final double playerTradeQuantity;
  final double playerTradePrice;
  final int playerTradeMinute;
  final ValueChanged<GameOrderBookLevel> onTapLevel;
  final GlobalKey? tutorialHeaderKey;
  final GlobalKey? tutorialBestAskKey;

  double _playerQuantity(GameOrderBookLevel level) => state.pendingOrders
      .where(
        (order) =>
            order.assetId == definition.id &&
            (order.limitPrice - level.price).abs() < 0.000001 &&
            (level.side == GameOrderBookSide.ask
                ? order.side == PendingOrderSide.sell
                : order.side == PendingOrderSide.buy),
      )
      .fold<double>(0, (sum, order) => sum + order.remainingQuantity);

  @override
  Widget build(BuildContext context) {
    final snapshot = buildGameOrderBookSnapshot(
      assetId: definition.id,
      day: state.day,
      minute: minute,
      currentPrice: quote.price,
      previousClose: quote.previousClose,
      date: state.currentDate,
      market: definition.market,
      tradingDay: quote.isTradingDay,
    );
    final levels = [...snapshot.asks, ...snapshot.bids];
    final maxDepth = levels.fold<int>(
      1,
      (maximum, level) =>
          math.max(maximum, level.quantity + _playerQuantity(level).ceil()),
    );
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
    final displayedTradeStrength = displayedAskQuantity <= 0
        ? 100.0
        : (displayedBidQuantity / displayedAskQuantity * 100)
              .clamp(20, 240)
              .toDouble();
    final range = marketDailyPriceRange(
      previousClose: quote.previousClose,
      date: state.currentDate,
      market: definition.market,
    );
    final pendingOrderCount = state.pendingOrders
        .where((order) => order.assetId == definition.id)
        .length;
    final previousTickPrice = quote.sessionHistory.length >= 2
        ? quote.sessionHistory[quote.sessionHistory.length - 2]
        : quote.previousClose;
    final clock = marketClockAt(
      minute,
      tradingDay: quote.isTradingDay && isMarketTradingDay(state.currentDate),
    );
    GameOrderBookTradePulse? activePulse = clock.tradable
        ? gameOrderBookTradePulse(
            assetId: definition.id,
            day: state.day,
            minute: minute,
            previousPrice: previousTickPrice,
            currentPrice: quote.price,
            executionCapacity: snapshot.executionCapacity,
            market: definition.market,
          )
        : null;
    if (clock.tradable &&
        playerTradeSide != null &&
        playerTradeMinute == minute &&
        playerTradeQuantity > 0 &&
        playerTradePrice > 0) {
      final levelSide = playerTradeSide == TradeSide.buy
          ? GameOrderBookSide.ask
          : GameOrderBookSide.bid;
      final tradeLevels = levelSide == GameOrderBookSide.ask
          ? snapshot.asks
          : snapshot.bids;
      var nearestIndex = 0;
      var nearestDistance = double.infinity;
      for (var index = 0; index < tradeLevels.length; index++) {
        final distance = (tradeLevels[index].price - playerTradePrice).abs();
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestIndex = index;
        }
      }
      activePulse = GameOrderBookTradePulse(
        levelSide: levelSide,
        levelIndex: nearestIndex,
        quantity: playerTradeQuantity.round(),
      );
    }
    final change = quote.price - quote.previousClose;
    return Container(
      key: const Key('stock-order-book'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E6EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D18263A),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            key: tutorialHeaderKey,
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '10단계 호가',
                        style: TextStyle(
                          color: Color(0xFF202632),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '게임용 자동생성',
                        style: TextStyle(
                          color: Color(0xFF6D7786),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 3,
                  children: [
                    Text(
                      '거래대금 ${_compactEok(snapshot.turnoverEok)}',
                      key: const Key('order-book-turnover'),
                      style: const TextStyle(
                        color: Color(0xFF4E5968),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '체결강도 ${displayedTradeStrength.toStringAsFixed(1)}%',
                      key: const Key('order-book-trade-strength'),
                      style: TextStyle(
                        color: displayedTradeStrength >= 100
                            ? const Color(0xFFF04452)
                            : _marketAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '분당 소화 ${_money(snapshot.executionCapacity)}주',
                      key: const Key('order-book-capacity'),
                      style: const TextStyle(
                        color: Color(0xFF4E5968),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '내 미체결 $pendingOrderCount건',
                      key: const Key('order-book-pending-count'),
                      style: const TextStyle(
                        color: Color(0xFF4E5968),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (activePulse != null) ...[
                  const SizedBox(height: 7),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      key: ValueKey(
                        '${activePulse.levelSide.name}-'
                        '${activePulse.levelIndex}-$minute-'
                        '${activePulse.quantity}',
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: activePulse.isBuyAggressor
                            ? const Color(0xFFFFEEF0)
                            : const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            activePulse.isBuyAggressor
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 12,
                            color: activePulse.isBuyAggressor
                                ? const Color(0xFFF04452)
                                : _marketAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${activePulse.isBuyAggressor ? '매수' : '매도'} 체결 '
                            '${_money(activePulse.quantity)}주 · 네모칸 이동 중',
                            key: const Key('order-book-active-summary'),
                            style: TextStyle(
                              color: activePulse.isBuyAggressor
                                  ? const Color(0xFFF04452)
                                  : _marketAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  '상 ${_money(range.upper.round())} · 하 ${_money(range.lower.round())}'
                  ' · 고 ${_money(quote.high.round())} · 저 ${_money(quote.low.round())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8A919E),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    fontFeatures: _marketNumberFeatures,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 28,
            color: const Color(0xFFF7F8FA),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    '구분',
                    style: TextStyle(
                      color: Color(0xFF8A919E),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '가격',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF8A919E),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 86,
                  child: Text(
                    '잔량',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Color(0xFF8A919E),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...snapshot.asks.reversed.toList().asMap().entries.map((entry) {
            final levelIndex = snapshot.asks.length - 1 - entry.key;
            final row = _OrderBookLevelRow(
              key: Key('order-book-ask-$levelIndex'),
              level: entry.value,
              maxDepth: maxDepth,
              playerQuantity: _playerQuantity(entry.value),
              isActive:
                  activePulse?.levelSide == GameOrderBookSide.ask &&
                  activePulse?.levelIndex == levelIndex,
              activeQuantity: activePulse?.quantity ?? 0,
              onTap: definition.currency == 'KRW'
                  ? () => onTapLevel(entry.value)
                  : null,
            );
            if (levelIndex != 0 || tutorialBestAskKey == null) return row;
            return RepaintBoundary(key: tutorialBestAskKey, child: row);
          }),
          Container(
            key: const Key('order-book-current-price'),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFCF0),
              border: Border.symmetric(
                horizontal: BorderSide(color: Color(0xFFFFE08A)),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 72,
                  child: Text(
                    '현재 체결가',
                    style: TextStyle(
                      color: Color(0xFF6E5A16),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${_money(quote.price.round())}원',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _priceColor(change),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFeatures: _marketNumberFeatures,
                    ),
                  ),
                ),
                SizedBox(
                  width: 86,
                  child: Text(
                    '${change >= 0 ? '+' : ''}${_changeRate(quote).toStringAsFixed(2)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _priceColor(change),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      fontFeatures: _marketNumberFeatures,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...snapshot.bids.asMap().entries.map(
            (entry) => _OrderBookLevelRow(
              key: Key('order-book-bid-${entry.key}'),
              level: entry.value,
              maxDepth: maxDepth,
              playerQuantity: _playerQuantity(entry.value),
              isActive:
                  activePulse?.levelSide == GameOrderBookSide.bid &&
                  activePulse?.levelIndex == entry.key,
              activeQuantity: activePulse?.quantity ?? 0,
              onTap: definition.currency == 'KRW'
                  ? () => onTapLevel(entry.value)
                  : null,
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
            color: const Color(0xFFFAFBFC),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '매도잔량 ${_money(displayedAskQuantity)}주',
                        style: const TextStyle(
                          color: _marketAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '매수잔량 ${_money(displayedBidQuantity)}주',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFFF04452),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  '매도호가를 누르면 매수, 매수호가를 누르면 매도 지정가가 입력됩니다. '
                  '가격이 달아나면 주문이 체결되지 않을 수 있습니다.',
                  style: TextStyle(
                    color: Color(0xFF7B8491),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _OrderBookLevelRow extends StatelessWidget {
  const _OrderBookLevelRow({
    super.key,
    required this.level,
    required this.maxDepth,
    required this.playerQuantity,
    required this.isActive,
    required this.activeQuantity,
    required this.onTap,
  });

  final GameOrderBookLevel level;
  final int maxDepth;
  final double playerQuantity;
  final bool isActive;
  final int activeQuantity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isAsk = level.side == GameOrderBookSide.ask;
    final levelColor = isAsk ? _marketAccent : const Color(0xFFF04452);
    final tradeColor = isAsk ? const Color(0xFFF04452) : _marketAccent;
    final tint = isAsk ? const Color(0xFFEAF3FF) : const Color(0xFFFFEEF0);
    final barColor = isAsk ? const Color(0x403278D5) : const Color(0x40F04452);
    final totalQuantity = level.quantity + playerQuantity.ceil();
    final depth = (totalQuantity / math.max(1, maxDepth)).clamp(0.04, 1.0);
    final isWall =
        level.isWall || playerQuantity >= math.max(1, level.quantity * 2);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isActive
            ? tradeColor.withValues(alpha: 0.10)
            : tint.withValues(alpha: 0.45),
        border: Border.all(
          color: isActive ? tradeColor : Colors.transparent,
          width: isActive ? 2 : 0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: tradeColor.withValues(alpha: 0.22),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 41,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: depth * 0.62,
                    child: ColoredBox(color: barColor),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: isActive
                              ? Container(
                                  key: const Key('order-book-active-trade'),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    isAsk ? '매수 체결 ↑' : '매도 체결 ↓',
                                    style: TextStyle(
                                      color: tradeColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    Text(
                                      isAsk ? '매도' : '매수',
                                      style: TextStyle(
                                        color: levelColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (isWall) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: levelColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '벽',
                                          style: TextStyle(
                                            color: levelColor,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                        Expanded(
                          child: Text(
                            '${_money(level.price.round())}원',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isActive ? tradeColor : levelColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              fontFeatures: _marketNumberFeatures,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 86,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _money(totalQuantity),
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Color(0xFF2C3440),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: _marketNumberFeatures,
                                ),
                              ),
                              if (isActive)
                                Text(
                                  '체결 ${_money(activeQuantity)}주',
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: tradeColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              else if (playerQuantity > 0)
                                Text(
                                  '내 주문 ${_displayUnits(playerQuantity)}주',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Color(0xFF7A5A00),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _OrderSheet extends StatefulWidget {
  const _OrderSheet({
    super.key,
    required this.definition,
    required this.live,
    required this.isBuy,
    required this.state,
    required this.minute,
    required this.onExecuteTrade,
    this.initialOrderType,
    this.initialLimitPrice,
    this.balanceLabel,
    this.submitLabel,
    this.successLabel = '완료',
    this.onSuccessContinue,
    this.forceActionHighlight = false,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final bool isBuy;
  final GameState state;
  final ValueNotifier<int> minute;
  final Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade;
  final TradeOrderType? initialOrderType;
  final double? initialLimitPrice;
  final String? balanceLabel;
  final String? submitLabel;
  final String successLabel;
  final VoidCallback? onSuccessContinue;
  final bool forceActionHighlight;

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  static const _tradeSaveFailureMessage =
      '주문을 저장하지 못했어요. 저장 공간을 확인하고 다시 시도해 주세요.';

  double _quantity = 1;
  late TradeOrderType _orderType;
  double? _limitPrice;
  bool _submitting = false;
  TradeExecutionResult? _result;

  @override
  void initState() {
    super.initState();
    widget.live.addListener(_handleMarketUpdate);
    widget.minute.addListener(_handleMarketUpdate);
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
  double get _orderPrice => _orderType == TradeOrderType.limit
      ? (_limitPrice ?? _executionPrice)
      : _executionPrice;
  int get _rawNotional => (_orderPrice * _quantity).round();
  double get _marketImpact => _orderType == TradeOrderType.market
      ? gameMarketImpactRate(_rawNotional)
      : 0;
  int get _notional => _orderType == TradeOrderType.market
      ? gameTradeNotional(
          side: widget.isBuy ? TradeSide.buy : TradeSide.sell,
          unitPrice: _executionPrice,
          quantity: _quantity,
        )
      : _rawNotional;
  int get _fee => gameTradingFeeForState(widget.state, _notional);
  double get _feeRate => gameTradingFeeRateForState(widget.state);
  int get _settlement => widget.isBuy ? _notional + _fee : _notional - _fee;
  double get _maxQuantity {
    if (!widget.isBuy) {
      final held = math.max(
        0.0,
        (_position?.units ?? 0) -
            widget.state.pendingSellReservedUnits(widget.definition.id),
      );
      if (_executionPrice <= 0) return 0;
      final liquidUnits =
          gameMarketOrderNotionalLimit(_orderPrice) / _orderPrice;
      return math.min(held, liquidUnits);
    }
    return gameMaxBuyQuantity(widget.state, _orderPrice).toDouble();
  }

  ({double lower, double upper}) get _dailyRange => marketDailyPriceRange(
    previousClose: _quote.previousClose,
    date: widget.state.currentDate,
    market: widget.definition.market,
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
          type: _orderType,
          limitPrice: _orderType == TradeOrderType.limit ? _limitPrice : null,
          previousClose: _quote.previousClose,
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
    final actionColor = widget.isBuy ? _marketAccent : const Color(0xFFF04452);
    final maxQuantity = _maxQuantity;
    final canSubmit =
        _authorityReady &&
        _tradable &&
        _quantity > 0 &&
        _quantity <= maxQuantity &&
        _validLimitPrice &&
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
                  fontWeight: FontWeight.w700,
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
                onSelectionChanged: (value) => setState(() {
                  _orderType = value.first;
                  _limitPrice ??= marketSnapPrice(
                    _executionPrice,
                    market: widget.definition.market,
                  );
                  _result = null;
                }),
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
                                ? '${widget.balanceLabel ?? '주문 가능 예수금'} ${_money(widget.state.brokerageCash)}원'
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
                    _OrderSummaryRow(
                      label: _marketImpact > 0
                          ? '시장충격 ${(_marketImpact * 100).toStringAsFixed(2)}% 반영'
                          : '주문 금액',
                      value: _notional,
                    ),
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
                  !_tradable
                      ? '현재는 주문 가능한 거래 시간이 아닙니다.'
                      : !_authorityReady
                      ? '종잣돈 10,000원을 먼저 마련해야 보호자 주문 승인을 받을 수 있습니다.'
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
                  key: const Key('request-parent-order-approval'),
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
        Text(label),
        const Spacer(),
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
    speaker: '한서윤 선생님',
    message: switch (step) {
      0 => '학원에서 배운 주문표를 실제 화면에서 연습해 볼게요. 지금부터 제가 가리키는 곳만 하나씩 눌러 보세요.',
      1 => '아래의 ‘주식’ 탭은 거래 가능한 회사를 모아 보는 곳이에요. 노란 테두리 안을 직접 눌러 보세요.',
      _ => '종목은 회사 한 곳을 뜻해요. 먼저 한빛통신을 눌러 가격과 회사 내용을 함께 살펴볼게요.',
    },
    actionLabel: '선생님과 화면 수업 시작',
    poseAlignment: Alignment.topCenter,
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
    speaker: '한서윤 선생님',
    message: switch (step) {
      0 =>
        '가장 큰 숫자는 지금 한 주의 가격이에요. 바로 아래 등락률은 어제 종가와 비교한 값이니, 노란 테두리를 눌러 확인하세요.',
      1 =>
        '차트는 가격의 움직임, 아래 재무 카드는 매출·이익·현금흐름·수주를 보여줘요. 가격만 보지 말고 회사가 돈을 버는지도 함께 읽어야 해요.',
      2 =>
        '호가창은 위 5줄이 매도, 아래 5줄이 매수예요. 잔량 막대가 큰 줄은 ‘벽’이고 거래대금에 따라 벽과 분당 체결 가능 수량이 달라져요. 체결강도·상한가·하한가·고가·저가·총 매수·매도잔량도 함께 읽으세요. 화면 수량과 실제 부분체결 한도는 같은 계산이며, 개장 전과 휴장일에는 거래대금과 체결 가능량이 0이에요.',
      _ =>
        '매도호가를 누르면 그 가격의 매수 지정가, 매수호가를 누르면 매도 지정가가 입력돼요. 내 미체결 주문도 호가에 표시됩니다. 가격이 달아나거나 잔량이 부족하면 예수금이나 주식이 예약된 채 미체결·부분체결로 기다려요. 지금은 가장 가까운 파란 매도호가를 눌러 매수를 연습해 보세요.',
    },
    actionLabel: '회사 숫자 확인했어요',
    poseAlignment: Alignment.topCenter,
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
    speaker: '한서윤 선생님',
    message: limitPrice == null
        ? '연습 화면에서만 쓰는 가짜 돈 100만 원을 준비했어요. 먼저 한 주를 사고, 가격이 바뀐 뒤 다시 팔아 볼 거예요. 실제 돈은 전혀 움직이지 않으니 천천히 해 봐요.'
        : '방금 누른 매도호가 ${_money(limitPrice!.round())}원이 매수 지정가에 들어왔어요. '
              '가격·시간 순서로 체결되고, 한 번에 다 못 사면 일부만 체결될 수도 있어요. 가격이 멀어지면 주문이 기다리고, 취소하거나 15:00가 되면 예약된 돈이 풀려요. 이제 노란 테두리의 버튼으로 한 주를 직접 사 볼까요?',
    actionLabel: '가짜 돈으로 주문 연습 시작',
    poseAlignment: Alignment.topCenter,
    onAction: () => unawaited(onDone()),
  );
}

class _StockTutorialGuideOverlay extends StatefulWidget {
  const _StockTutorialGuideOverlay({
    required this.overlayKey,
    required this.actionKey,
    required this.targetActionKey,
    required this.targetKey,
    required this.speaker,
    required this.message,
    required this.actionLabel,
    required this.poseAlignment,
    required this.onAction,
  });

  final Key overlayKey;
  final Key actionKey;
  final Key targetActionKey;
  final GlobalKey? targetKey;
  final String speaker;
  final String message;
  final String actionLabel;
  final Alignment poseAlignment;
  final VoidCallback onAction;

  @override
  State<_StockTutorialGuideOverlay> createState() =>
      _StockTutorialGuideOverlayState();
}

class _StockTutorialGuideOverlayState
    extends State<_StockTutorialGuideOverlay> {
  final GlobalKey _layoutKey = GlobalKey();
  Rect? _targetRect;
  Timer? _settleTimer;

  @override
  void initState() {
    super.initState();
    _scheduleTargetUpdate();
  }

  @override
  void didUpdateWidget(covariant _StockTutorialGuideOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
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
        widget.targetKey?.currentContext?.findRenderObject() as RenderBox?;
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

  @override
  Widget build(BuildContext context) {
    final hasTarget = widget.targetKey != null;
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
              const Positioned.fill(
                child: ModalBarrier(
                  dismissible: false,
                  color: Color(0x990C1424),
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
              Positioned(
                right: -6,
                bottom: 54,
                child: _StockTutorialTeacher(
                  poseAlignment: widget.poseAlignment,
                  width: teacherWidth,
                ),
              ),
              Positioned(
                left: 12,
                right: speechRight,
                top: speechAtTop ? 44 : null,
                bottom: speechAtTop ? null : 185,
                child: _StockTutorialSpeechBubble(
                  speaker: widget.speaker,
                  message: widget.message,
                  actionKey: widget.actionKey,
                  actionLabel: widget.actionLabel,
                  showAction: !hasTarget,
                  waitingForTarget: hasTarget && _targetRect == null,
                  onAction: widget.onAction,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StockTutorialTeacher extends StatelessWidget {
  const _StockTutorialTeacher({
    required this.poseAlignment,
    required this.width,
  });

  final Alignment poseAlignment;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.42;
    final cellDimension = height;
    final cropAlignment = Alignment(
      poseAlignment.x < -0.5
          ? -0.84
          : poseAlignment.x > 0.5
          ? 0.84
          : 0,
      poseAlignment.y < 0 ? -1 : 1,
    );
    return SizedBox(
      key: const Key('market-tutorial-teacher'),
      width: width,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: cropAlignment,
          minWidth: cellDimension * 3,
          maxWidth: cellDimension * 3,
          minHeight: cellDimension * 2,
          maxHeight: cellDimension * 2,
          child: Image.asset(
            'assets/images/주식선생님/06_6자세_블라우스_스커트_투명.png',
            key: const Key('market-tutorial-teacher-upper-body'),
            width: cellDimension * 3,
            height: cellDimension * 2,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _StockTutorialSpeechBubble extends StatelessWidget {
  const _StockTutorialSpeechBubble({
    required this.speaker,
    required this.message,
    required this.actionKey,
    required this.actionLabel,
    required this.showAction,
    required this.waitingForTarget,
    required this.onAction,
  });

  final String speaker;
  final String message;
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
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF24375A),
                fontSize: 12,
                height: 1.48,
                fontWeight: FontWeight.w700,
              ),
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

class _DailyMarketReportCard extends StatelessWidget {
  const _DailyMarketReportCard({
    required this.items,
    required this.cash,
    required this.purchasing,
    required this.onPurchase,
  });

  final List<Map<String, dynamic>> items;
  final int cash;
  final bool purchasing;
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
                onPressed: purchasing ? null : onPurchase,
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
                      : '1,200원에 조사 보고서 구매 · 보유 ${_money(cash)}원',
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
  Widget build(BuildContext context) => Column(
    key: const Key('market-ranking-table'),
    children: [
      for (var index = 0; index < stocks.length; index++)
        _MarketRankingRow(
          key: Key('market-ranking-row-${stocks[index].code}'),
          rank: index + 1,
          definition: stocks[index],
          live: live[stocks[index].code]!,
          onTap: () => onOpen(stocks[index]),
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
                        '${definition.code} · 거래대금 ${_compactEok(_simulatedTurnover(definition, quote))}',
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
                        '${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(2)}%',
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
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${state.companyName} 증권계좌',
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
            '${_money(state.brokerageCash + evaluation)}원',
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
                        label: '누적 수수료',
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
            state.pendingBuyReservedCash > 0
                ? '미체결 매수 예약 ${_money(state.pendingBuyReservedCash)}원 · '
                      '예수금 ${_money(state.brokerageCash)}원'
                : '누적 증권 수수료 ${_money(totalFees)}원 · 매매 수수료율 0.250%',
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
      : widget.state.availableBrokerageCash;
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
                : '출금 가능 예수금은 ${_money(widget.state.availableBrokerageCash)}원이에요.',
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                            '${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(2)}%',
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

  ({List<double> prices, int startMinute}) _visibleMinuteSeries({
    required int targetMinutes,
  }) {
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

  List<double> _dailyCloses() {
    final buckets = <String, double>{};
    for (final point in widget.quote.history) {
      buckets[_dailyBucket(point)] = point.close;
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

  String _dailyBucket(MarketPoint point) {
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

  List<String> _minuteAxisLabels(
    int visiblePointCount, {
    required int startMinuteOffset,
  }) {
    if (widget.minute < krxOpenMinute) {
      return <String>['', '', '개장 전 ${marketTimeLabel(widget.minute)}'];
    }
    final endMinute = widget.minute.clamp(krxOpenMinute, krxCloseMinute);
    if (startMinuteOffset < 0) {
      final previousStart = (krxCloseMinute + startMinuteOffset).clamp(
        krxOpenMinute,
        krxCloseMinute,
      );
      return <String>[
        '전일 ${marketTimeLabel(previousStart)}',
        '오늘 09:00',
        marketTimeLabel(endMinute),
      ];
    }
    final elapsed = math.max(0, visiblePointCount - 1);
    final startMinute = math.max(krxOpenMinute, endMinute - elapsed);
    final middleMinute = startMinute + (endMinute - startMinute) ~/ 2;
    return <String>[
      marketTimeLabel(startMinute),
      marketTimeLabel(middleMinute),
      marketTimeLabel(endMinute),
    ];
  }

  List<String> _dailyAxisLabels() {
    final keys = <String>[];
    String? lastKey;
    for (final point in widget.quote.history) {
      final key = _dailyBucket(point);
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
    final formatted = visible.map(_formatDailyAxisLabel).toList();
    return _axisTriplet(formatted);
  }

  String _formatDailyAxisLabel(String key) {
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
    required int dailyCount,
    required bool hasPreviousSession,
  }) {
    if (period != _ChartPeriod.minute) {
      return switch (period) {
        _ChartPeriod.day => '일봉 · 최근 $dailyCount거래일 · 가상 종가 기반',
        _ChartPeriod.week => '주봉 · 최근 $dailyCount주 · 가상 종가 기반',
        _ChartPeriod.month => '월봉 · 최근 $dailyCount개월 · 가상 종가 기반',
        _ChartPeriod.year => '년봉 · 최근 $dailyCount년 · 가상 종가 기반',
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
    var minuteSeries = _visibleMinuteSeries(targetMinutes: displayMinutes);
    final candleSeed = widget.quote.history.isEmpty
        ? widget.code.codeUnits.fold<int>(17, (sum, unit) => sum * 31 + unit)
        : marketStockSeed(widget.code, widget.quote.history.last.parsedDate);
    if (period == _ChartPeriod.minute &&
        widget.quote.isTradingDay &&
        widget.minute >= krxOpenMinute &&
        minuteSeries.startMinute == 0) {
      final targetPoints = displayMinutes + 1;
      final missingPoints = math.min(
        math.max(0, targetPoints - minuteSeries.prices.length),
        generatedRegularTradingTicks,
      );
      if (missingPoints > 0) {
        final previousSession = generatedPreviousSessionLeadIn(
          previousClose: widget.quote.previousClose,
          pointCount: missingPoints,
          seed: candleSeed ^ 0x5F3759DF,
        );
        minuteSeries = (
          prices: <double>[...previousSession, ...minuteSeries.prices],
          startMinute: -missingPoints,
        );
      }
    }
    final minutePrices = minuteSeries.prices;
    final candleLimitRate = widget.quote.history.isEmpty
        ? 0.15
        : marketDailyPriceLimitRate(widget.quote.history.last.parsedDate);
    final candles = period == _ChartPeriod.minute
        ? aggregateMarketCandles(
            minutePrices,
            interval,
            tickMinutes: marketTickMinutes,
            seed: candleSeed,
            startMinuteOffset: minuteSeries.startMinute,
            lowerPriceLimit: widget.quote.previousClose * (1 - candleLimitRate),
            upperPriceLimit: widget.quote.previousClose * (1 + candleLimitRate),
          )
        : const <MarketCandle>[];
    final dailyCloses = period == _ChartPeriod.minute
        ? const <double>[]
        : _dailyCloses();
    final visibleCandleCount = math.min(candles.length, displayCandleCount);
    final visibleStartMinute = candles.isEmpty
        ? minuteSeries.startMinute
        : candles[candles.length - visibleCandleCount].startMinute;
    final axisLabels = period == _ChartPeriod.minute
        ? _minuteAxisLabels(
            visibleCandleCount + 1,
            startMinuteOffset: visibleStartMinute,
          )
        : _dailyAxisLabels();
    return Column(
      children: [
        SizedBox(
          height: 268,
          child: CustomPaint(
            key: Key(
              period == _ChartPeriod.minute
                  ? 'minute-candle-chart'
                  : 'daily-close-chart',
            ),
            painter: period == _ChartPeriod.minute
                ? _CandleChartPainter(
                    candles: candles,
                    maxVisibleCandles: displayCandleCount,
                  )
                : _DailyCloseChartPainter(values: dailyCloses),
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
  });

  final List<MarketCandle> candles;
  final int maxVisibleCandles;

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
      oldDelegate.maxVisibleCandles != maxVisibleCandles;
}

class _DailyCloseChartPainter extends CustomPainter {
  const _DailyCloseChartPainter({required this.values});

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
      ..color = _marketAccent
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);
    canvas.drawCircle(
      Offset(size.width, yFor(values.last)),
      3.5,
      Paint()..color = _marketAccent,
    );
  }

  @override
  bool shouldRepaint(covariant _DailyCloseChartPainter oldDelegate) =>
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
              ? '정규장 마감 · 15:00 종가 고정'
              : '가상 장중 · 현실 1초마다 게임 1분 진행(기본) · 3배/10배 지원',
          style: const TextStyle(
            color: Color(0xFF596270),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 18),
        const Text(
          '마지막 값 = 오늘의 가상 종가',
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
    required this.generation,
    required this.financials,
    required this.relations,
  });

  factory _StockDefinition.fromAsset(FictionalMarketAsset asset) =>
      _StockDefinition(
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
        accent: _hexColor(asset.colorHex),
        generation: asset.generation,
        financials: asset.financials,
        relations: asset.relations,
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
    change >= 0 ? const Color(0xFFF04452) : _marketAccent;
