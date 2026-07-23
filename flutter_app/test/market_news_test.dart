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

    test('기업 사건 144개 세부 문법과 시대 기술 조합은 수억 가지를 넘는다', () {
      expect(fictionalMarketArcKinds, hasLength(18));
      expect(fictionalMarketArcKinds.toSet(), hasLength(18));
      expect(fictionalMarketArcScenarios, hasLength(144));
      expect(
        fictionalMarketArcScenarios.map((scenario) => scenario.id).toSet(),
        hasLength(144),
      );
      for (final kind in fictionalMarketArcKinds) {
        expect(
          fictionalMarketArcScenarios.where(
            (scenario) => scenario.kind == kind,
          ),
          hasLength(8),
          reason: kind,
        );
      }
      expect(fictionalEraTechnologies, hasLength(80));
      expect(
        fictionalHistoricalMarketCatalysts.length,
        greaterThanOrEqualTo(40),
      );
      expect(
        fictionalEraTechnologyCombinationFloor(),
        greaterThan(BigInt.from(100000000)),
      );
    });

    test('미래 제품은 실제 확산 연도 전 사건에 등장하지 않는다', () {
      final display = fixedFictionalCompanies.singleWhere(
        (company) => company.id == 'solbit_display',
      );
      final battery = fixedFictionalCompanies.singleWhere(
        (company) => company.id == 'moa_battery',
      );

      expect(
        fictionalProductsAvailableInYear(display, 2000),
        isNot(contains('유기발광 패널')),
      );
      expect(
        fictionalProductsAvailableInYear(display, 2007),
        contains('유기발광 패널'),
      );
      expect(
        fictionalProductsAvailableInYear(display, 2010),
        isNot(contains('접히는 화면')),
      );
      expect(
        fictionalProductsAvailableInYear(battery, 2010),
        isNot(contains('고체 전해질')),
      );
    });

    test('80개 시대 기술은 허용 연도 안에서 국내기업 4단계 사건이 된다', () {
      final technologyEvents = <FictionalMarketEvent>[];
      for (
        var date = DateTime(2000, 1, 1);
        date.isBefore(DateTime(2011, 1, 1));
        date = date.add(const Duration(days: 1))
      ) {
        technologyEvents.addAll(
          fictionalMarketEventsForDate(
            seed,
            date,
          ).where((event) => event.id.startsWith('technology-')),
        );
      }

      expect(technologyEvents, hasLength(fictionalEraTechnologies.length * 4));
      final publishedText = technologyEvents
          .map((event) => '${event.title} ${event.body}')
          .join(' ');
      expect(
        publishedText,
        isNot(matches(RegExp('Apple|Google|YouTube|iPhone|Android'))),
      );
      for (final technology in fictionalEraTechnologies) {
        final events = technologyEvents
            .where(
              (event) => event.id.startsWith('technology-${technology.id}-'),
            )
            .toList();
        expect(events, hasLength(4), reason: technology.id);
        expect(events.map((event) => event.stage).toSet(), <int>{0, 1, 2, 3});
        expect(
          events,
          everyElement(
            predicate<FictionalMarketEvent>((event) {
              final year = int.parse(event.date.substring(0, 4));
              return year >= technology.firstYear &&
                  year <= technology.lastYear &&
                  event.companyId != fictionalWholeMarketCompanyId;
            }),
          ),
          reason: technology.id,
        );
        expect(
          events.singleWhere((event) => event.stage == 2).impactPct.abs(),
          greaterThan(0.13),
          reason: technology.id,
        );
      }
    });

    test('실제 시기 기반 거시 촉매가 모두 시장 사건으로 들어간다', () {
      final historicalEvents = <FictionalMarketEvent>[];
      for (
        var date = DateTime(2000, 1, 1);
        date.isBefore(DateTime(2011, 1, 1));
        date = date.add(const Duration(days: 1))
      ) {
        historicalEvents.addAll(
          fictionalMarketEventsForDate(
            seed,
            date,
          ).where((event) => event.id.startsWith('historical-')),
        );
      }

      expect(
        historicalEvents,
        hasLength(fictionalHistoricalMarketCatalysts.length),
      );
      expect(
        historicalEvents,
        everyElement(
          predicate<FictionalMarketEvent>(
            (event) =>
                event.companyId == fictionalWholeMarketCompanyId &&
                event.companyName == '시장 전체',
          ),
        ),
      );
    });

    test('조선 수주는 선종·척수·금액·선수금 조건을 따로 만든다', () {
      final shipOrders = <FictionalMarketEvent>[];
      final shippingContracts = <FictionalMarketEvent>[];
      for (
        var date = DateTime(2000, 1, 1);
        date.isBefore(DateTime(2011, 1, 1));
        date = date.add(const Duration(days: 1))
      ) {
        final events = fictionalMarketEventsForDate(seed, date);
        shipOrders.addAll(
          events.where(
            (event) =>
                event.companyId == 'cheonghae_heavy' &&
                event.eyebrow.startsWith('선박 수주'),
          ),
        );
        shippingContracts.addAll(
          events.where(
            (event) =>
                event.companyId == 'maru_shipping' &&
                event.eyebrow.startsWith('장기 운송계약'),
          ),
        );
      }

      expect(shipOrders, isNotEmpty);
      expect(
        shipOrders.map((event) => '${event.title} ${event.body}').join(' '),
        allOf(contains('척'), contains('선수금'), contains('인도')),
      );
      expect(shippingContracts, isNotEmpty);
      expect(
        shippingContracts
            .map((event) => '${event.title} ${event.body}')
            .join(' '),
        allOf(contains('운임'), contains('물량')),
      );
    });

    test('한 기업은 캠페인 동안 같은 세부 사건 문법을 반복하지 않는다', () {
      final scenarioLabels = <String>[];
      for (
        var date = DateTime(2000, 1, 1);
        date.isBefore(DateTime(2011, 1, 1));
        date = date.add(const Duration(days: 1))
      ) {
        for (final event in fictionalMarketEventsForDate(seed, date)) {
          if (event.companyId == 'hanbit_telecom' &&
              event.id.startsWith('arc-') &&
              event.stage == 0) {
            scenarioLabels.add(event.eyebrow);
          }
        }
      }

      expect(scenarioLabels.length, greaterThan(25));
      expect(scenarioLabels.toSet(), hasLength(scenarioLabels.length));
    });

    test('새 게임은 같은 회사명이어도 다른 월드와 사건 순서를 만든다', () {
      final worlds = List.generate(
        32,
        (_) => engine.createNewGame('같은 이름의 투자사'),
      );
      expect(
        worlds.map((world) => world.simulationSeed).toSet(),
        hasLength(worlds.length),
      );
      final first = worlds[0];
      final second = worlds[1];
      expect(first.simulationSeed, isNot(second.simulationSeed));

      final firstSequence = <String>[];
      final secondSequence = <String>[];
      for (
        var date = DateTime(2000, 1, 1);
        date.isBefore(DateTime(2001, 1, 1));
        date = date.add(const Duration(days: 1))
      ) {
        firstSequence.addAll(
          fictionalMarketEventsForDate(first.simulationSeed, date).map(
            (event) => '${event.companyId}:${event.title}:${event.impactPct}',
          ),
        );
        secondSequence.addAll(
          fictionalMarketEventsForDate(second.simulationSeed, date).map(
            (event) => '${event.companyId}:${event.title}:${event.impactPct}',
          ),
        );
      }
      expect(firstSequence, isNot(secondSequence));
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
      expect(count, greaterThan(8500));
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

    test('세계 금융충격은 전체 시장과 취약 업종 가격에 반영된다', () async {
      final universe = await FictionalMarketUniverse.load(seed: seed);
      final finance = universe.assets.singleWhere(
        (asset) => asset.id == 'daon_finance',
      );
      final quote = finance.quoteAtOrBefore(DateTime(2008, 9, 15))!;
      final previous = finance.previousCloseBefore(quote.date)!;
      final dailyReturn = quote.close / previous - 1;

      expect(quote.isExactDate, isTrue);
      expect(dailyReturn, greaterThanOrEqualTo(-0.15));
      expect(dailyReturn, lessThanOrEqualTo(-0.14));
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

    test('평일과 주말 기본 기사도 장기 플레이에서 반복을 피한다', () {
      final weekdayTitles = <String>{};
      final weekendTitles = <String>{};
      for (
        var date = DateTime(2004, 1, 1);
        date.isBefore(DateTime(2007, 1, 1));
        date = date.add(const Duration(days: 1))
      ) {
        if (fictionalMarketEventsForDate(seed, date).isNotEmpty) continue;
        final brief = buildDailyBrief(at(date));
        if (date.weekday >= DateTime.saturday) {
          weekendTitles.add(brief.title);
        } else {
          weekdayTitles.add(brief.title);
        }
      }

      expect(weekdayTitles.length, greaterThan(100));
      expect(weekendTitles.length, greaterThanOrEqualTo(5));
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
