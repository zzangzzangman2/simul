part of 'main.dart';

enum _HorseRacePhase {
  welcome,
  guide,
  betting,
  acceptance,
  handover,
  racing,
  result,
}

class _HorseSheetData {
  const _HorseSheetData({
    required this.image,
    required this.sourceFrames,
    required this.canonicalFrameSize,
  });

  final ui.Image image;
  final List<Rect> sourceFrames;
  final Size canonicalFrameSize;
}

final Map<String, Future<_HorseSheetData>> _horseSheetCache =
    <String, Future<_HorseSheetData>>{};
const _horseSheetCacheLimit = 10;

Future<_HorseSheetData> _loadHorseSheet(String asset) {
  final cached = _horseSheetCache.remove(asset);
  if (cached != null) {
    _horseSheetCache[asset] = cached;
    return cached;
  }
  while (_horseSheetCache.length >= _horseSheetCacheLimit) {
    _horseSheetCache.remove(_horseSheetCache.keys.first);
  }
  final pending = _decodeHorseSheet(asset);
  _horseSheetCache[asset] = pending;
  return pending;
}

Future<_HorseSheetData> _decodeHorseSheet(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  final frame = await codec.getNextFrame();
  codec.dispose();
  final image = frame.image;
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (rgba == null) {
    final sourceFrames = _fallbackHorseSourceFrames(image);
    return _HorseSheetData(
      image: image,
      sourceFrames: sourceFrames,
      canonicalFrameSize: sourceFrames.first.size,
    );
  }
  final pixels = rgba.buffer.asUint8List(
    rgba.offsetInBytes,
    rgba.lengthInBytes,
  );
  final sourceFrames = List<Rect>.generate(
    8,
    (index) => _horseAlphaBounds(image, pixels, index),
    growable: false,
  );
  return _HorseSheetData(
    image: image,
    sourceFrames: sourceFrames,
    canonicalFrameSize: Size(
      sourceFrames.map((frame) => frame.width).reduce(math.max),
      sourceFrames.map((frame) => frame.height).reduce(math.max),
    ),
  );
}

List<Rect> _fallbackHorseSourceFrames(ui.Image image) =>
    List<Rect>.generate(8, (index) {
      final cellWidth = image.width / 4;
      final cellHeight = image.height / 2;
      return Rect.fromLTWH(
        (index % 4) * cellWidth,
        (index ~/ 4) * cellHeight,
        cellWidth,
        cellHeight,
      );
    }, growable: false);

Rect _horseAlphaBounds(ui.Image image, Uint8List pixels, int frame) {
  final cellLeft = (frame % 4 * image.width / 4).floor();
  final cellTop = (frame ~/ 4 * image.height / 2).floor();
  final cellRight = (((frame % 4) + 1) * image.width / 4).floor();
  final cellBottom = (((frame ~/ 4) + 1) * image.height / 2).floor();
  var minX = cellRight;
  var minY = cellBottom;
  var maxX = cellLeft;
  var maxY = cellTop;
  for (var y = cellTop; y < cellBottom; y++) {
    for (var x = cellLeft; x < cellRight; x++) {
      if (pixels[(y * image.width + x) * 4 + 3] <= 12) continue;
      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x);
      maxY = math.max(maxY, y);
    }
  }
  if (minX > maxX || minY > maxY) {
    return _fallbackHorseSourceFrames(image)[frame];
  }
  const margin = 7.0;
  return Rect.fromLTRB(
    math.max(cellLeft.toDouble(), minX - margin),
    math.max(cellTop.toDouble(), minY - margin),
    math.min(cellRight.toDouble(), maxX + margin + 1),
    math.min(cellBottom.toDouble(), maxY + margin + 1),
  );
}

class HorseRacingMiniGame extends StatefulWidget {
  const HorseRacingMiniGame({
    super.key,
    required this.race,
    required this.availableCash,
    this.previewMode = false,
    this.onPowerOff,
    this.raceDuration = const Duration(seconds: 16),
    this.stateRecoveryRateBps = horseRaceDefaultStateRecoveryRateBps,
  });

  final HorseRaceCard race;
  final int availableCash;
  final bool previewMode;
  final VoidCallback? onPowerOff;
  final Duration raceDuration;
  final int stateRecoveryRateBps;

  @override
  State<HorseRacingMiniGame> createState() => _HorseRacingMiniGameState();
}

