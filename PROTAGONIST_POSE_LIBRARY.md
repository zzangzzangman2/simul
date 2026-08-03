# 주인공 플레이어 전신 포즈 라이브러리

확정일: 2026-07-31

## 공통 규격

- 런타임 경로: `assets/images/protagonist_seed01/`
- 수량: **24종**
- 형식: 1024×1536 투명 PNG
- 목표 정체성: 14살 한국 남자 청소년, 검은 헝클어진 머리, 따뜻한 갈색 눈, 둥근 볼
- 현재 24종은 프롤로그와 편집기에서 사용하는 런타임 포즈다. 루트의 후보 PNG나
  미등록 포즈를 섞지 않는다.
- 센터 지급 현장복: 흰 반소매 셔츠, 빨강·검정 체크 넥타이, 남색 긴바지, 검정 로퍼
- 공통 배치: 발 하단 y=1516, 발 중심 x≈512, 네 모서리 알파 0

## 포즈 목록

| 번호 | 파일 | 표정·행동 |
| ---: | --- | --- |
| 01 | `01_neutral.png` | 편안한 중립 설명 |
| 02 | `02_cheerful_laugh.png` | 크게 웃으며 손 흔들기 |
| 03 | `03_playful_grin.png` | 장난스러운 미소, 양손 뒤로 |
| 04 | `04_curious_question.png` | 손바닥을 펴서 질문 |
| 05 | `05_surprised.png` | 눈을 크게 뜬 놀람 |
| 06 | `06_worried.png` | 두 손을 모은 걱정 |
| 07 | `07_sad_held_back.png` | 울음을 참으며 손목 잡기 |
| 08 | `08_angry_protest.png` | 손바닥을 내민 항의 |
| 09 | `09_determined.png` | 가슴 앞 작은 주먹, 결의 |
| 10 | `10_embarrassed.png` | 뒷머리를 긁는 당황 |
| 11 | `11_suspicious.png` | 팔짱을 낀 의심 |
| 12 | `12_thinking.png` | 턱을 짚은 생각 |
| 13 | `13_explaining_open_hands.png` | 양손을 펼친 설명 |
| 14 | `14_pointing_evidence.png` | 옆 자료를 가리키는 주장 |
| 15 | `15_hand_raise.png` | 얼굴 옆으로 손들기 |
| 16 | `16_hands_on_hips.png` | 양손 허리, 자신감 |
| 17 | `17_holding_badge.png` | 금속 표식 확인(호환 파일명) |
| 18 | `18_passbook_pencil.png` | 통장과 연필로 기록 |
| 19 | `19_reading_ledger.png` | 장부 읽기 |
| 20 | `20_calculating.png` | 계산기 확인 |
| 21 | `21_loss_shock.png` | 손실 통장을 본 충격 |
| 22 | `22_victory_fist.png` | 작은 주먹을 든 승리 |
| 23 | `23_farewell_wave.png` | 가슴에 손을 얹은 작별 |
| 24 | `24_protective_stance.png` | 옆 사람을 막아서는 보호 자세 |

## 현재 장면 연결

| 장면 | 포즈 |
| --- | --- |
| `decimal-044` 외 28개 장면 | 03 장난스러운 미소 |
| `decimal-156` | 13 양손을 펼친 설명 |
| `decimal-290` | 09 결의 |

24종 전체는 향후 대사 감정 태그와 행동 태그에 따라 확장 연결한다. 같은 장면에서
중립 포즈만 반복하지 않으며, 표정 변화와 함께 손·팔·어깨·체중 이동이 맞는 컷을
선택한다.
