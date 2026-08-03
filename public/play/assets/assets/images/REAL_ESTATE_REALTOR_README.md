# 서하늘 공인중개사 자산 규격

이 문서는 부동산 전용 화면에 반복 등장하는 **서하늘 공인중개사**의 역할, 6개
런타임 상태와 v3 전면 재설계 규칙을 정의한다. 서하늘은 여자 동기 8명이 아니므로
기존 얼굴·헤어·체형·의상·장신구는 보존 대상이 아니다.

## 기준 참조의 역할

- 최상위 목표 화풍: `SIMUL polished soft-render VN anime v3`
- 화풍 참조: `art_references/simul_polished_soft_render_vn_style_anchor_v3.png`의 렌더링 문법만 사용
- 아래 파일은 구형 외형 기록이며 새 정체성 앵커가 아니다.
  - `art_references/realtor_identity_pose_reference_01.jpg`
  - `art_references/realtor_identity_pose_reference_02.jpg`
  - `art_references/realtor_identity_pose_reference_03.jpg`
- 구형 참고 이미지의 얼굴·머리·장신구·의상·샌들을 복제하지 않는다. 역할과 포즈
  기능을 이해하는 자료로만 제한하고 생성 입력에는 넣지 않는다.
- 새 대표 디자인은 정식 앵커 속 한수아나 여자 동기 8명의 얼굴·머리·체형·의상을 복제하지 않는다.

## 유지할 서사 정체성

- 이름과 직업: 서하늘 공인중개사
- 연령: 만 24세 성인 여성
- 전문적이고 신뢰감 있는 성인 부동산 안내자
- 여섯 상태에서 같은 새 인물로 읽히는 얼굴·헤어·체형·의상
- 교복풍 얼굴·미성년 체형으로 줄이지 않는다.

## 새 대표 디자인 승인

기존 오프숄더 프릴 원피스·가터·플랫폼 샌들·장식 과밀 디자인은 보존하지 않는다.
1999~2000년 한국의 24세 공인중개사 역할과 화면 가독성에 맞는 새 얼굴·헤어·체형·
복장·신발을 대표 전신 한 장으로 먼저 제안하고 사용자 승인을 받는다. 승인 뒤에는
그 새 디자인을 6개 상태에서 동일하게 유지한다.

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
Canonical rendering reference: art_references/simul_polished_soft_render_vn_style_anchor_v3.png.
Use it for SIMUL polished soft-render VN anime v3 rendering only.
Do not copy Sua's face, black wavy hair, body, uniform, pose or expression.

Design a new 24-year-old adult Korean realtor, Seo Haneul, for her first
representative full-body approval image. Keep only her name, occupation,
professional and trustworthy role, age, and 1999-2000 Korean setting.
Do not preserve the legacy face, indigo-to-cyan bob, ornaments, frilled dress,
garter, or platform sandals. Do not reuse any of the eight cohort girls.

Use thin controlled dark colored linework, polished soft volume shading,
layered irises, dense but controlled hair rendering, clean skin volume,
crisp clothing seams and restrained material highlights.
Standing full-body transparent sprite, 1024x1536, common baseline,
no background, no cast shadow, no text, no logo, no watermark.
```

대표 디자인 한 장이 승인되기 전에는 6개 상태를 대량 생성하지 않는다. 승인 뒤에는
프롬프트를 `Design the same newly approved Seo Haneul`로 바꾸고 표의 표정·손동작·업무
소품만 상태별로 추가한다.

## 적용 전 회귀 확인

1. 기본 진입에서 `welcome` 자산이 보이는가?
2. `시장 안내` 조작 뒤 같은 슬롯에서 `explain` 자산으로 바뀌는가?
3. 매입·실패·성공·매각·임대 결과가 각각 지정한 상태로 바뀌는가?
4. 카드를 접었다 다시 열면 `welcome`으로 돌아오는가?
5. 부동산 전용이 아닌 화면에는 카드와 캐릭터가 없는가?
6. 360×800, 텍스트 배율 1.2에서 캐릭터·대사·조작이 넘치거나 가로 스크롤을 만들지 않는가?
