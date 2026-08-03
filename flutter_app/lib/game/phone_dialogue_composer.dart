import 'phone_messenger_state.dart';
import 'relationship_state.dart';
import 'stable_hash.dart';

enum PhonePlayerIntent {
  boundary,
  apology,
  gratitude,
  lossShare,
  gainShare,
  investmentAdvice,
  investmentReflection,
  emotionalSupport,
  planning,
  classHelp,
  casual,
  unknown,
}

enum PhoneInvestmentSituation {
  unavailable,
  marketClosed,
  flat,
  thriving,
  recovering,
  protectingGains,
  deepeningLoss,
}

const phoneRelationshipBandCount = 6;
final int phoneDialogueCombinationSpace =
    phoneMessengerContacts.length *
    phoneRelationshipBandCount *
    PhoneInvestmentSituation.values.length *
    PhonePlayerIntent.values.length *
    3 *
    3 *
    3;

class PhoneInvestmentConversationContext {
  const PhoneInvestmentConversationContext({
    this.hasCurrentReport = false,
    this.marketClosed = false,
    this.playerDailyProfitLoss = 0,
    this.playerCumulativeProfitLoss = 0,
    this.playerTotal = 0,
    this.playerRank = 0,
    this.contactDailyProfitLoss = 0,
    this.contactRank = 0,
  });

  final bool hasCurrentReport;
  final bool marketClosed;
  final int playerDailyProfitLoss;
  final int playerCumulativeProfitLoss;
  final int playerTotal;
  final int playerRank;
  final int contactDailyProfitLoss;
  final int contactRank;

  PhoneInvestmentSituation get situation {
    if (marketClosed) return PhoneInvestmentSituation.marketClosed;
    if (!hasCurrentReport) return PhoneInvestmentSituation.unavailable;
    if (playerDailyProfitLoss == 0) return PhoneInvestmentSituation.flat;
    if (playerDailyProfitLoss > 0) {
      return playerCumulativeProfitLoss < 0
          ? PhoneInvestmentSituation.recovering
          : PhoneInvestmentSituation.thriving;
    }
    return playerCumulativeProfitLoss > 0
        ? PhoneInvestmentSituation.protectingGains
        : PhoneInvestmentSituation.deepeningLoss;
  }
}

class PhoneDialogueContext {
  const PhoneDialogueContext({
    required this.worldSeed,
    required this.day,
    required this.marketMinute,
    required this.contact,
    required this.progress,
    required this.relationship,
    required this.investment,
    this.recentMemories = const <PhoneConversationMemory>[],
  });

  final String worldSeed;
  final int day;
  final int marketMinute;
  final PhoneContactDefinition contact;
  final PhoneThreadProgress progress;
  final GirlRelationshipProgress? relationship;
  final PhoneInvestmentConversationContext investment;
  final List<PhoneConversationMemory> recentMemories;
}

class PhoneComposedReply {
  const PhoneComposedReply({
    required this.text,
    required this.intent,
    required this.investmentSituation,
    required this.meaningful,
    required this.affectionDelta,
    required this.trustDelta,
    required this.closenessDelta,
    required this.investmentRespectDelta,
    required this.combinationKey,
  });

  final String text;
  final PhonePlayerIntent intent;
  final PhoneInvestmentSituation investmentSituation;
  final bool meaningful;
  final int affectionDelta;
  final int trustDelta;
  final int closenessDelta;
  final int investmentRespectDelta;
  final String combinationKey;
}

