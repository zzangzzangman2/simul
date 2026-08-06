import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_liquidity_zones.dart';
import 'package:millennium_capital/game/market_technical_levels.dart';
import 'package:millennium_capital/game/order_book.dart';

void main() {
  test('displayed order book and limit fills share one liquidity capacity', () {
    final date = DateTime(2016, 6, 20);
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 17,
      currentPrice: 10000,
      previousClose: 9800,
      date: date,
      market: '미래시장',
    );

    expect(snapshot.asks.length, greaterThanOrEqualTo(gameOrderBookLevelCount));
    expect(snapshot.bids.length, greaterThanOrEqualTo(gameOrderBookLevelCount));
    expect(snapshot.asks.any((level) => level.isWall), isTrue);
    expect(snapshot.bids.any((level) => level.isWall), isTrue);
    expect(
      snapshot.executionCapacity,
      gameOrderBookExecutionCapacity(
        assetId: 'hanbit_telecom',
        day: 6015,
        minute: 10 * 60 + 17,
        unitPrice: 10000,
        previousClose: 9800,
      ),
    );
    expect(snapshot.turnoverEok, greaterThan(0));
    expect(snapshot.totalAskQuantity, greaterThan(snapshot.executionCapacity));
    expect(snapshot.totalBidQuantity, greaterThan(snapshot.executionCapacity));
    expect(snapshot.tradeStrength, inInclusiveRange(20, 240));

    final preOpen = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 8 * 60,
      currentPrice: 10000,
      previousClose: 9800,
      date: date,
      market: '미래시장',
    );
    expect(preOpen.turnoverEok, 0);
    expect(preOpen.executionCapacity, 0);

    final postClose = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: krxCloseMinute,
      currentPrice: 10000,
      previousClose: 9800,
      date: date,
      market: '미래시장',
    );
    expect(postClose.turnoverEok, greaterThan(0));
    expect(postClose.executionCapacity, 0);

    final fillPlan = gameOrderBookLimitFillPlan(
      snapshot: snapshot,
      isBuy: true,
      requestedQuantity: snapshot.executionCapacity.toDouble(),
      limitPrice: snapshot.asks[1].price,
    );
    expect(fillPlan.hasFill, isTrue);
    expect(
      fillPlan.filledQuantity,
      lessThanOrEqualTo(snapshot.executionCapacity),
    );
    expect(fillPlan.averagePrice, lessThanOrEqualTo(snapshot.asks[1].price));
    expect(fillPlan.fills, isNotEmpty);

    final holiday = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60,
      currentPrice: 10000,
      previousClose: 9800,
      date: date,
      market: '미래시장',
      tradingDay: false,
    );
    expect(holiday.turnoverEok, 0);
    expect(holiday.executionCapacity, 0);
    expect(holiday.asks, isEmpty);
    expect(holiday.bids, isEmpty);
    expect(holiday.totalAskQuantity, 0);
    expect(holiday.totalBidQuantity, 0);
  });

  test('calm best quote is 0.6 to 1.2 minute capacities deep', () {
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 17,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
      date: DateTime(2016, 6, 20),
      market: '미래시장',
      simulationSeed: 'depth-audit',
      sharesOutstanding: 10000000,
    );

    expect(snapshot.asks.first.isWall, isFalse);
    expect(
      snapshot.executionCapacity / snapshot.asks.first.quantity,
      inInclusiveRange(0.6, 1.2),
    );
  });

  test('one ten-level side is one to three percent of daily volume', () {
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 17,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
      date: DateTime(2016, 6, 20),
      market: '미래시장',
      simulationSeed: 'depth-audit',
      sharesOutstanding: 10000000,
    );
    final fullDayVolume = gameEstimatedFullDayVolumeUnits(
      assetId: 'hanbit_telecom',
      day: 6015,
      referencePrice: 10000,
      simulationSeed: 'depth-audit',
      sharesOutstanding: 10000000,
    );
    final oneSideDepth = snapshot.asks
        .take(gameOrderBookLevelCount)
        .fold<int>(0, (sum, level) => sum + level.quantity);

    expect(oneSideDepth / fullDayVolume, inInclusiveRange(0.01, 0.03));
  });
  test('price-level rate uses the previous close', () {
    expect(
      gameOrderBookPriceChangePercent(price: 81300, previousClose: 77800),
      closeTo(4.498714652956299, 0.000000001),
    );
    expect(
      gameOrderBookPriceChangePercent(price: 77500, previousClose: 77800),
      closeTo(-0.3856041131105398, 0.000000001),
    );
    expect(gameOrderBookPriceChangePercent(price: 81300, previousClose: 0), 0);
  });
  test('execution strength uses buy and sell tape quantities', () {
    expect(
      gameOrderBookExecutionStrength(buyQuantity: 300, sellQuantity: 200),
      150,
    );
    expect(
      gameOrderBookExecutionStrength(buyQuantity: 0, sellQuantity: 0),
      100,
    );
    expect(
      gameOrderBookExecutionStrength(buyQuantity: 50, sellQuantity: 0),
      999,
    );
    expect(gameOrderBookExecutionStrength(buyQuantity: 0, sellQuantity: 50), 0);
  });

  test('consumed absolute prices are removed from the net visible book', () {
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'consumption_view',
      day: 6015,
      minute: 10 * 60 + 17,
      currentPrice: 10000,
      previousClose: 10000,
      date: DateTime(2016, 6, 20),
      market: 'main',
    );
    final firstAsk = snapshot.asks.first;
    final firstBid = snapshot.bids.first;
    final net = gameOrderBookSnapshotAfterConsumption(
      snapshot: snapshot,
      consumedAskByPrice: {firstAsk.price: firstAsk.quantity.toDouble()},
      consumedBidByPrice: {firstBid.price: 2},
    );

    expect(net.asks.first.price, snapshot.asks[1].price);
    expect(net.asks, hasLength(snapshot.asks.length - 1));
    expect(net.bids.first.price, firstBid.price);
    expect(net.bids.first.quantity, firstBid.quantity - 2);
    expect(net.totalAskQuantity, snapshot.totalAskQuantity - firstAsk.quantity);
    expect(net.totalBidQuantity, snapshot.totalBidQuantity - 2);
    expect(
      net.tradeStrength,
      (net.totalBidQuantity / net.totalAskQuantity * 100)
          .clamp(20, 240)
          .toDouble(),
    );
    expect(net.rememberedLevels[firstAsk.price]!.quantity, 0);
    expect(
      net.rememberedLevels[firstBid.price]!.quantity,
      firstBid.quantity - 2,
    );
    expect(net.appliedAskConsumptionByPrice[firstAsk.price], firstAsk.quantity);
    expect(net.appliedBidConsumptionByPrice[firstBid.price], 2);

    final repeated = gameOrderBookSnapshotAfterConsumption(
      snapshot: net,
      consumedAskByPrice: {firstAsk.price: firstAsk.quantity.toDouble()},
      consumedBidByPrice: {firstBid.price: 2},
    );
    expect(
      repeated.asks.map((level) => (level.price, level.quantity)),
      net.asks.map((level) => (level.price, level.quantity)),
    );
    expect(
      repeated.bids.map((level) => (level.price, level.quantity)),
      net.bids.map((level) => (level.price, level.quantity)),
    );
    expect(repeated.totalAskQuantity, net.totalAskQuantity);
    expect(repeated.totalBidQuantity, net.totalBidQuantity);

    final incremented = gameOrderBookSnapshotAfterConsumption(
      snapshot: repeated,
      consumedAskByPrice: {firstAsk.price: firstAsk.quantity.toDouble()},
      consumedBidByPrice: {firstBid.price: 3},
    );
    expect(
      incremented.rememberedLevels[firstBid.price]!.quantity,
      firstBid.quantity - 3,
    );

    final plan = gameOrderBookLimitFillPlan(
      snapshot: snapshot,
      isBuy: true,
      requestedQuantity: 1,
      limitPrice: snapshot.asks[1].price,
      alreadyConsumedByPrice: {firstAsk.price: firstAsk.quantity.toDouble()},
    );
    expect(plan.hasFill, isTrue);
    expect(plan.fills.single.price, snapshot.asks[1].price);
  });

  test('full bid print removes the quote before a later order can arrive', () {
    const assetId = 'dense_visible_bids';
    const simulationSeed = 'dense-visible-bids';
    const day = 6015;
    const minute = 9 * 60 + 12;
    final date = DateTime(2016, 6, 20);
    final raw = buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: minute,
      currentPrice: 39450,
      previousTradePrice: 39500,
      previousClose: 39500,
      date: date,
      market: '미래시장',
      simulationSeed: simulationSeed,
      liquidityPulse: 1,
      adaptiveLiquidityPulses: true,
    );
    expect(
      raw.bids.take(gameOrderBookLevelCount).map((level) => level.price),
      <double>[
        39450,
        39400,
        39350,
        39300,
        39250,
        39200,
        39150,
        39100,
        39050,
        39000,
      ],
    );

    final best = raw.bids.first;
    final latestDepletion = gameOrderBookSnapshotAfterSyntheticTrade(
      snapshot: raw,
      pulse: GameOrderBookTradePulse(
        levelSide: GameOrderBookSide.bid,
        levelIndex: 0,
        quantity: best.quantity,
        crossedTicks: 1,
      ),
      absolutePrice: best.price,
      perMinuteBudgetUnits: best.quantity,
    );
    expect(latestDepletion.lastSyntheticTrade?.price, 39450);
    expect(
      latestDepletion.rememberedLevels[39450]!.side,
      GameOrderBookSide.bid,
    );
    expect(latestDepletion.rememberedLevels[39450]!.quantity, 0);
    expect(latestDepletion.asks.any((level) => level.price == 39450), isFalse);
    expect(
      latestDepletion.bids
          .singleWhere((level) => level.price == 39450)
          .quantity,
      0,
    );
    expect(
      gameOrderBookFirstExecutableLevel(
        snapshot: latestDepletion,
        side: GameOrderBookSide.bid,
      )?.price,
      39400,
    );

    final nextPulse = buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: minute,
      currentPrice: 39450,
      previousTradePrice: 39500,
      previousClose: 39500,
      date: date,
      market: '미래시장',
      simulationSeed: simulationSeed,
      previousSnapshot: latestDepletion,
      previousSnapshotMinute: minute,
      liquidityPulse: 2,
      adaptiveLiquidityPulses: true,
    );

    expect(nextPulse.rememberedLevels[39450]!.side, GameOrderBookSide.ask);
    expect(
      nextPulse.rememberedLevels[39450]!.quantity,
      greaterThanOrEqualTo(gameOrderBookMinimumDisplayedQuantity),
    );
    expect(
      gameOrderBookFirstExecutableLevel(
        snapshot: nextPulse,
        side: GameOrderBookSide.bid,
      )?.price,
      39400,
    );

    final productionView = gameOrderBookSnapshotAfterConsumption(
      snapshot: nextPulse,
      retainSyntheticTombstone: false,
    );
    final visibleBids = productionView.bids
        .take(gameOrderBookLevelCount)
        .toList(growable: false);
    expect(visibleBids, hasLength(gameOrderBookLevelCount));
    expect(productionView.asks.first.price, 39450);
    expect(visibleBids.first.price, 39400);
    expect(visibleBids.every((level) => level.quantity > 0), isTrue);
  });
  test(
    'twenty seeds keep live ladders positive and full-row prints within one tick',
    () {
      const day = 6015;
      const minute = 9 * 60 + 12;
      final date = DateTime(2016, 6, 20);

      for (var seedIndex = 0; seedIndex < 20; seedIndex += 1) {
        final assetId = 'one_tick_seed_$seedIndex';
        var snapshot = buildGameOrderBookSnapshot(
          assetId: assetId,
          day: day,
          minute: minute,
          currentPrice: 39450,
          previousTradePrice: 39500,
          previousClose: 39500,
          sharesOutstanding: 1000000000,
          date: date,
          market: '미래시장',
          simulationSeed: 'one-tick-world-$seedIndex',
          liquidityPulse: 1,
          adaptiveLiquidityPulses: true,
        );
        double? previousPrintPrice;

        for (var pulse = 1; pulse <= 24; pulse += 1) {
          final target = gameOrderBookFirstExecutableLevel(
            snapshot: snapshot,
            side: GameOrderBookSide.bid,
          );
          expect(target, isNotNull, reason: 'seed $seedIndex pulse $pulse');
          final executable = target!;
          if (previousPrintPrice != null) {
            final oneTickUp = gameOrderBookPriceAfterTickImpact(
              basePrice: previousPrintPrice,
              signedTicks: 1,
              market: '미래시장',
            );
            final oneTickDown = gameOrderBookPriceAfterTickImpact(
              basePrice: previousPrintPrice,
              signedTicks: -1,
              market: '미래시장',
            );
            expect(
              <double>[
                previousPrintPrice,
                oneTickUp,
                oneTickDown,
              ].any((price) => (price - executable.price).abs() < 0.000001),
              isTrue,
              reason:
                  'seed $seedIndex pulse $pulse skipped from '
                  '$previousPrintPrice to ${executable.price}',
            );
          }

          final applied = gameOrderBookSnapshotAfterSyntheticTrade(
            snapshot: snapshot,
            pulse: GameOrderBookTradePulse(
              levelSide: GameOrderBookSide.bid,
              levelIndex: 0,
              quantity: executable.quantity,
              crossedTicks: 1,
            ),
            absolutePrice: executable.price,
            previousSnapshot: snapshot,
            availableSnapshot: snapshot,
            perMinuteBudgetUnits: 0x7fffffff,
          );
          final liveView = gameOrderBookSnapshotAfterConsumption(
            snapshot: applied,
            retainSyntheticTombstone: false,
          );
          expect(
            liveView.bids
                .take(gameOrderBookLevelCount)
                .every((level) => level.quantity > 0),
            isTrue,
            reason: 'seed $seedIndex pulse $pulse rendered a zero bid row',
          );
          expect(
            liveView.bids.take(gameOrderBookLevelCount),
            hasLength(gameOrderBookLevelCount),
          );
          previousPrintPrice = executable.price;
          if (pulse == 24) break;
          snapshot = buildGameOrderBookSnapshot(
            assetId: assetId,
            day: day,
            minute: minute,
            currentPrice: 39450,
            previousTradePrice: 39500,
            previousClose: 39500,
            sharesOutstanding: 1000000000,
            date: date,
            market: '미래시장',
            simulationSeed: 'one-tick-world-$seedIndex',
            previousSnapshot: applied,
            previousSnapshotMinute: minute,
            liquidityPulse: pulse + 1,
            adaptiveLiquidityPulses: true,
          );
        }
      }
    },
  );
  test(
    'full ask prints leave the consumed price empty until a new bid arrives',
    () {
      const day = 6015;
      const minute = 9 * 60 + 14;
      const market = '코스닥';
      final date = DateTime(2016, 6, 20);

      for (var seedIndex = 0; seedIndex < 20; seedIndex += 1) {
        final assetId = 'protected_touch_$seedIndex';
        final snapshot = buildGameOrderBookSnapshot(
          assetId: assetId,
          day: day,
          minute: minute,
          currentPrice: 13400,
          previousTradePrice: 13450,
          previousClose: 13350,
          sessionLow: 13400,
          sessionHigh: 13500,
          sharesOutstanding: 1000000000,
          date: date,
          market: market,
          simulationSeed: 'protected-touch-world-$seedIndex',
          liquidityPulse: 1,
          adaptiveLiquidityPulses: true,
        );
        expect(
          snapshot.fullDayTurnoverEok,
          greaterThanOrEqualTo(gameOrderBookSparseFullDayTurnoverEok),
        );

        const pulse = 1;
        final bestBid = snapshot.bids.first;
        final expectedBestAsk = gameOrderBookPriceAfterTickImpact(
          basePrice: bestBid.price,
          signedTicks: 1,
          market: market,
        );
        expect(
          snapshot.asks.first.price,
          expectedBestAsk,
          reason: 'seed $seedIndex pulse $pulse opened a wide spread',
        );

        final bestAsk = snapshot.asks.first;
        final nextAskPrice = snapshot.asks[1].price;
        final traded = gameOrderBookSnapshotAfterSyntheticTrade(
          snapshot: snapshot,
          pulse: GameOrderBookTradePulse(
            levelSide: GameOrderBookSide.ask,
            levelIndex: 0,
            quantity: bestAsk.quantity,
            crossedTicks: 1,
          ),
          absolutePrice: bestAsk.price,
          previousSnapshot: snapshot,
          availableSnapshot: snapshot,
          perMinuteBudgetUnits: 0x7fffffff,
        );
        final liveView = gameOrderBookSnapshotAfterConsumption(
          snapshot: traded,
          retainSyntheticTombstone: false,
        );
        expect(
          liveView.asks.any((level) => level.price == bestAsk.price),
          isFalse,
          reason: 'seed $seedIndex pulse $pulse revived the consumed ask',
        );
        expect(liveView.bids.first.price, bestBid.price);
        expect(
          liveView.bids.any((level) => level.price == bestAsk.price),
          isFalse,
          reason: '완전 체결된 매도호가가 즉시 매수호가로 바뀌면 안 됩니다.',
        );
        expect(liveView.asks.first.price, nextAskPrice);
        expect(
          liveView.asks.first.price,
          greaterThan(liveView.bids.first.price),
        );
        expect(
          [...liveView.asks, ...liveView.bids]
              .where((level) => level.quantity > 0)
              .every(
                (level) =>
                    level.quantity >= gameOrderBookMinimumDisplayedQuantity,
              ),
          isTrue,
        );
      }
    },
  );
  test('player and market fills never auto-create the opposite quote', () {
    const day = 6015;
    const minute = 9 * 60 + 19;
    const market = '코스닥';
    final date = DateTime(2016, 6, 20);
    final raw = buildGameOrderBookSnapshot(
      assetId: 'player-then-market-boundary',
      day: day,
      minute: minute,
      currentPrice: 32150,
      previousTradePrice: 32150,
      previousClose: 32150,
      sessionLow: 32150,
      sessionHigh: 32200,
      sharesOutstanding: 1000000000,
      date: date,
      market: market,
      simulationSeed: 'player-then-market-world',
      liquidityPulse: 1,
      adaptiveLiquidityPulses: true,
    );
    expect(raw.asks.first.price, 32200);
    expect(
      raw.fullDayTurnoverEok,
      greaterThanOrEqualTo(gameOrderBookSeverelySparseFullDayTurnoverEok),
    );

    final afterPlayerFill = gameOrderBookSnapshotAfterConsumption(
      snapshot: raw,
      consumedAskByPrice: <double, double>{
        raw.asks.first.price: raw.asks.first.quantity.toDouble(),
      },
      consumedCapacityUnits: raw.asks.first.quantity,
      latestConsumedSide: GameOrderBookSide.ask,
      latestConsumedPrice: raw.asks.first.price,
    );
    expect(afterPlayerFill.sourceLastTradePrice, 32200);
    expect(afterPlayerFill.boundaryBidPrice, 32150);
    expect(afterPlayerFill.bids.first.price, 32150);
    expect(afterPlayerFill.asks.first.price, 32250);
    expect(afterPlayerFill.asks.any((level) => level.price == 32200), isFalse);
    expect(afterPlayerFill.bids.any((level) => level.price == 32200), isFalse);

    final nextAsk = afterPlayerFill.asks.first;
    final afterMarketFill = gameOrderBookSnapshotAfterSyntheticTrade(
      snapshot: afterPlayerFill,
      pulse: GameOrderBookTradePulse(
        levelSide: GameOrderBookSide.ask,
        levelIndex: 0,
        quantity: nextAsk.quantity,
        crossedTicks: 1,
      ),
      absolutePrice: nextAsk.price,
      previousSnapshot: afterPlayerFill,
      availableSnapshot: afterPlayerFill,
      perMinuteBudgetUnits: 0x7fffffff,
    );
    expect(afterMarketFill.sourceLastTradePrice, 32250);
    expect(afterMarketFill.boundaryBidPrice, 32150);
    expect(afterMarketFill.bids.first.price, 32150);
    expect(
      afterMarketFill.asks
          .singleWhere((level) => level.price == 32250)
          .quantity,
      0,
    );
    expect(
      gameOrderBookFirstExecutableLevel(
        snapshot: afterMarketFill,
        side: GameOrderBookSide.ask,
      )?.price,
      32300,
    );
    expect(afterMarketFill.bids.any((level) => level.price == 32250), isFalse);

    final stalePathRebuild = buildGameOrderBookSnapshot(
      assetId: 'player-then-market-boundary',
      day: day,
      minute: minute,
      currentPrice: 32150,
      previousTradePrice: 32150,
      previousClose: 32150,
      sessionLow: 32150,
      sessionHigh: 32250,
      sharesOutstanding: 1000000000,
      date: date,
      market: market,
      simulationSeed: 'player-then-market-world',
      previousSnapshot: afterMarketFill,
      previousSnapshotMinute: minute,
      liquidityPulse: 2,
      adaptiveLiquidityPulses: true,
    );
    expect(
      stalePathRebuild.asks.first.price,
      greaterThan(stalePathRebuild.bids.first.price),
    );
    expect(
      [
        ...stalePathRebuild.asks,
        ...stalePathRebuild.bids,
      ].every((level) => level.quantity > 0),
      isTrue,
    );
  });
  test(
    'a visible queue reduction cannot revive from an older carry snapshot',
    () {
      const minute = 9 * 60 + 19;
      const market = '코스닥';

      GameOrderBookSnapshot bookWithBestAsk(int bestAskQuantity) {
        final asks = <GameOrderBookLevel>[
          GameOrderBookLevel(
            side: GameOrderBookSide.ask,
            price: 32200,
            quantity: bestAskQuantity,
            isWall: true,
          ),
          const GameOrderBookLevel(
            side: GameOrderBookSide.ask,
            price: 32250,
            quantity: 240,
            isWall: false,
          ),
        ];
        const bids = <GameOrderBookLevel>[
          GameOrderBookLevel(
            side: GameOrderBookSide.bid,
            price: 32150,
            quantity: 220,
            isWall: false,
          ),
          GameOrderBookLevel(
            side: GameOrderBookSide.bid,
            price: 32100,
            quantity: 240,
            isWall: false,
          ),
        ];
        return GameOrderBookSnapshot(
          asks: asks,
          bids: bids,
          turnoverEok: 6.1,
          fullDayTurnoverEok: 33,
          boundaryBidPrice: 32150,
          executionCapacity: 10000,
          totalAskQuantity: asks.fold(0, (sum, level) => sum + level.quantity),
          totalBidQuantity: bids.fold(0, (sum, level) => sum + level.quantity),
          tradeStrength: 100,
          liquidityPulse: 9,
          adaptiveLiquidityPulses: true,
          rememberedLevels: <double, GameOrderBookLevel>{
            for (final level in [...asks, ...bids]) level.price: level,
          },
          sourceAssetId: 'cancelled-wall-regression',
          sourceLiquidityDayKey: 6015,
          sourceDateKey: marketDateKey(DateTime(2016, 6, 20)),
          sourceMarketMinute: minute,
          sourceLastTradePrice: 32150,
          sourceMarket: market,
          sourceSimulationSeed: 'cancelled-wall-world',
        );
      }

      final olderCarry = bookWithBestAsk(100);
      final currentlyVisible = bookWithBestAsk(50);
      final filled = gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: currentlyVisible,
        pulse: const GameOrderBookTradePulse(
          levelSide: GameOrderBookSide.ask,
          levelIndex: 0,
          quantity: 50,
          crossedTicks: 1,
        ),
        absolutePrice: 32200,
        previousSnapshot: olderCarry,
        availableSnapshot: currentlyVisible,
        perMinuteBudgetUnits: 10000,
      );

      expect(filled.lastSyntheticTrade?.quantity, 50);
      expect(
        filled.asks.singleWhere((level) => level.price == 32200).quantity,
        0,
      );
      expect(filled.bids.any((level) => level.price == 32200), isFalse);
      expect(
        gameOrderBookFirstExecutableLevel(
          snapshot: filled,
          side: GameOrderBookSide.ask,
        )?.price,
        32250,
      );
      expect(filled.boundaryBidPrice, 32150);

      final arrivalSuppressed = gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: bookWithBestAsk(100),
        pulse: const GameOrderBookTradePulse(
          levelSide: GameOrderBookSide.ask,
          levelIndex: 0,
          quantity: 10,
          crossedTicks: 1,
        ),
        absolutePrice: 32200,
        previousSnapshot: bookWithBestAsk(50),
        availableSnapshot: bookWithBestAsk(100),
        perMinuteBudgetUnits: 10000,
      );
      expect(
        arrivalSuppressed.asks.first.quantity,
        40,
        reason: '같은 프레임의 새 유입이 체결 아래에서 벽을 다시 채우면 안 됩니다.',
      );
    },
  );
  test('a wide legacy gap is not filled by converting the executed order', () {
    const market = '코스닥';
    const minute = 9 * 60 + 19;
    final asks = <GameOrderBookLevel>[
      for (var index = 0; index < 12; index += 1)
        GameOrderBookLevel(
          side: GameOrderBookSide.ask,
          price: 32500 + index * 50,
          quantity: index == 0 ? 100 : 240,
          isWall: index == 0,
        ),
    ];
    final bids = <GameOrderBookLevel>[
      for (var index = 0; index < 12; index += 1)
        GameOrderBookLevel(
          side: GameOrderBookSide.bid,
          price: 32150 - index * 50,
          quantity: 220,
          isWall: false,
        ),
    ];
    final legacyGap = GameOrderBookSnapshot(
      asks: asks,
      bids: bids,
      turnoverEok: 6.1,
      fullDayTurnoverEok: 33,
      boundaryBidPrice: 32150,
      executionCapacity: 10000,
      totalAskQuantity: asks.fold(0, (sum, level) => sum + level.quantity),
      totalBidQuantity: bids.fold(0, (sum, level) => sum + level.quantity),
      tradeStrength: 100,
      liquidityPulse: 10,
      adaptiveLiquidityPulses: true,
      rememberedLevels: <double, GameOrderBookLevel>{
        for (final level in [...asks, ...bids]) level.price: level,
        for (var price = 32200; price < 32500; price += 50)
          price.toDouble(): GameOrderBookLevel(
            side: GameOrderBookSide.ask,
            price: price.toDouble(),
            quantity: 0,
            isWall: false,
          ),
      },
      sourceAssetId: 'legacy-gap-32150-32500',
      sourceLiquidityDayKey: 6015,
      sourceDateKey: marketDateKey(DateTime(2016, 6, 20)),
      sourceMarketMinute: minute,
      sourceLastTradePrice: 32200,
      sourceMarket: market,
      sourceSimulationSeed: 'legacy-gap-world',
    );

    expect(
      gameOrderBookPriceAfterTickImpact(
        basePrice: 32150,
        signedTicks: 1,
        market: market,
      ),
      32200,
    );

    final filled32500 = gameOrderBookSnapshotAfterSyntheticTrade(
      snapshot: legacyGap,
      pulse: const GameOrderBookTradePulse(
        levelSide: GameOrderBookSide.ask,
        levelIndex: 0,
        quantity: 100,
        crossedTicks: 1,
      ),
      absolutePrice: 32500,
      previousSnapshot: legacyGap,
      availableSnapshot: legacyGap,
      perMinuteBudgetUnits: 10000,
    );
    expect(filled32500.sourceLastTradePrice, 32500);
    expect(filled32500.boundaryBidPrice, 32150);
    expect(filled32500.bids.first.price, 32150);
    expect(
      gameOrderBookFirstExecutableLevel(
        snapshot: filled32500,
        side: GameOrderBookSide.ask,
      )?.price,
      32550,
    );
    expect(
      filled32500.asks.singleWhere((level) => level.price == 32500).quantity,
      0,
    );
    expect(
      filled32500.bids.any((level) => level.price == 32500),
      isFalse,
      reason: '체결된 32,500원 매도 주문이 매수 주문으로 자동 변환되면 안 됩니다.',
    );

    final rebuilt = buildGameOrderBookSnapshot(
      assetId: 'legacy-gap-32150-32500',
      day: 6015,
      minute: minute,
      currentPrice: 32150,
      previousTradePrice: 32200,
      previousClose: 32200,
      sessionLow: 32150,
      sessionHigh: 32500,
      sharesOutstanding: 1000000000,
      date: DateTime(2016, 6, 20),
      market: market,
      simulationSeed: 'legacy-gap-world',
      previousSnapshot: filled32500,
      previousSnapshotMinute: minute,
      liquidityPulse: 11,
      adaptiveLiquidityPulses: true,
    );
    expect(rebuilt.sourceLastTradePrice, 32500);
    expect(rebuilt.asks.first.price, greaterThan(rebuilt.bids.first.price));
    expect(
      [...rebuilt.asks, ...rebuilt.bids].every((level) => level.quantity > 0),
      isTrue,
    );
  });

  test('new minute cannot rewind the boundary without executable fills', () {
    const minute = krxCloseMinute - 1;
    final previous = buildGameOrderBookSnapshot(
      assetId: 'no-teleport-boundary',
      day: 6015,
      minute: minute,
      currentPrice: 32500,
      previousTradePrice: 32450,
      previousClose: 32200,
      sharesOutstanding: 1000000000,
      date: DateTime(2016, 6, 20),
      market: '코스닥',
      simulationSeed: 'no-teleport-world',
    );
    final afterClose = buildGameOrderBookSnapshot(
      assetId: 'no-teleport-boundary',
      day: 6015,
      minute: krxCloseMinute,
      currentPrice: 32150,
      previousTradePrice: 32200,
      previousClose: 32200,
      sharesOutstanding: 1000000000,
      date: DateTime(2016, 6, 20),
      market: '코스닥',
      simulationSeed: 'no-teleport-world',
      previousSnapshot: previous,
      previousSnapshotMinute: minute,
    );

    expect(afterClose.executionCapacity, 0);
    expect(afterClose.sourceLastTradePrice, previous.sourceLastTradePrice);
    expect(afterClose.bids.first.price, previous.bids.first.price);
    expect(afterClose.asks.first.price, previous.asks.first.price);
  });

  test(
    '24500 ask-wall breakout cannot rewind to 24300 without sequential bid fills',
    () {
      const assetId = '24500-no-rewind';
      const simulationSeed = '24500-no-rewind-world';
      const market = '미래시장';
      const day = 6015;
      const minute = 10 * 60 + 13;
      final date = DateTime(2016, 6, 20);

      List<GameOrderBookLevel> ladder(
        GameOrderBookSide side,
        double firstPrice,
        double step, {
        double? wallPrice,
      }) => List<GameOrderBookLevel>.generate(12, (index) {
        final price = firstPrice + step * index;
        final isWall = wallPrice != null && price == wallPrice;
        return GameOrderBookLevel(
          side: side,
          price: price,
          quantity: isWall ? 50 : 20,
          isWall: isWall,
        );
      });

      GameOrderBookSnapshot snapshotAt({
        required double price,
        required List<GameOrderBookLevel> asks,
        required List<GameOrderBookLevel> bids,
        required int pulse,
      }) => GameOrderBookSnapshot(
        asks: asks,
        bids: bids,
        turnoverEok: 12,
        fullDayTurnoverEok: 80,
        boundaryBidPrice: price,
        executionCapacity: 10000,
        totalAskQuantity: asks.fold(0, (sum, level) => sum + level.quantity),
        totalBidQuantity: bids.fold(0, (sum, level) => sum + level.quantity),
        tradeStrength: 100,
        liquidityPulse: pulse,
        adaptiveLiquidityPulses: true,
        rememberedLevels: <double, GameOrderBookLevel>{
          for (final level in [...asks, ...bids]) level.price: level,
        },
        sourceAssetId: assetId,
        sourceLiquidityDayKey: day,
        sourceDateKey: marketDateKey(date),
        sourceMarketMinute: minute,
        sourceLastTradePrice: price,
        sourceMarket: market,
        sourceSimulationSeed: simulationSeed,
      );

      final openingAsks = ladder(
        GameOrderBookSide.ask,
        24050,
        50,
        wallPrice: 24500,
      );
      final opening = snapshotAt(
        price: 24000,
        asks: openingAsks,
        bids: ladder(GameOrderBookSide.bid, 24000, -50),
        pulse: 10,
      );
      final upwardCapacity = openingAsks
          .where((level) => level.price <= 24500)
          .fold<int>(0, (sum, level) => sum + level.quantity);
      final breakout = gameOrderBookPriceTransitionTowardTarget(
        snapshot: opening,
        previousPrice: 24000,
        targetPrice: 24500,
        availableUnits: upwardCapacity,
        market: market,
      );

      expect(breakout.price, 24500);
      expect(breakout.targetReached, isTrue);
      expect(
        breakout.orderedFills.map((fill) => fill.price),
        orderedEquals(<double>[
          for (var price = 24050; price <= 24500; price += 50) price.toDouble(),
        ]),
      );
      expect(breakout.orderedFills.last.boundaryCrossed, isTrue);
      expect(
        openingAsks.singleWhere((level) => level.price == 24500).isWall,
        isTrue,
      );

      final postBreakout = snapshotAt(
        price: 24500,
        asks: ladder(GameOrderBookSide.ask, 24550, 50),
        bids: ladder(GameOrderBookSide.bid, 24500, -50),
        pulse: 11,
      );
      final sameMinuteTargetRewind = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: 24300,
        previousTradePrice: 24000,
        previousClose: 24000,
        sessionLow: 24000,
        sessionHigh: 24500,
        sharesOutstanding: 1000000000,
        date: date,
        market: market,
        simulationSeed: simulationSeed,
        previousSnapshot: postBreakout,
        previousSnapshotMinute: minute,
        liquidityPulse: 12,
        adaptiveLiquidityPulses: true,
        holdSameMinuteBoundaryUntilExecution: true,
      );

      expect(sameMinuteTargetRewind.sourceLastTradePrice, 24500);
      expect(sameMinuteTargetRewind.boundaryBidPrice, 24500);
      expect(sameMinuteTargetRewind.bids.first.price, 24500);
      expect(sameMinuteTargetRewind.asks.first.price, 24550);
      expect(sameMinuteTargetRewind.sweepSteps, isEmpty);

      final noSellExecution = gameOrderBookPriceTransitionTowardTarget(
        snapshot: postBreakout,
        previousPrice: 24500,
        targetPrice: 24300,
        availableUnits: 0,
        market: market,
      );
      expect(noSellExecution.price, 24500);
      expect(noSellExecution.orderedFills, isEmpty);

      final partialBestBid = gameOrderBookPriceTransitionTowardTarget(
        snapshot: postBreakout,
        previousPrice: 24500,
        targetPrice: 24300,
        availableUnits: 10,
        market: market,
      );
      expect(partialBestBid.price, 24500);
      expect(partialBestBid.orderedFills, hasLength(1));
      expect(partialBestBid.orderedFills.single.boundaryCrossed, isFalse);

      final legitimateDrop = gameOrderBookPriceTransitionTowardTarget(
        snapshot: postBreakout,
        previousPrice: 24500,
        targetPrice: 24300,
        availableUnits: 81,
        market: market,
      );
      expect(legitimateDrop.price, 24300);
      expect(legitimateDrop.targetReached, isTrue);
      expect(
        legitimateDrop.orderedFills.map((fill) => fill.price),
        orderedEquals(const <double>[24500, 24450, 24400, 24350, 24300]),
      );
      expect(
        legitimateDrop.orderedFills
            .take(4)
            .every((fill) => fill.boundaryCrossed),
        isTrue,
      );
      expect(legitimateDrop.orderedFills.last.boundaryCrossed, isFalse);
      expect(legitimateDrop.orderedFills.last.remainingQuantity, 19);
    },
  );
  test(
    'net book promotes deeper prices and keeps ten asks and bids after exhaustion',
    () {
      final snapshot = buildGameOrderBookSnapshot(
        assetId: 'consumed_symmetric_window',
        day: 6015,
        minute: 10 * 60 + 13,
        currentPrice: 10000,
        previousTradePrice: 10000,
        previousClose: 9800,
        date: DateTime(2016, 6, 20),
        market: '미래시장',
        simulationSeed: 'consumed-symmetric-window',
        levelCount: gameOrderBookLevelCount + 4,
      );
      expect(
        snapshot.asks.length,
        greaterThanOrEqualTo(gameOrderBookLevelCount),
      );
      expect(
        snapshot.bids.length,
        greaterThanOrEqualTo(gameOrderBookLevelCount),
      );

      final consumedAsks = <double, double>{
        for (final level in snapshot.asks.take(4))
          level.price: level.quantity.toDouble(),
      };
      final consumedBids = <double, double>{
        for (final level in snapshot.bids.take(4))
          level.price: level.quantity.toDouble(),
      };
      final net = gameOrderBookSnapshotAfterConsumption(
        snapshot: snapshot,
        consumedAskByPrice: consumedAsks,
        consumedBidByPrice: consumedBids,
      );
      final visibleAsks = net.asks
          .take(gameOrderBookLevelCount)
          .toList(growable: false);
      final visibleBids = net.bids
          .take(gameOrderBookLevelCount)
          .toList(growable: false);

      expect(visibleAsks, hasLength(gameOrderBookLevelCount));
      expect(visibleBids, hasLength(gameOrderBookLevelCount));
      expect(
        visibleAsks.every(
          (level) => level.side == GameOrderBookSide.ask && level.quantity > 0,
        ),
        isTrue,
      );
      expect(
        visibleBids.every(
          (level) => level.side == GameOrderBookSide.bid && level.quantity > 0,
        ),
        isTrue,
      );
      expect(visibleAsks.first.price, snapshot.asks[4].price);
      expect(visibleBids.first.price, snapshot.bids[4].price);
      expect(visibleAsks.last.price, snapshot.asks[13].price);
      expect(visibleBids.last.price, snapshot.bids[13].price);
    },
  );

  test('one-sided net depth reports maximum buy-side trade strength', () {
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'one_sided_strength',
      day: 6015,
      minute: 10 * 60 + 17,
      currentPrice: 10000,
      previousClose: 10000,
      date: DateTime(2016, 6, 20),
      market: 'main',
    );
    final net = gameOrderBookSnapshotAfterConsumption(
      snapshot: snapshot,
      consumedAskByPrice: {
        for (final level in snapshot.asks)
          level.price: level.quantity.toDouble(),
      },
    );

    expect(net.asks, isEmpty);
    expect(net.bids, isNotEmpty);
    expect(net.tradeStrength, 240);

    final empty = gameOrderBookSnapshotAfterConsumption(
      snapshot: net,
      consumedBidByPrice: {
        for (final level in snapshot.bids)
          level.price: level.quantity.toDouble(),
      },
    );
    expect(empty.asks, isEmpty);
    expect(empty.bids, isEmpty);
    expect(empty.tradeStrength, 100);
  });

  test(
    'dynamic raw depth leaves ten asks and bids after five-plus level fills',
    () {
      const assetId = 'deep_execution_reserve';
      const simulationSeed = 'deep-execution-reserve';
      const day = 6015;
      const minute = 10 * 60 + 17;
      final date = DateTime(2016, 6, 20);
      final base = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: 10000,
        previousClose: 10000,
        date: date,
        market: 'main',
        simulationSeed: simulationSeed,
      );

      GameOrderBookLevel thin(GameOrderBookLevel level) => GameOrderBookLevel(
        side: level.side,
        price: level.price,
        quantity: 1,
        isWall: level.isWall,
        structuralKind: level.structuralKind,
        structuralStrength: level.structuralStrength,
        structuralHoldTicks: level.structuralHoldTicks,
        isStructuralWall: level.isStructuralWall,
        isStructuralBreached: level.isStructuralBreached,
        structuralVacuumMultiplier: level.structuralVacuumMultiplier,
        isPsychological: level.isPsychological,
        technicalPeriods: level.technicalPeriods,
        wasLiquidityPulseTouched: level.wasLiquidityPulseTouched,
      );

      final thinAsks = base.asks.map(thin).toList(growable: false);
      final thinBids = base.bids.map(thin).toList(growable: false);
      final thinPrevious = GameOrderBookSnapshot(
        asks: thinAsks,
        bids: thinBids,
        turnoverEok: base.turnoverEok,
        executionCapacity: base.executionCapacity,
        totalAskQuantity: thinAsks.length,
        totalBidQuantity: thinBids.length,
        tradeStrength: 100,
        rememberedLevels: {
          for (final level in [...thinAsks, ...thinBids]) level.price: level,
        },
      );
      final snapshot = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: 10000,
        previousClose: 10000,
        date: date,
        market: 'main',
        simulationSeed: simulationSeed,
        previousSnapshot: thinPrevious,
        previousSnapshotMinute: minute,
      );
      final askPlan = gameOrderBookLimitFillPlan(
        snapshot: snapshot,
        isBuy: true,
        requestedQuantity: snapshot.executionCapacity.toDouble(),
        limitPrice: snapshot.asks.last.price,
      );
      final bidPlan = gameOrderBookLimitFillPlan(
        snapshot: snapshot,
        isBuy: false,
        requestedQuantity: snapshot.executionCapacity.toDouble(),
        limitPrice: snapshot.bids.last.price,
      );

      expect(askPlan.fills.length, greaterThanOrEqualTo(5));
      expect(bidPlan.fills.length, greaterThanOrEqualTo(5));
      final net = gameOrderBookSnapshotAfterConsumption(
        snapshot: snapshot,
        consumedAskByPrice: {
          for (final fill in askPlan.fills)
            fill.price: fill.quantity.toDouble(),
        },
        consumedBidByPrice: {
          for (final fill in bidPlan.fills)
            fill.price: fill.quantity.toDouble(),
        },
      );
      expect(
        net.asks.take(gameOrderBookLevelCount),
        hasLength(gameOrderBookLevelCount),
      );
      expect(
        net.bids.take(gameOrderBookLevelCount),
        hasLength(gameOrderBookLevelCount),
      );
      expect(net.asks.every((level) => level.quantity > 0), isTrue);
      expect(net.bids.every((level) => level.quantity > 0), isTrue);
    },
  );

  test(
    'same frame stays idempotent but next pulse admits a small new queue',
    () {
      const assetId = 'zero_depth_carry';
      const simulationSeed = 'zero-depth-carry';
      const day = 6015;
      const minute = 10 * 60 + 17;
      final date = DateTime(2016, 6, 20);
      final raw = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: 10000,
        previousClose: 10000,
        date: date,
        market: 'main',
        simulationSeed: simulationSeed,
        liquidityPulse: 1,
        adaptiveLiquidityPulses: true,
      );
      final pulseTwoTemplate = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: 10000,
        previousClose: 10000,
        date: date,
        market: 'main',
        simulationSeed: simulationSeed,
        liquidityPulse: 2,
        adaptiveLiquidityPulses: true,
      );
      final exhausted = raw.asks.firstWhere(
        (level) =>
            !level.isStructuralBreached &&
            level.structuralVacuumMultiplier >= 0.999999 &&
            !(pulseTwoTemplate
                    .rememberedLevels[level.price]
                    ?.wasLiquidityPulseTouched ??
                true),
      );
      final net = gameOrderBookSnapshotAfterConsumption(
        snapshot: raw,
        consumedAskByPrice: {exhausted.price: exhausted.quantity.toDouble()},
      );
      expect(net.rememberedLevels[exhausted.price]!.quantity, 0);

      GameOrderBookSnapshot carriedAtPulse(int pulse) =>
          buildGameOrderBookSnapshot(
            assetId: assetId,
            day: day,
            minute: minute,
            currentPrice: 10000,
            previousClose: 10000,
            date: date,
            market: 'main',
            simulationSeed: simulationSeed,
            previousSnapshot: net,
            previousSnapshotMinute: minute,
            liquidityPulse: pulse,
            adaptiveLiquidityPulses: true,
          );

      final samePulse = carriedAtPulse(1);
      expect(samePulse.rememberedLevels[exhausted.price]!.quantity, 0);

      final nextPulse = carriedAtPulse(2);
      final replenished = nextPulse.rememberedLevels[exhausted.price]!;
      expect(replenished.wasLiquidityPulseTouched, isFalse);
      expect(replenished.quantity, greaterThan(0));
      expect(replenished.quantity, lessThan(exhausted.quantity));
    },
  );
  test(
    'minute carry adds a small new queue and resets consumption watermarks',
    () {
      const assetId = 'minute_net_carry';
      const simulationSeed = 'minute-net-carry';
      const day = 6015;
      const minute = 10 * 60 + 17;
      final date = DateTime(2016, 6, 20);
      final raw = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: 10000,
        previousClose: 10000,
        date: date,
        market: 'main',
        simulationSeed: simulationSeed,
        liquidityPulse: 7,
        adaptiveLiquidityPulses: true,
      );
      final exhausted = raw.asks.firstWhere(
        (level) =>
            !level.isWall &&
            !level.isStructuralWall &&
            !level.isStructuralBreached &&
            level.structuralVacuumMultiplier >= 0.999999,
      );
      final net = gameOrderBookSnapshotAfterConsumption(
        snapshot: raw,
        consumedAskByPrice: {exhausted.price: exhausted.quantity.toDouble()},
        consumedCapacityUnits: 7,
      );
      expect(net.rememberedLevels[exhausted.price]!.quantity, 0);
      expect(net.appliedAskConsumptionByPrice, isNotEmpty);
      expect(net.appliedCapacityConsumptionUnits, 7);

      final nextMinute = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute + 1,
        currentPrice: 10000,
        previousClose: 10000,
        date: date,
        market: 'main',
        simulationSeed: simulationSeed,
        previousSnapshot: net,
        previousSnapshotMinute: minute,
        liquidityPulse: 7,
        adaptiveLiquidityPulses: true,
      );

      final replenished = nextMinute.rememberedLevels[exhausted.price]!;
      expect(replenished.quantity, greaterThan(0));
      expect(replenished.quantity, lessThan(exhausted.quantity));
      expect(nextMinute.appliedAskConsumptionByPrice, isEmpty);
      expect(nextMinute.appliedBidConsumptionByPrice, isEmpty);
      expect(nextMinute.appliedCapacityConsumptionUnits, 0);
    },
  );

  test('new queue arrivals scale with turnover', () {
    const assetId = 'arrival_activity_scale';
    const simulationSeed = 'arrival-activity-scale';
    const day = 6015;
    const minute = 10 * 60 + 17;
    final date = DateTime(2016, 6, 20);

    int nextQueue({
      required int sharesOutstanding,
      required double currentPrice,
      required double previousTradePrice,
    }) {
      final raw = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: currentPrice,
        previousTradePrice: previousTradePrice,
        previousClose: 10000,
        date: date,
        market: 'main',
        simulationSeed: simulationSeed,
        sharesOutstanding: sharesOutstanding,
        liquidityPulse: 1,
        adaptiveLiquidityPulses: true,
      );
      final exhausted = raw.bids.firstWhere(
        (level) =>
            !level.isWall &&
            !level.isStructuralWall &&
            !level.isStructuralBreached &&
            level.structuralVacuumMultiplier >= 0.999999,
      );
      final net = gameOrderBookSnapshotAfterConsumption(
        snapshot: raw,
        consumedBidByPrice: {exhausted.price: exhausted.quantity.toDouble()},
      );
      final next = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: currentPrice,
        previousTradePrice: previousTradePrice,
        previousClose: 10000,
        date: date,
        market: 'main',
        simulationSeed: simulationSeed,
        sharesOutstanding: sharesOutstanding,
        previousSnapshot: net,
        previousSnapshotMinute: minute,
        liquidityPulse: 2,
        adaptiveLiquidityPulses: true,
      );
      final arrival = next.rememberedLevels[exhausted.price]!.quantity;
      expect(arrival, greaterThan(0));
      expect(arrival, lessThan(exhausted.quantity));
      return arrival;
    }

    final lowTurnover = nextQueue(
      sharesOutstanding: 1000000,
      currentPrice: 10000,
      previousTradePrice: 10000,
    );
    final highTurnover = nextQueue(
      sharesOutstanding: 50000000,
      currentPrice: 10000,
      previousTradePrice: 10000,
    );
    expect(highTurnover, greaterThan(lowTurnover));
  });
  test('ordinary swept quote rebuilds on selected calm and fast pulses', () {
    const day = 6015;
    const minute = 10 * 60 + 17;
    final date = DateTime(2016, 6, 20);
    final scenarios =
        <({String name, double currentPrice, double previousTradePrice})>[
          (name: 'calm', currentPrice: 10000, previousTradePrice: 10000),
          (name: 'fast', currentPrice: 10150, previousTradePrice: 10000),
        ];

    for (final scenario in scenarios) {
      GameOrderBookSnapshot? initial;
      GameOrderBookLevel? swept;
      var selectedAssetId = '';
      var selectedSeed = '';

      for (var index = 0; index < 80 && initial == null; index += 1) {
        final assetId = 'ordinary_recovery_${scenario.name}_$index';
        final seed = 'ordinary-recovery-${scenario.name}-$index';
        final candidate = buildGameOrderBookSnapshot(
          assetId: assetId,
          day: day,
          minute: minute,
          currentPrice: scenario.currentPrice,
          previousTradePrice: scenario.previousTradePrice,
          previousClose: 10000,
          date: date,
          market: '미래시장',
          simulationSeed: seed,
          sharesOutstanding: 120000000,
          liquidityPulse: 1,
          adaptiveLiquidityPulses: true,
        );
        final nearOrdinary = candidate.asks.asMap().entries.where(
          (entry) =>
              entry.key == 0 &&
              !entry.value.isWall &&
              !entry.value.isStructuralBreached &&
              entry.value.structuralVacuumMultiplier >= 0.999999,
        );
        if (nearOrdinary.isEmpty) continue;
        initial = candidate;
        swept = nearOrdinary.first.value;
        selectedAssetId = assetId;
        selectedSeed = seed;
      }

      expect(initial, isNotNull, reason: scenario.name);
      final startingBook = initial!;
      final original = swept!;
      var carried = gameOrderBookSnapshotAfterConsumption(
        snapshot: startingBook,
        consumedAskByPrice: {original.price: original.quantity.toDouble()},
      );
      expect(carried.rememberedLevels[original.price]!.quantity, 0);
      expect(
        carried.rememberedLevels[original.price]!.queueRecoveryTargetQuantity,
        original.quantity,
      );

      var selectedGrowthPulses = 0;
      for (var pulse = 2; pulse <= 160; pulse += 1) {
        final beforeLevel = carried.rememberedLevels[original.price]!;
        final next = buildGameOrderBookSnapshot(
          assetId: selectedAssetId,
          day: day,
          minute: minute,
          currentPrice: scenario.currentPrice,
          previousTradePrice: scenario.previousTradePrice,
          previousClose: 10000,
          date: date,
          market: '미래시장',
          simulationSeed: selectedSeed,
          sharesOutstanding: 120000000,
          previousSnapshot: carried,
          previousSnapshotMinute: minute,
          liquidityPulse: pulse,
          adaptiveLiquidityPulses: true,
        );
        final nextLevel = next.rememberedLevels[original.price]!;
        if (beforeLevel.quantity > 0 && !nextLevel.wasLiquidityPulseTouched) {
          expect(
            nextLevel.quantity,
            beforeLevel.quantity,
            reason: '${scenario.name}: 선택되지 않은 복구 큐가 다른 행과 함께 자라면 안 됩니다.',
          );
        }
        if (beforeLevel.queueRecoveryTargetQuantity > 0) {
          expect(
            nextLevel.quantity,
            lessThanOrEqualTo(beforeLevel.queueRecoveryTargetQuantity),
            reason: '${scenario.name}: 복구 중인 일반 큐가 목표량을 건너뛰면 안 됩니다.',
          );
        }
        if (beforeLevel.quantity > 0 &&
            nextLevel.wasLiquidityPulseTouched &&
            nextLevel.quantity > beforeLevel.quantity) {
          selectedGrowthPulses += 1;
        }
        carried = next;
        if (nextLevel.queueRecoveryTargetQuantity == 0 &&
            nextLevel.quantity >= (original.quantity * 0.70).ceil()) {
          break;
        }
      }
      expect(selectedGrowthPulses, greaterThan(0), reason: scenario.name);
      final recoveryTarget = original.quantity;
      final recovered = carried.rememberedLevels[original.price]!;

      expect(
        recovered.quantity,
        greaterThanOrEqualTo((recoveryTarget * 0.70).ceil()),
        reason: '${scenario.name}: 일반 호가는 첫 재유입 뒤 선택된 펄스에서 실용적 두께로 돌아와야 합니다.',
      );
      expect(
        recovered.quantity,
        lessThanOrEqualTo(original.quantity),
        reason: '${scenario.name}: 복구 큐가 소진 전 원래 주문량을 넘으면 안 됩니다.',
      );
    }
  });
  test('queue arrival proximity follows the best-to-row-ten decay curve', () {
    expect(
      gameOrderBookQueueArrivalProximity(0) /
          gameOrderBookQueueArrivalProximity(9),
      greaterThanOrEqualTo(5.9),
    );

    const day = 6015;
    const minute = 10 * 60 + 17;
    final date = DateTime(2016, 6, 20);
    GameOrderBookSnapshot? initial;
    var selectedAssetId = '';
    var selectedSeed = '';

    bool ordinary(GameOrderBookLevel level) =>
        !level.isWall &&
        !level.isStructuralBreached &&
        level.structuralVacuumMultiplier >= 0.999999;

    for (var index = 0; index < 120 && initial == null; index += 1) {
      final assetId = 'distance_recovery_$index';
      final seed = 'distance-recovery-$index';
      final candidate = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: 10000,
        previousTradePrice: 10000,
        previousClose: 10000,
        date: date,
        market: '미래시장',
        simulationSeed: seed,
        sharesOutstanding: 120000000,
        liquidityPulse: 1,
        adaptiveLiquidityPulses: true,
      );
      if (candidate.asks.length < gameOrderBookLevelCount) continue;
      final indexed = candidate.asks.asMap().entries;
      final nearOrdinary = indexed.where(
        (entry) => entry.key < 2 && ordinary(entry.value),
      );
      final farOrdinary = indexed.where(
        (entry) =>
            entry.key >= gameOrderBookLevelCount - 2 &&
            entry.key < gameOrderBookLevelCount &&
            ordinary(entry.value),
      );
      if (nearOrdinary.isEmpty || farOrdinary.isEmpty) continue;
      initial = candidate;
      selectedAssetId = assetId;
      selectedSeed = seed;
    }

    expect(initial, isNotNull);
    final startingBook = initial!;
    final indexed = startingBook.asks.asMap().entries;
    final nearEntry = indexed.firstWhere(
      (entry) => entry.key < 2 && ordinary(entry.value),
    );
    final farEntry = indexed.firstWhere(
      (entry) =>
          entry.key >= gameOrderBookLevelCount - 2 &&
          entry.key < gameOrderBookLevelCount &&
          ordinary(entry.value),
    );
    final near = nearEntry.value;
    final far = farEntry.value;
    GameOrderBookSnapshot rebuildAfterExhausting(
      Map<double, double> consumedAskByPrice,
    ) {
      final exhausted = gameOrderBookSnapshotAfterConsumption(
        snapshot: startingBook,
        consumedAskByPrice: consumedAskByPrice,
      );
      return buildGameOrderBookSnapshot(
        assetId: selectedAssetId,
        day: day,
        minute: minute,
        currentPrice: 10000,
        previousTradePrice: 10000,
        previousClose: 10000,
        date: date,
        market: '미래시장',
        simulationSeed: selectedSeed,
        sharesOutstanding: 120000000,
        previousSnapshot: exhausted,
        previousSnapshotMinute: minute,
        liquidityPulse: 2,
        adaptiveLiquidityPulses: true,
      );
    }

    final template = buildGameOrderBookSnapshot(
      assetId: selectedAssetId,
      day: day,
      minute: minute,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
      date: date,
      market: '미래시장',
      simulationSeed: selectedSeed,
      sharesOutstanding: 120000000,
      liquidityPulse: 2,
      adaptiveLiquidityPulses: true,
    );
    final together = rebuildAfterExhausting({
      near.price: near.quantity.toDouble(),
      far.price: far.quantity.toDouble(),
    });
    final competingLevels = [
      together.rememberedLevels[near.price]!,
      together.rememberedLevels[far.price]!,
    ];
    expect(
      competingLevels.any((level) => !level.wasLiquidityPulseTouched),
      isTrue,
    );
    for (final level in competingLevels) {
      if (!level.wasLiquidityPulseTouched) {
        expect(
          level.quantity,
          0,
          reason: '여러 소진 가격은 선택되지 않은 행까지 한 번에 재생성되면 안 됩니다.',
        );
      }
    }

    final nearNext = rebuildAfterExhausting({
      near.price: near.quantity.toDouble(),
    });
    final farNext = rebuildAfterExhausting({
      far.price: far.quantity.toDouble(),
    });
    final nearArrival = nearNext.rememberedLevels[near.price]!.quantity;
    final farArrival = farNext.rememberedLevels[far.price]!.quantity;
    final nearTarget = template.rememberedLevels[near.price]!.quantity;
    final farTarget = template.rememberedLevels[far.price]!.quantity;
    final actualRatio = (nearArrival / nearTarget) / (farArrival / farTarget);
    final expectedRatio =
        gameOrderBookQueueArrivalProximity(nearEntry.key) /
        gameOrderBookQueueArrivalProximity(farEntry.key);

    expect(nearArrival, greaterThan(0));
    expect(farArrival, greaterThan(0));
    expect(
      actualRatio,
      inInclusiveRange(expectedRatio * 0.85, expectedRatio * 1.15),
      reason: '소진 호가의 정규화 재유입률은 거리 감쇠 곡선을 따라야 합니다.',
    );
  });
  test('sparse stocks keep internal price gaps and market IOC skips them', () {
    const day = 6015;
    const minute = 10 * 60 + 17;
    final date = DateTime(2016, 6, 20);
    GameOrderBookSnapshot? sparse;
    GameOrderBookLevel? skippedAsk;

    for (var index = 0; index < 300 && sparse == null; index += 1) {
      final assetId = 'sparse_gap_$index';
      final seed = 'sparse-gap-$index';
      final candidate = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: 10000,
        previousTradePrice: 10000,
        previousClose: 10000,
        date: date,
        market: '미래시장',
        simulationSeed: seed,
        sharesOutstanding: 100000,
        liquidityPulse: 1,
        adaptiveLiquidityPulses: true,
      );
      if (candidate.asks.length < gameOrderBookLevelCount ||
          candidate.executionCapacity <= candidate.asks.first.quantity) {
        continue;
      }
      final first = candidate.asks.first;
      final second = candidate.asks[1];
      final tick = marketTickSize(first.price, market: '미래시장');
      if (second.price <= first.price + tick + 0.000001) continue;
      final internalGap = candidate.rememberedLevels.values.where(
        (level) =>
            level.side == GameOrderBookSide.ask &&
            level.quantity == 0 &&
            level.price > first.price &&
            level.price < second.price,
      );
      if (internalGap.isEmpty) continue;
      sparse = candidate;
      skippedAsk = internalGap.first;
    }

    expect(sparse, isNotNull);
    final book = sparse!;
    expect(book.asks.take(gameOrderBookLevelCount), hasLength(10));
    expect(book.bids.take(gameOrderBookLevelCount), hasLength(10));
    expect(book.asks.every((level) => level.quantity > 0), isTrue);
    expect(book.bids.every((level) => level.quantity > 0), isTrue);
    expect(skippedAsk!.quantity, 0);
    final plan = gameOrderBookLimitFillPlan(
      snapshot: book,
      isBuy: true,
      requestedQuantity: book.executionCapacity.toDouble(),
      limitPrice: book.asks[1].price,
      availableCapacity: book.executionCapacity,
      maximumNotional: 2000000000,
    );

    expect(plan.fills, hasLength(greaterThanOrEqualTo(2)));
    expect(plan.fills.first.price, book.asks.first.price);
    expect(plan.fills[1].price, book.asks[1].price);
    expect(
      plan.fills.any(
        (fill) => (fill.price - skippedAsk!.price).abs() < 0.000001,
      ),
      isFalse,
      reason: 'IOC는 내부 0주 가격을 체결로 만들지 않고 다음 양수 호가로 넘어가야 합니다.',
    );
  });
  test('low and high prices receive comparable notional capacity', () {
    const assetId = 'liquidity_capacity_probe';
    const simulationSeed = 'liquidity-price-scale';
    const day = 6015;
    const minute = 10 * 60 + 17;
    final lowPriceCapacity = gameOrderBookExecutionCapacity(
      assetId: assetId,
      day: day,
      minute: minute,
      unitPrice: 120,
      previousClose: 120,
      simulationSeed: simulationSeed,
    );
    final highPriceCapacity = gameOrderBookExecutionCapacity(
      assetId: assetId,
      day: day,
      minute: minute,
      unitPrice: 100000,
      previousClose: 100000,
      simulationSeed: simulationSeed,
    );
    final lowPriceNotional = lowPriceCapacity * 120;
    final highPriceNotional = highPriceCapacity * 100000;

    expect(lowPriceCapacity, greaterThan(50000));
    expect(highPriceCapacity, greaterThan(0));
    expect(
      highPriceNotional / lowPriceNotional,
      inInclusiveRange(0.5, 2.0),
      reason: '주가 차이만으로 분당 체결금액이 수백 배 벌어지면 안 된다.',
    );
  });

  test('turnover caps are price-neutral and reject invalid inputs', () {
    expect(
      gameOrderBookMinuteCapacityUnits(turnoverEok: 137, unitPrice: 120) * 120,
      closeTo(
        gameOrderBookMinuteCapacityUnits(turnoverEok: 137, unitPrice: 100000) *
            100000,
        100000,
      ),
    );
    expect(gameOrderBookNotionalLimitForTurnover(turnoverEok: 137), 274000000);
    expect(gameOrderBookMinuteCapacityUnits(turnoverEok: 0, unitPrice: 120), 0);
    expect(
      gameOrderBookMinuteCapacityUnits(turnoverEok: double.nan, unitPrice: 120),
      0,
    );
    expect(gameOrderBookNotionalLimitForTurnover(turnoverEok: double.nan), 0);
    expect(gameOrderBookNotionalLimitForTurnover(turnoverEok: 0), 0);
  });
  test('null share fallback cannot exceed generated minute volume', () {
    const assetId = 'legacy_null_share_asset';
    const day = 6015;
    const minute = 10 * 60 + 17;
    const referencePrice = 10000.0;
    const simulationSeed = 'null-share-cap';
    final generatedMinuteVolume = gameEstimatedContinuousMinuteVolumeUnits(
      assetId: assetId,
      day: day,
      minute: minute,
      referencePrice: referencePrice,
      simulationSeed: simulationSeed,
    );
    final capacity = gameOrderBookExecutionCapacity(
      assetId: assetId,
      day: day,
      minute: minute,
      unitPrice: referencePrice,
      previousClose: referencePrice,
      simulationSeed: simulationSeed,
      cumulativeTurnoverEok: 500000,
    );

    expect(generatedMinuteVolume, greaterThan(0));
    expect(capacity, lessThanOrEqualTo(generatedMinuteVolume));
  });

  test('large player fills create bounded temporary tick impact', () {
    expect(
      gamePlayerMarketImpactInitialTicks(
        filledQuantity: 79,
        executionCapacity: 1000,
      ),
      0,
    );
    final initialTicks = gamePlayerMarketImpactInitialTicks(
      filledQuantity: 500,
      executionCapacity: 1000,
    );
    expect(initialTicks, inInclusiveRange(1, 6));
    expect(
      gamePlayerMarketImpactTicksAtAge(
        initialTicks: initialTicks,
        ageMinutes: 1,
      ),
      initialTicks,
    );
    expect(
      gamePlayerMarketImpactTicksAtAge(
        initialTicks: initialTicks,
        ageMinutes: gamePlayerMarketImpactDurationMinutes + 1,
      ),
      0,
    );

    final raised = gameOrderBookPriceAfterTickImpact(
      basePrice: 10000,
      signedTicks: initialTicks,
      market: '미래시장',
    );
    final lowered = gameOrderBookPriceAfterTickImpact(
      basePrice: 10000,
      signedTicks: -initialTicks,
      market: '미래시장',
    );
    expect(raised, greaterThan(10000));
    expect(lowered, lessThan(10000));
    expect(isValidMarketOrderPrice(raised, market: '미래시장'), isTrue);
    expect(isValidMarketOrderPrice(lowered, market: '미래시장'), isTrue);
  });

  test('wall identity is attached to price instead of the visible row', () {
    final first = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 17,
      currentPrice: 10000,
      previousClose: 9800,
      date: DateTime(2016, 6, 20),
      market: '미래시장',
    );
    final second = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 17,
      currentPrice: 10050,
      previousClose: 9800,
      date: DateTime(2016, 6, 20),
      market: '미래시장',
    );

    final firstByPrice = <double, bool>{
      for (final level in [...first.asks, ...first.bids])
        level.price: level.isWall,
    };
    for (final level in [...second.asks, ...second.bids]) {
      if (!firstByPrice.containsKey(level.price)) continue;
      expect(
        level.isWall,
        firstByPrice[level.price],
        reason: '${level.price}원의 벽 여부는 행 위치가 바뀌어도 같아야 합니다.',
      );
    }
  });

  test(
    'structural support is deep while intact and stays thin after breach',
    () {
      const assetId = 'structural_support_depth';
      const simulationSeed = 'structural-liquidity-world';
      const day = 6015;
      const minute = 10 * 60 + 31;
      const previousClose = 290000.0;
      const currentPrice = 289500.0;
      final date = DateTime(2016, 6, 20);
      final range = marketDailyPriceRange(
        previousClose: previousClose,
        date: date,
        market: '미래시장',
      );
      final structure = buildMarketStructuralLiquidityMap(
        worldSeed: simulationSeed,
        assetId: assetId,
        market: '미래시장',
        referencePrice: previousClose,
        lowerPrice: range.lower,
        upperPrice: range.upper,
      );
      final support = structure.zoneAtPrice(previousClose);

      expect(support, isNotNull);
      expect(support!.kind, MarketLiquidityZoneKind.support);
      expect(support.isActive, isTrue);
      expect(support.isMajor, isTrue);

      GameOrderBookSnapshot snapshot({
        required double sessionLow,
        GameOrderBookSnapshot? previousSnapshot,
        int? previousSnapshotMinute,
      }) => buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: currentPrice,
        previousTradePrice: previousClose,
        previousClose: previousClose,
        date: date,
        market: '미래시장',
        simulationSeed: simulationSeed,
        levelCount: 25,
        sessionLow: sessionLow,
        sessionHigh: previousClose,
        previousSnapshot: previousSnapshot,
        previousSnapshotMinute: previousSnapshotMinute,
      );

      GameOrderBookLevel levelAt(
        GameOrderBookSnapshot snapshot,
        double price,
      ) => [
        ...snapshot.asks,
        ...snapshot.bids,
      ].singleWhere((level) => level.price == price);

      final intact = snapshot(sessionLow: currentPrice);
      final intactWall = levelAt(intact, support.price);
      expect(intactWall.isStructuralWall, isTrue);
      expect(intactWall.isStructuralBreached, isFalse);
      expect(intactWall.isWall, isTrue);
      expect(intactWall.structuralKind, MarketLiquidityZoneKind.support);
      expect(intactWall.structuralStrength, support.strength);
      expect(intactWall.structuralHoldTicks, support.holdTicks);

      final ordinaryDepths = [...intact.asks, ...intact.bids]
          .where(
            (level) =>
                !level.isWall &&
                !level.isStructuralWall &&
                (level.price - support.price).abs() <= 5000,
          )
          .map((level) => level.quantity)
          .toList(growable: false);
      expect(ordinaryDepths, isNotEmpty);
      final ordinaryAverage =
          ordinaryDepths.reduce((left, right) => left + right) /
          ordinaryDepths.length;
      expect(
        intactWall.quantity,
        greaterThan(ordinaryAverage * 2),
        reason: '29만원 구조적 지지벽은 주변 일반 호가보다 뚜렷하게 깊어야 한다.',
      );

      final intactGap = levelAt(intact, currentPrice);
      expect(intactGap.structuralVacuumMultiplier, 1);

      final breached = snapshot(sessionLow: support.breachBoundary);
      final breachedWall = levelAt(breached, support.price);
      final breachedGap = levelAt(breached, currentPrice);
      expect(breachedWall.isStructuralWall, isFalse);
      expect(breachedWall.isStructuralBreached, isTrue);
      expect(breachedWall.isWall, isFalse);
      expect(breachedWall.quantity, lessThan(intactWall.quantity * 0.25));
      expect(breachedGap.structuralVacuumMultiplier, lessThan(1));
      expect(breachedGap.isWall, isFalse);
      expect(breachedGap.quantity, lessThan(intactGap.quantity));

      final forcedMicroWall = GameOrderBookLevel(
        side: intactGap.side,
        price: intactGap.price,
        quantity: intactGap.quantity * 4,
        isWall: true,
        structuralKind: intactGap.structuralKind,
        structuralStrength: intactGap.structuralStrength,
        structuralHoldTicks: intactGap.structuralHoldTicks,
        isStructuralWall: false,
        isStructuralBreached: false,
        structuralVacuumMultiplier: 1,
      );
      List<GameOrderBookLevel> withForcedMicroWall(
        List<GameOrderBookLevel> levels,
      ) => [
        for (final level in levels)
          if (level.price == intactGap.price) forcedMicroWall else level,
      ];
      final previousWithMicroWall = GameOrderBookSnapshot(
        asks: withForcedMicroWall(intact.asks),
        bids: withForcedMicroWall(intact.bids),
        turnoverEok: intact.turnoverEok,
        executionCapacity: intact.executionCapacity,
        totalAskQuantity: intact.totalAskQuantity,
        totalBidQuantity: intact.totalBidQuantity,
        tradeStrength: intact.tradeStrength,
      );
      final carriedGapSnapshot = snapshot(
        sessionLow: support.breachBoundary,
        previousSnapshot: previousWithMicroWall,
        previousSnapshotMinute: minute,
      );
      final carriedGap = levelAt(carriedGapSnapshot, currentPrice);
      expect(carriedGap.structuralVacuumMultiplier, lessThan(1));
      expect(
        carriedGap.isWall,
        isFalse,
        reason: '돌파 뒤 얇은 구간에서는 직전 micro wall 표시를 승계하면 안 된다.',
      );
      expect(
        carriedGap.quantity,
        lessThan(forcedMicroWall.quantity),
        reason: '직전 큰 micro wall 수량도 구조벽 돌파 뒤에는 얇아져야 한다.',
      );
      expect(carriedGap.quantity, lessThanOrEqualTo(breachedGap.quantity));

      final carried = snapshot(
        sessionLow: support.breachBoundary - support.tickSize,
        previousSnapshot: intact,
        previousSnapshotMinute: minute,
      );
      final carriedWall = levelAt(carried, support.price);
      expect(carriedWall.isStructuralWall, isFalse);
      expect(carriedWall.isStructuralBreached, isTrue);
      expect(carriedWall.isWall, isFalse);
      expect(
        carriedWall.quantity,
        lessThanOrEqualTo(breachedWall.quantity),
        reason: '이전 스냅샷의 큰 벽을 승계하더라도 돌파 상태가 벽을 되살리면 안 된다.',
      );
    },
  );

  test('weekly-average confluence reinforces displayed depth and metadata', () {
    const assetId = 'technical_confluence_depth';
    const simulationSeed = 'technical-confluence-world';
    const currentPrice = 100000.0;
    const previousClose = 102000.0;
    const technicalLevels = <MarketTechnicalLevel>[
      MarketTechnicalLevel(
        periodWeeks: 5,
        price: currentPrice,
        kind: MarketTechnicalLevelKind.support,
        strength: 3.15,
        holdTicks: 3,
        weeklySamples: 5,
      ),
      MarketTechnicalLevel(
        periodWeeks: 20,
        price: currentPrice,
        kind: MarketTechnicalLevelKind.support,
        strength: 3.85,
        holdTicks: 5,
        weeklySamples: 20,
      ),
      MarketTechnicalLevel(
        periodWeeks: 60,
        price: currentPrice,
        kind: MarketTechnicalLevelKind.support,
        strength: 4.55,
        holdTicks: 8,
        weeklySamples: 60,
      ),
    ];

    GameOrderBookSnapshot snapshot({
      Iterable<MarketTechnicalLevel> levels = const <MarketTechnicalLevel>[],
    }) => buildGameOrderBookSnapshot(
      assetId: assetId,
      day: 6015,
      minute: 10 * 60 + 31,
      currentPrice: currentPrice,
      previousClose: previousClose,
      date: DateTime(2016, 6, 20),
      market: 'main',
      simulationSeed: simulationSeed,
      technicalLevels: levels,
    );

    GameOrderBookLevel displayedLevel(GameOrderBookSnapshot snapshot) => [
      ...snapshot.asks,
      ...snapshot.bids,
    ].singleWhere((level) => level.price == currentPrice);

    final ordinary = displayedLevel(snapshot());
    final reinforced = displayedLevel(snapshot(levels: technicalLevels));

    expect(ordinary.isPsychological, isTrue);
    expect(ordinary.technicalPeriods, isEmpty);
    expect(ordinary.confluenceCount, 1);
    expect(reinforced.isStructuralWall, isTrue);
    expect(reinforced.isStructuralBreached, isFalse);
    expect(reinforced.isPsychological, isTrue);
    expect(reinforced.technicalPeriods, <int>[5, 20, 60]);
    expect(reinforced.confluenceCount, 4);
    expect(
      reinforced.structuralStrength,
      greaterThan(ordinary.structuralStrength),
    );
    expect(
      reinforced.structuralHoldTicks,
      greaterThan(ordinary.structuralHoldTicks),
    );
    expect(
      reinforced.quantity,
      greaterThan(ordinary.quantity),
      reason: '같은 가격의 주봉·심리 가격 합류는 화면 호가 수량에도 반영돼야 한다.',
    );
  });

  test('same-price standing depth changes gradually instead of rerolling', () {
    const assetId = 'persistent_depth';
    const day = 6015;
    const simulationSeed = 'persistent-book';
    final first = buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: 10 * 60 + 13,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 9800,
      date: DateTime(2016, 6, 20),
      market: '미래시장',
      simulationSeed: simulationSeed,
    );
    final next = buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: 10 * 60 + 14,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 9800,
      date: DateTime(2016, 6, 20),
      market: '미래시장',
      simulationSeed: simulationSeed,
    );

    String key(GameOrderBookLevel level) =>
        '${level.side.name}:${level.price.toStringAsFixed(4)}';
    final firstByPrice = <String, GameOrderBookLevel>{
      for (final level in [...first.asks, ...first.bids]) key(level): level,
    };
    final common = [...next.asks, ...next.bids]
        .where((level) => firstByPrice.containsKey(key(level)))
        .toList(growable: false);

    expect(common.length, greaterThanOrEqualTo(18));
    for (final level in common) {
      final previous = firstByPrice[key(level)]!;
      final changeRate =
          (level.quantity - previous.quantity).abs() / previous.quantity;
      expect(
        changeRate,
        lessThanOrEqualTo(0.10),
        reason: '${level.price}원의 잔량이 한 분 만에 재추첨되면 안 됩니다.',
      );
      expect(level.isWall, previous.isWall);
    }
  });

  test('intact walls follow clustered flow with finite wall-order shocks', () {
    const assetId = 'breathing_walls';
    const day = 6015;
    const simulationSeed = 'breathing-wall-book';
    const currentPrice = 10000.0;
    const previousClose = 9800.0;
    final date = DateTime(2016, 6, 20);
    var minute = 10 * 60 + 12;

    GameOrderBookSnapshot snapshot({
      required int atMinute,
      required int pulseSlot,
      GameOrderBookSnapshot? previous,
      int? previousMinute,
    }) => buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: atMinute,
      currentPrice: currentPrice,
      previousTradePrice: currentPrice,
      previousClose: previousClose,
      date: date,
      market: '미래시장',
      simulationSeed: simulationSeed,
      previousSnapshot: previous,
      previousSnapshotMinute: previousMinute,
      liquidityPulse: gameOrderBookLiquidityPulseFrame(
        marketMinute: atMinute,
        slotIndex: pulseSlot,
      ),
      adaptiveLiquidityPulses: true,
    );

    var current = snapshot(atMinute: minute, pulseSlot: 0);
    final changedSides = <GameOrderBookSide>{};
    var changedTransitions = 0;
    for (var step = 0; step < 10; step += 1) {
      final nextMinute = minute + 1;
      final next = snapshot(
        atMinute: nextMinute,
        pulseSlot: 1,
        previous: current,
        previousMinute: minute,
      );
      final previousWalls = <String, GameOrderBookLevel>{
        for (final level in [...current.asks, ...current.bids])
          if (level.isWall &&
              !level.isStructuralBreached &&
              level.queueRecoveryTargetQuantity <= level.quantity)
            '${level.side.name}:${level.price}': level,
      };
      final changed = <GameOrderBookLevel>[];
      for (final level in [...next.asks, ...next.bids]) {
        final previous = previousWalls['${level.side.name}:${level.price}'];
        if (previous == null || !level.isWall) continue;
        final delta = (level.quantity - previous.quantity).abs();
        if (delta == 0) continue;
        changed.add(level);
        changedSides.add(level.side);
        final maximumChangeRatio = level.quantity > previous.quantity
            ? 0.30
            : 0.85;
        expect(
          delta,
          lessThanOrEqualTo(
            math.max(1, (previous.quantity * maximumChangeRatio).ceil()),
          ),
          reason: '${level.price}원 벽의 취소·재유입은 이벤트 상한 안에서만 변해야 합니다.',
        );
      }
      expect(
        changed.length,
        lessThanOrEqualTo(2),
        reason: '한 펄스에서 여러 벽을 동시에 다시 그리면 안 됩니다.',
      );
      if (changed.isNotEmpty) changedTransitions += 1;
      current = next;
      minute = nextMinute;
    }

    expect(changedTransitions, greaterThanOrEqualTo(3));
    expect(
      changedSides,
      isNotEmpty,
      reason: '수급이 한쪽에 이어지더라도 대표 벽은 조금씩 반응해야 합니다.',
    );
  });

  test(
    'a rare full wall cancellation removes depth without printing a trade',
    () {
      const day = 6015;
      const minute = 10 * 60 + 12;
      const currentPrice = 10000.0;
      final date = DateTime(2016, 6, 20);

      GameOrderBookLevel? cancelledWall;
      GameOrderBookSnapshot? cancelledSnapshot;
      for (var trial = 0; trial < 4000 && cancelledWall == null; trial += 1) {
        final assetId = 'full-wall-cancellation-$trial';
        final simulationSeed = 'full-wall-cancellation-world-$trial';
        final current = buildGameOrderBookSnapshot(
          assetId: assetId,
          day: day,
          minute: minute,
          currentPrice: currentPrice,
          previousTradePrice: currentPrice,
          previousClose: 9800,
          date: date,
          market: '미래시장',
          simulationSeed: simulationSeed,
          sharesOutstanding: 500000000,
          liquidityPulse: gameOrderBookLiquidityPulseFrame(
            marketMinute: minute,
            slotIndex: 0,
          ),
          adaptiveLiquidityPulses: true,
        );
        final previousWalls = <GameOrderBookLevel>[
          ...current.asks.where((level) => level.isWall),
          ...current.bids.where((level) => level.isWall),
        ];
        if (previousWalls.isEmpty) continue;
        final next = buildGameOrderBookSnapshot(
          assetId: assetId,
          day: day,
          minute: minute,
          currentPrice: currentPrice,
          previousTradePrice: currentPrice,
          previousClose: 9800,
          date: date,
          market: '미래시장',
          simulationSeed: simulationSeed,
          sharesOutstanding: 500000000,
          previousSnapshot: current,
          previousSnapshotMinute: minute,
          liquidityPulse: gameOrderBookLiquidityPulseFrame(
            marketMinute: minute,
            slotIndex: 1,
          ),
          adaptiveLiquidityPulses: true,
        );
        for (final wall in previousWalls) {
          final remembered = next.rememberedLevels[wall.price];
          if (remembered == null ||
              remembered.side != wall.side ||
              remembered.quantity != 0 ||
              remembered.isWall) {
            continue;
          }
          cancelledWall = wall;
          cancelledSnapshot = next;
          break;
        }
      }

      expect(cancelledWall, isNotNull, reason: '드물지만 벽 전체 취소 사건이 실제로 발생해야 한다.');
      expect(cancelledSnapshot, isNotNull);
      final wall = cancelledWall!;
      final snapshotAfterCancellation = cancelledSnapshot!;
      expect(snapshotAfterCancellation.lastSyntheticTrade, isNull);
      expect(snapshotAfterCancellation.sweepSteps, isEmpty);
      expect(
        [
          ...snapshotAfterCancellation.asks,
          ...snapshotAfterCancellation.bids,
        ].any(
          (level) =>
              level.side == wall.side &&
              (level.price - wall.price).abs() < 0.000001,
        ),
        isFalse,
        reason: '전량 취소된 벽은 체결 가능한 호가에서 즉시 빠져야 한다.',
      );
      expect(
        snapshotAfterCancellation
            .rememberedLevels[wall.price]!
            .queueRecoveryTargetQuantity,
        inInclusiveRange(
          gameOrderBookMinimumDisplayedQuantity,
          math.max(
            gameOrderBookMinimumDisplayedQuantity,
            (wall.quantity * 0.35).round(),
          ),
        ),
        reason: '나중의 재유입은 소진 전 벽 전체가 아니라 작은 신규 주문부터 시작해야 한다.',
      );
    },
  );

  test(
    'busy quote pulses update one 18-share wall independently from the border',
    () {
      const assetId = 'busy-independent-wall-flow';
      const simulationSeed = 'busy-independent-wall-world';
      const day = 6015;
      const minute = 10 * 60 + 12;
      const currentPrice = 10000.0;
      const previousClose = 9800.0;
      const sharesOutstanding = 500000000;
      final date = DateTime(2016, 6, 20);
      final pulseZero = gameOrderBookLiquidityPulseFrame(
        marketMinute: minute,
        slotIndex: 0,
      );
      final base = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: currentPrice,
        previousTradePrice: currentPrice,
        previousClose: previousClose,
        date: date,
        market: '미래시장',
        simulationSeed: simulationSeed,
        sharesOutstanding: sharesOutstanding,
        liquidityPulse: pulseZero,
        adaptiveLiquidityPulses: true,
      );

      GameOrderBookLevel fixtureLevel(GameOrderBookLevel source) =>
          GameOrderBookLevel(
            side: source.side,
            price: source.price,
            quantity: source.isWall ? 18 : source.quantity,
            isWall: source.isWall,
            structuralKind: source.structuralKind,
            structuralStrength: source.structuralStrength,
            structuralHoldTicks: source.structuralHoldTicks,
            isStructuralWall: source.isStructuralWall,
            isStructuralBreached: source.isStructuralBreached,
            structuralVacuumMultiplier: source.structuralVacuumMultiplier,
            isPsychological: source.isPsychological,
            technicalPeriods: source.technicalPeriods,
            wasLiquidityPulseTouched: source.wasLiquidityPulseTouched,
            queueRecoveryTargetQuantity: source.queueRecoveryTargetQuantity,
          );
      final asks = <GameOrderBookLevel>[
        for (final entry in base.asks.asMap().entries)
          fixtureLevel(entry.value),
      ];
      final bids = <GameOrderBookLevel>[
        for (final entry in base.bids.asMap().entries)
          fixtureLevel(entry.value),
      ];
      var current = GameOrderBookSnapshot(
        asks: asks,
        bids: bids,
        turnoverEok: base.turnoverEok,
        fullDayTurnoverEok: base.fullDayTurnoverEok,
        boundaryBidPrice: base.bids.first.price,
        executionCapacity: base.executionCapacity,
        totalAskQuantity: asks.fold<int>(
          0,
          (sum, level) => sum + level.quantity,
        ),
        totalBidQuantity: bids.fold<int>(
          0,
          (sum, level) => sum + level.quantity,
        ),
        tradeStrength: base.tradeStrength,
        liquidityPulse: pulseZero,
        adaptiveLiquidityPulses: true,
        rememberedLevels: <double, GameOrderBookLevel>{
          for (final level in [...asks, ...bids]) level.price: level,
        },
        sourceAssetId: assetId,
        sourceLiquidityDayKey: day,
        sourceDateKey: marketDateKey(date),
        sourceMarketMinute: minute,
        sourceLastTradePrice: currentPrice,
        sourceMarket: '미래시장',
        sourceSimulationSeed: simulationSeed,
      );
      final fixedBoundary = current.boundaryBidPrice;
      final changedSides = <GameOrderBookSide>{};
      final changedWallKeys = <String>{};
      GameOrderBookSide? previousChangedSide;
      var observedFlowCluster = false;

      for (
        var slot = 1;
        slot <= gameOrderBookMaximumPulsesPerMarketMinute;
        slot += 1
      ) {
        final next = buildGameOrderBookSnapshot(
          assetId: assetId,
          day: day,
          minute: minute,
          currentPrice: currentPrice,
          previousTradePrice: currentPrice,
          previousClose: previousClose,
          date: date,
          market: '미래시장',
          simulationSeed: simulationSeed,
          sharesOutstanding: sharesOutstanding,
          previousSnapshot: current,
          previousSnapshotMinute: minute,
          liquidityPulse: gameOrderBookLiquidityPulseFrame(
            marketMinute: minute,
            slotIndex: slot,
          ),
          adaptiveLiquidityPulses: true,
        );
        final previousWalls = <String, GameOrderBookLevel>{
          for (final level in [...current.asks, ...current.bids])
            if (level.isWall) '${level.side.name}:${level.price}': level,
        };
        final changedWalls = <GameOrderBookLevel>[];
        for (final level in [...next.asks, ...next.bids]) {
          final previous = previousWalls['${level.side.name}:${level.price}'];
          if (previous == null || !level.isWall) continue;
          final delta = (level.quantity - previous.quantity).abs();
          if (delta == 0) continue;
          changedWalls.add(level);
          changedSides.add(level.side);
          changedWallKeys.add('${level.side.name}:${level.price}');
          expect(
            delta,
            1,
            reason:
                'slot $slot ${level.side.name} ${level.price}: '
                '${previous.quantity} -> ${level.quantity}',
          );
        }

        final previousWallSummary = previousWalls.values
            .map(
              (level) => '${level.side.name}:${level.price}=${level.quantity}',
            )
            .join(',');
        final nextWallSummary = [...next.asks, ...next.bids]
            .where((level) => level.isWall)
            .map(
              (level) => '${level.side.name}:${level.price}=${level.quantity}',
            )
            .join(',');
        expect(
          changedWalls,
          hasLength(1),
          reason: 'slot $slot: 이전벽=$previousWallSummary 다음벽=$nextWallSummary',
        );
        final changedSide = changedWalls.single.side;
        if (previousChangedSide != null) {
          observedFlowCluster =
              observedFlowCluster || changedSide == previousChangedSide;
        }
        previousChangedSide = changedSide;
        expect(next.boundaryBidPrice, fixedBoundary);
        expect(next.sourceLastTradePrice, currentPrice);
        expect(next.lastSyntheticTrade, current.lastSyntheticTrade);
        expect(next.syntheticTradePrints, current.syntheticTradePrints);
        expect(next.sweepSteps, current.sweepSteps);
        current = next;
      }

      expect(
        changedWallKeys.length,
        lessThanOrEqualTo(2),
        reason: '빠른 펄스를 따라잡아도 매도·매수 대표 벽 가격이 바뀌면 안 됩니다.',
      );
      expect(
        changedSides,
        isNotEmpty,
        reason: '체결 테두리와 별개로 실제 수급 방향의 대표 벽이 반응해야 합니다.',
      );
      expect(
        observedFlowCluster,
        isTrue,
        reason: '벽 방향을 기계적으로 번갈지 말고 같은 방향의 수급 군집을 허용해야 합니다.',
      );
    },
  );
  test(
    'partially filled walls keep breathing while the price ladder moves',
    () {
      const assetId = 'breathing_walls';
      const day = 6015;
      const simulationSeed = 'breathing-wall-book';
      const previousClose = 9800.0;
      final date = DateTime(2016, 6, 20);
      var minute = 10 * 60 + 12;
      var price = 10000.0;
      var current = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: price,
        previousTradePrice: price,
        previousClose: previousClose,
        date: date,
        market: '미래시장',
        simulationSeed: simulationSeed,
        liquidityPulse: gameOrderBookLiquidityPulseFrame(
          marketMinute: minute,
          slotIndex: 0,
        ),
        adaptiveLiquidityPulses: true,
      );
      final walls = [...current.asks, ...current.bids]
          .where(
            (level) =>
                level.isWall &&
                !level.isStructuralBreached &&
                level.quantity >= gameOrderBookMinimumDisplayedQuantity * 2,
          )
          .toList(growable: false);
      expect(
        walls.map((level) => level.side).toSet(),
        containsAll(<GameOrderBookSide>[
          GameOrderBookSide.ask,
          GameOrderBookSide.bid,
        ]),
      );
      current = gameOrderBookSnapshotAfterConsumption(
        snapshot: current,
        consumedAskByPrice: <double, double>{
          for (final wall in walls.where(
            (level) => level.side == GameOrderBookSide.ask,
          ))
            wall.price: math.max(1, wall.quantity ~/ 20).toDouble(),
        },
        consumedBidByPrice: <double, double>{
          for (final wall in walls.where(
            (level) => level.side == GameOrderBookSide.bid,
          ))
            wall.price: math.max(1, wall.quantity ~/ 20).toDouble(),
        },
      );

      final changedSides = <GameOrderBookSide>{};
      for (var step = 0; step < 16; step += 1) {
        final nextMinute = minute + 1;
        final nextPrice = marketSnapPrice(
          10000 + (step.isEven ? 10 : 0),
          market: '미래시장',
        );
        final next = buildGameOrderBookSnapshot(
          assetId: assetId,
          day: day,
          minute: nextMinute,
          currentPrice: nextPrice,
          previousTradePrice: price,
          previousClose: previousClose,
          date: date,
          market: '미래시장',
          simulationSeed: simulationSeed,
          previousSnapshot: current,
          previousSnapshotMinute: minute,
          liquidityPulse: gameOrderBookLiquidityPulseFrame(
            marketMinute: nextMinute,
            slotIndex: 1,
          ),
          adaptiveLiquidityPulses: true,
        );
        final previousByKey = <String, GameOrderBookLevel>{
          for (final level in [...current.asks, ...current.bids])
            '${level.side.name}:${level.price}': level,
        };
        var changedWallCount = 0;
        for (final level in [...next.asks, ...next.bids]) {
          final previous = previousByKey['${level.side.name}:${level.price}'];
          if (previous == null || !previous.isWall || !level.isWall) continue;
          final delta = (level.quantity - previous.quantity).abs();
          if (delta == 0) continue;
          changedWallCount += 1;
          changedSides.add(level.side);
          final maximumChangeRatio = level.quantity > previous.quantity
              ? 0.30
              : 0.55;
          expect(
            delta,
            lessThanOrEqualTo(
              math.max(1, (previous.quantity * maximumChangeRatio).ceil()),
            ),
            reason: '부분체결 벽도 이벤트 상한을 넘어 즉시 복원·소거되면 안 됩니다.',
          );
        }
        expect(
          changedWallCount,
          lessThanOrEqualTo(1),
          reason: '가격이 움직여도 한 펄스에서 여러 벽을 함께 다시 그리면 안 됩니다.',
        );
        current = next;
        minute = nextMinute;
        price = nextPrice;
      }

      expect(
        changedSides,
        isNotEmpty,
        reason: '가격이 움직이고 부분체결된 뒤에도 우세 수급 방향의 벽은 미세 수정돼야 합니다.',
      );
    },
  );
  test('standing depth follows absolute price when its row index changes', () {
    const assetId = 'price_attached_depth';
    const day = 6015;
    const minute = 10 * 60 + 13;
    const simulationSeed = 'persistent-book';
    final first = buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: minute,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 9800,
      date: DateTime(2016, 6, 20),
      market: '미래시장',
      simulationSeed: simulationSeed,
    );
    final shifted = buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: minute,
      currentPrice: 10050,
      previousTradePrice: 10000,
      previousClose: 9800,
      date: DateTime(2016, 6, 20),
      market: '미래시장',
      simulationSeed: simulationSeed,
    );

    final firstByPrice = <String, GameOrderBookLevel>{
      for (final level in [...first.asks, ...first.bids])
        '${level.side.name}:${level.price}': level,
    };
    var compared = 0;
    for (final level in [...shifted.asks, ...shifted.bids]) {
      final previous = firstByPrice['${level.side.name}:${level.price}'];
      if (previous == null) continue;
      compared += 1;
      expect(level.quantity, previous.quantity);
      expect(level.isWall, previous.isWall);
    }
    expect(compared, greaterThanOrEqualTo(14));
  });

  test('price transition cannot skip a partially filled best quote', () {
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'depth_gated_transition',
      day: 6015,
      minute: 10 * 60 + 13,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
      date: DateTime(2016, 6, 20),
      market: '미래시장',
      simulationSeed: 'depth-gated-transition',
    );
    final bestAsk = snapshot.asks.first;
    final nextAsk = snapshot.asks[1];
    final partialRise = gameOrderBookPriceTransitionTowardTarget(
      snapshot: snapshot,
      previousPrice: snapshot.bids.first.price,
      targetPrice: nextAsk.price,
      availableUnits: bestAsk.quantity - 1,
      market: '미래시장',
    );

    expect(partialRise.price, bestAsk.price);
    expect(partialRise.targetReached, isFalse);
    expect(partialRise.consumedAskByPrice[bestAsk.price], bestAsk.quantity - 1);
    expect(partialRise.consumedAskByPrice.containsKey(nextAsk.price), isFalse);
    expect(partialRise.orderedFills, hasLength(1));
    expect(partialRise.orderedFills.single.side, GameOrderBookSide.ask);
    expect(partialRise.orderedFills.single.price, bestAsk.price);
    expect(partialRise.orderedFills.single.quantity, bestAsk.quantity - 1);
    expect(partialRise.orderedFills.single.remainingQuantity, 1);
    expect(partialRise.orderedFills.single.structuralBreach, isFalse);
    expect(partialRise.orderedFills.single.boundaryCrossed, isFalse);

    final clearedRise = gameOrderBookPriceTransitionTowardTarget(
      snapshot: snapshot,
      previousPrice: snapshot.bids.first.price,
      targetPrice: nextAsk.price,
      availableUnits: bestAsk.quantity + 1,
      market: '미래시장',
    );
    expect(clearedRise.price, nextAsk.price);
    expect(clearedRise.targetReached, isTrue);
    expect(clearedRise.consumedAskByPrice[bestAsk.price], bestAsk.quantity);
    expect(clearedRise.consumedAskByPrice[nextAsk.price], 1);
    expect(
      clearedRise.orderedFills.map((fill) => fill.price),
      orderedEquals(<double>[bestAsk.price, nextAsk.price]),
    );
    expect(
      clearedRise.orderedFills.map((fill) => fill.quantity),
      orderedEquals(<int>[bestAsk.quantity, 1]),
    );
    expect(
      clearedRise.orderedFills.map((fill) => fill.remainingQuantity),
      orderedEquals(<int>[0, nextAsk.quantity - 1]),
    );
    expect(
      clearedRise.orderedFills.map((fill) => fill.structuralBreach),
      orderedEquals(const <bool>[false, false]),
    );
    expect(
      clearedRise.orderedFills.map((fill) => fill.boundaryCrossed),
      orderedEquals(const <bool>[true, false]),
    );

    final bestBid = snapshot.bids.first;
    final nextBid = snapshot.bids[1];
    final partialBidUnits = math.max(1, (bestBid.quantity * 0.5).floor());
    final partialFall = gameOrderBookPriceTransitionTowardTarget(
      snapshot: snapshot,
      previousPrice: snapshot.asks.first.price,
      targetPrice: nextBid.price,
      availableUnits: partialBidUnits,
      market: '미래시장',
    );
    expect(partialFall.price, bestBid.price);
    expect(partialFall.targetReached, isFalse);
    expect(partialFall.consumedBidByPrice[bestBid.price], partialBidUnits);
    expect(partialFall.consumedBidByPrice.containsKey(nextBid.price), isFalse);
    expect(partialFall.orderedFills.single.side, GameOrderBookSide.bid);
    expect(partialFall.orderedFills.single.price, bestBid.price);
    expect(
      partialFall.orderedFills.single.remainingQuantity,
      bestBid.quantity - partialBidUnits,
    );
    expect(partialFall.orderedFills.single.structuralBreach, isFalse);
    expect(partialFall.orderedFills.single.boundaryCrossed, isFalse);
  });

  test(
    'minute boundary keeps partial queues and flips only crossed quotes',
    () {
      const assetId = 'minute-boundary-side-ownership';
      const simulationSeed = 'minute-boundary-side-world';
      const day = 6015;
      const minute = 10 * 60 + 13;
      const previousClose = 10000.0;
      const sharesOutstanding = 120000000;
      final date = DateTime(2016, 6, 20);
      final base = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: previousClose,
        previousClose: previousClose,
        date: date,
        market: '미래시장',
        simulationSeed: simulationSeed,
        sharesOutstanding: sharesOutstanding,
      );

      GameOrderBookLevel ordinaryLevel(
        GameOrderBookLevel source,
        int quantity,
      ) => GameOrderBookLevel(
        side: source.side,
        price: source.price,
        quantity: quantity,
        isWall: false,
      );

      GameOrderBookSnapshot previousBook({
        required List<GameOrderBookLevel> asks,
        required List<GameOrderBookLevel> bids,
        required double lastTradePrice,
      }) => GameOrderBookSnapshot(
        asks: asks,
        bids: bids,
        turnoverEok: base.turnoverEok,
        fullDayTurnoverEok: base.fullDayTurnoverEok,
        boundaryBidPrice: bids.first.price,
        executionCapacity: base.executionCapacity,
        totalAskQuantity: asks.fold<int>(
          0,
          (sum, level) => sum + level.quantity,
        ),
        totalBidQuantity: bids.fold<int>(
          0,
          (sum, level) => sum + level.quantity,
        ),
        tradeStrength: base.tradeStrength,
        liquidityPulse: 40,
        adaptiveLiquidityPulses: true,
        rememberedLevels: {
          for (final level in [...asks, ...bids]) level.price: level,
        },
        sourceAssetId: assetId,
        sourceLiquidityDayKey: day,
        sourceDateKey: marketDateKey(date),
        sourceMarketMinute: minute,
        sourceLastTradePrice: lastTradePrice,
        sourceMarket: '미래시장',
        sourceSimulationSeed: simulationSeed,
      );

      int capacityAt(double targetPrice) => gameOrderBookExecutionCapacity(
        assetId: assetId,
        day: day,
        minute: minute + 1,
        unitPrice: targetPrice,
        previousClose: previousClose,
        simulationSeed: simulationSeed,
        sharesOutstanding: sharesOutstanding,
      );

      GameOrderBookSnapshot nextBook(
        GameOrderBookSnapshot previous,
        double targetPrice,
        int pulse,
      ) => buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute + 1,
        currentPrice: targetPrice,
        previousClose: previousClose,
        date: date,
        market: '미래시장',
        simulationSeed: simulationSeed,
        sharesOutstanding: sharesOutstanding,
        previousSnapshot: previous,
        previousSnapshotMinute: minute,
        liquidityPulse: pulse,
        adaptiveLiquidityPulses: true,
      );

      final riseTarget = base.asks[1].price;
      final riseCapacity = capacityAt(riseTarget);
      expect(riseCapacity, greaterThan(0));
      final partialAsk = ordinaryLevel(base.asks.first, riseCapacity + 20);
      final rise = nextBook(
        previousBook(
          asks: <GameOrderBookLevel>[partialAsk, ...base.asks.skip(1)],
          bids: base.bids,
          lastTradePrice: base.bids.first.price,
        ),
        riseTarget,
        41,
      );

      expect(rise.sweepSteps, hasLength(1));
      expect(rise.sweepSteps.single.side, GameOrderBookSide.ask);
      expect(rise.sweepSteps.single.price, partialAsk.price);
      expect(rise.sweepSteps.single.remainingQuantity, 20);
      expect(rise.sweepSteps.single.boundaryCrossed, isFalse);
      expect(rise.sourceLastTradePrice, partialAsk.price);
      expect(
        rise.asks
            .singleWhere((level) => level.price == partialAsk.price)
            .quantity,
        20,
      );
      expect(
        rise.bids.any((level) => level.price == partialAsk.price),
        isFalse,
      );

      final fallTarget = base.bids[1].price;
      final fallCapacity = capacityAt(fallTarget);
      expect(
        fallCapacity,
        greaterThanOrEqualTo(gameOrderBookMinimumDisplayedQuantity),
      );
      final partialBid = ordinaryLevel(base.bids.first, fallCapacity + 20);
      final fall = nextBook(
        previousBook(
          asks: base.asks,
          bids: <GameOrderBookLevel>[partialBid, ...base.bids.skip(1)],
          lastTradePrice: base.asks.first.price,
        ),
        fallTarget,
        42,
      );

      expect(fall.sweepSteps, hasLength(1));
      expect(fall.sweepSteps.single.side, GameOrderBookSide.bid);
      expect(fall.sweepSteps.single.price, partialBid.price);
      expect(fall.sweepSteps.single.remainingQuantity, 20);
      expect(fall.sweepSteps.single.boundaryCrossed, isFalse);
      expect(fall.sourceLastTradePrice, partialBid.price);
      expect(
        fall.bids
            .singleWhere((level) => level.price == partialBid.price)
            .quantity,
        20,
      );
      expect(
        fall.asks.any((level) => level.price == partialBid.price),
        isFalse,
      );

      final crossedBid = ordinaryLevel(base.bids.first, fallCapacity);
      final crossed = nextBook(
        previousBook(
          asks: base.asks,
          bids: <GameOrderBookLevel>[crossedBid, ...base.bids.skip(1)],
          lastTradePrice: base.asks.first.price,
        ),
        fallTarget,
        43,
      );

      expect(crossed.sweepSteps, hasLength(1));
      expect(crossed.sweepSteps.single.side, GameOrderBookSide.bid);
      expect(crossed.sweepSteps.single.price, crossedBid.price);
      expect(crossed.sweepSteps.single.remainingQuantity, 0);
      expect(crossed.sweepSteps.single.boundaryCrossed, isTrue);
      expect(crossed.sourceLastTradePrice, crossedBid.price);
      expect(
        crossed.asks.any((level) => level.price == crossedBid.price),
        isTrue,
      );
      expect(
        crossed.bids.any((level) => level.price == crossedBid.price),
        isFalse,
      );
    },
  );

  test('reduced visual slots still reach the target through actual walls', () {
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'reduced_cadence_target',
      day: 6015,
      minute: 10 * 60 + 13,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
      date: DateTime(2016, 6, 20),
      market: '미래시장',
      simulationSeed: 'reduced-cadence-target',
    );
    final target = snapshot.asks[2];
    final capacity = snapshot.asks[0].quantity + snapshot.asks[1].quantity + 1;
    final pulses = gameOrderBookMaximumOrdinaryPulsesPerMarketMinute;
    final transitions = [
      for (var slot = 1; slot <= pulses; slot += 1)
        gameOrderBookPriceTransitionTowardTarget(
          snapshot: snapshot,
          previousPrice: snapshot.bids.first.price,
          targetPrice: target.price,
          availableUnits: gameOrderBookCumulativeSlotCapacity(
            executionCapacity: capacity,
            slotIndex: slot,
            pulsesPerMarketMinute: pulses,
          ),
          market: '미래시장',
        ),
    ];

    expect(transitions, hasLength(4));
    expect(transitions.last.price, target.price);
    expect(transitions.last.targetReached, isTrue);
    expect(
      transitions.last.consumedAskByPrice[snapshot.asks[0].price],
      snapshot.asks[0].quantity,
    );
    expect(
      transitions.last.consumedAskByPrice[snapshot.asks[1].price],
      snapshot.asks[1].quantity,
    );
    expect(transitions.last.consumedAskByPrice[target.price], 1);
  });

  test('minute sweep exposes every crossed price in replay and tape order', () {
    const assetId = 'minute_sweep_replay';
    const simulationSeed = 'minute-sweep-replay-world';
    const day = 6015;
    const minute = 10 * 60 + 13;
    final date = DateTime(2016, 6, 20);
    final base = buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: minute,
      currentPrice: 10000,
      previousClose: 10000,
      date: date,
      market: '미래시장',
      simulationSeed: simulationSeed,
      sharesOutstanding: 120000000,
    );
    const quantities = <int>[20, 30, 40];
    final asks = <GameOrderBookLevel>[
      for (var index = 0; index < quantities.length; index += 1)
        GameOrderBookLevel(
          side: GameOrderBookSide.ask,
          price: base.asks[index].price,
          quantity: quantities[index],
          isWall: false,
        ),
    ];
    final previous = GameOrderBookSnapshot(
      asks: asks,
      bids: base.bids,
      turnoverEok: base.turnoverEok,
      fullDayTurnoverEok: base.fullDayTurnoverEok,
      boundaryBidPrice: base.bids.first.price,
      executionCapacity: base.executionCapacity,
      totalAskQuantity: quantities.fold<int>(0, (sum, value) => sum + value),
      totalBidQuantity: base.totalBidQuantity,
      tradeStrength: base.tradeStrength,
      rememberedLevels: {
        for (final level in [...asks, ...base.bids]) level.price: level,
      },
      sourceAssetId: assetId,
      sourceLiquidityDayKey: day,
      sourceDateKey: marketDateKey(date),
      sourceMarketMinute: minute,
      sourceLastTradePrice: base.bids.first.price,
      sourceMarket: '미래시장',
      sourceSimulationSeed: simulationSeed,
    );
    final next = buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: minute + 1,
      currentPrice: asks.last.price,
      previousTradePrice: base.bids.first.price,
      previousClose: 10000,
      date: date,
      market: '미래시장',
      simulationSeed: simulationSeed,
      sharesOutstanding: 120000000,
      previousSnapshot: previous,
      previousSnapshotMinute: minute,
      liquidityPulse: 77,
      adaptiveLiquidityPulses: true,
    );

    expect(
      next.sweepSteps.map((step) => step.side),
      everyElement(GameOrderBookSide.ask),
    );
    expect(
      next.sweepSteps.map((step) => step.price),
      orderedEquals(asks.map((level) => level.price)),
    );
    expect(
      next.sweepSteps.map((step) => step.consumedQuantity),
      orderedEquals(quantities),
    );
    expect(
      next.sweepSteps.map((step) => step.remainingQuantity),
      orderedEquals(const <int>[0, 0, 0]),
    );
    expect(
      next.sweepSteps.map((step) => step.sequence),
      orderedEquals(const <int>[0, 1, 2]),
    );
    expect(
      next.sweepSteps.every(
        (step) => step.marketMinute == minute + 1 && step.liquidityPulse == 77,
      ),
      isTrue,
    );
    expect(next.syntheticTradePrints.length, inInclusiveRange(7, 12));
    expect(next.sweepSteps.every((step) => step.boundaryCrossed), isTrue);
    expect(next.sweepSteps.every((step) => !step.structuralBreach), isTrue);
    expect(
      next.syntheticTradePrints.map((print) => print.sequence),
      orderedEquals(
        List<int>.generate(next.syntheticTradePrints.length, (index) => index),
      ),
    );
    for (var index = 0; index < asks.length; index += 1) {
      expect(
        next.syntheticTradePrints
            .where((print) => print.price == asks[index].price)
            .fold<int>(0, (sum, print) => sum + print.quantity),
        quantities[index],
      );
    }
    expect(
      next.syntheticTradePrints.fold<int>(
        0,
        (sum, print) => sum + print.quantity,
      ),
      quantities.fold<int>(0, (sum, value) => sum + value),
    );
    expect(next.lastSyntheticTrade?.price, asks.last.price);
    expect(next.lastSyntheticTrade?.quantity, quantities.last);
    expect(
      [...next.asks, ...next.bids].every(
        (level) => level.quantity >= gameOrderBookMinimumDisplayedQuantity,
      ),
      isTrue,
    );
  });

  test(
    'minute sweep removes a breached wall before a new ordinary quote arrives',
    () {
      const assetId = 'structural_support_depth';
      const simulationSeed = 'structural-liquidity-world';
      const day = 6015;
      const minute = 10 * 60 + 31;
      const previousClose = 290000.0;
      const currentPrice = 289500.0;
      final date = DateTime(2016, 6, 20);
      final range = marketDailyPriceRange(
        previousClose: previousClose,
        date: date,
        market: '미래시장',
      );
      final structure = buildMarketStructuralLiquidityMap(
        worldSeed: simulationSeed,
        assetId: assetId,
        market: '미래시장',
        referencePrice: previousClose,
        lowerPrice: range.lower,
        upperPrice: range.upper,
      );
      final support = structure.zoneAtPrice(previousClose)!;
      final intact = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: currentPrice,
        previousClose: previousClose,
        date: date,
        market: '미래시장',
        simulationSeed: simulationSeed,
        sharesOutstanding: 120000000,
        levelCount: 25,
        sessionLow: currentPrice,
        sessionHigh: previousClose,
        liquidityPulse: 41,
        adaptiveLiquidityPulses: true,
      );
      final intactWall = intact.asks.singleWhere(
        (level) => level.price == support.price,
      );
      expect(intactWall.isStructuralWall, isTrue);
      expect(intactWall.isStructuralBreached, isFalse);

      final nextMinuteProbe = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute + 1,
        currentPrice: support.price,
        previousTradePrice: currentPrice,
        previousClose: previousClose,
        date: date,
        market: '미래시장',
        simulationSeed: simulationSeed,
        sharesOutstanding: 120000000,
        levelCount: 25,
        sessionLow: currentPrice,
        sessionHigh: support.price,
        liquidityPulse: 42,
        adaptiveLiquidityPulses: true,
      );
      final capacity = nextMinuteProbe.executionCapacity;
      expect(capacity, greaterThan(gameOrderBookMinimumDisplayedQuantity));
      final wallQuantity = math
          .max(capacity + 1, (capacity / 0.90).floor())
          .toInt();
      expect(capacity / wallQuantity, greaterThanOrEqualTo(0.90));
      expect(capacity, lessThan(wallQuantity));

      GameOrderBookLevel resizedWall(GameOrderBookLevel level) =>
          GameOrderBookLevel(
            side: level.side,
            price: level.price,
            quantity: wallQuantity,
            isWall: level.isWall,
            structuralKind: level.structuralKind,
            structuralStrength: level.structuralStrength,
            structuralHoldTicks: level.structuralHoldTicks,
            isStructuralWall: level.isStructuralWall,
            isStructuralBreached: level.isStructuralBreached,
            structuralVacuumMultiplier: level.structuralVacuumMultiplier,
            isPsychological: level.isPsychological,
            technicalPeriods: level.technicalPeriods,
            wasLiquidityPulseTouched: level.wasLiquidityPulseTouched,
          );

      final asks = <GameOrderBookLevel>[
        for (final level in intact.asks)
          if (level.price == support.price) resizedWall(level) else level,
      ];
      final previous = GameOrderBookSnapshot(
        asks: asks,
        bids: intact.bids,
        turnoverEok: intact.turnoverEok,
        fullDayTurnoverEok: intact.fullDayTurnoverEok,
        boundaryBidPrice: intact.bids.first.price,
        executionCapacity: intact.executionCapacity,
        totalAskQuantity: asks.fold<int>(
          0,
          (sum, level) => sum + level.quantity,
        ),
        totalBidQuantity: intact.totalBidQuantity,
        tradeStrength: intact.tradeStrength,
        liquidityPulse: 41,
        adaptiveLiquidityPulses: true,
        rememberedLevels: {
          for (final level in [...asks, ...intact.bids]) level.price: level,
        },
        sourceAssetId: assetId,
        sourceLiquidityDayKey: day,
        sourceDateKey: marketDateKey(date),
        sourceMarketMinute: minute,
        sourceLastTradePrice: currentPrice,
        sourceMarket: '미래시장',
        sourceSimulationSeed: simulationSeed,
      );
      final breached = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute + 1,
        currentPrice: support.price,
        previousTradePrice: currentPrice,
        previousClose: previousClose,
        date: date,
        market: '미래시장',
        simulationSeed: simulationSeed,
        sharesOutstanding: 120000000,
        levelCount: 25,
        sessionLow: currentPrice,
        sessionHigh: support.price,
        previousSnapshot: previous,
        previousSnapshotMinute: minute,
        liquidityPulse: 42,
        adaptiveLiquidityPulses: true,
      );

      expect(breached.sweepSteps, hasLength(1));
      final step = breached.sweepSteps.single;
      expect(step.side, GameOrderBookSide.ask);
      expect(step.price, support.price);
      expect(step.consumedQuantity, capacity);
      expect(step.remainingQuantity, wallQuantity - capacity);
      expect(step.marketMinute, minute + 1);
      expect(step.liquidityPulse, 42);
      expect(step.structuralBreach, isTrue);
      expect(step.boundaryCrossed, isTrue);
      expect(
        breached.syntheticTradePrints.fold<int>(
          0,
          (sum, print) => sum + print.quantity,
        ),
        capacity,
      );
      expect(breached.syntheticTradePrints.length, inInclusiveRange(7, 12));

      final breachedLevel = breached.rememberedLevels[support.price]!;
      final recoveryCeiling = math.max(
        gameOrderBookMinimumDisplayedQuantity,
        (wallQuantity / math.max(1.0, intactWall.structuralStrength)).round(),
      );
      expect(breachedLevel.side, GameOrderBookSide.bid);
      expect(breachedLevel.isStructuralBreached, isTrue);
      expect(breachedLevel.isStructuralWall, isFalse);
      expect(breachedLevel.isWall, isFalse);
      expect(breachedLevel.quantity, lessThanOrEqualTo(recoveryCeiling));
      expect(
        breachedLevel.queueRecoveryTargetQuantity,
        anyOf(0, greaterThan(breachedLevel.quantity)),
        reason: '다음 프레임의 새 매수 주문은 소진된 구조벽 수량을 그대로 승계하면 안 됩니다.',
      );
      expect(
        breachedLevel.queueRecoveryTargetQuantity,
        lessThanOrEqualTo(recoveryCeiling),
      );

      final held = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute + 2,
        currentPrice: support.price,
        previousTradePrice: support.price,
        previousClose: previousClose,
        date: date,
        market: '미래시장',
        simulationSeed: simulationSeed,
        sharesOutstanding: 120000000,
        levelCount: 25,
        sessionLow: currentPrice,
        sessionHigh: support.price,
        previousSnapshot: breached,
        previousSnapshotMinute: minute + 1,
        liquidityPulse: 43,
        adaptiveLiquidityPulses: true,
      );
      final heldLevel = held.rememberedLevels[support.price]!;
      expect(held.sweepSteps, isEmpty);
      expect(heldLevel.isStructuralBreached, isTrue);
      expect(heldLevel.isStructuralWall, isFalse);
      expect(heldLevel.isWall, isFalse);
      expect(
        heldLevel.quantity,
        inInclusiveRange(
          breachedLevel.quantity,
          breachedLevel.queueRecoveryTargetQuantity,
        ),
      );
      if (!heldLevel.wasLiquidityPulseTouched) {
        expect(heldLevel.quantity, breachedLevel.quantity);
      }
      expect(
        heldLevel.queueRecoveryTargetQuantity,
        anyOf(0, breachedLevel.queueRecoveryTargetQuantity),
      );

      var recovering = held;
      var grewPastInitialQueue = heldLevel.quantity > breachedLevel.quantity;
      for (var pulse = 44; pulse <= 160 && !grewPastInitialQueue; pulse += 1) {
        final beforeLevel = recovering.rememberedLevels[support.price]!;
        final next = buildGameOrderBookSnapshot(
          assetId: assetId,
          day: day,
          minute: minute + 2,
          currentPrice: support.price,
          previousTradePrice: support.price,
          previousClose: previousClose,
          date: date,
          market: '미래시장',
          simulationSeed: simulationSeed,
          sharesOutstanding: 120000000,
          levelCount: 25,
          sessionLow: currentPrice,
          sessionHigh: support.price,
          previousSnapshot: recovering,
          previousSnapshotMinute: minute + 2,
          liquidityPulse: pulse,
          adaptiveLiquidityPulses: true,
        );
        final nextLevel = next.rememberedLevels[support.price]!;
        if (!nextLevel.wasLiquidityPulseTouched) {
          expect(
            nextLevel.quantity,
            beforeLevel.quantity,
            reason: '선택되지 않은 새 큐가 다른 행과 동시에 복구되면 안 됩니다.',
          );
        }
        grewPastInitialQueue = nextLevel.quantity > breachedLevel.quantity;
        recovering = next;
      }
      final recoveredQueue = recovering.rememberedLevels[support.price]!;
      expect(grewPastInitialQueue, isTrue);
      expect(recoveredQueue.quantity, greaterThan(breachedLevel.quantity));
      expect(
        recoveredQueue.quantity,
        lessThanOrEqualTo(breachedLevel.queueRecoveryTargetQuantity),
      );
      expect(recoveredQueue.isWall, isFalse);
      expect(recoveredQueue.isStructuralWall, isFalse);
    },
  );

  test('standing quantity does not change sides when price crosses spread', () {
    const assetId = 'center_crossing_depth';
    const day = 6015;
    const minute = 10 * 60 + 13;
    const simulationSeed = 'persistent-center-crossing-book';
    final date = DateTime(2016, 6, 20);

    GameOrderBookSnapshot snapshot({
      required double previous,
      required double current,
      GameOrderBookSnapshot? previousSnapshot,
    }) => buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: minute,
      currentPrice: current,
      previousTradePrice: previous,
      previousClose: 9800,
      date: date,
      market: '미래시장',
      simulationSeed: simulationSeed,
      previousSnapshot: previousSnapshot,
      previousSnapshotMinute: previousSnapshot == null ? null : minute,
    );

    GameOrderBookLevel levelAt(GameOrderBookSnapshot value, double price) => [
      ...value.asks,
      ...value.bids,
    ].singleWhere((level) => level.price == price);

    final before = snapshot(previous: 9950, current: 10000);
    final shifted = snapshot(
      previous: 10000,
      current: 10050,
      previousSnapshot: before,
    );
    final crossedAsk = levelAt(before, 10000);
    final newBid = levelAt(shifted, 10000);
    final stableAskBefore = levelAt(before, 10050);
    final stableAskAfter = levelAt(shifted, 10050);

    expect(crossedAsk.side, GameOrderBookSide.ask);
    expect(newBid.side, GameOrderBookSide.bid);
    expect(
      newBid.quantity,
      isNot(crossedAsk.quantity),
      reason: '남은 매도 주문을 같은 가격의 매수 주문으로 넘기면 안 됩니다.',
    );
    expect(
      stableAskAfter.quantity,
      stableAskBefore.quantity,
      reason: '스프레드를 건너지 않은 같은 방향·같은 가격 큐는 그대로 이어야 합니다.',
    );
  });
  test('one-tick noise does not reverse a strong daily depth trend', () {
    const assetId = 'strong_trend_one_tick_noise';
    const day = 6015;
    const minute = 10 * 60 + 31;
    const simulationSeed = 'persistent-trend-direction';
    final date = DateTime(2016, 6, 20);

    GameOrderBookSnapshot snapshot({
      required double previous,
      required double current,
    }) => buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: minute,
      currentPrice: current,
      previousTradePrice: previous,
      previousClose: 10000,
      date: date,
      market: '미래시장',
      simulationSeed: simulationSeed,
    );

    String key(GameOrderBookLevel level) =>
        '${level.side.name}:${level.price.toStringAsFixed(4)}';

    List<double> commonPriceChangeRates(
      GameOrderBookSnapshot before,
      GameOrderBookSnapshot after,
    ) {
      final beforeByPriceAndSide = <String, GameOrderBookLevel>{
        for (final level in [
          ...before.asks.take(gameOrderBookLevelCount),
          ...before.bids.take(gameOrderBookLevelCount),
        ])
          key(level): level,
      };
      return [
        for (final level in [
          ...after.asks.take(gameOrderBookLevelCount),
          ...after.bids.take(gameOrderBookLevelCount),
        ])
          if (beforeByPriceAndSide[key(level)] case final previous?)
            (level.quantity - previous.quantity).abs() / previous.quantity,
      ];
    }

    final risingTrend = snapshot(previous: 11150, current: 11200);
    final oneTickPullback = snapshot(previous: 11200, current: 11150);
    // Three ticks is the engine's fast-market boundary. It deliberately keeps
    // the same 11,150원 center as the one-tick pullback so only the confirmed
    // reversal regime, not a different set of visible prices, can move depth.
    final multiTickReversal = snapshot(previous: 11300, current: 11150);
    final oneTickChanges = commonPriceChangeRates(risingTrend, oneTickPullback);
    final reversalChanges = commonPriceChangeRates(
      risingTrend,
      multiTickReversal,
    );

    expect(oneTickChanges, hasLength(20));
    expect(
      oneTickChanges.reduce(math.max),
      lessThanOrEqualTo(0.20),
      reason: '+12% 상승 추세의 한 틱 눌림만으로 기존 잔량의 소진·보충 방향이 뒤집히면 안 됩니다.',
    );
    expect(reversalChanges, hasLength(20));
    expect(
      reversalChanges.reduce(math.max),
      greaterThan(0.25),
      reason: '여러 틱을 실제로 되돌린 반전에서는 빠른 호가 변화가 허용되어야 합니다.',
    );
  });

  test('surges and plunges consume depth on the pressured side', () {
    const assetId = 'regime_sensitive_depth';
    const simulationSeed = 'rapid-regime-book';
    const day = 6015;
    const minute = 10 * 60 + 31;
    final date = DateTime(2016, 6, 20);

    GameOrderBookSnapshot snapshot({
      required double previous,
      required double current,
      required double previousClose,
    }) => buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: minute,
      currentPrice: current,
      previousTradePrice: previous,
      previousClose: previousClose,
      date: date,
      market: '미래시장',
      simulationSeed: simulationSeed,
    );

    final calmAtHigh = snapshot(
      previous: 10400,
      current: 10400,
      previousClose: 10400,
    );
    final surge = snapshot(
      previous: 10000,
      current: 10400,
      previousClose: 10400,
    );
    final calmAtLow = snapshot(
      previous: 10000,
      current: 10000,
      previousClose: 10000,
    );
    final plunge = snapshot(
      previous: 10400,
      current: 10000,
      previousClose: 10000,
    );

    for (final cancellationOnlyBook in [surge, plunge]) {
      expect(cancellationOnlyBook.lastSyntheticTrade, isNull);
      expect(cancellationOnlyBook.syntheticTradeBudgetUsed, 0);
      expect(cancellationOnlyBook.appliedAskConsumptionByPrice, isEmpty);
      expect(cancellationOnlyBook.appliedBidConsumptionByPrice, isEmpty);
      expect(cancellationOnlyBook.appliedCapacityConsumptionUnits, 0);
    }

    expect(
      surge.tradeStrength,
      greaterThan(calmAtHigh.tradeStrength * 1.25),
      reason: '급등에서는 매도호가 소진과 매수호가 재유입이 보여야 한다.',
    );
    expect(
      plunge.tradeStrength,
      lessThan(calmAtLow.tradeStrength * 0.8),
      reason: '급락에서는 매수호가 소진과 매도호가 재유입이 보여야 한다.',
    );

    Map<double, GameOrderBookLevel> walls(
      Iterable<GameOrderBookLevel> levels,
    ) => {
      for (final level in levels.where((level) => level.isWall))
        level.price: level,
    };

    final calmAskWalls = walls(calmAtHigh.asks);
    final surgeAskWalls = walls(surge.asks);
    final commonAskWallPrices = calmAskWalls.keys
        .where(surgeAskWalls.containsKey)
        .toList(growable: false);
    expect(commonAskWallPrices, isNotEmpty);
    expect(
      commonAskWallPrices.any(
        (price) =>
            surgeAskWalls[price]!.quantity <
            calmAskWalls[price]!.quantity * 0.8,
      ),
      isTrue,
      reason: '강한 매수세에서는 기존 매도벽도 빠르게 얇아질 수 있어야 한다.',
    );

    final calmBidWalls = walls(calmAtLow.bids);
    final plungeBidWalls = walls(plunge.bids);
    final commonBidWallPrices = calmBidWalls.keys
        .where(plungeBidWalls.containsKey)
        .toList(growable: false);
    expect(commonBidWallPrices, isNotEmpty);
    expect(
      commonBidWallPrices.any(
        (price) =>
            plungeBidWalls[price]!.quantity <
            calmBidWalls[price]!.quantity * 0.8,
      ),
      isTrue,
      reason: '강한 매도세에서는 기존 매수벽도 빠르게 얇아질 수 있어야 한다.',
    );
  });

  test('strong trend depth can change quickly without independent rerolls', () {
    const assetId = 'fast_trend_depth';
    const simulationSeed = 'rapid-regime-book';
    const day = 6015;
    const currentPrice = 11200.0;
    final snapshots = <GameOrderBookSnapshot>[];
    for (var minute = 10 * 60 + 20; minute <= 10 * 60 + 28; minute++) {
      snapshots.add(
        buildGameOrderBookSnapshot(
          assetId: assetId,
          day: day,
          minute: minute,
          currentPrice: currentPrice,
          previousTradePrice: currentPrice,
          previousClose: 10000,
          date: DateTime(2016, 6, 20),
          market: '미래시장',
          simulationSeed: simulationSeed,
        ),
      );
    }

    var sawRapidChange = false;
    for (var index = 1; index < snapshots.length; index++) {
      final previousByPrice = <String, GameOrderBookLevel>{
        for (final level in [
          ...snapshots[index - 1].asks,
          ...snapshots[index - 1].bids,
        ])
          '${level.side.name}:${level.price}': level,
      };
      for (final level in [
        ...snapshots[index].asks,
        ...snapshots[index].bids,
      ]) {
        final previous = previousByPrice['${level.side.name}:${level.price}'];
        if (previous == null) continue;
        expect(level.isWall, previous.isWall);
        final changeRate =
            (level.quantity - previous.quantity).abs() / previous.quantity;
        if (changeRate >= 0.12) sawRapidChange = true;
      }
    }
    expect(
      sawRapidChange,
      isTrue,
      reason: '12%대 추세 종목까지 평시 보간 속도로만 움직이면 안 된다.',
    );
  });

  test('standing book does not collapse at open or close boundaries', () {
    GameOrderBookSnapshot snapshotAt(int minute) => buildGameOrderBookSnapshot(
      assetId: 'session_boundary_depth',
      day: 6015,
      minute: minute,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 9800,
      date: DateTime(2016, 6, 20),
      market: '미래시장',
      simulationSeed: 'persistent-book',
    );

    int total(GameOrderBookSnapshot snapshot) =>
        snapshot.totalAskQuantity + snapshot.totalBidQuantity;
    for (final pair in [
      (8 * 60 + 59, krxOpenMinute),
      (krxContinuousEndMinute - 1, krxContinuousEndMinute),
      (krxCloseMinute - 1, krxCloseMinute),
    ]) {
      final before = total(snapshotAt(pair.$1));
      final after = total(snapshotAt(pair.$2));
      expect(before, greaterThan(0));
      expect(after / before, inInclusiveRange(0.75, 1.25));
    }
  });

  test('visible price window keeps ten asks above ten bids', () {
    const day = 6015;
    const assetId = 'symmetric_price_window';
    const simulationSeed = 'persistent-book';
    final prices = <double>[10000, 10050, 10100, 10050, 10000];
    final currentRows = <int>[];
    final centerPrices = <(double, double)>[];
    for (var index = 0; index < prices.length; index++) {
      final current = prices[index];
      final previous = index == 0 ? current : prices[index - 1];
      final snapshot = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: 10 * 60 + 13 + index,
        currentPrice: current,
        previousTradePrice: previous,
        previousClose: 9800,
        date: DateTime(2016, 6, 20),
        market: '미래시장',
        simulationSeed: simulationSeed,
      );
      final window = <GameOrderBookLevel>[
        ...snapshot.asks
            .take(gameOrderBookLevelCount)
            .toList(growable: false)
            .reversed,
        ...snapshot.bids.take(gameOrderBookLevelCount),
      ];
      expect(window, hasLength(gameOrderBookLevelCount * 2));
      expect(
        window
            .take(gameOrderBookLevelCount)
            .every((level) => level.side == GameOrderBookSide.ask),
        isTrue,
      );
      expect(
        window
            .skip(gameOrderBookLevelCount)
            .every((level) => level.side == GameOrderBookSide.bid),
        isTrue,
      );
      final bestAskRow = gameOrderBookLevelCount - 1;
      final bestBidRow = gameOrderBookLevelCount;
      expect(window[bestAskRow].price, snapshot.asks.first.price);
      expect(window[bestBidRow].price, snapshot.bids.first.price);
      expect(window[bestAskRow].price, greaterThan(window[bestBidRow].price));

      final currentRow = window.indexWhere(
        (level) => (level.price - current).abs() < 0.000001,
      );
      expect(
        currentRow,
        anyOf(bestAskRow, bestBidRow),
        reason: '마지막 체결가는 중앙 최우선 매도·매수 두 칸 중 하나여야 한다.',
      );
      currentRows.add(currentRow);
      centerPrices.add((window[bestAskRow].price, window[bestBidRow].price));
    }

    expect(
      currentRows.toSet().difference({
        gameOrderBookLevelCount - 1,
        gameOrderBookLevelCount,
      }),
      isEmpty,
    );
    expect(
      centerPrices.toSet().length,
      greaterThanOrEqualTo(3),
      reason: '테두리는 중앙에 남아도 가격 사다리 값은 시세를 따라 바뀌어야 한다.',
    );
  });

  test(
    'rapid price regimes shift prices without moving outside center cells',
    () {
      const assetId = 'rapid_outline';
      const simulationSeed = 'rapid-regime-book';
      const day = 6015;
      const minute = 10 * 60 + 40;
      final date = DateTime(2016, 6, 20);

      GameOrderBookSnapshot snapshot(
        double previous,
        double current,
        int offset,
      ) => buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute + offset,
        currentPrice: current,
        previousTradePrice: previous,
        previousClose: 10000,
        date: date,
        market: '미래시장',
        simulationSeed: simulationSeed,
      );

      List<GameOrderBookLevel> visibleWindow(GameOrderBookSnapshot snapshot) =>
          [
            ...snapshot.asks
                .take(gameOrderBookLevelCount)
                .toList(growable: false)
                .reversed,
            ...snapshot.bids.take(gameOrderBookLevelCount),
          ];

      final calmWindow = visibleWindow(snapshot(10000, 10000, 0));
      final calmRow = calmWindow.indexWhere((level) => level.price == 10000);
      final surgeWindow = visibleWindow(snapshot(10000, 10200, 1));
      final surgeRow = surgeWindow.indexWhere((level) => level.price == 10200);
      final plungeWindow = visibleWindow(snapshot(10200, 10000, 2));
      final plungeRow = plungeWindow.indexWhere(
        (level) => level.price == 10000,
      );

      for (final window in [calmWindow, surgeWindow, plungeWindow]) {
        expect(window, hasLength(gameOrderBookLevelCount * 2));
        expect(
          window
              .take(gameOrderBookLevelCount)
              .every((level) => level.side == GameOrderBookSide.ask),
          isTrue,
        );
        expect(
          window
              .skip(gameOrderBookLevelCount)
              .every((level) => level.side == GameOrderBookSide.bid),
          isTrue,
        );
      }
      const bestAskRow = gameOrderBookLevelCount - 1;
      const bestBidRow = gameOrderBookLevelCount;
      expect(calmRow, anyOf(bestAskRow, bestBidRow));
      expect(surgeRow, bestAskRow);
      expect(plungeRow, bestBidRow);
      expect(surgeWindow[bestAskRow].price, 10200);
      expect(plungeWindow[bestBidRow].price, 10000);
      expect(
        surgeWindow[bestAskRow].price - calmWindow[bestAskRow].price,
        greaterThanOrEqualTo(150),
        reason: '급등에서는 테두리를 여러 행 보내지 않고 중앙 가격값이 빠르게 올라야 한다.',
      );
      expect(
        surgeWindow[bestBidRow].price - plungeWindow[bestBidRow].price,
        greaterThanOrEqualTo(150),
        reason: '급락 반전에서는 중앙 가격값이 빠르게 내려와야 한다.',
      );
    },
  );

  test('flat aggressors form local buy/sell regimes but balance long-term', () {
    final pulses = <GameOrderBookTradePulse>[];
    final minuteBuyRatios = <double>[];
    for (var minute = 10 * 60; minute < 11 * 60; minute += 1) {
      final minutePulses = <GameOrderBookTradePulse>[];
      for (var slot = 1; slot <= 32; slot += 1) {
        minutePulses.add(
          gameOrderBookTradePulse(
            assetId: 'balanced_flat_flow',
            day: 6015,
            minute: minute,
            previousPrice: 10000,
            currentPrice: 10000,
            executionCapacity: 1200,
            market: '미래시장',
            simulationSeed: 'persistent-book',
            liquidityPulse: gameOrderBookLiquidityPulseFrame(
              marketMinute: minute,
              slotIndex: slot,
            ),
            pulsesPerMarketMinute: 32,
          )!,
        );
      }
      pulses.addAll(minutePulses);
      minuteBuyRatios.add(
        minutePulses.where((pulse) => pulse.isBuyAggressor).length /
            minutePulses.length,
      );
    }

    final buyRatio =
        pulses.where((pulse) => pulse.isBuyAggressor).length / pulses.length;
    expect(buyRatio, inInclusiveRange(0.38, 0.62));
    expect(minuteBuyRatios.any((ratio) => ratio >= 0.625), isTrue);
    expect(minuteBuyRatios.any((ratio) => ratio <= 0.375), isTrue);
    expect(pulses.every((pulse) => pulse.levelIndex == 0), isTrue);
  });

  test('order-book levels obey historical daily limits and tick sizes', () {
    for (final date in [DateTime(2014, 6, 20), DateTime(2016, 6, 20)]) {
      final range = marketDailyPriceRange(
        previousClose: 10000,
        date: date,
        market: '미래시장',
      );
      final snapshot = buildGameOrderBookSnapshot(
        assetId: 'limit_fixture',
        day: date.difference(DateTime(2000)).inDays,
        minute: 14 * 60 + 45,
        currentPrice: range.upper,
        previousClose: 10000,
        date: date,
        market: '미래시장',
      );

      for (final level in [...snapshot.asks, ...snapshot.bids]) {
        expect(level.price, inInclusiveRange(range.lower, range.upper));
        expect(isValidMarketOrderPrice(level.price, market: '미래시장'), isTrue);
      }
    }
  });

  test('trade pulse moves to asks for buys and bids for sells', () {
    final buyPulse = gameOrderBookTradePulse(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 17,
      previousPrice: 10000,
      currentPrice: 10200,
      executionCapacity: 1200,
      market: '미래시장',
    );
    final sellPulse = gameOrderBookTradePulse(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 18,
      previousPrice: 10200,
      currentPrice: 9950,
      executionCapacity: 1200,
      market: '미래시장',
    );
    final flatPulse = gameOrderBookTradePulse(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 19,
      previousPrice: 10000,
      currentPrice: 10000,
      executionCapacity: 1200,
      market: '미래시장',
    );

    expect(buyPulse, isNotNull);
    expect(buyPulse!.levelSide, GameOrderBookSide.ask);
    expect(buyPulse.isBuyAggressor, isTrue);
    expect(
      buyPulse.levelIndex,
      inInclusiveRange(0, gameOrderBookLevelCount - 1),
    );
    expect(buyPulse.quantity, inInclusiveRange(1, 1200));
    expect(buyPulse.crossedTicks, 4);
    expect(buyPulse.isFastMarket, isTrue);

    expect(sellPulse, isNotNull);
    expect(sellPulse!.levelSide, GameOrderBookSide.bid);
    expect(sellPulse.isBuyAggressor, isFalse);
    expect(
      sellPulse.levelIndex,
      inInclusiveRange(0, gameOrderBookLevelCount - 1),
    );
    expect(sellPulse.quantity, inInclusiveRange(1, 1200));
    expect(sellPulse.crossedTicks, 9);
    expect(sellPulse.isFastMarket, isTrue);

    expect(flatPulse, isNotNull);
    expect(flatPulse!.levelIndex, inInclusiveRange(0, 1));
    expect(flatPulse.crossedTicks, 1);
    expect(flatPulse.isFastMarket, isFalse);
    final repeated = gameOrderBookTradePulse(
      assetId: 'hanbit_telecom',
      day: 6015,
      minute: 10 * 60 + 19,
      previousPrice: 10000,
      currentPrice: 10000,
      executionCapacity: 1200,
      market: '미래시장',
    );
    expect(repeated!.levelSide, flatPulse.levelSide);
    expect(repeated.levelIndex, flatPulse.levelIndex);
    expect(repeated.quantity, flatPulse.quantity);

    expect(
      gameOrderBookTradePulse(
        assetId: 'hanbit_telecom',
        day: 6015,
        minute: 8 * 60,
        previousPrice: 10000,
        currentPrice: 10000,
        executionCapacity: 0,
        market: '미래시장',
      ),
      isNull,
    );
  });

  test('last trade price moves between the best ask and best bid', () {
    final date = DateTime(2016, 6, 20);
    final rising = buildGameOrderBookSnapshot(
      assetId: 'moving_last_trade',
      day: 6015,
      minute: 10 * 60 + 17,
      currentPrice: 10050,
      previousTradePrice: 10000,
      previousClose: 10000,
      date: date,
      market: '미래시장',
      simulationSeed: 'moving-outline',
    );
    final falling = buildGameOrderBookSnapshot(
      assetId: 'moving_last_trade',
      day: 6015,
      minute: 10 * 60 + 18,
      currentPrice: 10000,
      previousTradePrice: 10050,
      previousClose: 10000,
      date: date,
      market: '미래시장',
      simulationSeed: 'moving-outline',
    );

    expect(rising.asks.first.price, 10050);
    expect(rising.bids.first.price, lessThan(10050));
    expect(falling.bids.first.price, 10000);
    expect(falling.asks.first.price, greaterThan(10000));
  });

  test('best-ask placement respects tick-size boundaries', () {
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'tick_boundary_last_trade',
      day: 6015,
      minute: 10 * 60 + 17,
      currentPrice: 100000,
      previousTradePrice: 99900,
      previousClose: 100000,
      date: DateTime(2016, 6, 20),
      market: '미래시장',
      simulationSeed: 'moving-outline',
    );

    expect(snapshot.asks.first.price, 100000);
    expect(snapshot.bids.first.price, 99900);
  });

  test('bid ladder crosses tick-size boundaries one valid price at a time', () {
    final cases = <({String market, double boundary, double previousValid})>[
      (market: '미래시장', boundary: 1000, previousValid: 999),
      (market: '미래시장', boundary: 5000, previousValid: 4995),
      (market: '미래시장', boundary: 10000, previousValid: 9990),
      (market: '미래시장', boundary: 50000, previousValid: 49950),
      (market: '미래시장', boundary: 100000, previousValid: 99900),
      (market: '미래시장', boundary: 500000, previousValid: 499500),
      (market: '도전시장', boundary: 1000, previousValid: 999),
      (market: '도전시장', boundary: 5000, previousValid: 4995),
      (market: '도전시장', boundary: 10000, previousValid: 9990),
      (market: '도전시장', boundary: 50000, previousValid: 49950),
      (market: '도전시장', boundary: 100000, previousValid: 99900),
      (market: '도전시장', boundary: 500000, previousValid: 499900),
    ];

    for (final testCase in cases) {
      final snapshot = buildGameOrderBookSnapshot(
        assetId:
            'bid_tick_boundary_${testCase.market}_${testCase.boundary.round()}',
        day: 6015,
        minute: 10 * 60 + 17,
        currentPrice: testCase.boundary,
        previousClose: testCase.boundary,
        date: DateTime(2016, 6, 20),
        market: testCase.market,
        simulationSeed: 'bid-boundary-ladder',
        sharesOutstanding: 1000000000,
        levelCount: 3,
      );

      expect(snapshot.bids, hasLength(3));
      expect(snapshot.bids.first.price, testCase.boundary);
      expect(
        snapshot.bids[1].price,
        testCase.previousValid,
        reason:
            '${testCase.market} ${testCase.boundary.round()}원 아래 첫 호가는 '
            '${testCase.previousValid.round()}원이어야 합니다.',
      );
      for (var index = 1; index < snapshot.bids.length; index++) {
        final upperPrice = snapshot.bids[index - 1].price;
        final expectedStep = marketTickSize(
          upperPrice - 0.000001,
          market: testCase.market,
        );
        expect(
          snapshot.bids[index].price,
          upperPrice - expectedStep,
          reason: '${testCase.market} $upperPrice원 아래 bid가 유효 호가 한 칸을 건너뛰었습니다.',
        );
      }
    }
  });

  test(
    'flat trade side and displayed current-price side stay synchronized',
    () {
      const assetId = 'flat_last_trade';
      const day = 6015;
      const minute = 10 * 60 + 19;
      const price = 10000.0;
      const simulationSeed = 'moving-outline';
      final snapshot = buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: minute,
        currentPrice: price,
        previousTradePrice: price,
        previousClose: price,
        date: DateTime(2016, 6, 20),
        market: '미래시장',
        simulationSeed: simulationSeed,
      );
      final pulse = gameOrderBookTradePulse(
        assetId: assetId,
        day: day,
        minute: minute,
        previousPrice: price,
        currentPrice: price,
        executionCapacity: snapshot.executionCapacity,
        market: '미래시장',
        simulationSeed: simulationSeed,
      );

      expect(pulse, isNotNull);
      if (pulse!.levelSide == GameOrderBookSide.ask) {
        expect(snapshot.asks.first.price, price);
        expect(snapshot.bids.first.price, lessThan(price));
      } else {
        expect(snapshot.bids.first.price, price);
        expect(snapshot.asks.first.price, greaterThan(price));
      }
    },
  );

  test('turnover changes with the saved world seed and trading day', () {
    final first = gameEstimatedTurnoverEok(
      assetId: 'hanbit_telecom',
      day: 4,
      minute: krxOpenMinute + 30,
      unitPrice: 10000,
      previousClose: 9800,
      simulationSeed: 'turnover-world-a',
    );
    final repeated = gameEstimatedTurnoverEok(
      assetId: 'hanbit_telecom',
      day: 4,
      minute: krxOpenMinute + 30,
      unitPrice: 10000,
      previousClose: 9800,
      simulationSeed: 'turnover-world-a',
    );
    final otherWorld = gameEstimatedTurnoverEok(
      assetId: 'hanbit_telecom',
      day: 4,
      minute: krxOpenMinute + 30,
      unitPrice: 10000,
      previousClose: 9800,
      simulationSeed: 'turnover-world-b',
    );
    final otherDay = gameEstimatedTurnoverEok(
      assetId: 'hanbit_telecom',
      day: 5,
      minute: krxOpenMinute + 30,
      unitPrice: 10000,
      previousClose: 9800,
      simulationSeed: 'turnover-world-a',
    );

    expect(repeated, first);
    expect(otherWorld, isNot(first));
    expect(otherDay, isNot(first));
  });

  test('cumulative turnover never falls when price reverts', () {
    var previous = 0.0;
    for (var minute = krxOpenMinute; minute <= krxCloseMinute; minute += 15) {
      final unitPrice = minute.isEven ? 13000.0 : 10000.0;
      final current = gameEstimatedTurnoverEok(
        assetId: 'hanbit_telecom',
        day: 4,
        minute: minute,
        unitPrice: unitPrice,
        previousClose: 10000,
        simulationSeed: 'monotonic-turnover',
      );
      expect(current, greaterThanOrEqualTo(previous));
      previous = current;
    }
  });

  test('closing auction keeps turnover and completed minute volume frozen', () {
    const fullDayVolume = 1000000;
    final continuousProgress = gameTurnoverProgressAtMinute(
      krxContinuousEndMinute - 1,
    );

    expect(
      gameTurnoverProgressAtMinute(krxContinuousEndMinute),
      continuousProgress,
    );
    expect(
      gameTurnoverProgressAtMinute(krxCloseMinute - 1),
      continuousProgress,
    );
    expect(gameTurnoverProgressAtMinute(krxCloseMinute), 1);

    final atContinuousEnd = gameContinuousMinuteVolumes(
      fullDayVolume: fullDayVolume,
      visibleThroughMinute: krxContinuousEndMinute - 1,
    );
    final duringAuction = gameContinuousMinuteVolumes(
      fullDayVolume: fullDayVolume,
      visibleThroughMinute: krxCloseMinute - 1,
    );
    expect(duringAuction, atContinuousEnd);
    expect(
      atContinuousEnd.fold<int>(0, (sum, volume) => sum + volume),
      (fullDayVolume * continuousProgress).round(),
    );
    expect(
      atContinuousEnd.fold<int>(0, (sum, volume) => sum + volume) +
          gameClosingAuctionVolume(fullDayVolume: fullDayVolume),
      fullDayVolume,
    );
  });

  test('extending the session never rewrites completed minute volumes', () {
    const fullDayVolume = 1234567;
    final morning = gameContinuousMinuteVolumes(
      fullDayVolume: fullDayVolume,
      visibleThroughMinute: 10 * 60,
    );
    final afternoon = gameContinuousMinuteVolumes(
      fullDayVolume: fullDayVolume,
      visibleThroughMinute: 14 * 60,
    );

    expect(afternoon.take(morning.length), morning);
    expect(afternoon.length, greaterThan(morning.length));
  });
}
