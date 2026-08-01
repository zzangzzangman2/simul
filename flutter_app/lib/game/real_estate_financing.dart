import 'dart:math' as math;

import 'real_estate_market.dart';

const _realEstateMortgageMarker = '::mortgage::';
const int realEstateSaleOfferValidityDays = 14;
const double realEstateTenantAuctionSaleRate = 0.88;
const double realEstateMortgageForeclosureSaleRate = 0.82;
const double realEstateMortgagePrepaymentFeeRate = 0.01;
const double realEstateVariableMortgageDiscountRate = 0.005;

class RealEstateFinancingRequest {
  const RealEstateFinancingRequest({
    required this.baseOptionId,
    required this.requestedLtvPercent,
  });

  final String baseOptionId;
  final int requestedLtvPercent;
}

String realEstateFinancedOptionId(String baseOptionId, int ltvPercent) =>
    '$baseOptionId$_realEstateMortgageMarker${ltvPercent.clamp(0, 100)}';

RealEstateFinancingRequest parseRealEstateFinancingRequest(String optionId) {
  final markerIndex = optionId.lastIndexOf(_realEstateMortgageMarker);
  if (markerIndex < 0) {
    return RealEstateFinancingRequest(
      baseOptionId: optionId,
      requestedLtvPercent: 0,
    );
  }
  final parsed = int.tryParse(
    optionId.substring(markerIndex + _realEstateMortgageMarker.length),
  );
  return RealEstateFinancingRequest(
    baseOptionId: optionId.substring(0, markerIndex),
    requestedLtvPercent: (parsed ?? 0).clamp(0, 100).toInt(),
  );
}

class RealEstateFinancingTerms {
  const RealEstateFinancingTerms({
    required this.maxLtvPercent,
    required this.annualInterestRate,
    required this.termMonths,
    required this.eraLabel,
  });

  final int maxLtvPercent;
  final double annualInterestRate;
  final int termMonths;
  final String eraLabel;

  bool get available => maxLtvPercent > 0 && termMonths > 0;

  RealEstateFinancingPlan planFor(
    RealEstatePurchaseQuote quote,
    int requestedLtvPercent,
  ) {
    final appliedLtv = requestedLtvPercent.clamp(0, maxLtvPercent).toInt();
    final principal = (quote.marketPrice * appliedLtv / 100).floor();
    return RealEstateFinancingPlan(
      requestedLtvPercent: requestedLtvPercent.clamp(0, 100).toInt(),
      appliedLtvPercent: appliedLtv,
      principal: principal,
      cashRequired: quote.totalCash - principal,
      annualInterestRate: principal == 0 ? 0 : annualInterestRate,
      termMonths: principal == 0 ? 0 : termMonths,
      monthlyPayment: mortgageMonthlyPayment(
        principal,
        annualInterestRate,
        termMonths,
      ),
    );
  }
}

class RealEstateFinancingPlan {
  const RealEstateFinancingPlan({
    required this.requestedLtvPercent,
    required this.appliedLtvPercent,
    required this.principal,
    required this.cashRequired,
    required this.annualInterestRate,
    required this.termMonths,
    required this.monthlyPayment,
  });

  final int requestedLtvPercent;
  final int appliedLtvPercent;
  final int principal;
  final int cashRequired;
  final double annualInterestRate;
  final int termMonths;
  final int monthlyPayment;

  bool get hasMortgage => principal > 0;
}

const double realEstateMaximumDsrRate = 0.45;
const double realEstateAdditionalPropertyDebtRate = 0.60;
const int realEstateMinimumMortgageCreditScore = 600;

enum RealEstateForcedDispositionKind { tenantAuction, mortgageForeclosure }

double realEstateForcedDispositionRate(RealEstateForcedDispositionKind kind) =>
    switch (kind) {
      RealEstateForcedDispositionKind.tenantAuction =>
        realEstateTenantAuctionSaleRate,
      RealEstateForcedDispositionKind.mortgageForeclosure =>
        realEstateMortgageForeclosureSaleRate,
    };

class RealEstateDispositionWaterfall {
  const RealEstateDispositionWaterfall({
    required this.netSaleBeforeTax,
    required this.capitalGainsTax,
    required this.mortgagePaid,
    required this.mortgageDeficiency,
    required this.tenantDepositPaid,
    required this.tenantDepositDeficiency,
    required this.ownerProceeds,
  });

