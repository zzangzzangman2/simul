class SkillDefinition {
  const SkillDefinition(this.id, this.level, this.name, this.effect);

  final String id;
  final int level;
  final String name;
  final String effect;
}

const List<SkillDefinition> skillCatalog = <SkillDefinition>[
  SkillDefinition('work_rhythm', 2, '일손의 요령', '일거리 보상 +10%'),
  SkillDefinition('fee_sense', 3, '거래비용 감각', '국내 주식 거래비용 -10%'),
  SkillDefinition('research_habit', 4, '리서치 습관', '월 리서치 수입 +20,000원'),
  SkillDefinition('calm_exit', 5, '침착한 매도', '수익 매도 평판 보너스 +1'),
  SkillDefinition('cohort_briefing', 6, '데시멀 동기 브리핑', '중요 선택 완료 시 공동체 신뢰 +1'),
  SkillDefinition('talent_network', 7, '인재 추천망', '신규 직원 계약금 10% 절감'),
  SkillDefinition('cash_management', 8, '현금 관리', '입출금·정기예금 우대금리 +0.15%p'),
  SkillDefinition('property_operation', 9, '임대 운영', '월 부동산 임대수입 +10%'),
];

const List<int> _levelThresholds = <int>[
  0,
  120,
  300,
  550,
  900,
  1350,
  1900,
  2600,
  3500,
];

int progressionLevelForExperience(int experience) {
  var level = 1;
  for (var index = 1; index < _levelThresholds.length; index++) {
    if (experience < _levelThresholds[index]) break;
    level = index + 1;
  }
  return level;
}

int experienceForLevel(int level) =>
    _levelThresholds[(level - 1).clamp(0, _levelThresholds.length - 1)];

class PlayerProgressionState {
  const PlayerProgressionState({
    required this.experience,
    required this.counters,
  });

  factory PlayerProgressionState.initial() =>
      const PlayerProgressionState(experience: 0, counters: <String, int>{});

  final int experience;
  final Map<String, int> counters;

  int get level => progressionLevelForExperience(experience);
  int counter(String metric) => counters[metric] ?? 0;
  bool hasSkill(String id) =>
      skillCatalog.any((skill) => skill.id == id && level >= skill.level);

  PlayerProgressionState copyWith({
    int? experience,
    Map<String, int>? counters,
  }) => PlayerProgressionState(
    experience: experience ?? this.experience,
    counters: counters ?? this.counters,
  );

  PlayerProgressionState record(String metric, [int amount = 1]) {
    if (amount <= 0) return this;
    return copyWith(
      counters: <String, int>{...counters, metric: counter(metric) + amount},
    );
  }

  PlayerProgressionState gainExperience(int amount) {
    if (amount <= 0) return this;
    return copyWith(experience: (experience + amount).clamp(0, 1 << 30));
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'experience': experience,
    'counters': counters,
  };

  factory PlayerProgressionState.fromJson(Map<String, dynamic> json) {
    return PlayerProgressionState(
      experience: ((json['experience'] as num?)?.toInt() ?? 0).clamp(
        0,
        1 << 30,
      ),
      counters: ((json['counters'] as Map?) ?? const <String, dynamic>{}).map(
        (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
      ),
    );
  }
}
