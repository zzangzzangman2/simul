import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_liquidity_zones.dart';
import 'package:millennium_capital/game/order_book.dart';

void main() {
  const assetId = 'adaptive_microstructure_asset';
  const simulationSeed = 'adaptive-microstructure-world';
  const day = 6015;
  const minute = 10 * 60 + 31;
  final date = DateTime(2016, 6, 20);

  GameOrderBookSnapshot snapshot({
    int pulse = 0,
    bool adaptive = true,
    double currentPrice = 10000,
    double previousTradePrice = 10000,
    double previousClose = 10000,
    int sharesOutstanding = 120000000,
    GameOrderBookSnapshot? previousSnapshot,
  }) => buildGameOrderBookSnapshot(
    assetId: assetId,
    day: day,
    minute: minute,
    currentPrice: currentPrice,
    previousTradePrice: previousTradePrice,
    previousClose: previousClose,
    date: date,
    market: 'main',
    simulationSeed: simulationSeed,
    sharesOutstanding: sharesOutstanding,
    previousSnapshot: previousSnapshot,
    previousSnapshotMinute: previousSnapshot == null ? null : minute,
    liquidityPulse: pulse,
    adaptiveLiquidityPulses: adaptive,
  );

  List<GameOrderBookLevel> levels(GameOrderBookSnapshot value) => [
    ...value.asks,
    ...value.bids,
  ];

  Map<double, GameOrderBookLevel> byPrice(GameOrderBookSnapshot value) => {
    for (final level in levels(value)) level.price: level,
  };

  Map<double, GameOrderBookLevel> visibleByPrice(GameOrderBookSnapshot value) =>
      {
        for (final level in value.asks.take(gameOrderBookLevelCount))
          level.price: level,
        for (final level in value.bids.take(gameOrderBookLevelCount))
          level.price: level,
      };

  double advanceTicks(double price, int count) {
    var result = price;
    for (var index = 0; index < count; index += 1) {
      result = marketSnapPrice(
        result + marketTickSize(result, market: 'main'),
        market: 'main',
      );
    }
    return result;
  }

  String signature(GameOrderBookSnapshot value) => levels(value)
      .map(
        (level) =>
            '${level.side.name}:${level.price}:${level.quantity}:'
            '${level.isWall}:${level.isStructuralWall}:'
            '${level.isStructuralBreached}:${level.structuralStrength}:'
            '${level.structuralHoldTicks}:${level.structuralVacuumMultiplier}:'
            '${level.isPsychological}:${level.technicalPeriods.join(',')}:'
            '${level.wasLiquidityPulseTouched}:'
            '${level.queueRecoveryTargetQuantity}',
      )
      .join('|');

  test('market-minute slots span low-liquidity two to active twenty-four', () {
    final dormant = gameOrderBookPulsesPerMarketMinute(
      fullDayTurnoverEok: 1,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
    );
    final ordinary = gameOrderBookPulsesPerMarketMinute(
      fullDayTurnoverEok: 100,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
    );
    final active = gameOrderBookPulsesPerMarketMinute(
      fullDayTurnoverEok: 60000,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
    );

    expect(dormant, gameOrderBookMinimumPulsesPerMarketMinute);
    expect(dormant, 2);
    expect(ordinary, greaterThan(dormant));
    expect(active, greaterThan(ordinary));
    expect(active, gameOrderBookMaximumOrdinaryPulsesPerMarketMinute);
  });

  test('fast and extreme moves use 32 and 40 slots without exceeding cap', () {
    final fast = gameOrderBookPulsesPerMarketMinute(
      fullDayTurnoverEok: 1,
      currentPrice: 10150,
      previousTradePrice: 10000,
      previousClose: 10000,
      market: 'main',
    );
    final extreme = gameOrderBookPulsesPerMarketMinute(
      fullDayTurnoverEok: 1,
      currentPrice: 10300,
      previousTradePrice: 10000,
      previousClose: 10000,
      market: 'main',
    );
    final extremeHighLiquidity = gameOrderBookPulsesPerMarketMinute(
      fullDayTurnoverEok: 1000000,
      currentPrice: 13000,
      previousTradePrice: 10000,
      previousClose: 10000,
      market: 'main',
      executionStrength: 500,
    );

    expect(fast, gameOrderBookFastPulsesPerMarketMinute);
    expect(extreme, gameOrderBookMaximumPulsesPerMarketMinute);
    expect(extremeHighLiquidity, gameOrderBookMaximumPulsesPerMarketMinute);
  });

  test('depth imbalance alone cannot accelerate balanced executions', () {
    final balancedExecutions = gameOrderBookPulsesPerMarketMinute(
      fullDayTurnoverEok: 1,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
      executionStrength: 100,
    );
    final buyOnlyExecutions = gameOrderBookPulsesPerMarketMinute(
      fullDayTurnoverEok: 1,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
      executionStrength: 500,
    );
    final sellOnlyExecutions = gameOrderBookPulsesPerMarketMinute(
      fullDayTurnoverEok: 1,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
      executionStrength: 0,
    );

    expect(balancedExecutions, gameOrderBookMinimumPulsesPerMarketMinute);
    expect(buyOnlyExecutions, gameOrderBookMaximumPulsesPerMarketMinute);
    expect(sellOnlyExecutions, gameOrderBookMaximumPulsesPerMarketMinute);
  });

  test('closed sessions and paused playback emit no slot', () {
    int cadence({
      bool tradingSessionActive = true,
      bool playbackActive = true,
    }) => gameOrderBookPulsesPerMarketMinute(
      fullDayTurnoverEok: 60000,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
      tradingSessionActive: tradingSessionActive,
      playbackActive: playbackActive,
    );

    expect(cadence(), greaterThan(0));
    expect(cadence(tradingSessionActive: false), 0);
    expect(cadence(playbackActive: false), 0);
    expect(cadence(tradingSessionActive: false, playbackActive: false), 0);
  });
  test('dropped render slots catch up to the same book and fill result', () {
    GameOrderBookSnapshot runTargets(Iterable<int> targetSlots) {
      var frame = gameOrderBookLiquidityPulseFrame(
        marketMinute: minute,
        slotIndex: 0,
      );
      var value = snapshot(pulse: frame);
      for (final targetSlot in targetSlots) {
        final pending = gameOrderBookPendingPulseFrames(
          marketMinute: minute,
          afterLiquidityPulse: frame,
          throughSlotIndex: targetSlot,
        );
        for (final pendingFrame in pending) {
          value = snapshot(pulse: pendingFrame, previousSnapshot: value);
          frame = pendingFrame;
        }
      }
      return value;
    }

    final everySlot = runTargets([
      for (var slot = 1; slot <= 24; slot += 1) slot,
    ]);
    final halfDropped = runTargets(const [4, 8, 12, 16, 20, 24]);
    expect(signature(halfDropped), signature(everySlot));

    GameOrderBookFillPlan fill(GameOrderBookSnapshot value) =>
        gameOrderBookLimitFillPlan(
          snapshot: value,
          isBuy: true,
          requestedQuantity: value.executionCapacity.toDouble(),
          limitPrice: value.asks[2].price,
        );
    final fullFill = fill(everySlot);
    final droppedFill = fill(halfDropped);
    expect(droppedFill.filledQuantity, fullFill.filledQuantity);
    expect(droppedFill.averagePrice, fullFill.averagePrice);
    expect(
      droppedFill.fills.map((item) => (item.price, item.quantity)),
      fullFill.fills.map((item) => (item.price, item.quantity)),
    );
  });

  test('low-liquidity minute still exposes two deterministic slots', () {
    final startFrame = gameOrderBookLiquidityPulseFrame(
      marketMinute: minute,
      slotIndex: 0,
    );
    final frames = gameOrderBookPendingPulseFrames(
      marketMinute: minute,
      afterLiquidityPulse: startFrame,
      throughSlotIndex: gameOrderBookMinimumPulsesPerMarketMinute,
    );

    expect(frames, hasLength(2));
    expect(frames.toSet(), hasLength(2));
    expect(
      frames,
      orderedEquals([
        gameOrderBookLiquidityPulseFrame(marketMinute: minute, slotIndex: 1),
        gameOrderBookLiquidityPulseFrame(marketMinute: minute, slotIndex: 2),
      ]),
    );
  });
  test(
    'multiple render frames can reuse one low-liquidity pulse unchanged',
    () {
      final first = snapshot(pulse: 7);
      var carried = first;

      for (var renderFrame = 1; renderFrame <= 12; renderFrame += 1) {
        final repeated = snapshot(pulse: 7, previousSnapshot: carried);
        expect(repeated.liquidityPulse, 7);
        expect(signature(repeated), signature(carried));
        carried = repeated;
      }
    },
  );

  test(
    'same world and pulse are deterministic without a previous snapshot',
    () {
      final first = snapshot(pulse: 41);
      final repeated = snapshot(pulse: 41);

      expect(first.adaptiveLiquidityPulses, isTrue);
      expect(first.liquidityPulse, 41);
      expect(signature(repeated), signature(first));
      expect(repeated.totalAskQuantity, first.totalAskQuantity);
      expect(repeated.totalBidQuantity, first.totalBidQuantity);
      expect(repeated.tradeStrength, first.tradeStrength);
    },
  );

  test(
    'legacy callers remain pulse-independent until adaptive mode is enabled',
    () {
      final legacy = snapshot(pulse: 0, adaptive: false);
      final ignoredPulse = snapshot(pulse: 99, adaptive: false);

      expect(signature(ignoredPulse), signature(legacy));
      expect(
        levels(ignoredPulse).every((level) => !level.wasLiquidityPulseTouched),
        isTrue,
      );
    },
  );

  test('a minute change without a new pulse carries common prices exactly', () {
    final first = snapshot(pulse: 12);
    final nextMinute = buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: minute + 1,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
      date: date,
      market: 'main',
      simulationSeed: simulationSeed,
      sharesOutstanding: 120000000,
      previousSnapshot: first,
      previousSnapshotMinute: minute,
      liquidityPulse: 12,
      adaptiveLiquidityPulses: true,
    );
    final before = byPrice(first);
    final after = byPrice(nextMinute);
    final commonPrices = before.keys.where(after.containsKey);

    expect(commonPrices, isNotEmpty);
    for (final price in commonPrices) {
      expect(
        after[price]!.quantity,
        before[price]!.quantity,
        reason: '$price원에는 새 펄스가 없으므로 분이 바뀌어도 재추첨되면 안 된다.',
      );
    }
  });

  test('an active pulse changes only a subset of absolute prices', () {
    final initial = snapshot();
    GameOrderBookSnapshot? pulsed;
    for (var pulse = 1; pulse <= 80; pulse += 1) {
      final candidate = snapshot(pulse: pulse, previousSnapshot: initial);
      final before = byPrice(initial);
      final after = byPrice(candidate);
      final changed = before.keys
          .where(
            (price) =>
                after.containsKey(price) &&
                after[price]!.quantity != before[price]!.quantity,
          )
          .length;
      if (changed > 0) {
        pulsed = candidate;
        break;
      }
    }

    expect(pulsed, isNotNull);
    final before = byPrice(initial);
    final after = byPrice(pulsed!);
    final commonPrices = before.keys
        .where(after.containsKey)
        .toList(growable: false);
    final changedPrices = commonPrices
        .where((price) => after[price]!.quantity != before[price]!.quantity)
        .toList(growable: false);
    final untouchedPrices = commonPrices
        .where((price) => after[price]!.quantity == before[price]!.quantity)
        .toList(growable: false);

    expect(commonPrices, hasLength(levels(initial).length));
    expect(changedPrices, isNotEmpty);
    expect(changedPrices.length, lessThan(commonPrices.length));
    expect(untouchedPrices, isNotEmpty);
    expect(
      changedPrices.every((price) => after[price]!.wasLiquidityPulseTouched),
      isTrue,
    );
    expect(
      untouchedPrices.any((price) => !after[price]!.wasLiquidityPulseTouched),
      isTrue,
    );
  });

  test(
    'absolute-price carry preserves wall identity and structural metadata',
    () {
      GameOrderBookSnapshot structuralSnapshot({
        required int pulse,
        required double currentPrice,
        required double previousTradePrice,
        GameOrderBookSnapshot? previousSnapshot,
      }) => buildGameOrderBookSnapshot(
        assetId: 'adaptive_structural_asset',
        day: day,
        minute: minute,
        currentPrice: currentPrice,
        previousTradePrice: previousTradePrice,
        previousClose: 290000,
        date: date,
        market: 'main',
        simulationSeed: 'adaptive-structural-world',
        sharesOutstanding: 120000000,
        previousSnapshot: previousSnapshot,
        previousSnapshotMinute: previousSnapshot == null ? null : minute,
        liquidityPulse: pulse,
        adaptiveLiquidityPulses: true,
      );

      final initial = structuralSnapshot(
        pulse: 0,
        currentPrice: 290000,
        previousTradePrice: 290000,
      );
      final initialByPrice = byPrice(initial);
      final structuralPrices = initialByPrice.entries
          .where((entry) => entry.value.isStructuralWall)
          .map((entry) => entry.key)
          .toList(growable: false);
      expect(structuralPrices, isNotEmpty);

      GameOrderBookSnapshot? shifted;
      double? commonStructuralPrice;
      for (var pulse = 1; pulse <= 80; pulse += 1) {
        final candidate = structuralSnapshot(
          pulse: pulse,
          currentPrice: 290500,
          previousTradePrice: 290000,
          previousSnapshot: initial,
        );
        final candidateByPrice = byPrice(candidate);
        final common = structuralPrices
            .where(candidateByPrice.containsKey)
            .firstOrNull;
        if (common != null) {
          shifted = candidate;
          commonStructuralPrice = common;
          break;
        }
      }

      expect(shifted, isNotNull);
      expect(commonStructuralPrice, isNotNull);
      final before = initialByPrice[commonStructuralPrice]!;
      final after = byPrice(shifted!)[commonStructuralPrice]!;
      expect(after.price, before.price);
      expect(after.isWall, isTrue);
      expect(after.isStructuralWall, isTrue);
      expect(after.isStructuralBreached, before.isStructuralBreached);
      expect(after.structuralKind, before.structuralKind);
      expect(after.structuralStrength, before.structuralStrength);
      expect(after.structuralHoldTicks, before.structuralHoldTicks);
      expect(
        after.structuralVacuumMultiplier,
        before.structuralVacuumMultiplier,
      );
      expect(after.isPsychological, before.isPsychological);
      expect(after.technicalPeriods, before.technicalPeriods);
    },
  );

  test(
    'a level keeps its depth and identity after leaving the visible ladder',
    () {
      const originalPrice = 10000.0;
      const pulse = 23;
      final initial = snapshot(
        pulse: pulse,
        currentPrice: originalPrice,
        previousTradePrice: originalPrice,
      );
      final rememberedPrice = initial.bids.first.price;
      final rememberedLevel = byPrice(initial)[rememberedPrice]!;
      final shiftedPrice = advanceTicks(originalPrice, 25);

      final shifted = snapshot(
        pulse: pulse,
        currentPrice: shiftedPrice,
        previousTradePrice: originalPrice,
        previousSnapshot: initial,
      );
      expect(
        visibleByPrice(shifted),
        isNot(contains(rememberedPrice)),
        reason:
            'fixture must move the old price more than one visible book away',
      );
      expect(
        shifted.rememberedLevels[rememberedPrice]?.quantity,
        rememberedLevel.quantity,
      );

      final returned = snapshot(
        pulse: pulse,
        currentPrice: originalPrice,
        previousTradePrice: shiftedPrice,
        previousSnapshot: shifted,
      );
      final restoredLevel = byPrice(returned)[rememberedPrice]!;

      expect(restoredLevel.quantity, rememberedLevel.quantity);
      expect(restoredLevel.isWall, rememberedLevel.isWall);
      expect(restoredLevel.structuralKind, rememberedLevel.structuralKind);
      expect(
        restoredLevel.structuralStrength,
        rememberedLevel.structuralStrength,
      );
      expect(
        restoredLevel.structuralHoldTicks,
        rememberedLevel.structuralHoldTicks,
      );
      expect(restoredLevel.isStructuralWall, rememberedLevel.isStructuralWall);
      expect(
        restoredLevel.isStructuralBreached,
        rememberedLevel.isStructuralBreached,
      );
      expect(
        restoredLevel.structuralVacuumMultiplier,
        rememberedLevel.structuralVacuumMultiplier,
      );
      expect(restoredLevel.isPsychological, rememberedLevel.isPsychological);
      expect(restoredLevel.technicalPeriods, rememberedLevel.technicalPeriods);
      expect(
        returned.rememberedLevels[rememberedPrice]?.quantity,
        rememberedLevel.quantity,
      );
    },
  );

  test('an offscreen structural wall stays breached when it returns', () {
    const structuralAssetId = 'adaptive_deep_breach_asset';
    const structuralSeed = 'adaptive-deep-breach-world';
    const previousClose = 290000.0;
    const pulse = 31;
    final range = marketDailyPriceRange(
      previousClose: previousClose,
      date: date,
      market: 'main',
    );
    final structure = buildMarketStructuralLiquidityMap(
      worldSeed: structuralSeed,
      assetId: structuralAssetId,
      market: 'main',
      referencePrice: previousClose,
      lowerPrice: range.lower,
      upperPrice: range.upper,
    );
    final support = structure.zoneAtPrice(previousClose)!;

    GameOrderBookSnapshot deepSnapshot({
      required double currentPrice,
      required double previousTradePrice,
      required double sessionLow,
      GameOrderBookSnapshot? previousSnapshot,
    }) => buildGameOrderBookSnapshot(
      assetId: structuralAssetId,
      day: day,
      minute: minute,
      currentPrice: currentPrice,
      previousTradePrice: previousTradePrice,
      previousClose: previousClose,
      date: date,
      market: 'main',
      simulationSeed: structuralSeed,
      sessionLow: sessionLow,
      sessionHigh: math.max(previousClose, currentPrice),
      sharesOutstanding: 120000000,
      previousSnapshot: previousSnapshot,
      previousSnapshotMinute: previousSnapshot == null ? null : minute,
      liquidityPulse: pulse,
      adaptiveLiquidityPulses: true,
    );

    final intact = deepSnapshot(
      currentPrice: previousClose,
      previousTradePrice: previousClose,
      sessionLow: previousClose,
    );
    final intactLevel = byPrice(intact)[support.price]!;
    expect(intactLevel.isStructuralWall, isTrue);
    expect(intactLevel.isStructuralBreached, isFalse);

    final shiftedPrice = advanceTicks(previousClose, 25);
    final breachedOffscreen = deepSnapshot(
      currentPrice: shiftedPrice,
      previousTradePrice: previousClose,
      sessionLow: support.breachBoundary,
      previousSnapshot: intact,
    );
    expect(visibleByPrice(breachedOffscreen), isNot(contains(support.price)));
    expect(
      breachedOffscreen.rememberedLevels[support.price]?.quantity,
      intactLevel.quantity,
      reason: 'the hidden level remains remembered until it re-enters the book',
    );

    final returned = deepSnapshot(
      currentPrice: previousClose,
      previousTradePrice: shiftedPrice,
      sessionLow: support.breachBoundary,
      previousSnapshot: breachedOffscreen,
    );
    final returnedLevel = returned.rememberedLevels[support.price]!;

    expect(returnedLevel.isStructuralBreached, isTrue);
    expect(returnedLevel.isStructuralWall, isFalse);
    expect(returnedLevel.isWall, isFalse);
    expect(returnedLevel.quantity, lessThan(intactLevel.quantity));
    expect(
      returned.rememberedLevels[support.price]?.isStructuralBreached,
      isTrue,
    );
  });

  test('breached structural liquidity cannot revive during a pulse', () {
    const previousClose = 290000.0;
    final range = marketDailyPriceRange(
      previousClose: previousClose,
      date: date,
      market: 'main',
    );
    final structure = buildMarketStructuralLiquidityMap(
      worldSeed: 'adaptive-breach-world',
      assetId: 'adaptive_breach_asset',
      market: 'main',
      referencePrice: previousClose,
      lowerPrice: range.lower,
      upperPrice: range.upper,
    );
    final support = structure.zoneAtPrice(previousClose)!;

    GameOrderBookSnapshot breachedSnapshot({
      required int pulse,
      required double sessionLow,
      GameOrderBookSnapshot? previousSnapshot,
    }) => buildGameOrderBookSnapshot(
      assetId: 'adaptive_breach_asset',
      day: day,
      minute: minute,
      currentPrice: previousClose,
      previousTradePrice: previousClose,
      previousClose: previousClose,
      date: date,
      market: 'main',
      simulationSeed: 'adaptive-breach-world',
      sessionLow: sessionLow,
      sessionHigh: previousClose,
      sharesOutstanding: 120000000,
      previousSnapshot: previousSnapshot,
      previousSnapshotMinute: previousSnapshot == null ? null : minute,
      liquidityPulse: pulse,
      adaptiveLiquidityPulses: true,
    );

    final intact = breachedSnapshot(pulse: 19, sessionLow: previousClose);
    final intactLevel = byPrice(intact)[support.price]!;
    expect(intactLevel.isStructuralBreached, isFalse);
    expect(intactLevel.isStructuralWall, isTrue);

    final samePulseBreach = breachedSnapshot(
      pulse: 19,
      sessionLow: support.breachBoundary,
      previousSnapshot: intact,
    );
    final breachedLevel = byPrice(samePulseBreach)[support.price]!;
    expect(samePulseBreach.liquidityPulse, intact.liquidityPulse);
    expect(breachedLevel.isStructuralBreached, isTrue);
    expect(breachedLevel.isStructuralWall, isFalse);
    expect(breachedLevel.isWall, isFalse);
    expect(breachedLevel.quantity, lessThan(intactLevel.quantity));

    final pulsed = breachedSnapshot(
      pulse: 20,
      sessionLow: support.breachBoundary,
      previousSnapshot: samePulseBreach,
    );
    final pulsedLevel = byPrice(pulsed)[support.price]!;
    expect(pulsedLevel.isStructuralBreached, isTrue);
    expect(pulsedLevel.isStructuralWall, isFalse);
    expect(pulsedLevel.isWall, isFalse);
    expect(pulsedLevel.quantity, lessThanOrEqualTo(breachedLevel.quantity));

    final exhaustedBreach = gameOrderBookSnapshotAfterConsumption(
      snapshot: samePulseBreach,
      consumedAskByPrice: breachedLevel.side == GameOrderBookSide.ask
          ? {breachedLevel.price: breachedLevel.quantity.toDouble()}
          : const <double, double>{},
      consumedBidByPrice: breachedLevel.side == GameOrderBookSide.bid
          ? {breachedLevel.price: breachedLevel.quantity.toDouble()}
          : const <double, double>{},
    );
    final heldBreach = breachedSnapshot(
      pulse: 20,
      sessionLow: support.breachBoundary,
      previousSnapshot: exhaustedBreach,
    );
    expect(
      heldBreach.rememberedLevels[support.price]!.quantity,
      0,
      reason: '현재가 근처에서 무너진 구조벽은 다음 펄스에 재생성되면 안 됩니다.',
    );

    final oneTickBelowSupport = gameOrderBookPriceAfterTickImpact(
      basePrice: support.price,
      signedTicks: -1,
      market: 'main',
    );
    final sideFlippedNearBreach = buildGameOrderBookSnapshot(
      assetId: 'adaptive_breach_asset',
      day: day,
      minute: minute,
      currentPrice: oneTickBelowSupport,
      previousTradePrice: support.price,
      previousClose: previousClose,
      date: date,
      market: 'main',
      simulationSeed: 'adaptive-breach-world',
      sessionLow: math.min(support.breachBoundary, oneTickBelowSupport),
      sessionHigh: previousClose,
      sharesOutstanding: 120000000,
      previousSnapshot: heldBreach,
      previousSnapshotMinute: minute,
      liquidityPulse: 21,
      adaptiveLiquidityPulses: true,
    );
    final flippedNearLevel =
        sideFlippedNearBreach.rememberedLevels[support.price]!;
    expect(flippedNearLevel.side, GameOrderBookSide.ask);
    expect(flippedNearLevel.isStructuralBreached, isTrue);
    expect(flippedNearLevel.isWall, isFalse);
    expect(
      flippedNearLevel.quantity,
      0,
      reason: '붕괴 가격이 bid에서 ask로 바뀌어도 근접 구조 공백을 우회하면 안 됩니다.',
    );

    final threeTicksBelowSupport = gameOrderBookPriceAfterTickImpact(
      basePrice: support.price,
      signedTicks: -3,
      market: 'main',
    );
    final sideFlippedFarFromBreach = buildGameOrderBookSnapshot(
      assetId: 'adaptive_breach_asset',
      day: day,
      minute: minute,
      currentPrice: threeTicksBelowSupport,
      previousTradePrice: support.price,
      previousClose: previousClose,
      date: date,
      market: 'main',
      simulationSeed: 'adaptive-breach-world',
      sessionLow: math.min(support.breachBoundary, threeTicksBelowSupport),
      sessionHigh: previousClose,
      sharesOutstanding: 120000000,
      previousSnapshot: heldBreach,
      previousSnapshotMinute: minute,
      liquidityPulse: 21,
      adaptiveLiquidityPulses: true,
    );
    final flippedFarLevel =
        sideFlippedFarFromBreach.rememberedLevels[support.price]!;
    expect(flippedFarLevel.side, GameOrderBookSide.ask);
    expect(flippedFarLevel.quantity, greaterThan(0));
    expect(flippedFarLevel.quantity, lessThan(breachedLevel.quantity));
    expect(flippedFarLevel.isWall, isFalse);
    expect(flippedFarLevel.queueRecoveryTargetQuantity, 0);

    var recoveringWall = gameOrderBookSnapshotAfterConsumption(
      snapshot: intact,
      consumedAskByPrice: intactLevel.side == GameOrderBookSide.ask
          ? {intactLevel.price: intactLevel.quantity.toDouble()}
          : const <double, double>{},
      consumedBidByPrice: intactLevel.side == GameOrderBookSide.bid
          ? {intactLevel.price: intactLevel.quantity.toDouble()}
          : const <double, double>{},
    );
    for (var nextPulse = 20; nextPulse < 40; nextPulse += 1) {
      recoveringWall = breachedSnapshot(
        pulse: nextPulse,
        sessionLow: previousClose,
        previousSnapshot: recoveringWall,
      );
    }
    expect(
      recoveringWall.rememberedLevels[support.price]!.quantity,
      lessThan((intactLevel.quantity * 0.70).floor()),
      reason: '구조벽은 일반 호가처럼 20슬롯 안에 통째로 복구되면 안 됩니다.',
    );
  });

  test(
    'synthetic prints cannot revive breached or vacuum-depleted raw depth',
    () {
      const structuralAssetId = 'synthetic_structural_clamp_asset';
      const structuralSeed = 'synthetic-structural-clamp-world';
      const previousClose = 290000.0;
      const currentPrice = 289500.0;
      final range = marketDailyPriceRange(
        previousClose: previousClose,
        date: date,
        market: 'main',
      );
      final structure = buildMarketStructuralLiquidityMap(
        worldSeed: structuralSeed,
        assetId: structuralAssetId,
        market: 'main',
        referencePrice: previousClose,
        lowerPrice: range.lower,
        upperPrice: range.upper,
      );
      final support = structure.zoneAtPrice(previousClose)!;

      GameOrderBookSnapshot structuralSnapshot({
        required double sessionLow,
        GameOrderBookSnapshot? previousSnapshot,
      }) => buildGameOrderBookSnapshot(
        assetId: structuralAssetId,
        day: day,
        minute: minute,
        currentPrice: currentPrice,
        previousTradePrice: previousClose,
        previousClose: previousClose,
        date: date,
        market: 'main',
        simulationSeed: structuralSeed,
        levelCount: 25,
        sessionLow: sessionLow,
        sessionHigh: previousClose,
        sharesOutstanding: 120000000,
        previousSnapshot: previousSnapshot,
        previousSnapshotMinute: previousSnapshot == null ? null : minute,
        liquidityPulse: 83,
        adaptiveLiquidityPulses: true,
      );

      final intact = structuralSnapshot(sessionLow: currentPrice);
      final depleted = structuralSnapshot(
        sessionLow: support.breachBoundary,
        previousSnapshot: intact,
      );
      final intactByPrice = byPrice(intact);
      final depletedByPrice = byPrice(depleted);
      final breachedTarget = depletedByPrice[support.price]!;
      final vacuumTarget = depletedByPrice[currentPrice]!;

      expect(breachedTarget.isStructuralBreached, isTrue);
      expect(vacuumTarget.isStructuralBreached, isFalse);
      expect(vacuumTarget.structuralVacuumMultiplier, lessThan(1));

      for (final target in [breachedTarget, vacuumTarget]) {
        final previousTarget = intactByPrice[target.price]!;
        expect(previousTarget.quantity, greaterThan(target.quantity));
        final requestedQuantity = math.min(7, target.quantity);
        expect(requestedQuantity, greaterThan(0));

        final applied = gameOrderBookSnapshotAfterSyntheticTrade(
          snapshot: depleted,
          pulse: GameOrderBookTradePulse(
            levelSide: target.side,
            levelIndex: 0,
            quantity: requestedQuantity,
            crossedTicks: 1,
          ),
          absolutePrice: target.price,
          previousSnapshot: intact,
          availableSnapshot: depleted,
          perMinuteBudgetUnits: target.quantity + 1,
        );
        final remaining = byPrice(applied)[target.price]!.quantity;

        expect(remaining, target.quantity - requestedQuantity);
        expect(
          remaining,
          isNot(previousTarget.quantity - requestedQuantity),
          reason:
              'the pre-breach raw row must not replace the current depleted row',
        );
      }
    },
  );

  test(
    'sub-minute trade border keeps directional bias but crosses both sides',
    () {
      final risingPulses = [
        for (var pulse = 1; pulse <= 400; pulse++)
          gameOrderBookTradePulse(
            assetId: assetId,
            day: day,
            minute: minute,
            previousPrice: 10000,
            currentPrice: 10050,
            executionCapacity: 5000,
            market: 'main',
            simulationSeed: simulationSeed,
            liquidityPulse: pulse,
          )!,
      ];
      final buyAggressorRatio =
          risingPulses.where((pulse) => pulse.isBuyAggressor).length /
          risingPulses.length;
      expect(buyAggressorRatio, inInclusiveRange(0.60, 0.85));
      expect(risingPulses.any((pulse) => !pulse.isBuyAggressor), isTrue);

      final flatBaseline = gameOrderBookTradePulse(
        assetId: assetId,
        day: day,
        minute: minute,
        previousPrice: 10000,
        currentPrice: 10000,
        executionCapacity: 5000,
        market: 'main',
        simulationSeed: simulationSeed,
      )!;
      final flatPulses = [
        for (var pulse = 1; pulse <= 400; pulse++)
          gameOrderBookTradePulse(
            assetId: assetId,
            day: day,
            minute: minute,
            previousPrice: 10000,
            currentPrice: 10000,
            executionCapacity: 5000,
            market: 'main',
            simulationSeed: simulationSeed,
            liquidityPulse: pulse,
          )!,
      ];
      final stickyRatio =
          flatPulses
              .where((pulse) => pulse.levelSide == flatBaseline.levelSide)
              .length /
          flatPulses.length;
      expect(stickyRatio, inInclusiveRange(0.65, 0.80));
      expect(
        flatPulses.any((pulse) => pulse.levelSide != flatBaseline.levelSide),
        isTrue,
      );

      final repeated = gameOrderBookTradePulse(
        assetId: assetId,
        day: day,
        minute: minute,
        previousPrice: 10000,
        currentPrice: 10050,
        executionCapacity: 5000,
        market: 'main',
        simulationSeed: simulationSeed,
        liquidityPulse: 37,
      )!;
      expect(repeated.levelSide, risingPulses[36].levelSide);
      expect(repeated.quantity, risingPulses[36].quantity);

      final firstFrame = snapshot(
        pulse: 1,
        currentPrice: 10050,
        previousTradePrice: 10000,
      );
      final secondFrame = snapshot(
        pulse: 2,
        currentPrice: 10050,
        previousTradePrice: 10000,
      );
      expect(
        levels(firstFrame).map((level) => level.price),
        orderedEquals(levels(secondFrame).map((level) => level.price)),
        reason: '체결 방향 테두리만 바뀌고 가격 사다리 전체가 움직이면 안 된다.',
      );
    },
  );

  test('adaptive pulses 1 through 12 stay within one execution capacity', () {
    const executionCapacity = 100000;

    for (final currentPrice in [10000.0, 11000.0]) {
      var totalRequested = 0;
      for (var pulse = 1; pulse <= 12; pulse += 1) {
        final tradePulse = gameOrderBookTradePulse(
          assetId: assetId,
          day: day,
          minute: minute,
          previousPrice: 10000,
          currentPrice: currentPrice,
          executionCapacity: executionCapacity,
          market: 'main',
          simulationSeed: simulationSeed,
          liquidityPulse: pulse,
        )!;
        totalRequested += tradePulse.quantity;

        if (pulse < 12) {
          expect(
            totalRequested,
            lessThan(executionCapacity),
            reason:
                'adaptive pulse $pulse exhausted the minute capacity too early',
          );
        }
      }

      expect(totalRequested, lessThanOrEqualTo(executionCapacity));
    }
  });

  test(
    'synthetic trade removes exact actual quantity at one absolute price',
    () {
      final raw = snapshot(pulse: 51);
      final target = raw.asks.first;
      expect(target.quantity, greaterThan(30));
      const ledgerConsumption = 7.0;
      const requestedQuantity = 13;
      final available = gameOrderBookSnapshotAfterConsumption(
        snapshot: raw,
        consumedAskByPrice: {target.price: ledgerConsumption},
        consumedCapacityUnits: ledgerConsumption.toInt(),
      );
      const pulse = GameOrderBookTradePulse(
        levelSide: GameOrderBookSide.ask,
        levelIndex: 0,
        quantity: requestedQuantity,
        crossedTicks: 1,
      );

      final applied = gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: raw,
        pulse: pulse,
        absolutePrice: target.price,
        previousSnapshot: raw,
        availableSnapshot: available,
        perMinuteBudgetUnits: 100,
      );
      final appliedTarget = byPrice(applied)[target.price]!;

      expect(target.quantity - appliedTarget.quantity, requestedQuantity);
      expect(
        applied.rememberedLevels[target.price]!.quantity,
        appliedTarget.quantity,
      );
      expect(applied.lastSyntheticTrade, isNotNull);
      expect(applied.lastSyntheticTrade!.marketMinute, minute);
      expect(applied.lastSyntheticTrade!.liquidityPulse, 51);
      expect(applied.lastSyntheticTrade!.levelSide, GameOrderBookSide.ask);
      expect(applied.lastSyntheticTrade!.price, target.price);
      expect(applied.lastSyntheticTrade!.quantity, requestedQuantity);
      expect(applied.syntheticTradeBudgetUsed, requestedQuantity);
      expect(applied.appliedAskConsumptionByPrice, isEmpty);
      expect(applied.appliedBidConsumptionByPrice, isEmpty);
      expect(applied.appliedCapacityConsumptionUnits, 0);

      final visible = gameOrderBookSnapshotAfterConsumption(
        snapshot: applied,
        consumedAskByPrice: {target.price: ledgerConsumption},
        consumedCapacityUnits: ledgerConsumption.toInt(),
      );
      expect(
        byPrice(visible)[target.price]!.quantity,
        target.quantity - requestedQuantity - ledgerConsumption.toInt(),
      );

      final appliedToLedgerNetted = gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: available,
        pulse: pulse,
        absolutePrice: target.price,
        previousSnapshot: available,
        availableSnapshot: available,
        perMinuteBudgetUnits: 100,
      );
      expect(
        appliedToLedgerNetted.appliedAskConsumptionByPrice,
        available.appliedAskConsumptionByPrice,
      );
      expect(
        appliedToLedgerNetted.appliedBidConsumptionByPrice,
        available.appliedBidConsumptionByPrice,
      );
      expect(
        appliedToLedgerNetted.appliedCapacityConsumptionUnits,
        available.appliedCapacityConsumptionUnits,
      );
    },
  );

  test(
    'synthetic trade token is idempotent and supports a diagnostic tombstone',
    () {
      final raw = snapshot(pulse: 52);
      final target = raw.asks.first;
      final pulse = GameOrderBookTradePulse(
        levelSide: GameOrderBookSide.ask,
        levelIndex: 0,
        quantity: target.quantity + 100,
        crossedTicks: 1,
      );
      final applied = gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: raw,
        pulse: pulse,
        absolutePrice: target.price,
        previousSnapshot: raw,
        availableSnapshot: raw,
        perMinuteBudgetUnits: target.quantity + 100,
      );

      expect(byPrice(applied)[target.price]!.quantity, 0);
      expect(applied.lastSyntheticTrade!.quantity, target.quantity);
      expect(applied.syntheticTradeBudgetUsed, target.quantity);

      final repeated = gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: applied,
        pulse: pulse,
        absolutePrice: target.price,
        previousSnapshot: raw,
        availableSnapshot: raw,
        perMinuteBudgetUnits: target.quantity + 100,
      );
      expect(repeated, same(applied));

      final visible = gameOrderBookSnapshotAfterConsumption(
        snapshot: applied,
        retainSyntheticTombstone: true,
      );
      final tombstone = visible.asks
          .where((level) => (level.price - target.price).abs() < 0.000001)
          .single;
      expect(tombstone.quantity, 0);
      expect(visible.lastSyntheticTrade, same(applied.lastSyntheticTrade));
    },
  );

  test('fractional consumption never rounds one partial share up', () {
    final raw = snapshot(pulse: 54);
    final target = raw.bids.first;

    final halfApplied = gameOrderBookSnapshotAfterConsumption(
      snapshot: raw,
      consumedBidByPrice: <double, double>{target.price: 0.5},
    );
    expect(
      byPrice(halfApplied)[target.price]!.quantity,
      target.quantity,
      reason: '0.5주는 정수 호가에서 1주가 빠진 것처럼 보여서는 안 됩니다.',
    );

    final wholeApplied = gameOrderBookSnapshotAfterConsumption(
      snapshot: halfApplied,
      consumedBidByPrice: <double, double>{target.price: 1.0},
    );
    expect(byPrice(wholeApplied)[target.price]!.quantity, target.quantity - 1);

    final repeated = gameOrderBookSnapshotAfterConsumption(
      snapshot: wholeApplied,
      consumedBidByPrice: <double, double>{target.price: 1.0},
    );
    expect(
      byPrice(repeated)[target.price]!.quantity,
      target.quantity - 1,
      reason: '누적 소수 차감 watermark를 다시 적용해 이중 차감하면 안 됩니다.',
    );
  });

  test('same synthetic frame keeps its token without crossing quote sides', () {
    final raw = snapshot(pulse: 58);
    final target = raw.asks.first;
    const pulse = GameOrderBookTradePulse(
      levelSide: GameOrderBookSide.ask,
      levelIndex: 0,
      quantity: 9,
      crossedTicks: 1,
    );
    final applied = gameOrderBookSnapshotAfterSyntheticTrade(
      snapshot: raw,
      pulse: pulse,
      absolutePrice: target.price,
      previousSnapshot: raw,
      availableSnapshot: raw,
      perMinuteBudgetUnits: 100,
    );
    final remaining = byPrice(applied)[target.price]!.quantity;

    final moved = snapshot(
      pulse: 58,
      currentPrice: advanceTicks(10000, 8),
      previousTradePrice: 10000,
      previousSnapshot: applied,
    );
    final movedLevel = moved.rememberedLevels[target.price]!;
    expect(movedLevel.side, GameOrderBookSide.bid);
    expect(
      movedLevel.quantity,
      isNot(remaining),
      reason: '남은 매도 잔량을 같은 가격의 새 매수 큐로 넘기면 안 됩니다.',
    );
    expect(moved.lastSyntheticTrade, same(applied.lastSyntheticTrade));
    expect(moved.syntheticTradeBudgetUsed, applied.syntheticTradeBudgetUsed);

    final repeated = gameOrderBookSnapshotAfterSyntheticTrade(
      snapshot: moved,
      pulse: pulse,
      absolutePrice: target.price,
      previousSnapshot: applied,
      availableSnapshot: moved,
      perMinuteBudgetUnits: 100,
    );
    expect(repeated, same(moved));
    expect(
      repeated.rememberedLevels[target.price]!.quantity,
      movedLevel.quantity,
    );
  });

  test(
    'next pulse starts from prior raw quantity before subtracting its print',
    () {
      final raw = snapshot(pulse: 60);
      final target = raw.asks.first;
      expect(target.quantity, greaterThan(30));
      const firstPulse = GameOrderBookTradePulse(
        levelSide: GameOrderBookSide.ask,
        levelIndex: 0,
        quantity: 11,
        crossedTicks: 1,
      );
      final first = gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: raw,
        pulse: firstPulse,
        absolutePrice: target.price,
        previousSnapshot: raw,
        availableSnapshot: raw,
        perMinuteBudgetUnits: 100,
      );
      final firstQuantity = byPrice(first)[target.price]!.quantity;

      final nextBuilt = snapshot(pulse: 61, previousSnapshot: first);
      const secondPulse = GameOrderBookTradePulse(
        levelSide: GameOrderBookSide.ask,
        levelIndex: 0,
        quantity: 5,
        crossedTicks: 1,
      );
      final second = gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: nextBuilt,
        pulse: secondPulse,
        absolutePrice: target.price,
        previousSnapshot: first,
        availableSnapshot: nextBuilt,
        perMinuteBudgetUnits: 100,
      );

      expect(byPrice(second)[target.price]!.quantity, firstQuantity - 5);
      expect(second.lastSyntheticTrade!.liquidityPulse, 61);
      expect(second.lastSyntheticTrade!.quantity, 5);
      expect(second.syntheticTradeBudgetUsed, 16);

      final sameFrameRebuild = snapshot(pulse: 61, previousSnapshot: second);
      expect(
        byPrice(sameFrameRebuild)[target.price]!.quantity,
        byPrice(second)[target.price]!.quantity,
      );
      expect(
        sameFrameRebuild.lastSyntheticTrade,
        same(second.lastSyntheticTrade),
      );
      expect(sameFrameRebuild.syntheticTradeBudgetUsed, 16);
    },
  );

  test('synthetic minute budget caps prints and resets on minute advance', () {
    final raw = snapshot(pulse: 70);
    final target = raw.asks.first;
    expect(target.quantity, greaterThan(20));
    const pulseQuantity = 4;
    const budget = 6;

    GameOrderBookSnapshot applyAtPulse(
      GameOrderBookSnapshot built,
      GameOrderBookSnapshot previous,
    ) {
      return gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: built,
        pulse: const GameOrderBookTradePulse(
          levelSide: GameOrderBookSide.ask,
          levelIndex: 0,
          quantity: pulseQuantity,
          crossedTicks: 1,
        ),
        absolutePrice: target.price,
        previousSnapshot: previous,
        availableSnapshot: built,
        perMinuteBudgetUnits: budget,
      );
    }

    final first = applyAtPulse(raw, raw);
    final secondBuilt = snapshot(pulse: 71, previousSnapshot: first);
    final second = applyAtPulse(secondBuilt, first);
    final thirdBuilt = snapshot(pulse: 72, previousSnapshot: second);
    final third = applyAtPulse(thirdBuilt, second);

    expect(first.lastSyntheticTrade!.quantity, 4);
    expect(first.syntheticTradeBudgetUsed, 4);
    expect(second.lastSyntheticTrade!.quantity, 2);
    expect(second.syntheticTradeBudgetUsed, budget);
    expect(third.lastSyntheticTrade!.quantity, 0);
    expect(third.syntheticTradeBudgetUsed, budget);
    expect(target.quantity - byPrice(third)[target.price]!.quantity, budget);

    final nextMinuteBuilt = buildGameOrderBookSnapshot(
      assetId: assetId,
      day: day,
      minute: minute + 1,
      currentPrice: 10000,
      previousTradePrice: 10000,
      previousClose: 10000,
      date: date,
      market: 'main',
      simulationSeed: simulationSeed,
      sharesOutstanding: 120000000,
      previousSnapshot: third,
      previousSnapshotMinute: minute,
      liquidityPulse: 72,
      adaptiveLiquidityPulses: true,
    );
    expect(nextMinuteBuilt.lastSyntheticTrade, isNull);
    expect(nextMinuteBuilt.syntheticTradeBudgetUsed, 0);

    final nextTarget = nextMinuteBuilt.asks.first;
    final nextMinute = gameOrderBookSnapshotAfterSyntheticTrade(
      snapshot: nextMinuteBuilt,
      pulse: const GameOrderBookTradePulse(
        levelSide: GameOrderBookSide.ask,
        levelIndex: 0,
        quantity: pulseQuantity,
        crossedTicks: 1,
      ),
      absolutePrice: nextTarget.price,
      previousSnapshot: third,
      availableSnapshot: nextMinuteBuilt,
      perMinuteBudgetUnits: budget,
    );
    expect(nextMinute.lastSyntheticTrade!.marketMinute, minute + 1);
    expect(nextMinute.lastSyntheticTrade!.quantity, pulseQuantity);
    expect(nextMinute.syntheticTradeBudgetUsed, pulseQuantity);
  });

  test(
    'engine fills from the exact microstructure snapshot shown to the user',
    () {
      const engine = GameEngine();
      final baseState = engine.createNewGame(
        'displayed-microstructure-frame',
        initialCash: 2000000000,
      );
      final state = baseState.copyWith(
        day: 4,
        marketMinute: minute,
        story: baseState.story.copyWith(accountAuthorityLevel: 5),
      );

      GameOrderBookSnapshot displayedSnapshot(int pulse) =>
          buildGameOrderBookSnapshot(
            assetId: 'hanbit_telecom',
            day: marketLiquidityDayKey(state.currentDate),
            minute: state.marketMinute,
            currentPrice: 10000,
            previousClose: 10000,
            date: state.currentDate,
            market: 'main',
            simulationSeed: state.simulationSeed,
            liquidityPulse: pulse,
            adaptiveLiquidityPulses: true,
          );

      final legacyFrame = displayedSnapshot(0);
      final generated = displayedSnapshot(37);
      expect(generated.liquidityPulse, 37);
      expect(generated.adaptiveLiquidityPulses, isTrue);
      final firstAsk = generated.asks.first;
      final visibleAsks = <GameOrderBookLevel>[
        GameOrderBookLevel(
          side: firstAsk.side,
          price: firstAsk.price,
          quantity: 1,
          isWall: firstAsk.isWall,
          structuralKind: firstAsk.structuralKind,
          structuralStrength: firstAsk.structuralStrength,
          structuralHoldTicks: firstAsk.structuralHoldTicks,
          isStructuralWall: firstAsk.isStructuralWall,
          isStructuralBreached: firstAsk.isStructuralBreached,
          structuralVacuumMultiplier: firstAsk.structuralVacuumMultiplier,
          isPsychological: firstAsk.isPsychological,
          technicalPeriods: firstAsk.technicalPeriods,
          wasLiquidityPulseTouched: firstAsk.wasLiquidityPulseTouched,
        ),
        ...generated.asks.skip(1),
      ];
      final visibleAskTotal = visibleAsks.fold<int>(
        0,
        (sum, level) => sum + level.quantity,
      );
      final visible = GameOrderBookSnapshot(
        asks: visibleAsks,
        bids: generated.bids,
        turnoverEok: generated.turnoverEok,
        executionCapacity: generated.executionCapacity,
        totalAskQuantity: visibleAskTotal,
        totalBidQuantity: generated.totalBidQuantity,
        tradeStrength: generated.totalBidQuantity / visibleAskTotal * 100,
        liquidityPulse: generated.liquidityPulse,
        adaptiveLiquidityPulses: true,
        sourceAssetId: generated.sourceAssetId,
        sourceLiquidityDayKey: generated.sourceLiquidityDayKey,
        sourceDateKey: generated.sourceDateKey,
        sourceMarketMinute: generated.sourceMarketMinute,
        sourceLastTradePrice: generated.sourceLastTradePrice,
        sourceMarket: generated.sourceMarket,
        sourceSimulationSeed: generated.sourceSimulationSeed,
      );
      const requestedQuantity = 2;
      final availableCapacity = visible.executionCapacity;
      final maximumNotional = gameBuyNotionalBudget(
        state,
        maximumNotional: math.min(
          gameMarketOrderNotionalLimit(10000, turnoverEok: visible.turnoverEok),
          gameOrderAuthorityLimit(state),
        ),
      );
      final expected = gameOrderBookLimitFillPlan(
        snapshot: visible,
        isBuy: true,
        requestedQuantity: requestedQuantity.toDouble(),
        limitPrice: marketDailyPriceRange(
          previousClose: 10000,
          date: state.currentDate,
          market: 'main',
        ).upper,
        availableCapacity: availableCapacity,
        maximumNotional: maximumNotional,
      );
      final legacyPlan = gameOrderBookLimitFillPlan(
        snapshot: legacyFrame,
        isBuy: true,
        requestedQuantity: requestedQuantity.toDouble(),
        limitPrice: marketDailyPriceRange(
          previousClose: 10000,
          date: state.currentDate,
          market: 'main',
        ).upper,
        availableCapacity: legacyFrame.executionCapacity,
        maximumNotional: maximumNotional,
      );

      expect(expected.hasFill, isTrue);
      expect(expected.filledQuantity, requestedQuantity);
      expect(
        expected.averagePrice,
        isNot(legacyPlan.averagePrice),
        reason: '이 fixture는 frame 0을 재생성하면 다른 체결 결과가 나와야 한다.',
      );

      final result = engine.executeTrade(
        state,
        TradeOrder(
          side: TradeSide.buy,
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: 'main',
          currency: 'KRW',
          quantity: requestedQuantity.toDouble(),
          unitPrice: 10000,
          quoteDate: marketDateKey(state.currentDate),
          marketMinute: state.marketMinute,
          isTradingDay: true,
          previousClose: 10000,
          microstructureFrame: visible.liquidityPulse,
          displayedSnapshot: visible,
        ),
      );

      expect(result.success, isTrue);
      expect(result.filledQuantity, expected.filledQuantity);
      expect(result.notional, expected.notional);
      expect(result.averageFillPrice, expected.averagePrice);
    },
  );

  test(
    'engine rejects displayed books with stale minute, asset, pulse, or price',
    () {
      const engine = GameEngine();
      final baseState = engine.createNewGame(
        'stale-displayed-microstructure',
        initialCash: 2000000000,
      );
      final state = baseState.copyWith(
        day: 4,
        marketMinute: minute,
        story: baseState.story.copyWith(accountAuthorityLevel: 5),
      );

      GameOrderBookSnapshot displayed({
        String sourceAssetId = 'hanbit_telecom',
        int sourceMinute = minute,
        double sourcePrice = 10000,
        int pulse = 41,
      }) => buildGameOrderBookSnapshot(
        assetId: sourceAssetId,
        day: marketLiquidityDayKey(state.currentDate),
        minute: sourceMinute,
        currentPrice: sourcePrice,
        previousClose: 10000,
        date: state.currentDate,
        market: 'main',
        simulationSeed: state.simulationSeed,
        liquidityPulse: pulse,
        adaptiveLiquidityPulses: true,
      );

      TradeOrder order({
        required GameOrderBookSnapshot snapshot,
        TradeOrderType type = TradeOrderType.market,
        int pulse = 41,
        double unitPrice = 10000,
      }) => TradeOrder(
        side: TradeSide.buy,
        assetId: 'hanbit_telecom',
        symbol: '1001',
        name: '한빛통신',
        market: 'main',
        currency: 'KRW',
        quantity: 2,
        unitPrice: unitPrice,
        quoteDate: marketDateKey(state.currentDate),
        marketMinute: state.marketMinute,
        isTradingDay: true,
        type: type,
        limitPrice: type == TradeOrderType.limit ? 13000 : null,
        previousClose: 10000,
        microstructureFrame: pulse,
        displayedSnapshot: snapshot,
      );

      final cases = <({String name, TradeOrder order})>[
        (
          name: 'stale minute',
          order: order(snapshot: displayed(sourceMinute: minute - 1)),
        ),
        (
          name: 'wrong asset',
          order: order(
            snapshot: displayed(sourceAssetId: 'another_asset'),
            type: TradeOrderType.limit,
          ),
        ),
        (name: 'wrong pulse', order: order(snapshot: displayed(), pulse: 42)),
        (
          name: 'wrong price',
          order: order(
            snapshot: displayed(),
            type: TradeOrderType.limit,
            unitPrice: 10100,
          ),
        ),
      ];

      for (final testCase in cases) {
        final result = engine.executeTrade(state, testCase.order);
        expect(result.success, isFalse, reason: testCase.name);
        expect(result.message, contains('시세가 바뀌었습니다'), reason: testCase.name);
        expect(result.state, same(state), reason: testCase.name);
      }
    },
  );

  test(
    'partial same-side prints stay on one price while counter-side prints may bounce',
    () {
      GameOrderBookSnapshot manualBook({
        required int pulse,
        int bestAskQuantity = 20000,
        int bestBidQuantity = 18000,
        GameOrderBookSyntheticTrade? lastTrade,
        int budgetUsed = 0,
      }) {
        final asks = <GameOrderBookLevel>[
          GameOrderBookLevel(
            side: GameOrderBookSide.ask,
            price: 10000,
            quantity: bestAskQuantity,
            isWall: false,
          ),
          const GameOrderBookLevel(
            side: GameOrderBookSide.ask,
            price: 10050,
            quantity: 9000,
            isWall: false,
          ),
        ];
        final bids = <GameOrderBookLevel>[
          GameOrderBookLevel(
            side: GameOrderBookSide.bid,
            price: 9990,
            quantity: bestBidQuantity,
            isWall: false,
          ),
          const GameOrderBookLevel(
            side: GameOrderBookSide.bid,
            price: 9980,
            quantity: 8000,
            isWall: false,
          ),
        ];
        return GameOrderBookSnapshot(
          asks: asks,
          bids: bids,
          turnoverEok: 100,
          executionCapacity: 100000,
          totalAskQuantity: asks.fold(0, (sum, level) => sum + level.quantity),
          totalBidQuantity: bids.fold(0, (sum, level) => sum + level.quantity),
          tradeStrength: 100,
          liquidityPulse: pulse,
          adaptiveLiquidityPulses: true,
          sourceAssetId: assetId,
          sourceLiquidityDayKey: day,
          sourceDateKey: marketDateKey(date),
          sourceMarketMinute: minute,
          sourceLastTradePrice: 10000,
          sourceMarket: 'main',
          sourceSimulationSeed: simulationSeed,
          lastSyntheticTrade: lastTrade,
          syntheticTradeBudgetUsed: budgetUsed,
        );
      }

      final firstBook = manualBook(pulse: 0);
      final firstAsk = gameOrderBookFirstExecutableLevel(
        snapshot: firstBook,
        side: GameOrderBookSide.ask,
      )!;
      final afterThreeThousand = gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: firstBook,
        pulse: const GameOrderBookTradePulse(
          levelSide: GameOrderBookSide.ask,
          levelIndex: 0,
          quantity: 3000,
          crossedTicks: 1,
        ),
        absolutePrice: firstAsk.price,
      );
      expect(afterThreeThousand.asks.first.price, 10000);
      expect(afterThreeThousand.asks.first.quantity, 17000);

      final nextBook = manualBook(
        pulse: 1,
        bestAskQuantity: afterThreeThousand.asks.first.quantity,
        lastTrade: afterThreeThousand.lastSyntheticTrade,
        budgetUsed: afterThreeThousand.syntheticTradeBudgetUsed,
      );
      final nextSameSide = gameOrderBookFirstExecutableLevel(
        snapshot: nextBook,
        side: GameOrderBookSide.ask,
      )!;
      expect(
        nextSameSide.price,
        firstAsk.price,
        reason: '17,000주가 남은 같은 매도호가를 다음 매수체결이 건너뛰면 안 됩니다.',
      );

      final afterSameSide = gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: nextBook,
        pulse: const GameOrderBookTradePulse(
          levelSide: GameOrderBookSide.ask,
          levelIndex: 0,
          quantity: 2000,
          crossedTicks: 1,
        ),
        absolutePrice: nextSameSide.price,
      );
      expect(afterSameSide.asks.first.quantity, 15000);
      expect(afterSameSide.lastSyntheticTrade?.price, firstAsk.price);

      final counterBook = manualBook(
        pulse: 1,
        bestAskQuantity: afterThreeThousand.asks.first.quantity,
        lastTrade: afterThreeThousand.lastSyntheticTrade,
        budgetUsed: afterThreeThousand.syntheticTradeBudgetUsed,
      );
      final counterSide = gameOrderBookFirstExecutableLevel(
        snapshot: counterBook,
        side: GameOrderBookSide.bid,
      )!;
      final afterCounterSide = gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: counterBook,
        pulse: const GameOrderBookTradePulse(
          levelSide: GameOrderBookSide.bid,
          levelIndex: 0,
          quantity: 1200,
          crossedTicks: 1,
        ),
        absolutePrice: counterSide.price,
      );
      expect(afterCounterSide.lastSyntheticTrade?.price, 9990);
      expect(afterCounterSide.asks.first.quantity, 17000);
      expect(afterCounterSide.bids.first.quantity, 16800);

      final depletionBook = manualBook(
        pulse: 2,
        bestAskQuantity: 17000,
        lastTrade: afterCounterSide.lastSyntheticTrade,
        budgetUsed: afterCounterSide.syntheticTradeBudgetUsed,
      );
      final depleted = gameOrderBookSnapshotAfterSyntheticTrade(
        snapshot: depletionBook,
        pulse: const GameOrderBookTradePulse(
          levelSide: GameOrderBookSide.ask,
          levelIndex: 0,
          quantity: 17000,
          crossedTicks: 1,
        ),
        absolutePrice: 10000,
      );
      final afterDepletion = manualBook(
        pulse: 3,
        bestAskQuantity: depleted.asks.first.quantity,
        lastTrade: depleted.lastSyntheticTrade,
        budgetUsed: depleted.syntheticTradeBudgetUsed,
      );
      expect(
        gameOrderBookFirstExecutableLevel(
          snapshot: afterDepletion,
          side: GameOrderBookSide.ask,
        )?.price,
        10050,
        reason: '최우선 행이 정확히 0주가 된 다음에만 같은 방향 다음 가격으로 진행해야 합니다.',
      );
    },
  );
}
