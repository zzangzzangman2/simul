import 'game_state.dart';
import 'market_clock.dart';
import 'relationship_state.dart';
import 'weekend_activity.dart';

const decimalCohortBirthYear = 1987;
const decimalGrowthCalendarStartYear = 2000;
const decimalGrowthCalendarAgeTwentyYear = 2006;

enum LifeCalendarEventKind { milestone, relationship, outing, market, personal }

class LifeCalendarEvent {
  const LifeCalendarEvent({
    required this.date,
    required this.title,
    required this.body,
    required this.markerLabel,
    required this.kind,
    required this.accentValue,
    this.imageAsset,
    this.isAuthored = false,
  });

  final DateTime date;
  final String title;
  final String body;
  final String markerLabel;
  final LifeCalendarEventKind kind;
  final int accentValue;
  final String? imageAsset;
  final bool isAuthored;
}

class LifeCalendarEventDefinition {
  const LifeCalendarEventDefinition({
    required this.dateKey,
    required this.title,
    required this.body,
    required this.markerLabel,
    required this.kind,
    required this.accentValue,
    this.imageAsset,
  });

  final String dateKey;
  final String title;
  final String body;
  final String markerLabel;
  final LifeCalendarEventKind kind;
  final int accentValue;
  final String? imageAsset;

  LifeCalendarEvent materialize() {
    final parts = dateKey.split('-').map(int.parse).toList(growable: false);
    return LifeCalendarEvent(
      date: DateTime(parts[0], parts[1], parts[2]),
      title: title,
      body: body,
      markerLabel: markerLabel,
      kind: kind,
      accentValue: accentValue,
      imageAsset: imageAsset,
      isAuthored: true,
    );
  }
}

const _calendarLounge =
    'assets/images/cinematic_soft_painted/decimal/bg_decimal_living_lounge_1999_v1.png';
const _calendarArchive =
    'assets/images/cinematic_soft_painted/decimal/bg_decimal_records_archive_2000_v1.png';
const _calendarTradingFloor =
    'assets/images/cinematic_soft_painted/decimal/bg_decimal_trading_floor_dawn_2000_v1.png';
const _calendarWorkshop =
    'assets/images/cinematic_soft_painted/decimal/bg_decimal_electronics_workshop_2000_v1.png';
const _calendarLibrary =
    'assets/images/cinematic_soft_painted/decimal_weekend/bg_weekend_public_library_2000_v1.png';

