enum HomeImprovementRoom { bedroom, livingRoom, kitchen }

enum HomeFamilyMember { mother, father, sibling, grandfather, family }

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
    required this.familyMember,
    required this.familyTrustDelta,
    required this.householdStabilityDelta,
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
  final HomeFamilyMember familyMember;
  final int familyTrustDelta;
  final int householdStabilityDelta;
  final int affinityDelta;
  final String storyEventId;
  final String storyTitle;
  final List<HomeStoryLine> storyLines;
  final String? prerequisiteId;
}

const homeImprovementCatalog = <HomeImprovementDefinition>[
  HomeImprovementDefinition(
    id: 'bedroom_father_tools',
    room: HomeImprovementRoom.bedroom,
    stage: 1,
    title: '아버지 공구함 채우기',
    subtitle: '닳은 드라이버와 인두 팁을 바꾸고 작은방을 정리합니다.',
    cost: 30000,
    familyMember: HomeFamilyMember.father,
    familyTrustDelta: 1,
    householdStabilityDelta: 4,
    affinityDelta: 4,
    storyEventId: 'HOME_FATHER_TOOLS',
    storyTitle: '나사가 제자리를 찾은 날',
    storyLines: [
      HomeStoryLine(text: '새 드라이버와 인두 팁을 공구함에 끼워 두자, 아버지의 손이 한참 그 위에 머물렀다.'),
      HomeStoryLine(speaker: '아버지', text: '이걸 왜 샀어. 아직 쓸 만한데.'),
      HomeStoryLine(speaker: '주인공', text: '십자드라이버 끝 다 뭉개졌잖아.'),
      HomeStoryLine(speaker: '아버지', text: '그걸 봤어?'),
      HomeStoryLine(speaker: '주인공', text: '나도 기술자 아들이거든.'),
      HomeStoryLine(text: '아버지는 대답 대신 새 드라이버로 헐거운 책상 나사부터 조였다.'),
      HomeStoryLine(speaker: '아버지', text: '영수증은 버리지 마. 공구도 장부에 남겨.'),
    ],
  ),
  HomeImprovementDefinition(
    id: 'bedroom_sister_desk',
    room: HomeImprovementRoom.bedroom,
    stage: 2,
    title: '누나의 공부자리 만들기',
    subtitle: '흔들리는 책상을 고치고 복학 서류를 펼칠 자리를 만듭니다.',
    cost: 120000,
    familyMember: HomeFamilyMember.sibling,
    familyTrustDelta: 2,
    householdStabilityDelta: 6,
    affinityDelta: 6,
    storyEventId: 'HOME_SISTER_DESK',
    storyTitle: '뒤집어 두지 않아도 되는 종이',
    prerequisiteId: 'bedroom_father_tools',
    storyLines: [
      HomeStoryLine(text: '잡지 밑에 접혀 있던 복학 신청서가 새 책상 한가운데 반듯하게 놓였다.'),
      HomeStoryLine(speaker: '누나', text: '야. 이거 진짜 내 자리야?'),
      HomeStoryLine(speaker: '주인공', text: '오른쪽 서랍만 내 장부 칸.'),
      HomeStoryLine(speaker: '누나', text: '그럼 반쪽짜리잖아.'),
      HomeStoryLine(speaker: '주인공', text: '책상값은 내가 다 냈는데?'),
      HomeStoryLine(text: '누나는 생색내지 말라며 밀어냈지만, 접힌 신청서부터 조심스럽게 폈다.'),
      HomeStoryLine(speaker: '누나', text: '알았어, 회장님. 대신 키보드 빌린 값은 아직이야.'),
    ],
  ),
  HomeImprovementDefinition(
    id: 'living_grandfather_bedding',
    room: HomeImprovementRoom.livingRoom,
    stage: 1,
    title: '외할아버지 겨울 이불',
    subtitle: '묵을 때마다 접어 쓰던 얇은 담요를 따뜻한 이불로 바꿉니다.',
    cost: 50000,
    familyMember: HomeFamilyMember.grandfather,
    familyTrustDelta: 1,
    householdStabilityDelta: 4,
    affinityDelta: 5,
    storyEventId: 'HOME_GRANDFATHER_BEDDING',
    storyTitle: '장부 밖의 오만 원',
    storyLines: [
      HomeStoryLine(text: '외할아버지는 새 이불을 한 번 눌러 보고는 가격표부터 찾았다.'),
      HomeStoryLine(speaker: '외할아버지', text: '얼마 줬냐?'),
      HomeStoryLine(speaker: '주인공', text: '오만 원이요. 제 돈으로요.'),
      HomeStoryLine(speaker: '외할아버지', text: '그래서, 남은 돈은?'),
      HomeStoryLine(speaker: '주인공', text: '그 질문 하실 줄 알고 장부 가져왔죠.'),
      HomeStoryLine(text: '외할아버지는 장부보다 먼저 이불 한쪽을 주인공 무릎 위에 덮어 주었다.'),
      HomeStoryLine(speaker: '외할아버지', text: '됐어. 오늘은 숫자 말고 발부터 녹여.'),
    ],
  ),
  HomeImprovementDefinition(
    id: 'living_mother_floor',
    room: HomeImprovementRoom.livingRoom,
    stage: 2,
    title: '거실 장판과 커튼',
    subtitle: '들뜬 장판을 고치고 찬바람이 새는 창에 두꺼운 커튼을 답니다.',
    cost: 180000,
    familyMember: HomeFamilyMember.mother,
    familyTrustDelta: 2,
    householdStabilityDelta: 8,
    affinityDelta: 6,
    storyEventId: 'HOME_MOTHER_FLOOR',
    storyTitle: '양말이 걸리지 않는 아침',
    prerequisiteId: 'living_grandfather_bedding',
    storyLines: [
      HomeStoryLine(text: '매일 발끝을 걸던 장판 틈이 사라졌다. 어머니는 괜히 같은 자리를 두 번 오갔다.'),
      HomeStoryLine(speaker: '어머니', text: '이런 데 돈 쓰지 말랬지.'),
      HomeStoryLine(speaker: '주인공', text: '엄마 양말 또 찢어지면 그게 더 비싸.'),
      HomeStoryLine(speaker: '어머니', text: '말은 아주 장사꾼이네.'),
      HomeStoryLine(text: '어머니는 새 커튼을 끝까지 당겨 보고, 남은 천 조각은 조용히 바느질 상자에 넣었다.'),
      HomeStoryLine(speaker: '어머니', text: '다음부터는 사기 전에 말해. 같이 깎게.'),
    ],
  ),
  HomeImprovementDefinition(
    id: 'kitchen_mother_rice',
    room: HomeImprovementRoom.kitchen,
    stage: 1,
    title: '쌀통과 반찬 선반 채우기',
    subtitle: '비어 가던 쌀통을 채우고 부엌 살림을 정돈합니다.',
    cost: 25000,
    familyMember: HomeFamilyMember.mother,
    familyTrustDelta: 2,
    householdStabilityDelta: 5,
    affinityDelta: 4,
    storyEventId: 'HOME_MOTHER_RICE',
    storyTitle: '쌀을 안 흔들어 본 저녁',
    storyLines: [
      HomeStoryLine(text: '어머니는 밥을 안치기 전에 쌀통을 흔들어 보곤 했다. 그날은 뚜껑만 열었다가 손을 멈췄다.'),
      HomeStoryLine(speaker: '어머니', text: '이거 네가 채웠어?'),
      HomeStoryLine(speaker: '주인공', text: '응. 근데 수익률은 밥 두 그릇으로 받을게.'),
      HomeStoryLine(speaker: '어머니', text: '세 그릇 먹어. 설거지도 하고.'),
      HomeStoryLine(speaker: '누나', text: '투자 조건이 너무 불리한데?'),
      HomeStoryLine(speaker: '주인공', text: '누나는 반찬값부터 내.'),
      HomeStoryLine(text: '좁은 부엌에서 세 사람이 동시에 웃었다.'),
    ],
  ),
  HomeImprovementDefinition(
    id: 'kitchen_family_fridge',
    room: HomeImprovementRoom.kitchen,
    stage: 2,
    title: '조용한 중고 냉장고',
    subtitle: '밤마다 덜컹거리던 냉장고를 검수한 중고 제품으로 바꿉니다.',
    cost: 220000,
    familyMember: HomeFamilyMember.family,
    familyTrustDelta: 3,
    householdStabilityDelta: 10,
    affinityDelta: 2,
    storyEventId: 'HOME_FAMILY_FRIDGE',
    storyTitle: '냉장고가 조용해진 밤',
    prerequisiteId: 'kitchen_mother_rice',
    storyLines: [
      HomeStoryLine(text: '새 냉장고가 들어온 첫날 밤, 가족은 부엌 앞에 서서 한동안 아무 말도 하지 않았다.'),
      HomeStoryLine(speaker: '누나', text: '고장 난 거 아니야? 왜 이렇게 조용해?'),
      HomeStoryLine(speaker: '아버지', text: '원래 냉장고는 안 떠는 게 정상이야.'),
      HomeStoryLine(speaker: '주인공', text: '내가 모터 소리까지 확인했어.'),
      HomeStoryLine(speaker: '어머니', text: '그래도 영수증은 내가 갖고 있을게.'),
      HomeStoryLine(text: '아버지가 문 수평을 다시 맞추는 동안, 누나는 예전 냉장고 자석을 새 문에 하나씩 옮겼다.'),
      HomeStoryLine(speaker: '누나', text: '이제 우리 집도 밤에 안 걸어 다니네.'),
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
      totalSpent: ((json['totalSpent'] as num?)?.toInt() ?? catalogSpent)
          .clamp(catalogSpent, 0x7fffffff)
          .toInt(),
    );
  }
}
