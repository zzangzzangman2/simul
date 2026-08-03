part of 'main.dart';

enum _ApartmentPlace { bedroom, livingRoom, kitchen, corridor, neighborhood }

const _hubDisplayFont = 'Maplestory';

String _apartmentDateLabel(DateTime date) {
  const weekdays = <String>['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
}

String _apartmentHudDateLabel(DateTime date) {
  const weekdays = <String>['월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
}

class ApartmentHubScreen extends StatefulWidget {
  const ApartmentHubScreen({
    super.key,
    required this.state,
    required this.onOpenMarket,
    required this.onOpenBank,
    required this.onOpenDecisions,
    required this.onOpenLedger,
    required this.onOpenOrganization,
    required this.onOpenRelationships,
    required this.onOpenMessenger,
    required this.onOpenCalendar,
    required this.onOpenHomeImprovements,
    required this.onOpenWork,
    required this.activeSaveSlot,
    required this.lastSavedAt,
    required this.onOpenGameMenu,
    required this.onAdvanceHour,
    required this.onAdvanceDay,
    required this.onAdvanceBatch,
    required this.onOpenEnding,
    this.onClaimMission,
    this.onTutorialComplete,
  });

  final GameState state;
  final VoidCallback onOpenMarket;
  final VoidCallback onOpenBank;
  final VoidCallback onOpenDecisions;
  final VoidCallback onOpenLedger;
  final VoidCallback onOpenOrganization;
  final VoidCallback onOpenRelationships;
  final VoidCallback onOpenMessenger;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenHomeImprovements;
  final VoidCallback onOpenWork;
  final int activeSaveSlot;
  final DateTime? lastSavedAt;
  final VoidCallback onOpenGameMenu;
  final VoidCallback onAdvanceHour;
  final VoidCallback onAdvanceDay;
  final VoidCallback onAdvanceBatch;
  final VoidCallback onOpenEnding;
  final Future<MissionClaimResult> Function()? onClaimMission;
  final Future<void> Function()? onTutorialComplete;

  @override
  State<ApartmentHubScreen> createState() => _ApartmentHubScreenState();
}

class _ApartmentHubScreenState extends State<ApartmentHubScreen> {
  _ApartmentPlace _place = _ApartmentPlace.bedroom;
  late bool _tutorialVisible =
      widget.onTutorialComplete != null && !widget.state.story.tutorialSeen;

  Future<void> _dismissTutorial() async {
    if (!_tutorialVisible) return;
    setState(() => _tutorialVisible = false);
    await widget.onTutorialComplete?.call();
  }

  void _moveTo(_ApartmentPlace place) {
    if (place == _place) return;
    setState(() => _place = place);
  }

  @override
  Widget build(BuildContext context) {
    final details = _ApartmentPlaceDetails.forPlace(_place);
    final legacyMissionUiDisabled = widget.state.story.flagBool(
      'legacyMissionUiDisabled',
    );
    final missionProgress = legacyMissionUiDisabled
        ? null
        : const GameEngine().missionProgress(widget.state);
    final placeIndex = _ApartmentPlace.values.indexOf(_place);
    final previousPlace = placeIndex > 0
        ? _ApartmentPlace.values[placeIndex - 1]
        : null;
    final nextPlace = placeIndex < _ApartmentPlace.values.length - 1
        ? _ApartmentPlace.values[placeIndex + 1]
        : null;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            reverseDuration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final scale = Tween<double>(begin: 1.025, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: scale, child: child),
              );
            },
            child: _ApartmentPlaceScene(
              key: ValueKey(_place),
              place: _place,
              state: widget.state,
              onOpenMarket: widget.onOpenMarket,
              onOpenBank: widget.onOpenBank,
              onOpenDecisions: widget.onOpenDecisions,
              onOpenLedger: widget.onOpenLedger,
              onOpenOrganization: widget.onOpenOrganization,
              onOpenHomeImprovements: widget.onOpenHomeImprovements,
              onOpenWork: widget.onOpenWork,
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: _ApartmentSceneVignette()),
          ),
          Positioned(
            left: 6,
            top: 6,
            right: 6,
            child: _ApartmentLocationHeader(
              details: details,
              state: widget.state,
              activeSaveSlot: widget.activeSaveSlot,
              lastSavedAt: widget.lastSavedAt,
              onOpenGameMenu: widget.onOpenGameMenu,
            ),
          ),
          if (!legacyMissionUiDisabled)
            Positioned(
              right: 10,
              bottom: 100,
              child: _ApartmentMissionCard(
                progress: missionProgress,
                starBalance: widget.state.progression.starBalance,
                onClaim: widget.onClaimMission,
              ),
            ),
          Positioned(
            left: 10,
            bottom: 24,
            child: _ApartmentRoomArrow(
              destination: previousPlace,
              flipHorizontally: true,
              onMove: _moveTo,
            ),
          ),
          Positioned(
            right: 10,
            bottom: 24,
            child: _ApartmentRoomArrow(
              destination: nextPlace,
              flipHorizontally: false,
              onMove: _moveTo,
            ),
          ),
          Positioned(
            right: 7,
            top: 118,
            child: _ApartmentActionRail(
              hasPendingDecision: widget.state.pendingDecisions.isNotEmpty,
              campaignComplete: widget.state.campaignComplete,
              marketMinute: widget.state.marketMinute,
              messengerUnread: widget.state.phoneMessenger.totalUnread,
              onOpenMessenger: widget.onOpenMessenger,
              onOpenRelationships: widget.onOpenRelationships,
              onOpenCalendar: widget.onOpenCalendar,
              onAdvanceHour: widget.onAdvanceHour,
              onAdvanceDay: widget.onAdvanceDay,
              onAdvanceBatch: widget.onAdvanceBatch,
              onOpenEnding: widget.onOpenEnding,
              onHelp: () => setState(() => _tutorialVisible = true),
            ),
          ),
          if (_tutorialVisible)
            Positioned.fill(
              child: _HubTutorialOverlay(onDone: _dismissTutorial),
            ),
        ],
      ),
    );
  }
}