  final int netSaleBeforeTax;
  final int capitalGainsTax;
  final int mortgagePaid;
  final int mortgageDeficiency;
  final int tenantDepositPaid;
  final int tenantDepositDeficiency;
  final int ownerProceeds;
}

RealEstateDispositionWaterfall realEstateDispositionWaterfall({
  required DateTime saleDate,
  required RealEstateAssetType type,
  required int ownedHousingCount,
  required int holdingDays,
  required int netSaleBeforeTax,
  required int purchaseCost,
  required int mortgageBalance,
  required int tenantDepositDue,
}) {
  final safeNetSale = math.max(0, netSaleBeforeTax);
  final capitalGainsTax = realEstateCapitalGainsTax(
    saleDate: saleDate,
    type: type,
    ownedHousingCount: ownedHousingCount,
    holdingDays: holdingDays,
    netSaleBeforeTax: safeNetSale,
    purchaseCost: purchaseCost,
  );
  var remaining = math.max(0, safeNetSale - capitalGainsTax);
  final mortgagePaid = math.min(math.max(0, mortgageBalance), remaining);
  remaining -= mortgagePaid;
  final mortgageDeficiency = math.max(0, mortgageBalance - mortgagePaid);
  final tenantDepositPaid = math.min(math.max(0, tenantDepositDue), remaining);
  remaining -= tenantDepositPaid;
  final tenantDepositDeficiency = math.max(
    0,
    tenantDepositDue - tenantDepositPaid,
  );
  return RealEstateDispositionWaterfall(
    netSaleBeforeTax: safeNetSale,
    capitalGainsTax: capitalGainsTax,
    mortgagePaid: mortgagePaid,
    mortgageDeficiency: mortgageDeficiency,
    tenantDepositPaid: tenantDepositPaid,
    tenantDepositDeficiency: tenantDepositDeficiency,
    ownerProceeds: remaining,
  );
}

class RealEstateBorrowingAssessment {
  const RealEstateBorrowingAssessment({
    required this.approved,
    required this.dsr,
    required this.maximumMonthlyDebtService,
    required this.maximumPortfolioDebt,
    required this.reason,
  });

  final bool approved;
  final double dsr;
  final int maximumMonthlyDebtService;
  final int maximumPortfolioDebt;
  final String reason;
}

