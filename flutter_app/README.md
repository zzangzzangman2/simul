# Flutter 주 구현

10대부터 건물주의 Android·Web 기준 구현입니다.

## 실행

```powershell
flutter pub get
flutter run -d chrome
```

릴리스 웹에서 주식만 바로 검증할 때는 `/play/stock-test.html`을 사용합니다.
09:00·100만 원 테스트 계좌로 시작하며 실제 5슬롯 저장과 격리되고 새로고침하면
테스트 상태만 초기화됩니다.

개별 화면은 `/play/index.html?newspaperPreview=1`,
`/play/index.html?horseRacePreview=1`, `/play/index.html?casinoTest=1`로 바로 확인합니다.
신문배달·경마 미리보기는 화면 검수용이고,
카지노 테스트는 2000-01-03 15:00·격리된 1,000,000원 국가계좌 메모리 상태를 사용해
본편 5슬롯을 읽거나 쓰지 않습니다. 시작 칩은 0원이므로 이안의 안내대로 칩을 교환해야
테이블에 들어갑니다.

## 검증

```powershell
flutter analyze
Get-ChildItem test\*_test.dart | ForEach-Object { flutter test $_.FullName }
flutter build web --release --base-href /play/
```

27년 월드 생성 테스트는 메모리 점유가 크므로 테스트 파일을 하나씩 실행합니다.
특정 테스트 개수, 번들 크기와 SHA-256은 빌드마다 달라지므로 영구 기준으로
고정하지 않습니다. 현재 구현 상태는 루트 `HANDOFF.md`, 미완성 범위는
`GAMEPLAY_GAPS.md`에 기록하며, `flutter analyze`, 파일별 Flutter 테스트, `npm test`, `npm run lint`,
`npm run build:release`, `git diff --check`가 모두 통과한 상태만 푸시합니다.

## 핵심 구조

- `lib/main.dart`: 앱 상태·저장·신문·화면 연결
- `lib/visual_novel_onboarding.dart`: 편집본 장면·배경·화자·포즈와 동적 종료점, 4구간 시작 선택·막간 자동저장을 적용하는 리부트 프롤로그
- `lib/game/game_state.dart`: 저장 스키마 v27과 관계·데시멀톡·일일 투자·상장사 주주권·경영권·자회사 장부
- `lib/game/phone_messenger_state.dart`: 데시멀 동기 9명 연락처·MBTI 답장·읽음·하루 제한 저장
- `lib/game/phone_ai_service.dart`: 서버 Gemini 답장 호출과 안전한 로컬 조합기 폴백
- `lib/phone_messenger_screens.dart`: 데시멀톡 채팅 목록·읽지 않음·자유 입력·좌우 말풍선 UI
- `lib/game/cohort_investment_state.dart`: 데시멀 동기 9명 NPC 계좌·10인 일일 결과·대여·자동 상환 저장
- `lib/cohort_investment_screens.dart`: 15:00 `오늘의 투자 결과` 10행 표와 하루 1회 대여 UI
- `lib/game/player_progression.dart`: 의미 있는 행동 경험치·1~9단계 기술·행동 카운터 저장
- `lib/game/weekly_portfolio_review.dart`: 주간 회사 조사·손실 확인선·실제 체결 완료와 회전 후보
- `lib/game/progress_review.dart`: 월말·연말·10년 누적 거래·조사·관계·주말 회고
- `lib/game/monthly_unlock_chapter.dart`: 2~9월 8명 기능 해금·5단계 관계 톤·후속 톡
- `lib/game/relationship_state.dart`: 여학생 8명 프로필·호감도·단계·장면·최근 선택 저장
- `lib/relationship_screens.dart`: 관계 목록과 하루 종료 대화·데이트 UI
- `lib/game/game_engine.dart`: 거래·경제·기업행동·부동산·동네 사업·관계 일일 훅·마이그레이션
- `lib/game/business_state.dart`: 점포·6축 정책·월 손익·사건 포트폴리오
- `lib/game/business_districts.dart`: 32개 실제 상권의 2000~2026 국면·지표·사건·순위
- `lib/game/business_simulation.dart`: 18업종·6개 미시 입지·32개 실제 상권의 월 매물·손익·투자·사건 계산
- `lib/game/business_engine.dart`: 회사 통장 거래·월 정산·부동산 연결·미지급·폐업
- `lib/game/fictional_market.dart`, `lib/game/market_era_events.dart`: 50개 출발 기업, 2026년까지의 시드형 시장과 공통 경제 원천 내보내기
- `lib/game/world_economy.dart`: 주식의 공개 거시 사건을 사업·부동산 수치로 투영하고 14개 부동산 지역을 상권에 매핑
- `lib/game/market_data.dart`: 시장 데이터 모델·2개 LRU·백그라운드 생성
- `lib/game/order_book.dart`: 방향별 대기잔량·체결강도·분당 소화량·깊이 제한 가격 전이
- `lib/game/shareholder_governance.dart`, `lib/game/shareholder_governance_engine.dart`: 상장사
  주주권·주총·공개매수·CEO·자회사·기업재편 저장과 일일 처리
