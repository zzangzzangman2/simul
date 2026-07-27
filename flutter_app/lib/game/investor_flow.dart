import 'dart:math' as math;

import 'market_clock.dart';
import 'market_data.dart';
import 'order_book.dart';

class FictionalInvestorFlowDay {
  const FictionalInvestorFlowDay({
    required this.date,
    required this.closePrice,
    required this.tradedShares,
    required this.individual,
    required this.foreign,
    required this.financialInvestment,
    required this.investmentTrust,
    required this.pension,
    required this.insurance,
    required this.otherInstitution,
    required this.otherCorporation,
  });

  final DateTime date;
  final double closePrice;
  final int tradedShares;
  final int individual;
  final int foreign;
  final int financialInvestment;
  final int investmentTrust;
  final int pension;
  final int insurance;
  final int otherInstitution;
  final int otherCorporation;

  int get institution =>
      financialInvestment +
      investmentTrust +
      pension +
      insurance +
      otherInstitution;

  int get marketNet => individual + foreign + institution + otherCorporation;
}

List<FictionalInvestorFlowDay> buildFictionalInvestorFlowHistory({
  required String simulationSeed,
  required String assetId,
  required DateTime throughDate,
  required List<MarketPoint> priceHistory,
  required double currentPrice,
  required int sharesOutstanding,
  int? Function(DateTime date)? sharesOutstandingAt,
  double Function(DateTime date, double previousClose)? referenceCloseAt,
  int currentMarketMinute = krxCloseMinute,
  double? currentReferencePrice,
  int count = 13,
}) {
  if (count <= 0 || priceHistory.isEmpty) {
    return const <FictionalInvestorFlowDay>[];
  }
  final cutoff = DateTime(throughDate.year, throughDate.month, throughDate.day);
  final eligible = priceHistory
      .where((point) => !point.parsedDate.isAfter(cutoff))
      .where(
        (point) =>
            !_sameDay(point.parsedDate, cutoff) ||
            currentMarketMinute >= krxOpenMinute,
      )
      .toList(growable: false);
  if (eligible.isEmpty) return const <FictionalInvestorFlowDay>[];

  final firstVisibleIndex = math.max(0, eligible.length - count);
  final result = <FictionalInvestorFlowDay>[];
  for (var index = firstVisibleIndex; index < eligible.length; index += 1) {
    final point = eligible[index];
    final isCurrentDate = _sameDay(point.parsedDate, cutoff);
    final effectiveClose = isCurrentDate && currentPrice > 0
        ? currentPrice
        : point.close;
    final adjustedCurrentReference =
        isCurrentDate &&
            currentReferencePrice != null &&
            currentReferencePrice.isFinite &&
            currentReferencePrice > 0
        ? currentReferencePrice
        : null;
    final rawPreviousClose = index == 0
        ? effectiveClose
        : eligible[index - 1].close;
    final previousClose =
        adjustedCurrentReference ??
        referenceCloseAt?.call(point.parsedDate, rawPreviousClose) ??
        rawPreviousClose;
    final dailyLimit = marketDailyPriceLimitRate(point.parsedDate);
    final returnRate = previousClose <= 0
        ? 0.0
        : ((effectiveClose - previousClose) / previousClose).clamp(
            -dailyLimit,
            dailyLimit,
          );
    final momentum = returnRate / dailyLimit;
    final seed = _stableHash('$simulationSeed|$assetId|${point.date}');
    final marketDay = marketLiquidityDayKey(point.parsedDate);
    final outstanding = math.max(
      100000,
      sharesOutstandingAt?.call(point.parsedDate) ?? sharesOutstanding,
    );
    final fullDayTradedShares = gameEstimatedFullDayVolumeUnits(
      assetId: assetId,
      day: marketDay,
      referencePrice: previousClose,
      simulationSeed: simulationSeed,
      sharesOutstanding: outstanding,
    );
    final completedFraction = !isCurrentDate
        ? 1.0
        : gameTurnoverProgressAtMinute(currentMarketMinute);
    final tradedShares = (fullDayTradedShares * completedFraction).round();

    int flow(double share) => (tradedShares * share).round();

    final foreign = flow(_centered(seed, 2) * 0.11 + momentum * 0.045);
    final financialInvestment = flow(
      _centered(seed, 3) * 0.052 + momentum * 0.018,
    );
    final investmentTrust = flow(_centered(seed, 4) * 0.042 + momentum * 0.014);
    final pension = flow(_centered(seed, 5) * 0.032 + momentum * 0.012);
    final insurance = flow(_centered(seed, 6) * 0.025);
    final otherInstitution = flow(_centered(seed, 7) * 0.028);
    final otherCorporation = flow(_centered(seed, 8) * 0.035);
    final institution =
        financialInvestment +
        investmentTrust +
        pension +
        insurance +
        otherInstitution;
    final individual = -(foreign + institution + otherCorporation);

    result.add(
      FictionalInvestorFlowDay(
        date: point.parsedDate,
        closePrice: effectiveClose,
        tradedShares: tradedShares,
        individual: individual,
        foreign: foreign,
        financialInvestment: financialInvestment,
        investmentTrust: investmentTrust,
        pension: pension,
        insurance: insurance,
        otherInstitution: otherInstitution,
        otherCorporation: otherCorporation,
      ),
    );
  }
  return result.reversed.toList(growable: false);
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

int _stableHash(String value) {
  var hash = 17;
  for (final unit in value.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}

double _unit(int seed, int salt) {
  var value = (seed ^ ((salt * 0x45d9f3b) & 0x7fffffff)) & 0x7fffffff;
  value = (value * 1103515245 + 12345) & 0x7fffffff;
  return value / 0x7fffffff;
}

double _centered(int seed, int salt) => _unit(seed, salt) * 2 - 1;
