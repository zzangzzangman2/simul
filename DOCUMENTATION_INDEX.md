# 문서 기준표

최종 갱신: 2026-08-05

이 저장소에는 현재 구현을 설명하는 문서만 둔다. 작업 일지, 후보 제작 보고서,
폐기된 서사 원고는 정본과 함께 보관하지 않는다.

## 충돌 판단 순서

1. 현재 코드와 자동화 테스트
2. `AGENTS.md`의 전역 불변 조건
3. `DECISIONS.md`의 현재 결정
4. `PROJECT_GUIDE.md`와 아래 분야별 정본

충돌을 발견하면 과거 문서를 근거로 되돌리지 말고 코드·테스트·정본 문서를 같은
변경에서 맞춘다.

## 처음 읽을 문서

| 목적 | 문서 |
| --- | --- |
| 전역 작업 규칙 | `AGENTS.md` |
| 제품·실행 진입점 | `README.md` |
| 구현 구조·저장·배포·검증 | `PROJECT_GUIDE.md` |
| 현재 구현 상태 | `HANDOFF.md` |
| 채택된 결정 | `DECISIONS.md` |
| 금지 패턴 | `DO_NOTS.md` |
| 미완성 범위 | `GAMEPLAY_GAPS.md` |

## 분야별 정본

| 분야 | 문서 |
| --- | --- |
| 프로젝트 데시멀 세계관·프롤로그 | `DECIMAL_WORLD.md` |
| 플레이어·동기 연령·실제 경험치/기술·월말/연말 회고 | `PROTAGONIST_AGE_LINE.md` |
| 월간 성장 달력·주간 복기·주말 행동력·알바·선물·평일 경마·외출·날짜 사건 | `CALENDAR_SYSTEM.md` |
| 새벽 신문배달 플릭 조작·점수·성과 수당·렌더링 | `NEWSPAPER_DELIVERY_MINIGAME.md` |
| 데시멀 카지노 현장·딜러·칩 교환·테이블 규칙·시간·한도·원장 | `CASINO_SYSTEM.md` |
| 요원 PC 국가망 경마·전자 마권·수수료·실시간 중계 | `HORSE_RACING_SYSTEM.md` |
| 여학생 8명 성격·대사 | `characters/cohort6_girls/README.md`와 인물별 문서 |
| 관계 시스템 | `RELATIONSHIP_SYSTEM.md` — 호감도·신뢰·친밀·투자존중·주말 외출 |
| 데시멀 동기 일일 투자·대여 | `COHORT_DAILY_INVESTMENT.md` |
| 데시멀톡 | `PHONE_MESSENGER_SYSTEM.md` — Gemini 3.5 Flash-Lite·로컬 폴백·성격별 대화·투자 반응·장기기억 |
| 대사 편집기 | `DIALOGUE_EDITOR_GUIDE.md` |
| 시장·경제 수치 | `BALANCE_NOTES.md` |
| 상장사 실적/감사/주총 공시 일정·주주권·경영권·자회사·발행/유통주식 호가원장 | `SHAREHOLDER_GOVERNANCE_SYSTEM.md` |
| 부동산 | `REAL_ESTATE_SYSTEM.md` |
| 가상기업·사건 문법 | `CONTENT_GUIDE.md` |
| 데이터·라이선스 | `DATA_SOURCES.md` |
| 제품 방향 | `PRODUCT_VISION.md` |
| 이미지 제작·v3 전환 규칙 | `ART_STYLE_GUIDE.md`, `IMAGE_GENERATION_STYLE_PROMPT.md` |
| 런타임 이미지 승인표 | `ART_STYLE_AUDIT.md` |
| 주인공 무초상화 정책 | `PROTAGONIST_POSE_LIBRARY.md` — 플레이어만 사진이 없는 이유와 적용 범위 |

## 런타임 자산 메모

`flutter_app/assets/images/` 아래 README는 그 폴더의 현재 런타임 자산 규격만
설명한다. 인물 후보나 폐기 이력을 기록하지 않는다. `public/play/` 안의 파일은
릴리스 빌드 산출물이므로 문서 정본으로 읽지 않는다.

2026-08-03 사용자 승인 v3 화풍 정식 앵커는
`art_references/simul_polished_soft_render_vn_style_anchor_v3.png`다. 여자 동기 8명만
기존 외형을 보존하고 나머지 부적합 인물은 전면
재설계한다는 범위는 `ART_STYLE_GUIDE.md`와 `ART_STYLE_AUDIT.md`가 정본이다.

## 문서로 취급하지 않는 것

- `.next/`, `.vinext/`, `dist/`, `work/`, `flutter_app/build/`
- 이미지 후보·아카이브·실사 시험본·루트 임시 PNG
- Git 이력으로 확인할 수 있는 날짜별 작업 일지와 과거 검토 보고서
- `public/play/`에 복제된 빌드 산출물

완료한 구현은 `HANDOFF.md`에 현재형으로 짧게 반영하고, 남은 일만
`GAMEPLAY_GAPS.md`에 적는다. 같은 정보를 여러 문서에 복제하지 않는다.
