import 'dart:math' as math;

enum RealEstateInvestmentTier {
  starter,
  income,
  apartment,
  prestige,
  building,
  landmark,
}

extension RealEstateInvestmentTierLabel on RealEstateInvestmentTier {
  String get label => switch (this) {
    RealEstateInvestmentTier.starter => '1단계 · 첫 부동산',
    RealEstateInvestmentTier.income => '2단계 · 월세 기반',
    RealEstateInvestmentTier.apartment => '3단계 · 수도권 아파트',
    RealEstateInvestmentTier.prestige => '4단계 · 핵심지 대장주',
    RealEstateInvestmentTier.building => '5단계 · 대형 빌딩',
    RealEstateInvestmentTier.landmark => '6단계 · 랜드마크',
  };

  String get description => switch (this) {
    RealEstateInvestmentTier.starter => '수천만원대 오피스텔과 노후 빌라로 시작합니다.',
    RealEstateInvestmentTier.income => '월세와 공실, 유지비를 함께 관리합니다.',
    RealEstateInvestmentTier.apartment => '서울 외곽과 경기 신도시의 가격 흐름을 탑니다.',
    RealEstateInvestmentTier.prestige => '실제 유명 고가 단지의 면적별 거래를 추적합니다.',
    RealEstateInvestmentTier.building => '법인으로 임대수익과 공실률을 운영합니다.',
    RealEstateInvestmentTier.landmark => '전체 매입 대신 기관형 지분 투자로 접근합니다.',
  };
}

enum RealEstateAssetType {
  officetel,
  villa,
  apartment,
  commercialUnit,
  officeBuilding,
  landmarkFund,
}

extension RealEstateAssetTypeLabel on RealEstateAssetType {
  String get label => switch (this) {
    RealEstateAssetType.officetel => '오피스텔',
    RealEstateAssetType.villa => '빌라',
    RealEstateAssetType.apartment => '아파트',
    RealEstateAssetType.commercialUnit => '상가',
    RealEstateAssetType.officeBuilding => '오피스 빌딩',
    RealEstateAssetType.landmarkFund => '랜드마크 지분',
  };

  bool get isHousing => switch (this) {
    RealEstateAssetType.villa || RealEstateAssetType.apartment => true,
    _ => false,
  };
}

enum RealEstatePriceEvidence {
  actualTransaction,
  actualBuildingSale,
  indexBackcast,
  appraisedEstimate,
  gameExtension,
}

extension RealEstatePriceEvidenceLabel on RealEstatePriceEvidence {
  String get label => switch (this) {
    RealEstatePriceEvidence.actualTransaction => '실거래',
    RealEstatePriceEvidence.actualBuildingSale => '실제 빌딩 매각',
    RealEstatePriceEvidence.indexBackcast => '가격지수 역산',
    RealEstatePriceEvidence.appraisedEstimate => '시장평가',
    RealEstatePriceEvidence.gameExtension => '게임 연장',
  };
}

class RealEstatePriceAnchor {
  const RealEstatePriceAnchor({
    required this.date,
    required this.price,
    required this.evidence,
    required this.sourceLabel,
  });

  final DateTime date;
  final int price;
  final RealEstatePriceEvidence evidence;
  final String sourceLabel;
}

class RealEstatePurchaseQuote {
  const RealEstatePurchaseQuote({
    required this.marketPrice,
    required this.acquisitionTax,
    required this.localEducationTax,
    required this.ruralSpecialTax,
    required this.brokerageFee,
    required this.brokerageVat,
    required this.bondLegalAndRegistration,
  });

  final int marketPrice;
  final int acquisitionTax;
  final int localEducationTax;
  final int ruralSpecialTax;
  final int brokerageFee;
  final int brokerageVat;
  final int bondLegalAndRegistration;

  int get acquisitionCosts =>
      acquisitionTax +
      localEducationTax +
      ruralSpecialTax +
      brokerageFee +
      brokerageVat +
      bondLegalAndRegistration;

  int get totalCash => marketPrice + acquisitionCosts;

  RealEstatePurchaseQuote copyWith({
    int? acquisitionTax,
    int? localEducationTax,
  }) => RealEstatePurchaseQuote(
    marketPrice: marketPrice,
    acquisitionTax: acquisitionTax ?? this.acquisitionTax,
    localEducationTax: localEducationTax ?? this.localEducationTax,
    ruralSpecialTax: ruralSpecialTax,
    brokerageFee: brokerageFee,
    brokerageVat: brokerageVat,
    bondLegalAndRegistration: bondLegalAndRegistration,
  );
}

