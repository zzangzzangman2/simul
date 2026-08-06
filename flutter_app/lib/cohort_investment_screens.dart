part of 'main.dart';

class CohortDailyResultScreen extends StatefulWidget {
  const CohortDailyResultScreen({
    super.key,
    required this.state,
    required this.onLend,
    required this.onBorrow,
    required this.onAcknowledge,
    this.loanOnly = false,
  });

  final GameState state;
  final Future<CohortInvestmentActionResult> Function(
    String borrowerId,
    int amount,
  )
  onLend;
  final Future<CohortInvestmentActionResult> Function(
    String lenderId,
    int amount,
  )
  onBorrow;
  final Future<CohortInvestmentActionResult> Function() onAcknowledge;
  final bool loanOnly;

  @override
  State<CohortDailyResultScreen> createState() =>
      _CohortDailyResultScreenState();
}

class _CohortDailyResultScreenState extends State<CohortDailyResultScreen> {
  late GameState _state = widget.state;
  bool _busy = false;

  CohortDailyInvestmentReport? get _report =>
      _state.cohortInvestments.reportForDay(_state.day);

  Future<void> _lend(CohortDailyInvestmentResult borrower, int maximum) async {
    final presetAmounts = <int>{
      math.min(100, maximum),
      math.min(500, maximum),
      math.min(1000, maximum),
      math.min(2000, maximum),
      maximum,
    }.where((amount) => amount > 0).toList()..sort();
    final amount = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFBF2),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${borrower.name}에게 얼마를 빌려줄까?',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '국가계좌 현금에서 나가며 $cohortLoanTermDays일 뒤 이자 ${(cohortLoanInterestRateBps / 100).toStringAsFixed(0)}%를 더해 자동상환 · 호감도 변화 없음',
                style: const TextStyle(
                  color: Color(0xFF6D7892),
                  fontSize: 10,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in presetAmounts)
                    FilledButton(
                      key: Key('cohort-loan-amount-$value'),
                      onPressed: () => Navigator.pop(sheetContext, value),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD66B),
                        foregroundColor: _ink,
                        side: const BorderSide(color: _ink, width: 1.5),
                      ),
                      child: Text('${_money(value)}원'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (amount == null || !mounted) return;
    setState(() => _busy = true);
    final result = await widget.onLend(borrower.investorId, amount);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.success) _state = result.state;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _borrow(CohortDailyInvestmentResult lender, int maximum) async {
    final presetAmounts = <int>{
      math.min(1000, maximum),
      math.min(5000, maximum),
      math.min(10000, maximum),
      maximum,
    }.where((amount) => amount > 0).toList()..sort();
    final amount = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFBF2),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${lender.name}에게 얼마를 빌릴까?',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$cohortLoanTermDays일 만기 · 단리 ${(cohortLoanInterestRateBps / 100).toStringAsFixed(0)}% · 만기일 국가계좌에서 자동상환',
                style: const TextStyle(
                  color: Color(0xFF9A4556),
                  fontSize: 10,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in presetAmounts)
                    FilledButton(
                      key: Key('cohort-borrow-amount-$value'),
                      onPressed: () => Navigator.pop(sheetContext, value),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA7B4),
                        foregroundColor: _ink,
                        side: const BorderSide(color: _ink, width: 1.5),
                      ),
                      child: Text('${_money(value)}원'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (amount == null || !mounted) return;
    setState(() => _busy = true);
    final result = await widget.onBorrow(lender.investorId, amount);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.success) _state = result.state;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _finish() async {
    if (_busy) return;
    if (widget.loanOnly) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _busy = true);
    final result = await widget.onAcknowledge();
    if (!mounted) return;
    if (!result.success) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    if (report == null) {
      return const Scaffold(
        body: Center(child: Text('오늘의 투자 결과를 불러오지 못했습니다.')),
      );
    }
    final rankedRows = report.rankedRows;
    final best = rankedRows.first;
    final profitableCount = rankedRows
        .where((row) => row.profitLoss > 0)
        .length;
    final loanUsed = _state.cohortInvestments.loanedForDay(_state.day);
    final eligibleBorrowers = rankedRows
        .where((row) => !row.isPlayer)
        .toList(growable: false);
    final eligibleLenders = rankedRows
        .where((row) {
          if (row.isPlayer) return false;
          return _state.cohortInvestments.accountFor(row.investorId).balance >
              cohortNpcEmergencyReserve;
        })
        .toList(growable: false);
    final todayLoan = _state.cohortInvestments.loans
        .where(
          (loan) =>
              loan.issuedDay == _state.day &&
              loan.direction == CohortLoanDirection.playerLends,
        )
        .firstOrNull;
    final todayBorrowing = _state.cohortInvestments.loans
        .where(
          (loan) =>
              loan.issuedDay == _state.day &&
              loan.direction == CohortLoanDirection.playerBorrows,
        )
        .firstOrNull;

    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('cohort-daily-result-screen'),
        backgroundColor: const Color(0xFFFFF6DF),
        body: SafeArea(
          child: Column(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.82, end: 1),
                duration: const Duration(milliseconds: 520),
                curve: Curves.elasticOut,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD66B),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: _ink, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x5533405F), offset: Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.loanOnly ? '점호 이후' : '뚜둥!',
                        style: const TextStyle(
                          color: _coral,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        widget.loanOnly ? '동기 대여·재기 장부' : '오늘의 투자 결과',
                        style: const TextStyle(
                          color: _ink,
                          fontFamily: _hubDisplayFont,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.loanOnly
                            ? '원금 이동은 오늘 수익 순위에 반영하지 않음'
                            : '15:00 종가 기준 · 데시멀 동기 10명',
                        style: const TextStyle(
                          color: Color(0xFF675A42),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  key: const Key('cohort-daily-result-list'),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _CohortResultMetric(
                            label: '수익률 1등',
                            value: best.name,
                            detail:
                                '누적 ${_cohortSignedPercent(best.returnRateBps)} · '
                                '오늘 ${_cohortSignedMoney(best.profitLoss)}원',
                            color: const Color(0xFFFFE5A0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CohortResultMetric(
                            label: '수익 난 사람',
                            value: '$profitableCount명',
                            detail: '손실·보합 ${10 - profitableCount}명',
                            color: const Color(0xFFDDF1FF),
                          ),
                        ),
                      ],
                    ),
                    if (report.repaymentTotal > 0) ...[
                      const SizedBox(height: 9),
                      _CohortNotice(
                        icon: Icons.savings_rounded,
                        text:
                            '오늘 만기 대여금 ${_money(report.repaymentTotal)}원이 국가계좌로 자동상환됐어. 이자 수입 ${_money(report.loanInterestIncome)}원 포함.',
                      ),
                    ],
                    if (report.borrowingRepaymentTotal > 0) ...[
                      const SizedBox(height: 9),
                      _CohortNotice(
                        icon: Icons.warning_amber_rounded,
                        text:
                            '오늘 동기 차입금 ${_money(report.borrowingRepaymentTotal)}원을 자동상환했어. 이자 비용 ${_money(report.loanInterestExpense)}원 포함.',
                      ),
                    ],
                    const SizedBox(height: 11),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _ink, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          const _CohortResultHeader(),
                          for (
                            var index = 0;
                            index < rankedRows.length;
                            index++
                          )
                            _CohortResultRow(
                              state: _state,
                              rank: index + 1,
                              row: rankedRows[index],
                              alternate: index.isOdd,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                    if (_state.needsTradingRecovery ||
                        todayBorrowing != null ||
                        _state.cohortInvestments.hasOutstandingPlayerBorrowing)
                      Container(
                        key: const Key('cohort-emergency-borrow-card'),
                        margin: const EdgeInsets.only(bottom: 13),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE1E6),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _ink, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.crisis_alert_rounded, color: _coral),
                                SizedBox(width: 7),
                                Text(
                                  '파산 구제 · 동기에게 빌리기',
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '보유 주식이 없고 주문 가능금이 1만원 미만일 때만 가능 · $cohortLoanTermDays일 단리 ${(cohortLoanInterestRateBps / 100).toStringAsFixed(0)}% · 미상환 중 추가 차입 금지',
                              style: const TextStyle(
                                color: Color(0xFF88404E),
                                fontSize: 9,
                                height: 1.4,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (todayBorrowing != null)
                              _CohortNotice(
                                icon: Icons.check_circle_rounded,
                                text:
                                    '${todayBorrowing.borrowerName}에게 ${_money(todayBorrowing.principal)}원 차입 · 만기 상환액 ${_money(todayBorrowing.totalDue)}원',
                              )
                            else if (_state
                                .cohortInvestments
                                .hasOutstandingPlayerBorrowing)
                              Text(
                                '기존 동기 차입금 ${_money(_state.cohortInvestments.outstandingLoanPayables)}원을 먼저 갚아야 해.',
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            else if (eligibleLenders.isEmpty)
                              const Text(
                                '지금 여유 자금이 있는 동기가 없어.',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            else
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  for (final lender in eligibleLenders)
                                    OutlinedButton.icon(
                                      key: Key(
                                        'cohort-borrow-lender-${lender.investorId}',
                                      ),
                                      onPressed: _busy || loanUsed
                                          ? null
                                          : () {
                                              final account = _state
                                                  .cohortInvestments
                                                  .accountFor(
                                                    lender.investorId,
                                                  );
                                              final maximum = math.min(
                                                cohortPlayerBorrowingLimit,
                                                math.max(
                                                  0,
                                                  account.balance -
                                                      cohortNpcEmergencyReserve,
                                                ),
                                              );
                                              _borrow(lender, maximum);
                                            },
                                      icon: const Icon(
                                        Icons.handshake_rounded,
                                        size: 16,
                                      ),
                                      label: Text(lender.name),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _ink,
                                        side: const BorderSide(
                                          color: _coral,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE9ED),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _ink, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.volunteer_activism_rounded,
                                color: _coral,
                              ),
                              SizedBox(width: 7),
                              Text(
                                '오늘 한 번 돈 빌려주기',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            '동기 한 명에게 하루 한 번만 가능해. 7일 단리 12%이며 대여는 호감도를 사는 행동이 아니야.',
                            style: TextStyle(
                              color: Color(0xFF6D7892),
                              fontSize: 9,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (loanUsed && todayLoan != null)
                            _CohortNotice(
                              icon: Icons.check_circle_rounded,
                              text:
                                  '${todayLoan.borrowerName}에게 ${_money(todayLoan.principal)}원 대여 완료 · $cohortLoanTermDays일 뒤 ${_money(todayLoan.totalDue)}원 상환',
                            )
                          else if (eligibleBorrowers.isEmpty)
                            const Text(
                              '오늘 대여할 수 있는 동기가 없어.',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          else if (_state.withdrawableBrokerageCash <= 0)
                            const Text(
                              '출금 가능한 국가계좌 현금이 없어 지금은 빌려줄 수 없어.',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                for (final borrower in eligibleBorrowers)
                                  OutlinedButton.icon(
                                    key: Key(
                                      'cohort-loan-borrower-${borrower.investorId}',
                                    ),
                                    onPressed: _busy
                                        ? null
                                        : () {
                                            final maximum = math.min(
                                              _state.withdrawableBrokerageCash,
                                              cohortPlayerBorrowingLimit,
                                            );
                                            _lend(borrower, maximum);
                                          },
                                    icon: const Icon(
                                      Icons.currency_exchange_rounded,
                                      size: 16,
                                    ),
                                    label: Text(borrower.name),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _ink,
                                      side: const BorderSide(
                                        color: _coral,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    key: const Key('cohort-result-finish-button'),
                    onPressed: _busy ? null : _finish,
                    style: FilledButton.styleFrom(
                      backgroundColor: _ink,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      _busy
                          ? '저장 중…'
                          : widget.loanOnly
                          ? '점호 화면으로 돌아가기'
                          : '결과 확인하고 저녁으로',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CohortResultMetric extends StatelessWidget {
  const _CohortResultMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _ink, width: 1.7),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6D7892),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          detail,
          style: const TextStyle(
            color: Color(0xFF58637A),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CohortResultHeader extends StatelessWidget {
  const _CohortResultHeader();

  @override
  Widget build(BuildContext context) => Container(
    color: _ink,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    child: const Row(
      children: [
        SizedBox(width: 31, child: Text('순위', style: _headerStyle)),
        Expanded(flex: 5, child: Text('이름 · 오늘 종목', style: _headerStyle)),
        Expanded(
          flex: 3,
          child: Text('오늘 손익', textAlign: TextAlign.right, style: _headerStyle),
        ),
        Expanded(
          flex: 3,
          child: Text('총 수익률', textAlign: TextAlign.right, style: _headerStyle),
        ),
      ],
    ),
  );

  static const _headerStyle = TextStyle(
    color: Colors.white,
    fontSize: 8,
    fontWeight: FontWeight.w900,
  );
}

class _CohortResultRow extends StatelessWidget {
  const _CohortResultRow({
    required this.state,
    required this.rank,
    required this.row,
    required this.alternate,
  });

  final GameState state;
  final int rank;
  final CohortDailyInvestmentResult row;
  final bool alternate;

  @override
  Widget build(BuildContext context) {
    final profitColor = row.profitLoss > 0
        ? const Color(0xFFE85A5A)
        : row.profitLoss < 0
        ? const Color(0xFF3B78C8)
        : const Color(0xFF737A89);
    final rateColor = row.returnRateBps > 0
        ? const Color(0xFFE85A5A)
        : row.returnRateBps < 0
        ? const Color(0xFF3B78C8)
        : const Color(0xFF737A89);
    return Semantics(
      button: true,
      label: '${row.name} 상세 정보 열기',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showCohortInvestorDetail(
          context,
          state: state,
          investorId: row.investorId,
          fallbackName: row.name,
        ),
        child: Container(
          key: Key('cohort-result-row-${row.investorId}'),
          color: row.isPlayer
              ? const Color(0xFFFFF1B9)
              : alternate
              ? const Color(0xFFF7F9FC)
              : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 31,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.isPlayer ? '${row.name} · 나' : row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      row.assetName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF788094),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  '${_cohortSignedMoney(row.profitLoss)}원',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: profitColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _cohortSignedPercent(row.returnRateBps),
                      key: Key('cohort-result-rate-${row.investorId}'),
                      maxLines: 1,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: rateColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${_money(row.totalAmount)}원',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF788094),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CohortNotice extends StatelessWidget {
  const _CohortNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _coral, width: 1.2),
    ),
    child: Row(
      children: [
        Icon(icon, color: _coral, size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _ink,
              fontSize: 9,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

String _cohortSignedMoney(int value) =>
    '${value > 0 ? '+' : ''}${_money(value)}';

/// 국가원금 대비 누적 수익률을 소수 첫째 자리까지 표시한다.
String _cohortSignedPercent(int rateBps) {
  final percent = rateBps / 100;
  return '${rateBps > 0 ? '+' : ''}${percent.toStringAsFixed(1)}%';
}

class CohortDailyRollCallScreen extends StatelessWidget {
  const CohortDailyRollCallScreen({
    super.key,
    required this.state,
    required this.report,
    this.onOpenCohortFinance,
  });

  final GameState state;
  final CohortDailyRollCallReport report;
  final Future<void> Function()? onOpenCohortFinance;

  Map<String, int> _monthlyTotals() {
    final closingDate = state.dateForDay(report.day);
    final totals = <String, int>{};
    for (final daily in state.cohortInvestments.rollCallReports) {
      final date = state.dateForDay(daily.day);
      if (date.year != closingDate.year || date.month != closingDate.month) {
        continue;
      }
      for (final row in daily.rows) {
        totals[row.investorId] =
            (totals[row.investorId] ?? 0) + row.dailyProfitLoss;
      }
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final ranked = report.rankedRows;
    final monthly = _monthlyTotals();
    final profitableCount = ranked
        .where((row) => row.dailyProfitLoss > 0)
        .length;
    final date = state.dateForDay(report.day);
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('cohort-daily-roll-call-screen'),
        backgroundColor: const Color(0xFF101B32),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  key: const Key('cohort-roll-call-scroll'),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  children: [
                    _RollCallTeacherIntro(
                      date: date,
                      profitableCount: profitableCount,
                    ),
                    const SizedBox(height: 13),
                    _RollCallPodium(state: state, ranked: ranked),
                    const SizedBox(height: 13),
                    Container(
                      padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F2E5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFD7B66E),
                          width: 1.4,
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '결산 기준',
                            style: TextStyle(
                              color: Color(0xFF263451),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '열 명 모두 동일한 50,000원에서 시작했어요. 오늘 순위는 실제 일간손익 원금액으로 결정하고, 월간손익은 이번 달 누적 참고값으로 보여 줍니다. 카지노와 경마는 개인별로 하루 하나만 기록합니다.',
                            style: TextStyle(
                              color: Color(0xFF657087),
                              fontSize: 9.5,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 7),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _RollCallLegend('주식', Color(0xFF2F5F94)),
                              _RollCallLegend('카지노', Color(0xFF8A405E)),
                              _RollCallLegend('경마', Color(0xFF2C796D)),
                              _RollCallLegend(
                                '기타자금 · 예금/부동산 등',
                                Color(0xFF8B6C2E),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),
                    for (var index = 0; index < ranked.length; index++) ...[
                      TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 260 + index * 45),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, value, child) => Transform.translate(
                          offset: Offset(20 * (1 - value), 0),
                          child: Opacity(opacity: value, child: child),
                        ),
                        child: _RollCallRankingRow(
                          state: state,
                          rank: index + 1,
                          row: ranked[index],
                          monthlyProfitLoss:
                              monthly[ranked[index].investorId] ?? 0,
                        ),
                      ),
                      if (index != ranked.length - 1) const SizedBox(height: 7),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (onOpenCohortFinance != null) ...[
                      OutlinedButton.icon(
                        key: const Key('cohort-roll-call-finance-button'),
                        onPressed: onOpenCohortFinance,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(42),
                          foregroundColor: const Color(0xFFE6C46E),
                          side: const BorderSide(color: Color(0xFFE6C46E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.handshake_rounded, size: 18),
                        label: const Text(
                          '선택 · 동기 대여·재기 장부',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 7),
                    ],
                    FilledButton.icon(
                      key: const Key('cohort-roll-call-finish-button'),
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: const Color(0xFFE6C46E),
                        foregroundColor: const Color(0xFF182640),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.nights_stay_rounded, size: 19),
                      label: const Text(
                        '점호 확인 · 데시멀톡/관계 시간',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RollCallTeacherIntro extends StatelessWidget {
  const _RollCallTeacherIntro({
    required this.date,
    required this.profitableCount,
  });

  final DateTime date;
  final int profitableCount;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('cohort-roll-call-teacher-intro'),
    height: 174,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF22365B), Color(0xFF16233F)],
      ),
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: const Color(0xFFE6C46E), width: 1.5),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 14,
          offset: Offset(0, 7),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        Positioned(
          right: -14,
          bottom: -48,
          width: 154,
          height: 224,
          child: Image.asset(
            _stockTeacherPoseBook,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, _, _) => const Align(
              alignment: Alignment.center,
              child: Icon(
                Icons.supervisor_account_rounded,
                size: 72,
                color: Color(0x66FFFFFF),
              ),
            ),
          ),
        ),
        Positioned.fill(
          right: 108,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} · 20:00',
                  style: const TextStyle(
                    color: Color(0xFFE6C46E),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  '저녁 점호 · 오늘의 결과',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: _hubDisplayFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '한서윤 운영관  “오늘 번 돈으로 열 명의 순위를 발표할게요. 수익은 빨간색, 손실은 파란색으로 읽습니다.”',
                  style: const TextStyle(
                    color: Color(0xFFE6EBF4),
                    fontSize: 9.5,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '오늘 수익 $profitableCount명 · 손실/보합 ${10 - profitableCount}명',
                  style: const TextStyle(
                    color: Color(0xFFAFC7E9),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
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

class _RollCallPodium extends StatelessWidget {
  const _RollCallPodium({required this.state, required this.ranked});

  final GameState state;
  final List<CohortDailyRollCallRow> ranked;

  @override
  Widget build(BuildContext context) {
    if (ranked.length < 3) return const SizedBox.shrink();
    return Container(
      key: const Key('cohort-roll-call-podium'),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2945),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFF405378)),
      ),
      child: Column(
        children: [
          const Text(
            '오늘의 시상대',
            style: TextStyle(
              color: Color(0xFFE6C46E),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _RollCallPodiumPlace(
                  state: state,
                  rank: 2,
                  row: ranked[1],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _RollCallPodiumPlace(
                  state: state,
                  rank: 1,
                  row: ranked[0],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _RollCallPodiumPlace(
                  state: state,
                  rank: 3,
                  row: ranked[2],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RollCallPodiumPlace extends StatelessWidget {
  const _RollCallPodiumPlace({
    required this.state,
    required this.rank,
    required this.row,
  });

  final GameState state;
  final int rank;
  final CohortDailyRollCallRow row;

  @override
  Widget build(BuildContext context) {
    final height = rank == 1
        ? 88.0
        : rank == 2
        ? 74.0
        : 66.0;
    final medal = rank == 1
        ? const Color(0xFFE6C46E)
        : rank == 2
        ? const Color(0xFFB9C6D8)
        : const Color(0xFFC58A61);
    return Semantics(
      button: true,
      label: '${row.name} 상세 정보 열기',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showCohortInvestorDetail(
          context,
          state: state,
          investorId: row.investorId,
          fallbackName: row.name,
        ),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            color: medal.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: medal, width: rank == 1 ? 1.8 : 1.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$rank위',
                style: TextStyle(
                  color: medal,
                  fontSize: rank == 1 ? 17 : 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                row.isPlayer ? '${row.name} · 나' : row.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _rollCallSignedMoney(row.dailyProfitLoss),
                maxLines: 1,
                style: TextStyle(
                  color: _rollCallProfitColor(row.dailyProfitLoss),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RollCallRankingRow extends StatelessWidget {
  const _RollCallRankingRow({
    required this.state,
    required this.rank,
    required this.row,
    required this.monthlyProfitLoss,
  });

  final GameState state;
  final int rank;
  final CohortDailyRollCallRow row;
  final int monthlyProfitLoss;

  String get _activitySummary {
    if (row.leisureActivity == '미참여') return '오늘 오후 활동 없음';
    if (row.leisureActivity == '그냥 넘어감') return '오늘은 그냥 넘어감';
    if (row.leisureActivity == '자금 부족') return '오늘 자금 부족으로 미이용';
    if (row.afternoonStake > 0) {
      final recovery = row.afternoonStateRecovery > 0
          ? ' · 국가 환수 ${_money(row.afternoonStateRecovery)}원'
          : '';
      return '오늘 ${row.leisureActivity} · 베팅 ${_money(row.afternoonStake)}원$recovery';
    }
    return '오늘 ${row.leisureActivity}';
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${row.name} 상세 정보 열기',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showCohortInvestorDetail(
        context,
        state: state,
        investorId: row.investorId,
        fallbackName: row.name,
      ),
      child: Container(
        key: Key('cohort-roll-call-row-${row.investorId}'),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
        decoration: BoxDecoration(
          color: row.isPlayer
              ? const Color(0xFFFFF2C9)
              : const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: row.isPlayer
                ? const Color(0xFFE0B94F)
                : const Color(0xFFD6DCE7),
            width: row.isPlayer ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 31,
                  height: 31,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: rank <= 3
                        ? const Color(0xFFE6C46E)
                        : const Color(0xFF31415F),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: rank <= 3 ? const Color(0xFF25334E) : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.isPlayer ? '${row.name} · 나' : row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF263451),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        _activitySummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF778197),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '일간 ${_rollCallSignedMoney(row.dailyProfitLoss)}',
                      key: Key('cohort-roll-call-daily-${row.investorId}'),
                      style: TextStyle(
                        color: _rollCallProfitColor(row.dailyProfitLoss),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '월간 ${_rollCallSignedMoney(monthlyProfitLoss)}',
                      key: Key('cohort-roll-call-monthly-${row.investorId}'),
                      style: TextStyle(
                        color: _rollCallProfitColor(monthlyProfitLoss),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _RollCallBreakdown(
                    label: '주식',
                    amount: row.stockProfitLoss,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _RollCallBreakdown(
                    label:
                        row.leisureActivity == '카지노' ||
                            row.leisureActivity == '경마'
                        ? row.leisureActivity
                        : '카지노/경마',
                    amount: row.leisureProfitLoss,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _RollCallBreakdown(
                    label: '기타자금',
                    amount: row.otherProfitLoss,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _RollCallBreakdown extends StatelessWidget {
  const _RollCallBreakdown({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFE9EDF4),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF6A7489),
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          _rollCallSignedMoney(amount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _rollCallProfitColor(amount),
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _RollCallLegend extends StatelessWidget {
  const _RollCallLegend(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.55)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900),
    ),
  );
}

Color _rollCallProfitColor(int value) => value > 0
    ? const Color(0xFFD94A51)
    : value < 0
    ? const Color(0xFF3567D6)
    : const Color(0xFF777F8E);

String _rollCallSignedMoney(int value) =>
    '${value > 0 ? '+' : ''}${_money(value)}원';

Future<void> _showCohortInvestorDetail(
  BuildContext context, {
  required GameState state,
  required String investorId,
  String? fallbackName,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (context) => FractionallySizedBox(
    heightFactor: 0.9,
    child: _CohortInvestorDetailSheet(
      state: state,
      investorId: investorId,
      fallbackName: fallbackName,
    ),
  ),
);

class _CohortAssetLocation {
  const _CohortAssetLocation({required this.label, required this.amount});

  final String label;
  final int amount;
}

class _CohortAssetSnapshot {
  const _CohortAssetSnapshot({
    required this.grossAssets,
    required this.liabilities,
    required this.locations,
    required this.note,
  });

  final int grossAssets;
  final int liabilities;
  final List<_CohortAssetLocation> locations;
  final String note;

  int get netWorth => grossAssets - liabilities;
}

_CohortAssetSnapshot _cohortAssetSnapshot(GameState state, String investorId) {
  if (investorId == 'player') {
    final locations = <_CohortAssetLocation>[
      _CohortAssetLocation(label: '생활·회사 통장', amount: state.bankCash),
      _CohortAssetLocation(label: '국가계좌 예수금', amount: state.brokerageCash),
      if (state.portfolioCost > 0)
        _CohortAssetLocation(
          label: '보유 주식 · 취득 장부가',
          amount: state.portfolioCost,
        ),
      if (state.banking.termDepositAssetValueAt(state.day) > 0)
        _CohortAssetLocation(
          label: '정기예금',
          amount: state.banking.termDepositAssetValueAt(state.day),
        ),
      if (state.personalFinance.casino.chipBalance > 0)
        _CohortAssetLocation(
          label: '데시멀 카지노 보관 칩',
          amount: state.personalFinance.casino.chipBalance,
        ),
      if (state.personalFinance.estimatedPropertyValueAt(state.day) > 0)
        _CohortAssetLocation(
          label: '보유 부동산 · 현재 추정가',
          amount: state.personalFinance.estimatedPropertyValueAt(state.day),
        ),
      if (state.businesses.totalBookValue > 0)
        _CohortAssetLocation(
          label: '보유 사업체 · 장부가',
          amount: state.businesses.totalBookValue,
        ),
      if (state.company.investmentBookValue > 0)
        _CohortAssetLocation(
          label: '인수기업 투자 장부가',
          amount: state.company.investmentBookValue,
        ),
      if (state.cohortInvestments.outstandingLoanReceivables > 0)
        _CohortAssetLocation(
          label: '동기에게 받을 대여 원금',
          amount: state.cohortInvestments.outstandingLoanReceivables,
        ),
      if (state.story.selfRelianceReserve > 0)
        _CohortAssetLocation(
          label: '자립 적립금',
          amount: state.story.selfRelianceReserve,
        ),
    ];
    return _CohortAssetSnapshot(
      grossAssets: state.balanceSheetGrossAssets(),
      liabilities: state.totalKnownLiabilities,
      locations: locations,
      note: '주식은 현재 시세를 불러오지 않는 인물 카드이므로 취득 장부가로 표시합니다.',
    );
  }

  final account = state.cohortInvestments.accountFor(investorId);
  CohortDailyInvestmentResult? latestInvestment;
  for (final report in state.cohortInvestments.reports.reversed) {
    final row = report.resultFor(investorId);
    if (row == null) continue;
    latestInvestment = row;
    break;
  }
  final stockAllocation = math.min(
    account.balance,
    latestInvestment?.investedAmount ?? 0,
  );
  final otherFunds = math.max(0, account.balance - stockAllocation);
  var loanReceivable = 0;
  var loanPayable = 0;
  for (final loan in state.cohortInvestments.loans.where(
    (loan) => !loan.isRepaid && loan.borrowerId == investorId,
  )) {
    if (loan.direction == CohortLoanDirection.playerBorrows) {
      loanReceivable += loan.outstanding;
    } else {
      loanPayable += loan.outstanding;
    }
  }
  return _CohortAssetSnapshot(
    grossAssets: account.balance + loanReceivable,
    liabilities: loanPayable,
    locations: <_CohortAssetLocation>[
      if (stockAllocation > 0)
        _CohortAssetLocation(label: '최근 주식 운용 배정', amount: stockAllocation),
      _CohortAssetLocation(label: '데시멀 계좌 유동·기타자금', amount: otherFunds),
      if (loanReceivable > 0)
        _CohortAssetLocation(label: '플레이어에게 받을 대여금', amount: loanReceivable),
    ],
    note: '동기 장부는 최근 주식 운용 배정액과 나머지 유동·예금·부동산 통합자금을 구분합니다.',
  );
}

String _playerAbilitySummary(GameState state) {
  final trait = switch (state.story.startingTrait) {
    StoryTrait.stability => '안정성과 손실 한도 관리',
    StoryTrait.innovation => '새 기술과 성장 기회 발견',
    StoryTrait.analysis => '자료 분석과 가격 검증',
    StoryTrait.control => '운영 통제와 실행 관리',
  };
  final skills = skillCatalog
      .where((skill) => state.progression.level >= skill.level)
      .map((skill) => skill.name)
      .toList(growable: false);
  return skills.isEmpty ? trait : '$trait · ${skills.join(' · ')}';
}

class _CohortInvestorDetailSheet extends StatelessWidget {
  const _CohortInvestorDetailSheet({
    required this.state,
    required this.investorId,
    this.fallbackName,
  });

  final GameState state;
  final String investorId;
  final String? fallbackName;

  @override
  Widget build(BuildContext context) {
    final isPlayer = investorId == 'player';
    final profile = isPlayer ? null : cohortCharacterProfileById(investorId);
    final name = isPlayer
        ? (state.story.playerName.trim().isEmpty
              ? '나'
              : state.story.playerName.trim())
        : profile?.name ?? fallbackName ?? investorId;
    final accent = Color(profile?.accentValue ?? 0xFFE0B94F);
    final currentAge = isPlayer
        ? '${state.story.ageOn(state.currentDate)}살'
        : profile?.ageLabelAt(state.currentDate) ?? '나이 미상';
    final birthday = isPlayer
        ? state.story.flagInt('playerBirthMonth') > 0 &&
                  state.story.flagInt('playerBirthDay') > 0
              ? '${state.story.playerBirthYear}.${state.story.flagInt('playerBirthMonth').toString().padLeft(2, '0')}.${state.story.flagInt('playerBirthDay').toString().padLeft(2, '0')}'
              : '${state.story.playerBirthYear}년생 · 생일 미설정'
        : profile?.birthdayLabel ?? '생일 미상';
    final girl = cohortGirlProfileById(investorId);
    final relationship = girl == null
        ? isPlayer
              ? '본인'
              : '호감도 수치 미적용'
        : '${state.relationships.progressFor(investorId).affection} / $relationshipMaxAffection · ${state.relationships.progressFor(investorId).stage.label}';
    final ability = isPlayer
        ? _playerAbilitySummary(state)
        : profile == null
        ? '능력 정보 없음'
        : '${profile.role} · ${profile.strength}';
    final assets = _cohortAssetSnapshot(state, investorId);

    return Material(
      key: Key('cohort-investor-detail-$investorId'),
      color: const Color(0xFFF7F2E8),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 13),
            color: const Color(0xFF182640),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent),
                  ),
                  child: Icon(
                    isPlayer
                        ? Icons.person_outline_rounded
                        : Icons.badge_rounded,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isPlayer ? '$name · 나' : name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        '현재 인물 정보 · 실제 자산 장부',
                        style: TextStyle(
                          color: Color(0xFFB9C6DA),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('cohort-investor-detail-close-$investorId'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 26),
              children: <Widget>[
                _CohortInvestorIdentityPanel(
                  age: currentAge,
                  birthday: birthday,
                  relationship: relationship,
                  ability: ability,
                  accent: accent,
                ),
                const SizedBox(height: 12),
                _CohortInvestorAssetPanel(
                  snapshot: assets,
                  accent: accent,
                  investorId: investorId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CohortInvestorIdentityPanel extends StatelessWidget {
  const _CohortInvestorIdentityPanel({
    required this.age,
    required this.birthday,
    required this.relationship,
    required this.ability,
    required this.accent,
  });

  final String age;
  final String birthday;
  final String relationship;
  final String ability;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent.withValues(alpha: 0.65), width: 1.5),
    ),
    child: Column(
      children: <Widget>[
        _CohortInvestorFact(label: '현재 나이', value: age),
        _CohortInvestorFact(label: '생일', value: birthday),
        _CohortInvestorFact(label: '현재 호감도', value: relationship),
        _CohortInvestorFact(label: '고유 능력', value: ability, last: true),
      ],
    ),
  );
}

class _CohortInvestorFact extends StatelessWidget {
  const _CohortInvestorFact({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFE6E9EF))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7A8497),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF263451),
              fontSize: 10.5,
              height: 1.4,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CohortInvestorAssetPanel extends StatelessWidget {
  const _CohortInvestorAssetPanel({
    required this.snapshot,
    required this.accent,
    required this.investorId,
  });

  final _CohortAssetSnapshot snapshot;
  final Color accent;
  final String investorId;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('cohort-investor-assets-$investorId'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF182640),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: accent, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          '총자산 · 자금 위치',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: _CohortAssetTotal(
                label: '총자산',
                amount: snapshot.grossAssets,
                color: const Color(0xFFE6C46E),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _CohortAssetTotal(
                label: '총부채',
                amount: snapshot.liabilities,
                color: const Color(0xFF8BB8E8),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _CohortAssetTotal(
                label: '순자산',
                amount: snapshot.netWorth,
                color: const Color(0xFFFFA0A8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        for (final location in snapshot.locations)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: accent,
                  size: 15,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    location.label,
                    style: const TextStyle(
                      color: Color(0xFFD7DFEC),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${_money(location.amount)}원',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text(
          snapshot.note,
          style: const TextStyle(
            color: Color(0xFFAEBAD0),
            fontSize: 8.5,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CohortAssetTotal extends StatelessWidget {
  const _CohortAssetTotal({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF263857),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFAEBAD0),
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '${_money(amount)}원',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
