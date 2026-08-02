import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/news_combinator.dart';
import 'game/banking_state.dart';
import 'game/business_districts.dart';
import 'game/business_engine.dart';
import 'game/business_simulation.dart';
import 'game/business_state.dart';
import 'game/character_profile.dart';
import 'game/cohort_investment_state.dart';
import 'game/game_engine.dart';
import 'game/game_persistence.dart';
import 'game/game_state.dart';
import 'game/home_improvement_state.dart';
import 'game/investor_flow.dart';

import 'game/market_clock.dart';
import 'game/market_data.dart';
import 'game/market_technical_levels.dart';
import 'game/market_tick.dart';
import 'game/market_news.dart';
import 'game/order_book.dart';
import 'game/market_quote.dart';
import 'game/mission_progression.dart';
import 'game/organization_state.dart';
import 'game/real_estate_analysis.dart';
import 'game/real_estate_financing.dart';
import 'game/real_estate_rental.dart';
import 'game/real_estate_world.dart';
import 'game/personal_finance_state.dart';
import 'game/phone_messenger_state.dart';
import 'game/real_estate_market.dart';
import 'game/relationship_state.dart';
import 'game/seed_money_content.dart';
import 'game/star_shop.dart';
import 'game/story_state.dart';
import 'game/world_bootstrapper.dart';
import 'game/world_economy.dart';
export 'game/world_bootstrapper.dart'
    show CampaignWorldPreparer, WorldLoadProgress, WorldLoadProgressCallback;

part 'organization_screen.dart';
part 'apartment_hub_screens.dart';
part 'apartment_ambient_layer.dart';
part 'home_improvement_screen.dart';
part 'business_management_screen.dart';
part 'bank_screen.dart';
part 'rider_mini_game.dart';
part 'save_menu_screens.dart';
part 'asset_spending_screen.dart';
part 'room_screens.dart';
part 'seed_money_screen.dart';
part 'stock_market_screen.dart';
part 'stock_market_order_workspace.dart';
part 'stock_market_order_book.dart';
part 'stock_market_tutorial.dart';
part 'stock_market_corporate_actions.dart';
part 'star_shop_screen.dart';
part 'dialogue/canonical_dialogue_data.dart';
part 'visual_novel_onboarding.dart';
part 'campaign_scenes.dart';
part 'relationship_screens.dart';
part 'cohort_investment_screens.dart';
part 'phone_messenger_screens.dart';

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
  runApp(
    MillenniumCapitalApp(
      stockTestMode: Uri.base.queryParameters['stockTest'] == '1',
      dialoguePreviewMode: Uri.base.queryParameters['dialoguePreview'] == '1',
    ),
  );
}

GameState _firstPlayableMarketState(GameState state) {
  var day = state.day;
  var date = state.currentDate;
  final campaignEnd = DateTime(fictionalCampaignEndYear, 12, 31);
  while (!isMarketTradingDay(date) && date.isBefore(campaignEnd)) {
    day += 1;
    date = state.dateForDay(day);
  }
  return day == state.day
      ? state
      : state.copyWith(day: day, marketMinute: marketDayStartMinute);
}

class MillenniumCapitalApp extends StatefulWidget {
  const MillenniumCapitalApp({
    super.key,
    this.persistence,
    this.campaignWorldPreparer,
    this.stockTestMode = false,
    this.dialoguePreviewMode = false,
    this.dialogueOverrideJson,
  });

  final GamePersistence? persistence;
  final CampaignWorldPreparer? campaignWorldPreparer;
  final bool stockTestMode;
  final bool dialoguePreviewMode;
  final String? dialogueOverrideJson;

  @override
  State<MillenniumCapitalApp> createState() => _MillenniumCapitalAppState();
}

class _MillenniumCapitalAppState extends State<MillenniumCapitalApp> {
  static const _engine = GameEngine();
  static const _businessEngine = LocalBusinessEngine();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final GamePersistence _persistence;
  GameState? _state;
  List<GameSaveSlot> _slots = const [];
  _AppView _view = _AppView.title;
  int _activeSlot = 1;
  int? _newGameSlot;
  String? _newGameWorldSeed;
  GameState? _newGameDraftState;
  Future<void>? _prologueCheckpointQueue;
  DateTime? _lastSavedAt;
  int? _lastDurablySavedMarketDay;
  int? _lastDurablySavedMarketMinute;
  final Map<String, GamePendingOrderQuotePath> _pendingQuotePathCache =
      <String, GamePendingOrderQuotePath>{};
  final StockOrderBookSessionCache _stockOrderBookSessionCache =
      StockOrderBookSessionCache();
  bool _isReady = false;
  bool _isRestoring = false;
  bool _isContinuingSlot = false;
  bool _isPreparingNewGame = false;
  bool _isNewGameWorldPrepared = false;
  bool _marketTutorialLaunchScheduled = false;
  WorldLoadProgress? _worldLoadProgress;
  Object? _restoreError;

  @override
  void initState() {
    super.initState();
    _persistence = widget.persistence ?? GamePersistence();
    if (widget.stockTestMode) {
      final testState = _engine.createNewGame(
        '주식시장 테스트',
        initialCash: 1000000,
        worldSeed: 'stock-market-test-v1',
      );
      _state = _firstPlayableMarketState(
        testState.copyWith(
          story: testState.story.copyWith(accountAuthorityLevel: 5),
        ),
      ).copyWith(marketMinute: krxOpenMinute);
      _view = _AppView.game;
      _isReady = true;
      return;
    }
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
        _lastDurablySavedMarketDay = null;
        _lastDurablySavedMarketMinute = null;
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
    if (_isPreparingNewGame || _isContinuingSlot) return;
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
    unawaited(_prepareNewGameInSlot(freeSlot.slot));
  }

