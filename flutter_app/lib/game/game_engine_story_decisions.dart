part of 'game_engine.dart';

DecisionCardData _bankAccessIntroduction(int day) => DecisionCardData(
  id: 'facility-intro-bank-yoon-harin',
  category: '시설 해금 이야기',
  title: '국가계좌의 생활금융 담당자를 만나세요',
  proposer: '한서윤 운영관',
  body:
      '주식 계좌와 생활 자금을 섞지 않도록 새천년은행 개인금융 창구를 연결했습니다. '
      '예금과 신용 상담은 윤하린 은행원이 맡습니다. 첫 면담을 마치면 평일 장 마감 후 은행 업무를 볼 수 있습니다.',
  createdDay: day,
  dueDay: day + 7,
  requestedFunds: 0,
  benefit: '윤하린 은행원 소개 · 새천년은행 저녁 업무 해금',
  risk: '예금과 대출은 현금흐름과 상환 조건을 직접 확인해야 합니다.',
  advisorOpinions: const [
    '한서윤: 증권 계좌와 생활 통장을 먼저 분리해 두세요.',
    '김서아: 예금·대출 계약은 만기와 이자 지급일을 장부에 기록해야 해요.',
  ],
  options: const [
    DecisionOptionData(
      id: 'meet_bank_clerk_deposit',
      label: '윤하린에게 예금부터 배운다',
      description: '생활 자금과 만기 구조를 중심으로 첫 상담을 예약합니다.',
    ),
    DecisionOptionData(
      id: 'meet_bank_clerk_credit',
      label: '윤하린에게 신용부터 배운다',
      description: '신용점수·대출한도·상환 조건을 중심으로 첫 상담을 예약합니다.',
    ),
  ],
);

DecisionCardData _realEstateAccessIntroduction(int day) => DecisionCardData(
  id: 'facility-intro-realtor-seo-haneul',
  category: '시설 해금 이야기',
  title: '윤하린이 건넨 한마음부동산 소개장',
  proposer: '윤하린 은행원',
  body:
      '첫 은행 상담을 마친 뒤 윤하린이 담보와 현금흐름을 함께 설명할 수 있는 중개사를 소개했습니다. '
      '서하늘 공인중개사와 면담하면 평일 장 마감 후 부동산 시장을 확인할 수 있습니다.',
  createdDay: day,
  dueDay: day + 7,
  requestedFunds: 0,
  benefit: '서하늘 공인중개사 소개 · 한마음부동산 저녁 업무 해금',
  risk: '매입가뿐 아니라 취득비·대출·공실·보유세를 함께 봐야 합니다.',
  advisorOpinions: const [
    '윤하린: 대출 가능액보다 매달 감당할 현금흐름을 먼저 보세요.',
    '김학준: 계약서와 등기·임대 조건을 확인하기 전에는 돈을 보내면 안 돼.',
  ],
  options: const [
    DecisionOptionData(
      id: 'meet_realtor_home',
      label: '서하늘에게 실거주 관점부터 배운다',
      description: '주거비와 대출 부담을 기준으로 첫 매물을 살펴봅니다.',
    ),
    DecisionOptionData(
      id: 'meet_realtor_cashflow',
      label: '서하늘에게 임대 현금흐름부터 배운다',
      description: '공실·보증금·월 순현금을 기준으로 첫 매물을 살펴봅니다.',
    ),
  ],
);

