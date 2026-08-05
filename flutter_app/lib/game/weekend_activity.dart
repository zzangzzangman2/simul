import 'game_state.dart';
import 'horse_racing.dart';

const weekendActionPointsPerDay = 2;
const weekendActivityLogFlag = 'weekendActivityLog';
const weekendMarketResearchCreditsFlag = 'weekendMarketResearchCredits';
const weekendActivityHistoryLimit = 730;

const weekendNeighborhoodAsset =
    'assets/images/cinematic_soft_painted/decimal_weekend/bg_weekend_neighborhood_winter_2000_v1.png';
const weekendRestaurantAsset =
    'assets/images/cinematic_soft_painted/decimal_weekend/bg_weekend_restaurant_kitchen_2000_v1.png';
const weekendGiftShopAsset =
    'assets/images/kbeauty_gifts/bg_miraon_beauty_store_v1.png';
const weekendLibraryAsset =
    'assets/images/cinematic_soft_painted/decimal_weekend/bg_weekend_public_library_2000_v1.png';
const weekendNewspaperDeliveryAsset =
    'assets/images/minigames/bg_newspaper_delivery_dawn_seoul_2000_v1.png';

enum WeekendActivityKind { partTimeJob, gift, marketStudy, entertainment, rest }

class WeekendJobDefinition {
  const WeekendJobDefinition({
    required this.id,
    required this.workActivityId,
    required this.title,
    required this.location,
    required this.description,
    required this.payHint,
    required this.imageAsset,
    required this.accentValue,
    this.requiresMiniGame = false,
  });

  final String id;
  final String workActivityId;
  final String title;
  final String location;
  final String description;
  final String payHint;
  final String imageAsset;
  final int accentValue;
  final bool requiresMiniGame;
}

const weekendJobs = <WeekendJobDefinition>[
  WeekendJobDefinition(
    id: 'newspaper_delivery',
    workActivityId: 'newspaper_delivery',
    title: '새벽 신문배달',
    location: '강남 겨울 주택가',
    description: '자전거로 골목을 돌며 정해진 집에 조간신문을 던진다. 정확도와 연속 배달만큼 수당이 오른다.',
    payHint: '성과에 따라 약 900~2,500원',
    imageAsset: weekendNewspaperDeliveryAsset,
    accentValue: 0xFF5B78A6,
    requiresMiniGame: true,
  ),
  WeekendJobDefinition(
    id: 'restaurant_dishes',
    workActivityId: 'dishes',
    title: '식당 설거지 알바',
    location: '센터 협력 식당',
    description: '그릇을 분류하고 점심 장사 전 주방을 정리한다. 수입은 작지만 가장 안정적이다.',
    payHint: '약 1,000~1,300원',
    imageAsset: weekendRestaurantAsset,
    accentValue: 0xFFEF8A62,
  ),
  WeekendJobDefinition(
    id: 'stationery_stock',
    workActivityId: 'stationery',
    title: '문구 창고 정리',
    location: '동네 문구점 창고',
    description: '공책과 필기구를 품목별로 세고 진열할 상자를 만든다. 꼼꼼할수록 수당이 오른다.',
    payHint: '약 1,300~1,500원',
    imageAsset: weekendGiftShopAsset,
    accentValue: 0xFFE77F96,
  ),
  WeekendJobDefinition(
    id: 'flea_market_helper',
    workActivityId: 'flea_market',
    title: '교환장터 판매 보조',
    location: '주말 생활 교환장터',
    description: '가격표 없는 물건의 상태를 설명하고 잔돈을 맞춘다. 성과 폭이 가장 크다.',
    payHint: '약 1,700~2,200원',
    imageAsset: weekendNeighborhoodAsset,
    accentValue: 0xFF5EAF91,
  ),
];

WeekendJobDefinition? weekendJobById(String id) {
  for (final job in weekendJobs) {
    if (job.id == id) return job;
  }
  return null;
}

