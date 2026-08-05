part of 'main.dart';

const _newspaperDeliveryTargetCount = 7;
const _newspaperSteeringSlotCount = 10;
const _newspaperCyclistAsset =
    'assets/images/minigames/rider_newspaper_cyclist_rear_v2.png';
const _newspaperPuddleAsset =
    'assets/images/minigames/obstacle_puddle_winter_v2.png';
const _newspaperCrateAsset =
    'assets/images/minigames/obstacle_wood_crate_v2.png';
const _newspaperTrashBagsAsset =
    'assets/images/minigames/obstacle_trash_bags_v2.png';

int calculateNewspaperDeliveryScore({
  required int delivered,
  required int totalTargets,
  required int accuracyTotal,
  required int bestCombo,
  required int collisions,
}) {
  if (totalTargets <= 0) return 0;
  final safeDelivered = delivered.clamp(0, totalTargets);
  final coverage = safeDelivered / totalTargets;
  final averageAccuracy = safeDelivered == 0
      ? 0.0
      : (accuracyTotal / safeDelivered).clamp(0.0, 100.0);
  final comboRate = (bestCombo / totalTargets).clamp(0.0, 1.0);
  final safety = math.max(0, 5 - collisions * 2);
  return (coverage * 50 + averageAccuracy * 0.30 + comboRate * 15 + safety)
      .round()
      .clamp(0, 100);
}

enum _RiderPhase { ready, running, complete }

enum _RiderObstacleKind { puddle, crate, trashBag }

class _RiderObstacle {
  _RiderObstacle({required this.id, required this.slot, required this.kind});

  final int id;
  final int slot;
  final _RiderObstacleKind kind;
  double y = -0.14;
  bool resolved = false;
}

class _NewspaperTarget {
  _NewspaperTarget({required this.id, required this.side});

  final int id;
  final int side;
  double y = -0.12;
  bool delivered = false;
  bool missed = false;
}

class _ThrownNewspaper {
  _ThrownNewspaper({
    required this.id,
    required this.fromSlot,
    required this.toSide,
    required this.targetY,
  });

  final int id;
  final int fromSlot;
  final int toSide;
  final double targetY;
  double progress = 0;
}

class RiderMiniGame extends StatefulWidget {
  const RiderMiniGame({
    super.key,
    this.courseDuration = const Duration(seconds: 34),
    this.spawnObstacles = true,
    this.autoDeliverTargets = false,
    this.randomSeed = 20000102,
  });

  final Duration courseDuration;
  final bool spawnObstacles;
  final bool autoDeliverTargets;
  final int randomSeed;

  @override
  State<RiderMiniGame> createState() => _RiderMiniGameState();
}

class _RiderMiniGameState extends State<RiderMiniGame> {
  static const _tick = Duration(milliseconds: 50);
  static const _targetFractions = <double>[
    0.08,
    0.21,
    0.34,
    0.48,
    0.62,
    0.76,
    0.89,
  ];
  late math.Random _random;
  Timer? _timer;
  _RiderPhase _phase = _RiderPhase.ready;
  final List<_RiderObstacle> _obstacles = <_RiderObstacle>[];
  final List<_NewspaperTarget> _targets = <_NewspaperTarget>[];
  final List<_ThrownNewspaper> _papers = <_ThrownNewspaper>[];
  int _playerSlot = _newspaperSteeringSlotCount ~/ 2;
  int _nextObjectId = 0;
  int _nextTarget = 0;
  int _delivered = 0;
  int _missed = 0;
  int _accuracyTotal = 0;
  int _perfects = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _collisions = 0;
  int _rawScore = 0;
  double _elapsedSeconds = 0;
  double _spawnCooldown = 0.8;
  double _invulnerableSeconds = 0;
  double _throwCooldown = 0;
  double _feedbackSeconds = 0;
  String _banner = '새벽 첫 배달을 준비해요';
  String _feedback = '';
  Color _feedbackColor = const Color(0xFFFFD66B);

