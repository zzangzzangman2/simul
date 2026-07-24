import 'dart:math' as math;

import 'market_clock.dart';

enum GameOrderBookSide { ask, bid }

class GameOrderBookLevel {
  const GameOrderBookLevel({
    required this.side,
    required this.price,
    required this.quantity,
    required this.isWall,
  });

  final GameOrderBookSide side;
  final double price;
  final int quantity;
  final bool isWall;
}

class GameOrderBookSnapshot {
  const GameOrderBookSnapshot({
    required this.asks,
    required this.bids,
    required this.turnoverEok,
    required this.executionCapacity,
    required this.totalAskQuantity,
    required this.totalBidQuantity,
    required this.tradeStrength,
  });

  final List<GameOrderBookLevel> asks;
  final List<GameOrderBookLevel> bids;
  final double turnoverEok;
  final int executionCapacity;
  final int totalAskQuantity;
  final int totalBidQuantity;
  final double tradeStrength;
}

class GameOrderBookTradePulse {
  const GameOrderBookTradePulse({
    required this.levelSide,
    required this.levelIndex,
    required this.quantity,
  });

  /// 매수자가 매도호가를 먹으면 ask, 매도자가 매수호가를 먹으면 bid다.
  final GameOrderBookSide levelSide;
  final int levelIndex;
  final int quantity;

  bool get isBuyAggressor => levelSide == GameOrderBookSide.ask;
}

class GameOrderBookLevelFill {
  const GameOrderBookLevelFill({
    required this.levelIndex,
    required this.price,
    required this.quantity,
  });

  final int levelIndex;
  final double price;
  final int quantity;
}

class GameOrderBookFillPlan {
  const GameOrderBookFillPlan({
    required this.levelSide,
    required this.fills,
    required this.filledQuantity,
    required this.notional,
    required this.averagePrice,
    required this.worstPrice,
  });

  final GameOrderBookSide levelSide;
  final List<GameOrderBookLevelFill> fills;
  final int filledQuantity;
  final int notional;
  final double averagePrice;
  final double worstPrice;

  bool get hasFill => filledQuantity > 0;
}

/// 현재까지의 가상 거래대금(억원)을 종목·날짜·시각으로 재현한다.
///
/// 같은 월드 상태에서는 같은 값이 나오며, 장중 누적 거래대금이 커질수록
/// 호가 잔량과 한 분에 소화할 수 있는 지정가 수량도 함께 커진다.
double gameEstimatedTurnoverEok({
  required String assetId,
  required int day,
  required int minute,
  required double unitPrice,
}) {
  if (assetId.isEmpty || !unitPrice.isFinite || unitPrice <= 0) return 0;
  if (minute < krxOpenMinute) return 0;
  final assetHash = _orderBookHash(assetId, day, 0);
  final fullDayTurnover = 24.0 + assetHash % 760;
  final elapsed = (minute - krxOpenMinute + 1)
      .clamp(1, krxCloseMinute - krxOpenMinute)
      .toDouble();
  final progress = elapsed / (krxCloseMinute - krxOpenMinute);
  final accumulationCurve = math.sqrt(progress) * 0.72 + progress * 0.28;
  final priceFactor = math
      .pow(10000 / unitPrice, 0.08)
      .toDouble()
      .clamp(0.72, 1.28);
  return fullDayTurnover * accumulationCurve * priceFactor;
}

/// 현재 호가에서 한 게임 분 동안 실제로 소화 가능한 지정가 수량.
///
/// 호가창과 주문 엔진이 이 함수를 함께 사용하므로 화면의 거래대금·벽 규모와
/// 부분체결 한도가 서로 따로 움직이지 않는다.
int gameOrderBookExecutionCapacity({
  required String assetId,
  required int day,
  required int minute,
  required double unitPrice,
}) {
  if (!marketClockAt(minute, tradingDay: true).tradable) return 0;
  final turnoverEok = gameEstimatedTurnoverEok(
    assetId: assetId,
    day: day,
    minute: minute,
    unitPrice: unitPrice,
  );
  if (turnoverEok <= 0) return 0;
  final elapsed = (minute - krxOpenMinute + 1)
      .clamp(1, krxCloseMinute - krxOpenMinute)
      .toDouble();
  final averageUnitsPerMinute =
      turnoverEok * 100000000 / unitPrice / math.max(15, elapsed);
  final pulse = 0.22 + _orderBookUnit(assetId, day, minute * 17 + 31) * 0.78;
  final auctionMultiplier =
      minute < krxOpenMinute + 5 || minute >= krxContinuousEndMinute
      ? 1.6
      : 1.0;
  final raw = (averageUnitsPerMinute * pulse * 0.48 * auctionMultiplier)
      .round();
  final notionalCap = (unitPrice * 50000).round().clamp(5000000, 2000000000);
  final maximum = math.min(4200, notionalCap ~/ unitPrice);
  if (maximum <= 0) return 0;
  return raw.clamp(1, maximum);
}

