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
            _RiderRoadPaint(progress: progress),
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
                left: laneWidth * obstacle.lane + laneWidth / 2 - 28,
                top: -45 + obstacle.y * 350,
                child: _RiderObstacleView(obstacle: obstacle),
              ),
            AnimatedPositioned(
              key: const Key('rider-player'),
              duration: const Duration(milliseconds: 105),
              curve: Curves.easeOutBack,
              left: laneWidth * playerLane + laneWidth / 2 - 40,
              bottom: 8,
              child: _RiderPlayer(lane: playerLane),
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
  const _RiderRoadPaint({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PixelRoadPainter(progress: progress));
}

class _PixelRoadPainter extends CustomPainter {
  const _PixelRoadPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF667280), Color(0xFF343B47)],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    paint.shader = null;

    _rect(canvas, paint, 0, 0, 15, size.height, const Color(0xFF276D43));
    _rect(
      canvas,
      paint,
      size.width - 15,
      0,
      15,
      size.height,
      const Color(0xFF276D43),
    );

    final tileOffset = (progress * 520) % 20;
    for (var y = -20.0 + tileOffset; y < size.height; y += 20) {
      final alternate = ((y / 20).round() & 1) == 0;
      _rect(
        canvas,
        paint,
        2,
        y,
        10,
        10,
        alternate ? const Color(0xFF43A05D) : const Color(0xFF33864E),
      );
      _rect(
        canvas,
        paint,
        size.width - 12,
        y + 8,
        10,
        10,
        alternate ? const Color(0xFF33864E) : const Color(0xFF43A05D),
      );
    }

    for (var y = -16.0 + tileOffset; y < size.height; y += 16) {
      final red = ((y / 16).round() & 1) == 0;
      final curb = red ? const Color(0xFFEE6B5F) : const Color(0xFFF8F1D9);
      _rect(canvas, paint, 15, y, 7, 13, curb);
      _rect(canvas, paint, size.width - 22, y, 7, 13, curb);
    }

    final dashOffset = (progress * 900) % 44;
    for (final x in [size.width / 3, size.width * 2 / 3]) {
      for (var y = -42.0 + dashOffset; y < size.height; y += 44) {
        _rect(canvas, paint, x - 2, y, 4, 24, const Color(0xFFE9E7D8));
        _rect(canvas, paint, x - 1, y, 2, 24, const Color(0xFFFFFFFF));
      }
    }

    _rect(canvas, paint, 22, 0, size.width - 44, 7, const Color(0xFFFFD65F));
    _rect(canvas, paint, 22, 7, size.width - 44, 3, const Color(0xFFBE7D2B));

    const crackSeeds = <(double, double)>[
      (0.23, 0.17),
      (0.75, 0.31),
      (0.48, 0.54),
      (0.81, 0.74),
      (0.18, 0.88),
    ];
    for (final (dx, dy) in crackSeeds) {
      final y = (dy * size.height + progress * 680) % size.height;
      final x = 22 + dx * (size.width - 44);
      _rect(canvas, paint, x, y, 8, 2, const Color(0xFF2B313A));
      _rect(canvas, paint, x + 5, y + 2, 2, 5, const Color(0xFF2B313A));
    }
  }

  void _rect(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double width,
    double height,
    Color color,
  ) {
    paint.color = color;
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelRoadPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _RiderObstacleView extends StatelessWidget {
  const _RiderObstacleView({required this.obstacle});

  final _RiderObstacle obstacle;

  @override
  Widget build(BuildContext context) {
    final label = switch (obstacle.kind) {
      _RiderObstacleKind.cone => 'traffic cone',
      _RiderObstacleKind.box => 'wooden crate',
      _RiderObstacleKind.puddle => 'water puddle',
      _RiderObstacleKind.cart => 'hand cart',
      _RiderObstacleKind.checkpoint => 'delivery checkpoint',
    };
    return Semantics(
      label: label,
      child: RepaintBoundary(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: obstacle.isCheckpoint
                    ? const Color(0x995BFFAC)
                    : const Color(0x55000000),
                blurRadius: obstacle.isCheckpoint ? 12 : 5,
                spreadRadius: obstacle.isCheckpoint ? 2 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _PixelObstaclePainter(kind: obstacle.kind),
          ),
        ),
      ),
    );
  }
}

class _PixelObstaclePainter extends CustomPainter {
  const _PixelObstaclePainter({required this.kind});

