# SIMUL 런타임 이미지 승인표

최종 갱신: 2026-08-03

이 문서는 현재 런타임 연결과 새 화풍 재제작 상태를 함께 기록한다. 여자 동기 8명의
정체성 앵커 승인과 `SIMUL polished soft-render VN anime v3` 화풍 통과는 별도 판정이다.
`재제작`·`보정 필요` 자산은 교체 전까지 런타임에 남아 있을 수 있지만 신규 생성의
화풍 참조로 사용하지 않는다.

## 단일 화풍

- 공식명: `SIMUL polished soft-render VN anime v3`
- 사용자 승인 정식 화풍 앵커:
  `art_references/simul_polished_soft_render_vn_style_anchor_v3.png`
  (승인·적용된 한수아 중립 전신과 동일한 픽셀)
- 생성 규칙: `IMAGE_GENERATION_STYLE_PROMPT.md`, `ART_STYLE_GUIDE.md`
- 구형 v2 공통 앵커는 삭제했으며 복원하거나 신규 생성의 화풍 참조로 사용하지 않는다.
- 기존 외형 보존 대상은 여자 동기 8명뿐이다. 그 밖의 인물은 역할·나이·성격·장면
  기능만 이어받아 새 v3 디자인으로 교체한다.

## 여학생 런타임 연결·화풍 재검수

| 인물 | 정체성 앵커 | 현행 런타임 세트 | v3 재제작 판정 |
| --- | --- | --- | --- |
| 김서아 | `kim_seoa_identity_anchor_v1.png` | `production_soft_painted/kim_seoa/` 9종 | 대기 — 얼굴·헤어·체형·의상·포즈를 유지하고 화풍만 v3로 재생성 |
| 이지안 | `lee_jian_face_identity_anchor_v2.png`, `lee_jian_identity_anchor_v2.png` | `production_soft_painted/lee_jian/` v2 9종 | 대기 — 보이는 승인 얼굴 앵커를 우선하고 문서·런타임 외형 충돌은 재생성 전에 별도 확인 |
| 최이서 | `choi_iseo_identity_anchor_v1.png` | `production_soft_painted/choi_iseo/` 9종 | 대기 — 얼굴·헤어·체형·의상·포즈를 유지하고 화풍만 v3로 재생성 |
| 정아린 | `jung_arin_identity_anchor_v1.png` | `production_soft_painted/jung_arin/` 기존 9종 | **승인 대기** — 2026-08-03 얼굴·헤어·체형·의상·포즈 보존 v3 후보 9종 생성. 런타임 미적용 |
| 박하은 | `park_haeun_face_identity_anchor_v2.png`, `park_haeun_identity_anchor_v2.png` | `production_soft_painted/park_haeun/` v2 9종 | 대기 — 구형 v2 화풍 통과 이력은 종료. 기존 얼굴·헤어·체형·의상·포즈 유지 |
| 한수아 | `han_sua_identity_anchor_v3.png`(1차 전신), `han_sua_face_identity_anchor_v3.png`(2차 얼굴 크롭) | `production_soft_painted/han_sua/` 새 v3 9종 | **완료·적용** — 2026-08-03 사용자 승인. 구형 9종 제거 후 런타임 교체 |
| 오지우 | `oh_jiwoo_identity_anchor_v1.png` | `production_soft_painted/oh_jiwoo/` 9종 | 대기 — 얼굴·헤어·체형·의상·포즈를 유지하고 화풍만 v3로 재생성 |
| 윤채아 | `yoon_chaea_identity_anchor_v1.png` | `production_soft_painted/yoon_chaea/` 9종 | 대기 — 얼굴·헤어·체형·의상·포즈를 유지하고 화풍만 v3로 재생성 |

위 경로는 모두 `flutter_app/assets/images/` 기준이다. 현재 편집기와 프롤로그는
이 파일들을 사용하지만, 전부 교체 전 임시 런타임 연결이다. 여자 8명의 현행 파일은
정체성·포즈 입력으로만 사용하고 신규 제작의 화풍 참조로 사용하지 않는다.

한수아의 얼굴 크롭은 얼굴 비율 확인용이다. 크롭에 보이는 `1/2` UI, 손, 파란
천·레이스는 승인 정체성에 포함하지 않는다.

## 비보존 인물·다른 현행 자산군

아래 인물 자산은 기존 얼굴·헤어·체형·의상 보존 대상이 아니다. 서사 역할·나이·성격·
장면 기능과 꼭 필요한 소품만 유지하고 v3에 맞춰 전면 재설계한다. 청와대·정부·정책실
계열 구형 인물도 같은 규칙으로 모두 교체하며, 이미 삭제한 자산은 되살리지 않는다.

