import 'market_tick.dart';

const marketDayStartMinute = 8 * 60;
const nxtPreEndMinute = 8 * 60 + 50;
const krxOpenMinute = 9 * 60;
const krxContinuousEndMinute = 15 * 60 + 20;
const krxCloseMinute = 15 * 60 + 30;
const nxtAfterStartMinute = 15 * 60 + 40;
const marketDayEndMinute = 20 * 60;
const marketTickMinutes = 3;
const krxCloseTick = 150;

enum MarketSessionPhase {
  nxtPre,
  openingTransition,
  regular,
  closingAuction,
  closeSettlement,
  nxtAfter,
  closed,
  holiday,
}

class MarketClockInfo {
  const MarketClockInfo({
    required this.phase,
    required this.label,
    required this.description,
    required this.tradable,
    this.isGameExtension = false,
  });
  final MarketSessionPhase phase;
  final String label;
  final String description;
  final bool tradable;
  final bool isGameExtension;
}

bool isMarketTradingDay(DateTime date) {
  if (date.weekday >= DateTime.saturday) return false;
  return switch ((date.month, date.day)) {
    (1, 1) ||
    (3, 1) ||
    (5, 5) ||
    (6, 6) ||
    (8, 15) ||
    (10, 3) ||
    (12, 25) => false,
    _ => true,
  };
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
  if (value < nxtPreEndMinute) {
    return const MarketClockInfo(
      phase: MarketSessionPhase.nxtPre,
      label: 'NXT형 프리마켓',
      description: '08:00~08:50 · 게임용 확장 거래',
      tradable: true,
      isGameExtension: true,
    );
  }
  if (value < krxOpenMinute) {
    return const MarketClockInfo(
      phase: MarketSessionPhase.openingTransition,
      label: '개장 준비',
      description: '09:00 정규장 개장을 기다려요.',
      tradable: false,
    );
  }
  if (value < krxContinuousEndMinute) {
    return const MarketClockInfo(
      phase: MarketSessionPhase.regular,
      label: 'KRX 정규장',
      description: '09:00~15:20 · 접속매매',
      tradable: true,
    );
  }
  if (value < krxCloseMinute) {
    return const MarketClockInfo(
      phase: MarketSessionPhase.closingAuction,
      label: '장마감 동시호가',
      description: '15:20~15:30 · 종가를 결정하는 중',
      tradable: true,
    );
  }
  if (value < nxtAfterStartMinute) {
    return const MarketClockInfo(
      phase: MarketSessionPhase.closeSettlement,
      label: '정규장 마감',
      description: '15:30 종가 확정 · 확장장 준비',
      tradable: false,
    );
  }
  if (value < marketDayEndMinute) {
    return const MarketClockInfo(
      phase: MarketSessionPhase.nxtAfter,
      label: 'NXT형 애프터마켓',
      description: '15:40~20:00 · 게임용 확장 거래',
      tradable: true,
      isGameExtension: true,
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