class HomeComputerScreen extends StatefulWidget {
  const HomeComputerScreen({
    super.key,
    required this.state,
    required this.onOpenStockMarket,
    required this.onOpenRealEstate,
    required this.onOpenBusiness,
    required this.onOpenStarShop,
  });

  final GameState state;
  final Future<GameState> Function(GameState state) onOpenStockMarket;
  final Future<GameState> Function(GameState state) onOpenRealEstate;
  final Future<GameState> Function(GameState state) onOpenBusiness;
  final Future<GameState> Function(GameState state) onOpenStarShop;

  @override
  State<HomeComputerScreen> createState() => _HomeComputerScreenState();
}

class _HomeComputerScreenState extends State<HomeComputerScreen> {
  late GameState _state = widget.state;

  Future<void> _openStockMarket() async {
    final next = await widget.onOpenStockMarket(_state);
    if (mounted) setState(() => _state = next);
  }

  Future<void> _openRealEstate() async {
    final next = await widget.onOpenRealEstate(_state);
    if (mounted) setState(() => _state = next);
  }

  Future<void> _openBusiness() async {
    final next = await widget.onOpenBusiness(_state);
    if (mounted) setState(() => _state = next);
  }

  Future<void> _openStarShop() async {
    final next = await widget.onOpenStarShop(_state);
    if (mounted) setState(() => _state = next);
  }

