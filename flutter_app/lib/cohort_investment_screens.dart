part of 'main.dart';

class CohortDailyResultScreen extends StatefulWidget {
  const CohortDailyResultScreen({
    super.key,
    required this.state,
    required this.onLend,
    required this.onBorrow,
    required this.onAcknowledge,
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
                  child: const Column(
                    children: [
                      Text(
                        '뚜둥!',
                        style: TextStyle(
                          color: _coral,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '오늘의 투자 결과',
                        style: TextStyle(
                          color: _ink,
                          fontFamily: _hubDisplayFont,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '15:00 종가 기준 · 데시멀 동기 10명',
                        style: TextStyle(
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
                    label: Text(_busy ? '저장 중…' : '결과 확인하고 저녁으로'),
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
    required this.rank,
    required this.row,
    required this.alternate,
  });

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
    return Container(
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
