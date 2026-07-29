part of 'main.dart';

const _onboardingBeatCount = 51;
const _computerRepairBeat = 5;
const _introChoiceBeat = 20;
const _academyTravelDepartureBeat = 31;
const _academyRegistrationBeat = 34;
const _playerNameBeat = 37;
const _traitChoiceBeat = 44;
const _familyChoiceBeat = 47;
const _companyNameBeat = 50;
const _storyCharacterBottomInset = 122.0;
const _storyCharacterHeightFactor = 0.78;
const _storyCharacterAspectRatio = 2 / 3;

void _playStoryFeedback({bool strong = false}) {
  if (strong) {
    unawaited(HapticFeedback.mediumImpact());
  } else {
    unawaited(HapticFeedback.selectionClick());
  }
  unawaited(SystemSound.play(SystemSoundType.click));
}

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
  static const _repairGoalLabels = <String, String>{
    'power-cord': '전원선 찾기',
    'screwdriver': '드라이버 빌리기',
    'keyboard': '키보드 협상',
    'modem': '모뎀 연결',
    'parts': '부품 구분',
  };

  final _playerController = TextEditingController();
  final _companyController = TextEditingController();
  final Set<String> _completedRepairGoals = <String>{};
  final List<String> _dialogueHistory = <String>[];
  int _beat = 0;
  String _repairArea = 'small-room';
  String? _activeRepairGoal;
  String? _introChoice;
  StoryTrait? _trait;
  FamilyRule? _familyRule;
  bool _isCreating = false;
  bool _isTraveling = false;
  bool _tuitionPaid = false;
  bool _quickSetup = false;
  Timer? _travelTimer;
  String _repairMessage = '좋아. 전원선부터 부품까지, 쓸 수 있는 건 내가 직접 골라 볼 거야.';  WorldLoadProgress _creationProgress = const WorldLoadProgress(
    0.02,
    '투자연구소 정보를 정리하는 중…',
  );

  @override
  void dispose() {
    _travelTimer?.cancel();
    _playerController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  String get _background {
    if (_beat == _computerRepairBeat) {
      return switch (_repairArea) {
        'living-room' =>
          'assets/images/bg_prologue_repair_living_room_keyboard_1999_portrait_cartoon_v6.png',
        'kitchen' =>
          'assets/images/bg_prologue_repair_kitchen_modem_1999_portrait_cartoon_v6.png',
        _ =>
          'assets/images/bg_prologue_small_room_repair_1999_portrait_cartoon_v6.png',
      };
    }
    return switch (_beat) {
      <= 4 =>
        'assets/images/bg_prologue_small_room_arrival_1999_portrait_cartoon_v6.png',
      <= 7 =>
        'assets/images/bg_prologue_small_room_repair_1999_portrait_cartoon_v6.png',
      <= 10 =>
        'assets/images/bg_prologue_living_room_tv_1999_portrait_cartoon_v6.png',
      11 =>
        'assets/images/bg_prologue_small_room_newspaper_1999_portrait_cartoon_v6.png',
      <= 13 =>
        'assets/images/bg_prologue_living_room_tv_1999_portrait_cartoon_v6.png',
      <= 21 =>
        'assets/images/bg_prologue_living_room_new_year_2000_portrait_cartoon_v6.png',
      <= 25 =>
        'assets/images/bg_prologue_public_class_2000_portrait_cartoon_v6.png',
      <= 30 =>
        'assets/images/bg_prologue_living_room_family_registration_2000_portrait_cartoon_v6.png',
      31 =>
        'assets/images/bg_prologue_small_room_departure_2000_portrait_cartoon_v6.png',
      <= 33 =>
        'assets/images/bg_prologue_academy_exterior_2000_portrait_cartoon_v6.png',
      34 =>
        'assets/images/bg_prologue_academy_reception_2000_portrait_cartoon_v6.png',
      <= 39 =>
        'assets/images/bg_prologue_academy_classroom_welcome_2000_portrait_cartoon_v6.png',
      <= 45 =>
        'assets/images/bg_prologue_academy_classroom_lesson_2000_portrait_cartoon_v6.png',
      _ =>
        'assets/images/bg_prologue_academy_classroom_order_practice_2000_portrait_cartoon_v6.png',
    };
  }

  String get _location {
    if (_beat == _computerRepairBeat) {
      return switch (_repairArea) {
        'living-room' => '거실 · 누나의 키보드',
        'kitchen' => '부엌 · 유선전화와 모뎀',
        _ => '작은방 · 아버지 공구와 부품',
      };
    }
    return switch (_beat) {
      <= 4 => '재개발 임대아파트 · 작은방 입구',
      <= 7 => '재개발 임대아파트 · 작은방 수리 책상',
      <= 10 => '거실 · TV 앞',
      11 => '작은방 · 컴퓨터 밑 신문',
      <= 13 => '거실 · 투자학교 광고',
      <= 21 => '우리 집 · 설날 거실',
      <= 25 => '오래된 상가 3층 · 무료 공개수업',
      <= 30 => '우리 집 거실 · 가족 등록회의',
      31 => '작은방 · 첫 등교 준비',
      <= 33 => '새천년 청소년 투자학교 · 정문',
      34 => '새천년 청소년 투자학교 · 접수대',
      <= 39 => '새천년 청소년 투자학교 · 10대 입문반',
      <= 45 => '새천년 청소년 투자학교 · 가격 수업',
      _ => '새천년 청소년 투자학교 · 주문 실습',
    };
  }

  String get _dateLabel => switch (_beat) {
    <= 13 => '1999.12.31  ·  20:50',
    <= 21 => '2000.01.01  ·  새해 첫날',
    <= 25 => '2000년 1월  ·  무료 공개수업',
    <= 30 => '공개수업 날  ·  점심 무렵',
    31 => '2000년 1월  ·  첫 등교 아침',
    <= 35 => '2000년 1월  ·  첫 등교',
    _ => '2000년 1월  ·  첫 수업',
  };

  String? get _character {
    if (_beat == _computerRepairBeat) return _repairCharacter;
    return switch (_beat) {
      1 => FamilyPortraitAssets.pose(
        FamilyPortraitAssets.mother,
        FamilyPortraitPose.action,
      ),
      27 => FamilyPortraitAssets.pose(
        FamilyPortraitAssets.mother,
        FamilyPortraitPose.neutral,
      ),
      30 => FamilyPortraitAssets.pose(
        FamilyPortraitAssets.mother,
        FamilyPortraitPose.concerned,
      ),
      2 || 12 || 31 || 38 || 48 => FamilyPortraitAssets.pose(
        FamilyPortraitAssets.hero,
        FamilyPortraitPose.action,
      ),
      15 => FamilyPortraitAssets.pose(
        FamilyPortraitAssets.hero,
        FamilyPortraitPose.neutral,
      ),
      7 || 9 || 24 || 33 || 40 || 42 => FamilyPortraitAssets.pose(
        FamilyPortraitAssets.hero,
        FamilyPortraitPose.expressive,
      ),
      18 || 28 || 45 => FamilyPortraitAssets.pose(
        FamilyPortraitAssets.hero,
        FamilyPortraitPose.concerned,
      ),
      3 || 10 || 16 => FamilyPortraitAssets.pose(
        FamilyPortraitAssets.sister,
        FamilyPortraitPose.expressive,
      ),
      4 => FamilyPortraitAssets.pose(
        FamilyPortraitAssets.father,
        FamilyPortraitPose.action,
      ),
      13 || 29 => FamilyPortraitAssets.pose(
        FamilyPortraitAssets.father,
        FamilyPortraitPose.concerned,
      ),
      17 => FamilyPortraitAssets.pose(
        FamilyPortraitAssets.grandfather,
        FamilyPortraitPose.expressive,
      ),
      19 || 20 || 21 => FamilyPortraitAssets.pose(
        FamilyPortraitAssets.grandfather,
        FamilyPortraitPose.action,
      ),
      _ => null,
    };
  }
  bool get _isAcademyTeacherBeat =>
      _beat == 23 ||
      _beat == 25 ||
      _beat == 36 ||
      _beat == 37 ||
      _beat == 39 ||
      _beat == 41 ||
      _beat == 43 ||
      _beat == 44 ||
      _beat == 47 ||
      _beat == 49;
  bool get _isAcademyReceptionistBeat => _beat == _academyRegistrationBeat;

  String get _teacherPoseAsset => switch (_beat) {
    23 || 37 || 39 || 43 => 'assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png',
    25 || 41 || 49 => 'assets/images/주식선생님/23_포즈2_주인공그림체_공통슬롯_투명.png',
    44 || 47 => 'assets/images/주식선생님/25_포즈4_주인공그림체_공통슬롯_투명.png',
    36 || 48 || 50 => 'assets/images/주식선생님/24_포즈3_주인공그림체_공통슬롯_투명.png',
    _ => 'assets/images/주식선생님/26_포즈5_주인공그림체_공통슬롯_투명.png',
  };

  bool get _isNarration =>
      _beat == 0 ||
      _beat == 6 ||
      _beat == 8 ||
      _beat == 11 ||
      _beat == 14 ||
      _beat == 22 ||
      _beat == 26 ||
      _beat == 32 ||
      _beat == 35 ||
      _beat == 46 ||
      _beat == 50;

  String get _speaker => switch (_beat) {
    0 || 6 || 8 || 11 || 14 || 22 || 26 || 32 || 35 || 46 || 50 => '이야기',
    1 || 27 || 30 => '엄마',
    2 ||
    7 ||
    9 ||
    12 ||
    15 ||
    18 ||
    24 ||
    28 ||
    31 ||
    33 ||
    38 ||
    40 ||
    42 ||
    45 ||
    48 =>
      _playerController.text.trim().isEmpty
          ? '나'
          : _playerController.text.trim(),
    3 || 10 || 16 => '누나',
    4 || 13 || 29 => '아빠',
    5 => _repairSpeaker,
    17 || 19 || 20 || 21 => '외할아버지',
    34 => '투자학교 접수원',
    23 ||
    25 ||
    36 ||
    37 ||
    39 ||
    41 ||
    43 ||
    44 ||
    47 ||
    49 => '한서윤 선생님',
    _ => '이야기',
  };
  String get _line => switch (_beat) {
    0 =>
      '드르륵. 쿵. 현관문 밖에서 본체가 계단을 긁었다. 나는 검은 매직으로 ‘폐기’라고 적힌 베이지색 컴퓨터를 두 팔로 안고 작은방까지 끌고 들어왔다.',
    1 => '그거 당장 내다 버려. 바퀴벌레 나오면 너랑 같이 재운다.',
    2 => '나보다 밥 덜 먹잖아.',
    3 => '재벌 회장님, 첫 자산이 쓰레기야?',
    4 => '전원부도 없고 메모리도 뽑혔네. 공구는 빌려줄 테니, 없는 건 네가 찾아.',
    5 => _repairMessage,
    6 =>
      '마지막 나사를 조이고 전원을 눌렀다. 팬이 청소기처럼 울고 화면이 두 번 흔들렸다. 초록빛 한가운데에 ‘16384 KB OK’가 떠올랐다.',
    7 => '봐. 안 죽었잖아. 시끄러운 건 다음에 고치면 돼.',
    8 =>
      '거실 TV의 연말 드라마에서는 아무도 거들떠보지 않던 작은 회사를 먼저 알아본 투자자가 넓은 회의실의 주인이 됐다. 전화 한 통마다 큰돈이 움직였다.',
    9 => '나도 저거 할래. 남들이 모르는 좋은 회사부터 찾는 거.',
    10 => '뭘, 엔딩에 서 있기? 컴퓨터 하나 살렸다고 회사도 살리게?',
    11 =>
      '모뎀이 삐 소리를 내자 부엌 전화가 끊겼다. 엄마가 선을 뽑는 바람에 인터넷 대신 컴퓨터 밑의 헌 신문이 나왔다. 구석에는 ‘새천년 청소년 투자학교’ 광고가 실려 있었다.',
    12 => '나 여기 갈래. 공개수업은 공짜래.',
    13 => '공짜는 첫 줄까지고, 입문반은 백만 원이야. 영 하나를 통째로 건너뛰었네.',
    14 =>
      '새해 첫날, 외할아버지가 귤 봉지와 모서리를 투명테이프로 기운 장부를 들고 왔다. 나는 귤보다 먼저 허리를 폈다.',
    15 => '할아버지, 저 만 원만 빌려주세요.',
    16 => '돈 얘기 나오니까 존댓말도 나오네.',
    17 => '그 돈으로 뭐 하게?',
    18 => '십만 원으로 만들려고요. …방법은 지금부터 적을 거고요.',
    19 => '돈 달란 말은 빨랐네. 그런데 갚는 날짜는 왜 안 적혔지?',
    20 => '네가 할 수 있는 일 세 개만 골라 봐. 위험한 일과 남의 돈은 빼고.',
    21 => _introResponse,
    22 =>
      '며칠 뒤 무료 공개수업은 오래된 상가 3층에서 열렸다. 흔들리는 접이식 의자 사이에서 나는 가장 작았고, 손은 가장 빨랐다.',
    23 => '수업 시작도 안 했는데 손부터 들었네요. 질문 있어요?',
    24 => '좋은 회사 찾으면 무조건 벌어요?',
    25 =>
      '같은 전자사전도 만 원이면 사고 싶고, 십만 원이면 망설여지죠? 회사가 좋아도 산 가격이 다르면 결과도 달라져요.',
    26 =>
      '집으로 돌아오자 밥상에는 생활비 봉투, 아빠의 새 공구 전단, 누나 잡지 밑의 등록금 분납 안내서가 나란히 놓였다. 나는 입문반 수강료 백만 원을 손으로 가리지 않았다.',
    27 => '그래서, 뭐 배웠어? 광고 말고 네 장부부터 보여 줘.',
    28 => '비싼 거 알아. 공짜로 해 달라는 말도 안 할게. 서른 날만 줘. 십만 원짜리 계획부터 보여줄게.',
    29 =>
      '백만 원을 내면 새 공구는 미뤄야 해. 그래도 배우겠다면 내가 먼저 돈을 건다. 공짜는 아니다.',
    30 => '계좌는 내 이름, 비밀번호는 내 손. 넌 왜 사는지부터 설명해.',
    31 => '초대장, 장부, 연필 세 자루. 다 챙겼어. 이제 진짜 가는 거지?',
    32 =>
      '버스에서 내려 골목을 돌자 남색 문양이 붙은 투자학교가 보였다. 초등학생부터 고등학생까지 두꺼운 노트와 서류철을 들고 정문으로 모여들었다.',
    33 => '형, 누나들만 있는 줄 알았는데 나만 한 애도 있네. 내가 제일 작은 건 아니네.',
    34 => '보호자 서류 확인됐어요. 영수증에는 등록비와 맡긴 투자금을 따로 적어 드릴게요.',
    35 =>
      '등록비 영수증을 장부와 다른 칸에 끼웠다. 교실 문을 열자 두꺼운 CRT 모니터, 가격표 두 장, 빈 주문표가 교탁 위에 놓여 있었다.',
    36 => '안녕하세요, 한서윤입니다. 그런데 저기 손 든 학생. 이름보다 질문이 먼저인가요?',
    37 => '질문은 환영이에요. 그래도 서로 부를 이름부터 적어 볼까요?',
    38 => '저는 ${_playerController.text.trim()}예요. 질문은 몇 개까지 해도 돼요?',
    39 => '끝까지 들을 수 있는 만큼요. 같은 전자사전에 만 원과 십만 원 가격표가 붙어 있어요. 어느 쪽을 살래요?',
    40 => '만 원짜리요. 그런데 그 회사가 좋은지는 아직 모르잖아요?',
    41 => '바로 그거예요. 회사와 가격을 따로 본 다음, 사기로 정했을 때 쓰는 게 매수 주문이에요.',
    42 => '그럼 제가 사고 싶은 가격도 정할 수 있어요?',
    43 => '정할 수 있어요. 원하는 가격에 줄을 서는 지정가와, 지금 나온 가격부터 사는 시장가를 주문표에서 비교해 봐요.',
    44 => '첫 회사를 볼 때 네 눈이 어디부터 가는지 골라 볼까요?',
    45 => _traitResponse,
    46 =>
      '한서윤 선생님이 컴퓨터 옆에 주문표를 놓았다. 그때 장부 사이에서 엄마가 접어 준 가족 약속 쪽지가 툭 떨어졌다.',
    47 => '가족이 정해 준 약속이 있네요. 오늘 주문에 들고 갈 한 줄은 무엇인가요?',
    48 => _lessonRuleResponse,
    49 => '좋아요. 마지막으로 한 달 동안 회사 하나를 볼 관찰팀을 만들어요. 혼자여도 팀 이름은 있어도 돼요.',
    _ =>
      '빈 관찰 노트 표지 한가운데에 두 줄을 그었다. 첫 줄에는 내 이름, 둘째 줄에는 오늘부터 키워 갈 투자연구소 이름이 들어간다.',
  };

  String get _introResponse => switch (_introChoice) {
    'computer' =>
      '좋다. 남의 시간을 빌렸으면 그것도 빚이지. 이 만 원은 네게 맡긴다. 장부 첫 줄부터 써라.',
    'y2k' =>
      '좋다. 위험한 부품은 손대지 말고, 번 돈 옆에 쓴 시간도 적어라. 이 만 원은 네게 맡긴다.',
    'stocks' =>
      '좋다. 상금과 투자금은 섞지 마라. 이 만 원은 네게 맡긴다. 다음엔 말 말고 숫자를 들고 와.',
    _ => '',
  };

  String get _traitResponse => switch (_trait) {
    StoryTrait.stability => '엄마 돈부터 안 잃는 법이요. 잃으면 다음 질문도 못 하잖아요.',
    StoryTrait.innovation => '사람들이 새로 줄 서서 사는 물건이요. 그런 건 누가 만드는지 보고 싶어요.',
    StoryTrait.analysis => '같은 회사인데 어제랑 오늘 값이 다른 이유요. 숫자가 혼자 움직이진 않잖아요.',
    StoryTrait.control => '한 주만 사도 회사에 말할 수 있어요? 주인이라면서요.',
    null => '',
  };

  String get _lessonRuleResponse => switch (_familyRule) {
    FamilyRule.reportLosses => '손해가 나도 숨기지 않고 쓸게요. 지우면 왜 틀렸는지도 없어지니까.',
    FamilyRule.noHotTips => '누가 좋다고 해도 바로 안 살게요. 제 이유가 없으면 제 주문도 아니잖아요.',
    FamilyRule.keepCash => '한 번에 다 안 쓸게요. 다음에 다시 고를 돈은 남겨 둬야 하니까.',
    null => '',
  };

  String get _repairSpeaker => switch (_activeRepairGoal) {
    'power-cord' || 'screwdriver' || 'parts' => '아빠',
    'keyboard' => '누나',
    'modem' => '엄마',
    _ => _playerController.text.trim().isEmpty
        ? '나'
        : _playerController.text.trim(),
  };

  String? get _repairCharacter => switch (_activeRepairGoal) {
    'power-cord' || 'screwdriver' => FamilyPortraitAssets.pose(
      FamilyPortraitAssets.father,
      FamilyPortraitPose.action,
    ),
    'parts' => FamilyPortraitAssets.pose(
      FamilyPortraitAssets.father,
      FamilyPortraitPose.concerned,
    ),
    'keyboard' => FamilyPortraitAssets.pose(
      FamilyPortraitAssets.sister,
      FamilyPortraitPose.expressive,
    ),
    'modem' => FamilyPortraitAssets.pose(
      FamilyPortraitAssets.mother,
      FamilyPortraitPose.action,
    ),
    _ => FamilyPortraitAssets.pose(
      FamilyPortraitAssets.hero,
      FamilyPortraitPose.action,
    ),
  };

  String? get _stageDirection => switch (_beat) {
    1 => '어머니가 고무장갑 낀 손으로 신문지를 바닥에 펼쳤다.',
    2 => '나는 본체를 들어 올리려다 무게를 못 이기고 다시 내려놨다.',
    3 => '누나는 잡지 위로 눈만 들었다. 해진 민소매 면티와 돌핀팬츠 차림이었다.',
    4 => '아버지는 웃지 않고 본체 뒤쪽의 탄 냄새부터 맡았다.',
    5 => switch (_activeRepairGoal) {
      'power-cord' => '책상 밑에서 전원선 두 개를 꺼냈다.',
      'screwdriver' => '공구함에는 크기가 다른 십자드라이버가 있었다.',
      'keyboard' => '누나가 키보드를 등 뒤로 감췄다.',
      'modem' => '부엌 수화기에서는 아직 통화 소리가 났다.',
      'parts' => '아버지가 부품 다섯 개를 쟁반에 늘어놓았다.',
      _ => '작은방 바닥에는 부품과 공구가 뒤섞여 있었다.',
    },
    7 => '초록 글씨가 뜨자 나는 모니터 코앞까지 붙었다.',
    9 => '엔딩 음악이 흐르는데도 나는 TV 앞에서 비키지 않았다.',
    10 => '누나가 리모컨으로 화면 속 넥타이 차림 남자를 가리켰다.',
    12 => '나는 광고의 무료 수업 줄만 손가락으로 가렸다.',
    13 => '아버지의 손가락이 수강료 마지막 영에서 멈췄다.',
    15 => '나는 귤 봉지보다 장부 가방을 먼저 봤다.',
    16 => '누나가 귤껍질을 길게 늘어뜨리며 웃었다.',
    17 => '외할아버지는 웃었지만 지갑은 꺼내지 않았다.',
    18 => '입이 먼저 움직였다. 십만 원은 말하고 나서야 커 보였다.',
    19 => '외할아버지가 닳은 장부를 펴서 내 쪽으로 밀었다.',
    20 => '짧아진 연필 한 자루가 빈 장부 칸 위에 놓였다.',
    21 => '외할아버지가 내 답을 장부 첫 줄에 그대로 받아 적었다.',
    23 => '출석부도 펴기 전, 내 손이 먼저 올라갔다.',
    24 => '뒤쪽에서 웃음이 났다. 나는 손을 내리지 않았다.',
    25 => '선생님은 같은 전자사전 아래에 서로 다른 가격표를 붙였다.',
    27 => '어머니는 생활비 봉투를 세면서 장부부터 턱으로 가리켰다.',
    28 => '나는 신발도 벗기 전에 삐뚤어진 표를 밥상 위에 폈다.',
    29 => '아버지는 새 공구 전단을 접어 공구함 밑에 넣었다.',
    30 => '어머니가 가족 규칙 칸에 한 줄만 크게 적었다.',
    31 => '연필이 불안해 두 자루를 더 챙겼다.',
    33 => '학생들의 두꺼운 서류철을 보고 가방끈을 고쳐 멨다.',
    36 => '선생님은 출석부 대신 아직 들려 있는 내 손을 먼저 봤다.',
    38 => '이름을 적자마자 나는 다시 손을 들었다.',
    39 => '선생님이 같은 전자사전에 두 가격표를 붙였다.',
    40 => '나는 십만 원 가격표를 뒤집어 보고 고개를 저었다.',
    41 => '선생님은 칠판의 ‘회사’와 ‘가격’ 사이에 줄을 그었다.',
    42 => '나는 빈 주문표의 가격 칸을 손가락으로 짚었다.',
    45 => '내가 고른 자료 쪽으로 의자를 바짝 당겼다.',
    48 => '나는 엄마가 적어 준 한 줄을 소리 내어 다시 읽었다.',
    49 => '선생님이 빈 관찰 노트 표지를 한 장씩 나눠 줬다.',
    _ => null,
  };

  String get _historyLine {
    final direction = _stageDirection?.trim();
    if (direction == null || direction.isEmpty) return _line;
    return '$direction\n$_line';
  }
  void _rememberCurrentLine() {
    final entry = '$_speaker\n$_historyLine';
    if (_dialogueHistory.isEmpty || _dialogueHistory.last != entry) {
      _dialogueHistory.add(entry);
    }
  }

  void _next() {
    FocusManager.instance.primaryFocus?.unfocus();
    _rememberCurrentLine();
    _playStoryFeedback();
    if (_beat == _academyTravelDepartureBeat) {
      _travelToAcademy();
      return;
    }
    if (_quickSetup && _beat == _playerNameBeat) {
      setState(() => _beat = _companyNameBeat);
      return;
    }
    setState(() => _beat += 1);
  }

  void _travelToAcademy() {
    if (_isTraveling) return;
    setState(() => _isTraveling = true);
    _travelTimer?.cancel();
    _travelTimer = Timer(
      const Duration(milliseconds: 2600),
      _finishAcademyTravel,
    );
  }

  void _finishAcademyTravel() {
    _travelTimer?.cancel();
    _travelTimer = null;
    if (!mounted || !_isTraveling) return;
    _playStoryFeedback(strong: true);
    setState(() {
      _isTraveling = false;
      _beat = 32;
    });
  }

  void _completeRepairGoal(String id) {
    if (_completedRepairGoals.contains(id)) return;
    _rememberCurrentLine();
    final message = switch (id) {
      'power-cord' =>
        '타는 냄새 맡고 싶으면 국에 코를 박아. 전기는 확인부터. 멀쩡한 선을 다시 골라.',
      'screwdriver' =>
        '십자라고 다 같은 건 아니야. 나사에 맞는 걸 대 보고, 손잡이 끝까지 눌러.',
      'keyboard' =>
        '부자 될 때까지는 너무 길고. 설거지 두 번. 싫으면 키보드도 안 가.',
      'modem' =>
        '전화 끝나기 전엔 꽂지 마. 밤새 연결하면 컴퓨터보다 네가 먼저 밖에 나가.',
      'parts' =>
        '탄 냄새 나는 건 내려놔. 먼지만 쌓인 것과 망가진 건 다르니까 다시 봐.',
      _ => _repairMessage,
    };
    _playStoryFeedback();
    setState(() {
      _activeRepairGoal = id;
      _completedRepairGoals.add(id);
      _repairMessage = message;
      _repairArea = switch (id) {
        'keyboard' => 'living-room',
        'modem' => 'kitchen',
        _ => 'small-room',
      };
    });
  }
  void _powerOnRepairedComputer() {
    if (_completedRepairGoals.length != _repairGoalLabels.length) return;
    _rememberCurrentLine();
    _playStoryFeedback(strong: true);
    setState(() => _beat = 6);
  }

  Future<void> _showBacklog() async {
    _playStoryFeedback();
    final entries = <String>[..._dialogueHistory];
    final current = '$_speaker\n$_historyLine';
    if (entries.isEmpty || entries.last != current) entries.add(current);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF8E7),
      builder: (context) => SizedBox(
        key: const Key('story-backlog-sheet'),
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: _coral),
                  SizedBox(width: 8),
                  Text(
                    '지나간 대사',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Divider(height: 18),
                itemBuilder: (context, index) {
                  final parts = entries[index].split('\n');
                  final speaker = parts.first;
                  final line = parts.skip(1).join('\n');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        speaker,
                        style: const TextStyle(
                          color: _coral,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        line,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSkipDialog() async {
    _playStoryFeedback();
    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('story-skip-dialog'),
        title: const Text('프롤로그를 건너뛸까요?'),
        content: const Text(
          '컴퓨터 수리와 가족 이야기를 건너뛰고 이름 설정으로 이동합니다. '
          '기본 원칙은 숫자 분석·손실 기록으로 저장됩니다.',
        ),
        actions: [
          TextButton(
            key: const Key('story-skip-cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속 보기'),
          ),
          FilledButton(
            key: const Key('story-skip-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('건너뛰기'),
          ),
        ],
      ),
    );
    if (!mounted || shouldSkip != true) return;
    _travelTimer?.cancel();
    _playStoryFeedback(strong: true);
    setState(() {
      _isTraveling = false;
      _tuitionPaid = true;
      _introChoice ??= 'computer';
      _trait ??= StoryTrait.analysis;
      _familyRule ??= FamilyRule.reportLosses;
      _quickSetup = true;
      _beat = _playerController.text.trim().isEmpty
          ? _playerNameBeat
          : _companyNameBeat;
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
    final isNameEntry = _beat == _playerNameBeat || _beat == _companyNameBeat;
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

              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 54, right: 10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xB8292B3A),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0x55FFFFFF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: const Key('story-backlog-button'),
                            tooltip: '지난 대사',
                            visualDensity: VisualDensity.compact,
                            color: Colors.white,
                            onPressed: _showBacklog,
                            icon: const Icon(Icons.history_rounded, size: 19),
                          ),
                          IconButton(
                            key: const Key('story-skip-button'),
                            tooltip: '프롤로그 건너뛰기',
                            visualDensity: VisualDensity.compact,
                            color: _yellow,
                            onPressed: _showSkipDialog,
                            icon: const Icon(
                              Icons.fast_forward_rounded,
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (sceneCharacterAsset != null)
                Positioned.fill(
                  bottom: _storyCharacterBottomInset,
                  child: _OnboardingCharacterSlot(
                    key: const Key('story-character-stage-slot'),
                    asset: sceneCharacterAsset,
                    alignment: Alignment.bottomCenter,
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
                Positioned.fill(
                  child: _AcademyTravelOverlay(onSkip: _finishAcademyTravel),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogue(BuildContext context) {
    if (_beat == _computerRepairBeat) return _computerRepair();
    if (_beat == _introChoiceBeat) return _introChoices();
    if (_beat == _academyRegistrationBeat) return _academyRegistration();
    if (_beat == 43) return _academyTutorial();
    if (_beat == _playerNameBeat) return _nameEntry();
    if (_beat == _traitChoiceBeat) return _traitChoices();
    if (_beat == _familyChoiceBeat) return _familyChoices();
    if (_beat == _companyNameBeat) return _researchDeskName();

    return _NovelDialogue(
      key: ValueKey(_beat),
      speaker: _speaker,
      line: _line,
      stageDirection: _stageDirection,
      narration: _isNarration,
      onContinue: _next,
    );
  }

  Widget _computerRepair() => _NovelDialogue(
    key: ValueKey(
      'computer-repair-${_completedRepairGoals.length}-$_repairMessage',
    ),
    speaker: _speaker,
    line: _line,
    stageDirection: _stageDirection,
    child: Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 7) / 2;
            return Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _repairGoalLabels.entries
                  .map(
                    (entry) => SizedBox(
                      width: width,
                      child: _RepairGoalButton(
                        key: ValueKey('repair-goal-${entry.key}'),
                        label: entry.value,
                        completed: _completedRepairGoals.contains(entry.key),
                        onTap: () => _completeRepairGoal(entry.key),
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          key: const Key('repair-progress'),
          value: _completedRepairGoals.length / _repairGoalLabels.length,
          minHeight: 7,
          borderRadius: BorderRadius.circular(99),
          color: const Color(0xFF54A86B),
          backgroundColor: const Color(0xFFD9D6CC),
        ),
        const SizedBox(height: 10),
        _NovelNextButton(
          key: const Key('repair-power-on'),
          label: _completedRepairGoals.length == _repairGoalLabels.length
              ? '전원 버튼 누르기'
              : '${_completedRepairGoals.length}/5 · 부품을 더 찾기',
          enabled: _completedRepairGoals.length == _repairGoalLabels.length,
          onTap: _powerOnRepairedComputer,
        ),
      ],
    ),
  );

  Widget _introChoices() => _NovelDialogue(
    key: const ValueKey('intro-choice'),
    speaker: _speaker,
    line: _line,
    stageDirection: _stageDirection,
    choices: [
      _NovelChoice(
        key: const Key('story-intro-computer'),
        label: '누나와 컴퓨터 시간을 나누고 조사한 걸 적을게요',
        onTap: () => _chooseIntroChoice('computer'),
      ),
      _NovelChoice(
        key: const Key('story-intro-y2k'),
        label: '아빠 옆에서 부품을 나누고 확인표를 쓸게요',
        onTap: () => _chooseIntroChoice('y2k'),
      ),
      _NovelChoice(
        key: const Key('story-intro-stocks'),
        label: '축제 상금과 조사 시간을 장부에 따로 쓸게요',
        onTap: () => _chooseIntroChoice('stocks'),
      ),
    ],
  );

  void _chooseIntroChoice(String choice) {
    _rememberCurrentLine();
    _playStoryFeedback();
    setState(() {
      _introChoice = choice;
      _beat = _introChoiceBeat + 1;
    });
  }

  Widget _academyTutorial() => _NovelDialogue(
    key: const ValueKey('academy-tutorial'),
    speaker: _speaker,
    line: _line,
    stageDirection: _stageDirection,
    child: Column(
      children: [
        const _AcademyLessonRow(
          number: '1',
          title: '지정가',
          body: '원하는 가격에 주문을 놓고 기다린다',
        ),
        const SizedBox(height: 6),
        const _AcademyLessonRow(
          number: '2',
          title: '시장가',
          body: '지금 나온 가격부터 바로 체결한다',
        ),
        const SizedBox(height: 6),
        const _AcademyLessonRow(
          number: '3',
          title: '주문 전 확인',
          body: '가격 · 수량 · 수수료는 화면에서 직접 확인한다',
        ),
        const SizedBox(height: 10),
        _NovelNextButton(
          key: const Key('academy-tutorial-continue'),
          label: '두 주문 비교했어요',
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
    stageDirection: _stageDirection,
    child: _AcademyTuitionPaymentPanel(
      paid: _tuitionPaid,
      onPay: () {
        _playStoryFeedback(strong: true);
        setState(() => _tuitionPaid = true);
      },
      onContinue: _next,
    ),
  );

  Widget _nameEntry() => _NovelDialogue(
    key: const ValueKey('name-entry'),
    speaker: _speaker,
    line: _line,
    stageDirection: _stageDirection,
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
    stageDirection: _stageDirection,
    choices: [
      _NovelChoice(
        key: const Key('story-trait-stability'),
        label: '엄마 돈부터 안 잃는 법',
        onTap: () => _chooseTrait(StoryTrait.stability),
      ),
      _NovelChoice(
        key: const Key('story-trait-innovation'),
        label: '사람들이 줄 서서 사는 물건',
        onTap: () => _chooseTrait(StoryTrait.innovation),
      ),
      _NovelChoice(
        key: const Key('story-trait-analysis'),
        label: '같은 회사 값이 매일 바뀌는 이유',
        onTap: () => _chooseTrait(StoryTrait.analysis),
      ),
      _NovelChoice(
        key: const Key('story-trait-control'),
        label: '한 주만 사도 회사에 말할 수 있는지',
        onTap: () => _chooseTrait(StoryTrait.control),
      ),
    ],
  );

  void _chooseTrait(StoryTrait trait) {
    _rememberCurrentLine();
    _playStoryFeedback();
    setState(() {
      _trait = trait;
      _beat = 45;
    });
  }

  Widget _familyChoices() => _NovelDialogue(
    key: const ValueKey('family-choice'),
    speaker: _speaker,
    line: _line,
    stageDirection: _stageDirection,
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

  void _chooseFamilyRule(FamilyRule rule) {
    _rememberCurrentLine();
    _playStoryFeedback();
    setState(() {
      _familyRule = rule;
      _beat = 48;
    });
  }

  Widget _researchDeskName() => _NovelDialogue(
    key: const ValueKey('desk-name'),
    speaker: _speaker,
    line: _line,
    stageDirection: _stageDirection,
    narration: true,
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
          label: '투자회사 이름을 정하고 주문 연습 시작',
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
  const _AcademyTravelOverlay({required this.onSkip});

  final VoidCallback onSkip;

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
              const SizedBox(height: 16),
              TextButton.icon(
                key: const Key('academy-travel-skip'),
                onPressed: onSkip,
                style: TextButton.styleFrom(foregroundColor: _yellow),
                icon: const Icon(Icons.fast_forward_rounded, size: 18),
                label: const Text(
                  '이동 장면 건너뛰기',
                  style: TextStyle(fontWeight: FontWeight.w900),
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
      key: const Key('story-background-image'),
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
      transitionBuilder: (child, animation) {
        final horizontalOffset = alignment.x < 0
            ? -0.08
            : alignment.x > 0
            ? 0.08
            : 0.0;
        final entrance = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: entrance,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(horizontalOffset, 0.02),
              end: Offset.zero,
            ).animate(entrance),
            child: child,
          ),
        );
      },
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
                key: const Key('story-character-image'),
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

class _NovelDialogue extends StatefulWidget {
  const _NovelDialogue({
    super.key,
    required this.speaker,
    required this.line,
    this.narration = false,
    this.stageDirection,
    this.onContinue,
    this.choices = const [],
    this.child,
  });

  final String speaker;
  final String line;
  final bool narration;
  final String? stageDirection;
  final VoidCallback? onContinue;
  final List<_NovelChoice> choices;
  final Widget? child;

  @override
  State<_NovelDialogue> createState() => _NovelDialogueState();
}

class _NovelDialogueState extends State<_NovelDialogue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _typingController;

  bool get _typingComplete => _typingController.isCompleted;

  Duration _typingDuration(String line) => Duration(
    milliseconds: math.min(1400, math.max(180, line.length * 14)).toInt(),
  );

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: _typingDuration(widget.line),
    )..addListener(() => setState(() {}));
    _typingController.forward();
  }

  @override
  void didUpdateWidget(covariant _NovelDialogue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line != widget.line) {
      _typingController
        ..duration = _typingDuration(widget.line)
        ..reset()
        ..forward();
    }
  }

  void _revealLine() {
    if (_typingComplete) return;
    _playStoryFeedback();
    _typingController.value = 1;
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleCharacters = _typingComplete
        ? widget.line.length
        : (widget.line.length * _typingController.value).floor();
    final visibleLine = widget.line.substring(
      0,
      math.min(visibleCharacters, widget.line.length),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _typingComplete ? null : _revealLine,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
        decoration: BoxDecoration(
          color: widget.narration
              ? const Color(0xEC272A37)
              : const Color(0xF7FFF9EA),
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
            if (!widget.narration)
              Transform.translate(
                offset: const Offset(0, -25),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _coral,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Color(0x4433405F), offset: Offset(0, 3)),
                    ],
                  ),
                  child: Text(
                    widget.speaker,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            if (!widget.narration) const SizedBox(height: 0),
            if (widget.stageDirection?.trim().isNotEmpty ?? false) ...[
              Text(
                widget.stageDirection!,
                key: const Key('story-stage-direction'),
                style: TextStyle(
                  color: widget.narration
                      ? const Color(0xFFCBD4E8)
                      : const Color(0xFF777268),
                  fontSize: 11,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
            ],            Semantics(

              liveRegion: true,
              label: widget.line,
              child: Text(
                visibleLine,
                key: const Key('story-line-text'),
                style: TextStyle(
                  color: widget.narration ? Colors.white : _ink,
                  fontSize: widget.narration ? 13 : 14,
                  height: 1.55,
                  fontWeight: widget.narration
                      ? FontWeight.w600
                      : FontWeight.w700,
                ),
              ),
            ),
            if (!_typingComplete) ...[
              const SizedBox(height: 8),
              Text(
                '탭하여 문장 펼치기',
                key: const Key('story-typewriter-hint'),
                style: TextStyle(
                  color: widget.narration
                      ? const Color(0xFFCBD4E8)
                      : const Color(0xFF8B877F),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (_typingComplete && widget.choices.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...widget.choices.map(
                (choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: choice,
                ),
              ),
            ],
            if (_typingComplete && widget.child != null) ...[
              const SizedBox(height: 12),
              widget.child!,
            ],
            if (_typingComplete && widget.onContinue != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('story-continue'),
                  onPressed: widget.onContinue,
                  label: Text(widget.narration ? '장면 계속' : '계속'),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  style: TextButton.styleFrom(
                    foregroundColor: widget.narration ? _yellow : _coral,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RepairGoalButton extends StatelessWidget {
  const _RepairGoalButton({
    super.key,
    required this.label,
    required this.completed,
    required this.onTap,
  });

  final String label;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: OutlinedButton.icon(
      onPressed: completed ? null : onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
        foregroundColor: _ink,
        disabledForegroundColor: const Color(0xFF258257),
        backgroundColor: completed
            ? const Color(0xFFE9F8EF)
            : const Color(0xEFFFFFFF),
        disabledBackgroundColor: const Color(0xFFE9F8EF),
        side: BorderSide(
          color: completed ? const Color(0xFF78BE91) : const Color(0xFFD8BE91),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
      icon: Icon(
        completed ? Icons.check_circle_rounded : Icons.search_rounded,
        size: 16,
      ),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