  @override
  Widget build(BuildContext context) {
    final date = _state.currentDate;
    final hour = _state.marketMinute ~/ 60;
    final minute = _state.marketMinute % 60;
    final clock =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return Scaffold(
      key: const Key('home-computer-screen'),
      backgroundColor: const Color(0xFF071A35),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;
            final windowHeight = (constraints.maxHeight - (compact ? 148 : 190))
                .clamp(280.0, 360.0);
            return Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF075B79),
                        Color(0xFF1E91A5),
                        Color(0xFF0E405F),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  right: -58,
                  top: 72,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 210,
                      height: 210,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x247DE5D5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: -72,
                  bottom: 70,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 230,
                      height: 230,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x1FFFE29A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 8,
                  top: 8,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.computer_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '새천년 홈 PC',
                              style: TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Colors.white,
                                fontSize: 15,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '내 컴퓨터 · 온라인',
                              style: TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Color(0xFFD2F4F3),
                                fontSize: 9,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('home-computer-close'),
                        tooltip: '컴퓨터 화면 닫기',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.power_settings_new_rounded),
                        color: Colors.white,
                        iconSize: 23,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  top: compact ? 58 : 78,
                  height: windowHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1E8),
                      border: Border.all(
                        color: const Color(0xFFE6F4FF),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66031220),
                          blurRadius: 18,
                          offset: Offset(0, 9),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Column(
                        children: [
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF153B78), Color(0xFF2E70B5)],
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.language_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    '온라인 자산센터',
                                    style: TextStyle(
                                      fontFamily: _hubDisplayFont,
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _ComputerWindowDot(color: Color(0xFFBBD7F6)),
                                SizedBox(width: 5),
                                _ComputerWindowDot(color: Color(0xFFFFD66F)),
                                SizedBox(width: 5),
                                _ComputerWindowDot(color: Color(0xFFFF8B83)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                14,
                                14,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '실행할 프로그램을 선택하세요',
                                    style: TextStyle(
                                      fontFamily: _hubDisplayFont,
                                      color: _ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '투자 시장과 별빛 상점은 각각 별도 프로그램으로 열립니다.',
                                    maxLines: 2,
                                    style: TextStyle(
                                      fontFamily: _hubDisplayFont,
                                      color: Color(0xFF697486),
                                      fontSize: 9.5,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 13),
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, appConstraints) {
                                        final tileWidth =
                                            (appConstraints.maxWidth - 8) / 2;
                                        final tileHeight =
                                            (appConstraints.maxHeight - 8) / 2;
                                        return GridView.count(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          padding: EdgeInsets.zero,
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio:
                                              tileWidth / tileHeight,
                                          children: [
                                            _ComputerAppTile(
                                              interactionKey: const Key(
                                                'computer-stock-market-app',
                                              ),
                                              icon: Icons
                                                  .candlestick_chart_rounded,
                                              iconColor: const Color(
                                                0xFF55C7A1,
                                              ),
                                              title: '미래 증권',
                                              subtitle: '주식시장',
                                              status: '시세 · 주문',
                                              onTap: _openStockMarket,
                                            ),
                                            _ComputerAppTile(
                                              interactionKey: const Key(
                                                'computer-real-estate-app',
                                              ),
                                              icon: Icons.apartment_rounded,
                                              iconColor: const Color(
                                                0xFFFFA45C,
                                              ),
                                              title: '한마음 부동산',
                                              subtitle: '서울·경기 매물',
                                              status: '지도 · 계약',
                                              onTap: _openRealEstate,
                                            ),
                                            _ComputerAppTile(
                                              interactionKey: const Key(
                                                'computer-business-app',
                                              ),
                                              icon: Icons.storefront_rounded,
                                              iconColor: const Color(
                                                0xFFFF86A8,
                                              ),
                                              title: '동네상권넷',
                                              subtitle: '창업 · 점포운영',
                                              status:
                                                  '점포 ${_state.businesses.activeBusinesses.length}'
                                                  ' · 사건 ${_state.businesses.pendingEvents.length}',
                                              onTap: _openBusiness,
                                            ),
                                            _ComputerAppTile(
                                              interactionKey: const Key(
                                                'computer-star-shop-app',
                                              ),
                                              icon: Icons.auto_awesome_rounded,
                                              iconColor: const Color(
                                                0xFFFFD75E,
                                              ),
                                              title: '별빛 상점',
                                              subtitle: '미션 스타',
                                              status:
                                                  '⭐ ${_state.progression.starBalance}',
                                              onTap: _openStarShop,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 7,
                  right: 7,
                  bottom: 7,
                  height: 48,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xEDE4E8E0),
                      border: Border.all(color: const Color(0xFFFFFFFF)),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55031220),
                          blurRadius: 9,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A8D67),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.window_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '시작',
                                style: TextStyle(
                                  fontFamily: _hubDisplayFont,
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Icon(
                          Icons.signal_wifi_4_bar_rounded,
                          color: Color(0xFF26415E),
                          size: 19,
                        ),
                        const Spacer(),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              clock,
                              style: const TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Color(0xFF20344F),
                                fontSize: 10,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Color(0xFF5B6776),
                                fontSize: 8,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

class _ComputerAppTile extends StatelessWidget {
  const _ComputerAppTile({
    required this.interactionKey,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  final Key interactionKey;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final dense = constraints.maxWidth < 112 || constraints.maxHeight < 130;
      final iconSize = dense ? 34.0 : 58.0;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          key: interactionKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAF4),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFF94A4B7), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.white, offset: Offset(-2, -2)),
                BoxShadow(color: Color(0xFF9AA7AF), offset: Offset(2, 2)),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                dense ? 5 : 9,
                dense ? 8 : 12,
                dense ? 5 : 9,
                dense ? 7 : 9,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFF172C4A),
                      borderRadius: BorderRadius.circular(dense ? 10 : 12),
                      border: Border.all(color: const Color(0xFF6E89AC)),
                    ),
                    child: Icon(icon, color: iconColor, size: dense ? 22 : 34),
                  ),
                  SizedBox(height: dense ? 7 : 10),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _hubDisplayFont,
                      color: _ink,
                      fontSize: dense ? 10 : 12,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.25,
                    ),
                  ),
                  SizedBox(height: dense ? 4 : 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: _hubDisplayFont,
                      color: Color(0xFF586476),
                      fontSize: dense ? 8 : 9,
                      height: 1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: dense ? 5 : 7,
                      vertical: dense ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E9E4),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      status,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: _hubDisplayFont,
                        color: Color(0xFF486070),
                        fontSize: dense ? 7.2 : 8,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ComputerWindowDot extends StatelessWidget {
  const _ComputerWindowDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: const Color(0x66000000)),
    ),
    child: const SizedBox(width: 13, height: 13),
  );
}

