import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_news.dart';

void main() {
  const engine = GameEngine();

  test('플레이어의 최근 선택과 현재 시대 흐름을 기사 입력으로 만든다', () {
    final initial = engine.createNewGame('새벽투자연구소');
    final resolved = engine.resolveDecision(
      initial,
      'first-research-note',
      'research_products',
    );
    final brief = buildDailyBrief(resolved);

    final request = dynamicNewsRequestForState(resolved, brief);
    expect(request.year, 2000);
    expect(request.companyName, '새벽투자연구소');
    expect(request.action, contains('써 본 제품부터 보기'));
    expect(request.megaTrend, isNotEmpty);
  });
}
