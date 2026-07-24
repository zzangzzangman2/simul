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
    id: 'rider',
    title: '잼민 라이더',
    subtitle: '슬라이드 회피 · 크리티컬 콤보 · 완주 상금',
    periodPay: '완주 점수에 따라 700~2,200원 + 특성 수당',
    description:
        '동네 축제의 폐쇄된 킥보드 코스를 달립니다. 장애물을 아슬아슬하게 피하고 배달 지점을 모두 통과해야 상금을 받습니다.',
  ),
];
