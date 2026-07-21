# 현재 인수인계 상태

마지막 갱신: 2026-07-21

## 가장 먼저 읽을 순서

1. `AGENTS.md`
2. `PROJECT_GUIDE.md`
3. `HANDOFF.md`
4. `story.md`
5. `ALTERNATE_HISTORY.md`
6. `CONTENT_GUIDE.md`, `BALANCE_NOTES.md`
7. `PRODUCT_VISION.md`, `DO_NOTS.md`, `DECISIONS.md`
8. `DATA_SOURCES.md`, `WORK_LOG.md`

## 현재 상태

- 브랜치: `main`
- 기준 커밋: `0a46a09 docs: refresh GitHub project overview` + 국내시장 미커밋 변경
- 새 주 구현: `flutter_app/`
- Flutter 3.44.7, Dart 3.12.2, Android·Web 대상
- 논리 저장 키: `simul-millennium-capital-v1`
- Flutter 상태 스키마: 버전 6
- 기존 React 앱과 스키마 v3은 시장·거래 이관 기준으로 보존
- 로컬 SDK 확인 경로: `C:\Users\godho\Downloads\flutter-sdk`

## Flutter에 구현된 이야기 시작

- 1999-12-31 23:57 작은방에서 시작해 거실·식탁·다시 작은방으로 이어지는 16장면 미연시식 프롤로그
- 첫 선택 전 방 설명, 엄마의 호출, 거실 이동, 아빠·누나 대화를 순서대로 재생
- imagegen 배경 3종과 외할아버지·아버지·어머니·누나·주인공 투명 캐릭터 5종
- 배경 크로스페이드·미세 줌, 말하는 인물의 페이드·슬라이드 등장
- 구현 파일: `flutter_app/lib/visual_novel_onboarding.dart`
- 외할아버지의 현금 증여 없이 첫 장이 0원인 저금장부로 시작
- 주인공 이름과 안정·혁신·분석·지배 시작 동기
- 손실 보고·추천주 금지·현금 유지 중 가족 투자규칙 선택
- 법인 대신 A4 간판으로 시작하는 `[회사명] 투자연구소`
- 가족 신뢰, 가족별 관계, 보호자 계좌 권한과 회사문화 태그 저장
- 첫 기업 조사노트와 제품·현금흐름·사람·가격 관점 선택
- CRT 시장의 국내 22개 기본 팩, 국내·코스피·코스닥 탭과 기존 해외 6개 보존 탭
- 종목 상세의 실제 일별 종가와 분리된 0.9초 장중 틱, 장 상태·전일 대비·기업 요약·사기/팔기·부모 주문 승인 시트
- 종목 상세의 날짜형 실제 경영진 카드: 삼성전자 회장·CEO 분리, Microsoft 2000-01-13 CEO 이양
- 2000년 시작 핵심 10개 회사 12명의 밝은 카툰 상반신 WebP 초상
- 경영진 레코드·출처·추가 순서는 EXECUTIVES.md에 기록
- 시장 구현 파일: `flutter_app/lib/stock_market_screen.dart`
- 가족 투자연구소 상태 카드와 어머니 명의·생활비 분리 안내
- 사무실 `일거리`에서 설거지 순서·문방구 품목 분류·가족 벼룩장터 거스름돈 3종 미니게임
- 2000년 상반기 시간급 1,600원 기준, 점수별 300~1,600원 수입, 하루 3회 제한과 현금 장부 저장
- 첫 조사예산 목표 1만원 뒤에도 일거리 지속 여부를 플레이어가 선택
- 구현 파일: `flutter_app/lib/seed_money_screen.dart`, `flutter_app/lib/game/seed_money_content.dart`
- `사람들` 화면의 가족 조언자 배치: 선택 인물 상체 초상, 하단 카드, 역할·전문분야·피로도·하루 1회 조사 도움
- 가족 도움 기록·일일 피로 회복과 2003년 첫 조사원 채용 해금 안내
- 구현 파일: `flutter_app/lib/game/organization_state.dart`, `flutter_app/lib/organization_screen.dart`

## 대체역사 구현

