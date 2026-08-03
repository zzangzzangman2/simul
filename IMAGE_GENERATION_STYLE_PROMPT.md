# SIMUL 캐릭터 이미지 생성 공식 프롬프트

> [!CAUTION]
> 이 문서는 모든 신규·재생성 캐릭터에 적용하는 최상위 화풍 명세다.
> 2026-08-03 사용자가 승인한 한수아 중립 전신의 렌더링을 새 목표로 삼는다.
> 한수아 9종은 런타임에 적용됐고, 중립 전신과 동일한 픽셀이 정식 v3 앵커다.

## 1. 공식 화풍

- 공식명: **SIMUL polished soft-render VN anime v3**
- 한국어명: **고밀도 폴리시드 소프트 렌더 비주얼노벨 애니 v3**
- 사용자 승인 정식 화풍 앵커:
  `art_references/simul_polished_soft_render_vn_style_anchor_v3.png`
- 이 앵커는 2026-08-03 승인·적용된 한수아 중립 전신과 동일한 픽셀이다.
- 앵커는 **윤곽선, 명암 밀도, 피부·홍채·머리카락·의상의 마감, 재질 대비**만
  전달한다. 앵커 속 한수아의 얼굴·검은 웨이브 머리·체형·현장복·포즈를 다른
  인물에게 복제하지 않는다.
- 구형 v2 공통 화풍 앵커는 2026-08-03 삭제했다. 신규 생성이나 비교 참조로 되살리지 않는다.

## 2. 반드시 고정할 렌더링 문법

- 전체는 고밀도 마감의 2D 한국 모바일 비주얼노벨 애니 캐릭터다. 인체와 재질의
  입체감은 충분히 주되 사진·실사 합성·3D 렌더로 보이지 않게 한다.
- 선은 기존 v2보다 또렷하다. 속눈썹·눈꺼풀·머리 다발·손가락·의상 외곽에는
  얇고 정돈된 짙은 유색선을 사용하고, 피부 외곽은 더 부드럽게 연결한다. 균일한
  굵은 검정 만화선이나 선이 거의 사라진 흐린 에어브러시는 모두 피한다.
- **기존 얼굴·정체성·헤어·의상을 그대로 유지하는 대상은 데시멀 여자 동기 8명뿐이다.**
  이 8명은 얼굴형, 이마와 헤어라인, 눈 크기·간격·각도, 눈썹, 코, 입, 인중,
  턱과 볼 비율을 재설계하지 않는다.
- 주인공은 고정 인물 이미지를 생성하지 않는 무초상화 플레이어다. 김학준·한서윤·
  국정원/정부 관계자·은행원·공인중개사 등 나머지 NPC는 구형 외형 보존 대상이 아니다. 서사상 역할·나이·성격·필수 소품만 유지하고 새 v3
  화풍에 맞는 얼굴·헤어·체형·의상으로 전면 재설계할 수 있다. 화풍이 맞지 않는
  청와대·정부 계열 구형 인물은 모두 교체하며, 이미 삭제·격리한 자산을 되살리지 않는다.
- 홍채는 선명한 어두운 링, 캐릭터 고유색의 그라데이션, 작은 다층 하이라이트와
  또렷한 속눈썹으로 마감한다. 눈을 더 크게 만들거나 앵커 속 한수아의 눈으로
  표준화하지 않는다.
- 피부는 깨끗한 밝은 기본색 위에 부드러운 웜 섀도, 볼·콧등 홍조, 코끝과 입술의
  작은 반사광을 얹는다. 사진식 모공은 없지만 얼굴 평면과 코·볼·턱의 볼륨은
  읽혀야 하며, 플라스틱 인형 같은 균일 광택은 금지한다.
- 머리카락은 어두운 깊이, 큰 웨이브·묶음의 명확한 덩어리, 가는 머릿결과 잔머리,
  좁고 밝은 윤광 밴드를 겹쳐 고밀도로 마감한다. 여자 동기 8명은 색·길이·가르마·
  앞머리·컬과 전체 실루엣을 그대로 유지하고, 비보존 인물은 새 대표 디자인 승인 뒤 고정한다.
