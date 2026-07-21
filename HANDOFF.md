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
- 기준 커밋: `5907cf0 feat: start daily simulation in interactive office`
- 새 주 구현: `flutter_app/`
- Flutter 3.44.7, Dart 3.12.2, Android·Web 대상
- 논리 저장 키: `simul-millennium-capital-v1`
- Flutter 상태 스키마: 버전 5
- 기존 React 앱과 스키마 v3은 시장·거래 이관 기준으로 보존
- 로컬 SDK 확인 경로: `C:\Users\godho\Downloads\flutter-sdk`

## Flutter에 구현된 이야기 시작

- 1999-12-31 23:57 새천년 콜드 오픈과 첫 대화 선택
- 외할아버지가 맡긴 100만원과 어머니 명의 보호자 동의 계좌 설명
- 주인공 이름과 안정·혁신·분석·지배 시작 동기
- 손실 보고·추천주 금지·현금 유지 중 가족 투자규칙 선택
- 법인 대신 A4 간판으로 시작하는 `[회사명] 투자연구소`
- 가족 신뢰, 가족별 관계, 보호자 계좌 권한과 회사문화 태그 저장
- 첫 기업 조사노트와 제품·현금흐름·사람·가격 관점 선택
- 가족 투자연구소 상태 카드와 어머니 명의·생활비 분리 안내

## 대체역사 구현

- 실제 회사명 Apple을 사용한 게임용 Project Atlas 체인
- 경영권 분기, 투자 규모, 개발 문제, 출시·연기·취소와 지연 결과
- 현금 원장, 매출·브랜드·기술·사기·위험과 시뮬레이션 기준지수 변화
- `simulationSeed` 기반 결정론과 사건·원장 중복 반영 방지
- Apple 경영권 안건은 새 게임 첫날이 아니라 2007년부터 해금
- 실제 회사명과 게임용 내부 대화·비용·수치·결과 구분

## 저장과 테스트

- Flutter 상태 v5에 `StoryState`를 포함합니다.
- 기존 Flutter v1·v4 저장은 회사명·날짜·현금·팀을 보존하고 안전한 가족 스토리 기본값을 추가합니다.
- 자동 검증: 엔진 6개 + 위젯 6개, 총 12개
- 화면 검증: `390×844`, `360×800`, 선택 버튼 44px 이상

## 아직 Flutter로 이관하지 않은 것

- React `market-history.json` 로더와 9개 종목의 실제 정규화 수정주가
- 첫 기업 조사 화면, 투자 제안서와 부모 승인 첫 주문
- 매수·매도, 포지션, AUM과 휴장일 직전 종가 처리
- React 웹 저장 v3에서 Flutter v5로의 브라우저 마이그레이션
- 첫 장 마감 수익·손실 가족 반응과 투자일지
- 모뎀·전화, 학교, 닷컴 과열, 낙폭과 첫 가족 투자회의
- CEO·이사회, 월간 기업 재무와 장부 분리

## 바로 다음 작업

**첫 기업 조사노트 → 부모 승인 첫 주문을 구현합니다.**

1. `app/data/market-history.json`을 Flutter 자산으로 등록합니다.
2. 삼성전자·SK텔레콤·POSCO홀딩스를 첫 조사 후보로 보여줍니다.
3. 매수 이유, 위험, 5만원/10만원과 틀렸다는 기준을 선택하게 합니다.
4. 어머니 질문과 승인·수정 요청·거절을 구현합니다.
5. 다음 거래일 예약주문과 첫 장 마감 가족 반응을 연결합니다.

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
- 초기 상태를 법인·1인 회사라고 부르지 않고 가족 투자연구소라고 표시합니다.
- 전화는 초반에 가족·증권사 기능이며 M&A 전화는 성장 후 해금합니다.
- Apple 대체역사는 2007년 이전에 노출하지 않습니다.
- 기존 React 앱은 시장·거래와 v3 저장 이관 전까지 삭제하지 않습니다.
