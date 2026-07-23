part of 'market_data.dart';

const fictionalMarketArcKinds = <String>[
  'breakthrough',
  'capacity',
  'contract',
  'safety',
  'security',
  'finance',
  'regulation',
  'competition',
  'earnings',
  'governance',
  'supply_chain',
  'commodity',
  'currency',
  'patent',
  'litigation',
  'merger',
  'labor',
  'product_launch',
];

/// 2000~2010년에 실제로 확산된 기술 흐름을 게임용 가상 기술로 추상화한다.
/// 실제 회사명·상표·기사 문장을 저장하지 않고, 등장 시기와 산업 파급 구조만
/// 국내 가상기업의 협약·개발 사건으로 변환한다.
class FictionalEraTechnology {
  const FictionalEraTechnology({
    required this.id,
    required this.name,
    required this.firstYear,
    required this.lastYear,
    required this.sectors,
    required this.successImpact,
    required this.failureImpact,
  });

  final String id;
  final String name;
  final int firstYear;
  final int lastYear;
  final List<String> sectors;
  final double successImpact;
  final double failureImpact;
}

const fictionalEraTechnologies = <FictionalEraTechnology>[
  FictionalEraTechnology(
    id: 'broadband_portal',
    name: '초고속인터넷·포털 서비스',
    firstYear: 2000,
    lastYear: 2001,
    sectors: ['통신·네트워크', '인터넷', '소프트웨어'],
    successImpact: 0.17,
    failureImpact: 0.18,
  ),
  FictionalEraTechnology(
    id: 'persistent_online_world',
    name: '대규모 온라인 세계',
    firstYear: 2000,
    lastYear: 2001,
    sectors: ['게임', '소프트웨어', '인터넷'],
    successImpact: 0.19,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'online_commerce_payment',
    name: '온라인 장터·전자결제',
    firstYear: 2000,
    lastYear: 2002,
    sectors: ['유통', '인터넷', '금융', '물류'],
    successImpact: 0.16,
    failureImpact: 0.17,
  ),
  FictionalEraTechnology(
    id: 'camera_phone_module',
    name: '카메라폰 핵심모듈',
    firstYear: 2001,
    lastYear: 2002,
    sectors: ['정밀기기', '통신·네트워크', '디스플레이', '반도체'],
    successImpact: 0.18,
    failureImpact: 0.19,
  ),
  FictionalEraTechnology(
    id: 'third_generation_mobile',
    name: '3세대 이동통신',
    firstYear: 2001,
    lastYear: 2003,
    sectors: ['통신·네트워크', '반도체', '디스플레이'],
    successImpact: 0.18,
    failureImpact: 0.19,
  ),
  FictionalEraTechnology(
    id: 'mobile_color_display',
    name: '고해상도 휴대기기 화면',
    firstYear: 2002,
    lastYear: 2003,
    sectors: ['디스플레이', '첨단소재', '정밀기기'],
    successImpact: 0.17,
    failureImpact: 0.18,
  ),
  FictionalEraTechnology(
    id: 'portable_flash_storage',
    name: '휴대형 플래시 저장장치',
    firstYear: 2002,
    lastYear: 2004,
    sectors: ['반도체', '첨단소재', '정밀기기'],
    successImpact: 0.18,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'digital_music_distribution',
    name: '디지털 음원 유통',
    firstYear: 2003,
    lastYear: 2004,
    sectors: ['미디어', '인터넷', '소프트웨어'],
    successImpact: 0.16,
    failureImpact: 0.17,
  ),
  FictionalEraTechnology(
    id: 'rfid_supply_chain',
    name: '무선인식 공급망',
    firstYear: 2003,
    lastYear: 2005,
    sectors: ['유통', '물류', '반도체', '정보보안'],
    successImpact: 0.15,
    failureImpact: 0.16,
  ),
  FictionalEraTechnology(
    id: 'search_ads_maps',
    name: '검색광고·지도 서비스',
    firstYear: 2004,
    lastYear: 2005,
    sectors: ['인터넷', '소프트웨어', '미디어'],
    successImpact: 0.20,
    failureImpact: 0.19,
  ),
  FictionalEraTechnology(
    id: 'streaming_education',
    name: '동영상 온라인 교육',
    firstYear: 2004,
    lastYear: 2006,
    sectors: ['교육', '소프트웨어', '인터넷'],
    successImpact: 0.16,
    failureImpact: 0.17,
  ),
  FictionalEraTechnology(
    id: 'user_video_platform',
    name: '사용자 동영상 플랫폼',
    firstYear: 2005,
    lastYear: 2006,
    sectors: ['미디어', '인터넷', '소프트웨어'],
    successImpact: 0.23,
    failureImpact: 0.22,
  ),
  FictionalEraTechnology(
    id: 'hybrid_electric_drive',
    name: '하이브리드·전기 구동계',
    firstYear: 2005,
    lastYear: 2007,
    sectors: ['자동차', '전지', '정밀기기'],
    successImpact: 0.18,
    failureImpact: 0.21,
  ),
  FictionalEraTechnology(
    id: 'biometric_public_security',
    name: '생체인증·전자정부 보안',
    firstYear: 2005,
    lastYear: 2007,
    sectors: ['정보보안', '정밀기기', '의료기기'],
    successImpact: 0.17,
    failureImpact: 0.18,
  ),
  FictionalEraTechnology(
    id: 'cloud_object_storage',
    name: '인터넷 객체저장·클라우드',
    firstYear: 2006,
    lastYear: 2007,
    sectors: ['소프트웨어', '인터넷', '정보보안'],
    successImpact: 0.22,
    failureImpact: 0.21,
  ),
  FictionalEraTechnology(
    id: 'mobile_oled',
    name: '휴대기기용 유기발광 화면',
    firstYear: 2006,
    lastYear: 2008,
    sectors: ['디스플레이', '첨단소재', '반도체'],
    successImpact: 0.20,
    failureImpact: 0.22,
  ),
  FictionalEraTechnology(
    id: 'lng_ship_design',
    name: '고부가 LNG 운반선 설계',
    firstYear: 2006,
    lastYear: 2008,
    sectors: ['조선·기계', '첨단소재', '해운'],
    successImpact: 0.19,
    failureImpact: 0.21,
  ),
  FictionalEraTechnology(
    id: 'multitouch_smart_device',
    name: '멀티터치 스마트 단말',
    firstYear: 2007,
    lastYear: 2008,
    sectors: ['통신·네트워크', '디스플레이', '반도체', '소프트웨어', '전지'],
    successImpact: 0.25,
    failureImpact: 0.24,
  ),
  FictionalEraTechnology(
    id: 'thin_film_solar',
    name: '박막 태양광·전력변환',
    firstYear: 2007,
    lastYear: 2009,
    sectors: ['에너지', '첨단소재', '환경'],
    successImpact: 0.18,
    failureImpact: 0.21,
  ),
  FictionalEraTechnology(
    id: 'personal_diagnostics',
    name: '맞춤진단·약물전달',
    firstYear: 2007,
    lastYear: 2009,
    sectors: ['바이오', '제약', '의료기기'],
    successImpact: 0.22,
    failureImpact: 0.24,
  ),
  FictionalEraTechnology(
    id: 'mobile_app_marketplace',
    name: '모바일 응용프로그램 장터',
    firstYear: 2008,
    lastYear: 2009,
    sectors: ['소프트웨어', '인터넷', '게임', '금융기술'],
    successImpact: 0.24,
    failureImpact: 0.22,
  ),
  FictionalEraTechnology(
    id: 'open_smartphone_platform',
    name: '개방형 스마트폰 플랫폼',
    firstYear: 2008,
    lastYear: 2009,
    sectors: ['통신·네트워크', '소프트웨어', '인터넷', '반도체'],
    successImpact: 0.23,
    failureImpact: 0.22,
  ),
  FictionalEraTechnology(
    id: 'lte_baseband_network',
    name: '차세대 광대역 무선망·모뎀',
    firstYear: 2008,
    lastYear: 2010,
    sectors: ['통신·네트워크', '반도체', '정보보안'],
    successImpact: 0.21,
    failureImpact: 0.22,
  ),
  FictionalEraTechnology(
    id: 'smart_grid_storage',
    name: '지능형 전력망·대형 저장장치',
    firstYear: 2008,
    lastYear: 2010,
    sectors: ['에너지', '전지', '정보보안', '환경'],
    successImpact: 0.19,
    failureImpact: 0.21,
  ),
  FictionalEraTechnology(
    id: 'mobile_social_messaging',
    name: '실시간 소셜·모바일 메시징',
    firstYear: 2009,
    lastYear: 2010,
    sectors: ['인터넷', '소프트웨어', '미디어', '통신·네트워크'],
    successImpact: 0.22,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'mass_market_ev_battery',
    name: '양산형 전기차·차량용 전지',
    firstYear: 2009,
    lastYear: 2010,
    sectors: ['자동차', '전지', '첨단소재'],
    successImpact: 0.22,
    failureImpact: 0.24,
  ),
  FictionalEraTechnology(
    id: 'enterprise_cloud_suite',
    name: '기업용 클라우드 업무도구',
    firstYear: 2009,
    lastYear: 2010,
    sectors: ['소프트웨어', '인터넷', '정보보안'],
    successImpact: 0.20,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'tablet_computing',
    name: '태블릿형 휴대컴퓨팅',
    firstYear: 2010,
    lastYear: 2010,
    sectors: ['통신·네트워크', '디스플레이', '반도체', '소프트웨어', '전지'],
    successImpact: 0.23,
    failureImpact: 0.22,
  ),
  FictionalEraTechnology(
    id: 'fourth_generation_launch',
    name: '4세대 이동통신 상용망',
    firstYear: 2010,
    lastYear: 2010,
    sectors: ['통신·네트워크', '반도체', '정보보안'],
    successImpact: 0.21,
    failureImpact: 0.22,
  ),
  FictionalEraTechnology(
    id: 'connected_smart_tv',
    name: '인터넷 연결형 스마트 화면',
    firstYear: 2010,
    lastYear: 2010,
    sectors: ['디스플레이', '미디어', '소프트웨어', '인터넷'],
    successImpact: 0.20,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'low_carbon_ship',
    name: '저탄소 선박 추진장치',
    firstYear: 2010,
    lastYear: 2010,
    sectors: ['조선·기계', '해운', '첨단소재', '에너지'],
    successImpact: 0.19,
    failureImpact: 0.22,
  ),
  FictionalEraTechnology(
    id: 'robotic_logistics',
    name: '로봇 물류 자동화',
    firstYear: 2010,
    lastYear: 2010,
    sectors: ['로봇', '물류', '정밀기기'],
    successImpact: 0.18,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'wireless_local_network',
    name: '무선 근거리 통신망',
    firstYear: 2000,
    lastYear: 2001,
    sectors: ['통신·네트워크', '반도체', '정보보안', '소프트웨어'],
    successImpact: 0.17,
    failureImpact: 0.18,
  ),
  FictionalEraTechnology(
    id: 'short_range_wireless_peripheral',
    name: '근거리 무선 주변기기',
    firstYear: 2000,
    lastYear: 2002,
    sectors: ['반도체', '정밀기기', '통신·네트워크', '자동차'],
    successImpact: 0.16,
    failureImpact: 0.17,
  ),
  FictionalEraTechnology(
    id: 'usb_flash_memory',
    name: '휴대형 범용직렬 저장장치',
    firstYear: 2000,
    lastYear: 2002,
    sectors: ['반도체', '정밀기기', '첨단소재'],
    successImpact: 0.18,
    failureImpact: 0.19,
  ),
  FictionalEraTechnology(
    id: 'civilian_gps_navigation',
    name: '민간 위성항법 단말',
    firstYear: 2000,
    lastYear: 2002,
    sectors: ['정밀기기', '자동차', '통신·네트워크', '물류'],
    successImpact: 0.17,
    failureImpact: 0.18,
  ),
  FictionalEraTechnology(
    id: 'digital_terrestrial_broadcast',
    name: '지상파 디지털 방송',
    firstYear: 2000,
    lastYear: 2002,
    sectors: ['미디어', '디스플레이', '통신·네트워크', '반도체'],
    successImpact: 0.16,
    failureImpact: 0.17,
  ),
  FictionalEraTechnology(
    id: 'internet_banking_pki',
    name: '인터넷은행·공개키 보안',
    firstYear: 2000,
    lastYear: 2002,
    sectors: ['금융', '정보보안', '소프트웨어', '인터넷'],
    successImpact: 0.17,
    failureImpact: 0.19,
  ),
  FictionalEraTechnology(
    id: 'robotic_minimally_invasive_surgery',
    name: '로봇 보조 최소침습 수술',
    firstYear: 2000,
    lastYear: 2002,
    sectors: ['의료기기', '로봇', '정밀기기'],
    successImpact: 0.21,
    failureImpact: 0.23,
  ),
  FictionalEraTechnology(
    id: 'genome_draft_bioinformatics',
    name: '유전체 초안·생명정보 분석',
    firstYear: 2000,
    lastYear: 2002,
    sectors: ['바이오', '소프트웨어', '의료기기', '제약'],
    successImpact: 0.20,
    failureImpact: 0.21,
  ),
  FictionalEraTechnology(
    id: 'optical_broadband_access',
    name: '광가입자 초고속망',
    firstYear: 2001,
    lastYear: 2003,
    sectors: ['통신·네트워크', '첨단소재', '반도체'],
    successImpact: 0.18,
    failureImpact: 0.19,
  ),
  FictionalEraTechnology(
    id: 'web_services_integration',
    name: '웹서비스 기업시스템 연동',
    firstYear: 2001,
    lastYear: 2003,
    sectors: ['소프트웨어', '인터넷', '정보보안'],
    successImpact: 0.16,
    failureImpact: 0.17,
  ),
  FictionalEraTechnology(
    id: 'digital_rights_management',
    name: '디지털 저작권 관리',
    firstYear: 2001,
    lastYear: 2003,
    sectors: ['미디어', '정보보안', '소프트웨어', '인터넷'],
    successImpact: 0.15,
    failureImpact: 0.17,
  ),
  FictionalEraTechnology(
    id: 'capsule_endoscopy',
    name: '캡슐형 내시경 진단',
    firstYear: 2001,
    lastYear: 2003,
    sectors: ['의료기기', '정밀기기', '바이오'],
    successImpact: 0.20,
    failureImpact: 0.22,
  ),
  FictionalEraTechnology(
    id: 'targeted_cancer_therapy',
    name: '표적형 항암 치료',
    firstYear: 2001,
    lastYear: 2004,
    sectors: ['바이오', '제약', '의료기기'],
    successImpact: 0.23,
    failureImpact: 0.25,
  ),
  FictionalEraTechnology(
    id: 'vehicle_telematics',
    name: '차량 텔레매틱스',
    firstYear: 2001,
    lastYear: 2003,
    sectors: ['자동차', '통신·네트워크', '소프트웨어', '정밀기기'],
    successImpact: 0.17,
    failureImpact: 0.18,
  ),
  FictionalEraTechnology(
    id: 'wiki_collaboration',
    name: '공동편집 지식 서비스',
    firstYear: 2001,
    lastYear: 2003,
    sectors: ['인터넷', '소프트웨어', '교육', '미디어'],
    successImpact: 0.16,
    failureImpact: 0.16,
  ),
  FictionalEraTechnology(
    id: 'data_center_virtualization',
    name: '데이터센터 서버 가상화',
    firstYear: 2001,
    lastYear: 2004,
    sectors: ['소프트웨어', '정보보안', '반도체', '인터넷'],
    successImpact: 0.19,
    failureImpact: 0.19,
  ),
  FictionalEraTechnology(
    id: 'high_resolution_photo_sensor',
    name: '고해상도 디지털 촬상소자',
    firstYear: 2002,
    lastYear: 2004,
    sectors: ['반도체', '정밀기기', '첨단소재'],
    successImpact: 0.18,
    failureImpact: 0.19,
  ),
  FictionalEraTechnology(
    id: 'microarray_diagnostics',
    name: '유전자칩 진단',
    firstYear: 2002,
    lastYear: 2004,
    sectors: ['바이오', '의료기기', '반도체', '제약'],
    successImpact: 0.21,
    failureImpact: 0.22,
  ),
  FictionalEraTechnology(
    id: 'contactless_transit_card',
    name: '비접촉 교통·결제 카드',
    firstYear: 2002,
    lastYear: 2004,
    sectors: ['금융기술', '정보보안', '반도체', '통신·네트워크'],
    successImpact: 0.17,
    failureImpact: 0.18,
  ),
  FictionalEraTechnology(
    id: 'recordable_optical_media',
    name: '가정용 기록형 광매체',
    firstYear: 2002,
    lastYear: 2004,
    sectors: ['미디어', '디스플레이', '반도체', '정밀기기'],
    successImpact: 0.15,
    failureImpact: 0.17,
  ),
  FictionalEraTechnology(
    id: 'industrial_ethernet_control',
    name: '산업용 이더넷 제어',
    firstYear: 2002,
    lastYear: 2005,
    sectors: ['로봇', '농업기계', '조선·기계', '소프트웨어'],
    successImpact: 0.17,
    failureImpact: 0.18,
  ),
  FictionalEraTechnology(
    id: 'auction_based_online_ads',
    name: '경매형 온라인 광고',
    firstYear: 2002,
    lastYear: 2004,
    sectors: ['인터넷', '미디어', '소프트웨어'],
    successImpact: 0.20,
    failureImpact: 0.19,
  ),
  FictionalEraTechnology(
    id: 'internet_voice_call',
    name: '인터넷 음성통화',
    firstYear: 2003,
    lastYear: 2005,
    sectors: ['통신·네트워크', '소프트웨어', '인터넷', '반도체'],
    successImpact: 0.18,
    failureImpact: 0.19,
  ),
  FictionalEraTechnology(
    id: 'advanced_video_codec',
    name: '고효율 동영상 압축규격',
    firstYear: 2003,
    lastYear: 2005,
    sectors: ['미디어', '소프트웨어', '반도체', '인터넷'],
    successImpact: 0.19,
    failureImpact: 0.18,
  ),
  FictionalEraTechnology(
    id: 'online_social_network',
    name: '온라인 관계망 서비스',
    firstYear: 2003,
    lastYear: 2005,
    sectors: ['인터넷', '미디어', '소프트웨어'],
    successImpact: 0.21,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'electronic_paper_display',
    name: '전자종이 화면',
    firstYear: 2003,
    lastYear: 2006,
    sectors: ['디스플레이', '첨단소재', '반도체'],
    successImpact: 0.18,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'genome_based_drug_discovery',
    name: '유전체 기반 신약탐색',
    firstYear: 2003,
    lastYear: 2006,
    sectors: ['바이오', '제약', '소프트웨어'],
    successImpact: 0.22,
    failureImpact: 0.24,
  ),
  FictionalEraTechnology(
    id: 'fuel_cell_vehicle_stack',
    name: '차량용 연료전지 스택',
    firstYear: 2003,
    lastYear: 2006,
    sectors: ['에너지', '자동차', '첨단소재', '화학·소재'],
    successImpact: 0.20,
    failureImpact: 0.23,
  ),
  FictionalEraTechnology(
    id: 'podcast_distribution',
    name: '구독형 음성방송 유통',
    firstYear: 2004,
    lastYear: 2006,
    sectors: ['미디어', '인터넷', '소프트웨어'],
    successImpact: 0.17,
    failureImpact: 0.17,
  ),
  FictionalEraTechnology(
    id: 'graphene_nanomaterial',
    name: '단원자층 탄소 신소재',
    firstYear: 2004,
    lastYear: 2007,
    sectors: ['첨단소재', '화학·소재', '반도체', '전지'],
    successImpact: 0.21,
    failureImpact: 0.23,
  ),
  FictionalEraTechnology(
    id: 'satellite_digital_multimedia',
    name: '위성 디지털 멀티미디어 방송',
    firstYear: 2004,
    lastYear: 2006,
    sectors: ['미디어', '통신·네트워크', '디스플레이', '반도체'],
    successImpact: 0.17,
    failureImpact: 0.19,
  ),
  FictionalEraTechnology(
    id: 'multicore_processor',
    name: '다중연산핵 프로세서',
    firstYear: 2004,
    lastYear: 2006,
    sectors: ['반도체', '소프트웨어', '정밀기기'],
    successImpact: 0.20,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'digital_factory_plm',
    name: '디지털 공장·제품수명 관리',
    firstYear: 2004,
    lastYear: 2007,
    sectors: ['소프트웨어', '조선·기계', '자동차', '로봇'],
    successImpact: 0.17,
    failureImpact: 0.18,
  ),
  FictionalEraTechnology(
    id: 'electronic_document_signature',
    name: '전자문서·디지털 서명',
    firstYear: 2004,
    lastYear: 2006,
    sectors: ['정보보안', '금융', '소프트웨어', '금융기술'],
    successImpact: 0.16,
    failureImpact: 0.17,
  ),
  FictionalEraTechnology(
    id: 'metropolitan_wireless_broadband',
    name: '도시형 광대역 무선망',
    firstYear: 2005,
    lastYear: 2007,
    sectors: ['통신·네트워크', '반도체', '소프트웨어'],
    successImpact: 0.19,
    failureImpact: 0.21,
  ),
  FictionalEraTechnology(
    id: 'high_definition_optical_media',
    name: '고화질 차세대 광매체',
    firstYear: 2005,
    lastYear: 2007,
    sectors: ['미디어', '디스플레이', '반도체', '정밀기기'],
    successImpact: 0.17,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'electronic_passport_biometrics',
    name: '전자여권·생체인식 칩',
    firstYear: 2005,
    lastYear: 2007,
    sectors: ['정보보안', '정밀기기', '반도체'],
    successImpact: 0.17,
    failureImpact: 0.18,
  ),
  FictionalEraTechnology(
    id: 'mobile_digital_broadcast',
    name: '휴대형 디지털 방송',
    firstYear: 2005,
    lastYear: 2007,
    sectors: ['미디어', '통신·네트워크', '디스플레이', '반도체'],
    successImpact: 0.18,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'advanced_biofuel_refining',
    name: '수송용 바이오연료 정제',
    firstYear: 2005,
    lastYear: 2008,
    sectors: ['에너지', '화학·소재', '환경', '식품'],
    successImpact: 0.18,
    failureImpact: 0.21,
  ),
  FictionalEraTechnology(
    id: 'distributed_data_processing',
    name: '분산형 대용량 데이터 처리',
    firstYear: 2006,
    lastYear: 2008,
    sectors: ['소프트웨어', '인터넷', '정보보안'],
    successImpact: 0.21,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'preventive_viral_vaccine',
    name: '예방형 바이러스 백신',
    firstYear: 2006,
    lastYear: 2008,
    sectors: ['바이오', '제약', '의료기기'],
    successImpact: 0.22,
    failureImpact: 0.24,
  ),
  FictionalEraTechnology(
    id: 'high_speed_packet_mobile',
    name: '고속 이동통신 패킷망',
    firstYear: 2006,
    lastYear: 2008,
    sectors: ['통신·네트워크', '반도체', '소프트웨어'],
    successImpact: 0.19,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'biosimilar_manufacturing',
    name: '바이오복제약 대량생산',
    firstYear: 2006,
    lastYear: 2009,
    sectors: ['바이오', '제약', '의료기기'],
    successImpact: 0.21,
    failureImpact: 0.23,
  ),
  FictionalEraTechnology(
    id: 'solid_state_drive',
    name: '반도체형 고속 저장장치',
    firstYear: 2007,
    lastYear: 2009,
    sectors: ['반도체', '정밀기기', '소프트웨어'],
    successImpact: 0.21,
    failureImpact: 0.21,
  ),
  FictionalEraTechnology(
    id: 'electronic_book_reader',
    name: '전자책 전용단말·유통',
    firstYear: 2007,
    lastYear: 2009,
    sectors: ['디스플레이', '미디어', '인터넷', '소프트웨어'],
    successImpact: 0.18,
    failureImpact: 0.19,
  ),
  FictionalEraTechnology(
    id: 'white_led_general_lighting',
    name: '고효율 백색 반도체 조명',
    firstYear: 2007,
    lastYear: 2010,
    sectors: ['반도체', '에너지', '첨단소재', '환경'],
    successImpact: 0.19,
    failureImpact: 0.20,
  ),
  FictionalEraTechnology(
    id: 'high_throughput_genome_sequencing',
    name: '고속 대량 유전체 분석',
    firstYear: 2007,
    lastYear: 2010,
    sectors: ['바이오', '의료기기', '소프트웨어', '제약'],
    successImpact: 0.22,
    failureImpact: 0.23,
  ),
  FictionalEraTechnology(
    id: 'near_field_mobile_payment',
    name: '근거리 무선 모바일결제',
    firstYear: 2008,
    lastYear: 2010,
    sectors: ['금융기술', '정보보안', '반도체', '통신·네트워크'],
    successImpact: 0.20,
    failureImpact: 0.21,
  ),
];