  double get _courseSeconds =>
      math.max(0.25, widget.courseDuration.inMilliseconds / 1000);
  double get _progress => (_elapsedSeconds / _courseSeconds).clamp(0.0, 1.0);
  int get _remainingSeconds =>
      math.max(0, (_courseSeconds - _elapsedSeconds).ceil());
  int get _papersRemaining =>
      math.max(0, _newspaperDeliveryTargetCount - _delivered - _missed);
  int get _finalScore => calculateNewspaperDeliveryScore(
    delivered: _delivered,
    totalTargets: _newspaperDeliveryTargetCount,
    accuracyTotal: _accuracyTotal,
    bestCombo: _bestCombo,
    collisions: _collisions,
  );

  @override
  void initState() {
    super.initState();
    _random = math.Random(widget.randomSeed);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    GameAudio.instance.playSfx(GameSfx.raceBell, volumeScale: 0.75);
    setState(() {
      _random = math.Random(widget.randomSeed);
      _phase = _RiderPhase.running;
      _obstacles.clear();
      _targets.clear();
      _papers.clear();
      _playerSlot = _newspaperSteeringSlotCount ~/ 2;
      _nextObjectId = 0;
      _nextTarget = 0;
      _delivered = 0;
      _missed = 0;
      _accuracyTotal = 0;
      _perfects = 0;
      _combo = 0;
      _bestCombo = 0;
      _collisions = 0;
      _rawScore = 0;
      _elapsedSeconds = 0;
      _spawnCooldown = 0.8;
      _invulnerableSeconds = 0;
      _throwCooldown = 0;
      _feedbackSeconds = 0;
      _banner = '빛나는 우편함 쪽으로 이동!';
      _feedback = '';
    });
    HapticFeedback.mediumImpact();
    _timer = Timer.periodic(_tick, (_) => _advance());
  }

  void _advance() {
    if (!mounted || _phase != _RiderPhase.running) return;
    const dt = 0.05;
    var collided = false;
    var completed = false;
    setState(() {
      _elapsedSeconds += dt;
      _rawScore += 3 + _combo * 2;
      _spawnCooldown -= dt;
      _invulnerableSeconds = math.max(0, _invulnerableSeconds - dt);
      _throwCooldown = math.max(0, _throwCooldown - dt);
      _feedbackSeconds = math.max(0, _feedbackSeconds - dt);

      while (_nextTarget < _targetFractions.length &&
          _progress >= _targetFractions[_nextTarget]) {
        _spawnDeliveryTarget();
        _nextTarget++;
      }

      if (widget.spawnObstacles && _spawnCooldown <= 0) {
        _spawnObstacle();
        _spawnCooldown = 1.05 + _random.nextDouble() * 0.65;
      }

      final speed = 0.33 + _progress * 0.12;
      for (final target in _targets) {
        target.y += speed * dt;
        if (!target.delivered && !target.missed && target.y > 0.98) {
          target.missed = true;
          _missed++;
          _combo = 0;
          _banner = '놓쳤어요 · 다음 우편함에 집중!';
          _showFeedback('MISS', const Color(0xFFFF8A83));
        }
      }
      _targets.removeWhere((target) => target.y > 1.14);

      for (final obstacle in _obstacles) {
        obstacle.y += speed * dt;
        if (!obstacle.resolved &&
            _invulnerableSeconds <= 0 &&
            (obstacle.slot - _playerSlot).abs() <= 1 &&
            obstacle.y >= 0.78 &&
            obstacle.y <= 0.91) {
          obstacle.resolved = true;
          _collisions++;
          _combo = 0;
          _elapsedSeconds = math.min(_courseSeconds, _elapsedSeconds + 1.4);
          _invulnerableSeconds = 0.9;
          _banner = '조심! 충돌로 1.4초 손실';
          _showFeedback('-1.4초', const Color(0xFFFF8A83));
          collided = true;
        }
      }
      _obstacles.removeWhere((obstacle) => obstacle.y > 1.1);

      for (final paper in _papers) {
        paper.progress += dt * 4.6;
      }
      _papers.removeWhere((paper) => paper.progress >= 1);

      if (_elapsedSeconds >= _courseSeconds) completed = true;
    });
    if (collided) {
      HapticFeedback.heavyImpact();
      GameAudio.instance.playSfx(GameSfx.impactMetal);
    }
    if (completed) _complete();
  }

