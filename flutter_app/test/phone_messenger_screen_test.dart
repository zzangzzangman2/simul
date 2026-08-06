import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/phone_ai_service.dart';
import 'package:millennium_capital/game/phone_messenger_state.dart';
import 'package:millennium_capital/main.dart';

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

PhoneAiService _phoneAiService({
  required bool serverConfigured,
  _MemoryPhoneAiCredentialStore? store,
}) => PhoneAiService(
  endpoint: Uri.parse('https://decimal.test/api/gemini/chat'),
  credentialStore: store ?? _MemoryPhoneAiCredentialStore(),
  client: MockClient(
    (request) async => http.Response(
      jsonEncode({'ok': true, 'configured': serverConfigured}),
      200,
      headers: const {'content-type': 'application/json'},
    ),
  ),
);

void main() {
  testWidgets('chat gift picker sends an illustrated Miraon gift card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const engine = GameEngine();
    var state = engine.createNewGame(
      '톡 선물 화면 테스트',
      worldSeed: 'phone-gift-screen',
    );
    state = state.copyWith(cash: state.cash + 20000);
    await tester.pumpWidget(
      MaterialApp(
        home: PhoneMessengerScreen(
          state: state,
          onMarkRead: (contactId) async {
            final result = engine.markPhoneThreadRead(
              state,
              contactId: contactId,
            );
            if (result.success) state = result.state;
            return result;
          },
          onSend: (contactId, text) async =>
              engine.sendPhoneMessage(state, contactId: contactId, text: text),
          onSendGift: (contactId, giftId) async {
            final result = engine.sendPhoneGift(
              state,
              contactId: contactId,
              giftId: giftId,
            );
            if (result.success) state = result.state;
            return result;
          },
          aiService: _phoneAiService(
            serverConfigured: true,
            store: _MemoryPhoneAiCredentialStore()
              ..apiKey = 'test-project-decimal-personal-key-1234567890',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('phone-contact-kim_seoa')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('phone-gift-open-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('phone-gift-product-grid')), findsOneWidget);
    final handCream = find.byKey(
      const Key('phone-gift-product-barrier_hand_cream'),
    );
    await tester.ensureVisible(handCream);
    await tester.pumpAndSettle();
    await tester.tap(handCream);
    await tester.pumpAndSettle();
    final sendButton = tester.widget<FilledButton>(
      find.byKey(const Key('phone-gift-send-button')),
    );
    expect(sendButton.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('phone-gift-send-button')));
    await tester.pumpAndSettle();
    expect(
      state.phoneMessenger.messages.any(
        (message) => message.giftId == 'barrier_hand_cream',
      ),
      isTrue,
    );
    await tester.fling(
      find.byKey(const Key('phone-chat-message-list')),
      const Offset(0, -700),
      1200,
    );
    await tester.pumpAndSettle();

    expect(find.text('MIRAON GIFT'), findsOneWidget);
    expect(find.text('온결 장벽 핸드크림'), findsOneWidget);
    expect(find.textContaining('고마워'), findsWidgets);
  });

  testWidgets('future-talk lists nine contacts and sends typed MBTI replies', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const engine = GameEngine();
    var state = engine.createNewGame('메신저 화면 테스트', worldSeed: 'phone-screen');

    await tester.pumpWidget(
      MaterialApp(
        home: PhoneMessengerScreen(
          state: state,
          onMarkRead: (contactId) async {
            final result = engine.markPhoneThreadRead(
              state,
              contactId: contactId,
            );
            if (result.success) state = result.state;
            return result;
          },
          onSend: (contactId, text) async {
            final result = engine.sendPhoneMessage(
              state,
              contactId: contactId,
              text: text,
            );
            if (result.success) state = result.state;
            return result;
          },
          aiService: _phoneAiService(
            serverConfigured: true,
            store: _MemoryPhoneAiCredentialStore()
              ..apiKey = 'test-project-decimal-personal-key-1234567890',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('phone-messenger-screen')), findsOneWidget);
    expect(find.byKey(const Key('phone-messenger-total-unread')), findsNothing);
    for (final id in <String>[
      'kim_hakjun',
      'kim_seoa',
      'lee_jian',
      'choi_iseo',
      'jung_arin',
      'park_haeun',
      'han_sua',
      'oh_jiwoo',
      'yoon_chaea',
    ]) {
      expect(find.byKey(Key('phone-contact-$id')), findsOneWidget);
    }
    expect(find.text('첫 메시지를 보내보세요'), findsNWidgets(9));

    await tester.tap(find.byKey(const Key('phone-contact-han_sua')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('phone-chat-han_sua')), findsOneWidget);
    expect(find.byKey(const Key('phone-chat-empty-state')), findsOneWidget);
    expect(find.text('첫 메시지를 보내보세요'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('phone-status-time'))).data,
      '08:00',
    );
    expect(find.byKey(const Key('phone-date-2000-01-01')), findsNothing);

    expect(find.byKey(const Key('phone-chat-search-button')), findsNothing);
    expect(find.byKey(const Key('phone-chat-search-input')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('phone-chat-input')),
      '나도 오늘 수업 헷갈려',
    );
    await tester.tap(find.byKey(const Key('phone-chat-send-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('phone-chat-empty-state')), findsNothing);
    expect(find.byKey(const Key('phone-date-2000-01-01')), findsOneWidget);
    expect(find.text('나도 오늘 수업 헷갈려'), findsOneWidget);
    expect(find.textContaining('둘이 틀리면'), findsOneWidget);
    expect(state.phoneMessenger.progressFor('han_sua').totalExchanges, 1);
    expect(state.marketMinute, 8 * 60 + 30);
    expect(
      tester.widget<Text>(find.byKey(const Key('phone-status-time'))).data,
      '08:30',
    );

    await tester.tap(find.byKey(const Key('phone-chat-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('phone-messenger-screen')), findsOneWidget);
    expect(find.textContaining('둘이 틀리면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat becomes read-only at the 22:00 bedtime', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const engine = GameEngine();
    var state = engine
        .createNewGame('메신저 취침 화면', worldSeed: 'phone-screen-bedtime')
        .copyWith(marketMinute: phoneMessengerBedtimeMinute);
    final contact = phoneContactById('kim_seoa')!;

    await tester.pumpWidget(
      MaterialApp(
        home: PhoneChatScreen(
          state: state,
          contact: contact,
          onSend: (contactId, text) async {
            final result = engine.sendPhoneMessage(
              state,
              contactId: contactId,
              text: text,
            );
            if (result.success) state = result.state;
            return result;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('phone-status-time'))).data,
      '22:00',
    );
    expect(find.byKey(const Key('phone-chat-bedtime')), findsOneWidget);
    expect(find.byKey(const Key('phone-chat-input')), findsNothing);
    expect(find.byKey(const Key('phone-chat-send-button')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hub phone indicator opens the saved messenger', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const engine = GameEngine();
    var state = engine
        .createNewGame('허브 휴대폰 테스트', worldSeed: 'phone-hub')
        .copyWith(decisions: const []);

    await tester.pumpWidget(
      MaterialApp(
        home: OfficeScreen(
          state: state,
          engine: engine,
          activeSaveSlot: 1,
          lastSavedAt: null,
          onManualSave: () async {},
          onReturnToTitle: () {},
          onAdvanceDay: () async => state,
          onSetMarketMinute: (minute) async =>
              state.copyWith(marketMinute: minute),
          onSaveMarketNotebook: (_, _) async => state,
          onResolveDecision: (_, _) async {},
          onRequestAcademyHelp: (_) async => state,
          onMarkPhoneThreadRead: (contactId) async {
            final result = engine.markPhoneThreadRead(
              state,
              contactId: contactId,
            );
            if (result.success) state = result.state;
            return result;
          },
          onSendPhoneMessage: (contactId, text) async {
            final result = engine.sendPhoneMessage(
              state,
              contactId: contactId,
              text: text,
            );
            if (result.success) state = result.state;
            return result;
          },
          phoneAiService: _phoneAiService(
            serverConfigured: true,
            store: _MemoryPhoneAiCredentialStore()
              ..apiKey = 'test-project-decimal-personal-key-1234567890',
          ),
          onCompleteWork: (_) async => state,
          onExecuteTrade: (_) async => TradeExecutionResult(
            state: state,
            success: false,
            message: 'test',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('phone-messenger-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('phone-messenger-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('phone-messenger-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first entry explains and registers a missing Gemini key', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const engine = GameEngine();
    final state = engine.createNewGame(
      'AI 등록 화면 테스트',
      worldSeed: 'phone-ai-setup',
    );
    final store = _MemoryPhoneAiCredentialStore();

    await tester.pumpWidget(
      MaterialApp(
        home: PhoneMessengerScreen(
          state: state,
          onMarkRead: (contactId) async =>
              engine.markPhoneThreadRead(state, contactId: contactId),
          onSend: (contactId, text) async =>
              engine.sendPhoneMessage(state, contactId: contactId, text: text),
          aiService: _phoneAiService(serverConfigured: true, store: store),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('phone-ai-registration-dialog')),
      findsOneWidget,
    );
    expect(find.text('더 실감 나는 대화를 켤까요?'), findsOneWidget);
    expect(find.textContaining('12만 가지 이상의 로컬 대화'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('phone-ai-key-input')),
      'test-project-decimal-personal-key-1234567890',
    );
    await tester.tap(find.byKey(const Key('phone-ai-register-button')));
    await tester.pumpAndSettle();

    expect(store.apiKey, 'test-project-decimal-personal-key-1234567890');
    expect(store.promptDismissed, isTrue);
    expect(find.byKey(const Key('phone-ai-registration-dialog')), findsNothing);
    expect(find.byKey(const Key('phone-ai-setup-banner')), findsNothing);
    expect(find.textContaining('안전하게 등록했습니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local dialogue remains available when key setup is skipped', (
    tester,
  ) async {
    const engine = GameEngine();
    final state = engine.createNewGame(
      'AI 건너뛰기 테스트',
      worldSeed: 'phone-ai-skip',
    );
    final store = _MemoryPhoneAiCredentialStore();

    await tester.pumpWidget(
      MaterialApp(
        home: PhoneMessengerScreen(
          state: state,
          onMarkRead: (contactId) async =>
              engine.markPhoneThreadRead(state, contactId: contactId),
          onSend: (contactId, text) async =>
              engine.sendPhoneMessage(state, contactId: contactId, text: text),
          aiService: _phoneAiService(serverConfigured: false, store: store),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('phone-ai-local-only-button')));
    await tester.pumpAndSettle();

    expect(store.apiKey, isNull);
    expect(store.promptDismissed, isTrue);
    expect(find.byKey(const Key('phone-ai-setup-banner')), findsOneWidget);
    expect(find.byKey(const Key('phone-messenger-screen')), findsOneWidget);
  });
}
