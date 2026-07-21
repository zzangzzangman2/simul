part of 'main.dart';

class VisualNovelOnboardingScreen extends StatefulWidget {
  const VisualNovelOnboardingScreen({super.key, required this.onCreate});

  final ValueChanged<NewGameSetup> onCreate;

  @override
  State<VisualNovelOnboardingScreen> createState() =>
      _VisualNovelOnboardingScreenState();
}

class _VisualNovelOnboardingScreenState
    extends State<VisualNovelOnboardingScreen> {
  final _playerController = TextEditingController();
  final _companyController = TextEditingController();
  int _beat = 0;
  String? _introChoice;
  StoryTrait? _trait;
  FamilyRule? _familyRule;

  @override
  void dispose() {
    _playerController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  String get _background => switch (_beat) {
    <= 2 => 'assets/images/bg_boy_room_1999.png',
    <= 8 => 'assets/images/bg_living_room_1999.png',
    <= 14 => 'assets/images/bg_kitchen_1999.png',
    _ => 'assets/images/bg_boy_room_1999.png',
  };

  String get _location => switch (_beat) {
    <= 2 => '작은방',
    <= 8 => '거실',
    <= 14 => '부엌 식탁',
    _ => '작은방 책상',
  };

  String get _dateLabel =>
      _beat <= 8 ? '1999.12.31  ·  23:57' : '2000.01.01  ·  아침';

  String? get _character => switch (_beat) {
    2 || 6 || 7 || 12 || 15 => 'assets/images/character_hero.png',
    4 || 14 => 'assets/images/character_father.png',
    5 => 'assets/images/character_sister.png',
    9 || 10 || 11 => 'assets/images/character_grandfather.png',
    13 => 'assets/images/character_mother.png',
    _ => null,
  };

  Alignment get _characterAlignment => switch (_beat) {
    4 || 9 || 10 || 11 || 14 => Alignment.bottomLeft,
    5 || 13 => Alignment.bottomRight,
    _ => Alignment.bottomCenter,
  };

  bool get _isNarration => _beat == 0 || _beat == 3 || _beat == 8;

  String get _speaker => switch (_beat) {
    0 || 3 || 8 || 15 => '이야기',
    1 || 13 => '엄마',
    2 || 6 || 7 || 12 =>
      _playerController.text.trim().isEmpty
          ? '나'
          : _playerController.text.trim(),
    4 || 14 => '아빠',
    5 => '누나',
    9 || 10 || 11 => '외할아버지',
    _ => '이야기',
  };

  String get _line => switch (_beat) {
    0 => '새 천년을 세 분 앞둔 밤. 서울의 오래된 아파트에는 귤 냄새와 난방 열기, 거실 TV의 카운트다운 소리가 섞여 있었다.',
    1 => '컴퓨터 그만 보고 거실로 나와. 곧 열두 시야!',
    2 => '화면 속 숫자는 계속 바뀌었다. 컴퓨터가 세상을 멈춘다는 말보다, 이 작은 상자로 어디까지 갈 수 있는지가 더 궁금했다.',
    3 => '나는 의자에서 뛰어내려 거실로 향했다. 양말이 마룻바닥을 미끄러지고, 누나가 웃음을 터뜨렸다.',
    4 => '천천히 뛰어. 컴퓨터 날짜가 잘 넘어가는지 같이 확인해 보자꾸나.',
    5 => '아빠, 얘는 벌써 컴퓨터를 자기 거라고 생각하는 것 같은데?',
    6 => '가족들의 시선이 내게 모였다. 나는 CRT 화면에서 본 숫자를 떠올리며 입을 열었다.',
    7 => _introResponse,
    8 =>
      '셋, 둘, 하나. TV 속 사람들이 환호했고 오래된 컴퓨터의 시계도 조용히 2000년으로 넘어갔다. 하지만 진짜 시작은 다음 날 아침이었다.',
    9 => '새해 선물이다. 돈 대신 빈 저금장부부터 주마.',
    10 =>
      '첫 장에는 0원이라고 적혀 있었다. 집안일과 엄마가 함께 가는 동네 일거리로 네 돈을 직접 모아 보거라. 번 돈과 쓴 시간을 모두 기록해야 한다.',
    11 => '그 전에 네 이름부터 똑바로 적어야겠지. 이 투자노트의 첫 번째 주인은 누구냐?',
    12 => '내가 가장 먼저 배우고 싶은 것은…',
    13 =>
      '네가 번 돈이 모이면 엄마 이름으로 교육용 계좌를 만들자. 비밀번호와 도장은 내가 보관하고, 너는 회사를 조사해 가족 앞에서 설명하는 거야.',
    14 => '좋아. 생활비와 투자금은 섞지 않고, 빚도 내지 않는다. 마지막 약속 한 줄은 네가 골라라.',
    _ =>
      '법인도 큰돈도 없지만, 내 방 책상과 빈 저금장부면 시작할 수 있다. 일해서 모은 돈으로 시작할 우리 가족 투자연구소의 이름은…',
  };

  String get _introResponse => switch (_introChoice) {
    'computer' => '“제가 먼저 켜 봐도 돼요?” 아빠가 웃으며 컴퓨터 옆자리를 내주었다.',
    'y2k' => '“정말 컴퓨터가 다 멈출 수도 있어요?” 엄마는 걱정보다 확인하는 습관이 중요하다고 답했다.',
    'stocks' => '“이걸로 주식도 살 수 있어요?” 순간 거실이 조용해졌다. 외할아버지만 재미있다는 듯 웃었다.',
    _ => '',
  };

  void _next() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _beat += 1);
  }

  void _finish() {
    final playerName = _playerController.text.trim();
    final companyName = _companyController.text.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (playerName.isEmpty ||
        companyName.isEmpty ||
        _introChoice == null ||
        _trait == null ||
        _familyRule == null) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onCreate(
      NewGameSetup(
        playerName: playerName,
        companyName: companyName,
        introChoice: _introChoice!,
        startingTrait: _trait!,
        familyRule: _familyRule!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final isKeyboardOpen = viewInsets.bottom > 0;
    final isNameEntry = _beat == 11 || _beat == 15;
    return Scaffold(
      backgroundColor: const Color(0xFF171B2A),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: _LivingBackground(
              key: ValueKey(_background),
              asset: _background,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Colors.transparent,
                  Color(0xA6000000),
                ],
                stops: [0, 0.52, 1],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: _SceneLabel(
                date: _dateLabel,
                location: _location,
                progress: (_beat + 1) / 16,
              ),
            ),
          ),
          if (_character != null)
            Positioned.fill(
              bottom: 122,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: isKeyboardOpen && isNameEntry ? 0 : 1,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Align(
                    key: ValueKey('$_character-$_beat'),
                    alignment: _characterAlignment,
                    child: FractionallySizedBox(
                      heightFactor: 0.78,
                      child: Image.asset(
                        _character!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.fromLTRB(12, 76, 12, viewInsets.bottom + 10),
              child: LayoutBuilder(
                builder: (context, constraints) => Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 560,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: SingleChildScrollView(
                      reverse: isKeyboardOpen && isNameEntry,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: _buildDialogue(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogue(BuildContext context) {
    if (_beat == 6) return _introChoices();
    if (_beat == 11) return _nameEntry();
    if (_beat == 12) return _traitChoices();
    if (_beat == 14) return _familyChoices();
    if (_beat == 15) return _researchDeskName();

    return _NovelDialogue(
      key: ValueKey(_beat),
      speaker: _speaker,
      line: _line,
      narration: _isNarration,
      onContinue: _next,
    );
  }

  Widget _introChoices() => _NovelDialogue(
    key: const ValueKey('intro-choice'),
    speaker: _speaker,
    line: _line,
    choices: [
      _NovelChoice(
        key: const Key('story-intro-computer'),
        label: '“제가 먼저 켜 봐도 돼요?”',
        onTap: () => setState(() {
          _introChoice = 'computer';
          _beat = 7;
        }),
      ),
      _NovelChoice(
        key: const Key('story-intro-y2k'),
        label: '“정말 다 멈출 수도 있어요?”',
        onTap: () => setState(() {
          _introChoice = 'y2k';
          _beat = 7;
        }),
      ),
      _NovelChoice(
        key: const Key('story-intro-stocks'),
        label: '“이걸로 주식도 살 수 있어요?”',
        onTap: () => setState(() {
          _introChoice = 'stocks';
          _beat = 7;
        }),
      ),
    ],
  );

  Widget _nameEntry() => _NovelDialogue(
    key: const ValueKey('name-entry'),
    speaker: _speaker,
    line: _line,
    child: Column(
      children: [
        TextField(
          key: const Key('player-name-input'),
          controller: _playerController,
          maxLength: 12,
          autofocus: false,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (_playerController.text.trim().isNotEmpty) _next();
          },
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: _fieldDecoration('예: 민준'),
        ),
        _NovelNextButton(
          key: const Key('story-next-name'),
          label: '투자노트에 이름 쓰기',
          enabled: _playerController.text.trim().isNotEmpty,
          onTap: _next,
        ),
      ],
    ),
  );

  Widget _traitChoices() => _NovelDialogue(
    key: const ValueKey('trait-choice'),
    speaker: _speaker,
    line: _line,
    choices: [
      _NovelChoice(
        key: const Key('story-trait-stability'),
        label: '가족의 돈을 안전하게 지키는 법',
        onTap: () => _chooseTrait(StoryTrait.stability),
      ),
      _NovelChoice(
        key: const Key('story-trait-innovation'),
        label: '세상을 바꿀 기술과 제품',
        onTap: () => _chooseTrait(StoryTrait.innovation),
      ),
      _NovelChoice(
        key: const Key('story-trait-analysis'),
        label: '신문 속 숫자가 움직이는 이유',
        onTap: () => _chooseTrait(StoryTrait.analysis),
      ),
      _NovelChoice(
        key: const Key('story-trait-control'),
        label: '회사의 주인이 되는 방법',
        onTap: () => _chooseTrait(StoryTrait.control),
      ),
    ],
  );

  void _chooseTrait(StoryTrait trait) => setState(() {
    _trait = trait;
    _beat = 13;
  });

  Widget _familyChoices() => _NovelDialogue(
    key: const ValueKey('family-choice'),
    speaker: _speaker,
    line: _line,
    choices: [
      _NovelChoice(
        key: const Key('family-rule-report-losses'),
        label: '손실을 숨기지 않는다',
        onTap: () => _chooseFamilyRule(FamilyRule.reportLosses),
      ),
      _NovelChoice(
        key: const Key('family-rule-no-hot-tips'),
        label: '남이 찍어준 종목은 사지 않는다',
        onTap: () => _chooseFamilyRule(FamilyRule.noHotTips),
      ),
      _NovelChoice(
        key: const Key('family-rule-keep-cash'),
        label: '언제나 현금을 남겨 둔다',
        onTap: () => _chooseFamilyRule(FamilyRule.keepCash),
      ),
    ],
  );

  void _chooseFamilyRule(FamilyRule rule) => setState(() {
    _familyRule = rule;
    _beat = 15;
  });

  Widget _researchDeskName() => _NovelDialogue(
    key: const ValueKey('desk-name'),
    speaker: _speaker,
    line: _line,
    child: Column(
      children: [
        TextField(
          key: const Key('company-name-input'),
          controller: _companyController,
          maxLength: 24,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _finish(),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: _fieldDecoration('예: 별빛 투자'),
        ),
        _NovelNextButton(
          key: const Key('create-company-button'),
          label: '0원부터 시작하기',
          enabled: _companyController.text.trim().isNotEmpty,
          onTap: _finish,
        ),
      ],
    ),
  );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    counterText: '',
    filled: true,
    fillColor: const Color(0xFFFFFCF2),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD8BE91)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _coral, width: 2),
    ),
  );
}

class _LivingBackground extends StatelessWidget {
  const _LivingBackground({super.key, required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 1.04, end: 1),
    duration: const Duration(seconds: 7),
    curve: Curves.easeOut,
    builder: (context, scale, child) =>
        Transform.scale(scale: scale, child: child),
    child: Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
    ),
  );
}

class _SceneLabel extends StatelessWidget {
  const _SceneLabel({
    required this.date,
    required this.location,
    required this.progress,
  });

  final String date;
  final String location;
  final double progress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xD9292B3A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x66FFFFFF)),
              ),
              child: Text(
                '⌂  $location',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
            Text(
              date,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 3,
            value: progress,
            backgroundColor: const Color(0x55FFFFFF),
            valueColor: const AlwaysStoppedAnimation(_yellow),
          ),
        ),
      ],
    ),
  );
}