/// 보유 주택 수까지 반영한 게임용 취득세 견적이다.
///
/// 기준 매물의 시대별 세율은 유지하되, 두 번째 주택부터 눈덩이 매입을
/// 억제하는 단순화 중과를 더한다. 오피스텔·상가·빌딩·지분은 제외한다.
RealEstatePurchaseQuote realEstatePortfolioAdjustedPurchaseQuote({
  required RealEstatePurchaseQuote baseQuote,
  required DateTime date,
  required RealEstateAssetType type,
  required int ownedHousingCount,
}) {
  if (!type.isHousing || ownedHousingCount <= 0) return baseQuote;
  final additionalRate = switch ((date.year, ownedHousingCount)) {
    (>= 2020, >= 2) => 0.08,
    (>= 2020, _) => 0.04,
    (>= 2018, >= 2) => 0.04,
    (>= 2018, _) => 0.02,
    (_, >= 2) => 0.02,
    _ => 0.01,
  };
  final surcharge = (baseQuote.marketPrice * additionalRate).round();
  return baseQuote.copyWith(
    acquisitionTax: baseQuote.acquisitionTax + surcharge,
    localEducationTax: baseQuote.localEducationTax + (surcharge * 0.1).round(),
  );
}

/// 매각 중개비와 취득원가를 뺀 양도차익에 적용하는 게임용 양도세.
int realEstateCapitalGainsTax({
  required DateTime saleDate,
  required RealEstateAssetType type,
  required int ownedHousingCount,
  required int holdingDays,
  required int netSaleBeforeTax,
  required int purchaseCost,
}) {
  final gain = netSaleBeforeTax - purchaseCost;
  if (gain <= 0) return 0;
  var rate = switch (holdingDays) {
    < 365 => 0.40,
    < 730 => 0.25,
    _ => 0.15,
  };
  if (type.isHousing && saleDate.year >= 2018 && ownedHousingCount > 1) {
    rate += ownedHousingCount >= 3 ? 0.20 : 0.10;
  }
  return (gain * rate.clamp(0.0, 0.60)).round();
}

/// 월 정산 때 별도로 빠져나가는 보유세·다주택 중과 적립액.
int realEstateMonthlyHoldingTax({
  required DateTime date,
  required RealEstateAssetType type,
  required int marketValue,
  required int ownedHousingCount,
}) {
  if (marketValue <= 0) return 0;
  var annualRate = switch (type) {
    RealEstateAssetType.villa || RealEstateAssetType.apartment => 0.0015,
    RealEstateAssetType.officetel => 0.0018,
    RealEstateAssetType.commercialUnit => 0.0025,
    RealEstateAssetType.officeBuilding => 0.0030,
    RealEstateAssetType.landmarkFund => 0.0010,
  };
  if (type.isHousing && ownedHousingCount > 1) {
    annualRate +=
        (ownedHousingCount - 1) * (date.year >= 2020 ? 0.0025 : 0.0015);
  }
  final baseTax = marketValue * annualRate;
  final highValueTax = type.isHousing && marketValue > 900000000
      ? (marketValue - 900000000) * (date.year >= 2020 ? 0.003 : 0.002)
      : 0.0;
  return ((baseTax + highValueTax) / 12).round();
}

int realEstateSaleListingDays({
  required RealEstateAssetType type,
  required String worldSeed,
  required String assetId,
  required int listedDay,
}) {
  final spread = switch (type) {
    RealEstateAssetType.villa ||
    RealEstateAssetType.apartment ||
    RealEstateAssetType.officetel => 31,
    RealEstateAssetType.commercialUnit => 46,
    RealEstateAssetType.officeBuilding => 61,
    RealEstateAssetType.landmarkFund => 11,
  };
  final minimum = switch (type) {
    RealEstateAssetType.landmarkFund => 5,
    RealEstateAssetType.officeBuilding => 30,
    _ => 14,
  };
  return minimum +
      _realEstateStableHash('$worldSeed:$assetId:$listedDay:sale-wait') %
          spread;
}

double realEstateSaleOfferRate({
  required String worldSeed,
  required String assetId,
  required int listedDay,
}) =>
    (9300 +
        _realEstateStableHash('$worldSeed:$assetId:$listedDay:sale-offer') %
            901) /
    10000;

int _realEstateStableHash(String value) {
  var hash = 2166136261;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash;
}

class RealEstateMarketAsset {
  RealEstateMarketAsset({
    required this.id,
    required this.name,
    required this.region,
    required this.province,
    required this.type,
    required this.tier,
    required this.availableFrom,
    required this.areaSquareMeters,
    required this.imageAsset,
    required this.priceAnchors,
    required this.annualGrossYield,
    required this.annualOperatingCostRate,
    required this.sourceNote,
    this.realNamedAsset = false,
    this.requiresLegalCompany = false,
  }) : assert(priceAnchors.length >= 2);

  final String id;
  final String name;
  final String region;
  final String province;
  final RealEstateAssetType type;
  final RealEstateInvestmentTier tier;
  final DateTime availableFrom;
  final double areaSquareMeters;
  final String imageAsset;
  final List<RealEstatePriceAnchor> priceAnchors;
  final double annualGrossYield;
  final double annualOperatingCostRate;
  final String sourceNote;
  final bool realNamedAsset;
  final bool requiresLegalCompany;

  RealEstatePriceAnchor evidenceAt(DateTime date) {
    final anchors = [...priceAnchors]
      ..sort((left, right) => left.date.compareTo(right.date));
    var latestPublished = anchors.first;
    for (final anchor in anchors) {
      if (anchor.date.isAfter(date)) break;
      latestPublished = anchor;
    }
    return latestPublished;
  }