PhonePlayerIntent classifyPhoneIntent(String rawText) {
  final text = rawText.toLowerCase().replaceAll(' ', '');
  bool hasAny(List<String> words) => words.any(text.contains);

  if (hasAny(const ['야한', '벗어', '몸매', '죽어', '꺼져', '멍청', '바보'])) {
    return PhonePlayerIntent.boundary;
  }
  if (hasAny(const ['미안', '사과', '잘못했', '실수했'])) {
    return PhonePlayerIntent.apology;
  }
  if (hasAny(const ['고마워', '고맙', '덕분', '감사'])) {
    return PhonePlayerIntent.gratitude;
  }
  if (hasAny(const ['손해', '손실', '잃었', '물렸', '마이너스', '망했'])) {
    return PhonePlayerIntent.lossShare;
  }
  if (hasAny(const ['벌었', '수익났', '플러스', '익절', '대박'])) {
    return PhonePlayerIntent.gainShare;
  }
  if (hasAny(const ['추천', '뭘사', '뭐사', '매수할까', '매도할까', '조언'])) {
    return PhonePlayerIntent.investmentAdvice;
  }
  if (hasAny(const ['왜올랐', '왜내렸', '복기', '분석', '손익', '투자', '주식', '종목'])) {
    return PhonePlayerIntent.investmentReflection;
  }
  if (hasAny(const ['힘들', '불안', '무서', '속상', '괜찮아', '위로'])) {
    return PhonePlayerIntent.emotionalSupport;
  }
  if (hasAny(const ['내일', '주말', '같이', '약속', '계획', '만날'])) {
    return PhonePlayerIntent.planning;
  }
  if (hasAny(const ['실습', '공부', '복습', '숙제', '컴퓨터', 'pc', '모르', '헷갈'])) {
    return PhonePlayerIntent.classHelp;
  }
  if (hasAny(const ['안녕', '뭐해', '뭐하', '심심', '밥', '먹', '놀', '잘자', '자냐'])) {
    return PhonePlayerIntent.casual;
  }
  return PhonePlayerIntent.unknown;
}

PhoneComposedReply composePhoneReply(
  PhoneDialogueContext context,
  String playerText,
) {
  final intent = classifyPhoneIntent(playerText);
  final situation = context.investment.situation;
  final voice = _voices[context.contact.id] ?? _voices.values.first;
  final stage = context.relationship?.stage ?? RelationshipStage.newClassmate;
  final key =
      '${context.worldSeed}:${context.day}:${context.contact.id}:'
      '${context.progress.totalExchanges}:$intent:$situation:${stage.name}';
  final relationshipLine = voice.relationshipLines[stage.index];
  final situationLine = voice.investmentLines[situation.index];
  final pivot = _intentPivots[intent]![_pick('$key:pivot', 3)];
  final followUp =
      voice.followUps[_pick('$key:follow', voice.followUps.length)];
  final repeated =
      context.progress.lastIntent == intent.name &&
      context.progress.sameIntentStreak >= 2;

  final components = <String>[relationshipLine];
  if (intent == PhonePlayerIntent.boundary) {
    components.add(context.contact.boundaryReply);
  } else {
    final memory = _latestPastMemory(context);
    if (memory != null && _pick('$key:memory', 2) == 0) {
      final quote = _shortQuote(memory.playerText);
      components.add(
        '${voice.recallPrefixes[_pick('$key:recall', voice.recallPrefixes.length)]} “$quote”라고 했던 것도 기억해.',
      );
    }
    if (situation != PhoneInvestmentSituation.unavailable ||
        _isInvestmentIntent(intent)) {
      components.add(situationLine);
    }
    components.add(_baseReply(context.contact, intent));
    components.add(repeated ? voice.repetitionLine : pivot);
    components.add(followUp);
  }

  var affectionDelta = _affectionDelta(intent);
  var trustDelta = _trustDelta(intent);
  var closenessDelta = _closenessDelta(intent);
  var investmentRespectDelta = _investmentRespectDelta(intent);
  if (repeated) {
    affectionDelta = 0;
    trustDelta = 0;
    closenessDelta = 0;
    investmentRespectDelta = 0;
  }

  return PhoneComposedReply(
    text: _fitReply(components),
    intent: intent,
    investmentSituation: situation,
    meaningful: intent != PhonePlayerIntent.unknown,
    affectionDelta: affectionDelta,
    trustDelta: trustDelta,
    closenessDelta: closenessDelta,
    investmentRespectDelta: investmentRespectDelta,
    combinationKey: key,
  );
}

