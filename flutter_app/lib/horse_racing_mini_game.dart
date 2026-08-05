part of 'main.dart';

enum _HorseRacePhase { betting, racing, result }

const _boardHeaderStyle = TextStyle(
  color: Color(0xFF766E82),
  fontSize: 8.5,
  fontWeight: FontWeight.w800,
);

class _HorseSheetData {
  const _HorseSheetData({required this.image, required this.sourceFrames});

  final ui.Image image;
  final List<Rect> sourceFrames;
}

final Map<String, Future<_HorseSheetData>> _horseSheetCache =
    <String, Future<_HorseSheetData>>{};

Future<_HorseSheetData> _loadHorseSheet(String asset) =>
    _horseSheetCache.putIfAbsent(asset, () async {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      final image = frame.image;
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgba == null) {
        return _HorseSheetData(
          image: image,
          sourceFrames: _fallbackHorseSourceFrames(image),
        );
      }
      final pixels = rgba.buffer.asUint8List(
        rgba.offsetInBytes,
        rgba.lengthInBytes,
      );
      return _HorseSheetData(
        image: image,
        sourceFrames: List<Rect>.generate(
          8,
          (index) => _horseAlphaBounds(image, pixels, index),
          growable: false,
        ),
      );
    });

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
    this.raceDuration = const Duration(seconds: 12),
    this.stateRecoveryRateBps = horseRaceDefaultStateRecoveryRateBps,
  });

  final HorseRaceCard race;
  final int availableCash;
  final bool previewMode;
  final Duration raceDuration;
  final int stateRecoveryRateBps;

  @override
  State<HorseRacingMiniGame> createState() => _HorseRacingMiniGameState();
}

