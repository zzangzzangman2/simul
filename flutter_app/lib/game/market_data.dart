import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show compute, visibleForTesting;

import 'market_clock.dart';
import 'stable_hash.dart';

part 'fictional_market.dart';
part 'market_corpus_calibration.dart';
part 'market_corpus_events.dart';
part 'market_arc_scenarios.dart';
part 'market_era_events.dart';

const marketMaterialNewsHaltMinutes = 5;
const marketCorporateActionAnnouncementTradingDays = 14;
const marketRightsIssuePreferenceFlag = 'marketRightsIssuePreference';
const marketRightsIssueSubscribePreference = 'subscribe';
const marketRightsIssueAutoSellPreference = 'autoSell';
const marketMaterialNewsHaltImpactRate = 0.06;

/// Returns the first day on which an upcoming corporate action is public.
///
/// The deterministic campaign timeline contains future actions internally,
/// but an as-of view exposes them only after this announcement date. This
/// lets the UI show a useful schedule without leaking the full future.
DateTime marketCorporateActionAnnouncementDate(MarketCorporateAction action) {
  var cursor = DateTime.parse(action.date);
  var remaining = marketCorporateActionAnnouncementTradingDays;
  while (remaining > 0) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (isMarketTradingDay(cursor)) remaining -= 1;
  }
  return cursor;
}

bool marketCorporateActionIsAnnouncedBy(
  MarketCorporateAction action,
  DateTime date,
) {
  final through = DateTime(date.year, date.month, date.day);
  return !marketCorporateActionAnnouncementDate(action).isAfter(through);
}

/// A short, deterministic halt for a material negative disclosure.
///
/// The event schedule is already seed/date deterministic, so no extra mutable
/// timer or migration field is needed. The reveal minute and following four
/// minutes reject immediate orders, keep pending orders queued, and stop book
/// prints.
FictionalMarketEvent? marketMaterialNewsTradingHaltAt({
  required String simulationSeed,
  required DateTime date,
  required String assetId,
  required int minute,
}) {
  FictionalMarketEvent? latest;
  for (final event in fictionalMarketEventsForDate(simulationSeed, date)) {
    if (event.companyId != assetId ||
        event.tone != NewsTone.shock ||
        event.impactPct > -marketMaterialNewsHaltImpactRate ||
        minute < event.revealMinute ||
        minute >= event.revealMinute + marketMaterialNewsHaltMinutes) {
      continue;
    }
    if (latest == null || event.revealMinute > latest.revealMinute) {
      latest = event;
    }
  }
  return latest;
}

/// Publicly known financial distress that warrants a management-risk badge.
///
/// Management-risk stocks remain tradable. Only a separate VI or material
/// disclosure halt stops orders.
bool marketFinancialSnapshotIsManagementRisk(
  FictionalFinancialSnapshot? snapshot,
) {
  if (snapshot == null) return false;
  if (snapshot.equity <= 0) return true;
  final weakCashGeneration =
      snapshot.netIncome < 0 && snapshot.operatingCashFlow < 0;
  final leverageBase = math.max(1, snapshot.cash + snapshot.equity);
  return weakCashGeneration && snapshot.debt >= leverageBase * 2;
}

enum MarketCorporateActionType {
  split,
  dividend,
  rightsIssue,
  materialSpinoff,
  spinoff,
  merger,
  shareExchange,
  tenderOffer,
  delisting,
}

enum MarketRightsIssueAllocationMethod { shareholder, thirdParty }

enum FictionalCompanyRelationType {
  supplier,
  customer,
  competitor,
  partner,
  parent,
  subsidiary,
}

class FictionalCompanyRelation {
  const FictionalCompanyRelation({
    required this.relatedAssetId,
    required this.relatedName,
    required this.type,
    required this.strength,
  });

  final String relatedAssetId;
  final String relatedName;
  final FictionalCompanyRelationType type;
  final double strength;

  Map<String, dynamic> toJson() => {
    'relatedAssetId': relatedAssetId,
    'relatedName': relatedName,
    'type': type.name,
    'strength': strength,
  };

  factory FictionalCompanyRelation.fromJson(Map<String, dynamic> json) =>
      FictionalCompanyRelation(
        relatedAssetId: json['relatedAssetId'] as String? ?? '',
        relatedName: json['relatedName'] as String? ?? '',
        type: FictionalCompanyRelationType.values.firstWhere(
          (value) => value.name == json['type'],
          orElse: () => FictionalCompanyRelationType.partner,
        ),
        strength: ((json['strength'] as num?)?.toDouble() ?? 0.2)
            .clamp(0.05, 0.8)
            .toDouble(),
      );
}

class FictionalFinancialSnapshot {
  const FictionalFinancialSnapshot({
    required this.period,
    required this.revenue,
    required this.operatingProfit,
    required this.consensusOperatingProfit,
    required this.netIncome,
    required this.operatingCashFlow,
    required this.cash,
    required this.debt,
    required this.equity,
    required this.sharesOutstanding,
    required this.orderBacklog,
  });

  final String period;
  final int revenue;
  final int operatingProfit;
  final int consensusOperatingProfit;
  final int netIncome;
  final int operatingCashFlow;
  final int cash;
  final int debt;
  final int equity;
  final int sharesOutstanding;
  final int orderBacklog;

  double get operatingMargin =>
      revenue <= 0 ? 0 : operatingProfit / revenue * 100;
  double get roe => equity <= 0 ? 0 : netIncome * 4 / equity * 100;
  double get eps =>
      sharesOutstanding <= 0 ? 0 : netIncome * 4 / sharesOutstanding;
  double get bps => sharesOutstanding <= 0 ? 0 : equity / sharesOutstanding;
  double get earningsSurprisePct => consensusOperatingProfit == 0
      ? 0
      : (operatingProfit - consensusOperatingProfit) /
            consensusOperatingProfit.abs() *
            100;

  Map<String, dynamic> toJson() => {
    'period': period,
    'revenue': revenue,
    'operatingProfit': operatingProfit,
    'consensusOperatingProfit': consensusOperatingProfit,
    'netIncome': netIncome,
    'operatingCashFlow': operatingCashFlow,
    'cash': cash,
    'debt': debt,
    'equity': equity,
    'sharesOutstanding': sharesOutstanding,
    'orderBacklog': orderBacklog,
  };

