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
    backgroundColor: _cream,
    body: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFDDF8F3), Color(0xFFEAF8F0), _cream],
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
              color: Color(0x66FFDF68),
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
              color: Color(0x55FF7D72),
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
                            color: Colors.white.withValues(alpha: 0.86),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: const Color(0xFFBBDDD7)),
                          ),
                          child: const Text(
                            '서울 · 2000년',
                            style: TextStyle(
                              color: Color(0xFF39766D),
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
                            color: Color(0xFF66837E),
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
                      '부자되기\n시뮬레이션',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ink,
                        fontSize: compact ? 31 : 35,
                        height: 0.98,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '2000년 서울, 우리 가족의 작은 저금통부터 시작해요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF58736E),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 260),
                          child: AspectRatio(
                            aspectRatio: 1.5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1F496A63),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Semantics(
                                key: const Key('title-cartoon-hero'),
                                image: true,
                                label: '서울 2000년 부자되기 카툰 일러스트',
                                child: Image.asset(
                                  'assets/images/title_wealth_sim_hero.webp',
                                  fit: BoxFit.cover,
                                  alignment: const Alignment(0, 0.38),
                                ),
                              ),
                            ),
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
                          : '새로운 부자 이야기를 시작해요',
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
