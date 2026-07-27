part of 'main.dart';

const _onboardingBeatCount = 39;
const _storyCharacterBottomInset = 122.0;
const _storyCharacterHeightFactor = 0.78;
const _storyCharacterAspectRatio = 2 / 3;

typedef NewGameCreator =
    Future<void> Function(
      NewGameSetup setup,
      WorldLoadProgressCallback onProgress,
    );

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
  bool _isTraveling = false;
  bool _tuitionPaid = false;
  WorldLoadProgress _creationProgress = const WorldLoadProgress(
    0.02,
    '투자연구소 정보를 정리하는 중…',
  );

  @override
  void dispose() {
    _playerController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  String get _background => switch (_beat) {
    <= 7 => 'assets/images/bg_living_room_1999_portrait_cartoon_v2.png',
    <= 13 => 'assets/images/bg_kitchen_2000_morning_portrait_cartoon_v2.png',
    <= 18 => 'assets/images/bg_living_room_1999_portrait_cartoon_v2.png',
    <= 23 =>
      'assets/images/bg_stock_academy_entrance_2000_portrait_cartoon_v1.png',
    _ => 'assets/images/bg_stock_academy_2000_portrait_cartoon_v4.png',
  };

  String get _location => switch (_beat) {
    <= 7 => '거실 · TV 앞',
    <= 13 => '부엌 식탁',
    <= 15 => '우리 집 · 거실',
    <= 18 => '우리 집 · 현관 앞',
    <= 20 => '새천년 청소년 투자학교 · 정문',
    <= 23 => '새천년 청소년 투자학교 · 접수대',
    _ => '새천년 청소년 투자학교 · 10대 입문반',
  };

  String get _dateLabel => switch (_beat) {
    <= 7 => '1999.12.31  ·  21:40',
    <= 13 => '2000.01.02  ·  일요일',
    <= 15 => '2000년 1월  ·  초대장 도착',
    <= 24 => '2000년 1월  ·  첫 등교',
    _ => '2000년 1월  ·  첫 수업',
  };

  String? get _character => switch (_beat) {
    1 ||
    5 ||
    7 ||
    10 ||
    15 => 'assets/images/character_hero_title_style_v2.png',
    18 => 'assets/images/character_hero_determined_v1.png',
    20 || 27 => 'assets/images/character_hero_questioning_v1.png',
    29 => 'assets/images/character_hero_thoughtful_v1.png',
    31 || 33 => 'assets/images/character_hero_determined_v1.png',
    4 || 6 || 12 || 17 => 'assets/images/character_father_title_style_v2.png',
    2 => 'assets/images/character_sister_title_style_v2.png',
    9 || 11 => 'assets/images/character_grandfather.png',
    3 || 13 => 'assets/images/character_mother_title_style_v2.png',
    _ => null,
  };

  Alignment get _characterAlignment => switch (_beat) {
    4 || 6 || 9 || 11 || 12 || 17 => Alignment.bottomLeft,
    2 || 3 || 13 => Alignment.bottomRight,
    _ => Alignment.bottomCenter,
  };

  bool get _isAcademyTeacherBeat =>
      _beat == 25 ||
      _beat == 26 ||
      _beat == 28 ||
      _beat == 30 ||
      _beat == 32 ||
      _beat >= 35;

  bool get _isAcademyReceptionistBeat =>
      _beat == 21 || _beat == 22 || _beat == 23;

  String get _teacherPoseAsset => switch (_beat) {
    25 => 'assets/images/주식선생님/24_포즈3_주인공그림체_공통슬롯_투명.png',
    26 || 36 => 'assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png',
    28 || 37 => 'assets/images/주식선생님/23_포즈2_주인공그림체_공통슬롯_투명.png',
    30 => 'assets/images/주식선생님/27_포즈6_주인공그림체_공통슬롯_투명.png',
    32 || 35 => 'assets/images/주식선생님/25_포즈4_주인공그림체_공통슬롯_투명.png',
    38 => 'assets/images/주식선생님/24_포즈3_주인공그림체_공통슬롯_투명.png',
    _ => 'assets/images/주식선생님/26_포즈5_주인공그림체_공통슬롯_투명.png',
  };

  bool get _isNarration =>
      _beat == 0 ||
      _beat == 8 ||
      _beat == 14 ||
      _beat == 16 ||
      _beat == 19 ||
      _beat == 24 ||
      _beat == 34;

  String get _speaker => switch (_beat) {
    0 || 8 || 14 || 16 || 19 || 24 || 34 => '이야기',
    1 || 5 || 7 || 10 || 15 || 18 || 20 || 31 || 33 =>
      _playerController.text.trim().isEmpty
          ? '나'
          : _playerController.text.trim(),
    2 => '누나',
    3 || 13 => '엄마',
    4 || 6 || 12 || 17 => '아빠',
    9 || 11 => '외할아버지',
    21 || 22 || 23 => '투자학교 접수원',
    25 || 26 || 28 || 30 || 32 => '한서윤 선생님',
    35 || 36 || 37 || 38 => '한서윤 선생님',
    27 || 29 =>
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
      '첫 등교 날 아침. 나는 초대장, 외할아버지의 투자 장부, 연필 세 자루를 가방에 넣었다. 현관에는 아빠가 수업료 봉투와 등록 서류를 들고 기다리고 있었다.',
    17 =>
      '초대장과 장부는 챙겼지? 접수할 때 아빠가 수업료 100만 원을 먼저 낼 거야. 네 투자금 만 원과는 다른 돈이고, 나중에 장부에 갚을 돈으로 적는 거야.',
    18 => '네! 투자 장부도 챙겼어요. 이제 정말 출발하는 거죠? 어떤 친구들이 와 있을지 궁금해요.',
    19 =>
      '버스에서 내려 골목을 돌자 남색 문양이 붙은 건물이 보였다. 초등학생부터 고등학생까지, 나보다 훨씬 커 보이는 학생들이 노트와 서류철을 들고 정문으로 모여들고 있었다.',
    20 =>
      '우와… 정말 학생이 이렇게 많아? 형, 누나들만 있는 줄 알았는데 저만 한 친구도 있네. 다들 벌써 주식을 잘 아는 걸까?',
    21 =>
      '처음 오셨죠? 초대장과 보호자 등록 서류를 확인할게요. 입문반은 나이보다 투자 경험을 먼저 묻지 않으니 긴장하지 않아도 돼요.',
    22 =>
      '등록 서류가 확인됐습니다. 수업료 1,000,000원은 보호자 통장에서 결제되고, 학생의 교육용 투자금 10,000원은 그대로 남습니다.',
    23 => '결제가 완료됐어요. 여기 영수증과 학원비 상환 메모가 있습니다. 오른쪽 복도를 따라가면 10대 입문반 교실이에요.',
    24 =>
      '영수증을 장부 사이에 끼우고 교실 문을 열었다. 교탁과 주식 단말이 놓인 조용한 교실에 먼저 앉자, 잠시 뒤 담임 선생님이 교탁 옆에 섰다.',
    25 =>
      '안녕하세요! 10대 입문반을 맡은 한서윤이에요. 여기서는 “이 종목 사세요”라고 답을 주지 않아요. 회사와 숫자를 보고 스스로 고르는 법을 연습할 거예요.',
    26 =>
      '주식 한 주는 회사의 아주 작은 조각이에요. 주식을 사면 가격표뿐 아니라 그 회사가 잘될 가능성과 어려워질 위험도 함께 갖게 돼요.',
    27 => '그럼 가격이 제일 많이 오른 회사가 제일 좋은 회사예요?',
    28 =>
      '꼭 그렇지는 않아요. 가격은 사람들의 주문 때문에 먼저 움직일 수도 있거든요. 회사, 매수와 매도, 주문 가격을 하나씩 볼까요?',
    29 => '시장가랑 지정가는 이름이 어려워요. 빨리 사고 싶을 때는 그냥 시장가를 누르면 돼요?',
    30 =>
      '시장가는 빨리 사고팔 때, 지정가는 원하는 가격을 정할 때 써요. 둘 다 장단점이 있으니 수수료까지 보고 고르면 돼요. 먼저 이름을 알려 줄래요?',
    31 =>
      '저는 ${_playerController.text.trim()}예요. 멋져 보이는 것보다, 제가 왜 샀는지 제 말로 설명해 보고 싶어요.',
    32 => '좋아요. 첫 번째로 어떤 걸 연습해 보고 싶어요?',
    33 => _traitResponse,
    34 => '선생님은 컴퓨터 옆에 작은 주문표를 놓았다. 이제 직접 매수와 매도를 해 볼 시간이었다.',
    35 => '주문 버튼을 누르기 전에, 오늘부터 지킬 약속 하나만 골라 볼까요?',
    36 => _lessonRuleResponse,
    37 => '좋아요. 이제 교실 컴퓨터로 실제 주문 화면을 연습할 거예요. 그 전에 투자노트 표지에 붙일 이름도 하나 정해 볼까요?',
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
    if (_beat == 18) {
      unawaited(_travelToAcademy());
      return;
    }
    setState(() => _beat += 1);
  }

  Future<void> _travelToAcademy() async {
    if (_isTraveling) return;
    setState(() => _isTraveling = true);
    await Future<void>.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    setState(() {
      _isTraveling = false;
      _beat = 19;
    });
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
      _creationProgress = const WorldLoadProgress(0.02, '투자연구소 정보를 정리하는 중…');
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
        (progress) {
          if (mounted) setState(() => _creationProgress = progress);
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
    final isNameEntry = _beat == 30 || _beat == 38;
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
              : _isAcademyReceptionistBeat
              ? 'assets/images/character_academy_receptionist_v1.png'
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
                    alignment:
                        _isAcademyTeacherBeat || _isAcademyReceptionistBeat
                        ? Alignment.bottomCenter
                        : _characterAlignment,
                    characterKey: _isAcademyTeacherBeat
                        ? const Key('academy-teacher-character')
                        : _isAcademyReceptionistBeat
                        ? const Key('academy-receptionist-character')
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
                  child: _NewGamePreparationOverlay(
                    progress: _creationProgress,
                  ),
                ),
              if (_isTraveling)
                const Positioned.fill(child: _AcademyTravelOverlay()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogue(BuildContext context) {
    if (_beat == 10) return _introChoices();
    if (_beat == 22) return _academyRegistration();
    if (_beat == 28) return _academyTutorial();
    if (_beat == 30) return _nameEntry();
    if (_beat == 32) return _traitChoices();
    if (_beat == 35) return _familyChoices();
    if (_beat == 38) return _researchDeskName();

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

  Widget _academyRegistration() => _NovelDialogue(
    key: const ValueKey('academy-registration'),
    speaker: _speaker,
    line: _line,
    child: _AcademyTuitionPaymentPanel(
      paid: _tuitionPaid,
      onPay: () => setState(() => _tuitionPaid = true),
      onContinue: _next,
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
        const SizedBox(height: 16),
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
    _beat = 33;
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
    _beat = 36;
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
        const SizedBox(height: 16),
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

class _AcademyTravelOverlay extends StatelessWidget {
  const _AcademyTravelOverlay();

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('academy-travel-loading'),
    color: const Color(0xF2171B2A),
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 7,
                  color: _yellow,
                  backgroundColor: Color(0x33536A96),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '학원으로 이동 중…',
                key: Key('academy-travel-title'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 11),
              const Text(
                '우리 집  ·  버스 정류장  ·  투자학교',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFCCD4E6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 250,
                height: 6,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF394259),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const LinearProgressIndicator(
                  color: _coral,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AcademyTuitionPaymentPanel extends StatelessWidget {
  const _AcademyTuitionPaymentPanel({
    required this.paid,
    required this.onPay,
    required this.onContinue,
  });

  final bool paid;
  final VoidCallback onPay;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AnimatedContainer(
        key: const Key('academy-tuition-payment-card'),
        duration: const Duration(milliseconds: 320),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: paid ? const Color(0xFFE9F8EF) : const Color(0xFFFFF4D8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: paid ? const Color(0xFF78BE91) : const Color(0xFFE5C98E),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  paid ? Icons.receipt_long_rounded : Icons.account_balance,
                  color: paid
                      ? const Color(0xFF258257)
                      : const Color(0xFF536A96),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    paid ? '등록비 결제 완료' : '아빠 통장 · 등록비 결제',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (paid)
                  const Text(
                    '-1,000,000원',
                    key: Key('academy-tuition-debit'),
                    style: TextStyle(
                      color: Color(0xFFC53F4B),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFeatures: _marketNumberFeatures,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                const Text(
                  '아빠 통장',
                  style: TextStyle(
                    color: Color(0xFF697386),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (paid)
                  TweenAnimationBuilder<double>(
                    key: const Key('academy-father-balance-animation'),
                    tween: Tween(begin: 1000000, end: 0),
                    duration: const Duration(milliseconds: 850),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Text(
                      '${_money(value.round())}원',
                      style: const TextStyle(
                        color: Color(0xFFC53F4B),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        fontFeatures: _marketNumberFeatures,
                      ),
                    ),
                  )
                else
                  const Text(
                    '1,000,000원',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      fontFeatures: _marketNumberFeatures,
                    ),
                  ),
              ],
            ),
            const Divider(height: 17),
            const Row(
              children: [
                Text(
                  '내 교육용 투자금',
                  style: TextStyle(
                    color: Color(0xFF697386),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Spacer(),
                Text(
                  '10,000원 그대로',
                  key: Key('academy-investment-cash-preserved'),
                  style: TextStyle(
                    color: Color(0xFF258257),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (paid) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    '나중에 갚을 학원비',
                    style: TextStyle(
                      color: Color(0xFF697386),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '+1,000,000원 채무',
                    key: Key('academy-tuition-debt-created'),
                    style: TextStyle(
                      color: Color(0xFF8F5B25),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 10),
      _NovelNextButton(
        key: Key(
          paid ? 'academy-registration-continue' : 'academy-tuition-pay-button',
        ),
        label: paid ? '영수증 받고 접수 마치기' : '등록비 1,000,000원 결제',
        enabled: true,
        onTap: paid ? onContinue : onPay,
      ),
    ],
  );
}

class _NewGamePreparationOverlay extends StatelessWidget {
  const _NewGamePreparationOverlay({required this.progress});

  final WorldLoadProgress progress;

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
                    progress.label,
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
                LinearProgressIndicator(
                  key: const Key('new-game-preparation-progress'),
                  value: progress.fraction,
                  minHeight: 9,
                  backgroundColor: const Color(0xFFE8E1D1),
                  color: const Color(0xFFFFA45F),
                  borderRadius: BorderRadius.circular(99),
                ),
                const SizedBox(height: 10),
                Text(
                  '${(progress.fraction * 100).round()}%',
                  key: const Key('new-game-preparation-percent'),
                  style: const TextStyle(
                    color: Color(0xFF536A96),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '2000~2026 전체 세계를 만들며 기기에 따라 약 1분 걸릴 수 있어요.\n'
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