/// 날짜가 확정된 장기 이벤트는 여기에 제목·본문·그림 경로를 추가한다.
/// 현재 날짜보다 미래인 항목은 `lifeCalendarEventsForState`가 걸러내므로 달력에
/// 노출되지 않는다. 프롤로그가 남긴 실마리를 날짜가 지나면서 하나씩 닫는 용도이며,
/// 가격·사건 결과 같은 미래 정보는 본문에 쓰지 않는다.
const authoredLifeCalendarEvents = <LifeCalendarEventDefinition>[
  LifeCalendarEventDefinition(
    dateKey: '2000-01-03',
    title: '데시멀 첫 거래일',
    body: '열 명이 각자 50,000원 국가계좌의 첫 판단을 장부에 남긴 날.',
    markerLabel: '첫 거래',
    kind: LifeCalendarEventKind.milestone,
    accentValue: 0xFFFFB84D,
    imageAsset: _calendarTradingFloor,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2000-01-05',
    title: '첫 안건: 너무 빨리 정한 일',
    body:
        '아린이 자리 배치를 4분에 끝낸 걸 안건으로 올렸다. 이서가 손을 들려다 말았던 이유를 '
        '말하고, 열 명은 다음부터 결정 뒤에 한 사람씩 이름을 불러 확인하기로 정했다.',
    markerLabel: '첫 안건',
    kind: LifeCalendarEventKind.personal,
    accentValue: 0xFF7C9CD6,
    imageAsset: _calendarLounge,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2000-01-07',
    title: '검산 규칙이 장부에 들어갔다',
    body:
        '학준이 주문 전 최악 손실을 먼저 적는 칸을 원장에 만들었다. 처음엔 번거롭다고 했지만 '
        '그 칸을 비운 사람의 손실이 더 컸다는 걸 아무도 반박하지 못했다.',
    markerLabel: '검산',
    kind: LifeCalendarEventKind.market,
    accentValue: 0xFF5D7FA3,
    imageAsset: _calendarTradingFloor,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2000-01-10',
    title: '첫 주 장부 대조',
    body:
        '서아가 열 권의 장부를 나란히 놓고 첫 주를 맞췄다. 수익이 아니라 적지 않은 칸이 몇 개인지를 '
        '먼저 셌고, 빈 칸이 가장 적은 사람은 1등이 아니었다.',
    markerLabel: '주간 대조',
    kind: LifeCalendarEventKind.milestone,
    accentValue: 0xFFEFA45C,
    imageAsset: _calendarLounge,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2000-01-14',
    title: '시계 다섯 개가 같아졌다',
    body:
        '지안이 트레이딩 플로어 시계를 전부 맞췄다. 소유자 확인과 전원 차단, 두 명 입회까지 지켜서 '
        '이번에는 아무도 놀라지 않았다. 순서가 규칙이 된 첫 사례로 기록됐다.',
    markerLabel: '정비',
    kind: LifeCalendarEventKind.personal,
    accentValue: 0xFF8FA9B8,
    imageAsset: _calendarWorkshop,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2000-01-21',
    title: '수아의 소문 공책',
    body:
        '수아가 사람들이 어느 회사 이름을 어디서 처음 꺼내는지 적기 시작했다. 채아가 그 공책에 '
        '언제 들었는지 칸을 하나 더 그었다. 먼저 듣는 것과 먼저 아는 것은 다르다고.',
    markerLabel: '소문 공책',
    kind: LifeCalendarEventKind.market,
    accentValue: 0xFFE58BA8,
    imageAsset: _calendarLounge,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2000-01-31',
    title: '첫 달 결산',
    body:
        '한서윤이 첫 달 환수금과 자립적립금을 각각 읽어 줬다. 번 사람도 잃은 사람도 있었지만 '
        '밥과 잠자리는 그대로였다. 계약서 첫 장이 사실이라는 게 확인된 날.',
    markerLabel: '월 결산',
    kind: LifeCalendarEventKind.milestone,
    accentValue: 0xFFFFB84D,
    imageAsset: _calendarLounge,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2000-02-25',
    title: '창고에 남아 있던 1996년 종이',
    body:
        '서아가 기록 보관실에서 폐기로 적혀 있던 1996년 시험지를 찾았다. 세 해 전 종이 규격이 '
        '왜 달랐는지 드디어 맞아떨어졌고, 도윤석은 기록을 고치는 대신 발견자 이름을 적었다.',
    markerLabel: '1996년',
    kind: LifeCalendarEventKind.milestone,
    accentValue: 0xFF9C8AC7,
    imageAsset: _calendarArchive,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2000-03-24',
    title: '경계가 규정이 됐다',
    body:
        '이서가 말한 “먼저 물어보기”가 센터 생활 규정 3조로 들어갔다. 고치는 사람과 주인이 '
        '같이 보는 조항이라 지안이 가장 먼저 서명했다.',
    markerLabel: '생활 규정',
    kind: LifeCalendarEventKind.personal,
    accentValue: 0xFFC98A8A,
    imageAsset: _calendarLounge,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2000-04-14',
    title: '모른다고 말할 권리',
    body:
        '하은이 “모른다고 답한 사람을 창피하게 만들지 않기”를 회의 규칙에 넣자고 했다. '
        '그 주부터 확인되지 않은 정보가 회의에 올라오는 횟수가 늘었다.',
    markerLabel: '회의 규칙',
    kind: LifeCalendarEventKind.personal,
    accentValue: 0xFFE0A3C4,
    imageAsset: _calendarLounge,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2000-06-30',
    title: '상반기 감사',
    body:
        '조민경이 반년 치 기록을 열람했다. 확인한 건 수익률이 아니라 중단권을 쓴 사람이 있었는지, '
        '그때 아무도 불이익을 받지 않았는지였다.',
    markerLabel: '감사',
    kind: LifeCalendarEventKind.milestone,
    accentValue: 0xFF7FA88B,
    imageAsset: _calendarArchive,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2000-09-01',
    title: '깨지는 조건 게시판',
    body:
        '채아가 라운지 벽에 가설과 함께 “이 가설이 틀리는 조건”을 붙이는 칸을 만들었다. '
        '오지우가 가장 많이 붙였고, 가장 많이 지운 것도 그였다.',
    markerLabel: '가설 게시판',
    kind: LifeCalendarEventKind.market,
    accentValue: 0xFF6E86B8,
    imageAsset: _calendarLounge,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2000-12-29',
    title: '첫 해가 닫혔다',
    body:
        '2000년 마지막 거래일. 열 명의 장부 첫 권이 다 찼다. 아무도 첫 장의 50,000원을 '
        '지우지 않았고, 서아는 마지막 줄 아래에 다음 권 번호만 적었다.',
    markerLabel: '첫 해 마감',
    kind: LifeCalendarEventKind.milestone,
    accentValue: 0xFFFFB84D,
    imageAsset: _calendarTradingFloor,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2001-04-16',
    title: '15살, 두 번째 봄',
    body:
        '프로젝트 재가동 2주년. 한규진은 여전히 수익률보다 중단권을 먼저 보고받았다. '
        '열 명 중 누구도 아직 나가지 않았다는 문장이 보고서 첫 줄이었다.',
    markerLabel: '2주년',
    kind: LifeCalendarEventKind.milestone,
    accentValue: 0xFF9C8AC7,
    imageAsset: _calendarArchive,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2002-01-04',
    title: '16살, 장부가 두 권이 됐다',
    body:
        '두 번째 장부의 첫 장에는 원금이 아니라 지난 두 해의 최대 낙폭이 적혔다. '
        '학준이 제안하고 채아가 계산했다.',
    markerLabel: '16살',
    kind: LifeCalendarEventKind.milestone,
    accentValue: 0xFF5D7FA3,
    imageAsset: _calendarLibrary,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2003-01-06',
    title: '17살, 각자의 방식이 갈렸다',
    body:
        '같은 종목을 열 명이 서로 다른 이유로 보기 시작했다. 아린은 순서를, 이서는 결을, '
        '지우는 반례를 봤고 아무도 남의 방식을 고치라고 하지 않았다.',
    markerLabel: '17살',
    kind: LifeCalendarEventKind.personal,
    accentValue: 0xFFEFA45C,
    imageAsset: _calendarTradingFloor,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2004-01-05',
    title: '18살, 밖의 숫자를 보기 시작했다',
    body:
        '센터 밖 임대료와 상권 이야기가 회의에 올라왔다. 국가계좌 밖으로 판단을 넓히는 첫 해로 '
        '기록됐고, 한서윤은 계약서에 새 장을 붙였다.',
    markerLabel: '18살',
    kind: LifeCalendarEventKind.milestone,
    accentValue: 0xFF7FA88B,
    imageAsset: _calendarLounge,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2005-01-04',
    title: '19살, 책임의 크기가 바뀌었다',
    body:
        '이제 한 사람의 판단이 다른 아홉 명의 장부에도 숫자로 남는다. 하은이 “먼저 말하기”를 '
        '규정 1조로 올리자고 다시 제안했다.',
    markerLabel: '19살',
    kind: LifeCalendarEventKind.milestone,
    accentValue: 0xFFE0A3C4,
    imageAsset: _calendarLounge,
  ),
  LifeCalendarEventDefinition(
    dateKey: '2006-01-04',
    title: '20살, 첫 장의 50,000원',
    body:
        '성인이 된 첫 거래일. 첫 장부의 첫 줄을 다시 펼쳐 본 사람이 여러 명이었다. '
        '그 줄에는 아직 아무 수익률도 적혀 있지 않았다.',
    markerLabel: '20살',
    kind: LifeCalendarEventKind.milestone,
    accentValue: 0xFFFFB84D,
    imageAsset: _calendarArchive,
  ),
];

