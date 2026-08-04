import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'cohort_investment_state.dart';
import 'game_state.dart';
import 'market_clock.dart';
import 'phone_ability_hint.dart';
import 'phone_dialogue_composer.dart';
import 'phone_messenger_state.dart';
import 'phone_situation_context.dart';
import 'relationship_state.dart';

const _phoneAiApiKeyStorageKey = 'project_decimal_gemini_api_key_v1';
const _phoneAiPromptDismissedStorageKey =
    'project_decimal_gemini_prompt_dismissed_v1';
const _phoneAiPersonalKeyHeader = 'x-project-decimal-gemini-key';

class PhoneAiConfiguration {
  const PhoneAiConfiguration({
    required this.serverReachable,
    required this.serverConfigured,
    required this.personalKeyConfigured,
    required this.promptDismissed,
  });

  final bool serverReachable;
  final bool serverConfigured;
  final bool personalKeyConfigured;
  final bool promptDismissed;

  bool get enabled => serverConfigured || personalKeyConfigured;

  bool get shouldPrompt => !personalKeyConfigured && !promptDismissed;
}

class PhoneAiKeyRegistrationResult {
  const PhoneAiKeyRegistrationResult({
    required this.success,
    required this.persisted,
    required this.message,
  });

  final bool success;
  final bool persisted;
  final String message;
}

abstract class PhoneAiCredentialStore {
  Future<String?> readApiKey();

  Future<bool> writeApiKey(String value);

  Future<void> deleteApiKey();

  Future<bool> readPromptDismissed();

  Future<void> writePromptDismissed(bool value);
}

