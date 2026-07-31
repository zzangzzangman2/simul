part of 'main.dart';

const _onboardingBeatCount = 54;
const _policyBriefingBeat = 5;
const _orientationRosterBeat = 43;
const _orientationCompleteBeat = 53;
const _introChoiceBeat = 120;
const _accountHallDepartureBeat = 131;
const _stateAccountActivationBeat = 134;
const _playerNameBeat = 137;
const _traitChoiceBeat = 144;
const _principleChoiceBeat = 147;
const _companyNameBeat = 150;
const _storyCharacterBottomInset = 0.0;
const _storyCharacterHeightFactor = 0.9;
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
  const VisualNovelOnboardingScreen({
    super.key,
    required this.onCreate,
    this.onExit,
  });

  final NewGameCreator onCreate;
  final VoidCallback? onExit;

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
      <= 15 =>
        'assets/images/historical_prologue/bg_blue_house_conference_1981_portrait_cartoon_v1.png',
      16 =>
        'assets/images/historical_prologue/bg_future_development_orphanage_1982_portrait_cartoon_v1.png',
      <= 22 =>
        'assets/images/historical_prologue/bg_orphanage_departure_2000_portrait_v1.png',
      <= 31 =>
        'assets/images/historical_prologue/bg_future_development_academy_gate_2000_portrait_v1.png',
      _ =>
        'assets/images/historical_prologue/bg_future_development_orientation_hall_2000_portrait_v1.png',
    };
  }

  String get _location {
    return switch (_beat) {
      <= 4 => '청와대 · 정책실',
      <= 15 => '청와대 · 미래전략 심야회의',
      16 => '국립 미래양성원 · 개원 기록',
      <= 22 => '새봄보육원 · 2층 다섯 번째 방',
      <= 31 => '국립 미래양성원 · 투자전문과정 정문',
      _ => '국립 미래양성원 · 제6기 오리엔테이션 강당',
    };
  }

  String get _dateLabel => switch (_beat) {
    <= 15 => '1981.01.12  ·  23:40',
    16 => '1982년  ·  미래양성계획 출범',
    <= 22 => '2000.01.02  ·  06:42',
    <= 31 => '2000.01.02  ·  07:31',
    _ => '2000.01.02  ·  08:00',
  };

  String? get _character {
    return switch (_beat) {
      1 || 12 || 14 =>
        'assets/images/historical_prologue/character_jeon_dugwang_decree_cartoon_v2.png',
      2 ||
      7 ||
      11 ||
      13 => 'assets/images/historical_prologue/character_seo_muntae_v1.png',
      4 => 'assets/images/historical_prologue/character_kang_incheol_v1.png',
      3 ||
      10 => 'assets/images/historical_prologue/character_baek_gihyeon_v1.png',
      5 => _policyBriefingCharacter,
      8 || 15 => 'assets/images/historical_prologue/character_yoon_mira_v1.png',
      25 || 27 || 29 || 31 || 36 || 38 || 47 =>
        'assets/images/historical_prologue/character_sua_orientation_v1.png',
      28 || 30 || 39 || 46 =>
        'assets/images/historical_prologue/character_hakjun_orientation_v1.png',
      _ => null,
    };
  }

  bool get _isAcademyTeacherBeat =>
      _beat == 34 ||
      _beat == 35 ||
      _beat == 37 ||
      _beat == 42 ||
      _beat == 43 ||
      _beat == 44 ||
      _beat == 45 ||
      _beat == 49 ||
      _beat == 51 ||
      _beat == 53;

  bool get _isAcademyReceptionistBeat =>
      _beat == _stateAccountActivationBeat || _beat == 135;

  String get _teacherPoseAsset => switch (_beat) {
    34 || 42 || 51 => 'assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png',
    35 || 43 || 49 => 'assets/images/주식선생님/24_포즈3_주인공그림체_공통슬롯_투명.png',
    37 || 44 => 'assets/images/주식선생님/23_포즈2_주인공그림체_공통슬롯_투명.png',
    45 || 53 => 'assets/images/주식선생님/26_포즈5_주인공그림체_공통슬롯_투명.png',
    _ => 'assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png',
  };

  bool get _isNarration =>
      _beat == 0 ||
      _beat == 6 ||
      _beat == 16 ||
      _beat == 17 ||
      _beat == 20 ||
      _beat == 23 ||
      _beat == 27 ||
      _beat == 32 ||
      _beat == 41 ||
      _beat == 52;

  String get _speaker => switch (_beat) {
    0 || 6 || 16 || 17 || 20 || 23 || 27 || 32 || 41 || 52 => '이야기',
    1 || 9 || 12 || 14 => '전두광',
    2 || 7 || 11 || 13 => '서문태 정책실장',
    3 || 10 => '백기현 비서실장',
    4 => '강인철 경제수석',
    5 => _policyBriefingSpeaker,
    8 || 15 => '윤미라 사회교육수석',
    18 => '민호',
    19 || 21 || 26 || 40 || 48 || 50 => '나',
    22 => '박선희 원장',
    24 || 33 => '아이들',
    25 || 29 || 31 || 36 || 38 || 47 => '수아',
    28 || 30 || 39 || 46 => '학준',
    34 || 35 || 37 || 42 || 43 || 44 || 45 || 49 || 51 || 53 => '한서윤 선생님',
    _ => '이야기',
  };

  String get _line => switch (_beat) {
    0 =>
      '1981년 1월 12일 밤 11시 40분. 청와대 정책실의 불은 자정이 가까워져도 꺼지지 않았다. 보고서 다섯 권 가운데 하나만, 이상할 만큼 얇았다.',
    1 => '그래서. 당장은 멀쩡한데, 이대로 가면 나라가 망한다?',
    2 => '당장은 아닙니다. 하지만 당장만 보고 달리면 이십 년 뒤에는 남의 기술과 남의 돈에 목줄이 잡힙니다.',
    3 => '각하 앞에서 나라 앞날이 어둡다고 했으니, 자네 앞날도 같이 어두워질 수 있겠어.',
    4 =>
      '지금은 공장 세우고 물건을 찍는 쪽이 이깁니다. 하지만 미래에는 어떤 기술에 돈을 넣고, 어떤 회사를 살릴지 정하는 사람이 공장 몇 개보다 더 큰 힘을 갖게 됩니다.',
    5 => _policyMessage,
    6 => '수출산업, 인구전망, 국가계좌, 특별법. 네 권은 벽돌처럼 두꺼웠다. 「요보호아동 시설 현황」만 종잇장처럼 얇았다.',
    7 => '국가는 이미 아이들의 오늘을 먹이고 재웁니다. 이제 내일을 고를 힘까지 줘야 합니다.',
    8 => '미치셨습니까? 아이들을 국가가 키우는 자본이나 실험쥐로 보겠다는 겁니까? 실패하면 그 아이 인생은 누가 책임집니까!',
    9 => '먹이고 재우는 데서 끝내면 세금 낭비지. 스스로 돈을 벌게 만들면 투자가 되고.',
    10 => '핏덩이들에게 나랏돈을 줬다가 잃으면 혈세 낭비라 할 겁니다. 벌면 나라가 코 묻은 돈을 빼앗는다고 할 테고요.',
    11 =>
      '열 살, SEED 01부터 시작합니다. 원금은 만 원. 작아서 우습지만, 잃었을 때 왜 잃었는지는 숨길 수 없는 돈입니다.',
    12 => '잃으면?',
    13 => '아이 빚으로 남기지 않습니다. 대신 다음 달 주문 한도를 깎습니다. 벌면 일부를 국가가 회수하고요.',
    14 => '이십 퍼센트. 나머지는 아이 몫. 대신 왜 샀고 왜 팔았는지 전부 쓰게 해. 성공담 말고, 바닥을 긴 기록까지.',
    15 => '그 80퍼센트는 시설 돈이 아닙니다. 아이 이름으로 묶어두고, 열아홉에 1원도 빠짐없이 넘기십시오.',
    16 => '이듬해, 국립 미래양성원이 문을 열었다. 환영 문구 대신 정문에는 한 줄이 걸렸다. 「기록 없는 판단은 우연이다」',
    17 =>
      '2000년 1월 2일 오전 6시 42분. 눈을 뜨자 천장의 누런 물자국이 먼저 보였다. 여섯 살 때부터 귀 잘린 토끼 같다고 생각했던 얼룩. 마지막 날인데도 물자국은 그냥 물자국이었다.',
    18 => '형아… 진짜 가?',
    19 => '응. 돈 세는 학교래. 돈을 그냥 주면 좋은데, 세기만 시키면 손가락만 아프잖아.',
    20 =>
      '민호가 웃다가 낡은 가방을 보고 입을 다물었다. 나는 왕딱지 한 장만 챙기고 나머지는 민호 이불 위에 던졌다. 가방 안감을 들추자 낯선 쇳조각이 손끝에 걸렸다. 「제5기 · 17번」.',
    21 =>
      '이름은 칼로 긁어 지워져 있었다. 뒷면에는 더 이상한 말이 파여 있었다. 「17번을 믿지 마.」 …이게 17번 명찰인데, 누구를 믿지 말라는 거야?',
    22 =>
      '짐 가벼운 걸 부끄러워하지 마. 앞으로 채울 자리가 많은 거니까. 그리고 가서도 이유를 물어. 말이 안 되면 두 번 묻고. 그래도 이상하면 장부에 적어. 말은 날아가도 적은 건 남으니까.',
    23 =>
      '버스는 서울을 벗어나 한참을 덜컹거렸다. 눈발 너머로 붉은 벽돌 건물이 나타났다. 학교치고는 담장이 길었고, 공장치고는 창문이 많았다.',
    24 => '“여기가 그 유명한 데래.”\n“고아원에서 추천받은 애들만 온다던데?”\n“입학식인데 왜 면접장보다 조용해?”',
    25 => '야, 바퀴 달린 가방. 네 바퀴 하나가 계속 눈을 모으고 있어.',
    26 => '일부러 눈사람 만드는 중이야. 본관 도착할 때쯤 머리까지 붙이려고.',
    27 =>
      '여자아이는 대꾸 대신 쪼그려 앉아 연필로 바퀴의 눈을 긁어냈다. 친화력이 좋다기보다, 남의 일에 거리낌 없이 끼어드는 타입 같았다. 이름은 수아라고 했다.',
    28 => '정문에서 본관까지 420미터. 권장 도착 시간은 6분. 뛰면 감점이야. 안내문 7쪽.',
    29 => '안내문에 별명 금지도 있어, 설명서 학준아?',
    30 => '…없어. 그리고 그렇게 부르지 마.',
    31 => '그럼 합법이네.',
    32 =>
      '강당에는 내빈석도 부모 자리도 없었다. 스무 개의 의자만 반원으로 놓여 있었다. 무대 위 나무상자 하나가 더 수상해 보였다.',
    33 => '“남자 열, 여자 열이래.”\n“자리도 성적순일까?”\n“아직 시험도 안 봤는데 무슨 성적이 있어.”',
    34 => '제6기 담당 한서윤입니다. 인사는 이따 하죠. 여러분 배에서 나는 소리가 더 급해 보이니까.',
    35 => '이 상자 안에는 단팥빵 하나와 500원짜리 동전이 있어요. 식당에서 빵은 300원입니다. 하나만 고르세요.',
    36 => '동전이요! 빵 사고도 200원 남잖아요.',
    37 => '좋아요. 그런데 식당 문은 두 시간 뒤, 열 시에 열립니다.',
    38 => '두 시간이요? …참을 수 있어요. 아마도.',
    39 => '빵이 몇 개 남았는지, 열 시에 새로 들어오는지부터 확인해야 합니다. 동전만 보고 고르면 정보가 부족해요.',
    40 => '그 전에 상자부터 열어봐야 하는 거 아니에요? 선생님이 단팥빵을 벌써 드셨을 수도 있잖아요.',
    41 => '아이들 사이에서 웃음이 터졌다. 한서윤은 화내지 않았다. 오히려 상자 뚜껑 위에 손을 얹고 나를 다시 보았다.',
    42 =>
      '그래요. 정답은 하나가 아닙니다. 무엇을 아느냐에 따라 답이 바뀌니까. 여기서 제일 먼저 배울 건 돈 버는 법이 아니라, 모르는 걸 모른다고 인정하는 법이에요.',
    43 =>
      '여기 온 아이는 스무 명. 남학생 열, 여학생 열. 모두 전국 보호시설에서 추천받았고, 시험보다 긴 관찰 기록을 거쳐 뽑혔습니다.',
    44 =>
      '여긴 고아원 간판만 바꾼 곳도, 부자 흉내를 내는 학원도 아니에요. 숫자 뒤에 숨은 사람과 거짓말, 그리고 자기 판단의 값을 배우는 곳입니다.',
    45 => '그럼 첫 번째 기록을 남겨볼까요. 자기가 왜 뽑혔다고 생각하죠?',
    46 => '규칙을 빨리 외우고 계산 실수가 없어서입니다.',
    47 => '사람 얼굴 보면 뭘 좋아하고 싫어하는지 금방 알아서요.',
    48 => '돈을 많이 벌 것 같아서 뽑은 거 아니에요?',
    49 => '지금 가진 돈은 얼마인데요?',
    50 => '왕딱지 한 장이요. 용 그려진 제일 센 거.',
    51 => '돈은 빵점. 솔직함은 합격. 뽑힌 이유는 내일부터 직접 찾아보죠.',
    52 =>
      '가장 어둡던 형광등이 한 번 떨리고 안정됐다. 스무 개의 이름표가 같은 빛을 받았다. 주머니 속 5기 명찰만 혼자 차갑게 식어 있었다.',
    _ =>
      '오늘은 여기까지입니다. 주식도, 국가계좌도 아직 열지 않아요. 먼저 이름과 자리를 외우세요. 내일부터는 틀린 답보다, 이유 없는 답을 더 무섭게 볼 겁니다.',
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
    1 => '전두광이 가장 얇은 보고서를 탁자 가운데로 밀었다.',
    2 => '밤샘으로 충혈된 서문태의 눈이 잠깐 흔들렸다.',
    3 => '백기현은 안경을 벗어 천천히 닦았다.',
    4 => '강인철의 연필이 1981년에서 2000년으로 긴 선을 그었다.',
    5 => switch (_activePolicyFile) {
      'industry' => '수출 보고서에는 공장 숫자와 외화 목표가 빼곡했다.',
      'population' => '인구 곡선은 2000년을 지나며 완만하게 꺾였다.',
      'children' => '보호시설 보고서만 다른 서류의 절반 두께였다.',
      'capital' => '빈 계좌 양식의 명의자 칸에는 국가 이름만 찍혀 있었다.',
      'law' => '법적 근거 칸은 깨끗하게 비어 있었다.',
      _ => '서로 다른 미래를 말하는 보고서 다섯 권이 탁자 위에 놓였다.',
    },
    7 => '서문태의 손이 가장 얇은 보고서 위에서 멈췄다.',
    8 => '윤미라가 손바닥으로 탁자를 내리쳤다.',
    9 => '전두광은 대답 대신 보고서 표지를 두 번 두드렸다.',
    10 => '백기현이 안경을 다시 쓰며 정치적 손익을 셌다.',
    11 => '서문태가 기다렸다는 듯 새 계좌 양식을 펼쳤다.',
    12 => '만년필 끝이 손실 처리 칸 위에서 멈췄다.',
    13 => '서문태가 다음 달 주문 한도 칸을 손가락으로 짚었다.',
    14 => '전두광은 20%에 동그라미를 치고 「미래양성원」 네 글자를 갈겨썼다.',
    15 => '윤미라는 80% 아래에 ‘아이 명의’라고 힘주어 적었다.',
    18 => '옆 침대 이불이 꿈틀거리더니 민호가 코만 내밀었다.',
    19 => '나는 지퍼가 잘 닫히지 않는 가방을 무릎으로 눌렀다.',
    20 => '모서리가 닳은 왕딱지 두 장이 민호의 이불 위로 날아갔다.',
    21 => '나는 쇳조각 명찰을 재빨리 바지 주머니에 쑤셔 넣었다.',
    22 => '박선희 원장이 목도리를 한 번 더 단단히 매어주었다.',
    23 => '정문의 돌 표어가 눈발 사이로 드러났다. 「기록 없는 판단은 우연이다」.',
    24 => '종이상자와 비닐봉지를 든 아이들의 속삭임이 겹쳤다.',
    25 => '수아가 내 가방이 남긴 삐뚤어진 바퀴 자국을 가리켰다.',
    26 => '나는 한쪽으로 기운 가방을 태연하게 세웠다.',
    27 => '연필 끝에서 굳은 눈덩이가 후두둑 떨어졌다.',
    28 => '남색 규정집을 낀 학준이 우리 옆에 바짝 붙었다.',
    29 => '수아가 눈을 가늘게 뜨고 학준의 명찰을 읽었다.',
    30 => '학준의 귀끝이 규정집 표지보다 먼저 붉어졌다.',
    31 => '수아가 깔깔 웃으며 먼저 언덕을 뛰어올랐다.',
    32 => '오래된 형광등 아래, 이름표 스무 장이 빈 의자를 지키고 있었다.',
    33 => '앞자리와 뒷자리에서 서로 다른 소문이 동시에 튀어나왔다.',
    34 => '구두 소리가 무대에 닿자 웅성거림이 절반쯤 줄었다.',
    35 => '한서윤이 나무상자 위에 손바닥을 올렸다.',
    36 => '수아의 손이 누구보다 먼저 천장을 찔렀다.',
    37 => '한서윤이 벽시계를 턱으로 가리켰다.',
    38 => '말이 끝나자마자 수아의 배에서 작은 소리가 났다.',
    39 => '학준은 규정집 모서리를 만지며 상자를 노려봤다.',
    40 => '나는 열리지 않은 상자 뚜껑을 손가락으로 가리켰다.',
    41 => '한서윤의 입꼬리가 처음으로 아주 조금 올라갔다.',
    42 => '칠판에 네 칸이 그어졌다. 아는 것, 모르는 것, 고른 이유, 생각을 바꿀 조건.',
    43 => '출석부가 펼쳐지고 남학생 열 칸, 여학생 열 칸이 차례로 확인됐다.',
    44 => '지시봉이 숫자, 사람, 판단 세 단어를 천천히 지나갔다.',
    45 => '한서윤의 시선이 반원으로 앉은 아이들을 훑었다.',
    46 => '학준은 기다렸다는 듯 허리를 곧게 폈다.',
    47 => '수아는 옆자리 아이들의 표정을 한번 훑고 대답했다.',
    48 => '나는 이유를 찾는 대신 가장 그럴듯한 답부터 꺼냈다.',
    49 => '한서윤이 웃음을 누르며 되물었다.',
    50 => '주머니 속 왕딱지가 손끝에 걸렸다.',
    51 => '한서윤이 출석부 내 이름 옆에 짧은 표시를 남겼다.',
    52 => '낡은 명찰의 모서리가 주머니 안에서 허벅지를 찔렀다.',
    53 => '강당 문이 열리고 차가운 복도 공기가 발끝으로 밀려왔다.',
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
    if (_beat >= _orientationCompleteBeat) return;
    final currentBeat = _beat;
    FocusManager.instance.primaryFocus?.unfocus();
    _rememberCurrentLine();
    _playStoryFeedback();
    if (_beat == _accountHallDepartureBeat) {
      _travelToAccountHall();
      return;
    }
    setState(() {
      if (_beat == currentBeat) {
        _beat = math.min(currentBeat + 1, _orientationCompleteBeat);
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
      'industry' => '공장 백 개를 세워도 돈의 방향을 남이 정하면, 우리는 남의 주문만 받게 됩니다.',
      'population' => '아이 수는 줄고 기술값은 오릅니다. 지금 태어난 아이가 그때의 돈을 움직입니다.',
      'children' => '열아홉에 가방 하나만 쥐여 보내선 선택하라고 말할 수도 없습니다.',
      'capital' => '만 원은 작습니다. 그래서 좋습니다. 실패는 작게, 판단은 숨김없이 남길 수 있으니까요.',
      'law' => '특별법이 필요합니다. 다만 실패를 아이 개인의 빚으로 돌리는 조항은 넣을 수 없습니다.',
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
          '미래양성계획 창설과 수아·학준의 첫 만남을 건너뛰고 '
          '제6기 오리엔테이션 마지막 안내로 이동합니다. '
          '주식 수업과 새 게임 저장은 아직 시작되지 않습니다.',
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
            child: const Text('마지막 안내로'),
          ),
        ],
      ),
    );
    if (!mounted || shouldSkip != true) return;
    _travelTimer?.cancel();
    _playStoryFeedback(strong: true);
    setState(() {
      _isTraveling = false;
      _beat = _orientationCompleteBeat;
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
                  ambientFlicker: _beat >= 32,
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
    if (_beat == _orientationRosterBeat) return _orientationRoster();
    if (_beat >= _orientationCompleteBeat) return _orientationComplete();
    if (_beat == _introChoiceBeat) return _introChoices();
    if (_beat == _stateAccountActivationBeat) {
      return _stateAccountActivation();
    }
    if (_beat == 143) return _academyTutorial();
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

  Widget _orientationRoster() => _NovelDialogue(
    key: const ValueKey('orientation-roster'),
    speaker: _speaker,
    line: _line,
    stageDirection: _stageDirection,
    child: Column(
      children: [
        Container(
          key: const Key('orientation-roster-card'),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F2E3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD8BE91)),
          ),
          child: Column(
            children: [
              const Text(
                '제6기 오리엔테이션 명단',
                style: TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _orientationStat(
                      key: const Key('orientation-total-count'),
                      label: '총원',
                      value: '20명',
                      color: const Color(0xFF536A96),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _orientationStat(
                      key: const Key('orientation-male-count'),
                      label: '남학생',
                      value: '10명',
                      color: const Color(0xFF3F72A5),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _orientationStat(
                      key: const Key('orientation-female-count'),
                      label: '여학생',
                      value: '10명',
                      color: const Color(0xFFC85C72),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              const Text(
                '전국 보호시설 추천 · 제6기 투자전문과정',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF697386),
                  fontSize: 10,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NovelNextButton(
          key: const Key('orientation-roster-continue'),
          label: '스무 명의 이름표 확인',
          enabled: true,
          onTap: _next,
        ),
      ],
    ),
  );

  Widget _orientationStat({
    required Key key,
    required String label,
    required String value,
    required Color color,
  }) => Container(
    key: key,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF697386),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  Widget _orientationComplete() => _NovelDialogue(
    key: const ValueKey('orientation-complete'),
    speaker: _speaker,
    line: _line,
    stageDirection: _stageDirection,
    child: Column(
      children: [
        Container(
          key: const Key('orientation-complete-card'),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF9DB4CC)),
          ),
          child: const Column(
            children: [
              Text(
                '제6기 오리엔테이션 · 1막 완료',
                style: TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 7),
              Text(
                '수아와 학준을 만났습니다.\n주식 수업과 국가계좌는 아직 잠겨 있습니다.',
                key: Key('stock-lesson-locked'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF536A96),
                  fontSize: 10,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _NovelNextButton(
          key: const Key('orientation-exit-button'),
          label: '처음 화면으로 돌아가기',
          enabled: true,
          onTap: widget.onExit ?? () {},
        ),
      ],
    ),
  );

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

class _LivingBackground extends StatefulWidget {
  const _LivingBackground({
    super.key,
    required this.asset,
    this.ambientFlicker = false,
  });

  final String asset;
  final bool ambientFlicker;

  @override
  State<_LivingBackground> createState() => _LivingBackgroundState();
}

class _LivingBackgroundState extends State<_LivingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    final isTestBinding = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (const bool.fromEnvironment('FLUTTER_TEST') || isTestBinding) {
      _ambientController.value = 0.25;
    } else {
      _ambientController.repeat();
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ambientController,
    builder: (context, child) => LayoutBuilder(
      builder: (context, constraints) {
        final t = _ambientController.value;
        final wave = math.sin(t * math.pi * 2);
        final driftX = wave * 1.8;
        final driftY = math.cos(t * math.pi * 2) * 1.1;
        final fluorescentPulse =
            0.025 +
            (math.sin(t * math.pi * 14) + 1) * 0.012 +
            (math.sin(t * math.pi * 34) > 0.97 ? 0.025 : 0);
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(driftX, driftY),
              child: Transform.scale(
                scale: 1.025,
                child: Image.asset(
                  widget.asset,
                  key: const Key('story-background-image'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            if (widget.ambientFlicker)
              IgnorePointer(
                child: Opacity(
                  key: const Key('orientation-light-flicker'),
                  opacity: fluorescentPulse.clamp(0.0, 0.08),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFF4C9),
                          Color(0x22FFE7A1),
                          Colors.transparent,
                        ],
                        stops: [0, 0.28, 0.66],
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.ambientFlicker)
              for (var index = 0; index < 12; index++)
                Positioned(
                  left:
                      ((index * 37) % 101) / 101 * constraints.maxWidth +
                      math.sin(t * math.pi * 2 + index) * 2,
                  top:
                      ((((index * 61) % 97) / 97 * constraints.maxHeight) +
                          t * 42) %
                      (constraints.maxHeight * 0.76),
                  child: IgnorePointer(
                    child: Opacity(
                      opacity:
                          0.11 +
                          ((math.sin(t * math.pi * 2 + index * 0.8) + 1) *
                              0.045),
                      child: Container(
                        key: index == 0
                            ? const Key('orientation-dust-motes')
                            : null,
                        width: index.isEven ? 2.2 : 1.4,
                        height: index.isEven ? 2.2 : 1.4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEDB5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
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
    final panelGradient = widget.narration
        ? const [Color(0xC21B2436), Color(0xAD111A2A)]
        : const [Color(0xBA172A42), Color(0xA6111E31)];
    final secondaryText = widget.narration
        ? const Color(0xFFE1ECFA)
        : const Color(0xFFEAF4FF);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _typingComplete ? null : _revealLine,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            key: const Key('story-dialogue-panel'),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: panelGradient,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xB8C8EDFF), width: 1.15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x5C020814),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0x344BC7F1),
                  blurRadius: 12,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(17, 23, 14, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.stageDirection?.trim().isNotEmpty ??
                          false) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(10, 6, 9, 6),
                          decoration: BoxDecoration(
                            color: const Color(0x304FD7FF),
                            border: const Border(
                              left: BorderSide(
                                color: Color(0xFF72DEFF),
                                width: 3,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.stageDirection!,
                            key: const Key('story-stage-direction'),
                            style: const TextStyle(
                              color: Color(0xFFF2FAFF),
                              fontFamily: 'Pretendard',
                              fontSize: 12.5,
                              height: 1.38,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.15,
                              shadows: [
                                Shadow(
                                  color: Color(0xCC000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
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
                          style: const TextStyle(
                            color: Color(0xFFF9FCFF),
                            fontFamily: 'Maplestory',
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.2,
                            shadows: [
                              Shadow(
                                color: Color(0xE6000000),
                                blurRadius: 5,
                                offset: Offset(0, 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!_typingComplete) ...[
                        const SizedBox(height: 7),
                        Text(
                          '화면을 누르면 문장이 한 번에 표시됩니다',
                          key: const Key('story-typewriter-hint'),
                          style: TextStyle(
                            color: secondaryText.withValues(alpha: 0.78),
                            fontFamily: 'Pretendard',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (_typingComplete && widget.choices.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...widget.choices.map(
                          (choice) => Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: choice,
                          ),
                        ),
                      ],
                      if (_typingComplete && widget.child != null) ...[
                        const SizedBox(height: 10),
                        widget.child!,
                      ],
                      if (_typingComplete && widget.onContinue != null) ...[
                        const SizedBox(height: 2),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            key: const Key('story-continue'),
                            onPressed: widget.onContinue,
                            label: const Text('다음'),
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(
                              Icons.keyboard_double_arrow_down_rounded,
                              size: 20,
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(70, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                              ),
                              foregroundColor: const Color(0xFF83E5FF),
                              textStyle: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: -15,
            child: Container(
              key: const Key('story-speaker-chip'),
              padding: const EdgeInsets.fromLTRB(13, 6, 16, 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xF03DB9E9), Color(0xE92D79C7)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(15),
                  bottomRight: Radius.circular(5),
                  bottomLeft: Radius.circular(5),
                ),
                border: Border.all(color: const Color(0xD9E6F9FF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66020A18),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                widget.speaker,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Maplestory',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  shadows: [Shadow(color: Color(0x99000000), blurRadius: 3)],
                ),
              ),
            ),
          ),
          Positioned(
            right: 15,
            top: 8,
            child: Row(
              children: [
                Container(width: 42, height: 2, color: const Color(0x996FDCFF)),
                const SizedBox(width: 5),
                Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8BE6FF),
                      border: Border.all(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
