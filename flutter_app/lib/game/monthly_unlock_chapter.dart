import 'game_state.dart';
import 'phone_messenger_state.dart';
import 'relationship_state.dart';
import 'weekday_activity.dart';

const monthlyUnlockDecisionPrefix = 'monthly-unlock-';
const monthlyUnlockCompletedFlagPrefix = 'monthlyUnlockCompleted_';
const businessMarketAccessUnlockedFlag = 'businessMarketAccessUnlocked';
const businessOperationsUnlockedFlag = 'businessOperationsUnlocked';
const realEstateTransactionsUnlockedFlag = 'realEstateTransactionsUnlocked';
const realEstateOperationsUnlockedFlag = 'realEstateOperationsUnlocked';
const propertyBusinessLinkUnlockedFlag = 'propertyBusinessLinkUnlocked';
const advancedCorporateActionsUnlockedFlag = 'advancedCorporateActionsUnlocked';

enum MonthlyHeroineTone { fractured, strained, awkward, friendly, close }

extension MonthlyHeroineTonePresentation on MonthlyHeroineTone {
  String get label => switch (this) {
    MonthlyHeroineTone.fractured => '갈등이 남은 사이',
    MonthlyHeroineTone.strained => '조금 냉랭한 사이',
    MonthlyHeroineTone.awkward => '아직 서먹한 동기',
    MonthlyHeroineTone.friendly => '편하게 말하는 친구',
    MonthlyHeroineTone.close => '서로 마음을 아는 친구',
  };
}

class MonthlyToneDialogue {
  const MonthlyToneDialogue({
    required this.stageDirection,
    required this.firstLine,
    required this.secondLine,
    required this.followUpLead,
  });

  final String stageDirection;
  final String firstLine;
  final String secondLine;
  final String followUpLead;
}

class MonthlyUnlockOptionDefinition {
  const MonthlyUnlockOptionDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.heroineReply,
    this.affectionDelta = 0,
    this.trustDelta = 0,
    this.closenessDelta = 0,
    this.investmentRespectDelta = 0,
  });

  final String id;
  final String label;
  final String description;
  final String heroineReply;
  final int affectionDelta;
  final int trustDelta;
  final int closenessDelta;
  final int investmentRespectDelta;
}

class MonthlyUnlockChapterDefinition {
  const MonthlyUnlockChapterDefinition({
    required this.id,
    required this.year,
    required this.month,
    required this.heroineId,
    required this.title,
    required this.location,
    required this.situation,
    required this.featureLabel,
    required this.npcLine,
    required this.unlockFlags,
    required this.dialogueByTone,
    required this.options,
  });

  final String id;
  final int year;
  final int month;
  final String heroineId;
  final String title;
  final String location;
  final String situation;
  final String featureLabel;
  final String npcLine;
  final Map<String, bool> unlockFlags;
  final Map<MonthlyHeroineTone, MonthlyToneDialogue> dialogueByTone;
  final List<MonthlyUnlockOptionDefinition> options;

  DateTime get startsOn => DateTime(year, month);
  String get decisionBaseId => '$monthlyUnlockDecisionPrefix$id';

  MonthlyToneDialogue dialogueFor(MonthlyHeroineTone tone) =>
      dialogueByTone[tone] ?? dialogueByTone[MonthlyHeroineTone.awkward]!;

  MonthlyUnlockOptionDefinition? optionById(String optionId) {
    for (final option in options) {
      if (monthlyUnlockOptionId(this, option.id) == optionId) return option;
    }
    return null;
  }
}

class _RelationshipSignal {
  const _RelationshipSignal({
    required this.day,
    required this.minute,
    required this.score,
    required this.trustDelta,
    required this.isApology,
  });

  final int day;
  final int minute;
  final int score;
  final int trustDelta;
  final bool isApology;
}

MonthlyHeroineTone monthlyHeroineToneFor(GameState state, String heroineId) {
  final progress = state.relationships.progressFor(heroineId);
  final signals =
      <_RelationshipSignal>[
        for (final memory in state.relationships.memories)
          if (memory.girlId == heroineId && memory.day <= state.day)
            _RelationshipSignal(
              day: memory.day,
              minute: 20 * 60,
              score:
                  memory.affectionDelta +
                  memory.trustDelta +
                  memory.closenessDelta,
              trustDelta: memory.trustDelta,
              isApology: memory.choiceId.toLowerCase().contains('apolog'),
            ),
        for (final memory in state.phoneMessenger.memoriesFor(heroineId))
          if (memory.day <= state.day)
            _RelationshipSignal(
              day: memory.day,
              minute: memory.marketMinute,
              score:
                  memory.affectionDelta +
                  memory.trustDelta +
                  memory.closenessDelta,
              trustDelta: memory.trustDelta,
              isApology: memory.intent == 'apology',
            ),
      ]..sort((a, b) {
        final dayOrder = a.day.compareTo(b.day);
        return dayOrder != 0 ? dayOrder : a.minute.compareTo(b.minute);
      });

  _RelationshipSignal? latestNegative;
  _RelationshipSignal? latestRepair;
  for (final signal in signals) {
    if (signal.score < 0) latestNegative = signal;
    if (signal.score > 0 && (signal.isApology || signal.trustDelta > 0)) {
      latestRepair = signal;
    }
  }
  final negativeIsRecent =
      latestNegative != null && state.day - latestNegative.day <= 14;
  final repairedAfterNegative =
      latestNegative != null &&
      latestRepair != null &&
      (latestRepair.day > latestNegative.day ||
          (latestRepair.day == latestNegative.day &&
              latestRepair.minute > latestNegative.minute));

  if (negativeIsRecent && !repairedAfterNegative) {
    if (latestNegative.score <= -4 || latestNegative.trustDelta <= -2) {
      return MonthlyHeroineTone.fractured;
    }
    return MonthlyHeroineTone.strained;
  }
  if (negativeIsRecent && repairedAfterNegative) {
    return MonthlyHeroineTone.awkward;
  }
  if (progress.trust <= 5 &&
      (progress.conversationCount > 0 || progress.meaningfulMessageCount > 0)) {
    return MonthlyHeroineTone.strained;
  }
  if (progress.affection >= 60 &&
      progress.trust >= 50 &&
      progress.closeness >= 40) {
    return MonthlyHeroineTone.close;
  }
  if (progress.affection >= 20 &&
      progress.trust >= 15 &&
      progress.closeness >= 12) {
    return MonthlyHeroineTone.friendly;
  }
  return MonthlyHeroineTone.awkward;
}