class SecurePhoneAiCredentialStore implements PhoneAiCredentialStore {
  SecurePhoneAiCredentialStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(migrateWithBackup: true),
          );

  final FlutterSecureStorage _storage;

  static String? _sessionApiKey;
  static bool _sessionApiKeyLoaded = false;
  static bool? _sessionPromptDismissed;

  @override
  Future<String?> readApiKey() async {
    if (_sessionApiKeyLoaded) return _sessionApiKey;
    try {
      final value = (await _storage.read(
        key: _phoneAiApiKeyStorageKey,
      ))?.trim();
      _sessionApiKey = value == null || value.isEmpty ? null : value;
    } catch (_) {
      _sessionApiKey = null;
    }
    _sessionApiKeyLoaded = true;
    return _sessionApiKey;
  }

  @override
  Future<bool> writeApiKey(String value) async {
    _sessionApiKey = value;
    _sessionApiKeyLoaded = true;
    try {
      await _storage.write(key: _phoneAiApiKeyStorageKey, value: value);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> deleteApiKey() async {
    _sessionApiKey = null;
    _sessionApiKeyLoaded = true;
    try {
      await _storage.delete(key: _phoneAiApiKeyStorageKey);
    } catch (_) {
      // In insecure Web contexts the in-memory key is still cleared.
    }
  }

  @override
  Future<bool> readPromptDismissed() async {
    if (_sessionPromptDismissed != null) return _sessionPromptDismissed!;
    try {
      _sessionPromptDismissed =
          await _storage.read(key: _phoneAiPromptDismissedStorageKey) == '1';
    } catch (_) {
      _sessionPromptDismissed = false;
    }
    return _sessionPromptDismissed!;
  }

  @override
  Future<void> writePromptDismissed(bool value) async {
    _sessionPromptDismissed = value;
    try {
      await _storage.write(
        key: _phoneAiPromptDismissedStorageKey,
        value: value ? '1' : '0',
      );
    } catch (_) {
      // Session state still prevents the prompt from repeating immediately.
    }
  }
}

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
  PhoneAiService({
    http.Client? client,
    Uri? endpoint,
    PhoneAiCredentialStore? credentialStore,
  }) : _client = client ?? http.Client(),
       _endpoint = endpoint ?? _defaultEndpoint(),
       _credentialStore = credentialStore ?? SecurePhoneAiCredentialStore();

  final http.Client _client;
  final Uri? _endpoint;
  final PhoneAiCredentialStore _credentialStore;

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

  Future<PhoneAiConfiguration> loadConfiguration() async {
    final personalKey = await _credentialStore.readApiKey();
    final promptDismissed = await _credentialStore.readPromptDismissed();
    final endpoint = _endpoint;
    if (endpoint == null) {
      return PhoneAiConfiguration(
        serverReachable: false,
        serverConfigured: false,
        personalKeyConfigured: personalKey != null,
        promptDismissed: promptDismissed,
      );
    }

    try {
      final response = await _client
          .get(
            endpoint,
            headers: const <String, String>{'accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const FormatException('configuration status unavailable');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['ok'] != true) {
        throw const FormatException('invalid configuration status');
      }
      return PhoneAiConfiguration(
        serverReachable: true,
        serverConfigured: decoded['configured'] == true,
        personalKeyConfigured: personalKey != null,
        promptDismissed: promptDismissed,
      );
    } catch (_) {
      return PhoneAiConfiguration(
        serverReachable: false,
        serverConfigured: false,
        personalKeyConfigured: personalKey != null,
        promptDismissed: promptDismissed,
      );
    }
  }

  Future<PhoneAiKeyRegistrationResult> registerPersonalApiKey(
    String rawValue,
  ) async {
    final value = rawValue.trim();
    if (value.length < 20 ||
        value.length > 200 ||
        RegExp(r'\s|[\x00-\x1F\x7F]').hasMatch(value)) {
      return const PhoneAiKeyRegistrationResult(
        success: false,
        persisted: false,
        message: '공백 없이 발급받은 Gemini API 키 전체를 입력해 주세요.',
      );
    }
    final persisted = await _credentialStore.writeApiKey(value);
    await _credentialStore.writePromptDismissed(true);
    return PhoneAiKeyRegistrationResult(
      success: true,
      persisted: persisted,
      message: persisted
          ? '이 기기에 Gemini 키를 안전하게 등록했습니다.'
          : '현재 실행에 Gemini 키를 등록했습니다. HTTPS 또는 localhost에서는 다음 실행에도 유지됩니다.',
    );
  }

  Future<void> dismissRegistrationPrompt() =>
      _credentialStore.writePromptDismissed(true);

  Future<void> clearPersonalApiKey() => _credentialStore.deleteApiKey();

  Future<PhoneAiReply?> createReply({
    required GameState state,
    required String contactId,
    required String playerText,
    required String localDraft,
    PhoneAbilityHint? abilityHint,
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
    final recentMemories = state.phoneMessenger.relevantMemoriesFor(
      contactId,
      queryText: playerText,
      currentDay: state.day,
    );
    final situation = buildPhoneSituationContext(
      state,
      contactId: contactId,
      playerText: playerText,
    );

    final body = <String, dynamic>{
      'contactId': contactId,
      'playerMessage': playerText.trim(),
      'playerIntent': classifyPhoneIntent(playerText).name,
      'localDraft': localDraft,
      'date': marketDateKey(state.currentDate),
      'situation': situation.toRequestJson(),
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
            'importance': memory.importance,
            'privacyScope': memory.privacyScope,
            'ownerContactId': memory.contactId,
            'abilityHintLevel': memory.abilityHintLevel,
            'abilityHintObservation': memory.abilityHintObservation,
            'marketMinute': memory.marketMinute,
            'situationSummary': memory.situationSummary,
            'scheduleDecision': memory.scheduleDecision,
          },
      ],
      'abilityHint': abilityHint == null
          ? <String, dynamic>{}
          : <String, dynamic>{
              'contactId': abilityHint.contactId,
              'level': abilityHint.level.name,
              'ability': abilityHint.ability,
              'lensLine': abilityHint.lensLine,
              'observation': abilityHint.observation,
              'verificationQuestion': abilityHint.verificationQuestion,
              'blindSpot': abilityHint.blindSpot,
              'focusAssetName': abilityHint.focusAssetName,
              'sourceThroughDate': abilityHint.sourceThroughDate,
              'mayNameFocusAsset': abilityHint.mayNameFocusAsset,
              'usesResearchCredit': abilityHint.usesResearchCredit,
            },
    };

    try {
      final personalApiKey = await _credentialStore.readApiKey();
      final headers = <String, String>{
        'content-type': 'application/json',
        'accept': 'application/json',
      };
      if (personalApiKey != null) {
        headers[_phoneAiPersonalKeyHeader] = personalApiKey;
      }
      final response = await _client
          .post(endpoint, headers: headers, body: jsonEncode(body))
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
      if (phoneAiReplyViolatesAbilityHintPolicy(
        reply,
        hint: abilityHint,
        enforceInvestmentAdvice:
            classifyPhoneIntent(playerText) ==
            PhonePlayerIntent.investmentAdvice,
      )) {
        if (kDebugMode) {
          debugPrint(
            'Phone AI fallback: direct investment instruction rejected',
          );
        }
        return null;
      }
      if (phoneAiReplyViolatesSituationPolicy(reply, situation: situation)) {
        if (kDebugMode) {
          debugPrint(
            'Phone AI fallback: impossible schedule acceptance rejected',
          );
        }
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
