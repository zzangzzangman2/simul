part of 'main.dart';

enum _CasinoTableMotion { idle, deal, reveal, wheel, crapsDice, dice, reels }

Duration _casinoTableMotionDuration(_CasinoTableMotion motion) =>
    switch (motion) {
      _CasinoTableMotion.deal => const Duration(milliseconds: 2200),
      _CasinoTableMotion.reveal => const Duration(milliseconds: 1350),
      _CasinoTableMotion.wheel => const Duration(milliseconds: 2100),
      _CasinoTableMotion.crapsDice => const Duration(milliseconds: 1750),
      _CasinoTableMotion.dice => const Duration(milliseconds: 1500),
      _CasinoTableMotion.reels => const Duration(milliseconds: 1900),
      _CasinoTableMotion.idle => Duration.zero,
    };

String _casinoTableMotionLabel(_CasinoTableMotion motion) => switch (motion) {
  _CasinoTableMotion.deal => '카드를 배분하고 있습니다',
  _CasinoTableMotion.reveal => '딜러 패를 공개하고 있습니다',
  _CasinoTableMotion.wheel => '볼이 휠을 돌고 있습니다',
  _CasinoTableMotion.crapsDice => '두 주사위가 테이블을 굴러가고 있습니다',
  _CasinoTableMotion.dice => '주사위가 슈트 안에서 구르고 있습니다',
  _CasinoTableMotion.reels => '릴이 회전하고 있습니다',
  _CasinoTableMotion.idle => '베팅 접수 대기',
};

class _CasinoLiveTableStage extends StatefulWidget {
  const _CasinoLiveTableStage({
    required this.game,
    required this.motion,
    required this.motionToken,
    required this.stake,
    required this.betLabel,
    required this.blackjackHand,
    required this.crapsRound,
    required this.latest,
    required this.reduceMotion,
  });

  final CasinoGameType game;
  final _CasinoTableMotion motion;
  final int motionToken;
  final int stake;
  final String betLabel;
  final BlackjackHandState? blackjackHand;
  final CrapsRoundState? crapsRound;
  final CasinoRoundRecord? latest;
  final bool reduceMotion;

  @override
  State<_CasinoLiveTableStage> createState() => _CasinoLiveTableStageState();
}

