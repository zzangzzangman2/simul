part of 'market_data.dart';

/// 화면과 저장 데이터에 쓰이는 모든 회사는 이 목록에서 출발한다.
/// 이름과 사업 내용은 게임 전용 창작이며 실제 법인·종목과 무관하다.
class FictionalCompanyDefinition {
  const FictionalCompanyDefinition({
    required this.id,
    required this.symbol,
    required this.name,
    required this.market,
    required this.sector,
    required this.colorHex,
    required this.initialPrice,
    required this.volatility,
    required this.products,
    required this.summary,
    required this.question,
    this.generation = 0,
    this.parentAssetId,
  });

  final String id;
  final String symbol;
  final String name;
  final String market;
  final String sector;
  final String colorHex;
  final double initialPrice;
  final double volatility;
  final List<String> products;
  final String summary;
  final String question;
  final int generation;
  final String? parentAssetId;
}

const fictionalMainMarket = '미래시장';
const fictionalGrowthMarket = '도전시장';

const fixedFictionalCompanies = <FictionalCompanyDefinition>[
  FictionalCompanyDefinition(
    id: 'hanbit_telecom',
    symbol: '1001',
    name: '한빛통신',
    market: fictionalMainMarket,
    sector: '통신·네트워크',
    colorHex: '#376FD0',
    initialPrice: 28400,
    volatility: 0.025,
    products: ['광대역망', '휴대통신', '위성 단말', '주머니형 통합단말'],
    summary: '도시 통신망과 휴대 단말을 함께 만드는 종합 통신 기업입니다.',
    question: '망 투자와 새 단말 사업을 동시에 감당할 현금이 충분할까?',
  ),
  FictionalCompanyDefinition(
    id: 'dodam_semicon',
    symbol: '1002',
    name: '도담반도체',
    market: fictionalMainMarket,
    sector: '반도체',
    colorHex: '#6E5BC7',
    initialPrice: 41200,
    volatility: 0.034,
    products: ['메모리 칩', '통신 칩', '저전력 연산칩', '미세공정'],
    summary: '메모리와 통신용 칩을 설계·생산하는 기술 기업입니다.',
    question: '설비투자 속도가 다음 반도체 수요를 앞서갈 수 있을까?',
  ),
  FictionalCompanyDefinition(
    id: 'saebyeol_software',
    symbol: '1003',
    name: '새별소프트',
    market: fictionalGrowthMarket,
    sector: '소프트웨어',
    colorHex: '#2B9C8C',
    initialPrice: 17600,
    volatility: 0.042,
    products: ['업무 운영체제', '검색 서비스', '온라인 장터', '원격 저장공간'],
    summary: '기업용 소프트웨어와 인터넷 서비스를 개발하는 성장 기업입니다.',
    question: '빠른 이용자 증가를 실제 이익으로 바꿀 수 있을까?',
  ),
  FictionalCompanyDefinition(
    id: 'cheonghae_heavy',
    symbol: '1004',
    name: '청해중공업',
    market: fictionalMainMarket,
    sector: '조선·기계',
    colorHex: '#3D6680',
    initialPrice: 33700,
    volatility: 0.026,
    products: ['상선', '해양설비', '산업용 로봇팔', '친환경 추진장치'],
    summary: '대형 선박과 산업기계를 수주해 건조하는 중공업 기업입니다.',
    question: '긴 수주잔고가 원가 상승을 견디고 이익으로 남을까?',
  ),
  FictionalCompanyDefinition(
    id: 'mirinae_motors',
    symbol: '1005',
    name: '미리내자동차',
    market: fictionalMainMarket,
    sector: '자동차',
    colorHex: '#C84E4E',
    initialPrice: 52600,
    volatility: 0.027,
    products: ['승용차', '상용차', '전기 구동계', '운전자 보조장치'],
    summary: '내연기관 차량에서 전기 구동 차량으로 영역을 넓히는 완성차 기업입니다.',
    question: '새 구동 기술이 기존 생산망의 부담을 넘어설 수 있을까?',
  ),
  FictionalCompanyDefinition(
    id: 'taesung_bio',
    symbol: '1006',
    name: '태성바이오',
    market: fictionalGrowthMarket,
    sector: '바이오',
    colorHex: '#C04F86',
    initialPrice: 13200,
    volatility: 0.061,
    products: ['면역질환 신약', '항암 후보물질', '유전자 진단', '백신 플랫폼'],
    summary: '후보물질 발굴부터 임상시험까지 도전하는 신약 개발 기업입니다.',
    question: '임상 성공 가능성과 남은 연구자금을 어떻게 판단해야 할까?',
  ),
  FictionalCompanyDefinition(
    id: 'onnuri_retail',
    symbol: '1007',
    name: '온누리유통',
    market: fictionalMainMarket,
    sector: '유통',
    colorHex: '#E17A32',
    initialPrice: 24800,
    volatility: 0.022,
    products: ['백화점', '생활매장', '온라인 주문', '자체 결제망'],
    summary: '전국 매장과 온라인 주문망을 잇는 생활 유통 기업입니다.',
    question: '매장 확장이 재고와 부채 부담보다 큰 현금흐름을 만들까?',
  ),
  FictionalCompanyDefinition(
    id: 'haedam_energy',
    symbol: '1008',
    name: '해담에너지',
    market: fictionalMainMarket,
    sector: '에너지',
    colorHex: '#D19A23',
    initialPrice: 36100,
    volatility: 0.029,
    products: ['도시가스', '발전소', '태양광 모듈', '수소 저장'],
    summary: '기존 발전과 차세대 에너지 투자를 병행하는 에너지 기업입니다.',
    question: '연료가격과 규제가 바뀌어도 발전 수익을 지킬 수 있을까?',
  ),
  FictionalCompanyDefinition(
    id: 'narae_aerospace',
    symbol: '1009',
    name: '나래항공',
    market: fictionalGrowthMarket,
    sector: '항공·우주',
    colorHex: '#557DB5',
    initialPrice: 21900,
    volatility: 0.045,
    products: ['지역 항공기', '항공 엔진부품', '소형 발사체', '저궤도 위성'],
    summary: '항공기 부품에서 위성과 발사체로 도전하는 항공우주 기업입니다.',
    question: '긴 개발기간을 버틸 수주와 자금 여력이 있을까?',
  ),
  FictionalCompanyDefinition(
    id: 'solbit_display',
    symbol: '1010',
    name: '솔빛디스플레이',
    market: fictionalMainMarket,
    sector: '디스플레이',
    colorHex: '#7E57C2',
    initialPrice: 30500,
    volatility: 0.035,
    products: ['평판 화면', '유기발광 패널', '접히는 화면', '초소형 투사장치'],
    summary: '얇고 밝은 차세대 화면을 양산하는 부품 기업입니다.',
    question: '새 패널 수율이 대규모 고객 주문을 맞출 만큼 안정적일까?',
  ),
  FictionalCompanyDefinition(
    id: 'daon_finance',
    symbol: '1011',
    name: '다온금융',
    market: fictionalMainMarket,
    sector: '금융',
    colorHex: '#315A88',
    initialPrice: 19400,
    volatility: 0.023,
    products: ['기업금융', '가계예금', '온라인 증권', '전자지갑'],
    summary: '은행과 증권 서비스를 함께 운영하는 종합 금융 기업입니다.',
    question: '대출 성장 뒤에 숨어 있는 부실 위험은 어느 정도일까?',
  ),
  FictionalCompanyDefinition(
    id: 'baram_media',
    symbol: '1012',
    name: '바람미디어',
    market: fictionalGrowthMarket,
    sector: '미디어',
    colorHex: '#D65A71',
    initialPrice: 9800,
    volatility: 0.048,
    products: ['방송 채널', '음원 유통', '온라인 영상', '창작자 플랫폼'],
    summary: '방송과 디지털 콘텐츠를 제작·유통하는 미디어 기업입니다.',
    question: '인기 작품 한 편의 성과를 반복 가능한 사업으로 만들 수 있을까?',
  ),
  FictionalCompanyDefinition(
    id: 'pureunmaru_food',
    symbol: '1013',
    name: '푸른마루식품',
    market: fictionalMainMarket,
    sector: '식품',
    colorHex: '#5C8A45',
    initialPrice: 22700,
    volatility: 0.019,
    products: ['가공식품', '냉장 유통', '건강식', '식물성 단백질'],
    summary: '가정용 식품과 건강식 브랜드를 운영하는 소비재 기업입니다.',
    question: '원재료 부담을 브랜드와 제품 가격으로 흡수할 수 있을까?',
  ),
  FictionalCompanyDefinition(
    id: 'aram_construction',
    symbol: '1014',
    name: '아람건설',
    market: fictionalMainMarket,
    sector: '건설',
    colorHex: '#8A6C54',
    initialPrice: 27800,
    volatility: 0.028,
    products: ['주택', '도시철도', '초고층 건물', '스마트도시'],
    summary: '주택과 대형 사회기반시설을 시공하는 건설 기업입니다.',
    question: '수주액보다 현장별 원가와 미수금을 더 잘 관리하고 있을까?',
  ),
  FictionalCompanyDefinition(
    id: 'bora_chemical',
    symbol: '1015',
    name: '보라화학',
    market: fictionalMainMarket,
    sector: '화학·소재',
    colorHex: '#8165A3',
    initialPrice: 32200,
    volatility: 0.026,
    products: ['산업수지', '전자재료', '생분해 소재', '고강도 섬유'],
    summary: '기초 화학제품과 고부가 전자재료를 생산하는 소재 기업입니다.',
    question: '범용제품의 변동성을 신소재 이익이 상쇄할 수 있을까?',
  ),
  FictionalCompanyDefinition(
    id: 'yeoul_robotics',
    symbol: '1016',
    name: '여울로보틱스',
    market: fictionalGrowthMarket,
    sector: '로봇',
    colorHex: '#2F8795',
    initialPrice: 11800,
    volatility: 0.052,
    products: ['공장 로봇', '물류 로봇', '가정용 로봇', '정밀 제어기'],
    summary: '공장 자동화에서 생활 로봇까지 확장하는 로봇 기업입니다.',
    question: '화려한 시제품이 반복 판매와 유지보수 매출로 이어질까?',
  ),
  FictionalCompanyDefinition(
    id: 'jini_medical',
    symbol: '1017',
    name: '진이메디컬',
    market: fictionalGrowthMarket,
    sector: '의료기기',
    colorHex: '#D75563',
    initialPrice: 15400,
    volatility: 0.043,
    products: ['영상진단기', '수술 보조기', '휴대 진단기', '원격진료 장비'],
    summary: '병원용 정밀 장비와 휴대 진단기를 개발하는 의료기기 기업입니다.',
    question: '인허가와 병원 채택 속도가 개발비를 감당할 만큼 빠를까?',
  ),
  FictionalCompanyDefinition(
    id: 'nurim_logistics',
    symbol: '1018',
    name: '누림물류',
    market: fictionalMainMarket,
    sector: '물류',
    colorHex: '#416F7C',
    initialPrice: 18300,
    volatility: 0.021,
    products: ['육상운송', '항만창고', '당일배송', '자동분류센터'],
    summary: '전국 운송망과 창고를 연결하는 종합 물류 기업입니다.',
    question: '물동량 성장보다 유가와 설비비가 더 빨리 오르지는 않을까?',
  ),
  FictionalCompanyDefinition(
    id: 'saemul_security',
    symbol: '1019',
    name: '새물보안',
    market: fictionalGrowthMarket,
    sector: '정보보안',
    colorHex: '#344B72',
    initialPrice: 10600,
    volatility: 0.049,
    products: ['방화벽', '암호모듈', '침입탐지', '생체인증'],
    summary: '기업과 공공기관의 정보망을 지키는 보안 기술 기업입니다.',
    question: '보안 사고가 성장 기회가 될까, 신뢰 훼손이 될까?',
  ),
  FictionalCompanyDefinition(
    id: 'moa_battery',
    symbol: '1020',
    name: '모아전지',
    market: fictionalGrowthMarket,
    sector: '전지',
    colorHex: '#4E9B62',
    initialPrice: 14300,
    volatility: 0.047,
    products: ['소형 충전지', '차량용 전지', '에너지 저장장치', '고체 전해질'],
    summary: '휴대기기용 전지에서 차량·전력 저장장치로 확장하는 기업입니다.',
    question: '에너지 밀도 향상이 안전성과 양산수율을 함께 지킬까?',
  ),
  FictionalCompanyDefinition(
    id: 'onbit_games',
    symbol: '1021',
    name: '온빛게임즈',
    market: fictionalGrowthMarket,
    sector: '게임',
    colorHex: '#E05F8F',
    initialPrice: 8900,
    volatility: 0.058,
    products: ['PC 게임', '온라인 세계', '휴대 게임', '가상현실 콘텐츠'],
    summary: '온라인 놀이공간과 자체 캐릭터를 만드는 게임 기업입니다.',
    question: '새 작품 흥행 뒤에도 이용자와 결제 매출이 남을까?',
  ),
  FictionalCompanyDefinition(
    id: 'gayeon_living',
    symbol: '1022',
    name: '가연생활',
    market: fictionalMainMarket,
    sector: '생활소비재',
    colorHex: '#C9778C',
    initialPrice: 21100,
    volatility: 0.020,
    products: ['생활용품', '화장품', '건강관리', '친환경 포장'],
    summary: '매일 쓰는 생활용품과 미용 브랜드를 운영하는 소비재 기업입니다.',
    question: '브랜드 충성도가 유통 경쟁과 광고비 상승을 이겨낼까?',
  ),
  FictionalCompanyDefinition(
    id: 'raon_precision',
    symbol: '1023',
    name: '라온정밀',
    market: fictionalMainMarket,
    sector: '정밀기기',
    colorHex: '#58758F',
    initialPrice: 34800,
    volatility: 0.025,
    products: ['공작기계', '카메라 모듈', '센서', '나노 계측기'],
    summary: '산업용 정밀장비와 전자 센서를 공급하는 부품 기업입니다.',
    question: '소수 대형 고객 의존도를 신사업이 낮출 수 있을까?',
  ),
  FictionalCompanyDefinition(
    id: 'eunha_networks',
    symbol: '1024',
    name: '은하네트웍스',
    market: fictionalGrowthMarket,
    sector: '인터넷',
    colorHex: '#3A78B4',
    initialPrice: 12100,
    volatility: 0.051,
    products: ['인터넷 포털', '전자우편', '지도 서비스', '개인 방송'],
    summary: '검색과 커뮤니티를 중심으로 이용자를 모으는 인터넷 기업입니다.',
    question: '이용자 수가 서버비와 마케팅비보다 빨리 수익으로 바뀔까?',
  ),
  FictionalCompanyDefinition(
    id: 'irum_education',
    symbol: '1025',
    name: '이룸교육',
    market: fictionalGrowthMarket,
    sector: '교육',
    colorHex: '#D5893E',
    initialPrice: 9700,
    volatility: 0.036,
    products: ['학습지', '입시교육', '온라인 강의', '맞춤 학습엔진'],
    summary: '교재와 온라인 학습 서비스를 함께 제공하는 교육 기업입니다.',
    question: '온라인 전환이 기존 교재 매출을 잠식하지 않고 성장할까?',
  ),
  FictionalCompanyDefinition(
    id: 'byeolha_pharma',
    symbol: '1026',
    name: '별하제약',
    market: fictionalMainMarket,
    sector: '제약',
    colorHex: '#B94B6B',
    initialPrice: 26400,
    volatility: 0.038,
    products: ['전문의약품', '희귀질환 치료제', '복제약', '약물전달 기술'],
    summary: '안정적인 의약품 판매로 신약 연구비를 마련하는 제약 기업입니다.',
    question: '기존 약의 현금흐름이 다음 신약의 실패 가능성을 견딜까?',
  ),
  FictionalCompanyDefinition(
    id: 'dure_agritech',
    symbol: '1027',
    name: '두레농기',
    market: fictionalMainMarket,
    sector: '농업기계',
    colorHex: '#66884F',
    initialPrice: 16800,
    volatility: 0.024,
    products: ['농기계', '자동관수', '수확 로봇', '작물 데이터'],
    summary: '농기계에 센서와 자동제어 기술을 붙이는 농업 기술 기업입니다.',
    question: '농촌의 실제 비용 절감이 새 장비 가격을 정당화할까?',
  ),
  FictionalCompanyDefinition(
    id: 'maru_shipping',
    symbol: '1028',
    name: '마루해운',
    market: fictionalMainMarket,
    sector: '해운',
    colorHex: '#32657A',
    initialPrice: 23800,
    volatility: 0.035,
    products: ['컨테이너선', '벌크선', '항만터미널', '저탄소 선대'],
    summary: '세계 항로에서 화물을 운송하는 해운 기업입니다.',
    question: '운임 호황 때 늘린 선박이 불황의 부채가 되지는 않을까?',
  ),
  FictionalCompanyDefinition(
    id: 'seum_materials',
    symbol: '1029',
    name: '세움소재',
    market: fictionalGrowthMarket,
    sector: '첨단소재',
    colorHex: '#6D6A9C',
    initialPrice: 12700,
    volatility: 0.044,
    products: ['탄소복합재', '반도체 기판', '초경량 합금', '투명 전극'],
    summary: '전자·항공 산업에 쓰이는 경량 고기능 소재를 개발하는 기업입니다.',
    question: '실험실 성능을 고객이 요구하는 수율과 가격으로 양산할 수 있을까?',
  ),
  FictionalCompanyDefinition(
    id: 'chorong_environment',
    symbol: '1030',
    name: '초롱환경',
    market: fictionalGrowthMarket,
    sector: '환경',
    colorHex: '#3C956E',
    initialPrice: 8600,
    volatility: 0.039,
    products: ['수처리', '폐기물 재활용', '탄소 포집', '환경 측정망'],
    summary: '물과 폐기물을 정화하고 자원으로 되돌리는 환경 기업입니다.',
    question: '정책 지원이 줄어도 기술과 계약만으로 수익을 낼 수 있을까?',
  ),
];

