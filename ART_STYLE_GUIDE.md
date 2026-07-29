> [!CAUTION]
> **생성 버튼을 누르기 전 필수:** 아래에 지정된 기준 이미지와 같은 인물·장소의 기존 런타임 이미지를 먼저 직접 열어 확인하고, 반드시 생성·편집 도구에 실제 참조 이미지로 넣는다. 프롬프트 문장만 보고 화풍을 추측하는 생성은 금지한다. 결과물은 기존 자산과 동일한 고밀도 2D 카툰/애니 게임의 가는 유색선, 얼굴·눈 렌더링, 셀 채색과 명암 밀도를 유지해야 한다. **실사·사진풍·3D·건축 시각화·임의의 다른 애니/웹툰 화풍은 별도 사용자 요청이 없는 한 불합격**이다. 기존 이미지와 나란히 놓았을 때 같은 게임으로 보이지 않으면 저장·연결하지 말고 즉시 재생성한다.

# SIMUL 고정 그림체 가이드

이 문서는 이후 제작·수정하는 모든 게임 일러스트의 기본 아트 디렉션이다. 사용자가 장면별로 다른 방향을 명시하지 않는 한 이 기준을 최우선으로 적용한다.

## 1. 기준 자산

- **모든 신규 NPC의 얼굴 렌더링·눈·선화·머리카락·채색 밀도 최상위 기준**:
  `art_references/npc_canonical_style_teal_v1.png`
- 한서윤 선생님의 의상 실루엣 기준:
  `art_references/stock_teacher_outfit_reference_v1.png`
- 부동산 중개업자의 얼굴·머리·장신구·복장 정체성 기준:
  `art_references/realtor_identity_pose_reference_01.jpg`,
  `art_references/realtor_identity_pose_reference_02.jpg`,
  `art_references/realtor_identity_pose_reference_03.jpg`
- 주인공 얼굴 정체성 기준: `flutter_app/assets/images/title_elementary_landlord_portrait_v2.png`
- 주인공 전신과 투명 컷아웃 기준: `flutter_app/assets/images/character_hero_title_style_v2.png`
- 주인공은 메인 타이틀과 같은 인물이어야 한다. 머리 모양, 눈매, 얼굴 비율, 볼의 형태, 표정 밀도를 장면마다 새로 해석하지 않는다.
- `npc_canonical_style_teal_v1.png`에서 모든 NPC가 가져오는 것은 **그림체와 렌더링 문법**이다. 청록 머리·보라 눈·점 위치는 한서윤의 고유 정체성이므로 다른 NPC에게 복사하지 않는다.
- 인물별 정체성 참조는 최상위 화풍 참조를 대체하지 않는다. 부동산 중개업자 3개 참조에서는 얼굴 골격·남청색에서 시안색으로 이어지는 단발·장신구·프릴 원피스·샌들만 가져오고, 사진의 배경·원근·앉거나 무릎 꿇은 자세·조명은 복사하지 않는다.
- 캐릭터와 배경은 서로 다른 게임의 그림처럼 보이면 안 된다. 모든 신규 NPC는 위 기준 이미지의 고밀도 2D 애니 게임 채색을 공유하고, 배경은 같은 색 선명도와 명암 밀도를 가진 손그림 2D 카툰으로 맞춘다.

## 2. 고정 스타일

