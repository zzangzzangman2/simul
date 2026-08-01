# 생활 맵 전용 카툰 자산

이 폴더는 아파트 생활 허브와 `잼민 라이더` 미니게임의 전용 배경을 보관한다.

## 런타임 공간

생활 허브는 다음 5공간을 순서대로 이동한다.

1. 작은방: CRT 홈 PC와 장부 서류함
2. 거실: 가족·조직 소파와 살림 꾸미기 밥상 장부
3. 부엌: 가족 생활 공간. 일거리·미니게임 진입점 없음
4. 우리 집 앞 복도: 실제 벽걸이 우편함
5. 동네 골목: 실제 은행 출입구와 일거리·미니게임 게시판

핫스폿은 이미지 안에 그려진 물건을 직접 덮어야 하며, 우편함을 거실에 두거나
일거리 게시판을 부엌에 두면 안 된다.

## 배경 목록

| 용도 | 파일 |
| --- | --- |
| 작은방 기본·중간·개선 | `bg_gameplay_bedroom_tier0_2000_portrait_cartoon_v1.png` · `bg_gameplay_bedroom_tier1_2000_portrait_cartoon_v1.png` · `bg_gameplay_bedroom_tier2_2000_portrait_cartoon_v1.png` |
| 거실 기본·중간·개선 | `bg_gameplay_living_room_tier0_2000_portrait_cartoon_v1.png` · `bg_gameplay_living_room_tier1_2000_portrait_cartoon_v1.png` · `bg_gameplay_living_room_tier2_2000_portrait_cartoon_v1.png` |
| 부엌 기본·중간·개선 | `bg_gameplay_kitchen_tier0_2000_portrait_cartoon_v1.png` · `bg_gameplay_kitchen_tier1_2000_portrait_cartoon_v1.png` · `bg_gameplay_kitchen_tier2_2000_portrait_cartoon_v1.png` |
| 집 앞 복도 기본·중간·개선 | `bg_gameplay_corridor_tier0_2000_portrait_cartoon_v1.png` · `bg_gameplay_corridor_tier1_2000_portrait_cartoon_v1.png` · `bg_gameplay_corridor_tier2_2000_portrait_cartoon_v1.png` |
| 동네 날씨·시간 | `bg_gameplay_neighborhood_clear_2000_portrait_cartoon_v1.png` · `bg_gameplay_neighborhood_cloudy_2000_portrait_cartoon_v1.png` · `bg_gameplay_neighborhood_rain_2000_portrait_cartoon_v1.png` · `bg_gameplay_neighborhood_dusk_2000_portrait_cartoon_v1.png` |
| 라이더 행사장·코스 | `bg_minigame_rider_venue_2000_portrait_cartoon_v1.png` · `bg_minigame_rider_course_2000_portrait_cartoon_v1.png` |

모든 배경은 853×1844 세로형 불투명 PNG다.

## 미니게임 소품

투명 96×96 PNG 소품은 `../minigames/`에 둔다.

- `rider_obstacle_cone_pixel_v2.png`
- `rider_obstacle_crate_pixel_v2.png`
- `rider_obstacle_puddle_pixel_v2.png`
- `rider_obstacle_cart_pixel_v2.png`
- `rider_checkpoint_delivery_pixel_v2.png`

## 생활 애니메이션

투명 생활 배우는 `../gameplay_ambient/`에 둔다.

- `ambient_corridor_cat_cartoon_v1.png`
- `ambient_neighborhood_minibus_cartoon_v1.png`
- `ambient_neighborhood_bicycle_cartoon_v1.png`
- `ambient_neighborhood_walkers_cartoon_v1.png`

`apartment_ambient_layer.dart`가 작은방 CRT 불빛·주사선과 먼지, 거실 조명·TV
반사, 부엌 형광등·밥솥 김, 복도 센서등·우편함 알림, 동네 구름·비·물웅덩이·
새와 위 배우들을 합성한다. 레이어는 `IgnorePointer` 아래에서 그려 터치 영역을
가로채지 않는다. 시스템의 애니메이션 줄이기가 켜지면 정지 프레임을 사용한다.
## 생성 화풍과 프롬프트 요약

이 폴더의 현재 파일은 레거시 카툰 화풍으로 제작된 자산이며, 재생성 시에는
`ART_STYLE_GUIDE.md`의 공식 **SIMUL production soft-painted VN anime v1**을 적용한다.
부드러운 페인터리 질감, 자연스러운 시네마틱 광원과 공기 원근을 사용하고
두꺼운 외곽선, 딱딱한 셀 명암, 플라스틱 3D와 사진식 실사는 피한다.
배경 프롬프트는 2000년 재개발 대기 임대아파트와 동네의 가난하지만
살아 있는 생활감, 모바일 세로 화면, 사람·문자·로고 없음, 공간마다 고정된
실제 상호작용 물건을 요구했다. 라이더 소품은 배경과 구분되는 16비트풍 판독성,
단일 오브젝트, 그림자 외 완전 투명 배경을 요구했다.
