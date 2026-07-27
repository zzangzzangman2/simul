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
            '${level.wasLiquidityPulseTouched}',
      )
      .join('|');

  test(
    'adaptive cadence spans dormant low-liquidity to active high-liquidity',
    () {
      final dormant = gameOrderBookAdaptivePulseHz(
        fullDayTurnoverEok: 1,
        currentPrice: 10000,
        previousTradePrice: 10000,
        previousClose: 10000,
      );
      final ordinary = gameOrderBookAdaptivePulseHz(
        fullDayTurnoverEok: 100,
        currentPrice: 10000,
        previousTradePrice: 10000,
        previousClose: 10000,
      );
      final active = gameOrderBookAdaptivePulseHz(
        fullDayTurnoverEok: 60000,
        currentPrice: 10000,
        previousTradePrice: 10000,
        previousClose: 10000,
      );

      expect(dormant, gameOrderBookMinimumAdaptivePulseHz);
      expect(1 / dormant, greaterThanOrEqualTo(10));
      expect(ordinary, greaterThan(dormant));
      expect(active, greaterThan(ordinary));
      expect(active, 8);
      expect(
        (active * 10).floor(),
        greaterThan((dormant * 10).floor()),
        reason: '같은 10초 동안 고유동 종목이 더 많은 활성 펄스를 가져야 한다.',
      );
    },
  );

  test('fast and extreme moves enter 10-12 Hz but never exceed the cap', () {
    final fast = gameOrderBookAdaptivePulseHz(
      fullDayTurnoverEok: 1,
      currentPrice: 10150,
      previousTradePrice: 10000,
      previousClose: 10000,
      market: 'main',
    );
    final extreme = gameOrderBookAdaptivePulseHz(
      fullDayTurnoverEok: 1,
      currentPrice: 10300,
      previousTradePrice: 10000,
      previousClose: 10000,
      market: 'main',
    );
    final extremeHighLiquidity = gameOrderBookAdaptivePulseHz(
      fullDayTurnoverEok: 1000000,
      currentPrice: 13000,
      previousTradePrice: 10000,
      previousClose: 10000,
      market: 'main',
      tradeStrength: 500,
    );

    expect(fast, inInclusiveRange(10, 12));
    expect(extreme, 12);
    expect(extremeHighLiquidity, gameOrderBookMaximumAdaptivePulseHz);
  });

  test('closed sessions and paused playback emit no pulse', () {
    double cadence({
      bool tradingSessionActive = true,
      bool playbackActive = true,
    }) => gameOrderBookAdaptivePulseHz(
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
        byPrice(shifted),
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
    expect(byPrice(breachedOffscreen), isNot(contains(support.price)));
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
    final returnedLevel = byPrice(returned)[support.price]!;

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
  });

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
}
