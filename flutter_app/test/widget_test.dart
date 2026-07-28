import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_persistence.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_quote.dart';
import 'package:millennium_capital/game/market_tick.dart';
import 'package:millennium_capital/game/story_state.dart';
import 'package:millennium_capital/game/seed_money_content.dart';
import 'package:millennium_capital/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/market_fixture.dart';

Future<void> _skipCampaignWorldPreparation(
  GameState state,
  WorldLoadProgressCallback onProgress,
) async {}

typedef _DisplayedOrderBookTrade = ({
  int price,
  int printedQuantity,
  int displayedQuantity,
  bool isBuy,
});

int _displayedOrderBookNumber(WidgetTester tester, Finder finder) {
  final label = tester.widget<Text>(finder).data!;
  return int.parse(label.replaceAll(RegExp(r'[^0-9]'), ''));
}

Map<int, int> _displayedOrderBookQuantities(WidgetTester tester) {
  final quantities = <int, int>{};
  for (final side in const ['ask', 'bid']) {
    final quantityCellKey = ValueKey(
      side == 'ask'
          ? 'order-book-sell-quantity-cell'
          : 'order-book-buy-quantity-cell',
    );
    for (var index = 0; index < 6; index += 1) {
      final row = find.byKey(ValueKey('order-book-$side-$index'));
      if (row.evaluate().isEmpty) continue;
      final price = _displayedOrderBookNumber(
        tester,
        find
            .descendant(
              of: row,
              matching: find.byKey(const ValueKey('order-book-price-label')),
            )
            .first,
      );
      final quantity = _displayedOrderBookNumber(
        tester,
        find
            .descendant(
              of: find.descendant(
                of: row,
                matching: find.byKey(quantityCellKey),
              ),
              matching: find.byType(Text),
            )
            .first,
      );
      quantities[price] = quantity;
    }
  }
  return quantities;
}

_DisplayedOrderBookTrade _displayedOrderBookTrade(WidgetTester tester) {
  final activeTrade = find.byKey(const Key('order-book-active-trade'));
  expect(activeTrade, findsOneWidget);
  final text = tester.widget<Text>(activeTrade).data!;
  final match = RegExp(r'^(매수|매도) 체결 ([\d,]+)주$').firstMatch(text);
  expect(match, isNotNull, reason: '체결 문구는 방향과 실제 체결수량을 안정적으로 노출해야 합니다: $text');
  final isBuy = match!.group(1) == '매수';
  final printedQuantity = int.parse(match.group(2)!.replaceAll(',', ''));
  final expectedSide = isBuy ? 'ask' : 'bid';
  final quantityCellKey = ValueKey(
    isBuy ? 'order-book-sell-quantity-cell' : 'order-book-buy-quantity-cell',
  );

  Finder? activeRow;
  for (var index = 0; index < 6; index += 1) {
    final row = find.byKey(ValueKey('order-book-$expectedSide-$index'));
    if (find.descendant(of: row, matching: activeTrade).evaluate().isNotEmpty) {
      activeRow = row;
      break;
    }
  }
  expect(
    activeRow,
    isNotNull,
    reason: '${isBuy ? '매수' : '매도'} 체결 문구는 반대편 실제 체결 호가 행 안에 있어야 합니다.',
  );
  final price = _displayedOrderBookNumber(
    tester,
    find
        .descendant(
          of: activeRow!,
          matching: find.byKey(const ValueKey('order-book-price-label')),
        )
        .first,
  );
  final displayedQuantity = _displayedOrderBookNumber(
    tester,
    find
        .descendant(
          of: find.descendant(
            of: activeRow,
            matching: find.byKey(quantityCellKey),
          ),
          matching: find.byType(Text),
        )
        .first,
  );
  return (
    price: price,
    printedQuantity: printedQuantity,
    displayedQuantity: displayedQuantity,
    isBuy: isBuy,
  );
}