class WeekendGiftDefinition {
  const WeekendGiftDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.cost,
    required this.imageAsset,
    required this.favoriteGirlId,
    required this.preferenceReason,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final int cost;
  final String imageAsset;
  final String favoriteGirlId;
  final String preferenceReason;

  bool isFavoriteFor(String girlId) => favoriteGirlId == girlId;

  int affectionFor(String girlId, {required int monthlyRepeatCount}) {
    final favorite = isFavoriteFor(girlId);
    if (favorite) {
      return switch (monthlyRepeatCount) {
        0 => 6,
        1 => 3,
        2 => 1,
        _ => 0,
      };
    }
    return switch (monthlyRepeatCount) {
      0 => 2,
      1 => 1,
      _ => 0,
    };
  }

  int trustFor(String girlId, {required int monthlyRepeatCount}) {
    if (monthlyRepeatCount >= 2) return 0;
    if (isFavoriteFor(girlId)) return monthlyRepeatCount == 0 ? 2 : 1;
    return monthlyRepeatCount == 0 ? 1 : 0;
  }
}

const weekendGifts = <WeekendGiftDefinition>[
  WeekendGiftDefinition(
    id: 'barrier_hand_cream',
    title: '온결 장벽 핸드크림',
    category: '보습 · 핸드케어',
    description: '향이 세지 않고 오래 촉촉한 선물용 보습 크림.',
    cost: 3400,
    imageAsset: 'assets/images/kbeauty_gifts/gift_barrier_hand_cream_v1.png',
    favoriteGirlId: 'kim_seoa',
    preferenceReason: '사람을 배려하는 은은한 향과 매일 챙겨 쓰기 좋은 실용성',
  ),
  WeekendGiftDefinition(
    id: 'daily_sun_stick',
    title: '바로쓱 데일리 선스틱',
    category: '선케어 · 기능성',
    description: '손에 묻지 않고 빠르게 바르는 보송한 휴대용 선스틱.',
    cost: 4200,
    imageAsset: 'assets/images/kbeauty_gifts/gift_daily_sun_stick_v1.png',
    favoriteGirlId: 'lee_jian',
    preferenceReason: '설명보다 바로 써 보고 효용을 확인할 수 있는 간결한 도구성',
  ),
  WeekendGiftDefinition(
    id: 'velvet_tint_duo',
    title: '결빛 벨벳 틴트 듀오',
    category: '메이크업 · 립',
    description: '말린 장미와 브릭 코랄의 미묘한 색 차이를 담은 두 색 세트.',
    cost: 6900,
    imageAsset: 'assets/images/kbeauty_gifts/gift_velvet_tint_duo_v1.png',
    favoriteGirlId: 'choi_iseo',
    preferenceReason: '유행보다 직접 보고 고를 수 있는 섬세한 색감과 질감',
  ),
  WeekendGiftDefinition(
    id: 'travel_skin_kit',
    title: '세칸 루틴 트래블 키트',
    category: '스킨케어 · 세트',
    description: '세안·토너·보습을 순서대로 정리한 파우치 세트.',
    cost: 7800,
    imageAsset: 'assets/images/kbeauty_gifts/gift_travel_skin_kit_v1.png',
    favoriteGirlId: 'jung_arin',
    preferenceReason: '정해진 순서로 빠르게 끝낼 수 있는 명확한 구성과 휴대성',
  ),
  WeekendGiftDefinition(
    id: 'soothing_mask_set',
    title: '같이쉼 진정 마스크 세트',
    category: '마스크 · 기프트',
    description: '친구와 나눠 쓰기 좋은 순한 진정 마스크와 헤어밴드.',
    cost: 5200,
    imageAsset: 'assets/images/kbeauty_gifts/gift_soothing_mask_set_v1.png',
    favoriteGirlId: 'park_haeun',
    preferenceReason: '혼자보다 함께 쉬는 시간을 자연스럽게 만들어 주는 구성',
  ),
  WeekendGiftDefinition(
    id: 'fruity_glow_balm',
    title: '과즙톡 글로우 밤 트리오',
    category: '메이크업 · 멀티밤',
    description: '복숭아·베리·펄을 기분에 따라 바꿔 쓰는 발랄한 세트.',
    cost: 6300,
    imageAsset: 'assets/images/kbeauty_gifts/gift_fruity_glow_balm_v1.png',
    favoriteGirlId: 'han_sua',
    preferenceReason: '친구들과 색을 바꿔 보며 새 사용법을 떠올릴 수 있는 재미',
  ),
  WeekendGiftDefinition(
    id: 'color_shift_balm',
    title: '반전빛 컬러 시프트 밤',
    category: '메이크업 · 실험 키트',
    description: '바르는 사람마다 다른 색이 올라오는 테스트 카드 포함 투명 밤.',
    cost: 7200,
    imageAsset: 'assets/images/kbeauty_gifts/gift_color_shift_balm_v1.png',
    favoriteGirlId: 'oh_jiwoo',
    preferenceReason: '결과를 예상하고 반례까지 직접 시험해 볼 수 있는 작은 실험성',
  ),
  WeekendGiftDefinition(
    id: 'ingredient_serum',
    title: '한줄성분 카밍 세럼',
    category: '스킨케어 · 세럼',
    description: '핵심 성분과 사용 순서를 간결하게 정리한 저자극 세럼 세트.',
    cost: 8900,
    imageAsset: 'assets/images/kbeauty_gifts/gift_ingredient_serum_v1.png',
    favoriteGirlId: 'yoon_chaea',
    preferenceReason: '과장보다 성분 구조와 반복 사용 기준을 확인할 수 있는 정보성',
  ),
];

