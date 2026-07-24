part of 'main.dart';

const _onboardingBeatCount = 31;
const _storyCharacterBottomInset = 122.0;
const _storyCharacterHeightFactor = 0.78;
const _storyCharacterAspectRatio = 2 / 3;

typedef NewGameCreator =
    Future<void> Function(NewGameSetup setup, ValueChanged<String> onProgress);

class VisualNovelOnboardingScreen extends StatefulWidget {
  const VisualNovelOnboardingScreen({super.key, required this.onCreate});

  final NewGameCreator onCreate;

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
  bool _isCreating = false;
  String _creationStatus = '투자연구소 정보를 정리하는 중…';

  @override
  void dispose() {
    _playerController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  String get _background => switch (_beat) {
    <= 7 => 'assets/images/bg_living_room_1999.png',
    <= 13 => 'assets/images/bg_kitchen_1999.png',
    _ => 'assets/images/bg_stock_academy_2000_v3.png',
  };

  String get _location => switch (_beat) {
    <= 7 => '거실 · TV 앞',
    <= 13 => '부엌 식탁',
    _ => '새천년 청소년 투자학교 · 10대 입문반',
  };

  String get _dateLabel => switch (_beat) {
    <= 7 => '1999.12.31  ·  21:40',
    <= 13 => '2000.01.02  ·  일요일',
    <= 16 => '2000년 1월  ·  첫 등교',
    _ => '2000년 1월  ·  첫 수업',
  };

  String? get _character => switch (_beat) {
    1 ||
    5 ||
    7 ||
    10 ||
    15 ||
    23 ||
    25 => 'assets/images/character_hero_title_style_v2.png',
    4 || 6 || 12 => 'assets/images/character_father_title_style_v2.png',
    2 => 'assets/images/character_sister_title_style_v2.png',
    9 || 11 => 'assets/images/character_grandfather.png',
    3 || 13 => 'assets/images/character_mother_title_style_v2.png',
    _ => null,
  };

  Alignment get _characterAlignment => switch (_beat) {
    4 || 6 || 9 || 11 || 12 => Alignment.bottomLeft,
    2 || 3 || 13 => Alignment.bottomRight,
    _ => Alignment.bottomCenter,
  };

  bool get _isAcademyTeacherBeat =>
      _beat >= 17 && _beat <= 22 || _beat == 24 || _beat >= 27;

  String get _teacherPoseAsset => switch (_beat) {
    17 => 'assets/images/주식선생님/24_포즈3_주인공그림체_공통슬롯_투명.png',
    18 || 28 => 'assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png',
    19 || 21 => 'assets/images/주식선생님/26_포즈5_주인공그림체_공통슬롯_투명.png',
    20 || 29 => 'assets/images/주식선생님/23_포즈2_주인공그림체_공통슬롯_투명.png',
    22 => 'assets/images/주식선생님/27_포즈6_주인공그림체_공통슬롯_투명.png',
    24 || 27 => 'assets/images/주식선생님/25_포즈4_주인공그림체_공통슬롯_투명.png',
    30 => 'assets/images/주식선생님/24_포즈3_주인공그림체_공통슬롯_투명.png',
    _ => 'assets/images/주식선생님/26_포즈5_주인공그림체_공통슬롯_투명.png',
  };

  bool get _isNarration =>
      _beat == 0 || _beat == 8 || _beat == 14 || _beat == 16 || _beat == 26;

  String get _speaker => switch (_beat) {
    0 || 8 || 14 || 16 || 26 => '이야기',
    1 || 5 || 7 || 10 || 15 || 23 || 25 =>
      _playerController.text.trim().isEmpty
          ? '나'
          : _playerController.text.trim(),
    2 => '누나',
    3 || 13 => '엄마',
    4 || 6 || 12 => '아빠',
    9 || 11 => '외할아버지',
    17 || 18 || 20 || 22 || 24 => '한서윤 선생님',
    27 || 28 || 29 || 30 => '한서윤 선생님',
    19 || 21 =>
      _playerController.text.trim().isEmpty
          ? '나'
          : _playerController.text.trim(),
    _ => '이야기',
  };

  String get _line => switch (_beat) {
    0 =>
      'TV 드라마에서 작은 회사의 가능성을 먼저 알아본 투자자가 모두를 놀라게 했다. 엔딩 음악이 끝났는데도 나는 리모컨을 내려놓지 못했다.',
    1 => '나도 주식 해 보고 싶어요! 저 사람처럼 좋은 회사를 먼저 찾으면 진짜 신날 것 같아요.',
    2 => '드라마 한 편 보고 벌써 투자자야? 내일 넥타이부터 사 달라고 하겠네.',
    3 => '주식은 게임 점수가 아니라 진짜 돈이 움직이는 일이야. 먼저 배우고, 어른과 같이 해 보자.',
    4 => '정말 궁금하면 청소년 투자학교 입문반에 가 보자. 회사와 주문이 뭔지부터 천천히 배우는 거야.',
    5 => '투자학교요? 우와, 저도 갈래요! 거기 가면 주식 화면도 직접 눌러 볼 수 있어요?',
    6 => '수업료는 100만 원이야. 아빠가 먼저 내 줄게. 용돈은 아니니까 나중에 장부에 어떻게 갚을지도 같이 적자.',
    7 => '네! 몰래 사지 않고, 배운 건 집에 와서 꼭 보여드릴게요.',
    8 => '주말 아침, 소식을 들은 외할아버지가 낡은 투자 장부와 세뱃돈 봉투를 들고 찾아왔다.',
    9 => '배우고 싶다는 마음이 기특하구나. 이 장부와 세뱃돈 만 원을 줄 테니, 처음에는 아주 작게 연습해 보렴.',
    10 => '음… 저는 학원에서 뭘 제일 먼저 배우면 좋을까요?',
    11 => _introResponse,
    12 => '수업을 듣고도 헷갈리는 주문은 그냥 누르지 말고 꼭 우리에게 물어봐.',
    13 => '세뱃돈은 엄마가 교육용 계좌에 따로 넣어 둘게. 네가 무엇을 사고 왜 샀는지도 같이 적어 보자.',
    14 =>
      '며칠 뒤, 집으로 ‘새천년 청소년 투자학교’의 남색 초대장이 왔다. 만 10세부터 19세까지만 다니며, 첫 주문은 보호자와 함께 돌아보는 학교였다.',
    15 => '진짜 10대만 오는 곳이네! 무슨 종목을 사라고 외우는 곳이 아니라, 제가 고른 이유를 말하는 곳이래요.',
    16 =>
      '첫 등교 날. 나는 교탁과 주식 단말이 놓인 조용한 교실에 먼저 들어갔다. 잠시 뒤 문이 열리고 담임 선생님이 교탁 옆에 섰다.',
    17 =>
      '안녕하세요! 10대 입문반을 맡은 한서윤이에요. 여기서는 “이 종목 사세요”라고 답을 주지 않아요. 회사와 숫자를 보고 스스로 고르는 법을 연습할 거예요.',
    18 =>
      '주식 한 주는 회사의 아주 작은 조각이에요. 주식을 사면 가격표뿐 아니라 그 회사가 잘될 가능성과 어려워질 위험도 함께 갖게 돼요.',
    19 => '그럼 가격이 제일 많이 오른 회사가 제일 좋은 회사예요?',
    20 =>
      '꼭 그렇지는 않아요. 가격은 사람들의 주문 때문에 먼저 움직일 수도 있거든요. 회사, 매수와 매도, 주문 가격을 하나씩 볼까요?',
    21 => '시장가랑 지정가는 이름이 어려워요. 빨리 사고 싶을 때는 그냥 시장가를 누르면 돼요?',
    22 =>
      '시장가는 빨리 사고팔 때, 지정가는 원하는 가격을 정할 때 써요. 둘 다 장단점이 있으니 수수료까지 보고 고르면 돼요. 먼저 이름을 알려 줄래요?',
    23 =>
      '저는 ${_playerController.text.trim()}예요. 멋져 보이는 것보다, 제가 왜 샀는지 제 말로 설명해 보고 싶어요.',
    24 => '좋아요. 첫 번째로 어떤 걸 연습해 보고 싶어요?',
    25 => _traitResponse,
    26 => '선생님은 컴퓨터 옆에 작은 주문표를 놓았다. 이제 직접 매수와 매도를 해 볼 시간이었다.',
    27 => '주문 버튼을 누르기 전에, 오늘부터 지킬 약속 하나만 골라 볼까요?',
    28 => _lessonRuleResponse,
    29 => '좋아요. 이제 교실 컴퓨터로 실제 주문 화면을 연습할 거예요. 그 전에 투자노트 표지에 붙일 이름도 하나 정해 볼까요?',
    _ => '어렵게 짓지 않아도 돼요. 마음에 드는 이름이면 충분해요. 이름을 적으면 같이 주식 화면을 열어 봐요!',
  };

  String get _introResponse => switch (_introChoice) {
    'computer' =>
      '좋은 질문이구나. 컴퓨터는 빠르지만 답을 대신 골라 주지는 않아. 회사 소식을 찾고 서로 맞는지 확인하는 법부터 배우렴.',
    'y2k' => '돈을 잃지 않는 법이 궁금하구나. 처음에는 조금만 해 보고, 모르는 위험을 하나씩 확인하면 된단다.',
    'stocks' => '좋은 회사는 하루 만에 알아보기 어려워. 무엇을 파는 회사인지 보고, 숫자도 천천히 읽어 보렴.',
    _ => '',
  };

  String get _traitResponse => switch (_trait) {
    StoryTrait.stability => '돈을 잃지 않는 법부터 배우고 싶어요! 그래야 오래 해 볼 수 있잖아요.',
    StoryTrait.innovation => '사람들이 “우와!” 할 물건을 만드는 회사를 찾아보고 싶어요.',
    StoryTrait.analysis => '신문에 나오는 숫자가 왜 오르내리는지 궁금해요. 제가 직접 비교해 볼래요.',
    StoryTrait.control => '주주가 되면 회사에 어떤 말을 할 수 있는지 궁금해요.',
    null => '',
  };

  String get _lessonRuleResponse => switch (_familyRule) {
    FamilyRule.reportLosses =>
      '좋아요. 손해가 나도 숨기지 않고 그대로 적기! 틀린 이유를 찾으면 다음 주문은 더 잘할 수 있어요.',
    FamilyRule.noHotTips =>
      '좋아요. 누가 좋다고 해도 바로 사지 않고, 내가 먼저 회사를 확인하기! 아주 중요한 약속이에요.',
    FamilyRule.keepCash =>
      '좋아요. 가진 돈을 한 번에 다 쓰지 않고 조금 남겨 두기! 다음 기회를 기다릴 수 있어요.',
    null => '',
  };

  void _next() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _beat += 1);
  }

  Future<void> _finish() async {
    if (_isCreating) return;
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
    setState(() {
      _isCreating = true;
      _creationStatus = '투자연구소 정보를 정리하는 중…';
    });
    await WidgetsBinding.instance.endOfFrame;
    try {
      await widget.onCreate(
        NewGameSetup(
          playerName: playerName,
          companyName: companyName,
          introChoice: _introChoice!,
          startingTrait: _trait!,
          familyRule: _familyRule!,
        ),
        (status) {
          if (mounted) setState(() => _creationStatus = status);
        },
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final isKeyboardOpen = viewInsets.bottom > 0;
    final isNameEntry = _beat == 22 || _beat == 30;
    final keyboardLift = isKeyboardOpen && isNameEntry
        ? viewInsets.bottom
        : 0.0;
    return Scaffold(
      backgroundColor: const Color(0xFF171B2A),
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sceneCharacterAsset = _isAcademyTeacherBeat
              ? _teacherPoseAsset
              : _character;
          return Stack(
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
                    progress: (_beat + 1) / _onboardingBeatCount,
                  ),
                ),
              ),

              if (sceneCharacterAsset != null)
                Positioned.fill(
                  bottom: _storyCharacterBottomInset,
                  child: _OnboardingCharacterSlot(
                    key: const Key('story-character-stage-slot'),
                    asset: sceneCharacterAsset,
                    alignment: _isAcademyTeacherBeat
                        ? Alignment.bottomCenter
                        : _characterAlignment,
                    characterKey: _isAcademyTeacherBeat
                        ? const Key('academy-teacher-character')
                        : const Key('story-character-character'),
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
              if (_isCreating)
                Positioned.fill(
                  child: _NewGamePreparationOverlay(status: _creationStatus),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogue(BuildContext context) {
    if (_beat == 10) return _introChoices();
    if (_beat == 20) return _academyTutorial();
    if (_beat == 22) return _nameEntry();
    if (_beat == 24) return _traitChoices();
    if (_beat == 27) return _familyChoices();
    if (_beat == 30) return _researchDeskName();

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
    _beat = 25;
  });

  Widget _familyChoices() => _NovelDialogue(
    key: const ValueKey('family-choice'),
    speaker: _speaker,
    line: _line,
    choices: [
      _NovelChoice(
        key: const Key('family-rule-report-losses'),
        label: '손해가 나도 숨기지 않고 적기',
        onTap: () => _chooseFamilyRule(FamilyRule.reportLosses),
      ),
      _NovelChoice(
        key: const Key('family-rule-no-hot-tips'),
        label: '남이 좋다고 해도 바로 사지 않기',
        onTap: () => _chooseFamilyRule(FamilyRule.noHotTips),
      ),
      _NovelChoice(
        key: const Key('family-rule-keep-cash'),
        label: '돈을 한 번에 다 쓰지 않기',
        onTap: () => _chooseFamilyRule(FamilyRule.keepCash),
      ),
    ],
  );

  void _chooseFamilyRule(FamilyRule rule) => setState(() {
    _familyRule = rule;
    _beat = 28;
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
          label: '투자노트 이름을 적고 주문 연습 시작',
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

class _NewGamePreparationOverlay extends StatelessWidget {
  const _NewGamePreparationOverlay({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('new-game-preparation-overlay'),
    color: const Color(0xD9171B2A),
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFE4A3), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.savings_rounded,
                  color: Color(0xFF536A96),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  '첫 투자 수업을 준비하고 있어요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF33405F),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    status,
                    key: const Key('new-game-preparation-status'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF66728A),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const LinearProgressIndicator(
                  minHeight: 9,
                  backgroundColor: Color(0xFFE8E1D1),
                  color: Color(0xFFFFA45F),
                ),
                const SizedBox(height: 14),
                const Text(
                  '준비가 끝나면 자동으로 주식 화면으로 넘어갑니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8B877F),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

class _OnboardingCharacterSlot extends StatelessWidget {
  const _OnboardingCharacterSlot({
    super.key,
    required this.asset,
    required this.alignment,
    required this.characterKey,
  });

  final String asset;
  final Alignment alignment;
  final Key characterKey;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    duration: const Duration(milliseconds: 180),
    opacity: 1,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: LayoutBuilder(
        key: ValueKey('$asset-${alignment.x}-${alignment.y}'),
        builder: (context, constraints) {
          final characterHeight =
              constraints.maxHeight * _storyCharacterHeightFactor;
          return Align(
            alignment: alignment,
            child: SizedBox(
              key: characterKey,
              width: characterHeight * _storyCharacterAspectRatio,
              height: characterHeight,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
          );
        },
      ),
    ),
  );
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