- 여자 동기 8명의 의상은 기존 디자인과 치수를 바꾸지 않고 봉제선, 얕은 주름,
  가장자리 명암과 절제된 재질광만 강화한다. 타탄은 선명한 고정 격자로 유지한다.
  비보존 인물의 의상은 새 대표 디자인 승인 뒤 세트 전체에서 고정한다.
- 명암은 밝은 피부·흰 셔츠와 짙은 머리·타탄 사이의 대비가 선명하되 검게 뭉개지지
  않아야 한다. 얼굴, 손, 발, 신발, 체크무늬가 흐린 결과는 폐기한다.
- 금지: 실사 얼굴, 사진 합성, 3D, 치비, 하드 셀 2단 명암, 균일한 굵은 검정선,
  흐린 수채 번짐, 과도한 피부 광택, 과도한 렌즈 효과, 성인화, 얼굴 재설계.

## 3. 모든 채팅에서 지킬 입력 순서

1. `art_references/simul_polished_soft_render_vn_style_anchor_v3.png`를 **Image 1: 새 v3 화풍 전용 참조**로 직접 연다.
2. **여자 동기 8명일 때만** 해당 인물의 승인 얼굴 앵커를 **Image 2: 얼굴 정체성 참조**로 직접 연다.
3. **여자 동기 8명일 때만** 교체할 현행 런타임 이미지를 **Image 3: 포즈·표정·복장·체형·구도 참조**로 직접 연다.
4. 그 밖의 인물은 구형 이미지를 정체성 참조로 넣지 않는다. 역할·나이·성격·장면 기능을
   텍스트로 설계하고, 꼭 필요한 소품이나 포즈만 제한된 참조로 추가한다.
5. 별도 전신 앵커, 소품 또는 신발 참고가 꼭 필요할 때만 다음 Image 슬롯에 추가한다.
6. 프롬프트에 `Image 1에서는 렌더링 문법만 가져오고 한수아의 얼굴·머리·체형·복장·포즈는 복제하지 않는다`를 적는다.
7. 여자 동기 8명은 프롬프트에 `Image 2와 Image 3의 인물은 같은 사람이다. 얼굴·헤어·체형·복장·표정·포즈·카메라·프레이밍은 유지하고 렌더링 화풍만 v3로 바꾼다`를 적는다.
8. 문서 설명과 보이는 승인 이미지가 충돌하면 얼굴을 새로 추측하지 않는다. 승인 얼굴
   앵커의 실제 픽셀을 우선하고 충돌은 `ART_STYLE_AUDIT.md`에 기록한다.

## 4. 캐릭터별 독립 정체성

- 여자 동기 8명은 이미 승인된 독립 정체성을 그대로 유지한다. 그 밖의 신규·전면
  재설계 인물만 얼굴 골격, 이마와 헤어라인, 눈, 눈썹, 코, 입술, 인중, 턱선과 볼을 새로 설계한다.
- 데시멀 여자 동기 8명은 어떠한 경우에도 같거나 비슷한 얼굴을 사용할 수 없다. 머리와 현장복을 가린 얼굴만으로도 전원을 즉시 구분해야 한다.
- 키, 어깨 폭과 경사, 몸통 길이, 허리·골반 상대 폭, 팔다리 길이, 다리의 건강한 굵기, 체중 중심과 서 있는 버릇도 캐릭터마다 다르게 적는다.
- 같은 미인형 얼굴, 같은 전신 마네킹, 앵커 속 한수아 얼굴에 머리만 바꾼 결과는 폐기한다.
- 나이에 맞는 건강하고 비선정적인 인체 비율을 사용한다.

## 5. 여자 동기 8명용 화풍 전환 프롬프트