BigInt fictionalEraTechnologyCombinationFloor() {
  var combinations = BigInt.one;
  for (final technology in fictionalEraTechnologies) {
    final fixedCandidates = fixedFictionalCompanies
        .where((company) => technology.sectors.contains(company.sector))
        .length;
    final yearOptions = technology.lastYear - technology.firstYear + 1;
    final perTechnology =
        fixedCandidates *
        yearOptions *
        _technologyAgreementModes.length *
        2 *
        2 *
        220;
    combinations *= BigInt.from(perTechnology);
  }
  return combinations;
}

const fictionalProductStartYears = <String, int>{
  '주머니형 통합단말': 2007,
  '저전력 연산칩': 2005,
  '원격 저장공간': 2006,
  '자체 결제망': 2003,
  '수소 저장': 2008,
  '소형 발사체': 2002,
  '저궤도 위성': 2004,
  '유기발광 패널': 2006,
  '접히는 화면': 2011,
  '초소형 투사장치': 2008,
  '전자지갑': 2008,
  '온라인 영상': 2005,
  '창작자 플랫폼': 2006,
  '식물성 단백질': 2008,
  '스마트도시': 2008,
  '가정용 로봇': 2005,
  '휴대 진단기': 2005,
  '원격진료 장비': 2008,
  '당일배송': 2006,
  '자동분류센터': 2003,
  '생체인증': 2005,
  '차량용 전지': 2007,
  '에너지 저장장치': 2009,
  '고체 전해질': 2011,
  '휴대 게임': 2004,
  '가상현실 콘텐츠': 2011,
  '친환경 포장': 2006,
  '카메라 모듈': 2001,
  '나노 계측기': 2004,
  '지도 서비스': 2004,
  '개인 방송': 2005,
  '온라인 강의': 2001,
  '맞춤 학습엔진': 2007,
  '약물전달 기술': 2003,
  '수확 로봇': 2007,
  '작물 데이터': 2006,
  '저탄소 선대': 2008,
  '투명 전극': 2007,
  '탄소 포집': 2008,
  '환경 측정망': 2005,
  '전기 구동계': 2005,
  '운전자 보조장치': 2008,
  '친환경 추진장치': 2008,
  '모바일 연산칩': 2007,
  '저전력 모뎀': 2005,
  '해양 무인기': 2008,
  '급속충전 장치': 2008,
  '전지 관리칩': 2006,
};

