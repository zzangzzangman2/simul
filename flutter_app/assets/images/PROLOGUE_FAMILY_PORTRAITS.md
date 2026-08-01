# 프롤로그 가족 전신 포즈 세트

> [!WARNING]
> 기존 가족 세계관 저장의 레거시 자산 표다. 리부트 신규 프롤로그에는 연결하지
> 않으며, 새 포즈를 만들 때는 정체성·의상·소품만 보존하고
> `cinematic soft-painted anime realism`으로 재승인한다.

프롤로그 가족은 `ART_STYLE_GUIDE.md`의 공통 `1024×1536` 전신 슬롯과
현행 cinematic soft-painted 승인 규칙을 사용한다. 아래 구형 파일은 인물마다 네 가지 상태를 갖고,
소품이 있는 `action` 포즈는 해당 행동 장면에서만 표시한다.

| 인물 | neutral | expressive | concerned | action |
|---|---|---|---|---|
| 주인공 | `character_prologue_hero_neutral_cartoon_v4.png` | `character_prologue_hero_curious_cartoon_v4.png` | `character_prologue_hero_determined_cartoon_v4.png` | `character_prologue_hero_patched_hoodie_cartoon_v4.png` |
| 어머니 | `character_prologue_mother_neutral_cartoon_v4.png` | `character_prologue_mother_warm_cartoon_v4.png` | `character_prologue_mother_concerned_cartoon_v4.png` | `character_prologue_mother_worn_homewear_cartoon_v4.png` |
| 아버지 | `character_prologue_father_neutral_cartoon_v4.png` | `character_prologue_father_skeptical_cartoon_v4.png` | `character_prologue_father_concerned_cartoon_v4.png` | `character_prologue_father_worn_serious_cartoon_v4.png` |
| 누나 | `character_prologue_sister_neutral_cartoon_v4.png` | `character_prologue_sister_teasing_cartoon_v4.png` | `character_prologue_sister_concerned_cartoon_v4.png` | `character_prologue_sister_worn_homewear_cartoon_v4.png` |
| 외할아버지 | `character_prologue_grandfather_neutral_cartoon_v4.png` | `character_prologue_grandfather_questioning_cartoon_v4.png` | `character_prologue_grandfather_approving_cartoon_v4.png` | `character_prologue_grandfather_worn_vest_cartoon_v4.png` |

런타임 자산 선택은 `lib/family_portrait_assets.dart`에서 관리한다.

- `neutral`: 평범한 경청과 일상 대화
- `expressive`: 질문, 농담, 반문, 승인
- `concerned`: 돈 문제, 위험, 약속처럼 무게가 있는 대화
- `action`: 전선, 드라이버, 키보드, 장부 등 장면에 필요한 소품 행동

새 가족 대화를 추가할 때 같은 인물이 두 비트 이상 연속 등장하면 대사의
감정이나 행동 변화에 맞춰 포즈를 바꾼다. 소품이 대사에 언급되지 않으면
`action`을 사용하지 않는다.