  int priceAt(DateTime date) {
    final anchors = [...priceAnchors]..sort((a, b) => a.date.compareTo(b.date));
    if (!date.isAfter(anchors.first.date)) return anchors.first.price;
    if (!date.isBefore(anchors.last.date)) return anchors.last.price;
    for (var index = 1; index < anchors.length; index += 1) {
      final previous = anchors[index - 1];
      final next = anchors[index];
      if (date.isAfter(next.date)) continue;
      final span = next.date.difference(previous.date).inDays;
      if (span <= 0) return next.price;
      final elapsed = date.difference(previous.date).inDays;
      final progress = (elapsed / span).clamp(0.0, 1.0);
      return (previous.price + (next.price - previous.price) * progress)
          .round();
    }
    return anchors.last.price;
  }

  /// 임대료는 매매가와 별도의 임대수요 지수를 중심으로 움직인다.
  ///
  /// 매매가를 그대로 곱하면 장기 상승장에서 가격과 월세가 같은 속도로
  /// 복리 상승해 초기 수익률이 영원히 유지된다. 기준일 임대료는 기존
  /// 수익률을 보존하되 이후에는 임대료 지수와 낮은 가격 탄력성만 반영해
  /// 가격이 빠르게 오를수록 자연스럽게 cap rate가 압축되도록 한다.
  int monthlyRentAt(DateTime date) {
    final referenceDate = availableFrom.isAfter(DateTime(2000, 1, 1))
        ? availableFrom
        : DateTime(2000, 1, 1);
    final referencePrice = priceAt(referenceDate);
    if (referencePrice <= 0) return 0;
    final referenceRent = referencePrice * annualGrossYield / 12;
    final rentIndexGrowth =
        realEstateRentIndexAt(date, type) /
        realEstateRentIndexAt(referenceDate, type);
    final priceGrowth = (priceAt(date) / referencePrice).clamp(0.35, 6.0);
    final priceElasticity = switch (type) {
      RealEstateAssetType.villa || RealEstateAssetType.apartment => 0.12,
      RealEstateAssetType.officetel => 0.16,
      RealEstateAssetType.commercialUnit => 0.22,
      RealEstateAssetType.officeBuilding => 0.26,
      RealEstateAssetType.landmarkFund => 0.18,
    };
    return (referenceRent *
            rentIndexGrowth *
            math.pow(priceGrowth, priceElasticity))
        .round();
  }

  int monthlyOperatingCostAt(DateTime date) =>
      (priceAt(date) * annualOperatingCostRate / 12).round();

  RealEstatePurchaseQuote quoteAt(DateTime date) =>
      quoteForPrice(date, priceAt(date));

  RealEstatePurchaseQuote quoteForPrice(DateTime date, int price) {
    final acquisitionTaxRate = _acquisitionTaxRate(date, price);
    final acquisitionTax = (price * acquisitionTaxRate).round();
    final educationRate = type.isHousing ? acquisitionTaxRate * 0.1 : 0.004;
    final localEducationTax = (price * educationRate).round();
    final ruralSpecialTax =
        (type.isHousing && areaSquareMeters <= 85) ||
            type == RealEstateAssetType.landmarkFund
        ? 0
        : (price * 0.002).round();
    final brokerageFee = _brokerageFee(date, price);
    final brokerageVat = (brokerageFee * 0.1).round();
    final bondLegalAndRegistration = switch (type) {
      RealEstateAssetType.landmarkFund => (price * 0.001).round(),
      _ => (price * 0.0012).round().clamp(250000, 150000000).toInt(),
    };
    return RealEstatePurchaseQuote(
      marketPrice: price,
      acquisitionTax: acquisitionTax,
      localEducationTax: localEducationTax,
      ruralSpecialTax: ruralSpecialTax,
      brokerageFee: brokerageFee,
      brokerageVat: brokerageVat,
      bondLegalAndRegistration: bondLegalAndRegistration,
    );
  }

  int saleCostsAt(DateTime date) => saleCostsForPrice(date, priceAt(date));

  int saleCostsForPrice(DateTime date, int price) {
    final brokerage = _brokerageFee(date, price);
    return brokerage + (brokerage * 0.1).round();
  }

  double _acquisitionTaxRate(DateTime date, int price) {
    if (type == RealEstateAssetType.landmarkFund) return 0.002;
    if (!type.isHousing) return 0.04;
    if (date.year < 2011) return 0.04;
    if (price <= 600000000) return 0.01;
    if (price > 900000000) return 0.03;
    return 0.01 + ((price - 600000000) / 300000000) * 0.02;
  }

  int _brokerageFee(DateTime date, int price) {
    if (type == RealEstateAssetType.landmarkFund) {
      return (price * 0.002).round();
    }
    if (type == RealEstateAssetType.officetel) {
      final rate = date.isBefore(DateTime(2015, 1, 6)) ? 0.009 : 0.005;
      return (price * rate).round();
    }
    if (!type.isHousing) return (price * 0.009).round();
    if (date.isBefore(DateTime(2021, 12, 30))) {
      if (price < 50000000) {
        return (price * 0.006).round().clamp(0, 250000).toInt();
      }
      if (price < 200000000) {
        return (price * 0.005).round().clamp(0, 800000).toInt();
      }
      if (price < 600000000) return (price * 0.004).round();
      if (price < 900000000) return (price * 0.005).round();
      return (price * 0.009).round();
    }
    if (price < 50000000) {
      return (price * 0.006).round().clamp(0, 250000).toInt();
    }
    if (price < 200000000) {
      return (price * 0.005).round().clamp(0, 800000).toInt();
    }
    if (price < 900000000) return (price * 0.004).round();
    if (price < 1200000000) return (price * 0.005).round();
    if (price < 1500000000) return (price * 0.006).round();
    return (price * 0.007).round();
  }
}

