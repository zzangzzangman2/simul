import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/investor_flow.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/order_book.dart';

void main() {
  const history = <MarketPoint>[
    MarketPoint(date: '2000-01-03', close: 10000),
    MarketPoint(date: '2000-01-04', close: 10200),
    MarketPoint(date: '2000-01-05', close: 9900),
    MarketPoint(date: '2000-01-06', close: 10100),
  ];

  test('investor flows are deterministic and balance to zero', () {
    final first = buildFictionalInvestorFlowHistory(
      simulationSeed: 'flow-seed-a',
      assetId: 'hanbit_telecom',
      throughDate: DateTime(2000, 1, 6),
      priceHistory: history,
      currentPrice: 10150,
      sharesOutstanding: 10000000,
    );
    final repeated = buildFictionalInvestorFlowHistory(
      simulationSeed: 'flow-seed-a',
      assetId: 'hanbit_telecom',
      throughDate: DateTime(2000, 1, 6),
      priceHistory: history,
      currentPrice: 10150,
      sharesOutstanding: 10000000,
    );

    expect(first, hasLength(4));
    expect(first.first.date, DateTime(2000, 1, 6));
    expect(first.first.closePrice, 10150);
    expect(first[1].closePrice, 9900);
    expect(first.every((row) => row.marketNet == 0), isTrue);
    for (var index = 0; index < first.length; index += 1) {
      expect(first[index].individual, repeated[index].individual);
      expect(first[index].foreign, repeated[index].foreign);
      expect(first[index].institution, repeated[index].institution);
      expect(first[index].pension, repeated[index].pension);
    }
  });

  test('institution total equals every detailed institution category', () {
    final rows = buildFictionalInvestorFlowHistory(
      simulationSeed: 'flow-seed-a',
      assetId: 'hanbit_telecom',
      throughDate: DateTime(2000, 1, 6),
      priceHistory: history,
      currentPrice: 10150,
      sharesOutstanding: 10000000,
    );

    for (final row in rows) {
      expect(
        row.institution,
        row.financialInvestment +
            row.investmentTrust +
            row.pension +
            row.insurance +
            row.otherInstitution,
      );
    }
  });

  test('different simulation seeds produce different investor flows', () {
    final first = buildFictionalInvestorFlowHistory(
      simulationSeed: 'flow-seed-a',
      assetId: 'hanbit_telecom',
      throughDate: DateTime(2000, 1, 6),
      priceHistory: history,
      currentPrice: 10150,
      sharesOutstanding: 10000000,
    );
    final second = buildFictionalInvestorFlowHistory(
      simulationSeed: 'flow-seed-b',
      assetId: 'hanbit_telecom',
      throughDate: DateTime(2000, 1, 6),
      priceHistory: history,
      currentPrice: 10150,
      sharesOutstanding: 10000000,
    );

    expect(
      first.map((row) => row.foreign),
      isNot(orderedEquals(second.map((row) => row.foreign))),
    );
  });

  test('future quotes are excluded and current price changes only today', () {
    final morning = buildFictionalInvestorFlowHistory(
      simulationSeed: 'flow-seed-a',
      assetId: 'hanbit_telecom',
      throughDate: DateTime(2000, 1, 5),
      priceHistory: history,
      currentPrice: 9800,
      sharesOutstanding: 10000000,
    );
    final afternoon = buildFictionalInvestorFlowHistory(
      simulationSeed: 'flow-seed-a',
      assetId: 'hanbit_telecom',
      throughDate: DateTime(2000, 1, 5),
      priceHistory: history,
      currentPrice: 10300,
      sharesOutstanding: 10000000,
    );

    expect(morning, hasLength(3));
    expect(morning.first.date, DateTime(2000, 1, 5));
    expect(morning.first.closePrice, 9800);
    expect(afternoon.first.closePrice, 10300);
    expect(morning[1].closePrice, afternoon[1].closePrice);
    expect(morning.first.foreign, isNot(afternoon.first.foreign));
    expect(morning[1].foreign, afternoon[1].foreign);
    expect(morning[2].institution, afternoon[2].institution);
  });

  test(
    'today flow is hidden before open and grows with completed trading time',
    () {
      final preOpen = buildFictionalInvestorFlowHistory(
        simulationSeed: 'flow-seed-a',
        assetId: 'hanbit_telecom',
        throughDate: DateTime(2000, 1, 6),
        priceHistory: history,
        currentPrice: 10150,
        sharesOutstanding: 10000000,
        currentMarketMinute: 8 * 60,
      );
      final open = buildFictionalInvestorFlowHistory(
        simulationSeed: 'flow-seed-a',
        assetId: 'hanbit_telecom',
        throughDate: DateTime(2000, 1, 6),
        priceHistory: history,
        currentPrice: 10150,
        sharesOutstanding: 10000000,
        currentMarketMinute: 9 * 60,
      );
      final close = buildFictionalInvestorFlowHistory(
        simulationSeed: 'flow-seed-a',
        assetId: 'hanbit_telecom',
        throughDate: DateTime(2000, 1, 6),
        priceHistory: history,
        currentPrice: 10150,
        sharesOutstanding: 10000000,
        currentMarketMinute: 15 * 60,
      );

      expect(preOpen.first.date, DateTime(2000, 1, 5));
      expect(open.first.date, DateTime(2000, 1, 6));
      expect(
        open.first.foreign.abs(),
        lessThanOrEqualTo(close.first.foreign.abs()),
      );
    },
  );

  test('today flow return uses the corporate-action-adjusted reference', () {
    final adjusted = buildFictionalInvestorFlowHistory(
      simulationSeed: 'flow-seed-a',
      assetId: 'hanbit_telecom',
      throughDate: DateTime(2000, 1, 6),
      priceHistory: history,
      currentPrice: 9500,
      sharesOutstanding: 10000000,
      currentReferencePrice: 9500,
    );
    final unadjusted = buildFictionalInvestorFlowHistory(
      simulationSeed: 'flow-seed-a',
      assetId: 'hanbit_telecom',
      throughDate: DateTime(2000, 1, 6),
      priceHistory: history,
      currentPrice: 9500,
      sharesOutstanding: 10000000,
    );

    expect(adjusted.first.foreign, isNot(unadjusted.first.foreign));
  });

  test('historical flow returns use each day corporate-action reference', () {
    const splitHistory = <MarketPoint>[
      MarketPoint(date: '2000-01-03', close: 10000),
      MarketPoint(date: '2000-01-04', close: 10200),
      MarketPoint(date: '2000-01-05', close: 5100),
      MarketPoint(date: '2000-01-06', close: 5200),
    ];
    final adjusted = buildFictionalInvestorFlowHistory(
      simulationSeed: 'historical-reference',
      assetId: 'split_company',
      throughDate: DateTime(2000, 1, 6),
      priceHistory: splitHistory,
      currentPrice: 5200,
      sharesOutstanding: 10000000,
      referenceCloseAt: (date, previousClose) =>
          marketDateKey(date) == '2000-01-05' ? 5100 : previousClose,
    );
    final unadjusted = buildFictionalInvestorFlowHistory(
      simulationSeed: 'historical-reference',
      assetId: 'split_company',
      throughDate: DateTime(2000, 1, 6),
      priceHistory: splitHistory,
      currentPrice: 5200,
      sharesOutstanding: 10000000,
    );
    final adjustedSplitDay = adjusted.singleWhere(
      (row) => row.date == DateTime(2000, 1, 5),
    );
    final unadjustedSplitDay = unadjusted.singleWhere(
      (row) => row.date == DateTime(2000, 1, 5),
    );

    expect(adjustedSplitDay.foreign, isNot(unadjustedSplitDay.foreign));
    expect(
      adjustedSplitDay.financialInvestment,
      isNot(unadjustedSplitDay.financialInvestment),
    );
  });

  test('flow shares and displayed turnover use one daily liquidity source', () {
    const seed = 'single-liquidity-source';
    const outstanding = 10000000;
    final close = buildFictionalInvestorFlowHistory(
      simulationSeed: seed,
      assetId: 'hanbit_telecom',
      throughDate: DateTime(2000, 1, 6),
      priceHistory: history,
      currentPrice: 10100,
      sharesOutstanding: outstanding,
      currentMarketMinute: 15 * 60,
    );
    final marketDay = marketLiquidityDayKey(DateTime(2000, 1, 6));
    final expectedVolume = gameEstimatedFullDayVolumeUnits(
      assetId: 'hanbit_telecom',
      day: marketDay,
      referencePrice: 9900,
      simulationSeed: seed,
      sharesOutstanding: outstanding,
    );
    final turnover = gameEstimatedTurnoverEok(
      assetId: 'hanbit_telecom',
      day: marketDay,
      minute: 15 * 60,
      unitPrice: 10100,
      previousClose: 9900,
      simulationSeed: seed,
      sharesOutstanding: outstanding,
    );

    expect(close.first.tradedShares, expectedVolume);
    expect(turnover, closeTo(expectedVolume * 9900 / 100000000, 0.0000001));
  });

  test(
    'current-day investor flow is frozen throughout the closing auction',
    () {
      FictionalInvestorFlowDay currentAt(int minute) =>
          buildFictionalInvestorFlowHistory(
            simulationSeed: 'closing-auction-flow',
            assetId: 'hanbit_telecom',
            throughDate: DateTime(2000, 1, 6),
            priceHistory: history,
            currentPrice: 10100,
            sharesOutstanding: 10000000,
            currentMarketMinute: minute,
          ).first;

      final beforeAuction = currentAt(krxContinuousEndMinute - 1);
      final duringAuction = currentAt(krxCloseMinute - 1);
      final atClose = currentAt(krxCloseMinute);

      expect(duringAuction.tradedShares, beforeAuction.tradedShares);
      expect(duringAuction.individual, beforeAuction.individual);
      expect(duringAuction.foreign, beforeAuction.foreign);
      expect(duringAuction.institution, beforeAuction.institution);
      expect(duringAuction.otherCorporation, beforeAuction.otherCorporation);
      expect(atClose.tradedShares, greaterThan(duringAuction.tradedShares));
    },
  );

  test('historical flow volume uses shares outstanding on each date', () {
    const seed = 'historical-share-count';
    final rows = buildFictionalInvestorFlowHistory(
      simulationSeed: seed,
      assetId: 'hanbit_telecom',
      throughDate: DateTime(2000, 1, 6),
      priceHistory: history,
      currentPrice: 10100,
      sharesOutstanding: 10000000,
      sharesOutstandingAt: (date) =>
          date.isBefore(DateTime(2000, 1, 5)) ? 5000000 : 10000000,
      currentMarketMinute: 15 * 60,
    );
    const references = <String, double>{
      '2000-01-03': 10000,
      '2000-01-04': 10000,
      '2000-01-05': 10200,
      '2000-01-06': 9900,
    };

    for (final row in rows) {
      final key = marketDateKey(row.date);
      final outstanding = row.date.isBefore(DateTime(2000, 1, 5))
          ? 5000000
          : 10000000;
      expect(
        row.tradedShares,
        gameEstimatedFullDayVolumeUnits(
          assetId: 'hanbit_telecom',
          day: marketLiquidityDayKey(row.date),
          referencePrice: references[key]!,
          simulationSeed: seed,
          sharesOutstanding: outstanding,
        ),
      );
    }
  });
}
