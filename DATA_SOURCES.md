# 가상시장 레퍼런스와 데이터 원칙

## 현재 데이터 구조

게임은 실제 종가 원장이나 실종목 목록을 배포하지 않는다. `flutter_app/lib/game/fictional_market.dart`가 다음을 월드시드로 생성한다.

- 고정 출발 기업 50개
- 2000~2026 일별 종가와 장중 경로의 기준값
- 분사 후보와 매년 신규상장 기업
- 업종별 연속 사건, 유상증자, 분할, 신규상장, 상장폐지
- `market_era_events.dart`의 2000~2026 시대 기술 112종과 초기 시장 촉매 44종
- 18개 기업 사건 대분류 아래 실적·회계·수주·공급망·환율·원자재·특허·소송·M&A·노무 등 독립 인과 문법 144종
- `market_corpus_calibration.dart`의 익명화된 사건 반응 439개와 거래일 수치 표본 6,545개
- `market_corpus_calendar.dart`의 2000-01-04~2026-07-23 실제 거래일 6,545개
- `market_corpus_events.dart`의 시드형 시장 전체 서사 16종과 42거래일 단위 변동성 군집
- 오늘의 비공개 시나리오와 장중 공개 시각

같은 시드와 같은 선택은 같은 세계를 만든다. 새 게임은 새 시드를 받아 기업 이름은 같아도 미래가 달라진다. 과거의 `market-history.json`, 실경영진 초상, 실제시장 수집 스크립트는 제품에서 제거했다.

## 공통 경제 사건의 원천과 경계

`market_era_events.dart`의 `fictionalSharedEconomyEventsThrough`가 주식시장
객체 중 다른 자산에도 의미가 있는 사건만 내보낸다. 별도 외부 데이터셋이나
두 번째 거시 생성기는 사용하지 않는다.

포함 범위:

- 주식 가격에 이미 반영된 시드형 실물경제 역사 촉매
- 타임라인 코퍼스 시장 서사의 최초 `stage == 0` 거시 충격
- 원본과 같은 ID·발생일·제목·본문·이미 시드화된 `impactPct`

제외 범위:

- 급격한 호가 유동성 사고, 공매도 중단·재개, 레버리지 청산 등 순수 시장구조
- 개별 기업·생애주기 사건과 코퍼스 후속 단계

`world_economy.dart`는 원본 강도를 다시 해시하지 않고 사업과 부동산의
도메인별 효과로만 투영한다. 주식 가격·종가·장중 경로에는 새 거시 배율을
추가하지 않는다. 주식에서 08:00 이후 공개되는 장중 사건은 날짜 단위
사업·부동산에 다음 달력일부터 공개하며, 수치 효과가 활성화된 사건은 최근
목록 제한보다 우선해 계속 확인할 수 있다.

부동산 14개 중심 지역과 상권 32곳의 관계는
`worldEconomyBusinessDistrictByRealEstateDistrict` 한 곳에서 관리한다. 이
매핑과 공통 사건 투영은 새로운 원자료가 아니라 동일 월드시드 세계를 연결하는
게임 규칙이다. 지역 고유 상권 사건 49개와 부동산의 교통·재개발·건물·
`commercialCycle`·`demographicShift` 사건은 별도 로컬 원인으로 유지한다.

## 로컬 타임라인 코퍼스 반영

사용자가 제공한 `한국주식시장_2000_2026_사건_주가_타임라인.txt` 12,856,912바이트를 빌드 입력으로 사용했다. BOM을 제거한 본문의 SHA-256은 `d5bff9afc0b7afa1f00453a6df67f6e5ef54c04ad42ded2eef16dd7ce753fd6e`이며, 파서는 다음 개수를 고정 검증한다.

- 큐레이션 사건: 439개
- 충격일: 975개
- 전체 거래일: 6,545개
- 시장 충격 서사 템플릿: 16개

`scripts/generate-market-corpus.mjs`는 사건 제목·기사·실제 회사명을 버리고 12개 일반 채널, 당일·5일·20일·60일 대형/성장시장 반응, 신뢰도와 연도만 남긴다. 전체 거래일은 대형/성장시장의 수익률·일중 범위·시가 갭·20일 변동성을 정수 bps로 보존한다. 거래일 날짜는 별도 달력으로 분리해 설·추석·연말 휴장 판정에 사용한다. 런타임은 42거래일 묶음을 월드시드로 골라 변동성 군집을 만들고, 사건 반응은 월별 시장 전체 3단계 사건의 강도와 방향을 보정한다. 절대 지수값, 종목명과 기사 문장은 유저 화면에 재생하지 않는다.

재생성 명령:

```powershell
node scripts/generate-market-corpus.mjs <timeline.txt> flutter_app/lib/game/market_corpus_calibration.dart flutter_app/lib/game/market_corpus_calendar.dart
```

원본 TXT는 용량과 출처 경계 때문에 앱·저장소에 복사하지 않는다. 생성된 Dart 표본·거래일 달력과 SHA-256·개수 상수로 변환 결과만 추적한다. 원본 마지막 날 다음인 2026-07-24부터 캠페인 종료일까지는 실제 미래를 단정하지 않고 가상시장 기본 달력과 월드시드 사건을 사용한다.

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

