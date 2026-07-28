# Flutter 주 구현

초딩부터 건물주의 Android·Web 기준 구현입니다.

## 실행

```powershell
flutter pub get
flutter run -d chrome
```

릴리스 웹에서 주식만 바로 검증할 때는 `/play/stock-test.html`을 사용합니다.
09:00·100만 원 테스트 계좌로 시작하며 실제 5슬롯 저장과 격리되고 새로고침하면
테스트 상태만 초기화됩니다.

## 검증

```powershell
flutter analyze
Get-ChildItem test\*_test.dart | ForEach-Object { flutter test $_.FullName }
flutter build web --release --base-href /play/
```

27년 월드 생성 테스트는 메모리 점유가 크므로 테스트 파일을 하나씩 실행합니다.
2026-07-28 전체 통합 감사 뒤 최종 기준은 `flutter analyze` No issues,
공통 경제 집중 41/41, 부동산·금융·엔진 집중 116/116, 전체 `flutter test`
536/536 PASS입니다. 루트 `npm test` 8/8, `npm run lint`,
`npm run build:release`, `git diff --check`도 모두 통과했습니다. 세부 실행 범위는
`HANDOFF.md`를 기준으로 합니다.

## 핵심 구조

- `lib/main.dart`: 앱 상태·저장·신문·화면 연결
- `lib/game/game_state.dart`: 저장 스키마 v20와 사업 자산·미지급금 합산
- `lib/game/game_engine.dart`: 거래·경제·기업행동·부동산·동네 사업 일일 훅·마이그레이션
- `lib/game/business_state.dart`: 점포·6축 정책·월 손익·사건 포트폴리오
- `lib/game/business_districts.dart`: 32개 실제 상권의 2000~2026 국면·지표·사건·순위
- `lib/game/business_simulation.dart`: 18업종·6개 미시 입지·32개 실제 상권의 월 매물·손익·투자·사건 계산
- `lib/game/business_engine.dart`: 회사 통장 거래·월 정산·부동산 연결·미지급·폐업
- `lib/game/fictional_market.dart`, `lib/game/market_era_events.dart`: 50개 출발 기업, 2026년까지의 시드형 시장과 공통 경제 원천 내보내기
- `lib/game/world_economy.dart`: 주식의 공개 거시 사건을 사업·부동산 수치로 투영하고 14개 부동산 지역을 상권에 매핑
- `lib/game/market_data.dart`: 시장 데이터 모델·2개 LRU·백그라운드 생성
- `lib/game/order_book.dart`: 방향별 대기잔량·체결강도·분당 소화량·깊이 제한 가격 전이
- `lib/game/market_news.dart`: 공개된 전날 사실만 쓰는 신문 데이터
- `lib/game/real_estate_market.dart`: 부동산 기준 자산·가격·거래비용
- `lib/game/real_estate_world.dart`: 생성기 v4 개별 매물·지역 사건·공통 경제 투영·공간 영향과 v1~v3 보존
- `lib/game/real_estate_financing.dart`: 담보대출·상환·연체
- `lib/game/real_estate_rental.dart`: 공실·월세·전세·세입자 사건
- `lib/stock_market_screen.dart`: 호가·주문·차트·배속·보고서·속보
- `lib/business_management_screen.dart`: 동네상권넷 인수·점포·사건·월별 손익·상권판세 5탭 UI
- `lib/rider_mini_game.dart`: 픽셀 아트 배달 일거리 조작과 점수
- `test/world_economy_test.dart`, `test/shared_economy_stock_export_test.dart`: 공통 사건 동일성·공개일·지역 매핑·주식 원천 비변경 회귀
- `test/business_districts_test.dart`: 상권 카탈로그·국면·사건 비누설·순위·적합도·부동산 매핑·레거시 회귀
- `test/business_simulation_test.dart`: 카탈로그·손익·사건·JSON 결정론 회귀
- `test/business_engine_test.dart`: 인수·부동산 연결·정책·투자·월 정산·강제폐업 회귀
- `test/business_ui_test.dart`: 390×844·360×800 앱 진입·5탭·상권판세·실제 인수·6축·투자·폐업 회귀

## 공통 경제 규칙

- 주식의 기존 시드형 역사 촉매와 타임라인 코퍼스 `stage 0` 거시 충격이 원본이다.
  같은 ID·발생일·제목·이미 시드화된 `impactPct`를 사용하고 다시 해시하지 않는다.
- 급격한 호가 유동성 사고, 공매도 규칙 변경, 레버리지 청산 같은 순수 시장구조
  사건은 주식에만 남긴다.
- 주가·장중 경로에는 추가 거시 배율을 넣지 않는다. 기존 주식 가격에 이미
  반영된 원인을 사업과 부동산에 맞게 투영할 뿐이다.
