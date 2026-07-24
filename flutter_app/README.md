# Flutter 주 구현

초딩부터 건물주의 Android·Web 기준 구현입니다.

## 실행

```powershell
flutter pub get
flutter run -d chrome
```

## 검증

```powershell
flutter analyze
Get-ChildItem test\*_test.dart | ForEach-Object { flutter test $_.FullName }
flutter build web --release --base-href /play/
```

27년 월드 생성 테스트는 메모리 점유가 크므로 테스트 파일을 하나씩 실행합니다.

## 핵심 구조

- `lib/main.dart`: 앱 상태·저장·신문·화면 연결
- `lib/game/game_state.dart`: 저장 스키마 v15
- `lib/game/game_engine.dart`: 거래·경제·기업행동·부동산·마이그레이션
- `lib/game/fictional_market.dart`: 50개 출발 기업과 2026년까지의 시드형 시장
- `lib/game/market_data.dart`: 시장 데이터 모델·2개 LRU·백그라운드 생성
- `lib/game/order_book.dart`: 호가벽·체결강도·분당 소화량·가격단계 체결
- `lib/game/market_news.dart`: 공개된 전날 사실만 쓰는 신문 데이터
- `lib/game/real_estate_market.dart`: 부동산 기준 자산·가격·거래비용
- `lib/game/real_estate_world.dart`: 개별 매물·지역 사건·공간 영향
- `lib/game/real_estate_financing.dart`: 담보대출·상환·연체
- `lib/game/real_estate_rental.dart`: 공실·월세·전세·세입자 사건
- `lib/stock_market_screen.dart`: 호가·주문·차트·배속·보고서·속보
- `lib/rider_mini_game.dart`: 배달 일거리 조작과 점수

## 시장 규칙

- 거래 대상은 모두 가상기업이다.
- 출발 기업 50개의 이름·업종·제품은 고정하고 미래는 월드시드로 바꾼다.
- 캠페인과 기업행동은 2026-12-31 최종 결산까지 이어진다.
- 사건은 공개시각 전에 가격·신문·보고서에 누설하지 않는다.
- 화면 호가 잔량과 실제 지정가 부분체결은 같은 계산을 사용한다.
- 현실 1초=게임 1분을 기본으로 정지·1배·3배·10배를 제공한다.
- 시장 저장은 직렬화하고 백그라운드 전환 시 현재 분을 저장한다.

## 레이아웃

기준은 390×844px, 최소 폭은 360px입니다. 데스크톱에서도 최대 430px의 같은 세로 프레임을 사용합니다.

전체 규칙은 저장소 루트의 `AGENTS.md`, `PROJECT_GUIDE.md`, `HANDOFF.md`를 따릅니다.
