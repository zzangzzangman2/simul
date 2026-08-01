import 'dart:math' as math;

import 'personal_finance_state.dart';
import 'real_estate_financing.dart';
import 'real_estate_market.dart';
import 'real_estate_rental.dart';
import 'real_estate_world.dart';

/// A historical point that is safe to show on the property screen.
///
/// Callers pass the current game date as [asOf]. No method in this file reads
/// future anchors or future event outcomes.
class RealEstatePricePoint {
  const RealEstatePricePoint({
    required this.date,
    required this.price,
    required this.pricePerSquareMeter,
  });

  final DateTime date;
  final int price;
  final int pricePerSquareMeter;
}

class RealEstateComparable {
  const RealEstateComparable({
    required this.assetId,
    required this.listingIndex,
    required this.name,
    required this.areaSquareMeters,
    required this.price,
    required this.pricePerSquareMeter,
    required this.stationWalkMinutes,
    required this.condition,
  });

  final String assetId;
  final int listingIndex;
  final String name;
  final double areaSquareMeters;
  final int price;
  final int pricePerSquareMeter;
  final int stationWalkMinutes;
  final RealEstateListingCondition condition;
}

class RealEstateInvestmentAnalysis {
  const RealEstateInvestmentAnalysis({
    required this.marketValue,
    required this.acquisitionCash,
    required this.debt,
    required this.tenantDepositLiability,
    required this.equity,
    required this.grossMonthlyRent,
    required this.expectedMonthlyVacancyLoss,
    required this.monthlyOperatingCost,
    required this.monthlyRepairReserve,
    required this.monthlyInsurancePremium,
    required this.monthlyHoldingTax,
    required this.monthlyDebtService,
    required this.monthlyNoi,
    required this.monthlyCashFlow,
    required this.capRate,
    required this.cashOnCashReturn,
    required this.dscr,
    required this.ltv,
    required this.combinedLiabilityRate,
    required this.breakEvenOccupancy,
    required this.expectedVacancyRate,
  });

  final int marketValue;
  final int acquisitionCash;
  final int debt;
  final int tenantDepositLiability;
  final int equity;
  final int grossMonthlyRent;
  final int expectedMonthlyVacancyLoss;
  final int monthlyOperatingCost;
  final int monthlyRepairReserve;
  final int monthlyInsurancePremium;
  final int monthlyHoldingTax;
  final int monthlyDebtService;
  final int monthlyNoi;
  final int monthlyCashFlow;
  final double capRate;
  final double cashOnCashReturn;
  final double dscr;
  final double ltv;
  final double combinedLiabilityRate;
  final double breakEvenOccupancy;
  final double expectedVacancyRate;
}

class RealEstateAmortizationRow {
  const RealEstateAmortizationRow({
    required this.paymentNumber,
    required this.openingBalance,
    required this.payment,
    required this.interest,
    required this.principal,
    required this.closingBalance,
  });

  final int paymentNumber;
  final int openingBalance;
  final int payment;
  final int interest;
  final int principal;
  final int closingBalance;
}

DateTime _monthOffset(DateTime date, int offset) =>
    DateTime(date.year, date.month + offset, 1);

int _pricePerSquareMeter(int price, double areaSquareMeters) =>
    areaSquareMeters <= 0 ? 0 : (price / areaSquareMeters).round();

List<RealEstatePricePoint> realEstatePriceHistoryForListing({
  required GeneratedRealEstateListing listing,
  required DateTime asOf,
  int months = 60,
}) {
  final safeMonths = months.clamp(2, 324);
  final firstMonth = _monthOffset(asOf, -(safeMonths - 1));
  final points = <RealEstatePricePoint>[];
  for (var index = 0; index < safeMonths; index += 1) {
    final month = _monthOffset(firstMonth, index);
    if (month.isBefore(listing.asset.availableFrom)) continue;
    final pointDate = month.year == asOf.year && month.month == asOf.month
        ? asOf
        : month;
    if (pointDate.isAfter(asOf)) break;
    final price = listing.priceAt(pointDate);
    points.add(
      RealEstatePricePoint(
        date: pointDate,
        price: price,
        pricePerSquareMeter: _pricePerSquareMeter(
          price,
          listing.areaSquareMeters,
        ),
      ),
    );
  }
  return List<RealEstatePricePoint>.unmodifiable(points);
}