WeekendGiftDefinition? weekendGiftById(String id) {
  for (final gift in weekendGifts) {
    if (gift.id == id) return gift;
  }
  return null;
}

class WeekendActivityRequest {
  const WeekendActivityRequest({
    required this.activityId,
    this.girlId,
    this.giftId,
    this.workScore,
    this.workMaxScore,
    this.horseRaceResult,
  });

  final String activityId;
  final String? girlId;
  final String? giftId;
  final int? workScore;
  final int? workMaxScore;
  final HorseRaceSessionResult? horseRaceResult;
}

class WeekendActivityLog {
  const WeekendActivityLog({
    required this.day,
    required this.kind,
    required this.activityId,
    required this.title,
    required this.body,
    required this.markerLabel,
    required this.accentValue,
    required this.imageAsset,
    this.actionPointCost = 1,
    this.cashDelta = 0,
    this.girlId,
    this.affectionDelta = 0,
  });

  final int day;
  final WeekendActivityKind kind;
  final String activityId;
  final String title;
  final String body;
  final String markerLabel;
  final int accentValue;
  final String imageAsset;
  final int actionPointCost;
  final int cashDelta;
  final String? girlId;
  final int affectionDelta;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'day': day,
    'kind': kind.name,
    'activityId': activityId,
    'title': title,
    'body': body,
    'markerLabel': markerLabel,
    'accentValue': accentValue,
    'imageAsset': imageAsset,
    'actionPointCost': actionPointCost,
    'cashDelta': cashDelta,
    if (girlId != null) 'girlId': girlId,
    'affectionDelta': affectionDelta,
  };

  factory WeekendActivityLog.fromJson(Map<String, dynamic> json) {
    final kind = WeekendActivityKind.values.firstWhere(
      (value) => value.name == json['kind'],
      orElse: () => WeekendActivityKind.rest,
    );
    return WeekendActivityLog(
      day: ((json['day'] as num?)?.toInt() ?? 0).clamp(0, 0x7fffffff),
      kind: kind,
      activityId: json['activityId'] as String? ?? '',
      title: json['title'] as String? ?? '주말 생활 기록',
      body: json['body'] as String? ?? '',
      markerLabel: json['markerLabel'] as String? ?? '주말',
      accentValue: (json['accentValue'] as num?)?.toInt() ?? 0xFFFF7E73,
      imageAsset: json['imageAsset'] as String? ?? weekendNeighborhoodAsset,
      actionPointCost: ((json['actionPointCost'] as num?)?.toInt() ?? 1).clamp(
        1,
        weekendActionPointsPerDay,
      ),
      cashDelta: (json['cashDelta'] as num?)?.toInt() ?? 0,
      girlId: json['girlId'] as String?,
      affectionDelta: (json['affectionDelta'] as num?)?.toInt() ?? 0,
    );
  }
}

