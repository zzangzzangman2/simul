# 서하늘 공인중개사 자산 규격

이 문서는 부동산 전용 화면에 반복 등장하는 **서하늘 공인중개사**의 고정 정체성, 복장, 6개 런타임 포즈와 생성 규칙을 정의한다. 다른 에이전트가 자산을 수정·추가할 때 `ART_STYLE_GUIDE.md`와 함께 반드시 읽는다.

## 기준 참조의 역할

- 최상위 렌더링 화풍: `art_references/simul_luminous_soft_painted_vn_style_anchor_v2.png`
- 서하늘 정체성·복장·장신구:
  - `art_references/realtor_identity_pose_reference_01.jpg`
  - `art_references/realtor_identity_pose_reference_02.jpg`
  - `art_references/realtor_identity_pose_reference_03.jpg`
- 화풍 참조에서는 거의 보이지 않는 유색 경계선, 자연스러운 다층 홍채,
  섬세한 머리카락, 부드러운 페인터리 명암과 은은한 광학 조명만 가져온다.
- 정체성 참조에서는 얼굴·머리·장신구·의상·샌들만 가져온다. 야외 배경, 내려다보는 카메라, 앉거나 무릎 꿇은 자세와 햇빛 방향은 가져오지 않는다.
- 화풍 참조의 청록 머리·보라 눈·뷰티마크는 한서윤의 정체성이므로 서하늘에게 섞지 않는다.

## 변경 금지 정체성

- 이름과 직업: 서하늘 공인중개사
- 연령: 만 24세 성인 여성
- 얼굴: 둥근 턱선의 성인 얼굴, 차분한 옅은 청회색 눈
- 머리: 눈썹을 덮는 일자 앞머리, 정수리의 짙은 남청·보라색에서 턱선의 밝은 시안색으로 이어지는 둥근 단발, 양옆의 바깥 뻗침
- 머리 장식: 한쪽의 검은 삼각 핀, 반대쪽의 흰색·검은색 겹삼각 핀과 파란 물방울 장식
- 나머지 장신구: 턱선 옆 흰색 네 꽃잎 장식, 작은 은색 마름모가 달린 검은 초커
- 체형: 여섯 컷에서 동일한 성인 키와 체형. 교복풍 얼굴·미성년 체형으로 줄이지 않는다.

## 변경 금지 복장

- 흰색·아주 옅은 하늘색의 짧은 오프숄더 프릴 원피스
- 가는 어깨끈과 어깨의 작은 흰 리본
- 쇄골 아래의 이중 프릴과 중앙 파란 리본
- 잘록한 허리 묶음
- 파란 작은 리본이 달린 이중 프릴 밑단
- 흰 프릴 손목 장식
- 오른쪽 허벅지의 가는 검은 가터
- 흰 꽃 장식이 있는 파랑·검정 리본 플랫폼 샌들

포즈가 바뀌어도 원피스 길이, 프릴 층수, 리본의 수·색·위치, 가터 위치와 신발을 바꾸지 않는다. 정장, 재킷, 분리형 치마, 구두, 스타킹으로 재해석하지 않는다.

## 런타임 자산과 상태 매핑

| `_RealtorMood` | 자산 | 표정·자세·소품 | 사용 상태 |
| --- | --- | --- | --- |
| `welcome` | `character_realtor_welcome_v1.png` | 남색 서류철을 들고 열린 손으로 환영 | 첫 진입, 상담 다시 열기 |
| `explain` | `character_realtor_explain_v1.png` | 펼친 매물 책자를 지시봉으로 설명 | 티어·지도·시장 안내 |
| `finance` | `character_realtor_finance_v1.png` | 계산기를 들어 가리키고 클립보드를 듦 | 매입 자금·담보대출 안내 |
| `concerned` | `character_realtor_concerned_v1.png` | 걱정스러운 표정으로 계약서의 경고 부분을 지시 | 매입 실패, 한도 부족, 위험 경고 |
| `approve` | `character_realtor_approve_v1.png` | 집 모양 열쇠를 들어 밝게 축하 | 매입 성공 |
| `negotiate` | `character_realtor_negotiate_v1.png` | 전화를 받으며 다른 손을 열어 협의 | 매각·월세·전세 협상 |

`AssetSpendingScreen(realEstateOnly: true)`에서만 재무 개요 위 `_RealtorGuideCard`로 표시한다. 일반 자산 지출 화면에는 카드도 상태 변경도 노출하지 않는다.

안정 키는 다음을 유지한다.

- 카드 슬롯: `real-estate-realtor-slot`
- 캐릭터: `real-estate-realtor-character`
- 상태별 이미지: `real-estate-realtor-{mood}`
- 조작: `real-estate-realtor-consult`, `real-estate-realtor-dismiss`, `real-estate-realtor-reopen`

## 캔버스와 투명도

- 여섯 파일은 모두 `1024×1536` RGBA 투명 세로 캔버스다.
- 머리 시작은 `y=20`, 발 마지막 픽셀은 `y=1516`, 발 중심은 `x=512`에 맞춘다.
- 머리·샌들·열쇠·책자·계산기·계약서·전화와 열린 손이 캔버스 밖으로 잘리면 안 된다.
- 포즈 때문에 가로폭은 달라도 인물 높이·몸 중심·발 기준선은 동일해야 한다.
- 흰색과 짙은 회색 배경에 각각 합성해 네 모서리 알파 0, 자홍·초록·파랑 크로마 테두리 없음, 머리카락과 프릴의 반투명 가장자리를 확인한다.

## 생성 프롬프트 고정 블록

```text
Canonical rendering reference: art_references/simul_luminous_soft_painted_vn_style_anchor_v2.png.
Identity references: art_references/realtor_identity_pose_reference_01.jpg,
art_references/realtor_identity_pose_reference_02.jpg,
art_references/realtor_identity_pose_reference_03.jpg.

Draw the same 24-year-old adult Korean realtor, Seo Haneul:
the same rounded indigo-to-cyan bob, pale blue-gray eyes, geometric hair clips,
blue teardrop ornament, white four-petal ornament, and black choker.
Keep exactly the same white and pale-blue short off-shoulder frilled dress,
fixed blue bows, right-thigh black garter, white wrist frill,
and blue-black ribbon platform sandals in every pose.

Match the SIMUL luminous soft-painted VN anime v2: fine colored edges,
natural layered irises, delicate hair strands, smooth painterly skin and cloth shading,
and subtle optical light. Do not copy Sua's face, black hair, body, or uniform.
Standing full-body transparent sprite, 1024x1536, common baseline,
no background, no cast shadow, no text, no logo, no watermark.
```

포즈별 마지막 문장에 이 파일의 6개 표에서 지정한 표정·손동작·업무 소품 하나만 추가한다. 얼굴 골격, 머리, 복장과 장신구를 새로 해석하는 문장을 추가하면 안 된다.

## 적용 전 회귀 확인

1. 기본 진입에서 `welcome` 자산이 보이는가?
2. `시장 안내` 조작 뒤 같은 슬롯에서 `explain` 자산으로 바뀌는가?
3. 매입·실패·성공·매각·임대 결과가 각각 지정한 상태로 바뀌는가?
4. 카드를 접었다 다시 열면 `welcome`으로 돌아오는가?
5. 부동산 전용이 아닌 화면에는 카드와 캐릭터가 없는가?
6. 360×800, 텍스트 배율 1.2에서 캐릭터·대사·조작이 넘치거나 가로 스크롤을 만들지 않는가?