int fictionalProductStartYear(String product) =>
    fictionalProductStartYears[product] ?? 2000;

List<String> fictionalProductsAvailableInYear(
  FictionalCompanyDefinition company,
  int year,
) {
  final available = company.products
      .where((product) => fictionalProductStartYear(product) <= year)
      .toList(growable: false);
  return available.isEmpty ? <String>[company.products.first] : available;
}

int fictionalCompanyEarliestListingYear(FictionalCompanyDefinition company) =>
    switch (company.id) {
      'saebyeol_cloud' => 2006,
      'mirinae_battery' => 2006,
      'onnuri_pay' => 2007,
      _ => 2000,
    };

const fictionalWholeMarketCompanyId = '__whole_market__';

class FictionalHistoricalCatalyst {
  const FictionalHistoricalCatalyst({
    required this.id,
    required this.year,
    required this.month,
    required this.day,
    required this.category,
    required this.title,
    required this.body,
    required this.signal,
    required this.marketImpact,
    this.sectorImpacts = const <String, double>{},
  });

  final String id;
  final int year;
  final int month;
  final int day;
  final String category;
  final String title;
  final String body;
  final String signal;
  final double marketImpact;
  final Map<String, double> sectorImpacts;
}

/// 실제 시기의 대표 시장 촉매를 가상세계용 표현으로 바꾼 목록이다.
/// 방향은 당시 충격의 경제적 성격을 따르되 강도는 월드 시드마다 달라진다.
const fictionalHistoricalMarketCatalysts = <FictionalHistoricalCatalyst>[
  FictionalHistoricalCatalyst(
    id: '2000_internet_valuation_reversal',
    year: 2000,
    month: 3,
    day: 10,
    category: '세계 증시',
    title: '인터넷 성장주의 고평가 논쟁, 세계 시장으로 확산',
    body: '매출보다 이용자 수와 기대감으로 평가받던 기업들의 자금조달 여건이 급격히 나빠졌다.',
    signal: '성장률보다 현금소진 속도와 실제 매출 전환을 확인해야 합니다.',
    marketImpact: -0.065,
    sectorImpacts: {'인터넷': -0.085, '소프트웨어': -0.06, '게임': -0.055, '미디어': -0.04},
  ),
  FictionalHistoricalCatalyst(
    id: '2000_technology_deleveraging',
    year: 2000,
    month: 4,
    day: 14,
    category: '투자심리',
    title: '기술주 신용매물 급증, 성장시장 변동성 확대',
    body: '주가 하락과 담보 부족이 맞물리며 차입 투자자의 매도가 연쇄적으로 나왔다.',
    signal: '좋은 사업도 강제매도가 겹치면 가격과 가치가 따로 움직일 수 있습니다.',
    marketImpact: -0.09,
    sectorImpacts: {'인터넷': -0.06, '소프트웨어': -0.05, '반도체': -0.04},
  ),
  FictionalHistoricalCatalyst(
    id: '2000_oil_price_pressure',
    year: 2000,
    month: 9,
    day: 20,
    category: '원자재',
    title: '국제 원유가격 급등, 운송·제조 원가 경계',
    body: '연료와 석유화학 원료 가격이 동시에 오르며 기업별 가격 전가 능력이 핵심 변수로 떠올랐다.',
    signal: '같은 유가 상승도 생산자와 소비자, 헤지 여부에 따라 손익 방향이 달라집니다.',
    marketImpact: -0.025,
    sectorImpacts: {
      '에너지': 0.065,
      '항공·우주': -0.075,
      '해운': -0.035,
      '물류': -0.03,
      '화학·소재': -0.03,
    },
  ),
  FictionalHistoricalCatalyst(
    id: '2001_global_recession',
    year: 2001,
    month: 3,
    day: 12,
    category: '세계 경기',
    title: '세계 경기후퇴 우려, 설비투자와 수출주 전망 하향',
    body: '기업 주문과 고용이 둔화하면서 경기민감 업종의 재고와 부채 부담이 부각됐다.',
    signal: '불황에서는 매출 성장보다 재고·고정비·차입 만기가 먼저 주가를 움직입니다.',
    marketImpact: -0.055,
    sectorImpacts: {'반도체': -0.04, '조선·기계': -0.035, '자동차': -0.03},
  ),
  FictionalHistoricalCatalyst(
    id: '2001_market_infrastructure_shock',
    year: 2001,
    month: 9,
    day: 11,
    category: '국제 충격',
    title: '대규모 국제 충격으로 금융·운송망 일시 마비',
    body: '결제와 항공·물류 운영에 차질이 생기며 안전자산 선호와 보안투자 수요가 동시에 커졌다.',
    signal: '운영 중단 기간, 보험 보상, 유동성 확보 여부를 업종별로 나눠 봐야 합니다.',
    marketImpact: -0.12,
    sectorImpacts: {'항공·우주': -0.09, '물류': -0.04, '금융': -0.045, '정보보안': 0.055},
  ),
  FictionalHistoricalCatalyst(
    id: '2001_china_trade_opening',
    year: 2001,
    month: 12,
    day: 11,
    category: '세계 교역',
    title: '대형 신흥경제권의 세계 무역체제 편입',
    body: '관세와 교역 규칙 변화로 소재·운송·기계 수요의 장기 확대 기대가 형성됐다.',
    signal: '시장 규모뿐 아니라 현지 경쟁, 설비 증설, 대금 회수 조건을 함께 봐야 합니다.',
    marketImpact: 0.035,
    sectorImpacts: {'조선·기계': 0.045, '해운': 0.055, '물류': 0.04, '화학·소재': 0.035},
  ),
  FictionalHistoricalCatalyst(
    id: '2002_accounting_confidence_crisis',
    year: 2002,
    month: 6,
    day: 25,
    category: '회계 신뢰',
    title: '대형 회계부정 연쇄 적발, 공시 신뢰 급락',
    body: '매출 인식과 부외부채에 대한 의심이 확산되며 현금흐름이 약한 기업의 할인율이 높아졌다.',
    signal: '손익계산서보다 영업현금흐름과 감사의견을 우선 확인해야 합니다.',
    marketImpact: -0.07,
    sectorImpacts: {'금융': -0.045, '소프트웨어': -0.035, '인터넷': -0.03},
  ),
  FictionalHistoricalCatalyst(
    id: '2002_disclosure_reform',
    year: 2002,
    month: 7,
    day: 30,
    category: '시장 제도',
    title: '경영진 공시책임·감사 독립성 강화',
    body: '회계와 내부통제 기준이 강화되며 투명한 기업과 취약한 기업의 평가 차이가 커졌다.',
    signal: '규제 강화는 단기 비용이지만 장기적으로 자금조달 신뢰를 높일 수 있습니다.',
    marketImpact: 0.025,
    sectorImpacts: {'금융': 0.02, '정보보안': 0.015},
  ),
  FictionalHistoricalCatalyst(
    id: '2003_sars_outbreak',
    year: 2003,
    month: 2,
    day: 11,
    category: '감염병',
    title: '신종 호흡기 감염병 확산, 이동·소비 위축',
    body: '국경 이동과 대면 소비가 줄고 진단·방역 제품 수요가 빠르게 늘었다.',
    signal: '환자 수뿐 아니라 이동 제한 기간과 공급망 정상화 속도가 중요합니다.',
    marketImpact: -0.055,
    sectorImpacts: {
      '항공·우주': -0.075,
      '유통': -0.04,
      '물류': -0.025,
      '바이오': 0.045,
      '의료기기': 0.045,
    },
  ),
  FictionalHistoricalCatalyst(
    id: '2003_war_energy_shock',
    year: 2003,
    month: 3,
    day: 20,
    category: '지정학',
    title: '중동 군사충돌, 에너지·운송 불확실성 확대',
    body: '원유 공급과 주요 항로의 보험료가 흔들리며 에너지 생산자와 소비 업종의 차별화가 커졌다.',
    signal: '전쟁 뉴스는 유가·운임·환율을 통해 기업 손익으로 전달됩니다.',
    marketImpact: -0.04,
    sectorImpacts: {'에너지': 0.07, '해운': 0.02, '항공·우주': -0.055},
  ),
  FictionalHistoricalCatalyst(
    id: '2003_domestic_card_liquidity',
    year: 2003,
    month: 11,
    day: 21,
    category: '국내 신용',
    title: '가계 신용과 카드채 부실 우려, 단기자금시장 경색',
    body: '연체율 상승과 차환 불안이 금융사·유통사의 유동성 위험으로 번졌다.',
    signal: '대출 성장률보다 연체율, 조달 만기, 충당금 적립을 봐야 합니다.',
    marketImpact: -0.06,
    sectorImpacts: {'금융': -0.095, '유통': -0.05, '건설': -0.03},
  ),
  FictionalHistoricalCatalyst(
    id: '2004_china_tightening',
    year: 2004,
    month: 4,
    day: 28,
    category: '신흥시장',
    title: '과열 억제 긴축 신호, 원자재·설비 수요 전망 흔들',
    body: '빠른 투자 증가에 제동이 걸릴 수 있다는 우려로 경기민감 업종의 주문 전망이 낮아졌다.',
    signal: '장기 성장과 단기 재고조정은 동시에 일어날 수 있습니다.',
    marketImpact: -0.05,
    sectorImpacts: {
      '조선·기계': -0.04,
      '해운': -0.04,
      '첨단소재': -0.035,
      '화학·소재': -0.035,
    },
  ),
  FictionalHistoricalCatalyst(
    id: '2004_oil_transport_squeeze',
    year: 2004,
    month: 10,
    day: 25,
    category: '원자재',
    title: '고유가 장기화, 운송·소비 업종 마진 압박',
    body: '연료비가 판매가격보다 빠르게 오르며 에너지 효율과 장기구매 계약의 가치가 커졌다.',
    signal: '원가 상승분을 고객에게 넘길 수 있는지가 업종별 승패를 가릅니다.',
    marketImpact: -0.03,
    sectorImpacts: {'에너지': 0.06, '항공·우주': -0.07, '물류': -0.035},
  ),
  FictionalHistoricalCatalyst(
    id: '2005_climate_policy',
    year: 2005,
    month: 2,
    day: 16,
    category: '환경 정책',
    title: '국제 온실가스 감축 체제 발효, 친환경 투자 확대',
    body: '발전·소재·운송 기업에 배출 비용과 저탄소 설비 수요가 함께 생겼다.',
    signal: '정책 수혜 기대와 실제 설비 수익률을 구분해야 합니다.',
    marketImpact: 0.012,
    sectorImpacts: {'환경': 0.055, '에너지': 0.035, '첨단소재': 0.025},
  ),
  FictionalHistoricalCatalyst(
    id: '2005_avian_flu',
    year: 2005,
    month: 8,
    day: 18,
    category: '감염병',
    title: '조류 감염병 확산, 식품·여행 수요 재편',
    body: '가금류 소비와 국제 이동이 위축되는 한편 백신·진단 투자 기대가 높아졌다.',
    signal: '수요 감소 업종과 방역 수혜 업종을 같은 방향으로 보지 않아야 합니다.',
    marketImpact: -0.025,
    sectorImpacts: {'식품': -0.05, '항공·우주': -0.04, '바이오': 0.05},
  ),
  FictionalHistoricalCatalyst(
    id: '2006_emerging_market_selloff',
    year: 2006,
    month: 5,
    day: 22,
    category: '글로벌 유동성',
    title: '금리 상승 우려로 신흥시장 자금 급이탈',
    body: '외국인 매도와 환율 상승이 겹치며 차입이 많은 경기민감주의 변동성이 커졌다.',
    signal: '외화부채와 수출 매출의 통화 구성이 충격 방향을 바꿀 수 있습니다.',
    marketImpact: -0.05,
    sectorImpacts: {'금융': -0.035, '건설': -0.03, '첨단소재': -0.025},
  ),
  FictionalHistoricalCatalyst(
    id: '2006_geopolitical_test',
    year: 2006,
    month: 10,
    day: 9,
    category: '한반도 위험',
    title: '한반도 지정학 위험 급등, 환율·외국인 수급 불안',
    body: '위험 회피 매물이 늘고 방산·보안·현금흐름 방어 업종에 관심이 쏠렸다.',
    signal: '지정학 충격은 지속 기간과 실물 교역 차질 여부가 핵심입니다.',
    marketImpact: -0.06,
    sectorImpacts: {'항공·우주': 0.03, '정보보안': 0.025, '해운': -0.03},
  ),
  FictionalHistoricalCatalyst(
    id: '2007_global_equity_correction',
    year: 2007,
    month: 2,
    day: 27,
    category: '세계 증시',
    title: '세계 증시 동반 조정, 차입 투자 청산',
    body: '위험자산 변동성이 급등하며 고평가 성장주와 외화차입 기업의 할인율이 높아졌다.',
    signal: '시장 전체 하락일에는 기업 고유 악재와 유동성 매도를 분리해야 합니다.',
    marketImpact: -0.06,
    sectorImpacts: {'금융': -0.035, '인터넷': -0.03, '바이오': -0.03},
  ),
  FictionalHistoricalCatalyst(
    id: '2007_credit_freeze',
    year: 2007,
    month: 8,
    day: 9,
    category: '신용시장',
    title: '주택연계 신용상품 손실, 단기자금시장 경색',
    body: '금융기관끼리의 신뢰가 낮아지며 건설·소비·고부채 기업의 차환 비용이 뛰었다.',
    signal: '보유자산 손실보다 자금조달 중단이 더 빠르게 기업을 흔들 수 있습니다.',
    marketImpact: -0.08,
    sectorImpacts: {'금융': -0.09, '건설': -0.06, '유통': -0.03},
  ),
  FictionalHistoricalCatalyst(
    id: '2007_emergency_rate_cut',
    year: 2007,
    month: 9,
    day: 18,
    category: '통화정책',
    title: '주요 중앙은행 금리 인하, 위험자산 반등',
    body: '신용경색 완화 기대와 경기침체 우려가 맞서며 성장주와 금융주의 변동성이 커졌다.',
    signal: '금리 인하는 호재지만 인하 이유가 심각한 경기둔화라면 실적은 별개입니다.',
    marketImpact: 0.055,
    sectorImpacts: {'금융': 0.04, '인터넷': 0.025, '소프트웨어': 0.025},
  ),
  FictionalHistoricalCatalyst(
    id: '2008_investment_bank_rescue',
    year: 2008,
    month: 3,
    day: 17,
    category: '금융위기',
    title: '대형 투자금융사 긴급구제, 거래상대방 위험 부각',
    body: '파생상품과 단기차입이 얽힌 금융기관의 자산가치와 지급능력에 의문이 커졌다.',
    signal: '장부상 자본보다 유동성, 담보가치, 거래상대방 집중도를 봐야 합니다.',
    marketImpact: -0.07,
    sectorImpacts: {'금융': -0.10, '건설': -0.04},
  ),
  FictionalHistoricalCatalyst(
    id: '2008_record_oil',
    year: 2008,
    month: 6,
    day: 30,
    category: '원자재',
    title: '기록적 고유가, 세계 경기와 소비 위협',
    body: '에너지 생산자의 현금흐름은 늘었지만 운송·자동차·화학 기업의 비용 부담이 급증했다.',
    signal: '원유 생산, 정제, 소비 업종의 손익 방향은 서로 다릅니다.',
    marketImpact: -0.04,
    sectorImpacts: {'에너지': 0.08, '항공·우주': -0.095, '자동차': -0.05, '화학·소재': -0.04},
  ),
  FictionalHistoricalCatalyst(
    id: '2008_global_bank_failure',
    year: 2008,
    month: 9,
    day: 15,
    category: '금융위기',
    title: '세계 대형 금융기관 파산, 신용시장 기능 급랭',
    body: '외화조달과 기업어음 시장이 얼어붙으며 건전한 기업도 현금 확보를 최우선으로 돌렸다.',
    signal: '위기 국면에서는 이익보다 생존 가능한 현금과 만기 구조가 먼저입니다.',
    marketImpact: -0.18,
    sectorImpacts: {'금융': -0.10, '건설': -0.065, '유통': -0.04},
  ),
  FictionalHistoricalCatalyst(
    id: '2008_coordinated_rate_cut',
    year: 2008,
    month: 10,
    day: 8,
    category: '정책 대응',
    title: '주요국 공동 금리 인하, 시장 안정 총력',
    body: '동시다발적 유동성 공급으로 극단적 신용경색이 완화될 것이라는 기대가 생겼다.',
    signal: '정책 발표 뒤 실제 대출과 회사채 거래가 살아나는지 확인해야 합니다.',
    marketImpact: 0.075,
    sectorImpacts: {'금융': 0.045, '건설': 0.035, '인터넷': 0.025},
  ),
  FictionalHistoricalCatalyst(
    id: '2008_currency_swap',
    year: 2008,
    month: 10,
    day: 30,
    category: '외환 안정',
    title: '대규모 통화교환 협정, 외화 유동성 불안 완화',
    body: '달러 조달 창구가 확보되며 금융사와 수입기업의 단기 지급 위험이 낮아졌다.',
    signal: '환율 안정은 외화부채 기업에는 호재지만 수출 가격경쟁력에는 다른 영향을 줍니다.',
    marketImpact: 0.085,
    sectorImpacts: {'금융': 0.06, '항공·우주': 0.035, '화학·소재': 0.03},
  ),
  FictionalHistoricalCatalyst(
    id: '2008_asset_purchase',
    year: 2008,
    month: 11,
    day: 25,
    category: '정책 대응',
    title: '중앙은행 대규모 자산매입, 장기금리 안정 기대',
    body: '주택·채권시장에 직접 유동성을 공급하는 비전통적 정책이 시작됐다.',
    signal: '유동성 확대가 실물 주문과 기업 실적으로 이어지는 데에는 시간이 걸립니다.',
    marketImpact: 0.065,
    sectorImpacts: {'금융': 0.05, '건설': 0.04},
  ),
  FictionalHistoricalCatalyst(
    id: '2009_recovery_rally',
    year: 2009,
    month: 3,
    day: 10,
    category: '경기 전환',
    title: '극단적 침체 완화 신호, 경기민감주 급반등',
    body: '재고조정과 정책 효과 기대가 겹치며 금융·자동차·반도체로 위험자금이 돌아왔다.',
    signal: '바닥 반등에서는 적자 축소 속도와 추가 자금조달 가능성을 확인해야 합니다.',
    marketImpact: 0.095,
    sectorImpacts: {'금융': 0.065, '자동차': 0.05, '반도체': 0.05},
  ),
  FictionalHistoricalCatalyst(
    id: '2009_h1n1_emergency',
    year: 2009,
    month: 4,
    day: 25,
    category: '감염병',
    title: '신종 인플루엔자 국제 보건비상, 여행·방역 수요 급변',
    body: '항공과 대면소비가 위축되고 백신·진단·원격서비스에 긴급 수요가 생겼다.',
    signal: '초기 공포와 실제 장기 매출을 구분하고 생산능력을 확인해야 합니다.',
    marketImpact: -0.04,
    sectorImpacts: {
      '항공·우주': -0.08,
      '유통': -0.035,
      '바이오': 0.07,
      '제약': 0.065,
      '의료기기': 0.05,
    },
  ),
  FictionalHistoricalCatalyst(
    id: '2009_property_debt_shock',
    year: 2009,
    month: 11,
    day: 27,
    category: '국제 신용',
    title: '대형 개발사업 채무상환 유예, 국가·부동산 위험 재부각',
    body: '해외 개발과 프로젝트금융에 참여한 금융·건설사의 손실 가능성이 커졌다.',
    signal: '보증과 우발채무는 대차대조표 밖에서도 주가를 흔듭니다.',
    marketImpact: -0.05,
    sectorImpacts: {'금융': -0.045, '건설': -0.06, '해운': -0.025},
  ),
  FictionalHistoricalCatalyst(
    id: '2010_market_liquidity_shock',
    year: 2010,
    month: 5,
    day: 6,
    category: '시장 구조',
    title: '초단기 주문 쏠림으로 세계 증시 순간 급락',
    body: '자동주문과 얕은 호가가 겹치며 짧은 시간에 가격이 비정상적으로 흔들렸다.',
    signal: '유동성 사고는 기업가치가 아니라 주문 구조가 만든 가격 왜곡일 수 있습니다.',
    marketImpact: -0.08,
    sectorImpacts: {'금융': -0.05, '인터넷': -0.025},
  ),
  FictionalHistoricalCatalyst(
    id: '2010_europe_stabilization',
    year: 2010,
    month: 5,
    day: 10,
    category: '정책 대응',
    title: '대규모 유럽 금융안정 장치 발표, 위험자산 반등',
    body: '국가채무 불안의 금융권 전염을 막기 위한 공동 지원책이 마련됐다.',
    signal: '구제 규모와 함께 긴축이 실물수요를 얼마나 줄일지도 봐야 합니다.',
    marketImpact: 0.06,
    sectorImpacts: {'금융': 0.04, '조선·기계': 0.025, '자동차': 0.025},
  ),
  FictionalHistoricalCatalyst(
    id: '2010_additional_asset_purchase',
    year: 2010,
    month: 11,
    day: 3,
    category: '통화정책',
    title: '추가 자산매입 발표, 달러·원자재·신흥시장 자금 이동',
    body: '저금리 장기화 기대가 커지며 성장주와 원자재, 신흥시장으로 자금이 이동했다.',
    signal: '유동성 장세에서는 실적 개선보다 할인율 변화가 주가를 먼저 움직일 수 있습니다.',
    marketImpact: 0.05,
    sectorImpacts: {'인터넷': 0.03, '바이오': 0.025, '첨단소재': 0.025},
  ),
  FictionalHistoricalCatalyst(
    id: '2010_peninsula_shock',
    year: 2010,
    month: 11,
    day: 23,
    category: '한반도 위험',
    title: '한반도 군사 긴장 급등, 외환·운송시장 경계',
    body: '외국인 위험회피와 방산·보안 수요 기대가 동시에 나타났다.',
    signal: '단기 공포와 실제 생산·교역 차질을 구분해야 합니다.',
    marketImpact: -0.07,
    sectorImpacts: {'항공·우주': 0.03, '정보보안': 0.025, '해운': -0.03},
  ),
  FictionalHistoricalCatalyst(
    id: '2000_global_rate_hike',
    year: 2000,
    month: 5,
    day: 16,
    category: '통화정책',
    title: '주요국 기준금리 인상, 성장주 할인율 상승',
    body: '과열 억제를 위한 긴축으로 차입비용이 오르고 먼 미래 이익에 의존한 기업의 평가가 낮아졌다.',
    signal: '금리가 오르면 같은 이익 전망도 현재가치와 자금조달 조건이 달라집니다.',
    marketImpact: -0.04,
    sectorImpacts: {'인터넷': -0.035, '소프트웨어': -0.03, '건설': -0.025},
  ),
  FictionalHistoricalCatalyst(
    id: '2001_energy_trader_bankruptcy',
    year: 2001,
    month: 12,
    day: 2,
    category: '기업 신용',
    title: '세계 대형 에너지거래사 파산, 부외부채 공포 확산',
    body: '복잡한 특수목적 거래와 매출 인식 문제가 드러나며 감사·신용평가 전반의 신뢰가 흔들렸다.',
    signal: '빠른 매출 성장 뒤의 현금흐름과 보증·파생계약을 확인해야 합니다.',
    marketImpact: -0.055,
    sectorImpacts: {'에너지': -0.065, '금융': -0.04},
  ),
  FictionalHistoricalCatalyst(
    id: '2003_sars_restrictions_ease',
    year: 2003,
    month: 7,
    day: 5,
    category: '감염병',
    title: '감염병 이동제한 완화, 여행·유통 수요 회복 기대',
    body: '주요 지역의 경보가 낮아지며 항공편과 대면소비가 점진적으로 정상화됐다.',
    signal: '억눌린 수요의 일시 반등과 장기 정상화 속도를 구분해야 합니다.',
    marketImpact: 0.035,
    sectorImpacts: {'항공·우주': 0.055, '유통': 0.035, '물류': 0.025},
  ),
  FictionalHistoricalCatalyst(
    id: '2004_indian_ocean_disaster',
    year: 2004,
    month: 12,
    day: 26,
    category: '자연재해',
    title: '대형 해양재난, 관광·보험·항만 운영 충격',
    body: '광범위한 인명·시설 피해로 여행과 물류가 위축되고 복구용 건설·장비 수요가 생겼다.',
    signal: '초기 피해와 보험·복구 지출이 업종별로 다른 시점에 반영됩니다.',
    marketImpact: -0.035,
    sectorImpacts: {'항공·우주': -0.05, '해운': -0.035, '건설': 0.025, '의료기기': 0.02},
  ),
  FictionalHistoricalCatalyst(
    id: '2005_hurricane_energy_disruption',
    year: 2005,
    month: 8,
    day: 29,
    category: '자연재해',
    title: '대형 허리케인, 원유생산·정제·물류시설 중단',
    body: '에너지 공급시설과 항만이 멈추며 연료가격과 운송비가 동시에 뛰었다.',
    signal: '에너지 가격 상승이 생산량 감소를 상쇄하는지 기업별로 계산해야 합니다.',
    marketImpact: -0.03,
    sectorImpacts: {'에너지': 0.045, '항공·우주': -0.05, '물류': -0.035, '화학·소재': -0.03},
  ),
  FictionalHistoricalCatalyst(
    id: '2006_missile_geopolitical_shock',
    year: 2006,
    month: 7,
    day: 5,
    category: '한반도 위험',
    title: '한반도 미사일 긴장, 외환·운송시장 위험회피',
    body: '지정학 불안으로 외국인 수급이 흔들리고 항공우주·보안 관련 수요 기대가 높아졌다.',
    signal: '정치 뉴스의 지속성과 실제 교역·생산 차질 여부를 구분해야 합니다.',
    marketImpact: -0.045,
    sectorImpacts: {'항공·우주': 0.025, '정보보안': 0.02, '해운': -0.025},
  ),
  FictionalHistoricalCatalyst(
    id: '2007_credit_fund_losses',
    year: 2007,
    month: 6,
    day: 22,
    category: '신용시장',
    title: '주택연계 투자펀드 손실, 담보가치 재평가 시작',
    body: '고수익 신용상품의 가격 산정이 어려워지며 금융기관의 레버리지와 환매 위험이 부각됐다.',
    signal: '작은 펀드 손실도 같은 담보를 보유한 금융권 전체로 번질 수 있습니다.',
    marketImpact: -0.045,
    sectorImpacts: {'금융': -0.06, '건설': -0.035},
  ),
  FictionalHistoricalCatalyst(
    id: '2008_rescue_vote_failure',
    year: 2008,
    month: 9,
    day: 29,
    category: '정책 불확실성',
    title: '금융구제안 첫 표결 실패, 세계 증시 투매',
    body: '정책 공백 우려가 커지며 현금과 단기국채로 자금이 몰리고 기업자금시장이 더 얼어붙었다.',
    signal: '정책의 규모만큼 의회·집행 가능성과 시장 도달 속도가 중요합니다.',
    marketImpact: -0.12,
    sectorImpacts: {'금융': -0.08, '건설': -0.05, '유통': -0.035},
  ),
  FictionalHistoricalCatalyst(
    id: '2009_bank_stress_results',
    year: 2009,
    month: 5,
    day: 7,
    category: '금융 안정',
    title: '대형은행 건전성 점검 공개, 자본확충 규모 가시화',
    body: '최악의 경기 가정에서도 필요한 자본 규모가 공개되며 불확실성이 일부 낮아졌다.',
    signal: '낙관적 통과 여부보다 손실 가정과 실제 자본조달 조건을 확인해야 합니다.',
    marketImpact: 0.055,
    sectorImpacts: {'금융': 0.075, '건설': 0.025},
  ),
  FictionalHistoricalCatalyst(
    id: '2010_volcanic_ash_transport',
    year: 2010,
    month: 4,
    day: 15,
    category: '운송망',
    title: '대규모 화산재로 국제 항공망 폐쇄',
    body: '여객과 고부가 항공화물 운송이 멈추며 대체 해상·육상 운송 수요가 늘었다.',
    signal: '운항 중단 일수와 화물 대체 가능성이 손익 충격을 결정합니다.',
    marketImpact: -0.025,
    sectorImpacts: {'항공·우주': -0.075, '해운': 0.025, '물류': 0.015},
  ),
  FictionalHistoricalCatalyst(
    id: '2010_offshore_oil_spill',
    year: 2010,
    month: 4,
    day: 20,
    category: '환경 사고',
    title: '대형 해양 원유유출, 에너지 안전규제 강화',
    body: '복구·배상 비용과 신규 시추 규제가 부각되고 환경측정·정화 수요가 급증했다.',
    signal: '사고기업의 직접 비용과 산업 전체의 규제비용, 정화기업 수혜를 나눠 봐야 합니다.',
    marketImpact: -0.025,
    sectorImpacts: {'에너지': -0.065, '환경': 0.075, '조선·기계': -0.025, '화학·소재': 0.02},
  ),
];

