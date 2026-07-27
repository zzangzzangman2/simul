import 'real_estate_market.dart';
import 'real_estate_financing.dart';
import 'real_estate_rental.dart';
import 'real_estate_world.dart';

enum SpendingCategory { family, education, business, realEstate, social }

enum SpendingRepeat { once, monthly, yearly }

class SpendingOption {
  const SpendingOption({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.unlockYear,
    required this.cost,
    this.repeat = SpendingRepeat.once,
    this.requiresEmployee = false,
    this.requiresLegalCompany = false,
    this.isRealEstate = false,
    this.monthlyIncome = 0,
    this.monthlyCost = 0,
    this.marketAssetId,
    this.researchIncomeBonus = 0,
    this.researchIncomePerEmployeeBonus = 0,
    this.reputationDelta = 0,
    this.familyTrustDelta = 0,
  });

  final String id;
  final String title;
  final String description;
  final SpendingCategory category;
  final int unlockYear;
  final int cost;
  final SpendingRepeat repeat;
  final bool requiresEmployee;
  final bool requiresLegalCompany;
  final bool isRealEstate;
  final int monthlyIncome;
  final int monthlyCost;
  final String? marketAssetId;
  final int researchIncomeBonus;
  final int researchIncomePerEmployeeBonus;
  final int reputationDelta;
  final int familyTrustDelta;

  RealEstateMarketAsset? get marketAsset =>
      marketAssetId == null ? null : realEstateMarketAssetById(marketAssetId!);

  RealEstatePurchaseQuote? quoteAt(DateTime date) => marketAsset?.quoteAt(date);

  int costAt(DateTime date) => quoteAt(date)?.totalCash ?? cost;

  int monthlyIncomeAt(DateTime date) =>
      marketAsset?.monthlyRentAt(date) ?? monthlyIncome;

  int monthlyCostAt(DateTime date) =>
      marketAsset?.monthlyOperatingCostAt(date) ?? monthlyCost;
}

final spendingCatalog = <SpendingOption>[
  SpendingOption(
    id: 'family_outing',
    title: '가족과 보내는 하루',
    description: '가족 외식과 나들이 비용입니다. 같은 달에는 한 번만 선택해 가족 신뢰를 높입니다.',
    category: SpendingCategory.family,
    unlockYear: 2000,
    cost: 20000,
    repeat: SpendingRepeat.monthly,
    familyTrustDelta: 4,
  ),
  SpendingOption(
    id: 'research_books',
    title: '회계·투자 서적 묶음',
    description: '한 해에 한 번 구입하며 그해 월 리서치 수입을 1만원 늘립니다.',
    category: SpendingCategory.education,
    unlockYear: 2001,
    cost: 80000,
    repeat: SpendingRepeat.yearly,
    reputationDelta: 1,
    researchIncomeBonus: 10000,
  ),
  SpendingOption(
    id: 'employee_training',
    title: '직원 합동 연수',
    description: '그해 직원 1명당 월 리서치 수입을 1만5천원 늘립니다. 연 1회 가능합니다.',
    category: SpendingCategory.education,
    unlockYear: 2003,
    cost: 300000,
    repeat: SpendingRepeat.yearly,
    requiresEmployee: true,
    reputationDelta: 2,
    researchIncomePerEmployeeBonus: 15000,
  ),
  SpendingOption(
    id: 'data_archive',
    title: '기업자료 아카이브',
    description: '장기 자료 구독권을 구입해 월 리서치 수입을 4만원 늘립니다.',
    category: SpendingCategory.business,
    unlockYear: 2004,
    cost: 500000,
    researchIncomeBonus: 40000,
    reputationDelta: 2,
  ),
  SpendingOption(
    id: 'owner_office',
    title: '자가 사무실',
    description: '법인 명의의 작은 사무실입니다. 월 임대료 대신 유지비 4만원이 듭니다.',
    category: SpendingCategory.realEstate,
    unlockYear: 2006,
    cost: 3000000,
    requiresLegalCompany: true,
    isRealEstate: true,
    monthlyCost: 40000,
    reputationDelta: 3,
  ),
  SpendingOption(
    id: 'commercial_unit',
    title: '소형 상가 지분',
    description: '게임용 가상 부동산입니다. 월 임대수입 11만원, 유지비 2만5천원이 발생합니다.',
    category: SpendingCategory.realEstate,
    unlockYear: 2008,
    cost: 12000000,
    requiresLegalCompany: true,
    isRealEstate: true,
    monthlyIncome: 110000,
    monthlyCost: 25000,
    reputationDelta: 2,
  ),
  SpendingOption(
    id: 'scholarship',
    title: '청소년 금융교육 장학금',
    description: '지역 학생을 지원합니다. 한 해에 한 번 평판과 가족 신뢰를 높입니다.',
    category: SpendingCategory.social,
    unlockYear: 2008,
    cost: 1000000,
    repeat: SpendingRepeat.yearly,
    reputationDelta: 7,
    familyTrustDelta: 2,
  ),
  SpendingOption(
    id: 'family_home_trust',
    title: '가족 주택 신탁',
    description: '보호자와 공동 관리하는 게임용 주거자산입니다. 월 관리비 8만원이 듭니다.',
    category: SpendingCategory.realEstate,
    unlockYear: 2009,
    cost: 25000000,
    requiresLegalCompany: true,
    isRealEstate: true,
    monthlyCost: 80000,
    familyTrustDelta: 8,
  ),
  ...realEstateMarketCatalog.map((asset) {
    final openingQuote = asset.quoteAt(asset.availableFrom);
    return SpendingOption(
      id: 'market_${asset.id}',
      title: asset.name,
      description: asset.sourceNote,
      category: SpendingCategory.realEstate,
      unlockYear: asset.availableFrom.year,
      cost: openingQuote.totalCash,
      requiresLegalCompany: asset.requiresLegalCompany,
      isRealEstate: true,
      monthlyIncome: asset.monthlyRentAt(asset.availableFrom),
      monthlyCost: asset.monthlyOperatingCostAt(asset.availableFrom),
      reputationDelta: switch (asset.tier) {
        RealEstateInvestmentTier.starter => 1,
        RealEstateInvestmentTier.income => 2,
        RealEstateInvestmentTier.apartment => 3,
        RealEstateInvestmentTier.prestige => 5,
        RealEstateInvestmentTier.building => 7,
        RealEstateInvestmentTier.landmark => 10,
      },
      marketAssetId: asset.id,
    );
  }),
];