  void _spawnDeliveryTarget() {
    final side = _nextTarget.isEven ? -1 : 1;
    final target = _NewspaperTarget(id: _nextObjectId++, side: side);
    _targets.add(target);
    _banner = side < 0 ? '왼쪽 우편함 준비!' : '오른쪽 우편함 준비!';
    if (widget.autoDeliverTargets) {
      target.delivered = true;
      _delivered++;
      _accuracyTotal += 100;
      _perfects++;
      _combo++;
      _bestCombo = math.max(_bestCombo, _combo);
    }
  }

  void _spawnObstacle() {
    final slotsNearTop = _obstacles
        .where((obstacle) => obstacle.y < 0.18)
        .expand(
          (obstacle) => <int>[
            obstacle.slot - 1,
            obstacle.slot,
            obstacle.slot + 1,
          ],
        )
        .toSet();
    final available = List<int>.generate(
      _newspaperSteeringSlotCount,
      (index) => index,
    ).where((slot) => !slotsNearTop.contains(slot)).toList();
    if (available.length <= 3) return;
    final kinds = _RiderObstacleKind.values;
    _obstacles.add(
      _RiderObstacle(
        id: _nextObjectId++,
        slot: available[_random.nextInt(available.length)],
        kind: kinds[_random.nextInt(kinds.length)],
      ),
    );
  }

  void _throwNewspaper({int? chosenSide, double power = 0.74}) {
    if (_phase != _RiderPhase.running || _throwCooldown > 0) return;
    GameAudio.instance.playSfx(GameSfx.paperRustle);
    final visibleTargets = _targets
        .where(
          (target) =>
              !target.delivered &&
              !target.missed &&
              target.y >= 0.48 &&
              target.y <= 0.97,
        )
        .toList();
    final candidates =
        visibleTargets
            .where((target) => chosenSide == null || target.side == chosenSide)
            .toList()
          ..sort((a, b) => (a.y - 0.76).abs().compareTo((b.y - 0.76).abs()));
    setState(() {
      _throwCooldown = 0.22;
      if (candidates.isEmpty) {
        final missY = visibleTargets.isEmpty ? 0.72 : visibleTargets.first.y;
        _papers.add(
          _ThrownNewspaper(
            id: _nextObjectId++,
            fromSlot: _playerSlot,
            toSide:
                chosenSide ??
                (_playerSlot < _newspaperSteeringSlotCount / 2 ? -1 : 1),
            targetY: missY,
          ),
        );
        _combo = 0;
        _banner = visibleTargets.isEmpty
            ? '우편함이 타이밍 선에 올 때 플릭해요'
            : '반대쪽으로 던졌어요 · 방향을 확인!';
        _showFeedback(
          visibleTargets.isEmpty ? '조금만 기다려요' : '방향 MISS',
          const Color(0xFFFFA09A),
        );
        return;
      }
      final target = candidates.first;
      final timingDistance = (target.y - 0.76).abs();
      final timingScore = timingDistance <= 0.065
          ? 100
          : timingDistance <= 0.13
          ? 86
          : timingDistance <= 0.21
          ? 68
          : 48;
      final horizontalFraction =
          _playerSlot / (_newspaperSteeringSlotCount - 1);
      final edgeCloseness = target.side < 0
          ? 1 - horizontalFraction
          : horizontalFraction;
      final laneFactor = 0.48 + edgeCloseness * 0.52;
      final safePower = power.clamp(0.35, 1.0);
      final powerFactor = (1.0 - (safePower - 0.74).abs() * 0.72).clamp(
        0.66,
        1.0,
      );
      final accuracy = (timingScore * laneFactor * powerFactor).round().clamp(
        0,
        100,
      );
      _papers.add(
        _ThrownNewspaper(
          id: _nextObjectId++,
          fromSlot: _playerSlot,
          toSide: target.side,
          targetY: target.y,
        ),
      );
      if (accuracy < 50) {
        _combo = 0;
        _banner = '방향이 멀어요 · 우편함 쪽 차선으로!';
        _showFeedback('빗나감', const Color(0xFFFFA09A));
        return;
      }
      target.delivered = true;
      _delivered++;
      _accuracyTotal += accuracy;
      _combo++;
      _bestCombo = math.max(_bestCombo, _combo);
      _rawScore += accuracy * 12 + _combo * 180;
      if (accuracy >= 96) {
        _perfects++;
        _banner = '문틈 한가운데! $_combo연속 배달';
        _showFeedback('PERFECT', const Color(0xFFFFD66B));
      } else if (accuracy >= 78) {
        _banner = '깔끔한 배달! $_combo연속';
        _showFeedback('GREAT', const Color(0xFF83E2C0));
      } else {
        _banner = '도착했어요 · 다음 집 준비';
        _showFeedback('GOOD', const Color(0xFF9FC8FF));
      }
    });
    HapticFeedback.lightImpact();
  }

