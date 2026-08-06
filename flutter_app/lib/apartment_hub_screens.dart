part of 'main.dart';

enum _ApartmentPlace { bedroom, livingRoom, kitchen, corridor, neighborhood }

const _hubDisplayFont = 'Maplestory';

String _apartmentDateLabel(DateTime date) {
  const weekdays = <String>['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
}

String _apartmentHudDateLabel(DateTime date) {
  const weekdays = <String>['월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
}

class _LobbyHeroinePresentation {
  const _LobbyHeroinePresentation({
    required this.smileAsset,
    required this.closeAsset,
    required this.morningLine,
    required this.marketLine,
    required this.eveningLine,
    required this.weekendLine,
    required this.friendlyAside,
    required this.closeAside,
    required this.trustedAside,
  });

  final String smileAsset;
  final String closeAsset;
  final String morningLine;
  final String marketLine;
  final String eveningLine;
  final String weekendLine;
  final String friendlyAside;
  final String closeAside;
  final String trustedAside;
}

const _lobbyHeroinePresentations = <String, _LobbyHeroinePresentation>{
  'kim_seoa': _LobbyHeroinePresentation(
    smileAsset:
        'assets/images/production_soft_painted/kim_seoa/02_soft_smile_agree_v1.png',
    closeAsset:
        'assets/images/production_soft_painted/kim_seoa/04_shy_appreciative_v1.png',
    morningLine: '오늘 날짜랑 할 일은 적어 뒀어. 빠진 약속이 있는지만 같이 보자.',
    marketLine: '장중 기록은 나중에 기억으로 메우기 어렵더라. 지금 한 줄만 남겨 둘래?',
    eveningLine: '오늘 장부는 여기까지 정리했어. 네가 마음에 걸리는 부분도 적어 줄까?',
    weekendLine: '오늘은 평일 기록 말고, 쉬는 동안 지키고 싶은 약속부터 정해도 돼.',
    friendlyAside: ' 전에 네가 말한 기준도 그대로 남겨 놨어.',
    closeAside: ' 네 얘기는 대충 적고 싶지 않아서 기다리고 있었어.',
    trustedAside: ' 네가 올 줄 알고 네 자리 옆은 비워 뒀어.',
  ),
  'lee_jian': _LobbyHeroinePresentation(
    smileAsset:
        'assets/images/production_soft_painted/lee_jian/02_playful_wink_v2.png',
    closeAsset:
        'assets/images/production_soft_painted/lee_jian/07_apologetic_boundary_v2.png',
    morningLine: 'PC는 공용 컴퓨터실에 있어. 다 같이 쓰는 자리니까 정리하고 가자.',
    marketLine: '숫자 튀는 데는 원인이 있어. 차트보다 체결부터 보면 빨라.',
    eveningLine: '기계는 껐고 공구도 셌어. 이제 네가 뭘 확인했는지 들으면 돼.',
    weekendLine: '정비할 건 끝냈어. 부품 구경 갈 거면 사람 적을 때 가자.',
    friendlyAside: ' 네가 옆에서 순서만 맞춰 주면 금방 끝나.',
    closeAside: ' 네 몫은 남겨 뒀어. 같이 만지는 편이 더 빠르니까.',
    trustedAside: ' 네가 오면 설명을 줄여도 돼서 편해.',
  ),
  'choi_iseo': _LobbyHeroinePresentation(
    smileAsset:
        'assets/images/production_soft_painted/choi_iseo/02_gentle_smile_v1.png',
    closeAsset:
        'assets/images/production_soft_painted/choi_iseo/04_shy_flustered_v1.png',
    morningLine: '라운지 쿠션 위치를 조금 바꿨어. 네가 앉기 불편하면 다시 둘게.',
    marketLine: '계속 보고 있으면 숫자 색만 남아. 잠깐 눈 쉬고 다시 골라도 돼.',
    eveningLine: '오늘 쓰던 건 정리했어. 조용히 있고 싶으면 말 안 해도 괜찮아.',
    weekendLine: '밖에 나가면 원단 가게 앞만 천천히 보고 싶어. 네 취향도 궁금하고.',
    friendlyAside: ' 네가 편한 쪽을 먼저 말해 줘.',
    closeAside: ' 네 자리는 내가 알아볼 수 있게 해 뒀어.',
    trustedAside: ' 기다리는 동안 네 생각이 나서 하나 더 만들었어.',
  ),
  'jung_arin': _LobbyHeroinePresentation(
    smileAsset:
        'assets/images/production_soft_painted/jung_arin/01_base_cheeky_v1.png',
    closeAsset:
        'assets/images/production_soft_painted/jung_arin/01_base_cheeky_v1.png',
    morningLine: '지금부터 장 시작 전까지 할 일 세 개. 우선순위는 네가 골라.',
    marketLine: '결정했으면 체결 조건까지 확인. 망설이는 시간도 비용이야.',
    eveningLine: '마감됐어. 잘한 건 남기고 틀린 건 내일 순서에 넣자.',
    weekendLine: '주말이라고 계획이 없는 건 아니야. 대신 네가 원하는 시간부터 말해.',
    friendlyAside: ' 이번엔 내가 통보하지 않고 먼저 물어보는 거야.',
    closeAside: ' 네 일정은 내 표에 따로 비워 뒀어.',
    trustedAside: ' 너랑 맞춘 계획이면 중간에 바뀌어도 다시 짜면 돼.',
  ),
  'park_haeun': _LobbyHeroinePresentation(
    smileAsset:
        'assets/images/production_soft_painted/park_haeun/02_gentle_smile_v3.png',
    closeAsset:
        'assets/images/production_soft_painted/park_haeun/07_embarrassed_v3.png',
    morningLine: '다들 바빠 보여도 도움을 원한다는 뜻은 아니야. 너부터 어떤지 말해 줘.',
    marketLine: '손익 보기 전에 숨 한번 쉬자. 지금 필요한 게 정보인지 위로인지도 다르니까.',
    eveningLine: '오늘은 네 얘기를 먼저 들을게. 나도 끝나면 내 얘기 조금 해도 돼?',
    weekendLine: '주말 계획은 같이 정해야 즐겁지. 쉬고 싶은 마음도 일정에 넣자.',
    friendlyAside: ' 네가 솔직하게 말해 주면 나도 덜 짐작해도 돼.',
    closeAside: ' 네 앞에서는 나도 괜찮은 척을 조금 덜 하게 돼.',
    trustedAside: ' 오늘 네가 오길 기다렸어. 그냥 같이 있고 싶어서.',
  ),
  'han_sua': _LobbyHeroinePresentation(
    smileAsset:
        'assets/images/production_soft_painted/han_sua/02_warm_smile_wave_v3.png',
    closeAsset:
        'assets/images/production_soft_painted/han_sua/03_bright_laugh_v3.png',
    morningLine: '오늘 분위기 좀 다르지 않아? 장 열리기 전에 다들 표정부터 볼까?',
    marketLine: '방금 다들 같은 숫자에서 멈췄어. 그게 기회인지 겁인지 확인해 보자.',
    eveningLine: '끝났다! 이제 숫자 말고 오늘 진짜 놀란 순간 하나씩 말하기.',
    weekendLine: '주말이면 새로운 데 가 보자. 당장 나가자는 건 아니고, 같이 계획부터!',
    friendlyAside: ' 네 반응은 이상하게 제일 먼저 보이더라.',
    closeAside: ' 사실 네가 오면 분위기가 어떻게 바뀔지 기다렸어.',
    trustedAside: ' 너한테는 장난 말고 진짜 걱정한 것도 말할 수 있어.',
  ),
  'oh_jiwoo': _LobbyHeroinePresentation(
    smileAsset:
        'assets/images/production_soft_painted/oh_jiwoo/02_cheerful_fang_wave_v1.png',
    closeAsset:
        'assets/images/production_soft_painted/oh_jiwoo/04_playful_counterpoint_v1.png',
    morningLine: '오늘 첫 가설. 다들 확신하는 종목일수록 한 번 더 의심해야 한다.',
    marketLine: '속보처럼 보이는 잡음이 제일 위험하지. 반대 설명부터 하나 세워 볼래?',
    eveningLine: '오늘 내 예측도 하나 틀렸어. 네가 웃기 전에 반례부터 같이 찾자.',
    weekendLine: '주말 토론 주제 접수 중. 결론 없는 얘기도 재미있으면 합격.',
    friendlyAside: ' 네 반론은 꽤 쓸 만해서 따로 적어 뒀고.',
    closeAside: ' 너한테 틀린 걸 들키는 건 전보다 덜 싫어.',
    trustedAside: ' 네 앞에서는 모른다고 말해도 다음 얘기가 이어지니까 좋아.',
  ),
  'yoon_chaea': _LobbyHeroinePresentation(
    smileAsset:
        'assets/images/production_soft_painted/yoon_chaea/02_soft_smile_wave_v1.png',
    closeAsset:
        'assets/images/production_soft_painted/yoon_chaea/04_shy_blush_v1.png',
    morningLine: '오늘 일정은 어제와 같아 보여도 전제가 하나 달라. 먼저 찾으면 말해 줄게.',
    marketLine: '가격 하나만 보면 늦어. 그 숫자를 만든 구조가 아직 유지되는지 봐.',
    eveningLine: '오늘 결과는 정리했어. 결론보다 네가 중간에 버린 가정이 궁금해.',
    weekendLine: '사람 적은 곳이면 나가도 괜찮아. 계획은 미리 세우는 편이 좋고.',
    friendlyAside: ' 네 생각은 결론 전에 들어도 괜찮을 것 같아.',
    closeAside: ' 아직 덜 정리됐지만 너한테는 중간부터 말해 볼게.',
    trustedAside: ' 내 계획에 네가 있는 건 이제 별도 가정이 아니야.',
  ),
};

enum _LobbyIdleGesture { nod, lean, perk, settle, playful, shy }

enum _LobbyTouchZone { face, torso, accessory }

enum _LobbyCharacterMotionMode { blinkOnly, generatedFullBodyFrames }

// The generated full-body frames remain catalogued below for later dialogue
// scenes. They are not suitable for continuous lobby animation because every
// frame redraws the whole character, so cross-fading them makes the body pop or
// briefly disappear. Keep the lobby portrait still and animate only blinking.
final _lobbyCharacterMotionMode = _LobbyCharacterMotionMode.blinkOnly;

bool get _usesGeneratedLobbyFrames =>
    _lobbyCharacterMotionMode ==
    _LobbyCharacterMotionMode.generatedFullBodyFrames;

class _LobbyMotionProfile {
  const _LobbyMotionProfile({
    required this.gestures,
    required this.motionFrames,
    required this.strength,
    required this.tempoMs,
    required this.faceLine,
    required this.torsoLine,
    required this.accessoryLine,
    required this.repeatLine,
  });

  final List<_LobbyIdleGesture> gestures;
  final List<String> motionFrames;
  final double strength;
  final int tempoMs;
  final String faceLine;
  final String torsoLine;
  final String accessoryLine;
  final String repeatLine;
}

const _lobbyMotionProfiles = <String, _LobbyMotionProfile>{
  'kim_seoa': _LobbyMotionProfile(
    gestures: <_LobbyIdleGesture>[
      _LobbyIdleGesture.nod,
      _LobbyIdleGesture.settle,
      _LobbyIdleGesture.shy,
    ],
    // The former notebook/uniform motion frames belonged to the retired
    // identity. The approved pink twin-bun set stays on its relationship pose
    // and uses the shared blink-only lobby motion.
    motionFrames: <String>[],
    strength: 0.82,
    tempoMs: 3200,
    faceLine: '앗, 가까이 왔네. 기록은 흐트러뜨리지 말아 줘.',
    torsoLine: '응, 같이 볼 부분은 여기야.',
    accessoryLine: '수첩이 궁금해? 오늘 약속부터 적어 뒀어.',
    repeatLine: '잠깐, 하나씩 말해 줘. 다 기억하고 싶어.',
  ),
  'lee_jian': _LobbyMotionProfile(
    gestures: <_LobbyIdleGesture>[
      _LobbyIdleGesture.lean,
      _LobbyIdleGesture.settle,
      _LobbyIdleGesture.perk,
    ],
    // The previous field-uniform tool-check frames were removed when Jian's
    // approved casual athletic set replaced that outfit. The lobby remains a
    // still portrait with blink-only motion.
    motionFrames: <String>[],
    strength: 0.94,
    tempoMs: 2800,
    faceLine: '손보다 먼저 말해. 조금 놀랐잖아.',
    torsoLine: '왜, 작업 순서가 궁금해?',
    accessoryLine: '공구는 세어 놨어. 만지기 전에 나한테 물어봐.',
    repeatLine: '계속 그러면 고장 원인보다 네 의도부터 검사한다?',
  ),
  'choi_iseo': _LobbyMotionProfile(
    gestures: <_LobbyIdleGesture>[
      _LobbyIdleGesture.shy,
      _LobbyIdleGesture.settle,
      _LobbyIdleGesture.lean,
    ],
    motionFrames: <String>[
      'assets/images/production_soft_painted/choi_iseo/10_lobby_thread_tidy_f0_v2.png',
      'assets/images/production_soft_painted/choi_iseo/10_lobby_thread_tidy_f1_v2.png',
      'assets/images/production_soft_painted/choi_iseo/10_lobby_thread_tidy_f2_v2.png',
      'assets/images/production_soft_painted/choi_iseo/10_lobby_thread_tidy_f3_v2.png',
    ],
    strength: 0.74,
    tempoMs: 3400,
    faceLine: '갑자기 가까워지면 조금 부끄러워.',
    torsoLine: '괜찮아. 불편한 건 아니야.',
    accessoryLine: '실이 걸릴 수 있으니까 천천히 봐 줘.',
    repeatLine: '잠깐만… 조금만 거리를 두고 이야기하면 안 될까?',
  ),
  'jung_arin': _LobbyMotionProfile(
    gestures: <_LobbyIdleGesture>[
      _LobbyIdleGesture.nod,
      _LobbyIdleGesture.perk,
      _LobbyIdleGesture.lean,
    ],
    motionFrames: <String>[
      'assets/images/production_soft_painted/jung_arin/10_lobby_tie_reset_f0_v2.png',
      'assets/images/production_soft_painted/jung_arin/10_lobby_tie_reset_f1_v2.png',
      'assets/images/production_soft_painted/jung_arin/10_lobby_tie_reset_f2_v2.png',
      'assets/images/production_soft_painted/jung_arin/10_lobby_tie_reset_f3_v2.png',
    ],
    strength: 0.98,
    tempoMs: 2600,
    faceLine: '집중 중이었어. 용건부터 말해.',
    torsoLine: '좋아, 확인했으면 다음 순서로 가자.',
    accessoryLine: '표에는 다 이유가 있어. 궁금한 칸을 먼저 짚어.',
    repeatLine: '반복 접촉은 비효율적이야. 한 번에 말해.',
  ),
  'park_haeun': _LobbyMotionProfile(
    gestures: <_LobbyIdleGesture>[
      _LobbyIdleGesture.perk,
      _LobbyIdleGesture.shy,
      _LobbyIdleGesture.nod,
    ],
    // The retired low-pigtail lobby frames were removed with the old
    // identity. The approved ash-blonde set uses still poses and blink-only
    // motion until a matching lobby sequence is approved.
    motionFrames: <String>[],
    strength: 0.88,
    tempoMs: 3200,
    faceLine: '응? 무슨 일 있어? 표정부터 볼게.',
    torsoLine: '여기 있어. 천천히 말해도 돼.',
    accessoryLine: '그게 궁금했구나. 같이 보면 더 쉬워.',
    repeatLine: '장난인 건 알겠는데, 나도 마음의 준비는 하게 해 줘.',
  ),
  'han_sua': _LobbyMotionProfile(
    gestures: <_LobbyIdleGesture>[
      _LobbyIdleGesture.playful,
      _LobbyIdleGesture.perk,
      _LobbyIdleGesture.lean,
    ],
    motionFrames: <String>[
      'assets/images/production_soft_painted/han_sua/10_lobby_stretch_f0_v2.png',
      'assets/images/production_soft_painted/han_sua/10_lobby_stretch_f1_v2.png',
      'assets/images/production_soft_painted/han_sua/10_lobby_stretch_f2_v2.png',
      'assets/images/production_soft_painted/han_sua/10_lobby_stretch_f3_v2.png',
    ],
    strength: 1.0,
    tempoMs: 3600,
    faceLine: '오, 지금 나 불렀지? 재미있는 얘기야?',
    torsoLine: '반응 확인 완료. 이제 네 얘기 차례!',
    accessoryLine: '그거보다 더 재미있는 걸 보여 줄까?',
    repeatLine: '계속 누르면 나도 똑같이 장난친다?',
  ),
  'oh_jiwoo': _LobbyMotionProfile(
    gestures: <_LobbyIdleGesture>[
      _LobbyIdleGesture.playful,
      _LobbyIdleGesture.lean,
      _LobbyIdleGesture.nod,
    ],
    // Jiwoo's legacy field-uniform frames are kept only in the external
    // backup. The active casual set uses the approved still poses and blink.
    motionFrames: <String>[],
    strength: 1.04,
    tempoMs: 2800,
    faceLine: '가설 하나. 지금 내 반응을 관찰 중이지?',
    torsoLine: '접촉 위치와 반응의 상관관계라… 기록할까?',
    accessoryLine: '좋은 관찰이야. 그런데 결론은 아직 비밀.',
    repeatLine: '반복 실험은 대조군이 있어야지. 일단 멈춤!',
  ),
  'yoon_chaea': _LobbyMotionProfile(
    gestures: <_LobbyIdleGesture>[
      _LobbyIdleGesture.settle,
      _LobbyIdleGesture.nod,
      _LobbyIdleGesture.shy,
    ],
    motionFrames: <String>[
      'assets/images/production_soft_painted/yoon_chaea/10_lobby_uniform_tidy_f0_v2.png',
      'assets/images/production_soft_painted/yoon_chaea/10_lobby_uniform_tidy_f1_v2.png',
      'assets/images/production_soft_painted/yoon_chaea/10_lobby_uniform_tidy_f2_v2.png',
      'assets/images/production_soft_painted/yoon_chaea/10_lobby_uniform_tidy_f3_v2.png',
    ],
    strength: 0.78,
    tempoMs: 3400,
    faceLine: '시선이 가까워졌네. 이유를 말해 줄래?',
    torsoLine: '확인했어. 필요한 이야기가 있으면 들어 줄게.',
    accessoryLine: '그 물건의 용도를 먼저 추측해 봐.',
    repeatLine: '충분히 관찰했을 텐데. 이제 말로 설명해 줘.',
  ),
};

class _LobbyMotionFrame {
  const _LobbyMotionFrame({
    this.offset = Offset.zero,
    this.rotation = 0,
    this.scale = 1,
  });

  final Offset offset;
  final double rotation;
  final double scale;
}

_LobbyMotionFrame _lobbyIdleGestureFrame({
  required _LobbyIdleGesture gesture,
  required double value,
  required double direction,
  required double strength,
}) {
  final lift = math.sin(value * math.pi) * strength;
  final ripple = math.sin(value * math.pi * 2) * lift;
  return switch (gesture) {
    _LobbyIdleGesture.nod => _LobbyMotionFrame(
      offset: Offset(direction * 0.25 * ripple, 1.45 * lift),
      rotation: direction * 0.0015 * ripple,
      scale: 1 - 0.0012 * lift,
    ),
    _LobbyIdleGesture.lean => _LobbyMotionFrame(
      offset: Offset(direction * 2.25 * lift, 0.35 * lift),
      rotation: direction * 0.0055 * lift,
    ),
    _LobbyIdleGesture.perk => _LobbyMotionFrame(
      offset: Offset(direction * 0.35 * ripple, -2.35 * lift),
      rotation: direction * 0.0018 * ripple,
      scale: 1 + 0.0028 * lift,
    ),
    _LobbyIdleGesture.settle => _LobbyMotionFrame(
      offset: Offset(direction * 0.55 * lift, 1.35 * lift),
      rotation: -direction * 0.0024 * lift,
      scale: 1 - 0.0014 * lift,
    ),
    _LobbyIdleGesture.playful => _LobbyMotionFrame(
      offset: Offset(direction * (2.0 * lift + 0.55 * ripple), -0.8 * lift),
      rotation: direction * 0.0065 * lift,
      scale: 1 + 0.0018 * lift,
    ),
    _LobbyIdleGesture.shy => _LobbyMotionFrame(
      offset: Offset(-direction * 1.1 * lift, 1.0 * lift),
      rotation: -direction * 0.0038 * lift,
      scale: 1 - 0.001 * lift,
    ),
  };
}

class _LobbyBlinkGeometry {
  const _LobbyBlinkGeometry({
    required this.leftEye,
    required this.rightEye,
    this.eyeWidth = 0.044,
    this.skinColor = const Color(0xFFFDEADE),
  });

  final Offset leftEye;
  final Offset rightEye;
  final double eyeWidth;
  final double eyeHeight = 0.024;
  final Color skinColor;
  final Color lidColor = const Color(0xFF66413F);
}

// The production lobby portraits share a 1024x1536 canvas, but each face is
// centered a little differently. These normalized anchors keep the blink over
// the eyes instead of applying an unnatural squash to the whole face.
const _lobbyBlinkGeometry = <String, _LobbyBlinkGeometry>{
  'kim_seoa': _LobbyBlinkGeometry(
    leftEye: Offset(0.489, 0.145),
    rightEye: Offset(0.553, 0.138),
    eyeWidth: 0.060,
    skinColor: Color(0xFFFDE7DF),
  ),
  'lee_jian': _LobbyBlinkGeometry(
    leftEye: Offset(0.476, 0.131),
    rightEye: Offset(0.549, 0.131),
    eyeWidth: 0.044,
    skinColor: Color(0xFFFDEDE3),
  ),
  'choi_iseo': _LobbyBlinkGeometry(
    leftEye: Offset(0.451, 0.133),
    rightEye: Offset(0.516, 0.133),
    eyeWidth: 0.044,
    skinColor: Color(0xFFFDE5DB),
  ),
  'jung_arin': _LobbyBlinkGeometry(
    leftEye: Offset(0.476, 0.139),
    rightEye: Offset(0.549, 0.139),
    eyeWidth: 0.047,
    skinColor: Color(0xFFFDEADE),
  ),
  'park_haeun': _LobbyBlinkGeometry(
    leftEye: Offset(0.476, 0.125),
    rightEye: Offset(0.540, 0.125),
    eyeWidth: 0.042,
    skinColor: Color(0xFFFCD8CA),
  ),
  'han_sua': _LobbyBlinkGeometry(
    leftEye: Offset(0.486, 0.133),
    rightEye: Offset(0.555, 0.143),
    eyeWidth: 0.043,
    skinColor: Color(0xFFFDEAE2),
  ),
  'oh_jiwoo': _LobbyBlinkGeometry(
    leftEye: Offset(0.475, 0.132),
    rightEye: Offset(0.544, 0.132),
    eyeWidth: 0.042,
    skinColor: Color(0xFFFCE4DA),
  ),
  'yoon_chaea': _LobbyBlinkGeometry(
    leftEye: Offset(0.478, 0.135),
    rightEye: Offset(0.549, 0.135),
    eyeWidth: 0.044,
    skinColor: Color(0xFFFEE4D6),
  ),
};

// Base and close portraits do not share the same face center as the friendly
// portrait. Keep those anchors per asset so relationship-stage pose changes do
// not make the eyelid drift across the cheek or hair.
const _lobbyBlinkGeometryByAsset = <String, _LobbyBlinkGeometry>{
  'assets/images/production_soft_painted/kim_seoa/01_neutral_notebook_v1.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.435, 0.142),
        rightEye: Offset(0.522, 0.137),
        eyeWidth: 0.062,
        skinColor: Color(0xFFFBE3DC),
      ),
  'assets/images/production_soft_painted/kim_seoa/04_shy_appreciative_v1.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.491, 0.167),
        rightEye: Offset(0.558, 0.154),
        eyeWidth: 0.060,
        skinColor: Color(0xFFFDE3DB),
      ),
  'assets/images/production_soft_painted/lee_jian/01_neutral_screwdriver_v2.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.476, 0.131),
        rightEye: Offset(0.550, 0.131),
        skinColor: Color(0xFFFDEDE3),
      ),
  'assets/images/production_soft_painted/lee_jian/07_apologetic_boundary_v2.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.467, 0.132),
        rightEye: Offset(0.539, 0.132),
        skinColor: Color(0xFFFDEDE4),
      ),
  'assets/images/production_soft_painted/choi_iseo/01_base_thread_v1.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.456, 0.128),
        rightEye: Offset(0.519, 0.128),
        skinColor: Color(0xFFFDE5DB),
      ),
  'assets/images/production_soft_painted/choi_iseo/04_shy_flustered_v1.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.438, 0.135),
        rightEye: Offset(0.502, 0.135),
        skinColor: Color(0xFFFDE8DF),
      ),
  'assets/images/production_soft_painted/jung_arin/01_base_cheeky_v1.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.474, 0.138),
        rightEye: Offset(0.546, 0.138),
        eyeWidth: 0.047,
        skinColor: Color(0xFFFDEADE),
      ),
  'assets/images/production_soft_painted/jung_arin/03_cheeky_laugh_v1.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.473, 0.141),
        rightEye: Offset(0.548, 0.141),
        eyeWidth: 0.047,
        skinColor: Color(0xFFFEE7DA),
      ),
  'assets/images/production_soft_painted/park_haeun/01_neutral_v3.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.471, 0.128),
        rightEye: Offset(0.534, 0.128),
        eyeWidth: 0.042,
        skinColor: Color(0xFFFCD8CA),
      ),
  'assets/images/production_soft_painted/park_haeun/07_embarrassed_v3.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.469, 0.135),
        rightEye: Offset(0.532, 0.126),
        eyeWidth: 0.042,
        skinColor: Color(0xFFFCE2D9),
      ),
  'assets/images/production_soft_painted/han_sua/01_neutral_wavy_v3.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.474, 0.133),
        rightEye: Offset(0.544, 0.141),
        eyeWidth: 0.043,
        skinColor: Color(0xFFFDEAE2),
      ),
  'assets/images/production_soft_painted/han_sua/03_bright_laugh_v3.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.478, 0.133),
        rightEye: Offset(0.547, 0.139),
        eyeWidth: 0.043,
        skinColor: Color(0xFFFDEDE6),
      ),
  'assets/images/production_soft_painted/oh_jiwoo/01_alert_neutral_v1.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.475, 0.132),
        rightEye: Offset(0.544, 0.132),
        eyeWidth: 0.042,
        skinColor: Color(0xFFFCE4DA),
      ),
  'assets/images/production_soft_painted/oh_jiwoo/04_playful_counterpoint_v1.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.456, 0.132),
        rightEye: Offset(0.528, 0.132),
        eyeWidth: 0.042,
        skinColor: Color(0xFFFCE4DA),
      ),
  'assets/images/production_soft_painted/yoon_chaea/01_neutral_tie_v1.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.472, 0.135),
        rightEye: Offset(0.542, 0.135),
        skinColor: Color(0xFFFEE4D6),
      ),
  'assets/images/production_soft_painted/yoon_chaea/04_shy_blush_v1.png':
      _LobbyBlinkGeometry(
        leftEye: Offset(0.471, 0.141),
        rightEye: Offset(0.540, 0.141),
        skinColor: Color(0xFFFDE1D5),
      ),
};