const _spinoffBlueprints = <FictionalCompanyDefinition>[
  FictionalCompanyDefinition(
    id: 'hanbit_semicon',
    symbol: '2001',
    name: '한빛반도체',
    market: fictionalGrowthMarket,
    sector: '반도체',
    colorHex: '#4A63BF',
    initialPrice: 11600,
    volatility: 0.055,
    products: ['통신 칩', '모바일 연산칩', '저전력 모뎀'],
    summary: '한빛통신의 단말용 칩 조직이 독립한 반도체 기업입니다.',
    question: '모회사 주문을 넘어 외부 고객을 확보할 수 있을까?',
    generation: 1,
    parentAssetId: 'hanbit_telecom',
  ),
  FictionalCompanyDefinition(
    id: 'taesung_newdrug',
    symbol: '2002',
    name: '태성신약',
    market: fictionalGrowthMarket,
    sector: '바이오',
    colorHex: '#B43F78',
    initialPrice: 8400,
    volatility: 0.072,
    products: ['면역 신약', '항암 신약', '임상 플랫폼'],
    summary: '태성바이오의 임상 후보물질 부문이 독립한 신약 기업입니다.',
    question: '독립한 연구조직이 임상과 자금조달을 함께 완주할까?',
    generation: 1,
    parentAssetId: 'taesung_bio',
  ),
  FictionalCompanyDefinition(
    id: 'cheonghae_robotics',
    symbol: '2003',
    name: '청해로보틱스',
    market: fictionalGrowthMarket,
    sector: '로봇',
    colorHex: '#427384',
    initialPrice: 12900,
    volatility: 0.051,
    products: ['용접 로봇', '물류 로봇', '해양 무인기'],
    summary: '청해중공업의 자동화 조직이 분사한 산업 로봇 기업입니다.',
    question: '모회사 현장을 넘어 범용 로봇 시장을 열 수 있을까?',
    generation: 1,
    parentAssetId: 'cheonghae_heavy',
  ),
  FictionalCompanyDefinition(
    id: 'saebyeol_cloud',
    symbol: '2004',
    name: '새별클라우드',
    market: fictionalGrowthMarket,
    sector: '인터넷',
    colorHex: '#278E85',
    initialPrice: 9700,
    volatility: 0.059,
    products: ['원격 저장공간', '서버 임대', '온라인 업무도구'],
    summary: '새별소프트의 원격 서버 사업이 독립한 인터넷 인프라 기업입니다.',
    question: '빠른 서버 증설이 장기 계약과 이익으로 이어질까?',
    generation: 1,
    parentAssetId: 'saebyeol_software',
  ),
  FictionalCompanyDefinition(
    id: 'mirinae_battery',
    symbol: '2005',
    name: '미리내전지',
    market: fictionalGrowthMarket,
    sector: '전지',
    colorHex: '#AF5548',
    initialPrice: 15100,
    volatility: 0.057,
    products: ['차량용 전지', '급속충전 장치', '전지 관리칩'],
    summary: '미리내자동차의 전기 구동용 전지 부문이 독립한 기업입니다.',
    question: '모회사 차종 외에도 선택받는 전지 기술을 만들 수 있을까?',
    generation: 1,
    parentAssetId: 'mirinae_motors',
  ),
  FictionalCompanyDefinition(
    id: 'onnuri_pay',
    symbol: '2006',
    name: '온누리결제',
    market: fictionalGrowthMarket,
    sector: '금융기술',
    colorHex: '#D36E35',
    initialPrice: 7300,
    volatility: 0.063,
    products: ['온라인 결제', '가맹점 단말', '전자지갑'],
    summary: '온누리유통의 자체 결제망이 독립한 금융기술 기업입니다.',
    question: '모회사 매장 밖에서도 신뢰받는 결제망이 될 수 있을까?',
    generation: 1,
    parentAssetId: 'onnuri_retail',
  ),
];