/// 2000년 1월을 1.0으로 둔 게임용 임대료 수요 지수다.
///
/// 주택·오피스텔은 가계소득과 전월세 수요, 상업용은 경기와 공실 사이클을
/// 반영한다. 매매가격 앵커와 독립적이어서 가격 급등이 월세로 즉시
/// 전이되지 않는다.
double realEstateRentIndexAt(DateTime date, RealEstateAssetType type) {
  final normalized = DateTime(date.year, date.month, date.day);
  final start = DateTime(2000, 1, 1);
  if (!normalized.isAfter(start)) return 1.0;
  var index = 1.0;
  for (var year = 2000; year < normalized.year; year += 1) {
    index *= 1 + _realEstateAnnualRentGrowthRate(year, type);
  }
  final yearStart = DateTime(normalized.year, 1, 1);
  final nextYear = DateTime(normalized.year + 1, 1, 1);
  final elapsed = normalized.difference(yearStart).inDays;
  final yearDays = nextYear.difference(yearStart).inDays;
  final fraction = (elapsed / yearDays).clamp(0.0, 1.0);
  return index *
      math.pow(
        1 + _realEstateAnnualRentGrowthRate(normalized.year, type),
        fraction,
      );
}

double _realEstateAnnualRentGrowthRate(int year, RealEstateAssetType type) {
  final housingRate = switch (year) {
    <= 2002 => 0.045,
    <= 2007 => 0.035,
    <= 2009 => 0.012,
    <= 2012 => 0.052,
    <= 2019 => 0.028,
    <= 2021 => 0.055,
    <= 2023 => 0.012,
    _ => 0.022,
  };
  final commercialRate = switch (year) {
    <= 2002 => 0.032,
    <= 2007 => 0.026,
    <= 2009 => -0.030,
    <= 2012 => 0.025,
    <= 2019 => 0.020,
    <= 2021 => -0.018,
    <= 2023 => 0.034,
    _ => 0.020,
  };
  return switch (type) {
    RealEstateAssetType.villa || RealEstateAssetType.apartment => housingRate,
    RealEstateAssetType.officetel => housingRate - 0.004,
    RealEstateAssetType.commercialUnit => commercialRate,
    RealEstateAssetType.officeBuilding => commercialRate + 0.002,
    RealEstateAssetType.landmarkFund => (housingRate + commercialRate) / 2,
  };
}

RealEstatePriceAnchor _anchor(
  int year,
  int month,
  int price,
  RealEstatePriceEvidence evidence,
  String source,
) => RealEstatePriceAnchor(
  date: DateTime(year, month),
  price: price,
  evidence: evidence,
  sourceLabel: source,
);