  final _RiderObstacleKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    switch (kind) {
      case _RiderObstacleKind.cone:
        _cone(canvas, paint);
      case _RiderObstacleKind.box:
        _box(canvas, paint);
      case _RiderObstacleKind.puddle:
        _puddle(canvas, paint);
      case _RiderObstacleKind.cart:
        _cart(canvas, paint);
      case _RiderObstacleKind.checkpoint:
        _checkpoint(canvas, paint);
    }
  }

  void _cone(Canvas canvas, Paint paint) {
    _rect(canvas, paint, 8, 45, 40, 7, const Color(0xFF232A35));
    _rect(canvas, paint, 12, 40, 32, 7, const Color(0xFFB8492E));
    _rect(canvas, paint, 17, 31, 22, 10, const Color(0xFFFF7A3D));
    _rect(canvas, paint, 20, 22, 16, 9, const Color(0xFFF4EEE1));
    _rect(canvas, paint, 23, 11, 10, 12, const Color(0xFFFF8A42));
    _rect(canvas, paint, 26, 7, 4, 5, const Color(0xFFFFB15A));
  }

  void _box(Canvas canvas, Paint paint) {
    _rect(canvas, paint, 7, 12, 44, 41, const Color(0xFF4D2D23));
    _rect(canvas, paint, 10, 9, 38, 41, const Color(0xFFC88642));
    _rect(canvas, paint, 14, 13, 30, 33, const Color(0xFFE3A95C));
    _rect(canvas, paint, 25, 10, 7, 39, const Color(0xFF8D522F));
    _rect(canvas, paint, 10, 26, 38, 6, const Color(0xFF8D522F));
    _rect(canvas, paint, 14, 15, 9, 4, const Color(0xFFF3C879));
  }

  void _puddle(Canvas canvas, Paint paint) {
    _rect(canvas, paint, 6, 27, 44, 16, const Color(0xFF194E79));
    _rect(canvas, paint, 12, 21, 32, 27, const Color(0xFF3B9ED0));
    _rect(canvas, paint, 5, 32, 46, 8, const Color(0xFF3B9ED0));
    _rect(canvas, paint, 16, 25, 22, 12, const Color(0xFF78D8F0));
    _rect(canvas, paint, 20, 24, 12, 4, const Color(0xFFC8F5FF));
    _rect(canvas, paint, 10, 45, 10, 4, const Color(0xFF194E79));
    _rect(canvas, paint, 38, 19, 7, 5, const Color(0xFF78D8F0));
  }

  void _cart(Canvas canvas, Paint paint) {
    _rect(canvas, paint, 7, 16, 38, 25, const Color(0xFF722F3A));
    _rect(canvas, paint, 10, 12, 34, 25, const Color(0xFFE25B5B));
    _rect(canvas, paint, 14, 16, 26, 6, const Color(0xFFFF8580));
    _rect(canvas, paint, 13, 29, 28, 5, const Color(0xFFA33E48));
    _rect(canvas, paint, 43, 8, 5, 31, const Color(0xFFE7C06A));
    _rect(canvas, paint, 47, 6, 7, 5, const Color(0xFF5A3928));
    _rect(canvas, paint, 11, 39, 11, 11, const Color(0xFF202733));
    _rect(canvas, paint, 34, 39, 11, 11, const Color(0xFF202733));
    _rect(canvas, paint, 14, 42, 5, 5, const Color(0xFF9EB1BA));
    _rect(canvas, paint, 37, 42, 5, 5, const Color(0xFF9EB1BA));
  }

  void _checkpoint(Canvas canvas, Paint paint) {
    _rect(canvas, paint, 4, 7, 48, 45, const Color(0xFF173B33));
    _rect(canvas, paint, 7, 4, 42, 45, const Color(0xFF42D88B));
    _rect(canvas, paint, 11, 8, 34, 37, const Color(0xFF1E8E61));
    _rect(canvas, paint, 15, 12, 26, 29, const Color(0xFF76F2AE));
    _rect(canvas, paint, 20, 17, 16, 18, const Color(0xFFFFF5CC));
    _rect(canvas, paint, 23, 13, 10, 6, const Color(0xFFFFD765));
    _rect(canvas, paint, 24, 21, 8, 3, const Color(0xFFE26955));
    _rect(canvas, paint, 24, 27, 8, 3, const Color(0xFFE26955));
    _rect(canvas, paint, 7, 45, 42, 5, const Color(0xFFFFD765));
  }

  void _rect(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double width,
    double height,
    Color color,
  ) {
    paint.color = color;
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelObstaclePainter oldDelegate) =>
      oldDelegate.kind != kind;
}

class _RiderPlayer extends StatefulWidget {
  const _RiderPlayer({required this.lane});

  final int lane;

  @override
  State<_RiderPlayer> createState() => _RiderPlayerState();
}

class _RiderPlayerState extends State<_RiderPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'pixel-art hero riding a yellow kick scooter',
    child: TweenAnimationBuilder<double>(
      tween: Tween(end: (widget.lane - 1) * 0.055),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutBack,
      builder: (context, tilt, child) => Transform.rotate(
        angle: tilt,
        alignment: Alignment.bottomCenter,
        child: child,
      ),
      child: AnimatedBuilder(
        animation: _bounceController,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -1.5 * _bounceController.value),
          child: child,
        ),
        child: SizedBox(
          width: 80,
          height: 128,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              const Positioned(
                left: 11,
                bottom: 4,
                child: _PixelDust(color: Color(0x99F4D28A), size: 7),
              ),
              const Positioned(
                right: 10,
                bottom: 10,
                child: _PixelDust(color: Color(0x77FFFFFF), size: 5),
              ),
              Image.asset(
                'assets/images/minigames/rider_hero_pixel_v1.png',
                key: const Key('rider-player-sprite'),
                width: 72,
                height: 128,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
                gaplessPlayback: true,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PixelDust extends StatelessWidget {
  const _PixelDust({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(1),
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
