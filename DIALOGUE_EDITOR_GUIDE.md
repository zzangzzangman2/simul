# 대사·장면 편집기 가이드

최종 갱신: 2026-08-03

`/editor`는 리부트 프롤로그의 장면 순서, 화자, 캐릭터 포즈, 지문, 대사와
배경을 한 화면에서 관리하는 제작 도구다. 현행 정식 스키마는
`contentVersion: 3`, `appearanceVersion: 17`이며 정규 편집본은 292장면이다.

## 편집 범위

- 왼쪽 장면 목록에서 장면을 검색·선택·재정렬·삭제한다.
- 기존 장면은 장 제목, 날짜, 장소, 화자, 화자별 포즈, 지문, 대사와 배경을
  즉시 수정할 수 있다.
- `＋ 장면 추가`는 현재 장면의 메타데이터를 기본값으로 가져온 작성 창을 연다.
  화자·포즈·배경·지문·대사를 확인한 뒤 선택 장면 바로 다음에 삽입한다.
- 화자를 바꾸면 포즈 목록도 해당 화자에게 등록된 자산만 표시한다. `이야기`는
  내레이션으로 처리하며 캐릭터를 표시하지 않는다.
- 캐릭터는 오른쪽 무대에서 직접 드래그해 옮기고, 마우스 휠이나 `+`·`-`로
  확대·축소한다. 방향키는 미세 이동, Shift+방향키는 큰 이동이다.
  드래그 판정과 선택 테두리는 인물 몸 중심으로 제한해 상단 장면 정보와 겹치지 않는다.
- `Ctrl/⌘+Z`는 직전 수정 전으로 돌아가고, `Ctrl/⌘+Shift+Z` 또는 `Ctrl/⌘+Y`는
  취소한 수정을 다시 적용한다. 짧은 시간에 이어서 입력한 대사는 글자 하나씩이 아니라
  한 번의 입력 묶음으로 되돌린다.
- 위치 X/Y와 크기 슬라이더, `전신`, `기본`, `상반신` 프리셋을 함께 제공한다.
  전신 프리셋은 캐릭터를 위로 올리고 축소해 기존에 잘리던 다리와 신발을 보인다.
- 배치 범위는 `이 장면만`과 `같은 화자 전체` 중에서 고른다. 전체 범위에서는
  같은 화자의 모든 장면에 위치와 크기가 동시에 적용된다.
- 배경은 `app/editor/background-catalog.ts`의 미리보기 카드에서 선택하거나
  `assets/images/...` 직접 경로로 지정한다. 게임 자산 경로만 사용하고
  `/play/assets/` 접두사는 저장 시 정규화한다.

## 저장과 게임 반영

텍스트를 수정하면 브라우저 로컬 초안에 자동 저장된다. 자동저장은 편집 중
복구용이며 `대사 미리보기` 화면에서는 별도 빌드 없이 최신 초안을 확인할 수 있다.

`게임에 즉시 적용`을 누르면 다음 작업을 수행한다.

1. 장면 수·필드 형식·중복 ID·6,000자 제한·실제 에셋 경로를 검증한다.
2. 단일 정본 `flutter_app/assets/dialogue/dialogue-editor-override.json`을 기록한다.
3. 정본에서 `app/editor/dialogue-data.ts`와 Flutter Dart 데이터를 생성한다.
4. 현재 `public/play`의 런타임 대사 JSON을 교체한다.

이 경로는 Flutter를 다시 컴파일하지 않으므로 게임 새로고침만으로 적용된다.
새 이미지나 Flutter 코드까지 산출물에 포함해야 할 때는 `전체 빌드`를 누른다.
전체 빌드는 위 작업 후 Flutter Web release를 만들고 완성된 디렉터리만
`public/play/`와 교체한다. 중간에 실패하면 JSON·TypeScript·Dart와 런타임 파일을
이전 내용으로 복원하며,
긴 대사를 몰래 자르거나 일부 파일만 반영하지 않는다.

로컬 빌드 API는 저장소가 있는 개발 PC에서만 동작한다. 기본값은 비활성화며,
시작 전 `DIALOGUE_BUILD_ENABLED=1`과 충분히 긴 `DIALOGUE_BUILD_TOKEN`을 모두
설정해야 한다. POST 빌드는 localhost와 LAN 접속을 구분하지 않고 편집기에 입력한
동일 토큰을 항상 검증한다. 정적 호스팅에 올라간 `/editor`는 UI 확인용이며 서버
파일을 직접 수정할 수 없다.

PowerShell 로컬 실행 예:

```powershell
$env:DIALOGUE_BUILD_ENABLED = '1'
$env:DIALOGUE_BUILD_TOKEN = '<충분히 긴 임의 토큰>'
npm run dev
```

## 런타임 규칙

- Flutter는 편집본의 `order`를 기준으로 장면을 재생한다. 현재 정규본은
  292장면이며 마지막 장면을 동적으로 종료점으로 사용한다.
- 일반 게임은 번들 정본만 읽는다. 브라우저 자동저장 초안은 편집기의
  `대사 미리보기` 링크가 여는 `dialoguePreview=1` 실행에서만 번들 위에 적용한다.
- 비정상 초안으로 인한 무한 진행을 막기 위해 320장면을 넘는 입력은 저장 전에
  명시적으로 거부한다.
- 추가·삭제·재정렬된 장면과 각 장면의 배경·화자·포즈·지문·대사를 모두
  적용한다. 캐릭터 위치 X/Y와 크기는 누락 시 `0/0/1`로 호환하며 범위를 벗어난
  값은 거부한다.
- 진행률, 다음 대사, 빠른 넘김과 완료 카드는 편집본의 실제 장면 수를 따른다.
- 장면 ID `decimal-final-ten-roster`는 최종 열 명 카드의 특수 연출 식별자다.
- `decimal-001`부터 `decimal-292`는 국정원 데시멀 재가동, 봉인된 실패 기록, 세 선발 시험, 강남 도착,
  열 명 자기소개, 침상·사물함·개인 물건·경계 합의·첫 갈등·첫날 밤,
  50,000원 장부와 트레이딩 플로어 순서로 이어진다.
- 마지막 장면은 재정렬 뒤에도 주식실습 PC 진입을 준비하는 정규 종료점이다.

## 관련 파일

- 편집 화면: `app/editor/page.tsx`
- 편집 화면 스타일: `app/editor/editor.module.css`
- 인물·포즈 목록: `app/editor/character-catalog.ts`
- 배경 목록: `app/editor/background-catalog.ts`
- 단일 대사 정본: `flutter_app/assets/dialogue/dialogue-editor-override.json`
- 편집기 파생 데이터: `app/editor/dialogue-data.ts`
- 저장·빌드 API: `app/api/dialogue/build/route.ts`
- Flutter 적용: `flutter_app/lib/visual_novel_onboarding.dart`

## 변경 후 검증

```powershell
node --test tests/rendered-html.test.mjs
npm run build

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
