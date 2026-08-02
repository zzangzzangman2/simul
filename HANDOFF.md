# 현재 구현 핸드오프

## 기준

- 제품명: `10대부터 건물주`
- 세계관 정본: `DECIMAL_WORLD.md`
- 대사 정본: `flutter_app/assets/dialogue/dialogue-editor-override.json`
- 현재 대사 버전: content 2 / appearance 14 / 292장면

## 프롤로그

8개 장으로 연결돼 있다.

1. 1981년 자본전 선언
2. 정답형 설계의 실패와 1997년 외환위기
3. 1999년 숨은 규칙 시험
4. 불공정 배분 게임
5. 결핍·욕망·종료권 시험
6. 1999년 12월 강남 센터 도착과 열 명 자기소개
7. 침상·사물함·개인 물건·생활 경계·첫 갈등·밥솥 사건·첫날 밤
8. 2000년 1월 3일 50,000원 장부와 트레이딩 플로어, 주식실습 PC

성준·김학준과 여자 동기 8명 모두 최소 5회 이상 말한다. 한서윤은 교사가 아닌
운영관이며 선발관·경제수석·시설관리관 등 엑스트라도 고유 역할과 말투가 있다.

## 이미지

- 신규 세로 배경 11종은
  `flutter_app/assets/images/cinematic_soft_painted/decimal/`에 있다.
- IMF 실패, 숨은 규칙 시험, 불공정 게임, 욕망 시험, 강남 외관, 보안 입구,
  생활 라운지, 수면동, 트레이딩 플로어, 기록 보관실, 기기 정비실을 포함한다.
- 전부 ImageGen 생성 9:16 자산이며 실제 크기는 941×1672다.
- 여자 동기 8명은 기존 승인 정체성 자산을 그대로 사용한다.

## 런타임 연결

- 신규 저장은 `StoryState.newDecimalPlayer`로 시작한다.
- 기본 이름은 성준이며 데시멀 플래그·10인 구성·강남 센터·국가 기금 소유권을 저장한다.
- 프롤로그 완료 후 PC 전원 → 데시멀 주식실습 앱 → 선택형 투자노트 → 모의 주문
  리허설 → 정식 50,000원 자유 플레이로 이어진다.
- 생활 허브의 라운지·트레이딩 플로어·기기 정비실·기록 보관실은 새 배경을 쓴다.

## 호환

옛 세계관 파일명과 `academy`, `orientation`, `cohort`, `seed` 같은 내부 식별자 일부는
구형 저장·테스트 호환 때문에 남아 있다. 사용자 화면과 새 데이터에는 옛 설정을
노출하지 않는다. `ORPHANAGE_STORY_REBOOT.md`와 `PROTAGONIST_AGE_LINE.md`는 폐기 안내
문서이며 새 구현 근거로 사용하지 않는다.

## 검증

```powershell
pnpm run dialogue:sync
pnpm run lint
pnpm test
pnpm run build:release
```

Flutter는 analyze와 `flutter_app/test/*.dart` 파일별 테스트를 실행한다. 대사 편집기
빌드는 `DIALOGUE_BUILD_ENABLED=1`과 `DIALOGUE_BUILD_TOKEN`이 모두 있어야 한다.
