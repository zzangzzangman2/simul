import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_news.dart';

void main() {
  const engine = GameEngine();

  int dayFor(DateTime date) => date.difference(DateTime(2000, 1, 1)).inDays + 1;

  GameState at(DateTime date, {int cash = 1000000}) =>
      engine.createNewGame('테스트').copyWith(day: dayFor(date), cash: cash);

  group('역사 소식', () {
    test('수백 개의 사건이 2000~2010 범위에 담겨 있다', () {
      expect(kHistoricalNews.length, greaterThan(300));
      for (final event in kHistoricalNews) {
        expect(event.year, inInclusiveRange(2000, 2010));
        expect(event.month, inInclusiveRange(1, 12));
        expect(event.day, inInclusiveRange(1, 31));
        expect(event.title, isNotEmpty);
        expect(event.body, isNotEmpty);
        expect(event.signal, isNotEmpty);
      }
    });

    test('정확한 날짜에 굵직한 사건이 걸려 있다', () {
      expect(historicalNewsForDate(DateTime(2001, 9, 11))?.tone, NewsTone.shock);
      expect(historicalNewsForDate(DateTime(2008, 9, 15))?.eyebrow, '금융위기');
      expect(
        historicalNewsForDate(DateTime(2000, 1, 1))?.tone,
        NewsTone.milestone,
      );
      expect(historicalNewsForDate(DateTime(2007, 6, 29)), isNotNull);
      expect(historicalNewsForDate(DateTime(2004, 8, 19)), isNotNull);
    });

    test('사건이 없는 날은 null 이다', () {
      // 411건이 있어도 대부분의 날은 비어 있다. 빈 날 하나를 찾아 검증한다.
      DateTime? empty;
      for (
        var d = DateTime(2000, 1, 1);
        d.isBefore(DateTime(2011, 1, 1));
        d = d.add(const Duration(days: 1))
      ) {
        if (historicalNewsForDate(d) == null) {
          empty = d;
          break;
        }
      }
      expect(empty, isNotNull);
      expect(historicalNewsForDate(empty!), isNull);
    });

    test('모든 사건은 실제로 지나가는 날짜에 걸려 있다', () {
      for (final event in kHistoricalNews) {
        final date = DateTime(event.year, event.month, event.day);
        expect(dayFor(date), greaterThan(0));
        expect(historicalNewsForDate(date), isNotNull);
      }
    });
  });

  group('매일 소식이 빈 날을 채운다', () {
    test('큰 사건일에는 헤드라인이 뜬다', () {
      final brief = buildDailyBrief(at(DateTime(2008, 9, 15)));
      expect(brief.isBreaking, isTrue);
      expect(brief.headline?.eyebrow, '금융위기');
    });

    test('평범한 거래일에도 소식이 비지 않고 개장 상태다', () {
      // 2005-04-12는 화요일이고 등록된 사건이 없다.
      final brief = buildDailyBrief(at(DateTime(2005, 4, 12)));
      expect(brief.isBreaking, isFalse);
      expect(brief.title, isNotEmpty);
      expect(brief.body, isNotEmpty);
      expect(brief.marketClosed, isFalse);
    });

    test('주말에는 휴장으로 표시한다', () {
      // 2005-04-16은 토요일.
      final brief = buildDailyBrief(at(DateTime(2005, 4, 16)));
      expect(brief.marketClosed, isTrue);
      expect(brief.tone, NewsTone.weekend);
    });

    test('양력 고정 휴일은 이름과 함께 휴장으로 표시한다', () {
      // 어린이날(2005-05-05는 목요일).
      final brief = buildDailyBrief(at(DateTime(2005, 5, 5)));
      expect(brief.marketClosed, isTrue);
      expect(brief.eyebrow, contains('어린이날'));
      expect(brief.tone, NewsTone.holiday);
    });

    test('종잣돈 단계(현금 부족)에는 일거리로 안내한다', () {
      // 현금 0원, 사건·휴일이 아닌 평일 짝수 날.
      final brief = buildDailyBrief(at(DateTime(2000, 2, 2), cash: 0));
      expect(brief.body, contains('일거리'));
    });
  });
}