SpendingOption? spendingOptionById(String id) {
  for (final option in spendingCatalog) {
    if (option.id == id) return option;
  }
  return null;
}

class OwnedRealEstate {
  const OwnedRealEstate({
    required this.id,
    required this.optionId,
    required this.name,
    required this.purchasePrice,
    required this.acquiredDay,
    required this.monthlyIncome,
    required this.monthlyCost,
    this.marketAssetId,
    this.marketPriceAtPurchase = 0,
    this.acquisitionCosts = 0,
    this.purchaseDateIso = '',
    this.marketListingIndex,
    this.realEstateWorldSeed = '',
    this.realEstateWorldVersion = 1,
    this.cashInvestedAtPurchase = 0,
    this.mortgageOriginalPrincipal = 0,
    this.mortgageBalance = 0,
    this.mortgageAnnualInterestRate = 0,
    this.mortgageTermMonths = 0,
    this.mortgagePaymentsMade = 0,
    this.mortgageMissedPayments = 0,
    this.nextMortgagePaymentDay = 0,
    this.mortgageIsVariableRate = false,
    this.leaseType = RealEstateLeaseType.vacant,
    this.leaseDeposit = 0,
    this.leaseMonthlyRent = 0,
    this.leaseRemainingMonths = 0,
    this.nextRentalSettlementDay = 0,
    this.tenantReliability = 0,
    this.rentArrearsMonths = 0,
    this.vacancyMonths = 0,
    this.totalVacancyMonths = 0,
    this.lastRentalEvent = '',
    this.totalRepairCosts = 0,
    this.saleListedDay = 0,
    this.saleOfferAmount = 0,
    this.saleOfferIssuedDay = 0,
    this.saleOfferExpiresDay = 0,
    this.investmentNote = '',
    this.propertyCondition = 70,
    this.insuranceActive = false,
  });

