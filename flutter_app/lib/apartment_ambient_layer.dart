part of 'main.dart';

// Repaints independently from the map and never takes pointer events.
class _ApartmentAmbientLayer extends StatefulWidget {
  const _ApartmentAmbientLayer({required this.place, required this.state});

  final _ApartmentPlace place;
  final GameState state;

  @override
  State<_ApartmentAmbientLayer> createState() => _ApartmentAmbientLayerState();
}

class _ApartmentAmbientLayerState extends State<_ApartmentAmbientLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
    value: 0.23,
  );

  bool get _runningInWidgetTest => WidgetsBinding.instance.runtimeType
      .toString()
      .contains('TestWidgetsFlutterBinding');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldAnimate =
        !MediaQuery.disableAnimationsOf(context) && !_runningInWidgetTest;
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0.23;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = _ApartmentPlaceDetails.forPlace(widget.place).id;
    return ExcludeSemantics(
      child: RepaintBoundary(
        key: Key('apartment-ambient-$id'),
        child: LayoutBuilder(
          builder: (context, constraints) => AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final phase = _controller.value;
              return Stack(
                clipBehavior: Clip.hardEdge,
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    key: Key('apartment-ambient-paint-$id'),
                    painter: _ApartmentAmbientPainter(
                      place: widget.place,
                      state: widget.state,
                      phase: phase,
                    ),
                  ),
                  if (widget.place == _ApartmentPlace.corridor)
                    _AmbientMovingSprite(
                      key: const Key('ambient-corridor-cat'),
                      asset:
                          'assets/images/gameplay_ambient/ambient_corridor_cat_cartoon_v1.png',
                      progress: (phase * 0.72 + 0.08) % 1,
                      viewport: constraints.biggest,
                      width: 82,
                      verticalFraction: 0.69,
                      movingRight: true,
                      bobAmount: 2.2,
                    ),
                  if (widget.place == _ApartmentPlace.neighborhood) ...[
                    _AmbientMovingSprite(
                      key: const Key('ambient-neighborhood-minibus'),
                      asset:
                          'assets/images/gameplay_ambient/ambient_neighborhood_minibus_cartoon_v1.png',
                      progress: (phase * 0.58 + 0.62) % 1,
                      viewport: constraints.biggest,
                      width: 176,
                      verticalFraction: 0.56,
                      movingRight: true,
                      bobAmount: 1.2,
                      opacity: 0.78,
                    ),
                    _AmbientMovingSprite(
                      key: const Key('ambient-neighborhood-walkers'),
                      asset:
                          'assets/images/gameplay_ambient/ambient_neighborhood_walkers_cartoon_v1.png',
                      progress: (phase * 0.43 + 0.28) % 1,
                      viewport: constraints.biggest,
                      width: 68,
                      verticalFraction: 0.60,
                      movingRight: false,
                      bobAmount: 2.6,
                      opacity: 0.88,
                    ),
                    _AmbientMovingSprite(
                      key: const Key('ambient-neighborhood-bicycle'),
                      asset:
                          'assets/images/gameplay_ambient/ambient_neighborhood_bicycle_cartoon_v1.png',
                      progress: (phase * 0.82 + 0.04) % 1,
                      viewport: constraints.biggest,
                      width: 96,
                      verticalFraction: 0.69,
                      movingRight: false,
                      bobAmount: 1.6,
                      opacity: 0.92,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AmbientMovingSprite extends StatelessWidget {
  const _AmbientMovingSprite({
    super.key,
    required this.asset,
    required this.progress,
    required this.viewport,
    required this.width,
    required this.verticalFraction,
    required this.movingRight,
    required this.bobAmount,
    this.opacity = 1,
  });

  final String asset;
  final double progress;
  final Size viewport;
  final double width;
  final double verticalFraction;
  final bool movingRight;
  final double bobAmount;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    final travel = viewport.width + width * 1.8;
    final forwardLeft = -width * 1.15 + travel * safeProgress;
    final left = movingRight
        ? forwardLeft
        : viewport.width - forwardLeft - width;
    final edgeFade = math
        .min(
          (safeProgress / 0.08).clamp(0.0, 1.0),
          ((1 - safeProgress) / 0.08).clamp(0.0, 1.0),
        )
        .toDouble();
    final bob = math.sin(safeProgress * math.pi * 12) * bobAmount;
    return Positioned(
      left: left,
      top: viewport.height * verticalFraction + bob,
      width: width,
      child: Opacity(
        opacity: opacity * edgeFade,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(movingRight ? 1 : -1, 1, 1),
          child: Image.asset(
            asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _ApartmentAmbientPainter extends CustomPainter {
  const _ApartmentAmbientPainter({
    required this.place,
    required this.state,
    required this.phase,
  });

  final _ApartmentPlace place;
  final GameState state;
  final double phase;

  int get _weatherCode {
    final seed = state.simulationSeed.codeUnits.fold<int>(
      state.day * 17,
      (value, unit) => (value * 31 + unit) & 0x7fffffff,
    );
    return seed % 5;
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (place) {
      case _ApartmentPlace.bedroom:
        _paintBedroom(canvas, size);
        break;
      case _ApartmentPlace.livingRoom:
        _paintLivingRoom(canvas, size);
        break;
      case _ApartmentPlace.kitchen:
        _paintKitchen(canvas, size);
        break;
      case _ApartmentPlace.corridor:
        _paintCorridor(canvas, size);
        break;
      case _ApartmentPlace.neighborhood:
        _paintNeighborhood(canvas, size);
        break;
    }
  }

  void _paintBedroom(Canvas canvas, Size size) {
    final pulse = 0.5 + 0.5 * math.sin(phase * math.pi * 14);
    final screen = Rect.fromCenter(
      center: Offset(size.width * 0.17, size.height * 0.40),
      width: size.width * 0.27,
      height: size.height * 0.16,
    );
    final glow = screen.inflate(size.width * 0.12);
    canvas.drawOval(
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.fromRGBO(109, 225, 255, 0.20 + pulse * 0.12),
            const Color(0x0000C8FF),
          ],
        ).createShader(glow),
    );
    final scanPaint = Paint()
      ..color = Color.fromRGBO(210, 251, 255, 0.08 + pulse * 0.05)
      ..strokeWidth = 1;
    for (var index = 0; index < 7; index++) {
      final y = screen.top + ((index + phase) % 7) / 7 * screen.height;
      canvas.drawLine(
        Offset(screen.left, y),
        Offset(screen.right, y),
        scanPaint,
      );
    }
    _paintDust(canvas, size, color: const Color(0x66BDEEFF), count: 11);
  }

  void _paintLivingRoom(Canvas canvas, Size size) {
    _paintRadialGlow(
      canvas,
      Rect.fromCircle(
        center: Offset(size.width * 0.24, size.height * 0.33),
        radius: size.width * 0.23,
      ),
      const Color(0x42FFD67E),
    );
    final tvPulse = 0.5 + 0.5 * math.sin(phase * math.pi * 17);
    _paintRadialGlow(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.32),
        width: size.width * 0.34,
        height: size.height * 0.18,
      ),
      Color.fromRGBO(135, 202, 255, 0.08 + tvPulse * 0.08),
    );
    _paintDust(canvas, size, color: const Color(0x55FFE4A6), count: 9);
  }

  void _paintKitchen(Canvas canvas, Size size) {
    final flicker = 0.82 + math.sin(phase * math.pi * 23) * 0.04;
    final light = Rect.fromLTWH(
      size.width * 0.13,
      size.height * 0.04,
      size.width * 0.74,
      size.height * 0.20,
    );
    canvas.drawRect(
      light,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(255, 248, 204, flicker * 0.16),
            const Color(0x00FFF8CC),
          ],
        ).createShader(light),
    );
    for (var index = 0; index < 5; index++) {
      final local = (phase * 1.65 + index * 0.21) % 1;
      final center = Offset(
        size.width * 0.68 + math.sin((local + index) * math.pi * 2) * 7,
        size.height * (0.56 - local * 0.18),
      );
      canvas.drawCircle(
        center,
        4 + local * 8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = Color.fromRGBO(255, 255, 245, (1 - local) * 0.34),
      );
    }
    _paintDust(canvas, size, color: const Color(0x44FFF7DA), count: 7);
  }

  void _paintCorridor(Canvas canvas, Size size) {
    final sensorPulse = 0.72 + math.sin(phase * math.pi * 4) * 0.05;
    final cone = Path()
      ..moveTo(size.width * 0.48, 0)
      ..lineTo(size.width * 0.14, size.height * 0.78)
      ..lineTo(size.width * 0.88, size.height * 0.78)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(255, 227, 157, sensorPulse * 0.20),
            const Color(0x00FFE39D),
          ],
        ).createShader(Offset.zero & size),
    );
    if (state.pendingDecisions.isNotEmpty) {
      final mailbox = Offset(size.width * 0.54, size.height * 0.40);
      for (var index = 0; index < 5; index++) {
        final angle = phase * math.pi * 2 + index * math.pi * 0.4;
        final radius = 22 + 8 * math.sin(phase * math.pi * 2 + index);
        canvas.drawCircle(
          mailbox + Offset(math.cos(angle), math.sin(angle)) * radius,
          2.2,
          Paint()..color = const Color(0xD9FFD86B),
        );
      }
    }
  }

  void _paintNeighborhood(Canvas canvas, Size size) {
    if (state.marketMinute >= 17 * 60) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x2AFFAA66), Color(0x1A553477)],
          ).createShader(Offset.zero & size),
      );
    }
    if (_weatherCode == 1 || _weatherCode == 3) {
      _paintCloudShadows(canvas, size);
    } else if (_weatherCode == 4) {
      _paintRain(canvas, size);
    }
    final birdPaint = Paint()
      ..color = const Color(0x8A253247)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (var index = 0; index < 4; index++) {
      final x = ((phase * 1.2 + index * 0.24) % 1) * size.width;
      final y = size.height * (0.19 + index * 0.018);
      final wing = 3 + math.sin(phase * math.pi * 20 + index) * 1.2;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(x - wing, y),
          width: wing * 2,
          height: 5,
        ),
        math.pi * 0.1,
        math.pi * 0.8,
        false,
        birdPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(x + wing, y),
          width: wing * 2,
          height: 5,
        ),
        math.pi * 0.1,
        math.pi * 0.8,
        false,
        birdPaint,
      );
    }
  }

  void _paintCloudShadows(Canvas canvas, Size size) {
    for (var index = 0; index < 3; index++) {
      final progress = (phase * 0.28 + index * 0.41) % 1;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            -size.width * 0.24 + progress * size.width * 1.48,
            size.height * (0.12 + index * 0.055),
          ),
          width: size.width * 0.42,
          height: size.height * 0.06,
        ),
        Paint()..color = Color.fromRGBO(225, 238, 244, 0.11 + index * 0.018),
      );
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66C8EEFF)
      ..strokeWidth = 1.2;
    for (var index = 0; index < 42; index++) {
      final x = ((index * 47.0 + phase * 620) % (size.width + 30)) - 15;
      final y = ((index * 83.0 + phase * 1180) % (size.height + 42)) - 21;
      canvas.drawLine(Offset(x, y), Offset(x - 5, y + 14), paint);
    }
    for (var index = 0; index < 7; index++) {
      final local = (phase * 1.8 + index * 0.19) % 1;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            size.width * (0.08 + index * 0.14),
            size.height * (0.74 + index % 2 * 0.035),
          ),
          width: 8 + local * 20,
          height: 2 + local * 5,
        ),
        Paint()
          ..color = Color.fromRGBO(182, 232, 255, (1 - local) * 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    }
  }

  void _paintRadialGlow(Canvas canvas, Rect rect, Color color) {
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  void _paintDust(
    Canvas canvas,
    Size size, {
    required Color color,
    required int count,
  }) {
    for (var index = 0; index < count; index++) {
      final drift = (phase * (0.18 + index % 3 * 0.035) + index * 0.137) % 1;
      final x =
          (index * 73.0 + math.sin(phase * math.pi * 2 + index) * 13) %
          size.width;
      final y = size.height * (0.18 + drift * 0.58);
      canvas.drawCircle(
        Offset(x, y),
        0.8 + index % 3 * 0.45,
        Paint()..color = color.withValues(alpha: 0.18 + drift * 0.22),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ApartmentAmbientPainter oldDelegate) =>
      oldDelegate.place != place ||
      oldDelegate.state.day != state.day ||
      oldDelegate.state.marketMinute != state.marketMinute ||
      oldDelegate.state.pendingDecisions.length !=
          state.pendingDecisions.length ||
      oldDelegate.phase != phase;
}
