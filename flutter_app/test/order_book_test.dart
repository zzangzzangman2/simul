import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
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

    expect(snapshot.asks, hasLength(gameOrderBookLevelCount));
    expect(snapshot.bids, hasLength(gameOrderBookLevelCount));
    expect(snapshot.asks.any((level) => level.isWall), isTrue);
    expect(snapshot.bids.any((level) => level.isWall), isTrue);
    expect(
      snapshot.executionCapacity,
      gameAvailableLimitFillUnits(
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

  test(
    'net book promotes deeper prices and keeps six asks and bids after exhaustion',
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
      );
      expect(snapshot.asks, hasLength(gameOrderBookLevelCount));
      expect(snapshot.bids, hasLength(gameOrderBookLevelCount));

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
      final visibleAsks = net.asks.take(6).toList(growable: false);
      final visibleBids = net.bids.take(6).toList(growable: false);

      expect(visibleAsks, hasLength(6));
      expect(visibleBids, hasLength(6));
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
      expect(visibleAsks.last.price, snapshot.asks[9].price);
      expect(visibleBids.last.price, snapshot.bids[9].price);
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
    'dynamic raw depth leaves six asks and bids after five-plus level fills',
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
      expect(net.asks.take(6), hasLength(6));
      expect(net.bids.take(6), hasLength(6));
      expect(net.asks.every((level) => level.quantity > 0), isTrue);
      expect(net.bids.every((level) => level.quantity > 0), isTrue);
    },
  );

  test(
    'zero remembered depth stays empty until its price is pulse-touched',
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
      final exhausted = raw.asks.firstWhere(
        (level) =>
            !level.isStructuralBreached &&
            level.structuralVacuumMultiplier >= 0.999999,
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

      GameOrderBookLevel? replenished;
      for (var pulse = 2; pulse < 500; pulse += 1) {
        final carried = carriedAtPulse(pulse);
        final level = carried.rememberedLevels[exhausted.price]!;
        if (level.wasLiquidityPulseTouched) {
          replenished = level;
          break;
        }
        expect(level.quantity, 0);
      }
      expect(replenished, isNotNull);
      expect(replenished!.quantity, greaterThan(0));
      expect(replenished.quantity, lessThan(exhausted.quantity));
    },
  );

  test(
    'minute carry keeps net zero depth and resets consumption watermarks',
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

      expect(nextMinute.rememberedLevels[exhausted.price]!.quantity, 0);
      expect(nextMinute.appliedAskConsumptionByPrice, isEmpty);
      expect(nextMinute.appliedBidConsumptionByPrice, isEmpty);
      expect(nextMinute.appliedCapacityConsumptionUnits, 0);
    },
  );

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
    expect(
      gameMarketOrderNotionalLimit(120, turnoverEok: 137),
      gameMarketOrderNotionalLimit(100000, turnoverEok: 137),
    );
    expect(gameMarketOrderNotionalLimit(120, turnoverEok: 137), 274000000);
    expect(gameOrderBookMinuteCapacityUnits(turnoverEok: 0, unitPrice: 120), 0);
    expect(
      gameOrderBookMinuteCapacityUnits(turnoverEok: double.nan, unitPrice: 120),
      0,
    );
    expect(gameMarketOrderNotionalLimit(double.nan, turnoverEok: 137), 0);
    expect(gameMarketOrderNotionalLimit(120, turnoverEok: 0), 0);
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

  test(
    'price-level depth survives crossing the center without being rerolled',
    () {
      const assetId = 'center_crossing_depth';
      const day = 6015;
      const minute = 10 * 60 + 13;
      const simulationSeed = 'persistent-center-crossing-book';
      final date = DateTime(2016, 6, 20);

      GameOrderBookSnapshot snapshot({
        required int atMinute,
        required double previous,
        required double current,
        GameOrderBookSnapshot? previousSnapshot,
        int? previousSnapshotMinute,
      }) => buildGameOrderBookSnapshot(
        assetId: assetId,
        day: day,
        minute: atMinute,
        currentPrice: current,
        previousTradePrice: previous,
        previousClose: 9800,
        date: date,
        market: '미래시장',
        simulationSeed: simulationSeed,
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

      int visibleRowAt(GameOrderBookSnapshot snapshot, double price) {
        final visible = <GameOrderBookLevel>[
          ...snapshot.asks.take(6).toList(growable: false).reversed,
          ...snapshot.bids.take(6),
        ];
        return visible.indexWhere((level) => level.price == price);
      }

      final before = snapshot(atMinute: minute, previous: 9950, current: 10000);
      final shiftedSameMinute = snapshot(
        atMinute: minute,
        previous: 10000,
        current: 10050,
        previousSnapshot: before,
        previousSnapshotMinute: minute,
      );
      final beforeLevel = levelAt(before, 10000);
      final shiftedSameMinuteLevel = levelAt(shiftedSameMinute, 10000);

      expect(beforeLevel.side, GameOrderBookSide.ask);
      expect(shiftedSameMinuteLevel.side, GameOrderBookSide.bid);
      expect(visibleRowAt(before, 10000), 5);
      expect(visibleRowAt(shiftedSameMinute, 10000), 6);
      expect(
        shiftedSameMinuteLevel.quantity,
        beforeLevel.quantity,
        reason: '같은 분의 10,000원 잔량은 중앙을 통과해도 새로 추첨되면 안 됩니다.',
      );
      expect(
        shiftedSameMinuteLevel.isWall,
        beforeLevel.isWall,
        reason: '벽 여부도 매수·매도 행이 아니라 절대 가격에 붙어 있어야 합니다.',
      );

      final shiftedNextMinute = snapshot(
        atMinute: minute + 1,
        previous: 10050,
        current: 10100,
        previousSnapshot: shiftedSameMinute,
        previousSnapshotMinute: minute,
      );
      final nextMinuteBeforeLevel = levelAt(shiftedSameMinute, 10050);
      final nextMinuteAfterLevel = levelAt(shiftedNextMinute, 10050);
      final nextMinuteChangeRate =
          (nextMinuteAfterLevel.quantity - nextMinuteBeforeLevel.quantity)
              .abs() /
          nextMinuteBeforeLevel.quantity;

      expect(nextMinuteBeforeLevel.side, GameOrderBookSide.ask);
      expect(nextMinuteAfterLevel.side, GameOrderBookSide.bid);
      expect(visibleRowAt(shiftedSameMinute, 10050), 5);
      expect(visibleRowAt(shiftedNextMinute, 10050), 6);
      expect(
        nextMinuteChangeRate,
        lessThanOrEqualTo(0.10),
        reason: '다음 분에도 동일 가격 잔량은 3천 건에서 1만 건처럼 급변하면 안 됩니다.',
      );
      expect(nextMinuteAfterLevel.isWall, nextMinuteBeforeLevel.isWall);
    },
  );

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
        for (final level in [...before.asks, ...before.bids]) key(level): level,
      };
      return [
        for (final level in [...after.asks, ...after.bids])
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

  test('visible price window keeps six asks above six bids', () {
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
        ...snapshot.asks.take(6).toList(growable: false).reversed,
        ...snapshot.bids.take(6),
      ];
      expect(window, hasLength(12));
      expect(
        window.take(6).every((level) => level.side == GameOrderBookSide.ask),
        isTrue,
      );
      expect(
        window.skip(6).every((level) => level.side == GameOrderBookSide.bid),
        isTrue,
      );
      expect(window[5].price, snapshot.asks.first.price);
      expect(window[6].price, snapshot.bids.first.price);
      expect(window[5].price, greaterThan(window[6].price));

      final currentRow = window.indexWhere(
        (level) => (level.price - current).abs() < 0.000001,
      );
      expect(
        currentRow,
        anyOf(5, 6),
        reason: '마지막 체결가는 중앙 최우선 매도·매수 두 칸 중 하나여야 한다.',
      );
      currentRows.add(currentRow);
      centerPrices.add((window[5].price, window[6].price));
    }

    expect(currentRows.toSet().difference({5, 6}), isEmpty);
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
            ...snapshot.asks.take(6).toList(growable: false).reversed,
            ...snapshot.bids.take(6),
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
        expect(window, hasLength(12));
        expect(
          window.take(6).every((level) => level.side == GameOrderBookSide.ask),
          isTrue,
        );
        expect(
          window.skip(6).every((level) => level.side == GameOrderBookSide.bid),
          isTrue,
        );
      }
      expect(calmRow, anyOf(5, 6));
      expect(surgeRow, 5);
      expect(plungeRow, 6);
      expect(surgeWindow[5].price, 10200);
      expect(plungeWindow[6].price, 10000);
      expect(
        surgeWindow[5].price - calmWindow[5].price,
        greaterThanOrEqualTo(150),
        reason: '급등에서는 테두리를 여러 행 보내지 않고 중앙 가격값이 빠르게 올라야 한다.',
      );
      expect(
        surgeWindow[6].price - plungeWindow[6].price,
        greaterThanOrEqualTo(150),
        reason: '급락 반전에서는 중앙 가격값이 빠르게 내려와야 한다.',
      );
    },
  );

  test('flat aggressor direction is sticky for a multi-minute burst', () {
    final pulses = <GameOrderBookTradePulse>[];
    for (var minute = 10 * 60 + 12; minute <= 10 * 60 + 17; minute++) {
      pulses.add(
        gameOrderBookTradePulse(
          assetId: 'sticky_flat_flow',
          day: 6015,
          minute: minute,
          previousPrice: 10000,
          currentPrice: 10000,
          executionCapacity: 1200,
          market: '미래시장',
          simulationSeed: 'persistent-book',
        )!,
      );
    }

    expect(pulses.map((pulse) => pulse.levelSide).toSet(), hasLength(1));
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
