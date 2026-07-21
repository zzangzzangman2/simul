import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_news.dart';
import 'package:millennium_capital/game/seed_money_content.dart';
import 'package:millennium_capital/main.dart';

void main() {
  const phoneSize = Size(360, 800);
  const engine = GameEngine();

  GameState newState() =>
      engine.createNewGame('아주 긴 이름의 모바일 투자 연구소', initialCash: 1000000);

  Future<void> usePhoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('360px stock list, detail, and executive portraits stay inside', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: StockMarketScreen(state: newState().copyWith(day: 4))),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    for (var attempt = 0; attempt < 50; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('stock-row-005930')).evaluate().isNotEmpty) {
        break;
      }
    }
    if (find.byKey(const Key('stock-row-005930')).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.byKey(const Key('stock-row-005930')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
    }

    expect(find.byKey(const Key('stock-row-005930')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byKey(const Key('stock-row-005930')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('stock-row-005930')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(
      find.byKey(const Key('historical-executive-section')),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();

    expect(
      find.byKey(const Key('executive-portrait-lee_kun_hee')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('360px organization and upper-body cards stay inside', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    final state = newState();
    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationScreen(
          state: state,
          onRequestFamilyHelp: (_) async => state,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('assignment-portrait-mother')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('assignment-card-father')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('360px work hub and all three mini-games stay inside', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    final state = newState();
    await tester.pumpWidget(
      MaterialApp(
        home: SeedMoneyHubScreen(
          state: state,
          onComplete: (WorkSessionResult _) async => state,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('seed-money-summary')), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final game in <Widget>[
      const DishwashingMiniGame(),
      const StationerySortMiniGame(),
      const FleaMarketMiniGame(),
    ]) {
      await tester.pumpWidget(MaterialApp(home: game));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('360px longest news bulletin stays inside', (tester) async {
    await usePhoneSurface(tester);
    final event = kHistoricalNews.reduce(
      (current, next) =>
          next.title.length + next.eyebrow.length >
              current.title.length + current.eyebrow.length
          ? next
          : current,
    );
    final date = DateTime(event.year, event.month, event.day);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewsBulletinSheet(event: event, date: date),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(event.title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360px daily market newspaper stays inside', (tester) async {
    await usePhoneSurface(tester);
    final state = newState().copyWith(day: 5);
    final newspaper = DailyMarketNewspaper(
      date: state.currentDate,
      brief: buildDailyBrief(state),
      total: 22,
      advancers: 12,
      decliners: 8,
      unchanged: 2,
      topGainers: const [DailyMarketMover(name: 'A', changeRate: 8.4)],
      topLosers: const [DailyMarketMover(name: 'B', changeRate: -6.2)],
      headline: 'Mobile newspaper layout headline',
      summary: 'A compact market summary for a narrow mobile screen.',
    );
    await tester.pumpWidget(
      MaterialApp(home: KoreaEconomicNewspaperScene(newspaper: newspaper)),
    );
    await tester.pumpAndSettle();
    expect(find.text('한국경제신문'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('360px visual novel portraits stay inside through all scenes', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    var created = false;
    await tester.pumpWidget(
      MaterialApp(
        home: VisualNovelOnboardingScreen(onCreate: (_) => created = true),
      ),
    );
    await tester.pumpAndSettle();

    void expectPortraitInside() {
      final portraits = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.contains('character_'),
      );
      for (var index = 0; index < portraits.evaluate().length; index++) {
        final rect = tester.getRect(portraits.at(index));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(phoneSize.width));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(phoneSize.height));
      }
      expect(tester.takeException(), isNull);
    }

    for (var index = 0; index < 6; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
      expectPortraitInside();
    }
    await tester.tap(find.byKey(const Key('story-intro-computer')));
    await tester.pumpAndSettle();
    expectPortraitInside();

    for (var index = 0; index < 4; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
      expectPortraitInside();
    }
    await tester.enterText(find.byKey(const Key('player-name-input')), '민준');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('story-next-name')));
    await tester.tap(find.byKey(const Key('story-next-name')));
    await tester.pumpAndSettle();
    expectPortraitInside();

    await tester.tap(find.byKey(const Key('story-trait-analysis')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expectPortraitInside();

    await tester.tap(find.byKey(const Key('family-rule-report-losses')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('company-name-input')),
      '별빛 투자',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('create-company-button')));
    await tester.tap(find.byKey(const Key('create-company-button')));
    await tester.pumpAndSettle();

    expect(created, isTrue);
    expect(tester.takeException(), isNull);
  });
}
