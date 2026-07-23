import 'market_clock.dart';

part 'fictional_market.dart';

enum MarketCorporateActionType {
  split,
  dividend,
  rightsIssue,
  materialSpinoff,
  spinoff,
  delisting,
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
    if (type == MarketCorporateActionType.split &&
        (!numerator.isFinite ||
            !denominator.isFinite ||
            numerator <= 0 ||
            denominator <= 0)) {
      throw FormatException('Invalid split ratio for $assetId');
    }
    if (type == MarketCorporateActionType.dividend &&
        (!amount.isFinite || amount <= 0)) {
      throw FormatException('Invalid dividend for $assetId');
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

  double get unitFactor => numerator / denominator;
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
    required Map<String, double> prices,
    this.corporateActions = const <MarketCorporateAction>[],
    this.summary = '',
    this.question = '',
    this.generation = 0,
    this.parentAssetId,
    this.listedOn,
    this.delistedOn,
  }) : _dates = prices.keys.toList()..sort(),
       _prices = prices;

  factory FictionalMarketAsset.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final symbol = json['symbol'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final market = json['market'] as String? ?? '';
    final country = json['country'] as String? ?? 'KR';
    final currency = json['currency'] as String? ?? 'KRW';
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
    return FictionalMarketAsset(
      id: id,
      symbol: symbol,
      name: name,
      market: market,
      country: country,
      sector: json['sector'] as String? ?? '기타',
      colorHex: json['color'] as String? ?? '#607D8B',
      currency: currency,
      prices: prices,
      corporateActions: actions,
      summary: json['summary'] as String? ?? '',
      question: json['question'] as String? ?? '',
      generation: (json['generation'] as num?)?.toInt() ?? 0,
      parentAssetId: json['parentAssetId'] as String?,
      listedOn: json['listedOn'] as String?,
      delistedOn: json['delistedOn'] as String?,
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
  final List<MarketCorporateAction> corporateActions;
  final String summary;
  final String question;
  final int generation;
  final String? parentAssetId;
  final String? listedOn;
  final String? delistedOn;
  final List<String> _dates;
  final Map<String, double> _prices;

  String get code => symbol.split('.').first;
  bool get isDomestic => country == 'KR';
  String? get firstTradeDate => _dates.isEmpty ? null : _dates.first;
  String? get lastTradeDate => _dates.isEmpty ? null : _dates.last;

  FictionalMarketQuote? quoteAtOrBefore(DateTime date) {
    final key = _dateKey(date);
    if (delistedOn != null && key.compareTo(delistedOn!) >= 0) return null;
    final index = _indexAtOrBefore(key);
    if (index < 0) return null;
    final quoteDate = _dates[index];
    return FictionalMarketQuote(
      date: quoteDate,
      close: _prices[quoteDate]!,
      isExactDate: quoteDate == key,
    );
  }

  double? previousCloseBefore(String quoteDate) {
    final index = _dates.indexOf(quoteDate);
    if (index <= 0) return null;
    return _prices[_dates[index - 1]];
  }

  List<MarketPoint> historyThrough(DateTime date, {int count = 4000}) {
    final index = _indexAtOrBefore(_dateKey(date));
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

  int _indexAtOrBefore(String date) {
    var low = 0;
    var high = _dates.length - 1;
    var result = -1;
    while (low <= high) {
      final middle = (low + high) ~/ 2;
      if (_dates[middle].compareTo(date) <= 0) {
        result = middle;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return result;
  }
}

class FictionalMarketUniverse {
  static final Map<String, Future<FictionalMarketUniverse>> _seededLoads = {};

  const FictionalMarketUniverse({
    required this.schemaVersion,
    required this.sourceName,
    required this.assets,
  });

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

  List<MarketCorporateAction> corporateActionsOn(DateTime date) {
    final key = _dateKey(date);
    return [
      for (final asset in assets)
        ...asset.corporateActions.where((action) => action.date == key),
    ]..sort((left, right) {
      final typeOrder =
          (left.type == MarketCorporateActionType.dividend ? 0 : 1).compareTo(
            right.type == MarketCorporateActionType.dividend ? 0 : 1,
          );
      if (typeOrder != 0) return typeOrder;
      return left.id.compareTo(right.id);
    });
  }

  static Future<FictionalMarketUniverse> load({
    String seed = 'simul-preview',
    bool forceRefresh = false,
  }) {
    if (forceRefresh) _seededLoads.remove(seed);
    return _seededLoads.putIfAbsent(
      seed,
      () => Future<FictionalMarketUniverse>.value(
        buildFictionalMarketUniverse(seed),
      ),
    );
  }
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
