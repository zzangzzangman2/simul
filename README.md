# 부자되기 시뮬레이션

1999년 마지막 밤, 열 살 주인공이 외할아버지에게 받은 세뱃돈 10,000원을 어머니 명의의 교육용 증권계좌에 넣고 투자연구소를 시작하는 모바일 세로형 생활·투자 시뮬레이션입니다.

거래 대상은 모두 게임 전용 가상기업입니다. 출발 기업 30개의 이름과 업종은 고정되지만 새 게임마다 월드시드가 달라져 가격, 사건의 시기와 성패, 신규상장, 분사, 유상증자와 상장폐지의 미래가 바뀝니다.

<p align="center">
  <img src="./public/og-apartment-v2.png" alt="2000년 세로형 3공간 아파트 허브" width="760" />
</p>

## 핵심 플레이 루프

1. 작은방·거실·부엌의 실제 물건을 눌러 시장, 장부, 안건, 조직과 일거리를 연다.
2. 작은 일로 종잣돈을 벌고 가족 신뢰와 주문 권한을 얻는다.
3. 한빛통신을 포함한 30개 가상기업을 조사하고 거래한다.
4. 1시간을 보내며 정해진 시각의 장중 속보를 확인한다.
5. 하루를 보내면 20:00 종가를 저장하고 다음 날 08:00에 전날 조간신문을 읽는다.
6. 필요하면 오늘의 유료 조사보고서에서 결과를 숨긴 현장 징후를 산다.
7. 시간이 흐르며 신규상장·분사·유상증자·상장폐지로 시장 자체가 달라진다.

## 시장 정보 규칙

- Gemini는 전날 공개 사실만 기사로 정리한다.
- 오늘의 숨은 시나리오와 가격은 게임 엔진이 먼저 고정한다.
- 신문은 오늘 사건을 미리 알려주지 않는다.
- 보고서는 방향·성패·영향률·미래 종가 없이 징후만 제공한다.
- 장중 사건은 `revealMinute`를 통과할 때 속보로 공개된다.
- 같은 시드와 같은 선택은 같은 세계를 만든다.

## 문서 읽는 순서

| 문서 | 역할 |
| --- | --- |
| [AGENTS.md](./AGENTS.md) | 절대 작업 규칙 |
| [PROJECT_GUIDE.md](./PROJECT_GUIDE.md) | 전체 구조와 검증 절차 |
| [HANDOFF.md](./HANDOFF.md) | 현재 구현과 다음 작업 |
| [CONTENT_GUIDE.md](./CONTENT_GUIDE.md) | 가상기업 이벤트·업종 문법 |
| [DATA_SOURCES.md](./DATA_SOURCES.md) | 26년 국내시장 레퍼런스와 저작권 원칙 |
| [GAMEPLAY_GAPS.md](./GAMEPLAY_GAPS.md) | 구현 완료 범위와 남은 갭 |
| [DECISIONS.md](./DECISIONS.md) | 주요 결정 기록 |
| [story.md](./story.md) | 가족 서사와 장기 성장 기준 |

## 실행

주 구현은 `flutter_app/`이며 Android와 Web을 대상으로 합니다.

```bash
cd flutter_app
flutter pub get
flutter run -d chrome
```

검증:

```bash
flutter analyze
flutter test
```

배포용 Web 번들:

```bash
npm run build:flutter-web
npm test
npm run build:release
```

기본 웹 경로 `/`는 `/play/index.html`로 이동합니다. 루트 Next/Vinext 앱은 정적 Flutter 호스트와 뉴스 API를 제공합니다.

## 주요 구현 파일

- `flutter_app/lib/game/fictional_market.dart`: 고정 30개, 가격, 수천 사건, IPO·분사·유증·상폐
- `flutter_app/lib/game/game_engine.dart`: 날짜, 저장 v14, 보고서, 기업행동, 마이그레이션
- `flutter_app/lib/game/market_news.dart`: 전날 사실만 쓰는 신문 데이터
- `flutter_app/lib/stock_market_screen.dart`: 종목, 거래, 보고서, 속보, 차트
- `flutter_app/lib/main.dart`: 앱 상태와 20:00→08:00 신문 흐름

## 모바일 기준

기준 화면은 390×844px이며 최소 360px에서 가로 스크롤이 없어야 합니다. PC에서도 최대 430px의 같은 세로형 앱 프레임을 가운데 표시합니다.
