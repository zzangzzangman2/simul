part of 'main.dart';

enum _AppView { title, continueGame, onboarding, game }

enum _GameMenuAction { save, title }

class _GameTitleScreen extends StatelessWidget {
  const _GameTitleScreen({
    required this.occupiedSlots,
    required this.onNewGame,
    required this.onContinue,
  });

  final int occupiedSlots;
  final VoidCallback onNewGame;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('game-title-screen'),
    backgroundColor: const Color(0xFF061F2A),
    body: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF061923), Color(0xFF0B3340), Color(0xFF102A37)],
            ),
          ),
        ),
        Positioned(
          top: -54,
          right: -58,
          child: Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x55FFD15B),
            ),
          ),
        ),
        Positioned(
          top: 170,
          left: -46,
          child: Container(
            width: 116,
            height: 116,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x44F44D46),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 740;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  compact ? 14 : 22,
                  20,
                  compact ? 14 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0B2632,
                            ).withValues(alpha: 0.84),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: const Color(0x66FFD76A)),
                          ),
                          child: const Text(
                            '서울 · 2000년',
                            style: TextStyle(
                              color: Color(0xFFFFE49A),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$occupiedSlots / ${GamePersistence.slotCount} 저장',
                          style: const TextStyle(
                            color: Color(0xFFB9D6D7),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 10 : 16),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _yellow,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0xFFFFC84F)),
                        ),
                        child: const Text(
                          '세뱃돈 1만원 시작!',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 7 : 9),
                    Text(
                      '초딩부터 건물주',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFFFF4C6),
                        fontFamily: 'Maplestory',
                        fontSize: compact ? 31 : 37,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        shadows: const [
                          Shadow(
                            color: Color(0xFFE6463E),
                            offset: Offset(0, 3),
                          ),
                          Shadow(color: Color(0xAAFFCF4D), blurRadius: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '세뱃돈 1만원으로 시작하는 꼬마 투자왕의 꿈',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD4E8E3),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 282),
                          child: AspectRatio(
                            aspectRatio: 1.5,
                            child: const _AnimatedTitleHero(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    _TitleActionButton(
                      key: const Key('new-game-button'),
                      icon: Icons.auto_awesome_rounded,
                      label: '처음하기',
                      detail: occupiedSlots >= GamePersistence.slotCount
                          ? '슬롯이 가득 찼어요 · 저장 삭제 후 시작'
                          : '나만의 건물주 이야기를 시작해요',
                      filled: true,
                      onPressed: onNewGame,
                    ),
                    const SizedBox(height: 9),
                    _TitleActionButton(
                      key: const Key('continue-game-button'),
                      icon: Icons.folder_open_rounded,
                      label: '이어하기',
                      detail: occupiedSlots == 0
                          ? '저장된 게임이 없습니다'
                          : '저장 슬롯 $occupiedSlots개',
                      filled: false,
                      onPressed: onContinue,
                    ),
                    SizedBox(height: compact ? 9 : 13),
                    const Text(
                      '최대 5개 저장 · 하루 종료 자동저장 · 언제든 수동저장',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF718783),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _AnimatedTitleHero extends StatefulWidget {
  const _AnimatedTitleHero();

  @override
  State<_AnimatedTitleHero> createState() => _AnimatedTitleHeroState();
}

class _AnimatedTitleHeroState extends State<_AnimatedTitleHero>
    with SingleTickerProviderStateMixin {
  static const _asset = 'assets/images/title_elementary_landlord_hero.png';

  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    final isWidgetTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (!isWidgetTest) _motion.repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFFFFD86A), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66FFB83E),
          blurRadius: 22,
          spreadRadius: -5,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, _) {
          final breath = math.sin(_motion.value * math.pi * 2);
          final breeze = math.sin(_motion.value * math.pi * 4);
          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: 1.018 + breath * 0.006,
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(0, breath * 1.7),
                  child: Semantics(
                    key: const Key('title-cartoon-hero'),
                    image: true,
                    label: '초딩부터 건물주, 액자 밖으로 손을 내미는 꼬마 투자자',
                    child: Image.asset(_asset, fit: BoxFit.cover),
                  ),
                ),
              ),
              Transform.rotate(
                angle: breeze * 0.007,
                alignment: const Alignment(-0.78, 0.66),
                child: ClipPath(
                  clipper: _HeroHandClipper(),
                  child: Image.asset(_asset, fit: BoxFit.cover),
                ),
              ),
              Transform.rotate(
                angle: breeze * -0.005,
                alignment: const Alignment(0.1, -0.72),
                child: ClipPath(
                  clipper: _HeroBeretClipper(),
                  child: Image.asset(_asset, fit: BoxFit.cover),
                ),
              ),
              CustomPaint(painter: _HeroMotionPainter(_motion.value)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x18001822)],
                    stops: [0.68, 1],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _HeroHandClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, size.height * 0.36)
    ..lineTo(size.width * 0.38, size.height * 0.33)
    ..lineTo(size.width * 0.48, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HeroBeretClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * 0.37, 0)
    ..lineTo(size.width * 0.73, 0)
    ..lineTo(size.width * 0.7, size.height * 0.48)
    ..lineTo(size.width * 0.4, size.height * 0.52)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HeroMotionPainter extends CustomPainter {
  const _HeroMotionPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = const Color(
        0xFFFFE779,
      ).withValues(alpha: 0.45 + 0.35 * math.sin(progress * math.pi * 6).abs())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final crisp = Paint()..color = const Color(0xFFFFF7BF);
    final sparkles = <Offset>[
      Offset(size.width * 0.12, size.height * 0.26),
      Offset(size.width * 0.78, size.height * 0.18),
      Offset(size.width * 0.87, size.height * 0.58),
      Offset(size.width * 0.62, size.height * 0.82),
    ];
    for (var i = 0; i < sparkles.length; i++) {
      final pulse = (math.sin(progress * math.pi * 2 + i * 1.7) + 1) * 0.5;
      final point = sparkles[i];
      canvas.drawCircle(point, 2 + pulse * 3, glow);
      canvas.drawCircle(point, 0.8 + pulse, crisp);
    }

    final arrowPaint = Paint()
      ..color = const Color(
        0xFFFF4E45,
      ).withValues(alpha: 0.25 + progress * 0.55)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final local = (progress + i / 3) % 1;
      final x = size.width * (0.58 + i * 0.12);
      final y = size.height * (0.78 - local * 0.55);
      canvas.drawLine(Offset(x, y + 9), Offset(x, y), arrowPaint);
      canvas.drawLine(Offset(x, y), Offset(x - 4, y + 4), arrowPaint);
      canvas.drawLine(Offset(x, y), Offset(x + 4, y + 4), arrowPaint);
    }

    final notePaint = Paint()..color = const Color(0x99BDE9D0);
    final coinPaint = Paint()..color = const Color(0xCCFFD65A);
    for (var i = 0; i < 8; i++) {
      final local = (progress + i * 0.137) % 1;
      final x = size.width * ((i * 0.283 + local * 0.16) % 1);
      final y = size.height * (1.05 - local * 1.12);
      if (i.isEven) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: 3 + local * 5,
            height: 1.5 + local * 2.5,
          ),
          coinPaint,
        );
      } else {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(math.sin(progress * math.pi * 2 + i) * 0.45);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: 7 + local * 5,
              height: 4 + local * 3,
            ),
            const Radius.circular(1),
          ),
          notePaint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeroMotionPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _TitleActionButton extends StatelessWidget {
  const _TitleActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.detail,
    required this.filled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String detail;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: filled ? const Color(0xFFFFCC57) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: filled ? const Color(0xFFFFB936) : const Color(0xFFC9E2DC),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1745635E),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white.withValues(alpha: 0.72)
                      : const Color(0xFFE5F6F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF39766D), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF657A76),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: filled
                      ? const Color(0x22FFFFFF)
                      : const Color(0xFFEFF8F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: _ink,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SaveSlotScreen extends StatelessWidget {
  const _SaveSlotScreen({
    required this.slots,
    required this.activeSlot,
    required this.onLoad,
    required this.onDelete,
    required this.onBack,
  });

  final List<GameSaveSlot> slots;
  final int activeSlot;
  final Future<void> Function(int slot) onLoad;
  final Future<void> Function(int slot) onDelete;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('save-slot-screen'),
    backgroundColor: const Color(0xFF0C1321),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  key: const Key('save-slots-back-button'),
                  tooltip: '뒤로',
                  onPressed: onBack,
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이어하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      Text(
                        '저장 선택 · 삭제는 휴지통 버튼',
                        style: TextStyle(
                          color: Color(0xFF8393AD),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF17233A),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${slots.where((slot) => !slot.isEmpty).length} / ${GamePersistence.slotCount}',
                    style: const TextStyle(
                      color: Color(0xFFFFD76A),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 22),
              itemCount: slots.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final slot = slots[index];
                return _SaveSlotCard(
                  key: Key('save-slot-${slot.slot}'),
                  slot: slot,
                  isActive: activeSlot == slot.slot,
                  onLoad: () => onLoad(slot.slot),
                  onDelete: () => _confirmDelete(context, slot),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _confirmDelete(BuildContext context, GameSaveSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${slot.slot}번 저장을 삭제할까요?'),
        content: const Text('삭제하면 이 진행 기록과 백업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton.tonal(
            key: Key('confirm-delete-slot-${slot.slot}'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) await onDelete(slot.slot);
  }
}

class _SaveSlotCard extends StatelessWidget {
  const _SaveSlotCard({
    super.key,
    required this.slot,
    required this.isActive,
    required this.onLoad,
    required this.onDelete,
  });

  final GameSaveSlot slot;
  final bool isActive;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final state = slot.state;
    final accent = slot.isCorrupt
        ? const Color(0xFFFF8179)
        : state == null
        ? const Color(0xFF4D5B72)
        : const Color(0xFFFFD76A);
    return Material(
      color: const Color(0xFF151F31),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('load-save-slot-${slot.slot}'),
        onTap: slot.canContinue ? onLoad : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive && slot.canContinue
                  ? const Color(0xB3FFD76A)
                  : const Color(0xFF283750),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withValues(alpha: 0.42)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${slot.slot}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _slotDetails(state)),
              if (!slot.isEmpty)
                IconButton(
                  key: Key('delete-save-slot-${slot.slot}'),
                  tooltip: '저장 삭제',
                  onPressed: onDelete,
                  color: const Color(0xFF92A1B8),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotDetails(GameState? state) {
    if (slot.isCorrupt) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '손상된 저장',
            style: TextStyle(
              color: Color(0xFFFF8179),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '불러올 수 없습니다. 삭제 후 슬롯을 다시 사용하세요.',
            style: TextStyle(color: Color(0xFF8C9BB2), fontSize: 10),
          ),
        ],
      );
    }
    if (state == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '빈 슬롯',
            style: TextStyle(
              color: Color(0xFF8594AA),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '처음하기를 선택하면 가장 앞의 빈 슬롯에 저장됩니다.',
            style: TextStyle(color: Color(0xFF5E6C82), fontSize: 10),
          ),
        ],
      );
    }
    final date = state.currentDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                state.companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              const Text(
                '최근',
                style: TextStyle(
                  color: Color(0xFFFFD76A),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} · DAY ${state.day} · LV.${state.progression.level}',
          style: const TextStyle(
            color: Color(0xFF9AABC4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${_money(state.cash)}원 · ${_savedAtLabel(slot.savedAt)}',
          style: const TextStyle(
            color: Color(0xFF6F809A),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String _savedAtLabel(DateTime? value) {
  if (value == null) return '기존 저장';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}.${two(local.month)}.${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
