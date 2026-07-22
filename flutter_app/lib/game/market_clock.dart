import 'market_tick.dart';

const marketDayStartMinute = 8 * 60;
const krxOpenMinute = 9 * 60;
const krxContinuousEndMinute = 15 * 60 + 20;
const krxCloseMinute = 15 * 60 + 30;
const marketDayEndMinute = 20 * 60;
const marketTickMinutes = 1;
const krxCloseTick = 450;

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

const _krxClosedWeekdays = <String>{
  '2000-01-03',
  '2005-12-30',
  '2006-01-30',
  '2006-03-01',
  '2006-05-01',
  '2006-05-05',
  '2006-06-06',
  '2006-07-17',
  '2006-08-15',
  '2006-10-03',
  '2006-10-05',
  '2006-10-06',
  '2006-12-25',
  '2006-12-29',
  '2007-01-01',
  '2007-02-19',
  '2007-03-02',
  '2007-05-01',
  '2007-05-24',
  '2007-06-06',
  '2007-07-17',
  '2007-08-15',
  '2007-09-24',
  '2007-09-25',
  '2007-09-26',
  '2007-10-03',
  '2007-12-19',
  '2007-12-25',
  '2007-12-31',
  '2008-01-01',
  '2008-02-06',
  '2008-02-07',
  '2008-02-08',
  '2008-04-09',
  '2009-01-01',
  '2009-01-26',
  '2009-01-27',
  '2009-05-01',
  '2009-05-05',
  '2009-10-02',
  '2009-12-25',
  '2009-12-31',
  '2010-01-01',
  '2010-02-15',
  '2010-03-01',
  '2010-05-05',
  '2010-05-21',
  '2010-06-02',
  '2010-09-21',
  '2010-09-22',
  '2010-09-23',
  '2010-12-31',
};

String marketDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

bool isMarketTradingDay(DateTime date) {
  if (date.weekday >= DateTime.saturday) return false;
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
  return !fixedHoliday && !_krxClosedWeekdays.contains(marketDateKey(date));
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
  if (value < marketDayEndMinute) {
    return const MarketClockInfo(
      phase: MarketSessionPhase.closeSettlement,
      label: '오늘 장 마감',
      description: '15:30 종가 확정 · 추가 거래 없음',
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
