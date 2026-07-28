part of 'main.dart';

typedef BusinessAcquireCallback =
    Future<FinanceActionResult> Function({
      required String listingId,
      required String businessName,
      required String locationId,
      required BusinessPremiseMode premiseMode,
      String? linkedRealEstateId,
      required BusinessOperatingPolicy policy,
    });

typedef BusinessPolicyUpdateCallback =
    Future<FinanceActionResult> Function(
      String businessId,
      BusinessOperatingPolicy policy,
    );

typedef BusinessInvestmentCallback =
    Future<FinanceActionResult> Function(
      String businessId,
      BusinessInvestmentKind kind,
    );

typedef BusinessCloseCallback =
    Future<FinanceActionResult> Function(String businessId);

typedef BusinessEventChoiceCallback =
    Future<FinanceActionResult> Function(String eventId, String choiceId);

class BusinessManagementScreen extends StatefulWidget {
  const BusinessManagementScreen({
    super.key,
    required this.state,
    required this.onAcquire,
    required this.onUpdatePolicy,
    required this.onInvest,
    required this.onClose,
    required this.onChooseEvent,
    this.initialLinkedRealEstateId,
  });

  final GameState state;
  final BusinessAcquireCallback onAcquire;
  final BusinessPolicyUpdateCallback onUpdatePolicy;
  final BusinessInvestmentCallback onInvest;
  final BusinessCloseCallback onClose;
  final BusinessEventChoiceCallback onChooseEvent;
  final String? initialLinkedRealEstateId;

  @override
  State<BusinessManagementScreen> createState() =>
      _BusinessManagementScreenState();
}

class _BusinessManagementScreenState extends State<BusinessManagementScreen> {
  late GameState _state = widget.state;
  late final List<BusinessListing> _listings = generateBusinessListings(
    worldSeed: widget.state.simulationSeed,
    asOfDate: widget.state.currentDate,
    generatorVersion: businessWorldGeneratorVersion,
  );
  final Map<String, BusinessOperatingPolicy> _policyDrafts =
      <String, BusinessOperatingPolicy>{};
  BusinessIndustry? _industryFilter;
  String? _listingDistrictFilter;
  bool _busy = false;

