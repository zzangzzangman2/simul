import 'dart:math' as math;

import 'market_data.dart';
import 'shareholder_governance.dart';
import 'stable_hash.dart';

enum ListedIndustryArchetype {
  digital,
  chips,
  industrial,
  healthcare,
  consumer,
  finance,
  energy,
  infrastructure,
  media,
  telecom,
  environment,
  trading,
}

class ListedManagementOption {
  const ListedManagementOption({
    required this.id,
    required this.label,
    required this.description,
    required this.riskLabel,
    required this.cashCost,
    required this.durationDays,
    required this.successChancePct,
    required this.revenueDeltaBps,
    required this.expenseDeltaBps,
    required this.immediatePriceImpactBps,
    required this.successPriceImpactBps,
    required this.failurePriceImpactBps,
    required this.innovationDelta,
    required this.operationsDelta,
    required this.brandDelta,
    required this.workforceDelta,
  });

  final String id;
  final String label;
  final String description;
  final String riskLabel;
  final int cashCost;
  final int durationDays;
  final double successChancePct;
  final int revenueDeltaBps;
  final int expenseDeltaBps;
  final int immediatePriceImpactBps;
  final int successPriceImpactBps;
  final int failurePriceImpactBps;
  final int innovationDelta;
  final int operationsDelta;
  final int brandDelta;
  final int workforceDelta;
}

class ListedManagementAgenda {
  const ListedManagementAgenda({
    required this.id,
    required this.quarterKey,
    required this.archetype,
    required this.title,
    required this.question,
    required this.context,
    required this.options,
  });

  final String id;
  final String quarterKey;
  final ListedIndustryArchetype archetype;
  final String title;
  final String question;
  final String context;
  final List<ListedManagementOption> options;
}

class ListedCompanyManagementCatalog {
  const ListedCompanyManagementCatalog._();

  static const supportedSectors = <String>{
    '통신·네트워크',
    '반도체',
    '소프트웨어',
    '조선·기계',
    '자동차',
    '바이오',
    '유통',
    '에너지',
    '항공·우주',
    '디스플레이',
    '금융',
    '미디어',
    '식품',
    '건설',
    '화학·소재',
    '로봇',
    '의료기기',
    '물류',
    '정보보안',
    '전지',
    '게임',
    '생활소비재',
    '정밀기기',
    '인터넷',
    '교육',
    '제약',
    '농업기계',
    '해운',
    '첨단소재',
    '환경',
    '항공운송',
    '호텔·여행',
    '보험',
    '증권',
    '소비자금융',
    '철강',
    '전력·유틸리티',
    '전자·가전',
    '반도체장비',
    '건자재',
    '화장품',
    '엔터테인먼트',
    '방산',
    '정유',
    '전력기기',
    '포장·제지',
    '레저',
    '가구',
    '종합상사',
    '자원개발',
    '금융기술',
  };

  static String quarterKey(DateTime date) =>
      '${date.year}-Q${(date.month - 1) ~/ 3 + 1}';

  static ListedIndustryArchetype archetypeForSector(String sector) {
    if (const {'소프트웨어', '인터넷', '게임', '정보보안', '금융기술'}.contains(sector)) {
      return ListedIndustryArchetype.digital;
    }
    if (const {'반도체', '디스플레이', '전자·가전', '반도체장비', '정밀기기'}.contains(sector)) {
      return ListedIndustryArchetype.chips;
    }
    if (const {
      '조선·기계',
      '자동차',
      '로봇',
      '농업기계',
      '항공·우주',
      '방산',
      '전력기기',
    }.contains(sector)) {
      return ListedIndustryArchetype.industrial;
    }
    if (const {'바이오', '제약', '의료기기'}.contains(sector)) {
      return ListedIndustryArchetype.healthcare;
    }
    if (const {
      '유통',
      '식품',
      '생활소비재',
      '화장품',
      '가구',
      '호텔·여행',
      '레저',
    }.contains(sector)) {
      return ListedIndustryArchetype.consumer;
    }
    if (const {'금융', '보험', '증권', '소비자금융'}.contains(sector)) {
      return ListedIndustryArchetype.finance;
    }
    if (const {
      '에너지',
      '화학·소재',
      '전지',
      '첨단소재',
      '철강',
      '정유',
      '자원개발',
      '전력·유틸리티',
    }.contains(sector)) {
      return ListedIndustryArchetype.energy;
    }
    if (const {'건설', '물류', '해운', '항공운송', '건자재', '포장·제지'}.contains(sector)) {
      return ListedIndustryArchetype.infrastructure;
    }
    if (const {'미디어', '엔터테인먼트', '교육'}.contains(sector)) {
      return ListedIndustryArchetype.media;
    }
    if (sector == '통신·네트워크') return ListedIndustryArchetype.telecom;
    if (sector == '환경') return ListedIndustryArchetype.environment;
    if (sector == '종합상사') return ListedIndustryArchetype.trading;
    return ListedIndustryArchetype.trading;
  }