class _VoicePack {
  const _VoicePack({
    required this.relationshipLines,
    required this.investmentLines,
    required this.followUps,
    required this.recallPrefixes,
    required this.repetitionLine,
  });

  final List<String> relationshipLines;
  final List<String> investmentLines;
  final List<String> followUps;
  final List<String> recallPrefixes;
  final String repetitionLine;
}

const _voices = <String, _VoicePack>{
  'kim_hakjun': _VoicePack(
    relationshipLines: [
      '용건부터 말해.',
      '그래, 들어 볼게.',
      '이번엔 네 계산을 믿어 볼게.',
      '말 길어져도 괜찮아.',
      '중요한 얘기면 끝까지 듣지.',
      '네 판단이면 먼저 검토할게.',
    ],
    investmentLines: [
      '아직 오늘 장부가 안 닫혔어.',
      '휴장일엔 포지션보다 기록을 보자.',
      '오늘 손익은 거의 제자리야.',
      '오늘도 누적도 플러스네. 비용까지 빼고 봐.',
      '오늘 벌었지만 누적은 아직 마이너스야. 회복으로 봐.',
      '오늘은 잃어도 누적 수익 안쪽이야. 방어선을 확인해.',
      '오늘도 누적도 마이너스야. 원금부터 지켜.',
    ],
    followUps: ['숫자 하나만 정확히 말해 봐.', '네 기준가는 얼마였어?', '다음 행동을 한 줄로 정해 봐.'],
    recallPrefixes: ['장부에 남은 걸 보니까', '전에 계산할 때', '지난 얘기 기준이면'],
    repetitionLine: '같은 질문은 숫자가 달라졌을 때 다시 보자.',
  ),
  'kim_seoa': _VoicePack(
    relationshipLines: [
      '응, 천천히 말해 줘.',
      '네 얘기는 적어 둘게.',
      '오늘 마음까지 같이 기록해 둘까?',
      '무슨 말인지 끝까지 들어 볼게.',
      '네가 먼저 말해 줘서 고마워.',
      '우리가 쌓은 기록이 있으니까 괜찮아.',
    ],
    investmentLines: [
      '아직 오늘 결과표가 없어서 단정하면 안 될 것 같아.',
      '장은 쉬어도 지난 기록은 정리할 수 있어.',
      '오늘은 큰 변화 없이 버틴 날이네.',
      '오늘도 벌었고 누적도 플러스라 다행이야.',
      '오늘은 벌었지만 전체로는 아직 손실이야. 그래도 회복 중이네.',
      '오늘 손실은 났지만 누적 수익은 남아 있어.',
      '오늘도 잃었고 누적도 마이너스라 마음이 무겁겠다.',
    ],
    followUps: ['오늘 느낀 것도 같이 적어 둘까?', '내일 확인할 약속 하나 정할래?', '밥은 먹었는지도 말해 줘.'],
    recallPrefixes: ['내 기록에는', '전에 네가 조용히', '지난번 대화에서'],
    repetitionLine: '같은 마음이 계속 드는 것 같아. 오늘은 이유를 하나만 더 적어 보자.',
  ),
  'lee_jian': _VoicePack(
    relationshipLines: [
      '응. 짧게 말해.',
      '일단 들어 볼게.',
      '네 말이면 직접 확인해 보지.',
      '말해. 지금은 안 끊을게.',
      '굳이 숨길 필요 없잖아.',
      '네 판단 과정은 꽤 믿을 만해.',
    ],
    investmentLines: [
      '결과 안 나왔어. 지금 답하면 추측이야.',
      '휴장이면 컴퓨터 끄고 구조부터 봐.',
      '움직임 거의 없어. 억지로 의미 붙이지 마.',
      '오늘도 전체도 플러스. 잘 됐네.',
      '오늘 수익은 회복분이야. 아직 본전은 아니고.',
      '오늘 빠졌어도 전체 수익은 남았네.',
      '오늘도 전체도 손실. 포지션 크기부터 줄여.',
    ],
    followUps: ['차트 말고 실제로 뭘 봤어?', '내일 직접 확인할 건 뭐야?', '한 번 더 재현할 수 있어?'],
    recallPrefixes: ['전에 직접 확인했을 때', '기억나는 건', '지난번 네 말 중엔'],
    repetitionLine: '같은 말 반복해도 데이터는 안 바뀌어. 새 근거 줘.',
  ),
  'choi_iseo': _VoicePack(
    relationshipLines: [
      '응, 듣고 있어.',
      '네 말의 느낌부터 알고 싶어.',
      '조금 더 솔직하게 말해도 돼.',
      '오늘은 네 쪽으로 가까이 앉을게.',
      '그 마음을 가볍게 넘기고 싶지 않아.',
      '네가 느낀 결을 이제는 알아.',
    ],
    investmentLines: [
      '아직 결과가 없으니까 마음부터 앞서가진 말자.',
      '장이 쉬는 날엔 숫자 소음도 잠깐 쉬어.',
      '오늘은 잔잔했네. 그런 날도 필요해.',
      '오늘도 전체도 밝은 쪽이네. 들뜨지만 않으면 좋겠어.',
      '오늘은 올랐지만 오래 쌓인 손실의 색은 아직 남아 있어.',
      '오늘은 내려도 전체 흐름의 여유는 남았네.',
      '오늘도 전체도 어두운 쪽이야. 혼자 버티진 마.',
    ],
    followUps: ['그때 네 마음은 어땠어?', '숫자를 색으로 보면 어떤 느낌이야?', '오늘은 어디까지 버틸 수 있어?'],
    recallPrefixes: ['전에 네 표정이랑 같이', '내가 기억하는 건', '지난번 그 말의 느낌은'],
    repetitionLine: '같은 말을 되풀이할수록 마음이 더 굳어. 다른 느낌도 찾아보자.',
  ),
  'jung_arin': _VoicePack(
    relationshipLines: [
      '핵심부터 말해.',
      '좋아, 바로 정리하자.',
      '이번 건 같이 실행해 보자.',
      '네 계획이면 일정부터 비울게.',
      '중요한 결정이면 내가 책임지고 듣지.',
      '우리 사이는 결론까지 같이 내는 거야.',
    ],
    investmentLines: [
      '마감 전이야. 결과 없이 회의하지 마.',
      '휴장일엔 다음 주 계획표를 확정하자.',
      '오늘은 보합. 계획 이탈 여부만 확인해.',
      '오늘도 누적도 플러스. 목표와 상한을 다시 잡아.',
      '오늘 수익은 났지만 누적 손실을 메우는 단계야.',
      '오늘 손실이어도 누적 수익은 남았어. 손절선을 점검해.',
      '일간·누적 모두 손실. 즉시 규모와 기한을 수정해.',
    ],
    followUps: ['그래서 내일 몇 시에 뭘 할 건데?', '수치 목표를 하나 정해.', '담당과 마감부터 나누자.'],
    recallPrefixes: ['지난 계획표에는', '전에 합의한 건', '내가 적어 둔 실행안엔'],
    repetitionLine: '같은 안건은 그만. 변경된 수치와 다음 행동을 가져와.',
  ),
  'park_haeun': _VoicePack(
    relationshipLines: [
      '응, 네 편에서 들을게.',
      '지금은 네 마음부터 챙기자.',
      '혼자 안고 있지 않아도 돼.',
      '네가 기대도 괜찮아.',
      '무슨 결과여도 같이 정리하자.',
      '네가 흔들릴 때 먼저 알아챌게.',
    ],
    investmentLines: [
      '아직 결과가 안 나왔으니 미리 자신을 탓하지 마.',
      '휴장일엔 몸과 마음도 쉬어야 해.',
      '오늘은 그대로 지킨 것도 성과야.',
      '오늘도 전체도 수익이라 기쁘겠다. 너무 무리하진 말고.',
      '오늘 번 건 분명 좋은데 누적 손실은 아직 남았네. 조급해하지 마.',
      '오늘 잃었어도 지금까지 만든 수익의 여유는 있어.',
      '오늘도 전체도 손실이라 속상하겠다. 먼저 숨부터 돌리자.',
    ],
    followUps: [
      '지금 내가 어떻게 도와주면 좋겠어?',
      '오늘은 잠깐 같이 걸을까?',
      '혼자 결정하지 말고 한 번 더 말해 줘.',
    ],
    recallPrefixes: ['전에 힘들다고 했을 때', '내가 기억하기로는', '지난번 네 마음은'],
    repetitionLine: '같은 걱정이 계속 돌아오네. 답보다 먼저 네 상태를 보자.',
  ),
  'han_sua': _VoicePack(
    relationshipLines: [
      '어, 말해 봐!',
      '그거 재밌겠다. 더 얘기해.',
      '우리 이번엔 진짜 해 보자.',
      '네 얘기면 시간 가는 줄 모르겠다.',
      '나한테 제일 먼저 말한 거지?',
      '좋아, 어디든 같이 가 보자.',
    ],
    investmentLines: [
      '아직 결과도 안 나왔는데 벌써 결론 내리면 재미없지!',
      '휴장일이면 밖에 나가서 아이디어 찾자.',
      '오늘은 조용했네. 내일 튈 수도 있잖아.',
      '오늘도 전체도 플러스! 그래도 전부 걸지는 마.',
      '오늘 벌긴 했는데 전체는 아직 마이너스네. 반등 첫 장면인가?',
      '오늘은 빠져도 쌓아 둔 수익이 있네. 다음 수를 보자.',
      '오늘도 전체도 마이너스야. 무작정 더 세게 가면 안 돼.',
    ],
    followUps: ['그다음엔 뭘 시험해 볼까?', '주말에 같이 확인하러 갈래?', '이걸 이야기로 만들면 결말이 뭐야?'],
    recallPrefixes: ['전에 네가 신나서', '내 기억엔', '지난번 우리 얘기에서'],
    repetitionLine: '또 같은 주제야? 이번엔 완전히 다른 가설로 가 보자!',
  ),
  'oh_jiwoo': _VoicePack(
    relationshipLines: [
      '오, 일단 들어 보지.',
      '그 주장 흥미로운데?',
      '반대편까지 같이 따져 보자.',
      '네 논리라면 오래 얘기해도 돼.',
      '우리끼린 허점도 숨기지 말자.',
      '좋아, 네가 던지면 내가 끝까지 받아 줄게.',
    ],
    investmentLines: [
      '아직 결과가 없는데 확신부터 사는 건 비싸.',
      '휴장일이니까 오히려 반대 가설을 세워 보자.',
      '오늘은 보합. 시장이 대답을 미룬 셈이지.',
      '오늘도 누적도 플러스. 이제 반대 시나리오가 더 중요해.',
      '오늘 수익인데 누적 손실? 반등인지 착시인지 구분해야지.',
      '오늘 손실인데 누적 수익? 이탈인지 소음인지 보자.',
      '오늘도 누적도 손실. 네 가설이 틀렸다는 증거부터 모아.',
    ],
    followUps: [
      '반대 입장에서 한 번 말해 볼래?',
      '네 가설을 깨는 조건은 뭐야?',
      '내가 반박해도 끝까지 지킬 근거 있어?',
    ],
    recallPrefixes: ['지난번 네 주장에선', '내가 기억한 논점은', '전에 우리가 반박하다가'],
    repetitionLine: '같은 주장만 반복하면 토론이 아니지. 반증 하나 가져와.',
  ),
  'yoon_chaea': _VoicePack(
    relationshipLines: [
      '전제부터 말해 줘.',
      '맥락까지 들을게.',
      '네 패턴은 어느 정도 파악했어.',
      '장기 계획에 넣을 이야기야?',
      '네 선택이 내 계획에도 중요해졌어.',
      '이제는 네가 말하지 않은 변수도 함께 보게 돼.',
    ],
    investmentLines: [
      '오늘 데이터가 닫히지 않았어. 판단 보류.',
      '휴장은 관찰 구간이지 빈 날이 아니야.',
      '오늘 변화는 미미해. 한 달 패턴을 유지해.',
      '일간과 누적 모두 양수. 이제 과최적화를 경계해.',
      '일간은 양수지만 누적은 음수. 추세 전환으로 단정하긴 일러.',
      '일간은 음수지만 누적은 양수. 허용 변동 범위인지 확인해.',
      '일간과 누적 모두 음수. 가정과 노출도를 동시에 재검토해.',
    ],
    followUps: ['그 판단의 전제는 뭐야?', '한 달 뒤에도 유효한 선택일까?', '변수가 하나 더 생기면 어떻게 바뀌어?'],
    recallPrefixes: ['장기 기록상', '이전 대화의 전제는', '내가 보관한 패턴에는'],
    repetitionLine: '동일한 입력에는 동일한 결론뿐이야. 새 변수를 추가해 줘.',
  ),
};

