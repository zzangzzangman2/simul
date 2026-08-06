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
| 시작 | 1999년 12월 31일 강남 데시멀 센터 도착 → 2000년 1월 3일 하루 모의 실습 → 1월 4일 실전 |
| 인물 | 1987년생 동갑내기 10명과 23세 운영관 한서윤 |
| 자금 | 실전 종잣돈 50,000원, 확정 순이익 국가 환수 20% / 재투자 가능 잔액 80% |
| 성장 | 2000년 14살부터 2006년 20살까지 월간 성장 달력 |
| 시장 | 50개 가상기업에서 시작하는 2000~2026 결정론적 시장 |
| 화면 | 모든 폰에서 동일한 390×844 논리 화면을 비율 유지 확대·축소 |
| 저장 | `GameState` v27, 최대 5슬롯 |

프롤로그에서 플레이어 이름을 확정하고 프로젝트 데시멀의 재가동과 선발 과정을 거칩니다. 2000년 1월 3일 각자의 CRT PC와 모의계좌로 딱 하루 연습한 뒤, 1월 4일부터 실제 50,000원 계좌로 주식, 관계, 메신저, 생활, 부동산과 사업을 하나의 날짜·월드시드 안에서 운영합니다.

## 공식 화풍

<p align="center">
  <a href="art_references/simul_polished_soft_render_vn_style_anchor_v3.png">
    <img src="art_references/simul_polished_soft_render_vn_style_anchor_v3.png" width="72%" alt="SIMUL polished soft-render VN anime v3 정식 화풍 앵커">
  </a>
</p>

공식 목표는 **`SIMUL polished soft-render VN anime v3`**입니다. 현재 사용자 승인 정식 화풍 앵커는 위의 `art_references/simul_polished_soft_render_vn_style_anchor_v3.png`이며, 이 이미지에서는 선·명암·피부·홍채·머리카락·의상 마감만 참고합니다.

- 여자 동기 8명은 승인된 얼굴·헤어·체형·의상·포즈를 유지하고 렌더링 화풍만 v3로 전환합니다.
- 주인공은 사용자가 외형을 상상하는 1인칭 역할이므로 고정 얼굴·전신 포즈·대사 초상화를 사용하지 않습니다. 김학준·한서윤·정부 관계자·반복 NPC는 역할·나이·성격을 기준으로 v3 디자인을 사용합니다.
- 새 이미지 작업 전 [생성 프롬프트](IMAGE_GENERATION_STYLE_PROMPT.md), [화풍 가이드](ART_STYLE_GUIDE.md), [런타임 승인표](ART_STYLE_AUDIT.md)를 함께 확인합니다.
- 주인공만 사진이 없는 이유와 적용 범위는 [주인공 무초상화 정책](PROTAGONIST_POSE_LIBRARY.md)을 따릅니다.

## 핵심 플레이 루프

```text
08:00 조간신문·일정 확인
  → 주식 주문 / 정보·은행 / 생활·사업 활동
  → 거래일 15:00 종가·10인 투자 결과 (휴장일은 생략)
  → 월~금요일 장 마감 확인 / 토·일요일 행동력 2칸 자유 일정
     └─ 신문배달·알바 / 미라온 K-뷰티 매장 / 시장 공부 / 휴식
  → 20:00 관계 시간·데시멀톡
  → 월간 성장 달력
  → 다음 날 08:00
```

새벽 신문배달은 우편함 방향으로 신문을 직접 플릭하고 투척 세기·타이밍·차선·콤보로
0~100점을 계산해 약 900~2,500원의 성과 수당을 지급합니다. 세부 규칙은
[NEWSPAPER_DELIVERY_MINIGAME.md](NEWSPAPER_DELIVERY_MINIGAME.md)를 따릅니다.

