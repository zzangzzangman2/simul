# Pink Bun Girl Identity Set v1

최종 갱신: 2026-08-05

## 상태

- 사용자가 김서아의 새 공식 외형으로 지정한 캐릭터 아이덴티티·표정 참고 세트다.
- 2026-08-05 김서아의 정체성 앵커와 Flutter 런타임 9종으로 연결했다.
- 구형 김서아 얼굴·헤어·현장복·로비 동작 프레임은 새 세트와 혼용하지 않는다.
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

## 런타임 전환 결과

- 연결 대상: 김서아 (`kim_seoa`)
- 정체성 앵커: `art_references/kim_seoa_identity_anchor_v2.png`
- 런타임: `flutter_app/assets/images/production_soft_painted/kim_seoa/` 9종
- 투명 배경, 가장자리 알파, `1024x1536` 캔버스와 발바닥 기준선을 정규화한다.
- 캐릭터 정본 문서와 테스트를 갱신하고 `public/play/`를 재빌드한다.
