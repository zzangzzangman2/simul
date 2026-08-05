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

  Future<WeekendActivityResult?> _run(WeekendActivityRequest request) async {
    if (_busy || _remaining <= 0) return null;
    setState(() => _busy = true);
    final result = await widget.onComplete(request);
    if (!mounted) return result;
    setState(() {
      _busy = false;
      if (result.success) _state = result.state;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message)));
    return result;
  }

  Future<void> _openGiftPicker() async {
    final request = await Navigator.of(context).push<WeekendActivityRequest>(
      _gameSceneRoute<WeekendActivityRequest>(
        _KBeautyStoreScreen(state: _state),
      ),
    );
    if (request == null || !mounted) return;
    final result = await _run(request);
    if (result?.success != true || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선물 전달 완료'),
        content: Text('$kBeautyClerkThanksLine\n\n${result!.message}'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _openJob(WeekendJobDefinition job) async {
    if (!job.requiresMiniGame) {
      await _run(WeekendActivityRequest(activityId: job.id));
      return;
    }
    final result = await Navigator.of(context).push<WorkSessionResult>(
      _gameSceneRoute<WorkSessionResult>(
        RiderMiniGame(randomSeed: _state.day ^ _state.simulationSeed.hashCode),
      ),
    );
    if (result == null || !mounted) return;
    await _run(
      WeekendActivityRequest(
        activityId: job.id,
        workScore: result.score,
        workMaxScore: result.maxScore,
      ),
    );
  }

  Future<void> _openHorseRace() async {
    final race = buildAfternoonHorseRace(
      simulationSeed: _state.simulationSeed,
      day: _state.day,
    );
    final session = await Navigator.of(context).push<HorseRaceSessionResult>(
      _gameSceneRoute<HorseRaceSessionResult>(
        HorseRacingMiniGame(
          race: race,
          availableCash: _state.bankCash,
          stateRecoveryRateBps: _state.story.stateRecoveryRateBps,
        ),
      ),
    );
    if (session == null || !mounted) return;
    final result = await _run(
      WeekendActivityRequest(
        activityId: 'horse_racing',
        horseRaceResult: session,
      ),
    );
    if (result?.success != true || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전자 마권 정산 완료'),
        content: Text(result!.message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
                          : () => _openJob(job),
                    ),
                    const SizedBox(height: 9),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    key: Key('weekend-action-afternoon-fun'),
                    '오후 온라인 활동',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _WeekendActionCard(
                    key: const Key('weekend-action-horse-racing'),
                    title: '국가망 경마 중계',
                    subtitle: '오후 15:10 · 데시멀 PC 온라인 접속',
                    description: horseRaceAlreadyPlayedToday(_state)
                        ? '오늘 국가망 경주 중계와 전자 마권 정산을 마쳤다.'
                        : '센터를 나가지 않고 국가 전용망으로 원격 패독·배당·실시간 중계를 본다. 확정 이익의 20%는 국가 수수료다.',
                    imageAsset: horseRaceBackgroundAsset,
                    accent: const Color(0xFF2E7D5A),
                    icon: Icons.emoji_events_rounded,
                    onTap:
                        _busy ||
                            _remaining <= 0 ||
                            horseRaceAlreadyPlayedToday(_state) ||
                            _state.bankCash < horseRaceMinStake
                        ? null
                        : _openHorseRace,
                  ),
                  const SizedBox(height: 13),
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
                    title: '미라온 K-뷰티 외출',
                    subtitle: '주말 매장 방문 · 선물 하루 1회',
                    description: '프리미엄 K-뷰티 상품을 직접 비교하고 동기 한 명의 취향에 맞춰 고른다.',
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

class _KBeautyStoreScreen extends StatefulWidget {
  const _KBeautyStoreScreen({required this.state});

  final GameState state;

  @override
  State<_KBeautyStoreScreen> createState() => _KBeautyStoreScreenState();
}

class _KBeautyStoreScreenState extends State<_KBeautyStoreScreen> {
  String? _girlId;
  String? _giftId;

  @override
  Widget build(BuildContext context) {
    final profile = _girlId == null ? null : cohortGirlProfileById(_girlId!);
    final gift = _giftId == null ? null : weekendGiftById(_giftId!);
    final repeatCount = profile == null || gift == null
        ? 0
        : kBeautyGiftMonthlyRepeatCount(
            widget.state,
            girlId: profile.id,
            giftId: gift.id,
          );
    final alreadyGifted = kBeautyGiftAlreadyGivenToday(widget.state);
    final canCheckout =
        !alreadyGifted &&
        profile != null &&
        gift != null &&
        widget.state.bankCash >= gift.cost;
    final clerkLine = gift == null
        ? kBeautyClerkWelcomeLine
        : profile == null
        ? kBeautyClerkPriceLine(gift)
        : '$kBeautyClerkCheckoutLine\n$kBeautyClerkWrapLine';

    return Scaffold(
      key: const Key('kbeauty-store-screen'),
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F5),
        foregroundColor: _ink,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MIRAON BEAUTY',
              style: TextStyle(
                fontSize: 15,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '주말 K-뷰티 스토어',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                '생활비 ${_money(widget.state.bankCash)}원',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 116),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 245,
                  width: double.infinity,
                  child: Image.asset(
                    weekendGiftShopAsset,
                    fit: BoxFit.cover,
                    cacheWidth: 900,
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xB3412630)],
                        stops: [0.52, 1],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '한 사람을 생각하며 고르는 시간',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '같은 상품을 같은 달에 반복하면 호감 효과가 점점 줄어들어요.',
                        style: TextStyle(
                          color: Color(0xFFFFEAF0),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              key: const Key('kbeauty-clerk-dialogue'),
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: const Color(0xFFEBCFD6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE5EC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFFB6647A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '직원',
                          style: TextStyle(
                            color: Color(0xFFB6647A),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          clerkLine,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (alreadyGifted)
              Container(
                key: const Key('kbeauty-daily-limit-notice'),
                margin: const EdgeInsets.fromLTRB(12, 9, 12, 0),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0D7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '오늘은 이미 선물을 보냈어요. 상품은 둘러볼 수 있지만 계산은 내일 다시 열립니다.',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 18, 14, 8),
              child: Text(
                '1. 누구를 생각하며 고를까?',
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              height: 82,
              child: ListView.separated(
                key: const Key('kbeauty-recipient-list'),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: cohortGirlProfiles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final girl = cohortGirlProfiles[index];
                  final selected = girl.id == _girlId;
                  return InkWell(
                    key: Key('kbeauty-recipient-${girl.id}'),
                    onTap: () => setState(() => _girlId = girl.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 92,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFE6ED)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFB6647A)
                              : const Color(0xFFE8D9D4),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 21,
                            backgroundColor: Color(
                              girl.accentValue,
                            ).withValues(alpha: 0.18),
                            backgroundImage: girl.portraitAsset == null
                                ? null
                                : AssetImage(girl.portraitAsset!),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  girl.name,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  girl.mbti,
                                  style: TextStyle(
                                    color: Color(girl.accentValue),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 19, 14, 8),
              child: Text(
                '2. K-뷰티 선물 고르기',
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            GridView.builder(
              key: const Key('kbeauty-product-grid'),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 9,
                mainAxisSpacing: 9,
                childAspectRatio: 0.65,
              ),
              itemCount: weekendGifts.length,
              itemBuilder: (context, index) {
                final product = weekendGifts[index];
                final selected = product.id == _giftId;
                final productRepeats = profile == null
                    ? 0
                    : kBeautyGiftMonthlyRepeatCount(
                        widget.state,
                        girlId: profile.id,
                        giftId: product.id,
                      );
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  child: InkWell(
                    key: Key('kbeauty-product-${product.id}'),
                    onTap: () => setState(() => _giftId = product.id),
                    borderRadius: BorderRadius.circular(17),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFB6647A)
                              : const Color(0xFFE8D9D4),
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                product.imageAsset,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                cacheWidth: 480,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.category,
                            style: const TextStyle(
                              color: Color(0xFFB6647A),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 12,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            product.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF766A6D),
                              fontSize: 8,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_money(product.cost)}원',
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (profile != null &&
                                  product.isFavoriteFor(profile.id))
                                const Icon(
                                  Icons.favorite_rounded,
                                  size: 15,
                                  color: Color(0xFFC65172),
                                ),
                            ],
                          ),
                          if (productRepeats > 0)
                            Text(
                              '이번 달 같은 상품 ${productRepeats + 1}회째',
                              style: const TextStyle(
                                color: Color(0xFF9A6A42),
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (profile != null && gift != null)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: gift.isFavoriteFor(profile.id)
                      ? const Color(0xFFFFE7EE)
                      : const Color(0xFFF1EFEC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gift.isFavoriteFor(profile.id)
                          ? '${profile.name}의 취향과 특히 잘 맞을 것 같아'
                          : '${profile.name}에게는 뜻밖의 선택일 수 있어',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      gift.isFavoriteFor(profile.id)
                          ? gift.preferenceReason
                          : 'MBTI는 힌트일 뿐이에요. 실제 반응은 현재 관계와 최근 대화 분위기도 함께 반영합니다.',
                      style: const TextStyle(
                        color: Color(0xFF766A6D),
                        fontSize: 9,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      kBeautyGiftRepeatLabel(repeatCount),
                      style: const TextStyle(
                        color: Color(0xFF9A5066),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: FilledButton.icon(
            key: const Key('kbeauty-checkout-button'),
            onPressed: canCheckout
                ? () => Navigator.pop(
                    context,
                    WeekendActivityRequest(
                      activityId: 'gift',
                      girlId: profile.id,
                      giftId: gift.id,
                    ),
                  )
                : null,
            icon: const Icon(Icons.shopping_bag_rounded),
            label: Text(
              alreadyGifted
                  ? '오늘 선물 완료 · 내일 다시'
                  : profile == null
                  ? '받을 동기를 골라 주세요'
                  : gift == null
                  ? '상품을 골라 주세요'
                  : widget.state.bankCash < gift.cost
                  ? '생활비가 부족해요'
                  : '${_money(gift.cost)}원 · 포장하고 계산하기',
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