/// 최근 체결이 어느 호가를 소화했는지 표시할 이동 네모를 만든다.
///
/// 가격 상승은 매수자가 매도호가를 먹은 체결, 가격 하락은 매도자가
/// 매수호가를 먹은 체결로 본다. 보합 틱도 실제 장처럼 양쪽에서 번갈아
/// 체결되도록 같은 시드에서 재현 가능한 방향과 수량을 만든다.
GameOrderBookTradePulse? gameOrderBookTradePulse({
  required String assetId,
  required int day,
  required int minute,
  required double previousPrice,
  required double currentPrice,
  required int executionCapacity,
  required String market,
  int levelCount = 5,
}) {
  if (assetId.isEmpty ||
      levelCount <= 0 ||
      executionCapacity <= 0 ||
      !previousPrice.isFinite ||
      !currentPrice.isFinite ||
      previousPrice <= 0 ||
      currentPrice <= 0) {
    return null;
  }
  final delta = currentPrice - previousPrice;
  final hash = _orderBookHash(assetId, day, minute * 73 + 2203);
  final side = delta > 0
      ? GameOrderBookSide.ask
      : delta < 0
      ? GameOrderBookSide.bid
      : hash.isEven
      ? GameOrderBookSide.ask
      : GameOrderBookSide.bid;
  final tick = marketTickSize(previousPrice, market: market);
  final crossedTicks = delta == 0
      ? 1 + hash % 2
      : math.max(1, (delta.abs() / tick).round());
  final index = (crossedTicks - 1).clamp(0, levelCount - 1);
  final participation = 0.08 + (hash % 25) / 100;
  final quantity = math.max(1, (executionCapacity * participation).round());
  return GameOrderBookTradePulse(
    levelSide: side,
    levelIndex: index,
    quantity: quantity,
  );
}

/// 화면에 표시된 반대편 호가를 가격 순서대로 실제 소모한다.
///
/// 지정가 매수는 지정가 이하 매도호가만, 지정가 매도는 지정가 이상
/// 매수호가만 체결한다. [availableCapacity]는 같은 분에 이미 체결된
/// 수량을 제외한 잔여 분당 소화량이다.
GameOrderBookFillPlan gameOrderBookLimitFillPlan({
  required GameOrderBookSnapshot snapshot,
  required bool isBuy,
  required double requestedQuantity,
  required double limitPrice,
  int? availableCapacity,
}) {
  final side = isBuy ? GameOrderBookSide.ask : GameOrderBookSide.bid;
  final capacity = math.min(
    snapshot.executionCapacity,
    availableCapacity ?? snapshot.executionCapacity,
  );
  if (!requestedQuantity.isFinite ||
      requestedQuantity <= 0 ||
      !limitPrice.isFinite ||
      limitPrice <= 0 ||
      capacity <= 0) {
    return GameOrderBookFillPlan(
      levelSide: side,
      fills: const [],
      filledQuantity: 0,
      notional: 0,
      averagePrice: 0,
      worstPrice: 0,
    );
  }

  final levels = isBuy ? snapshot.asks : snapshot.bids;
  final fills = <GameOrderBookLevelFill>[];
  var remaining = math.min(requestedQuantity.floor(), capacity);
  var filled = 0;
  var notional = 0;
  var worstPrice = 0.0;
  for (var index = 0; index < levels.length && remaining > 0; index++) {
    final level = levels[index];
    final withinLimit = isBuy
        ? level.price <= limitPrice + 0.000001
        : level.price + 0.000001 >= limitPrice;
    if (!withinLimit) break;
    final quantity = math.min(level.quantity, remaining);
    if (quantity <= 0) continue;
    fills.add(
      GameOrderBookLevelFill(
        levelIndex: index,
        price: level.price,
        quantity: quantity,
      ),
    );
    filled += quantity;
    remaining -= quantity;
    notional += (level.price * quantity).round();
    worstPrice = level.price;
  }
  return GameOrderBookFillPlan(
    levelSide: side,
    fills: List.unmodifiable(fills),
    filledQuantity: filled,
    notional: notional,
    averagePrice: filled <= 0 ? 0 : notional / filled,
    worstPrice: worstPrice,
  );
}

double gameOrderBookQueueAhead({
  required GameOrderBookSnapshot snapshot,
  required bool isBuy,
  required double limitPrice,
}) {
  final levels = isBuy ? snapshot.bids : snapshot.asks;
  for (final level in levels) {
    if ((level.price - limitPrice).abs() < 0.000001) {
      return level.quantity.toDouble();
    }
  }
  return 0;
}

