# 가상시장 레퍼런스와 데이터 원칙

## 현재 데이터 구조

게임은 실제 종가 원장이나 실종목 목록을 배포하지 않는다. `flutter_app/lib/game/fictional_market.dart`가 다음을 월드시드로 생성한다.

- 고정 출발 기업 30개
- 2000~2010 일별 종가와 장중 경로의 기준값
- 분사 후보와 매년 신규상장 기업
- 업종별 연속 사건, 유상증자, 분할, 신규상장, 상장폐지
- `market_era_events.dart`의 2000~2010 시대 기술 80종과 시장 촉매 44종
- 18개 기업 사건 대분류 아래 실적·회계·수주·공급망·환율·원자재·특허·소송·M&A·노무 등 독립 인과 문법 144종
- 오늘의 비공개 시나리오와 장중 공개 시각

같은 시드와 같은 선택은 같은 세계를 만든다. 새 게임은 새 시드를 받아 기업 이름은 같아도 미래가 달라진다. 과거의 `market-history.json`, 실경영진 초상, 실제시장 수집 스크립트는 제품에서 제거했다.

## 26년치 현실을 참고하는 방법

2000년 이후 국내 시장에서 반복된 공시·산업 사건을 “사실 사전”이 아니라 “인과 문법”으로 참고한다. 예를 들어 `대규모 투자 → 자금 부담 → 수율 검증 → 고객 인증 → 증설 회수`나 `수주 증가 → 원재료 상승 → 공정 지연 → 인도 → 충당금` 같은 순서를 추출한다.

실제 회사명, 인물명, 기사 문장과 기업별 실적 수치를 가상기업에 그대로 이식하지 않는다. 복수 사례에서 공통 구조를 뽑고 업종·제품·회사 체력·시드에 맞춰 다시 조합한다. 세계 경기·감염병·통화정책처럼 시장 전체가 실제로 함께 겪은 사건은 연도와 공개일을 시대 앵커로 사용할 수 있지만, 기사 문장과 실제 상장사 이름은 쓰지 않고 충격 강도와 업종 전이는 월드시드로 다시 계산한다.

## 2000~2026 연대별 사건 문법 매트릭스

이 표는 특정 사건을 재현하는 시나리오가 아니라, 26년간 반복된 충격의 전이 순서를 사건 생성기에 주는 편집표다.

| 기간 | 권위 레퍼런스에서 추출한 문법 | 게임용 재조합 |
| --- | --- | --- |
| 2000~2002 | IT 기대로 가격·상장·조달이 빠르게 늘은 뒤 버블 조정으로 자금조달 기능까지 위축됨 | 신기술 기대 → 고평가 신규상장 → 실적 검증 지연 → 증자·투자 취소 |
| 2003~2005 | 신용 확장 뒤 연체·부실이 커지고, 한도 축소·부실채권 정리·심사 강화로 반전 | 고성장 결제·금융 → 연체 신호 → 자산건전성 악화 → 영업 축소·자본 조달 |
| 2006~2009 | 대규모 수주·증설이 원자재·환율·고정비 부담과 맞물리고, 글로벌 신용경색이 실물 위축으로 전이 | 수주 호황 → 설비투자 → 원가 변동 → 차환 어려움 → 충당금·구조조정 |
| 2010~2012 | 유럽 재정불안·지정학·원자재 변동이 외국인 자금과 환율을 거쳐 업종별 실적 기대를 바꿈 | 대외 악재 → 외국인 수급·환율 급변 → 수출주 마진 변화 → 안전자산 선호 완화 |
| 2013~2016 | 통화정책 정상화 우려·중국 둔화로 신흥국 자금유출과 가격 변동이 반복 | 성장률 둥화 신호 → 원화·원자재 변동 → 재고·수출 조정 → 보수적 설비투자 |
| 2017~2019 | 반도체 호황과 고객 편중이 이익을 키운 뒤 재고 사이클과 수출 편중 위험이 드러남 | 수요 급증 → 수율·증설 경쟁 → 재고 증가 → 가동률·판가 조정 |
| 2020~2021 | 팬데믹 충격 후 유동성·개인투자·대형 IPO가 겹치며 신용공여와 청약 수요가 급증 | 영업 중단 → 정책 유동성 → 비대면 수요·신규상장 과열 → 실적과 밸류에이션 검증 |
| 2022~2024 | 금리 상승과 PF-ABCP 차환 어려움이 단기자금시장·건설·증권사 유동성으로 확산 | 사업성 저하 → 차환 실패 → 보증채무·연체 확대 → 정책자금·대주단 재구조화 |
| 2025~2026 | 물적분할 자회사 상장의 주주보호와 상장관리·공시 절차가 강화됨 | 이사회 검토 → 분할 공시 → 주주보호 조치 → 신규상장 심사·거부·지연 |

생성기는 연대를 그대로 순서대로 재생하지 않는다. 예를 들어 2003년형 신용경색이 다른 월드에서는 온라인 결제사나 건설 PF의 자금경색으로 변형될 수 있다.

