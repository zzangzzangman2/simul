class WorkSessionResult {
  const WorkSessionResult({
    required this.activityId,
    required this.score,
    required this.maxScore,
  });

  final String activityId;
  final int score;
  final int maxScore;
}

class WorkActivityInfo {
  const WorkActivityInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.periodPay,
    required this.description,
  });

  final String id;
  final String title;
  final String subtitle;
  final String periodPay;
  final String description;
}

const workActivities = <WorkActivityInfo>[
  WorkActivityInfo(
    id: 'dishes',
    title: '저녁 설거지',
    subtitle: '헹구기 → 닦기 → 마무리',
    periodPay: '용돈 300~800원',
    description: '순서를 기억해 그릇을 깨끗하게 닦습니다. 실수 없이 이어가면 정리 보너스를 받습니다.',
  ),
  WorkActivityInfo(
    id: 'stationery',
    title: '문방구 재고 정리',
    subtitle: '학용품·간식·완구를 제자리에',
    periodPay: '30분 작업 800원 + 정확도 수당',
    description: '엄마와 함께 새 물건을 분류합니다. 이동과 정리를 포함해 게임 시간은 60분이 흐릅니다.',
  ),
  WorkActivityInfo(
    id: 'flea_market',
    title: '가족 벼룩장터',
    subtitle: '중고책을 팔고 거스름돈 계산',
    periodPay: '판매 몫 600~1,600원',
    description: '가족이 내놓은 중고책과 장난감을 팔며 정확한 거스름돈을 계산합니다.',
  ),
];