- 한국 모바일 스토리 게임에 어울리는 **고밀도 2D 애니 게임 일러스트**
- 선화는 검은 외곽선을 굵게 두르지 않고, 머리·피부·의상 색에 맞춘 가는 유색선과 부분적인 굵기 변화를 쓴다.
- 얼굴은 부드러운 타원형과 자연스러운 볼 입체감, 작지만 생략하지 않은 코, 얇고 섬세한 입술을 함께 그린다. 눈만 크게 붙인 범용 애니 얼굴이나 인물마다 다른 얼굴 문법은 금지한다.
- 눈은 어두운 림, 홍채의 방사형 그라데이션, 안쪽 명암, 큰 주 하이라이트와 작은 보조 하이라이트를 겹친 보석 같은 구조로 그린다. 속눈썹은 또렷하되 한 덩어리 검은 띠가 되지 않게 한다.
- 머리카락은 큰 덩어리 → 중간 가닥 → 가는 잔머리의 3단계로 나누고, 셀 명암 위에 띠 모양의 밝은 반사광과 소수의 가는 하이라이트를 얹는다. 플라스틱 덩어리나 한 색 면으로 처리하지 않는다.
- 피부는 따뜻한 기본색, 턱·목·팔 아래의 선명한 셀 그림자, 볼과 관절의 아주 옅은 혈색, 코끝·쇄골의 절제된 밝은 점을 사용한다. 과한 광택이나 실사 피부 모공은 넣지 않는다.
- 채색은 선명한 셀 셰이딩을 뼈대로 두고 부드러운 페인터리 보정을 얹는다. 주광과 얇은 림라이트는 허용하지만 인물마다 광원 방향과 대비가 제멋대로 달라지면 안 된다.
- 모바일 세로 화면에서 축소해도 눈·표정·손동작과 주요 소품이 선명하게 읽히는 대비
- 2000년 서울이라는 시대 배경은 소품과 공간으로 표현하되 화면 전체에 과도한 세피아 필터를 씌우지 않는다.

다음 스타일은 별도 지시가 없으면 사용하지 않는다.

- 실사·사진 합성·3D 렌더
- 납작한 벡터·웹툰 스티커·SD 치비
- 저밀도 범용 AI 애니풍, 포즈마다 바뀌는 눈 렌더링, 과도한 유광 피부
- 서양 코믹스, 픽셀 아트, 수채화 번짐 위주의 저선명 화풍
- 캐릭터마다 선 굵기·눈 모양·채색 방식이 달라지는 혼합 화풍

## 3. 주인공 얼굴 고정

- 한국인 10세 남자아이의 연령감을 유지한다. 유아처럼 축소하거나 중·고등학생처럼 성숙하게 만들지 않는다.
- 짙은 갈색에 가까운 검은 머리, 살아 있는 잔머리와 분리된 머리카락 덩어리를 유지한다.
- 따뜻한 짙은 갈색 눈, 선명한 하이라이트, 둥근 볼, 옅은 홍조, 작고 자연스러운 코를 유지한다.
- 기본 표정은 밝고 자신감 있지만 과장된 광대 표정은 피한다.
- 메인 타이틀의 빨간 모자는 해당 장면 의상일 뿐 고정 신체 특징이 아니다. 다른 장면에 임의로 추가하지 않는다.
- 주황 후드 전신 컷아웃을 수정할 때는 의상·자세·연령·체형을 보존하고 얼굴 정체성만 흐트러지지 않게 한다.

## 4. 다른 캐릭터와 배경

