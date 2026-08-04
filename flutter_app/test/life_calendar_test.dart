import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/life_calendar.dart';
import 'package:millennium_capital/game/relationship_state.dart';

void main() {
  const engine = GameEngine();

  test('January 2000 uses a stable Monday-first six-week grid', () {
    final cells = lifeCalendarMonthCells(DateTime(2000, 1));

    expect(cells, hasLength(42));
    expect(cells[5], DateTime(2000, 1, 1));
    expect(cells[6], DateTime(2000, 1, 2));
    expect(cells[7], DateTime(2000, 1, 3));
    expect(cells.whereType<DateTime>(), hasLength(31));
  });

  test('growth calendar labels the cohort from age 14 through age 20', () {
    expect(decimalKoreanAge(DateTime(2000, 1, 3)), 14);
    expect(decimalKoreanAge(DateTime(2006, 12, 31)), 20);
    expect(decimalGrowthCalendarProgress(DateTime(2000, 1, 3)), 0);
    expect(decimalGrowthCalendarProgress(DateTime(2006, 1, 1)), 1);
  });

  test('weekends open outings while weekdays keep the market rhythm', () {
    expect(relationshipOutingAvailableOn(DateTime(2000, 1, 8)), isTrue);
    expect(relationshipOutingAvailableOn(DateTime(2000, 1, 9)), isTrue);
    expect(relationshipOutingAvailableOn(DateTime(2000, 1, 10)), isFalse);
    expect(lifeCalendarDayStatus(DateTime(2000, 1, 8)), contains('외출'));
    expect(lifeCalendarDayStatus(DateTime(2000, 1, 10)), contains('거래일'));
  });

  test('authored and relationship events expose future art and text slots', () {
    var base = engine.createNewGame(
      '달력 기록 테스트',
      worldSeed: 'life-calendar-events',
    );
    while (base.currentDate.isBefore(DateTime(2000, 1, 3))) {
      base = base.copyWith(day: base.day + 1);
    }
    final action = engine.completeRelationshipEvening(
      base,
      girlId: 'kim_seoa',
      activity: RelationshipActivity.conversation,
      choiceId: 'rebuild_together',
    );

    final events = lifeCalendarEventsForState(action.state);
    final today = lifeCalendarEventsOn(events, action.state.currentDate);

    expect(today.any((event) => event.markerLabel == '첫 거래'), isTrue);
    final relationship = today.singleWhere(
      (event) => event.kind == LifeCalendarEventKind.relationship,
    );
    expect(relationship.title, contains('김서아'));
    expect(relationship.body, contains('호감도 +5'));
    expect(relationship.imageAsset, isNotEmpty);
  });

  test('authored timeline spreads beats past the first day', () {
    final dates = authoredLifeCalendarEvents
        .map((definition) => definition.materialize().date)
        .toList(growable: false);

    // 첫날에 몰리지 않고 2000~2006 전체에 퍼져 있어야 한다.
    expect(dates.length, greaterThanOrEqualTo(12));
    expect(
      dates.where((date) => date.isAfter(DateTime(2000, 1, 4))),
      isNotEmpty,
    );
    expect(
      dates.map((date) => date.year).toSet(),
      containsAll(<int>[2000, 2001, 2006]),
    );
    // 첫 한 달에도 여러 번 나와야 지루하지 않다.
    final firstMonth = dates.where(
      (date) => !date.isAfter(DateTime(2000, 1, 31)),
    );
    expect(firstMonth.length, greaterThanOrEqualTo(5));
    // 성장 달력 범위(2000~2006)를 벗어나지 않는다.
    for (final date in dates) {
      expect(date.year, inInclusiveRange(2000, 2006));
    }
    // 날짜와 표식이 겹치지 않는다.
    expect(dates.toSet().length, dates.length);
  });

  test('authored timeline never leaks a future beat', () {
    final state = engine
        .createNewGame('달력 연표 테스트', worldSeed: 'calendar-timeline')
        .copyWith(day: 4);
    final visible = lifeCalendarEventsForState(state);
    final currentDate = state.currentDate;

    for (final event in visible) {
      expect(
        event.date.isAfter(currentDate),
        isFalse,
        reason: '${event.title}이 현재 날짜보다 미래인데 달력에 보인다',
      );
    }
    // 2006년 항목은 2000년 시점에서 보이지 않는다.
    expect(visible.any((event) => event.date.year == 2006), isFalse);
    // 날짜가 지나면 같은 항목이 실제로 열린다.
    final later = lifeCalendarEventsForState(state.copyWith(day: 366 * 6));
    expect(later.length, greaterThan(visible.length));
    expect(later.any((event) => event.markerLabel == '20살'), isTrue);
  });

  test('authored timeline artwork points at bundled assets', () {
    for (final definition in authoredLifeCalendarEvents) {
      final asset = definition.imageAsset;
      expect(asset, isNotNull, reason: '${definition.title}에 그림이 없다');
      expect(asset, startsWith('assets/images/'));
      expect(
        File(asset!).existsSync(),
        isTrue,
        reason: '${definition.title}의 그림 파일이 없다: $asset',
      );
    }
  });
}