  List<OwnedRealEstate> get _eligibleOwnedProperties {
    final portfolio = _state.businesses;
    return _state.personalFinance.realEstate
        .where((property) {
          final commercial =
              property.assetType == RealEstateAssetType.commercialUnit ||
              property.assetType == RealEstateAssetType.officeBuilding;
          return commercial &&
              property.marketAsset != null &&
              !property.hasActiveLease &&
              !property.isDirectUse &&
              property.saleListedDay <= 0 &&
              !portfolio.usesRealEstate(property.id);
        })
        .toList(growable: false);
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String actionLabel,
    bool destructive = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF9E403A),
                    )
                  : null,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(actionLabel),
            ),
          ],
        ),
      ) ??
      false;

  Future<FinanceActionResult?> _runAction(
    Future<FinanceActionResult> Function() action, {
    String? confirmationTitle,
    String? confirmationBody,
    String confirmationLabel = '확인',
    bool destructive = false,
  }) async {
    if (_busy) return null;
    if (confirmationTitle != null &&
        confirmationBody != null &&
        !await _confirm(
          title: confirmationTitle,
          body: confirmationBody,
          actionLabel: confirmationLabel,
          destructive: destructive,
        )) {
      return null;
    }
    if (!mounted) return null;
    setState(() => _busy = true);
    try {
      final result = await action();
      if (!mounted) return result;
      if (result.success) {
        setState(() => _state = result.state);
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
      return result;
    } catch (_) {
      if (mounted) _showSaveFailure(context);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openListing(BusinessListing listing) async {
    final locationIds = businessLocationCatalog
        .map((location) => location.id)
        .toList(growable: false);
    final ownedPropertiesForDistrict = _eligibleOwnedProperties
        .where((property) {
          if (listing.districtId.isEmpty) return false;
          final asset = property.marketAsset;
          if (asset == null) return false;
          return businessDistrictIdForRealEstateRegion(
                asset.region,
                province: asset.province,
              ) ==
              listing.districtId;
        })
        .toList(growable: false);
    final result = await Navigator.of(context).push<FinanceActionResult>(
      MaterialPageRoute<FinanceActionResult>(
        builder: (routeContext) => _BusinessListingReviewScreen(
          state: _state,
          listing: listing,
          availableLocationIds: locationIds,
          eligibleOwnedProperties: ownedPropertiesForDistrict,
          initialLinkedRealEstateId: widget.initialLinkedRealEstateId,
          onAcquire: widget.onAcquire,
        ),
      ),
    );
    if (!mounted || result == null) return;
    if (result.success) setState(() => _state = result.state);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _savePolicy(OwnedBusiness business) async {
    final policy = _policyDrafts[business.id] ?? business.policy;
    final result = await _runAction(
      () => widget.onUpdatePolicy(business.id, policy),
      confirmationTitle: '${business.name} 운영계획 변경',
      confirmationBody:
          '가격·품질·인력·홍보·영업시간·설비관리의 새 계획을 적용합니다. '
          '높은 단계는 매출 기회를 늘릴 수 있지만 비용과 피로도도 함께 커집니다.',
      confirmationLabel: '계획 적용',
    );
    if (result?.success ?? false) {
      final refreshed = result!.state.businesses.businessById(business.id);
      if (refreshed != null) _policyDrafts[business.id] = refreshed.policy;
    }
  }

  Future<void> _invest(
    OwnedBusiness business,
    BusinessInvestmentKind kind,
  ) async {
    final plan = businessInvestmentPlanFor(business, kind);
    await _runAction(
      () => widget.onInvest(business.id, kind),
      confirmationTitle: '${business.name} · ${kind.label}',
      confirmationBody:
          '${plan.description}\n\n'
          '필요 현금 ${_money(plan.cost)}원\n'
          '설비 ${_signedScore(plan.conditionDelta)} · '
          '평판 ${_signedScore(plan.reputationDelta)} · '
          '직원 사기 ${_signedScore(plan.staffMoraleDelta)} · '
          '위험 ${_signedScore(plan.riskDelta)}\n\n'
          '회사의 통장 현금만 사용하며, 저장에 성공한 뒤 점포 상태에 반영됩니다.',
      confirmationLabel: '투자 실행',
    );
  }

  Future<void> _close(OwnedBusiness business) async {
    await _runAction(
      () => widget.onClose(business.id),
      confirmationTitle: '${business.name} 폐업',
      confirmationBody:
          '영업을 종료하고 보증금·설비 잔존가·미지급금을 정산합니다. '
          '결과는 되돌릴 수 없고 보유 상가를 사용 중이면 해당 연결도 해제됩니다.',
      confirmationLabel: '폐업 확정',
      destructive: true,
    );
  }

  Future<void> _chooseEvent(
    BusinessEventInstance event,
    BusinessEventChoice choice,
  ) async {
    await _runAction(
      () => widget.onChooseEvent(event.id, choice.id),
      confirmationTitle: event.title,
      confirmationBody:
          '${choice.label}\n\n${choice.description}\n\n'
          '${choice.upfrontCost > 0 ? '즉시 비용 ${_money(choice.upfrontCost)}원\n' : ''}'
          '결과는 바로 공개되지 않으며 예정일이 지나야 확정됩니다.',
      confirmationLabel: '대응 선택',
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    child: Scaffold(
      key: const Key('business-management-screen'),
      backgroundColor: const Color(0xFFF4EEE4),
      appBar: AppBar(
        title: const Text('동네사업 관리'),
        backgroundColor: const Color(0xFFF4EEE4),
        bottom: const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelPadding: EdgeInsets.symmetric(horizontal: 13),
          tabs: [
            Tab(
              key: Key('business-tab-listings'),
              text: '인수·창업',
              icon: Icon(Icons.storefront_rounded, size: 18),
            ),
            Tab(
              key: Key('business-tab-owned'),
              text: '내 점포',
              icon: Icon(Icons.badge_outlined, size: 18),
            ),
            Tab(
              key: Key('business-tab-events'),
              text: '사건함',
              icon: Icon(Icons.mark_email_unread_outlined, size: 18),
            ),
            Tab(
              key: Key('business-tab-statements'),
              text: '월별 손익',
              icon: Icon(Icons.receipt_long_outlined, size: 18),
            ),
            Tab(
              key: Key('business-tab-districts'),
              text: '상권판세',
              icon: Icon(Icons.location_city_rounded, size: 18),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          children: [
            _buildListingTab(),
            _buildOwnedTab(),
            _buildEventTab(),
            _buildStatementTab(),
            _BusinessDistrictBoard(state: _state),
          ],
        ),
      ),
    ),
  );

  Widget _buildListingTab() {
    final listedDistrictIds = _listings
        .map((listing) => listing.districtId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final listedDistricts = businessDistrictCatalog
        .where((district) => listedDistrictIds.contains(district.id))
        .toList(growable: false);
    final filtered = _listings
        .where(
          (listing) =>
              (_industryFilter == null ||
                  listing.industry == _industryFilter) &&
              (_listingDistrictFilter == null ||
                  listing.districtId == _listingDistrictFilter),
        )
        .toList(growable: false);
    return ListView(
      key: const Key('business-listings-panel'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
      children: [
        _BusinessSummaryCard(
          cash: _state.bankCash,
          activeStores: _state.businesses.activeBusinesses.length,
          pendingEvents: _state.businesses.pendingEvents
              .where(
                (event) => event.status == BusinessEventStatus.pendingChoice,
              )
              .length,
          totalProfit: _state.businesses.totalProfit,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _businessCardDecoration(),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '클릭 한 번으로 사지 않습니다',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                '매물을 열어 손익과 위험을 검토한 뒤 이름·입지·사업장·6축 운영계획을 '
                '직접 정하고 마지막 확인까지 해야 인수됩니다.',
                style: TextStyle(fontSize: 10.5, height: 1.45),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _BusinessFeatureChip(label: 'PC방'),
                  _BusinessFeatureChip(label: '노래방'),
                  _BusinessFeatureChip(label: '카페·식당'),
                  _BusinessFeatureChip(label: '생활 서비스'),
                ],
              ),
            ],
          ),
        ),
        if (listedDistricts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _businessCardDecoration(),
            child: DropdownButtonFormField<String>(
              key: const Key('business-listing-district-filter'),
              initialValue: _listingDistrictFilter ?? '',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '도시·상권 매물',
                helperText: '상권판세를 확인한 뒤 원하는 지역의 매물만 모아 봅니다.',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('모든 도시·상권'),
                ),
                ...listedDistricts.map(
                  (district) => DropdownMenuItem<String>(
                    value: district.id,
                    child: Text(
                      '${district.city} · ${district.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(
                () => _listingDistrictFilter = value == null || value.isEmpty
                    ? null
                    : value,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 37,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  key: const Key('business-industry-all'),
                  label: const Text('전체'),
                  selected: _industryFilter == null,
                  onSelected: (_) => setState(() => _industryFilter = null),
                ),
              ),
              ...BusinessIndustry.values.map(
                (industry) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: Key('business-industry-${industry.name}'),
                    label: Text(industry.label),
                    selected: _industryFilter == industry,
                    onSelected: (_) =>
                        setState(() => _industryFilter = industry),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const _BusinessEmptyCard(
            icon: Icons.search_off_rounded,
            title: '조건에 맞는 점포가 없습니다',
            body: '다른 업종을 선택하거나 다음 달 새 매물을 기다려 보세요.',
          )
        else
          ...filtered.map(
            (listing) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _BusinessListingCard(
                listing: listing,
                busy: _busy,
                onOpen: () => _openListing(listing),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOwnedTab() {
    final businesses = _state.businesses.businesses;
    return ListView(
      key: const Key('business-owned-panel'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
      children: [
        _BusinessSectionHeader(
          icon: Icons.store_mall_directory_outlined,
          title: '내 점포 ${businesses.length}곳',
          caption:
              '영업 ${_state.businesses.activeBusinesses.length}곳 · '
              '미지급금 ${_money(_state.businesses.totalAccountsPayable)}원',
        ),
        const SizedBox(height: 10),
        if (businesses.isEmpty)
          const _BusinessEmptyCard(
            icon: Icons.storefront_outlined,
            title: '아직 운영하는 점포가 없습니다',
            body: '인수·창업 탭에서 매물을 검토하고 첫 점포의 운영계획을 세워 보세요.',
          )
        else
          ...businesses.map(
            (business) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildOwnedBusinessCard(business),
            ),
          ),
      ],
    );
  }

  Widget _buildOwnedBusinessCard(OwnedBusiness business) {
    final draft = _policyDrafts.putIfAbsent(business.id, () => business.policy);
    final latest = business.statements.isEmpty
        ? null
        : business.statements.last;
    return Container(
      key: Key('business-owned-${business.id}'),
      decoration: _businessCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          leading: CircleAvatar(
            backgroundColor: _businessIndustryColor(
              business.industry,
            ).withValues(alpha: 0.14),
            foregroundColor: _businessIndustryColor(business.industry),
            child: Icon(_businessIndustryIcon(business.industry), size: 21),
          ),
          title: Text(
            business.name,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            '${_businessDistrictLabel(business.districtId)} · '
            '${business.industry.label} · ${_businessLocationLabel(business.locationId)}\n'
            '${business.status.label} · '
            '${latest == null ? '첫 월 정산 전' : '최근 손익 ${_signedMoney(latest.netProfit)}원'}',
            style: const TextStyle(fontSize: 10.5, height: 1.35),
          ),
          trailing: _BusinessStatusBadge(status: business.status),
          children: [
            _BusinessMetricGrid(
              items: [
                _BusinessMetric('평판', '${business.reputation}/100'),
                _BusinessMetric('단골', '${business.customerLoyalty}/100'),
                _BusinessMetric('설비', '${business.equipmentCondition}/100'),
                _BusinessMetric('직원 사기', '${business.staffMorale}/100'),
                _BusinessMetric('위험', '${business.riskLevel}/100'),
                _BusinessMetric(
                  '누적 손익',
                  '${_signedMoney(business.totalProfit)}원',
                ),
              ],
            ),
            if (business.accountsPayable > 0) ...[
              const SizedBox(height: 8),
              _BusinessWarning(
                text:
                    '미지급금 ${_money(business.accountsPayable)}원 · '
                    '연속 미납 ${business.missedPaymentMonths}개월',
              ),
            ],
            const SizedBox(height: 14),
            const _BusinessSubheading(
              icon: Icons.tune_rounded,
              title: '6축 운영계획',
            ),
            const SizedBox(height: 6),
            _BusinessPolicyEditor(
              keyPrefix: 'business-policy-${business.id}',
              policy: draft,
              enabled: business.isActive && !_busy,
              onChanged: (next) =>
                  setState(() => _policyDrafts[business.id] = next),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: Key('business-policy-save-${business.id}'),
                onPressed: business.isActive && !_busy
                    ? () => _savePolicy(business)
                    : null,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('운영계획 저장'),
              ),
            ),
            const SizedBox(height: 14),
            const _BusinessSubheading(
              icon: Icons.build_circle_outlined,
              title: '점포 투자',
            ),
            const SizedBox(height: 7),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BusinessInvestmentKind.values
                      .map((kind) {
                        final plan = businessInvestmentPlanFor(business, kind);
                        return SizedBox(
                          width: width,
                          child: OutlinedButton(
                            key: Key(
                              'business-invest-${business.id}-${kind.name}',
                            ),
                            onPressed: business.isActive && !_busy
                                ? () => _invest(business, kind)
                                : null,
                            child: Text(
                              '${kind.label}\n${_money(plan.cost)}원',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: Key('business-close-${business.id}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF9E403A),
                ),
                onPressed: business.isActive && !_busy
                    ? () => _close(business)
                    : null,
                icon: const Icon(Icons.store_mall_directory_outlined, size: 18),
                label: Text(
                  business.isActive ? '폐업 및 정산' : business.status.label,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTab() {
    final pending = _state.businesses.pendingEvents;
    final history = _state.businesses.eventHistory.reversed
        .take(40)
        .toList(growable: false);
    return ListView(
      key: const Key('business-events-panel'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
      children: [
        _BusinessSectionHeader(
          icon: Icons.campaign_outlined,
          title: '점포 사건',
          caption:
              '선택 대기 ${pending.where((event) => event.status == BusinessEventStatus.pendingChoice).length}건 · '
              '결과 대기 ${pending.where((event) => event.status == BusinessEventStatus.awaitingOutcome).length}건',
        ),
        const SizedBox(height: 10),
        if (pending.isEmpty)
          const _BusinessEmptyCard(
            icon: Icons.mark_email_read_outlined,
            title: '지금 대응할 사건이 없습니다',
            body: '업종·입지·설비 상태와 운영계획에 따라 서로 다른 사건이 발생합니다.',
          )
        else
          ...pending.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BusinessEventCard(
                event: event,
                businessName:
                    _state.businesses.businessById(event.businessId)?.name ??
                    '알 수 없는 점포',
                busy: _busy,
                onChoose: (choice) => _chooseEvent(event, choice),
              ),
            ),
          ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 8),
          const _BusinessSectionHeader(
            icon: Icons.history_rounded,
            title: '지난 결과',
            caption: '확정된 결과만 표시하며 대기 중 결과는 미리 보여주지 않습니다.',
          ),
          const SizedBox(height: 8),
          ...history.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _BusinessEventHistoryCard(
                event: event,
                businessName:
                    _state.businesses.businessById(event.businessId)?.name ??
                    '과거 점포',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatementTab() {
    final entries =
        <_BusinessStatementEntry>[
          for (final business in _state.businesses.businesses)
            for (final statement in business.statements)
              _BusinessStatementEntry(business: business, statement: statement),
        ]..sort((a, b) {
          final year = b.statement.year.compareTo(a.statement.year);
          return year != 0
              ? year
              : b.statement.month.compareTo(a.statement.month);
        });
    return ListView(
      key: const Key('business-statements-panel'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
      children: [
        _BusinessSectionHeader(
          icon: Icons.analytics_outlined,
          title: '월별 손익',
          caption:
              '누적 매출 ${_money(_state.businesses.totalSales)}원 · '
              '누적 손익 ${_signedMoney(_state.businesses.totalProfit)}원',
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          const _BusinessEmptyCard(
            icon: Icons.receipt_long_outlined,
            title: '아직 월 정산표가 없습니다',
            body: '첫 점포를 연 뒤 월말이 지나면 매출과 비용이 항목별로 기록됩니다.',
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _BusinessStatementCard(entry: entry),
            ),
          ),
      ],
    );
  }
}

class _BusinessListingReviewScreen extends StatefulWidget {
  const _BusinessListingReviewScreen({
    required this.state,
    required this.listing,
    required this.availableLocationIds,
    required this.eligibleOwnedProperties,
    required this.initialLinkedRealEstateId,
    required this.onAcquire,
  });

  final GameState state;
  final BusinessListing listing;
  final List<String> availableLocationIds;
  final List<OwnedRealEstate> eligibleOwnedProperties;
  final String? initialLinkedRealEstateId;
  final BusinessAcquireCallback onAcquire;

  @override
  State<_BusinessListingReviewScreen> createState() =>
      _BusinessListingReviewScreenState();
}

class _BusinessListingReviewScreenState
    extends State<_BusinessListingReviewScreen> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.listing.title,
  );
  late String _locationId = widget.listing.locationId;
  late BusinessPremiseMode _premiseMode = _validInitialPropertyId == null
      ? BusinessPremiseMode.leased
      : BusinessPremiseMode.ownedProperty;
  late String? _linkedRealEstateId = _validInitialPropertyId;
  BusinessOperatingPolicy _policy = BusinessOperatingPolicy.neutral;
  bool _busy = false;

  String? get _validInitialPropertyId {
    final initial = widget.initialLinkedRealEstateId;
    if (initial == null) return null;
    return widget.eligibleOwnedProperties.any(
          (property) => property.id == initial,
        )
        ? initial
        : null;
  }

  @override
  void initState() {
    super.initState();
    if (_premiseMode == BusinessPremiseMode.ownedProperty &&
        _linkedRealEstateId == null &&
        widget.eligibleOwnedProperties.isNotEmpty) {
      _linkedRealEstateId = widget.eligibleOwnedProperties.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('점포 이름을 2자 이상 입력하세요.')));
      return;
    }
    if (_premiseMode == BusinessPremiseMode.ownedProperty &&
        _linkedRealEstateId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('사용할 보유 상가를 선택하세요.')));
      return;
    }
    final property = _selectedProperty;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('최종 인수·창업 확인'),
            content: SingleChildScrollView(
              child: Text(
                '$name · ${widget.listing.industry.label}\n'
                '지역 ${_businessDistrictLabel(widget.listing.districtId)}\n'
                '상권 유형 ${_businessLocationLabel(_locationId)}\n'
                '사업장 ${_premiseMode == BusinessPremiseMode.leased ? '임차' : property?.name ?? '보유 상가'}\n'
                '예상 초기현금 ${_money(_effectiveInitialCash)}원\n\n'
                '가격·품질·인력·홍보·영업시간·설비관리 계획을 모두 확인했습니다. '
                '사업은 매달 적자가 날 수 있고 미지급금이 누적되면 폐업할 수 있습니다.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('다시 검토'),
              ),
              FilledButton(
                key: const Key('business-acquire-submit'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('인수·창업 확정'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await widget.onAcquire(
        listingId: widget.listing.id,
        businessName: name,
        locationId: _locationId,
        premiseMode: _premiseMode,
        linkedRealEstateId: _premiseMode == BusinessPremiseMode.ownedProperty
            ? _linkedRealEstateId
            : null,
        policy: _policy,
      );
      if (!mounted) return;
      if (result.success) {
        Navigator.of(context).pop(result);
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    } catch (_) {
      if (mounted) _showSaveFailure(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  OwnedRealEstate? get _selectedProperty {
    final id = _linkedRealEstateId;
    if (id == null) return null;
    for (final property in widget.eligibleOwnedProperties) {
      if (property.id == id) return property;
    }
    return null;
  }

  int get _effectiveInitialCash =>
      widget.listing.askingPrice +
      (_premiseMode == BusinessPremiseMode.leased
          ? repriceBusinessListingForLocation(
              listing: widget.listing,
              locationId: _locationId,
            ).leaseDeposit
          : 0);

  @override
  Widget build(BuildContext context) {
    final listing = repriceBusinessListingForLocation(
      listing: widget.listing,
      locationId: _locationId,
    );
    final canChooseLocation =
        listing.mode == BusinessListingMode.startup &&
        widget.availableLocationIds.length > 1;
    final hasEnoughCash = widget.state.bankCash >= _effectiveInitialCash;
    return Scaffold(
      key: const Key('business-listing-review'),
      backgroundColor: const Color(0xFFF4EEE4),
      appBar: AppBar(
        title: const Text('사업 검토서'),
        backgroundColor: const Color(0xFFF4EEE4),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _businessCardDecoration(
                borderColor: _businessIndustryColor(listing.industry),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _businessIndustryColor(
                          listing.industry,
                        ).withValues(alpha: 0.15),
                        foregroundColor: _businessIndustryColor(
                          listing.industry,
                        ),
                        child: Icon(_businessIndustryIcon(listing.industry)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              '${_businessDistrictLabel(listing.districtId)} · '
                              '${listing.mode.label} · ${listing.industry.label} · '
                              '${_businessLocationLabel(listing.locationId)}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BusinessMetricGrid(
                    items: [
                      _BusinessMetric(
                        '초기 필요현금',
                        '${_money(listing.totalInitialCashRequired)}원',
                      ),
                      _BusinessMetric(
                        '과거 월매출 추정',
                        '${_money(listing.priorMonthlySalesEstimate)}원',
                      ),
                      _BusinessMetric('시설 상태', '${listing.condition}/100'),
                      _BusinessMetric('기존 평판', '${listing.reputation}/100'),
                      _BusinessMetric('직원', '${listing.employeeCount}명'),
                      _BusinessMetric('수용 규모', '${listing.capacity}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _BusinessCostLine(
                    label: '권리금·인수가',
                    value: listing.askingPrice,
                  ),
                  _BusinessCostLine(
                    label: '임차보증금',
                    value: listing.leaseDeposit,
                  ),
                  _BusinessCostLine(label: '월 임차료', value: listing.monthlyRent),
                  _BusinessCostLine(
                    label: '설비 장부가',
                    value: listing.equipmentBookValue,
                  ),
                  if (listing.riskSignals.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const _BusinessSubheading(
                      icon: Icons.warning_amber_rounded,
                      title: '검토할 위험',
                    ),
                    const SizedBox(height: 5),
                    ...listing.riskSignals.map(
                      (risk) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '• $risk',
                          style: const TextStyle(
                            color: Color(0xFF8C493F),
                            fontSize: 10.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (listing.districtId.isNotEmpty) ...[
              const SizedBox(height: 12),
              _BusinessListingDistrictFitCard(
                state: widget.state,
                listing: listing,
              ),
            ],
            const SizedBox(height: 12),
            _BusinessStepCard(
              number: 1,
              title: '점포 이름',
              child: TextField(
                key: const Key('business-name-input'),
                controller: _nameController,
                maxLength: 24,
                decoration: const InputDecoration(
                  labelText: '운영할 이름',
                  helperText: '저장된 회사 이름과 별개의 점포 상호입니다.',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _BusinessStepCard(
              number: 2,
              title: '상권 유형 확인',
              child: DropdownButtonFormField<String>(
                key: const Key('business-location-select'),
                initialValue: _locationId,
                isExpanded: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  helperText: canChooseLocation
                      ? '신규 창업은 입지를 바꿔 수요와 비용을 비교할 수 있습니다.'
                      : '기존 점포 인수는 현재 입지를 승계합니다.',
                ),
                items: widget.availableLocationIds
                    .map(
                      (id) => DropdownMenuItem<String>(
                        value: id,
                        child: Text(_businessLocationLabel(id)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: canChooseLocation
                    ? (value) {
                        if (value != null) setState(() => _locationId = value);
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            _BusinessStepCard(
              number: 3,
              title: '사업장 방식',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      ChoiceChip(
                        key: const Key('business-premise-leased'),
                        label: const Text('임차해서 운영'),
                        selected: _premiseMode == BusinessPremiseMode.leased,
                        onSelected: _busy
                            ? null
                            : (_) => setState(
                                () => _premiseMode = BusinessPremiseMode.leased,
                              ),
                      ),
                      ChoiceChip(
                        key: const Key('business-premise-owned'),
                        label: const Text('보유 상가에서 운영'),
                        selected:
                            _premiseMode == BusinessPremiseMode.ownedProperty,
                        onSelected:
                            _busy || widget.eligibleOwnedProperties.isEmpty
                            ? null
                            : (_) => setState(() {
                                _premiseMode =
                                    BusinessPremiseMode.ownedProperty;
                                _linkedRealEstateId ??=
                                    widget.eligibleOwnedProperties.first.id;
                              }),
                      ),
                    ],
                  ),
                  if (widget.eligibleOwnedProperties.isEmpty) ...[
                    const SizedBox(height: 6),
                    const Text(
                      '임대 중이거나 매각 등록된 곳을 제외한 보유 상가가 없습니다.',
                      style: TextStyle(color: Color(0xFF8B5546), fontSize: 10),
                    ),
                  ],
                  if (_premiseMode == BusinessPremiseMode.ownedProperty) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: const Key('business-owned-property-select'),
                      initialValue: _linkedRealEstateId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '직접 사용할 보유 상가',
                        helperText: '사업 중에는 임대하거나 매각할 수 없습니다.',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.eligibleOwnedProperties
                          .map(
                            (property) => DropdownMenuItem<String>(
                              value: property.id,
                              child: Text(
                                '${property.name} · ${property.assetType.label}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _busy
                          ? null
                          : (value) =>
                                setState(() => _linkedRealEstateId = value),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            _BusinessStepCard(
              number: 4,
              title: '6축 운영계획',
              child: _BusinessPolicyEditor(
                keyPrefix: 'business-plan',
                policy: _policy,
                enabled: !_busy,
                onChanged: (next) => setState(() => _policy = next),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD9AA4E)),
              ),
              child: const Text(
                '매출은 보장되지 않습니다. 업종·입지·가격·직원·설비·사건이 함께 작동하며, '
                '운전자금이 부족하면 미지급금과 경영난이 누적되어 실제로 폐업할 수 있습니다.',
                style: TextStyle(fontSize: 10.5, height: 1.45),
              ),
            ),
            if (!hasEnoughCash) ...[
              const SizedBox(height: 8),
              _BusinessWarning(
                text:
                    '회사 통장 현금이 예상 초기현금보다 부족합니다. '
                    '주식 예수금은 사업 인수에 사용할 수 없습니다.',
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                key: const Key('business-acquire-confirm'),
                onPressed: _busy || !hasEnoughCash ? null : _submit,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fact_check_outlined),
                label: Text(
                  _busy
                      ? '저장 중'
                      : hasEnoughCash
                      ? '최종 내용 확인'
                      : '초기현금 부족',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessListingCard extends StatelessWidget {
  const _BusinessListingCard({
    required this.listing,
    required this.busy,
    required this.onOpen,
  });

  final BusinessListing listing;
  final bool busy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      key: Key('business-listing-${listing.id}'),
      onTap: busy ? null : onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: _businessCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _businessIndustryColor(
                      listing.industry,
                    ).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _businessIndustryIcon(listing.industry),
                    color: _businessIndustryColor(listing.industry),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_businessDistrictLabel(listing.districtId)} · '
                        '${listing.industry.label} · ${listing.mode.label} · '
                        '${_businessLocationLabel(listing.locationId)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9.8),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _BusinessListingValue(
                    label: '초기현금',
                    value: '${_money(listing.totalInitialCashRequired)}원',
                  ),
                ),
                Expanded(
                  child: _BusinessListingValue(
                    label: '기존 월매출 추정',
                    value: '${_money(listing.priorMonthlySalesEstimate)}원',
                  ),
                ),
                Expanded(
                  child: _BusinessListingValue(
                    label: '시설·평판',
                    value: '${listing.condition} · ${listing.reputation}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              listing.riskSignals.isEmpty
                  ? '확인된 큰 위험 신호 없음 · 상세 검토 필요'
                  : '위험 신호 ${listing.riskSignals.length}개 · '
                        '${listing.riskSignals.first}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: listing.riskSignals.isEmpty
                    ? const Color(0xFF55705C)
                    : const Color(0xFF985148),
                fontSize: 9.8,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '상세 검토',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BusinessEventCard extends StatelessWidget {
  const _BusinessEventCard({
    required this.event,
    required this.businessName,
    required this.busy,
    required this.onChoose,
  });

  final BusinessEventInstance event;
  final String businessName;
  final bool busy;
  final ValueChanged<BusinessEventChoice> onChoose;

  @override
  Widget build(BuildContext context) {
    final awaiting = event.status == BusinessEventStatus.awaitingOutcome;
    return Container(
      key: Key('business-event-${event.id}'),
      padding: const EdgeInsets.all(13),
      decoration: _businessCardDecoration(
        borderColor: awaiting
            ? const Color(0xFF5E78A0)
            : const Color(0xFFD3913E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              _BusinessEventStatusBadge(status: event.status),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '$businessName · 발생 ${_shortIsoDate(event.occurredDateIso)}',
            style: const TextStyle(color: Color(0xFF776B60), fontSize: 9.8),
          ),
          const SizedBox(height: 8),
          Text(
            event.body,
            style: const TextStyle(fontSize: 10.8, height: 1.45),
          ),
          if (event.status == BusinessEventStatus.pendingChoice) ...[
            const SizedBox(height: 10),
            ...event.choices.map(
              (choice) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: OutlinedButton(
                  key: Key('business-event-choice-${event.id}-${choice.id}'),
                  onPressed: busy ? null : () => onChoose(choice),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(11),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice.label,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${choice.description}'
                        '${choice.upfrontCost > 0 ? '\n즉시 비용 ${_money(choice.upfrontCost)}원' : ''}',
                        style: const TextStyle(fontSize: 9.8, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              '선택 기한 ${_shortIsoDate(event.choiceDueDateIso)}',
              style: const TextStyle(
                color: Color(0xFF985148),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else if (awaiting) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '선택: ${event.selectedChoice?.label ?? '대응 완료'}\n'
                '결과 예정 ${_shortIsoDate(event.resolutionDateIso)} · '
                '성공 여부와 손익은 예정일 전에는 공개되지 않습니다.',
                style: const TextStyle(fontSize: 10, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BusinessEventHistoryCard extends StatelessWidget {
  const _BusinessEventHistoryCard({
    required this.event,
    required this.businessName,
  });

  final BusinessEventInstance event;
  final String businessName;

  @override
  Widget build(BuildContext context) {
    final color = switch (event.outcome) {
      BusinessEventOutcome.success => const Color(0xFF3F765A),
      BusinessEventOutcome.partial => const Color(0xFF96712E),
      BusinessEventOutcome.failure => const Color(0xFF9E4943),
      null => const Color(0xFF6B7079),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _businessCardDecoration(borderColor: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.outcomeTitle.isEmpty ? event.title : event.outcomeTitle,
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            '$businessName · ${_shortIsoDate(event.resolutionDateIso)}',
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF776B60)),
          ),
          const SizedBox(height: 6),
          Text(
            event.outcomeBody.isEmpty ? event.body : event.outcomeBody,
            style: const TextStyle(fontSize: 10.5, height: 1.4),
          ),
          if (event.realizedCashDelta != 0) ...[
            const SizedBox(height: 5),
            Text(
              '확정 현금 영향 ${_signedMoney(event.realizedCashDelta)}원',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BusinessStatementCard extends StatelessWidget {
  const _BusinessStatementCard({required this.entry});

  final _BusinessStatementEntry entry;

  @override
  Widget build(BuildContext context) {
    final statement = entry.statement;
    final positive = statement.netProfit >= 0;
    return Container(
      key: Key(
        'business-statement-${entry.business.id}-'
        '${statement.year}-${statement.month}',
      ),
      decoration: _businessCardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 13),
          title: Text(
            '${statement.year}년 ${statement.month}월 · ${entry.business.name}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          subtitle: Text(
            '매출 ${_money(statement.grossSales)}원 · '
            '비용 ${_money(statement.totalOperatingCosts)}원',
            style: const TextStyle(fontSize: 9.8),
          ),
          trailing: Text(
            '${_signedMoney(statement.netProfit)}원',
            style: TextStyle(
              color: positive
                  ? const Color(0xFF39735A)
                  : const Color(0xFFA04440),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          children: [
            _BusinessMetricGrid(
              items: [
                _BusinessMetric('영업일', '${statement.operatingDays}일'),
                _BusinessMetric('고객', '${statement.customerCount}명'),
                _BusinessMetric(
                  '영업이익률',
                  '${(statement.operatingMargin * 100).toStringAsFixed(1)}%',
                ),
                _BusinessMetric(
                  '월 순손익',
                  '${_signedMoney(statement.netProfit)}원',
                ),
              ],
            ),
            const SizedBox(height: 10),
            _BusinessStatementLine(label: '매출', value: statement.grossSales),
            const Divider(height: 14),
            _BusinessStatementLine(
              label: '재료·상품 원가',
              value: -statement.variableCosts,
            ),
            _BusinessStatementLine(label: '급여', value: -statement.payroll),
            _BusinessStatementLine(label: '임차료', value: -statement.rent),
            _BusinessStatementLine(label: '공과금', value: -statement.utilities),
            _BusinessStatementLine(label: '광고비', value: -statement.marketing),
            _BusinessStatementLine(label: '정비비', value: -statement.maintenance),
            _BusinessStatementLine(
              label: '사건 비용',
              value: -statement.eventCosts,
            ),
            _BusinessStatementLine(label: '세금', value: -statement.taxes),
            const Divider(height: 14),
            _BusinessStatementLine(
              label: '순손익',
              value: statement.netProfit,
              strong: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessPolicyEditor extends StatelessWidget {
  const _BusinessPolicyEditor({
    required this.keyPrefix,
    required this.policy,
    required this.enabled,
    required this.onChanged,
  });

  final String keyPrefix;
  final BusinessOperatingPolicy policy;
  final bool enabled;
  final ValueChanged<BusinessOperatingPolicy> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: BusinessPolicyAxis.values
        .map((axis) {
          final value = policy.valueFor(axis);
          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 7, 5, 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5EF),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFE2D7C8)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          axis.label,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        _businessPolicyLevelLabel(axis, value),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6E6258),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    key: Key('$keyPrefix-${axis.name}'),
                    value: value.toDouble(),
                    min: 0,
                    max: 4,
                    divisions: 4,
                    label: _businessPolicyLevelLabel(axis, value),
                    onChanged: enabled
                        ? (next) =>
                              onChanged(policy.withAxis(axis, next.round()))
                        : null,
                  ),
                ],
              ),
            ),
          );
        })
        .toList(growable: false),
  );
}

class _BusinessSummaryCard extends StatelessWidget {
  const _BusinessSummaryCard({
    required this.cash,
    required this.activeStores,
    required this.pendingEvents,
    required this.totalProfit,
  });

  final int cash;
  final int activeStores;
  final int pendingEvents;
  final int totalProfit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF273D5D), Color(0xFF355C6B)],
      ),
      borderRadius: BorderRadius.circular(17),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '사업 운전자금',
          style: TextStyle(
            color: Color(0xFFD7E8E4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_money(cash)}원',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 21,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BusinessSummaryValue(
                label: '영업 점포',
                value: '$activeStores곳',
              ),
            ),
            Expanded(
              child: _BusinessSummaryValue(
                label: '선택 대기',
                value: '$pendingEvents건',
              ),
            ),
            Expanded(
              child: _BusinessSummaryValue(
                label: '누적 손익',
                value: '${_signedMoney(totalProfit)}원',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _BusinessSummaryValue extends StatelessWidget {
  const _BusinessSummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xFFBFD3D0), fontSize: 8.5),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
        ),
      ),
    ],
  );
}

class _BusinessMetric {
  const _BusinessMetric(this.label, this.value);

  final String label;
  final String value;
}

class _BusinessMetricGrid extends StatelessWidget {
  const _BusinessMetricGrid({required this.items});

  final List<_BusinessMetric> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 7) / 2;
      return Wrap(
        spacing: 7,
        runSpacing: 7,
        children: items
            .map(
              (item) => Container(
                width: width,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EEE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Color(0xFF756A60),
                        fontSize: 8.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      );
    },
  );
}

class _BusinessSectionHeader extends StatelessWidget {
  const _BusinessSectionHeader({
    required this.icon,
    required this.title,
    required this.caption,
  });

  final IconData icon;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E8DF),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: const Color(0xFF456453), size: 20),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            Text(
              caption,
              style: const TextStyle(
                color: Color(0xFF756A60),
                fontSize: 9.5,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _BusinessStepCard extends StatelessWidget {
  const _BusinessStepCard({
    required this.number,
    required this.title,
    required this.child,
  });

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: _businessCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFF365E68),
              foregroundColor: Colors.white,
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _BusinessSubheading extends StatelessWidget {
  const _BusinessSubheading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: const Color(0xFF49665A)),
      const SizedBox(width: 6),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
    ],
  );
}

class _BusinessFeatureChip extends StatelessWidget {
  const _BusinessFeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFE5EEE8),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
    ),
  );
}

class _BusinessListingValue extends StatelessWidget {
  const _BusinessListingValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xFF7A6F64), fontSize: 8),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 9.5),
      ),
    ],
  );
}

class _BusinessStatusBadge extends StatelessWidget {
  const _BusinessStatusBadge({required this.status});

  final BusinessStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BusinessStatus.operating => const Color(0xFF3F765A),
      BusinessStatus.struggling => const Color(0xFFB06B35),
      BusinessStatus.suspended => const Color(0xFF756B60),
      BusinessStatus.closed || BusinessStatus.sold => const Color(0xFF9E4943),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BusinessEventStatusBadge extends StatelessWidget {
  const _BusinessEventStatusBadge({required this.status});

  final BusinessEventStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      BusinessEventStatus.pendingChoice => ('선택 필요', const Color(0xFFB36C2E)),
      BusinessEventStatus.awaitingOutcome => ('결과 대기', const Color(0xFF506F9A)),
      BusinessEventStatus.resolved => ('해결', const Color(0xFF3F765A)),
      BusinessEventStatus.expired => ('기한 만료', const Color(0xFF965049)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BusinessEmptyCard extends StatelessWidget {
  const _BusinessEmptyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _businessCardDecoration(),
    child: Column(
      children: [
        Icon(icon, size: 34, color: const Color(0xFF829186)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF756A60),
            fontSize: 10,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _BusinessWarning extends StatelessWidget {
  const _BusinessWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE3DD),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE1A39A)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8C4039),
        fontSize: 9.8,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _BusinessCostLine extends StatelessWidget {
  const _BusinessCostLine({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF74695F), fontSize: 10),
          ),
        ),
        Text(
          '${_money(value)}원',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _BusinessStatementLine extends StatelessWidget {
  const _BusinessStatementLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final int value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${_signedMoney(value)}원',
          style: TextStyle(
            fontSize: 10,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            color: value < 0
                ? const Color(0xFFA04440)
                : const Color(0xFF39735A),
          ),
        ),
      ],
    ),
  );
}

class _BusinessStatementEntry {
  const _BusinessStatementEntry({
    required this.business,
    required this.statement,
  });

  final OwnedBusiness business;
  final BusinessMonthlyStatement statement;
}

BoxDecoration _businessCardDecoration({Color? borderColor}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: borderColor ?? const Color(0xFFDCCFC0)),
  boxShadow: const [
    BoxShadow(color: Color(0x10000000), blurRadius: 5, offset: Offset(0, 2)),
  ],
);

String _signedMoney(int value) =>
    value > 0 ? '+${_money(value)}' : _money(value);

String _shortIsoDate(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.'
      '${date.day.toString().padLeft(2, '0')}';
}

String _businessLocationLabel(String id) {
  final profile = businessLocationProfileById(id);
  if (profile != null) return profile.label;
  const labels = <String, String>{
    'residential': '주택가 생활권',
    'station': '역세권',
    'university': '대학가',
    'office': '오피스 상권',
    'academy': '학원가',
    'nightlife': '야간 상권',
    'suburban': '외곽 생활권',
    'new_town': '신도시',
  };
  return labels[id] ??
      id
          .split('_')
          .where((part) => part.isNotEmpty)
          .map(
            (part) => part.length == 1
                ? part.toUpperCase()
                : '${part[0].toUpperCase()}${part.substring(1)}',
          )
          .join(' ');
}

String _businessPolicyLevelLabel(BusinessPolicyAxis axis, int value) {
  const generic = <String>['최소', '절약', '균형', '강화', '최대'];
  const pricing = <String>['초저가', '할인', '표준', '프리미엄', '고가'];
  const hours = <String>['단축', '짧게', '표준', '연장', '심야 포함'];
  final index = value.clamp(0, 4).toInt();
  return switch (axis) {
    BusinessPolicyAxis.pricing => pricing[index],
    BusinessPolicyAxis.openingHours => hours[index],
    _ => generic[index],
  };
}

String _signedScore(int value) => value > 0 ? '+$value' : '$value';

IconData _businessIndustryIcon(BusinessIndustry industry) => switch (industry) {
  BusinessIndustry.pcBang => Icons.computer_rounded,
  BusinessIndustry.karaoke => Icons.mic_rounded,
  BusinessIndustry.cafe ||
  BusinessIndustry.boardGameCafe ||
  BusinessIndustry.studyCafe => Icons.local_cafe_rounded,
  BusinessIndustry.bakery => Icons.bakery_dining_rounded,
  BusinessIndustry.koreanRestaurant ||
  BusinessIndustry.fastFood ||
  BusinessIndustry.deliveryKitchen => Icons.restaurant_rounded,
  BusinessIndustry.convenienceStore => Icons.local_convenience_store_rounded,
  BusinessIndustry.fitnessCenter => Icons.fitness_center_rounded,
  BusinessIndustry.coinLaundry => Icons.local_laundry_service_rounded,
  BusinessIndustry.hairSalon ||
  BusinessIndustry.nailSalon => Icons.content_cut_rounded,
  BusinessIndustry.arcade => Icons.sports_esports_rounded,
  BusinessIndustry.petGrooming => Icons.pets_rounded,
  BusinessIndustry.photographyStudio => Icons.photo_camera_rounded,
  BusinessIndustry.usedBookStore => Icons.menu_book_rounded,
};

Color _businessIndustryColor(BusinessIndustry industry) => switch (industry) {
  BusinessIndustry.pcBang || BusinessIndustry.arcade => const Color(0xFF5767A7),
  BusinessIndustry.karaoke ||
  BusinessIndustry.photographyStudio => const Color(0xFF9A568D),
  BusinessIndustry.cafe ||
  BusinessIndustry.bakery ||
  BusinessIndustry.boardGameCafe => const Color(0xFF9A6B3F),
  BusinessIndustry.koreanRestaurant ||
  BusinessIndustry.fastFood ||
  BusinessIndustry.deliveryKitchen => const Color(0xFFAE5748),
  BusinessIndustry.convenienceStore ||
  BusinessIndustry.usedBookStore => const Color(0xFF437A64),
  BusinessIndustry.studyCafe => const Color(0xFF54738F),
  BusinessIndustry.fitnessCenter => const Color(0xFF3E7D79),
  BusinessIndustry.coinLaundry => const Color(0xFF4C82A0),
  BusinessIndustry.hairSalon ||
  BusinessIndustry.nailSalon ||
  BusinessIndustry.petGrooming => const Color(0xFFA86773),
};

class _BusinessListingDistrictFitCard extends StatelessWidget {
  const _BusinessListingDistrictFitCard({
    required this.state,
    required this.listing,
  });

  final GameState state;
  final BusinessListing listing;

  @override
  Widget build(BuildContext context) {
    final profile = businessDistrictProfileById(listing.districtId);
    if (profile == null) return const SizedBox.shrink();
    final snapshot = businessDistrictSnapshot(
      districtId: profile.id,
      asOf: state.currentDate,
      worldSeed: state.simulationSeed,
      generatorVersion: businessDistrictVersionForBusinessWorld(
        listing.generatorVersion,
      ),
    );
    final fit = businessDistrictIndustryFit(profile, listing.industry);
    return Container(
      key: Key('business-listing-fit-${listing.id}'),
      padding: const EdgeInsets.all(12),
      decoration: _businessCardDecoration(
        borderColor: _districtPhaseColor(snapshot.phase),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${snapshot.city} · ${snapshot.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              _BusinessDistrictPill(
                label: snapshot.phase.label,
                color: _districtPhaseColor(snapshot.phase),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${listing.industry.label} 적합지수 ${(fit * 100).round()}점 · '
            '${_districtFitLabel(fit)}',
            style: const TextStyle(
              color: Color(0xFF665D54),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          _BusinessDistrictMetrics(snapshot: snapshot),
          if (snapshot.currentSignals.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              snapshot.currentSignals
                  .take(2)
                  .map((signal) => '• $signal')
                  .join('\n'),
              style: const TextStyle(fontSize: 9.5, height: 1.4),
            ),
          ],
          const SizedBox(height: 6),
          const Text(
            '이 매물의 도시·상권은 고정입니다. 신규 창업은 아래에서 역세권·대학가 같은 상권 유형만 비교합니다.',
            style: TextStyle(
              color: Color(0xFF7B6D61),
              fontSize: 9,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessDistrictBoard extends StatefulWidget {
  const _BusinessDistrictBoard({required this.state});

  final GameState state;

  @override
  State<_BusinessDistrictBoard> createState() => _BusinessDistrictBoardState();
}

class _BusinessDistrictBoardState extends State<_BusinessDistrictBoard> {
  String? _selectedDistrictId;
  BusinessIndustry _industry = BusinessIndustry.pcBang;

  @override
  Widget build(BuildContext context) {
    final ranked = rankBusinessDistricts(
      asOf: widget.state.currentDate,
      worldSeed: widget.state.simulationSeed,
      generatorVersion: businessDistrictVersionForBusinessWorld(
        businessWorldGeneratorVersion,
      ),
    );
    if (ranked.isEmpty) {
      return ListView(
        key: const Key('business-district-board'),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: const [
          _BusinessEmptyCard(
            icon: Icons.location_off_outlined,
            title: '공개된 상권 정보가 없습니다',
            body: '현재 날짜에 확인할 수 있는 지역 정보가 생기면 이곳에 표시됩니다.',
          ),
        ],
      );
    }

    final selectedId =
        _selectedDistrictId != null &&
            ranked.any(
              (entry) => entry.snapshot.districtId == _selectedDistrictId,
            )
        ? _selectedDistrictId!
        : ranked.first.snapshot.districtId;
    final selected = ranked
        .firstWhere((entry) => entry.snapshot.districtId == selectedId)
        .snapshot;
    final profile = businessDistrictProfileById(selectedId);
    final fit = profile == null
        ? 1.0
        : businessDistrictIndustryFit(profile, _industry);
    final recentEvents = selected.revealedEvents
        .take(6)
        .toList(growable: false);

    return ListView(
      key: const Key('business-district-board'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
      children: [
        Container(
          key: const Key('business-district-as-of'),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF283F5E), Color(0xFF426B69)],
            ),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '지역 상권판세',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_districtDate(selected.asOf)} 현재까지 공개된 정보',
                style: const TextStyle(
                  color: Color(0xFFD8E7E3),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '순위와 신호는 현재·과거 관측치입니다. 이후 사건이나 결과는 미리 보여 주지 않습니다.',
                style: TextStyle(
                  color: Color(0xFFC4D8D5),
                  fontSize: 9.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _businessCardDecoration(),
          child: DropdownButtonFormField<String>(
            key: const Key('business-district-select'),
            initialValue: selectedId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: '자세히 볼 도시·상권',
              helperText: '현재 활력 순위의 지역을 선택해 원인과 위험을 비교합니다.',
              border: OutlineInputBorder(),
            ),
            items: ranked
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.snapshot.districtId,
                    child: Text(
                      '${entry.snapshot.city} · ${entry.snapshot.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) setState(() => _selectedDistrictId = value);
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: _businessCardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: ExpansionTile(
              key: const Key('business-district-ranking'),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 2,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              leading: const Icon(Icons.leaderboard_outlined),
              title: const Text(
                '현재 활력 순위',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
              subtitle: Text(
                '1위 ${ranked.first.snapshot.city} · ${ranked.first.snapshot.name} '
                '${ranked.first.snapshot.vitalityScore.round()}점',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9.5),
              ),
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '활력이 높아도 임대료와 경쟁이 함께 높으면 수익이 보장되지 않습니다.',
                    style: TextStyle(
                      color: Color(0xFF756A60),
                      fontSize: 9.2,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                ...ranked.map(
                  (entry) => _BusinessDistrictRankRow(
                    rank: entry.rank,
                    snapshot: entry.snapshot,
                    selected: entry.snapshot.districtId == selectedId,
                    onTap: () => setState(
                      () => _selectedDistrictId = entry.snapshot.districtId,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _businessCardDecoration(
            borderColor: _districtTrendColor(
              selected.monthOverMonth.vitalityPoints,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 7,
                runSpacing: 7,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${selected.city} · ${selected.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  _BusinessDistrictPill(
                    key: Key('business-district-phase-$selectedId'),
                    label: selected.phase.label,
                    color: _districtPhaseColor(selected.phase),
                  ),
                  _BusinessDistrictPill(
                    label: _districtTrendLabel(
                      selected.monthOverMonth.vitalityPoints,
                    ),
                    color: _districtTrendColor(
                      selected.monthOverMonth.vitalityPoints,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '전월 활력 ${_signedDistrictPoints(selected.monthOverMonth.vitalityPoints)} · '
                '전년 ${_signedDistrictPoints(selected.yearOverYear.vitalityPoints)}',
                style: const TextStyle(
                  color: Color(0xFF756A60),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _BusinessDistrictMetrics(
                key: Key('business-district-metrics-$selectedId'),
                snapshot: selected,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<BusinessIndustry>(
                key: const Key('business-district-industry-select'),
                initialValue: _industry,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '업종 적합도 비교',
                  border: OutlineInputBorder(),
                ),
                items: BusinessIndustry.values
                    .map(
                      (industry) => DropdownMenuItem<BusinessIndustry>(
                        value: industry,
                        child: Text(industry.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _industry = value);
                },
              ),
              const SizedBox(height: 8),
              Container(
                key: Key('business-district-fit-$selectedId'),
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EEE7),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '${_industry.label} 적합지수 ${(fit * 100).round()}점 · '
                  '${_districtFitLabel(fit)}\n'
                  '${_districtFitReason(selected, fit)}',
                  style: const TextStyle(fontSize: 10, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: Key('business-district-signals-$selectedId'),
          padding: const EdgeInsets.all(12),
          decoration: _businessCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BusinessSubheading(
                icon: Icons.sensors_outlined,
                title: '현재 관측 신호',
              ),
              const SizedBox(height: 5),
              Text(
                selected.currentSignals.isEmpty
                    ? '아직 뚜렷한 관측 신호가 없습니다.'
                    : selected.currentSignals
                          .map((signal) => '• $signal')
                          .join('\n'),
                style: const TextStyle(fontSize: 10, height: 1.5),
              ),
              const SizedBox(height: 6),
              const Text(
                '신호는 공개된 현재 상황의 해석이며 미래 상승·하락을 확정하지 않습니다.',
                style: TextStyle(
                  color: Color(0xFF7C6D60),
                  fontSize: 9,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: _businessCardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: ExpansionTile(
              key: Key('business-district-history-toggle-$selectedId'),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 2,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              leading: const Icon(Icons.history_rounded),
              title: const Text(
                '공개된 과거 원인',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
              subtitle: Text(
                recentEvents.isEmpty
                    ? '현재까지 공개된 변곡점이 없습니다.'
                    : '최근 공개 사건 ${recentEvents.length}건',
                style: const TextStyle(fontSize: 9.5),
              ),
              children: recentEvents.isEmpty
                  ? const [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '시간이 흐르고 사건이 공개되면 원인과 관측 결과가 여기에 쌓입니다.',
                          style: TextStyle(fontSize: 9.5, height: 1.4),
                        ),
                      ),
                    ]
                  : recentEvents
                        .map(
                          (event) => Container(
                            key: Key(
                              'business-district-history-$selectedId-${event.id}',
                            ),
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 7),
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F1EA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_districtDate(event.revealedOn)} 공개 · '
                                  '${event.isActive ? '영향 진행 중' : '영향 종료'}',
                                  style: const TextStyle(
                                    color: Color(0xFF76695E),
                                    fontSize: 8.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  event.headline,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  event.summary,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }
}

class _BusinessDistrictRankRow extends StatelessWidget {
  const _BusinessDistrictRankRow({
    required this.rank,
    required this.snapshot,
    required this.selected,
    required this.onTap,
  });

  final int rank;
  final BusinessDistrictSnapshot snapshot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFE8F0EB) : Colors.transparent,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      key: Key('business-district-rank-${snapshot.districtId}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 25,
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${snapshot.city} · ${snapshot.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 62),
              child: Text(
                snapshot.phase.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _districtPhaseColor(snapshot.phase),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 7),
            SizedBox(
              width: 36,
              child: Text(
                '${snapshot.vitalityScore.round()}점',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 9.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BusinessDistrictMetrics extends StatelessWidget {
  const _BusinessDistrictMetrics({super.key, required this.snapshot});

  final BusinessDistrictSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final metrics = <(String, String)>[
      ('활력', '${snapshot.vitalityScore.round()}점'),
      ('임대료 부담', '지수 ${(snapshot.rentMultiplier * 100).round()}'),
      ('경쟁 강도', '지수 ${(snapshot.competitionMultiplier * 100).round()}'),
      ('공실', '지수 ${(snapshot.vacancyMultiplier * 100).round()}'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 7) / 2;
        return Wrap(
          spacing: 7,
          runSpacing: 7,
          children: metrics
              .map(
                (metric) => Container(
                  width: width,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EEE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.$1,
                        style: const TextStyle(
                          color: Color(0xFF756A60),
                          fontSize: 8.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metric.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _BusinessDistrictPill extends StatelessWidget {
  const _BusinessDistrictPill({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

String _districtDate(DateTime date) =>
    '${date.year}.${date.month.toString().padLeft(2, '0')}.'
    '${date.day.toString().padLeft(2, '0')}';

String _districtTrendLabel(double points) {
  if (points >= 4) return '급상승';
  if (points >= 1) return '상승';
  if (points <= -4) return '급하락';
  if (points <= -1) return '하락';
  return '보합';
}

Color _districtTrendColor(double points) {
  if (points >= 1) return const Color(0xFF39735A);
  if (points <= -1) return const Color(0xFFA04440);
  return const Color(0xFF756B60);
}

String _signedDistrictPoints(double points) {
  final fixed = points.abs() >= 10
      ? points.toStringAsFixed(0)
      : points.toStringAsFixed(1);
  return '${points > 0 ? '+' : ''}$fixed점';
}

String _districtFitLabel(double fit) {
  if (fit >= 1.18) return '매우 좋음';
  if (fit >= 1.06) return '좋음';
  if (fit <= 0.82) return '매우 불리';
  if (fit <= 0.94) return '불리';
  return '보통';
}

String _districtFitReason(BusinessDistrictSnapshot snapshot, double fit) {
  final notes = <String>[
    if (fit >= 1.06) '현재 지역 수요와 업종 구성이 잘 맞습니다.',
    if (fit <= 0.94) '현재 지역 수요와 업종 구성이 맞지 않는 편입니다.',
    if (snapshot.rentMultiplier >= 1.18) '높은 임대료 부담을 함께 계산해야 합니다.',
    if (snapshot.competitionMultiplier >= 1.18) '경쟁 강도가 높아 단순 입점만으로는 어렵습니다.',
    if (snapshot.vacancyMultiplier >= 1.15) '공실 신호가 커 유동인구를 다시 확인해야 합니다.',
  ];
  return notes.isEmpty ? '현재 지표상 특별한 우위나 경고가 없습니다.' : notes.take(2).join(' ');
}

Color _districtPhaseColor(BusinessDistrictPhase phase) => switch (phase) {
  BusinessDistrictPhase.emerging => const Color(0xFF527D9A),
  BusinessDistrictPhase.booming => const Color(0xFF368064),
  BusinessDistrictPhase.mature => const Color(0xFF5E7068),
  BusinessDistrictPhase.cooling => const Color(0xFF9B713C),
  BusinessDistrictPhase.declining => const Color(0xFFA75A45),
  BusinessDistrictPhase.distressed => const Color(0xFF9B4242),
  BusinessDistrictPhase.regenerating => const Color(0xFF6F5A9A),
};

String _businessDistrictLabel(String id) {
  final profile = businessDistrictProfileById(id);
  if (profile == null) return '지역 미확인';
  return '${profile.city} · ${profile.name}';
}
