# 10살 여자친구 NPC 자산 규격

이 문서는 주인공과 동갑인 **만 10살 여자친구 NPC(이름 미정)**의 고정 정체성과
현재 제작된 홈웨어 전신 자산을 정의한다. 아직 게임 화면이나 저장 데이터에는 연결하지
않으며, 등장 장면과 관계 시스템이 확정될 때 이 자산을 사용한다.

## 기준 참조

- 정체성 참조: `art_references/girlfriend_identity_reference_v1.jpg`
- 최상위 화풍 참조: `art_references/npc_canonical_style_teal_v1.png`
- 정체성 참조에서는 둥근 얼굴의 인상, 밤색 양갈래, 분홍 리본, 루비·코랄색 눈과
  분홍·흰색 파자마 색 구성을 가져온다.
- 화풍 참조에서는 가는 유색 선화, 보석형 다층 홍채, 3단계 머리카락 묘사,
  선명한 셀 명암과 절제된 페인터리 하이라이트만 가져온다. 한서윤의 청록 머리,
  보라 눈, 뷰티마크는 가져오지 않는다.

## 고정 정체성

- 나이: 만 10살. 주인공과 같은 나이의 어린이
- 얼굴: 따뜻한 밝은 피부, 둥근 볼, 작은 코와 입, 옅은 홍조
- 눈: 짙은 루비 테두리와 코랄·진홍색 층이 겹친 큰 보석형 눈
- 머리: 눈썹을 덮는 반듯한 밤색 앞머리, 좌우 길이와 높이가 같은 긴 양갈래
- 머리 장식: 양쪽에 같은 더스티핑크 리본 한 개씩
- 체형: 작은 어깨와 짧은 몸통을 가진 자연스러운 10살 아동 비율
- 금지: 성인 키·가슴·허리·골반 곡선, 과도한 노출, 선정적 자세, 치비 비율

## 고정 홈웨어

- 여유 있는 연분홍 반소매 파자마 상의
- 목을 충분히 덮는 흰 물결 레이스 세일러 칼라
- 가슴 중앙의 작은 분홍 리본, 흰 파이핑과 단추
- 흰 레이스 소매 끝과 작은 주머니 두 개
- 무릎 아래에서 끝나는 여유 있는 연분홍 파자마 바지
- 흰 레이스 바짓단과 허리의 흰 끈·리본
- 앞이 막힌 연분홍 실내 슬리퍼와 작은 분홍 리본

모든 컷에서 칼라, 단추 수, 리본 수와 위치, 바지 길이, 슬리퍼 디자인을 바꾸지 않는다.

## 현재 자산

| 상태 | 파일 | 표정과 자세 |
| --- | --- | --- |
| 기본 | `character_girlfriend_neutral_v3.png` | 부드러운 미소, 한 손으로 작은 인사 |
| 미소 | `character_girlfriend_smile_v3.png` | 밝은 미소, 얼굴 옆 브이 |
| 활짝 웃음 | `character_girlfriend_laugh_v3.png` | 눈을 감고 웃으며 두 손을 가슴 앞에 모음 |
| 울음 | `character_girlfriend_cry_v3.png` | 작은 눈물, 두 손을 허리 앞에서 맞잡음 |
| 삐짐 | `character_girlfriend_pout_v3.png` | 볼을 살짝 부풀리고 팔짱 |
| 수줍음 | `character_girlfriend_shy_v3.png` | 홍조와 작은 미소, 두 손을 등 뒤에 둠 |

여섯 자산은 모두 `1024×1536` RGBA 투명 전신이다. 머리 시작 `y=20`,
발 마지막 픽셀 `y=1516`, 발 중심 `x=512`를 공통으로 유지한다.

## 기존 여자1 자산과의 관계

`flutter_app/assets/images/여자1/` 및 기존 `character_girlfriend_*_v1/v2.png`
표정 시트는 다른 성인 임시 캐릭터의 보관 자료다. 이번 10살 여자친구와 얼굴,
연령, 머리, 눈, 체형을 섞지 않으며 런타임에 대신 연결하지 않는다.

## 공통 생성 프롬프트

```text
Create the same wholesome 10-year-old Korean childhood-friend character.
Identity reference: art_references/girlfriend_identity_reference_v1.jpg.
Rendering reference: art_references/npc_canonical_style_teal_v1.png.
Keep her round child face, layered ruby-coral eyes, straight chestnut-brown bangs,
long symmetrical high twin-tails, matching dusty-pink bows, and natural school-age proportions.
Keep the same loose pink-and-white child pajama set and closed-toe pink slippers.
Match the canonical fine colored linework, jewel-like irises, three-level hair strands,
crisp cel shading, and subtle painterly highlights without copying Han Seoyun's identity.
Full-body standing sprite, 1024x1536 common canvas and baseline, no background,
no cast shadow, no text, no logo, no watermark, and no chibi proportions.
```

각 상태를 만들 때는 마지막에 표정과 손·상체 자세 한 가지만 추가한다.
얼굴 골격, 홍채, 머리 길이, 리본, 체형과 파자마 재봉선은 다시 해석하지 않는다.