  factory FictionalFinancialSnapshot.fromJson(Map<String, dynamic> json) =>
      FictionalFinancialSnapshot(
        period: json['period'] as String? ?? '',
        revenue: (json['revenue'] as num?)?.toInt() ?? 0,
        operatingProfit: (json['operatingProfit'] as num?)?.toInt() ?? 0,
        consensusOperatingProfit:
            (json['consensusOperatingProfit'] as num?)?.toInt() ?? 0,
        netIncome: (json['netIncome'] as num?)?.toInt() ?? 0,
        operatingCashFlow: (json['operatingCashFlow'] as num?)?.toInt() ?? 0,
        cash: (json['cash'] as num?)?.toInt() ?? 0,
        debt: (json['debt'] as num?)?.toInt() ?? 0,
        equity: (json['equity'] as num?)?.toInt() ?? 0,
        sharesOutstanding: (json['sharesOutstanding'] as num?)?.toInt() ?? 0,
        orderBacklog: (json['orderBacklog'] as num?)?.toInt() ?? 0,
      );
}

class MarketCorporateAction {
  const MarketCorporateAction({
    required this.id,
    required this.assetId,
    required this.type,
    required this.date,
    required this.numerator,
    required this.denominator,
    required this.amount,
    required this.currency,
    required this.source,
    this.relatedAssetId,
    this.relatedSymbol,
    this.relatedName,
    this.relatedMarket,
    this.referencePrice,
    this.sharesOutstandingBefore,
    this.sharesIssued,
    this.allocationMethod = MarketRightsIssueAllocationMethod.shareholder,
  });

