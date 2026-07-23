part of 'main.dart';

enum _ApartmentPlace { bedroom, livingRoom, kitchen }

String _apartmentDateLabel(DateTime date) {
  const weekdays = <String>['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
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
            left: 10,
            top: 10,
            right: 10,
            child: _ApartmentLocationHeader(
              details: details,
              state: widget.state,
              activeSaveSlot: widget.activeSaveSlot,
              lastSavedAt: widget.lastSavedAt,
              onOpenGameMenu: widget.onOpenGameMenu,
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 9,
            child: _ApartmentTravelDock(place: _place, onMove: _moveTo),
          ),
          Positioned(
            right: 10,
            top: 126,
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
                '아래 이동 독에서는 어느 방으로든 바로 이동할 수 있어요. 노란 테두리는 확인할 안건이 있다는 뜻입니다.',
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
            alignment: const Alignment(-0.58, -0.14),
            icon: Icons.desktop_windows_rounded,
            eyebrow: '컴퓨터 켜기',
            label: '주식시장',
            accent: const Color(0xFF80D8FF),
            onTap: onOpenMarket,
          ),
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-ledger-button'),
            alignment: const Alignment(0.72, 0.36),
            icon: Icons.inventory_2_rounded,
            eyebrow: '장부 펼치기',
            label: '서류함',
            accent: const Color(0xFFFFC78E),
            onTap: onOpenLedger,
          ),
        ],
        if (place == _ApartmentPlace.livingRoom) ...[
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-organization-button'),
            alignment: const Alignment(-0.52, 0.06),
            icon: Icons.family_restroom_rounded,
            eyebrow: '함께 이야기',
            label: '가족·조직',
            accent: const Color(0xFFFFD27A),
            onTap: onOpenOrganization,
          ),
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-decisions-button'),
            alignment: const Alignment(0.02, 0.48),
            icon: state.pendingDecisions.isEmpty
                ? Icons.drafts_rounded
                : Icons.mark_email_unread_rounded,
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
            alignment: const Alignment(-0.68, 0.06),
            icon: Icons.phone_in_talk_rounded,
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

    return Semantics(
      container: true,
      label: '${details.title}, ${state.companyName}, $activeSaveSlot번 저장 슬롯',
      child: ClipRRect(
        key: const Key('room-company-sign'),
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
            decoration: BoxDecoration(
              color: const Color(0xEFFFFAF0),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xF2FFFFFF), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330F1724),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            details.accent,
                            details.accent.withValues(alpha: 0.72),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: [
                          BoxShadow(
                            color: details.accent.withValues(alpha: 0.34),
                            blurRadius: 11,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'DAY',
                            style: TextStyle(
                              color: _ink.withValues(alpha: 0.66),
                              fontSize: 7,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${state.day}',
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 19,
                              height: 1,
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
                          Row(
                            children: [
                              Icon(
                                details.icon,
                                color: details.accent,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  details.title,
                                  key: const Key('apartment-location-title'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 15,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          KeyedSubtree(
                            key: const Key('room-company-name'),
                            child: Text(
                              state.companyName,
                              key: const Key('company-header-title'),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: details.accent.computeLuminance() > 0.7
                                    ? const Color(0xFF8A5F20)
                                    : details.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'LV.$level',
                                style: const TextStyle(
                                  color: Color(0xFF667189),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: levelProgress,
                                    minHeight: 4,
                                    backgroundColor: const Color(0xFFDDE2EA),
                                    valueColor: AlwaysStoppedAnimation(
                                      details.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          key: const Key('game-menu-button'),
                          tooltip: '저장 및 게임 메뉴',
                          onPressed: onOpenGameMenu,
                          style: IconButton.styleFrom(
                            backgroundColor: _ink,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(44, 44),
                          ),
                          icon: const Icon(Icons.menu_rounded),
                        ),
                        if (lastSavedAt != null)
                          const Positioned(
                            right: 2,
                            top: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFF55C88A),
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                              child: SizedBox(width: 10, height: 10),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _ApartmentHudChip(
                        icon: Icons.schedule_rounded,
                        label:
                            '${_apartmentDateLabel(state.currentDate)} · ${marketTimeLabel(state.marketMinute)}',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: _ApartmentHudChip(
                        icon: Icons.savings_rounded,
                        label: '${_money(state.cash)}원',
                        accent: const Color(0xFFFFB84D),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _ApartmentHudChip(label: 'S$activeSaveSlot'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApartmentHudChip extends StatelessWidget {
  const _ApartmentHudChip({this.icon, required this.label, this.accent});

  final IconData? icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Container(
    height: 27,
    padding: EdgeInsets.symmetric(horizontal: icon == null ? 8 : 7),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F3F7),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: accent ?? const Color(0xFF76829A), size: 12),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ApartmentObjectHotspot extends StatelessWidget {
  const _ApartmentObjectHotspot({
    required this.interactionKey,
    required this.alignment,
    required this.icon,
    required this.eyebrow,
    required this.label,
    required this.accent,
    required this.onTap,
    this.attention = false,
  });

  final Key interactionKey;
  final Alignment alignment;
  final IconData icon;
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
            width: 58,
            height: 58,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: interactionKey,
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Ink(
                      decoration: BoxDecoration(
                        color: const Color(0xEFFFFAF0),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: attention ? _coral : Colors.white,
                          width: attention ? 2.6 : 2,
                        ),
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0x480B1423),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                          BoxShadow(
                            color: accent.withValues(
                              alpha: attention ? 0.52 : 0.26,
                            ),
                            blurRadius: attention ? 18 : 10,
                            spreadRadius: attention ? 2 : 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: _ink, size: 22),
                        ),
                      ),
                    ),
                    if (attention)
                      const Positioned(
                        right: -1,
                        top: -1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _coral,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(color: Colors.white, width: 2),
                            ),
                          ),
                          child: SizedBox(width: 15, height: 15),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 13, sigmaY: 13),
        child: Container(
          width: 58,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xDFFFFAF0),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xEFFFFFFF), width: 1.4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x380B1423),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ApartmentRailButton(
                buttonKey: const Key('advance-hour-button'),
                tooltip: '1시간 보내기 · 게임 시간 60분 진행',
                icon: hasPendingDecision || ended
                    ? Icons.lock_clock_rounded
                    : Icons.more_time_rounded,
                color: const Color(0xFF4B9F87),
                onPressed: hasPendingDecision || ended ? null : onAdvanceHour,
              ),
              const SizedBox(height: 6),
              _ApartmentRailButton(
                buttonKey: const Key('advance-day-button'),
                tooltip: campaignComplete
                    ? '최종 결산 열기'
                    : '하루 보내기 · 신문 확인 후 다음 날 08:00',
                icon: campaignComplete
                    ? Icons.emoji_events_rounded
                    : Icons.bedtime_rounded,
                color: _coral,
                onPressed: hasPendingDecision
                    ? null
                    : campaignComplete
                    ? onOpenEnding
                    : onAdvanceDay,
              ),
              const SizedBox(height: 6),
              _ApartmentRailButton(
                buttonKey: const Key('advance-batch-button'),
                tooltip: '빠르게 진행 · 여러 날을 한 번에',
                icon: Icons.fast_forward_rounded,
                color: const Color(0xFFFFD05A),
                foreground: _ink,
                onPressed: hasPendingDecision || campaignComplete
                    ? null
                    : onAdvanceBatch,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                  width: 28,
                  child: Divider(height: 1, color: Color(0xFFD9DDE4)),
                ),
              ),
              _ApartmentRailButton(
                buttonKey: const Key('hub-help-button'),
                tooltip: '아이콘 사용법 보기',
                icon: Icons.help_outline_rounded,
                color: const Color(0xFF74819A),
                onPressed: onHelp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApartmentRailButton extends StatelessWidget {
  const _ApartmentRailButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.foreground = Colors.white,
  });

  final Key buttonKey;
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    waitDuration: const Duration(milliseconds: 280),
    child: Semantics(
      button: true,
      label: tooltip,
      child: SizedBox(
        width: 46,
        height: 48,
        child: ElevatedButton(
          key: buttonKey,
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            elevation: 0,
            backgroundColor: color,
            foregroundColor: foreground,
            disabledBackgroundColor: const Color(0xFFE1E4E8),
            disabledForegroundColor: const Color(0xFF9AA2AF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Icon(icon, size: 21),
        ),
      ),
    ),
  );
}

class _ApartmentTravelDock extends StatelessWidget {
  const _ApartmentTravelDock({required this.place, required this.onMove});

  final _ApartmentPlace place;
  final ValueChanged<_ApartmentPlace> onMove;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: Semantics(
      container: true,
      label: '아파트 장소 이동',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 13, sigmaY: 13),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xDFFFFAF0),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xEFFFFFFF), width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3D0B1423),
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (
                  var index = 0;
                  index < _ApartmentPlace.values.length;
                  index++
                ) ...[
                  if (index > 0) const SizedBox(width: 6),
                  _ApartmentTravelButton(
                    place: _ApartmentPlace.values[index],
                    selected: _ApartmentPlace.values[index] == place,
                    onTap: () => onMove(_ApartmentPlace.values[index]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ApartmentTravelButton extends StatelessWidget {
  const _ApartmentTravelButton({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final _ApartmentPlace place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = _ApartmentPlaceDetails.forPlace(place);
    return Tooltip(
      message: selected ? '${details.title} · 현재 위치' : '${details.title}으로 이동',
      waitDuration: const Duration(milliseconds: 280),
      child: Semantics(
        button: true,
        selected: selected,
        label: '${details.title}으로 이동',
        child: SizedBox(
          width: 48,
          height: 48,
          child: ElevatedButton(
            key: Key('apartment-go-${details.id}'),
            onPressed: selected ? null : onTap,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              elevation: 0,
              backgroundColor: details.accent,
              foregroundColor: _ink,
              disabledBackgroundColor: details.accent,
              disabledForegroundColor: _ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: selected ? _ink : Colors.transparent,
                  width: selected ? 2 : 0,
                ),
              ),
            ),
            child: Icon(details.icon, size: 21),
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
          assetPath: 'assets/images/bg_bedroom_premium_2000.png',
          icon: Icons.bedroom_parent_rounded,
          accent: Color(0xFF82D7FF),
        ),
        _ApartmentPlace.livingRoom => const _ApartmentPlaceDetails(
          id: 'living-room',
          title: '가족 아파트 · 거실',
          shortTitle: '거실',
          hint: '안건 확인 · 가족 이야기',
          assetPath: 'assets/images/bg_living_room_premium_2000.png',
          icon: Icons.weekend_rounded,
          accent: Color(0xFFFFCB78),
        ),
        _ApartmentPlace.kitchen => const _ApartmentPlaceDetails(
          id: 'kitchen',
          title: '가족 아파트 · 부엌',
          shortTitle: '부엌',
          hint: '일거리 찾기 · 종잣돈 벌기',
          assetPath: 'assets/images/bg_kitchen_premium_2000.png',
          icon: Icons.kitchen_rounded,
          accent: Color(0xFF8CE3BE),
        ),
      };
}
