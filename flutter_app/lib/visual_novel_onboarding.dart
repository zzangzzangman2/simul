part of 'main.dart';

const _onboardingBeatCount = 66;
const _maximumDialogueBeatCount = 240;
const _dialogueRuntimeStorageKey = 'future-academy-dialogue-runtime-v1';
const _dialogueBundleAsset = 'assets/dialogue/dialogue-editor-override.json';
const _dialoguePanelOpacityStorageKey =
    'future-academy-dialogue-panel-opacity-v2';
const _dialoguePanelOpacityMin = 0.0;
const _dialoguePanelOpacityMax = 0.74;
const _dialoguePanelOpacityDefault = _dialoguePanelOpacityMin;
final ValueNotifier<double> _dialoguePanelOpacity = ValueNotifier<double>(
  _dialoguePanelOpacityDefault,
);
const _orientationRosterBeat = 43;
const _orientationCompleteBeat = _onboardingBeatCount - 1;
const _introChoiceBeat = 120;
const _accountHallDepartureBeat = 131;
const _stateAccountActivationBeat = 134;
const _playerNameBeat = 137;
const _traitChoiceBeat = 144;
const _principleChoiceBeat = 147;
const _companyNameBeat = 150;
const _storyCharacterBottomInset = 104.0;
const _storyCharacterHeightFactor = 0.9;
const _storyCharacterAspectRatio = 2 / 3;
const _minhoCharacterAsset =
    'assets/images/historical_prologue/character_minho_farewell_v3.png';
const _minhoCharacterScale = 0.72;
const _maximumWheelBackSteps = 12;
const _wheelBackDebounce = Duration(milliseconds: 180);

double _storyCharacterScaleForAsset(String asset) =>
    asset == _minhoCharacterAsset ? _minhoCharacterScale : 1.0;

void _playStoryFeedback({bool strong = false}) {
  if (strong) {
    unawaited(HapticFeedback.mediumImpact());
  } else {
    unawaited(HapticFeedback.selectionClick());
  }
  unawaited(SystemSound.play(SystemSoundType.click));
}

double _clampDialoguePanelOpacity(double value) =>
    value.clamp(_dialoguePanelOpacityMin, _dialoguePanelOpacityMax).toDouble();

double _dialogueBackdropBlurSigma(double panelOpacity) {
  final progress =
      ((panelOpacity - _dialoguePanelOpacityMin) /
              (_dialoguePanelOpacityMax - _dialoguePanelOpacityMin))
          .clamp(0.0, 1.0)
          .toDouble();
  return 7 * progress * progress;
}

void _setDialoguePanelOpacity(double value) {
  _dialoguePanelOpacity.value = _clampDialoguePanelOpacity(value);
}

Future<void> _saveDialoguePanelOpacity() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(
      _dialoguePanelOpacityStorageKey,
      _dialoguePanelOpacity.value,
    );
  } catch (_) {
    // The control must remain usable even when browser storage is unavailable.
  }
}

typedef NewGameCreator =
    Future<void> Function(
      NewGameSetup setup,
      WorldLoadProgressCallback onProgress,
    );

class _DialogueOverride {
  const _DialogueOverride({
    required this.id,
    required this.speaker,
    required this.line,
    required this.direction,
    required this.date,
    required this.location,
    this.background,
    this.character,
  });

  final String id;
  final String speaker;
  final String line;
  final String direction;
  final String date;
  final String location;
  final String? background;
  final String? character;
}

class VisualNovelOnboardingScreen extends StatefulWidget {
  const VisualNovelOnboardingScreen({
    super.key,
    required this.onCreate,
    this.onExit,
    this.dialogueOverrideJson,
  });

  final NewGameCreator onCreate;
  final VoidCallback? onExit;
  final String? dialogueOverrideJson;

  @override
  State<VisualNovelOnboardingScreen> createState() =>
      _VisualNovelOnboardingScreenState();
}

