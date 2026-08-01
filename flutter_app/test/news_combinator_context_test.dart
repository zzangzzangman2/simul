import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_news.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const engine = GameEngine();

  test('기사 조합 입력에는 플레이어 행동과 미래 사건 정보가 없다', () async {
    final initial = engine.createNewGame('민수의 투자연구소');
    final resolved = engine.resolveDecision(
      initial,
      'first-research-note',
      'research_products',
    );
    final newspaper = await buildDailyMarketNewspaper(resolved);
    final input = newsCombinatorInputForState(
      resolved,
      newspaper.brief,
      newspaper: newspaper,
    );
    final snapshot = input.toSafeSnapshot();
    final values = snapshot.values.join(' ');

    expect(input.year, 2000);
    expect(input.date, '2000-01-01');
    expect(input.marketSummary, isNotEmpty);
    expect(snapshot, isNot(contains('companyName')));
    expect(snapshot, isNot(contains('action')));
    expect(snapshot, isNot(contains('futureEvents')));
    expect(snapshot, isNot(contains('futurePrices')));
    expect(values, isNot(contains('민수의 투자연구소')));
    expect(values, isNot(contains('research_products')));
  });
}
