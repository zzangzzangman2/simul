import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';

void main() {
  const engine = GameEngine();

  PendingTradeOrder pending({
    required String id,
    required int sequence,
    required double remaining,
    required double queueAhead,
  }) => PendingTradeOrder(
    id: id,
    side: PendingOrderSide.buy,
    assetId: 'queue_audit_stock',
    symbol: 'Q001',
    name: '큐 감사 종목',
    market: 'KSE',
    currency: 'KRW',
    limitPrice: 10000,
    originalQuantity: remaining,
    remainingQuantity: remaining,
    placedDate: '2000-01-03',
    placedMinute: 600,
    placedSequence: sequence,
    queueAheadQuantity: queueAhead,
    maximumPositionUnits: 1000000,
  );

  test(
    'canceling an earlier same-price order advances the later FIFO queue',
    () {
      final state = engine
          .createNewGame('FIFO 취소 감사', worldSeed: 'fifo-cancel-audit')
          .copyWith(
            pendingOrders: <PendingTradeOrder>[
              pending(id: 'first', sequence: 1, remaining: 20, queueAhead: 100),
              pending(
                id: 'second',
                sequence: 2,
                remaining: 30,
                queueAhead: 120,
              ),
            ],
          );

      final result = engine.cancelPendingOrder(state, 'first');

      expect(result.success, isTrue);
      expect(result.state.pendingOrders, hasLength(1));
      expect(result.state.pendingOrders.single.id, 'second');
      expect(result.state.pendingOrders.single.queueAheadQuantity, 100);
    },
  );
}
