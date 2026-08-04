import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/story_state.dart';
import 'package:millennium_capital/main.dart';

import 'support/market_fixture.dart';

Future<void> _waitForMarketHome(WidgetTester tester) async {
  final home = find.byKey(const Key('market-home-section'));
  for (var attempt = 0; attempt < 80; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (home.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  expect(home, findsOneWidget);
}

Future<void> _advanceToTarget(
  WidgetTester tester, {
  required Key actionKey,
  required Key targetKey,
}) async {
  final action = find.byKey(actionKey);
  final target = find.byKey(targetKey);
  for (var attempt = 0; attempt < 16; attempt += 1) {
    await tester.pump();
    if (target.evaluate().isNotEmpty) return;
    expect(action, findsOneWidget);
    await tester.tap(action);
    await tester.pump(const Duration(milliseconds: 650));
  }
  expect(target, findsOneWidget);
}

void _expectAligned(
  WidgetTester tester, {
  required Key overlayTargetKey,
  required Key sourceKey,
}) {
  final overlayRect = tester.getRect(find.byKey(overlayTargetKey));
  final expectedRect = tester.getRect(find.byKey(sourceKey)).inflate(5);
  expect(overlayRect.left, closeTo(expectedRect.left, 0.6));
  expect(overlayRect.top, closeTo(expectedRect.top, 0.6));
  expect(overlayRect.right, closeTo(expectedRect.right, 0.6));
  expect(overlayRect.bottom, closeTo(expectedRect.bottom, 0.6));
}

void main() {
  testWidgets('주식 튜토리얼 강조는 실제 조작 대상과 정확히 일치한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const engine = GameEngine();
    final story = StoryState.newPlayer(
      playerName: '주식 튜토리얼 좌표 테스트',
      introChoice: 'stocks',
      startingTrait: StoryTrait.analysis,
      operatingPrinciple: OperatingPrinciple.reportLosses,
    );
    var current = engine
        .createNewGame('좌표 테스트', initialCash: 237000, story: story)
        .copyWith(day: 4, marketMinute: krxOpenMinute);

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
          onCompleteTutorial: () async => current,
        ),
      ),
    );
    await _waitForMarketHome(tester);
    await tester.pump(const Duration(milliseconds: 600));

    await _advanceToTarget(
      tester,
      actionKey: const Key('market-tutorial-next'),
      targetKey: const Key('market-tutorial-target'),
    );
    _expectAligned(
      tester,
      overlayTargetKey: const Key('market-tutorial-target'),
      sourceKey: const Key('market-nav-explore'),
    );
    await tester.tap(find.byKey(const Key('market-tutorial-target')));
    await tester.pump(const Duration(milliseconds: 750));

    await _advanceToTarget(
      tester,
      actionKey: const Key('market-tutorial-next'),
      targetKey: const Key('market-tutorial-target'),
    );
    _expectAligned(
      tester,
      overlayTargetKey: const Key('market-tutorial-target'),
      sourceKey: const Key('stock-row-1001'),
    );
    await tester.tap(find.byKey(const Key('market-tutorial-target')));
    await tester.pump(const Duration(milliseconds: 1200));

    await _advanceToTarget(
      tester,
      actionKey: const Key('market-detail-tutorial-next'),
      targetKey: const Key('market-detail-tutorial-target'),
    );
    _expectAligned(
      tester,
      overlayTargetKey: const Key('market-detail-tutorial-target'),
      sourceKey: const Key('market-tutorial-price-source'),
    );
    await tester.tap(find.byKey(const Key('market-detail-tutorial-target')));
    await tester.pump(const Duration(milliseconds: 600));

    await _advanceToTarget(
      tester,
      actionKey: const Key('market-detail-tutorial-next'),
      targetKey: const Key('market-detail-tutorial-target'),
    );
    _expectAligned(
      tester,
      overlayTargetKey: const Key('market-detail-tutorial-target'),
      sourceKey: const Key('stock-detail-tab-info'),
    );
    await tester.tap(find.byKey(const Key('market-detail-tutorial-target')));
    await tester.pump(const Duration(milliseconds: 600));

    for (var page = 0; page < 3; page += 1) {
      await tester.tap(find.byKey(const Key('market-detail-tutorial-next')));
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('tutorial-buy-reason-choice-0')));
    await tester.pump();
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

    await _advanceToTarget(
      tester,
      actionKey: const Key('market-detail-tutorial-next'),
      targetKey: const Key('market-detail-tutorial-target'),
    );
    _expectAligned(
      tester,
      overlayTargetKey: const Key('market-detail-tutorial-target'),
      sourceKey: const Key('market-tutorial-order-book-header-source'),
    );
    await tester.tap(find.byKey(const Key('market-detail-tutorial-target')));
    await tester.pump(const Duration(milliseconds: 600));

    await _advanceToTarget(
      tester,
      actionKey: const Key('market-detail-tutorial-next'),
      targetKey: const Key('market-detail-tutorial-target'),
    );
    _expectAligned(
      tester,
      overlayTargetKey: const Key('market-detail-tutorial-target'),
      sourceKey: const Key('order-book-best-ask'),
    );
    expect(find.byKey(const Key('order-book-ask-0')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const Key('order-book-best-ask'))),
      tester.getRect(find.byKey(const Key('order-book-ask-0'))),
    );
    expect(tester.takeException(), isNull);
  });
}