List<RealEstateComparable> realEstateComparablesForListing({
  required GeneratedRealEstateListing subject,
  required DateTime asOf,
  int maximum = 5,
}) {
  final districtId = realEstateDistrictFor(subject.asset).id;
  final candidates = <GeneratedRealEstateListing>[];
  for (final asset in realEstateMarketCatalogAt(asOf)) {
    if (realEstateDistrictFor(asset).id != districtId) continue;
    if (asset.type != subject.asset.type) continue;
    candidates.addAll(
      realEstateActiveListingsAt(
        asset,
        subject.worldSeed,
        asOf,
        generatorVersion: subject.generatorVersion,
      ),
    );
  }
  candidates.removeWhere(
    (listing) =>
        listing.asset.id == subject.asset.id && listing.index == subject.index,
  );
  candidates.sort((left, right) {
    final leftDistance =
        (left.areaSquareMeters - subject.areaSquareMeters).abs() +
        (left.stationWalkMinutes - subject.stationWalkMinutes).abs() * 0.8;
    final rightDistance =
        (right.areaSquareMeters - subject.areaSquareMeters).abs() +
        (right.stationWalkMinutes - subject.stationWalkMinutes).abs() * 0.8;
    return leftDistance.compareTo(rightDistance);
  });
  return List<RealEstateComparable>.unmodifiable(
    candidates.take(maximum.clamp(1, 10)).map((listing) {
      final price = listing.priceAt(asOf);
      return RealEstateComparable(
        assetId: listing.asset.id,
        listingIndex: listing.index,
        name: listing.displayName,
        areaSquareMeters: listing.areaSquareMeters,
        price: price,
        pricePerSquareMeter: _pricePerSquareMeter(
          price,
          listing.areaSquareMeters,
        ),
        stationWalkMinutes: listing.stationWalkMinutes,
        condition: listing.condition,
      );
    }),
  );
}

double realEstateAnalysisExpectedVacancyRate(
  GeneratedRealEstateListing listing,
  DateTime asOf,
) {
  final baseRate = switch (listing.asset.type) {
    RealEstateAssetType.apartment => 0.035,
    RealEstateAssetType.villa => 0.075,
    RealEstateAssetType.officetel => 0.085,
    RealEstateAssetType.commercialUnit => 0.135,
    RealEstateAssetType.officeBuilding => 0.115,
    RealEstateAssetType.landmarkFund => 0.055,
  };
  final risk = listing.riskFactorsAt(asOf);
  return (baseRate * risk.vacancyMultiplier).clamp(0.015, 0.35);
}

double _repairReserveRate(GeneratedRealEstateListing listing, DateTime asOf) {
  final risk = listing.riskFactorsAt(asOf);
  return (0.075 *
          math.sqrt(
            risk.repairProbabilityMultiplier * risk.repairCostMultiplier,
          ))
      .clamp(0.025, 0.24);
}

RealEstateInvestmentAnalysis analyzeRealEstateListing({
  required GeneratedRealEstateListing listing,
  required DateTime asOf,
  required int requestedLtvPercent,
  required int ownedHousingCount,
}) {
  final value = listing.priceAt(asOf);
  final baseQuote = listing.quoteAt(asOf);
  final quote = realEstatePortfolioAdjustedPurchaseQuote(
    baseQuote: baseQuote,
    date: asOf,
    type: listing.asset.type,
    ownedHousingCount: ownedHousingCount,
  );
  final financingTerms = realEstateFinancingTermsAt(asOf, listing.asset.type);
  final plan = financingTerms.planFor(quote, requestedLtvPercent);
  final grossRent = listing.monthlyRentAt(asOf);
  final vacancyRate = realEstateAnalysisExpectedVacancyRate(listing, asOf);
  final vacancyLoss = (grossRent * vacancyRate).round();
  final operatingCost = listing.monthlyOperatingCostAt(asOf);
  final repairReserve = (grossRent * _repairReserveRate(listing, asOf)).round();
  final holdingTax = realEstateMonthlyHoldingTax(
    date: asOf,
    type: listing.asset.type,
    marketValue: value,
    ownedHousingCount:
        ownedHousingCount + (listing.asset.type.isHousing ? 1 : 0),
  );
  return _buildAnalysis(
    marketValue: value,
    acquisitionCash: plan.cashRequired,
    debt: plan.principal,
    tenantDepositLiability: 0,
    grossMonthlyRent: grossRent,
    expectedMonthlyVacancyLoss: vacancyLoss,
    monthlyOperatingCost: operatingCost,
    monthlyRepairReserve: repairReserve,
    monthlyInsurancePremium: 0,
    monthlyHoldingTax: holdingTax,
    monthlyDebtService: plan.monthlyPayment,
  );
}

RealEstateInvestmentAnalysis analyzeOwnedRealEstate({
  required OwnedRealEstate asset,
  required int currentDay,
  required DateTime asOf,
  required int ownedHousingCount,
}) {
  final listing = asset.generatedListing;
  final value = asset.estimatedMarketValue(currentDay);
  // Monthly-rent contracts already store the condition-adjusted rent that was
  // agreed when the lease was signed. Applying the condition multiplier again
  // here would overstate renovated assets (and understate worn assets).
  final grossRent = asset.isDirectUse ? 0 : asset.monthlyIncomeAt(asOf);
  final vacancyRate = asset.isLandmarkFund
      ? 0.03
      : listing == null || !asset.hasActiveLease
      ? (asset.hasActiveLease ? 0.05 : 1.0)
      : realEstateAnalysisExpectedVacancyRate(listing, asOf);
  final vacancyLoss = asset.hasActiveLease
      ? (grossRent * vacancyRate).round()
      : grossRent;
  final operatingCost = asset.monthlyCostAt(asOf);
  final baseRepairReserve = listing == null
      ? (grossRent * 0.08).round()
      : (grossRent * _repairReserveRate(listing, asOf)).round();
  final repairReserve =
      (baseRepairReserve *
              asset.conditionRepairProbabilityMultiplier *
              asset.conditionRepairCostMultiplier *
              (asset.insuranceActive ? 0.70 : 1.0))
          .round();
  final insurancePremium = asset.insuranceActive
      ? realEstateMonthlyInsurancePremium(value)
      : 0;
  final holdingTax = realEstateMonthlyHoldingTax(
    date: asOf,
    type: asset.assetType,
    marketValue: value,
    ownedHousingCount: ownedHousingCount,
  );
  return _buildAnalysis(
    marketValue: value,
    acquisitionCash: asset.effectiveCashInvestedAtPurchase,
    debt: asset.mortgageBalance,
    tenantDepositLiability: asset.hasActiveLease ? asset.leaseDeposit : 0,
    grossMonthlyRent: grossRent,
    expectedMonthlyVacancyLoss: vacancyLoss,
    monthlyOperatingCost: operatingCost,
    monthlyRepairReserve: repairReserve,
    monthlyInsurancePremium: insurancePremium,
    monthlyHoldingTax: holdingTax,
    monthlyDebtService: asset.monthlyMortgagePayment,
  );
}

