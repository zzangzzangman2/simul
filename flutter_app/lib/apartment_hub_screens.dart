part of 'main.dart';

enum _ApartmentPlace { bedroom, livingRoom, kitchen }

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
    required this.onOpenDecisions,
    required this.onOpenLedger,
    required this.onOpenOrganization,
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
  final VoidCallback onOpenDecisions;
  final VoidCallback onOpenLedger;
  final VoidCallback onOpenOrganization;
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
    final missionProgress = const GameEngine().missionProgress(widget.state);
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
              onOpenDecisions: widget.onOpenDecisions,
              onOpenLedger: widget.onOpenLedger,
              onOpenOrganization: widget.onOpenOrganization,
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
          Positioned(
            left: 56,
            right: 56,
            bottom: 10,
            child: Center(
              child: _ApartmentMissionCard(
                progress: missionProgress,
                onOpen: widget.onOpenDecisions,
                onClaim: widget.onClaimMission,
              ),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 38,
            child: _ApartmentRoomArrow(
              destination: previousPlace,
              flipHorizontally: true,
              onMove: _moveTo,
            ),
          ),
          Positioned(
            right: 6,
            bottom: 38,
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
                '우리 집 투자연구소 사용법',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                '• 침실 CRT: 주식시장과 1분봉\n• 침실 서류함: 장부·성과\n• 거실 편지: 필수 결정\n• 거실 소파: 가족·채용·펀드\n• 부엌 전화: 직접 번 종잣돈',
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
    required this.onOpenDecisions,
    required this.onOpenLedger,
    required this.onOpenOrganization,
    required this.onOpenWork,
  });

  final _ApartmentPlace place;
  final GameState state;
  final VoidCallback onOpenMarket;
  final VoidCallback onOpenDecisions;
  final VoidCallback onOpenLedger;
  final VoidCallback onOpenOrganization;
  final VoidCallback onOpenWork;

  @override
  Widget build(BuildContext context) {
    final details = _ApartmentPlaceDetails.forPlace(place);
    return Stack(
      key: Key('apartment-place-${details.id}'),
      fit: StackFit.expand,
      children: [
        Image.asset(
          details.assetPath,
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
            alignment: const Alignment(-0.63, -0.22),
            eyebrow: '컴퓨터 켜기',
            label: '주식시장',
            accent: const Color(0xFF80D8FF),
            onTap: onOpenMarket,
          ),
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-ledger-button'),
            alignment: const Alignment(0.56, -0.02),
            eyebrow: '장부 펼치기',
            label: '서류함',
            accent: const Color(0xFFFFC78E),
            onTap: onOpenLedger,
          ),
        ],
        if (place == _ApartmentPlace.livingRoom) ...[
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-organization-button'),
            alignment: const Alignment(-0.72, -0.25),
            eyebrow: '함께 이야기',
            label: '가족·조직',
            accent: const Color(0xFFFFD27A),
            onTap: onOpenOrganization,
          ),
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-decisions-button'),
            alignment: const Alignment(0.22, 0.10),
            eyebrow: '새 편지 확인',
            label: state.pendingDecisions.isEmpty
                ? '안건 편지'
                : '안건 ${state.pendingDecisions.length}건',
            accent: state.pendingDecisions.isEmpty
                ? const Color(0xFFFFE9BA)
                : _yellow,
            attention: state.pendingDecisions.isNotEmpty,
            onTap: onOpenDecisions,
          ),
        ],
        if (place == _ApartmentPlace.kitchen)
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-work-button'),
            alignment: const Alignment(-0.65, -0.08),
            eyebrow: '일거리 찾기',
            label: '일거리 전화',
            accent: const Color(0xFF98E5C1),
            onTap: onOpenWork,
          ),
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
    final seed = state.simulationSeed.codeUnits.fold<int>(
      state.day * 17,
      (value, unit) => (value * 31 + unit) & 0x7fffffff,
    );
    const labels = <String>['맑음', '구름', '포근', '찬바람'];
    return _ApartmentWeather(labels[seed % labels.length]);
  }
}

class _ApartmentMissionCard extends StatefulWidget {
  const _ApartmentMissionCard({
    required this.progress,
    required this.onOpen,
    required this.onClaim,
  });

