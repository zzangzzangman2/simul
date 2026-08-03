import 'game_state.dart';
import 'market_clock.dart';
import 'relationship_state.dart';

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
  });

  final DateTime date;
  final String title;
  final String body;
  final String markerLabel;
  final LifeCalendarEventKind kind;
  final int accentValue;
  final String? imageAsset;
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
    );
  }
}

/// 날짜가 확정된 장기 이벤트는 여기에 제목·본문·그림 경로를 추가한다.
/// 현재 날짜보다 미래인 항목은 달력에 노출되지 않는다.
const authoredLifeCalendarEvents = <LifeCalendarEventDefinition>[
  LifeCalendarEventDefinition(
    dateKey: '2000-01-03',
    title: '데시멀 첫 거래일',
    body: '열 명이 각자 50,000원 국가계좌의 첫 판단을 장부에 남긴 날.',
    markerLabel: '첫 거래',
    kind: LifeCalendarEventKind.milestone,
    accentValue: 0xFFFFB84D,
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
  if (isWeekendOutingDay(date)) return '주말 · 외출 가능';
  if (!isMarketTradingDay(date)) return '휴장일 · 생활 시간';
  return '정규 거래일 · 09:00~15:00';
}