const _intentPivots = <PhonePlayerIntent, List<String>>{
  PhonePlayerIntent.boundary: [
    '선을 지켜 줘.',
    '그 표현은 받아들이기 어려워.',
    '존중 없는 대화는 이어 가지 않을게.',
  ],
  PhonePlayerIntent.apology: [
    '무엇을 미안해하는지 말해 줘서 이해가 돼.',
    '다음에 어떻게 달라질지가 더 중요해.',
    '사과를 들었으니 행동도 지켜볼게.',
  ],
  PhonePlayerIntent.gratitude: [
    '그렇게 말해 주니 나도 힘이 난다.',
    '도움이 됐다면 다행이야.',
    '고마움을 바로 말하는 건 좋은 습관이야.',
  ],
  PhonePlayerIntent.lossShare: [
    '손실액과 잘못된 판단은 따로 봐야 해.',
    '잃은 날일수록 다음 선택을 작게 만들어.',
    '오늘 손실이 네 전체 실력을 뜻하진 않아.',
  ],
  PhonePlayerIntent.gainShare: [
    '번 돈과 좋은 판단이 항상 같은 건 아니야.',
    '수익이 난 이유를 남겨야 다음에도 써먹지.',
    '기쁜 건 기쁜 거고, 위험은 다시 계산하자.',
  ],
  PhonePlayerIntent.investmentAdvice: [
    '종목 이름보다 네 기준과 기간이 먼저야.',
    '매수·매도보다 틀렸을 때 나올 조건을 정해.',
    '내 답을 따라 사는 건 조언이 아니라 책임 회피야.',
  ],
  PhonePlayerIntent.investmentReflection: [
    '결과보다 그때 알고 있던 정보로 복기해.',
    '맞힌 이유와 틀린 이유를 같은 형식으로 적어.',
    '가격 변화와 네 판단 변화를 분리해서 보자.',
  ],
  PhonePlayerIntent.emotionalSupport: [
    '지금 감정을 숨기지 않아도 돼.',
    '답을 급히 내기보다 네 상태부터 확인하자.',
    '혼자 결론 내리기 전에 한 번 더 이야기해.',
  ],
  PhonePlayerIntent.planning: [
    '시간과 장소까지 정해야 진짜 계획이야.',
    '무리하지 않는 범위부터 같이 잡자.',
    '좋아, 서로 준비할 걸 나누자.',
  ],
  PhonePlayerIntent.classHelp: [
    '모르는 지점을 한 줄로 좁히면 풀기 쉬워.',
    '답을 외우기보다 순서를 다시 밟아 보자.',
    '막힌 화면이나 문장을 정확히 알려 줘.',
  ],
  PhonePlayerIntent.casual: [
    '별일 없는 얘기도 계속 들려줘.',
    '이런 이야기면 부담 없이 답할 수 있어.',
    '잠깐 쉬면서 이야기하는 것도 좋네.',
  ],
  PhonePlayerIntent.unknown: [
    '무슨 뜻인지 한 가지만 더 구체적으로 말해 줘.',
    '핵심이 무엇인지 아직은 잘 모르겠어.',
    '상황이나 원하는 답을 조금 더 알려 줘.',
  ],
};

