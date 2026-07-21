# MILLENNIUM CAPITAL Flutter

밝고 캐주얼한 2D 모바일 투자회사 경영 게임의 새 주 구현입니다. 기존 React 앱은 시장·거래·인수 로직과 저장 데이터의 기준 구현으로 저장소 루트에 보존합니다.

## 현재 구현

- 10살 소년 주인공이 등장하는 회사명 온보딩
- 초기 조건: 2000-01-01, 현금 0원, 가족 투자연구소
- 회사명과 날짜의 기기 로컬 저장·복원
- 캐주얼 2D 사무실 홈
- 컴퓨터, 전화, 서류함 진입점
- 하루 단위 진행
- Android와 Web 프로젝트

## 실행

```bash
flutter pub get
flutter run -d chrome
```

Android 기기 또는 에뮬레이터가 연결되어 있다면 다음 명령을 사용합니다.

```bash
flutter run
```

## 검증

```bash
flutter analyze
flutter test
flutter build web --release
```

위젯 테스트는 `390×844`와 `360×800` 화면에서 온보딩 레이아웃이 넘치지 않는지 확인합니다.

## 주요 파일

| 경로 | 역할 |
| --- | --- |
| `lib/main.dart` | 앱 상태, 온보딩, 사무실 홈과 저장 |
| `assets/images/hero-boy.png` | 소년 주인공 투명 PNG |
| `test/widget_test.dart` | 온보딩, 저장 복원과 모바일 화면 검증 |

## 다음 이관 작업

1. 루트의 `app/data/market-history.json`을 Flutter 자산으로 등록
2. 거래일·휴장일 가격 조회 모델과 테스트 작성
3. 컴퓨터 버튼에서 1열 종목 목록 열기
4. 거래 바텀시트와 매수·매도 상태 이관
5. React 저장 스키마 버전 3 마이그레이션

기존 저장 데이터를 Flutter 앱에서 읽는 마이그레이션이 완성되기 전에는 기존 React 배포를 교체하지 않습니다.
