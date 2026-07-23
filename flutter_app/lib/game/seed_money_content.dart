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
    title: '설거지 러시 V2',
    subtitle: '물 묻히기 → 얼룩 닦기 → 헹구기',
    periodPay: '기본 500~1,300원 + 특성 수당',
    description: '그릇마다 남은 얼룩을 직접 문질러 닦습니다. 실수 없이 이어가면 콤보 보너스를 받습니다.',
  ),
  WorkActivityInfo(
    id: 'stationery',
    title: '문방구 주문 포장 V2',
    subtitle: '손님 메모대로 물건과 수량 맞추기',
    periodPay: '기본 800~1,500원 + 특성 수당',
    description: '진열대에서 물건을 골라 주문 꾸러미를 만듭니다. 정확하게 연속 포장하면 수당이 올라갑니다.',
  ),
  WorkActivityInfo(
    id: 'flea_market',
    title: '동네 벼룩장터 V2',
    subtitle: '가격 흥정부터 거스름돈까지 직접',
    periodPay: '기본 700~2,200원 + 특성 수당',
    description: '손님과 적정 가격을 흥정하고 지폐를 직접 골라 정확한 거스름돈을 건넵니다.',
  ),
];
