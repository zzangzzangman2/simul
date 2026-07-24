part of 'main.dart';

enum _RiderPhase { ready, running, failed, complete }

enum _RiderObstacleKind { cone, box, puddle, cart, checkpoint }

class _RiderObstacle {
  _RiderObstacle({required this.id, required this.lane, required this.kind});

  final int id;
  final int lane;
  final _RiderObstacleKind kind;
  double y = -0.12;
  bool threatened = false;

  bool get isCheckpoint => kind == _RiderObstacleKind.checkpoint;
}

class RiderMiniGame extends StatefulWidget {
  const RiderMiniGame({
    super.key,
    this.courseDuration = const Duration(seconds: 28),
    this.spawnObstacles = true,
    this.randomSeed = 20000102,
  });

  final Duration courseDuration;
  final bool spawnObstacles;
  final int randomSeed;

  @override
  State<RiderMiniGame> createState() => _RiderMiniGameState();
}

class _RiderMiniGameState extends State<RiderMiniGame> {
  static const _tick = Duration(milliseconds: 50);
  static const _checkpointFractions = <double>[0.18, 0.48, 0.78];
  static const _laneLabels = <String>['왼쪽', '가운데', '오른쪽'];

  late math.Random _random;
  Timer? _timer;
  _RiderPhase _phase = _RiderPhase.ready;
  final List<_RiderObstacle> _obstacles = <_RiderObstacle>[];
  int _playerLane = 1;
  int _nextObstacleId = 0;
  int _nextCheckpoint = 0;
  int _deliveries = 0;
  int _nearMisses = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _rawScore = 0;
  double _elapsedSeconds = 0;
  double _spawnCooldown = 0.55;
  String _banner = '준비됐으면 출발!';
  String _failureReason = '';