enum NewsTone { breaking, shock, launch, calm, weekend, holiday, milestone }

class FictionalMarketEvent {
  const FictionalMarketEvent({
    required this.id,
    required this.date,
    required this.companyId,
    required this.companyName,
    required this.sector,
    required this.stage,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.signal,
    required this.reportHint,
    required this.revealMinute,
    required this.impactPct,
    required this.tone,
    this.sectorImpactPcts = const <String, double>{},
  });

  final String id;
  final String date;
  final String companyId;
  final String companyName;
  final String sector;
  final int stage;
  final String eyebrow;
  final String title;
  final String body;
  final String signal;
  final String reportHint;
  final int revealMinute;
  final double impactPct;
  final NewsTone tone;
  final Map<String, double> sectorImpactPcts;

  Map<String, dynamic> toJson({bool includeHidden = true}) => {
    'id': id,
    'date': date,
    'companyId': companyId,
    'companyName': companyName,
    'sector': sector,
    'stage': stage,
    'eyebrow': eyebrow,
    'title': title,
    'body': body,
    'signal': signal,
    'revealMinute': revealMinute,
    'tone': tone.name,
    if (includeHidden) 'reportHint': reportHint,
    if (includeHidden) 'impactPct': impactPct,
    if (includeHidden && sectorImpactPcts.isNotEmpty)
      'sectorImpactPcts': sectorImpactPcts,
  };
}

class _SpinoffPlan {
  const _SpinoffPlan({required this.definition, required this.date});
  final FictionalCompanyDefinition definition;
  final DateTime date;
}

class _GeneratedListingPlan {
  const _GeneratedListingPlan({
    required this.definition,
    required this.listingDate,
    this.delistingDate,
  });

  final FictionalCompanyDefinition definition;
  final DateTime listingDate;
  final DateTime? delistingDate;
}

const _newCompanyPrefixes = <String>[
  '가람',
  '겨레',
  '누리',
  '다솜',
  '라온',
  '마중',
  '보담',
  '새론',
  '아라',
  '여민',
  '온새미',
  '윤슬',
  '이든',
  '자람',
  '차오름',
  '큰솔',
  '파란',
  '해온',
  '하람',
  '희망',
];

String _listingSuffix(String sector) => switch (sector) {
  '반도체' => '칩스',
  '소프트웨어' => '시스템즈',
  '조선·기계' => '기공',
  '자동차' => '모빌리티',
  '바이오' => '바이오랩',
  '유통' => '커머스',
  '에너지' => '파워',
  '항공·우주' => '스페이스',
  '디스플레이' => '비전',
  '금융' => '캐피탈',
  '미디어' => '콘텐츠',
  '식품' => '푸드',
  '건설' => '디벨롭',
  '화학·소재' => '머티리얼',
  '로봇' => '오토메이션',
  '의료기기' => '헬스텍',
  '물류' => '로지스',
  '정보보안' => '시큐어',
  '전지' => '에너지셀',
  '게임' => '인터랙티브',
  '생활소비재' => '리빙',
  '정밀기기' => '인스트루먼트',
  '인터넷' => '네트',
  '교육' => '러닝',
  '제약' => '파마',
  '농업기계' => '애그리텍',
  '해운' => '쉬핑',
  '첨단소재' => '컴포지트',
  '환경' => '에코텍',
  _ => '테크',
};

final _listingPlanCache = <String, List<_GeneratedListingPlan>>{};
final _spinoffPlanCache = <String, List<_SpinoffPlan>>{};
final _dailyEventCache = <String, List<FictionalMarketEvent>>{};

List<_GeneratedListingPlan> _generatedListingPlans(String seed) {
  final cached = _listingPlanCache[seed];
  if (cached != null) return cached;
  final plans = <_GeneratedListingPlan>[];
  var serial = 0;
  for (var year = 2000; year <= 2010; year++) {
    final count = 4 + _fictionalHash('$seed:ipo-count:$year') % 5;
    for (var index = 0; index < count; index++) {
      serial += 1;
      final source =
          fixedFictionalCompanies[_fictionalHash(
                '$seed:ipo-sector:$year:$index',
              ) %
              fixedFictionalCompanies.length];
      final prefix =
          _newCompanyPrefixes[_fictionalHash('$seed:ipo-prefix:$year:$index') %
              _newCompanyPrefixes.length];
      final name = '$prefix${_listingSuffix(source.sector)}';
      final listingDay =
          22 + _fictionalHash('$seed:ipo-day:$year:$index') % 320;
      final listingDate = _nextFictionalTradingDay(
        DateTime(year, 1, 1).add(Duration(days: listingDay)),
      );
      final delistRoll = _fictionalUnit(seed, 'delist:$year:$index');
      final rawDelistingDate = listingDate.add(
        Duration(
          days: 620 + _fictionalHash('$seed:delist-day:$year:$index') % 1250,
        ),
      );
      final delistingDate =
          delistRoll < 0.18 && rawDelistingDate.isBefore(DateTime(2010, 12, 20))
          ? _nextFictionalTradingDay(rawDelistingDate)
          : null;
      final id = 'ipo_${year}_${serial.toString().padLeft(3, '0')}';
      plans.add(
        _GeneratedListingPlan(
          definition: FictionalCompanyDefinition(
            id: id,
            symbol: '3${serial.toString().padLeft(3, '0')}',
            name: name,
            market: fictionalGrowthMarket,
            sector: source.sector,
            colorHex: source.colorHex,
            initialPrice: 3200 + _fictionalHash('$seed:ipo-price:$id') % 23800,
            volatility:
                0.034 + _fictionalUnit(seed, 'ipo-volatility:$id') * 0.044,
            products: source.products,
            summary:
                '${source.sector} 분야의 ${source.products.first}에서 출발해 상장한 신생 기업입니다.',
            question: '상장으로 마련한 자금이 실제 고객과 이익으로 이어질까?',
            generation: 1,
          ),
          listingDate: listingDate,
          delistingDate: delistingDate,
        ),
      );
    }
  }
  final result = List<_GeneratedListingPlan>.unmodifiable(plans);
  _listingPlanCache[seed] = result;
  return result;
}

int _fictionalHash(String input) {
  var hash = 2166136261;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash;
}

double _fictionalUnit(String seed, String key) =>
    _fictionalHash('$seed:$key') / 0x7fffffff;

double _fictionalSigned(String seed, String key) =>
    _fictionalUnit(seed, key) * 2 - 1;

DateTime _nextFictionalTradingDay(DateTime date) {
  var next = DateTime(date.year, date.month, date.day);
  while (!isMarketTradingDay(next)) {
    next = next.add(const Duration(days: 1));
  }
  return next;
}

List<_SpinoffPlan> _spinoffPlans(String seed) {
  final cached = _spinoffPlanCache[seed];
  if (cached != null) return cached;
  final plans = <_SpinoffPlan>[];
  for (var index = 0; index < _spinoffBlueprints.length; index++) {
    final definition = _spinoffBlueprints[index];
    final selected =
        index < 3 ||
        _fictionalUnit(seed, 'spinoff-select-${definition.id}') > 0.38;
    if (!selected) continue;
    final offset =
        720 + _fictionalHash('$seed:spinoff-date:${definition.id}') % 2600;
    final rawDate = DateTime(2000, 1, 1).add(Duration(days: offset));
    final earliestDate = DateTime(
      fictionalCompanyEarliestListingYear(definition),
      1,
      1,
    );
    final date = _nextFictionalTradingDay(
      rawDate.isBefore(earliestDate) ? earliestDate : rawDate,
    );
    plans.add(_SpinoffPlan(definition: definition, date: date));
  }
  plans.sort((left, right) => left.date.compareTo(right.date));
  final result = List<_SpinoffPlan>.unmodifiable(plans);
  _spinoffPlanCache[seed] = result;
  return result;
}

FictionalCompanyDefinition? fictionalCompanyById(String id) {
  for (final company in [...fixedFictionalCompanies, ..._spinoffBlueprints]) {
    if (company.id == id) return company;
  }
  return null;
}

bool isFictionalMarketAssetId(String id, {required String seed}) {
  if (fictionalCompanyById(id) != null) return true;
  return _generatedListingPlans(seed).any((plan) => plan.definition.id == id);
}