  factory MarketCorporateAction.fromJson(
    String assetId,
    Map<String, dynamic> json,
  ) {
    final type = MarketCorporateActionType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => throw FormatException(
        'Unknown corporate action type: ${json['type']}',
      ),
    );
    final numerator = (json['numerator'] as num?)?.toDouble() ?? 1;
    final denominator = (json['denominator'] as num?)?.toDouble() ?? 1;
    final amount = (json['amount'] as num?)?.toDouble() ?? 0;
    final referencePrice = (json['referencePrice'] as num?)?.toDouble();
    final sharesOutstandingBefore = (json['sharesOutstandingBefore'] as num?)
        ?.toInt();
    final sharesIssued = (json['sharesIssued'] as num?)?.toInt();
    final rawAllocationMethod = json['allocationMethod'] as String?;
    final allocationMethod = rawAllocationMethod == null
        ? MarketRightsIssueAllocationMethod.shareholder
        : MarketRightsIssueAllocationMethod.values.firstWhere(
            (value) => value.name == rawAllocationMethod,
            orElse: () => throw FormatException(
              'Invalid rights issue allocation method for $assetId',
            ),
          );
    if (!numerator.isFinite ||
        !denominator.isFinite ||
        numerator <= 0 ||
        denominator <= 0) {
      throw FormatException('Invalid corporate action ratio for $assetId');
    }
    if (!amount.isFinite) {
      throw FormatException('Invalid corporate action amount for $assetId');
    }
    if (type == MarketCorporateActionType.dividend && amount <= 0) {
      throw FormatException('Invalid dividend for $assetId');
    }
    if (type == MarketCorporateActionType.rightsIssue &&
        ((!numerator.isFinite ||
                !denominator.isFinite ||
                numerator <= 0 ||
                denominator <= 0) ||
            (referencePrice != null &&
                (!referencePrice.isFinite || referencePrice <= 0)) ||
            (referencePrice != null && amount <= 0) ||
            (sharesOutstandingBefore != null && sharesOutstandingBefore <= 0) ||
            (sharesIssued != null && sharesIssued <= 0) ||
            ((sharesOutstandingBefore == null) != (sharesIssued == null)))) {
      throw FormatException('Invalid rights issue terms for $assetId');
    }
    if (type == MarketCorporateActionType.delisting && amount < 0) {
      throw FormatException('Invalid delisting recovery for $assetId');
    }
    final relatedFields = <String?>[
      json['relatedAssetId'] as String?,
      json['relatedSymbol'] as String?,
      json['relatedName'] as String?,
      json['relatedMarket'] as String?,
    ];
    final needsRelatedSecurity =
        type == MarketCorporateActionType.spinoff ||
        type == MarketCorporateActionType.merger ||
        type == MarketCorporateActionType.shareExchange;
    if (needsRelatedSecurity &&
        relatedFields.any((value) => value == null || value.trim().isEmpty)) {
      throw FormatException(
        'Invalid corporate-action destination for $assetId',
      );
    }
    if (needsRelatedSecurity && relatedFields.first == assetId) {
      throw FormatException('Corporate-action destination must differ');
    }
    if (type == MarketCorporateActionType.tenderOffer && amount <= 0) {
      throw FormatException('Invalid tender-offer price for $assetId');
    }
    final id = json['id'] as String? ?? '';
    final date = json['date'] as String? ?? '';
    final currency = json['currency'] as String? ?? 'KRW';
    final source = json['source'] as String? ?? 'unknown';
    if (id.trim().isEmpty || !_isValidDateKey(date)) {
      throw FormatException('Invalid corporate action identity for $assetId');
    }
    if (currency.trim().isEmpty || source.trim().isEmpty) {
      throw FormatException('Invalid corporate action metadata for $assetId');
    }
    return MarketCorporateAction(
      id: id,
      assetId: assetId,
      type: type,
      date: date,
      numerator: numerator,
      denominator: denominator,
      amount: amount,
      currency: currency,
      source: source,
      relatedAssetId: json['relatedAssetId'] as String?,
      relatedSymbol: json['relatedSymbol'] as String?,
      relatedName: json['relatedName'] as String?,
      relatedMarket: json['relatedMarket'] as String?,
      referencePrice: referencePrice,
      sharesOutstandingBefore: sharesOutstandingBefore,
      sharesIssued: sharesIssued,
      allocationMethod: allocationMethod,
    );
  }

  final String id;
  final String assetId;
  final MarketCorporateActionType type;
  final String date;
  final double numerator;
  final double denominator;
  final double amount;
  final String currency;
  final String source;
  final String? relatedAssetId;
  final String? relatedSymbol;
  final String? relatedName;
  final String? relatedMarket;
  final double? referencePrice;
  final int? sharesOutstandingBefore;
  final int? sharesIssued;
  final MarketRightsIssueAllocationMethod allocationMethod;

  double get unitFactor => numerator / denominator;

  /// 유상증자 신주 수 / 증자 전 발행주식수.
  double get rightsIssueRate {
    if (type != MarketCorporateActionType.rightsIssue) return 0;
    final before = sharesOutstandingBefore;
    final issued = sharesIssued;
    if (before != null && before > 0 && issued != null && issued > 0) {
      return issued / before;
    }
    return unitFactor;
  }

  /// 미청약 기존 주주의 상대 지분율 감소분.
  ///
  /// 보유 주식 수를 무상으로 늘리지 않으므로 N / (S + N)만큼 희석된다.
  double get ownershipDilutionRate {
    final issueRate = rightsIssueRate;
    if (!issueRate.isFinite || issueRate <= 0) return 0;
    return issueRate / (1 + issueRate);
  }

  int? get sharesOutstandingAfter {
    final before = sharesOutstandingBefore;
    final issued = sharesIssued;
    if (before == null || issued == null) return null;
    return before + issued;
  }

  double? get rightsIssueGrossProceeds {
    final issued = sharesIssued;
    if (type != MarketCorporateActionType.rightsIssue ||
        issued == null ||
        issued <= 0 ||
        !amount.isFinite ||
        amount <= 0) {
      return null;
    }
    return issued * amount;
  }

  bool get hasTheoreticalExRightsTerms =>
      type == MarketCorporateActionType.rightsIssue &&
      allocationMethod == MarketRightsIssueAllocationMethod.shareholder &&
      rightsIssueRate > 0 &&
      amount.isFinite &&
      amount > 0 &&
      referencePrice != null &&
      referencePrice!.isFinite &&
      referencePrice! > 0;

  double theoreticalExRightsPriceFor(double priorReferencePrice) {
    final issueRate = rightsIssueRate;
    if (type != MarketCorporateActionType.rightsIssue ||
        allocationMethod != MarketRightsIssueAllocationMethod.shareholder ||
        !priorReferencePrice.isFinite ||
        priorReferencePrice <= 0 ||
        !issueRate.isFinite ||
        issueRate <= 0 ||
        !amount.isFinite ||
        amount <= 0) {
      return priorReferencePrice;
    }
    return (priorReferencePrice + issueRate * amount) / (1 + issueRate);
  }

  double? get theoreticalExRightsPrice {
    final reference = referencePrice;
    if (!hasTheoreticalExRightsTerms || reference == null) return null;
    return theoreticalExRightsPriceFor(reference);
  }

  double? get theoreticalExRightsFactor {
    final reference = referencePrice;
    final theoretical = theoreticalExRightsPrice;
    if (reference == null || theoretical == null || reference <= 0) return null;
    return theoretical / reference;
  }

  bool get hasTheoreticalSpinoffTerms =>
      type == MarketCorporateActionType.spinoff &&
      unitFactor.isFinite &&
      unitFactor > 0 &&
      amount.isFinite &&
      amount > 0 &&
      referencePrice != null &&
      referencePrice!.isFinite &&
      referencePrice! > 0;

  double theoreticalExSpinoffPriceFor(double priorReferencePrice) {
    if (!hasTheoreticalSpinoffTerms ||
        !priorReferencePrice.isFinite ||
        priorReferencePrice <= 0) {
      return priorReferencePrice;
    }
    return math.max(1.0, priorReferencePrice - unitFactor * amount);
  }

  double? get theoreticalExSpinoffPrice {
    final reference = referencePrice;
    if (!hasTheoreticalSpinoffTerms || reference == null) return null;
    return theoreticalExSpinoffPriceFor(reference);
  }

  double? get theoreticalExSpinoffFactor {
    final reference = referencePrice;
    final theoretical = theoreticalExSpinoffPrice;
    if (reference == null || theoretical == null || reference <= 0) return null;
    return theoretical / reference;
  }

  MarketCorporateAction copyWith({double? amount, double? referencePrice}) =>
      MarketCorporateAction(
        id: id,
        assetId: assetId,
        type: type,
        date: date,
        numerator: numerator,
        denominator: denominator,
        amount: amount ?? this.amount,
        currency: currency,
        source: source,
        relatedAssetId: relatedAssetId,
        relatedSymbol: relatedSymbol,
        relatedName: relatedName,
        relatedMarket: relatedMarket,
        referencePrice: referencePrice ?? this.referencePrice,
        sharesOutstandingBefore: sharesOutstandingBefore,
        sharesIssued: sharesIssued,
        allocationMethod: allocationMethod,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'assetId': assetId,
    'type': type.name,
    'date': date,
    'numerator': numerator,
    'denominator': denominator,
    'amount': amount,
    'currency': currency,
    'source': source,
    if (relatedAssetId != null) 'relatedAssetId': relatedAssetId,
    if (relatedSymbol != null) 'relatedSymbol': relatedSymbol,
    if (relatedName != null) 'relatedName': relatedName,
    if (relatedMarket != null) 'relatedMarket': relatedMarket,
    if (referencePrice != null) 'referencePrice': referencePrice,
    if (sharesOutstandingBefore != null)
      'sharesOutstandingBefore': sharesOutstandingBefore,
    if (sharesIssued != null) 'sharesIssued': sharesIssued,
    if (type == MarketCorporateActionType.rightsIssue)
      'allocationMethod': allocationMethod.name,
  };
}

class MarketPoint {
  const MarketPoint({required this.date, required this.close});

  final String date;
  final double close;

  DateTime get parsedDate => DateTime.parse(date);
}

class FictionalMarketQuote {
  const FictionalMarketQuote({
    required this.date,
    required this.close,
    required this.isExactDate,
  });

  final String date;
  final double close;
  final bool isExactDate;
}

bool _financialSnapshotIsPublicAt(
  FictionalFinancialSnapshot snapshot,
  String asOfDateKey,
) {
  final periodDate = DateTime.tryParse(snapshot.period);
  final asOfDate = DateTime.tryParse(asOfDateKey);
  if (periodDate == null || asOfDate == null) return false;
  final quarter = (periodDate.month - 1) ~/ 3 + 1;
  final quarterEnd = DateTime(periodDate.year, quarter * 3 + 1, 0);
  return quarterEnd.isBefore(asOfDate);
}

