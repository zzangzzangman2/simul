class MissionDefinition {
  const MissionDefinition({
    required this.id,
    required this.chapter,
    required this.title,
    required this.story,
    required this.metric,
    required this.target,
    required this.objective,
    required this.experienceReward,
    this.cashReward = 0,
    this.reputationReward = 0,
    this.trustReward = 0,
    this.relative = false,
    this.deadlineDays,
    this.requiredYear = 2000,
  });

  final String id;
  final String chapter;
  final String title;
  final String story;
  final String metric;
  final int target;
  final String objective;
  final int experienceReward;
  final int cashReward;
  final int reputationReward;
  final int trustReward;
  final bool relative;
  final int? deadlineDays;
  final int requiredYear;
}

MissionDefinition _mission(
  String id,
  String chapter,
  String title,
  String story,
  String metric,
  int target,
  String objective,
  int xp, {
  int cash = 0,
  int reputation = 0,
  int trust = 0,
  bool relative = false,
  int? deadlineDays,
  int year = 2000,
}) => MissionDefinition(
  id: id,
  chapter: chapter,
  title: title,
  story: story,
  metric: metric,
  target: target,
  objective: objective,
  experienceReward: xp,
  cashReward: cash,
  reputationReward: reputation,
  trustReward: trust,
  relative: relative,
  deadlineDays: deadlineDays,
  requiredYear: year,
);