## 1차 권위 자료

### 공시·상장·기업행동

- KRX KIND 주식발행 내역: https://kind.krx.co.kr/corpgeneral/stockissuelist.do?method=loadInitPage
- KRX 상장심사·상장 안내: https://kind.krx.co.kr/listinvstg/listinvstginfo.do?method=searchListInvstgInfoMain
- KRX 2025 상장 가이드북: https://kind.krx.co.kr/external/dst/guidebook/2025_KRX_guidebook.pdf
- KRX 2025 코스닥 공시·상장관리 해설서: https://kind.krx.co.kr/external/dst/reference/11499/%28%EA%B3%B5%EC%A7%80%2925%EB%85%84%EC%BD%94%EC%8A%A4%EB%8B%A5%EC%8B%9C%EC%9E%A5%EA%B3%B5%EC%8B%9C%EC%83%81%EC%9E%A5%EA%B4%80%EB%A6%AC%ED%95%B4%EC%84%A4%EC%84%9C.pdf
- KRX 2026 유가증권시장 공시·상장 업무해설서: https://kind.krx.co.kr/external/dst/reference/11635/%EC%9C%A0%EA%B0%80%EC%A6%9D%EA%B6%8C%EC%8B%9C%EC%9E%A5%20%EA%B3%B5%EC%8B%9C_%EC%83%81%EC%9E%A5%20%EC%97%85%EB%AC%B4%ED%95%B4%EC%84%A4%EC%84%9C.pdf
- DART 최근 정정공시: https://dart.fss.or.kr/dsac003/mainK.do
- DART 주요사항보고서 안내: https://dart.fss.or.kr/info/main.do?menu=220
- DART 합병·분할 안내: https://dart.fss.or.kr/info/main.do?menu=240
- DART 지분·자본변동 안내: https://dart.fss.or.kr/info/main.do?menu=310
- 금융감독원 물적분할 자회사 상장 시 주주보호 방안: https://dart.fss.or.kr/dsaa003/selectBodoMain.ax?seqno=24865
- 금융감독원 물적분할 관련 심사 현황: https://dart.fss.or.kr/dsaa003/selectBodoMain.ax?seqno=26201

이 자료에서 신규상장, 유상증자, 제3자배정, 합병·분할, 관리종목, 감사의견, 자본잠식, 상장폐지의 상태 전이와 공개 순서를 참고한다.

### 업종 문법

- 조선 수주·선종·산업주기 공시 사례: https://kind.krx.co.kr/external/2026/03/12/001651/20260312003896/11011.htm
- 조선 원가·후판 가격 공시 사례: https://kind.krx.co.kr/external/2025/05/15/002003/20250515004703/11013.htm
- 반도체 장비·소재 수요 공시 사례: https://kind.krx.co.kr/external/2026/05/14/000227/20260514000416/11013.htm
- 자동차 생산과 차량용 부품 공급 공시 사례: https://kind.krx.co.kr/external/2026/04/23/000745/20260423001869/10002.htm
- 바이오 임상·허가 절차 공시 사례: https://kind.krx.co.kr/external/2025/05/15/002815/20250515006591/11013.htm
- 건설 프로젝트금융 위험 공시 사례: https://kind.krx.co.kr/external/2026/01/19/000955/20260119002096/10002.htm
- 이차전지 원재료 가격·공급 공시 사례: https://kind.krx.co.kr/external/2024/09/30/000937/20240930001782/10001.htm
- 반도체 세정·수율 공시 사례: https://kind.krx.co.kr/external/2026/03/23/002207/20260323009212/11011.htm

### 연대별 시장 충격·수급

- 한국은행 IT 버블과 코스닥 자금조달 위축 설명: https://www.bok.or.kr/portal/bbs/B0000217/view.do?menuNo=200144&nttId=10070532
- 한국은행 2003~2004 신용카드 이용·연체·부실정리 자료: https://www.bok.or.kr/portal/bbs/P0000720/view.do?menuNo=200570&nttId=53661
- 한국은행 2008년 금융·외환시장 동향: https://www.bok.or.kr/portal/bbs/P0000551/view.do?menuNo=200484&nttId=148295
- 한국은행 2010년 유럽 재정불안·지정학·자본유출입 자료: https://www.bok.or.kr/portal/bbs/P0000551/view.do?menuNo=200484&nttId=167373&pageIndex=12
- 한국은행 2011년 유럽 재정위기와 시장 변동성 연구: https://www.bok.or.kr/portal/bbs/P0002353/view.do?menuNo=200433&nttId=190544
- 한국은행 2013~2015 테이퍼링·중국 둔화·신흥국 금융불안 비교: https://www.bok.or.kr/portal/bbs/P0000528/view.do?menuNo=200431&nttId=10048320
- 한국은행 2020년 이후 개인투자·해외증권 수요 변화: https://www.bok.or.kr/portal/bbs/B0000347/view.do?menuNo=201106&nttId=10082962
- 금융위원회 2022년 회사채·은행채 구축효과 대응: https://fsc.go.kr/no010101/78809
- 금융위원회 2022~2023 PF-ABCP 차환·유동성 악순환 자료: https://www.fsc.go.kr/po010102/80034