class _HorseRacingMiniGameState extends State<HorseRacingMiniGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _raceController;
  _HorseRacePhase _phase = _HorseRacePhase.welcome;
  int _welcomeDialogueStep = 0;
  HorseBetType _betType = HorseBetType.win;
  late String _primaryHorseId = widget.race.entrants.first.id;
  String? _secondaryHorseId;
  bool _pickingQuinellaSecond = false;
  late int _stake;
  int _raceAudioCue = 0;
  final Set<String> _playedRaceSurges = <String>{};
  double _lastRaceSurgeCueAt = -1;
  Timer? _raceIntroTimer;
  bool _showRaceIntroduction = false;

  Duration get _raceIntroductionDuration => widget.raceDuration.inSeconds >= 8
      ? const Duration(milliseconds: 2600)
      : const Duration(milliseconds: 120);

  HorseRaceEntrant get _primary => widget.race.entrantById(_primaryHorseId);

  HorseRaceEntrant? get _secondary => _secondaryHorseId == null
      ? null
      : widget.race.entrantById(_secondaryHorseId!);

  bool get _canStart =>
      isValidHorseRaceStake(_stake, widget.availableCash) &&
      (_betType != HorseBetType.quinella ||
          (_secondaryHorseId != null && _secondaryHorseId != _primaryHorseId));

  int get _grossPayout => calculateHorseRacePayout(
    race: widget.race,
    betType: _betType,
    primaryHorseId: _primaryHorseId,
    secondaryHorseId: _secondaryHorseId,
    stake: _stake,
  );

  double get _hitMultiplier => switch (_betType) {
    HorseBetType.win => _primary.winOdds,
    HorseBetType.place => _primary.placeOdds,
    HorseBetType.quinella =>
      _secondary == null
          ? 0
          : horseRaceQuinellaOdds(
              widget.race,
              _primaryHorseId,
              _secondaryHorseId!,
            ),
  };

  int get _estimatedGrossPayout => (_stake * _hitMultiplier).floor();

  int get _estimatedStateProfitFee => horseRaceStateProfitFee(
    stake: _stake,
    grossPayout: _estimatedGrossPayout,
    recoveryRateBps: widget.stateRecoveryRateBps,
  );

  int get _estimatedNetDelta =>
      _estimatedGrossPayout - _stake - _estimatedStateProfitFee;

  String get _tellerBettingLine => switch (_betType) {
    HorseBetType.win => '오빠, ${_primary.name} 단승을 골랐네. 1등으로 들어오면 적중이야.',
    HorseBetType.place => '오빠, ${_primary.name} 연승을 골랐네. 3등 안에 들어오면 적중이야.',
    HorseBetType.quinella when _secondary == null =>
      '오빠, 복승은 말 두 마리를 골라야 해. 두 번째 말을 선택해 줘.',
    HorseBetType.quinella =>
      '오빠, ${_primary.name}하고 ${_secondary!.name} 복승이네. 두 말이 1·2등이면 순서는 상관없어.',
  };

  String _tellerRaceLine(double time) {
    if (time < 0.13) return '오빠, 출발했어. 아직 초반이니까 자리 잡는 걸 보자.';
    if (time < 0.48) return '선두가 계속 바뀌고 있어. 오빠가 고른 말도 흐름을 타는 중이야.';
    if (time < 0.76) return '이제 승부처야. 바깥으로 나오는 말들의 탄력을 봐.';
    if (time < 0.93) return '직선 들어왔어! 선두가 결승선까지 버티는지 끝까지 봐.';
    return '결승선 통과야. 잠깐만, 공식 착순하고 기록 확인해 줄게.';
  }

  @override
  void initState() {
    super.initState();
    _stake = horseRaceStakePercents
        .map(
          (percent) =>
              horseRaceStakeForCashPercent(widget.availableCash, percent),
        )
        .firstWhere((stake) => stake >= horseRaceMinStake, orElse: () => 0);
    _raceController =
        AnimationController(vsync: this, duration: widget.raceDuration)
          ..addListener(_handleRaceAudioProgress)
          ..addStatusListener((status) {
            if (status != AnimationStatus.completed || !mounted) return;
            HapticFeedback.heavyImpact();
            GameAudio.instance.stopLoop(GameLoopSfx.horseGallop);
            GameAudio.instance.stopLoop(GameLoopSfx.raceCrowd);
            GameAudio.instance.playSfx(GameSfx.crowdVictory);
            GameAudio.instance.playSfx(
              _grossPayout > 0 ? GameSfx.coinsLarge : GameSfx.error,
            );
            setState(() => _phase = _HorseRacePhase.result);
          });
  }

  @override
  void dispose() {
    _raceIntroTimer?.cancel();
    GameAudio.instance.stopLoop(GameLoopSfx.horseGallop);
    GameAudio.instance.stopLoop(GameLoopSfx.raceCrowd);
    _raceController.dispose();
    super.dispose();
  }

  void _handleRaceAudioProgress() {
    if (_phase != _HorseRacePhase.racing) return;
    _handleRaceSurgeAudio();
    final nextCue = _raceController.value >= 0.78
        ? 3
        : _raceController.value >= 0.52
        ? 2
        : _raceController.value >= 0.27
        ? 1
        : 0;
    if (nextCue <= _raceAudioCue) return;
    _raceAudioCue = nextCue;
    if (nextCue == 3) {
      HapticFeedback.heavyImpact();
    } else if (nextCue == 2) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    GameAudio.instance.playSfx(
      nextCue == 2 ? GameSfx.notification : GameSfx.impactWood,
      volumeScale: nextCue == 3 ? 0.8 : 0.55,
    );
  }

  void _handleRaceSurgeAudio() {
    final now = _raceController.value;
    final due = widget.race.entrants
        .where((entrant) {
          final surgeAt =
              horseRaceBroadcastSurgeAt(race: widget.race, entrant: entrant) *
              _LiveHorseRaceTrack.officialRaceFraction;
          return now >= surgeAt && !_playedRaceSurges.contains(entrant.id);
        })
        .toList(growable: false);
    if (due.isEmpty) return;
    _playedRaceSurges.addAll(due.map((entrant) => entrant.id));
    if (now - _lastRaceSurgeCueAt < 0.045) return;

    final featured = [...due]
      ..sort((left, right) {
        final leftSelected =
            left.id == _primaryHorseId || left.id == _secondaryHorseId;
        final rightSelected =
            right.id == _primaryHorseId || right.id == _secondaryHorseId;
        if (leftSelected != rightSelected) return leftSelected ? -1 : 1;
        return widget.race.finishOrder
            .indexOf(left.id)
            .compareTo(widget.race.finishOrder.indexOf(right.id));
      });
    final horse = featured.first;
    final decisive =
        horse.id == _primaryHorseId ||
        horse.id == _secondaryHorseId ||
        widget.race.finishOrder.indexOf(horse.id) < 2;
    _lastRaceSurgeCueAt = now;
    if (decisive) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    GameAudio.instance.playRaceSurgeSfx(decisive: decisive);
  }

  void _changeBetType(HorseBetType type) {
    GameAudio.instance.playSfx(GameSfx.toggle);
    setState(() {
      _betType = type;
      if (type == HorseBetType.quinella) {
        _secondaryHorseId = null;
        _pickingQuinellaSecond = true;
      } else {
        _secondaryHorseId = null;
        _pickingQuinellaSecond = false;
      }
    });
  }

  void _selectEntrant(String id) {
    GameAudio.instance.playSfx(GameSfx.select);
    setState(() {
      if (_betType != HorseBetType.quinella) {
        _primaryHorseId = id;
        return;
      }
      if (!_pickingQuinellaSecond) {
        _primaryHorseId = id;
        _secondaryHorseId = null;
        _pickingQuinellaSecond = true;
      } else if (id != _primaryHorseId) {
        _secondaryHorseId = id;
        _pickingQuinellaSecond = false;
      }
    });
  }

  Future<void> _showHorseDetails(HorseRaceEntrant entrant) async {
    GameAudio.instance.playSfx(GameSfx.paperRustle, volumeScale: 0.65);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xAA17101F),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.92,
        child: _HorseDetailSheet(entrant: entrant),
      ),
    );
  }

  void _setStake(int stake) {
    GameAudio.instance.playSfx(GameSfx.coins, volumeScale: 0.7);
    setState(() => _stake = stake);
  }

  void _goOffline() {
    GameAudio.instance.playSfx(GameSfx.toggle);
    GameAudio.instance.stopLoop(GameLoopSfx.horseGallop);
    GameAudio.instance.stopLoop(GameLoopSfx.raceCrowd);
    final powerOff = widget.onPowerOff;
    if (powerOff != null) {
      powerOff();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _reviewTicket() {
    if (!_canStart) return;
    GameAudio.instance.playSfx(GameSfx.paperPlace);
    setState(() => _phase = _HorseRacePhase.acceptance);
  }

  void _acceptTicket() {
    GameAudio.instance.playSfx(GameSfx.paperRustle);
    setState(() => _phase = _HorseRacePhase.handover);
  }

  void _beginRace() {
    if (_phase == _HorseRacePhase.racing) return;
    _raceAudioCue = 0;
    _playedRaceSurges.clear();
    _lastRaceSurgeCueAt = -1;
    _raceController.reset();
    _raceIntroTimer?.cancel();
    GameAudio.instance.playSfx(GameSfx.paperRustle, volumeScale: 0.55);
    setState(() {
      _phase = _HorseRacePhase.racing;
      _showRaceIntroduction = true;
    });
    _raceIntroTimer = Timer(_raceIntroductionDuration, _startLiveRace);
  }

  void _startLiveRace() {
    _raceIntroTimer?.cancel();
    _raceIntroTimer = null;
    if (!mounted ||
        _phase != _HorseRacePhase.racing ||
        !_showRaceIntroduction) {
      return;
    }
    HapticFeedback.mediumImpact();
    GameAudio.instance.playSfx(GameSfx.raceBell);
    GameAudio.instance.startLoop(GameLoopSfx.horseGallop);
    GameAudio.instance.startLoop(GameLoopSfx.raceCrowd);
    setState(() => _showRaceIntroduction = false);
    _raceController.forward(from: 0);
  }

  HorseRaceSessionResult _buildResult() => HorseRaceSessionResult(
    raceId: widget.race.id,
    betType: _betType,
    primaryHorseId: _primaryHorseId,
    secondaryHorseId: _secondaryHorseId,
    stake: _stake,
    grossPayout: _grossPayout,
    finishOrder: widget.race.finishOrder,
    stateRecoveryRateBps: widget.stateRecoveryRateBps,
  );

  void _finish() {
    if (widget.previewMode) {
      _raceController.reset();
      setState(() => _phase = _HorseRacePhase.betting);
      return;
    }
    Navigator.pop(context, _buildResult());
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    return Theme(
      data: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(fontFamily: 'Maplestory'),
        primaryTextTheme: baseTheme.primaryTextTheme.apply(
          fontFamily: 'Maplestory',
        ),
      ),
      child: PopScope(
        canPop: _phase != _HorseRacePhase.racing,
        child: switch (_phase) {
          _HorseRacePhase.welcome => _buildTellerWelcomeScreen(),
          _HorseRacePhase.guide => _buildTellerGuideScreen(),
          _HorseRacePhase.betting => _buildBettingScreen(),
          _HorseRacePhase.acceptance => _buildTicketAcceptanceScreen(),
          _HorseRacePhase.handover => _buildTicketHandoverScreen(),
          _HorseRacePhase.racing => _buildRacingScreen(),
          _HorseRacePhase.result => _buildResultScreen(),
        },
      ),
    );
  }

  Widget _buildTellerWelcomeScreen() {
    final firstLine = _welcomeDialogueStep == 0;
    return _buildTellerStoryScreen(
      screenKey: const Key('horse-race-teller-welcome-screen'),
      asset: horseRaceTellerWelcomeAsset,
      title: '국가망 경마 · 전자 마권 창구',
      line: firstLine
          ? '오빠, 오늘 경주 중계도 보러 접속했네.'
          : '잘 왔어. 출전표 보기 전에 마권 적는 법부터 같이 볼까?',
      continueKey: firstLine
          ? const Key('horse-race-teller-welcome-next')
          : const Key('horse-race-teller-open-guide-anywhere'),
      onContinue: firstLine
          ? () => setState(() => _welcomeDialogueStep = 1)
          : () => setState(() => _phase = _HorseRacePhase.guide),
      child: firstLine
          ? null
          : _tellerActionButton(
              key: const Key('horse-race-teller-open-guide'),
              icon: Icons.description_outlined,
              label: '마권 작성법 보기',
              onPressed: () => setState(() => _phase = _HorseRacePhase.guide),
            ),
    );
  }

  Widget _buildTellerGuideScreen() => _buildTellerStoryScreen(
    screenKey: const Key('horse-race-teller-guide-screen'),
    asset: horseRaceTellerGuideAsset,
    title: '마권 작성 안내',
    line: '오빠, 단승은 고른 말이 1등, 연승은 3등 안에 들면 적중이야. 복승은 1·2등 두 마리를 순서 없이 고르면 돼.',
    continueKey: const Key('horse-race-teller-open-card-anywhere'),
    onContinue: () => setState(() => _phase = _HorseRacePhase.betting),
    child: _tellerActionButton(
      key: const Key('horse-race-teller-open-card'),
      icon: Icons.format_list_numbered_rounded,
      label: '출전표 보고 마권 작성하기',
      onPressed: () => setState(() => _phase = _HorseRacePhase.betting),
    ),
  );

  Widget _buildTicketAcceptanceScreen() => _buildTellerStoryScreen(
    screenKey: const Key('horse-race-teller-acceptance-screen'),
    asset: horseRaceTellerAcceptAsset,
    title: '마권 접수',
    line:
        '오빠, ${_betType.label} ${_primary.name}${_secondary == null ? '' : '·${_secondary!.name}'}에 ${_money(_stake)}원 맞지? 확인했어. 지금 접수할게.',
    continueKey: const Key('horse-race-teller-confirm-ticket-anywhere'),
    onContinue: _acceptTicket,
    child: _tellerActionButton(
      key: const Key('horse-race-teller-confirm-ticket'),
      icon: Icons.point_of_sale_rounded,
      label: '이 내용으로 접수하기',
      onPressed: _acceptTicket,
    ),
  );

  Widget _buildTicketHandoverScreen() => _buildTellerStoryScreen(
    screenKey: const Key('horse-race-teller-handover-screen'),
    asset: horseRaceTellerHandoverAsset,
    title: '전자 마권 발권 완료',
    line: '오빠, 전자 마권 나왔어. 내가 끝까지 같이 볼 테니까 이제 중계 화면으로 가자.',
    continueKey: const Key('horse-race-teller-watch-race-anywhere'),
    onContinue: _beginRace,
    child: _tellerActionButton(
      key: const Key('horse-race-teller-watch-race'),
      icon: Icons.sensors_rounded,
      label: '마권 받고 중계 보기',
      onPressed: _beginRace,
    ),
  );

  Widget _buildTellerStoryScreen({
    required Key screenKey,
    required String asset,
    required String title,
    required String line,
    required Widget? child,
    Key? continueKey,
    VoidCallback? onContinue,
  }) => Scaffold(
    key: screenKey,
    backgroundColor: const Color(0xFF171713),
    body: SafeArea(
      child: GestureDetector(
        key: const Key('horse-race-teller-fullscreen-continue'),
        behavior: HitTestBehavior.translucent,
        onTap: () => _activeNovelDialogueState?._handleExternalTap(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              asset,
              key: Key('horse-race-teller-image-$asset'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x08000000),
                    Color(0x24000000),
                    Color(0xE8161411),
                  ],
                  stops: [0, 0.58, 1],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              top: 8,
              child: _HorseRaceTellerHeader(
                title: title,
                onBack: () {
                  if (_phase == _HorseRacePhase.welcome) {
                    Navigator.of(context).maybePop();
                  } else if (_phase == _HorseRacePhase.guide) {
                    setState(() {
                      _phase = _HorseRacePhase.welcome;
                      _welcomeDialogueStep = 1;
                    });
                  } else {
                    setState(() => _phase = _HorseRacePhase.betting);
                  }
                },
              ),
            ),
            Positioned(
              right: 12,
              top: 62,
              child: Container(
                key: const Key('horse-race-access-mode-badge'),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xE6352D50),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFFB9A8D9)),
                ),
                child: Text(
                  '국가망 · 온라인',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: _NovelDialogue(
                key: ValueKey<String>('horse-race-teller-$line'),
                speaker: '창구 직원',
                line: line,
                charactersPerSecond: 42,
                fontFamily: 'Maplestory',
                continueKey: continueKey,
                onContinue: onContinue,
                child: child,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _tellerActionButton({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) => SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton.icon(
      key: key,
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF254F42),
        foregroundColor: const Color(0xFFFFF5DD),
        side: const BorderSide(color: Color(0xFFBA9860)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      icon: Icon(icon, size: 19),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
      ),
    ),
  );

  Widget _buildAccessModeSelector() => Container(
    key: const Key('horse-race-access-mode-selector'),
    height: 48,
    margin: const EdgeInsets.fromLTRB(12, 9, 12, 9),
    decoration: BoxDecoration(
      color: const Color(0xFF2A2439),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1C0B0712),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: _buildConnectionButton(
            key: const Key('horse-race-mode-online'),
            icon: Icons.sensors_rounded,
            title: '온라인',
            subtitle: '국가망 접속 중',
            active: true,
          ),
        ),
        Container(width: 1, height: 24, color: const Color(0xFF4D4561)),
        SizedBox(
          width: 132,
          child: _buildConnectionButton(
            key: const Key('horse-race-mode-offline'),
            icon: Icons.power_settings_new_rounded,
            title: '오프라인',
            subtitle: 'PC 전원 끄기',
            active: false,
            onTap: _goOffline,
          ),
        ),
      ],
    ),
  );

  Widget _buildConnectionButton({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool active,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 12),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF2DAA78)
                      : const Color(0xFF3B344B),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: active ? Colors.white : const Color(0xFFC3B9D0),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF9DE1C5)
                          : const Color(0xFFB1A8BE),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
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

  Widget _buildBettingScreen() {
    final stakeOptions = horseRaceStakePercents
        .map(
          (percent) => MapEntry(
            percent,
            horseRaceStakeForCashPercent(widget.availableCash, percent),
          ),
        )
        .where((option) => option.value >= horseRaceMinStake)
        .toList(growable: false);
    return Scaffold(
      key: const Key('horse-race-betting-screen'),
      backgroundColor: const Color(0xFFF6F3EE),
      appBar: AppBar(
        toolbarHeight: 64,
        elevation: 0,
        backgroundColor: const Color(0xFF211C30),
        foregroundColor: Colors.white,
        titleSpacing: 12,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFB99251), width: 1.4),
        ),
        title: Row(
          children: [
            const _RaceHubEmblem(),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '오늘의 제6경주',
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: -0.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '국가망 · 온라인  ·  ${widget.race.postTime} 출발',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFD7D0E7),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '주문 가능금',
                    style: TextStyle(
                      color: Color(0xFFC9C0D9),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '₩ ${_money(widget.availableCash)}',
                    style: const TextStyle(
                      color: Color(0xFFFFD36F),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 188),
        children: [
          _buildAccessModeSelector(),
          Container(
            key: const Key('horse-race-venue-hero'),
            height: 190,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x280F0A18),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  horseRaceBackgroundAsset,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.12, 0.08),
                  filterQuality: FilterQuality.high,
                  cacheWidth: 900,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x1A181227), Color(0xE634294E)],
                      stops: [0.15, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE95778),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '베팅 접수 중',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xD926203C),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0x66FFFFFF)),
                    ),
                    child: Text(
                      '${widget.race.weather}  ·  주로 ${widget.race.trackCondition}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 13,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '서울 제6경주',
                              style: TextStyle(
                                color: Color(0xFFFFD972),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${widget.race.distanceMeters}m 더트',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                height: 1.05,
                                letterSpacing: -0.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '출전 8두',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${widget.race.postTime} 발주',
                            style: const TextStyle(
                              color: Color(0xFFDAD3E8),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: _HorseRaceTellerHint(line: _tellerBettingLine),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 5),
            child: Row(
              children: [
                for (
                  var index = 0;
                  index < HorseBetType.values.length;
                  index++
                ) ...[
                  Expanded(
                    child: _BetTypeButton(
                      type: HorseBetType.values[index],
                      selected: _betType == HorseBetType.values[index],
                      onTap: () => _changeBetType(HorseBetType.values[index]),
                    ),
                  ),
                  if (index != HorseBetType.values.length - 1)
                    const SizedBox(width: 7),
                ],
              ],
            ),
          ),
          const SizedBox(height: 9),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  _betType == HorseBetType.quinella
                      ? (_pickingQuinellaSecond
                            ? '두 번째 말을 골라주세요'
                            : '첫 번째 말을 골라주세요')
                      : '출전마 8두',
                  style: const TextStyle(
                    color: Color(0xFF302944),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.touch_app_rounded,
                  size: 14,
                  color: Color(0xFF8B829D),
                ),
                const SizedBox(width: 3),
                const Text(
                  '말을 터치해 선택',
                  style: TextStyle(
                    color: Color(0xFF7B738A),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _SelectedRunnerIntel(
              primary: _primary,
              secondary: _secondary,
              betType: _betType,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x180B0712),
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < widget.race.entrants.length;
                  index++
                ) ...[
                  _HorseEntryRow(
                    entrant: widget.race.entrants[index],
                    primary: widget.race.entrants[index].id == _primaryHorseId,
                    secondary:
                        widget.race.entrants[index].id == _secondaryHorseId,
                    betType: _betType,
                    onTap: () => _selectEntrant(widget.race.entrants[index].id),
                    onDetails: () =>
                        _showHorseDetails(widget.race.entrants[index]),
                  ),
                  if (index != widget.race.entrants.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 50,
                      endIndent: 10,
                      color: Color(0xFFF0EDF1),
                    ),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(15, 9, 15, 0),
            child: Text(
              '적중 이익에만 국가 수수료 20%가 부과됩니다. 미적중 시 추가 수수료는 없습니다.',
              style: TextStyle(
                color: Color(0xFF777080),
                fontSize: 9,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 11),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFD8D2DF))),
            boxShadow: [
              BoxShadow(
                color: Color(0x25000000),
                blurRadius: 14,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BetSlipSummary(
                betType: _betType,
                primary: _primary,
                secondary: _secondary,
                stake: _stake,
                multiplier: _hitMultiplier,
                stateFee: _estimatedStateProfitFee,
                netDelta: _estimatedNetDelta,
              ),
              if (widget.availableCash > horseRaceLeisureStakeBasisCap) ...[
                const SizedBox(height: 5),
                Text(
                  '고액 계좌 보호 · 레저 기준금 ${_money(horseRaceStakeBasisForCash(widget.availableCash))}원까지만 베팅 산정',
                  key: const Key('horse-race-leisure-stake-cap'),
                  style: const TextStyle(
                    color: Color(0xFF765C20),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 7),
              Row(
                children: [
                  for (var index = 0; index < stakeOptions.length; index++) ...[
                    Expanded(
                      child: _StakeCoinButton(
                        percent: stakeOptions[index].key,
                        value: stakeOptions[index].value,
                        selected: _stake == stakeOptions[index].value,
                        enabled: isValidHorseRaceStake(
                          stakeOptions[index].value,
                          widget.availableCash,
                        ),
                        onTap: () => _setStake(stakeOptions[index].value),
                      ),
                    ),
                    if (index != stakeOptions.length - 1)
                      const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 7),
              SizedBox(
                width: double.infinity,
                height: 49,
                child: FilledButton.icon(
                  key: const Key('horse-race-start'),
                  onPressed: _canStart ? _reviewTicket : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2DAA78),
                    disabledBackgroundColor: const Color(0xFFC9C5CE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.flag_rounded, size: 20),
                  label: Text(
                    '${_money(_stake)}원 베팅하고 경주 보기',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRacingScreen() => Scaffold(
    key: const Key('horse-race-running-screen'),
    backgroundColor: const Color(0xFF211B31),
    body: SafeArea(
      child: Column(
        children: [
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            color: const Color(0xFF352D50),
            child: Row(
              children: [
                const Icon(Icons.sensors_rounded, color: Color(0xFFFF6A89)),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '국가망 실시간 중계',
                        style: const TextStyle(
                          color: Color(0xFFFF9AAF),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '제6경주 ${widget.race.distanceMeters}m · ${_betType.label} ${_primary.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_money(_stake)}원',
                  style: const TextStyle(
                    color: Color(0xFFFFD972),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _showRaceIntroduction
                ? _HorseRaceBroadcastLineup(
                    race: widget.race,
                    selectedIds: <String>{_primaryHorseId, ?_secondaryHorseId},
                    onContinue: _startLiveRace,
                  )
                : AnimatedBuilder(
                    animation: _raceController,
                    builder: (context, _) => _LiveHorseRaceTrack(
                      race: widget.race,
                      time: _raceController.value,
                      selectedIds: <String>{
                        _primaryHorseId,
                        ?_secondaryHorseId,
                      },
                      duration: widget.raceDuration,
                      reduceMotion: MediaQuery.disableAnimationsOf(context),
                    ),
                  ),
          ),
          if (_showRaceIntroduction)
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: _HorseRaceLiveDialogue(
                line: '출전마 프리뷰야. 예상 순위와 최근 전적 확인하면 바로 출발해.',
              ),
            )
          else
            AnimatedBuilder(
              animation: _raceController,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: _HorseRaceLiveDialogue(
                  line: _tellerRaceLine(_raceController.value),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _buildResultScreen() {
    final result = _buildResult();
    final winner = widget.race.entrantById(widget.race.finishOrder.first);
    final hit = result.grossPayout > 0;
    return Scaffold(
      key: const Key('horse-race-result-screen'),
      backgroundColor: const Color(0xFFF4F1F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF352D50),
        foregroundColor: Colors.white,
        title: Text(
          '서울경마공원 · 공식 확정',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
        children: [
          _OfficialRaceBroadcastHeader(race: widget.race, winner: winner),
          const SizedBox(height: 11),
          _OfficialRaceRecordBoard(
            race: widget.race,
            selectedIds: <String>{_primaryHorseId, ?_secondaryHorseId},
          ),
          const SizedBox(height: 11),
          Container(
            key: const Key('horse-race-payout-card'),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: hit ? const Color(0xFFE8F7F0) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hit ? const Color(0xFF2DAA78) : const Color(0xFFD8D2DF),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: hit
                      ? const Color(0xFF2DAA78)
                      : const Color(0xFF867B91),
                  foregroundColor: Colors.white,
                  child: Icon(
                    hit ? Icons.emoji_events_rounded : Icons.receipt_long,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hit ? '${_betType.label} 적중' : '${_betType.label} 미적중',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '전자 마권 ${_money(_stake)}원 · 배당 ${_money(result.grossPayout)}원',
                        style: const TextStyle(
                          color: Color(0xFF68736D),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '확정이익 ${_money(math.max(0, result.grossPayout - result.stake))}원 · 국가 수수료 ${_money(result.stateProfitFee)}원',
                        style: const TextStyle(
                          color: Color(0xFF68736D),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${result.netDelta >= 0 ? '+' : ''}${_money(result.netDelta)}원',
                  style: TextStyle(
                    color: result.netDelta >= 0
                        ? const Color(0xFF187C4C)
                        : const Color(0xFFC64D4D),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HorseRaceLiveDialogue(
                key: const Key('horse-race-teller-result-dialogue'),
                line: hit
                    ? '오빠, 적중이야. 축하해. 배당하고 수수료까지 정확히 정산해 뒀어.'
                    : '오빠, 이번에는 조금 아쉽게 비켜갔어. 공식 기록은 남겨 뒀으니까 차분히 확인해 봐.',
              ),
              const SizedBox(height: 7),
              FilledButton.icon(
                key: const Key('horse-race-confirm-result'),
                onPressed: _finish,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4C3E71),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: const Icon(Icons.home_rounded),
                label: const Text(
                  '메인으로 가기',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorseRaceTellerHeader extends StatelessWidget {
  const _HorseRaceTellerHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 5),
    decoration: BoxDecoration(
      color: const Color(0xE9181815),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x99BA9860)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        IconButton(
          key: const Key('horse-race-teller-back'),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        const Icon(
          Icons.confirmation_number_outlined,
          color: Color(0xFFE0C07C),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Maplestory',
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HorseRaceTellerHint extends StatelessWidget {
  const _HorseRaceTellerHint({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 220),
    child: Container(
      key: ValueKey<String>(line),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF282234),
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240B0712),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF2DAA78),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '창구 직원',
                  style: TextStyle(
                    color: Color(0xFFFFD98B),
                    fontFamily: 'Maplestory',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Maplestory',
                    fontSize: 10.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _HorseRaceLiveDialogue extends StatelessWidget {
  const _HorseRaceLiveDialogue({super.key, required this.line});

  final String line;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    key: const Key('horse-race-live-dialogue'),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: Container(
        key: ValueKey<String>(line),
        padding: const EdgeInsets.fromLTRB(11, 8, 11, 9),
        decoration: BoxDecoration(
          color: const Color(0xDA17131F),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x88E0C07C)),
          boxShadow: const [
            BoxShadow(color: Color(0x77000000), blurRadius: 10),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '창구 직원',
              style: TextStyle(
                color: Color(0xFFFFD98B),
                fontFamily: 'Maplestory',
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                line,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Maplestory',
                  fontSize: 9.5,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RaceHubEmblem extends StatelessWidget {
  const _RaceHubEmblem();

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: const Color(0xFFE95778),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFFFD36F), width: 1.2),
    ),
    child: const Icon(Icons.sports_score, color: Colors.white, size: 19),
  );
}

class _StakeCoinButton extends StatelessWidget {
  const _StakeCoinButton({
    required this.percent,
    required this.value,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int percent;
  final int value;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : 0.35,
    child: Material(
      key: Key('horse-stake-$value'),
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 43,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE95778) : const Color(0xFFF2EFF4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFFE95778)
                  : const Color(0xFFD9D4DE),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$percent%',
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF40384D),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '${_money(value)}원',
                maxLines: 1,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFFFE8EE)
                      : const Color(0xFF777080),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SelectedRunnerIntel extends StatelessWidget {
  const _SelectedRunnerIntel({
    required this.primary,
    required this.secondary,
    required this.betType,
  });

  final HorseRaceEntrant primary;
  final HorseRaceEntrant? secondary;
  final HorseBetType betType;

  @override
  Widget build(BuildContext context) {
    final paired = betType == HorseBetType.quinella && secondary != null;
    return Container(
      key: const Key('horse-race-selected-runner-intel'),
      height: 102,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF272232),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240B0712),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: Color(primary.accentValue)),
          ),
          Positioned(
            key: const Key('horse-selected-sprite'),
            right: -4,
            top: 30,
            width: 120,
            height: 68,
            child: Opacity(
              opacity: 0.96,
              child: _GallopSprite(
                asset: primary.spriteAsset,
                framePhase: 6,
                width: 120,
                height: 70,
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 20,
            child: Container(
              width: 38,
              height: 44,
              decoration: BoxDecoration(
                color: Color(primary.accentValue),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(
                '${primary.gate}',
                style: TextStyle(
                  color: primary.gate == 1 || primary.gate == 5
                      ? const Color(0xFF252033)
                      : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Positioned(
            left: 61,
            top: 11,
            right: 118,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '나의 선택',
                  style: TextStyle(
                    color: Color(0xFFD8B76A),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  paired
                      ? '${primary.name} + ${secondary!.name}'
                      : primary.name,
                  maxLines: paired ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  paired
                      ? '복승 조합 선택 완료'
                      : '${primary.jockey} · ${primary.runningStyle} · 우승 ${(primary.winProbability * 100).toStringAsFixed(1)}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC9C1D4),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 61,
            right: 118,
            bottom: 9,
            child: paired
                ? _RecentTenPairSummary(primary: primary, secondary: secondary!)
                : _RecentTenStrip(entrant: primary, onDark: true),
          ),
          Positioned(
            right: 12,
            top: 9,
            child: Text(
              key: const Key('horse-selected-win-odds'),
              '단승 ${primary.winOdds.toStringAsFixed(1)}배',
              style: const TextStyle(
                color: Color(0xFFFFD66B),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BetSlipSummary extends StatelessWidget {
  const _BetSlipSummary({
    required this.betType,
    required this.primary,
    required this.secondary,
    required this.stake,
    required this.multiplier,
    required this.stateFee,
    required this.netDelta,
  });

  final HorseBetType betType;
  final HorseRaceEntrant primary;
  final HorseRaceEntrant? secondary;
  final int stake;
  final double multiplier;
  final int stateFee;
  final int netDelta;

  @override
  Widget build(BuildContext context) {
    final horseLabel = secondary == null
        ? '${primary.gate}번 ${primary.name}'
        : '${primary.gate}번 ${primary.name} + ${secondary!.gate}번 ${secondary!.name}';
    return Container(
      key: const Key('horse-race-ticket-slip'),
      height: 43,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDD7E3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF4C3E71),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              betType.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  horseLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF312A3F),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '배당 ×${multiplier.toStringAsFixed(1)} · 적중 가정 국가 수수료 ${_money(stateFee)}원',
                  style: const TextStyle(
                    color: Color(0xFF7A7284),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_money(stake)}원',
                style: const TextStyle(
                  color: Color(0xFF302944),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '예상 ${netDelta >= 0 ? '+' : ''}${_money(netDelta)}원',
                style: const TextStyle(
                  color: Color(0xFF15906B),
                  fontSize: 8.5,
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

class _BetTypeButton extends StatelessWidget {
  const _BetTypeButton({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final HorseBetType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: Key('horse-bet-${type.name}'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(9),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF302A43) : const Color(0xFFEAE5DE),
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x30302A43),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            type.label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF393145),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            type.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: selected
                  ? const Color(0xFFE4DDED)
                  : const Color(0xFF847B8D),
              fontSize: 7.3,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _HorseEntryRow extends StatelessWidget {
  const _HorseEntryRow({
    required this.entrant,
    required this.primary,
    required this.secondary,
    required this.betType,
    required this.onTap,
    required this.onDetails,
  });

  final HorseRaceEntrant entrant;
  final bool primary;
  final bool secondary;
  final HorseBetType betType;
  final VoidCallback onTap;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final selected = primary || secondary;
    return Material(
      key: Key('horse-entry-${entrant.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          height: 80,
          color: selected ? const Color(0xFFF0F7F3) : Colors.white,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                width: 3,
                color: selected ? const Color(0xFF2DAA78) : Colors.transparent,
              ),
              SizedBox(
                width: 44,
                child: Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(entrant.accentValue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${entrant.gate}',
                      style: TextStyle(
                        color: entrant.gate == 1 || entrant.gate == 5
                            ? const Color(0xFF282431)
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entrant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF302944),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${entrant.origin} · ${entrant.sex}${entrant.age}',
                            style: const TextStyle(
                              color: Color(0xFF8B8295),
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (selected)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF2DAA78),
                                    size: 13,
                                  ),
                                  if (betType == HorseBetType.quinella) ...[
                                    const SizedBox(width: 2),
                                    Text(
                                      primary ? 'A' : 'B',
                                      style: const TextStyle(
                                        color: Color(0xFF187557),
                                        fontSize: 7,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '${entrant.jockey} · ${entrant.assignedWeight.toStringAsFixed(1)}kg · ${entrant.trainer} · ${entrant.runningStyle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF766E7F),
                          fontSize: 7.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _BroadcastRecentForm(entrant: entrant),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '10전 ${entrant.recentWinCount}승 · 3위권 ${entrant.recentTopThreeCount}회',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF756C80),
                                fontSize: 7.4,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '단승',
                      style: TextStyle(
                        color: Color(0xFF9A929F),
                        fontSize: 6.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      entrant.winOdds.toStringAsFixed(1),
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFFE54F71)
                            : const Color(0xFF443A54),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '연승',
                      style: TextStyle(
                        color: Color(0xFF9A929F),
                        fontSize: 6.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      entrant.placeOdds.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Color(0xFF645A70),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 30,
                child: InkWell(
                  key: Key('horse-detail-${entrant.id}'),
                  onTap: onDetails,
                  borderRadius: BorderRadius.circular(15),
                  child: const SizedBox(
                    width: 28,
                    height: 36,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9A929F),
                      size: 20,
                    ),
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

class _RecentTenPairSummary extends StatelessWidget {
  const _RecentTenPairSummary({required this.primary, required this.secondary});

  final HorseRaceEntrant primary;
  final HorseRaceEntrant secondary;

  @override
  Widget build(BuildContext context) => Container(
    height: 25,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: const Color(0x550E091A),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0x33FFFFFF)),
    ),
    alignment: Alignment.centerLeft,
    child: Text(
      '최근 10전  A ${primary.recentWinCount}승·3위권 ${primary.recentTopThreeCount}회   B ${secondary.recentWinCount}승·3위권 ${secondary.recentTopThreeCount}회',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _RecentTenStrip extends StatelessWidget {
  const _RecentTenStrip({required this.entrant, this.onDark = false});

  final HorseRaceEntrant entrant;
  final bool onDark;

  Color _rankColor(int rank) => switch (rank) {
    1 => const Color(0xFFE7B34B),
    2 => const Color(0xFF5A8FD8),
    3 => const Color(0xFF43A47A),
    _ => onDark ? const Color(0xFF776B8C) : const Color(0xFFE7E2EB),
  };

  @override
  Widget build(BuildContext context) => SizedBox(
    key: Key(
      onDark
          ? 'horse-selected-recent-ten-${entrant.id}'
          : 'horse-recent-ten-${entrant.id}',
    ),
    height: 17,
    child: Row(
      children: [
        for (var index = 0; index < entrant.recentFinishes.length; index++) ...[
          Container(
            width: 13,
            height: 13,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _rankColor(entrant.recentFinishes[index]),
              shape: BoxShape.circle,
              border: Border.all(
                color: entrant.recentFinishes[index] <= 3
                    ? const Color(0x44FFFFFF)
                    : (onDark
                          ? const Color(0x33FFFFFF)
                          : const Color(0xFFD5CFDA)),
              ),
            ),
            child: Text(
              '${entrant.recentFinishes[index]}',
              style: TextStyle(
                color: entrant.recentFinishes[index] <= 3 || onDark
                    ? Colors.white
                    : const Color(0xFF6F6778),
                fontSize: 6.6,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (index != entrant.recentFinishes.length - 1)
            const SizedBox(width: 1),
        ],
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${entrant.recentWinCount}승 · 3위권 ${entrant.recentTopThreeCount}회',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onDark ? const Color(0xFFF5EAFB) : const Color(0xFF756C80),
              fontSize: 7.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HorseDetailSheet extends StatelessWidget {
  const _HorseDetailSheet({required this.entrant});

  final HorseRaceEntrant entrant;

  String _date(DateTime value) =>
      '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final weightChange = entrant.weightChange == 0
        ? '변동 없음'
        : '${entrant.weightChange > 0 ? '+' : ''}${entrant.weightChange}kg';
    final signatureSkill = horseRaceSignatureSkill(entrant);
    return Container(
      key: Key('horse-detail-sheet-${entrant.id}'),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F4F1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 9, bottom: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFC8C0CB),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  height: 142,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF31284D), Color(0xFF604E7D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -8,
                        bottom: -2,
                        child: Opacity(
                          opacity: 0.92,
                          child: _GallopSprite(
                            asset: entrant.spriteAsset,
                            framePhase: 6,
                            width: 176,
                            height: 112,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 15,
                        top: 16,
                        right: 138,
                        bottom: 13,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Color(entrant.accentValue),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: const Color(0x99FFFFFF),
                                    ),
                                  ),
                                  child: Text(
                                    '${entrant.gate}',
                                    style: TextStyle(
                                      color:
                                          entrant.gate == 1 || entrant.gate == 5
                                          ? const Color(0xFF272131)
                                          : Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entrant.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        '${entrant.origin} · ${entrant.sex}${entrant.age}세 · ${entrant.runningStyle}',
                                        style: const TextStyle(
                                          color: Color(0xFFDCD3E7),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              '기수 ${entrant.jockey}  ·  조교사 ${entrant.trainer}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '부담중량 ${entrant.assignedWeight.toStringAsFixed(1)}kg  ·  마체중 ${entrant.bodyWeight}kg ($weightChange)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFDCD3E7),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          key: const Key('horse-detail-close'),
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0x660B0712),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Container(
                    key: Key('horse-signature-skill-${entrant.id}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF342B4B),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: Color(entrant.accentValue).withAlpha(180),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color(entrant.accentValue).withAlpha(48),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(entrant.accentValue),
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 19,
                            color: Color(entrant.accentValue),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '고유 스킬 · ${signatureSkill.name}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(
                                        entrant.accentValue,
                                      ).withAlpha(48),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: Color(entrant.accentValue),
                                      ),
                                    ),
                                    child: Text(
                                      '강도 ${signatureSkill.strengthGrade}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '효과 · ${signatureSkill.effectLabel}',
                                style: const TextStyle(
                                  color: Color(0xFFF0EBF5),
                                  fontSize: 8.8,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '조건 · ${signatureSkill.triggerLabel}',
                                style: const TextStyle(
                                  color: Color(0xFFD7D0E1),
                                  fontSize: 8.4,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '발동 구간 ${signatureSkill.phaseLabel}  ·  지속 약 2초  ·  실제 전개 반영',
                                style: TextStyle(
                                  color: Color(entrant.accentValue),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 0),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0D9E2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '최근 10전 요약',
                          style: TextStyle(
                            color: Color(0xFF352D42),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _RecentTenStrip(entrant: entrant),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _HorseDetailMetric(
                              label: '출전/1/2/3위',
                              value:
                                  '10/${entrant.recentWinCount}/${entrant.recentTopTwoCount - entrant.recentWinCount}/${entrant.recentTopThreeCount - entrant.recentTopTwoCount}',
                            ),
                            _HorseDetailMetric(
                              label: '승률',
                              value: '${entrant.recentWinCount * 10}.0%',
                              emphasized: true,
                            ),
                            _HorseDetailMetric(
                              label: '복승률',
                              value: '${entrant.recentTopTwoCount * 10}.0%',
                            ),
                            _HorseDetailMetric(
                              label: '종합점수',
                              value: entrant.compositeScore.toStringAsFixed(1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(15, 17, 15, 7),
                  child: Row(
                    children: [
                      Text(
                        '최근 10회 상세 전적',
                        style: TextStyle(
                          color: Color(0xFF302944),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '최신순',
                        style: TextStyle(
                          color: Color(0xFF8B8294),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                for (
                  var index = 0;
                  index < entrant.recentPerformances.length;
                  index++
                )
                  _HorseRecentPerformanceRow(
                    key: Key('horse-performance-${entrant.id}-$index'),
                    index: index,
                    performance: entrant.recentPerformances[index],
                    dateLabel: _date(entrant.recentPerformances[index].date),
                  ),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorseDetailMetric extends StatelessWidget {
  const _HorseDetailMetric({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          style: TextStyle(
            color: emphasized
                ? const Color(0xFFE95778)
                : const Color(0xFF3C334A),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: Color(0xFF8D8495),
            fontSize: 7,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _HorseRecentPerformanceRow extends StatelessWidget {
  const _HorseRecentPerformanceRow({
    super.key,
    required this.index,
    required this.performance,
    required this.dateLabel,
  });

  final int index;
  final HorseRecentPerformance performance;
  final String dateLabel;

  Color get _rankColor => switch (performance.position) {
    1 => const Color(0xFFE7B34B),
    2 => const Color(0xFF5A8FD8),
    3 => const Color(0xFF43A47A),
    _ => const Color(0xFF8E8496),
  };

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 7),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFE4DEE6)),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _rankColor,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '${performance.position}위',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$dateLabel · ${performance.distanceMeters}m · ${performance.position}/${performance.fieldSize}두',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF352E40),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${performance.jockey} · ${performance.assignedWeight.toStringAsFixed(1)}kg · 마체중 ${performance.bodyWeight}kg · 레이팅 ${performance.rating}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF807787),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              horseRaceRecordLabel(performance.recordSeconds),
              style: const TextStyle(
                color: Color(0xFF4C3E71),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${index + 1}전',
              style: const TextStyle(
                color: Color(0xFFA097A5),
                fontSize: 7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _HorseRaceBroadcastLineup extends StatelessWidget {
  const _HorseRaceBroadcastLineup({
    required this.race,
    required this.selectedIds,
    required this.onContinue,
  });

  final HorseRaceCard race;
  final Set<String> selectedIds;
  final VoidCallback onContinue;

  Color _gateTextColor(int gate) =>
      gate == 1 || gate == 5 ? const Color(0xFF202A26) : Colors.white;

  @override
  Widget build(BuildContext context) {
    final predicted = [...race.entrants]
      ..sort((left, right) {
        final probability = right.winProbability.compareTo(left.winProbability);
        if (probability != 0) return probability;
        return left.winOdds.compareTo(right.winOdds);
      });
    final predictedRank = <String, int>{
      for (var index = 0; index < predicted.length; index++)
        predicted[index].id: index + 1,
    };
    return Container(
      key: const Key('horse-race-broadcast-lineup'),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      color: const Color(0xFF10131C),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(11, 9, 10, 9),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2130),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF343B4C)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDA405B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '발주 전 라인업',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '서울 제6경주 · ${race.distanceMeters}m · ${race.weather} · ${race.trackCondition}',
                        style: const TextStyle(
                          color: Color(0xFFB9C6D0),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD66B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '발주 대기',
                    style: TextStyle(
                      color: Color(0xFF2B2515),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 25,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF171B26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(width: 30, child: _BroadcastHeaderText('예상')),
                SizedBox(width: 34, child: _BroadcastHeaderText('마번')),
                Expanded(child: _BroadcastHeaderText('출전마 / 기수')),
                SizedBox(width: 74, child: _BroadcastHeaderText('최근 5전')),
                SizedBox(width: 47, child: _BroadcastHeaderText('단승')),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1018),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < race.entrants.length; index++)
                    Expanded(
                      child: _HorseBroadcastRunnerRow(
                        key: Key(
                          'horse-race-broadcast-runner-${race.entrants[index].id}',
                        ),
                        entrant: race.entrants[index],
                        predictedRank: predictedRank[race.entrants[index].id]!,
                        selected: selectedIds.contains(race.entrants[index].id),
                        stripe: index.isOdd,
                        gateTextColor: _gateTextColor(
                          race.entrants[index].gate,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            height: 46,
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2130),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFFFFD66B),
                  size: 16,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '예상 1위 ${predicted.first.name}  ·  단승 ${predicted.first.winOdds.toStringAsFixed(1)}배  ·  최근 ${predicted.first.recentWinCount}승',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('horse-race-broadcast-start-now'),
                  onPressed: onContinue,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF241D13),
                    backgroundColor: const Color(0xFFFFD66B),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '바로 출발 〉',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
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

class _BroadcastHeaderText extends StatelessWidget {
  const _BroadcastHeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Color(0xFF92A3B1),
      fontSize: 7.5,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _BroadcastRecentForm extends StatelessWidget {
  const _BroadcastRecentForm({required this.entrant});

  final HorseRaceEntrant entrant;

  Color _finishColor(int finish) => switch (finish) {
    1 => const Color(0xFFD7A83C),
    2 => const Color(0xFF4B80C4),
    3 => const Color(0xFF3F9A72),
    _ => const Color(0xFF3A4554),
  };

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (final finish in entrant.recentFinishes.take(5))
        Container(
          width: 12,
          height: 13,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _finishColor(finish),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            '$finish',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 5.8,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
    ],
  );
}

class _HorseBroadcastRunnerRow extends StatelessWidget {
  const _HorseBroadcastRunnerRow({
    super.key,
    required this.entrant,
    required this.predictedRank,
    required this.selected,
    required this.stripe,
    required this.gateTextColor,
  });

  final HorseRaceEntrant entrant;
  final int predictedRank;
  final bool selected;
  final bool stripe;
  final Color gateTextColor;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 1),
    decoration: BoxDecoration(
      color: selected
          ? const Color(0xFF283442)
          : stripe
          ? const Color(0xFF151C27)
          : const Color(0xFF101620),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(
        color: selected ? const Color(0xFFFFD66B) : const Color(0x00101620),
        width: selected ? 1.2 : 0.7,
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 30,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$predictedRank',
                style: TextStyle(
                  color: predictedRank <= 3
                      ? const Color(0xFFFFD66B)
                      : const Color(0xFFB9C6D0),
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                '예상',
                style: TextStyle(
                  color: Color(0xFF778A99),
                  fontSize: 5.5,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 34,
          child: Center(
            child: Container(
              width: 25,
              height: 25,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(entrant.accentValue),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0x99FFFFFF)),
              ),
              child: Text(
                '${entrant.gate}',
                style: TextStyle(
                  color: gateTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      entrant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.confirmation_number_rounded,
                      color: Color(0xFFFFD66B),
                      size: 10,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${entrant.jockey} · ${entrant.assignedWeight.toStringAsFixed(1)}kg · ${entrant.runningStyle}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFAEBCC7),
                  fontSize: 6.8,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 74,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BroadcastRecentForm(entrant: entrant),
              Text(
                '10전 ${entrant.recentWinCount}승 · 3위권 ${entrant.recentTopThreeCount}',
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF91A5B3),
                  fontSize: 6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 47,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '×${entrant.winOdds.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Color(0xFFFFD66B),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${(entrant.winProbability * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFF93A5B3),
                  fontSize: 6.5,
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

class _LiveHorseRaceTrack extends StatelessWidget {
  const _LiveHorseRaceTrack({
    required this.race,
    required this.time,
    required this.selectedIds,
    required this.duration,
    required this.reduceMotion,
  });

  final HorseRaceCard race;
  final double time;
  final Set<String> selectedIds;
  final Duration duration;
  final bool reduceMotion;

  // Finish the official order before the broadcast itself ends. That leaves
  // enough live track time for every runner to gallop through the embedded
  // stripe instead of stopping on it while only the sprite frames keep moving.
  static const officialRaceFraction = 0.84;

  // The production race is 16 seconds, so this keeps each signature skill
  // visible for about two seconds. Short widget-test races cap the normalized
  // window so the rest of the broadcast can still be exercised.
  double get _surgeVisualDuration =>
      (2000 / duration.inMilliseconds).clamp(0.10, 0.24).toDouble();

  double get _officialTime => (time / officialRaceFraction).clamp(0.0, 1.0);

  double _surgeStart(HorseRaceEntrant entrant) =>
      horseRaceBroadcastSurgeAt(race: race, entrant: entrant) *
      officialRaceFraction;

  double _surgeProgress(HorseRaceEntrant entrant) =>
      ((time - _surgeStart(entrant)) / _surgeVisualDuration).clamp(0.0, 1.0);

  bool _isSurging(HorseRaceEntrant entrant) {
    final start = _surgeStart(entrant);
    return time >= start && time < start + _surgeVisualDuration;
  }

  double _progress(HorseRaceEntrant entrant) {
    return horseRaceBroadcastProgress(
      race: race,
      entrant: entrant,
      time: _officialTime,
    );
  }

  double _extendedProgress(HorseRaceEntrant entrant, double raceProgress) {
    final officialFinishAt = horseRaceBroadcastFinishAt(
      race: race,
      entrant: entrant,
    );
    final visualFinishAt = officialFinishAt * officialRaceFraction;
    if (time <= visualFinishAt) return raceProgress;

    const speedSampleWindow = 0.018;
    final sampleOfficialTime = officialFinishAt - speedSampleWindow;
    final sampleProgress = horseRaceBroadcastProgress(
      race: race,
      entrant: entrant,
      time: sampleOfficialTime,
    );
    final sampleVisualTime = sampleOfficialTime * officialRaceFraction;
    final incomingProgressSpeed =
        (1 - sampleProgress) / (visualFinishAt - sampleVisualTime);
    final elapsed = time - visualFinishAt;
    const runOutProgressSpeed = 4.0;
    const accelerationWindow = 0.018;
    if (elapsed <= accelerationWindow) {
      final blend = elapsed / accelerationWindow;
      final currentSpeed = ui.lerpDouble(
        incomingProgressSpeed,
        runOutProgressSpeed,
        blend,
      )!;
      return 1 + elapsed * (incomingProgressSpeed + currentSpeed) / 2;
    }
    final rampDistance =
        accelerationWindow * (incomingProgressSpeed + runOutProgressSpeed) / 2;
    return 1 +
        rampDistance +
        (elapsed - accelerationWindow) * runOutProgressSpeed;
  }

  @override
  Widget build(BuildContext context) {
    final progress = <String, double>{
      for (final entrant in race.entrants) entrant.id: _progress(entrant),
    };
    final extendedProgress = <String, double>{
      for (final entrant in race.entrants)
        entrant.id: _extendedProgress(entrant, progress[entrant.id]!),
    };
    final liveOrder = [...race.entrants]
      ..sort((left, right) {
        final progressOrder = progress[right.id]!.compareTo(progress[left.id]!);
        if (progressOrder != 0) return progressOrder;
        return race.finishOrder
            .indexOf(left.id)
            .compareTo(race.finishOrder.indexOf(right.id));
      });
    final leader = liveOrder.first;
    final remaining = (race.distanceMeters * (1 - progress[leader.id]!))
        .round()
        .clamp(0, race.distanceMeters);
    final previousTime = math.max(0.0, _officialTime - 0.065);
    final mover = [...race.entrants]
      ..sort((left, right) {
        final leftGain =
            progress[left.id]! -
            horseRaceBroadcastProgress(
              race: race,
              entrant: left,
              time: previousTime,
            );
        final rightGain =
            progress[right.id]! -
            horseRaceBroadcastProgress(
              race: race,
              entrant: right,
              time: previousTime,
            );
        return rightGain.compareTo(leftGain);
      });
    final stageLabel = _officialTime < 0.26
        ? '초반 선행'
        : _officialTime < 0.68
        ? '중반 승부'
        : '결승 직선 총력전';
    final announcement = _officialTime < 0.045
        ? '출발했습니다! 8두가 일제히 게이트를 나섭니다.'
        : _officialTime < 0.26
        ? '${leader.name} 초반 선두! ${liveOrder[1].name}이 바로 압박합니다.'
        : _officialTime < 0.68
        ? '${mover.first.name} 중간에서 치고 나옵니다! 선두 ${leader.name}과 접전!'
        : remaining > 0
        ? '마지막 $remaining미터! ${mover.first.name} 막판 스퍼트, ${leader.name} 버팁니다!'
        : '결승선 통과! 공식 착순을 확인합니다.';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        // The generated panorama has an orthographic dirt surface from 39% to
        // 94% of its height. Keep one immutable center line per entrant so the
        // runners can never drift between the painted lanes.
        final laneTop = height * 0.39;
        final laneHeight = height * 0.55 / race.entrants.length;
        final spriteHeight = math.min(51.0, laneHeight * 0.9);
        final spriteWidth = spriteHeight * 1.72;
        final startAnchor = spriteWidth * 0.92 + 4;
        final gateExitTime = (360 / duration.inMilliseconds).clamp(
          0.018,
          0.055,
        );
        // The finish stripe is painted into the generated panorama rather
        // than drawn as a screen-space layer. The camera follows the field
        // across that single background, revealing the physical finish near
        // the end and settling before the horses reach it.
        final fixedFinishLineX = (width * 0.82).roundToDouble();
        const cameraOffset = 0.0;
        final leaderCameraProgress = progress[leader.id]!;
        // Follow the leader all the way to the stripe. Stopping the panorama
        // early removes half of the perceived motion and makes the field look
        // as if it suddenly slows before the finish.
        // Reveal and settle the physical finish stripe before the last burst.
        // Using the runner's raw progress made the stripe arrive too late once
        // more distance was reserved for a fast final gallop. The eased camera
        // still moves continuously, but is nearly settled while the field is
        // visibly spread on the approach.
        final cameraPan = Curves.easeOutQuad.transform(leaderCameraProgress);
        const embeddedFinishTopRatio = 0.843;
        const embeddedFinishBottomRatio = 0.860;
        const embeddedFinishCenterRatio =
            (embeddedFinishTopRatio + embeddedFinishBottomRatio) / 2;
        final backgroundWidth = width * 1.8;
        final settledBackgroundOffset =
            fixedFinishLineX - backgroundWidth * embeddedFinishCenterRatio;
        final backgroundOffset = settledBackgroundOffset * cameraPan;
        return Stack(
          key: const Key('horse-race-live-track'),
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              key: const Key('horse-race-straight-panorama'),
              left: backgroundOffset,
              top: 0,
              width: backgroundWidth,
              height: height,
              child: Image.asset(
                horseRaceStraightTrackAsset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                cacheWidth: 1800,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x18000000),
                    Color(0x08000000),
                    Color(0x591A0E04),
                  ],
                ),
              ),
            ),
            const CustomPaint(painter: _BroadcastScanlinePainter()),
            CustomPaint(
              key: const Key('horse-race-straight-lanes'),
              painter: _StraightLanePainter(
                laneTop: laneTop,
                laneHeight: laneHeight,
                laneCount: race.entrants.length,
              ),
            ),
            Positioned(
              left: 9,
              right: 9,
              top: 9,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: const Color(0xF2FFFFFF),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFD1C9DB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            remaining == 0 ? '결승선 통과' : '선두 ${leader.name}',
                            style: const TextStyle(
                              color: Color(0xFF302944),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              minHeight: 5,
                              value: progress[leader.id],
                              backgroundColor: const Color(0xFFE2DDE7),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF2DAA78),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      remaining == 0 ? '착순 판독' : '남은 $remaining m',
                      style: const TextStyle(
                        color: Color(0xFFE95778),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 69,
              child: Container(
                key: const Key('horse-race-course-label'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xE6352D50),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0x779C8BBD)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.straighten_rounded,
                      size: 11,
                      color: Color(0xFFFF9AAF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${race.distanceMeters}m 직선 · $stageLabel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 69,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xE6352D50),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < 3; index++) ...[
                      if (index > 0) const SizedBox(width: 5),
                      Text(
                        '${index + 1} ${liveOrder[index].gate}',
                        style: TextStyle(
                          color: index == 0
                              ? const Color(0xFFFFD972)
                              : Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            for (var index = 0; index < race.entrants.length; index++)
              _buildRunner(
                race.entrants[index],
                index: index,
                laneTop: laneTop,
                laneHeight: laneHeight,
                spriteWidth: spriteWidth,
                spriteHeight: spriteHeight,
                trackWidth: width,
                startAnchor: startAnchor,
                trackSpan:
                    settledBackgroundOffset +
                    backgroundWidth *
                        ui.lerpDouble(
                          embeddedFinishTopRatio,
                          embeddedFinishBottomRatio,
                          (index + 0.5) / race.entrants.length,
                        )! -
                    startAnchor,
                cameraOffset: cameraOffset,
                extendedProgress: extendedProgress[race.entrants[index].id]!,
              ),
            if (time < gateExitTime)
              Positioned(
                key: const Key('horse-race-starting-gate'),
                left: startAnchor - spriteWidth * 0.92 - 5,
                top: laneTop - 3,
                width: 30,
                height: laneHeight * race.entrants.length + 12,
                child: Opacity(
                  opacity: (1 - time / gateExitTime).clamp(0.0, 1.0),
                  child: CustomPaint(
                    painter: _StartingGatePainter(
                      opening: (time / (gateExitTime * 0.55)).clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              top: 101,
              child: Container(
                key: const Key('horse-race-announcer'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xF2FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD1C9DB)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.campaign_rounded,
                      color: Color(0xFFE95778),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        announcement,
                        style: const TextStyle(
                          color: Color(0xFF302944),
                          fontSize: 10,
                          height: 1.35,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRunner(
    HorseRaceEntrant entrant, {
    required int index,
    required double laneTop,
    required double laneHeight,
    required double spriteWidth,
    required double spriteHeight,
    required double trackWidth,
    required double startAnchor,
    required double trackSpan,
    required double cameraOffset,
    required double extendedProgress,
  }) {
    final officialFinishAt = horseRaceBroadcastFinishAt(
      race: race,
      entrant: entrant,
    );
    final visualFinishAt = officialFinishAt * officialRaceFraction;
    // A runner's screen position must come from one continuous world-space
    // curve. The former late-race spacing lerp rewrote every x coordinate at
    // once, which looked like the whole field teleported off-screen when a
    // surge cue happened near the same time.
    final racePoint = startAnchor + extendedProgress * trackSpan - cameraOffset;
    final winnerBadgeArrival = ((time - visualFinishAt) / 0.028).clamp(
      0.0,
      1.0,
    );
    final urgency = Curves.easeInCubic.transform(
      ((_officialTime - 0.52) / 0.48).clamp(0.0, 1.0),
    );
    final strideFrames = math.max(1, duration.inMilliseconds ~/ 54);
    final framePhase = time * strideFrames + entrant.gate * 0.7;
    final stridePhase = time * math.pi * (29 + urgency * 13) + entrant.gate;
    final bob = math.sin(stridePhase) * (0.8 + urgency * 1.35);
    final tilt = math.sin(stridePhase * 0.5) * 0.014;
    // Horizontal stride wobble made a runner move backward by a few pixels on
    // some frames, most noticeably beside the finish stripe. World progress is
    // now the only source of x movement; gait remains visible through the
    // sprite frames, vertical bob and subtle body tilt.
    final left = racePoint - spriteWidth * 0.92;
    final selected = selectedIds.contains(entrant.id);
    final surgeActive = _isSurging(entrant);
    final surgeProgress = surgeActive ? _surgeProgress(entrant) : 0.0;
    final signatureSkill = horseRaceSignatureSkill(entrant);
    final placeSkillBeforeHorse = left + spriteWidth + 101 > trackWidth;
    final showWinnerBadge =
        race.finishOrder.first == entrant.id &&
        time >= visualFinishAt &&
        !surgeActive;
    return Positioned(
      key: Key('horse-live-${entrant.id}'),
      left: left,
      top: laneTop + index * laneHeight + (laneHeight - spriteHeight) / 2 + bob,
      width: spriteWidth,
      height: spriteHeight,
      child: Transform.rotate(
        angle: tilt,
        alignment: Alignment.bottomCenter,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            if (surgeActive && !reduceMotion)
              Positioned(
                key: Key('horse-race-surge-${entrant.id}'),
                left: -spriteWidth * 0.58,
                bottom: -4,
                width: spriteWidth * 1.62,
                height: spriteHeight + 12,
                child: CustomPaint(
                  painter: _HorseRaceSurgeTrailPainter(
                    progress: surgeProgress,
                    accent: selected
                        ? const Color(0xFFFFD76D)
                        : Color(entrant.accentValue),
                    seed: entrant.gate,
                  ),
                ),
              ),
            Positioned(
              left: spriteWidth * 0.12,
              bottom: 1,
              child: Container(
                width: spriteWidth * 0.7,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x66000000),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: const [
                    BoxShadow(color: Color(0x55000000), blurRadius: 5),
                  ],
                ),
              ),
            ),
            if (time > 0.035 && _officialTime < 0.99)
              Positioned(
                left: -10 - urgency * 8,
                bottom: -1,
                child: _HorseDust(
                  phase: time * (20 + urgency * 18) + entrant.gate,
                  intensity: urgency,
                  color: const Color(0x99DAB783),
                ),
              ),
            _GallopSprite(
              asset: entrant.spriteAsset,
              framePhase: framePhase,
              width: spriteWidth,
              height: spriteHeight,
            ),
            if (surgeActive)
              Positioned(
                left: placeSkillBeforeHorse ? -97 : spriteWidth + 3,
                top: -2,
                width: 94,
                child: _HorseRaceSkillTag(
                  key: Key('horse-race-skill-tag-${entrant.id}'),
                  entrant: entrant,
                  skill: signatureSkill,
                  progress: surgeProgress,
                  selected: selected,
                  reduceMotion: reduceMotion,
                  tailOnRight: placeSkillBeforeHorse,
                ),
              ),
            if (showWinnerBadge)
              Positioned(
                left: spriteWidth * 0.28,
                top: -27,
                child: _WinnerFinishBadge(
                  key: const Key('horse-race-winner-badge'),
                  arrival: winnerBadgeArrival,
                  floatPhase: stridePhase,
                ),
              ),
            Positioned(
              left: 1,
              top: 0,
              child: Container(
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: Color(entrant.accentValue),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFFFD76D)
                        : const Color(0xAAFFFFFF),
                    width: selected ? 2.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(0xCCFFD76D),
                            blurRadius: 7 + urgency * 5,
                            spreadRadius:
                                0.5 + math.sin(stridePhase).abs() * 1.2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${entrant.gate}',
                    style: TextStyle(
                      color: entrant.gate == 1 || entrant.gate == 5
                          ? const Color(0xFF202A26)
                          : Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
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

class _HorseRaceSkillTag extends StatelessWidget {
  const _HorseRaceSkillTag({
    super.key,
    required this.entrant,
    required this.skill,
    required this.progress,
    required this.selected,
    required this.reduceMotion,
    required this.tailOnRight,
  });

  final HorseRaceEntrant entrant;
  final HorseRaceSignatureSkill skill;
  final double progress;
  final bool selected;
  final bool reduceMotion;
  final bool tailOnRight;

  @override
  Widget build(BuildContext context) {
    final arrival = reduceMotion
        ? 1.0
        : Curves.easeOutBack.transform((progress / 0.16).clamp(0.0, 1.0));
    final departure = progress < 0.82
        ? 1.0
        : ((1 - progress) / 0.18).clamp(0.0, 1.0);
    final accent = selected
        ? const Color(0xFFFFD76D)
        : Color(entrant.accentValue);
    return Semantics(
      liveRegion: true,
      label: '${entrant.name} 고유 스킬 ${skill.name} 발동, ${skill.effectLabel}',
      child: Opacity(
        opacity: departure,
        child: Transform.translate(
          offset: Offset(0, reduceMotion ? 0 : (1 - arrival) * 7),
          child: Transform.scale(
            scale: reduceMotion ? 1 : 0.88 + arrival * 0.12,
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 23,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 23,
                    margin: EdgeInsets.only(
                      left: tailOnRight ? 0 : 3,
                      right: tailOnRight ? 3 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xF22B233D),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: accent,
                        width: selected ? 1.6 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withAlpha(selected ? 115 : 72),
                          blurRadius: 8,
                        ),
                        const BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 10,
                          color: accent,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            skill.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: tailOnRight ? null : 0,
                    right: tailOnRight ? 0 : null,
                    top: 8,
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B233D),
                          border: Border(
                            right: BorderSide(color: accent),
                            bottom: BorderSide(color: accent),
                          ),
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
}

class _HorseRaceSurgeTrailPainter extends CustomPainter {
  const _HorseRaceSurgeTrailPainter({
    required this.progress,
    required this.accent,
    required this.seed,
  });

  final double progress;
  final Color accent;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final energy = math.sin(progress * math.pi).clamp(0.0, 1.0);
    final ribbonPaint = Paint()
      ..color = accent.withAlpha((energy * 170).round().clamp(0, 170).toInt())
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var index = 0; index < 5; index++) {
      final lane = (index + seed) % 5;
      final y = size.height * (0.30 + lane * 0.105);
      final startX = size.width * (0.05 + index * 0.035);
      final endX = size.width * (0.66 + index * 0.035);
      ribbonPaint.strokeWidth = index.isEven ? 2.2 : 1.2;
      canvas.drawLine(
        Offset(startX, y + math.sin((progress + index) * math.pi) * 3),
        Offset(endX, y),
        ribbonPaint,
      );
    }
    final sparkPaint = Paint()
      ..color = const Color(
        0xFFFFF1B7,
      ).withAlpha((energy * 220).round().clamp(0, 220).toInt());
    for (var index = 0; index < 7; index++) {
      final x = size.width * (0.12 + ((index * 23 + seed * 11) % 48) / 100);
      final y = size.height * (0.20 + ((index * 19 + seed * 7) % 62) / 100);
      canvas.drawCircle(Offset(x, y), index.isEven ? 1.8 : 1.1, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HorseRaceSurgeTrailPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.seed != seed;
}

class _WinnerFinishBadge extends StatelessWidget {
  const _WinnerFinishBadge({
    super.key,
    required this.arrival,
    required this.floatPhase,
  });

  final double arrival;
  final double floatPhase;

  @override
  Widget build(BuildContext context) {
    final pop = Curves.easeOutBack.transform(arrival);
    return Transform.translate(
      offset: Offset(0, -math.sin(floatPhase * 0.42).abs() * 1.4),
      child: Transform.scale(
        scale: ui.lerpDouble(0.68, 1, pop)!,
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 3, 7, 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD45C),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white, width: 1.3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
              BoxShadow(
                color: Color(0x99FFD45C),
                blurRadius: 8,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 11,
                color: Color(0xFF5A3511),
              ),
              SizedBox(width: 3),
              Text(
                '1등!',
                style: TextStyle(
                  color: Color(0xFF35200B),
                  fontFamily: 'Maplestory',
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: Color(0x55FFFFFF), offset: Offset(0, 1)),
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

class _GallopSprite extends StatelessWidget {
  const _GallopSprite({
    required this.asset,
    required this.framePhase,
    required this.width,
    required this.height,
  });

  final String asset;
  final double framePhase;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: FutureBuilder<_HorseSheetData>(
      future: _loadHorseSheet(asset),
      builder: (context, snapshot) {
        final sheet = snapshot.data;
        if (sheet == null) return const SizedBox.shrink();
        final normalizedPhase = framePhase % 8;
        final frame = normalizedPhase.floor();
        final nextFrame = (frame + 1) % 8;
        final blend = horseRaceFrameCrossfadeProgress(normalizedPhase);
        return CustomPaint(
          key: Key('horse-frame-${asset.hashCode}-$frame'),
          painter: _HorseFramePainter(
            image: sheet.image,
            sourceRect: sheet.sourceFrames[frame],
            nextSourceRect: sheet.sourceFrames[nextFrame],
            blend: blend,
            canonicalFrameSize: sheet.canonicalFrameSize,
            frame: frame,
          ),
        );
      },
    ),
  );
}

class _HorseFramePainter extends CustomPainter {
  const _HorseFramePainter({
    required this.image,
    required this.sourceRect,
    required this.nextSourceRect,
    required this.blend,
    required this.canonicalFrameSize,
    required this.frame,
  });

  final ui.Image image;
  final Rect sourceRect;
  final Rect nextSourceRect;
  final double blend;
  final Size canonicalFrameSize;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    _paintFrame(canvas, size, sourceRect, 1 - blend);
    if (blend > 0) _paintFrame(canvas, size, nextSourceRect, blend);
  }

  void _paintFrame(Canvas canvas, Size size, Rect source, double opacity) {
    if (opacity <= 0) return;
    final destination = horseRaceStableFrameDestination(
      canvasSize: size,
      sourceSize: source.size,
      canonicalSourceSize: canonicalFrameSize,
    );
    canvas.drawImageRect(
      image,
      source,
      destination,
      Paint()
        ..filterQuality = FilterQuality.high
        ..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0)),
    );
  }

  @override
  bool shouldRepaint(covariant _HorseFramePainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.image != image ||
      oldDelegate.sourceRect != sourceRect ||
      oldDelegate.nextSourceRect != nextSourceRect ||
      oldDelegate.blend != blend ||
      oldDelegate.canonicalFrameSize != canonicalFrameSize;
}

@visibleForTesting
double horseRaceFrameCrossfadeProgress(double framePhase) {
  final fraction = framePhase - framePhase.floorToDouble();
  if (fraction <= 0.58) return 0;
  final transition = ((fraction - 0.58) / 0.42).clamp(0.0, 1.0);
  return transition * transition * (3 - 2 * transition);
}

@visibleForTesting
Rect horseRaceStableFrameDestination({
  required Size canvasSize,
  required Size sourceSize,
  required Size canonicalSourceSize,
}) {
  if (canvasSize.isEmpty || sourceSize.isEmpty || canonicalSourceSize.isEmpty) {
    return Rect.zero;
  }
  final scale = math.min(
    canvasSize.width / canonicalSourceSize.width,
    canvasSize.height / canonicalSourceSize.height,
  );
  final destinationSize = Size(
    sourceSize.width * scale,
    sourceSize.height * scale,
  );
  return Alignment.bottomCenter.inscribe(
    destinationSize,
    Offset.zero & canvasSize,
  );
}

class _HorseDust extends StatelessWidget {
  const _HorseDust({
    required this.phase,
    required this.intensity,
    required this.color,
  });

  final double phase;
  final double intensity;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 28 + intensity * 20,
    height: 16 + intensity * 6,
    child: Stack(
      children: List.generate(5 + (intensity * 6).round(), (index) {
        final trail = 18 + intensity * 24;
        final drift = (phase * (7 + intensity * 4) + index * 9) % trail;
        final size = 3.5 + index % 3 * 1.6 + intensity * 1.2;
        return Positioned(
          left: trail - drift,
          bottom: 1 + index % 4 * (2.5 + intensity),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: (0.72 - index * 0.055).clamp(0.16, 0.72),
              ),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    ),
  );
}

class _StraightLanePainter extends CustomPainter {
  const _StraightLanePainter({
    required this.laneTop,
    required this.laneHeight,
    required this.laneCount,
  });

  final double laneTop;
  final double laneHeight;
  final int laneCount;

  @override
  void paint(Canvas canvas, Size size) {
    final bright = Paint()
      ..color = const Color(0xA8FFF6DB)
      ..strokeWidth = 1.35;
    final shade = Paint()
      ..color = const Color(0x2A6E3E1C)
      ..strokeWidth = 3.2;
    for (var boundary = 0; boundary <= laneCount; boundary++) {
      final y = laneTop + laneHeight * boundary;
      canvas.drawLine(Offset(0, y + 1), Offset(size.width, y + 1), shade);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), bright);
    }
  }

  @override
  bool shouldRepaint(covariant _StraightLanePainter oldDelegate) =>
      oldDelegate.laneTop != laneTop ||
      oldDelegate.laneHeight != laneHeight ||
      oldDelegate.laneCount != laneCount;
}

class _BroadcastScanlinePainter extends CustomPainter {
  const _BroadcastScanlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x1006E3A0)
      ..strokeWidth = 1;
    for (double y = 1; y < size.height; y += 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    final edgePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x24000000), Color(0x00000000), Color(0x24000000)],
        stops: [0, 0.5, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StartingGatePainter extends CustomPainter {
  const _StartingGatePainter({required this.opening});

  final double opening;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = Paint()
      ..color = const Color(0xFFC6D1CD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final lane = size.height / 8;
    for (var index = 0; index < 8; index++) {
      final top = index * lane;
      canvas.drawRect(Rect.fromLTWH(1, top, size.width - 2, lane - 1), frame);
      final door = Paint()
        ..color = const Color(0xFF4B6A5E)
        ..strokeWidth = 2;
      canvas.save();
      canvas.translate(size.width / 2, top + lane / 2);
      canvas.rotate(-opening * math.pi * 0.42);
      canvas.drawLine(Offset.zero, Offset(size.width / 2, -lane / 2 + 2), door);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StartingGatePainter oldDelegate) =>
      oldDelegate.opening != opening;
}

class _OfficialRaceBroadcastHeader extends StatelessWidget {
  const _OfficialRaceBroadcastHeader({
    required this.race,
    required this.winner,
  });

  final HorseRaceCard race;
  final HorseRaceEntrant winner;

  @override
  Widget build(BuildContext context) {
    final record = horseRaceRecordLabel(
      horseRaceFinishTimeSeconds(race: race, entrant: winner),
    );
    return Container(
      key: const Key('horse-race-official-broadcast-header'),
      decoration: BoxDecoration(
        color: const Color(0xFF101924),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF536475), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 29,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            color: const Color(0xFF1D2A38),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  color: const Color(0xFFC72432),
                  child: const Text(
                    'KRA 중계',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '서울경마공원  제6경주',
                    style: TextStyle(
                      color: Color(0xFFDCE5EC),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Text(
                  '공식 확정',
                  style: TextStyle(
                    color: Color(0xFFFFD65A),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 78,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  horseRacePhotoFinishAsset,
                  key: const Key('horse-race-photo-finish-image'),
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.4, 0.12),
                  filterQuality: FilterQuality.high,
                  cacheWidth: 1000,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x0A000000), Color(0xA8000000)],
                      stops: [0.4, 1],
                    ),
                  ),
                ),
                const Positioned(
                  left: 9,
                  bottom: 6,
                  child: Text(
                    '포토피니시 판독 영상',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
            color: const Color(0xFF101924),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  color: Color(winner.accentValue),
                  child: Text(
                    '${winner.gate}',
                    style: TextStyle(
                      color: winner.gate == 1 || winner.gate == 5
                          ? const Color(0xFF182027)
                          : Colors.white,
                      fontSize: 22,
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
                        '1위  ${winner.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${winner.jockey} 기수 · 단승 ${winner.winOdds.toStringAsFixed(1)}배',
                        style: const TextStyle(
                          color: Color(0xFF9FB0BD),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '우승 기록',
                      style: TextStyle(
                        color: Color(0xFF9FB0BD),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      record,
                      key: const Key('horse-race-winning-record'),
                      style: const TextStyle(
                        color: Color(0xFFFFD65A),
                        fontSize: 22,
                        fontFeatures: [ui.FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFF0A1119),
            child: Text(
              '${race.distanceMeters}m  |  출발 ${race.postTime}  |  '
              '날씨 ${race.weather}  |  주로 ${race.trackCondition}',
              style: const TextStyle(
                color: Color(0xFFB9C5CE),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficialRaceRecordBoard extends StatelessWidget {
  const _OfficialRaceRecordBoard({
    required this.race,
    required this.selectedIds,
  });

  final HorseRaceCard race;
  final Set<String> selectedIds;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('horse-race-official-record-board'),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F2E8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFC99A3D), width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x280B1824),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF172838),
            border: Border(
              bottom: BorderSide(color: Color(0xFFC99A3D), width: 1.5),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFFD66F),
                size: 23,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '공식 경주 성적',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '서울경마공원 · 제6경주',
                      style: TextStyle(
                        color: Color(0xFFB9C7D2),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _OfficialStatusBadge(),
            ],
          ),
        ),
        const SizedBox(height: 30, child: _OfficialRecordColumns()),
        for (var index = 0; index < race.finishOrder.length; index++)
          _OfficialRecordRow(
            position: index + 1,
            entrant: race.entrantById(race.finishOrder[index]),
            recordSeconds: horseRaceFinishTimeSeconds(
              race: race,
              entrant: race.entrantById(race.finishOrder[index]),
            ),
            previousSeconds: index == 0
                ? null
                : horseRaceFinishTimeSeconds(
                    race: race,
                    entrant: race.entrantById(race.finishOrder[index - 1]),
                  ),
            selected: selectedIds.contains(race.finishOrder[index]),
          ),
      ],
    ),
  );
}

class _OfficialStatusBadge extends StatelessWidget {
  const _OfficialStatusBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFF2E8B66),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: const Color(0xFF8EE0BC)),
    ),
    child: const Text(
      '공식 확정',
      style: TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _OfficialRecordColumns extends StatelessWidget {
  const _OfficialRecordColumns();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFE7D8B4),
    child: Row(
      children: [
        SizedBox(width: 26, child: _RecordHeading('착순')),
        SizedBox(width: 36, child: _RecordHeading('마번')),
        Expanded(child: _RecordHeading('마명 / 기수', align: TextAlign.left)),
        SizedBox(width: 60, child: _RecordHeading('기록')),
        SizedBox(width: 38, child: _RecordHeading('착차')),
        SizedBox(width: 44, child: _RecordHeading('단승')),
      ],
    ),
  );
}

class _RecordHeading extends StatelessWidget {
  const _RecordHeading(this.label, {this.align = TextAlign.center});

  final String label;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text(
    label,
    textAlign: align,
    style: const TextStyle(
      color: Color(0xFF374656),
      fontSize: 7.5,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _OfficialRecordRow extends StatelessWidget {
  const _OfficialRecordRow({
    required this.position,
    required this.entrant,
    required this.recordSeconds,
    required this.previousSeconds,
    required this.selected,
  });

  final int position;
  final HorseRaceEntrant entrant;
  final double recordSeconds;
  final double? previousSeconds;
  final bool selected;

  String get _margin {
    if (previousSeconds == null) return '-';
    return horseRaceMarginLabel(recordSeconds - previousSeconds!);
  }

  @override
  Widget build(BuildContext context) => Container(
    key: Key('horse-result-record-${entrant.id}'),
    height: 44,
    decoration: BoxDecoration(
      color: selected
          ? const Color(0xFFE1F3E9)
          : position == 1
          ? const Color(0xFFFFF4CF)
          : position.isEven
          ? const Color(0xFFF1F4F2)
          : const Color(0xFFFBFAF6),
      border: const Border(
        top: BorderSide(color: Color(0xFFC9D1D4), width: 0.7),
      ),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(
            '$position',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: position == 1
                  ? const Color(0xFFB27811)
                  : const Color(0xFF263746),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Center(
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(entrant.accentValue),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0x33000000)),
              ),
              child: Text(
                '${entrant.gate}',
                style: TextStyle(
                  color: entrant.gate == 1 || entrant.gate == 5
                      ? const Color(0xFF182027)
                      : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entrant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF24374A),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                entrant.jockey,
                style: const TextStyle(
                  color: Color(0xFF708090),
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            horseRaceRecordLabel(recordSeconds),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF24374A),
              fontSize: 9,
              fontFeatures: [ui.FontFeature.tabularFigures()],
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            _margin,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6D7780),
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            entrant.winOdds.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB04462),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}
