import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_news.dart';
import 'package:millennium_capital/game/seed_money_content.dart';
import 'package:millennium_capital/main.dart';

import 'support/market_fixture.dart';

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
      MaterialApp(
        home: StockMarketScreen(
          state: newState().copyWith(day: 4),
          universe: testMarketUniverse(),
        ),
      ),
    );
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
    await tester.tap(find.byKey(const Key('write-research-note-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-quantity-value')), findsOneWidget);
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

  testWidgets('360px room hotspots stay on-screen and remain touchable', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    final state = newState();
    await tester.pumpWidget(
      MaterialApp(
        home: OfficeScreen(
          state: state,
          engine: engine,
          onAdvanceDay: () async => state,
          onSetMarketMinute: (_) async => state,
          onResolveDecision: (_, _) async {},
          onRequestFamilyHelp: (_) async => state,
          onCompleteWork: (_) async => state,
          onExecuteTrade: (_) async => TradeExecutionResult(
            success: false,
            state: state,
            message: 'test',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hotspotRects = <String, Rect>{};
    for (final key in [
      'open-market-button',
      'open-decisions-button',
      'open-ledger-button',
      'open-organization-button',
      'open-work-button',
    ]) {
      final object = find.byKey(Key(key));
      expect(object, findsOneWidget);
      final size = tester.getSize(object);
      final rect = tester.getRect(object);
      hotspotRects[key] = rect;
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(phoneSize.width));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(phoneSize.height));
    }
    final entries = hotspotRects.entries.toList();
    for (var first = 0; first < entries.length; first++) {
      for (var second = first + 1; second < entries.length; second++) {
        expect(
          entries[first].value.overlaps(entries[second].value),
          isFalse,
          reason: '${entries[first].key} overlaps ${entries[second].key}',
        );
      }
    }
    expect(
      hotspotRects['open-market-button']!.center.dx,
      lessThan(hotspotRects['open-work-button']!.center.dx),
    );
    expect(
      hotspotRects['open-decisions-button']!.center.dy,
      greaterThan(hotspotRects['open-market-button']!.center.dy),
    );
    expect(
      hotspotRects['open-ledger-button']!.center.dx,
      greaterThan(hotspotRects['open-decisions-button']!.center.dx),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('open-market-button')));
    await tester.pump();
    expect(find.byType(StockMarketScreen, skipOffstage: false), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('decision scene stays locked in front until its save completes', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    final state = newState();
    final save = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: OfficeScreen(
          state: state,
          engine: engine,
          onAdvanceDay: () async => state,
          onSetMarketMinute: (_) async => state,
          onResolveDecision: (_, _) => save.future,
          onRequestFamilyHelp: (_) async => state,
          onCompleteWork: (_) async => state,
          onExecuteTrade: (_) async => TradeExecutionResult(
            success: false,
            state: state,
            message: 'test',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-decisions-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('decision-inbox-item-first-research-note')),
    );
    await tester.pumpAndSettle();

    final option = find.byKey(const Key('decision-option-research_products'));
    await tester.tap(option);
    await tester.pump();
    expect(option, findsOneWidget);
    expect(find.byKey(const Key('decision-saving-indicator')), findsOneWidget);
    expect(
      find.byKey(const Key('decision-inbox-screen'), skipOffstage: false),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(option, findsOneWidget);
    expect(find.byKey(const Key('decision-saving-indicator')), findsOneWidget);

    save.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('decision-inbox-screen')), findsNothing);
    expect(option, findsNothing);
    expect(tester.takeException(), isNull);
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

  testWidgets('name inputs stay above a 320px mobile keyboard', (tester) async {
    await usePhoneSurface(tester);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(home: VisualNovelOnboardingScreen(onCreate: (_) {})),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 6; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('story-intro-computer')));
    await tester.pumpAndSettle();
    for (var index = 0; index < 4; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const Key('player-name-input')));
    tester.view.viewInsets = FakeViewPadding(
      bottom: 320 * tester.view.devicePixelRatio,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('player-name-input')), '민준');
    await tester.pump();
    final playerInput = find.byKey(const Key('player-name-input'));
    final playerButton = find.byKey(const Key('story-next-name'));
    final playerInputRect = tester.getRect(playerInput);
    expect(playerInputRect.top, greaterThanOrEqualTo(0));
    expect(playerInputRect.bottom, lessThanOrEqualTo(phoneSize.height - 320));
    expect(playerInput.hitTestable(), findsOneWidget);
    expect(playerButton.hitTestable(), findsOneWidget);
    expect(
      tester.getRect(playerButton).bottom,
      lessThanOrEqualTo(phoneSize.height - 320),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(playerButton);
    await tester.pump();
    expect(
      find.byKey(const Key('story-trait-analysis')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-trait-analysis')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('family-rule-report-losses')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('company-name-input')));
    tester.view.viewInsets = FakeViewPadding(
      bottom: 320 * tester.view.devicePixelRatio,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('company-name-input')),
      '별빛 투자',
    );
    await tester.pump();
    final companyInput = find.byKey(const Key('company-name-input'));
    final companyButton = find.byKey(const Key('create-company-button'));
    final companyInputRect = tester.getRect(companyInput);
    expect(companyInputRect.top, greaterThanOrEqualTo(0));
    expect(companyInputRect.bottom, lessThanOrEqualTo(phoneSize.height - 320));
    expect(companyInput.hitTestable(), findsOneWidget);
    expect(companyButton.hitTestable(), findsOneWidget);
    expect(
      tester.getRect(companyButton).bottom,
      lessThanOrEqualTo(phoneSize.height - 320),
    );
    expect(tester.takeException(), isNull);
  });
}
