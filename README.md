# 초딩부터 건물주

1999년 마지막 밤, TV 드라마 속 투자자를 보고 주식에 관심을 가진 열 살 주인공이 가족의 권유로 투자학교 입문반부터 배우고 주식·부동산·동네 사업을 함께 키우는 모바일 세로형 생활·투자 시뮬레이션입니다.

아빠가 먼저 낸 학원비 1,000,000원은 갚아야 할 가족 채무, 외할아버지 세뱃돈 10,000원은 어머니 명의 교육용 증권계좌의 첫 투자금으로 분리합니다.

거래 대상은 모두 게임 전용 가상기업입니다. 2000년부터 2026년 최종 결산까지 출발 기업 50개와 생성 기업이 움직이며, 새 게임의 월드시드에 따라 가격·사건·신규상장·분사·유상증자·상장폐지가 달라집니다.

새 캠페인은 `처음하기`를 누른 직후 프롤로그보다 먼저 월드시드를 확정하고
2000~2026 주식시장 연표를 만든 뒤 그 안의 실물경제형 공통 사건을 서울·경기
부동산 세계와 전국 상권에 연결합니다. 첫 로딩은 환경에 따라 약 1분 걸릴 수
있으며 화면에 현재 생성 단계와 퍼센트를 표시합니다. 예열이 끝난 뒤 프롤로그를
시작하고, 회사 이름을 확정할 때 같은 시드의 첫 저장을
만듭니다. 전체 연표를 예열해도 플레이 중에는 현재 날짜까지 공개된 정보만 보입니다.

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
7. 생활·조직·부동산과 전국 32개 상권의 18업종 동네 사업을 함께 운영하며 2026년 최종 결산까지 성장한다.

작은방 CRT의 홈 PC에는 주식시장·부동산·`동네상권넷`·별빛 상점이 있다.
동네상권넷에서는 PC방·노래방을 포함한 18업종, 6개 미시 입지 유형과 전국 주요
도시의 실제 상권 32곳을 조합해 점포를 인수하거나 창업한다. 2000~2026에 뜨고
쇠퇴하고 재생하는 상권은 `상권판세`를 포함한 5탭에서 현재 날짜까지 확인하며,
가격·품질·인력·홍보·영업시간·설비관리 6축을 조정한다. 수익은 보장되지 않고
월 손익, 선택형 사건, 미지급금과 폐업이 회사 통장에 반영된다.

## 한 세계의 경제 사건

주식·부동산·동네 사업은 거래 방식과 장부는 서로 다르지만 같은 날짜의 경제를
공유한다. 기준 원천은 주식시장에 이미 가격 반영된 시드형 역사 촉매와 타임라인
코퍼스의 `stage 0` 거시 충격이다. `world_economy.dart`는 그 객체의 같은 ID·발생일·
제목·이미 시드화된 충격 강도를 다시 뽑지 않고, 상권의 수요·임대료·경쟁·임금·
공실·위험과 부동산의 가격·임대·공실·수선·유동성에 맞게 투영한다.

급격한 호가 유동성 사고, 공매도 규칙 변경, 레버리지 청산처럼 주식시장 구조에만
해당하는 사건은 공유하지 않는다. 주식 가격과 장중 경로에는 새 거시 배율을
덧붙이지 않으므로 기존 숫자를 다시 계산하거나 같은 충격을 두 번 적용하지 않는다.
장중에 공개된 주식 사건은 날짜 단위인 부동산·상권 화면에서 다음 달력일부터
보이며, 숫자 효과가 활성화된 사건은 최근 목록 한도를 넘어도 원인을 확인할 수 있다.

저장 스키마는 `GameState` v20을 유지한다. 신규 점포는 사업 생성기 v3와 상권
생성기 v2, 신규 부동산은 생성기 v4를 사용한다. 기존 사업 v1·v2와 부동산
v1·v2·v3 보유분은 저장된 생성기를 그대로 사용해 과거 가격과 손익을 바꾸지
않는다. 부동산 14개 중심 지역은 상권 32곳 중 대응 상권 하나로 연결한다.

## 시장 정보 원칙