int decimalKoreanAge(DateTime date) => date.year - decimalCohortBirthYear + 1;

double decimalGrowthCalendarProgress(DateTime date) {
  final elapsed = date.year - decimalGrowthCalendarStartYear;
  final span =
      decimalGrowthCalendarAgeTwentyYear - decimalGrowthCalendarStartYear;
  if (span <= 0) return 1;
  return (elapsed / span).clamp(0, 1).toDouble();
}

bool isSameCalendarDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

bool isSameCalendarMonth(DateTime left, DateTime right) =>
    left.year == right.year && left.month == right.month;

bool isWeekendOutingDay(DateTime date) => relationshipOutingAvailableOn(date);

DateTime calendarMonthStart(DateTime date) => DateTime(date.year, date.month);

DateTime previousCalendarMonth(DateTime date) =>
    DateTime(date.year, date.month - 1);

DateTime nextCalendarMonth(DateTime date) =>
    DateTime(date.year, date.month + 1);

List<DateTime?> lifeCalendarMonthCells(DateTime month) {
  final first = calendarMonthStart(month);
  final firstOffset = first.weekday - DateTime.monday;
  final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
  return List<DateTime?>.generate(42, (index) {
    final day = index - firstOffset + 1;
    if (day < 1 || day > daysInMonth) return null;
    return DateTime(first.year, first.month, day);
  }, growable: false);
}