```text
Use case: stylized-concept
Asset type: production-ready full-body visual-novel character sprite

Input images:
- Image 1: official SIMUL polished soft-render VN anime v3 style reference. Match only its
  rendering grammar; do not copy Sua's face, black wavy hair, body, uniform,
  pose, or expression.
- Image 2: approved face identity reference for this cohort girl. Preserve the exact
  face geometry, eye shape and spacing, brows, nose, mouth, hairline, hairstyle,
  and character-specific colors.
- Image 3: current runtime image being regenerated. Preserve its exact body
  proportions, outfit, expression, gesture, pose, camera angle and framing.
- Image 4+: optional prop or detail references only.

Style:
- SIMUL polished soft-render VN anime v3.
- Match Image 1's rendering only. Never copy Sua's face, black wavy hair,
  body proportions, uniform, pose, or expression into another character.
- Thin, controlled dark colored linework with crisp eyelids, lashes, hair locks,
  fingers, garment seams and outer edges; no uniform heavy comic outline.
- Highest detail on the preserved face and character-specific layered irises.
- Skin: clean luminous base, smooth warm volume shadows, thin cheek-and-nose blush,
  small controlled highlights; no pores, flat two-tone cells, or plastic gloss.
- Hair: preserve the exact silhouette, color, length, part, bangs and curl pattern;
  deepen major locks with dense strand layering and narrow polished highlights.
- Clothing: preserve the exact design and fit; add crisp seams, soft folds,
  controlled material sheen and clean edge contrast.
- Repeating patterns: crisp fixed grid with stable color, spacing and direction.
- High quality through exact identity preservation, clean anatomy, polished
  material rendering, controlled contrast and sharp readable edges.

Identity invariants:
- For the eight Decimal cohort girls only, keep the character recognizably
  identical to Images 2 and 3. Preserve face, hair, body, outfit, expression,
  gesture, pose, camera angle, framing, prop placement and weight shift.
- For those eight girls, change only line treatment, shading density, material
  rendering and finish.
- For every other character, do not preserve an off-style legacy face, hair,
  body or outfit. Redesign the person in v3 while keeping only the required
  narrative role, age, personality and scene function.
- Never reuse another character's face or body template.

Composition:
- One character, full body from top of hair through complete soles.
- Both hands, fingers, legs, footwear, and props fully visible.
- 1024×1536 portrait character slot with generous padding.
- Flat removable chroma-key background for transparent extraction.

Avoid:
photorealism, photo compositing, 3D, chibi, generic shared anime face,
face redesign, identity drift, uniformly heavy black outlines, flat cel shading,
plastic airbrushed skin, painterly blur, uncontrolled hair noise, unstable patterns,
adult styling for minors, cropped limbs, extra people, text, logo, watermark.
```

### 비보존 인물 전면 재설계 프롬프트

```text
Use case: stylized-concept
Asset type: new production-ready full-body visual-novel character design

Input images:
- Image 1: simul_polished_soft_render_vn_style_anchor_v3.png. Match only the SIMUL polished
  soft-render VN anime v3 rendering grammar. Never copy Sua's face, black wavy
  hair, body, uniform, pose or expression.
- Do not use an off-style legacy character image as an identity reference.
- Optional references may define only a required work prop or pose function.

Narrative invariants:
- Preserve only the character's required name, role, age, personality, era,
  scene function and indispensable prop.
- Create a new face, hair design, body design and outfit appropriate to those facts.
- Do not preserve a legacy face, hair, body or outfit and do not reuse any of
  the eight Decimal cohort girls.

Style:
- SIMUL polished soft-render VN anime v3.
- Thin controlled dark colored linework, polished soft volume shading,
  layered character-specific irises, clean skin volume, dense controlled hair,
  crisp garment construction and restrained material highlights.
- Clearly 2D anime, not photoreal, photo-composited, 3D, chibi or flat hard cel.

Composition:
- One character, full body, 1024x1536 transparent production slot.
- Complete hands, fingers, legs, footwear and required props in frame.
- No background, cast shadow, text, logo or watermark.
```

### 표정·동작 세트의 생동감 고정 규칙

- 현행 포즈를 일대일 재생성할 때는 해당 파일의 표정·손동작·자세·구도를 그대로
  유지한다. 아래 규칙은 세트 안의 서로 다른 기존 포즈를 한 자세로 뭉개지 말라는 뜻이다.