class _HorseRacingMiniGameState extends State<HorseRacingMiniGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _raceController;
  _HorseRacePhase _phase = _HorseRacePhase.betting;
  HorseBetType _betType = HorseBetType.win;
  late String _primaryHorseId = widget.race.entrants.first.id;
  String? _secondaryHorseId;
  bool _pickingQuinellaSecond = false;
  int _stake = horseRaceMinStake;

  HorseRaceEntrant get _primary => widget.race.entrantById(_primaryHorseId);

  HorseRaceEntrant? get _secondary => _secondaryHorseId == null
      ? null
      : widget.race.entrantById(_secondaryHorseId!);

  bool get _canStart =>
      widget.availableCash >= horseRaceMinStake &&
      _stake >= horseRaceMinStake &&
      _stake <= math.min(horseRaceMaxStake, widget.availableCash) &&
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

  @override
  void initState() {
    super.initState();
    _raceController =
        AnimationController(vsync: this, duration: widget.raceDuration)
          ..addStatusListener((status) {
            if (status != AnimationStatus.completed || !mounted) return;
            HapticFeedback.heavyImpact();
            setState(() => _phase = _HorseRacePhase.result);
          });
  }

  @override
  void dispose() {
    _raceController.dispose();
    super.dispose();
  }

  void _changeBetType(HorseBetType type) {
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

  void _startRace() {
    if (!_canStart) return;
    HapticFeedback.mediumImpact();
    setState(() => _phase = _HorseRacePhase.racing);
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
  Widget build(BuildContext context) => PopScope(
    canPop: _phase != _HorseRacePhase.racing,
    child: switch (_phase) {
      _HorseRacePhase.betting => _buildBettingScreen(),
      _HorseRacePhase.racing => _buildRacingScreen(),
      _HorseRacePhase.result => _buildResultScreen(),
    },
  );

  Widget _buildBettingScreen() {
    final stakeOptions = <int>{
      horseRaceMinStake,
      1000,
      2000,
      math.min(horseRaceMaxStake, widget.availableCash),
    }.where((value) => value >= horseRaceMinStake).toList()..sort();
    return Scaffold(
      key: const Key('horse-race-betting-screen'),
      backgroundColor: const Color(0xFFF4F1F7),
      appBar: AppBar(
        toolbarHeight: 58,
        elevation: 0,
        backgroundColor: const Color(0xFF352D50),
        foregroundColor: Colors.white,
        titleSpacing: 12,
        shape: const Border(bottom: BorderSide(color: Color(0xFF241E38))),
        title: Row(
          children: [
            const _RaceHubEmblem(),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘의 경주',
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: -0.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '제6경주  ·  ${widget.race.postTime} 출발',
                  style: const TextStyle(
                    color: Color(0xFFD7D0E7),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A243F),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF554B75)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '₩',
                      style: TextStyle(
                        color: Color(0xFFFFD36F),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _money(widget.availableCash),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 188),
        children: [
          Container(
            key: const Key('horse-race-venue-hero'),
            height: 154,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFCFC8DC))),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  horseRaceBackgroundAsset,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.18),
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
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                      : '출전표',
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD8D2DF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120B0712),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  color: const Color(0xFFEEEAF3),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 39,
                        child: Text('마번', style: _boardHeaderStyle),
                      ),
                      Expanded(
                        child: Text('출전마 · 최근 3경주', style: _boardHeaderStyle),
                      ),
                      SizedBox(
                        width: 47,
                        child: Text(
                          '단승',
                          textAlign: TextAlign.center,
                          style: _boardHeaderStyle,
                        ),
                      ),
                      SizedBox(
                        width: 43,
                        child: Text(
                          '연승',
                          textAlign: TextAlign.center,
                          style: _boardHeaderStyle,
                        ),
                      ),
                    ],
                  ),
                ),
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
                  ),
                  if (index != widget.race.entrants.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEDE9F0),
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
              const SizedBox(height: 7),
              Row(
                children: [
                  for (var index = 0; index < stakeOptions.length; index++) ...[
                    Expanded(
                      child: _StakeCoinButton(
                        value: stakeOptions[index],
                        selected: _stake == stakeOptions[index],
                        enabled: stakeOptions[index] <= widget.availableCash,
                        onTap: () =>
                            setState(() => _stake = stakeOptions[index]),
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
                  onPressed: _canStart ? _startRace : null,
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
                      const Text(
                        '국가망 실시간 중계',
                        style: TextStyle(
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
            child: AnimatedBuilder(
              animation: _raceController,
              builder: (context, _) => _LiveHorseRaceTrack(
                race: widget.race,
                time: _raceController.value,
                selectedIds: <String>{_primaryHorseId, ?_secondaryHorseId},
                duration: widget.raceDuration,
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
        title: const Text(
          '제6경주 결과',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4C3E71), Color(0xFF76528D)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '우승',
                  style: TextStyle(
                    color: Color(0xFFFFD972),
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(
                  height: 105,
                  child: _GallopSprite(
                    key: const Key('horse-race-winner-sprite'),
                    asset: winner.spriteAsset,
                    frame: 6,
                    width: 176,
                    height: 105,
                  ),
                ),
                Text(
                  '${winner.gate}번 ${winner.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${winner.jockey} 기수 · ${winner.runningStyle} · 단승 ${winner.winOdds.toStringAsFixed(1)}배',
                  style: const TextStyle(
                    color: Color(0xFFD9EAE3),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
          const SizedBox(height: 14),
          const Text(
            '최종 순위',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          for (var index = 0; index < widget.race.finishOrder.length; index++)
            _FinishOrderRow(
              position: index + 1,
              entrant: widget.race.entrantById(widget.race.finishOrder[index]),
              selected:
                  widget.race.finishOrder[index] == _primaryHorseId ||
                  widget.race.finishOrder[index] == _secondaryHorseId,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: FilledButton.icon(
            key: const Key('horse-race-confirm-result'),
            onPressed: _finish,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4C3E71),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            icon: Icon(
              widget.previewMode ? Icons.replay_rounded : Icons.check_rounded,
            ),
            label: Text(
              widget.previewMode ? '중계 다시 보기' : '전자 마권 정산하기',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

class _RaceHubEmblem extends StatelessWidget {
  const _RaceHubEmblem();

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: const Color(0xFFE95778),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFFA4B7)),
    ),
    child: const Icon(Icons.sports_score, color: Colors.white, size: 19),
  );
}

class _StakeCoinButton extends StatelessWidget {
  const _StakeCoinButton({
    required this.value,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

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
          height: 36,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE95778) : const Color(0xFFF2EFF4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFFE95778)
                  : const Color(0xFFD9D4DE),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value >= 1000 ? '${value ~/ 1000}천' : '$value',
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF40384D),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
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
      height: 88,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C3E71), Color(0xFF6C5790)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF77669A)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -7,
            top: 8,
            width: 128,
            height: 78,
            child: Opacity(
              opacity: 0.96,
              child: _GallopSprite(
                asset: primary.spriteAsset,
                frame: 6,
                width: 128,
                height: 78,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: ColoredBox(color: Color(primary.accentValue)),
          ),
          Positioned(
            left: 13,
            top: 10,
            bottom: 10,
            right: 105,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(primary.accentValue),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xBBFFFFFF)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${primary.gate}',
                    style: TextStyle(
                      color: primary.gate == 1 || primary.gate == 5
                          ? const Color(0xFF252033)
                          : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 4),
                      Text(
                        paired
                            ? '복승 조합 선택 완료'
                            : '${primary.jockey} · ${primary.runningStyle} · 종합 ${primary.compositeScore.toStringAsFixed(1)} · 우승 ${(primary.winProbability * 100).toStringAsFixed(1)}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE1DAEC),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE95778),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '× ${primary.winOdds.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
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
    child: Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF4C3E71) : const Color(0xFFF3F0F5),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: selected ? const Color(0xFF4C3E71) : const Color(0xFFD8D2DF),
        ),
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
  });

  final HorseRaceEntrant entrant;
  final bool primary;
  final bool secondary;
  final HorseBetType betType;
  final VoidCallback onTap;

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
          height: 66,
          color: selected ? const Color(0xFFE8F7F0) : Colors.white,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                width: 4,
                color: selected ? const Color(0xFF2DAA78) : Colors.transparent,
              ),
              SizedBox(
                width: 42,
                child: Center(
                  child: Container(
                    width: 31,
                    height: 31,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color(entrant.accentValue),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFB9B3BF)),
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
              const SizedBox(width: 2),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
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
                          if (selected)
                            Container(
                              margin: const EdgeInsets.only(left: 5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2DAA78),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                betType == HorseBetType.quinella
                                    ? (primary ? 'A' : 'B')
                                    : '선택',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '${entrant.jockey} · ${entrant.runningStyle} · 최근 ${entrant.recentForm}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF766E7F),
                          fontSize: 8.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '종합 ${entrant.compositeScore.toStringAsFixed(1)} · 속${entrant.speed} 가${entrant.acceleration} 지${entrant.stamina} 막${entrant.finishingKick} 안${entrant.consistency}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFA099A7),
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 47,
                child: Text(
                  entrant.winOdds.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFFE54F71)
                        : const Color(0xFF443A54),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                width: 43,
                child: Text(
                  entrant.placeOdds.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF645A70),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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

class _LiveHorseRaceTrack extends StatelessWidget {
  const _LiveHorseRaceTrack({
    required this.race,
    required this.time,
    required this.selectedIds,
    required this.duration,
  });

  final HorseRaceCard race;
  final double time;
  final Set<String> selectedIds;
  final Duration duration;

  double _progress(HorseRaceEntrant entrant) {
    final rank = race.finishOrder.indexOf(entrant.id);
    // Keep the broadcast moving at race speed until the actual finish. The
    // former power curve made every runner visibly coast in the middle and
    // then left the winner frozen for the last fifth of the broadcast.
    final finishAt = 0.965 + rank * 0.0045;
    final base = (time / finishAt).clamp(0.0, 1.0);
    final phase = entrant.gate * 0.77;
    final stride =
        math.sin(time * math.pi * 13 + phase) *
        0.006 *
        (1 - time) *
        (1 + (90 - entrant.consistency) / 50);
    final style = switch (entrant.runningStyle) {
      '선행' => time < 0.56 ? 0.028 * math.sin(time * math.pi / 0.56) : 0.0,
      '추입' => time < 0.48 ? -0.018 * math.sin(time * math.pi / 0.48) : 0.0,
      '지구력' => 0.009 * math.sin(time * math.pi),
      _ => 0.0,
    };
    final normalizedTime = (time / finishAt).clamp(0.0, 1.0);
    final abilityEnvelope = math.sin(math.pi * normalizedTime);
    final abilityProfile =
        (entrant.acceleration - 85) *
            0.0008 *
            abilityEnvelope *
            (1 - normalizedTime) +
        (entrant.speed - 85) * 0.0005 * abilityEnvelope +
        (entrant.stamina - 85) * 0.0006 * abilityEnvelope * normalizedTime +
        (entrant.finishingKick - 85) *
            0.0007 *
            abilityEnvelope *
            normalizedTime *
            normalizedTime;
    return (base + stride + style + abilityProfile).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = <String, double>{
      for (final entrant in race.entrants) entrant.id: _progress(entrant),
    };
    final liveOrder = [
      ...race.entrants,
    ]..sort((left, right) => progress[right.id]!.compareTo(progress[left.id]!));
    final leader = liveOrder.first;
    final remaining = (race.distanceMeters * (1 - progress[leader.id]!))
        .round()
        .clamp(0, race.distanceMeters);
    final announcement = time < 0.045
        ? '출발했습니다! 8두가 일제히 게이트를 나섭니다.'
        : remaining > 700
        ? '${leader.name} 선두, 바깥쪽에서 ${liveOrder[1].name}이 따라붙습니다.'
        : remaining > 250
        ? '직선 중반! ${leader.name}, ${liveOrder[1].name}, ${liveOrder[2].name} 접전!'
        : remaining > 0
        ? '마지막 $remaining미터! 결승선 앞 전력 질주입니다!'
        : '결승선 통과! 공식 착순을 확인합니다.';

    // Broadcast-style hard cuts preserve the quality of both authored sprite
    // angles. The middle shot follows the pack through the bend; the start and
    // home straight stay on the original side camera.
    if (time >= 0.16 && time < 0.62) {
      return _CurveHorseRaceTrack(
        race: race,
        time: time,
        selectedIds: selectedIds,
        duration: duration,
        progress: progress,
        liveOrder: liveOrder,
        leader: leader,
        remaining: remaining,
        announcement: announcement,
      );
    }

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
        final leaderProgress = progress[leader.id]!;
        final startAnchor = spriteWidth * 0.92 + 4;
        final cruiseAnchor = width * 0.63;
        final finishX = width - 32;
        // Pan the world at a constant rate. Once the final panorama is fully
        // in view the camera locks, so the finish line stays planted in the
        // dirt while the field runs through it.
        final cameraProgress = ((time - 0.08) / 0.68).clamp(0.0, 1.0);
        final backgroundWidth = math.max(width, height * 1774 / 887);
        final backgroundTravel = math.max(0.0, backgroundWidth - width);
        final backgroundOffset = -backgroundTravel * cameraProgress;
        final finishLineX = backgroundWidth - 32 + backgroundOffset;
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
            CustomPaint(
              painter: _TrackSpeedPainter(
                time: time,
                trackTop: laneTop,
                trackBottom: laneTop + laneHeight * race.entrants.length,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xE6352D50),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0x779C8BBD)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_rounded,
                      size: 11,
                      color: Color(0xFFFF9AAF),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '국가망 중계',
                      style: TextStyle(
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
            Positioned(
              key: const Key('horse-race-fixed-finish-line'),
              left: finishLineX - 8,
              top: laneTop - 10,
              height: laneHeight * race.entrants.length + 24,
              width: 18,
              child: const CustomPaint(painter: _FinishLinePainter()),
            ),
            for (var index = 0; index < race.entrants.length; index++)
              _buildRunner(
                race.entrants[index],
                index: index,
                laneTop: laneTop,
                laneHeight: laneHeight,
                spriteWidth: spriteWidth,
                spriteHeight: spriteHeight,
                startAnchor: startAnchor,
                cruiseAnchor: cruiseAnchor,
                finishX: finishX,
                leaderProgress: leaderProgress,
                progress: progress[race.entrants[index].id]!,
              ),
            if (time < 0.09)
              Positioned(
                left: startAnchor - spriteWidth * 0.92 - 5,
                top: laneTop - 3,
                width: 30,
                height: laneHeight * race.entrants.length + 12,
                child: CustomPaint(
                  painter: _StartingGatePainter(
                    opening: (time / 0.09).clamp(0.0, 1.0),
                  ),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 14,
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
    required double startAnchor,
    required double cruiseAnchor,
    required double finishX,
    required double leaderProgress,
    required double progress,
  }) {
    final launch = Curves.easeOutCubic.transform(
      (leaderProgress / 0.2).clamp(0.0, 1.0),
    );
    final packAnchor = ui.lerpDouble(startAnchor, cruiseAnchor, launch)!;
    final packPoint =
        packAnchor + (progress - leaderProgress) * cruiseAnchor * 1.35;
    // The home straight must not drop into a second ease-in phase: that read
    // as an unintended slow-motion shot halfway through the race.
    final finishRun = ((progress - 0.78) / 0.22).clamp(0.0, 1.0);
    final racePoint = ui.lerpDouble(packPoint, finishX + 8, finishRun)!;
    final left = racePoint - spriteWidth * 0.92;
    final strideFrames = math.max(1, duration.inMilliseconds ~/ 70);
    final frame = ((time * strideFrames + entrant.gate * 0.7).floor()) % 8;
    final bob = math.sin(time * math.pi * 26 + entrant.gate) * 0.8;
    final selected = selectedIds.contains(entrant.id);
    return Positioned(
      key: Key('horse-live-${entrant.id}'),
      left: left,
      top: laneTop + index * laneHeight + (laneHeight - spriteHeight) / 2 + bob,
      width: spriteWidth,
      height: spriteHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
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
          if (time > 0.05 && progress < 0.99)
            Positioned(
              left: -6,
              bottom: 0,
              child: _HorseDust(
                phase: time * 18 + entrant.gate,
                color: const Color(0x99DAB783),
              ),
            ),
          _GallopSprite(
            asset: entrant.spriteAsset,
            frame: frame,
            width: spriteWidth,
            height: spriteHeight,
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
                    ? const [BoxShadow(color: Color(0xAAFFD76D), blurRadius: 7)]
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
    );
  }
}

Offset _curveLanePoint(Size size, double lane, double progress) {
  final t = progress.clamp(0.0, 1.0);
  final start = Offset(size.width * (0.135 + lane * 0.106), size.height * 0.91);
  final control = Offset(
    size.width * (0.22 + lane * 0.070),
    size.height * 0.60,
  );
  final end = Offset(size.width * (0.33 + lane * 0.042), size.height * 0.30);
  final inverse = 1 - t;
  return Offset(
    inverse * inverse * start.dx +
        2 * inverse * t * control.dx +
        t * t * end.dx,
    inverse * inverse * start.dy +
        2 * inverse * t * control.dy +
        t * t * end.dy,
  );
}

class _CurveHorseRaceTrack extends StatelessWidget {
  const _CurveHorseRaceTrack({
    required this.race,
    required this.time,
    required this.selectedIds,
    required this.duration,
    required this.progress,
    required this.liveOrder,
    required this.leader,
    required this.remaining,
    required this.announcement,
  });

  final HorseRaceCard race;
  final double time;
  final Set<String> selectedIds;
  final Duration duration;
  final Map<String, double> progress;
  final List<HorseRaceEntrant> liveOrder;
  final HorseRaceEntrant leader;
  final int remaining;
  final String announcement;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final size = Size(width, height);
      final curveTime = ((time - 0.16) / 0.46).clamp(0.0, 1.0);
      final leaderProgress = progress[leader.id]!;
      final strideFrames = math.max(1, duration.inMilliseconds ~/ 70);
      final placements = <MapEntry<double, Widget>>[];

      for (var index = 0; index < race.entrants.length; index++) {
        final entrant = race.entrants[index];
        // Every runner stays on the exact center curve of its own lane. Race
        // order only changes how far along that curve the runner has travelled.
        final raceGap = (progress[entrant.id]! - leaderProgress) * 2.1;
        final laneProgress = (0.08 + curveTime * 0.74 + raceGap).clamp(
          0.04,
          0.86,
        );
        final point = _curveLanePoint(size, index + 0.5, laneProgress);
        final perspective = ui.lerpDouble(1.0, 0.57, laneProgress)!;
        final spriteHeight =
            math.min(height * 0.18, width * 0.245) * perspective;
        final spriteWidth = spriteHeight * 0.92;
        final frame = ((time * strideFrames + entrant.gate * 0.7).floor()) % 8;
        final selected = selectedIds.contains(entrant.id);
        placements.add(
          MapEntry(
            point.dy,
            Positioned(
              key: Key('horse-curve-${entrant.id}'),
              left: point.dx - spriteWidth * 0.5,
              top: point.dy - spriteHeight * 0.82,
              width: spriteWidth,
              height: spriteHeight,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: spriteWidth * 0.18,
                    bottom: 1,
                    child: Container(
                      width: spriteWidth * 0.62,
                      height: math.max(2.0, spriteHeight * 0.045),
                      decoration: BoxDecoration(
                        color: const Color(0x4D14250E),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                  _GallopSprite(
                    asset: horseRaceCurveGallopAssetFor(entrant.spriteAsset),
                    frame: frame,
                    width: spriteWidth,
                    height: spriteHeight,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: math.max(15.0, spriteWidth * 0.22),
                      height: math.max(15.0, spriteWidth * 0.22),
                      decoration: BoxDecoration(
                        color: Color(entrant.accentValue),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFFFD76D)
                              : const Color(0xCCFFFFFF),
                          width: selected ? 2.5 : 1,
                        ),
                        boxShadow: selected
                            ? const [
                                BoxShadow(
                                  color: Color(0xAAFFD76D),
                                  blurRadius: 7,
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
                            fontSize: math.max(7.0, spriteWidth * 0.09),
                            fontWeight: FontWeight.w900,
                          ),
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
      // Distant runners paint first so converging lanes overlap naturally.
      placements.sort((left, right) => left.key.compareTo(right.key));

      return Stack(
        key: const Key('horse-race-live-track'),
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            key: const Key('horse-race-curve-track'),
            child: Image.asset(
              horseRaceCurveTrackAsset,
              key: const Key('horse-race-curve-background'),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              cacheWidth: 1600,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x12000000),
                  Color(0x02000000),
                  Color(0x4513250D),
                ],
              ),
            ),
          ),
          const CustomPaint(painter: _BroadcastScanlinePainter()),
          CustomPaint(
            key: const Key('horse-race-curve-lanes'),
            painter: _CurveLanePainter(laneCount: race.entrants.length),
          ),
          for (final placement in placements) placement.value,
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
                          '선두 ${leader.name}',
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
                            value: leaderProgress,
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
                    '남은 $remaining m',
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
              key: const Key('horse-race-camera-label'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xE6352D50),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0x779C8BBD)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam_rounded,
                    size: 11,
                    color: Color(0xFFFFD972),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '3코너 · 후방 카메라',
                    style: TextStyle(
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
          Positioned(
            left: 10,
            right: 10,
            bottom: 14,
            child: Container(
              key: const Key('horse-race-announcer'),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
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

class _CurveLanePainter extends CustomPainter {
  const _CurveLanePainter({required this.laneCount});

  final int laneCount;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = const Color(0x2E254411)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4;
    final highlight = Paint()
      ..color = const Color(0xA6FFF5D5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var lane = 0; lane <= laneCount; lane++) {
      final start = _curveLanePoint(size, lane.toDouble(), 0);
      final control = Offset(
        size.width * (0.22 + lane * 0.070),
        size.height * 0.60,
      );
      final end = _curveLanePoint(size, lane.toDouble(), 1);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(path.shift(const Offset(0, 1.2)), shadow);
      canvas.drawPath(path, highlight);
    }
  }

  @override
  bool shouldRepaint(covariant _CurveLanePainter oldDelegate) =>
      oldDelegate.laneCount != laneCount;
}

class _GallopSprite extends StatelessWidget {
  const _GallopSprite({
    super.key,
    required this.asset,
    required this.frame,
    required this.width,
    required this.height,
  });

  final String asset;
  final int frame;
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
        return CustomPaint(
          key: Key('horse-frame-${asset.hashCode}-${frame % 8}'),
          painter: _HorseFramePainter(
            image: sheet.image,
            sourceRect: sheet.sourceFrames[frame % 8],
            frame: frame % 8,
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
    required this.frame,
  });

  final ui.Image image;
  final Rect sourceRect;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    final fitted = applyBoxFit(BoxFit.contain, sourceRect.size, size);
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    canvas.drawImageRect(
      image,
      sourceRect,
      destination,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _HorseFramePainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.image != image ||
      oldDelegate.sourceRect != sourceRect;
}

class _HorseDust extends StatelessWidget {
  const _HorseDust({required this.phase, required this.color});

  final double phase;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 28,
    height: 16,
    child: Stack(
      children: List.generate(5, (index) {
        final drift = (phase * 7 + index * 9) % 18;
        return Positioned(
          left: 20 - drift,
          bottom: 1 + index % 3 * 3,
          child: Container(
            width: 3.5 + index % 2 * 2,
            height: 3.5 + index % 2 * 2,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.72 - index * 0.09),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    ),
  );
}

class _TrackSpeedPainter extends CustomPainter {
  const _TrackSpeedPainter({
    required this.time,
    required this.trackTop,
    required this.trackBottom,
  });

  final double time;
  final double trackTop;
  final double trackBottom;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x22FFF3D5)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 30; index++) {
      final x = ((index * 53.0 - time * size.width * 5) % size.width);
      final y = ui.lerpDouble(
        trackTop + 4,
        trackBottom - 4,
        (index % 12) / 11,
      )!;
      canvas.drawLine(Offset(x, y), Offset(x + 18, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrackSpeedPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.trackTop != trackTop ||
      oldDelegate.trackBottom != trackBottom;
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

class _FinishLinePainter extends CustomPainter {
  const _FinishLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const rows = 20;
    const columns = 2;
    final cellHeight = size.height / rows;
    final cellWidth = size.width / columns;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        canvas.drawRect(
          Rect.fromLTWH(
            column * cellWidth,
            row * cellHeight,
            cellWidth,
            cellHeight,
          ),
          Paint()
            ..color = (row + column).isEven
                ? Colors.white
                : const Color(0xFF1C2A27),
        );
      }
    }
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

class _FinishOrderRow extends StatelessWidget {
  const _FinishOrderRow({
    required this.position,
    required this.entrant,
    required this.selected,
  });

  final int position;
  final HorseRaceEntrant entrant;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFFE8F7F0) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: selected ? const Color(0xFF2DAA78) : const Color(0xFFD8D2DF),
      ),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(
            '$position위',
            style: TextStyle(
              color: position == 1 ? const Color(0xFFB98100) : _ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Color(entrant.accentValue),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0x33000000)),
          ),
          child: Center(
            child: Text(
              '${entrant.gate}',
              style: TextStyle(
                color: entrant.gate == 1 || entrant.gate == 5
                    ? const Color(0xFF202A26)
                    : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            entrant.name,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          entrant.jockey,
          style: const TextStyle(
            color: Color(0xFF6D766F),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