  final String id;
  final String optionId;
  final String name;
  final int purchasePrice;
  final int acquiredDay;
  final int monthlyIncome;
  final int monthlyCost;
  final String? marketAssetId;
  final int marketPriceAtPurchase;
  final int acquisitionCosts;
  final String purchaseDateIso;
  final int? marketListingIndex;
  final String realEstateWorldSeed;
  final int realEstateWorldVersion;
  final int cashInvestedAtPurchase;
  final int mortgageOriginalPrincipal;
  final int mortgageBalance;
  final double mortgageAnnualInterestRate;
  final int mortgageTermMonths;
  final int mortgagePaymentsMade;
  final int mortgageMissedPayments;
  final int nextMortgagePaymentDay;
  final bool mortgageIsVariableRate;
  final RealEstateLeaseType leaseType;
  final int leaseDeposit;
  final int leaseMonthlyRent;
  final int leaseRemainingMonths;
  final int nextRentalSettlementDay;
  final int tenantReliability;
  final int rentArrearsMonths;
  final int vacancyMonths;
  final int totalVacancyMonths;
  final String lastRentalEvent;
  final int totalRepairCosts;
  final int saleListedDay;
  final int saleOfferAmount;
  final int saleOfferIssuedDay;
  final int saleOfferExpiresDay;
  final String investmentNote;
  final int propertyCondition;
  final bool insuranceActive;

  bool get hasMortgage => mortgageBalance > 0;

  bool mortgageDueAt(int day) =>
      hasMortgage &&
      (nextMortgagePaymentDay <= 0 || day >= nextMortgagePaymentDay);

  bool get hasManagedLease => leaseType != RealEstateLeaseType.automatic;

  bool get hasActiveLease =>
      leaseType == RealEstateLeaseType.monthlyRent ||
      leaseType == RealEstateLeaseType.jeonse;

  bool get isDirectUse =>
      optionId == 'owner_office' || optionId == 'family_home_trust';

  bool get isLandmarkFund => assetType == RealEstateAssetType.landmarkFund;

  double get conditionRentMultiplier =>
      (1 + (propertyCondition - 70) * 0.003).clamp(0.85, 1.10).toDouble();

  double get conditionRepairProbabilityMultiplier =>
      ((115 - propertyCondition) / 45).clamp(0.50, 1.80).toDouble();

  double get conditionRepairCostMultiplier =>
      (1 + (70 - propertyCondition) * 0.008).clamp(0.70, 1.50).toDouble();

  RealEstateAssetType get assetType =>
      marketAsset?.type ?? RealEstateAssetType.commercialUnit;

  int get effectiveCashInvestedAtPurchase =>
      cashInvestedAtPurchase > 0 ? cashInvestedAtPurchase : purchasePrice;

  int get mortgageRemainingMonths {
    final remaining = mortgageTermMonths - mortgagePaymentsMade;
    return remaining > 0 ? remaining : 1;
  }

  int get monthlyMortgagePayment {
    if (!hasMortgage) return 0;
    final calculated = mortgageMonthlyPayment(
      mortgageBalance,
      mortgageAnnualInterestRate,
      mortgageRemainingMonths,
    );
    final finalPayoff = mortgageBalance + nextMortgageInterest;
    return calculated < finalPayoff ? calculated : finalPayoff;
  }

  int get nextMortgageInterest =>
      mortgageMonthlyInterest(mortgageBalance, mortgageAnnualInterestRate);

  OwnedRealEstate recordMortgagePayment({int? nextPaymentDay}) {
    if (!hasMortgage) return this;
    final due = monthlyMortgagePayment;
    final interest = nextMortgageInterest;
    final principalPaid = (due - interest).clamp(0, mortgageBalance).toInt();
    return copyWith(
      mortgageBalance: mortgageBalance - principalPaid,
      mortgagePaymentsMade: mortgagePaymentsMade + 1,
      mortgageMissedPayments: 0,
      nextMortgagePaymentDay: nextPaymentDay ?? nextMortgagePaymentDay,
    );
  }

  OwnedRealEstate recordMissedMortgagePayment({int? nextPaymentDay}) {
    if (!hasMortgage) return this;
    return copyWith(
      mortgageBalance: mortgageBalance + nextMortgageInterest,
      mortgageMissedPayments: mortgageMissedPayments + 1,
      nextMortgagePaymentDay: nextPaymentDay ?? nextMortgagePaymentDay,
    );
  }