final List<MissionDefinition> missionCatalog = <MissionDefinition>[
  _mission(
    'first_note',
    '1장 · 0원의 장부',
    '첫 조사 원칙을 정하자',
    '가족 앞에서 어떤 기준으로 회사를 볼지 선언하면 첫 장부가 시작된다.',
    'decisions_resolved',
    1,
    '첫 기업 조사노트 안건 해결',
    80,
    cash: 500,
    trust: 1,
  ),
  _mission(
    'first_work',
    '1장 · 0원의 장부',
    '내 손으로 첫 돈 벌기',
    '투자금과 생활비를 섞지 않으려면 작은 일거리부터 직접 해내야 한다.',
    'work_sessions',
    1,
    '일거리 1회 완료',
    70,
    cash: 300,
  ),
  _mission(
    'seed_10000',
    '1장 · 0원의 장부',
    '종잣돈 1만원 완성',
    '직접 번 돈이 1만원을 넘으면 보호자에게 첫 주문 승인을 부탁할 수 있다.',
    'earned_seed',
    10000,
    '누적 종잣돈 10,000원 벌기',
    130,
    cash: 1000,
    reputation: 1,
    trust: 1,
  ),
  _mission(
    'first_buy',
    '2장 · 첫 주문',
    '주식 1주를 직접 사 보자',
    '신문에서 고른 회사를 주문표에 적고 실제 계좌 현금 안에서 첫 매수를 체결한다.',
    'buy_orders',
    1,
    '국내 주식 매수 1회',
    150,
    cash: 1500,
    reputation: 1,
  ),
  _mission(
    'buy_three_shares',
    '2장 · 첫 주문',
    '세 번 확인하고 3주 모으기',
    '한 번의 클릭보다 주문 이유와 수량을 기록하는 습관이 중요하다.',
    'shares_bought',
    3,
    '누적 3주 매수',
    110,
    cash: 1000,
  ),
  _mission(
    'two_companies',
    '2장 · 첫 주문',
    '두 회사를 비교하자',
    '한 회사만 보면 좋은 점만 보인다. 서로 다른 두 회사를 장부에 올려 비교한다.',
    'unique_assets',
    2,
    '서로 다른 국내 종목 2개 보유',
    150,
    cash: 2000,
    reputation: 1,
  ),
  _mission(
    'watch_three_days',
    '2장 · 첫 주문',
    '사흘 동안 가격을 지켜보자',
    '산 직후의 등락에 흔들리지 않고 사흘의 신문과 장 마감을 기록한다.',
    'days_advanced',
    3,
    '미션 시작 후 3일 진행',
    120,
    relative: true,
    trust: 1,
  ),
  _mission(
    'three_decisions',
    '3장 · 투자 습관',
    '세 번 설명하고 결정하기',
    '결정의 결과보다 가족에게 이유를 설명하는 과정이 투자 원칙을 만든다.',
    'decisions_resolved',
    3,
    '누적 안건 3건 해결',
    140,
    reputation: 1,
    trust: 1,
  ),
  _mission(
    'first_sell',
    '3장 · 투자 습관',
    '처음으로 매도해 보자',
    '사는 것만큼 파는 이유도 중요하다. 보유 주식 일부 또는 전부를 매도한다.',
    'sell_orders',
    1,
    '주식 매도 1회',
    130,
    cash: 1000,
  ),
  _mission(
    'first_profit',
    '3장 · 투자 습관',
    '첫 수익을 확정하자',
    '평가이익은 숫자일 뿐이다. 수수료를 빼고 남는 첫 실현이익을 기록한다.',
    'profitable_sales',
    1,
    '이익이 난 매도 1회',
    170,
    cash: 2500,
    reputation: 2,
  ),
  _mission(
    'profit_10000',
    '3장 · 투자 습관',
    '실현이익 1만원',
    '작은 이익을 반복 가능하게 만드는 것이 운보다 강한 연구소의 시작이다.',
    'realized_profit',
    10000,
    '누적 양의 실현이익 10,000원',
    180,
    cash: 3000,
    reputation: 2,
  ),
  _mission(
    'five_work',
    '3장 · 투자 습관',
    '일거리 다섯 번의 기록',
    '시장이 쉬는 날에도 현금흐름은 멈추지 않는다.',
    'work_sessions',
    5,
    '누적 일거리 5회',
    120,
    cash: 2500,
    trust: 1,
  ),
  _mission(
    'cash_100k',
    '4장 · 작은 운용사',
    '현금 10만원 만들기',
    '기회를 기다릴 수 있는 현금이 있어야 싼 가격이 와도 움직일 수 있다.',
    'cash',
    100000,
    '보유 현금 100,000원',
    180,
    cash: 5000,
    reputation: 1,
  ),
  _mission(
    'five_buys',
    '4장 · 작은 운용사',
    '매수 기록 다섯 장',
    '각 주문에 한 줄 이유를 붙이며 서로 다른 시장 상황을 경험한다.',
    'buy_orders',
    5,
    '누적 매수 주문 5회',
    160,
    cash: 3500,
  ),
  _mission(
    'twenty_shares',
    '4장 · 작은 운용사',
    '20주의 무게',
    '수량이 커질수록 작은 가격 변화도 장부에 크게 찍힌다.',
    'shares_bought',
    20,
    '누적 20주 매수',
    170,
    cash: 4000,
  ),
  _mission(
    'family_help_two',
    '4장 · 작은 운용사',
    '가족과 두 번 조사하기',
    '혼자 놓친 숫자를 가족의 다른 시선으로 다시 확인한다.',
    'family_help',
    2,
    '가족 조사 도움 누적 2회',
    140,
    trust: 3,
  ),
  _mission(
    'three_companies',
    '4장 · 작은 운용사',
    '세 업종 바구니',
    '한 사건에 계좌 전체가 흔들리지 않도록 세 회사를 함께 살펴본다.',
    'unique_assets',
    3,
    '서로 다른 국내 종목 3개 보유',
    190,
    cash: 5000,
    reputation: 1,
  ),
  _mission(
    'earn_100k_30d',
    '5장 · 30일 도전',
    '30일 안에 10만원 늘리기',
    '일거리·매매·수입을 조합해 한 달 안에 현금을 늘린다. 실패하면 새 30일 창이 자동으로 시작된다.',
    'cash_gain',
    100000,
    '30일 안에 현금 +100,000원',
    260,
    cash: 10000,
    reputation: 2,
    deadlineDays: 30,
  ),
  _mission(
    'thirty_days',
    '5장 · 30일 도전',
    '한 달의 장부 완주',
    '매일의 작은 판단을 한 달 동안 이어가며 시장 리듬을 익힌다.',
    'days_advanced',
    30,
    '미션 시작 후 30일 진행',
    200,
    cash: 7000,
    relative: true,
  ),
  _mission(
    'reputation_20',
    '5장 · 30일 도전',
    '동네에서 믿는 연구소',
    '수익뿐 아니라 약속과 설명이 쌓여야 다른 사람이 돈 이야기를 맡긴다.',
    'reputation',
    20,
    '평판 20 달성',
    220,
    cash: 6000,
    trust: 2,
  ),
  _mission(
    'three_profit_sales',
    '6장 · 반복 가능한 원칙',
    '수익 매도 세 번',
    '한 번의 행운이 아니라 세 번의 기록으로 원칙을 증명한다.',
    'profitable_sales',
    3,
    '누적 수익 매도 3회',
    230,
    cash: 8000,
    reputation: 2,
  ),
  _mission(
    'profit_50k',
    '6장 · 반복 가능한 원칙',
    '실현이익 5만원',
    '수수료와 실패를 포함한 누적 실현손익을 흑자로 키운다.',
    'realized_profit',
    50000,
    '누적 양의 실현이익 50,000원',
    240,
    cash: 10000,
    reputation: 2,
  ),
  _mission(
    'cash_500k',
    '6장 · 반복 가능한 원칙',
    '현금 50만원 방어선',
    '급한 지출과 새로운 기회를 동시에 견딜 수 있는 현금 방어선을 만든다.',
    'cash',
    500000,
    '보유 현금 500,000원',
    260,
    cash: 15000,
    reputation: 2,
  ),
  _mission(
    'positive_month',
    '6장 · 반복 가능한 원칙',
    '첫 흑자 월 결산',
    '월간 수입에서 급여·임대료·유지비를 빼고도 플러스를 남긴다.',
    'positive_months',
    1,
    '흑자 월 결산 1회',
    230,
    cash: 12000,
    reputation: 2,
  ),
  _mission(
    'eight_decisions',
    '6장 · 반복 가능한 원칙',
    '여덟 번의 선택 기록',
    '어떤 선택이 조직과 가족에게 어떤 결과를 남겼는지 되짚는다.',
    'decisions_resolved',
    8,
    '누적 안건 8건 해결',
    220,
    trust: 2,
  ),
  _mission(
    'first_employee',
    '7장 · 혼자가 아닌 회사',
    '첫 조사원 채용',
    '2003년부터 급여를 감당할 준비가 되면 첫 직원을 정식으로 맞는다.',
    'employees',
    1,
    '정식 직원 1명 채용',
    300,
    cash: 20000,
    reputation: 3,
    year: 2003,
  ),
  _mission(
    'research_income_180k',
    '7장 · 혼자가 아닌 회사',
    '리서치 수입 18만원',
    '조사 결과가 실제 고객 수입으로 이어지는 구조를 만든다.',
    'research_income',
    180000,
    '누적 월 리서치 수입 180,000원',
    280,
    cash: 18000,
    reputation: 2,
    year: 2003,
  ),
  _mission(
    'launch_fund',
    '7장 · 혼자가 아닌 회사',
    '첫 외부 펀드 출범',
    '직원·평판·원칙을 갖추고 외부 자금을 맡는 첫 펀드를 연다.',
    'fund_launched',
    1,
    '외부 펀드 출범',
    380,
    cash: 30000,
    reputation: 4,
    year: 2004,
  ),
  _mission(
    'external_aum',
    '7장 · 혼자가 아닌 회사',
    '외부자금 500만원',
    '내 돈이 아닌 자금을 맡았다는 책임을 장부의 첫 줄에 적는다.',
    'external_aum',
    5000000,
    '외부 AUM 5,000,000원',
    320,
    cash: 25000,
    reputation: 3,
    year: 2004,
  ),
  _mission(
    'first_spending',
    '8장 · 돈을 쓰는 이유',
    '성장을 위한 첫 소비',
    '무조건 아끼지 말고 교육·자료·가족·사업 중 목적이 분명한 곳에 돈을 쓴다.',
    'finance_purchases',
    1,
    '자산·소비 계획 1회 실행',
    240,
    cash: 10000,
    trust: 1,
  ),
  _mission(
    'first_property',
    '8장 · 돈을 쓰는 이유',
    '첫 부동산 계약',
    '법인 장부에서 매입가·월수입·유지비·매각 조건을 모두 확인한다.',
    'properties',
    1,
    '법인 부동산 1개 보유',
    400,
    cash: 40000,
    reputation: 3,
    year: 2006,
  ),
  _mission(
    'earn_250k_30d',
    '9장 · 운용 능력 시험',
    '30일 안에 25만원 늘리기',
    '투자·리서치·임대수입을 엮어 더 높은 월간 목표에 도전한다.',
    'cash_gain',
    250000,
    '30일 안에 현금 +250,000원',
    420,
    cash: 30000,
    reputation: 3,
    deadlineDays: 30,
    year: 2006,
  ),
  _mission(
    'three_employees',
    '9장 · 운용 능력 시험',
    '세 사람의 연구팀',
    '서로 다른 강점의 직원 세 명과 급여를 버티는 조직을 만든다.',
    'employees',
    3,
    '정식 직원 3명 채용',
    360,
    cash: 30000,
    reputation: 3,
    year: 2005,
  ),
  _mission(
    'trade_volume_2m',
    '9장 · 운용 능력 시험',
    '누적 거래대금 200만원',
    '큰 숫자에 취하지 않고 모든 주문의 비용과 이유를 남긴다.',
    'trade_volume',
    2000000,
    '누적 매수·매도 거래대금 2,000,000원',
    340,
    cash: 25000,
  ),
  _mission(
    'networth_5m',
    '10장 · 중견 투자사',
    '회사 자산 500만원',
    '현금과 보유주식 원가, 부동산 장부가를 합쳐 첫 500만원 규모를 만든다.',
    'net_worth',
    5000000,
    '장부 자산 5,000,000원',
    450,
    cash: 50000,
    reputation: 4,
  ),
  _mission(
    'reputation_60',
    '10장 · 중견 투자사',
    '평판 60의 이름값',
    '수익·고용·가족 신뢰가 함께 쌓인 회사로 인정받는다.',
    'reputation',
    60,
    '평판 60 달성',
    420,
    cash: 35000,
    trust: 3,
  ),
  _mission(
    'six_positive_months',
    '10장 · 중견 투자사',
    '흑자 월 결산 여섯 번',
    '단기 매매가 없어도 버티는 사업 현금흐름을 증명한다.',
    'positive_months',
    6,
    '누적 흑자 월 결산 6회',
    480,
    cash: 60000,
    reputation: 4,
  ),
  _mission(
    'property_income_500k',
    '10장 · 중견 투자사',
    '임대수입 누적 50만원',
    '유지비를 무시하지 않고 부동산 현금흐름을 실제 장부에 쌓는다.',
    'property_income',
    500000,
    '누적 부동산 임대수입 500,000원',
    430,
    cash: 45000,
    year: 2008,
  ),
  _mission(
    'chance_once',
    '11장 · 성인의 선택',
    '확률표를 읽고 한 번만',
    '2010년 성인이 된 뒤 확률과 평균 지급률을 확인하고 정한 한도 안에서만 체험한다.',
    'chance_plays',
    1,
    '성인 게임머니 확률 오락 1회',
    250,
    cash: 10000,
    year: 2010,
  ),
  _mission(
    'earn_1m_30d',
    '11장 · 성인의 선택',
    '30일 안에 100만원 늘리기',
    '10년 동안 만든 투자·조직·자산 시스템을 한 달 성과로 증명한다.',
    'cash_gain',
    1000000,
    '30일 안에 현금 +1,000,000원',
    600,
    cash: 100000,
    reputation: 5,
    deadlineDays: 30,
    year: 2010,
  ),
  _mission(
    'networth_10m',
    '12장 · 투자 명가',
    '회사 자산 1천만원',
    '현금·증권·부동산을 합친 장부 자산 1천만원을 달성한다.',
    'net_worth',
    10000000,
    '장부 자산 10,000,000원',
    650,
    cash: 120000,
    reputation: 5,
  ),
  _mission(
    'twenty_decisions',
    '12장 · 투자 명가',
    '스무 번의 선택',
    '결과가 좋았던 선택과 틀렸던 선택을 모두 회사의 역사로 남긴다.',
    'decisions_resolved',
    20,
    '누적 안건 20건 해결',
    500,
    cash: 70000,
    trust: 4,
  ),
  _mission(
    'ten_profit_sales',
    '12장 · 투자 명가',
    '수익 매도 열 번',
    '한 번의 대박보다 반복 가능한 매수·매도 원칙을 완성한다.',
    'profitable_sales',
    10,
    '누적 수익 매도 10회',
    650,
    cash: 100000,
    reputation: 6,
  ),
];