class _NovelDialogue extends StatelessWidget {
  const _NovelDialogue({
    super.key,
    required this.speaker,
    required this.line,
    this.narration = false,
    this.onContinue,
    this.choices = const [],
    this.child,
  });

  final String speaker;
  final String line;
  final bool narration;
  final VoidCallback? onContinue;
  final List<_NovelChoice> choices;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
    decoration: BoxDecoration(
      color: narration ? const Color(0xEC272A37) : const Color(0xF7FFF9EA),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xCCFFFFFF), width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!narration)
          Transform.translate(
            offset: const Offset(0, -25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              decoration: BoxDecoration(
                color: _coral,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x4433405F), offset: Offset(0, 3)),
                ],
              ),
              child: Text(
                speaker,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        if (!narration) const SizedBox(height: 0),
        Text(
          line,
          style: TextStyle(
            color: narration ? Colors.white : _ink,
            fontSize: narration ? 13 : 14,
            height: 1.55,
            fontWeight: narration ? FontWeight.w600 : FontWeight.w700,
          ),
        ),
        if (choices.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...choices.map(
            (choice) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: choice,
            ),
          ),
        ],
        if (child != null) ...[const SizedBox(height: 12), child!],
        if (onContinue != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('story-continue'),
              onPressed: onContinue,
              label: Text(narration ? '장면 계속' : '계속'),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              style: TextButton.styleFrom(
                foregroundColor: narration ? _yellow : _coral,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _NovelChoice extends StatelessWidget {
  const _NovelChoice({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(46),
        foregroundColor: _ink,
        backgroundColor: const Color(0xEFFFFFFF),
        side: const BorderSide(color: Color(0xFFD8BE91)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const Icon(Icons.chevron_right_rounded, color: _coral),
        ],
      ),
    ),
  );
}

class _NovelNextButton extends StatelessWidget {
  const _NovelNextButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 47,
    child: FilledButton.icon(
      onPressed: enabled ? onTap : null,
      label: Text(label),
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
      style: FilledButton.styleFrom(
        foregroundColor: _ink,
        backgroundColor: _yellow,
        disabledBackgroundColor: const Color(0xFFD9D6CC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
  );
}