  OwnedRealEstate copyWith({
    int? mortgageOriginalPrincipal,
    int? mortgageBalance,
    double? mortgageAnnualInterestRate,
    int? mortgageTermMonths,
    int? mortgagePaymentsMade,
    int? mortgageMissedPayments,
    int? nextMortgagePaymentDay,
    bool? mortgageIsVariableRate,
    RealEstateLeaseType? leaseType,
    int? leaseDeposit,
    int? leaseMonthlyRent,
    int? leaseRemainingMonths,
    int? nextRentalSettlementDay,
    int? tenantReliability,
    int? rentArrearsMonths,
    int? vacancyMonths,
    int? totalVacancyMonths,
    String? lastRentalEvent,
    int? totalRepairCosts,
    int? saleListedDay,
    int? saleOfferAmount,
    int? saleOfferIssuedDay,
    int? saleOfferExpiresDay,
    int? realEstateWorldVersion,
    String? investmentNote,
    int? propertyCondition,
    bool? insuranceActive,
  }) => OwnedRealEstate(
    id: id,
    optionId: optionId,
    name: name,
    purchasePrice: purchasePrice,
    acquiredDay: acquiredDay,
    monthlyIncome: monthlyIncome,
    monthlyCost: monthlyCost,
    marketAssetId: marketAssetId,
    marketPriceAtPurchase: marketPriceAtPurchase,
    acquisitionCosts: acquisitionCosts,
    purchaseDateIso: purchaseDateIso,
    marketListingIndex: marketListingIndex,
    realEstateWorldSeed: realEstateWorldSeed,
    realEstateWorldVersion:
        realEstateWorldVersion ?? this.realEstateWorldVersion,
    cashInvestedAtPurchase: cashInvestedAtPurchase,
    mortgageOriginalPrincipal:
        mortgageOriginalPrincipal ?? this.mortgageOriginalPrincipal,
    mortgageBalance: mortgageBalance ?? this.mortgageBalance,
    mortgageAnnualInterestRate:
        mortgageAnnualInterestRate ?? this.mortgageAnnualInterestRate,
    mortgageTermMonths: mortgageTermMonths ?? this.mortgageTermMonths,
    mortgagePaymentsMade: mortgagePaymentsMade ?? this.mortgagePaymentsMade,
    mortgageMissedPayments:
        mortgageMissedPayments ?? this.mortgageMissedPayments,
    nextMortgagePaymentDay:
        nextMortgagePaymentDay ?? this.nextMortgagePaymentDay,
    mortgageIsVariableRate:
        mortgageIsVariableRate ?? this.mortgageIsVariableRate,
    leaseType: leaseType ?? this.leaseType,
    leaseDeposit: leaseDeposit ?? this.leaseDeposit,
    leaseMonthlyRent: leaseMonthlyRent ?? this.leaseMonthlyRent,
    leaseRemainingMonths: leaseRemainingMonths ?? this.leaseRemainingMonths,
    nextRentalSettlementDay:
        nextRentalSettlementDay ?? this.nextRentalSettlementDay,
    tenantReliability: tenantReliability ?? this.tenantReliability,
    rentArrearsMonths: rentArrearsMonths ?? this.rentArrearsMonths,
    vacancyMonths: vacancyMonths ?? this.vacancyMonths,
    totalVacancyMonths: totalVacancyMonths ?? this.totalVacancyMonths,
    lastRentalEvent: lastRentalEvent ?? this.lastRentalEvent,
    totalRepairCosts: totalRepairCosts ?? this.totalRepairCosts,
    saleListedDay: saleListedDay ?? this.saleListedDay,
    saleOfferAmount: saleOfferAmount ?? this.saleOfferAmount,
    saleOfferIssuedDay: saleOfferIssuedDay ?? this.saleOfferIssuedDay,
    saleOfferExpiresDay: saleOfferExpiresDay ?? this.saleOfferExpiresDay,
    investmentNote: investmentNote ?? this.investmentNote,
    propertyCondition: propertyCondition ?? this.propertyCondition,
    insuranceActive: insuranceActive ?? this.insuranceActive,
  );

  RealEstateMarketAsset? get marketAsset =>
      marketAssetId == null ? null : realEstateMarketAssetById(marketAssetId!);