String monthlyUnlockDecisionId(
  MonthlyUnlockChapterDefinition chapter,
  MonthlyHeroineTone tone,
) => '${chapter.decisionBaseId}-tone-${tone.name}';

String monthlyUnlockOptionId(
  MonthlyUnlockChapterDefinition chapter,
  String optionId,
) => '${chapter.decisionBaseId}__$optionId';

bool isMonthlyUnlockDecisionId(String decisionId) =>
    decisionId.startsWith(monthlyUnlockDecisionPrefix);

MonthlyUnlockChapterDefinition? monthlyUnlockChapterForDecisionId(
  String decisionId,
) {
  for (final chapter in monthlyUnlockChapters) {
    if (decisionId.startsWith(chapter.decisionBaseId)) return chapter;
  }
  return null;
}

MonthlyHeroineTone monthlyUnlockToneForDecisionId(String decisionId) {
  final marker = decisionId.lastIndexOf('-tone-');
  if (marker < 0) return MonthlyHeroineTone.awkward;
  final encoded = decisionId.substring(marker + '-tone-'.length);
  return MonthlyHeroineTone.values.firstWhere(
    (tone) => tone.name == encoded,
    orElse: () => MonthlyHeroineTone.awkward,
  );
}

bool monthlyUnlockChapterCompleted(
  GameState state,
  MonthlyUnlockChapterDefinition chapter,
) =>
    state.story.flagBool('$monthlyUnlockCompletedFlagPrefix${chapter.id}') ||
    state.decisions.any(
      (decision) => decision.id.startsWith(chapter.decisionBaseId),
    );

DecisionCardData? nextMonthlyUnlockDecision(GameState state) {
  if (!facilityStoryGatesEnabled(state) || state.pendingDecisions.isNotEmpty) {
    return null;
  }
  for (final chapter in monthlyUnlockChapters) {
    if (state.currentDate.isBefore(chapter.startsOn) ||
        monthlyUnlockChapterCompleted(state, chapter)) {
      continue;
    }
    final tone = monthlyHeroineToneFor(state, chapter.heroineId);
    final dialogue = chapter.dialogueFor(tone);
    final profile = cohortGirlProfileById(chapter.heroineId);
    final heroineName = profile?.name ?? chapter.heroineId;
    return DecisionCardData(
      id: monthlyUnlockDecisionId(chapter, tone),
      category: '${chapter.month}월 해금 이야기',
      title: chapter.title,
      proposer: heroineName,
      body:
          '${dialogue.stageDirection}\n\n'
          '$heroineName: “${dialogue.firstLine}”\n\n'
          '${chapter.situation}\n\n'
          '$heroineName: “${dialogue.secondLine}”',
      createdDay: state.day,
      dueDay: state.day + 7,
      requestedFunds: 0,
      benefit: chapter.featureLabel,
      risk: '사이가 좋지 않아도 억지로 화해하지 않으며, 기능 해금은 막히지 않습니다.',
      advisorOpinions: <String>[
        chapter.npcLine,
        '$heroineName: ${dialogue.followUpLead}',
      ],
      options: <DecisionOptionData>[
        for (final option in chapter.options)
          DecisionOptionData(
            id: monthlyUnlockOptionId(chapter, option.id),
            label: option.label,
            description: option.description,
          ),
      ],
    );
  }
  return null;
}

GameState resolveMonthlyUnlockDecision(
  GameState state,
  String decisionId,
  String optionId,
) {
  final chapter = monthlyUnlockChapterForDecisionId(decisionId);
  if (chapter == null) return state;
  final option = chapter.optionById(optionId);
  if (option == null) return state;
  final tone = monthlyUnlockToneForDecisionId(decisionId);
  final dialogue = chapter.dialogueFor(tone);
  final current = state.relationships.progressFor(chapter.heroineId);
  final updated = current.copyWith(
    affection: current.affection + option.affectionDelta,
    trust: current.trust + option.trustDelta,
    closeness: current.closeness + option.closenessDelta,
    investmentRespect:
        current.investmentRespect + option.investmentRespectDelta,
    lastInteractionDay: state.day,
    conversationCount: current.conversationCount + 1,
  );
  final appliedAffection = updated.affection - current.affection;
  final appliedTrust = updated.trust - current.trust;
  final appliedCloseness = updated.closeness - current.closeness;
  final appliedRespect = updated.investmentRespect - current.investmentRespect;
  final memories = <RelationshipMemory>[
    ...state.relationships.memories,
    RelationshipMemory(
      day: state.day,
      girlId: chapter.heroineId,
      activity: RelationshipActivity.conversation,
      sceneId: chapter.decisionBaseId,
      choiceId: option.id,
      affectionDelta: appliedAffection,
      affectionAfter: updated.affection,
      trustDelta: appliedTrust,
      closenessDelta: appliedCloseness,
      investmentRespectDelta: appliedRespect,
    ),
  ];
  final flags = <String, dynamic>{
    ...state.story.storyFlags,
    ...chapter.unlockFlags,
    '$monthlyUnlockCompletedFlagPrefix${chapter.id}': true,
    'monthlyUnlockTone_${chapter.id}': tone.name,
    'monthlyUnlockChoice_${chapter.id}': option.id,
    'monthlyUnlockCompletedDay_${chapter.id}': state.day,
  };
  if (chapter.id == '2000-02-bank') {
    flags['bankAccessUnlockedDay'] = state.day;
    flags['bankIntroductionFocus'] = 'deposit';
  }
  if (chapter.id == '2000-05-real-estate-research') {
    flags['realEstateAccessUnlockedDay'] = state.day;
    flags['realtorIntroductionFocus'] = 'cashflow';
  }
  final eventId = 'MONTHLY_UNLOCK_${chapter.id.toUpperCase()}';
  final compatibilityEventIds = <String>[
    if (chapter.id == '2000-02-bank') 'BANK_CLERK_YOON_HARIN_INTRODUCED',
    if (chapter.id == '2000-05-real-estate-research')
      'REALTOR_SEO_HANEUL_INTRODUCED',
  ];
  final followUp = '${dialogue.followUpLead} ${option.heroineReply}'.trim();
  final messages = <PhoneMessage>[
    ...state.phoneMessenger.messages,
    PhoneMessage(
      id: '${chapter.decisionBaseId}-${state.day}-${option.id}',
      contactId: chapter.heroineId,
      senderId: chapter.heroineId,
      text: followUp,
      day: state.day,
      marketMinute: state.marketMinute,
      read: false,
    ),
  ];
  final boundedMessages = retainPhoneMessages(messages);

  return state.copyWith(
    story: state.story.copyWith(
      storyFlags: flags,
      seenStoryEventIds: <String>[
        ...state.story.seenStoryEventIds,
        if (!state.story.seenStoryEventIds.contains(eventId)) eventId,
        for (final id in compatibilityEventIds)
          if (!state.story.seenStoryEventIds.contains(id)) id,
      ],
    ),
    relationships: state.relationships.copyWith(
      girls: <String, GirlRelationshipProgress>{
        ...state.relationships.girls,
        chapter.heroineId: updated,
      },
      memories: memories.length <= relationshipMemoryHistoryLimit
          ? memories
          : memories.sublist(memories.length - relationshipMemoryHistoryLimit),
    ),
    phoneMessenger: state.phoneMessenger.copyWith(
      messages: List<PhoneMessage>.unmodifiable(boundedMessages),
    ),
  );
}