class _CasinoLiveTableStageState extends State<_CasinoLiveTableStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    value: 1,
  );

  @override
  void didUpdateWidget(covariant _CasinoLiveTableStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.motionToken == oldWidget.motionToken) return;
    _motion.duration = _casinoTableMotionDuration(widget.motion);
    if (widget.reduceMotion || widget.motion == _CasinoTableMotion.idle) {
      _motion.value = 1;
    } else {
      _motion.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: const Key('casino-live-table-repaint'),
    child: Semantics(
      label:
          '${casinoGameTitle(widget.game)} 여성 딜러 실시간 테이블. ${_casinoTableMotionLabel(widget.motion)}.',
      liveRegion: true,
      child: Container(
        key: const Key('casino-live-table-stage'),
        height: 272,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _casinoGold.withValues(alpha: 0.78)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  const Positioned.fill(child: _CasinoFeltSurface()),
                  _buildCameraBar(),
                  Positioned(
                    top: 42,
                    right: 14,
                    child: _CasinoCardShoe(
                      active: widget.motion == _CasinoTableMotion.deal,
                    ),
                  ),
                  Positioned.fill(child: _buildGameSurface(size)),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: Center(
                      child: _CasinoChipStack(
                        stake: widget.stake,
                        label: widget.betLabel,
                        progress: _motion.value,
                        active: _movesBettingChips,
                      ),
                    ),
                  ),
                  if (_usesDealerHands) ..._buildDealerMotion(size),
                  if (!_usesDealerHands && _movesBettingChips)
                    ..._buildChipDealerMotion(size),
                  if (widget.latest != null &&
                      widget.motion == _CasinoTableMotion.idle)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 8,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xDD130E0C),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: _casinoGold.withValues(alpha: 0.62),
                              ),
                            ),
                            child: Text(
                              widget.latest!.outcome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );

  bool get _usesDealerHands =>
      widget.game == CasinoGameType.baccarat ||
      widget.game == CasinoGameType.blackjack;

  bool get _movesBettingChips =>
      widget.motion != _CasinoTableMotion.idle &&
      !(widget.game == CasinoGameType.craps && widget.crapsRound != null);

  bool get _isSinglePlayerDraw =>
      widget.game == CasinoGameType.blackjack && widget.blackjackHand != null;

  bool get _collectsBeforeDeal =>
      widget.motion == _CasinoTableMotion.deal &&
      !_isSinglePlayerDraw &&
      widget.latest != null;

  int get _dealCardCount => _isSinglePlayerDraw ? 1 : 4;

  double get _dealProgress {
    if (!_collectsBeforeDeal) return _motion.value;
    return ((_motion.value - 0.18) / 0.82).clamp(0.0, 1.0);
  }

  Widget _buildCameraBar() => Positioned(
    left: 10,
    right: 10,
    top: 9,
    child: Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFFFF5D58),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x99FF5D58), blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'LIVE · 여성 딜러 CAM 03',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _casinoTableMotionLabel(widget.motion),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFFDCC791),
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildGameSurface(Size size) => switch (widget.game) {
    CasinoGameType.baccarat ||
    CasinoGameType.blackjack => _buildCardSurface(size),
    CasinoGameType.roulette => _CasinoRouletteSurface(
      progress: _motion.value,
      active: widget.motion == _CasinoTableMotion.wheel,
      detail: widget.latest?.detail,
    ),
    CasinoGameType.craps => _CasinoCrapsSurface(
      progress: _motion.value,
      active: widget.motion == _CasinoTableMotion.crapsDice,
      detail: widget.latest?.detail,
      round: widget.crapsRound,
    ),
    CasinoGameType.sicBo => _CasinoDiceSurface(
      progress: _motion.value,
      active: widget.motion == _CasinoTableMotion.dice,
      detail: widget.latest?.detail,
    ),
    CasinoGameType.slots => _CasinoReelSurface(
      progress: _motion.value,
      active: widget.motion == _CasinoTableMotion.reels,
      detail: widget.latest?.detail,
    ),
  };

  Widget _buildCardSurface(Size size) {
    final cards = _tableCards;
    final dealing = widget.motion == _CasinoTableMotion.deal;
    final revealing = widget.motion == _CasinoTableMotion.reveal;
    final staticOpacity = dealing
        ? _isSinglePlayerDraw
              ? 1.0
              : _collectsBeforeDeal
              ? (1 - (_motion.value / 0.18)).clamp(0.0, 1.0)
              : 0.0
        : revealing
        ? (1 - Curves.easeIn.transform((_motion.value * 1.4).clamp(0.0, 1.0)))
        : 1.0;
    return Stack(
      children: [
        Positioned(
          left: 16,
          top: 48,
          child: _CasinoSeatLabel(
            title: widget.game == CasinoGameType.baccarat ? 'BANKER' : 'DEALER',
          ),
        ),
        Positioned(
          left: 16,
          top: 132,
          child: _CasinoSeatLabel(
            title: widget.game == CasinoGameType.baccarat ? 'PLAYER' : 'YOU',
          ),
        ),
        Positioned(
          left: 70,
          right: 66,
          top: 43,
          child: Opacity(
            opacity: staticOpacity,
            child: _CasinoCardFan(
              key: ValueKey('dealer-${cards.dealer.join('-')}'),
              cards: cards.dealer,
              alignRight: true,
            ),
          ),
        ),
        Positioned(
          left: 70,
          right: 66,
          top: 134,
          child: Opacity(
            opacity: staticOpacity,
            child: _CasinoCardFan(
              key: ValueKey('player-${cards.player.join('-')}'),
              cards: cards.player,
            ),
          ),
        ),
        if (dealing) ..._buildSettledDealCards(size),
        if (dealing) _buildFlyingCard(size),
      ],
    );
  }

  ({List<String?> dealer, List<String?> player}) get _tableCards {
    final hand = widget.blackjackHand;
    if (widget.game == CasinoGameType.blackjack && hand != null) {
      return (
        dealer: <String?>[casinoCardLabel(hand.dealerCards.first), null],
        player: hand.playerCards.map(casinoCardLabel).toList(growable: false),
      );
    }
    final detail = widget.latest?.detail ?? '';
    if (widget.game == CasinoGameType.baccarat) {
      return (
        dealer: _extractCardLabels(detail, 'B'),
        player: _extractCardLabels(detail, 'P'),
      );
    }
    if (widget.game == CasinoGameType.blackjack) {
      return (
        dealer: _extractCardLabels(detail, '딜러'),
        player: _extractCardLabels(detail, '플레이어'),
      );
    }
    return (dealer: const <String?>[], player: const <String?>[]);
  }

  List<String?> _extractCardLabels(String detail, String prefix) {
    final match = RegExp(
      '${RegExp.escape(prefix)} (.+?) \\(',
    ).firstMatch(detail);
    if (match == null) return const <String?>[];
    return match
        .group(1)!
        .split(RegExp(r'\s+'))
        .where((label) => label.isNotEmpty)
        .cast<String?>()
        .toList(growable: false);
  }

  ({int index, double local, bool dealerTarget}) _dealPhase() {
    final count = _dealCardCount;
    final cycle = (_dealProgress * count).clamp(0.0, count - 0.001);
    final index = cycle.floor();
    return (
      index: index,
      local: cycle - index,
      dealerTarget: !_isSinglePlayerDraw && index.isEven,
    );
  }

  Offset _dealStart(Size size) => Offset(size.width - 39.5, 60);

  Offset _dealTarget(Size size, int index, bool dealerTarget) {
    final seatCardIndex = _isSinglePlayerDraw
        ? widget.blackjackHand!.playerCards.length
        : index ~/ 2;
    return dealerTarget
        ? Offset(size.width - 120 + seatCardIndex * 31, 75)
        : Offset(93 + seatCardIndex * 31, 166);
  }

  double _cardCarry(double local) =>
      Curves.easeInOutCubic.transform(((local - 0.12) / 0.64).clamp(0.0, 1.0));

  List<Widget> _buildSettledDealCards(Size size) {
    if (_collectsBeforeDeal && _motion.value < 0.18) {
      return const <Widget>[];
    }
    final phase = _dealPhase();
    return <Widget>[
      for (var index = 0; index < phase.index; index++)
        Positioned(
          left:
              _dealTarget(
                size,
                index,
                !_isSinglePlayerDraw && index.isEven,
              ).dx -
              23,
          top:
              _dealTarget(
                size,
                index,
                !_isSinglePlayerDraw && index.isEven,
              ).dy -
              32,
          child: const _PremiumCasinoCard(hidden: true),
        ),
    ];
  }

  Widget _buildFlyingCard(Size size) {
    if (_collectsBeforeDeal && _motion.value < 0.18) {
      return const SizedBox.shrink();
    }
    final phase = _dealPhase();
    final carry = _cardCarry(phase.local);
    final start = _dealStart(size);
    final target = _dealTarget(size, phase.index, phase.dealerTarget);
    final position = Offset.lerp(start, target, carry)!;
    return Positioned(
      key: const Key('casino-flying-card'),
      left: position.dx - 23,
      top: position.dy - 32,
      child: Transform.rotate(
        angle: (1 - carry) * 0.16 * (phase.dealerTarget ? 1 : -1),
        child: const _PremiumCasinoCard(hidden: true),
      ),
    );
  }

  List<Widget> _buildDealerMotion(Size size) {
    final t = _motion.value;
    if (widget.motion == _CasinoTableMotion.idle || t >= 1) {
      return const <Widget>[];
    }
    final collecting = widget.motion == _CasinoTableMotion.reveal;
    if (collecting) {
      final curve = math.sin(t * math.pi);
      return <Widget>[
        Positioned(
          key: const Key('casino-dealer-collect-hand'),
          right: -54 + curve * 82,
          top: -182 + curve * 86,
          child: Transform.rotate(
            angle: -0.08 + curve * 0.12,
            child: Image.asset(
              'assets/images/casino/dealer_hand_collect_v1.png',
              width: 178,
              height: 267,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ];
    }

    if (_collectsBeforeDeal && t < 0.18) {
      final collect = Curves.easeInOut.transform((t / 0.18).clamp(0.0, 1.0));
      return <Widget>[
        Positioned(
          key: const Key('casino-dealer-collect-hand'),
          right: -74 + collect * 96,
          top: -168 + collect * 72,
          child: Image.asset(
            'assets/images/casino/dealer_hand_collect_v1.png',
            width: 166,
            height: 249,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ];
    }

    final phase = _dealPhase();
    final carry = _cardCarry(phase.local);
    final release = Curves.easeInOutCubic.transform(
      ((phase.local - 0.78) / 0.20).clamp(0.0, 1.0),
    );
    final start = _dealStart(size);
    final target = _dealTarget(size, phase.index, phase.dealerTarget);
    final cardCenter = Offset.lerp(start, target, carry)!;
    final fingertip = Offset.lerp(cardCenter, start, release)!;
    return <Widget>[
      Positioned(
        key: const Key('casino-dealer-deal-hand'),
        left: fingertip.dx - 74,
        top: fingertip.dy - 202,
        child: Transform.rotate(
          angle: (phase.dealerTarget ? -0.035 : 0.035) * carry,
          child: Image.asset(
            'assets/images/casino/dealer_hand_deal_v1.png',
            width: 148,
            height: 222,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildChipDealerMotion(Size size) {
    final t = _motion.value;
    if (t >= 0.56) return const <Widget>[];
    final local = (t / 0.56).clamp(0.0, 1.0);
    final reach = math.sin(local * math.pi);
    return <Widget>[
      Positioned(
        key: const Key('casino-dealer-chip-hand'),
        right: -92 + reach * (size.width * 0.42),
        top: -196 + reach * 166,
        child: Transform.rotate(
          angle: -0.12 + reach * 0.15,
          child: Image.asset(
            'assets/images/casino/dealer_hand_collect_v1.png',
            width: 176,
            height: 264,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    ];
  }
}

class _CasinoFeltSurface extends StatelessWidget {
  const _CasinoFeltSurface();

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _CasinoFeltPainter(),
    child: const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.35),
          radius: 1.2,
          colors: [Color(0xFF176A50), Color(0xFF0A4434), Color(0xFF06281F)],
          stops: [0, 0.58, 1],
        ),
      ),
    ),
  );
}

class _CasinoFeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = _casinoGold.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = Offset(size.width / 2, size.height * 0.58);
    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.86,
        height: size.height * 0.82,
      ),
      math.pi,
      math.pi,
      false,
      gold,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.60,
        height: size.height * 0.52,
      ),
      math.pi,
      math.pi,
      false,
      gold,
    );
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 0.6;
    for (var y = 40.0; y < size.height; y += 8) {
      canvas.drawLine(Offset.zero.translate(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CasinoSeatLabel extends StatelessWidget {
  const _CasinoSeatLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48,
    child: Text(
      title,
      style: TextStyle(
        color: _casinoGold.withValues(alpha: 0.86),
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _CasinoCardShoe extends StatelessWidget {
  const _CasinoCardShoe({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    width: 51,
    height: 36,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0xFF171311),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: active ? _casinoGold : const Color(0xFF6B5B4D)),
      boxShadow: [
        BoxShadow(
          color: active
              ? _casinoGold.withValues(alpha: 0.22)
              : const Color(0x66000000),
          blurRadius: active ? 11 : 6,
        ),
      ],
    ),
    child: Stack(
      children: List<Widget>.generate(
        4,
        (index) => Positioned(
          left: index * 2.5,
          right: 7 - index * 2.0,
          top: index * 2.5,
          bottom: 7 - index * 1.5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _casinoWine,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: _casinoGold, width: 0.6),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CasinoCardFan extends StatelessWidget {
  const _CasinoCardFan({
    super.key,
    required this.cards,
    this.alignRight = false,
  });
  final List<String?> cards;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final visible = cards.isEmpty ? const <String?>[null, null] : cards;
    return SizedBox(
      height: 70,
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: SizedBox(
          width: 46 + (visible.length - 1) * 31,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < visible.length; index++)
                Positioned(
                  left: index * 31,
                  top: (index - (visible.length - 1) / 2).abs() * 1.8,
                  child: Transform.rotate(
                    angle: (index - (visible.length - 1) / 2) * 0.035,
                    child: _FlippingCasinoCard(
                      key: ValueKey('${visible[index]}-$index'),
                      label: visible[index],
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

class _FlippingCasinoCard extends StatelessWidget {
  const _FlippingCasinoCard({super.key, required this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return const _PremiumCasinoCard(hidden: true);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 460),
      curve: Curves.easeInOutCubic,
      builder: (context, value, _) {
        final firstHalf = value < 0.5;
        final horizontalScale = (value - 0.5).abs() * 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0014)
            ..rotateY((1 - value) * math.pi),
          child: Transform.scale(
            scaleX: horizontalScale.clamp(0.04, 1.0),
            child: _PremiumCasinoCard(
              label: firstHalf ? null : label,
              hidden: firstHalf,
            ),
          ),
        );
      },
    );
  }
}

class _PremiumCasinoCard extends StatelessWidget {
  const _PremiumCasinoCard({
    this.label,
    required this.hidden,
    this.width = 46,
    this.height = 64,
  });

  final String? label;
  final bool hidden;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final raw = label ?? '';
    const suits = <String>{'♠', '♥', '♦', '♣'};
    final suitIsFirst = raw.isNotEmpty && suits.contains(raw.substring(0, 1));
    final suit = raw.isEmpty
        ? ''
        : suitIsFirst
        ? raw.substring(0, 1)
        : raw.substring(raw.length - 1);
    final rank = raw.isEmpty
        ? ''
        : suitIsFirst
        ? raw.substring(1)
        : raw.substring(0, raw.length - 1);
    final red = suit == '♥' || suit == '♦';
    final ink = red ? const Color(0xFFB9283C) : const Color(0xFF151515);
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: hidden
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF85273C), Color(0xFF47101E)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFEFA), Color(0xFFECE3D4)],
              ),
        borderRadius: BorderRadius.circular(width * 0.13),
        border: Border.all(
          color: hidden ? _casinoGold : const Color(0xFFDDD0BB),
          width: 1.15,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x44FFFFFF),
            blurRadius: 2,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: hidden
          ? CustomPaint(painter: _CasinoCardBackPainter())
          : Stack(
              children: [
                Positioned(
                  left: width * 0.10,
                  top: height * 0.07,
                  child: _CasinoCardCorner(rank: rank, suit: suit, color: ink),
                ),
                Center(
                  child: Text(
                    suit,
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.93),
                      fontSize: height * 0.34,
                      height: 1,
                      shadows: const [
                        Shadow(
                          color: Color(0x22000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: width * 0.10,
                  bottom: height * 0.07,
                  child: Transform.rotate(
                    angle: math.pi,
                    child: _CasinoCardCorner(
                      rank: rank,
                      suit: suit,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CasinoCardCorner extends StatelessWidget {
  const _CasinoCardCorner({
    required this.rank,
    required this.suit,
    required this.color,
  });
  final String rank;
  final String suit;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        rank,
        style: TextStyle(
          color: color,
          fontSize: 10,
          height: 0.9,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(suit, style: TextStyle(color: color, fontSize: 8, height: 0.9)),
    ],
  );
}

class _CasinoCardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = _casinoGold.withValues(alpha: 0.62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final inset = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, const Radius.circular(4)),
      line,
    );
    final center = Offset(size.width / 2, size.height / 2);
    for (var scale = 0.18; scale <= 0.72; scale += 0.18) {
      final path = Path()
        ..moveTo(center.dx, center.dy - size.height * scale / 2)
        ..lineTo(center.dx + size.width * scale / 2, center.dy)
        ..lineTo(center.dx, center.dy + size.height * scale / 2)
        ..lineTo(center.dx - size.width * scale / 2, center.dy)
        ..close();
      canvas.drawPath(path, line);
    }
    canvas.drawCircle(center, size.shortestSide * 0.08, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CasinoChipStack extends StatelessWidget {
  const _CasinoChipStack({
    required this.stake,
    required this.label,
    required this.progress,
    required this.active,
  });
  final int stake;
  final String label;
  final double progress;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final move = active
        ? Curves.easeOutBack.transform(progress.clamp(0.0, 1.0))
        : 1.0;
    final chipColor = stake >= 100000
        ? const Color(0xFF202020)
        : stake >= 50000
        ? const Color(0xFF9A2438)
        : stake >= 20000
        ? const Color(0xFF285E9E)
        : const Color(0xFFE8E1D1);
    return Transform.translate(
      offset: Offset(0, (1 - move) * 64),
      child: Opacity(
        opacity: active ? progress.clamp(0.0, 1.0) : 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 39,
              height: 28,
              child: Stack(
                children: [
                  for (var index = 0; index < 4; index++)
                    Positioned(
                      left: 4.0,
                      bottom: index * 3.5,
                      child: Container(
                        width: 31,
                        height: 12,
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: _casinoGold, width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 3,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Container(
              constraints: const BoxConstraints(maxWidth: 118),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xB814100E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _casinoGold.withValues(alpha: 0.45)),
              ),
              child: Text(
                '$label · ${_money(stake)}원',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
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

class _CasinoRouletteSurface extends StatelessWidget {
  const _CasinoRouletteSurface({
    required this.progress,
    required this.active,
    required this.detail,
  });
  final double progress;
  final bool active;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final turns = active
        ? Curves.decelerate.transform(progress) * math.pi * 9
        : 0.0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 28),
        child: Transform.rotate(
          angle: turns,
          child: CustomPaint(
            key: const Key('casino-roulette-wheel'),
            size: const Size.square(170),
            painter: _CasinoRoulettePainter(ballAngle: -turns * 1.42),
          ),
        ),
      ),
    );
  }
}

class _CasinoRoulettePainter extends CustomPainter {
  const _CasinoRoulettePainter({required this.ballAngle});
  final double ballAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final gold = Paint()..color = _casinoGold;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF211612));
    for (var index = 0; index < 18; index++) {
      final paint = Paint()
        ..color = index.isEven
            ? const Color(0xFF8A1D31)
            : const Color(0xFF171717)
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 7),
        index * math.pi * 2 / 18,
        math.pi * 2 / 18 - 0.015,
        true,
        paint,
      );
    }
    canvas.drawCircle(
      center,
      radius * 0.52,
      Paint()..color = const Color(0xFF5B371E),
    );
    canvas.drawCircle(center, radius * 0.24, gold);
    canvas.drawCircle(
      center,
      radius * 0.12,
      Paint()..color = const Color(0xFF24150E),
    );
    final ballCenter =
        center +
        Offset(math.cos(ballAngle), math.sin(ballAngle)) * radius * 0.74;
    canvas.drawCircle(ballCenter, 5, Paint()..color = const Color(0xFFF8F1DA));
  }

  @override
  bool shouldRepaint(covariant _CasinoRoulettePainter oldDelegate) =>
      oldDelegate.ballAngle != ballAngle;
}

class _CasinoCrapsSurface extends StatelessWidget {
  const _CasinoCrapsSurface({
    required this.progress,
    required this.active,
    required this.detail,
    required this.round,
  });

  final double progress;
  final bool active;
  final String? detail;
  final CrapsRoundState? round;

  List<int> get _settledDice {
    if (round != null && round!.rolls.isNotEmpty) {
      return round!.rolls.last;
    }
    final matches = RegExp(r'(\d)\+(\d)=\d+').allMatches(detail ?? '');
    if (matches.isEmpty) return const <int>[3, 4];
    final match = matches.last;
    return <int>[int.parse(match.group(1)!), int.parse(match.group(2)!)];
  }

  @override
  Widget build(BuildContext context) {
    const pointNumbers = <int>[4, 5, 6, 8, 9, 10];
    final settled = _settledDice;
    final displayed = active
        ? <int>[
            ((progress * 31).floor() + 1) % 6 + 1,
            ((progress * 43).floor() + 4) % 6 + 1,
          ]
        : settled;
    final travel = Curves.easeOutCubic.transform(progress);
    final bounce = active ? math.sin(progress * math.pi * 5).abs() : 0.0;
    final spread = active ? (1 - travel) * 46 : 0.0;
    return Stack(
      children: [
        Positioned(
          left: 16,
          right: 16,
          top: 47,
          child: Row(
            children: [
              for (final point in pointNumbers) ...[
                if (point != pointNumbers.first) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0x22100B09),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0x99E5D4AC)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$point',
                          style: const TextStyle(
                            color: Color(0xFFF4E6C9),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (round?.point == point)
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF2E7D5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'ON',
                                  style: TextStyle(
                                    color: Color(0xFF791D2E),
                                    fontSize: 5,
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
              ],
            ],
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          top: 87,
          child: Container(
            height: 103,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(58),
              border: Border.all(color: const Color(0x88E8D8B4), width: 1.1),
            ),
            child: const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 7),
                child: Text(
                  'COME  ·  FIELD  ·  PLACE',
                  style: TextStyle(
                    color: Color(0x77F6E8CB),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 108,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < 2; index++) ...[
                if (index > 0) const SizedBox(width: 18),
                Transform.translate(
                  offset: Offset(
                    index == 0 ? -spread : spread,
                    -bounce * (index == 0 ? 22 : 16),
                  ),
                  child: Transform.rotate(
                    angle: active
                        ? progress * math.pi * (index == 0 ? 7 : -8)
                        : (index == 0 ? -0.1 : 0.12),
                    child: _CasinoDie(value: displayed[index], red: true),
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 32,
          child: Column(
            children: [
              Container(
                height: 25,
                decoration: BoxDecoration(
                  color: const Color(0x227A1D2E),
                  border: Border.all(color: const Color(0xAAE4CF9C)),
                ),
                child: const Center(
                  child: Text(
                    'PASS LINE',
                    style: TextStyle(
                      color: Color(0xFFECD8AA),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x66E4CF9C)),
                ),
                child: const Center(
                  child: Text(
                    "DON'T PASS BAR 12",
                    style: TextStyle(
                      color: Color(0x99ECD8AA),
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CasinoDiceSurface extends StatelessWidget {
  const _CasinoDiceSurface({
    required this.progress,
    required this.active,
    required this.detail,
  });
  final double progress;
  final bool active;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final values = RegExp(r'주사위 (\d) · (\d) · (\d)').firstMatch(detail ?? '');
    final dice = values == null
        ? const <int>[1, 3, 5]
        : <int>[
            int.parse(values.group(1)!),
            int.parse(values.group(2)!),
            int.parse(values.group(3)!),
          ];
    final shake = active
        ? math.sin(progress * math.pi * 12) * (1 - progress) * 18
        : 0.0;
    return Center(
      child: Transform.translate(
        offset: Offset(
          shake,
          active ? math.sin(progress * math.pi * 7).abs() * -16 : 0,
        ),
        child: Row(
          key: const Key('casino-dice-cup'),
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              Transform.rotate(
                angle: active ? progress * math.pi * (index + 2) : 0,
                child: _CasinoDie(value: dice[index]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CasinoDie extends StatelessWidget {
  const _CasinoDie({required this.value, this.red = false});
  final int value;
  final bool red;

  @override
  Widget build(BuildContext context) {
    const points = <int, List<Alignment>>{
      1: [Alignment.center],
      2: [Alignment.topLeft, Alignment.bottomRight],
      3: [Alignment.topLeft, Alignment.center, Alignment.bottomRight],
      4: [
        Alignment.topLeft,
        Alignment.topRight,
        Alignment.bottomLeft,
        Alignment.bottomRight,
      ],
      5: [
        Alignment.topLeft,
        Alignment.topRight,
        Alignment.center,
        Alignment.bottomLeft,
        Alignment.bottomRight,
      ],
      6: [
        Alignment.topLeft,
        Alignment.centerLeft,
        Alignment.bottomLeft,
        Alignment.topRight,
        Alignment.centerRight,
        Alignment.bottomRight,
      ],
    };
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: red
              ? const [Color(0xFFE84F62), Color(0xFF7A1027)]
              : const [Color(0xFFFFFEF8), Color(0xFFDCCEB9)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _casinoGold, width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          for (final point in points[value]!)
            Align(
              alignment: Alignment(point.x * 0.62, point.y * 0.62),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: red
                      ? const Color(0xFFFFF3DC)
                      : value == 1 || value == 4
                      ? _casinoWine
                      : const Color(0xFF202020),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CasinoReelSurface extends StatelessWidget {
  const _CasinoReelSurface({
    required this.progress,
    required this.active,
    required this.detail,
  });
  final double progress;
  final bool active;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    const symbols = <String>['7', 'BAR', '★', '●', '♣', '♦'];
    final parts = (detail ?? '')
        .split('|')
        .map((value) => value.trim())
        .toList();
    return Center(
      child: Container(
        key: const Key('casino-slot-reels'),
        margin: const EdgeInsets.only(top: 25, bottom: 34),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFF201411),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: _casinoGold, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0) const SizedBox(width: 7),
              Container(
                width: 61,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFFEF4),
                      Color(0xFFDCCCB4),
                      Color(0xFFFFFEF4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFF8E744D)),
                ),
                child: Transform.translate(
                  offset: Offset(
                    0,
                    active
                        ? math.sin(progress * math.pi * 14 + index) *
                              22 *
                              (1 - progress)
                        : 0,
                  ),
                  child: Text(
                    active
                        ? symbols[((progress * 30).floor() + index * 2) %
                              symbols.length]
                        : index < parts.length
                        ? parts[index].split(' ').first
                        : symbols[index],
                    style: TextStyle(
                      color: index == 0 ? _casinoWine : const Color(0xFF1E1A16),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
