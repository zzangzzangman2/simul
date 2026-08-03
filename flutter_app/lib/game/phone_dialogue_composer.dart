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
  if (hasAny(const ['힘들', '불안', '무서', '속상', '괜찮아', '위로'])) {
    return PhonePlayerIntent.emotionalSupport;
  }
  if (hasAny(const ['회복했', '만회했'])) {
    return PhonePlayerIntent.gainShare;
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
  final followUp =
      voice.followUps[_pick('$key:follow', voice.followUps.length)];
  final repeated =
      context.progress.lastIntent == intent.name &&
      context.progress.sameIntentStreak >= 2;
  final claimConflict = _isInvestmentIntent(intent)
      ? _claimConflictLine(context.investment, intent, voice, playerText)
      : null;

  final components = <String>[];
  if (intent == PhonePlayerIntent.boundary) {
    components.add(context.contact.boundaryReply);
  } else if (repeated) {
    components.add(voice.repetitionLine);
  } else {
    final memory = _latestPastMemory(context);
    String? memoryLine;
    if (memory != null && _pick('$key:memory', 2) == 0) {
      final quote = _shortQuote(memory.playerText);
      memoryLine = voice
          .recallTemplates[_pick('$key:recall', voice.recallTemplates.length)]
          .replaceAll('{memory}', quote);
    }
    if (_isInvestmentIntent(intent)) {
      if (claimConflict != null) {
        components.add(claimConflict);
      } else {
        final intentLines =
            voice.investmentIntentLines[_investmentIntentIndex(intent)];
        final intentLine =
            intentLines[_pick('$key:intent-line', intentLines.length)];
        if (memoryLine != null) components.add(memoryLine);
        components
          ..add(voice.investmentLines[situation.index])
          ..add(intentLine);
        if (memoryLine == null && !intentLine.trimRight().endsWith('?')) {
          components.add(followUp);
        }
      }
    } else if (_isSocialIntent(intent)) {
      final investmentEmotion =
          intent == PhonePlayerIntent.emotionalSupport &&
          _mentionsInvestment(playerText) &&
          situation != PhoneInvestmentSituation.unavailable;
      components
        ..add(
          investmentEmotion
              ? voice.investmentLines[situation.index]
              : memoryLine ?? relationshipLine,
        )
        ..add(voice.socialLines[_socialIntentIndex(intent)])
        ..add(_socialFollowUps[intent]![_pick('$key:social-follow', 3)]);
    } else if (intent == PhonePlayerIntent.classHelp) {
      final anchor = memoryLine ?? relationshipLine;
      if (_sentenceCount(anchor) + _sentenceCount(context.contact.classReply) <=
          4) {
        components.add(anchor);
      }
      components.add(context.contact.classReply);
    } else if (intent == PhonePlayerIntent.casual) {
      final anchor = memoryLine ?? relationshipLine;
      if (_sentenceCount(anchor) +
              _sentenceCount(context.contact.casualReply) <=
          4) {
        components.add(anchor);
      }
      components.add(context.contact.casualReply);
    } else {
      components.add(context.contact.fallbackReply);
    }
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
  } else if (claimConflict != null) {
    affectionDelta = 0;
    trustDelta = -1;
    closenessDelta = 0;
    investmentRespectDelta = -1;
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
    required this.investmentIntentLines,
    required this.socialLines,
    required this.followUps,
    required this.recallTemplates,
    required this.repetitionLine,
    required this.gainClaimConflict,
    required this.lossClaimConflict,
    required this.dailyGainClaimConflict,
    required this.dailyLossClaimConflict,
  });

  final List<String> relationshipLines;
  final List<String> investmentLines;
  final List<List<String>> investmentIntentLines;
  final List<String> socialLines;
  final List<String> followUps;
  final List<String> recallTemplates;
  final String repetitionLine;
  final String gainClaimConflict;
  final String lossClaimConflict;
  final String dailyGainClaimConflict;
  final String dailyLossClaimConflict;
}

