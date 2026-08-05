part of 'main.dart';

class ListedGovernanceScreen extends StatefulWidget {
  const ListedGovernanceScreen({
    super.key,
    required this.state,
    required this.asset,
    required this.marketCap,
    this.onSaveState,
  });

  final GameState state;
  final FictionalMarketAsset asset;
  final int marketCap;
  final Future<GameState> Function(GameState)? onSaveState;

  @override
  State<ListedGovernanceScreen> createState() => _ListedGovernanceScreenState();
}

class _ListedGovernanceScreenState extends State<ListedGovernanceScreen> {
  static const _engine = ShareholderGovernanceEngine();
  late GameState _state;
  bool _working = false;
  bool _allowPop = false;

  ListedCompanyGovernance? get _company =>
      _state.shareholderGovernance.companyById(widget.asset.id);

  ShareholderMeeting? get _meeting {
    final rows =
        _state.shareholderGovernance
            .meetingsFor(widget.asset.id)
            .where((item) => item.status != ShareholderMeetingStatus.closed)
            .toList()
          ..sort((a, b) => a.heldDay.compareTo(b.heldDay));
    return rows.isEmpty ? null : rows.first;
  }

  @override
  void initState() {
    super.initState();
    _state = _engine.processDay(
      widget.state,
      FictionalMarketUniverse(
        schemaVersion: 14,
        sourceName: 'listed-governance',
        assets: <FictionalMarketAsset>[widget.asset],
      ),
    );
  }