int _lobbyDateOrdinal(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

CohortGirlProfile _dailyLobbyHeroine(GameState state) {
  final seedOffset = state.simulationSeed.codeUnits.fold<int>(
    0,
    (value, unit) => (value * 31 + unit) & 0x7fffffff,
  );
  final index =
      (_lobbyDateOrdinal(state.currentDate) + seedOffset) %
      cohortGirlProfiles.length;
  return cohortGirlProfiles[index];
}

String _lobbyHeroineAsset({
  required CohortGirlProfile profile,
  required GirlRelationshipProgress progress,
  required bool reacting,
}) {
  final presentation = _lobbyHeroinePresentations[profile.id]!;
  if (reacting) {
    return progress.affection >= 40
        ? presentation.closeAsset
        : presentation.smileAsset;
  }
  return switch (progress.stage) {
    RelationshipStage.newClassmate => profile.portraitAsset!,
    RelationshipStage.friendly ||
    RelationshipStage.interested => presentation.smileAsset,
    _ => presentation.closeAsset,
  };
}

double _lobbyAffectionDistanceScale(RelationshipStage stage) => switch (stage) {
  RelationshipStage.newClassmate => 0.992,
  RelationshipStage.friendly => 0.996,
  RelationshipStage.interested => 1.0,
  RelationshipStage.close => 1.004,
  RelationshipStage.special => 1.007,
  RelationshipStage.trusted => 1.010,
};

double _lobbyAffectionDistanceY(RelationshipStage stage) => switch (stage) {
  RelationshipStage.newClassmate => 3.0,
  RelationshipStage.friendly => 1.8,
  RelationshipStage.interested => 0.4,
  RelationshipStage.close => -0.8,
  RelationshipStage.special => -1.5,
  RelationshipStage.trusted => -2.1,
};

int _lobbyBreathingDurationMs(int marketMinute) {
  if (marketMinute < krxOpenMinute) return 3400;
  if (marketMinute < krxCloseMinute) return 3600;
  if (marketMinute < 20 * 60) return 4100;
  return 4700;
}

int _lobbyEveningMotionDelayMs(int marketMinute) {
  if (marketMinute < krxCloseMinute) return 0;
  if (marketMinute < 20 * 60) return 700;
  return 1700;
}

_LobbyMotionFrame _lobbyTouchReactionFrame({
  required _LobbyTouchZone zone,
  required double value,
  required double direction,
  required int affection,
  required bool repeated,
}) {
  final pulse = math.sin(value * math.pi);
  final ripple = math.sin(value * math.pi * 2) * pulse;
  final distanceResponse = affection >= 60
      ? 1.0
      : affection < 20
      ? -0.8
      : 0.35;
  if (repeated) {
    return _LobbyMotionFrame(
      offset: Offset(-direction * (1.5 * pulse + 0.7 * ripple), -1.2 * pulse),
      rotation: -direction * 0.007 * pulse,
      scale: 1 - 0.0025 * pulse,
    );
  }
  return switch (zone) {
    _LobbyTouchZone.face => _LobbyMotionFrame(
      offset: Offset(-direction * 1.25 * pulse, -0.75 * pulse),
      rotation: -direction * 0.0045 * pulse,
      scale: 1 + distanceResponse * 0.0038 * pulse,
    ),
    _LobbyTouchZone.torso => _LobbyMotionFrame(
      offset: Offset(direction * 1.8 * pulse, 0.35 * pulse),
      rotation: direction * 0.0042 * pulse,
      scale: 1 + distanceResponse * 0.0024 * pulse,
    ),
    _LobbyTouchZone.accessory => _LobbyMotionFrame(
      offset: Offset(direction * 0.65 * ripple, 1.25 * pulse),
      rotation: -direction * 0.0028 * pulse,
      scale: 1 - 0.0012 * pulse,
    ),
  };
}

String _lobbyHeroineGreeting({
  required GameState state,
  required CohortGirlProfile profile,
  required GirlRelationshipProgress progress,
}) {
  final presentation = _lobbyHeroinePresentations[profile.id]!;
  final unread = state.phoneMessenger.unreadFor(profile.id);
  String line;
  if (unread > 0) {
    line = '톡으로 남긴 말 아직 못 봤지? 급한 건 아니니까 편할 때 확인해.';
  } else if (state.pendingDecisions.isNotEmpty) {
    line = '중요한 선택이 남아 있어. 천천히 읽고 네 생각대로 정하면 돼.';
  } else if (relationshipOutingAvailableOn(state.currentDate)) {
    line = presentation.weekendLine;
  } else if (state.marketMinute < krxOpenMinute) {
    line = presentation.morningLine;
  } else if (state.marketMinute < krxCloseMinute) {
    line = presentation.marketLine;
  } else {
    line = presentation.eveningLine;
  }
  final aside = switch (progress.stage) {
    RelationshipStage.newClassmate => '',
    RelationshipStage.friendly ||
    RelationshipStage.interested => presentation.friendlyAside,
    RelationshipStage.close ||
    RelationshipStage.special => presentation.closeAside,
    RelationshipStage.trusted => presentation.trustedAside,
  };
  return '$line$aside';
}

class ApartmentHubScreen extends StatefulWidget {
  const ApartmentHubScreen({
    super.key,
    required this.state,
    required this.onOpenMarket,
    required this.onOpenRealEstate,
    required this.onOpenBank,
    required this.onOpenPendingChoice,
    required this.onOpenLedger,
    required this.onOpenOrganization,
    required this.onOpenRelationships,
    required this.onOpenMessenger,
    required this.onOpenCalendar,
    required this.onOpenHomeImprovements,
    required this.onOpenWork,
    required this.activeSaveSlot,
    required this.lastSavedAt,
    required this.onOpenGameMenu,
    required this.onAdvanceHour,
    required this.onAdvanceDay,
    required this.onAdvanceBatch,
    required this.onOpenEnding,
    this.onTutorialComplete,
  });

  final GameState state;
  final VoidCallback onOpenMarket;
  final VoidCallback onOpenRealEstate;
  final VoidCallback onOpenBank;
  final VoidCallback onOpenPendingChoice;
  final VoidCallback onOpenLedger;
  final VoidCallback onOpenOrganization;
  final VoidCallback onOpenRelationships;
  final VoidCallback onOpenMessenger;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenHomeImprovements;
  final VoidCallback onOpenWork;
  final int activeSaveSlot;
  final DateTime? lastSavedAt;
  final VoidCallback onOpenGameMenu;
  final VoidCallback onAdvanceHour;
  final VoidCallback onAdvanceDay;
  final VoidCallback onAdvanceBatch;
  final VoidCallback onOpenEnding;
  final Future<void> Function()? onTutorialComplete;

  @override
  State<ApartmentHubScreen> createState() => _ApartmentHubScreenState();
}

class _ApartmentHubScreenState extends State<ApartmentHubScreen> {
  _ApartmentPlace _place = _ApartmentPlace.bedroom;
  late bool _tutorialVisible =
      widget.onTutorialComplete != null && !widget.state.story.tutorialSeen;

  Future<void> _dismissTutorial() async {
    if (!_tutorialVisible) return;
    setState(() => _tutorialVisible = false);
    await widget.onTutorialComplete?.call();
  }

  void _moveTo(_ApartmentPlace place) {
    if (place == _place) return;
    setState(() => _place = place);
  }

  void _openEveningChoice() => widget.onAdvanceDay();

  void _handleGuidanceAction() {
    if (widget.state.pendingDecisions.isNotEmpty) {
      widget.onOpenPendingChoice();
      return;
    }
    if (widget.state.currentDate.weekday >= DateTime.saturday ||
        widget.state.marketMinute >= marketDayEndMinute) {
      widget.onAdvanceDay();
      return;
    }
    if (widget.state.marketMinute < krxCloseMinute) {
      widget.onOpenMarket();
      return;
    }
    _openEveningChoice();
  }

  @override
  Widget build(BuildContext context) {
    final details = _ApartmentPlaceDetails.forPlace(_place);
    final lobbyHeroine = _place == _ApartmentPlace.bedroom
        ? _dailyLobbyHeroine(widget.state)
        : null;
    return DefaultTextStyle.merge(
      style: const TextStyle(
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        decorationThickness: 0,
      ),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              reverseDuration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final scale = Tween<double>(begin: 1.025, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: scale, child: child),
                );
              },
              child: _ApartmentPlaceScene(
                key: ValueKey(_place),
                place: _place,
                state: widget.state,
                onOpenMarket: widget.onOpenMarket,
                onOpenBank: widget.onOpenBank,
                onOpenLedger: widget.onOpenLedger,
                onOpenOrganization: widget.onOpenOrganization,
                onOpenHomeImprovements: widget.onOpenHomeImprovements,
                onOpenWork: widget.onOpenWork,
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(child: _ApartmentSceneVignette()),
            ),
            if (lobbyHeroine != null)
              Positioned.fill(
                top: 142,
                bottom: 64,
                child: _LobbyHeroineStage(
                  key: ValueKey(
                    'daily-lobby-${widget.state.currentDate.toIso8601String()}-${lobbyHeroine.id}',
                  ),
                  state: widget.state,
                  profile: lobbyHeroine,
                  progress: widget.state.relationships.progressFor(
                    lobbyHeroine.id,
                  ),
                  onOpenMessenger: widget.onOpenMessenger,
                  onOpenRelationships: widget.onOpenRelationships,
                ),
              ),
            Positioned(
              left: 6,
              top: 6,
              right: 6,
              child: _ApartmentLocationHeader(
                details: details,
                state: widget.state,
                activeSaveSlot: widget.activeSaveSlot,
                lastSavedAt: widget.lastSavedAt,
                onOpenGameMenu: widget.onOpenGameMenu,
              ),
            ),
            Positioned(
              left: 8,
              top: 92,
              right: 8,
              child: _ApartmentDayGuideCard(
                state: widget.state,
                onPressed: _handleGuidanceAction,
              ),
            ),
            Positioned(
              right: 7,
              top: 151,
              child: _ApartmentActionRail(
                hasPendingDecision: widget.state.pendingDecisions.isNotEmpty,
                campaignComplete: widget.state.campaignComplete,
                marketMinute: widget.state.marketMinute,
                messengerUnread: widget.state.phoneMessenger.totalUnread,
                onOpenMessenger: widget.onOpenMessenger,
                onOpenRelationships: widget.onOpenRelationships,
                onOpenCalendar: widget.onOpenCalendar,
                onAdvanceHour: widget.onAdvanceHour,
                onAdvanceDay: widget.onAdvanceDay,
                onAdvanceBatch: widget.onAdvanceBatch,
                onOpenEnding: widget.onOpenEnding,
                onHelp: () => setState(() => _tutorialVisible = true),
              ),
            ),
            Positioned(
              left: 6,
              right: 6,
              bottom: 6,
              child: _ApartmentLocationDock(current: _place, onMove: _moveTo),
            ),
            if (_tutorialVisible)
              Positioned.fill(
                child: _HubTutorialOverlay(onDone: _dismissTutorial),
              ),
          ],
        ),
      ),
    );
  }
}