class _VisualNovelOnboardingScreenState
    extends State<VisualNovelOnboardingScreen> {
  final _playerController = TextEditingController();
  final _companyController = TextEditingController();
  final List<String> _dialogueHistory = <String>[];
  final List<int> _beatNavigationHistory = <int>[];
  Map<int, _DialogueOverride> _dialogueOverrides =
      const <int, _DialogueOverride>{};
  int _beat = 0;
  int _dialogueEndBeat = _orientationCompleteBeat;
  String? _introChoice;
  StoryTrait? _trait;
  FamilyRule? _familyRule;
  bool _isCreating = false;
  String? _creationError;
  bool _isTraveling = false;
  bool _stateAccountActivated = false;
  Timer? _travelTimer;
  DateTime? _lastWheelBackAt;
  late final Future<void> _dialogueLoadFuture;
  WorldLoadProgress _creationProgress = const WorldLoadProgress(
    0.02,
    '제6기 국가계좌 정보를 정리하는 중…',
  );

  @override
  void initState() {
    super.initState();
    _dialogueLoadFuture = _loadDialogueOverrides();
    unawaited(_dialogueLoadFuture);
    unawaited(_loadDialoguePanelOpacity());
  }

  Future<void> _loadDialoguePanelOpacity() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.reload();
      _setDialoguePanelOpacity(
        preferences.getDouble(_dialoguePanelOpacityStorageKey) ??
            _dialoguePanelOpacityDefault,
      );
    } catch (_) {
      _setDialoguePanelOpacity(_dialoguePanelOpacityDefault);
    }
  }

  Map<int, _DialogueOverride> _decodeDialogueOverrides(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return const {};
    final rawScenes = decoded['scenes'];
    if (rawScenes is! List) return const {};

    final loaded = <int, _DialogueOverride>{};
    for (final rawScene in rawScenes) {
      if (rawScene is! Map<String, dynamic>) continue;
      final order = rawScene['order'];
      if (order is! num) continue;
      final beat = order.toInt() - 1;
      if (beat < 0 || beat >= _maximumDialogueBeatCount) continue;

      String text(String key) {
        final value = rawScene[key] is String ? rawScene[key] as String : '';
        return value
            .replaceAll(r'\r\n', '\n')
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\r', '\n');
      }

      String? asset(String key) {
        if (!rawScene.containsKey(key)) return null;
        final value = text(key).trim();
        const webAssetPrefix = '/play/assets/';
        return value.startsWith(webAssetPrefix)
            ? value.substring(webAssetPrefix.length)
            : value;
      }

      loaded[beat] = _DialogueOverride(
        id: text('id'),
        speaker: text('speaker'),
        line: text('line'),
        direction: text('direction'),
        date: text('date'),
        location: text('location'),
        background: asset('background'),
        character: asset('character'),
      );
    }
    return loaded;
  }

  Future<void> _loadDialogueOverrides() async {
    final loaded = <int, _DialogueOverride>{};
    final injectedRaw = widget.dialogueOverrideJson;
    if (injectedRaw != null) {
      loaded.addAll(_decodeDialogueOverrides(injectedRaw));
    }

    if (injectedRaw == null) {
      try {
        final bundledRaw = await rootBundle.loadString(_dialogueBundleAsset);
        loaded.addAll(_decodeDialogueOverrides(bundledRaw));
      } catch (_) {
        // An absent or damaged generated asset falls back to the source dialogue.
      }
    }

    if (injectedRaw == null) {
      try {
        final preferences = await SharedPreferences.getInstance();
        final raw = preferences.getString(_dialogueRuntimeStorageKey);
        if (raw != null && raw.trim().isNotEmpty) {
          final browserDraft = _decodeDialogueOverrides(raw);
          if (browserDraft.isNotEmpty) {
            loaded
              ..clear()
              ..addAll(browserDraft);
          }
        }
      } catch (_) {
        // A damaged browser draft must never prevent the prologue from starting.
      }
    }

    if (!mounted || loaded.isEmpty) return;
    setState(() {
      _dialogueOverrides = Map<int, _DialogueOverride>.unmodifiable(loaded);
      _dialogueEndBeat = loaded.keys.reduce(math.max);
    });
  }

  @override
  void dispose() {
    _travelTimer?.cancel();
    _playerController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  String get _background {
    final override = _dialogueOverrides[_beat]?.background?.trim();
    if (override != null && override.isNotEmpty) return override;
    return switch (_beat) {
      <= 4 =>
        'assets/images/cinematic_soft_painted/policy_1981/backgrounds/bg_policy_room_night_v1.png',
      <= 15 =>
        'assets/images/cinematic_soft_painted/policy_1981/backgrounds/bg_conference_night_v1.png',
      16 =>
        'assets/images/historical_prologue/bg_future_development_orphanage_1982_portrait_cartoon_v1.png',
      <= 22 =>
        'assets/images/historical_prologue/bg_orphanage_departure_2000_portrait_v1.png',
      <= 31 =>
        'assets/images/historical_prologue/bg_future_development_academy_gate_2000_portrait_v1.png',
      <= 53 =>
        'assets/images/historical_prologue/bg_future_development_orientation_hall_2000_portrait_v1.png',
      <= 57 =>
        'assets/images/cinematic_soft_painted/dormitory_2000/bg_future_academy_dorm_corridor_2000_v1.png',
      <= 63 =>
        'assets/images/cinematic_soft_painted/dormitory_2000/bg_future_academy_dorm_shared_room_day_2000_v1.png',
      64 =>
        'assets/images/cinematic_soft_painted/dormitory_2000/bg_future_academy_dorm_washroom_2000_v1.png',
      _ =>
        'assets/images/cinematic_soft_painted/dormitory_2000/bg_future_academy_dorm_shared_room_night_2000_v1.png',
    };
  }

  String get _location {
    final override = _dialogueOverrides[_beat]?.location.trim();
    if (override != null && override.isNotEmpty) return override;
    return switch (_beat) {
      <= 4 => '청와대 · 정책실',
      <= 15 => '청와대 · 미래전략 심야회의',
      16 => '국립 미래양성원 · 개원 기록',
      <= 22 => '새봄보육원 · 2층 다섯 번째 방',
      <= 31 => '국립 미래양성원 · 투자전문과정 정문',
      <= 53 => '국립 미래양성원 · 제6기 오리엔테이션 강당',
      <= 57 => '국립 미래양성원 · 기숙사 중앙 복도',
      <= 63 => '국립 미래양성원 · 제6기 공용 생활실',
      64 => '국립 미래양성원 · 기숙사 세면실',
      _ => '국립 미래양성원 · 제6기 공용 생활실',
    };
  }

  String get _dateLabel {
    final override = _dialogueOverrides[_beat]?.date.trim();
    if (override != null && override.isNotEmpty) return override;
    return switch (_beat) {
      <= 15 => '1981.01.12  ·  23:40',
      16 => '1982년  ·  미래양성계획 출범',
      <= 22 => '2000.01.02  ·  06:42',
      <= 31 => '2000.01.02  ·  07:31',
      <= 53 => '2000.01.02  ·  08:00',
      <= 57 => '2000.01.02  ·  09:05',
      <= 64 => '2000.01.02  ·  09:10',
      _ => '2000.01.02  ·  21:40',
    };
  }

  String? get _character {
    return switch (_beat) {
      1 =>
        'assets/images/cinematic_soft_painted/policy_1981/jeon_dugwang/02_listening_v1.png',
      5 =>
        'assets/images/cinematic_soft_painted/policy_1981/jeon_dugwang/05_pressure_v1.png',
      9 =>
        'assets/images/cinematic_soft_painted/policy_1981/jeon_dugwang/04_cold_laugh_v1.png',
      12 =>
        'assets/images/cinematic_soft_painted/policy_1981/jeon_dugwang/03_calculating_v1.png',
      14 =>
        'assets/images/cinematic_soft_painted/policy_1981/jeon_dugwang/01_signing_v1.png',
      2 =>
        'assets/images/cinematic_soft_painted/policy_1981/seo_muntae/01_policy_pitch_v1.png',
      7 =>
        'assets/images/cinematic_soft_painted/policy_1981/seo_muntae/04_exhausted_concession_v1.png',
      11 =>
        'assets/images/cinematic_soft_painted/policy_1981/seo_muntae/02_searching_chart_v1.png',
      13 =>
        'assets/images/cinematic_soft_painted/policy_1981/seo_muntae/03_rebuttal_v1.png',
      3 =>
        'assets/images/cinematic_soft_painted/policy_1981/baek_gihyeon/03_warning_v2.png',
      10 =>
        'assets/images/cinematic_soft_painted/policy_1981/baek_gihyeon/02_advice_v2.png',
      4 =>
        'assets/images/cinematic_soft_painted/policy_1981/kang_incheol/02_explain_v2.png',
      8 =>
        'assets/images/cinematic_soft_painted/policy_1981/yoon_mira/03_objection_v1.png',
      15 =>
        'assets/images/cinematic_soft_painted/policy_1981/yoon_mira/04_solution_v1.png',
      18 => _minhoCharacterAsset,
      19 => 'assets/images/protagonist_seed01/03_playful_grin.png',
      21 => 'assets/images/protagonist_seed01/17_holding_badge.png',
      26 => 'assets/images/protagonist_seed01/02_cheerful_laugh.png',
      40 => 'assets/images/protagonist_seed01/04_curious_question.png',
      48 => 'assets/images/protagonist_seed01/16_hands_on_hips.png',
      50 => 'assets/images/protagonist_seed01/22_victory_fist.png',
      22 =>
        'assets/images/historical_prologue/character_park_sunhee_farewell_v1.png',
      25 => 'assets/images/cinematic_soft_painted/sua/07_determined_v1.png',
      27 => 'assets/images/cinematic_soft_painted/sua/01_neutral_v1.png',
      29 => 'assets/images/cinematic_soft_painted/sua/04_playful_tease_v1.png',
      31 => 'assets/images/cinematic_soft_painted/sua/03_bright_laugh_v1.png',
      36 => 'assets/images/cinematic_soft_painted/sua/05_surprised_v1.png',
      38 => 'assets/images/cinematic_soft_painted/sua/06_worried_v1.png',
      47 => 'assets/images/cinematic_soft_painted/sua/02_warm_smile_v1.png',
      60 => 'assets/images/cinematic_soft_painted/sua/04_playful_tease_v1.png',
      56 =>
        'assets/images/historical_prologue/character_hakjun_orientation_v2.png',
      62 => 'assets/images/protagonist_seed01/04_curious_question.png',
      28 || 30 || 39 || 46 =>
        'assets/images/historical_prologue/character_hakjun_orientation_v2.png',
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
      _beat == 53 ||
      _beat == 55 ||
      _beat == 57 ||
      _beat == 59 ||
      _beat == 61 ||
      _beat == 63 ||
      _beat == 64;

  bool get _isAcademyReceptionistBeat =>
      _beat == _stateAccountActivationBeat || _beat == 135;

  String get _teacherPoseAsset => switch (_beat) {
    34 || 42 || 51 => 'assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png',
    35 || 43 || 49 => 'assets/images/주식선생님/24_포즈3_주인공그림체_공통슬롯_투명.png',
    37 || 44 => 'assets/images/주식선생님/23_포즈2_주인공그림체_공통슬롯_투명.png',
    45 || 53 || 64 => 'assets/images/주식선생님/26_포즈5_주인공그림체_공통슬롯_투명.png',
    55 || 63 => 'assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png',
    57 || 61 => 'assets/images/주식선생님/24_포즈3_주인공그림체_공통슬롯_투명.png',
    59 => 'assets/images/주식선생님/23_포즈2_주인공그림체_공통슬롯_투명.png',
    _ => 'assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png',
  };

  bool get _isNarration => _speaker == '이야기';

  bool get _isOrientationRosterScene =>
      _dialogueOverrides[_beat]?.id == 'scene-44' ||
      (_dialogueOverrides[_beat] == null && _beat == _orientationRosterBeat);

  String get _speaker =>
      _dialogueOverrides[_beat]?.speaker ??
      switch (_beat) {
        0 ||
        6 ||
        16 ||
        17 ||
        20 ||
        23 ||
        27 ||
        32 ||
        41 ||
        52 ||
        54 ||
        58 ||
        65 => '이야기',
        1 || 9 || 12 || 14 => '전두광',
        2 || 7 || 11 || 13 => '서문태 정책실장',
        3 || 10 => '백기현 비서실장',
        4 => '강인철 경제수석',
        5 => '전두광',
        8 || 15 => '윤미라 사회교육수석',
        18 => '민호',
        19 || 21 || 26 || 40 || 48 || 50 => '나',
        22 => '박선희 원장',
        24 || 33 => '아이들',
        25 || 29 || 31 || 36 || 38 || 47 => '수아',
        28 => '김학준',
        30 || 39 || 46 || 56 => '학준',
        60 => '수아',
        62 => '나',
        34 ||
        35 ||
        37 ||
        42 ||
        43 ||
        44 ||
        45 ||
        49 ||
        51 ||
        53 ||
        55 ||
        57 ||
        59 ||
        61 ||
        63 ||
        64 => '한서윤 선생님',
        _ => '이야기',
      };

  String get _line =>
      _dialogueOverrides[_beat]?.line ??
      switch (_beat) {
        0 =>
          '1981년 1월 12일 밤 11시 40분. 청와대 정책실의 불은 자정이 가까워져도 꺼지지 않았다. 보고서 다섯 권 가운데 하나만, 이상할 만큼 얇았다.',
        1 => '그래서. 당장은 멀쩡한데, 이대로 가면 나라가 망한다?',
        2 => '당장은 아닙니다. 하지만 지금만 보고 달리면 이십 년 뒤에는 남의 기술과 남의 돈에 나라의 목줄이 잡힙니다.',
        3 => '각하 앞에서 나라 앞날이 어둡다고 했으니, 자네 앞날도 같이 어두워질 수 있겠어.',
        4 =>
          '지금은 공장 세우고 물건을 찍는 쪽이 이깁니다. 하지만 미래에는 어떤 기술에 돈을 넣고, 어떤 회사를 살릴지 정하는 사람이 공장 몇 개보다 더 큰 힘을 갖게 됩니다.',
        5 => '공장도, 인구도, 법도 두꺼운데 아이들 보고서만 이 모양이군. 미래를 말하면서, 미래에 살 아이들은 뺐나?',
        6 => '수출산업, 인구전망, 국가계좌, 특별법. 네 권은 벽돌처럼 두꺼웠다. 「요보호아동 시설 현황」만 종잇장처럼 얇았다.',
        7 => '국가는 이미 아이들에게 밥과 잠자리를 줍니다. 이제는 내일을 고를 힘도 줘야 합니다.',
        8 => '미치셨습니까? 아이들을 국가가 키우는 자본이나 실험쥐로 보겠다는 겁니까? 실패하면 그 아이 인생은 누가 책임집니까!',
        9 => '먹이고 재우는 데서 끝내면 세금 낭비지. 스스로 돈을 벌게 만들면 투자가 되고.',
        10 => '핏덩이들에게 나랏돈을 줬다가 잃으면 혈세 낭비라 할 겁니다. 벌면 나라가 코 묻은 돈을 빼앗는다고 할 테고요.',
        11 =>
          '열 살, SEED 01부터 시작합니다. 원금은 만 원입니다. 작아서 우스워 보여도, 손실 이유를 감추기엔 충분히 큰 돈입니다.',
        12 => '잃으면?',
        13 => '아이 빚으로 남기지 않습니다. 대신 다음 달 주문 한도를 깎습니다. 벌면 일부를 국가가 회수하고요.',
        14 =>
          '이십 퍼센트. 나머지는 아이 몫. 대신 왜 샀고 왜 팔았는지 전부 쓰게 해. 잘한 이야기만 말고, 손실로 바닥까지 내려간 기록도.',
        15 => '그 80퍼센트는 시설 돈이 아닙니다. 아이 이름으로 묶어두고, 열아홉에 1원도 빠짐없이 넘기십시오.',
        16 => '이듬해, 국립 미래양성원이 문을 열었다. 환영 문구 대신 정문에는 한 줄이 걸렸다. 「기록 없는 판단은 우연이다」',
        17 =>
          '2000년 1월 2일 오전 6시 42분. 눈을 뜨자 천장의 누런 물자국이 먼저 보였다. 여섯 살 때부터 귀 잘린 토끼 같다고 생각했던 얼룩. 마지막 날인데도 물자국은 그냥 물자국이었다.',
        18 => '형아… 진짜 가?',
        19 => '응. 돈 세는 학교래. 그냥 주면 더 좋을 텐데, 세기만 시키면 손가락만 아프잖아.',
        20 =>
          '민호가 웃다가 낡은 가방을 보고 입을 다물었다. 나는 왕딱지 한 장만 챙기고 나머지는 민호 이불 위에 던졌다. 가방 안감을 들추자 낯선 쇳조각이 손끝에 걸렸다. 「제5기 · 17번」.',
        21 =>
          '이름은 칼로 긁어 지워져 있었다. 뒷면에는 더 이상한 말이 파여 있었다. 「17번을 믿지 마.」 …이게 17번 명찰인데, 누구를 믿지 말라는 거야?',
        22 =>
          '짐이 가볍다고 주눅 들지 마. 앞으로 채울 게 많다는 뜻이니까. 가서도 이상한 말은 그냥 넘기지 말고 두 번 물어. 그래도 이상하면 장부에 적어 둬. 말은 날아가도 글은 남으니까.',
        23 =>
          '버스는 서울을 벗어나 한참을 덜컹거렸다. 눈발 너머로 붉은 벽돌 건물이 나타났다. 학교치고는 담장이 길었고, 공장치고는 창문이 많았다.',
        24 => '“여기가 그 유명한 데래.”\n“고아원에서 추천받은 애들만 온다던데?”\n“입학식인데 왜 면접장보다 조용해?”',
        25 => '야, 가방 바퀴 하나가 눈을 계속 끌고 다녀.',
        26 => '일부러 눈사람 만드는 중이야. 본관 도착할 때쯤 머리까지 붙이려고.',
        27 =>
          '여자아이는 대꾸 대신 쪼그려 앉아 연필로 바퀴의 눈을 긁어냈다. 처음 보는 사이인데도 망설임이 없었다. 이름은 수아라고 했다.',
        28 => '정문에서 본관까지 420미터. 6분 안에 도착해야 하고, 뛰면 감점이야. 안내문 7쪽에 있어.',
        29 => '설명서 학준아, 별명 붙이면 안 된다는 규정도 있어?',
        30 => '…없어. 그리고 그렇게 부르지 마.',
        31 => '그럼 합법이네.',
        32 =>
          '강당에는 내빈석도 부모 자리도 없었다. 열 개의 의자만 반원으로 놓여 있었다. 무대 위 나무상자 하나가 더 수상해 보였다.',
        33 => '“남자 둘, 여자 여덟이래.”\n“자리도 성적순일까?”\n“아직 시험도 안 봤는데 무슨 성적이 있어.”',
        34 => '제6기 교육을 맡은 한서윤입니다. 인사는 조금 뒤에 하죠. 여러분 배에서 나는 소리가 더 급해 보이니까.',
        35 => '이 상자 안에는 단팥빵 하나와 500원짜리 동전이 있어요. 식당에서 빵은 300원입니다. 하나만 고르세요.',
        36 => '동전이요! 빵 사고도 200원 남잖아요.',
        37 => '좋아요. 그런데 식당 문은 두 시간 뒤, 열 시에 열립니다.',
        38 => '두 시간이요? …참을 수 있어요. 아마도.',
        39 =>
          '빵이 얼마나 남았는지, 열 시에 새 빵이 들어오는지부터 알아야 해요. 동전만 보고 고르기엔 모르는 게 너무 많아요.',
        40 => '그 전에 상자부터 열어봐야 하는 거 아니에요? 선생님이 단팥빵을 벌써 드셨을 수도 있잖아요.',
        41 => '아이들 사이에서 웃음이 터졌다. 한서윤은 화내지 않았다. 오히려 상자 뚜껑 위에 손을 얹고 나를 다시 보았다.',
        42 =>
          '그래요. 아는 게 달라지면 답도 달라집니다. 여기서 제일 먼저 배울 건 돈 버는 법이 아니라, 모르는 걸 모른다고 말하는 법이에요.',
        43 =>
          '여기 온 아이는 열 명, 남학생 두 명과 여학생 여덟 명입니다. 이번 기수는 여학생이 유난히 많네요. 모두 전국 보호시설의 추천을 받고, 오랫동안 생활 기록을 살핀 끝에 선발됐어요.',
        44 =>
          '여긴 간판만 바꾼 고아원도, 부자 흉내를 내는 학원도 아니에요. 숫자 뒤에 있는 사람과 거짓말을 보고, 자기 판단에 책임지는 법을 배우는 곳입니다.',
        45 => '그럼 첫 기록부터 남겨 볼까요? 자기가 왜 뽑혔다고 생각해요?',
        46 => '규칙을 빨리 외우고, 계산을 잘해서요.',
        47 => '사람 얼굴 보면 뭘 좋아하고 싫어하는지 금방 알아서요.',
        48 => '돈을 많이 벌 것 같아서 뽑은 거 아니에요?',
        49 => '지금 가진 돈은 얼마인데요?',
        50 => '왕딱지 한 장이요. 용 그려진 제일 센 거.',
        51 => '돈은 빵점. 솔직함은 합격. 뽑힌 이유는 내일부터 직접 찾아보죠.',
        52 =>
          '가장 어둡던 형광등이 한 번 떨리고 안정됐다. 열 개의 이름표가 같은 빛을 받았다. 주머니 속 5기 명찰만 혼자 차갑게 식어 있었다.',
        53 => '자, 이제 오늘은 첫날이니 기숙사 소개를 해줄게요. 짐 챙기고 모두 따라오세요.',
        54 =>
          '열 명의 의자가 한꺼번에 밀렸다. 강당 문 너머로 이어진 복도에는 젖은 운동화 자국과 낯선 방문들이 줄지어 있었다.',
        55 =>
          '복도 끝이 제6기 생활실이에요. 남학생 둘과 여학생 여덟이 방 하나를 함께 씁니다. 침상과 사물함은 한 사람에게 하나씩 돌아가요.',
        56 => '남학생하고 여학생이 정말 같은 방에서 잔다고요?',
        57 =>
          '같은 방에서 자지만 남의 침상과 사물함은 허락 없이 건드리지 않습니다. 옷을 갈아입거나 씻을 때는 잠금 칸막이실을 쓰고요. 불편한 일이 생기면 참지 말고 바로 말하세요.',
        58 => '한서윤이 가장 가까운 방문을 밀었다. 양쪽 벽의 이층침대와 열 개의 사물함, 길쭉한 공용 책상이 한눈에 들어왔다.',
        59 =>
          '아래층과 위층 중 원하는 자리를 먼저 골라 보세요. 자리를 바꾸고 싶을 때는 둘이 합의하고 생활기록표에 적으면 됩니다.',
        60 => '그럼 코 고는 사람은 남자든 여자든 창가 자리로 보내도 돼요?',
        61 => '보내는 건 안 되고, 본인에게 먼저 말하는 건 됩니다. 첫 생활 회의 안건으로 올려도 좋고요.',
        62 => '맨 위 침대는 먼저 올라가는 사람이 임자예요?',
        63 =>
          '오늘만 선착순이에요. 짐을 풀고 서로 이름부터 외우세요. 주식 수업은 내일 시작합니다. 주식이 뭔지도 모른다고 생각하고, 회사와 주식 한 주가 무엇인지부터 천천히 배울 거예요.',
        64 =>
          '세면대와 바구니도 한 사람당 하나씩입니다. 씻는 칸과 갈아입는 칸은 문을 잠그고 사용하세요. 같은 방을 쓴다는 말이 서로의 경계까지 없어진다는 뜻은 아니에요.',
        _ =>
          '밤 아홉 시 사십 분. 열 개의 침상에서 이불이 차례로 부풀었다. 남자 둘과 여자 여덟이 한 방을 쓰는 첫날, 낯선 숨소리 사이로 내일 배울 ‘주식’이라는 말만 오래 잠들지 않았다.',
      };

  String? get _stageDirection {
    final override = _dialogueOverrides[_beat];
    if (override != null) {
      final direction = override.direction.trim();
      return direction.isEmpty ? null : direction;
    }
    return switch (_beat) {
      1 => '전두광이 가장 얇은 보고서를 탁자 가운데로 밀었다.',
      2 => '밤샘으로 충혈된 서문태의 눈이 잠깐 흔들렸다.',
      3 => '백기현은 안경을 벗어 천천히 닦았다.',
      4 => '강인철의 연필이 1981년에서 2000년으로 긴 선을 그었다.',
      5 => '전두광이 「요보호아동 시설 현황」 표지를 손가락으로 두 번 두드렸다.',
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
      28 => '남색 규정집을 낀 김학준이 우리 옆에 바짝 붙었다.',
      29 => '수아가 눈을 가늘게 뜨고 김학준의 명찰을 읽었다.',
      30 => '학준의 귀끝이 규정집 표지보다 먼저 붉어졌다.',
      31 => '수아가 깔깔 웃으며 먼저 언덕을 뛰어올랐다.',
      32 => '오래된 형광등 아래, 이름표 열 장이 빈 의자를 지키고 있었다.',
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
      43 => '출석부가 펼쳐지고 남학생 두 칸, 여학생 여덟 칸이 차례로 확인됐다.',
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
      54 => '한서윤이 출석부를 덮고 복도 쪽으로 먼저 걸음을 옮겼다.',
      55 => '한서윤이 복도 끝 열린 방문을 가리켰다.',
      56 => '학준의 규정집이 가슴팍에서 조금 내려갔다.',
      57 => '한서윤은 열린 방문보다 먼저 복도 안쪽 칸막이실을 가리켰다.',
      58 => '낡은 경첩이 낮게 울리고 생활실의 따뜻한 공기가 복도로 흘러나왔다.',
      59 => '한서윤이 양쪽 이층침대와 사물함을 차례로 짚었다.',
      60 => '수아가 가장 안쪽 침대를 보며 코끝을 찡긋했다.',
      61 => '한서윤이 웃음을 참듯 출석부로 입가를 가렸다.',
      62 => '나는 창가 쪽 위층 침대 사다리에 손을 얹었다.',
      63 => '한서윤이 공용 책상 위 빈 장부를 펼쳐 보였다.',
      64 => '세면실 문 안쪽의 잠금쇠가 또각 소리를 냈다.',
      65 => '소등 뒤에도 창밖의 눈빛이 이층침대 난간에 가늘게 남아 있었다.',
      _ => null,
    };
  }

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

  void _rememberNavigationBeat(int beat) {
    if (_beatNavigationHistory.isNotEmpty &&
        _beatNavigationHistory.last == beat) {
      return;
    }
    _beatNavigationHistory.add(beat);
    if (_beatNavigationHistory.length > _maximumWheelBackSteps) {
      _beatNavigationHistory.removeAt(0);
    }
  }

  void _goBackOneBeat() {
    if (_isCreating || _isTraveling || _beatNavigationHistory.isEmpty) return;
    final previousBeat = _beatNavigationHistory.removeLast();
    if (previousBeat == _beat) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _playStoryFeedback();
    setState(() => _beat = previousBeat);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || event.scrollDelta.dy >= 0) return;
    final now = DateTime.now();
    final last = _lastWheelBackAt;
    if (last != null && now.difference(last) < _wheelBackDebounce) return;
    _lastWheelBackAt = now;
    _goBackOneBeat();
  }

  void _next() {
    if (_beat >= _dialogueEndBeat) return;
    final currentBeat = _beat;
    FocusManager.instance.primaryFocus?.unfocus();
    _rememberCurrentLine();
    _rememberNavigationBeat(currentBeat);
    _playStoryFeedback();
    if (_beat == _accountHallDepartureBeat) {
      _travelToAccountHall();
      return;
    }
    setState(() {
      if (_beat == currentBeat) {
        _beat = math.min(currentBeat + 1, _dialogueEndBeat);
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
      _beat = _dialogueEndBeat;
    });
    await _dialogueLoadFuture;
    if (!mounted || _beat == _dialogueEndBeat) return;
    setState(() => _beat = _dialogueEndBeat);
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
    return Listener(
      key: const Key('story-wheel-navigation-listener'),
      onPointerSignal: _handlePointerSignal,
      child: Scaffold(
        backgroundColor: const Color(0xFF171B2A),
        resizeToAvoidBottomInset: false,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final characterOverride = _dialogueOverrides[_beat]?.character;
            final sceneCharacterAsset = characterOverride != null
                ? (characterOverride.isEmpty ? null : characterOverride)
                : _isAcademyTeacherBeat
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
                Positioned.fill(
                  child: GestureDetector(
                    key: const Key('story-stage-advance-area'),
                    behavior: HitTestBehavior.translucent,
                    onTap: _isCreating || _isTraveling
                        ? null
                        : () => _activeNovelDialogueState?._handleExternalTap(),
                  ),
                ),
                SafeArea(
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _SceneLabel(
                        date: _dateLabel,
                        location: _location,
                        progress: (_beat + 1) / (_dialogueEndBeat + 1),
                      ),
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
                    top: -_storyCharacterBottomInset,
                    bottom: _storyCharacterBottomInset,
                    child: IgnorePointer(
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
      ),
    );
  }

  Widget _buildDialogue(BuildContext context) {
    if (_beat >= _dialogueEndBeat) return _orientationComplete();
    if (_isOrientationRosterScene) return _orientationRoster();
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
    onContinue: _next,
    child: Container(
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
                  value: '10명',
                  color: const Color(0xFF536A96),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _orientationStat(
                  key: const Key('orientation-male-count'),
                  label: '남학생',
                  value: '2명',
                  color: const Color(0xFF3F72A5),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _orientationStat(
                  key: const Key('orientation-female-count'),
                  label: '여학생',
                  value: '8명',
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
                '제6기 첫날 · 기숙사 안내 완료',
                style: TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 7),
              Text(
                '남학생 둘과 여학생 여덟이 한 생활실을 함께 씁니다.\n다음 수업은 주식이 무엇인지부터 시작합니다.',
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
    _rememberNavigationBeat(_beat);
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
    _rememberNavigationBeat(_beat);
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
    _rememberNavigationBeat(_beat);
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
          final characterWidth = (characterHeight * _storyCharacterAspectRatio)
              .clamp(0.0, constraints.maxWidth)
              .toDouble();
          final characterImageHeight = characterHeight
              .clamp(0.0, constraints.maxHeight - _storyCharacterBottomInset)
              .toDouble();
          return Align(
            alignment: alignment,
            child: SizedBox(
              key: characterKey,
              width: characterWidth,
              height: characterHeight,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform.scale(
                  key: const Key('story-character-scale'),
                  scale: _storyCharacterScaleForAsset(asset),
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: characterWidth,
                    height: characterImageHeight,
                    child: Image.asset(
                      key: const Key('story-character-image'),
                      asset,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
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

_NovelDialogueState? _activeNovelDialogueState;

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
    _activeNovelDialogueState = this;
    _dialoguePanelOpacity.addListener(_handlePanelOpacityChanged);
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

  void _handleExternalTap() {
    if (!_typingComplete) {
      _revealLine();
      return;
    }
    widget.onContinue?.call();
  }

  void _handlePanelOpacityChanged() {
    if (mounted) setState(() {});
  }

  void _updatePanelOpacity(double localX, double width) {
    if (width <= 0) return;
    final normalized = (localX / width).clamp(0.0, 1.0).toDouble();
    _setDialoguePanelOpacity(
      _dialoguePanelOpacityMin +
          ((_dialoguePanelOpacityMax - _dialoguePanelOpacityMin) * normalized),
    );
  }

  void _adjustPanelOpacity(double delta) {
    _setDialoguePanelOpacity(_dialoguePanelOpacity.value + delta);
    unawaited(_saveDialoguePanelOpacity());
  }

  @override
  void dispose() {
    if (identical(_activeNovelDialogueState, this)) {
      _activeNovelDialogueState = null;
    }
    _dialoguePanelOpacity.removeListener(_handlePanelOpacityChanged);
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
    final panelOpacity = _dialoguePanelOpacity.value;
    final panelStrength = (panelOpacity / _dialoguePanelOpacityMax)
        .clamp(0.0, 1.0)
        .toDouble();
    final backdropBlurSigma = _dialogueBackdropBlurSigma(panelOpacity);
    final panelGradient = widget.narration
        ? [
            const Color(0xFF1B2436).withValues(alpha: panelOpacity),
            const Color(0xFF111A2A).withValues(alpha: panelOpacity * 0.9),
          ]
        : [
            const Color(0xFF172A42).withValues(alpha: panelOpacity),
            const Color(0xFF111E31).withValues(alpha: panelOpacity * 0.9),
          ];
    final secondaryText = widget.narration
        ? const Color(0xFFE1ECFA)
        : const Color(0xFFEAF4FF);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleExternalTap,
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
                key: ValueKey(
                  'story-dialogue-backdrop-blur-${backdropBlurSigma.toStringAsFixed(2)}',
                ),
                filter: ui.ImageFilter.blur(
                  sigmaX: backdropBlurSigma,
                  sigmaY: backdropBlurSigma,
                ),
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
                            color: const Color(
                              0xFF4FD7FF,
                            ).withValues(alpha: 0.19 * panelStrength),
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
            right: 10,
            top: 0,
            child: Semantics(
              slider: true,
              label: '대화창 배경 농도',
              value: '${(panelOpacity * 100).round()}%',
              increasedValue:
                  '${((_clampDialoguePanelOpacity(panelOpacity + 0.08)) * 100).round()}%',
              decreasedValue:
                  '${((_clampDialoguePanelOpacity(panelOpacity - 0.08)) * 100).round()}%',
              onIncrease: () => _adjustPanelOpacity(0.08),
              onDecrease: () => _adjustPanelOpacity(-0.08),
              child: SizedBox(
                key: const Key('story-dialogue-opacity-control'),
                width: 72,
                height: 28,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const thumbSize = 8.0;
                    const horizontalInset = 5.0;
                    final trackWidth =
                        constraints.maxWidth - (horizontalInset * 2);
                    final normalized =
                        (panelOpacity - _dialoguePanelOpacityMin) /
                        (_dialoguePanelOpacityMax - _dialoguePanelOpacityMin);
                    final thumbLeft =
                        horizontalInset +
                        ((trackWidth - thumbSize) * normalized);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        _updatePanelOpacity(
                          details.localPosition.dx - horizontalInset,
                          trackWidth,
                        );
                        unawaited(_saveDialoguePanelOpacity());
                      },
                      onHorizontalDragUpdate: (details) => _updatePanelOpacity(
                        details.localPosition.dx - horizontalInset,
                        trackWidth,
                      ),
                      onHorizontalDragEnd: (_) =>
                          unawaited(_saveDialoguePanelOpacity()),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Positioned(
                            left: horizontalInset,
                            right: horizontalInset,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: const Color(0x996FDCFF),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          Positioned(
                            left: thumbLeft,
                            child: Transform.rotate(
                              angle: math.pi / 4,
                              child: Container(
                                key: const Key('story-dialogue-opacity-thumb'),
                                width: thumbSize,
                                height: thumbSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8BE6FF),
                                  border: Border.all(color: Colors.white70),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xAA39CFFF),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
