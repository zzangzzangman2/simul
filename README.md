# 10대부터 건물주 — PROJECT DECIMAL

> 2000년 서울. 국가가 맡긴 50,000원으로 시작하는 10명의 투자·생활 시뮬레이션.

[![CI](https://github.com/zzangzzangman2/simul/actions/workflows/ci.yml/badge.svg)](https://github.com/zzangzzangman2/simul/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44.7-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-2F855A)

<p align="center">
  <img src="flutter_app/assets/images/cinematic_soft_painted/decimal/bg_decimal_matrix_exam_1999_v1.png" width="32%" alt="1999년 데시멀 선발 시험">
  <img src="flutter_app/assets/images/cinematic_soft_painted/decimal/bg_decimal_gangnam_exterior_winter_1999_v1.png" width="32%" alt="눈 내리는 강남 데시멀 센터">
  <img src="flutter_app/assets/images/cinematic_soft_painted/decimal/bg_decimal_trading_floor_dawn_2000_v1.png" width="32%" alt="2000년 새벽 트레이딩 플로어">
</p>

**PROJECT DECIMAL**은 국가 보호시설에서 자란 열네 살 아이들이 비공개 금융 훈련 프로그램 **데시멀**에 선발되면서 시작되는 세로형 모바일 게임입니다. 플레이어는 2000년 1월 3일, 국가 원금 50,000원을 받고 주식·관계·생활·부동산·사업을 함께 운영합니다.

현재 정사는 `미래양성원`, `제6기`, `SEED`, 학교 입학물 같은 과거 설정이 아닙니다. 최신 세계관의 기준 문서는 [DECIMAL_WORLD.md](DECIMAL_WORLD.md)입니다.

## 게임 한눈에 보기

| 항목 | 현재 기준 |
| --- | --- |
| 장르 | 투자·생활 시뮬레이션 + 비주얼 노벨 |
| 시대와 장소 | 1999년 12월 31일~2000년대 서울 |
| 플레이어 | 1987년생, 2000년 한국 나이 14세 |
| 핵심 인물 | 플레이어, 김학준, 동갑내기 여자아이 8명, 운영관 한서윤 |
| 시작 자금 | 국가 원금 50,000원 |
| 수익 배분 | 실현 순이익의 국가 20% / 자립적립금 80% |
| 프롤로그 | 8장, 292개 장면 |
| 대사 데이터 | content v3 / appearance v17 |
| 주식 세계 | 고정 50개사에서 시작해 IPO·분할로 200개 이상 확장 |
| 저장 | 스키마 v24, 최대 5슬롯 |
| 화면 기준 | 세로 390×844, 최소 폭 360 |
| 플랫폼 | Android / Web |

## 스토리

1999년 마지막 날, 국가정보원 지하에서 폐기됐던 실패 기록이 다시 열린다. 과거의 비인간적인 실험을 되풀이하지 않기 위해 담당자들은 선발 과정과 운영 원칙을 새로 세운다. 아이들의 판단은 국가의 소유물이 아니라, 성인이 되었을 때 돌려받을 자립 자산으로 남아야 한다.

강남의 데시멀 센터에 모인 열 명은 서로의 이름도, 이곳에 온 이유도 모른 채 첫날 밤을 보낸다. 그리고 2000년 1월 3일 오전 9시, CRT 모니터에 국가 원금 **50,000원**이 표시되며 게임의 자유 플레이가 시작된다.

### 프롤로그 8장

| 장 | 제목 | 장면 | 핵심 내용 |
| ---: | --- | ---: | --- |
| 1 | 데시멀 재가동 | 20 | 1999년, 봉인됐던 계획의 재검토 |
| 2 | 봉인된 실패 기록 | 18 | 과거 실험의 실패와 새 운영 원칙 |
| 3 | 종이 속에 숨긴 행렬 | 30 | 보호시설 기록에서 후보를 찾는 과정 |
| 4 | 불공정한 게임 | 31 | 같은 답보다 판단 과정을 보는 선발 시험 |
| 5 | 무엇을 원하는 아이들인가 | 24 | 최종 면담과 각자의 선택 |
| 6 | 눈 내리는 강남의 열 명 | 44 | 데시멀 센터 도착과 첫 만남 |
| 7 | 첫날 밤의 공동 장부 | 91 | 생활 규칙, 갈등, 공동체의 시작 |
| 8 | 50,000원이 켜지는 아침 | 34 | 자금 지급과 투자 튜토리얼 진입 |
|  | **합계** | **292** |  |

## 핵심 플레이 루프

```text
아침 브리핑
  → 뉴스·시장·생활 일정 확인
  → 주식 주문 / 정보 구매 / 은행 업무
  → 관계·메신저·부동산·사업 활동
  → 장 마감과 일일 정산
  → 10명의 결과 비교 및 다음 날 선택
```

스토리에서 자유 플레이로 넘어간 뒤에도 주식만 따로 굴러가지 않습니다. 같은 날짜와 거시 이벤트가 주식, 사업, 부동산에 한 번만 투영되고, 플레이어의 현금·부채·관계·시간이 하나의 경제 안에서 맞물립니다.

## 현재 구현된 시스템

| 시스템 | 구현 내용 |
| --- | --- |
| 주식 시장 | 50개 가상 기업, 2000~2026 시드 데이터, IPO·분할·상장폐지 등 기업 행동 |
| 주문 체결 | 매수·매도 각 10호가, 시장가 IOC, 지정가, 부분 체결, 종가 동시호가 |
| 정보 비대칭 | 결정론적 일일 뉴스, 유료 리포트, 미래 정보 누출 방지 |
| 공동 투자 | 10명의 일일 성과, 7일 무이자 대여 1회 |
| 관계 | 여자아이 8명, 호감도 1~100, 하루 1회 교류, 호감도 20 이상 공개 데이트 |
| DecimalTalk | 9명 연락처, 추천 답장·직접 입력, 읽지 않은 메시지, 인물별 하루 3회 |
| 부동산 | 14개 권역, 기본 자산 18종·매물 54개, 대출·세금·공실·월세·전세·수리·매각 |
| 사업 | 18개 업종 × 6개 상권 입지 × 32개 권역, 6축 운영 정책, 이벤트·월별 손익·폐업 |
| 은행 | 예금, 신용대출, 신용점수, DSR, 연체 처리 |
| 공유 경제 | 하나의 거시 이벤트를 주식·사업·부동산에 일관되게 반영 |
| 경영권 | 한빛전자부품 지분, 이사회 권리, 첫 운영 전략 단계 |
| 저장 | 최대 5슬롯, 스키마 v24 및 이전 저장 데이터 마이그레이션 |

아직 완료되지 않은 항목과 우선순위는 [GAMEPLAY_GAPS.md](GAMEPLAY_GAPS.md)에서 관리합니다.

## 주요 인물

| 인물 | 역할 |
| --- | --- |
| 플레이어 | 이름을 직접 정하는 데시멀 참가자 |
| 김학준 | 플레이어의 경쟁심을 자극하는 동갑내기 라이벌 |
| 김서아 | 모두가 확인할 수 있는 생활 기록과 약속을 관리하는 인물 |
| 이지안 | 말보다 직접 열어 보고 작동 원인을 찾는 수리·기기 담당 |
| 최이서 | 손으로 만든 물건과 개인의 선택·경계를 중시하는 제작자 |
| 정아린 | 생각을 담당·순서·마감으로 바꾸는 현장 실행 담당 |
| 박하은 | 말하지 못한 사람까지 합의에 참여시키는 관계 조정자 |
| 한수아 | 표정에서 가능성을 읽고 먼저 말을 거는 분위기 촉진자 |
| 오지우 | 한 가지 설명에서 반례와 다른 가설을 찾는 라디오광 |
| 윤채아 | 가격 뒤의 구조와 다음 움직임을 보는 장기 전략가 |
| 한서윤 | 데시멀의 23세 운영관 |

인물별 정사와 말투 기준은 [characters/cohort6_girls/README.md](characters/cohort6_girls/README.md)에서 확인할 수 있습니다.

## 로컬 실행

### 요구 환경

- Node.js 22.13.0 이상 — CI는 Node.js 24 사용
- Flutter 3.44.7
- npm

### 설치 및 개발 서버

```powershell
npm ci
Push-Location flutter_app
flutter pub get
Pop-Location
npm run dev:lan
```

`npm run dev:lan`은 `0.0.0.0:8000`에서 실행됩니다.

| 화면 | 주소 |
| --- | --- |
| 게임 | `http://localhost:8000/play/index.html` |
| 대사 편집기 | `http://localhost:8000/editor` |
| 주식 테스트 | `http://localhost:8000/play/stock-test.html` |

로컬 PC에서만 확인할 때는 `npm run dev`를 사용할 수 있으며 기본 포트는 3000입니다.

## 대사 편집기

대사의 단일 원본은 [flutter_app/assets/dialogue/dialogue-editor-override.json](flutter_app/assets/dialogue/dialogue-editor-override.json)입니다. `/editor`에서는 장면 순서, 제목, 날짜, 장소, 배경, 화자, 포즈, 지문·대사를 수정하고 미리 볼 수 있습니다.
캐릭터는 무대에서 직접 끌거나 휠·슬라이더로 위치와 크기를 조정하며, 현재 장면만
바꿀지 같은 화자의 모든 장면에 적용할지도 선택할 수 있습니다.

로컬 자동 저장은 브라우저 복구와 `대사 미리보기`의 즉시 확인에 사용됩니다.
**게임에 즉시 적용** 또는 **전체 빌드**로 저장소와 게임 산출물을 바꾸려면 서버에
아래 환경 변수가 필요합니다.

```powershell
$env:DIALOGUE_BUILD_ENABLED='1'
$env:DIALOGUE_BUILD_TOKEN='로컬에서만_사용할_토큰'
npm run dev:lan
```

**게임에 즉시 적용**은 JSON 검증, 정사 파일과 파생 데이터 갱신, 현재
`public/play`의 런타임 JSON 교체까지만 수행하므로 재컴파일 없이 새로고침으로
반영됩니다. 새 이미지·Flutter 코드까지 묶어야 할 때만 **전체 빌드**를 사용합니다.
실패하면 이전 파일로 되돌립니다. 정적 호스팅된 편집기는 서버 파일을 직접 변경할
수 없습니다.

자세한 사용법은 [DIALOGUE_EDITOR_GUIDE.md](DIALOGUE_EDITOR_GUIDE.md)를 참고하세요.

## 검증과 릴리스 빌드

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

CI도 대사 동기화 결과, 정적 분석, Node 테스트, Flutter 테스트, 릴리스 빌드, `public/play` 산출물 일치를 검사합니다.

## 저장소 구조

| 경로 | 역할 |
| --- | --- |
| `flutter_app/` | Flutter 게임 본체와 정사 대사 데이터 |
| `app/` | Next.js 편집기·테스트 화면 |
| `lib/` | 대사 생성기와 웹 도구 공용 코드 |
| `public/play/` | Flutter Web 생성 산출물 — 직접 수정 금지 |
| `scripts/` | 동기화·검증·빌드 스크립트 |
| `characters/` | 인물별 설정과 대사 기준 |
| `.github/workflows/ci.yml` | 전체 검증 파이프라인 |

## 기준 문서

| 문서 | 내용 |
| --- | --- |
| [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) | 문서 탐색 순서와 정사 우선순위 |
| [DECIMAL_WORLD.md](DECIMAL_WORLD.md) | 최신 세계관과 스토리 정사 |
| [PROJECT_GUIDE.md](PROJECT_GUIDE.md) | 시스템·데이터·UI 전체 구조 |
| [PRODUCT_VISION.md](PRODUCT_VISION.md) | 제품 방향과 플레이 감정 |
| [CONTENT_GUIDE.md](CONTENT_GUIDE.md) | 시대 고증과 콘텐츠 작성 규칙 |
| [ART_STYLE_GUIDE.md](ART_STYLE_GUIDE.md) | 캐릭터·배경·UI 미술 기준 |
| [HANDOFF.md](HANDOFF.md) | 현재 구현 상태와 다음 작업 |
| [DECISIONS.md](DECISIONS.md) | 확정된 기술·기획 결정 |

문서가 충돌하면 **현재 코드와 테스트 → `DECIMAL_WORLD.md` → 분야별 기준 문서 → 보조 문서** 순서로 판단합니다.

## 콘텐츠 원칙

- 실존 기업명, 종목 코드, 실제 로고를 사용하지 않습니다.
- 2000년의 가격·금리·세금·제도 값은 사료 기반 가상값으로 다룹니다.
- 외부 데이터는 원문을 그대로 배포하지 않고 가공된 통계와 추세만 반영합니다.
- 인물의 행동과 관계는 모두 동갑내기 참가자라는 최신 정사를 따릅니다.

데이터 출처와 사용 원칙은 [DATA_SOURCES.md](DATA_SOURCES.md)에 정리되어 있습니다.
