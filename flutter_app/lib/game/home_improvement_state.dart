enum HomeImprovementRoom { bedroom, livingRoom, kitchen }

enum HomeCommunityMember { hakjun, sua, seoa, jian, cohort }

class HomeStoryLine {
  const HomeStoryLine({this.speaker, required this.text});

  final String? speaker;
  final String text;
}

class HomeImprovementDefinition {
  const HomeImprovementDefinition({
    required this.id,
    required this.room,
    required this.stage,
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.communityMember,
    required this.communityTrustDelta,
    required this.facilityStabilityDelta,
    required this.affinityDelta,
    required this.storyEventId,
    required this.storyTitle,
    required this.storyLines,
    this.prerequisiteId,
  });

  final String id;
  final HomeImprovementRoom room;
  final int stage;
  final String title;
  final String subtitle;
  final int cost;
  final HomeCommunityMember communityMember;
  final int communityTrustDelta;
  final int facilityStabilityDelta;
  final int affinityDelta;
  final String storyEventId;
  final String storyTitle;
  final List<HomeStoryLine> storyLines;
  final String? prerequisiteId;
}

const homeImprovementCatalog = <HomeImprovementDefinition>[
  HomeImprovementDefinition(
    id: 'dorm_repair_tools',
    room: HomeImprovementRoom.bedroom,
    stage: 1,
    title: '기숙사 공용 수리함',
    subtitle: '헐거운 침상과 사물함을 고칠 드라이버·나사·절연테이프를 갖춥니다.',
    cost: 30000,
    communityMember: HomeCommunityMember.jian,
    communityTrustDelta: 1,
    facilityStabilityDelta: 4,
    affinityDelta: 4,
    storyEventId: 'ACADEMY_DORM_REPAIR_TOOLS',
    storyTitle: '흔들리던 사다리가 멈춘 날',
    storyLines: [
      HomeStoryLine(text: '이지안이 새 공구함을 열어 규격별 나사를 작은 통에 나눠 담았다.'),
      HomeStoryLine(speaker: '이지안', text: '공구를 빌리면 어느 침상을 고쳤는지 기록해.'),
      HomeStoryLine(speaker: '나', text: '고장 낸 사람이 쓰는 칸도 만들까?'),
      HomeStoryLine(speaker: '이지안', text: '실수한 사람 칸 말고, 다음에 확인할 곳 칸을 만들어.'),
      HomeStoryLine(text: '둘은 흔들리던 위층 사다리를 조이고 생활기록표에 첫 수리 날짜를 적었다.'),
    ],
  ),
  HomeImprovementDefinition(
    id: 'dorm_shared_study_desks',
    room: HomeImprovementRoom.bedroom,
    stage: 2,
    title: '열 명의 공부자리',
    subtitle: '공용 책상을 보강하고 열 명의 투자노트 자리를 나눕니다.',
    cost: 120000,
    communityMember: HomeCommunityMember.seoa,
    communityTrustDelta: 2,
    facilityStabilityDelta: 6,
    affinityDelta: 6,
    storyEventId: 'ACADEMY_DORM_STUDY_DESKS',
    storyTitle: '겹치지 않는 열 권의 장부',
    prerequisiteId: 'dorm_repair_tools',
    storyLines: [
      HomeStoryLine(text: '김서아가 책상 가장자리에 열 개의 번호표를 같은 간격으로 붙였다.'),
      HomeStoryLine(speaker: '김서아', text: '넓이는 같게. 대신 안 쓰는 시간은 서로 빌려 주기.'),
      HomeStoryLine(speaker: '김학준', text: '대여 기록은 생활기록표 몇 쪽에 적지?'),
      HomeStoryLine(speaker: '한수아', text: '앉기도 전에 서류부터 만들면 공부시간 끝나겠다.'),
      HomeStoryLine(text: '열 권의 공책이 서로 겹치지 않고 처음으로 한 줄에 놓였다.'),
    ],
  ),
  HomeImprovementDefinition(
    id: 'common_room_winter_bedding',
    room: HomeImprovementRoom.livingRoom,
    stage: 1,
    title: '공용 겨울 침구',
    subtitle: '얇고 해진 여분 담요를 세탁 가능한 겨울 침구로 바꿉니다.',
    cost: 50000,
    communityMember: HomeCommunityMember.hakjun,
    communityTrustDelta: 1,
    facilityStabilityDelta: 4,
    affinityDelta: 5,
    storyEventId: 'ACADEMY_COMMON_WINTER_BEDDING',
    storyTitle: '숫자보다 먼저 따뜻해진 밤',
    storyLines: [
      HomeStoryLine(text: '학준은 새 담요 수량을 세다가 가장 얇은 한 장을 자기 침상에서 먼저 빼냈다.'),
      HomeStoryLine(
        speaker: '김학준',
        text: '여분 한 장은 세면실 앞 보관함. 젖었을 때 바로 바꿀 수 있게.',
      ),
      HomeStoryLine(speaker: '나', text: '규정집에도 담요 위치가 나와 있어?'),
      HomeStoryLine(speaker: '김학준', text: '없어서 지금 생활규칙에 추가하는 거야.'),
      HomeStoryLine(text: '그날 밤에는 이불을 더 달라는 목소리가 한 번도 나오지 않았다.'),
    ],
  ),
  HomeImprovementDefinition(
    id: 'common_room_floor_curtains',
    room: HomeImprovementRoom.livingRoom,
    stage: 2,
    title: '생활실 장판과 암막커튼',
    subtitle: '들뜬 장판을 고치고 외풍과 야간 빛을 막는 커튼을 답니다.',
    cost: 180000,
    communityMember: HomeCommunityMember.sua,
    communityTrustDelta: 2,
    facilityStabilityDelta: 8,
    affinityDelta: 6,
    storyEventId: 'ACADEMY_COMMON_FLOOR_CURTAINS',
    storyTitle: '발끝과 잠이 걸리지 않는 방',
    prerequisiteId: 'common_room_winter_bedding',
    storyLines: [
      HomeStoryLine(text: '매일 양말을 잡아당기던 장판 틈이 사라지고 창가의 찬빛도 부드러워졌다.'),
      HomeStoryLine(speaker: '한수아', text: '좋다. 이제 새벽에 가로등이 내 얼굴만 심문하지 않겠네.'),
      HomeStoryLine(speaker: '정아린', text: '기상 시간에는 바로 열어. 늦잠 핑계로 쓰면 안 돼.'),
      HomeStoryLine(speaker: '한수아', text: '봐. 설치 첫날부터 규정이 생겼어.'),
      HomeStoryLine(text: '아이들은 커튼을 닫고 여는 순번을 생활기록표 아래에 함께 적었다.'),
    ],
  ),
  HomeImprovementDefinition(
    id: 'cafeteria_shared_pantry',
    room: HomeImprovementRoom.kitchen,
    stage: 1,
    title: '제6기 공용 식품 선반',
    subtitle: '개인 간식과 공용 비상식량을 구분해 보관할 선반을 만듭니다.',
    cost: 25000,
    communityMember: HomeCommunityMember.seoa,
    communityTrustDelta: 2,
    facilityStabilityDelta: 5,
    affinityDelta: 4,
    storyEventId: 'ACADEMY_SHARED_PANTRY',
    storyTitle: '이름 없는 간식이 사라진 날',
    storyLines: [
      HomeStoryLine(text: '서아가 선반을 개인 칸 열 개와 공용 칸 하나로 나눴다.'),
      HomeStoryLine(
        speaker: '김서아',
        text: '공용 칸에서 먹으면 수량만 적어. 갚을 수 있을 때 같은 종류로 채우고.',
      ),
      HomeStoryLine(speaker: '한수아', text: '과자는 종류가 바뀌면 물가 변동으로 처리해 줘?'),
      HomeStoryLine(speaker: '윤채아', text: '가격표 가져오면 비교는 해줄게.'),
      HomeStoryLine(text: '누가 먹었는지 몰라 생기던 의심 대신, 남은 수량이 장부에 남기 시작했다.'),
    ],
  ),
  HomeImprovementDefinition(
    id: 'cafeteria_quiet_fridge',
    room: HomeImprovementRoom.kitchen,
    stage: 2,
    title: '검수한 공용 냉장고',
    subtitle: '밤마다 진동하던 냉장고를 검수한 중고 제품으로 바꿉니다.',
    cost: 220000,
    communityMember: HomeCommunityMember.cohort,
    communityTrustDelta: 3,
    facilityStabilityDelta: 10,
    affinityDelta: 2,
    storyEventId: 'ACADEMY_SHARED_FRIDGE',
    storyTitle: '모터 소리가 사라진 밤',
    prerequisiteId: 'cafeteria_shared_pantry',
    storyLines: [
      HomeStoryLine(text: '새 냉장고가 들어온 첫날 밤, 열 명이 문 앞에서 소리를 기다렸다.'),
      HomeStoryLine(speaker: '오지우', text: '고장 난 거 아니야? 너무 조용한데.'),
      HomeStoryLine(speaker: '이지안', text: '온도 내려가는 중이야. 모터 진동은 정상 범위.'),
      HomeStoryLine(speaker: '윤채아', text: '중고 가격표랑 전기 사용량도 붙여 둘게.'),
      HomeStoryLine(text: '누구도 깨지 않은 첫날 밤의 온도와 전기 사용량이 다음 날 장부에 기록됐다.'),
    ],
  ),
];