- 성인 캐릭터는 주인공보다 확실히 성인 비율과 키로 표현한다. 선생님을 꼬마처럼 축소하지 않는다.
- 한서윤 선생님은 만 23세 성인 여성으로 고정한다. `npc_canonical_style_teal_v1.png`와 같은 긴 물결형 청록색 머리·성긴 일자 앞머리·겹 하이라이트가 있는 보라색 눈·작은 뷰티마크·섬세한 성인 얼굴을 모든 컷에서 유지한다.
- 한서윤 의상은 `stock_teacher_outfit_reference_v1.png`의 실루엣을 2D 게임 의상으로 번안한 아이보리색 반소매 오픈칼라 블라우스, 안쪽의 좁은 흰 레이스 가장자리, 사원증 목걸이, 흰 레이스 밑단이 있는 몸에 맞는 검은색 하이웨이스트 미니스커트, 차콜색 시어 타이츠, 검은색 앞막힌 낮은 펌스로 고정한다. 실사 사진 질감을 섞거나 컷마다 치마 길이·칼라·레이스·스타킹을 바꾸지 않는다.
- 가족 인물은 `character_father_title_style_v2.png`, `character_mother_title_style_v2.png`, `character_sister_title_style_v2.png`를 기준으로 한다. 세 자산은 모두 `1024×1536` 공통 캔버스, 머리 `y=20`, 발 `y=1516`, 몸 중심 `x=512`로 정규화하며 주인공·선생님과 같은 선화·얼굴 렌더링·채색 밀도를 유지한다.
- 여자친구 NPC는 주인공과 동갑인 **만 10살 어린이**로 고정한다. `art_references/girlfriend_identity_reference_v1.jpg`에서 둥근 얼굴 인상·밤색 양갈래·양쪽 분홍 리본·루비와 코랄색의 보석형 눈을 가져오되, 체형은 작은 어깨와 짧은 몸통을 가진 자연스러운 10살 아동 비율로 다시 그린다. 성인 키나 가슴·허리·골반 곡선으로 그리지 않는다.
- 여자친구의 현재 홈웨어는 목을 충분히 덮는 흰 물결 레이스 세일러 칼라, 작은 가슴 리본, 흰 파이핑·단추·레이스가 있는 여유 있는 연분홍 반소매 상의, 무릎 아래 연분홍 파자마 바지, 앞이 막힌 연분홍 실내 슬리퍼로 고정한다. 런타임 후보는 `character_girlfriend_neutral/smile/laugh/cry/pout/shy_v3.png` 6종이며 얼굴·홍채·양갈래 길이·리본·옷의 재봉선은 같고 손·상체 자세만 상태에 맞게 달라야 한다.
- `flutter_app/assets/images/여자1/`과 기존 `character_girlfriend_*_v1/v2.png`는 서로 다른 성인 임시 캐릭터의 보관 자료다. 새 10살 여자친구와 섞거나 대신 연결하지 않는다. 세부 규격은 `flutter_app/assets/images/GIRLFRIEND_README.md`를 따른다.
- 누나는 설정상 21~23세의 성인이다. 1999~2000년 서울의 세련되고 매력적인 성인 스타일을 유지하되 교복·미성년 인상·과도한 노출·선정적인 자세는 사용하지 않는다.
- 은행 창구 직원은 **만 23세 성인 여성**으로 고정한다. 검은색 하이 포니테일, 따뜻한 금갈색 눈, 성인 여성의 키와 굴곡 있는 체형, 친절하고 차분한 표정을 유지하며 교복풍 얼굴·미성년 체형으로 축소하지 않는다. 런타임 자산은 환영 `character_bank_clerk_title_style_v2.png`, 금리 설명 `character_bank_clerk_explain_v2.png`, 승인·축하 `character_bank_clerk_approve_v2.png`, 한도 부족·연체 걱정 `character_bank_clerk_concerned_v2.png`의 4종이다.
- 은행 창구 직원 복장은 사용자가 지정한 노출도로 고정한다. 세로 절개선과 작은 검은 단추가 있는 아이보리색 스트랩리스 튜브톱형 정장 블라우스, 얇은 목 칼라에 연결된 짙은 버건디 넥타이, 허벅지 위쪽에서 끝나는 몸에 맞는 짙은 남색 하이웨이스트 정장 스커트, 상단 밴드가 얇게 보이는 차콜색 시어 사이하이 스타킹, 검은색 앞막힌 펌스를 사용한다. 어깨·쇄골·윗가슴과 다리 노출은 허용하지만 유두·속옷 노출, 비치는 상의, 마이크로 스커트, 다리를 들어 올린 자세, 발 강조, 침실·페티시 연출은 금지한다.
- 네 표정 컷은 얼굴만 바꾸지 않는다. 환영은 한 손으로 통장을 제시하고, 설명은 서류를 든 채 열린 손으로 안내하며, 승인은 두 손으로 통장을 내밀고, 걱정은 클립보드의 한도를 짚는다. 의상·인물 높이·몸 중심·발 기준선은 모두 동일하고 두 발을 바닥에 둔 자연스러운 창구 업무 자세를 유지한다.
- 부동산 중개업자의 이름은 **서하늘 공인중개사**, 나이는 **만 24세 성인 여성**으로 고정한다. 둥근 턱선의 성인 얼굴, 차분한 옅은 청회색 눈, 눈썹을 덮는 일자 앞머리, 정수리의 짙은 남청·보라색에서 턱선의 밝은 시안색으로 이어지는 둥근 단발과 양옆의 바깥 뻗침을 세 정체성 참조와 동일하게 유지한다. 교복풍 얼굴이나 미성년 체형으로 축소하지 않는다.
- 부동산 중개업자의 장신구는 한쪽 앞머리의 검은 삼각 핀, 반대쪽 관자놀이의 흰색·검은색 겹삼각 핀과 파란 물방울 장식, 턱선 옆 흰색 네 꽃잎 장식, 작은 은색 마름모가 달린 검은 초커로 고정한다. 포즈마다 장식의 수·색·방향을 바꾸거나 한서윤의 보라 눈·뷰티마크를 섞지 않는다.
- 복장은 세 사용자 참조와 같은 **흰색·아주 옅은 하늘색의 짧은 오프숄더 프릴 원피스**로 고정한다. 가는 어깨끈과 어깨의 작은 흰 리본, 쇄골 아래의 이중 프릴과 중앙 파란 리본, 잘록한 허리 묶음, 파란 작은 리본이 달린 이중 프릴 밑단, 흰 프릴 손목 장식, 오른쪽 허벅지의 가는 검은 가터, 흰 꽃 장식이 있는 파랑·검정 리본 플랫폼 샌들을 모든 컷에서 그대로 사용한다. 정장·재킷·분리형 치마·구두·스타킹으로 바꾸거나 원피스 길이와 리본 위치를 임의 변경하지 않는다.
- 런타임 중개업자 자산은 6종이다. `character_realtor_welcome_v1.png`는 남색 서류철을 들고 열린 손으로 환영, `character_realtor_explain_v1.png`는 펼친 매물 책자를 지시봉으로 설명, `character_realtor_finance_v1.png`는 계산기를 가리키며 대출·자금 안내, `character_realtor_concerned_v1.png`는 걱정스러운 표정으로 계약서의 경고 부분을 지시, `character_realtor_approve_v1.png`는 집 모양 열쇠를 들어 거래 성공 축하, `character_realtor_negotiate_v1.png`는 전화 통화와 열린 손으로 매각·임대 협상을 표현한다.
- 중개업자 6종은 모두 `1024×1536` 투명 세로 캔버스, 머리 `y=20`, 발 마지막 픽셀 `y=1516`, 발 중심 `x=512`의 공통 전신 기준을 따른다. 얼굴·체형·머리·의상·장신구는 동일하고 표정·손동작·업무 소품만 상태에 맞게 달라야 한다.
- 교실과 시장 실습의 한서윤 런타임 자산은 위 얼굴·의상으로 통일한 `22_포즈1`~`27_포즈6`을 쓴다. 순서는 환영 지시봉, 차트 지시, 마커 양손 설명, 교재 안내, 경청, 핵심 강조다. 여섯 자산은 모두 공통 `1024×1536` 투명 세로 캔버스, 머리 `y=20`, 발 마지막 픽셀 `y=1516`, 발 중심 `x=512`로 정규화한다.
- 반복 등장 NPC는 얼굴만 바꾼 한 장으로 끝내지 않는다. 최소 4종의 **표정과 서로 다른 손·상체 자세**를 만들고, 설명 역할처럼 대화 비중이 큰 인물은 6종을 기본으로 한다. 표정·자세가 달라도 얼굴 골격, 홍채 구조, 머리 길이와 가르마, 체형, 의상 재봉선·소품은 동일해야 한다.
- 교실·집·시장 배경은 따뜻한 손그림풍 2D 카툰으로 제작한다. 사진처럼 사실적인 배경 위에 애니 캐릭터만 얹지 않는다.
- 은행 배경은 `bg_stock_academy_2000_portrait_cartoon_v4.png`의 손그림 선화와 셀 채색을 직접 기준으로 삼고 `bg_bank_branch_2000_portrait_cartoon_v2.png`를 런타임 자산으로 사용한다. 건축·가구·CRT·유선전화·통장정리기에도 또렷한 외곽선을 넣고 형태와 재질은 2D 카툰으로 단순화한다. 실사 대리석 질감, 사진 조명, 3D 렌더, 레이트레이싱 반사, 사실적인 건축 시각화는 불합격으로 폐기한다.
- 은행 배경은 2000년 한국 동네 은행의 목재 창구, 투명 칸막이, CRT, 유선전화, 통장정리기, 번호표 동선, 벽시계와 대기 의자를 사용한다. 인물을 합성할 중앙은 비우고 하단 약 22%는 대화창이 덮어도 핵심 소품이 잘리지 않도록 낮은 정보 밀도로 둔다. 배경 자체에는 사람·로고·읽을 수 있는 상호를 넣지 않는다.
- 배경은 대화창과 인물의 자리까지 고려해 구성한다. 인물의 머리, 손, 발이 모바일 안전영역이나 대화창에 잘리지 않게 한다.
- 교실 배경은 별도 요청이 없으면 학생 군중을 넣지 않고 교탁·칠판·트레이딩 화면을 중심으로 둔다.

