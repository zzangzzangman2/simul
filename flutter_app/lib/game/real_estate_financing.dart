import 'dart:math' as math;

import 'real_estate_market.dart';

const _realEstateMortgageMarker = '::mortgage::';

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
