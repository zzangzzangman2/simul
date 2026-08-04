import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/phone_ability_hint.dart';
import 'package:millennium_capital/game/phone_ai_service.dart';
import 'package:millennium_capital/game/phone_messenger_state.dart';

class _MemoryPhoneAiCredentialStore implements PhoneAiCredentialStore {
  String? apiKey;
  bool promptDismissed = false;

  @override
  Future<void> deleteApiKey() async => apiKey = null;

  @override
  Future<String?> readApiKey() async => apiKey;

  @override
  Future<bool> readPromptDismissed() async => promptDismissed;

  @override
  Future<bool> writeApiKey(String value) async {
    apiKey = value;
    return true;
  }

  @override
  Future<void> writePromptDismissed(bool value) async {
    promptDismissed = value;
  }
}

void main() {
  const engine = GameEngine();
  final endpoint = Uri.parse('https://decimal.test/api/gemini/chat');

  test('sends compact game context and accepts a Gemini reply', () async {
    final initial = engine.createNewGame('AI 대화 테스트', worldSeed: 'phone-ai');
    final remembered = engine.sendPhoneMessage(
      initial,
      contactId: 'han_sua',
      text: '주말에 문구점에 같이 가기로 약속하자.',
    );
    final state = remembered.state.copyWith(day: remembered.state.day + 1);
    late Map<String, dynamic> requestBody;
    final service = PhoneAiService(
      endpoint: endpoint,
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url, endpoint);
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'ok': true,
              'reply': '오늘은 벌었어도 누적 손실은 남아 있네. 그래도 흐름이 바뀐 건 괜찮은 신호야.',
              'model': 'gemini-3.5-flash-lite',
              'fallbackUsed': false,
            }),
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final reply = await service.createReply(
      state: state,
      contactId: 'han_sua',
      playerText: '오늘은 벌었는데 아직 전체로는 마이너스야.',
      localDraft: '오늘 번 건 맞지만 누적 손실은 아직 남아 있어.',
    );

    expect(reply?.model, 'gemini-3.5-flash-lite');
    expect(reply?.fallbackUsed, isFalse);
    expect(reply?.text, contains('누적 손실'));
    expect(requestBody['contactId'], 'han_sua');
    expect(requestBody['playerMessage'], contains('마이너스'));
    expect(requestBody['localDraft'], contains('누적 손실'));
    expect(requestBody['relationship'], isA<Map>());
    expect(requestBody['investment'], isA<Map>());
    expect(requestBody['situation'], isA<Map>());
    final situation = (requestBody['situation'] as Map).cast<String, dynamic>();
    expect(situation['marketMinute'], state.marketMinute);
    expect(situation['relationshipTimeUsedToday'], isFalse);
    expect(requestBody['recentMessages'], isA<List>());
    expect(requestBody['memories'], isA<List>());
    final memories = (requestBody['memories'] as List).cast<Map>();
    expect(memories, isNotEmpty);
    expect(
      memories.every(
        (memory) =>
            memory['privacyScope'] == phoneDirectMessagePrivateScope &&
            memory['ownerContactId'] == 'han_sua',
      ),
      isTrue,
    );
  });

  test('returns null when the remote quota or server is unavailable', () async {
    final state = engine.createNewGame(
      'AI 폴백 테스트',
      worldSeed: 'phone-ai-fallback',
    );
    final service = PhoneAiService(
      endpoint: endpoint,
      client: MockClient((_) async => http.Response('{}', 429)),
    );

    final reply = await service.createReply(
      state: state,
      contactId: 'kim_seoa',
      playerText: '오늘 기분이 좀 이상해.',
      localDraft: '무슨 일 있었어?',
    );

    expect(reply, isNull);
  });

  test(
    'rejects a remote reply that accepts an impossible weekday date',
    () async {
      final base = engine.createNewGame(
        'AI 일정 검증 테스트',
        worldSeed: 'phone-ai-schedule-guard',
      );
      final state = base.copyWith(
        day: 3,
        marketMinute: 20 * 60,
        relationships: base.relationships.copyWith(
          girls: {
            ...base.relationships.girls,
            'kim_seoa': base.relationships
                .progressFor('kim_seoa')
                .copyWith(affection: 35),
          },
        ),
      );
      final service = PhoneAiService(
        endpoint: endpoint,
        client: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'ok': true,
                'reply': '좋아, 오늘 지금 바로 만나자.',
                'model': 'gemini-3.5-flash-lite',
              }),
            ),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );

      final reply = await service.createReply(
        state: state,
        contactId: 'kim_seoa',
        playerText: '오늘 일 끝났으니 데이트 나갈까?',
        localDraft: '오늘은 평일이라 못 나가. 이번 주말은 어때?',
      );

      expect(reply, isNull);
    },
  );

  test(
    'sends the exact ability-hint envelope and rejects direct AI orders',
    () async {
      final state = engine.createNewGame(
        'AI 능력 힌트 테스트',
        worldSeed: 'phone-ai-ability-hint',
      );
      late Map<String, dynamic> requestBody;
      var directReply = false;
      final service = PhoneAiService(
        endpoint: endpoint,
        client: MockClient((request) async {
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'ok': true,
                'reply': directReply
                    ? '지금 당장 매수해. 무조건 오를 거야.'
                    : '어제 이름이 자주 나온 건 맞아. 실제 수요인지는 더 확인해 보자.',
                'model': 'gemini-3.5-flash-lite',
                'fallbackUsed': false,
              }),
            ),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      const hint = PhoneAbilityHint(
        contactId: 'han_sua',
        ability: '테마와 수요 전조',
        level: PhoneAbilityHintLevel.observation,
        lensLine: '반복되는 수요를 봐.',
        blindSpot: '소문은 매출을 보장하지 않는다.',
        observation: '어제 같은 회사 이름이 여러 자리에서 나왔어.',
        focusAssetName: '한빛통신',
        sourceThroughDate: '2000-01-02',
      );

      final safe = await service.createReply(
        state: state,
        contactId: 'han_sua',
        playerText: '수요 힌트 하나 줘',
        localDraft: hint.localReply,
        abilityHint: hint,
      );
      expect(safe, isNotNull);
      expect(requestBody['playerIntent'], 'investmentAdvice');
      final sentHint = (requestBody['abilityHint'] as Map)
          .cast<String, dynamic>();
      expect(sentHint['contactId'], 'han_sua');
      expect(sentHint['level'], PhoneAbilityHintLevel.observation.name);
      expect(sentHint['ability'], '테마와 수요 전조');
      expect(sentHint['observation'], hint.observation);
      expect(sentHint['sourceThroughDate'], '2000-01-02');

      directReply = true;
      final rejected = await service.createReply(
        state: state,
        contactId: 'han_sua',
        playerText: '수요 힌트 하나 줘',
        localDraft: hint.localReply,
        abilityHint: hint,
      );
      expect(rejected, isNull);
    },
  );

  test(
    'detects missing server setup and sends a device key only as a header',
    () async {
      final state = engine.createNewGame(
        'AI 개인 키 테스트',
        worldSeed: 'phone-ai-personal-key',
      );
      final store = _MemoryPhoneAiCredentialStore();
      String? receivedKey;
      late Map<String, dynamic> requestBody;
      final service = PhoneAiService(
        endpoint: endpoint,
        credentialStore: store,
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode({'ok': true, 'configured': false}),
              200,
            );
          }
          receivedKey = request.headers['x-project-decimal-gemini-key'];
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'ok': true,
                'reply': '그 숫자는 오늘 결과랑 누적 결과를 따로 놓고 다시 보자.',
                'model': 'gemini-3.5-flash-lite',
                'fallbackUsed': false,
              }),
            ),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final before = await service.loadConfiguration();
      expect(before.shouldPrompt, isTrue);

      final registration = await service.registerPersonalApiKey(
        'test-project-decimal-personal-key-1234567890',
      );
      expect(registration.success, isTrue);
      expect(registration.persisted, isTrue);

      final after = await service.loadConfiguration();
      expect(after.enabled, isTrue);
      expect(after.personalKeyConfigured, isTrue);
      expect(after.shouldPrompt, isFalse);

      final reply = await service.createReply(
        state: state,
        contactId: 'kim_hakjun',
        playerText: '오늘 결과가 맞는지 다시 봐 줘.',
        localDraft: '오늘 결과와 누적 결과를 따로 확인하자.',
      );

      expect(reply, isNotNull);
      expect(receivedKey, 'test-project-decimal-personal-key-1234567890');
      expect(requestBody.containsKey('apiKey'), isFalse);
    },
  );

  test('server configuration suppresses the personal key prompt', () async {
    final service = PhoneAiService(
      endpoint: endpoint,
      credentialStore: _MemoryPhoneAiCredentialStore(),
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode({'ok': true, 'configured': true}), 200),
      ),
    );

    final configuration = await service.loadConfiguration();
    expect(configuration.serverReachable, isTrue);
    expect(configuration.serverConfigured, isTrue);
    expect(configuration.enabled, isTrue);
    expect(configuration.shouldPrompt, isFalse);
  });

  test('engine stores an approved remote reply but keeps local scoring', () {
    final state = engine.createNewGame(
      'AI 저장 테스트',
      worldSeed: 'phone-ai-memory',
    );
    final result = engine.sendPhoneMessage(
      state,
      contactId: 'kim_seoa',
      text: '오늘 도와줘서 고마워.',
      replyOverride: '별거 아니야. 그래도 네가 편해졌다니 다행이다.',
    );

    expect(result.success, isTrue);
    expect(result.reply?.text, '별거 아니야. 그래도 네가 편해졌다니 다행이다.');
    expect(
      result.state.phoneMessenger.memoriesFor('kim_seoa').last.replyText,
      result.reply?.text,
    );
    expect(result.relationshipChanged, isTrue);
  });
}