  double get _courseSeconds =>
      math.max(0.25, widget.courseDuration.inMilliseconds / 1000);
  double get _progress => (_elapsedSeconds / _courseSeconds).clamp(0.0, 1.0);
  int get _remainingSeconds =>
      math.max(0, (_courseSeconds - _elapsedSeconds).ceil());
  int get _finalScore =>
      (55 + _deliveries * 8 + math.min(21, _nearMisses * 3 + _bestCombo * 2))
          .clamp(0, 100)
          .toInt();

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
    setState(() {
      _random = math.Random(widget.randomSeed);
      _phase = _RiderPhase.running;
      _obstacles.clear();
      _playerLane = 1;
      _nextObstacleId = 0;
      _nextCheckpoint = 0;
      _deliveries = 0;
      _nearMisses = 0;
      _combo = 0;
      _bestCombo = 0;
      _rawScore = 0;
      _elapsedSeconds = 0;
      _spawnCooldown = 0.55;
      _banner = '좌우로 밀어서 피해!';
      _failureReason = '';
    });
    _timer = Timer.periodic(_tick, (_) => _advance());
  }

  void _advance() {
    if (!mounted || _phase != _RiderPhase.running) return;
    const dt = 0.05;
    var failed = false;
    String failure = '';
    setState(() {
      _elapsedSeconds += dt;
      _rawScore += 2 + _combo;
      _spawnCooldown -= dt;

      if (widget.spawnObstacles && _spawnCooldown <= 0) {
        _spawnObstacle();
        _spawnCooldown = 0.62 + _random.nextDouble() * 0.48;
      }

      if (_nextCheckpoint < _checkpointFractions.length &&
          _progress >= _checkpointFractions[_nextCheckpoint]) {
        if (widget.spawnObstacles) {
          _spawnCheckpoint();
        } else {
          _deliveries++;
          _rawScore += 800;
          _banner = '배달 성공! $_deliveries/3';
        }
        _nextCheckpoint++;
      }

      final speed = 0.34 + _progress * 0.12;
      for (final obstacle in _obstacles) {
        obstacle.y += speed * dt;
        if (!obstacle.isCheckpoint &&
            obstacle.lane == _playerLane &&
            obstacle.y >= 0.58 &&
            obstacle.y < 0.77) {
          obstacle.threatened = true;
        }

        if (obstacle.isCheckpoint &&
            obstacle.lane == _playerLane &&
            obstacle.y >= 0.77 &&
            obstacle.y <= 0.93) {
          _deliveries++;
          _rawScore += 800;
          _combo++;
          _bestCombo = math.max(_bestCombo, _combo);
          _banner = '배달 성공! $_deliveries/3';
          obstacle.y = 1.2;
          continue;
        }

        if (!obstacle.isCheckpoint &&
            obstacle.lane == _playerLane &&
            obstacle.y >= 0.78 &&
            obstacle.y <= 0.91) {
          failed = true;
          failure = '장애물과 부딪혔어요';
          break;
        }

        if (obstacle.isCheckpoint && obstacle.y > 0.96) {
          failed = true;
          failure = '배달 지점을 놓쳤어요';
          break;
        }

        if (!obstacle.isCheckpoint &&
            obstacle.threatened &&
            obstacle.lane != _playerLane &&
            obstacle.y > 0.92 &&
            obstacle.y < 1.08) {
          obstacle.threatened = false;
          _nearMisses++;
          _combo++;
          _bestCombo = math.max(_bestCombo, _combo);
          _rawScore += 250 * _combo;
          _banner = _combo >= 3 ? '크리티컬! 콤보 ×$_combo' : '아슬아슬!';
        }
      }
      _obstacles.removeWhere((obstacle) => obstacle.y > 1.08);
    });

    if (failed) {
      _fail(failure);
      return;
    }
    if (_elapsedSeconds >= _courseSeconds) {
      if (_deliveries == _checkpointFractions.length) {
        _complete();
      } else {
        _fail('배달 지점을 모두 통과하지 못했어요');
      }
    }
  }

  void _spawnObstacle() {
    final blockedLanes = _obstacles
        .where((obstacle) => obstacle.y < 0.16)
        .map((obstacle) => obstacle.lane)
        .toSet();
    final available = <int>[
      0,
      1,
      2,
    ].where((lane) => !blockedLanes.contains(lane)).toList();
    if (available.isEmpty) return;
    final kinds = <_RiderObstacleKind>[
      _RiderObstacleKind.cone,
      _RiderObstacleKind.box,
      _RiderObstacleKind.puddle,
      _RiderObstacleKind.cart,
    ];
    _obstacles.add(
      _RiderObstacle(
        id: _nextObstacleId++,
        lane: available[_random.nextInt(available.length)],
        kind: kinds[_random.nextInt(kinds.length)],
      ),
    );
  }

  void _spawnCheckpoint() {
    final lane = _random.nextInt(3);
    _obstacles.removeWhere(
      (obstacle) => obstacle.lane == lane && obstacle.y < 0.25,
    );
    _obstacles.add(
      _RiderObstacle(
        id: _nextObstacleId++,
        lane: lane,
        kind: _RiderObstacleKind.checkpoint,
      ),
    );
    _banner = '초록 배달 지점으로 이동!';
  }

  void _moveTo(int lane) {
    if (_phase != _RiderPhase.running) return;
    final next = lane.clamp(0, 2);
    if (next == _playerLane) return;
    setState(() {
      _playerLane = next;
      _banner = '${_laneLabels[next]} 차선';
    });
  }

  void _handleDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 100) return;
    _moveTo(_playerLane + (velocity > 0 ? 1 : -1));
  }

  void _handleTap(TapUpDetails details, double width) {
    if (width <= 0) return;
    _moveTo((details.localPosition.dx / (width / 3)).floor());
  }

  void _fail(String reason) {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _phase = _RiderPhase.failed;
      _failureReason = reason;
      _combo = 0;
    });
  }

  void _complete() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _phase = _RiderPhase.complete;
      _rawScore += 3000 + _remainingSeconds * 100;
      _banner = '코스 완주!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _MiniGameShell(
      title: '잼민 라이더',
      subtitle: '2000년 동네 축제 · 보호자와 함께하는 폐쇄 코스',
      backgroundAsset:
          'assets/images/real_estate/03_gyeonggi_old_apartment_2000.png',
      progress: _phase == _RiderPhase.complete ? 1 : _progress,
      child: _phase == _RiderPhase.complete
          ? _MiniGameResult(
              activityId: 'rider',
              score: _finalScore,
              title: _finalScore >= 90 ? '동네 최강 라이더!' : '안전하게 완주!',
              detail:
                  '배달 $_deliveries/3 · 크리티컬 $_nearMisses회 · 최고 콤보 $_bestCombo · 기본 상금 ${700 + _finalScore * 15}원',
            )
          : Column(
              children: [
                _RiderHud(
                  remainingSeconds: _remainingSeconds,
                  deliveries: _deliveries,
                  combo: _combo,
                  rawScore: _rawScore,
                  banner: _banner,
                ),
                const SizedBox(height: 9),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return GestureDetector(
                      key: const Key('rider-road'),
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragEnd: _handleDrag,
                      onTapUp: (details) => _handleTap(details, width),
                      child: _RiderRoad(
                        playerLane: _playerLane,
                        obstacles: _obstacles,
                        progress: _progress,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          key: const Key('rider-left'),
                          onPressed: _phase == _RiderPhase.running
                              ? () => _moveTo(_playerLane - 1)
                              : null,
                          icon: const Icon(Icons.arrow_left_rounded, size: 28),
                          label: const Text('왼쪽'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xEFFFFFFF),
                            foregroundColor: _ink,
                            side: const BorderSide(color: Color(0xFF9DD5E3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          key: const Key('rider-right'),
                          onPressed: _phase == _RiderPhase.running
                              ? () => _moveTo(_playerLane + 1)
                              : null,
                          icon: const Icon(Icons.arrow_right_rounded, size: 28),
                          label: const Text('오른쪽'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xEFFFFFFF),
                            foregroundColor: _ink,
                            side: const BorderSide(color: Color(0xFF9DD5E3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_phase == _RiderPhase.ready) ...[
                  const SizedBox(height: 9),
                  _RiderStartCard(onStart: _start),
                ],
                if (_phase == _RiderPhase.failed) ...[
                  const SizedBox(height: 9),
                  _RiderFailureCard(reason: _failureReason, onRetry: _start),
                ],
              ],
            ),
    );
  }
}

class _RiderHud extends StatelessWidget {
  const _RiderHud({
    required this.remainingSeconds,
    required this.deliveries,
    required this.combo,
    required this.rawScore,
    required this.banner,
  });

  final int remainingSeconds;
  final int deliveries;
  final int combo;
  final int rawScore;
  final String banner;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xED102039),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0x55FFFFFF)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x44000000),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            _RiderHudChip(
              icon: Icons.timer_rounded,
              label: '$remainingSeconds초',
              color: const Color(0xFFFFD767),
            ),
            const SizedBox(width: 6),
            _RiderHudChip(
              icon: Icons.delivery_dining_rounded,
              label: '$deliveries/3',
              color: const Color(0xFF7FE0A9),
            ),
            const Spacer(),
            Text(
              '$rawScore점',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (combo > 0) ...[
              const SizedBox(width: 7),
              Text(
                '×$combo',
                style: const TextStyle(
                  color: Color(0xFFFF887E),
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
          style: const TextStyle(
            color: Color(0xFFE8F3FF),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _RiderHudChip extends StatelessWidget {
  const _RiderHudChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _RiderRoad extends StatelessWidget {
  const _RiderRoad({
    required this.playerLane,
    required this.obstacles,
    required this.progress,
  });

  final int playerLane;
  final List<_RiderObstacle> obstacles;
  final double progress;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('rider-course'),
    height: 350,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF424B5B),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFFF5D879), width: 3),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final laneWidth = constraints.maxWidth / 3;
        return Stack(
          fit: StackFit.expand,
          children: [
            const _RiderRoadPaint(),
            Positioned(
              top: 8,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Text(
                      '${index + 1}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0x66FFFFFF),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (final obstacle in obstacles)
              Positioned(
                key: ValueKey('rider-obstacle-${obstacle.id}'),
                left: laneWidth * obstacle.lane + laneWidth / 2 - 25,
                top: -45 + obstacle.y * 350,
                child: _RiderObstacleView(obstacle: obstacle),
              ),
            AnimatedPositioned(
              key: const Key('rider-player'),
              duration: const Duration(milliseconds: 105),
              curve: Curves.easeOutBack,
              left: laneWidth * playerLane + laneWidth / 2 - 27,
              bottom: 20,
              child: const _RiderPlayer(),
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
                  backgroundColor: const Color(0x44000000),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD767)),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _RiderRoadPaint extends StatelessWidget {
  const _RiderRoadPaint();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF586574), Color(0xFF343B47)],
          ),
        ),
      ),
      for (final alignment in const [-0.33, 0.33])
        Align(
          alignment: Alignment(alignment, 0),
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                7,
                (_) => Container(
                  width: 4,
                  height: 27,
                  decoration: BoxDecoration(
                    color: const Color(0xBFFFFFFF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
        ),
      const Positioned(
        left: 8,
        top: 0,
        bottom: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFFEFC85F)),
          child: SizedBox(width: 4),
        ),
      ),
      const Positioned(
        right: 8,
        top: 0,
        bottom: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFFEFC85F)),
          child: SizedBox(width: 4),
        ),
      ),
    ],
  );
}