class FictionalMarketAsset {
  FictionalMarketAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.market,
    required this.country,
    required this.sector,
    required this.colorHex,
    required this.currency,
    required this.initialSharesOutstanding,
    required Map<String, double> prices,
    this.appliedEventScales = const <String, double>{},
    this.corporateActions = const <MarketCorporateAction>[],
    this.summary = '',
    this.question = '',
    this.products = const <String>[],
    this.generation = 0,
    this.parentAssetId,
    this.listedOn,
    this.delistedOn,
    this.listingReferencePrice,
    this.financials = const <FictionalFinancialSnapshot>[],
    this.relations = const <FictionalCompanyRelation>[],
  }) : assert(initialSharesOutstanding > 0),
       _dates = prices.keys.toList()..sort(),
       _prices = prices,
       _visibleThroughDateKey = null;

  FictionalMarketAsset._asOf(
    FictionalMarketAsset source, {
    required String throughDateKey,
    required Set<String> knownAssetIds,
    required Set<String> activeAssetIds,
  }) : id = source.id,
       symbol = source.symbol,
       name = source.name,
       market = source.market,
       country = source.country,
       sector = source.sector,
       colorHex = source.colorHex,
       currency = source.currency,
       initialSharesOutstanding = source.initialSharesOutstanding,
       corporateActions = List<MarketCorporateAction>.unmodifiable(
         source.corporateActions.where(
           (action) => marketCorporateActionIsAnnouncedBy(
             action,
             DateTime.parse(throughDateKey),
           ),
         ),
       ),
       summary = source.summary,
       question = source.question,
       products = source.products,
       generation = source.generation,
       parentAssetId = knownAssetIds.contains(source.parentAssetId)
           ? source.parentAssetId
           : null,
       listedOn = source.listedOn,
       delistedOn =
           source.delistedOn != null &&
               source.delistedOn!.compareTo(throughDateKey) <= 0
           ? source.delistedOn
           : null,
       listingReferencePrice = source.listingReferencePrice,
       financials = List<FictionalFinancialSnapshot>.unmodifiable(
         source.financials.where(
           (snapshot) => _financialSnapshotIsPublicAt(snapshot, throughDateKey),
         ),
       ),
       relations = List<FictionalCompanyRelation>.unmodifiable(
         source.relations.where(
           (relation) => activeAssetIds.contains(relation.relatedAssetId),
         ),
       ),
       appliedEventScales = Map<String, double>.unmodifiable({
         for (final entry in source.appliedEventScales.entries)
           if (entry.key.compareTo(throughDateKey) <= 0) entry.key: entry.value,
       }),
       _dates = source._dates,
       _prices = source._prices,
       _visibleThroughDateKey = throughDateKey;

  factory FictionalMarketAsset.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final symbol = json['symbol'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final market = json['market'] as String? ?? '';
    final country = json['country'] as String? ?? 'KR';
    final currency = json['currency'] as String? ?? 'KRW';
    final initialSharesOutstanding = (json['initialSharesOutstanding'] as num?)
        ?.toInt();
    if ([
      id,
      symbol,
      name,
      market,
      country,
      currency,
    ].any((value) => value.trim().isEmpty)) {
      throw const FormatException('Market asset metadata is incomplete');
    }
    if (initialSharesOutstanding == null || initialSharesOutstanding <= 0) {
      throw FormatException(
        'Market asset $id has invalid initial shares outstanding',
      );
    }
    final rawPrices = json['prices'] as Map<String, dynamic>? ?? const {};
    if (rawPrices.isEmpty) {
      throw FormatException('Market asset $id has no prices');
    }
    final prices = <String, double>{};
    for (final entry in rawPrices.entries) {
      final value = (entry.value as num).toDouble();
      if (!_isValidDateKey(entry.key) || !value.isFinite || value <= 0) {
        throw FormatException('Invalid market price for $id on ${entry.key}');
      }
      prices[entry.key] = value;
    }
    final actions = ((json['corporateActions'] as List?) ?? const [])
        .map(
          (item) => MarketCorporateAction.fromJson(
            id,
            (item as Map).cast<String, dynamic>(),
          ),
        )
        .toList(growable: false);
    if (actions.map((action) => action.id).toSet().length != actions.length) {
      throw FormatException('Duplicate corporate action id for $id');
    }
    final listingReferencePrice = (json['listingReferencePrice'] as num?)
        ?.toDouble();
    if (listingReferencePrice != null &&
        (!listingReferencePrice.isFinite || listingReferencePrice <= 0)) {
      throw FormatException('Invalid listing reference price for $id');
    }
    return FictionalMarketAsset(
      id: id,
      symbol: symbol,
      name: name,
      market: market,
      country: country,
      sector: json['sector'] as String? ?? '기타',
      colorHex: json['color'] as String? ?? '#607D8B',
      currency: currency,
      initialSharesOutstanding: initialSharesOutstanding,
      prices: prices,
      appliedEventScales:
          ((json['appliedEventScales'] as Map?) ?? const <Object?, Object?>{})
              .map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num).toDouble()),
              ),
      corporateActions: actions,
      summary: json['summary'] as String? ?? '',
      question: json['question'] as String? ?? '',
      products: ((json['products'] as List?) ?? const <Object?>[])
          .whereType<String>()
          .toList(growable: false),
      generation: (json['generation'] as num?)?.toInt() ?? 0,
      parentAssetId: json['parentAssetId'] as String?,
      listedOn: json['listedOn'] as String?,
      delistedOn: json['delistedOn'] as String?,
      listingReferencePrice: listingReferencePrice,
      financials: ((json['financials'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => FictionalFinancialSnapshot.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
      relations: ((json['relations'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                FictionalCompanyRelation.fromJson(item.cast<String, dynamic>()),
          )
          .where((relation) => relation.relatedAssetId.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String id;
  final String symbol;
  final String name;
  final String market;
  final String country;
  final String sector;
  final String colorHex;
  final String currency;
  final int initialSharesOutstanding;
  final List<MarketCorporateAction> corporateActions;
  final String summary;
  final String question;
  final List<String> products;
  final int generation;
  final String? parentAssetId;
  final String? listedOn;
  final String? delistedOn;
  final double? listingReferencePrice;
  final List<FictionalFinancialSnapshot> financials;
  final List<FictionalCompanyRelation> relations;
  final Map<String, double> appliedEventScales;
  final List<String> _dates;
  final Map<String, double> _prices;
  final String? _visibleThroughDateKey;

  String get code => symbol.split('.').first;
  bool get isDomestic => country == 'KR';
  String? get firstTradeDate {
    if (_dates.isEmpty) return null;
    final first = _dates.first;
    return _isAfterVisibleCutoff(first) ? null : first;
  }

  String? get lastTradeDate {
    if (_dates.isEmpty) return null;
    final index = _indexAtOrBefore(_visibleThroughDateKey ?? _dates.last);
    return index < 0 ? null : _dates[index];
  }

  bool isIpoFirstTradingDay(DateTime date) {
    final firstDate = listedOn ?? firstTradeDate;
    return generation > 0 &&
        parentAssetId == null &&
        listingReferencePrice != null &&
        firstDate == marketDateKey(date);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'symbol': symbol,
    'name': name,
    'market': market,
    'country': country,
    'sector': sector,
    'color': colorHex,
    'currency': currency,
    'initialSharesOutstanding': initialSharesOutstanding,
    'prices': <String, double>{
      for (final date in _dates)
        if (!_isAfterVisibleCutoff(date)) date: _prices[date]!,
    },
    'appliedEventScales': Map<String, double>.from(appliedEventScales),
    'corporateActions': corporateActions
        .map((action) => action.toJson())
        .toList(growable: false),
    'summary': summary,
    'question': question,
    'products': products,
    'generation': generation,
    if (parentAssetId != null) 'parentAssetId': parentAssetId,
    if (listedOn != null) 'listedOn': listedOn,
    if (delistedOn != null) 'delistedOn': delistedOn,
    if (listingReferencePrice != null)
      'listingReferencePrice': listingReferencePrice,
    'financials': financials
        .map((snapshot) => snapshot.toJson())
        .toList(growable: false),
    'relations': relations
        .map((relation) => relation.toJson())
        .toList(growable: false),
  };

  FictionalFinancialSnapshot? financialAtOrBefore(DateTime date) {
    final key = _boundedDateKey(_dateKey(date));
    FictionalFinancialSnapshot? result;
    for (final snapshot in financials) {
      if (snapshot.period.compareTo(key) > 0) break;
      result = snapshot;
    }
    return result;
  }

  /// 분기 재무 공시 사이에 발생한 유상증자까지 반영한 당일 발행주식수.
  int? sharesOutstandingAtOrBefore(DateTime date) {
    final key = _boundedDateKey(_dateKey(date));
    final firstDate = listedOn ?? firstTradeDate;
    if (firstDate == null || key.compareTo(firstDate) < 0) return null;
    if (delistedOn != null && key.compareTo(delistedOn!) >= 0) return null;
    var outstanding = initialSharesOutstanding;
    final shareActions =
        corporateActions
            .where(
              (action) =>
                  action.date.compareTo(key) <= 0 &&
                  (action.type == MarketCorporateActionType.rightsIssue ||
                      action.type == MarketCorporateActionType.split),
            )
            .toList(growable: false)
          ..sort((left, right) {
            final dateOrder = left.date.compareTo(right.date);
            if (dateOrder != 0) return dateOrder;
            final typeOrder = marketCorporateActionOrder(
              left.type,
            ).compareTo(marketCorporateActionOrder(right.type));
            if (typeOrder != 0) return typeOrder;
            return left.id.compareTo(right.id);
          });
    for (final action in shareActions) {
      if (action.type == MarketCorporateActionType.rightsIssue) {
        final issued = action.sharesIssued;
        if (issued != null && issued > 0) {
          outstanding += issued;
        } else if (action.rightsIssueRate.isFinite &&
            action.rightsIssueRate > 0) {
          outstanding += (outstanding * action.rightsIssueRate).round();
        }
      } else if (action.type == MarketCorporateActionType.split &&
          action.unitFactor.isFinite &&
          action.unitFactor > 0) {
        outstanding = math.max(1, (outstanding * action.unitFactor).round());
      }
    }
    return outstanding;
  }

  FictionalMarketQuote? quoteAtOrBefore(DateTime date) {
    final requestedKey = _dateKey(date);
    final key = _boundedDateKey(requestedKey);
    if (delistedOn != null && key.compareTo(delistedOn!) >= 0) return null;
    final index = _indexAtOrBefore(key);
    if (index < 0) return null;
    final quoteDate = _dates[index];
    return FictionalMarketQuote(
      date: quoteDate,
      close: _prices[quoteDate]!,
      isExactDate: quoteDate == requestedKey && requestedKey == key,
    );
  }

  double? previousCloseBefore(String quoteDate) {
    if (_isAfterVisibleCutoff(quoteDate)) return null;
    final index = _dates.indexOf(quoteDate);
    if (index <= 0) return null;
    return _prices[_dates[index - 1]];
  }

  /// 직전 종가가 없는 첫 거래일에는 당일 종가가 아니라 공모·분할 기준가를 쓴다.
  double unadjustedReferenceCloseFor(String quoteDate) {
    if (_isAfterVisibleCutoff(quoteDate)) return 0;
    return previousCloseBefore(quoteDate) ??
        listingReferencePrice ??
        _prices[quoteDate] ??
        0;
  }

  List<MarketPoint> historyThrough(DateTime date, {int count = 4000}) {
    final index = _indexAtOrBefore(_boundedDateKey(_dateKey(date)));
    if (index < 0 || count <= 0) return const <MarketPoint>[];
    final start = (index - count + 1).clamp(0, index);
    return <MarketPoint>[
      for (var cursor = start; cursor <= index; cursor++)
        MarketPoint(date: _dates[cursor], close: _prices[_dates[cursor]]!),
    ];
  }

  List<double> closesThrough(DateTime date, {int count = 18}) {
    return historyThrough(
      date,
      count: count,
    ).map((point) => point.close).toList(growable: false);
  }

  double appliedEventScaleOn(DateTime date) {
    final key = _dateKey(date);
    if (_isAfterVisibleCutoff(key)) return 1;
    return appliedEventScales[key] ?? 1;
  }

  List<MarketCorporateAction> corporateActionsOn(DateTime date) {
    final key = _dateKey(date);
    final actions = corporateActions
        .where((action) => action.date == key)
        .toList(growable: false);
    return actions..sort((left, right) {
      final typeOrder = marketCorporateActionOrder(
        left.type,
      ).compareTo(marketCorporateActionOrder(right.type));
      if (typeOrder != 0) return typeOrder;
      return left.id.compareTo(right.id);
    });
  }

  List<MarketCorporateAction> announcedCorporateActionsFrom(DateTime date) {
    final key = _dateKey(date);
    final actions = corporateActions
        .where((action) => action.date.compareTo(key) >= 0)
        .toList(growable: false);
    return actions..sort((left, right) {
      final dateOrder = left.date.compareTo(right.date);
      if (dateOrder != 0) return dateOrder;
      final typeOrder = marketCorporateActionOrder(
        left.type,
      ).compareTo(marketCorporateActionOrder(right.type));
      if (typeOrder != 0) return typeOrder;
      return left.id.compareTo(right.id);
    });
  }

  /// 현금배당·유상증자·주식분할이 겹치는 날의 가격제한폭/장중 경로 기준가.
  ///
  /// 직전 종가 자체는 보유자의 손익 비교를 위해 보존하고, 거래소가 당일
  /// 사용하는 기계적 조정 기준가만 별도로 계산한다.
  double marketReferenceCloseOn(
    DateTime date, {
    required double previousClose,
  }) {
    return _marketReferenceCloseForActions(
      previousClose: previousClose,
      actions: corporateActionsOn(date),
      currency: currency,
      market: market,
    );
  }

  int _indexAtOrBefore(String date) {
    final boundedDate = _boundedDateKey(date);
    var low = 0;
    var high = _dates.length - 1;
    var result = -1;
    while (low <= high) {
      final middle = (low + high) ~/ 2;
      if (_dates[middle].compareTo(boundedDate) <= 0) {
        result = middle;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return result;
  }

  String _boundedDateKey(String requestedDateKey) {
    final cutoff = _visibleThroughDateKey;
    if (cutoff != null && requestedDateKey.compareTo(cutoff) > 0) {
      return cutoff;
    }
    return requestedDateKey;
  }

  bool _isAfterVisibleCutoff(String dateKey) {
    final cutoff = _visibleThroughDateKey;
    return cutoff != null && dateKey.compareTo(cutoff) > 0;
  }
}

class FictionalMarketUniverse {
  static const int _maximumCachedTimelines = 2;
  static const int _maximumCachedViews = 12;
  static const int _maximumCampaignPreloadIntents = 8;
  static const String _viewKeySeparator = '\u0000';
  static final LinkedHashMap<String, Future<FictionalMarketUniverse>>
  _timelineLoads = LinkedHashMap();
  static final LinkedHashMap<String, Future<FictionalMarketUniverse>>
  _asOfLoads = LinkedHashMap();
  static final LinkedHashSet<String> _campaignPreloadSeeds = LinkedHashSet();
  static final Map<String, int> _timelineBuildCounts = <String, int>{};

  const FictionalMarketUniverse({
    required this.schemaVersion,
    required this.sourceName,
    required this.assets,
  }) : _visibleThroughDateKey = null,
       _timelineThroughDateKey = null,
       _timeline = null;

  FictionalMarketUniverse._timeline(
    FictionalMarketUniverse source, {
    required String throughDateKey,
  }) : schemaVersion = source.schemaVersion,
       sourceName = source.sourceName,
       assets = source.assets,
       _visibleThroughDateKey = null,
       _timelineThroughDateKey = throughDateKey,
       _timeline = null;

  FictionalMarketUniverse._asOf(
    FictionalMarketUniverse timeline, {
    required String throughDateKey,
    required List<FictionalMarketAsset> assets,
  }) : schemaVersion = timeline.schemaVersion,
       sourceName = timeline.sourceName,
       assets = List<FictionalMarketAsset>.unmodifiable(assets),
       _visibleThroughDateKey = throughDateKey,
       _timelineThroughDateKey = timeline._timelineThroughDateKey,
       _timeline = timeline;

  factory FictionalMarketUniverse.fromJson(Map<String, dynamic> json) {
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 0;
    if (schemaVersion < 4) {
      throw FormatException('Unsupported market data schema: $schemaVersion');
    }
    final source = json['source'] as Map<String, dynamic>? ?? const {};
    final sourceName = source['name'] as String? ?? 'unknown';
    if (sourceName.trim().isEmpty) {
      throw const FormatException('Market data source is missing');
    }
    final rawAssets = json['assets'] as List<dynamic>? ?? const [];
    final assets = rawAssets
        .map(
          (asset) =>
              FictionalMarketAsset.fromJson(asset as Map<String, dynamic>),
        )
        .toList(growable: false);
    if (assets.isEmpty) throw const FormatException('Market assets are empty');
    if (assets.map((asset) => asset.id).toSet().length != assets.length) {
      throw const FormatException('Duplicate market asset id');
    }
    if (assets.map((asset) => asset.symbol).toSet().length != assets.length) {
      throw const FormatException('Duplicate market asset symbol');
    }
    final actionIds = [
      for (final asset in assets)
        for (final action in asset.corporateActions) action.id,
    ];
    if (actionIds.toSet().length != actionIds.length) {
      throw const FormatException('Duplicate corporate action id');
    }
    return FictionalMarketUniverse(
      schemaVersion: schemaVersion,
      sourceName: sourceName,
      assets: assets,
    );
  }

  final int schemaVersion;
  final String sourceName;
  final List<FictionalMarketAsset> assets;
  final String? _visibleThroughDateKey;
  final String? _timelineThroughDateKey;
  final FictionalMarketUniverse? _timeline;

  /// Returns a read-only world view that cannot reveal anything after [date].
  ///
  /// The expensive price timeline remains shared with the root universe. Every
  /// public asset lookup is bounded by the view date, while metadata that would
  /// reveal a future listing, delisting, relationship, action, or financial
  /// result is filtered out.
  FictionalMarketUniverse asOf(DateTime date) {
    var throughDateKey = _dateKey(DateTime(date.year, date.month, date.day));
    final timeline = _timeline ?? this;
    final timelineCutoff = timeline._timelineThroughDateKey;
    if (timelineCutoff != null &&
        throughDateKey.compareTo(timelineCutoff) > 0) {
      throughDateKey = timelineCutoff;
    }
    final currentCutoff = _visibleThroughDateKey;
    if (currentCutoff != null && throughDateKey.compareTo(currentCutoff) > 0) {
      throughDateKey = currentCutoff;
    }
    if (throughDateKey == currentCutoff) return this;

    final knownAssets = timeline.assets
        .where(
          (asset) =>
              asset.firstTradeDate != null &&
              asset.firstTradeDate!.compareTo(throughDateKey) <= 0,
        )
        .toList(growable: false);
    final knownAssetIds = knownAssets.map((asset) => asset.id).toSet();
    final activeAssetIds = knownAssets
        .where(
          (asset) =>
              asset.delistedOn == null ||
              throughDateKey.compareTo(asset.delistedOn!) < 0,
        )
        .map((asset) => asset.id)
        .toSet();
    return FictionalMarketUniverse._asOf(
      timeline,
      throughDateKey: throughDateKey,
      assets: [
        for (final asset in knownAssets)
          FictionalMarketAsset._asOf(
            asset,
            throughDateKey: throughDateKey,
            knownAssetIds: knownAssetIds,
            activeAssetIds: activeAssetIds,
          ),
      ],
    );
  }

  List<MarketCorporateAction> corporateActionsOn(DateTime date) {
    final key = _dateKey(date);
    return [
      for (final asset in assets)
        ...asset.corporateActions.where((action) => action.date == key),
    ]..sort((left, right) {
      final typeOrder = marketCorporateActionOrder(
        left.type,
      ).compareTo(marketCorporateActionOrder(right.type));
      if (typeOrder != 0) return typeOrder;
      return left.id.compareTo(right.id);
    });
  }

  static Future<FictionalMarketUniverse> load({
    String seed = 'simul-preview',
    DateTime? throughDate,
    bool forceRefresh = false,
  }) {
    final normalizedThroughDate = throughDate == null
        ? null
        : DateTime(throughDate.year, throughDate.month, throughDate.day);
    final shouldKeepCampaignHorizon =
        normalizedThroughDate == null || _campaignPreloadSeeds.contains(seed);
    if (forceRefresh) _invalidateSeed(seed);
    final timeline = _loadTimeline(
      seed,
      shouldKeepCampaignHorizon
          ? DateTime(fictionalCampaignEndYear, 12, 31)
          : _timelineHorizonFor(normalizedThroughDate),
    );
    if (normalizedThroughDate == null) return timeline;

    final cacheKey = _viewCacheKey(seed, _dateKey(normalizedThroughDate));
    final cached = _asOfLoads.remove(cacheKey);
    if (cached != null) {
      _asOfLoads[cacheKey] = cached;
      return cached;
    }

    late final Future<FictionalMarketUniverse> pending;
    pending = () async {
      try {
        // 첫 프레임을 먼저 그리고, 네이티브에서는 별도 isolate에서
        // 장기 월드를 생성한다. Web에서도 compute의 호환 경로를 사용한다.
        await Future<void>.delayed(Duration.zero);
        if (!normalizedThroughDate.isBefore(
          DateTime(fictionalCampaignEndYear, 12, 31),
        )) {
          // 전체 27년 월드는 isolate 간 대형 객체 복사 비용이 더 크므로
          // 검증 도구에서는 현재 isolate에서 한 번만 생성한다.
          return (await timeline).asOf(normalizedThroughDate);
        }
        return (await timeline).asOf(normalizedThroughDate);
      } catch (_) {
        if (identical(_asOfLoads[cacheKey], pending)) {
          _asOfLoads.remove(cacheKey);
        }
        rethrow;
      }
    }();
    _asOfLoads[cacheKey] = pending;
    while (_asOfLoads.length > _maximumCachedViews) {
      _asOfLoads.remove(_asOfLoads.keys.first);
    }
    return pending;
  }

  /// Builds the complete campaign timeline once without exposing its future
  /// data to callers.
  ///
  /// Screens must continue to call [load] with `throughDate`. Once this
  /// prewarm completes, those dated views reuse the full internal timeline
  /// and remain bounded by [asOf].
  static Future<void> prewarmCampaign({
    required String seed,
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) _invalidateSeed(seed);
    await _loadTimeline(seed, DateTime(fictionalCampaignEndYear, 12, 31));
    _rememberCampaignPreload(seed);
  }

  /// Whether a complete campaign timeline is currently resident or building.
  @visibleForTesting
  static bool isCampaignTimelineCached(String seed) =>
      _timelineLoads.containsKey(
        '$seed$_viewKeySeparator'
        '${_dateKey(DateTime(fictionalCampaignEndYear, 12, 31))}',
      );

  @visibleForTesting
  static int debugTimelineBuildCount(String seed) =>
      _timelineBuildCounts[seed] ?? 0;

  static Future<FictionalMarketUniverse> _loadTimeline(
    String seed,
    DateTime requestedHorizon,
  ) {
    final requestedHorizonKey = _dateKey(requestedHorizon);
    final prefix = '$seed$_viewKeySeparator';
    String? selectedCacheKey;
    String? selectedHorizonKey;
    for (final cacheKey in _timelineLoads.keys) {
      if (!cacheKey.startsWith(prefix)) continue;
      final cachedHorizonKey = cacheKey.substring(prefix.length);
      if (cachedHorizonKey.compareTo(requestedHorizonKey) < 0) continue;
      if (selectedHorizonKey == null ||
          cachedHorizonKey.compareTo(selectedHorizonKey) < 0) {
        selectedCacheKey = cacheKey;
        selectedHorizonKey = cachedHorizonKey;
      }
    }
    if (selectedCacheKey != null) {
      final cached = _timelineLoads.remove(selectedCacheKey)!;
      _timelineLoads[selectedCacheKey] = cached;
      return cached;
    }

    final dominatedKeys = _timelineLoads.keys
        .where(
          (cacheKey) =>
              cacheKey.startsWith(prefix) &&
              cacheKey.substring(prefix.length).compareTo(requestedHorizonKey) <
                  0,
        )
        .toList(growable: false);
    for (final dominatedKey in dominatedKeys) {
      _timelineLoads.remove(dominatedKey);
    }
    if (dominatedKeys.isNotEmpty) _removeViewsForSeed(seed);

    final cacheKey = '$prefix$requestedHorizonKey';
    _timelineBuildCounts[seed] = (_timelineBuildCounts[seed] ?? 0) + 1;
    late final Future<FictionalMarketUniverse> pending;
    pending = () async {
      try {
        // Generate only to the end of the requested year. A later cached
        // horizon can safely serve an earlier request through an as-of view.
        await Future<void>.delayed(Duration.zero);
        final generated = await compute(
          _buildFictionalMarketUniverseInBackground,
          <String, Object?>{
            'seed': seed,
            'throughDateMillis': requestedHorizon.millisecondsSinceEpoch,
          },
          debugLabel: 'fictional-market-$seed-$requestedHorizonKey',
        );
        final generatedTimeline = generated._timeline ?? generated;
        return FictionalMarketUniverse._timeline(
          generatedTimeline,
          throughDateKey: requestedHorizonKey,
        );
      } catch (_) {
        if (identical(_timelineLoads[cacheKey], pending)) {
          _timelineLoads.remove(cacheKey);
          _removeViewsForSeed(seed);
        }
        rethrow;
      }
    }();
    _timelineLoads[cacheKey] = pending;
    while (_timelineLoads.length > _maximumCachedTimelines) {
      final evictedCacheKey = _timelineLoads.keys.first;
      _timelineLoads.remove(evictedCacheKey);
      _removeViewsForSeed(_seedFromTimelineCacheKey(evictedCacheKey));
    }
    return pending;
  }

  static DateTime _timelineHorizonFor(DateTime? requestedDate) {
    final campaignEnd = DateTime(fictionalCampaignEndYear, 12, 31);
    if (requestedDate == null || !requestedDate.isBefore(campaignEnd)) {
      return campaignEnd;
    }
    final horizonYear = requestedDate.year < fictionalCampaignStartYear
        ? fictionalCampaignStartYear
        : requestedDate.year;
    return DateTime(horizonYear, 12, 31);
  }

  static String _seedFromTimelineCacheKey(String cacheKey) {
    final separatorIndex = cacheKey.indexOf(_viewKeySeparator);
    return separatorIndex < 0
        ? cacheKey
        : cacheKey.substring(0, separatorIndex);
  }

  static String _viewCacheKey(String seed, String throughDateKey) =>
      '$seed$_viewKeySeparator$throughDateKey';

  static void _rememberCampaignPreload(String seed) {
    _campaignPreloadSeeds.remove(seed);
    _campaignPreloadSeeds.add(seed);
    while (_campaignPreloadSeeds.length > _maximumCampaignPreloadIntents) {
      _campaignPreloadSeeds.remove(_campaignPreloadSeeds.first);
    }
  }

  static void _invalidateSeed(String seed) {
    final prefix = '$seed$_viewKeySeparator';
    _timelineLoads.removeWhere((key, _) => key.startsWith(prefix));
    _removeViewsForSeed(seed);
  }

  static void _removeViewsForSeed(String seed) {
    final prefix = '$seed$_viewKeySeparator';
    _asOfLoads.removeWhere((key, _) => key.startsWith(prefix));
  }
}

FictionalMarketUniverse _buildFictionalMarketUniverseInBackground(
  Map<String, Object?> request,
) {
  final millis = request['throughDateMillis'] as int?;
  return buildFictionalMarketUniverse(
    request['seed']! as String,
    throughDate: millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis),
  );
}

bool _isValidDateKey(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parsed = DateTime.tryParse(value);
  return parsed != null && _dateKey(parsed) == value;
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

int marketCorporateActionOrder(MarketCorporateActionType type) =>
    switch (type) {
      MarketCorporateActionType.dividend => 0,
      MarketCorporateActionType.rightsIssue => 1,
      MarketCorporateActionType.split => 2,
      MarketCorporateActionType.spinoff => 3,
      MarketCorporateActionType.materialSpinoff => 4,
      MarketCorporateActionType.merger => 5,
      MarketCorporateActionType.shareExchange => 6,
      MarketCorporateActionType.tenderOffer => 7,
      MarketCorporateActionType.delisting => 8,
    };

double _marketReferenceCloseForActions({
  required double previousClose,
  required Iterable<MarketCorporateAction> actions,
  required String currency,
  required String market,
}) {
  if (!previousClose.isFinite || previousClose <= 0) return previousClose;
  final orderedActions = actions.toList(growable: false)
    ..sort((left, right) {
      final typeOrder = marketCorporateActionOrder(
        left.type,
      ).compareTo(marketCorporateActionOrder(right.type));
      if (typeOrder != 0) return typeOrder;
      return left.id.compareTo(right.id);
    });
  var reference = previousClose;
  for (final action in orderedActions) {
    switch (action.type) {
      case MarketCorporateActionType.dividend:
        if (action.currency == currency &&
            action.amount.isFinite &&
            action.amount > 0) {
          reference = math.max(1.0, reference - action.amount);
        }
        break;
      case MarketCorporateActionType.rightsIssue:
        if (action.hasTheoreticalExRightsTerms) {
          reference = action.theoreticalExRightsPriceFor(reference);
        }
        break;
      case MarketCorporateActionType.split:
        if (action.unitFactor.isFinite && action.unitFactor > 0) {
          reference /= action.unitFactor;
        }
        break;
      case MarketCorporateActionType.spinoff:
        if (action.hasTheoreticalSpinoffTerms) {
          reference = action.theoreticalExSpinoffPriceFor(reference);
        }
        break;
      case MarketCorporateActionType.materialSpinoff:
      case MarketCorporateActionType.merger:
      case MarketCorporateActionType.shareExchange:
      case MarketCorporateActionType.tenderOffer:
      case MarketCorporateActionType.delisting:
        break;
    }
  }
  return marketSnapPrice(
    // The 120-won floor belongs only to baseline quote generation. Applying it
    // again here would give holders free dividend, rights, or spinoff value
    // whenever the economically adjusted reference falls below that floor.
    reference.clamp(1.0, 2500000.0).toDouble(),
    market: market,
  );
}