  static ListedManagementAgenda agendaFor(
    FictionalMarketAsset asset,
    ListedCompanyGovernance company,
    DateTime date,
  ) {
    final quarter = quarterKey(date);
    final archetype = archetypeForSector(asset.sector);
    final themes = _themes(archetype);
    final theme = themes[stableHash31('${asset.id}:$quarter') % themes.length];
    final product1 = asset.products.isEmpty
        ? asset.sector
        : asset.products.first;
    final product2 = asset.products.length < 2 ? product1 : asset.products[1];
    String fill(String value) => value
        .replaceAll('{name}', asset.name)
        .replaceAll('{p1}', product1)
        .replaceAll('{p2}', product2)
        .replaceAll('{sector}', asset.sector);

    final revenue = math.max(100000, company.monthlyRevenue);
    return ListedManagementAgenda(
      id: '${asset.id}-$quarter-${theme.id}',
      quarterKey: quarter,
      archetype: archetype,
      title: fill(theme.title),
      question: fill(theme.question),
      context: asset.summary.isEmpty
          ? '${asset.name}의 ${asset.sector} 사업을 다음 단계로 이끌 선택입니다.'
          : '${asset.name} · ${asset.summary}'
                '${asset.question.isEmpty ? '' : ' · ${asset.question}'}',
      options: <ListedManagementOption>[
        ListedManagementOption(
          id: 'aggressive',
          label: fill(theme.aggressiveLabel),
          description: fill(theme.aggressiveDescription),
          riskLabel: '고위험·고성장',
          cashCost: (revenue * 0.42).round(),
          durationDays: 60,
          successChancePct: 62,
          revenueDeltaBps: 1200,
          expenseDeltaBps: 600,
          immediatePriceImpactBps: 320,
          successPriceImpactBps: 720,
          failurePriceImpactBps: -850,
          innovationDelta: archetype == ListedIndustryArchetype.finance
              ? 8
              : 14,
          operationsDelta: 5,
          brandDelta: 8,
          workforceDelta: -3,
        ),
        ListedManagementOption(
          id: 'focused',
          label: fill(theme.focusedLabel),
          description: fill(theme.focusedDescription),
          riskLabel: '균형 투자',
          cashCost: (revenue * 0.2).round(),
          durationDays: 45,
          successChancePct: 78,
          revenueDeltaBps: 650,
          expenseDeltaBps: 150,
          immediatePriceImpactBps: 130,
          successPriceImpactBps: 360,
          failurePriceImpactBps: -320,
          innovationDelta: 6,
          operationsDelta: 7,
          brandDelta: 5,
          workforceDelta: 3,
        ),
        ListedManagementOption(
          id: 'defensive',
          label: fill(theme.defensiveLabel),
          description: fill(theme.defensiveDescription),
          riskLabel: '현금·수익 방어',
          cashCost: (revenue * 0.06).round(),
          durationDays: 30,
          successChancePct: 90,
          revenueDeltaBps: 180,
          expenseDeltaBps: -420,
          immediatePriceImpactBps: -60,
          successPriceImpactBps: 150,
          failurePriceImpactBps: -140,
          innovationDelta: -2,
          operationsDelta: 10,
          brandDelta: -1,
          workforceDelta: -5,
        ),
      ],
    );
  }

