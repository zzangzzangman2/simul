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
    <= 7 => 'assets/images/bg_living_room_1999.png',
    <= 13 => 'assets/images/bg_kitchen_1999.png',
    _ => 'assets/images/bg_stock_academy_2000_v1.png',
  };

  String get _location => switch (_beat) {
    <= 7 => '거실 · TV 앞',
    <= 13 => '부엌 식탁',
    _ => '새천년 투자학원 · 입문반',
  };

  String get _dateLabel => switch (_beat) {
    <= 7 => '1999.12.31  ·  21:40',
    <= 13 => '2000.01.02  ·  일요일',
    _ => '2000년 1월  ·  첫 수업',
  };

  String? get _character => switch (_beat) {
    1 || 5 || 7 || 10 || 21 || 23 => 'assets/images/character_hero.png',
    4 || 6 || 12 => 'assets/images/character_father.png',
    2 => 'assets/images/character_sister.png',
    9 || 11 => 'assets/images/character_grandfather.png',
    3 || 13 => 'assets/images/character_mother.png',
    _ => null,
  };

  Alignment get _characterAlignment => switch (_beat) {
    4 || 6 || 9 || 11 || 12 => Alignment.bottomLeft,
    2 || 3 || 13 => Alignment.bottomRight,
    _ => Alignment.bottomCenter,
  };

  bool get _isAcademyTeacherBeat =>
      _beat >= 15 && _beat <= 20 || _beat == 22 || _beat >= 25;

  Alignment get _teacherPoseAlignment => switch (_beat) {
    15 => Alignment.topLeft,
    16 => Alignment.topCenter,
    17 => Alignment.topRight,
    18 => Alignment.bottomLeft,
    19 => Alignment.bottomRight,
    25 => Alignment.topLeft,
    26 => Alignment.bottomCenter,
    27 => Alignment.bottomRight,
    28 => Alignment.topCenter,
    _ => Alignment.bottomCenter,
  };

  bool get _isNarration =>
      _beat == 0 || _beat == 8 || _beat == 14 || _beat == 24;

  String get _speaker => switch (_beat) {
    0 || 8 || 14 || 24 => '이야기',
    1 || 5 || 7 || 10 || 21 || 23 =>
      _playerController.text.trim().isEmpty
          ? '나'
          : _playerController.text.trim(),
    2 => '누나',
    3 || 13 => '엄마',
    4 || 6 || 12 => '아빠',
    9 || 11 => '외할아버지',
    15 || 16 || 18 || 20 || 22 => '한서윤 선생님',
    25 || 26 || 27 || 28 => '한서윤 선생님',
    17 || 19 =>
      _playerController.text.trim().isEmpty
          ? '나'
          : _playerController.text.trim(),
    _ => '이야기',
  };

  String get _line => switch (_beat) {
    0 =>
      'TV 드라마 속 젊은 투자자가 작은 회사의 가능성을 먼저 알아보고 모두를 놀라게 했다. 엔딩 음악이 끝났는데도 내 눈은 화면에서 떨어지지 않았다.',
    1 => '저도 주식 해 보고 싶어요. 멋진 회사를 남들보다 먼저 찾아내는 거, 진짜 멋있잖아요!',
    2 => '드라마 한 편 보고 벌써 투자자야? 넥타이부터 사 달라고 하겠네.',
    3 => '멋있어 보이는 장면 뒤에는 잃을 수도 있는 진짜 돈이 있어. 버튼부터 누르는 건 안 돼.',
    4 => '그래도 정말 배우고 싶다면 먼저 투자학원 입문반부터 다녀. 회사와 주문이 뭔지는 알고 시작해야지.',
    5 => '학원이요? 저도 갈래요. 그런데 학원비는 얼마예요?',
    6 => '100만 원이다. 내가 먼저 내주마. 공짜 용돈은 아니고, 네 장부에 “아빠에게 갚을 학원비”로 적는 거야.',
    7 => '약속할게요. 제가 돈을 벌면 아빠가 먼저 내준 학원비부터 꼭 갚을게요.',
    8 => '주말 아침, 소식을 들은 외할아버지가 낡은 투자 장부와 세뱃돈 봉투를 들고 찾아왔다.',
    9 => '배우겠다고 마음먹은 건 좋구나. 이 장부와 세뱃돈 만 원을 첫 투자금으로 주마. 학원비 빚과 투자금은 절대 섞지 말거라.',
    10 => '외할아버지가 물었다. “학원에서 가장 먼저 무엇을 배우고 싶니?”',
    11 => _introResponse,
    12 => '입문반 수업은 내가 먼저 신청해 뒀다. 배운 뒤에도 모르는 주문은 반드시 우리에게 물어봐.',
    13 => '세뱃돈은 어머니 명의 교육용 증권계좌에 넣을게. 생활비, 학원비 빚, 투자금은 각각 따로 기록하자.',
    14 =>
      '첫 수업 날. 중학생과 고등학생들 사이에서 발이 바닥에 닿지 않는 의자에 앉았지만, 칠판의 차트만큼은 누구보다 크게 보였다.',
    15 => '반가워요. 입문반을 맡은 한서윤입니다. 오늘은 종목 추천 대신, 주문하기 전에 반드시 알아야 할 것부터 배울 거예요.',
    16 => '주식 한 주는 회사의 아주 작은 조각이에요. 가격표만 사는 게 아니라 그 회사의 제품, 실적, 위험을 함께 사는 거죠.',
    17 => '그럼 가격이 오르는 회사가 무조건 좋은 회사인 건가요?',
    18 =>
      '아니에요. 가격이 오른다는 건 사려는 사람이 더 급했다는 뜻일 뿐이에요. 회사·매수와 매도·가격 방식을 따로 확인해 볼까요?',
    19 => '시장가랑 지정가는 언제 골라야 해요? 빨리 사는 게 항상 좋은 건 아니죠?',
    20 =>
      '맞아요. 시장가는 빠른 체결, 지정가는 원하는 가격을 우선해요. 수수료까지 확인한 뒤 투자노트 첫 장에 이름을 적어 볼까요?',
    21 =>
      '${_playerController.text.trim()}입니다. 드라마처럼 멋있어 보이는 것보다, 제가 왜 사는지 설명할 수 있는 투자자가 될래요.',
    22 => '첫 조사 과제입니다. 어떤 기준을 가장 먼저 연습해 보고 싶나요?',
    23 => _traitResponse,
    24 => '수업 마지막 화면 실습을 앞두고, 선생님은 가족이 적어 보낸 투자 약속 카드와 세뱃돈 장부를 교탁 위에 펼쳤다.',
    25 => '가족과 약속한 원칙 가운데 첫 주문부터 반드시 지킬 한 가지를 골라 볼까요?',
    26 =>
      '아빠가 먼저 낸 학원비 1,000,000원은 투자금이 아니에요. 나중에 회사 통장에 돈이 모이면 거실에서 아빠에게 갚아야 해요.',
    27 =>
      '외할아버지의 세뱃돈 10,000원은 교육용 증권계좌에 들어 있어요. 이제 화면 실습에 표시할 투자연구소 이름을 정해 볼까요?',
    _ => '좋아요. 이름을 적으면 집으로 돌아가기 전에 실제 주식 화면을 열어, 제가 가리키는 곳을 함께 눌러 볼게요.',
  };

  String get _introResponse => switch (_introChoice) {
    'computer' => '컴퓨터는 빠르지만 답을 대신 정해 주지는 않는단다. 회사 소식을 찾고 서로 맞는지 확인하는 법부터 배우렴.',
    'y2k' => '돈을 지키는 질문부터 배우겠다는 건 좋은 시작이다. 모르는 위험은 작게 시작해서 확인하면 돼.',
    'stocks' => '좋은 회사를 고르는 눈은 하루아침에 생기지 않는다. 제품을 보고 숫자를 읽고, 틀릴 가능성도 함께 적어 보렴.',
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
    final isNameEntry = _beat == 20 || _beat == 28;
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
                progress: (_beat + 1) / 29,
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
          if (_isAcademyTeacherBeat)
            Positioned(
              right: -18,
              bottom: 112,
              child: _AcademyTeacherPose(poseAlignment: _teacherPoseAlignment),
            )
          else if (_character != null)
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
    if (_beat == 10) return _introChoices();
    if (_beat == 18) return _academyTutorial();
    if (_beat == 20) return _nameEntry();
    if (_beat == 22) return _traitChoices();
    if (_beat == 25) return _familyChoices();
    if (_beat == 28) return _researchDeskName();

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
        label: '컴퓨터로 회사 소식을 찾는 법',
        onTap: () => setState(() {
          _introChoice = 'computer';
          _beat = 11;
        }),
      ),
      _NovelChoice(
        key: const Key('story-intro-y2k'),
        label: '돈을 잃지 않게 위험을 확인하는 법',
        onTap: () => setState(() {
          _introChoice = 'y2k';
          _beat = 11;
        }),
      ),
      _NovelChoice(
        key: const Key('story-intro-stocks'),
        label: '좋은 회사를 골라 주주가 되는 법',
        onTap: () => setState(() {
          _introChoice = 'stocks';
          _beat = 11;
        }),
      ),
    ],
  );

  Widget _academyTutorial() => _NovelDialogue(
    key: const ValueKey('academy-tutorial'),
    speaker: _speaker,
    line: _line,
    child: Column(
      children: [
        const _AcademyLessonRow(
          number: '1',
          title: '회사 조각',
          body: '제품 · 실적 · 위험을 먼저 본다',
        ),
        const SizedBox(height: 6),
        const _AcademyLessonRow(
          number: '2',
          title: '매수와 매도',
          body: '사는 주문과 파는 주문을 구분한다',
        ),
        const SizedBox(height: 6),
        const _AcademyLessonRow(
          number: '3',
          title: '시장가와 지정가',
          body: '빠른 체결과 원하는 가격의 차이, 수수료까지 확인한다',
        ),
        const SizedBox(height: 10),
        _NovelNextButton(
          key: const Key('academy-tutorial-continue'),
          label: '주문표 연습 완료',
          enabled: true,
          onTap: _next,
        ),
      ],
    ),
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
    _beat = 23;
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
    _beat = 26;
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
          label: '투자연구소 이름을 적고 시장 실습 시작',
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

class _AcademyTeacherPose extends StatelessWidget {
  const _AcademyTeacherPose({required this.poseAlignment});

  final Alignment poseAlignment;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dimension = math
        .min(size.width * 1.28, size.height * 0.68)
        .clamp(300.0, 520.0)
        .toDouble();
    return SizedBox(
      key: const Key('academy-teacher-character'),
      width: dimension,
      height: dimension,
      child: ClipRect(
        child: OverflowBox(
          alignment: poseAlignment,
          minWidth: dimension * 3,
          maxWidth: dimension * 3,
          minHeight: dimension * 2,
          maxHeight: dimension * 2,
          child: Image.asset(
            'assets/images/주식선생님/05_6자세_슬랜더_투명_최종.png',
            width: dimension * 3,
            height: dimension * 2,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _AcademyLessonRow extends StatelessWidget {
  const _AcademyLessonRow({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4D8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5C98E)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: const Color(0xFF536A96),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                body,
                style: const TextStyle(
                  color: Color(0xFF687183),
                  fontSize: 9,
                  height: 1.3,
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
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xD9292B3A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x66FFFFFF)),
                ),
                child: Text(
                  '⌂  $location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
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
