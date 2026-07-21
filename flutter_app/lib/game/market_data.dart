import 'dart:convert';

import 'package:flutter/services.dart';

class HistoricalMarketQuote {
  const HistoricalMarketQuote({
    required this.date,
    required this.close,
    required this.isExactDate,
  });

  final String date;
  final double close;
  final bool isExactDate;
}

class HistoricalMarketAsset {
  HistoricalMarketAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.market,
    required this.country,
    required this.sector,
    required this.colorHex,
    required this.currency,
    required Map<String, double> prices,
  }) : _dates = prices.keys.toList()..sort(),
       _prices = prices;

  factory HistoricalMarketAsset.fromJson(Map<String, dynamic> json) {
    final rawPrices = json['prices'] as Map<String, dynamic>? ?? const {};
    return HistoricalMarketAsset(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      market: json['market'] as String,
      country: json['country'] as String? ?? 'KR',
      sector: json['sector'] as String? ?? '기타',
      colorHex: json['color'] as String? ?? '#607D8B',
      currency: json['currency'] as String? ?? 'KRW',
      prices: rawPrices.map(
        (date, value) => MapEntry(date, (value as num).toDouble()),
      ),
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
  final List<String> _dates;
  final Map<String, double> _prices;

  String get code => symbol.split('.').first;
  bool get isDomestic => country == 'KR';
  String? get firstTradeDate => _dates.isEmpty ? null : _dates.first;
  String? get lastTradeDate => _dates.isEmpty ? null : _dates.last;

  HistoricalMarketQuote? quoteAtOrBefore(DateTime date) {
    final key = _dateKey(date);
    final index = _indexAtOrBefore(key);
    if (index < 0) return null;
    final quoteDate = _dates[index];
    return HistoricalMarketQuote(
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

  List<double> closesThrough(DateTime date, {int count = 18}) {
    final index = _indexAtOrBefore(_dateKey(date));
    if (index < 0) return const [];
    final start = (index - count + 1).clamp(0, index);
    return [
      for (var cursor = start; cursor <= index; cursor++)
        _prices[_dates[cursor]]!,
    ];
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

class HistoricalMarketUniverse {
  static const _defaultAssetPath = 'assets/market/market-history.json';
  static Future<HistoricalMarketUniverse>? _cachedDefaultLoad;

  const HistoricalMarketUniverse({
    required this.schemaVersion,
    required this.sourceName,
    required this.assets,
  });

  factory HistoricalMarketUniverse.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as Map<String, dynamic>? ?? const {};
    final rawAssets = json['assets'] as List<dynamic>? ?? const [];
    return HistoricalMarketUniverse(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      sourceName: source['name'] as String? ?? 'unknown',
      assets: rawAssets
          .map(
            (asset) =>
                HistoricalMarketAsset.fromJson(asset as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final int schemaVersion;
  final String sourceName;
  final List<HistoricalMarketAsset> assets;

  static Future<HistoricalMarketUniverse> load({
    String assetPath = _defaultAssetPath,
    bool forceRefresh = false,
  }) {
    if (assetPath != _defaultAssetPath) return _loadFromAsset(assetPath);
    if (forceRefresh) _cachedDefaultLoad = null;
    return _cachedDefaultLoad ??= _loadFromAsset(assetPath).onError((
      error,
      stackTrace,
    ) {
      _cachedDefaultLoad = null;
      Error.throwWithStackTrace(
        error ?? StateError('시장 데이터 로드 실패'),
        stackTrace,
      );
    });
  }

  static Future<HistoricalMarketUniverse> _loadFromAsset(
    String assetPath,
  ) async {
    final raw = await rootBundle.loadString(assetPath);
    return HistoricalMarketUniverse.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