2000년 첫 주식 실습 뒤 한서윤 운영관의 사전 설명을 들으면 작업실 PC에
`국가망 경마`와 `데시멀 카지노`가 함께 열립니다. 둘 다 현장 이동이나 외부 결제 없이
국가계좌 주문 가능금만 쓰는 온라인 확률시장입니다. 평일 장 마감 뒤 둘 중 하나만
고르며, 경마는 8두 실시간 중계의 단승·연승·복승 전자 마권을 하루 한 번 살 수 있고
정산 즉시 20:00으로 이동합니다. 두 시스템 모두 확정 이익에만 20% 국가 환수를
분리 기록합니다.

토·일요일에는 낮 행동력 2칸으로 세 종류 알바, 미라온 K-뷰티 매장 외출, 도서관 시장 복기, 휴식을 조합합니다. 매장에서는 이미지로 제작된 8종 상품 중 동기별 취향에 맞는 선물을 고르고, 데시멀톡에서는 요일과 무관하게 `MIRAON GIFT` 카드로 같은 상품을 보낼 수 있습니다. 두 경로는 하루 1회 제한을 공유하며 같은 사람에게 같은 상품을 같은 달에 반복하면 호감 효과가 단계적으로 줄어듭니다. 돈이 바닥난 재기 상태에서는 알바 수당을 실전 증권계좌에 바로 넣거나 동기에게 7일 단리 12%로 빌릴 수 있고, 반대로 플레이어도 동기에게 같은 조건으로 빌려줄 수 있습니다. 낮 일정을 마친 뒤에는 호감도 20 이상인 동기와 공개 장소 외출을 선택할 수 있습니다. 데시멀톡은 9명의 MBTI별 성격, 6단계 관계, 당일·누적 손익, 말의 의도, 과거 기억과 현재 게임 날짜·요일·시각·일과를 바탕으로 Gemini 3.5 Flash-Lite가 자연스러운 답장을 만들고, 할당량·장애·불가능한 일정 수락이 생기면 12만 가지 이상의 로컬 조합기로 안전하게 전환합니다. 휴대폰 상단에는 현재 게임 시각이 표시되고 대화 1회마다 30분이 흐르며, 친구별 하루 3회·마지막 시작 21:30·22:00 전원 취침 제한을 적용합니다. 톡 선물은 대화 횟수와 30분을 소비하지 않습니다. 평일 당일 외출은 거절하고 주말 계획만 실제 조건에 맞게 동의하며, 카톡 자체가 데이트를 실행하지는 않습니다. 여자 동기 8명에게는 각자 능력으로 간접 투자 힌트를 물을 수 있지만 직전 거래일까지 공개된 관찰과 확인 방향만 주며 정답 종목·미래 가격은 말하지 않습니다. 관계 수치는 원격 AI가 아니라 로컬 규칙으로만 계산합니다. 빠르게 진행은 장기 투자 시뮬레이션을 위해 매일 관계·달력 선택을 강제하지 않습니다.

현재 `qplay` 무료 등급의 공식 활성 한도는 3.5 Flash-Lite **15 RPM / 250K TPM / 500 RPD**이며, 앱은 여유를 남겨 **8 RPM / 400 RPD**로 제한한다. 3.6 Flash는 하루 20회뿐이라 사용하지 않고, 2.5 Flash 계열도 이 신규 프로젝트 키에서 사용할 수 없다. 키 보안·개인정보·폴백 세부 규칙은 [PHONE_MESSENGER_SYSTEM.md](PHONE_MESSENGER_SYSTEM.md)를 정본으로 삼는다.

생활 라운지에는 날짜마다 여자 동기 8명 중 한 명이 순환 등장합니다. 호감도에 따라 포즈·인사말·화면 거리감이 달라지며, 자동 대기 상태에서는 승인된 관계 포즈를 고정한 채 불규칙한 눈 깜빡임만 재생합니다. 서로 다른 전신 PNG를 잇는 4프레임 동작은 로비에서 재생하지 않고, 보존된 프레임은 추후 대사에 맞는 정지 포즈·컷 연출 후보로만 사용합니다. PC는 작업실, 국가계좌 장부는 기록 보관실에만 배치하며 라운지·투자실·작업실·기록 보관실·본관 앞은 하단 장소 메뉴로 이동합니다. 비주얼 노벨은 PC 휠 뒤로가기와 모바일 오른쪽 스와이프를 지원하며, 모바일 스와이프는 연속 최대 네 장면까지 되돌릴 수 있습니다.

