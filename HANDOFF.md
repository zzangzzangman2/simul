# 현재 구현 핸드오프

## 기준

- 제품명: `10대부터 건물주`
- 세계관 정본: `DECIMAL_WORLD.md`
- 대사 정본: `flutter_app/assets/dialogue/dialogue-editor-override.json`
- 현재 대사 버전: content 3 / appearance 17 / 292장면

## 프롤로그

8개 장으로 연결돼 있다.

1. 1999년 국정원의 데시멀 재가동
2. 봉인된 정답형 설계·1997년 외환위기 실패 기록
3. 1999년 숨은 규칙 시험
4. 불공정 배분 게임
5. 결핍·욕망·종료권 시험
6. 1999년 12월 강남 센터 도착과 열 명 자기소개
7. 침상·사물함·개인 물건·생활 경계·첫 갈등·밥솥 사건·첫날 밤
8. 2000년 1월 3일 50,000원 장부와 트레이딩 플로어, 주식실습 PC

플레이어·김학준과 여자 동기 8명 모두 최소 5회 이상 말한다. 한서윤은 교사가 아닌
운영관이며 국정원장·경제안보국장·권익감사관·선발관·시설관리관 등 엑스트라도
고유 얼굴과 역할, 말투가 있다.

## 이미지

- 공식 목표 화풍은 `SIMUL luminous soft-painted VN anime v2`이며,
  `art_references/simul_luminous_soft_painted_vn_style_anchor_v2.png`를 새 채팅의
  최우선 화풍 참조로 사용한다. 박하은 v2와 한수아 v3는 통과했지만 나머지
  런타임 자산의 화풍 단일화는 아직 완료되지 않았다.
- 박하은은 `park_haeun_face_identity_anchor_v2.png`와
  `park_haeun_identity_anchor_v2.png`, 런타임 v2 9종으로 연결돼 있다.
- 한수아는 `han_sua_identity_anchor_v3.png` 전신을 1차, `han_sua_face_identity_anchor_v3.png`
  얼굴 크롭을 2차 정체성 기준으로 사용하며 `production_soft_painted/han_sua/`의 런타임
  v3 9종으로 연결돼 있다. 얼굴 크롭의 `1/2` UI·손·파란 천·레이스는 복제하지 않는다.
- 현재 세로 배경은 `flutter_app/assets/images/cinematic_soft_painted/decimal/`과
  `flutter_app/assets/images/cinematic_soft_painted/decimal_nis_1999/`에 연결돼 있다.
- IMF 실패, 숨은 규칙 시험, 불공정 게임, 욕망 시험, 강남 외관, 보안 입구,
  생활 라운지, 수면동, 트레이딩 플로어, 기록 보관실, 기기 정비실을 포함한다.
- 2026-08-03 재검수에서 해당 13개 배경은 9:16 구도는 맞지만 사진·3D형 질감이
  강해 공식 카툰 소프트 페인터리 화풍 재제작 대상으로 판정됐다.
- 여자 동기 8명의 정체성 앵커는 유지한다. 런타임은 박하은 v2·한수아 v3만
  화풍 통과이며, 나머지는 `ART_STYLE_AUDIT.md`의 보정·재제작 판정을 따른다.

## 런타임 연결

- 신규 저장은 `StoryState.newDecimalPlayer`로 시작한다.
- 기본 이름은 없으며 프롤로그 첫 화면에서 사용자가 확정한 이름을 대사와 저장에 쓴다.
- 프롤로그 완료 후 PC 전원 → 데시멀 주식실습 앱 → 선택형 투자노트 → 모의 주문
  리허설 → 정식 50,000원 자유 플레이로 이어진다.
- 생활 허브의 라운지·트레이딩 플로어·기기 정비실·기록 보관실은 새 배경을 쓴다.

## 대사·장면 편집기

- `/editor`는 대사뿐 아니라 장면 메타데이터, 배경, 캐릭터 포즈·위치·크기를
  편집한다. 캐릭터는 무대에서 직접 드래그하고 휠·슬라이더·프리셋으로 조정한다.
  드래그 핸들과 파란 테두리는 몸 중심의 작은 영역만 사용해 상단 메뉴를 가리지 않는다.
- 캐릭터 배치는 현재 장면만 또는 같은 화자의 모든 장면에 적용할 수 있다.
- `Ctrl/⌘+Z` 실행 취소와 `Ctrl/⌘+Shift+Z`, `Ctrl/⌘+Y` 다시 실행을 지원하며,
  연속 타이핑과 위치 조정은 짧은 단위로 묶어 기록한다.
- 자동저장 초안은 `dialoguePreview=1`에서 즉시 확인한다. `게임에 즉시 적용`은
  재컴파일 없이 정본·파생 데이터·현재 Web 런타임 JSON을 갱신하며, 새 에셋이나
  코드 반영에는 `전체 빌드`를 사용한다.

## 호환

옛 세계관 파일명과 `academy`, `orientation`, `cohort`, `seed` 같은 내부 식별자 일부는
구형 저장·테스트 호환 때문에 남아 있다. 사용자 화면과 새 데이터에는 옛 설정을
노출하지 않는다. 플레이어·동기 연령과 장기 성장은 `PROTAGONIST_AGE_LINE.md`를
따르며, 폐기된 미래양성원 원고는 정본·호환 문서로 보존하지 않는다.

## 검증

```powershell
npm run dialogue:sync
npm run lint
npm test
npm run build:release
```

Flutter는 analyze와 `flutter_app/test/*.dart` 파일별 테스트를 실행한다. 대사 편집기
빌드는 `DIALOGUE_BUILD_ENABLED=1`과 `DIALOGUE_BUILD_TOKEN`이 모두 있어야 한다.

## 문서 진입점

- 루트 `README.md`는 현재 데시멀 정사, 8장 292장면, 구현 시스템, npm 실행법,
  대사 편집기와 CI 검증 흐름을 한 페이지에서 안내한다.

## 다음 한 가지 작업

- 투명 여백이 서로 다른 전체 포즈에서 몸 중심 드래그 핸들의 감도를 실기기로 최종 점검한다.
