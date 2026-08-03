# SIMUL 런타임 이미지 승인표

최종 갱신: 2026-08-03

이 문서는 현재 런타임 연결과 공식 화풍 재검수 상태를 함께 기록한다. 정체성 앵커
승인과 `SIMUL luminous soft-painted VN anime v2` 화풍 통과는 별도 판정이다.
`재제작`·`보정 필요` 자산은 교체 전까지 런타임에 남아 있을 수 있지만 신규 생성의
화풍 참조로 사용하지 않는다.

## 단일 화풍

- 공식명: `SIMUL luminous soft-painted VN anime v2`
- 화풍 앵커: `art_references/simul_luminous_soft_painted_vn_style_anchor_v2.png`
- 생성 규칙: `IMAGE_GENERATION_STYLE_PROMPT.md`, `ART_STYLE_GUIDE.md`
- 신규 캐릭터는 실사·사진 합성·3D·치비가 아니라 위 화풍을 사용한다.

## 여학생 런타임 연결·화풍 재검수

| 인물 | 정체성 앵커 | 런타임 세트 | 2026-08-03 화풍 판정 |
| --- | --- | --- | --- |
| 김서아 | `kim_seoa_identity_anchor_v1.png` | `production_soft_painted/kim_seoa/` 9종 | 보정 필요 — 피부·홍채 색층과 머리카락 진주빛 하이라이트가 공식 앵커보다 평평함 |
| 이지안 | `lee_jian_face_identity_anchor_v2.png`, `lee_jian_identity_anchor_v2.png` | `production_soft_painted/lee_jian/` v2 9종 | 재제작 우선 — 런타임의 밝은 장발이 승인된 먹갈색 C컬 보브 정체성과 불일치 |
| 최이서 | `choi_iseo_identity_anchor_v1.png` | `production_soft_painted/choi_iseo/` 9종 | 보정 필요 — 피부·홍채 층과 유색선이 공식 앵커보다 단순함 |
| 정아린 | `jung_arin_identity_anchor_v1.png` | `production_soft_painted/jung_arin/` 9종 | 재제작 우선 — 굵고 어두운 선, 하드 셀 명암과 과장된 얼굴 비율 |
| 박하은 | `park_haeun_face_identity_anchor_v2.png`, `park_haeun_identity_anchor_v2.png` | `production_soft_painted/park_haeun/` v2 9종 | 통과 — 공식 화풍 앵커의 기준 세트 |
| 한수아 | `han_sua_identity_anchor_v3.png`(1차 전신), `han_sua_face_identity_anchor_v3.png`(2차 얼굴 크롭) | `production_soft_painted/han_sua/` v3 9종 | 통과 — 공식 v2 렌더링 문법과 승인 정체성 유지 |
| 오지우 | `oh_jiwoo_identity_anchor_v1.png` | `production_soft_painted/oh_jiwoo/` 9종 | 보정 필요 — 피부·홍채 색층과 유색선이 공식 앵커보다 평평함 |
| 윤채아 | `yoon_chaea_identity_anchor_v1.png` | `production_soft_painted/yoon_chaea/` 9종 | 보정 필요 — 피부·홍채 색층과 얼굴 세부가 공식 앵커보다 단순함 |

위 경로는 모두 `flutter_app/assets/images/` 기준이다. 현재 편집기와 프롤로그는
이 파일들을 사용하지만, `재제작 우선`·`보정 필요` 판정은 교체 전 임시 런타임
연결일 뿐 신규 제작의 승인 화풍 참조가 아니다.

한수아의 얼굴 크롭은 얼굴 비율 확인용이다. 크롭에 보이는 `1/2` UI, 손, 파란
천·레이스는 승인 정체성에 포함하지 않는다.

## 다른 현행 자산군

