part of 'main.dart';

class AssetSpendingScreen extends StatefulWidget {
  const AssetSpendingScreen({
    super.key,
    required this.state,
    required this.onPurchase,
    required this.onSellRealEstate,
    required this.onPlayChanceGame,
    this.onConfigureLease,
    this.realEstateOnly = false,
  });

  final GameState state;
  final Future<FinanceActionResult> Function(String optionId) onPurchase;
  final Future<FinanceActionResult> Function(String assetId) onSellRealEstate;
  final Future<FinanceActionResult> Function(int stake) onPlayChanceGame;
  final Future<FinanceActionResult> Function(
    String assetId,
    RealEstateLeaseType leaseType,
  )?
  onConfigureLease;
  final bool realEstateOnly;

  @override
  State<AssetSpendingScreen> createState() => _AssetSpendingScreenState();
}

class _AssetSpendingScreenState extends State<AssetSpendingScreen> {
  late GameState _state = widget.state;
  bool _busy = false;
  RealEstateInvestmentTier _selectedPropertyTier =
      RealEstateInvestmentTier.starter;
  String? _selectedPropertyDistrictId;

  String _periodFor(SpendingOption option) => switch (option.repeat) {
    SpendingRepeat.once => 'once',
    SpendingRepeat.monthly =>
      '${_state.currentDate.year}-${_state.currentDate.month.toString().padLeft(2, '0')}',
    SpendingRepeat.yearly => '${_state.currentDate.year}',
  };

  String? _lockReason(SpendingOption option) {
    if (_state.currentDate.year < option.unlockYear) {
      return '${option.unlockYear}년 해금';
    }
    final availableFrom = option.marketAsset?.availableFrom;
    if (availableFrom != null && _state.currentDate.isBefore(availableFrom)) {
      return '${availableFrom.year}년 ${availableFrom.month}월 해금';
    }
    if (option.requiresEmployee && _state.organization.employees.isEmpty) {
      return '직원 채용 필요';
    }
    if (option.requiresLegalCompany &&
        !_state.story.flagBool('isLegalCompany')) {
      return '법인 설립 필요';
    }
    if (option.isRealEstate &&
        _state.personalFinance.ownsRealEstate(option.id)) {
      return '이미 보유 중';
    }
    if (option.repeat == SpendingRepeat.once &&
        !option.isRealEstate &&
        _state.personalFinance.hasPermanentPurchase(option.id)) {
      return '구입 완료';
    }
    if (option.repeat != SpendingRepeat.once &&
        _state.personalFinance.lastPurchasePeriods[option.id] ==
            _periodFor(option)) {
      return option.repeat == SpendingRepeat.monthly ? '이번 달 완료' : '올해 완료';
    }
    if (_state.bankCash < option.costAt(_state.currentDate)) return '현금 부족';
    return null;
  }

