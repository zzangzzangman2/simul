part of 'main.dart';

String _homeImprovementBackgroundAsset(HomeImprovementRoom room, int tier) {
  final safeTier = tier.clamp(0, 2);
  return switch (room) {
    HomeImprovementRoom.bedroom => switch (safeTier) {
      0 =>
        'assets/images/gameplay_map/bg_gameplay_bedroom_tier0_2000_portrait_cartoon_v1.png',
      1 =>
        'assets/images/gameplay_map/bg_gameplay_bedroom_tier1_2000_portrait_cartoon_v1.png',
      _ =>
        'assets/images/gameplay_map/bg_gameplay_bedroom_tier2_2000_portrait_cartoon_v1.png',
    },
    HomeImprovementRoom.livingRoom => switch (safeTier) {
      0 =>
        'assets/images/gameplay_map/bg_gameplay_living_room_tier0_2000_portrait_cartoon_v1.png',
      1 =>
        'assets/images/gameplay_map/bg_gameplay_living_room_tier1_2000_portrait_cartoon_v1.png',
      _ =>
        'assets/images/gameplay_map/bg_gameplay_living_room_tier2_2000_portrait_cartoon_v1.png',
    },
    HomeImprovementRoom.kitchen => switch (safeTier) {
      0 =>
        'assets/images/gameplay_map/bg_gameplay_kitchen_tier0_2000_portrait_cartoon_v1.png',
      1 =>
        'assets/images/gameplay_map/bg_gameplay_kitchen_tier1_2000_portrait_cartoon_v1.png',
      _ =>
        'assets/images/gameplay_map/bg_gameplay_kitchen_tier2_2000_portrait_cartoon_v1.png',
    },
  };
}

int _sharedHomeExteriorTier(HomeImprovementState home) =>
    switch (home.completedCount) {
      >= 4 => 2,
      >= 1 => 1,
      _ => 0,
    };

String _gameplayCorridorBackgroundAsset(HomeImprovementState home) =>
    'assets/images/gameplay_map/bg_gameplay_corridor_tier${_sharedHomeExteriorTier(home)}_2000_portrait_cartoon_v1.png';

String _gameplayNeighborhoodBackgroundAsset(GameState state) {
  if (state.marketMinute >= 17 * 60) {
    return 'assets/images/gameplay_map/bg_gameplay_neighborhood_dusk_2000_portrait_cartoon_v1.png';
  }
  final weatherSeed = state.simulationSeed.codeUnits.fold<int>(
    state.day * 17,
    (value, unit) => (value * 31 + unit) & 0x7fffffff,
  );
  return switch (weatherSeed % 5) {
    1 || 3 =>
      'assets/images/gameplay_map/bg_gameplay_neighborhood_cloudy_2000_portrait_cartoon_v1.png',
    4 =>
      'assets/images/gameplay_map/bg_gameplay_neighborhood_rain_2000_portrait_cartoon_v1.png',
    _ =>
      'assets/images/gameplay_map/bg_gameplay_neighborhood_clear_2000_portrait_cartoon_v1.png',
  };
}

String _homeRoomLabel(HomeImprovementRoom room) => switch (room) {
  HomeImprovementRoom.bedroom => '작은방',
  HomeImprovementRoom.livingRoom => '거실',
  HomeImprovementRoom.kitchen => '부엌',
};

IconData _homeRoomIcon(HomeImprovementRoom room) => switch (room) {
  HomeImprovementRoom.bedroom => Icons.bedroom_parent_rounded,
  HomeImprovementRoom.livingRoom => Icons.weekend_rounded,
  HomeImprovementRoom.kitchen => Icons.kitchen_rounded,
};

String _homeFamilyLabel(HomeFamilyMember member) => switch (member) {
  HomeFamilyMember.mother => '어머니',
  HomeFamilyMember.father => '아버지',
  HomeFamilyMember.sibling => '누나',
  HomeFamilyMember.grandfather => '외할아버지',
  HomeFamilyMember.family => '온 가족',
};

class HomeImprovementScreen extends StatefulWidget {
  const HomeImprovementScreen({
    super.key,
    required this.state,
    required this.onPurchase,
  });

  final GameState state;
  final Future<FinanceActionResult> Function(String improvementId) onPurchase;

  @override
  State<HomeImprovementScreen> createState() => _HomeImprovementScreenState();
}

class _HomeImprovementScreenState extends State<HomeImprovementScreen> {
  late GameState _state = widget.state;
  HomeImprovementRoom _room = HomeImprovementRoom.livingRoom;
  bool _purchasing = false;

