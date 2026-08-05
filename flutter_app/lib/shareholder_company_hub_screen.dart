part of 'main.dart';

class ShareholderCompanyHubScreen extends StatefulWidget {
  const ShareholderCompanyHubScreen({
    super.key,
    required this.state,
    this.onSaveState,
    this.universe,
  });

  final GameState state;
  final Future<GameState> Function(GameState)? onSaveState;
  final FictionalMarketUniverse? universe;

  @override
  State<ShareholderCompanyHubScreen> createState() =>
      _ShareholderCompanyHubScreenState();
}

class _ShareholderCompanyHubScreenState
    extends State<ShareholderCompanyHubScreen> {
  static const _engine = ShareholderGovernanceEngine();

  late GameState _state = widget.state;
  FictionalMarketUniverse? _universe;
  Object? _loadError;
  bool _loading = true;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (mounted && (!_loading || _loadError != null)) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final universe =
          widget.universe ??
          await FictionalMarketUniverse.load(
            seed: _state.simulationSeed,
            throughDate: _state.currentDate,
          );
      var next = _engine.processDay(_state, universe);
      final save = widget.onSaveState;
      if (save != null) next = await save(next);
      if (!mounted) return;
      setState(() {
        _state = next;
        _universe = universe;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  void _close() {
    if (_allowPop) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(_state);
    });
  }

  FictionalMarketAsset? _assetFor(String assetId) {
    for (final asset in _universe?.assets ?? const <FictionalMarketAsset>[]) {
      if (asset.id == assetId) return asset;
    }
    return null;
  }

  int _marketCapFor(FictionalMarketAsset asset) {
    final quote = asset.quoteAtOrBefore(_state.currentDate);
    final rawPrice = quote?.close ?? asset.listingReferencePrice ?? 1;
    final price = _state.shareholderGovernance.adjustedPrice(
      asset.id,
      _state.day,
      rawPrice,
    );
    final shares =
        asset.sharesOutstandingAtOrBefore(_state.currentDate) ??
        asset.initialSharesOutstanding;
    return math.max(1, (price * shares).round());
  }

  Future<void> _openCompany(ListedCompanyGovernance company) async {
    final asset = _assetFor(company.assetId);
    if (asset == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('현재 회사 정보를 불러올 수 없습니다.')));
      return;
    }
    final updated = await Navigator.of(context).push<GameState>(
      MaterialPageRoute<GameState>(
        builder: (_) => ListedGovernanceScreen(
          state: _state,
          asset: asset,
          marketCap: _marketCapFor(asset),
          onSaveState: widget.onSaveState,
        ),
      ),
    );
    if (updated != null && mounted) setState(() => _state = updated);
  }

  List<ListedCompanyGovernance> get _companies {
    final rows = _state.shareholderGovernance.companies.values
        .where((company) => company.ownershipPct > 0)
        .toList(growable: false);
    return rows..sort((left, right) {
      final control = (right.isControlled ? 1 : 0).compareTo(
        left.isControlled ? 1 : 0,
      );
      if (control != 0) return control;
      final ownership = right.ownershipPct.compareTo(left.ownershipPct);
      if (ownership != 0) return ownership;
      return left.name.compareTo(right.name);
    });
  }

  List<ShareholderMeeting> get _upcomingMeetings {
    final ownedIds = _companies.map((company) => company.assetId).toSet();
    final rows = _state.shareholderGovernance.meetings
        .where(
          (meeting) =>
              ownedIds.contains(meeting.assetId) &&
              meeting.status != ShareholderMeetingStatus.closed,
        )
        .toList(growable: false);
    return rows..sort((left, right) => left.heldDay.compareTo(right.heldDay));
  }

  String _meetingStatus(ShareholderMeeting meeting) {
    final remaining = meeting.heldDay - _state.day;
    if (remaining > 0) {
      return meeting.status == ShareholderMeetingStatus.open
          ? '전자참석·사전의결 가능 · D-$remaining'
          : '개최 D-$remaining';
    }
    if (remaining == 0) return '오늘 개최';
    final deadlineRemaining = meeting.deadlineDay - _state.day;
    return deadlineRemaining >= 0 ? '의결 마감 D-$deadlineRemaining' : '마감';
  }

  String _companyMeetingName(ShareholderMeeting meeting) =>
      _state.shareholderGovernance.companyById(meeting.assetId)?.name ??
      meeting.assetId;

  @override
  Widget build(BuildContext context) {
    final companies = _companies;
    final meetings = _upcomingMeetings;
    final controlled = companies
        .where((company) => company.isControlled)
        .length;
    final ceoCount = companies.where((company) => company.playerIsCeo).length;
    final activeCorporateActions = _state.shareholderGovernance.corporateActions
        .where((action) => action.isExecuting)
        .length;
    final actionRequired = meetings
        .where(
          (meeting) =>
              meeting.status == ShareholderMeetingStatus.open &&
              (!meeting.attended || meeting.hasUnvotedAgenda),
        )
        .length;
    return PopScope<GameState>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        key: const Key('shareholder-company-hub-screen'),
        backgroundColor: const Color(0xFFF4F3F8),
        appBar: AppBar(
          leading: IconButton(
            key: const Key('close-shareholder-company-hub'),
            onPressed: _close,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: const Text('주주·회사관리'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Text(
                  _listedGovernanceDate(_state.currentDate),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? _ShareholderHubLoadError(onRetry: _load)
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                children: [
                  _ShareholderHubSummary(
                    companyCount: companies.length,
                    meetingCount: meetings.length,
                    controlledCount: controlled,
                    ceoCount: ceoCount,
                    actionRequiredCount: actionRequired,
                    activeCorporateActions: activeCorporateActions,
                  ),
                  const SizedBox(height: 18),
                  const _ShareholderHubSectionTitle(
                    icon: Icons.event_available_rounded,
                    title: '주주총회 일정',
                    subtitle: '정기주총은 회사별 날짜가 정해지며, 임시주총도 소집일정이 기록됩니다.',
                  ),
                  const SizedBox(height: 9),
                  if (meetings.isEmpty)
                    const _ShareholderHubEmpty(
                      key: Key('shareholder-hub-empty-meetings'),
                      message: '예정된 주주총회가 없습니다.',
                    )
                  else
                    for (final meeting in meetings) ...[
                      _ShareholderMeetingScheduleCard(
                        key: Key('shareholder-hub-meeting-${meeting.id}'),
                        companyName: _companyMeetingName(meeting),
                        meeting: meeting,
                        heldDate: _state.dateForDay(meeting.heldDay),
                        votingOpenDate: _state.dateForDay(
                          math.max(1, meeting.heldDay - 14),
                        ),
                        deadlineDate: _state.dateForDay(meeting.deadlineDay),
                        statusLabel: _meetingStatus(meeting),
                        onOpen: () {
                          final company = _state.shareholderGovernance
                              .companyById(meeting.assetId);
                          if (company != null) unawaited(_openCompany(company));
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 18),
                  const _ShareholderHubSectionTitle(
                    icon: Icons.apartment_rounded,
                    title: '보유·관리 회사',
                    subtitle: '지분권 행사부터 공개매수, CEO 취임, 업종별 경영과 합병까지 관리합니다.',
                  ),
                  const SizedBox(height: 9),
                  if (companies.isEmpty)
                    const _ShareholderHubEmpty(
                      key: Key('shareholder-hub-empty-companies'),
                      message: '주식을 보유하면 회사와 주주권이 여기에 등록됩니다.',
                    )
                  else
                    for (final company in companies) ...[
                      _ShareholderCompanyCard(
                        key: Key('shareholder-hub-company-${company.assetId}'),
                        company: company,
                        activeCorporateActions: _state.shareholderGovernance
                            .corporateActionsFor(company.assetId)
                            .where((action) => action.isExecuting)
                            .length,
                        onOpen: () => _openCompany(company),
                      ),
                      const SizedBox(height: 8),
                    ],
                ],
              ),
      ),
    );
  }
}

class _ShareholderHubSummary extends StatelessWidget {
  const _ShareholderHubSummary({
    required this.companyCount,
    required this.meetingCount,
    required this.controlledCount,
    required this.ceoCount,
    required this.actionRequiredCount,
    required this.activeCorporateActions,
  });

  final int companyCount;
  final int meetingCount;
  final int controlledCount;
  final int ceoCount;
  final int actionRequiredCount;
  final int activeCorporateActions;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('shareholder-hub-summary'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF34255D), Color(0xFF7253C7)],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x337253C7),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주주 비서실',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          actionRequiredCount > 0
              ? '확인할 주총·의결권 행사가 $actionRequiredCount건 있습니다.'
              : activeCorporateActions > 0
              ? '기업재편 $activeCorporateActions건이 실행 중입니다.'
              : '현재 놓친 주주행동이 없습니다.',
          style: const TextStyle(color: Color(0xFFEAE3FF), fontSize: 12),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _ShareholderHubMetric(label: '보유회사', value: '$companyCount'),
            _ShareholderHubMetric(label: '예정주총', value: '$meetingCount'),
            _ShareholderHubMetric(label: '경영회사', value: '$controlledCount'),
            _ShareholderHubMetric(label: 'CEO 재임', value: '$ceoCount'),
          ],
        ),
      ],
    ),
  );
}

