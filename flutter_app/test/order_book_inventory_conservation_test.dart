import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/order_book.dart';

void main() {
  const outstanding = 1000000;

  GameOrderBookSnapshot snapshot({
    required int day,
    required double owned,
    double tenderOwned = 0,
  }) => buildGameOrderBookSnapshot(
    assetId: 'inventory_audit_stock',
    day: day,
    minute: 600,
    currentPrice: 10000,
    previousClose: 10000,
    date: DateTime(2000, 1, 3),
    market: 'KSE',
    simulationSeed: 'inventory-conservation-test',
    sharesOutstanding: outstanding,
    playerOwnedUnits: owned,
    playerTenderAcquiredUnits: tenderOwned,
  );

  test(
    'player, external float, and locked holders always conserve issuance',
    () {
      for (final ownership in const <double>[
        0,
        1,
        200000,
        510000,
        999000,
        1000000,
      ]) {
        final profile = gameMarketInventoryProfile(
          assetId: 'inventory_audit_stock',
          day: 12,
          referencePrice: 10000,
          simulationSeed: 'inventory-conservation-test',
          sharesOutstanding: outstanding,
          playerOwnedUnits: ownership,
          playerTenderAcquiredUnits: ownership >= 510000 ? 310000 : 0,
        );

        expect(profile.hasIssuedShareLedger, isTrue);
        expect(profile.conservedShares, outstanding);
        expect(profile.nonPlayerTradableShares, greaterThanOrEqualTo(0));
        expect(profile.nonPlayerLockedShares, greaterThanOrEqualTo(0));
        expect(
          profile.playerTenderAcquiredShares,
          lessThanOrEqualTo(profile.playerOwnedShares),
        );
        expect(profile.maximumQuoteQuantity, 50000);
      }
    },
  );

  test(
    '100 percent ownership removes synthetic asks but preserves funded bids',
    () {
      final book = snapshot(day: 1, owned: outstanding.toDouble());

      expect(book.ownershipIsConserved, isTrue);
      expect(book.nonPlayerTradableShares, 0);
      expect(book.asks, isEmpty);
      expect(book.totalAskQuantity, 0);
      expect(book.bids, isNotEmpty);
      expect(
        book.totalBidQuantity,
        lessThanOrEqualTo(book.visibleBidDemandLimit),
      );
      expect(book.externalBidCash, greaterThan(0));
      final displayedBidNotional = book.bids.fold<double>(
        0,
        (sum, level) => sum + level.price * level.quantity,
      );
      expect(displayedBidNotional, lessThanOrEqualTo(book.externalBidCash));
    },
  );

  test('visible asks never exceed remaining external tradable inventory', () {
    for (final ownership in const <double>[0, 200000, 510000, 900000, 999000]) {
      final book = snapshot(
        day: 17,
        owned: ownership,
        tenderOwned: ownership >= 510000 ? 310000 : 0,
      );

      expect(book.ownershipIsConserved, isTrue);
      expect(
        book.totalAskQuantity,
        lessThanOrEqualTo(book.nonPlayerTradableShares),
      );
      expect(
        book.totalAskQuantity,
        lessThanOrEqualTo(book.visibleAskSupplyLimit),
      );
      expect(book.visibleInventoryIsConserved, isTrue);
      for (final level in <GameOrderBookLevel>[...book.asks, ...book.bids]) {
        expect(level.quantity, lessThanOrEqualTo(outstanding));
      }
    }
  });

  test(
    '51 percent owner remains protected when an exhausted bid disappears',
    () {
      final asks = <GameOrderBookLevel>[
        const GameOrderBookLevel(
          side: GameOrderBookSide.ask,
          price: 10100,
          quantity: 200000,
          isWall: true,
        ),
        const GameOrderBookLevel(
          side: GameOrderBookSide.ask,
          price: 10200,
          quantity: 200000,
          isWall: true,
        ),
        const GameOrderBookLevel(
          side: GameOrderBookSide.ask,
          price: 10300,
          quantity: 90000,
          isWall: true,
        ),
      ];
      final bids = <GameOrderBookLevel>[
        const GameOrderBookLevel(
          side: GameOrderBookSide.bid,
          price: 9900,
          quantity: 10000,
          isWall: false,
        ),
      ];
      final ledger = GameOrderBookSnapshot(
        asks: asks,
        bids: bids,
        turnoverEok: 100,
        fullDayTurnoverEok: 100,
        boundaryBidPrice: 9900,
        executionCapacity: 100000,
        totalAskQuantity: 490000,
        totalBidQuantity: 10000,
        tradeStrength: 100,
        liquidityPulse: gameOrderBookLiquidityPulseFrame(
          marketMinute: 600,
          slotIndex: 1,
        ),
        adaptiveLiquidityPulses: true,
        sourceAssetId: 'majority-transition-stock',
        sourceLiquidityDayKey: 1,
        sourceDateKey: '2000-01-03',
        sourceMarketMinute: 600,
        sourceLastTradePrice: 10000,
        sourceMarket: 'KSE',
        sourceSimulationSeed: 'majority-transition-world',
        sharesOutstanding: outstanding,
        estimatedFreeFloatShares: outstanding,
        playerOwnedShares: 510000,
        nonPlayerTradableShares: 490000,
        maximumQuoteQuantity: 50000,
        externalBidCash: 500000000,
        visibleAskSupplyLimit: 490000,
        visibleBidDemandLimit: 50000,
      );

      final playerFillTransition = gameOrderBookSnapshotAfterConsumption(
        snapshot: ledger,
        consumedBidByPrice: <double, double>{9900: 10000},
        consumedCapacityUnits: 10000,
        latestConsumedSide: GameOrderBookSide.bid,
        latestConsumedPrice: 9900,
      );
      final generatedTradeTransition = gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: ledger,
        pulse: const GameOrderBookTradePulse(
          levelSide: GameOrderBookSide.bid,
          levelIndex: 0,
          quantity: 10000,
          crossedTicks: 1,
        ),
        absolutePrice: 9900,
        availableSnapshot: ledger,
        perMinuteBudgetUnits: 10000,
      );

      for (final transitioned in <GameOrderBookSnapshot>[
        playerFillTransition,
        generatedTradeTransition,
      ]) {
        expect(transitioned.asks.first.price, 10100);
        expect(
          transitioned.asks.any((level) => level.price == 9900),
          isFalse,
          reason: '소진된 9,900원 매수 주문을 매도 주문으로 자동 변환하면 안 됩니다.',
        );
        expect(
          transitioned.bids
              .where((level) => level.price == 9900)
              .every((level) => level.quantity == 0),
          isTrue,
        );
        expect(transitioned.totalAskQuantity, lessThanOrEqualTo(490000));
        expect(
          transitioned.totalAskQuantity + transitioned.playerOwnedShares,
          lessThanOrEqualTo(outstanding),
        );
        expect(
          transitioned.asks.every((level) => level.quantity <= 200000),
          isTrue,
        );
        expect(transitioned.visibleInventoryIsConserved, isTrue);
      }
    },
  );

  test('large wall cancellations and replenishment stay inventory funded', () {
    const wallOutstanding = 500000000;
    const wallPlayerOwned = wallOutstanding * 0.51;
    GameOrderBookLevel? levelAt(
      GameOrderBookSnapshot book,
      GameOrderBookSide side,
      double price,
    ) {
      for (final level in <GameOrderBookLevel>[...book.asks, ...book.bids]) {
        if (level.side == side && (level.price - price).abs() < 0.000001) {
          return level;
        }
      }
      final remembered = book.rememberedLevels[price];
      return remembered?.side == side ? remembered : null;
    }

    var largeCancellations = 0;
    var largeReplenishments = 0;
    for (var sample = 0; sample < 60; sample += 1) {
      final day = 6015 + sample;
      var current = buildGameOrderBookSnapshot(
        assetId: 'busy-independent-wall-flow',
        day: day,
        minute: 600,
        currentPrice: 10000,
        previousTradePrice: 10000,
        previousClose: 9800,
        date: DateTime(2016, 6, 20).add(Duration(days: sample)),
        market: 'KSE',
        simulationSeed: 'busy-independent-wall-world',
        sharesOutstanding: wallOutstanding,
        playerOwnedUnits: wallPlayerOwned,
        liquidityPulse: gameOrderBookLiquidityPulseFrame(
          marketMinute: 600,
          slotIndex: 0,
        ),
        adaptiveLiquidityPulses: true,
      );
      expect(current.visibleInventoryIsConserved, isTrue);

      for (
        var slot = 1;
        slot <= gameOrderBookMaximumPulsesPerMarketMinute;
        slot += 1
      ) {
        final next = buildGameOrderBookSnapshot(
          assetId: 'busy-independent-wall-flow',
          day: day,
          minute: 600,
          currentPrice: 10000,
          previousTradePrice: 10000,
          previousClose: 9800,
          date: DateTime(2016, 6, 20).add(Duration(days: sample)),
          market: 'KSE',
          simulationSeed: 'busy-independent-wall-world',
          sharesOutstanding: wallOutstanding,
          playerOwnedUnits: wallPlayerOwned,
          previousSnapshot: current,
          previousSnapshotMinute: 600,
          liquidityPulse: gameOrderBookLiquidityPulseFrame(
            marketMinute: 600,
            slotIndex: slot,
          ),
          adaptiveLiquidityPulses: true,
        );
        expect(next.visibleInventoryIsConserved, isTrue);
        expect(
          next.totalAskQuantity + next.playerOwnedShares,
          lessThanOrEqualTo(wallOutstanding),
        );

        final side = next.lastBreathingWallSide;
        final price = side == GameOrderBookSide.ask
            ? next.breathingAskWallPrice
            : next.breathingBidWallPrice;
        if (side != null && price != null) {
          final before = levelAt(current, side, price);
          final after = levelAt(next, side, price);
          if (before != null &&
              after != null &&
              before.isWall &&
              after.isWall &&
              before.quantity > 0) {
            final ratio = (after.quantity - before.quantity) / before.quantity;
            if (ratio <= -0.06) largeCancellations += 1;
            if (ratio >= 0.03) largeReplenishments += 1;
          }
        }
        current = next;
      }
    }

    expect(
      largeCancellations,
      greaterThan(0),
      reason: 'observed replenishments: $largeReplenishments',
    );
    expect(
      largeReplenishments,
      greaterThan(0),
      reason: 'observed cancellations: $largeCancellations',
    );
  });

  test(
    'bid and ask walls are independently imbalanced rather than mirrored',
    () {
      var unequalDays = 0;
      var bidHeavyDays = 0;
      var askHeavyDays = 0;
      for (var day = 1; day <= 120; day += 1) {
        final book = snapshot(day: day, owned: 100000);
        if (book.totalBidQuantity != book.totalAskQuantity) unequalDays += 1;
        if (book.totalBidQuantity > book.totalAskQuantity) bidHeavyDays += 1;
        if (book.totalAskQuantity > book.totalBidQuantity) askHeavyDays += 1;
      }

      expect(unequalDays, greaterThan(100));
      expect(bidHeavyDays + askHeavyDays, unequalDays);
      expect(bidHeavyDays, greaterThan(0));
      expect(askHeavyDays, greaterThan(0));
    },
  );

  test(
    'one regular order follows the 5 percent or 100 million share ceiling',
    () {
      expect(gameMaximumQuoteQuantity(1000), 50);
      expect(gameMaximumQuoteQuantity(1000000), 50000);
      expect(gameMaximumQuoteQuantity(5000000000), 100000000);
    },
  );
}