DecisionCardData _firstResearchNote(int day) => DecisionCardData(
  id: 'first-research-note',
  category: '처음 배우기',
  title: '첫 미션: 회사 하나를 구경해 보자',
  proposer: '한서윤 운영관',
  body:
      '아직 돈을 쓰지 않아도 괜찮아. 눈에 익은 회사 하나를 고르고, 무엇을 파는지부터 같이 살펴보자. 아래 네 가지 중 가장 쉬워 보이는 방법을 하나 고르면 돼.',
  createdDay: day,
  dueDay: day + 30,
  requestedFunds: 0,
  benefit: '회사 보는 첫 방법을 배우고 +25 XP 받기',
  risk: '한 가지만 보고 바로 사면 실수할 수 있음',
  advisorOpinions: const [
    '김학준: 회사가 지켜야 할 규정과 빚부터 확인하자.',
    '한수아: 사람들이 왜 이 물건을 사는지 직접 물어보자.',
    '김서아: 매수 이유와 생각이 바뀔 조건을 같은 장에 적자.',
  ],
  options: const [
    DecisionOptionData(
      id: 'research_products',
      label: '써 본 제품부터 보기',
      description: '생활실에서 써 본 물건을 떠올려 회사와 연결해 봅니다.',
    ),
    DecisionOptionData(
      id: 'research_cashflow',
      label: '회사가 돈 버는 법 보기',
      description: '누가 이 회사에 왜 돈을 내는지 한 줄로 적습니다.',
    ),
    DecisionOptionData(
      id: 'research_people',
      label: '회사를 운영하는 사람 보기',
      description: '대표와 직원이 어떤 목표로 일하는지 살펴봅니다.',
    ),
    DecisionOptionData(
      id: 'research_price',
      label: '가격부터 본다',
      description: '주가가 싼지 비싼지 다른 회사와 천천히 비교합니다.',
    ),
  ],
);

DecisionCardData _controlOffer(
  int day, {
  required bool followUp,
}) => DecisionCardData(
  id: followUp ? 'control-offer-followup-$day' : 'control-offer-$day',
  category: '경영권 기회',
  title: followUp ? '한빛전자부품 지분 협상, 마지막 선택' : '흔들리는 부품 회사를 다시 세울 수 있을까?',
  proposer: '한빛전자부품 매각자문 윤 실장',
  body: followUp
      ? '사흘 사이 다른 인수자가 우호지분을 모았습니다. 경영권 가격은 올랐고, 이사회에 들어갈 마지막 조건도 오늘 결정해야 합니다.'
      : '구조조정 뒤 주인이 여러 번 바뀐 한빛전자부품이 투자자를 찾습니다. 작은 지분으로 이사회를 지켜볼 수도, 주요주주가 될 수도, 과반 의결권을 인수할 수도 있습니다.',
  createdDay: day,
  dueDay: day + (followUp ? 1 : 3),
  requestedFunds: followUp ? 240000 : 120000,
  benefit: '지분 단계에 맞는 배당·이사회 정보·경영권',
  risk: '회사 통장 감소 · 공장 정상화 비용 · 직원과 거래처 책임',
  advisorOpinions: const [
    '한서윤: 싸게 사는 것보다 공장과 거래처가 왜 흔들렸는지 먼저 보세요.',
    '김학준: 지분율마다 가능한 행동과 책임이 다릅니다.',
    '한수아: 주인이 된다고 고객이 저절로 돌아오는 건 아니잖아.',
  ],
  options: followUp
      ? const [
          DecisionOptionData(
            id: 'acquire_board_stake',
            label: '24만원 · 주요주주 34%',
            description: '이사회 2석을 확보하고 경영을 감시하지만 단독 결정권은 없습니다.',
            cashCost: 240000,
          ),
          DecisionOptionData(
            id: 'acquire_control_followup',
            label: '35만원 · 경영권 55%',
            description: '의결권 과반과 이사회 4석을 확보해 첫 경영 안건을 맡습니다.',
            cashCost: 350000,
          ),
          DecisionOptionData(
            id: 'pass_control',
            label: '이번 기회 포기',
            description: '현금을 지키고 다른 인수자의 선택을 지켜봅니다.',
          ),
        ]
      : const [
          DecisionOptionData(
            id: 'acquire_board_observer',
            label: '12만원 · 지분 18%',
            description: '이사회 관찰권과 소수지분 배당을 얻고 회사부터 배웁니다.',
            cashCost: 120000,
          ),
          DecisionOptionData(
            id: 'acquire_board_stake',
            label: '22만원 · 주요주주 34%',
            description: '이사회 2석을 확보하지만 경영권은 아직 없습니다.',
            cashCost: 220000,
          ),
          DecisionOptionData(
            id: 'acquire_control',
            label: '30만원 · 경영권 55%',
            description: '의결권 과반과 이사회 4석을 확보해 직접 운영을 시작합니다.',
            cashCost: 300000,
          ),
          DecisionOptionData(
            id: 'review_control',
            label: '3일 더 검토',
            description: '실사 자료는 늘지만 지분 가격과 경쟁 위험이 커집니다.',
          ),
        ],
);

