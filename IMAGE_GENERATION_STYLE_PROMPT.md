# SIMUL 캐릭터 이미지 생성 공식 프롬프트

> [!CAUTION]
> 이 문서는 모든 신규·재생성 캐릭터에 적용하는 최상위 화풍 명세다.
> 새 채팅이나 새 에이전트도 이미지 생성 전에 반드시 이 문서와
> `art_references/simul_production_soft_painted_vn_style_anchor_v1.png`를 직접 연다.

## 1. 공식 화풍

- 공식명: **SIMUL production soft-painted VN anime v1**
- 한국어명: **대량생산형 고품질 소프트 페인터리 비주얼노벨 애니 v1**
- 단일 최상위 이미지 기준:
  `art_references/simul_production_soft_painted_vn_style_anchor_v1.png`
- 공식 앵커의 인물은 수아다. 다른 캐릭터는 **렌더링 문법과 여자 8명 공통 교복·맨발 클로그 규격**을 따르되 수아의 얼굴·머리·체형은 복제하지 않는다.

## 2. 반드시 고정할 렌더링 문법

- 전체는 고급 2D 한국 모바일 비주얼노벨 캐릭터 일러스트다.
- 검은 굵은 외곽선이 아니라 피부·머리·의상색에 맞춘 깨끗한 중간 두께 유색선을 쓴다.
- 얼굴과 눈에 가장 높은 디테일을 배정한다. 홍채는 맑은 다층 구조, 눈꺼풀과 속눈썹은 선명하게, 코와 입의 위치는 모든 포즈에서 고정한다.
- 피부는 `밝은 기본색 + 부드러운 그림자 2단계 + 절제된 홍조 1회`만 사용한다. 사진식 모공, 복잡한 에어브러시, 과도한 광택은 금지한다.
- 머리카락은 `강한 외곽 실루엣 + 주요 머리 묶음 5~7개 + 그림자 덩어리 1개 + 정돈된 하이라이트 띠 1개`로 만든다. 수백 개의 잔머리와 가닥 묘사는 금지한다.
- 옷은 정확한 재단과 실루엣을 우선하고 주름은 한 단계 그림자로 정리한다.
- 체크무늬·패턴은 포즈마다 다시 만들기 쉬운 큰 반복 격자로 단순화하고, 캐릭터 안에서는 색·간격·방향을 고정한다.
- 고급스러움은 과도한 질감이 아니라 정확한 얼굴, 안정적인 인체, 자신 있는 선, 균형 잡힌 색, 깨끗한 가장자리에서 만든다.
- 실사, 반실사 사진 채색, 3D, 치비, 굵은 검은 선, 흐린 페인터리 번짐, 플라스틱 피부, 하드 셀 명암은 금지한다.

## 3. 모든 채팅에서 지킬 입력 순서

1. `art_references/simul_production_soft_painted_vn_style_anchor_v1.png`를 **Image 1: 공식 화풍 참조**로 직접 연다.
2. 해당 인물의 승인 기본 전신을 **Image 2: 정체성 참조**로 직접 연다.
3. 의상·신발·소품 참고가 필요할 때만 Image 3 이후에 추가한다.
4. 프롬프트에 `Image 1의 렌더링 문법만 따르고 수아 정체성은 복제하지 않는다`를 적는다.
5. 표정·동작 확장에서는 얼굴 골격·눈 크기와 간격·코·입·헤어라인·체형·의상을 불변값으로 다시 적는다.

## 4. 캐릭터별 독립 정체성

- 신규 인물마다 얼굴 골격, 이마와 헤어라인, 눈의 형태·크기·간격·각도, 눈썹, 코, 입술, 인중, 턱선, 볼의 볼륨을 별도로 설계한다.
- 데시멀 여자 동기 8명은 어떠한 경우에도 같거나 비슷한 얼굴을 사용할 수 없다. 머리와 현장복을 가린 얼굴만으로도 전원을 즉시 구분해야 한다.
- 키, 어깨 폭과 경사, 몸통 길이, 허리·골반 상대 폭, 팔다리 길이, 다리의 건강한 굵기, 체중 중심과 서 있는 버릇도 캐릭터마다 다르게 적는다.
- 같은 미인형 얼굴, 같은 전신 마네킹, 수아 얼굴에 머리만 바꾼 결과는 폐기한다.
- 나이에 맞는 건강하고 비선정적인 인체 비율을 사용한다.

## 5. 복사해서 쓰는 기본 프롬프트

