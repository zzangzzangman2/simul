# Flutter 주 구현

부자되기 시뮬레이션의 Android·Web 기준 구현입니다.

## 실행

```bash
flutter pub get
flutter run -d chrome
```

## 검증

```bash
flutter analyze
flutter test
flutter build web --release --base-href /play/
```

## 핵심 구조

- `lib/main.dart`: 앱 상태, 저장 콜백, 전날 조간신문과 다음날 08:00 흐름
- `lib/game/game_state.dart`: 저장 스키마 v14
- `lib/game/game_engine.dart`: 거래, 경제, 숨은 시나리오, 보고서, 기업행동
- `lib/game/fictional_market.dart`: 고정 30개 회사, 가격, 수천 사건, IPO·분사·유증·상폐
- `lib/game/market_data.dart`: 가상시장 자산·기업행동 모델
- `lib/game/market_news.dart`: 전날 공개 사실만 사용하는 신문 데이터
- `lib/stock_market_screen.dart`: 가상 종목, 조사보고서, 장중 속보, 주문·차트

## 시장 규칙

- 거래 대상은 모두 가상기업이다.
- 새 게임마다 월드시드가 달라져 미래가 바뀐다.
- 출발 30개 기업의 이름·업종·제품은 고정한다.
- Gemini는 전날 기사 문장만 생성한다.
- 오늘의 시나리오·가격·기업행동은 엔진이 결정한다.
- 보고서는 방향과 결과를 숨긴 징후만 제공한다.
- 장중 사건은 저장된 공개 시각에 속보로 나타난다.

## 레이아웃

기준은 390×844px, 최소 폭은 360px입니다. 데스크톱에서도 최대 430px의 같은 세로 프레임을 사용합니다.

전체 제품 규칙은 저장소 루트의 `AGENTS.md`, `PROJECT_GUIDE.md`, `HANDOFF.md`를 확인하세요.
