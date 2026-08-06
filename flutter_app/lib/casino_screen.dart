part of 'main.dart';

const _casinoGold = Color(0xFFD8AE62);
const _casinoWine = Color(0xFF6A192B);
const _casinoGreen = Color(0xFF0D4938);
const _casinoInk = Color(0xFF170F0D);
const _casinoGameDialogueHeight = 112.0;
const _casinoGameDialogueBottomInset = 0.0;

enum _CasinoEntryPhase { welcome, exchange, handover, lobby }

enum _CasinoExitChoice { keepChips, cashOut }

enum _CasinoNoChipChoice { exchange, offline }

class CasinoScreen extends StatefulWidget {
  const CasinoScreen({
    super.key,
    required this.state,
    required this.onExchangeChips,
    required this.onCashOutChips,
    required this.onPlayRound,
    required this.onStartBlackjack,
    required this.onBlackjackAction,
    required this.onCrapsRoll,
    this.testMode = false,
    this.onGoOffline,
  });

  final GameState state;
  final Future<CasinoActionResult> Function(int amount) onExchangeChips;
  final Future<CasinoActionResult> Function() onCashOutChips;
  final Future<CasinoActionResult> Function(CasinoBet bet) onPlayRound;
  final Future<CasinoActionResult> Function(int stake) onStartBlackjack;
  final Future<CasinoActionResult> Function(BlackjackAction action)
  onBlackjackAction;
  final Future<CasinoActionResult> Function() onCrapsRoll;
  final bool testMode;
  final VoidCallback? onGoOffline;

  @override
  State<CasinoScreen> createState() => _CasinoScreenState();
}

class _CasinoScreenState extends State<CasinoScreen> {
  late GameState _state = widget.state;
  CasinoGameType? _selectedGame;
  CasinoBetType _selectedBet = CasinoBetType.baccaratPlayer;
  int _selection = 0;
  int _stake = 0;
  int _exchangeAmount = casinoMinimumStake;
  bool _busy = false;
  bool _showingNoChipsPrompt = false;
  late _CasinoEntryPhase _entryPhase;
  int _welcomeDialogueStep = 0;
  final ScrollController _scrollController = ScrollController();
  _CasinoTableMotion _tableMotion = _CasinoTableMotion.idle;
  int _tableMotionToken = 0;
  String? _dealerReaction;

  CasinoState get _casino => _state.personalFinance.casino;

  int get _availableChips => _casino.chipBalance;

  int get _totalCasinoBankroll =>
      _state.availableBrokerageCash + _availableChips;

  bool get _showsWelcomeStage =>
      _selectedGame == null && _entryPhase == _CasinoEntryPhase.welcome;

  @override
  void initState() {
    super.initState();
    final activeBlackjack = _casino.activeBlackjack != null;
    final activeCraps = _casino.activeCraps != null;
    _entryPhase = activeBlackjack || activeCraps
        ? _CasinoEntryPhase.lobby
        : _CasinoEntryPhase.welcome;
    if (activeBlackjack) {
      _selectedGame = CasinoGameType.blackjack;
    } else if (activeCraps) {
      _selectedGame = CasinoGameType.craps;
    }
    final exchangeable =
        (_state.availableBrokerageCash ~/ casinoMinimumStake) *
        casinoMinimumStake;
    _exchangeAmount = math.min(100000, exchangeable);
    if (_exchangeAmount < casinoMinimumStake && exchangeable > 0) {
      _exchangeAmount = exchangeable;
    }
    _stake = _firstPlayableStake();
  }

  String get _backgroundAsset => switch (_selectedGame) {
    CasinoGameType.baccarat =>
      'assets/images/casino/bg_decimal_casino_baccarat_2010_v1.png',
    CasinoGameType.roulette =>
      'assets/images/casino/bg_decimal_casino_roulette_2010_v1.png',
    CasinoGameType.blackjack || CasinoGameType.craps || CasinoGameType.sicBo =>
      'assets/images/casino/bg_decimal_casino_table_games_2010_v1.png',
    CasinoGameType.slots =>
      'assets/images/casino/bg_decimal_casino_lobby_2010_v1.png',
    null => switch (_entryPhase) {
      _CasinoEntryPhase.welcome =>
        'assets/images/casino/dealer_entry_welcome_age20_v1.png',
      _CasinoEntryPhase.exchange =>
        'assets/images/casino/dealer_chip_exchange_age20_v1.png',
      _CasinoEntryPhase.handover =>
        'assets/images/casino/dealer_chip_handover_age20_v2.png',
      _CasinoEntryPhase.lobby =>
        'assets/images/casino/bg_decimal_casino_lobby_2010_v1.png',
    },
  };

  int get _monthBasis => _casino.monthKey == casinoMonthKey(_state.currentDate)
      ? _casino.monthBankrollBasis
      : _totalCasinoBankroll;

  int get _lossLimit => widget.testMode
      ? casinoTestBankroll
      : casinoMonthlyLossLimitForBasis(_monthBasis);
  int get _maxStake => casinoMaximumStakeForChips(_availableChips);

  bool _stakeIsPlayable(int stake) =>
      isValidCasinoChipStake(stake, _availableChips) &&
      _casino.monthlyLoss + stake <= _lossLimit;

  int _firstPlayableStake() => casinoStakePercents
      .map((percent) => casinoStakeForChipPercent(_availableChips, percent))
      .firstWhere(_stakeIsPlayable, orElse: () => 0);

  bool get _nationalNetworkUnlocked =>
      widget.testMode || _state.story.nationalNetworkBriefingSeen;

  bool get _roundTimeAvailable =>
      _state.currentDate.weekday < DateTime.saturday &&
      _state.marketMinute >= krxCloseMinute &&
      _state.marketMinute <= marketDayEndMinute - casinoRoundMinutes &&
      !weekdayEveningUsed(_state);

  bool get _canStartRound =>
      _nationalNetworkUnlocked &&
      _roundTimeAvailable &&
      _state.pendingDecisions.isEmpty &&
      _casino.activeBlackjack == null &&
      _casino.activeCraps == null &&
      _casino.roundsForDay(_state.day) < casinoDailyRoundLimit &&
      _stakeIsPlayable(_stake);

  bool get _isOutOfChips =>
      _casino.activeBlackjack == null &&
      _casino.activeCraps == null &&
      _maxStake < casinoMinimumStake;

  bool get _canGoOffline =>
      !_busy && _casino.activeBlackjack == null && _casino.activeCraps == null;

  void _resetScrollAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _selectGame(CasinoGameType game) {
    GameAudio.instance.playSfx(GameSfx.select);
    setState(() {
      _selectedGame = game;
      _selectedBet = switch (game) {
        CasinoGameType.baccarat => CasinoBetType.baccaratPlayer,
        CasinoGameType.blackjack => CasinoBetType.blackjackHand,
        CasinoGameType.roulette => CasinoBetType.rouletteRed,
        CasinoGameType.craps => CasinoBetType.crapsPassLine,
        CasinoGameType.sicBo => CasinoBetType.sicBoBig,
        CasinoGameType.slots => CasinoBetType.slotsSpin,
      };
      _selection = switch (game) {
        CasinoGameType.roulette => 0,
        CasinoGameType.sicBo => 10,
        _ => 0,
      };
      _dealerReaction = null;
    });
    _resetScrollAfterBuild();
  }

  bool get _canEnterChipDesk =>
      _nationalNetworkUnlocked &&
      _roundTimeAvailable &&
      _state.pendingDecisions.isEmpty &&
      _casino.roundsForDay(_state.day) < casinoDailyRoundLimit &&
      (_casino.chipBalance >= casinoMinimumStake ||
          _state.availableBrokerageCash >= casinoMinimumStake);

  bool get _canOpenTables =>
      _canEnterChipDesk && _maxStake >= casinoMinimumStake;

  bool get _canExchangeChips =>
      _canEnterChipDesk && _maximumExchangeAmount >= casinoMinimumStake;

  int get _maximumExchangeAmount =>
      (_state.availableBrokerageCash ~/ casinoMinimumStake) *
      casinoMinimumStake;

  void _openChipDesk() {
    if (!_canExchangeChips) {
      GameAudio.instance.playSfx(GameSfx.error);
      return;
    }
    GameAudio.instance.playSfx(GameSfx.doorOpen);
    setState(() => _entryPhase = _CasinoEntryPhase.exchange);
    _resetScrollAfterBuild();
  }