GameOrderBookSnapshot buildGameOrderBookSnapshot({
  required String assetId,
  required int day,
  required int minute,
  required double currentPrice,
  required double previousClose,
  required DateTime date,
  required String market,
  int levelCount = 5,
  bool tradingDay = true,
}) {
  final safePreviousClose = previousClose > 0 ? previousClose : currentPrice;
  final range = marketDailyPriceRange(
    previousClose: safePreviousClose,
    date: date,
    market: market,
  );
  final center = marketSnapPrice(
    currentPrice.clamp(range.lower, range.upper).toDouble(),
    market: market,
  );
  final tradable =
      tradingDay && marketClockAt(minute, tradingDay: true).tradable;
  final executionCapacity = tradable
      ? gameOrderBookExecutionCapacity(
          assetId: assetId,
          day: day,
          minute: minute,
          unitPrice: center,
        )
      : 0;
  final turnoverEok = tradingDay
      ? gameEstimatedTurnoverEok(
          assetId: assetId,
          day: day,
          minute: minute,
          unitPrice: center,
        )
      : 0.0;
  final baseDepth = math.max(20, (executionCapacity * 1.35).round());
  final askWallIndex = _orderBookHash(assetId, day, 701) % levelCount;
  final bidWallIndex = _orderBookHash(assetId, day, 907) % levelCount;
  final asks = <GameOrderBookLevel>[];
  final bids = <GameOrderBookLevel>[];

  var askPrice = marketSnapPrice(
    center + marketTickSize(center, market: market),
    market: market,
  );
  for (var index = 0; index < levelCount; index++) {
    if (askPrice > range.upper + 0.000001) break;
    asks.add(
      _buildLevel(
        side: GameOrderBookSide.ask,
        assetId: assetId,
        day: day,
        minute: minute,
        index: index,
        price: askPrice,
        baseDepth: baseDepth,
        wallIndex: askWallIndex,
      ),
    );
    final tick = marketTickSize(askPrice, market: market);
    final next = marketSnapPrice(askPrice + tick, market: market);
    if (next <= askPrice) break;
    askPrice = next;
  }

  var bidPrice = center;
  for (var index = 0; index < levelCount; index++) {
    if (bidPrice < range.lower - 0.000001 || bidPrice <= 0) break;
    bids.add(
      _buildLevel(
        side: GameOrderBookSide.bid,
        assetId: assetId,
        day: day,
        minute: minute,
        index: index,
        price: bidPrice,
        baseDepth: baseDepth,
        wallIndex: bidWallIndex,
      ),
    );
    final tick = marketTickSize(bidPrice, market: market);
    final next = marketSnapPrice(bidPrice - tick, market: market);
    if (next >= bidPrice) break;
    bidPrice = next;
  }

  final totalAsk = asks.fold<int>(0, (sum, level) => sum + level.quantity);
  final totalBid = bids.fold<int>(0, (sum, level) => sum + level.quantity);
  final strength = totalAsk <= 0
      ? 100.0
      : (totalBid / totalAsk * 100).clamp(20, 240).toDouble();
  return GameOrderBookSnapshot(
    asks: List.unmodifiable(asks),
    bids: List.unmodifiable(bids),
    turnoverEok: turnoverEok,
    executionCapacity: executionCapacity,
    totalAskQuantity: totalAsk,
    totalBidQuantity: totalBid,
    tradeStrength: strength,
  );
}

GameOrderBookLevel _buildLevel({
  required GameOrderBookSide side,
  required String assetId,
  required int day,
  required int minute,
  required int index,
  required double price,
  required int baseDepth,
  required int wallIndex,
}) {
  final sideSalt = side == GameOrderBookSide.ask ? 1301 : 1709;
  final variation =
      0.62 +
      _orderBookUnit(assetId, day, minute * 41 + index * 97 + sideSalt) * 1.06;
  final wallMultiplier = index == wallIndex
      ? 4.2 + _orderBookUnit(assetId, day, minute + index + sideSalt) * 4.8
      : 1.0;
  return GameOrderBookLevel(
    side: side,
    price: price,
    quantity: math.max(1, (baseDepth * variation * wallMultiplier).round()),
    isWall: index == wallIndex,
  );
}

int _orderBookHash(String assetId, int day, int salt) {
  var hash = (day * 1009 + salt * 9176) & 0x7fffffff;
  for (final unit in assetId.codeUnits) {
    hash = ((hash * 31) ^ unit) & 0x7fffffff;
  }
  return hash;
}

double _orderBookUnit(String assetId, int day, int salt) =>
    (_orderBookHash(assetId, day, salt) % 10000) / 9999;