DecisionCardData _controlStakeFollowUp(int day, CompanyState company) {
  final observerStage = company.votingOwnershipPct < 33.4;
  return DecisionCardData(
    id: 'control-stake-followup-$day',
    category: '주주 행동',
    title: observerStage ? '관찰권을 이사회 자리로 넓힐까?' : '주요주주에서 경영권으로 올라설까?',
    proposer: '한빛전자부품 매각자문 윤 실장',
    body: observerStage
        ? '90일 동안 공장과 장부를 지켜봤습니다. 34% 주요주주나 55% 경영권으로 지분을 늘릴 수 있습니다.'
        : '이사회 두 자리는 확보했지만 단독으로 대표와 투자안을 결정할 수는 없습니다. 과반 인수 여부를 정해야 합니다.',
    createdDay: day,
    dueDay: day + 7,
    requestedFunds: observerStage ? 120000 : 160000,
    benefit: '기존 장부가치와 지분을 보존한 단계적 인수',
    risk: '추가 출자 · 과반 취득 뒤 운영 책임',
    advisorOpinions: const [
      '한서윤: 관찰한 문제를 고칠 준비가 됐는지부터 생각하세요.',
      '김서아: 이미 산 지분과 이번 추가대금을 한 장부에서 이어 적자.',
    ],
    options: [
      if (observerStage)
        const DecisionOptionData(
          id: 'expand_board_stake',
          label: '12만원 추가 · 34%',
          description: '이사회 2석을 확보하고 주요 안건에 목소리를 냅니다.',
          cashCost: 120000,
        ),
      DecisionOptionData(
        id: 'complete_control',
        label: observerStage ? '23만원 추가 · 55%' : '16만원 추가 · 55%',
        description: '의결권 과반과 이사회 4석을 확보합니다.',
        cashCost: observerStage ? 230000 : 160000,
      ),
      const DecisionOptionData(
        id: 'hold_company_stake',
        label: '현재 지분 유지',
        description: '보유 지분과 이사회 권한만 유지하고 이번 증액은 넘깁니다.',
      ),
    ],
  );
}

DecisionCardData _controlTransitionDecision(int day) => DecisionCardData(
  id: 'control-transition-$day',
  category: '첫 이사회',
  title: '한빛전자부품을 누가 이끌어야 할까?',
  proposer: '한빛전자부품 이사회',
  body:
      '경영권 인수는 끝났지만 회사를 바로 바꿀 수는 없습니다. 기존 대표, 데시멀 센터 운영자문단, 외부 전문경영인 중 첫 운영 체계를 정해야 합니다.',
  createdDay: day,
  dueDay: day + 7,
  requestedFunds: 0,
  benefit: '첫 리더십 확정과 공장 운영계획 안건 개방',
  risk: '현장 반발 · 교육기관과 회사의 역할 혼동 · 실행 속도',
  advisorOpinions: const [
    '한서윤: 교육 담당자는 직원으로 들어가지 않고 운영 자문만 맡아야 합니다.',
    '김학준: 자문 권한과 보수는 회사 장부에서 분리해 공개해야 해.',
    '기존 공장장: 숙련직원이 떠나면 새 설비도 돌릴 사람이 없습니다.',
  ],
  options: const [
    DecisionOptionData(
      id: 'retain_incumbent_ceo',
      label: '기존 대표 유임',
      description: '현장 충격을 줄이고 이사회가 계획을 감독합니다.',
    ),
    DecisionOptionData(
      id: 'appoint_academy_advisor',
      label: '데시멀 센터 운영자문단',
      description: '정식 직원 수에는 넣지 않고 현장 실사와 준법 자문만 맡깁니다.',
    ),
    DecisionOptionData(
      id: 'appoint_professional_ceo',
      label: '전문경영인 선임',
      description: '변화 속도는 높지만 기존 직원의 불안도 커집니다.',
    ),
  ],
);