  final MissionProgressView? progress;
  final VoidCallback onOpen;
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
    return Semantics(
      container: true,
      button: true,
      label: progress == null
          ? '모든 미션 완료'
          : '현재 미션 ${progress.mission.title}, ${progress.current}/${progress.mission.target}',
      child: Material(
        key: const Key('hub-mission-card'),
        color: Colors.transparent,
        child: Container(
          width: 248,
          height: 104,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF243451), width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66070A12),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: widget.onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 10, 8),
              child: progress == null
                  ? const Row(
                      children: [
                        _ApartmentMissionEmblem(),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '모든 미션 완료!',
                                style: TextStyle(
                                  fontFamily: _hubDisplayFont,
                                  color: _ink,
                                  fontSize: 15,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 7),
                              Text(
                                '성장 기록 보기  ›',
                                style: TextStyle(
                                  fontFamily: _hubDisplayFont,
                                  color: Color(0xFF6B7485),
                                  fontSize: 10,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const _ApartmentMissionEmblem(),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        '현재 미션',
                                        style: TextStyle(
                                          fontFamily: _hubDisplayFont,
                                          color: Color(0xFF9B681C),
                                          fontSize: 8.5,
                                          height: 1,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (progress.remainingDays != null)
                                        Text(
                                          '${progress.remainingDays}일 남음',
                                          style: const TextStyle(
                                            fontFamily: _hubDisplayFont,
                                            color: Color(0xFF9A5146),
                                            fontSize: 8,
                                            height: 1,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    progress.mission.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: _hubDisplayFont,
                                      color: _ink,
                                      fontSize: 14.5,
                                      height: 1,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                progress.mission.objective,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: _hubDisplayFont,
                                  color: Color(0xFF5E6675),
                                  fontSize: 9,
                                  height: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${progress.current.clamp(0, progress.mission.target)}/${progress.mission.target}',
                              style: const TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: _ink,
                                fontSize: 8.5,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress.ratio,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFD9CDB5),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF4EBA8E),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              '보상  ${progress.mission.experienceReward} XP',
                              style: const TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Color(0xFF8A5A16),
                                fontSize: 8.5,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (progress.mission.cashReward > 0) ...[
                              const SizedBox(width: 7),
                              Text(
                                '+${_money(progress.mission.cashReward)}원',
                                style: const TextStyle(
                                  fontFamily: _hubDisplayFont,
                                  color: Color(0xFF2E8063),
                                  fontSize: 8.5,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (complete)
                              SizedBox(
                                height: 23,
                                child: FilledButton(
                                  key: const Key('hub-claim-mission-reward'),
                                  onPressed: _claiming ? null : _claim,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    backgroundColor: const Color(0xFF243451),
                                    foregroundColor: Colors.white,
                                    textStyle: const TextStyle(
                                      fontFamily: _hubDisplayFont,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(_claiming ? '저장 중' : '보상 받기'),
                                ),
                              )
                            else
                              const Text(
                                '자세히  ›',
                                style: TextStyle(
                                  fontFamily: _hubDisplayFont,
                                  color: Color(0xFF243451),
                                  fontSize: 9,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
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
    required this.accent,
    required this.onTap,
    this.attention = false,
  });

  final Key interactionKey;
  final Alignment alignment;
  final String eyebrow;
  final String label;
  final Color accent;
  final VoidCallback onTap;
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
            width: 48,
            height: 48,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: interactionKey,
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Center(
                  child: AnimatedContainer(
                    key: ValueKey(attention),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: attention ? 42 : 36,
                    height: attention ? 42 : 36,
                    decoration: BoxDecoration(
                      color: attention
                          ? const Color(0xBFE24B5B)
                          : const Color(0x9975D6F4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xF2FFFFFF),
                        width: 2,
                      ),
                      boxShadow: [
                        const BoxShadow(
                          color: Color(0x3D0B1423),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                        BoxShadow(
                          color: (attention ? _coral : accent).withValues(
                            alpha: attention ? 0.62 : 0.42,
                          ),
                          blurRadius: attention ? 18 : 12,
                          spreadRadius: attention ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: attention
                          ? const Text(
                              '!',
                              style: TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Colors.white,
                                fontSize: 26,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                    ),
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
    required this.onAdvanceHour,
    required this.onAdvanceDay,
    required this.onAdvanceBatch,
    required this.onOpenEnding,
    required this.onHelp,
  });

  final bool hasPendingDecision;
  final bool campaignComplete;
  final int marketMinute;
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
    required this.assetPath,
    required this.onPressed,
    this.disabled = false,
  });

  final Key buttonKey;
  final String tooltip;
  final String assetPath;
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
                child: Image.asset(
                  assetPath,
                  width: 37,
                  height: 37,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
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
          opacity: target == null ? 0.24 : 1,
          child: SizedBox(
            width: 50,
            height: 50,
            child: ElevatedButton(
              key: details == null ? null : Key('apartment-go-${details.id}'),
              onPressed: target == null ? null : () => onMove(target),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                elevation: target == null ? 0 : 5,
                shadowColor: const Color(0x660B1423),
                backgroundColor: const Color(0xF7FFF8E9),
                foregroundColor: _ink,
                disabledBackgroundColor: const Color(0xE8EEE8DC),
                shape: const CircleBorder(
                  side: BorderSide(color: Color(0xFF243451), width: 2),
                ),
              ),
              child: Transform.flip(
                flipX: flipHorizontally,
                child: Image.asset(
                  'assets/images/hud_clean_arrow_right.png',
                  width: 35,
                  height: 35,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
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

  static _ApartmentPlaceDetails forPlace(_ApartmentPlace place) =>
      switch (place) {
        _ApartmentPlace.bedroom => const _ApartmentPlaceDetails(
          id: 'bedroom',
          title: '가족 아파트 · 작은방',
          shortTitle: '작은방',
          hint: '주식 보기 · 장부 정리',
          assetPath: 'assets/images/bg_bedroom_cartoon_2000.png',
          icon: Icons.bedroom_parent_rounded,
          accent: Color(0xFF82D7FF),
        ),
        _ApartmentPlace.livingRoom => const _ApartmentPlaceDetails(
          id: 'living-room',
          title: '가족 아파트 · 거실',
          shortTitle: '거실',
          hint: '안건 확인 · 가족 이야기',
          assetPath: 'assets/images/bg_living_room_cartoon_2000.png',
          icon: Icons.weekend_rounded,
          accent: Color(0xFFFFCB78),
        ),
        _ApartmentPlace.kitchen => const _ApartmentPlaceDetails(
          id: 'kitchen',
          title: '가족 아파트 · 부엌',
          shortTitle: '부엌',
          hint: '일거리 찾기 · 종잣돈 벌기',
          assetPath: 'assets/images/bg_kitchen_cartoon_2000.png',
          icon: Icons.kitchen_rounded,
          accent: Color(0xFF8CE3BE),
        ),
      };
}