class _TechnologyOpportunityPlan {
  const _TechnologyOpportunityPlan({
    required this.technology,
    required this.company,
    required this.startDate,
    required this.agreement,
    required this.success,
    required this.pilotPositive,
    required this.strength,
  });

  final FictionalEraTechnology technology;
  final FictionalCompanyDefinition company;
  final DateTime startDate;
  final String agreement;
  final bool success;
  final bool pilotPositive;
  final double strength;
}

const _technologyAgreementModes = <String>[
  '해외 원천기술 실시권',
  '국내 독점 상용화권',
  '글로벌 플랫폼 운영 제휴',
  '핵심부품 공동개발',
  '국제표준 컨소시엄 참여',
  '완제품·서비스 합작개발',
  '국내 생산·수출 총판권',
  '공동 특허·상호사용권',
  '대학·연구소 기술이전',
  '해외기업 전략적 지분제휴',
  '국산화 조건부 장기구매',
  '공공 실증·민간 상용화 협약',
];

final _technologyPlanCache = <String, List<_TechnologyOpportunityPlan>>{};

List<_TechnologyOpportunityPlan> _technologyOpportunityPlans(String seed) {
  final cached = _technologyPlanCache[seed];
  if (cached != null) return cached;
  final plans = <_TechnologyOpportunityPlan>[];
  for (final technology in fictionalEraTechnologies) {
    final yearSpan = technology.lastYear - technology.firstYear + 1;
    final year =
        technology.firstYear +
        _fictionalHash('$seed:technology-year:${technology.id}') % yearSpan;
    final dayOffset =
        24 + _fictionalHash('$seed:technology-day:${technology.id}') % 220;
    final startDate = _nextFictionalTradingDay(
      DateTime(year, 1, 1).add(Duration(days: dayOffset)),
    );
    final candidates = _activeFictionalCompanies(
      seed,
      startDate,
    ).where((company) => technology.sectors.contains(company.sector)).toList();
    if (candidates.isEmpty) continue;
    final company =
        candidates[_fictionalHash('$seed:technology-company:${technology.id}') %
            candidates.length];
    final agreement =
        _technologyAgreementModes[_fictionalHash(
              '$seed:technology-agreement:${technology.id}:${company.id}',
            ) %
            _technologyAgreementModes.length];
    final leadSectorBonus = company.sector == technology.sectors.first
        ? 0.06
        : 0;
    final success =
        _fictionalUnit(
          seed,
          'technology-success:${technology.id}:${company.id}',
        ) >=
        0.48 - leadSectorBonus;
    plans.add(
      _TechnologyOpportunityPlan(
        technology: technology,
        company: company,
        startDate: startDate,
        agreement: agreement,
        success: success,
        pilotPositive:
            _fictionalUnit(
              seed,
              'technology-pilot:${technology.id}:${company.id}',
            ) >=
            0.5,
        strength:
            0.88 +
            _fictionalUnit(
                  seed,
                  'technology-strength:${technology.id}:${company.id}',
                ) *
                0.38,
      ),
    );
  }
  final result = List<_TechnologyOpportunityPlan>.unmodifiable(plans);
  _technologyPlanCache[seed] = result;
  return result;
}