List<String> _allowedArcKinds(FictionalCompanyDefinition company) =>
    switch (company.sector) {
      '조선·기계' || '해운' => const [
        'capacity',
        'contract',
        'safety',
        'finance',
        'competition',
        'regulation',
        'earnings',
        'commodity',
        'currency',
        'labor',
        'supply_chain',
      ],
      '반도체' || '디스플레이' || '정밀기기' || '첨단소재' => const [
        'breakthrough',
        'capacity',
        'contract',
        'safety',
        'competition',
        'finance',
        'earnings',
        'supply_chain',
        'commodity',
        'currency',
        'patent',
        'product_launch',
      ],
      '바이오' || '제약' || '의료기기' => const [
        'breakthrough',
        'regulation',
        'safety',
        'finance',
        'contract',
        'earnings',
        'patent',
        'litigation',
        'product_launch',
      ],
      '자동차' || '전지' || '로봇' || '항공·우주' => const [
        'breakthrough',
        'capacity',
        'contract',
        'safety',
        'regulation',
        'competition',
        'earnings',
        'supply_chain',
        'commodity',
        'currency',
        'labor',
        'patent',
        'product_launch',
      ],
      '소프트웨어' || '인터넷' || '정보보안' || '게임' || '미디어' => const [
        'breakthrough',
        'security',
        'capacity',
        'competition',
        'regulation',
        'finance',
        'earnings',
        'governance',
        'patent',
        'litigation',
        'merger',
        'product_launch',
      ],
      '건설' => const [
        'contract',
        'capacity',
        'safety',
        'finance',
        'regulation',
        'earnings',
        'commodity',
        'currency',
        'labor',
        'governance',
      ],
      '금융' || '금융기술' => const [
        'finance',
        'regulation',
        'security',
        'competition',
        'earnings',
        'governance',
        'litigation',
        'merger',
        'currency',
      ],
      '에너지' || '화학·소재' || '환경' => const [
        'capacity',
        'contract',
        'safety',
        'regulation',
        'finance',
        'breakthrough',
        'earnings',
        'commodity',
        'currency',
        'litigation',
        'product_launch',
      ],
      _ => const [
        'capacity',
        'contract',
        'safety',
        'competition',
        'finance',
        'regulation',
        'earnings',
        'governance',
        'supply_chain',
        'currency',
        'labor',
        'product_launch',
      ],
    };

int _fictionalGreatestCommonDivisor(int left, int right) {
  var a = left.abs();
  var b = right.abs();
  while (b != 0) {
    final remainder = a % b;
    a = b;
    b = remainder;
  }
  return a;
}

List<FictionalMarketArcScenario> _allowedArcScenarios(
  FictionalCompanyDefinition company,
) {
  final allowedKinds = _allowedArcKinds(company).toSet();
  return fictionalMarketArcScenarios
      .where((scenario) => allowedKinds.contains(scenario.kind))
      .toList(growable: false);
}

FictionalMarketArcScenario _arcScenarioForCompany(
  String seed,
  FictionalCompanyDefinition company,
  int arc,
) {
  final kinds = _allowedArcKinds(company);
  final kindStart =
      _fictionalHash('$seed:${company.id}:arc-kind-start') % kinds.length;
  var kindStride =
      1 +
      _fictionalHash('$seed:${company.id}:arc-kind-stride') %
          (kinds.length - 1);
  while (_fictionalGreatestCommonDivisor(kindStride, kinds.length) != 1) {
    kindStride = kindStride % (kinds.length - 1) + 1;
  }
  final kind = kinds[(kindStart + arc * kindStride) % kinds.length];
  final variants = _allowedArcScenarios(
    company,
  ).where((scenario) => scenario.kind == kind).toList(growable: false);
  final variantCycle = arc ~/ kinds.length;
  final variantStart =
      _fictionalHash('$seed:${company.id}:$kind:variant-start') %
      variants.length;
  const coprimeVariantStrides = <int>[1, 3, 5, 7];
  final variantStride =
      coprimeVariantStrides[_fictionalHash(
            '$seed:${company.id}:$kind:variant-stride',
          ) %
          coprimeVariantStrides.length];
  return variants[(variantStart + variantCycle * variantStride) %
      variants.length];
}

List<FictionalCompanyDefinition> _activeFictionalCompanies(
  String seed,
  DateTime date,
) {
  final active = <FictionalCompanyDefinition>[...fixedFictionalCompanies];
  for (final plan in _spinoffPlans(seed)) {
    if (!date.isBefore(plan.date)) active.add(plan.definition);
  }
  for (final plan in _generatedListingPlans(seed)) {
    if (date.isBefore(plan.listingDate)) continue;
    if (plan.delistingDate != null && !date.isBefore(plan.delistingDate!)) {
      continue;
    }
    active.add(plan.definition);
  }
  return active;
}

List<FictionalMarketEvent> _lifecycleEventsForDate(String seed, DateTime date) {
  final dateKey = marketDateKey(date);
  final events = <FictionalMarketEvent>[];
  for (final plan in _generatedListingPlans(seed)) {
    final company = plan.definition;
    if (marketDateKey(plan.listingDate) == dateKey) {
      events.add(
        FictionalMarketEvent(
          id: 'ipo-${company.id}-$dateKey',
          date: dateKey,
          companyId: company.id,
          companyName: company.name,
          sector: company.sector,
          stage: 0,
          eyebrow: '신규 상장',
          title: '${company.name}, 도전시장에 첫 거래 시작',
          body:
              '${company.name}이 공개모집을 마치고 거래를 시작했다. 조달 자금은 ${company.products.first} 투자와 운영자금에 쓰일 예정이다.',
          signal: '상장 첫날의 인기와 회사가 실제로 버는 돈은 다를 수 있습니다.',
          reportHint: '기관 수요와 의무보유 물량, 상장 직후 풀리는 기존 주주 물량을 함께 살펴야 한다.',
          revealMinute: 9 * 60,
          impactPct: 0,
          tone: NewsTone.milestone,
        ),
      );
    }
    if (plan.delistingDate != null &&
        marketDateKey(plan.delistingDate!) == dateKey) {
      events.add(
        FictionalMarketEvent(
          id: 'delisting-${company.id}-$dateKey',
          date: dateKey,
          companyId: company.id,
          companyName: company.name,
          sector: company.sector,
          stage: 3,
          eyebrow: '상장폐지',
          title: '${company.name}, 개선기간 끝에 상장폐지 확정',
          body:
              '감사의견과 계속기업 요건을 회복하지 못해 정규 거래가 끝났다. 남은 자산의 처분가치는 장부가보다 크게 낮을 수 있다.',
          signal: '매매정지 전에 현금흐름·자본잠식·감사의견 경고가 누적됐는지 복기해야 합니다.',
          reportHint: '감사 일정 지연과 자금조달 실패가 겹쳐 계속기업 불확실성이 커지고 있다.',
          revealMinute: 8 * 60 + 30,
          impactPct: -0.65,
          tone: NewsTone.shock,
        ),
      );
    }
  }

  for (final company in _activeFictionalCompanies(seed, date)) {
    final year = date.year;
    if (_fictionalHash('$seed:rights-select:${company.id}:$year') % 100 >= 24) {
      continue;
    }
    final dayOffset =
        18 + _fictionalHash('$seed:rights-day:${company.id}:$year') % 320;
    final actionDate = _nextFictionalTradingDay(
      DateTime(year, 1, 1).add(Duration(days: dayOffset)),
    );
    if (marketDateKey(actionDate) != dateKey) continue;
    final thirdParty =
        _fictionalHash('$seed:rights-method:${company.id}:$year') % 3 == 0;
    final discount =
        12 + _fictionalHash('$seed:rights-discount:${company.id}:$year') % 29;
    events.add(
      FictionalMarketEvent(
        id: 'rights-${company.id}-$year',
        date: dateKey,
        companyId: company.id,
        companyName: company.name,
        sector: company.sector,
        stage: 2,
        eyebrow: '자금 조달',
        title: '${company.name}, ${thirdParty ? '제3자배정' : '주주배정'} 유상증자 결정',
        body:
            '회사는 ${company.products.first} 투자와 차입금 상환을 위해 기준가격보다 약 $discount% 낮은 조건의 신주 발행을 결정했다.',
        signal: '들어오는 현금의 용도와 늘어나는 주식 수를 함께 계산해야 합니다.',
        reportHint: '단기차입과 투자지출이 동시에 늘어 외부자금 조달 가능성이 높아졌다.',
        revealMinute:
            13 * 60 +
            _fictionalHash('$seed:rights-reveal:${company.id}:$year') % 120,
        impactPct: -(0.018 + discount / 1000),
        tone: NewsTone.shock,
      ),
    );
  }
  return events;
}

