import 'market_corpus_calendar.dart';
import 'market_tick.dart';

const fictionalCampaignStartYear = 2000;
const fictionalCampaignEndYear = 2026;
const marketDayStartMinute = 8 * 60;
const krxOpenMinute = 9 * 60;
// 미래거래소는 실제 거래소를 복제하지 않는 가상시장이다. 저장·주문·차트의
// 일관성을 위해 2000~2026 캠페인 전체에서 15:00 마감을 사용한다.
const krxContinuousEndMinute = 14 * 60 + 50;
const krxCloseMinute = 15 * 60;
const marketDayEndMinute = 20 * 60;
const marketTickMinutes = 1;
const krxCloseTick = 420;

/// 주식시장 화면이 열려 있을 때 현실 1초마다 게임 시각 1분을 진행한다.
const marketRealtimeTickDuration = Duration(seconds: 1);

const decisionActionMinutes = 30;
const familyHelpActionMinutes = 30;
const workActionMinutes = 60;

int advanceGameTime(int currentMinute, int elapsedMinutes) =>
    (currentMinute + elapsedMinutes).clamp(
      marketDayStartMinute,
      marketDayEndMinute,
    );

enum MarketSessionPhase {
  openingTransition,
  regular,
  closingAuction,
  closeSettlement,
  closed,
  holiday,
}

class MarketClockInfo {
  const MarketClockInfo({
    required this.phase,
    required this.label,
    required this.description,
    required this.tradable,
  });
  final MarketSessionPhase phase;
  final String label;
  final String description;
  final bool tradable;
}

const _krxClosedWeekdays = <String>{'2000-01-03'};

String marketDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

bool isMarketTradingDay(DateTime date) {
  if (date.weekday >= DateTime.saturday) return false;
  final dateKey = marketDateKey(date);
  if (dateKey.compareTo(fictionalCorpusFirstTradingDate) >= 0 &&
      dateKey.compareTo(fictionalCorpusLastTradingDate) <= 0) {
    return fictionalCorpusTradingDateKeys.contains(dateKey);
  }

  final fixedHoliday = switch ((date.month, date.day)) {
    (1, 1) ||
    (3, 1) ||
    (5, 1) ||
    (5, 5) ||
    (6, 6) ||
    (7, 17) ||
    (8, 15) ||
    (10, 3) ||
    (12, 25) => true,
    _ => false,
  };
  return !fixedHoliday && !_krxClosedWeekdays.contains(dateKey);
}

MarketClockInfo marketClockAt(int minute, {bool tradingDay = true}) {
  if (!tradingDay) {
    return const MarketClockInfo(
      phase: MarketSessionPhase.holiday,
      label: '휴장',
      description: '오늘은 거래소가 쉬는 날이에요.',
      tradable: false,
    );
  }
  final value = minute.clamp(marketDayStartMinute, marketDayEndMinute);
  if (value < krxOpenMinute) {
    return const MarketClockInfo(
      phase: MarketSessionPhase.openingTransition,
      label: '개장 준비',
      description: '08:00~08:59 · 가격 고정 · 09:00 정규장 개장',
      tradable: false,
    );
  }
  if (value < krxContinuousEndMinute) {
    return const MarketClockInfo(
      phase: MarketSessionPhase.regular,
      label: '미래거래소 정규장',
      description: '09:00~14:50 · 접속매매',
      tradable: true,
    );
  }
  if (value < krxCloseMinute) {
    return const MarketClockInfo(
      phase: MarketSessionPhase.closingAuction,
      label: '장마감 동시호가',
      description: '14:50~15:00 · 종가를 결정하는 중',
      tradable: true,
    );
  }
  if (value < marketDayEndMinute) {
    return const MarketClockInfo(
      phase: MarketSessionPhase.closeSettlement,
      label: '오늘 장 마감',
      description: '15:00 종가 확정 · 추가 거래 없음',
      tradable: false,
    );
  }
  return const MarketClockInfo(
    phase: MarketSessionPhase.closed,
    label: '오늘 장 종료',
    description: '20:00 · 오늘 신문을 확인할 시간',
    tradable: false,
  );
}

String marketTimeLabel(int minute) {
  final value = minute.clamp(0, 23 * 60 + 59);
  final hour = (value ~/ 60).toString().padLeft(2, '0');
  final min = (value % 60).toString().padLeft(2, '0');
  return '$hour:$min';
}

int marketTickForMinute(int minute) =>
    ((minute.clamp(marketDayStartMinute, marketDayEndMinute) -
                marketDayStartMinute) /
            marketTickMinutes)
        .floor()
        .clamp(0, generatedSessionTicks);

int marketMinuteForTick(int tick) =>
    (marketDayStartMinute +
            tick.clamp(0, generatedSessionTicks) * marketTickMinutes)
        .clamp(marketDayStartMinute, marketDayEndMinute);

double marketDailyPriceLimitRate(DateTime date) {
  // 가격제한폭 확대 시점만 반영하고, 장 운영 시간은 가상시장 규칙을 따른다.
  if (date.isBefore(DateTime(2015, 6, 15))) return 0.15;
  return 0.30;
}

double marketTickSize(double price, {String market = '미래시장'}) {
  if (!price.isFinite || price <= 0) return 1;
  if (price < 1000) return 1;
  if (price < 5000) return 5;
  if (price < 10000) return 10;
  if (price < 50000) return 50;
  if (price < 100000) return 100;
  if (price < 500000) return market == '도전시장' ? 100 : 500;
  return market == '도전시장' ? 100 : 1000;
}

double marketSnapPrice(
  double price, {
  String market = '미래시장',
  bool roundDown = false,
}) {
  if (!price.isFinite || price <= 0) return 0;
  final tick = marketTickSize(price, market: market);
  final units = price / tick;
  return (roundDown ? units.floor() : units.round()) * tick;
}

({double lower, double upper}) marketDailyPriceRange({
  required double previousClose,
  required DateTime date,
  String market = '미래시장',
}) {
  if (!previousClose.isFinite || previousClose <= 0) {
    return (lower: 0, upper: 0);
  }
  final rate = marketDailyPriceLimitRate(date);
  final rawLower = previousClose * (1 - rate);
  final lowerTick = marketTickSize(rawLower, market: market);
  final lower = (rawLower / lowerTick).ceil() * lowerTick;
  final upper = marketSnapPrice(
    previousClose * (1 + rate),
    market: market,
    roundDown: true,
  );
  return (lower: lower, upper: upper);
}

bool isValidMarketOrderPrice(double price, {String market = '미래시장'}) {
  if (!price.isFinite || price <= 0) return false;
  final snapped = marketSnapPrice(price, market: market);
  return (snapped - price).abs() < 0.000001;
}
