import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_persistence.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_quote.dart';
import 'package:millennium_capital/game/order_book.dart';
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
  bool isVisible,
});

int _displayedOrderBookNumber(WidgetTester tester, Finder finder) {
  final label = tester.widget<Text>(finder).data!;
  return int.parse(label.replaceAll(RegExp(r'[^0-9]'), ''));
}

Future<void> _finishOrderBookSweepPlayback(WidgetTester tester) async {
  final activeSweep = find.byWidgetPredicate((widget) {
    final key = widget.key;
    if (key is! ValueKey) return false;
    final value = key.value;
    if (value is! Record) return false;
    final dynamic record = value;
    return record.$1 == 'order-book-sweep-active';
  }, skipOffstage: false);
  var emptyFrames = 0;
  for (var wait = 0; wait < 80; wait += 1) {
    if (activeSweep.evaluate().isEmpty) {
      emptyFrames += 1;
      if (emptyFrames >= 3) return;
    } else {
      emptyFrames = 0;
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(
    activeSweep,
    findsNothing,
    reason: 'canonical 주문장을 검증하기 전에 도착→소진 FIFO 표현 재생이 끝나야 합니다.',
  );
}

Map<int, int> _displayedOrderBookQuantities(WidgetTester tester) {
  final quantities = <int, int>{};
  for (final side in const ['ask', 'bid']) {
    final quantityCellKey = ValueKey(
      side == 'ask'
          ? 'order-book-sell-quantity-cell'
          : 'order-book-buy-quantity-cell',
    );
    for (var index = 0; index < stockOrderBookVisibleSideRows; index += 1) {
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

_DisplayedOrderBookTrade _displayedOrderBookTrade(
  WidgetTester tester, {
  bool player = false,
}) {
  final tapeScope = find.byKey(
    Key(player ? 'order-book-player-tape-print' : 'order-book-trade-tape'),
  );
  expect(tapeScope, findsOneWidget);
  final tapeQuantitySide = find.descendant(
    of: tapeScope,
    matching: find.byKey(const Key('order-book-tape-quantity-side')),
  );
  final tapePrice = find.descendant(
    of: tapeScope,
    matching: find.byKey(const Key('order-book-tape-price')),
  );
  expect(tapeQuantitySide, findsWidgets);
  expect(tapePrice, findsWidgets);
  final tapeText = tester.widget<Text>(tapeQuantitySide.first).data!;
  final match = RegExp(r'^([\d,]+)주 (매수|매도)').firstMatch(tapeText);
  expect(match, isNotNull, reason: '체결 테이프는 실제 수량과 방향을 노출해야 합니다: $tapeText');
  final printedQuantity = int.parse(match!.group(1)!.replaceAll(',', ''));
  final isBuy = match.group(2) == '매수';
  final expectedSide = isBuy ? 'ask' : 'bid';
  final quantityCellKey = ValueKey(
    isBuy ? 'order-book-sell-quantity-cell' : 'order-book-buy-quantity-cell',
  );
  final price = _displayedOrderBookNumber(tester, tapePrice.first);
  final activeMarker = find.byKey(const Key('order-book-active-trade-row'));

  Finder? matchingRow;
  var matchingRowIsActive = false;
  for (var index = 0; index < stockOrderBookVisibleSideRows; index += 1) {
    final row = find.byKey(ValueKey('order-book-$expectedSide-$index'));
    final rowPriceFinder = find.descendant(
      of: row,
      matching: find.byKey(const ValueKey('order-book-price-label')),
    );
    final hasTapePrice =
        rowPriceFinder.evaluate().isNotEmpty &&
        _displayedOrderBookNumber(tester, rowPriceFinder.first) == price;
    if (!hasTapePrice) continue;
    matchingRow = row;
    matchingRowIsActive = find
        .descendant(of: row, matching: activeMarker)
        .evaluate()
        .isNotEmpty;
    break;
  }

  if (matchingRow == null) {
    if (!player) {
      expect(
        activeMarker,
        findsNothing,
        reason: '완전 소진된 체결 가격은 0행이나 활성 테두리로 남으면 안 됩니다.',
      );
    }
    return (
      price: price,
      printedQuantity: printedQuantity,
      displayedQuantity: 0,
      isBuy: isBuy,
      isVisible: false,
    );
  }

  if (!player) {
    expect(
      matchingRowIsActive,
      isTrue,
      reason: '남아 있는 최근 체결 호가는 체결 테이프와 같은 행이어야 합니다.',
    );
  }
  final displayedQuantity = _displayedOrderBookNumber(
    tester,
    find
        .descendant(
          of: find.descendant(
            of: matchingRow,
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
    isVisible: true,
  );
}

bool _hasSynchronizedDisplayedOrderBookTrade(WidgetTester tester) {
  final tapeScope = find.byKey(const Key('order-book-trade-tape'));
  final activeMarker = find.byKey(const Key('order-book-active-trade-row'));
  final currentPriceBorder = find.byKey(
    const Key('order-book-current-price-border'),
  );
  if (tapeScope.evaluate().length != 1 || activeMarker.evaluate().length != 1) {
    return false;
  }
  if (currentPriceBorder.evaluate().length != 1 ||
      (tester.getCenter(currentPriceBorder).dy -
                  tester.getCenter(activeMarker).dy)
              .abs() >
          0.1) {
    return false;
  }
  final quantitySide = find.descendant(
    of: tapeScope,
    matching: find.byKey(const Key('order-book-tape-quantity-side')),
  );
  final tapePrice = find.descendant(
    of: tapeScope,
    matching: find.byKey(const Key('order-book-tape-price')),
  );
  if (quantitySide.evaluate().isEmpty || tapePrice.evaluate().isEmpty) {
    return false;
  }
  final tapeText = tester.widget<Text>(quantitySide.first).data ?? '';
  final match = RegExp(r'^([\d,]+)주 (매수|매도)').firstMatch(tapeText);
  if (match == null) return false;
  final expectedSide = match.group(2) == '매수' ? 'ask' : 'bid';
  final expectedPrice = _displayedOrderBookNumber(tester, tapePrice.first);
  for (var index = 0; index < stockOrderBookVisibleSideRows; index += 1) {
    final row = find.byKey(ValueKey('order-book-$expectedSide-$index'));
    if (find.descendant(of: row, matching: activeMarker).evaluate().isEmpty) {
      continue;
    }
    final rowPrice = find.descendant(
      of: row,
      matching: find.byKey(const ValueKey('order-book-price-label')),
    );
    return rowPrice.evaluate().isNotEmpty &&
        _displayedOrderBookNumber(tester, rowPrice.first) == expectedPrice;
  }
  return false;
}

String _displayedOrderBookTradeDebug(WidgetTester tester) {
  final tapeScope = find.byKey(const Key('order-book-trade-tape'));
  final quantitySide = find.descendant(
    of: tapeScope,
    matching: find.byKey(const Key('order-book-tape-quantity-side')),
  );
  final tapePrice = find.descendant(
    of: tapeScope,
    matching: find.byKey(const Key('order-book-tape-price')),
  );
  final tapeSideText = quantitySide.evaluate().isEmpty
      ? '<none>'
      : tester.widget<Text>(quantitySide.first).data ?? '<null>';
  final tapePriceText = tapePrice.evaluate().isEmpty
      ? '<none>'
      : tester.widget<Text>(tapePrice.first).data ?? '<null>';
  final active = <String>[];
  for (final side in const <String>['ask', 'bid']) {
    for (var index = 0; index < stockOrderBookVisibleSideRows; index += 1) {
      final row = find.byKey(ValueKey('order-book-$side-$index'));
      if (find
          .descendant(
            of: row,
            matching: find.byKey(const Key('order-book-active-trade-row')),
          )
          .evaluate()
          .isEmpty) {
        continue;
      }
      final price = find.descendant(
        of: row,
        matching: find.byKey(const ValueKey('order-book-price-label')),
      );
      active.add(
        '$side[$index]=${price.evaluate().isEmpty ? '<none>' : tester.widget<Text>(price.first).data}',
      );
    }
  }
  return 'tape=$tapeSideText@$tapePriceText active=${active.join(',')}';
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
    if (find
        .byKey(const Key('prologue-player-name-input'))
        .evaluate()
        .isNotEmpty) {
      await tester.enterText(
        find.byKey(const Key('prologue-player-name-input')),
        '테스트운용자',
      );
      await tester.tap(find.byKey(const Key('prologue-player-name-confirm')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> skipCurrentPrologueSection(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('story-skip-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('story-skip-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('story-skip-confirm')));
    await tester.pumpAndSettle();
  }

  Future<void> skipAllPrologueSections(WidgetTester tester) async {
    for (var section = 0; section < 8; section += 1) {
      await skipCurrentPrologueSection(tester);
    }
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
    for (var attempt = 0; attempt < 64; attempt++) {
      await tester.pump(const Duration(milliseconds: 650));
      if (overlay.evaluate().isEmpty) return;
      if (action.evaluate().isEmpty) {
        expect(find.byKey(const Key('story-dialogue-panel')), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
        continue;
      }
      expect(action, findsOneWidget);
      await tester.tap(action);
      await tester.pump(const Duration(milliseconds: 650));
    }
    expect(overlay, findsNothing);
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
    expect(askRows, findsNWidgets(stockOrderBookVisibleSideRows));
    expect(bidRows, findsNWidgets(stockOrderBookVisibleSideRows));

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
    final borderWidget = tester.widget(border);
    final borderTop = switch (borderWidget) {
      AnimatedPositioned(:final top) => top,
      Positioned(:final top) => top,
      _ => null,
    };
    expect(borderTop, isNotNull);
    final bestAskSlot = tester.widget<Positioned>(
      find.ancestor(of: lowestAskRow, matching: find.byType(Positioned)).first,
    );
    final bestBidSlot = tester.widget<Positioned>(
      find.ancestor(of: highestBidRow, matching: find.byType(Positioned)).first,
    );
    if (borderWidget is AnimatedPositioned) {
      expect(borderWidget.duration, const Duration(milliseconds: 144));
      expect(
        borderTop,
        anyOf(bestAskSlot.top, bestBidSlot.top),
        reason: '대기 중 인라인 공유 테두리는 중앙 두 고정 슬롯 사이에서 움직여야 한다.',
      );
    } else {
      final sweep = find.byKey(const Key('inline-order-book-sweep-step'));
      expect(sweep, findsOneWidget);
      expect(
        tester.getCenter(border).dy,
        closeTo(tester.getCenter(sweep).dy, 0.1),
        reason: '소진 중 테두리는 현재 체결 가격행에 고정돼야 한다.',
      );
    }
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

  Future<void> goToCorridor(WidgetTester tester) async {
    await dismissHubTutorial(tester);
    await tester.tap(find.byKey(const Key('apartment-go-living-room')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apartment-go-kitchen')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('apartment-go-corridor')));
    await tester.pumpAndSettle();
  }

  Future<void> completeOrientationPreview(WidgetTester tester) async {
    await startNewGame(tester);
    await skipAllPrologueSections(tester);
    expect(find.byKey(const Key('orientation-complete-card')), findsOneWidget);
  }

  testWidgets('opening dialogue establishes the NIS Project Decimal restart', (
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
    await startNewGame(tester);

    expect(find.textContaining('비가 자정의 유리창을'), findsOneWidget);
    await advanceDialogue(tester, 1);
    expect(find.text('한규진 국정원장'), findsOneWidget);
    expect(find.textContaining('결정권이 넘어가는 순간'), findsOneWidget);
    await advanceDialogue(tester, 1);
    expect(find.text('임서희 경제안보국장'), findsOneWidget);
    await advanceDialogue(tester, 1);
    expect(find.text('도윤석 기획조정관'), findsOneWidget);
    await advanceDialogue(tester, 1);
    expect(find.text('조민경 권익감사관'), findsOneWidget);
    expect(find.textContaining('거부권'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialogue opacity control persists across the next line', (
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
    await startNewGame(tester);

    double visiblePanelOpacity() {
      final panel = tester.widget<Container>(
        find.byKey(const Key('story-dialogue-panel')),
      );
      final decoration = panel.decoration! as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      return gradient.colors.first.a;
    }

    expect(visiblePanelOpacity(), lessThan(0.01));
    expect(
      find.byKey(const ValueKey('story-dialogue-backdrop-blur-0.00')),
      findsOneWidget,
    );
    final control = find.byKey(const Key('story-dialogue-opacity-control'));
    expect(control, findsOneWidget);
    await tester.tapAt(tester.getTopRight(control) + const Offset(-5, 14));
    await tester.pumpAndSettle();
    final adjustedOpacity = visiblePanelOpacity();
    expect(adjustedOpacity, greaterThan(0.7));
    expect(
      find.byKey(const ValueKey('story-dialogue-backdrop-blur-7.00')),
      findsOneWidget,
    );

    await advanceDialogue(tester, 1);
    expect(visiblePanelOpacity(), closeTo(adjustedOpacity, 0.01));

    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    expect(
      preferences.getDouble('project-decimal-dialogue-panel-opacity-v1'),
      closeTo(adjustedOpacity, 0.01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping anywhere advances even while dialogue is typing', (
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
    await tester.tap(find.byKey(const Key('new-game-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('prologue-player-name-input')),
      '민수',
    );
    await tester.tap(find.byKey(const Key('prologue-player-name-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('이야기'), findsOneWidget);
    expect(find.byKey(const Key('story-stage-advance-area')), findsOneWidget);
    expect(find.byKey(const Key('story-continue')), findsOneWidget);
    expect(find.text('다음'), findsNothing);
    expect(find.byIcon(Icons.keyboard_double_arrow_down_rounded), findsNothing);

    await tester.tapAt(const Offset(24, 420));
    await tester.pump();
    expect(find.text('한규진 국정원장'), findsOneWidget);

    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 420));
    await tester.pumpAndSettle();
    expect(find.text('임서희 경제안보국장'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Decimal operator scene advances when the character area is tapped',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MillenniumCapitalApp(
          campaignWorldPreparer: _skipCampaignWorldPreparation,
        ),
      );
      await tester.pumpAndSettle();
      await startNewGame(tester);
      await advanceDialogue(tester, 134);

      expect(find.text('한서윤 운영관'), findsOneWidget);
      expect(find.textContaining('감당하지 않아도 될 위험'), findsOneWidget);
      expect(
        find.byKey(const Key('academy-teacher-character')),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(195, 390));
      await tester.pumpAndSettle();
      expect(find.text('박하은'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mouse wheel up returns to a recent previous dialogue beat', (
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
    await startNewGame(tester);
    await advanceDialogue(tester, 2);

    expect(find.text('임서희 경제안보국장'), findsOneWidget);
    expect(
      find.byKey(const Key('story-wheel-navigation-listener')),
      findsOneWidget,
    );

    tester.binding.handlePointerEvent(
      const PointerScrollEvent(
        position: Offset(195, 390),
        scrollDelta: Offset(0, -120),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('한규진 국정원장'), findsOneWidget);
    expect(find.textContaining('결정권이 넘어가는 순간'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection montage withholds center uniforms until final arrival', (
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
    await startNewGame(tester);
    await skipCurrentPrologueSection(tester);
    await skipCurrentPrologueSection(tester);

    expect(
      (tester
                  .widget<Image>(
                    find.byKey(const Key('story-background-image')),
                  )
                  .image
              as AssetImage)
          .assetName,
      'assets/images/cinematic_soft_painted/decimal/bg_decimal_matrix_exam_1999_v1.png',
    );
    expect(find.byKey(const Key('story-character-image')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prologue skip visits every Project Decimal visual act', (
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
    await startNewGame(tester);

    const expected = <String>[
      'assets/images/cinematic_soft_painted/decimal_nis_1999/backgrounds/bg_nis_decimal_archive_predawn_1999_v1.png',
      'assets/images/cinematic_soft_painted/decimal/bg_decimal_matrix_exam_1999_v1.png',
      'assets/images/cinematic_soft_painted/decimal/bg_decimal_unfair_game_1999_v1.png',
      'assets/images/cinematic_soft_painted/decimal/bg_decimal_desire_test_1999_v1.png',
      'assets/images/cinematic_soft_painted/decimal/bg_decimal_gangnam_exterior_winter_1999_v1.png',
      'assets/images/cinematic_soft_painted/decimal/bg_decimal_living_lounge_1999_v1.png',
      'assets/images/cinematic_soft_painted/decimal/bg_decimal_trading_floor_dawn_2000_v1.png',
    ];
    for (final asset in expected) {
      await skipCurrentPrologueSection(tester);
      expect(
        (tester
                    .widget<Image>(
                      find.byKey(const Key('story-background-image')),
                    )
                    .image
                as AssetImage)
            .assetName,
        asset,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialogue editor overrides backgrounds and appends new scenes', (
    tester,
  ) async {
    final scenes = List.generate(55, (index) {
      final order = index + 1;
      if (order == 1) {
        return {
          'id': 'scene-01',
          'order': order,
          'chapter': '프롤로그',
          'date': '편집기 날짜',
          'location': '편집기 장소',
          'speaker': '편집기 화자',
          'direction': '편집기에서 고친 지문이다.',
          'line': '편집기에서 고친 대사다.\\n두 번째 줄도 적용됐다.',
          'background':
              '/play/assets/assets/images/bg_bank_branch_2000_portrait_cartoon_v2.png',
          'character':
              '/play/assets/assets/images/protagonist_seed01/05_surprised.png',
        };
      }
      if (order == 55) {
        return {
          'id': 'scene-custom-55',
          'order': order,
          'chapter': '추가 장면',
          'date': '2000.01.02 · 08:05',
          'location': '추가 장면 교실',
          'speaker': '수아',
          'direction': '수아가 새 장면의 문을 열었다.',
          'line': '이 대사는 편집기에서 새로 추가했어.',
          'background':
              '/play/assets/assets/images/historical_prologue/bg_future_development_orientation_hall_2000_portrait_v1.png',
          'character':
              '/play/assets/assets/images/production_soft_painted/han_sua/02_warm_smile_quality_v2.png',
        };
      }
      return {
        'id': 'scene-${order.toString().padLeft(2, '0')}',
        'order': order,
        'chapter': '기존 장면',
        'date': '2000.01.02 · 08:00',
        'location': '오리엔테이션 강당',
        'speaker': '이야기',
        'direction': '',
        'line': '기존 장면 $order',
        'background':
            '/play/assets/assets/images/historical_prologue/bg_future_development_orientation_hall_2000_portrait_v1.png',
        'character': '',
      };
    });
    final dialogueOverrideJson = jsonEncode({
      'version': 1,
      'appearanceVersion': 6,
      'updatedAt': '2000-01-02T00:00:00.000Z',
      'scenes': scenes,
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MillenniumCapitalApp(
        campaignWorldPreparer: _skipCampaignWorldPreparation,
        dialogueOverrideJson: dialogueOverrideJson,
      ),
    );
    await tester.pumpAndSettle();
    await startNewGame(tester);
    await tester.pumpAndSettle();

    expect(find.text('편집기 화자'), findsOneWidget);
    expect(find.text('편집기에서 고친 지문이다.'), findsOneWidget);
    expect(find.text('편집기에서 고친 대사다.\n두 번째 줄도 적용됐다.'), findsOneWidget);
    expect(find.textContaining(r'\n'), findsNothing);
    expect(find.textContaining('편집기 장소'), findsOneWidget);
    expect(find.textContaining('편집기 날짜'), findsOneWidget);
    expect(
      (tester
                  .widget<Image>(find.byKey(const Key('story-character-image')))
                  .image
              as AssetImage)
          .assetName,
      'assets/images/protagonist_seed01/05_surprised.png',
    );
    expect(
      (tester
                  .widget<Image>(
                    find.byKey(const Key('story-background-image')),
                  )
                  .image
              as AssetImage)
          .assetName,
      'assets/images/bg_bank_branch_2000_portrait_cartoon_v2.png',
    );
    await advanceDialogue(tester, 54);

    expect(find.text('수아'), findsOneWidget);
    expect(find.text('수아가 새 장면의 문을 열었다.'), findsOneWidget);
    expect(find.text('이 대사는 편집기에서 새로 추가했어.'), findsOneWidget);
    expect(find.byKey(const Key('orientation-complete-card')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Project Decimal prologue connects the final ten to the stock PC',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MillenniumCapitalApp(
          campaignWorldPreparer: _skipCampaignWorldPreparation,
        ),
      );
      await tester.pumpAndSettle();
      await startNewGame(tester);
      await skipAllPrologueSections(tester);

      expect(
        find.byKey(const Key('orientation-complete-card')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('academy-pc-powered-off')), findsOneWidget);
      await tester.tap(find.byKey(const Key('academy-pc-power-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('academy-stock-app-icon')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('academy-stock-setup-screen')),
        findsOneWidget,
      );
      final playerNameInput = tester.widget<TextField>(
        find.byKey(const Key('academy-player-name-input')),
      );
      expect(playerNameInput.controller?.text, '테스트운용자');
      expect(find.text('데시멀 주식실습'), findsOneWidget);
      expect(find.textContaining('국가원금 50,000원'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pre-rewrite browser draft cannot restore obsolete dialogue', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'project-decimal-dialogue-runtime-v2': jsonEncode({
        'version': 1,
        'contentVersion': 2,
        'appearanceVersion': 15,
        'updatedAt': '2026-08-01T00:00:00.000Z',
        'scenes': [
          {
            'id': 'scene-01',
            'order': 1,
            'chapter': '구형 초안',
            'date': '구형 날짜',
            'location': '구형 장소',
            'speaker': '구형 화자',
            'direction': '',
            'line': '교체되기 전의 오래된 대사',
            'background': '',
            'character': '',
          },
        ],
      }),
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MillenniumCapitalApp(
        campaignWorldPreparer: _skipCampaignWorldPreparation,
      ),
    );
    await tester.pumpAndSettle();
    await startNewGame(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('구형 화자'), findsNothing);
    expect(find.textContaining('교체되기 전의 오래된 대사'), findsNothing);
    expect(find.textContaining('비가 자정의 유리창을'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'browser draft is applied only in explicit dialogue preview mode',
    (tester) async {
      final previewDraft = jsonEncode({
        'version': 1,
        'contentVersion': 2,
        'appearanceVersion': 15,
        'updatedAt': '2026-08-02T00:00:00.000Z',
        'scenes': [
          {
            'id': 'scene-01',
            'order': 1,
            'chapter': '명시적 미리보기',
            'date': '미리보기 날짜',
            'location': '미리보기 장소',
            'speaker': '미리보기 화자',
            'direction': '',
            'line': '편집기 브라우저 초안 미리보기',
            'background': '',
            'character': '',
          },
        ],
      });
      SharedPreferences.setMockInitialValues({
        'project-decimal-dialogue-runtime-v2': previewDraft,
      });
      final preferences = await SharedPreferences.getInstance();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MillenniumCapitalApp(
          campaignWorldPreparer: _skipCampaignWorldPreparation,
          dialoguePreviewMode: true,
        ),
      );
      await tester.pumpAndSettle();
      await startNewGame(tester);
      for (var attempt = 0; attempt < 40; attempt += 1) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('미리보기 화자').evaluate().isNotEmpty) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
      }
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<VisualNovelOnboardingScreen>(
              find.byType(VisualNovelOnboardingScreen),
            )
            .allowRuntimeDialoguePreview,
        isTrue,
      );
      await preferences.reload();
      expect(
        preferences.getString('project-decimal-dialogue-runtime-v2'),
        isNotNull,
      );
      expect(find.text('미리보기 화자'), findsOneWidget);
      expect(find.textContaining('편집기 브라우저 초안 미리보기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('prologue skip advances through eight Decimal sections', (
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
    await startNewGame(tester);

    const labels = <String>[
      '데시멀 재가동을 건너뛸까요?',
      '봉인된 실패 기록을 건너뛸까요?',
      '행렬 시험을 건너뛸까요?',
      '불공정 게임을 건너뛸까요?',
      '욕망 검증을 건너뛸까요?',
      '강남 아지트 도착을 건너뛸까요?',
      '첫날 공동생활을 건너뛸까요?',
      '첫 주문 브리핑을 건너뛸까요?',
    ];
    for (final label in labels) {
      await tester.tap(find.byKey(const Key('story-skip-button')));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      await tester.tap(find.byKey(const Key('story-skip-confirm')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('orientation-complete-card')), findsOneWidget);
    expect(find.byKey(const Key('academy-pc-powered-off')), findsOneWidget);
    expect(
      find.byKey(const Key('academy-market-tutorial-screen')),
      findsNothing,
    );
  });

  testWidgets(
    'orientation checkpoint resumes without opening the stock tutorial',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final persistence = GamePersistence(preferences: preferences);
      var prepareCalls = 0;

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MillenniumCapitalApp(
          persistence: persistence,
          campaignWorldPreparer: (state, onProgress) async {
            prepareCalls += 1;
            onProgress(const WorldLoadProgress(0.96, '데시멀 세계 계산 완료'));
            await Future<void>.delayed(Duration.zero);
          },
        ),
      );
      await tester.pumpAndSettle();
      await startNewGame(tester);
      expect(prepareCalls, 1);

      await skipAllPrologueSections(tester);
      expect(
        find.byKey(const Key('orientation-complete-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('academy-market-tutorial-screen')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('orientation-exit-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('game-title-screen')), findsOneWidget);
      final slots = await persistence.listSlots();
      expect(slots.first.isEmpty, isFalse);
      expect(slots.first.state!.story.flagBool('prologueInProgress'), isTrue);
      expect(slots.first.state!.story.flagInt('prologueBeat'), greaterThan(0));
      expect(prepareCalls, 1);

      await tester.tap(find.byKey(const Key('continue-game-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('load-save-slot-1')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('orientation-complete-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('academy-market-tutorial-screen')),
        findsNothing,
      );
      expect(prepareCalls, 2);
    },
  );

  testWidgets('linear policy dialogue fits the 360 by 800 mobile minimum', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MillenniumCapitalApp(
        campaignWorldPreparer: _skipCampaignWorldPreparation,
      ),
    );
    await tester.pumpAndSettle();
    await startNewGame(tester);
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pump();
    expect(find.byKey(const Key('story-typewriter-hint')), findsWidgets);
    await tester.tap(find.byKey(const ValueKey(1)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('story-line-text')), findsOneWidget);
    expect(find.byKey(const Key('story-typewriter-hint')), findsNothing);
    expect(find.byKey(const Key('story-continue')), findsWidgets);
    await tester.pumpAndSettle();
    await advanceDialogue(tester, 3);

    final continueButton = find.byKey(const Key('story-continue')).last;
    expect(continueButton, findsOneWidget);
    expect(tester.getTopLeft(continueButton).dx, greaterThanOrEqualTo(0));
    expect(tester.getBottomRight(continueButton).dx, lessThanOrEqualTo(360));
    expect(tester.getBottomRight(continueButton).dy, lessThanOrEqualTo(800));
    expect(find.byKey(const Key('story-line-text')), findsOneWidget);
    expect(find.byKey(const Key('policy-file-children')), findsNothing);
    expect(find.byKey(const Key('policy-file-capital')), findsNothing);
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

      expect(find.text('10대부터 건물주'), findsOneWidget);
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

  testWidgets('visual novel onboarding ends at the powered-off classroom PC', (
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

    await completeOrientationPreview(tester);

    expect(find.byKey(const Key('orientation-complete-card')), findsOneWidget);
    expect(find.byKey(const Key('academy-pc-powered-off')), findsOneWidget);
    expect(find.byKey(const Key('academy-pc-power-toggle')), findsOneWidget);
    expect(find.text('전원 OFF'), findsOneWidget);
    expect(
      find.byKey(const Key('academy-market-tutorial-screen')),
      findsNothing,
    );
    expect(find.byKey(const Key('apartment-place-bedroom')), findsNothing);
    expect(find.byKey(const Key('company-name-input')), findsNothing);
  });

  testWidgets(
    'classroom PC powers on and launches the first live stock lesson',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final preferences = await SharedPreferences.getInstance();
      final persistence = GamePersistence(preferences: preferences);

      await tester.pumpWidget(
        MillenniumCapitalApp(
          persistence: persistence,
          campaignWorldPreparer: _skipCampaignWorldPreparation,
        ),
      );
      await tester.pumpAndSettle();
      await startNewGame(tester);
      await skipAllPrologueSections(tester);

      expect(find.byKey(const Key('academy-pc-powered-off')), findsOneWidget);
      await tester.tap(find.byKey(const Key('academy-pc-power-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('academy-pc-desktop')), findsOneWidget);
      expect(find.text('전원 ON'), findsOneWidget);
      final stockAppIcon = tester.widget<Image>(
        find.byKey(const Key('academy-stock-app-icon-image')),
      );
      expect(
        (stockAppIcon.image as AssetImage).assetName,
        'assets/images/stock_practice_app_icon_v1.png',
      );
      expect(stockAppIcon.filterQuality, FilterQuality.high);

      await tester.tap(find.byKey(const Key('academy-stock-app-icon')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('academy-stock-setup-screen')),
        findsOneWidget,
      );
      expect(find.textContaining('한빛통신 · 거래일 시세'), findsOneWidget);
      expect(find.textContaining('국가원금 50,000원'), findsOneWidget);

      final lockedPlayerName = tester.widget<TextField>(
        find.byKey(const Key('academy-player-name-input')),
      );
      expect(lockedPlayerName.readOnly, isTrue);
      expect(lockedPlayerName.controller?.text, '테스트운용자');
      await tester.enterText(
        find.byKey(const Key('academy-company-name-input')),
        '첫빛 투자연구소',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('academy-start-market-tutorial')));

      final tutorialScreen = find.byKey(
        const Key('academy-market-tutorial-screen'),
      );
      for (var attempt = 0; attempt < 160; attempt += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (tutorialScreen.evaluate().isNotEmpty) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      expect(tutorialScreen, findsOneWidget);
      await waitForMarketHome(tester);
      expect(find.byKey(const Key('market-tutorial-overlay')), findsOneWidget);

      final saved = await persistence.loadSlot(1);
      expect(saved, isNotNull);
      expect(saved!.story.playerName, '테스트운용자');
      expect(saved.companyName, '첫빛 투자연구소');
      expect(saved.story.orphanageReboot, isTrue);
      expect(saved.story.marketTutorialSeen, isFalse);
      expect(saved.story.flagBool('prologueInProgress'), isFalse);
      expect(saved.brokerageCash, initialCompanyCash);
      expect(saved.currentDate, DateTime(2000, 1, 3));
      expect(saved.marketMinute, krxOpenMinute);
      expect(tester.takeException(), isNull);
    },
  );

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
    await goToCorridor(tester);
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

    expect(find.text('총자산 구성'), findsOneWidget);
    for (final id in ['cash', 'deposit', 'stock', 'property', 'business']) {
      expect(find.byKey(Key('ledger-allocation-$id')), findsOneWidget);
    }
    expect(find.byKey(const Key('ledger-total-liabilities')), findsOneWidget);
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
    final ledgerScroll = find.descendant(
      of: find.byKey(const Key('portfolio-ledger-scroll')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('애플'),
      240,
      scrollable: ledgerScroll,
    );
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
        operatingPrinciple: OperatingPrinciple.reportLosses,
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
            onSaveMarketNotebook: (favorites, notes) async {
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
      expect(
        (tester
                    .widget<Image>(
                      find.byKey(
                        const Key('market-tutorial-teacher-upper-body'),
                      ),
                    )
                    .image
                as AssetImage)
            .assetName,
        'assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png',
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

      expect(find.text('1 / 4').hitTestable(), findsOneWidget);
      expect(find.textContaining('이 교실이 회사라고 하죠'), findsOneWidget);
      await tester.tapAt(const Offset(8, 8));
      await tester.pump();
      expect(
        find.byKey(const Key('market-tutorial-wrong-tap-feedback')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('market-tutorial-next')));
      await tester.pump(const Duration(milliseconds: 650));
      expect(find.byKey(const Key('market-tutorial-teacher')), findsOneWidget);
      expect(find.byKey(const Key('market-tutorial-student')), findsNothing);
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
      expect(find.textContaining('싼 거랑 작은 거는 다른 겁니다'), findsOneWidget);
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
      expect(find.text('1 / 3').hitTestable(), findsOneWidget);
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
      expect(find.byKey(const Key('stock-detail-tab-chart')), findsOneWidget);
      expect(
        (tester
                    .widget<Image>(
                      find.byKey(
                        const Key('market-tutorial-teacher-upper-body'),
                      ),
                    )
                    .image
                as AssetImage)
            .assetName,
        'assets/images/주식선생님/23_포즈2_주인공그림체_공통슬롯_투명.png',
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

      await tester.tap(find.byKey(const Key('market-detail-tutorial-target')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('stock-detail-tab-info')), findsOneWidget);
      expect(
        (tester
                    .widget<Image>(
                      find.byKey(
                        const Key('market-tutorial-teacher-upper-body'),
                      ),
                    )
                    .image
                as AssetImage)
            .assetName,
        'assets/images/주식선생님/25_포즈4_주인공그림체_공통슬롯_투명.png',
      );
      expect(find.textContaining('주문 전에 두 칸을 채워야 해요'), findsOneWidget);
      for (var page = 0; page < 3; page += 1) {
        await tester.tap(find.byKey(const Key('market-detail-tutorial-next')));
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byKey(const Key('tutorial-buy-reason-choice-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tutorial-sell-rule-choice-0')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('save-market-research-note')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('tutorial-buy-reason-choice-0')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('save-market-research-note')),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(const Key('tutorial-sell-rule-choice-0')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('tutorial-sell-rule-choice-0')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('save-market-research-note')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-market-research-note')));
      await tester.pump(const Duration(milliseconds: 700));
      final savedNotes = current.story.storyFlags['marketResearchNotes'] as Map;
      expect(savedNotes.values.single, contains('매수 이유:'));
      expect(savedNotes.values.single, contains('매도 조건:'));

      await advanceTutorialPagesToTarget(
        tester,
        actionKey: const Key('market-detail-tutorial-next'),
        targetKey: const Key('market-detail-tutorial-target'),
      );
      expect(
        find.byKey(const Key('market-detail-tutorial-target')),
        findsOneWidget,
      );

      expect(find.textContaining('값이 너무 빨리 움직이면'), findsOneWidget);
      await tester.tap(find.byKey(const Key('market-detail-tutorial-target')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.textContaining('위쪽 숫자를 누르면 그 값이 주문에 들어와요'), findsOneWidget);
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
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const Key('stock-detail-tab-order')), findsOneWidget);
      expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);
      expect(find.byKey(const Key('inline-amend-cancel-tab')), findsOneWidget);
      expect(find.byKey(const Key('inline-open-orders-tab')), findsOneWidget);
      expect(find.byKey(const Key('inline-balance-tab')), findsOneWidget);
      expect(find.textContaining('정정/취소, 미체결, 잔고'), findsOneWidget);
      expect(
        (tester
                    .widget<Image>(
                      find.byKey(
                        const Key('market-tutorial-teacher-upper-body'),
                      ),
                    )
                    .image
                as AssetImage)
            .assetName,
        'assets/images/주식선생님/26_포즈5_주인공그림체_공통슬롯_투명.png',
      );
      for (var page = 0; page < 3; page += 1) {
        await tester.tap(find.byKey(const Key('market-detail-tutorial-next')));
        await tester.pump(const Duration(milliseconds: 180));
      }
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        find.byKey(const Key('market-order-tutorial-overlay')),
        findsOneWidget,
      );
      final tutorialPageRect = tester.getRect(
        find.byKey(const Key('market-practical-tutorial-page')),
      );
      expect(tutorialPageRect, const Rect.fromLTWH(0, 0, 360, 800));
      expect(
        find.byKey(const Key('market-order-tutorial-done')),
        findsOneWidget,
      );
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.textContaining('방금 누른'), findsOneWidget);

      await advanceTutorialPagesUntilDismissed(
        tester,
        actionKey: const Key('market-order-tutorial-done'),
        overlayKey: const Key('market-order-tutorial-overlay'),
      );
      expect(
        find.byKey(const Key('market-order-tutorial-overlay')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('tutorial-failure-practice')),
        findsOneWidget,
      );
      expect(find.text('틀려 봐야 주문표가 보입니다'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('tutorial-insufficient-funds-try')),
      );
      await tester.pump();
      expect(find.textContaining('접수 거절'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('tutorial-partial-fill-try')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('tutorial-partial-fill-try')));
      await tester.pump();
      expect(find.textContaining('나머지 1주는 미체결'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('tutorial-failure-practice-complete')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('tutorial-failure-practice-complete')),
      );
      await tester.pump();
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
      expect(
        find.byKey(const Key('tutorial-buy-action-highlight')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(current.story.marketTutorialSeen, isFalse);

      await tester.ensureVisible(
        find.byKey(const Key('request-state-account-order-approval')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('request-state-account-order-approval')),
      );
      await tester.pump();
      expect(find.byKey(const Key('order-result')), findsOneWidget);
      expect(find.textContaining('지정가 1주 전량 체결'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(current.cash, actualCashBefore);
      expect(current.brokerageCash, actualBrokerageBefore);
      expect(current.positions.length, actualPositionsBefore);

      await tester.ensureVisible(
        find.byKey(const Key('request-state-account-order-approval')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('request-state-account-order-approval')),
      );
      await tester.pump();
      expect(find.byKey(const Key('tutorial-price-change')), findsOneWidget);
      expect(find.text('매수 뒤 가격이 움직였어요'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('tutorial-live-account-state')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'tutorial-dialogue-character-assets/images/주식선생님/26_포즈5_주인공그림체_공통슬롯_투명.png',
          ),
        ),
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
      expect(
        find.text('화면의 이익은 아직 평가액이에요. 한 주를 팔아 결과를 확정해 볼까요?'),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'tutorial-dialogue-character-assets/images/주식선생님/27_포즈6_주인공그림체_공통슬롯_투명.png',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('한 주 팔고 결과 확정하기'), findsOneWidget);
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
        find.byKey(const Key('request-state-account-order-approval')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('request-state-account-order-approval')),
      );
      await tester.pump();
      expect(find.byKey(const Key('order-result')), findsOneWidget);
      expect(find.textContaining('매도 완료'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(
        find.byKey(const Key('request-state-account-order-approval')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('request-state-account-order-approval')),
      );
      await tester.pump();
      expect(find.byKey(const Key('tutorial-trade-summary')), findsOneWidget);
      expect(find.text('매수부터 매도까지 완료!'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(current.cash, actualCashBefore);
      expect(current.brokerageCash, actualBrokerageBefore);
      expect(current.positions.length, actualPositionsBefore);
      expect(current.story.marketTutorialSeen, isFalse);

      await tester.ensureVisible(
        find.byKey(const Key('tutorial-summary-continue')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('tutorial-summary-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tutorial-state-recovery')), findsOneWidget);
      expect(find.byKey(const Key('story-dialogue-panel')), findsOneWidget);
      await advanceTutorialPagesUntilDismissed(
        tester,
        actionKey: const Key('tutorial-recovery-continue'),
        overlayKey: const Key('tutorial-state-recovery'),
      );
      expect(
        find.byKey(const Key('tutorial-post-trade-review')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('story-dialogue-panel')), findsOneWidget);
      expect(find.byKey(const Key('story-speaker-chip')), findsOneWidget);
      expect(find.textContaining('첫 거래를 다시 본다면'), findsOneWidget);
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
        closeTo(reviewStageRect.height * 0.9, 0.01),
      );
      expect(
        reviewTeacherRect.bottom,
        closeTo(reviewStageRect.bottom - 104, 0.01),
      );
      expect(
        reviewTeacherRect.center.dx,
        closeTo(reviewStageRect.center.dx, 0.01),
      );
      expect(
        find.byKey(const Key('tutorial-review-protagonist-character')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('tutorial-review-choice-turnover')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const Key('tutorial-review-choice-turnover')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('tutorial-review-choice-turnover')),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
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
        find.descendant(
          of: find.byKey(const Key('tutorial-review-protagonist-character')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName ==
                    'assets/images/protagonist_seed01/12_thinking.png',
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('tutorial-review-continue')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byKey(const Key('tutorial-review-continue')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.byKey(const Key('tutorial-review-peer-character')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('tutorial-review-continue')));
      await tester.pump();
      expect(
        find.byKey(const Key('tutorial-school-dismissal')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tutorial-stock-feature-map')),
        findsOneWidget,
      );
      expect(find.text('호가 · 주문 · 차트 · 회사 정보/투자노트'), findsOneWidget);
      expect(find.textContaining('생활 라운지와 트레이딩 플로어를 오가며'), findsOneWidget);
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
    await tester.tap(find.byKey(const Key('market-speed-pause')).last);
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
    expect(
      find.descendant(
        of: find.byKey(const Key('inline-order-book')),
        matching: find.byKey(const Key('inline-order-book-price-rate')),
      ),
      findsNWidgets(stockOrderBookVisibleSideRows * 2),
    );
    expect(find.byKey(const Key('detailed-order-screen')), findsNothing);
    expect(find.text('현금'), findsNothing);
    expect(find.text('신용'), findsNothing);
    expect(find.text('주문 금액'), findsOneWidget);
    expect(find.byKey(const Key('order-quantity-value')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('시장가'));
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('request-state-account-order-approval')),
    );
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const Key('order-result')).evaluate().isNotEmpty) break;
    }
    final marketOrderResult = find.byKey(const Key('order-result'));
    expect(marketOrderResult, findsOneWidget);
    final marketOrderMessage = tester
        .widget<Text>(
          find
              .descendant(of: marketOrderResult, matching: find.byType(Text))
              .first,
        )
        .data!;
    final marketOrderSucceeded = marketOrderMessage.contains('1주 매수 완료');
    expect(
      marketOrderSucceeded ||
          marketOrderMessage == '시세가 바뀌었습니다. 호가창을 다시 확인해 주세요.',
      isTrue,
      reason: '실제 주문 결과: $marketOrderMessage',
    );
    expect(tester.takeException(), isNull);
    final saved =
        jsonDecode(
              (await SharedPreferences.getInstance()).getString(
                GamePersistence.saveKey,
              )!,
            )
            as Map<String, dynamic>;
    expect(
      (saved['positions'] as List<dynamic>),
      marketOrderSucceeded ? hasLength(1) : isEmpty,
    );
    expect(
      saved['cash'] as int,
      marketOrderSucceeded ? lessThan(1000000) : 1000000,
    );
    if (marketOrderSucceeded) {
      await tester.tap(
        find.byKey(const Key('request-state-account-order-approval')),
      );
      await tester.pumpAndSettle();
    }
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

  testWidgets(
    'stock detail separates wall identity when price crosses spread',
    (tester) async {
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
            .widget<Text>(
              find.byKey(const Key('market-phone-status-time')).first,
            )
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

      Key rowDepthAnimationKey(Key rowKey, Key depthBarKey) => tester
          .widget<TweenAnimationBuilder<double>>(
            find
                .ancestor(
                  of: find
                      .descendant(
                        of: find.byKey(rowKey),
                        matching: find.byKey(depthBarKey),
                      )
                      .first,
                  matching: find.byType(TweenAnimationBuilder<double>),
                )
                .first,
          )
          .key!;

      const bestAskKey = Key('order-book-ask-0');
      const bestBidKey = Key('order-book-bid-0');
      final beforeDepthAnimationKey = rowDepthAnimationKey(
        bestAskKey,
        const Key('order-book-sell-depth-bar'),
      );
      final askPriceIdentity = ValueKey((
        'order-book-price',
        'ask',
        targetPrice.toDouble(),
      ));
      final bidPriceIdentity = ValueKey((
        'order-book-price',
        'bid',
        targetPrice.toDouble(),
      ));
      expect(rowPrice(bestAskKey), targetPrice);
      expect(find.byKey(askPriceIdentity), findsOneWidget);
      expect(find.byKey(bidPriceIdentity), findsNothing);

      await tester.tap(find.byKey(const Key('market-speed-1x')).last);
      await tester.pump();
      await tester.pump(marketRealtimeTickDuration);
      await tester.pump();
      await tester.tap(find.byKey(const Key('market-speed-10x')).last);
      await tester.pump();
      var crossedBoundaryPresented = false;
      for (var frame = 0; frame < 90; frame += 1) {
        if (rowPrice(bestBidKey) == targetPrice &&
            find.byKey(askPriceIdentity).evaluate().isEmpty &&
            find.byKey(bidPriceIdentity).evaluate().isNotEmpty) {
          crossedBoundaryPresented = true;
          break;
        }
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(
        crossedBoundaryPresented,
        isTrue,
        reason: '다음 시계 틱 전에 체결된 경계 가격이 매수호가로 한 칸 이동해야 합니다.',
      );
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();

      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('market-phone-status-time')).first,
            )
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
      final afterDepthAnimationKey = rowDepthAnimationKey(
        bestBidKey,
        const Key('order-book-buy-depth-bar'),
      );
      expect(afterQuantity, greaterThan(0));
      expect(find.byKey(askPriceIdentity), findsNothing);
      expect(find.byKey(bidPriceIdentity), findsOneWidget);
      expect(
        afterDepthAnimationKey,
        isNot(equals(beforeDepthAnimationKey)),
        reason: '체결된 매도벽의 막대 상태를 새 매수벽이 이어받으면 안 됩니다.',
      );
      expect(
        find.descendant(
          of: find.byKey(bestBidKey),
          matching: find.byKey(const Key('order-book-quantity-delta')),
        ),
        findsNothing,
        reason: '새 매수벽에 직전 매도벽 대비 가짜 잔량 증감이 표시되면 안 됩니다.',
      );
      expect(tester.takeException(), isNull);
    },
  );

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
          .createNewGame(
            '일일 시가총액 회귀 테스트',
            initialCash: 1000000,
            worldSeed: 'daily-market-cap-widget-test',
          )
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
      final timeBeforeTick = tester
          .widget<Text>(find.byKey(const Key('market-phone-status-time')).first)
          .data;

      await tester.tap(find.byKey(const Key('market-speed-1x')).last);
      await tester.pump();
      await tester.pump(marketRealtimeTickDuration);
      await tester.pump();
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();

      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('market-phone-status-time')).first,
            )
            .data,
        isNot(timeBeforeTick),
        reason: '게임분이 진행된 뒤에도 일일 시가총액은 고정되어야 합니다.',
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
    await verifyDay(day: 5, expectedMarketCap: '60.4억원');
  });

  testWidgets(
    'stock market route re-entry restores the same 7+7 order-book session',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = const GameEngine()
          .createNewGame(
            '호가 재진입 회귀 테스트',
            initialCash: 1000000,
            worldSeed: 'order-book-route-reentry-widget-test',
          )
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
        for (var index = 0; index < stockOrderBookVisibleSideRows; index++)
          displayedLevelSignature(
            'ask',
            index,
            const Key('order-book-sell-quantity-cell'),
          ),
        for (var index = 0; index < stockOrderBookVisibleSideRows; index++)
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
      await tester.pump(const Duration(milliseconds: 160));
      await _finishOrderBookSweepPlayback(tester);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();
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
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();
      await openTargetStock();
      final restoredPulse = orderBookPulseNotifier();
      await _finishOrderBookSweepPlayback(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        restoredPulse.value,
        7,
        reason: '시장 화면 전체를 닫아도 같은 게임 세션의 미시구조 프레임을 이어야 합니다.',
      );
      final afterReentry = displayedBookSignature();
      expect(afterReentry, hasLength(beforeLeaving.length));
      final reentryQuantityChanges = <String>[];
      for (var index = 0; index < beforeLeaving.length; index += 1) {
        final before = beforeLeaving[index];
        final after = afterReentry[index];
        final beforeSeparator = before.lastIndexOf(':');
        final afterSeparator = after.lastIndexOf(':');
        expect(
          after.substring(0, afterSeparator),
          before.substring(0, beforeSeparator),
          reason: '시장 화면 전체 재진입 때 7+7 절대가격 행을 새로 추첨하면 안 됩니다.',
        );
        final beforeQuantity = int.parse(
          before
              .substring(beforeSeparator + 1)
              .replaceAll(RegExp(r'[^0-9]'), ''),
        );
        final afterQuantity = int.parse(
          after.substring(afterSeparator + 1).replaceAll(RegExp(r'[^0-9]'), ''),
        );
        expect(afterQuantity, greaterThan(0));
        if (afterQuantity != beforeQuantity) {
          reentryQuantityChanges.add('$index:$beforeQuantity->$afterQuantity');
        }
      }
      expect(
        reentryQuantityChanges.length,
        lessThanOrEqualTo(8),
        reason:
            '재진입 시 가격 14행과 프레임은 유지하되, 적응형 잔량 조각은 '
            '전체가 다시 추첨되지 않아야 합니다: $reentryQuantityChanges',
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
    final rightsSubscribe = find.byKey(const Key('market-rights-subscribe'));
    await Scrollable.ensureVisible(
      tester.element(rightsSubscribe),
      alignment: 0.5,
    );
    await tester.pump();
    await tester.tap(rightsSubscribe);
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
      await tester.tap(find.byKey(const Key('market-speed-10x')).last);
      await tester.pump();
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

  testWidgets(
    'opening a stock cannot alter settled OHLC candles or valuation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = const GameEngine()
          .createNewGame('호가 관측자 효과 회귀', initialCash: 1000000)
          .copyWith(
            day: 4,
            marketMinute: krxOpenMinute,
            brokerageCash: 500000,
            positions: const [
              PortfolioPosition(
                assetId: 'widget_partner',
                symbol: '1002',
                name: '테스트 부품',
                market: '미래시장',
                currency: 'KRW',
                units: 7,
                totalCost: 42000,
              ),
            ],
          );

      Future<Map<String, String>> runScenario({
        required bool keepTargetOpen,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StockMarketScreen(
              state: state,
              universe: testMarketUniverse(includeKnownPartner: true),
            ),
          ),
        );
        await waitForMarketHome(tester);
        await tester.tap(find.byKey(const Key('market-speed-pause')).last);
        await tester.pump();
        await openMarketExplore(tester);
        if (keepTargetOpen) {
          await tester.tap(find.byKey(const Key('stock-row-1001')));
          await tester.pumpAndSettle();
        }

        int displayedMinute() {
          final label = tester
              .widget<Text>(
                find.byKey(const Key('market-phone-status-time')).first,
              )
              .data!;
          final parts = label.split(':');
          return int.parse(parts[0]) * 60 + int.parse(parts[1]);
        }

        var guard = 0;
        while (displayedMinute() < krxContinuousEndMinute - 1) {
          final remaining = krxContinuousEndMinute - 1 - displayedMinute();
          final speedKey = remaining >= 10
              ? const Key('market-speed-10x')
              : remaining >= 3
              ? const Key('market-speed-3x')
              : const Key('market-speed-normal');
          for (final confirmKey in const <Key>[
            Key('market-breaking-news-confirm'),
            Key('market-session-notice-confirm'),
          ]) {
            final confirm = find.byKey(confirmKey);
            if (confirm.evaluate().isNotEmpty) {
              await tester.tap(confirm);
              await tester.pumpAndSettle();
            }
          }
          await tester.tap(find.byKey(speedKey).last);
          await tester.pump();
          await tester.pump(marketRealtimeTickDuration);
          await tester.pump();
          guard += 1;
          expect(guard, lessThan(80), reason: '14:49까지 시장 시간이 진행되어야 합니다.');
        }
        expect(displayedMinute(), krxContinuousEndMinute - 1);
        await tester.tap(find.byKey(const Key('market-speed-pause')).last);
        await tester.pump();

        if (!keepTargetOpen) {
          await tester.tap(find.byKey(const Key('stock-row-1001')));
          await tester.pumpAndSettle();
        }

        String metric(Key key) {
          final text = tester.widget<Text>(
            find.descendant(of: find.byKey(key), matching: find.byType(Text)),
          );
          return text.textSpan?.toPlainText() ?? text.data ?? '';
        }

        final result = <String, String>{
          'price': tester
              .widget<Text>(find.byKey(const Key('stock-detail-price')))
              .data!,
          'open': metric(const Key('order-book-open')),
          'high': metric(const Key('order-book-high')),
          'low': metric(const Key('order-book-low')),
        };
        await tester.tap(find.byKey(const Key('stock-detail-tab-chart')));
        await tester.pump();
        result['minuteCandles'] = tester
            .widget<Text>(find.byKey(const Key('chart-window-label')))
            .data!;
        await tester.tap(find.byKey(const Key('close-stock-detail')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('market-nav-account')));
        await tester.pump();
        result['valuation'] = tester
            .widget<Text>(find.byKey(const Key('market-account-total-assets')))
            .data!;
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        return result;
      }

      final openedAllDay = await runScenario(keepTargetOpen: true);
      final openedAtEnd = await runScenario(keepTargetOpen: false);
      final settledAllDay = Map<String, String>.of(openedAllDay)
        ..remove('price');
      final settledAtEnd = Map<String, String>.of(openedAtEnd)..remove('price');
      expect(settledAllDay, settledAtEnd);
      for (final result in [openedAllDay, openedAtEnd]) {
        final displayedPrice = int.parse(
          result['price']!.replaceAll(RegExp(r'[^0-9]'), ''),
        );
        expect(
          marketSnapPrice(displayedPrice.toDouble(), market: '미래시장'),
          displayedPrice,
          reason: '분내 마지막 미세 체결가도 유효 호가단위여야 합니다.',
        );
      }
    },
  );

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
    // The pending-order callback crosses an async persistence boundary. Flush
    // its zero-duration continuation before reading the rendered clock; under
    // a parallel full-suite load it need not complete in the same pump.
    await tester.pump();

    expect(synchronizedMinutes, [krxOpenMinute + 1]);
    expect(tester.widget<Text>(clock.first).data, contains('09:10'));
    expect(tester.widget<Text>(clock.first).data, isNot(before));
    expect(find.text('내 지정가 주문이 체결되어 시장 시간을 일시정지했어요.'), findsNothing);
    expect(find.byKey(const Key('order-book-pending-count')), findsNothing);
    final activeTradeRow = find.byKey(const Key('order-book-active-trade-row'));
    if (activeTradeRow.evaluate().isNotEmpty) {
      expect(
        _hasSynchronizedDisplayedOrderBookTrade(tester),
        isTrue,
        reason:
            '다음 분의 새 시장 체결행은 허용하지만 과거 플레이어 체결행을 '
            '현재 테이프와 무관하게 남기면 안 됩니다. '
            '${_displayedOrderBookTradeDebug(tester)}',
      );
    }

    await tester.pump(const Duration(seconds: 1));
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump();
      if (tester.widget<Text>(clock.first).data?.contains('09:20') ?? false) {
        break;
      }
    }
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
      allOf(contains('90개 캔들'), contains('전 거래일 포함')),
    );
    expect(find.textContaining('전일 '), findsWidgets);
    expect(find.text('개장 전 08:00'), findsOneWidget);

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

  testWidgets('pre-open chart renders previous-session candles', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = const GameEngine()
        .createNewGame('Pre-open Chart Regression', initialCash: 1000000)
        .copyWith(day: 4, marketMinute: marketDayStartMinute);
    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(state: state, universe: testMarketUniverse()),
      ),
    );
    await openMarketExplore(tester);
    await tester.ensureVisible(find.byKey(const Key('stock-row-1001')));
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('stock-detail-tab-chart')));
    await tester.pump();

    expect(find.byKey(const Key('minute-candle-chart')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('chart-window-label'))).data,
      allOf(contains('90개 캔들'), contains('전 거래일 포함')),
    );
    expect(find.textContaining('전일 '), findsWidgets);
    expect(find.text('개장 전 08:00'), findsOneWidget);
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
      await tester.pumpAndSettle();

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

      await tester.tap(
        find.byKey(const Key('request-state-account-order-approval')),
      );
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
    'counter-side order-book pulse keeps tape and red border on one row',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = const GameEngine()
          .createNewGame(
            '호가 반대 체결 행 테스트',
            initialCash: 1000000,
            worldSeed: 'counter-side-order-book-widget-test',
          )
          .copyWith(day: 4, marketMinute: 9 * 60);

      await tester.pumpWidget(
        MaterialApp(
          home: StockMarketScreen(state: state, universe: testMarketUniverse()),
        ),
      );
      await openMarketExplore(tester);
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();
      await tester.tap(find.byKey(const Key('stock-row-1001')));
      await tester.pumpAndSettle();

      final orderBook = find.byKey(const Key('stock-order-book'));
      final activeTradeRow = find.byKey(
        const Key('order-book-active-trade-row'),
      );
      final currentPriceBorder = find.byKey(
        const Key('order-book-current-price-border'),
      );
      expect(orderBook, findsOneWidget);
      expect(currentPriceBorder, findsOneWidget);

      final pulseNotifier = _orderBookPulseNotifier(tester);
      pulseNotifier.value = gameOrderBookLiquidityPulseFrame(
        marketMinute: 9 * 60,
        slotIndex: 0,
      );
      await tester.pump();
      expect(
        activeTradeRow,
        findsNothing,
        reason: '정지 상태로 연 최초 프레임은 가짜 체결을 만들면 안 됩니다.',
      );
      await tester.tap(find.byKey(const Key('market-speed-1x')).last);
      await tester.pump();
      late _DisplayedOrderBookTrade initialTrade;
      var foundInitialTrade = false;
      final firstCandidateFrame = pulseNotifier.value + 1;
      for (
        var frame = firstCandidateFrame;
        frame < firstCandidateFrame + 64;
        frame += 1
      ) {
        pulseNotifier.value = frame;
        await tester.pump();
        for (var playbackFrame = 0; playbackFrame < 24; playbackFrame += 1) {
          if (_hasSynchronizedDisplayedOrderBookTrade(tester)) {
            initialTrade = _displayedOrderBookTrade(tester);
            foundInitialTrade = true;
            break;
          }
          await tester.pump(const Duration(milliseconds: 160));
        }
        if (foundInitialTrade) break;
      }
      expect(
        foundInitialTrade,
        isTrue,
        reason:
            '64개 결정론적 슬롯 안에 테이프와 활성 행이 일치하는 첫 체결이 있어야 합니다. '
            '${_displayedOrderBookTradeDebug(tester)}',
      );
      expect(
        _displayedOrderBookNumber(
          tester,
          find.byKey(const Key('stock-detail-price')),
        ),
        initialTrade.price,
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
      _DisplayedOrderBookTrade? counterSideTrade;
      final firstCounterSideCandidateFrame = pulseNotifier.value + 1;

      for (
        var frame = firstCounterSideCandidateFrame;
        frame < firstCounterSideCandidateFrame + 64;
        frame += 1
      ) {
        pulseNotifier.value = frame;
        await tester.pump();
        for (var playbackFrame = 0; playbackFrame < 32; playbackFrame += 1) {
          if (activeTradeRow.evaluate().isNotEmpty &&
              _hasSynchronizedDisplayedOrderBookTrade(tester)) {
            final trade = _displayedOrderBookTrade(tester);
            if (trade.isBuy != initialTrade.isBuy) {
              counterSideTrade = trade;
              break;
            }
          }
          await tester.pump(const Duration(milliseconds: 160));
        }
        if (counterSideTrade != null) break;
      }
      expect(
        counterSideTrade,
        isNotNull,
        reason: '64개 결정론적 미세구조 펄스 안에 반대 방향 체결이 있어야 한다.',
      );

      expect(counterSideTrade!.price, greaterThan(0));
      final borderWidget = tester.widget(currentPriceBorder);
      expect(
        tester.getTopLeft(activeTradeRow).dy,
        closeTo(tester.getTopLeft(currentPriceBorder).dy, 0.1),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('order-book-current-price')),
          matching: activeTradeRow,
        ),
        findsOneWidget,
      );

      if (borderWidget is AnimatedPositioned) {
        expect(borderWidget.duration, const Duration(milliseconds: 144));
      }
      expect(
        find.descendant(
          of: orderBook,
          matching: find.byKey(const Key('order-book-price-rate')),
        ),
        findsNWidgets(stockOrderBookVisibleSideRows * 2),
      );
      final depthAnimations = tester
          .widgetList<TweenAnimationBuilder<double>>(
            find.descendant(
              of: orderBook,
              matching: find.byType(TweenAnimationBuilder<double>),
            ),
          )
          .where(
            (animation) =>
                !animation.key.toString().contains('order-book-sweep-drain'),
          )
          .toList(growable: false);
      expect(depthAnimations, hasLength(stockOrderBookVisibleSideRows * 2));
      expect(
        depthAnimations.every(
          (animation) =>
              animation.duration.inMilliseconds >= 56 &&
              animation.duration.inMilliseconds <= 144,
        ),
        isTrue,
      );

      expect(
        tester.getCenter(currentPriceBorder).dy,
        closeTo(tester.getCenter(activeTradeRow).dy, 0.1),
        reason: '벽이 감소하는 동안 빨간 테두리는 같은 체결행에 고정돼야 합니다.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('order-book ledger never re-admits a pending packet past its cap', () {
    final ledger = OrderBookSweepIdentityLedger(completedHistoryCapacity: 4);

    for (var index = 0; index < 600; index += 1) {
      expect(ledger.admit('packet-$index'), isTrue);
    }
    expect(
      ledger.admit('packet-0'),
      isFalse,
      reason: '완료 이력 용량과 무관하게 pending identity는 절대 다시 들어오면 안 됩니다.',
    );

    for (var index = 0; index < 600; index += 1) {
      ledger.complete('packet-$index');
    }
    expect(ledger.admit('packet-0'), isTrue);
    expect(ledger.admit('packet-599'), isFalse);
  });

  test('order-book sweep depth uses the visible-book scale', () {
    const step = GameOrderBookSweepStep(
      marketMinute: 540,
      liquidityPulse: 1,
      sequence: 0,
      side: GameOrderBookSide.ask,
      price: 13500,
      consumedQuantity: 20,
      remainingQuantity: 10,
      structuralBreach: false,
      boundaryCrossed: true,
    );

    final transition = orderBookSweepDepthTransition(step: step, maxDepth: 100);

    expect(transition.before, closeTo(0.30, 0.000001));
    expect(transition.after, closeTo(0.10, 0.000001));
    expect(transition.before, isNot(1.0));
  });

  test('order-book sweep keeps future walls and skips consumed zero rows', () {
    const rememberedAsk100 = GameOrderBookLevel(
      side: GameOrderBookSide.ask,
      price: 100,
      quantity: 50,
      isWall: true,
    );
    const rememberedAsk101 = GameOrderBookLevel(
      side: GameOrderBookSide.ask,
      price: 101,
      quantity: 40,
      isWall: true,
    );
    const finalAsk101 = GameOrderBookLevel(
      side: GameOrderBookSide.ask,
      price: 101,
      quantity: 20,
      isWall: false,
    );
    const finalAsk102 = GameOrderBookLevel(
      side: GameOrderBookSide.ask,
      price: 102,
      quantity: 30,
      isWall: false,
    );
    const promotedBid100 = GameOrderBookLevel(
      side: GameOrderBookSide.bid,
      price: 100,
      quantity: 70,
      isWall: true,
    );
    const bid99 = GameOrderBookLevel(
      side: GameOrderBookSide.bid,
      price: 99,
      quantity: 25,
      isWall: false,
    );
    const steps = <GameOrderBookSweepStep>[
      GameOrderBookSweepStep(
        marketMinute: 540,
        liquidityPulse: 1,
        sequence: 0,
        side: GameOrderBookSide.ask,
        price: 100,
        consumedQuantity: 50,
        remainingQuantity: 0,
        structuralBreach: true,
        boundaryCrossed: true,
      ),
      GameOrderBookSweepStep(
        marketMinute: 540,
        liquidityPulse: 1,
        sequence: 1,
        side: GameOrderBookSide.ask,
        price: 101,
        consumedQuantity: 20,
        remainingQuantity: 20,
        structuralBreach: false,
        boundaryCrossed: false,
      ),
    ];
    final snapshot = GameOrderBookSnapshot(
      asks: <GameOrderBookLevel>[finalAsk101, finalAsk102],
      bids: <GameOrderBookLevel>[promotedBid100, bid99],
      turnoverEok: 0,
      executionCapacity: 70,
      totalAskQuantity: 50,
      totalBidQuantity: 95,
      tradeStrength: 190,
      rememberedLevels: <double, GameOrderBookLevel>{
        100: rememberedAsk100,
        101: rememberedAsk101,
      },
      sweepSteps: steps,
    );

    GameOrderBookLevel levelAt(
      List<GameOrderBookLevel> levels,
      GameOrderBookSide side,
      double price,
    ) => levels.firstWhere(
      (level) => level.side == side && level.price == price,
    );

    final firstArriving = orderBookSweepPresentationLevels(
      snapshot: snapshot,
      steps: steps,
      activeStepIndex: 0,
      activeStepArrived: false,
      sideRowCount: 4,
    );
    expect(levelAt(firstArriving, GameOrderBookSide.ask, 100).quantity, 50);
    expect(levelAt(firstArriving, GameOrderBookSide.ask, 101).quantity, 40);
    expect(
      firstArriving.any(
        (level) => level.side == GameOrderBookSide.bid && level.price == 100,
      ),
      isFalse,
      reason: '체결 전에는 같은 가격의 반대편 신규 큐를 먼저 보여주면 안 됩니다.',
    );

    final firstDraining = orderBookSweepPresentationLevels(
      snapshot: snapshot,
      steps: steps,
      activeStepIndex: 0,
      activeStepArrived: true,
      sideRowCount: 4,
    );
    expect(
      firstDraining.any(
        (level) => level.side == GameOrderBookSide.ask && level.price == 100,
      ),
      isFalse,
      reason: '전량체결된 현재 행도 숫자 0으로 그리지 않고 즉시 다음 양수 호가로 넘어가야 합니다.',
    );
    expect(
      firstDraining.map((level) => level.quantity),
      everyElement(greaterThan(0)),
    );
    expect(levelAt(firstDraining, GameOrderBookSide.ask, 101).quantity, 40);

    final secondArriving = orderBookSweepPresentationLevels(
      snapshot: snapshot,
      steps: steps,
      activeStepIndex: 1,
      activeStepArrived: false,
      sideRowCount: 4,
    );
    expect(
      secondArriving.any(
        (level) => level.side == GameOrderBookSide.ask && level.price == 100,
      ),
      isFalse,
      reason: '지나간 0주 ghost는 다음 깊은 체결행의 10호가 슬롯을 가리면 안 됩니다.',
    );
    expect(levelAt(secondArriving, GameOrderBookSide.ask, 101).quantity, 40);

    final secondDraining = orderBookSweepPresentationLevels(
      snapshot: snapshot,
      steps: steps,
      activeStepIndex: 1,
      activeStepArrived: true,
      sideRowCount: 4,
    );
    expect(levelAt(secondDraining, GameOrderBookSide.ask, 101).quantity, 20);
  });

  test('repeated passive fills never make the same wall rebound', () {
    const externalBid = GameOrderBookLevel(
      side: GameOrderBookSide.bid,
      price: 100,
      quantity: 100,
      isWall: true,
    );
    const ask = GameOrderBookLevel(
      side: GameOrderBookSide.ask,
      price: 101,
      quantity: 80,
      isWall: false,
    );
    final snapshot = GameOrderBookSnapshot(
      asks: const <GameOrderBookLevel>[ask],
      bids: const <GameOrderBookLevel>[externalBid],
      turnoverEok: 0,
      executionCapacity: 100,
      totalAskQuantity: 80,
      totalBidQuantity: 100,
      tradeStrength: 125,
      rememberedLevels: const <double, GameOrderBookLevel>{},
    );
    const rawSteps = <GameOrderBookSweepStep>[
      GameOrderBookSweepStep(
        marketMinute: 540,
        liquidityPulse: 1,
        sequence: 0,
        side: GameOrderBookSide.bid,
        price: 100,
        consumedQuantity: 3,
        remainingQuantity: 100,
        structuralBreach: false,
        boundaryCrossed: false,
      ),
      GameOrderBookSweepStep(
        marketMinute: 540,
        liquidityPulse: 1,
        sequence: 1,
        side: GameOrderBookSide.bid,
        price: 100,
        consumedQuantity: 2,
        remainingQuantity: 100,
        structuralBreach: false,
        boundaryCrossed: false,
      ),
    ];
    final remaining = playerOwnedOrderBookRemainingQuantities(rawSteps);
    expect(remaining, <int>[102, 100]);
    final steps = <GameOrderBookSweepStep>[
      for (final entry in rawSteps.asMap().entries)
        GameOrderBookSweepStep(
          marketMinute: entry.value.marketMinute,
          liquidityPulse: entry.value.liquidityPulse,
          sequence: entry.key,
          side: entry.value.side,
          price: entry.value.price,
          consumedQuantity: entry.value.consumedQuantity,
          remainingQuantity: remaining[entry.key],
          structuralBreach: entry.value.structuralBreach,
          boundaryCrossed: entry.value.boundaryCrossed,
        ),
    ];

    int quantityAt(int stepIndex, {required bool arrived}) =>
        orderBookSweepPresentationLevels(
              snapshot: snapshot,
              steps: steps,
              activeStepIndex: stepIndex,
              activeStepArrived: arrived,
            )
            .singleWhere(
              (level) =>
                  level.side == GameOrderBookSide.bid && level.price == 100,
            )
            .quantity;

    expect(quantityAt(0, arrived: false), 105);
    expect(quantityAt(0, arrived: true), 102);
    expect(
      quantityAt(1, arrived: false),
      102,
      reason: '첫 passive drain 뒤 두 번째 border가 올 때 벽이 다시 커지면 안 됩니다.',
    );
    expect(quantityAt(1, arrived: true), 100);
  });
  test('deep sweep always keeps the current border row inside 10 quotes', () {
    final remembered = <double, GameOrderBookLevel>{
      for (var index = 0; index < 12; index += 1)
        (100 + index).toDouble(): GameOrderBookLevel(
          side: GameOrderBookSide.ask,
          price: (100 + index).toDouble(),
          quantity: 10,
          isWall: index == 11,
        ),
    };
    final steps = List<GameOrderBookSweepStep>.generate(
      12,
      (index) => GameOrderBookSweepStep(
        marketMinute: 540,
        liquidityPulse: 1,
        sequence: index,
        side: GameOrderBookSide.ask,
        price: (100 + index).toDouble(),
        consumedQuantity: 10,
        remainingQuantity: 0,
        structuralBreach: false,
        boundaryCrossed: true,
      ),
      growable: false,
    );
    final snapshot = GameOrderBookSnapshot(
      asks: const <GameOrderBookLevel>[
        GameOrderBookLevel(
          side: GameOrderBookSide.ask,
          price: 112,
          quantity: 20,
          isWall: false,
        ),
      ],
      bids: const <GameOrderBookLevel>[
        GameOrderBookLevel(
          side: GameOrderBookSide.bid,
          price: 111,
          quantity: 30,
          isWall: false,
        ),
        GameOrderBookLevel(
          side: GameOrderBookSide.bid,
          price: 99,
          quantity: 20,
          isWall: false,
        ),
      ],
      turnoverEok: 0,
      executionCapacity: 120,
      totalAskQuantity: 20,
      totalBidQuantity: 50,
      tradeStrength: 250,
      rememberedLevels: remembered,
      sweepSteps: steps,
    );

    final arriving = orderBookSweepPresentationLevels(
      snapshot: snapshot,
      steps: steps,
      activeStepIndex: 11,
      activeStepArrived: false,
      sideRowCount: 10,
    );
    final active = arriving.singleWhere(
      (level) => level.side == GameOrderBookSide.ask && level.price == 111,
    );
    expect(active.quantity, 10);
    expect(
      arriving.any(
        (level) => level.side == GameOrderBookSide.ask && level.price < 111,
      ),
      isFalse,
      reason: '완료된 0주 ghost가 현재 12번째 체결행을 10호가 밖으로 밀면 안 됩니다.',
    );
  });

  test('order-book hides cancellation deltas but keeps actual flow labels', () {
    expect(orderBookQuantityDeltaLabel(-125, isTrade: false), isEmpty);
    expect(orderBookQuantityDeltaLabel(-125, isTrade: true), '-125');
    expect(orderBookQuantityDeltaLabel(125, isTrade: false), '+125');
  });

  test('empty cancellation packet keeps the previous ladder visible', () {
    const ask = GameOrderBookLevel(
      side: GameOrderBookSide.ask,
      price: 101,
      quantity: 80,
      isWall: false,
    );
    const bid = GameOrderBookLevel(
      side: GameOrderBookSide.bid,
      price: 100,
      quantity: 90,
      isWall: false,
    );
    final previous = GameOrderBookSnapshot(
      asks: const <GameOrderBookLevel>[ask],
      bids: const <GameOrderBookLevel>[bid],
      turnoverEok: 0,
      executionCapacity: 0,
      totalAskQuantity: 80,
      totalBidQuantity: 90,
      tradeStrength: 100,
    );
    const cancellationPacket = GameOrderBookSnapshot(
      asks: <GameOrderBookLevel>[],
      bids: <GameOrderBookLevel>[],
      turnoverEok: 0,
      executionCapacity: 0,
      totalAskQuantity: 0,
      totalBidQuantity: 0,
      tradeStrength: 100,
    );

    final levels = stableOrderBookPresentationLevels(
      snapshot: cancellationPacket,
      fallbackSnapshot: previous,
    );

    expect(levels, hasLength(2));
    expect(levels.map((level) => level.price), <double>[101, 100]);
  });

  test('fully removed depth is a cancellation unless a trade reached it', () {
    const wall = GameOrderBookLevel(
      side: GameOrderBookSide.ask,
      price: 100,
      quantity: 125,
      isWall: true,
    );
    const cancelledWall = GameOrderBookLevel(
      side: GameOrderBookSide.ask,
      price: 100,
      quantity: 0,
      isWall: false,
    );
    const bid = GameOrderBookLevel(
      side: GameOrderBookSide.bid,
      price: 99,
      quantity: 80,
      isWall: false,
    );
    final previous = GameOrderBookSnapshot(
      asks: <GameOrderBookLevel>[wall],
      bids: <GameOrderBookLevel>[bid],
      turnoverEok: 0,
      executionCapacity: 100,
      totalAskQuantity: 125,
      totalBidQuantity: 80,
      tradeStrength: 64,
      rememberedLevels: <double, GameOrderBookLevel>{100: wall, 99: bid},
      sourceAssetId: 'cancel-test',
      sourceDateKey: '2000-01-04',
    );
    final next = GameOrderBookSnapshot(
      asks: <GameOrderBookLevel>[],
      bids: <GameOrderBookLevel>[bid],
      turnoverEok: 0,
      executionCapacity: 100,
      totalAskQuantity: 0,
      totalBidQuantity: 80,
      tradeStrength: 240,
      rememberedLevels: <double, GameOrderBookLevel>{
        100: cancelledWall,
        99: bid,
      },
      sourceAssetId: 'cancel-test',
      sourceDateKey: '2000-01-04',
    );

    expect(
      orderBookCancellationNotices(previous: previous, next: next),
      const <OrderBookCancellationNotice>[
        (side: GameOrderBookSide.ask, price: 100, quantity: 125),
      ],
    );

    const tradeStep = GameOrderBookSweepStep(
      marketMinute: 540,
      liquidityPulse: 1,
      sequence: 0,
      side: GameOrderBookSide.ask,
      price: 100,
      consumedQuantity: 125,
      remainingQuantity: 0,
      structuralBreach: true,
      boundaryCrossed: true,
    );
    expect(
      orderBookCancellationNotices(
        previous: previous,
        next: next,
        tradeSteps: const <GameOrderBookSweepStep>[tradeStep],
      ),
      isEmpty,
      reason: '테두리가 도착한 실제 전량 체결은 취소 문구로 위장하면 안 됩니다.',
    );

    final offscreen = GameOrderBookSnapshot(
      asks: <GameOrderBookLevel>[],
      bids: <GameOrderBookLevel>[bid],
      turnoverEok: 0,
      executionCapacity: 100,
      totalAskQuantity: 0,
      totalBidQuantity: 80,
      tradeStrength: 240,
      rememberedLevels: <double, GameOrderBookLevel>{100: wall, 99: bid},
      sourceAssetId: 'cancel-test',
      sourceDateKey: '2000-01-04',
    );
    expect(
      orderBookCancellationNotices(previous: previous, next: offscreen),
      isEmpty,
      reason: '수량이 그대로인 채 10호가 밖으로 이동한 행은 취소가 아닙니다.',
    );
  });

  test(
    'same-price trade from another packet cannot hide the current cancellation',
    () {
      const wall = GameOrderBookLevel(
        side: GameOrderBookSide.bid,
        price: 100,
        quantity: 125,
        isWall: true,
      );
      const cancelledWall = GameOrderBookLevel(
        side: GameOrderBookSide.bid,
        price: 100,
        quantity: 0,
        isWall: false,
      );
      const ask = GameOrderBookLevel(
        side: GameOrderBookSide.ask,
        price: 101,
        quantity: 80,
        isWall: false,
      );
      final previous = GameOrderBookSnapshot(
        asks: const <GameOrderBookLevel>[ask],
        bids: const <GameOrderBookLevel>[wall],
        turnoverEok: 0,
        executionCapacity: 125,
        totalAskQuantity: 80,
        totalBidQuantity: 125,
        tradeStrength: 80,
        rememberedLevels: <double, GameOrderBookLevel>{101: ask, 100: wall},
        sourceAssetId: 'packet-cancel-test',
        sourceDateKey: '2000-01-04',
        sourceMarketMinute: 541,
        liquidityPulse: 1,
      );
      final next = GameOrderBookSnapshot(
        asks: const <GameOrderBookLevel>[ask],
        bids: const <GameOrderBookLevel>[],
        turnoverEok: 0,
        executionCapacity: 125,
        totalAskQuantity: 80,
        totalBidQuantity: 0,
        tradeStrength: 80,
        rememberedLevels: <double, GameOrderBookLevel>{
          101: ask,
          100: cancelledWall,
        },
        sourceAssetId: 'packet-cancel-test',
        sourceDateKey: '2000-01-04',
        sourceMarketMinute: 541,
        liquidityPulse: 2,
      );
      const olderPacketTrade = GameOrderBookSweepStep(
        marketMinute: 540,
        liquidityPulse: 9,
        sequence: 0,
        side: GameOrderBookSide.bid,
        price: 100,
        consumedQuantity: 125,
        remainingQuantity: 0,
        structuralBreach: true,
        boundaryCrossed: true,
      );

      expect(
        orderBookCancellationNotices(
          previous: previous,
          next: next,
          tradeSteps: const <GameOrderBookSweepStep>[olderPacketTrade],
          transitionMarketMinute: 541,
          transitionLiquidityPulse: 2,
        ),
        const <OrderBookCancellationNotice>[
          (side: GameOrderBookSide.bid, price: 100, quantity: 125),
        ],
        reason: '다른 minute/frame의 같은 가격 체결이 현재 전량 취소를 가리면 안 됩니다.',
      );

      const currentPartialTrade = GameOrderBookSweepStep(
        marketMinute: 541,
        liquidityPulse: 2,
        sequence: 0,
        side: GameOrderBookSide.bid,
        price: 100,
        consumedQuantity: 25,
        remainingQuantity: 0,
        structuralBreach: false,
        boundaryCrossed: false,
      );
      expect(
        orderBookCancellationNotices(
          previous: previous,
          next: next,
          tradeSteps: const <GameOrderBookSweepStep>[
            olderPacketTrade,
            currentPartialTrade,
          ],
          transitionMarketMinute: 541,
          transitionLiquidityPulse: 2,
        ),
        const <OrderBookCancellationNotice>[
          (side: GameOrderBookSide.bid, price: 100, quantity: 100),
        ],
        reason: '현재 전환의 실제 25주 체결만 빼고 나머지 100주는 취소여야 합니다.',
      );

      const currentFullTrade = GameOrderBookSweepStep(
        marketMinute: 541,
        liquidityPulse: 2,
        sequence: 1,
        side: GameOrderBookSide.bid,
        price: 100,
        consumedQuantity: 100,
        remainingQuantity: 0,
        structuralBreach: true,
        boundaryCrossed: true,
      );
      expect(
        orderBookCancellationNotices(
          previous: previous,
          next: next,
          tradeSteps: const <GameOrderBookSweepStep>[
            olderPacketTrade,
            currentPartialTrade,
            currentFullTrade,
          ],
          transitionMarketMinute: 541,
          transitionLiquidityPulse: 2,
        ),
        isEmpty,
        reason: '현재 전환에서 실제로 전량 체결됐으면 취소 문구가 나오면 안 됩니다.',
      );
    },
  );

  test('future zero-row cancellation waits for its own FIFO transition', () {
    const activeWall = GameOrderBookLevel(
      side: GameOrderBookSide.ask,
      price: 100,
      quantity: 50,
      isWall: true,
    );
    const futureCancelledWall = GameOrderBookLevel(
      side: GameOrderBookSide.ask,
      price: 101,
      quantity: 200,
      isWall: true,
    );
    const bid = GameOrderBookLevel(
      side: GameOrderBookSide.bid,
      price: 99,
      quantity: 80,
      isWall: false,
    );
    final beforeActivePacket = GameOrderBookSnapshot(
      asks: const <GameOrderBookLevel>[activeWall, futureCancelledWall],
      bids: const <GameOrderBookLevel>[bid],
      turnoverEok: 0,
      executionCapacity: 50,
      totalAskQuantity: 250,
      totalBidQuantity: 80,
      tradeStrength: 100,
      rememberedLevels: <double, GameOrderBookLevel>{
        100: activeWall,
        101: futureCancelledWall,
        99: bid,
      },
      sourceAssetId: 'cancel-fifo-test',
      sourceDateKey: '2000-01-04',
      sourceMarketMinute: 540,
      liquidityPulse: 1,
    );
    const activeStep = GameOrderBookSweepStep(
      marketMinute: 540,
      liquidityPulse: 1,
      sequence: 0,
      side: GameOrderBookSide.ask,
      price: 100,
      consumedQuantity: 50,
      remainingQuantity: 0,
      structuralBreach: true,
      boundaryCrossed: true,
    );
    final activePacket = GameOrderBookSnapshot(
      asks: const <GameOrderBookLevel>[futureCancelledWall],
      bids: const <GameOrderBookLevel>[bid],
      turnoverEok: 0,
      executionCapacity: 50,
      totalAskQuantity: 200,
      totalBidQuantity: 80,
      tradeStrength: 100,
      rememberedLevels: <double, GameOrderBookLevel>{
        100: activeWall,
        101: futureCancelledWall,
        99: bid,
      },
      sweepSteps: const <GameOrderBookSweepStep>[activeStep],
      sourceAssetId: 'cancel-fifo-test',
      sourceDateKey: '2000-01-04',
      sourceMarketMinute: 540,
      liquidityPulse: 1,
    );

    for (final arrived in const <bool>[false, true]) {
      final levels = orderBookSweepPresentationLevels(
        snapshot: activePacket,
        previousSnapshot: beforeActivePacket,
        steps: const <GameOrderBookSweepStep>[activeStep],
        activeStepIndex: 0,
        activeStepArrived: arrived,
      );
      expect(
        levels
            .singleWhere(
              (level) =>
                  level.side == GameOrderBookSide.ask && level.price == 101,
            )
            .quantity,
        200,
        reason: '뒤 패킷의 0행 취소는 앞 패킷 arrival/drain 동안 먼저 반영되면 안 됩니다.',
      );
    }

    const cancelledFutureWall = GameOrderBookLevel(
      side: GameOrderBookSide.ask,
      price: 101,
      quantity: 0,
      isWall: false,
    );
    final futurePacket = GameOrderBookSnapshot(
      asks: const <GameOrderBookLevel>[],
      bids: const <GameOrderBookLevel>[bid],
      turnoverEok: 0,
      executionCapacity: 50,
      totalAskQuantity: 0,
      totalBidQuantity: 80,
      tradeStrength: 100,
      rememberedLevels: <double, GameOrderBookLevel>{
        101: cancelledFutureWall,
        99: bid,
      },
      sourceAssetId: 'cancel-fifo-test',
      sourceDateKey: '2000-01-04',
      sourceMarketMinute: 540,
      liquidityPulse: 2,
    );
    expect(
      orderBookCancellationNotices(
        previous: activePacket,
        next: futurePacket,
        transitionMarketMinute: 540,
        transitionLiquidityPulse: 2,
      ),
      const <OrderBookCancellationNotice>[
        (side: GameOrderBookSide.ask, price: 101, quantity: 200),
      ],
      reason: '앞 패킷 이후 자기 FIFO 전환에 도달했을 때만 0행 전량 취소가 생성돼야 합니다.',
    );
  });

  testWidgets('order-book sweep status stays in the blank side cell', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = const GameEngine()
        .createNewGame(
          '호가 소진 흰칸 배치 테스트',
          initialCash: 1000000,
          worldSeed: 'stock-market-test-v1',
        )
        .copyWith(day: 4, marketMinute: 9 * 60);

    await tester.pumpWidget(
      MaterialApp(
        home: StockMarketScreen(state: state, universe: testMarketUniverse()),
      ),
    );
    await openMarketExplore(tester);
    await tester.tap(find.byKey(const Key('stock-row-1001')));
    await tester.pumpAndSettle();

    final orderBook = find.byKey(const Key('stock-order-book'));
    final statusCell = find.byKey(const Key('order-book-sweep-status-cell'));
    final currentPriceBorder = find.byKey(
      const Key('order-book-current-price-border'),
    );
    expect(orderBook, findsOneWidget);
    expect(currentPriceBorder, findsOneWidget);

    var foundSweep = false;
    Tween<double>? sweepDepthTween;
    for (var minuteOffset = 0; minuteOffset < 45; minuteOffset += 1) {
      await tester.pump(const Duration(seconds: 1));
      if (statusCell.evaluate().isNotEmpty) {
        final drainAnimation = find.descendant(
          of: orderBook,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is TweenAnimationBuilder<double> &&
                widget.key.toString().contains('order-book-sweep-drain'),
          ),
        );
        if (drainAnimation.evaluate().length == 1) {
          final tween = tester
              .widget<TweenAnimationBuilder<double>>(drainAnimation)
              .tween;
          foundSweep = true;
          sweepDepthTween = tween;
          break;
        }
      }
    }
    expect(foundSweep, isTrue, reason: '결정론적 분 전이 안에 실제 경계 통과 표시가 있어야 합니다.');

    final statusRect = tester.getRect(statusCell);
    final borderRect = tester.getRect(currentPriceBorder);
    expect(statusRect.width, closeTo(124, 0.1));
    expect(
      statusRect.right <= borderRect.left + 0.1 ||
          statusRect.left >= borderRect.right - 0.1,
      isTrue,
      reason: '소진 문구는 중앙 가격·빨간 테두리가 아닌 반대편 흰 칸에 있어야 합니다.',
    );
    expect(
      find.descendant(of: statusCell, matching: find.byType(Text)),
      findsOneWidget,
    );
    expect(sweepDepthTween, isNotNull);
    expect(sweepDepthTween!.begin, inInclusiveRange(0.0, 1.0));
    expect(sweepDepthTween.end, inInclusiveRange(0.0, 1.0));
    expect(sweepDepthTween.begin!, greaterThanOrEqualTo(sweepDepthTween.end!));

    final sweepRect = tester.getRect(
      find.byKey(const Key('order-book-sweep-step')),
    );
    expect(
      tester.getCenter(currentPriceBorder).dy,
      closeTo(sweepRect.center.dy, 0.1),
      reason: '벽 소진 오버레이가 나타날 때는 빨간 테두리가 해당 가격행에 먼저 도착해야 합니다.',
    );
    final isAskSweep = statusRect.left >= borderRect.right - 0.1;
    final baseDepthBars = find.descendant(
      of: orderBook,
      matching: find.byKey(
        ValueKey(
          isAskSweep ? 'order-book-sell-depth-bar' : 'order-book-buy-depth-bar',
        ),
      ),
    );
    FractionallySizedBox? targetDepthBar;
    for (var index = 0; index < baseDepthBars.evaluate().length; index += 1) {
      final candidate = baseDepthBars.at(index);
      if ((tester.getRect(candidate).center.dy - sweepRect.center.dy).abs() <
          0.1) {
        targetDepthBar = tester.widget<FractionallySizedBox>(candidate);
        break;
      }
    }
    if (targetDepthBar == null) {
      expect(
        sweepDepthTween.end,
        inInclusiveRange(0.0, 1.0),
        reason: '재생 중 ghost 행의 종료 폭도 실제 주문장 깊이 범위를 벗어나면 안 됩니다.',
      );
    } else {
      expect(
        sweepDepthTween.end,
        closeTo(targetDepthBar.widthFactor!, 0.000001),
        reason: 'sweep 종료 폭은 사라진 뒤 드러나는 실제 호가 잔량 폭과 같아야 합니다.',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('10x keeps FIFO replay current and pause freezes the ladder', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = const GameEngine()
        .createNewGame(
          '10배속 호가 FIFO',
          initialCash: 1000000,
          worldSeed: 'stock-market-test-v1',
        )
        .copyWith(day: 4, marketMinute: krxOpenMinute);

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

    ({String identity, int sequence, String phase})? activeVisit() {
      final finder = find.byWidgetPredicate((widget) {
        final key = widget.key;
        if (key is! ValueKey) return false;
        final value = key.value;
        if (value is! Record) return false;
        final dynamic record = value;
        return record.$1 == 'order-book-sweep-active' && record.$5 == 'full';
      }, skipOffstage: false);
      final elements = finder.evaluate().toList(growable: false);
      if (elements.isEmpty) return null;
      expect(elements, hasLength(1));
      final dynamic record = (elements.single.widget.key! as ValueKey).value;
      return (
        identity: record.$2 as String,
        sequence: record.$3 as int,
        phase: record.$4 as String,
      );
    }

    final drainedRows = <({String identity, int sequence, double centerY})>[];

    void captureVisit(
      List<({String identity, int sequence, String phase})> visits,
    ) {
      final visit = activeVisit();
      if (visit == null || (visits.isNotEmpty && visits.last == visit)) return;
      visits.add(visit);
      final position = find.byKey(const Key('order-book-sweep-position'));
      final border = find.byKey(const Key('order-book-current-price-border'));
      if (visit.phase == 'arriving') {
        expect(
          position,
          findsNothing,
          reason: '테두리가 이동 중일 때 벽 소진 오버레이가 먼저 보이면 안 됩니다.',
        );
        return;
      }
      expect(visit.phase, 'draining');
      expect(position, findsOneWidget);
      expect(border, findsOneWidget);
      expect(
        tester.getCenter(border).dy,
        closeTo(tester.getCenter(position).dy, 1.1),
        reason: '10배속 drain도 테두리가 정확한 체결행에 도착한 뒤에만 보여야 합니다.',
      );
      final drainedRow = (
        identity: visit.identity,
        sequence: visit.sequence,
        centerY: tester.getCenter(border).dy,
      );
      if (drainedRows.isEmpty ||
          drainedRows.last.identity != drainedRow.identity ||
          drainedRows.last.sequence != drainedRow.sequence) {
        if (drainedRows.isNotEmpty) {
          final firstAsk = find.byKey(const ValueKey('order-book-ask-0'));
          final secondAsk = find.byKey(const ValueKey('order-book-ask-1'));
          final rowHeight =
              (tester.getCenter(firstAsk).dy - tester.getCenter(secondAsk).dy)
                  .abs();
          expect(
            (drainedRow.centerY - drainedRows.last.centerY).abs(),
            lessThanOrEqualTo(rowHeight + 0.2),
            reason: '연속 체결 테두리는 호가 한 칸씩만 이동해야 합니다.',
          );
        }
        drainedRows.add(drainedRow);
      }
    }

    final visits = <({String identity, int sequence, String phase})>[];
    await tester.tap(find.byKey(const Key('market-speed-10x')).last);
    await tester.pump(marketRealtimeTickDuration);
    for (var frame = 0; frame < 24; frame += 1) {
      await tester.pump(const Duration(milliseconds: 5));
      for (final confirmationKey in const <Key>[
        Key('market-breaking-news-confirm'),
        Key('market-session-notice-confirm'),
      ]) {
        final confirmation = find.byKey(confirmationKey);
        if (confirmation.evaluate().isNotEmpty) {
          await tester.tap(confirmation);
          await tester.pump();
        }
      }
      captureVisit(visits);
      if (activeVisit() != null) break;
    }
    expect(
      activeVisit(),
      isNotNull,
      reason: '10배속 체결 재생 도중 정지 동작을 검증할 활성 단계가 있어야 합니다.',
    );
    await tester.tap(find.byKey(const Key('market-speed-pause')).last);
    await tester.pump();
    final frozenVisit = activeVisit();
    final frozenQuantities = _displayedOrderBookQuantities(tester);
    final frozenBorderTop = (tester.widget<AnimatedPositioned>(
      find.byKey(const Key('order-book-current-price-border')),
    )).top;
    await tester.pump(const Duration(seconds: 3));
    expect(activeVisit(), frozenVisit);
    expect(_displayedOrderBookQuantities(tester), frozenQuantities);
    expect(
      (tester.widget<AnimatedPositioned>(
        find.byKey(const Key('order-book-current-price-border')),
      )).top,
      frozenBorderTop,
      reason: '정지 중에는 대기 중인 FIFO가 남아 있어도 호가 테두리가 움직이면 안 됩니다.',
    );

    await tester.tap(find.byKey(const Key('market-speed-10x')).last);
    for (var frame = 0; frame < 160; frame += 1) {
      await tester.pump(const Duration(milliseconds: 5));
      captureVisit(visits);
    }
    await tester.tap(find.byKey(const Key('market-speed-pause')).last);
    await tester.pump();

    final marketVisits = visits
        .where((visit) => visit.identity.startsWith('market:'))
        .toList(growable: false);
    final batchOrder = <String>[];
    for (final visit in marketVisits) {
      if (batchOrder.isEmpty || batchOrder.last != visit.identity) {
        batchOrder.add(visit.identity);
      }
    }
    expect(
      batchOrder.length,
      greaterThanOrEqualTo(2),
      reason: '10분씩 건너뛴 중간 체결 배치도 두 개 이상 FIFO에 남아야 합니다.',
    );
    expect(
      batchOrder.toSet().length,
      batchOrder.length,
      reason: '완료한 batch가 뒤에서 다시 나타나면 FIFO 순서가 아닙니다.',
    );

    final phasesByStep = <(String, int), List<String>>{};
    for (final visit in marketVisits) {
      phasesByStep
          .putIfAbsent((visit.identity, visit.sequence), () => <String>[])
          .add(visit.phase);
    }
    expect(drainedRows.length, greaterThanOrEqualTo(2));
    for (final entry in phasesByStep.entries) {
      final drains = entry.value.where((phase) => phase == 'draining');
      expect(drains.length, lessThanOrEqualTo(1));
      expect(
        entry.value.where((phase) => phase == 'arriving').length,
        lessThanOrEqualTo(1),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'trade print consumes its absolute-price row without same-frame replenishment',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = const GameEngine()
          .createNewGame(
            '체결 잔량 차감 회귀 테스트',
            initialCash: 1000000,
            worldSeed: 'trade-depth-consumption-widget-test',
          )
          .copyWith(day: 4, marketMinute: 9 * 60);

      await tester.pumpWidget(
        MaterialApp(
          home: StockMarketScreen(state: state, universe: testMarketUniverse()),
        ),
      );
      await openMarketExplore(tester);
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();
      await tester.tap(find.byKey(const Key('stock-row-1001')));
      await tester.pumpAndSettle();
      await _finishOrderBookSweepPlayback(tester);

      final pulseNotifier = _orderBookPulseNotifier(tester);
      final before = _displayedOrderBookQuantities(tester);
      pulseNotifier.value += 1;
      await tester.pump();
      expect(
        _displayedOrderBookQuantities(tester),
        before,
        reason: '정지 중 늦게 도착한 호가 패킷도 화면 숫자를 바꾸면 안 됩니다.',
      );
      expect(
        find.byKey(const Key('order-book-trade-tape-empty')),
        findsOneWidget,
        reason: 'packet ingest 첫 프레임에는 아직 도착하지 않은 미래 체결을 먼저 노출하면 안 됩니다.',
      );
      expect(
        find.byKey(const Key('order-book-tape-quantity-side')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('order-book-active-trade-row')),
        findsNothing,
        reason: 'arrival 중에는 체결 완료 행을 먼저 표시하면 안 됩니다.',
      );
      expect(
        tester.widget<Widget>(
          find.byKey(const Key('order-book-current-price-border')),
        ),
        isA<AnimatedPositioned>(),
      );
      await tester.tap(find.byKey(const Key('market-speed-1x')).last);
      await tester.pump();
      var foundSynchronizedDrain = false;
      for (var frame = 0; frame < 80; frame += 1) {
        await tester.pump(const Duration(milliseconds: 40));
        if (_hasSynchronizedDisplayedOrderBookTrade(tester)) {
          foundSynchronizedDrain = true;
          break;
        }
      }
      expect(
        foundSynchronizedDrain,
        isTrue,
        reason:
            'cancellation/arrival 표현 뒤 실제 drain 프레임에는 tape와 active row가 '
            '같은 행에 동시에 나타나야 합니다.',
      );

      final trade = _displayedOrderBookTrade(tester);
      final beforeQuantity = before[trade.price];
      expect(
        beforeQuantity,
        isNotNull,
        reason: '체결 문구가 붙은 절대가격은 직전 프레임의 7+7 호가에도 있어야 합니다.',
      );
      expect(find.byKey(const Key('order-book-trade-tape')), findsOneWidget);
      expect(
        find.byKey(const Key('order-book-trade-tape-empty')),
        findsNothing,
      );
      final expectedRemaining = math.max(
        0,
        beforeQuantity! - trade.printedQuantity,
      );
      final expectedDisplayedRemaining =
          expectedRemaining >= gameOrderBookMinimumDisplayedQuantity
          ? expectedRemaining
          : 0;
      expect(
        _displayedOrderBookQuantities(
          tester,
        ).values.every((quantity) => quantity > 0),
        isTrue,
        reason: '운영 호가창은 소진된 숫자 0 행을 노출하면 안 됩니다.',
      );
      // Match the original trade side. A fully consumed ask may legally create
      // a fresh bid at the same absolute price; that opposite queue is not a
      // replenished ask and must not be compared with the pre-trade ask.
      final displayedAfter = trade.isVisible ? trade.displayedQuantity : null;
      if (displayedAfter != null) {
        expect(
          displayedAfter,
          greaterThanOrEqualTo(gameOrderBookMinimumDisplayedQuantity),
        );
        expect(
          displayedAfter,
          lessThanOrEqualTo(expectedRemaining),
          reason:
              '${trade.isBuy ? '매수' : '매도'} 체결 ${trade.printedQuantity}주는 '
              '${trade.price}원 행을 최소 그 수량만큼 줄여야 하며, 같은 프레임의 '
              '유입으로 다시 채워지면 안 됩니다.',
        );
        expect(
          trade.isVisible,
          isTrue,
          reason:
              'price=${trade.price}, before=$beforeQuantity, '
              'print=${trade.printedQuantity}, '
              'isBuy=${trade.isBuy}, '
              'expected=$expectedDisplayedRemaining, '
              'visible=${_displayedOrderBookQuantities(tester)}',
        );
        expect(
          trade.displayedQuantity,
          displayedAfter,
          reason: '체결 활성 행은 테이프 가격과 같은 방향의 현재 잔량이어야 합니다.',
        );
      } else {
        expect(trade.isVisible, isFalse);
        expect(trade.displayedQuantity, 0);
      }
      await tester.tap(find.byKey(const Key('stock-detail-tab-chart')));
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(
          const Key('order-book-tape-cursor-clear'),
          skipOffstage: false,
        ),
        findsOneWidget,
        reason: 'full ladder dispose는 자신이 발행한 shared tape cursor를 남기면 안 됩니다.',
      );
      await tester.tap(find.byKey(const Key('stock-detail-tab-quote')));
      await tester.pump();
      expect(
        tester.widget<Widget>(
          find.byKey(const Key('order-book-current-price-border')),
        ),
        isA<AnimatedPositioned>(),
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
      await tester.pumpAndSettle();

      final compactBorder = find.byKey(
        const Key('inline-order-book-current-price-border'),
      );
      expect(compactBorder, findsOneWidget);
      expect(tester.widget<Widget>(compactBorder), isA<AnimatedPositioned>());

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
          reason: '선택 가격 $price 행이 compact 7+7 호가에 하나 있어야 합니다.',
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

      final rowsByPrice = <int, String>{
        for (final row in inlineRows())
          int.parse(rowPrice(row).replaceAll(',', '')): rowPrice(row),
      };
      final displayedPrices = rowsByPrice.keys.toSet();
      (int, int)? adjacentPair;
      for (final price in displayedPrices) {
        final nextPrice = marketSnapPrice(
          price.toDouble() +
              marketTickSize(price.toDouble(), market: fictionalMainMarket),
          market: fictionalMainMarket,
        ).round();
        if (displayedPrices.contains(nextPrice)) {
          adjacentPair = (price, nextPrice);
          break;
        }
      }
      expect(
        adjacentPair,
        isNotNull,
        reason: 'compact 7+7에는 +/- 버튼 선택 이동을 검증할 인접 호가가 있어야 합니다.',
      );

      final pair = adjacentPair!;
      final initialPrice = rowsByPrice[pair.$1]!;
      await tester.tap(rowAtPrice(initialPrice));
      await tester.pump();
      expect(selectedLimitPrice(), initialPrice);
      final initiallySelectedRow = rowAtPrice(initialPrice);
      expect(rowMaterialAlpha(initiallySelectedRow), closeTo(0.90, 0.01));

      await tester.tap(find.byKey(const Key('limit-price-plus')));
      await tester.pump();

      final raisedPrice = rowsByPrice[pair.$2]!;
      expect(selectedLimitPrice(), raisedPrice);
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
    'multi-level full fill keeps exact tape without a zero quote row',
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
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();
      await tester.tap(find.byKey(const Key('stock-row-1001')));
      await tester.pumpAndSettle();
      final activeSweep = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey &&
            (widget.key! as ValueKey).value is Record &&
            ((widget.key! as ValueKey).value as dynamic).$1 ==
                'order-book-sweep-active',
        skipOffstage: false,
      );
      for (var wait = 0; wait < 80; wait += 1) {
        if (activeSweep.evaluate().isEmpty) break;
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(
        activeSweep,
        findsNothing,
        reason: '수동 주문을 넣기 전 자동 체결 FIFO가 끝나야 플레이어 두 벽의 시작량을 고정할 수 있습니다.',
      );

      await tester.tap(find.byKey(const Key('market-speed-10x')).last);
      await tester.pump();
      var sawInitialSweep = false;
      var emptyInitialSweepFrames = 0;
      for (var frame = 0; frame < 45; frame += 1) {
        await tester.pump(const Duration(milliseconds: 20));
        if (activeSweep.evaluate().isEmpty) {
          if (sawInitialSweep) emptyInitialSweepFrames += 1;
          if (emptyInitialSweepFrames >= 3) break;
        } else {
          sawInitialSweep = true;
          emptyInitialSweepFrames = 0;
        }
      }
      expect(activeSweep, findsNothing);
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();

      final positiveAskRows = <({int price, int quantity})>[];
      for (var index = 0; index < stockOrderBookVisibleSideRows; index += 1) {
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
      await tester.pumpAndSettle();
      await tester.tap(find.text('시장가'));
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('request-state-account-order-approval')),
      );
      await tester.pump();
      expect(submittedOrder, isNotNull);

      await tester.tap(find.byKey(const Key('stock-detail-tab-quote')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('market-speed-1x')).last);
      await tester.pump();

      expect(
        find.byKey(const Key('order-book-player-tape-print')),
        findsNothing,
        reason: '플레이어 체결도 첫 가격 테두리가 도착하기 전에는 테이프에 먼저 나오면 안 됩니다.',
      );

      Finder askRowFinderAtPrice(int price) {
        for (var index = 0; index < stockOrderBookVisibleSideRows; index += 1) {
          final row = find.byKey(ValueKey('order-book-ask-$index'));
          final label = find.descendant(
            of: row,
            matching: find.byKey(const ValueKey('order-book-price-label')),
          );
          if (label.evaluate().isNotEmpty &&
              _displayedOrderBookNumber(tester, label.first) == price) {
            return row;
          }
        }
        return find.byKey(ValueKey('missing-order-book-ask-$price'));
      }

      Finder askRowAtPrice(int price) {
        final row = askRowFinderAtPrice(price);
        if (row.evaluate().isEmpty) {
          fail('매도호가 $price 행이 순차 체결 재생 중 보여야 합니다.');
        }
        return row;
      }

      int askQuantityAtPrice(int price) {
        final row = askRowAtPrice(price);
        return _displayedOrderBookNumber(
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
      }

      late _DisplayedOrderBookTrade playerTrade;
      final border = find.byKey(const Key('order-book-current-price-border'));
      expect(tester.widget<Widget>(border), isA<AnimatedPositioned>());
      expect(askQuantityAtPrice(firstPrice), firstQuantity);
      expect(askQuantityAtPrice(lastPrice), lastQuantity);

      await tester.pump(const Duration(milliseconds: 72));
      expect(
        askQuantityAtPrice(firstPrice),
        firstQuantity,
        reason: '첫 가격 테두리가 이동 중일 때 첫 벽이 먼저 줄면 안 됩니다.',
      );
      expect(askQuantityAtPrice(lastPrice), lastQuantity);

      final firstTargetTop = tester.getCenter(askRowAtPrice(firstPrice)).dy;
      await tester.pump(const Duration(milliseconds: 72));
      expect(
        askRowFinderAtPrice(firstPrice),
        findsNothing,
        reason: '전량 체결된 첫 가격은 0주 drain 행으로 남지 않아야 합니다.',
      );
      expect(askQuantityAtPrice(lastPrice), lastQuantity);
      expect(
        tester.getCenter(border).dy,
        closeTo(firstTargetTop, 0.1),
        reason: '첫 가격 도착 직후 다음 가격 이동은 현재 위치에서 연속으로 시작해야 합니다.',
      );
      expect(
        _displayedOrderBookQuantities(tester).values,
        everyElement(greaterThan(0)),
        reason: '첫 전량체결 직후에도 화면에 숫자 0 행을 한 프레임도 남기면 안 됩니다.',
      );

      final secondTargetTop = tester.getCenter(askRowAtPrice(lastPrice)).dy;
      await tester.pump(const Duration(milliseconds: 72));
      final midArrivalTop = tester.getCenter(border).dy;
      if ((firstTargetTop - secondTargetTop).abs() > 0.1) {
        expect(
          midArrivalTop,
          allOf(
            greaterThan(math.min(firstTargetTop, secondTargetTop)),
            lessThan(math.max(firstTargetTop, secondTargetTop)),
          ),
          reason: '0주 행을 건너뛰어도 테두리는 다음 실제 행까지 연속 이동해야 합니다.',
        );
      }
      expect(askQuantityAtPrice(lastPrice), lastQuantity);

      var lastFillPresented = false;
      for (var frame = 0; frame < 24; frame += 1) {
        await tester.pump(const Duration(milliseconds: 8));
        expect(
          _displayedOrderBookQuantities(tester).values,
          everyElement(greaterThan(0)),
          reason: '마지막 전량체결 전환 중에도 숫자 0 행이 한 프레임이라도 보이면 안 됩니다.',
        );
        final playerTape = find.byKey(
          const Key('order-book-player-tape-print'),
        );
        if (playerTape.evaluate().isNotEmpty) {
          final visiblePlayerTrade = _displayedOrderBookTrade(
            tester,
            player: true,
          );
          if (visiblePlayerTrade.price == lastPrice &&
              visiblePlayerTrade.printedQuantity == lastQuantity) {
            lastFillPresented = true;
            break;
          }
        }
      }
      expect(
        lastFillPresented,
        isTrue,
        reason: '마지막 전량체결도 순서대로 도착해야 하며 0주 행은 노출하면 안 됩니다.',
      );
      playerTrade = _displayedOrderBookTrade(tester, player: true);
      expect(playerTrade.isBuy, isTrue);
      expect(playerTrade.price, lastPrice);
      expect(playerTrade.printedQuantity, lastQuantity);
      final stalePlayerTapeText = tester
          .widget<Text>(
            find.byKey(const Key('order-book-tape-quantity-side')).first,
          )
          .data;
      expect(
        playerTrade.printedQuantity,
        isNot(firstQuantity + lastQuantity),
        reason: '마지막 행에는 다단계 총체결량이 아니라 그 행 체결량만 표시해야 합니다.',
      );
      final pulseNotifier = _orderBookPulseNotifier(tester);
      expect(
        pulseNotifier.value,
        greaterThanOrEqualTo(submittedOrder!.microstructureFrame),
      );
      pulseNotifier.value += 1;
      await tester.pump();

      final activeTradeRow = find.byKey(
        const Key('order-book-active-trade-row'),
      );
      if (activeTradeRow.evaluate().isNotEmpty) {
        final nextTrade = _displayedOrderBookTrade(tester);
        final latestTapeText = tester
            .widget<Text>(
              find.byKey(const Key('order-book-tape-quantity-side')).first,
            )
            .data;
        expect(
          nextTrade.price != lastPrice || latestTapeText != stalePlayerTapeText,
          isTrue,
          reason: '플레이어 체결 활성 행은 다음 미세구조 펄스까지 남으면 안 됩니다.',
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
    await tester.tap(find.byKey(const Key('market-speed-pause')).last);
    await tester.pump();
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
    expect(find.byKey(const Key('order-book-depth-ratio')), findsOneWidget);
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
    expect(sellCellCount, stockOrderBookVisibleSideRows);
    expect(buyCellCount, stockOrderBookVisibleSideRows);
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
    expect(
      depthRecords.every((record) => record.$1 > 0),
      isTrue,
      reason: '운영 7+7 호가에는 숫자 0 잔량을 렌더링하면 안 됩니다.',
    );
    final inferredDepthScales = depthRecords
        .where((record) => record.$2 > 0 && record.$2 < 0.999999)
        .map((record) => record.$1 / record.$2)
        .toList(growable: false);
    expect(inferredDepthScales, isNotEmpty);
    expect(
      inferredDepthScales.reduce(math.max) -
          inferredDepthScales.reduce(math.min),
      lessThan(1),
      reason: '양쪽 7단 잔량 막대는 같은 안정화 분모를 사용해야 합니다.',
    );
    expect(
      [...sellDepthBars, ...buyDepthBars].reduce(math.max),
      inInclusiveRange(0.8, 1.0),
      reason: '분모 완충 중에도 가장 두꺼운 호가는 충분한 폭으로 보여야 합니다.',
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
    double? currentPriceBorderTop(Finder finder) {
      final border = tester.widget<Widget>(finder);
      expect(
        border,
        isA<AnimatedPositioned>(),
        reason:
            'arrival과 drain 모두 같은 AnimatedPositioned runtime type을 유지해야 합니다.',
      );
      final animatedBorder = border as AnimatedPositioned;
      expect(animatedBorder.duration, const Duration(milliseconds: 144));
      return animatedBorder.top;
    }

    final currentPriceBorderFinder = find.byKey(
      const Key('order-book-current-price-border'),
    );
    expect(currentPriceBorderFinder, findsOneWidget);
    currentPriceBorderTop(currentPriceBorderFinder);
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
    expect(priceSurfaces, hasLength(stockOrderBookVisibleSideRows * 2));
    final priceLabels = tester
        .widgetList<Text>(find.byKey(const Key('order-book-price-label')))
        .toList(growable: false);
    expect(priceLabels, hasLength(stockOrderBookVisibleSideRows * 2));
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
    final hasActiveSweep = find
        .byWidgetPredicate((widget) {
          final key = widget.key;
          if (key is! ValueKey) return false;
          final value = key.value;
          if (value is! Record) return false;
          final dynamic record = value;
          return record.$1 == 'order-book-sweep-active';
        }, skipOffstage: false)
        .evaluate()
        .isNotEmpty;
    if (!hasActiveSweep) {
      expect(
        outlinedPrice,
        tester.widget<Text>(find.byKey(const Key('stock-detail-price'))).data,
      );
    }
    void expectOutlineUsesOnlyCentralBestPriceRows() {
      final currentPriceOutline = find.byKey(
        const Key('order-book-current-price-border'),
      );
      final currentPriceRow = find.byKey(const Key('order-book-current-price'));
      final ladderStack = find.byKey(const Key('order-book-ladder-stack'));
      expect(currentPriceOutline, findsOneWidget);
      expect(currentPriceRow, findsOneWidget);
      expect(ladderStack, findsOneWidget);
      final ladderTop = tester.getTopLeft(ladderStack).dy;
      final outlineTop = currentPriceBorderTop(currentPriceOutline);
      expect(
        outlineTop,
        closeTo(tester.getTopLeft(currentPriceRow).dy - ladderTop, 0.1),
      );
      final bestAskTop =
          tester.getTopLeft(find.byKey(const Key('order-book-ask-0'))).dy -
          ladderTop;
      final bestBidTop =
          tester.getTopLeft(find.byKey(const Key('order-book-bid-0'))).dy -
          ladderTop;
      expect(bestAskTop, lessThan(bestBidTop));
      expect(
        outlineTop,
        anyOf(closeTo(bestAskTop, 0.1), closeTo(bestBidTop, 0.1)),
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
    expect(
      find.byKey(const Key('order-book-active-trade')),
      findsNothing,
      reason: '7+7 단일행 호가는 체결 문구 대신 테이프와 중앙 테두리를 사용합니다.',
    );
    expect(
      find.byKey(const Key('order-book-trade-tape-empty')),
      findsOneWidget,
    );
    expectOutlineUsesOnlyCentralBestPriceRows();
    expect(
      find.descendant(
        of: find.byKey(const Key('stock-order-book')),
        matching: find.text('현재가'),
      ),
      findsNothing,
    );
    final fixedPriceTop = tester.getTopLeft(
      find.byKey(const Key('stock-detail-price')),
    );

    await _finishOrderBookSweepPlayback(tester);
    await tester.pump();

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
    await tester.tap(find.text('시장가'));
    await tester.pump();
    expect(
      tester
          .widget<SegmentedButton<TradeOrderType>>(
            find.byKey(const Key('order-type-selector')),
          )
          .selected,
      {TradeOrderType.market},
    );
    await tester.ensureVisible(
      find.byKey(const Key('request-state-account-order-approval')),
    );
    await tester.tap(
      find.byKey(const Key('request-state-account-order-approval')),
    );
    for (var attempt = 0; attempt < 20; attempt += 1) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const Key('order-result')).evaluate().isNotEmpty) break;
    }
    expect(find.byKey(const Key('order-result')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('request-state-account-order-approval')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('request-state-account-order-approval')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-book-active-summary')), findsNothing);
    expect(find.byKey(const Key('inline-order-workspace')), findsOneWidget);

    await tester.tap(find.byKey(const Key('stock-detail-tab-quote')));
    await tester.pump();
    expectOutlineUsesOnlyCentralBestPriceRows();
    final position = current.positions
        .where((entry) => entry.assetId == 'hanbit_telecom')
        .firstOrNull;
    if (position == null) {
      expect(
        find.byKey(const Key('order-book-average-cost-marker')),
        findsNothing,
        reason: '지정가가 대기 중이면 아직 평균단가 마커가 없어야 합니다.',
      );
    } else {
      final snappedAverageCost = marketSnapPrice(position.averageCost).round();
      final averageCostIsVisible = find
          .byKey(const ValueKey('order-book-price-label'))
          .evaluate()
          .any(
            (element) =>
                _displayedOrderBookNumber(
                  tester,
                  find.byWidget(element.widget),
                ) ==
                snappedAverageCost,
          );
      expect(
        find.byKey(const Key('order-book-average-cost-marker')),
        averageCostIsVisible ? findsOneWidget : findsNothing,
        reason: '평균단가 마커는 평균단가가 현재 7+7 호가 창 안에 있을 때만 표시합니다.',
      );
    }

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
    final sellSubmit = find.byKey(
      const Key('request-state-account-order-approval'),
    );
    await tester.ensureVisible(sellSubmit);
    if (position == null) {
      expect(tester.widget<FilledButton>(sellSubmit).onPressed, isNull);
    } else {
      await tester.tap(sellSubmit);
      for (var attempt = 0; attempt < 20; attempt += 1) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byKey(const Key('order-result')).evaluate().isNotEmpty) break;
      }
      expect(find.byKey(const Key('order-result')), findsOneWidget);
      await tester.ensureVisible(sellSubmit);
      await tester.pump();
      await tester.tap(sellSubmit);
      await tester.pumpAndSettle();
    }
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
    final finalOwnedShares =
        current.positions
            .where((entry) => entry.assetId == 'hanbit_telecom')
            .firstOrNull
            ?.units ??
        0;
    final finalOwnedSharesLabel =
        finalOwnedShares == finalOwnedShares.roundToDouble()
        ? finalOwnedShares.toInt().toString()
        : finalOwnedShares.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '');
    expect(
      tester
          .widget<Text>(find.byKey(const Key('company-owned-shares-value')))
          .data,
      '$finalOwnedSharesLabel\uC8FC',
    );
    final ownershipLabel = tester
        .widget<Text>(find.byKey(const Key('company-ownership-percent-value')))
        .data;
    expect(ownershipLabel, finalOwnedShares > 0 ? isNot('0%') : '0%');
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

  testWidgets(
    'buy and sell slide the ticket in while preserving both quote walls',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = const GameEngine()
          .createNewGame(
            '호가 슬라이드 보존 테스트',
            initialCash: 1000000,
            worldSeed: 'widget-inline-order-slide-v1',
          )
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
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();
      await tester.tap(find.byKey(const Key('stock-row-1001')));
      await tester.pumpAndSettle();

      String normalizedPrice(String value) =>
          value.replaceAll(RegExp(r'[^0-9]'), '');
      Set<String> fullWallPrices(String side) => {
        for (var index = 0; index < stockOrderBookVisibleSideRows; index++)
          normalizedPrice(
            tester
                .widget<Text>(
                  find
                      .descendant(
                        of: find.byKey(Key('order-book-$side-$index')),
                        matching: find.byKey(
                          const ValueKey('order-book-price-label'),
                        ),
                      )
                      .first,
                )
                .data!,
          ),
      };
      Set<String> inlineWallPrices(String side) {
        final rows = find
            .byKey(ValueKey('inline-order-book-$side-row'))
            .evaluate();
        return {
          for (final row in rows)
            normalizedPrice(
              tester
                  .widget<Text>(
                    find
                        .descendant(
                          of: find.byElementPredicate(
                            (element) => identical(element, row),
                          ),
                          matching: find.byType(Text),
                        )
                        .first,
                  )
                  .data!,
            ),
        };
      }

      Map<String, int> inlineQuantities() {
        final result = <String, int>{};
        for (final side in const <String>['ask', 'bid']) {
          final rows = find
              .byKey(ValueKey('inline-order-book-$side-row'))
              .evaluate();
          for (final row in rows) {
            final rowFinder = find.byElementPredicate(
              (element) => identical(element, row),
            );
            final priceText = tester
                .widget<Text>(
                  find
                      .descendant(of: rowFinder, matching: find.byType(Text))
                      .first,
                )
                .data!;
            final quantityText = tester
                .widget<Text>(
                  find
                      .descendant(
                        of: rowFinder,
                        matching: find.byKey(
                          const Key('inline-order-book-quantity-value'),
                        ),
                      )
                      .first,
                )
                .data!;
            result['$side:${normalizedPrice(priceText)}'] = int.parse(
              normalizedPrice(quantityText),
            );
          }
        }
        return result;
      }

      final asksBefore = fullWallPrices('ask');
      final bidsBefore = fullWallPrices('bid');
      expect(asksBefore, hasLength(stockOrderBookVisibleSideRows));
      expect(bidsBefore, hasLength(stockOrderBookVisibleSideRows));

      await tester.tap(find.byKey(const Key('quote-order-dock-buy')));
      await tester.pump();

      final workspace = find.byKey(const Key('inline-order-workspace'));
      final ticket = find.byKey(const Key('inline-order-ticket'));
      final rail = find.byKey(const Key('inline-order-book'));
      final border = find.byKey(
        const Key('inline-order-book-current-price-border'),
      );
      expect(
        find.byKey(const Key('inline-order-slide-transition')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('inline-order-book-ask-row')),
        findsNWidgets(stockOrderBookVisibleSideRows),
      );
      expect(
        find.byKey(const ValueKey('inline-order-book-bid-row')),
        findsNWidgets(stockOrderBookVisibleSideRows),
      );
      expect(inlineWallPrices('ask'), asksBefore);
      expect(inlineWallPrices('bid'), bidsBefore);

      final workspaceRect = tester.getRect(workspace);
      final initialTicketRect = tester.getRect(ticket);
      final initialRailRect = tester.getRect(rail);
      final initialBorderPosition = tester.getTopLeft(border);
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('inline-order-book-ask-row')).first,
            )
            .width,
        closeTo(initialRailRect.width, 0.1),
      );
      expect(initialTicketRect.right, closeTo(workspaceRect.left, 0.1));
      expect(initialRailRect.left, closeTo(workspaceRect.left, 0.1));
      expect(initialRailRect.right, closeTo(workspaceRect.right, 0.1));

      await tester.pump(const Duration(milliseconds: 160));

      final middleTicketRect = tester.getRect(ticket);
      final middleRailRect = tester.getRect(rail);
      final middleBorderPosition = tester.getTopLeft(border);
      expect(middleTicketRect.left, greaterThan(initialTicketRect.left));
      expect(middleTicketRect.right, greaterThan(workspaceRect.left));
      expect(middleRailRect.left, greaterThan(initialRailRect.left));
      expect(middleRailRect.right, closeTo(workspaceRect.right, 0.1));
      expect(middleRailRect.width, lessThan(initialRailRect.width));
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('inline-order-book-ask-row')).first,
            )
            .width,
        closeTo(middleRailRect.width, 0.1),
      );
      expect(middleBorderPosition.dx, greaterThan(initialBorderPosition.dx));
      expect(middleBorderPosition.dy, closeTo(initialBorderPosition.dy, 0.1));
      expect(inlineWallPrices('ask'), asksBefore);
      expect(inlineWallPrices('bid'), bidsBefore);

      final railElementDuringSlide = tester.element(rail);
      final pulseNotifierDuringSlide = tester
          .widgetList<ValueListenableBuilder<int>>(
            find.descendant(
              of: workspace,
              matching: find.byType(ValueListenableBuilder<int>),
            ),
          )
          .map((builder) => builder.valueListenable)
          .whereType<ValueNotifier<int>>()
          .first;
      pulseNotifierDuringSlide.value = gameOrderBookLiquidityPulseFrame(
        marketMinute: state.marketMinute,
        slotIndex: 0,
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('market-speed-1x')).last);
      await tester.pump();
      final quantitiesBeforePulse = inlineQuantities();
      pulseNotifierDuringSlide.value = gameOrderBookLiquidityPulseFrame(
        marketMinute: state.marketMinute,
        slotIndex: 1,
      );
      await tester.pump();
      final quantitiesAfterPulse = inlineQuantities();
      final changedQuantities = <String>[
        for (final entry in quantitiesBeforePulse.entries)
          if (quantitiesAfterPulse[entry.key] != null &&
              quantitiesAfterPulse[entry.key] != entry.value)
            entry.key,
      ];
      final sortedDepth = quantitiesBeforePulse.values.toList(growable: false)
        ..sort((left, right) => right.compareTo(left));
      final largeDepthThreshold =
          sortedDepth[math.min(7, sortedDepth.length - 1)];

      expect(
        changedQuantities.any((key) {
          final before = quantitiesBeforePulse[key]!;
          final after = quantitiesAfterPulse[key]!;
          return before >= largeDepthThreshold &&
              (after - before).abs() <= math.max(1, (before * 0.02).ceil());
        }),
        isTrue,
        reason: '슬라이드 중에도 큰 매수벽·매도벽 중 한 행은 2% 이내로 실제 미세 수정돼야 합니다.',
      );
      expect(
        quantitiesAfterPulse.values,
        everyElement(greaterThan(0)),
        reason: '분할 호가에서도 0주 행을 렌더링하면 안 됩니다.',
      );
      expect(workspace, findsOneWidget);
      expect(ticket, findsOneWidget);
      expect(rail, findsOneWidget);
      expect(identical(tester.element(rail), railElementDuringSlide), isTrue);
      expect(
        find.byKey(const ValueKey('inline-order-book-ask-row')),
        findsNWidgets(stockOrderBookVisibleSideRows),
      );
      expect(
        find.byKey(const ValueKey('inline-order-book-bid-row')),
        findsNWidgets(stockOrderBookVisibleSideRows),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('market-speed-pause')).last);
      await tester.pump();

      await tester.pumpAndSettle();

      final settledTicketRect = tester.getRect(ticket);
      final settledRailRect = tester.getRect(rail);
      final settledBorderPosition = tester.getTopLeft(border);
      expect(settledTicketRect.left, closeTo(workspaceRect.left, 0.1));
      expect(settledTicketRect.right, lessThanOrEqualTo(settledRailRect.left));
      expect(settledRailRect.right, closeTo(workspaceRect.right, 0.1));
      expect(settledRailRect.width, inInclusiveRange(138, 156));
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('inline-order-book-ask-row')).first,
            )
            .width,
        closeTo(settledRailRect.width, 0.1),
      );
      expect(settledBorderPosition.dx, greaterThan(middleBorderPosition.dx));
      final settledRowHeight = tester
          .getSize(
            find.byKey(const ValueKey('inline-order-book-ask-row')).first,
          )
          .height;
      expect(
        (settledBorderPosition.dy - initialBorderPosition.dy).abs(),
        lessThanOrEqualTo(settledRowHeight + 0.1),
        reason: '호가 펄스 한 번에 현재가 테두리가 여러 칸 점프하면 안 됩니다.',
      );
      expect(inlineWallPrices('ask'), asksBefore);
      expect(inlineWallPrices('bid'), bidsBefore);

      final preservedRailElement = tester.element(rail);
      await tester.tap(find.byKey(const Key('sell-stock-button')));
      await tester.pump();
      expect(find.text('매도 주문'), findsWidgets);
      expect(identical(tester.element(rail), preservedRailElement), isTrue);
      expect(tester.getRect(rail), equals(settledRailRect));
      expect(inlineWallPrices('ask'), asksBefore);
      expect(inlineWallPrices('bid'), bidsBefore);

      await tester.tap(find.byKey(const Key('buy-stock-button')));
      await tester.pump();
      expect(find.text('매수 주문'), findsWidgets);
      expect(identical(tester.element(rail), preservedRailElement), isTrue);
      expect(tester.getRect(rail), equals(settledRailRect));
      expect(inlineWallPrices('ask'), asksBefore);
      expect(inlineWallPrices('bid'), bidsBefore);
      expect(tester.takeException(), isNull);
    },
  );
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
          universe: testMarketUniverse(
            tradingDate: state.currentDate,
            includeKnownPartner: true,
          ),
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
    expect(compactSellRows, findsNWidgets(stockOrderBookVisibleSideRows));
    expect(compactBuyRows, findsNWidgets(stockOrderBookVisibleSideRows));
    expect(
      tester.getSize(compactSellRows.first).height,
      greaterThan(15),
      reason: '각 호가 터치 행은 10단 표시 때의 최소 높이보다 커야 합니다.',
    );
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
    await tester.pumpAndSettle();
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
          universe: testMarketUniverse(
            tradingDate: state.currentDate,
            includeKnownPartner: true,
          ),
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

  testWidgets('state principal opens the first state-account order authority', (
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
      find.byKey(const Key('request-state-account-order-approval')),
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
    await tester.tap(
      find.byKey(const Key('request-state-account-order-approval')),
    );
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const Key('order-result')).evaluate().isNotEmpty) break;
    }

    expect(find.textContaining('주문을 저장하지 못했어요'), findsWidgets);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('request-state-account-order-approval')),
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
          'companyName': '제6기 배치 연구소',
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
        '제6기 배치 연구소',
      );
      expect(find.text('정식 직원 0명'), findsOneWidget);
      expect(
        find.byKey(const Key('assignment-portrait-hakjun')),
        findsOneWidget,
      );

      final suaCard = find.byKey(const Key('assignment-card-sua'));
      await tester.ensureVisible(suaCard);
      await tester.tap(suaCard);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('assignment-portrait-sua')), findsOneWidget);

      final helpButton = find.byKey(const Key('academy-help-sua'));
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
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
        onRequestAcademyHelp: (_) async => currentState,
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
          onRequestAcademyHelp: (_) async => state,
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
    expect(requestedMinute, krxCloseMinute);

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