## 5. 생성 프롬프트 필수 문구

모든 신규 이미지 프롬프트에는 아래 의미를 빠뜨리지 않는다.

```text
Canonical NPC rendering reference: art_references/npc_canonical_style_teal_v1.png
Match its refined high-detail 2D anime-game face rendering, jewel-like layered irises,
fine colored linework, three-level hair strand structure, crisp cel shading, and subtle painterly highlights.
Keep recurring character identity consistent; do not reinterpret the face.
The teal hair, violet eyes, and beauty marks belong only to Han Seoyun; use each other NPC's own identity colors.
Avoid low-detail generic anime, chibi, photorealism, 3D, flat vector art, mixed styles, text, and watermarks.
Compose for a 390×844 mobile portrait screen with clear facial readability and safe margins.
```

주인공이 포함되면 다음도 추가한다.

```text
The protagonist must be the same Korean 10-year-old boy as the canonical title reference:
same dark tousled hair, warm dark-brown eyes, rounded cheeks, youthful facial proportions, and lively friendly expression.
```

부동산 중개업자가 포함되면 다음도 추가한다.

```text
Realtor identity references:
art_references/realtor_identity_pose_reference_01.jpg,
art_references/realtor_identity_pose_reference_02.jpg,
art_references/realtor_identity_pose_reference_03.jpg.
Keep the same 24-year-old adult realtor: rounded indigo-to-cyan bob, pale blue-gray eyes,
paired geometric hair clips, blue teardrop ornament, white four-petal ornament, and black choker.
Keep exactly the same white and pale-blue short off-shoulder frilled dress, fixed blue bows,
right-thigh black garter, white wrist frill, and blue-black ribbon platform sandals.
Use the canonical NPC reference only for rendering language; do not copy Han Seoyun's identity.
Create a standing full-body transparent game sprite, not the seated pose, outdoor background, or camera angle of the identity references.
```

