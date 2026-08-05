import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/order_book.dart';
import 'package:millennium_capital/main.dart';

void main() {
  test('player sell remains visible when external asks are exhausted', () {
    const bid = GameOrderBookLevel(
      side: GameOrderBookSide.bid,
      price: 9900,
      quantity: 1200,
      isWall: false,
    );
    const sell = PendingTradeOrder(
      id: 'player-sell',
      side: PendingOrderSide.sell,
      assetId: 'full-takeover',
      symbol: 'FULL',
      name: 'Full Takeover',
      market: 'KOSPI',
      currency: 'KRW',
      limitPrice: 10100,
      originalQuantity: 250,
      remainingQuantity: 250,
      placedDate: '2026-08-05',
      placedMinute: 600,
      placedSequence: 1,
    );

    final levels = orderBookPresentationLevelsWithPlayerOrders(
      marketLevels: const <GameOrderBookLevel>[bid],
      playerOrders: const <PendingTradeOrder>[sell],
    );

    expect(levels, hasLength(2));
    expect(levels.first.side, GameOrderBookSide.ask);
    expect(levels.first.price, 10100);
    expect(levels.first.quantity, 0);
    expect(levels.last, same(bid));
  });

  test('player quote shares an existing row instead of duplicating it', () {
    const ask = GameOrderBookLevel(
      side: GameOrderBookSide.ask,
      price: 10100,
      quantity: 900,
      isWall: false,
    );
    const sell = PendingTradeOrder(
      id: 'player-sell',
      side: PendingOrderSide.sell,
      assetId: 'partial-takeover',
      symbol: 'PART',
      name: 'Partial Takeover',
      market: 'KOSPI',
      currency: 'KRW',
      limitPrice: 10100,
      originalQuantity: 250,
      remainingQuantity: 250,
      placedDate: '2026-08-05',
      placedMinute: 600,
      placedSequence: 1,
    );

    final levels = orderBookPresentationLevelsWithPlayerOrders(
      marketLevels: const <GameOrderBookLevel>[ask],
      playerOrders: const <PendingTradeOrder>[sell],
    );

    expect(levels, hasLength(1));
    expect(levels.single, same(ask));
  });
}