class HomeComputerScreen extends StatefulWidget {
  const HomeComputerScreen({
    super.key,
    required this.state,
    required this.onOpenStockMarket,
    required this.onOpenCompanyManagement,
    required this.onOpenRealEstate,
    required this.onOpenBusiness,
    this.onCompleteNationalNetworkBriefing,
    this.onOpenCasino,
    this.onOpenHorseRace,
  });

  final GameState state;
  final Future<GameState> Function(GameState state) onOpenStockMarket;
  final Future<GameState> Function(GameState state) onOpenCompanyManagement;
  final Future<GameState> Function(GameState state) onOpenRealEstate;
  final Future<GameState> Function(GameState state) onOpenBusiness;
  final Future<GameState> Function()? onCompleteNationalNetworkBriefing;
  final Future<GameState> Function(GameState state)? onOpenCasino;
  final Future<GameState> Function(GameState state)? onOpenHorseRace;

  @override
  State<HomeComputerScreen> createState() => _HomeComputerScreenState();
}

class _HomeComputerScreenState extends State<HomeComputerScreen> {
  late GameState _state = widget.state;
  bool _nationalNetworkBriefingScheduled = false;
  bool _nationalNetworkBriefingShowing = false;

  bool get _nationalNetworkBriefingEligible => _state.story.marketTutorialSeen;

  bool get _nationalNetworkUnlocked => _state.story.nationalNetworkBriefingSeen;

  @override
  void initState() {
    super.initState();
    _scheduleNationalNetworkBriefing();
  }