class _HubTutorialOverlay extends StatelessWidget {
  const _HubTutorialOverlay({required this.onDone});
  final Future<void> Function() onDone;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xB8000000),
    child: SafeArea(
      child: Center(
        child: Container(
          key: const Key('hub-tutorial-overlay'),
          width: 330,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEF8),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF27334B), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '데시멀 센터 데시멀 생활 안내',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                '• 데시멀 생활동 단말기: 시장·부동산·상권 앱\n'
                '• 개인 장부함: 거래 근거·성과\n'
                '• 트레이딩 플로어: 동기·운영관·운용 조직\n'
                '• 기기 정비실: 단말기·통신 장비와 생활 설비\n'
                '• 기록 보관실: 국가 회수금과 선발 과정의 봉인 기록\n'
                '• 본관 앞: 국가계좌 창구·원내 실습',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.65,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '화면 아래 양옆의 화살표로 이전 방과 다음 방으로 이동해요. 노란 테두리는 확인할 안건이 있다는 뜻입니다.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  key: const Key('hub-tutorial-done'),
                  onPressed: () => onDone(),
                  child: const Text('알겠어요'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ApartmentPlaceScene extends StatelessWidget {
  const _ApartmentPlaceScene({
    super.key,
    required this.place,
    required this.state,
    required this.onOpenMarket,
    required this.onOpenBank,
    required this.onOpenDecisions,
    required this.onOpenLedger,
    required this.onOpenOrganization,
    required this.onOpenHomeImprovements,
    required this.onOpenWork,
  });

  final _ApartmentPlace place;
  final GameState state;
  final VoidCallback onOpenMarket;
  final VoidCallback onOpenBank;
  final VoidCallback onOpenDecisions;
  final VoidCallback onOpenLedger;
  final VoidCallback onOpenOrganization;
  final VoidCallback onOpenHomeImprovements;
  final VoidCallback onOpenWork;

  @override
  Widget build(BuildContext context) {
    final details = _ApartmentPlaceDetails.forPlace(place);
    final backgroundAsset = details.assetPath;
    return Stack(
      key: Key('apartment-place-${details.id}'),
      fit: StackFit.expand,
      children: [
        Image.asset(
          backgroundAsset,
          key: Key('apartment-background-${details.id}'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) =>
              _ApartmentFallbackBackground(details: details),
        ),
        if (place == _ApartmentPlace.bedroom) ...[
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-market-button'),
            alignment: const Alignment(-0.66, -0.20),
            width: 118,
            height: 112,
            eyebrow: '공용 단말기 켜기',
            label: '데시멀 홈 PC',
            icon: Icons.computer_rounded,
            accent: const Color(0xFF80D8FF),
            onTap: onOpenMarket,
          ),
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-ledger-button'),
            alignment: const Alignment(0.62, -0.08),
            width: 94,
            height: 126,
            eyebrow: '개인 장부 꺼내기',
            label: '국가계좌 장부',
            icon: Icons.inventory_2_rounded,
            accent: const Color(0xFFFFC78E),
            onTap: onOpenLedger,
          ),
        ],
        if (place == _ApartmentPlace.livingRoom) ...[
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-organization-button'),
            alignment: const Alignment(-0.68, -0.08),
            width: 124,
            height: 148,
            eyebrow: '동기·지도관과 회의',
            label: '데시멀·운용조직',
            icon: Icons.groups_2_rounded,
            accent: const Color(0xFFFFD27A),
            onTap: onOpenOrganization,
          ),
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-home-improvements-button'),
            alignment: const Alignment(0.68, 0.04),
            width: 122,
            height: 112,
            eyebrow: '공용 시설 정비',
            label: '생활환경 관리',
            icon: Icons.home_work_rounded,
            accent: const Color(0xFFFFA97A),
            onTap: onOpenHomeImprovements,
          ),
        ],
        if (place == _ApartmentPlace.corridor)
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-decisions-button'),
            alignment: const Alignment(0.08, -0.20),
            width: 106,
            height: 126,
            eyebrow: '봉인 기록함 열기',
            label: state.pendingDecisions.isEmpty
                ? '기록 보관실'
                : '새 기록 ${state.pendingDecisions.length}건',
            icon: Icons.markunread_mailbox_rounded,
            accent: state.pendingDecisions.isEmpty
                ? const Color(0xFF9ED9EF)
                : _yellow,
            attention: state.pendingDecisions.isNotEmpty,
            onTap: onOpenDecisions,
          ),
        if (place == _ApartmentPlace.neighborhood) ...[
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-bank-button'),
            alignment: const Alignment(-0.74, -0.34),
            width: 118,
            height: 144,
            eyebrow: '국가계좌 창구 가기',
            label: '국가계좌 창구',
            icon: Icons.account_balance_rounded,
            accent: const Color(0xFF86CBEA),
            onTap: onOpenBank,
          ),
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-work-button'),
            alignment: const Alignment(0.76, -0.24),
            width: 122,
            height: 148,
            eyebrow: '원내 실습 확인',
            label: '데시멀 실습 게시판',
            icon: Icons.sports_esports_rounded,
            accent: const Color(0xFF98E5C1),
            onTap: onOpenWork,
          ),
        ],
      ],
    );
  }
}

