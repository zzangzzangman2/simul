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
}