List<FictionalMarketEvent> _eraTechnologyEventsForDate(
  String seed,
  DateTime date,
) {
  final dateKey = marketDateKey(date);
  final events = <FictionalMarketEvent>[];
  const stageOffsets = <int>[0, 24, 58, 86];
  for (final plan in _technologyOpportunityPlans(seed)) {
    for (var stage = 0; stage < stageOffsets.length; stage++) {
      final stageDate = _nextFictionalTradingDay(
        plan.startDate.add(Duration(days: stageOffsets[stage])),
      );
      if (marketDateKey(stageDate) != dateKey) continue;
      final technology = plan.technology;
      final company = plan.company;
      final direction = stage == 0
          ? true
          : stage == 1
          ? plan.pilotPositive
          : plan.success;
      final impact = switch (stage) {
        0 => 0.012 * plan.strength,
        1 => (plan.pilotPositive ? 0.026 : -0.022) * plan.strength,
        2 =>
          (plan.success
                  ? technology.successImpact
                  : -technology.failureImpact) *
              plan.strength,
        _ => (plan.success ? 0.07 : -0.06) * plan.strength,
      };
      final title = switch (stage) {
        0 => '${company.name}, ${technology.name} ${plan.agreement} 체결',
        1 =>
          '${company.name}, ${technology.name} 국산화 시험 '
              '${plan.pilotPositive ? '기준 접근' : '일정 지연'}',
        2 =>
          '${company.name}, ${technology.name} 핵심 검증 '
              '${plan.success ? '성공' : '실패'}',
        _ =>
          '${company.name}, ${technology.name} '
              '${plan.success ? '상용화·대형 고객 확보' : '손상차손·사업 재검토'}',
      };
      final body = switch (stage) {
        0 =>
          '${company.name}이 해외 기술 보유사와 ${technology.name}의 ${plan.agreement} 계약을 맺었다. 국내 규격에 맞춘 개발과 양산 검증은 이제부터 시작된다.',
        1 =>
          plan.pilotPositive
              ? '첫 시제품이 목표 성능에 접근했다. 다만 수율·원가·고객 인증은 아직 확정되지 않았다.'
              : '첫 시제품에서 성능과 원가 문제가 확인됐다. 일정 연장과 추가 개발비 가능성이 생겼다.',
        2 =>
          plan.success
              ? '핵심 성능과 양산 기준을 통과했다. 국내 공급계약과 후속 제품 매출 가능성이 열렸다.'
              : '핵심 시험에서 목표를 충족하지 못했다. 선급 기술료와 개발설비의 회수 가능성이 낮아졌다.',
        _ =>
          plan.success
              ? '초기 고객 주문과 반복 매출이 확인됐다. 회사는 생산능력과 후속 생태계 투자를 확대한다.'
              : '협약 사업을 축소하고 관련 자산의 손상차손을 반영했다. 재무 부담과 기술인력 이탈이 남았다.',
      };
      events.add(
        FictionalMarketEvent(
          id: 'technology-${technology.id}-${company.id}-$stage',
          date: dateKey,
          companyId: company.id,
          companyName: company.name,
          sector: company.sector,
          stage: stage,
          eyebrow: '시대 기술 협약',
          title: title,
          body: body,
          signal: stage < 2
              ? '협약 발표보다 실제 시제품·수율·고객 인증의 순서를 확인해야 합니다.'
              : '성공은 새 시장의 현금흐름으로, 실패는 손상차손과 추가 자금조달로 이어지는지 봐야 합니다.',
          reportHint:
              '${technology.name} 전담인력과 시험설비 지출이 늘고 있으나 공개된 최종 성능과 고객 확정 물량은 제한적이다.',
          revealMinute:
              9 * 60 +
              5 +
              _fictionalHash(
                    '$seed:technology-reveal:${technology.id}:$stage',
                  ) %
                  365,
          impactPct: impact,
          tone: !direction && stage >= 1
              ? NewsTone.shock
              : stage >= 2
              ? NewsTone.milestone
              : NewsTone.launch,
        ),
      );
    }
  }
  return events;
}