| 자산군 | 경로·기준 | 2026-08-03 화풍 판정 |
| --- | --- | --- |
| 주인공 플레이어 | `flutter_app/assets/images/protagonist_seed01/` 24종(호환 경로) | 전면 재설계 — 기존 얼굴·헤어·체형·의상 비보존 |
| 김학준 | `legacy_quarantine/character_hakjun_orientation_v2.png` | 격리 유지·전면 재설계 — 구형 자산을 정체성 참조로 사용하지 않음 |
| 한서윤 운영관 | `flutter_app/assets/images/주식선생님/`의 코드 연결 6포즈 | 전면 재설계 가능 — 기존 외형 보존 대상이 아니며 새 v3 대표 디자인부터 승인 |
| 1999년 국정원·정부 인물 | `cinematic_soft_painted/decimal_nis_1999/characters/` 6명 | 전면 재설계 — 혼재한 기존 외형을 보존하지 않음 |
| 1999년 국정원 배경 | `cinematic_soft_painted/decimal_nis_1999/backgrounds/` 2종 | 재검수 대기 — 인물 완료 뒤 별도 v3 배경 앵커로 판단 |
| 데시멀 센터 배경 | `cinematic_soft_painted/decimal/` 11종 | 재검수 대기 — 인물 완료 뒤 별도 v3 배경 앵커로 판단 |
| 은행 창구 직원 | 루트 `character_bank_clerk_*_v2.png` 4종 | 전면 재설계 — 기존 외형 보존 대상 아님 |
| 서하늘 공인중개사 | 루트 `character_realtor_*_v1.png` 6종 | 전면 재설계 — 기존 얼굴·헤어·복장·장신구 고정 규칙 폐기 |
| 부동산 배경 | `real_estate/` 9종 | 보정 필요 — 후반 자산으로 갈수록 사진·건축 CG 인상이 강함 |
| 생활 공간 배경 | `gameplay_map/`의 방·주방·거실 9종 | 재검수 대기 — 별도 v3 배경 앵커 확정 전 판정 보류 |
| 라이더 코스 배경 | `gameplay_map/bg_minigame_rider_*` 2종 | 재제작 우선 — 실사 사진형 경기장 렌더링. 픽셀 오브젝트 예외와도 불일치 |
| 타이틀 일러스트 | `title_elementary_landlord_portrait_v2.png` | 재검수 대기 — 새 v3 인물 디자인 완료 뒤 다시 제작 판단 |
| 픽셀 미니게임 | `minigames/` 6종 | 예외 통과 — `PROJECT_GUIDE.md`가 허용한 조작형 미니게임 전용 16비트 예외 |

## 제거·격리 완료

| 처리 대상 | 2026-08-03 결과 |
| --- | --- |
| 1981 정책 자산 | 미참조 인물 22종·배경 2종, 총 24종 삭제 및 번들 선언 제거 |
| 구형 생활동 배경 | 4종 삭제. 방 화면은 `decimal/bg_decimal_sleeping_wing_1999_v1.png`, 투자·신문 화면은 `decimal/bg_decimal_trading_floor_dawn_2000_v1.png`로 치환 |
| 구형 역사 프롤로그 | 배경 10종·미참조 인물 5종 삭제. 버스 전환과 본관 앞은 현행 데시멀 외관으로 치환 |
| 김학준 호환 자산 | 실제 23개 대사 장면 때문에 1종을 `legacy_quarantine/`에 격리. 새 v3 디자인·세트 승인 뒤 삭제 |
## 승인·재제작 검사

- 여자 동기 8명은 기존 승인 얼굴과 픽셀 비교했을 때 동일인으로 즉시 읽히는가
- 여자 동기 8명은 기존 헤어·체형·의상·표정·포즈·구도를 그대로 유지했는가
- 다른 여학생과 얼굴 골격·눈·코·입·턱선 중 최소 네 축이 뚜렷하게 다른가
- 비보존 인물은 구형 부적합 외형이나 여자 8명의 얼굴을 재활용하지 않고 새로 설계됐는가
- 얼굴을 가린 전신 실루엣에서도 키·어깨·몸통·팔다리·체중 중심이 구분되는가
- 해당 인물의 얼굴·머리·체형이 포즈마다 유지되는가
- 고개·시선·손동작·체중 이동·머리카락 관성이 장면별로 다른가
- 여자 동기 8명은 복부를 가리는 흰 반소매 셔츠, 빨간 체크 넥타이·치마, 맨발
  산호분홍 통풍 클로그가 정확한가
- 전신, 양손, 신발과 소품이 잘리지 않았는가
- 투명 가장자리와 크로마 잔색이 깨끗한가

승인되지 않은 이미지는 저장소 후보 폴더에 쌓지 않고 외부 임시 작업 공간에서
폐기한다.

## 재제작 순서

1. **완료: 한수아** — 새 v3 9종 런타임 적용, 구형 세트와 구형 v2 공통 앵커 삭제
2. **승인 대기: 정아린** — 새 v3 후보 9종 생성 완료. 사용자 승인 전 런타임 미적용
3. 나머지 여자 동기 6명: 인물별 중립 1장 승인 후 각 9종 세트
4. 주인공·김학준·한서윤: 기존 외형 비보존, 새 대표 디자인 승인 후 포즈 세트
5. 국정원·정부·청와대 계열 인물, 은행원, 공인중개사와 기타 반복 NPC 전면 재설계
6. 인물 교체가 끝난 뒤 배경은 별도 v3 배경 앵커와 구도 규칙으로 재검수

완료 인물은 이 절과 위 표에 계속 누적한다. 한수아는 실제 런타임 적용까지 완료했고,
정아린은 9종 후보 생성까지 완료했지만 사용자 승인 전이라 기존 런타임을 유지한다.