/// 포트폴리오 전체의 원리금과 담보잔액을 함께 보는 게임용 DSR 심사.
RealEstateBorrowingAssessment assessRealEstateBorrowing({
  required RealEstateFinancingPlan plan,
  required int existingMortgageBalance,
  int existingNonMortgageDebt = 0,
  required int existingMonthlyDebtService,
  required int existingPropertyValue,
  required int targetPropertyValue,
  required int existingPropertyCount,
  required int qualifyingMonthlyIncome,
  int creditScore = 850,
  bool hasDelinquency = false,
  bool hasForeclosureHistory = false,
}) {
  if (!plan.hasMortgage) {
    return const RealEstateBorrowingAssessment(
      approved: true,
      dsr: 0,
      maximumMonthlyDebtService: 0,
      maximumPortfolioDebt: 0,
      reason: '',
    );
  }
  if (hasDelinquency) {
    return const RealEstateBorrowingAssessment(
      approved: false,
      dsr: 0,
      maximumMonthlyDebtService: 0,
      maximumPortfolioDebt: 0,
      reason: '연체·결손채무·미반환 보증금을 먼저 정리해야 합니다.',
    );
  }
  if (creditScore < realEstateMinimumMortgageCreditScore) {
    return RealEstateBorrowingAssessment(
      approved: false,
      dsr: 0,
      maximumMonthlyDebtService: 0,
      maximumPortfolioDebt: 0,
      reason:
          '신용점수 $creditScore점으로 담보대출 최소 기준 '
          '$realEstateMinimumMortgageCreditScore점에 미달합니다.',
    );
  }
  if (hasForeclosureHistory && creditScore < 700) {
    return const RealEstateBorrowingAssessment(
      approved: false,
      dsr: 0,
      maximumMonthlyDebtService: 0,
      maximumPortfolioDebt: 0,
      reason: '강제매각 이력이 있어 신용점수 700점 이상 회복 후 신청할 수 있습니다.',
    );
  }
  final safeIncome = math.max(1, qualifyingMonthlyIncome);
  final afterMonthlyDebt = existingMonthlyDebtService + plan.monthlyPayment;
  final dsr = afterMonthlyDebt / safeIncome;
  final maximumMonthlyDebtService = (safeIncome * realEstateMaximumDsrRate)
      .floor();
  if (afterMonthlyDebt > maximumMonthlyDebtService) {
    return RealEstateBorrowingAssessment(
      approved: false,
      dsr: dsr,
      maximumMonthlyDebtService: maximumMonthlyDebtService,
      maximumPortfolioDebt: 0,
      reason:
          'DSR ${(dsr * 100).toStringAsFixed(1)}%로 '
          '한도 ${(realEstateMaximumDsrRate * 100).round()}%를 넘습니다.',
    );
  }
  final afterPropertyValue = existingPropertyValue + targetPropertyValue;
  final afterMortgage = existingMortgageBalance + plan.principal;
  final portfolioDebtRate = existingPropertyCount == 0
      ? plan.appliedLtvPercent / 100
      : realEstateAdditionalPropertyDebtRate;
  final maximumPortfolioDebt = existingPropertyCount == 0
      ? (afterPropertyValue * plan.appliedLtvPercent) ~/ 100
      : (afterPropertyValue * portfolioDebtRate).floor();
  final afterPortfolioDebt =
      afterMortgage +
      (existingPropertyCount == 0 ? 0 : existingNonMortgageDebt);
  if (afterPortfolioDebt > maximumPortfolioDebt) {
    return RealEstateBorrowingAssessment(
      approved: false,
      dsr: dsr,
      maximumMonthlyDebtService: maximumMonthlyDebtService,
      maximumPortfolioDebt: maximumPortfolioDebt,
      reason:
          '추가 매입 후 담보대출·보증금 등 총부채가 '
          '${(realEstateAdditionalPropertyDebtRate * 100).round()}% 한도를 넘습니다.',
    );
  }
  return RealEstateBorrowingAssessment(
    approved: true,
    dsr: dsr,
    maximumMonthlyDebtService: maximumMonthlyDebtService,
    maximumPortfolioDebt: maximumPortfolioDebt,
    reason: '',
  );
}

RealEstateFinancingTerms realEstateFinancingTermsAt(
  DateTime date,
  RealEstateAssetType type,
) {
  if (date.isBefore(DateTime(2010, 1, 1)) ||
      type == RealEstateAssetType.landmarkFund) {
    return const RealEstateFinancingTerms(
      maxLtvPercent: 0,
      annualInterestRate: 0,
      termMonths: 0,
      eraLabel: '현금 매입만 가능',
    );
  }

  final isResidential = type.isHousing || type == RealEstateAssetType.officetel;
  final base = switch (date.year) {
    <= 2016 => (
      maxLtv: isResidential ? 70 : 60,
      rate: isResidential ? 0.048 : 0.060,
      label: '2010~2016 완화기',
    ),
    <= 2019 => (
      maxLtv: isResidential ? 50 : 55,
      rate: isResidential ? 0.038 : 0.052,
      label: '2017~2019 규제기',
    ),
    <= 2022 => (
      maxLtv: isResidential ? 40 : 50,
      rate: isResidential ? 0.045 : 0.059,
      label: '2020~2022 변동기',
    ),
    _ => (
      maxLtv: isResidential ? 50 : 55,
      rate: isResidential ? 0.042 : 0.055,
      label: '2023~2026 조정기',
    ),
  };
  return RealEstateFinancingTerms(
    maxLtvPercent: base.maxLtv,
    annualInterestRate: base.rate,
    termMonths: isResidential ? 240 : 180,
    eraLabel: base.label,
  );
}

int mortgageMonthlyInterest(int balance, double annualInterestRate) {
  if (balance <= 0 || annualInterestRate <= 0) return 0;
  return math.max(1, (balance * annualInterestRate / 12).round());
}

int mortgageMonthlyPayment(
  int principal,
  double annualInterestRate,
  int remainingMonths,
) {
  if (principal <= 0 || remainingMonths <= 0) return 0;
  final monthlyRate = annualInterestRate / 12;
  if (monthlyRate <= 0) return (principal / remainingMonths).ceil();
  final growth = math.pow(1 + monthlyRate, remainingMonths).toDouble();
  return (principal * monthlyRate * growth / (growth - 1)).ceil();
}
