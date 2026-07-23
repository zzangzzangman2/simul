import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_news.dart';

void main() {
  const engine = GameEngine();
  const seed = 'news-test-world';

  int dayFor(DateTime date) => date.difference(DateTime(2000, 1, 1)).inDays + 1;

  GameState at(DateTime date, {int cash = 1000000}) => engine
      .createNewGame('테스트', worldSeed: seed)
      .copyWith(day: dayFor(date), cash: cash);

  group('가상 시장 사건', () {
    test('시작 상장사는 고정된 가상 기업 30개다', () {
      expect(fixedFictionalCompanies, hasLength(30));
      expect(
        fixedFictionalCompanies.map((company) => company.id).toSet(),
        hasLength(30),
      );
      expect(
        fixedFictionalCompanies.map((company) => company.name),
        containsAll(<String>['한빛통신', '청해중공업', '태성바이오']),
      );
    });

    test('한 세계에 수천 개의 연속 사건이 결정론적으로 생성된다', () {
      var count = 0;
      for (
        var date = DateTime(2000, 1, 1);
        date.isBefore(DateTime(2011, 1, 1));
        date = date.add(const Duration(days: 1))
      ) {
        final first = fictionalMarketEventsForDate(seed, date);
        final second = fictionalMarketEventsForDate(seed, date);
        expect(
          first.map((event) => event.toJson()).toList(),
          second.map((event) => event.toJson()).toList(),
        );
        count += first.length;
      }
      expect(count, greaterThan(3000));
    });

    test('조선 회사에는 바이오·반도체 전용 사건이 섞이지 않는다', () {
      final forbidden = RegExp('신약|임상|후보물질|메모리 칩|미세공정');
      for (
        var date = DateTime(2000, 1, 1);
        date.isBefore(DateTime(2011, 1, 1));
        date = date.add(const Duration(days: 1))
      ) {
        final shipEvents = fictionalMarketEventsForDate(
          seed,
          date,
        ).where((event) => event.companyId == 'cheonghae_heavy');
        for (final event in shipEvents) {
          expect('${event.title} ${event.body}', isNot(matches(forbidden)));
        }
      }
    });

    test('신규상장·유상증자·분할·상장폐지가 세계 생애주기에 들어간다', () async {
      final universe = await FictionalMarketUniverse.load(seed: seed);
      expect(universe.assets.length, greaterThan(70));
      final actions = universe.assets
          .expand((asset) => asset.corporateActions)
          .map((action) => action.type)
          .toSet();
      expect(actions, contains(MarketCorporateActionType.rightsIssue));
      expect(actions, contains(MarketCorporateActionType.materialSpinoff));
      expect(actions, contains(MarketCorporateActionType.spinoff));
      expect(actions, contains(MarketCorporateActionType.delisting));
    });

    test('오늘의 비공개 시나리오는 같은 세이브에서 다시 뽑히지 않는다', () {
      final initial = at(DateTime(2004, 5, 3));
      final first = engine.prepareHiddenMarketScenario(initial);
      final second = engine.prepareHiddenMarketScenario(first);
      expect(
        first.story.storyFlags['hiddenMarketScenario'],
        second.story.storyFlags['hiddenMarketScenario'],
      );
    });
  });

  group('전날을 정리하는 조간신문', () {
    test('사건이 있는 날에는 공개된 사건만 헤드라인에 쓴다', () {
      DateTime? eventDate;
      for (
        var date = DateTime(2002, 1, 1);
        date.isBefore(DateTime(2003, 1, 1));
        date = date.add(const Duration(days: 1))
      ) {
        if (fictionalMarketEventsForDate(seed, date).isNotEmpty) {
          eventDate = date;
          break;
        }
      }
      expect(eventDate, isNotNull);
      final brief = buildDailyBrief(at(eventDate!));
      expect(brief.isBreaking, isTrue);
      expect(brief.headline?.date, marketDateKey(eventDate));
    });

    test('평범한 거래일에도 소식이 비지 않는다', () {
      DateTime? emptyTradingDay;
      for (
        var date = DateTime(2005, 4, 1);
        date.isBefore(DateTime(2005, 6, 1));
        date = date.add(const Duration(days: 1))
      ) {
        if (date.weekday < DateTime.saturday &&
            fictionalMarketEventsForDate(seed, date).isEmpty) {
          emptyTradingDay = date;
          break;
        }
      }
      expect(emptyTradingDay, isNotNull);
      final brief = buildDailyBrief(at(emptyTradingDay!));
      expect(brief.title, isNotEmpty);
      expect(brief.body, isNotEmpty);
    });

    test('주말에는 휴장으로 표시한다', () {
      final brief = buildDailyBrief(at(DateTime(2005, 4, 16)));
      expect(brief.marketClosed, isTrue);
    });

    test('개인 일거리와 오늘의 숨은 결과는 기사에 넣지 않는다', () {
      final brief = buildDailyBrief(at(DateTime(2000, 2, 2), cash: 0));
      final articleText = '${brief.title} ${brief.body}';
      expect(articleText, isNot(contains('일거리')));
      expect(articleText, isNot(contains('조사노트')));
      expect(articleText, isNot(contains('reportHint')));
      expect(articleText, isNot(contains('impactPct')));
    });
  });
}
