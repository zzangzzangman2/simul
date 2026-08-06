part of 'main.dart';

class RelationshipStatusScreen extends StatelessWidget {
  const RelationshipStatusScreen({super.key, required this.state});

  final GameState state;

  void _openCard(BuildContext context, CohortCharacterProfile profile) {
    final girlProfile = cohortGirlProfileById(profile.id);
    Navigator.of(context).push(
      _gameSceneRoute<void>(
        _CharacterCardScreen(
          state: state,
          profile: profile,
          progress: girlProfile == null
              ? null
              : state.relationships.progressFor(profile.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF5F0),
    body: SafeArea(
      child: Column(
        children: [
          _RelationshipHeader(
            title: '캐릭터',
            subtitle: '여자 동기 8명 · 김학준 · 한서윤 운영관',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: GridView.builder(
              key: const Key('character-card-grid'),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.67,
              ),
              itemCount: cohortCharacterProfiles.length,
              itemBuilder: (context, index) {
                final profile = cohortCharacterProfiles[index];
                final girlProfile = cohortGirlProfileById(profile.id);
                return _CohortCharacterTile(
                  currentDate: state.currentDate,
                  profile: profile,
                  progress: girlProfile == null
                      ? null
                      : state.relationships.progressFor(profile.id),
                  onTap: () => _openCard(context, profile),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _CohortCharacterTile extends StatelessWidget {
  const _CohortCharacterTile({
    required this.currentDate,
    required this.profile,
    required this.progress,
    required this.onTap,
  });

  final DateTime currentDate;
  final CohortCharacterProfile profile;
  final GirlRelationshipProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Color(profile.accentValue);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('character-card-${profile.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                const Color(0xFFFFFEFD),
                accent.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accent.withValues(alpha: 0.72),
              width: 1.6,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accent.withValues(alpha: 0.16),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              const BoxShadow(
                color: Color(0x1733405F),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Stack(
                    key: Key('character-card-portrait-region-${profile.id}'),
                    fit: StackFit.expand,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.white.withValues(alpha: 0.88),
                              accent.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                      ClipRect(
                        child: Hero(
                          tag: 'cohort-character-${profile.id}',
                          child: _CharacterPortraitImage(
                            profile: profile,
                            fit: BoxFit.cover,
                            scale: 1.42,
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 34,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.transparent,
                                Color(0x66FFFFFF),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _CharacterBadge(
                          label: profile.mbti,
                          color: accent,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: _CharacterBadge(
                          label: profile.ageLabelAt(currentDate),
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  key: Key('character-card-info-${profile.id}'),
                  padding: const EdgeInsets.fromLTRB(10, 9, 9, 10),
                  decoration: const BoxDecoration(
                    color: Color(0xF7FFFFFF),
                    border: Border(top: BorderSide(color: Color(0xFFDDE3EC))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              profile.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontFamily: 'Maplestory',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_circle_right_rounded,
                            size: 19,
                            color: accent.withValues(alpha: 0.92),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profile.role,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF68738B),
                          fontSize: 9.5,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          progress == null
                              ? profile.keywords.join(' · ')
                              : '호감도 ${progress!.affection} · ${progress!.stage.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: 8.7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
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

class _CharacterCardScreen extends StatelessWidget {
  const _CharacterCardScreen({
    required this.state,
    required this.profile,
    required this.progress,
  });

  final GameState state;
  final CohortCharacterProfile profile;
  final GirlRelationshipProgress? progress;

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      _gameSceneRoute<void>(
        _CharacterProfileDetailScreen(
          state: state,
          profile: profile,
          progress: progress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(profile.accentValue);
    return Scaffold(
      key: Key('character-card-screen-${profile.id}'),
      backgroundColor: const Color(0xFFFFF5F0),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _RelationshipHeader(
              title: profile.name,
              subtitle:
                  '${profile.ageLabelAt(state.currentDate)} · ${profile.mbti} · ${profile.group}',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          Colors.white,
                          accent.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: _ink, width: 2),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x3033405F),
                          blurRadius: 0,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: <Widget>[
                        Semantics(
                          button: true,
                          label: '${profile.name} 상세 프로필 열기',
                          child: InkWell(
                            key: Key('character-card-portrait-${profile.id}'),
                            onTap: () => _openDetails(context),
                            child: SizedBox(
                              height: 340,
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  ColoredBox(
                                    color: accent.withValues(alpha: 0.1),
                                  ),
                                  Hero(
                                    tag: 'cohort-character-${profile.id}',
                                    child: _CharacterPortraitImage(
                                      profile: profile,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Positioned(
                                    left: 12,
                                    right: 12,
                                    bottom: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xD933405F),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.75,
                                          ),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(
                                            Icons.touch_app_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            '초상화를 눌러 상세 프로필 보기',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
                          child: Column(
                            children: <Widget>[
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  color: _ink,
                                  fontFamily: 'Maplestory',
                                  fontSize: 27,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.role,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 11),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 7,
                                runSpacing: 7,
                                children: <Widget>[
                                  _CharacterBadge(
                                    label: profile.ageLabelAt(
                                      state.currentDate,
                                    ),
                                    color: _ink,
                                  ),
                                  _CharacterBadge(
                                    label: profile.mbti,
                                    color: accent,
                                  ),
                                  for (final keyword in profile.keywords)
                                    _CharacterBadge(
                                      label: keyword,
                                      color: accent,
                                      pale: true,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  _CohortInvestorIdentityPanel(
                    age: profile.ageLabelAt(state.currentDate),
                    birthday: profile.birthdayLabel,
                    relationship: progress == null
                        ? '호감도 수치 미적용'
                        : '${progress!.affection} / $relationshipMaxAffection · ${progress!.stage.label}',
                    ability: '${profile.role} · ${profile.strength}',
                    accent: accent,
                  ),
                  const SizedBox(height: 11),
                  _CharacterSummaryPanel(
                    icon: Icons.auto_awesome_rounded,
                    title: '한 줄 소개',
                    body: profile.summary,
                    accent: accent,
                  ),
                  if (progress != null) ...<Widget>[
                    const SizedBox(height: 11),
                    _CharacterAffectionSummary(
                      profile: profile,
                      progress: progress!,
                    ),
                  ],
                  const SizedBox(height: 11),
                  if (profile.id == 'han_seoyoon')
                    _CharacterSummaryPanel(
                      icon: Icons.lock_outline_rounded,
                      title: '자산 장부',
                      body: '운영관은 10인 투자 순위 참가자가 아니어서 개인 자산을 공개하지 않습니다.',
                      accent: accent,
                    )
                  else
                    _CohortInvestorAssetPanel(
                      snapshot: _cohortAssetSnapshot(state, profile.id),
                      accent: accent,
                      investorId: profile.id,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterProfileDetailScreen extends StatelessWidget {
  const _CharacterProfileDetailScreen({
    required this.state,
    required this.profile,
    required this.progress,
  });

  final GameState state;
  final CohortCharacterProfile profile;
  final GirlRelationshipProgress? progress;

  @override
  Widget build(BuildContext context) {
    final accent = Color(profile.accentValue);
    return Scaffold(
      key: Key('character-detail-screen-${profile.id}'),
      backgroundColor: const Color(0xFFFFF5F0),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _RelationshipHeader(
              title: '${profile.name} 프로필',
              subtitle: '${profile.mbti} · ${profile.role}',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                key: Key('character-detail-list-${profile.id}'),
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 26),
                children: <Widget>[
                  Container(
                    height: 265,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Colors.white,
                          accent.withValues(alpha: 0.17),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _ink, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Hero(
                      tag: 'cohort-character-${profile.id}',
                      child: _CharacterPortraitImage(
                        profile: profile,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CharacterFactPanel(
                    profile: profile,
                    currentDate: state.currentDate,
                  ),
                  const SizedBox(height: 11),
                  _CharacterSummaryPanel(
                    icon: Icons.psychology_alt_rounded,
                    title: '성격',
                    body: profile.personality,
                    accent: accent,
                  ),
                  const SizedBox(height: 11),
                  _CharacterSummaryPanel(
                    icon: Icons.favorite_outline_rounded,
                    title: '좋아하는 것',
                    body: profile.likes,
                    accent: accent,
                  ),
                  const SizedBox(height: 11),
                  _CharacterSummaryPanel(
                    icon: Icons.workspace_premium_outlined,
                    title: '잘하는 것',
                    body: profile.strength,
                    accent: accent,
                  ),
                  const SizedBox(height: 11),
                  _CharacterSummaryPanel(
                    icon: Icons.candlestick_chart_rounded,
                    title: '투자를 보는 기준',
                    body: profile.investmentView,
                    accent: accent,
                  ),
                  const SizedBox(height: 11),
                  _CharacterSummaryPanel(
                    icon: Icons.forum_outlined,
                    title: '사람과 가까워지는 방식',
                    body: profile.relationshipStyle,
                    accent: accent,
                  ),
                  if (progress != null) ...<Widget>[
                    const SizedBox(height: 11),
                    _CharacterAffectionSummary(
                      profile: profile,
                      progress: progress!,
                    ),
                  ],
                  const SizedBox(height: 11),
                  if (profile.id == 'han_seoyoon')
                    _CharacterSummaryPanel(
                      icon: Icons.lock_outline_rounded,
                      title: '자산 장부',
                      body: '운영관은 10인 투자 순위 참가자가 아니어서 개인 자산을 공개하지 않습니다.',
                      accent: accent,
                    )
                  else
                    _CohortInvestorAssetPanel(
                      snapshot: _cohortAssetSnapshot(state, profile.id),
                      accent: accent,
                      investorId: profile.id,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterPortraitImage extends StatelessWidget {
  const _CharacterPortraitImage({
    required this.profile,
    required this.fit,
    this.scale = 1,
  });

  final CohortCharacterProfile profile;
  final BoxFit fit;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final portrait = Image.asset(
      profile.portraitAsset,
      fit: fit,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      errorBuilder: (_, _, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.person_rounded,
              color: Color(profile.accentValue),
              size: 54,
            ),
            const SizedBox(height: 7),
            Text(
              profile.name,
              style: TextStyle(
                color: Color(profile.accentValue),
                fontFamily: 'Maplestory',
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
    if (scale == 1) return portrait;
    return Transform.scale(
      key: Key('character-card-portrait-zoom-${profile.id}'),
      scale: scale,
      alignment: Alignment.topCenter,
      child: portrait,
    );
  }
}

class _CharacterBadge extends StatelessWidget {
  const _CharacterBadge({
    required this.label,
    required this.color,
    this.pale = false,
  });

  final String label;
  final Color color;
  final bool pale;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: pale
          ? color.withValues(alpha: 0.13)
          : color.withValues(alpha: 0.91),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: pale ? color.withValues(alpha: 0.5) : Colors.white,
        width: 1,
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: pale ? color : Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _CharacterFactPanel extends StatelessWidget {
  const _CharacterFactPanel({required this.profile, required this.currentDate});

  final CohortCharacterProfile profile;
  final DateTime currentDate;

  @override
  Widget build(BuildContext context) {
    final accent = Color(profile.accentValue);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _ink, width: 1.8),
      ),
      child: Column(
        children: <Widget>[
          _CharacterFactRow(label: '이름', value: profile.name, accent: accent),
          _CharacterFactRow(
            label: '현재 나이',
            value: profile.ageLabelAt(currentDate),
            accent: accent,
          ),
          _CharacterFactRow(
            label: '생일',
            value: profile.birthdayLabel,
            accent: accent,
          ),
          _CharacterFactRow(label: 'MBTI', value: profile.mbti, accent: accent),
          _CharacterFactRow(label: '소속', value: profile.group, accent: accent),
          _CharacterFactRow(
            label: '역할',
            value: profile.role,
            accent: accent,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _CharacterFactRow extends StatelessWidget {
  const _CharacterFactRow({
    required this.label,
    required this.value,
    required this.accent,
    this.last = false,
  });

  final String label;
  final String value;
  final Color accent;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Color(0xFFE9E2DF))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 54,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7A8294),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: label == 'MBTI' ? accent : _ink,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CharacterSummaryPanel extends StatelessWidget {
  const _CharacterSummaryPanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: accent.withValues(alpha: 0.56), width: 1.6),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x1833405F), offset: Offset(0, 3)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontFamily: 'Maplestory',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          body,
          style: const TextStyle(
            color: Color(0xFF59647C),
            fontSize: 11,
            height: 1.55,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CharacterAffectionSummary extends StatelessWidget {
  const _CharacterAffectionSummary({
    required this.profile,
    required this.progress,
  });

  final CohortCharacterProfile profile;
  final GirlRelationshipProgress progress;

  @override
  Widget build(BuildContext context) {
    final accent = Color(profile.accentValue);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: accent, width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.favorite_rounded, color: accent, size: 20),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '현재 관계 · ${progress.stage.label}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${progress.affection} / $relationshipMaxAffection',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              key: Key('relationship-affection-${profile.id}'),
              minHeight: 9,
              value: progress.affection / relationshipMaxAffection,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: [
              _RelationshipAxisChip(label: '신뢰', value: progress.trust),
              _RelationshipAxisChip(label: '친밀', value: progress.closeness),
              _RelationshipAxisChip(
                label: '투자존중',
                value: progress.investmentRespect,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '대화 ${progress.conversationCount}회 · 데이트 ${progress.dateCount}회 · '
            '의미 있는 톡 ${progress.meaningfulMessageCount}회',
            style: const TextStyle(
              color: Color(0xFF6D7892),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class RelationshipEveningScreen extends StatefulWidget {
  const RelationshipEveningScreen({
    super.key,
    required this.state,
    required this.onComplete,
    required this.onRest,
    this.onOpenMessenger,
  });

  final GameState state;
  final Future<RelationshipActionResult> Function(
    String girlId,
    RelationshipActivity activity,
    String choiceId,
  )
  onComplete;
  final Future<RelationshipActionResult> Function() onRest;
  final Future<GameState> Function()? onOpenMessenger;

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
    final progress = _state.relationships.progressFor(profile.id);
    return relationshipSceneFor(
      profile: profile,
      activity: activity,
      day: _state.day,
      interactionCount: activity == RelationshipActivity.date
          ? progress.dateCount
          : progress.conversationCount,
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

  Future<void> _openMessenger() async {
    final open = widget.onOpenMessenger;
    if (_busy || open == null) return;
    setState(() => _busy = true);
    try {
      final next = await open();
      if (!mounted) return;
      setState(() => _state = next);
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
      Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Text(
          isWeekendOutingDay(_state.currentDate)
              ? '주식시장이 쉬는 주말이야. 한 명과 이야기하거나 친해진 동기와 외출할 수 있어.'
              : '평일 저녁이야. 데시멀톡을 확인하거나 한 명과 차분히 이야기할 수 있어.',
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
      if (widget.onOpenMessenger != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              key: const Key('relationship-open-messenger-button'),
              onPressed: _busy ? null : _openMessenger,
              icon: const Icon(Icons.smartphone_rounded),
              label: const Text('데시멀톡 · 하루 첫 의미 있는 톡은 관계에 반영'),
            ),
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
    final weekend = isWeekendOutingDay(_state.currentDate);
    final outingAvailable = weekend && progress.dateUnlocked;
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
            icon: outingAvailable
                ? Icons.favorite_rounded
                : Icons.lock_outline_rounded,
            title: outingAvailable
                ? '주말 외출하기'
                : weekend
                ? '주말 외출 잠김'
                : '주말 외출은 토·일요일',
            subtitle: outingAvailable
                ? '${profile.dateScene.location} · 공개 장소 · 결과 -3~+8'
                : weekend
                ? '호감도 $relationshipDateUnlockAffection부터 가능 · 현재 ${progress.affection}'
                : '주식시장이 쉬는 주말에만 외출할 수 있어',
            onTap: outingAvailable
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
  const _RelationshipGirlCard({required this.profile, required this.progress});

  final CohortGirlProfile profile;
  final GirlRelationshipProgress progress;

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
        const SizedBox(height: 9),
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: [
            _RelationshipAxisChip(label: '신뢰', value: progress.trust),
            _RelationshipAxisChip(label: '친밀', value: progress.closeness),
            _RelationshipAxisChip(
              label: '투자존중',
              value: progress.investmentRespect,
            ),
          ],
        ),
      ],
    ),
  );
}

class _RelationshipAxisChip extends StatelessWidget {
  const _RelationshipAxisChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F4FA),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFFD5DCEB)),
    ),
    child: Text(
      '$label $value',
      style: const TextStyle(
        color: _ink,
        fontSize: 9,
        fontWeight: FontWeight.w900,
      ),
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
