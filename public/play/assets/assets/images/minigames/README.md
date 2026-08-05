# Minigame assets

## `bg_newspaper_delivery_dawn_seoul_2000_v1.png`

- 생성일: 2026-08-05
- 용도: 새벽 신문배달 미니게임의 세로 9:16 배경
- 런타임: `rider_mini_game.dart`, `weekend_activity.dart`
- 문자·로고·인물 없음. 신문·우편함 판정과 동적 연출은 Flutter 레이어로 합성한다.

## ImageGen 투명 오브젝트

- `rider_newspaper_cyclist_rear_v2.png`: 얼굴이 보이지 않는 신문배달 자전거 탑승자 후면
- `obstacle_puddle_winter_v2.png`: 겨울 도로 물웅덩이
- `obstacle_wood_crate_v2.png`: 빈 나무 상자
- `obstacle_trash_bags_v2.png`: 검정·파랑 쓰레기봉투 세 묶음

네 에셋 모두 정식 v3 화풍 앵커를 렌더링 문법으로만 참조해 2026-08-05 생성했다.
단색 녹색 배경을 soft-matte 크로마 제거한 RGBA이며 캐릭터는 공식 플레이어 외형을
정하지 않는 얼굴 없는 조작 표지다.

최종 ImageGen 프롬프트:

> Create a brand-new polished vertical 9:16 mobile game background for a Korean newspaper-delivery minigame set in Seoul in January 2000 at 6:30 a.m. Viewpoint: elevated third-person chase-camera looking straight down a gently descending narrow residential street, with a wide clear central asphalt route that recedes toward the upper center and leaves readable gameplay space in three invisible lanes. On both sides: authentic late-1990s Seoul brick villas, low walls, steel gates, modest apartment entrances, newspaper slots and small freestanding mailboxes positioned clearly along the roadside at alternating depths; bare winter trees, a little old snow along curbs, warm porch lights, pale blue dawn sky, faint peach sunrise and light morning mist. No people, no rider, no bicycle, no newspapers in motion, no cars blocking the central road, no UI, no text, no logos, no signs, no brands, no lane paint, no arrows, no checkpoints. Art direction: SIMUL polished soft-render visual-novel anime v3 background art, premium Korean mobile game quality, softly painted but crisp environment detail, smooth clean edges, luminous controlled highlights, cool blue-violet shadows balanced by warm window light, strong depth and atmospheric perspective, elegant cinematic color grading, not photorealistic, not 3D, not pixel art, not chibi, no heavy ink outlines. Composition must remain calm and uncluttered under gameplay objects: darkest foreground pavement in the lower quarter, brightest neighborhood depth in the upper half, obvious mailbox targets only at the left and right edges, central roadway kept open.