## 6. 투명 캐릭터 제작

- 인물 컷아웃은 머리카락과 신발이 모두 들어온 전신 원본으로 생성한다.
- 모든 중앙 전신 캐릭터는 `1024×1536` 투명 캔버스로 정규화한다. 알파 인물 높이는 약 `1496px`, 머리 여백은 약 `14~20px`, 발 기준선은 `y=1516`, 발 중심은 `x=512`에 둔다. 포즈가 바뀌어도 이 기준선과 몸 중심은 움직이지 않는다.
- 런타임은 캐릭터마다 임의 좌표를 만들지 않는다. 공통 슬롯 `Positioned.fill(bottom: 122) → LayoutBuilder → Align.bottomCenter → SizedBox(aspectRatio: 2/3, height: maxHeight×0.78)`을 사용한다.
- 390×844에서는 공통 이미지 박스가 `left 7.28, top 158.84, width 375.44, height 563.16, bottom 722, centerX 195`, 360×800에서는 `left 3.72, top 149.16, width 352.56, height 528.84, bottom 678, centerX 180`이다. 주인공·선생님·추가 등장인물 모두 같은 값이다.
- 팔이나 소품 때문에 포즈별 가로폭은 달라도 된다. 대신 인물 높이·발 기준선·몸 중심은 동일해야 하며, 자세 변경을 위해 런타임 `left/top/scale`을 바꾸지 않는다.
- 투명 배경이 직접 안정적으로 나오지 않으면 인물에 없는 단색 크로마 배경으로 생성한 뒤 알파로 제거한다.
- 제거 후 네 모서리 알파 0, 인물 바운딩 박스의 충분한 여백, 색 번짐과 초록 테두리 부재를 검사한다.
- 크로마 색은 인물의 머리·눈·의상과 겹치지 않게 고른다. 제거 뒤에는 흰색과 짙은 회색 배경에 각각 합성해 초록색뿐 아니라 자홍색·파란색 잔여 테두리도 검사한다.
- 발밑 그림자, 배경 광원, 소품을 투명 컷아웃에 합치지 않는다.