class _ApartmentSceneVignette extends StatelessWidget {
  const _ApartmentSceneVignette();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x8A070A12), Color(0x00070A12), Color(0xB8070A12)],
        stops: [0, 0.48, 1],
      ),
    ),
  );
}

class _ApartmentLocationHeader extends StatelessWidget {
  const _ApartmentLocationHeader({
    required this.details,
    required this.state,
    required this.activeSaveSlot,
    required this.lastSavedAt,
    required this.onOpenGameMenu,
  });

  final _ApartmentPlaceDetails details;
  final GameState state;
  final int activeSaveSlot;
  final DateTime? lastSavedAt;
  final VoidCallback onOpenGameMenu;

  @override
  Widget build(BuildContext context) {
    final level = state.progression.level;
    final currentLevelXp = experienceForLevel(level);
    final nextLevelXp = level >= 10
        ? currentLevelXp
        : experienceForLevel(level + 1);
    final levelProgress = level >= 10
        ? 1.0
        : ((state.progression.experience - currentLevelXp) /
                  (nextLevelXp - currentLevelXp))
              .clamp(0.0, 1.0);
    final weather = _ApartmentWeather.forState(state);

    return Semantics(
      container: true,
      label: '${details.title}, ${state.companyName}, $activeSaveSlot번 저장 슬롯',
      child: Container(
        key: const Key('room-company-sign'),
        height: 100,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFF243451),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF18243A), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66070A12),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 7, 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF9EA), Color(0xFFF4E6C5)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD99B2B), width: 1.5),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 47,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD66F),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF9C681B),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'DAY',
                            style: TextStyle(
                              fontFamily: _hubDisplayFont,
                              color: Color(0xFF76501B),
                              fontSize: 7.5,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${state.day}',
                            style: const TextStyle(
                              fontFamily: _hubDisplayFont,
                              color: _ink,
                              fontSize: 19,
                              height: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            details.title,
                            key: const Key('apartment-location-title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _hubDisplayFont,
                              color: _ink,
                              fontSize: 14.5,
                              height: 1.05,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Expanded(
                                child: KeyedSubtree(
                                  key: const Key('room-company-name'),
                                  child: Text(
                                    state.companyName,
                                    key: const Key('company-header-title'),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: _hubDisplayFont,
                                      color: Color(0xFF8B5C17),
                                      fontSize: 9.5,
                                      height: 1,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'LV.$level',
                                style: const TextStyle(
                                  fontFamily: _hubDisplayFont,
                                  color: Color(0xFF59667D),
                                  fontSize: 8.5,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: levelProgress,
                              minHeight: 5,
                              backgroundColor: const Color(0xFFD8CAB0),
                              valueColor: AlwaysStoppedAnimation(
                                details.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          key: const Key('game-menu-button'),
                          tooltip: '저장 및 게임 메뉴',
                          onPressed: onOpenGameMenu,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF243451),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(44, 44),
                            side: const BorderSide(
                              color: Color(0xFFDCA538),
                              width: 1.5,
                            ),
                          ),
                          icon: const Icon(Icons.menu_rounded, size: 23),
                        ),
                        if (lastSavedAt != null)
                          const Positioned(
                            right: -1,
                            top: -1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFF55C88A),
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                              child: SizedBox(width: 11, height: 11),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 27,
                decoration: BoxDecoration(
                  color: const Color(0xFF243451),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDCA538)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 13,
                      child: _ApartmentStatusChip(
                        icon: Icons.schedule_rounded,
                        iconColor: const Color(0xFFFFD66F),
                        label:
                            '${_apartmentHudDateLabel(state.currentDate)} · ${marketTimeLabel(state.marketMinute)}',
                        semanticLabel:
                            '${_apartmentDateLabel(state.currentDate)} · ${marketTimeLabel(state.marketMinute)}',
                      ),
                    ),
                    const _ApartmentStatusDivider(),
                    Expanded(
                      flex: 9,
                      child: _ApartmentStatusChip(
                        icon: Icons.payments_rounded,
                        iconColor: const Color(0xFFFFC66F),
                        label: '${_money(state.cash)}원',
                      ),
                    ),
                    const _ApartmentStatusDivider(),
                    Expanded(
                      flex: 9,
                      child: _ApartmentStatusChip(
                        icon: Icons.wb_sunny_rounded,
                        iconColor: const Color(0xFF83DBB7),
                        label: weather.label,
                        trailing: 'S$activeSaveSlot',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApartmentStatusDivider extends StatelessWidget {
  const _ApartmentStatusDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 14, color: const Color(0x66F3C960));
}

class _ApartmentStatusChip extends StatelessWidget {
  const _ApartmentStatusChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailing,
    this.semanticLabel,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? trailing;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel ?? label,
    excludeSemantics: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontFamily: _hubDisplayFont,
                  color: Colors.white,
                  fontSize: 9.2,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 3),
            Text(
              trailing!,
              style: const TextStyle(
                fontFamily: _hubDisplayFont,
                color: Color(0xFFFFD66F),
                fontSize: 7.2,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ApartmentWeather {
  const _ApartmentWeather(this.label);

  final String label;

  static _ApartmentWeather forState(GameState state) {
    if (state.marketMinute >= 17 * 60) {
      return const _ApartmentWeather('해질녘');
    }
    final seed = state.simulationSeed.codeUnits.fold<int>(
      state.day * 17,
      (value, unit) => (value * 31 + unit) & 0x7fffffff,
    );
    return switch (seed % 5) {
      1 || 3 => const _ApartmentWeather('구름'),
      4 => const _ApartmentWeather('비'),
      _ => const _ApartmentWeather('맑음'),
    };
  }
}

class _ApartmentMissionCard extends StatefulWidget {
  const _ApartmentMissionCard({
    required this.progress,
    required this.starBalance,
    required this.onClaim,
  });

  final MissionProgressView? progress;
  final int starBalance;
  final Future<MissionClaimResult> Function()? onClaim;

  @override
  State<_ApartmentMissionCard> createState() => _ApartmentMissionCardState();
}

class _ApartmentMissionCardState extends State<_ApartmentMissionCard> {
  bool _claiming = false;

  Future<void> _claim() async {
    final progress = widget.progress;
    final onClaim = widget.onClaim;
    if (_claiming ||
        progress == null ||
        !progress.complete ||
        onClaim == null) {
      return;
    }
    setState(() => _claiming = true);
    try {
      final result = await onClaim();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    final complete = progress?.complete ?? false;
    final current = progress == null
        ? 0
        : progress.current.clamp(0, progress.mission.target);
    return Semantics(
      container: true,
      button: complete,
      label: progress == null
          ? '모든 미션 완료'
          : complete
          ? '완료한 미션 ${progress.mission.title}, 눌러서 보상 받기'
          : '현재 미션 ${progress.mission.title}, ${progress.current}/${progress.mission.target}',
      child: Material(
        key: const Key('hub-mission-card'),
        color: Colors.transparent,
        child: Container(
          width: 202,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xF5FFF8E9),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFF243451), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D070A12),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: complete && !_claiming ? _claim : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 7, 7),
              child: Row(
                children: [
                  const _ApartmentMissionEmblem(),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              progress == null
                                  ? '미션 완료'
                                  : complete
                                  ? '보상 받기'
                                  : '현재 미션 $current/${progress.mission.target}',
                              style: const TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Color(0xFF9B681C),
                                fontSize: 8,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '⭐ ${widget.starBalance}',
                              style: const TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Color(0xFF6B7485),
                                fontSize: 8,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          progress?.mission.title ?? '모든 미션을 완료했어요!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: _hubDisplayFont,
                            color: _ink,
                            fontSize: 11.5,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  if (complete)
                    Container(
                      key: const Key('hub-claim-mission-reward'),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF243451),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: _claiming
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.card_giftcard_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                    )
                  else
                    const Icon(
                      Icons.flag_rounded,
                      color: Color(0xFF9B681C),
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApartmentMissionEmblem extends StatelessWidget {
  const _ApartmentMissionEmblem();

  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: const Color(0xFFFFD66F),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFF9C681B), width: 1.5),
    ),
    child: const Icon(Icons.star_rounded, color: Color(0xFF243451), size: 20),
  );
}

class _ApartmentObjectHotspot extends StatelessWidget {
  const _ApartmentObjectHotspot({
    required this.interactionKey,
    required this.alignment,
    required this.eyebrow,
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.width = 84,
    this.height = 84,
    this.attention = false,
  });

  final Key interactionKey;
  final Alignment alignment;
  final String eyebrow;
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final double width;
  final double height;
  final bool attention;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Tooltip(
        message: '$label · $eyebrow',
        waitDuration: const Duration(milliseconds: 280),
        child: Semantics(
          button: true,
          label: '$label 열기',
          child: SizedBox(
            width: width,
            height: height,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: interactionKey,
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  key: ValueKey(attention),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: (attention ? _coral : accent).withValues(
                      alpha: attention ? 0.20 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: attention ? 0.98 : 0.86,
                      ),
                      width: attention ? 2.6 : 2,
                    ),
                    boxShadow: [
                      const BoxShadow(
                        color: Color(0x450B1423),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                      BoxShadow(
                        color: (attention ? _coral : accent).withValues(
                          alpha: attention ? 0.64 : 0.34,
                        ),
                        blurRadius: attention ? 22 : 14,
                        spreadRadius: attention ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        attention ? Icons.priority_high_rounded : icon,
                        color: Colors.white.withValues(
                          alpha: attention ? 1 : 0.82,
                        ),
                        size: attention ? 34 : 28,
                        shadows: const [
                          Shadow(
                            color: Color(0xA0121A27),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(4, 0, 4, 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xD91B2537),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: const TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ApartmentActionRail extends StatelessWidget {
  const _ApartmentActionRail({
    required this.hasPendingDecision,
    required this.campaignComplete,
    required this.marketMinute,
    required this.messengerUnread,
    required this.onOpenMessenger,
    required this.onOpenRelationships,
    required this.onOpenCalendar,
    required this.onAdvanceHour,
    required this.onAdvanceDay,
    required this.onAdvanceBatch,
    required this.onOpenEnding,
    required this.onHelp,
  });

  final bool hasPendingDecision;
  final bool campaignComplete;
  final int marketMinute;
  final int messengerUnread;
  final VoidCallback onOpenMessenger;
  final VoidCallback onOpenRelationships;
  final VoidCallback onOpenCalendar;
  final VoidCallback onAdvanceHour;
  final VoidCallback onAdvanceDay;
  final VoidCallback onAdvanceBatch;
  final VoidCallback onOpenEnding;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final ended = marketMinute >= marketDayEndMinute;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ApartmentRailButton(
          buttonKey: const Key('phone-messenger-button'),
          tooltip: messengerUnread > 0
              ? '데시멀톡 · 새 메시지 $messengerUnread개'
              : '데시멀톡 · 동기들과 대화',
          icon: Icons.smartphone_rounded,
          badgeCount: messengerUnread,
          onPressed: onOpenMessenger,
        ),
        const SizedBox(height: 7),
        _ApartmentRailButton(
          buttonKey: const Key('relationship-status-button'),
          tooltip: '캐릭터 10명',
          assetPath: 'assets/images/hud_clean_letter.png',
          onPressed: onOpenRelationships,
        ),
        const SizedBox(height: 7),
        _ApartmentRailButton(
          buttonKey: const Key('life-calendar-button'),
          tooltip: '성장 달력 · 날짜와 지난 사건 기록',
          icon: Icons.calendar_month_rounded,
          onPressed: onOpenCalendar,
        ),
        const SizedBox(height: 7),
        _ApartmentRailButton(
          buttonKey: const Key('advance-hour-button'),
          tooltip: '1시간 보내기 · 게임 시간 60분 진행',
          assetPath: 'assets/images/hud_clean_hourglass.png',
          disabled: hasPendingDecision || ended,
          onPressed: hasPendingDecision || ended ? null : onAdvanceHour,
        ),
        const SizedBox(height: 7),
        _ApartmentRailButton(
          buttonKey: const Key('advance-day-button'),
          tooltip: campaignComplete
              ? '최종 결산 열기'
              : '하루 보내기 · 신문 확인 후 다음 날 08:00',
          assetPath: campaignComplete
              ? 'assets/images/hud_clean_quest.png'
              : 'assets/images/hud_clean_moon.png',
          disabled: hasPendingDecision,
          onPressed: hasPendingDecision
              ? null
              : campaignComplete
              ? onOpenEnding
              : onAdvanceDay,
        ),
        const SizedBox(height: 7),
        _ApartmentRailButton(
          buttonKey: const Key('advance-batch-button'),
          tooltip: '빠르게 진행 · 여러 날을 한 번에',
          assetPath: 'assets/images/hud_clean_fast.png',
          disabled: hasPendingDecision || campaignComplete,
          onPressed: hasPendingDecision || campaignComplete
              ? null
              : onAdvanceBatch,
        ),
        const SizedBox(height: 7),
        _ApartmentRailButton(
          buttonKey: const Key('hub-help-button'),
          tooltip: '아이콘 사용법 보기',
          assetPath: 'assets/images/hud_clean_quest.png',
          onPressed: onHelp,
        ),
      ],
    );
  }
}

class _ApartmentRailButton extends StatelessWidget {
  const _ApartmentRailButton({
    required this.buttonKey,
    required this.tooltip,
    required this.onPressed,
    this.assetPath,
    this.icon,
    this.badgeCount = 0,
    this.disabled = false,
  }) : assert(assetPath != null || icon != null);

  final Key buttonKey;
  final String tooltip;
  final String? assetPath;
  final IconData? icon;
  final int badgeCount;
  final VoidCallback? onPressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    waitDuration: const Duration(milliseconds: 280),
    child: Semantics(
      button: true,
      label: tooltip,
      child: SizedBox(
        width: 50,
        height: 50,
        child: ElevatedButton(
          key: buttonKey,
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            elevation: disabled ? 1 : 5,
            shadowColor: const Color(0x660B1423),
            backgroundColor: const Color(0xF7FFF8E9),
            foregroundColor: _ink,
            disabledBackgroundColor: const Color(0xE8EEE8DC),
            disabledForegroundColor: const Color(0xFF8C8F96),
            shape: const CircleBorder(
              side: BorderSide(color: Color(0xFF243451), width: 2),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: disabled ? 0.34 : 1,
                child: assetPath != null
                    ? Image.asset(
                        assetPath!,
                        width: 37,
                        height: 37,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      )
                    : Icon(icon, size: 28, color: const Color(0xFF243451)),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    key: ValueKey('rail-badge-$badgeCount'),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE85252),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              if (disabled)
                Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: const Color(0xE623314C),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFE7A8)),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ApartmentRoomArrow extends StatelessWidget {
  const _ApartmentRoomArrow({
    required this.destination,
    required this.flipHorizontally,
    required this.onMove,
  });

  final _ApartmentPlace? destination;
  final bool flipHorizontally;
  final ValueChanged<_ApartmentPlace> onMove;

  @override
  Widget build(BuildContext context) {
    final target = destination;
    final details = target == null
        ? null
        : _ApartmentPlaceDetails.forPlace(target);
    final tooltip = details == null ? '더 이동할 방이 없어요' : '${details.title}으로 이동';
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 280),
      child: Semantics(
        button: true,
        enabled: target != null,
        label: tooltip,
        child: Opacity(
          opacity: target == null ? 0.22 : 1,
          child: SizedBox.square(
            dimension: 68,
            child: Material(
              color: Colors.transparent,
              child: InkResponse(
                key: details == null ? null : Key('apartment-go-${details.id}'),
                onTap: target == null ? null : () => onMove(target),
                radius: 34,
                splashColor: const Color(0x44FFD76A),
                highlightColor: Colors.transparent,
                child: Center(
                  child: Transform.flip(
                    flipX: flipHorizontally,
                    child: Image.asset(
                      'assets/images/hud_clean_arrow_right.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApartmentFallbackBackground extends StatelessWidget {
  const _ApartmentFallbackBackground({required this.details});

  final _ApartmentPlaceDetails details;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF172031),
          details.accent.withValues(alpha: 0.48),
          const Color(0xFF292235),
        ],
      ),
    ),
    child: Center(
      child: Icon(
        details.icon,
        size: 112,
        color: Colors.white.withValues(alpha: 0.11),
      ),
    ),
  );
}

class _ApartmentPlaceDetails {
  const _ApartmentPlaceDetails({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.hint,
    required this.assetPath,
    required this.icon,
    required this.accent,
  });

  final String id;
  final String title;
  final String shortTitle;
  final String hint;
  final String assetPath;
  final IconData icon;
  final Color accent;

  static _ApartmentPlaceDetails forPlace(
    _ApartmentPlace place,
  ) => switch (place) {
    _ApartmentPlace.bedroom => const _ApartmentPlaceDetails(
      id: 'bedroom',
      title: '프로젝트 데시멀 · 생활 라운지',
      shortTitle: '생활 라운지',
      hint: '공용 단말기 · 국가계좌 장부',
      assetPath:
          'assets/images/cinematic_soft_painted/decimal/bg_decimal_living_lounge_1999_v1.png',
      icon: Icons.bed_rounded,
      accent: Color(0xFF82D7FF),
    ),
    _ApartmentPlace.livingRoom => const _ApartmentPlaceDetails(
      id: 'living-room',
      title: '프로젝트 데시멀 · 트레이딩 플로어',
      shortTitle: '투자실',
      hint: '동기 10명 · 운영관 · 운용 조직',
      assetPath:
          'assets/images/cinematic_soft_painted/decimal/bg_decimal_trading_floor_dawn_2000_v1.png',
      icon: Icons.monitor_heart_rounded,
      accent: Color(0xFFFFCB78),
    ),
    _ApartmentPlace.kitchen => const _ApartmentPlaceDetails(
      id: 'kitchen',
      title: '프로젝트 데시멀 · 기기 정비실',
      shortTitle: '기기 정비실',
      hint: '단말기 정비 · 통신 장비 · 공용 설비',
      assetPath:
          'assets/images/cinematic_soft_painted/decimal/bg_decimal_electronics_workshop_2000_v1.png',
      icon: Icons.inventory_2_rounded,
      accent: Color(0xFF8CE3BE),
    ),
    _ApartmentPlace.corridor => const _ApartmentPlaceDetails(
      id: 'corridor',
      title: '프로젝트 데시멀 · 기록 보관실',
      shortTitle: '기록 보관실',
      hint: '국가 회수금 · 선발 과정 · 봉인 안건',
      assetPath:
          'assets/images/cinematic_soft_painted/decimal/bg_decimal_records_archive_2000_v1.png',
      icon: Icons.folder_copy_rounded,
      accent: Color(0xFF9ED9EF),
    ),
    _ApartmentPlace.neighborhood => const _ApartmentPlaceDetails(
      id: 'neighborhood',
      title: '프로젝트 데시멀 · 본관 앞',
      shortTitle: '본관 앞',
      hint: '국가계좌 창구 · 원내 실습',
      assetPath:
          'assets/images/cinematic_soft_painted/decimal/bg_decimal_gangnam_exterior_winter_1999_v1.png',
      icon: Icons.account_balance_rounded,
      accent: Color(0xFF98E5C1),
    ),
  };
}
