import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_news.dart';
import 'package:millennium_capital/game/order_book.dart';
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
    await tester.tap(find.byKey(const Key('stock-detail-tab-info')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('오늘의 조사 질문'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();

    expect(find.text('오늘의 조사 질문'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('stock-detail-tab-order')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('buy-stock-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-ticket')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-book')), findsOneWidget);
    final inlineAskRows = find.byKey(
      const ValueKey('inline-order-book-ask-row'),
    );
    final inlineBidRows = find.byKey(
      const ValueKey('inline-order-book-bid-row'),
    );
    expect(inlineAskRows, findsNWidgets(gameOrderBookLevelCount));
    expect(inlineBidRows, findsNWidgets(gameOrderBookLevelCount));
    final bestAskY = tester.getCenter(inlineAskRows.last).dy;
    final bestBidY = tester.getCenter(inlineBidRows.first).dy;
    expect(bestAskY, lessThan(bestBidY));
    final currentPriceBorderY = tester
        .getCenter(
          find.byKey(const Key('inline-order-book-current-price-border')),
        )
        .dy;
    expect(
      currentPriceBorderY,
      anyOf(closeTo(bestAskY, 1), closeTo(bestBidY, 1)),
    );
    expect(find.byKey(const Key('detailed-order-screen')), findsNothing);
    expect(find.text('현금'), findsNothing);
    expect(find.text('신용'), findsNothing);
    expect(find.byKey(const Key('order-quantity-value')), findsOneWidget);
    final ticketRect = tester.getRect(
      find.byKey(const Key('inline-order-ticket')),
    );
    final railRect = tester.getRect(find.byKey(const Key('inline-order-book')));
    final workspaceRect = tester.getRect(
      find.byKey(const Key('inline-order-workspace')),
    );
    expect(ticketRect.left, greaterThanOrEqualTo(0));
    expect(ticketRect.right, lessThanOrEqualTo(railRect.left));
    expect(railRect.right, lessThanOrEqualTo(phoneSize.width));
    expect(
      workspaceRect.bottom,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const Key('stock-detail-bottom-nav'))).dy,
      ),
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
          onRequestAcademyHelp: (_) async => state,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('assignment-portrait-hakjun')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('assignment-card-sua')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('360px controlled-company governance card stays inside', (
    tester,
  ) async {
    await usePhoneSurface(tester);
    final base = newState();
    final state = base.copyWith(
      company: base.company.copyWith(
        id: 'hanbit_components',
        name: '한빛전자부품',
        worldStartedAtDay: 1828,
        worldPremise: '의결권 55% · 이사회 4/7석',
        votingOwnershipPct: 55,
        economicOwnershipPct: 55,
        boardSeats: 4,
        totalBoardSeats: 7,
        investmentBookValue: 390000,
        acquiredAtDay: 1828,
        leadershipModel: CompanyLeadershipModel.academyAdvisor,
        monthlyRevenue: 175000,
        monthlyOperatingCost: 140000,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationScreen(
          state: state,
          onRequestAcademyHelp: (_) async => state,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('controlled-company-governance-card'));
    expect(card, findsOneWidget);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    final rect = tester.getRect(card);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(phoneSize.width));
    expect(find.text('한빛전자부품 · 경영권'), findsOneWidget);
    expect(find.text('4/7석'), findsOneWidget);
    expect(find.text('390,000원'), findsOneWidget);
    expect(find.textContaining('정식 직원 수'), findsOneWidget);
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
      await tester.pump(const Duration(milliseconds: 500));
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
          onRequestAcademyHelp: (_) async => state,
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
    final businessApp = find.byKey(const Key('computer-business-app'));
    final starShopApp = find.byKey(const Key('computer-star-shop-app'));
    expect(stockApp.hitTestable(), findsOneWidget);
    expect(realEstateApp.hitTestable(), findsOneWidget);
    expect(businessApp.hitTestable(), findsOneWidget);
    expect(starShopApp.hitTestable(), findsOneWidget);
    expect(tester.getSize(stockApp).width, greaterThanOrEqualTo(88));
    expect(tester.getSize(realEstateApp), tester.getSize(stockApp));
    expect(tester.getSize(businessApp), tester.getSize(stockApp));
    expect(tester.getSize(starShopApp), tester.getSize(stockApp));
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

    await tester.tap(businessApp);
    await tester.pumpAndSettle();
    final businessRoute = find.byKey(const Key('business-management-screen'));
    expect(businessRoute, findsOneWidget);
    expect(find.byKey(const Key('business-tab-events')), findsOneWidget);
    expect(find.byKey(const Key('business-tab-statements')), findsOneWidget);
    Navigator.of(tester.element(businessRoute)).pop();
    await tester.pumpAndSettle();

    await tester.tap(starShopApp);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('star-shop-screen')), findsOneWidget);
    expect(find.byKey(const Key('star-balance')), findsOneWidget);
    Navigator.of(
      tester.element(find.byKey(const Key('star-shop-screen'))),
    ).pop();
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
    expectRoomHotspots([
      'open-organization-button',
      'open-home-improvements-button',
    ]);
    expect(find.byKey(const Key('open-bank-button')), findsNothing);
    expect(find.byKey(const Key('open-decisions-button')), findsNothing);
    expect(find.byKey(const Key('open-work-button')), findsNothing);
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
    expectRoomHotspots([]);
    expect(find.byKey(const Key('hub-mission-card')), findsOneWidget);
    expect(find.byKey(const Key('open-work-button')), findsNothing);
    expect(find.byKey(const Key('open-decisions-button')), findsNothing);
    expect(find.byKey(const Key('open-bank-button')), findsNothing);

    await tester.tap(find.byKey(const Key('apartment-go-corridor')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('apartment-place-corridor')), findsOneWidget);
    expectRoomHotspots(['open-decisions-button']);
    expect(find.byKey(const Key('open-work-button')), findsNothing);
    expect(find.byKey(const Key('open-bank-button')), findsNothing);
    expect(find.byKey(const Key('open-organization-button')), findsNothing);

    await tester.tap(find.byKey(const Key('apartment-go-neighborhood')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('apartment-place-neighborhood')),
      findsOneWidget,
    );
    expectRoomHotspots(['open-bank-button', 'open-work-button']);
    expect(find.byKey(const Key('open-decisions-button')), findsNothing);

    await tester.tap(find.byKey(const Key('open-bank-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-screen')), findsOneWidget);
    expect(find.byKey(const Key('bank-clerk-welcome')), findsOneWidget);
    expect(find.byKey(const Key('bank-intro-dialogue')), findsOneWidget);
    await tester.tap(find.byKey(const Key('bank-intro-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bank-intro-deposit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bank-consultation-panel')), findsOneWidget);
    expect(find.byKey(const Key('bank-deposit-term-6')), findsOneWidget);
    expect(find.byKey(const Key('bank-deposit-term-12')), findsOneWidget);
    expect(find.byKey(const Key('bank-deposit-term-24')), findsOneWidget);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byKey(const Key('bank-screen')))).pop();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('apartment-place-neighborhood')),
      findsOneWidget,
    );

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
    await tester.ensureVisible(appendix);
    await tester.pumpAndSettle();
    expect(appendix.hitTestable(), findsOneWidget);
    await tester.tap(appendix.hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('국가계좌 상태와 오늘의 신문 스크랩'), findsOneWidget);
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
          onRequestAcademyHelp: (_) async => state,
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
    await tester.tap(find.byKey(const Key('apartment-go-kitchen')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apartment-go-corridor')));
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
            onProgress(const WorldLoadProgress(0.18, '테스트 시장 준비 중…'));
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
        final stageRect = tester.getRect(
          find.byKey(const Key('onboarding-stage')),
        );
        expect(rect.right, greaterThan(stageRect.left));
        expect(rect.left, lessThan(stageRect.right));
        expect(rect.top, greaterThanOrEqualTo(stageRect.top));
        expect(rect.bottom, lessThanOrEqualTo(stageRect.bottom));
      }
      final teacher = find.byKey(const Key('academy-teacher-character'));
      if (teacher.evaluate().isNotEmpty) {
        final stageRect = tester.getRect(
          find.byKey(const Key('onboarding-stage')),
        );
        final teacherRect = tester.getRect(teacher);
        expect(teacherRect.center.dx, closeTo(stageRect.center.dx, 0.01));
        expect(teacherRect.height, closeTo(stageRect.height * 0.9, 0.01));
        expect(teacherRect.bottom, closeTo(stageRect.bottom - 104, 0.01));
      }
      expect(tester.takeException(), isNull);
    }

    for (var index = 0; index < 5; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
      expectPortraitInside();
    }
    expect(find.byKey(const Key('policy-file-children')), findsNothing);
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expectPortraitInside();

    for (var index = 0; index < 37; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
      expectPortraitInside();
    }
    expect(find.byKey(const Key('orientation-roster-card')), findsOneWidget);
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expectPortraitInside();
    for (var index = 0; index < 28; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
      expectPortraitInside();
    }
    expect(find.byKey(const Key('orientation-complete-card')), findsOneWidget);
    expect(find.byKey(const Key('academy-pc-powered-off')), findsOneWidget);
    expect(find.byKey(const Key('academy-pc-power-toggle')), findsOneWidget);
    expect(
      find.byKey(const Key('academy-market-tutorial-screen')),
      findsNothing,
    );
    expect(created, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('story skip opens the powered-off classroom PC', (tester) async {
    await usePhoneSurface(tester);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        home: VisualNovelOnboardingScreen(onCreate: (_, onProgress) async {}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('story-skip-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-skip-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('orientation-complete-card')), findsOneWidget);
    expect(find.byKey(const Key('academy-pc-powered-off')), findsOneWidget);
    expect(find.byKey(const Key('academy-pc-power-toggle')), findsOneWidget);
    expect(find.byKey(const Key('academy-player-name-input')), findsNothing);
    expect(find.byKey(const Key('academy-company-name-input')), findsNothing);
    final stageRect = tester.getRect(find.byKey(const Key('onboarding-stage')));
    expect(stageRect.top, 0);
    expect(stageRect.height, phoneSize.height);

    await tester.tap(find.byKey(const Key('academy-pc-power-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('academy-pc-desktop')), findsOneWidget);
    await tester.tap(find.byKey(const Key('academy-stock-app-icon')));
    await tester.pumpAndSettle();
    final setupRect = tester.getRect(
      find.byKey(const Key('academy-stock-setup-screen')),
    );
    expect(setupRect.left, greaterThanOrEqualTo(stageRect.left));
    expect(setupRect.right, lessThanOrEqualTo(stageRect.right));
    expect(setupRect.top, greaterThanOrEqualTo(stageRect.top));
    expect(setupRect.bottom, lessThanOrEqualTo(stageRect.bottom));
    await tester.tap(find.byKey(const Key('academy-pc-power-off')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('academy-pc-powered-off')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