class SkillDefinition {
  const SkillDefinition(this.id, this.level, this.name, this.effect);

  final String id;
  final int level;
  final String name;
  final String effect;
}

const List<SkillDefinition> skillCatalog = <SkillDefinition>[
  SkillDefinition('mission_board', 1, '첫 장부', '미션과 보상을 기록한다.'),
  SkillDefinition('work_rhythm', 2, '일손의 요령', '일거리 보상 +10%'),
  SkillDefinition('fee_sense', 3, '거래비용 감각', '국내 주식 거래비용 -10%'),
  SkillDefinition('research_habit', 4, '리서치 습관', '월 리서치 수입 +20,000원'),
  SkillDefinition('calm_exit', 5, '침착한 매도', '수익 매도 평판 보너스 +1'),
  SkillDefinition('family_briefing', 6, '가족 브리핑', '안건 해결 시 가족 신뢰 +1'),
  SkillDefinition('talent_network', 7, '인재 추천망', '신규 직원 계약금 10% 절감'),
  SkillDefinition('cash_management', 8, '현금 관리', '월 예수금 이자율 0.10% → 0.15%'),
  SkillDefinition('property_operation', 9, '임대 운영', '월 부동산 임대수입 +10%'),
  SkillDefinition('legendary_house', 10, '투자 명가', '미션 현금 보상 +25%'),
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
  4600,
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

class MissionProgressionState {
  const MissionProgressionState({
    required this.experience,
    required this.currentMissionIndex,
    required this.missionStartedDay,
    required this.missionStartCash,
    required this.missionStartCounter,
    required this.counters,
    required this.claimedMissionIds,
  });

  factory MissionProgressionState.initial({
    required int day,
    required int cash,
  }) => MissionProgressionState(
    experience: 0,
    currentMissionIndex: 0,
    missionStartedDay: day,
    missionStartCash: cash,
    missionStartCounter: 0,
    counters: const <String, int>{},
    claimedMissionIds: const <String>[],
  );

  final int experience;
  final int currentMissionIndex;
  final int missionStartedDay;
  final int missionStartCash;
  final int missionStartCounter;
  final Map<String, int> counters;
  final List<String> claimedMissionIds;

  int get level => progressionLevelForExperience(experience);
  bool get allMissionsComplete => currentMissionIndex >= missionCatalog.length;
  MissionDefinition? get activeMission =>
      allMissionsComplete ? null : missionCatalog[currentMissionIndex];
  int counter(String metric) => counters[metric] ?? 0;
  bool hasSkill(String id) =>
      skillCatalog.any((skill) => skill.id == id && level >= skill.level);

  MissionProgressionState copyWith({
    int? experience,
    int? currentMissionIndex,
    int? missionStartedDay,
    int? missionStartCash,
    int? missionStartCounter,
    Map<String, int>? counters,
    List<String>? claimedMissionIds,
  }) => MissionProgressionState(
    experience: experience ?? this.experience,
    currentMissionIndex: currentMissionIndex ?? this.currentMissionIndex,
    missionStartedDay: missionStartedDay ?? this.missionStartedDay,
    missionStartCash: missionStartCash ?? this.missionStartCash,
    missionStartCounter: missionStartCounter ?? this.missionStartCounter,
    counters: counters ?? this.counters,
    claimedMissionIds: claimedMissionIds ?? this.claimedMissionIds,
  );

  MissionProgressionState record(String metric, [int amount = 1]) {
    if (amount <= 0) return this;
    return copyWith(
      counters: <String, int>{...counters, metric: counter(metric) + amount},
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'experience': experience,
    'currentMissionIndex': currentMissionIndex,
    'missionStartedDay': missionStartedDay,
    'missionStartCash': missionStartCash,
    'missionStartCounter': missionStartCounter,
    'counters': counters,
    'claimedMissionIds': claimedMissionIds,
  };

  factory MissionProgressionState.fromJson(
    Map<String, dynamic> json, {
    required int fallbackDay,
    required int fallbackCash,
  }) {
    if (json.isEmpty) {
      return MissionProgressionState.initial(
        day: fallbackDay,
        cash: fallbackCash,
      );
    }
    return MissionProgressionState(
      experience: ((json['experience'] as num?)?.toInt() ?? 0).clamp(
        0,
        1 << 30,
      ),
      currentMissionIndex: ((json['currentMissionIndex'] as num?)?.toInt() ?? 0)
          .clamp(0, missionCatalog.length),
      missionStartedDay:
          ((json['missionStartedDay'] as num?)?.toInt() ?? fallbackDay).clamp(
            1,
            1 << 30,
          ),
      missionStartCash:
          (json['missionStartCash'] as num?)?.toInt() ?? fallbackCash,
      missionStartCounter: (json['missionStartCounter'] as num?)?.toInt() ?? 0,
      counters: ((json['counters'] as Map?) ?? const <String, dynamic>{}).map(
        (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
      ),
      claimedMissionIds:
          ((json['claimedMissionIds'] as List?) ?? const <dynamic>[])
              .whereType<String>()
              .toSet()
              .toList(growable: false),
    );
  }
}
