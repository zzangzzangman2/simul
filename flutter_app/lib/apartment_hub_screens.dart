part of 'main.dart';

enum _ApartmentPlace { bedroom, livingRoom, kitchen }

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
            right: 12,
            top: 108,
            child: Semantics(
              button: true,
              label: '허브 도움말 열기',
              child: IconButton.filled(
                key: const Key('hub-help-button'),
                tooltip: '허브 사용법',
                onPressed: () => setState(() => _tutorialVisible = true),
                icon: const Icon(Icons.help_outline_rounded),
              ),
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
            eyebrow: 'CRT COMPUTER',
            label: '주식시장',
            accent: const Color(0xFF80D8FF),
            onTap: onOpenMarket,
          ),
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-ledger-button'),
            alignment: const Alignment(0.72, 0.36),
            icon: Icons.inventory_2_rounded,
            eyebrow: 'FILE CABINET',
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
            eyebrow: 'FAMILY SOFA',
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
            eyebrow: 'DECISION LETTER',
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
            eyebrow: 'CORDED PHONE',
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
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '${details.title}, ${state.companyName}, $activeSaveSlot번 저장 슬롯',
    child: ClipRRect(
      key: const Key('room-company-sign'),
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 11, sigmaY: 11),
        child: Container(
          constraints: const BoxConstraints(minHeight: 90),
          padding: const EdgeInsets.fromLTRB(11, 9, 8, 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xB52B2927), Color(0xA6141B28)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x70F3DFC1), width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x52000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: details.accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: details.accent.withValues(alpha: 0.72),
                      ),
                    ),
                    child: Icon(details.icon, color: details.accent, size: 22),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              details.title,
                              key: const Key('apartment-location-title'),
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: KeyedSubtree(
                                key: const Key('room-company-name'),
                                child: Text(
                                  state.companyName,
                                  key: const Key('company-header-title'),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: details.accent,
                                    fontSize: 9,
                                    height: 1.15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                state.story.officeTier >= 2
                                    ? '정식 본사 · ${details.hint}'
                                    : state.story.officeTier == 1
                                    ? '작은 사무실 · ${details.hint}'
                                    : details.hint,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFB5C0D3),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('game-menu-button'),
                    tooltip: '저장 및 게임 메뉴',
                    onPressed: onOpenGameMenu,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x1FFFFFFF),
                      foregroundColor: lastSavedAt == null
                          ? const Color(0xFFCBD4E4)
                          : const Color(0xFF8FE0A9),
                      minimumSize: const Size(42, 42),
                    ),
                    icon: const Icon(Icons.menu_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      _ApartmentHudChip(
                        icon: Icons.calendar_today_rounded,
                        label:
                            'DAY ${state.day} · ${marketTimeLabel(state.marketMinute)}',
                      ),
                      const SizedBox(width: 5),
                      _ApartmentHudChip(
                        icon: Icons.account_balance_wallet_rounded,
                        label: '${_money(state.cash)}원',
                      ),
                      const SizedBox(width: 5),
                      _ApartmentHudChip(label: 'LV.${state.progression.level}'),
                      const SizedBox(width: 5),
                      _ApartmentHudChip(label: 'S$activeSaveSlot'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ApartmentHudChip extends StatelessWidget {
  const _ApartmentHudChip({this.icon, required this.label});

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: EdgeInsets.symmetric(horizontal: icon == null ? 7 : 6),
    decoration: BoxDecoration(
      color: const Color(0x2B0B0D11),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0x3DF3DFC1)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: const Color(0xFF93A4BD), size: 10),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: Color(0xFFDDE4EF),
            fontSize: 9,
            fontWeight: FontWeight.w800,
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
    child: Semantics(
      button: true,
      label: '$label 열기',
      excludeSemantics: true,
      child: SizedBox(
        width: 132,
        height: 64,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: interactionKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(19),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(8, 7, 9, 7),
              decoration: BoxDecoration(
                color: const Color(0xB81D2632),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: attention ? _yellow : const Color(0x99F3DFC1),
                  width: attention ? 2.0 : 1.2,
                ),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 11,
                    offset: Offset(0, 5),
                  ),
                  BoxShadow(
                    color: accent.withValues(alpha: attention ? 0.65 : 0.30),
                    blurRadius: attention ? 20 : 11,
                    spreadRadius: attention ? 2 : 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x52000000),
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: const Color(0xFF20283A), size: 22),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: 6.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.45,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
  Widget build(BuildContext context) {
    final destinations = _ApartmentPlace.values
        .where((destination) => destination != place)
        .toList(growable: false);

    return Semantics(
      container: true,
      label: '아파트 장소 이동',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 70),
            padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xAA312820), Color(0xB8141A24)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x70F3DFC1), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 13,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.near_me_rounded, size: 11, color: _yellow),
                    SizedBox(width: 4),
                    Text(
                      '집 안에서 이동',
                      style: TextStyle(
                        color: Color(0xFFC9D1DF),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    for (
                      var index = 0;
                      index < destinations.length;
                      index++
                    ) ...[
                      if (index > 0) const SizedBox(width: 7),
                      Expanded(
                        child: _ApartmentTravelButton(
                          place: destinations[index],
                          onTap: () => onMove(destinations[index]),
                        ),
                      ),
                    ],
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

class _ApartmentTravelButton extends StatelessWidget {
  const _ApartmentTravelButton({required this.place, required this.onTap});

  final _ApartmentPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = _ApartmentPlaceDetails.forPlace(place);
    return Semantics(
      button: true,
      label: '${details.title}으로 이동',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('apartment-go-${details.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: details.accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: details.accent.withValues(alpha: 0.68)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(details.icon, color: details.accent, size: 19),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    '${details.shortTitle}으로',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ],
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