- `lib/game/listed_company_management.dart`: 업종별 이사회·CEO 집행·합병·합작·분할·자산매각
- `lib/shareholder_company_hub_screen.dart`, `lib/listed_governance_screen.dart`: 작업실 PC
  회사관리 허브와 종목별 경영 화면
- `lib/game/market_news.dart`: 공개된 전날 사실만 쓰는 신문 데이터
- `lib/game/real_estate_market.dart`: 부동산 기준 자산·가격·거래비용
- `lib/game/real_estate_world.dart`: 생성기 v4 개별 매물·지역 사건·공통 경제 투영·공간 영향과 v1~v3 보존
- `lib/game/real_estate_financing.dart`: 담보대출·상환·연체
- `lib/game/real_estate_rental.dart`: 공실·월세·전세·세입자 사건
- `lib/stock_market_screen.dart`: 호가·주문·차트·배속·보고서·속보
- `lib/business_management_screen.dart`: 동네상권넷 인수·점포·사건·월별 손익·상권판세 5탭 UI
- `lib/rider_mini_game.dart`: 새벽 신문배달 방향 플릭·투척 포물선·자전거 캔버스 애니메이션·성과 점수
- `lib/game/horse_racing.dart`, `lib/horse_racing_mini_game.dart`: 평일 데시멀 PC 국가망 경마의 8두 결정론 경주·하루 1회 전자 마권·20:00 종료·카지노 상호 배제·확정이익 20% 국가 수수료·실시간 중계
- `lib/game/casino_state.dart`, `lib/casino_screen.dart`, `lib/casino_table_animation.dart`:
  카지노 6게임·30분/10판·결정론 원장·블랙잭/크랩스 저장·현장 테이블 연출
- `test/world_economy_test.dart`, `test/shared_economy_stock_export_test.dart`: 공통 사건 동일성·공개일·지역 매핑·주식 원천 비변경 회귀
- `test/business_districts_test.dart`: 상권 카탈로그·국면·사건 비누설·순위·적합도·부동산 매핑·레거시 회귀
- `test/business_simulation_test.dart`: 카탈로그·손익·사건·JSON 결정론 회귀
- `test/business_engine_test.dart`: 인수·부동산 연결·정책·투자·월 정산·강제폐업 회귀
- `test/business_long_run_balance_test.dart`: 2000~2026 다중 시드·18업종·6입지·32상권·4정책 장기 분포 감사
- `test/business_ui_test.dart`: 390×844·360×800 앱 진입·5탭·상권판세·실제 인수·6축·투자·폐업 회귀
- `test/casino_engine_test.dart`, `test/casino_screen_test.dart`, `test/casino_ten_round_playtest.dart`:
  카지노 한도·수수료·저장·6게임 규칙·360px·게임별 10판 플레이
- `test/horse_racing_test.dart`, `test/horse_racing_mini_game_test.dart`: 경마 결정론·배당·원장·
  위조 방지·8두 중계·모바일 UI
