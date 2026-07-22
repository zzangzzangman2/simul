import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/main.dart';

void main() {
  const engine = GameEngine();

  testWidgets(
    'asset and spending screen fits a 360px phone and records a spend',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var state = engine
          .createNewGame('소비 화면 테스트', initialCash: 100000)
          .copyWith(decisions: const []);

      await tester.pumpWidget(
        MaterialApp(
          home: AssetSpendingScreen(
            state: state,
            onPurchase: (optionId) async {
              final result = engine.purchaseSpendingOption(state, optionId);
              if (result.success) state = result.state;
              return result;
            },
            onSellRealEstate: (assetId) async =>
                engine.sellRealEstate(state, assetId),
            onPlayChanceGame: (stake) async =>
                engine.playAdultChanceGame(state, stake),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('asset-spending-screen')), findsOneWidget);
      expect(
        find.byKey(const Key('spending-option-family_outing')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('spending-option-family_outing')));
      await tester.pumpAndSettle();
      expect(find.text('지출 확정'), findsOneWidget);
      await tester.tap(find.text('지출 확정'));
      await tester.pumpAndSettle();

      expect(state.cash, 80000);
      expect(state.personalFinance.totalSpent, 20000);
      expect(find.textContaining('80,000원'), findsWidgets);
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('adult-chance-card')), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );
}