const _voices = <String, _VoicePack>{
  'kim_hakjun': _VoicePack(
    relationshipLines: [
      '확인했어.',
      '그래, 알겠어.',
      '네 말은 이해했어.',
      '끝까지 읽었어.',
      '중요한 얘기인 건 알겠어.',
      '네 말이면 가볍게 넘기진 않아.',
    ],
    investmentLines: [
      '아직 오늘 계산 안 끝났어. 끝나고 보자.',
      '오늘 장 쉬잖아. 지난 기록이나 보자.',
      '오늘은 거의 그대로네. 괜히 의미 붙이지 말자.',
      '오늘도 벌었고 전체도 플러스네. 수수료 뺀 것도 맞지?',
      '오늘은 벌었네. 그래도 아직 전체는 마이너스야.',
      '오늘 좀 잃어도 지금까지 번 돈은 남아 있어. 어디까지 버틸지만 정해.',
      '오늘도 잃었고 전체도 마이너스야. 일단 돈부터 지켜.',
    ],
    investmentIntentLines: [
      ['잃은 돈부터 정확히 적어. 그래야 다음 계산이 돼.', '이번 손해랑 네가 잘못 본 건 따로 보자.'],
      ['번 건 좋지. 수수료 빼고도 남았는지만 봐.', '이번에 왜 벌었는지 적어 둬. 운인지 아닌지는 다음에 보자.'],
      ['남 말만 듣고 사지는 마. 네가 감당할 돈부터 정해.', '사기 전에 얼마까지 잃을 수 있는지 먼저 정해.'],
      ['처음 계산이랑 지금 숫자부터 맞춰 보자.', '어디서 계산이 달라졌는지 한 줄씩 보자.'],
    ],
    socialLines: [
      '다음 계산에서 같은 실수만 안 하면 돼.',
      '도움 됐으면 됐어.',
      '뭐가 불안한지 하나씩 말해 봐.',
      '좋아. 일정부터 맞춰 보자.',
    ],
    followUps: ['정확히 얼마야?', '처음 산 가격은 얼마였어?', '그래서 다음에는 뭐 할 건데?'],
    recallTemplates: [
      '장부에 “{memory}”라고 적혀 있어.',
      '전에 “{memory}”라고 했던 건 기억해.',
      '지난번 기준은 “{memory}”였지.',
    ],
    repetitionLine: '같은 질문은 숫자가 달라졌을 때 다시 보자.',
    gainClaimConflict: '지금까지는 손실이야. 어떤 돈을 번 건지 숫자부터 맞춰.',
    lossClaimConflict: '지금까지는 수익이야. 다른 데서 잃은 거면 그걸 말해 줘.',
    dailyGainClaimConflict: '오늘은 손해인데 벌었다고? 오늘 숫자 다시 봐.',
    dailyLossClaimConflict: '오늘은 벌었는데 잃었다고? 전체 얘기면 그렇게 말해.',
  ),
  'kim_seoa': _VoicePack(
    relationshipLines: [
      '응, 읽었어.',
      '네 얘기는 적어 둘게.',
      '무슨 뜻인지 알겠어.',
      '끝까지 읽었어.',
      '네가 먼저 말해 줘서 고마워.',
      '우리가 쌓은 기록이 있으니까 믿을게.',
    ],
    investmentLines: [
      '아직 오늘 결과도 안 나왔는데 미리 정하긴 이른 것 같아.',
      '오늘은 장 쉬니까 전에 적어 둔 거나 같이 볼까?',
      '오늘은 거의 그대로네.',
      '오늘도 벌었고 지금까지도 플러스라 다행이야.',
      '오늘은 벌었지만 아직 본전 아래네. 그래도 조금 돌아왔어.',
      '오늘은 잃었지만 지금까지 번 돈은 남아 있어.',
      '오늘도 잃었고 아직 본전 아래라 속상하겠다.',
    ],
    investmentIntentLines: [
      ['전에 정한 선보다 더 잃은 건 아닌지 먼저 볼까?', '오늘 잃은 이유랑 그때 뭘 믿었는지 같이 적어 두자.'],
      [
        '번 건 다행이야. 그 회사가 전에 한 약속도 지켰는지 보자.',
        '오늘 잘된 건 적어 두자. 다음에도 같은 이유인지 볼 수 있게.',
      ],
      ['전에 한 말이랑 계속 맞는 회사인지부터 보면 좋겠어.', '사람들이 한 번만 산 건지 계속 찾는지도 확인해 보자.'],
      ['그때 적어 둔 이유랑 지금 이유가 같은지 볼까?', '오늘 숫자만 말고 전에 한 약속도 같이 보자.'],
    ],
    socialLines: [
      '사과해 줘서 고마워.',
      '나도 네게 도움이 됐다니 기뻐.',
      '혼자 참지 말고 지금 마음부터 말해 줘.',
      '서로 무리하지 않는 계획이면 좋아.',
    ],
    followUps: ['오늘 느낀 것도 같이 적어 둘까?', '내일 확인할 약속 하나 정할래?', '밥은 먹었는지도 말해 줘.'],
    recallTemplates: [
      '내 기록에는 “{memory}”라고 남아 있어.',
      '전에 네가 “{memory}”라고 말한 것도 기억해.',
      '지난번 네 말은 “{memory}”였지.',
    ],
    repetitionLine: '같은 마음이 계속 드는 것 같아. 오늘은 이유를 하나만 더 적어 보자.',
    gainClaimConflict: '지금까지는 손실이야. 어떤 돈을 번 건지 같이 볼까?',
    lossClaimConflict: '지금까지는 수익이야. 다른 데서 잃은 거면 그 부분을 알려 줘.',
    dailyGainClaimConflict: '오늘은 손해로 적혀 있어. 혹시 지금까지 번 돈을 말한 걸까?',
    dailyLossClaimConflict: '오늘은 벌었어. 아직 본전 아래라는 뜻이면 알겠어.',
  ),
  'lee_jian': _VoicePack(
    relationshipLines: [
      '읽었어.',
      '그래, 알겠어.',
      '네 말은 확인했어.',
      '끝까지 읽었어.',
      '굳이 숨길 필요 없잖아.',
      '네 판단 과정은 믿어.',
    ],
    investmentLines: [
      '결과 안 나왔어. 지금 말하면 그냥 추측이야.',
      '오늘 장 안 열리잖아. 컴퓨터 끄고 생각이나 정리해.',
      '움직임 거의 없어. 억지로 의미 붙이지 마.',
      '오늘도 벌었고 지금까지도 플러스네. 잘됐어.',
      '오늘 번 건 본전으로 돌아가는 중인 거야. 아직 남았어.',
      '오늘은 빠졌어도 지금까지 번 건 남았어.',
      '오늘도 잃었고 아직 본전 아래네. 산 돈부터 줄여.',
    ],
    investmentIntentLines: [
      [
        '뭐가 안 됐는지 직접 확인해. 그냥 운 없었다고 넘기진 말고.',
        '잃은 돈보다 원인부터 봐. 제품이 문제인지 가격이 문제인지.',
      ],
      ['벌긴 했네. 제품이 진짜 좋아진 건지도 봤어?', '이번엔 됐어. 같은 방식으로 한 번 더 되는지가 중요해.'],
      ['광고 말고 물건부터 봐. 직접 써 볼 수 있으면 더 좋고.', '좋은 물건이랑 싼 주식은 다른 얘기야. 둘 다 확인해.'],
      ['처음에 뭘 보고 샀는지 다시 보여 줘.', '직접 본 사실이랑 네 추측을 나눠 봐.'],
    ],
    socialLines: [
      '알았어. 다음에 같은 일만 없으면 돼.',
      '도움 됐다면 됐어.',
      '뭐가 불안한 건데? 해결할 일이면 같이 보자.',
      '좋아. 복잡하게만 안 하면 돼.',
    ],
    followUps: ['직접 확인한 건 뭐야?', '내일 뭘 볼 건데?', '한 번 더 해도 같은 결과가 나와?'],
    recallTemplates: [
      '전에 “{memory}”라고 했던 건 기억나.',
      '전에 확인한 네 말은 “{memory}”였지.',
      '지난번 네 말은 “{memory}”였어.',
    ],
    repetitionLine: '같은 말 해도 숫자는 안 바뀌어. 다른 근거 있어?',
    gainClaimConflict: '지금까지는 손실이야. 무슨 수익인지 확인할 걸 보여 줘.',
    lossClaimConflict: '지금까지는 수익이야. 다른 손실이면 어디서 난 건지 보여 줘.',
    dailyGainClaimConflict: '오늘은 손해야. 번 건 다른 날 얘기야?',
    dailyLossClaimConflict: '오늘은 벌었어. 전체 손실을 말한 거면 그렇게 말해.',
  ),
  'choi_iseo': _VoicePack(
    relationshipLines: [
      '응, 읽었어.',
      '네 말의 느낌은 알겠어.',
      '솔직하게 말해 줘서 고마워.',
      '천천히 읽어 봤어.',
      '그 마음을 가볍게 넘기고 싶지 않아.',
      '네가 느낀 결을 이제는 알아.',
    ],
    investmentLines: [
      '아직 결과도 안 나왔는데 마음부터 달리진 말자.',
      '오늘은 장 쉬잖아. 숫자도 잠깐 내려놓자.',
      '오늘은 조용했네. 이런 날도 있는 거지.',
      '오늘도 벌었고 지금까지도 플러스네. 잘됐다.',
      '오늘은 올랐지만 아직 본전 아래야. 그래도 조금 나아졌네.',
      '오늘은 내려도 지금까지 번 건 남아 있네.',
      '오늘도 잃었고 아직 본전 아래네. 혼자 버티진 마.',
    ],
    investmentIntentLines: [
      ['네가 좋아한 거랑 사람들이 계속 사는 건 다를 수 있어.', '속상하겠지만, 쓰는 사람들은 진짜 편했는지 다시 보자.'],
      ['잘됐다. 그래도 네 취향만 맞은 건 아닌지 한 번 볼래?', '번 건 기쁜데, 사람들이 계속 쓰고 싶어 하는지도 궁금해.'],
      [
        '네가 직접 써 보고 좋은지부터 봐. 남들이 예쁘다고 하는 건 나중이고.',
        '한 번 사고 마는 물건인지 자꾸 찾는 물건인지 보면 어때?',
      ],
      ['그때 마음에 들었던 이유랑 돈이 될 거라 본 이유는 같았어?', '사람들이 실제로 쓰는 모습까지 봤는지 생각해 보자.'],
    ],
    socialLines: [
      '미안하다고 말해 준 마음은 알겠어.',
      '내가 한 일이 도움이 됐다니 다행이야.',
      '지금 느끼는 걸 억지로 숨기지 않아도 돼.',
      '우리 둘 다 편한 계획이면 좋겠어.',
    ],
    followUps: ['그 회사 물건, 써 본 사람은 뭐래?', '너는 그 물건 마음에 들었어?', '오늘은 얼마까지 괜찮아?'],
    recallTemplates: [
      '전에 “{memory}”라고 말했던 거 기억나.',
      '내가 기억하는 네 말은 “{memory}”야.',
      '지난번에는 “{memory}”라고 했었지.',
    ],
    repetitionLine: '같은 얘기가 자꾸 돌아오네. 네 마음은 그대로야?',
    gainClaimConflict: '지금까지는 본전 아래야. 네가 말한 수익은 어디에서 난 걸까?',
    lossClaimConflict: '지금까지는 수익이야. 마음에 걸린 다른 손실이 있어?',
    dailyGainClaimConflict: '오늘은 내려갔어. 지금까지 번 돈을 말한 걸까?',
    dailyLossClaimConflict: '오늘은 올랐어. 아직 본전 아래라는 뜻이야?',
  ),
  'jung_arin': _VoicePack(
    relationshipLines: [
      '확인했어.',
      '좋아, 이해했어.',
      '네 의견도 알겠어.',
      '끝까지 읽고 정리했어.',
      '중요한 얘기인 건 알겠어.',
      '네가 말한 거면 일단 믿을게.',
    ],
    investmentLines: [
      '아직 마감 전이야. 결과 나온 다음에 얘기하자.',
      '오늘 장 쉬잖아. 다음 주 계획이나 정하자.',
      '오늘은 거의 그대로네. 계획에서 벗어난 것만 봐.',
      '오늘도 벌었고 지금까지도 플러스야. 욕심낼 선부터 정해.',
      '오늘은 벌었지만 아직 본전 아래야.',
      '오늘은 잃었어도 지금까지 번 돈은 남아 있어. 그만둘 선 다시 봐.',
      '오늘도 잃었고 아직 본전 아래야. 얼마까지 줄일지 바로 정해.',
    ],
    investmentIntentLines: [
      ['손해 봤으면 다음엔 얼마만 살지 지금 정해.', '틀린 건 바로 고치면 돼. 내일 할 일부터 하나 정하자.'],
      ['벌었으면 됐어. 이제 어디서 멈출지만 정해.', '잘됐네. 다음에도 볼 숫자랑 날짜를 바로 적자.'],
      ['뭘 살지보다 언제 사고 언제 그만둘지부터 정해.', '말만 좋은 회사 말고 약속한 걸 제때 했는지 봐.'],
      ['처음 계획에서 뭐가 달라졌는지 바로 찾아.', '잘한 거 하나, 틀린 거 하나만 적고 다음 행동 정하자.'],
    ],
    socialLines: [
      '사과는 받았어.',
      '도움이 됐다면 됐어.',
      '뭐가 제일 불안해? 내가 할 수 있는 건 맡을게.',
      '좋아. 몇 시에 할지만 정하자.',
    ],
    followUps: ['그래서 내일 몇 시에 뭘 볼 건데?', '목표 숫자 하나만 정해.', '언제 다시 확인할지도 정하자.'],
    recallTemplates: [
      '전에 네가 “{memory}”라고 했잖아.',
      '전에 말한 건 “{memory}”였지.',
      '내가 적어 둔 건 “{memory}”야.',
    ],
    repetitionLine: '같은 얘기만 해서는 안 바뀌어. 달라진 게 뭐야?',
    gainClaimConflict: '지금까지는 손실이야. 어디서 수익이라고 본 건지 다시 확인해.',
    lossClaimConflict: '지금까지는 수익이야. 다른 데서 잃은 거라면 그걸 따로 말해.',
    dailyGainClaimConflict: '오늘은 손해야. 오늘 번 돈을 말한 거면 숫자 다시 봐.',
    dailyLossClaimConflict: '오늘은 수익이야. 전체 손실이랑 나눠서 말해.',
  ),
  'park_haeun': _VoicePack(
    relationshipLines: [
      '응, 읽었어.',
      '무슨 말인지 알겠어.',
      '끝까지 들어 볼게.',
      '나한테는 편하게 말해도 돼.',
      '네가 먼저 말해 줘서 고마워.',
      '네 얘기라면 언제든 들어 줄게.',
    ],
    investmentLines: [
      '아직 결과도 안 나왔잖아. 미리 네 탓부터 하지 마.',
      '오늘은 장도 쉬는데 우리도 좀 쉬자.',
      '오늘은 그대로네. 무리 안 한 것도 잘한 거야.',
      '오늘도 벌었고 지금까지도 플러스라 기쁘겠다. 그래도 무리하진 마.',
      '오늘 번 건 잘됐지만 아직 본전 아래네. 조급해하지 마.',
      '오늘 잃어도 지금까지 번 돈은 남아 있어.',
      '오늘도 잃었고 아직 본전 아래라 속상하겠다. 잠깐 쉬자.',
    ],
    investmentIntentLines: [
      ['속상한 건 알겠어. 지금 같이 볼까, 잠깐 쉬고 볼까?', '잃었다고 혼자 정리하지 마. 네가 원하는 도움부터 말해 줘.'],
      ['기쁘겠다. 그래도 그 회사 사람들도 오래 버티는지는 보자.', '잘됐네. 너도 무리한 건 없는지 먼저 확인해.'],
      [
        '대표가 좋은 말 하는 것보다 사람들이 계속 남는 회사인지 봐.',
        '고객이 문제 생겼을 때 어떻게 대해 주는지도 보면 좋겠어.',
      ],
      ['숫자 말고 그 회사 때문에 힘들어진 사람은 없었는지도 보자.', '그때 네가 누구 말을 믿었는지도 같이 떠올려 보자.'],
    ],
    socialLines: [
      '사과해 줘서 고마워.',
      '도움이 됐다니 나도 기뻐.',
      '오늘은 괜찮은 척 안 해도 돼. 그냥 들어 줄까?',
      '천천히 같이 정해 보자.',
    ],
    followUps: [
      '지금 내가 어떻게 도와주면 좋겠어?',
      '오늘은 잠깐 같이 걸을까?',
      '혼자 결정하지 말고 한 번 더 말해 줘.',
    ],
    recallTemplates: [
      '전에 “{memory}”라고 말했던 거 기억해.',
      '나는 네가 “{memory}”라고 한 걸 기억하고 있어.',
      '지난번에는 “{memory}”라고 말했었지.',
    ],
    repetitionLine: '같은 걱정이 계속 돌아오네. 답보다 먼저 네 상태를 보자.',
    gainClaimConflict: '지금까지는 손실이야. 다른 데서 번 돈을 말하는 걸까?',
    lossClaimConflict: '지금까지는 수익이야. 그래도 잃었다고 느낀 이유가 있어?',
    dailyGainClaimConflict: '오늘은 손해로 나와. 지금까지 번 돈 얘기일까?',
    dailyLossClaimConflict: '오늘은 벌었어. 아직 본전 아래라 속상하다는 뜻이야?',
  ),
  'han_sua': _VoicePack(
    relationshipLines: [
      '어, 읽었어!',
      '좋아, 무슨 말인지 알겠어.',
      '잠깐, 이건 좀 더 들어 보고 싶어.',
      '네 얘기라면 끝까지 듣지!',
      '나한테 먼저 말한 거지?',
      '너한테 온 톡이면 바로 보게 돼.',
    ],
    investmentLines: [
      '아직 결과도 안 나왔는데 벌써 결론 내리면 재미없지!',
      '휴장일이면 밖에 나가서 아이디어 찾자.',
      '오늘은 조용했네. 내일 튈 수도 있잖아.',
      '오늘도 벌었고 지금까지도 플러스야! 그래도 다 걸지는 마.',
      '오늘 벌긴 했는데 전체는 아직 마이너스네. 반등 첫 장면인가?',
      '오늘은 빠졌어도 지금까지 번 건 남았네. 그다음은?',
      '오늘도 잃었고 아직 본전 아래야. 무작정 더 세게 가면 안 돼.',
    ],
    investmentIntentLines: [
      [
        '속상하지. 근데 왜 사람들이 갑자기 안 사기 시작했는지 궁금하지 않아?',
        '이번엔 틀렸네. 그럼 완전 다른 이유가 있었던 걸까?',
      ],
      ['오, 벌었네! 근데 사람들이 진짜 다시 사는지도 봤어?', '잘됐다! 잠깐, 우리 또 신나서 앞서가는 건 아니지?'],
      ['사람들이 요즘 뭘 자꾸 얘기하는지부터 찾아보자!', '직접 써 본 사람 만나서 물어보면 어때?'],
      ['처음에 뭐가 재밌어 보여서 샀는지 다시 생각해 보자.', '사람들 반응이 바뀐 순간이 있었는지 떠올려 봐!'],
    ],
    socialLines: [
      '미안하다고 했으니까 이번엔 믿어 볼게!',
      '나도 같이해서 좋았어!',
      '혼자 끙끙대지 말고 다 말해 봐.',
      '좋아! 재미있는 쪽으로 가 보자.',
    ],
    followUps: ['그다음엔 뭘 시험해 볼까?', '주말에 같이 확인하러 갈래?', '근데 실제로 다시 사는 사람도 늘었대?'],
    recallTemplates: [
      '전에 네가 “{memory}”라고 먼저 말했잖아.',
      '나도 네가 “{memory}”라고 했던 거 기억나!',
      '지난번 우리 얘기는 “{memory}”에서 시작했지.',
    ],
    repetitionLine: '또 같은 주제야? 이번엔 완전히 다른 가설로 가 보자!',
    gainClaimConflict: '잠깐, 지금까지는 마이너스인데 수익이라고? 어느 숫자 본 거야?',
    lossClaimConflict: '잠깐, 지금까지는 플러스인데 손실이라고? 다른 데서 잃었어?',
    dailyGainClaimConflict: '잠깐, 오늘은 손해인데? 지금까지 번 돈 말한 거야?',
    dailyLossClaimConflict: '잠깐, 오늘은 벌었는데? 아직 본전 아래라는 얘기야?',
  ),
  'oh_jiwoo': _VoicePack(
    relationshipLines: [
      '오, 읽어 봤어.',
      '좋아, 이해했어.',
      '네 생각도 알겠어.',
      '이번에는 반박하지 않고 읽었어.',
      '우리끼린 숨길 필요 없잖아.',
      '네 말이면 끝까지 읽게 돼.',
    ],
    investmentLines: [
      '아직 결과도 없는데 확신부터 하면 너무 빠르지.',
      '오늘 장 쉬잖아. 그럼 반대로 틀릴 이유나 찾아보자.',
      '오늘은 거의 그대로네. 시장이 대답을 미룬 셈이지.',
      '오늘도 벌었고 지금까지도 플러스네. 자, 반대면 어떻게 되는지도 보자.',
      '오늘은 벌었는데 아직 본전 아래네. 반등인지 잠깐 튄 건지 보자.',
      '오늘은 잃었지만 지금까지 번 건 남아 있네. 그냥 흔들린 건지 봐야지.',
      '오늘도 잃었고 아직 본전 아래네. 네 생각이 틀렸을 가능성부터 보자.',
    ],
    investmentIntentLines: [
      ['틀렸다고 치자. 그럼 제일 먼저 버릴 생각은 뭐야?', '손해 난 이유가 네 설명이랑 완전히 다른 거면?'],
      ['벌었다고 네 생각이 맞은 건가? 운이면?', '잘됐네. 그럼 반대로 언제부터 틀린 얘기가 돼?'],
      ['내가 반대해도 살 이유가 있으면 그때 생각해 봐.', '다들 같은 이유로 사는 거면, 그 이유가 틀릴 때는?'],
      ['네 설명이 틀렸다고 가정하면 뭐가 보여?', '결과 빼고도 같은 선택을 했을지 말해 봐.'],
    ],
    socialLines: [
      '사과는 접수.',
      '도움이 됐다니 오늘 토론은 무승부로 해 줄게.',
      '잠깐, 지금은 토론할 때 아니네. 그냥 들어 줄까?',
      '좋아. 안 되면 뭘 할지도 하나 정해 두자.',
    ],
    followUps: [
      '반대 입장에서 한 번 말해 볼래?',
      '네 생각이 틀렸다고 인정할 때는 언제야?',
      '내가 반박해도 끝까지 지킬 이유가 있어?',
    ],
    recallTemplates: [
      '지난번에는 “{memory}”라고 했지.',
      '내가 기억하는 건 “{memory}”야.',
      '전에 “{memory}”라고 말한 데서 이야기가 시작됐지.',
    ],
    repetitionLine: '같은 주장만 반복하면 토론이 아니지. 반대 증거는 없어?',
    gainClaimConflict: '속보 정정. 지금까지는 손실이야. 수익이라고 본 이유가 뭐야?',
    lossClaimConflict: '속보 정정. 지금까지는 수익이야. 다른 데서 잃은 거야?',
    dailyGainClaimConflict: '속보 정정. 오늘은 손해. 지금까지 번 돈 얘기였어?',
    dailyLossClaimConflict: '속보 정정. 오늘은 수익. 전체가 아직 마이너스라는 얘기야?',
  ),
  'yoon_chaea': _VoicePack(
    relationshipLines: [
      '읽었어.',
      '무슨 뜻인지 알겠어.',
      '네가 왜 그렇게 말했는지도 알겠어.',
      '끝까지 읽고 생각해 봤어.',
      '네 선택도 이제는 나한테 중요해.',
      '말하지 않은 부분도 조금은 알 것 같아.',
    ],
    investmentLines: [
      '오늘 결과 아직 안 나왔어. 지금은 판단 못 해.',
      '오늘 장 쉬잖아. 그래도 지난 기록은 볼 수 있어.',
      '오늘은 거의 그대로야. 하루보다 한 달 흐름을 보자.',
      '오늘도 벌었고 지금까지도 플러스야. 잘됐다고 이유를 끼워 맞추진 마.',
      '오늘은 벌었지만 아직 본전 아래야. 흐름이 바뀌었다고 보긴 일러.',
      '오늘은 잃었지만 지금까지 번 돈은 남아 있어. 이 정도는 생각했던 건지 봐.',
      '오늘도 잃었고 아직 본전 아래야. 처음 생각과 산 금액을 둘 다 다시 봐.',
    ],
    investmentIntentLines: [
      ['손해 난 이유보다 처음 생각이 아직 맞는지부터 봐.', '지금 숫자 때문에 처음 기준을 슬쩍 바꾸고 있진 않아?'],
      ['벌었어도 처음 생각이 맞았다는 뜻은 아니야.', '잘된 결과에 맞춰 이유를 새로 만들진 마.'],
      ['오늘 가격 말고 왜 달라질 회사인지부터 생각해.', '한 달 뒤에도 같은 이유로 들고 있을 수 있는 걸 골라.'],
      ['처음 생각에서 바뀐 게 뭔지 하나만 찾아.', '그때 몰랐던 사실이 지금 생긴 건지부터 보자.'],
    ],
    socialLines: [
      '왜 그랬는지는 알겠어.',
      '도움이 됐다면 그걸로 충분해.',
      '뭐가 불안한지 나눠 보면 우리가 바꿀 수 있는 게 보여.',
      '좋아. 그다음에 뭘 할지도 같이 생각해 보자.',
    ],
    followUps: [
      '그렇게 생각한 이유가 뭐야?',
      '한 달 뒤에도 같은 선택 할까?',
      '상황 하나 달라져도 같은 선택 할 거야?',
    ],
    recallTemplates: [
      '전에 “{memory}”라고 했지.',
      '지난번 얘기는 “{memory}”에서 시작했어.',
      '내가 계속 생각해 본 건 “{memory}”이야.',
    ],
    repetitionLine: '같은 얘기만으로는 답도 같아. 달라진 게 있어?',
    gainClaimConflict: '지금까지는 손실이야. 어디서 수익이라고 본 건지 다시 확인해.',
    lossClaimConflict: '지금까지는 수익이야. 다른 손실을 말하는 거면 어디까지 계산한 건지 알려 줘.',
    dailyGainClaimConflict: '오늘은 손해야. 지금까지 번 돈을 말한 거라면 나눠서 봐.',
    dailyLossClaimConflict: '오늘은 수익이야. 전체가 아직 손실이라는 뜻이면 그렇게 말해.',
  ),
};