class WeekendActivityResult {
  const WeekendActivityResult({
    required this.state,
    required this.success,
    required this.message,
    this.cashDelta = 0,
    this.affectionDelta = 0,
  });

  final GameState state;
  final bool success;
  final String message;
  final int cashDelta;
  final int affectionDelta;
}

List<WeekendActivityLog> weekendActivityLogsForState(GameState state) =>
    ((state.story.storyFlags[weekendActivityLogFlag] as List?) ??
            const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) => WeekendActivityLog.fromJson(item.cast<String, dynamic>()),
        )
        .where((log) => log.day > 0)
        .toList(growable: false);

List<WeekendActivityLog> weekendActivityLogsForDay(GameState state, int day) =>
    weekendActivityLogsForState(
      state,
    ).where((log) => log.day == day).toList(growable: false);

int weekendActivityPointsUsed(GameState state) => weekendActivityLogsForDay(
  state,
  state.day,
).fold<int>(0, (sum, log) => sum + log.actionPointCost);

int weekendActivityPointsRemaining(GameState state) =>
    (weekendActionPointsPerDay - weekendActivityPointsUsed(state)).clamp(
      0,
      weekendActionPointsPerDay,
    );

bool weekendScheduleCompleteForState(GameState state) =>
    weekendActivityPointsRemaining(state) == 0;

bool horseRaceAlreadyPlayedToday(GameState state) => weekendActivityLogsForDay(
  state,
  state.day,
).any((log) => log.activityId == 'horse_racing');

bool kBeautyGiftAlreadyGivenToday(GameState state) {
  if (state.relationships.memories.any(
    (memory) => memory.day == state.day && memory.activity.name == 'gift',
  )) {
    return true;
  }
  return weekendActivityLogsForDay(
    state,
    state.day,
  ).any((log) => log.kind == WeekendActivityKind.gift);
}

int kBeautyGiftMonthlyRepeatCount(
  GameState state, {
  required String girlId,
  required String giftId,
}) {
  final current = state.currentDate;
  return state.relationships.memories.where((memory) {
    if (memory.activity.name != 'gift' ||
        memory.girlId != girlId ||
        memory.choiceId != giftId) {
      return false;
    }
    final date = state.dateForDay(memory.day);
    return date.year == current.year && date.month == current.month;
  }).length;
}

String kBeautyGiftRepeatLabel(int count) => switch (count) {
  0 => '이번 달 첫 선물 · 효과 100%',
  1 => '같은 상품 두 번째 · 호감 효과 감소',
  2 => '같은 상품 세 번째 · 호감 효과 크게 감소',
  _ => '같은 상품 반복 · 이번 달 호감 효과 없음',
};

int kBeautyGiftRelationshipTier(GameState state, String girlId) {
  final affection = state.relationships.progressFor(girlId).affection;
  var tier = switch (affection) {
    >= 80 => 4,
    >= 60 => 3,
    >= 40 => 2,
    >= 20 => 1,
    _ => 0,
  };
  final recentRelationship = state.relationships.memories.reversed
      .where((memory) => memory.girlId == girlId)
      .firstOrNull;
  final recentPhone = state.phoneMessenger.memories.reversed
      .where((memory) => memory.contactId == girlId)
      .firstOrNull;
  final relationshipTense =
      recentRelationship != null &&
      state.day - recentRelationship.day <= 14 &&
      recentRelationship.affectionDelta < 0;
  final phoneTense =
      recentPhone != null &&
      state.day - recentPhone.day <= 14 &&
      recentPhone.affectionDelta < 0;
  if (relationshipTense || phoneTense) tier = (tier - 1).clamp(0, 4);
  return tier;
}

