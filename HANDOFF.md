# 초딩부터 건물주 인수인계

마지막 갱신: 2026-07-24

## 현재 상태

주 구현은 `flutter_app/`의 Flutter 앱이다. Android와 Web을 지원하며 웹 루트는 `/play/index.html`로 이동한다. 제품 기준은 390×844 모바일 세로 화면이고, 360px 최소 폭에서도 가로 스크롤이 없어야 한다.

신규 게임은 1999년 마지막 밤의 가족 대화와 새천년 청소년 투자학교를 거쳐 2000-01-02 08:00에 시작한다. 초기 증권 예수금은 외할아버지 세뱃돈 10,000원이고, 아빠가 선납한 학원비 1,000,000원은 투자금과 분리된 가족 채무다.

거래 대상은 게임 전용 가상기업뿐이다. 고정 출발 기업 50개에서 시작해 월드시드에 따라 사건·가격·IPO·분사·유상증자·상장폐지가 갈라지며 2026-12-31에 최종 결산한다.

## 현재 구현 범위

- 최대 5개 저장 슬롯, 자동·수동 저장, 정상 백업과 손상 원문 보존
- 작은방·거실·부엌 아파트 허브와 홈 PC, 장부, 조직, 안건, 일거리 연결
- 가족 대화, 투자학교, 별도 연습 계좌를 쓰는 첫 주식시장 강제 실습
- 2000~2026 가상시장, 50개 고정 기업, 기준 시드 212개 종목과 사건 단계 38,970개
- 2015-06-14까지 ±15%, 이후 ±30% 가격제한폭
- 5단계 매도·5단계 매수 호가, 거래대금 연동 벽, 가격·시간 우선 부분체결과 미체결 주문
- 현실 1초=게임 1분, 정지·1배·3배·10배, 체결·속보·장 경계·급등락 자동 정지
- 서울·경기 18개 기준 부동산, 54개 개별 매물, 14개 권역과 기준 시드 사건 2,215개
- 취득비용, 담보대출, 연체·강제매각, 공실·월세·전세·보증금 반환
- 실제 조작형 일거리 `잼민 라이더`
- Flutter Web 릴리스 산출물의 `public/play/` 동기화

## 시장 불변 조건

- 같은 월드시드와 같은 선택은 같은 결과를 만든다.
- 주말·휴장일에는 직전 종가를 유지한다.
- 08:00~08:59는 이전 종가 고정, 09:00 개장, 14:50~15:00 종가 동시호가, 15:00 마감이다.
- 사건 영향은 `revealMinute` 전에 가격에 선반영하지 않는다.
- 신문은 전날 공개 사실만 쓰며 오늘의 숨은 시나리오·영향률·미래 가격을 누설하지 않는다.
- Gemini는 기사 문장만 만들고 가격·사건·주문 결과를 결정하지 않는다.
- 지정가 매수는 지정가 이하의 매도호가, 지정가 매도는 지정가 이상의 매수호가만 소모한다.
- 같은 가격의 플레이어 주문은 외부 벽 뒤에서 가격·시간 우선으로 대기한다.
- 체결과 15:00 주문 만료를 서로 다른 결과로 기록한다.
- 시장 시간·거래·이체·보고서·노트·닫기 저장은 직렬화한다.

## 저장과 호환

현재 상태 스키마는 `v15`다.

- 1번 슬롯은 과거 단일 저장 키와 호환한다.
- 기존 저장의 날짜·현금·조직·원장을 보존한다.
- 과거 실기업 포지션은 기록 원가를 현금으로 한 번 환급하고 제거한다.
- 과거 제어 회사는 한빛통신으로 전환한다.
- 기존 저장은 첫 시장 실습 완료 상태로 보며 신규 게임만 실습을 강제한다.
- 기존 부동산은 신규 임대 필드가 없으면 `기존 자동운영`으로 복원한다.
- 마이그레이션은 여러 번 실행해도 결과가 같아야 한다.

## 핵심 파일

| 파일 | 역할 |
| --- | --- |
| `flutter_app/lib/main.dart` | 앱 상태, 저장 연결, 하루 전환과 신문 |
| `flutter_app/lib/game/game_state.dart` | v15 저장 모델 |
| `flutter_app/lib/game/game_engine.dart` | 날짜·거래·원장·부동산·마이그레이션 |
| `flutter_app/lib/game/fictional_market.dart` | 50개 기업과 2000~2026 월드 생성 |
| `flutter_app/lib/game/order_book.dart` | 호가벽과 지정가 부분체결 |
| `flutter_app/lib/game/market_tick.dart` | 장중 1분 경로와 캔들 |
| `flutter_app/lib/game/market_news.dart` | 전날 사실 기반 신문 |
| `flutter_app/lib/stock_market_screen.dart` | 종목·호가·주문·차트·시장 실습 UI |
| `flutter_app/lib/game/real_estate_market.dart` | 기준 부동산과 취득비용 |
| `flutter_app/lib/game/real_estate_world.dart` | 개별 매물·권역·사건 |
| `flutter_app/lib/game/real_estate_financing.dart` | LTV·원리금·연체·강제매각 |
| `flutter_app/lib/game/real_estate_rental.dart` | 공실·월세·전세·세입자 사건 |
| `flutter_app/lib/rider_mini_game.dart` | 잼민 라이더 조작형 미니게임 |
| `flutter_app/lib/game/game_persistence.dart` | 5슬롯 저장과 복구 |
| `scripts/build-flutter-web.mjs` | Flutter Web 릴리스 원자적 동기화 |

## 문서 기준

- 제품·구조·검증: `PROJECT_GUIDE.md`
- 채택된 설계 결정: `DECISIONS.md`
- 현재 완료 범위: `WORK_LOG.md`
- 미구현 항목: `GAMEPLAY_GAPS.md`
- 밸런스 기준: `BALANCE_NOTES.md`
- 시장 자료와 라이선스: `DATA_SOURCES.md`
- 사건 작성 규칙: `CONTENT_GUIDE.md`
- 아트 제작 규칙: `ART_STYLE_GUIDE.md`

중복된 작업 이력이나 폐기된 수치는 다시 추가하지 않는다. 남은 구현 범위는 `GAMEPLAY_GAPS.md` 한 곳에서만 관리한다.

## 검증

```powershell
Push-Location flutter_app
flutter pub get
flutter analyze
Get-ChildItem test\*_test.dart | ForEach-Object { flutter test $_.FullName }
Pop-Location
npm test
npm run lint
npm run build:release
```

27년 월드 생성은 메모리를 많이 사용하므로 Flutter 테스트는 파일별로 순차 실행한다. 최종 통과 수는 `WORK_LOG.md`의 마지막 검증을 기준으로 한다.

실기기 확인은 개발 서버를 `0.0.0.0:8000`에 열고 같은 Wi-Fi의 휴대폰에서 `http://<PC 내부 IP>:8000`으로 접속한다. 다음 수동 확인은 갤럭시 플립에서 잼민 라이더의 장애물 간격·속도·체크포인트 손맛을 조정하는 것이다.
