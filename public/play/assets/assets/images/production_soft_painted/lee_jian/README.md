# 이지안 현행 v2 표정·동작 세트와 v3 전환

- 얼굴 앵커: `art_references/lee_jian_face_identity_anchor_v2.png`
- 전신 앵커: `art_references/lee_jian_identity_anchor_v2.png`
- 목표 화풍: `SIMUL polished soft-render VN anime v3`
- 규격: 1024×1536 RGBA 투명 전신, 배경·그림자 없음

현행 9종은 새 v3 승인 전까지 런타임이자 얼굴·헤어·체형·의상·포즈 보존 참조다.
이지안은 여자 동기 8명에 포함되므로 외형을 재설계하지 않고 렌더링 마감만 바꾼다.
텍스트 설명과 보이는 승인 앵커가 충돌하면 이미지를 임의 수정하지 않고 충돌을 먼저 확인한다.

## 런타임 파일

1. `01_neutral_screwdriver_v2.png` — 드라이버를 내린 기본 자세
2. `02_playful_wink_v2.png` — 사용자 승인 참고 표정의 부드러운 윙크
3. `03_focused_repair_v2.png` — 고개를 숙여 나사와 공구를 확인하는 집중
4. `04_surprised_fault_v2.png` — 고장음을 듣고 상체가 반동하는 놀람
5. `05_worried_diagnosis_v2.png` — 공구를 양손 가까이 들고 원인을 고민하는 걱정
6. `06_annoyed_interrupted_v2.png` — 고개를 옆으로 돌리고 한 손을 허리에 둔 불만
7. `07_apologetic_boundary_v2.png` — 고개를 숙이고 책임을 인정하는 사과
8. `08_determined_repair_v2.png` — 앞으로 체중을 옮겨 수리를 준비하는 결심
9. `09_explaining_mechanism_v2.png` — 드라이버와 열린 손으로 작동 원리를 설명

## 불변값

짧고 둥근 얼굴, 넓은 볼, 매우 짧은 뭉툭한 턱, 순한 금갈색 눈,
밀크티 베이지 금발 장발, 두툼한 U자 앞머리, 넓은 흰 천 헤어밴드와 뒤 리본,
중간 키·완만한 어깨·약간 긴 팔다리·건강한 슬림 체형을 유지한다.
센터 지급 현장복은 배를 완전히 가리는 흰 반소매 셔츠, 빨간 체크 넥타이와 V자 허리단
체크 주름치마, 맨발 코랄핑크 통풍 클로그다. 양말은 사용하지 않는다.

검은 장발·높은 번 v1은 폐기되었다. 런타임과 편집기는 이 문서의 v2 9종만
사용한다.