ValueNotifier<int> _orderBookPulseNotifier(WidgetTester tester) {
  final notifiers = <ValueNotifier<int>>[];
  tester
      .element(find.byKey(const Key('stock-order-book')))
      .visitAncestorElements((element) {
        final widget = element.widget;
        if (widget is ValueListenableBuilder<int> &&
            widget.valueListenable is ValueNotifier<int>) {
          notifiers.add(widget.valueListenable as ValueNotifier<int>);
        }
        return true;
      });
  expect(notifiers, isNotEmpty, reason: '호가창 미세구조 프레임 notifier를 찾을 수 있어야 합니다.');
  return notifiers.first;
}

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
    final home = find.byKey(const Key('market-home-section'));
    for (var attempt = 0; attempt < 300; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (home.evaluate().isNotEmpty) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    expect(
      home,
      findsOneWidget,
      reason: 'Background market generation did not finish within 6 seconds.',
    );
  }

  Future<void> waitForFinderToDisappear(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (finder.evaluate().isNotEmpty && stopwatch.elapsed < timeout) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isEmpty) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
    }
    expect(
      finder,
      findsNothing,
      reason: 'Background work did not finish within ${timeout.inSeconds}s.',
    );
  }

  Future<void> advanceTutorialPagesToTarget(
    WidgetTester tester, {
    required Key actionKey,
    required Key targetKey,
  }) async {
    final action = find.byKey(actionKey);
    final target = find.byKey(targetKey);
    for (var attempt = 0; attempt < 16; attempt++) {
      await tester.pump();
      if (target.evaluate().isNotEmpty) return;
      expect(action, findsOneWidget);
      await tester.tap(action);
      await tester.pump(const Duration(milliseconds: 650));
    }
    expect(target, findsOneWidget);
  }

  Future<void> advanceTutorialPagesUntilDismissed(
    WidgetTester tester, {
    required Key actionKey,
    required Key overlayKey,
  }) async {
    final action = find.byKey(actionKey);
    final overlay = find.byKey(overlayKey);
    for (var attempt = 0; attempt < 8; attempt++) {
      await tester.pump();
      if (overlay.evaluate().isEmpty) return;
      expect(action, findsOneWidget);
      await tester.tap(action);
      await tester.pump();
    }
    expect(overlay, findsNothing);
  }

  Future<void> completeGuidedMarketAndReturnHome(WidgetTester tester) async {
    await waitForMarketHome(tester);
    await tester.pump(const Duration(milliseconds: 600));
    await advanceTutorialPagesToTarget(
      tester,
      actionKey: const Key('market-tutorial-next'),
      targetKey: const Key('market-tutorial-target'),
    );
    await tester.tap(find.byKey(const Key('market-tutorial-target')));
    await tester.pump(const Duration(milliseconds: 750));
    await advanceTutorialPagesToTarget(
      tester,
      actionKey: const Key('market-tutorial-next'),
      targetKey: const Key('market-tutorial-target'),
    );
    await tester.tap(find.byKey(const Key('market-tutorial-target')));
    await tester.pump(const Duration(milliseconds: 800));
    await advanceTutorialPagesToTarget(
      tester,
      actionKey: const Key('market-detail-tutorial-next'),
      targetKey: const Key('market-detail-tutorial-target'),
    );
    await tester.tap(find.byKey(const Key('market-detail-tutorial-target')));
    await tester.pump(const Duration(milliseconds: 600));
    await advanceTutorialPagesToTarget(
      tester,
      actionKey: const Key('market-detail-tutorial-next'),
      targetKey: const Key('market-detail-tutorial-target'),
    );
    await tester.tap(find.byKey(const Key('market-detail-tutorial-target')));
    await tester.pump(const Duration(milliseconds: 700));
    await advanceTutorialPagesToTarget(
      tester,
      actionKey: const Key('market-detail-tutorial-next'),
      targetKey: const Key('market-detail-tutorial-target'),
    );
    await tester.tap(find.byKey(const Key('market-detail-tutorial-target')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    await advanceTutorialPagesUntilDismissed(
      tester,
      actionKey: const Key('market-order-tutorial-done'),
      overlayKey: const Key('market-order-tutorial-overlay'),
    );
    expect(
      find.byKey(const Key('market-order-tutorial-overlay')),
      findsNothing,
    );
    expect(find.byKey(const Key('market-practical-tutorial')), findsOneWidget);
    expect(find.textContaining('1,000,000원'), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const Key('request-parent-order-approval')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-parent-order-approval')));
    await tester.pump();
    expect(find.byKey(const Key('order-result')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('request-parent-order-approval')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-parent-order-approval')));
    await tester.pump();
    expect(find.byKey(const Key('tutorial-price-change')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.ensureVisible(
      find.byKey(const Key('tutorial-price-change-continue')),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('tutorial-price-change-continue')));
    await tester.pump();
    expect(find.byKey(const Key('tutorial-sell-order')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('request-parent-order-approval')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-parent-order-approval')));
    await tester.pump();
    expect(find.byKey(const Key('order-result')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('request-parent-order-approval')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-parent-order-approval')));
    await tester.pump();
    expect(find.byKey(const Key('tutorial-trade-summary')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutorial-summary-continue')));
    await tester.pump();
    expect(find.byKey(const Key('tutorial-post-trade-review')), findsOneWidget);
    for (var reviewBeat = 0; reviewBeat < 4; reviewBeat += 1) {
      await tester.tap(find.byKey(const Key('tutorial-review-continue')));
      await tester.pump();
    }
    expect(find.byKey(const Key('tutorial-school-dismissal')), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('market-practical-tutorial-complete')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('market-practical-tutorial')), findsNothing);
    expect(
      find.byKey(const Key('academy-market-tutorial-screen')),
      findsNothing,
    );
    expect(find.byKey(const Key('apartment-place-bedroom')), findsOneWidget);
  }

  Future<void> openMarketExplore(WidgetTester tester) async {
    await waitForMarketHome(tester);
    await tester.tap(find.byKey(const Key('market-nav-explore')));
    await tester.pump();
    for (var attempt = 0; attempt < 30; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('stock-row-1001')).evaluate().isNotEmpty) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -240));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('stock-row-1001')));
        return;
      }
    }
  }

  void expectSymmetricInlineOrderBook(WidgetTester tester) {
    final askRows = find.byKey(const ValueKey('inline-order-book-ask-row'));
    final bidRows = find.byKey(const ValueKey('inline-order-book-bid-row'));
    expect(askRows, findsNWidgets(6));
    expect(bidRows, findsNWidgets(6));

    final highestBidRow = bidRows.first;
    final lowestAskRow = askRows.last;
    expect(
      tester.getCenter(lowestAskRow).dy,
      lessThan(tester.getCenter(highestBidRow).dy),
    );

    final border = find.byKey(
      const Key('inline-order-book-current-price-border'),
    );
    expect(border, findsOneWidget);
    final animatedBorder = tester.widget<AnimatedPositioned>(border);
    expect(animatedBorder.duration, const Duration(milliseconds: 72));
    final bestAskSlot = tester.widget<Positioned>(
      find.ancestor(of: lowestAskRow, matching: find.byType(Positioned)).first,
    );
    final bestBidSlot = tester.widget<Positioned>(
      find.ancestor(of: highestBidRow, matching: find.byType(Positioned)).first,
    );
    expect(
      animatedBorder.top,
      anyOf(bestAskSlot.top, bestBidSlot.top),
      reason: '인라인 공유 테두리는 중앙 두 고정 슬롯 사이에서만 움직여야 한다.',
    );
    final borderY = tester.getCenter(border).dy;
    expect(
      borderY,
      anyOf(
        closeTo(tester.getCenter(lowestAskRow).dy, 1),
        closeTo(tester.getCenter(highestBidRow).dy, 1),
      ),
      reason: '인라인 체결가 테두리는 중앙 최우선 매도·매수 두 칸만 오가야 한다.',
    );
  }

  Future<void> goToLivingRoom(WidgetTester tester) async {
    await dismissHubTutorial(tester);
    await tester.tap(find.byKey(const Key('apartment-go-living-room')));
    await tester.pumpAndSettle();
  }

  Future<void> completeStoryOnboarding(WidgetTester tester) async {
    await startNewGame(tester);
    await advanceDialogue(tester, 10);
    await tester.tap(find.byKey(const Key('story-intro-computer')));
    await tester.pumpAndSettle();

    await advanceDialogue(tester, 11);
    expect(find.byKey(const Key('academy-tuition-pay-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('academy-tuition-pay-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('academy-tuition-debit')), findsOneWidget);
    await tester.tap(find.byKey(const Key('academy-registration-continue')));
    await tester.pumpAndSettle();
    await advanceDialogue(tester, 5);
    await tester.tap(find.byKey(const Key('academy-tutorial-continue')));
    await tester.pumpAndSettle();
    await advanceDialogue(tester, 1);
    await tester.enterText(find.byKey(const Key('player-name-input')), '민준');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('story-next-name')));
    final playerNameRect = tester.getRect(
      find.byKey(const Key('player-name-input')),
    );
    final playerNameButtonRect = tester.getRect(
      find.byKey(const Key('story-next-name')),
    );
    expect(playerNameButtonRect.top - playerNameRect.bottom, closeTo(16, 0.01));
    await tester.tap(find.byKey(const Key('story-next-name')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('story-trait-analysis')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expect(find.textContaining('작은 주문표'), findsOneWidget);
    expect(find.textContaining('세뱃돈 장부'), findsNothing);
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expect(find.textContaining('오늘부터 지킬 약속'), findsOneWidget);

    await tester.tap(find.byKey(const Key('family-rule-report-losses')));
    await tester.pumpAndSettle();
    expect(find.textContaining('손해가 나도 숨기지 않고'), findsOneWidget);
    expect(find.textContaining('아빠가 먼저 낸'), findsNothing);
    expect(find.textContaining('외할아버지의 세뱃돈'), findsNothing);
    await advanceDialogue(tester, 2);
    await tester.enterText(
      find.byKey(const Key('company-name-input')),
      '별빛 투자',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('create-company-button')));
    final investmentNoteRect = tester.getRect(
      find.byKey(const Key('company-name-input')),
    );
    final investmentNoteButtonRect = tester.getRect(
      find.byKey(const Key('create-company-button')),
    );
    expect(
      investmentNoteButtonRect.top - investmentNoteRect.bottom,
      closeTo(16, 0.01),
    );
    await tester.tap(find.byKey(const Key('create-company-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('academy-market-tutorial-screen')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('apartment-place-bedroom')), findsNothing);
    await completeGuidedMarketAndReturnHome(tester);
    await dismissHubTutorial(tester);
  }

  testWidgets('prologue explains the setting before showing a choice', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MillenniumCapitalApp(
        campaignWorldPreparer: _skipCampaignWorldPreparation,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('game-title-screen')), findsOneWidget);
    expect(find.text('초딩부터 건물주'), findsOneWidget);
    expect(find.text('처음하기'), findsOneWidget);
    expect(find.text('이어하기'), findsOneWidget);

    await startNewGame(tester);

    expect(find.byKey(const Key('onboarding-exit-button')), findsNothing);
    expect(find.textContaining('TV 드라마에서 작은 회사'), findsOneWidget);
    expect(find.textContaining('거실 · TV 앞'), findsOneWidget);
    expect(find.byKey(const Key('story-intro-computer')), findsNothing);
    expect(find.byKey(const Key('company-name-input')), findsNothing);

    await advanceDialogue(tester, 1);
    expect(find.textContaining('나도 주식 해 보고 싶어요'), findsOneWidget);
    Finder storyCharacterAsset(String assetName) => find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == assetName,
    );
    expect(
      storyCharacterAsset('assets/images/character_hero_title_style_v2.png'),
      findsOneWidget,
    );
    final heroCharacterRect = tester.getRect(
      find.byKey(const Key('story-character-character')),
    );
    expect(heroCharacterRect.left, closeTo(7.28, 0.01));
    expect(heroCharacterRect.top, closeTo(158.84, 0.01));
    expect(heroCharacterRect.width, closeTo(375.44, 0.01));
    expect(heroCharacterRect.height, closeTo(563.16, 0.01));
    expect(heroCharacterRect.bottom, closeTo(722, 0.01));
    expect(heroCharacterRect.center.dx, closeTo(195, 0.01));

    await advanceDialogue(tester, 1);
    expect(
      storyCharacterAsset('assets/images/character_sister_title_style_v2.png'),
      findsOneWidget,
    );
    await advanceDialogue(tester, 1);
    expect(
      storyCharacterAsset('assets/images/character_mother_title_style_v2.png'),
      findsOneWidget,
    );
    await advanceDialogue(tester, 1);
    expect(
      storyCharacterAsset('assets/images/character_father_title_style_v2.png'),
      findsOneWidget,
    );
    await advanceDialogue(tester, 2);
    expect(find.textContaining('100만 원'), findsOneWidget);
    await advanceDialogue(tester, 4);
    expect(find.byKey(const Key('story-intro-computer')), findsOneWidget);
    await tester.tap(find.byKey(const Key('story-intro-computer')));
    await tester.pumpAndSettle();
    await advanceDialogue(tester, 7);
    expect(find.textContaining('이제 정말 출발하는 거죠'), findsOneWidget);
    expect(
      storyCharacterAsset('assets/images/character_hero_determined_v1.png'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pump();
    expect(find.byKey(const Key('academy-travel-loading')), findsOneWidget);
    expect(find.text('학원으로 이동 중…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('academy-travel-loading')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('academy-travel-loading')), findsNothing);
    final entranceBackground = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/bg_stock_academy_entrance_2000_portrait_cartoon_v1.png',
      ),
    );
    expect(
      (entranceBackground.image as AssetImage).assetName,
      'assets/images/bg_stock_academy_entrance_2000_portrait_cartoon_v1.png',
    );
    expect(find.textContaining('학생들이 노트와 서류철'), findsOneWidget);
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expect(find.textContaining('학생이 이렇게 많아'), findsOneWidget);
    expect(
      storyCharacterAsset('assets/images/character_hero_questioning_v1.png'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('academy-receptionist-character')),
      findsOneWidget,
    );
    expect(
      storyCharacterAsset(
        'assets/images/character_academy_receptionist_v1.png',
      ),
      findsOneWidget,
    );
    expect(
      tester.getRect(find.byKey(const Key('academy-receptionist-character'))),
      heroCharacterRect,
    );
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('academy-tuition-pay-button')), findsOneWidget);
    expect(
      find.byKey(const Key('academy-investment-cash-preserved')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('academy-tuition-debit')), findsNothing);
    await tester.tap(find.byKey(const Key('academy-tuition-pay-button')));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('academy-tuition-debit')), findsOneWidget);
    expect(find.text('-1,000,000원'), findsOneWidget);
    expect(
      find.byKey(const Key('academy-tuition-debt-created')),
      findsOneWidget,
    );
    expect(find.text('10,000원 그대로'), findsOneWidget);
    await tester.tap(find.byKey(const Key('academy-registration-continue')));
    await tester.pumpAndSettle();
    await advanceDialogue(tester, 5);
    final academyBackground = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/bg_stock_academy_2000_portrait_cartoon_v4.png',
      ),
    );
    expect(
      (academyBackground.image as AssetImage).assetName,
      'assets/images/bg_stock_academy_2000_portrait_cartoon_v4.png',
    );
    expect(find.byKey(const Key('academy-teacher-character')), findsOneWidget);
    final teacherRect = tester.getRect(
      find.byKey(const Key('academy-teacher-character')),
    );
    expect(teacherRect, heroCharacterRect);
    expect(teacherRect.left, closeTo(7.28, 0.01));
    expect(teacherRect.top, closeTo(158.84, 0.01));
    expect(teacherRect.width, closeTo(375.44, 0.01));
    expect(teacherRect.height, closeTo(563.16, 0.01));
    expect(teacherRect.bottom, closeTo(722, 0.01));
    expect(teacherRect.center.dx, closeTo(195, 0.01));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/주식선생님/23_포즈2_주인공그림체_공통슬롯_투명.png',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('academy-tutorial-continue')), findsOneWidget);
    expect(find.text('시장가와 지정가'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('academy-tutorial-continue')));
    await tester.pumpAndSettle();
    expect(
      storyCharacterAsset('assets/images/character_hero_thoughtful_v1.png'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('academy-teacher-character')), findsNothing);
    expect(
      tester.getRect(find.byKey(const Key('story-character-character'))),
      teacherRect,
    );
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/주식선생님/27_포즈6_주인공그림체_공통슬롯_투명.png',
      ),
      findsOneWidget,
    );
    expect(
      tester.getRect(find.byKey(const Key('academy-teacher-character'))),
      teacherRect,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('bright cartoon title fits supported mobile viewports', (
    tester,
  ) async {
    const sizes = [Size(360, 800), Size(390, 844), Size(419, 860)];
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        const MillenniumCapitalApp(
          campaignWorldPreparer: _skipCampaignWorldPreparation,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('초딩부터 건물주'), findsOneWidget);
      expect(find.byKey(const Key('title-cartoon-hero')), findsOneWidget);
      expect(
        find.byKey(const Key('new-game-button')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('continue-game-button')).hitTestable(),
        findsOneWidget,
      );
      expect(
        tester.getBottomRight(find.byKey(const Key('continue-game-button'))).dy,
        lessThanOrEqualTo(size.height),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('visual novel onboarding saves the family research desk', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MillenniumCapitalApp(
        campaignWorldPreparer: _skipCampaignWorldPreparation,
      ),
    );
    await tester.pumpAndSettle();

    await completeStoryOnboarding(tester);

    final companyHeader = tester.widget<Text>(
      find.byKey(const Key('company-header-title')),
    );
    expect(companyHeader.data, '별빛 투자');
    expect(companyHeader.maxLines, 1);
    expect(companyHeader.softWrap, isFalse);
    expect(find.text('가족 아파트 · 작은방'), findsOneWidget);
    expect(find.text('10,000원'), findsOneWidget);
    expect(find.byKey(const Key('apartment-place-bedroom')), findsOneWidget);
    expect(find.byKey(const Key('room-company-sign')), findsOneWidget);
    expect(find.byTooltip('1시간 보내기 · 게임 시간 60분 진행'), findsOneWidget);
  });

  testWidgets('father card reveals and repays the academy tuition debt', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const engine = GameEngine();
    final story = StoryState.newPlayer(
      playerName: '민준',
      introChoice: 'computer',
      startingTrait: StoryTrait.analysis,
      familyRule: FamilyRule.reportLosses,
    );
    var state = engine
        .createNewGame('별빛 투자', story: story)
        .copyWith(cash: academyTuitionDebtAmount + 10000);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationScreen(
          state: state,
          onRequestFamilyHelp: (helperId) async => state,
          onRepayAcademyTuitionDebt: () async {
            final result = engine.repayAcademyTuitionDebt(state);
            state = result.state;
            return result;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('academy-tuition-debt-card')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('assignment-card-father')));
    await tester.tap(find.byKey(const Key('assignment-card-father')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('academy-tuition-debt-card')), findsOneWidget);
    expect(find.textContaining('1,000,000'), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const Key('repay-academy-tuition-button')),
    );
    await tester.tap(find.byKey(const Key('repay-academy-tuition-button')));
    await tester.pumpAndSettle();

    expect(find.text('학원비 전액 상환 완료'), findsOneWidget);
    expect(state.story.academyTuitionDebt, 0);
    expect(state.cash, 10000);
    expect(state.brokerageCash, 10000);
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

    await tester.pumpWidget(
      const MillenniumCapitalApp(
        campaignWorldPreparer: _skipCampaignWorldPreparation,
      ),
    );
    await tester.pumpAndSettle();
    await continueFirstSave(tester);

    final companyHeader = tester.widget<Text>(
      find.byKey(const Key('company-header-title')),
    );
    expect(companyHeader.data, '이어하기 연구소');
    expect(find.textContaining('1월 8일 토'), findsWidgets);
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

    await tester.pumpWidget(
      const MillenniumCapitalApp(
        campaignWorldPreparer: _skipCampaignWorldPreparation,
      ),
    );
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
    expect(find.byKey(const Key('open-decisions-button')), findsOneWidget);
    expect(find.text('1월 1일 토 · 08:30'), findsOneWidget);
    expect(find.byKey(const Key('hub-claim-mission-reward')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('hub-mission-card')),
        matching: find.byType(LinearProgressIndicator),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('hub-mission-card')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('decision-inbox-screen')), findsNothing);
    expect(find.text('내 손으로 첫 돈 벌기'), findsOneWidget);
    expect(find.byKey(const Key('hub-claim-mission-reward')), findsNothing);
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

    await tester.pumpWidget(
      const MillenniumCapitalApp(
        campaignWorldPreparer: _skipCampaignWorldPreparation,
      ),
    );
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
    await waitForFinderToDisappear(tester, find.text('계산 중'));
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
              assetId: 'hanbit_telecom',
              symbol: '1001',
              name: '한빛통신',
              market: '미래시장',
              currency: 'KRW',
              units: 10,
              totalCost: 60000,
            ),
            PortfolioPosition(
              assetId: 'us-aapl',
              symbol: 'LGCY',
              name: '애플',
              market: '해외시장',
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

    expect(find.text('한빛통신'), findsOneWidget);
    final samsungDetails = tester.widget<Text>(
      find.textContaining('10주 · 평균 6,000원'),
    );
    expect(samsungDetails.data, contains('%'));
    final samsungTile = tester.widget<ListTile>(
      find.ancestor(of: find.text('한빛통신'), matching: find.byType(ListTile)),
    );
    final samsungValue = (samsungTile.trailing! as Text).data!;
    expect(samsungValue, endsWith('원'));
    expect(samsungValue, isNot('시세 없음'));
    expect(find.text('애플'), findsOneWidget);
    expect(find.text('환율 연결 대기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ledger retry coalesces same-frame taps into one market load', (
    tester,
  ) async {
    final state = const GameEngine()
        .createNewGame('원장 재시도 테스트')
        .copyWith(day: 4);
    final retryGate = Completer<FictionalMarketUniverse>();
    var loadCalls = 0;

    Future<FictionalMarketUniverse> loader({
      required String seed,
      required DateTime? throughDate,
      required bool forceRefresh,
    }) {
      loadCalls += 1;
      if (loadCalls == 1) {
        return Future<FictionalMarketUniverse>.error(
          StateError('initial ledger load failed'),
        );
      }
      return retryGate.future;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: PortfolioLedgerScreen(state: state, universeLoader: loader),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('retry-ledger-market-data'));
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.tap(retry);
    expect(loadCalls, 2);

    retryGate.complete(testMarketUniverse());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('retry-ledger-market-data')), findsNothing);
    expect(loadCalls, 2);
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
    expect(find.textContaining('시장 사건 2건'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'first market visit completes a temporary buy price-change sell tutorial',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const engine = GameEngine();
      final persistence = GamePersistence();
      final completionGate = Completer<void>();
      final story = StoryState.newPlayer(
        playerName: '민재',
        introChoice: 'stocks',
        startingTrait: StoryTrait.analysis,
        familyRule: FamilyRule.reportLosses,
      );
      var current = engine
          .createNewGame('별빛 투자', initialCash: 237000, story: story)
          .copyWith(day: 4, marketMinute: krxOpenMinute);
      final actualCashBefore = current.cash;
      final actualBrokerageBefore = current.brokerageCash;
      final actualPositionsBefore = current.positions.length;

      await tester.pumpWidget(
        MaterialApp(
          home: StockMarketScreen(
            state: current,
            universe: testMarketUniverse(tradingDate: current.currentDate),
            onCompleteTutorial: () async {
              current = engine.markMarketTutorialSeen(current);
              await persistence.save(current);
              await completionGate.future;
              return current;
            },
          ),
        ),
      );
      await waitForMarketHome(tester);
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const Key('market-tutorial-overlay')), findsOneWidget);
      expect(find.byKey(const Key('market-tutorial-teacher')), findsOneWidget);
      expect(
        find.byKey(const Key('market-tutorial-teacher-upper-body')),
        findsOneWidget,
      );
      final tutorialTeacherRect = tester.getRect(
        find.byKey(const Key('market-tutorial-teacher')),
      );
      expect(tutorialTeacherRect.width, 180);
      expect(tutorialTeacherRect.height, closeTo(255.6, 0.1));
      expect(tutorialTeacherRect.top, greaterThanOrEqualTo(0));
      expect(tutorialTeacherRect.bottom, lessThanOrEqualTo(800));
      expect(find.byKey(const Key('market-tutorial-next')), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('market-nav-account')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(find.byKey(const Key('market-home-section')), findsOneWidget);

      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('학원에서 배운 주문표를 이제 실제 화면에서 연습해 볼게요.'), findsOneWidget);
      await advanceTutorialPagesToTarget(
        tester,
        actionKey: const Key('market-tutorial-next'),
        targetKey: const Key('market-tutorial-target'),
      );
      expect(find.byKey(const Key('market-tutorial-next')), findsNothing);
      expect(find.byKey(const Key('market-tutorial-target')), findsOneWidget);

      await tester.tap(find.byKey(const Key('market-tutorial-target')));
      await tester.pump(const Duration(milliseconds: 750));
      expect(find.byKey(const Key('stock-row-1001')), findsOneWidget);
      await advanceTutorialPagesToTarget(
        tester,
        actionKey: const Key('market-tutorial-next'),
        targetKey: const Key('market-tutorial-target'),
      );
      expect(find.byKey(const Key('market-tutorial-target')), findsOneWidget);
      expect(find.text('먼저 한빛통신을 눌러 가격과 회사 내용을 함께 살펴볼게요.'), findsOneWidget);
      expect(
        find.byKey(const Key('market-tutorial-target')).hitTestable(),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('market-tutorial-target')));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('market-detail-tutorial-overlay')),
        findsOneWidget,
      );
      expect(find.text('1 / 3'), findsOneWidget);
      await advanceTutorialPagesToTarget(
        tester,
        actionKey: const Key('market-detail-tutorial-next'),
        targetKey: const Key('market-detail-tutorial-target'),
      );
      expect(
        find.byKey(const Key('market-detail-tutorial-target')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('market-detail-tutorial-target')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.byKey(const Key('market-detail-tutorial-next')),
        findsOneWidget,
      );

      await advanceTutorialPagesToTarget(
        tester,
        actionKey: const Key('market-detail-tutorial-next'),
        targetKey: const Key('market-detail-tutorial-target'),
      );
      expect(
        find.byKey(const Key('market-detail-tutorial-target')),
        findsOneWidget,
      );

      expect(find.textContaining('수량 막대 길이와 가격'), findsOneWidget);
      await tester.tap(find.byKey(const Key('market-detail-tutorial-target')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('매도호가를 누르면 그 가격이 매수 지정가에 들어가요.'), findsOneWidget);
      expect(find.byKey(const Key('order-book-ask-0')), findsOneWidget);
      final bestAskPrice = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('order-book-ask-0')),
              matching: find.byType(Text),
            ),
          )
          .map((widget) => widget.data)
          .whereType<String>()
          .firstWhere((value) => value.endsWith('원'));
      await advanceTutorialPagesToTarget(
        tester,
        actionKey: const Key('market-detail-tutorial-next'),
        targetKey: const Key('market-detail-tutorial-target'),
      );
      await tester.tap(find.byKey(const Key('market-detail-tutorial-target')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(
        find.byKey(const Key('market-order-tutorial-overlay')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('market-order-tutorial-done')),
        findsOneWidget,
      );
      expect(find.text('1 / 4'), findsOneWidget);

      await advanceTutorialPagesUntilDismissed(
        tester,
        actionKey: const Key('market-order-tutorial-done'),
        overlayKey: const Key('market-order-tutorial-overlay'),
      );
      expect(
        find.byKey(const Key('market-order-tutorial-overlay')),
        findsNothing,
      );
      expect(find.byKey(const Key('order-type-selector')), findsOneWidget);
      expect(
        tester
            .widget<SegmentedButton<TradeOrderType>>(
              find.byKey(const Key('order-type-selector')),
            )
            .selected,
        <TradeOrderType>{TradeOrderType.limit},
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('limit-price-value'))).data,
        bestAskPrice,
      );
      expect(find.textContaining('1,000,000원'), findsWidgets);
      expect(
        find.byKey(const Key('tutorial-buy-action-highlight')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(current.story.marketTutorialSeen, isFalse);

      await tester.ensureVisible(
        find.byKey(const Key('request-parent-order-approval')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('request-parent-order-approval')));
      await tester.pump();
      expect(find.byKey(const Key('order-result')), findsOneWidget);
      expect(find.textContaining('지정가 1주 전량 체결'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(current.cash, actualCashBefore);
      expect(current.brokerageCash, actualBrokerageBefore);
      expect(current.positions.length, actualPositionsBefore);

      await tester.ensureVisible(
        find.byKey(const Key('request-parent-order-approval')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('request-parent-order-approval')));
      await tester.pump();
      expect(find.byKey(const Key('tutorial-price-change')), findsOneWidget);
      expect(find.text('매수 뒤 가격이 움직였어요'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('tutorial-live-account-state')),
        findsOneWidget,
      );
      final firstLivePrice = tester
          .widget<Text>(find.byKey(const Key('tutorial-live-current-price')))
          .data;
      await tester.pump(const Duration(milliseconds: 850));
      final secondLivePrice = tester
          .widget<Text>(find.byKey(const Key('tutorial-live-current-price')))
          .data;
      expect(secondLivePrice, isNot(firstLivePrice));
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('tutorial-price-change-continue')),
            )
            .onPressed,
        isNull,
      );
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('어맛, 많이 올랐네요! 이제 한 번 팔아 볼까요?'), findsOneWidget);
      expect(find.text('선생님 말대로 한 주 팔러 가기'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('tutorial-price-change-continue')),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('tutorial-price-change-continue')));
      await tester.pump();
      expect(find.byKey(const Key('tutorial-sell-order')), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('tutorial-sell-action-highlight')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const Key('request-parent-order-approval')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('request-parent-order-approval')));
      await tester.pump();
      expect(find.byKey(const Key('order-result')), findsOneWidget);
      expect(find.textContaining('매도 완료'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(
        find.byKey(const Key('request-parent-order-approval')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('request-parent-order-approval')));
      await tester.pump();
      expect(find.byKey(const Key('tutorial-trade-summary')), findsOneWidget);
      expect(find.text('매수부터 매도까지 완료!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(current.cash, actualCashBefore);
      expect(current.brokerageCash, actualBrokerageBefore);
      expect(current.positions.length, actualPositionsBefore);
      expect(current.story.marketTutorialSeen, isFalse);

      await tester.tap(find.byKey(const Key('tutorial-summary-continue')));
      await tester.pump();
      expect(
        find.byKey(const Key('tutorial-post-trade-review')),
        findsOneWidget,
      );
      expect(find.textContaining('첫 거래, 같이 돌아볼까요'), findsOneWidget);
      expect(
        find.byKey(const Key('tutorial-review-teacher-character')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      final reviewStageRect = tester.getRect(
        find.byKey(const Key('tutorial-post-trade-review')),
      );
      final reviewTeacherRect = tester.getRect(
        find.byKey(const Key('tutorial-review-teacher-character')),
      );
      expect(
        reviewTeacherRect.height,
        closeTo((reviewStageRect.height - 122) * 0.78, 0.01),
      );
      expect(
        reviewTeacherRect.bottom,
        closeTo(reviewStageRect.bottom - 122, 0.01),
      );
      expect(
        reviewTeacherRect.center.dx,
        closeTo(reviewStageRect.center.dx, 0.01),
      );
      expect(
        find.byKey(const Key('tutorial-review-protagonist-character')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('tutorial-review-continue')));
      await tester.pump();
      expect(find.textContaining('언제 팔지 정하는 게 더 어려웠어요'), findsOneWidget);
      expect(
        find.byKey(const Key('tutorial-review-protagonist-character')),
        findsOneWidget,
      );
      expect(
        tester.getRect(
          find.byKey(const Key('tutorial-review-protagonist-character')),
        ),
        reviewTeacherRect,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/character_hero_thoughtful_v1.png',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('아빠'), findsNothing);
      expect(find.textContaining('외할아버지'), findsNothing);
      for (var reviewBeat = 1; reviewBeat < 4; reviewBeat += 1) {
        await tester.tap(find.byKey(const Key('tutorial-review-continue')));
        await tester.pump();
      }
      expect(
        find.byKey(const Key('tutorial-school-dismissal')),
        findsOneWidget,
      );
      expect(find.textContaining('교문을 나섰다'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('market-practical-tutorial-complete')),
      );
      await tester.pump();
      expect(current.story.marketTutorialSeen, isTrue);
      completionGate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('market-practical-tutorial')), findsNothing);
      final restored = await persistence.load();
      expect(restored!.cash, actualCashBefore);
      expect(restored.brokerageCash, actualBrokerageBefore);
      expect(restored.positions.length, actualPositionsBefore);
      expect(restored.story.marketTutorialSeen, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('market preparation shows stage and percent before home', (
    tester,
  ) async {
    final state = const GameEngine()
        .createNewGame('별빛 투자', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: krxOpenMinute);

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(state: state, universe: testMarketUniverse()),
      ),
    );

    expect(find.byKey(const Key('market-preparing-screen')), findsOneWidget);
    expect(find.byKey(const Key('market-loading-stage')), findsOneWidget);
    expect(find.byKey(const Key('market-loading-progress')), findsOneWidget);
    expect(find.byKey(const Key('market-loading-percent')), findsOneWidget);
    await tester.pump();
    await waitForMarketHome(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('market retry coalesces same-frame taps into one world rebuild', (
    tester,
  ) async {
    final state = const GameEngine()
        .createNewGame('시장 재시도 테스트')
        .copyWith(day: 4, marketMinute: krxOpenMinute);
    final retryGate = Completer<FictionalMarketUniverse>();
    var loadCalls = 0;

    Future<FictionalMarketUniverse> loader({
      required String seed,
      required DateTime? throughDate,
      required bool forceRefresh,
    }) {
      loadCalls += 1;
      if (loadCalls == 1) {
        return Future<FictionalMarketUniverse>.error(
          StateError('initial market load failed'),
        );
      }
      return retryGate.future;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(state: state, universeLoader: loader),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('market-load-retry'));
    expect(retry, findsOneWidget);
    final retryButton = tester.widget<FilledButton>(retry);
    retryButton.onPressed!();
    retryButton.onPressed!();
    for (var attempt = 0; attempt < 3 && loadCalls < 2; attempt++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    expect(loadCalls, 2);

    retryGate.complete(testMarketUniverse());
    await tester.pump();
    await waitForMarketHome(tester);

    expect(find.byKey(const Key('market-load-retry')), findsNothing);
    expect(loadCalls, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
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
    expect(find.byKey(const Key('market-index-board')), findsOneWidget);
    expect(find.byKey(const Key('market-main-index')), findsOneWidget);
    expect(find.byKey(const Key('market-growth-index')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('market-sector-index-반도체')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('market-investment-overview')), findsNothing);
    expect(find.byKey(const Key('market-account-summary')), findsNothing);
    expect(find.byKey(const Key('market-mission-card')), findsNothing);
    expect(find.byKey(const Key('market-nav-home')), findsOneWidget);
    expect(find.byKey(const Key('market-nav-account')), findsOneWidget);
    await openMarketExplore(tester);

    expect(find.text('가상시장 종목'), findsOneWidget);
    expect(find.byKey(const Key('market-phone-status-bar')), findsOneWidget);
    expect(find.byKey(const Key('market-home-app-bar')), findsOneWidget);
    expect(find.byKey(const Key('market-phone-status-time')), findsOneWidget);
    expect(find.text('내 방 · CRT 투자 단말'), findsNothing);
    expect(find.text('모뎀 소리와 함께 2000년 시장 화면이 켜졌다.'), findsNothing);
    expect(find.byKey(const Key('market-mission-card')), findsNothing);
    await tester.tap(find.byKey(const Key('market-sort-name')));
    await tester.pump();
    if (find.byKey(const Key('stock-row-1001')).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.byKey(const Key('stock-row-1001')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
    }
    expect(find.byKey(const Key('stock-row-1001')), findsOneWidget);
    final clock = find.byKey(const Key('market-phone-status-time'));
    final before = tester.widget<Text>(clock.first).data;
    await tester.pump(marketRealtimeTickDuration);
    if (find.byKey(const Key('stock-rate-1001')).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.byKey(const Key('stock-row-1001')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
    }
    final after = tester.widget<Text>(clock.first).data;
    expect(after, isNot(before));
    expect(after, contains('09:01'));

    await tester.ensureVisible(find.byKey(const Key('stock-row-1001')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('한빛통신'), findsWidgets);
    expect(find.byKey(const Key('market-phone-status-bar')), findsWidgets);
    expect(find.byKey(const Key('stock-detail-price')), findsOneWidget);
    expect(find.textContaining('현실 1초마다 게임 1분 진행'), findsNothing);
    expect(find.byKey(const Key('stock-order-book')), findsOneWidget);
    expect(find.byKey(const Key('minute-interval-selector')), findsNothing);
    expect(find.byKey(const Key('company-overview-card')), findsNothing);
    await tester.tap(find.byKey(const Key('stock-detail-tab-chart')));
    await tester.pump();
    expect(find.byKey(const Key('minute-interval-selector')), findsOneWidget);
    expect(find.byKey(const Key('minute-candle-chart')), findsOneWidget);
    expect(find.byKey(const Key('chart-time-axis')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('chart-window-label'))).data,
      contains('최대 최근 90분'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('chart-window-label'))).data,
      allOf(contains('90개 캔들'), contains('전 거래일 포함')),
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
    expect(find.byKey(const Key('daily-candle-chart')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('chart-window-label'))).data,
      allOf(contains('일봉'), contains('5·20·60·120일 이동평균')),
    );
    await tester.tap(find.byKey(const Key('chart-range-week')));
    await tester.pump();
    expect(find.byKey(const Key('weekly-candle-chart')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('chart-window-label'))).data,
      contains('주봉'),
    );
    await tester.tap(find.byKey(const Key('chart-range-month')));
    await tester.pump();
    expect(find.byKey(const Key('monthly-candle-chart')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('chart-window-label'))).data,
      contains('월봉'),
    );
    await tester.tap(find.byKey(const Key('chart-range-year')));
    await tester.pump();
    expect(find.byKey(const Key('yearly-candle-chart')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('chart-window-label'))).data,
      contains('년봉'),
    );

    await tester.tap(find.byKey(const Key('toggle-market-favorite')));
    await tester.pumpAndSettle();
    final favoriteIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('toggle-market-favorite')),
        matching: find.byType(Icon),
      ),
    );
    expect(favoriteIcon.icon, Icons.star_rounded);

    await tester.tap(find.byKey(const Key('stock-detail-tab-info')));
    await tester.pump();
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
      contains('hanbit_telecom'),
    );
    expect(
      (current.story.storyFlags['marketResearchNotes']
          as Map<dynamic, dynamic>)['hanbit_telecom'],
      '제품 경쟁력과 다음 실적을 확인한다.',
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    await tester.tap(find.byKey(const Key('stock-detail-tab-order')));
    await tester.pump();
    expect(find.byKey(const Key('buy-stock-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('buy-stock-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-ticket')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-book')), findsOneWidget);
    expectSymmetricInlineOrderBook(tester);
    expect(find.byKey(const Key('detailed-order-screen')), findsNothing);
    expect(find.text('현금'), findsNothing);
    expect(find.text('신용'), findsNothing);
    expect(find.text('주문 금액'), findsOneWidget);
    expect(find.byKey(const Key('order-quantity-value')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('시장가'));
    await tester.pump();
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
    await tester.tap(find.byKey(const Key('stock-detail-tab-info')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('오늘의 조사 질문'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('오늘의 조사 질문'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stock detail carries central price depth across a live tick', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const engine = GameEngine();
    final universe = testMarketUniverse();
    final baseState = engine
        .createNewGame(
          '호가 캐시 통합 테스트',
          initialCash: 1000000,
          // Structural breakouts intentionally thin the book by more than the
          // ordinary carry cap. Keep this regression on a stable, calm path;
          // breakout depletion has dedicated order-book tests.
          worldSeed: 'central-depth-carry-normal-world',
        )
        .copyWith(day: 4);
    final asset = universe.assets.singleWhere(
      (asset) => asset.id == 'hanbit_telecom',
    );
    final quote = asset.quoteAtOrBefore(baseState.currentDate)!;
    final path = generatedMarketDayPathForAsset(
      asset: asset,
      simulationSeed: baseState.simulationSeed,
      date: baseState.currentDate,
      previousClose: asset.unadjustedReferenceCloseFor(quote.date),
      officialClose: quote.close,
    );
    final continuousStart = generatedPreOpenTicks + 1;
    final continuousEnd =
        generatedPreOpenTicks + generatedContinuousTradingTicks - 1;
    final transitionTicks = <int>[
      for (
        var tick = continuousStart;
        tick < continuousEnd && tick + 1 < path.length;
        tick += 1
      )
        if (path[tick] > path[tick - 1] &&
            (path[tick + 1] -
                        path[tick] -
                        marketTickSize(path[tick], market: asset.market))
                    .abs() <
                0.000001)
          tick,
    ];
    expect(
      transitionTicks,
      isNotEmpty,
      reason: 'fixture에 중앙 ask→bid 이동을 검증할 연속 상승 1틱 구간이 필요합니다.',
    );
    final transitionTick = transitionTicks.first;
    final transitionMinute = marketMinuteForTick(transitionTick);
    final targetPrice = path[transitionTick].round();
    final state = baseState.copyWith(marketMinute: transitionMinute);

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(state: state, universe: universe),
      ),
    );
    await waitForMarketHome(tester);
    await tester.tap(find.byKey(const Key('market-speed-pause')));
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.byKey(const Key('market-phone-status-time')).first)
          .data,
      contains(marketTimeLabel(transitionMinute)),
    );

    await openMarketExplore(tester);
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('stock-order-book')), findsOneWidget);

    int displayedNumber(Finder finder) {
      final label = tester.widget<Text>(finder).data!;
      return int.parse(label.replaceAll(RegExp(r'[^0-9]'), ''));
    }

    int rowPrice(Key rowKey) => displayedNumber(
      find
          .descendant(
            of: find.byKey(rowKey),
            matching: find.byKey(const ValueKey('order-book-price-label')),
          )
          .first,
    );

    int rowQuantity(Key rowKey, Key quantityCellKey) => displayedNumber(
      find
          .descendant(
            of: find.descendant(
              of: find.byKey(rowKey),
              matching: find.byKey(quantityCellKey),
            ),
            matching: find.byType(Text),
          )
          .first,
    );

    double rowDepth(Key rowKey, Key depthBarKey) => tester
        .widget<FractionallySizedBox>(
          find
              .descendant(
                of: find.byKey(rowKey),
                matching: find.byKey(depthBarKey),
              )
              .first,
        )
        .widthFactor!;

    const bestAskKey = Key('order-book-ask-0');
    const bestBidKey = Key('order-book-bid-0');
    final beforeQuantity = rowQuantity(
      bestAskKey,
      const Key('order-book-sell-quantity-cell'),
    );
    final beforeDepth = rowDepth(
      bestAskKey,
      const Key('order-book-sell-depth-bar'),
    );
    expect(rowPrice(bestAskKey), targetPrice);

    await tester.tap(find.byKey(const Key('market-speed-1x')).last);
    await tester.pump();
    await tester.pump(marketRealtimeTickDuration);
    await tester.pump();
    await tester.tap(find.byKey(const Key('market-speed-pause')).last);
    await tester.pump();

    expect(
      tester
          .widget<Text>(find.byKey(const Key('market-phone-status-time')).first)
          .data,
      contains(marketTimeLabel(transitionMinute + 1)),
    );
    expect(
      rowPrice(bestBidKey),
      targetPrice,
      reason: '직전 중앙 매도호가는 다음 1틱 상승 뒤 중앙 매수호가로 이동해야 합니다.',
    );
    final afterQuantity = rowQuantity(
      bestBidKey,
      const Key('order-book-buy-quantity-cell'),
    );
    final transitionStartDepth = rowDepth(
      bestBidKey,
      const Key('order-book-buy-depth-bar'),
    );
    expect(
      transitionStartDepth,
      closeTo(beforeDepth, 0.0001),
      reason: 'ask→bid로 자리가 바뀌어도 막대 애니메이션은 같은 절대가격의 직전 길이에서 시작해야 합니다.',
    );
    final changeRate = (afterQuantity - beforeQuantity).abs() / beforeQuantity;
    expect(
      changeRate,
      lessThanOrEqualTo(0.10),
      reason: '화면 캐시가 동일 절대가격 잔량을 이어받아 분당 10% 넘는 재추첨 점프를 막아야 합니다.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('market cap updates once per game day and stays fixed intraday', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const engine = GameEngine();
    final universe = testMarketUniverse(includeKnownPartner: true);
    final asset = universe.assets.singleWhere(
      (asset) => asset.id == 'hanbit_telecom',
    );

    Future<void> verifyDay({
      required int day,
      required String expectedMarketCap,
    }) async {
      final baseState = engine
          .createNewGame('일일 시가총액 회귀 테스트', initialCash: 1000000)
          .copyWith(day: day);
      final quote = asset.quoteAtOrBefore(baseState.currentDate)!;
      final path = generatedMarketDayPathForAsset(
        asset: asset,
        simulationSeed: baseState.simulationSeed,
        date: baseState.currentDate,
        previousClose: asset.unadjustedReferenceCloseFor(quote.date),
        officialClose: quote.close,
      );
      final firstContinuousTick = generatedPreOpenTicks + 1;
      final lastContinuousTick =
          generatedPreOpenTicks + generatedContinuousTradingTicks - 1;
      final transitionTick = [
        for (
          var tick = firstContinuousTick;
          tick < lastContinuousTick && tick + 1 < path.length;
          tick += 1
        )
          if ((path[tick + 1] - path[tick]).abs() > 0.000001) tick,
      ].first;
      final transitionMinute = marketMinuteForTick(transitionTick);
      final state = baseState.copyWith(marketMinute: transitionMinute);

      await tester.pumpWidget(
        MaterialApp(
          home: StockMarketScreen(
            key: ValueKey<String>('daily-market-cap-$day'),
            state: state,
            universe: universe,
          ),
        ),
      );
      await waitForMarketHome(tester);
      await tester.tap(find.byKey(const Key('market-speed-pause')));
      await tester.pump();
      await openMarketExplore(tester);
      await tester.tap(find.byKey(const Key('stock-row-1001')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stock-detail-tab-info')));
      await tester.pump();

      final overviewMarketCap = find.byKey(
        const Key('company-market-cap-value'),
      );
      final fundamentalsMarketCap = find.byKey(
        const Key('company-fundamentals-market-cap-value'),
      );
      final ranking = find.byKey(const Key('company-market-cap-rank-value'));
      expect(tester.widget<Text>(overviewMarketCap).data, expectedMarketCap);
      final rankingBeforeTick = tester.widget<Text>(ranking).data;
      await tester.scrollUntilVisible(
        fundamentalsMarketCap,
        320,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        tester.widget<Text>(fundamentalsMarketCap).data,
        expectedMarketCap,
      );
      final priceBeforeTick = tester
          .widget<Text>(find.byKey(const Key('stock-detail-price')))
          .data;

      await tester.tap(find.byKey(const Key('market-speed-1x')).last);
      await tester.pump();
      await tester.pump(marketRealtimeTickDuration);
      await tester.pump();
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();

      expect(
        tester.widget<Text>(find.byKey(const Key('stock-detail-price'))).data,
        isNot(priceBeforeTick),
        reason: '장중 현재가는 움직여야 일일 시가총액 고정 검증이 유효합니다.',
      );
      expect(
        tester.widget<Text>(fundamentalsMarketCap).data,
        expectedMarketCap,
      );
      await tester.scrollUntilVisible(
        overviewMarketCap,
        -320,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.widget<Text>(overviewMarketCap).data, expectedMarketCap);
      expect(tester.widget<Text>(ranking).data, rankingBeforeTick);
      expect(tester.takeException(), isNull);
    }

    await verifyDay(day: 3, expectedMarketCap: '59.2억원');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await verifyDay(day: 4, expectedMarketCap: '60.4억원');
  });

  testWidgets(
    'stock market route re-entry restores the same 6+6 order-book session',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const GameEngine()
          .createNewGame('호가 재진입 회귀 테스트', initialCash: 1000000)
          .copyWith(day: 4, marketMinute: 9 * 60);
      final orderBookSessionCache = StockOrderBookSessionCache();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('open-market-with-order-book-session'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => StockMarketScreen(
                      state: state,
                      universe: testMarketUniverse(),
                      orderBookSessionCache: orderBookSessionCache,
                    ),
                  ),
                ),
                child: const Text('Open market'),
              ),
            ),
          ),
        ),
      );

      Future<void> openMarketRoute() async {
        await tester.tap(
          find.byKey(const Key('open-market-with-order-book-session')),
        );
        await tester.pump();
        await waitForMarketHome(tester);
        await tester.tap(find.byKey(const Key('market-speed-pause')));
        await tester.pump();
        await openMarketExplore(tester);
      }

      Future<void> openTargetStock() async {
        await tester.ensureVisible(find.byKey(const Key('stock-row-1001')));
        await tester.tap(find.byKey(const Key('stock-row-1001')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('stock-order-book')), findsOneWidget);
      }

      ValueNotifier<int> orderBookPulseNotifier() {
        final notifiers = <ValueNotifier<int>>[];
        tester
            .element(find.byKey(const Key('stock-order-book')))
            .visitAncestorElements((element) {
              final widget = element.widget;
              if (widget is ValueListenableBuilder<int> &&
                  widget.valueListenable is ValueNotifier<int>) {
                notifiers.add(widget.valueListenable as ValueNotifier<int>);
              }
              return true;
            });
        expect(notifiers, isNotEmpty);
        return notifiers.first;
      }

      String displayedLevelSignature(
        String side,
        int index,
        Key quantityCellKey,
      ) {
        final row = find.byKey(Key('order-book-$side-$index'));
        final price = tester
            .widget<Text>(
              find
                  .descendant(
                    of: row,
                    matching: find.byKey(
                      const ValueKey('order-book-price-label'),
                    ),
                  )
                  .first,
            )
            .data;
        final quantity = tester
            .widget<Text>(
              find
                  .descendant(
                    of: find.descendant(
                      of: row,
                      matching: find.byKey(quantityCellKey),
                    ),
                    matching: find.byType(Text),
                  )
                  .first,
            )
            .data;
        return '$side:$index:$price:$quantity';
      }

      List<String> displayedBookSignature() => <String>[
        for (var index = 0; index < 6; index++)
          displayedLevelSignature(
            'ask',
            index,
            const Key('order-book-sell-quantity-cell'),
          ),
        for (var index = 0; index < 6; index++)
          displayedLevelSignature(
            'bid',
            index,
            const Key('order-book-buy-quantity-cell'),
          ),
      ];

      await openMarketRoute();
      await openTargetStock();
      final firstPulse = orderBookPulseNotifier();
      firstPulse.value = 7;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final beforeLeaving = displayedBookSignature();
      expect(firstPulse.value, 7);
      expect(find.byKey(const Key('order-book-ask-0')), findsOneWidget);
      expect(find.byKey(const Key('order-book-ask-5')), findsOneWidget);
      expect(find.byKey(const Key('order-book-bid-0')), findsOneWidget);
      expect(find.byKey(const Key('order-book-bid-5')), findsOneWidget);

      Navigator.of(
        tester.element(find.byKey(const Key('stock-order-book'))),
      ).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('stock-order-book')), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(StockMarketScreen), findsNothing);
      expect(
        find.byKey(const Key('open-market-with-order-book-session')),
        findsOneWidget,
      );

      await openMarketRoute();
      await openTargetStock();
      final restoredPulse = orderBookPulseNotifier();
      expect(
        restoredPulse.value,
        7,
        reason: '시장 화면 전체를 닫아도 같은 게임 세션의 미시구조 프레임을 이어야 합니다.',
      );
      expect(
        displayedBookSignature(),
        beforeLeaving,
        reason: '시장 화면 전체 재진입 때 6+6 가격별 수량을 새로 추첨하면 안 됩니다.',
      );
      expect(tester.takeException(), isNull);
    },
  );

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
              assetId: 'hanbit_telecom',
              symbol: '1001',
              name: '한빛통신',
              market: '미래시장',
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
              description: '한빛통신 매수 · 증권 수수료 50원',
              sourceId: 'test-buy',
              notional: 20000,
              tradingFee: 50,
              assetId: 'hanbit_telecom',
              tradeSide: 'buy',
              tradeQuantity: 2,
              tradeUnitPrice: 10000,
              marketMinute: krxOpenMinute,
              orderType: 'market',
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
          onSetRightsIssuePreference: (subscribe) async {
            current = current.copyWith(
              story: current.story.copyWith(
                storyFlags: {
                  ...current.story.storyFlags,
                  marketRightsIssuePreferenceFlag: subscribe
                      ? marketRightsIssueSubscribePreference
                      : marketRightsIssueAutoSellPreference,
                },
              ),
            );
            return current;
          },
        ),
      ),
    );
    await waitForMarketHome(tester);

    expect(find.byKey(const Key('market-account-summary')), findsNothing);
    expect(
      find.byKey(const Key('market-account-position-hanbit_telecom')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('market-nav-account')));
    await tester.pump();
    expect(find.byKey(const Key('market-account-summary')), findsOneWidget);
    expect(find.byKey(const Key('market-mission-card')), findsNothing);
    expect(
      find.byKey(const Key('market-corporate-action-schedule')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const Key('market-rights-subscribe')),
    );
    await tester.tap(find.byKey(const Key('market-rights-subscribe')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      current.story.storyFlags[marketRightsIssuePreferenceFlag],
      marketRightsIssueSubscribePreference,
    );
    final subscribeChip = tester.widget<ChoiceChip>(
      find.byKey(const Key('market-rights-subscribe')),
    );
    expect(subscribeChip.selected, isTrue);
    ScaffoldMessenger.of(
      tester.element(find.byKey(const Key('market-account-section'))),
    ).hideCurrentSnackBar();
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('market-account-deposit')),
      -220,
      scrollable: find.descendant(
        of: find.byKey(const Key('market-account-section')),
        matching: find.byType(Scrollable),
      ),
    );
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
    expect(find.textContaining('누적 거래비용 50원'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('open-trade-journal')),
      220,
      scrollable: find.descendant(
        of: find.byKey(const Key('market-account-section')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('open-trade-journal')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trade-journal-sheet')), findsOneWidget);
    expect(find.text('매매일지 · 거래내역'), findsOneWidget);
    expect(find.textContaining('시장가 · 2주 · 평균 10,000원'), findsWidgets);
    Navigator.of(
      tester.element(find.byKey(const Key('trade-journal-sheet'))),
    ).pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('market-account-position-hanbit_telecom')),
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('market-account-section')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('market-account-position-hanbit_telecom')),
      findsOneWidget,
    );

    final value = find.byKey(const Key('position-value-hanbit_telecom'));
    final before = tester.widget<Text>(value).data;
    var after = before;
    for (var attempt = 0; attempt < 10 && after == before; attempt++) {
      await tester.pump(marketRealtimeTickDuration);
      after = tester.widget<Text>(value).data;
    }
    expect(after, isNot(before));

    await tester.tap(find.byKey(const Key('market-nav-explore')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('stock-row-1001')));
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stock-detail-tab-info')));
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.byKey(const Key('company-owned-shares-value')))
          .data,
      '2주',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('company-ownership-percent-value')),
          )
          .data,
      isNot('0%'),
    );
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
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pumpAndSettle();
    expect(find.textContaining('현실 1초마다 게임 1분 진행'), findsNothing);
    final detailPrice = find.byKey(const Key('stock-detail-price'));
    expect(detailPrice, findsOneWidget);
    final clockBeforeTick = tester
        .widget<Text>(find.byKey(const Key('market-phone-status-time')))
        .data;
    await tester.tap(find.byKey(const Key('stock-detail-tab-chart')));
    await tester.pump();
    expect(find.textContaining('1분봉'), findsWidgets);
    await tester.pump(const Duration(seconds: 1));
    final clockAfterTick = tester
        .widget<Text>(find.byKey(const Key('market-phone-status-time')))
        .data;
    expect(clockAfterTick, isNot(clockBeforeTick));
    expect(clockAfterTick, contains('09:'));
    expect(find.byKey(const Key('chart-time-axis')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('market speed controls pause and advance 3x and 10x', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = const GameEngine()
        .createNewGame('Market Speed Test', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: krxOpenMinute);
    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(state: state, universe: testMarketUniverse()),
      ),
    );
    await waitForMarketHome(tester);

    final clock = find.byKey(const Key('market-phone-status-time'));
    int displayedMinute() {
      final label = tester.widget<Text>(clock.first).data!;
      final parts = label.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    await tester.tap(find.byKey(const Key('market-speed-pause')));
    await tester.pump();
    final pausedAt = displayedMinute();
    await tester.pump(const Duration(seconds: 2));
    expect(displayedMinute(), pausedAt);

    await tester.tap(find.byKey(const Key('market-speed-3x')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(displayedMinute(), pausedAt + 3);

    await tester.tap(find.byKey(const Key('market-speed-pause')));
    await tester.pump();
    final pausedAgainAt = displayedMinute();
    await tester.pump(const Duration(seconds: 1));
    expect(displayedMinute(), pausedAgainAt);

    await tester.tap(find.byKey(const Key('market-speed-10x')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(displayedMinute(), pausedAgainAt + 10);

    await openMarketExplore(tester);
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('market-speed-controls')), findsWidgets);
    await tester.tap(find.byKey(const Key('market-speed-pause')).last);
    await tester.pump();
    final detailPausedAt = displayedMinute();
    await tester.pump(const Duration(seconds: 2));
    expect(displayedMinute(), detailPausedAt);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unwatched company news uses a ticker without pausing play', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const seed = 'background-news-widget-seed';
    DateTime? eventDate;
    FictionalMarketEvent? backgroundEvent;
    for (
      var date = DateTime(2000, 1, 1);
      date.isBefore(DateTime(2002, 1, 1));
      date = date.add(const Duration(days: 1))
    ) {
      if (!isMarketTradingDay(date)) continue;
      for (final event in fictionalMarketEventsForDate(seed, date)) {
        if (event.companyId != fictionalWholeMarketCompanyId &&
            event.companyId != 'hanbit_telecom' &&
            event.revealMinute > marketDayStartMinute) {
          eventDate = date;
          backgroundEvent = event;
          break;
        }
      }
      if (backgroundEvent != null) break;
    }
    expect(backgroundEvent, isNotNull);
    final event = backgroundEvent!;
    final day = eventDate!.difference(DateTime(2000, 1, 1)).inDays + 1;
    final state = const GameEngine()
        .createNewGame('Background News Test', initialCash: 1000000)
        .copyWith(
          day: day,
          marketMinute: event.revealMinute - 1,
          simulationSeed: seed,
        );
    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(
          state: state,
          universe: testMarketUniverse(tradingDate: eventDate),
        ),
      ),
    );
    await waitForMarketHome(tester);

    await tester.pump(marketRealtimeTickDuration);

    expect(find.byKey(const Key('background-news-ticker')), findsOneWidget);
    expect(find.textContaining(event.companyName), findsOneWidget);
    expect(find.byKey(const Key('market-breaking-news-confirm')), findsNothing);
    final clock = find.byKey(const Key('market-phone-status-time'));
    final afterNews = tester.widget<Text>(clock.first).data;
    await tester.pump(marketRealtimeTickDuration);
    expect(tester.widget<Text>(clock.first).data, isNot(afterNews));
  });

  testWidgets('watched breaking news restores the previous playback speed', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const seed = 'watched-news-widget-seed';
    DateTime? eventDate;
    FictionalMarketEvent? watchedEvent;
    for (
      var date = DateTime(2000, 1, 1);
      date.isBefore(DateTime(2008, 1, 1));
      date = date.add(const Duration(days: 1))
    ) {
      if (!isMarketTradingDay(date)) continue;
      for (final event in fictionalMarketEventsForDate(seed, date)) {
        if (event.companyId == fictionalWholeMarketCompanyId &&
            event.revealMinute > marketDayStartMinute) {
          eventDate = date;
          watchedEvent = event;
          break;
        }
      }
      if (watchedEvent != null) break;
    }
    expect(watchedEvent, isNotNull);
    final event = watchedEvent!;
    final day = eventDate!.difference(DateTime(2000, 1, 1)).inDays + 1;
    final state = const GameEngine()
        .createNewGame('Watched News Test', initialCash: 1000000)
        .copyWith(
          day: day,
          marketMinute: event.revealMinute - 1,
          simulationSeed: seed,
        );
    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(
          state: state,
          universe: testMarketUniverse(tradingDate: eventDate),
        ),
      ),
    );
    await waitForMarketHome(tester);

    await tester.pump(marketRealtimeTickDuration);
    expect(
      find.byKey(const Key('market-breaking-news-confirm')),
      findsOneWidget,
    );
    final confirm = find.byKey(const Key('market-breaking-news-confirm'));
    tester.widget<ElevatedButton>(confirm).onPressed!();
    await tester.pumpAndSettle();
    final clock = find.byKey(const Key('market-phone-status-time'));
    final afterDismiss = tester.widget<Text>(clock.first).data;

    await tester.pump(marketRealtimeTickDuration);

    expect(tester.widget<Text>(clock.first).data, isNot(afterDismiss));
  });

  testWidgets('accelerated market keeps running after a pending order fill', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final base = const GameEngine()
        .createNewGame('Pending Fill Pause Test', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: krxOpenMinute);
    var current = base.copyWith(
      pendingOrders: [
        PendingTradeOrder(
          id: 'pending-speed-test',
          side: PendingOrderSide.buy,
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: '미래시장',
          currency: 'KRW',
          limitPrice: 6000,
          originalQuantity: 1,
          remainingQuantity: 1,
          placedDate: marketDateKey(base.currentDate),
          placedMinute: krxOpenMinute,
          placedSequence: 0,
        ),
      ],
    );
    final synchronizedMinutes = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(
          state: current,
          universe: testMarketUniverse(),
          onSetMarketMinute: (minute) async {
            synchronizedMinutes.add(minute);
            current = current.copyWith(
              marketMinute: minute,
              pendingOrders: const <PendingTradeOrder>[],
              ledger: [
                ...current.ledger,
                LedgerEntry(
                  id: 'trade-buy-4-$minute-hanbit_telecom-widget',
                  day: current.day,
                  amount: -6015,
                  account: 'brokerage_cash',
                  counterAccount: 'market_security',
                  description: '한빛통신 1주 지정가 체결',
                  sourceId: 'trade-buy-4-$minute-hanbit_telecom-widget',
                  notional: 6000,
                  tradingFee: 15,
                  assetId: 'hanbit_telecom',
                  tradeSide: TradeSide.buy.name,
                  tradeQuantity: 1,
                  tradeUnitPrice: 6000,
                  marketMinute: minute,
                  orderType: TradeOrderType.limit.name,
                ),
              ],
            );
            return current;
          },
        ),
      ),
    );
    await waitForMarketHome(tester);
    await tester.tap(find.byKey(const Key('market-speed-pause')));
    await tester.pump();
    await openMarketExplore(tester);
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-book-pending-count')), findsNothing);

    final clock = find.byKey(const Key('market-phone-status-time'));
    final before = tester.widget<Text>(clock.first).data;
    await tester.tap(find.byKey(const Key('market-speed-10x')).last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(synchronizedMinutes, [krxOpenMinute + 1]);
    expect(tester.widget<Text>(clock.first).data, contains('09:10'));
    expect(tester.widget<Text>(clock.first).data, isNot(before));
    expect(find.text('내 지정가 주문이 체결되어 시장 시간을 일시정지했어요.'), findsNothing);
    expect(find.byKey(const Key('order-book-pending-count')), findsNothing);
    expect(
      find.byKey(const Key('order-book-active-trade')),
      findsNothing,
      reason: '10배속으로 다음 분까지 진행된 뒤에는 과거 분 체결행을 남기면 안 됩니다.',
    );

    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<Text>(clock.first).data, contains('09:20'));
    expect(synchronizedMinutes, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an expiring order is never reported as a fill', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final base = const GameEngine()
        .createNewGame('Expiry Notice Test', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: krxCloseMinute - 1);
    final pending = PendingTradeOrder(
      id: 'pending-expiry-test',
      side: PendingOrderSide.buy,
      assetId: 'hanbit_telecom',
      symbol: '1001',
      name: '한빛통신',
      market: '미래시장',
      currency: 'KRW',
      limitPrice: 1000,
      originalQuantity: 1,
      remainingQuantity: 1,
      placedDate: marketDateKey(base.currentDate),
      placedMinute: krxCloseMinute - 1,
      placedSequence: 0,
    );
    var current = base.copyWith(pendingOrders: [pending]);

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(
          state: current,
          universe: testMarketUniverse(),
          onSetMarketMinute: (minute) async {
            current = current.copyWith(
              marketMinute: minute,
              pendingOrders: const <PendingTradeOrder>[],
              ledger: [
                ...current.ledger,
                LedgerEntry(
                  id: 'expire-${pending.id}',
                  day: current.day,
                  amount: 0,
                  account: 'brokerage_order',
                  counterAccount: 'day_order_expiry',
                  description: '장 마감 미체결 자동 취소',
                  sourceId: 'expire-${pending.id}',
                  assetId: pending.assetId,
                  tradeSide: pending.side.name,
                  marketMinute: minute,
                  orderType: TradeOrderType.limit.name,
                ),
              ],
            );
            return current;
          },
        ),
      ),
    );
    await waitForMarketHome(tester);
    await tester.tap(find.byKey(const Key('market-speed-10x')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('장 마감으로 미체결 주문 1건이 자동 취소됐어요.'), findsOneWidget);
    expect(find.textContaining('체결되어 시장 시간을'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hour jump cannot race an in-flight realtime save', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final base = const GameEngine()
        .createNewGame('Realtime Race Test', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: krxOpenMinute);
    final pending = PendingTradeOrder(
      id: 'pending-race-test',
      side: PendingOrderSide.buy,
      assetId: 'hanbit_telecom',
      symbol: '1001',
      name: '한빛통신',
      market: '미래시장',
      currency: 'KRW',
      limitPrice: 1000,
      originalQuantity: 1,
      remainingQuantity: 1,
      placedDate: marketDateKey(base.currentDate),
      placedMinute: krxOpenMinute,
      placedSequence: 0,
    );
    var current = base.copyWith(pendingOrders: [pending]);
    final saveCompleter = Completer<GameState>();
    final requestedMinutes = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(
          state: current,
          universe: testMarketUniverse(),
          onSetMarketMinute: (minute) {
            requestedMinutes.add(minute);
            return saveCompleter.future;
          },
        ),
      ),
    );
    await waitForMarketHome(tester);
    await tester.tap(find.byKey(const Key('market-speed-10x')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(requestedMinutes, [krxOpenMinute + 1]);

    await tester.tap(find.byKey(const Key('market-advance-hour-button')));
    await tester.pump();
    expect(requestedMinutes, [krxOpenMinute + 1]);

    current = current.copyWith(marketMinute: krxOpenMinute + 1);
    saveCompleter.complete(current);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(requestedMinutes, everyElement(lessThan(krxOpenMinute + 60)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('notebook saves queue without letting the market clock race', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var current = const GameEngine()
        .createNewGame('Notebook Race Test', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: krxOpenMinute);
    final firstSave = Completer<void>();
    final requestedMinutes = <int>[];
    final savedFavorites = <Set<String>>[];

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(
          state: current,
          universe: testMarketUniverse(),
          onSetMarketMinute: (minute) async {
            requestedMinutes.add(minute);
            current = current.copyWith(marketMinute: minute);
            return current;
          },
          onSaveMarketNotebook: (favorites, notes) async {
            savedFavorites.add(Set<String>.of(favorites));
            if (savedFavorites.length == 1) await firstSave.future;
            current = current.copyWith(
              story: current.story.copyWith(
                storyFlags: <String, dynamic>{
                  ...current.story.storyFlags,
                  'marketFavoriteAssetIds': favorites.toList()..sort(),
                  'marketResearchNotes': <String, String>{...notes},
                },
              ),
            );
            return current;
          },
        ),
      ),
    );
    await waitForMarketHome(tester);
    await tester.tap(find.byKey(const Key('market-speed-pause')));
    await tester.pump();
    await openMarketExplore(tester);
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggle-market-favorite')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('toggle-market-favorite')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('market-speed-10x')).last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(savedFavorites, hasLength(1));
    expect(savedFavorites.single, {'hanbit_telecom'});
    expect(requestedMinutes, everyElement(krxOpenMinute));

    firstSave.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(savedFavorites, hasLength(2));
    expect(savedFavorites.last, isEmpty);
    expect(requestedMinutes, everyElement(krxOpenMinute));
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
    await tester.ensureVisible(find.byKey(const Key('stock-row-1001')));
    await tester.pump();
    final preOpenRate = tester.widget<Text>(
      find.byKey(const Key('stock-rate-1001')),
    );
    expect(preOpenRate.data, '0.00%');
    expect(preOpenRate.style?.color, const Color(0xFF191F28));
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final detailPrice = find.byKey(const Key('stock-detail-price'));
    expect(detailPrice, findsOneWidget);
    final detailChange = tester.widget<Text>(
      find.byKey(const Key('stock-detail-change-rate')),
    );
    expect(detailChange.data, '0원 · 0.00%');
    expect(detailChange.style?.color, const Color(0xFF191F28));
    final priceBeforeOpen = tester.widget<Text>(detailPrice).data;
    expect(find.text('개장 전 · 09:00부터 1분봉 생성'), findsNothing);
    expect(find.byKey(const Key('order-book-trade-strength')), findsOneWidget);
    expect(find.byKey(const Key('stock-detail-status-strip')), findsOneWidget);
    expect(find.byKey(const Key('stock-status-session')), findsOneWidget);
    expect(find.text('개장전'), findsOneWidget);
    await tester.tap(find.byKey(const Key('stock-detail-tab-chart')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('chart-window-label'))).data,
      contains('0개 캔들'),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('stock-detail-tab-quote')));
    await tester.pump();
    expect(find.byKey(const Key('order-book-trade-strength')), findsOneWidget);

    expect(
      tester.widget<Text>(find.byKey(const Key('stock-detail-price'))).data,
      priceBeforeOpen,
    );
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

  testWidgets('market clock keeps running in the inline order workspace', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = const GameEngine()
        .createNewGame('인라인 주문 시계 진행 테스트', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: 9 * 60);

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(state: state, universe: testMarketUniverse()),
      ),
    );
    await openMarketExplore(tester);
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pumpAndSettle();
    final clock = find.byKey(const Key('market-phone-status-time'));
    await tester.tap(find.byKey(const Key('stock-detail-tab-order')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('buy-stock-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-ticket')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-book')), findsOneWidget);
    expect(find.byKey(const Key('detailed-order-screen')), findsNothing);
    expect(find.byKey(const Key('order-quantity-value')), findsOneWidget);
    final before = tester.widget<Text>(clock.first).data;

    await tester.pump(const Duration(seconds: 2));

    expect(tester.widget<Text>(clock.first).data, isNot(before));
    expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'order-book pulse rebuilds only live liquidity fragments and submits the latest book',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = const GameEngine()
          .createNewGame('호가 펄스 범위 테스트', initialCash: 1000000)
          .copyWith(day: 4, marketMinute: 9 * 60);
      TradeOrder? submittedOrder;

      await tester.pumpWidget(
        MaterialApp(
          home: StockMarketScreen(
            state: state,
            universe: testMarketUniverse(),
            onExecuteTrade: (order) async {
              submittedOrder = order;
              return TradeExecutionResult(
                state: state,
                success: false,
                message: 'captured',
              );
            },
          ),
        ),
      );
      await openMarketExplore(tester);
      await tester.tap(find.byKey(const Key('stock-row-1001')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stock-detail-tab-order')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('order-quantity-plus')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('limit-price-plus')));
      await tester.pump();
      final quantityBeforePulse = tester.widget<Text>(
        find.byKey(const Key('order-quantity-value')),
      );
      final limitPriceBeforePulse = tester.widget<Text>(
        find.byKey(const Key('limit-price-value')),
      );
      final orderTypeBeforePulse = tester
          .widget<SegmentedButton<TradeOrderType>>(
            find.byKey(const Key('order-type-selector')),
          );
      final ticketBeforePulse = tester.widget(
        find.byKey(const Key('inline-order-ticket')),
      );
      final railBeforePulse = tester.widget(
        find.byKey(const Key('inline-order-book')),
      );
      final maximumBeforePulse = tester.widget(
        find.byKey(const Key('inline-order-maximum')),
      );
      final previewBeforePulse = tester.widget(
        find.byKey(const Key('inline-order-liquidity-preview')),
      );

      final pulseBuilders = tester
          .widgetList<ValueListenableBuilder<int>>(
            find.descendant(
              of: find.byKey(const Key('inline-order-workspace')),
              matching: find.byType(ValueListenableBuilder<int>),
            ),
          )
          .toList(growable: false);
      final pulseNotifier = pulseBuilders
          .map((builder) => builder.valueListenable)
          .whereType<ValueNotifier<int>>()
          .first;
      pulseNotifier.value += 1;
      await tester.pump();

      expect(
        identical(
          tester.widget(find.byKey(const Key('inline-order-ticket'))),
          ticketBeforePulse,
        ),
        isTrue,
      );
      expect(
        identical(
          tester.widget<Text>(find.byKey(const Key('order-quantity-value'))),
          quantityBeforePulse,
        ),
        isTrue,
      );
      expect(
        identical(
          tester.widget<Text>(find.byKey(const Key('limit-price-value'))),
          limitPriceBeforePulse,
        ),
        isTrue,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('limit-price-value'))).data,
        limitPriceBeforePulse.data,
      );
      expect(
        identical(
          tester.widget<SegmentedButton<TradeOrderType>>(
            find.byKey(const Key('order-type-selector')),
          ),
          orderTypeBeforePulse,
        ),
        isTrue,
      );
      expect(
        tester
            .widget<SegmentedButton<TradeOrderType>>(
              find.byKey(const Key('order-type-selector')),
            )
            .selected,
        orderTypeBeforePulse.selected,
      );
      expect(
        identical(
          tester.widget(find.byKey(const Key('inline-order-book'))),
          railBeforePulse,
        ),
        isFalse,
      );
      expect(
        identical(
          tester.widget(find.byKey(const Key('inline-order-maximum'))),
          maximumBeforePulse,
        ),
        isFalse,
      );
      expect(
        identical(
          tester.widget(
            find.byKey(const Key('inline-order-liquidity-preview')),
          ),
          previewBeforePulse,
        ),
        isFalse,
      );

      await tester.tap(find.byKey(const Key('request-parent-order-approval')));
      await tester.pump();
      expect(submittedOrder, isNotNull);
      expect(submittedOrder!.microstructureFrame, pulseNotifier.value);
      expect(
        submittedOrder!.displayedSnapshot?.liquidityPulse,
        pulseNotifier.value,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'counter-side order-book pulse keeps trade text and red border on one row',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = const GameEngine()
          .createNewGame('호가 반대 체결 행 테스트', initialCash: 1000000)
          .copyWith(day: 4, marketMinute: 9 * 60);

      await tester.pumpWidget(
        MaterialApp(
          home: StockMarketScreen(state: state, universe: testMarketUniverse()),
        ),
      );
      await openMarketExplore(tester);
      await tester.tap(find.byKey(const Key('stock-row-1001')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();

      final orderBook = find.byKey(const Key('stock-order-book'));
      final activeTrade = find.byKey(const Key('order-book-active-trade'));
      final currentPriceBorder = find.byKey(
        const Key('order-book-current-price-border'),
      );
      expect(orderBook, findsOneWidget);
      expect(currentPriceBorder, findsOneWidget);

      final pulseNotifier = _orderBookPulseNotifier(tester);
      expect(
        activeTrade,
        findsNothing,
        reason: '정지 상태로 연 최초 프레임은 가짜 체결을 만들면 안 됩니다.',
      );
      pulseNotifier.value += 1;
      await tester.pump();
      expect(activeTrade, findsOneWidget);
      expect(
        _displayedOrderBookNumber(
          tester,
          find.byKey(const Key('stock-detail-price')),
        ),
        _displayedOrderBookTrade(tester).price,
      );

      final pulseBuilders = tester
          .widgetList<ValueListenableBuilder<int>>(
            find.ancestor(
              of: orderBook,
              matching: find.byType(ValueListenableBuilder<int>),
            ),
          )
          .toList(growable: false);
      expect(pulseBuilders, isNotEmpty);
      final initialTradeText = tester.widget<Text>(activeTrade).data!;
      final initialWasBuy = initialTradeText.startsWith('매수');
      String? counterSideTradeText;
      final firstCounterSideCandidateFrame = pulseNotifier.value + 1;

      for (
        var frame = firstCounterSideCandidateFrame;
        frame < firstCounterSideCandidateFrame + 64;
        frame += 1
      ) {
        pulseNotifier.value = frame;
        await tester.pump();
        expect(activeTrade, findsOneWidget);
        final text = tester.widget<Text>(activeTrade).data!;
        if (text.startsWith('매수') != initialWasBuy) {
          counterSideTradeText = text;
          break;
        }
      }
      expect(
        counterSideTradeText,
        isNotNull,
        reason: '64개 결정론적 미세구조 펄스 안에 반대 방향 체결이 있어야 한다.',
      );

      expect(
        _displayedOrderBookNumber(
          tester,
          find.byKey(const Key('stock-detail-price')),
        ),
        _displayedOrderBookTrade(tester).price,
        reason: '상단 현재가는 마지막 합성 체결의 절대가격과 같아야 합니다.',
      );
      final activeTradePosition = tester.widget<Positioned>(
        find.ancestor(of: activeTrade, matching: find.byType(Positioned)).first,
      );
      final borderPosition = tester.widget<AnimatedPositioned>(
        currentPriceBorder,
      );
      expect(activeTradePosition.top, borderPosition.top);
      expect(
        find.descendant(
          of: find.byKey(const Key('order-book-current-price')),
          matching: activeTrade,
        ),
        findsOneWidget,
      );

      const twelveHzFrameInterval = Duration(milliseconds: 83);
      expect(borderPosition.duration, const Duration(milliseconds: 72));
      expect(borderPosition.duration, lessThan(twelveHzFrameInterval));
      final depthAnimations = tester
          .widgetList<TweenAnimationBuilder<double>>(
            find.descendant(
              of: orderBook,
              matching: find.byType(TweenAnimationBuilder<double>),
            ),
          )
          .toList(growable: false);
      expect(depthAnimations, hasLength(24));
      expect(
        depthAnimations.every(
          (animation) =>
              animation.duration == const Duration(milliseconds: 72) &&
              animation.duration < twelveHzFrameInterval,
        ),
        isTrue,
      );

      await tester.pump(const Duration(milliseconds: 72));
      expect(
        tester.getCenter(currentPriceBorder).dy,
        closeTo(
          tester
              .getCenter(find.byKey(const Key('order-book-current-price')))
              .dy,
          0.1,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'trade print consumes the same absolute-price row by its printed quantity',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = const GameEngine()
          .createNewGame('체결 잔량 차감 회귀 테스트', initialCash: 1000000)
          .copyWith(day: 4, marketMinute: 9 * 60);

      await tester.pumpWidget(
        MaterialApp(
          home: StockMarketScreen(state: state, universe: testMarketUniverse()),
        ),
      );
      await openMarketExplore(tester);
      await tester.tap(find.byKey(const Key('stock-row-1001')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();

      final pulseNotifier = _orderBookPulseNotifier(tester);
      final before = _displayedOrderBookQuantities(tester);
      pulseNotifier.value += 1;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      final trade = _displayedOrderBookTrade(tester);
      final beforeQuantity = before[trade.price];
      expect(
        beforeQuantity,
        isNotNull,
        reason: '체결 문구가 붙은 절대가격은 직전 프레임의 6+6 호가에도 있어야 합니다.',
      );
      expect(find.byKey(const Key('order-book-trade-tape')), findsOneWidget);
      expect(
        find.byKey(const Key('order-book-trade-tape-empty')),
        findsNothing,
      );
      expect(find.byKey(const Key('order-book-quantity-delta')), findsWidgets);
      expect(
        trade.displayedQuantity,
        math.max(0, beforeQuantity! - trade.printedQuantity),
        reason:
            '${trade.isBuy ? '매수' : '매도'} 체결 ${trade.printedQuantity}주는 '
            '${trade.price}원 행의 표시 잔량에서 같은 프레임에 정확히 차감돼야 합니다.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inline limit controls move and clear the compact rail selection',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = const GameEngine()
          .createNewGame('인라인 호가 선택 동기화 테스트', initialCash: 1000000)
          .copyWith(day: 4, marketMinute: 9 * 60);

      await tester.pumpWidget(
        MaterialApp(
          home: StockMarketScreen(state: state, universe: testMarketUniverse()),
        ),
      );
      await openMarketExplore(tester);
      await tester.tap(find.byKey(const Key('stock-row-1001')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();
      await tester.tap(find.byKey(const Key('stock-detail-tab-order')));
      await tester.pump();

      List<Finder> inlineRows() {
        final asks = find.byKey(const ValueKey('inline-order-book-ask-row'));
        final bids = find.byKey(const ValueKey('inline-order-book-bid-row'));
        return <Finder>[
          for (var index = 0; index < asks.evaluate().length; index += 1)
            asks.at(index),
          for (var index = 0; index < bids.evaluate().length; index += 1)
            bids.at(index),
        ];
      }

      String rowPrice(Finder row) => tester
          .widget<Text>(
            find.descendant(of: row, matching: find.byType(Text)).first,
          )
          .data!;

      Finder rowAtPrice(String price) {
        final matches = inlineRows()
            .where((row) => rowPrice(row) == price)
            .toList(growable: false);
        expect(
          matches,
          hasLength(1),
          reason: '선택 가격 $price 행이 compact 6+6 호가에 하나 있어야 합니다.',
        );
        return matches.single;
      }

      double rowMaterialAlpha(Finder row) => tester
          .widget<Material>(
            find.ancestor(of: row, matching: find.byType(Material)).first,
          )
          .color!
          .a;

      String selectedLimitPrice() => tester
          .widget<Text>(find.byKey(const Key('limit-price-value')))
          .data!
          .replaceAll('원', '');

      final initialPrice = selectedLimitPrice();
      final initiallySelectedRow = rowAtPrice(initialPrice);
      expect(rowMaterialAlpha(initiallySelectedRow), closeTo(0.90, 0.01));

      await tester.tap(find.byKey(const Key('limit-price-plus')));
      await tester.pump();

      final raisedPrice = selectedLimitPrice();
      expect(raisedPrice, isNot(initialPrice));
      expect(rowMaterialAlpha(rowAtPrice(raisedPrice)), closeTo(0.90, 0.01));
      expect(rowMaterialAlpha(rowAtPrice(initialPrice)), closeTo(0.58, 0.01));

      await tester.tap(find.text('시장가'));
      await tester.pump();

      expect(
        inlineRows().map(rowMaterialAlpha),
        everyElement(closeTo(0.58, 0.01)),
        reason: '시장가 주문에는 특정 지정가 호가 선택 tint가 남으면 안 됩니다.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'multi-level full fill prints only the last exact row for one pulse',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final baseState = const GameEngine()
          .createNewGame('플레이어 다단계 체결 표시 테스트', initialCash: 2000000000)
          .copyWith(day: 4, marketMinute: 9 * 60, brokerageCash: 2000000000);
      late int firstPrice;
      late int firstQuantity;
      late int lastPrice;
      late int lastQuantity;
      TradeOrder? submittedOrder;

      await tester.pumpWidget(
        MaterialApp(
          home: StockMarketScreen(
            state: baseState,
            universe: testMarketUniverse(),
            onExecuteTrade: (order) async {
              submittedOrder = order;
              final filledQuantity = firstQuantity + lastQuantity;
              final notional =
                  firstPrice * firstQuantity + lastPrice * lastQuantity;
              final averageFillPrice = notional / filledQuantity;
              final filledState = baseState.copyWith(
                ledger: <LedgerEntry>[
                  ...baseState.ledger,
                  LedgerEntry(
                    id: 'widget-multi-level-full-fill',
                    day: baseState.day,
                    amount: -notional,
                    account: 'brokerage_cash',
                    counterAccount: 'listed_equity',
                    description: '두 호가 전량 체결',
                    sourceId: 'widget-multi-level-full-fill',
                    notional: notional,
                    assetId: order.assetId,
                    tradeSide: TradeSide.buy.name,
                    tradeQuantity: filledQuantity.toDouble(),
                    tradeUnitPrice: averageFillPrice,
                    marketMinute: order.marketMinute,
                    orderType: TradeOrderType.market.name,
                    orderBookSide: 'ask',
                    orderBookFills: <LedgerOrderBookFill>[
                      LedgerOrderBookFill(
                        price: firstPrice.toDouble(),
                        quantity: firstQuantity.toDouble(),
                      ),
                      LedgerOrderBookFill(
                        price: lastPrice.toDouble(),
                        quantity: lastQuantity.toDouble(),
                      ),
                    ],
                    orderBookCapacityUnits: filledQuantity,
                  ),
                ],
              );
              return TradeExecutionResult(
                state: filledState,
                success: true,
                message: '다단계 전량 체결',
                notional: notional,
                filledQuantity: filledQuantity.toDouble(),
                averageFillPrice: averageFillPrice,
              );
            },
          ),
        ),
      );
      await openMarketExplore(tester);
      await tester.tap(find.byKey(const Key('stock-row-1001')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();

      final positiveAskRows = <({int price, int quantity})>[];
      for (var index = 0; index < 6; index += 1) {
        final row = find.byKey(ValueKey('order-book-ask-$index'));
        if (row.evaluate().isEmpty) continue;
        final quantity = _displayedOrderBookNumber(
          tester,
          find
              .descendant(
                of: find.descendant(
                  of: row,
                  matching: find.byKey(
                    const ValueKey('order-book-sell-quantity-cell'),
                  ),
                ),
                matching: find.byType(Text),
              )
              .first,
        );
        if (quantity <= 0) continue;
        positiveAskRows.add((
          price: _displayedOrderBookNumber(
            tester,
            find
                .descendant(
                  of: row,
                  matching: find.byKey(
                    const ValueKey('order-book-price-label'),
                  ),
                )
                .first,
          ),
          quantity: quantity,
        ));
      }
      expect(
        positiveAskRows,
        hasLength(greaterThanOrEqualTo(2)),
        reason: '다단계 체결 회귀에는 양수 매도호가 두 행이 필요합니다.',
      );
      firstPrice = positiveAskRows[0].price;
      firstQuantity = positiveAskRows[0].quantity;
      lastPrice = positiveAskRows[1].price;
      lastQuantity = positiveAskRows[1].quantity;

      await tester.tap(find.byKey(const Key('stock-detail-tab-order')));
      await tester.pump();
      await tester.tap(find.text('시장가'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('request-parent-order-approval')));
      await tester.pump();
      expect(submittedOrder, isNotNull);

      await tester.tap(find.byKey(const Key('stock-detail-tab-quote')));
      await tester.pump();

      final playerTrade = _displayedOrderBookTrade(tester);
      expect(
        find.byKey(const Key('order-book-player-tape-print')),
        findsOneWidget,
      );
      expect(playerTrade.isBuy, isTrue);
      expect(playerTrade.price, lastPrice);
      expect(playerTrade.printedQuantity, lastQuantity);
      expect(playerTrade.displayedQuantity, 0);
      expect(
        playerTrade.printedQuantity,
        isNot(firstQuantity + lastQuantity),
        reason: '마지막 행에는 다단계 총체결량이 아니라 그 행 체결량만 표시해야 합니다.',
      );
      final stalePlayerText = tester
          .widget<Text>(find.byKey(const Key('order-book-active-trade')))
          .data;

      final pulseNotifier = _orderBookPulseNotifier(tester);
      expect(pulseNotifier.value, submittedOrder!.microstructureFrame);
      pulseNotifier.value += 1;
      await tester.pump();

      final activeTrade = find.byKey(const Key('order-book-active-trade'));
      if (activeTrade.evaluate().isNotEmpty) {
        final nextTrade = _displayedOrderBookTrade(tester);
        expect(
          nextTrade.price != lastPrice ||
              tester.widget<Text>(activeTrade).data != stalePlayerText,
          isTrue,
          reason: '플레이어 체결 문구는 다음 미세구조 펄스까지 남으면 안 됩니다.',
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stock detail exposes fundamentals and a limit-order ticket', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const engine = GameEngine();
    var current = engine
        .createNewGame('지정가 화면 테스트', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: 9 * 60);

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(
          state: current,
          universe: testMarketUniverse(includeKnownPartner: true),
          onExecuteTrade: (order) async {
            final result = engine.executeTrade(current, order);
            current = result.state;
            return result;
          },
        ),
      ),
    );
    await openMarketExplore(tester);
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stock-detail-bottom-nav')), findsOneWidget);
    expect(find.byKey(const Key('stock-order-book')), findsOneWidget);
    expect(find.byKey(const Key('order-book-trade-flow')), findsNothing);
    expect(find.byKey(const Key('order-book-trade-flow-list')), findsNothing);
    expect(find.byKey(const Key('minute-candle-chart')), findsNothing);
    expect(find.byKey(const Key('investor-flow-card')), findsNothing);
    expect(find.byKey(const Key('order-book-turnover')), findsOneWidget);
    expect(find.byKey(const Key('order-book-capacity')), findsNothing);
    expect(find.byKey(const Key('order-book-trade-strength')), findsOneWidget);
    expect(find.byKey(const Key('order-book-active-summary')), findsNothing);
    expect(find.byKey(const Key('order-book-market-summary')), findsOneWidget);
    expect(find.byKey(const Key('order-book-trade-tape')), findsOneWidget);
    expect(find.byKey(const Key('quote-order-dock')), findsOneWidget);
    expect(find.byKey(const Key('quote-order-dock-sell')), findsOneWidget);
    expect(find.byKey(const Key('quote-order-dock-buy')), findsOneWidget);
    expect(find.text('10단계 호가'), findsNothing);
    expect(find.textContaining('게임용 자동생성'), findsNothing);
    expect(find.textContaining('가상 장중'), findsNothing);
    expect(find.byKey(const Key('order-book-ask-0')), findsOneWidget);
    expect(find.byKey(const Key('order-book-bid-0')), findsOneWidget);
    expect(find.text('매도잔량'), findsWidgets);
    expect(find.text('매수잔량'), findsWidgets);
    final sellCells = find.byKey(const Key('order-book-sell-quantity-cell'));
    final buyCells = find.byKey(const Key('order-book-buy-quantity-cell'));
    final sellCellCount = sellCells.evaluate().length;
    final buyCellCount = buyCells.evaluate().length;
    expect(sellCellCount, 6);
    expect(buyCellCount, 6);
    final sellDepthBarFinder = find.byKey(
      const Key('order-book-sell-depth-bar'),
    );
    final buyDepthBarFinder = find.byKey(const Key('order-book-buy-depth-bar'));
    final sellDepthBars = tester
        .widgetList<FractionallySizedBox>(sellDepthBarFinder)
        .map((bar) => bar.widthFactor!)
        .toList(growable: false);
    final buyDepthBars = tester
        .widgetList<FractionallySizedBox>(buyDepthBarFinder)
        .map((bar) => bar.widthFactor!)
        .toList(growable: false);
    expect(sellDepthBars, hasLength(sellCellCount));
    expect(buyDepthBars, hasLength(buyCellCount));
    for (final depthBarFinder in <Finder>[
      sellDepthBarFinder,
      buyDepthBarFinder,
    ]) {
      for (
        var index = 0;
        index < depthBarFinder.evaluate().length;
        index += 1
      ) {
        final renderedBar = depthBarFinder.at(index);
        expect(
          tester.widget<FractionallySizedBox>(renderedBar).heightFactor,
          1,
        );
        expect(tester.getSize(renderedBar).height, greaterThan(0));
      }
    }
    expect(
      tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: sellDepthBarFinder,
              matching: find.byType(DecoratedBox),
            ),
          )
          .every(
            (bar) =>
                (bar.decoration as BoxDecoration).color ==
                const Color(0x998DB8F3),
          ),
      isTrue,
    );
    expect(
      tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: buyDepthBarFinder,
              matching: find.byType(DecoratedBox),
            ),
          )
          .every(
            (bar) =>
                (bar.decoration as BoxDecoration).color ==
                const Color(0x99EF9AB7),
          ),
      isTrue,
    );
    final depthRecords = <(int, double)>[];
    for (final sideKey in const <Key>[
      Key('order-book-sell-quantity-cell'),
      Key('order-book-buy-quantity-cell'),
    ]) {
      final cells = find.byKey(sideKey);
      for (
        var index = 0;
        index < find.byKey(sideKey).evaluate().length;
        index += 1
      ) {
        final cell = cells.at(index);
        final label = tester
            .widget<Text>(
              find.descendant(of: cell, matching: find.byType(Text)).first,
            )
            .data!;
        final quantityText = RegExp(r'[\d,]+').allMatches(label).last.group(0)!;
        final quantity = int.parse(quantityText.replaceAll(',', ''));
        final fraction = tester
            .widget<FractionallySizedBox>(
              find
                  .descendant(
                    of: cell,
                    matching: find.byType(FractionallySizedBox),
                  )
                  .first,
            )
            .widthFactor!;
        depthRecords.add((quantity, fraction));
      }
    }
    final commonMaximum = depthRecords
        .map((record) => record.$1)
        .reduce(math.max);
    for (final (quantity, fraction) in depthRecords) {
      expect(fraction, closeTo(quantity / commonMaximum, 0.0001));
    }
    expect(
      [...sellDepthBars, ...buyDepthBars].reduce(math.max),
      closeTo(1, 0.0001),
    );
    expect(sellDepthBars.toSet().length, greaterThan(1));
    expect(buyDepthBars.toSet().length, greaterThan(1));
    expect(
      tester
          .widgetList<Align>(
            find.descendant(
              of: find.byKey(const Key('order-book-sell-quantity-cell')),
              matching: find.byType(Align),
            ),
          )
          .every((align) => align.alignment == Alignment.centerRight),
      isTrue,
    );
    expect(
      tester
          .widgetList<Align>(
            find.descendant(
              of: find.byKey(const Key('order-book-buy-quantity-cell')),
              matching: find.byType(Align),
            ),
          )
          .every((align) => align.alignment == Alignment.centerLeft),
      isTrue,
    );
    expect(find.byKey(const Key('order-book-sell-wall')), findsNothing);
    expect(find.byKey(const Key('order-book-buy-wall')), findsNothing);
    expect(find.textContaining('매도벽'), findsNothing);
    expect(find.textContaining('매수벽'), findsNothing);
    expect(
      find.byKey(const Key('order-book-current-price-border')),
      findsOneWidget,
    );
    final currentPriceBorder = tester.widget<AnimatedPositioned>(
      find.byKey(const Key('order-book-current-price-border')),
    );
    expect(currentPriceBorder.duration, const Duration(milliseconds: 72));
    final currentPriceBorderBox = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const Key('order-book-current-price-border')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final currentPriceBorderDecoration =
        currentPriceBorderBox.decoration as BoxDecoration;
    expect(currentPriceBorderDecoration.color, isNull);
    expect(currentPriceBorderDecoration.boxShadow, isNull);
    final currentPriceBorderSide =
        (currentPriceBorderDecoration.border! as Border).top;
    expect(currentPriceBorderSide.color, const Color(0xFFF04452));
    expect(currentPriceBorderSide.width, 2);
    final priceSurfaces = tester
        .widgetList<Container>(
          find.byKey(const Key('order-book-price-surface')),
        )
        .toList(growable: false);
    expect(priceSurfaces, hasLength(12));
    final priceLabels = tester
        .widgetList<Text>(find.byKey(const Key('order-book-price-label')))
        .toList(growable: false);
    expect(priceLabels, hasLength(12));
    expect(priceLabels.map((label) => label.style!.fontSize).toSet(), {16.0});
    final outlinedPrice = tester
        .widget<Text>(
          find
              .descendant(
                of: find.byKey(const Key('order-book-current-price')),
                matching: find.byKey(const ValueKey('order-book-price-label')),
              )
              .first,
        )
        .data;
    expect(
      outlinedPrice,
      tester.widget<Text>(find.byKey(const Key('stock-detail-price'))).data,
    );
    void expectOutlineUsesOnlyCentralBestPriceRows() {
      final currentPriceOutline = find.byKey(
        const Key('order-book-current-price-border'),
      );
      final currentPriceRow = find.byKey(const Key('order-book-current-price'));
      expect(currentPriceOutline, findsOneWidget);
      expect(currentPriceRow, findsOneWidget);
      final outlinePosition = tester.widget<AnimatedPositioned>(
        currentPriceOutline,
      );
      final rowPosition = tester.widget<Positioned>(
        find
            .ancestor(of: currentPriceRow, matching: find.byType(Positioned))
            .first,
      );
      expect(outlinePosition.top, rowPosition.top);
      final bestAskPosition = tester.widget<Positioned>(
        find
            .ancestor(
              of: find.byKey(const Key('order-book-ask-0')),
              matching: find.byType(Positioned),
            )
            .first,
      );
      final bestBidPosition = tester.widget<Positioned>(
        find
            .ancestor(
              of: find.byKey(const Key('order-book-bid-0')),
              matching: find.byType(Positioned),
            )
            .first,
      );
      expect(bestAskPosition.top, lessThan(bestBidPosition.top!));
      expect(
        <double?>[bestAskPosition.top, bestBidPosition.top],
        contains(outlinePosition.top),
        reason: '체결가 테두리는 중앙 최우선 매도·매수 두 칸만 오가야 한다.',
      );
    }

    expectOutlineUsesOnlyCentralBestPriceRows();
    final quoteScrollable = find
        .ancestor(
          of: find.byKey(const Key('stock-order-book')),
          matching: find.byType(Scrollable),
        )
        .first;
    expect(
      tester.state<ScrollableState>(quoteScrollable).position.maxScrollExtent,
      0,
    );
    expect(
      tester.getBottomRight(find.byKey(const Key('stock-order-book'))).dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const Key('stock-detail-bottom-nav'))).dy,
      ),
    );
    expect(
      find.byKey(const Key('order-book-active-trade')),
      findsNothing,
      reason: 'frame 0 must not invent a trade before the first pulse',
    );
    _orderBookPulseNotifier(tester).value += 1;
    await tester.pump();
    final activeTradeText = tester
        .widget<Text>(find.byKey(const Key('order-book-active-trade')))
        .data!;
    expect(
      activeTradeText.contains('매수') || activeTradeText.contains('매도'),
      isTrue,
    );
    final activeTradePosition = tester.widget<Positioned>(
      find
          .ancestor(
            of: find.byKey(const Key('order-book-active-trade')),
            matching: find.byType(Positioned),
          )
          .first,
    );
    final currentOutlinePosition = tester.widget<AnimatedPositioned>(
      find.byKey(const Key('order-book-current-price-border')),
    );
    expect(activeTradePosition.top, currentOutlinePosition.top);
    expect(
      find.descendant(
        of: find.byKey(const Key('stock-order-book')),
        matching: find.text('현재가'),
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('order-book-active-trade')), findsOneWidget);
    final fixedPriceTop = tester.getTopLeft(
      find.byKey(const Key('stock-detail-price')),
    );

    final selectedAskPrice = tester
        .widget<Text>(
          find
              .descendant(
                of: find.byKey(const Key('order-book-ask-0')),
                matching: find.byKey(const ValueKey('order-book-price-label')),
              )
              .first,
        )
        .data;
    await tester.ensureVisible(find.byKey(const Key('order-book-ask-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('order-book-ask-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quote-quick-actions')), findsOneWidget);
    expect(
      find.byKey(const Key('order-book-selected-price-marker')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('quote-quick-sell')), findsOneWidget);
    expect(find.byKey(const Key('quote-quick-buy')), findsOneWidget);
    expect(find.byKey(const Key('quote-quick-amend-cancel')), findsOneWidget);
    await tester.tap(find.byKey(const Key('quote-quick-buy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-ticket')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-book')), findsOneWidget);
    expectSymmetricInlineOrderBook(tester);
    expect(find.byKey(const Key('detailed-order-screen')), findsNothing);
    expect(find.text('현금'), findsNothing);
    expect(find.text('신용'), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const Key('inline-order-book'))).dx,
      greaterThan(
        tester.getTopLeft(find.byKey(const Key('inline-order-ticket'))).dx,
      ),
    );
    expect(find.byKey(const Key('order-type-selector')), findsOneWidget);
    expect(find.byKey(const Key('limit-price-control')), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<TradeOrderType>>(
            find.byKey(const Key('order-type-selector')),
          )
          .selected,
      {TradeOrderType.limit},
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('limit-price-value'))).data,
      selectedAskPrice,
    );
    await tester.ensureVisible(
      find.byKey(const Key('request-parent-order-approval')),
    );
    await tester.tap(find.byKey(const Key('request-parent-order-approval')));
    await tester.pump();
    expect(find.byKey(const Key('order-result')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('request-parent-order-approval')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-parent-order-approval')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-book-active-summary')), findsNothing);
    expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);

    await tester.tap(find.byKey(const Key('stock-detail-tab-quote')));
    await tester.pump();
    expectOutlineUsesOnlyCentralBestPriceRows();
    expect(
      find.byKey(const Key('order-book-average-cost-marker')),
      findsOneWidget,
    );

    final selectedBidPrice = tester
        .widget<Text>(
          find
              .descendant(
                of: find.byKey(const Key('order-book-bid-0')),
                matching: find.byKey(const ValueKey('order-book-price-label')),
              )
              .first,
        )
        .data;
    await tester.ensureVisible(find.byKey(const Key('order-book-bid-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('order-book-bid-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quote-quick-actions')), findsOneWidget);
    await tester.tap(find.byKey(const Key('quote-quick-sell')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-ticket')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-book')), findsOneWidget);
    expect(find.byKey(const Key('detailed-order-screen')), findsNothing);
    expect(find.text('매도 주문'), findsWidgets);
    expect(find.byKey(const Key('limit-price-control')), findsOneWidget);
    expect(find.text('수수료·세금'), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<TradeOrderType>>(
            find.byKey(const Key('order-type-selector')),
          )
          .selected,
      {TradeOrderType.limit},
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('limit-price-value'))).data,
      selectedBidPrice,
    );
    await tester.ensureVisible(
      find.byKey(const Key('request-parent-order-approval')),
    );
    await tester.tap(find.byKey(const Key('request-parent-order-approval')));
    await tester.pump();
    expect(find.byKey(const Key('order-result')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('request-parent-order-approval')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('request-parent-order-approval')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-book-active-summary')), findsNothing);
    expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);

    await tester.tap(find.byKey(const Key('stock-detail-tab-quote')));
    await tester.pump();
    expectOutlineUsesOnlyCentralBestPriceRows();

    await tester.tap(find.byKey(const Key('stock-detail-tab-chart')));
    await tester.pump();
    expect(find.byKey(const Key('minute-candle-chart')), findsOneWidget);
    expect(find.byKey(const Key('stock-order-book')), findsNothing);

    await tester.tap(find.byKey(const Key('stock-detail-tab-info')));
    await tester.pump();
    expect(find.byKey(const Key('investor-flow-card')), findsOneWidget);
    expect(find.text('종목투자자'), findsOneWidget);
    expect(find.text('개인'), findsWidgets);
    expect(find.text('외국인'), findsWidgets);
    expect(find.text('기관계'), findsWidgets);
    await tester.tap(find.byKey(const Key('investor-flow-unit-amount')));
    await tester.pump();
    expect(find.text('순매수 · 금액'), findsOneWidget);
    await tester.tap(find.byKey(const Key('investor-flow-detail-tab')));
    await tester.pump();
    expect(find.text('금융투자'), findsOneWidget);
    expect(find.text('연기금'), findsWidgets);

    await tester.scrollUntilVisible(
      find.byKey(const Key('company-overview-card')),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('기업정보'), findsOneWidget);
    expect(find.text('국내 시가총액 순위'), findsOneWidget);
    expect(find.text('내 보유주식수'), findsOneWidget);
    expect(find.text('내 지분율'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('company-owned-shares-value')))
          .data,
      '0주',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const Key('company-ownership-percent-value')),
          )
          .data,
      '0%',
    );
    expect(find.text('발행주식수'), findsOneWidget);
    expect(find.text('광대역망'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('company-fundamentals-card')),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('company-fundamentals-card')), findsOneWidget);
    expect(find.text('분기 재무와 시장 기대'), findsOneWidget);
    expect(find.text('사업 관계망'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('stock-detail-price'))).dy,
      closeTo(fixedPriceTop.dy, 0.1),
    );
    expect(find.byKey(const Key('stock-detail-change-rate')), findsOneWidget);

    await tester.tap(find.byKey(const Key('stock-detail-tab-order')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('buy-stock-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-type-selector')), findsOneWidget);
    await tester.tap(find.text('지정가'));
    await tester.pump();
    expect(find.byKey(const Key('limit-price-control')), findsOneWidget);
    expect(find.text('오른쪽 호가를 누르면 주문 가격이 바뀝니다.'), findsOneWidget);
    expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);
    expect(find.byKey(const Key('detailed-order-screen')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quote order dock applies a fixed share preset to buy orders', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = const GameEngine()
        .createNewGame('호가 주문 도크 테스트', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: 9 * 60);

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(state: state, universe: testMarketUniverse()),
      ),
    );
    await openMarketExplore(tester);
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('market-speed-pause')).last);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('quote-quantity-ten')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quote-order-dock-buy')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('order-quantity-value')).first)
          .data,
      '10주',
    );
    expect(find.text('매수 주문'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('order book fits a compact phone without quote scrolling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = const GameEngine()
        .createNewGame('호가 한 화면 테스트', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: 9 * 60);

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(
          state: state,
          universe: testMarketUniverse(includeKnownPartner: true),
        ),
      ),
    );
    await openMarketExplore(tester);
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pumpAndSettle();

    final compactSellRows = find.byKey(
      const Key('order-book-sell-quantity-cell'),
    );
    final compactBuyRows = find.byKey(
      const Key('order-book-buy-quantity-cell'),
    );
    expect(compactSellRows, findsNWidgets(6));
    expect(compactBuyRows, findsNWidgets(6));
    final quoteScrollable = find
        .ancestor(
          of: find.byKey(const Key('stock-order-book')),
          matching: find.byType(Scrollable),
        )
        .first;
    expect(
      tester.state<ScrollableState>(quoteScrollable).position.maxScrollExtent,
      0,
    );
    expect(
      tester.getBottomRight(find.byKey(const Key('stock-order-book'))).dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const Key('stock-detail-bottom-nav'))).dy,
      ),
    );

    await tester.tap(find.byKey(const Key('stock-detail-tab-order')));
    await tester.pump();
    expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-ticket')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-book')), findsOneWidget);
    expectSymmetricInlineOrderBook(tester);
    expect(find.byKey(const Key('detailed-order-screen')), findsNothing);
    expect(find.text('현금'), findsNothing);
    expect(find.text('신용'), findsNothing);
    final ticketRect = tester.getRect(
      find.byKey(const Key('inline-order-ticket')),
    );
    final railRect = tester.getRect(find.byKey(const Key('inline-order-book')));
    final workspaceRect = tester.getRect(
      find.byKey(const Key('inline-order-workspace')),
    );
    expect(ticketRect.left, greaterThanOrEqualTo(0));
    expect(ticketRect.right, lessThanOrEqualTo(railRect.left));
    expect(railRect.right, lessThanOrEqualTo(360));
    expect(
      workspaceRect.bottom,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const Key('stock-detail-bottom-nav'))).dy,
      ),
    );

    final firstRailRow = find
        .byKey(const ValueKey('inline-order-book-ask-row'))
        .first;
    final firstRailPrice = tester
        .widget<Text>(
          find.descendant(of: firstRailRow, matching: find.byType(Text)).first,
        )
        .data!;
    await tester.tap(firstRailRow);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('limit-price-value'))).data,
      '$firstRailPrice원',
    );

    await tester.tap(find.byKey(const Key('sell-stock-button')));
    await tester.pumpAndSettle();
    expect(find.text('매도 주문'), findsWidgets);
    expect(find.byKey(const Key('inline-order-book')), findsOneWidget);
    expect(find.byKey(const Key('detailed-order-screen')), findsNothing);
    await tester.tap(find.byKey(const Key('buy-stock-button')));
    await tester.pumpAndSettle();
    expect(find.text('매수 주문'), findsWidgets);
    expect(find.byKey(const Key('inline-order-book')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(
          state: state.copyWith(marketMinute: krxContinuousEndMinute),
          universe: testMarketUniverse(includeKnownPartner: true),
        ),
      ),
    );
    await openMarketExplore(tester);
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('closing-auction-indicative-price')),
      findsOneWidget,
    );
    final closingQuoteScrollable = find
        .ancestor(
          of: find.byKey(const Key('stock-order-book')),
          matching: find.byType(Scrollable),
        )
        .first;
    expect(
      tester
          .state<ScrollableState>(closingQuoteScrollable)
          .position
          .maxScrollExtent,
      0,
    );
    expect(
      tester.getBottomRight(find.byKey(const Key('stock-order-book'))).dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(const Key('stock-detail-bottom-nav'))).dy,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('grandfather gift opens the first guardian order authority', (
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
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stock-detail-tab-order')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('buy-stock-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order-authority-warning')), findsNothing);
    expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-ticket')), findsOneWidget);
    expect(find.byKey(const Key('inline-order-book')), findsOneWidget);
    expect(find.text('매수 주문'), findsWidgets);
    expect(find.text('현금'), findsNothing);
    expect(find.text('신용'), findsNothing);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('request-parent-order-approval')),
    );
    expect(button.onPressed, isNotNull);
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
        contains('미래거래소 정규장'),
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
      var dismissedBreakingNews = 0;
      while (find
              .byKey(const Key('market-breaking-news-confirm'))
              .evaluate()
              .isNotEmpty &&
          dismissedBreakingNews < 50) {
        final confirm = find.byKey(const Key('market-breaking-news-confirm'));
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        dismissedBreakingNews++;
      }
      expect(
        find.byKey(const Key('market-breaking-news-confirm')),
        findsNothing,
      );
      expect(requestedMinutes, <int>[krxOpenMinute, krxCloseMinute]);
      expect(tester.widget<Text>(clock.first).data, contains('15:00'));
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
      expect(tester.widget<Text>(clock.first).data, contains('15:00'));
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

    await tester.ensureVisible(find.byKey(const Key('stock-row-1001')));
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('stock-detail-tab-order')));
    await tester.pump();
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

      await tester.pumpWidget(
        const MillenniumCapitalApp(
          campaignWorldPreparer: _skipCampaignWorldPreparation,
        ),
      );
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
    'rider mini-game clears checkpoints and produces a scored result',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(
          home: RiderMiniGame(
            courseDuration: Duration(milliseconds: 350),
            spawnObstacles: false,
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('rider-start')));
      await tester.tap(find.byKey(const Key('rider-start')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byKey(const Key('work-result-card')), findsOneWidget);
      expect(find.text('79점'), findsOneWidget);
      expect(find.textContaining('배달 3/3'), findsOneWidget);
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
    final rider = tester.widget<InkWell>(
      find.byKey(const Key('work-activity-rider')),
    );
    expect(rider.onTap, isNotNull);
    rider.onTap!();
    await tester.pumpAndSettle();
    expect(find.byType(RiderMiniGame), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('rider clear score determines the paid reward', () {
    const engine = GameEngine();
    final base = engine.createNewGame('라이더 보상 테스트');
    final low = engine.completeWorkSession(
      base,
      const WorkSessionResult(activityId: 'rider', score: 60, maxScore: 100),
    );
    final high = engine.completeWorkSession(
      base,
      const WorkSessionResult(activityId: 'rider', score: 100, maxScore: 100),
    );

    expect(low.cash, greaterThan(base.cash));
    expect(high.cash, greaterThan(low.cash));
    expect(high.story.storyFlags['lastWorkActivity'], 'rider');
  });

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
    expect(find.textContaining('09:00'), findsOneWidget);
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

        await tester.pumpWidget(
          const MillenniumCapitalApp(
            campaignWorldPreparer: _skipCampaignWorldPreparation,
          ),
        );
        await tester.pumpAndSettle();
        await continueFirstSave(tester);

        final hourFinder = find.byKey(const Key('advance-hour-button'));
        final dayFinder = find.byKey(const Key('advance-day-button'));
        expect(hourFinder, findsOneWidget);
        expect(dayFinder, findsOneWidget);
        expect(find.byTooltip('1시간 보내기 · 게임 시간 60분 진행'), findsOneWidget);
        expect(find.byTooltip('하루 보내기 · 신문 확인 후 다음 날 08:00'), findsOneWidget);

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
