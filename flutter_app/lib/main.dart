import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'game/dynamic_news.dart';
import 'game/game_engine.dart';
import 'game/game_persistence.dart';
import 'game/game_state.dart';
import 'game/historical_executives.dart';
import 'game/market_clock.dart';
import 'game/market_data.dart';
import 'game/market_tick.dart';
import 'game/market_news.dart';
import 'game/market_quote.dart';
import 'game/mission_progression.dart';
import 'game/organization_state.dart';
import 'game/personal_finance_state.dart';
import 'game/seed_money_content.dart';
import 'game/story_state.dart';

part 'organization_screen.dart';
part 'apartment_hub_screens.dart';
part 'save_menu_screens.dart';
part 'asset_spending_screen.dart';
part 'room_screens.dart';
part 'seed_money_screen.dart';
part 'stock_market_screen.dart';
part 'visual_novel_onboarding.dart';

const _ink = Color(0xFF33405F);
const _sky = Color(0xFFBDEBFA);
const _cream = Color(0xFFFFF8E7);
const _yellow = Color(0xFFFFDF68);
const _coral = Color(0xFFFF7D72);
const _blue = Color(0xFF67C7EC);

Route<T> _gameSceneRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 300),
  reverseTransitionDuration: const Duration(milliseconds: 280),
  pageBuilder: (_, animation, secondaryAnimation) => _GameFrame(child: page),
  transitionsBuilder: (_, animation, secondaryAnimation, child) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final scale = Tween<double>(begin: 0.985, end: 1).animate(fade);
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(scale: scale, child: child),
    );
  },
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MillenniumCapitalApp());
}

class MillenniumCapitalApp extends StatefulWidget {
  const MillenniumCapitalApp({super.key, this.persistence});

  final GamePersistence? persistence;

  @override
  State<MillenniumCapitalApp> createState() => _MillenniumCapitalAppState();
}

class _MillenniumCapitalAppState extends State<MillenniumCapitalApp> {
  static const _engine = GameEngine();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final GamePersistence _persistence;
  GameState? _state;
  List<GameSaveSlot> _slots = const [];
  _AppView _view = _AppView.title;
  int _activeSlot = 1;
  int? _newGameSlot;
  DateTime? _lastSavedAt;
  bool _isReady = false;
  bool _isRestoring = false;
  Object? _restoreError;

  @override
  void initState() {
    super.initState();
    _persistence = widget.persistence ?? GamePersistence();
    _restoreGame();
  }

  Future<void> _restoreGame({bool retry = false}) async {
    if (_isRestoring) return;
    _isRestoring = true;
    if (retry && mounted) {
      setState(() {
        _isReady = false;
        _restoreError = null;
      });
    }
    try {
      final slots = await _persistence.listSlots();
      final activeSlot = await _persistence.getActiveSlot();
      if (!mounted) return;
      setState(() {
        _state = null;
        _slots = slots;
        _activeSlot = activeSlot;
        _lastSavedAt = slots
            .where((slot) => slot.slot == activeSlot)
            .firstOrNull
            ?.savedAt;
        _view = _AppView.title;
        _restoreError = null;
        _isReady = true;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to restore game: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _restoreError = error;
        _isReady = true;
      });
    } finally {
      _isRestoring = false;
    }
  }

