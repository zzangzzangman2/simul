import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DynamicNewsRequest {
  const DynamicNewsRequest({
    required this.year,
    required this.date,
    required this.marketSummary,
    required this.megaTrend,
  });

  final int year;
  final String date;
  final String marketSummary;
  final String megaTrend;

  Map<String, Object> toJson() => {
    'year': year,
    'date': date,
    'marketSummary': marketSummary,
    'megaTrend': megaTrend,
  };
}

class DynamicNewsArticle {
  const DynamicNewsArticle({
    required this.headline,
    required this.content,
    required this.marketSentiment,
    required this.stockImpactScore,
  });

  final String headline;
  final String content;
  final String marketSentiment;
  final double stockImpactScore;

  factory DynamicNewsArticle.fromJson(Map<String, dynamic> json) {
    final sentiment = json['marketSentiment'] as String? ?? '';
    final score = (json['stockImpactScore'] as num?)?.toDouble();
    if (!const {'POSITIVE', 'NEUTRAL', 'NEGATIVE'}.contains(sentiment) ||
        score == null ||
        score < -30 ||
        score > 50) {
      throw const FormatException('동적 뉴스 응답 범위가 올바르지 않습니다.');
    }
    final headline = (json['headline'] as String? ?? '').trim();
    final content = (json['content'] as String? ?? '').trim();
    if (headline.isEmpty || content.isEmpty) {
      throw const FormatException('동적 뉴스 내용이 비어 있습니다.');
    }
    return DynamicNewsArticle(
      headline: headline,
      content: content,
      marketSentiment: sentiment,
      stockImpactScore: score,
    );
  }
}

class DynamicNewsClient {
  DynamicNewsClient({http.Client? client, Uri? endpoint})
    : _client = client ?? http.Client(),
      _endpointOverride = endpoint;

  static const _configuredBaseUrl = String.fromEnvironment('NEWS_API_BASE_URL');

  final http.Client _client;
  final Uri? _endpointOverride;

  Uri? get _endpoint {
    if (_endpointOverride != null) return _endpointOverride;
    if (_configuredBaseUrl.isNotEmpty) {
      final base = _configuredBaseUrl.endsWith('/')
          ? _configuredBaseUrl
          : '$_configuredBaseUrl/';
      return Uri.parse(base).resolve('api/news');
    }
    if (kIsWeb) return Uri.base.resolve('/api/news');
    return null;
  }

  Future<DynamicNewsArticle?> generate(DynamicNewsRequest request) async {
    final endpoint = _endpoint;
    if (endpoint == null) return null;
    try {
      final response = await _client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 16));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) return null;
      return DynamicNewsArticle.fromJson(json);
    } catch (_) {
      // AI 연결이 없거나 지연돼도 기존 결정론적 신문으로 하루를 진행한다.
      return null;
    }
  }

  void close() => _client.close();
}