DecisionCardData _factoryStrategyDecision(int day) => DecisionCardData(
  id: 'factory-strategy-$day',
  category: '공장 운영계획',
  title: '낡은 공장에 첫 돈을 어디에 쓸까?',
  proposer: '한빛전자부품 경영회의',
  body:
      '한 번에 모든 문제를 고칠 수 없습니다. 회사 통장에서 출자한 돈은 지배회사 투자 장부가치로 남고, 선택은 매출·비용·기술·사기·위험을 함께 바꿉니다.',
  createdDay: day,
  dueDay: day + 10,
  requestedFunds: 180000,
  benefit: '첫 운영전략과 월간 손익 구조 확정',
  risk: '자동화 해고 충격 · 인건비 · 신제품 실패 · 현금 부족',
  advisorOpinions: const [
    '한서윤: 기계만 바꾸지 말고 누가 그 기계를 돌릴지도 보세요.',
    '김서아: 매출 증가보다 매달 남는 영업이익을 같이 계산하자.',
    '한수아: 비싼 부품이면 고객이 정말 차이를 알아보는지도 확인해야 해.',
  ],
  options: const [
    DecisionOptionData(
      id: 'factory_automation',
      label: '18만원 · 공장 자동화',
      description: '고정비와 기술은 개선되지만 숙련직원 사기와 실행 위험이 흔들립니다.',
      cashCost: 180000,
    ),
    DecisionOptionData(
      id: 'protect_skilled_workforce',
      label: '9만원 · 숙련직원 유지',
      description: '급여·교육비는 늘지만 현장 지식과 사기를 지킵니다.',
      cashCost: 90000,
    ),
    DecisionOptionData(
      id: 'premium_components',
      label: '14만원 · 고부가 부품',
      description: '매출과 기술 기회를 늘리지만 개발비와 실패 위험도 커집니다.',
      cashCost: 140000,
    ),
    DecisionOptionData(
      id: 'stabilize_existing_lines',
      label: '기존 라인 안정화',
      description: '큰 출자 없이 불량과 위험부터 줄입니다.',
    ),
  ],
);

DecisionCardData _developmentIssue(int day) => DecisionCardData(
  id: 'development-issue-$day',
  category: '개발 문제',
  title: '시제품이 너무 뜨거워집니다',
  proposer: '기술책임자 미나',
  body: '오래 사용하면 배터리 온도가 안전 기준을 넘습니다. 출시 일정, 기능, 품질을 동시에 지킬 수는 없어요.',
  createdDay: day,
  dueDay: day + 2,
  requestedFunds: 80000,
  benefit: '품질 개선 또는 빠른 일정 유지',
  risk: '지연 · 기능 축소 · 개발비 증가',
  advisorOpinions: const [
    '기술자: 부품을 바꾸면 품질은 좋아지지만 시간이 듭니다.',
    'CEO: 핵심 기능을 줄이면 제품의 매력이 약해집니다.',
    '회계사: 추가 지출 뒤에도 비상금은 남겨야 합니다.',
  ],
  options: const [
    DecisionOptionData(
      id: 'fix_quality',
      label: '8만원 들여 부품 교체',
      description: '품질과 팀 사기는 오르지만 비용이 큽니다.',
      cashCost: 80000,
    ),
    DecisionOptionData(
      id: 'cut_scope',
      label: '2만원으로 기능 축소',
      description: '빠르게 가지만 품질과 시장성이 낮아집니다.',
      cashCost: 20000,
    ),
    DecisionOptionData(
      id: 'delay_development',
      label: '3만5천원 · 일정 연장',
      description: '품질을 보강하지만 경쟁사가 움직일 시간이 생깁니다.',
      cashCost: 35000,
    ),
    DecisionOptionData(
      id: 'cancel_development',
      label: '개발 중단',
      description: '추가 손실을 막지만 조직 충격이 큽니다.',
    ),
  ],
);