  void _startNewGame() {
    GameSaveSlot? freeSlot;
    for (final slot in _slots) {
      if (slot.isEmpty) {
        freeSlot = slot;
        break;
      }
    }
    if (freeSlot == null) {
      setState(() => _view = _AppView.continueGame);
      _scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('저장 슬롯 5개가 모두 찼어요. 하나를 삭제해 주세요.')),
        );
      return;
    }
    setState(() {
      _newGameSlot = freeSlot!.slot;
      _view = _AppView.onboarding;
    });
  }

  void _showContinue() => setState(() => _view = _AppView.continueGame);

  void _showTitle() => setState(() {
    _state = null;
    _newGameSlot = null;
    _view = _AppView.title;
  });

  Future<void> _continueSlot(int slot) async {
    setState(() => _isReady = false);
    try {
      final state = await _persistence.loadSlot(slot);
      if (state == null) throw StateError('Save slot $slot is empty');
      final slots = await _persistence.listSlots();
      if (!mounted) return;
      setState(() {
        _state = state;
        _slots = slots;
        _activeSlot = slot;
        _lastSavedAt = slots
            .where((item) => item.slot == slot)
            .firstOrNull
            ?.savedAt;
        _view = _AppView.game;
        _isReady = true;
      });
    } catch (error) {
      debugPrint('Failed to load slot $slot: $error');
      if (!mounted) return;
      setState(() {
        _view = _AppView.continueGame;
        _isReady = true;
      });
      _scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('저장을 불러오지 못했어요. 삭제하거나 다시 시도해 주세요.')),
        );
    }
  }

  Future<void> _deleteSaveSlot(int slot) async {
    try {
      await _persistence.deleteSlot(slot);
      final slots = await _persistence.listSlots();
      final activeSlot = await _persistence.getActiveSlot();
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _activeSlot = activeSlot;
      });
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('$slot번 저장을 삭제했습니다.')),
      );
    } catch (error) {
      debugPrint('Failed to delete slot $slot: $error');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('저장을 삭제하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _manualSave() async {
    final state = _state;
    if (state == null) return;
    await _persistence.saveToSlot(state, _activeSlot);
    final slots = await _persistence.listSlots();
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _lastSavedAt = slots
          .where((slot) => slot.slot == _activeSlot)
          .firstOrNull
          ?.savedAt;
    });
  }

  void _returnToTitle() {
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    unawaited(_restoreGame(retry: true));
  }

  Future<void> _createCompany(NewGameSetup setup) async {
    final story = StoryState.newPlayer(
      playerName: setup.playerName,
      introChoice: setup.introChoice,
      startingTrait: setup.startingTrait,
      familyRule: setup.familyRule,
    );
    final state = _engine.createNewGame(
      setup.companyName,
      story: story,
      initialCash: initialCompanyCash,
    );
    final slot = _newGameSlot;
    if (slot == null) {
      _showTitle();
      return;
    }
    try {
      await _persistence.saveToSlot(state, slot);
      await _persistence.setActiveSlot(slot);
    } catch (error) {
      debugPrint('Failed to create company save: $error');
      _scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(_saveFailureSnackBar());
      return;
    }
    if (!mounted) return;
    final slots = await _persistence.listSlots();
    if (!mounted) return;
    setState(() {
      _state = state;
      _slots = slots;
      _activeSlot = slot;
      _lastSavedAt = slots
          .where((item) => item.slot == slot)
          .firstOrNull
          ?.savedAt;
      _view = _AppView.game;
    });
  }

  Future<void> _resolveDecision(String decisionId, String optionId) async {
    final current = _state;
    if (current == null) return;
    final resolved = _engine.resolveDecision(current, decisionId, optionId);
    final next = resolved.copyWith(
      marketMinute: advanceGameTime(
        current.marketMinute,
        decisionActionMinutes,
      ),
    );
    await _persistence.save(next);
    if (!mounted) return;
    setState(() => _state = next);
  }

  Future<MissionClaimResult> _claimMission() async {
    final current = _state!;
    final result = _engine.claimMission(current);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<GameState> _completeWork(WorkSessionResult result) async {
    final current = _state!;
    final completed = _engine.completeWorkSession(current, result);
    final next = completed.copyWith(
      marketMinute: advanceGameTime(current.marketMinute, workActionMinutes),
    );
    await _persistence.save(next);
    if (mounted) setState(() => _state = next);
    return next;
  }

  Future<GameState> _requestFamilyHelp(String helperId) async {
    final current = _state!;
    final helped = _engine.requestFamilyHelp(current, helperId);
    final next = helped.copyWith(
      marketMinute: advanceGameTime(
        current.marketMinute,
        familyHelpActionMinutes,
      ),
    );
    await _persistence.save(next);
    if (mounted) setState(() => _state = next);
    return next;
  }

  Future<GameState> _advanceDay() => _advanceDays(1);

  Future<GameState> _advanceDays(int requestedDays) async {
    final current = _state!;
    var next = current;
    var advanced = false;
    final universe = await HistoricalMarketUniverse.load();
    for (var i = 0; i < requestedDays; i++) {
      if (next.pendingDecisions.isNotEmpty || next.campaignComplete) break;
      final before = next;
      next = _engine.advanceOneDay(next);
      if (next.day == before.day) break;
      advanced = true;
      next = _engine.applyCorporateActions(
        next,
        universe.corporateActionsOn(next.currentDate),
      );
      next = next.copyWith(marketMinute: marketDayStartMinute);
      await _persistence.save(next);
      if (mounted) {
        setState(() {
          _state = next;
          _lastSavedAt = DateTime.now();
        });
      }
      if (next.pendingDecisions.isNotEmpty) break;
    }
    if (!advanced && mounted) setState(() => _state = next);
    return next;
  }

  Future<GameState> _hireEmployee(String candidateId) async {
    final next = _engine.hireEmployee(_state!, candidateId);
    await _persistence.save(next);
    if (mounted) setState(() => _state = next);
    return next;
  }

  Future<GameState> _launchFund() async {
    final next = _engine.launchFund(_state!);
    await _persistence.save(next);
    if (mounted) setState(() => _state = next);
    return next;
  }

  Future<FinanceActionResult> _purchaseSpendingOption(String optionId) async {
    final result = _engine.purchaseSpendingOption(_state!, optionId);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _sellRealEstate(String assetId) async {
    final result = _engine.sellRealEstate(_state!, assetId);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _playAdultChanceGame(int stake) async {
    final result = _engine.playAdultChanceGame(_state!, stake);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<void> _completeHubTutorial() async {
    final next = _engine.markHubTutorialSeen(_state!);
    await _persistence.save(next);
    if (mounted) setState(() => _state = next);
  }

  Future<void> _archiveNews(String headline, List<String> eventIds) async {
    final next = _engine.archiveNews(
      _state!,
      headline: headline,
      eventIds: eventIds,
    );
    await _persistence.save(next);
    if (mounted) setState(() => _state = next);
  }

  Future<GameState> _setMarketMinute(int minute) async {
    final current = _state!;
    final next = current.copyWith(
      marketMinute: minute.clamp(marketDayStartMinute, marketDayEndMinute),
    );
    await _persistence.save(next);
    if (mounted) setState(() => _state = next);
    return next;
  }

  Future<GameState> _saveMarketNotebook(
    Set<String> favoriteAssetIds,
    Map<String, String> researchNotes,
  ) async {
    final current = _state!;
    final favorites = favoriteAssetIds.toList()..sort();
    final notes = <String, String>{
      for (final entry in researchNotes.entries)
        if (entry.value.trim().isNotEmpty)
          entry.key: entry.value.trim().substring(
            0,
            math.min(300, entry.value.trim().length),
          ),
    };
    final flags = <String, dynamic>{
      ...current.story.storyFlags,
      'marketFavoriteAssetIds': favorites,
      'marketResearchNotes': notes,
    };
    final next = current.copyWith(
      story: current.story.copyWith(storyFlags: flags),
    );
    await _persistence.save(next);
    if (mounted) setState(() => _state = next);
    return next;
  }

  Future<TradeExecutionResult> _executeTrade(TradeOrder order) async {
    final current = _state!;
    HistoricalTradeQuote? quote;
    try {
      quote = resolveHistoricalTradeQuote(
        await HistoricalMarketUniverse.load(),
        current,
        order.assetId,
      );
    } catch (_) {
      return TradeExecutionResult(
        state: current,
        success: false,
        message: '기준 시세를 확인하지 못했어요. 잠시 뒤 다시 시도해 주세요.',
      );
    }
    final asset = quote?.asset;
    if (quote == null ||
        asset == null ||
        order.symbol != asset.code ||
        order.name != asset.name ||
        order.market != asset.market ||
        order.currency != asset.currency ||
        order.quoteDate != quote.quoteDate ||
        order.marketMinute != quote.marketMinute ||
        order.unitPrice != quote.unitPrice ||
        order.isTradingDay != quote.isTradingDay) {
      return TradeExecutionResult(
        state: current,
        success: false,
        message: '기준 시세가 바뀌었어요. 주문창을 다시 확인해 주세요.',
      );
    }
    final result = _engine.executeTrade(current, order);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _transferBrokerageCash(
    int amount,
    bool deposit,
  ) async {
    final result = _engine.transferBrokerageCash(
      _state!,
      amount: amount,
      deposit: deposit,
    );
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: '부자되기 시뮬레이션',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: _sky,
        colorScheme: ColorScheme.fromSeed(seedColor: _blue),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: _ink,
            fontSize: 34,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.8,
          ),
          titleLarge: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF5C6884),
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: !_isReady
          ? const _GameFrame(child: _LoadingScreen())
          : _restoreError != null
          ? _GameFrame(
              child: _RestoreFailureScreen(
                onRetry: () => unawaited(_restoreGame(retry: true)),
              ),
            )
          : _GameFrame(
              child: switch (_view) {
                _AppView.title => _GameTitleScreen(
                  occupiedSlots: _slots.where((slot) => !slot.isEmpty).length,
                  onNewGame: _startNewGame,
                  onContinue: _showContinue,
                ),
                _AppView.continueGame => _SaveSlotScreen(
                  slots: _slots,
                  activeSlot: _activeSlot,
                  onLoad: _continueSlot,
                  onDelete: _deleteSaveSlot,
                  onBack: _showTitle,
                ),
                _AppView.onboarding => VisualNovelOnboardingScreen(
                  onCreate: _createCompany,
                  onExit: _showTitle,
                ),
                _AppView.game when _state != null => OfficeScreen(
                  state: _state!,
                  engine: _engine,
                  activeSaveSlot: _activeSlot,
                  lastSavedAt: _lastSavedAt,
                  onManualSave: _manualSave,
                  onReturnToTitle: _returnToTitle,
                  onAdvanceDay: _advanceDay,
                  onAdvanceDays: _advanceDays,
                  onSetMarketMinute: _setMarketMinute,
                  onSaveMarketNotebook: _saveMarketNotebook,
                  onResolveDecision: _resolveDecision,
                  onClaimMission: _claimMission,
                  onRequestFamilyHelp: _requestFamilyHelp,
                  onHireEmployee: _hireEmployee,
                  onLaunchFund: _launchFund,
                  onPurchaseSpendingOption: _purchaseSpendingOption,
                  onSellRealEstate: _sellRealEstate,
                  onPlayChanceGame: _playAdultChanceGame,
                  onCompleteHubTutorial: _completeHubTutorial,
                  onArchiveNews: _archiveNews,
                  onCompleteWork: _completeWork,
                  onExecuteTrade: _executeTrade,
                  onTransferBrokerageCash: _transferBrokerageCash,
                ),
                _ => _GameTitleScreen(
                  occupiedSlots: _slots.where((slot) => !slot.isEmpty).length,
                  onNewGame: _startNewGame,
                  onContinue: _showContinue,
                ),
              },
            ),
    );
  }
}

class _GameFrame extends StatelessWidget {
  const _GameFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _sky,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: _cream,
              boxShadow: [
                BoxShadow(
                  color: Color(0x4033405F),
                  blurRadius: 34,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: _sky,
    body: Center(child: CircularProgressIndicator(color: _coral)),
  );
}

class _RestoreFailureScreen extends StatelessWidget {
  const _RestoreFailureScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('restore-failure-screen'),
    backgroundColor: const Color(0xFF171B2A),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _ink, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.save_as_rounded, color: _coral, size: 52),
                const SizedBox(height: 16),
                Text(
                  '저장 데이터를\n불러오지 못했어요',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const Text(
                  '기존 저장은 지우거나 덮어쓰지 않았습니다.\n잠시 후 같은 저장으로 다시 시도해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5C6884),
                    fontSize: 12,
                    height: 1.55,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const Key('restore-retry-button'),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('다시 불러오기'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: _ink,
                      backgroundColor: _yellow,
                      elevation: 0,
                      side: const BorderSide(color: _ink, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class NewGameSetup {
  const NewGameSetup({
    required this.playerName,
    required this.companyName,
    required this.introChoice,
    required this.startingTrait,
    required this.familyRule,
  });

  final String playerName;
  final String companyName;
  final String introChoice;
  final StoryTrait startingTrait;
  final FamilyRule familyRule;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onCreate});

  final ValueChanged<NewGameSetup> onCreate;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _playerController = TextEditingController();
  final _companyController = TextEditingController();
  int _step = 0;
  String? _introChoice;
  StoryTrait? _trait;
  FamilyRule? _familyRule;

  @override
  void dispose() {
    _playerController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _finish() {
    final playerName = _playerController.text.trim();
    final companyName = _companyController.text.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (playerName.isEmpty ||
        companyName.isEmpty ||
        _introChoice == null ||
        _trait == null ||
        _familyRule == null) {
      return;
    }
    widget.onCreate(
      NewGameSetup(
        playerName: playerName,
        companyName: companyName,
        introChoice: _introChoice!,
        startingTrait: _trait!,
        familyRule: _familyRule!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _step == 0 ? '1999.12.31 · 23:57' : '2000.01.01 · 새 천년';
    return Scaffold(
      backgroundColor: _sky,
      body: SafeArea(
        child: Column(
          children: [
            _BrandHeader(trailing: dateLabel),
            _StoryProgress(step: _step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: ListView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: _buildStep(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStep(BuildContext context) => switch (_step) {
    0 => _buildColdOpen(context),
    1 => _buildEnvelope(context),
    2 => _buildFamilyAgreement(context),
    _ => _buildResearchDesk(context),
  };

  List<Widget> _buildColdOpen(BuildContext context) => [
    const _Sticker(icon: Icons.nightlight_round, label: '00 / NEW MILLENNIUM'),
    const SizedBox(height: 15),
    Text('새 천년,\n낡은 컴퓨터', style: Theme.of(context).textTheme.headlineLarge),
    const SizedBox(height: 10),
    const Text(
      '모두가 새 천년을 기다리던 밤, 우리 집에는 버려질 뻔한 베이지색 컴퓨터 한 대가 들어왔습니다.',
      style: TextStyle(
        color: Color(0xFF596783),
        fontSize: 13,
        height: 1.5,
        fontWeight: FontWeight.w700,
      ),
    ),
    const SizedBox(height: 10),
    _OutlinedCard(
      color: const Color(0xFF26334F),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '거실 · TV 카운트다운',
                  style: TextStyle(
                    color: _yellow,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '누나  “날짜가 1900년으로 돌아가면 어떡해?”',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '아빠  “망가지면 고치면 되지.”',
                  style: TextStyle(
                    color: Color(0xFFD9E6FF),
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 82,
            height: 118,
            child: Image.asset(
              'assets/images/hero-boy.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    const Text(
      '열 살인 나는 처음으로 뭐라고 말했을까?',
      style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w900),
    ),
    const SizedBox(height: 8),
    _StoryOption(
      key: const Key('story-intro-computer'),
      title: '“제가 먼저 켜봐도 돼요?”',
      subtitle: '호기심 · 아버지와 컴퓨터를 살펴봅니다.',
      onTap: () => setState(() {
        _introChoice = 'computer';
        _step = 1;
      }),
    ),
    _StoryOption(
      key: const Key('story-intro-y2k'),
      title: '“정말 컴퓨터가 다 멈출 수도 있어요?”',
      subtitle: '신중함 · 어머니와 위험을 먼저 확인합니다.',
      onTap: () => setState(() {
        _introChoice = 'y2k';
        _step = 1;
      }),
    ),
    _StoryOption(
      key: const Key('story-intro-stocks'),
      title: '“이걸로 주식도 살 수 있어요?”',
      subtitle: '야심 · 투자와 책임 이야기가 일찍 시작됩니다.',
      onTap: () => setState(() {
        _introChoice = 'stocks';
        _step = 1;
      }),
    ),
  ];

  List<Widget> _buildEnvelope(BuildContext context) {
    final canContinue =
        _playerController.text.trim().isNotEmpty && _trait != null;
    return [
      _BackStoryButton(onTap: () => setState(() => _step = 0)),
      const _Sticker(icon: Icons.mail_rounded, label: '첫 투자 장부'),
      const SizedBox(height: 14),
      Text(
        '초기자본 0원\n직접 번 종잣돈으로 시작',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 10),
      const _OutlinedCard(
        color: Color(0xFFFFFEF8),
        child: Text(
          '“첫 돈은 네가 직접 벌어 보아라. 어떤 회사를 믿고, 왜 믿었는지도 함께 기록해라.”\n\n계좌는 0원으로 열고 어머니 명의로 관리합니다. 나는 일거리로 종잣돈 1만원을 먼저 마련한 뒤, 기업을 조사하고 투자 제안서를 씁니다.',
          style: TextStyle(
            color: _ink,
            fontSize: 12,
            height: 1.55,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        key: const Key('player-name-input'),
        controller: _playerController,
        maxLength: 12,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: '주인공 이름',
          hintText: '예: 민준',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      const Text(
        '왜 투자 기록을 시작하고 싶을까?',
        style: TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      _StoryOption(
        key: const Key('story-trait-stability'),
        title: '부모님이 돈 때문에 싸우지 않았으면 좋겠어요',
        subtitle: '안정 · 현금관리와 위험통제에 관심을 둡니다.',
        selected: _trait == StoryTrait.stability,
        onTap: () => setState(() => _trait = StoryTrait.stability),
      ),
      _StoryOption(
        key: const Key('story-trait-innovation'),
        title: '세상을 바꾸는 회사를 먼저 찾고 싶어요',
        subtitle: '혁신 · 기술과 제품을 먼저 살펴봅니다.',
        selected: _trait == StoryTrait.innovation,
        onTap: () => setState(() => _trait = StoryTrait.innovation),
      ),
      _StoryOption(
        key: const Key('story-trait-analysis'),
        title: '신문 속 숫자가 왜 움직이는지 알고 싶어요',
        subtitle: '분석 · 재무와 시장 기록을 꼼꼼히 봅니다.',
        selected: _trait == StoryTrait.analysis,
        onTap: () => setState(() => _trait = StoryTrait.analysis),
      ),
      _StoryOption(
        key: const Key('story-trait-control'),
        title: '언젠가 큰 회사의 주인이 되고 싶어요',
        subtitle: '지배 · 지분과 이사회라는 장기 목표를 세웁니다.',
        selected: _trait == StoryTrait.control,
        onTap: () => setState(() => _trait = StoryTrait.control),
      ),
      const SizedBox(height: 5),
      _StoryNextButton(
        key: const Key('story-next-motivation'),
        label: '가족과 약속 정하기',
        enabled: canContinue,
        onTap: () => setState(() => _step = 2),
      ),
    ];
  }

  List<Widget> _buildFamilyAgreement(BuildContext context) => [
    _BackStoryButton(onTap: () => setState(() => _step = 1)),
    const _Sticker(
      icon: Icons.family_restroom_rounded,
      label: '01 / FAMILY AGREEMENT',
    ),
    const SizedBox(height: 14),
    Text('우리 가족의\n투자 약속', style: Theme.of(context).textTheme.headlineLarge),
    const SizedBox(height: 10),
    const _OutlinedCard(
      color: Color(0xFFFFF4B8),
      child: Text(
        '생활비와 투자금은 섞지 않는다.\n빚을 내지 않는다.\n처음에는 한 번에 10만원 이상 사지 않는다.\n비밀번호와 도장은 부모님이 보관한다.',
        style: TextStyle(
          color: _ink,
          fontSize: 12,
          height: 1.65,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    const SizedBox(height: 14),
    const Text(
      '마지막 한 줄은 내가 고릅니다.',
      style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w900),
    ),
    const SizedBox(height: 8),
    _StoryOption(
      key: const Key('family-rule-report-losses'),
      title: '손실을 숨기지 않는다',
      subtitle: '정직한 보고 · 어머니 신뢰가 높아집니다.',
      selected: _familyRule == FamilyRule.reportLosses,
      onTap: () => setState(() => _familyRule = FamilyRule.reportLosses),
    ),
    _StoryOption(
      key: const Key('family-rule-no-hot-tips'),
      title: '남이 찍어준 종목은 사지 않는다',
      subtitle: '독립적인 조사 · 아버지 신뢰가 높아집니다.',
      selected: _familyRule == FamilyRule.noHotTips,
      onTap: () => setState(() => _familyRule = FamilyRule.noHotTips),
    ),
    _StoryOption(
      key: const Key('family-rule-keep-cash'),
      title: '매달 현금을 남겨둔다',
      subtitle: '위기 대비 · 외할아버지 신뢰가 높아집니다.',
      selected: _familyRule == FamilyRule.keepCash,
      onTap: () => setState(() => _familyRule = FamilyRule.keepCash),
    ),
    const SizedBox(height: 5),
    _StoryNextButton(
      key: const Key('story-next-family-rule'),
      label: 'A4 간판 만들기',
      enabled: _familyRule != null,
      onTap: () => setState(() => _step = 3),
    ),
  ];

  List<Widget> _buildResearchDesk(BuildContext context) => [
    _BackStoryButton(onTap: () => setState(() => _step = 2)),
    const _Sticker(icon: Icons.edit_note_rounded, label: '02 / RESEARCH DESK'),
    const SizedBox(height: 14),
    Text('A4 용지에\n이름을 적어보자', style: Theme.of(context).textTheme.headlineLarge),
    const SizedBox(height: 10),
    const Text(
      '아직 법인은 아니에요. 엄마가 관리하는 교육용 계좌와 작은방 책상에서 시작하는 가족 투자연구소입니다.',
      style: TextStyle(
        color: Color(0xFF596783),
        fontSize: 13,
        height: 1.5,
        fontWeight: FontWeight.w700,
      ),
    ),
    const SizedBox(height: 12),
    const _StartingConditions(),
    const SizedBox(height: 14),
    _CompanyNameCard(
      controller: _companyController,
      onChanged: (_) => setState(() {}),
      onSubmit: _finish,
    ),
  ];
}

class _StoryProgress extends StatelessWidget {
  const _StoryProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xEFFFFEF8),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 7),
      child: Row(
        children: List.generate(4, (index) {
          final active = index <= step;
          return Expanded(
            child: Container(
              height: 5,
              margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
              decoration: BoxDecoration(
                color: active ? _coral : const Color(0xFFD9DDE2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StoryOption extends StatelessWidget {
  const _StoryOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFFF4B8) : Colors.white,
              border: Border.all(color: _ink, width: selected ? 3 : 2),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: _ink, offset: Offset(0, 3))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6D7892),
                          fontSize: 9,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected ? _coral : _ink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryNextButton extends StatelessWidget {
  const _StoryNextButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          foregroundColor: _ink,
          backgroundColor: _yellow,
          disabledBackgroundColor: const Color(0xFFE4E6E5),
          elevation: 0,
          side: const BorderSide(color: _ink, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _BackStoryButton extends StatelessWidget {
  const _BackStoryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: const Text('이전 장면'),
        style: TextButton.styleFrom(foregroundColor: _ink),
      ),
    );
  }
}

class OfficeScreen extends StatelessWidget {
  const OfficeScreen({
    super.key,
    required this.state,
    required this.engine,
    required this.activeSaveSlot,
    required this.lastSavedAt,
    required this.onManualSave,
    required this.onReturnToTitle,
    required this.onAdvanceDay,
    this.onAdvanceDays,
    required this.onSetMarketMinute,
    required this.onSaveMarketNotebook,
    required this.onResolveDecision,
    this.onClaimMission,
    required this.onRequestFamilyHelp,
    this.onHireEmployee,
    this.onLaunchFund,
    this.onPurchaseSpendingOption,
    this.onSellRealEstate,
    this.onPlayChanceGame,
    this.onCompleteHubTutorial,
    this.onArchiveNews,
    this.onBuildDailyNewspaper,
    required this.onCompleteWork,
    required this.onExecuteTrade,
    this.onTransferBrokerageCash,
  });

  final GameState state;
  final GameEngine engine;
  final int activeSaveSlot;
  final DateTime? lastSavedAt;
  final Future<void> Function() onManualSave;
  final VoidCallback onReturnToTitle;
  final Future<GameState> Function() onAdvanceDay;
  final Future<GameState> Function(int days)? onAdvanceDays;
  final Future<GameState> Function(int) onSetMarketMinute;
  final Future<GameState> Function(Set<String>, Map<String, String>)
  onSaveMarketNotebook;
  final Future<void> Function(String, String) onResolveDecision;
  final Future<MissionClaimResult> Function()? onClaimMission;
  final Future<GameState> Function(String) onRequestFamilyHelp;
  final Future<GameState> Function(String)? onHireEmployee;
  final Future<GameState> Function()? onLaunchFund;
  final Future<FinanceActionResult> Function(String optionId)?
  onPurchaseSpendingOption;
  final Future<FinanceActionResult> Function(String assetId)? onSellRealEstate;
  final Future<FinanceActionResult> Function(int stake)? onPlayChanceGame;
  final Future<void> Function()? onCompleteHubTutorial;
  final Future<void> Function(String headline, List<String> eventIds)?
  onArchiveNews;
  final Future<DailyMarketNewspaper> Function(GameState)? onBuildDailyNewspaper;
  final Future<GameState> Function(WorkSessionResult) onCompleteWork;
  final Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade;
  final Future<FinanceActionResult> Function(int amount, bool deposit)?
  onTransferBrokerageCash;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF17130F),
    body: SafeArea(
      child: ApartmentHubScreen(
        state: state,
        onOpenDecisions: () => _openDecision(context),
        onOpenMarket: () => Navigator.of(context).push(
          _gameSceneRoute<void>(
            StockMarketScreen(
              state: state,
              onSetMarketMinute: onSetMarketMinute,
              onSaveMarketNotebook: onSaveMarketNotebook,
              onClaimMission: onClaimMission,
              onExecuteTrade: onExecuteTrade,
              onTransferCash: onTransferBrokerageCash,
            ),
          ),
        ),
        onOpenLedger: () => _openLedger(context),
        onOpenOrganization: () => Navigator.of(context).push(
          _gameSceneRoute<void>(
            OrganizationScreen(
              state: state,
              onRequestFamilyHelp: onRequestFamilyHelp,
              onHireEmployee: onHireEmployee,
              onLaunchFund: onLaunchFund,
            ),
          ),
        ),
        onOpenWork: () => Navigator.of(context).push(
          _gameSceneRoute<void>(
            SeedMoneyHubScreen(state: state, onComplete: onCompleteWork),
          ),
        ),
        activeSaveSlot: activeSaveSlot,
        lastSavedAt: lastSavedAt,
        onOpenGameMenu: () => _showGameMenu(context),
        onAdvanceHour: () => _handleAdvanceHour(context),
        onAdvanceDay: () => _handleAdvanceDay(context),
        onAdvanceBatch: () => _showAdvanceMenu(context),
        onOpenEnding: () => Navigator.of(
          context,
        ).push(_gameSceneRoute<void>(CampaignEndingScreen(state: state))),
        onTutorialComplete: onCompleteHubTutorial,
      ),
    ),
  );
  Future<void> _showGameMenu(BuildContext context) async {
    final action = await showModalBottomSheet<_GameMenuAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF7F3EA),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B263A),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.save_rounded,
                      color: Color(0xFFFFD76A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$activeSaveSlot번 저장 슬롯',
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          lastSavedAt == null
                              ? '아직 저장 시각 정보가 없습니다'
                              : '최근 저장 ${_savedAtLabel(lastSavedAt)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2E8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.autorenew_rounded,
                      color: Color(0xFF3C7651),
                      size: 19,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '게임 날짜가 하루 넘어갈 때마다 자동 저장됩니다.',
                        style: TextStyle(
                          color: Color(0xFF315F42),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: const Key('manual-save-button'),
                onPressed: () =>
                    Navigator.pop(sheetContext, _GameMenuAction.save),
                icon: const Icon(Icons.save_rounded),
                label: const Text('지금 수동저장'),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                key: const Key('return-title-button'),
                onPressed: () =>
                    Navigator.pop(sheetContext, _GameMenuAction.title),
                icon: const Icon(Icons.home_outlined),
                label: const Text('타이틀로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == _GameMenuAction.save) {
      try {
        await onManualSave();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$activeSaveSlot번 슬롯에 수동저장했습니다.')),
        );
      } catch (_) {
        if (context.mounted) _showSaveFailure(context);
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('타이틀로 돌아갈까요?'),
        content: const Text('현재 진행은 이미 저장되어 있습니다. 필요하면 먼저 수동저장할 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('계속 플레이'),
          ),
          FilledButton(
            key: const Key('confirm-return-title-button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('타이틀로'),
          ),
        ],
      ),
    );
    if (confirmed == true) onReturnToTitle();
  }

  Future<void> _handleAdvanceHour(BuildContext context) async {
    final target = math.min(state.marketMinute + 60, marketDayEndMinute);
    try {
      final saved = await onSetMarketMinute(target);
      if (saved.marketMinute != target) return;
    } catch (_) {
      if (context.mounted) _showSaveFailure(context);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${marketTimeLabel(target)} · 아파트 시간이 1시간 흘렀어요.')),
    );
  }

  Future<void> _showAdvanceMenu(BuildContext context) async {
    if (onAdvanceDays == null) return;
    final selection = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '빠르게 진행',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text('모든 날짜를 하루씩 계산하므로 기업행동·월 비용·결정 이벤트를 건너뛰지 않습니다.'),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.next_plan_rounded),
                  title: const Text('다음 거래일까지'),
                  onTap: () {
                    var days = 1;
                    while (days < 14 &&
                        !isMarketTradingDay(
                          state.currentDate.add(Duration(days: days)),
                        )) {
                      days++;
                    }
                    Navigator.pop(sheetContext, days);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.view_week_rounded),
                  title: const Text('1주 진행'),
                  onTap: () => Navigator.pop(sheetContext, 7),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text('1개월 진행'),
                  onTap: () => Navigator.pop(sheetContext, 30),
                ),
                ListTile(
                  leading: const Icon(Icons.event_available_rounded),
                  title: const Text('다음 결정까지 (최대 90일)'),
                  onTap: () => Navigator.pop(sheetContext, 90),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selection == null || !context.mounted) return;
    try {
      final next = await onAdvanceDays!(selection);
      if (!context.mounted) return;
      final advanced = next.day - state.day;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next.pendingDecisions.isNotEmpty
                ? '$advanced일 진행 후 새 안건 앞에서 멈췄습니다.'
                : '$advanced일 진행했습니다.',
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) _showSaveFailure(context);
    }
  }

  Future<void> _handleAdvanceDay(BuildContext context) async {
    try {
      await _advanceDayWithNewspaper(context);
    } catch (_) {
      if (context.mounted) _showSaveFailure(context);
    }
  }

  Future<void> _advanceDayWithNewspaper(BuildContext context) async {
    final navigator = Navigator.of(context);
    final loadingRoute = _gameSceneRoute<void>(
      NewsGeneratingScene(date: state.currentDate),
    );
    navigator.push<void>(loadingRoute);
    final stopwatch = Stopwatch()..start();
    final client = DynamicNewsClient();
    DailyMarketNewspaper newspaper;
    final closingDay = state.day;
    try {
      var closingState = state;
      if (closingState.marketMinute < marketDayEndMinute) {
        closingState = await onSetMarketMinute(marketDayEndMinute);
      }
      if (!context.mounted) return;
      final baseNewspaper = onBuildDailyNewspaper == null
          ? await buildDailyMarketNewspaper(closingState)
          : await onBuildDailyNewspaper!(closingState);
      final article = await client.generate(
        dynamicNewsRequestForState(
          closingState,
          baseNewspaper.brief,
          newspaper: baseNewspaper,
        ),
      );
      newspaper = baseNewspaper.withDynamicArticle(article);
      await onArchiveNews?.call(
        newspaper.headline,
        historicalNewsEventsForDate(closingState.currentDate)
            .map(
              (event) =>
                  '${event.year}-${event.month}-${event.day}-${event.title}',
            )
            .toList(growable: false),
      );
      final remaining = 350 - stopwatch.elapsedMilliseconds;
      if (remaining > 0) {
        await Future<void>.delayed(Duration(milliseconds: remaining));
      }
    } finally {
      client.close();
      if (loadingRoute.isActive) navigator.removeRoute(loadingRoute);
    }
    if (!context.mounted) return;
    await navigator.push<bool>(
      _gameSceneRoute<bool>(KoreaEconomicNewspaperScene(newspaper: newspaper)),
    );
    if (!context.mounted) return;
    var advancedState = await onAdvanceDay();
    if (advancedState.day <= closingDay) {
      throw StateError('신문을 닫은 뒤 다음 날짜로 진행하지 못했습니다.');
    }
    if (advancedState.marketMinute != marketDayStartMinute) {
      advancedState = await onSetMarketMinute(marketDayStartMinute);
    }
    if (advancedState.marketMinute != marketDayStartMinute) {
      throw StateError('다음 날 시작 시각을 08:00으로 저장하지 못했습니다.');
    }
  }

  void _openDecision(BuildContext context) {
    Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        DecisionInboxScreen(
          state: state,
          onResolveDecision: onResolveDecision,
          onClaimMission:
              onClaimMission ??
              () async => MissionClaimResult(
                state: state,
                success: false,
                message: '이 화면에서는 미션 보상을 저장할 수 없습니다.',
              ),
        ),
      ),
    );
  }

  void _openLedger(BuildContext context) {
    Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        PortfolioLedgerScreen(
          state: state,
          onPurchaseSpendingOption:
              onPurchaseSpendingOption ??
              (optionId) async => FinanceActionResult(
                state: state,
                success: false,
                message: '이 화면에서는 저장 기능을 사용할 수 없습니다.',
              ),
          onSellRealEstate:
              onSellRealEstate ??
              (assetId) async => FinanceActionResult(
                state: state,
                success: false,
                message: '이 화면에서는 저장 기능을 사용할 수 없습니다.',
              ),
          onPlayChanceGame:
              onPlayChanceGame ??
              (stake) async => FinanceActionResult(
                state: state,
                success: false,
                message: '이 화면에서는 저장 기능을 사용할 수 없습니다.',
              ),
        ),
      ),
    );
  }
}

SnackBar _saveFailureSnackBar() => const SnackBar(
  content: Text(
    '저장하지 못했어요. 이전 진행 상태를 그대로 유지했습니다.',
    key: Key('save-failure-message'),
  ),
);

void _showSaveFailure(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(_saveFailureSnackBar());
}

class _SceneClockStrip extends StatelessWidget {
  const _SceneClockStrip({
    required this.location,
    required this.caption,
    required this.minute,
    this.costLabel,
    this.onBack,
    this.dark = true,
  });

  final String location;
  final String caption;
  final int minute;
  final String? costLabel;
  final VoidCallback? onBack;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    final foreground = dark ? Colors.white : _ink;
    final secondary = dark ? const Color(0xFFCBD2E0) : const Color(0xFF6B7488);
    return Container(
      key: Key('scene-location-${location.hashCode}'),
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: dark ? const Color(0xE6263148) : const Color(0xF7FFF0D0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? const Color(0x556DD2FF) : const Color(0x6692693F),
          width: dark ? 1 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x33000000) : const Color(0x33432C17),
            blurRadius: dark ? 14 : 5,
            offset: Offset(0, dark ? 6 : 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            SizedBox(
              width: 44,
              height: 44,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(22),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: foreground,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
          ],
          Icon(
            Icons.location_on_rounded,
            color: dark ? _yellow : _coral,
            size: 19,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (costLabel != null && !compact) ...[
            Container(
              margin: const EdgeInsets.only(right: 7),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: dark ? const Color(0x334DB8E8) : const Color(0xFFF4D582),
                borderRadius: BorderRadius.circular(9),
                border: dark
                    ? null
                    : Border.all(color: const Color(0xFFB98345), width: 0.8),
              ),
              child: Text(
                costLabel!,
                style: TextStyle(
                  color: foreground,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          Text(
            marketTimeLabel(minute),
            key: const Key('scene-clock-time'),
            style: TextStyle(
              color: foreground,
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class FamilyDecisionScene extends StatefulWidget {
  const FamilyDecisionScene({
    super.key,
    required this.state,
    required this.decision,
    required this.onSelect,
  });
  final GameState state;
  final DecisionCardData decision;
  final Future<void> Function(BuildContext context, String optionId) onSelect;

  @override
  State<FamilyDecisionScene> createState() => _FamilyDecisionSceneState();
}

class _FamilyDecisionSceneState extends State<FamilyDecisionScene> {
  bool _isSubmitting = false;

  Future<void> _handleSelect(String optionId) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSelect(context, optionId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('안건 저장에 실패했어요. 다시 선택해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isSubmitting,
    child: Scaffold(
      backgroundColor: const Color(0xFF22253A),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_living_room_1999.png',
              fit: BoxFit.cover,
            ),
          ),
          const Positioned.fill(child: ColoredBox(color: Color(0x8A171926))),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    _SceneClockStrip(
                      location: '우리 집 거실 · 가족회의',
                      caption: _isSubmitting
                          ? '선택을 투자노트에 저장하고 있다.'
                          : '가족이 함께 읽는 중이에요. 어려운 말은 아래에서 풀어드려요.',
                      minute: widget.state.marketMinute,
                      costLabel: _isSubmitting ? '저장 중' : '함께 고르기 · 30분',
                      onBack: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: AbsorbPointer(
                              absorbing: _isSubmitting,
                              child: DecisionSheet(
                                state: widget.state,
                                decision: widget.decision,
                                onSelect: _handleSelect,
                              ),
                            ),
                          ),
                          if (_isSubmitting)
                            const Positioned(
                              left: 20,
                              right: 20,
                              bottom: 20,
                              child: _DecisionSavingIndicator(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DecisionSavingIndicator extends StatelessWidget {
  const _DecisionSavingIndicator();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('decision-saving-indicator'),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0xF2FFF8E7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _ink, width: 2),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        SizedBox(width: 10),
        Text('투자노트에 저장 중…', style: TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class NewsGeneratingScene extends StatelessWidget {
  const NewsGeneratingScene({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      backgroundColor: const Color(0xFF24212B),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_living_room_1999.png',
              fit: BoxFit.cover,
            ),
          ),
          const Positioned.fill(child: ColoredBox(color: Color(0xA3181620))),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    const _SceneClockStrip(
                      location: '우리 집 거실 · 편집 마감',
                      caption: '오늘의 선택과 시장 기록을 기사로 엮고 있다.',
                      minute: marketDayEndMinute,
                      costLabel: 'AI 특별판',
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          key: const Key('news-generating-scene'),
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F0E4),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFF24211C),
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.newspaper_rounded,
                                color: Color(0xFF24211C),
                                size: 52,
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                '뉴스를 생성 중입니다',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF171512),
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${date.year}년의 시대 흐름과\n오늘의 행동을 취재하고 있어요.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF615B52),
                                  fontSize: 12,
                                  height: 1.55,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 22),
                              const SizedBox(
                                width: 34,
                                height: 34,
                                child: CircularProgressIndicator(
                                  strokeWidth: 4,
                                  color: Color(0xFFD45D52),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                '연결이 늦어지면 기존 시장 기록으로 신문을 완성합니다.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF777168),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
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
    ),
  );
}

class KoreaEconomicNewspaperScene extends StatelessWidget {
  const KoreaEconomicNewspaperScene({super.key, required this.newspaper});
  final DailyMarketNewspaper newspaper;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF24212B),
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/bg_living_room_1999.png',
            fit: BoxFit.cover,
          ),
        ),
        const Positioned.fill(child: ColoredBox(color: Color(0x83181620))),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  _SceneClockStrip(
                    location: '우리 집 거실 · 저녁 신문',
                    caption: '가족이 식탁에 둘러앉아 오늘의 시장을 정리한다.',
                    minute: marketDayEndMinute,
                    costLabel: '하루 결산',
                    onBack: () => Navigator.of(context).pop(true),
                  ),
                  Expanded(
                    child: KoreaEconomicNewspaperSheet(newspaper: newspaper),
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

class DecisionSheet extends StatelessWidget {
  const DecisionSheet({
    super.key,
    required this.state,
    required this.decision,
    required this.onSelect,
  });

  final GameState state;
  final DecisionCardData decision;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.96,
      minChildSize: 0.72,
      maxChildSize: 0.96,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: _ink, width: 3)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF9BA5B7),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Sticker(
                  icon: Icons.campaign_rounded,
                  label: decision.category,
                ),
                const Spacer(),
                Text(
                  'DAY ${decision.dueDay}까지 선택',
                  style: const TextStyle(
                    color: _coral,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(decision.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(
              '이야기를 꺼낸 사람 · ${decision.proposer}',
              style: const TextStyle(
                color: Color(0xFF6E7890),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(decision.body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Container(
              key: const Key('decision-reward-preview'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFDDF3FF),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _blue, width: 1.5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18, color: _ink),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '정답은 없어요 · 선택하면 +25 XP · 미션 +1',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FactChip(
                    label: '좋아지는 점',
                    value: decision.benefit,
                    color: const Color(0xFFDFF7EF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FactChip(
                    label: '조심할 점',
                    value: decision.risk,
                    color: const Color(0xFFFFE3DF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '내 생각과 가까운 쪽은?',
              style: TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...decision.options.map((option) {
              final locked = option.cashCost > state.cash;
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: SizedBox(
                  height: 64,
                  child: ElevatedButton(
                    key: Key('decision-option-${option.id}'),
                    onPressed: locked ? null : () => onSelect(option.id),
                    style: ElevatedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: _ink,
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE5E7E8),
                      elevation: 0,
                      side: const BorderSide(color: _ink, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                locked
                                    ? '현금 부족 · ${_money(option.cashCost)}원 필요'
                                    : option.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                key: const Key('decision-advisor-opinions'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 6),
                title: const Text(
                  '가족 의견 더 보기',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                children: decision.advisorOpinions
                    .map(
                      (opinion) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '• $opinion',
                            style: const TextStyle(
                              color: Color(0xFF66718A),
                              fontSize: 11,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const Text(
              '실제 회사 이름이 나와도 수치와 결과는 게임용 이야기예요. 선택한 뒤 결과를 보며 천천히 배워 보세요.',
              style: TextStyle(
                color: Color(0xFF8A92A2),
                fontSize: 9,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficeStatusCard extends StatelessWidget {
  const _OfficeStatusCard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final diverged = state.company.worldMode == WorldMode.diverged;
    final authority = state.story.accountAuthorityLevel;
    final orderLimit = switch (authority) {
      0 => '관찰 전용',
      1 => '10만원',
      2 => '25만원',
      3 => '자산 25%',
      4 => '500만원',
      _ => '제한 없음',
    };
    return _OutlinedCard(
      color: const Color(0xF7FFFEF8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DAY ${state.day} · ${state.companyName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _coral,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: diverged
                      ? const Color(0xFFFFE3DF)
                      : const Color(0xFFDFF7EF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  diverged ? '대체역사 진행 중' : 'FAMILY RESEARCH DESK',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _StatusValue(
                  label: '연구계좌 현금',
                  value: '${_money(state.cash)}원',
                ),
              ),
              Expanded(
                child: _StatusValue(
                  label: '가족 신뢰',
                  value: '${state.story.familyTrust}',
                ),
              ),
              _StatusValue(label: '주문 한도', value: orderLimit),
              _StatusValue(label: '평판', value: '${state.story.reputation}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            diverged
                ? '분기 DAY ${state.company.divergedAtDay} · ${state.company.divergenceReason}'
                : '계좌 명의: 어머니 · 생활비와 분리 · 대출·미수·신용 금지',
            style: const TextStyle(
              color: Color(0xFF7B849A),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

typedef _NewsToneStyle = ({
  Color fill,
  Color accent,
  IconData icon,
  String tag,
});

_NewsToneStyle _newsToneStyle(NewsTone tone) => switch (tone) {
  NewsTone.breaking => (
    fill: const Color(0xFFFFF0EC),
    accent: _coral,
    icon: Icons.campaign_rounded,
    tag: '속보',
  ),
  NewsTone.shock => (
    fill: const Color(0xFFFFE6E1),
    accent: const Color(0xFFE0574B),
    icon: Icons.warning_amber_rounded,
    tag: '시장 충격',
  ),
  NewsTone.launch => (
    fill: const Color(0xFFE7F4FF),
    accent: const Color(0xFF3E8FD0),
    icon: Icons.rocket_launch_rounded,
    tag: '새 소식',
  ),
  NewsTone.milestone => (
    fill: const Color(0xFFFFF7DA),
    accent: const Color(0xFFE0A100),
    icon: Icons.auto_awesome_rounded,
    tag: '오늘의 소식',
  ),
  NewsTone.weekend => (
    fill: const Color(0xFFECEEF6),
    accent: const Color(0xFF7C86A0),
    icon: Icons.weekend_rounded,
    tag: '주말',
  ),
  NewsTone.holiday => (
    fill: const Color(0xFFEFEAF7),
    accent: const Color(0xFF8A6FC0),
    icon: Icons.celebration_rounded,
    tag: '휴장',
  ),
  NewsTone.calm => (
    fill: const Color(0xFFE7F5EC),
    accent: const Color(0xFF3AA982),
    icon: Icons.wb_sunny_rounded,
    tag: '오늘의 소식',
  ),
};

class _TodayNewsCard extends StatelessWidget {
  const _TodayNewsCard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final brief = buildDailyBrief(state);
    final pending = state.pendingDecisions;
    final project = state.project;
    final tone = _newsToneStyle(brief.tone);

    return _OutlinedCard(
      color: tone.fill,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tone.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tone.icon, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      brief.isBreaking ? tone.tag : '오늘의 소식',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  brief.eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7B849A),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _MarketStatusPill(closed: brief.marketClosed),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            brief.title,
            style: const TextStyle(
              color: _ink,
              fontSize: 15,
              height: 1.25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            brief.body,
            style: const TextStyle(
              color: Color(0xFF5E6883),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xF2FFFEF8),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0x2233405F), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  pending.isEmpty
                      ? Icons.schedule_rounded
                      : Icons.notifications_active_rounded,
                  color: pending.isEmpty ? const Color(0xFF3AA982) : _coral,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pending.isEmpty ? '시간을 보내도 좋아요' : '중요 안건에서 시간이 멈췄어요',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        pending.isNotEmpty
                            ? pending.first.title
                            : project == null
                            ? '1시간씩 진행하고 오늘 신문에서 하루를 마쳐요.'
                            : 'Project Atlas · ${_projectLabel(project.status)} · 다음 변화 대기 중',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7B849A),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

class _MarketStatusPill extends StatelessWidget {
  const _MarketStatusPill({required this.closed});

  final bool closed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: closed ? const Color(0xFFE7E9F0) : const Color(0xFFDFF7EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: closed ? const Color(0x3333405F) : const Color(0x333AA982),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: closed ? const Color(0xFF9AA2B5) : const Color(0xFF3AA982),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            closed ? '휴장' : '개장',
            style: TextStyle(
              color: closed ? const Color(0xFF6B7488) : const Color(0xFF2E8768),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class NewsBulletinSheet extends StatelessWidget {
  const NewsBulletinSheet({super.key, required this.event, required this.date});

  final HistoricalNewsEvent event;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final tone = _newsToneStyle(event.tone);
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.42,
      maxChildSize: 0.9,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: _ink, width: 3)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF9BA5B7),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tone.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tone.icon, color: Colors.white, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        '속보 · ${event.eyebrow}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Color(0xFF7B849A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              event.title,
              style: const TextStyle(
                color: _ink,
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              event.body,
              style: const TextStyle(
                color: Color(0xFF515C77),
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7DA),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _ink, width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    color: Color(0xFFE0A100),
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '투자 메모',
                          style: TextStyle(
                            color: _coral,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          event.signal,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            height: 1.45,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('확인했어요'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: _ink,
                  backgroundColor: _yellow,
                  elevation: 0,
                  side: const BorderSide(color: _ink, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '실제 사건에서 착안한 게임용 소식입니다. 내부 수치·결과는 가상입니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF9AA2B5),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KoreaEconomicNewspaperSheet extends StatelessWidget {
  const KoreaEconomicNewspaperSheet({super.key, required this.newspaper});
  final DailyMarketNewspaper newspaper;

  @override
  Widget build(BuildContext context) {
    final date = newspaper.date;
    final dateLabel = '${date.year}년 ${date.month}월 ${date.day}일';
    return FractionallySizedBox(
      heightFactor: 0.94,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F0E4),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: Color(0xFF24211C), width: 3)),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Row(
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(color: Color(0xFF24211C), thickness: 1),
            const Text(
              '한국경제신문',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF171512),
                fontSize: 31,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
            const Text(
              '2000~2010 시장 시뮬레이션 특별판',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
            const Divider(color: Color(0xFF24211C), thickness: 3),
            const SizedBox(height: 14),
            Text(
              newspaper.headline,
              style: const TextStyle(
                color: Color(0xFF171512),
                fontSize: 25,
                height: 1.18,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.1,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              newspaper.dynamicArticle?.content ?? newspaper.brief.body,
              style: const TextStyle(
                color: Color(0xFF444039),
                fontSize: 13,
                height: 1.55,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (newspaper.brief.otherHeadlines.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFF1EBDD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '같은 날의 다른 소식',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    ...newspaper.brief.otherHeadlines.map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${event.title}',
                          style: const TextStyle(fontSize: 11, height: 1.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (newspaper.dynamicArticle != null) ...[
              const SizedBox(height: 12),
              _DynamicNewsImpact(article: newspaper.dynamicArticle!),
            ],
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF24211C), width: 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '오늘의 국내 증시',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    newspaper.summary,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _NewspaperStat(
                        label: '상승',
                        value: newspaper.advancers,
                        color: const Color(0xFFD83B45),
                      ),
                      _NewspaperStat(
                        label: '하락',
                        value: newspaper.decliners,
                        color: const Color(0xFF2D6FD2),
                      ),
                      _NewspaperStat(
                        label: '보합',
                        value: newspaper.unchanged,
                        color: const Color(0xFF6B6861),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            if (newspaper.topGainers.isNotEmpty) ...[
              const Text(
                '오늘 많이 오른 종목',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              ...newspaper.topGainers.map(
                (mover) => _NewspaperMoverRow(mover: mover),
              ),
              const SizedBox(height: 10),
            ],
            if (newspaper.topLosers.isNotEmpty) ...[
              const Text(
                '오늘 많이 내린 종목',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              ...newspaper.topLosers.map(
                (mover) => _NewspaperMoverRow(mover: mover),
              ),
              const SizedBox(height: 10),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFE7E0D0),
              child: Text(
                '시장 해설 · ${newspaper.brief.title}\n${newspaper.brief.body}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                key: const Key('newspaper-next-day-button'),
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.wb_sunny_rounded),
                label: const Text('신문 읽고 다음 날 08:00'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFDF68),
                  foregroundColor: const Color(0xFF24211C),
                  side: const BorderSide(color: Color(0xFF24211C), width: 2),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '게임 내 비공식 재현판이며 실제 한국경제신문과 무관합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF777168),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DynamicNewsImpact extends StatelessWidget {
  const _DynamicNewsImpact({required this.article});
  final DynamicNewsArticle article;

  @override
  Widget build(BuildContext context) {
    final positive = article.marketSentiment == 'POSITIVE';
    final negative = article.marketSentiment == 'NEGATIVE';
    final label = positive
        ? '긍정'
        : negative
        ? '부정'
        : '중립';
    final color = positive
        ? const Color(0xFFD83B45)
        : negative
        ? const Color(0xFF2D6FD2)
        : const Color(0xFF6B6861);
    final score = article.stockImpactScore;
    return Container(
      key: const Key('dynamic-news-impact'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFECE4D4),
        border: Border.all(color: const Color(0xFFBDB29F)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI 기자 · 시장 심리 $label',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '영향 ${score >= 0 ? '+' : ''}${score.toStringAsFixed(1)}',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewspaperStat extends StatelessWidget {
  const _NewspaperStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _NewspaperMoverRow extends StatelessWidget {
  const _NewspaperMoverRow({required this.mover});
  final DailyMarketMover mover;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            mover.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          '${mover.changeRate >= 0 ? '+' : ''}${mover.changeRate.toStringAsFixed(2)}%',
          style: TextStyle(
            color: mover.changeRate >= 0
                ? const Color(0xFFD83B45)
                : const Color(0xFF2D6FD2),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class CampaignEndingScreen extends StatelessWidget {
  const CampaignEndingScreen({super.key, required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final realized = state.ledger.fold<int>(
      0,
      (sum, entry) => sum + entry.realizedPnl,
    );
    final fees = state.ledger.fold<int>(
      0,
      (sum, entry) => sum + entry.tradingFee,
    );
    final resolved = state.decisions
        .where((decision) => decision.status == DecisionStatus.resolved)
        .length;
    final history =
        (state.story.storyFlags['performanceHistory'] as List?) ?? const [];
    final benchmarkStart = history.isEmpty
        ? 1000
        : ((history.first as Map)['benchmarkIndex'] as num?)?.toInt() ?? 1000;
    final benchmarkEnd = history.isEmpty
        ? 1000
        : ((history.last as Map)['benchmarkIndex'] as num?)?.toInt() ?? 1000;
    final benchmarkRate = benchmarkStart <= 0
        ? 0.0
        : (benchmarkEnd - benchmarkStart) / benchmarkStart * 100;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1E5),
      appBar: AppBar(title: const Text('2010 최종 결산')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Icon(Icons.emoji_events_rounded, size: 72, color: _coral),
          const Text(
            '새천년의 10년을 완주했습니다',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          _EndingMetric(label: '최종 현금', value: '${_money(state.cash)}원'),
          _EndingMetric(
            label: '보유원가',
            value: '${_money(state.portfolioCost)}원',
          ),
          _EndingMetric(
            label: '누적 실현손익',
            value: '${realized >= 0 ? '+' : ''}${_money(realized)}원',
          ),
          _EndingMetric(label: '누적 거래비용', value: '${_money(fees)}원'),
          _EndingMetric(
            label: '평판 / 가족 신뢰',
            value: '${state.story.reputation} / ${state.story.familyTrust}',
          ),
          _EndingMetric(
            label: '직원 / 외부 AUM',
            value:
                '${state.organization.employees.length}명 / ${_money(state.story.externalAum)}원',
          ),
          _EndingMetric(
            label: '부동산 추정가 / 월 순현금',
            value:
                '${_money(state.personalFinance.estimatedPropertyValueAt(state.day))}원 / ${_money(state.personalFinance.monthlyPropertyIncome - state.personalFinance.monthlyPropertyCost)}원',
          ),
          _EndingMetric(
            label: '선택지출 / 확률 오락 손익',
            value:
                '${_money(state.personalFinance.totalSpent)}원 / ${state.personalFinance.chanceNet >= 0 ? '+' : ''}${_money(state.personalFinance.chanceNet)}원',
          ),
          _EndingMetric(label: '해결한 결정', value: '$resolved건'),
          _EndingMetric(
            label: '기준지수 변화',
            value:
                '${benchmarkRate >= 0 ? '+' : ''}${benchmarkRate.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 16),
          Text(
            state.story.reputation >= 70
                ? '엔딩: 신뢰받는 장기 투자회사'
                : state.story.fundLaunched
                ? '엔딩: 첫 고객과 함께 성장한 운용사'
                : state.story.familyTrust >= 60
                ? '엔딩: 원칙을 지킨 가족 투자연구소'
                : '엔딩: 시장에서 배움을 이어가는 투자자',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _EndingMetric extends StatelessWidget {
  const _EndingMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
  );
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.trailing});

  final String trailing;

  @override
  Widget build(BuildContext context) {
    const displayTitle = '밀레니엄 캐피탈';
    const mark = 'MC';
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xF2FFFEF8),
        border: Border(bottom: BorderSide(color: Color(0x2933405F), width: 2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _yellow,
              border: Border.all(color: _ink, width: 2),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: _ink, offset: Offset(3, 3))],
            ),
            child: Text(
              mark,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  key: const Key('company-header-title'),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '2000 투자 모험',
                  style: TextStyle(
                    color: Color(0xFF5A91AD),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF65728E),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartingConditions extends StatelessWidget {
  const _StartingConditions();

  @override
  Widget build(BuildContext context) {
    const conditions = [
      ('출발하는 날', '2000.01.01', Color(0xFFFFFEF8)),
      ('초기자본', '0원', Color(0xFFFFF4B8)),
      ('창립 인원', '1명', Color(0xFFDFF7EF)),
      ('첫 무대', '한국 · 미국 · 일본', Color(0xFFFFE3DF)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.35,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
      ),
      itemCount: conditions.length,
      itemBuilder: (context, index) {
        final item = conditions[index];
        return _OutlinedCard(
          color: item.$3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.$1,
                style: const TextStyle(
                  color: Color(0xFF7A849A),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompanyNameCard extends StatelessWidget {
  const _CompanyNameCard({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final enabled = controller.text.trim().isNotEmpty;
    return _OutlinedCard(
      color: const Color(0xFFFFFEF8),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '우리 투자연구소 이름',
            style: TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('company-name-input'),
            controller: controller,
            maxLength: 24,
            onChanged: onChanged,
            onSubmitted: (_) => enabled ? onSubmit() : null,
            decoration: InputDecoration(
              hintText: '예: 새벽투자파트너스',
              counterText: '${controller.text.length}/24',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF8792AA),
                  width: 2,
                ),
              ),
            ),
          ),
          const Text(
            '연구소 이름과 가족 약속은 이 기기에 자동 저장돼요.',
            style: TextStyle(
              color: Color(0xFF8790A3),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              key: const Key('create-company-button'),
              onPressed: enabled ? onSubmit : null,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.star_rounded),
              label: const Text('A4 간판 붙이기'),
              style: ElevatedButton.styleFrom(
                foregroundColor: _ink,
                backgroundColor: _coral,
                disabledBackgroundColor: const Color(0xFFE4E6E5),
                elevation: 0,
                side: const BorderSide(color: _ink, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomButton extends StatelessWidget {
  const _RoomButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $subtitle 열기',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: EdgeInsets.all(compact ? 8 : 11),
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: _ink, width: 2),
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [BoxShadow(color: _ink, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                Icon(icon, color: _ink, size: compact ? 21 : 27),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ink,
                          fontSize: compact ? 10 : 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6D7892),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class _CartoonRoomBackground extends StatelessWidget {
  const _CartoonRoomBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE5F8FF), Color(0xFFFFEDBE), Color(0xFFC98B62)],
          stops: [0, 0.66, 1],
        ),
      ),
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _yellow,
        border: Border.all(color: _ink, width: 2),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: _ink, offset: Offset(2, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _coral, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: _ink,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusValue extends StatelessWidget {
  const _StatusValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF7B849A), fontSize: 9),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _ink, width: 2),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _coral,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontSize: 10,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedCard extends StatelessWidget {
  const _OutlinedCard({
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _ink, width: 2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Color(0xCC33405F), offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

String _money(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final result = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) result.write(',');
    result.write(digits[i]);
  }
  return '${negative ? '-' : ''}$result';
}

double? _portfolioPriceAtCurrentTime(
  HistoricalMarketAsset asset,
  GameState state,
) {
  final quote = asset.quoteAtOrBefore(state.currentDate);
  if (quote == null) return null;
  if (!quote.isExactDate) return quote.close;
  final previousClose = asset.previousCloseBefore(quote.date) ?? quote.close;
  final path = generatedFullMarketDayPath(
    previousClose: previousClose,
    officialClose: quote.close,
    seed: marketStockSeed(asset.code, state.currentDate),
  );
  return path[marketTickForMinute(
    state.marketMinute,
  ).clamp(0, path.length - 1)];
}

String _projectLabel(ProjectStatus status) => switch (status) {
  ProjectStatus.proposal => '제안',
  ProjectStatus.development => '개발 중',
  ProjectStatus.launchReview => '출시 심사',
  ProjectStatus.launched => '출시됨',
  ProjectStatus.cancelled => '중단',
  ProjectStatus.completed => '초기 결과 확인',
};