List<FictionalMarketEvent> fictionalMarketEventsForDate(
  String seed,
  DateTime date,
) {
  final day = date.difference(DateTime(2000, 1, 1)).inDays;
  if (day < 0) return const [];
  final dateKey = marketDateKey(date);
  final cacheKey = '$seed:$dateKey';
  final cached = _dailyEventCache[cacheKey];
  if (cached != null) return cached;
  final events = <FictionalMarketEvent>[
    ..._lifecycleEventsForDate(seed, date),
    ..._historicalCatalystEventsForDate(seed, date),
    ..._eraTechnologyEventsForDate(seed, date),
  ];
  final active = _activeFictionalCompanies(seed, date);
  final spinoffs = _spinoffPlans(seed);
  for (var index = 0; index < spinoffs.length; index++) {
    final plan = spinoffs[index];
    if (marketDateKey(plan.date) == dateKey) {
      final parent = fictionalCompanyById(plan.definition.parentAssetId!)!;
      final material = index.isEven;
      events.add(
        FictionalMarketEvent(
          id: 'spinoff-${plan.definition.id}-$dateKey',
          date: dateKey,
          companyId: parent.id,
          companyName: parent.name,
          sector: parent.sector,
          stage: 3,
          eyebrow: material ? '물적분할' : '인적분할',
          title: '${parent.name}, ${plan.definition.name} 분할·상장 확정',
          body: material
              ? '${parent.name}의 ${plan.definition.products.first} 조직이 자회사로 독립했다. 신설회사 지분은 모회사가 보유하며 기존 주주에게 새 주식이 직접 배정되지 않는다.'
              : '${parent.name}의 ${plan.definition.products.first} 조직이 독립했다. 기존 주주는 정해진 비율로 새 회사 주식을 함께 받는다.',
          signal: material
              ? '물적분할 뒤 자회사 상장은 성장자금과 모회사 주주가치 희석을 함께 봐야 합니다.'
              : '인적분할은 두 회사의 사업가치와 배정비율을 각각 계산해야 합니다.',
          reportHint: '${parent.name} 내부에서 핵심 조직의 독립 회계와 인력 이동이 늘고 있다.',
          revealMinute: 9 * 60 + 5,
          impactPct: 0.045,
          tone: NewsTone.milestone,
        ),
      );
    }
  }

  for (final company in active) {
    final arcLength = 120;
    final arc = day ~/ arcLength;
    final localDay = day % arcLength;
    final offset = _fictionalHash('${company.id}:arc-offset') % 19;
    final stageDays = <int>[7 + offset, 34 + offset, 66 + offset, 96 + offset];
    final stage = stageDays.indexOf(localDay);
    if (stage < 0) continue;
    final scenario = _arcScenarioForCompany(seed, company, arc);
    final availableProducts = fictionalProductsAvailableInYear(
      company,
      date.year,
    );
    final product =
        availableProducts[_fictionalHash(
              '$seed:${company.id}:arc-product:$arc',
            ) %
            availableProducts.length];
    final success =
        _fictionalUnit(seed, '${company.id}:arc-outcome:$arc') >= 0.43;
    final strength =
        0.55 + _fictionalUnit(seed, '${company.id}:arc-strength:$arc') * 0.75;
    events.add(
      _buildArcEvent(
        seed: seed,
        dateKey: dateKey,
        company: company,
        arc: arc,
        stage: stage,
        scenario: scenario,
        product: product,
        success: success,
        strength: strength,
      ),
    );
  }
  events.sort((left, right) => left.revealMinute.compareTo(right.revealMinute));
  final result = List<FictionalMarketEvent>.unmodifiable(events);
  _dailyEventCache[cacheKey] = result;
  return result;
}