  void _showFeedback(String text, Color color) {
    _feedback = text;
    _feedbackColor = color;
    _feedbackSeconds = 0.72;
  }

  void _moveTo(int slot) {
    if (_phase != _RiderPhase.running) return;
    final next = slot.clamp(0, _newspaperSteeringSlotCount - 1);
    if (next == _playerSlot) return;
    setState(() {
      _playerSlot = next;
      _banner = '조향 위치 ${next + 1}/$_newspaperSteeringSlotCount · 우편함을 확인해요';
    });
    HapticFeedback.selectionClick();
  }

  int _slotForX(double x, double width) {
    if (width <= 0) return _playerSlot;
    final fraction = (x / width).clamp(0.0, 0.999999);
    return (fraction * _newspaperSteeringSlotCount).floor();
  }

  void _handleDragUpdate(DragUpdateDetails details, double width) {
    _moveTo(_slotForX(details.localPosition.dx, width));
  }

  void _handleTap(TapUpDetails details, double width) {
    _moveTo(_slotForX(details.localPosition.dx, width));
  }

  void _complete() {
    _timer?.cancel();
    if (!mounted || _phase == _RiderPhase.complete) return;
    setState(() {
      _phase = _RiderPhase.complete;
      _banner = '새벽 배달 마감!';
    });
    HapticFeedback.mediumImpact();
    GameAudio.instance.playSfx(GameSfx.confirm);
  }

