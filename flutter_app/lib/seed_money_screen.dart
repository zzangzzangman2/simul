part of 'main.dart';

class SeedMoneyHubScreen extends StatefulWidget {
  const SeedMoneyHubScreen({
    super.key,
    required this.state,
    required this.onComplete,
  });

  final GameState state;
  final Future<GameState> Function(WorkSessionResult result) onComplete;

  @override
  State<SeedMoneyHubScreen> createState() => _SeedMoneyHubScreenState();
}

class _SeedMoneyHubScreenState extends State<SeedMoneyHubScreen> {
  late GameState _state = widget.state;
  bool _saving = false;

  int get _earned =>
      (_state.story.storyFlags['earnedSeedMoney'] as num?)?.toInt() ?? 0;
  int get _today {
    final recordedDay = (_state.story.storyFlags['workDay'] as num?)?.toInt();
    if (recordedDay != _state.day) return 0;
    return (_state.story.storyFlags['workSessionsToday'] as num?)?.toInt() ?? 0;
  }

  Future<void> _openGame(WorkActivityInfo activity) async {
    if (_saving || _today >= 3) return;
    final cashBefore = _state.cash;
    final result = await Navigator.of(context).push<WorkSessionResult>(
      _gameSceneRoute<WorkSessionResult>(switch (activity.id) {
        'dishes' => const DishwashingMiniGame(),
        'stationery' => const StationerySortMiniGame(),
        _ => const FleaMarketMiniGame(),
      }),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    late GameState next;
    try {
      next = await widget.onComplete(result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSaveFailure(context);
      return;
    }
    if (!mounted) return;
    setState(() {
      _state = next;
      _saving = false;
    });
    final paid = next.cash - cashBefore;
    final traitLabel = switch (next.story.startingTrait) {
      StoryTrait.stability => '안정형',
      StoryTrait.innovation => '혁신형',
      StoryTrait.analysis => '분석형',
      StoryTrait.control => '통제형',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '실제 지급 ${_money(paid)}원 · $traitLabel 성향과 해금 스킬 보너스 반영',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_earned / 10000).clamp(0.0, 1.0);
    final age = _state.story.ageOn(_state.currentDate);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3E9),
      body: SafeArea(
        child: Column(
          children: [
            _WorkTopBar(
              title: '오늘 뭐 하고 벌까?',
              subtitle: '${_state.currentDate.year}년 · $age살 · 직접 번 돈만 집계',
              onBack: () => Navigator.of(context).pop(),
            ),
            _SceneClockStrip(
              location: '우리 동네 · 용돈 퀘스트',
              caption: '일을 마치면 수입과 함께 한 시간이 흐른다.',
              minute: _state.marketMinute,
              costLabel: '완료 +60분',
              dark: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                children: [
                  _SeedMoneyIllustratedSummary(
                    cash: _state.cash,
                    earned: _earned,
                    today: _today,
                    progress: progress,
                  ),
                  const SizedBox(height: 13),
                  const _ChorePeriodNotice(),
                  const SizedBox(height: 14),
                  ...workActivities.indexed.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: _WorkActivityCard(
                        questNumber: entry.$1 + 1,
                        activity: entry.$2,
                        disabled: _saving || _today >= 3,
                        onTap: () => _openGame(entry.$2),
                      ),
                    ),
                  ),
                  if (_today >= 3)
                    Container(
                      key: const Key('daily-work-limit'),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3D9A4),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: const Color(0xFF8D6036),
                          width: 1.4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x443A2614),
                            offset: Offset(3, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        '오늘 할 수 있는 일은 충분히 했어요. 공부와 가족 시간을 지키려면 하루를 보낸 뒤 다시 선택하세요.',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 11,
                          height: 1.45,
                          fontWeight: FontWeight.w800,
                        ),
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
}

class _SeedMoneyIllustratedSummary extends StatelessWidget {
  const _SeedMoneyIllustratedSummary({
    required this.cash,
    required this.earned,
    required this.today,
    required this.progress,
  });

  final int cash;
  final int earned;
  final int today;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final reachedGoal = earned >= 10000;
    return Container(
      key: const Key('seed-money-summary'),
      height: 202,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E2C2118),
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/ui_seed_money_quest_header.webp',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x12000000),
                    Color(0x05000000),
                    Color(0xB8211A17),
                  ],
                  stops: [0, 0.48, 1],
                ),
              ),
            ),
            Positioned(
              left: 13,
              top: 13,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xF5FFF8E8),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.savings_rounded, color: _coral, size: 16),
                    SizedBox(width: 6),
                    Text(
                      '첫 주문 종잣돈 모으기',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 13,
              top: 13,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xEAFB7D72),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < 3; index++) ...[
                      if (index > 0) const SizedBox(width: 3),
                      Icon(
                        index < today
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: index < today
                            ? const Color(0xFFFFE27B)
                            : Colors.white,
                        size: 13,
                      ),
                    ],
                    const SizedBox(width: 4),
                    Text(
                      '오늘 $today / 3',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 11,
              child: Container(
                padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
                decoration: BoxDecoration(
                  color: const Color(0xF4FFFCF4),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: Colors.white, width: 1.4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '내 지갑',
                                style: TextStyle(
                                  color: Color(0xFF7A8292),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${_money(cash)}원',
                                key: const Key('seed-money-cash'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 24,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
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
                            color: reachedGoal
                                ? const Color(0xFFDDF4E7)
                                : const Color(0xFFFFEDC0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                reachedGoal ? '해금 완료' : '첫 주문까지',
                                style: const TextStyle(
                                  color: Color(0xFF727A8A),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                reachedGoal
                                    ? '주문 가능!'
                                    : '${_money(10000 - earned)}원',
                                style: TextStyle(
                                  color: reachedGoal
                                      ? const Color(0xFF318367)
                                      : const Color(0xFFB56B21),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _LedgerProgress(progress: progress),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerProgress extends StatelessWidget {
  const _LedgerProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final filled = (progress * 10).ceil();
    return Row(
      children: [
        for (var index = 0; index < 10; index++) ...[
          if (index > 0) const SizedBox(width: 3),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              height: 9,
              decoration: BoxDecoration(
                color: index < filled
                    ? Color.lerp(const Color(0xFFFFD866), _coral, index / 12)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChorePeriodNotice extends StatelessWidget {
  const _ChorePeriodNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(11, 10, 12, 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E9),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFFFE1A2)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFFFFE7AF),
          child: Icon(
            Icons.favorite_rounded,
            color: Color(0xFFCF7654),
            size: 20,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '엄마의 2000년 용돈 메모',
                style: TextStyle(
                  color: _ink,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '법정 최저임금은 시간당 1,600원. 10살인 지금은 집안일·보호자 동행·가족 장터로 시작해요!',
                style: TextStyle(
                  color: Color(0xFF737C8E),
                  fontSize: 9.2,
                  height: 1.35,
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

class _WorkActivityCard extends StatelessWidget {
  const _WorkActivityCard({
    required this.questNumber,
    required this.activity,
    required this.disabled,
    required this.onTap,
  });

  final int questNumber;
  final WorkActivityInfo activity;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = switch (activity.id) {
      'dishes' => (
        Icons.soup_kitchen_rounded,
        const Color(0xFFDDF5E9),
        const Color(0xFF3B9C7A),
        '기억력',
      ),
      'stationery' => (
        Icons.inventory_2_rounded,
        const Color(0xFFFFE9BD),
        const Color(0xFFD47A2C),
        '분류력',
      ),
      _ => (
        Icons.storefront_rounded,
        const Color(0xFFE9E0F7),
        const Color(0xFF8060AF),
        '계산력',
      ),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('work-activity-${activity.id}'),
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(23),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 11, 11),
          decoration: BoxDecoration(
            color: disabled ? const Color(0xFFE8E6E1) : Colors.white,
            borderRadius: BorderRadius.circular(23),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F263247),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 67,
                    height: 86,
                    decoration: BoxDecoration(
                      color: disabled ? const Color(0xFFD4D2CE) : data.$2,
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Icon(
                      data.$1,
                      color: disabled ? const Color(0xFF9B9A97) : data.$3,
                      size: 34,
                    ),
                  ),
                  Positioned(
                    left: 7,
                    right: 7,
                    bottom: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        data.$4,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: disabled ? const Color(0xFF92918D) : data.$3,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -4,
                    top: -5,
                    child: Container(
                      width: 23,
                      height: 23,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: disabled ? const Color(0xFFA5A39F) : _coral,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '$questNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activity.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: disabled ? const Color(0xFF98999D) : data.$3,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      activity.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7A8292),
                        fontSize: 9,
                        height: 1.28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _WorkMiniChip(
                          icon: Icons.schedule_rounded,
                          label: '60분',
                          color: const Color(0xFF68758C),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: _WorkMiniChip(
                            icon: Icons.paid_rounded,
                            label: activity.periodPay,
                            color: data.$3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 41,
                height: 41,
                decoration: BoxDecoration(
                  color: disabled ? const Color(0xFFB8B7B4) : data.$3,
                  shape: BoxShape.circle,
                  boxShadow: disabled
                      ? null
                      : [
                          BoxShadow(
                            color: data.$3.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Icon(
                  disabled ? Icons.lock_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkMiniChip extends StatelessWidget {
  const _WorkMiniChip({
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
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 10),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class DishwashingMiniGame extends StatefulWidget {
  const DishwashingMiniGame({super.key});

  @override
  State<DishwashingMiniGame> createState() => _DishwashingMiniGameState();
}

class _DishwashingMiniGameState extends State<DishwashingMiniGame> {
  static const _dishNames = <String>['밥그릇', '머그컵', '프라이팬', '도시락통'];
  static const _grimeLayouts = <List<Offset>>[
    [Offset(86, 82), Offset(146, 73), Offset(117, 127)],
    [Offset(92, 70), Offset(149, 108), Offset(101, 139)],
    [
      Offset(74, 75),
      Offset(124, 64),
      Offset(162, 92),
      Offset(97, 126),
      Offset(151, 139),
    ],
    [Offset(78, 76), Offset(139, 70), Offset(173, 112), Offset(105, 137)],
  ];

  int _dish = 0;
  int _mistakes = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _dishMistakes = 0;
  bool _wet = false;
  bool _rinsed = false;
  final Set<int> _cleanedGrime = <int>{};

  List<Offset> get _grime => _grimeLayouts[_dish];
  bool get _allClean => _cleanedGrime.length == _grime.length;

  void _markMistake() {
    setState(() {
      _mistakes++;
      _dishMistakes++;
      _combo = 0;
    });
  }

  void _wetDish() {
    if (_wet || _rinsed) {
      _markMistake();
      return;
    }
    setState(() => _wet = true);
  }

  void _cleanSpot(int index) {
    if (!_wet || _rinsed) {
      _markMistake();
      return;
    }
    if (_cleanedGrime.contains(index)) return;
    setState(() => _cleanedGrime.add(index));
  }

  void _scrubAt(Offset localPosition) {
    if (!_wet || _rinsed) return;
    final cleaned = <int>{};
    for (var index = 0; index < _grime.length; index++) {
      if ((_grime[index] - localPosition).distance <= 31) {
        cleaned.add(index);
      }
    }
    if (cleaned.isEmpty) return;
    setState(() => _cleanedGrime.addAll(cleaned));
  }

  void _rinseDish() {
    if (!_wet || !_allClean || _rinsed) {
      _markMistake();
      return;
    }
    setState(() => _rinsed = true);
  }

  void _rackDish() {
    if (!_rinsed) {
      _markMistake();
      return;
    }
    setState(() {
      if (_dishMistakes == 0) {
        _combo++;
        _bestCombo = math.max(_bestCombo, _combo);
      }
      _dish++;
      _wet = false;
      _rinsed = false;
      _dishMistakes = 0;
      _cleanedGrime.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _dish >= _dishNames.length;
    final score = (100 - _mistakes * 7).clamp(40, 100);
    final stageProgress = done
        ? 1.0
        : (_wet ? 0.16 : 0.0) +
              (_cleanedGrime.length / _grime.length) * 0.5 +
              (_rinsed ? 0.25 : 0.0);
    return _MiniGameShell(
      title: '설거지 러시 V2',
      subtitle: '물을 묻히고 얼룩을 문질러 건조대까지',
      backgroundAsset: 'assets/images/bg_kitchen_cartoon_2000.png',
      progress: done ? 1 : (_dish + stageProgress) / _dishNames.length,
      child: done
          ? _MiniGameResult(
              activityId: 'dishes',
              score: score,
              title: _mistakes == 0 ? '반짝반짝 완벽 콤보!' : '주방 정리 완료!',
              detail:
                  '최고 콤보 ${math.max(_bestCombo, _combo)} · 실수 $_mistakes회 · 기본 용돈 ${300 + score * 5}원',
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xE6112438),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_dish + 1}/${_dishNames.length} · ${_dishNames[_dish]}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: _yellow,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '콤보 $_combo',
                        style: const TextStyle(
                          color: Color(0xFFFFE9A8),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 248,
                  height: 218,
                  decoration: BoxDecoration(
                    color: const Color(0xE6DCEEF1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFFF4FFFF),
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    key: const Key('dish-scrub-board'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) => _scrubAt(details.localPosition),
                    onPanUpdate: (details) => _scrubAt(details.localPosition),
                    child: Stack(
                      children: [
                        Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: _dish == 2 ? 205 : 185,
                            height: _dish == 2 ? 154 : 170,
                            decoration: BoxDecoration(
                              color: _rinsed
                                  ? const Color(0xFFF8FFFF)
                                  : const Color(0xFFF3F0E7),
                              shape: _dish == 2
                                  ? BoxShape.rectangle
                                  : BoxShape.circle,
                              borderRadius: _dish == 2
                                  ? BorderRadius.circular(52)
                                  : null,
                              border: Border.all(
                                color: _wet
                                    ? const Color(0xFF6FC7E7)
                                    : const Color(0xFFB5C4C7),
                                width: 8,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33243451),
                                  blurRadius: 8,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                          ),
                        ),
                        for (var index = 0; index < _grime.length; index++)
                          if (!_cleanedGrime.contains(index))
                            Positioned(
                              left: _grime[index].dx - 18,
                              top: _grime[index].dy - 18,
                              child: Semantics(
                                button: true,
                                label: '얼룩 ${index + 1} 닦기',
                                child: InkWell(
                                  key: Key('dish-grime-$_dish-$index'),
                                  onTap: () => _cleanSpot(index),
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xBFA16A42),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0x99FFF0C8),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.blur_on_rounded,
                                      color: Color(0xFFFBE3B1),
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        if (_allClean && !_rinsed)
                          const Center(
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFFFC94F),
                              size: 54,
                            ),
                          ),
                        if (_rinsed)
                          const Center(
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF4BB58D),
                              size: 60,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _GameAction(
                      key: const Key('dish-wet'),
                      icon: Icons.water_drop_rounded,
                      label: '물 묻히기',
                      onTap: _wet || _rinsed ? null : _wetDish,
                    ),
                    const SizedBox(width: 8),
                    _GameAction(
                      key: const Key('dish-rinse'),
                      icon: Icons.shower_rounded,
                      label: '헹구기',
                      onTap: _wet && _allClean && !_rinsed
                          ? _rinseDish
                          : _markMistake,
                    ),
                    const SizedBox(width: 8),
                    _GameAction(
                      key: const Key('dish-rack'),
                      icon: Icons.dry_cleaning_rounded,
                      label: '건조대',
                      onTap: _rinsed ? _rackDish : _markMistake,
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  !_wet
                      ? '먼저 물을 묻혀요'
                      : !_allClean
                      ? '얼룩을 손가락으로 문지르거나 하나씩 눌러요'
                      : !_rinsed
                      ? '깨끗해졌어요 · 헹구기!'
                      : '건조대로 옮기면 콤보 성공',
                  style: const TextStyle(
                    color: Color(0xFFFFF1C5),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
    );
  }
}

class StationerySortMiniGame extends StatefulWidget {
  const StationerySortMiniGame({super.key});

  @override
  State<StationerySortMiniGame> createState() => _StationerySortMiniGameState();
}

class _StationerySortMiniGameState extends State<StationerySortMiniGame> {
  static const _stock = <(String, String, IconData)>[
    ('notebook', '공책', Icons.menu_book_rounded),
    ('pencil', '연필', Icons.edit_rounded),
    ('eraser', '지우개', Icons.crop_7_5_rounded),
    ('candy', '사탕', Icons.cake_rounded),
    ('snack', '과자', Icons.cookie_rounded),
    ('marbles', '구슬', Icons.bubble_chart_rounded),
  ];
  static const _orders = <(String, List<String>)>[
    ('새 학기 준비', ['notebook', 'pencil', 'pencil', 'eraser']),
    ('쉬는 시간 간식', ['candy', 'candy', 'snack']),
    ('구슬치기 약속', ['marbles', 'marbles', 'marbles', 'candy']),
    ('동생 선물 꾸러미', ['notebook', 'pencil', 'snack', 'marbles']),
  ];
  int _index = 0;
  int _mistakes = 0;
  int _streak = 0;
  int _bestStreak = 0;
  final Map<String, int> _basket = <String, int>{};

  String _nameOf(String id) => _stock.firstWhere((item) => item.$1 == id).$2;

  int _targetCount(String id) =>
      _orders[_index].$2.where((item) => item == id).length;

  void _addItem(String id) {
    if (_index >= _orders.length) return;
    setState(() => _basket[id] = (_basket[id] ?? 0) + 1);
  }

  void _removeItem(String id) {
    final count = _basket[id] ?? 0;
    if (count == 0) return;
    setState(() {
      if (count == 1) {
        _basket.remove(id);
      } else {
        _basket[id] = count - 1;
      }
    });
  }

  void _packOrder() {
    final target = <String, int>{};
    for (final id in _orders[_index].$2) {
      target[id] = (target[id] ?? 0) + 1;
    }
    final correct =
        target.length == _basket.length &&
        target.entries.every((entry) => _basket[entry.key] == entry.value);
    setState(() {
      if (correct) {
        _streak++;
        _bestStreak = math.max(_bestStreak, _streak);
        _index++;
      } else {
        _mistakes++;
        _streak = 0;
      }
      _basket.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _index >= _orders.length;
    final score = (100 - _mistakes * 7).clamp(40, 100);
    final order = done ? null : _orders[_index];
    final patience = (1 - (_mistakes.clamp(0, 4) / 4)).clamp(0.0, 1.0);
    return _MiniGameShell(
      title: '문방구 주문 포장 V2',
      subtitle: '손님 메모를 보고 필요한 물건을 정확히 담아주세요',
      backgroundAsset: 'assets/images/bg_stationery_shop_2000.webp',
      progress: done
          ? 1
          : (_index + (_basket.isEmpty ? 0 : 0.45)) / _orders.length,
      child: done
          ? _MiniGameResult(
              activityId: 'stationery',
              score: score,
              title: _mistakes == 0 ? '단골손님 예약 완료!' : '오늘 주문 포장 끝!',
              detail:
                  '최고 연속 포장 $_bestStreak건 · 실수 $_mistakes회 · 기본 수당 ${600 + score * 4}원',
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
                  decoration: BoxDecoration(
                    color: const Color(0xF7FFF8E8),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFE3C68B),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD873),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: _ink,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '주문 ${_index + 1} · ${order!.$1}',
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Text(
                                  '메모에 적힌 수량만큼 담기',
                                  style: TextStyle(
                                    color: Color(0xFF84745E),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '연속 $_streak',
                            style: const TextStyle(
                              color: _coral,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _stock
                            .where((item) => _targetCount(item.$1) > 0)
                            .map(
                              (item) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: const Color(0xFFE7D5AE),
                                  ),
                                ),
                                child: Text(
                                  '${item.$2} × ${_targetCount(item.$1)}',
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          const Text(
                            '손님 기다림',
                            style: TextStyle(
                              color: Color(0xFF84745E),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                minHeight: 7,
                                value: patience,
                                backgroundColor: const Color(0xFFE6DDD0),
                                valueColor: AlwaysStoppedAnimation(
                                  patience > 0.5
                                      ? const Color(0xFF64B98F)
                                      : _coral,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xE6132538),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    mainAxisSpacing: 7,
                    crossAxisSpacing: 7,
                    children: _stock
                        .map(
                          (item) => FilledButton(
                            key: Key('stock-${item.$1}'),
                            onPressed: () => _addItem(item.$1),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.all(5),
                              foregroundColor: _ink,
                              backgroundColor: const Color(0xFFFDF6E6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(item.$3, color: _coral, size: 25),
                                const SizedBox(height: 3),
                                Text(
                                  item.$2,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 58),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xF7FFFFFF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD8E0E8)),
                  ),
                  child: _basket.isEmpty
                      ? const Center(
                          child: Text(
                            '바구니가 비어 있어요',
                            style: TextStyle(
                              color: Color(0xFF8B94A3),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: _basket.entries
                              .map(
                                (entry) => InkWell(
                                  key: Key('basket-${entry.key}'),
                                  onTap: () => _removeItem(entry.key),
                                  borderRadius: BorderRadius.circular(99),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE6DA),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      '${_nameOf(entry.key)} × ${entry.value}  −',
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    key: const Key('pack-order'),
                    onPressed: _packOrder,
                    style: FilledButton.styleFrom(
                      backgroundColor: _coral,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: const Icon(Icons.inventory_2_rounded),
                    label: Text(
                      '포장 완료 · 실수 $_mistakes회',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class FleaMarketMiniGame extends StatefulWidget {
  const FleaMarketMiniGame({super.key});

  @override
  State<FleaMarketMiniGame> createState() => _FleaMarketMiniGameState();
}

class _FleaMarketMiniGameState extends State<FleaMarketMiniGame> {
  static const _sales = <(String, int, int, int)>[
    ('과학 만화책', 1000, 1500, 5000),
    ('별자리 상자', 2000, 3000, 5000),
    ('동화책 세 권', 1500, 2500, 5000),
    ('장난감 자동차', 3000, 4500, 10000),
  ];
  int _index = 0;
  int _offer = _sales.first.$2;
  int _patience = 3;
  int _dealPoints = 0;
  int _correctChange = 0;
  int _mistakes = 0;
  bool _negotiating = true;
  final List<int> _changeNotes = <int>[];

  int get _changeTotal => _changeNotes.fold(0, (total, value) => total + value);

  void _counterOffer() {
    final next = _offer + 500;
    setState(() {
      if (next <= _sales[_index].$3) {
        _offer = next;
      } else {
        _mistakes++;
        _patience = math.max(0, _patience - 1);
      }
    });
  }

  void _acceptOffer() {
    setState(() {
      _dealPoints += _offer == _sales[_index].$3 ? 10 : 5;
      _negotiating = false;
    });
  }

  void _addChange(int value) {
    setState(() => _changeNotes.add(value));
  }

  void _undoChange() {
    if (_changeNotes.isEmpty) return;
    setState(() => _changeNotes.removeLast());
  }

  void _submitChange() {
    final due = _sales[_index].$4 - _offer;
    setState(() {
      if (_changeTotal == due) {
        _correctChange++;
        _index++;
        if (_index < _sales.length) {
          _offer = _sales[_index].$2;
          _patience = 3;
          _negotiating = true;
          _changeNotes.clear();
        }
      } else {
        _mistakes++;
        _changeNotes.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _index >= _sales.length;
    final score = (20 + _dealPoints + _correctChange * 10 - _mistakes * 5)
        .clamp(40, 100);
    final sale = done ? null : _sales[_index];
    final due = done ? 0 : sale!.$4 - _offer;
    final phaseProgress = done ? 1.0 : (_negotiating ? 0.2 : 0.65);
    return _MiniGameShell(
      title: '동네 벼룩장터 V2',
      subtitle: '가격을 흥정하고 지폐를 직접 골라 거스름돈을 주세요',
      backgroundAsset: 'assets/images/bg_living_room_cartoon_2000.png',
      progress: done ? 1 : (_index + phaseProgress) / _sales.length,
      child: done
          ? _MiniGameResult(
              activityId: 'flea_market',
              score: score,
              title: _mistakes == 0 ? '흥정도 계산도 완벽!' : '벼룩장터 마감!',
              detail:
                  '정확한 계산 $_correctChange건 · 실수 $_mistakes회 · 기본 몫 ${400 + score * 12}원',
            )
          : Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xF7FFF9EA),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFDB76),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: _ink,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_index + 1}/${_sales.length} · ${sale!.$1}',
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _negotiating ? '손님과 가격 흥정 중' : '거스름돈 계산 중',
                              style: const TextStyle(
                                color: Color(0xFF7C746A),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _negotiating
                        ? _FleaNegotiationPanel(
                            offer: _offer,
                            patience: _patience,
                            onCounter: _counterOffer,
                            onAccept: _acceptOffer,
                          )
                        : _FleaChangePanel(
                            salePrice: _offer,
                            paid: sale.$4,
                            due: due,
                            selected: _changeTotal,
                            canUndo: _changeNotes.isNotEmpty,
                            onAdd: _addChange,
                            onUndo: _undoChange,
                            onSubmit: _submitChange,
                          ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '실수 $_mistakes회',
                    style: const TextStyle(
                      color: Color(0xFF8B7354),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _FleaNegotiationPanel extends StatelessWidget {
  const _FleaNegotiationPanel({
    required this.offer,
    required this.patience,
    required this.onCounter,
    required this.onAccept,
  });

  final int offer;
  final int patience;
  final VoidCallback onCounter;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('negotiating'),
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0C7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6C679)),
        ),
        child: Column(
          children: [
            const Text(
              '현재 제안',
              style: TextStyle(
                color: Color(0xFF8A7856),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${_money(offer)}원',
              style: const TextStyle(
                color: _ink,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    index < patience
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: index < patience ? _coral : const Color(0xFFB7AFA3),
                    size: 20,
                  ),
                ),
              ),
            ),
            const Text(
              '욕심내면 손님 인내심이 줄어요',
              style: TextStyle(
                color: Color(0xFF8A7856),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                key: const Key('deal-counter'),
                onPressed: onCounter,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _coral, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  '500원 흥정',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton.icon(
                key: const Key('deal-accept'),
                onPressed: onAccept,
                style: FilledButton.styleFrom(
                  backgroundColor: _coral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.handshake_rounded),
                label: const Text(
                  '거래 확정',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _FleaChangePanel extends StatelessWidget {
  const _FleaChangePanel({
    required this.salePrice,
    required this.paid,
    required this.due,
    required this.selected,
    required this.canUndo,
    required this.onAdd,
    required this.onUndo,
    required this.onSubmit,
  });

  final int salePrice;
  final int paid;
  final int due;
  final int selected;
  final bool canUndo;
  final ValueChanged<int> onAdd;
  final VoidCallback onUndo;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('making-change'),
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PricePaper(label: '판매가', value: salePrice),
          const Icon(Icons.arrow_forward_rounded, color: _coral),
          _PricePaper(label: '받은 돈', value: paid),
        ],
      ),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F3EA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text(
              '내가 고른 돈',
              style: TextStyle(
                color: Color(0xFF647769),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${_money(selected)}원 / ${_money(due)}원',
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        alignment: WrapAlignment.center,
        children: [100, 500, 1000, 5000]
            .map(
              (value) => SizedBox(
                width: 68,
                height: 46,
                child: FilledButton(
                  key: Key('change-note-$value'),
                  onPressed: () => onAdd(value),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: const Color(0xFFDAE9D6),
                    foregroundColor: _ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                      side: const BorderSide(color: Color(0xFF8EB58D)),
                    ),
                  ),
                  child: Text(
                    '${_money(value)}원',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          SizedBox(
            width: 76,
            height: 48,
            child: OutlinedButton(
              key: const Key('change-undo'),
              onPressed: canUndo ? onUndo : null,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: _ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                '한 장 빼기',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                key: const Key('change-submit'),
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: _coral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.payments_rounded, size: 18),
                label: const Text(
                  '거스름돈 건네기',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _MiniGameShell extends StatelessWidget {
  const _MiniGameShell({
    required this.title,
    required this.subtitle,
    required this.backgroundAsset,
    required this.progress,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String backgroundAsset;
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: const Color(0xFF252B3A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            backgroundAsset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x720E1625),
                  Color(0x18131A27),
                  Color(0xA8111927),
                ],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _WorkTopBar(
                  title: title,
                  subtitle: subtitle,
                  onBack: () => Navigator.of(context).pop(),
                  dark: true,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xDDFFFFFF),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: const Color(0xEFFFFFFF)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 29,
                          height: 29,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE17B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: _ink,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '퀘스트 진행',
                                    style: TextStyle(
                                      color: _ink,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${(normalized * 100).round()}%',
                                    style: const TextStyle(
                                      color: _coral,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  minHeight: 7,
                                  value: normalized,
                                  backgroundColor: const Color(0xFFE1E5EC),
                                  valueColor: const AlwaysStoppedAnimation(
                                    _coral,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 14, 18),
                    child: Center(child: SingleChildScrollView(child: child)),
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

class _WorkTopBar extends StatelessWidget {
  const _WorkTopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.dark = false,
  });
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    height: 70,
    margin: dark ? const EdgeInsets.fromLTRB(8, 4, 8, 0) : EdgeInsets.zero,
    padding: const EdgeInsets.symmetric(horizontal: 5),
    decoration: BoxDecoration(
      color: dark ? const Color(0x330B1320) : const Color(0xFFFFFAF0),
      borderRadius: dark ? BorderRadius.circular(22) : BorderRadius.zero,
      border: dark ? Border.all(color: const Color(0x22FFFFFF)) : null,
      boxShadow: dark
          ? null
          : const [
              BoxShadow(
                color: Color(0x1A263247),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
    ),
    child: Row(
      children: [
        IconButton.filled(
          key: const Key('close-work-screen'),
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: dark
                ? const Color(0xCCFFFFFF)
                : const Color(0xFFF0F2F6),
            foregroundColor: _ink,
            minimumSize: const Size(44, 44),
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: dark ? Colors.white : _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.45,
                  shadows: dark
                      ? const [Shadow(color: Colors.black45, blurRadius: 5)]
                      : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: dark
                      ? const Color(0xFFE8EDF4)
                      : const Color(0xFF737C91),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  shadows: dark
                      ? const [Shadow(color: Colors.black54, blurRadius: 4)]
                      : null,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: dark ? const Color(0xCCFFDB70) : const Color(0xFFFFE7AC),
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_rounded, color: _ink, size: 12),
              SizedBox(width: 3),
              Text(
                '60분',
                style: TextStyle(
                  color: _ink,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
      ],
    ),
  );
}

class _GameAction extends StatelessWidget {
  const _GameAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (label) {
      '헹구기' => const Color(0xFF53A8D8),
      '닦기' => const Color(0xFF62B991),
      '마무리' => const Color(0xFFE48A59),
      '학용품' => const Color(0xFF648CC9),
      '간식' => const Color(0xFFE18A4B),
      '완구' => const Color(0xFF8A6AB5),
      _ => _coral,
    };
    return Expanded(
      child: SizedBox(
        height: 72,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: onTap == null
                ? const Color(0xBFE5E7EB)
                : const Color(0xF7FFFFFF),
            foregroundColor: _ink,
            disabledBackgroundColor: const Color(0xBFE5E7EB),
            disabledForegroundColor: const Color(0xFF9AA2AF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(6),
            elevation: onTap == null ? 0 : 3,
            shadowColor: Colors.black38,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: onTap == null
                      ? const Color(0xFFCDD1D8)
                      : accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: onTap == null ? const Color(0xFF969DA8) : accent,
                  size: 19,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniGameResult extends StatelessWidget {
  const _MiniGameResult({
    required this.activityId,
    required this.score,
    required this.title,
    required this.detail,
  });
  final String activityId;
  final int score;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('work-result-card'),
    padding: const EdgeInsets.fromLTRB(22, 19, 22, 20),
    decoration: BoxDecoration(
      color: const Color(0xFAFFFDF6),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE7A0),
                shape: BoxShape.circle,
              ),
            ),
            const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFD69626),
              size: 56,
            ),
            const Positioned(
              left: 0,
              top: 7,
              child: Icon(Icons.auto_awesome_rounded, color: _coral, size: 23),
            ),
            const Positioned(
              right: 0,
              bottom: 8,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF68B89C),
                size: 19,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                score >= 60 + index * 15
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: const Color(0xFFFFC94E),
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE5DF),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$score점',
            style: const TextStyle(
              color: _coral,
              fontSize: 27,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF70798B),
            fontSize: 10.5,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            key: const Key('claim-work-reward'),
            onPressed: () => Navigator.of(context).pop(
              WorkSessionResult(
                activityId: activityId,
                score: score,
                maxScore: 100,
              ),
            ),
            icon: const Icon(Icons.savings_rounded),
            label: const Text('보상 받고 저금통 채우기'),
            style: FilledButton.styleFrom(
              backgroundColor: _coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PricePaper extends StatelessWidget {
  const _PricePaper({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDBB),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE3C57C)),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF89744B),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${_money(value)}원',
          style: const TextStyle(
            color: _ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