- `test/shareholder_governance_test.dart`, `test/listed_company_management_test.dart`,
  `test/listed_governance_screen_test.dart`, `test/shareholder_company_hub_test.dart`: 지분 임계값·
  주총·공개매수·CEO·기업재편·PC 허브
- `test/order_book_inventory_conservation_test.dart`, `test/pending_order_queue_invariant_test.dart`,
  `test/stock_market_player_order_level_test.dart`: 발행주식 보존·외부 재고/예산·FIFO·1주 주문
- `test/player_progression_test.dart`, `test/weekly_portfolio_review_test.dart`,
  `test/one_year_simulation_test.dart`, `test/ten_year_simulation_test.dart`: 성장·주간 복기·연간/10년 회고
- `test/widget_test.dart`: 프롤로그, 대사 편집본 배경과 추가 장면을 포함한 위젯 회귀

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
- 저장은 v27이다. 신규 사업 v3는 상권 생성기 v2, 신규 부동산은 v4를
  사용하며 사업 v1·v2와 부동산 v1·v2·v3 저장분의 수치 경로는 바꾸지 않는다.

## 동네 사업 규칙

- 작업실 PC의 `동네상권넷`은 `인수·창업 / 내 점포 / 사건함 / 월별 손익 /
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
- 현재 저장은 v27·신규 점포는 사업 생성기 v3와 상권 생성기 v2다.
  사업 생성기 v1·v2는 저장된 수치 경로를 동결하며, `districtId`가 없는 v1은
  기존 `locationId`와 중립 상권 보정을 유지해 안전하게 복원한다.

## 시장 규칙

- 거래 대상은 모두 가상기업이다.
- 출발 기업 50개의 이름·업종·제품은 고정하고 미래는 월드시드로 바꾼다.
- 캠페인과 기업행동은 2026-12-31 최종 결산까지 이어진다.
- 사건은 공개시각 전에 가격·신문·보고서에 누설하지 않는다.
- 화면 호가 잔량과 실제 지정가 부분체결은 같은 계산을 사용한다.
- 일일 예상 거래대금 20억원 이상 종목은 중앙 최우선 ask/bid를 정확히 한 유효
  틱 차이로 유지하고, 바깥 호가와 구조 공백까지 생성형 가시 사다리의 모든
  유효 틱을 최소 10주로 잇는다. 20억원 미만만 내부·최우선 공백을 허용한다.
  최우선 ask가 전량 체결되면 기존 ask를 재충전하지 않고 같은 가격에 새 일반
  bid를 만들어 경계를 한 틱 전진시키며 bid 체결은 대칭적으로 처리한다.
  전진한 경계는 직전 체결 표시와 별도의 세션 상태로 승계해 다음 펄스·재생성에서
  과거 중앙가로 되감지 않는다. 20,000~50,000원 구간은 50원 단위이므로
  32,150원 다음 유효가격은 32,200원이다.
- 이전 저장·스냅샷이 `32,150 bid / 32,500 ask` 레거시 갭이어도 32,500원
  ask 전량 체결 즉시 `32,500 bid / 32,550 ask`로 정규화하고, 실제 새
  반대방향 체결 전에는 32,150원으로 되감지 않는다.
- 생성·승계·전량 체결 전이로 노출되는 모든 양수 호가는 최소 10주이며 수량
  1짜리 인공 호가·벽은 허용하지 않는다. 실제 KRX의 호가 공백과 1주 주문은
  가능하며, 중앙 한 틱 연속성과 10주 하한은 예상 거래대금 20억원 이상
  종목에 대해 시뮬레이션이 생성한 가시 큐에 적용하는 현실감 정책이다.
- 합성 큐의 실제 부분소모 뒤 1~9주만 남으면 잔여분을 즉시 취소한다. 취소분은
  `lastSyntheticTrade`, 체결 테이프·거래량·체결강도·분당 예산·가격별 원장
  watermark에 반영하지 않는다.
- 라이브 UI의 같은 분 carry는 플레이어 체결을 누적 ask/bid 원장 소모·공유
  용량과 함께 현재 스냅샷에 정규화한 결과를 다음 프레임에 사용한다. 최신
  플레이어 체결이 최우선 전량 소진을 명시할 때만 중앙 경계를 승격한다. 실제
  체결 전에는 직전 최우선 bid를 유지하고 결정론적 목표가격만으로 방향을
  뒤집지 않는다. 합성 체결의 잔량은 현재 표시된 같은 ask/bid 방향·절대가격
  큐를 기준으로 한다. 이전 carry의 더 작은 같은 방향 잔량은 같은 프레임 신규
  유입을 막는 상한으로만 쓰며, 더 큰 수량이나 반대 방향 depth로 줄어든 벽을
  되살리지 않는다.
- 현재가·최근 체결가는 직전 실제 체결가격이고 최우선 ask/bid는 남아 있는
  주문의 최저 매도·최고 매수다. 경계를 다시 만드는 것만으로 현재가를 바꾸지 않는다.
- 구조벽은 가격 경계 통과 또는 최초·회복 기준 잔량 90% 이상 실제 소진 시 붕괴하며, 이후에는 원래 벽이 아니라 일반 호가 수준까지만 회복한다.
- 호가 펄스는 게임분당 거래대금 기본 1·1·1·1·2·2·3·4·4회, 급변 5회,
  극단 7회다. 20~75억원 구간은 1회/분이고 75억원 미만은 체결강도 불균형만으로
  가속하지 않는다. 75억원 이상도 최근 3시장분에 고유 `(시장분, 미세구조 프레임)` 표본 최소 3개와 체결대금 합계 0.10억원 이상이 있어야 불균형 가속하며, 부족하면 기본 슬롯을 유지한다. 실제 벽 잔량과 standing depth 계수 `0.45`는 그대로 두고 각 슬롯의 누적 체결 용량을 비례 확대해 마지막 슬롯에서 같은 목표가에 도달한다. 가격·잔량 숫자는 즉시 반영하고 잔량 막대·대기 중 중앙 테두리는 144ms로 보간하며 활성 체결 테두리는 즉시 스냅한다.
- 현실 1초=게임 1분을 기본으로 정지·1분·3분·10분을 제공한다.
- 시장 저장은 직렬화하고 백그라운드 전환 시 현재 분을 저장한다.

- 한 슬롯의 집계 합성 체결은 표시 큐에서 한 번만 차감한다. 수량이 충분하면 합계가 정확히 같은 7~12개 테이프 체결로 나누며 약 65%는 1~5주이고 10주 배수 스냅은 하지 않는다. 체결강도·거래대금은 자식 수량을 합산하지만 가속 표본은 고유 `(시장분, 미세구조 프레임)`으로 세고, 보합 방향은 결정론적 쌍으로 장기 50:50이다.
- 정상 호가 이벤트 깊이는 최우선 46%, 2~3호가 32%, 4~10호가 22%로 선택한 뒤 평온 55%·급변 78% 게이트를 통과할 때만 바뀐다. 비선택 비구조·비벽·비회복 가시 큐도 낮은 결정론적 확률로 작은 주문 유입·취소·정정을 받아 장시간 얼어붙지 않는다. 비구조벽 깊이는 최우선이 얇은 험프를 사용하고 고정 5틱 미시 벽은 만들지 않는다. 전체·압축 호가 모두 전일종가 대비 등락률을 표시하며 숫자는 즉시, 잔량 막대·대기 중 중앙 테두리는 144ms로 갱신하고 활성 체결 테두리는 즉시 스냅한다. 20억원 이상 생성형 호가는 연속 양수, 20억원 미만은 결정론적 공백 정책이다.

## 레이아웃

기준은 390×844px, 최소 폭은 360px입니다. 실제 모바일 Web에서는 기기의 가용
뷰포트 너비·높이를 여백 없이 100% 채웁니다. 데스크톱에서만 정확한 390×844
세로 프레임을 가운데 표시하고 창이 작을 때만 프레임 전체를 비례 축소합니다.

전체 규칙은 저장소 루트의 `AGENTS.md`, `PROJECT_GUIDE.md`, `HANDOFF.md`를 따릅니다.
