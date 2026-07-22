import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_persistence.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/market_fixture.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> advanceDialogue(WidgetTester tester, int count) async {
    for (var index = 0; index < count; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> startNewGame(WidgetTester tester) async {
    if (find.byKey(const Key('game-title-screen')).evaluate().isEmpty) return;
    await tester.tap(find.byKey(const Key('new-game-button')));
    await tester.pumpAndSettle();
  }

  Future<void> continueFirstSave(WidgetTester tester) async {
    if (find.byKey(const Key('game-title-screen')).evaluate().isEmpty) return;
    await tester.tap(find.byKey(const Key('continue-game-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('load-save-slot-1')));
    await tester.pumpAndSettle();
  }

  Future<void> dismissHubTutorial(WidgetTester tester) async {
    final done = find.byKey(const Key('hub-tutorial-done'));
    if (done.evaluate().isEmpty) return;
    await tester.tap(done);
    await tester.pumpAndSettle();
  }

  Future<void> waitForMarketHome(WidgetTester tester) async {
    for (var attempt = 0; attempt < 30; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('market-home-section')).evaluate().isNotEmpty) {
        return;
      }
    }
  }

  Future<void> openMarketExplore(WidgetTester tester) async {
    await waitForMarketHome(tester);
    await tester.tap(find.byKey(const Key('market-nav-explore')));
    await tester.pump();
    for (var attempt = 0; attempt < 30; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('stock-row-005930')).evaluate().isNotEmpty) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -240));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('stock-row-005930')));
        return;
      }
    }
  }

  Future<void> goToLivingRoom(WidgetTester tester) async {
    await dismissHubTutorial(tester);
    await tester.tap(find.byKey(const Key('apartment-go-living-room')));
    await tester.pumpAndSettle();
  }

  Future<void> goToKitchen(WidgetTester tester) async {
    await goToLivingRoom(tester);
    await tester.tap(find.byKey(const Key('apartment-go-kitchen')));
    await tester.pumpAndSettle();
  }

  Future<void> completeStoryOnboarding(WidgetTester tester) async {
    await startNewGame(tester);
    await advanceDialogue(tester, 9);
    await tester.tap(find.byKey(const Key('story-intro-computer')));
    await tester.pumpAndSettle();

    await advanceDialogue(tester, 7);
    await tester.enterText(find.byKey(const Key('player-name-input')), '민준');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('story-next-name')));
    await tester.tap(find.byKey(const Key('story-next-name')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('story-trait-analysis')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();

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
    await dismissHubTutorial(tester);
  }

  testWidgets('prologue explains the setting before showing a choice', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MillenniumCapitalApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('game-title-screen')), findsOneWidget);
    expect(find.text('처음하기'), findsOneWidget);
    expect(find.text('이어하기'), findsOneWidget);

    await startNewGame(tester);

    expect(find.textContaining('새 천년을 세 분 앞둔 밤'), findsOneWidget);
    expect(find.textContaining('작은방'), findsOneWidget);
    expect(find.byKey(const Key('story-intro-computer')), findsNothing);
    expect(find.byKey(const Key('company-name-input')), findsNothing);

    await advanceDialogue(tester, 9);
    expect(find.byKey(const Key('story-intro-computer')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('visual novel onboarding saves the family research desk', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MillenniumCapitalApp());
    await tester.pumpAndSettle();

    await completeStoryOnboarding(tester);

    final companyHeader = tester.widget<Text>(
      find.byKey(const Key('company-header-title')),
    );
    expect(companyHeader.data, '별빛 투자');
    expect(companyHeader.maxLines, 1);
    expect(companyHeader.softWrap, isFalse);
    expect(find.text('가족 아파트 · 작은방'), findsOneWidget);
    expect(find.text('0원'), findsOneWidget);
    expect(find.byKey(const Key('apartment-place-bedroom')), findsOneWidget);
    expect(find.byKey(const Key('room-company-sign')), findsOneWidget);
    expect(find.textContaining('거실의 안건 편지를 먼저'), findsOneWidget);
  });

  testWidgets('existing v1 save is restored with safe story defaults', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: jsonEncode({
        'version': 1,
        'companyName': '이어하기 연구소',
        'day': 8,
        'cash': 900000,
        'team': 1,
      }),
    });

    await tester.pumpWidget(const MillenniumCapitalApp());
    await tester.pumpAndSettle();
    await continueFirstSave(tester);

    final companyHeader = tester.widget<Text>(
      find.byKey(const Key('company-header-title')),
    );
    expect(companyHeader.data, '이어하기 연구소');
    expect(find.textContaining('1월 8일 토요일'), findsWidgets);
    expect(find.byKey(const Key('room-company-name')), findsOneWidget);
  });

  testWidgets('first research sheet is one-hand operable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: jsonEncode({
        'version': 1,
        'companyName': '모바일 연구소',
        'day': 1,
        'cash': 1000000,
        'team': 1,
      }),
    });

    await tester.pumpWidget(const MillenniumCapitalApp());
    await tester.pumpAndSettle();
    await continueFirstSave(tester);
    await goToLivingRoom(tester);
    await tester.tap(find.byKey(const Key('open-decisions-button')));
    await tester.pumpAndSettle();

    expect(find.text('첫 미션: 회사 하나를 구경해 보자'), findsWidgets);
    expect(find.byKey(const Key('decision-inbox-screen')), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('decision-inbox-item-first-research-note')),
    );
    await tester.pumpAndSettle();
    final option = find.byKey(const Key('decision-option-research_products'));
    expect(option, findsOneWidget);
    expect(tester.getSize(option).height, greaterThanOrEqualTo(44));

    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('decision-inbox-screen')), findsNothing);
    expect(find.text('안건 편지'), findsOneWidget);
    expect(find.text('1월 1일 토요일 · 08:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mission board shows progress rewards level and skills', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const engine = GameEngine();
    final base = engine.createNewGame('미션 연구소');
    final state = engine.resolveDecision(
      base,
      'first-research-note',
      'research_products',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DecisionInboxScreen(
          state: state,
          onResolveDecision: (_, _) async {},
          onClaimMission: () async => engine.claimMission(state),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('미션 · 안건 보드'), findsOneWidget);
    expect(find.byKey(const Key('active-mission-card')), findsOneWidget);
    expect(find.text('첫 조사 원칙을 정하자'), findsOneWidget);
    expect(find.text('+80 XP'), findsOneWidget);
    expect(find.textContaining('첫 장부'), findsWidgets);
    final claim = tester.widget<FilledButton>(
      find.byKey(const Key('claim-mission-reward')),
    );
    expect(claim.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desk drawer opens the ledger as its own scene', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: jsonEncode({
        'version': 1,
        'companyName': '별빛 투자',
        'day': 4,
        'cash': 1000000,
        'team': 1,
      }),
    });

    await tester.pumpWidget(const MillenniumCapitalApp());
    await tester.pumpAndSettle();
    await continueFirstSave(tester);
    await dismissHubTutorial(tester);
    await tester.tap(find.byKey(const Key('open-ledger-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('portfolio-ledger-screen')), findsOneWidget);
    expect(find.text('서류함 · 포트폴리오'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('ledger-company-name'))).data,
      '별빛 투자',
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('계산 중').evaluate().isEmpty) break;
    }
    expect(find.text('계산 중'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('ledger shows valued local and pending foreign positions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = const GameEngine()
        .createNewGame('별빛 투자', initialCash: 1000000)
        .copyWith(
          day: 4,
          positions: const [
            PortfolioPosition(
              assetId: 'kr-005930',
              symbol: '005930.KS',
              name: '삼성전자',
              market: 'KOSPI',
              currency: 'KRW',
              units: 10,
              totalCost: 60000,
            ),
            PortfolioPosition(
              assetId: 'us-aapl',
              symbol: 'AAPL',
              name: '애플',
              market: 'NASDAQ',
              currency: 'USD',
              units: 2,
              totalCost: 30000,
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

    expect(find.text('삼성전자'), findsOneWidget);
    final samsungDetails = tester.widget<Text>(
      find.textContaining('10주 · 평균 6,000원'),
    );
    expect(samsungDetails.data, contains('%'));
    final samsungTile = tester.widget<ListTile>(
      find.ancestor(of: find.text('삼성전자'), matching: find.byType(ListTile)),
    );
    final samsungValue = (samsungTile.trailing! as Text).data!;
    expect(samsungValue, endsWith('원'));
    expect(samsungValue, isNot('시세 없음'));
    expect(find.text('애플'), findsOneWidget);
    expect(find.text('환율 연결 대기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ledger replays recent archived newspapers', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final base = const GameEngine().createNewGame('별빛 투자');
    final state = base.copyWith(
      day: 4,
      story: base.story.copyWith(
        storyFlags: {
          ...base.story.storyFlags,
          'newsArchive': <Map<String, dynamic>>[
            {
              'day': 4,
              'headline': '새천년 시장의 첫 기록',
              'eventIds': <String>['event-1', 'event-2'],
            },
          ],
        },
      ),
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

    final card = find.byKey(const Key('news-archive-day-4'));
    final ledgerScroll = find.descendant(
      of: find.byKey(const Key('portfolio-ledger-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(card, 300, scrollable: ledgerScroll);
    expect(card, findsOneWidget);
    expect(find.text('새천년 시장의 첫 기록'), findsOneWidget);
    expect(find.textContaining('역사 사건 2건'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('market ticks and opens a stock detail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = const GameEngine()
        .createNewGame('별빛 투자', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: krxOpenMinute);
    const engine = GameEngine();
    final persistence = GamePersistence();
    var current = state;
    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(
          state: state,
          universe: testMarketUniverse(),
          onSetMarketMinute: (minute) async {
            current = current.copyWith(marketMinute: minute);
            await persistence.save(current);
            return current;
          },
          onSaveMarketNotebook: (favorites, notes) async {
            final favoriteList = favorites.toList()..sort();
            current = current.copyWith(
              story: current.story.copyWith(
                storyFlags: <String, dynamic>{
                  ...current.story.storyFlags,
                  'marketFavoriteAssetIds': favoriteList,
                  'marketResearchNotes': <String, String>{...notes},
                },
              ),
            );
            await persistence.save(current);
            return current;
          },
          onExecuteTrade: (order) async {
            final result = engine.executeTrade(current, order);
            if (result.success) {
              current = result.state;
              await persistence.save(current);
            }
            return result;
          },
        ),
      ),
    );
    await tester.pump();
    await waitForMarketHome(tester);
    expect(find.byKey(const Key('market-snapshot-card')), findsNothing);
    expect(find.byKey(const Key('market-ranking-table')), findsOneWidget);
    expect(find.byKey(const Key('market-investment-overview')), findsNothing);
    expect(find.byKey(const Key('market-account-summary')), findsNothing);
    expect(find.byKey(const Key('market-mission-card')), findsNothing);
    expect(find.byKey(const Key('market-nav-home')), findsOneWidget);
    expect(find.byKey(const Key('market-nav-account')), findsOneWidget);
    await openMarketExplore(tester);

    expect(find.text('2000년 국내 종목'), findsOneWidget);
    expect(find.byKey(const Key('market-phone-status-bar')), findsOneWidget);
    expect(find.byKey(const Key('market-home-app-bar')), findsOneWidget);
    expect(find.byKey(const Key('market-phone-status-time')), findsOneWidget);
    expect(find.text('내 방 · CRT 투자 단말'), findsNothing);
    expect(find.text('모뎀 소리와 함께 2000년 시장 화면이 켜졌다.'), findsNothing);
    expect(find.byKey(const Key('market-mission-card')), findsNothing);
    await tester.tap(find.byKey(const Key('market-sort-name')));
    await tester.pump();
    if (find.byKey(const Key('stock-row-005930')).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.byKey(const Key('stock-row-005930')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
    }
    expect(find.byKey(const Key('stock-row-005930')), findsOneWidget);
    final clock = find.byKey(const Key('market-phone-status-time'));
    final before = tester.widget<Text>(clock.first).data;
    await tester.pump(marketRealtimeTickDuration);
    if (find.byKey(const Key('stock-rate-005930')).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.byKey(const Key('stock-row-005930')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
    }
    final after = tester.widget<Text>(clock.first).data;
    expect(after, isNot(before));
    expect(after, contains('09:01'));

    await tester.ensureVisible(find.byKey(const Key('stock-row-005930')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('stock-row-005930')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('삼성전자'), findsWidgets);
    expect(find.byKey(const Key('market-phone-status-bar')), findsWidgets);
    expect(find.byKey(const Key('stock-detail-price')), findsOneWidget);
    expect(find.byKey(const Key('minute-interval-selector')), findsOneWidget);
    expect(find.byKey(const Key('minute-candle-chart')), findsOneWidget);
    expect(find.byKey(const Key('chart-time-axis')), findsOneWidget);
    expect(find.text('재현 장중 · 현실 1초마다 게임 1분 진행'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('chart-window-label'))).data,
      contains('최대 최근 3시간'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('chart-window-label'))).data,
      allOf(contains('180개 캔들'), contains('전일 재현 포함')),
    );
    expect(find.textContaining('전일 '), findsWidgets);
    expect(find.text('오늘 09:00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('minute-interval-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3분').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('chart-window-label'))).data,
      contains('최대 최근 4시간'),
    );
    await tester.tap(find.byKey(const Key('chart-range-day')));
    await tester.pump();
    expect(find.byKey(const Key('historical-close-chart')), findsOneWidget);
    expect(find.textContaining('일봉'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chart-range-week')));
    await tester.pump();
    expect(find.textContaining('주봉'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chart-range-month')));
    await tester.pump();
    expect(find.textContaining('월봉'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chart-range-year')));
    await tester.pump();
    expect(find.byKey(const Key('historical-close-chart')), findsOneWidget);
    expect(find.textContaining('년봉'), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-market-favorite')));
    await tester.pumpAndSettle();
    final favoriteIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('toggle-market-favorite')),
        matching: find.byType(Icon),
      ),
    );
    expect(favoriteIcon.icon, Icons.star_rounded);

    await tester.scrollUntilVisible(
      find.byKey(const Key('open-market-research-note')),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -140));
    await tester.pump();
    await tester.tap(find.byKey(const Key('open-market-research-note')));
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('market-research-note-input')),
      '제품 경쟁력과 다음 실적을 확인한다.',
    );
    await tester.tap(find.byKey(const Key('save-market-research-note')));
    await tester.pumpAndSettle();
    expect(find.text('제품 경쟁력과 다음 실적을 확인한다.'), findsOneWidget);
    expect(
      (current.story.storyFlags['marketFavoriteAssetIds'] as List<dynamic>),
      contains('kr-005930'),
    );
    expect(
      (current.story.storyFlags['marketResearchNotes']
          as Map<dynamic, dynamic>)['kr-005930'],
      '제품 경쟁력과 다음 실적을 확인한다.',
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(find.byKey(const Key('buy-stock-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('buy-stock-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('현재 게임 체결가'), findsOneWidget);
    expect(find.byKey(const Key('order-quantity-value')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('request-parent-order-approval')));
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const Key('order-result')).evaluate().isNotEmpty) break;
    }
    expect(find.textContaining('1주 매수 완료'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final saved =
        jsonDecode(
              (await SharedPreferences.getInstance()).getString(
                GamePersistence.saveKey,
              )!,
            )
            as Map<String, dynamic>;
    expect((saved['positions'] as List<dynamic>), hasLength(1));
    expect(saved['cash'] as int, lessThan(1000000));
    await tester.tap(find.byKey(const Key('request-parent-order-approval')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const Key('historical-executive-section')),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('그날의 경영진'), findsOneWidget);
    expect(find.text('이건희'), findsOneWidget);
    expect(find.text('윤종용'), findsOneWidget);
    expect(
      find.byKey(const Key('executive-portrait-lee_kun_hee')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('investment tab deposit and live holdings stay in sync', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const engine = GameEngine();
    var current = engine
        .createNewGame('계좌 테스트', initialCash: 200000)
        .copyWith(
          day: 4,
          marketMinute: 9 * 60,
          cash: 179950,
          brokerageCash: 50000,
          positions: const [
            PortfolioPosition(
              assetId: 'kr-005930',
              symbol: '005930',
              name: '삼성전자',
              market: 'KOSPI',
              currency: 'KRW',
              units: 2,
              totalCost: 20050,
            ),
          ],
          ledger: const [
            LedgerEntry(
              id: 'test-buy',
              day: 4,
              amount: -20050,
              account: 'cash',
              counterAccount: 'market_security',
              description: '삼성전자 매수 · 증권 수수료 50원',
              sourceId: 'test-buy',
              notional: 20000,
              tradingFee: 50,
            ),
          ],
        );

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(
          state: current,
          universe: testMarketUniverse(),
          onSetMarketMinute: (minute) async {
            current = current.copyWith(marketMinute: minute);
            return current;
          },
          onTransferCash: (amount, deposit) async {
            final result = engine.transferBrokerageCash(
              current,
              amount: amount,
              deposit: deposit,
            );
            if (result.success) current = result.state;
            return result;
          },
        ),
      ),
    );
    await waitForMarketHome(tester);

    expect(find.byKey(const Key('market-account-summary')), findsNothing);
    expect(
      find.byKey(const Key('market-account-position-kr-005930')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('market-nav-account')));
    await tester.pump();
    expect(find.byKey(const Key('market-account-summary')), findsOneWidget);
    expect(find.byKey(const Key('market-mission-card')), findsOneWidget);
    await tester.tap(find.byKey(const Key('market-account-deposit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('brokerage-transfer-amount')),
      '10000',
    );
    await tester.tap(find.byKey(const Key('brokerage-transfer-submit')));
    await tester.pumpAndSettle();

    expect(current.brokerageCash, 60000);
    expect(current.bankCash, 119950);
    ScaffoldMessenger.of(
      tester.element(find.byKey(const Key('market-account-section'))),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('market-account-summary')), findsOneWidget);
    expect(find.textContaining('누적 증권 수수료 50원'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('market-account-position-kr-005930')),
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('market-account-section')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('market-account-position-kr-005930')),
      findsOneWidget,
    );

    final value = find.byKey(const Key('position-value-kr-005930'));
    final before = tester.widget<Text>(value).data;
    await tester.pump(const Duration(seconds: 1));
    final after = tester.widget<Text>(value).data;
    expect(after, isNot(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back saves market time before leaving', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = const GameEngine()
        .createNewGame('Back Test Capital', initialCash: 1000000)
        .copyWith(day: 4);
    final saveGate = Completer<GameState>();
    var saveCalls = 0;
    int? savedMinute;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('open-market-for-system-back'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StockMarketScreen(
                    state: state,
                    universe: testMarketUniverse(),
                    onSetMarketMinute: (minute) {
                      saveCalls += 1;
                      savedMinute = minute;
                      return saveGate.future;
                    },
                  ),
                ),
              ),
              child: const Text('Open market'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-market-for-system-back')));
    await tester.pump();
    await waitForMarketHome(tester);
    await tester.pump(marketRealtimeTickDuration);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(saveCalls, 1);
    expect(savedMinute, greaterThan(state.marketMinute));
    expect(find.byType(StockMarketScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(saveCalls, 1);

    saveGate.complete(state.copyWith(marketMinute: savedMinute!));
    await tester.pumpAndSettle();

    expect(find.byType(StockMarketScreen), findsNothing);
    expect(
      find.byKey(const Key('open-market-for-system-back')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('back waits for a successful hour save before leaving', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = const GameEngine()
        .createNewGame('Queued Exit Success', initialCash: 1000000)
        .copyWith(day: 4);
    final hourSave = Completer<GameState>();
    final requestedMinutes = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('open-market-for-hour-exit-success'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StockMarketScreen(
                    state: state,
                    universe: testMarketUniverse(),
                    onSetMarketMinute: (minute) {
                      requestedMinutes.add(minute);
                      return hourSave.future;
                    },
                  ),
                ),
              ),
              child: const Text('Open market'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const Key('open-market-for-hour-exit-success')),
    );
    await tester.pump();
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('market-clock-bar')).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.tap(find.byKey(const Key('market-advance-hour-button')));
    await tester.pump();
    expect(requestedMinutes, hasLength(1));

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(requestedMinutes, hasLength(1));
    expect(find.byType(StockMarketScreen), findsOneWidget);

    hourSave.complete(state.copyWith(marketMinute: requestedMinutes.single));
    await tester.pumpAndSettle();

    expect(requestedMinutes, hasLength(1));
    expect(find.byType(StockMarketScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back waits for a failed hour save then saves the old time', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = const GameEngine()
        .createNewGame('Queued Exit Failure', initialCash: 1000000)
        .copyWith(day: 4);
    final hourSave = Completer<GameState>();
    final requestedMinutes = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('open-market-for-hour-exit-failure'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StockMarketScreen(
                    state: state,
                    universe: testMarketUniverse(),
                    onSetMarketMinute: (minute) {
                      requestedMinutes.add(minute);
                      if (requestedMinutes.length == 1) {
                        return hourSave.future;
                      }
                      return Future.value(state.copyWith(marketMinute: minute));
                    },
                  ),
                ),
              ),
              child: const Text('Open market'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const Key('open-market-for-hour-exit-failure')),
    );
    await tester.pump();
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('market-clock-bar')).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.tap(find.byKey(const Key('market-advance-hour-button')));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(requestedMinutes, hasLength(1));
    expect(find.byType(StockMarketScreen), findsOneWidget);

    hourSave.completeError(StateError('hour save failed'));
    await tester.pumpAndSettle();

    expect(requestedMinutes, hasLength(2));
    expect(requestedMinutes[1], requestedMinutes[0] - 60);
    expect(find.byType(StockMarketScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('open market advances one game minute after one real second', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = const GameEngine()
        .createNewGame('Minute Market Test', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: 9 * 60);
    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(state: state, universe: testMarketUniverse()),
      ),
    );
    await tester.pump();
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('market-clock-bar')).evaluate().isNotEmpty) {
        break;
      }
    }
    final clock = find.byKey(const Key('market-phone-status-time'));
    expect(tester.widget<Text>(clock.first).data, contains('09:00'));

    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<Text>(clock.first).data, contains('09:00'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<Text>(clock.first).data, contains('09:01'));

    await openMarketExplore(tester);
    await tester.tap(find.byKey(const Key('stock-row-005930')));
    await tester.pumpAndSettle();
    expect(find.textContaining('1분봉'), findsWidgets);
    expect(find.textContaining('현실 1초마다 게임 1분 진행'), findsOneWidget);
    final detailPrice = find.byKey(const Key('stock-detail-price'));
    final priceBeforeTick = tester.widget<Text>(detailPrice).data;
    await tester.pump(const Duration(seconds: 1));
    final priceAfterTick = tester.widget<Text>(detailPrice).data;
    expect(priceAfterTick, isNot(priceBeforeTick));
    expect(
      tester
          .widget<Text>(find.byKey(const Key('market-phone-status-time')))
          .data,
      contains('09:'),
    );
    expect(find.byKey(const Key('chart-time-axis')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pre-open clock advances but price and one-minute candles wait', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = const GameEngine()
        .createNewGame('Pre-open Market Test', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: marketDayStartMinute);
    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(state: state, universe: testMarketUniverse()),
      ),
    );
    await openMarketExplore(tester);
    await tester.ensureVisible(find.byKey(const Key('stock-row-005930')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('stock-row-005930')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('stock-detail-price')), findsOneWidget);
    expect(find.text('개장 전 · 09:00부터 1분봉 생성'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('chart-window-label'))).data,
      contains('0개 캔들'),
    );
    final detailPrice = find.byKey(const Key('stock-detail-price'));
    final priceBeforeOpen = tester.widget<Text>(detailPrice).data;

    await tester.pump(const Duration(seconds: 2));

    expect(tester.widget<Text>(detailPrice).data, priceBeforeOpen);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('market-phone-status-time')))
          .data,
      contains('08:'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'market clock pauses while the brokerage transfer sheet is open',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = const GameEngine()
          .createNewGame('이체 시계 정지 테스트', initialCash: 1000000)
          .copyWith(day: 4, marketMinute: 9 * 60, brokerageCash: 500000);

      await tester.pumpWidget(
        MaterialApp(
          home: StockMarketScreen(
            state: state,
            universe: testMarketUniverse(),
            onTransferCash: (amount, deposit) async => const GameEngine()
                .transferBrokerageCash(state, amount: amount, deposit: deposit),
          ),
        ),
      );
      await waitForMarketHome(tester);
      final clock = find.byKey(const Key('market-phone-status-time'));

      await tester.tap(find.byKey(const Key('market-nav-account')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('market-account-deposit')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('brokerage-transfer-amount')),
        findsOneWidget,
      );
      final pausedAt = tester.widget<Text>(clock.first).data;
      await tester.pump(const Duration(seconds: 2));
      expect(tester.widget<Text>(clock.first).data, pausedAt);

      Navigator.of(
        tester.element(find.byKey(const Key('brokerage-transfer-amount'))),
      ).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('market clock pauses while the order sheet is open', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = const GameEngine()
        .createNewGame('주문 시계 정지 테스트', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: 9 * 60);

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(state: state, universe: testMarketUniverse()),
      ),
    );
    await openMarketExplore(tester);
    await tester.tap(find.byKey(const Key('stock-row-005930')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('buy-stock-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-quantity-value')), findsOneWidget);

    final clock = find.byKey(const Key('market-phone-status-time'));
    final pausedAt = tester.widget<Text>(clock.first).data;
    await tester.pump(const Duration(seconds: 2));
    expect(tester.widget<Text>(clock.first).data, pausedAt);

    Navigator.of(
      tester.element(find.byKey(const Key('order-quantity-value'))),
    ).pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('first buy is visibly locked until seed-money authority opens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final base = const GameEngine().createNewGame('주문 권한 표시 테스트');
    final state = base.copyWith(
      day: 4,
      marketMinute: 9 * 60,
      cash: 1000000,
      brokerageCash: 1000000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(state: state, universe: testMarketUniverse()),
      ),
    );
    await openMarketExplore(tester);
    await tester.tap(find.byKey(const Key('stock-row-005930')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('buy-stock-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order-authority-warning')), findsOneWidget);
    expect(find.textContaining('10,000원 달성 후'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('request-parent-order-approval')),
    );
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'market quick jumps are only enabled in their allowed time windows',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final requestedMinutes = <int>[];
      final state = const GameEngine()
          .createNewGame('Quick Jump Test', initialCash: 1000000)
          .copyWith(day: 4, marketMinute: marketDayStartMinute);
      await tester.pumpWidget(
        MaterialApp(
          home: StockMarketScreen(
            state: state,
            universe: testMarketUniverse(),
            onSetMarketMinute: (minute) async {
              requestedMinutes.add(minute);
              return state.copyWith(marketMinute: minute);
            },
          ),
        ),
      );
      await tester.pump();
      for (var attempt = 0; attempt < 20; attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byKey(const Key('market-clock-bar')).evaluate().isNotEmpty) {
          break;
        }
      }

      FilledButton button(String key) =>
          tester.widget<FilledButton>(find.byKey(Key(key)));

      expect(button('market-jump-open-button').onPressed, isNotNull);
      expect(button('market-jump-close-button').onPressed, isNull);
      expect(
        tester.widget<Text>(find.byKey(const Key('market-header-status'))).data,
        contains('개장 준비'),
      );

      await tester.tap(find.byKey(const Key('market-jump-open-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(requestedMinutes, <int>[krxOpenMinute]);
      final clock = find.byKey(const Key('market-phone-status-time'));
      expect(tester.widget<Text>(clock.first).data, contains('09:00'));
      expect(button('market-jump-open-button').onPressed, isNull);
      expect(button('market-jump-close-button').onPressed, isNotNull);
      expect(
        tester.widget<Text>(find.byKey(const Key('market-header-status'))).data,
        contains('KRX 정규장'),
      );
      expect(
        find.byKey(const Key('market-session-open-dialog')),
        findsOneWidget,
      );
      expect(find.text('장이 시작되었습니다'), findsOneWidget);
      expect(
        find.byKey(const Key('market-session-close-dialog')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('market-session-notice-confirm')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('market-jump-close-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(requestedMinutes, <int>[krxOpenMinute, krxCloseMinute]);
      expect(tester.widget<Text>(clock.first).data, contains('15:30'));
      expect(button('market-jump-open-button').onPressed, isNull);
      expect(button('market-jump-close-button').onPressed, isNull);
      expect(
        tester.widget<Text>(find.byKey(const Key('market-header-status'))).data,
        contains('오늘 장 마감'),
      );
      expect(
        find.byKey(const Key('market-session-close-dialog')),
        findsOneWidget,
      );
      expect(find.text('장이 마감되었습니다'), findsOneWidget);
      await tester.tap(find.byKey(const Key('market-session-notice-confirm')));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 1));
      expect(button('market-jump-close-button').onPressed, isNull);
      expect(tester.widget<Text>(clock.first).data, contains('15:30'));
      expect(
        tester.widget<Text>(find.byKey(const Key('market-header-status'))).data,
        contains('오늘 장 마감'),
      );
      expect(find.textContaining('NXT'), findsNothing);
      expect(find.byKey(const Key('market-session-open-dialog')), findsNothing);
      expect(
        find.byKey(const Key('market-session-close-dialog')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed hour save does not publish the future market time', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = const GameEngine()
        .createNewGame('Hour Save Test', initialCash: 1000000)
        .copyWith(day: 4);
    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(
          state: state,
          universe: testMarketUniverse(),
          onSetMarketMinute: (_) async => throw StateError('save failed'),
        ),
      ),
    );
    await tester.pump();
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('market-clock-bar')).evaluate().isNotEmpty) {
        break;
      }
    }

    final clock = find.byKey(const Key('market-phone-status-time'));
    final before = tester.widget<Text>(clock.first).data;

    await tester.tap(find.byKey(const Key('market-advance-hour-button')));
    await tester.pump();

    expect(tester.widget<Text>(clock.first).data, before);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const Key('market-advance-hour-button')),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('trade save failure unlocks the order sheet for retry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var current = const GameEngine()
        .createNewGame('Trade Failure Test', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: krxOpenMinute);
    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(
          state: current,
          universe: testMarketUniverse(),
          onSetMarketMinute: (minute) async {
            current = current.copyWith(marketMinute: minute);
            return current;
          },
          onExecuteTrade: (_) async => throw StateError('trade save failed'),
        ),
      ),
    );
    await tester.pump();
    await openMarketExplore(tester);

    await tester.ensureVisible(find.byKey(const Key('stock-row-005930')));
    await tester.tap(find.byKey(const Key('stock-row-005930')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('buy-stock-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request-parent-order-approval')));
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const Key('order-result')).evaluate().isNotEmpty) break;
    }

    expect(find.textContaining('주문을 저장하지 못했어요'), findsWidgets);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('request-parent-order-approval')),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'organization uses upper-body portrait and cards for assignment',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        GamePersistence.saveKey: jsonEncode({
          'version': 1,
          'companyName': '가족 배치 연구소',
          'day': 1,
          'cash': 1000000,
          'team': 1,
        }),
      });

      await tester.pumpWidget(const MillenniumCapitalApp());
      await tester.pumpAndSettle();
      await continueFirstSave(tester);
      await goToLivingRoom(tester);
      await tester.ensureVisible(
        find.byKey(const Key('open-organization-button')),
      );
      await tester.tap(find.byKey(const Key('open-organization-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('employee-count-badge')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('organization-company-name')))
            .data,
        '가족 배치 연구소',
      );
      expect(find.text('정식 직원 0명'), findsOneWidget);
      expect(
        find.byKey(const Key('assignment-portrait-mother')),
        findsOneWidget,
      );

      final fatherCard = find.byKey(const Key('assignment-card-father'));
      await tester.ensureVisible(fatherCard);
      await tester.tap(fatherCard);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('assignment-portrait-father')),
        findsOneWidget,
      );

      final helpButton = find.byKey(const Key('family-help-father'));
      await tester.ensureVisible(helpButton);
      await tester.tap(helpButton);
      await tester.pumpAndSettle();
      expect(find.text('오늘 도움 완료'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'dish mini-game requires the full cleaning sequence before reward',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: DishwashingMiniGame()));
      await tester.pump();
      expect(find.byKey(const Key('dish-sequence-preview')), findsOneWidget);

      const sequences = <List<String>>[
        ['rinse', 'scrub', 'finish'],
        ['scrub', 'rinse', 'finish'],
        ['rinse', 'rinse', 'finish'],
        ['scrub', 'scrub', 'finish'],
        ['rinse', 'scrub', 'finish'],
      ];
      for (final sequence in sequences) {
        await tester.pump(const Duration(milliseconds: 1400));
        expect(find.byKey(const Key('dish-recall-prompt')), findsOneWidget);
        for (final action in sequence) {
          await tester.tap(find.byKey(Key('dish-$action')));
          await tester.pump();
        }
      }

      expect(find.byKey(const Key('work-result-card')), findsOneWidget);
      expect(find.text('100점'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('daily work limit resets visually on the next game day', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final base = const GameEngine().createNewGame('일거리 날짜 초기화 테스트');
    final state = base.copyWith(
      day: 2,
      story: base.story.copyWith(
        storyFlags: <String, dynamic>{
          ...base.story.storyFlags,
          'workDay': 1,
          'workSessionsToday': 3,
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SeedMoneyHubScreen(state: state, onComplete: (_) async => state),
      ),
    );
    await tester.pump();

    expect(find.text('오늘 0 / 3'), findsOneWidget);
    expect(find.byKey(const Key('daily-work-limit')), findsNothing);
    final dishes = tester.widget<InkWell>(
      find.byKey(const Key('work-activity-dishes')),
    );
    expect(dishes.onTap, isNotNull);
    dishes.onTap!();
    await tester.pumpAndSettle();
    expect(find.byType(DishwashingMiniGame), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stationery mini-game sorts every item into its period shop shelf',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: StationerySortMiniGame()),
      );
      await tester.pumpAndSettle();

      for (final category in [
        'school',
        'school',
        'snack',
        'toy',
        'school',
        'snack',
        'toy',
        'school',
      ]) {
        await tester.tap(find.byKey(Key('sort-$category')));
        await tester.pump();
      }

      expect(find.byKey(const Key('work-result-card')), findsOneWidget);
      expect(find.text('100점'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('flea market mini-game checks real won change calculations', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: FleaMarketMiniGame()));
    await tester.pumpAndSettle();

    for (final change in [800, 2500, 3200, 6500, 5800]) {
      await tester.tap(find.byKey(Key('change-$change')));
      await tester.pump();
    }

    expect(find.byKey(const Key('work-result-card')), findsOneWidget);
    expect(find.text('100점'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'completed work adds cash and returns to the persistent work hub',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        GamePersistence.saveKey: jsonEncode({
          'version': 1,
          'companyName': '0원 연구소',
          'day': 1,
          'cash': 0,
          'team': 1,
        }),
      });

      await tester.pumpWidget(const MillenniumCapitalApp());
      await tester.pumpAndSettle();
      await continueFirstSave(tester);
      await goToKitchen(tester);
      await tester.ensureVisible(find.byKey(const Key('open-work-button')));
      await tester.tap(find.byKey(const Key('open-work-button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('시간당 1,600원'), findsOneWidget);

      await tester.tap(find.byKey(const Key('work-activity-dishes')));
      await tester.pump();
      const sequences = <List<String>>[
        ['rinse', 'scrub', 'finish'],
        ['scrub', 'rinse', 'finish'],
        ['rinse', 'rinse', 'finish'],
        ['scrub', 'scrub', 'finish'],
        ['rinse', 'scrub', 'finish'],
      ];
      for (final sequence in sequences) {
        await tester.pump(const Duration(milliseconds: 1400));
        for (final action in sequence) {
          await tester.tap(find.byKey(Key('dish-$action')));
          await tester.pump();
        }
      }
      await tester.tap(find.byKey(const Key('claim-work-reward')));
      await tester.pumpAndSettle();

      final cash = tester.widget<Text>(
        find.byKey(const Key('seed-money-cash')),
      );
      expect(cash.data, '880원');
      final clock = tester.widget<Text>(
        find.byKey(const Key('scene-clock-time')),
      );
      expect(clock.data, '09:00');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('hour and day advance controls stay distinct when unlocked', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const engine = GameEngine();
    final state = engine
        .createNewGame('시간 진행 테스트', initialCash: 1000000)
        .copyWith(decisions: const [], marketMinute: krxOpenMinute);
    int? requestedMinute;

    Widget buildOffice(GameState currentState) => MaterialApp(
      home: OfficeScreen(
        state: currentState,
        engine: engine,
        activeSaveSlot: 1,
        lastSavedAt: null,
        onManualSave: () async {},
        onReturnToTitle: () {},
        onAdvanceDay: () async => currentState,
        onSetMarketMinute: (minute) async {
          requestedMinute = minute;
          return currentState.copyWith(marketMinute: minute);
        },
        onSaveMarketNotebook: (_, _) async => currentState,
        onResolveDecision: (_, _) async {},
        onRequestFamilyHelp: (_) async => currentState,
        onCompleteWork: (_) async => currentState,
        onExecuteTrade: (_) async => TradeExecutionResult(
          state: currentState,
          success: false,
          message: 'test',
        ),
      ),
    );

    await tester.pumpWidget(buildOffice(state));
    await tester.pumpAndSettle();
    expect(find.text('09:00 · 아파트 생활'), findsOneWidget);
    expect(find.text('KRX 정규장'), findsNothing);

    final hourFinder = find.byKey(const Key('advance-hour-button'));
    final dayFinder = find.byKey(const Key('advance-day-button'));
    expect(tester.widget<ElevatedButton>(hourFinder).onPressed, isNotNull);
    expect(tester.widget<ElevatedButton>(dayFinder).onPressed, isNotNull);

    await tester.tap(hourFinder);
    await tester.pump();
    expect(requestedMinute, state.marketMinute + 60);

    await tester.pumpWidget(
      buildOffice(state.copyWith(marketMinute: marketDayEndMinute)),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(hourFinder).onPressed, isNull);
    expect(tester.widget<ElevatedButton>(dayFinder).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('day advance commits market close before showing results', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const engine = GameEngine();
    final state = engine
        .createNewGame('하루 진행 안전 테스트', initialCash: initialCompanyCash)
        .copyWith(decisions: const []);
    final closeCommit = Completer<GameState>();
    int? requestedMinute;

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
          onSetMarketMinute: (minute) {
            requestedMinute = minute;
            return closeCommit.future;
          },
          onSaveMarketNotebook: (_, _) async => state,
          onResolveDecision: (_, _) async {},
          onRequestFamilyHelp: (_) async => state,
          onCompleteWork: (_) async => state,
          onExecuteTrade: (_) async => TradeExecutionResult(
            state: state,
            success: false,
            message: 'test',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('advance-day-button')));
    await tester.pump();
    expect(requestedMinute, marketDayEndMinute);

    await tester.pumpWidget(const SizedBox.shrink());
    closeCommit.complete(state.copyWith(marketMinute: marketDayEndMinute));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(390, 844), const Size(360, 800)]) {
    testWidgets(
      'office has no layout exception at ${size.width}x${size.height}',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({
          GamePersistence.saveKey: jsonEncode({
            'version': 1,
            'companyName': '아주 긴 이름의 모바일 투자 연구소',
            'day': 1,
            'cash': 1000000,
            'team': 1,
          }),
        });

        await tester.pumpWidget(const MillenniumCapitalApp());
        await tester.pumpAndSettle();
        await continueFirstSave(tester);

        final hourFinder = find.byKey(const Key('advance-hour-button'));
        final dayFinder = find.byKey(const Key('advance-day-button'));
        expect(hourFinder, findsOneWidget);
        expect(dayFinder, findsOneWidget);
        expect(find.text('1시간 보내기'), findsOneWidget);
        expect(find.text('하루 보내기'), findsOneWidget);

        final hourButton = tester.widget<ElevatedButton>(hourFinder);
        final dayButton = tester.widget<ElevatedButton>(dayFinder);
        expect(hourButton.onPressed, isNull);
        expect(dayButton.onPressed, isNull);
        expect(tester.getSize(hourFinder).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(dayFinder).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
