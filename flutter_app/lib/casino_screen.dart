part of 'main.dart';

const _casinoGold = Color(0xFFD8AE62);
const _casinoWine = Color(0xFF6A192B);
const _casinoGreen = Color(0xFF0D4938);
const _casinoInk = Color(0xFF170F0D);

class CasinoScreen extends StatefulWidget {
  const CasinoScreen({
    super.key,
    required this.state,
    required this.onPlayRound,
    required this.onStartBlackjack,
    required this.onBlackjackAction,
    required this.onCrapsRoll,
    this.testMode = false,
  });

  final GameState state;
  final Future<CasinoActionResult> Function(CasinoBet bet) onPlayRound;
  final Future<CasinoActionResult> Function(int stake) onStartBlackjack;
  final Future<CasinoActionResult> Function(BlackjackAction action)
  onBlackjackAction;
  final Future<CasinoActionResult> Function() onCrapsRoll;
  final bool testMode;

  @override
  State<CasinoScreen> createState() => _CasinoScreenState();
}

class _CasinoScreenState extends State<CasinoScreen> {
  late GameState _state = widget.state;
  CasinoGameType? _selectedGame;
  CasinoBetType _selectedBet = CasinoBetType.baccaratPlayer;
  int _selection = 0;
  int _stake = casinoMinimumStake;
  bool _busy = false;
  String _status = '테이블을 선택하세요.';
  _CasinoTableMotion _tableMotion = _CasinoTableMotion.idle;
  int _tableMotionToken = 0;

  CasinoState get _casino => _state.personalFinance.casino;

  String get _backgroundAsset => switch (_selectedGame) {
    CasinoGameType.baccarat =>
      'assets/images/casino/bg_decimal_casino_baccarat_2010_v1.png',
    CasinoGameType.roulette =>
      'assets/images/casino/bg_decimal_casino_roulette_2010_v1.png',
    CasinoGameType.blackjack || CasinoGameType.craps || CasinoGameType.sicBo =>
      'assets/images/casino/bg_decimal_casino_table_games_2010_v1.png',
    CasinoGameType.slots ||
    null => 'assets/images/casino/bg_decimal_casino_lobby_2010_v1.png',
  };

  int get _monthBasis => _casino.monthKey == casinoMonthKey(_state.currentDate)
      ? _casino.monthBankrollBasis
      : _state.bankCash;

  int get _lossLimit => casinoMonthlyLossLimitForBasis(_monthBasis);
  int get _maxStake {
    if (!widget.testMode) return casinoMaximumStakeForCash(_state.bankCash);
    final remainingLoss = math.max(0, _lossLimit - _casino.monthlyLoss);
    final available = math.min(
      _state.bankCash,
      math.min(casinoMaximumStake, remainingLoss),
    );
    return (available ~/ casinoMinimumStake) * casinoMinimumStake;
  }

  bool get _adultUnlocked =>
      !_state.currentDate.isBefore(DateTime(2010, 1, 1)) &&
      _state.story.ageOn(_state.currentDate) >= 20;

  bool get _roundTimeAvailable =>
      _state.currentDate.weekday < DateTime.saturday &&
      _state.marketMinute >= krxCloseMinute &&
      _state.marketMinute <= marketDayEndMinute - casinoRoundMinutes &&
      !weekdayEveningUsed(_state);

  bool get _canStartRound =>
      _adultUnlocked &&
      _roundTimeAvailable &&
      _state.pendingDecisions.isEmpty &&
      _casino.activeBlackjack == null &&
      _casino.activeCraps == null &&
      _casino.roundsForDay(_state.day) < casinoDailyRoundLimit &&
      _maxStake >= casinoMinimumStake &&
      _casino.monthlyLoss + _stake <= _lossLimit;

  bool get _canFinishEvening =>
      !_busy &&
      _casino.activeBlackjack == null &&
      _casino.activeCraps == null &&
      _casino.roundsForDay(_state.day) > 0;

