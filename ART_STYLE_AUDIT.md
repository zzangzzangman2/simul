# SIMUL 런타임 이미지 승인표

최종 갱신: 2026-08-02

이 문서는 현재 승인된 자산만 기록한다. 후보·폐기 이력은 남기지 않는다.

## 단일 화풍

- 공식명: `SIMUL production soft-painted VN anime v1`
- 화풍 앵커: `art_references/simul_production_soft_painted_vn_style_anchor_v1.png`
- 생성 규칙: `IMAGE_GENERATION_STYLE_PROMPT.md`, `ART_STYLE_GUIDE.md`
- 신규 캐릭터는 실사·사진 합성·3D·치비가 아니라 위 화풍을 사용한다.

## 여학생 승인 자산

| 인물 | 정체성 앵커 | 런타임 세트 |
| --- | --- | --- |
| 김서아 | `kim_seoa_identity_anchor_v1.png` | `production_soft_painted/kim_seoa/` 9종 |
| 이지안 | `lee_jian_face_identity_anchor_v2.png`, `lee_jian_identity_anchor_v2.png` | `production_soft_painted/lee_jian/` v2 9종 |
| 최이서 | `choi_iseo_identity_anchor_v1.png` | `production_soft_painted/choi_iseo/` 9종 |
| 정아린 | `jung_arin_identity_anchor_v1.png` | `production_soft_painted/jung_arin/` 9종 |
| 박하은 | `park_haeun_identity_anchor_v1.png` | `production_soft_painted/park_haeun/` 9종 |
| 한수아 | 공식 화풍 앵커와 런타임 중립 포즈 | `production_soft_painted/han_sua/` quality v2 8종 |
| 오지우 | `oh_jiwoo_identity_anchor_v1.png` | `production_soft_painted/oh_jiwoo/` 9종 |
| 윤채아 | `yoon_chaea_identity_anchor_v1.png` | `production_soft_painted/yoon_chaea/` 9종 |

위 경로는 모두 `flutter_app/assets/images/` 기준이다. 편집기와 프롤로그는 이
파일들만 인물별 승인 포즈로 사용한다.

## 다른 현행 자산군

| 자산군 | 경로·기준 |
| --- | --- |
| 주인공 성준 | `flutter_app/assets/images/protagonist_seed01/` 24종(호환 경로) |
| 한서윤 운영관 | `flutter_app/assets/images/주식선생님/`의 코드 연결 포즈(호환 경로) |
| 1981년 정책실 | `cinematic_soft_painted/policy_1981/` |
| 데시멀 센터 | `cinematic_soft_painted/decimal/` 신규 배경 11종 |
| 역사 프롤로그 | `historical_prologue/`의 코드 연결 자산 |
| 서하늘 공인중개사 | `character_realtor_*_v1.png` 6종 |

## 승인 검사

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
