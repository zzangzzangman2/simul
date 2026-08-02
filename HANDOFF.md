# 현재 구현 핸드오프

최종 갱신: 2026-08-02

이 문서는 현재 구현 상태만 요약한다. 과거 작업 과정과 후보 이력은 Git에서 확인한다.

## 현재 제품 상태

- Flutter Web 본편과 Vinext 배포·대사 편집 셸이 연결되어 있다.
- 루트 `/`는 `/play/index.html`로 이동하며 LAN 모바일 접속을 지원한다.
- 모바일은 가용 뷰포트를 채우고 데스크톱만 `390×844` 프레임을 사용한다.
- Maplestory 글꼴이 Flutter 테마와 Web 자산에 등록되어 있다.
- 저장은 최대 5슬롯, `GameState.schemaVersion == 24`다.
- 신규 게임 시작일은 `2000-01-02 08:00`, 국가원금과 튜토리얼 실습금은
  `50,000원`이다.

## 프롤로그와 대사

- 대사 정본은 `flutter_app/assets/dialogue/dialogue-editor-override.json`이다.
- 현재 140장면, `appearanceVersion: 13`이다.
- 진행 순서는 청와대 정책실, 미래양성원 개원 기록, 새봄보육원, 미래양성원 정문,
  제6기 강당, 첫날 기숙사, 둘째 날 주식 PC 실습이다.
- 구간 건너뛰기는 청와대·고아원·강당·기숙사 구간을 한 번에 하나씩만 넘기며,
  마지막에는 꺼진 CRT가 있는 튜토리얼 진입 화면에서 멈춘다.
- PC 전원, 주식실습 앱 실행, 운용자·투자장부 이름 확정 뒤 첫 저장과 한빛통신
  매수·가격 변화·매도 튜토리얼이 이어진다.

## 인물과 관계

- 고정 캐릭터 카드: 김서아, 이지안, 최이서, 정아린, 박하은, 한수아, 오지우,
  윤채아, 김학준, 한서윤.
- 카드 초상화를 누르면 나이·MBTI·성격·선호·강점·투자 기준·관계 방식 상세로
  들어간다.
- 여학생 8명 호감도는 1~100, 직접 하루 종료 시 한 명과 교류하거나 혼자 쉰다.
- 제6기 10명의 일일 투자 결과와 7일 무이자 대여·자동 상환이 저장된다.
- 미래톡은 동기 9명, 친구별 하루 3회, 최근 256개 메시지를 저장한다.
- 대사 수정은 `characters/cohort6_girls/`의 인물별 문서를 먼저 읽고 진행한다.

## 이미지 정본

- 공식 화풍: `SIMUL production soft-painted VN anime v1`
- 화풍 앵커: `art_references/simul_production_soft_painted_vn_style_anchor_v1.png`
- 여학생 승인 앵커: `art_references/`의 `*_identity_anchor_*`
- 런타임 포즈: `flutter_app/assets/images/production_soft_painted/<인물>/`
- 후보·아카이브·범용 여자친구·실사 시험 이미지는 정본이 아니며 저장소에서 제거한다.

## 경제 시스템

- 50개 가상기업, 2000~2026 결정론적 가격·사건·기업 생애주기
- 09:00 개장, 14:50 종가 동시호가, 15:00 마감
- 10+10 호가, 주문·정정·취소·미체결·잔고, 장중 속보와 보고서
- 전날 공개 사실만 쓰는 로컬 조간신문
- 전국 32개 상권과 18업종 동네 사업
- 부동산 생성기 v4 신규 매입과 구버전 보유 자산 호환
- 공통 월드시드 경제 사건의 주식·부동산·사업 투영

시장 수치와 호가 불변 조건은 `BALANCE_NOTES.md`, 부동산은
`REAL_ESTATE_SYSTEM.md`가 정본이다.

## 주요 진입점

| 기능 | 파일 |
| --- | --- |
| 앱 시작·저장·화면 전환 | `flutter_app/lib/main.dart` |
| 프롤로그 | `flutter_app/lib/visual_novel_onboarding.dart` |
| 캐릭터 프로필 | `flutter_app/lib/game/character_profile.dart` |
| 캐릭터 카드 UI | `flutter_app/lib/relationship_screens.dart` |
| 주식 화면·튜토리얼 | `flutter_app/lib/stock_market_screen.dart`, `stock_market_tutorial.dart` |
| 핵심 엔진·저장 | `flutter_app/lib/game/game_engine.dart`, `game_state.dart`, `game_persistence.dart` |
| 관계·투자·미래톡 | `relationship_state.dart`, `cohort_investment_state.dart`, `phone_messenger_state.dart` |
| 부동산·사업 | `real_estate_*`, `business_*`, `world_economy.dart` |
| 대사 편집기 | `app/editor/` |

## 다음 작업을 고르는 기준

- 미완성 기능은 `GAMEPLAY_GAPS.md`에서만 고른다.
- 대사는 별도 작업자가 수정 중이므로 이 정리 작업에서 문장을 임의 재작성하지 않는다.
- 캐릭터 이미지를 추가할 때는 기존 8명과 얼굴·실루엣 중복 검사를 먼저 한다.
- 기능을 완료하면 관련 테스트와 정본 문서를 같은 변경에서 갱신한다.

## 검증

```powershell
Push-Location flutter_app
flutter analyze
Get-ChildItem test\*_test.dart | ForEach-Object { flutter test $_.FullName }
Pop-Location
npm run lint
npm test
npm run build:release
```

전체 Flutter 테스트는 메모리 사용량 때문에 파일별 실행한다.
