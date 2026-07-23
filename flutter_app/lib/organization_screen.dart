part of 'main.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({
    super.key,
    required this.state,
    required this.onRequestFamilyHelp,
    this.onRepayAcademyTuitionDebt,
    this.onHireEmployee,
    this.onLaunchFund,
  });

  final GameState state;
  final Future<GameState> Function(String helperId) onRequestFamilyHelp;
  final Future<FinanceActionResult> Function()? onRepayAcademyTuitionDebt;
  final Future<GameState> Function(String candidateId)? onHireEmployee;
  final Future<GameState> Function()? onLaunchFund;

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  late GameState _state = widget.state;
  String? _busyHelperId;
  String? _busyCandidateId;
  bool _fundBusy = false;
  bool _repayingTuition = false;
  String _selectedHelperId = 'mother';

  bool get _hiringUnlocked => _state.currentDate.year >= 2003;

  Future<void> _requestHelp(FamilyHelperStatus helper) async {
    if (_busyHelperId != null || !helper.canHelpOn(_state.day)) return;
    setState(() => _busyHelperId = helper.id);
    late GameState next;
    try {
      next = await widget.onRequestFamilyHelp(helper.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyHelperId = null);
      _showSaveFailure(context);
      return;
    }
    if (!mounted) return;
    setState(() {
      _state = next;
      _busyHelperId = null;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${helper.name}의 조언을 오늘 조사노트에 추가했어요.')),
      );
  }

  Future<void> _hire(EmployeeProfile candidate) async {
    if (_busyCandidateId != null) return;
    setState(() => _busyCandidateId = candidate.id);
    try {
      final next = await widget.onHireEmployee?.call(candidate.id) ?? _state;
      if (!mounted) return;
      final hired = next.organization.employees.any(
        (item) => item.id == candidate.id,
      );
      setState(() {
        _state = next;
        _busyCandidateId = null;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              hired
                  ? '${candidate.name}님이 합류했습니다.'
                  : '채용 계약금 ${_money(candidate.salaryMonthly ~/ 2)}원이 필요합니다.',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyCandidateId = null);
      _showSaveFailure(context);
    }
  }

  Future<void> _launchFund() async {
    if (_fundBusy) return;
    setState(() => _fundBusy = true);
    try {
      final next = await widget.onLaunchFund?.call() ?? _state;
      if (!mounted) return;
      setState(() {
        _state = next;
        _fundBusy = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              next.story.fundLaunched
                  ? '첫 외부자금 펀드가 출범했습니다.'
                  : '2004년 이후 · 직원 1명 · 평판 12가 필요합니다.',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() => _fundBusy = false);
      _showSaveFailure(context);
    }
  }

  Future<void> _repayAcademyTuition() async {
    if (_repayingTuition || widget.onRepayAcademyTuitionDebt == null) return;
    setState(() => _repayingTuition = true);
    try {
      final result = await widget.onRepayAcademyTuitionDebt!.call();
      if (!mounted) return;
      setState(() {
        _state = result.state;
        _repayingTuition = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _repayingTuition = false);
      _showSaveFailure(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final organization = _state.organization;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EC),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SafeArea(
            child: Column(
              children: [
                _OrganizationHeader(onBack: () => Navigator.of(context).pop()),
                _SceneClockStrip(
                  location: '우리 집 거실 · 사람들',
                  caption: '가족에게 조사를 부탁하고 역할을 나눈다.',
                  minute: _state.marketMinute,
                  costLabel: '도움 요청 +30분',
                  dark: false,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _OrganizationSummary(state: _state),
                      const SizedBox(height: 22),
                      const Text(
                        '지금 함께하는 사람들',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        '가족은 무료 직원이 아닙니다. 하루에 한 번만 부탁할 수 있고, 반복해서 부탁하면 피로가 쌓여요.',
                        style: TextStyle(
                          color: Color(0xFF747B88),
                          fontSize: 11,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 13),
                      _FamilyAssignmentBoard(
                        state: _state,
                        helpers: organization.familyHelpers,
                        selectedId: _selectedHelperId,
                        day: _state.day,
                        busyHelperId: _busyHelperId,
                        repayingTuition: _repayingTuition,
                        onSelected: (helperId) =>
                            setState(() => _selectedHelperId = helperId),
                        onRequest: _requestHelp,
                        onRepayTuition: _repayAcademyTuition,
                      ),
                      const SizedBox(height: 16),
                      _HiringSection(
                        state: _state,
                        unlocked: _hiringUnlocked,
                        busyCandidateId: _busyCandidateId,
                        fundBusy: _fundBusy,
                        onHire: _hire,
                        onLaunchFund: _launchFund,
                      ),
                      if (organization.helpLog.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        const Text(
                          '최근 도움 기록',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 9),
                        ...organization.helpLog.reversed
                            .take(4)
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 5),
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF58A47B),
                                        size: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        entry,
                                        style: const TextStyle(
                                          color: Color(0xFF626A78),
                                          fontSize: 11,
                                          height: 1.4,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrganizationHeader extends StatelessWidget {
  const _OrganizationHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
    child: Row(
      children: [
        IconButton(
          key: const Key('close-organization-button'),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        const Expanded(
          child: Text(
            '사람들',
            style: TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Icon(Icons.groups_2_rounded, color: _coral),
      ],
    ),
  );
}

class _OrganizationSummary extends StatelessWidget {
  const _OrganizationSummary({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final organization = state.organization;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF2E3953),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332E3953),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.companyName,
                  key: const Key('organization-company-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                key: const Key('employee-count-badge'),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '정식 직원 ${organization.employees.length}명',
                  style: const TextStyle(
                    color: _yellow,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _OrganizationMetric(
                label: '가족 피로도',
                value: '${organization.familyFatigue}%',
              ),
              _OrganizationMetric(
                label: '도움 기록',
                value: '${organization.researchHelpCount}회',
              ),
              _OrganizationMetric(
                label: '평판 / 월급',
                value:
                    '${state.story.reputation} / ${_money(organization.monthlyPayroll)}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: organization.cultureTags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '# $tag',
                      style: const TextStyle(
                        color: Color(0xFFDCE6FA),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _OrganizationMetric extends StatelessWidget {
  const _OrganizationMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9EABC5),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _FamilyAssignmentBoard extends StatelessWidget {
  const _FamilyAssignmentBoard({
    required this.state,
    required this.helpers,
    required this.selectedId,
    required this.day,
    required this.busyHelperId,
    required this.repayingTuition,
    required this.onSelected,
    required this.onRequest,
    required this.onRepayTuition,
  });

  final GameState state;
  final List<FamilyHelperStatus> helpers;
  final String selectedId;
  final int day;
  final String? busyHelperId;
  final bool repayingTuition;
  final ValueChanged<String> onSelected;
  final ValueChanged<FamilyHelperStatus> onRequest;
  final VoidCallback onRepayTuition;

  @override
  Widget build(BuildContext context) {
    final selected = helpers.firstWhere(
      (helper) => helper.id == selectedId,
      orElse: () => helpers.first,
    );
    final available = selected.canHelpOn(day);
    final busy = busyHelperId == selected.id;
    final fatigueColor = selected.fatigue >= 65
        ? const Color(0xFFF06464)
        : selected.fatigue >= 35
        ? const Color(0xFFE4A43A)
        : const Color(0xFF58A47B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4DDD0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_ind_rounded, color: _coral),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  '오늘 조사팀 배치',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '조언자 1명',
                  style: TextStyle(
                    color: Color(0xFF8E6C25),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 190,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF2D8), Color(0xFFF0E6D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                SizedBox(
                  width: 138,
                  height: 190,
                  child: Image.asset(
                    selected.asset,
                    key: ValueKey('assignment-portrait-${selected.id}'),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selected.name} · ${selected.relation}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          selected.role,
                          style: const TextStyle(
                            color: Color(0xFF56647A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selected.specialty,
                          style: const TextStyle(
                            color: Color(0xFF7E6A46),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Expanded(
                          child: Text(
                            selected.effect,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF737985),
                              fontSize: 9,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '피로 ${selected.fatigue}',
                              style: TextStyle(
                                color: fatigueColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  minHeight: 5,
                                  value: selected.fatigue / 100,
                                  backgroundColor: const Color(0x33FFFFFF),
                                  valueColor: AlwaysStoppedAnimation(
                                    fatigueColor,
                                  ),
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
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              key: Key('family-help-${selected.id}'),
              onPressed: available && busyHelperId == null
                  ? () => onRequest(selected)
                  : null,
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: Text(
                busy
                    ? '기록 중…'
                    : selected.lastHelpDay == day
                    ? '오늘 도움 완료'
                    : selected.fatigue >= 80
                    ? '오늘은 쉬어야 해요'
                    : '${selected.name}에게 조사 도움 부탁하기',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF536A96),
                disabledBackgroundColor: const Color(0xFFD5D7DA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (selected.id == 'father' &&
              state.story.academyTuitionOriginal > 0) ...[
            const SizedBox(height: 12),
            _AcademyTuitionDebtCard(
              debt: state.story.academyTuitionDebt,
              bankCash: state.bankCash,
              repaying: repayingTuition,
              onRepay: onRepayTuition,
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            '아래 카드에서 조언자를 선택하세요',
            style: TextStyle(
              color: Color(0xFF878C95),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: helpers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final helper = helpers[index];
                final selectedCard = helper.id == selected.id;
                return InkWell(
                  key: Key('assignment-card-${helper.id}'),
                  onTap: () => onSelected(helper.id),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 78,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: selectedCard
                          ? const Color(0xFFFFF1C7)
                          : const Color(0xFFF7F7F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selectedCard ? _coral : const Color(0xFFE1E2E3),
                        width: selectedCard ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9E1D5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              helper.asset,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          helper.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _ink,
                            fontSize: 10,
                            fontWeight: selectedCard
                                ? FontWeight.w900
                                : FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademyTuitionDebtCard extends StatelessWidget {
  const _AcademyTuitionDebtCard({
    required this.debt,
    required this.bankCash,
    required this.repaying,
    required this.onRepay,
  });

  final int debt;
  final int bankCash;
  final bool repaying;
  final VoidCallback onRepay;

  @override
  Widget build(BuildContext context) {
    final repaid = debt <= 0;
    final canRepay = !repaid && !repaying && bankCash >= debt;
    final shortfall = debt > bankCash ? debt - bankCash : 0;

    return Container(
      key: const Key('academy-tuition-debt-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: repaid ? const Color(0xFFEAF6EF) : const Color(0xFFFFF5E3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: repaid ? const Color(0xFFB9DBC6) : const Color(0xFFE9C98B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                repaid ? Icons.task_alt_rounded : Icons.school_outlined,
                size: 19,
                color: repaid
                    ? const Color(0xFF3D8A5F)
                    : const Color(0xFF9A6820),
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  '아빠가 먼저 낸 주식학원비',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                repaid ? '상환 완료' : '${_money(debt)}원',
                style: TextStyle(
                  color: repaid
                      ? const Color(0xFF3D8A5F)
                      : const Color(0xFFB05F39),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            repaid
                ? '약속을 지켰습니다. 교육비 채무가 가족 장부에서 정리됐어요.'
                : shortfall > 0
                ? '회사 통장에 ${_money(shortfall)} 더 필요해요. 증권 예수금은 자동 출금하지 않습니다.'
                : '투자금이 아닌 교육비 채무입니다. 회사 통장에서 전액 상환합니다.',
            style: const TextStyle(
              color: Color(0xFF6E675D),
              fontSize: 9,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: FilledButton.icon(
              key: const Key('repay-academy-tuition-button'),
              onPressed: canRepay ? onRepay : null,
              icon: repaying
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      repaid
                          ? Icons.check_rounded
                          : Icons.account_balance_wallet_outlined,
                      size: 17,
                    ),
              label: Text(
                repaying
                    ? '상환 기록 중…'
                    : repaid
                    ? '학원비 전액 상환 완료'
                    : '학원비 ${_money(debt)} 갚기',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9A6820),
                disabledBackgroundColor: repaid
                    ? const Color(0xFFB9DBC6)
                    : const Color(0xFFD8D4CC),
                disabledForegroundColor: repaid
                    ? const Color(0xFF356D4D)
                    : const Color(0xFF77736C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                textStyle: const TextStyle(
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
}

class _HiringSection extends StatelessWidget {
  const _HiringSection({
    required this.state,
    required this.unlocked,
    required this.busyCandidateId,
    required this.fundBusy,
    required this.onHire,
    required this.onLaunchFund,
  });

  final GameState state;
  final bool unlocked;
  final String? busyCandidateId;
  final bool fundBusy;
  final ValueChanged<EmployeeProfile> onHire;
  final VoidCallback onLaunchFund;

  @override
  Widget build(BuildContext context) {
    final employees = state.organization.employees;
    final available = kHiringCandidates
        .where(
          (candidate) =>
              !employees.any((employee) => employee.id == candidate.id),
        )
        .toList();
    final canLaunchFund =
        state.currentDate.year >= 2004 &&
        employees.isNotEmpty &&
        state.story.reputation >= 12 &&
        !state.story.fundLaunched;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFEAF4FF) : const Color(0xFFE9E8E4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                unlocked ? Icons.badge_rounded : Icons.lock_clock_rounded,
                color: unlocked
                    ? const Color(0xFF397CC0)
                    : const Color(0xFF777C83),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  unlocked ? '채용 · 급여 · 펀드 성장' : '정식 채용은 2003년에 열려요',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            unlocked
                ? '후보의 능력·윤리·월 급여를 비교하세요. 계약금은 월 급여의 절반이며 급여와 사무실 임대료는 매월 원장에 반영됩니다.'
                : '그전에는 가족 조사팀과 함께 종잣돈과 평판을 쌓습니다.',
            style: const TextStyle(
              color: Color(0xFF626A76),
              fontSize: 11,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (unlocked && available.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...available.map(
              (candidate) => Card(
                margin: const EdgeInsets.only(bottom: 9),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(candidate.displayedGrade.label),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${candidate.name} · ${candidate.role.label}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '월 ${_money(candidate.salaryMonthly)}원 · 윤리 ${candidate.ethics} · ${candidate.specialties.join(' · ')}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FilledButton(
                          key: Key('hire-${candidate.id}'),
                          onPressed: busyCandidateId == null
                              ? () => onHire(candidate)
                              : null,
                          child: Text(
                            busyCandidateId == candidate.id
                                ? '계약 확인 중…'
                                : '계약금 ${_money(candidate.salaryMonthly ~/ 2)}원으로 채용',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (employees.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('현재 직원', style: TextStyle(fontWeight: FontWeight.w900)),
            ...employees.map(
              (employee) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(employee.displayedGrade.label),
                ),
                title: Text(employee.name),
                subtitle: Text(
                  '${employee.role.label} · 월 ${_money(employee.salaryMonthly)}원',
                ),
              ),
            ),
          ],
          const Divider(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '외부자금 펀드',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '평판 ${state.story.reputation}/12',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            state.story.fundLaunched
                ? '운용 중 · 외부 AUM ${_money(state.story.externalAum)}원 · 월 운용보수 자동 수입'
                : '2004년 이후 직원과 평판을 갖추면 외부 AUM과 반복 운용보수가 열립니다.',
            style: const TextStyle(fontSize: 10, height: 1.4),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              key: const Key('launch-fund-button'),
              onPressed: canLaunchFund && !fundBusy ? onLaunchFund : null,
              icon: const Icon(Icons.account_balance_rounded),
              label: Text(state.story.fundLaunched ? '첫 펀드 운용 중' : '첫 펀드 출범'),
            ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _UnlockChip(label: '2003 · 조사원'),
              _UnlockChip(label: '2004 · 작은 사무실'),
              _UnlockChip(label: '2006 · 정식 회사'),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnlockChip extends StatelessWidget {
  const _UnlockChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0x99FFFFFF),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF656C77),
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
