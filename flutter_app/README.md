# MILLENNIUM CAPITAL Flutter

밝고 캐주얼한 2D 모바일 투자회사 경영 게임의 주 구현입니다. 세로형 모바일 화면을 우선하며 Web에서도 실행할 수 있습니다.

## 게임 시작

- 1999년 마지막 밤부터 시작하는 비주얼 노벨 프롤로그
- 열 살 주인공과 아빠·엄마·누나·외할아버지의 가족 대화
- 초기자본 100만원, 창립 인원 1명의 투자회사
- 이름·시작 동기·가족 투자규칙 선택과 로컬 자동 저장

## 현재 구현된 콘텐츠

- 세로형 3공간 아파트 허브: 작은방 CRT·서류함, 거실 안건 편지·가족/조직, 부엌 유선전화·일거리
- `bg_bedroom_premium_2000.png`, `bg_living_room_premium_2000.png`, `bg_kitchen_premium_2000.png` 배경과 장소 전환 도크
- 배경에 실제로 그려진 오브젝트 중심과 터치 핫스폿을 일치시키는 48px 이상 조작 규칙
- 안건함과 가죽 장부형 고급 포트폴리오·현금원장을 허브와 분리한 전용 장면
- 독립된 `1시간 보내기`·`하루 보내기` 버튼과 미해결 안건 시 동시 잠금
- 모바일 키보드 위에서 닉네임·연구소 이름 입력과 완료 버튼을 유지하는 프롤로그 레이아웃
- 저장된 연구소 이름을 방·시장·사람들·서류함에 그대로 표시
- 설거지 순서, 문방구 상품 분류, 벼룩장터 거스름돈 계산 미니게임
- 당시 물가 기반 보상, 하루 3회 일거리 제한과 수입 원장
- 모바일 1열 종목 목록, 국내 종목 매수·매도와 포트폴리오
- 국내 22개 실제 종가 기본 팩과 별도 해외 참고 탭 6개, 날짜별 역사 소식 400여 건. 해외 주문은 실제 환율 원장 연결 전까지 잠금
- 실제 경영진 12명의 재임 기간과 카툰 상반신 카드
- 가족 조언자 카드 배치, 피로도·도움 기록과 향후 직원 채용 안내
- 실제 Apple을 사용한 Project Atlas 대체역사 경영권 시나리오
- Flutter v9 자동 저장과 Flutter v8·React 웹 v3 진행 보존 마이그레이션. 재무·일거리 진행 없는 0원 v8 저장만 초기자본 100만원을 한 번 받고 실제 진행 잔액은 유지
- 주식시장의 화면 뒤로가기·시스템 Back 모두 현재 장중 시각 저장이 성공한 뒤 한 번만 종료

## 실행하기

Flutter 안정 버전이 필요합니다.

```bash
flutter pub get
flutter run -d chrome
```

Android 기기 또는 에뮬레이터가 연결되어 있다면:

```bash
flutter run
```

## 검증하기

```bash
flutter analyze
flutter test
flutter build web --release
```

Flutter 테스트가 게임 엔진, v8→v9 저장 마이그레이션, 주식시장의 시스템 Back 저장, 스토리, 미니게임, 시장 소식, 경영진 데이터와 화면 동작을 검증합니다. 테스트 개수와 통과 여부는 최종 통합 검증 결과를 기준으로 확인합니다. 레이아웃 회귀 테스트는 `360×800`과 `390×844` 세로 화면에서 배경·인물·카드·종목 상세·주문 바텀시트가 화면 밖으로 넘치지 않는지 확인합니다.

## 주요 파일

| 경로 | 역할 |
| --- | --- |
| `lib/main.dart` | 앱 상태, 1시간·하루 진행과 v9 저장 |
| `lib/apartment_hub_screens.dart` | 작은방·거실·부엌 허브, 장소 이동과 오브젝트 핫스폿 |
| `lib/room_screens.dart` | 안건함과 고급 포트폴리오·현금원장 전용 장면 |
| `lib/visual_novel_onboarding.dart` | 프롤로그와 가족 대화 |
| `lib/seed_money_screen.dart` | 일거리 허브와 3종 미니게임 |
| `lib/stock_market_screen.dart` | 종목 목록·상세·거래·경영진 UI와 화면·시스템 Back 저장 가드 |
| `lib/organization_screen.dart` | 가족 조언자·직원 배치 UI |
| `lib/game/historical_events.dart` | 날짜별 역사 소식 데이터 |
| `lib/game/historical_executives.dart` | 실제 경영진 재임 데이터 |
| `assets/images/character_hero.png` | 주인공 투명 캐릭터 이미지 |
| `assets/images/bg_bedroom_premium_2000.png` | 작은방 CRT·서류함 배경 |
| `assets/images/bg_living_room_premium_2000.png` | 거실 안건·가족/조직 배경 |
| `assets/images/bg_kitchen_premium_2000.png` | 부엌 전화·일거리 배경 |
| `test/layout_regression_test.dart` | 세로 화면 이미지·레이아웃 회귀 검증 |

배포 시 OG/X 대표 이미지는 저장소 루트의 `public/og-apartment-v2.png`를 사용합니다.

## 다음 우선순위

1. 실제 기기에서 대화 속도, 터치 영역과 작은 화면 가독성 검수
2. KRX 계정·라이선스 연결 후 상장폐지 종목을 포함한 전 종목 원장 생성
3. 일거리 미니게임의 사운드·콤보·난이도 단계 추가
4. 2003년 이후 직원 채용과 부서 성장 콘텐츠 구현
5. 앱 아이콘, 시작 화면과 배포용 Web 호스팅 정리

세부 현재 상태와 이어서 할 일은 저장소 루트의 [`HANDOFF.md`](../HANDOFF.md)를 기준으로 확인합니다.

## 동적 뉴스 API 연결

Flutter Web은 같은 호스트의 `/api/news`를 자동으로 사용합니다. 로컬에서 Next와 Flutter Web을 따로 실행할 때는 Flutter에 `--dart-define=NEWS_API_BASE_URL=http://127.0.0.1:3000`을 전달합니다. 동일 출처와 localhost만 기본 허용하며 추가 Web 출처는 서버의 `NEWS_ALLOWED_ORIGINS`에 쉼표로 지정합니다. Android 빌드는 배포된 Node 서버 주소를 같은 방식으로 전달합니다. AI 서버가 없거나 16초 안에 응답하지 않으면 기존 역사·시장 신문으로 자동 폴백하므로 하루 진행은 막히지 않습니다.
