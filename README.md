# 10대부터 건물주

1981년 국가 미래양성계획에서 시작해 2000년 미래양성원 제6기 교육생의 투자와
공동생활을 따라가는 모바일 세로형 투자·생활 시뮬레이션이다. 플레이어는 14살
`SEED 01 · 첫빛`으로 입소해 국가원금 50,000원의 첫 주문 실습을 배우고, 2026년까지
가상기업·부동산·동네 사업과 인간관계를 함께 성장시킨다.

## 현재 기준

- Flutter Web 게임 + Vinext 대사 편집기·배포 셸
- 모바일 실제 뷰포트 전체 화면, 데스크톱 `390×844` 프리뷰
- 5개 저장 슬롯, `GameState` 스키마 v24
- 프롤로그 장면·PC·이름 입력 자동 체크포인트와 이어하기
- 140장면 프롤로그, 대사 `appearanceVersion: 13`
- 50개 고정 가상기업과 월드시드 기반 결정론적 시장
- 제6기 여학생 8명 호감도, 10명 일일 투자 결과, 9명 미래톡
- 부동산·동네 사업·별빛 상점·미니게임
- 공식 캐릭터 화풍 `SIMUL production soft-painted VN anime v1`

## 문서 읽기

새 작업은 [문서 기준표](./DOCUMENTATION_INDEX.md)와 [작업 규칙](./AGENTS.md)을
먼저 읽는다. 구현 구조는 [프로젝트 가이드](./PROJECT_GUIDE.md), 현재 상태는
[핸드오프](./HANDOFF.md), 세계관은 [제6기 리부트 설정](./ORPHANAGE_STORY_REBOOT.md)이
정본이다.

## 개발 실행

```powershell
npm install
npm run dev:lan
```

같은 Wi-Fi의 휴대폰에서 `http://<PC 내부 IP>:8000`으로 접속한다. 루트는 자동으로
`/play/index.html`로 이동한다. 대사 편집기는 `/editor`, 주식 전용 독립 테스트는
`/play/stock-test.html`이다.

Flutter 앱만 실행하려면 다음을 사용한다.

```powershell
Push-Location flutter_app
flutter pub get
flutter run -d chrome
Pop-Location
```

## 검증과 릴리스 빌드

```powershell
Push-Location flutter_app
flutter analyze
Get-ChildItem test\*_test.dart | ForEach-Object { flutter test $_.FullName }
Pop-Location
npm run lint
npm test
npm run build:release
```

`public/play/`는 빌드 결과다. 직접 수정하지 않고 Flutter 소스·대사·자산을 고친 뒤
`npm run build:release`로 다시 만든다.

## 핵심 경로

| 경로 | 역할 |
| --- | --- |
| `flutter_app/lib/` | Flutter 화면과 게임 로직 |
| `flutter_app/lib/game/` | 저장·시장·관계·사업·부동산 엔진 |
| `flutter_app/assets/dialogue/dialogue-editor-override.json` | 140장면 대사 정본 |
| `flutter_app/assets/images/` | 런타임 이미지 자산 |
| `art_references/` | 승인된 화풍·인물 정체성 앵커 |
| `app/editor/` | 대사 편집기 |
| `scripts/` | 대사 동기화·Flutter Web 빌드 |
| `tests/`, `flutter_app/test/` | Web·Flutter 회귀 테스트 |
| `public/play/` | Flutter Web 릴리스 산출물 |

후보 이미지, 폐기본, 실사 시험본, 날짜별 작업 일지는 현재 저장소 정본에 두지
않는다. 과거 상태가 필요하면 Git 이력을 확인한다.
