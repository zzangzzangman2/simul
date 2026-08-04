# Pink Bun Girl Identity Set v1

최종 갱신: 2026-08-05

## 상태

- 사용자가 보존을 요청한 공식 캐릭터 아이덴티티·표정 참고 세트다.
- 아직 연결할 NPC가 정해지지 않았으므로 Flutter 런타임과 캐릭터 문서에서는 참조하지 않는다.
- NPC가 정해지면 이 세트를 기준으로 투명 배경 런타임 자산을 만들고 해당 인물의 정본 문서와 테스트를 함께 갱신한다.
- 사용자 제공 원본 참고 이미지는 저장소에 포함하지 않고, 파생된 최종 9장만 추적한다.

## 비율 기준

- 9장 모두 기존 SIMUL 전신 NPC와 어울리도록 머리·얼굴 크기를 줄인 최종 비율을 사용한다.
- `01_neutral_front_v3.png`을 세트의 체형·머리 비율 기준으로 삼는다.
- 표정과 동작이 달라도 얼굴 크기, 몸 비율, 의상, 쌍만두 머리와 장식은 동일 인물로 유지한다.

## 구성

1. `01_neutral_front_v3.png` — 정면 기본표정
2. `02_cheerful_wave_head_right_v3.png` — 화면 왼쪽 3/4 손인사
3. `03_bright_laugh_head_left_up_v3.png` — 화면 오른쪽 3/4 밝은 웃음
4. `04_surprised_chin_up_v3.png` — 정면에서 턱을 든 놀람
5. `05_worried_head_right_down_v3.png` — 화면 왼쪽 아래를 보는 걱정
6. `06_sulky_head_left_sideeye_v3.png` — 화면 오른쪽을 보는 뾰루퉁
7. `07_apologetic_head_left_down_v3.png` — 고개를 숙인 미안함
8. `08_determined_chin_up_v3.png` — 정면에서 턱을 든 결의
9. `09_explaining_head_right_v3.png` — 화면 왼쪽 3/4 설명 동작

## 런타임 전환 시 필수 작업

- 연결 대상 NPC와 파일명 규칙 확정
- 투명 배경 및 가장자리 알파 검수
- `1024x1536` 런타임 캔버스와 발바닥 기준선 정규화
- 캐릭터 정본 문서, Flutter 자산, 테스트 및 `public/play/` 재빌드
