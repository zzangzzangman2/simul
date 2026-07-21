# 데이터 출처와 실사 기준

## 현재 국내 중심 스냅샷

`app/data/market-history.json`과 `flutter_app/assets/market/market-history.json`은 같은 스키마 3 원장을 사용합니다. `prices`는 거래일의 원시 일별 종가이고, `adjustedIndex`는 분할·배당을 반영한 수정주가를 기준일=100으로 만든 보조 수익률 지수입니다.

| 화면 탭 | 현재 기본 팩 | 용도 |
| --- | ---: | --- |
| 국내·KOSPI | 19개 | 2000년 첫 거래일부터 국내 핵심 플레이 |
| 국내·KOSDAQ | 3개 | 새롬기술·한글과컴퓨터·에스엠엔터테인먼트의 상장 이후 흐름 |
| 해외 | 6개 | Apple·Microsoft·Cisco·Toyota·Sony·SoftBank 데이터 보존과 후반 확장 |

현재 국내 22개는 전 종목 완전판이 아니라 Yahoo Finance chart endpoint에서 2000~2010 원시 종가를 검증할 수 있었던 개발용 기본 팩입니다. 삼성전자의 첫 제공 거래일은 2000-01-04이고 종가는 6,110원입니다. 종목별 첫 관측 전에는 미래 가격을 미리 보여주지 않습니다.

Flutter의 0.9초 장중 틱은 실제 체결 데이터가 아닙니다. 08:00 이전 종가에서 출발해 15:30의 150번째 틱을 실제 당일 종가에 고정합니다. 이후 NXT형 확장장은 종가 주변에서 변동한 뒤 20:00의 240번째 틱에 다시 실제 종가로 닫습니다. 주말·휴장일에는 틱을 만들지 않고 직전 종가를 유지합니다.

Flutter v8의 장중 주문과 AUM은 화면에 보이는 현재 생성 틱으로 계산합니다. 15:30 틱은 확정된 실제 일별 종가와 같고, 15:40 이후 확장장은 다시 게임용 생성 가격으로 표시하다가 20:00에 실제 종가로 닫습니다. 주문창에서 장 마감값을 미리 보여주거나 확장장 가격을 실제 종가로 부르지 않습니다. 생성 장중 틱과 Gemini 기사 영향점수는 실제 종가 원장을 덮어쓰지 않으며, 화면에서도 게임용 연출로 구분합니다. USD·JPY를 원화처럼 합산하지 않도록 해외 주문과 원화 AUM 환산은 실제 환율 원장을 연결하기 전까지 잠급니다.

## KRX 전 종목 자동 생성기

`scripts/fetch-krx-full-market.py`는 2000~2010의 모든 평일 KOSPI·KOSDAQ 상장목록 합집합을 만든 뒤 각 종목의 원시 일별 종가를 수집합니다. 따라서 한 달 안에 상장·폐지된 종목까지 현재 생존 종목 목록에서 누락시키는 생존편향을 피하도록 설계했습니다.

```powershell
python -m pip install -r scripts/requirements-market.txt
$env:KRX_ID='개인 KRX 계정'
$env:KRX_PW='로컬에서만 설정'
npm run data:fetch:krx-full
```

2026-07-21 시험에서는 KRX_ID·KRX_PW가 없을 때 과거 상장목록 API가 빈 목록을 반환함을 확인했습니다. 계정이 연결되더라도 실패 종목이 하나라도 있으면 생성기는 최종 파일을 덮어쓰지 않고 `.cache/krx-market/failures.json`을 남깁니다. KRX 생성물은 이용계약과 재배포 권한을 확인하기 전 공개 GitHub에 커밋하지 않습니다.

## 상용 데이터 전환 우선순위