- 동일 인물 고정은 얼굴 정체성과 체형을 유지한다는 뜻이며, 모든 장면에서 머리 실루엣과 고개 각도를 복사한다는 뜻이 아니다.
- 각 표정은 대사의 감정에 맞는 고개 숙임·기울기·좌우 회전, 턱 각도와 시선 방향을 가져야 한다.
- 묶은 머리·긴 머리·잔머리는 고개와 몸의 움직임을 따라 중력, 관성, 반동이 보이게 흐른다.
- 웃음은 머리카락이 들리고, 놀람은 반동이 생기며, 걱정은 가라앉고, 삐침은 고개 반대편으로 흐르는 식으로 장면마다 실루엣을 구분한다.
- 전 세트가 같은 정면 머리와 목 각도를 재사용하면 불합격이다. 얼굴은 같되 머리 방향과 자세는 자연스럽게 달라야 한다.
- 게임 런타임에서는 캐릭터에 미세한 호흡·좌우 흔들림을 주고, 대사나 표정 전환 때 짧은 반응 동작을 사용한다.

## 6. 승인 순서

1. 여자 동기 8명은 각 9종, 총 72종의 v3 런타임 적용을 완료했다.
2. 1999년 국정원·정부 인물 6명은 구형 외형을 보존하지 않은 새 v3 대표 디자인으로
   전면 교체하고 기존 호환 경로에 연결했다.
3. 플레이어는 고정 인물 이미지를 생성하지 않는다. 구형 포즈 24종은 삭제했으며 대사와
   별도 주식 복기 연출에서도 초상화 슬롯을 비운다. 김학준은 공식 남자 현장복 v4 9종을
   적용했다. 이후 포즈는 `production_soft_painted/kim_hakjun/01_neutral_crosscheck_uniform_v4.png`와
   `art_references/future_development_male_uniform_length_reference_v1.png`를 함께 기준으로 확장한다.
4. 한서윤·은행원·공인중개사 등 남은 비보존 인물은 기존 외형 보존 없이 v3로 새로
   설계하고, 중립 또는 대표 포즈 한 장을 기준으로 전체 세트로 확장한다.
5. 기존 런타임 파일은 대체 세트 전체가 준비되기 전까지 덮어쓰거나 연결 해제하지 않는다.
5. 적용 자산은 `ART_STYLE_AUDIT.md`에 기록하고 런타임에 연결한다.

## 7. 여자 8명 공통 센터 지급 현장복·신발 규칙과 캐릭터별 체형 변주

- 여자 8명은 모두 동일한 하복 디자인을 사용한다: 배꼽과 복부를 완전히 가리는
  정상 길이의 불투명 흰색 반팔 단추 셔츠, 빨강·검정·흰색 타탄 넥타이, 빨간
  타탄 주름치마와 겹친 V자형 하이웨이스트 허리선.
- 여자 8명은 모두 동일한 코랄핑크 계열의 통풍구가 있는 크록스형 클로그를 맨발로 신는다. 양말·스타킹·타이츠는 사용하지 않는다.
- 사용자가 전체 공통 복장을 새로 변경하라고 명시하지 않는 한 캐릭터별로 현장복, 넥타이, 치마 구조, 신발 디자인이나 색을 바꾸지 않는다.
- 캐릭터별 개성은 이미 승인된 얼굴, 키, 체중 인상, 어깨·골반 폭, 몸통 길이,
  팔·다리 길이, 머리 대 신체 비율과 골격의 차이로 유지한다. 화풍 전환 중 새로 설계하지 않는다.
- 모든 체형 차이는 실제 중학교 1학년 연령에 맞는 건강하고 비선정적인 범위로 유지한다.
- 같은 캐릭터의 표정·동작 세트에서는 얼굴뿐 아니라 키, 체중 인상, 골격, 체형, 팔다리 비율, 현장복과 신발 크기까지 완전히 고정한다. 장면마다 바꾸는 것은 표정, 손동작, 자세와 체중 이동뿐이다.
