part of 'main.dart';

class RelationshipStatusScreen extends StatelessWidget {
  const RelationshipStatusScreen({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF5F0),
    body: SafeArea(
      child: Column(
        children: [
          _RelationshipHeader(
            title: '제6기 관계 기록',
            subtitle: '여학생 8명 · 호감도 1~100',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView.separated(
              key: const Key('relationship-status-list'),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: cohortGirlProfiles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final profile = cohortGirlProfiles[index];
                final progress = state.relationships.progressFor(profile.id);
                return _RelationshipGirlCard(
                  profile: profile,
                  progress: progress,
                  showCounts: true,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class RelationshipEveningScreen extends StatefulWidget {
  const RelationshipEveningScreen({
    super.key,
    required this.state,
    required this.onComplete,
    required this.onRest,
  });

  final GameState state;
  final Future<RelationshipActionResult> Function(
    String girlId,
    RelationshipActivity activity,
    String choiceId,
  )
  onComplete;
  final Future<RelationshipActionResult> Function() onRest;

  @override
  State<RelationshipEveningScreen> createState() =>
      _RelationshipEveningScreenState();
}

class _RelationshipEveningScreenState extends State<RelationshipEveningScreen> {
  late GameState _state = widget.state;
  CohortGirlProfile? _selectedProfile;
  RelationshipActivity? _activity;
  RelationshipActionResult? _result;
  bool _busy = false;

  RelationshipSceneDefinition? get _scene {
    final profile = _selectedProfile;
    final activity = _activity;
    if (profile == null || activity == null) return null;
    return relationshipSceneFor(
      profile: profile,
      activity: activity,
      day: _state.day,
    );
  }

  Future<void> _rest() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.onRest();
      if (!mounted) return;
      if (!result.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
        return;
      }
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose(RelationshipChoiceDefinition choice) async {
    final profile = _selectedProfile;
    final activity = _activity;
    if (_busy || profile == null || activity == null) return;
    setState(() => _busy = true);
    try {
      final result = await widget.onComplete(profile.id, activity, choice.id);
      if (!mounted) return;
      if (!result.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
        return;
      }
      setState(() {
        _state = result.state;
        _result = result;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goBack() {
    if (_busy) return;
    if (_result != null) return;
    if (_activity != null) {
      setState(() => _activity = null);
      return;
    }
    if (_selectedProfile != null) {
      setState(() => _selectedProfile = null);
      return;
    }
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _selectedProfile;
    final result = _result;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF5F0),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _RelationshipHeader(
                    title: result != null
                        ? '오늘의 마음 기록'
                        : profile == null
                        ? '하루 끝 · 누구와 보낼까?'
                        : profile.name,
                    subtitle: result != null
                        ? '${profile!.name} · ${profile.mbti}'
                        : profile == null
                        ? '${_dateLabel(_state.currentDate)} 20:00 · 하루 한 번'
                        : '${profile.mbti} · ${profile.role}',
                    onBack: result == null ? _goBack : null,
                  ),
                  Expanded(
                    child: result != null
                        ? _buildResult(profile!, result)
                        : profile == null
                        ? _buildGirlSelection()
                        : _activity == null
                        ? _buildActivitySelection(profile)
                        : _buildChoiceSelection(profile, _scene!),
                  ),
                ],
              ),
              if (_busy)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x55000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGirlSelection() => Column(
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Text(
          '한 명을 골라 이야기하거나, 친해진 동기에게 데이트를 신청할 수 있어.',
          style: TextStyle(
            color: Color(0xFF626C84),
            fontSize: 11,
            height: 1.45,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Expanded(
        child: ListView.separated(
          key: const Key('relationship-evening-girl-list'),
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
          itemCount: cohortGirlProfiles.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final profile = cohortGirlProfiles[index];
            return InkWell(
              key: Key('relationship-select-${profile.id}'),
              onTap: () => setState(() => _selectedProfile = profile),
              borderRadius: BorderRadius.circular(17),
              child: _RelationshipGirlCard(
                profile: profile,
                progress: _state.relationships.progressFor(profile.id),
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            key: const Key('relationship-rest-button'),
            onPressed: _busy ? null : _rest,
            icon: const Icon(Icons.bedtime_outlined),
            label: const Text('오늘은 혼자 쉬기'),
          ),
        ),
      ),
    ],
  );

  Widget _buildActivitySelection(CohortGirlProfile profile) {
    final progress = _state.relationships.progressFor(profile.id);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RelationshipPortrait(profile: profile, height: 240),
          const SizedBox(height: 12),
          _AffectionPanel(profile: profile, progress: progress),
          const SizedBox(height: 14),
          _RelationshipActivityButton(
            key: const Key('relationship-conversation-button'),
            color: const Color(0xFFFFE19B),
            icon: Icons.chat_bubble_outline_rounded,
            title: '같이 이야기하기',
            subtitle: '일상 선택지 · 결과에 따라 -2~+5',
            onTap: () =>
                setState(() => _activity = RelationshipActivity.conversation),
          ),
          const SizedBox(height: 10),
          _RelationshipActivityButton(
            key: const Key('relationship-date-button'),
            color: const Color(0xFFFFB8C1),
            icon: progress.dateUnlocked
                ? Icons.favorite_rounded
                : Icons.lock_outline_rounded,
            title: progress.dateUnlocked ? '데이트 신청하기' : '데이트 잠김',
            subtitle: progress.dateUnlocked
                ? '${profile.dateScene.location} · 결과에 따라 -3~+8'
                : '호감도 $relationshipDateUnlockAffection부터 가능 · 현재 ${progress.affection}',
            onTap: progress.dateUnlocked
                ? () => setState(() => _activity = RelationshipActivity.date)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceSelection(
    CohortGirlProfile profile,
    RelationshipSceneDefinition scene,
  ) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RelationshipPortrait(profile: profile, height: 205),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _ink, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x3333405F), offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${scene.location} · ${scene.title}',
                style: const TextStyle(
                  color: _coral,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                scene.prompt,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < scene.choices.length; index++) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: Key('relationship-choice-${scene.choices[index].id}'),
              onPressed: _busy ? null : () => _choose(scene.choices[index]),
              style: FilledButton.styleFrom(
                foregroundColor: _ink,
                backgroundColor: const Color(0xFFFFE7A8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                side: const BorderSide(color: _ink, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  scene.choices[index].label,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          if (index < scene.choices.length - 1) const SizedBox(height: 9),
        ],
      ],
    ),
  );

  Widget _buildResult(
    CohortGirlProfile profile,
    RelationshipActionResult result,
  ) {
    final after = result.affectionAfter ?? relationshipMinAffection;
    final progress = _state.relationships.progressFor(profile.id);
    final delta = result.affectionDelta;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RelationshipPortrait(profile: profile, height: 235),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _ink, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x3333405F), offset: Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.response ?? result.message,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    height: 1.55,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: _coral),
                    const SizedBox(width: 7),
                    Text(
                      '${result.affectionBefore} → $after '
                      '(${delta >= 0 ? '+' : ''}$delta)',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _RelationshipProgressBar(profile: profile, affection: after),
                const SizedBox(height: 7),
                Text(
                  progress.stage.label,
                  style: const TextStyle(
                    color: Color(0xFF6D7892),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (result.dateJustUnlocked) ...[
                  const SizedBox(height: 12),
                  const _RelationshipUnlockBanner(
                    icon: Icons.favorite_rounded,
                    text: '데이트가 열렸어! 다음 하루 종료부터 신청할 수 있어.',
                  ),
                ] else if (result.stageJustUnlocked != null) ...[
                  const SizedBox(height: 12),
                  _RelationshipUnlockBanner(
                    icon: Icons.auto_awesome_rounded,
                    text: '새 관계 단계 · ${result.stageJustUnlocked!.label}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              key: const Key('relationship-finish-button'),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.nights_stay_rounded),
              label: const Text('하루 마치고 내일로'),
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelationshipHeader extends StatelessWidget {
  const _RelationshipHeader({
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(10, 8, 10, 5),
    padding: const EdgeInsets.fromLTRB(8, 8, 13, 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFCE3D8),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _ink, width: 2),
    ),
    child: Row(
      children: [
        if (onBack != null)
          IconButton(
            key: const Key('relationship-back-button'),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          )
        else
          const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontFamily: _hubDisplayFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6D7892),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.favorite_rounded, color: _coral, size: 26),
      ],
    ),
  );
}

class _RelationshipGirlCard extends StatelessWidget {
  const _RelationshipGirlCard({
    required this.profile,
    required this.progress,
    this.showCounts = false,
  });

  final CohortGirlProfile profile;
  final GirlRelationshipProgress progress;
  final bool showCounts;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _ink, width: 1.7),
      boxShadow: const [
        BoxShadow(color: Color(0x2633405F), offset: Offset(0, 3)),
      ],
    ),
    child: Row(
      children: [
        _RelationshipAvatar(profile: profile, size: 60),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${profile.name} · ${profile.mbti}',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${progress.affection}',
                    style: TextStyle(
                      color: Color(profile.accentValue),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _RelationshipProgressBar(
                profile: profile,
                affection: progress.affection,
              ),
              const SizedBox(height: 5),
              Text(
                progress.dateUnlocked
                    ? '${progress.stage.label} · 데이트 가능'
                    : '${progress.stage.label} · 데이트까지 ${relationshipDateUnlockAffection - progress.affection}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6D7892),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (showCounts) ...[
                const SizedBox(height: 3),
                Text(
                  '대화 ${progress.conversationCount}회 · 데이트 ${progress.dateCount}회',
                  style: const TextStyle(
                    color: Color(0xFF8A90A0),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _RelationshipAvatar extends StatelessWidget {
  const _RelationshipAvatar({required this.profile, required this.size});

  final CohortGirlProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = profile.portraitAsset;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Container(
        width: size,
        height: size,
        color: Color(profile.accentValue).withValues(alpha: 0.18),
        child: asset == null
            ? Center(
                child: Text(
                  profile.name.substring(1),
                  style: TextStyle(
                    color: Color(profile.accentValue),
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            : Image.asset(
                asset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    profile.name.substring(1),
                    style: TextStyle(
                      color: Color(profile.accentValue),
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _RelationshipPortrait extends StatelessWidget {
  const _RelationshipPortrait({required this.profile, required this.height});

  final CohortGirlProfile profile;
  final double height;

  @override
  Widget build(BuildContext context) {
    final asset = profile.portraitAsset;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Color(profile.accentValue).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ink, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_outline_rounded,
                    color: Color(profile.accentValue),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.name,
                    style: TextStyle(
                      color: Color(profile.accentValue),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            )
          : Image.asset(
              asset,
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  profile.name,
                  style: TextStyle(
                    color: Color(profile.accentValue),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
    );
  }
}

class _RelationshipProgressBar extends StatelessWidget {
  const _RelationshipProgressBar({
    required this.profile,
    required this.affection,
  });

  final CohortGirlProfile profile;
  final int affection;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: LinearProgressIndicator(
      key: Key('relationship-affection-${profile.id}'),
      minHeight: 8,
      value: affection / relationshipMaxAffection,
      backgroundColor: const Color(0xFFE9E5E2),
      valueColor: AlwaysStoppedAnimation<Color>(Color(profile.accentValue)),
    ),
  );
}

class _AffectionPanel extends StatelessWidget {
  const _AffectionPanel({required this.profile, required this.progress});

  final CohortGirlProfile profile;
  final GirlRelationshipProgress progress;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _ink, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                progress.stage.label,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${progress.affection} / $relationshipMaxAffection',
              style: TextStyle(
                color: Color(profile.accentValue),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        _RelationshipProgressBar(
          profile: profile,
          affection: progress.affection,
        ),
      ],
    ),
  );
}

class _RelationshipActivityButton extends StatelessWidget {
  const _RelationshipActivityButton({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFE9E6E2) : color,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: _ink, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x5533405F), offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: onTap == null ? Colors.grey : _ink, size: 29),
            const SizedBox(width: 12),
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
                    style: const TextStyle(
                      color: Color(0xFF626C84),
                      fontSize: 9,
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

class _RelationshipUnlockBanner extends StatelessWidget {
  const _RelationshipUnlockBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE6A7),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: _coral, width: 1.5),
    ),
    child: Row(
      children: [
        Icon(icon, color: _coral, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _ink,
              fontSize: 10,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

String _dateLabel(DateTime date) {
  const weekdays = <String>['월', '화', '수', '목', '금', '토', '일'];
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.'
      '${date.day.toString().padLeft(2, '0')} ${weekdays[date.weekday - 1]}';
}