  void _selectGame(CasinoGameType game) {
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
      _status = '${casinoGameTitle(game)} 테이블입니다.';
    });
  }

  Future<void> _apply(
    Future<CasinoActionResult> future, {
    _CasinoTableMotion motion = _CasinoTableMotion.reveal,
  }) async {
    if (_busy) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _busy = true;
      _tableMotion = motion;
      _tableMotionToken++;
      _status = _casinoTableMotionLabel(motion);
    });
    unawaited(HapticFeedback.mediumImpact());
    try {
      final result = await future;
      if (!mounted) return;
      if (result.success && !reduceMotion) {
        await Future<void>.delayed(_casinoTableMotionDuration(motion));
        if (!mounted) return;
      }
      setState(() {
        if (result.success) _state = result.state;
        _status = result.message;
        _tableMotion = _CasinoTableMotion.idle;
        final maxStake = _maxStake;
        if (maxStake >= casinoMinimumStake && _stake > maxStake) {
          _stake = maxStake;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _playSelected() async {
    final game = _selectedGame;
    if (game == null || game == CasinoGameType.blackjack) return;
    if (game == CasinoGameType.craps && _casino.activeCraps != null) {
      await _apply(widget.onCrapsRoll(), motion: _CasinoTableMotion.crapsDice);
      return;
    }
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
    canPop: _casino.activeBlackjack == null && _casino.activeCraps == null,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && mounted) {
        setState(() {
          final blackjack = _casino.activeBlackjack != null;
          _selectedGame = blackjack
              ? CasinoGameType.blackjack
              : CasinoGameType.craps;
          _status = blackjack
              ? '진행 중인 블랙잭 핸드를 먼저 정산해야 카지노를 나갈 수 있습니다.'
              : '포인트가 설정된 크랩스 라운드를 먼저 정산해야 나갈 수 있습니다.';
        });
      }
    },
    child: Scaffold(
      key: const Key('casino-screen'),
      backgroundColor: _casinoInk,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: Image.asset(
                _backgroundAsset,
                key: ValueKey(_backgroundAsset),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x18000000),
                    Color(0x66000000),
                    Color(0xFA120C0B),
                  ],
                  stops: [0, 0.28, 0.66],
                ),
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                key: const Key('casino-scroll'),
                padding: const EdgeInsets.fromLTRB(12, 94, 12, 28),
                child: _selectedGame == null ? _buildLobby() : _buildGame(),
              ),
            ),
            Positioned(left: 8, right: 8, top: 6, child: _buildHeader()),
          ],
        ),
      ),
    ),
  );

  Widget _buildHeader() {
    final clock = marketTimeLabel(_state.marketMinute);
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xE8120D0C),
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
            onPressed: () {
              if (_casino.activeBlackjack != null ||
                  _casino.activeCraps != null) {
                setState(() {
                  final blackjack = _casino.activeBlackjack != null;
                  _selectedGame = blackjack
                      ? CasinoGameType.blackjack
                      : CasinoGameType.craps;
                  _status = blackjack
                      ? '진행 중인 블랙잭 핸드를 먼저 정산해야 카지노를 나갈 수 있습니다.'
                      : '포인트가 설정된 크랩스 라운드를 먼저 정산해야 나갈 수 있습니다.';
                });
              } else if (_selectedGame != null) {
                setState(() => _selectedGame = null);
              } else {
                Navigator.of(context).pop();
              }
            },
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
                            ? '데시멀 카지노 LIVE · TEST'
                            : '데시멀 카지노 LIVE'
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
                  '$clock · ${widget.testMode ? '테스트머니' : '현금'} ${_money(_state.bankCash)}원',
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

  Widget _buildLobby() => Column(
    children: [
      const SizedBox(height: 118),
      _CasinoPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '요원 전용 실시간 중계',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _CasinoBadge(
                  label: widget.testMode
                      ? 'TEST MONEY'
                      : _adultUnlocked
                      ? '성인 인증'
                      : '2010년 해금',
                  color: widget.testMode
                      ? _casinoGold
                      : _adultUnlocked
                      ? const Color(0xFF5DC7A2)
                      : const Color(0xFFE2A66A),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              _entryStatusText(),
              style: const TextStyle(
                color: Color(0xFFD8CDC3),
                fontSize: 11,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            _buildBudgetMeter(),
          ],
        ),
      ),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.94,
        children: CasinoGameType.values
            .map((game) => _buildGameCard(game))
            .toList(growable: false),
      ),
      if (_canFinishEvening) ...[
        const SizedBox(height: 12),
        _buildFinishEveningButton(),
      ],
      const SizedBox(height: 12),
      _buildHistory(),
    ],
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
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('casino-game-${game.name}'),
        onTap: () => _selectGame(game),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            image: DecorationImage(
              image: AssetImage(asset),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
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
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _casinoGold.withValues(alpha: 0.72),
                    width: 1.1,
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 5,
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
                      Icon(icon, color: _casinoGold, size: 13),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Color(0xFFF3D69B),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 10,
                top: 12,
                child: Text(
                  'TABLE $tableNumber',
                  style: const TextStyle(
                    color: Color(0xFFE7CC96),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 10,
                bottom: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 2,
                      decoration: BoxDecoration(
                        color: _casinoGold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            casinoGameTitle(game),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
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
                          size: 17,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD7CCC2),
                        fontSize: 8.5,
                        height: 1.25,
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
        const SizedBox(height: 142),
        _CasinoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      casinoGameTitle(game),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _CasinoBadge(
                    label: '1판 $casinoRoundMinutes분',
                    color: _casinoGold,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CasinoLiveTableStage(
                game: game,
                motion: _tableMotion,
                motionToken: _tableMotionToken,
                stake:
                    game == CasinoGameType.blackjack &&
                        _casino.activeBlackjack != null
                    ? _casino.activeBlackjack!.stake
                    : game == CasinoGameType.craps &&
                          _casino.activeCraps != null
                    ? _casino.activeCraps!.stake
                    : _stake,
                betLabel: game == CasinoGameType.blackjack
                    ? '기본 핸드'
                    : game == CasinoGameType.craps &&
                          _casino.activeCraps != null
                    ? casinoBetTitle(_casino.activeCraps!.betType)
                    : casinoBetTitle(_selectedBet, selection: _selection),
                blackjackHand: _casino.activeBlackjack,
                crapsRound: _casino.activeCraps,
                latest: _latestRecordFor(game),
                reduceMotion: MediaQuery.disableAnimationsOf(context),
              ),
              const SizedBox(height: 6),
              Text(
                _gameRuleLine(game),
                style: const TextStyle(
                  color: Color(0xFFD6C9BE),
                  fontSize: 10,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              if (game == CasinoGameType.blackjack)
                _buildBlackjackTable()
              else ...[
                _buildBetOptions(game),
                if (game != CasinoGameType.craps ||
                    _casino.activeCraps == null) ...[
                  const SizedBox(height: 12),
                  _buildStakeSelector(),
                ],
                const SizedBox(height: 12),
                _buildPlayButton(game),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildStatusCard(),
        if (_canFinishEvening) ...[
          const SizedBox(height: 10),
          _buildFinishEveningButton(),
        ],
        const SizedBox(height: 10),
        _buildBudgetMeter(panel: true),
        const SizedBox(height: 10),
        _buildHistory(game: game),
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
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.all(8),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final point in pointNumbers) ...[
                      if (point != pointNumbers.first) const SizedBox(width: 4),
                      Expanded(child: _CrapsPointCell(point: point)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
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
        const SizedBox(height: 9),
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
      const SizedBox(height: 9),
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
      const SizedBox(height: 6),
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
          height: compact ? 62 : 76,
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
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 7 : 8,
                vertical: compact ? 6 : 8,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    english,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD7C7B8),
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payout,
                    style: TextStyle(
                      color: selected ? const Color(0xFFFFD98E) : _casinoGold,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
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
        const SizedBox(height: 9),
        Row(
          children: [
            for (final bet in const [
              (
                type: CasinoBetType.rouletteLow,
                label: '1–18',
                color: Color(0xFF234B3D),
              ),
              (
                type: CasinoBetType.rouletteEven,
                label: '짝수',
                color: Color(0xFF34302D),
              ),
              (
                type: CasinoBetType.rouletteRed,
                label: '레드',
                color: Color(0xFF8B2437),
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
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (final bet in const [
              (
                type: CasinoBetType.rouletteBlack,
                label: '블랙',
                color: Color(0xFF171719),
              ),
              (
                type: CasinoBetType.rouletteOdd,
                label: '홀수',
                color: Color(0xFF34302D),
              ),
              (
                type: CasinoBetType.rouletteHigh,
                label: '19–36',
                color: Color(0xFF234B3D),
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
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        trio(const [
          (type: CasinoBetType.rouletteDozen1, label: '첫째 12'),
          (type: CasinoBetType.rouletteDozen2, label: '둘째 12'),
          (type: CasinoBetType.rouletteDozen3, label: '셋째 12'),
        ]),
        const SizedBox(height: 5),
        trio(const [
          (type: CasinoBetType.rouletteColumn1, label: '1열'),
          (type: CasinoBetType.rouletteColumn2, label: '2열'),
          (type: CasinoBetType.rouletteColumn3, label: '3열'),
        ]),
        const SizedBox(height: 5),
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
              crossAxisCount: 3,
              childAspectRatio: 2.7,
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
      const SizedBox(height: 9),
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
      const SizedBox(height: 6),
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
      const SizedBox(height: 6),
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
      const SizedBox(height: 6),
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
      (symbol: '7  7  7', label: '럭키 세븐', payout: '95×'),
      (symbol: '♢ ♢ ♢', label: '벨', payout: '27×'),
      (symbol: 'B  B  B', label: 'BAR', payout: '18×'),
      (symbol: '★ ★ ★', label: '스타', payout: '12×'),
      (symbol: '● ● ●', label: '레몬', payout: '8×'),
      (symbol: '♥ ♥ ♥', label: '체리', payout: '5×'),
      (symbol: '♥ ♥ —', label: '체리 2개', payout: '3×'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CasinoBoardHeader(
          eyebrow: 'CLASSIC THREE REEL',
          title: '1라인 페이테이블',
          note: '가운데 한 줄만 판정합니다. 릴은 자동으로 멈춥니다.',
        ),
        const SizedBox(height: 9),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _casinoGold.withValues(alpha: 0.7)),
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < rows.length; index++) ...[
                      if (index > 0)
                        const Divider(height: 9, color: Color(0xFF493A32)),
                      Row(
                        children: [
                          SizedBox(
                            width: 67,
                            child: Text(
                              rows[index].symbol,
                              style: const TextStyle(
                                color: Color(0xFFFFE4A5),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              rows[index].label,
                              style: const TextStyle(
                                color: Color(0xFFD6CBC2),
                                fontSize: 9,
                              ),
                            ),
                          ),
                          Text(
                            rows[index].payout,
                            style: const TextStyle(
                              color: _casinoGold,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
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
    if (_maxStake < casinoMinimumStake) return _buildLegacyStakeSelector();
    final stakes = <int>{
      casinoMinimumStake,
      20000,
      50000,
      casinoMaximumStake,
      _maxStake,
    }.where((value) => value <= _maxStake).toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _CasinoSectionLabel('CHIP RACK · 칩 선택')),
            Text(
              '한도 ${_money(_maxStake)}원',
              style: const TextStyle(color: Color(0xFFAFA198), fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: stakes
              .map((value) {
                final selected = _stake == value;
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
                  label: '${_money(value)}원 칩',
                  child: Material(
                    key: Key('casino-stake-$value'),
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _busy
                          ? null
                          : () {
                              unawaited(HapticFeedback.selectionClick());
                              setState(() => _stake = value);
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 58,
                        height: 58,
                        padding: const EdgeInsets.all(4),
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
                              color: foreground.withValues(alpha: 0.75),
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${value ~/ 10000}만',
                            style: TextStyle(
                              color: foreground,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
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

  Widget _buildLegacyStakeSelector() {
    final stakes = <int>{
      casinoMinimumStake,
      20000,
      50000,
      casinoMaximumStake,
      if (_maxStake >= casinoMinimumStake) _maxStake,
    }.where((value) => value <= _maxStake).toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _CasinoSectionLabel('칩 선택')),
            Text(
              '테이블 한도 ${_money(_maxStake)}원',
              style: const TextStyle(color: Color(0xFFAFA198), fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 7),
        if (stakes.isEmpty)
          const Text(
            '현금 100만원 이상일 때 1만원 칩을 사용할 수 있습니다.',
            style: TextStyle(color: Color(0xFFF0B47C), fontSize: 11),
          )
        else
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: stakes
                .map(
                  (value) => ChoiceChip(
                    key: Key('casino-stake-$value'),
                    label: Text('${_money(value)}원'),
                    selected: _stake == value,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() => _stake = value),
                    avatar: Icon(
                      Icons.circle,
                      size: 14,
                      color: value >= 100000
                          ? const Color(0xFF252525)
                          : value >= 50000
                          ? const Color(0xFF9D2436)
                          : value >= 20000
                          ? const Color(0xFF285E9E)
                          : const Color(0xFFE9E3D4),
                    ),
                    selectedColor: const Color(0xFFE0BB74),
                    backgroundColor: const Color(0xFF302622),
                    labelStyle: TextStyle(
                      color: _stake == value
                          ? const Color(0xFF1A100C)
                          : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
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
    final action = continuingCraps
        ? 'ROLL DICE · POINT ${crapsRound.point}'
        : game == CasinoGameType.slots
        ? 'SPIN'
        : game == CasinoGameType.craps
        ? 'COME-OUT ROLL'
        : 'PLACE BET';
    return Container(
      width: double.infinity,
      height: 58,
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
        onPressed: enabled ? _playSelected : null,
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
                        fontSize: 12,
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
    height: 52,
    child: FilledButton.icon(
      key: const Key('casino-play-round'),
      onPressed: _busy || !_canStartRound ? null : _playSelected,
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
          const SizedBox(height: 12),
          _buildStakeSelector(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              key: const Key('casino-blackjack-deal'),
              onPressed: _busy || !_canStartRound
                  ? null
                  : () => _apply(
                      widget.onStartBlackjack(_stake),
                      motion: _CasinoTableMotion.deal,
                    ),
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
                _canStartRound
                    ? '${_money(_stake)}원 · 카드 받기'
                    : _shortLockReason(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
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
        const SizedBox(height: 14),
        Row(
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
                        hand.stake > _state.bankCash
                    ? null
                    : () => _apply(
                        widget.onBlackjackAction(BlackjackAction.doubleDown),
                        motion: _CasinoTableMotion.deal,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final game = _selectedGame;
    final latest = game == null ? null : _latestRecordFor(game);
    return _CasinoPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CasinoSectionLabel('딜러 메시지'),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              _status,
              key: ValueKey(_status),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.45,
              ),
            ),
          ),
          if (latest != null) ...[
            const SizedBox(height: 8),
            Text(
              latest.detail,
              style: const TextStyle(
                color: Color(0xFFBBAEA4),
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinishEveningButton() => SizedBox(
    width: double.infinity,
    height: 52,
    child: OutlinedButton.icon(
      key: const Key('casino-finish-evening'),
      onPressed: _canFinishEvening ? () => Navigator.of(context).pop() : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: _casinoGold,
        backgroundColor: const Color(0xE8261D19),
        side: const BorderSide(color: _casinoGold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.nights_stay_rounded, size: 18),
      label: const Text(
        '그만하고 20:00으로 이동',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
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
            minHeight: 7,
            backgroundColor: const Color(0xFF40362F),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 0.8 ? const Color(0xFFDD786D) : _casinoGold,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '오늘 ${_casino.roundsForDay(_state.day)}/$casinoDailyRoundLimit판 · 누적 ${_casino.totalRounds}판 · 누적 순손익 ${_signedMoney(_casino.lifetimeNet)}원\n'
          '국가 수수료 누적 ${_money(_casino.totalNationalFee)}원',
          style: const TextStyle(
            color: Color(0xFFB5A79D),
            fontSize: 9,
            height: 1.35,
          ),
        ),
      ],
    );
    return panel ? _CasinoPanel(child: child) : child;
  }

  Widget _buildHistory({CasinoGameType? game}) {
    final records = _casino.history.reversed
        .where((record) => game == null || record.game == game)
        .take(5)
        .toList(growable: false);
    return _CasinoPanel(
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

  String _entryStatusText() {
    if (!_adultUnlocked) {
      return '성인 시점인 2010년부터 요원 PC에 중계 앱이 해금됩니다. 실제 결제나 광고는 없습니다.';
    }
    if (_state.pendingDecisions.isNotEmpty) {
      return '새 기록의 결정을 먼저 마치면 전용 중계망에 접속할 수 있습니다.';
    }
    if (_state.currentDate.weekday >= DateTime.saturday) {
      return '카지노 LIVE는 평일 주식장 마감 뒤 선택하는 저녁 행동입니다.';
    }
    if (_casino.activeBlackjack != null) {
      return '저장된 블랙잭 핸드가 있습니다. 블랙잭 테이블에서 이어 하세요.';
    }
    if (_casino.activeCraps != null) {
      return '포인트 ${_casino.activeCraps!.point}가 설정된 크랩스 라운드가 있습니다. 포인트나 7이 나올 때까지 이어 하세요.';
    }
    if (weekdayEveningUsed(_state)) {
      return '오늘의 저녁 행동을 이미 사용했습니다. 다음 평일 장 마감 뒤 이용할 수 있습니다.';
    }
    if (_state.marketMinute < krxCloseMinute) {
      return '현재는 중계 준비 시간입니다. 15:00 장 마감 뒤 라이브 테이블이 열립니다.';
    }
    if (_state.marketMinute > marketDayEndMinute - casinoRoundMinutes) {
      return '마지막 게임 시작 시각 19:30이 지났습니다. 오늘 원장만 확인할 수 있습니다.';
    }
    return '오늘의 저녁 행동 · 테이블을 자유롭게 바꿀 수 있고, 한 판마다 30분을 사용합니다.';
  }

  String _shortLockReason() {
    if (!_adultUnlocked) return '2010년 성인 해금';
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
    if (_maxStake < casinoMinimumStake) return '현금 100만원 필요';
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
              '• 데시멀 요원은 현장에 가지 않고 작업실 PC의 전용 중계망으로 테이블을 시청·베팅합니다.\n'
              '• 카지노는 평일 주식장 마감 뒤 선택하는 저녁 행동입니다. 선택하면 다른 저녁 행동은 이용할 수 없습니다.\n'
              '• 2010년 성인 시점부터 15:00~19:30에 새 게임을 시작할 수 있습니다.\n'
              '• 바카라·블랙잭·룰렛·크랩스·다이사이·3릴을 자유롭게 바꿀 수 있으며, 정산된 한 판마다 30분을 사용해 하루 최대 10판입니다. 10판을 채울 필요는 없으며 1판 후에도 나갈 수 있습니다.\n'
              '• 카지노를 끝내고 나가면 남은 저녁 시간이 정리되어 즉시 20:00이 됩니다.\n'
              '• 한 판 베팅은 1만원 단위, 현금의 1%와 10만원 중 작은 금액까지입니다.\n'
              '• 월 손실 중단선은 월 첫 입장 현금의 2%, 최소 5만원·최대 100만원입니다.\n'
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

class _CasinoPanel extends StatelessWidget {
  const _CasinoPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
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

class _CasinoBadge extends StatelessWidget {
  const _CasinoBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: 0.7)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
    ),
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
    padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
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
          height: 39,
          decoration: BoxDecoration(
            color: _casinoGold,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: _casinoGold,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                note,
                style: const TextStyle(
                  color: Color(0xFFB9AAA0),
                  fontSize: 8,
                  height: 1.25,
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
    height: 52,
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
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFC9BDB4), fontSize: 7.5),
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
    final icon = switch (label) {
      '히트' => Icons.add_card_rounded,
      '더블' => Icons.exposure_plus_2_rounded,
      '스탠드' => Icons.pan_tool_alt_rounded,
      _ => Icons.visibility_rounded,
    };
    return SizedBox(
      height: 56,
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
            Icon(icon, size: 16),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
            Text(
              english,
              style: const TextStyle(fontSize: 6.5, letterSpacing: 0.7),
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
