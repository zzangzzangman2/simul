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

  Future<void> openMarketExplore(WidgetTester tester) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('market-nav-explore')).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.tap(find.byKey(const Key('market-nav-explore')));
    await tester.pump();
    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('stock-row-1001')).evaluate().isNotEmpty) {
        return;
      }
    }
  }

  testWidgets('360px fictional stock list and research detail stay inside', (
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
    await openMarketExplore(tester);
    if (find.byKey(const Key('stock-row-1001')).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.byKey(const Key('stock-row-1001')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
    }

    expect(find.byKey(const Key('stock-row-1001')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byKey(const Key('stock-row-1001')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(
      find.text('오늘의 조사 질문'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();

    expect(find.text('오늘의 조사 질문'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('buy-stock-button')));
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

  testWidgets('360px work hub and rider stay inside', (tester) async {
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

    for (final game in <Widget>[const RiderMiniGame()]) {
      await tester.pumpWidget(MaterialApp(home: game));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('360px apartment rooms keep logical hotspots separate', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    final state = newState();
    await tester.pumpWidget(
      MaterialApp(
        home: OfficeScreen(
          state: state,
          engine: engine,
          activeSaveSlot: 1,
          lastSavedAt: null,
          onManualSave: () async {},
          onReturnToTitle: () {},
          onAdvanceDay: () async => state,
          onSetMarketMinute: (_) async => state,
          onSaveMarketNotebook: (_, _) async => state,
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

    void expectRoomHotspots(List<String> keys) {
      final rects = <Rect>[];
      for (final key in keys) {
        final object = find.byKey(Key(key));
        expect(object, findsOneWidget);
        expect(object.hitTestable(), findsOneWidget);
        final size = tester.getSize(object);
        final rect = tester.getRect(object);
        rects.add(rect);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(phoneSize.width));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(phoneSize.height));
      }
      for (var first = 0; first < rects.length; first++) {
        for (var second = first + 1; second < rects.length; second++) {
          expect(rects[first].overlaps(rects[second]), isFalse);
        }
      }
    }

    expect(find.byKey(const Key('apartment-place-bedroom')), findsOneWidget);
    expect(find.byKey(const Key('hub-mission-card')), findsOneWidget);
    expectRoomHotspots(['open-market-button', 'open-ledger-button']);
    expect(find.byKey(const Key('open-decisions-button')), findsNothing);
    expect(find.byKey(const Key('open-organization-button')), findsNothing);
    expect(find.byKey(const Key('open-work-button')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('open-market-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final computerRoute = find.byType(HomeComputerScreen, skipOffstage: false);
    expect(computerRoute, findsOneWidget);
    expect(find.byKey(const Key('home-computer-screen')), findsOneWidget);
    expect(find.byType(StockMarketScreen), findsNothing);
    final stockApp = find.byKey(const Key('computer-stock-market-app'));
    final realEstateApp = find.byKey(const Key('computer-real-estate-app'));
    expect(stockApp.hitTestable(), findsOneWidget);
    expect(realEstateApp.hitTestable(), findsOneWidget);
    expect(tester.getSize(stockApp).width, greaterThanOrEqualTo(120));
    expect(tester.getSize(realEstateApp), tester.getSize(stockApp));
    expect(
      find.byKey(const Key('hub-mission-card')).hitTestable(),
      findsNothing,
    );

    await tester.tap(stockApp);
    await tester.pump(const Duration(milliseconds: 500));
    final marketRoute = find.byType(StockMarketScreen, skipOffstage: false);
    expect(marketRoute, findsOneWidget);
    Navigator.of(tester.element(marketRoute)).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-computer-screen')), findsOneWidget);

    await tester.tap(realEstateApp);
    await tester.pumpAndSettle();
    final realEstateRoute = find.byKey(const Key('real-estate-market-screen'));
    expect(realEstateRoute, findsOneWidget);
    expect(find.text('부동산 시장'), findsOneWidget);
    expect(find.byKey(const Key('real-estate-metro-map')), findsOneWidget);
    Navigator.of(tester.element(realEstateRoute)).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-computer-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hub-mission-card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('apartment-go-living-room')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('apartment-place-living-room')),
      findsOneWidget,
    );
    expectRoomHotspots(['open-decisions-button', 'open-organization-button']);
    expect(find.byKey(const Key('hub-mission-card')), findsOneWidget);
    final leftArrow = find.byKey(const Key('apartment-go-bedroom'));
    final rightArrow = find.byKey(const Key('apartment-go-kitchen'));
    expect(leftArrow, findsOneWidget);
    expect(rightArrow, findsOneWidget);
    final leftArrowRect = tester.getRect(leftArrow);
    final rightArrowRect = tester.getRect(rightArrow);
    expect(leftArrowRect.size, rightArrowRect.size);
    expect(leftArrowRect.width, 68);
    expect(leftArrowRect.height, 68);
    expect(leftArrowRect.bottom, closeTo(rightArrowRect.bottom, 0.01));
    expect(
      leftArrowRect.left,
      closeTo(phoneSize.width - rightArrowRect.right, 0.01),
    );

    final missionRect = tester.getRect(
      find.byKey(const Key('hub-mission-card')),
    );
    expect(missionRect.width, 202);
    expect(missionRect.height, 62);
    expect(missionRect.right, closeTo(rightArrowRect.right, 0.01));
    expect(missionRect.bottom, lessThan(rightArrowRect.top));
    expect(missionRect.overlaps(rightArrowRect), isFalse);
    expect(missionRect.overlaps(leftArrowRect), isFalse);
    expect(find.byKey(const Key('open-market-button')), findsNothing);
    expect(find.byKey(const Key('open-ledger-button')), findsNothing);

    await tester.tap(find.byKey(const Key('apartment-go-kitchen')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('apartment-place-kitchen')), findsOneWidget);
    expectRoomHotspots(['open-work-button']);
    expect(find.byKey(const Key('hub-mission-card')), findsOneWidget);
    expect(find.byKey(const Key('open-decisions-button')), findsNothing);
    expect(find.byKey(const Key('open-organization-button')), findsNothing);

    await tester.tap(find.byKey(const Key('open-work-button')));
    await tester.pumpAndSettle();
    expect(find.byType(SeedMoneyHubScreen), findsOneWidget);
    expect(
      find.byKey(const Key('hub-mission-card')).hitTestable(),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('360px premium ledger scrolls through the daily appendix', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    final state = newState().copyWith(
      day: 4,
      cash: -50000,
      positions: const [
        PortfolioPosition(
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: '미래시장',
          currency: 'KRW',
          units: 10,
          totalCost: 60000,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PortfolioLedgerScreen(
          state: state,
          universe: testMarketUniverse(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('portfolio-ledger-screen')), findsOneWidget);
    expect(find.byKey(const Key('ledger-aum-hero')), findsOneWidget);
    expect(find.byKey(const Key('ledger-operating-debt')), findsOneWidget);

    final appendix = find.byKey(const Key('ledger-daily-appendix'));
    final ledgerScroll = find.descendant(
      of: find.byKey(const Key('portfolio-ledger-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(appendix, 260, scrollable: ledgerScroll);
    await tester.tap(appendix);
    await tester.pumpAndSettle();

    expect(find.text('가족 계좌 상태와 오늘의 신문 스크랩'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
          activeSaveSlot: 1,
          lastSavedAt: null,
          onManualSave: () async {},
          onReturnToTitle: () {},
          onAdvanceDay: () async => state,
          onSetMarketMinute: (_) async => state,
          onSaveMarketNotebook: (_, _) async => state,
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
    await tester.tap(find.byKey(const Key('apartment-go-living-room')));
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
    const event = FictionalMarketEvent(
      id: 'layout-long-event',
      date: '2006-06-15',
      companyId: 'cheonghae_heavy',
      companyName: '청해중공업',
      sector: '조선·기계',
      stage: 3,
      eyebrow: '대형 프로젝트 원가 재검토',
      title: '청해중공업, 장기간 진행한 친환경 해양설비의 인도 일정과 추가 비용을 다시 검토한다',
      body: '발주처의 설계 변경과 원자재 가격 상승이 겹쳐 회사가 공정별 원가와 인도 일정을 다시 계산하고 있다.',
      signal: '수주 금액보다 남은 공사비와 지체상금 조건을 함께 확인해야 합니다.',
      reportHint: '현장 투입 인력과 외주비가 계획보다 빠르게 늘고 있다.',
      revealMinute: 14 * 60,
      impactPct: -0.08,
      tone: NewsTone.shock,
    );
    final date = DateTime(2006, 6, 15);

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
    expect(find.text('새천년경제'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('360px visual novel portraits stay inside through all scenes', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    var created = false;
    final creationGate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: VisualNovelOnboardingScreen(
          onCreate: (_, onProgress) async {
            created = true;
            onProgress('테스트 시장 준비 중…');
            await creationGate.future;
          },
        ),
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
      final teacher = find.byKey(const Key('academy-teacher-character'));
      if (teacher.evaluate().isNotEmpty) {
        final teacherRect = tester.getRect(teacher);
        expect(teacherRect.left, closeTo(3.72, 0.01));
        expect(teacherRect.center.dx, closeTo(phoneSize.width / 2, 0.01));
        expect(teacherRect.top, closeTo(149.16, 0.01));
        expect(teacherRect.width, closeTo(352.56, 0.01));
        expect(teacherRect.height, closeTo(528.84, 0.01));
        expect(teacherRect.bottom, closeTo(678, 0.01));
      }
      expect(tester.takeException(), isNull);
    }

    for (var index = 0; index < 10; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
      expectPortraitInside();
    }
    await tester.tap(find.byKey(const Key('story-intro-computer')));
    await tester.pumpAndSettle();
    expectPortraitInside();

    for (var index = 0; index < 9; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
      expectPortraitInside();
    }
    expect(find.byKey(const Key('academy-teacher-character')), findsOneWidget);
    final academyTeacherRect = tester.getRect(
      find.byKey(const Key('academy-teacher-character')),
    );
    expect(academyTeacherRect.height, closeTo(528.84, 0.01));
    await tester.tap(find.byKey(const Key('academy-tutorial-continue')));
    await tester.pumpAndSettle();
    expectPortraitInside();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expectPortraitInside();
    await tester.enterText(find.byKey(const Key('player-name-input')), '민준');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('story-next-name')));
    await tester.tap(find.byKey(const Key('story-next-name')));
    await tester.pumpAndSettle();
    expectPortraitInside();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expectPortraitInside();

    await tester.tap(find.byKey(const Key('story-trait-analysis')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expectPortraitInside();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expectPortraitInside();

    await tester.tap(find.byKey(const Key('family-rule-report-losses')));
    await tester.pumpAndSettle();
    for (var index = 0; index < 2; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
    }
    await tester.enterText(
      find.byKey(const Key('company-name-input')),
      '별빛 투자',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('create-company-button')));
    await tester.tap(find.byKey(const Key('create-company-button')));
    await tester.pump();

    expect(created, isTrue);
    expect(
      find.byKey(const Key('new-game-preparation-overlay')),
      findsOneWidget,
    );
    await tester.pump();
    expect(find.text('테스트 시장 준비 중…'), findsOneWidget);
    creationGate.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('name inputs stay above a 320px mobile keyboard', (tester) async {
    await usePhoneSurface(tester);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        home: VisualNovelOnboardingScreen(onCreate: (_, onProgress) async {}),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 10; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('story-intro-computer')));
    await tester.pumpAndSettle();
    for (var index = 0; index < 9; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('academy-tutorial-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('player-name-input')));
    tester.view.viewInsets = FakeViewPadding(
      bottom: 320 * tester.view.devicePixelRatio,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('player-name-input')), '민준');
    await tester.pump();
    final stageRect = tester.getRect(find.byKey(const Key('onboarding-stage')));
    expect(stageRect.top, 0);
    expect(stageRect.height, phoneSize.height);
    final playerPanelRect = tester.getRect(
      find.byKey(const Key('keyboard-name-panel')),
    );
    expect(playerPanelRect.bottom, lessThanOrEqualTo(phoneSize.height - 320));
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
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('story-continue')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('story-trait-analysis')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('story-trait-analysis')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('family-rule-report-losses')));
    await tester.pumpAndSettle();
    for (var index = 0; index < 2; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
    }

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
    final companyStageRect = tester.getRect(
      find.byKey(const Key('onboarding-stage')),
    );
    expect(companyStageRect.top, 0);
    expect(companyStageRect.height, phoneSize.height);
    final companyPanelRect = tester.getRect(
      find.byKey(const Key('keyboard-name-panel')),
    );
    expect(companyPanelRect.bottom, lessThanOrEqualTo(phoneSize.height - 320));
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
