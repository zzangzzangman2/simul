import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/main.dart';

void main() {
  testWidgets('서울·경기 지도 핀으로 현재 단계의 지역 매물을 필터링한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const engine = GameEngine();
    final state = engine
        .createNewGame('부동산 지도 테스트', initialCash: 100000000)
        .copyWith(
          simulationSeed: 'real-estate-map-test',
          brokerageCash: 0,
          decisions: const [],
        );

    await tester.pumpWidget(
      MaterialApp(
        home: AssetSpendingScreen(
          state: state,
          onPurchase: (id) async => engine.purchaseSpendingOption(state, id),
          onSellRealEstate: (id) async => engine.sellRealEstate(state, id),
          onPlayChanceGame: (stake) async =>
              engine.playAdultChanceGame(state, stake),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final map = find.byKey(const Key('real-estate-metro-map'));
    await tester.scrollUntilVisible(
      map,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(map, findsOneWidget);

    final uijeongbuPin = find.byKey(
      const Key('real-estate-map-district-gyeonggi-uijeongbu'),
    );
    expect(uijeongbuPin, findsOneWidget);
    await tester.tap(uijeongbuPin);
    await tester.pumpAndSettle();

    expect(find.textContaining('의정부시 3개 매물'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'real-estate-market-uijeongbu_station_officetel_20-',
            ),
      ),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'real-estate-market-guro_station_officetel_21-',
            ),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('real-estate-map-show-all')));
    await tester.pumpAndSettle();
    expect(find.textContaining('지도 핀을 누르면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