```text
Use case: stylized-concept
Asset type: production-ready full-body visual-novel character sprite

Input images:
- Image 1: official SIMUL production style reference. Match its rendering
  grammar and the shared uniform and barefoot-clog specification; do not copy
  Sua's face, hair, or body design.
- Image 2: approved identity reference for this character. Preserve the exact
  face geometry, eye shape and spacing, brows, nose, mouth, hairline, hairstyle,
  body proportions, outfit, and character-specific colors.
- Image 3+: optional clothing, footwear, prop, or pose references only.

Style:
- SIMUL production soft-painted VN anime v1.
- Clean medium-thin colored linework.
- Highest detail on the face and layered irises.
- Skin: base color, two controlled soft shadow steps, one restrained blush.
- Hair: one strong silhouette, 5–7 major locks, one shadow mass, one clean
  highlight band; no dense individual strands.
- Clothing: accurate silhouette, one clear fold-shadow layer.
- Repeating patterns: simplified fixed grid with stable color and spacing.
- High quality through clean anatomy, stable identity, confident shapes,
  balanced color, and crisp edges rather than excessive texture.

Identity invariants:
- Keep this character recognizably identical across every expression and pose.
- Change only the requested expression, gesture, hand action, and weight shift.
- Never reuse another character's face or body template.

Composition:
- One character, full body from top of hair through complete soles.
- Both hands, fingers, legs, footwear, and props fully visible.
- 1024×1536 portrait character slot with generous padding.
- Flat removable chroma-key background for transparent extraction.

Avoid:
photorealism, 3D, chibi, generic shared anime face, black heavy outlines,
airbrushed skin, painterly blur, excessive hair strands, unstable patterns,
adult styling for minors, cropped limbs, extra people, text, logo, watermark.
```

### 표정·동작 세트의 생동감 고정 규칙

- 동일 인물 고정은 얼굴 정체성과 체형을 유지한다는 뜻이며, 모든 장면에서 머리 실루엣과 고개 각도를 복사한다는 뜻이 아니다.
- 각 표정은 대사의 감정에 맞는 고개 숙임·기울기·좌우 회전, 턱 각도와 시선 방향을 가져야 한다.
- 묶은 머리·긴 머리·잔머리는 고개와 몸의 움직임을 따라 중력, 관성, 반동이 보이게 흐른다.
- 웃음은 머리카락이 들리고, 놀람은 반동이 생기며, 걱정은 가라앉고, 삐침은 고개 반대편으로 흐르는 식으로 장면마다 실루엣을 구분한다.
- 전 세트가 같은 정면 머리와 목 각도를 재사용하면 불합격이다. 얼굴은 같되 머리 방향과 자세는 자연스럽게 달라야 한다.
- 게임 런타임에서는 캐릭터에 미세한 호흡·좌우 흔들림을 주고, 대사나 표정 전환 때 짧은 반응 동작을 사용한다.

## 6. 승인 순서

1. 중립 얼굴과 전신 한 장을 승인한다.
2. 기본·웃음·화남·놀람 4장으로 동일인 유지 여부를 시험한다.
3. 다른 캐릭터 전원과 얼굴·전신 실루엣 중복 검사를 한다.
4. 통과한 인물만 표정·동작 전체 세트로 확장한다.
5. 승인 자산만 `ART_STYLE_AUDIT.md`에 기록하고 런타임에 연결한다.

## 7. 여자 8명 공통 교복·신발 규칙과 캐릭터별 체형 변주

- 여자 8명은 모두 동일한 하복 디자인을 사용한다: 배꼽과 복부를 완전히 가리는
  정상 길이의 불투명 흰색 반팔 단추 셔츠, 빨강·검정·흰색 타탄 넥타이, 빨간
  타탄 주름치마와 겹친 V자형 하이웨이스트 허리선.
- 여자 8명은 모두 동일한 코랄핑크 계열의 통풍구가 있는 크록스형 클로그를 맨발로 신는다. 양말·스타킹·타이츠는 사용하지 않는다.
- 사용자가 전체 공통 복장을 새로 변경하라고 명시하지 않는 한 캐릭터별로 교복, 넥타이, 치마 구조, 신발 디자인이나 색을 바꾸지 않는다.
- 캐릭터별 개성은 얼굴 설계와 함께 키, 체중 인상, 어깨·골반 폭, 몸통 길이, 팔·다리 길이, 머리 대 신체 비율, 골격과 건강한 체형 범위에서 만든다.
- 모든 체형 차이는 실제 중학교 1학년 연령에 맞는 건강하고 비선정적인 범위로 유지한다.
- 같은 캐릭터의 표정·동작 세트에서는 얼굴뿐 아니라 키, 체중 인상, 골격, 체형, 팔다리 비율, 교복과 신발 크기까지 완전히 고정한다. 장면마다 바꾸는 것은 표정, 손동작, 자세와 체중 이동뿐이다.
