# 실제 경영진 데이터와 캐릭터 자산

이 문서는 다른 환경에서도 실제 인물의 재임 기간, 직책, 초상 자산과 출처를 바로 이어서 관리하기 위한 기준입니다.

## 구현 원칙

- 게임 날짜에 재임 중인 인물만 보여 미래 인사 정보를 누출하지 않습니다.
- 회장과 CEO가 다른 경우 같은 직책처럼 합치지 않습니다. 삼성전자는 이건희 회장과 윤종용 CEO를 별도 카드로 표시합니다.
- 인물 이름과 재임 직책은 실제 기록이며 게임 속 대사, 성격 수치, 판단과 결과는 창작임을 화면에 표시합니다.
- 초상은 사진 복제가 아니라 식별 가능한 특징만 남긴 밝은 캐주얼 2D 캐릭터입니다.
- 모든 인물은 세로 2:3, 가슴~허리 위 상반신, 선화와 2~3단 셀 명암, 크림·하늘색 배경을 사용합니다.
- 로고, 문구, 워터마크, 현대 기기, 전신, 실사 피부와 무거운 기념 초상화 질감은 넣지 않습니다.
- 프로젝트 자산은 600×900 WebP로 최적화합니다. 원본 생성본은 앱 번들에 포함하지 않습니다.

## 첫 경영진 팩

범위는 게임 시작일인 2000-01-01에 보이는 핵심 10개 회사의 12명과 2000-01-13 Microsoft CEO 이양입니다.

| 회사 | 실제 인물 | 시작 시점 직책 | 초상 파일 |
| --- | --- | --- | --- |
| 삼성전자 | 이건희 | 회장 | lee_kun_hee.webp |
| 삼성전자 | 윤종용 | 대표이사 사장·CEO | yun_jong_yong.webp |
| Apple | Steve Jobs | 임시 CEO, 2000-01-05부터 CEO | steve_jobs.webp |
| Microsoft | Bill Gates | 회장·CEO, 2000-01-13부터 회장·최고 소프트웨어 설계자 | bill_gates.webp |
| Microsoft | Steve Ballmer | 2000-01-13부터 사장·CEO | steve_ballmer.webp |
| Cisco | John T. Chambers | 사장·CEO | john_chambers.webp |
| Toyota | Fujio Cho | 사장 | fujio_cho.webp |
| Sony | Nobuyuki Idei | 회장·CEO | nobuyuki_idei.webp |
| SoftBank | Masayoshi Son | 사장·CEO | masayoshi_son.webp |
| SK텔레콤 | 조정남 | 대표이사 사장 | cho_jung_nam.webp |
| 포항제철 | 유상부 | 이사회 의장·CEO | yoo_sang_boo.webp |
| 현대자동차 | 정몽구 | 회장·CEO | chung_mong_koo.webp |

경영진 기간과 화면 조회 코드는 flutter_app/lib/game/historical_executives.dart, 초상은 flutter_app/assets/images/executives/에 있습니다.

## 1차 출처

- 삼성전자: [Samsung Electronics 2005 Annual Report](https://images.samsung.com/is/content/samsung/p5/co/aboutsamsung/2005_E.pdf)
- Apple: [Steve Jobs Resigns as CEO of Apple](https://www.apple.com/sg/newsroom/2011/08/24Steve-Jobs-Resigns-as-CEO-of-Apple/)
- Microsoft: [Microsoft Company Facts](https://news.microsoft.com/facts-about-microsoft/), [Microsoft 2000 Annual Report](https://www.microsoft.com/investor/reports/ar00/lts.htm)
- Cisco: [Cisco 2000 Annual Report](https://www.cisco.com/c/dam/en_us/about/ac49/ac20/downloads/annualreport/ar2000/pdf/Cisco_00_AR.pdf)
- Toyota: [Executive Changes](https://global.toyota/en/detail/249266)
- Sony: [Corporate Executive Appointments](https://www.sony.com/en/SonyInfo/News/Press_Archive/199906/99-057/)
- SoftBank: [SoftBank 2000 Annual Report](https://group.softbank/system/files/pdf/ir/financials/annual_reports/annual-report_fy2000_01_en.pdf)
- SK텔레콤: [2000 Leadership Release](https://www.sktelecom.com/en/press/press_detail.do?idx=131)
- 포항제철: [2001 Environmental Progress Report](https://www.posco.com/homepage/docs/eng6/jsp/dn/irinfo/2001_environment_en.pdf)
- 현대자동차: [Mong-Koo Chung Profile](https://www.hyundai.com/content/hyundai/worldwide/en/newsroom/detail/hyundai-motor-group-honorary-chairman-mong-koo-chung-inducted-into-automotive-hall-of-fame-at-official-ceremony-0000000496.html)

## 화면과 검증

- 종목 상세의 그날의 경영진 영역은 현재 게임 날짜를 배지로 표시합니다.
- 카드에는 카툰 상반신, 실제 이름, 영문명, 직책, 재임 기간과 역할 설명을 표시합니다.
- historical_executives_test.dart는 삼성 회장·CEO 분리와 Microsoft 2000-01-13 이양을 검증합니다.
- widget_test.dart는 삼성전자 상세에서 두 인물과 초상 자산이 표시되는지 검증합니다.

## 다음 팩을 추가하는 순서

1. 공식 연차보고서나 회사 보도자료에서 정확한 취임일과 퇴임일을 확인합니다.
2. HistoricalExecutive 레코드를 기간이 겹치지 않게 추가합니다.
3. 동일한 카툰 상반신 프롬프트로 WebP 초상을 추가합니다.
4. 미래 시점 이전에 새 인물 이름이 노출되지 않는 날짜 테스트를 추가합니다.
5. flutter analyze, flutter test, flutter build web --release를 실행합니다.

2000년 이후 교체 경영진은 아직 전부 제작하지 않았습니다. 해당 연도 콘텐츠를 출시하기 전에 Toyota 2005, Sony 2005, 삼성 2008, POSCO 2003, SK텔레콤 2000년 12월 이후 순으로 다음 팩을 보강합니다.