  Future<void> _showEpisode(HomeImprovementDefinition improvement) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _HomeEpisodeDialog(improvement: improvement),
    );
  }

  Future<void> _purchase(HomeImprovementDefinition improvement) async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    final result = await widget.onPurchase(improvement.id);
    if (!mounted) return;
    setState(() {
      _purchasing = false;
      if (result.success) _state = result.state;
    });
    if (!result.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    await _showEpisode(improvement);
  }

  @override
  Widget build(BuildContext context) {
    final home = _state.homeImprovements;
    final tier = home.roomTier(_room);
    final improvements = homeImprovementCatalog
        .where((item) => item.room == _room)
        .toList(growable: false);
    return Scaffold(
      key: const Key('home-improvement-screen'),
      backgroundColor: const Color(0xFFF2E7D1),
      body: SafeArea(
        child: Column(
          children: [
            _HomeImprovementHeader(
              state: _state,
              onClose: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
              child: _HomeRoomTabs(
                selected: _room,
                home: home,
                onSelected: (room) => setState(() => _room = room),
              ),
            ),
            Expanded(
              child: ListView(
                key: Key('home-improvement-list-${_room.name}'),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                children: [
                  _HomeRoomPreview(
                    room: _room,
                    tier: tier,
                    assetPath: _homeImprovementBackgroundAsset(_room, tier),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD3B77F)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFF885F2D),
                          size: 22,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            '한 번에 번쩍 바꾸는 집이 아닙니다. 필요한 살림부터 하나씩 마련하고, 그날의 가족 이야기를 장부에 남깁니다.',
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 11,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final improvement in improvements) ...[
                    _HomeImprovementCard(
                      improvement: improvement,
                      state: _state,
                      busy: _purchasing,
                      onPurchase: () => _purchase(improvement),
                      onReplay: () => _showEpisode(improvement),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeImprovementHeader extends StatelessWidget {
  const _HomeImprovementHeader({required this.state, required this.onClose});

  final GameState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
    decoration: const BoxDecoration(
      color: Color(0xFF25324A),
      boxShadow: [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 9,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD66F),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.home_work_rounded, color: _ink),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '우리 집 살림 장부',
                style: TextStyle(
                  fontFamily: _hubDisplayFont,
                  color: Colors.white,
                  fontSize: 17,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '회사 통장으로 가족의 생활을 조금씩 바꿉니다',
                style: TextStyle(
                  color: Color(0xFFC7D4E8),
                  fontSize: 9.5,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              '회사 통장',
              style: TextStyle(
                color: Color(0xFFC7D4E8),
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${_money(state.bankCash)}원',
              key: const Key('home-improvement-bank-cash'),
              style: const TextStyle(
                color: Color(0xFFFFD66F),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        IconButton(
          key: const Key('home-improvement-close'),
          tooltip: '살림 장부 닫기',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          color: Colors.white,
        ),
      ],
    ),
  );
}

class _HomeRoomTabs extends StatelessWidget {
  const _HomeRoomTabs({
    required this.selected,
    required this.home,
    required this.onSelected,
  });

  final HomeImprovementRoom selected;
  final HomeImprovementState home;
  final ValueChanged<HomeImprovementRoom> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final room in HomeImprovementRoom.values) ...[
        if (room != HomeImprovementRoom.values.first) const SizedBox(width: 7),
        Expanded(
          child: Semantics(
            button: true,
            selected: room == selected,
            label: '${_homeRoomLabel(room)} 살림 ${home.roomTier(room)}/2단계',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: Key('home-room-tab-${room.name}'),
                onTap: () => onSelected(room),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  height: 52,
                  decoration: BoxDecoration(
                    color: room == selected
                        ? const Color(0xFFFFD66F)
                        : const Color(0xFFFFFBF2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: room == selected
                          ? const Color(0xFF7C5727)
                          : const Color(0xFFCBB58B),
                      width: room == selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_homeRoomIcon(room), color: _ink, size: 20),
                      const SizedBox(height: 2),
                      Text(
                        '${_homeRoomLabel(room)} ${home.roomTier(room)}/2',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class _HomeRoomPreview extends StatelessWidget {
  const _HomeRoomPreview({
    required this.room,
    required this.tier,
    required this.assetPath,
  });

  final HomeImprovementRoom room;
  final int tier;
  final String assetPath;

  @override
  Widget build(BuildContext context) => Container(
    height: 184,
    decoration: BoxDecoration(
      color: const Color(0xFF292A2E),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xFF6D4D25), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x44000000),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            key: Key('home-room-preview-${room.name}-tier-$tier'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x11000000), Color(0xB3000000)],
                stops: [0.45, 1],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_homeRoomLabel(room)} · ${tier == 0 ? '아직 손볼 곳이 많다' : '$tier단계까지 정돈됨'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xEFFFF3CF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$tier / 2',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
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

class _HomeImprovementCard extends StatelessWidget {
  const _HomeImprovementCard({
    required this.improvement,
    required this.state,
    required this.busy,
    required this.onPurchase,
    required this.onReplay,
  });

  final HomeImprovementDefinition improvement;
  final GameState state;
  final bool busy;
  final VoidCallback onPurchase;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final home = state.homeImprovements;
    final purchased = home.has(improvement.id);
    final prerequisite = improvement.prerequisiteId == null
        ? null
        : homeImprovementById(improvement.prerequisiteId!);
    final unlocked =
        prerequisite == null || home.has(improvement.prerequisiteId!);
    final affordable = state.bankCash >= improvement.cost;
    final buttonEnabled = purchased || (unlocked && affordable && !busy);
    final status = purchased
        ? '완료'
        : !unlocked
        ? '${prerequisite.title} 먼저'
        : !affordable
        ? '${_money(improvement.cost - state.bankCash)}원 부족'
        : '${_money(improvement.cost)}원';
    return Container(
      key: Key('home-improvement-card-${improvement.id}'),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: purchased ? const Color(0xFFF0F7E9) : const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: purchased ? const Color(0xFF76A66F) : const Color(0xFFD2B77F),
          width: purchased ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: purchased
                      ? const Color(0xFFD4E9C9)
                      : const Color(0xFFFFE7A2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  purchased
                      ? Icons.check_rounded
                      : _homeRoomIcon(improvement.room),
                  color: _ink,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      improvement.title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_homeFamilyLabel(improvement.familyMember)} 이야기 · ${improvement.storyTitle}',
                      style: const TextStyle(
                        color: Color(0xFF80612F),
                        fontSize: 9.5,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${improvement.stage}단계',
                style: const TextStyle(
                  color: Color(0xFF6F7685),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            improvement.subtitle,
            style: const TextStyle(
              color: Color(0xFF596375),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '집 안정 +${improvement.householdStabilityDelta} · 가족 신뢰 +${improvement.familyTrustDelta}',
                  style: const TextStyle(
                    color: Color(0xFF61704F),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                height: 43,
                child: FilledButton(
                  key: Key(
                    purchased
                        ? 'replay-home-story-${improvement.id}'
                        : 'buy-home-improvement-${improvement.id}',
                  ),
                  onPressed: buttonEnabled
                      ? (purchased ? onReplay : onPurchase)
                      : null,
                  style: FilledButton.styleFrom(
                    foregroundColor: _ink,
                    backgroundColor: purchased
                        ? const Color(0xFFD7EBCB)
                        : _yellow,
                    disabledBackgroundColor: const Color(0xFFE0DDD4),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: _ink, width: 1.4),
                    ),
                  ),
                  child: Text(
                    purchased ? '이야기 보기' : status,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!purchased && (!unlocked || !affordable)) ...[
            const SizedBox(height: 7),
            Text(
              status,
              style: const TextStyle(
                color: Color(0xFFA04A43),
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeEpisodeDialog extends StatelessWidget {
  const _HomeEpisodeDialog({required this.improvement});

  final HomeImprovementDefinition improvement;

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
    backgroundColor: Colors.transparent,
    child: Container(
      key: Key('home-story-${improvement.id}'),
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 650),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF25324A), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF25324A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFFFFD66F),
                  size: 23,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '우리 집 이야기',
                        style: TextStyle(
                          color: Color(0xFFC7D4E8),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        improvement.storyTitle,
                        style: const TextStyle(
                          fontFamily: _hubDisplayFont,
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '이야기 닫기',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final line in improvement.storyLines) ...[
                    if (line.speaker == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 7,
                        ),
                        child: Text(
                          line.text,
                          style: const TextStyle(
                            color: Color(0xFF687083),
                            fontSize: 11,
                            height: 1.55,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                        decoration: BoxDecoration(
                          color: line.speaker == '주인공'
                              ? const Color(0xFFFFEAB0)
                              : const Color(0xFFF0E9DC),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 11,
                              height: 1.45,
                            ),
                            children: [
                              TextSpan(
                                text: '${line.speaker}  ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(text: line.text),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 15),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                key: const Key('home-story-close'),
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  foregroundColor: _ink,
                  backgroundColor: _yellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: _ink, width: 1.5),
                  ),
                ),
                child: const Text(
                  '장부에 남기기',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