const _socialFollowUps = <PhonePlayerIntent, List<String>>{
  PhonePlayerIntent.apology: [
    '이제 어떤 부분을 바꿀지 말해 줄래?',
    '왜 그랬는지도 솔직하게 말해 줘.',
    '다음에는 먼저 이야기해 줘.',
  ],
  PhonePlayerIntent.gratitude: [
    '너도 필요할 때 꼭 말해 줘.',
    '다음에는 내가 부탁할 수도 있어.',
    '다음에도 같이 해 보자.',
  ],
  PhonePlayerIntent.emotionalSupport: [
    '지금은 무엇이 제일 힘들어?',
    '그냥 들어 주는 게 좋을까?',
    '같이 하나씩 정리해 볼까?',
  ],
  PhonePlayerIntent.planning: [
    '언제 어디서 볼까?',
    '서로 준비할 걸 정하자.',
    '무리 없는 시간부터 잡아 보자.',
  ],
};

bool _isInvestmentIntent(PhonePlayerIntent intent) =>
    intent == PhonePlayerIntent.lossShare ||
    intent == PhonePlayerIntent.gainShare ||
    intent == PhonePlayerIntent.investmentAdvice ||
    intent == PhonePlayerIntent.investmentReflection;

int _investmentIntentIndex(PhonePlayerIntent intent) => switch (intent) {
  PhonePlayerIntent.lossShare => 0,
  PhonePlayerIntent.gainShare => 1,
  PhonePlayerIntent.investmentAdvice => 2,
  PhonePlayerIntent.investmentReflection => 3,
  _ => 0,
};