## 핵심 문서

### 정사와 인물

| 문서 | 내용 |
| --- | --- |
| [DECIMAL_WORLD.md](DECIMAL_WORLD.md) | 세계관·프롤로그·인물·생활 정사 |
| [PROTAGONIST_AGE_LINE.md](PROTAGONIST_AGE_LINE.md) | 14~20살 성장선·경험치·9단계 기술·월말/연말 회고 |
| [여학생 8명 인물 정본](characters/cohort6_girls/README.md) | 인물별 성격·MBTI·말투와 개별 문서 진입점 |
| [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | 가상기업·사건·시대 콘텐츠 작성 규칙 |
| [DATA_SOURCES.md](DATA_SOURCES.md) | 데이터 출처·가공·라이선스 원칙 |

### 게임 시스템

| 문서 | 내용 |
| --- | --- |
| [PROJECT_GUIDE.md](PROJECT_GUIDE.md) | 전체 구현 구조·저장·UI·배포·검증 |
| [BALANCE_NOTES.md](BALANCE_NOTES.md) | 주식 시장·호가·체결·경제 수치 |
| [SHAREHOLDER_GOVERNANCE_SYSTEM.md](SHAREHOLDER_GOVERNANCE_SYSTEM.md) | 상장사 주주권·주주총회·공개매수·경영권·복수 자회사 |
| [CALENDAR_SYSTEM.md](CALENDAR_SYSTEM.md) | 월간 성장 달력·주간 복기·주말 행동력·경마·월말/연말 회고 |
| [NEWSPAPER_DELIVERY_MINIGAME.md](NEWSPAPER_DELIVERY_MINIGAME.md) | 새벽 신문배달 플릭·점수·성과 수당·Flutter 렌더링 |
| [HORSE_RACING_SYSTEM.md](HORSE_RACING_SYSTEM.md) | 국가망 온라인 경마·8두 중계·전자 마권·수수료·위조 방지 |
| [CASINO_SYSTEM.md](CASINO_SYSTEM.md) | PC 국가망 카지노·국가계좌 칩 교환·6개 게임·시간·한도·결정론 원장 |
| [RELATIONSHIP_SYSTEM.md](RELATIONSHIP_SYSTEM.md) | 호감도·신뢰·친밀·투자존중·하루 관계 시간·주말 외출 |
| [COHORT_DAILY_INVESTMENT.md](COHORT_DAILY_INVESTMENT.md) | 데시멀 10인 일일 투자 결과·7일 단리 12% 양방향 대여 |
| [PHONE_MESSENGER_SYSTEM.md](PHONE_MESSENGER_SYSTEM.md) | Gemini 3.5 Flash-Lite→로컬 조합기·MBTI 말투·투자 반응·장기기억·키 보안 |
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

## 다른 PC에서 바로 이어서 실행

필수 환경은 Node.js 22.13.0 이상, Flutter 3.44.7, Git, npm입니다. 새 PC에서는
`main`을 받아 아래 순서로 의존성을 복원합니다. `public/play/`는 함께 내려오는 현재
릴리스이며, 새 변경을 배포할 때만 다시 빌드합니다.

```powershell
git clone https://github.com/zzangzzangman2/simul.git
Set-Location simul
git switch main
git pull --ff-only origin main
npm ci
Push-Location flutter_app
flutter pub get
Pop-Location
npm run dev:lan
```

## 기존 작업 폴더에서 로컬 실행

이미 저장소가 있는 PC에서는 다음만 실행합니다.

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
| 신문배달 미리보기 | `http://localhost:8000/play/index.html?newspaperPreview=1` |
| 경마 미리보기 | `http://localhost:8000/play/index.html?horseRacePreview=1` |
| 카지노 격리 테스트 | `http://localhost:8000/play/index.html?casinoTest=1` |

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
