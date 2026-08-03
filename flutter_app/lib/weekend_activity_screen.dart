part of 'main.dart';

class WeekendScheduleScreen extends StatefulWidget {
  const WeekendScheduleScreen({
    super.key,
    required this.state,
    required this.onComplete,
  });

  final GameState state;
  final Future<WeekendActivityResult> Function(WeekendActivityRequest request)
  onComplete;

  @override
  State<WeekendScheduleScreen> createState() => _WeekendScheduleScreenState();
}

class _WeekendScheduleScreenState extends State<WeekendScheduleScreen> {
  late GameState _state = widget.state;
  bool _busy = false;

  int get _remaining => weekendActivityPointsRemaining(_state);

  Future<void> _run(WeekendActivityRequest request) async {
    if (_busy || _remaining <= 0) return;
    setState(() => _busy = true);
    final result = await widget.onComplete(request);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.success) _state = result.state;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _openGiftPicker() async {
    String? giftId;
    String? girlId;
    final request = await showModalBottomSheet<WeekendActivityRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFBF2),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              18,
              0,
              18,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '주말 선물 고르기',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                RadioGroup<String>(
                  groupValue: giftId,
                  onChanged: (value) => setSheetState(() => giftId = value),
                  child: Column(
                    children: [
                      for (final gift in weekendGifts)
                        RadioListTile<String>(
                          value: gift.id,
                          title: Text('${gift.title} · ${_money(gift.cost)}원'),
                          subtitle: Text(gift.description),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  '받을 동기',
                  style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final profile in cohortGirlProfiles)
                      ChoiceChip(
                        label: Text(profile.name),
                        selected: girlId == profile.id,
                        onSelected: (_) =>
                            setSheetState(() => girlId = profile.id),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: giftId == null || girlId == null
                      ? null
                      : () => Navigator.pop(
                          sheetContext,
                          WeekendActivityRequest(
                            activityId: 'gift',
                            girlId: girlId,
                            giftId: giftId,
                          ),
                        ),
                  child: const Text('선물 건네기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (request != null) await _run(request);
  }

  Future<void> _confirmRest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('남은 시간을 쉴까?'),
        content: Text('남은 행동력 $_remaining칸을 모두 사용하고 낮 일정을 마친다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('쉬기'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(const WeekendActivityRequest(activityId: 'rest'));
    }
  }

  void _finish() {
    if (_remaining > 0 || _busy) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final recovery = _state.needsTradingRecovery;
    return PopScope(
      canPop: _remaining == 0,
      child: Scaffold(
        key: const Key('weekend-schedule-screen'),
        backgroundColor: const Color(0xFFFFF6DF),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFFFD66B),
          foregroundColor: _ink,
          title: const Text(
            '주말 자유 일정',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '행동력 $_remaining / $weekendActionPointsPerDay',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              key: const Key('weekend-schedule-list'),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    key: const Key('weekend-recommendation-card'),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: recovery ? const Color(0xFFFFDCE2) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: recovery ? _coral : _ink,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          recovery
                              ? Icons.crisis_alert_rounded
                              : Icons.weekend_rounded,
                          color: recovery ? _coral : const Color(0xFF5C79A9),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recovery ? '실전 계좌 재기 필요' : '이번 주말 추천',
                                style: const TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                weekendActivityRecommendation(_state),
                                style: const TextStyle(
                                  color: Color(0xFF65708A),
                                  fontSize: 11,
                                  height: 1.45,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (recovery) ...[
                                const SizedBox(height: 5),
                                Text(
                                  '현재 주문 가능금 ${_money(_state.availableBrokerageCash)}원',
                                  style: const TextStyle(
                                    color: _coral,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    key: Key('weekend-action-work'),
                    '주말 알바',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final job in weekendJobs) ...[
                    _WeekendActionCard(
                      key: Key('weekend-job-${job.id}'),
                      title: job.title,
                      subtitle: '${job.location} · ${job.payHint}',
                      description: recovery
                          ? '${job.description} 수당은 실전 증권계좌에 바로 입금된다.'
                          : job.description,
                      imageAsset: job.imageAsset,
                      accent: Color(job.accentValue),
                      icon: Icons.work_rounded,
                      onTap: _busy || _remaining <= 0
                          ? null
                          : () => _run(
                              WeekendActivityRequest(activityId: job.id),
                            ),
                    ),
                    const SizedBox(height: 9),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    '다른 일정',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _WeekendActionCard(
                    key: const Key('weekend-action-study'),
                    title: '도서관 시장 복기',
                    subtitle: '다음 거래일 조사보고서 1회',
                    description: '지난 신문과 장부를 대조해 다음 거래일을 준비한다.',
                    imageAsset: weekendLibraryAsset,
                    accent: const Color(0xFF5C79A9),
                    icon: Icons.menu_book_rounded,
                    onTap: _busy || _remaining <= 0
                        ? null
                        : () => _run(
                            const WeekendActivityRequest(
                              activityId: 'market_study',
                            ),
                          ),
                  ),
                  const SizedBox(height: 9),
                  _WeekendActionCard(
                    key: const Key('weekend-action-gift'),
                    title: '동기에게 선물',
                    subtitle: '생활비 사용 · 관계 기록',
                    description: '작은 선물을 직접 골라 여자 동기 한 명에게 건넨다.',
                    imageAsset: weekendGiftShopAsset,
                    accent: const Color(0xFFE77F96),
                    icon: Icons.card_giftcard_rounded,
                    onTap: _busy || _remaining <= 0 ? null : _openGiftPicker,
                  ),
                  const SizedBox(height: 9),
                  _WeekendActionCard(
                    key: const Key('weekend-action-rest'),
                    title: '남은 시간 쉬기',
                    subtitle: '남은 행동력 모두 사용',
                    description: '몸과 장부를 정리하고 다음 날로 넘어간다.',
                    imageAsset: weekendNeighborhoodAsset,
                    accent: const Color(0xFF7B8DA8),
                    icon: Icons.bedtime_rounded,
                    onTap: _busy || _remaining <= 0 ? null : _confirmRest,
                  ),
                ],
              ),
            ),
            if (_busy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x44000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: FilledButton.icon(
              key: const Key('weekend-schedule-finish-button'),
              onPressed: _remaining == 0 && !_busy ? _finish : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _remaining == 0 ? '낮 일정 완료 · 저녁 시간으로' : '행동력 $_remaining칸 남음',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekendActionCard extends StatelessWidget {
  const _WeekendActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageAsset,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String description;
  final String imageAsset;
  final Color accent;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _ink, width: 1.8),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: accent.withValues(alpha: 0.18),
                    child: Icon(icon, color: accent, size: 31),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF65708A),
                      fontSize: 10,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _ink),
          ],
        ),
      ),
    ),
  );
}
