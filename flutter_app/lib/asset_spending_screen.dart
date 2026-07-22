part of 'main.dart';

class AssetSpendingScreen extends StatefulWidget {
  const AssetSpendingScreen({
    super.key,
    required this.state,
    required this.onPurchase,
    required this.onSellRealEstate,
    required this.onPlayChanceGame,
  });

  final GameState state;
  final Future<FinanceActionResult> Function(String optionId) onPurchase;
  final Future<FinanceActionResult> Function(String assetId) onSellRealEstate;
  final Future<FinanceActionResult> Function(int stake) onPlayChanceGame;

  @override
  State<AssetSpendingScreen> createState() => _AssetSpendingScreenState();
}

class _AssetSpendingScreenState extends State<AssetSpendingScreen> {
  late GameState _state = widget.state;
  bool _busy = false;

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
    if (_state.cash < option.cost) return '현금 부족';
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
        ..showSnackBar(SnackBar(content: Text(result.message)));
    } catch (_) {
      if (mounted) _showSaveFailure(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _purchase(SpendingOption option) => _run(
    () => widget.onPurchase(option.id),
    title: option.title,
    body:
        '${_money(option.cost)}원을 지출합니다. ${option.description}\n\n저장에 성공한 뒤에만 현금과 효과가 반영됩니다.',
    confirmLabel: '지출 확정',
  );

  Future<void> _sell(OwnedRealEstate asset) => _run(
    () => widget.onSellRealEstate(asset.id),
    title: '${asset.name} 매각',
    body:
        '예상 매각대금은 ${_money(asset.estimatedSaleValue(_state.day))}원입니다. 취득 후 30일 이내에는 매각할 수 없으며, 매입가 대비 거래비용이 반영된 게임용 평가입니다.',
    confirmLabel: '매각 확정',
  );

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
    return Scaffold(
      key: const Key('asset-spending-screen'),
      backgroundColor: const Color(0xFFF3EBDD),
      appBar: AppBar(
        title: const Text('자산·소비 계획'),
        backgroundColor: const Color(0xFFF3EBDD),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
          children: [
            _FinanceOverviewCard(
              cash: _state.cash,
              propertyValue: propertyValue,
              monthlyPropertyNet:
                  finance.monthlyPropertyIncome - finance.monthlyPropertyCost,
              totalSpent: finance.totalSpent,
            ),
            const SizedBox(height: 12),
            const _FinanceNoticeCard(),
            const SizedBox(height: 18),
            const _FinanceSectionTitle(
              icon: Icons.shopping_bag_rounded,
              title: '쓸 곳과 키울 곳',
              caption: '연도·법인·직원 조건에 따라 순서대로 열립니다.',
            ),
            const SizedBox(height: 8),
            ...spendingCatalog.map(
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
                body: '2006년 법인 설립 뒤 자가 사무실부터 검토할 수 있습니다.',
              )
            else
              ...finance.realEstate.map(
                (asset) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _OwnedPropertyCard(
                    asset: asset,
                    currentDay: _state.day,
                    busy: _busy,
                    onSell: () => _sell(asset),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            _AdultChanceCard(state: _state, busy: _busy, onPlay: _playChance),
          ],
        ),
      ),
    );
  }
}

class _FinanceOverviewCard extends StatelessWidget {
  const _FinanceOverviewCard({
    required this.cash,
    required this.propertyValue,
    required this.monthlyPropertyNet,
    required this.totalSpent,
  });

  final int cash;
  final int propertyValue;
  final int monthlyPropertyNet;
  final int totalSpent;

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
      '부동산 가격·임대수입·매각가는 게임 밸런스용 가상 수치이며 실제 역사 데이터가 아닙니다. 부동산은 주식 운용 AUM과 분리해 표시합니다.',
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
    required this.busy,
    required this.onSell,
  });
  final OwnedRealEstate asset;
  final int currentDay;
  final bool busy;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final canSell = currentDay - asset.acquiredDay >= 30;
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
            '매입 ${_money(asset.purchasePrice)}원 · 추정 매각 ${_money(asset.estimatedSaleValue(currentDay))}원',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
          Text(
            '월 임대 ${_money(asset.monthlyIncome)}원 · 유지 ${_money(asset.monthlyCost)}원',
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: canSell && !busy ? onSell : null,
              child: Text(canSell ? '매각 검토' : '취득 30일 뒤 매각 가능'),
            ),
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
