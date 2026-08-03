import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'cohort_investment_state.dart';
import 'game_state.dart';
import 'market_clock.dart';
import 'phone_messenger_state.dart';
import 'relationship_state.dart';

class PhoneAiReply {
  const PhoneAiReply({
    required this.text,
    required this.model,
    required this.fallbackUsed,
  });

  final String text;
  final String model;
  final bool fallbackUsed;
}

class PhoneAiService {
  PhoneAiService({http.Client? client, Uri? endpoint})
    : _client = client ?? http.Client(),
      _endpoint = endpoint ?? _defaultEndpoint();

  final http.Client _client;
  final Uri? _endpoint;

  static Uri? _defaultEndpoint() {
    const configuredBase = String.fromEnvironment('PHONE_AI_API_BASE');
    if (configuredBase.isNotEmpty) {
      return Uri.parse(configuredBase).resolve('/api/gemini/chat');
    }
    final base = Uri.base;
    if (base.scheme == 'http' || base.scheme == 'https') {
      return base.resolve('/api/gemini/chat');
    }
    return null;
  }

  Future<PhoneAiReply?> createReply({
    required GameState state,
    required String contactId,
    required String playerText,
    required String localDraft,
  }) async {
    final endpoint = _endpoint;
    final contact = phoneContactById(contactId);
    if (endpoint == null || contact == null || playerText.trim().isEmpty) {
      return null;
    }

    final report = state.cohortInvestments.reportForDay(state.day);
    final playerRow = report?.resultFor('player');
    final contactRow = report?.resultFor(contactId);
    int rankFor(String investorId) {
      final rows = report?.rankedRows ?? const <CohortDailyInvestmentResult>[];
      for (var index = 0; index < rows.length; index++) {
        if (rows[index].investorId == investorId) return index + 1;
      }
      return 0;
    }

    final relationship = cohortGirlProfileById(contactId) == null
        ? null
        : state.relationships.progressFor(contactId);
    final messages = state.phoneMessenger.messagesFor(contactId);
    final recentMessages = messages.length <= 10
        ? messages
        : messages.sublist(messages.length - 10);
    final memories = state.phoneMessenger.memoriesFor(contactId);
    final recentMemories = memories.length <= 6
        ? memories
        : memories.sublist(memories.length - 6);

    final body = <String, dynamic>{
      'contactId': contactId,
      'playerMessage': playerText.trim(),
      'localDraft': localDraft,
      'date': marketDateKey(state.currentDate),
      'relationship': <String, dynamic>{
        'stage': relationship?.stage.name ?? 'classmate',
        'affection': relationship?.affection ?? 0,
        'trust': relationship?.trust ?? 0,
        'closeness': relationship?.closeness ?? 0,
        'investmentRespect': relationship?.investmentRespect ?? 0,
      },
      'investment': <String, dynamic>{
        'marketClosed': !isMarketTradingDay(state.currentDate),
        'playerDailyProfitLoss': playerRow?.profitLoss ?? 0,
        'playerCumulativeProfitLoss':
            state.cohortInvestments.playerCumulativeProfitLoss,
        'contactDailyProfitLoss': contactRow?.profitLoss ?? 0,
        'playerRank': rankFor('player'),
        'contactRank': rankFor(contactId),
      },
      'recentMessages': <Map<String, dynamic>>[
        for (final message in recentMessages)
          <String, dynamic>{
            'from': message.isFromPlayer ? 'player' : contactId,
            'text': message.text,
          },
      ],
      'memories': <Map<String, dynamic>>[
        for (final memory in recentMemories)
          <String, dynamic>{
            'day': memory.day,
            'player': memory.playerText,
            'reply': memory.replyText,
            'intent': memory.intent,
          },
      ],
    };

    try {
      final response = await _client
          .post(
            endpoint,
            headers: const <String, String>{
              'content-type': 'application/json',
              'accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        var serverMessage = '';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map) {
            serverMessage = (errorBody['message'] as String? ?? '').trim();
          }
        } on FormatException {
          // The local reply remains available when the error body is not JSON.
        }
        if (kDebugMode) {
          debugPrint(
            'Phone AI fallback: HTTP ${response.statusCode}'
            '${serverMessage.isEmpty ? '' : ' · $serverMessage'}',
          );
        }
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final reply = (decoded['reply'] as String? ?? '')
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
          .trim();
      if (decoded['ok'] != true || reply.isEmpty || reply.length > 160) {
        return null;
      }
      return PhoneAiReply(
        text: reply,
        model: decoded['model'] as String? ?? 'gemini-3.5-flash-lite',
        fallbackUsed: decoded['fallbackUsed'] == true,
      );
    } on TimeoutException {
      if (kDebugMode) debugPrint('Phone AI fallback: request timed out');
      return null;
    } on FormatException {
      if (kDebugMode) debugPrint('Phone AI fallback: invalid JSON response');
      return null;
    } catch (error) {
      if (kDebugMode) debugPrint('Phone AI fallback: $error');
      return null;
    }
  }
}
