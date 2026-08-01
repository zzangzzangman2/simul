# 문서 기준표

최종 갱신: 2026-08-01

이 저장소의 Markdown은 현행 명세, 구현 현황, 제작 가이드와 과거 감사 기록을
함께 보관한다. 충돌할 때는 아래 순서로 판단한다.

1. 현재 코드와 테스트
2. `AGENTS.md`의 필수 규칙
3. `DECISIONS.md`의 채택 결정
4. `PROJECT_GUIDE.md`, `HANDOFF.md`, 분야별 현행 가이드
5. 날짜가 붙은 작업 기록·감사·레거시 문서

## 현행 기준 문서

| 문서 | 역할 |
| --- | --- |
| `AGENTS.md` | 저장소 전체에서 반드시 지킬 현재 규칙 |
| `README.md` | 제품 개요와 실행·검증 진입점 |
| `PROJECT_GUIDE.md` | 구현 구조, 저장, 배포, 검증의 상세 기준 |
| `HANDOFF.md` | 가장 최근 구현 상태와 다음 작업 |
| `DECISIONS.md` | 현재 채택된 결정만 기록 |
| `DO_NOTS.md` | 반복하면 안 되는 구현·문서 패턴 |
| `GAMEPLAY_GAPS.md` | 아직 연결되지 않은 기능 |
| `ORPHANAGE_STORY_REBOOT.md` | 미래양성원 제6기 리부트 설정 |
| `characters/cohort6_girls/README.md` | 제6기 여학생 8명 MBTI 배정과 인물별 대사·갈등·투자 성향 문서 인덱스 |
| `PROTAGONIST_AGE_LINE.md` | 14~19살과 SEED 01~06 성장선 |
| `RELATIONSHIP_SYSTEM.md` | 여학생 8명 호감도 1~100, 하루 종료 선택과 데이트 규칙 |
| `COHORT_DAILY_INVESTMENT.md` | 제6기 10명 일일 투자 결과표, 하루 1회 대여와 자동 상환 규칙 |
| `PHONE_MESSENGER_SYSTEM.md` | 미래톡 휴대폰 UI, 제6기 9명 자유 입력 대화와 MBTI 답장 규칙 |
| `DIALOGUE_EDITOR_GUIDE.md` | 대사·장면·배경 편집과 빌드 규칙 |
| `FIRST_DAY_DORMITORY.md` | 첫날 남녀 공용 기숙사와 둘째 날 PC 주식 수업 입실 장면 |
| `ART_STYLE_GUIDE.md` | `SIMUL production soft-painted VN anime v1` 제작 규칙 |
| `IMAGE_GENERATION_STYLE_PROMPT.md` | 모든 채팅에서 사용하는 공식 캐릭터 화풍 앵커·복사용 생성 프롬프트 |
| `ART_STYLE_AUDIT.md` | 런타임 자산 승인·보류·폐기 기록 |
| `CONTENT_GUIDE.md` | 가상기업·사건·업종 문법 |
| `DATA_SOURCES.md` | 출처·라이선스·현실 자료 경계 |
| `BALANCE_NOTES.md` | 현행 경제·시장 수치와 레거시 시작값 경계 |
| `PRODUCT_VISION.md` | 제품의 장기 경험과 리부트 방향 |
| `PROTAGONIST_POSE_LIBRARY.md` | 주인공 SEED 01 정식 교복 24종 매핑 |

## 현황·검증 기록

| 문서 | 역할 |
| --- | --- |
| `WORK_LOG.md` | 날짜별 완료 내용과 검증 명령 |
| `CHARACTER_REGENERATION_RESULT.md` | 리부트 인물 후보와 현재 승인본 연결 상태 |
| `PROLOGUE_DIALOGUE_FULL_AUDIT.md` | 과거 가족 프롤로그 감사와 반영 이력 |
| `REAL_ESTATE_SYSTEM.md` | 부동산 시스템 상세 참고 |
| `SPENDING_CONTENT_PROPOSAL.md` | 자산 지출 콘텐츠 제안·구현 대조 |
| `STOCK_MARKET_REVIEW.md` | 주식시장 과거 검토와 회귀 참고 |
| `CHARACTER_REGENERATION_PLAN.md` | 현행 화풍으로 재생성할 인물·수량 계획 |
| `flutter_app/README.md` | Flutter 실행·검증과 핵심 파일 |
| `flutter_app/assets/images/cinematic_soft_painted/README.md` | 현행 cinematic 런타임 자산군 |
| `flutter_app/assets/images/cinematic_soft_painted/dormitory_2000/README.md` | 제6기 기숙사 배경 4종과 생성·검수 기준 |
| `flutter_app/assets/images/cinematic_soft_painted/README.md` | 카툰·소프트 페인터리 인물·배경 자산 기준 |
| `flutter_app/assets/images/historical_prologue/README.md` | 역사 프롤로그 자산별 제작·교체 이력 |
| `flutter_app/assets/images/gameplay_map/README.md` | 장소·맵 자산 메모 |
| `flutter_app/assets/images/real_estate/README.md` | 부동산 배경 자산 메모 |
| `flutter_app/assets/images/주식선생님/README.md` | 한서윤 정체성·포즈·공통 슬롯 |
| `flutter_app/assets/images/REAL_ESTATE_REALTOR_README.md` | 서하늘 정체성·포즈 규격 |
| `flutter_app/assets/images/GIRLFRIEND_README.md` | 미연결 여자친구 정체성·재생성 조건 |

## 레거시·보관 문서

- `story.md`, `PROLOGUE_STORY_REVIEW.md`, `PROLOGUE_DIALOGUE_FULL_AUDIT.md`의
  2026-07-30 이전 가족·투자학원 서술은 기존 저장 호환과 제작 이력이다.
- `PROLOGUE_BACKGROUNDS.md`, `PROLOGUE_FAMILY_PORTRAITS.md`,
  `여자1/README.md`는 레거시 자산 매핑이며 신규 리부트의 런타임 명세가 아니다.
- `ORPHANAGE_OPENING_ARC.md`, `ORPHANAGE_WEBNOVEL_PROLOGUE.md`는 서사 원고,
  `PROTAGONIST_AGE_LINE.md`는 성장선 기준이다. 원고의 묘사가 런타임 연결 상태를
  의미하지는 않는다.
- `art_references/simul_canonical_art_style_v1.png`, `npc_canonical_style_teal_v1.png`
  및 문서 속 `고밀도 2D 카툰`·하드 셀 채색 설명은 구형 자산 정체성·의상·포즈
  참고일 뿐 신규 화풍 기준이 아니다.
- 날짜가 적힌 감사 문서의 자산 버전은 당시 결과를 설명할 수 있다. 현재 런타임
  경로는 `ART_STYLE_AUDIT.md`, `ART_STYLE_GUIDE.md`, 코드와
  `flutter_app/assets/dialogue/dialogue-editor-override.json`을 우선한다.

과거 기록을 새 기능의 명세로 다시 복사하지 않는다. 현행 결정이 바뀌면 코드와
테스트, `AGENTS.md`, `DECISIONS.md`, 관련 분야 가이드와 `HANDOFF.md`를 같은
변경에서 갱신한다.