DecisionCardData _launchReview(int day, {required bool finalReview}) =>
    DecisionCardData(
      id: '${finalReview ? 'final-' : ''}launch-review-$day',
      category: '출시 심사',
      title: finalReview ? '완성한 기기를 이제 출시할까?' : '새 휴대기기를 지금 팔기 시작할까?',
      proposer: '한빛통신 이사회',
      body: finalReview
          ? '품질 보강은 끝났지만 경쟁사의 소문이 커졌습니다. 이제 출시하거나 접어야 합니다.'
          : '시제품은 작동하지만 수요는 넓은 범위로만 추정됩니다. 지금 출시하면 빠르지만 품질 위험이 남습니다.',
      createdDay: day,
      dueDay: day + 2,
      requestedFunds: finalReview ? 0 : 40000,
      benefit: '첫 매출과 브랜드 기회',
      risk: '실제 성공은 보장되지 않음 · 출시 후 지원비',
      advisorOpinions: const [
        'CEO: 완벽하지 않아도 시장에서 배울 수 있습니다.',
        '기술자: 조금 더 다듬으면 결함 가능성을 낮출 수 있습니다.',
        '회계사: 연기할수록 현금과 선점 기회가 줄어듭니다.',
      ],
      options: finalReview
          ? const [
              DecisionOptionData(
                id: 'launch_after_delay',
                label: '보강한 제품 출시',
                description: '개선된 품질로 시장 반응을 확인합니다.',
              ),
              DecisionOptionData(
                id: 'cancel_launch',
                label: '출시 취소',
                description: '남은 위험을 피하지만 투자금과 기회를 잃습니다.',
              ),
            ]
          : const [
              DecisionOptionData(
                id: 'launch_now',
                label: '지금 출시',
                description: '선점 기회가 크지만 품질 위험도 남습니다.',
              ),
              DecisionOptionData(
                id: 'delay_launch',
                label: '4만원 · 3일 연기',
                description: '품질은 좋아지지만 비용과 경쟁 위험이 생깁니다.',
                cashCost: 40000,
              ),
              DecisionOptionData(
                id: 'cancel_launch',
                label: '출시 취소',
                description: '추가 위험은 막지만 팀과 브랜드가 흔들립니다.',
              ),
            ],
    );

DecisionCardData _endingCard(int day, String message) => DecisionCardData(
  id: 'story-result-$day-${GameEngine._stableHash(message)}',
  category: '결과 보고',
  title: '선택의 결과가 도착했어요',
  proposer: '시뮬레이션 기록실',
  body: message,
  createdDay: day,
  dueDay: day + 30,
  requestedFunds: 0,
  benefit: '이번 선택의 변화가 저장됩니다.',
  risk: '다음 선택에도 누적 영향을 줍니다.',
  advisorOpinions: const ['기록: 모든 회사명·수치·의견·결과는 게임용 가상 시나리오입니다.'],
  options: const [
    DecisionOptionData(
      id: 'acknowledge',
      label: '결과 확인',
      description: '가상 세계 기록을 닫고 사무실로 돌아갑니다.',
    ),
  ],
);
