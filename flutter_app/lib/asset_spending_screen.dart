part of 'main.dart';

enum _RealtorMood { welcome, explain, finance, concerned, approve, negotiate }

enum _RealEstateDetailTab {
  listing,
  price,
  returns,
  loan,
  tax,
  news,
  management,
}

class AssetSpendingScreen extends StatefulWidget {
  const AssetSpendingScreen({
    super.key,
    required this.state,
    required this.onPurchase,
    required this.onSellRealEstate,
    required this.onPlayChanceGame,
    this.onConfigureLease,
    this.onCancelSaleListing,
    this.onSaveInvestmentNote,
    this.onPrepayMortgage,
    this.onRefinanceMortgage,
    this.onRenovateRealEstate,
    this.onSetRealEstateInsurance,
    this.onRenewMonthlyLease,
    this.onTerminateMonthlyLeaseEarly,
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
  final Future<FinanceActionResult> Function(String assetId)?
  onCancelSaleListing;
  final Future<FinanceActionResult> Function(String assetId, String note)?
  onSaveInvestmentNote;
  final Future<FinanceActionResult> Function(String assetId, int amount)?
  onPrepayMortgage;
  final Future<FinanceActionResult> Function(
    String assetId, {
    required bool variableRate,
    int? termMonths,
  })?
  onRefinanceMortgage;
  final Future<FinanceActionResult> Function(String assetId)?
  onRenovateRealEstate;
  final Future<FinanceActionResult> Function(String assetId, bool active)?
  onSetRealEstateInsurance;
  final Future<FinanceActionResult> Function(String assetId)?
  onRenewMonthlyLease;
  final Future<FinanceActionResult> Function(String assetId)?
  onTerminateMonthlyLeaseEarly;
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
  _RealtorMood _realtorMood = _RealtorMood.welcome;
  bool _realtorGuideVisible = true;
  final Map<String, String> _realEstateNotes = <String, String>{};

  void _showRealtorMood(_RealtorMood mood) {
    if (!widget.realEstateOnly || !mounted) return;
    setState(() {
      _realtorMood = mood;
      _realtorGuideVisible = true;
    });
  }

  RealEstatePurchaseQuote _listingQuote(GeneratedRealEstateListing listing) =>
      realEstatePortfolioAdjustedPurchaseQuote(
        baseQuote: listing.quoteAt(_state.currentDate),
        date: _state.currentDate,
        type: listing.asset.type,
        ownedHousingCount: _state.personalFinance.ownedHousingCount,
      );

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
    final quote = _listingQuote(listing);
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
    _RealtorMood? successRealtorMood,
    _RealtorMood? failureRealtorMood,
  }) async {
    if (_busy || !await _confirm(title, body, confirmLabel)) return;
    setState(() => _busy = true);
    try {
      final result = await action();
      if (!mounted) return;
      setState(() {
        if (result.success) _state = result.state;
        if (widget.realEstateOnly) {
          final nextMood = result.success
              ? successRealtorMood
              : failureRealtorMood;
          if (nextMood != null) {
            _realtorMood = nextMood;
            _realtorGuideVisible = true;
          }
        }
      });
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
      if (mounted) {
        if (widget.realEstateOnly && failureRealtorMood != null) {
          setState(() {
            _realtorMood = failureRealtorMood;
            _realtorGuideVisible = true;
          });
        }
        _showSaveFailure(context);
      }
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

  Future<void> _sell(OwnedRealEstate asset) {
    _showRealtorMood(_RealtorMood.negotiate);
    final offer = asset.estimatedSaleOfferValue(_state.day);
    final tax = realEstateCapitalGainsTax(
      saleDate: _state.currentDate,
      type: asset.assetType,
      ownedHousingCount: _state.personalFinance.ownedHousingCount,
      holdingDays: _state.day - asset.acquiredDay,
      netSaleBeforeTax: offer,
      purchaseCost: asset.purchasePrice,
    );
    final listed = asset.saleListedDay > 0;
    final ready = listed && _state.day >= asset.saleOfferReadyDay;
    final body = !listed
        ? '즉시 매각되지 않습니다. 매물 등록 후 자산 종류에 따라 일정 기간 '
              '매수자를 기다리고 제안가를 확인합니다. 급매 제안은 시세보다 낮을 수 있습니다.'
        : !ready
        ? '매수자 제안까지 ${asset.saleOfferReadyDay - _state.day}일 남았습니다.'
        : '매수자 제안 ${_money(offer)}원\n'
              '담보대출 상환 ${_money(asset.mortgageBalance)}원\n'
              '예상 양도세·단기매매 중과 ${_money(tax)}원\n'
              '예상 순수령 ${_money(offer - asset.mortgageBalance - tax)}원';
    return _run(
      () => widget.onSellRealEstate(asset.id),
      title: listed ? '${asset.name} 매수자 제안' : '${asset.name} 매각 등록',
      body: body,
      confirmLabel: ready ? '제안 수락' : '확인',
      successRealtorMood: _RealtorMood.approve,
      failureRealtorMood: _RealtorMood.concerned,
    );
  }

  Future<void> _manageLease(OwnedRealEstate asset) async {
    final handler = widget.onConfigureLease;
    if (handler == null) return;
    _showRealtorMood(_RealtorMood.negotiate);
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
                  mortgageBalance: asset.mortgageBalance,
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
    final marketValue = asset.estimatedMarketValue(_state.day);
    final terms = realEstateLeaseTermsAt(
      date: _state.currentDate,
      type: assetType,
      leaseType: selected,
      marketValue: marketValue,
      marketMonthlyRent: marketRent,
      mortgageBalance: asset.mortgageBalance,
    );
    final combinedLiability = asset.mortgageBalance + terms.deposit;
    final combinedRate = marketValue <= 0
        ? 0.0
        : combinedLiability * 100 / marketValue;
    final combinedLimit =
        realEstateMaximumCombinedLiabilityRate(_state.currentDate, assetType) *
        100;
    final body = selected == RealEstateLeaseType.vacant
        ? '임대수입 없이 공실로 전환합니다. 공실 중에도 유지비와 수리 사건은 발생합니다.'
        : '${selected.label} ${terms.contractMonths}개월 계약\n'
              '보증금 ${_money(terms.deposit)}원 · 월세 ${_money(terms.monthlyRent)}원\n'
              '담보대출+보증금 ${_money(combinedLiability)}원 '
              '(${combinedRate.toStringAsFixed(1)}% / 한도 ${combinedLimit.toStringAsFixed(0)}%)\n'
              '중개·입주 정비비 ${_money(terms.placementFee)}원\n'
              '계약 만료 때 보증금을 돌려주지 못하면 경매 위험이 있습니다.';
    return _run(
      () => handler(asset.id, selected),
      title: '${asset.name} ${selected.label}',
      body: body,
      confirmLabel: '계약 확정',
      successRealtorMood: _RealtorMood.approve,
      failureRealtorMood: _RealtorMood.concerned,
    );
  }

  Future<void> _cancelSaleListing(OwnedRealEstate asset) async {
    final handler = widget.onCancelSaleListing;
    if (handler == null) return;
    _showRealtorMood(_RealtorMood.negotiate);
    await _run(
      () => handler(asset.id),
      title: '${asset.name} 매각 등록 취소',
      body: '진행 중인 매각 등록과 도착한 제안을 취소합니다. 나중에 다시 등록할 수 있습니다.',
      confirmLabel: '등록 취소',
      successRealtorMood: _RealtorMood.approve,
      failureRealtorMood: _RealtorMood.concerned,
    );
  }

  Future<void> _prepayMortgage(OwnedRealEstate asset, int amount) async {
    final handler = widget.onPrepayMortgage;
    if (handler == null) return;
    final principal = math.min(amount, asset.mortgageBalance);
    final fee = (principal * realEstateMortgagePrepaymentFeeRate).round();
    await _run(
      () => handler(asset.id, amount),
      title: '${asset.name} 중도상환',
      body:
          '상환 원금 ${_money(principal)}원\n'
          '중도상환 수수료 ${_money(fee)}원\n'
          '회사 통장에서 총 ${_money(principal + fee)}원이 나갑니다.',
      confirmLabel: '중도상환 실행',
      successRealtorMood: _RealtorMood.approve,
      failureRealtorMood: _RealtorMood.concerned,
    );
  }

  Future<void> _refinanceMortgage(
    OwnedRealEstate asset, {
    required bool variableRate,
    int? termMonths,
  }) async {
    final handler = widget.onRefinanceMortgage;
    if (handler == null) return;
    final terms = realEstateFinancingTermsAt(
      _state.currentDate,
      asset.assetType,
    );
    final rate = math.max(
      0.001,
      terms.annualInterestRate -
          (variableRate ? realEstateVariableMortgageDiscountRate : 0),
    );
    final months = termMonths ?? terms.termMonths;
    await _run(
      () =>
          handler(asset.id, variableRate: variableRate, termMonths: termMonths),
      title: '${asset.name} 대환대출',
      body:
          '${variableRate ? '변동' : '고정'}금리 연 ${(rate * 100).toStringAsFixed(2)}%\n'
          '$months개월 · 예상 월 원리금 '
          '${_money(mortgageMonthlyPayment(asset.mortgageBalance, rate, months))}원\n'
          '대환 비용과 DSR·신용 심사를 다시 확인합니다.',
      confirmLabel: '대환 신청',
      successRealtorMood: _RealtorMood.approve,
      failureRealtorMood: _RealtorMood.concerned,
    );
  }

  Future<void> _renovateRealEstate(OwnedRealEstate asset) async {
    final handler = widget.onRenovateRealEstate;
    if (handler == null) return;
    final marketValue = asset.estimatedMarketValue(_state.day);
    final cost = realEstateRenovationCost(marketValue);
    final conditionGain = math.min(25, 100 - asset.propertyCondition);
    await _run(
      () => handler(asset.id),
      title: '${asset.name} 리모델링',
      body:
          '현재 상태 ${asset.propertyCondition}/100 → '
          '예상 ${asset.propertyCondition + conditionGain}/100\n'
          '예상 비용 ${_money(cost)}원\n'
          '공사 중에는 활성 임대계약이 없어야 하며, 매각 등록과 제안은 취소됩니다.',
      confirmLabel: '리모델링 실행',
      successRealtorMood: _RealtorMood.approve,
      failureRealtorMood: _RealtorMood.concerned,
    );
  }

  Future<void> _setRealEstateInsurance(
    OwnedRealEstate asset,
    bool active,
  ) async {
    final handler = widget.onSetRealEstateInsurance;
    if (handler == null) return;
    final premium = realEstateMonthlyInsurancePremium(
      asset.estimatedMarketValue(_state.day),
    );
    await _run(
      () => handler(asset.id, active),
      title: '${asset.name} 재산보험 ${active ? '가입' : '해지'}',
      body: active
          ? '월 보험료 약 ${_money(premium)}원이 다음 월 정산부터 청구됩니다.\n'
                '대형 수리 사건은 자기부담금을 뺀 보상 대상 비용의 70%를 회수합니다.'
          : '보험을 해지하면 다음 월부터 보험료가 없지만 대형 수리 사건을 전액 부담합니다.',
      confirmLabel: active ? '보험 가입' : '보험 해지',
      successRealtorMood: _RealtorMood.approve,
      failureRealtorMood: _RealtorMood.concerned,
    );
  }

  Future<void> _renewMonthlyLease(OwnedRealEstate asset) async {
    final handler = widget.onRenewMonthlyLease;
    if (handler == null) return;
    final marketRent =
        asset.generatedListing?.monthlyRentAt(_state.currentDate) ??
        asset.marketAsset?.monthlyRentAt(_state.currentDate) ??
        asset.leaseMonthlyRent;
    final terms = realEstateLeaseTermsAt(
      date: _state.currentDate,
      type: asset.assetType,
      leaseType: RealEstateLeaseType.monthlyRent,
      marketValue: asset.estimatedMarketValue(_state.day),
      marketMonthlyRent: marketRent,
      mortgageBalance: asset.mortgageBalance,
    );
    final depositDelta = terms.deposit - asset.leaseDeposit;
    final renewalFee = math.max(100000, terms.monthlyRent ~/ 2);
    await _run(
      () => handler(asset.id),
      title: '${asset.name} 월세 계약 갱신',
      body:
          '새 계약 ${terms.contractMonths}개월 · 월세 ${_money(terms.monthlyRent)}원\n'
          '새 보증금 ${_money(terms.deposit)}원 '
          '(${depositDelta >= 0 ? '+' : '-'}${_money(depositDelta.abs())}원)\n'
          '갱신 비용 ${_money(renewalFee)}원 · 연체 월세와 총부채 한도를 다시 확인합니다.',
      confirmLabel: '계약 갱신',
      successRealtorMood: _RealtorMood.approve,
      failureRealtorMood: _RealtorMood.concerned,
    );
  }

  Future<void> _terminateMonthlyLeaseEarly(OwnedRealEstate asset) async {
    final handler = widget.onTerminateMonthlyLeaseEarly;
    if (handler == null) return;
    final rentClaim = math.min(
      asset.leaseDeposit,
      asset.leaseMonthlyRent * asset.rentArrearsMonths,
    );
    final depositRefund = asset.leaseDeposit - rentClaim;
    final legalCost = realEstateEarlyLeaseTerminationLegalCost(
      asset.leaseMonthlyRent,
    );
    await _run(
      () => handler(asset.id),
      title: '${asset.name} 월세 계약 중도 종료',
      body:
          '보증금 반환 ${_money(depositRefund)}원\n'
          '${rentClaim > 0 ? '연체 월세 상계 ${_money(rentClaim)}원\n' : ''}'
          '합의·법무 비용 ${_money(legalCost)}원\n'
          '회사 통장에서 총 ${_money(depositRefund + legalCost)}원이 나가고 매물은 공실로 전환됩니다.',
      confirmLabel: '중도 종료 확정',
      successRealtorMood: _RealtorMood.negotiate,
      failureRealtorMood: _RealtorMood.concerned,
    );
  }

  Future<void> _saveOwnedInvestmentNote(
    OwnedRealEstate asset,
    String note,
  ) async {
    final handler = widget.onSaveInvestmentNote;
    if (handler == null) {
      if (mounted) {
        setState(() => _realEstateNotes[asset.optionId] = note);
      }
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await handler(asset.id, note);
      if (!mounted) return;
      setState(() {
        if (result.success) {
          _state = result.state;
          _realEstateNotes[asset.optionId] = note;
        }
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    } catch (_) {
      if (mounted) _showSaveFailure(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<int?> _chooseFinancingLtv(GeneratedRealEstateListing listing) async {
    _showRealtorMood(_RealtorMood.finance);
    final quote = _listingQuote(listing);
    final terms = realEstateFinancingTermsAt(
      _state.currentDate,
      listing.asset.type,
    );
    if (!terms.available) return 0;
    final choices = <int>[
      0,
      for (var ltv = 10; ltv <= terms.maxLtvPercent; ltv += 10) ltv,
      if (terms.maxLtvPercent % 10 != 0) terms.maxLtvPercent,
    ];
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
                '취득세·중개비 등 부대비용은 대출이 아니라 현금으로 냅니다.\n'
                'DSR 45%와 추가 매입 총부채 60% 제한을 모두 통과해야 합니다.',
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

  Future<void> _purchaseListing(
    GeneratedRealEstateListing listing, {
    int? selectedLtvPercent,
  }) async {
    final quote = _listingQuote(listing);
    final terms = realEstateFinancingTermsAt(
      _state.currentDate,
      listing.asset.type,
    );
    final selectedLtv =
        selectedLtvPercent ?? await _chooseFinancingLtv(listing);
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
      successRealtorMood: _RealtorMood.approve,
      failureRealtorMood: _RealtorMood.concerned,
    );
  }

  Future<void> _openListingDetail(GeneratedRealEstateListing listing) async {
    _showRealtorMood(_RealtorMood.explain);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => _RealEstateDetailScreen(
          listing: listing,
          state: _state,
          ownedHousingCount: _state.personalFinance.ownedHousingCount,
          lockReason: _listingLockReason(listing),
          initialNote: _realEstateNotes[listing.optionId] ?? '',
          onNoteSaved: (note) async {
            if (!mounted) return;
            setState(() => _realEstateNotes[listing.optionId] = note);
          },
          onPurchase: (ltv) =>
              _purchaseListing(listing, selectedLtvPercent: ltv),
        ),
      ),
    );
  }

  Future<void> _openOwnedDetail(OwnedRealEstate owned) async {
    final listing =
        owned.generatedListing ??
        (owned.marketAsset == null
            ? null
            : realEstateListingsFor(
                owned.marketAsset!,
                _state.simulationSeed,
              ).first);
    if (listing == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('이 자산은 상세 시세 데이터가 준비되지 않았습니다.')),
        );
      return;
    }
    _showRealtorMood(_RealtorMood.explain);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => _RealEstateDetailScreen(
          listing: listing,
          state: _state,
          ownedHousingCount: _state.personalFinance.ownedHousingCount,
          owned: owned,
          initialNote: owned.investmentNote.isNotEmpty
              ? owned.investmentNote
              : _realEstateNotes[owned.optionId] ?? '',
          onNoteSaved: (note) => _saveOwnedInvestmentNote(owned, note),
          onSell: () => _sell(owned),
          onCancelSale: widget.onCancelSaleListing == null
              ? null
              : () => _cancelSaleListing(owned),
          onManageLease: widget.onConfigureLease == null
              ? null
              : () => _manageLease(owned),
          onPrepayMortgage: widget.onPrepayMortgage == null
              ? null
              : (amount) => _prepayMortgage(owned, amount),
          onRefinanceMortgage: widget.onRefinanceMortgage == null
              ? null
              : ({required variableRate, termMonths}) => _refinanceMortgage(
                  owned,
                  variableRate: variableRate,
                  termMonths: termMonths,
                ),
          onRenovate: widget.onRenovateRealEstate == null
              ? null
              : () => _renovateRealEstate(owned),
          onSetInsurance: widget.onSetRealEstateInsurance == null
              ? null
              : (active) => _setRealEstateInsurance(owned, active),
          onRenewMonthlyLease: widget.onRenewMonthlyLease == null
              ? null
              : () => _renewMonthlyLease(owned),
          onTerminateMonthlyLeaseEarly:
              widget.onTerminateMonthlyLeaseEarly == null
              ? null
              : () => _terminateMonthlyLeaseEarly(owned),
        ),
      ),
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
              if (widget.realEstateOnly) ...[
                if (_realtorGuideVisible)
                  _RealtorGuideCard(
                    mood: _realtorMood,
                    onConsult: () => _showRealtorMood(_RealtorMood.explain),
                    onDismiss: () =>
                        setState(() => _realtorGuideVisible = false),
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('real-estate-realtor-reopen'),
                      onPressed: () => _showRealtorMood(_RealtorMood.welcome),
                      icon: const Icon(Icons.support_agent_rounded, size: 18),
                      label: const Text('중개사 상담 다시 열기'),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              _FinanceOverviewCard(
                cash: _state.cash,
                propertyValue: propertyValue,
                monthlyPropertyNet:
                    finance.monthlyPropertyIncomeAt(_state.currentDate) -
                    finance.monthlyPropertyCostAt(_state.currentDate) -
                    finance.monthlyPropertyHoldingTaxAt(
                      _state.day,
                      _state.currentDate,
                    ) -
                    finance.monthlyMortgagePayment,
                totalSpent: finance.totalSpent,
                totalMortgageBalance: finance.totalMortgageBalance,
                totalTenantDeposits: finance.totalTenantDepositLiability,
                tenantDepositDebt: _state.story.flagInt('tenantDepositDebt'),
                propertyEquity: finance.propertyEquityAt(_state.day),
                totalKnownLiabilities: _state.totalKnownLiabilities,
                netWorth: _state.balanceSheetNetWorth(),
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
                ownedHousingCount: finance.ownedHousingCount,
                busy: _busy,
                lockReason: _listingLockReason,
                onTierSelected: (tier) => setState(() {
                  _selectedPropertyTier = tier;
                  _selectedPropertyDistrictId = null;
                  if (widget.realEstateOnly) {
                    _realtorMood = _RealtorMood.explain;
                    _realtorGuideVisible = true;
                  }
                }),
                onDistrictSelected: (districtId) => setState(() {
                  _selectedPropertyDistrictId = districtId;
                  if (widget.realEstateOnly) {
                    _realtorMood = _RealtorMood.explain;
                    _realtorGuideVisible = true;
                  }
                }),
                onPurchase: _openListingDetail,
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
                      worldSeed: _state.simulationSeed,
                      ownedHousingCount: finance.ownedHousingCount,
                      busy: _busy,
                      onSell: () => _sell(asset),
                      leaseManagementAvailable: widget.onConfigureLease != null,
                      onManageLease: () => _manageLease(asset),
                      onOpenDetail: () => _openOwnedDetail(asset),
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

class _RealtorGuideCard extends StatelessWidget {
  const _RealtorGuideCard({
    required this.mood,
    required this.onConsult,
    required this.onDismiss,
  });

  final _RealtorMood mood;
  final VoidCallback onConsult;
  final VoidCallback onDismiss;

  String get _asset => switch (mood) {
    _RealtorMood.welcome => 'assets/images/character_realtor_welcome_v1.png',
    _RealtorMood.explain => 'assets/images/character_realtor_explain_v1.png',
    _RealtorMood.finance => 'assets/images/character_realtor_finance_v1.png',
    _RealtorMood.concerned =>
      'assets/images/character_realtor_concerned_v1.png',
    _RealtorMood.approve => 'assets/images/character_realtor_approve_v1.png',
    _RealtorMood.negotiate =>
      'assets/images/character_realtor_negotiate_v1.png',
  };

  String get _line => switch (mood) {
    _RealtorMood.welcome => '어서 오세요. 지역을 고르면 매물과 대출 위험을 함께 짚어드릴게요.',
    _RealtorMood.explain => '지도에는 지금 공개된 정보만 보여요. 가격뿐 아니라 공실과 지역 사건도 확인하세요.',
    _RealtorMood.finance => '취득비는 현금, 대출은 원리금이에요. LTV와 월 순현금을 함께 비교해요.',
    _RealtorMood.concerned => '조건을 다시 볼게요. 현금·DSR·총부채 한도 중 막힌 항목이 있을 수 있어요.',
    _RealtorMood.approve => '계약이 반영됐어요. 이제 원리금·공실·보유세를 뺀 순현금을 관리하세요.',
    _RealtorMood.negotiate => '매각 제안과 임대 조건을 살펴볼게요. 보증금은 돌려줘야 하는 부채예요.',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('real-estate-realtor-slot'),
      constraints: const BoxConstraints(minHeight: 166),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD3AE72), width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          KeyedSubtree(
            key: const Key('real-estate-realtor-character'),
            child: SizedBox(
              width: 108,
              height: 166,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Image.asset(
                  _asset,
                  key: ValueKey(_asset),
                  alignment: Alignment.bottomCenter,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Align(
                    alignment: Alignment.bottomCenter,
                    child: Icon(
                      Icons.support_agent_rounded,
                      color: Color(0xFF7A593B),
                      size: 62,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 12, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    key: Key('real-estate-realtor-${mood.name}'),
                    width: 0,
                    height: 0,
                  ),
                  const Text(
                    '서하늘 공인중개사',
                    style: TextStyle(
                      color: Color(0xFF493326),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _line,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF655548),
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 3,
                    runSpacing: 2,
                    children: [
                      TextButton.icon(
                        key: const Key('real-estate-realtor-consult'),
                        onPressed: onConsult,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.map_outlined, size: 15),
                        label: const Text(
                          '시장 안내',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        key: const Key('real-estate-realtor-dismiss'),
                        onPressed: onDismiss,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          '상담 접기',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RealEstateDetailScreen extends StatefulWidget {
  const _RealEstateDetailScreen({
    required this.listing,
    required this.state,
    required this.ownedHousingCount,
    required this.initialNote,
    required this.onNoteSaved,
    this.owned,
    this.lockReason,
    this.onPurchase,
    this.onSell,
    this.onCancelSale,
    this.onManageLease,
    this.onPrepayMortgage,
    this.onRefinanceMortgage,
    this.onRenovate,
    this.onSetInsurance,
    this.onRenewMonthlyLease,
    this.onTerminateMonthlyLeaseEarly,
  });

  final GeneratedRealEstateListing listing;
  final GameState state;
  final int ownedHousingCount;
  final OwnedRealEstate? owned;
  final String? lockReason;
  final Future<void> Function(int ltvPercent)? onPurchase;
  final Future<void> Function()? onSell;
  final Future<void> Function()? onCancelSale;
  final Future<void> Function()? onManageLease;
  final Future<void> Function(int amount)? onPrepayMortgage;
  final Future<void> Function({required bool variableRate, int? termMonths})?
  onRefinanceMortgage;
  final Future<void> Function()? onRenovate;
  final Future<void> Function(bool active)? onSetInsurance;
  final Future<void> Function()? onRenewMonthlyLease;
  final Future<void> Function()? onTerminateMonthlyLeaseEarly;
  final String initialNote;
  final Future<void> Function(String note) onNoteSaved;

  @override
  State<_RealEstateDetailScreen> createState() =>
      _RealEstateDetailScreenState();
}

class _RealEstateDetailScreenState extends State<_RealEstateDetailScreen> {
  late final TextEditingController _noteController;
  int _selectedLtv = 0;
  bool _actionBusy = false;
  bool _noteSaving = false;
  bool _noteSaved = false;

  GeneratedRealEstateListing get _listing => widget.listing;
  RealEstateMarketAsset get _asset => _listing.asset;
  DateTime get _date => widget.state.currentDate;
  OwnedRealEstate? get _owned => widget.owned;

  RealEstatePurchaseQuote get _quote =>
      realEstatePortfolioAdjustedPurchaseQuote(
        baseQuote: _listing.quoteAt(_date),
        date: _date,
        type: _asset.type,
        ownedHousingCount: widget.ownedHousingCount,
      );

  RealEstateFinancingTerms get _terms =>
      realEstateFinancingTermsAt(_date, _asset.type);

  RealEstateFinancingPlan get _plan => _terms.planFor(_quote, _selectedLtv);

  List<_RealEstateDetailTab> get _tabs => <_RealEstateDetailTab>[
    _RealEstateDetailTab.listing,
    _RealEstateDetailTab.price,
    _RealEstateDetailTab.returns,
    _RealEstateDetailTab.loan,
    _RealEstateDetailTab.tax,
    _RealEstateDetailTab.news,
    if (_owned != null) _RealEstateDetailTab.management,
  ];

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _tabLabel(_RealEstateDetailTab tab) => switch (tab) {
    _RealEstateDetailTab.listing => '매물',
    _RealEstateDetailTab.price => '시세',
    _RealEstateDetailTab.returns => '수익',
    _RealEstateDetailTab.loan => '대출',
    _RealEstateDetailTab.tax => '세금',
    _RealEstateDetailTab.news => '지역뉴스',
    _RealEstateDetailTab.management => '보유관리',
  };

  List<int> get _ltvChoices => <int>[
    0,
    for (var ltv = 10; ltv <= _terms.maxLtvPercent; ltv += 10) ltv,
    if (_terms.maxLtvPercent % 10 != 0) _terms.maxLtvPercent,
  ];

  RealEstateInvestmentAnalysis get _analysis => _owned == null
      ? analyzeRealEstateListing(
          listing: _listing,
          asOf: _date,
          requestedLtvPercent: _selectedLtv,
          ownedHousingCount: widget.ownedHousingCount,
        )
      : analyzeOwnedRealEstate(
          asset: _owned!,
          currentDay: widget.state.day,
          asOf: _date,
          ownedHousingCount: widget.ownedHousingCount,
        );

  double get _expectedVacancyRate => _analysis.expectedVacancyRate;

  int get _monthlyRent => _analysis.grossMonthlyRent;

  int get _monthlyOperatingCost => _analysis.monthlyOperatingCost;

  int get _marketValue => _analysis.marketValue;

  int get _monthlyHoldingTax => _analysis.monthlyHoldingTax;

  int get _monthlyVacancyReserve => _analysis.expectedMonthlyVacancyLoss;

  int get _monthlyRepairReserve => _analysis.monthlyRepairReserve;

  int get _monthlyNoi => _analysis.monthlyNoi;

  int get _monthlyDebtService => _analysis.monthlyDebtService;

  RealEstateBorrowingAssessment get _borrowingAssessment =>
      assessRealEstateBorrowing(
        plan: _plan,
        existingMortgageBalance:
            widget.state.personalFinance.totalMortgageBalance,
        existingNonMortgageDebt: math.max(
          0,
          widget.state.totalKnownLiabilities -
              widget.state.personalFinance.totalMortgageBalance,
        ),
        existingMonthlyDebtService:
            widget.state.personalFinance.monthlyMortgagePayment +
            widget.state.banking.monthlyUnsecuredDebtService,
        existingPropertyValue: widget.state.personalFinance
            .estimatedPropertyValueAt(widget.state.day),
        targetPropertyValue: _quote.marketPrice,
        existingPropertyCount: widget.state.personalFinance.realEstate.length,
        qualifyingMonthlyIncome: gameRealEstateQualifyingMonthlyIncome(
          widget.state,
          targetMonthlyRent: _listing.monthlyRentAt(_date),
        ),
      );

  int get _estimatedCompletionYear {
    final ageAtListing = switch (_asset.type) {
      RealEstateAssetType.villa => 14 + _listing.index * 3,
      RealEstateAssetType.officetel => 8 + _listing.index * 2,
      RealEstateAssetType.apartment => 10 + _listing.index * 3,
      RealEstateAssetType.commercialUnit => 12 + _listing.index * 4,
      RealEstateAssetType.officeBuilding => 9 + _listing.index * 4,
      RealEstateAssetType.landmarkFund => 6 + _listing.index * 2,
    };
    return math.max(1965, _asset.availableFrom.year - ageAtListing);
  }

  String get _moveInStatus => switch (_listing.condition) {
    RealEstateListingCondition.needsRepair => '수리 후 입주 협의',
    RealEstateListingCondition.average => '잔금 후 입주 협의',
    RealEstateListingCondition.renovated => '즉시 입주 가능',
  };

  Future<void> _purchase() async {
    final callback = widget.onPurchase;
    if (callback == null || _actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      await callback(_selectedLtv);
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _requestMortgagePrepayment() async {
    final owned = _owned;
    final callback = widget.onPrepayMortgage;
    if (owned == null || callback == null || !owned.hasMortgage) return;
    final maximumByCash =
        (widget.state.bankCash / (1 + realEstateMortgagePrepaymentFeeRate))
            .floor();
    final maximum = math.min(owned.mortgageBalance, maximumByCash);
    final controller = TextEditingController(
      text: maximum > 0 ? maximum.toString() : '',
    );
    final amount = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFBF2),
      builder: (sheetContext) {
        String error = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void submit() {
              final value =
                  int.tryParse(controller.text.replaceAll(',', '').trim()) ?? 0;
              if (value <= 0 || value > maximum) {
                setSheetState(() {
                  error = maximum <= 0
                      ? '현재 상환 가능한 회사 통장 잔액이 없습니다.'
                      : '1원부터 ${_money(maximum)}원까지 입력하세요.';
                });
                return;
              }
              Navigator.of(sheetContext).pop(value);
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                18 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '담보대출 중도상환',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '대출잔액 ${_money(owned.mortgageBalance)}원 · '
                    '회사 통장 ${_money(widget.state.bankCash)}원 · '
                    '수수료 ${(realEstateMortgagePrepaymentFeeRate * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Color(0xFF71665C),
                      fontSize: 10.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('real-estate-prepay-input'),
                    controller: controller,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setSheetState(() => error = ''),
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: '상환 원금',
                      suffixText: '원',
                      errorText: error.isEmpty ? null : error,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final ratio in const <double>[0.1, 0.25, 0.5, 1])
                        ActionChip(
                          label: Text(
                            ratio == 1 ? '최대' : '${(ratio * 100).round()}%',
                          ),
                          onPressed: maximum <= 0
                              ? null
                              : () {
                                  controller.text = math
                                      .max(1, (maximum * ratio).floor())
                                      .toString();
                                  setSheetState(() => error = '');
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('real-estate-prepay-confirm'),
                    onPressed: maximum <= 0 ? null : submit,
                    child: const Text('상환 금액 확인'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    if (amount != null && mounted) await callback(amount);
  }

  Future<void> _requestMortgageRefinance() async {
    final owned = _owned;
    final callback = widget.onRefinanceMortgage;
    if (owned == null || callback == null || !owned.hasMortgage) return;
    final terms = realEstateFinancingTermsAt(_date, owned.assetType);
    if (!terms.available) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('현재 이용 가능한 대환 상품이 없습니다.')));
      return;
    }
    final termChoices = <int>{120, 180, terms.termMonths}.toList()..sort();
    final selection = await showModalBottomSheet<(bool, int)>(
      context: context,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFFBF2),
      builder: (sheetContext) {
        var variableRate = owned.mortgageIsVariableRate;
        var selectedTerm = terms.termMonths;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final rate = math.max(
              0.001,
              terms.annualInterestRate -
                  (variableRate ? realEstateVariableMortgageDiscountRate : 0),
            );
            final payment = mortgageMonthlyPayment(
              owned.mortgageBalance,
              rate,
              selectedTerm,
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '담보대출 대환',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${terms.eraLabel} · 잔액 ${_money(owned.mortgageBalance)}원',
                    style: const TextStyle(
                      color: Color(0xFF71665C),
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    key: const Key('real-estate-refinance-rate-type'),
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('고정금리')),
                      ButtonSegment(value: true, label: Text('변동금리')),
                    ],
                    selected: {variableRate},
                    onSelectionChanged: (value) =>
                        setSheetState(() => variableRate = value.first),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final months in termChoices)
                        ChoiceChip(
                          key: Key('real-estate-refinance-term-$months'),
                          selected: selectedTerm == months,
                          onSelected: (_) =>
                              setSheetState(() => selectedTerm = months),
                          label: Text('${months ~/ 12}년'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailMetricGrid(
                    items: [
                      _DetailMetricData(
                        '예상 금리',
                        '연 ${(rate * 100).toStringAsFixed(2)}%',
                      ),
                      _DetailMetricData('예상 월 원리금', '${_money(payment)}원'),
                    ],
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    '변동금리는 시작 금리가 낮지만 매년 기준금리에 따라 달라질 수 있습니다. '
                    '실행 시 대환비용·신용·DSR을 다시 심사합니다.',
                    style: TextStyle(
                      color: Color(0xFF71665C),
                      fontSize: 10,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('real-estate-refinance-confirm'),
                    onPressed: () => Navigator.of(
                      sheetContext,
                    ).pop((variableRate, selectedTerm)),
                    child: const Text('대환 조건 확인'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (selection != null && mounted) {
      await callback(variableRate: selection.$1, termMonths: selection.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final plan = _plan;
    final hasPurchaseCash = widget.state.bankCash >= plan.cashRequired;
    final canPurchase =
        _owned == null &&
        widget.onPurchase != null &&
        widget.lockReason == null &&
        hasPurchaseCash;
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        key: const Key('real-estate-detail-screen'),
        backgroundColor: const Color(0xFFF3EBDD),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F0E4),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _listing.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${_asset.province} ${_asset.region} · ${_asset.type.label}',
                style: const TextStyle(
                  color: Color(0xFF75675D),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
            tabs: [
              for (final tab in tabs)
                Tab(
                  key: Key('real-estate-detail-tab-${tab.name}'),
                  text: _tabLabel(tab),
                ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final tab in tabs)
              switch (tab) {
                _RealEstateDetailTab.listing => _buildListingTab(),
                _RealEstateDetailTab.price => _buildPriceTab(),
                _RealEstateDetailTab.returns => _buildReturnsTab(),
                _RealEstateDetailTab.loan => _buildLoanTab(),
                _RealEstateDetailTab.tax => _buildTaxTab(),
                _RealEstateDetailTab.news => _buildNewsTab(),
                _RealEstateDetailTab.management => _buildManagementTab(),
              },
          ],
        ),
        bottomNavigationBar: _owned != null
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  key: const Key('real-estate-detail-purchase-bar'),
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFBF2),
                    border: Border(top: BorderSide(color: Color(0xFFD8C7A9))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '필요 현금 ${_money(plan.cashRequired)}원',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '회사 통장 ${_money(widget.state.bankCash)}원'
                              '${plan.hasMortgage ? ' · LTV ${plan.appliedLtvPercent}%' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasPurchaseCash
                                    ? const Color(0xFF5D6C61)
                                    : const Color(0xFFB34B3E),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        key: const Key('real-estate-detail-purchase'),
                        onPressed: canPurchase && !_actionBusy
                            ? _purchase
                            : null,
                        child: Text(
                          _actionBusy
                              ? '처리 중'
                              : widget.lockReason ??
                                    (hasPurchaseCash ? '매입 확인' : '현금 부족'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _detailList({required Key key, required List<Widget> children}) =>
      ListView(
        key: key,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 34),
        children: children,
      );

  Widget _buildListingTab() {
    final quote = _quote;
    final pricePerSquareMeter =
        quote.marketPrice ~/ math.max(1, _listing.areaSquareMeters.round());
    return _detailList(
      key: const Key('real-estate-detail-listing-panel'),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.asset(
              _asset.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFE4D4BE),
                child: Center(child: Icon(Icons.apartment_rounded, size: 64)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _RealEstateDetailSection(
          title: '매물 핵심',
          icon: Icons.home_work_outlined,
          child: Column(
            children: [
              _DetailInfoRow(
                label: '주소',
                value: '${_asset.province} ${_asset.region} ${_asset.name}',
              ),
              _DetailInfoRow(
                label: '면적·층',
                value:
                    '${_listing.areaSquareMeters.toStringAsFixed(1)}㎡ · ${_listing.floor}층',
              ),
              _DetailInfoRow(
                label: '준공',
                value: '$_estimatedCompletionYear년 · 게임 추정',
              ),
              _DetailInfoRow(
                label: '상태·입주',
                value: '${_listing.condition.label} · $_moveInStatus',
              ),
              _DetailInfoRow(
                label: '교통',
                value: '가까운 역 도보 ${_listing.stationWalkMinutes}분',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _DetailMetricGrid(
          items: [
            _DetailMetricData('호가', '${_money(quote.marketPrice)}원'),
            _DetailMetricData('㎡당가', '${_money(pricePerSquareMeter)}원'),
            _DetailMetricData('취득 총액', '${_money(quote.totalCash)}원'),
            _DetailMetricData(
              '예상 월세',
              '${_money(_listing.monthlyRentAt(_date))}원',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _RealEstateDetailSection(
          title: '현장 체크',
          icon: Icons.fact_check_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '개별 위험 · ${_listing.riskSummary}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_asset.evidenceAt(_date).sourceLabel}\n${_asset.sourceNote}',
                style: const TextStyle(
                  color: Color(0xFF756A61),
                  fontSize: 10.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _RealEstateDetailSection(
          title: '투자노트',
          icon: Icons.edit_note_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('real-estate-investment-note'),
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                onChanged: (_) {
                  if (_noteSaved) setState(() => _noteSaved = false);
                },
                decoration: const InputDecoration(
                  hintText: '확인할 권리관계, 수리비, 협상 가격을 메모하세요.',
                  filled: true,
                  fillColor: Color(0xFFF8F3E9),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  key: const Key('real-estate-investment-note-save'),
                  onPressed: _noteSaving
                      ? null
                      : () async {
                          setState(() => _noteSaving = true);
                          try {
                            await widget.onNoteSaved(
                              _noteController.text.trim(),
                            );
                            if (mounted) setState(() => _noteSaved = true);
                          } finally {
                            if (mounted) setState(() => _noteSaving = false);
                          }
                        },
                  icon: Icon(
                    _noteSaved
                        ? Icons.check_rounded
                        : _noteSaving
                        ? Icons.hourglass_top_rounded
                        : Icons.save_outlined,
                    size: 17,
                  ),
                  label: Text(
                    _noteSaved
                        ? '저장됨'
                        : _noteSaving
                        ? '저장 중'
                        : '노트 저장',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceTab() {
    final points = realEstatePriceHistoryForListing(
      listing: _listing,
      asOf: _date,
      months: 60,
    );
    final comparisons = realEstateComparablesForListing(
      subject: _listing,
      asOf: _date,
      maximum: 5,
    );
    final anchors =
        _asset.priceAnchors
            .where((anchor) => !anchor.date.isAfter(_date))
            .toList(growable: false)
          ..sort((a, b) => b.date.compareTo(a.date));
    return _detailList(
      key: const Key('real-estate-detail-price-panel'),
      children: [
        _RealEstateDetailSection(
          title: '개별 매물 시세',
          icon: Icons.show_chart_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                key: const Key('real-estate-price-chart'),
                height: 190,
                child: CustomPaint(
                  painter: _RealEstatePriceChartPainter(points: points),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                points.isEmpty
                    ? '현재 시점에 표시할 가격 이력이 없습니다.'
                    : '${_realEstateDate(points.first.date)} ${_money(points.first.price)}원 → '
                          '${_realEstateDate(points.last.date)} ${_money(points.last.price)}원',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF66574B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _RealEstateDetailSection(
          title: '같은 단지 비교매물',
          icon: Icons.compare_arrows_rounded,
          child: Column(
            children: [
              for (final comparable in comparisons)
                _ComparableListingRow(comparable: comparable),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _RealEstateDetailSection(
          title: '공개 가격 근거',
          icon: Icons.receipt_long_outlined,
          child: anchors.isEmpty
              ? const Text('현재 시점에 공개된 가격 기준점이 없습니다.')
              : Column(
                  children: [
                    for (final anchor in anchors.take(8))
                      _DetailInfoRow(
                        label: _realEstateDate(anchor.date),
                        value:
                            '${_money(anchor.price)}원 · ${anchor.evidence.label}',
                        caption: anchor.sourceLabel,
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildReturnsTab() {
    final analysis = _analysis;
    final capRate = analysis.capRate * 100;
    final cashOnCash = analysis.cashOnCashReturn * 100;
    final dscr = analysis.dscr.isInfinite ? null : analysis.dscr;
    final equity = analysis.equity;
    final assessment = _borrowingAssessment;
    final currentDsr =
        (widget.state.personalFinance.monthlyMortgagePayment +
            widget.state.banking.monthlyUnsecuredDebtService) /
        math.max(1, gameQualifyingRecurringMonthlyIncome(widget.state));
    return _detailList(
      key: const Key('real-estate-detail-returns-panel'),
      children: [
        _DetailMetricGrid(
          items: [
            _DetailMetricData(
              '월 NOI',
              '${_money(_monthlyNoi)}원',
              positive: _monthlyNoi >= 0,
            ),
            _DetailMetricData(
              'Cap rate',
              '${capRate.toStringAsFixed(2)}%',
              positive: capRate > 0,
            ),
            _DetailMetricData(
              'Cash-on-cash',
              '${cashOnCash.toStringAsFixed(2)}%',
              positive: cashOnCash >= 0,
            ),
            _DetailMetricData(
              'DSCR',
              dscr == null ? '현금 매입' : '${dscr.toStringAsFixed(2)}배',
              positive: dscr == null || dscr >= 1.2,
            ),
            _DetailMetricData('자기자본', '${_money(equity)}원'),
            _DetailMetricData(
              _owned == null ? '심사 DSR' : '현재 DSR',
              _owned != null
                  ? '${(currentDsr * 100).toStringAsFixed(1)}%'
                  : _plan.hasMortgage
                  ? '${(assessment.dsr * 100).toStringAsFixed(1)}%'
                  : '해당 없음',
              positive: _owned != null
                  ? currentDsr <= realEstateMaximumDsrRate
                  : !_plan.hasMortgage || assessment.approved,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _RealEstateDetailSection(
          title: '월 수익 구조',
          icon: Icons.account_balance_wallet_outlined,
          child: Column(
            children: [
              _DetailInfoRow(
                label: '예상 임대수입',
                value: '${_money(_monthlyRent)}원',
              ),
              _DetailInfoRow(
                label: '운영·유지비',
                value: '-${_money(_monthlyOperatingCost)}원',
              ),
              _DetailInfoRow(
                label: '보유세 적립',
                value: '-${_money(_monthlyHoldingTax)}원',
              ),
              if (analysis.monthlyInsurancePremium > 0)
                _DetailInfoRow(
                  label: '보험료',
                  value: '-${_money(analysis.monthlyInsurancePremium)}원',
                ),
              _DetailInfoRow(
                label:
                    '공실 충당 ${(100 * _expectedVacancyRate).toStringAsFixed(1)}%',
                value: '-${_money(_monthlyVacancyReserve)}원',
              ),
              _DetailInfoRow(
                label: '수리 충당',
                value: '-${_money(_monthlyRepairReserve)}원',
              ),
              const Divider(),
              _DetailInfoRow(
                label: 'NOI',
                value: '${_money(_monthlyNoi)}원',
                emphasized: true,
              ),
              _DetailInfoRow(
                label: '월 원리금',
                value: '-${_money(_monthlyDebtService)}원',
              ),
              _DetailInfoRow(
                label: '월 순현금',
                value: '${_money(_monthlyNoi - _monthlyDebtService)}원',
                emphasized: true,
              ),
            ],
          ),
        ),
        if (_plan.hasMortgage) ...[
          const SizedBox(height: 10),
          _RealEstateDetailSection(
            title: assessment.approved ? '대출 심사 통과 예상' : '대출 심사 주의',
            icon: assessment.approved
                ? Icons.verified_outlined
                : Icons.warning_amber_rounded,
            tone: assessment.approved
                ? const Color(0xFFE8F3E8)
                : const Color(0xFFFFE8DE),
            child: Text(
              assessment.approved
                  ? 'DSR과 포트폴리오 총부채 한도 안입니다. 실제 매입 시 엔진이 다시 심사합니다.'
                  : assessment.reason,
              style: const TextStyle(fontSize: 11, height: 1.45),
            ),
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          '공실·수리 충당은 현재 상태와 위험도를 바탕으로 한 UI 예상치이며 미래 사건을 미리 보여주지 않습니다.',
          style: TextStyle(
            color: Color(0xFF766B61),
            fontSize: 9.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildLoanTab() {
    if (_owned != null) {
      final owned = _owned!;
      return _detailList(
        key: const Key('real-estate-detail-loan-panel'),
        children: [
          _DetailMetricGrid(
            items: [
              _DetailMetricData('대출 잔액', '${_money(owned.mortgageBalance)}원'),
              _DetailMetricData(
                '현재 LTV',
                _marketValue <= 0
                    ? '0.0%'
                    : '${(owned.mortgageBalance * 100 / _marketValue).toStringAsFixed(1)}%',
              ),
              _DetailMetricData(
                '월 원리금',
                '${_money(owned.monthlyMortgagePayment)}원',
              ),
              _DetailMetricData('남은 기간', '${owned.mortgageRemainingMonths}개월'),
            ],
          ),
          const SizedBox(height: 10),
          _RealEstateDetailSection(
            title: '현재 담보대출',
            icon: Icons.account_balance_outlined,
            child: Column(
              children: [
                _DetailInfoRow(
                  label: '적용 금리',
                  value:
                      '연 ${(owned.mortgageAnnualInterestRate * 100).toStringAsFixed(2)}%',
                ),
                _DetailInfoRow(
                  label: '다음 달 이자',
                  value: '${_money(owned.nextMortgageInterest)}원',
                ),
                _DetailInfoRow(
                  label: '납입·연체',
                  value:
                      '${owned.mortgagePaymentsMade}회 납입 · ${owned.mortgageMissedPayments}/3회 연체',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (widget.onPrepayMortgage == null &&
              widget.onRefinanceMortgage == null)
            const _UnavailableActionCard(
              title: '중도상환·대환대출',
              body: '현재 연결된 상환·대환 기능이 없어 비활성 상태입니다.',
              actionKey: Key('real-estate-detail-loan-refinance-disabled'),
            )
          else
            _RealEstateDetailSection(
              title: '대출 관리',
              icon: Icons.currency_exchange_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.tonalIcon(
                    key: const Key('real-estate-detail-prepay'),
                    onPressed:
                        owned.hasMortgage && widget.onPrepayMortgage != null
                        ? _requestMortgagePrepayment
                        : null,
                    icon: const Icon(Icons.savings_outlined, size: 18),
                    label: const Text('원금 중도상환'),
                  ),
                  const SizedBox(height: 7),
                  OutlinedButton.icon(
                    key: const Key('real-estate-detail-refinance'),
                    onPressed:
                        owned.hasMortgage && widget.onRefinanceMortgage != null
                        ? _requestMortgageRefinance
                        : null,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('고정·변동금리 대환'),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    final plan = _plan;
    final assessment = _borrowingAssessment;
    final schedule = realEstateAmortizationSchedule(
      openingBalance: plan.principal,
      annualInterestRate: plan.annualInterestRate,
      remainingMonths: plan.termMonths,
      maximumRows: 12,
    );
    final totalPayment = plan.monthlyPayment * plan.termMonths;
    final totalInterest = math.max(0, totalPayment - plan.principal);
    return _detailList(
      key: const Key('real-estate-detail-loan-panel'),
      children: [
        _RealEstateDetailSection(
          title: 'LTV 선택',
          icon: Icons.tune_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final ltv in _ltvChoices)
                    ChoiceChip(
                      key: Key('real-estate-detail-ltv-$ltv'),
                      selected: _selectedLtv == ltv,
                      onSelected: (_) => setState(() => _selectedLtv = ltv),
                      label: Text(ltv == 0 ? '현금' : '$ltv%'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_terms.eraLabel} · 게임 단순화 고정 적용\n'
                '회사 통장 ${_money(widget.state.bankCash)}원에서 자기자본과 취득비용을 냅니다.',
                style: const TextStyle(
                  color: Color(0xFF716358),
                  fontSize: 10.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _DetailMetricGrid(
          items: [
            _DetailMetricData('대출 원금', '${_money(plan.principal)}원'),
            _DetailMetricData('필요 현금', '${_money(plan.cashRequired)}원'),
            _DetailMetricData(
              '적용 금리',
              plan.hasMortgage
                  ? '연 ${(plan.annualInterestRate * 100).toStringAsFixed(2)}%'
                  : '없음',
            ),
            _DetailMetricData('월 원리금', '${_money(plan.monthlyPayment)}원'),
            _DetailMetricData('총 예상이자', '${_money(totalInterest)}원'),
            _DetailMetricData(
              '예상 DSR',
              plan.hasMortgage
                  ? '${(assessment.dsr * 100).toStringAsFixed(1)}%'
                  : '해당 없음',
              positive: !plan.hasMortgage || assessment.approved,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _RealEstateDetailSection(
          title: '첫 12개월 상환 일정',
          icon: Icons.calendar_month_outlined,
          child: plan.hasMortgage
              ? Column(
                  children: [
                    const _MortgageScheduleHeader(),
                    for (final row in schedule) _MortgageScheduleRowView(row),
                  ],
                )
              : const Text('현금 매입에는 상환 일정이 없습니다.'),
        ),
        const SizedBox(height: 10),
        _RealEstateDetailSection(
          title: '금리·심사 안내',
          icon: Icons.info_outline_rounded,
          tone: assessment.approved
              ? const Color(0xFFEAF3EA)
              : const Color(0xFFFFE8DE),
          child: Text(
            !plan.hasMortgage
                ? '대출 없이 전액 현금으로 매입합니다.'
                : assessment.approved
                ? '실행 시점 고정금리가 저장됩니다. 매입 뒤 보유관리에서 '
                      '조건과 신용 심사를 거쳐 변동금리 대환 또는 기간 조정을 신청할 수 있습니다.'
                : assessment.reason,
            style: const TextStyle(fontSize: 10.5, height: 1.45),
          ),
        ),
      ],
    );
  }

  Widget _buildTaxTab() {
    final quote = _quote;
    final saleValue =
        _owned?.estimatedSaleValue(widget.state.day) ??
        (_listing.priceAt(_date) - _listing.saleCostsAt(_date));
    final purchaseCost = _owned?.purchasePrice ?? quote.totalCash;
    final holdingDays = _owned == null
        ? 0
        : widget.state.day - _owned!.acquiredDay;
    final capitalGainsTax = realEstateCapitalGainsTax(
      saleDate: _date,
      type: _asset.type,
      ownedHousingCount: widget.ownedHousingCount,
      holdingDays: holdingDays,
      netSaleBeforeTax: saleValue,
      purchaseCost: purchaseCost,
    );
    return _detailList(
      key: const Key('real-estate-detail-tax-panel'),
      children: [
        _RealEstateDetailSection(
          title: '취득 비용',
          icon: Icons.receipt_long_outlined,
          child: Column(
            children: [
              if (_owned case final owned?) ...[
                _DetailInfoRow(
                  label: '취득 당시 매매가',
                  value: '${_money(owned.marketPriceAtPurchase)}원',
                  caption: owned.purchaseDateIso.isEmpty
                      ? null
                      : owned.purchaseDateIso.split('T').first,
                ),
                _DetailInfoRow(
                  label: '취득 부대비용',
                  value: '${_money(owned.acquisitionCosts)}원',
                  caption: '취득세·중개보수·등기비 등 실제 저장 합계',
                ),
              ] else ...[
                _DetailInfoRow(
                  label: '매매가',
                  value: '${_money(quote.marketPrice)}원',
                ),
                _DetailInfoRow(
                  label: '취득세',
                  value: '${_money(quote.acquisitionTax)}원',
                ),
                _DetailInfoRow(
                  label: '지방교육세',
                  value: '${_money(quote.localEducationTax)}원',
                ),
                _DetailInfoRow(
                  label: '농어촌특별세',
                  value: '${_money(quote.ruralSpecialTax)}원',
                ),
                _DetailInfoRow(
                  label: '중개보수+VAT',
                  value: '${_money(quote.brokerageFee + quote.brokerageVat)}원',
                ),
                _DetailInfoRow(
                  label: '등기·채권·법무',
                  value: '${_money(quote.bondLegalAndRegistration)}원',
                ),
              ],
              const Divider(),
              _DetailInfoRow(
                label: '총 취득원가',
                value: '${_money(_owned?.purchasePrice ?? quote.totalCash)}원',
                emphasized: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _DetailMetricGrid(
          items: [
            _DetailMetricData('월 보유세', '${_money(_monthlyHoldingTax)}원'),
            _DetailMetricData('연 보유세', '${_money(_monthlyHoldingTax * 12)}원'),
            _DetailMetricData(
              '현재 매각비',
              '${_money(_listing.saleCostsAt(_date))}원',
            ),
            _DetailMetricData('예상 양도세', '${_money(capitalGainsTax)}원'),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          '세금은 시대·주택 수·보유기간을 반영한 게임용 단순화 계산입니다. 실제 신고·세무 판단에 사용할 수 없습니다.',
          style: TextStyle(color: Color(0xFF75685D), fontSize: 10, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildNewsTab() {
    final events = [..._listing.visibleEventsAt(_date)]
      ..sort((left, right) => right.announcedAt.compareTo(left.announcedAt));
    final unresolvedCount = events
        .where((event) => !event.isResolvedAt(_date))
        .length;
    return _detailList(
      key: const Key('real-estate-detail-news-panel'),
      children: [
        _RealEstateDetailSection(
          title: '지역·매물 공개 이벤트',
          icon: Icons.newspaper_outlined,
          child: events.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      '현재 시점에 공개된 지역뉴스가 없습니다.',
                      style: TextStyle(color: Color(0xFF756A60)),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '공개 ${events.length}건 · 진행 중 $unresolvedCount건 · 최근 24건',
                      style: const TextStyle(
                        color: Color(0xFF796B60),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final event in events.take(24))
                      _RealEstateEventTimelineItem(event: event, date: _date),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        const Text(
          '미해결 사건의 결과와 해결 예정일은 표시하지 않습니다. 발표 내용은 지연되거나 취소될 수 있습니다.',
          style: TextStyle(
            color: Color(0xFF766B61),
            fontSize: 9.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildManagementTab() {
    final owned = _owned!;
    final saleWaitFinished = widget.state.day - owned.acquiredDay >= 30;
    final saleListed = owned.saleListedDay > 0;
    final saleOfferReady =
        saleListed && widget.state.day >= owned.saleOfferReadyDay;
    final saleOfferExpired =
        owned.saleOfferAmount > 0 &&
        owned.saleOfferExpiresDay > 0 &&
        widget.state.day > owned.saleOfferExpiresDay;
    final canSell =
        saleWaitFinished &&
        !owned.hasActiveLease &&
        (!saleListed || saleOfferReady);
    final saleStatus = owned.hasActiveLease
        ? '임대계약 종료 후 매각 가능'
        : !saleWaitFinished
        ? '취득 30일 후 매각 가능'
        : !saleListed
        ? '매물 등록 전'
        : !saleOfferReady
        ? '매수자 제안까지 ${owned.saleOfferReadyDay - widget.state.day}일'
        : saleOfferExpired
        ? '매수자 제안 만료 · 새 등록 필요'
        : '매수자 제안 ${_money(owned.saleOfferAmount)}원 · '
              '${owned.saleOfferExpiresDay - widget.state.day}일 뒤 만료';
    final tenantSearchMonths = realEstateTenantSearchMonths(
      worldSeed: widget.state.simulationSeed,
      assetId: owned.id,
    );
    final canManageLease =
        widget.onManageLease != null &&
        (!owned.hasActiveLease || owned.leaseRemainingMonths <= 0) &&
        owned.vacancyMonths >= tenantSearchMonths;
    final heldMonths = math.max(
      1,
      ((widget.state.day - owned.acquiredDay) / 30).ceil(),
    );
    final vacancyRate = (owned.totalVacancyMonths * 100 / heldMonths).clamp(
      0,
      100,
    );
    final isActiveMonthlyLease =
        owned.leaseType == RealEstateLeaseType.monthlyRent &&
        owned.leaseRemainingMonths > 0;
    final canRenewMonthlyLease =
        isActiveMonthlyLease &&
        owned.leaseRemainingMonths <= 3 &&
        owned.rentArrearsMonths == 0 &&
        widget.onRenewMonthlyLease != null;
    final renovationCost = realEstateRenovationCost(_marketValue);
    final canRenovate =
        !owned.isLandmarkFund &&
        !owned.hasActiveLease &&
        owned.propertyCondition < 100 &&
        widget.state.bankCash >= renovationCost &&
        widget.onRenovate != null;
    final insurancePremium = realEstateMonthlyInsurancePremium(_marketValue);
    return _detailList(
      key: const Key('real-estate-detail-management-panel'),
      children: [
        _DetailMetricGrid(
          items: [
            _DetailMetricData('현재 시세', '${_money(_marketValue)}원'),
            _DetailMetricData('담보 잔액', '${_money(owned.mortgageBalance)}원'),
            _DetailMetricData('누적 공실률', '${vacancyRate.toStringAsFixed(1)}%'),
            _DetailMetricData('누적 수리비', '${_money(owned.totalRepairCosts)}원'),
          ],
        ),
        const SizedBox(height: 10),
        _RealEstateDetailSection(
          title: '매각 제안',
          icon: Icons.sell_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                saleStatus,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  height: 1.45,
                ),
              ),
              if (saleListed && !saleOfferReady)
                Text(
                  '등록 ${owned.saleListingDays}일 뒤 제안 도착 · 현재 제안은 만료되지 않습니다.',
                  style: const TextStyle(
                    color: Color(0xFF75695F),
                    fontSize: 10,
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                key: const Key('real-estate-detail-sell'),
                onPressed: canSell && widget.onSell != null
                    ? widget.onSell
                    : null,
                child: Text(
                  !saleListed
                      ? '매각 등록'
                      : saleOfferExpired
                      ? '만료 처리'
                      : saleOfferReady
                      ? '제안 검토'
                      : '제안 대기 중',
                ),
              ),
              if (saleListed && widget.onCancelSale != null) ...[
                const SizedBox(height: 7),
                OutlinedButton(
                  key: const Key('real-estate-detail-cancel-sale'),
                  onPressed: widget.onCancelSale,
                  child: const Text('매각 등록 취소'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _RealEstateDetailSection(
          title: '임대 운영',
          icon: Icons.key_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailInfoRow(label: '운영 방식', value: owned.leaseType.label),
              _DetailInfoRow(
                label: '월세·보증금',
                value:
                    '${_money(owned.leaseMonthlyRent)}원 · ${_money(owned.leaseDeposit)}원',
              ),
              _DetailInfoRow(
                label: '계약·공실',
                value:
                    '남은 ${owned.leaseRemainingMonths}개월 · 공실 ${owned.vacancyMonths}개월',
              ),
              if (owned.lastRentalEvent.isNotEmpty)
                Text(
                  owned.lastRentalEvent,
                  style: const TextStyle(
                    color: Color(0xFF8E4E48),
                    fontSize: 10,
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('real-estate-detail-lease'),
                onPressed: canManageLease ? widget.onManageLease : null,
                child: Text(
                  owned.hasActiveLease
                      ? '계약 종료 후 변경'
                      : owned.vacancyMonths < tenantSearchMonths
                      ? '세입자 모집 ${owned.vacancyMonths}/$tenantSearchMonths개월'
                      : '임대 방식 선택',
                ),
              ),
              if (isActiveMonthlyLease) ...[
                const SizedBox(height: 7),
                OutlinedButton.icon(
                  key: const Key('real-estate-detail-lease-renew'),
                  onPressed: canRenewMonthlyLease
                      ? widget.onRenewMonthlyLease
                      : null,
                  icon: const Icon(Icons.autorenew_rounded, size: 18),
                  label: Text(
                    owned.leaseRemainingMonths > 3
                        ? '만료 3개월 전부터 갱신'
                        : owned.rentArrearsMonths > 0
                        ? '연체 정산 후 갱신'
                        : '월세 계약 갱신',
                  ),
                ),
                const SizedBox(height: 7),
                OutlinedButton.icon(
                  key: const Key('real-estate-detail-lease-terminate'),
                  onPressed: widget.onTerminateMonthlyLeaseEarly,
                  icon: const Icon(Icons.key_off_outlined, size: 18),
                  label: const Text('월세 계약 중도 종료'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _RealEstateDetailSection(
          title: '건물 상태·보험',
          icon: Icons.home_repair_service_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailInfoRow(
                label: '현재 상태',
                value: '${owned.propertyCondition}/100',
                caption: owned.propertyCondition >= 85
                    ? '양호'
                    : owned.propertyCondition >= 60
                    ? '보통 · 수리비 위험 증가'
                    : '노후 · 공실과 대형 수리 위험 높음',
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  key: const Key('real-estate-condition-progress'),
                  value: owned.propertyCondition.clamp(0, 100) / 100,
                  minHeight: 8,
                  color: owned.propertyCondition >= 70
                      ? const Color(0xFF4D7B63)
                      : const Color(0xFFC45F4D),
                  backgroundColor: const Color(0xFFE5D9CA),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                key: const Key('real-estate-detail-renovate'),
                onPressed: canRenovate ? widget.onRenovate : null,
                icon: const Icon(Icons.construction_rounded, size: 18),
                label: Text(
                  owned.isLandmarkFund
                      ? '지분형 자산은 직접 공사 불가'
                      : owned.hasActiveLease
                      ? '임대 종료 후 리모델링'
                      : owned.propertyCondition >= 100
                      ? '최상 상태'
                      : widget.state.bankCash < renovationCost
                      ? '리모델링 현금 부족'
                      : '리모델링 · ${_money(renovationCost)}원',
                ),
              ),
              const SizedBox(height: 10),
              _DetailInfoRow(
                label: '재산보험',
                value: owned.insuranceActive ? '가입 중' : '미가입',
                caption:
                    '월 ${_money(insurancePremium)}원 · 대형 수리비는 자기부담금 차감 후 70% 보상',
              ),
              OutlinedButton.icon(
                key: const Key('real-estate-detail-insurance-toggle'),
                onPressed:
                    !owned.isLandmarkFund && widget.onSetInsurance != null
                    ? () => widget.onSetInsurance!(!owned.insuranceActive)
                    : null,
                icon: Icon(
                  owned.insuranceActive
                      ? Icons.shield_outlined
                      : Icons.add_moderator_outlined,
                  size: 18,
                ),
                label: Text(owned.insuranceActive ? '재산보험 해지' : '재산보험 가입'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _UnavailableActionCard(
          title: '직접 사용',
          body: '직접 사용 전환은 현재 공개 엔진 API가 없어 비활성 상태입니다.',
          actionKey: Key('real-estate-detail-direct-use-disabled'),
        ),
        const SizedBox(height: 8),
        if (widget.onPrepayMortgage == null &&
            widget.onRefinanceMortgage == null)
          const _UnavailableActionCard(
            title: '중도상환·대환',
            body: '현재 연결된 상환·대환 기능이 없어 비활성 상태입니다.',
            actionKey: Key('real-estate-detail-refinance-disabled'),
          )
        else
          _RealEstateDetailSection(
            title: '담보대출 관리',
            icon: Icons.account_balance_outlined,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('real-estate-management-prepay'),
                    onPressed:
                        owned.hasMortgage && widget.onPrepayMortgage != null
                        ? _requestMortgagePrepayment
                        : null,
                    child: const Text('중도상환'),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('real-estate-management-refinance'),
                    onPressed:
                        owned.hasMortgage && widget.onRefinanceMortgage != null
                        ? _requestMortgageRefinance
                        : null,
                    child: const Text('대환'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _realEstateDate(DateTime date) =>
    '${date.year}.${date.month.toString().padLeft(2, '0')}';

class _RealEstatePriceChartPainter extends CustomPainter {
  const _RealEstatePriceChartPainter({required this.points});

  final List<RealEstatePricePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const left = 10.0;
    const top = 12.0;
    const bottom = 20.0;
    const right = 8.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final prices = points.map((point) => point.price.toDouble()).toList();
    final minimum = prices.reduce(math.min);
    final maximum = prices.reduce(math.max);
    final spread = math.max(1.0, maximum - minimum);
    final gridPaint = Paint()
      ..color = const Color(0x1F6A5D52)
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index += 1) {
      final y = chart.top + chart.height * index / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    final path = Path();
    final fillPath = Path();
    for (var index = 0; index < points.length; index += 1) {
      final x = points.length == 1
          ? chart.left
          : chart.left + chart.width * index / (points.length - 1);
      final y =
          chart.bottom -
          (points[index].price - minimum) / spread * chart.height;
      if (index == 0) {
        path.moveTo(x, y);
        fillPath
          ..moveTo(x, chart.bottom)
          ..lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath
      ..lineTo(chart.right, chart.bottom)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x554D7790), Color(0x054D7790)],
        ).createShader(chart),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4D7790)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    if (points.isNotEmpty) {
      final lastY =
          chart.bottom - (points.last.price - minimum) / spread * chart.height;
      canvas.drawCircle(
        Offset(chart.right, lastY),
        5,
        Paint()..color = const Color(0xFFB45A3C),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RealEstatePriceChartPainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      (points.isNotEmpty &&
          oldDelegate.points.isNotEmpty &&
          oldDelegate.points.last.price != points.last.price);
}

class _RealEstateDetailSection extends StatelessWidget {
  const _RealEstateDetailSection({
    required this.title,
    required this.icon,
    required this.child,
    this.tone = Colors.white,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: tone,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFD8C7A9)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF7D5035), size: 19),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    required this.label,
    required this.value,
    this.caption,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final String? caption;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFF756A61),
              fontSize: emphasized ? 11 : 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: const Color(0xFF3D3029),
                  fontSize: emphasized ? 12 : 10.5,
                  fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF8B8178),
                    fontSize: 8.5,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailMetricData {
  const _DetailMetricData(this.label, this.value, {this.positive});

  final String label;
  final String value;
  final bool? positive;
}

class _DetailMetricGrid extends StatelessWidget {
  const _DetailMetricGrid({required this.items});

  final List<_DetailMetricData> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.max(120.0, (constraints.maxWidth - 8) / 2);
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            SizedBox(
              width: width,
              child: Container(
                constraints: const BoxConstraints(minHeight: 72),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDDCCAE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Color(0xFF7A6E64),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.positive == false
                            ? const Color(0xFFB34B3E)
                            : item.positive == true
                            ? const Color(0xFF35684B)
                            : const Color(0xFF3D3029),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _ComparableListingRow extends StatelessWidget {
  const _ComparableListingRow({required this.comparable});

  final RealEstateComparable comparable;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F3EA),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comparable.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${comparable.areaSquareMeters.toStringAsFixed(1)}㎡ · '
                '역 ${comparable.stationWalkMinutes}분 · '
                '${comparable.condition.label}',
                style: const TextStyle(color: Color(0xFF786D64), fontSize: 9),
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_money(comparable.price)}원',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
            Text(
              '㎡ ${_money(comparable.pricePerSquareMeter)}원',
              style: const TextStyle(color: Color(0xFF786D64), fontSize: 8.5),
            ),
          ],
        ),
      ],
    ),
  );
}

class _RealEstateEventTimelineItem extends StatelessWidget {
  const _RealEstateEventTimelineItem({required this.event, required this.date});

  final RealEstateWorldEvent event;
  final DateTime date;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 18,
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: event.isPotentialUpside
                      ? const Color(0xFF4D7790)
                      : const Color(0xFFB45A3C),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(width: 2, color: const Color(0xFFD8C7A9)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_realEstateDate(event.announcedAt)} · ${event.kind.label} · ${event.statusAt(date)}',
                  style: const TextStyle(
                    color: Color(0xFF796B60),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  event.detailAt(date),
                  style: const TextStyle(fontSize: 10, height: 1.4),
                ),
                if (event.isResolvedAt(date))
                  Text(
                    '해결 ${_realEstateDate(event.resolvedAt)}',
                    style: const TextStyle(
                      color: Color(0xFF857970),
                      fontSize: 8.5,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _MortgageScheduleHeader extends StatelessWidget {
  const _MortgageScheduleHeader();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        SizedBox(width: 42, child: Text('회차', style: _scheduleHeaderStyle)),
        Expanded(child: Text('납입', style: _scheduleHeaderStyle)),
        Expanded(child: Text('이자', style: _scheduleHeaderStyle)),
        Expanded(
          child: Text(
            '잔액',
            textAlign: TextAlign.right,
            style: _scheduleHeaderStyle,
          ),
        ),
      ],
    ),
  );
}

const _scheduleHeaderStyle = TextStyle(
  color: Color(0xFF7A6E64),
  fontSize: 8.5,
  fontWeight: FontWeight.w900,
);

class _MortgageScheduleRowView extends StatelessWidget {
  const _MortgageScheduleRowView(this.row);

  final RealEstateAmortizationRow row;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            '${row.paymentNumber}회',
            style: const TextStyle(fontSize: 9),
          ),
        ),
        Expanded(
          child: Text(_money(row.payment), style: const TextStyle(fontSize: 9)),
        ),
        Expanded(
          child: Text(
            _money(row.interest),
            style: const TextStyle(fontSize: 9),
          ),
        ),
        Expanded(
          child: Text(
            _money(row.closingBalance),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _UnavailableActionCard extends StatelessWidget {
  const _UnavailableActionCard({
    required this.title,
    required this.body,
    required this.actionKey,
  });

  final String title;
  final String body;
  final Key actionKey;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFEAE7E2),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFD2CBC2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline_rounded, color: Color(0xFF877E74)),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  color: Color(0xFF716A64),
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 7),
              SizedBox(
                width: double.infinity,
                child: IgnorePointer(
                  child: OutlinedButton(
                    key: actionKey,
                    onPressed: null,
                    child: Text('$title 준비 중'),
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

class _RealEstateMarketSection extends StatelessWidget {
  const _RealEstateMarketSection({
    required this.selectedTier,
    required this.selectedDistrictId,
    required this.currentDate,
    required this.worldSeed,
    required this.ownedHousingCount,
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
  final int ownedHousingCount;
  final bool busy;
  final String? Function(GeneratedRealEstateListing listing) lockReason;
  final ValueChanged<RealEstateInvestmentTier> onTierSelected;
  final ValueChanged<String?> onDistrictSelected;
  final Future<void> Function(GeneratedRealEstateListing listing) onPurchase;

  @override
  Widget build(BuildContext context) {
    final availableAssets = realEstateMarketCatalogAt(currentDate);
    final availableTiers = RealEstateInvestmentTier.values
        .where((tier) => availableAssets.any((asset) => asset.tier == tier))
        .toList(growable: false);
    final tierAssets = availableAssets
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
            .expand(
              (asset) =>
                  realEstateActiveListingsAt(asset, worldSeed, currentDate),
            )
            .toList(growable: false)
          ..sort(
            (a, b) => a.priceAt(currentDate).compareTo(b.priceAt(currentDate)),
          );
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final listingCarouselHeight =
        510.0 + (textScale - 1.0).clamp(0.0, 1.0).toDouble() * 140.0;
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
            children: availableTiers
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
        if (listings.isEmpty)
          Container(
            key: const Key('real-estate-listing-empty'),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFFD8C7A9)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  color: Color(0xFF8A7667),
                  size: 34,
                ),
                SizedBox(height: 7),
                Text(
                  '현재 등록된 매물이 없습니다.',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '시간이 지나면 신규 등록이나 재등록 매물이 나타납니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF756A61), fontSize: 10),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: listingCarouselHeight,
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
                    ownedHousingCount: ownedHousingCount,
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
    required this.ownedHousingCount,
    required this.lockReason,
    required this.busy,
    required this.onPurchase,
  });

  final GeneratedRealEstateListing listing;
  final DateTime currentDate;
  final int ownedHousingCount;
  final String? lockReason;
  final bool busy;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final asset = listing.asset;
    final quote = realEstatePortfolioAdjustedPurchaseQuote(
      baseQuote: listing.quoteAt(currentDate),
      date: currentDate,
      type: asset.type,
      ownedHousingCount: ownedHousingCount,
    );
    final evidence = asset.evidenceAt(currentDate);
    final monthlyRent = listing.monthlyRentAt(currentDate);
    final monthlyCost = listing.monthlyOperatingCostAt(currentDate);
    final monthlyHoldingTax = realEstateMonthlyHoldingTax(
      date: currentDate,
      type: asset.type,
      marketValue: quote.marketPrice,
      ownedHousingCount: ownedHousingCount + (asset.type.isHousing ? 1 : 0),
    );
    final financingTerms = realEstateFinancingTermsAt(currentDate, asset.type);
    final maxFinancing = financingTerms.planFor(
      quote,
      financingTerms.maxLtvPercent,
    );
    final monthlyNetBeforeDebt = monthlyRent - monthlyCost - monthlyHoldingTax;
    final pricePerSquareMeter =
        quote.marketPrice ~/ math.max(1, listing.areaSquareMeters.round());
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
          SizedBox(
            height: 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  asset.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Color(0xFFE8D9C3),
                    child: Center(
                      child: Icon(Icons.apartment_rounded, size: 58),
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x99000000)],
                      stops: [0.55, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Text(
                    '${asset.province} ${asset.region} · 역 ${listing.stationWalkMinutes}분',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
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
                      if (lockReason != null)
                        _MarketBadge(
                          label: lockReason!,
                          color: const Color(0xFF9A5A3E),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    listing.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${listing.areaSquareMeters.toStringAsFixed(1)}㎡ · ${listing.floor}층 · '
                    '㎡당 ${_money(pricePerSquareMeter)}원',
                    style: const TextStyle(
                      color: Color(0xFF75685D),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  FittedBox(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_money(quote.marketPrice)}원',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF382820),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EFE5),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      '월 예상 NOI ${_money(monthlyNetBeforeDebt)}원 · '
                      '최저 필요 현금 ${_money(maxFinancing.cashRequired)}원\n'
                      '${financingTerms.available ? '최대 LTV ${financingTerms.maxLtvPercent}% · 월 원리금 ${_money(maxFinancing.monthlyPayment)}원' : '현재는 현금 매입만 가능'}',
                      style: const TextStyle(
                        color: Color(0xFF665247),
                        fontSize: 9.5,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  KeyedSubtree(
                    key: Key('real-estate-detail-${asset.id}-${listing.index}'),
                    child: SizedBox(
                      width: double.infinity,
                      height: 47,
                      child: FilledButton.icon(
                        key: Key(
                          'real-estate-buy-${asset.id}-${listing.index}',
                        ),
                        onPressed: busy ? null : onPurchase,
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: const Text('전체 분석 보기'),
                      ),
                    ),
                  ),
                ],
              ),
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
    required this.propertyEquity,
    required this.monthlyPropertyNet,
    required this.totalSpent,
    required this.totalMortgageBalance,
    required this.totalTenantDeposits,
    required this.tenantDepositDebt,
    required this.totalKnownLiabilities,
    required this.netWorth,
  });

  final int cash;
  final int propertyValue;
  final int propertyEquity;
  final int monthlyPropertyNet;
  final int totalSpent;
  final int totalMortgageBalance;
  final int totalTenantDeposits;
  final int tenantDepositDebt;
  final int totalKnownLiabilities;
  final int netWorth;

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
              label: '부동산 자기자본',
              value: '${_money(propertyEquity)}원',
            ),
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
            _FinancePill(
              label: '전체 부채',
              value: '${_money(totalKnownLiabilities)}원',
            ),
            _FinancePill(label: '순자산', value: '${_money(netWorth)}원'),
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
      '실제 유명 단지·빌딩은 공개 실거래 또는 실제 매각가를 기준점으로 씁니다. 가격·세금·대출 금리와 LTV는 시대 흐름을 반영한 게임용 단순화 수치입니다. DSR은 45%, 추가 매입 총부채는 부동산 가치의 60%로 제한되며 담보대출과 임차보증금의 합계도 시가 한도를 넘을 수 없습니다. 신규 매입은 공실로 시작하고, 보유세·원리금·유지비를 모두 뺀 순현금을 확인해야 합니다. 투자 권유가 아닙니다.',
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
    required this.worldSeed,
    required this.ownedHousingCount,
    required this.busy,
    required this.onSell,
    required this.leaseManagementAvailable,
    required this.onManageLease,
    required this.onOpenDetail,
  });
  final OwnedRealEstate asset;
  final int currentDay;
  final DateTime currentDate;
  final String worldSeed;
  final int ownedHousingCount;
  final bool busy;
  final VoidCallback onSell;
  final bool leaseManagementAvailable;
  final VoidCallback onManageLease;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final saleWaitFinished = currentDay - asset.acquiredDay >= 30;
    final saleListed = asset.saleListedDay > 0;
    final saleOfferReady = saleListed && currentDay >= asset.saleOfferReadyDay;
    final canSell =
        saleWaitFinished &&
        !asset.hasActiveLease &&
        (!saleListed || saleOfferReady);
    final resolvedSaleActionLabel = asset.hasActiveLease
        ? '계약 종료 후 매각'
        : !saleWaitFinished
        ? '30일 뒤 매각'
        : !saleListed
        ? '매각 등록'
        : !saleOfferReady
        ? '제안 ${asset.saleOfferReadyDay - currentDay}일 남음'
        : '제안 수락';
    final currentMarketValue = asset.estimatedMarketValue(currentDay);
    final depositLiability = asset.hasActiveLease ? asset.leaseDeposit : 0;
    final propertyEquity =
        currentMarketValue - asset.mortgageBalance - depositLiability;
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
    final monthlyHoldingTax = realEstateMonthlyHoldingTax(
      date: currentDate,
      type: assetType,
      marketValue: currentMarketValue,
      ownedHousingCount: ownedHousingCount,
    );
    final monthlyNet =
        monthlyIncome -
        monthlyCost -
        monthlyHoldingTax -
        asset.monthlyMortgagePayment;
    final ltvPercent = currentMarketValue <= 0
        ? 0.0
        : asset.mortgageBalance * 100 / currentMarketValue;
    final tenantSearchMonths = realEstateTenantSearchMonths(
      worldSeed: worldSeed,
      assetId: asset.id,
    );
    final tenantSearchComplete = asset.vacancyMonths >= tenantSearchMonths;
    final heldMonths = math.max(
      1,
      ((currentDay - asset.acquiredDay) / 30).ceil(),
    );
    final vacancyRate = (asset.totalVacancyMonths * 100 / heldMonths).clamp(
      0,
      100,
    );
    final canManageLease =
        leaseManagementAvailable &&
        supportsManagedLease &&
        (!asset.hasActiveLease || asset.leaseRemainingMonths <= 0) &&
        tenantSearchComplete;
    final leaseActionLabel = !supportsManagedLease
        ? '직접 임대 불가'
        : asset.hasActiveLease
        ? '계약 ${asset.leaseRemainingMonths}개월 뒤 변경'
        : !tenantSearchComplete
        ? '세입자 모집 ${asset.vacancyMonths}/$tenantSearchMonths개월'
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
            '총취득 ${_money(asset.purchasePrice)}원 · 현재 시세 ${_money(currentMarketValue)}원 · 자기자본 ${_money(propertyEquity)}원',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          Text(
            '현재 월 임대 ${_money(monthlyIncome)}원 · 유지 ${_money(monthlyCost)}원'
            ' · 보유세 ${_money(monthlyHoldingTax)}원'
            '${asset.hasMortgage ? ' · 원리금 ${_money(asset.monthlyMortgagePayment)}원' : ''}\n'
            '순월현금 ${monthlyNet >= 0 ? '+' : ''}${_money(monthlyNet)}원 · LTV ${ltvPercent.toStringAsFixed(1)}%',
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
                '월 상환 ${_money(asset.monthlyMortgagePayment)}원 · '
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
                  ' · 누적 공실률 ${vacancyRate.toStringAsFixed(1)}%'
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
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              key: Key('real-estate-owned-detail-${asset.id}'),
              onPressed: busy ? null : onOpenDetail,
              icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
              label: const Text('상세 분석 · 보유관리'),
            ),
          ),
          const SizedBox(height: 7),
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
                  child: Text(resolvedSaleActionLabel),
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
