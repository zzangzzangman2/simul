import 'game_state.dart';

const weekendActionPointsPerDay = 2;
const weekendActivityLogFlag = 'weekendActivityLog';
const weekendMarketResearchCreditsFlag = 'weekendMarketResearchCredits';

const weekendNeighborhoodAsset =
    'assets/images/cinematic_soft_painted/decimal_weekend/bg_weekend_neighborhood_winter_2000_v1.png';
const weekendRestaurantAsset =
    'assets/images/cinematic_soft_painted/decimal_weekend/bg_weekend_restaurant_kitchen_2000_v1.png';
const weekendGiftShopAsset =
    'assets/images/cinematic_soft_painted/decimal_weekend/bg_weekend_stationery_gift_shop_2000_v1.png';
const weekendLibraryAsset =
    'assets/images/cinematic_soft_painted/decimal_weekend/bg_weekend_public_library_2000_v1.png';

enum WeekendActivityKind { partTimeJob, gift, marketStudy, rest }

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
  });

  final String id;
  final String workActivityId;
  final String title;
  final String location;
  final String description;
  final String payHint;
  final String imageAsset;
  final int accentValue;
}

const weekendJobs = <WeekendJobDefinition>[
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
    required this.description,
    required this.cost,
    required this.preferredGirlIds,
  });

  final String id;
  final String title;
  final String description;
  final int cost;
  final Set<String> preferredGirlIds;

  int affectionFor(String girlId) => preferredGirlIds.contains(girlId) ? 4 : 2;
  int trustFor(String girlId) => preferredGirlIds.contains(girlId) ? 2 : 1;
}

const weekendGifts = <WeekendGiftDefinition>[
  WeekendGiftDefinition(
    id: 'sturdy_notebook',
    title: '튼튼한 미니 수첩',
    description: '약속과 숫자를 오래 남길 수 있는 작은 수첩.',
    cost: 1200,
    preferredGirlIds: <String>{'kim_seoa', 'jung_arin', 'yoon_chaea'},
  ),
  WeekendGiftDefinition(
    id: 'repair_parts_tin',
    title: '작은 부품 틴케이스',
    description: '나사와 단자를 나눠 담는 실용적인 금속 상자.',
    cost: 1800,
    preferredGirlIds: <String>{'lee_jian', 'oh_jiwoo'},
  ),
  WeekendGiftDefinition(
    id: 'fabric_charm',
    title: '천 조각 행운 매듭',
    description: '손으로 만져지는 질감이 좋은 소박한 장식.',
    cost: 1500,
    preferredGirlIds: <String>{'choi_iseo', 'park_haeun'},
  ),
  WeekendGiftDefinition(
    id: 'winter_snack_box',
    title: '겨울 간식 작은 상자',
    description: '같이 나눠 먹기 좋은 사탕과 과자 묶음.',
    cost: 900,
    preferredGirlIds: <String>{'han_sua', 'park_haeun', 'oh_jiwoo'},
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
  });

  final String activityId;
  final String? girlId;
  final String? giftId;
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

bool weekendGiftAlreadyGivenTo(GameState state, String girlId) =>
    weekendActivityLogsForDay(state, state.day).any(
      (log) => log.kind == WeekendActivityKind.gift && log.girlId == girlId,
    );

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