  void _scheduleNationalNetworkBriefing() {
    if (_nationalNetworkBriefingScheduled ||
        _nationalNetworkBriefingShowing ||
        !_nationalNetworkBriefingEligible ||
        _nationalNetworkUnlocked) {
      return;
    }
    _nationalNetworkBriefingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nationalNetworkBriefingScheduled = false;
      if (mounted) _showNationalNetworkBriefing();
    });
  }

  Future<void> _showNationalNetworkBriefing() async {
    if (_nationalNetworkBriefingShowing ||
        !_nationalNetworkBriefingEligible ||
        _nationalNetworkUnlocked) {
      return;
    }
    _nationalNetworkBriefingShowing = true;
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _NationalNetworkBriefingDialog(),
    );
    if (!mounted) return;
    if (completed == true) {
      final save = widget.onCompleteNationalNetworkBriefing;
      final next = save == null
          ? _state.copyWith(
              story: _state.story.copyWith(
                storyFlags: <String, dynamic>{
                  ..._state.story.storyFlags,
                  'nationalNetworkBriefingSeen': true,
                  'nationalNetworkBriefingCompletedDay': _state.day,
                },
              ),
            )
          : await save();
      if (mounted) setState(() => _state = next);
    }
    _nationalNetworkBriefingShowing = false;
  }

  bool get _afterMarketLeisureOpen {
    final casino = _state.personalFinance.casino;
    final hasUnsettledCasino =
        casino.activeBlackjack != null || casino.activeCraps != null;
    if (hasUnsettledCasino) {
      return _nationalNetworkUnlocked &&
          _state.currentDate.weekday < DateTime.saturday &&
          _state.marketMinute >= krxCloseMinute &&
          _state.marketMinute <= marketDayEndMinute;
    }
    return _nationalNetworkUnlocked &&
        _state.currentDate.weekday < DateTime.saturday &&
        _state.marketMinute >= krxCloseMinute &&
        _state.marketMinute < marketDayEndMinute &&
        !weekdayEveningUsed(_state);
  }

  String get _afterMarketLeisureStatus {
    if (!_nationalNetworkBriefingEligible) {
      return '국가계좌 주식 실습을 먼저 마치세요';
    }
    if (!_nationalNetworkUnlocked) return '한서윤 운영관 사전 안내 대기';
    if (_state.currentDate.weekday >= DateTime.saturday) {
      return '휴장일 · 다음 평일 장 마감 뒤 이용';
    }
    final casino = _state.personalFinance.casino;
    if (casino.activeBlackjack != null || casino.activeCraps != null) {
      return '카지노 진행 중 · 온라인 세션 정산 필요';
    }
    if (_state.personalFinance.casino.roundsForDay(_state.day) > 0) {
      return '오늘 선택 완료 · 데시멀 카지노';
    }
    if (horseRaceDailyLimitReached(_state)) {
      return '오늘 선택 완료 · 국가망 경마';
    }
    if (weekdayEveningUsed(_state)) return '오늘 저녁 일정 완료';
    if (_state.marketMinute < krxCloseMinute) {
      return '주식장 마감 ${marketTimeLabel(krxCloseMinute)} 뒤 열림';
    }
    if (_state.marketMinute >= marketDayEndMinute) {
      return '오늘 접속 종료 · 다음 거래일 이용';
    }
    return '장 마감 완료 · 경마·카지노 선택 또는 그냥 넘어가기';
  }

  bool get _casinoSessionAvailable {
    if (widget.onOpenCasino == null || !_nationalNetworkUnlocked) return false;
    final casino = _state.personalFinance.casino;
    final hasUnsettledRound =
        casino.activeBlackjack != null || casino.activeCraps != null;
    if (hasUnsettledRound) {
      return _state.currentDate.weekday < DateTime.saturday &&
          _state.marketMinute >= krxCloseMinute &&
          _state.marketMinute <= marketDayEndMinute;
    }
    return _state.currentDate.weekday < DateTime.saturday &&
        _state.marketMinute >= krxCloseMinute &&
        _state.marketMinute <= marketDayEndMinute - casinoRoundMinutes &&
        !weekdayEveningUsed(_state);
  }

  String get _casinoSessionStatus {
    if (_state.personalFinance.casino.activeBlackjack != null) {
      return '블랙잭 핸드 정산 필요';
    }
    if (_state.personalFinance.casino.activeCraps != null) {
      return '크랩스 포인트 정산 필요';
    }
    if (!_nationalNetworkUnlocked) return '운영관 안내 후 접속';
    if (_state.currentDate.weekday >= DateTime.saturday) {
      return '평일 장 마감 후';
    }
    if (horseRaceDailyLimitReached(_state)) return '오늘 경마 선택';
    if (weekdayEveningUsed(_state)) return '오늘 저녁 행동 사용';
    if (_state.marketMinute < krxCloseMinute) return '15:00 개장';
    if (_state.marketMinute > marketDayEndMinute - casinoRoundMinutes) {
      return '오늘 이용 종료';
    }
    return '접속 가능 · 1판 30분';
  }

  bool get _horseRaceSessionAvailable =>
      widget.onOpenHorseRace != null &&
      _nationalNetworkUnlocked &&
      _state.currentDate.weekday < DateTime.saturday &&
      _state.marketMinute >= krxCloseMinute &&
      _state.marketMinute < marketDayEndMinute &&
      !weekdayEveningUsed(_state) &&
      _state.personalFinance.casino.roundsForDay(_state.day) == 0 &&
      !horseRaceDailyLimitReached(_state) &&
      horseRaceMaximumStakeForCash(_state.availableBrokerageCash) >=
          horseRaceMinStake;

  String get _horseRaceSessionStatus {
    if (!_nationalNetworkUnlocked) return '운영관 안내 후 접속';
    if (_state.currentDate.weekday >= DateTime.saturday) return '평일 장 마감 후';
    if (_state.personalFinance.casino.roundsForDay(_state.day) > 0) {
      return '오늘 카지노 선택';
    }
    if (horseRaceDailyLimitReached(_state)) {
      return '오늘 $horseRaceDailyBetLimit/$horseRaceDailyBetLimit회 완료';
    }
    if (weekdayEveningUsed(_state)) return '오늘 저녁 행동 사용';
    if (_state.marketMinute < krxCloseMinute) return '15:00 개장';
    if (_state.marketMinute >= marketDayEndMinute) return '오늘 이용 종료';
    if (horseRaceMaximumStakeForCash(_state.availableBrokerageCash) <
        horseRaceMinStake) {
      return '국가계좌 주문 가능금 부족';
    }
    return '베팅 ${horseRaceBetsToday(_state)}/$horseRaceDailyBetLimit회';
  }

  Future<void> _openStockMarket() async {
    final next = await widget.onOpenStockMarket(_state);
    if (mounted) {
      setState(() => _state = next);
      _scheduleNationalNetworkBriefing();
    }
  }

  Future<void> _openCompanyManagement() async {
    final next = await widget.onOpenCompanyManagement(_state);
    if (mounted) setState(() => _state = next);
  }

  Future<void> _openRealEstate() async {
    final next = await widget.onOpenRealEstate(_state);
    if (mounted) setState(() => _state = next);
  }

  Future<void> _openBusiness() async {
    final next = await widget.onOpenBusiness(_state);
    if (mounted) setState(() => _state = next);
  }

  Future<void> _openCasino() async {
    final open = widget.onOpenCasino;
    if (open == null) return;
    final casino = _state.personalFinance.casino;
    final resuming =
        casino.activeBlackjack != null || casino.activeCraps != null;
    if (!resuming) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('after-market-casino-gateway'),
          title: const Text('데시멀 카지노 국가망 접속'),
          content: const Text(
            '데시멀 PC에서 이안 딜러가 운영하는 국가 전용망 테이블에 접속합니다. 현장 이동과 외부 결제는 없고, 국가계좌 주문 가능금만 칩으로 바꿔 사용합니다.\n\n'
            '평일 장 마감 뒤 15:00~19:30 · 1판 30분 · 500원 단위 · 국가망 경마와 같은 날 중복 이용 불가',
          ),
          actions: [
            TextButton(
              key: const Key('after-market-casino-cancel'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            FilledButton.icon(
              key: const Key('after-market-casino-confirm'),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('국가망 테이블 접속'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final next = await open(_state);
    if (mounted) setState(() => _state = next);
  }

  Future<void> _openHorseRace() async {
    final open = widget.onOpenHorseRace;
    if (open == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('after-market-horse-gateway'),
        title: const Text('국가망 경마 접속'),
        content: const Text(
          '공용 PC의 국가망에서 원격 패독과 8두 출전표를 확인하고, 주문 가능금 중 최대 5천만원을 레저 기준금으로 잡아 2%·5%·10%·30% 중 하나로 전자 마권을 전송합니다. 최소 500원이며 정산 즉시 20:00으로 이동합니다.\n\n'
          '평일 장 마감 뒤 1일 1회 · 확정 이익 20% 국가 환수 · 카지노와 같은 날 중복 이용 불가',
        ),
        actions: [
          TextButton(
            key: const Key('after-market-horse-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton.icon(
            key: const Key('after-market-horse-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.satellite_alt_rounded),
            label: const Text('국가망 접속'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final next = await open(_state);
    if (mounted) setState(() => _state = next);
  }

  int get _shareholderCompanyCount => <String>{
    ..._state.positions
        .where((position) => position.units > 0)
        .map((position) => position.assetId),
    ..._state.shareholderGovernance.companies.values
        .where((company) => company.ownershipPct > 0)
        .map((company) => company.assetId),
  }.length;

  int get _shareholderMeetingCount => _state.shareholderGovernance.meetings
      .where((meeting) => meeting.status != ShareholderMeetingStatus.closed)
      .length;

  @override
  Widget build(BuildContext context) {
    final date = _state.currentDate;
    final hour = _state.marketMinute ~/ 60;
    final minute = _state.marketMinute % 60;
    final clock =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return Scaffold(
      key: const Key('home-computer-screen'),
      backgroundColor: const Color(0xFF071A35),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;
            final windowHeight = (constraints.maxHeight - (compact ? 148 : 190))
                .clamp(280.0, 360.0);
            return Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF075B79),
                        Color(0xFF1E91A5),
                        Color(0xFF0E405F),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  right: -58,
                  top: 72,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 210,
                      height: 210,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x247DE5D5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: -72,
                  bottom: 70,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 230,
                      height: 230,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x1FFFE29A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 8,
                  top: 8,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.computer_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '새천년 홈 PC',
                              style: TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Colors.white,
                                fontSize: 15,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '내 컴퓨터 · 온라인',
                              style: TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Color(0xFFD2F4F3),
                                fontSize: 9,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('home-computer-close'),
                        tooltip: '컴퓨터 화면 닫기',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.power_settings_new_rounded),
                        color: Colors.white,
                        iconSize: 23,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  top: compact ? 58 : 78,
                  height: windowHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1E8),
                      border: Border.all(
                        color: const Color(0xFFE6F4FF),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66031220),
                          blurRadius: 18,
                          offset: Offset(0, 9),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Column(
                        children: [
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF153B78), Color(0xFF2E70B5)],
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.language_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    '온라인 자산센터',
                                    style: TextStyle(
                                      fontFamily: _hubDisplayFont,
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _ComputerWindowDot(color: Color(0xFFBBD7F6)),
                                SizedBox(width: 5),
                                _ComputerWindowDot(color: Color(0xFFFFD66F)),
                                SizedBox(width: 5),
                                _ComputerWindowDot(color: Color(0xFFFF8B83)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                14,
                                14,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '실행할 프로그램을 선택하세요',
                                    style: TextStyle(
                                      fontFamily: _hubDisplayFont,
                                      color: _ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _nationalNetworkUnlocked
                                        ? '자산 프로그램과 국가망 확률시장은 같은 게임 시간과 국가계좌를 공유합니다.'
                                        : '주식거래·주주권·회사경영·부동산·상권 프로그램은 현재 상태를 공유합니다.',
                                    maxLines: 2,
                                    style: const TextStyle(
                                      fontFamily: _hubDisplayFont,
                                      color: Color(0xFF697486),
                                      fontSize: 9.5,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 13),
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, appConstraints) {
                                        return Column(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: _ComputerAppTile(
                                                      interactionKey: const Key(
                                                        'computer-stock-market-app',
                                                      ),
                                                      icon: Icons
                                                          .candlestick_chart_rounded,
                                                      iconColor: const Color(
                                                        0xFF55C7A1,
                                                      ),
                                                      title: '미래 증권',
                                                      subtitle: '주식시장',
                                                      status: '시세 · 주문',
                                                      onTap: _openStockMarket,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: _ComputerAppTile(
                                                      interactionKey: const Key(
                                                        'computer-company-management-app',
                                                      ),
                                                      icon: Icons
                                                          .account_balance_rounded,
                                                      iconColor: const Color(
                                                        0xFF8D72D8,
                                                      ),
                                                      title: '주주·회사관리',
                                                      subtitle: '보유회사·주총일정',
                                                      status:
                                                          '회사 $_shareholderCompanyCount'
                                                          ' · 일정 $_shareholderMeetingCount',
                                                      onTap:
                                                          _openCompanyManagement,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: _ComputerAppTile(
                                                      interactionKey: const Key(
                                                        'computer-real-estate-app',
                                                      ),
                                                      icon: Icons
                                                          .apartment_rounded,
                                                      iconColor: const Color(
                                                        0xFFFFA45C,
                                                      ),
                                                      title: '한마음 부동산',
                                                      subtitle:
                                                          realEstateAccessUnlocked(
                                                            _state,
                                                          )
                                                          ? '서울·경기 매물'
                                                          : '5월 매물 이야기 필요',
                                                      status:
                                                          realEstateAccessUnlocked(
                                                            _state,
                                                          )
                                                          ? '지도 · 계약'
                                                          : '🔒 스토리 잠김',
                                                      onTap:
                                                          realEstateAccessUnlocked(
                                                            _state,
                                                          )
                                                          ? _openRealEstate
                                                          : null,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: _ComputerAppTile(
                                                      interactionKey: const Key(
                                                        'computer-business-app',
                                                      ),
                                                      icon: Icons
                                                          .storefront_rounded,
                                                      iconColor: const Color(
                                                        0xFFFF86A8,
                                                      ),
                                                      title: '동네상권넷',
                                                      subtitle:
                                                          businessMarketAccessUnlocked(
                                                            _state,
                                                          )
                                                          ? businessOperationsUnlocked(
                                                                  _state,
                                                                )
                                                                ? '창업 · 점포운영'
                                                                : '상권 관찰 · 4월 운영 해금'
                                                          : '3월 상권 이야기 필요',
                                                      status:
                                                          businessMarketAccessUnlocked(
                                                            _state,
                                                          )
                                                          ? '점포 ${_state.businesses.activeBusinesses.length}'
                                                                ' · 사건 ${_state.businesses.pendingEvents.length}'
                                                          : '🔒 스토리 잠김',
                                                      onTap:
                                                          businessMarketAccessUnlocked(
                                                            _state,
                                                          )
                                                          ? _openBusiness
                                                          : null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (widget.onOpenCasino != null ||
                                                widget.onOpenHorseRace !=
                                                    null) ...[
                                              const SizedBox(height: 8),
                                              _AfterMarketLeisureBanner(
                                                open: _afterMarketLeisureOpen,
                                                status:
                                                    _afterMarketLeisureStatus,
                                              ),
                                              const SizedBox(height: 8),
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    if (widget.onOpenCasino !=
                                                        null)
                                                      Expanded(
                                                        child: _ComputerAppTile(
                                                          interactionKey: const Key(
                                                            'computer-casino-live-app',
                                                          ),
                                                          icon: Icons
                                                              .casino_rounded,
                                                          iconColor:
                                                              const Color(
                                                                0xFFD5A64E,
                                                              ),
                                                          title: '데시멀 카지노',
                                                          subtitle:
                                                              'PC 온라인 · 국가계좌 칩',
                                                          status:
                                                              _casinoSessionStatus,
                                                          onTap:
                                                              _casinoSessionAvailable
                                                              ? _openCasino
                                                              : null,
                                                        ),
                                                      ),
                                                    if (widget.onOpenCasino !=
                                                            null &&
                                                        widget.onOpenHorseRace !=
                                                            null)
                                                      const SizedBox(width: 8),
                                                    if (widget
                                                            .onOpenHorseRace !=
                                                        null)
                                                      Expanded(
                                                        child: _ComputerAppTile(
                                                          interactionKey: const Key(
                                                            'computer-horse-racing-app',
                                                          ),
                                                          icon: Icons
                                                              .emoji_events_rounded,
                                                          iconColor:
                                                              const Color(
                                                                0xFF2E7D5A,
                                                              ),
                                                          title: '국가망 경마',
                                                          subtitle:
                                                              'PC 원격 · 전자 마권',
                                                          status:
                                                              _horseRaceSessionStatus,
                                                          onTap:
                                                              _horseRaceSessionAvailable
                                                              ? _openHorseRace
                                                              : null,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        );
                                      },
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
                Positioned(
                  left: 7,
                  right: 7,
                  bottom: 7,
                  height: 48,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xEDE4E8E0),
                      border: Border.all(color: const Color(0xFFFFFFFF)),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55031220),
                          blurRadius: 9,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A8D67),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.window_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '시작',
                                style: TextStyle(
                                  fontFamily: _hubDisplayFont,
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Icon(
                          Icons.signal_wifi_4_bar_rounded,
                          color: Color(0xFF26415E),
                          size: 19,
                        ),
                        const Spacer(),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              clock,
                              style: const TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Color(0xFF20344F),
                                fontSize: 10,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Color(0xFF5B6776),
                                fontSize: 8,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NationalNetworkBriefingBeat {
  const _NationalNetworkBriefingBeat({required this.title, required this.body});

  final String title;
  final String body;
}

const _nationalNetworkBriefingBeats = <_NationalNetworkBriefingBeat>[
  _NationalNetworkBriefingBeat(
    title: '국가계좌에 붙는 두 개의 온라인 시장',
    body:
        '한서윤 운영관: “주식 실습을 마친 후부터 PC에 국가망 경마와 데시멀 카지노가 열립니다. 둘 다 현장에 가는 서비스가 아니라, 프로젝트 내부 PC에서만 접속하는 확률시장입니다.”',
  ),
  _NationalNetworkBriefingBeat(
    title: '국가망 경마 · 레저 기준금의 2~30%',
    body:
        '한서윤 운영관: “단승·연승·복승 중 하나를 고르고, 주문 가능금 중 최대 5천만원을 레저 기준금으로 잡아 2%·5%·10%·30% 중 하나를 전자 마권으로 삽니다. 최소는 500원이고 하루 한 번만 가능합니다.”',
  ),
  _NationalNetworkBriefingBeat(
    title: '데시멀 카지노 · 보유 칩의 2~30%',
    body:
        '한서윤 운영관: “국가계좌 돈을 온라인 칩으로 먼저 바꾸고, 이안 딜러가 진행하는 여섯 테이블 중 하나를 고릅니다. 실제 베팅은 보유 칩의 2%·5%·10%·30%를 500원 단위로 내린 금액 중 하나입니다. 최소 베팅은 500원이고, 한 판은 30분입니다.”',
  ),
  _NationalNetworkBriefingBeat(
    title: '이기면 20% 국가 환수 · 지면 수수료 0원',
    body:
        '한서윤 운영관: “원금이 아닌 확정 이익에서만 20%를 국가가 환수합니다. 나머지 80%는 다시 국가계좌로 돌아옵니다. 손실이나 본전에는 환수가 없지만, 잃은 돈도 국가계좌에서 실제로 빠집니다. 경마와 카지노는 같은 날 하나만 고르세요.”',
  ),
];

class _NationalNetworkBriefingDialog extends StatefulWidget {
  const _NationalNetworkBriefingDialog();

  @override
  State<_NationalNetworkBriefingDialog> createState() =>
      _NationalNetworkBriefingDialogState();
}

class _NationalNetworkBriefingDialogState
    extends State<_NationalNetworkBriefingDialog> {
  int _page = 0;

  bool get _showUnlock => _page >= _nationalNetworkBriefingBeats.length;

  void _advance() {
    if (_showUnlock) {
      Navigator.of(context).pop(true);
      return;
    }
    GameAudio.instance.playSfx(GameSfx.select);
    setState(() => _page += 1);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Dialog(
      key: const Key('national-network-briefing-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: math.min(680, screen.height - 40),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F0E5),
            border: Border.all(color: const Color(0xFF263854), width: 2),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  color: const Color(0xFF1B2B45),
                  child: Text(
                    _showUnlock
                        ? '국가망 접속 승인'
                        : '한서윤 운영관 · 사전 안내 ${_page + 1}/${_nationalNetworkBriefingBeats.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: _hubDisplayFont,
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _showUnlock
                        ? const _NationalNetworkUnlockEffect()
                        : _NationalNetworkTeacherPage(
                            key: ValueKey(_page),
                            beat: _nationalNetworkBriefingBeats[_page],
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: Key(
                        _showUnlock
                            ? 'national-network-briefing-complete'
                            : 'national-network-briefing-next',
                      ),
                      onPressed: _advance,
                      icon: Icon(
                        _showUnlock
                            ? Icons.power_settings_new_rounded
                            : Icons.navigate_next_rounded,
                      ),
                      label: Text(
                        _showUnlock
                            ? 'PC 국가망 열기'
                            : _page == _nationalNetworkBriefingBeats.length - 1
                            ? '안내 확인 · 잠금해제'
                            : '다음 설명',
                      ),
                    ),
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

class _NationalNetworkTeacherPage extends StatelessWidget {
  const _NationalNetworkTeacherPage({super.key, required this.beat});

  final _NationalNetworkBriefingBeat beat;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 210,
          child: Image.asset(
            'assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png',
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, _, _) => const Icon(
              Icons.school_rounded,
              size: 96,
              color: Color(0xFF526A8E),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          beat.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: _hubDisplayFont,
            color: Color(0xFF1C2F4A),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF9AA9BA)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            beat.body,
            style: const TextStyle(
              fontFamily: _hubDisplayFont,
              color: Color(0xFF26364C),
              fontSize: 12,
              height: 1.55,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _NationalNetworkUnlockEffect extends StatelessWidget {
  const _NationalNetworkUnlockEffect();

  @override
  Widget build(BuildContext context) => Center(
    child: TweenAnimationBuilder<double>(
      key: const Key('national-network-unlock-effect'),
      tween: Tween(begin: 0.72, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF193B5E),
                border: Border.all(color: const Color(0xFFFFCF66), width: 4),
                boxShadow: const [
                  BoxShadow(color: Color(0x88FFD15D), blurRadius: 28),
                ],
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                size: 58,
                color: Color(0xFFFFD66F),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              '잠금해제',
              style: TextStyle(
                fontFamily: _hubDisplayFont,
                color: Color(0xFFB37A13),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '국가망 확률시장',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _hubDisplayFont,
                color: Color(0xFF1D304B),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '국가망 경마 · 데시멀 온라인 카지노\n국가계좌 전용 · 확정 이익 20% 국가 환수',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _hubDisplayFont,
                color: Color(0xFF5D6878),
                fontSize: 12,
                height: 1.55,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AfterMarketLeisureBanner extends StatelessWidget {
  const _AfterMarketLeisureBanner({required this.open, required this.status});

  final bool open;
  final String status;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('after-market-leisure-banner'),
    constraints: const BoxConstraints(minHeight: 30),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: open ? const Color(0xFFE3F3E8) : const Color(0xFFE8EDF4),
      border: Border.all(
        color: open ? const Color(0xFF6E9E7C) : const Color(0xFF8795A8),
      ),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Icon(
          open ? Icons.lock_open_rounded : Icons.schedule_rounded,
          size: 15,
          color: open ? const Color(0xFF2E7150) : const Color(0xFF536276),
        ),
        const SizedBox(width: 6),
        const Text(
          '국가망 확률시장',
          style: TextStyle(
            fontFamily: _hubDisplayFont,
            color: Color(0xFF27394F),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            status,
            key: const Key('after-market-leisure-status'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: _hubDisplayFont,
              color: open ? const Color(0xFF2E7150) : const Color(0xFF5E6B7C),
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ComputerAppTile extends StatelessWidget {
  const _ComputerAppTile({
    required this.interactionKey,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  final Key interactionKey;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final dense = constraints.maxWidth < 112 || constraints.maxHeight < 130;
      final compact = constraints.maxHeight < 82;
      final iconSize = compact ? 20.0 : (dense ? 34.0 : 58.0);
      return SizedBox.expand(
        child: Opacity(
          opacity: onTap == null ? 0.62 : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: interactionKey,
              onTap: onTap,
              borderRadius: BorderRadius.circular(7),
              child: Ink(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAF4),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: const Color(0xFF94A4B7),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.white, offset: Offset(-2, -2)),
                    BoxShadow(color: Color(0xFF9AA7AF), offset: Offset(2, 2)),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 4 : (dense ? 5 : 9),
                    compact ? 2 : (dense ? 8 : 12),
                    compact ? 4 : (dense ? 5 : 9),
                    compact ? 2 : (dense ? 7 : 9),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: const Color(0xFF172C4A),
                          borderRadius: BorderRadius.circular(
                            compact ? 6 : (dense ? 10 : 12),
                          ),
                          border: Border.all(color: const Color(0xFF6E89AC)),
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: compact ? 14 : (dense ? 22 : 34),
                        ),
                      ),
                      SizedBox(height: compact ? 2 : (dense ? 7 : 10)),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: _hubDisplayFont,
                          color: _ink,
                          fontSize: compact ? 8.5 : (dense ? 10 : 12),
                          height: 1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.25,
                        ),
                      ),
                      if (!compact) ...[
                        SizedBox(height: dense ? 4 : 5),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _hubDisplayFont,
                            color: Color(0xFF586476),
                            fontSize: dense ? 8 : 9,
                            height: 1,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 4 : (dense ? 5 : 7),
                          vertical: compact ? 1 : (dense ? 3 : 4),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E9E4),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          status,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: _hubDisplayFont,
                            color: Color(0xFF486070),
                            fontSize: compact ? 6.5 : (dense ? 7.2 : 8),
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ComputerWindowDot extends StatelessWidget {
  const _ComputerWindowDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: const Color(0x66000000)),
    ),
    child: const SizedBox(width: 13, height: 13),
  );
}

class _HubTutorialOverlay extends StatelessWidget {
  const _HubTutorialOverlay({required this.onDone});
  final Future<void> Function() onDone;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xB8000000),
    child: SafeArea(
      child: Center(
        child: Container(
          key: const Key('hub-tutorial-overlay'),
          width: 330,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEF8),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF27334B), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '데시멀 센터 데시멀 생활 안내',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                '• 생활 라운지: 매일 바뀌는 동기와 오늘의 대화\n'
                '• 투자실: 동기·운영관·운용 조직\n'
                '• 컴퓨터실: 공용 PC·시장·부동산·상권 앱과 공동 작업\n'
                '• 기록 보관실: 국가계좌 장부·신문 스크랩\n'
                '• 본관 앞: 국가계좌 창구·원내 실습',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.65,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '아래 장소 메뉴로 바로 이동할 수 있어요. 라운지의 동기를 누르면 표정과 인사가 달라지고, 오른쪽 버튼에서는 톡·관계·시간 기능을 엽니다.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  key: const Key('hub-tutorial-done'),
                  onPressed: () => onDone(),
                  child: const Text('알겠어요'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LobbyMotionPortrait extends StatelessWidget {
  const _LobbyMotionPortrait({
    required this.baseAsset,
    required this.motionFrames,
    required this.gesture,
    required this.reacting,
  });

  final String baseAsset;
  final List<String> motionFrames;
  final Animation<double> gesture;
  final bool reacting;

  Widget _portraitImage(String asset, {Key? key}) => Image.asset(
    asset,
    key: key,
    fit: BoxFit.contain,
    alignment: Alignment.topCenter,
    filterQuality: FilterQuality.high,
    gaplessPlayback: true,
    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
  );

  double _motionOpacity(double value) {
    if (reacting || value <= 0.001 || value >= 0.999) return 0;
    if (value < 0.14) {
      return Curves.easeInOutCubic.transform(value / 0.14);
    }
    if (value > 0.86) {
      return Curves.easeInOutCubic.transform((1 - value) / 0.14);
    }
    return 1;
  }

  Widget _basePortrait() => AnimatedSwitcher(
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 520),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, animation) =>
        FadeTransition(opacity: animation, child: child),
    child: _portraitImage(
      baseAsset,
      key: Key(
        reacting ? 'lobby-heroine-reaction-image' : 'lobby-heroine-idle-image',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!_usesGeneratedLobbyFrames) {
      return SizedBox.expand(child: _basePortrait());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: gesture,
          builder: (context, child) =>
              Opacity(opacity: 1 - _motionOpacity(gesture.value), child: child),
          child: _basePortrait(),
        ),
        if (!reacting)
          AnimatedBuilder(
            animation: gesture,
            builder: (context, child) {
              final value = gesture.value;
              if (value <= 0.001 || value >= 0.999) {
                return const SizedBox.shrink(
                  key: Key('lobby-heroine-motion-frame-layer'),
                );
              }
              const sequence = <int>[0, 0, 1, 2, 3, 3, 3, 2, 1, 0, 0];
              final position = value * (sequence.length - 1);
              final segment = position.floor().clamp(0, sequence.length - 2);
              final mix = Curves.easeInOutCubic.transform(position - segment);
              final currentAsset = motionFrames[sequence[segment]];
              final nextAsset = motionFrames[sequence[segment + 1]];
              final edgeOpacity = _motionOpacity(value);
              return Opacity(
                key: const Key('lobby-heroine-motion-frame-layer'),
                opacity: edgeOpacity.clamp(0.0, 1.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 1 - mix,
                      child: _portraitImage(currentAsset),
                    ),
                    if (nextAsset != currentAsset)
                      Opacity(opacity: mix, child: _portraitImage(nextAsset)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _LobbyHeroineStage extends StatefulWidget {
  const _LobbyHeroineStage({
    super.key,
    required this.state,
    required this.profile,
    required this.progress,
    required this.onOpenMessenger,
    required this.onOpenRelationships,
  });

  final GameState state;
  final CohortGirlProfile profile;
  final GirlRelationshipProgress progress;
  final VoidCallback onOpenMessenger;
  final VoidCallback onOpenRelationships;

  @override
  State<_LobbyHeroineStage> createState() => _LobbyHeroineStageState();
}

class _LobbyHeroineStageState extends State<_LobbyHeroineStage>
    with TickerProviderStateMixin {
  late final AnimationController _breathing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final AnimationController _gesture = AnimationController(vsync: this);
  late final AnimationController _reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );
  late final AnimationController _lookReturn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  Timer? _idleTimer;
  Timer? _blinkTimer;
  Timer? _reactionTimer;
  Timer? _gestureTimer;
  Timer? _tapResetTimer;
  Timer? _lookHoldTimer;
  bool _animationsEnabled = false;
  bool _reacting = false;
  bool _pressed = false;
  bool _lookReturning = false;
  bool _repeatedTouch = false;
  int _motionCycle = 0;
  int _blinkCycle = 0;
  int _gestureCycle = 0;
  int _tapStreak = 0;
  double _swayDirection = 1;
  double _touchDirection = 1;
  Offset _lookOffset = Offset.zero;
  Offset _lookStart = Offset.zero;
  _LobbyIdleGesture _idleGesture = _LobbyIdleGesture.nod;
  _LobbyTouchZone _touchZone = _LobbyTouchZone.torso;
  _LobbyTouchZone? _lastTouchZone;
  String? _reactionLine;
  String? _precachedMotionProfile;

  _LobbyMotionProfile get _motionProfile =>
      _lobbyMotionProfiles[widget.profile.id]!;

  int get _motionSeed => widget.profile.id.codeUnits.fold<int>(
    0,
    (value, unit) => (value * 31 + unit) & 0x7fffffff,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheMotionFrames();
    final animationsEnabled = !MediaQuery.of(context).disableAnimations;
    _breathing.duration = Duration(
      milliseconds: _lobbyBreathingDurationMs(widget.state.marketMinute),
    );
    if (_animationsEnabled == animationsEnabled) return;
    _animationsEnabled = animationsEnabled;
    if (_animationsEnabled) {
      if (_usesGeneratedLobbyFrames) {
        _entrance.forward(from: 0);
        _playIdleMotion();
        _scheduleGesture(initial: true);
      } else {
        _entrance.value = 1;
      }
      _scheduleBlink(initial: true);
    } else {
      _idleTimer?.cancel();
      _blinkTimer?.cancel();
      _gestureTimer?.cancel();
      _lookHoldTimer?.cancel();
      _breathing
        ..stop()
        ..reset();
      _blink
        ..stop()
        ..reset();
      _gesture
        ..stop()
        ..reset();
      _reaction
        ..stop()
        ..reset();
      _lookReturn
        ..stop()
        ..reset();
      _entrance
        ..stop()
        ..value = 1;
      _lookOffset = Offset.zero;
      _lookReturning = false;
    }
  }

  void _precacheMotionFrames() {
    if (!_usesGeneratedLobbyFrames) return;
    if (_precachedMotionProfile == widget.profile.id) return;
    _precachedMotionProfile = widget.profile.id;
    for (final asset in _motionProfile.motionFrames) {
      precacheImage(AssetImage(asset), context);
    }
  }

  void _playIdleMotion() {
    if (!_usesGeneratedLobbyFrames ||
        !mounted ||
        !_animationsEnabled ||
        _breathing.isAnimating) {
      return;
    }
    _swayDirection = ((_motionSeed + _motionCycle) & 1) == 0 ? 1 : -1;
    _breathing.forward(from: 0).whenComplete(() {
      if (!mounted || !_animationsEnabled) return;
      _motionCycle += 1;
      _idleTimer?.cancel();
      final pauseMs = 900 + ((_motionSeed + _motionCycle * 977) % 1200);
      _idleTimer = Timer(Duration(milliseconds: pauseMs), _playIdleMotion);
    });
  }

  void _scheduleBlink({required bool initial}) {
    if (!mounted || !_animationsEnabled) return;
    _blinkTimer?.cancel();
    final delayMs = initial
        ? 1500 + (_motionSeed % 900)
        : 3200 + ((_motionSeed + _blinkCycle * 1381) % 3500);
    _blinkTimer = Timer(
      Duration(milliseconds: delayMs),
      () => _playBlink(followUp: false),
    );
  }

  void _playBlink({required bool followUp}) {
    if (!mounted || !_animationsEnabled) return;
    _blink.forward(from: 0).whenComplete(() {
      if (!mounted || !_animationsEnabled) return;
      final doubleBlink =
          !followUp && ((_motionSeed + _blinkCycle * 17) % 6 == 0);
      if (doubleBlink) {
        _blinkTimer = Timer(
          const Duration(milliseconds: 115),
          () => _playBlink(followUp: true),
        );
        return;
      }
      _blinkCycle += 1;
      _scheduleBlink(initial: false);
    });
  }

  void _scheduleGesture({required bool initial}) {
    if (!_usesGeneratedLobbyFrames || !mounted || !_animationsEnabled) return;
    _gestureTimer?.cancel();
    final delayMs = initial
        ? 4200 + (_motionSeed % 2800)
        : 7200 +
              ((_motionSeed + _gestureCycle * 1601) % 7000) +
              _lobbyEveningMotionDelayMs(widget.state.marketMinute);
    _gestureTimer = Timer(Duration(milliseconds: delayMs), _playGesture);
  }

  void _playGesture() {
    if (!_usesGeneratedLobbyFrames || !mounted || !_animationsEnabled) return;
    if (_reacting || _pressed) {
      _scheduleGesture(initial: false);
      return;
    }
    final gestures = _motionProfile.gestures;
    _idleGesture = gestures[(_motionSeed + _gestureCycle) % gestures.length];
    _swayDirection = ((_motionSeed + _gestureCycle * 13) & 1) == 0 ? 1 : -1;
    _gesture.duration = Duration(
      milliseconds:
          _motionProfile.tempoMs + ((_motionSeed + _gestureCycle * 173) % 260),
    );
    _gesture.forward(from: 0).whenComplete(() {
      if (!mounted || !_animationsEnabled) return;
      _gestureCycle += 1;
      _scheduleGesture(initial: false);
    });
  }

  void _updateLook(Offset localPosition, Size size) {
    if (!_usesGeneratedLobbyFrames ||
        !mounted ||
        !_animationsEnabled ||
        size.isEmpty) {
      return;
    }
    _lookHoldTimer?.cancel();
    _lookReturn.stop();
    final dx = ((localPosition.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
    final dy = ((localPosition.dy / size.height) * 2 - 1).clamp(-1.0, 1.0);
    final next = Offset(dx * 2.2, dy * 1.25);
    if (next == _lookOffset && !_lookReturning) return;
    setState(() {
      _lookOffset = next;
      _lookReturning = false;
    });
  }

  void _releaseLook({Duration delay = const Duration(milliseconds: 280)}) {
    if (!_usesGeneratedLobbyFrames || !_animationsEnabled) return;
    _lookHoldTimer?.cancel();
    _lookHoldTimer = Timer(delay, () {
      if (!mounted || _lookOffset == Offset.zero) return;
      _lookStart = _lookOffset;
      setState(() => _lookReturning = true);
      _lookReturn.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        setState(() {
          _lookOffset = Offset.zero;
          _lookReturning = false;
        });
      });
    });
  }

  @override
  void didUpdateWidget(covariant _LobbyHeroineStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.marketMinute != widget.state.marketMinute) {
      _breathing.duration = Duration(
        milliseconds: _lobbyBreathingDurationMs(widget.state.marketMinute),
      );
    }
    if (oldWidget.profile.id != widget.profile.id) {
      _idleTimer?.cancel();
      _blinkTimer?.cancel();
      _reactionTimer?.cancel();
      _gestureTimer?.cancel();
      _tapResetTimer?.cancel();
      _lookHoldTimer?.cancel();
      _breathing.reset();
      _blink.reset();
      _gesture.reset();
      _reaction.reset();
      _lookReturn.reset();
      _entrance.reset();
      _motionCycle = 0;
      _blinkCycle = 0;
      _gestureCycle = 0;
      _tapStreak = 0;
      _reacting = false;
      _pressed = false;
      _lookReturning = false;
      _repeatedTouch = false;
      _lastTouchZone = null;
      _reactionLine = null;
      _lookOffset = Offset.zero;
      _precachedMotionProfile = null;
      _precacheMotionFrames();
      if (_animationsEnabled) {
        if (_usesGeneratedLobbyFrames) {
          _entrance.forward(from: 0);
          _playIdleMotion();
          _scheduleGesture(initial: true);
        } else {
          _entrance.value = 1;
        }
        _scheduleBlink(initial: true);
      }
    }
  }

  void _setPressed(bool pressed) {
    if (!mounted || _pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  void _react(Offset localPosition, Size size) {
    _reactionTimer?.cancel();
    _gesture
      ..stop()
      ..value = 0;
    final normalizedY = size.height <= 0
        ? 0.5
        : (localPosition.dy / size.height).clamp(0.0, 1.0);
    final zone = normalizedY < 0.34
        ? _LobbyTouchZone.face
        : normalizedY < 0.67
        ? _LobbyTouchZone.torso
        : _LobbyTouchZone.accessory;
    _touchDirection = localPosition.dx < size.width / 2 ? -1 : 1;
    _tapStreak = _lastTouchZone == zone ? _tapStreak + 1 : 1;
    _lastTouchZone = zone;
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(seconds: 4), () {
      _tapStreak = 0;
      _lastTouchZone = null;
    });
    final repeated = _tapStreak >= 3;
    final line = repeated
        ? _motionProfile.repeatLine
        : switch (zone) {
            _LobbyTouchZone.face => _motionProfile.faceLine,
            _LobbyTouchZone.torso => _motionProfile.torsoLine,
            _LobbyTouchZone.accessory => _motionProfile.accessoryLine,
          };
    if (_usesGeneratedLobbyFrames &&
        _animationsEnabled &&
        !_breathing.isAnimating) {
      _idleTimer?.cancel();
      _playIdleMotion();
    }
    if (_animationsEnabled) _reaction.forward(from: 0);
    setState(() {
      _reacting = true;
      _touchZone = zone;
      _repeatedTouch = repeated;
      _reactionLine = line;
    });
    _reactionTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() {
        _reacting = false;
        _repeatedTouch = false;
        _reactionLine = null;
      });
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _blinkTimer?.cancel();
    _reactionTimer?.cancel();
    _gestureTimer?.cancel();
    _tapResetTimer?.cancel();
    _lookHoldTimer?.cancel();
    _breathing.dispose();
    _blink.dispose();
    _gesture.dispose();
    _reaction.dispose();
    _entrance.dispose();
    _lookReturn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final progress = widget.progress;
    final greeting = _lobbyHeroineGreeting(
      state: widget.state,
      profile: profile,
      progress: progress,
    );
    final asset = _lobbyHeroineAsset(
      profile: profile,
      progress: progress,
      reacting: _reacting,
    );
    final accent = Color(profile.accentValue);

    return Stack(
      key: const Key('daily-lobby-heroine-stage'),
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          bottom: 54,
          child: LayoutBuilder(
            builder: (context, gestureConstraints) => MouseRegion(
              onHover: (event) =>
                  _updateLook(event.localPosition, gestureConstraints.biggest),
              onExit: (_) => _releaseLook(),
              child: GestureDetector(
                key: Key('daily-lobby-heroine-${profile.id}'),
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  _setPressed(true);
                  _updateLook(
                    details.localPosition,
                    gestureConstraints.biggest,
                  );
                },
                onTapCancel: () {
                  _setPressed(false);
                  _releaseLook();
                },
                onTapUp: (details) {
                  _setPressed(false);
                  _react(details.localPosition, gestureConstraints.biggest);
                  _releaseLook(delay: const Duration(milliseconds: 650));
                },
                onPanStart: (details) => _updateLook(
                  details.localPosition,
                  gestureConstraints.biggest,
                ),
                onPanUpdate: (details) => _updateLook(
                  details.localPosition,
                  gestureConstraints.biggest,
                ),
                onPanEnd: (_) => _releaseLook(),
                onPanCancel: _releaseLook,
                child: Semantics(
                  button: true,
                  label: '${profile.name}, 눌러서 인사 듣기',
                  child: AnimatedSlide(
                    offset: Offset(
                      0,
                      _pressed ? 0.0015 : (_reacting ? -0.002 : 0),
                    ),
                    duration: Duration(milliseconds: _pressed ? 90 : 320),
                    curve: Curves.easeOutCubic,
                    child: AnimatedScale(
                      key: const Key('lobby-heroine-touch-motion'),
                      scale: _pressed ? 0.997 : (_reacting ? 1.004 : 1),
                      duration: Duration(milliseconds: _pressed ? 90 : 360),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.bottomCenter,
                      child: AnimatedScale(
                        key: const Key('lobby-heroine-affection-distance'),
                        scale: _lobbyAffectionDistanceScale(progress.stage),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.bottomCenter,
                        child: Transform.translate(
                          offset: Offset(
                            0,
                            _lobbyAffectionDistanceY(progress.stage),
                          ),
                          child: AnimatedBuilder(
                            animation: Listenable.merge(<Listenable>[
                              _breathing,
                              _gesture,
                              _reaction,
                              _entrance,
                              _lookReturn,
                            ]),
                            builder: (context, child) {
                              final phase = _breathing.value * math.pi * 2;
                              final breath = (1 - math.cos(phase)) * 0.5;
                              final weightShift =
                                  math.sin(_breathing.value * math.pi) *
                                  _swayDirection;
                              final microSway = math.sin(phase) * 0.35;
                              final gestureFrame = _lobbyIdleGestureFrame(
                                gesture: _idleGesture,
                                value: _gesture.value,
                                direction: _swayDirection,
                                strength: _motionProfile.strength,
                              );
                              final reactionFrame = _lobbyTouchReactionFrame(
                                zone: _touchZone,
                                value: _reaction.value,
                                direction: _touchDirection,
                                affection: progress.affection,
                                repeated: _repeatedTouch,
                              );
                              final entrance = _animationsEnabled
                                  ? Curves.easeOutCubic.transform(
                                      _entrance.value,
                                    )
                                  : 1.0;
                              final lookOffset = _lookReturning
                                  ? Offset.lerp(
                                      _lookStart,
                                      Offset.zero,
                                      Curves.easeOutCubic.transform(
                                        _lookReturn.value,
                                      ),
                                    )!
                                  : _lookOffset;
                              return Opacity(
                                key: const Key('lobby-heroine-entrance-motion'),
                                opacity: 0.35 + entrance * 0.65,
                                child: Transform.translate(
                                  key: const Key('lobby-heroine-gaze-motion'),
                                  offset:
                                      lookOffset +
                                      Offset(0, (1 - entrance) * 6),
                                  child: Transform.translate(
                                    key: const Key(
                                      'lobby-heroine-idle-gesture-motion',
                                    ),
                                    offset: gestureFrame.offset,
                                    child: Transform.translate(
                                      key: const Key(
                                        'lobby-heroine-zone-reaction-motion',
                                      ),
                                      offset: reactionFrame.offset,
                                      child: Transform.translate(
                                        key: const Key(
                                          'lobby-heroine-breathing-motion',
                                        ),
                                        offset: Offset(
                                          weightShift * 1.7 + microSway,
                                          -breath * 1.5,
                                        ),
                                        child: Transform.rotate(
                                          angle:
                                              weightShift * 0.0022 +
                                              gestureFrame.rotation +
                                              reactionFrame.rotation,
                                          alignment: Alignment.bottomCenter,
                                          child: Transform(
                                            alignment: Alignment.bottomCenter,
                                            transform: Matrix4.diagonal3Values(
                                              (1 + breath * 0.0012) *
                                                  gestureFrame.scale *
                                                  reactionFrame.scale,
                                              (1 + breath * 0.0032) *
                                                  gestureFrame.scale *
                                                  reactionFrame.scale,
                                              1,
                                            ),
                                            child: child,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                const portraitScale = 1.32;
                                return Align(
                                  alignment: Alignment.topCenter,
                                  child: OverflowBox(
                                    alignment: Alignment.topCenter,
                                    minWidth:
                                        constraints.maxWidth *
                                        1.18 *
                                        portraitScale,
                                    maxWidth:
                                        constraints.maxWidth *
                                        1.18 *
                                        portraitScale,
                                    minHeight:
                                        constraints.maxHeight * portraitScale,
                                    maxHeight:
                                        constraints.maxHeight * portraitScale,
                                    child: SizedBox(
                                      width:
                                          constraints.maxWidth *
                                          1.18 *
                                          portraitScale,
                                      height:
                                          constraints.maxHeight * portraitScale,
                                      child: RepaintBoundary(
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            _LobbyMotionPortrait(
                                              baseAsset: asset,
                                              motionFrames:
                                                  _motionProfile.motionFrames,
                                              gesture: _gesture,
                                              reacting: _reacting,
                                            ),
                                            Positioned.fill(
                                              child: IgnorePointer(
                                                child: AnimatedBuilder(
                                                  animation: Listenable.merge(
                                                    <Listenable>[
                                                      _blink,
                                                      _gesture,
                                                    ],
                                                  ),
                                                  builder: (context, child) {
                                                    final gestureVisible =
                                                        _gesture.value >
                                                            0.001 &&
                                                        _gesture.value < 0.999;
                                                    final amount =
                                                        _reacting ||
                                                            gestureVisible
                                                        ? 0.0
                                                        : widget.state.story
                                                              .flagBool(
                                                                'hubBlinkPreview',
                                                              )
                                                        ? 1.0
                                                        : _lobbyBlinkAmount(
                                                            _blink.value,
                                                          );
                                                    return Opacity(
                                                      key: const Key(
                                                        'lobby-heroine-blink-overlay',
                                                      ),
                                                      opacity: amount,
                                                      child: CustomPaint(
                                                        painter: _LobbyBlinkPainter(
                                                          geometry:
                                                              _lobbyBlinkGeometryByAsset[asset] ??
                                                              _lobbyBlinkGeometry[profile
                                                                  .id]!,
                                                          closure: amount,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 4,
          child: Container(
            key: const Key('lobby-heroine-greeting-card'),
            padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
            decoration: BoxDecoration(
              color: const Color(0xF21B2639),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withValues(alpha: 0.95),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66070A12),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            profile.name,
                            key: const Key('lobby-heroine-name'),
                            style: const TextStyle(
                              fontFamily: _hubDisplayFont,
                              color: Colors.white,
                              fontSize: 13.5,
                              height: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            key: const Key('lobby-heroine-stage-label'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.7),
                              ),
                            ),
                            child: Text(
                              progress.stage.label,
                              style: TextStyle(
                                color: accent,
                                fontSize: 8,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _reactionLine ?? greeting,
                        key: const Key('lobby-heroine-greeting'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF8F2E6),
                          fontSize: 10.2,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('lobby-heroine-message-button'),
                  tooltip: '${profile.name}에게 데시멀톡 보내기',
                  onPressed: widget.onOpenMessenger,
                  color: const Color(0xFFFFD66F),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                ),
                IconButton(
                  key: const Key('lobby-heroine-relationship-button'),
                  tooltip: '${profile.name} 관계 확인',
                  onPressed: widget.onOpenRelationships,
                  color: accent,
                  icon: const Icon(Icons.favorite_rounded, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

double _lobbyBlinkAmount(double value) {
  if (value <= 0 || value >= 1) return 0;
  if (value < 0.38) {
    return Curves.easeInCubic.transform(value / 0.38);
  }
  if (value <= 0.58) return 1;
  return Curves.easeOutCubic.transform((1 - value) / 0.42);
}

class _LobbyBlinkPainter extends CustomPainter {
  const _LobbyBlinkPainter({required this.geometry, required this.closure});

  final _LobbyBlinkGeometry geometry;
  final double closure;

  @override
  void paint(Canvas canvas, Size size) {
    if (closure <= 0) return;
    const sourceSize = Size(1024, 1536);
    final fitted = applyBoxFit(BoxFit.contain, sourceSize, size);
    final imageRect = Alignment.topCenter.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    final eyeWidth = imageRect.width * geometry.eyeWidth;
    final eyeHeight = imageRect.height * geometry.eyeHeight;
    final skinPaint = Paint()
      ..color = geometry.skinColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        math.max(0.35, imageRect.width * 0.0012),
      )
      ..isAntiAlias = true;
    final lidPaint = Paint()
      ..color = geometry.lidColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1, imageRect.width * 0.0026)
      ..isAntiAlias = true;

    for (final anchor in <Offset>[geometry.leftEye, geometry.rightEye]) {
      final center = Offset(
        imageRect.left + imageRect.width * anchor.dx,
        imageRect.top + imageRect.height * anchor.dy,
      );
      final cover = Rect.fromCenter(
        center: center,
        width: eyeWidth,
        height: eyeHeight * (0.72 + closure * 0.28),
      );
      canvas.drawOval(cover, skinPaint);
      final lid = Path()
        ..moveTo(cover.left + eyeWidth * 0.08, center.dy)
        ..quadraticBezierTo(
          center.dx,
          center.dy + eyeHeight * 0.20,
          cover.right - eyeWidth * 0.08,
          center.dy,
        );
      canvas.drawPath(lid, lidPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LobbyBlinkPainter oldDelegate) =>
      oldDelegate.geometry != geometry || oldDelegate.closure != closure;
}

Color _lobbyAmbientColor(int marketMinute) {
  if (marketMinute < krxOpenMinute) return const Color(0xFFFFD58A);
  if (marketMinute < krxCloseMinute) return const Color(0xFFFFF0C2);
  if (marketMinute < 20 * 60) return const Color(0xFFFFB56B);
  return const Color(0xFF9DB9E8);
}

class _LobbyAmbientBackground extends StatefulWidget {
  const _LobbyAmbientBackground({required this.state, required this.child});

  final GameState state;
  final Widget child;

  @override
  State<_LobbyAmbientBackground> createState() =>
      _LobbyAmbientBackgroundState();
}

class _LobbyAmbientBackgroundState extends State<_LobbyAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7600),
  );
  Timer? _pauseTimer;
  bool _animationsEnabled = false;
  int _cycle = 0;

  int get _seed => widget.state.simulationSeed.codeUnits.fold<int>(
    widget.state.day,
    (value, unit) => (value * 31 + unit) & 0x7fffffff,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = !MediaQuery.of(context).disableAnimations;
    if (_animationsEnabled == enabled) return;
    _animationsEnabled = enabled;
    if (enabled) {
      _play();
    } else {
      _pauseTimer?.cancel();
      _motion
        ..stop()
        ..value = 1;
    }
  }

  void _play() {
    if (!mounted || !_animationsEnabled || _motion.isAnimating) return;
    _motion.forward(from: 0).whenComplete(() {
      if (!mounted || !_animationsEnabled) return;
      _cycle += 1;
      final pauseMs = 2600 + ((_seed + _cycle * 761) % 3200);
      _pauseTimer = Timer(Duration(milliseconds: pauseMs), _play);
    });
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ambient = _lobbyAmbientColor(widget.state.marketMinute);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, child) {
          final progress = _animationsEnabled ? _motion.value : 1.0;
          final drift = math.sin(progress * math.pi);
          final direction = ((_seed + _cycle) & 1) == 0 ? 1.0 : -1.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                key: const Key('lobby-ambient-background-motion'),
                offset: Offset(direction * drift * 1.8, -drift * 0.8),
                child: Transform.scale(
                  scale: 1.012 + drift * 0.0015,
                  child: child,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ambient.withValues(alpha: 0.075),
                      Colors.transparent,
                      const Color(0xFF0D1625).withValues(alpha: 0.045),
                    ],
                    stops: const [0, 0.52, 1],
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  key: const Key('lobby-ambient-particles'),
                  painter: _LobbyAtmospherePainter(
                    progress: progress,
                    color: ambient,
                    seed: _seed,
                    enabled: _animationsEnabled,
                  ),
                ),
              ),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _LobbyAtmospherePainter extends CustomPainter {
  const _LobbyAtmospherePainter({
    required this.progress,
    required this.color,
    required this.seed,
    required this.enabled,
  });

  final double progress;
  final Color color;
  final int seed;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled) return;
    final fade = math.sin(progress * math.pi).clamp(0.0, 1.0);
    for (var index = 0; index < 7; index += 1) {
      final xRatio = ((seed + index * 137) % 947) / 947;
      final yRatio = ((seed ~/ 7 + index * 211) % 887) / 887;
      final rise = progress * size.height * (0.055 + index * 0.004);
      final wobble = math.sin(progress * math.pi * 2 + index) * 2.2;
      final center = Offset(
        size.width * (0.08 + xRatio * 0.84) + wobble,
        size.height * (0.18 + yRatio * 0.66) - rise,
      );
      final paint = Paint()
        ..color = color.withValues(alpha: (0.035 + index * 0.007) * fade)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawCircle(center, 0.7 + (index % 3) * 0.42, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LobbyAtmospherePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.seed != seed ||
      oldDelegate.enabled != enabled;
}

class _ApartmentPlaceScene extends StatelessWidget {
  const _ApartmentPlaceScene({
    super.key,
    required this.place,
    required this.state,
    required this.onOpenMarket,
    required this.onOpenBank,
    required this.onOpenLedger,
    required this.onOpenOrganization,
    required this.onOpenHomeImprovements,
    required this.onOpenWork,
  });

  final _ApartmentPlace place;
  final GameState state;
  final VoidCallback onOpenMarket;
  final VoidCallback onOpenBank;
  final VoidCallback onOpenLedger;
  final VoidCallback onOpenOrganization;
  final VoidCallback onOpenHomeImprovements;
  final VoidCallback onOpenWork;

  @override
  Widget build(BuildContext context) {
    final details = _ApartmentPlaceDetails.forPlace(place);
    final backgroundAsset = details.assetPath;
    final background = Image.asset(
      backgroundAsset,
      key: Key('apartment-background-${details.id}'),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) =>
          _ApartmentFallbackBackground(details: details),
    );
    return Stack(
      key: Key('apartment-place-${details.id}'),
      fit: StackFit.expand,
      children: [
        if (place == _ApartmentPlace.bedroom)
          _LobbyAmbientBackground(state: state, child: background)
        else
          background,
        if (place == _ApartmentPlace.livingRoom) ...[
          _InvestmentRoomActionPanel(onTap: onOpenOrganization),
        ],
        if (place == _ApartmentPlace.kitchen) ...[
          _ComputerLabActionDock(
            onOpenComputer: onOpenMarket,
            onOpenHomeImprovements: onOpenHomeImprovements,
          ),
        ],
        if (place == _ApartmentPlace.corridor) ...[
          _ArchiveRoomActionPanel(
            pendingCount: state.pendingDecisions.length,
            onTap: onOpenLedger,
          ),
        ],
        if (place == _ApartmentPlace.neighborhood) ...[
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-bank-button'),
            alignment: const Alignment(-0.74, -0.34),
            width: 118,
            height: 144,
            eyebrow: '국가계좌 창구 가기',
            label: bankAccessUnlocked(state) ? '국가계좌 창구' : '잠김 · 윤하린 소개 필요',
            icon: Icons.account_balance_rounded,
            accent: const Color(0xFF86CBEA),
            attention: !bankAccessUnlocked(state),
            onTap: onOpenBank,
          ),
          _ApartmentObjectHotspot(
            interactionKey: const Key('open-work-button'),
            alignment: const Alignment(0.76, -0.24),
            width: 122,
            height: 148,
            eyebrow: '원내 실습 확인',
            label: '데시멀 실습 게시판',
            icon: Icons.sports_esports_rounded,
            accent: const Color(0xFF98E5C1),
            onTap: onOpenWork,
          ),
        ],
      ],
    );
  }
}

class _ApartmentSceneVignette extends StatelessWidget {
  const _ApartmentSceneVignette();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x8A070A12), Color(0x00070A12), Color(0xB8070A12)],
        stops: [0, 0.48, 1],
      ),
    ),
  );
}

class _ApartmentLocationHeader extends StatelessWidget {
  const _ApartmentLocationHeader({
    required this.details,
    required this.state,
    required this.activeSaveSlot,
    required this.lastSavedAt,
    required this.onOpenGameMenu,
  });

  final _ApartmentPlaceDetails details;
  final GameState state;
  final int activeSaveSlot;
  final DateTime? lastSavedAt;
  final VoidCallback onOpenGameMenu;

  @override
  Widget build(BuildContext context) {
    final level = state.progression.level;
    final weather = _ApartmentWeather.forState(state);

    return Semantics(
      container: true,
      label: '${details.title}, ${state.companyName}, $activeSaveSlot번 저장 슬롯',
      child: Container(
        key: const Key('room-company-sign'),
        height: 80,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFF243451),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF18243A), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66070A12),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 4, 6, 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF9EA), Color(0xFFF4E6C5)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD99B2B), width: 1.5),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD66F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF9C681B),
                          width: 1.5,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '현재 시각',
                              style: TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Color(0xFF76501B),
                                fontSize: 7,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              marketTimeLabel(state.marketMinute),
                              key: const Key('apartment-current-time'),
                              style: const TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: _ink,
                                fontSize: 16,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            details.title,
                            key: const Key('apartment-location-title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _hubDisplayFont,
                              color: _ink,
                              fontSize: 12.5,
                              height: 1.05,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Expanded(
                                child: KeyedSubtree(
                                  key: const Key('room-company-name'),
                                  child: Text(
                                    state.companyName,
                                    key: const Key('company-header-title'),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: _hubDisplayFont,
                                      color: Color(0xFF8B5C17),
                                      fontSize: 8.5,
                                      height: 1,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'LV.$level',
                                style: const TextStyle(
                                  fontFamily: _hubDisplayFont,
                                  color: Color(0xFF59667D),
                                  fontSize: 7.8,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          key: const Key('game-menu-button'),
                          tooltip: '저장 및 게임 메뉴',
                          onPressed: onOpenGameMenu,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF243451),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(40, 40),
                            side: const BorderSide(
                              color: Color(0xFFDCA538),
                              width: 1.5,
                            ),
                          ),
                          icon: const Icon(Icons.menu_rounded, size: 21),
                        ),
                        if (lastSavedAt != null)
                          const Positioned(
                            right: -1,
                            top: -1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFF55C88A),
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                              child: SizedBox(width: 11, height: 11),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF243451),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDCA538)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 13,
                      child: _ApartmentStatusChip(
                        icon: Icons.schedule_rounded,
                        iconColor: const Color(0xFFFFD66F),
                        label:
                            'DAY ${state.day} · ${_apartmentHudDateLabel(state.currentDate)}',
                        semanticLabel:
                            'DAY ${state.day} · ${_apartmentDateLabel(state.currentDate)}',
                      ),
                    ),
                    const _ApartmentStatusDivider(),
                    Expanded(
                      flex: 9,
                      child: _ApartmentStatusChip(
                        icon: Icons.payments_rounded,
                        iconColor: const Color(0xFFFFC66F),
                        label: '${_money(state.cash)}원',
                      ),
                    ),
                    const _ApartmentStatusDivider(),
                    Expanded(
                      flex: 9,
                      child: _ApartmentStatusChip(
                        icon: Icons.wb_sunny_rounded,
                        iconColor: const Color(0xFF83DBB7),
                        label: weather.label,
                        trailing: 'S$activeSaveSlot',
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
}

class _ApartmentStatusDivider extends StatelessWidget {
  const _ApartmentStatusDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 14, color: const Color(0x66F3C960));
}

class _ApartmentStatusChip extends StatelessWidget {
  const _ApartmentStatusChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailing,
    this.semanticLabel,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? trailing;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel ?? label,
    excludeSemantics: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontFamily: _hubDisplayFont,
                  color: Colors.white,
                  fontSize: 9.2,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 3),
            Text(
              trailing!,
              style: const TextStyle(
                fontFamily: _hubDisplayFont,
                color: Color(0xFFFFD66F),
                fontSize: 7.2,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ApartmentWeather {
  const _ApartmentWeather(this.label);

  final String label;

  static _ApartmentWeather forState(GameState state) {
    if (state.marketMinute >= 17 * 60) {
      return const _ApartmentWeather('해질녘');
    }
    final seed = state.simulationSeed.codeUnits.fold<int>(
      state.day * 17,
      (value, unit) => (value * 31 + unit) & 0x7fffffff,
    );
    return switch (seed % 5) {
      1 || 3 => const _ApartmentWeather('구름'),
      4 => const _ApartmentWeather('비'),
      _ => const _ApartmentWeather('맑음'),
    };
  }
}

class _ApartmentDayGuideCard extends StatelessWidget {
  const _ApartmentDayGuideCard({required this.state, required this.onPressed});

  final GameState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final guidance = gameDayGuidanceForState(state);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('apartment-day-guide'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(8, 6, 7, 6),
          decoration: BoxDecoration(
            color: const Color(0xF7FFF9EA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD99B2B), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x52070A12),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD66F),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF9C681B)),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Color(0xFF61451F),
                  size: 19,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guidance.phaseLabel,
                      key: const Key('apartment-day-phase'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _hubDisplayFont,
                        color: Color(0xFF9A6114),
                        fontSize: 7.5,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      guidance.title,
                      key: const Key('apartment-next-objective'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _hubDisplayFont,
                        color: _ink,
                        fontSize: 10.5,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF9A6114),
                    size: 18,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    guidance.actionLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: _hubDisplayFont,
                      color: Color(0xFF76501B),
                      fontSize: 6.5,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestmentRoomActionPanel extends StatelessWidget {
  const _InvestmentRoomActionPanel({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: const Alignment(0, 0.04),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Semantics(
        button: true,
        label: '데시멀 운용조직 열기',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('open-organization-button'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              height: 108,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFA242C3E),
                    Color(0xFA111827),
                    Color(0xFE090E18),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xD5C69B4A), width: 1.25),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0xB0000000),
                    blurRadius: 18,
                    offset: Offset(0, 9),
                  ),
                  BoxShadow(
                    color: Color(0x2849A8D8),
                    blurRadius: 2,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 64,
                        height: 92,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFF353346),
                              Color(0xFF151926),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: const Color(0xB7C69B4A)),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x99000000),
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 43,
                            height: 43,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x332D3548),
                              border: Border.all(
                                color: const Color(0xFFE0B965),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.groups_2_rounded,
                              color: Color(0xFFFFD47A),
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Text(
                                '전략 회의 · 교차검토',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: _hubDisplayFont,
                                  color: Color(0xFFFFC969),
                                  fontSize: 7.4,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 1,
                                color: const Color(0x554E668A),
                              ),
                              const SizedBox(height: 7),
                              const Text(
                                '데시멀 운용조직',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: _hubDisplayFont,
                                  color: Colors.white,
                                  fontSize: 13.2,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                '동기·운영관과 투자 판단 점검',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: _hubDisplayFont,
                                  color: Colors.white.withValues(alpha: 0.66),
                                  fontSize: 7.2,
                                  height: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        width: 43,
                        height: 92,
                        decoration: BoxDecoration(
                          color: const Color(0xFF131722),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x887A6742)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 29,
                              height: 35,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF806536),
                                    Color(0xFF4D3A21),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFD8AF5D),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Color(0xFFFFD47A),
                                size: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '+30분',
                              style: TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Color(0xFFFF806C),
                                fontSize: 7.4,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const _ComputerLabIndicator(
                              color: Color(0xFFFF625C),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Positioned(left: 3, top: 3, child: _ComputerLabBolt()),
                  const Positioned(right: 3, top: 3, child: _ComputerLabBolt()),
                  Positioned(
                    left: 79,
                    right: 55,
                    bottom: 1,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: <Color>[
                            Colors.transparent,
                            Color(0xFFFFC45C),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(color: Color(0x99FFB83E), blurRadius: 5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ArchiveRoomActionPanel extends StatelessWidget {
  const _ArchiveRoomActionPanel({
    required this.pendingCount,
    required this.onTap,
  });

  final int pendingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = pendingCount > 0 ? '신규 $pendingCount건' : '열기';
    final indicator = pendingCount > 0
        ? const Color(0xFFFFC45E)
        : const Color(0xFF88D879);
    return Align(
      alignment: const Alignment(0, 0.23),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        child: Semantics(
          button: true,
          label: '국가계좌 장부 열기',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('open-ledger-button'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                height: 104,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFA393B3B),
                      Color(0xFA202322),
                      Color(0xFE111413),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xD6A98A51),
                    width: 1.2,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0xB0000000),
                      blurRadius: 18,
                      offset: Offset(0, 9),
                    ),
                    BoxShadow(
                      color: Color(0x2AFFD37A),
                      blurRadius: 3,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
                child: Stack(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 57,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color(0xFF6E5630),
                                Color(0xFF352817),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFC09A58)),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Color(0xFFFFD88C),
                            size: 29,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Container(
                            height: 88,
                            padding: const EdgeInsets.fromLTRB(10, 9, 8, 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  Color(0xFFF3E6C9),
                                  Color(0xFFD8C39A),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF826841),
                              ),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x77000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Text(
                                  '기록 보관함 · 열람',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: _hubDisplayFont,
                                    color: Color(0xFF68502C),
                                    fontSize: 7.2,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 1,
                                  color: const Color(0x665E4929),
                                ),
                                const SizedBox(height: 7),
                                const Text(
                                  '국가계좌 장부',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: _hubDisplayFont,
                                    color: Color(0xFF2A241C),
                                    fontSize: 12.8,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.45,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                const Text(
                                  '계좌 기록·오늘의 신문 스크랩',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: _hubDisplayFont,
                                    color: Color(0xFF6E6049),
                                    fontSize: 6.9,
                                    height: 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          width: 43,
                          height: 88,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B201E),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: const Color(0xFF79633F)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  _ComputerLabIndicator(color: indicator),
                                  const SizedBox(width: 4),
                                  _ComputerLabIndicator(color: indicator),
                                ],
                              ),
                              const SizedBox(height: 9),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Color(0xFFD8B36C),
                                size: 20,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                status,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: _hubDisplayFont,
                                  color: indicator,
                                  fontSize: 6.6,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Positioned(
                      left: 3,
                      top: 3,
                      child: _ComputerLabBolt(),
                    ),
                    const Positioned(
                      right: 3,
                      top: 3,
                      child: _ComputerLabBolt(),
                    ),
                    const Positioned(
                      left: 3,
                      bottom: 3,
                      child: _ComputerLabBolt(),
                    ),
                    const Positioned(
                      right: 3,
                      bottom: 3,
                      child: _ComputerLabBolt(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComputerLabActionDock extends StatelessWidget {
  const _ComputerLabActionDock({
    required this.onOpenComputer,
    required this.onOpenHomeImprovements,
  });

  final VoidCallback onOpenComputer;
  final VoidCallback onOpenHomeImprovements;

  @override
  Widget build(BuildContext context) => Align(
    alignment: const Alignment(0, 0.42),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xF52B3646),
                  Color(0xF51A2331),
                  Color(0xFA111925),
                ],
              ),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xC7C69B4A), width: 1.15),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0xAA050A11),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: Color(0x2639B8E5),
                  blurRadius: 2,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _ComputerLabActionButton(
                    interactionKey: const Key('open-market-button'),
                    eyebrow: '공용 단말 · 8대',
                    label: '공용 PC',
                    description: '시장·업무 앱 실행',
                    icon: Icons.computer_rounded,
                    accent: const Color(0xFF67D6FF),
                    onTap: onOpenComputer,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _ComputerLabActionButton(
                    interactionKey: const Key('open-home-improvements-button'),
                    eyebrow: '생활 설비',
                    label: '생활환경 관리',
                    description: '조명·냉난방 상태 확인',
                    icon: Icons.tune_rounded,
                    accent: const Color(0xFFFFB95F),
                    onTap: onOpenHomeImprovements,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(left: 5, top: 5, child: _ComputerLabBolt()),
          const Positioned(right: 5, top: 5, child: _ComputerLabBolt()),
          const Positioned(left: 5, bottom: 5, child: _ComputerLabBolt()),
          const Positioned(right: 5, bottom: 5, child: _ComputerLabBolt()),
        ],
      ),
    ),
  );
}

class _ComputerLabBolt extends StatelessWidget {
  const _ComputerLabBolt();

  @override
  Widget build(BuildContext context) => Container(
    width: 4,
    height: 4,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF8F7B56),
      border: Border.all(color: const Color(0xFF322A20), width: 0.6),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    ),
  );
}

class _ComputerLabIconPanel extends StatelessWidget {
  const _ComputerLabIconPanel({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    width: 43,
    height: 68,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          accent.withValues(alpha: 0.22),
          const Color(0xFF121D29),
        ],
      ),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: accent.withValues(alpha: 0.56), width: 1),
      boxShadow: <BoxShadow>[
        const BoxShadow(
          color: Color(0xA8000000),
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
        BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 8),
      ],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned(
          left: 6,
          right: 6,
          top: 8,
          child: Container(height: 1, color: accent.withValues(alpha: 0.22)),
        ),
        Icon(icon, color: accent, size: 25),
        Positioned(
          bottom: 8,
          child: Row(
            children: <Widget>[
              _ComputerLabIndicator(color: accent),
              const SizedBox(width: 3),
              const _ComputerLabIndicator(color: Color(0xFF536070)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ComputerLabIndicator extends StatelessWidget {
  const _ComputerLabIndicator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 3.5,
    height: 3.5,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: <BoxShadow>[
        BoxShadow(color: color.withValues(alpha: 0.58), blurRadius: 4),
      ],
    ),
  );
}

class _ComputerLabActionButton extends StatelessWidget {
  const _ComputerLabActionButton({
    required this.interactionKey,
    required this.eyebrow,
    required this.label,
    required this.description,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final Key interactionKey;
  final String eyebrow;
  final String label;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label 열기',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: interactionKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 102,
          padding: const EdgeInsets.fromLTRB(8, 9, 7, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                accent.withValues(alpha: 0.16),
                const Color(0xF51A2532),
                const Color(0xF5101823),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.58)),
            boxShadow: <BoxShadow>[
              const BoxShadow(
                color: Color(0x8A03070D),
                blurRadius: 7,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Row(
                children: <Widget>[
                  _ComputerLabIconPanel(icon: icon, accent: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          eyebrow,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _hubDisplayFont,
                            color: accent,
                            fontSize: 7.1,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: _hubDisplayFont,
                            color: Colors.white,
                            fontSize: 11.2,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _hubDisplayFont,
                            color: Colors.white.withValues(alpha: 0.66),
                            fontSize: 6.8,
                            height: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Row(
                  children: <Widget>[
                    _ComputerLabIndicator(color: accent),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withValues(alpha: 0.62),
                      size: 14,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 54,
                right: 5,
                bottom: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.transparent,
                        accent.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.34),
                        blurRadius: 5,
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
  );
}

class _ApartmentObjectHotspot extends StatelessWidget {
  const _ApartmentObjectHotspot({
    required this.interactionKey,
    required this.alignment,
    required this.eyebrow,
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.width = 84,
    this.height = 84,
    this.attention = false,
  });

  final Key interactionKey;
  final Alignment alignment;
  final String eyebrow;
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final double width;
  final double height;
  final bool attention;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Tooltip(
        message: '$label · $eyebrow',
        waitDuration: const Duration(milliseconds: 280),
        child: Semantics(
          button: true,
          label: '$label 열기',
          child: SizedBox(
            width: width,
            height: height,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: interactionKey,
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  key: ValueKey(attention),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: (attention ? _coral : accent).withValues(
                      alpha: attention ? 0.20 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: attention ? 0.98 : 0.86,
                      ),
                      width: attention ? 2.6 : 2,
                    ),
                    boxShadow: [
                      const BoxShadow(
                        color: Color(0x450B1423),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                      BoxShadow(
                        color: (attention ? _coral : accent).withValues(
                          alpha: attention ? 0.64 : 0.34,
                        ),
                        blurRadius: attention ? 22 : 14,
                        spreadRadius: attention ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        attention ? Icons.priority_high_rounded : icon,
                        color: Colors.white.withValues(
                          alpha: attention ? 1 : 0.82,
                        ),
                        size: attention ? 34 : 28,
                        shadows: const [
                          Shadow(
                            color: Color(0xA0121A27),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(4, 0, 4, 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xD91B2537),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: const TextStyle(
                                fontFamily: _hubDisplayFont,
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ApartmentActionRail extends StatelessWidget {
  const _ApartmentActionRail({
    required this.hasPendingDecision,
    required this.campaignComplete,
    required this.marketMinute,
    required this.messengerUnread,
    required this.onOpenMessenger,
    required this.onOpenRelationships,
    required this.onOpenCalendar,
    required this.onAdvanceHour,
    required this.onAdvanceDay,
    required this.onAdvanceBatch,
    required this.onOpenEnding,
    required this.onHelp,
  });

  final bool hasPendingDecision;
  final bool campaignComplete;
  final int marketMinute;
  final int messengerUnread;
  final VoidCallback onOpenMessenger;
  final VoidCallback onOpenRelationships;
  final VoidCallback onOpenCalendar;
  final VoidCallback onAdvanceHour;
  final VoidCallback onAdvanceDay;
  final VoidCallback onAdvanceBatch;
  final VoidCallback onOpenEnding;
  final VoidCallback onHelp;

  Future<void> _openTimeActions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFBF2),
      builder: (sheetContext) => _ApartmentTimeActionsSheet(
        hasPendingDecision: hasPendingDecision,
        campaignComplete: campaignComplete,
        marketMinute: marketMinute,
        onOpenCalendar: onOpenCalendar,
        onAdvanceHour: onAdvanceHour,
        onAdvanceDay: onAdvanceDay,
        onAdvanceBatch: onAdvanceBatch,
        onOpenEnding: onOpenEnding,
        onHelp: onHelp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _ApartmentRailButton(
        buttonKey: const Key('phone-messenger-button'),
        tooltip: messengerUnread > 0
            ? '데시멀톡 · 새 메시지 $messengerUnread개'
            : '데시멀톡 · 동기들과 대화',
        icon: Icons.smartphone_rounded,
        badgeCount: messengerUnread,
        onPressed: onOpenMessenger,
      ),
      const SizedBox(height: 7),
      _ApartmentRailButton(
        buttonKey: const Key('relationship-status-button'),
        tooltip: '캐릭터와 관계 보기',
        icon: Icons.favorite_rounded,
        onPressed: onOpenRelationships,
      ),
      const SizedBox(height: 7),
      _ApartmentRailButton(
        buttonKey: const Key('hub-time-actions-button'),
        tooltip: '시간·일정·달력',
        icon: Icons.more_time_rounded,
        onPressed: () => _openTimeActions(context),
      ),
    ],
  );
}

class _ApartmentTimeActionsSheet extends StatelessWidget {
  const _ApartmentTimeActionsSheet({
    required this.hasPendingDecision,
    required this.campaignComplete,
    required this.marketMinute,
    required this.onOpenCalendar,
    required this.onAdvanceHour,
    required this.onAdvanceDay,
    required this.onAdvanceBatch,
    required this.onOpenEnding,
    required this.onHelp,
  });

  final bool hasPendingDecision;
  final bool campaignComplete;
  final int marketMinute;
  final VoidCallback onOpenCalendar;
  final VoidCallback onAdvanceHour;
  final VoidCallback onAdvanceDay;
  final VoidCallback onAdvanceBatch;
  final VoidCallback onOpenEnding;
  final VoidCallback onHelp;

  void _run(BuildContext context, VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final ended = marketMinute >= marketDayEndMinute;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '시간과 일정',
              style: TextStyle(
                fontFamily: _hubDisplayFont,
                color: _ink,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '달력을 확인하거나 게임 시간을 진행합니다.',
              style: TextStyle(
                color: Color(0xFF65708A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _ApartmentTimeActionTile(
              tileKey: const Key('life-calendar-button'),
              icon: Icons.calendar_month_rounded,
              title: '성장 달력',
              subtitle: '날짜와 지난 사건 기록 확인',
              onTap: () => _run(context, onOpenCalendar),
            ),
            _ApartmentTimeActionTile(
              tileKey: const Key('advance-hour-button'),
              icon: Icons.hourglass_bottom_rounded,
              title: '1시간 보내기',
              subtitle: hasPendingDecision
                  ? '새 기록을 먼저 확인해야 합니다'
                  : ended
                  ? '오늘 진행 가능한 시간이 끝났습니다'
                  : '게임 시간을 60분 진행',
              onTap: hasPendingDecision || ended
                  ? null
                  : () => _run(context, onAdvanceHour),
            ),
            _ApartmentTimeActionTile(
              tileKey: const Key('advance-day-button'),
              icon: campaignComplete
                  ? Icons.emoji_events_rounded
                  : Icons.bedtime_rounded,
              title: campaignComplete ? '최종 결산' : '하루 보내기',
              subtitle: hasPendingDecision
                  ? '새 기록을 먼저 확인해야 합니다'
                  : campaignComplete
                  ? '캠페인 결과 확인'
                  : '오늘을 마치고 다음 날로 진행',
              onTap: hasPendingDecision
                  ? null
                  : () => _run(
                      context,
                      campaignComplete ? onOpenEnding : onAdvanceDay,
                    ),
            ),
            _ApartmentTimeActionTile(
              tileKey: const Key('advance-batch-button'),
              icon: Icons.fast_forward_rounded,
              title: '빠르게 진행',
              subtitle: '여러 날을 한 번에 진행',
              onTap: hasPendingDecision || campaignComplete
                  ? null
                  : () => _run(context, onAdvanceBatch),
            ),
            _ApartmentTimeActionTile(
              tileKey: const Key('hub-help-button'),
              icon: Icons.help_outline_rounded,
              title: '허브 사용법',
              subtitle: '장소와 아이콘 설명 다시 보기',
              onTap: () => _run(context, onHelp),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApartmentTimeActionTile extends StatelessWidget {
  const _ApartmentTimeActionTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    key: tileKey,
    enabled: onTap != null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    dense: true,
    leading: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(
          0xFF243451,
        ).withValues(alpha: onTap == null ? 0.08 : 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: onTap == null
            ? const Color(0xFF9AA2B1)
            : const Color(0xFF243451),
      ),
    ),
    title: Text(
      title,
      style: TextStyle(
        color: onTap == null ? const Color(0xFF8C939F) : _ink,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    ),
    subtitle: Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
    ),
    trailing: Icon(
      onTap == null ? Icons.lock_rounded : Icons.chevron_right_rounded,
      size: 20,
    ),
    onTap: onTap,
  );
}

class _ApartmentRailButton extends StatelessWidget {
  const _ApartmentRailButton({
    required this.buttonKey,
    required this.tooltip,
    required this.onPressed,
    this.assetPath,
    this.icon,
    this.badgeCount = 0,
  }) : assert(assetPath != null || icon != null);

  final Key buttonKey;
  final String tooltip;
  final String? assetPath;
  final IconData? icon;
  final int badgeCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    waitDuration: const Duration(milliseconds: 280),
    child: Semantics(
      button: true,
      label: tooltip,
      child: SizedBox(
        width: 46,
        height: 46,
        child: ElevatedButton(
          key: buttonKey,
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            elevation: 5,
            shadowColor: const Color(0x660B1423),
            backgroundColor: const Color(0xF7FFF8E9),
            foregroundColor: _ink,
            disabledBackgroundColor: const Color(0xE8EEE8DC),
            disabledForegroundColor: const Color(0xFF8C8F96),
            shape: const CircleBorder(
              side: BorderSide(color: Color(0xFF243451), width: 2),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              assetPath != null
                  ? Image.asset(
                      assetPath!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    )
                  : Icon(icon, size: 25, color: const Color(0xFF243451)),
              if (badgeCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    key: ValueKey('rail-badge-$badgeCount'),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE85252),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ApartmentLocationDock extends StatelessWidget {
  const _ApartmentLocationDock({required this.current, required this.onMove});

  final _ApartmentPlace current;
  final ValueChanged<_ApartmentPlace> onMove;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      key: const Key('apartment-location-dock'),
      height: 58,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xF21B2639),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7A948), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73070A12),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final place in _ApartmentPlace.values)
            Expanded(
              child: _ApartmentLocationDockItem(
                place: place,
                selected: place == current,
                onTap: () => onMove(place),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ApartmentLocationDockItem extends StatelessWidget {
  const _ApartmentLocationDockItem({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final _ApartmentPlace place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = _ApartmentPlaceDetails.forPlace(place);
    return Semantics(
      button: !selected,
      selected: selected,
      label: selected
          ? '현재 장소 ${details.shortTitle}'
          : '${details.shortTitle}으로 이동',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key(
            selected
                ? 'apartment-current-${details.id}'
                : 'apartment-go-${details.id}',
          ),
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected
                  ? details.accent.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              border: selected
                  ? Border.all(
                      color: details.accent.withValues(alpha: 0.9),
                      width: 1.2,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  details.icon,
                  size: 20,
                  color: selected ? details.accent : const Color(0xFFDCE4F1),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    details.shortTitle,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: _hubDisplayFont,
                      color: selected ? Colors.white : const Color(0xFFBAC4D4),
                      fontSize: 7.8,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
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

class _ApartmentFallbackBackground extends StatelessWidget {
  const _ApartmentFallbackBackground({required this.details});

  final _ApartmentPlaceDetails details;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF172031),
          details.accent.withValues(alpha: 0.48),
          const Color(0xFF292235),
        ],
      ),
    ),
    child: Center(
      child: Icon(
        details.icon,
        size: 112,
        color: Colors.white.withValues(alpha: 0.11),
      ),
    ),
  );
}

class _ApartmentPlaceDetails {
  const _ApartmentPlaceDetails({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.hint,
    required this.assetPath,
    required this.icon,
    required this.accent,
  });

  final String id;
  final String title;
  final String shortTitle;
  final String hint;
  final String assetPath;
  final IconData icon;
  final Color accent;

  static _ApartmentPlaceDetails forPlace(
    _ApartmentPlace place,
  ) => switch (place) {
    _ApartmentPlace.bedroom => const _ApartmentPlaceDetails(
      id: 'bedroom',
      title: '프로젝트 데시멀 · 생활 라운지',
      shortTitle: '라운지',
      hint: '오늘의 동기 · 데시멀톡',
      assetPath:
          'assets/images/cinematic_soft_painted/decimal/bg_decimal_living_lounge_1999_v1.png',
      icon: Icons.bed_rounded,
      accent: Color(0xFF82D7FF),
    ),
    _ApartmentPlace.livingRoom => const _ApartmentPlaceDetails(
      id: 'living-room',
      title: '프로젝트 데시멀 · 투자실',
      shortTitle: '투자실',
      hint: '동기 10명 · 운영관 · 운용 회의',
      assetPath:
          'assets/images/cinematic_soft_painted/decimal/bg_decimal_trading_floor_dawn_2000_v1.png',
      icon: Icons.monitor_heart_rounded,
      accent: Color(0xFFFFCB78),
    ),
    _ApartmentPlace.kitchen => const _ApartmentPlaceDetails(
      id: 'kitchen',
      title: '프로젝트 데시멀 · 공용 컴퓨터실',
      shortTitle: '컴퓨터실',
      hint: '공용 PC 8대 · 공동 작업 · 생활설비',
      assetPath:
          'assets/images/cinematic_soft_painted/decimal/bg_decimal_communal_computer_lounge_2000_v2.png',
      icon: Icons.computer_rounded,
      accent: Color(0xFF78D9FF),
    ),
    _ApartmentPlace.corridor => const _ApartmentPlaceDetails(
      id: 'corridor',
      title: '프로젝트 데시멀 · 기록 보관실',
      shortTitle: '기록실',
      hint: '국가계좌 장부 · 신문 스크랩',
      assetPath:
          'assets/images/cinematic_soft_painted/decimal/bg_decimal_records_archive_2000_v1.png',
      icon: Icons.folder_copy_rounded,
      accent: Color(0xFF9ED9EF),
    ),
    _ApartmentPlace.neighborhood => const _ApartmentPlaceDetails(
      id: 'neighborhood',
      title: '프로젝트 데시멀 · 본관 앞',
      shortTitle: '본관 앞',
      hint: '국가계좌 창구 · 원내 실습',
      assetPath:
          'assets/images/cinematic_soft_painted/decimal/bg_decimal_gangnam_exterior_winter_1999_v1.png',
      icon: Icons.account_balance_rounded,
      accent: Color(0xFF98E5C1),
    ),
  };
}
