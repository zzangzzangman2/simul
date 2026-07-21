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
  int get _today =>
      (_state.story.storyFlags['workSessionsToday'] as num?)?.toInt() ?? 0;

  Future<void> _openGame(WorkActivityInfo activity) async {
    if (_saving || _today >= 3) return;
    final result = await Navigator.of(context).push<WorkSessionResult>(
      MaterialPageRoute<WorkSessionResult>(
        builder: (_) => switch (activity.id) {
          'dishes' => const DishwashingMiniGame(),
          'stationery' => const StationerySortMiniGame(),
          _ => const FleaMarketMiniGame(),
        },
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    final next = await widget.onComplete(result);
    if (!mounted) return;
    setState(() {
      _state = next;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_state.cash / 10000).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEDC),
      body: SafeArea(
        child: Column(
          children: [
            _WorkTopBar(
              title: '종잣돈 일거리',
              subtitle: '2000년 1월 · 보호자와 함께',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                children: [
                  Container(
                    key: const Key('seed-money-summary'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF405478), Color(0xFF6B7FA6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33405278),
                          blurRadius: 18,
                          offset: Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '내 손으로 만드는 첫 투자금',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x22FFFFFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '오늘 $_today / 3',
                                style: const TextStyle(
                                  color: _yellow,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${_money(_state.cash)}원',
                          key: const Key('seed-money-cash'),
                          style: const TextStyle(
                            color: _yellow,
                            fontSize: 31,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _state.cash >= 10000
                              ? '첫 목표 달성! 이제 일할지 조사할지는 네 선택이야.'
                              : '첫 조사예산 10,000원까지 ${_money(10000 - _state.cash)}원',
                          style: const TextStyle(
                            color: Color(0xFFDCE5F6),
                            fontSize: 11,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 9,
                            value: progress,
                            backgroundColor: const Color(0x33FFFFFF),
                            valueColor: const AlwaysStoppedAnimation(_yellow),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          '누적 일거리 수입 ${_money(_earned)}원 · 원금 증여 없음',
                          style: const TextStyle(
                            color: Color(0xFFCED8EB),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8D5A8)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.history_edu_rounded,
                          color: Color(0xFFB47C2C),
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            '시대 기준 · 2000년 1~8월 법정 최저임금은 시간당 1,600원입니다. 주인공은 10살이므로 정식 고용 대신 집안일, 보호자 동행 일거리와 가족 벼룩장터로 시작합니다.',
                            style: TextStyle(
                              color: Color(0xFF746244),
                              fontSize: 10,
                              height: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...workActivities.map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: _WorkActivityCard(
                        activity: activity,
                        disabled: _saving || _today >= 3,
                        onTap: () => _openGame(activity),
                      ),
                    ),
                  ),
                  if (_today >= 3)
                    Container(
                      key: const Key('daily-work-limit'),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4ECF5),
                        borderRadius: BorderRadius.circular(17),
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

class _WorkActivityCard extends StatelessWidget {
  const _WorkActivityCard({
    required this.activity,
    required this.disabled,
    required this.onTap,
  });

  final WorkActivityInfo activity;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = switch (activity.id) {
      'dishes' => (
        Icons.soup_kitchen_rounded,
        const Color(0xFFDDF5F2),
        const Color(0xFF3E8E85),
      ),
      'stationery' => (
        Icons.inventory_2_rounded,
        const Color(0xFFFFE8C7),
        const Color(0xFFB8782F),
      ),
      _ => (
        Icons.calculate_rounded,
        const Color(0xFFE7E2FA),
        const Color(0xFF6E61A6),
      ),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('work-activity-${activity.id}'),
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(21),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: disabled ? const Color(0xFFE5E3DD) : Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFFE4DDD0)),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 72,
                decoration: BoxDecoration(
                  color: data.$2,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(data.$1, color: data.$3, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      activity.subtitle,
                      style: TextStyle(
                        color: data.$3,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activity.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7B7F87),
                        fontSize: 9,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      activity.periodPay,
                      style: const TextStyle(
                        color: Color(0xFF496A59),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _coral),
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
  static const _steps = ['rinse', 'scrub', 'finish'];
  int _dish = 0;
  int _step = 0;
  int _mistakes = 0;

  void _tap(String action) {
    if (_dish >= 5) return;
    if (action != _steps[_step]) {
      setState(() => _mistakes++);
      return;
    }
    setState(() {
      if (_step == _steps.length - 1) {
        _dish++;
        _step = 0;
      } else {
        _step++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _dish >= 5;
    final score = (100 - _mistakes * 8).clamp(40, 100);
    return _MiniGameShell(
      title: '저녁 설거지',
      subtitle: '순서를 기억해서 다섯 장을 깨끗하게',
      backgroundAsset: 'assets/images/bg_kitchen_1999.png',
      progress: (_dish + (_step / 3)) / 5,
      child: done
          ? _MiniGameResult(
              activityId: 'dishes',
              score: score,
              title: _mistakes == 0 ? '반짝반짝 완벽해!' : '깨끗하게 정리 완료!',
              detail: '순서 실수 $_mistakes회 · 예상 용돈 ${300 + score * 5}원',
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
                        _step == 0
                            ? Icons.bubble_chart_rounded
                            : _step == 1
                            ? Icons.cleaning_services_rounded
                            : Icons.auto_awesome_rounded,
                        color: _step == 2 ? _yellow : const Color(0xFF5A8D89),
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
                Text(
                  '지금 할 일 · ${['물로 헹구기', '수세미로 닦기', '깨끗한 물로 마무리'][_step]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _GameAction(
                      key: const Key('dish-rinse'),
                      icon: Icons.water_drop_rounded,
                      label: '헹구기',
                      onTap: () => _tap('rinse'),
                    ),
                    const SizedBox(width: 8),
                    _GameAction(
                      key: const Key('dish-scrub'),
                      icon: Icons.cleaning_services_rounded,
                      label: '닦기',
                      onTap: () => _tap('scrub'),
                    ),
                    const SizedBox(width: 8),
                    _GameAction(
                      key: const Key('dish-finish'),
                      icon: Icons.shower_rounded,
                      label: '마무리',
                      onTap: () => _tap('finish'),
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
              detail: '정답 $_correct개 · 실수 $_mistakes회 · 30분 기준 수당',
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
              detail: '정답 $_correct개 · 다시 계산 $_mistakes회 · 판매 몫 정산',
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
  Widget build(BuildContext context) => SizedBox(
    height: 67,
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
  final VoidCallback onTap;

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
