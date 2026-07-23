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
  static const _dishSteps = <List<String>>[
    ['rinse', 'scrub', 'finish'],
    ['scrub', 'rinse', 'finish'],
    ['rinse', 'rinse', 'finish'],
    ['scrub', 'scrub', 'finish'],
    ['rinse', 'scrub', 'finish'],
  ];
  static const _actionLabels = <String, String>{
    'rinse': '헹구기',
    'scrub': '닦기',
    'finish': '마무리',
  };
  Timer? _previewTimer;
  int _dish = 0;
  int _step = 0;
  int _mistakes = 0;
  bool _showSequence = true;

  List<String> get _steps => _dishSteps[_dish];

  @override
  void initState() {
    super.initState();
    _schedulePreviewEnd();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  void _schedulePreviewEnd() {
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted && _dish < _dishSteps.length) {
        setState(() => _showSequence = false);
      }
    });
  }

  void _tap(String action) {
    if (_dish >= _dishSteps.length || _showSequence) return;
    if (action != _steps[_step]) {
      setState(() => _mistakes++);
      return;
    }
    final completedDish = _step == _steps.length - 1;
    setState(() {
      if (completedDish) {
        _dish++;
        _step = 0;
        _showSequence = _dish < _dishSteps.length;
      } else {
        _step++;
      }
    });
    if (completedDish && _dish < _dishSteps.length) _schedulePreviewEnd();
  }

  @override
  Widget build(BuildContext context) {
    final done = _dish >= _dishSteps.length;
    final score = (100 - _mistakes * 8).clamp(40, 100);
    return _MiniGameShell(
      title: '저녁 설거지',
      subtitle: '순서를 기억해서 다섯 장을 깨끗하게',
      backgroundAsset: 'assets/images/bg_kitchen_1999.png',
      progress: (_dish + (_step / 3)) / _dishSteps.length,
      child: done
          ? _MiniGameResult(
              activityId: 'dishes',
              score: score,
              title: _mistakes == 0 ? '반짝반짝 완벽해!' : '깨끗하게 정리 완료!',
              detail:
                  '순서 실수 $_mistakes회 · 기본 용돈 ${300 + score * 5}원 · 성향/스킬 보너스 별도',
            )
          : Column(
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    color: const Color(0xEEF2F8F8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFB7D5D2),
                      width: 8,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        _showSequence
                            ? Icons.visibility_rounded
                            : Icons.psychology_alt_rounded,
                        color: _showSequence
                            ? const Color(0xFF5A8D89)
                            : _yellow,
                        size: 74,
                      ),
                      Positioned(
                        bottom: 24,
                        child: Text(
                          '${_dish + 1}번째 접시',
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _showSequence
                      ? Container(
                          key: const Key('dish-sequence-preview'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xDD10243A),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '순서 외우기 · ${_steps.map((step) => _actionLabels[step]).join(' → ')}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      : const Text(
                          '순서를 숨겼어요 · 기억한 순서대로 눌러 보세요',
                          key: Key('dish-recall-prompt'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _GameAction(
                      key: const Key('dish-rinse'),
                      icon: Icons.water_drop_rounded,
                      label: '헹구기',
                      onTap: _showSequence ? null : () => _tap('rinse'),
                    ),
                    const SizedBox(width: 8),
                    _GameAction(
                      key: const Key('dish-scrub'),
                      icon: Icons.cleaning_services_rounded,
                      label: '닦기',
                      onTap: _showSequence ? null : () => _tap('scrub'),
                    ),
                    const SizedBox(width: 8),
                    _GameAction(
                      key: const Key('dish-finish'),
                      icon: Icons.shower_rounded,
                      label: '마무리',
                      onTap: _showSequence ? null : () => _tap('finish'),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  '실수 $_mistakes회 · 연속 정확도가 보너스를 결정해요',
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
  static const _items = <(String, IconData, String)>[
    ('공책', Icons.menu_book_rounded, 'school'),
    ('연필', Icons.edit_rounded, 'school'),
    ('사탕', Icons.cake_rounded, 'snack'),
    ('딱지', Icons.style_rounded, 'toy'),
    ('지우개', Icons.crop_7_5_rounded, 'school'),
    ('과자', Icons.cookie_rounded, 'snack'),
    ('구슬', Icons.circle, 'toy'),
    ('자', Icons.straighten_rounded, 'school'),
  ];
  int _index = 0;
  int _correct = 0;
  int _mistakes = 0;

  void _choose(String category) {
    if (_index >= _items.length) return;
    setState(() {
      if (category == _items[_index].$3) {
        _correct++;
        _index++;
      } else {
        _mistakes++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _index >= _items.length;
    final score = (_correct * 12 + (4 - _mistakes).clamp(0, 4)).clamp(40, 100);
    return _MiniGameShell(
      title: '문방구 재고 정리',
      subtitle: '물건을 보고 맞는 진열장으로 분류하세요',
      backgroundAsset: 'assets/images/bg_stationery_shop_2000.webp',
      progress: _index / _items.length,
      child: done
          ? _MiniGameResult(
              activityId: 'stationery',
              score: score,
              title: score >= 90 ? '사장님도 놀란 진열 실력!' : '재고 정리 완료!',
              detail:
                  '정답 $_correct개 · 실수 $_mistakes회 · 기본 수당 ${600 + score * 4}원 · 보너스 별도',
            )
          : Column(
              children: [
                Container(
                  key: Key('sort-item-$_index'),
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xF7FFF8E8),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFFE3C68B),
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _items[_index].$2,
                        color: const Color(0xFFB47435),
                        size: 76,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _items[_index].$1,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _GameAction(
                      key: const Key('sort-school'),
                      icon: Icons.school_rounded,
                      label: '학용품',
                      onTap: () => _choose('school'),
                    ),
                    const SizedBox(width: 8),
                    _GameAction(
                      key: const Key('sort-snack'),
                      icon: Icons.cookie_rounded,
                      label: '간식',
                      onTap: () => _choose('snack'),
                    ),
                    const SizedBox(width: 8),
                    _GameAction(
                      key: const Key('sort-toy'),
                      icon: Icons.toys_rounded,
                      label: '완구',
                      onTap: () => _choose('toy'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${_index + 1} / ${_items.length} · 실수 $_mistakes회',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 5)],
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
  static const _sales = <(String, int, int, List<int>)>[
    ('과학 만화책', 1200, 2000, [600, 700, 800, 900]),
    ('퍼즐 상자', 2500, 5000, [1500, 2000, 2500, 3000]),
    ('동화책 세 권', 1800, 5000, [2800, 3000, 3200, 3500]),
    ('장난감 자동차', 3500, 10000, [5500, 6000, 6500, 7000]),
    ('백과사전 낱권', 4200, 10000, [5200, 5600, 5800, 6200]),
  ];
  int _index = 0;
  int _correct = 0;
  int _mistakes = 0;

  void _choose(int value) {
    if (_index >= _sales.length) return;
    final answer = _sales[_index].$3 - _sales[_index].$2;
    setState(() {
      if (value == answer) {
        _correct++;
        _index++;
      } else {
        _mistakes++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _index >= _sales.length;
    final score = (_correct * 19 + (5 - _mistakes).clamp(0, 5)).clamp(40, 100);
    final sale = done ? null : _sales[_index];
    return _MiniGameShell(
      title: '가족 벼룩장터',
      subtitle: '천천히 계산해 정확한 거스름돈을 건네요',
      backgroundAsset: 'assets/images/bg_living_room_1999.png',
      progress: _index / _sales.length,
      child: done
          ? _MiniGameResult(
              activityId: 'flea_market',
              score: score,
              title: score >= 90 ? '오늘 계산대는 완벽했어!' : '벼룩장터 마감!',
              detail:
                  '정답 $_correct개 · 다시 계산 $_mistakes회 · 기본 몫 ${400 + score * 12}원 · 보너스 별도',
            )
          : Container(
              padding: const EdgeInsets.all(17),
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
                  const Icon(Icons.storefront_rounded, color: _coral, size: 42),
                  const SizedBox(height: 5),
                  Text(
                    sale!.$1,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PricePaper(label: '가격', value: sale.$2),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded, color: _coral),
                      ),
                      _PricePaper(label: '받은 돈', value: sale.$3),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '거스름돈은 얼마일까?',
                    style: TextStyle(
                      color: Color(0xFF6D7180),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: sale.$4
                        .map(
                          (value) => OutlinedButton(
                            key: Key('change-$value'),
                            onPressed: () => _choose(value),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ink,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFD7C49A)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: Text(
                              '${_money(value)}원',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_index + 1} / ${_sales.length} · 다시 계산 $_mistakes회',
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
