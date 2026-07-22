import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_news.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const engine = GameEngine();

  test('플레이어 행동과 투자소 이름은 경제 기사 입력에서 제외한다', () async {
    final initial = engine.createNewGame('새벽투자연구소');
    final resolved = engine.resolveDecision(
      initial,
      'first-research-note',
      'research_products',
    );
    final baseNewspaper = await buildDailyMarketNewspaper(resolved);

    final request = dynamicNewsRequestForState(
      resolved,
      baseNewspaper.brief,
      newspaper: baseNewspaper,
    );
    final payload = request.toJson();
    expect(request.year, 2000);
    expect(request.date, '2000-01-01');
    expect(request.marketSummary, isNotEmpty);
    expect(payload, isNot(contains('companyName')));
    expect(payload, isNot(contains('action')));
    expect(payload.values.join(' '), isNot(contains('새벽투자연구소')));
    expect(payload.values.join(' '), isNot(contains('써 본 제품부터 보기')));
  });
}
