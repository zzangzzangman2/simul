# MILLENNIUM CAPITAL

2000년 1월 1일부터 시작하는 모바일 우선 투자회사 경영 시뮬레이션입니다. PC 브라우저에서도 같은 게임을 바로 테스트할 수 있습니다.

## 현재 플레이 가능 범위

- 2000년 1월부터 2010년 12월까지 월 단위 진행
- KRX, NASDAQ, TSE 대표 기업 9개 투자
- 매수·매도와 거래비용, 현금·포트폴리오·운용자산 계산
- 팀 채용, 평판, 2호 펀드 결성
- 실제 기업사에서 착안한 인수 딜 4개
- 닷컴 버블, 9·11, iPod, Google IPO, iPhone, 금융위기 등 역사 이벤트
- 브라우저 로컬 저장을 이용한 자동 세이브

가격 흐름은 월별 수정주가를 종목별 기준월=100으로 정규화한 개발용 스냅샷입니다. 자세한 범위와 상용 데이터 전환 계획은 [DATA_SOURCES.md](./DATA_SOURCES.md)를 참고하세요.

다른 환경에서 이어서 개발할 때는 [PROJECT_GUIDE.md](./PROJECT_GUIDE.md)를 먼저 읽으세요. 모바일 기준과 절대 유지해야 하는 규칙은 [AGENTS.md](./AGENTS.md)에 짧게 고정해 두었습니다.

## 로컬 실행

Node.js 22.13 이상이 필요합니다.

```bash
npm install
npm run dev
```

브라우저에서 `http://localhost:3000`을 엽니다.

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

- Next.js 호환 vinext + React + TypeScript
- Cloudflare Worker 호환 빌드
- 별도 계정 없이 기기 로컬에 게임 저장
- 모바일 360px부터 데스크톱까지 반응형 UI