  String? _listingLockReason(GeneratedRealEstateListing listing) {
    final option = spendingOptionById('market_${listing.asset.id}')!;
    final baseReason = _lockReason(option);
    if (baseReason != null && baseReason != '현금 부족') return baseReason;
    if (_state.currentDate.isBefore(listing.asset.availableFrom)) {
      final date = listing.asset.availableFrom;
      return '${date.year}년 ${date.month}월 해금';
    }
    if (_state.personalFinance.ownsRealEstate(listing.optionId)) {
      return '이미 보유 중';
    }
    final quote = listing.quoteAt(_state.currentDate);
    final terms = realEstateFinancingTermsAt(
      _state.currentDate,
      listing.asset.type,
    );
    final minimumCash = terms.planFor(quote, terms.maxLtvPercent).cashRequired;
    if (_state.bankCash < minimumCash) {
      return '현금 부족';
    }
    return null;
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _run(
    Future<FinanceActionResult> Function() action, {
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    if (_busy || !await _confirm(title, body, confirmLabel)) return;
    setState(() => _busy = true);
    try {
      final result = await action();
      if (!mounted) return;
      if (result.success) setState(() => _state = result.state);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${result.message}\n회사 통장 ${_money(result.state.cash)}원',
            ),
          ),
        );
    } catch (_) {
      if (mounted) _showSaveFailure(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _purchase(SpendingOption option) {
    final quote = option.quoteAt(_state.currentDate);
    final total = option.costAt(_state.currentDate);
    final body = quote == null
        ? '${_money(total)}원을 지출합니다. ${option.description}\n\n저장에 성공한 뒤에만 현금과 효과가 반영됩니다.'
        : '매매가 ${_money(quote.marketPrice)}원\n'
              '취득세 ${_money(quote.acquisitionTax)}원\n'
              '지방교육세 ${_money(quote.localEducationTax)}원\n'
              '농어촌특별세 ${_money(quote.ruralSpecialTax)}원\n'
              '중개보수+VAT ${_money(quote.brokerageFee + quote.brokerageVat)}원\n'
              '등기·채권·법무 추정 ${_money(quote.bondLegalAndRegistration)}원\n'
              '총 필요 현금 ${_money(total)}원\n\n'
              '${option.description}';
    return _run(
      () => widget.onPurchase(option.id),
      title: option.title,
      body: body,
      confirmLabel: quote == null ? '지출 확정' : '매입 확정',
    );
  }

  Future<void> _sell(OwnedRealEstate asset) => _run(
    () => widget.onSellRealEstate(asset.id),
    title: '${asset.name} 매각',
    body: asset.hasMortgage
        ? '예상 매각대금 ${_money(asset.estimatedSaleValue(_state.day))}원에서 '
              '대출잔액 ${_money(asset.mortgageBalance)}원을 상환합니다. '
              '예상 수령액은 ${_money(asset.estimatedSaleValue(_state.day) - asset.mortgageBalance)}원입니다. '
              '취득 후 30일 이내에는 매각할 수 없습니다.'
        : '예상 매각대금은 ${_money(asset.estimatedSaleValue(_state.day))}원입니다. 취득 후 30일 이내에는 매각할 수 없으며, 매입가 대비 거래비용이 반영된 게임용 평가입니다.',
    confirmLabel: '매각 확정',
  );

  Future<void> _manageLease(OwnedRealEstate asset) async {
    final handler = widget.onConfigureLease;
    if (handler == null) return;
    final assetType =
        asset.marketAsset?.type ?? RealEstateAssetType.commercialUnit;
    final choices = <RealEstateLeaseType>[
      RealEstateLeaseType.vacant,
      RealEstateLeaseType.monthlyRent,
      if (realEstateSupportsJeonse(assetType)) RealEstateLeaseType.jeonse,
    ];
    final marketRent =
        asset.generatedListing?.monthlyRentAt(_state.currentDate) ??
        asset.marketAsset?.monthlyRentAt(_state.currentDate) ??
        asset.monthlyIncome;
    final selected = await showDialog<RealEstateLeaseType>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${asset.name} 임대 운영'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '보증금은 수익이 아니라 계약 만료 때 돌려줘야 할 부채입니다. '
                '반환하지 못하면 매물이 경매 처분될 수 있습니다.',
                style: TextStyle(fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 12),
              ...choices.map((leaseType) {
                final terms = realEstateLeaseTermsAt(
                  date: _state.currentDate,
                  type: assetType,
                  leaseType: leaseType,
                  marketValue: asset.estimatedMarketValue(_state.day),
                  marketMonthlyRent: marketRent,
                );
                final subtitle = switch (leaseType) {
                  RealEstateLeaseType.vacant =>
                    '임대수입 0원 · 공실 개월과 수리 사건이 누적됩니다.',
                  RealEstateLeaseType.monthlyRent =>
                    '보증금 ${_money(terms.deposit)}원 · 월세 ${_money(terms.monthlyRent)}원\n'
                        '중개·입주비 ${_money(terms.placementFee)}원 · ${terms.contractMonths}개월',
                  RealEstateLeaseType.jeonse =>
                    '보증금 ${_money(terms.deposit)}원 · 월세 0원\n'
                        '중개·입주비 ${_money(terms.placementFee)}원 · ${terms.contractMonths}개월',
                  RealEstateLeaseType.automatic => '',
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    key: Key('real-estate-lease-${leaseType.name}'),
                    tileColor: const Color(0xFFF5EFE5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      leaseType.label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(subtitle),
                    onTap: () => Navigator.of(dialogContext).pop(leaseType),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final terms = realEstateLeaseTermsAt(
      date: _state.currentDate,
      type: assetType,
      leaseType: selected,
      marketValue: asset.estimatedMarketValue(_state.day),
      marketMonthlyRent: marketRent,
    );
    final body = selected == RealEstateLeaseType.vacant
        ? '임대수입 없이 공실로 전환합니다. 공실 중에도 유지비와 수리 사건은 발생합니다.'
        : '${selected.label} ${terms.contractMonths}개월 계약\n'
              '보증금 ${_money(terms.deposit)}원 · 월세 ${_money(terms.monthlyRent)}원\n'
              '중개·입주 정비비 ${_money(terms.placementFee)}원\n'
              '계약 만료 때 보증금을 돌려주지 못하면 경매 위험이 있습니다.';
    return _run(
      () => handler(asset.id, selected),
      title: '${asset.name} ${selected.label}',
      body: body,
      confirmLabel: '계약 확정',
    );
  }

  Future<int?> _chooseFinancingLtv(GeneratedRealEstateListing listing) async {
    final quote = listing.quoteAt(_state.currentDate);
    final terms = realEstateFinancingTermsAt(
      _state.currentDate,
      listing.asset.type,
    );
    if (!terms.available) return 0;
    final choices = <int>{
      0,
      if (terms.maxLtvPercent > 40) 40,
      terms.maxLtvPercent,
    }.toList()..sort();
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('매입 자금 선택'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${terms.eraLabel} · 게임 단순화 금리\n'
                '취득세·중개비 등 부대비용은 대출이 아니라 현금으로 냅니다.',
                style: const TextStyle(fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 12),
              ...choices.map((ltv) {
                final plan = terms.planFor(quote, ltv);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    key: Key('real-estate-financing-$ltv'),
                    tileColor: const Color(0xFFF5EFE5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      ltv == 0 ? '현금 매입' : '담보대출 LTV $ltv%',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      ltv == 0
                          ? '필요 현금 ${_money(plan.cashRequired)}원'
                          : '자기자본 ${_money(plan.cashRequired)}원 · '
                                '대출 ${_money(plan.principal)}원\n'
                                '연 ${(plan.annualInterestRate * 100).toStringAsFixed(2)}% · '
                                '${plan.termMonths}개월 · 월 ${_money(plan.monthlyPayment)}원',
                    ),
                    onTap: () => Navigator.of(dialogContext).pop(ltv),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseListing(GeneratedRealEstateListing listing) async {
    final quote = listing.quoteAt(_state.currentDate);
    final terms = realEstateFinancingTermsAt(
      _state.currentDate,
      listing.asset.type,
    );
    final selectedLtv = await _chooseFinancingLtv(listing);
    if (selectedLtv == null || !mounted) return;
    final financing = terms.planFor(quote, selectedLtv);
    final latestEvent = listing.latestVisibleEventAt(_state.currentDate);
    final eventText = latestEvent == null
        ? '아직 공개된 지역·매물 사건이 없습니다.'
        : '${latestEvent.title} [${latestEvent.statusAt(_state.currentDate)}]\n'
              '${latestEvent.detailAt(_state.currentDate)}';
    final body =
        '매매가 ${_money(quote.marketPrice)}원\n'
        '취득세 ${_money(quote.acquisitionTax)}원\n'
        '지방교육세 ${_money(quote.localEducationTax)}원\n'
        '농어촌특별세 ${_money(quote.ruralSpecialTax)}원\n'
        '중개보수+VAT ${_money(quote.brokerageFee + quote.brokerageVat)}원\n'
        '등기·채권·법무 추정 ${_money(quote.bondLegalAndRegistration)}원\n'
        '총 취득원가 ${_money(quote.totalCash)}원\n'
        '실제 필요 현금 ${_money(financing.cashRequired)}원\n'
        '${financing.hasMortgage ? '담보대출 ${_money(financing.principal)}원 · LTV ${financing.appliedLtvPercent}%\n연 ${(financing.annualInterestRate * 100).toStringAsFixed(2)}% · ${financing.termMonths}개월 · 월 원리금 ${_money(financing.monthlyPayment)}원\n' : '대출 없이 현금 매입\n'}\n'
        '매물 위험: ${listing.riskSummary}\n'
        '최근 공개 정보: $eventText\n\n'
        '발표 단계의 개발 계획은 지연되거나 취소될 수 있습니다. '
        '원리금 3회 연속 연체 시 강제매각되며 부족액은 결손채무로 남습니다.';
    return _run(
      () => widget.onPurchase(
        realEstateFinancedOptionId(
          listing.optionId,
          financing.appliedLtvPercent,
        ),
      ),
      title: listing.displayName,
      body: body,
      confirmLabel: '위험 확인 후 매입',
    );
  }

  Future<void> _playChance(int stake) => _run(
    () => widget.onPlayChanceGame(stake),
    title: '성인 확률 오락',
    body:
        '게임머니 ${_money(stake)}원을 사용합니다. 지급률은 60%: 0원, 30%: 1.5배, 10%: 3배이며 평균 지급률은 75%입니다. 월 1회이고 실제 결제나 현금 보상은 없습니다.',
    confirmLabel: '확률 확인 후 참여',
  );

  @override
  Widget build(BuildContext context) {
    final finance = _state.personalFinance;
    final propertyValue = finance.estimatedPropertyValueAt(_state.day);
    final familyOption = spendingOptionById('family_outing')!;
    return Scaffold(
      key: const Key('asset-spending-screen'),
      backgroundColor: const Color(0xFFF3EBDD),
      appBar: AppBar(
        title: Text(widget.realEstateOnly ? '부동산 시장' : '자산·소비 계획'),
        backgroundColor: const Color(0xFFF3EBDD),
      ),
      body: SafeArea(
        top: false,
        child: KeyedSubtree(
          key: widget.realEstateOnly
              ? const Key('real-estate-market-screen')
              : null,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: [
              _FinanceOverviewCard(
                cash: _state.cash,
                propertyValue: propertyValue,
                monthlyPropertyNet:
                    finance.monthlyPropertyIncomeAt(_state.currentDate) -
                    finance.monthlyPropertyCostAt(_state.currentDate) -
                    finance.monthlyMortgagePayment,
                totalSpent: finance.totalSpent,
                totalMortgageBalance: finance.totalMortgageBalance,
                totalTenantDeposits: finance.totalTenantDepositLiability,
                tenantDepositDebt: _state.story.flagInt('tenantDepositDebt'),
              ),
              if (!widget.realEstateOnly) ...[
                const SizedBox(height: 12),
                const _FinanceNoticeCard(),
                const SizedBox(height: 10),
                _SpendingOptionCard(
                  option: familyOption,
                  lockReason: _lockReason(familyOption),
                  busy: _busy,
                  onTap: () => _purchase(familyOption),
                ),
              ],
              const SizedBox(height: 18),
              _RealEstateMarketSection(
                selectedTier: _selectedPropertyTier,
                selectedDistrictId: _selectedPropertyDistrictId,
                currentDate: _state.currentDate,
                worldSeed: _state.simulationSeed,
                busy: _busy,
                lockReason: _listingLockReason,
                onTierSelected: (tier) => setState(() {
                  _selectedPropertyTier = tier;
                  _selectedPropertyDistrictId = null;
                }),
                onDistrictSelected: (districtId) =>
                    setState(() => _selectedPropertyDistrictId = districtId),
                onPurchase: _purchaseListing,
              ),
              if (!widget.realEstateOnly) ...[
                const SizedBox(height: 18),
                const _FinanceSectionTitle(
                  icon: Icons.shopping_bag_rounded,
                  title: '쓸 곳과 키울 곳',
                  caption: '연도·법인·직원 조건에 따라 순서대로 열립니다.',
                ),
                const SizedBox(height: 8),
                ...spendingCatalog
                    .where(
                      (option) =>
                          option.marketAssetId == null &&
                          option.id != familyOption.id,
                    )
                    .map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _SpendingOptionCard(
                          option: option,
                          lockReason: _lockReason(option),
                          busy: _busy,
                          onTap: () => _purchase(option),
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 10),
              _FinanceSectionTitle(
                icon: Icons.apartment_rounded,
                title: '보유 부동산',
                caption:
                    '${finance.realEstate.length}건 · 추정가 ${_money(propertyValue)}원',
              ),
              const SizedBox(height: 8),
              if (finance.realEstate.isEmpty)
                const _FinanceEmptyCard(
                  title: '아직 부동산이 없습니다',
                  body: '수천만원대 오피스텔부터 시작해 월세와 시세 변동을 경험해 보세요.',
                )
              else
                ...finance.realEstate.map(
                  (asset) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _OwnedPropertyCard(
                      asset: asset,
                      currentDay: _state.day,
                      currentDate: _state.currentDate,
                      busy: _busy,
                      onSell: () => _sell(asset),
                      leaseManagementAvailable: widget.onConfigureLease != null,
                      onManageLease: () => _manageLease(asset),
                    ),
                  ),
                ),
              if (!widget.realEstateOnly) ...[
                const SizedBox(height: 10),
                _AdultChanceCard(
                  state: _state,
                  busy: _busy,
                  onPlay: _playChance,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RealEstateMarketSection extends StatelessWidget {
  const _RealEstateMarketSection({
    required this.selectedTier,
    required this.selectedDistrictId,
    required this.currentDate,
    required this.worldSeed,
    required this.busy,
    required this.lockReason,
    required this.onTierSelected,
    required this.onDistrictSelected,
    required this.onPurchase,
  });

  final RealEstateInvestmentTier selectedTier;
  final String? selectedDistrictId;
  final DateTime currentDate;
  final String worldSeed;
  final bool busy;
  final String? Function(GeneratedRealEstateListing listing) lockReason;
  final ValueChanged<RealEstateInvestmentTier> onTierSelected;
  final ValueChanged<String?> onDistrictSelected;
  final Future<void> Function(GeneratedRealEstateListing listing) onPurchase;

  @override
  Widget build(BuildContext context) {
    final tierAssets = realEstateMarketCatalog
        .where((asset) => asset.tier == selectedTier)
        .toList(growable: false);
    final visibleAssets = selectedDistrictId == null
        ? tierAssets
        : tierAssets
              .where(
                (asset) =>
                    realEstateDistrictFor(asset).id == selectedDistrictId,
              )
              .toList(growable: false);
    final listings =
        visibleAssets
            .expand((asset) => realEstateListingsFor(asset, worldSeed))
            .toList(growable: false)
          ..sort(
            (a, b) => a.priceAt(currentDate).compareTo(b.priceAt(currentDate)),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FinanceSectionTitle(
          icon: Icons.location_city_rounded,
          title: '서울·경기 부동산 투자',
          caption: '단지마다 3개 개별 매물 · 사건 결과는 확정 시점까지 비공개',
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: RealEstateInvestmentTier.values
                .map(
                  (tier) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      key: Key('real-estate-tier-${tier.name}'),
                      selected: selectedTier == tier,
                      onSelected: (_) => onTierSelected(tier),
                      label: Text(tier.label),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 8),
        _RealEstateMetroMap(
          assets: tierAssets,
          selectedDistrictId: selectedDistrictId,
          currentDate: currentDate,
          worldSeed: worldSeed,
          onDistrictSelected: onDistrictSelected,
        ),
        const SizedBox(height: 8),
        Text(
          selectedDistrictId == null
              ? '${selectedTier.description} · 지도 핀을 누르면 해당 지역 매물만 볼 수 있습니다.'
              : '${visibleAssets.first.region} ${listings.length}개 매물 · 다시 누르면 전체 권역으로 돌아갑니다.',
          style: const TextStyle(
            color: Color(0xFF66584E),
            fontSize: 11,
            height: 1.45,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 920,
          child: ListView.separated(
            key: const Key('real-estate-listing-carousel'),
            scrollDirection: Axis.horizontal,
            itemCount: listings.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final listing = listings[index];
              return SizedBox(
                width: MediaQuery.sizeOf(context).width - 28,
                child: _RealEstateMarketCard(
                  listing: listing,
                  currentDate: currentDate,
                  lockReason: lockReason(listing),
                  busy: busy,
                  onPurchase: () {
                    onPurchase(listing);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RealEstateMetroMap extends StatelessWidget {
  const _RealEstateMetroMap({
    required this.assets,
    required this.selectedDistrictId,
    required this.currentDate,
    required this.worldSeed,
    required this.onDistrictSelected,
  });

  final List<RealEstateMarketAsset> assets;
  final String? selectedDistrictId;
  final DateTime currentDate;
  final String worldSeed;
  final ValueChanged<String?> onDistrictSelected;

  @override
  Widget build(BuildContext context) {
    final districtIds = assets
        .map(realEstateDistrictFor)
        .map((district) => district.id)
        .toSet();
    final districts = realEstateDistrictCatalog
        .where((district) => districtIds.contains(district.id))
        .toList(growable: false);
    final selectedDistrict = selectedDistrictId == null
        ? null
        : realEstateDistrictById(selectedDistrictId!);
    final selectedEvent = selectedDistrict == null
        ? null
        : realEstateLatestDistrictEventAt(
            selectedDistrict,
            worldSeed,
            currentDate,
          );
    return Container(
      key: const Key('real-estate-metro-map'),
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1E3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7BE91)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedDistrict?.label ?? '서울·경기 광역 투자 지도',
                        style: const TextStyle(
                          color: Color(0xFF49372B),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        selectedEvent == null
                            ? '건물 핀을 눌러 지역 매물과 사건을 확인하세요.'
                            : '${selectedEvent.title} · ${selectedEvent.statusAt(currentDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7C6C5E),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  key: const Key('real-estate-map-show-all'),
                  onPressed: selectedDistrictId == null
                      ? null
                      : () => onDistrictSelected(null),
                  icon: const Icon(Icons.public_rounded, size: 15),
                  label: const Text('전체'),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RealEstateMetroMapPainter(
                        selectedDistrictId: selectedDistrictId,
                      ),
                    ),
                  ),
                  ...districts.map((district) {
                    final selected = district.id == selectedDistrictId;
                    final event = realEstateLatestDistrictEventAt(
                      district,
                      worldSeed,
                      currentDate,
                    );
                    final propertyCount =
                        assets
                            .where(
                              (asset) =>
                                  realEstateDistrictFor(asset).id ==
                                  district.id,
                            )
                            .length *
                        3;
                    final left = (district.mapX * constraints.maxWidth - 29)
                        .clamp(0.0, constraints.maxWidth - 58);
                    final top = (district.mapY * constraints.maxHeight - 22)
                        .clamp(0.0, constraints.maxHeight - 52);
                    final shortName = district.name
                        .replaceAll('특별시', '')
                        .replaceAll('시', '')
                        .replaceAll('구', '');
                    return Positioned(
                      left: left,
                      top: top,
                      width: 58,
                      height: 52,
                      child: Tooltip(
                        message: event == null
                            ? '${district.label} · 매물 $propertyCount개'
                            : '${district.label}\n${event.title}\n${event.statusAt(currentDate)}',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: Key('real-estate-map-district-${district.id}'),
                            onTap: () => onDistrictSelected(
                              selected ? null : district.id,
                            ),
                            borderRadius: BorderRadius.circular(13),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: selected ? 34 : 30,
                                  height: selected ? 34 : 30,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFFB45A3C)
                                        : district.province == '서울특별시'
                                        ? const Color(0xFF4D7790)
                                        : const Color(0xFF66845D),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x33000000),
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(
                                        Icons.apartment_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      if (event != null)
                                        const Positioned(
                                          right: 2,
                                          top: 2,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: Color(0xFFFFD15C),
                                              shape: BoxShape.circle,
                                            ),
                                            child: SizedBox(
                                              width: 7,
                                              height: 7,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$shortName $propertyCount',
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  style: TextStyle(
                                    color: selected
                                        ? const Color(0xFF8C3D27)
                                        : const Color(0xFF493D35),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RealEstateMetroMapPainter extends CustomPainter {
  const _RealEstateMetroMapPainter({required this.selectedDistrictId});

  final String? selectedDistrictId;

  @override
  void paint(Canvas canvas, Size size) {
    final gyeonggi = Path()
      ..moveTo(size.width * 0.46, size.height * 0.01)
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.00,
        size.width * 0.94,
        size.height * 0.22,
        size.width * 0.91,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.96,
        size.height * 0.73,
        size.width * 0.74,
        size.height * 0.98,
        size.width * 0.50,
        size.height * 0.97,
      )
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.98,
        size.width * 0.05,
        size.height * 0.78,
        size.width * 0.08,
        size.height * 0.50,
      )
      ..cubicTo(
        size.width * 0.02,
        size.height * 0.25,
        size.width * 0.20,
        size.height * 0.07,
        size.width * 0.46,
        size.height * 0.01,
      )
      ..close();
    canvas.drawPath(gyeonggi, Paint()..color = const Color(0xFFDCE8CF));
    canvas.drawPath(
      gyeonggi,
      Paint()
        ..color = const Color(0xFF8DA57E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final seoul = Path()
      ..moveTo(size.width * 0.29, size.height * 0.31)
      ..cubicTo(
        size.width * 0.45,
        size.height * 0.20,
        size.width * 0.72,
        size.height * 0.24,
        size.width * 0.80,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.85,
        size.height * 0.58,
        size.width * 0.70,
        size.height * 0.70,
        size.width * 0.50,
        size.height * 0.69,
      )
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.72,
        size.width * 0.18,
        size.height * 0.58,
        size.width * 0.22,
        size.height * 0.43,
      )
      ..cubicTo(
        size.width * 0.23,
        size.height * 0.37,
        size.width * 0.25,
        size.height * 0.34,
        size.width * 0.29,
        size.height * 0.31,
      )
      ..close();
    canvas.drawPath(seoul, Paint()..color = const Color(0xFFD6E4E9));
    canvas.drawPath(
      seoul,
      Paint()
        ..color = const Color(0xFF7593A2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final river = Path()
      ..moveTo(size.width * 0.20, size.height * 0.49)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.43,
        size.width * 0.59,
        size.height * 0.58,
        size.width * 0.83,
        size.height * 0.49,
      );
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF78B4CD)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5,
    );

    final selected = realEstateDistrictById(selectedDistrictId ?? '');
    if (selected != null) {
      final selectedPoint = Offset(
        selected.mapX * size.width,
        selected.mapY * size.height,
      );
      final linkPaint = Paint()
        ..color = const Color(0x99B45A3C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final influenceDistricts =
          realEstateDistrictCatalog
              .where((district) => selected.distanceTo(district) <= 0.30)
              .toList()
            ..sort(
              (a, b) =>
                  selected.distanceTo(a).compareTo(selected.distanceTo(b)),
            );
      for (final district in influenceDistricts.take(4)) {
        if (district.id == selected.id) continue;
        canvas.drawLine(
          selectedPoint,
          Offset(district.mapX * size.width, district.mapY * size.height),
          linkPaint,
        );
      }
      canvas.drawCircle(
        selectedPoint,
        22,
        Paint()
          ..color = const Color(0x44B45A3C)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RealEstateMetroMapPainter oldDelegate) =>
      oldDelegate.selectedDistrictId != selectedDistrictId;
}

class _RealEstateMarketCard extends StatelessWidget {
  const _RealEstateMarketCard({
    required this.listing,
    required this.currentDate,
    required this.lockReason,
    required this.busy,
    required this.onPurchase,
  });

  final GeneratedRealEstateListing listing;
  final DateTime currentDate;
  final String? lockReason;
  final bool busy;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final asset = listing.asset;
    final quote = listing.quoteAt(currentDate);
    final evidence = asset.evidenceAt(currentDate);
    final monthlyRent = listing.monthlyRentAt(currentDate);
    final monthlyCost = listing.monthlyOperatingCostAt(currentDate);
    final financingTerms = realEstateFinancingTermsAt(currentDate, asset.type);
    final maxFinancing = financingTerms.planFor(
      quote,
      financingTerms.maxLtvPercent,
    );
    final latestEvent = listing.latestVisibleEventAt(currentDate);
    final evidenceColor = switch (evidence.evidence) {
      RealEstatePriceEvidence.actualTransaction => const Color(0xFF2F6B4F),
      RealEstatePriceEvidence.actualBuildingSale => const Color(0xFF2F6B4F),
      RealEstatePriceEvidence.indexBackcast => const Color(0xFF72559C),
      RealEstatePriceEvidence.appraisedEstimate => const Color(0xFF91672F),
      RealEstatePriceEvidence.gameExtension => const Color(0xFF8E4E48),
    };
    return Container(
      key: Key('real-estate-market-${asset.id}-${listing.index}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFD5C19E)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 2,
            child: Image.asset(
              asset.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFE8D9C3),
                child: Center(child: Icon(Icons.apartment_rounded, size: 58)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MarketBadge(
                      label: asset.type.label,
                      color: const Color(0xFF714C34),
                    ),
                    _MarketBadge(
                      label: evidence.evidence.label,
                      color: evidenceColor,
                    ),
                    _MarketBadge(
                      label: listing.condition.label,
                      color: const Color(0xFF8E4E48),
                    ),
                    if (asset.realNamedAsset)
                      const _MarketBadge(
                        label: '실제 유명 자산',
                        color: Color(0xFF2F6B4F),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  listing.displayName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${asset.province} ${asset.region} · ${listing.areaSquareMeters.toStringAsFixed(0)}㎡ · ${listing.floor}층 · 역 도보 ${listing.stationWalkMinutes}분',
                  style: const TextStyle(
                    color: Color(0xFF75685D),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '현재 매매가',
                            style: TextStyle(
                              color: Color(0xFF7F7165),
                              fontSize: 9,
                            ),
                          ),
                          FittedBox(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${_money(quote.marketPrice)}원',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF382820),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '취득 총현금',
                          style: TextStyle(
                            color: Color(0xFF7F7165),
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          '${_money(quote.totalCash)}원',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EFE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '취득 부대비용 ${_money(quote.acquisitionCosts)}원 · 월세 ${_money(monthlyRent)}원',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '월 유지·공실충당 ${_money(monthlyCost)}원 · 월 순현금 +${_money(monthlyRent - monthlyCost)}원',
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        financingTerms.available
                            ? '대출 최대 LTV ${financingTerms.maxLtvPercent}% · '
                                  '최저 필요 현금 ${_money(maxFinancing.cashRequired)}원 · '
                                  '월 원리금 ${_money(maxFinancing.monthlyPayment)}원'
                            : '현재는 현금 매입만 가능',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF7D5035),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4DF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8C98A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestEvent == null
                            ? '현재 공개된 지역·매물 사건 없음'
                            : '${latestEvent.title} · ${latestEvent.statusAt(currentDate)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        latestEvent?.detailAt(currentDate) ??
                            '사건은 월드 시드에 따라 발생하며 미래 결과는 미리 보이지 않습니다.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '개별 위험: ${listing.riskSummary}\n'
                  '${evidence.sourceLabel} · ${asset.sourceNote}',
                  style: const TextStyle(
                    color: Color(0xFF766A60),
                    fontSize: 9,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  height: 47,
                  child: FilledButton(
                    key: Key('real-estate-buy-${asset.id}-${listing.index}'),
                    onPressed: lockReason == null && !busy ? onPurchase : null,
                    child: Text(lockReason ?? '매입·대출 검토'),
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

class _MarketBadge extends StatelessWidget {
  const _MarketBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
    ),
  );
}

class _FinanceOverviewCard extends StatelessWidget {
  const _FinanceOverviewCard({
    required this.cash,
    required this.propertyValue,
    required this.monthlyPropertyNet,
    required this.totalSpent,
    required this.totalMortgageBalance,
    required this.totalTenantDeposits,
    required this.tenantDepositDebt,
  });

  final int cash;
  final int propertyValue;
  final int monthlyPropertyNet;
  final int totalSpent;
  final int totalMortgageBalance;
  final int totalTenantDeposits;
  final int tenantDepositDebt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF3A2A24),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 14)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '운용 현금과 비시장 자산',
          style: TextStyle(
            color: Color(0xFFFFD990),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        FittedBox(
          child: Text(
            '현금 ${_money(cash)}원',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _FinancePill(label: '부동산 추정가', value: '${_money(propertyValue)}원'),
            _FinancePill(
              label: '월 부동산 순현금',
              value:
                  '${monthlyPropertyNet >= 0 ? '+' : ''}${_money(monthlyPropertyNet)}원',
            ),
            _FinancePill(
              label: '담보대출 잔액',
              value: '${_money(totalMortgageBalance)}원',
            ),
            _FinancePill(
              label: '반환할 임차보증금',
              value: '${_money(totalTenantDeposits)}원',
            ),
            if (tenantDepositDebt > 0)
              _FinancePill(
                label: '미반환 보증금',
                value: '${_money(tenantDepositDebt)}원',
              ),
            _FinancePill(label: '누적 선택지출', value: '${_money(totalSpent)}원'),
          ],
        ),
      ],
    ),
  );
}

class _FinancePill extends StatelessWidget {
  const _FinancePill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white24),
    ),
    child: Text(
      '$label · $value',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _FinanceNoticeCard extends StatelessWidget {
  const _FinanceNoticeCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFDCC38F)),
    ),
    child: const Text(
      '실제 유명 단지·빌딩은 공개 실거래 또는 실제 매각가를 기준점으로 씁니다. 가격·세금·대출 금리와 LTV는 시대 흐름을 반영한 게임용 단순화 수치입니다. 취득 부대비용은 현금으로 내며, 월세보다 원리금과 유지비가 크면 매달 현금이 줄어듭니다. 투자 권유가 아닙니다.',
      style: TextStyle(fontSize: 11, height: 1.5, fontWeight: FontWeight.w700),
    ),
  );
}

class _FinanceSectionTitle extends StatelessWidget {
  const _FinanceSectionTitle({
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
      Icon(icon, color: const Color(0xFF7D5035)),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            Text(
              caption,
              style: const TextStyle(fontSize: 10, color: Color(0xFF756B61)),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SpendingOptionCard extends StatelessWidget {
  const _SpendingOptionCard({
    required this.option,
    required this.lockReason,
    required this.busy,
    required this.onTap,
  });
  final SpendingOption option;
  final String? lockReason;
  final bool busy;
  final VoidCallback onTap;

  String get categoryLabel => switch (option.category) {
    SpendingCategory.family => '가족',
    SpendingCategory.education => '교육',
    SpendingCategory.business => '사업',
    SpendingCategory.realEstate => '부동산',
    SpendingCategory.social => '사회공헌',
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFD8C7A9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5A8),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                categoryLabel,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${_money(option.cost)}원',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          option.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          option.description,
          style: const TextStyle(fontSize: 11, height: 1.45),
        ),
        if (option.monthlyIncome != 0 || option.monthlyCost != 0) ...[
          const SizedBox(height: 6),
          Text(
            '월 수입 ${_money(option.monthlyIncome)}원 · 월 비용 ${_money(option.monthlyCost)}원',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF55715F),
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            key: Key('spending-option-${option.id}'),
            onPressed: lockReason == null && !busy ? onTap : null,
            child: Text(lockReason ?? '선택하기'),
          ),
        ),
      ],
    ),
  );
}

class _OwnedPropertyCard extends StatelessWidget {
  const _OwnedPropertyCard({
    required this.asset,
    required this.currentDay,
    required this.currentDate,
    required this.busy,
    required this.onSell,
    required this.leaseManagementAvailable,
    required this.onManageLease,
  });
  final OwnedRealEstate asset;
  final int currentDay;
  final DateTime currentDate;
  final bool busy;
  final VoidCallback onSell;
  final bool leaseManagementAvailable;
  final VoidCallback onManageLease;

  @override
  Widget build(BuildContext context) {
    final saleWaitFinished = currentDay - asset.acquiredDay >= 30;
    final canSell = saleWaitFinished && !asset.hasActiveLease;
    final saleActionLabel = asset.hasActiveLease
        ? '계약 종료 후 매각'
        : saleWaitFinished
        ? '매각 검토'
        : '30일 뒤 매각';
    final currentMarketValue = asset.estimatedMarketValue(currentDay);
    final saleValue = asset.estimatedSaleValue(currentDay);
    final saleNet = saleValue - asset.mortgageBalance;
    final recordedMarketPrice = asset.marketPriceAtPurchase > 0
        ? asset.marketPriceAtPurchase
        : asset.purchasePrice;
    final listing = asset.generatedListing;
    final latestEvent = listing?.latestVisibleEventAt(currentDate);
    final monthlyIncome = asset.monthlyIncomeAt(currentDate);
    final monthlyCost = asset.monthlyCostAt(currentDate);
    final assetType =
        asset.marketAsset?.type ?? RealEstateAssetType.commercialUnit;
    final directUse =
        asset.optionId == 'owner_office' ||
        asset.optionId == 'family_home_trust';
    final supportsManagedLease =
        realEstateSupportsManagedLease(assetType) && !directUse;
    final canManageLease =
        leaseManagementAvailable &&
        supportsManagedLease &&
        (!asset.hasActiveLease || asset.leaseRemainingMonths <= 0);
    final leaseActionLabel = !supportsManagedLease
        ? '직접 임대 불가'
        : asset.hasActiveLease
        ? '계약 ${asset.leaseRemainingMonths}개월 뒤 변경'
        : '임대 방식 선택';
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2E7),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF9FBEA1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            asset.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            '매매가 ${_money(recordedMarketPrice)}원 · 취득비용 ${_money(asset.acquisitionCosts)}원',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          Text(
            '총취득 ${_money(asset.purchasePrice)}원 · 현재 시세 ${_money(currentMarketValue)}원 · 매도 후 자기자본 ${_money(saleNet)}원',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          Text(
            '현재 월 임대 ${_money(monthlyIncome)}원 · 유지 ${_money(monthlyCost)}원'
            '${asset.hasMortgage ? ' · 원리금 ${_money(asset.monthlyMortgagePayment)}원' : ''}',
            style: const TextStyle(fontSize: 10),
          ),
          if (asset.hasMortgage)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 7),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: asset.mortgageMissedPayments > 0
                    ? const Color(0xFFFFE4DE)
                    : Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '대출잔액 ${_money(asset.mortgageBalance)}원 · '
                '연 ${(asset.mortgageAnnualInterestRate * 100).toStringAsFixed(2)}% · '
                '남은 ${asset.mortgageRemainingMonths}개월\n'
                '연체 ${asset.mortgageMissedPayments}/3회 · 실제 투입 현금 ${_money(asset.effectiveCashInvestedAtPurchase)}원',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 7),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: asset.rentArrearsMonths > 0
                  ? const Color(0xFFFFE4DE)
                  : const Color(0xFFE8EEF8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '임대 ${asset.leaseType.label}'
                  '${asset.hasActiveLease ? ' · 남은 ${asset.leaseRemainingMonths}개월' : ''}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (asset.hasActiveLease)
                  Text(
                    '반환할 보증금 ${_money(asset.leaseDeposit)}원 · '
                    '세입자 신뢰도 ${asset.tenantReliability} · '
                    '월세 연체 ${asset.rentArrearsMonths}개월',
                    style: const TextStyle(fontSize: 9),
                  ),
                Text(
                  '${asset.lastRentalEvent.isEmpty ? '새 임대 운영을 선택할 수 있습니다.' : asset.lastRentalEvent}'
                  '${asset.vacancyMonths > 0 ? ' · 공실 ${asset.vacancyMonths}개월' : ''}'
                  '${asset.totalRepairCosts > 0 ? ' · 누적 수리 ${_money(asset.totalRepairCosts)}원' : ''}',
                  style: const TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
          if (latestEvent != null)
            Text(
              '${latestEvent.title} · ${latestEvent.statusAt(currentDate)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8E4E48),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: Key('real-estate-lease-manage-${asset.id}'),
                  onPressed: canManageLease && !busy ? onManageLease : null,
                  child: Text(leaseActionLabel),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: OutlinedButton(
                  onPressed: canSell && !busy ? onSell : null,
                  child: Text(saleActionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdultChanceCard extends StatelessWidget {
  const _AdultChanceCard({
    required this.state,
    required this.busy,
    required this.onPlay,
  });
  final GameState state;
  final bool busy;
  final ValueChanged<int> onPlay;

  @override
  Widget build(BuildContext context) {
    final month =
        '${state.currentDate.year}-${state.currentDate.month.toString().padLeft(2, '0')}';
    final age = state.story.ageOn(state.currentDate);
    final unlocked = state.currentDate.year >= 2010 && age >= 20;
    final alreadyPlayed = state.personalFinance.lastChanceMonth == month;
    final onePercent = state.cash ~/ 100;
    final maxStake = onePercent < 100000 ? onePercent : 100000;
    final stakes = [
      10000,
      50000,
      100000,
    ].where((stake) => stake <= maxStake).toList(growable: false);
    return Container(
      key: const Key('adult-chance-card'),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2737),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '성인 확률 오락 · 선택 콘텐츠',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '60% 지급 없음 · 30% 1.5배 · 10% 3배 · 평균 지급률 75%\n월 1회, 현금의 최대 1%, 상한 10만원. 실제 돈·광고·결제 없음.',
            style: TextStyle(
              color: Color(0xFFD8D3E6),
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          if (!unlocked)
            const Text(
              '2010년 성인 시점에 해금됩니다.',
              style: TextStyle(
                color: Color(0xFFFFD27A),
                fontWeight: FontWeight.w900,
              ),
            )
          else if (alreadyPlayed)
            const Text(
              '이번 달 이용 완료',
              style: TextStyle(
                color: Color(0xFFFFD27A),
                fontWeight: FontWeight.w900,
              ),
            )
          else if (stakes.isEmpty)
            const Text(
              '현금 100만원 이상일 때 1만원부터 참여할 수 있습니다.',
              style: TextStyle(
                color: Color(0xFFFFD27A),
                fontWeight: FontWeight.w900,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stakes
                  .map(
                    (stake) => SizedBox(
                      height: 44,
                      child: FilledButton.tonal(
                        key: Key('adult-chance-$stake'),
                        onPressed: busy ? null : () => onPlay(stake),
                        child: Text('${_money(stake)}원'),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 8),
          Text(
            '누적 참가 ${_money(state.personalFinance.totalChanceStake)}원 · 지급 ${_money(state.personalFinance.totalChancePayout)}원',
            style: const TextStyle(color: Color(0xFFAFA8C1), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _FinanceEmptyCard extends StatelessWidget {
  const _FinanceEmptyCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(body, style: const TextStyle(fontSize: 11, height: 1.4)),
      ],
    ),
  );
}

class _AssetSpendingEntry extends StatelessWidget {
  const _AssetSpendingEntry({required this.state, required this.onTap});
  final GameState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFE7A8),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      key: const Key('open-asset-spending-button'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC28B38), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.real_estate_agent_rounded,
              color: Color(0xFF6B4425),
              size: 30,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '자산·소비 계획',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  Text(
                    '부동산 ${state.personalFinance.realEstate.length}건 · 교육·가족·사회공헌·성인 오락',
                    style: const TextStyle(fontSize: 9, height: 1.35),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