class _RiderObstacleView extends StatelessWidget {
  const _RiderObstacleView({required this.obstacle});

  final _RiderObstacle obstacle;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (obstacle.kind) {
      _RiderObstacleKind.cone => (
        Icons.change_history_rounded,
        const Color(0xFFFF8B4F),
        '고깔',
      ),
      _RiderObstacleKind.box => (
        Icons.inventory_2_rounded,
        const Color(0xFFCC9B65),
        '상자',
      ),
      _RiderObstacleKind.puddle => (
        Icons.water_rounded,
        const Color(0xFF71C9EF),
        '물웅덩이',
      ),
      _RiderObstacleKind.cart => (
        Icons.shopping_cart_rounded,
        const Color(0xFFEF6D73),
        '손수레',
      ),
      _RiderObstacleKind.checkpoint => (
        Icons.takeout_dining_rounded,
        const Color(0xFF5BD494),
        '배달 지점',
      ),
    };
    return Semantics(
      label: label,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: obstacle.isCheckpoint ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: obstacle.isCheckpoint
              ? null
              : BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 7,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 27),
      ),
    );
  }
}

class _RiderPlayer extends StatelessWidget {
  const _RiderPlayer();

  @override
  Widget build(BuildContext context) => Container(
    width: 54,
    height: 72,
    decoration: BoxDecoration(
      color: const Color(0xFF16223B),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x77000000),
          blurRadius: 9,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: const Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 7,
          child: Icon(Icons.face_rounded, color: Color(0xFFFFD4B2), size: 24),
        ),
        Positioned(
          top: 29,
          child: Icon(
            Icons.directions_bike_rounded,
            color: Color(0xFFFFD65F),
            size: 31,
          ),
        ),
        Positioned(
          bottom: 2,
          child: Icon(Icons.horizontal_rule_rounded, color: Colors.white),
        ),
      ],
    ),
  );
}

class _RiderStartCard extends StatelessWidget {
  const _RiderStartCard({required this.onStart});

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
          '장애물은 피하고 초록 배달 지점은 통과!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          '도로를 좌우로 밀거나 차선을 눌러 이동해요. 충돌하거나 배달을 놓치면 상금은 0원입니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF716A5F),
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
            icon: const Icon(Icons.flag_rounded),
            label: const Text(
              '코스 출발',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RiderFailureCard extends StatelessWidget {
  const _RiderFailureCard({required this.reason, required this.onRetry});

  final String reason;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('rider-failure-card'),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xF7FFF0EF),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFF9C93), width: 2),
    ),
    child: Column(
      children: [
        const Icon(Icons.health_and_safety_rounded, color: _coral, size: 34),
        const SizedBox(height: 4),
        Text(
          reason,
          style: const TextStyle(
            color: _ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text(
          '안전요원이 코스를 멈췄어요 · 이번 상금 0원',
          style: TextStyle(
            color: Color(0xFF7A7180),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton.icon(
            key: const Key('rider-retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.replay_rounded),
            label: const Text(
              '처음부터 재도전',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