HomeImprovementDefinition? homeImprovementById(String id) {
  for (final improvement in homeImprovementCatalog) {
    if (improvement.id == id) return improvement;
  }
  return null;
}

class HomeImprovementState {
  const HomeImprovementState({
    required this.purchasedIds,
    required this.purchaseDayById,
    required this.totalSpent,
  });

  const HomeImprovementState.initial()
    : purchasedIds = const <String>[],
      purchaseDayById = const <String, int>{},
      totalSpent = 0;

  final List<String> purchasedIds;
  final Map<String, int> purchaseDayById;
  final int totalSpent;

  bool has(String improvementId) => purchasedIds.contains(improvementId);

  int roomTier(HomeImprovementRoom room) => homeImprovementCatalog
      .where((item) => item.room == room && has(item.id))
      .length
      .clamp(0, 2)
      .toInt();

  int get completedCount => purchasedIds.length;

  bool canPurchase(HomeImprovementDefinition improvement) {
    if (has(improvement.id)) return false;
    final prerequisite = improvement.prerequisiteId;
    return prerequisite == null || has(prerequisite);
  }

  HomeImprovementState recordPurchase(
    HomeImprovementDefinition improvement, {
    required int day,
  }) {
    if (has(improvement.id)) return this;
    return HomeImprovementState(
      purchasedIds: <String>[...purchasedIds, improvement.id],
      purchaseDayById: <String, int>{...purchaseDayById, improvement.id: day},
      totalSpent: totalSpent + improvement.cost,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'purchasedIds': purchasedIds,
    'purchaseDayById': purchaseDayById,
    'totalSpent': totalSpent,
  };

  factory HomeImprovementState.fromJson(Map<String, dynamic> json) {
    final knownIds = homeImprovementCatalog.map((item) => item.id).toSet();
    final purchasedIds = ((json['purchasedIds'] as List?) ?? const <dynamic>[])
        .whereType<String>()
        .where(knownIds.contains)
        .toSet()
        .toList(growable: false);
    final rawDays =
        (json['purchaseDayById'] as Map?) ?? const <dynamic, dynamic>{};
    final purchaseDayById = <String, int>{};
    for (final entry in rawDays.entries) {
      final id = entry.key.toString();
      if (!purchasedIds.contains(id) || entry.value is! num) continue;
      purchaseDayById[id] = (entry.value as num).toInt().clamp(1, 9862).toInt();
    }
    final catalogSpent = purchasedIds.fold<int>(
      0,
      (sum, id) => sum + (homeImprovementById(id)?.cost ?? 0),
    );
    return HomeImprovementState(
      purchasedIds: purchasedIds,
      purchaseDayById: purchaseDayById,
      totalSpent: catalogSpent,
    );
  }
}
