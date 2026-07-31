# 대사·장면 편집기 가이드

최종 갱신: 2026-08-01

`/editor`는 리부트 프롤로그의 장면 순서, 화자, 캐릭터 포즈, 지문, 대사와
배경을 한 화면에서 관리하는 제작 도구다. 현행 초안 스키마는
`appearanceVersion: 6`이다.

## 편집 범위

- 왼쪽 장면 목록에서 장면을 검색·선택·재정렬·삭제한다.
- 기존 장면은 장 제목, 날짜, 장소, 화자, 화자별 포즈, 지문, 대사와 배경을
  즉시 수정할 수 있다.
- `＋ 장면 추가`는 현재 장면의 메타데이터를 기본값으로 가져온 작성 창을 연다.
  화자·포즈·배경·지문·대사를 확인한 뒤 선택 장면 바로 다음에 삽입한다.
- 화자를 바꾸면 포즈 목록도 해당 화자에게 등록된 자산만 표시한다. `이야기`는
  내레이션으로 처리하며 캐릭터를 표시하지 않는다.
- 배경은 `app/editor/background-catalog.ts`의 미리보기 카드에서 선택하거나
  `assets/images/...` 직접 경로로 지정한다. 게임 자산 경로만 사용하고
  `/play/assets/` 접두사는 저장 시 정규화한다.

## 저장과 게임 반영

텍스트를 수정하면 브라우저 로컬 초안에 자동 저장된다. 자동저장은 편집 중
복구용이며 Flutter 게임 파일을 바꾸지 않는다.

`저장하고 게임 빌드`를 누르면 다음 작업을 한 번에 수행한다.

1. 장면을 순서대로 정규화한다.
2. `flutter_app/assets/dialogue/dialogue-editor-override.json`을 기록한다.
3. Flutter Web release를 빌드한다.
4. 결과물을 `public/play/`에 동기화한다.

로컬 빌드 API는 저장소가 있는 개발 PC에서만 동작한다. 정적 호스팅에 올라간
`/editor`는 UI 확인용이며 서버 파일을 직접 수정할 수 없다.

## 런타임 규칙

- Flutter는 편집본의 `order`를 기준으로 장면을 재생한다. 현재 기본 66장면에
  고정하지 않고 마지막 장면을 동적으로 종료점으로 사용한다.
- 비정상 초안으로 인한 무한 진행을 막기 위해 최대 240장면까지만 읽는다.
- 추가·삭제·재정렬된 장면과 각 장면의 배경·화자·포즈·지문·대사를 모두
  적용한다.
- 진행률, 다음 대사, 빠른 넘김과 완료 카드는 편집본의 실제 장면 수를 따른다.
- 장면 ID `scene-44`는 제6기 인원 카드의 특수 연출 식별자로 유지한다.
- `scene-54`는 오리엔테이션에서 기숙사로 이동하자는 한서윤의 선언이고,
  `scene-55`~`scene-66`은 중앙 복도·공용 생활실·세면실·첫날 밤으로 이어진다.

## 관련 파일

- 편집 화면: `app/editor/page.tsx`
- 편집 화면 스타일: `app/editor/editor.module.css`
- 인물·포즈 목록: `app/editor/character-catalog.ts`
- 배경 목록: `app/editor/background-catalog.ts`
- 기본 대사: `app/editor/dialogue-data.ts`
- 저장·빌드 API: `app/api/dialogue/build/route.ts`
- Flutter 적용: `flutter_app/lib/visual_novel_onboarding.dart`
- 빌드된 초안: `flutter_app/assets/dialogue/dialogue-editor-override.json`

## 변경 후 검증

```powershell
node --test tests/rendered-html.test.mjs
pnpm run build

Push-Location flutter_app
dart format lib/visual_novel_onboarding.dart test/widget_test.dart
flutter analyze
flutter test test/widget_test.dart
Pop-Location

npm test
npm run lint
npm run build:release
```

27년 월드 생성 테스트는 메모리 경합을 피하도록 Flutter 테스트 파일을 하나씩
실행한다. 배경 필드를 추가하거나 초안 스키마를 올릴 때는 편집기·빌드 API·Flutter
디코더·위젯 테스트를 같은 변경에서 함께 고친다.