FictionalMarketEvent _buildArcEvent({
  required String seed,
  required String dateKey,
  required FictionalCompanyDefinition company,
  required int arc,
  required int stage,
  required FictionalMarketArcScenario scenario,
  required String product,
  required bool success,
  required double strength,
}) {
  final kind = scenario.kind;
  final revealMinute =
      9 * 60 +
      10 +
      _fictionalHash('$seed:${company.id}:reveal:$arc:$stage') % 350;
  final earlySign = _fictionalSigned(seed, '${company.id}:early:$arc') >= 0;
  final direction = stage < 2 ? earlySign : success;
  final kindMultiplier = switch (kind) {
    'merger' => 1.85,
    'litigation' || 'governance' => 1.55,
    'earnings' || 'product_launch' || 'patent' => 1.35,
    'commodity' || 'currency' || 'supply_chain' => 1.2,
    _ => 1.0,
  };
  final magnitude =
      <double>[0.004, 0.012, 0.055, 0.032][stage] * strength * kindMultiplier;
  final impact = direction ? magnitude : -magnitude;
  final isBio = company.sector == '바이오' || company.sector == '제약';
  final year = int.parse(dateKey.substring(0, 4));
  late String eyebrow;
  late String title;
  late String body;
  late String signal;
  late String reportHint;

  if (kind == 'contract' && company.sector == '조선·기계') {
    final vesselTypes = <String>[
      '대형 컨테이너선',
      '원유운반선',
      '벌크선',
      'LNG 운반선',
      if (year >= 2005) '해양 시추지원선',
      if (year >= 2008) '저연비 컨테이너선',
    ];
    final vessel =
        vesselTypes[_fictionalHash('$seed:ship-type:${company.id}:$arc') %
            vesselTypes.length];
    final buyer = const [
      '유럽 정기선사',
      '중동 에너지 운송사',
      '아시아 자원개발사',
      '글로벌 해운 컨소시엄',
      '국영 에너지 기업',
    ][_fictionalHash('$seed:ship-buyer:${company.id}:$arc') % 5];
    final count =
        2 + _fictionalHash('$seed:ship-count:${company.id}:$arc') % 11;
    final value =
        (4 + _fictionalHash('$seed:ship-value:${company.id}:$arc') % 33) * 1000;
    final advance =
        10 + _fictionalHash('$seed:ship-advance:${company.id}:$arc') % 21;
    final delivery =
        18 + _fictionalHash('$seed:ship-delivery:${company.id}:$arc') % 25;
    eyebrow = '선박 수주';
    title = switch (stage) {
      0 => '${company.name}, $buyer $vessel $count척 국제입찰 참여',
      1 => '${company.name}, $vessel 우선협상·선수금 $advance% 조율',
      2 =>
        success
            ? '${company.name}, $vessel $count척·$value억원 수주 확정'
            : '${company.name}, $vessel 가격·납기 협상 결렬',
      _ =>
        success
            ? '${company.name}, 선수금 유입·수주잔고 매출 전환'
            : '${company.name}, 설계비 손실·도크 공백 부담',
    };
    body = switch (stage) {
      0 => '$buyer가 발주한 $vessel $count척 사업에 참여했다. 총사업비와 경쟁사 제안은 공개되지 않았다.',
      1 => '선수금 $advance%, 인도기간 $delivery개월, 원자재 가격조정 조항을 두고 최종 협상이 진행 중이다.',
      2 =>
        success
            ? '총 $value억원 규모 계약이 확정됐다. 선수금과 후판 가격 연동 조항이 향후 이익률을 좌우한다.'
            : '선가와 인도일 조건을 맞추지 못해 계약이 무산됐다. 이미 투입한 설계비 일부가 비용으로 남는다.',
      _ =>
        success
            ? '첫 선수금이 들어오고 건조 공정이 시작됐다. 실제 이익은 후판 가격과 공정 지연 여부에 달렸다.'
            : '후속 수주도 늦어지며 도크 가동률이 떨어졌다. 고정비와 숙련인력 유지 부담이 커졌다.',
    };
    signal = '수주액만 보지 말고 선수금·원가연동·인도기간·지체보상 조항을 확인해야 합니다.';
    reportHint =
        '$vessel 설계인력과 구매 문의가 늘었고 도크 배치가 조정되고 있으나 최종 발주서와 선수금 조건은 공개되지 않았다.';
  } else if (kind == 'contract' && company.sector == '해운') {
    final cargo = const [
      '컨테이너 화물',
      '철광석',
      '원유',
      'LNG',
      '곡물',
    ][_fictionalHash('$seed:shipping-cargo:${company.id}:$arc') % 5];
    final customer = const [
      '글로벌 제조기업',
      '국제 자원개발사',
      '대형 유통연합',
      '국영 에너지 기업',
    ][_fictionalHash('$seed:shipping-customer:${company.id}:$arc') % 4];
    final years =
        3 + _fictionalHash('$seed:shipping-years:${company.id}:$arc') % 8;
    final volume =
        1 + _fictionalHash('$seed:shipping-volume:${company.id}:$arc') % 9;
    eyebrow = '장기 운송계약';
    title = switch (stage) {
      0 => '${company.name}, $customer $cargo 장기운송 입찰',
      1 => '${company.name}, 운임·연료비 연동조건 막판 협상',
      2 =>
        success
            ? '${company.name}, $years년·연 $volume백만톤 운송계약 확보'
            : '${company.name}, 장기운송 계약 경쟁사에 내줘',
      _ =>
        success
            ? '${company.name}, 장기물량 매출·선대 가동률 개선'
            : '${company.name}, 유휴선박·용선료 부담 확대',
    };
    body = switch (stage) {
      0 => '$customer가 발주한 $cargo 장기운송 사업에 참여했다. 확정 운임과 최소 물량은 아직 공개되지 않았다.',
      1 => '연료비 연동, 최소보장 물량, 항만체선 비용을 두고 최종 조율이 이어지고 있다.',
      2 =>
        success
            ? '$years년 동안 연 $volume백만톤을 운송하는 계약을 따냈다. 운임 조정식이 수익 안정성을 좌우한다.'
            : '운임과 선박 투입 조건에서 합의하지 못했다. 확보해 둔 선박의 대체 화물이 필요하다.',
      _ =>
        success
            ? '계약 물량이 실제 선적되며 선대 가동률이 올랐다. 연료비와 항만 적체가 남은 변수다.'
            : '대체 화물을 충분히 찾지 못해 유휴선박과 용선료 부담이 손익에 반영됐다.',
    };
    signal = '계약기간보다 최소보장 물량·운임 조정식·용선료 부담을 함께 봐야 합니다.';
    reportHint = '$cargo 항로 배선과 용선 문의가 늘었지만 최소 물량과 연료비 연동식은 확정되지 않았다.';
  } else if (kind == 'breakthrough') {
    final step = isBio
        ? ['후보물질 선정', '초기 시험', '핵심 임상 결과', success ? '허가·출시 준비' : '연구 방향 재검토']
        : [
            '비밀 연구팀 구성',
            '작동 시제품 공개',
            '양산 시험 결과',
            success ? '새 시장 출시' : '개발 중단·재설계',
          ];
    eyebrow = isBio ? '신약 개발' : '미래 기술';
    title = '${company.name}, $product ${step[stage]}';
    body = stage < 2
        ? '${company.name}이 $product 개발의 ${step[stage]} 단계에 들어갔다. 아직 성능과 사업성은 확정되지 않았다.'
        : success
        ? '$product 개발이 중요한 기준을 통과했다. 회사는 생산·판매 준비와 후속 기술 투자를 이어갈 계획이다.'
        : '$product 개발에서 예상하지 못한 한계가 확인됐다. 회사는 일정과 비용을 다시 계산하고 있다.';
    signal = stage < 2
        ? '아이디어보다 다음 검증 단계와 남은 현금을 확인해야 합니다.'
        : '결과가 좋아도 양산과 판매가 남았고, 실패해도 보유 기술은 남을 수 있습니다.';
    reportHint = '$product 조직의 인력·시험비가 늘었지만 외부에 공개할 성과는 아직 제한적이다.';
  } else if (kind == 'capacity' || kind == 'contract') {
    eyebrow = kind == 'capacity' ? '생산 투자' : '대형 계약';
    title = stage == 0
        ? '${company.name}, $product 수요 대응 검토'
        : stage == 1
        ? '${company.name}, $product 설비·공급 협상 확대'
        : stage == 2
        ? '${company.name}, $product ${success ? '수주·가동 시험 순항' : '협상·가동 차질'}'
        : '${company.name}, $product 사업 ${success ? '본격 매출 반영' : '투자 축소'}';
    body = stage < 2
        ? '회사 안팎에서 $product 주문과 생산능력을 함께 늘리는 방안이 논의되고 있다. 계약 조건은 아직 확정되지 않았다.'
        : success
        ? '고객 주문과 생산 준비가 계획 범위에 들어왔다. 회사는 후속 공급과 원가 절감까지 추진한다.'
        : '예상 수요와 실제 비용이 어긋나 일정이 늦어졌다. 고정비와 계약상 책임이 쟁점으로 떠올랐다.';
    signal = '계약 금액보다 이익률·선수금·증설 비용을 함께 봐야 합니다.';
    reportHint = '$product 관련 발주와 채용이 평소보다 늘었지만 고객 확정 물량은 공개되지 않았다.';
  } else if (kind == 'safety' || kind == 'security') {
    eyebrow = kind == 'security' ? '보안 점검' : '품질 점검';
    title = stage < 2
        ? '${company.name}, $product 위험 신호 점검 확대'
        : '${company.name}, $product 조사 ${success ? '문제 제한적' : '결함·침해 확인'}';
    body = stage < 2
        ? '$product 운영 과정에서 이상 징후가 발견돼 내부 점검 범위가 넓어졌다. 회사는 원인과 영향을 확인 중이다.'
        : success
        ? '점검 결과 영향 범위가 제한적인 것으로 나타났다. 회사는 보완 조치와 신뢰 회복에 나섰다.'
        : '조사에서 실제 결함이나 침해가 확인됐다. 교체·보상·시스템 개선 비용이 발생할 전망이다.';
    signal = '사고 자체보다 영향 범위와 재발 방지 비용이 기업가치를 가릅니다.';
    reportHint = '$product 부문의 고객 문의와 품질 점검 시간이 늘어 정상 운영 여부를 확인할 필요가 있다.';
  } else if (kind == 'finance' || kind == 'regulation') {
    eyebrow = kind == 'finance' ? '재무 변화' : '정책·인허가';
    title = stage < 2
        ? '${company.name}, $product 자금·규정 대응안 검토'
        : '${company.name}, $product ${success ? '조건 충족' : '비용·규제 부담 확대'}';
    body = stage < 2
        ? '회사가 $product 사업에 필요한 자금과 새 기준을 검토하고 있다. 조달 조건과 승인 여부는 아직 열려 있다.'
        : success
        ? '회사가 필요한 자금과 기준을 예상보다 유리하게 확보했다. 후속 투자 여력이 커질 수 있다.'
        : '자금조달 조건이나 규제 기준이 예상보다 까다로워졌다. 지분 희석과 일정 지연 가능성이 생겼다.';
    signal = '성장 계획이 좋아도 조달 금리와 새 주식 발행 조건을 확인해야 합니다.';
    reportHint = '재무·법무 조직의 외부 자문이 늘어 자금조달이나 인허가 변화를 준비하는 모습이다.';
  } else if (kind == 'earnings') {
    final estimateGap =
        6 + _fictionalHash('$seed:earnings-gap:${company.id}:$arc') % 29;
    eyebrow = '실적 변동';
    title = stage < 2
        ? '${company.name}, $product 분기 실적 추정치 변화'
        : '${company.name}, 영업이익 ${success ? '예상 $estimateGap% 상회' : '예상 $estimateGap% 하회'}';
    body = stage < 2
        ? '$product 출하·판매와 비용 집행이 기존 계획에서 달라지고 있다. 최종 매출과 일회성 항목은 아직 확정되지 않았다.'
        : success
        ? '판매량과 제품 구성이 개선돼 시장 기대를 웃돌았다. 현금흐름과 다음 분기 주문도 함께 늘었다.'
        : '판매 둔화와 비용 증가가 겹쳐 시장 기대를 밑돌았다. 재고와 매출채권 부담이 커졌다.';
    signal = '매출보다 영업이익률·현금흐름·일회성 항목을 나눠 봐야 합니다.';
    reportHint = '$product 출하와 판촉비 집행이 평소 범위를 벗어나 실적 추정치 조정 가능성이 있다.';
  } else if (kind == 'governance') {
    eyebrow = '경영·지배구조';
    title = stage < 2
        ? '${company.name}, 이사회·경영진 변화 가능성'
        : '${company.name}, 지배구조 점검 ${success ? '독립성 강화' : '이해상충 확인'}';
    body = stage < 2
        ? '주요 투자와 내부거래를 둘러싸고 이사회 검토 범위가 넓어졌다. 인사와 책임소재는 확정되지 않았다.'
        : success
        ? '독립 이사와 내부통제 권한을 강화하고 문제 거래를 정리했다. 자금조달 신뢰가 회복될 수 있다.'
        : '특수관계 거래와 승인 절차의 문제가 확인됐다. 경영진 교체와 추가 조사 가능성이 생겼다.';
    signal = '경영진 이름보다 이사회 독립성·내부거래·자금 사용처가 중요합니다.';
    reportHint = '이사회 회의와 외부 법률자문이 늘었고 주요 투자안의 승인 절차가 길어지고 있다.';
  } else if (kind == 'supply_chain' ||
      kind == 'commodity' ||
      kind == 'currency') {
    final label = switch (kind) {
      'supply_chain' => '공급망',
      'commodity' => '원자재',
      _ => '환율',
    };
    eyebrow = '$label 변화';
    title = stage < 2
        ? '${company.name}, $product $label 위험 대응'
        : '${company.name}, $product $label ${success ? '비용 방어' : '원가 충격'}';
    body = stage < 2
        ? '$product의 조달가격과 납기 변동이 커져 대체 공급처와 가격 조정 협상이 진행 중이다.'
        : success
        ? '장기계약·재고관리·판매가격 조정으로 비용 충격을 제한했다. 공급 안정성도 개선됐다.'
        : '핵심 투입재 가격과 납기 문제가 생산차질로 번졌다. 긴급조달 비용과 고객 보상 부담이 생겼다.';
    signal = '가격 방향만 보지 말고 재고일수·헤지·판매가격 전가 시차를 확인해야 합니다.';
    reportHint = '$product 구매단가와 납기가 흔들리며 대체 공급처 심사와 환헤지 거래가 늘고 있다.';
  } else if (kind == 'patent' || kind == 'litigation') {
    final patent = kind == 'patent';
    eyebrow = patent ? '특허·기술권리' : '소송·분쟁';
    title = stage < 2
        ? '${company.name}, $product ${patent ? '핵심특허 심사·협상' : '법적분쟁 대응'}'
        : '${company.name}, $product ${success ? '권리·협상 우위 확보' : '판매제한·배상 위험'}';
    body = stage < 2
        ? '$product의 기술권리와 계약 해석을 두고 외부 심사와 협상이 진행되고 있다. 최종 판단은 나오지 않았다.'
        : success
        ? '핵심 권리와 계약상 지위를 인정받아 경쟁사 견제와 실시료 수입 가능성이 커졌다.'
        : '불리한 판단으로 설계변경·판매제한·배상 비용 가능성이 생겼다. 출시 일정도 다시 계산해야 한다.';
    signal = '승패뿐 아니라 판매금지 범위·배상 상한·대체설계 기간을 확인해야 합니다.';
    reportHint = '$product 관련 특허대리인과 법률자문 비용이 늘고 경쟁사와의 기술문서 교환이 중단됐다.';
  } else if (kind == 'merger') {
    eyebrow = '인수·합병';
    title = stage < 2
        ? '${company.name}, 동종기업 인수·사업결합 검토'
        : '${company.name}, 사업결합 ${success ? '조건부 승인·통합 착수' : '협상 결렬·비용 반영'}';
    body = stage < 2
        ? '시장점유율과 기술인력을 확보하기 위한 거래가 검토되고 있다. 가격과 자금조달 방식은 확정되지 않았다.'
        : success
        ? '거래 조건과 승인을 확보해 통합을 시작했다. 중복비용 절감과 고객 이탈 방지가 다음 과제다.'
        : '가격·규제·실사 문제로 거래가 무산됐다. 자문료와 인수 준비비가 손실로 남았다.';
    signal = '인수 발표보다 지불가격·신주발행·부채·통합비용을 계산해야 합니다.';
    reportHint = '외부 실사와 자금조달 자문이 늘고 일부 조직의 채용·투자가 일시 중단됐다.';
  } else if (kind == 'labor') {
    eyebrow = '노사·인력';
    title = stage < 2
        ? '${company.name}, $product 생산인력 협상'
        : '${company.name}, 노사협상 ${success ? '타결·가동 정상화' : '중단·납기 차질'}';
    body = stage < 2
        ? '임금·교대제·외주 범위를 두고 협상이 진행 중이다. 생산 일정에 미칠 영향은 확정되지 않았다.'
        : success
        ? '협상을 마치고 생산과 연구 일정을 정상화했다. 숙련인력 이탈 위험도 낮아졌다.'
        : '작업중단과 인력 이탈이 발생해 생산량과 납기 계획이 흔들렸다. 위약금 가능성도 생겼다.';
    signal = '임금 인상률뿐 아니라 가동중단 일수와 고객 납기 보상 조건을 봐야 합니다.';
    reportHint = '교대조 편성과 외주 발주가 바뀌고 인사·노무 회의가 평소보다 잦아졌다.';
  } else if (kind == 'product_launch') {
    eyebrow = '신제품 출시';
    title = stage < 2
        ? '${company.name}, $product 출시·고객검증 준비'
        : '${company.name}, $product ${success ? '초기 주문 돌풍' : '판매 부진·재고 부담'}';
    body = stage < 2
        ? '$product의 가격·유통·초도물량이 조율되고 있다. 예약 수요가 반복 구매로 이어질지는 아직 알 수 없다.'
        : success
        ? '초기 판매와 재주문이 계획을 웃돌았다. 생산수율과 고객지원 투자가 성장 속도를 결정한다.'
        : '초기 판매가 계획에 못 미쳐 재고와 판촉비가 늘었다. 가격 인하와 제품 수정이 검토된다.';
    signal = '출시 당일 판매보다 재주문·반품·수율·마케팅비를 확인해야 합니다.';
    reportHint = '$product 초도생산과 유통점 교육이 시작됐지만 예약 취소율과 실제 판매가는 공개되지 않았다.';
  } else {
    eyebrow = '산업 경쟁';
    title = stage < 2
        ? '${company.name}, $product 경쟁 전략 수정'
        : '${company.name}, $product 경쟁 ${success ? '우위 확보' : '점유율 압박'}';
    body = stage < 2
        ? '새 경쟁 제품과 가격 변화에 대응하기 위해 $product의 기능·가격·유통 전략을 다시 짜고 있다.'
        : success
        ? '개선된 제품과 유통 전략이 고객 반응을 얻었다. 회사는 인접 시장으로 후속 확장을 검토한다.'
        : '경쟁사의 빠른 출시와 가격 공세로 판매 계획이 흔들렸다. 재고와 마케팅 비용이 늘 수 있다.';
    signal = '시장 성장률보다 이 회사가 실제로 지키는 점유율과 가격 결정력을 봐야 합니다.';
    reportHint = '$product 영업조직의 판촉과 가격 협상이 늘어 경쟁 강도가 높아진 것으로 보인다.';
  }

  eyebrow = '$eyebrow · ${scenario.focus}';
  if (stage < 2) {
    body = '$body ${scenario.leadingSignal}.';
    reportHint = '$reportHint 핵심 관찰축은 ${scenario.focus}이다.';
  } else {
    body = '$body ${success ? scenario.upside : scenario.downside}.';
  }
  signal = '$signal 이번 사건의 핵심 검증축은 ${scenario.focus}입니다.';

  final tone = !direction && stage >= 2
      ? NewsTone.shock
      : stage == 3
      ? NewsTone.milestone
      : direction
      ? NewsTone.launch
      : NewsTone.calm;
  return FictionalMarketEvent(
    id: 'arc-${company.id}-$arc-$stage',
    date: dateKey,
    companyId: company.id,
    companyName: company.name,
    sector: company.sector,
    stage: stage,
    eyebrow: eyebrow,
    title: title,
    body: body,
    signal: signal,
    reportHint: reportHint,
    revealMinute: revealMinute,
    impactPct: impact,
    tone: tone,
  );
}