  Future<void> _showOutOfChipsPrompt() async {
    if (_busy || _showingNoChipsPrompt || !_isOutOfChips) return;
    _showingNoChipsPrompt = true;
    GameAudio.instance.playSfx(GameSfx.error);
    var dialogueStep = 0;
    final canExchange = _canExchangeChips;
    final choice = await showModalBottomSheet<_CasinoNoChipChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xD9000000),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Container(
          key: const Key('casino-out-of-chips-sheet'),
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF170F0D),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _casinoGold.withValues(alpha: 0.75)),
            boxShadow: const [
              BoxShadow(
                color: Color(0xCC000000),
                blurRadius: 28,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 9),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF69594F),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 4),
              _NovelDialogue(
                key: ValueKey<int>(dialogueStep),
                speaker: '이안',
                line: dialogueStep == 0
                    ? '칩이 떨어졌네.'
                    : canExchange
                    ? '더 할 거면 칩 사러 가자. 오늘은 여기까지면 접속을 끝내면 돼.'
                    : '칩으로 바꿀 국가계좌 돈도 부족해. 오늘은 여기까지 접속을 끝내는 게 좋겠어.',
                charactersPerSecond: 48,
                continueKey: const Key('casino-no-chips-dialogue-next'),
                onContinue: dialogueStep == 0
                    ? () => setSheetState(() => dialogueStep = 1)
                    : null,
                child: dialogueStep == 0
                    ? null
                    : SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                key: const Key('casino-no-chips-exchange'),
                                onPressed: canExchange
                                    ? () => Navigator.of(
                                        sheetContext,
                                      ).pop(_CasinoNoChipChoice.exchange)
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _casinoWine,
                                  disabledBackgroundColor: const Color(
                                    0xFF49383A,
                                  ),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.currency_exchange_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  '칩 사러 가기',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const Key('casino-no-chips-offline'),
                                onPressed: () => Navigator.of(
                                  sheetContext,
                                ).pop(_CasinoNoChipChoice.offline),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _casinoGold,
                                  side: const BorderSide(color: _casinoGold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  '접속 종료',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
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
        ),
      ),
    );
    _showingNoChipsPrompt = false;
    if (!mounted || choice == null) return;
    if (choice == _CasinoNoChipChoice.exchange) {
      GameAudio.instance.playSfx(GameSfx.doorOpen);
      setState(() {
        _selectedGame = null;
        _entryPhase = _CasinoEntryPhase.exchange;
        _dealerReaction = null;
      });
      _resetScrollAfterBuild();
      return;
    }
    GameAudio.instance.playSfx(GameSfx.doorClose);
    if (widget.onGoOffline != null) {
      widget.onGoOffline!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _openTableLobby() {
    if (!_canOpenTables) {
      GameAudio.instance.playSfx(GameSfx.error);
      return;
    }
    GameAudio.instance.playSfx(GameSfx.doorOpen);
    setState(() => _entryPhase = _CasinoEntryPhase.lobby);
    _resetScrollAfterBuild();
  }

  void _setExchangeAmount(int amount) {
    final maximum = _maximumExchangeAmount;
    if (maximum < casinoMinimumStake) return;
    setState(() {
      _exchangeAmount = amount.clamp(casinoMinimumStake, maximum).toInt();
      _exchangeAmount =
          (_exchangeAmount ~/ casinoMinimumStake) * casinoMinimumStake;
    });
  }

  Future<void> _confirmChipExchange() async {
    if (_busy || _exchangeAmount < casinoMinimumStake) return;
    setState(() {
      _busy = true;
    });
    try {
      final result = await widget.onExchangeChips(_exchangeAmount);
      if (!mounted) return;
      setState(() {
        if (result.success) {
          _state = result.state;
          _stake = _firstPlayableStake();
          _entryPhase = _CasinoEntryPhase.handover;
          GameAudio.instance.playSfx(GameSfx.chipsHandle);
        } else {
          GameAudio.instance.playSfx(GameSfx.error);
        }
      });
      if (result.success) _resetScrollAfterBuild();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _acceptChips() {
    GameAudio.instance.playSfx(GameSfx.chipsCollide);
    setState(() {
      _entryPhase = _CasinoEntryPhase.lobby;
    });
    _resetScrollAfterBuild();
  }

  Future<void> _exitCasino() async {
    if (_busy) return;
    if (_casino.activeBlackjack != null || _casino.activeCraps != null) {
      setState(() {
        final blackjack = _casino.activeBlackjack != null;
        _entryPhase = _CasinoEntryPhase.lobby;
        _selectedGame = blackjack
            ? CasinoGameType.blackjack
            : CasinoGameType.craps;
        _dealerReaction = blackjack
            ? '진행 중인 블랙잭 핸드를 먼저 정산해야 나갈 수 있어.'
            : '포인트가 잡힌 크랩스 라운드를 먼저 정산해야 나갈 수 있어.';
      });
      return;
    }
    if (_casino.chipBalance <= 0) {
      if (mounted) _goOfflineToLivingQuarters();
      return;
    }
    final choice = await _showExitChoices();
    if (!mounted || choice == null) return;
    if (choice == _CasinoExitChoice.keepChips) {
      GameAudio.instance.playSfx(GameSfx.chipsHandle);
      _goOfflineToLivingQuarters();
      return;
    }
    if (choice == _CasinoExitChoice.cashOut) {
      setState(() {
        _busy = true;
      });
      try {
        final result = await widget.onCashOutChips();
        if (!mounted) return;
        if (!result.success) {
          GameAudio.instance.playSfx(GameSfx.error);
          return;
        }
        _state = result.state;
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    if (mounted) _goOfflineToLivingQuarters();
  }

  void _goOfflineToLivingQuarters() {
    final onGoOffline = widget.onGoOffline;
    if (onGoOffline != null) {
      onGoOffline();
      return;
    }
    Navigator.of(context).pop();
  }

  Future<_CasinoExitChoice?> _showExitChoices() =>
      showModalBottomSheet<_CasinoExitChoice>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF201816),
        builder: (sheetContext) => SafeArea(
          child: Container(
            key: const Key('casino-exit-sheet'),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '칩을 어떻게 할까?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('casino-exit-cancel'),
                      tooltip: '계속 게임하기',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded, color: _casinoGold),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '현재 보유 칩 ${_money(_casino.chipBalance)}원',
                  style: const TextStyle(
                    color: _casinoGold,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  '칩을 보관하면 다음 카지노 접속 때 같은 잔액으로 바로 온라인 테이블에 갈 수 있어.',
                  style: TextStyle(
                    color: Color(0xFFD2C6BE),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    key: const Key('casino-exit-cash-out'),
                    onPressed: () => Navigator.of(
                      sheetContext,
                    ).pop(_CasinoExitChoice.cashOut),
                    style: FilledButton.styleFrom(
                      backgroundColor: _casinoGold,
                      foregroundColor: const Color(0xFF1B120E),
                    ),
                    icon: const Icon(Icons.currency_exchange_rounded),
                    label: Text(
                      '국가계좌 ${_money(_casino.chipBalance)}원으로 환전',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    key: const Key('casino-exit-keep-chips'),
                    onPressed: () => Navigator.of(
                      sheetContext,
                    ).pop(_CasinoExitChoice.keepChips),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: _casinoGold),
                    ),
                    icon: const Icon(Icons.savings_rounded),
                    label: const Text(
                      '칩 보관하고 나가기',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  void _handleBack() {
    if (_casino.activeBlackjack != null || _casino.activeCraps != null) {
      unawaited(_exitCasino());
    } else if (_selectedGame != null) {
      setState(() => _selectedGame = null);
      _resetScrollAfterBuild();
    } else if (_entryPhase == _CasinoEntryPhase.handover) {
      setState(() => _entryPhase = _CasinoEntryPhase.exchange);
    } else if (_entryPhase == _CasinoEntryPhase.exchange) {
      setState(() {
        _entryPhase = _CasinoEntryPhase.welcome;
        _welcomeDialogueStep = 0;
      });
      _resetScrollAfterBuild();
    } else {
      unawaited(_exitCasino());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _apply(
    Future<CasinoActionResult> future, {
    _CasinoTableMotion motion = _CasinoTableMotion.reveal,
  }) async {
    if (_busy) return;
    final historyLengthBefore = _casino.history.length;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final startingBlackjack =
        motion == _CasinoTableMotion.deal &&
        _selectedGame == CasinoGameType.blackjack &&
        _casino.activeBlackjack == null;
    if (startingBlackjack) {
      GameAudio.instance.playSfx(GameSfx.chipLay);
    }
    GameAudio.instance.playSfx(switch (motion) {
      _CasinoTableMotion.deal =>
        startingBlackjack ? GameSfx.cardShuffle : GameSfx.cardSlide,
      _CasinoTableMotion.reveal => GameSfx.cardPlace,
      _CasinoTableMotion.wheel => GameSfx.tick,
      _CasinoTableMotion.crapsDice ||
      _CasinoTableMotion.dice => GameSfx.diceShake,
      _CasinoTableMotion.reels => GameSfx.metalLatch,
      _CasinoTableMotion.idle => GameSfx.select,
    });
    setState(() {
      _busy = true;
      _tableMotion = motion;
      _tableMotionToken++;
    });
    unawaited(HapticFeedback.mediumImpact());
    try {
      final result = await future;
      if (!mounted) return;
      if (result.success && !reduceMotion) {
        await Future<void>.delayed(_casinoTableMotionDuration(motion));
        if (!mounted) return;
      }
      if (result.success) {
        GameAudio.instance.playSfx(switch (motion) {
          _CasinoTableMotion.deal ||
          _CasinoTableMotion.reveal => GameSfx.cardPlace,
          _CasinoTableMotion.wheel => GameSfx.notification,
          _CasinoTableMotion.crapsDice ||
          _CasinoTableMotion.dice => GameSfx.diceThrow,
          _CasinoTableMotion.reels => GameSfx.coins,
          _CasinoTableMotion.idle => GameSfx.confirm,
        });
        _playCasinoResultAlert(result);
      } else {
        GameAudio.instance.playSfx(GameSfx.error);
      }
      setState(() {
        if (result.success) {
          _state = result.state;
          final history = _casino.history;
          _dealerReaction = history.length > historyLengthBefore
              ? _dealerReactionForResult(history.last, history)
              : null;
        } else {
          _dealerReaction = '베팅 내용 다시 한번 확인해 줘.';
        }
        _tableMotion = _CasinoTableMotion.idle;
        if (!_stakeIsPlayable(_stake)) {
          _stake = _firstPlayableStake();
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _playCasinoResultAlert(CasinoActionResult result) {
    final casinoAfter = result.state.personalFinance.casino;
    if (casinoAfter.activeBlackjack != null ||
        casinoAfter.activeCraps != null) {
      return;
    }
    final chipDelta = casinoAfter.chipBalance - _casino.chipBalance;
    GameAudio.instance.playSfx(GameSfx.notification, volumeScale: 0.9);
    GameAudio.instance.playSfx(
      chipDelta > 0
          ? GameSfx.coinsLarge
          : chipDelta < 0
          ? GameSfx.impactSoft
          : GameSfx.confirm,
    );
  }

  Future<void> _playSelected() async {
    final game = _selectedGame;
    if (game == null || game == CasinoGameType.blackjack) return;
    if (_isOutOfChips) {
      await _showOutOfChipsPrompt();
      return;
    }
    if (game == CasinoGameType.craps && _casino.activeCraps != null) {
      await _apply(widget.onCrapsRoll(), motion: _CasinoTableMotion.crapsDice);
      return;
    }
    GameAudio.instance.playSfx(GameSfx.chipLay);
    await _apply(
      widget.onPlayRound(
        CasinoBet(
          game: game,
          type: _selectedBet,
          stake: _stake,
          selection:
              _selectedBet == CasinoBetType.rouletteStraight ||
                  _selectedBet == CasinoBetType.sicBoSpecificTriple ||
                  _selectedBet == CasinoBetType.sicBoTotal
              ? _selection
              : null,
        ),
      ),
      motion: switch (game) {
        CasinoGameType.baccarat => _CasinoTableMotion.deal,
        CasinoGameType.roulette => _CasinoTableMotion.wheel,
        CasinoGameType.craps => _CasinoTableMotion.crapsDice,
        CasinoGameType.sicBo => _CasinoTableMotion.dice,
        CasinoGameType.slots => _CasinoTableMotion.reels,
        CasinoGameType.blackjack => _CasinoTableMotion.deal,
      },
    );
  }

  CasinoRoundRecord? _latestRecordFor(CasinoGameType game) {
    for (final record in _casino.history.reversed) {
      if (record.game == game) return record;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop:
        !_busy &&
        _casino.activeBlackjack == null &&
        _casino.activeCraps == null &&
        _casino.chipBalance == 0,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && mounted) {
        unawaited(_exitCasino());
      }
    },
    child: Scaffold(
      key: const Key('casino-screen'),
      backgroundColor: _casinoInk,
      body: GestureDetector(
        key: const Key('casino-welcome-fullscreen-continue'),
        behavior: HitTestBehavior.opaque,
        onTap: _showsWelcomeStage && _welcomeDialogueStep == 0
            ? () => _activeNovelDialogueState?._handleExternalTap()
            : null,
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: ClipRect(
                  key: ValueKey(
                    '$_backgroundAsset-${_showsWelcomeStage ? 'focused' : 'base'}',
                  ),
                  child: Transform.scale(
                    key: const Key('casino-background-transform'),
                    scale: _showsWelcomeStage ? 1.16 : 1,
                    alignment: const Alignment(0, -0.62),
                    child: Image.asset(
                      _backgroundAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _showsWelcomeStage
                        ? const [
                            Color(0x10000000),
                            Color(0x24000000),
                            Color(0xD8120C0B),
                          ]
                        : const [
                            Color(0x18000000),
                            Color(0x66000000),
                            Color(0xFA120C0B),
                          ],
                    stops: _showsWelcomeStage
                        ? const [0, 0.58, 1]
                        : const [0, 0.28, 0.66],
                  ),
                ),
              ),
              if (_showsWelcomeStage)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _storyDialogueBottomInset,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _buildWelcome(),
                  ),
                )
              else
                Positioned(
                  left: 0,
                  right: 0,
                  top: _selectedGame == null ? 82 : 44,
                  bottom: _selectedGame == null
                      ? 0
                      : _casinoGameDialogueHeight +
                            _casinoGameDialogueBottomInset,
                  child: SingleChildScrollView(
                    key: const Key('casino-scroll'),
                    controller: _scrollController,
                    padding: _selectedGame == null
                        ? const EdgeInsets.fromLTRB(12, 12, 12, 28)
                        : const EdgeInsets.fromLTRB(5, 2, 5, 24),
                    child: _buildCurrentBody(),
                  ),
                ),
              if (_selectedGame != null)
                Positioned(
                  key: const Key('casino-game-dialogue-overlay'),
                  left: 0,
                  right: 0,
                  bottom: _casinoGameDialogueBottomInset,
                  child: IgnorePointer(
                    child: _buildDealerDialogue(
                      _dealerLiveDialogue(_selectedGame!),
                    ),
                  ),
                ),
              if (_selectedGame != null)
                Positioned(
                  left: 5,
                  right: 5,
                  top: 0,
                  child: ColoredBox(
                    color: _casinoInk,
                    child: _buildGameTitleBar(_selectedGame!),
                  ),
                ),
              if (_selectedGame == null)
                Positioned(left: 8, right: 8, top: 6, child: _buildHeader()),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildCurrentBody() {
    if (_selectedGame != null) return _buildGame();
    return switch (_entryPhase) {
      _CasinoEntryPhase.welcome => _buildWelcome(),
      _CasinoEntryPhase.exchange => _buildChipExchange(),
      _CasinoEntryPhase.handover => _buildChipHandover(),
      _CasinoEntryPhase.lobby => _buildLobby(),
    };
  }

  Widget _buildDealerDialogue(String line) => _NovelDialogue(
    key: ValueKey<String>('casino-dealer-$line'),
    speaker: '이안',
    line: line,
    charactersPerSecond: 80,
    compact: true,
  );

  String _dealerLiveDialogue(CasinoGameType game) {
    if (!_busy) return _dealerReaction ?? _dealerTableDialogue(game);
    return switch (_tableMotion) {
      _CasinoTableMotion.deal => '카드를 나눠 줄게. 잠깐만 기다려.',
      _CasinoTableMotion.reveal => '마지막 패 확인하고 있어. 곧 결과 나와.',
      _CasinoTableMotion.wheel => '휠이 돌고 있어. 공이 어디에 멈출지 같이 보자.',
      _CasinoTableMotion.crapsDice => '주사위가 구르고 있어. 포인트 확인할게.',
      _CasinoTableMotion.dice => '세 주사위가 멈추고 있어. 합을 확인해 줄게.',
      _CasinoTableMotion.reels => '릴이 돌아가고 있어. 같은 심벌이 모이는지 보자.',
      _CasinoTableMotion.idle => _dealerReaction ?? _dealerTableDialogue(game),
    };
  }

  String _dealerReactionForResult(
    CasinoRoundRecord record,
    List<CasinoRoundRecord> history,
  ) {
    final won = record.net > 0;
    final pushed = record.net == 0;
    final previousWasLoss =
        history.length > 1 && history[history.length - 2].net < 0;
    final winStreak = _trailingResultCount(history, (item) => item.net > 0);
    final lossStreak = _trailingResultCount(history, (item) => item.net < 0);

    if (won && previousWasLoss) {
      return _pickDealerResultLine(record, history, const <String>[
        '오빠, 바로 되찾았네. 침착하게 흐름 바꾼 거 좋았어.',
        '오빠, 방금 판으로 분위기가 다시 넘어왔어. 축하해.',
        '오빠, 흔들리지 않고 다음 판 잡았네. 멋진 반전이야.',
        '오빠, 손실 뒤에 바로 적중했어. 이번 판단 정확했어.',
      ]);
    }
    if (won && winStreak >= 3) {
      return _pickDealerResultLine(record, history, const <String>[
        '오빠, 연속 적중이야. 오늘 감각 정말 날카로운데?',
        '오빠, 또 맞혔네. 테이블 흐름 완전히 읽고 있어.',
        '오빠, 이걸로 연승이야. 축하해, 흐름 아주 좋아.',
        '오빠, 연달아 가져가네. 지금 선택이 계속 빛나고 있어.',
        '오빠, 세 판째 좋은 결과야. 멋진 연승이야.',
      ]);
    }
    if (won && record.net >= record.stake * 3) {
      return _pickDealerResultLine(record, history, const <String>[
        '오빠, 크게 터졌어! 이번 판은 제대로 가져갔네.',
        '오빠, 대박이야. 높은 배당을 정확히 잡았어!',
        '오빠, 축하해! 테이블이 한 번에 확 달아올랐어.',
        '오빠, 이건 정말 멋진 적중이야. 큰 수익이 들어왔어.',
        '오빠, 선택이 완벽했어. 이번 판 배당이 아주 커!',
        '오빠, 제대로 맞혔어. 오늘 기억에 남을 한 판이네.',
      ]);
    }
    if (won) {
      final gameLines = switch (record.game) {
        CasinoGameType.baccarat => const <String>[
          '오빠, 선택한 쪽이 이겼어. 축하해.',
          '오빠, 마지막 카드까지 정확히 읽었네. 적중이야.',
        ],
        CasinoGameType.blackjack => const <String>[
          '오빠, 딜러보다 좋은 패야. 깔끔한 승리네.',
          '오빠, 스탠드 타이밍 좋았어. 이 판은 오빠 승리야.',
        ],
        CasinoGameType.roulette => const <String>[
          '오빠, 공이 선택한 구역에 멈췄어. 축하해.',
          '오빠, 휠 결과가 딱 맞았어. 적중 칩 정산할게.',
        ],
        CasinoGameType.craps => const <String>[
          '오빠, 주사위가 선택을 따라줬어. 이번 판 승리야.',
          '오빠, 포인트를 잘 잡았어. 축하해.',
        ],
        CasinoGameType.sicBo => const <String>[
          '오빠, 세 주사위 조합이 정확히 맞았어. 축하해.',
          '오빠, 합계를 제대로 봤네. 적중이야.',
        ],
        CasinoGameType.slots => const <String>[
          '오빠, 심벌이 맞았어. 당첨 칩 챙겨 줄게.',
          '오빠, 릴이 예쁘게 멈췄네. 축하해.',
        ],
      };
      return _pickDealerResultLine(record, history, <String>[
        ...gameLines,
        '오빠, 축하해. 이번 판은 정확하게 맞혔어.',
        '오빠, 좋은 선택이었어. 당첨 칩 정산해 줄게.',
        '오빠, 결과가 좋네. 이번 판은 오빠가 가져갔어.',
        '오빠, 적중이야. 침착한 선택이 통했네.',
      ]);
    }
    if (pushed) {
      return _pickDealerResultLine(record, history, const <String>[
        '오빠, 이번 판은 무승부야. 베팅 칩은 그대로 돌려줄게.',
        '오빠, 서로 같은 결과네. 손해 없이 다음 판으로 가자.',
        '오빠, 푸시야. 승부는 다음 판에서 다시 보자.',
        '오빠, 이번에는 비겼어. 칩을 원위치해 줄게.',
        '오빠, 승패 없이 끝났어. 다음 선택을 천천히 보자.',
      ]);
    }
    if (lossStreak >= 3) {
      return _pickDealerResultLine(record, history, const <String>[
        '오빠, 지금은 흐름이 조금 차가워. 금액 낮추고 쉬어가도 좋아.',
        '오빠, 연속으로 아쉽네. 서두르지 말고 다음 선택 천천히 보자.',
        '오빠, 이번에도 결과가 비켜갔어. 무리해서 따라가지는 마.',
        '오빠, 잠깐 흐름을 끊어도 괜찮아. 다음 판은 더 신중하게 가자.',
        '오빠, 아쉬운 결과가 이어졌어. 베팅 크기부터 다시 살펴볼까?',
      ]);
    }
    if (_isNarrowLoss(record)) {
      return _pickDealerResultLine(record, history, const <String>[
        '오빠, 정말 한 끗 차이였어. 마지막 결과가 조금만 달랐으면 됐는데 아쉽네.',
        '오빠, 거의 잡았어. 딱 한 끗이 모자랐네.',
        '오빠, 아슬아슬했어. 이번 판은 정말 조금 차이로 놓쳤어.',
        '오빠, 끝까지 승부가 붙었는데 한 끗 차이로 아쉽게 됐어.',
        '오빠, 판단은 좋았어. 결과만 아주 살짝 비켜갔네.',
      ]);
    }
    return _pickDealerResultLine(record, history, const <String>[
      '오빠, 이번 판은 조금 아쉽게 됐어. 다음 결과를 차분히 보자.',
      '오빠, 이번에는 테이블이 반대쪽을 골랐네. 아쉬워.',
      '오빠, 결과가 비켜갔어. 다음 판은 서두르지 않아도 돼.',
      '오빠, 아쉽지만 이번 선택은 맞지 않았어. 칩을 정리할게.',
      '오빠, 이번 판은 놓쳤네. 흐름을 한 번 더 살펴보자.',
      '오빠, 조금 아쉬운 결과야. 다음 선택은 천천히 해도 괜찮아.',
      '오빠, 이번에는 운이 따라주지 않았네. 무리하지 말고 이어가자.',
    ]);
  }

  int _trailingResultCount(
    List<CasinoRoundRecord> history,
    bool Function(CasinoRoundRecord record) matches,
  ) {
    var count = 0;
    for (final record in history.reversed) {
      if (!matches(record)) break;
      count++;
    }
    return count;
  }

  bool _isNarrowLoss(CasinoRoundRecord record) {
    if (record.net >= 0) return false;
    final totals = RegExp(r'\((\d+)\)')
        .allMatches(record.detail)
        .map((match) => int.parse(match.group(1)!))
        .toList();
    if (totals.length < 2) return false;
    if (record.game == CasinoGameType.blackjack) {
      return totals[0] <= 21 &&
          totals[1] <= 21 &&
          (totals[0] - totals[1]).abs() <= 2;
    }
    if (record.game == CasinoGameType.baccarat &&
        (record.betLabel.contains('플레이어') || record.betLabel.contains('뱅커'))) {
      return (totals[0] - totals[1]).abs() == 1;
    }
    return false;
  }

  String _pickDealerLine(
    CasinoRoundRecord record,
    List<CasinoRoundRecord> history,
    List<String> lines,
  ) {
    final seed = record.id.codeUnits.fold<int>(
      record.minute + history.length,
      (sum, value) => sum + value,
    );
    var index = seed % lines.length;
    if (lines.length > 1 && lines[index] == _dealerReaction) {
      index = (index + 1) % lines.length;
    }
    return lines[index];
  }

  String _pickDealerResultLine(
    CasinoRoundRecord record,
    List<CasinoRoundRecord> history,
    List<String> lines,
  ) {
    final picked = _pickDealerLine(record, history, lines);
    final naturalLine = picked.startsWith('오빠, ')
        ? picked.substring('오빠, '.length)
        : picked;
    return '$naturalLine ${_chipSettlementDialogue(record)}';
  }

  String _chipSettlementDialogue(CasinoRoundRecord record) {
    if (record.net > 0) {
      return '칩 ${_money(record.net)}원을 더 얻었어. 베팅 칩까지 합쳐 ${_money(record.payout)}원을 돌려줄게.';
    }
    if (record.net < 0) {
      return '이번 판에는 칩 ${_money(-record.net)}원을 가져갔어.';
    }
    return '베팅한 칩 ${_money(record.stake)}원은 그대로 돌려줄게.';
  }

  String _dealerTableDialogue(CasinoGameType game) => switch (game) {
    CasinoGameType.baccarat => '플레이어와 뱅커 중 한쪽에 칩을 놓아 줘. 타이와 페어도 선택할 수 있어.',
    CasinoGameType.blackjack => '카드를 두 장 줄게. 히트, 스탠드, 더블 중에서 천천히 골라 줘.',
    CasinoGameType.roulette => '원하는 숫자나 구역에 칩을 놓아 줘. 선택이 끝나면 휠 돌릴게.',
    CasinoGameType.craps => '패스와 돈트 패스 중 하나를 골라 줘. 포인트가 정해지면 계속 이어져.',
    CasinoGameType.sicBo => '세 주사위의 합과 조합을 고르는 게임이야. 배당판을 보고 칩을 놓아 줘.',
    CasinoGameType.slots => '칩을 정한 뒤 스핀을 눌러 줘. 같은 심벌 세 개면 배당 줄게.',
  };

  Widget _buildHeader() {
    final clock = marketTimeLabel(_state.marketMinute);
    return Container(
      key: const Key('casino-header'),
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF120D0C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _casinoGold.withValues(alpha: 0.55)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('casino-back'),
            tooltip: _selectedGame == null ? '카지노 나가기' : '카지노 로비',
            onPressed: _busy ? null : _handleBack,
            icon: Icon(
              _selectedGame == null
                  ? Icons.arrow_back_rounded
                  : Icons.grid_view_rounded,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedGame == null
                      ? widget.testMode
                            ? '데시멀 온라인 카지노 · TEST'
                            : switch (_entryPhase) {
                                _CasinoEntryPhase.welcome => '데시멀 카지노 · 국가망 접속',
                                _CasinoEntryPhase.exchange => '국가계좌 칩 교환',
                                _CasinoEntryPhase.handover => '온라인 칩 전송',
                                _CasinoEntryPhase.lobby => '데시멀 온라인 카지노',
                              }
                      : casinoGameTitle(_selectedGame!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$clock · 국가계좌 ${_money(_state.availableBrokerageCash)}원 · 칩 ${_money(_casino.chipBalance)}원',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE7D2A8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('casino-rules'),
            tooltip: '게임 규칙',
            onPressed: _showRules,
            icon: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.help_outline_rounded, color: _casinoGold, size: 22),
                Text(
                  '규칙',
                  style: TextStyle(
                    color: _casinoGold,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    final isGreeting = _welcomeDialogueStep == 0;
    final hasTableChips = _availableChips >= casinoMinimumStake;
    return _NovelDialogue(
      key: ValueKey<int>(_welcomeDialogueStep),
      speaker: '이안',
      line: isGreeting
          ? '오빠, 오늘도 왔네.'
          : hasTableChips
          ? '보유 칩으로 온라인 테이블에 가거나, 국가계좌 돈을 칩으로 더 바꿀 수 있어.'
          : '지금은 칩이 하나도 없어. 먼저 국가계좌 돈을 칩으로 바꿔야 테이블에 들어갈 수 있어.',
      charactersPerSecond: 42,
      tapAdvancesImmediately: isGreeting,
      continueKey: const Key('casino-welcome-dialogue-next'),
      onContinue: isGreeting
          ? () => setState(() => _welcomeDialogueStep = 1)
          : null,
      child: isGreeting
          ? null
          : SizedBox(
              width: double.infinity,
              height: 52,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('casino-entry-continue'),
                      onPressed: _busy || !_canOpenTables
                          ? null
                          : _openTableLobby,
                      style: FilledButton.styleFrom(
                        backgroundColor: _casinoWine,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF49383A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.grid_view_rounded, size: 18),
                      label: Text(
                        hasTableChips ? '온라인 테이블' : '칩 교환 후 접속',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('casino-entry-exchange'),
                      onPressed: _busy || !_canExchangeChips
                          ? null
                          : _openChipDesk,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _casinoGold,
                        side: const BorderSide(color: _casinoGold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.currency_exchange_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        '칩 교환',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChipExchange() {
    final maximum = _maximumExchangeAmount;
    final presets =
        <int>{casinoMinimumStake, 5000, 10000, 50000, 100000, maximum}
            .where(
              (amount) => amount >= casinoMinimumStake && amount <= maximum,
            )
            .toList()
          ..sort();
    return Column(
      children: [
        const SizedBox(height: 330),
        _CasinoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CasinoSectionLabel('NATIONAL ACCOUNT · CHIP EXCHANGE'),
              const SizedBox(height: 7),
              const Text(
                '얼마를 칩으로 바꿀까?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              _buildDealerDialogue('오빠, 바꿀 금액 말해 줘. 국가계좌에서 500원 단위로 전송할게.'),
              const SizedBox(height: 9),
              Text(
                '국가계좌 ${_money(_state.availableBrokerageCash)}원 · 보유 칩 ${_money(_casino.chipBalance)}원\n'
                '교환한 칩만 온라인 테이블에서 사용해. 접속을 끝낼 때 국가계좌 환전 또는 칩 보관을 직접 고를 수 있어.',
                style: const TextStyle(
                  color: Color(0xFFD8CDC3),
                  fontSize: 10,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D352C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _casinoGold.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('casino-exchange-minus'),
                      onPressed: _busy || _exchangeAmount <= casinoMinimumStake
                          ? null
                          : () => _setExchangeAmount(
                              _exchangeAmount - casinoMinimumStake,
                            ),
                      icon: const Icon(Icons.remove_rounded),
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Text(
                        '${_money(_exchangeAmount)}원',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFD98C),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('casino-exchange-plus'),
                      onPressed: _busy || _exchangeAmount >= maximum
                          ? null
                          : () => _setExchangeAmount(
                              _exchangeAmount + casinoMinimumStake,
                            ),
                      icon: const Icon(Icons.add_rounded),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              if (presets.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: presets
                      .map(
                        (amount) => ChoiceChip(
                          key: Key('casino-exchange-$amount'),
                          selected: _exchangeAmount == amount,
                          onSelected: _busy
                              ? null
                              : (_) => _setExchangeAmount(amount),
                          label: Text('${_money(amount)}원'),
                          selectedColor: _casinoWine,
                          backgroundColor: const Color(0xFF2B211D),
                          labelStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                          side: BorderSide(
                            color: _exchangeAmount == amount
                                ? _casinoGold
                                : const Color(0xFF5D4C42),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  key: const Key('casino-exchange-confirm'),
                  onPressed: _busy || maximum < casinoMinimumStake
                      ? null
                      : _confirmChipExchange,
                  style: FilledButton.styleFrom(
                    backgroundColor: _casinoWine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.paid_rounded, size: 19),
                  label: const Text(
                    '이 금액으로 칩 교환',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChipHandover() => Column(
    children: [
      const SizedBox(height: 355),
      _CasinoPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CasinoSectionLabel('YOUR CHIPS ARE READY'),
            const SizedBox(height: 7),
            _buildDealerDialogue(
              '오빠, 여기 칩 ${_money(_casino.chipBalance)}원이야. 수량 확인해 줘. 나갈 때 환전하거나 다음에 쓰도록 보관할 수 있어.',
            ),
            const SizedBox(height: 7),
            const Text(
              '테이블에서는 이 칩 잔액으로만 베팅합니다. 딜러가 각 게임 자리까지 안내합니다.',
              style: TextStyle(
                color: Color(0xFFD8CDC3),
                fontSize: 11,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                key: const Key('casino-handover-accept'),
                onPressed: _busy || _casino.chipBalance < casinoMinimumStake
                    ? null
                    : _acceptChips,
                style: FilledButton.styleFrom(
                  backgroundColor: _casinoWine,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.casino_rounded, size: 19),
                label: const Text(
                  '칩 받고 테이블 보기',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildLobby() => Column(
    children: [
      SizedBox(
        height: 650,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 54, child: _buildDealerFullShotPane()),
            const SizedBox(width: 8),
            Expanded(
              flex: 46,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(9, 9, 9, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xF01A1310),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _casinoGold.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TABLE LIST',
                          style: TextStyle(
                            color: _casinoGold.withValues(alpha: 0.95),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          '게임을 골라 줘',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '“오빠, 원하는 테이블 눌러 줘.”',
                          style: TextStyle(
                            color: Color(0xFFE6D6C7),
                            fontSize: 10,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '칩 ${_money(_casino.chipBalance)}원',
                          style: const TextStyle(
                            color: Color(0xFFFFD98C),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  for (
                    var index = 0;
                    index < CasinoGameType.values.length;
                    index++
                  ) ...[
                    Expanded(
                      child: _buildGameCard(CasinoGameType.values[index]),
                    ),
                    if (index < CasinoGameType.values.length - 1)
                      const SizedBox(height: 7),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      if (!widget.testMode &&
          _casino.activeBlackjack == null &&
          _casino.activeCraps == null) ...[
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('casino-exchange-more'),
            onPressed: _busy || _maximumExchangeAmount < casinoMinimumStake
                ? null
                : () =>
                      setState(() => _entryPhase = _CasinoEntryPhase.exchange),
            icon: const Icon(Icons.currency_exchange_rounded, size: 17),
            label: const Text('칩 추가 교환'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _casinoGold,
              side: const BorderSide(color: _casinoGold),
            ),
          ),
        ),
      ],
      if (_canGoOffline) ...[const SizedBox(height: 12), _buildOfflineButton()],
      const SizedBox(height: 12),
      _buildBudgetMeter(panel: true),
      const SizedBox(height: 12),
      _buildHistory(),
    ],
  );

  Widget _buildDealerFullShotPane() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF16100E),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _casinoGold.withValues(alpha: 0.72)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/casino/dealer_table_guide_age20_v1.png',
          fit: BoxFit.cover,
          alignment: const Alignment(0.16, 0),
          filterQuality: FilterQuality.high,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0x00000000), Color(0xB8000000)],
              stops: [0, 0.72, 1],
            ),
          ),
        ),
        const Positioned(
          left: 9,
          right: 9,
          bottom: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IAN · CASINO DEALER',
                style: TextStyle(
                  color: Color(0xFFFFD98C),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '“오빠, 내가 안내할게.”',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildGameCard(CasinoGameType game) {
    final (icon, subtitle, asset) = switch (game) {
      CasinoGameType.baccarat => (
        Icons.style_rounded,
        'P·B·타이·페어 · 뱅커 5% 커미션',
        'assets/images/casino/tile_casino_baccarat_v1.webp',
      ),
      CasinoGameType.blackjack => (
        Icons.filter_2_rounded,
        'S17 · 블랙잭 3:2 · 히트·스탠드·더블',
        'assets/images/casino/tile_casino_blackjack_v1.webp',
      ),
      CasinoGameType.roulette => (
        Icons.motion_photos_on_rounded,
        '싱글 제로 · 스트레이트 35:1',
        'assets/images/casino/tile_casino_roulette_v1.webp',
      ),
      CasinoGameType.craps => (
        Icons.casino_outlined,
        '패스 · 돈트 패스 · 포인트와 세븐 아웃',
        'assets/images/casino/tile_casino_craps_v1.png',
      ),
      CasinoGameType.sicBo => (
        Icons.casino_rounded,
        '대·소·홀짝·트리플·합계',
        'assets/images/casino/tile_casino_sicbo_v1.webp',
      ),
      CasinoGameType.slots => (
        Icons.view_column_rounded,
        '3릴 · 공개 이론 지급률 97.2%',
        'assets/images/casino/tile_casino_slots_v1.webp',
      ),
    };
    final tableNumber = (CasinoGameType.values.indexOf(game) + 1)
        .toString()
        .padLeft(2, '0');
    return Material(
      color: const Color(0xFF17110F),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('casino-game-${game.name}'),
        onTap: () => _selectGame(game),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: AssetImage(asset),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x16000000),
                      Color(0x33000000),
                      Color(0xF0110C0A),
                    ],
                    stops: [0, 0.46, 0.82],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _casinoGold.withValues(alpha: 0.72),
                    width: 1.1,
                  ),
                ),
              ),
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC130D0B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _casinoGold.withValues(alpha: 0.72),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: _casinoGold, size: 10),
                      const SizedBox(width: 3),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Color(0xFFF3D69B),
                          fontSize: 6.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 6,
                top: 7,
                child: Text(
                  'TABLE $tableNumber',
                  style: const TextStyle(
                    color: Color(0xFFE7CC96),
                    fontSize: 6.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
              ),
              Positioned(
                left: 7,
                right: 6,
                bottom: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 1.5,
                      decoration: BoxDecoration(
                        color: _casinoGold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            casinoGameTitle(game),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: _casinoGold,
                          size: 13,
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD7CCC2),
                        fontSize: 6.5,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black, blurRadius: 6)],
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

  Widget _buildGame() {
    final game = _selectedGame!;
    return Column(
      children: [
        _CasinoPanel(
          key: const Key('casino-game-panel'),
          padding: const EdgeInsets.fromLTRB(7, 8, 7, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLiveTableStage(game),
              if (game != CasinoGameType.slots) ...[
                const SizedBox(height: 6),
                if (game == CasinoGameType.blackjack)
                  _buildBlackjackActionBar()
                else
                  _buildPlayButton(game),
              ],
              const SizedBox(height: 4),
              Text(
                _gameRuleLine(game),
                style: const TextStyle(
                  color: Color(0xFFD6C9BE),
                  fontSize: 10,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              if (game == CasinoGameType.blackjack) ...[
                _buildBlackjackTable(),
              ] else if (game == CasinoGameType.slots) ...[
                _buildStakeSelector(),
                const SizedBox(height: 8),
                _buildSlotsPaytable(),
              ] else ...[
                _buildBetOptions(game),
                if (game != CasinoGameType.craps ||
                    _casino.activeCraps == null) ...[
                  const SizedBox(height: 8),
                  _buildStakeSelector(),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 7),
        _buildGameNavigationRow(),
        const SizedBox(height: 5),
        _buildBudgetMeter(panel: true),
        const SizedBox(height: 7),
        _buildHistory(game: game),
      ],
    );
  }

  Widget _buildGameTitleBar(CasinoGameType game) {
    final clock = marketTimeLabel(_state.marketMinute);
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          IconButton(
            key: const Key('casino-back'),
            tooltip: '카지노 로비',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 40),
            visualDensity: VisualDensity.compact,
            onPressed: _busy ? null : _handleBack,
            icon: const Icon(
              Icons.grid_view_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 85),
            child: Text(
              casinoGameTitle(game),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              '$clock · 국가계좌 ${_money(_state.availableBrokerageCash)}원 · 칩 ${_money(_casino.chipBalance)}원',
              key: const Key('casino-game-money-status'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFFE7D2A8),
                fontSize: 8.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            key: const Key('casino-rules'),
            tooltip: '게임 규칙',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 40),
            visualDensity: VisualDensity.compact,
            onPressed: _showRules,
            icon: const Icon(
              Icons.help_outline_rounded,
              color: _casinoGold,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTableStage(CasinoGameType game) {
    final stage = _CasinoLiveTableStage(
      game: game,
      motion: _tableMotion,
      motionToken: _tableMotionToken,
      stake: game == CasinoGameType.blackjack && _casino.activeBlackjack != null
          ? _casino.activeBlackjack!.stake
          : game == CasinoGameType.craps && _casino.activeCraps != null
          ? _casino.activeCraps!.stake
          : _stake,
      betLabel: game == CasinoGameType.blackjack
          ? '기본 핸드'
          : game == CasinoGameType.craps && _casino.activeCraps != null
          ? casinoBetTitle(_casino.activeCraps!.betType)
          : casinoBetTitle(_selectedBet, selection: _selection),
      blackjackHand: _casino.activeBlackjack,
      crapsRound: _casino.activeCraps,
      latest: _latestRecordFor(game),
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
    if (game != CasinoGameType.slots) return stage;
    return Stack(
      children: [
        stage,
        Positioned(
          right: 5,
          top: 43,
          child: _CasinoSlotLever(
            stake: _stake,
            pulling: _busy && _tableMotion == _CasinoTableMotion.reels,
            enabled: !_busy && _canStartRound,
            lockReason: _shortLockReason(),
            onPull: _playSelected,
            onLockedTap: !_busy && _isOutOfChips ? _showOutOfChipsPrompt : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBetOptions(CasinoGameType game) => switch (game) {
    CasinoGameType.baccarat => _buildBaccaratBoard(),
    CasinoGameType.roulette => _buildRouletteBoard(),
    CasinoGameType.craps => _buildCrapsBoard(),
    CasinoGameType.sicBo => _buildSicBoBoard(),
    CasinoGameType.slots => _buildSlotsPaytable(),
    CasinoGameType.blackjack => _buildLegacyBetOptions(game),
  };

  Widget _buildCrapsBoard() {
    final round = _casino.activeCraps;
    const pointNumbers = <int>[4, 5, 6, 8, 9, 10];
    if (round == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CasinoBoardHeader(
            eyebrow: 'CRAPS · COME-OUT ROLL',
            title: '라인에 칩을 놓으세요',
            note: '컴아웃 후 포인트가 설정되면 포인트나 7이 먼저 나올 때까지 계속됩니다.',
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A3E30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _casinoGold.withValues(alpha: 0.72)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildBetZone(
                        CasinoBetType.crapsPassLine,
                        label: '패스 라인',
                        english: 'PASS LINE',
                        payout: '2.00×',
                        tint: const Color(0xFF7A2332),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _buildBetZone(
                        CasinoBetType.crapsDontPass,
                        label: '돈트 패스',
                        english: "DON'T PASS",
                        payout: '2.00×',
                        tint: const Color(0xFF263D38),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    for (final point in pointNumbers) ...[
                      if (point != pointNumbers.first) const SizedBox(width: 4),
                      Expanded(child: _CrapsPointCell(point: point)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'COME  ·  FIELD  ·  PLACE',
                      style: TextStyle(
                        color: Color(0x88F4E5C3),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      'v1 라인 베팅',
                      style: TextStyle(color: _casinoGold, fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    final recentRolls = round.rolls.length <= 4
        ? round.rolls
        : round.rolls.sublist(round.rolls.length - 4);
    final pass = round.betType == CasinoBetType.crapsPassLine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CasinoBoardHeader(
          eyebrow: 'CRAPS · POINT ON',
          title: '포인트 ${round.point} 진행 중',
          note: pass
              ? '${round.point}이 7보다 먼저 나오면 패스 라인 승리입니다.'
              : '7이 ${round.point}보다 먼저 나오면 돈트 패스 승리입니다.',
        ),
        const SizedBox(height: 6),
        Container(
          key: const Key('casino-craps-active-board'),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B4B38), Color(0xFF082F27)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _casinoGold, width: 1.2),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    key: Key('casino-craps-point-${round.point}'),
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1E7D5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black54, blurRadius: 10),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ON',
                            style: TextStyle(
                              color: Color(0xFF8A1F30),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${round.point}',
                            style: const TextStyle(
                              color: Color(0xFF17110F),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          casinoBetTitle(round.betType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '예치금 ${_money(round.stake)}원 · 1:1',
                          style: const TextStyle(
                            color: Color(0xFFE8D19D),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '주사위 ${round.rolls.length}회 · 중간 롤은 추가 시간 없음',
                          style: const TextStyle(
                            color: Color(0xFFB8CFC7),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var index = 0; index < recentRolls.length; index++) ...[
                    if (index > 0) const SizedBox(width: 5),
                    Expanded(
                      child: Container(
                        key: Key('casino-craps-roll-$index'),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x55140E0C),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_diceFace(recentRolls[index][0])} ${_diceFace(recentRolls[index][1])}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '합 ${recentRolls[index][0] + recentRolls[index][1]}',
                              style: const TextStyle(
                                color: _casinoGold,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _chooseBet(CasinoBetType type) {
    if (_busy) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _selectedBet = type;
      if (type == CasinoBetType.sicBoSpecificTriple) {
        _selection = 1;
      } else if (type == CasinoBetType.sicBoTotal) {
        _selection = 10;
      } else if (type == CasinoBetType.rouletteStraight) {
        _selection = 0;
      }
    });
  }

  Widget _buildBaccaratBoard() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _CasinoBoardHeader(
        eyebrow: 'BACCARAT BETTING MAT',
        title: '승부에 칩을 놓으세요',
        note: '표시 배당은 원금을 포함한 총 지급액입니다.',
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: _buildBetZone(
              CasinoBetType.baccaratPlayer,
              label: '플레이어',
              english: 'PLAYER',
              payout: '2.00×',
              tint: const Color(0xFF194A76),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildBetZone(
              CasinoBetType.baccaratTie,
              label: '타이',
              english: 'TIE',
              payout: '9.00×',
              tint: const Color(0xFF176045),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildBetZone(
              CasinoBetType.baccaratBanker,
              label: '뱅커',
              english: 'BANKER',
              payout: '1.95×',
              tint: const Color(0xFF731F32),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: _buildBetZone(
              CasinoBetType.baccaratPlayerPair,
              label: '플레이어 페어',
              english: 'P PAIR',
              payout: '12.00×',
              tint: const Color(0xFF183C5F),
              compact: true,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildBetZone(
              CasinoBetType.baccaratBankerPair,
              label: '뱅커 페어',
              english: 'B PAIR',
              payout: '12.00×',
              tint: const Color(0xFF5A1B2A),
              compact: true,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildBetZone(
    CasinoBetType type, {
    required String label,
    required String english,
    required String payout,
    required Color tint,
    bool compact = false,
    int? rouletteArtIndex,
  }) {
    final selected = _selectedBet == type;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label 베팅, $payout 지급',
      child: Material(
        key: Key('casino-bet-${type.name}'),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: Ink(
          height: compact ? 48 : 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(tint, Colors.white, selected ? 0.12 : 0.03)!,
                Color.lerp(tint, Colors.black, 0.35)!,
              ],
            ),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected ? _casinoGold : Colors.white24,
              width: selected ? 2 : 0.8,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _casinoGold.withValues(alpha: 0.24),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: _busy ? null : () => _chooseBet(type),
            borderRadius: BorderRadius.circular(11),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: rouletteArtIndex == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          english,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFD7C7B8),
                            fontSize: 6.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.45,
                          ),
                        ),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          payout,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFFFFD98E)
                                : _casinoGold,
                            fontSize: 8.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RouletteBetIcon(iconIndex: rouletteArtIndex),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                payout,
                                style: TextStyle(
                                  color: selected
                                      ? const Color(0xFFFFD98E)
                                      : _casinoGold,
                                  fontSize: 7.8,
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
        ),
      ),
    );
  }

  Widget _buildRouletteBoard() {
    Widget trio(List<({CasinoBetType type, String label})> bets) => Row(
      children: [
        for (var index = 0; index < bets.length; index++) ...[
          if (index > 0) const SizedBox(width: 5),
          Expanded(
            child: _buildBetZone(
              bets[index].type,
              label: bets[index].label,
              english: index == 0
                  ? '1–12'
                  : index == 1
                  ? '13–24'
                  : '25–36',
              payout: '3×',
              tint: _casinoGreen,
              compact: true,
            ),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CasinoBoardHeader(
          eyebrow: 'EUROPEAN SINGLE ZERO',
          title: '룰렛 베팅 보드',
          note: '0이 있는 유럽식 휠입니다. 0은 외부 베팅에서 제외됩니다.',
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final bet in const [
              (
                type: CasinoBetType.rouletteLow,
                label: '1–18',
                color: Color(0xFF234B3D),
                artIndex: 0,
              ),
              (
                type: CasinoBetType.rouletteEven,
                label: '짝수',
                color: Color(0xFF34302D),
                artIndex: 1,
              ),
              (
                type: CasinoBetType.rouletteRed,
                label: '레드',
                color: Color(0xFF8B2437),
                artIndex: 2,
              ),
            ]) ...[
              if (bet.type != CasinoBetType.rouletteLow)
                const SizedBox(width: 5),
              Expanded(
                child: _buildBetZone(
                  bet.type,
                  label: bet.label,
                  english: 'EVEN MONEY',
                  payout: '2×',
                  tint: bet.color,
                  compact: true,
                  rouletteArtIndex: bet.artIndex,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final bet in const [
              (
                type: CasinoBetType.rouletteBlack,
                label: '블랙',
                color: Color(0xFF171719),
                artIndex: 3,
              ),
              (
                type: CasinoBetType.rouletteOdd,
                label: '홀수',
                color: Color(0xFF34302D),
                artIndex: 4,
              ),
              (
                type: CasinoBetType.rouletteHigh,
                label: '19–36',
                color: Color(0xFF234B3D),
                artIndex: 5,
              ),
            ]) ...[
              if (bet.type != CasinoBetType.rouletteBlack)
                const SizedBox(width: 5),
              Expanded(
                child: _buildBetZone(
                  bet.type,
                  label: bet.label,
                  english: 'EVEN MONEY',
                  payout: '2×',
                  tint: bet.color,
                  compact: true,
                  rouletteArtIndex: bet.artIndex,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        trio(const [
          (type: CasinoBetType.rouletteDozen1, label: '첫째 12'),
          (type: CasinoBetType.rouletteDozen2, label: '둘째 12'),
          (type: CasinoBetType.rouletteDozen3, label: '셋째 12'),
        ]),
        const SizedBox(height: 4),
        trio(const [
          (type: CasinoBetType.rouletteColumn1, label: '1열'),
          (type: CasinoBetType.rouletteColumn2, label: '2열'),
          (type: CasinoBetType.rouletteColumn3, label: '3열'),
        ]),
        const SizedBox(height: 4),
        _buildBetZone(
          CasinoBetType.rouletteStraight,
          label: '번호 하나 직접 선택',
          english: 'STRAIGHT UP · ${_selection.toString().padLeft(2, '0')}',
          payout: '36×',
          tint: _casinoWine,
          compact: true,
        ),
        if (_selectedBet == CasinoBetType.rouletteStraight) ...[
          const SizedBox(height: 8),
          _buildRouletteNumberBoard(),
        ],
      ],
    );
  }

  Widget _buildRouletteNumberBoard() {
    const redNumbers = <int>{
      1,
      3,
      5,
      7,
      9,
      12,
      14,
      16,
      18,
      19,
      21,
      23,
      25,
      27,
      30,
      32,
      34,
      36,
    };
    Widget number(int value) {
      final color = value == 0
          ? const Color(0xFF176044)
          : redNumbers.contains(value)
          ? const Color(0xFF8B2437)
          : const Color(0xFF181719);
      final selected = _selection == value;
      return Semantics(
        button: true,
        selected: selected,
        label: '룰렛 $value번',
        child: Material(
          key: Key('casino-number-$value'),
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(
              color: selected ? _casinoGold : Colors.white24,
              width: selected ? 2 : 0.7,
            ),
          ),
          child: InkWell(
            onTap: _busy ? null : () => setState(() => _selection = value),
            borderRadius: BorderRadius.circular(5),
            child: Center(
              child: Text(
                '$value',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF0B3026),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB99454)),
      ),
      child: Column(
        children: [
          SizedBox(height: 34, width: double.infinity, child: number(0)),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 36,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1.35,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, index) => number(index + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSicBoBoard() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _CasinoBoardHeader(
        eyebrow: 'THREE DICE TABLE',
        title: '다이사이 배당판',
        note: '대·소·홀·짝은 트리플이 나오면 적중하지 않습니다.',
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          for (final bet in const [
            (type: CasinoBetType.sicBoBig, label: '대', en: 'BIG · 11–17'),
            (type: CasinoBetType.sicBoSmall, label: '소', en: 'SMALL · 4–10'),
          ]) ...[
            if (bet.type != CasinoBetType.sicBoBig) const SizedBox(width: 6),
            Expanded(
              child: _buildBetZone(
                bet.type,
                label: bet.label,
                english: bet.en,
                payout: '2×',
                tint: const Color(0xFF7B252E),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: _buildBetZone(
              CasinoBetType.sicBoOdd,
              label: '홀',
              english: 'ODD',
              payout: '2×',
              tint: const Color(0xFF25463A),
              compact: true,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildBetZone(
              CasinoBetType.sicBoEven,
              label: '짝',
              english: 'EVEN',
              payout: '2×',
              tint: const Color(0xFF25463A),
              compact: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: _buildBetZone(
              CasinoBetType.sicBoAnyTriple,
              label: '아무 트리플',
              english: 'ANY TRIPLE',
              payout: '26×',
              tint: const Color(0xFF55351C),
              compact: true,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildBetZone(
              CasinoBetType.sicBoSpecificTriple,
              label: '지정 트리플',
              english: 'SPECIFIC · $_selection',
              payout: '151×',
              tint: const Color(0xFF55351C),
              compact: true,
            ),
          ),
        ],
      ),
      if (_selectedBet == CasinoBetType.sicBoSpecificTriple) ...[
        const SizedBox(height: 7),
        _buildDiceSelector(),
      ],
      const SizedBox(height: 4),
      _buildBetZone(
        CasinoBetType.sicBoTotal,
        label: '주사위 합계 선택',
        english: 'TOTAL · $_selection',
        payout: '${_sicBoTotalMultiplier(_selection)}×',
        tint: const Color(0xFF173E33),
        compact: true,
      ),
      if (_selectedBet == CasinoBetType.sicBoTotal) ...[
        const SizedBox(height: 7),
        _buildSicBoTotalGrid(),
      ],
    ],
  );

  Widget _buildDiceSelector() => Row(
    children: [
      for (var value = 1; value <= 6; value++) ...[
        if (value > 1) const SizedBox(width: 5),
        Expanded(
          child: Semantics(
            button: true,
            selected: _selection == value,
            label: '$value 트리플',
            child: Material(
              key: Key('casino-number-$value'),
              color: _selection == value
                  ? const Color(0xFFE8D7B4)
                  : const Color(0xFF2D2521),
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                onTap: _busy ? null : () => setState(() => _selection = value),
                borderRadius: BorderRadius.circular(9),
                child: SizedBox(
                  height: 43,
                  child: Center(
                    child: Text(
                      _diceFace(value),
                      style: TextStyle(
                        color: _selection == value
                            ? const Color(0xFF541B24)
                            : Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );

  Widget _buildSicBoTotalGrid() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 14,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 7,
      childAspectRatio: 0.78,
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
    ),
    itemBuilder: (context, index) {
      final value = index + 4;
      final selected = _selection == value;
      return Semantics(
        button: true,
        selected: selected,
        label: '합계 $value, ${_sicBoTotalMultiplier(value)}배 지급',
        child: Material(
          key: Key('casino-number-$value'),
          color: selected ? _casinoWine : const Color(0xFF231C19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
            side: BorderSide(color: selected ? _casinoGold : Colors.white24),
          ),
          child: InkWell(
            onTap: _busy ? null : () => setState(() => _selection = value),
            borderRadius: BorderRadius.circular(7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${_sicBoTotalMultiplier(value)}×',
                  style: const TextStyle(color: _casinoGold, fontSize: 7),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  int _sicBoTotalMultiplier(int total) => switch (total) {
    4 || 17 => 51,
    5 || 16 => 19,
    6 || 15 => 15,
    7 || 14 => 13,
    8 || 13 => 9,
    9 || 10 || 11 || 12 => 7,
    _ => 0,
  };

  String _diceFace(int value) =>
      const ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'][value - 1];

  Widget _buildSlotsPaytable() {
    const rows = [
      (symbolIndex: 5, count: 3, label: '럭키 세븐', payout: '95×'),
      (symbolIndex: 4, count: 3, label: '벨', payout: '27×'),
      (symbolIndex: 3, count: 3, label: 'BAR', payout: '18×'),
      (symbolIndex: 2, count: 3, label: '스타', payout: '12×'),
      (symbolIndex: 1, count: 3, label: '레몬', payout: '8×'),
      (symbolIndex: 0, count: 3, label: '체리', payout: '5×'),
      (symbolIndex: 0, count: 2, label: '체리 2개', payout: '3×'),
    ];
    Widget payCell(int index) {
      final item = rows[index];
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF211916),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF493A32)),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: _CasinoSlotSymbol(
                reelIndex: index,
                symbolIndex: item.symbolIndex,
                dimension: 21,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD6CBC2),
                        fontSize: 7.5,
                      ),
                    ),
                  ),
                  Text(
                    ' ×${item.count}',
                    style: const TextStyle(
                      color: Color(0xFF9F9188),
                      fontSize: 6.5,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              item.payout,
              style: const TextStyle(
                color: _casinoGold,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CasinoBoardHeader(
          eyebrow: 'CLASSIC THREE REEL',
          title: '1라인 페이테이블',
          note: '가운데 한 줄만 판정합니다. 릴은 자동으로 멈춥니다.',
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          selected: true,
          label: '3릴 스핀 선택됨',
          child: Material(
            key: const Key('casino-bet-slotsSpin'),
            color: const Color(0xFF261B18),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _busy ? null : () => _chooseBet(CasinoBetType.slotsSpin),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _casinoGold.withValues(alpha: 0.7)),
                ),
                child: Column(
                  children: [
                    for (
                      var rowStart = 0;
                      rowStart < rows.length;
                      rowStart += 2
                    ) ...[
                      if (rowStart > 0) const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: payCell(rowStart)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: rowStart + 1 < rows.length
                                ? payCell(rowStart + 1)
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegacyBetOptions(CasinoGameType game) {
    final options = switch (game) {
      CasinoGameType.baccarat => const <CasinoBetType>[
        CasinoBetType.baccaratPlayer,
        CasinoBetType.baccaratBanker,
        CasinoBetType.baccaratTie,
        CasinoBetType.baccaratPlayerPair,
        CasinoBetType.baccaratBankerPair,
      ],
      CasinoGameType.roulette => const <CasinoBetType>[
        CasinoBetType.rouletteRed,
        CasinoBetType.rouletteBlack,
        CasinoBetType.rouletteOdd,
        CasinoBetType.rouletteEven,
        CasinoBetType.rouletteLow,
        CasinoBetType.rouletteHigh,
        CasinoBetType.rouletteDozen1,
        CasinoBetType.rouletteDozen2,
        CasinoBetType.rouletteDozen3,
        CasinoBetType.rouletteColumn1,
        CasinoBetType.rouletteColumn2,
        CasinoBetType.rouletteColumn3,
        CasinoBetType.rouletteStraight,
      ],
      CasinoGameType.craps => const <CasinoBetType>[
        CasinoBetType.crapsPassLine,
        CasinoBetType.crapsDontPass,
      ],
      CasinoGameType.sicBo => const <CasinoBetType>[
        CasinoBetType.sicBoBig,
        CasinoBetType.sicBoSmall,
        CasinoBetType.sicBoOdd,
        CasinoBetType.sicBoEven,
        CasinoBetType.sicBoAnyTriple,
        CasinoBetType.sicBoSpecificTriple,
        CasinoBetType.sicBoTotal,
      ],
      CasinoGameType.slots => const <CasinoBetType>[CasinoBetType.slotsSpin],
      CasinoGameType.blackjack => const <CasinoBetType>[],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CasinoSectionLabel('베팅 선택'),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options
              .map(
                (type) => ChoiceChip(
                  key: Key('casino-bet-${type.name}'),
                  label: Text(casinoBetTitle(type, selection: _selection)),
                  selected: _selectedBet == type,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() {
                          _selectedBet = type;
                          if (type == CasinoBetType.sicBoSpecificTriple) {
                            _selection = 1;
                          } else if (type == CasinoBetType.sicBoTotal) {
                            _selection = 10;
                          } else if (type == CasinoBetType.rouletteStraight) {
                            _selection = 0;
                          }
                        }),
                  selectedColor: _casinoGold,
                  backgroundColor: const Color(0xFF322822),
                  labelStyle: TextStyle(
                    color: _selectedBet == type
                        ? const Color(0xFF1A110D)
                        : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                  side: BorderSide(
                    color: _selectedBet == type
                        ? _casinoGold
                        : const Color(0xFF66564A),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        if (_selectedBet == CasinoBetType.rouletteStraight) ...[
          const SizedBox(height: 9),
          _buildNumberGrid(List<int>.generate(37, (index) => index)),
        ],
        if (_selectedBet == CasinoBetType.sicBoSpecificTriple) ...[
          const SizedBox(height: 9),
          _buildNumberGrid(List<int>.generate(6, (index) => index + 1)),
        ],
        if (_selectedBet == CasinoBetType.sicBoTotal) ...[
          const SizedBox(height: 9),
          _buildNumberGrid(List<int>.generate(14, (index) => index + 4)),
        ],
      ],
    );
  }

  Widget _buildNumberGrid(List<int> values) => Wrap(
    spacing: 5,
    runSpacing: 5,
    children: values
        .map(
          (value) => SizedBox(
            width: 39,
            height: 38,
            child: OutlinedButton(
              key: Key('casino-number-$value'),
              onPressed: _busy
                  ? null
                  : () => setState(() => _selection = value),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: _selection == value
                    ? _casinoWine
                    : const Color(0xFF241C19),
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: _selection == value
                      ? _casinoGold
                      : const Color(0xFF5C4A40),
                ),
              ),
              child: Text('$value', style: const TextStyle(fontSize: 10)),
            ),
          ),
        )
        .toList(growable: false),
  );

  Widget _buildStakeSelector() {
    final stakes = casinoStakePercents
        .map(
          (percent) => MapEntry(
            percent,
            casinoStakeForChipPercent(_availableChips, percent),
          ),
        )
        .where((option) => option.value >= casinoMinimumStake)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _CasinoSectionLabel('CHIP RACK · 칩 선택')),
            Text(
              '보유 칩 기준 최대 ${_money(_maxStake)}원',
              style: const TextStyle(color: Color(0xFFAFA198), fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 5),
        if (stakes.isEmpty)
          const Text(
            '베팅 가능한 칩이 부족해. 칩 교환소에서 더 충전해 줘.',
            style: TextStyle(color: Color(0xFFF0B47C), fontSize: 11),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 7,
            children: stakes
                .map((option) {
                  final percent = option.key;
                  final value = option.value;
                  final selected = _stake == value;
                  final enabled = !_busy && _stakeIsPlayable(value);
                  final chipColor = value >= 100000
                      ? const Color(0xFF202022)
                      : value >= 50000
                      ? const Color(0xFF8C2032)
                      : value >= 20000
                      ? const Color(0xFF245B91)
                      : const Color(0xFFE6DDCA);
                  final foreground = value >= 20000
                      ? Colors.white
                      : const Color(0xFF31251F);
                  return Semantics(
                    button: true,
                    selected: selected,
                    enabled: enabled,
                    label: '보유 칩의 $percent%, ${_money(value)}원',
                    child: Opacity(
                      opacity: enabled ? 1 : 0.38,
                      child: SizedBox(
                        width: 66,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              key: Key('casino-stake-$value'),
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: enabled
                                    ? () {
                                        unawaited(
                                          HapticFeedback.selectionClick(),
                                        );
                                        setState(() => _stake = value);
                                      }
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 50,
                                  height: 50,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected
                                        ? _casinoGold
                                        : const Color(0xFF241C19),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFFFFDEA0)
                                          : Colors.white24,
                                      width: selected ? 2 : 1,
                                    ),
                                    boxShadow: selected
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x55D8AE62),
                                              blurRadius: 12,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: chipColor,
                                      border: Border.all(
                                        color: foreground.withValues(
                                          alpha: 0.75,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$percent%',
                                      style: TextStyle(
                                        color: foreground,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_money(value)}원',
                              maxLines: 1,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFFFFD98C)
                                    : const Color(0xFFD1C4BA),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
      ],
    );
  }

  Widget _buildPlayButton(CasinoGameType game) {
    final crapsRound = game == CasinoGameType.craps
        ? _casino.activeCraps
        : null;
    final continuingCraps = crapsRound != null;
    if (_maxStake < casinoMinimumStake && !continuingCraps) {
      return _buildLegacyPlayButton(game);
    }
    final enabled = !_busy && (continuingCraps || _canStartRound);
    final opensChipPrompt = !_busy && !continuingCraps && _isOutOfChips;
    final action = continuingCraps
        ? 'ROLL DICE · POINT ${crapsRound.point}'
        : game == CasinoGameType.slots
        ? 'SPIN'
        : game == CasinoGameType.craps
        ? 'COME-OUT ROLL'
        : 'PLACE BET';
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                colors: game == CasinoGameType.slots
                    ? const [Color(0xFF8D263D), Color(0xFF4D1022)]
                    : const [Color(0xFFD7AE62), Color(0xFF8D642C)],
              )
            : const LinearGradient(
                colors: [Color(0xFF473B35), Color(0xFF302824)],
              ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color(0x445C3614),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: FilledButton(
        key: const Key('casino-play-round'),
        onPressed: enabled
            ? _playSelected
            : opensChipPrompt
            ? _showOutOfChipsPrompt
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: game == CasinoGameType.slots
              ? Colors.white
              : const Color(0xFF1C120D),
          disabledForegroundColor: const Color(0xFFB7AAA0),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    game == CasinoGameType.slots || game == CasinoGameType.craps
                        ? Icons.casino_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      continuingCraps
                          ? action
                          : _canStartRound
                          ? '$action · ${_money(_stake)}원'
                          : _shortLockReason(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLegacyPlayButton(CasinoGameType game) => SizedBox(
    width: double.infinity,
    height: 48,
    child: FilledButton.icon(
      key: const Key('casino-play-round'),
      onPressed: _busy
          ? null
          : _canStartRound
          ? _playSelected
          : _isOutOfChips
          ? _showOutOfChipsPrompt
          : null,
      style: FilledButton.styleFrom(
        backgroundColor: _casinoWine,
        disabledBackgroundColor: const Color(0xFF473B35),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: _busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              game == CasinoGameType.slots ? Icons.casino : Icons.play_arrow,
            ),
      label: Text(
        _canStartRound ? '${_money(_stake)}원 베팅 · 1판 시작' : _shortLockReason(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );

  Widget _buildBlackjackTable() {
    final hand = _casino.activeBlackjack;
    if (hand == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CasinoBoardHeader(
            eyebrow: 'BLACKJACK · DEALER STANDS S17',
            title: '칩을 놓고 첫 패를 받으세요',
            note: '블랙잭 3:2 · 일반 승리 1:1 · 동점은 원금 반환',
          ),
          const SizedBox(height: 7),
          const Row(
            children: [
              Expanded(
                child: _BlackjackRuleTile(value: '21', label: '목표 합계'),
              ),
              SizedBox(width: 5),
              Expanded(
                child: _BlackjackRuleTile(value: '3:2', label: '블랙잭'),
              ),
              SizedBox(width: 5),
              Expanded(
                child: _BlackjackRuleTile(value: 'S17', label: '딜러 규칙'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStakeSelector(),
        ],
      );
    }
    final playerValue = blackjackHandValue(hand.playerCards).total;
    final dealerUpValue = blackjackHandValue(<int>[
      hand.dealerCards.first,
    ]).total;
    final mustSettle = playerValue >= 21;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CasinoBoardHeader(
          eyebrow: 'LIVE HAND · ${_money(hand.stake)}원',
          title: mustSettle ? '판정을 기다립니다' : '히트 또는 스탠드를 선택하세요',
          note: hand.doubled
              ? '더블다운 적용 · 추가 카드를 받은 뒤 자동 스탠드'
              : '더블다운은 첫 두 장에서만 선택할 수 있습니다.',
        ),
        const SizedBox(height: 11),
        const _CasinoSectionLabel('딜러'),
        const SizedBox(height: 6),
        Row(
          children: [
            _CasinoPlayingCard(card: hand.dealerCards.first),
            const SizedBox(width: 7),
            const _CasinoPlayingCard(hidden: true),
            const SizedBox(width: 9),
            Text(
              '보이는 합 $dealerUpValue',
              style: const TextStyle(color: Color(0xFFCDBDAE), fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(child: _CasinoSectionLabel('플레이어')),
            Text(
              '합계 $playerValue${hand.doubled ? ' · 더블' : ''}',
              style: TextStyle(
                color: playerValue > 21 ? const Color(0xFFFF8B85) : _casinoGold,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: hand.playerCards
              .map((card) => _CasinoPlayingCard(card: card))
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildBlackjackActionBar() {
    final hand = _casino.activeBlackjack;
    if (hand == null) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          key: const Key('casino-blackjack-deal'),
          onPressed: _busy
              ? null
              : _canStartRound
              ? () => _apply(
                  widget.onStartBlackjack(_stake),
                  motion: _CasinoTableMotion.deal,
                )
              : _isOutOfChips
              ? _showOutOfChipsPrompt
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB78B46),
            foregroundColor: const Color(0xFF1A110D),
            disabledBackgroundColor: const Color(0xFF473B35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          icon: const Icon(Icons.style_rounded),
          label: Text(
            _canStartRound ? '${_money(_stake)}원 · 카드 받기' : _shortLockReason(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      );
    }
    final mustSettle = blackjackHandValue(hand.playerCards).total >= 21;
    return Row(
      children: [
        Expanded(
          child: _CasinoActionButton(
            key: const Key('casino-blackjack-hit'),
            label: '히트',
            onPressed: _busy || mustSettle
                ? null
                : () => _apply(
                    widget.onBlackjackAction(BlackjackAction.hit),
                    motion: _CasinoTableMotion.deal,
                  ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _CasinoActionButton(
            key: const Key('casino-blackjack-stand'),
            label: mustSettle ? '결과 확인' : '스탠드',
            primary: true,
            onPressed: _busy
                ? null
                : () => _apply(
                    widget.onBlackjackAction(BlackjackAction.stand),
                    motion: _CasinoTableMotion.reveal,
                  ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _CasinoActionButton(
            key: const Key('casino-blackjack-double'),
            label: '더블',
            onPressed:
                _busy ||
                    hand.playerCards.length != 2 ||
                    hand.doubled ||
                    hand.stake > _availableChips
                ? null
                : () => _apply(
                    widget.onBlackjackAction(BlackjackAction.doubleDown),
                    motion: _CasinoTableMotion.deal,
                  ),
          ),
        ),
      ],
    );
  }

  void _returnToTableList() {
    if (!_canGoOffline) return;
    GameAudio.instance.playSfx(GameSfx.select);
    setState(() {
      _selectedGame = null;
      _dealerReaction = null;
    });
    _resetScrollAfterBuild();
  }

  Widget _buildGameNavigationRow() => Row(
    children: [
      Expanded(
        key: const Key('casino-other-games'),
        child: SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            key: _selectedGame == CasinoGameType.blackjack
                ? const Key('casino-blackjack-other-games')
                : const Key('casino-change-game'),
            onPressed: _canGoOffline ? _returnToTableList : null,
            icon: const Icon(Icons.grid_view_rounded, size: 15),
            label: const Text(
              '다른 게임 하러가기',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              foregroundColor: _casinoGold,
              disabledForegroundColor: const Color(0xFF8F8177),
              side: BorderSide(
                color: _canGoOffline
                    ? _casinoGold.withValues(alpha: 0.75)
                    : const Color(0xFF5A4A42),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(child: _buildOfflineButton(compact: true)),
    ],
  );

  Widget _buildOfflineButton({bool compact = false}) => SizedBox(
    width: double.infinity,
    height: compact ? 44 : 48,
    child: FilledButton.icon(
      key: const Key('casino-go-offline'),
      onPressed: _canGoOffline ? () => unawaited(_exitCasino()) : null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        foregroundColor: Colors.white,
        backgroundColor: _casinoWine,
        disabledBackgroundColor: const Color(0xFF342A26),
        disabledForegroundColor: const Color(0xFF8F8177),
        side: const BorderSide(color: _casinoGold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.power_settings_new_rounded, size: 15),
      label: const Text(
        '접속 종료',
        maxLines: 1,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    ),
  );

  Widget _buildBudgetMeter({bool panel = false}) {
    final used = _casino.monthKey == casinoMonthKey(_state.currentDate)
        ? _casino.monthlyLoss
        : 0;
    final progress = _lossLimit <= 0
        ? 0.0
        : (used / _lossLimit).clamp(0.0, 1.0);
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _CasinoSectionLabel('이번 달 손실 중단선')),
            Text(
              '${_money(used)} / ${_money(_lossLimit)}원',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: const Color(0xFF40362F),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 0.8 ? const Color(0xFFDD786D) : _casinoGold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '칩 ${_money(_availableChips)}원 · 국가계좌 ${_money(_state.availableBrokerageCash)}원 · 오늘 ${_casino.roundsForDay(_state.day)}/$casinoDailyRoundLimit판\n'
          '누적 ${_casino.totalRounds}판 · 순손익 ${_signedMoney(_casino.lifetimeNet)}원 · 수수료 ${_money(_casino.totalNationalFee)}원',
          style: const TextStyle(
            color: Color(0xFFB5A79D),
            fontSize: 9,
            height: 1.35,
          ),
        ),
      ],
    );
    return panel
        ? _CasinoPanel(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            child: child,
          )
        : child;
  }

  Widget _buildHistory({CasinoGameType? game}) {
    final records = _casino.history.reversed
        .where((record) => game == null || record.game == game)
        .take(3)
        .toList(growable: false);
    return _CasinoPanel(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _CasinoSectionLabel('최근 게임 원장')),
              Text(
                '결과 시드 고정',
                style: TextStyle(
                  color: _casinoGold.withValues(alpha: 0.9),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (records.isEmpty)
            const Text(
              '아직 정산된 게임이 없습니다.',
              style: TextStyle(color: Color(0xFFBBAFA7), fontSize: 10),
            )
          else
            for (var index = 0; index < records.length; index++) ...[
              if (index > 0)
                const Divider(height: 15, color: Color(0xFF463A34)),
              _CasinoHistoryRow(record: records[index]),
            ],
        ],
      ),
    );
  }

  String _shortLockReason() {
    if (!_nationalNetworkUnlocked) return '한서윤 운영관 안내 필요';
    if (_state.pendingDecisions.isNotEmpty) return '새 기록 먼저 확인';
    if (_state.currentDate.weekday >= DateTime.saturday) return '평일 저녁만 이용';
    if (_casino.activeBlackjack != null) return '블랙잭 핸드 진행 중';
    if (_casino.activeCraps != null) {
      return '크랩스 포인트 ${_casino.activeCraps!.point} 진행 중';
    }
    if (weekdayEveningUsed(_state)) return '오늘 저녁 행동 사용';
    if (_state.marketMinute < krxCloseMinute) return '15:00부터 접속';
    if (_state.marketMinute > marketDayEndMinute - casinoRoundMinutes) {
      return '오늘 영업 종료';
    }
    if (_casino.roundsForDay(_state.day) >= casinoDailyRoundLimit) {
      return '오늘 판수 한도';
    }
    if (_availableChips < casinoMinimumStake) return '칩이 떨어졌어 · 눌러서 충전';
    if (_maxStake < casinoMinimumStake) return '베팅 한도 부족';
    if (_casino.monthlyLoss + _stake > _lossLimit) return '월 손실 중단선';
    return '현재 이용 불가';
  }

  String _gameRuleLine(CasinoGameType game) => switch (game) {
    CasinoGameType.baccarat =>
      '표준 3장 규칙 · 플레이어 1:1 · 뱅커 0.95:1 · 타이 8:1 · 페어 11:1',
    CasinoGameType.blackjack => '싱글 핸드 · 딜러 S17 · 블랙잭 3:2 · 더블 가능 · 스플릿·보험 없음',
    CasinoGameType.roulette => '유럽식 싱글 제로 · 단순찬스 1:1 · 더즌·열 2:1 · 스트레이트 35:1',
    CasinoGameType.craps => '컴아웃 7·11 / 2·3·12 · 포인트 4·5·6·8·9·10 · 패스·돈트 패스',
    CasinoGameType.sicBo => '주사위 3개 · 대·소·홀짝은 트리플 제외 · 트리플과 합계별 공개 배당',
    CasinoGameType.slots => '동일 확률 6심벌 3릴 · 트리플·체리 2개 지급 · 이론 지급률 97.2%',
  };

  String _signedMoney(int value) =>
      '${value >= 0 ? '+' : '-'}${_money(value.abs())}';

  Future<void> _showRules() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF201816),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SizedBox(
                width: 42,
                child: Divider(thickness: 4, color: Color(0xFF6C5B51)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '테이블 규칙 · 책임 이용',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('casino-rules-close'),
                  tooltip: '규칙 닫기',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: _casinoGold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• 2000년 국가계좌 실습을 마친 뒤부터, 평일 주식장 마감 후 PC의 국가 전용망에서만 접속합니다.\n'
              '• 딜러 이안이 온라인 칩 교환·테이블 안내와 각 게임 진행을 맡습니다. 한 판이 끝날 때마다 30분이 흐릅니다.\n'
              '• 현장 이동·외부 결제·인앱 결제는 없고, 15:00~19:30에 새 게임을 시작할 수 있습니다.\n'
              '• 바카라·블랙잭·룰렛·크랩스·다이사이·3릴을 자유롭게 바꿀 수 있으며, 정산된 한 판마다 30분을 사용해 하루 최대 10판입니다. 10판을 채울 필요는 없으며 1판 후에도 나갈 수 있습니다.\n'
              '• 접속을 끝내면 현재 시각을 유지한 채 PC 메인으로 돌아갑니다.\n'
              '• 테이블에서는 국가계좌 주문 가능금을 미리 교환한 칩만 사용합니다. 종료할 때 국가계좌 환전 또는 칩 보관을 선택하며, 보관한 칩은 다음 접속에도 유지됩니다.\n'
              '• 실제 베팅은 현금이 아니라 보유 칩에서만 빠지며, 보유 칩의 2%·5%·10%·30% 중 하나를 500원 단위로 내려 선택합니다.\n'
              '• 월 손실 중단선은 월 첫 접속 국가계좌+칩의 2%, 최소 5만원·최대 100만원입니다.\n'
              '• 확정 이익의 20%를 국가 수수료로 냅니다. 반환 원금과 푸시에는 부과하지 않으며 총지급·수수료·실수령을 원장에 따로 기록합니다.\n'
              '• 게임 결과는 월드시드·날짜·판 번호로 고정되며 베팅 종류나 금액으로 다시 뽑히지 않습니다.\n'
              '• 실제 돈·광고·인앱 결제·현금화는 없습니다. 카지노는 자산 성장의 안정적인 수단이 아닙니다.',
              style: TextStyle(
                color: Color(0xFFD2C6BE),
                fontSize: 11,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 18),
            const Divider(color: Color(0xFF5E4B40)),
            const SizedBox(height: 12),
            const Text(
              '게임별 핵심 규칙',
              style: TextStyle(
                color: _casinoGold,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '바카라\n'
              '플레이어와 뱅커 중 9에 가까운 쪽이 승리합니다. 자동 3장 규칙을 적용하며 뱅커 승리 배당은 0.95:1, 타이는 8:1입니다.\n\n'
              '블랙잭\n'
              '21을 넘기지 않고 딜러보다 높은 합을 만듭니다. 딜러는 17에 스탠드하며 내추럴 블랙잭은 3:2입니다. 히트·스탠드·더블을 직접 선택합니다.\n\n'
              '유럽식 룰렛\n'
              '0이 하나인 휠을 사용합니다. 레드·블랙과 홀·짝은 1:1, 더즌·열은 2:1, 번호 하나는 35:1입니다.\n\n'
              '크랩스\n'
              '컴아웃에서 패스 라인은 7·11 승리, 2·3·12 패배이고 돈트 패스는 2·3 승리, 7·11 패배, 12 푸시입니다. 4·5·6·8·9·10은 포인트가 되며, 패스는 포인트가 7보다 먼저 나오면 승리하고 돈트 패스는 그 반대입니다. 현재는 두 라인 베팅만 지원합니다. 포인트 중간 롤은 추가 시간을 쓰지 않고 계약 정산 시 한 판 30분을 반영합니다.\n\n'
              '다이사이\n'
              '주사위 3개의 합과 조합에 베팅합니다. 대·소·홀·짝은 트리플이 나오면 적중하지 않습니다.\n\n'
              '클래식 3릴\n'
              '3개 릴의 심벌을 맞추며, 같은 심벌 3개와 체리 2개에 배당이 있습니다. 공개 이론 지급률은 97.2%입니다.',
              style: TextStyle(
                color: Color(0xFFE0D4CB),
                fontSize: 11,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(backgroundColor: _casinoWine),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CrapsPointCell extends StatelessWidget {
  const _CrapsPointCell({required this.point});

  final int point;

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    decoration: BoxDecoration(
      color: const Color(0x44110C0A),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0x88E4CD9A)),
    ),
    child: Center(
      child: Text(
        '$point',
        style: const TextStyle(
          color: Color(0xFFF1DFC0),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _CasinoSlotLever extends StatelessWidget {
  const _CasinoSlotLever({
    required this.stake,
    required this.pulling,
    required this.enabled,
    required this.lockReason,
    required this.onPull,
    this.onLockedTap,
  });

  final int stake;
  final bool pulling;
  final bool enabled;
  final String lockReason;
  final VoidCallback onPull;
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled || onLockedTap != null,
    label: enabled
        ? '슬롯 레버 당기기 · ${_money(stake)}원'
        : onLockedTap != null
        ? '칩이 떨어졌어 · 칩 충전 선택 열기'
        : '슬롯 레버 잠김 · $lockReason',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('casino-slot-pull'),
        onTap: enabled ? onPull : onLockedTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 48,
          height: 108,
          decoration: BoxDecoration(
            color: const Color(0xD91A100E),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFE0B766)
                  : const Color(0xFF65574F),
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x99000000), blurRadius: 9),
            ],
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 25,
                child: Container(
                  width: 7,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8AE62),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOutBack,
                top: pulling ? 46 : 7,
                child: Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: enabled
                          ? const [Color(0xFFFF6274), Color(0xFF7B1029)]
                          : const [Color(0xFF6C6060), Color(0xFF302828)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFD98C),
                      width: 1.4,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0xAA000000), blurRadius: 7),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                child: Text(
                  enabled
                      ? '당기기'
                      : onLockedTap != null
                      ? '칩 충전'
                      : '잠김',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
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

class _CasinoPanel extends StatelessWidget {
  const _CasinoPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: const Color(0xEF191311),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _casinoGold.withValues(alpha: 0.42)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x77000000),
          blurRadius: 18,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: child,
  );
}

class _CasinoBoardHeader extends StatelessWidget {
  const _CasinoBoardHeader({
    required this.eyebrow,
    required this.title,
    required this.note,
  });

  final String eyebrow;
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(9, 6, 9, 7),
    decoration: BoxDecoration(
      color: const Color(0xFF241C19),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF54443A)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 31,
          decoration: BoxDecoration(
            color: _casinoGold,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: _casinoGold,
                  fontSize: 6.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFB9AAA0),
                  fontSize: 7.2,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CasinoSectionLabel extends StatelessWidget {
  const _CasinoSectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFFE2BC75),
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.2,
    ),
  );
}

class _BlackjackRuleTile extends StatelessWidget {
  const _BlackjackRuleTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    decoration: BoxDecoration(
      color: const Color(0xFF153D32),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF4D7364)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _casinoGold,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFC9BDB4), fontSize: 7),
        ),
      ],
    ),
  );
}

class _CasinoPlayingCard extends StatelessWidget {
  const _CasinoPlayingCard({this.card, this.hidden = false});
  final int? card;
  final bool hidden;

  @override
  Widget build(BuildContext context) => _PremiumCasinoCard(
    label: hidden ? null : casinoCardLabel(card!),
    hidden: hidden,
    width: 48,
    height: 66,
  );
}

class _CasinoActionButton extends StatelessWidget {
  const _CasinoActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final english = switch (label) {
      '히트' => 'HIT',
      '더블' => 'DOUBLE',
      '스탠드' => 'STAND',
      _ => 'SETTLE',
    };
    final actionIndex = switch (label) {
      '히트' => 0,
      '더블' => 2,
      _ => 1,
    };
    return SizedBox(
      height: 60,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          backgroundColor: primary ? _casinoWine : const Color(0xFF3B302B),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF2C2522),
          disabledForegroundColor: const Color(0xFF756A64),
          side: BorderSide(
            color: primary ? _casinoGold : const Color(0xFF615047),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: onPressed == null ? 0.38 : 1,
              child: _BlackjackActionIcon(
                key: Key('casino-blackjack-action-art-$actionIndex'),
                actionIndex: actionIndex,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
            Text(
              english,
              style: const TextStyle(fontSize: 5.5, letterSpacing: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlackjackActionIcon extends StatelessWidget {
  const _BlackjackActionIcon({super.key, required this.actionIndex});

  static const _asset = 'assets/images/casino/blackjack_action_atlas_v1.png';
  static const double _dimension = 31;

  final int actionIndex;

  @override
  Widget build(BuildContext context) {
    final safeIndex = actionIndex.clamp(0, 2).toInt();
    return SizedBox.square(
      dimension: _dimension,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: -safeIndex * _dimension,
              top: -_dimension / 2,
              width: _dimension * 3,
              height: _dimension * 2,
              child: Image.asset(
                _asset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouletteBetIcon extends StatelessWidget {
  const _RouletteBetIcon({required this.iconIndex});

  static const _asset = 'assets/images/casino/roulette_bet_icon_atlas_v1.png';
  static const double _dimension = 29;

  final int iconIndex;

  @override
  Widget build(BuildContext context) {
    final safeIndex = iconIndex.clamp(0, 5).toInt();
    final column = safeIndex % 3;
    final row = safeIndex ~/ 3;
    return SizedBox.square(
      key: Key('casino-roulette-bet-art-$safeIndex'),
      dimension: _dimension,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: -column * _dimension,
              top: -row * _dimension,
              width: _dimension * 3,
              height: _dimension * 2,
              child: Image.asset(
                _asset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CasinoHistoryRow extends StatelessWidget {
  const _CasinoHistoryRow({required this.record});
  final CasinoRoundRecord record;

  @override
  Widget build(BuildContext context) {
    final positive = record.net >= 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: positive ? const Color(0xFF133E31) : const Color(0xFF4A2025),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            positive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: positive ? const Color(0xFF75D0AD) : const Color(0xFFFF918C),
            size: 18,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${casinoGameTitle(record.game)} · ${record.betLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${record.outcome} · 베팅 ${_money(record.stake)}원',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFB9ACA3), fontSize: 9),
              ),
              if (record.grossPayout > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '총지급 ${_money(record.grossPayout)}원 · 국가 수수료 ${_money(record.nationalFee)}원 · 실수령 ${_money(record.payout)}원',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD8BE8A),
                    fontSize: 8,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${record.net >= 0 ? '+' : '-'}${_money(record.net.abs())}',
          style: TextStyle(
            color: positive ? const Color(0xFF75D0AD) : const Color(0xFFFF918C),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