class _ShareholderHubMetric extends StatelessWidget {
  const _ShareholderHubMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFDCD2FA), fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

class _ShareholderHubSectionTitle extends StatelessWidget {
  const _ShareholderHubSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFF7253C7), size: 22),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF71717B),
                fontSize: 10.5,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ShareholderMeetingScheduleCard extends StatelessWidget {
  const _ShareholderMeetingScheduleCard({
    super.key,
    required this.companyName,
    required this.meeting,
    required this.heldDate,
    required this.votingOpenDate,
    required this.deadlineDate,
    required this.statusLabel,
    required this.onOpen,
  });

  final String companyName;
  final ShareholderMeeting meeting;
  final DateTime heldDate;
  final DateTime votingOpenDate;
  final DateTime deadlineDate;
  final String statusLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: meeting.status == ShareholderMeetingStatus.open
            ? const Color(0xFFB9A5F4)
            : const Color(0xFFE2E0E8),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$companyName · ${meeting.extraordinary ? '임시' : '정기'}주총',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              statusLabel,
              style: const TextStyle(
                color: Color(0xFF7253C7),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          '개최 ${_listedGovernanceDate(heldDate)} · '
          '전자참석 ${_listedGovernanceDate(votingOpenDate)}~'
          '${_listedGovernanceDate(deadlineDate)}',
          style: const TextStyle(color: Color(0xFF66626F), fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          '안건 ${meeting.agendas.length}건 · '
          '${meeting.attended ? '참석 등록 완료' : '참석 미등록'} · '
          '${meeting.hasUnvotedAgenda ? '미의결 안건 있음' : '의결 완료'}',
          style: const TextStyle(color: Color(0xFF7A7582), fontSize: 10.5),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            key: Key('open-shareholder-meeting-${meeting.id}'),
            onPressed: onOpen,
            icon: const Icon(Icons.how_to_vote_rounded, size: 17),
            label: const Text('참석·의결 관리'),
          ),
        ),
      ],
    ),
  );
}

