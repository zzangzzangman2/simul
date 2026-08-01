import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_persistence.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/main.dart';

void main() {
  testWidgets('stock test mode opens a disposable one-million-won market', (
    tester,
  ) async {
    var persistentWrites = 0;
    final persistence = GamePersistence(
      saveString: (key, value) async {
        persistentWrites += 1;
        return true;
      },
    );

    await tester.pumpWidget(
      MillenniumCapitalApp(stockTestMode: true, persistence: persistence),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    final marketFinder = find.byKey(const Key('stock-test-market-screen'));
    expect(marketFinder, findsOneWidget);
    expect(find.text('처음하기'), findsNothing);

    final market = tester.widget<StockMarketScreen>(marketFinder);
    expect(market.state.companyName, '주식시장 테스트');
    expect(market.state.brokerageCash, 1000000);
    expect(market.state.marketMinute, krxOpenMinute);
    expect(market.state.story.marketTutorialSeen, isTrue);
    expect(market.state.story.accountAuthorityLevel, 5);

    final next = await market.onSetMarketMinute!(krxOpenMinute + 1);
    await tester.pump();
    expect(next.marketMinute, krxOpenMinute + 1);
    expect(persistentWrites, 0, reason: '테스트 거래 상태가 실제 저장 슬롯에 기록되면 안 됩니다.');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
