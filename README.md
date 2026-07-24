# 초딩부터 건물주

1999년 마지막 밤, TV 드라마 속 투자자를 보고 주식에 관심을 가진 열 살 주인공이 가족의 권유로 투자학교 입문반부터 배우는 모바일 세로형 생활·투자 시뮬레이션입니다.

아빠가 먼저 낸 학원비 1,000,000원은 갚아야 할 가족 채무, 외할아버지 세뱃돈 10,000원은 어머니 명의 교육용 증권계좌의 첫 투자금으로 분리합니다.

거래 대상은 모두 게임 전용 가상기업입니다. 2000년부터 2026년 최종 결산까지 출발 기업 50개와 생성 기업이 움직이며, 새 게임의 월드시드에 따라 가격·사건·신규상장·분사·유상증자·상장폐지가 달라집니다.

<p align="center">
  <img src="./public/og-apartment-v2.png" alt="2000년 세로형 3공간 아파트 허브" width="760" />
</p>

## 핵심 플레이 루프

1. 작은방·거실·부엌의 물건을 눌러 시장, 장부, 안건, 조직과 일거리를 연다.
2. 보호자와 안전요원이 관리하는 축제 코스의 `잼민 라이더`를 완주해 선택형 보조 자금을 번다.
3. 투자학교 뒤 한서윤 선생님의 전신 안내로 주식 탭, 한빛통신, 차트·재무, 실제 호가와 지정가 주문을 연습한다.
4. 50개 출발 가상기업과 이후 상장·분사 기업을 조사하고 거래한다.
5. 현실 1초=게임 1분 또는 3배·10배로 시간을 진행하며 체결과 장중 속보를 확인한다.
6. 하루가 끝나면 20:00 상태를 저장하고 다음 날 08:00에 전날 조간신문을 읽는다.
7. 생활·조직·부동산을 함께 운영하며 2026년 최종 결산까지 성장한다.

## 시장 정보 원칙

- 엔진이 오늘의 시나리오·가격·기업행동을 먼저 결정한다.
- 사건은 저장된 공개시각 전에는 가격과 기사에 나타나지 않는다.
- Gemini는 전날 공개 사실만 기사 문장으로 정리한다.
- 보고서는 방향·성패·영향률·미래 종가 없이 징후만 제공한다.
- 화면 호가 잔량과 실제 지정가 부분체결이 같은 유동성 계산을 사용한다.
- 같은 시드와 같은 선택은 같은 세계를 만든다.

## 문서

| 문서 | 역할 |
| --- | --- |
| [AGENTS.md](./AGENTS.md) | 필수 작업 규칙 |
| [PROJECT_GUIDE.md](./PROJECT_GUIDE.md) | 제품 구조·실행·검증 |
| [HANDOFF.md](./HANDOFF.md) | 현재 구현과 다음 작업 |
| [WORK_LOG.md](./WORK_LOG.md) | 현재 완료 범위와 마지막 검증 |
| [GAMEPLAY_GAPS.md](./GAMEPLAY_GAPS.md) | 아직 남은 기능만 |
| [DECISIONS.md](./DECISIONS.md) | 현재 채택된 결정만 |
| [CONTENT_GUIDE.md](./CONTENT_GUIDE.md) | 가상기업 사건·업종 문법 |
| [DATA_SOURCES.md](./DATA_SOURCES.md) | 시장·부동산 자료와 저작권 |
| [ART_STYLE_GUIDE.md](./ART_STYLE_GUIDE.md) | 고정 그림체·캐릭터 슬롯 |
| [story.md](./story.md) | 가족 서사와 장기 성장 기준 |

## 실행과 검증

```powershell
Push-Location flutter_app
flutter pub get
flutter run -d chrome
Pop-Location
```

```powershell
Push-Location flutter_app
flutter analyze
Get-ChildItem test\*_test.dart | ForEach-Object { flutter test $_.FullName }
Pop-Location
npm test
npm run lint
npm run build:release
```

27년 월드 생성은 메모리 점유가 크므로 Flutter 테스트는 파일별로 실행합니다.

기본 웹 경로 `/`는 `/play/index.html`로 이동하며 루트 Vinext 앱은 Flutter 정적 호스트와 뉴스 API를 제공합니다.

## 주요 구현

- `flutter_app/lib/game/fictional_market.dart`: 고정 50개, 2026까지 가격·사건·기업 생애주기
- `flutter_app/lib/game/order_book.dart`: 호가벽·거래대금·분당 소화량·실제 체결 계획
- `flutter_app/lib/game/game_engine.dart`: 저장 v15, 거래·경제·부동산·마이그레이션
- `flutter_app/lib/game/real_estate_world.dart`: 개별 매물·지역 사건·공간 영향
- `flutter_app/lib/game/real_estate_rental.dart`: 공실·월세·전세·세입자 사건
- `flutter_app/lib/rider_mini_game.dart`: 3차선 회피·체크포인트·콤보·완주 점수
- `flutter_app/lib/stock_market_screen.dart`: 호가·주문·차트·배속·보고서·속보
- `flutter_app/lib/main.dart`: 앱 상태와 저장, 20:00→08:00 신문 흐름

기준 화면은 390×844px이며 최소 360px에서 가로 스크롤이 없어야 합니다.