- 실제 회사명 Apple을 사용한 게임용 Project Atlas 체인
- 경영권 분기, 투자 규모, 개발 문제, 출시·연기·취소와 지연 결과
- 현금 원장, 매출·브랜드·기술·사기·위험과 시뮬레이션 기준지수 변화
- `simulationSeed` 기반 결정론과 사건·원장 중복 반영 방지
- Apple 경영권 안건은 새 게임 첫날이 아니라 2007년부터 해금
- 실제 회사명과 게임용 내부 대화·비용·수치·결과 구분

## 저장과 테스트

- Flutter 상태 v7에 `StoryState`와 `OrganizationState`를 포함합니다.
- 기존 Flutter v1·v4·v5 저장은 회사명·날짜·현금·숫자형 팀을 보존하고 가족 스토리와 조직 기본값을 추가합니다.
- 자동 검증: 엔진·경영진·시장소식·위젯·모바일 레이아웃 총 46개
- 화면 검증: `390×844`, `360×800`, 선택 버튼 44px 이상
- 360×800 회귀 검증: 프롤로그 16장면 인물, 종목·경영진 초상, 조직 카드, 일거리 3종, 뉴스 팝업의 경계 이탈 없음

## 아직 Flutter로 이관하지 않은 것

- 첫 기업 조사 화면, 투자 제안서와 부모 승인 첫 주문
- Flutter 실제 종가 기반 매수·매도, 포지션과 AUM 저장 연결
- React 웹 저장 v3에서 Flutter v7로의 브라우저 마이그레이션
- 첫 장 마감 수익·손실 가족 반응과 투자일지
- 모뎀·전화, 학교, 닷컴 과열, 낙폭과 첫 가족 투자회의
- CEO·이사회, 월간 기업 재무와 장부 분리

## 바로 다음 작업

**KRX 계정과 라이선스를 확인해 2000~2010 KOSPI·KOSDAQ 전 종목 원장을 생성합니다.**

1. KRX Data Marketplace 계정의 개인·개발·재배포 조건을 확인합니다.
2. 로컬에만 `KRX_ID`, `KRX_PW`를 설정하고 `npm run data:fetch:krx-full`을 실행합니다.
3. `.cache/krx-market/failures.json`이 비어 있고 상장폐지·합병 종목이 포함됐는지 검증합니다.
4. 역사적 사명과 업종을 날짜형 종목 마스터로 보강합니다.
5. 공개 저장소에 넣기 전 KRX 원자료 재배포 권한을 다시 확인합니다.

## 실행과 검증

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

## 주의

- 10살 주인공이 계좌 비밀번호를 직접 누르거나 부모 명의를 도용하지 않습니다.
- 10살 시기에는 정식 고용이 아니라 집안일·보호자 동행 일거리·가족 벼룩장터만 사용합니다.
- 초기 상태를 법인·1인 회사라고 부르지 않고 가족 투자연구소라고 표시합니다.
- 2000~2002년은 가족 조언자 단계이며 정식 채용은 2003년 첫 조사원부터 엽니다.
- 배치 화면의 선택 인물은 전신이 아니라 상체 초상으로 크게 표시합니다.
- 전화는 초반에 가족·증권사 기능이며 M&A 전화는 성장 후 해금합니다.
- Apple 대체역사는 2007년 이전에 노출하지 않습니다.
- 기존 React 앱은 시장·거래와 v3 저장 이관 전까지 삭제하지 않습니다.

## 시장 시간/신문 이어서 작업할 때

- 시간 규칙: `flutter_app/lib/game/market_clock.dart`
- 저장·다음 날 08:00 초기화: `game_state.dart`, `game_engine.dart`
- 15:30 실제 종가 앵커와 확장장 경로: `market_tick.dart`
- 주식 화면 시계/+1시간: `stock_market_screen.dart`
- 사무실 시계/하루 종료 신문 UI: `main.dart`
- 실제 종가 기반 신문 집계: `market_news.dart`
- 경계값·경로·신문 테스트: `test/market_clock_test.dart`

NXT는 2000년 역사 사실이 아니라 게임 규칙이라는 라벨을 유지한다. 다음 단계는 음력 공휴일/임시휴장일 캘린더 데이터와 신문 지면의 업종별 요약 확장이다.