List<FictionalMarketEvent> _historicalCatalystEventsForDate(
  String seed,
  DateTime date,
) {
  final dateKey = marketDateKey(date);
  final events = <FictionalMarketEvent>[];
  for (final catalyst in fictionalHistoricalMarketCatalysts) {
    final catalystDate = _nextFictionalTradingDay(
      DateTime(catalyst.year, catalyst.month, catalyst.day),
    );
    if (marketDateKey(catalystDate) != dateKey) continue;
    final strength =
        0.82 + _fictionalUnit(seed, 'historical:${catalyst.id}') * 0.36;
    events.add(
      FictionalMarketEvent(
        id: 'historical-${catalyst.id}',
        date: dateKey,
        companyId: fictionalWholeMarketCompanyId,
        companyName: '시장 전체',
        sector: '전체시장',
        stage: 0,
        eyebrow: catalyst.category,
        title: catalyst.title,
        body: catalyst.body,
        signal: catalyst.signal,
        reportHint: '공개된 거시 지표와 업종별 비용·수요 경로를 함께 대조해야 한다.',
        revealMinute:
            8 * 60 +
            20 +
            _fictionalHash('$seed:historical-reveal:${catalyst.id}') % 420,
        impactPct: catalyst.marketImpact * strength,
        sectorImpactPcts: {
          for (final entry in catalyst.sectorImpacts.entries)
            entry.key: entry.value * strength,
        },
        tone: catalyst.marketImpact < 0 ? NewsTone.shock : NewsTone.breaking,
      ),
    );
  }
  return events;
}
