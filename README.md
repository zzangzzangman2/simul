# 10대부터 건물주 — PROJECT DECIMAL

> 2000년 서울. 열네 살 동기 10명이 국가원금 50,000원으로 판단과 자립 장부를 쌓는 세로형 투자·생활 시뮬레이션.

[![CI](https://github.com/zzangzzangman2/simul/actions/workflows/ci.yml/badge.svg)](https://github.com/zzangzzangman2/simul/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44.7-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-2F855A)

프로젝트의 유일한 세계관 정본은 [DECIMAL_WORLD.md](DECIMAL_WORLD.md)입니다. 과거의 `미래양성원`, `제6기`, `SEED`, 학교 입학 설정은 현재 게임의 근거로 사용하지 않습니다.

## 게임 한눈에 보기

| 항목 | 현재 기준 |
| --- | --- |
| 장르 | 투자·생활 시뮬레이션 + 비주얼 노벨 |
| 시작 | 1999년 12월 31일 강남 데시멀 센터 도착 → 2000년 1월 3일 09:00 자유 플레이 |
| 인물 | 1987년생 동갑내기 10명과 23세 운영관 한서윤 |
| 자금 | 국가원금 50,000원, 확정 순이익 국가 환수 20% / 자립적립금 80% |
| 성장 | 2000년 14살부터 2006년 20살까지 월간 성장 달력 |
| 시장 | 50개 가상기업에서 시작하는 2000~2026 결정론적 시장 |
| 화면 | 세로 390×844 기준, 최소 너비 360px |
| 저장 | `GameState` v25, 최대 5슬롯 |

프롤로그에서 플레이어 이름을 확정하고 프로젝트 데시멀의 재가동과 선발 과정을 거칩니다. 2000년 1월 3일 각자의 CRT PC와 국가계좌를 받은 뒤 주식, 관계, 메신저, 생활, 부동산과 사업을 하나의 날짜·월드시드 안에서 운영합니다.

## 공식 화풍

<p align="center">
  <a href="art_references/simul_polished_soft_render_vn_style_anchor_v3.png">
    <img src="art_references/simul_polished_soft_render_vn_style_anchor_v3.png" width="72%" alt="SIMUL polished soft-render VN anime v3 정식 화풍 앵커">
  </a>
</p>

공식 목표는 **`SIMUL polished soft-render VN anime v3`**입니다. 현재 사용자 승인 정식 화풍 앵커는 위의 `art_references/simul_polished_soft_render_vn_style_anchor_v3.png`이며, 이 이미지에서는 선·명암·피부·홍채·머리카락·의상 마감만 참고합니다.

- 여자 동기 8명은 승인된 얼굴·헤어·체형·의상·포즈를 유지하고 렌더링 화풍만 v3로 전환합니다.
- 주인공·김학준·한서윤·정부 관계자·반복 NPC는 구형 외형 보존 대상이 아니며 역할·나이·성격을 기준으로 새로 설계합니다.
- 새 이미지 작업 전 [생성 프롬프트](IMAGE_GENERATION_STYLE_PROMPT.md), [화풍 가이드](ART_STYLE_GUIDE.md), [런타임 승인표](ART_STYLE_AUDIT.md)를 함께 확인합니다.
- 주인공 동작은 [주인공 포즈 라이브러리](PROTAGONIST_POSE_LIBRARY.md)를 따릅니다.

## 핵심 플레이 루프

```text
08:00 조간신문·일정 확인
  → 주식 주문 / 정보·은행 / 생활·사업 활동
  → 거래일 15:00 종가·10인 투자 결과 (휴장일은 생략)
  → 20:00 관계 시간·데시멀톡
  → 월간 성장 달력
  → 다음 날 08:00
```

호감도 20 이상이면 주식시장이 쉬는 토·일요일에 공개 장소 외출을 선택할 수 있습니다. 데시멀톡은 9명의 성격, 6단계 관계, 당일·누적 손익, 말의 의도와 과거 기억을 조합해 12만 가지 이상의 답장 공간을 만들며 하루 첫 의미 있는 톡만 관계에 반영합니다. 빠르게 진행은 장기 투자 시뮬레이션을 위해 매일 관계·달력 선택을 강제하지 않습니다.

## 핵심 문서

### 정사와 인물

| 문서 | 내용 |
| --- | --- |
| [DECIMAL_WORLD.md](DECIMAL_WORLD.md) | 세계관·프롤로그·인물·생활 정사 |
| [PROTAGONIST_AGE_LINE.md](PROTAGONIST_AGE_LINE.md) | 플레이어와 동기들의 14~20살 성장선 |
| [여학생 8명 인물 정본](characters/cohort6_girls/README.md) | 인물별 성격·MBTI·말투와 개별 문서 진입점 |
| [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | 가상기업·사건·시대 콘텐츠 작성 규칙 |
| [DATA_SOURCES.md](DATA_SOURCES.md) | 데이터 출처·가공·라이선스 원칙 |

### 게임 시스템

| 문서 | 내용 |
| --- | --- |
| [PROJECT_GUIDE.md](PROJECT_GUIDE.md) | 전체 구현 구조·저장·UI·배포·검증 |
| [BALANCE_NOTES.md](BALANCE_NOTES.md) | 주식 시장·호가·체결·경제 수치 |
| [CALENDAR_SYSTEM.md](CALENDAR_SYSTEM.md) | 월간 성장 달력·휴장일·주말 외출·날짜 사건 그림 |
| [RELATIONSHIP_SYSTEM.md](RELATIONSHIP_SYSTEM.md) | 호감도·신뢰·친밀·투자존중·하루 관계 시간·주말 외출 |
| [COHORT_DAILY_INVESTMENT.md](COHORT_DAILY_INVESTMENT.md) | 데시멀 10인 일일 투자 결과·7일 무이자 대여 |
| [PHONE_MESSENGER_SYSTEM.md](PHONE_MESSENGER_SYSTEM.md) | 성격별 대화 조합기·투자 반응·장기기억·일일 제한 |
| [REAL_ESTATE_SYSTEM.md](REAL_ESTATE_SYSTEM.md) | 부동산 매물·대출·세금·운영 |

### 제작과 현재 상태

| 문서 | 내용 |
| --- | --- |
| [ART_STYLE_GUIDE.md](ART_STYLE_GUIDE.md) | 공식 v3 화풍과 정체성 보존 범위 |
| [IMAGE_GENERATION_STYLE_PROMPT.md](IMAGE_GENERATION_STYLE_PROMPT.md) | 이미지 생성·수정용 정식 프롬프트 |
| [ART_STYLE_AUDIT.md](ART_STYLE_AUDIT.md) | 현재 런타임 이미지 승인·교체 판정 |
| [DIALOGUE_EDITOR_GUIDE.md](DIALOGUE_EDITOR_GUIDE.md) | 대사·장면 편집기 사용과 반영 절차 |
| [HANDOFF.md](HANDOFF.md) | 현재 구현 상태 |
| [GAMEPLAY_GAPS.md](GAMEPLAY_GAPS.md) | 아직 남은 구현 범위 |
| [PRODUCT_VISION.md](PRODUCT_VISION.md) | 제품 방향과 플레이 감정 |

전체 문서 탐색 순서와 충돌 우선순위는 [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)를 따릅니다. 작업자는 [AGENTS.md](AGENTS.md), [DECISIONS.md](DECISIONS.md), [DO_NOTS.md](DO_NOTS.md)도 먼저 확인합니다.

## 로컬 실행

필수 환경은 Node.js 22.13.0 이상, Flutter 3.44.7, npm입니다.

```powershell
npm ci
Push-Location flutter_app
flutter pub get
Pop-Location
npm run dev:lan
```

| 화면 | 주소 |
| --- | --- |
| 게임 | `http://localhost:8000/play/index.html` |
| 대사 편집기 | `http://localhost:8000/editor` |
| 주식 단독 테스트 | `http://localhost:8000/play/stock-test.html` |

루트 `/`는 `/play/index.html`로 이동합니다. 대사 편집기의 저장·미리보기·빌드 방법은 [DIALOGUE_EDITOR_GUIDE.md](DIALOGUE_EDITOR_GUIDE.md)에만 관리합니다.

## 검증과 빌드

```powershell
npm run dialogue:sync
npm run lint
npm test

Push-Location flutter_app
flutter analyze
Get-ChildItem -LiteralPath test -Filter '*_test.dart' |
  Sort-Object Name |
  ForEach-Object { flutter test $_.FullName }
Pop-Location

npm run build:release
```

`public/play/`는 Flutter Web 생성 산출물이므로 직접 편집하지 않습니다. 원본은 `flutter_app/`, 대사 정본은 `flutter_app/assets/dialogue/dialogue-editor-override.json`입니다. 완료 기능은 [HANDOFF.md](HANDOFF.md), 남은 기능은 [GAMEPLAY_GAPS.md](GAMEPLAY_GAPS.md)에만 기록합니다.
