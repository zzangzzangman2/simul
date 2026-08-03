import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/main.dart';

void main() {
  testWidgets('future-talk lists nine contacts and sends typed MBTI replies', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('phone-messenger-screen')), findsOneWidget);
    expect(
      find.byKey(const Key('phone-messenger-total-unread')),
      findsOneWidget,
    );
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

    await tester.tap(find.byKey(const Key('phone-contact-han_sua')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('phone-chat-han_sua')), findsOneWidget);
    expect(find.textContaining('뇌정지'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('phone-chat-input')),
      '나도 오늘 수업 헷갈려',
    );
    await tester.tap(find.byKey(const Key('phone-chat-send-button')));
    await tester.pumpAndSettle();

    expect(find.text('나도 오늘 수업 헷갈려'), findsOneWidget);
    expect(find.textContaining('둘이 틀리면'), findsOneWidget);
    expect(state.phoneMessenger.progressFor('han_sua').totalExchanges, 1);

    await tester.tap(find.byKey(const Key('phone-chat-back-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('phone-messenger-screen')), findsOneWidget);
    expect(find.textContaining('둘이 틀리면'), findsOneWidget);
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
}
