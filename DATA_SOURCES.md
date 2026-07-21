# 데이터 출처와 실사 기준

## 현재 MVP 스냅샷

`app/data/market-history.json`은 2026-07-20에 Yahoo Finance chart endpoint에서 받은 일별 adjusted close를 사용합니다. 1999년 12월 응답이 있는 종목은 마지막 가용 거래일, 응답이 없는 종목은 2000년 1월 첫 가용 거래일을 100으로 정규화했기 때문에 숫자는 당시 실제 호가가 아니라 **분할·배당을 반영한 상대 수익률 지수**입니다.

| 시장 | 현재 종목 |
| --- | --- |
| KRX | 삼성전자, SK텔레콤, POSCO홀딩스 |
| NASDAQ | Apple, Microsoft, Cisco |
| TSE | Toyota, Sony, SoftBank |

게임은 2000-01-01부터 2010-12-31까지 하루 단위로 진행합니다. 거래일에는 해당 날짜의 실제 수정주가 지수를 사용하고, 주말·휴장일에는 미래값을 보간하지 않고 직전 거래일 값을 유지합니다. 시작일 이전 응답이 없는 KRX 종목·Sony·SoftBank는 2000-01-04 첫 관측 전까지 거래할 수 없습니다.

이 스냅샷은 프로토타입 검증용입니다. Yahoo 응답은 편리하지만 거래소 공식 재배포 라이선스를 대신하지 않습니다. 공개·상용 서비스 전에는 아래 공식 또는 계약형 데이터로 교체하고, 화면 표시와 원본 데이터 저장에 대한 재배포 권리를 확인해야 합니다.

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