  @override
  Widget build(BuildContext context) {
    return _MiniGameShell(
      title: '새벽 신문배달',
      subtitle: '2000년 1월 · 강남 주택가 · 조간 7부',
      backgroundAsset: weekendNewspaperDeliveryAsset,
      progress: _phase == _RiderPhase.complete ? 1 : _progress,
      child: _phase == _RiderPhase.complete
          ? _MiniGameResult(
              activityId: 'newspaper_delivery',
              score: _finalScore,
              title: _finalScore >= 92
                  ? '골목의 완벽한 아침!'
                  : _finalScore >= 72
                  ? '조간 배달 완료!'
                  : '첫 노선을 마쳤어요',
              detail:
                  '배달 $_delivered/$_newspaperDeliveryTargetCount · 퍼펙트 $_perfects회 · 최고 콤보 $_bestCombo · 충돌 $_collisions회\n예상 기본 수당 ${900 + _finalScore * 16}원',
            )
          : Column(
              children: [
                _NewspaperDeliveryHud(
                  remainingSeconds: _remainingSeconds,
                  delivered: _delivered,
                  papersRemaining: _papersRemaining,
                  combo: _combo,
                  rawScore: _rawScore,
                  banner: _banner,
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return GestureDetector(
                      key: const Key('newspaper-road'),
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (details) =>
                          _handleDragUpdate(details, width),
                      onTapUp: (details) => _handleTap(details, width),
                      child: _NewspaperDeliveryRoad(
                        playerSlot: _playerSlot,
                        obstacles: _obstacles,
                        targets: _targets,
                        papers: _papers,
                        progress: _progress,
                        invulnerable: _invulnerableSeconds > 0,
                        feedback: _feedbackSeconds > 0 ? _feedback : '',
                        feedbackColor: _feedbackColor,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _NewspaperControls(
                  enabled: _phase == _RiderPhase.running,
                  onLeft: () => _moveTo(_playerSlot - 1),
                  onThrow: (side, power) =>
                      _throwNewspaper(chosenSide: side, power: power),
                  onRight: () => _moveTo(_playerSlot + 1),
                ),
                if (_phase == _RiderPhase.ready) ...[
                  const SizedBox(height: 8),
                  _NewspaperStartCard(onStart: _start),
                ],
              ],
            ),
    );
  }
}

class _NewspaperDeliveryHud extends StatelessWidget {
  const _NewspaperDeliveryHud({
    required this.remainingSeconds,
    required this.delivered,
    required this.papersRemaining,
    required this.combo,
    required this.rawScore,
    required this.banner,
  });

  final int remainingSeconds;
  final int delivered;
  final int papersRemaining;
  final int combo;
  final int rawScore;
  final String banner;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('newspaper-hud'),
    padding: const EdgeInsets.fromLTRB(11, 8, 11, 7),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xF2182945), Color(0xF2293D63)],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0x55FFFFFF)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x44000000),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            _DeliveryHudChip(
              icon: Icons.timer_rounded,
              label: '$remainingSeconds초',
              color: const Color(0xFFFFD66B),
            ),
            const SizedBox(width: 5),
            _DeliveryHudChip(
              icon: Icons.newspaper_rounded,
              label: '$delivered/$_newspaperDeliveryTargetCount',
              color: const Color(0xFF83E2C0),
            ),
            const SizedBox(width: 5),
            _DeliveryHudChip(
              icon: Icons.inventory_2_rounded,
              label: '남은 $papersRemaining',
              color: const Color(0xFFB9CFFF),
            ),
            const Spacer(),
            Text(
              '$rawScore',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (combo > 1) ...[
              const SizedBox(width: 5),
              Text(
                '×$combo',
                key: const Key('newspaper-combo'),
                style: const TextStyle(
                  color: Color(0xFFFFD66B),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Text(
          banner,
          key: const Key('rider-banner'),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFF2F6FF),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _DeliveryHudChip extends StatelessWidget {
  const _DeliveryHudChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _NewspaperDeliveryRoad extends StatelessWidget {
  const _NewspaperDeliveryRoad({
    required this.playerSlot,
    required this.obstacles,
    required this.targets,
    required this.papers,
    required this.progress,
    required this.invulnerable,
    required this.feedback,
    required this.feedbackColor,
  });

  final int playerSlot;
  final List<_RiderObstacle> obstacles;
  final List<_NewspaperTarget> targets;
  final List<_ThrownNewspaper> papers;
  final double progress;
  final bool invulnerable;
  final String feedback;
  final Color feedbackColor;

  static const double height = 372;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('rider-course'),
    height: height,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF17243C),
      borderRadius: BorderRadius.circular(27),
      border: Border.all(color: const Color(0xFFFFE29A), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 20,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const cyclistWidth = 104.0;
        const obstacleWidth = 54.0;
        final playerX = _slotX(
          playerSlot,
          width,
          horizontalInset: cyclistWidth / 2,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              weekendNewspaperDeliveryAsset,
              key: const Key('newspaper-background'),
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.high,
              cacheWidth: 720,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.45, 1],
                  colors: [
                    Color(0x0A08111F),
                    Color(0x16101E36),
                    Color(0x75101B30),
                  ],
                ),
              ),
            ),
            CustomPaint(painter: _RoadMotionPainter(progress: progress)),
            for (final target in targets)
              Positioned(
                key: ValueKey('newspaper-target-${target.id}'),
                left: target.side < 0 ? 3 : null,
                right: target.side > 0 ? 3 : null,
                top: -28 + target.y * height,
                child: _NewspaperTargetView(target: target),
              ),
            for (final obstacle in obstacles)
              Positioned(
                key: ValueKey('rider-obstacle-${obstacle.id}'),
                left:
                    _slotX(
                      obstacle.slot,
                      width,
                      horizontalInset: obstacleWidth / 2,
                    ) -
                    obstacleWidth / 2,
                top: -36 + obstacle.y * height,
                child: _DeliveryObstacleView(obstacle: obstacle),
              ),
            for (final paper in papers)
              _PaperFlight(
                key: ValueKey('newspaper-flight-${paper.id}'),
                paper: paper,
                roadWidth: width,
              ),
            AnimatedPositioned(
              key: const Key('rider-player'),
              duration: const Duration(milliseconds: 82),
              curve: Curves.easeOutCubic,
              left: playerX - cyclistWidth / 2,
              bottom: 4,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: invulnerable ? 0.52 : 1,
                child: _DeliveryCyclist(slot: playerSlot),
              ),
            ),
            Positioned(
              left: 64,
              right: 64,
              top: 8,
              child: _SteeringSlotRail(activeSlot: playerSlot),
            ),
            if (feedback.isNotEmpty)
              Positioned(
                key: const Key('newspaper-feedback'),
                left: 0,
                right: 0,
                top: 118,
                child: Center(
                  child: Transform.rotate(
                    angle: -0.035,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xE8182945),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: feedbackColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: feedbackColor.withValues(alpha: 0.45),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Text(
                        feedback,
                        style: TextStyle(
                          color: feedbackColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: progress,
                  backgroundColor: const Color(0x55081220),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD66B)),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  static double _slotX(
    int slot,
    double width, {
    required double horizontalInset,
  }) {
    final safeWidth = math.max(0.0, width - horizontalInset * 2);
    final fraction =
        slot.clamp(0, _newspaperSteeringSlotCount - 1) /
        (_newspaperSteeringSlotCount - 1);
    return horizontalInset + safeWidth * fraction;
  }
}

class _SteeringSlotRail extends StatelessWidget {
  const _SteeringSlotRail({required this.activeSlot});

  final int activeSlot;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '자전거 조향 위치 ${activeSlot + 1} / $_newspaperSteeringSlotCount',
    child: Container(
      key: Key('rider-steering-$activeSlot'),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xB3192A43),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x44FFFFFF)),
      ),
      child: Row(
        children: List.generate(
          _newspaperSteeringSlotCount,
          (index) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: index == activeSlot
                    ? const Color(0xFFFFD66B)
                    : const Color(0x558FA9C4),
                borderRadius: BorderRadius.circular(99),
                boxShadow: index == activeSlot
                    ? const [BoxShadow(color: Color(0xAAFFD66B), blurRadius: 5)]
                    : null,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoadMotionPainter extends CustomPainter {
  const _RoadMotionPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final timingY = size.height * 0.76;
    final timingPaint = Paint()
      ..color = const Color(0x66FFE18B)
      ..strokeWidth = 1.5;
    for (var x = 18.0; x < size.width - 18; x += 18) {
      canvas.drawLine(Offset(x, timingY), Offset(x + 9, timingY), timingPaint);
    }
    final snowPaint = Paint()..color = const Color(0x55FFFFFF);
    for (var i = 0; i < 16; i++) {
      final baseX = ((i * 71.0 + 23) % size.width);
      final y = ((i * 43.0 + progress * size.height * 2.4) % size.height);
      canvas.drawCircle(Offset(baseX, y), i.isEven ? 1.1 : 1.7, snowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadMotionPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _NewspaperTargetView extends StatelessWidget {
  const _NewspaperTargetView({required this.target});

  final _NewspaperTarget target;

  @override
  Widget build(BuildContext context) {
    final active = !target.delivered && !target.missed;
    return Semantics(
      label: target.side < 0 ? '왼쪽 신문 우편함' : '오른쪽 신문 우편함',
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 130),
        opacity: active ? 1 : 0.28,
        child: Container(
          width: 58,
          height: 54,
          decoration: BoxDecoration(
            color: active ? const Color(0xE920385A) : const Color(0x99323A48),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: active ? const Color(0xFFFFDC78) : const Color(0x66FFFFFF),
              width: 2,
            ),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0xAAFFD66B),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                key: const Key('newspaper-mailbox-painter'),
                size: const Size(38, 38),
                painter: _MailboxPainter(delivered: target.delivered),
              ),
              if (active)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8A83),
                      shape: BoxShape.circle,
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

class _MailboxPainter extends CustomPainter {
  const _MailboxPainter({required this.delivered});

  final bool delivered;

  @override
  void paint(Canvas canvas, Size size) {
    final post = Paint()..color = const Color(0xFF324861);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.44, size.height * 0.55, 5, 16),
        const Radius.circular(2),
      ),
      post,
    );
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 7, size.width - 6, 23),
      const Radius.circular(8),
    );
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEDF5FF), Color(0xFFAFC7DF)],
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = delivered ? const Color(0xFF83E2C0) : const Color(0xFFFFE19A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(9, 12, size.width - 18, 5),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF40536A),
    );
    canvas.drawLine(
      Offset(size.width - 7, 9),
      Offset(size.width - 7, 2),
      Paint()
        ..color = const Color(0xFFFF7C72)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 7, 2, 7, 5),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFFF7C72),
    );
    if (delivered) {
      final check = Paint()
        ..color = const Color(0xFF2D8E70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()
        ..moveTo(12, 22)
        ..lineTo(17, 26)
        ..lineTo(27, 18);
      canvas.drawPath(path, check);
    }
  }

  @override
  bool shouldRepaint(covariant _MailboxPainter oldDelegate) =>
      oldDelegate.delivered != delivered;
}