const _favoriteGiftReplies = <String, List<String>>{
  'kim_seoa': <String>[
    '“고마워. 아직 조금 어색하긴 한데… 향이 세지 않은 걸로 골라 줬네.” 서아가 포장지를 접어 둔다.',
    '“내가 이런 순한 향 좋아하는 거 기억했어?” 서아가 손등에 아주 조금 발라 본다.',
    '“다 쓰는 날짜도 적어 둘래. 다음에 좋았는지 제대로 말해 줄게.” 서아가 작게 웃는다.',
    '“손 트는 것까지 봤구나. 네가 챙겨 주니까 좀 간질간질하다.”',
    '“이건 아껴 두지 않고 매일 쓸게. 네가 준 거라는 것도 같이 기억할 거고.”',
  ],
  'lee_jian': <String>[
    '“고마워. 말은 나중에 하고, 일단 발림부터 확인해 볼게.” 지안이 뚜껑을 살핀다.',
    '“손 안 묻는 거네. 이런 건 실제로 편하면 오래 써.”',
    '“끈적이지 않으면 합격. 네가 고른 기준은 꽤 괜찮다.”',
    '“다 쓰면 케이스 구조도 볼래. 같이 시험해 보면 금방 알겠지.”',
    '“내가 귀찮아하는 지점을 정확히 골랐네. 이건 진짜 자주 쓸 것 같아.”',
  ],
  'choi_iseo': <String>[
    '“고마워. 지금은 조심스럽지만… 두 색이 아주 조금 다른 건 마음에 들어.”',
    '“유행색 하나가 아니라 비교해 보라고 두 개를 골랐네.” 이서가 빛에 비춰 본다.',
    '“나는 말린 장미 쪽. 너는 뭐가 더 편해 보여?” 이서가 색표를 네 쪽으로 돌린다.',
    '“내 취향을 대신 정하지 않고 고를 틈까지 줘서 좋아.”',
    '“이 색을 보면 오늘 같이 고른 순간부터 떠오를 것 같아.” 이서가 조심히 웃는다.',
  ],
  'jung_arin': <String>[
    '“고마워. 우리 사이가 좀 어색해도 물건 구성은 확실하네.” 아린이 세 병을 순서대로 세운다.',
    '“세 단계면 끝이네. 헷갈릴 일 없어서 마음에 들어.”',
    '“여행 아니어도 아침 준비 시간 줄이겠는데? 잘 골랐어.”',
    '“내가 시간 아끼는 거 좋아하는 것까지 계산했지? 인정.”',
    '“다음 외출 때 이 파우치 들고 갈게. 준비는 내가 정확히 해 둘 테니까.”',
  ],
  'park_haeun': <String>[
    '“고마워. 지금 당장 다 괜찮은 척은 못 해도, 마음은 받을게.” 하은이 봉투를 품에 안는다.',
    '“혼자 쓰라고 한 장이 아니라 같이 나누라고 여러 장이네.”',
    '“오늘 힘들었던 애한테 한 장 건네도 될까? 네 마음도 같이 전할게.”',
    '“나 챙기라고 준 건데 또 나눌 생각부터 했네. 한 장은 꼭 내가 쓸게.”',
    '“우리 둘 다 쉬는 날 하나 잡자. 그때 이거 같이 쓰면 좋겠다.”',
  ],
  'han_sua': <String>[
    '“고마워. 아직 텐션 올리긴 좀 그렇지만… 색 세 개는 솔직히 궁금해.”',
    '“잠깐, 투명한 것도 반짝여? 하나씩 발라 보면 조합 엄청 나오겠다.”',
    '“이거 우리끼리 색 바꿔 쓰면 재밌겠다. 아, 내 건 복숭아 먼저!”',
    '“나 좋아할 것 같은 걸 너무 정확히 골랐잖아. 좀 설렌다, 진짜.”',
    '“다음에 같이 바르고 사진 말고 서로 표정으로 점수 매기자. 그게 더 재밌어.”',
  ],
  'oh_jiwoo': <String>[
    '“선물 수신. 아직 방송 재개는 천천히 할 건데, 색 변하는 원리는 궁금하네.”',
    '“속보. 바르는 사람마다 다르다는 주장 입수. 검증이 필요합니다.”',
    '“테스트 카드가 세 장이면 반례도 세 번 찾을 수 있겠네. 같이 해 볼래?”',
    '“내가 이런 이상한 실험 좋아하는 거 읽혔네. 정정, 이상한 게 아니라 흥미로운 거.”',
    '“오늘의 결론. 색은 변했고, 네가 나를 보는 기준은 꽤 정확했다.”',
  ],
  'yoon_chaea': <String>[
    '“고마워. 지금은 반응을 크게 하긴 어렵지만, 성분표가 단순한 건 좋네.”',
    '“광고 문구보다 비교 카드가 먼저 들어 있네. 고른 기준은 알겠어.”',
    '“일주일 써 보고 변화가 있는지 적어 볼게. 결과도 네게 말해 줄 거고.”',
    '“내가 과장된 포장보다 구조를 보는 걸 기억했구나.” 채아가 상자를 다시 살핀다.',
    '“다음 달에도 쓰고 있으면 좋은 선물이었다는 뜻이겠지. 아마 그럴 것 같아.”',
  ],
};