  void _startNewGameInSlot(int slot) {
    if (_isPreparingNewGame || _isContinuingSlot) return;
    GameSaveSlot? target;
    for (final candidate in _slots) {
      if (candidate.slot == slot) {
        target = candidate;
        break;
      }
    }
    if (target == null || !target.isEmpty) return;
    unawaited(_prepareNewGameInSlot(slot));
  }

  Future<void> _prepareNewGameInSlot(int slot) async {
    if (_isPreparingNewGame || _isContinuingSlot) return;
    _isPreparingNewGame = true;
    _isNewGameWorldPrepared = false;
    final draftState = _engine.createNewGame(
      '새 투자연구소',
      initialCash: initialCompanyCash,
    );
    final checkpointState = draftState.copyWith(
      companyName: '프로젝트 데시멀',
      story: draftState.story.copyWith(
        storyFlags: {
          ...draftState.story.storyFlags,
          'prologueInProgress': true,
          'prologueComplete': false,
          'prologueBeat': 0,
          'prologueAcademyPcPoweredOn': false,
          'prologueAcademyStockAppOpen': false,
          'prologuePlayerName': '',
          'prologueCompanyName': '',
        },
      ),
    );
    setState(() {
      _newGameSlot = slot;
      _newGameWorldSeed = draftState.simulationSeed;
      _newGameDraftState = checkpointState;
      _worldLoadProgress = const WorldLoadProgress(
        0.03,
        '새 세계의 시드와 27년 시간축을 확정하는 중입니다…',
      );
      _isReady = false;
    });
    try {
      await _prepareCampaignWorld(draftState, (progress) {
        if (mounted) setState(() => _worldLoadProgress = progress);
      });
      await _persistence.saveToSlot(checkpointState, slot);
      final slots = await _persistence.listSlots();
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _isNewGameWorldPrepared = true;
        _worldLoadProgress = null;
        _view = _AppView.onboarding;
        _isReady = true;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to prepare a new campaign world: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _newGameSlot = null;
        _newGameWorldSeed = null;
        _newGameDraftState = null;
        _isNewGameWorldPrepared = false;
        _worldLoadProgress = null;
        _view = _AppView.title;
        _isReady = true;
      });
      _scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('새 세계를 구성하지 못했어요. 다시 시도해 주세요.')),
        );
    } finally {
      _isPreparingNewGame = false;
    }
  }

  void _showContinue() {
    if (_isPreparingNewGame || _isContinuingSlot) return;
    setState(() => _view = _AppView.continueGame);
  }

  void _showTitle() {
    if (_isPreparingNewGame || _isContinuingSlot) return;
    setState(() {
      _state = null;
      _lastDurablySavedMarketDay = null;
      _lastDurablySavedMarketMinute = null;
      _newGameSlot = null;
      _newGameWorldSeed = null;
      _newGameDraftState = null;
      _view = _AppView.title;
    });
  }

  Future<void> _continueSlot(int slot) async {
    if (_isPreparingNewGame || _isContinuingSlot) return;
    _isContinuingSlot = true;
    setState(() {
      _isReady = false;
      _worldLoadProgress = const WorldLoadProgress(
        0.03,
        '저장 파일과 세계 시드를 읽는 중입니다…',
      );
    });
    try {
      final state = await _persistence.loadSlot(slot, activate: false);
      if (state == null) throw StateError('Save slot $slot is empty');
      final isPrologueDraft = state.story.flagBool('prologueInProgress');
      await _prepareCampaignWorld(state, (progress) {
        if (mounted) setState(() => _worldLoadProgress = progress);
      });
      if (!isPrologueDraft) await _persistence.setActiveSlot(slot);
      final slots = await _persistence.listSlots();
      if (!mounted) return;
      setState(() {
        _state = isPrologueDraft ? null : state;
        _lastDurablySavedMarketDay = isPrologueDraft ? null : state.day;
        _lastDurablySavedMarketMinute = isPrologueDraft
            ? null
            : state.marketMinute;
        _slots = slots;
        if (!isPrologueDraft) _activeSlot = slot;
        _lastSavedAt = slots
            .where((item) => item.slot == slot)
            .firstOrNull
            ?.savedAt;
        _newGameSlot = isPrologueDraft ? slot : null;
        _newGameWorldSeed = isPrologueDraft ? state.simulationSeed : null;
        _newGameDraftState = isPrologueDraft ? state : null;
        _isNewGameWorldPrepared = isPrologueDraft;
        _worldLoadProgress = null;
        _view = isPrologueDraft ? _AppView.onboarding : _AppView.game;
        _isReady = true;
      });
      if (!isPrologueDraft) _scheduleMarketTutorialLaunch();
    } catch (error) {
      debugPrint('Failed to load slot $slot: $error');
      if (!mounted) return;
      setState(() {
        _view = _AppView.continueGame;
        _worldLoadProgress = null;
        _isReady = true;
      });
      _scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('저장을 불러오지 못했어요. 삭제하거나 다시 시도해 주세요.')),
        );
    } finally {
      _isContinuingSlot = false;
    }
  }

  Future<void> _deleteSaveSlot(int slot) async {
    if (_isPreparingNewGame || _isContinuingSlot) return;
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
    _lastDurablySavedMarketDay = state.day;
    _lastDurablySavedMarketMinute = state.marketMinute;
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

  Future<void> _savePrologueCheckpoint(
    int beat,
    bool academyPcPoweredOn,
    bool academyStockAppOpen,
    String playerName,
    String companyName,
  ) {
    final slot = _newGameSlot;
    final draft = _newGameDraftState;
    if (slot == null || draft == null) return Future<void>.value();
    final next = draft.copyWith(
      story: draft.story.copyWith(
        storyFlags: {
          ...draft.story.storyFlags,
          'prologueInProgress': true,
          'prologueComplete': false,
          'prologueBeat': beat,
          'prologueAcademyPcPoweredOn': academyPcPoweredOn,
          'prologueAcademyStockAppOpen': academyStockAppOpen,
          'prologuePlayerName': playerName,
          'prologueCompanyName': companyName,
        },
      ),
    );
    _newGameDraftState = next;
    final previous = _prologueCheckpointQueue;
    final task = () async {
      try {
        if (previous != null) await previous;
        await _persistence.saveToSlot(next, slot);
      } catch (error, stackTrace) {
        debugPrint('Failed to save prologue checkpoint: $error\n$stackTrace');
        if (mounted) {
          _scaffoldMessengerKey.currentState
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('프롤로그 진행 상황을 자동 저장하지 못했어요.')),
            );
        }
      }
    }();
    _prologueCheckpointQueue = task;
    return task;
  }

  Future<void> _createCompany(
    NewGameSetup setup,
    WorldLoadProgressCallback onProgress,
  ) async {
    onProgress(
      const WorldLoadProgress(0.18, '처음하기에서 준비한 시장과 데시멀 국가계좌를 연결하는 중입니다…'),
    );
    await Future<void>.delayed(Duration.zero);
    final slot = _newGameSlot;
    final worldSeed = _newGameWorldSeed;
    if (slot == null || worldSeed == null || !_isNewGameWorldPrepared) {
      throw StateError('The prepared new-game world is unavailable');
    }
    final story = StoryState.newDecimalPlayer(
      playerName: '성준',
      introChoice: setup.introChoice,
      startingTrait: setup.startingTrait,
      operatingPrinciple: setup.operatingPrinciple,
    );
    final state = _engine
        .createNewGame(
          setup.companyName,
          story: story,
          initialCash: initialCompanyCash,
          worldSeed: worldSeed,
        )
        .copyWith(day: 3, marketMinute: krxOpenMinute);
    onProgress(
      const WorldLoadProgress(
        0.68,
        '운용자 이름과 국가 환수 장부를 반영했습니다. 첫 저장을 만드는 중입니다…',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    try {
      final pendingCheckpoint = _prologueCheckpointQueue;
      if (pendingCheckpoint != null) await pendingCheckpoint;
      await _persistence.saveToSlot(state, slot);
      await _persistence.setActiveSlot(slot);
    } catch (error) {
      debugPrint('Failed to create company save: $error');
      _scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(_saveFailureSnackBar());
      rethrow;
    }
    if (!mounted) return;
    onProgress(
      const WorldLoadProgress(0.92, '저장을 마쳤습니다. 국가계좌 주문 화면을 확인하는 중입니다…'),
    );
    await Future<void>.delayed(Duration.zero);
    final slots = await _persistence.listSlots();
    if (!mounted) return;
    onProgress(const WorldLoadProgress(1, '준비 완료. 데시멀의 첫 주문을 시작합니다.'));
    await Future<void>.delayed(Duration.zero);
    setState(() {
      _state = state;
      _lastDurablySavedMarketDay = state.day;
      _lastDurablySavedMarketMinute = state.marketMinute;
      _slots = slots;
      _activeSlot = slot;
      _lastSavedAt = slots
          .where((item) => item.slot == slot)
          .firstOrNull
          ?.savedAt;
      _newGameSlot = null;
      _newGameWorldSeed = null;
      _newGameDraftState = null;
      _isNewGameWorldPrepared = false;
      _view = _AppView.game;
    });
    _scheduleMarketTutorialLaunch();
  }

  Future<void> _prepareCampaignWorld(
    GameState state,
    WorldLoadProgressCallback onProgress,
  ) {
    final preparer = widget.campaignWorldPreparer ?? prepareCampaignWorld;
    return preparer(state, onProgress);
  }

  void _scheduleMarketTutorialLaunch() {
    final state = _state;
    if (state == null ||
        !state.story.marketTutorialEligible ||
        state.story.marketTutorialSeen ||
        _marketTutorialLaunchScheduled) {
      return;
    }
    _marketTutorialLaunchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _marketTutorialLaunchScheduled = false;
        return;
      }
      final current = _state;
      final navigator = _navigatorKey.currentState;
      if (current == null ||
          current.story.marketTutorialSeen ||
          navigator == null) {
        _marketTutorialLaunchScheduled = false;
        return;
      }
      unawaited(
        navigator
            .push<void>(
              _gameSceneRoute<void>(
                StockMarketScreen(
                  key: const Key('academy-market-tutorial-screen'),
                  // The prologue happens on Sunday; free play and the paper
                  // market lesson begin on the first trading day, 2000-01-03.
                  state: _firstPlayableMarketState(current),
                  onSetMarketMinute: _setMarketMinute,
                  onSaveMarketNotebook: _saveMarketNotebook,
                  onSetRightsIssuePreference: _setMarketRightsIssuePreference,
                  onPurchaseReport: _purchaseDailyMarketReport,
                  onCompleteTutorial: _completeMarketTutorial,
                  onExecuteTrade: _executeTrade,
                  onCancelPendingOrder: _cancelPendingOrder,
                  onTransferCash: _transferBrokerageCash,
                  orderBookSessionCache: _stockOrderBookSessionCache,
                ),
              ),
            )
            .whenComplete(() => _marketTutorialLaunchScheduled = false),
      );
    });
  }

  Future<void> _resolveDecision(String decisionId, String optionId) async {
    final current = _state;
    if (current == null) return;
    final resolved = _engine.resolveDecision(current, decisionId, optionId);
    final next = await _processStateThroughMarketMinute(
      resolved,
      advanceGameTime(current.marketMinute, decisionActionMinutes),
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

  Future<StarShopPurchaseResult> _purchaseStarShopItem(String productId) async {
    final current = _state!;
    final result = _engine.purchaseStarShopItem(current, productId);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<GameState> _completeWork(WorkSessionResult result) async {
    final current = _state!;
    final completed = _engine.completeWorkSession(current, result);
    final next = await _processStateThroughMarketMinute(
      completed,
      advanceGameTime(current.marketMinute, workActionMinutes),
    );
    await _persistence.save(next);
    if (mounted) setState(() => _state = next);
    return next;
  }

  Future<GameState> _requestAcademyHelp(String helperId) async {
    final current = _state!;
    final helped = _engine.requestAcademyHelp(current, helperId);
    final next = await _processStateThroughMarketMinute(
      helped,
      advanceGameTime(current.marketMinute, academyHelpActionMinutes),
    );
    await _persistence.save(next);
    if (mounted) setState(() => _state = next);
    return next;
  }

  Future<RelationshipActionResult> _completeRelationshipEvening(
    String girlId,
    RelationshipActivity activity,
    String choiceId,
  ) async {
    final current = _state!;
    final result = _engine.completeRelationshipEvening(
      current,
      girlId: girlId,
      activity: activity,
      choiceId: choiceId,
    );
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<CohortInvestmentActionResult> _settleCohortInvestmentDay() async {
    final current = _state!;
    final universe = await FictionalMarketUniverse.load(
      seed: current.simulationSeed,
      throughDate: current.currentDate,
    );
    final result = _engine.settleCohortInvestmentDay(
      current,
      universe: universe,
    );
    if (!result.success || identical(result.state, current)) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<CohortInvestmentActionResult> _lendToCohortInvestor(
    String borrowerId,
    int amount,
  ) async {
    final current = _state!;
    final result = _engine.lendToCohortInvestor(
      current,
      borrowerId: borrowerId,
      amount: amount,
    );
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<CohortInvestmentActionResult>
  _acknowledgeCohortInvestmentReport() async {
    final current = _state!;
    final result = _engine.acknowledgeCohortInvestmentReport(current);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<PhoneMessengerActionResult> _markPhoneThreadRead(
    String contactId,
  ) async {
    final current = _state!;
    final result = _engine.markPhoneThreadRead(current, contactId: contactId);
    if (!result.success || identical(result.state, current)) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<PhoneMessengerActionResult> _sendPhoneMessage(
    String contactId,
    String text,
  ) async {
    final current = _state!;
    final result = _engine.sendPhoneMessage(
      current,
      contactId: contactId,
      text: text,
    );
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<RelationshipActionResult> _restDuringRelationshipEvening() async {
    final current = _state!;
    final result = _engine.restDuringRelationshipEvening(current);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<GameState> _advanceDay() => _advanceDays(1);

  Future<GameState> _advanceDays(
    int requestedDays, {
    bool stopOnImportantNews = true,
  }) async {
    final current = _state!;
    final initialFlags = Map<String, dynamic>.from(current.story.storyFlags)
      ..remove('fastForwardStopReason');
    var next = current.copyWith(
      story: current.story.copyWith(storyFlags: initialFlags),
    );
    var advanced = false;
    final universeWindow = await FictionalMarketUniverse.load(
      seed: next.simulationSeed,
      throughDate: next.currentDate.add(Duration(days: requestedDays + 7)),
    );
    for (var i = 0; i < requestedDays; i++) {
      if (next.pendingDecisions.isNotEmpty || next.campaignComplete) break;
      var before = next;
      var stopAfterClosing = false;
      String? stopReason;
      if (requestedDays > 1) {
        final events = marketNewsEventsForState(before);
        final brief = buildDailyBrief(
          before.copyWith(marketMinute: marketDayEndMinute),
        );
        before = _engine.archiveNews(
          before,
          headline: brief.title,
          eventIds: events.map((event) => event.id).toList(growable: false),
        );
        if (stopOnImportantNews) {
          final trackedAssets = <String>{
            ...before.positions.map((position) => position.assetId),
            ...((before.story.storyFlags['marketFavoriteAssetIds'] as List?) ??
                    const [])
                .whereType<String>(),
          };
          final important = events
              .where(
                (event) =>
                    event.companyId == fictionalWholeMarketCompanyId ||
                    trackedAssets.contains(event.companyId),
              )
              .where(
                (event) =>
                    event.tone == NewsTone.shock ||
                    event.tone == NewsTone.milestone ||
                    event.impactPct.abs() >= 0.08 ||
                    event.eyebrow.contains('상장폐지'),
              );
          if (important.isNotEmpty) {
            stopAfterClosing = true;
            stopReason =
                '${marketDateKey(before.currentDate)} 보유·관심 종목 중요 뉴스가 공개되어 멈췄습니다.';
          }
        }
      }
      final beforeUniverse = universeWindow.asOf(before.currentDate);
      next = _engine.advanceOneDay(
        before,
        pendingOrderQuotePaths: _pendingOrderQuotePaths(before, beforeUniverse),
      );
      if (next.day == before.day) break;
      advanced = true;
      final nextUniverse = universeWindow.asOf(next.currentDate);
      next = _engine.applyCorporateActions(
        next,
        nextUniverse.corporateActionsOn(next.currentDate),
      );
      next = next.copyWith(marketMinute: marketDayStartMinute);
      if (stopAfterClosing) {
        next = next.copyWith(
          story: next.story.copyWith(
            storyFlags: {
              ...next.story.storyFlags,
              'fastForwardStopReason': stopReason,
            },
          ),
        );
      }
      final shouldStop =
          stopAfterClosing ||
          next.pendingDecisions.isNotEmpty ||
          next.campaignComplete;
      final shouldCheckpoint =
          requestedDays == 1 ||
          (i + 1) % 7 == 0 ||
          i == requestedDays - 1 ||
          shouldStop;
      if (shouldCheckpoint) {
        await _persistence.save(next);
        _lastDurablySavedMarketDay = next.day;
        _lastDurablySavedMarketMinute = next.marketMinute;
      }
      if (mounted) {
        setState(() {
          _state = next;
          if (shouldCheckpoint) _lastSavedAt = DateTime.now();
        });
      }
      if (shouldStop) break;
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

  Future<FinanceActionResult> _persistBusinessAction(
    BusinessActionResult action,
  ) async {
    final result = FinanceActionResult(
      state: action.state,
      success: action.success,
      message: action.message,
      cashDelta: action.cashDelta,
    );
    if (!action.success) return result;
    await _persistence.save(action.state);
    if (mounted) setState(() => _state = action.state);
    return result;
  }

  Future<FinanceActionResult> _acquireBusiness({
    required String listingId,
    required String businessName,
    required String locationId,
    required BusinessPremiseMode premiseMode,
    String? linkedRealEstateId,
    required BusinessOperatingPolicy policy,
  }) {
    final action = _businessEngine.openOrAcquire(
      _state!,
      BusinessLaunchRequest(
        listingId: listingId,
        businessName: businessName,
        locationId: locationId,
        premiseMode: premiseMode,
        linkedRealEstateId: linkedRealEstateId,
        policy: policy,
      ),
    );
    return _persistBusinessAction(action);
  }

  Future<FinanceActionResult> _updateBusinessPolicy(
    String businessId,
    BusinessOperatingPolicy policy,
  ) => _persistBusinessAction(
    _businessEngine.updatePolicy(_state!, businessId, policy),
  );

  Future<FinanceActionResult> _investInBusiness(
    String businessId,
    BusinessInvestmentKind kind,
  ) =>
      _persistBusinessAction(_businessEngine.invest(_state!, businessId, kind));

  Future<FinanceActionResult> _closeBusiness(String businessId) =>
      _persistBusinessAction(_businessEngine.closeOrSell(_state!, businessId));

  Future<FinanceActionResult> _chooseBusinessEvent(
    String eventId,
    String choiceId,
  ) => _persistBusinessAction(
    _businessEngine.chooseEvent(_state!, eventId, choiceId),
  );

  Future<FinanceActionResult> _purchaseSpendingOption(String optionId) async {
    final result = _engine.purchaseSpendingOption(_state!, optionId);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _purchaseHomeImprovement(
    String improvementId,
  ) async {
    final result = _engine.purchaseHomeImprovement(_state!, improvementId);
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

  Future<FinanceActionResult> _configureRealEstateLease(
    String assetId,
    RealEstateLeaseType leaseType,
  ) async {
    final result = _engine.configureRealEstateLease(
      _state!,
      assetId,
      leaseType,
    );
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _cancelRealEstateSaleListing(
    String assetId,
  ) async {
    final result = _engine.cancelRealEstateSaleListing(_state!, assetId);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _saveRealEstateInvestmentNote(
    String assetId,
    String note,
  ) async {
    final result = _engine.saveRealEstateInvestmentNote(_state!, assetId, note);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _renovateRealEstate(String assetId) async {
    final result = _engine.renovateRealEstate(_state!, assetId);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _setRealEstateInsurance(
    String assetId,
    bool active,
  ) async {
    final result = _engine.setRealEstateInsurance(_state!, assetId, active);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _renewRealEstateMonthlyLease(
    String assetId,
  ) async {
    final result = _engine.renewRealEstateMonthlyLease(_state!, assetId);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _terminateRealEstateMonthlyLeaseEarly(
    String assetId,
  ) async {
    final result = _engine.terminateRealEstateMonthlyLeaseEarly(
      _state!,
      assetId,
    );
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _prepayRealEstateMortgage(
    String assetId,
    int amount,
  ) async {
    final result = _engine.prepayRealEstateMortgage(_state!, assetId, amount);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _refinanceRealEstateMortgage(
    String assetId, {
    required bool variableRate,
    int? termMonths,
  }) async {
    final result = _engine.refinanceRealEstateMortgage(
      _state!,
      assetId,
      variableRate: variableRate,
      termMonths: termMonths,
    );
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

  Future<FinanceActionResult> _openTimeDeposit(
    int amount,
    int termMonths,
  ) async {
    final result = _engine.openTimeDeposit(
      _state!,
      amount: amount,
      termMonths: termMonths,
    );
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _redeemTimeDeposit(String depositId) async {
    final result = _engine.redeemTimeDeposit(_state!, depositId);
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _takeUnsecuredLoan(
    int amount,
    int termMonths,
  ) async {
    final result = _engine.takeUnsecuredLoan(
      _state!,
      amount: amount,
      termMonths: termMonths,
    );
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _repayUnsecuredLoan(
    String loanId,
    int amount,
  ) async {
    final result = _engine.repayUnsecuredLoan(
      _state!,
      loanId: loanId,
      amount: amount,
    );
    if (!result.success) return result;
    await _persistence.save(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _purchaseDailyMarketReport() async {
    final result = _engine.purchaseDailyMarketReport(_state!);
    if (!result.success) return result;
    await _persistMarketState(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<void> _completeHubTutorial() async {
    final next = _engine.markHubTutorialSeen(_state!);
    await _persistence.save(next);
    if (mounted) setState(() => _state = next);
  }

  Future<GameState> _completeMarketTutorial() async {
    final next = _engine.markMarketTutorialSeen(_state!);
    await _persistMarketState(next);
    if (mounted) setState(() => _state = next);
    return next;
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

  Map<String, GamePendingOrderQuotePath> _pendingOrderQuotePaths(
    GameState state,
    FictionalMarketUniverse universe,
  ) {
    final paths = <String, GamePendingOrderQuotePath>{};
    for (final assetId
        in state.pendingOrders.map((order) => order.assetId).toSet()) {
      final cacheKey =
          '${state.simulationSeed}|${marketDateKey(state.currentDate)}|$assetId';
      final cached = _pendingQuotePathCache.remove(cacheKey);
      if (cached != null) {
        _pendingQuotePathCache[cacheKey] = cached;
        paths[assetId] = cached;
        continue;
      }
      final asset = universe.assets
          .where((candidate) => candidate.id == assetId)
          .firstOrNull;
      if (asset == null) continue;
      final quote = asset.quoteAtOrBefore(state.currentDate);
      if (quote == null) continue;
      final rawPreviousClose = asset.unadjustedReferenceCloseFor(quote.date);
      final marketReferenceClose = asset.marketReferenceCloseOn(
        DateTime.parse(quote.date),
        previousClose: rawPreviousClose,
      );
      final path = GamePendingOrderQuotePath(
        prices: quote.isExactDate
            ? generatedMarketDayPathForAsset(
                asset: asset,
                simulationSeed: state.simulationSeed,
                date: state.currentDate,
                previousClose: rawPreviousClose,
                officialClose: quote.close,
              )
            : <double>[quote.close],
        previousClose: marketReferenceClose,
        isTradingDay: quote.isExactDate,
        isIpoFirstTradingDay: asset.isIpoFirstTradingDay(state.currentDate),
        technicalLevels: marketTechnicalLevelsForAsset(
          asset: asset,
          sessionDate: state.currentDate,
          referencePrice: marketReferenceClose,
        ),
      );
      paths[assetId] = path;
      _pendingQuotePathCache[cacheKey] = path;
      while (_pendingQuotePathCache.length > 64) {
        _pendingQuotePathCache.remove(_pendingQuotePathCache.keys.first);
      }
    }
    return paths;
  }

  Future<void> _persistMarketState(GameState state) async {
    if (widget.stockTestMode) return;
    await _persistence.save(state);
  }

  Future<GameState> _setMarketMinute(int minute) async {
    final current = _state!;
    final target = minute.clamp(marketDayStartMinute, marketDayEndMinute);
    final next = await _processStateThroughMarketMinute(current, target);
    final lastSavedDay = _lastDurablySavedMarketDay;
    final lastSavedMinute = _lastDurablySavedMarketMinute;
    final explicitSync = target == current.marketMinute;
    final orderStateChanged =
        next.ledger.length != current.ledger.length ||
        next.pendingOrders.length != current.pendingOrders.length ||
        next.positions.length != current.positions.length ||
        next.brokerageCash != current.brokerageCash;
    final periodicCheckpoint =
        lastSavedDay == null ||
        lastSavedMinute == null ||
        next.day != lastSavedDay ||
        next.marketMinute - lastSavedMinute >= 30;
    final shouldPersist =
        !widget.stockTestMode &&
        (explicitSync ||
            orderStateChanged ||
            periodicCheckpoint ||
            target >= krxCloseMinute);
    if (shouldPersist) {
      await _persistence.save(next);
      _lastDurablySavedMarketDay = next.day;
      _lastDurablySavedMarketMinute = next.marketMinute;
      _lastSavedAt = DateTime.now();
    }
    if (mounted) {
      if (shouldPersist) {
        setState(() => _state = next);
      } else {
        _state = next;
      }
    }
    return next;
  }

  Future<GameState> _processStateThroughMarketMinute(
    GameState current,
    int targetMinute,
  ) async {
    final target = targetMinute.clamp(marketDayStartMinute, marketDayEndMinute);
    if (target > current.marketMinute && current.pendingOrders.isNotEmpty) {
      final universe = await FictionalMarketUniverse.load(
        seed: current.simulationSeed,
        throughDate: current.currentDate,
      );
      return _engine.processPendingOrdersThroughMarketMinute(
        current,
        targetMinute: target,
        quotePaths: _pendingOrderQuotePaths(current, universe),
      );
    }
    return current.copyWith(marketMinute: target);
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
    await _persistMarketState(next);
    if (mounted) setState(() => _state = next);
    return next;
  }

  Future<GameState> _setMarketRightsIssuePreference(bool subscribe) async {
    final current = _state!;
    final next = current.copyWith(
      story: current.story.copyWith(
        storyFlags: <String, dynamic>{
          ...current.story.storyFlags,
          marketRightsIssuePreferenceFlag: subscribe
              ? marketRightsIssueSubscribePreference
              : marketRightsIssueAutoSellPreference,
        },
      ),
    );
    await _persistMarketState(next);
    if (mounted) {
      setState(() => _state = next);
    }
    return next;
  }

  Future<TradeExecutionResult> _executeTrade(TradeOrder order) async {
    final current = _state!;
    MarketTradeQuote? quote;
    try {
      quote = resolveMarketTradeQuote(
        await FictionalMarketUniverse.load(
          seed: current.simulationSeed,
          throughDate: current.currentDate,
        ),
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
    final maximumPositionUnits = asset?.sharesOutstandingAtOrBefore(
      current.currentDate,
    );
    if (quote == null ||
        asset == null ||
        order.symbol != asset.code ||
        order.name != asset.name ||
        order.market != asset.market ||
        order.currency != asset.currency ||
        order.quoteDate != quote.quoteDate ||
        order.marketMinute != quote.marketMinute ||
        order.unitPrice != quote.unitPrice ||
        order.isTradingDay != quote.isTradingDay ||
        order.maximumPositionUnits != maximumPositionUnits ||
        order.isIpoFirstTradingDay !=
            asset.isIpoFirstTradingDay(current.currentDate)) {
      return TradeExecutionResult(
        state: current,
        success: false,
        message: '기준 시세가 바뀌었어요. 주문창을 다시 확인해 주세요.',
      );
    }
    final result = _engine.executeTrade(current, order);
    if (!result.success) return result;
    await _persistMarketState(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _cancelPendingOrder(String orderId) async {
    final result = _engine.cancelPendingOrder(_state!, orderId);
    if (!result.success) return result;
    await _persistMarketState(result.state);
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
    await _persistMarketState(result.state);
    if (mounted) setState(() => _state = result.state);
    return result;
  }

  Widget _buildStockTestHome() {
    return _GameFrame(
      child: StockMarketScreen(
        key: const Key('stock-test-market-screen'),
        state: _state!,
        onSetMarketMinute: _setMarketMinute,
        onSaveMarketNotebook: _saveMarketNotebook,
        onSetRightsIssuePreference: _setMarketRightsIssuePreference,
        onPurchaseReport: _purchaseDailyMarketReport,
        onExecuteTrade: _executeTrade,
        onCancelPendingOrder: _cancelPendingOrder,
        onTransferCash: _transferBrokerageCash,
        orderBookSessionCache: _stockOrderBookSessionCache,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: '10대부터 건물주',
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
      home: widget.stockTestMode && _state != null
          ? _buildStockTestHome()
          : !_isReady
          ? _GameFrame(
              child: _LoadingScreen(
                progress: _worldLoadProgress,
                creatingWorld: _isPreparingNewGame,
              ),
            )
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
                  onCreate: _startNewGameInSlot,
                  onBack: _showTitle,
                ),
                _AppView.onboarding => VisualNovelOnboardingScreen(
                  onCreate: _createCompany,
                  onExit: _showTitle,
                  onCheckpoint: _savePrologueCheckpoint,
                  initialBeat:
                      _newGameDraftState?.story.flagInt('prologueBeat') ?? 0,
                  initialAcademyPcPoweredOn:
                      _newGameDraftState?.story.flagBool(
                        'prologueAcademyPcPoweredOn',
                      ) ??
                      false,
                  initialAcademyStockAppOpen:
                      _newGameDraftState?.story.flagBool(
                        'prologueAcademyStockAppOpen',
                      ) ??
                      false,
                  initialPlayerName:
                      _newGameDraftState?.story.storyFlags['prologuePlayerName']
                          as String? ??
                      '',
                  initialCompanyName:
                      _newGameDraftState
                              ?.story
                              .storyFlags['prologueCompanyName']
                          as String? ??
                      '',
                  allowRuntimeDialoguePreview: widget.dialoguePreviewMode,
                  dialogueOverrideJson: widget.dialogueOverrideJson,
                ),
                _AppView.game when _state != null => OfficeScreen(
                  state: _state!,
                  stateReader: () => _state!,
                  engine: _engine,
                  stockOrderBookSessionCache: _stockOrderBookSessionCache,
                  activeSaveSlot: _activeSlot,
                  lastSavedAt: _lastSavedAt,
                  onManualSave: _manualSave,
                  onReturnToTitle: _returnToTitle,
                  onAdvanceDay: _advanceDay,
                  onAdvanceDays: _advanceDays,
                  onAdvanceDaysQuiet: (days) =>
                      _advanceDays(days, stopOnImportantNews: false),
                  onSetMarketMinute: _setMarketMinute,
                  onSaveMarketNotebook: _saveMarketNotebook,
                  onSetMarketRightsIssuePreference:
                      _setMarketRightsIssuePreference,
                  onResolveDecision: _resolveDecision,
                  onClaimMission: _claimMission,
                  onPurchaseStarShopItem: _purchaseStarShopItem,
                  onRequestAcademyHelp: _requestAcademyHelp,
                  onCompleteRelationshipEvening: _completeRelationshipEvening,
                  onRestDuringRelationshipEvening:
                      _restDuringRelationshipEvening,
                  onSettleCohortInvestmentDay: _settleCohortInvestmentDay,
                  onLendToCohortInvestor: _lendToCohortInvestor,
                  onAcknowledgeCohortInvestmentReport:
                      _acknowledgeCohortInvestmentReport,
                  onMarkPhoneThreadRead: _markPhoneThreadRead,
                  onSendPhoneMessage: _sendPhoneMessage,
                  onHireEmployee: _hireEmployee,
                  onLaunchFund: _launchFund,
                  onPurchaseSpendingOption: _purchaseSpendingOption,
                  onPurchaseHomeImprovement: _purchaseHomeImprovement,
                  onAcquireBusiness: _acquireBusiness,
                  onUpdateBusinessPolicy: _updateBusinessPolicy,
                  onInvestInBusiness: _investInBusiness,
                  onCloseBusiness: _closeBusiness,
                  onChooseBusinessEvent: _chooseBusinessEvent,
                  onSellRealEstate: _sellRealEstate,
                  onConfigureRealEstateLease: _configureRealEstateLease,
                  onCancelRealEstateSaleListing: _cancelRealEstateSaleListing,
                  onSaveRealEstateInvestmentNote: _saveRealEstateInvestmentNote,
                  onRenovateRealEstate: _renovateRealEstate,
                  onSetRealEstateInsurance: _setRealEstateInsurance,
                  onRenewRealEstateMonthlyLease: _renewRealEstateMonthlyLease,
                  onTerminateRealEstateMonthlyLeaseEarly:
                      _terminateRealEstateMonthlyLeaseEarly,
                  onPrepayRealEstateMortgage: _prepayRealEstateMortgage,
                  onRefinanceRealEstateMortgage: _refinanceRealEstateMortgage,
                  onPlayChanceGame: _playAdultChanceGame,
                  onOpenTimeDeposit: _openTimeDeposit,
                  onRedeemTimeDeposit: _redeemTimeDeposit,
                  onTakeUnsecuredLoan: _takeUnsecuredLoan,
                  onRepayUnsecuredLoan: _repayUnsecuredLoan,
                  onPurchaseMarketReport: _purchaseDailyMarketReport,
                  onCompleteHubTutorial: _completeHubTutorial,
                  onCompleteMarketTutorial: _completeMarketTutorial,
                  onArchiveNews: _archiveNews,
                  onCompleteWork: _completeWork,
                  onExecuteTrade: _executeTrade,
                  onCancelPendingOrder: _cancelPendingOrder,
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
  const _LoadingScreen({this.progress, this.creatingWorld = false});

  final WorldLoadProgress? progress;
  final bool creatingWorld;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('campaign-loading-screen'),
    backgroundColor: _sky,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.public_rounded,
              size: 56,
              color: Color(0xFF536A96),
            ),
            const SizedBox(height: 18),
            Text(
              progress == null
                  ? '게임 정보를 확인하고 있어요'
                  : creatingWorld
                  ? '새 캠페인 세계를 구성하고 있어요'
                  : '캠페인 세계를 불러오고 있어요',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              progress?.label ?? '저장 슬롯을 확인하는 중입니다…',
              key: const Key('campaign-loading-status'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF66728A),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 280,
              child: LinearProgressIndicator(
                key: const Key('campaign-loading-progress'),
                value: progress?.fraction,
                minHeight: 9,
                color: _coral,
                backgroundColor: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              Text(
                '${(progress!.fraction * 100).round()}%',
                key: const Key('campaign-loading-percent'),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '저장된 시드에서 같은 세계를 재구성합니다.\n'
                '기기에 따라 약 1분 걸릴 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF66728A),
                  fontSize: 11,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
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
    required this.operatingPrinciple,
  });

  final String playerName;
  final String companyName;
  final String introChoice;
  final StoryTrait startingTrait;
  final OperatingPrinciple operatingPrinciple;
}

class _AdvanceMenuChoice {
  const _AdvanceMenuChoice({
    required this.days,
    this.stopOnImportantNews = true,
  });

  final int days;
  final bool stopOnImportantNews;
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
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
  FictionalMarketAsset asset,
  GameState state,
) {
  final quote = asset.quoteAtOrBefore(state.currentDate);
  if (quote == null) return null;
  if (!quote.isExactDate) return quote.close;
  final previousClose = asset.unadjustedReferenceCloseFor(quote.date);
  final path = generatedMarketDayPathForAsset(
    asset: asset,
    simulationSeed: state.simulationSeed,
    date: state.currentDate,
    previousClose: previousClose,
    officialClose: quote.close,
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
