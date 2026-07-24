import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_rental.dart';
import 'package:millennium_capital/game/real_estate_world.dart';
import 'package:millennium_capital/main.dart';

void main() {
  testWidgets('360px 화면에서 지도와 첫 부동산 취득비용을 확인하고 매입한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const engine = GameEngine();
    var state = engine
        .createNewGame('부동산 화면 테스트', initialCash: 100000000)
        .copyWith(brokerageCash: 0, decisions: const []);

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

    expect(find.byKey(const Key('real-estate-tier-starter')), findsOneWidget);
    expect(find.byKey(const Key('real-estate-metro-map')), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);

    final carousel = find.byKey(const Key('real-estate-listing-carousel'));
    await tester.ensureVisible(carousel);
    await tester.pumpAndSettle();
    final horizontalScrollable = find.descendant(
      of: carousel,
      matching: find.byType(Scrollable),
    );
    final horizontalPosition = tester
        .state<ScrollableState>(horizontalScrollable)
        .position;
    horizontalPosition.jumpTo(0);
    await tester.pumpAndSettle();

    final buyButtons = find.descendant(
      of: carousel,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is FilledButton &&
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'real-estate-buy-',
            ),
      ),
    );
    expect(buyButtons, findsWidgets);
    final buyButton = buyButtons.first;
    final button = tester.widget<FilledButton>(buyButton);
    final keyValue = (button.key! as ValueKey<String>).value;
    final encoded = keyValue.substring('real-estate-buy-'.length);
    final separator = encoded.lastIndexOf('-');
    final assetId = encoded.substring(0, separator);
    final listingIndex = int.parse(encoded.substring(separator + 1));
    final listing = realEstateListingByRef(
      RealEstateListingRef(assetId: assetId, listingIndex: listingIndex),
      state.simulationSeed,
    )!;
    final quote = listing.quoteAt(state.currentDate);

    await tester.ensureVisible(buyButton);
    await tester.pumpAndSettle();
    horizontalPosition.jumpTo(220);
    await tester.pumpAndSettle();
    await tester.tap(buyButton);
    await tester.pumpAndSettle();

    expect(find.text('위험 확인 후 매입'), findsOneWidget);
    expect(find.textContaining('실제 필요 현금'), findsOneWidget);
    await tester.tap(find.text('위험 확인 후 매입'));
    await tester.pumpAndSettle();

    expect(state.cash, 100000000 - quote.totalCash);
    expect(
      state.personalFinance.realEstate.single.marketAssetId,
      listing.asset.id,
    );
    expect(
      state.personalFinance.realEstate.single.marketListingIndex,
      listing.index,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('2010년 매물은 현금과 담보대출 LTV를 선택할 수 있다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const engine = GameEngine();
    final base = engine
        .createNewGame('부동산 대출 화면 테스트', initialCash: 1000000000)
        .copyWith(brokerageCash: 0, decisions: const []);
    final targetDay =
        DateTime(2010, 6, 15).difference(base.campaignStartDate).inDays + 1;
    var state = base.copyWith(day: targetDay);

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

    final carousel = find.byKey(const Key('real-estate-listing-carousel'));
    await tester.ensureVisible(carousel);
    await tester.pumpAndSettle();
    final horizontalScrollable = find.descendant(
      of: carousel,
      matching: find.byType(Scrollable),
    );
    final horizontalPosition = tester
        .state<ScrollableState>(horizontalScrollable)
        .position;
    final buyButton = find
        .descendant(
          of: carousel,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is FilledButton &&
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'real-estate-buy-',
                ),
          ),
        )
        .first;
    await tester.ensureVisible(buyButton);
    horizontalPosition.jumpTo(220);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(buyButton);
    await tester.pumpAndSettle();

    expect(find.text('매입 자금 선택'), findsOneWidget);
    expect(find.byKey(const Key('real-estate-financing-70')), findsOneWidget);
    await tester.tap(find.byKey(const Key('real-estate-financing-70')));
    await tester.pumpAndSettle();

    expect(find.text('위험 확인 후 매입'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('월 원리금'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('390px 화면에서 보유 오피스텔의 월세 계약을 체결한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const engine = GameEngine();
    final base = engine
        .createNewGame('임대 운영 화면 테스트', initialCash: 1000000000)
        .copyWith(brokerageCash: 0, decisions: const []);
    final targetDay =
        DateTime(2010, 6, 15).difference(base.campaignStartDate).inDays + 1;
    final dated = base.copyWith(day: targetDay);
    final marketAsset = realEstateMarketAssetById(
      'uijeongbu_station_officetel_20',
    )!;
    final listing = realEstateListingsFor(
      marketAsset,
      dated.simulationSeed,
    ).first;
    final purchase = engine.purchaseSpendingOption(dated, listing.optionId);
    expect(purchase.success, isTrue);
    var state = purchase.state;
    final ownedId = state.personalFinance.realEstate.single.id;

    await tester.pumpWidget(
      MaterialApp(
        home: AssetSpendingScreen(
          state: state,
          onPurchase: (optionId) async =>
              engine.purchaseSpendingOption(state, optionId),
          onSellRealEstate: (assetId) async =>
              engine.sellRealEstate(state, assetId),
          onConfigureLease: (assetId, leaseType) async {
            final result = engine.configureRealEstateLease(
              state,
              assetId,
              leaseType,
            );
            if (result.success) state = result.state;
            return result;
          },
          onPlayChanceGame: (stake) async =>
              engine.playAdultChanceGame(state, stake),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final manageButton = find.byKey(Key('real-estate-lease-manage-$ownedId'));
    for (
      var attempt = 0;
      attempt < 8 && manageButton.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(
        find.byKey(const Key('asset-spending-screen')),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
    }
    expect(manageButton, findsOneWidget);
    await tester.ensureVisible(manageButton);
    await tester.tap(manageButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('보증금은 수익이 아니라'), findsOneWidget);
    expect(
      find.byKey(const Key('real-estate-lease-monthlyRent')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('real-estate-lease-monthlyRent')));
    await tester.pumpAndSettle();
    expect(find.text('계약 확정'), findsOneWidget);
    await tester.tap(find.text('계약 확정'));
    await tester.pumpAndSettle();

    expect(
      state.personalFinance.realEstate.single.leaseType,
      RealEstateLeaseType.monthlyRent,
    );
    expect(find.text('계약 종료 후 매각'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
