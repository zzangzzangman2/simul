part of 'main.dart';

// Kept temporarily as a visual fallback for very old save screenshots. The
// live game uses ApartmentHubScreen, whose interactions are split by room.
// ignore: unused_element
class _InteractiveBedroom extends StatelessWidget {
  const _InteractiveBedroom({
    required this.state,
    required this.onOpenDecisions,
    required this.onOpenMarket,
    required this.onOpenLedger,
    required this.onOpenOrganization,
    required this.onOpenWork,
  });

  final GameState state;
  final VoidCallback onOpenDecisions;
  final VoidCallback onOpenMarket;
  final VoidCallback onOpenLedger;
  final VoidCallback onOpenOrganization;
  final VoidCallback onOpenWork;

  @override
  Widget build(BuildContext context) {
    final pendingCount = state.pendingDecisions.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        const sourceWidth = 1536.0;
        const sourceHeight = 1024.0;
        const hotspotWidth = 112.0;
        const hotspotHeight = 60.0;
        final scale = math.max(
          size.width / sourceWidth,
          size.height / sourceHeight,
        );
        final renderedHeight = sourceHeight * scale;
        final offsetY = (size.height - renderedHeight) / 2;

        Widget hotspot({
          required Key key,
          required double sourceX,
          required double sourceY,
          required IconData icon,
          required String label,
          required Color color,
          required VoidCallback onTap,
          bool attention = false,
        }) {
          final maxLeft = math.max(8.0, size.width - hotspotWidth - 8);
          final maxTop = math.max(72.0, size.height - hotspotHeight - 8);
          final left = (sourceX * scale - hotspotWidth / 2)
              .clamp(8.0, maxLeft)
              .toDouble();
          final top = (offsetY + sourceY * scale - hotspotHeight / 2)
              .clamp(72.0, maxTop)
              .toDouble();
          return Positioned(
            left: left,
            top: top,
            width: hotspotWidth,
            height: hotspotHeight,
            child: _RoomHotspot(
              interactionKey: key,
              icon: icon,
              label: label,
              color: color,
              onTap: onTap,
              attention: attention,
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/bg_boy_room_1999.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) =>
                  const _CartoonRoomBackground(),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x70000000),
                    Color(0x08000000),
                    Color(0x9C000000),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              right: 10,
              child: _RoomCompanySign(state: state),
            ),
            hotspot(
              key: const Key('open-work-button'),
              sourceX: 520,
              sourceY: 235,
              icon: Icons.savings_rounded,
              label: '일거리',
              color: const Color(0xFFDFF5E8),
              onTap: onOpenWork,
            ),
            hotspot(
              key: const Key('open-organization-button'),
              sourceX: 475,
              sourceY: 420,
              icon: Icons.groups_2_rounded,
              label: '사람들',
              color: const Color(0xFFFFE9C7),
              onTap: onOpenOrganization,
            ),
            hotspot(
              key: const Key('open-market-button'),
              sourceX: 205,
              sourceY: 500,
              icon: Icons.computer_rounded,
              label: 'CRT 시장',
              color: const Color(0xFFDDF3FF),
              onTap: onOpenMarket,
            ),
            hotspot(
              key: const Key('open-decisions-button'),
              sourceX: 92,
              sourceY: 660,
              icon: pendingCount == 0
                  ? Icons.drafts_rounded
                  : Icons.mark_email_unread_rounded,
              label: pendingCount == 0 ? '안건 편지' : '안건 $pendingCount건',
              color: pendingCount == 0 ? const Color(0xFFF7F2DF) : _yellow,
              onTap: onOpenDecisions,
              attention: pendingCount > 0,
            ),
            hotspot(
              key: const Key('open-ledger-button'),
              sourceX: 455,
              sourceY: 700,
              icon: Icons.inventory_2_rounded,
              label: '서류 서랍',
              color: const Color(0xFFFFDCD7),
              onTap: onOpenLedger,
            ),
            const Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: Text(
                '빛나는 방 물건을 눌러 이동하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoomCompanySign extends StatelessWidget {
  const _RoomCompanySign({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('room-company-sign'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xDB20283A),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xCCFFFFFF)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.companyName,
                key: const Key('room-company-name'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'FAMILY RESEARCH DESK',
                style: TextStyle(
                  color: _yellow,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_money(state.cash)}원',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _RoomHotspot extends StatelessWidget {
  const _RoomHotspot({
    required this.interactionKey,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.attention = false,
  });

  final Key interactionKey;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool attention;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label 열기',
    excludeSemantics: true,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: interactionKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              const BoxShadow(
                color: Color(0xA6000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
              if (attention)
                const BoxShadow(
                  color: _yellow,
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: _ink, size: 22),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 10,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
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

class DecisionInboxScreen extends StatelessWidget {
  const DecisionInboxScreen({
    super.key,
    required this.state,
    required this.onResolveDecision,
    required this.onClaimMission,
  });

  final GameState state;
  final Future<void> Function(String decisionId, String optionId)
  onResolveDecision;
  final Future<MissionClaimResult> Function() onClaimMission;

  void _openDecision(BuildContext context, DecisionCardData decision) {
    final inboxNavigator = Navigator.of(context);
    inboxNavigator.push<void>(
      _gameSceneRoute<void>(
        FamilyDecisionScene(
          state: state,
          decision: decision,
          onSelect: (decisionContext, optionId) async {
            await onResolveDecision(decision.id, optionId);
            if (!decisionContext.mounted) return;
            Navigator.of(decisionContext).pop();
            if (!context.mounted) return;
            inboxNavigator.pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = state.pendingDecisions;
    final missionProgress = const GameEngine().missionProgress(state);
    return Scaffold(
      key: const Key('decision-inbox-screen'),
      backgroundColor: const Color(0xFF272331),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_boy_room_1999.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
            ),
          ),
          const Positioned.fill(child: ColoredBox(color: Color(0x990B0B12))),
          SafeArea(
            child: Column(
              children: [
                _SceneClockStrip(
                  location: '내 방 · 미션 보드',
                  caption: missionProgress == null
                      ? '모든 장기 미션을 완주했다.'
                      : '행동으로 목표를 채우고 보상과 스킬을 얻는다.',
                  minute: state.marketMinute,
                  costLabel:
                      'LV.${state.progression.level} · ${pending.length}건',
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F0D9),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFD5B987),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: missionProgress == null && pending.isEmpty
                        ? _EmptyDecisionInbox(
                            onBack: () => Navigator.of(context).pop(),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                            children: [
                              Text(
                                state.companyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _coral,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                '미션 · 안건 보드',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'LV.${state.progression.level} · ${state.progression.experience} XP · 완수 ${state.progression.claimedMissionIds.length}/${missionCatalog.length}',
                                style: const TextStyle(
                                  color: Color(0xFF777D8B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (missionProgress != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _MissionProgressCard(
                                    state: state,
                                    progress: missionProgress,
                                    onClaim: onClaimMission,
                                  ),
                                ),
                              if (pending.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    '지금 결정할 편지는 없어요. 미션 목표는 시장·일거리·사람들·자산 화면에서 계속 진행됩니다.',
                                    style: TextStyle(
                                      color: Color(0xFF6F7480),
                                      fontSize: 11,
                                      height: 1.45,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ...pending.map(
                                (decision) => Padding(
                                  padding: const EdgeInsets.only(bottom: 11),
                                  child: _DecisionEnvelopeCard(
                                    decision: decision,
                                    onTap: () =>
                                        _openDecision(context, decision),
                                  ),
                                ),
                              ),
                            ],
                          ),
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

class _MissionProgressCard extends StatefulWidget {
  const _MissionProgressCard({
    required this.state,
    required this.progress,
    required this.onClaim,
  });

  final GameState state;
  final MissionProgressView progress;
  final Future<MissionClaimResult> Function() onClaim;

  @override
  State<_MissionProgressCard> createState() => _MissionProgressCardState();
}

class _MissionProgressCardState extends State<_MissionProgressCard> {
  bool _claiming = false;

  Future<void> _claim() async {
    if (_claiming || !widget.progress.complete) return;
    setState(() => _claiming = true);
    try {
      final result = await widget.onClaim();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      if (result.success) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _claiming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('미션 보상 저장에 실패했습니다. 다시 시도해 주세요.')),
      );
    }
  }

  String _progressLabel() {
    const moneyMetrics = <String>{
      'cash',
      'cash_gain',
      'realized_profit',
      'research_income',
      'external_aum',
      'trade_volume',
      'net_worth',
      'property_income',
    };
    final current = widget.progress.current.clamp(
      0,
      widget.progress.mission.target,
    );
    if (moneyMetrics.contains(widget.progress.mission.metric)) {
      return '${_money(current)} / ${_money(widget.progress.mission.target)}원';
    }
    return '$current / ${widget.progress.mission.target}';
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.progress.mission;
    final level = widget.state.progression.level;
    final unlockedSkills = skillCatalog
        .where((skill) => skill.level <= level)
        .toList(growable: false);
    final nextSkill = skillCatalog
        .where((skill) => skill.level > level)
        .firstOrNull;
    return Container(
      key: const Key('active-mission-card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.progress.complete ? const Color(0xFF56A879) : _coral,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x2233405F), offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  mission.chapter,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.progress.remainingDays != null)
                Text(
                  '남은 ${widget.progress.remainingDays}일',
                  style: const TextStyle(
                    color: _coral,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            mission.title,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            mission.story,
            style: const TextStyle(
              color: Color(0xFF60697E),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            mission.objective,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              key: const Key('active-mission-progress'),
              value: widget.progress.ratio,
              minHeight: 10,
              backgroundColor: const Color(0xFFE6DFC9),
              color: widget.progress.complete ? const Color(0xFF56A879) : _blue,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.progress.unlocked
                ? _progressLabel()
                : '${mission.requiredYear}년 해금',
            style: const TextStyle(
              color: Color(0xFF6F7480),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MissionRewardChip(
                label: '+${mission.experienceReward} XP',
                color: _blue,
              ),
              if (mission.cashReward > 0)
                _MissionRewardChip(
                  label: '+${_money(mission.cashReward)}원',
                  color: _yellow,
                ),
              if (mission.reputationReward > 0)
                _MissionRewardChip(
                  label: '평판 +${mission.reputationReward}',
                  color: const Color(0xFFD7F0DE),
                ),
              if (mission.trustReward > 0)
                _MissionRewardChip(
                  label: '신뢰 +${mission.trustReward}',
                  color: const Color(0xFFFFD9D3),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              key: const Key('claim-mission-reward'),
              onPressed: widget.progress.complete && !_claiming ? _claim : null,
              icon: _claiming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.workspace_premium_rounded),
              label: Text(widget.progress.complete ? '보상 받고 다음 미션' : '목표 진행 중'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF33405F),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '해금 스킬',
            style: TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            unlockedSkills
                .map((skill) => '${skill.name} · ${skill.effect}')
                .join('\n'),
            style: const TextStyle(
              color: Color(0xFF677086),
              fontSize: 9,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (nextSkill != null) ...[
            const SizedBox(height: 5),
            Text(
              '다음: LV.${nextSkill.level} ${nextSkill.name} — ${nextSkill.effect}',
              style: const TextStyle(
                color: _coral,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MissionRewardChip extends StatelessWidget {
  const _MissionRewardChip({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _ink,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _EmptyDecisionInbox extends StatelessWidget {
  const _EmptyDecisionInbox({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mark_email_read_rounded, color: _coral, size: 58),
          const SizedBox(height: 12),
          const Text(
            '도착한 안건이 없어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '방으로 돌아가 시간을 보내면 새 편지가 도착할 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6F7480), height: 1.5),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 260,
            child: _RoomButton(
              key: const Key('empty-inbox-back-button'),
              icon: Icons.meeting_room_rounded,
              title: '내 방으로 돌아가기',
              subtitle: '다른 물건을 살펴본다',
              color: const Color(0xFFDDF3FF),
              compact: true,
              onTap: onBack,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DecisionEnvelopeCard extends StatelessWidget {
  const _DecisionEnvelopeCard({required this.decision, required this.onTap});

  final DecisionCardData decision;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: Key('decision-inbox-item-${decision.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFCFB686), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x2633405F), offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _yellow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.mail_rounded, color: _ink),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    decision.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${decision.proposer} · DAY ${decision.createdDay}',
                    style: const TextStyle(
                      color: Color(0xFF777D8B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

class PortfolioLedgerScreen extends StatefulWidget {
  const PortfolioLedgerScreen({
    super.key,
    required this.state,
    this.onPurchaseSpendingOption,
    this.onSellRealEstate,
    this.onPlayChanceGame,
    this.universe,
  });

  final GameState state;
  final Future<FinanceActionResult> Function(String optionId)?
  onPurchaseSpendingOption;
  final Future<FinanceActionResult> Function(String assetId)? onSellRealEstate;
  final Future<FinanceActionResult> Function(int stake)? onPlayChanceGame;
  final HistoricalMarketUniverse? universe;

  @override
  State<PortfolioLedgerScreen> createState() => _PortfolioLedgerScreenState();
}

class _PortfolioLedgerScreenState extends State<PortfolioLedgerScreen> {
  late Future<HistoricalMarketUniverse> _universeFuture;
  late GameState _state;

  GameState get state => _state;

  Future<FinanceActionResult> _purchase(String optionId) async {
    final handler = widget.onPurchaseSpendingOption;
    if (handler == null) return _disabledFinanceResult();
    final result = await handler(optionId);
    if (mounted && result.success) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _sell(String assetId) async {
    final handler = widget.onSellRealEstate;
    if (handler == null) return _disabledFinanceResult();
    final result = await handler(assetId);
    if (mounted && result.success) setState(() => _state = result.state);
    return result;
  }

  Future<FinanceActionResult> _playChance(int stake) async {
    final handler = widget.onPlayChanceGame;
    if (handler == null) return _disabledFinanceResult();
    final result = await handler(stake);
    if (mounted && result.success) setState(() => _state = result.state);
    return result;
  }

  FinanceActionResult _disabledFinanceResult() => FinanceActionResult(
    state: state,
    success: false,
    message: 'Saving is unavailable in this test screen.',
  );

  void _openAssetSpending() {
    Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        AssetSpendingScreen(
          state: state,
          onPurchase: _purchase,
          onSellRealEstate: _sell,
          onPlayChanceGame: _playChance,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _state = widget.state;
    _universeFuture = widget.universe == null
        ? HistoricalMarketUniverse.load()
        : Future.value(widget.universe!);
  }

  void _retryMarketData() {
    setState(() {
      _universeFuture = HistoricalMarketUniverse.load(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('portfolio-ledger-screen'),
    backgroundColor: const Color(0xFF201713),
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/bg_boy_room_1999.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
          ),
        ),
        const Positioned.fill(child: ColoredBox(color: Color(0xB8120C09))),
        SafeArea(
          child: Column(
            children: [
              _SceneClockStrip(
                location: '내 방 · 책상 서랍',
                caption: '보유 주식과 현금 기록을 서류철에서 확인한다.',
                minute: state.marketMinute,
                costLabel: '시간 소모 없음',
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF573628),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFD8A85A),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xAA000000),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FutureBuilder<HistoricalMarketUniverse>(
                      future: _universeFuture,
                      builder: (context, snapshot) {
                        final assets = {
                          for (final asset
                              in snapshot.data?.assets ??
                                  const <HistoricalMarketAsset>[])
                            asset.id: asset,
                        };
                        final prices = <String, double>{};
                        var valuedCost = 0;
                        for (final position in state.positions) {
                          final asset = assets[position.assetId];
                          if (asset == null || asset.currency != 'KRW') {
                            continue;
                          }
                          final price = _portfolioPriceAtCurrentTime(
                            asset,
                            state,
                          );
                          if (price != null) {
                            prices[position.assetId] = price;
                            valuedCost += position.totalCost;
                          }
                        }
                        final portfolioValue = state.portfolioValue(prices);
                        final aum = state.totalAum(prices);
                        final unrealizedPnl = portfolioValue - valuedCost;
                        final grade = _ledgerGradeFor(
                          snapshot.hasData ? aum : state.cash,
                          state.positions.length,
                        );
                        final positiveCashFlow = state.ledger.fold<int>(
                          0,
                          (sum, entry) =>
                              entry.amount > 0 ? sum + entry.amount : sum,
                        );
                        final negativeCashFlow = state.ledger.fold<int>(
                          0,
                          (sum, entry) =>
                              entry.amount < 0 ? sum + entry.amount.abs() : sum,
                        );
                        final recentNews = state.story.newsArchive.reversed
                            .take(10)
                            .toList(growable: false);
                        return ListView(
                          key: const Key('portfolio-ledger-scroll'),
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 28),
                          children: [
                            _LeatherLedgerCover(
                              companyName: state.companyName,
                              day: state.day,
                              grade: grade,
                            ),
                            const SizedBox(height: 10),
                            _AssetSpendingEntry(
                              state: state,
                              onTap: _openAssetSpending,
                            ),
                            const SizedBox(height: 10),
                            if (snapshot.hasError) ...[
                              _MarketDataLoadError(onRetry: _retryMarketData),
                              const SizedBox(height: 10),
                            ],
                            _LedgerHeroCard(
                              cash: state.cash,
                              portfolioValue: portfolioValue,
                              aum: aum,
                              unrealizedPnl: unrealizedPnl,
                              grade: grade,
                              marketReady: snapshot.hasData,
                              marketFailed: snapshot.hasError,
                            ),
                            const SizedBox(height: 10),
                            _LedgerAllocationCard(
                              cash: state.cash,
                              portfolioValue: portfolioValue,
                              marketReady: snapshot.hasData,
                            ),
                            const SizedBox(height: 18),
                            _LedgerSectionTitle(
                              icon: Icons.style_rounded,
                              title: '보유 종목 기록',
                              badge: '${state.positions.length}종목',
                            ),
                            if (state.positions.isEmpty)
                              const _LedgerEmptyPage(
                                icon: Icons.bookmark_add_outlined,
                                title: '첫 투자 기록을 기다리는 중',
                                body: 'CRT 시장에서 종목을 매수하면 이 장부에 카드가 생겨요.',
                              )
                            else
                              ...state.positions.map((position) {
                                final asset = assets[position.assetId];
                                final price = prices[position.assetId];
                                final currency =
                                    asset?.currency ?? position.currency;
                                final isForeign = currency != 'KRW';
                                final value = price == null
                                    ? null
                                    : (price * position.units).round();
                                final returnRate =
                                    value == null || position.totalCost <= 0
                                    ? null
                                    : (value - position.totalCost) /
                                          position.totalCost *
                                          100;
                                final units =
                                    position.units ==
                                        position.units.roundToDouble()
                                    ? position.units.toInt().toString()
                                    : position.units.toStringAsFixed(4);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 9),
                                  child: _LedgerHoldingCard(
                                    name: asset?.name ?? position.name,
                                    symbol: asset?.code ?? position.symbol,
                                    market: asset?.market ?? position.market,
                                    currency: currency,
                                    units: units,
                                    averageCost: position.averageCost.round(),
                                    value: value,
                                    returnRate: returnRate,
                                    isForeign: isForeign,
                                    marketFailed: snapshot.hasError,
                                  ),
                                );
                              }),
                            const SizedBox(height: 20),
                            _LedgerSectionTitle(
                              icon: Icons.receipt_long_rounded,
                              title: '현금 원장',
                              badge: '${state.ledger.length}건',
                            ),
                            const SizedBox(height: 9),
                            _CashFlowSummary(
                              income: positiveCashFlow,
                              expense: negativeCashFlow,
                            ),
                            if (state.ledger.isEmpty)
                              const _LedgerEmptyPage(
                                icon: Icons.edit_note_rounded,
                                title: '아직 적힌 거래가 없어요',
                                body: '일거리 수입과 주식 주문이 날짜순으로 기록됩니다.',
                              )
                            else
                              ...state.ledger.reversed
                                  .take(20)
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: _CashLedgerEntry(entry: entry),
                                    ),
                                  ),
                            const SizedBox(height: 12),
                            _LedgerAppendix(state: state),
                            const SizedBox(height: 20),
                            _LedgerSectionTitle(
                              icon: Icons.newspaper_rounded,
                              title: '최근 신문',
                              badge: '${state.story.newsArchive.length}일',
                            ),
                            if (recentNews.isEmpty)
                              const _LedgerEmptyPage(
                                icon: Icons.article_outlined,
                                title: '아직 보관한 신문이 없어요',
                                body: '하루를 마치고 신문을 확인하면 여기에 남습니다.',
                              )
                            else
                              ...recentNews.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: _NewsArchiveEntry(item: item),
                                ),
                              ),
                            const SizedBox(height: 12),
                            const SizedBox(height: 10),
                            const _LedgerFooterNote(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LedgerGrade {
  const _LedgerGrade({
    required this.rank,
    required this.title,
    required this.caption,
    required this.color,
  });

  final String rank;
  final String title;
  final String caption;
  final Color color;
}

_LedgerGrade _ledgerGradeFor(int aum, int holdingCount) {
  if (aum >= 100000000) {
    return const _LedgerGrade(
      rank: 'S',
      title: '밀레니엄 운용가',
      caption: '시장에 이름을 남길 준비가 됐어요.',
      color: Color(0xFF7C4DFF),
    );
  }
  if (aum >= 10000000) {
    return const _LedgerGrade(
      rank: 'A',
      title: '성장주 운용자',
      caption: '한 장의 장부가 진짜 포트폴리오가 됐어요.',
      color: Color(0xFFD98B20),
    );
  }
  if (aum >= 1000000) {
    return const _LedgerGrade(
      rank: 'B',
      title: '가치 사냥꾼',
      caption: '현금과 종목의 균형을 익히는 중이에요.',
      color: Color(0xFF3E8E72),
    );
  }
  if (aum >= 100000 || holdingCount >= 3) {
    return const _LedgerGrade(
      rank: 'C',
      title: '가족 계좌 연습생',
      caption: '첫 분산투자 원칙을 세우기 시작했어요.',
      color: Color(0xFF4C78B8),
    );
  }
  if (aum > 0 || holdingCount > 0) {
    return const _LedgerGrade(
      rank: 'D',
      title: '종잣돈 수습생',
      caption: '작은 수입과 첫 주식부터 또박또박 기록해요.',
      color: Color(0xFF9A6A3A),
    );
  }
  return const _LedgerGrade(
    rank: 'F',
    title: '빈 장부의 주인',
    caption: '첫 수입을 적는 순간 운용이 시작됩니다.',
    color: Color(0xFF777064),
  );
}

class _LeatherLedgerCover extends StatelessWidget {
  const _LeatherLedgerCover({
    required this.companyName,
    required this.day,
    required this.grade,
  });

  final String companyName;
  final int day;
  final _LedgerGrade grade;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFF3B241C),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFA97743), width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFCA9A52),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFD98B)),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Color(0xFF3A2319),
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                companyName,
                key: const Key('ledger-company-name'),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFFFE4AE),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                '서류함 · 포트폴리오',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'PRIVATE LEDGER 2000  ·  DAY $day',
                style: const TextStyle(
                  color: Color(0xFFBEA68D),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: grade.color.withValues(alpha: 0.2),
            border: Border.all(color: grade.color, width: 2),
          ),
          child: Text(
            grade.rank,
            style: TextStyle(
              color: grade.color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _LedgerHeroCard extends StatelessWidget {
  const _LedgerHeroCard({
    required this.cash,
    required this.portfolioValue,
    required this.aum,
    required this.unrealizedPnl,
    required this.grade,
    required this.marketReady,
    required this.marketFailed,
  });

  final int cash;
  final int portfolioValue;
  final int aum;
  final int unrealizedPnl;
  final _LedgerGrade grade;
  final bool marketReady;
  final bool marketFailed;

  @override
  Widget build(BuildContext context) {
    final valueLabel = marketReady
        ? '${_money(aum)}원'
        : marketFailed
        ? '현금 ${_money(cash)}원'
        : '계산 중';
    final pnlColor = unrealizedPnl >= 0
        ? const Color(0xFFB64235)
        : const Color(0xFF315E9B);
    final marketCaption = marketReady
        ? '현금과 평가 가능한 원화 주식을 합산한 장부가치'
        : marketFailed
        ? '시세를 다시 연결하면 총자산이 완성됩니다.'
        : '시장 장부를 펼치는 중입니다.';
    return Container(
      key: const Key('ledger-aum-hero'),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD3B77B), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '총 운용자산 · 원화 장부',
                  style: TextStyle(
                    color: Color(0xFF755B3B),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B241C),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                  'BOOK VALUE',
                  style: TextStyle(
                    color: Color(0xFFFFD98B),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valueLabel,
              key: const Key('ledger-total-aum'),
              style: const TextStyle(
                color: Color(0xFF30241C),
                fontSize: 31,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            marketCaption,
            style: const TextStyle(
              color: Color(0xFF8B765A),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: grade.color.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                    border: Border.all(color: grade.color, width: 2),
                  ),
                  child: Text(
                    grade.rank,
                    style: TextStyle(
                      color: grade.color,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '운용 등급 · ${grade.title}',
                        key: const Key('ledger-management-grade'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF3B3028),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        grade.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7C6A58),
                          fontSize: 9,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (marketReady && portfolioValue > 0) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${unrealizedPnl >= 0 ? '+' : ''}${_money(unrealizedPnl)}원',
                        style: TextStyle(
                          color: pnlColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerAllocationCard extends StatelessWidget {
  const _LedgerAllocationCard({
    required this.cash,
    required this.portfolioValue,
    required this.marketReady,
  });

  final int cash;
  final int portfolioValue;
  final bool marketReady;

  @override
  Widget build(BuildContext context) {
    final cashAssets = math.max(0, cash);
    final stockAssets = math.max(0, portfolioValue);
    final totalAssets = cashAssets + stockAssets;
    final hasAssets = marketReady && totalAssets > 0;
    final cashRatio = hasAssets
        ? (cashAssets / totalAssets).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final cashPercent = (cashRatio * 100).round();
    final stockPercent = hasAssets ? 100 - cashPercent : 0;
    final operatingDebt = math.max(0, -cash);
    final netAum = cash + portfolioValue;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E7C8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC9A86B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.donut_large_rounded,
                size: 17,
                color: Color(0xFF684936),
              ),
              SizedBox(width: 7),
              Text(
                '현금 · 주식 운용 비중',
                style: TextStyle(
                  color: Color(0xFF493426),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _LedgerRatioBar(
            cashRatio: cashRatio,
            marketReady: marketReady,
            hasAssets: hasAssets,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AllocationLegend(
                  color: const Color(0xFFD39A36),
                  label: '현금',
                  value: marketReady
                      ? '$cashPercent% · ${_money(cash)}원'
                      : '${_money(cash)}원',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AllocationLegend(
                  color: const Color(0xFF4B7A68),
                  label: '원화 주식',
                  value: marketReady
                      ? '$stockPercent% · ${_money(portfolioValue)}원'
                      : '시세 연결 중',
                ),
              ),
            ],
          ),
          if (!marketReady) ...[
            const SizedBox(height: 8),
            const Text(
              '시장 시세가 연결되면 정확한 자산 비중을 표시합니다.',
              style: TextStyle(
                color: Color(0xFF8B765A),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (operatingDebt > 0) ...[
            const SizedBox(height: 8),
            Text(
              '운영 부채 ${_money(operatingDebt)}원 · 순자산 ${_money(netAum)}원',
              key: const Key('ledger-operating-debt'),
              style: const TextStyle(
                color: Color(0xFF9E4A42),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LedgerRatioBar extends StatelessWidget {
  const _LedgerRatioBar({
    required this.cashRatio,
    required this.marketReady,
    required this.hasAssets,
  });

  final double cashRatio;
  final bool marketReady;
  final bool hasAssets;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('ledger-allocation-bar'),
    height: 13,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: marketReady && hasAssets
          ? const Color(0xFF4B7A68)
          : const Color(0xFFD8C9A8),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0xFFAA8A58)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: constraints.maxWidth * cashRatio,
          color: const Color(0xFFD39A36),
        ),
      ),
    ),
  );
}

class _AllocationLegend extends StatelessWidget {
  const _AllocationLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B765A),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF3F3025),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _LedgerSectionTitle extends StatelessWidget {
  const _LedgerSectionTitle({
    required this.icon,
    required this.title,
    required this.badge,
  });

  final IconData icon;
  final String title;
  final String badge;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 31,
        height: 31,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE1A2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD2A95E)),
        ),
        child: Icon(icon, size: 17, color: const Color(0xFF5B3B28)),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF3B241C),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF9E7248)),
        ),
        child: Text(
          badge,
          style: const TextStyle(
            color: Color(0xFFFFD98B),
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

class _LedgerHoldingCard extends StatelessWidget {
  const _LedgerHoldingCard({
    required this.name,
    required this.symbol,
    required this.market,
    required this.currency,
    required this.units,
    required this.averageCost,
    required this.value,
    required this.returnRate,
    required this.isForeign,
    required this.marketFailed,
  });

  final String name;
  final String symbol;
  final String market;
  final String currency;
  final String units;
  final int averageCost;
  final int? value;
  final double? returnRate;
  final bool isForeign;
  final bool marketFailed;

  @override
  Widget build(BuildContext context) {
    final rate = returnRate;
    final positive = rate != null && rate >= 0;
    final accent = rate == null
        ? const Color(0xFF8B8276)
        : positive
        ? const Color(0xFFB54A3E)
        : const Color(0xFF35639D);
    final valueLabel = isForeign
        ? '환율 연결 대기'
        : marketFailed
        ? '시세 불러오기 실패'
        : value == null
        ? '시세 없음'
        : '${_money(value!)}원';
    final rateLabel = rate == null
        ? '평가 대기'
        : '${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(2)}%';
    final detailLabel =
        '$units주 · 평균 ${_ledgerCurrencyAmount(averageCost, currency)}'
        ' · $rateLabel';
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD2B77C)),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 43,
            leading: Container(
              width: 43,
              height: 43,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.45)),
              ),
              child: Text(
                name.isEmpty ? '?' : String.fromCharCode(name.runes.first),
                style: TextStyle(
                  color: accent,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            title: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF352820),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Container(
              margin: const EdgeInsets.only(top: 5),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                detailLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            trailing: Text(
              valueLabel,
              maxLines: 2,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF49382D),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Divider(height: 18, color: Color(0xFFE5D6B7)),
          Row(
            children: [
              Expanded(
                child: _LedgerHoldingMetric(label: '운용 시장', value: market),
              ),
              Expanded(
                child: _LedgerHoldingMetric(label: '종목 코드', value: symbol),
              ),
              Expanded(
                child: _LedgerHoldingMetric(
                  label: '결제 통화',
                  value: currency,
                  alignRight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerHoldingMetric extends StatelessWidget {
  const _LedgerHoldingMetric({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final bool alignRight;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignRight
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF9A856C),
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          color: Color(0xFF44352A),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _CashFlowSummary extends StatelessWidget {
  const _CashFlowSummary({required this.income, required this.expense});

  final int income;
  final int expense;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _CashFlowStamp(
          label: '누적 유입',
          value: income == 0 ? '0원' : '+${_money(income)}원',
          color: const Color(0xFF3D7D61),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _CashFlowStamp(
          label: '누적 유출',
          value: expense == 0 ? '0원' : '-${_money(expense)}원',
          color: const Color(0xFF9E4A42),
        ),
      ),
    ],
  );
}

class _CashFlowStamp extends StatelessWidget {
  const _CashFlowStamp({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.55)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFFEAC3),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CashLedgerEntry extends StatelessWidget {
  const _CashLedgerEntry({required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final incoming = entry.amount >= 0;
    final accent = incoming ? const Color(0xFF3E7A5E) : const Color(0xFFA14D43);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFCDB17A)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            padding: const EdgeInsets.symmetric(vertical: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEEE0C1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              children: [
                const Text(
                  'DAY',
                  style: TextStyle(
                    color: Color(0xFF9B8261),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${entry.day}',
                  style: const TextStyle(
                    color: Color(0xFF49372A),
                    fontSize: 14,
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
                  entry.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3E3026),
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.sourceId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9A856D),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${incoming ? '+' : ''}${_money(entry.amount)}원',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerEmptyPage extends StatelessWidget {
  const _LedgerEmptyPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 9),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEEE0C1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFB9935E)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF89663F), size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF49372A),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  color: Color(0xFF7D684F),
                  fontSize: 9,
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

class _NewsArchiveEntry extends StatelessWidget {
  const _NewsArchiveEntry({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final day = (item['day'] as num?)?.toInt() ?? 1;
    final archivedDate = DateTime.tryParse(item['date'] as String? ?? '');
    final date =
        archivedDate ?? DateTime(2000, 1, 1).add(Duration(days: day - 1));
    final headline = item['headline'] as String? ?? '제목 없는 신문';
    final eventCount = (item['eventIds'] as List?)?.length ?? 0;
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return Container(
      key: Key('news-archive-day-$day'),
      padding: const EdgeInsets.fromLTRB(11, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFCDB17A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEEE0C1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              children: [
                Text(
                  '${date.month}월',
                  style: const TextStyle(
                    color: Color(0xFF9B8261),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${date.day}일',
                  style: const TextStyle(
                    color: Color(0xFF49372A),
                    fontSize: 14,
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
                  headline,
                  style: const TextStyle(
                    color: Color(0xFF3E3026),
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateLabel · 역사 사건 $eventCount건',
                  style: const TextStyle(
                    color: Color(0xFF8C765F),
                    fontSize: 10,
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
}

class _LedgerFooterNote extends StatelessWidget {
  const _LedgerFooterNote();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0x2BFFFFFF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x4DFFDDA0)),
    ),
    child: const Row(
      children: [
        Icon(Icons.lock_outline_rounded, color: Color(0xFFFFD98B), size: 15),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            '실제 주문과 일거리 결과만 장부에 기록됩니다. 외화 자산은 환율 연결 전까지 원화 AUM에서 제외됩니다.',
            style: TextStyle(
              color: Color(0xFFE6D0B6),
              fontSize: 9,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _LedgerAppendix extends StatelessWidget {
  const _LedgerAppendix({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      key: const Key('ledger-daily-appendix'),
      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      collapsedBackgroundColor: const Color(0xFFEEE0C1),
      backgroundColor: const Color(0xFFEEE0C1),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: Color(0xFFB9935E)),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: Color(0xFFB9935E)),
      ),
      leading: const Icon(Icons.attach_file_rounded, color: Color(0xFF765339)),
      title: const Text(
        '부록 · 오늘의 운용 메모',
        style: TextStyle(
          color: Color(0xFF49372A),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: const Text(
        '가족 계좌 상태와 오늘의 신문 스크랩',
        style: TextStyle(
          color: Color(0xFF806C55),
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
      children: [
        _OfficeStatusCard(state: state),
        const SizedBox(height: 8),
        _TodayNewsCard(state: state),
      ],
    ),
  );
}

String _ledgerCurrencyAmount(int value, String currency) {
  final sign = value < 0 ? '-' : '';
  final amount = _money(value.abs());
  return switch (currency) {
    'USD' => '$sign\$$amount',
    'JPY' => '$sign¥$amount',
    _ => '$sign$amount원',
  };
}

class _MarketDataLoadError extends StatelessWidget {
  const _MarketDataLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _OutlinedCard(
    color: const Color(0xFFFFE7E2),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: _coral),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            '시장 시세를 불러오지 못했어요. 현금 원장은 그대로 확인할 수 있습니다.',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(
          key: const Key('retry-ledger-market-data'),
          onPressed: onRetry,
          child: const Text('재시도'),
        ),
      ],
    ),
  );
}
