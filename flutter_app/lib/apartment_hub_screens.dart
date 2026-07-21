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
  });

  final GameState state;
  final VoidCallback onOpenMarket;
  final VoidCallback onOpenDecisions;
  final VoidCallback onOpenLedger;
  final VoidCallback onOpenOrganization;
  final VoidCallback onOpenWork;

  @override
  State<ApartmentHubScreen> createState() => _ApartmentHubScreenState();
}

class _ApartmentHubScreenState extends State<ApartmentHubScreen> {
  _ApartmentPlace _place = _ApartmentPlace.bedroom;

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
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 9,
            child: _ApartmentTravelDock(place: _place, onMove: _moveTo),
          ),
        ],
      ),
    );
  }
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
  const _ApartmentLocationHeader({required this.details, required this.state});

  final _ApartmentPlaceDetails details;
  final GameState state;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '${details.title}, ${state.companyName}',
    child: Container(
      key: const Key('room-company-sign'),
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.fromLTRB(12, 9, 11, 9),
      decoration: BoxDecoration(
        color: const Color(0xE61B2232),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x99FFFFFF), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: details.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: details.accent.withValues(alpha: 0.72)),
            ),
            child: Icon(details.icon, color: details.accent, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.title,
                  key: const Key('apartment-location-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  details.hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC8D0DE),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 112),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                KeyedSubtree(
                  key: const Key('room-company-name'),
                  child: Text(
                    state.companyName,
                    key: const Key('company-header-title'),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: details.accent,
                      fontSize: 10,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'DAY ${state.day} · ${marketTimeLabel(state.marketMinute)}',
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_money(state.cash)}원',
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFFCFD6E5),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
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
                color: const Color(0xE61D2638),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: attention ? _yellow : const Color(0xCCFFFFFF),
                  width: attention ? 2.2 : 1.4,
                ),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0x9C000000),
                    blurRadius: 15,
                    offset: Offset(0, 7),
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
    final destinations = switch (place) {
      _ApartmentPlace.bedroom => const [_ApartmentPlace.livingRoom],
      _ApartmentPlace.livingRoom => const [
        _ApartmentPlace.bedroom,
        _ApartmentPlace.kitchen,
      ],
      _ApartmentPlace.kitchen => const [_ApartmentPlace.livingRoom],
    };

    return Semantics(
      container: true,
      label: '아파트 장소 이동',
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
        decoration: BoxDecoration(
          color: const Color(0xEE171D2B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x99FFFFFF), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xA6000000),
              blurRadius: 19,
              offset: Offset(0, 8),
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
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.35,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                for (var index = 0; index < destinations.length; index++) ...[
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
              color: details.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: details.accent.withValues(alpha: 0.78)),
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
          hint: 'CRT와 서류 캐비닛에서 투자 업무를 본다',
          assetPath: 'assets/images/bg_bedroom_premium_2000.png',
          icon: Icons.bedroom_parent_rounded,
          accent: Color(0xFF82D7FF),
        ),
        _ApartmentPlace.livingRoom => const _ApartmentPlaceDetails(
          id: 'living-room',
          title: '가족 아파트 · 거실',
          shortTitle: '거실',
          hint: '안건을 검토하고 가족과 사람 이야기를 나눈다',
          assetPath: 'assets/images/bg_living_room_premium_2000.png',
          icon: Icons.weekend_rounded,
          accent: Color(0xFFFFCB78),
        ),
        _ApartmentPlace.kitchen => const _ApartmentPlaceDetails(
          id: 'kitchen',
          title: '가족 아파트 · 부엌',
          shortTitle: '부엌',
          hint: '유선전화로 오늘 할 수 있는 일거리를 찾는다',
          assetPath: 'assets/images/bg_kitchen_premium_2000.png',
          icon: Icons.kitchen_rounded,
          accent: Color(0xFF8CE3BE),
        ),
      };
}
