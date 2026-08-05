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
    id: 'newspaper_delivery',
    title: '새벽 신문배달',
    subtitle: '좌우 주행 · 방향 플릭 · 정확도 콤보',
    periodPay: '배달 점수에 따라 900~2,500원 + 실기 특성 수당',
    description:
        '겨울 새벽 주택가를 자전거로 돌며 우편함 방향으로 신문을 직접 플릭합니다. 투척 방향·세기·타이밍과 연속 배달이 수당을 결정합니다.',
  ),
];