Map<String, dynamic> hiddenFictionalMarketScenario(
  String seed,
  DateTime date,
) => {
  'schemaVersion': 1,
  'date': marketDateKey(date),
  'worldSeed': seed,
  'status': 'hidden',
  'events': fictionalMarketEventsForDate(
    seed,
    date,
  ).map((event) => event.toJson()).toList(growable: false),
};

Map<String, List<FictionalCompanyRelation>> _buildCompanyRelations(
  String seed,
  List<FictionalCompanyDefinition> definitions,
) {
  final result = <String, List<FictionalCompanyRelation>>{
    for (final company in definitions) company.id: <FictionalCompanyRelation>[],
  };

  void add(
    FictionalCompanyDefinition company,
    FictionalCompanyDefinition related,
    FictionalCompanyRelationType type,
    double strength,
  ) {
    if (company.id == related.id) return;
    final relations = result[company.id]!;
    if (relations.any(
      (relation) =>
          relation.relatedAssetId == related.id && relation.type == type,
    )) {
      return;
    }
    relations.add(
      FictionalCompanyRelation(
        relatedAssetId: related.id,
        relatedName: related.name,
        type: type,
        strength: strength.clamp(0.05, 0.8).toDouble(),
      ),
    );
  }

  for (final company in definitions) {
    if (company.parentAssetId != null) {
      FictionalCompanyDefinition? parent;
      for (final candidate in definitions) {
        if (candidate.id == company.parentAssetId) {
          parent = candidate;
          break;
        }
      }
      if (parent != null) {
        add(company, parent, FictionalCompanyRelationType.parent, 0.55);
        add(parent, company, FictionalCompanyRelationType.subsidiary, 0.38);
      }
    }

    final competitors = definitions
        .where(
          (candidate) =>
              candidate.id != company.id && candidate.sector == company.sector,
        )
        .toList(growable: false);
    if (competitors.isNotEmpty) {
      final competitor =
          competitors[_fictionalHash('$seed:competitor:${company.id}') %
              competitors.length];
      add(
        company,
        competitor,
        FictionalCompanyRelationType.competitor,
        0.22 + _fictionalUnit(seed, 'competitor-strength:${company.id}') * 0.24,
      );
    }

    final crossSector = definitions
        .where(
          (candidate) =>
              candidate.id != company.id &&
              candidate.sector != company.sector &&
              candidate.parentAssetId != company.id,
        )
        .toList(growable: false);
    if (crossSector.isEmpty) continue;
    final supplier =
        crossSector[_fictionalHash('$seed:supplier:${company.id}') %
            crossSector.length];
    add(
      company,
      supplier,
      FictionalCompanyRelationType.supplier,
      0.18 + _fictionalUnit(seed, 'supplier-strength:${company.id}') * 0.25,
    );
    add(
      supplier,
      company,
      FictionalCompanyRelationType.customer,
      0.16 + _fictionalUnit(seed, 'customer-strength:${company.id}') * 0.23,
    );
    final partner =
        crossSector[_fictionalHash('$seed:partner:${company.id}') %
            crossSector.length];
    add(
      company,
      partner,
      FictionalCompanyRelationType.partner,
      0.14 + _fictionalUnit(seed, 'partner-strength:${company.id}') * 0.22,
    );
  }
  return {
    for (final entry in result.entries)
      entry.key: List<FictionalCompanyRelation>.unmodifiable(entry.value),
  };
}

List<FictionalFinancialSnapshot> _buildCompanyFinancials({
  required String seed,
  required FictionalCompanyDefinition company,
  required Map<String, double> prices,
  required Map<String, double> businessImpacts,
  required Map<String, double> backlogImpacts,
}) {
  if (prices.isEmpty) return const <FictionalFinancialSnapshot>[];
  final quarterEnds = <String, String>{};
  for (final date in prices.keys) {
    final parsed = DateTime.parse(date);
    final key = '${parsed.year}-Q${(parsed.month - 1) ~/ 3 + 1}';
    quarterEnds[key] = date;
  }
  final shares =
      3000000 + _fictionalHash('$seed:shares:${company.id}') % 27000001;
  final firstPrice = prices.values.first;
  final salesMultiple =
      0.8 + _fictionalUnit(seed, 'sales-multiple:${company.id}') * 2.7;
  var revenue = math.max(
    100000000,
    (firstPrice * shares / salesMultiple / 4).round(),
  );
  final baseMargin =
      0.035 + _fictionalUnit(seed, 'margin:${company.id}') * 0.17;
  var cash = (revenue * (0.35 + _fictionalUnit(seed, 'cash:${company.id}')))
      .round();
  var debt =
      (revenue * (0.25 + _fictionalUnit(seed, 'debt:${company.id}') * 1.6))
          .round();
  var equity = math.max(revenue, cash + revenue * 2 - debt).round();
  final backlogHeavy =
      company.sector.contains('조선') ||
      company.sector.contains('건설') ||
      company.sector.contains('기계') ||
      company.sector.contains('항공') ||
      company.sector.contains('방산');
  var backlog = (revenue * (backlogHeavy ? 4.2 : 0.55)).round();
  var outstanding = shares;
  var previousYear = 0;
  final snapshots = <FictionalFinancialSnapshot>[];

  for (final entry in quarterEnds.entries) {
    final impact = businessImpacts[entry.key] ?? 0;
    final backlogImpact = backlogImpacts[entry.key] ?? 0;
    final growth =
        (-0.025 +
                _fictionalUnit(seed, 'growth:${company.id}:${entry.key}') *
                    0.11 +
                impact * 0.65)
            .clamp(-0.28, 0.38)
            .toDouble();
    revenue = math.max(10000000, (revenue * (1 + growth)).round());
    final margin =
        (baseMargin +
                _fictionalSigned(seed, 'margin:${company.id}:${entry.key}') *
                    0.025 +
                impact * 0.22)
            .clamp(-0.22, 0.36)
            .toDouble();
    final operatingProfit = (revenue * margin).round();
    final surprise =
        (impact * 0.75 +
                _fictionalSigned(seed, 'consensus:${company.id}:${entry.key}') *
                    0.055)
            .clamp(-0.38, 0.38)
            .toDouble();
    final consensus = surprise <= -0.95
        ? operatingProfit
        : (operatingProfit / (1 + surprise)).round();
    final interest = (debt * 0.0125).round();
    final netIncome = ((operatingProfit - interest) * 0.76).round();
    final operatingCashFlow =
        (netIncome +
                revenue *
                    (0.018 +
                        _fictionalSigned(
                              seed,
                              'cashflow:${company.id}:${entry.key}',
                            ) *
                            0.025))
            .round();
    cash = math.max(0, cash + operatingCashFlow - (revenue * 0.045).round());
    debt = math.max(
      0,
      (debt * 0.985 - math.max(0, operatingCashFlow) * 0.08).round(),
    );
    equity = math.max(1000000, equity + netIncome).round();
    backlog = math.max(
      0,
      (backlog * (backlogHeavy ? 0.86 : 0.72) +
              revenue *
                  (backlogHeavy ? 0.92 : 0.18) *
                  (1 + backlogImpact * 4).clamp(0.15, 2.8))
          .round(),
    );
    final year = int.parse(entry.key.substring(0, 4));
    if (year != previousYear &&
        _fictionalHash('$seed:rights-select:${company.id}:$year') % 100 < 24) {
      outstanding = (outstanding * 1.08).round();
    }
    previousYear = year;
    snapshots.add(
      FictionalFinancialSnapshot(
        period: entry.value,
        revenue: revenue,
        operatingProfit: operatingProfit,
        consensusOperatingProfit: consensus,
        netIncome: netIncome,
        operatingCashFlow: operatingCashFlow,
        cash: cash,
        debt: debt,
        equity: equity,
        sharesOutstanding: outstanding,
        orderBacklog: backlog,
      ),
    );
  }
  return List<FictionalFinancialSnapshot>.unmodifiable(snapshots);
}