class _DeliveryObstacleView extends StatelessWidget {
  const _DeliveryObstacleView({required this.obstacle});

  final _RiderObstacle obstacle;

  @override
  Widget build(BuildContext context) {
    final (label, asset, imageSize) = switch (obstacle.kind) {
      _RiderObstacleKind.puddle => (
        '물웅덩이',
        _newspaperPuddleAsset,
        const Size(60, 38),
      ),
      _RiderObstacleKind.crate => (
        '빈 나무 상자',
        _newspaperCrateAsset,
        const Size(54, 50),
      ),
      _RiderObstacleKind.trashBag => (
        '쓰레기 봉투 세 묶음',
        _newspaperTrashBagsAsset,
        const Size(56, 50),
      ),
    };
    return Semantics(
      label: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: obstacle.resolved ? 0.35 : 1,
        child: SizedBox(
          width: 60,
          height: 52,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (obstacle.kind != _RiderObstacleKind.puddle)
                Container(
                  width: 42,
                  height: 8,
                  margin: const EdgeInsets.only(bottom: 1),
                  decoration: BoxDecoration(
                    color: const Color(0x66000000),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66000000), blurRadius: 6),
                    ],
                  ),
                ),
              Image.asset(
                asset,
                key: Key('newspaper-obstacle-${obstacle.kind.name}'),
                width: imageSize.width,
                height: imageSize.height,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                cacheWidth: 240,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperFlight extends StatelessWidget {
  const _PaperFlight({super.key, required this.paper, required this.roadWidth});

  final _ThrownNewspaper paper;
  final double roadWidth;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(paper.progress.clamp(0.0, 1.0));
    final startX =
        _NewspaperDeliveryRoad._slotX(
          paper.fromSlot,
          roadWidth,
          horizontalInset: 40,
        ) -
        12;
    final endX = paper.toSide < 0 ? 21.0 : roadWidth - 45;
    final x = ui.lerpDouble(startX, endX, eased)!;
    final startY = _NewspaperDeliveryRoad.height - 112;
    final endY = (-2 + paper.targetY * _NewspaperDeliveryRoad.height).clamp(
      18.0,
      310.0,
    );
    final arc = math.sin(eased * math.pi) * 42;
    final y = ui.lerpDouble(startY, endY, eased)! - arc;
    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: (paper.toSide < 0 ? -1 : 1) * eased * 2.8,
        child: Container(
          width: 28,
          height: 19,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0DF),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF647084), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.horizontal_rule_rounded,
            color: Color(0xFF6C7482),
            size: 15,
          ),
        ),
      ),
    );
  }
}