## 7. 적용 전 확인표

1. `npc_canonical_style_teal_v1.png`를 모든 NPC 생성의 실제 스타일 참조로 넣었는가?
2. 같은 인물의 얼굴과 연령이 유지되는가?
3. 스타일과 정체성을 구분해 다른 NPC에게 한서윤의 청록 머리·보라 눈을 복사하지 않았는가?
4. 반복 NPC의 표정뿐 아니라 손·상체 자세도 장면별로 달라지는가?
5. 화면 안에서 머리·손·발이 잘리지 않는가?
6. 390×844와 360×800에서 표정이 읽히는가?
7. 캐릭터와 배경의 선화·색온도·명암 밀도가 같은가?
8. 글자, 워터마크, 불필요한 인물과 소품이 들어오지 않았는가?
9. 투명 자산을 흰색·짙은 회색 양쪽에 합성해 알파 가장자리와 잔여 크로마 색을 검사했는가?

## 8. 조작형 미니게임 픽셀 아트 예외

서사 장면·대화 인물·배경은 위의 고밀도 2D 카툰 기준을 그대로 따른다. 조작형 아케이드 미니게임의 작은 플레이 오브젝트만 화면 판독성을 위해 의도적인 16비트 픽셀 아트로 변환할 수 있다.

- 주인공의 검은 헝클어진 머리, 갈색 눈, 둥근 볼, 주황 후드와 연령은 메인 타이틀 정체성을 유지한다.
- 픽셀 캐릭터는 얼굴·팔다리·이동 수단이 구분되는 완성 스프라이트를 사용한다. 얼굴 아이콘, 원, 점, 단색 사각형으로 대체하지 않는다.
- `잼민 라이더` 기준 자산은 `assets/images/minigames/rider_hero_pixel_v1.png`이며, 주황 안전모·주황 후드·노란 수동 킥보드·빨간 배달 가방을 고정한다.
- 런타임 원본은 투명 `72×128` PNG로 유지하고 네 모서리 알파 0과 충분한 패딩을 검사한다.
- Flutter에서는 `FilterQuality.none`과 `isAntiAlias: false`를 사용한다. 스프라이트 크기를 임의의 소수 비율로 심하게 축소해 픽셀을 흐리지 않는다.
- 장애물·체크포인트·도로도 같은 굵기의 사각 픽셀 군집과 제한 팔레트를 사용한다. Material 아이콘과 둥근 임시 도형을 최종 자산으로 남기지 않는다.
- 움직임은 차선 이동 기울기, 1~2px 상하 바운스, 먼지 픽셀처럼 실루엣을 해치지 않는 짧은 애니메이션만 사용한다.
- 390×844와 360×800에서 주인공 얼굴, 킥보드 두 바퀴, 장애물 종류와 배달 지점이 즉시 구분되어야 한다.