List<LifeCalendarEvent> lifeCalendarEventsForState(GameState state) {
  final currentDate = state.currentDate;
  final events = <LifeCalendarEvent>[
    for (final definition in authoredLifeCalendarEvents)
      if (!definition.materialize().date.isAfter(currentDate))
        definition.materialize(),
  ];

  for (final memory in state.relationships.memories) {
    if (memory.activity == RelationshipActivity.gift) continue;
    final date = state.dateForDay(memory.day);
    if (date.isAfter(currentDate)) continue;
    final profile = cohortGirlProfileById(memory.girlId);
    if (profile == null) continue;
    final outing = memory.activity == RelationshipActivity.date;
    final deltaLabel = memory.affectionDelta > 0
        ? '+${memory.affectionDelta}'
        : '${memory.affectionDelta}';
    events.add(
      LifeCalendarEvent(
        date: date,
        title: outing ? '${profile.name}와 주말 외출' : '${profile.name}와 나눈 이야기',
        body:
            '${profile.name}의 방식으로 하루를 기록했다. '
            '호감도 $deltaLabel · 현재 ${memory.affectionAfter}.',
        markerLabel: outing ? '외출' : '대화',
        kind: outing
            ? LifeCalendarEventKind.outing
            : LifeCalendarEventKind.relationship,
        accentValue: profile.accentValue,
        imageAsset: profile.portraitAsset,
      ),
    );
  }

  for (final log in weekendActivityLogsForState(state)) {
    final date = state.dateForDay(log.day);
    if (date.isAfter(currentDate)) continue;
    events.add(
      LifeCalendarEvent(
        date: date,
        title: log.title,
        body: log.body,
        markerLabel: log.markerLabel,
        kind: log.kind == WeekendActivityKind.gift
            ? LifeCalendarEventKind.relationship
            : LifeCalendarEventKind.personal,
        accentValue: log.accentValue,
        imageAsset: log.imageAsset,
      ),
    );
  }

  events.sort((left, right) {
    final dateOrder = left.date.compareTo(right.date);
    if (dateOrder != 0) return dateOrder;
    return left.kind.index.compareTo(right.kind.index);
  });
  return List<LifeCalendarEvent>.unmodifiable(events);
}

List<LifeCalendarEvent> lifeCalendarEventsOn(
  Iterable<LifeCalendarEvent> events,
  DateTime date,
) => events
    .where((event) => isSameCalendarDay(event.date, date))
    .toList(growable: false);

String lifeCalendarDayStatus(DateTime date) {
  if (isWeekendOutingDay(date)) return '주말 · 행동력 2 · 외출 가능';
  if (!isMarketTradingDay(date)) return '휴장일 · 생활 시간';
  return '정규 거래일 · 09:00~15:00';
}