const monthlyUnlockChapters = <MonthlyUnlockChapterDefinition>[
  MonthlyUnlockChapterDefinition(
    id: '2000-02-bank',
    year: 2000,
    month: 2,
    heroineId: 'kim_seoa',
    title: '2월 · 돈을 묶는다는 것',
    location: '강남 아지트 · 생활 라운지',
    situation:
        '1월 결산 뒤 회사 통장에 남은 돈을 두고 이야기가 시작됐다. 윤하린 은행원은 6·12·24개월 예금과 중도해지 조건을 비교해 보자고 했다.',
    featureLabel: '새천년은행 · 정기예금 해금',
    npcLine: '윤하린: 전부 묶는 게 정답은 아니에요. 다음 달에 쓸 돈부터 남겨 두세요.',
    unlockFlags: <String, bool>{bankAccessUnlockedFlag: true},
    dialogueByTone: <MonthlyHeroineTone, MonthlyToneDialogue>{
      MonthlyHeroineTone.fractured: MonthlyToneDialogue(
        stageDirection: '서아는 장부를 탁자 끝에 내려놓고 맞은편에 앉았다.',
        firstLine: '장부는 여기 둘게. 지난 얘기는 아직 안 끝났으니까, 오늘은 필요한 것만 말하자.',
        secondLine: '그래도 만기일을 틀리게 적을 순 없어. 네가 고르면 날짜는 내가 확인할게.',
        followUpLead: '아무 일 없던 것처럼 굴진 않을게. 그래도 오늘 정한 날짜는 적어 뒀어.',
      ),
      MonthlyHeroineTone.strained: MonthlyToneDialogue(
        stageDirection: '서아는 몇 번이나 접은 장부 모서리를 펴며 먼저 입을 열었다.',
        firstLine: '같이 보긴 할 건데… 우리 사이 괜찮은 척까지 하진 말자.',
        secondLine: '돈 얘기는 정확히 하고 싶어. 그게 서로 덜 서운하니까.',
        followUpLead: '아직 조금 어색해. 그래도 네가 고른 기준은 빠뜨리지 않았어.',
      ),
      MonthlyHeroineTone.awkward: MonthlyToneDialogue(
        stageDirection: '서아는 장부를 안고 한참 서 있다가 플레이어 옆에 한 칸을 비워 앉았다.',
        firstLine: '1월에 남은 돈… 그냥 두는 건지 궁금해서. 장부 가져왔어.',
        secondLine: '같이 봐도 돼? 아직 서로 뭘 중요하게 보는지 잘 모르잖아.',
        followUpLead: '오늘 같이 본 건 따로 표시해 뒀어.',
      ),
      MonthlyHeroineTone.friendly: MonthlyToneDialogue(
        stageDirection: '서아가 장부를 펼쳐 플레이어 쪽으로 반쯤 밀었다.',
        firstLine: '야, 이거 봐. 우리 돈이 통장에 가만히 있는 날도 꽤 많아.',
        secondLine: '다 묶지는 말고, 다음 달에 쓸 돈부터 같이 남겨 보자.',
        followUpLead: '네가 말한 금액까지 옆에 적어 놨어.',
      ),
      MonthlyHeroineTone.close: MonthlyToneDialogue(
        stageDirection: '서아는 플레이어가 지난달 남겨 둔 메모 옆에 작은 분홍 표시를 해 두었다.',
        firstLine: '네가 남겨 둔 금액까지 맞춰 봤어. 나 혼자 정하면 네가 답답할 것 같아서.',
        secondLine: '은행 같이 갈래? 돌아오는 길에 장부 표지도 하나 고르고.',
        followUpLead: '같이 정하니까 덜 불안했어. 나도 내 생각을 먼저 말해 봤고.',
      ),
    },
    options: <MonthlyUnlockOptionDefinition>[
      MonthlyUnlockOptionDefinition(
        id: 'check_dates_together',
        label: '서아가 적은 날짜부터 같이 본다',
        description: '이전 기록과 다음 달 운영자금을 함께 확인한다.',
        heroineReply: '다음에는 나도 표부터 내밀지 말고 먼저 물어볼게.',
        affectionDelta: 1,
        trustDelta: 2,
        closenessDelta: 1,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'compare_rates',
        label: '각자 계산한 금리표를 맞춰 본다',
        description: '같은 숫자가 나오는지 직접 비교한다.',
        heroineReply: '계산이 같네. 그럼 이 줄은 같이 확인한 걸로 표시할게.',
        affectionDelta: 1,
        investmentRespectDelta: 2,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'respect_space',
        label: '윤하린에게 묻고 서아에게 공간을 준다',
        description: '동행을 강요하지 않고 필요한 기록만 받는다.',
        heroineReply: '응. 필요한 곳엔 표시해 놨어. 지금은 이 정도가 편해.',
        trustDelta: 1,
      ),
    ],
  ),
  MonthlyUnlockChapterDefinition(
    id: '2000-03-business-observation',
    year: 2000,
    month: 3,
    heroineId: 'han_sua',
    title: '3월 · 문구점에서 사라진 단골',
    location: '센터 근처 문구점',
    situation:
        '센터 근처 문구점의 단골이 갑자기 줄었다. 이번 주는 돈을 쓰지 않고 손님 표정·재고·유동인구를 나눠 관찰하기로 했다.',
    featureLabel: '동네상권넷 · 상권 관찰 해금',
    npcLine: '문구점 주인: 사러 오는 애보다 구경만 하고 가는 애가 부쩍 많아졌어.',
    unlockFlags: <String, bool>{businessMarketAccessUnlockedFlag: true},
    dialogueByTone: <MonthlyHeroineTone, MonthlyToneDialogue>{
      MonthlyHeroineTone.fractured: MonthlyToneDialogue(
        stageDirection: '수아는 평소처럼 농담을 꺼내려다 입술을 꾹 다물었다.',
        firstLine: '분위기 띄우려는 건 아니야. 문구점 손님 진짜 줄었어. 우리 일만 보자.',
        secondLine: '네가 불편하면 따로 조사해도 돼. 들은 말은 내가 보태지 않고 그대로 적을게.',
        followUpLead: '오늘은 괜히 웃겨 보이려 하지 않았어.',
      ),
      MonthlyHeroineTone.strained: MonthlyToneDialogue(
        stageDirection: '수아는 문구점 유리문에 비친 플레이어를 보고도 바로 돌아보지 않았다.',
        firstLine: '너랑 어색한 건 맞는데, 아줌마 걱정되는 것도 진짜야.',
        secondLine: '그러니까 우리 얘기랑 가게 얘기는 섞지 말자. 적어도 오늘은.',
        followUpLead: '아직 말 걸 때 한 번 더 생각하게 돼.',
      ),
      MonthlyHeroineTone.awkward: MonthlyToneDialogue(
        stageDirection: '수아가 연필 진열대 뒤에서 빼꼼 고개를 내밀었다.',
        firstLine: '혹시 같이 세어 볼래? 아니, 부담되면 너는 밖에서 사람 수만 봐도 되고.',
        secondLine: '내가 또 신나서 추측을 사실처럼 말하면 바로 잡아 줘. 진짜로.',
        followUpLead: '너랑 나눠 보니까 내가 본 거랑 바란 게 좀 구분됐어.',
      ),
      MonthlyHeroineTone.friendly: MonthlyToneDialogue(
        stageDirection: '수아가 작은 메모지를 세 장이나 흔들며 달려왔다.',
        firstLine: '잠깐, 손님이 없는 게 아니라 다들 들어왔다가 그냥 나가! 이거 완전 다른 얘기잖아.',
        secondLine: '너는 숫자 세어 줘. 나는 왜 안 샀는지 물어볼게. 끝나고 답 맞추자.',
        followUpLead: '야, 우리 둘이 본 게 딱 맞물렸어.',
      ),
      MonthlyHeroineTone.close: MonthlyToneDialogue(
        stageDirection: '수아가 장난기 없는 얼굴로 플레이어 소매를 살짝 잡았다가 금방 놓았다.',
        firstLine: '나 사실 아줌마 표정 보고 좀 겁났어. 괜히 내가 큰일처럼 만드는 걸까 봐 말 못 했어.',
        secondLine: '같이 확인해 줄래? 네가 옆에 있으면 나도 추측이라고 먼저 말할 수 있을 것 같아.',
        followUpLead: '혼자 신난 척 안 해도 돼서 좋았어.',
      ),
    },
    options: <MonthlyUnlockOptionDefinition>[
      MonthlyUnlockOptionDefinition(
        id: 'ask_customers',
        label: '수아와 손님에게 직접 물어본다',
        description: '왜 구경만 하고 나가는지 짧게 질문한다.',
        heroineReply: '좋아. 내가 말을 보태면 바로 눈으로 신호 줘.',
        affectionDelta: 1,
        trustDelta: 1,
        closenessDelta: 1,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'count_traffic',
        label: '유동인구와 실제 구매를 따로 센다',
        description: '사람 반응과 숫자가 같은 방향인지 확인한다.',
        heroineReply: '내가 들은 말이랑 실제 숫자를 따로 놓으니까 훨씬 잘 보인다.',
        investmentRespectDelta: 2,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'split_observation',
        label: '조사 구역을 나눠 각자 확인한다',
        description: '지금의 관계 거리를 존중하며 결과만 합친다.',
        heroineReply: '응. 끝나고 합칠 때만 빠뜨린 거 확인하자.',
        trustDelta: 1,
      ),
    ],
  ),
  MonthlyUnlockChapterDefinition(
    id: '2000-04-business-operation',
    year: 2000,
    month: 4,
    heroineId: 'jung_arin',
    title: '4월 · 가게를 맡은 일주일',
    location: '센터 근처 문구점 · 창고',
    situation:
        '문구점 주인이 일주일 동안 작은 진열대를 맡겼다. 가격·수량·홍보·담당을 직접 정하고 결과를 확인하면 실제 인수·창업을 검토할 수 있다.',
    featureLabel: '동네상권넷 · 인수·창업 해금',
    npcLine: '문구점 주인: 많이 파는 것보다 약속한 수량을 제때 채우는지부터 볼 거야.',
    unlockFlags: <String, bool>{businessOperationsUnlockedFlag: true},
    dialogueByTone: <MonthlyHeroineTone, MonthlyToneDialogue>{
      MonthlyHeroineTone.fractured: MonthlyToneDialogue(
        stageDirection: '아린은 시간표를 플레이어 쪽이 아닌 탁자 가운데에 내려놓았다.',
        firstLine: '우리 얘기는 나중에 해. 지금은 가게부터. 네 몫까지 내가 정하진 않을게.',
        secondLine: '하기 싫으면 지금 말해. 싫은데 괜찮은 척하다가 미루는 건 더 싫어.',
        followUpLead: '네가 말한 경계는 일정표에 억지로 넣지 않았어.',
      ),
      MonthlyHeroineTone.strained: MonthlyToneDialogue(
        stageDirection: '아린은 평소보다 천천히, 한 항목씩 손가락으로 짚었다.',
        firstLine: '내 말투 세다고 했던 거 기억해. 오늘은 네가 할 수 있는 것부터 말해.',
        secondLine: '대신 정한 건 지키자. 서운한 거랑 약속 시간은 따로 얘기할 수 있잖아.',
        followUpLead: '재촉하기 전에 네 대답을 기다렸어.',
      ),
      MonthlyHeroineTone.awkward: MonthlyToneDialogue(
        stageDirection: '아린은 빈 시간표 칸을 두고 연필을 플레이어에게 건넸다.',
        firstLine: '내가 다 정하면 편하긴 한데, 너랑 처음 맞추는 거니까 네 시간부터 써.',
        secondLine: '틀려도 돼. 대신 언제 다시 볼지는 지금 정하자.',
        followUpLead: '생각보다 같이 정하는 데 오래 안 걸렸네.',
      ),
      MonthlyHeroineTone.friendly: MonthlyToneDialogue(
        stageDirection: '아린이 젖은 앞머리를 넘기며 시간표 한쪽을 툭 두드렸다.',
        firstLine: '좋아, 네가 가격표. 내가 재고. 여섯 시에 바꿔서 서로 검사.',
        secondLine: '근데 네가 더 편한 순서 있으면 지금 바꾸자. 시작하고 투덜대지 말고.',
        followUpLead: '네 방식도 생각보다 빨랐어. 다음엔 처음부터 물어볼게.',
      ),
      MonthlyHeroineTone.close: MonthlyToneDialogue(
        stageDirection: '아린은 완성한 시간표 대신 빈 종이를 먼저 내밀었다.',
        firstLine: '나 또 혼자 다 짤 뻔했어. 너는 몇 시가 편해?',
        secondLine: '네가 힘들면 내가 한 칸 더 맡을 수 있어. 대신 숨기지 말고 바로 말해.',
        followUpLead: '너한텐 통보보다 물어보는 게 더 빠르다는 거 이제 알아.',
      ),
    },
    options: <MonthlyUnlockOptionDefinition>[
      MonthlyUnlockOptionDefinition(
        id: 'agree_roles',
        label: '담당과 마감을 함께 정한다',
        description: '아린의 실행력에 플레이어의 가능한 시간을 맞춘다.',
        heroineReply: '좋아. 네 칸은 네가 정했으니까 나도 함부로 안 바꿀게.',
        affectionDelta: 1,
        trustDelta: 2,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'test_small_batch',
        label: '소량만 먼저 진열해 반응을 본다',
        description: '속도보다 작은 실행 결과를 먼저 확인한다.',
        heroineReply: '오케이. 열 개만 하고 여섯 시에 결과 보자.',
        investmentRespectDelta: 2,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'choose_own_task',
        label: '각자 맡을 일을 직접 고른다',
        description: '지시보다 경계를 분명히 한 뒤 협력한다.',
        heroineReply: '반대면 이유 말해 줘. 이번엔 네 몫을 내가 대신 안 정할게.',
        trustDelta: 1,
        closenessDelta: 1,
      ),
    ],
  ),
  MonthlyUnlockChapterDefinition(
    id: '2000-05-real-estate-research',
    year: 2000,
    month: 5,
    heroineId: 'yoon_chaea',
    title: '5월 · 소개장과 세 개의 매물',
    location: '한마음부동산 · 상담 탁자',
    situation:
        '윤하린이 건넨 소개장으로 서하늘 공인중개사를 만났다. 같은 가격처럼 보이는 세 매물의 기준일·취득비·공실·월 순현금을 비교한다.',
    featureLabel: '한마음부동산 · 매물 조회와 분석 해금',
    npcLine: '서하늘: 매입가는 첫 숫자일 뿐이에요. 세금과 빈 기간까지 같은 날짜로 맞춰 보세요.',
    unlockFlags: <String, bool>{realEstateAccessUnlockedFlag: true},
    dialogueByTone: <MonthlyHeroineTone, MonthlyToneDialogue>{
      MonthlyHeroineTone.fractured: MonthlyToneDialogue(
        stageDirection: '채아는 플레이어와 눈을 맞추지 않은 채 매물표의 기준일만 동그라미 쳤다.',
        firstLine: '우리 사이를 해결한 척하고 같이 다닐 생각은 없어. 자료는 같은 걸 보자.',
        secondLine: '네 결론에 반대해도 사람을 공격하진 않을게. 너도 내 말을 사실처럼 받아들이진 마.',
        followUpLead: '관계랑 자료를 섞지 않으려고 했어.',
      ),
      MonthlyHeroineTone.strained: MonthlyToneDialogue(
        stageDirection: '채아는 자기 메모의 절반을 가린 채 필요한 숫자만 읽어 주었다.',
        firstLine: '아직 내 생각을 전부 보여 주고 싶진 않아. 기준일이 다른 건 말해 줄게.',
        secondLine: '지금은 각자 계산하고 마지막에 전제만 비교하자.',
        followUpLead: '결론보다 쓴 전제를 남겼어.',
      ),
      MonthlyHeroineTone.awkward: MonthlyToneDialogue(
        stageDirection: '채아가 세 장의 매물표를 가격 순서가 아니라 날짜 순서로 다시 놓았다.',
        firstLine: '이거, 같은 가격표가 아니야. 적힌 날짜가 다르잖아.',
        secondLine: '내가 중간 설명을 잘 생략해. 이해 안 되면 바로 끊고 물어봐.',
        followUpLead: '이번엔 중간 가정도 두 줄 남겼어.',
      ),
      MonthlyHeroineTone.friendly: MonthlyToneDialogue(
        stageDirection: '채아가 자기 옆 의자를 발끝으로 조금 빼 주었다.',
        firstLine: '여기 앉아. 가격보다 왜 이 매물만 오래 남았는지부터 보자.',
        secondLine: '네가 현장에서 이상한 점 찾으면 말해 줘. 내 표에는 그런 게 자주 빠져.',
        followUpLead: '네가 찾은 현장 정보 때문에 내 순서가 바뀌었어.',
      ),
      MonthlyHeroineTone.close: MonthlyToneDialogue(
        stageDirection: '채아는 아직 지우지 않은 연필 계산까지 그대로 펼쳐 보였다.',
        firstLine: '완성된 결론은 아니야. 그래도 너한텐 중간부터 보여 줘도 될 것 같아.',
        secondLine: '내가 놓친 걸 찾으면 바로 말해. 네가 틀릴 수도 있고, 내가 틀릴 수도 있으니까.',
        followUpLead: '미완성인 걸 보여 주는 게 전보다 덜 불편했어.',
      ),
    },
    options: <MonthlyUnlockOptionDefinition>[
      MonthlyUnlockOptionDefinition(
        id: 'align_dates',
        label: '세 매물의 기준일부터 맞춘다',
        description: '서로 다른 날짜의 가격을 같은 숫자처럼 보지 않는다.',
        heroineReply: '이제 비교가 돼. 날짜 하나 때문에 결론이 꽤 달라졌어.',
        investmentRespectDelta: 2,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'share_assumptions',
        label: '각자 쓴 전제를 한 줄씩 공개한다',
        description: '결론보다 생각의 중간 과정을 나눈다.',
        heroineReply: '네 전제는 내가 안 넣었던 거야. 표에 따로 남겨 둘게.',
        affectionDelta: 1,
        trustDelta: 1,
        closenessDelta: 1,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'compare_separately',
        label: '각자 계산한 뒤 마지막에만 비교한다',
        description: '지금의 관계 거리를 지키면서 자료는 함께 검증한다.',
        heroineReply: '좋아. 결론이 다르면 어느 전제부터 갈렸는지만 보자.',
        trustDelta: 1,
      ),
    ],
  ),
  MonthlyUnlockChapterDefinition(
    id: '2000-06-real-estate-contract',
    year: 2000,
    month: 6,
    heroineId: 'lee_jian',
    title: '6월 · 빈 점포의 열쇠',
    location: '강남의 빈 상가 · 현장 점검',
    situation:
        '서하늘이 교육용 빈 점포의 열쇠를 맡겼다. 벽의 습기·전기 차단기·수리비·대출 상환을 직접 확인한 뒤 실제 매입과 임대 계약 기능이 열린다.',
    featureLabel: '부동산 · 매입·대출·임대 계약 해금',
    npcLine: '서하늘: 계약서보다 먼저 현장을 보세요. 눈에 안 보인 수리는 결국 현금으로 나갑니다.',
    unlockFlags: <String, bool>{realEstateTransactionsUnlockedFlag: true},
    dialogueByTone: <MonthlyHeroineTone, MonthlyToneDialogue>{
      MonthlyHeroineTone.fractured: MonthlyToneDialogue(
        stageDirection: '지안은 드라이버를 돌리다 플레이어가 다가오자 반걸음 옆으로 비켰다.',
        firstLine: '지금 같이 붙어서 볼 필요는 없어. 나는 차단기, 너는 벽.',
        secondLine: '지난 일은 안 고쳐졌어. 그래도 일부러 위험한 곳을 말 안 하진 않을게.',
        followUpLead: '고장 난 곳은 전부 표시했어. 우리 얘기랑은 별개야.',
      ),
      MonthlyHeroineTone.strained: MonthlyToneDialogue(
        stageDirection: '지안은 필요한 공구만 건네고 손을 바로 거두었다.',
        firstLine: '설명 길게 안 할게. 이쪽 벽 눌러 봐. 축축하면 바로 말해.',
        secondLine: '말 안 섞어도 검사는 할 수 있어. 빠뜨리지만 말자.',
        followUpLead: '같이 있긴 어색했는데, 검사는 제대로 끝났어.',
      ),
      MonthlyHeroineTone.awkward: MonthlyToneDialogue(
        stageDirection: '지안은 차단기 덮개를 열어 둔 채 플레이어가 올 때까지 기다렸다.',
        firstLine: '이거 한번 내려 볼래? 무서우면 내가 하고.',
        secondLine: '좋아 보인다는 말보다 작동하는지 먼저 보자. 사람 사이도… 아니, 그건 다른 얘기고.',
        followUpLead: '네가 직접 확인해서 설명이 짧아도 됐어.',
      ),
      MonthlyHeroineTone.friendly: MonthlyToneDialogue(
        stageDirection: '지안이 빨간 손잡이 드라이버를 플레이어 손바닥에 툭 올려놓았다.',
        firstLine: '잡아. 나사 하나 풀어 보면 벽 안이 어떤지 바로 보여.',
        secondLine: '네가 발견하면 수리비 계산은 내가 할게. 누가 먼저 찾나 해 볼래?',
        followUpLead: '네가 찾은 누수 자국, 진짜였어. 꽤 잘 봤네.',
      ),
      MonthlyHeroineTone.close: MonthlyToneDialogue(
        stageDirection: '지안은 자기가 아끼는 드라이버를 망설임 없이 플레이어에게 먼저 건넸다.',
        firstLine: '이건 네가 열어 봐. 손 미끄러우면 내가 옆에서 잡아 줄게.',
        secondLine: '모르면 바로 말해. 나도 감정 얘기는 잘 모르니까 물어보잖아.',
        followUpLead: '같이 보니까 내가 놓친 소리도 들렸어.',
      ),
    },
    options: <MonthlyUnlockOptionDefinition>[
      MonthlyUnlockOptionDefinition(
        id: 'inspect_together',
        label: '지안과 현장을 한 칸씩 점검한다',
        description: '설명보다 직접 눌러 보고 작동시킨다.',
        heroineReply: '다음엔 배관 쪽도 같이 보자. 네가 듣는 소리가 나랑 좀 달라.',
        affectionDelta: 1,
        trustDelta: 1,
        closenessDelta: 1,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'test_before_contract',
        label: '계약 전에 수리 항목부터 시험한다',
        description: '가격보다 고장 원인과 실제 비용을 확인한다.',
        heroineReply: '작동 안 하는 걸 싼 가격으로 덮을 순 없지. 이 순서가 맞아.',
        investmentRespectDelta: 2,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'separate_zones',
        label: '점검 구역을 나눠 거리를 지킨다',
        description: '가까이 붙지 않아도 결과를 정확히 공유한다.',
        heroineReply: '응. 네 구역에서 위험한 것만 바로 불러 줘.',
        trustDelta: 1,
      ),
    ],
  ),
  MonthlyUnlockChapterDefinition(
    id: '2000-07-property-operation',
    year: 2000,
    month: 7,
    heroineId: 'park_haeun',
    title: '7월 · 비 오는 날의 빈 방',
    location: '교육용 상가 · 빗물 새는 복도',
    situation:
        '장맛비에 교육용 점포 천장에서 물이 샜다. 수리 순서만이 아니라 임차인이 원하는 설명과 기다릴 수 있는 시간을 확인해야 한다.',
    featureLabel: '부동산 · 수리·보험·임차인 운영 해금',
    npcLine: '서하늘: 수리비만 계산하면 절반이에요. 그동안 장사를 못 하는 사람의 시간도 계약에 남습니다.',
    unlockFlags: <String, bool>{realEstateOperationsUnlockedFlag: true},
    dialogueByTone: <MonthlyHeroineTone, MonthlyToneDialogue>{
      MonthlyHeroineTone.fractured: MonthlyToneDialogue(
        stageDirection: '하은은 모두에게 수건을 나눠 주면서도 플레이어 몫은 가까운 의자에 조용히 두었다.',
        firstLine: '네가 도움받는 게 불편할 수도 있으니까 여기 둘게. 가져갈지는 네가 정해.',
        secondLine: '우리 갈등을 오늘 억지로 풀 생각은 없어. 임차인 말만 끊지 않고 듣자.',
        followUpLead: '네 마음까지 내가 정하지 않으려고 했어.',
      ),
      MonthlyHeroineTone.strained: MonthlyToneDialogue(
        stageDirection: '하은은 말을 고르느라 평소보다 질문 사이가 길었다.',
        firstLine: '내가 또 괜찮아지라고 재촉할까 봐 먼저 물을게. 같이 들어도 괜찮아?',
        secondLine: '싫으면 내가 혼자 듣고 그대로 전할게. 예쁘게 바꿔 말하지 않고.',
        followUpLead: '네가 싫다고 한 부분은 그대로 남겼어.',
      ),
      MonthlyHeroineTone.awkward: MonthlyToneDialogue(
        stageDirection: '하은은 우산 두 개 중 하나를 내밀다 잠깐 멈췄다.',
        firstLine: '같이 쓸래? 아니면 하나씩 들까? 네가 편한 쪽으로.',
        secondLine: '수리부터 말하기 전에 임차인한테 뭐가 제일 급한지 물어보자.',
        followUpLead: '먼저 물어보니까 내가 짐작한 거랑 다른 게 있었어.',
      ),
      MonthlyHeroineTone.friendly: MonthlyToneDialogue(
        stageDirection: '하은이 젖은 수건을 받아 들고 플레이어 상태부터 살폈다.',
        firstLine: '너 손 차가워. 괜찮아? 그냥 수건만 줄까, 잠깐 쉴래?',
        secondLine: '임차인도 똑같을 거야. 우리가 해 줄 말 말고, 원하는 걸 먼저 듣자.',
        followUpLead: '네가 먼저 기다려 줘서 그분도 끝까지 말했어.',
      ),
      MonthlyHeroineTone.close: MonthlyToneDialogue(
        stageDirection: '하은은 젖은 머리카락을 털다가 처음으로 자기 피곤한 얼굴을 숨기지 않았다.',
        firstLine: '나 사실 좀 벅차. 다 챙기려다가 누구 말도 제대로 못 들을까 봐.',
        secondLine: '오늘은 내 옆에서 같이 들어 줄래? 해결은 그다음에 해도 되니까.',
        followUpLead: '내가 힘들다고 먼저 말해도 네가 부담스러워하지 않아서 다행이었어.',
      ),
    },
    options: <MonthlyUnlockOptionDefinition>[
      MonthlyUnlockOptionDefinition(
        id: 'ask_tenant_first',
        label: '임차인이 원하는 도움부터 묻는다',
        description: '좋은 의도로 해결책을 먼저 정하지 않는다.',
        heroineReply: '응. 우리가 생각한 급한 일과 그분이 말한 급한 일이 달랐어.',
        affectionDelta: 1,
        trustDelta: 1,
        closenessDelta: 1,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'separate_people_and_cost',
        label: '영업 손실과 수리비를 함께 적는다',
        description: '사람의 시간을 회계 밖으로 지우지 않는다.',
        heroineReply: '숫자로 적어 두니까 미안하다는 말만 하고 끝내지 않게 돼.',
        investmentRespectDelta: 2,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'offer_choice',
        label: '함께할지 각자 움직일지 하은에게 묻는다',
        description: '도움을 강요하지 않고 선택권을 돌려준다.',
        heroineReply: '고마워. 오늘은 같이 듣고, 정리는 내가 해 볼게.',
        trustDelta: 1,
      ),
    ],
  ),
  MonthlyUnlockChapterDefinition(
    id: '2000-08-property-business-link',
    year: 2000,
    month: 8,
    heroineId: 'choi_iseo',
    title: '8월 · 빈 점포에 놓을 첫 물건',
    location: '교육용 상가 · 비어 있는 진열대',
    situation:
        '빈 상가를 임대할지 직접 가게로 쓸지 결정해야 한다. 이서는 예쁜 배치보다 실제로 일할 사람과 손님이 편한지부터 시험해 보자고 한다.',
    featureLabel: '보유 부동산 · 직영 사업장 연결 해금',
    npcLine: '서하늘: 직접 쓰면 임대료는 아끼지만 사업의 손실도 건물주가 함께 감당해야 해요.',
    unlockFlags: <String, bool>{propertyBusinessLinkUnlockedFlag: true},
    dialogueByTone: <MonthlyHeroineTone, MonthlyToneDialogue>{
      MonthlyHeroineTone.fractured: MonthlyToneDialogue(
        stageDirection: '이서는 자기 실꾸러미를 플레이어 손이 닿지 않는 쪽에 두고 진열대만 바라봤다.',
        firstLine: '내 물건은 만지지 말아 줘. 가게 배치는 필요한 만큼 같이 볼게.',
        secondLine: '사이가 안 좋다고 네 의견까지 없는 건 아니니까. 대신 내 선택도 대신 정하지 마.',
        followUpLead: '선을 지켜 준 건 알아.',
      ),
      MonthlyHeroineTone.strained: MonthlyToneDialogue(
        stageDirection: '이서는 색실을 고르다 플레이어 쪽을 한번 보고 다시 손을 멈췄다.',
        firstLine: '같이 하긴 할 건데, 내 방식까지 고쳐 주려고 하진 마.',
        secondLine: '너도 싫은 건 바로 말해. 나중에 조용히 피하면 더 헷갈려.',
        followUpLead: '각자 싫은 걸 먼저 말하니까 덜 부딪혔어.',
      ),
      MonthlyHeroineTone.awkward: MonthlyToneDialogue(
        stageDirection: '이서는 빈 선반 위에 천 조각 두 장을 올려놓고 플레이어 반응을 살폈다.',
        firstLine: '나는 이쪽이 좋은데… 네가 매일 쓸 거면 네 손이 편한 게 먼저야.',
        secondLine: '한번 서 봐. 보기만 하지 말고 물건 꺼내는 척해 보자.',
        followUpLead: '직접 써 보니까 내가 예쁘다고 고른 쪽이 조금 불편했어.',
      ),
      MonthlyHeroineTone.friendly: MonthlyToneDialogue(
        stageDirection: '이서가 플레이어 손목 높이에 맞춰 선반 위치를 재 보았다.',
        firstLine: '여기면 네가 숙일 때 자꾸 부딪혀. 예뻐도 매일 아프면 싫잖아.',
        secondLine: '네가 손님 해 봐. 나는 주인 해 볼게. 바꿔서도 해 보고.',
        followUpLead: '네가 손님인 척한 거 좀 웃겼어. 그래도 불편한 곳은 잘 찾더라.',
      ),
      MonthlyHeroineTone.close: MonthlyToneDialogue(
        stageDirection: '이서는 아끼던 천 조각을 플레이어 손에 직접 올려 주었다.',
        firstLine: '이거 만져 봐. 내가 왜 좋아하는지 말로는 잘 설명 못 하겠어.',
        secondLine: '근데 네가 별로면 괜찮아. 네 취향까지 내 걸로 만들고 싶진 않아.',
        followUpLead: '내가 좋아하는 걸 보여 줘도 네가 함부로 정하지 않아서 좋았어.',
      ),
    },
    options: <MonthlyUnlockOptionDefinition>[
      MonthlyUnlockOptionDefinition(
        id: 'test_as_users',
        label: '주인과 손님 역할을 바꿔 시험한다',
        description: '보기 좋은 배치와 실제 사용감을 분리한다.',
        heroineReply: '반대로 서 보니까 또 다르네. 이건 바꾸자.',
        affectionDelta: 1,
        closenessDelta: 1,
        investmentRespectDelta: 1,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'ask_permission',
        label: '이서의 물건은 먼저 허락을 구한다',
        description: '가까운 사이여도 개인 경계를 지킨다.',
        heroineReply: '응, 이건 만져도 돼. 먼저 물어봐 줘서 고마워.',
        trustDelta: 2,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'compare_rent_and_use',
        label: '임대와 직영의 실제 사용을 비교한다',
        description: '취향뿐 아니라 비용과 일하는 사람의 편의도 본다.',
        heroineReply: '내가 좋다고 다 좋은 건 아니네. 쓰는 사람별로 따로 적자.',
        investmentRespectDelta: 2,
      ),
    ],
  ),
  MonthlyUnlockChapterDefinition(
    id: '2000-09-corporate-actions',
    year: 2000,
    month: 9,
    heroineId: 'oh_jiwoo',
    title: '9월 · 주식 수가 갑자기 늘어난 날',
    location: '강남 아지트 · 투자실',
    situation:
        '보유 회사에서 배당·분할·유상증자 안내가 동시에 도착했다. 지우와 공지 제목의 단일 설명을 의심하고 실제 주식 수와 권리 조건을 확인한다.',
    featureLabel: '주식 · 배당·분할·권리 선택 심화 해금',
    npcLine: '한서윤: 좋은 소식이라는 제목보다 내 계좌의 수량·현금·기준일이 어떻게 바뀌는지 보세요.',
    unlockFlags: <String, bool>{advancedCorporateActionsUnlockedFlag: true},
    dialogueByTone: <MonthlyHeroineTone, MonthlyToneDialogue>{
      MonthlyHeroineTone.fractured: MonthlyToneDialogue(
        stageDirection: '지우는 입을 열며 방송 흉내를 내려다 스스로 손으로 입가를 가렸다.',
        firstLine: '방송 놀이는 안 할게. 네가 지금 내 농담 싫어하는 거 아니까.',
        secondLine: '권리 조건만 보자. 내가 반대 질문을 해도 너를 공격하려는 건 아니야.',
        followUpLead: '오늘은 웃기게 넘기지 않았어.',
      ),
      MonthlyHeroineTone.strained: MonthlyToneDialogue(
        stageDirection: '지우는 평소보다 말풍선처럼 끊기는 말 대신 한 문장씩 천천히 말했다.',
        firstLine: '나 또 말싸움으로 바꿀까 봐 먼저 말하는데, 지금은 네 결론을 이기려는 거 아냐.',
        secondLine: '틀릴 수 있는 조건 하나씩만 던지자. 싫으면 바로 멈추고.',
        followUpLead: '반박보다 확인할 조건만 남겼어.',
      ),
      MonthlyHeroineTone.awkward: MonthlyToneDialogue(
        stageDirection: '지우가 라디오 주파수를 맞추듯 공지 세 장의 제목을 번갈아 가리켰다.',
        firstLine: '속보…라고 할 뻔했다. 아무튼 좋은 소식 세 장이면 진짜 세 배로 좋은 건가?',
        secondLine: '내가 괜히 꼬는 것 같으면 말해. 그래도 한 번은 반대로 가정해 보자.',
        followUpLead: '네가 안 웃어도 계속 말해도 되는지 먼저 물어봤어.',
      ),
      MonthlyHeroineTone.friendly: MonthlyToneDialogue(
        stageDirection: '지우가 종이 세 장을 부채처럼 펼치며 플레이어 의자 옆에 쪼그려 앉았다.',
        firstLine: '긴급 속보. 주식 수가 늘었는데 우리가 부자가 아닐 가능성 발견.',
        secondLine: '자, 네가 낙관 방송. 내가 반대 방송. 마지막엔 계좌 숫자로 판정하자.',
        followUpLead: '너 반대편 맡기니까 생각보다 독하더라. 재밌었어.',
      ),
      MonthlyHeroineTone.close: MonthlyToneDialogue(
        stageDirection: '지우는 장난스러운 제목을 적었다가 지우개로 지우고 작은 목소리로 말했다.',
        firstLine: '나 사실 이거 틀릴까 봐 먼저 웃긴 척했어. 네가 같이 보면 좀 덜 쪽팔릴 것 같아서.',
        secondLine: '내 가설 깨지면 핑계 안 붙일게. 대신 네 것도 같이 깨 봐도 돼?',
        followUpLead: '틀릴까 봐 겁난다고 먼저 말해도 분위기 안 망가지더라.',
      ),
    },
    options: <MonthlyUnlockOptionDefinition>[
      MonthlyUnlockOptionDefinition(
        id: 'argue_both_sides',
        label: '낙관과 반대 가설을 하나씩 맡는다',
        description: '말싸움이 아니라 깨지는 조건을 찾는다.',
        heroineReply: '반례 나왔네. 이번엔 새 핑계 안 붙이고 첫 가설 지울게.',
        affectionDelta: 1,
        closenessDelta: 1,
        investmentRespectDelta: 1,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'check_account_effect',
        label: '계좌의 수량과 현금 변화를 먼저 본다',
        description: '공지 제목보다 실제 권리 결과를 확인한다.',
        heroineReply: '속보 정정. 제목보다 계좌 숫자가 훨씬 덜 신났습니다.',
        investmentRespectDelta: 2,
      ),
      MonthlyUnlockOptionDefinition(
        id: 'set_debate_boundary',
        label: '불편하면 바로 멈추기로 약속한다',
        description: '논쟁의 재미보다 친구의 경계를 먼저 확인한다.',
        heroineReply: '알겠어. 방송 중단 신호 정하자. 네가 손 들면 바로 멈출게.',
        trustDelta: 2,
      ),
    ],
  ),
];