const _neutralGiftReplies = <String, String>{
  'kim_seoa': '“고마워. 내가 자주 쓰는 종류인지는 한번 천천히 봐도 되지?”',
  'lee_jian': '“일단 받아 둘게. 실제로 편한지는 써 보면 알겠지.”',
  'choi_iseo': '“고마워. 내 취향이랑 맞는지는 내가 직접 보고 정할게.”',
  'jung_arin': '“고마워. 필요한 순간이 생기면 바로 써 볼게.”',
  'park_haeun': '“마음 써 준 건 고마워. 잘 맞는 친구가 있으면 같이 써도 될까?”',
  'han_sua': '“오, 이건 예상 밖이다. 일단 한번 써 보고 얘기해 줄게.”',
  'oh_jiwoo': '“예상 밖 선물 접수. 쓸모가 있는지 검증 방송 들어갑니다.”',
  'yoon_chaea': '“고마워. 고른 이유를 나중에 한 번만 말해 줘.”',
};

const _repeatGiftReplies = <String, String>{
  'kim_seoa': '“같은 거 또 골랐네. 고맙지만 다음엔 내가 다른 취향도 말해 줄게.”',
  'lee_jian': '“이건 아직 남아 있어. 다음엔 다른 기능을 시험해 보는 게 낫겠다.”',
  'choi_iseo': '“같은 색만 계속 받으면 고르는 재미가 없잖아. 다음엔 같이 보자.”',
  'jung_arin': '“재고가 겹쳤어. 다음부터는 주기 전에 한 번 확인.”',
  'park_haeun': '“고마운 마음은 같아. 그래도 다음엔 네 돈도 아끼고 다른 걸 골라 보자.”',
  'han_sua': '“이거 좋아하긴 하는데 또 같은 거야? 다음엔 새 조합 발굴하자.”',
  'oh_jiwoo': '“재방송 확인. 같은 가설만 반복하면 새 결론은 안 나오지.”',
  'yoon_chaea': '“사용분이 아직 남았어. 같은 입력을 반복한다고 정보가 늘진 않아.”',
};

String kBeautyGiftReaction(
  GameState state, {
  required WeekendGiftDefinition gift,
  required String girlId,
  required int monthlyRepeatCount,
}) {
  if (monthlyRepeatCount >= 1) {
    return _repeatGiftReplies[girlId] ?? '“고마워. 다음에는 다른 것도 골라 보자.”';
  }
  if (!gift.isFavoriteFor(girlId)) {
    return _neutralGiftReplies[girlId] ?? '“고마워. 잘 써 볼게.”';
  }
  final replies = _favoriteGiftReplies[girlId];
  if (replies == null || replies.isEmpty) return '“고마워. 내 취향을 기억했네.”';
  return replies[kBeautyGiftRelationshipTier(state, girlId).clamp(0, 4)];
}