class _DeliveryCyclist extends StatefulWidget {
  const _DeliveryCyclist({required this.slot});

  final int slot;

  @override
  State<_DeliveryCyclist> createState() => _DeliveryCyclistState();
}

class _DeliveryCyclistState extends State<_DeliveryCyclist>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pedal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..repeat();

  @override
  void dispose() {
    _pedal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: '신문 가방을 멘 자전거 배달원',
    child: AnimatedBuilder(
      animation: _pedal,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -math.sin(_pedal.value * math.pi * 2).abs() * 1.8),
        child: Transform.rotate(
          angle:
              ((widget.slot - (_newspaperSteeringSlotCount - 1) / 2) /
                  ((_newspaperSteeringSlotCount - 1) / 2)) *
              0.055,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 104,
            height: 142,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 48,
                  height: 8,
                  margin: const EdgeInsets.only(bottom: 1),
                  decoration: BoxDecoration(
                    color: const Color(0x66000000),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: const [
                      BoxShadow(color: Color(0x77000000), blurRadius: 7),
                    ],
                  ),
                ),
                Image.asset(
                  _newspaperCyclistAsset,
                  key: const Key('newspaper-cyclist-image'),
                  width: 104,
                  height: 142,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.high,
                  cacheWidth: 416,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NewspaperControls extends StatefulWidget {
  const _NewspaperControls({
    required this.enabled,
    required this.onLeft,
    required this.onThrow,
    required this.onRight,
  });

  final bool enabled;
  final VoidCallback onLeft;
  final void Function(int side, double power) onThrow;
  final VoidCallback onRight;

  @override
  State<_NewspaperControls> createState() => _NewspaperControlsState();
}

class _NewspaperControlsState extends State<_NewspaperControls> {
  Offset _drag = Offset.zero;
  bool _dragging = false;

  void _updateDrag(DragUpdateDetails details) {
    if (!widget.enabled) return;
    setState(() {
      _drag = Offset(
        (_drag.dx + details.delta.dx).clamp(-58.0, 58.0),
        (_drag.dy + details.delta.dy).clamp(-28.0, 12.0),
      );
      _dragging = true;
    });
  }

  void _finishDrag(DragEndDetails details) {
    if (!widget.enabled) return;
    final distance = _drag.distance;
    final speed = details.velocity.pixelsPerSecond.distance;
    final side = _drag.dx <= 0 ? -1 : 1;
    final power = ((distance + speed / 32) / 78).clamp(0.35, 1.0);
    setState(() {
      _drag = Offset.zero;
      _dragging = false;
    });
    if (distance >= 12 || speed >= 220) {
      widget.onThrow(side, power);
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 66,
        height: 58,
        child: OutlinedButton(
          key: const Key('rider-left'),
          onPressed: widget.enabled ? widget.onLeft : null,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: const Color(0xEFFFFFFF),
            foregroundColor: _ink,
            side: const BorderSide(color: Color(0xFF9FB5D5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_left_rounded, size: 29),
              Text(
                '1칸',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: SizedBox(
          height: 64,
          child: GestureDetector(
            key: const Key('newspaper-throw'),
            behavior: HitTestBehavior.opaque,
            onPanUpdate: widget.enabled ? _updateDrag : null,
            onPanEnd: widget.enabled ? _finishDrag : null,
            onPanCancel: () => setState(() {
              _drag = Offset.zero;
              _dragging = false;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.enabled
                      ? const [Color(0xFFE66F62), Color(0xFFFF9A78)]
                      : const [Color(0xFFAAAEB7), Color(0xFFC5C8CF)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xCCFFFFFF), width: 1.5),
                boxShadow: widget.enabled
                    ? const [
                        BoxShadow(
                          color: Color(0x55E66358),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned(
                    left: 10,
                    child: Icon(
                      Icons.keyboard_double_arrow_left_rounded,
                      color: Color(0xBBFFFFFF),
                      size: 19,
                    ),
                  ),
                  const Positioned(
                    right: 10,
                    child: Icon(
                      Icons.keyboard_double_arrow_right_rounded,
                      color: Color(0xBBFFFFFF),
                      size: 19,
                    ),
                  ),
                  Transform.translate(
                    offset: _drag,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 100),
                      scale: _dragging ? 1.12 : 1,
                      child: Container(
                        width: 43,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F2DF),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: const Color(0xFF6C7482)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.newspaper_rounded,
                          color: Color(0xFF40506A),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 3,
                    child: Text(
                      '우편함 쪽으로 플릭',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 66,
        height: 58,
        child: OutlinedButton(
          key: const Key('rider-right'),
          onPressed: widget.enabled ? widget.onRight : null,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: const Color(0xEFFFFFFF),
            foregroundColor: _ink,
            side: const BorderSide(color: Color(0xFF9FB5D5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_right_rounded, size: 29),
              Text(
                '1칸',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _NewspaperStartCard extends StatelessWidget {
  const _NewspaperStartCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('rider-start-card'),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xF7FFF9E8),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFFD56B), width: 2),
    ),
    child: Column(
      children: [
        const Text(
          '도로는 10칸 · 누르거나 드래그해 조금씩 조향!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          '우편함 쪽으로 붙은 뒤 신문 패드를 플릭 · 노란 선 타이밍과 세기가 수당을 결정',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6D7180),
            fontSize: 9,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            key: const Key('rider-start'),
            onPressed: onStart,
            icon: const Icon(Icons.wb_twilight_rounded),
            label: const Text('새벽 노선 출발'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF405F89),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    ),
  );
}
