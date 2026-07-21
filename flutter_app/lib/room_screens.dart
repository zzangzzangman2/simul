part of 'main.dart';

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
  });

  final GameState state;
  final Future<void> Function(String decisionId, String optionId)
  onResolveDecision;

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
                  location: '내 방 · 책상 위 편지',
                  caption: pending.isEmpty
                      ? '지금 도착한 안건은 없다.'
                      : '가족에게 설명할 안건을 하나씩 검토한다.',
                  minute: state.marketMinute,
                  costLabel: '${pending.length}건 대기',
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
                    child: pending.isEmpty
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
                                '안건 편지함',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 14),
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
  const PortfolioLedgerScreen({super.key, required this.state, this.universe});

  final GameState state;
  final HistoricalMarketUniverse? universe;

  @override
  State<PortfolioLedgerScreen> createState() => _PortfolioLedgerScreenState();
}

class _PortfolioLedgerScreenState extends State<PortfolioLedgerScreen> {
  late Future<HistoricalMarketUniverse> _universeFuture;

  GameState get state => widget.state;

  @override
  void initState() {
    super.initState();
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
    backgroundColor: const Color(0xFF292431),
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/bg_boy_room_1999.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
          ),
        ),
        const Positioned.fill(child: ColoredBox(color: Color(0xA6101118))),
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
                    color: const Color(0xFFFFFCF3),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFD7C8A7),
                      width: 2,
                    ),
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
                        for (final position in state.positions) {
                          final asset = assets[position.assetId];
                          if (asset == null || asset.currency != 'KRW') {
                            continue;
                          }
                          final price = _portfolioPriceAtCurrentTime(
                            asset,
                            state,
                          );
                          if (price != null) prices[position.assetId] = price;
                        }
                        final portfolioValue = state.portfolioValue(prices);
                        final aum = state.totalAum(prices);
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                          children: [
                            Text(
                              state.companyName,
                              key: const Key('ledger-company-name'),
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
                              '서류함 · 포트폴리오',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (snapshot.hasError) ...[
                              _MarketDataLoadError(onRetry: _retryMarketData),
                              const SizedBox(height: 10),
                            ],
                            _OfficeStatusCard(state: state),
                            const SizedBox(height: 10),
                            _TodayNewsCard(state: state),
                            const SizedBox(height: 16),
                            _OutlinedCard(
                              color: const Color(0xFFEFF6FF),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _StatusValue(
                                      label: '현금',
                                      value: '${_money(state.cash)}원',
                                    ),
                                  ),
                                  Expanded(
                                    child: _StatusValue(
                                      label: '원화 주식',
                                      value: snapshot.hasError
                                          ? '불러오기 실패'
                                          : snapshot.hasData
                                          ? '${_money(portfolioValue)}원'
                                          : '계산 중',
                                    ),
                                  ),
                                  Expanded(
                                    child: _StatusValue(
                                      label: '원화 AUM',
                                      value: snapshot.hasError
                                          ? '불러오기 실패'
                                          : snapshot.hasData
                                          ? '${_money(aum)}원'
                                          : '계산 중',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '보유 종목',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (state.positions.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text('아직 보유한 주식이 없어요.'),
                              )
                            else
                              ...state.positions.map((position) {
                                final asset = assets[position.assetId];
                                final price = prices[position.assetId];
                                final isForeign = position.currency != 'KRW';
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
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(asset?.name ?? position.name),
                                  subtitle: Text(
                                    '$units주 · 평균 ${_money(position.averageCost.round())}원'
                                    '${returnRate == null ? '' : ' · ${returnRate >= 0 ? '+' : ''}${returnRate.toStringAsFixed(2)}%'}',
                                  ),
                                  trailing: Text(
                                    isForeign
                                        ? '환율 연결 대기'
                                        : snapshot.hasError
                                        ? '시세 불러오기 실패'
                                        : value == null
                                        ? '시세 없음'
                                        : '${_money(value)}원',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                );
                              }),
                            const Divider(height: 28),
                            const Text(
                              '현금 원장',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (state.ledger.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text('아직 기록된 거래가 없어요.'),
                              )
                            else
                              ...state.ledger.reversed
                                  .take(20)
                                  .map(
                                    (entry) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(entry.description),
                                      subtitle: Text(
                                        'DAY ${entry.day} · ${entry.sourceId}',
                                      ),
                                      trailing: Text(
                                        '${entry.amount > 0 ? '+' : ''}${_money(entry.amount)}원',
                                      ),
                                    ),
                                  ),
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