### 2000~2010 기술·세계시장 시대 앵커

- Apple 2007 멀티터치 스마트 단말 발표: https://www.apple.com/newsroom/2007/01/09Apple-Reinvents-the-Phone-with-iPhone/
- Google 2006 사용자 동영상 플랫폼 인수 발표: https://googlepress.blogspot.com/2006/10/google-to-acquire-youtube-for-165_09.html
- Android Developers 2008 개방형 스마트폰 SDK 1.0: https://android-developers.googleblog.com/2008/09/announcing-android-10-sdk-release-1.html
- Apple 2008 모바일 응용프로그램 장터 초기 확산: https://www.apple.com/newsroom/2008/07/14iPhone-App-Store-Downloads-Top-10-Million-in-First-Weekend/
- AWS 2006 인터넷 객체저장 서비스 공개: https://aws.amazon.com/about-aws/whats-new/2006/03/13/announcing-amazon-s3---simple-storage-service/
- 3GPP LTE Release 8 표준화 연혁: https://www.3gpp.org/ftp/information/presentations/presentations_2010/2010_06_Latin_America/3GPP%20RAN_3GPP%20seminar%20in%20Miami_rev4.pdf
- ITU IMT-2000과 2000~2001 3세대 이동통신 상용화: https://www.itu.int/ITU-D/ict/update/pdf/Update_2_01.pdf
- Bluetooth SIG 2000년 근거리 무선기기 상용화: https://www.bluetooth.com/bluetooth-le-primer/
- NHGRI 2001 유전체 초안과 2003 인간게놈프로젝트 완료 연표: https://www.genome.gov/human-genome-project/timeline
- FDA 2006 예방형 바이러스 백신 최초 허가 근거: https://www.fda.gov/downloads/BiologicsBloodVaccines/Vaccines/ApprovedProducts/UCM622941.pdf
- 미국 에너지부 2000~2007 반도체 조명 연구·상용화 연혁: https://www.energy.gov/cmei/ssl/technology-roadmap-archives
- WTO 중국 가입일과 무역체제 편입: https://www.wto.org/english/thewto_E/countries_E/china_E.htm
- Federal Reserve 2001년 9월 금융시장 충격: https://www.federalreservehistory.org/essays/september-11
- Federal Reserve 2007~2009 세계 금융위기: https://www.federalreservehistory.org/essays/great-recession-of-200709
- SEC 2002 회계 스캔들과 공시·감사 개혁: https://www.sec.gov/news/extra/initsfy2002.htm
- WHO 2003 SARS 연표: https://www.who.int/emergencies/disease-outbreak-news/item/2003_07_04-en
- WHO 2005 H5N1 확산: https://www.who.int/emergencies/disease-outbreak-news/item/2005_08_18-en
- WHO 2009 H1N1 국제 보건비상 연표: https://www.who.int/groups/h1n1-ihr-emergency-committee
- IEA 2008 기록적 고유가와 공급 제약: https://www.iea.org/news/despite-slowing-oil-demand-iea-sees-continued-market-tightness-over-the-medium-term
- 한국은행 2008년 금융·외환시장 동향: https://www.bok.or.kr/portal/bbs/P0000551/view.do?menuNo=200484&nttId=148295

이 자료는 실제 브랜드를 게임에 재현하기 위한 목록이 아니다. 발표 연도와 산업 파급 순서만 사용해 12가지 협약 방식과 `해외 원천기술 협약 → 국내 시제품 → 양산 검증 → 성공·실패 → 상용화·손상차손`으로 변환한다.

### 시장 규모와 산업 통계

- e-나라지표 상장회사 수: https://www.index.go.kr/unity/potal/main/EachDtlPageDetail.do?idx_cd=1079
- e-나라지표 조선산업 지표: https://www.index.go.kr/unity/potal/main/EachDtlPageDetail.do?idx_cd=1151

## 편집·저작권 규칙

1. 한 사건을 만들 때 최소 두 개 이상의 현실 사례에서 공통 인과를 뽑는다.
2. 기사 제목과 본문을 베끼지 않는다.
3. 실제 회사와 가상회사가 일대일로 대응한다고 적지 않는다.
4. 수치 범위는 게임 밸런스로 다시 만든다.
5. 업종 허용표를 통과하지 못한 조합은 생성 단계에서 제외한다.
6. 현실 사례의 결과를 오늘 신문이나 유료 보고서로 미리 누설하지 않는다.
7. 새 레퍼런스를 추가하면 URL, 자료 종류, 추출한 인과 문법을 이 문서에 기록한다.
