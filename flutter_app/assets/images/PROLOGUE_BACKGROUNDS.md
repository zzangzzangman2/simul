# 프롤로그 상황별 배경

> [!WARNING]
> 아래 비트 표는 기존 가족·투자학원 저장의 레거시 배경 매핑이다. 리부트 신규
> 프롤로그의 배경은 `ORPHANAGE_STORY_REBOOT.md`와 대사 편집본을 따른다.

레거시 프롤로그 배경은 `story.md` §4의 장소 정체성과 `ART_STYLE_GUIDE.md`의 현행 화풍·공통 슬롯 명세를 따른다.
배경에는 인물을 미리 합성하지 않으며 가족과 NPC는 중앙 공통 전신 스프라이트로만 표시한다.

| 비트/상태 | 상황 | 배경 자산 |
|---|---|---|
| 0~4 | 고물 컴퓨터를 작은방에 막 들여온 밤 | `bg_prologue_small_room_arrival_1999_portrait_cartoon_v6.png` |
| 5 · 작은방 목표 | 전원선·드라이버·부품 구분 | `bg_prologue_small_room_repair_1999_portrait_cartoon_v6.png` |
| 5 · 키보드 목표 | 거실에서 누나와 키보드 협상 | `bg_prologue_repair_living_room_keyboard_1999_portrait_cartoon_v6.png` |
| 5 · 모뎀 목표 | 부엌 유선전화와 모뎀 연결 | `bg_prologue_repair_kitchen_modem_1999_portrait_cartoon_v6.png` |
| 6~7 | 컴퓨터 부팅 성공 | `bg_prologue_small_room_repair_1999_portrait_cartoon_v6.png` |
| 8~10 | 거실 TV의 연말 드라마 | `bg_prologue_living_room_tv_1999_portrait_cartoon_v6.png` |
| 11 | 컴퓨터 밑 신문에서 광고 발견 | `bg_prologue_small_room_newspaper_1999_portrait_cartoon_v6.png` |
| 12~13 | 광고를 들고 거실에서 학원비 확인 | `bg_prologue_living_room_tv_1999_portrait_cartoon_v6.png` |
| 14~21 | 설날 외할아버지의 만 원짜리 질문 | `bg_prologue_living_room_new_year_2000_portrait_cartoon_v6.png` |
| 22~25 | 오래된 상가 3층 무료 공개수업 | `bg_prologue_public_class_2000_portrait_cartoon_v6.png` |
| 26~30 | 수업 뒤 거실 가족 등록회의 | `bg_prologue_living_room_family_registration_2000_portrait_cartoon_v6.png` |
| 31 | 첫 정식 등교 전 가방과 장부 준비 | `bg_prologue_small_room_departure_2000_portrait_cartoon_v6.png` |
| 32~33 | 투자학교 정문 도착 | `bg_prologue_academy_exterior_2000_portrait_cartoon_v6.png` |
| 34 | 접수대 등록 | `bg_prologue_academy_reception_2000_portrait_cartoon_v6.png` |
| 35~39 | 정식 입문반 첫 인사 | `bg_prologue_academy_classroom_welcome_2000_portrait_cartoon_v6.png` |
| 40~45 | 가격과 주문 방식 설명 | `bg_prologue_academy_classroom_lesson_2000_portrait_cartoon_v6.png` |
| 46~50 | CRT를 이용한 주문 실습 | `bg_prologue_academy_classroom_order_practice_2000_portrait_cartoon_v6.png` |

## 고정 제작·런타임 규칙

- 장소 또는 행동 목적이 바뀌면 배경도 바꾼다.
- 배경 안에는 가족, 강사, 접수원 등 대화 인물을 그리지 않는다.
- 모든 인물은 공통 부모의 `Positioned.fill(bottom: 0) → LayoutBuilder → Align.bottomCenter → SizedBox(aspectRatio: 2/3, height: maxHeight×0.9)` 중앙 슬롯을 공유한다.
- 중앙은 전신 캐릭터를 위해 비우고 화면 아래 22%는 대사창 뒤에서 복잡해지지 않게 구성한다.
- 공식 **cinematic soft-painted anime realism**으로 통일한다. 부드러운 페인터리 질감, 자연스러운 시네마틱 광원, 공기 원근과 절제된 애니메이션 디테일을 사용하며 두꺼운 외곽선, 딱딱한 셀 명암, 플라스틱 3D, 사진식 실사, 건축 시각화풍은 사용하지 않는다.
- CRT, 유선전화, 종이 장부, 형광등 등 당시 소품을 사용하고 현대 스마트 기기는 배제한다.
- 모든 프롤로그 배경은 불투명 `853×1844` PNG로 정규화한다.