  Future<void> _apply(ShareholderGovernanceActionResult result) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      var next = result.state;
      if (result.success && widget.onSaveState != null) {
        next = await widget.onSaveState!(next);
      }
      if (!mounted) return;
      setState(() => _state = next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success
              ? const Color(0xFF315E4B)
              : const Color(0xFF9A3844),
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _close() {
    if (_allowPop) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(_state);
    });
  }

  Future<void> _chooseProposal() async {
    final type = await showModalBottomSheet<ShareholderAgendaType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            const Text(
              '주주제안 안건',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            for (final type in <ShareholderAgendaType>[
              ShareholderAgendaType.dividend,
              ShareholderAgendaType.strategy,
              ShareholderAgendaType.labor,
              ShareholderAgendaType.audit,
              ShareholderAgendaType.executivePay,
              ShareholderAgendaType.capitalIncrease,
            ])
              ListTile(
                title: Text(type.label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, type),
              ),
          ],
        ),
      ),
    );
    if (type != null) {
      await _apply(
        _engine.submitProposal(_state, assetId: widget.asset.id, type: type),
      );
    }
  }

  Future<void> _tender(double target, int premiumBps) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공개매수 실행'),
        content: Text(
          '목표 $target% · 현재가 대비 ${(premiumBps / 100).round()}% '
          '프리미엄입니다. 실제 취득량은 응모 물량과 회사계좌 잔액에 따라 결정됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('실행'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await _apply(
        _engine.launchTenderOffer(
          _state,
          asset: widget.asset,
          targetOwnershipPct: target,
          premiumBps: premiumBps,
        ),
      );
    }
  }

  Future<void> _executeManagementOption(
    ListedManagementAgenda agenda,
    ListedManagementOption option,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(option.label),
        content: Text(
          '${option.description}\n\n'
          '자회사 투자금 ${_listedGovernanceWon(option.cashCost)} · '
          '기간 ${option.durationDays}일 · 성공확률 '
          '${option.successChancePct.toStringAsFixed(0)}%\n'
          '다음 거래일 예상반응 '
          '${option.immediatePriceImpactBps >= 0 ? '+' : ''}'
          '${(option.immediatePriceImpactBps / 100).toStringAsFixed(1)}%',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('다시 검토'),
          ),
          FilledButton(
            key: const Key('confirm-management-decision'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('이사회 의결'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await _apply(
        _engine.executeManagementDecision(
          _state,
          asset: widget.asset,
          optionId: option.id,
        ),
      );
    }
  }

  Future<void> _executeCeoDirective(ListedCeoDirective directive) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(directive.label),
        content: Text(
          '${directive.description}\n\nCEO 핵심 집행은 회사별 월 1회이며 비용·성과·실패가 회사 재무와 주가에 반영됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const Key('confirm-ceo-directive'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CEO 지시 집행'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await _apply(
        _engine.executeCeoDirective(
          _state,
          assetId: widget.asset.id,
          directive: directive,
        ),
      );
    }
  }

  Future<void> _choosePartnerCorporateAction(
    ListedCorporateActionType type,
  ) async {
    final candidates = _state.shareholderGovernance.controlledCompanies
        .where((company) => company.assetId != widget.asset.id)
        .toList(growable: false);
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('합병·합작 상대가 될 다른 지배회사가 없습니다.')),
      );
      return;
    }
    final selection = await showModalBottomSheet<_ListedCorporateSelection>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Text(
              '${type.label} 상대와 구조 선택',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final candidate in candidates)
              if (type == ListedCorporateActionType.merger)
                for (final structure in ListedMergerStructure.values)
                  ListTile(
                    key: Key(
                      'corporate-merger-${candidate.assetId}-${structure.name}',
                    ),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.merge_type_rounded),
                    title: Text('${candidate.name} · ${structure.label}'),
                    subtitle: Text(
                      '의결권 ${candidate.votingPowerPct.toStringAsFixed(2)}% · '
                      '${candidate.controlTier.label}',
                    ),
                    onTap: () => Navigator.pop(
                      context,
                      _ListedCorporateSelection(candidate.assetId, structure),
                    ),
                  )
              else
                ListTile(
                  key: Key('corporate-jv-${candidate.assetId}'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.handshake_rounded),
                  title: Text(candidate.name),
                  subtitle: Text(
                    '의결권 ${candidate.votingPowerPct.toStringAsFixed(2)}% · 공동출자',
                  ),
                  onTap: () => Navigator.pop(
                    context,
                    _ListedCorporateSelection(
                      candidate.assetId,
                      ListedMergerStructure.businessCombination,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
    if (selection == null) return;
    await _confirmCorporateAction(
      type,
      partnerAssetId: selection.partnerAssetId,
      structure: selection.structure,
    );
  }

  Future<void> _confirmCorporateAction(
    ListedCorporateActionType type, {
    String partnerAssetId = '',
    ListedMergerStructure structure = ListedMergerStructure.businessCombination,
  }) async {
    final partner = _state.shareholderGovernance.companyById(partnerAssetId);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${type.label} 추진'),
        content: Text(
          '${partner == null ? widget.asset.name : '${widget.asset.name}·${partner.name}'} '
          '${type == ListedCorporateActionType.merger ? structure.label : type.label} 안을 이사회와 주주총회 특별결의로 추진합니다.\n\n'
          '통합비용·신규차입·성공 또는 무산 결과가 양사 실적, CEO 평가와 주가에 반영됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const Key('confirm-corporate-action'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('특별결의 실행'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await _apply(
        _engine.startCorporateAction(
          _state,
          leadAssetId: widget.asset.id,
          type: type,
          partnerAssetId: partnerAssetId,
          mergerStructure: structure,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = _company;
    final rights = company?.rights ?? const <ShareholderRight>{};
    final meeting = _meeting;
    final owned = company?.ownershipPct ?? 0;
    return PopScope<GameState>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        key: const Key('listed-governance-screen'),
        backgroundColor: const Color(0xFFF5F3F8),
        appBar: AppBar(
          leading: IconButton(
            key: const Key('close-listed-governance'),
            onPressed: _close,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: Text('${widget.asset.name} 주주·경영관리'),
          actions: [
            if (_working)
              const Padding(
                padding: EdgeInsets.only(right: 18),
                child: Center(
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _ListedGovernancePanel(
              dark: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.asset.name} · ${widget.asset.symbol}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    company?.controlTier.label ?? '주식 미보유',
                    style: const TextStyle(
                      color: Color(0xFFD9D8F6),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _ListedGovernanceMetric(
                        label: '실소유',
                        value: '${owned.toStringAsFixed(2)}%',
                        light: true,
                      ),
                      _ListedGovernanceMetric(
                        label: '총 의결권',
                        value:
                            '${(company?.votingPowerPct ?? owned).toStringAsFixed(2)}%',
                        light: true,
                      ),
                      _ListedGovernanceMetric(
                        label: '이사회',
                        value: '${company?.boardSeats ?? 0}/7석',
                        light: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '회사계좌 ${_listedGovernanceWon(_state.bankCash)} · '
                    '우호지분 ${(company?.friendlyVotingPct ?? 0).toStringAsFixed(2)}%',
                    style: const TextStyle(
                      color: Color(0xFFBCBADF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _rightsPanel(owned),
            const SizedBox(height: 12),
            _meetingPanel(company, rights, meeting),
            const SizedBox(height: 12),
            _takeoverPanel(company, rights),
            if (company?.isControlled == true) ...[
              const SizedBox(height: 12),
              _ceoPanel(company!),
              const SizedBox(height: 12),
              _corporateStrategyPanel(company),
              const SizedBox(height: 12),
              _managementPanel(company),
              const SizedBox(height: 12),
              _subsidiaryPanel(company),
            ],
            const SizedBox(height: 12),
            _portfolioPanel(),
          ],
        ),
      ),
    );
  }

  Widget _rightsPanel(double owned) {
    const rows = <(double, String)>[
      (0.000001, '주주총회 참석·표결'),
      (1, '주주제안'),
      (3, '임시주총·이사 추천'),
      (5, '감사 요구'),
      (10, '이사회 참관·위임장 권유'),
      (20, '공개매수'),
      (33.34, '특별결의 저지'),
      (50.01, '경영권 확보·CEO 선임'),
      (66.67, '합병·분할·핵심자산 재편'),
      (99.99, '완전자회사·그룹 지배'),
    ];
    return _ListedGovernancePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ListedGovernanceTitle(Icons.verified_user_rounded, '지분별 주주권'),
          const SizedBox(height: 10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Icon(
                    owned >= row.$1
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: owned >= row.$1
                        ? const Color(0xFF347B59)
                        : const Color(0xFFAAA7B3),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 58,
                    child: Text(
                      row.$1 < 0.001 ? '1주+' : '${row.$1}%',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Expanded(child: Text(row.$2)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _meetingPanel(
    ListedCompanyGovernance? company,
    Set<ShareholderRight> rights,
    ShareholderMeeting? meeting,
  ) {
    final meetingActionable =
        meeting != null &&
        meeting.status != ShareholderMeetingStatus.closed &&
        _state.day >= meeting.heldDay - 14 &&
        _state.day <= meeting.deadlineDay;
    return _ListedGovernancePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ListedGovernanceTitle(Icons.how_to_vote_rounded, '주주총회'),
          const SizedBox(height: 10),
          if (meeting == null)
            const Text('예정된 주주총회가 없습니다.')
          else ...[
            Text(
              '${meeting.extraordinary ? '임시' : '정기'}주총 · '
              '${_listedGovernanceDate(_state.dateForDay(meeting.heldDay))}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '전자참석·사전의결 '
              '${_listedGovernanceDate(_state.dateForDay(math.max(1, meeting.heldDay - 14)))}'
              ' ~ ${_listedGovernanceDate(_state.dateForDay(meeting.deadlineDay))}',
              style: const TextStyle(color: Color(0xFF716B79), fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (!meeting.attended)
              FilledButton.icon(
                key: const Key('attend-shareholder-meeting'),
                onPressed: _working || !meetingActionable
                    ? null
                    : () => _apply(_engine.attendMeeting(_state, meeting.id)),
                icon: const Icon(Icons.login_rounded),
                label: Text(
                  _state.day < meeting.heldDay ? '전자참석 등록' : '주주총회 참석',
                ),
              )
            else
              for (final agenda in meeting.agendas)
                _ListedAgendaTile(
                  agenda: agenda,
                  enabled: !_working && agenda.vote == null,
                  onVote: (choice) => _apply(
                    _engine.vote(
                      _state,
                      meetingId: meeting.id,
                      agendaId: agenda.id,
                      choice: choice,
                    ),
                  ),
                ),
          ],
          const Divider(height: 26),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              OutlinedButton(
                key: const Key('ask-management-question'),
                onPressed:
                    !_working &&
                        rights.contains(ShareholderRight.submitQuestion)
                    ? () => _apply(
                        _engine.askManagementQuestion(_state, widget.asset.id),
                      )
                    : null,
                child: const Text('경영진 질의'),
              ),
              OutlinedButton(
                key: const Key('submit-shareholder-proposal'),
                onPressed:
                    !_working &&
                        rights.contains(ShareholderRight.submitProposal)
                    ? _chooseProposal
                    : null,
                child: const Text('주주제안'),
              ),
              OutlinedButton(
                key: const Key('nominate-shareholder-director'),
                onPressed:
                    !_working &&
                        rights.contains(ShareholderRight.nominateDirector)
                    ? () => _apply(
                        _engine.nominateDirector(_state, widget.asset.id),
                      )
                    : null,
                child: const Text('이사 추천'),
              ),
              OutlinedButton(
                key: const Key('request-shareholder-audit'),
                onPressed:
                    !_working && rights.contains(ShareholderRight.requestAudit)
                    ? () =>
                          _apply(_engine.requestAudit(_state, widget.asset.id))
                    : null,
                child: const Text('감사 요구'),
              ),
              OutlinedButton(
                key: const Key('publish-shareholder-letter'),
                onPressed:
                    !_working &&
                        rights.contains(
                          ShareholderRight.publishShareholderLetter,
                        )
                    ? () => _apply(
                        _engine.publishShareholderLetter(
                          _state,
                          assetId: widget.asset.id,
                          marketCap: widget.marketCap,
                        ),
                      )
                    : null,
                child: const Text('공개 주주서한'),
              ),
              OutlinedButton(
                key: const Key('call-extraordinary-meeting'),
                onPressed:
                    !_working &&
                        rights.contains(
                          ShareholderRight.callExtraordinaryMeeting,
                        )
                    ? () => _apply(
                        _engine.callExtraordinaryMeeting(
                          _state,
                          widget.asset.id,
                        ),
                      )
                    : null,
                child: const Text('임시주총'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _takeoverPanel(
    ListedCompanyGovernance? company,
    Set<ShareholderRight> rights,
  ) {
    return _ListedGovernancePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ListedGovernanceTitle(Icons.corporate_fare_rounded, '경영권 도전'),
          const SizedBox(height: 8),
          Text(
            company?.isControlled == true
                ? '의결권 과반을 확보했습니다. 자회사 경영 방침을 직접 정할 수 있습니다.'
                : '10%부터 우호 의결권, 20%부터 공개매수, 50.01%부터 경영권입니다.',
          ),
          const SizedBox(height: 10),
          Text(
            '시가총액 ${_listedGovernanceWon(widget.marketCap)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              OutlinedButton.icon(
                key: const Key('solicit-shareholder-proxies'),
                onPressed:
                    !_working &&
                        rights.contains(ShareholderRight.solicitProxies)
                    ? () => _apply(
                        _engine.solicitProxies(
                          _state,
                          assetId: widget.asset.id,
                          marketCap: widget.marketCap,
                        ),
                      )
                    : null,
                icon: const Icon(Icons.groups_rounded),
                label: const Text('우호지분'),
              ),
              FilledButton(
                key: const Key('launch-tender-offer-51'),
                onPressed:
                    !_working &&
                        rights.contains(ShareholderRight.launchTenderOffer)
                    ? () => _tender(51, 2500)
                    : null,
                child: const Text('51% 공개매수'),
              ),
              FilledButton.tonal(
                key: const Key('launch-tender-offer-67'),
                onPressed:
                    !_working &&
                        rights.contains(ShareholderRight.launchTenderOffer)
                    ? () => _tender(67, 4000)
                    : null,
                child: const Text('67% 안정지배'),
              ),
              OutlinedButton(
                key: const Key('launch-tender-offer-100'),
                onPressed:
                    !_working &&
                        rights.contains(ShareholderRight.launchTenderOffer)
                    ? () => _tender(100, 4000)
                    : null,
                child: const Text('100% 완전인수'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ceoPanel(ListedCompanyGovernance company) {
    final month = _listedGovernanceMonthKey(_state.currentDate);
    final actedThisMonth = company.lastCeoActionMonth == month;
    final tenureDays = company.ceoStartDay == null
        ? 0
        : math.max(1, _state.day - company.ceoStartDay! + 1);
    return _ListedGovernancePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ListedGovernanceTitle(Icons.badge_rounded, 'CEO 집무실'),
          const SizedBox(height: 8),
          if (!company.playerIsCeo) ...[
            const Text(
              '경영권과 이사회 과반을 확보했습니다. 직접 대표이사 CEO가 되거나 전문경영인에게 맡길 수 있습니다.',
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('appoint-player-ceo'),
              onPressed: _working
                  ? null
                  : () => _apply(
                      _engine.appointPlayerAsCeo(_state, widget.asset.id),
                    ),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('내가 CEO로 취임'),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE8FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '플레이어 대표이사 CEO · 재임 $tenureDays일 · 경영평가 ${company.ceoPerformance}/100\n'
                '${actedThisMonth ? '이번 달 핵심 집행 완료' : '이번 달 핵심 집행을 선택할 수 있습니다.'}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '월간 CEO 집행',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final directive in ListedCeoDirective.values)
                  OutlinedButton(
                    key: Key('ceo-directive-${directive.name}'),
                    onPressed: _working || actedThisMonth
                        ? null
                        : () => _executeCeoDirective(directive),
                    child: Text(directive.label),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const Key('step-down-player-ceo'),
              onPressed: _working
                  ? null
                  : () =>
                        _apply(_engine.stepDownAsCeo(_state, widget.asset.id)),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('CEO 사임·전문경영인 선임'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _corporateStrategyPanel(ListedCompanyGovernance company) {
    final actions = _state.shareholderGovernance
        .corporateActionsFor(widget.asset.id)
        .reversed
        .take(4)
        .toList(growable: false);
    final controlledPartners = _state.shareholderGovernance.controlledCompanies
        .where((item) => item.assetId != widget.asset.id)
        .toList(growable: false);
    final mergerPartners = controlledPartners
        .where(
          (item) =>
              item.rights.contains(ShareholderRight.approveMajorRestructuring),
        )
        .toList(growable: false);
    final canSpecial = company.rights.contains(
      ShareholderRight.approveMajorRestructuring,
    );
    final hasActive = actions.any((action) => action.isExecuting);
    return _ListedGovernancePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ListedGovernanceTitle(
            Icons.account_tree_rounded,
            '그룹 전략·기업재편',
          ),
          const SizedBox(height: 8),
          Text(
            canSpecial
                ? '특별결의 지배력을 확보했습니다. 합병·분할·자산 재편을 CEO 책임 아래 추진할 수 있습니다.'
                : '합작법인은 CEO 취임 후, 합병·분할·핵심자산 매각은 의결권 66.67%부터 가능합니다.',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              FilledButton.icon(
                key: const Key('start-listed-merger'),
                onPressed:
                    _working ||
                        hasActive ||
                        !company.playerIsCeo ||
                        !canSpecial ||
                        mergerPartners.isEmpty
                    ? null
                    : () => _choosePartnerCorporateAction(
                        ListedCorporateActionType.merger,
                      ),
                icon: const Icon(Icons.merge_rounded),
                label: const Text('합병 추진'),
              ),
              OutlinedButton.icon(
                key: const Key('start-listed-joint-venture'),
                onPressed:
                    _working ||
                        hasActive ||
                        !company.playerIsCeo ||
                        controlledPartners.isEmpty
                    ? null
                    : () => _choosePartnerCorporateAction(
                        ListedCorporateActionType.jointVenture,
                      ),
                icon: const Icon(Icons.handshake_rounded),
                label: const Text('합작법인'),
              ),
              OutlinedButton(
                key: const Key('start-listed-spin-off'),
                onPressed:
                    _working || hasActive || !company.playerIsCeo || !canSpecial
                    ? null
                    : () => _confirmCorporateAction(
                        ListedCorporateActionType.spinOff,
                      ),
                child: const Text('사업분할'),
              ),
              OutlinedButton(
                key: const Key('start-listed-asset-sale'),
                onPressed:
                    _working || hasActive || !company.playerIsCeo || !canSpecial
                    ? null
                    : () => _confirmCorporateAction(
                        ListedCorporateActionType.assetSale,
                      ),
                child: const Text('핵심자산 매각'),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const Divider(height: 26),
            const Text(
              '기업재편 진행·성과',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            for (final action in actions)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  action.isExecuting
                      ? Icons.sync_rounded
                      : action.status == ListedCorporateActionStatus.succeeded
                      ? Icons.check_circle_rounded
                      : action.status == ListedCorporateActionStatus.failed
                      ? Icons.error_rounded
                      : Icons.change_circle_rounded,
                  color: action.isExecuting
                      ? const Color(0xFF7253C7)
                      : action.status == ListedCorporateActionStatus.succeeded
                      ? const Color(0xFF347B59)
                      : const Color(0xFF9A3844),
                ),
                title: Text(
                  '${action.type.label} · ${action.strategy}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  action.isExecuting
                      ? '${math.max(0, action.completionDay - _state.day)}일 뒤 통합 결과'
                      : action.outcome,
                ),
                trailing: Text(action.status.label),
              ),
          ],
        ],
      ),
    );
  }

  Widget _subsidiaryPanel(ListedCompanyGovernance company) {
    return _ListedGovernancePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ListedGovernanceTitle(Icons.business_center_rounded, '자회사 경영'),
          const SizedBox(height: 10),
          Row(
            children: [
              _ListedGovernanceMetric(
                label: '월 매출',
                value: _listedGovernanceWon(company.monthlyRevenue),
              ),
              _ListedGovernanceMetric(
                label: '월 영업비용',
                value: _listedGovernanceWon(company.monthlyExpense),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ListedGovernanceMetric(
                label: '자회사 현금',
                value: _listedGovernanceWon(company.subsidiaryCash),
              ),
              _ListedGovernanceMetric(
                label: '부채',
                value: _listedGovernanceWon(company.subsidiaryDebt),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('운영 방침', style: TextStyle(fontWeight: FontWeight.w900)),
          Wrap(
            spacing: 6,
            children: [
              for (final policy in SubsidiaryOperatingPolicy.values)
                ChoiceChip(
                  label: Text(policy.label),
                  selected: policy == company.operatingPolicy,
                  onSelected: _working
                      ? null
                      : (_) => _apply(
                          _engine.setOperatingPolicy(
                            _state,
                            assetId: widget.asset.id,
                            policy: policy,
                          ),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('대표 체제', style: TextStyle(fontWeight: FontWeight.w900)),
          Wrap(
            spacing: 6,
            children: [
              for (final model in SubsidiaryLeadershipModel.values)
                ChoiceChip(
                  label: Text(model.label),
                  selected: model == company.leadershipModel,
                  onSelected:
                      _working ||
                          company.playerIsCeo ||
                          model == SubsidiaryLeadershipModel.founderLed
                      ? null
                      : (_) => _apply(
                          _engine.appointLeadership(
                            _state,
                            assetId: widget.asset.id,
                            leadership: model,
                          ),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '누적 배당 ${_listedGovernanceWon(company.cumulativeDistribution)} · '
            '유보이익 ${_listedGovernanceWon(company.retainedEarnings)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _managementPanel(ListedCompanyGovernance company) {
    final agenda = _engine.managementAgendaFor(_state, widget.asset);
    if (agenda == null) return const SizedBox.shrink();
    final decided = company.lastManagementQuarter == agenda.quarterKey;
    final decisions = company.managementDecisions.reversed.take(4).toList();
    final marketEvaluation = (company.priceMultiplierAt(_state.day) - 1) * 100;
    return _ListedGovernancePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ListedGovernanceTitle(
            Icons.dashboard_customize_rounded,
            '${agenda.quarterKey} ${widget.asset.sector} 이사회',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final product in widget.asset.products.take(4))
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(product),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            agenda.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(agenda.question),
          if (agenda.context.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              agenda.context,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF66626E), fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ListedManagementKpi(
                  label: '기술·상품',
                  value: company.innovation,
                  color: const Color(0xFF7253C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ListedManagementKpi(
                  label: '운영',
                  value: company.operations,
                  color: const Color(0xFF287A67),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ListedManagementKpi(
                  label: '고객신뢰',
                  value: company.brandTrust,
                  color: const Color(0xFFB56B28),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ListedManagementKpi(
                  label: '조직',
                  value: company.workforce,
                  color: const Color(0xFF347B59),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: marketEvaluation >= 0
                  ? const Color(0xFFE7F4EC)
                  : const Color(0xFFFFECEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '내 경영결정의 누적 시장평가 '
              '${marketEvaluation >= 0 ? '+' : ''}'
              '${marketEvaluation.toStringAsFixed(1)}% · '
              '선택과 실행 결과가 매매가격·차트·보유자산 평가에 반영됩니다.',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          if (decided)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDF8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '이번 분기 핵심안건은 결정됐습니다. 진행 결과를 기다리거나 다음 분기 안건을 준비하세요.',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          else
            for (var index = 0; index < agenda.options.length; index++)
              _ListedManagementOptionCard(
                option: agenda.options[index],
                index: index,
                enabled: !_working,
                onPressed: () =>
                    _executeManagementOption(agenda, agenda.options[index]),
              ),
          if (decisions.isNotEmpty) ...[
            const Divider(height: 28),
            const Text(
              '경영 공시·실행 기록',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            for (final decision in decisions)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  decision.isExecuting
                      ? Icons.pending_actions_rounded
                      : decision.status ==
                            ListedManagementDecisionStatus.succeeded
                      ? Icons.trending_up_rounded
                      : decision.status == ListedManagementDecisionStatus.failed
                      ? Icons.trending_down_rounded
                      : Icons.swap_vert_rounded,
                  color: decision.isExecuting
                      ? const Color(0xFF7253C7)
                      : decision.realizedPriceImpactBps >= 0
                      ? const Color(0xFF347B59)
                      : const Color(0xFF9A3844),
                ),
                title: Text(
                  '${decision.title} · ${decision.optionLabel}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  decision.isExecuting
                      ? '${decision.completionDay - _state.day}일 뒤 결과 발표'
                      : '${decision.status.label} · ${decision.outcome}',
                ),
                trailing: Text(
                  decision.isExecuting
                      ? '${decision.successChancePct.toStringAsFixed(0)}%'
                      : '${decision.realizedPriceImpactBps >= 0 ? '+' : ''}'
                            '${(decision.realizedPriceImpactBps / 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _portfolioPanel() {
    final companies =
        _state.shareholderGovernance.companies.values
            .where((item) => item.ownershipPct > 0)
            .toList()
          ..sort((a, b) => b.votingPowerPct.compareTo(a.votingPowerPct));
    return _ListedGovernancePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ListedGovernanceTitle(
            Icons.account_tree_rounded,
            '지분 포트폴리오 · 지배회사 '
            '${companies.where((item) => item.isControlled).length}개',
          ),
          for (final company in companies)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                company.isControlled
                    ? Icons.domain_verification_rounded
                    : Icons.pie_chart_rounded,
                color: const Color(0xFF7253C7),
              ),
              title: Text(
                company.name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(company.controlTier.label),
              trailing: Text('${company.ownershipPct.toStringAsFixed(2)}%'),
            ),
        ],
      ),
    );
  }
}

class _ListedCorporateSelection {
  const _ListedCorporateSelection(this.partnerAssetId, this.structure);

  final String partnerAssetId;
  final ListedMergerStructure structure;
}

class _ListedManagementKpi extends StatelessWidget {
  const _ListedManagementKpi({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
          Text(
            '$value',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
      const SizedBox(height: 3),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          minHeight: 7,
          value: value / 100,
          color: color,
          backgroundColor: const Color(0xFFE8E5EC),
        ),
      ),
    ],
  );
}

class _ListedManagementOptionCard extends StatelessWidget {
  const _ListedManagementOptionCard({
    required this.option,
    required this.index,
    required this.enabled,
    required this.onPressed,
  });

  final ListedManagementOption option;
  final int index;
  final bool enabled;
  final VoidCallback onPressed;

  String _signedPercent(int bps) =>
      '${bps >= 0 ? '+' : ''}${(bps / 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F7FA),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE4E0E9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                option.label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: index == 0
                    ? const Color(0xFFFFE8E4)
                    : index == 1
                    ? const Color(0xFFE9F0FF)
                    : const Color(0xFFE7F4EC),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                option.riskLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(option.description, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            Text(
              '투자 ${_listedGovernanceWon(option.cashCost)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            Text(
              '${option.durationDays}일 · 성공 ${option.successChancePct.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            Text(
              '공시 ${_signedPercent(option.immediatePriceImpactBps)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            Text(
              '결과 ${_signedPercent(option.successPriceImpactBps)} / '
              '${_signedPercent(option.failurePriceImpactBps)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: Key('management-option-${option.id}'),
            onPressed: enabled ? onPressed : null,
            child: const Text('이 안으로 경영'),
          ),
        ),
      ],
    ),
  );
}

class _ListedAgendaTile extends StatelessWidget {
  const _ListedAgendaTile({
    required this.agenda,
    required this.enabled,
    required this.onVote,
  });

  final ShareholderAgenda agenda;
  final bool enabled;
  final ValueChanged<ShareholderVoteChoice> onVote;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 9),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F6FA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(agenda.title, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(agenda.description, style: const TextStyle(fontSize: 12)),
        if (agenda.vote == null)
          Row(
            children: [
              for (final choice in ShareholderVoteChoice.values)
                Expanded(
                  child: TextButton(
                    onPressed: enabled ? () => onVote(choice) : null,
                    child: Text(choice.label),
                  ),
                ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${agenda.vote!.label} · ${agenda.passed == true ? '가결' : '부결'} · '
              '찬성 ${(agenda.finalSupportPct ?? 0).toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
      ],
    ),
  );
}

class _ListedGovernancePanel extends StatelessWidget {
  const _ListedGovernancePanel({required this.child, this.dark = false});

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF2F315B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: dark ? const Color(0xFF2F315B) : const Color(0xFFE3DFE8),
      ),
    ),
    child: child,
  );
}

class _ListedGovernanceTitle extends StatelessWidget {
  const _ListedGovernanceTitle(this.icon, this.title);

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFF7253C7), size: 20),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ),
    ],
  );
}

class _ListedGovernanceMetric extends StatelessWidget {
  const _ListedGovernanceMetric({
    required this.label,
    required this.value,
    this.light = false,
  });

  final String label;
  final String value;
  final bool light;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: light ? const Color(0xFFBCBADF) : const Color(0xFF77727F),
            fontSize: 11,
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: light ? Colors.white : const Color(0xFF282532),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

String _listedGovernanceDate(DateTime date) =>
    '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

String _listedGovernanceMonthKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

String _listedGovernanceWon(int value) => '${_listedGovernanceNumber(value)}원';

String _listedGovernanceNumber(num value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index += 1) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return '${value < 0 ? '-' : ''}$buffer';
}