| 자산군 | 경로·기준 | 2026-08-03 화풍 판정 |
| --- | --- | --- |
| 주인공 플레이어 | `flutter_app/assets/images/protagonist_seed01/` 24종(호환 경로) | 재제작 우선 — 굵은 검은 선, 평평한 피부와 하드 셀 명암 |
| 김학준 | `historical_prologue/character_hakjun_orientation_v2.png` | 재제작 우선 — 큰 머리 비율과 하드 셀 애니 렌더링 |
| 한서윤 운영관 | `flutter_app/assets/images/주식선생님/`의 코드 연결 6포즈 | 재제작 우선 — 반실사 에어브러시와 3D형 광택 |
| 1999년 국정원 인물 | `cinematic_soft_painted/decimal_nis_1999/characters/` 6명 | 재제작 우선 — 애니·반실사 렌더링이 한 세트 안에서 혼재 |
| 1999년 국정원 배경 | `cinematic_soft_painted/decimal_nis_1999/backgrounds/` 2종 | 재제작 우선 — 사진·3D형 질감과 어두운 시네마틱 렌더링 |
| 데시멀 센터 배경 | `cinematic_soft_painted/decimal/` 11종 | 재제작 우선 — 사진·3D형 재질과 공식 카툰 소프트 페인터리 문법 불일치 |
| 구형 수면동 배경 | `cinematic_soft_painted/dormitory_2000/` 2종 | 교체 또는 제거 — 구형 기관명과 사진형 렌더링 |
| 역사 프롤로그 | `historical_prologue/`의 현재 인물 3종·배경 3종 | 재제작 우선 — 하드 셀, 반실사, 사진형 배경이 혼재 |
| 은행 창구 직원 | 루트 `character_bank_clerk_*_v2.png` 4종 | 재제작 우선 — 반실사 에어브러시, 플라스틱 피부와 성인 비율 과장 |
| 서하늘 공인중개사 | 루트 `character_realtor_*_v1.png` 6종 | 재제작 우선 — 3D형 광택, 과밀 장식과 공식 렌더링 문법 불일치 |
| 부동산 배경 | `real_estate/` 9종 | 보정 필요 — 후반 자산으로 갈수록 사진·건축 CG 인상이 강함 |
| 생활 공간 배경 | `gameplay_map/`의 방·주방·거실 9종 | 대체로 유지 — 카툰 소프트 페인터리 범위, 세트 간 색온도 보정 필요 |
| 라이더 코스 배경 | `gameplay_map/bg_minigame_rider_*` 2종 | 재제작 우선 — 실사 사진형 경기장 렌더링. 픽셀 오브젝트 예외와도 불일치 |
| 1981 정책 자산 | `cinematic_soft_painted/policy_1981/` 인물 22종·배경 2종 | 제거 또는 격리 — 현재 서사 미참조이며 반실사 구형 화풍 |
| 타이틀 일러스트 | `title_elementary_landlord_portrait_v2.png` | 보정 필요 — 강한 대비·굵은 선·광고형 합성 밀도가 공식 루미너스 톤과 다름 |
| 픽셀 미니게임 | `minigames/` 6종 | 예외 통과 — `PROJECT_GUIDE.md`가 허용한 조작형 미니게임 전용 16비트 예외 |

## 승인·재제작 검사

- 다른 여학생과 얼굴 골격·눈·코·입·턱선 중 최소 네 축이 뚜렷하게 다른가
- 얼굴을 가린 전신 실루엣에서도 키·어깨·몸통·팔다리·체중 중심이 구분되는가
- 해당 인물의 얼굴·머리·체형이 포즈마다 유지되는가
- 고개·시선·손동작·체중 이동·머리카락 관성이 장면별로 다른가
- 복부를 가리는 흰 반소매 셔츠, 빨간 체크 넥타이·치마, 맨발 산호분홍 통풍
  클로그가 정확한가
- 전신, 양손, 신발과 소품이 잘리지 않았는가
- 투명 가장자리와 크로마 잔색이 깨끗한가

승인되지 않은 이미지는 저장소 후보 폴더에 쌓지 않고 외부 임시 작업 공간에서
폐기한다.
