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
      backgroundColor: const Color(0xFFF0E1BF),
      body: SafeArea(
        child: Column(
          children: [
            _WorkTopBar(
              title: '종잣돈 일거리',
              subtitle: '${_state.currentDate.year}년 · $age살 · 직접 번 돈만 집계',
              onBack: () => Navigator.of(context).pop(),
            ),
            _SceneClockStrip(
              location: '집과 동네 · 오늘의 일거리',
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
      height: 218,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF6E482A), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x553A2614),
            blurRadius: 8,
            offset: Offset(4, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
                    Color(0x08000000),
                    Color(0x00000000),
                    Color(0x8F23170F),
                  ],
                  stops: [0, 0.5, 1],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 6, 11, 6),
                    decoration: BoxDecoration(
                      color: const Color(0xEFFFF2CE),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: const Color(0xFF795033),
                        width: 1.3,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFF6F4729),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '우리 집 심부름 장부',
                          style: TextStyle(
                            color: Color(0xFF4B321F),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xE8B94F45),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFFFFE5B5)),
                    ),
                    child: Text(
                      '오늘 $today / 3',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 13,
              right: 13,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                decoration: BoxDecoration(
                  color: const Color(0xEEFFF4D8),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFF714727),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66351F10), offset: Offset(3, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                '${_money(cash)}원',
                                key: const Key('seed-money-cash'),
                                style: const TextStyle(
                                  color: Color(0xFF3F2C20),
                                  fontSize: 25,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          reachedGoal
                              ? '주문 권한 해금!'
                              : '${_money(earned)} / 10,000원',
                          style: TextStyle(
                            color: reachedGoal
                                ? const Color(0xFF2D7865)
                                : const Color(0xFF72553A),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    _LedgerProgress(progress: progress),
                    const SizedBox(height: 6),
                    Text(
                      reachedGoal
                          ? '직접 번 돈으로 첫 투자 준비를 마쳤어요.'
                          : '직접 번 돈만 도장을 채워요 · 남은 돈 ${_money(10000 - earned)}원',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF68533F),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: index < filled
                    ? const Color(0xFFE4AF3D)
                    : const Color(0xFFE3D1AC),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF765033), width: 0.7),
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
    decoration: BoxDecoration(
      color: const Color(0xFFFFF2D2),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFF9B7043), width: 1.4),
      boxShadow: const [
        BoxShadow(color: Color(0x3D51351D), offset: Offset(3, 4)),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 54,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: const BoxDecoration(
            color: Color(0xFFC98A45),
            borderRadius: BorderRadius.horizontal(left: Radius.circular(11)),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_edu_rounded, color: Color(0xFFFFF1CF)),
              SizedBox(height: 3),
              Text(
                '2000',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(11, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '엄마가 적어 둔 시대 메모',
                  style: TextStyle(
                    color: Color(0xFF6D4425),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '1~8월 법정 최저임금은 시간당 1,600원. 10살인 지금은 집안일, 보호자 동행, 가족 벼룩장터로 시작해요.',
                  style: TextStyle(
                    color: Color(0xFF725B43),
                    fontSize: 9.5,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
        const Color(0xFFDCEFE3),
        const Color(0xFF317B69),
      ),
      'stationery' => (
        Icons.inventory_2_rounded,
        const Color(0xFFF7D9A7),
        const Color(0xFFA85E28),
      ),
      _ => (
        Icons.calculate_rounded,
        const Color(0xFFE2D9EC),
        const Color(0xFF6D548E),
      ),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('work-activity-${activity.id}'),
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(10, 10, 9, 10),
          decoration: BoxDecoration(
            color: disabled ? const Color(0xFFE1D8C3) : const Color(0xFFFFF8E5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: disabled
                  ? const Color(0xFFAAA08D)
                  : const Color(0xFF735037),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x443A2614),
                blurRadius: 2,
                offset: Offset(4, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 88,
                decoration: BoxDecoration(
                  color: data.$2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: data.$3, width: 1.3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '의뢰 ${questNumber.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: data.$3,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Icon(data.$1, color: data.$3, size: 27),
                    const SizedBox(height: 4),
                    Text(
                      '60분',
                      style: TextStyle(
                        color: data.$3,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        color: Color(0xFF403025),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: data.$3,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF766553),
                        fontSize: 9,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: data.$2.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: data.$3.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Text(
                        activity.periodPay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: data.$3,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: disabled
                      ? const Color(0xFFB5AC9D)
                      : const Color(0xFFB95348),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFEAC1)),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) => Scaffold(
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
              colors: [Color(0x990E1625), Color(0x22131A27), Color(0xBB111927)],
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: progress.clamp(0, 1),
                    backgroundColor: const Color(0x55FFFFFF),
                    valueColor: const AlwaysStoppedAnimation(_yellow),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 22),
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
    height: 67,
    decoration: dark
        ? null
        : const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF3D8), Color(0xFFF0E1BF)],
            ),
            border: Border(
              bottom: BorderSide(color: Color(0x558C6239), width: 1.2),
            ),
          ),
    child: Row(
      children: [
        IconButton(
          key: const Key('close-work-screen'),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: dark ? Colors.white : _ink,
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: dark ? Colors.white : _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: dark
                      ? const Color(0xFFDDE4EF)
                      : const Color(0xFF737C91),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
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
  Widget build(BuildContext context) => Expanded(
    child: SizedBox(
      height: 68,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xEFFFFFFF),
          foregroundColor: _ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          padding: const EdgeInsets.all(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _coral),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    ),
  );
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
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xF7FFF9EA),
      borderRadius: BorderRadius.circular(28),
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
        const Icon(
          Icons.workspace_premium_rounded,
          color: Color(0xFFE2A93B),
          size: 62,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$score점',
          style: const TextStyle(
            color: _coral,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF707688),
            fontSize: 11,
            height: 1.45,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 17),
        SizedBox(
          width: double.infinity,
          height: 48,
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
            label: const Text('수입을 저금통에 넣기'),
            style: FilledButton.styleFrom(
              backgroundColor: _coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
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