- 장중 공개 사건은 날짜 단위 사업·부동산 화면에서 다음 달력일부터 보인다.
  활성 숫자 효과를 가진 사건은 최근 공개 목록 한도를 넘어도 계속 표시한다.
- 사업은 수요·임대료·경쟁·임금·공실·위험·활력, 부동산은 가격·임대료·공실·
  위험·수선비·유동성으로 같은 원인을 서로 다르게 해석한다.
- 부동산 14개 중심 지역은 중앙 매핑 하나를 통해 32개 상권 중 대응 상권과
  같은 지역 민감도를 쓴다.
- 부동산 v4는 기존 무작위 거시 수치 중 `interestRatePolicy`,
  `housingPolicy`, `tenantPolicy`만 공통 경제 투영으로 교체한다.
  지역 고유 `commercialCycle`, `demographicShift`와 교통·재개발·건물 사건은
  유지한다. 공통 유동성은 NPC 신규 매물은 각 주기의 `listedAt`, 플레이어 보유
  부동산은 `saleListedDay` 시점에 한 번 고정해 매물 체류기간과 매각 대기에
  적용한다.
- 저장은 v20 그대로다. 신규 사업 v3는 상권 생성기 v2, 신규 부동산은 v4를
  사용하며 사업 v1·v2와 부동산 v1·v2·v3 저장분의 수치 경로는 바꾸지 않는다.

## 동네 사업 규칙

- 작은방 홈 PC의 `동네상권넷`은 `인수·창업 / 내 점포 / 사건함 / 월별 손익 /
  상권판세` 5탭이다.
- PC방·노래방을 포함한 18업종에 `locationId` 6개 미시 입지 유형과
  `districtId` 32개 실제 상권을 조합한다.
- 실제 상권은 2000~2026에 7국면과 상권 연표 사건 49개로 움직인다. 수요·임대료·
  경쟁·임금·공실·위험·업종 적합도와 현재 순위를 날짜·월드시드로 계산하고,
  화면에는 현재 날짜까지 공개된 사건만 표시한다.
- 매물은 월 1일 상권 시세로 호가를 고정하고 같은 월드시드·연월에 재현한다.
  영업 손익과 사건은 정확한 게임 날짜의 상권 상태를 사용한다.
- 가격·품질·인력·홍보·영업시간·설비관리 여섯 축은 0~4단계이며 매출과
  원가·급여·공공요금·홍보·유지비·사건 위험을 함께 바꾼다.
- 회사 통장만 사용한다. 보유 공실 상가·오피스 빌딩은 한 직영점에 연결할 수
  있지만 매물과 부동산의 정확한 `districtId`가 같아야 한다. 직영 창업은
  부동산 지역으로 잠기며 연결 중 임대·매각·리모델링을 막는다.
- 임차 점포 임대료는 개점 당시 대비 현재의 시대 비용지수와 상권 임대료지수
  비율을 함께 반영한다. 직영 부동산은 사업 임대료만 0이고 부동산 운영비는 남는다.
- 첫 완전 영업월부터 다음 달 1일에 월 손익을 한 번 정산한다. 부족분은
  미지급금이며 3개월 연속 남으면 강제폐업과 잔존자산 상계로 이어진다.
- 사건 선택지·기한·결과 예정일은 저장하고, 같은 시드·날짜·선택은 같은 결과를
  낸다. 성공은 즉시 보장하지 않고 예정일에 성공·부분 성공·실패를 공개한다.
- 현재 저장은 v20·신규 점포는 사업 생성기 v3와 상권 생성기 v2다.
  사업 생성기 v1·v2는 저장된 수치 경로를 동결하며, `districtId`가 없는 v1은
  기존 `locationId`와 중립 상권 보정을 유지해 안전하게 복원한다.

## 시장 규칙

- 거래 대상은 모두 가상기업이다.
- 출발 기업 50개의 이름·업종·제품은 고정하고 미래는 월드시드로 바꾼다.
- 캠페인과 기업행동은 2026-12-31 최종 결산까지 이어진다.
- 사건은 공개시각 전에 가격·신문·보고서에 누설하지 않는다.
- 화면 호가 잔량과 실제 지정가 부분체결은 같은 계산을 사용한다.
- 현실 1초=게임 1분을 기본으로 정지·1배·3배·10배를 제공한다.
- 시장 저장은 직렬화하고 백그라운드 전환 시 현재 분을 저장한다.

## 레이아웃

기준은 390×844px, 최소 폭은 360px입니다. 데스크톱에서는 정확한 390×844
세로 프레임을 가운데 표시하고 창이 작을 때만 프레임 전체를 비례 축소합니다.

전체 규칙은 저장소 루트의 `AGENTS.md`, `PROJECT_GUIDE.md`, `HANDOFF.md`를 따릅니다.
