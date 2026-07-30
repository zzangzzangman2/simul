part of 'main.dart';

const _onboardingBeatCount = 51;
const _policyBriefingBeat = 5;
const _introChoiceBeat = 20;
const _accountHallDepartureBeat = 31;
const _stateAccountActivationBeat = 34;
const _playerNameBeat = 37;
const _traitChoiceBeat = 44;
const _principleChoiceBeat = 47;
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
  static const _policyFileLabels = <String, String>{
    'industry': '수출산업',
    'population': '인구전망',
    'children': '보호아동',
    'capital': '국가계좌',
    'law': '특별법',
  };

  final _playerController = TextEditingController();
  final _companyController = TextEditingController();
  final Set<String> _reviewedPolicyFiles = <String>{};
  final List<String> _dialogueHistory = <String>[];
  int _beat = 0;
  String? _activePolicyFile;
  String? _introChoice;
  StoryTrait? _trait;
  FamilyRule? _familyRule;
  bool _isCreating = false;
  String? _creationError;
  bool _isTraveling = false;
  bool _stateAccountActivated = false;
  bool _quickSetup = false;
  Timer? _travelTimer;
  String _policyMessage = '보고서 다섯 권을 모두 확인해야 결재안을 완성할 수 있다.';
  WorldLoadProgress _creationProgress = const WorldLoadProgress(
    0.02,
    '제6기 국가계좌 정보를 정리하는 중…',
  );

  @override
  void dispose() {
    _travelTimer?.cancel();
    _playerController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  String get _background {
    return switch (_beat) {
      <= 4 =>
        'assets/images/historical_prologue/bg_blue_house_policy_room_1981_portrait_cartoon_v1.png',
      <= 13 =>
        'assets/images/historical_prologue/bg_blue_house_conference_1981_portrait_cartoon_v1.png',
      <= 16 =>
        'assets/images/historical_prologue/bg_future_development_orphanage_1982_portrait_cartoon_v1.png',
      <= 21 =>
        'assets/images/historical_prologue/bg_orphanage_records_room_1999_portrait_cartoon_v1.png',
      <= 25 =>
        'assets/images/historical_prologue/bg_orphanage_dormitory_1999_portrait_cartoon_v1.png',
      <= 30 =>
        'assets/images/historical_prologue/bg_orphanage_electronics_storage_2000_portrait_cartoon_v1.png',
      31 =>
        'assets/images/historical_prologue/bg_orphanage_dormitory_1999_portrait_cartoon_v1.png',
      <= 39 =>
        'assets/images/historical_prologue/bg_orphanage_account_hall_2000_portrait_cartoon_v1.png',
      _ =>
        'assets/images/historical_prologue/bg_orphanage_investment_room_2000_portrait_cartoon_v1.png',
    };
  }

  String get _location {
    return switch (_beat) {
      <= 4 => '청와대 · 정책실',
      <= 13 => '청와대 · 미래전략 심야회의',
      <= 16 => '국립 미래양성원 · 개원 기록',
      <= 21 => '국립 미래양성원 · 제3기록실',
      <= 25 => '국립 미래양성원 · 6기 기숙사',
      <= 30 => '국립 미래양성원 · 전자창고',
      31 => '6기 기숙사 · 계좌 개통일 아침',
      <= 39 => '국립 미래양성원 · 국가계좌 개통실',
      _ => '국립 미래양성원 · 제6기 투자실',
    };
  }

  String get _dateLabel => switch (_beat) {
    <= 13 => '1981.01.12  ·  23:40',
    <= 16 => '1982년  ·  미래양성계획 1기',
    <= 21 => '1999.12.31  ·  자정 직전',
    <= 31 => '2000.01.01  ·  새천년',
    <= 39 => '2000.01.02  ·  08:00',
    _ => '2000.01.02  ·  제6기 첫 수업',
  };

  String? get _character {
    return switch (_beat) {
      1 ||
      7 ||
      11 => 'assets/images/historical_prologue/character_seo_muntae_v1.png',
      2 ||
      12 => 'assets/images/historical_prologue/character_baek_gihyeon_v1.png',
      3 || 13 || 14 =>
        'assets/images/historical_prologue/character_jeon_dugwang_decree_cartoon_v2.png',
      4 => 'assets/images/historical_prologue/character_kang_incheol_v1.png',
      5 => _policyBriefingCharacter,
      8 || 15 => 'assets/images/historical_prologue/character_yoon_mira_v1.png',
      10 => 'assets/images/historical_prologue/character_jang_daesik_v1.png',
      18 ||
      23 ||
      28 ||
      33 => 'assets/images/historical_prologue/character_park_taesu_v1.png',
      19 || 21 || 24 || 29 || 31 || 38 || 40 || 42 || 45 || 48 =>
        'assets/images/historical_prologue/character_hero_age14_passbook_v1.png',
      25 || 27 =>
        'assets/images/historical_prologue/character_living_guide_oh_gyeongtae_v1.png',
      34 || 35 =>
        'assets/images/historical_prologue/character_state_account_officer_cha_eunjoo_v1.png',
      _ => null,
    };
  }

  bool get _isAcademyTeacherBeat =>
      _beat == 36 ||
      _beat == 37 ||
      _beat == 39 ||
      _beat == 41 ||
      _beat == 43 ||
      _beat == 44 ||
      _beat == 47 ||
      _beat == 49;
  bool get _isAcademyReceptionistBeat =>
      _beat == _stateAccountActivationBeat || _beat == 35;

  String get _teacherPoseAsset => switch (_beat) {
    37 || 39 || 43 => 'assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png',
    41 || 49 => 'assets/images/주식선생님/23_포즈2_주인공그림체_공통슬롯_투명.png',
    44 || 47 => 'assets/images/주식선생님/25_포즈4_주인공그림체_공통슬롯_투명.png',
    36 || 48 || 50 => 'assets/images/주식선생님/24_포즈3_주인공그림체_공통슬롯_투명.png',
    _ => 'assets/images/주식선생님/26_포즈5_주인공그림체_공통슬롯_투명.png',
  };

  bool get _isNarration =>
      _beat == 0 ||
      _beat == 6 ||
      _beat == 14 ||
      _beat == 16 ||
      _beat == 17 ||
      _beat == 22 ||
      _beat == 26 ||
      _beat == 32 ||
      _beat == 35 ||
      _beat == 46 ||
      _beat == 50;

  String get _speaker => switch (_beat) {
    0 || 6 || 14 || 16 || 17 || 22 || 26 || 32 || 35 || 46 || 50 => '이야기',
    1 || 7 || 11 => '서문태 정책실장',
    2 || 12 => '백기현 비서실장',
    3 || 13 => '전두광',
    4 => '강인철 경제수석',
    5 => _policyBriefingSpeaker,
    8 || 15 => '윤미라 사회교육수석',
    9 => '전두광',
    10 => '장대식 법무수석',
    18 || 23 || 28 || 33 => '박태수',
    19 || 21 || 24 || 29 || 31 || 38 || 40 || 42 || 45 || 48 =>
      _playerController.text.trim().isEmpty
          ? '나'
          : _playerController.text.trim(),
    20 => '장부',
    25 || 27 => '오경태 생활지도관',
    34 || 35 => '차은주 국가계좌 담당관',
    36 || 37 || 39 || 41 || 43 || 44 || 47 || 49 => '한서윤 선생님',
    _ => '이야기',
  };
  String get _line => switch (_beat) {
    0 =>
      '1981년 1월 12일 밤 11시 40분. 청와대 정책실의 불은 자정이 가까워지도록 꺼지지 않았다. 다섯 권의 보고서 가운데 보호시설 보고서만 유난히 얇았다.',
    1 => '우리나라의 미래가 어둡습니다.',
    2 => '각하 앞에서 나라 망한다는 보고부터 꺼내는 배짱은 높이 사겠네. 자네 임기가 오늘 밤 끝날 수도 있다는 건 알고 시작하게.',
    3 => '계속해.',
    4 =>
      '앞으로의 전쟁은 공장 숫자로만 하지 않습니다. 반도체 회로 한 줄, 통신망 하나, 기업 지분 몇 퍼센트가 나라의 목줄을 쥘 수 있습니다.',
    5 => _policyMessage,
    6 =>
      '보고서 다섯 권이 한 줄로 놓였다. 부잣집 아이는 밥상머리에서 장부와 공장을 배우지만, 보호시설 아이에게는 열아홉 살의 퇴소 가방만 남아 있었다.',
    7 =>
      '국가는 이미 그 아이들의 오늘을 책임지고 있습니다. 이제 회계, 산업, 계약, 저축과 투자를 가르쳐 미래의 자본 지휘자로 만들어야 합니다.',
    8 => '아이를 국가가 소유한 자본이나 실험쥐처럼 취급하겠다는 겁니까?',
    9 => '국가 물건으로 만들자는 소리는 하지 말게. 국가가 끝까지 책임지는 미래의 쩐주로 만들면 되지.',
    10 => '미성년자가 국가 재산을 운용할 법적 근거가 없습니다.',
    11 => '만 열네 살부터 소액 국가계좌를 엽니다. 최초 원금은 단돈 만 원. 운용 판단은 교육생 본인이 합니다.',
    12 => '잃으면 혈세 낭비라 하고, 벌면 벼룩의 간을 빼먹는다고 할 겁니다. 몇 퍼센트를 회수할 생각인가?',
    13 => '이십 퍼센트.',
    14 =>
      '전두광의 만년필이 결재란을 눌렀다. 사각. 한 아이의 인생을 바꾸기에는 너무 짧고, 국가의 거대한 실험을 시작하기에는 지나치게 가벼운 소리였다.',
    15 =>
      '나머지 80퍼센트는 아이의 자립적립금으로 동결해야 합니다. 열아홉 살이 되면 국가 원금만 돌려주고 전부 본인 이름으로 이전해야 합니다.',
    16 => '1982년, 국립 미래양성원이 문을 열었다. 아이들은 구구단 다음에 복식부기를, 사회시간 다음에 공장 견학표를 배웠다.',
    17 =>
      '1997년 외환위기. 제5기 일부는 무너진 기업을 주워 담았고, 일부의 이름은 국가 기록에서 검은 줄로 지워졌다. 그리고 새천년 전야, 여섯째 줄이 인쇄됐다.',
    18 => '6기 명단 맞아. 그런데 5기 장부는 왜 이름표가 뜯겨 있지?',
    19 => '졸업했으면 이름이 더 잘 보여야 하는 거 아냐?',
    20 => '국가계좌를 운용할 첫 이유를 장부에 남기십시오.',
    21 => _introResponse,
    22 =>
      '소등 종이 울렸지만 6기 기숙사의 몇몇 이불 속에서는 손전등과 증권 용어집이 꺼지지 않았다. 국가가 준 만 원은 여의도에서는 점심값, 이곳에서는 열네 해를 기다린 주문권이었다.',
    23 => '네가 벌면 20퍼센트나 먼저 떼 간대. 남은 돈도 열아홉 살 전에는 못 만지고.',
    24 => '상관없어. 국가 이름으로 시작해서 내 이름으로 끝내면 되니까.',
    25 => '국가 기밀을 훔쳐본 운용자 둘은 새벽 전자창고 정리다. 그리고 5기 장부는 못 본 걸로 해.',
    26 =>
      '전자창고에는 고장 난 전화기와 모뎀이 산처럼 쌓여 있었다. 같은 한빛통신 제품 열두 대 중 아홉 대에 붉은 고장표가 붙어 있었다.',
    27 => '작동, 고장, 부품용. 세 칸으로 나눠. 고장 났다고 주인이 없어지는 건 아니다.',
    28 => '불량률이 이 정도면 한빛통신은 안 사는 게 맞아.',
    29 => '그런데 왜 우리 원은 열두 대나 샀을까? 싸고 빨리 납품했으니까. 중요한 건 이 문제를 고칠 수 있느냐야.',
    30 =>
      '수리전표 아래에는 다음 주 신형 통신칩 교체 시험과 추가구매 예정표가 끼워져 있었다. 성공은 아니었다. 그러나 성공하면 달라질 크기는 보였다.',
    31 => '장부, 통장, 연필. 다 챙겼어. 이제 국가계좌를 받으러 가자.',
    32 =>
      '강당을 개조한 계좌개통실에는 책상이 여섯 줄로 놓였다. 각 자리에는 남색 통장, 빈 장부, 그리고 원금 10,000원이 찍힌 표가 기다리고 있었다.',
    33 => '수익은 같이 먹고 손실은 같이 안 진다. 국가가 계산은 제일 잘하네.',
    34 => '제6기 국가계좌를 개통합니다. 확정수익 20퍼센트는 국가 환수, 80퍼센트는 만 열아홉 살까지 자립적립금으로 보호됩니다.',
    35 => '붉은 도장이 통장 위로 떨어졌다. 명의자는 대한민국 미래양성기금. 운용자 칸만 비어 있었다.',
    36 => '제6기 담당 한서윤입니다. 국가 돈을 받았다고 정답까지 받은 사람?',
    37 => '정답보다 먼저, 판단을 남길 운용자 이름부터 적어 볼까요?',
    38 => '저는 ${_playerController.text.trim()}입니다. 정답 말고 주문권 받으러 왔어요.',
    39 => '좋아요. 만 원이 국가 돈이면, 틀렸을 때 사라지는 건 누구의 기회죠?',
    40 => '제 기회요. 국가는 다음 7기를 뽑으면 되니까.',
    41 => '그래서 판단 기록은 네 이름으로 남겨요. 계좌 명의와 생각의 주인은 다를 수 있으니까.',
    42 => '그럼 제가 사고 싶은 가격도 정할 수 있어요?',
    43 =>
      '정할 수 있어요. 원하는 가격에 줄을 서는 지정가와 지금 나온 가격부터 사는 시장가, 그리고 이익이 확정될 때의 국가 환수까지 같이 확인합니다.',
    44 => '한빛통신을 다시 볼 때 네 눈이 어디부터 가는지 골라 볼까요?',
    45 => _traitResponse,
    46 => '한서윤이 컴퓨터 옆에 주문표를 놓았다. 국가 서약서 위로 주인 없는 빈 장부가 겹쳐졌다.',
    47 => '국가 규칙 말고, 네가 스스로 지킬 운용 원칙 한 줄을 정하세요.',
    48 => _lessonRuleResponse,
    49 => '통장에는 국가 이름이 있죠. 하지만 주문표의 투자회사 칸은 비어 있어요. 먼저 갖고 싶은 이름을 쓰세요.',
    _ => '빈 장부 표지 한가운데에 두 줄을 그었다. 첫 줄에는 내 이름, 둘째 줄에는 오늘부터 키워 갈 투자회사 이름이 들어간다.',
  };

  String get _introResponse => switch (_introChoice) {
    'computer' => '국가 이름으로 시작해도 마지막에는 내 이름을 남긴다.',
    'y2k' => '검게 지워진 5기 선배들의 장부부터 되찾는다.',
    'stocks' => '돈이 없으면 선택도 없다. 내 선택권을 사기 위해 번다.',
    _ => '',
  };

  String get _traitResponse => switch (_trait) {
    StoryTrait.stability => '불량이 줄지 않으면 안 삽니다. 다음 기회를 잃지 않는 게 먼저예요.',
    StoryTrait.innovation => '신형 통신칩이 실제로 문제를 바꾸는지부터 봅니다.',
    StoryTrait.analysis => '불량률, 납품 속도, 추가구매 가격을 같이 비교합니다.',
    StoryTrait.control => '한 주를 사더라도 회사가 약속을 지키는지 끝까지 묻겠습니다.',
    null => '',
  };

  String get _lessonRuleResponse => switch (_familyRule) {
    FamilyRule.reportLosses => '손해가 나도 숨기지 않고 쓸게요. 지우면 왜 틀렸는지도 없어지니까.',
    FamilyRule.noHotTips => '추천보다 제 이유를 먼저 쓸게요. 이유가 없으면 제 주문도 아니니까.',
    FamilyRule.keepCash => '한 번에 다 안 쓸게요. 다음에 다시 고를 돈은 남겨 둬야 하니까.',
    null => '',
  };

  String get _policyBriefingSpeaker => switch (_activePolicyFile) {
    'industry' || 'population' || 'capital' => '서문태 정책실장',
    'children' => '윤미라 사회교육수석',
    'law' => '장대식 법무수석',
    _ => '이야기',
  };

  String? get _policyBriefingCharacter => switch (_activePolicyFile) {
    'children' =>
      'assets/images/historical_prologue/character_yoon_mira_v1.png',
    'law' => 'assets/images/historical_prologue/character_jang_daesik_v1.png',
    _ => 'assets/images/historical_prologue/character_seo_muntae_v1.png',
  };

  String? get _stageDirection => switch (_beat) {
    1 => '서문태가 2000년과 2010년에서 꺾이는 낡은 괘도를 펼쳤다.',
    2 => '백기현은 천천히 안경을 벗어 탁자 위에 놓았다.',
    3 => '전두광이 만년필 뚜껑을 열었다.',
    4 => '강인철의 연필 끝이 반도체와 통신망 도표를 차례로 짚었다.',
    5 => switch (_activePolicyFile) {
      'industry' => '수출 보고서에는 공장 숫자와 외화 목표가 빼곡했다.',
      'population' => '인구 곡선은 2000년을 지나며 완만하게 꺾였다.',
      'children' => '보호시설 보고서만 다른 서류의 절반 두께였다.',
      'capital' => '빈 계좌 양식의 명의자 칸에는 국가 이름만 인쇄돼 있었다.',
      'law' => '법적 근거 칸은 깨끗하게 비어 있었다.',
      _ => '서로 다른 미래를 말하는 보고서 다섯 권이 탁자 위에 놓였다.',
    },
    7 => '서문태의 손이 가장 얇은 보호시설 보고서 위에서 멈췄다.',
    8 => '윤미라가 보고서를 덮고 자리에서 일어났다.',
    9 => '전두광은 얇은 보고서를 손가락으로 두 번 두드렸다.',
    10 => '장대식이 빈 법률수첩을 마지못해 끌어당겼다.',
    11 => '계좌 양식에 만 14세와 원금 10,000원이 적혔다.',
    12 => '백기현이 다시 안경을 쓰며 환수율 칸을 바라봤다.',
    13 => '전두광이 20%라는 숫자에 동그라미를 쳤다.',
    15 => '윤미라는 80% 아래에 자립적립금이라는 말을 힘주어 적었다.',
    18 => '도트프린터가 제6기 명단을 거칠게 밀어냈다.',
    19 => '나는 검게 지워진 세 이름을 손가락으로 문질렀다.',
    20 => '장부 첫 장의 운용 목적 칸이 푸른빛으로 깜빡였다.',
    21 => '내가 고른 문장이 빈 장부 첫 줄에 남았다.',
    23 => '박태수가 윗침대에서 약관을 아래로 내려뜨렸다.',
    24 => '나는 환수율 20%를 손가락으로 툭툭 두드렸다.',
    25 => '문간의 오경태가 5기 장부를 점검표 아래로 덮었다.',
    27 => '오경태가 빈 상자 세 개와 점검표를 내려놓았다.',
    28 => '박태수가 고장 딱지가 붙은 모뎀을 따로 밀어냈다.',
    29 => '나는 구매전표와 수리전표를 나란히 펼쳤다.',
    30 => '다음 주 시험 예정표가 낡은 수리전표 아래에서 나왔다.',
    31 => '나는 베개 밑 장부와 짧아진 연필을 제일 먼저 챙겼다.',
    33 => '박태수가 국가 환수 안내서를 반으로 접었다.',
    34 => '차은주가 남색 통장과 붉은 도장을 들어 보였다.',
    36 => '한서윤은 켜지지 않은 CRT 여섯 대 앞에 섰다.',
    38 => '운용자 칸에 이름을 적자 통장과 장부가 동시에 연결됐다.',
    39 => '한서윤이 국가 명의 통장과 빈 판단 장부를 나란히 놓았다.',
    40 => '나는 통장보다 장부를 내 쪽으로 끌어당겼다.',
    41 => '한서윤은 계좌 명의와 운용자 이름 사이에 선을 그었다.',
    42 => '나는 빈 주문표의 가격 칸을 손가락으로 짚었다.',
    45 => '내가 고른 자료를 한빛통신 수리전표 옆에 놓았다.',
    48 => '나는 국가 서약서가 아니라 내 장부 첫 줄에 원칙을 적었다.',
    49 => '한서윤이 회사명 칸만 비어 있는 첫 주문표를 내밀었다.',
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
    if (_beat >= _companyNameBeat) {
      if (_beat != _companyNameBeat) {
        setState(() => _beat = _companyNameBeat);
      }
      return;
    }
    final currentBeat = _beat;
    FocusManager.instance.primaryFocus?.unfocus();
    _rememberCurrentLine();
    _playStoryFeedback();
    if (_beat == _accountHallDepartureBeat) {
      _travelToAccountHall();
      return;
    }
    if (_quickSetup && _beat == _playerNameBeat) {
      setState(() => _beat = _companyNameBeat);
      return;
    }
    setState(() {
      if (_beat == currentBeat) {
        _beat = currentBeat + 1;
      }
    });
  }

  void _travelToAccountHall() {
    if (_isTraveling) return;
    setState(() => _isTraveling = true);
    _travelTimer?.cancel();
    _travelTimer = Timer(
      const Duration(milliseconds: 2600),
      _finishAccountHallTravel,
    );
  }

  void _finishAccountHallTravel() {
    _travelTimer?.cancel();
    _travelTimer = null;
    if (!mounted || !_isTraveling) return;
    _playStoryFeedback(strong: true);
    setState(() {
      _isTraveling = false;
      _beat = 32;
    });
  }

  void _reviewPolicyFile(String id) {
    if (_reviewedPolicyFiles.contains(id)) return;
    _rememberCurrentLine();
    final message = switch (id) {
      'industry' => '값싼 노동력과 외산 기계만으로는 몇십 년 뒤의 산업을 지휘할 수 없습니다.',
      'population' => '아이 수는 줄고 기술은 비싸집니다. 지금 태어난 아이가 미래의 돈을 굴려야 합니다.',
      'children' => '열아홉 살 퇴소 뒤에도 아이가 자기 삶을 선택할 자산을 남겨야 합니다.',
      'capital' => '원금 만 원은 국가가 대되, 모든 매수와 매도 이유는 운용자가 장부에 남깁니다.',
      'law' => '특별법 없이는 불가능합니다. 만들더라도 손실을 아이 개인의 빚으로 남길 수는 없습니다.',
      _ => _policyMessage,
    };
    _playStoryFeedback();
    setState(() {
      _activePolicyFile = id;
      _reviewedPolicyFiles.add(id);
      _policyMessage = message;
    });
  }

  void _finishPolicyBriefing() {
    if (_reviewedPolicyFiles.length != _policyFileLabels.length) return;
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
          '미래양성계획 창설과 제6기 장부 이야기를 건너뛰고 이름 설정으로 이동합니다. '
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
      _stateAccountActivated = true;
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
      setState(() {
        _creationError = '이름과 앞에서 선택한 투자 원칙을 모두 확인해 주세요.';
      });
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isCreating = true;
      _creationError = null;
      _creationProgress = const WorldLoadProgress(0.02, '제6기 국가계좌 정보를 정리하는 중…');
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
    } catch (error, stackTrace) {
      debugPrint('Failed to finish new-game onboarding: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _creationError = '저장이나 주문 연습 화면 준비에 실패했습니다. 잠시 후 다시 눌러 주세요.';
        });
      }
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
              ? 'assets/images/historical_prologue/character_state_account_officer_cha_eunjoo_v1.png'
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
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              for (final child in previousChildren)
                                IgnorePointer(child: child),
                              ?currentChild,
                            ],
                          );
                        },
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
                  child: _AcademyTravelOverlay(
                    onSkip: _finishAccountHallTravel,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogue(BuildContext context) {
    if (_beat == _policyBriefingBeat) return _policyBriefing();
    if (_beat == _introChoiceBeat) return _introChoices();
    if (_beat == _stateAccountActivationBeat) {
      return _stateAccountActivation();
    }
    if (_beat == 43) return _academyTutorial();
    if (_beat == _playerNameBeat) return _nameEntry();
    if (_beat == _traitChoiceBeat) return _traitChoices();
    if (_beat == _principleChoiceBeat) return _principleChoices();
    if (_beat >= _companyNameBeat) return _researchDeskName();

    return _NovelDialogue(
      key: ValueKey(_beat),
      speaker: _speaker,
      line: _line,
      stageDirection: _stageDirection,
      narration: _isNarration,
      onContinue: _next,
    );
  }

  Widget _policyBriefing() => _NovelDialogue(
    key: ValueKey(
      'policy-briefing-${_reviewedPolicyFiles.length}-$_policyMessage',
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
              children: _policyFileLabels.entries
                  .map(
                    (entry) => SizedBox(
                      width: width,
                      child: _RepairGoalButton(
                        key: ValueKey('policy-file-${entry.key}'),
                        label: entry.value,
                        completed: _reviewedPolicyFiles.contains(entry.key),
                        onTap: () => _reviewPolicyFile(entry.key),
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          key: const Key('policy-briefing-progress'),
          value: _reviewedPolicyFiles.length / _policyFileLabels.length,
          minHeight: 7,
          borderRadius: BorderRadius.circular(99),
          color: const Color(0xFF54A86B),
          backgroundColor: const Color(0xFFD9D6CC),
        ),
        const SizedBox(height: 10),
        _NovelNextButton(
          key: const Key('policy-briefing-finish'),
          label: _reviewedPolicyFiles.length == _policyFileLabels.length
              ? '다섯 보고서로 결재안 완성'
              : '${_reviewedPolicyFiles.length}/5 · 보고서를 더 확인',
          enabled: _reviewedPolicyFiles.length == _policyFileLabels.length,
          onTap: _finishPolicyBriefing,
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
        label: '국가 이름으로 시작해도 내 이름으로 끝낸다',
        onTap: () => _chooseIntroChoice('computer'),
      ),
      _NovelChoice(
        key: const Key('story-intro-y2k'),
        label: '검게 지워진 5기 선배들의 장부를 찾는다',
        onTap: () => _chooseIntroChoice('y2k'),
      ),
      _NovelChoice(
        key: const Key('story-intro-stocks'),
        label: '돈으로 내 선택권을 직접 산다',
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
          body: '원하는 가격에 줄을 서고 오지 않으면 사지 않는다',
        ),
        const SizedBox(height: 6),
        const _AcademyLessonRow(
          number: '2',
          title: '시장가',
          body: '지금 나온 호가부터 체결되어 가격이 달라질 수 있다',
        ),
        const SizedBox(height: 6),
        const _AcademyLessonRow(
          number: '3',
          title: '확정수익',
          body: '거래비용을 뺀 이익의 20%는 국가 환수로 기록한다',
        ),
        const SizedBox(height: 10),
        _NovelNextButton(
          key: const Key('academy-tutorial-continue'),
          label: '주문과 국가 환수 규칙 확인',
          enabled: true,
          onTap: _next,
        ),
      ],
    ),
  );

  Widget _stateAccountActivation() => _NovelDialogue(
    key: const ValueKey('state-account-activation'),
    speaker: _speaker,
    line: _line,
    stageDirection: _stageDirection,
    child: _AcademyTuitionPaymentPanel(
      paid: _stateAccountActivated,
      onPay: () {
        _playStoryFeedback(strong: true);
        setState(() => _stateAccountActivated = true);
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
          onChanged: (_) => setState(() => _creationError = null),
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
        label: '불량이 줄지 않으면 사지 않는다',
        onTap: () => _chooseTrait(StoryTrait.stability),
      ),
      _NovelChoice(
        key: const Key('story-trait-innovation'),
        label: '신형 통신칩이 문제를 바꾸는지 본다',
        onTap: () => _chooseTrait(StoryTrait.innovation),
      ),
      _NovelChoice(
        key: const Key('story-trait-analysis'),
        label: '불량률·납품 속도·가격을 같이 본다',
        onTap: () => _chooseTrait(StoryTrait.analysis),
      ),
      _NovelChoice(
        key: const Key('story-trait-control'),
        label: '회사가 약속을 지키는지 끝까지 묻는다',
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

  Widget _principleChoices() => _NovelDialogue(
    key: const ValueKey('investment-principle-choice'),
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
        label: '추천보다 내 이유를 먼저 쓰기',
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
          onChanged: (_) => setState(() => _creationError = null),
          onSubmitted: (_) => _finish(),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: _fieldDecoration('예: 별빛 투자'),
        ),
        const SizedBox(height: 16),
        _NovelNextButton(
          key: const Key('create-company-button'),
          label: '투자회사 이름을 정하고 국가계좌 주문 시작',
          enabled: _companyController.text.trim().isNotEmpty,
          onTap: _finish,
        ),
        if (_creationError != null) ...[
          const SizedBox(height: 10),
          Text(
            _creationError!,
            key: const Key('new-game-creation-error'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFD1C7),
              fontSize: 11,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
                '국가계좌 개통실로 이동 중…',
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
                '6기 기숙사  ·  중앙 복도  ·  계좌개통실',
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
                  '복도 이동 건너뛰기',
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
        key: const Key('state-account-activation-card'),
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
                  paid ? Icons.verified_rounded : Icons.account_balance,
                  color: paid
                      ? const Color(0xFF258257)
                      : const Color(0xFF536A96),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    paid ? '제6기 국가계좌 개통 완료' : '제6기 국가계좌 개통',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Text(
                  '10,000원',
                  key: Key('state-account-principal'),
                  style: TextStyle(
                    color: Color(0xFF258257),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFeatures: _marketNumberFeatures,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            const Row(
              children: [
                Text(
                  '계좌 명의',
                  style: TextStyle(
                    color: Color(0xFF697386),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Spacer(),
                Text(
                  '대한민국 미래양성기금',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Divider(height: 17),
            const Row(
              children: [
                Text(
                  '확정수익 국가 환수',
                  style: TextStyle(
                    color: Color(0xFF697386),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Spacer(),
                Text(
                  '20%',
                  key: Key('state-recovery-rate'),
                  style: TextStyle(
                    color: Color(0xFFC53F4B),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text(
                  '자립적립금',
                  style: TextStyle(
                    color: Color(0xFF697386),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Spacer(),
                Text(
                  '80% · 만 19세까지 잠금',
                  key: Key('self-reliance-rate'),
                  style: TextStyle(
                    color: Color(0xFF536A96),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text(
                  '손실의 개인 채무',
                  style: TextStyle(
                    color: Color(0xFF697386),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Spacer(),
                Text(
                  '0원',
                  key: Key('personal-debt-zero'),
                  style: TextStyle(
                    color: Color(0xFF258257),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (paid) ...[
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel_rounded, size: 15, color: Color(0xFF258257)),
                  SizedBox(width: 6),
                  Text(
                    '국가계좌 약관과 위험평가표 연결 완료',
                    key: Key('state-account-activated'),
                    style: TextStyle(
                      color: Color(0xFF258257),
                      fontSize: 10,
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
          paid
              ? 'state-account-activation-continue'
              : 'state-account-activation-button',
        ),
        label: paid ? '개통 통장 받고 투자실로 이동' : '국가계좌 약관 확인하고 개통',
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
                  '국가계좌를 개통하고 있어요',
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
                  '주식·부동산 세계 계산은 처음하기에서 이미 끝냈어요.\n'
                  '지금은 운용자·투자회사 이름과 국가 환수 장부를 저장하는 중입니다.',
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
            ],
            Semantics(
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