- 엔진이 오늘의 시나리오·가격·기업행동을 먼저 결정한다.
- 사건은 저장된 공개시각 전에는 가격과 기사에 나타나지 않는다.
- 로컬 결정론적 조합기가 전날 공개 사실만으로 172만 8천 가지 이상의 기사 문장을 만든다.
- 보고서는 방향·성패·영향률·미래 종가 없이 징후만 제공한다.
- 화면 호가 잔량과 실제 지정가 부분체결이 같은 유동성 계산을 사용한다.
- 같은 시드와 같은 선택은 같은 세계를 만든다.
- 공통 경제 사건은 자산별로 새 ID나 새 강도를 만들지 않으며, 공개 경계 뒤에만
  주식·부동산·상권에서 같은 원인을 확인할 수 있다.

## 문서

| 문서 | 역할 |
| --- | --- |
| [AGENTS.md](./AGENTS.md) | 필수 작업 규칙 |
| [PROJECT_GUIDE.md](./PROJECT_GUIDE.md) | 제품 구조·실행·검증 |
| [HANDOFF.md](./HANDOFF.md) | 새 채팅이 먼저 읽을 현재 상태·작업 트리·다음 행동 |
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

기본 웹 경로 `/`는 `/play/index.html`로 이동하며 루트 Vinext 앱은 Flutter 정적 호스트만 제공합니다. 신문은 네트워크 없이 앱 내부에서 생성됩니다.

주식만 바로 검증할 때는 /play/stock-test.html을 사용합니다. 100만 원 테스트 계좌로 09:00 시장부터 열리며 실제 저장 슬롯과 완전히 분리됩니다.

## 주요 구현

- `flutter_app/lib/game/fictional_market.dart`, `flutter_app/lib/game/market_era_events.dart`: 고정 50개, 2026까지 가격·사건·기업 생애주기와 공통 경제 원천 내보내기
- `flutter_app/lib/game/world_economy.dart`: 주식의 공개 거시 사건을 부동산·상권 효과로 한 번만 투영하고 14개 부동산 지역을 상권에 매핑
- `flutter_app/lib/game/order_book.dart`: 방향별 대기잔량·거래대금·분당 소화량·양수 실행 호가 기반 가격 전이와 저유동 빈 가격
- `flutter_app/lib/game/news_combinator.dart`: 외부 연결 없는 결정론적 신문 문장 조합기
- `flutter_app/lib/game/game_engine.dart`: 저장 v20, 거래·경제·부동산·동네 사업 일일 훅·스타 상점·마이그레이션
- `flutter_app/lib/game/star_shop.dart`: 미션 스타 상품과 다음 거래일 힌트
- `flutter_app/lib/game/real_estate_world.dart`: 생성기 v4 개별 매물·지역 사건·공통 경제 투영·공간 영향과 v1~v3 레거시 보존
- `flutter_app/lib/game/world_bootstrapper.dart`: 시작·이어하기 세계 예열과 진행률
- `flutter_app/lib/game/real_estate_rental.dart`: 공실·월세·전세·세입자 사건
- `flutter_app/lib/game/business_state.dart`: 점포·6축 정책·월 손익·사건의 저장 상태
- `flutter_app/lib/game/business_districts.dart`: 32개 실제 상권의 2000~2026 국면·지표·사건·순위
- `flutter_app/lib/game/business_simulation.dart`: 18업종·6개 미시 입지·32개 실제 상권의 매물·손익·투자·결정론적 사건
- `flutter_app/lib/game/business_engine.dart`: 회사 통장 운영·부동산 연결·미지급·폐업
- `flutter_app/lib/business_management_screen.dart`: 동네상권넷 5탭의 인수·점포·사건·손익·상권판세 UI
- `flutter_app/test/world_economy_test.dart`, `shared_economy_stock_export_test.dart`: 공통 사건 동일성·날짜 경계·지역 매핑·주식 원천 비변경 회귀
- `flutter_app/test/business_districts_test.dart`, `business_simulation_test.dart`, `business_engine_test.dart`, `business_ui_test.dart`: 상권·사업 계산·저장·엔진·UI 회귀
- `flutter_app/lib/rider_mini_game.dart`: 픽셀 아트 3차선 회피·체크포인트·콤보·완주 점수
- `flutter_app/lib/stock_market_screen.dart`: 호가·주문·차트·배속·보고서·속보
- `flutter_app/lib/main.dart`: 앱 상태와 저장, 20:00→08:00 신문 흐름

기준 화면은 390×844px이며 최소 360px에서 가로 스크롤이 없어야 합니다.
데스크톱은 390×844 앱 프레임을 가운데 고정하고, 창이 작을 때만 프레임 전체를
비례 축소합니다.