FictionalMarketUniverse buildFictionalMarketUniverse(String seed) {
  final spinoffs = _spinoffPlans(seed);
  final listings = _generatedListingPlans(seed);
  final definitions = <FictionalCompanyDefinition>[
    ...fixedFictionalCompanies,
    ...spinoffs.map((plan) => plan.definition),
    ...listings.map((plan) => plan.definition),
  ];
  final relationsByAsset = _buildCompanyRelations(seed, definitions);
  final quarterlyBusinessImpacts = <String, Map<String, double>>{
    for (final company in definitions) company.id: <String, double>{},
  };
  final quarterlyBacklogImpacts = <String, Map<String, double>>{
    for (final company in definitions) company.id: <String, double>{},
  };
  final listingDates = <String, DateTime>{
    for (final plan in spinoffs) plan.definition.id: plan.date,
    for (final plan in listings) plan.definition.id: plan.listingDate,
  };
  final delistingDates = <String, DateTime>{
    for (final plan in listings)
      if (plan.delistingDate != null) plan.definition.id: plan.delistingDate!,
  };
  final prices = <String, Map<String, double>>{
    for (final definition in definitions) definition.id: <String, double>{},
  };
  final current = <String, double>{};
  var date = DateTime(1999, 12, 30);
  final end = DateTime(2010, 12, 31);
  while (!date.isAfter(end)) {
    if (isMarketTradingDay(date)) {
      final dateKey = marketDateKey(date);
      final events = fictionalMarketEventsForDate(seed, date);
      final macro =
          _fictionalSigned(seed, 'macro:$dateKey') * 0.008 +
          _fictionalSigned(
                seed,
                'regime:${date.difference(DateTime(2000, 1, 1)).inDays ~/ 90}',
              ) *
              0.0018;
      for (final company in definitions) {
        final listed = listingDates[company.id];
        final delisted = delistingDates[company.id];
        if (listed != null && date.isBefore(listed)) continue;
        if (delisted != null && !date.isBefore(delisted)) continue;
        final previous = current.putIfAbsent(
          company.id,
          () =>
              company.initialPrice *
              (0.82 + _fictionalUnit(seed, 'initial:${company.id}') * 0.36),
        );
        final sector =
            _fictionalSigned(seed, 'sector:${company.sector}:$dateKey') * 0.006;
        final companyNoise =
            _fictionalSigned(seed, 'company:${company.id}:$dateKey') *
            company.volatility;
        final directEventImpact = events.fold<double>(0, (sum, event) {
          if (event.companyId == fictionalWholeMarketCompanyId) {
            return sum +
                event.impactPct +
                (event.sectorImpactPcts[company.sector] ?? 0);
          }
          if (event.companyId == company.id) return sum + event.impactPct;
          if (event.sector == company.sector) {
            return sum + event.impactPct * 0.12;
          }
          return sum;
        });
        var relationImpact = 0.0;
        var resolvedRelationImpact = 0.0;
        for (final relation
            in relationsByAsset[company.id] ??
                const <FictionalCompanyRelation>[]) {
          final factor =
              relation.type == FictionalCompanyRelationType.competitor
              ? -relation.strength * 0.55
              : relation.type == FictionalCompanyRelationType.parent ||
                    relation.type == FictionalCompanyRelationType.subsidiary
              ? relation.strength * 0.7
              : relation.strength * 0.42;
          for (final event in events) {
            if (event.companyId != relation.relatedAssetId) continue;
            relationImpact += event.impactPct * factor;
            if (event.stage >= 2) {
              resolvedRelationImpact += event.impactPct * factor;
            }
          }
        }
        final eventImpact = directEventImpact + relationImpact;
        final quarterKey = '${date.year}-Q${(date.month - 1) ~/ 3 + 1}';
        final resolvedDirectImpact = events.fold<double>(0, (sum, event) {
          if (event.stage < 2) return sum;
          if (event.companyId == company.id) return sum + event.impactPct;
          return sum;
        });
        quarterlyBusinessImpacts[company.id]![quarterKey] =
            (quarterlyBusinessImpacts[company.id]![quarterKey] ?? 0) +
            resolvedDirectImpact +
            resolvedRelationImpact * 0.55;
        final backlogEventImpact = events.fold<double>(0, (sum, event) {
          if (event.stage < 2 || event.companyId != company.id) return sum;
          final text = '${event.eyebrow} ${event.title}';
          final isOrderEvent =
              text.contains('수주') ||
              text.contains('계약') ||
              text.contains('공급') ||
              text.contains('주문');
          return isOrderEvent ? sum + event.impactPct : sum;
        });
        quarterlyBacklogImpacts[company.id]![quarterKey] =
            (quarterlyBacklogImpacts[company.id]![quarterKey] ?? 0) +
            backlogEventImpact;
        final dailyLimit = marketDailyPriceLimitRate(date);
        final dailyReturn = (macro + sector + companyNoise + eventImpact)
            .clamp(-dailyLimit, dailyLimit)
            .toDouble();
        final raw = (previous * (1 + dailyReturn))
            .clamp(120, 2500000)
            .toDouble();
        final range = marketDailyPriceRange(
          previousClose: previous,
          date: date,
          market: company.market,
        );
        final rounded = marketSnapPrice(
          raw.clamp(range.lower, range.upper).toDouble(),
          market: company.market,
        );
        current[company.id] = rounded;
        prices[company.id]![dateKey] = rounded;
      }
    }
    date = date.add(const Duration(days: 1));
  }

  final actionsByAsset = <String, List<MarketCorporateAction>>{};
  for (var index = 0; index < spinoffs.length; index++) {
    final plan = spinoffs[index];
    final parentId = plan.definition.parentAssetId!;
    final material = index.isEven;
    actionsByAsset
        .putIfAbsent(parentId, () => [])
        .add(
          MarketCorporateAction(
            id: '${material ? 'material' : 'personnel'}-spinoff-${plan.definition.id}-${marketDateKey(plan.date)}',
            assetId: parentId,
            type: material
                ? MarketCorporateActionType.materialSpinoff
                : MarketCorporateActionType.spinoff,
            date: marketDateKey(plan.date),
            numerator: 1,
            denominator: 5,
            amount: 0,
            currency: 'KRW',
            source: 'fictional-world-engine',
            relatedAssetId: plan.definition.id,
            relatedSymbol: plan.definition.symbol,
            relatedName: plan.definition.name,
            relatedMarket: plan.definition.market,
          ),
        );
  }

  for (final plan in listings) {
    if (plan.delistingDate == null) continue;
    final companyPrices = prices[plan.definition.id]!;
    if (companyPrices.isEmpty) continue;
    final lastClose = companyPrices.values.last;
    final recoveryRate =
        0.12 +
        _fictionalUnit(seed, 'delisting-recovery:${plan.definition.id}') * 0.43;
    actionsByAsset
        .putIfAbsent(plan.definition.id, () => [])
        .add(
          MarketCorporateAction(
            id: 'delisting-${plan.definition.id}-${marketDateKey(plan.delistingDate!)}',
            assetId: plan.definition.id,
            type: MarketCorporateActionType.delisting,
            date: marketDateKey(plan.delistingDate!),
            numerator: 1,
            denominator: 1,
            amount: lastClose * recoveryRate,
            currency: 'KRW',
            source: 'fictional-world-engine',
          ),
        );
  }

  for (final company in definitions) {
    for (var year = 2000; year <= 2010; year++) {
      if (_fictionalHash('$seed:rights-select:${company.id}:$year') % 100 >=
          24) {
        continue;
      }
      final dayOffset =
          18 + _fictionalHash('$seed:rights-day:${company.id}:$year') % 320;
      final actionDate = _nextFictionalTradingDay(
        DateTime(year, 1, 1).add(Duration(days: dayOffset)),
      );
      final listed = listingDates[company.id];
      final delisted = delistingDates[company.id];
      if (listed != null && actionDate.isBefore(listed)) continue;
      if (delisted != null && !actionDate.isBefore(delisted)) continue;
      actionsByAsset
          .putIfAbsent(company.id, () => [])
          .add(
            MarketCorporateAction(
              id: 'rights-${company.id}-$year',
              assetId: company.id,
              type: MarketCorporateActionType.rightsIssue,
              date: marketDateKey(actionDate),
              numerator: 1,
              denominator: 1,
              amount: 0,
              currency: 'KRW',
              source: 'fictional-world-engine',
            ),
          );
    }
  }

  return FictionalMarketUniverse(
    schemaVersion: 7,
    sourceName: 'seeded-fictional-market-v4-fundamentals-relations',
    assets: definitions
        .map((company) {
          final listed = listingDates[company.id];
          final delisted = delistingDates[company.id];
          return FictionalMarketAsset(
            id: company.id,
            symbol: company.symbol,
            name: company.name,
            market: company.market,
            country: 'KR',
            sector: company.sector,
            colorHex: company.colorHex,
            currency: 'KRW',
            prices: prices[company.id]!,
            corporateActions: actionsByAsset[company.id] ?? const [],
            summary: company.summary,
            question: company.question,
            generation: company.generation,
            parentAssetId: company.parentAssetId,
            listedOn: listed == null ? null : marketDateKey(listed),
            delistedOn: delisted == null ? null : marketDateKey(delisted),
            financials: _buildCompanyFinancials(
              seed: seed,
              company: company,
              prices: prices[company.id]!,
              businessImpacts: quarterlyBusinessImpacts[company.id] ?? const {},
              backlogImpacts: quarterlyBacklogImpacts[company.id] ?? const {},
            ),
            relations:
                relationsByAsset[company.id] ??
                const <FictionalCompanyRelation>[],
          );
        })
        .toList(growable: false),
  );
}