bool _isInvestmentIntent(PhonePlayerIntent intent) =>
    intent == PhonePlayerIntent.lossShare ||
    intent == PhonePlayerIntent.gainShare ||
    intent == PhonePlayerIntent.investmentAdvice ||
    intent == PhonePlayerIntent.investmentReflection;

String _baseReply(PhoneContactDefinition contact, PhonePlayerIntent intent) =>
    switch (intent) {
      PhonePlayerIntent.lossShare ||
      PhonePlayerIntent.gainShare ||
      PhonePlayerIntent.investmentAdvice ||
      PhonePlayerIntent.investmentReflection => contact.stockReply,
      PhonePlayerIntent.classHelp ||
      PhonePlayerIntent.planning => contact.classReply,
      PhonePlayerIntent.apology ||
      PhonePlayerIntent.gratitude ||
      PhonePlayerIntent.emotionalSupport ||
      PhonePlayerIntent.casual => contact.casualReply,
      PhonePlayerIntent.boundary => contact.boundaryReply,
      PhonePlayerIntent.unknown => contact.fallbackReply,
    };

int _affectionDelta(PhonePlayerIntent intent) => switch (intent) {
  PhonePlayerIntent.boundary => -2,
  PhonePlayerIntent.unknown => 0,
  _ => 1,
};

