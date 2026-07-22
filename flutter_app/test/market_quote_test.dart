import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_quote.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'authoritative quote resolves the exact asset, date, minute, and price',
    () async {
      const engine = GameEngine();
      final universe = await HistoricalMarketUniverse.load();
      final state = engine
          .createNewGame('시세 서비스 테스트')
          .copyWith(day: 4, marketMinute: 9 * 60);

      final quote = resolveHistoricalTradeQuote(universe, state, 'samsung');

      expect(quote, isNotNull);
      expect(quote!.asset.code, '005930');
      expect(quote.quoteDate, '2000-01-04');
      expect(quote.marketMinute, 9 * 60);
      expect(quote.unitPrice, greaterThan(0));
      expect(quote.isTradingDay, isTrue);
    },
  );

  test('unknown assets cannot obtain an authoritative quote', () async {
    const engine = GameEngine();
    final universe = await HistoricalMarketUniverse.load();
    final state = engine.createNewGame('시세 거부 테스트').copyWith(day: 4);

    expect(resolveHistoricalTradeQuote(universe, state, 'fake'), isNull);
  });
}