const _favoritePhoneGiftReplies = <String, String>{
  'kim_seoa': '이거 향 세지 않은 거지? 내가 그런 거 신경 쓰는 거 기억했네. 고마워. 다 쓰면 어땠는지도 말해 줄게.',
  'lee_jian': '손 안 묻는 거네. 바로 써 봐도 돼? 이런 건 진짜 편해야 오래 쓰거든. 고마워.',
  'choi_iseo': '두 색이 비슷해 보여도 느낌은 다르네. 나는 장미 쪽부터 써 볼래. 내 취향 물어봐 줘서 고마워.',
  'jung_arin': '세 단계면 끝이네. 순서도 확실하고. 내가 준비 시간 줄이는 거 좋아하는 것까지 봤지? 고마워.',
  'park_haeun': '여러 장이라 같이 쓸 수 있겠다. 근데 한 장은 꼭 내가 쓸게. 나 챙기라고 준 거잖아. 고마워 :)',
  'han_sua': '잠깐 색 세 개 다 다른 거야? ㅋㅋ 복숭아부터 써 보고 조합 찾아볼래. 완전 내 취향이야, 고마워!',
  'oh_jiwoo': '속보. 바르는 사람마다 색이 다르다는 물건 입수. 이건 검증이 필요합니다. 같이 테스트할 패널 하실?',
  'yoon_chaea': '성분 카드가 먼저 보이네. 일주일 써 보고 변화가 있는지 적어 볼게. 과장 없는 걸로 골라 줘서 고마워.',
};

String kBeautyGiftPhoneReaction(
  GameState state, {
  required WeekendGiftDefinition gift,
  required String girlId,
  required int monthlyRepeatCount,
}) {
  if (monthlyRepeatCount >= 1) {
    return (_repeatGiftReplies[girlId] ?? '같은 선물도 고맙지만 다음에는 다른 걸 골라 보자.')
        .replaceAll('“', '')
        .replaceAll('”', '');
  }
  if (!gift.isFavoriteFor(girlId)) {
    return (_neutralGiftReplies[girlId] ?? '고마워. 잘 써 볼게.')
        .replaceAll('“', '')
        .replaceAll('”', '');
  }
  final favorite = _favoritePhoneGiftReplies[girlId] ?? '내 취향 기억했네. 고마워.';
  if (kBeautyGiftRelationshipTier(state, girlId) == 0) {
    return '고마워. 아직 조금 어색하긴 한데, $favorite';
  }
  return favorite;
}

String kBeautyClerkPriceLine(WeekendGiftDefinition gift) =>
    '“${gift.title}은 ${gift.cost}원입니다. 선물용으로 포장해 드릴까요?”';

const kBeautyClerkWelcomeLine = '“어서 오세요. 미라온 뷰티입니다. 천천히 둘러보세요.”';
const kBeautyClerkCheckoutLine = '“고르신 상품 계산해 드릴까요?”';
const kBeautyClerkWrapLine = '“리본 색도 골라 주세요. 선물용으로 정성껏 포장해 드릴게요.”';
const kBeautyClerkThanksLine = '“계산되었습니다. 감사합니다. 조심히 들어가세요.”';

String weekendActivityRecommendation(GameState state) {
  if (state.needsTradingRecovery) {
    return '실전 주문 가능금이 부족해. 주말 알바 수당을 증권계좌에 바로 넣어 재기할 수 있어.';
  }
  if (state.bankCash < 1200) return '현금이 부족해. 주말 알바로 생활비부터 만들 수 있어.';
  if ((state.story.storyFlags[weekendMarketResearchCreditsFlag] as num?)
          ?.toInt() ==
      0) {
    return '다음 거래일을 준비하려면 도서관에서 조사권을 만들어 두는 것도 좋아.';
  }
  return '수입·관계·시장 준비 중 지금 필요한 한 가지를 고르면 돼.';
}