  GeneratedRealEstateListing? get generatedListing {
    final assetId = marketAssetId;
    final listingIndex = marketListingIndex;
    if (assetId == null ||
        listingIndex == null ||
        realEstateWorldSeed.isEmpty) {
      return null;
    }
    return realEstateListingByRef(
      RealEstateListingRef(assetId: assetId, listingIndex: listingIndex),
      realEstateWorldSeed,
      generatorVersion: realEstateWorldVersion,
    );
  }

  DateTime _dateAtDay(int day) {
    final purchaseDate = DateTime.tryParse(purchaseDateIso);
    if (purchaseDate != null) {
      return purchaseDate.add(
        Duration(days: (day - acquiredDay).clamp(0, 20000).toInt()),
      );
    }
    return DateTime(2000).add(Duration(days: day.clamp(1, 20000).toInt() - 1));
  }

  int estimatedMarketValue(int currentDay) {
    final listing = generatedListing;
    if (listing != null) return listing.priceAt(_dateAtDay(currentDay));
    final asset = marketAsset;
    if (asset != null) return asset.priceAt(_dateAtDay(currentDay));
    final heldYears = ((currentDay - acquiredDay).clamp(0, 5000) / 365).floor();
    final valueRate = (90 + heldYears * 2).clamp(90, 115);
    return (purchasePrice * valueRate / 100).round();
  }

  int estimatedSaleValue(int currentDay) {
    final listing = generatedListing;
    if (listing != null) {
      final date = _dateAtDay(currentDay);
      return (listing.priceAt(date) - listing.saleCostsAt(date))
          .clamp(0, 1 << 62)
          .toInt();
    }
    final asset = marketAsset;
    if (asset == null) return estimatedMarketValue(currentDay);
    final date = _dateAtDay(currentDay);
    return (asset.priceAt(date) - asset.saleCostsAt(date))
        .clamp(0, 1 << 62)
        .toInt();
  }

  int estimatedSaleCostsForPrice(int currentDay, int grossPrice) {
    final asset = marketAsset;
    if (asset == null || grossPrice <= 0) return 0;
    return asset.saleCostsForPrice(_dateAtDay(currentDay), grossPrice);
  }

  int get saleListingDays => realEstateSaleListingDays(
    type: assetType,
    worldSeed: realEstateWorldSeed,
    assetId: id,
    listedDay: saleListedDay,
  );

  int get saleOfferReadyDay =>
      saleListedDay <= 0 ? 0 : saleListedDay + saleListingDays;

  bool saleOfferActiveAt(int day) =>
      saleOfferAmount > 0 &&
      saleOfferIssuedDay > 0 &&
      day >= saleOfferIssuedDay &&
      (saleOfferExpiresDay <= 0 || day <= saleOfferExpiresDay);

  int estimatedSaleOfferValue(int currentDay) {
    if (saleOfferAmount > 0) return saleOfferAmount;
    final base = estimatedSaleValue(currentDay);
    if (saleListedDay <= 0) return base;
    return (base *
            realEstateSaleOfferRate(
              worldSeed: realEstateWorldSeed,
              assetId: id,
              listedDay: saleListedDay,
            ))
        .round();
  }

  int monthlyIncomeAt(DateTime date) {
    if (isLandmarkFund) {
      return generatedListing?.monthlyRentAt(date) ??
          marketAsset?.monthlyRentAt(date) ??
          monthlyIncome;
    }
    return switch (leaseType) {
      RealEstateLeaseType.automatic =>
        generatedListing?.monthlyRentAt(date) ?? monthlyIncome,
      RealEstateLeaseType.monthlyRent => leaseMonthlyRent,
      RealEstateLeaseType.vacant || RealEstateLeaseType.jeonse => 0,
    };
  }

  int monthlyCostAt(DateTime date) =>
      generatedListing?.monthlyOperatingCostAt(date) ?? monthlyCost;