## 호가·체결 미시구조의 1차 자료와 게임 변환

가격단위, 최우선호가와 연속매매 원칙은 한국거래소의 시장별 규정 설명을
기준으로 대조한다.

- 유가증권시장 가격단위:
  https://regulation.krx.co.kr/contents/RGL/03/03010100/RGL03010100T3.jsp
- 코스닥시장 가격단위:
  https://regulation.krx.co.kr/contents/RGL/03/03020100/RGL03020100.jsp
- 유가증권시장 연속매매·가격 및 시간 우선:
  https://regulation.krx.co.kr/contents/RGL/03/03010203/RGL03010203.jsp
- 코스닥시장 연속매매·가격 및 시간 우선:
  https://regulation.krx.co.kr/contents/RGL/03/03020205/RGL03020205.jsp
- 최우선호가와 직전 체결가격의 구분:
  https://regulation.krx.co.kr/contents/RGL/03/03020204/RGL03020204.jsp
- 시장가 주문과 상대 주문의 우선순위:
  https://regulation.krx.co.kr/contents/RGL/03/03010205/RGL03010205.jsp
- KRX 영문 주식시장 거래 가이드:
  https://global.krx.co.kr/contents/GLB/01/0109/0109000000/guide_to_trading_in_the_korean_stock_market.pdf

현재 일반주권의 20,000원 이상 50,000원 미만 구간은 유가증권시장과
코스닥시장 모두 50원 단위다. 따라서 32,150원 바로 위의 유효가격은
32,200원이다. 연속매매는 가장 낮은 매도호가와 가장 높은 매수호가를 가격
우선으로 대조하고 같은 가격에서는 시간 우선으로 처리한다. 화면의 현재가·
최근 체결가는 직전 실제 체결가격이고, 최우선 매도·매수호가는 아직 남은
주문 중 각각 가장 낮고 높은 가격이므로 서로 같은 개념이 아니다.

실제 KRX 주문장에는 중간 가격에 주문이 없을 수 있어 최우선호가 사이의 공백이
허용되고 1주 주문도 가능하다. 이 게임의 `일일 예상 거래대금 20억원 이상이면
바깥 호가와 구조 공백까지 생성형 가시 사다리의 모든 유효 틱을 잇는다`와
`생성한 양수 큐를 최소 10주로 표시`는 거래소의 적법성 규칙이 아니라, 가짜
공백·1주짜리 인공 벽과 시각적 리셋을 막기 위한 시뮬레이션 밸런스 계약이다.
20억원 미만 저유동주만 실제 시장처럼 결정론적 내부·최우선 빈 가격을 허용한다.
이 구분을 새 기능 설명에서 `KRX가 공백 또는 1주 주문을 금지한다`는 식으로
바꾸면 안 된다.

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

## 서울·경기 부동산 가격·거래비용

### 1차 자료

- 국토교통부 실거래가 공개시스템 GIS: https://rt.molit.go.kr/pt/gis/gis.do?mobileAt=&srhThingSecd=C
- 서울 열린데이터광장 부동산 실거래가 정보: https://data.seoul.go.kr/dataList/OA-21275/A/1/datasetView.do
- 한국부동산원 상업용부동산 임대동향조사: https://www.reb.or.kr/reb/cm/cntnts/cntntsView.do?cntntsId=1049&mi=10335&statId=S237220284
- 서울시 부동산 중개보수 요율표: https://land.seoul.go.kr/land/broker/brokerageCommission.do
- 서울시 부동산 취득세 안내: https://news.seoul.go.kr/gov/archives/200082

### 개별 거래 기준점 보조 자료

- 2025 한남더힐·나인원한남·아크로서울포레스트·래미안원베일리 고가 거래 정리: https://www.newsspace.kr/mobile/article.html?no=6720
- 판교푸르지오그랑블·과천푸르지오써밋·광교중흥S클래스 거래 정리: https://v.daum.net/v/zElHpUe756?f=m
- 2025 판교 테크원 매각 보도: https://www.yna.co.kr/view/AKR20251013110200008
- 2018 센트로폴리스·삼성물산 서초사옥·알파돔시티 매각 보도: https://www.yna.co.kr/view/AKR20190103150600003
- 2025 SI타워 매각 보도: https://www.yna.co.kr/view/AKR20250807046000003

적용 규칙:

1. 실제 이름을 쓰는 아파트는 면적과 거래 시점을 함께 고정하고 실제 거래 앵커만 `실거래`로 표시한다.
2. 실제 이름을 쓰는 빌딩은 공개된 전체 매각대금만 `실제 빌딩 매각`으로 표시한다.
3. 2000~2005와 실거래 앵커 사이 값은 지수 역산·보간 또는 시장평가이며 실거래로 표시하지 않는다.
4. 2026 최신 미공개 구간은 `게임 연장`으로 표시한다.
5. 세금과 중개보수는 게임이 다주택 여부·법인 구조·면제·누진 예외를 모두 알 수 없으므로 단순화된 추정치로 고지한다.
