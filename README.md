# MILLENNIUM CAPITAL

2000년 1월 1일부터 시작하는 모바일 우선 투자회사 경영 시뮬레이션입니다. PC 브라우저에서도 같은 게임을 바로 테스트할 수 있습니다.

## 문서 읽는 순서

| 문서 | 역할 |
| --- | --- |
| [AGENTS.md](./AGENTS.md) | 모든 작업자가 반드시 지켜야 하는 짧은 절대 규칙 |
| [PROJECT_GUIDE.md](./PROJECT_GUIDE.md) | 전체 구현 구조, 실행과 검증 절차 |
| [HANDOFF.md](./HANDOFF.md) | 현재 상태, 최근 논의와 바로 다음 작업 |
| [story.md](./story.md) | 10살 주인공, 가족 투자연구소와 장기 성장 이야기 기준 |
| [ALTERNATE_HISTORY.md](./ALTERNATE_HISTORY.md) | 실제 회사 대체역사 시스템의 영구 규칙과 구현 순서 |
| [CONTENT_GUIDE.md](./CONTENT_GUIDE.md) | 실제 회사 이벤트와 선택 카드 작성 규칙 |
| [BALANCE_NOTES.md](./BALANCE_NOTES.md) | 게임용 가격·비용·확률과 조정 이유 |
| [PRODUCT_VISION.md](./PRODUCT_VISION.md) | 장기 제품 방향과 주인공·경험 원칙 |
| [DO_NOTS.md](./DO_NOTS.md) | 제품, 서사, 데이터와 기술에서 피해야 할 것 |
| [DECISIONS.md](./DECISIONS.md) | 주요 제품·기술 결정과 그 이유 |
| [DATA_SOURCES.md](./DATA_SOURCES.md) | 시장 데이터 출처, 방법론과 라이선스 |
| [EXECUTIVES.md](./EXECUTIVES.md) | 실제 경영진 재임 기간, 출처와 카툰 상반신 자산 규칙 |
| [WORK_LOG.md](./WORK_LOG.md) | 버전별 완료 내역과 검증 결과 |

새 환경에서 이어서 작업할 때는 `AGENTS.md`, `PROJECT_GUIDE.md`, `HANDOFF.md` 순서로 읽고 문서의 상태가 실제 Git 상태와 일치하는지 확인하세요.

## 현재 플레이 가능 범위

- 2000년 1월 1일부터 2010년 12월 31일까지 하루 단위 진행
- 신규 플레이는 현금 0원과 빈 저금장부로 작은방에서 시작
- 방 안의 CRT 컴퓨터를 눌러 주식시장 진입
- KRX, NASDAQ, TSE 대표 기업 9개 투자
- 매수·매도와 거래비용, 현금·포트폴리오·운용자산 계산
- 팀 채용, 평판, 2호 펀드 결성
- 실제 기업사에서 착안한 인수 딜 4개
- 닷컴 버블, 9·11, iPod, Google IPO, iPhone, 금융위기 등 역사 이벤트
- 브라우저 로컬 저장을 이용한 자동 세이브

가격 흐름은 실제 일별 수정주가를 종목별 기준일=100으로 정규화한 개발용 스냅샷입니다. 주말·휴장일에는 직전 거래일 값을 유지하며 미래 가격을 미리 사용하지 않습니다. 자세한 범위와 상용 데이터 전환 계획은 [DATA_SOURCES.md](./DATA_SOURCES.md)를 참고하세요.

## Flutter 앱 실행

새 주 구현은 [`flutter_app`](./flutter_app)에서 진행합니다. Flutter 안정 버전이 필요합니다.

```bash
cd flutter_app
flutter pub get
flutter run -d chrome
```

검증:

```bash
flutter analyze
flutter test
flutter build web --release
```

### Flutter에서 현재 플레이 가능한 이야기 시작

- 1999년 마지막 3분의 새천년 콜드 오픈
- 외할아버지의 빈 저금장부와 직접 버는 첫 종잣돈
- 주인공 이름·시작 동기·가족 투자규칙 선택
- 법인이 아닌 A4 간판 가족 투자연구소와 가족 신뢰
- 설거지 순서·문방구 분류·벼룩장터 계산 3종 미니게임, 점수별 수입과 하루 3회 제한
- 첫 기업 조사노트, 자동 저장과 v6 스토리·조직 마이그레이션
- 가족 조언자 상체 초상·하단 카드 배치, 피로도·도움 기록과 2003년 첫 채용 안내

### Flutter에서 현재 플레이 가능한 대체역사

- 실제 회사명 Apple을 사용한 게임용 경영권 체험 시나리오
- Project Atlas 투자, 개발 문제, 출시·연기·취소와 지연 결과
- 실제 회사명과 게임용 내부 수치·의견·결과를 화면에서 구분
- 분기일 가격 연속성, 결정론적 결과, 자동정지와 현금 원장
- Flutter v1·v4·v5 저장을 상태 스키마 v6로 보존 마이그레이션

## 기존 React 앱 실행

Node.js 22.13 이상이 필요합니다.

```bash
npm install
npm run dev
```

기존 앱은 기능 이관과 저장 데이터 마이그레이션을 위한 기준 구현으로 보존합니다.

```bash
npm run build
npm test
```

## 시장 데이터 갱신

```bash
npm run data:fetch
```

이 명령은 `app/data/market-history.json`을 다시 생성합니다. 외부 응답이 바뀌면 수정주가 스냅샷도 달라질 수 있으므로, 갱신 전후 차이를 검토한 뒤 커밋하세요.

## 기술 구성

- 새 주 구현: Flutter 3.44 이상 + Dart 3.12 이상
- 대상 플랫폼: Android, Web
- 기준 구현: Next.js 호환 vinext + React + TypeScript
- 별도 계정 없이 기기 로컬에 게임 저장
- 모바일 360px부터 데스크톱까지 동일한 세로형 게임 프레임