  Map<String, dynamic> toJson() => {
    'id': id,
    'optionId': optionId,
    'name': name,
    'purchasePrice': purchasePrice,
    'acquiredDay': acquiredDay,
    'monthlyIncome': monthlyIncome,
    'monthlyCost': monthlyCost,
    'marketAssetId': marketAssetId,
    'marketPriceAtPurchase': marketPriceAtPurchase,
    'acquisitionCosts': acquisitionCosts,
    'purchaseDateIso': purchaseDateIso,
    'marketListingIndex': marketListingIndex,
    'realEstateWorldSeed': realEstateWorldSeed,
    'realEstateWorldVersion': realEstateWorldVersion,
    'cashInvestedAtPurchase': cashInvestedAtPurchase,
    'mortgageOriginalPrincipal': mortgageOriginalPrincipal,
    'mortgageBalance': mortgageBalance,
    'mortgageAnnualInterestRate': mortgageAnnualInterestRate,
    'mortgageTermMonths': mortgageTermMonths,
    'mortgagePaymentsMade': mortgagePaymentsMade,
    'mortgageMissedPayments': mortgageMissedPayments,
    'nextMortgagePaymentDay': nextMortgagePaymentDay,
    'mortgageIsVariableRate': mortgageIsVariableRate,
    'leaseType': leaseType.name,
    'leaseDeposit': leaseDeposit,
    'leaseMonthlyRent': leaseMonthlyRent,
    'leaseRemainingMonths': leaseRemainingMonths,
    'nextRentalSettlementDay': nextRentalSettlementDay,
    'tenantReliability': tenantReliability,
    'rentArrearsMonths': rentArrearsMonths,
    'vacancyMonths': vacancyMonths,
    'totalVacancyMonths': totalVacancyMonths,
    'lastRentalEvent': lastRentalEvent,
    'totalRepairCosts': totalRepairCosts,
    'saleListedDay': saleListedDay,
    'saleOfferAmount': saleOfferAmount,
    'saleOfferIssuedDay': saleOfferIssuedDay,
    'saleOfferExpiresDay': saleOfferExpiresDay,
    'investmentNote': investmentNote,
    'propertyCondition': propertyCondition,
    'insuranceActive': insuranceActive,
  };

  factory OwnedRealEstate.fromJson(
    Map<String, dynamic> json,
  ) => OwnedRealEstate(
    id: json['id'] as String? ?? '',
    optionId: json['optionId'] as String? ?? '',
    name: json['name'] as String? ?? '부동산',
    purchasePrice: (json['purchasePrice'] as num?)?.toInt() ?? 0,
    acquiredDay: (json['acquiredDay'] as num?)?.toInt() ?? 1,
    monthlyIncome: (json['monthlyIncome'] as num?)?.toInt() ?? 0,
    monthlyCost: (json['monthlyCost'] as num?)?.toInt() ?? 0,
    marketAssetId: json['marketAssetId'] as String?,
    marketPriceAtPurchase:
        (json['marketPriceAtPurchase'] as num?)?.toInt() ?? 0,
    acquisitionCosts: (json['acquisitionCosts'] as num?)?.toInt() ?? 0,
    purchaseDateIso: json['purchaseDateIso'] as String? ?? '',
    marketListingIndex: (json['marketListingIndex'] as num?)?.toInt(),
    realEstateWorldSeed: json['realEstateWorldSeed'] as String? ?? '',
    realEstateWorldVersion:
        (json['realEstateWorldVersion'] as num?)?.toInt() ?? 1,
    cashInvestedAtPurchase:
        (json['cashInvestedAtPurchase'] as num?)?.toInt() ?? 0,
    mortgageOriginalPrincipal:
        (json['mortgageOriginalPrincipal'] as num?)?.toInt() ?? 0,
    mortgageBalance: (json['mortgageBalance'] as num?)?.toInt() ?? 0,
    mortgageAnnualInterestRate:
        (json['mortgageAnnualInterestRate'] as num?)?.toDouble() ?? 0,
    mortgageTermMonths: (json['mortgageTermMonths'] as num?)?.toInt() ?? 0,
    mortgagePaymentsMade: (json['mortgagePaymentsMade'] as num?)?.toInt() ?? 0,
    mortgageMissedPayments:
        (json['mortgageMissedPayments'] as num?)?.toInt() ?? 0,
    nextMortgagePaymentDay:
        (json['nextMortgagePaymentDay'] as num?)?.toInt() ??
        ((json['acquiredDay'] as num?)?.toInt() ?? 1) + 30,
    mortgageIsVariableRate: json['mortgageIsVariableRate'] as bool? ?? false,
    leaseType: RealEstateLeaseType.values.firstWhere(
      (value) => value.name == json['leaseType'],
      orElse: () => RealEstateLeaseType.automatic,
    ),
    leaseDeposit: (json['leaseDeposit'] as num?)?.toInt() ?? 0,
    leaseMonthlyRent: (json['leaseMonthlyRent'] as num?)?.toInt() ?? 0,
    leaseRemainingMonths: (json['leaseRemainingMonths'] as num?)?.toInt() ?? 0,
    nextRentalSettlementDay:
        (json['nextRentalSettlementDay'] as num?)?.toInt() ??
        ((json['acquiredDay'] as num?)?.toInt() ?? 1) + 30,
    tenantReliability: (json['tenantReliability'] as num?)?.toInt() ?? 0,
    rentArrearsMonths: (json['rentArrearsMonths'] as num?)?.toInt() ?? 0,
    vacancyMonths: (json['vacancyMonths'] as num?)?.toInt() ?? 0,
    totalVacancyMonths:
        (json['totalVacancyMonths'] as num?)?.toInt() ??
        (json['vacancyMonths'] as num?)?.toInt() ??
        0,
    lastRentalEvent: json['lastRentalEvent'] as String? ?? '',
    totalRepairCosts: (json['totalRepairCosts'] as num?)?.toInt() ?? 0,
    saleListedDay: (json['saleListedDay'] as num?)?.toInt() ?? 0,
    saleOfferAmount: (json['saleOfferAmount'] as num?)?.toInt() ?? 0,
    saleOfferIssuedDay: (json['saleOfferIssuedDay'] as num?)?.toInt() ?? 0,
    saleOfferExpiresDay: (json['saleOfferExpiresDay'] as num?)?.toInt() ?? 0,
    investmentNote: json['investmentNote'] as String? ?? '',
    propertyCondition: ((json['propertyCondition'] as num?)?.toInt() ?? 70)
        .clamp(0, 100)
        .toInt(),
    insuranceActive: json['insuranceActive'] as bool? ?? false,
  );
}