class _ShareholderCompanyCard extends StatelessWidget {
  const _ShareholderCompanyCard({
    super.key,
    required this.company,
    required this.activeCorporateActions,
    required this.onOpen,
  });

  final ListedCompanyGovernance company;
  final int activeCorporateActions;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final executing = company.managementDecisions
        .where((decision) => decision.isExecuting)
        .length;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E0E8)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: company.isControlled
                      ? const Color(0xFFE7DFFF)
                      : const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  company.isControlled
                      ? Icons.corporate_fare_rounded
                      : Icons.pie_chart_rounded,
                  color: company.isControlled
                      ? const Color(0xFF7253C7)
                      : const Color(0xFF356DB8),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${company.name} · ${company.controlTier.label}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${company.sector} · 지분 ${company.ownershipPct.toStringAsFixed(2)}% · '
                      '의결권 ${company.votingPowerPct.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        color: Color(0xFF6D6974),
                        fontSize: 10.5,
                      ),
                    ),
                    if (company.isControlled) ...[
                      const SizedBox(height: 3),
                      Text(
                        '이사회 ${company.boardSeats}석 · '
                        '${company.playerIsCeo ? '내가 CEO · ' : ''}'
                        '경영안 $executing건 · 기업재편 $activeCorporateActions건',
                        style: const TextStyle(
                          color: Color(0xFF7253C7),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8D8895)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareholderHubEmpty extends StatelessWidget {
  const _ShareholderHubEmpty({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E0E8)),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFF77717E)),
    ),
  );
}

class _ShareholderHubLoadError extends StatelessWidget {
  const _ShareholderHubLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 42),
          const SizedBox(height: 10),
          const Text('회사 정보를 불러오지 못했습니다.'),
          const SizedBox(height: 10),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    ),
  );
}
