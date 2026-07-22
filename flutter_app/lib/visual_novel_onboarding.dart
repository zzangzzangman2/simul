part of 'main.dart';

class VisualNovelOnboardingScreen extends StatefulWidget {
  const VisualNovelOnboardingScreen({
    super.key,
    required this.onCreate,
    this.onExit,
  });

  final ValueChanged<NewGameSetup> onCreate;
  final VoidCallback? onExit;

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
    <= 13 => 'assets/images/bg_living_room_1999.png',
    <= 22 => 'assets/images/bg_kitchen_1999.png',
    _ => 'assets/images/bg_boy_room_1999.png',
  };

  String get _location => switch (_beat) {
    <= 2 => '작은방',
    <= 13 => '거실',
    <= 22 => '부엌 식탁',
    _ => '작은방 책상',
  };

  String get _dateLabel =>
      _beat <= 13 ? '1999.12.31  ·  23:57' : '2000.01.02  ·  일요일';

  String? get _character => switch (_beat) {
    2 || 5 || 9 || 10 || 18 || 19 || 20 => 'assets/images/character_hero.png',
    4 || 11 || 21 || 22 => 'assets/images/character_father.png',
    3 || 7 => 'assets/images/character_sister.png',
    14 || 15 || 17 => 'assets/images/character_grandfather.png',
    1 || 6 || 12 || 16 => 'assets/images/character_mother.png',
    _ => null,
  };

  Alignment get _characterAlignment => switch (_beat) {
    4 || 11 || 14 || 15 || 17 || 21 || 22 => Alignment.bottomLeft,
    1 || 3 || 6 || 7 || 12 || 16 => Alignment.bottomRight,
    _ => Alignment.bottomCenter,
  };

  bool get _isNarration =>
      _beat == 0 || _beat == 8 || _beat == 13 || _beat == 23;

  String get _speaker => switch (_beat) {
    0 || 8 || 13 || 23 => '이야기',
    1 || 6 || 12 || 16 => '엄마',
    2 || 5 || 9 || 10 || 18 || 19 || 20 =>
      _playerController.text.trim().isEmpty
          ? '나'
          : _playerController.text.trim(),
    3 || 7 => '누나',
    4 || 11 || 21 || 22 => '아빠',
    14 || 15 || 17 => '외할아버지',
    _ => '이야기',
  };

  String get _line => switch (_beat) {
    0 => '새 천년을 세 분 앞둔 밤. 방 안에는 컴퓨터 팬 소리와 거실에서 흘러오는 카운트다운 음악이 뒤섞여 있었다.',
    1 => '이제 컴퓨터도 잠깐 쉬게 해 줘. 귤 까 놨으니까 얼른 거실로 와!',
    2 => '잠깐만요. 화면에 있는 숫자 하나만 보고 갈게요. 자꾸 바뀌니까 신기해요.',
    3 => '또 숫자 구경이야? 그러다 새해도 컴퓨터랑 둘이 맞겠다.',
    4 => '놀리지는 말고. 궁금한 게 많은 건 좋은 일이야. 대신 직접 확인하는 습관을 들여야지.',
    5 => '그럼 오늘은 제가 날짜가 제대로 바뀌는지 확인할래요.',
    6 => '좋아. 확인이 끝나면 우리한테도 쉽게 설명해 줘. 어려운 말은 금지야.',
    7 => '맞아. 나도 알아들을 수 있게 말하면 인정해 줄게.',
    8 => '가족이 거실에 둘러앉았다. TV에서는 새 천년 이야기가 쏟아졌고, 모두의 시선이 자연스럽게 내게 모였다.',
    9 => '나는 조금 긴장했지만, 가장 궁금했던 말을 먼저 꺼냈다.',
    10 => _introResponse,
    11 => '좋은 질문이네. 답을 외우는 것보다 왜 그런지 하나씩 찾아보는 게 더 중요해.',
    12 => '모르면 가족에게 물어봐도 돼. 혼자 끙끙대다가 큰돈을 쓰는 건 안 되고.',
    13 => '셋, 둘, 하나. 모두가 환호했다. 그리고 주말 아침, 외할아버지가 낡은 장부 한 권을 들고 찾아왔다.',
    14 => '이건 네 첫 투자노트다. 주식은 회사의 아주 작은 조각을 사는 일이라고 생각하면 돼.',
    15 => '다만 시작 돈은 0원이다. 먼저 일해서 만 원을 벌고, 사고 싶은 회사가 생기면 가족에게 이유를 말해 보렴.',
    16 => '처음부터 잘할 필요 없어. 회사 하나를 보고, 좋은 점 하나와 걱정되는 점 하나만 찾으면 충분해.',
    17 => '좋아, 그럼 첫 장부터 채워 보자. 이 투자노트에 어떤 이름을 적을까?',
    18 => '내 이름을 적고 나니 진짜 내 장부가 된 것 같았다. 이제 무엇부터 배울지 정할 차례다.',
    19 => '나는 먼저 이것부터 알아보고 싶다.',
    20 => _traitResponse,
    21 => '좋아. 우리 집 규칙은 간단하다. 생활비와 투자금을 섞지 않고, 빚내서 투자하지 않는다.',
    22 => '마지막 약속 하나는 네가 직접 골라 보렴. 나중에 흔들릴 때 이 문장을 다시 읽는 거야.',
    _ => '큰 사무실은 없지만 작은방 책상과 0원에서 시작하는 투자노트가 있다. 이제 우리 투자연구소 이름을 붙여 보자.',
  };

  String get _introResponse => switch (_introChoice) {
    'computer' => '“제가 먼저 확인해 봐도 돼요?” 아빠가 웃으며 고개를 끄덕였다. “좋아. 확인하고 우리한테도 알려 줘.”',
    'y2k' => '“정말 컴퓨터가 다 멈출 수도 있어요?” 엄마가 말했다. “그래서 겁먹기보다 하나씩 확인하는 거야.”',
    'stocks' =>
      '“컴퓨터로 주식도 살 수 있어요?” 누나가 눈을 동그랗게 떴고 아빠는 “그 전에 주식이 뭔지부터 알아야지”라며 웃었다.',
    _ => '',
  };

  String get _traitResponse => switch (_trait) {
    StoryTrait.stability => '먼저 돈을 잃지 않는 방법을 배우고 싶다. 그래야 오래 계속할 수 있을 것 같다.',
    StoryTrait.innovation => '사람들의 생활을 바꾸는 제품을 찾아보고 싶다. 새 기술 이야기는 언제나 두근거린다.',
    StoryTrait.analysis => '숫자가 왜 오르고 내리는지 직접 적어 보고 싶다. 하나씩 비교하면 길이 보일 것 같다.',
    StoryTrait.control => '회사가 어떤 선택을 하는지 알아보고 싶다. 주주가 회사에 어떤 목소리를 내는지도 궁금하다.',
    null => '',
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
    final isNameEntry = _beat == 17 || _beat == 23;
    final keyboardLift = isKeyboardOpen && isNameEntry
        ? viewInsets.bottom
        : 0.0;
    return Scaffold(
      backgroundColor: const Color(0xFF171B2A),
      resizeToAvoidBottomInset: false,
      body: Stack(
        key: const Key('onboarding-stage'),
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
                progress: (_beat + 1) / 24,
              ),
            ),
          ),
          if (widget.onExit != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton.filledTonal(
                    key: const Key('onboarding-exit-button'),
                    tooltip: '타이틀로',
                    onPressed: widget.onExit,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xB3151B28),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
              ),
            ),
          if (_character != null)
            Positioned.fill(
              bottom: 122,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: 1,
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
          AnimatedPositioned(
            key: const Key('keyboard-name-panel'),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            left: 12,
            right: 12,
            bottom: keyboardLift + 10,
            child: SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _buildDialogue(context),
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
    if (_beat == 9) return _introChoices();
    if (_beat == 17) return _nameEntry();
    if (_beat == 19) return _traitChoices();
    if (_beat == 22) return _familyChoices();
    if (_beat == 23) return _researchDeskName();

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
          _beat = 10;
        }),
      ),
      _NovelChoice(
        key: const Key('story-intro-y2k'),
        label: '“정말 다 멈출 수도 있어요?”',
        onTap: () => setState(() {
          _introChoice = 'y2k';
          _beat = 10;
        }),
      ),
      _NovelChoice(
        key: const Key('story-intro-stocks'),
        label: '“이걸로 주식도 살 수 있어요?”',
        onTap: () => setState(() {
          _introChoice = 'stocks';
          _beat = 10;
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
          label: '이 이름으로 시작하기',
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
    _beat = 20;
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
    _beat = 23;
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
          label: '0원부터 첫날 시작하기',
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