RealEstateInvestmentAnalysis _buildAnalysis({
  required int marketValue,
  required int acquisitionCash,
  required int debt,
  required int tenantDepositLiability,
  required int grossMonthlyRent,
  required int expectedMonthlyVacancyLoss,
  required int monthlyOperatingCost,
  required int monthlyRepairReserve,
  required int monthlyInsurancePremium,
  required int monthlyHoldingTax,
  required int monthlyDebtService,
}) {
  final noi =
      grossMonthlyRent -
      expectedMonthlyVacancyLoss -
      monthlyOperatingCost -
      monthlyRepairReserve -
      monthlyInsurancePremium -
      monthlyHoldingTax;
  final cashFlow = noi - monthlyDebtService;
  final equity = math.max(0, marketValue - debt - tenantDepositLiability);
  final safeValue = math.max(1, marketValue);
  final safeCash = math.max(1, acquisitionCash);
  final annualNoi = noi * 12;
  final annualCashFlow = cashFlow * 12;
  final annualDebtService = monthlyDebtService * 12;
  final nonVacancyExpense =
      monthlyOperatingCost +
      monthlyRepairReserve +
      monthlyInsurancePremium +
      monthlyHoldingTax;
  final breakEvenOccupancy = grossMonthlyRent <= 0
      ? 0.0
      : ((nonVacancyExpense + monthlyDebtService) / grossMonthlyRent).clamp(
          0.0,
          2.0,
        );
  return RealEstateInvestmentAnalysis(
    marketValue: marketValue,
    acquisitionCash: acquisitionCash,
    debt: debt,
    tenantDepositLiability: tenantDepositLiability,
    equity: equity,
    grossMonthlyRent: grossMonthlyRent,
    expectedMonthlyVacancyLoss: expectedMonthlyVacancyLoss,
    monthlyOperatingCost: monthlyOperatingCost,
    monthlyRepairReserve: monthlyRepairReserve,
    monthlyInsurancePremium: monthlyInsurancePremium,
    monthlyHoldingTax: monthlyHoldingTax,
    monthlyDebtService: monthlyDebtService,
    monthlyNoi: noi,
    monthlyCashFlow: cashFlow,
    capRate: annualNoi / safeValue,
    cashOnCashReturn: annualCashFlow / safeCash,
    dscr: annualDebtService <= 0
        ? (annualNoi > 0 ? double.infinity : 0)
        : annualNoi / annualDebtService,
    ltv: debt / safeValue,
    combinedLiabilityRate: (debt + tenantDepositLiability) / safeValue,
    breakEvenOccupancy: breakEvenOccupancy,
    expectedVacancyRate: grossMonthlyRent <= 0
        ? 0
        : expectedMonthlyVacancyLoss / grossMonthlyRent,
  );
}

List<RealEstateAmortizationRow> realEstateAmortizationSchedule({
  required int openingBalance,
  required double annualInterestRate,
  required int remainingMonths,
  int maximumRows = 24,
}) {
  var balance = math.max(0, openingBalance);
  var months = math.max(0, remainingMonths);
  final rows = <RealEstateAmortizationRow>[];
  final limit = math.min(months, maximumRows.clamp(1, 360));
  for (var index = 0; index < limit && balance > 0; index += 1) {
    final payment = math.min(
      mortgageMonthlyPayment(balance, annualInterestRate, months),
      balance + mortgageMonthlyInterest(balance, annualInterestRate),
    );
    final interest = mortgageMonthlyInterest(balance, annualInterestRate);
    final principal = (payment - interest).clamp(0, balance).toInt();
    final closing = balance - principal;
    rows.add(
      RealEstateAmortizationRow(
        paymentNumber: index + 1,
        openingBalance: balance,
        payment: payment,
        interest: interest,
        principal: principal,
        closingBalance: closing,
      ),
    );
    balance = closing;
    months -= 1;
  }
  return List<RealEstateAmortizationRow>.unmodifiable(rows);
}
