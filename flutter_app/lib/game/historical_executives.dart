class HistoricalExecutive {
  HistoricalExecutive({
    required this.recordId,
    required this.personId,
    required this.companyCodes,
    required this.companyNameKo,
    required this.nameKo,
    required this.nameEn,
    required this.roleKo,
    required this.roleNote,
    required this.startDate,
    this.endDate,
    required this.portraitAsset,
    required this.sourceLabel,
    required this.sourceUrl,
  });

  final String recordId;
  final String personId;
  final List<String> companyCodes;
  final String companyNameKo;
  final String nameKo;
  final String nameEn;
  final String roleKo;
  final String roleNote;
  final DateTime startDate;
  final DateTime? endDate;
  final String portraitAsset;
  final String sourceLabel;
  final String sourceUrl;

  bool isActiveOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (day.isBefore(startDate)) return false;
    final lastDay = endDate;
    return lastDay == null || !day.isAfter(lastDay);
  }

  String get periodLabel {
    final start = '${startDate.year}.${_twoDigits(startDate.month)}';
    final lastDay = endDate;
    if (lastDay == null) return '$start~';
    return '$start~${lastDay.year}.${_twoDigits(lastDay.month)}';
  }
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// Date-gated real-world leadership records.
///
/// The first portrait pack covers the executives visible at the beginning of
/// 2000 plus Microsoft's January 13 handover. Later handovers must be added
/// with a dated record and matching portrait before those campaign dates ship.
final List<HistoricalExecutive> historicalExecutives = [
  HistoricalExecutive(
    recordId: 'samsung_lee_kun_hee_chairman',
    personId: 'lee_kun_hee',
    companyCodes: const ['005930', 'SAMSUNG'],
    companyNameKo: '삼성전자',
    nameKo: '이건희',
    nameEn: 'Lee Kun-hee',
    roleKo: '회장',
    roleNote: '그룹의 장기 방향과 대규모 투자 판단을 이끕니다.',
    startDate: DateTime(1987, 12, 1),
    endDate: DateTime(2008, 4, 22),
    portraitAsset: 'assets/images/executives/lee_kun_hee.webp',
    sourceLabel: 'Samsung Electronics 2005 Annual Report',
    sourceUrl:
        'https://images.samsung.com/is/content/samsung/p5/co/aboutsamsung/2005_E.pdf',
  ),
  HistoricalExecutive(
    recordId: 'samsung_yun_jong_yong_ceo',
    personId: 'yun_jong_yong',
    companyCodes: const ['005930', 'SAMSUNG'],
    companyNameKo: '삼성전자',
    nameKo: '윤종용',
    nameEn: 'Yun Jong-yong',
    roleKo: '대표이사 사장 · CEO',
    roleNote: '제품과 사업 운영을 책임지는 전문경영인입니다.',
    startDate: DateTime(1997, 1, 1),
    endDate: DateTime(2008, 5, 13),
    portraitAsset: 'assets/images/executives/yun_jong_yong.webp',
    sourceLabel: 'Samsung Electronics 2005 Annual Report',
    sourceUrl:
        'https://images.samsung.com/is/content/samsung/p5/co/aboutsamsung/2005_E.pdf',
  ),
  HistoricalExecutive(
    recordId: 'apple_steve_jobs_interim_ceo',
    personId: 'steve_jobs',
    companyCodes: const ['AAPL', 'APPLE'],
    companyNameKo: 'Apple',
    nameKo: '스티브 잡스',
    nameEn: 'Steve Jobs',
    roleKo: '임시 CEO',
    roleNote: '복귀 후 제품군과 회사의 방향을 다시 정리하고 있습니다.',
    startDate: DateTime(1997, 9, 16),
    endDate: DateTime(2000, 1, 4),
    portraitAsset: 'assets/images/executives/steve_jobs.webp',
    sourceLabel: 'Apple Newsroom',
    sourceUrl:
        'https://www.apple.com/sg/newsroom/2011/08/24Steve-Jobs-Resigns-as-CEO-of-Apple/',
  ),
  HistoricalExecutive(
    recordId: 'apple_steve_jobs_ceo',
    personId: 'steve_jobs',
    companyCodes: const ['AAPL', 'APPLE'],
    companyNameKo: 'Apple',
    nameKo: '스티브 잡스',
    nameEn: 'Steve Jobs',
    roleKo: 'CEO',
    roleNote: '제품 전략과 브랜드 경험을 직접 이끕니다.',
    startDate: DateTime(2000, 1, 5),
    endDate: DateTime(2011, 8, 24),
    portraitAsset: 'assets/images/executives/steve_jobs.webp',
    sourceLabel: 'Apple Newsroom',
    sourceUrl:
        'https://www.apple.com/sg/newsroom/2011/08/24Steve-Jobs-Resigns-as-CEO-of-Apple/',
  ),
  HistoricalExecutive(
    recordId: 'microsoft_bill_gates_ceo',
    personId: 'bill_gates',
    companyCodes: const ['MSFT', 'MICROSOFT'],
    companyNameKo: 'Microsoft',
    nameKo: '빌 게이츠',
    nameEn: 'Bill Gates',
    roleKo: '회장 · CEO',
    roleNote: '2000년 1월 12일까지 경영과 기술 방향을 함께 맡습니다.',
    startDate: DateTime(1981, 6, 25),
    endDate: DateTime(2000, 1, 12),
    portraitAsset: 'assets/images/executives/bill_gates.webp',
    sourceLabel: 'Microsoft Company Facts',
    sourceUrl: 'https://news.microsoft.com/facts-about-microsoft/',
  ),
  HistoricalExecutive(
    recordId: 'microsoft_bill_gates_chairman',
    personId: 'bill_gates',
    companyCodes: const ['MSFT', 'MICROSOFT'],
    companyNameKo: 'Microsoft',
    nameKo: '빌 게이츠',
    nameEn: 'Bill Gates',
    roleKo: '회장 · 최고 소프트웨어 설계자',
    roleNote: 'CEO 이양 뒤에도 제품과 장기 기술 방향을 맡습니다.',
    startDate: DateTime(2000, 1, 13),
    endDate: DateTime(2006, 6, 14),
    portraitAsset: 'assets/images/executives/bill_gates.webp',
    sourceLabel: 'Microsoft 2000 Annual Report',
    sourceUrl: 'https://www.microsoft.com/investor/reports/ar00/lts.htm',
  ),
  HistoricalExecutive(
    recordId: 'microsoft_steve_ballmer_ceo',
    personId: 'steve_ballmer',
    companyCodes: const ['MSFT', 'MICROSOFT'],
    companyNameKo: 'Microsoft',
    nameKo: '스티브 발머',
    nameEn: 'Steve Ballmer',
    roleKo: '사장 · CEO',
    roleNote: '2000년 1월 13일부터 회사 운영 전반을 책임집니다.',
    startDate: DateTime(2000, 1, 13),
    endDate: DateTime(2014, 2, 3),
    portraitAsset: 'assets/images/executives/steve_ballmer.webp',
    sourceLabel: 'Microsoft Company Facts',
    sourceUrl: 'https://news.microsoft.com/facts-about-microsoft/',
  ),
  HistoricalExecutive(
    recordId: 'cisco_john_chambers_ceo',
    personId: 'john_chambers',
    companyCodes: const ['CSCO', 'CISCO'],
    companyNameKo: 'Cisco',
    nameKo: '존 체임버스',
    nameEn: 'John T. Chambers',
    roleKo: '사장 · CEO',
    roleNote: '인터넷 네트워크 장비 사업의 확장과 인수를 이끕니다.',
    startDate: DateTime(1995, 1, 1),
    endDate: DateTime(2015, 7, 25),
    portraitAsset: 'assets/images/executives/john_chambers.webp',
    sourceLabel: 'Cisco 2000 Annual Report',
    sourceUrl:
        'https://www.cisco.com/c/dam/en_us/about/ac49/ac20/downloads/annualreport/ar2000/pdf/Cisco_00_AR.pdf',
  ),
  HistoricalExecutive(
    recordId: 'toyota_fujio_cho_president',
    personId: 'fujio_cho',
    companyCodes: const ['7203', 'TM', 'TOYOTA'],
    companyNameKo: 'Toyota',
    nameKo: '후지오 조',
    nameEn: 'Fujio Cho',
    roleKo: '사장',
    roleNote: '생산 혁신과 해외 사업 운영을 이끄는 최고경영자입니다.',
    startDate: DateTime(1999, 6, 23),
    endDate: DateTime(2005, 6, 22),
    portraitAsset: 'assets/images/executives/fujio_cho.webp',
    sourceLabel: 'Toyota Executive Changes',
    sourceUrl: 'https://global.toyota/en/detail/249266',
  ),
  HistoricalExecutive(
    recordId: 'sony_nobuyuki_idei_ceo',
    personId: 'nobuyuki_idei',
    companyCodes: const ['6758', 'SONY'],
    companyNameKo: 'Sony',
    nameKo: '노부유키 이데이',
    nameEn: 'Nobuyuki Idei',
    roleKo: '회장 · CEO',
    roleNote: '전자제품과 엔터테인먼트를 잇는 디지털 전략을 이끕니다.',
    startDate: DateTime(1999, 6, 29),
    endDate: DateTime(2005, 6, 21),
    portraitAsset: 'assets/images/executives/nobuyuki_idei.webp',
    sourceLabel: 'Sony Corporate Executive Appointments',
    sourceUrl:
        'https://www.sony.com/en/SonyInfo/News/Press_Archive/199906/99-057/',
  ),
  HistoricalExecutive(
    recordId: 'softbank_masayoshi_son_ceo',
    personId: 'masayoshi_son',
    companyCodes: const ['9984', 'SOFTBANK'],
    companyNameKo: 'SoftBank',
    nameKo: '손정의',
    nameEn: 'Masayoshi Son',
    roleKo: '사장 · CEO',
    roleNote: '인터넷 기업 투자와 통신 사업 확장을 직접 지휘합니다.',
    startDate: DateTime(1981, 9, 3),
    portraitAsset: 'assets/images/executives/masayoshi_son.webp',
    sourceLabel: 'SoftBank 2000 Annual Report',
    sourceUrl:
        'https://group.softbank/system/files/pdf/ir/financials/annual_reports/annual-report_fy2000_01_en.pdf',
  ),
  HistoricalExecutive(
    recordId: 'skt_cho_jung_nam_president',
    personId: 'cho_jung_nam',
    companyCodes: const ['017670', 'SKT'],
    companyNameKo: 'SK텔레콤',
    nameKo: '조정남',
    nameEn: 'Cho Jung-nam',
    roleKo: '대표이사 사장',
    roleNote: '이동통신 성장기의 경영과 망 투자를 책임집니다.',
    startDate: DateTime(1998, 1, 1),
    endDate: DateTime(2000, 12, 12),
    portraitAsset: 'assets/images/executives/cho_jung_nam.webp',
    sourceLabel: 'SK Telecom 2000 Leadership Release',
    sourceUrl: 'https://www.sktelecom.com/en/press/press_detail.do?idx=131',
  ),
  HistoricalExecutive(
    recordId: 'posco_yoo_sang_boo_ceo',
    personId: 'yoo_sang_boo',
    companyCodes: const ['005490', 'POSCO'],
    companyNameKo: '포항제철',
    nameKo: '유상부',
    nameEn: 'Yoo Sang-boo',
    roleKo: '이사회 의장 · CEO',
    roleNote: '민영화 전환기의 철강 사업과 경영 혁신을 이끕니다.',
    startDate: DateTime(1998, 3, 17),
    endDate: DateTime(2003, 3, 14),
    portraitAsset: 'assets/images/executives/yoo_sang_boo.webp',
    sourceLabel: 'POSCO 2001 Environmental Progress Report',
    sourceUrl:
        'https://www.posco.com/homepage/docs/eng6/jsp/dn/irinfo/2001_environment_en.pdf',
  ),
  HistoricalExecutive(
    recordId: 'hyundai_chung_mong_koo_ceo',
    personId: 'chung_mong_koo',
    companyCodes: const ['005380', 'HYUNDAI'],
    companyNameKo: '현대자동차',
    nameKo: '정몽구',
    nameEn: 'Chung Mong-koo',
    roleKo: '회장 · CEO',
    roleNote: '품질 개선과 글로벌 생산·수출 확대를 이끕니다.',
    startDate: DateTime(1999, 1, 1),
    endDate: DateTime(2020, 10, 13),
    portraitAsset: 'assets/images/executives/chung_mong_koo.webp',
    sourceLabel: 'Hyundai Motor Group Profile',
    sourceUrl:
        'https://www.hyundai.com/content/hyundai/worldwide/en/newsroom/detail/hyundai-motor-group-honorary-chairman-mong-koo-chung-inducted-into-automotive-hall-of-fame-at-official-ceremony-0000000496.html',
  ),
];

List<HistoricalExecutive> executivesForCompany(
  String companyCode,
  DateTime date,
) {
  final normalizedCode = companyCode.toUpperCase();
  return historicalExecutives
      .where(
        (executive) =>
            executive.companyCodes.contains(normalizedCode) &&
            executive.isActiveOn(date),
      )
      .toList(growable: false);
}