class PersonalFinanceState {
  const PersonalFinanceState({
    required this.realEstate,
    required this.permanentPurchases,
    required this.lastPurchasePeriods,
    required this.totalSpent,
    required this.totalPropertyIncome,
    required this.lastChanceMonth,
    required this.chancePlayCount,
    required this.totalChanceStake,
    required this.totalChancePayout,
  });

  factory PersonalFinanceState.initial() => const PersonalFinanceState(
    realEstate: [],
    permanentPurchases: [],
    lastPurchasePeriods: {},
    totalSpent: 0,
    totalPropertyIncome: 0,
    lastChanceMonth: '',
    chancePlayCount: 0,
    totalChanceStake: 0,
    totalChancePayout: 0,
  );

  final List<OwnedRealEstate> realEstate;
  final List<String> permanentPurchases;
  final Map<String, String> lastPurchasePeriods;
  final int totalSpent;
  final int totalPropertyIncome;
  final String lastChanceMonth;
  final int chancePlayCount;
  final int totalChanceStake;
  final int totalChancePayout;

  bool ownsRealEstate(String optionId) =>
      realEstate.any((asset) => asset.optionId == optionId);

  bool hasPermanentPurchase(String optionId) =>
      permanentPurchases.contains(optionId);

  int get propertyBookValue =>
      realEstate.fold<int>(0, (sum, asset) => sum + asset.purchasePrice);

  int get totalMortgageBalance =>
      realEstate.fold<int>(0, (sum, asset) => sum + asset.mortgageBalance);

  int get totalTenantDepositLiability => realEstate.fold<int>(
    0,
    (sum, asset) => sum + (asset.hasActiveLease ? asset.leaseDeposit : 0),
  );

  int get ownedHousingCount =>
      realEstate.where((asset) => asset.assetType.isHousing).length;

  int propertyEquityAt(int day) =>
      estimatedPropertyValueAt(day) -
      totalMortgageBalance -
      totalTenantDepositLiability;

  int get monthlyMortgagePayment => realEstate.fold<int>(
    0,
    (sum, asset) => sum + asset.monthlyMortgagePayment,
  );

  int estimatedPropertyValueAt(int day) => realEstate.fold<int>(
    0,
    (sum, asset) => sum + asset.estimatedMarketValue(day),
  );

  int get monthlyPropertyIncome =>
      realEstate.fold<int>(0, (sum, asset) => sum + asset.monthlyIncome);

