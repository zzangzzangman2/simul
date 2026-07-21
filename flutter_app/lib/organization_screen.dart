part of 'main.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({
    super.key,
    required this.state,
    required this.onRequestFamilyHelp,
  });

  final GameState state;
  final Future<GameState> Function(String helperId) onRequestFamilyHelp;

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  late GameState _state = widget.state;
  String? _busyHelperId;
  String _selectedHelperId = 'mother';

  bool get _hiringUnlocked => _state.currentDate.year >= 2003;

  Future<void> _requestHelp(FamilyHelperStatus helper) async {
    if (_busyHelperId != null || !helper.canHelpOn(_state.day)) return;
    setState(() => _busyHelperId = helper.id);
    final next = await widget.onRequestFamilyHelp(helper.id);
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
                        helpers: organization.familyHelpers,
                        selectedId: _selectedHelperId,
                        day: _state.day,
                        busyHelperId: _busyHelperId,
                        onSelected: (helperId) =>
                            setState(() => _selectedHelperId = helperId),
                        onRequest: _requestHelp,
                      ),
                      const SizedBox(height: 16),
                      _HiringSection(state: _state, unlocked: _hiringUnlocked),
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
              const Expanded(
                child: Text(
                  '가족 투자연구소',
                  style: TextStyle(
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
                label: '채용 해금',
                value: state.currentDate.year >= 2003 ? '가능' : '2003년',
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
    required this.helpers,
    required this.selectedId,
    required this.day,
    required this.busyHelperId,
    required this.onSelected,
    required this.onRequest,
  });

  final List<FamilyHelperStatus> helpers;
  final String selectedId;
  final int day;
  final String? busyHelperId;
  final ValueChanged<String> onSelected;
  final ValueChanged<FamilyHelperStatus> onRequest;

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

class _HiringSection extends StatelessWidget {
  const _HiringSection({required this.state, required this.unlocked});

  final GameState state;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final employees = state.organization.employees;
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
                  unlocked ? '첫 조사원 채용' : '정식 채용은 아직 일러요',
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
                ? employees.isEmpty
                      ? '대학 게시판과 지인 소개를 통해 첫 아르바이트 조사원 후보를 만날 수 있습니다.'
                      : '현재 ${employees.length}명의 직원이 있습니다. 능력과 윤리성은 별도로 평가합니다.'
                : '2000~2002년에는 가족 도움으로 조사 습관을 익힙니다. 2003년에 첫 아르바이트 조사원 이야기가 열립니다.',
            style: const TextStyle(
              color: Color(0xFF626A76),
              fontSize: 11,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _UnlockChip(label: '2003 · 조사원'),
              _UnlockChip(label: '2004 · 작은 사무실'),
              _UnlockChip(label: '2006 · 정식 회사'),
            ],
          ),
          if (employees.isNotEmpty) ...[
            const SizedBox(height: 13),
            ...employees.map(
              (employee) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(employee.displayedGrade.label),
                ),
                title: Text(employee.name),
                subtitle: Text(
                  '${employee.role.label} · ${employee.specialties.join(', ')}',
                ),
              ),
            ),
          ],
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
