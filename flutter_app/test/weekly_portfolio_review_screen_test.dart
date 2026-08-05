import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/weekly_portfolio_review.dart';
import 'package:millennium_capital/main.dart';

import 'support/market_fixture.dart';

void main() {
  testWidgets('weekly review records one real research or risk decision', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    const engine = GameEngine();
    final state = engine
        .createNewGame('주간 복기 화면', worldSeed: 'weekly-review-screen')
        .copyWith(day: 3, decisions: const []);
    final candidates = testMarketUniverse(
      tradingDate: state.currentDate,
      includeKnownPartner: true,
    ).assets;
    WeeklyPortfolioReviewAction? recordedAction;
    String? recordedAssetId;

    await tester.pumpWidget(
      MaterialApp(
        home: WeeklyPortfolioReviewScreen(
          state: state,
          candidates: candidates,
          onComplete:
              ({
                required action,
                required assetId,
                required assetName,
                required riskLimitBps,
              }) async {
                recordedAction = action;
                recordedAssetId = assetId;
                return completeWeeklyPortfolioReview(
                  state,
                  action: action,
                  assetId: assetId,
                  assetName: assetName,
                  riskLimitBps: riskLimitBps,
                );
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('weekly-portfolio-review-screen')),
      findsOneWidget,
    );
    expect(find.text('이번 주 투자 복기'), findsOneWidget);
    expect(find.textContaining('매일이 아닌 주 1회'), findsOneWidget);
    expect(
      find.byKey(const Key('weekly-review-asset-hanbit_telecom')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('weekly-review-research-button')));
    await tester.pumpAndSettle();

    expect(recordedAction, WeeklyPortfolioReviewAction.research);
    expect(recordedAssetId, 'hanbit_telecom');
    expect(tester.takeException(), isNull);
  });
}