1. 한국 주가·지수: [KRX Data Marketplace](https://data.krx.co.kr/contents/MDC/MAIN/main/index.cmd)의 개별종목 시세·월/연도 시세와 데이터 상품을 기준 원장으로 사용합니다.
2. 미국 주가·지수: [Nasdaq Global Data Products](https://www.nasdaqtrader.com/Trader.aspx?id=mddataproducts) 또는 승인된 재분배 사업자와 계약합니다. Nasdaq의 과거 Level 1/틱 데이터는 별도 상품입니다.
3. 일본 주가·지수: [JPX Historical Data](https://www.jpx.co.jp/english/markets/paid-info-equities/historical/) 또는 J-Quants 계열 상품을 사용합니다. JPX는 종목 OHLC, 지수, 통계 데이터를 상품별로 제공합니다.
4. 미국 재무·공시: 인증키 없이 제공되는 [SEC EDGAR Data APIs](https://www.sec.gov/search-filings/edgar-application-programming-interfaces)를 서버 수집 파이프라인에 연결합니다.
5. 한국 재무·공시: [금융감독원 OpenDART](https://opendart.fss.or.kr/guide/main.do)의 기업개황, 재무제표, 주요사항보고서를 사용합니다.
6. 거시지표·당시 공개 정보: [FRED/ALFRED API](https://fred.stlouisfed.org/docs/api/fred/overview.html)를 사용합니다. 특히 ALFRED 빈티지는 현재 수정된 수치가 아니라 당시 이용 가능했던 수치를 재현하는 데 유용합니다.

## 실사 모드 원칙

- 미래정보 누출 방지: 각 턴에는 해당 시점까지 공개된 공시와 이벤트만 노출합니다.
- 생존편향 방지: 상장폐지·합병·사명변경 종목도 당시 투자 가능 집합에 포함합니다.
- 기업행동 반영: 액면분할, 배당, 유상증자, 합병, 분사에 대해 adjusted/raw 시계열을 함께 보관합니다.
- 통화 분리: 최종 데이터 모델에서는 KRW, USD, JPY 원화 시계열과 당시 환율을 별도 원장으로 저장합니다.
- 출처 추적: 모든 관측값에 공급자, 원본 식별자, 수집 시각, 라이선스, 수정 여부를 기록합니다.
- 게임화 구분: 실제 시장가격·공시와 게임 밸런싱용 인수 가격·효과를 UI에서 명확히 구분합니다.

## 2000년 임금과 초반 일거리 기준

- [최저임금위원회 연도별 최저임금 결정현황](https://www.minimumwage.go.kr/minWage/policy/decisionMain.do): 1999-09-01~2000-08-31 시간급 1,600원, 8시간 일급 12,800원. 2000-09-01~2001-08-31 시간급 1,865원, 8시간 일급 14,920원.
- 문방구 재고 정리 30분 기본수당 800원은 2000년 상반기 시간급을 단순 시간비례한 값입니다. 정확도 보너스는 게임용 수치입니다.
- 설거지 용돈 300~800원과 가족 벼룩장터 판매 몫 600~1,600원은 공식 평균가격이 아니라 게임 밸런스용 가족 합의 금액입니다.
- [국가법령정보센터 근로기준법 최저 연령 조항](https://www.law.go.kr/LSW/lsSideInfoP.do?docCls=jo&joBrNo=00&joNo=0064&lsiSeq=265959&urlMode=lsScJoRltInfoR)과 [고용노동부 청소년 고용 FAQ](https://www.moel.go.kr/faq/faqView.do?seqRepeat=150)를 서사 안전 기준으로 참고합니다. 만 10세 구간은 정식 고용으로 표현하지 않습니다.

## 실제 경영진 데이터

게임 날짜별 회장·CEO·사장 직책은 회사 공식 연차보고서와 보도자료를 우선 사용합니다. 현재 1차 팩은 삼성전자, SK텔레콤, 포항제철, 현대자동차, Apple, Microsoft, Cisco, Toyota, Sony, SoftBank의 2000년 시작 경영진 12명과 Microsoft의 2000-01-13 CEO 이양을 포함합니다.

재임 기간과 원문 링크는 EXECUTIVES.md 및 flutter_app/lib/game/historical_executives.dart에 함께 기록합니다. 화면에는 실제 인물·직책과 게임용 AI 캐릭터 초상·창작 대사를 구분합니다. 미래 인사 정보는 취임일 이전에 노출하지 않습니다.

2000년 이후 경영진 교체는 해당 연도 콘텐츠를 구현하기 전에 공식 자료로 검증하고 기간 레코드와 새 초상을 함께 추가합니다.
## 다음 데이터 작업

- 거래소별 전체 종목 마스터와 상장·상장폐지 기간 수집
- 일별 가격의 결측·휴장·기업행동 검증 자동화
- 환율, 기준금리, CPI, GDP, 실업률 등 거시 시계열 추가
- 실제 M&A 공시와 거래가, 인수 방식, 완료일 정규화
- 데이터 검증 리포트: 결측, 중복, 급변, 기업행동 전후 단절 검사

## 시장 운영시간 근거 (2026-07-21 확인)

- KRX 정규시장: 09:00~15:20 접속매매, 15:20~15:30 종가 단일가(장마감 동시호가), 15:30 종료. https://global.krx.co.kr/contents/GLB/06/0606/0606010101/GLB0606010101T2.jsp
- KRX 시간외: 15:40~16:00 종가매매, 16:00~18:00 단일가매매. https://global.krx.co.kr/contents/GLB/06/0602/0602020204/GLB0602020204T1.jsp
- 넥스트레이드 현재 운영시간 참고: 프리마켓 08:00~08:50, 메인마켓 09:00:30~15:20, 애프터마켓 체결 15:40~20:00. https://www.nextrade.co.kr/menu/transactionSys.do
- 구현 주의: NXT는 2000년 역사 데이터가 아니다. 게임에서는 현대적인 플레이 리듬을 위한 `NXT형 확장장`으로만 사용한다.
- `한국경제신문` 게임 특별판의 등락 집계는 `flutter_app/assets/market/market-history.json`에서 현재 게임 날짜와 정확히 일치하는 국내 종가만 사용한다.