int _trustDelta(PhonePlayerIntent intent) => switch (intent) {
  PhonePlayerIntent.boundary => -3,
  PhonePlayerIntent.apology || PhonePlayerIntent.emotionalSupport => 2,
  PhonePlayerIntent.gratitude ||
  PhonePlayerIntent.planning ||
  PhonePlayerIntent.classHelp => 1,
  _ => 0,
};

int _closenessDelta(PhonePlayerIntent intent) => switch (intent) {
  PhonePlayerIntent.boundary => -2,
  PhonePlayerIntent.apology ||
  PhonePlayerIntent.gratitude ||
  PhonePlayerIntent.emotionalSupport ||
  PhonePlayerIntent.casual => 2,
  PhonePlayerIntent.unknown => 0,
  _ => 1,
};

int _investmentRespectDelta(PhonePlayerIntent intent) => switch (intent) {
  PhonePlayerIntent.boundary => -1,
  PhonePlayerIntent.investmentReflection => 2,
  PhonePlayerIntent.lossShare || PhonePlayerIntent.gainShare => 1,
  PhonePlayerIntent.planning || PhonePlayerIntent.classHelp => 1,
  _ => 0,
};

PhoneConversationMemory? _latestPastMemory(PhoneDialogueContext context) {
  for (final memory in context.recentMemories.reversed) {
    if (memory.day < context.day) return memory;
  }
  return null;
}

int _pick(String seed, int length) => stableHash31(seed) % length;

String _shortQuote(String value) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized.length <= 24
      ? normalized
      : '${normalized.substring(0, 23)}…';
}

String _fitReply(List<String> components) {
  final result = components.where((part) => part.trim().isNotEmpty).join(' ');
  final limit = phoneMessengerMaxMessageLength * 3;
  return result.length <= limit
      ? result
      : '${result.substring(0, limit - 1).trimRight()}…';
}
