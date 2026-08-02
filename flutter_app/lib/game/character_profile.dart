class CohortCharacterProfile {
  const CohortCharacterProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.group,
    required this.mbti,
    required this.role,
    required this.summary,
    required this.personality,
    required this.likes,
    required this.strength,
    required this.investmentView,
    required this.relationshipStyle,
    required this.keywords,
    required this.accentValue,
    required this.portraitAsset,
  });

  final String id;
  final String name;
  final int age;
  final String group;
  final String mbti;
  final String role;
  final String summary;
  final String personality;
  final String likes;
  final String strength;
  final String investmentView;
  final String relationshipStyle;
  final List<String> keywords;
  final int accentValue;
  final String portraitAsset;

  String get ageLabel => age < 20 ? '$age살' : '$age세';
}

const cohortCharacterProfiles = <CohortCharacterProfile>[
  CohortCharacterProfile(
    id: 'kim_seoa',
    name: '김서아',
    age: 14,
    group: '프로젝트 데시멀 · 최종 10인',
    mbti: 'ISFJ',
    role: '신뢰 기록 · 역발상 가치 담당',
    summary: '기록으로 약속과 사람 사이의 신뢰를 지키는 차분한 생활실 서기.',
    personality:
        '말수는 많지 않지만 친구가 빌린 물건과 싫어하는 것까지 세심하게 기억한다. 규칙을 좋아해도 권위에 무조건 따르지는 않으며, 기록이 사람을 덜 상하게 만드는지 먼저 본다.',
    likes: '정돈된 장부, 색색의 필기구, 약속이 정확히 지켜지는 순간',
    strength: '흩어진 약속과 생활 정보를 빠뜨리지 않고 한 장의 기록으로 묶는다.',
    investmentView: '꾸준한 운영 기록과 신뢰가 실제 숫자로 이어지는 회사를 선호한다.',
    relationshipStyle: '작은 배려와 반복해서 지켜진 약속을 오래 기억하며 천천히 마음을 연다.',
    keywords: <String>['세심함', '책임감', '기록'],
    accentValue: 0xFFF38B96,
    portraitAsset:
        'assets/images/production_soft_painted/kim_seoa/01_neutral_notebook_v1.png',
  ),
  CohortCharacterProfile(
    id: 'lee_jian',
    name: '이지안',
    age: 14,
    group: '프로젝트 데시멀 · 최종 10인',
    mbti: 'ISTP',
    role: '체결 구조 · 초단기 대응 담당',
    summary: '손으로 직접 확인해야 납득하는 조용하고 재빠른 수리광.',
    personality:
        '문제를 한동안 조용히 보다가 원인이 보이면 바로 손을 댄다. 혼자 집중하는 시간을 좋아하지만 누군가 정말 곤란할 때는 긴 설명보다 먼저 고쳐 준다.',
    likes: '라디오, 작은 공구, 분해 가능한 기계, 고장 원인 찾기',
    strength: '복잡한 문제를 작동 원리와 확인 가능한 원인으로 잘게 나눈다.',
    investmentView: '광고보다 실제 제품과 작동 원리를 시험하고 결함이 방치되면 판다.',
    relationshipStyle: '말은 짧아도 함께 작업하고 선제적으로 도와주는 행동으로 친밀함을 보인다.',
    keywords: <String>['관찰', '수리', '실험'],
    accentValue: 0xFF77BCE8,
    portraitAsset:
        'assets/images/production_soft_painted/lee_jian/01_neutral_screwdriver_v2.png',
  ),
  CohortCharacterProfile(
    id: 'choi_iseo',
    name: '최이서',
    age: 14,
    group: '프로젝트 데시멀 · 최종 10인',
    mbti: 'ISFP',
    role: '차트 리듬 · 이상 징후 담당',
    summary: '색과 재질, 당사자의 편안함을 놓치지 않는 섬세한 제작자.',
    personality:
        '남들이 좋아하는 것과 자신이 좋아하는 것을 분명히 구분한다. 조용하지만 개인의 선택과 경계를 가볍게 넘는 행동에는 단호하다.',
    likes: '천 조각, 색 조합, 손바느질, 오래 써서 손에 익은 물건',
    strength: '숫자로 설명하기 어려운 사용감과 사람의 불편을 구체적으로 발견한다.',
    investmentView: '사람이 실제로 쓰기 편한 제품인지, 유행 뒤에도 취향이 남는지 살핀다.',
    relationshipStyle: '취향을 강요하지 않고 서로의 선택을 존중할 때 가장 편하게 가까워진다.',
    keywords: <String>['감각', '제작', '경계'],
    accentValue: 0xFFB58CE8,
    portraitAsset:
        'assets/images/production_soft_painted/choi_iseo/01_base_thread_v1.png',
  ),
  CohortCharacterProfile(
    id: 'jung_arin',
    name: '정아린',
    age: 14,
    group: '프로젝트 데시멀 · 최종 10인',
    mbti: 'ESTJ',
    role: '인수 실행 · 운영 통합 담당',
    summary: '흐린 약속을 담당과 마감이 있는 행동으로 바꾸는 현장 반장.',
    personality:
        '누가 언제 무엇을 할지 불분명한 상황을 가장 답답해한다. 말이 단호해 친구를 몰아붙일 때도 있지만, 잘못을 알면 계획부터 바로 고친다.',
    likes: '체크표, 정확한 시간 약속, 끝난 일에 긋는 굵은 완료선',
    strength: '결정된 일을 담당·순서·마감으로 나눠 실제 행동까지 끌고 간다.',
    investmentView: '계획보다 실행 실적과 마감 준수, 반복 가능한 운영 능력을 확인한다.',
    relationshipStyle: '돌려 말하기보다 가능한 시간과 행동을 정확히 약속하는 사람을 신뢰한다.',
    keywords: <String>['실행력', '정리', '마감'],
    accentValue: 0xFFFF9466,
    portraitAsset:
        'assets/images/production_soft_painted/jung_arin/01_base_cheeky_v1.png',
  ),
  CohortCharacterProfile(
    id: 'park_haeun',
    name: '박하은',
    age: 14,
    group: '프로젝트 데시멀 · 최종 10인',
    mbti: 'ENFJ',
    role: '정보망 · 협상 · 관계 위험 담당',
    summary: '말하지 못한 친구를 발견하면 그냥 지나치지 못하는 다정한 조정자.',
    personality:
        '집단의 분위기와 혼자 입을 닫은 친구를 함께 살핀다. 모두를 빨리 화해시키려다 실수할 때도 있지만, 상대의 거절을 들으면 멈추는 법을 배우고 있다.',
    likes: '함께 먹는 간식, 역할 나누기, 친구가 자기 의견을 말하는 순간',
    strength: '서로 다른 입장을 말할 수 있게 만들고 각자 잘할 역할을 찾아 준다.',
    investmentView: '직원과 고객이 실제로 오래 머물 수 있는 조직인지 먼저 관찰한다.',
    relationshipStyle: '상대가 원하는 도움이 무엇인지 묻고, 가까워질수록 자기 필요도 솔직히 말한다.',
    keywords: <String>['배려', '합의', '응원'],
    accentValue: 0xFFFF7F9B,
    portraitAsset:
        'assets/images/production_soft_painted/park_haeun/01_neutral_soft_v2.png',
  ),
  CohortCharacterProfile(
    id: 'han_sua',
    name: '한수아',
    age: 14,
    group: '프로젝트 데시멀 · 최종 10인',
    mbti: 'ENFP',
    role: '테마 · 유행 · 수요 전조 담당',
    summary: '사람들의 표정과 반응에서 아직 숫자가 되지 않은 변화를 먼저 읽는다.',
    personality:
        '새로운 가능성을 발견하면 빠르게 들뜨고 여러 사람의 반응을 연결한다. 시작은 빠르지만 마무리가 흔들릴 수 있고, 자기 가치에 어긋난 압박에는 예상보다 단호하다.',
    likes: '새로운 이야기, 사람 구경, 간식 고르기, 뜻밖의 연결 찾기',
    strength: '흩어진 사람 반응에서 새로운 사용 방식과 분위기의 변화를 발견한다.',
    investmentView: '고객의 말과 표정, 입소문이 실제 수요로 이어질 가능성을 먼저 본다.',
    relationshipStyle: '빠르고 활기차게 다가오지만 진짜 불안은 충분히 믿는 사람에게만 보여 준다.',
    keywords: <String>['가능성', '관찰', '활기'],
    accentValue: 0xFFFF6F91,
    portraitAsset:
        'assets/images/production_soft_painted/han_sua/01_neutral_quality_v2.png',
  ),
  CohortCharacterProfile(
    id: 'oh_jiwoo',
    name: '오지우',
    age: 14,
    group: '프로젝트 데시멀 · 최종 10인',
    mbti: 'ENTP',
    role: '반대가설 · 공매도 논리 담당',
    summary: '신호 하나를 들으면 다른 해석을 세 개쯤 시험하는 재치 있는 라디오광.',
    personality:
        '설명의 빈틈과 숨은 전제를 발견하면 바로 다른 가설을 던진다. 장난스럽지만 핵심 가설이 틀렸다고 확인되면 억지 핑계를 붙이지 않고 고칠 줄 안다.',
    likes: '라디오 방송, 즉석 토론, 반례 찾기, 예상 밖의 질문',
    strength: '모두가 당연하다고 넘긴 전제를 뒤집어 더 나은 설명을 찾는다.',
    investmentView: '시장에 퍼진 한 가지 이야기의 반례를 찾고 가설이 깨지면 빠르게 수정한다.',
    relationshipStyle: '장난과 질문으로 거리를 좁히며, 가까워지면 틀릴 가능성과 실제 걱정을 인정한다.',
    keywords: <String>['가설', '반례', '재치'],
    accentValue: 0xFF45B7A7,
    portraitAsset:
        'assets/images/production_soft_painted/oh_jiwoo/01_alert_neutral_v1.png',
  ),
  CohortCharacterProfile(
    id: 'yoon_chaea',
    name: '윤채아',
    age: 14,
    group: '프로젝트 데시멀 · 최종 10인',
    mbti: 'INTJ',
    role: '퀀트 · 장기 전략 담당',
    summary: '숫자 뒤의 구조와 다음 단계를 혼자 오래 연결하는 독립적인 전략가.',
    personality:
        '흩어진 정보를 장기 패턴으로 묶고 핵심 질문 하나를 남긴다. 모든 것을 아는 척하지 않으며, 전제가 부족하면 모른다고 말한 뒤 다시 확인한다.',
    likes: '헌책방, 영수증 비교, 조용한 창가, 오래 이어지는 계획',
    strength: '가격과 규칙 뒤의 의도를 찾아 장기 경로와 실패 조건을 함께 세운다.',
    investmentView: '경쟁우위와 자본 배분을 보고 핵심 전제가 깨지면 미련 없이 계획을 바꾼다.',
    relationshipStyle: '말은 적지만 정확하며, 신뢰하는 사람에게는 미완성 계획과 모르는 부분도 공유한다.',
    keywords: <String>['전략', '구조', '독립성'],
    accentValue: 0xFF727FBE,
    portraitAsset:
        'assets/images/production_soft_painted/yoon_chaea/01_neutral_tie_v1.png',
  ),
  CohortCharacterProfile(
    id: 'kim_hakjun',
    name: '김학준',
    age: 14,
    group: '프로젝트 데시멀 · 최종 10인',
    mbti: 'ISTJ',
    role: '규정 · 계산 · 교차검토 담당',
    summary: '규정과 계산을 먼저 맞춰 모두가 오래 버틸 기준을 찾는 신중한 원칙파.',
    personality:
        '새로운 제안을 바로 믿기보다 규정과 숫자를 차례로 검산한다. 딱딱해 보일 때도 있지만, 누군가 손해를 떠안는 구조를 발견하면 끝까지 이유를 묻는다.',
    likes: '정리된 규정집, 계산 검산, 빈틈없는 장부, 약속된 순서',
    strength: '규정과 수치를 교차검토해 뒤늦게 드러날 위험과 누락을 찾아낸다.',
    investmentView: '수익보다 손실 한도와 책임 구조가 명확한지 먼저 확인한다.',
    relationshipStyle: '시간과 약속을 지키는 행동을 신뢰하며 필요한 도움은 구체적으로 제안한다.',
    keywords: <String>['원칙', '검산', '신중함'],
    accentValue: 0xFF5D7FA3,
    portraitAsset:
        'assets/images/historical_prologue/character_hakjun_orientation_v2.png',
  ),
  CohortCharacterProfile(
    id: 'han_seoyoon',
    name: '한서윤',
    age: 23,
    group: '프로젝트 데시멀 운영관',
    mbti: 'INFJ',
    role: '안전 공개 · 판단 기준 운영관',
    summary: '동기들의 질문을 끝까지 듣고 감당하지 않아도 될 위험을 먼저 공개하는 운영관.',
    personality:
        '답을 대신 정해 주기보다 각자가 관찰한 사실과 선택 이유를 말하게 한다. 차분하고 다정하지만 불공정한 제도나 숨긴 위험을 좋은 말로 포장하지 않는다.',
    likes: '솔직한 투자노트, 핵심을 찌르는 질문, 스스로 고친 판단, 조용한 복습 시간',
    strength: '어려운 시장 개념을 생활어로 풀고 열 명의 질문을 하나의 판단 기준으로 연결한다.',
    investmentView: '매수 이유와 매도 조건을 기록하고 손실 가능성까지 설명할 수 있어야 투자로 인정한다.',
    relationshipStyle: '사람을 한 유형으로 단정하지 않고 말이 끝날 때까지 들은 뒤 정확한 질문으로 되돌려 준다.',
    keywords: <String>['통찰', '경청', '원칙'],
    accentValue: 0xFF3E9CA8,
    portraitAsset: 'assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png',
  ),
];

CohortCharacterProfile? cohortCharacterProfileById(String id) {
  for (final profile in cohortCharacterProfiles) {
    if (profile.id == id) return profile;
  }
  return null;
}