  int get monthlyPropertyCost =>
      realEstate.fold<int>(0, (sum, asset) => sum + asset.monthlyCost);

  int monthlyPropertyIncomeAt(DateTime date) => realEstate.fold<int>(
    0,
    (sum, asset) => sum + asset.monthlyIncomeAt(date),
  );

  int monthlyPropertyCostAt(DateTime date) =>
      realEstate.fold<int>(0, (sum, asset) => sum + asset.monthlyCostAt(date));

  int monthlyPropertyHoldingTaxAt(int day, DateTime date) =>
      realEstate.fold<int>(
        0,
        (sum, asset) =>
            sum +
            realEstateMonthlyHoldingTax(
              date: date,
              type: asset.assetType,
              marketValue: asset.estimatedMarketValue(day),
              ownedHousingCount: ownedHousingCount,
            ),
      );

  int monthlyResearchBonusAt(int year, int employeeCount) {
    var total = 0;
    for (final option in spendingCatalog) {
      final active = option.repeat == SpendingRepeat.once
          ? permanentPurchases.contains(option.id)
          : option.repeat == SpendingRepeat.yearly &&
                lastPurchasePeriods[option.id] == '$year';
      if (!active) continue;
      total += option.researchIncomeBonus;
      total += option.researchIncomePerEmployeeBonus * employeeCount;
    }
    return total;
  }

  int get chanceNet => totalChancePayout - totalChanceStake;

  PersonalFinanceState copyWith({
    List<OwnedRealEstate>? realEstate,
    List<String>? permanentPurchases,
    Map<String, String>? lastPurchasePeriods,
    int? totalSpent,
    int? totalPropertyIncome,
    String? lastChanceMonth,
    int? chancePlayCount,
    int? totalChanceStake,
    int? totalChancePayout,
  }) => PersonalFinanceState(
    realEstate: realEstate ?? this.realEstate,
    permanentPurchases: permanentPurchases ?? this.permanentPurchases,
    lastPurchasePeriods: lastPurchasePeriods ?? this.lastPurchasePeriods,
    totalSpent: totalSpent ?? this.totalSpent,
    totalPropertyIncome: totalPropertyIncome ?? this.totalPropertyIncome,
    lastChanceMonth: lastChanceMonth ?? this.lastChanceMonth,
    chancePlayCount: chancePlayCount ?? this.chancePlayCount,
    totalChanceStake: totalChanceStake ?? this.totalChanceStake,
    totalChancePayout: totalChancePayout ?? this.totalChancePayout,
  );

  Map<String, dynamic> toJson() => {
    'realEstate': realEstate.map((asset) => asset.toJson()).toList(),
    'permanentPurchases': permanentPurchases,
    'lastPurchasePeriods': lastPurchasePeriods,
    'totalSpent': totalSpent,
    'totalPropertyIncome': totalPropertyIncome,
    'lastChanceMonth': lastChanceMonth,
    'chancePlayCount': chancePlayCount,
    'totalChanceStake': totalChanceStake,
    'totalChancePayout': totalChancePayout,
  };

  factory PersonalFinanceState.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return PersonalFinanceState.initial();
    return PersonalFinanceState(
      realEstate: ((json['realEstate'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => OwnedRealEstate.fromJson(item.cast<String, dynamic>()))
          .where((asset) => asset.id.isNotEmpty && asset.purchasePrice >= 0)
          .toList(growable: false),
      permanentPurchases: ((json['permanentPurchases'] as List?) ?? const [])
          .whereType<String>()
          .toSet()
          .toList(growable: false),
      lastPurchasePeriods: ((json['lastPurchasePeriods'] as Map?) ?? const {})
          .map((key, value) => MapEntry(key.toString(), value.toString())),
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      totalPropertyIncome: (json['totalPropertyIncome'] as num?)?.toInt() ?? 0,
      lastChanceMonth: json['lastChanceMonth'] as String? ?? '',
      chancePlayCount: (json['chancePlayCount'] as num?)?.toInt() ?? 0,
      totalChanceStake: (json['totalChanceStake'] as num?)?.toInt() ?? 0,
      totalChancePayout: (json['totalChancePayout'] as num?)?.toInt() ?? 0,
    );
  }
}