  static List<_ManagementTheme> _themes(ListedIndustryArchetype archetype) =>
      switch (archetype) {
        ListedIndustryArchetype.digital => const <_ManagementTheme>[
          _ManagementTheme(
            'ai-platform',
            '{p1} AI 전환',
            '{p1}을 차세대 AI 플랫폼으로 재설계할까요?',
            '전사 AI 베팅',
            '핵심 인력을 재배치하고 {p1} 전체를 AI 중심으로 다시 만듭니다.',
            '유료 기능부터 전환',
            '{p1}의 수익 기능에만 AI를 붙여 검증된 고객부터 전환합니다.',
            '서버비 절감',
            '신규 기능을 늦추고 {p1} 인프라와 운영 인력을 최적화합니다.',
          ),
          _ManagementTheme(
            'global-launch',
            '{p2} 글로벌 출시',
            '국내에서 검증된 {p2}를 어느 속도로 해외에 내보낼까요?',
            '동시 12개국 출시',
            '대규모 마케팅과 현지화를 묶어 {p2}의 시장을 단숨에 넓힙니다.',
            '핵심 3개국 공략',
            '반응이 좋은 세 나라에서 {p2}의 가격과 콘텐츠를 검증합니다.',
            '국내 ARPU 집중',
            '해외 진출을 미루고 기존 고객의 결제율과 유지율을 높입니다.',
          ),
          _ManagementTheme(
            'ecosystem',
            '개발자 생태계 개방',
            '{name}의 기술을 외부 파트너에게 얼마나 열까요?',
            '플랫폼 전면 개방',
            '{p1} API와 수익배분 체계를 공개해 외부 생태계를 선점합니다.',
            '인증 파트너제',
            '선별한 기업에만 {p1} 연동 권한을 주고 품질을 관리합니다.',
            '폐쇄형 유지',
            '외부 개방 대신 내부 제품 통합과 비용 통제에 집중합니다.',
          ),
        ],
        ListedIndustryArchetype.chips => const <_ManagementTheme>[
          _ManagementTheme(
            'fab',
            '{p1} 생산능력 증설',
            '수요 전망을 믿고 설비 투자를 앞당길까요?',
            '신공장 선제 착공',
            '{p1} 전용 생산라인을 먼저 지어 다음 사이클의 공급권을 잡습니다.',
            '병목공정만 증설',
            '수율을 제한하는 공정에 집중 투자해 납기를 줄입니다.',
            '외주·재고 조정',
            '대규모 증설 없이 외주와 재고 회전으로 현금을 지킵니다.',
          ),
          _ManagementTheme(
            'yield',
            '{p2} 수율 전쟁',
            '{p2}의 수율과 출시 속도 중 무엇을 우선할까요?',
            '차세대 공정 직행',
            '현재 세대를 건너뛰고 고난도 차세대 공정에 연구진을 집중합니다.',
            '수율 개선 TF',
            '양산 데이터를 모아 불량 원인을 제거하고 고객 신뢰를 높입니다.',
            '검증 공정 연장',
            '새 공정 도입을 늦추고 검증된 라인의 원가를 낮춥니다.',
          ),
          _ManagementTheme(
            'customer',
            '대형 고객 전용칩',
            '{name}이 단일 대형 고객의 맞춤 주문을 받아야 할까요?',
            '전용라인 계약',
            '공장 한 라인을 {p1} 맞춤형 생산에 묶고 장기 공급계약을 노립니다.',
            '공용 설계 제안',
            '맞춤 요구를 공용 제품에 반영해 다른 고객에게도 판매합니다.',
            '고객 분산 유지',
            '단일 고객 의존을 피하고 기존 제품의 마진과 공급 안정에 집중합니다.',
          ),
        ],
        ListedIndustryArchetype.industrial => const <_ManagementTheme>[
          _ManagementTheme(
            'new-model',
            '{p1} 차세대 모델',
            '{p1}의 개발 범위와 출시 시기를 결정해야 합니다.',
            '완전 신형 플랫폼',
            '설계·공장·서비스를 동시에 바꿔 경쟁사보다 한 세대 앞섭니다.',
            '핵심 모듈 교체',
            '{p1}의 동력·제어 모듈을 개선해 고객 체감 성능을 높입니다.',
            '현행 모델 원가혁신',
            '신형 개발을 늦추고 부품 공용화와 공정 단축에 집중합니다.',
          ),
          _ManagementTheme(
            'factory',
            '스마트공장 전환',
            '{name} 생산현장의 자동화 수준을 어디까지 높일까요?',
            '무인공장 구축',
            '로봇과 디지털트윈을 전 공정에 넣어 생산방식을 바꿉니다.',
            '위험공정 자동화',
            '품질과 안전 문제가 큰 공정부터 자동화해 현장 저항을 낮춥니다.',
            '인력 재배치',
            '설비 투자를 줄이고 교대·조달·정비 체계를 정리합니다.',
          ),
          _ManagementTheme(
            'export',
            '{p2} 수출 수주전',
            '대형 해외 발주처에 어떤 조건을 제시할까요?',
            '가격파괴 패키지',
            '초기 마진을 낮추고 금융·정비까지 묶어 시장을 선점합니다.',
            '기술·납기 승부',
            '{p2} 성능 보증과 빠른 납기를 앞세워 적정 마진을 지킵니다.',
            '고수익 주문 선별',
            '저가 수주를 포기하고 기존 고객과 정비 매출에 집중합니다.',
          ),
        ],
        ListedIndustryArchetype.healthcare => const <_ManagementTheme>[
          _ManagementTheme(
            'trial',
            '{p1} 임상·허가 전략',
            '{p1} 개발을 얼마나 공격적으로 진행할까요?',
            '글로벌 임상 동시 진행',
            '국내외 임상을 병렬로 열어 성공 시 시장 선점을 노립니다.',
            '적응증 하나에 집중',
            '성공 가능성이 높은 환자군부터 효능과 안전성을 입증합니다.',
            '공동개발·기술이전',
            '개발비를 줄이고 파트너에게 위험과 미래 수익을 나눕니다.',
          ),
          _ManagementTheme(
            'pipeline',
            '연구 파이프라인 재편',
            '{name}의 연구비를 어떤 후보에 집중할까요?',
            '차세대 후보 올인',
            '{p2} 후속 기술에 연구진과 자금을 집중해 큰 성공을 노립니다.',
            '후보군 단계별 검증',
            '작은 실험으로 후보를 걸러 실패 비용을 통제합니다.',
            '판매 제품 강화',
            '초기 연구를 줄이고 이미 허가된 제품의 생산성과 영업을 높입니다.',
          ),
          _ManagementTheme(
            'access',
            '가격·환자 접근성',
            '{p1}의 가격과 공급 정책을 결정해야 합니다.',
            '시장 확대 가격',
            '마진을 낮춰 병원 채택과 환자 접근성을 빠르게 넓힙니다.',
            '성과기반 계약',
            '치료 성과에 따라 가격을 받는 계약으로 신뢰를 쌓습니다.',
            '프리미엄 가격 유지',
            '공급량을 통제하고 고마진 전문 시장에 집중합니다.',
          ),
        ],
        ListedIndustryArchetype.consumer => const <_ManagementTheme>[
          _ManagementTheme(
            'brand',
            '{p1} 브랜드 리뉴얼',
            '고객에게 익숙한 {p1}을 얼마나 크게 바꿀까요?',
            '전면 리브랜딩',
            '제품·매장·광고를 한 번에 바꿔 젊은 고객층을 공략합니다.',
            '대표 제품 리뉴얼',
            '{p1}의 품질과 패키지를 개선하고 반응을 확인합니다.',
            '가격·SKU 정리',
            '저수익 품목을 줄이고 잘 팔리는 제품의 마진을 지킵니다.',
          ),
          _ManagementTheme(
            'stores',
            '판매망 확장',
            '{p2}를 어떤 채널에서 키울까요?',
            '직영점 대규모 출점',
            '핵심 상권을 선점하고 {p2} 체험형 매장을 동시에 엽니다.',
            '온라인·팝업 실험',
            '지역별 수요를 작게 검증한 뒤 잘 되는 채널만 늘립니다.',
            '기존점 효율화',
            '신규 출점을 멈추고 임대료·재고·인력을 최적화합니다.',
          ),
          _ManagementTheme(
            'premium',
            '{p1} 가격 포지셔닝',
            '원가 상승을 가격과 제품에 어떻게 반영할까요?',
            '프리미엄 라인 출시',
            '고급 원료와 대형 캠페인으로 더 높은 가격대를 만듭니다.',
            '용량·구성 차별화',
            '고객별 선택지를 늘려 가격 인상 충격을 분산합니다.',
            '원가 절감형 유지',
            '가격을 지키는 대신 포장·물류·판촉 비용을 줄입니다.',
          ),
        ],
        ListedIndustryArchetype.finance => const <_ManagementTheme>[
          _ManagementTheme(
            'credit',
            '대출·인수 심사 기준',
            '성장과 건전성 사이에서 위험 한도를 정해야 합니다.',
            '공격적 한도 확대',
            '신규 고객과 고수익 자산을 빠르게 늘려 점유율을 노립니다.',
            '데이터 기반 선별',
            '신용모형을 고도화해 우량 고객의 승인율만 높입니다.',
            '위험자산 축소',
            '충당금과 현금을 늘리고 고위험 익스포저를 줄입니다.',
          ),
          _ManagementTheme(
            'app',
            '{p1} 디지털 전환',
            '지점과 앱에 투자할 자원을 어떻게 배분할까요?',
            '모바일 금융사 전환',
            '핵심 업무와 고객 접점을 앱 중심으로 전면 재설계합니다.',
            '고객 여정 개선',
            '가입·상담·청구 같은 불편한 절차부터 자동화합니다.',
            '지점 통폐합',
            '신규 개발보다 중복 지점과 시스템 유지비를 줄입니다.',
          ),
          _ManagementTheme(
            'capital',
            '자본 배분',
            '{name}의 여유자본을 어디에 쓸까요?',
            '대형 M&A 추진',
            '새 고객기반을 얻기 위해 경쟁 금융사를 인수합니다.',
            '핵심사업 증자',
            '수익성이 검증된 {p2} 조직에 자본을 집중합니다.',
            '자사주·배당 확대',
            '성장을 늦추고 주주환원과 자본비율을 높입니다.',
          ),
        ],
        ListedIndustryArchetype.energy => const <_ManagementTheme>[
          _ManagementTheme(
            'capacity',
            '{p1} 생산설비 투자',
            '원자재 사이클을 보고 생산능력을 늘릴까요?',
            '대형 설비 선제투자',
            '수요 회복 전에 {p1} 생산능력을 크게 늘려 원가 우위를 노립니다.',
            '고효율 설비 개조',
            '기존 라인의 에너지 사용과 수율을 개선합니다.',
            '가동률·재고 축소',
            '증설을 미루고 저수익 설비와 재고를 정리합니다.',
          ),
          _ManagementTheme(
            'green',
            '저탄소 전환',
            '{name}의 탄소 비용에 어떻게 대응할까요?',
            '친환경 사업 전환',
            '{p2}와 재생에너지에 대규모 자본을 넣어 사업구조를 바꿉니다.',
            '공정 배출 감축',
            '고배출 공정부터 교체해 규제비용과 에너지비를 낮춥니다.',
            '배출권·장기계약',
            '설비 교체를 늦추고 계약으로 비용 변동성을 막습니다.',
          ),
          _ManagementTheme(
            'resource',
            '원료 조달권 확보',
            '{p1} 원료 가격 변동을 어떻게 통제할까요?',
            '해외 광구·공급사 인수',
            '원료부터 제품까지 수직계열화해 공급망을 장악합니다.',
            '장기 공급계약',
            '복수 공급처와 가격 공식을 묶어 안정성을 높입니다.',
            '현물 노출 축소',
            '생산과 재고를 줄여 가격 급락 위험을 피합니다.',
          ),
        ],
        ListedIndustryArchetype.infrastructure => const <_ManagementTheme>[
          _ManagementTheme(
            'project',
            '{p1} 대형 프로젝트 수주',
            '낮은 마진의 초대형 계약에 도전할까요?',
            '컨소시엄 주도 수주',
            '금융과 보증을 묶어 사업 전체의 주도권을 잡습니다.',
            '고수익 구간만 참여',
            '설계·운영 등 {name}이 강한 구간에만 들어갑니다.',
            '신규 수주 선별',
            '저마진 입찰을 줄이고 기존 현장의 원가와 현금을 관리합니다.',
          ),
          _ManagementTheme(
            'fleet',
            '{p2} 운송망 확장',
            '물동량 증가에 앞서 자산을 확보할까요?',
            '선박·차량·거점 대량확보',
            '운송 자산과 물류거점을 동시에 늘려 노선을 선점합니다.',
            '핵심노선 증편',
            '수익성이 검증된 노선과 고객에만 자산을 배치합니다.',
            '임차·가동률 개선',
            '소유자산을 늘리지 않고 임차와 배차 최적화로 대응합니다.',
          ),
          _ManagementTheme(
            'safety',
            '안전·품질 투자',
            '{name} 현장의 사고와 납기 위험을 어떻게 줄일까요?',
            '전 현장 디지털 안전망',
            '센서·관제·협력사 교육을 모든 현장에 동시에 도입합니다.',
            '고위험 현장 우선',
            '사고 가능성이 큰 현장을 집중 개선하고 기준을 확산합니다.',
            '관리조직 통합',
            '중복 조직을 줄이고 점검·조달 프로세스를 표준화합니다.',
          ),
        ],
        ListedIndustryArchetype.media => const <_ManagementTheme>[
          _ManagementTheme(
            'content',
            '{p1} 대형 콘텐츠 제작',
            '한 작품에 회사의 흥행 역량을 집중할까요?',
            '글로벌 텐트폴 제작',
            '최고 제작진과 마케팅을 모아 세계 흥행작을 노립니다.',
            '시즌제 파일럿',
            '짧은 파일럿으로 팬 반응을 본 뒤 제작비를 늘립니다.',
            '라이브러리 재활용',
            '신작 투자를 줄이고 기존 IP의 유통·재편집 수익을 키웁니다.',
          ),
          _ManagementTheme(
            'artist',
            '{p2} IP·인재 계약',
            '핵심 창작자와 장기 계약을 체결할까요?',
            '톱 인재 독점계약',
            '높은 선급금을 지급하고 글로벌 활동과 IP 권리를 확보합니다.',
            '프로젝트 공동계약',
            '작품별 성과배분으로 인재와 회사의 위험을 나눕니다.',
            '신인·내부제작 중심',
            '비싼 계약을 피하고 내부 인재와 기존 채널을 활용합니다.',
          ),
          _ManagementTheme(
            'subscription',
            '구독·팬덤 수익화',
            '{name}의 이용자에게 어떤 유료 경험을 제안할까요?',
            '통합 팬 플랫폼',
            '콘텐츠·커뮤니티·커머스를 하나의 글로벌 앱으로 묶습니다.',
            '프리미엄 멤버십',
            '충성 이용자용 독점 콘텐츠와 혜택부터 출시합니다.',
            '광고 효율화',
            '신규 플랫폼 대신 기존 채널의 광고 단가와 편성을 개선합니다.',
          ),
        ],
        ListedIndustryArchetype.telecom => const <_ManagementTheme>[
          _ManagementTheme(
            'network',
            '{p1} 망 투자',
            '수요보다 먼저 차세대 네트워크를 깔까요?',
            '전국망 조기 구축',
            '주파수·기지국·백본을 동시에 투자해 품질 1위를 노립니다.',
            '트래픽 지역 집중',
            '혼잡 지역과 기업고객 구간에만 설비를 우선 배치합니다.',
            '공동망·유지보수',
            '타사 공동망과 장비 수명연장으로 투자비를 줄입니다.',
          ),
          _ManagementTheme(
            'plan',
            '요금제 개편',
            '고객당 매출과 해지율 중 무엇을 우선할까요?',
            '콘텐츠 결합 요금제',
            '{p2}와 데이터 혜택을 묶어 고가 가입자를 늘립니다.',
            '고객별 맞춤 요금',
            '사용량을 분석해 해지 위험 고객에게만 혜택을 제공합니다.',
            '저수익 요금 정리',
            '복잡한 할인과 판매수수료를 줄여 마진을 높입니다.',
          ),
          _ManagementTheme(
            'enterprise',
            '기업 인프라 사업',
            '{name}이 통신망 밖의 기업 시장으로 확장할까요?',
            '클라우드·데이터센터 인수',
            '기업의 네트워크와 컴퓨팅 계약을 한 번에 가져옵니다.',
            '전용망 패키지',
            '통신 강점을 살린 보안·전용망 상품부터 확대합니다.',
            '통신 본업 집중',
            '비통신 확장을 멈추고 망 운영비와 고객지원 비용을 낮춥니다.',
          ),
        ],
        ListedIndustryArchetype.environment => const <_ManagementTheme>[
          _ManagementTheme(
            'plant',
            '{p1} 처리시설 확장',
            '환경 규제 강화에 앞서 처리능력을 늘릴까요?',
            '광역 처리단지 건설',
            '여러 폐기물과 자원을 처리하는 대형 단지를 선제 구축합니다.',
            '고마진 공정 증설',
            '{p1} 중 수요가 확실한 처리공정만 확대합니다.',
            '운영효율 개선',
            '신규시설 대신 기존 설비의 에너지비와 운반비를 줄입니다.',
          ),
          _ManagementTheme(
            'recycle',
            '{p2} 순환자원 사업',
            '폐기물을 원료로 되파는 사업을 얼마나 키울까요?',
            '재활용 밸류체인 인수',
            '수거부터 재생원료 판매까지 관련 회사를 묶어 인수합니다.',
            '대기업 공급계약',
            '품질 기준을 맞춰 재생원료의 장기 구매처를 확보합니다.',
            '처리수수료 중심',
            '원료 가격 위험을 피하고 안정적인 처리계약에 집중합니다.',
          ),
          _ManagementTheme(
            'technology',
            '환경기술 상용화',
            '{name}의 실증기술을 본사업으로 키울까요?',
            '신기술 전면 도입',
            '전 사업장에 신공정을 적용해 규제 시장을 선점합니다.',
            '한 개 사업장 실증',
            '경제성과 안전성을 확인한 뒤 단계적으로 확대합니다.',
            '검증기술 유지',
            '상용화 위험을 피하고 기존 설비의 가동률을 높입니다.',
          ),
        ],
        ListedIndustryArchetype.trading => const <_ManagementTheme>[
          _ManagementTheme(
            'deal',
            '{p1} 글로벌 딜',
            '대형 장기거래에 회사 신용을 얼마나 투입할까요?',
            '공급망 통째로 인수',
            '생산자·물류·판매권을 묶어 거래 주도권을 확보합니다.',
            '판매권 지분투자',
            '핵심 구간에만 자본을 넣고 장기 판매권을 받습니다.',
            '단기거래·헤지',
            '자산 인수 없이 거래마진과 위험관리로 현금을 지킵니다.',
          ),
          _ManagementTheme(
            'country',
            '신흥시장 진출',
            '{p2} 사업을 새로운 국가에 구축할까요?',
            '현지 법인·창고 구축',
            '영업·물류·금융 조직을 한 번에 세워 시장을 선점합니다.',
            '현지 파트너 합작',
            '검증된 파트너와 위험을 나누고 고객망을 활용합니다.',
            '수출중개 유지',
            '고정투자를 피하고 주문이 있는 거래만 수행합니다.',
          ),
          _ManagementTheme(
            'portfolio',
            '사업 포트폴리오 재편',
            '{name}의 자본을 어떤 사업에 집중할까요?',
            '미래사업 대형 인수',
            '기존 현금흐름을 담보로 성장 산업의 회사를 인수합니다.',
            '저수익 사업 교체',
            '수익이 낮은 자산을 팔고 {p1} 공급망에 재투자합니다.',
            '현금 회수',
            '신규 투자를 멈추고 재고·채권·비핵심 지분을 회수합니다.',
          ),
        ],
      };
}

class _ManagementTheme {
  const _ManagementTheme(
    this.id,
    this.title,
    this.question,
    this.aggressiveLabel,
    this.aggressiveDescription,
    this.focusedLabel,
    this.focusedDescription,
    this.defensiveLabel,
    this.defensiveDescription,
  );

  final String id;
  final String title;
  final String question;
  final String aggressiveLabel;
  final String aggressiveDescription;
  final String focusedLabel;
  final String focusedDescription;
  final String defensiveLabel;
  final String defensiveDescription;
}
