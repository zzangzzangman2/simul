# 10대부터 건물주

2000년 1월, 국가 비밀 금융 생존 실험 `프로젝트 데시멀`의 최종 열 명이 강남의
무표지 센터에서 50,000원을 맡아 첫 주문을 시작하는 모바일 세로형 생활·투자
시뮬레이션입니다. 주식, 부동산, 동네 사업, 은행, 관계와 장기 기업행동이 같은
시간축과 원장 위에서 움직입니다.

## 현재 정본

- 세계관: [`DECIMAL_WORLD.md`](./DECIMAL_WORLD.md)
- 시작: 1981년 자본전 선언 → 장기 실패 → 1999년 3단계 선발 → 강남 합숙 첫날 →
  2000년 1월 3일 50,000원 장부 → 주식실습
- 인물: 성준·김학준과 승인된 여자 동기 8명, 23세 한서윤 운영관
- 대사: 8장 292장면, `contentVersion 2`, `appearanceVersion 14`
- 신규 캠페인에서는 가족 NPC 및 가족 미션을 만들지 않습니다. 구형 저장의 가족
  콘텐츠만 호환을 위해 보존합니다.

과거 기관·기수·단계 설정은 폐기됐습니다. 옛 파일명과 내부 키 일부는 저장 호환용일
뿐이며 화면 문구나 새 서사의 근거로 사용하지 않습니다.

## 실행

```powershell
pnpm install
pnpm dev:lan
```

- 게임: `http://localhost:3000/play/index.html`
- 대사 편집기: `http://localhost:3000/editor`
- 주식 단독 테스트: `http://localhost:3000/play/stock-test.html`

## 검증과 빌드

```powershell
pnpm run dialogue:sync
pnpm run lint
pnpm test
pnpm run build:release
```

Flutter 테스트는 `flutter_app/test/*.dart`를 파일별로 실행합니다. 대사 원본은
`flutter_app/assets/dialogue/dialogue-editor-override.json`이며 생성 파일을 직접
고치지 않습니다.

## 핵심 경로

- `DECIMAL_WORLD.md`: 세계관·인물·생활 규칙·8장 서사 정본
- `scripts/build-decimal-dialogue.mjs`: 292장면 정본 생성기
- `flutter_app/lib/visual_novel_onboarding.dart`: 프롤로그 런타임
- `flutter_app/lib/stock_market_tutorial.dart`: 주식실습 연결
- `flutter_app/assets/images/cinematic_soft_painted/decimal/`: 신규 배경 11종
- `HANDOFF.md`: 현재 구현과 다음 작업