bool _isSocialIntent(PhonePlayerIntent intent) =>
    intent == PhonePlayerIntent.apology ||
    intent == PhonePlayerIntent.gratitude ||
    intent == PhonePlayerIntent.emotionalSupport ||
    intent == PhonePlayerIntent.planning;

int _socialIntentIndex(PhonePlayerIntent intent) => switch (intent) {
  PhonePlayerIntent.apology => 0,
  PhonePlayerIntent.gratitude => 1,
  PhonePlayerIntent.emotionalSupport => 2,
  PhonePlayerIntent.planning => 3,
  _ => 0,
};

bool _mentionsInvestment(String rawText) {
  final text = rawText.toLowerCase().replaceAll(' ', '');
  return const [
    '주식',
    '투자',
    '종목',
    '손실',
    '손해',
    '수익',
    '매수',
    '매도',
    '마이너스',
    '플러스',
  ].any(text.contains);
}

String? _claimConflictLine(
  PhoneInvestmentConversationContext investment,
  PhonePlayerIntent intent,
  _VoicePack voice,
  String playerText,
) {
  if (!investment.hasCurrentReport) return null;
  final compactText = playerText.toLowerCase().replaceAll(' ', '');
  final mentionsDaily = const ['오늘', '이번'].any(compactText.contains);
  final mentionsCumulative = const [
    '전체',
    '지금까지',
    '총금액',
    '누적',
    '본전',
  ].any(compactText.contains);
  if (mentionsDaily) {
    if (intent == PhonePlayerIntent.gainShare &&
        investment.playerDailyProfitLoss < 0) {
      return voice.dailyGainClaimConflict;
    }
    if (intent == PhonePlayerIntent.lossShare &&
        investment.playerDailyProfitLoss > 0) {
      return voice.dailyLossClaimConflict;
    }
  }
  if (mentionsCumulative) {
    if (intent == PhonePlayerIntent.gainShare &&
        investment.playerCumulativeProfitLoss < 0) {
      return voice.gainClaimConflict;
    }
    if (intent == PhonePlayerIntent.lossShare &&
        investment.playerCumulativeProfitLoss > 0) {
      return voice.lossClaimConflict;
    }
  }
  if (intent == PhonePlayerIntent.gainShare &&
      investment.playerDailyProfitLoss < 0 &&
      investment.playerCumulativeProfitLoss <= 0) {
    return voice.gainClaimConflict;
  }
  if (intent == PhonePlayerIntent.lossShare &&
      investment.playerDailyProfitLoss > 0 &&
      investment.playerCumulativeProfitLoss >= 0) {
    return voice.lossClaimConflict;
  }
  return null;
}

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

int _sentenceCount(String value) {
  final count = RegExp(r'[.!?](?:\s|$)').allMatches(value.trim()).length;
  return count == 0 && value.trim().isNotEmpty ? 1 : count;
}

String _fitReply(List<String> components) {
  final limit = phoneMessengerMaxMessageLength * 3;
  final kept = <String>[];
  var sentences = 0;
  for (final component in components) {
    final part = component.trim();
    if (part.isEmpty) continue;
    final candidate = [...kept, part].join(' ');
    final partSentences = _sentenceCount(part);
    if (candidate.length <= limit && sentences + partSentences <= 4) {
      kept.add(part);
      sentences += partSentences;
    }
  }
  return kept.join(' ');
}