final realEstateMarketCatalog = <RealEstateMarketAsset>[
  RealEstateMarketAsset(
    id: 'bucheon_jungdong_officetel_18',
    name: '부천 중동 소형 오피스텔 18㎡',
    region: '부천시',
    province: '경기도',
    type: RealEstateAssetType.officetel,
    tier: RealEstateInvestmentTier.starter,
    availableFrom: DateTime(2000, 1),
    areaSquareMeters: 18,
    imageAsset: 'assets/images/real_estate/01_entry_officetel_2000.png',
    priceAnchors: [
      _anchor(
        2000,
        1,
        32000000,
        RealEstatePriceEvidence.indexBackcast,
        '2000년 경기 소형 오피스텔 가격지수 추정',
      ),
      _anchor(
        2006,
        1,
        43000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '경기 소형 오피스텔 기준가',
      ),
      _anchor(
        2013,
        1,
        55000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '경기 소형 오피스텔 시장평가',
      ),
      _anchor(
        2021,
        1,
        76000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '경기 소형 오피스텔 시장평가',
      ),
      _anchor(
        2026,
        6,
        68000000,
        RealEstatePriceEvidence.gameExtension,
        '최근 실거래 보정 후 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.078,
    annualOperatingCostRate: 0.017,
    sourceNote: '지역·면적 대표 매물이며 실제 단지명은 사용하지 않습니다.',
  ),
  RealEstateMarketAsset(
    id: 'uijeongbu_station_officetel_20',
    name: '의정부역 소형 오피스텔 20㎡',
    region: '의정부시',
    province: '경기도',
    type: RealEstateAssetType.officetel,
    tier: RealEstateInvestmentTier.starter,
    availableFrom: DateTime(2000, 1),
    areaSquareMeters: 20,
    imageAsset: 'assets/images/real_estate/01_entry_officetel_2000.png',
    priceAnchors: [
      _anchor(
        2000,
        1,
        28000000,
        RealEstatePriceEvidence.indexBackcast,
        '2000년 경기 역세권 오피스텔 가격지수 추정',
      ),
      _anchor(
        2006,
        1,
        37000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '경기 북부 소형 오피스텔 기준가',
      ),
      _anchor(
        2015,
        1,
        48000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '경기 북부 소형 오피스텔 시장평가',
      ),
      _anchor(
        2021,
        1,
        66000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '경기 북부 소형 오피스텔 시장평가',
      ),
      _anchor(
        2026,
        6,
        59000000,
        RealEstatePriceEvidence.gameExtension,
        '최근 실거래 보정 후 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.082,
    annualOperatingCostRate: 0.019,
    sourceNote: '저가 진입용 지역 대표 매물입니다.',
  ),
  RealEstateMarketAsset(
    id: 'guro_station_officetel_21',
    name: '구로 역세권 오피스텔 21㎡',
    region: '구로구',
    province: '서울특별시',
    type: RealEstateAssetType.officetel,
    tier: RealEstateInvestmentTier.starter,
    availableFrom: DateTime(2000, 1),
    areaSquareMeters: 21,
    imageAsset: 'assets/images/real_estate/01_entry_officetel_2000.png',
    priceAnchors: [
      _anchor(
        2000,
        1,
        42000000,
        RealEstatePriceEvidence.indexBackcast,
        '2000년 서울 소형 오피스텔 가격지수 추정',
      ),
      _anchor(
        2006,
        1,
        59000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '서울 서남권 소형 오피스텔 기준가',
      ),
      _anchor(
        2013,
        1,
        78000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '서울 서남권 소형 오피스텔 시장평가',
      ),
      _anchor(
        2021,
        1,
        122000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '서울 서남권 소형 오피스텔 시장평가',
      ),
      _anchor(
        2026,
        6,
        108000000,
        RealEstatePriceEvidence.gameExtension,
        '최근 실거래 보정 후 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.071,
    annualOperatingCostRate: 0.016,
    sourceNote: '실제 지역 시세를 따르는 대표 매물입니다.',
  ),
  RealEstateMarketAsset(
    id: 'nowon_sanggye_villa_29',
    name: '상계동 노후 빌라 29㎡',
    region: '노원구',
    province: '서울특별시',
    type: RealEstateAssetType.villa,
    tier: RealEstateInvestmentTier.starter,
    availableFrom: DateTime(2000, 1),
    areaSquareMeters: 29,
    imageAsset: 'assets/images/real_estate/02_entry_villa_2000.png',
    priceAnchors: [
      _anchor(
        2000,
        1,
        47000000,
        RealEstatePriceEvidence.indexBackcast,
        '2000년 서울 연립·다세대 가격지수 추정',
      ),
      _anchor(
        2006,
        1,
        71000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '서울 동북권 연립·다세대 기준가',
      ),
      _anchor(
        2013,
        1,
        98000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '서울 동북권 연립·다세대 시장평가',
      ),
      _anchor(
        2021,
        1,
        185000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '서울 동북권 연립·다세대 시장평가',
      ),
      _anchor(
        2026,
        6,
        166000000,
        RealEstatePriceEvidence.gameExtension,
        '최근 실거래 보정 후 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.061,
    annualOperatingCostRate: 0.021,
    sourceNote: '노후도와 소규모 수선 위험이 큰 입문 자산입니다.',
  ),
  RealEstateMarketAsset(
    id: 'bucheon_old_apartment_49',
    name: '부천 중동 구축 아파트 49㎡',
    region: '부천시',
    province: '경기도',
    type: RealEstateAssetType.apartment,
    tier: RealEstateInvestmentTier.income,
    availableFrom: DateTime(2000, 1),
    areaSquareMeters: 49,
    imageAsset: 'assets/images/real_estate/03_gyeonggi_old_apartment_2000.png',
    priceAnchors: [
      _anchor(
        2000,
        1,
        78000000,
        RealEstatePriceEvidence.indexBackcast,
        '2000년 경기 소형 아파트 가격지수 추정',
      ),
      _anchor(
        2006,
        1,
        128000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '경기 1기 신도시 소형 아파트 기준가',
      ),
      _anchor(
        2013,
        1,
        170000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '경기 1기 신도시 소형 아파트 시장평가',
      ),
      _anchor(
        2021,
        1,
        345000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '경기 1기 신도시 소형 아파트 시장평가',
      ),
      _anchor(
        2026,
        6,
        292000000,
        RealEstatePriceEvidence.gameExtension,
        '최근 실거래 보정 후 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.049,
    annualOperatingCostRate: 0.012,
    sourceNote: '월세와 가격 변동을 함께 보는 2단계 자산입니다.',
  ),
  RealEstateMarketAsset(
    id: 'ilsan_old_apartment_59',
    name: '일산 신도시 아파트 59㎡',
    region: '고양시',
    province: '경기도',
    type: RealEstateAssetType.apartment,
    tier: RealEstateInvestmentTier.apartment,
    availableFrom: DateTime(2000, 1),
    areaSquareMeters: 59,
    imageAsset: 'assets/images/real_estate/03_gyeonggi_old_apartment_2000.png',
    priceAnchors: [
      _anchor(
        2000,
        1,
        105000000,
        RealEstatePriceEvidence.indexBackcast,
        '2000년 경기 신도시 아파트 가격지수 추정',
      ),
      _anchor(
        2006,
        1,
        172000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '일산 소형 아파트 기준가',
      ),
      _anchor(
        2013,
        1,
        220000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '일산 소형 아파트 시장평가',
      ),
      _anchor(
        2021,
        1,
        475000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '일산 소형 아파트 시장평가',
      ),
      _anchor(
        2026,
        6,
        405000000,
        RealEstatePriceEvidence.gameExtension,
        '최근 실거래 보정 후 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.041,
    annualOperatingCostRate: 0.011,
    sourceNote: '서울 접근성과 1기 신도시 노후화가 함께 반영됩니다.',
  ),
  RealEstateMarketAsset(
    id: 'pangyo_prugio_granbleu_140',
    name: '판교푸르지오그랑블 140㎡',
    region: '성남시',
    province: '경기도',
    type: RealEstateAssetType.apartment,
    tier: RealEstateInvestmentTier.prestige,
    availableFrom: DateTime(2011, 7),
    areaSquareMeters: 140,
    imageAsset: 'assets/images/real_estate/04_gyeonggi_newtown_apartment.png',
    priceAnchors: [
      _anchor(
        2011,
        7,
        2300000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '준공 초기 시장평가',
      ),
      _anchor(
        2020,
        1,
        2900000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '동일 면적대 실거래 보간',
      ),
      _anchor(
        2025,
        3,
        4200000000,
        RealEstatePriceEvidence.actualTransaction,
        '국토교통부 실거래 공개자료 2025-03',
      ),
      _anchor(
        2026,
        6,
        4350000000,
        RealEstatePriceEvidence.gameExtension,
        '2025 실거래 이후 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.025,
    annualOperatingCostRate: 0.008,
    sourceNote: '실제 유명 단지·전용면적을 사용합니다.',
    realNamedAsset: true,
  ),
  RealEstateMarketAsset(
    id: 'gwacheon_prugio_summit_121',
    name: '과천푸르지오써밋 121㎡',
    region: '과천시',
    province: '경기도',
    type: RealEstateAssetType.apartment,
    tier: RealEstateInvestmentTier.prestige,
    availableFrom: DateTime(2020, 4),
    areaSquareMeters: 121,
    imageAsset: 'assets/images/real_estate/04_gyeonggi_newtown_apartment.png',
    priceAnchors: [
      _anchor(
        2020,
        4,
        1750000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '준공 초기 시장평가',
      ),
      _anchor(
        2022,
        1,
        2450000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '동일 면적대 실거래 보간',
      ),
      _anchor(
        2025,
        3,
        2870000000,
        RealEstatePriceEvidence.actualTransaction,
        '국토교통부 실거래 공개자료 2025-03',
      ),
      _anchor(
        2026,
        6,
        3050000000,
        RealEstatePriceEvidence.gameExtension,
        '2025 실거래 이후 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.024,
    annualOperatingCostRate: 0.008,
    sourceNote: '실제 유명 단지·전용면적을 사용합니다.',
    realNamedAsset: true,
  ),
  RealEstateMarketAsset(
    id: 'gwanggyo_jungheung_129',
    name: '광교중흥S클래스 129㎡',
    region: '수원시',
    province: '경기도',
    type: RealEstateAssetType.apartment,
    tier: RealEstateInvestmentTier.prestige,
    availableFrom: DateTime(2019, 5),
    areaSquareMeters: 129,
    imageAsset: 'assets/images/real_estate/04_gyeonggi_newtown_apartment.png',
    priceAnchors: [
      _anchor(
        2019,
        5,
        1450000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '준공 초기 시장평가',
      ),
      _anchor(
        2022,
        1,
        2350000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '동일 면적대 실거래 보간',
      ),
      _anchor(
        2025,
        3,
        2890000000,
        RealEstatePriceEvidence.actualTransaction,
        '국토교통부 실거래 공개자료 2025-03',
      ),
      _anchor(
        2026,
        6,
        2960000000,
        RealEstatePriceEvidence.gameExtension,
        '2025 실거래 이후 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.027,
    annualOperatingCostRate: 0.009,
    sourceNote: '실제 유명 단지·전용면적을 사용합니다.',
    realNamedAsset: true,
  ),
  RealEstateMarketAsset(
    id: 'raemian_one_bailey_134',
    name: '래미안원베일리 134㎡',
    region: '서초구',
    province: '서울특별시',
    type: RealEstateAssetType.apartment,
    tier: RealEstateInvestmentTier.prestige,
    availableFrom: DateTime(2023, 8),
    areaSquareMeters: 134,
    imageAsset: 'assets/images/real_estate/05_banpo_hanriver_luxury.png',
    priceAnchors: [
      _anchor(
        2023,
        8,
        7000000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '입주 초기 동일 면적대 시장평가',
      ),
      _anchor(
        2025,
        4,
        9500000000,
        RealEstatePriceEvidence.actualTransaction,
        '국토교통부 실거래 공개자료 2025',
      ),
      _anchor(
        2026,
        6,
        10200000000,
        RealEstatePriceEvidence.gameExtension,
        '2025 실거래 이후 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.018,
    annualOperatingCostRate: 0.007,
    sourceNote: '실제 유명 단지·전용면적을 사용합니다.',
    realNamedAsset: true,
  ),
  RealEstateMarketAsset(
    id: 'hannam_the_hill_243',
    name: '한남더힐 243㎡',
    region: '용산구',
    province: '서울특별시',
    type: RealEstateAssetType.apartment,
    tier: RealEstateInvestmentTier.prestige,
    availableFrom: DateTime(2011, 1),
    areaSquareMeters: 243,
    imageAsset: 'assets/images/real_estate/06_hannam_luxury_residence.png',
    priceAnchors: [
      _anchor(
        2011,
        1,
        4500000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '입주 초기 시장평가',
      ),
      _anchor(
        2021,
        1,
        8000000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '동일 면적대 실거래 보간',
      ),
      _anchor(
        2025,
        4,
        17500000000,
        RealEstatePriceEvidence.actualTransaction,
        '국토교통부 실거래 공개자료 2025',
      ),
      _anchor(
        2026,
        6,
        18200000000,
        RealEstatePriceEvidence.gameExtension,
        '2025 실거래 이후 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.016,
    annualOperatingCostRate: 0.008,
    sourceNote: '거래가 적어 실제 거래점과 시장평가를 함께 표시합니다.',
    realNamedAsset: true,
  ),
  RealEstateMarketAsset(
    id: 'nineone_hannam_244',
    name: '나인원한남 244㎡',
    region: '용산구',
    province: '서울특별시',
    type: RealEstateAssetType.apartment,
    tier: RealEstateInvestmentTier.prestige,
    availableFrom: DateTime(2019, 11),
    areaSquareMeters: 244,
    imageAsset: 'assets/images/real_estate/06_hannam_luxury_residence.png',
    priceAnchors: [
      _anchor(
        2019,
        11,
        4500000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '입주 초기 시장평가',
      ),
      _anchor(
        2022,
        1,
        9000000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '동일 면적대 실거래 보간',
      ),
      _anchor(
        2025,
        2,
        15800000000,
        RealEstatePriceEvidence.actualTransaction,
        '국토교통부 실거래 공개자료 2025-02',
      ),
      _anchor(
        2026,
        6,
        16500000000,
        RealEstatePriceEvidence.gameExtension,
        '2025 실거래 이후 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.016,
    annualOperatingCostRate: 0.008,
    sourceNote: '거래가 적어 실제 거래점과 시장평가를 함께 표시합니다.',
    realNamedAsset: true,
  ),
  RealEstateMarketAsset(
    id: 'acro_seoul_forest_160',
    name: '아크로서울포레스트 160㎡',
    region: '성동구',
    province: '서울특별시',
    type: RealEstateAssetType.apartment,
    tier: RealEstateInvestmentTier.prestige,
    availableFrom: DateTime(2020, 11),
    areaSquareMeters: 160,
    imageAsset: 'assets/images/real_estate/05_banpo_hanriver_luxury.png',
    priceAnchors: [
      _anchor(
        2020,
        11,
        5600000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '입주 초기 시장평가',
      ),
      _anchor(
        2022,
        1,
        8500000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '동일 면적대 실거래 보간',
      ),
      _anchor(
        2025,
        4,
        13500000000,
        RealEstatePriceEvidence.actualTransaction,
        '국토교통부 실거래 공개자료 2025',
      ),
      _anchor(
        2026,
        6,
        14200000000,
        RealEstatePriceEvidence.gameExtension,
        '2025 실거래 이후 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.019,
    annualOperatingCostRate: 0.008,
    sourceNote: '실제 유명 단지·전용면적을 사용합니다.',
    realNamedAsset: true,
  ),
  RealEstateMarketAsset(
    id: 'centropolis_building',
    name: '센트로폴리스',
    region: '종로구',
    province: '서울특별시',
    type: RealEstateAssetType.officeBuilding,
    tier: RealEstateInvestmentTier.building,
    availableFrom: DateTime(2018, 10),
    areaSquareMeters: 141474,
    imageAsset: 'assets/images/real_estate/07_seoul_prime_office.png',
    priceAnchors: [
      _anchor(
        2018,
        10,
        1112200000000,
        RealEstatePriceEvidence.actualBuildingSale,
        '2018년 실제 대형 오피스 거래',
      ),
      _anchor(
        2025,
        1,
        1580000000000,
        RealEstatePriceEvidence.appraisedEstimate,
        'CBD 임대료·자본수익률 기반 시장평가',
      ),
      _anchor(
        2026,
        6,
        1620000000000,
        RealEstatePriceEvidence.gameExtension,
        '상업용 자본수익률로 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.052,
    annualOperatingCostRate: 0.018,
    sourceNote: '실제 매각점 사이를 NOI와 자본수익률로 평가합니다.',
    realNamedAsset: true,
    requiresLegalCompany: true,
  ),
  RealEstateMarketAsset(
    id: 'samsung_seocho_office',
    name: '삼성물산 서초사옥',
    region: '서초구',
    province: '서울특별시',
    type: RealEstateAssetType.officeBuilding,
    tier: RealEstateInvestmentTier.building,
    availableFrom: DateTime(2018, 9),
    areaSquareMeters: 81700,
    imageAsset: 'assets/images/real_estate/07_seoul_prime_office.png',
    priceAnchors: [
      _anchor(
        2018,
        9,
        748400000000,
        RealEstatePriceEvidence.actualBuildingSale,
        '2018년 실제 대형 오피스 거래',
      ),
      _anchor(
        2025,
        1,
        1120000000000,
        RealEstatePriceEvidence.appraisedEstimate,
        'GBD 임대료·자본수익률 기반 시장평가',
      ),
      _anchor(
        2026,
        6,
        1160000000000,
        RealEstatePriceEvidence.gameExtension,
        '상업용 자본수익률로 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.049,
    annualOperatingCostRate: 0.017,
    sourceNote: '실제 매각점 사이를 NOI와 자본수익률로 평가합니다.',
    realNamedAsset: true,
    requiresLegalCompany: true,
  ),
  RealEstateMarketAsset(
    id: 'si_tower_2025',
    name: 'SI타워(인터내셔널타워)',
    region: '강남구',
    province: '서울특별시',
    type: RealEstateAssetType.officeBuilding,
    tier: RealEstateInvestmentTier.building,
    availableFrom: DateTime(2025, 6),
    areaSquareMeters: 65000,
    imageAsset: 'assets/images/real_estate/07_seoul_prime_office.png',
    priceAnchors: [
      _anchor(
        2025,
        6,
        897100000000,
        RealEstatePriceEvidence.actualBuildingSale,
        '2025년 실제 오피스 거래',
      ),
      _anchor(
        2026,
        1,
        918000000000,
        RealEstatePriceEvidence.appraisedEstimate,
        'GBD 임대료·자본수익률 기반 시장평가',
      ),
      _anchor(
        2026,
        6,
        928000000000,
        RealEstatePriceEvidence.gameExtension,
        '상업용 자본수익률로 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.048,
    annualOperatingCostRate: 0.017,
    sourceNote: '2025년 실제 거래가격을 기준점으로 사용합니다.',
    realNamedAsset: true,
    requiresLegalCompany: true,
  ),
  RealEstateMarketAsset(
    id: 'pangyo_techone',
    name: '판교테크원타워',
    region: '성남시',
    province: '경기도',
    type: RealEstateAssetType.officeBuilding,
    tier: RealEstateInvestmentTier.building,
    availableFrom: DateTime(2025, 10),
    areaSquareMeters: 199000,
    imageAsset: 'assets/images/real_estate/08_pangyo_techone_landmark.png',
    priceAnchors: [
      _anchor(
        2025,
        10,
        2000000000000,
        RealEstatePriceEvidence.actualBuildingSale,
        '2025년 실제 오피스 거래 약 2조원',
      ),
      _anchor(
        2026,
        1,
        2020000000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '판교 오피스 임대료·자본수익률 기반 시장평가',
      ),
      _anchor(
        2026,
        6,
        2050000000000,
        RealEstatePriceEvidence.gameExtension,
        '상업용 자본수익률로 게임 종료일까지 연장',
      ),
    ],
    annualGrossYield: 0.046,
    annualOperatingCostRate: 0.016,
    sourceNote: '실제 매각점 이후에는 NOI 방식으로 평가합니다.',
    realNamedAsset: true,
    requiresLegalCompany: true,
  ),
  RealEstateMarketAsset(
    id: 'jamsil_landmark_fund',
    name: '잠실 초대형 랜드마크 지분',
    region: '송파구',
    province: '서울특별시',
    type: RealEstateAssetType.landmarkFund,
    tier: RealEstateInvestmentTier.landmark,
    availableFrom: DateTime(2017, 4),
    areaSquareMeters: 0,
    imageAsset: 'assets/images/real_estate/09_jamsil_supertall_landmark.png',
    priceAnchors: [
      _anchor(
        2017,
        4,
        100000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '건물 전체 실거래가가 아닌 게임용 기관 지분 기준가',
      ),
      _anchor(
        2021,
        1,
        128000000,
        RealEstatePriceEvidence.appraisedEstimate,
        '임대수익·관광수요 기반 지분 평가',
      ),
      _anchor(
        2026,
        6,
        146000000,
        RealEstatePriceEvidence.gameExtension,
        '공식 전체 매각가가 없어 지분 평가로만 연장',
      ),
    ],
    annualGrossYield: 0.043,
    annualOperatingCostRate: 0.014,
    sourceNote: '랜드마크 전체를 실제 거래가로 표시하지 않고 펀드 지분으로 투자합니다.',
    requiresLegalCompany: true,
  ),
];

List<RealEstateMarketAsset> realEstateMarketCatalogAt(DateTime date) =>
    realEstateMarketCatalog
        .where((asset) => !date.isBefore(asset.availableFrom))
        .toList(growable: false);

RealEstateMarketAsset? realEstateMarketAssetById(String id) {
  for (final asset in realEstateMarketCatalog) {
    if (asset.id == id) return asset;
  }
  return null;
}
