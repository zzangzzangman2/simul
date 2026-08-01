import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/personal_finance_state.dart';
import 'package:millennium_capital/game/real_estate_analysis.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_rental.dart';
import 'package:millennium_capital/game/real_estate_world.dart';

void main() {
  const worldSeed = 'real-estate-analysis-regression';
  final asset = realEstateMarketAssetById('uijeongbu_station_officetel_20')!;
  final listing = realEstateListingsFor(asset, worldSeed).first;

  test('price history never exposes a point after the as-of date', () {
    final asOf = DateTime(2015, 6, 17);
    final history = realEstatePriceHistoryForListing(
      listing: listing,
      asOf: asOf,
      months: 60,
    );

    expect(history, isNotEmpty);
    expect(history.every((point) => !point.date.isAfter(asOf)), isTrue);
    expect(history.last.date, asOf);
    expect(history.last.price, listing.priceAt(asOf));
    expect(history.every((point) => point.pricePerSquareMeter > 0), isTrue);
  });

  test('comparables are deterministic and exclude the subject listing', () {
    final comparables = realEstateComparablesForListing(
      subject: listing,
      asOf: DateTime(2015, 6, 17),
    );

    expect(comparables, isNotEmpty);
    expect(
      comparables.any(
        (item) =>
            item.assetId == listing.asset.id &&
            item.listingIndex == listing.index,
      ),
      isFalse,
    );
    expect(comparables.every((item) => item.pricePerSquareMeter > 0), isTrue);
  });

  test('listing analysis reconciles NOI, debt service, and leverage', () {
    final analysis = analyzeRealEstateListing(
      listing: listing,
      asOf: DateTime(2015, 6, 17),
      requestedLtvPercent: 40,
      ownedHousingCount: 0,
    );

    expect(analysis.marketValue, listing.priceAt(DateTime(2015, 6, 17)));
    expect(analysis.acquisitionCash, greaterThan(0));
    expect(analysis.debt, greaterThan(0));
    expect(analysis.ltv, closeTo(0.40, 0.02));
    expect(
      analysis.monthlyNoi,
      analysis.grossMonthlyRent -
          analysis.expectedMonthlyVacancyLoss -
          analysis.monthlyOperatingCost -
          analysis.monthlyRepairReserve -
          analysis.monthlyHoldingTax,
    );
    expect(
      analysis.monthlyCashFlow,
      analysis.monthlyNoi - analysis.monthlyDebtService,
    );
    expect(analysis.expectedVacancyRate, inInclusiveRange(0.015, 0.35));
  });

  test('owned analysis subtracts mortgage and tenant deposit from equity', () {
    final date = DateTime(2015, 6, 17);
    final marketValue = listing.priceAt(date);
    final owned = OwnedRealEstate(
      id: listing.id,
      optionId: listing.optionId,
      name: listing.displayName,
      purchasePrice: marketValue,
      acquiredDay: 1,
      monthlyIncome: listing.monthlyRentAt(date),
      monthlyCost: listing.monthlyOperatingCostAt(date),
      purchaseDateIso: date.toIso8601String(),
      marketAssetId: listing.asset.id,
      marketListingIndex: listing.index,
      realEstateWorldSeed: worldSeed,
      cashInvestedAtPurchase: marketValue ~/ 2,
      mortgageOriginalPrincipal: marketValue ~/ 2,
      mortgageBalance: marketValue ~/ 2,
      mortgageAnnualInterestRate: 0.04,
      mortgageTermMonths: 240,
      propertyCondition: 90,
      leaseType: RealEstateLeaseType.monthlyRent,
      leaseDeposit: marketValue ~/ 10,
      leaseMonthlyRent: listing.monthlyRentAt(date),
      leaseRemainingMonths: 24,
    );

    final analysis = analyzeOwnedRealEstate(
      asset: owned,
      currentDay: 1,
      asOf: date,
      ownedHousingCount: 0,
    );

    expect(
      analysis.equity,
      analysis.marketValue - owned.mortgageBalance - owned.leaseDeposit,
    );
    expect(
      analysis.grossMonthlyRent,
      owned.leaseMonthlyRent,
      reason: '계약 때 상태가 반영된 월세에 상태 배수를 다시 곱하면 안 된다.',
    );
    expect(analysis.combinedLiabilityRate, greaterThan(analysis.ltv));
  });

  test('amortization schedule reduces balance without negative principal', () {
    final rows = realEstateAmortizationSchedule(
      openingBalance: 100000000,
      annualInterestRate: 0.045,
      remainingMonths: 240,
      maximumRows: 24,
    );

    expect(rows, hasLength(24));
    expect(rows.first.openingBalance, 100000000);
    expect(rows.last.closingBalance, lessThan(rows.first.openingBalance));
    expect(rows.every((row) => row.principal >= 0), isTrue);
    expect(
      rows.every((row) => row.payment == row.interest + row.principal),
      isTrue,
    );
  });
}
