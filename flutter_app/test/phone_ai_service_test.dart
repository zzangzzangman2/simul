import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/phone_ai_service.dart';

void main() {
  const engine = GameEngine();
  final endpoint = Uri.parse('https://decimal.test/api/gemini/chat');

  test('sends compact game context and accepts a Gemini reply', () async {
    final state = engine.createNewGame('AI 대화 테스트', worldSeed: 'phone-ai');
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
    expect(requestBody['recentMessages'], isA<List>());
    expect(requestBody['memories'], isA<List>());
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
