import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_persistence.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const engine = GameEngine();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Map<String, dynamic> v8Json(GameState state) => {
    ...state.toJson(),
    'version': 8,
  };

  test('a pristine zero-cash v8 start receives the new capital once', () async {
    final oldStart = engine.createNewGame('기존 테스트 회사', initialCash: 0);
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: jsonEncode(v8Json(oldStart)),
    });
    final preferences = await SharedPreferences.getInstance();
    final persistence = GamePersistence(preferences: preferences);

    final migrated = await persistence.load();

    expect(migrated, isNotNull);
    expect(migrated!.cash, initialCompanyCash);
    expect(migrated.version, GameState.schemaVersion);
    final stored =
        jsonDecode(preferences.getString(GamePersistence.saveKey)!)
            as Map<String, dynamic>;
    expect(stored['version'], GameState.schemaVersion);
    expect(stored['cash'], initialCompanyCash);

    await persistence.save(migrated.copyWith(cash: 0));
    final loadedAgain = await persistence.load();
    expect(
      loadedAgain!.cash,
      0,
      reason: 'v9 saves must not receive capital again',
    );
  });

  test(
    'non-financial v8 progress gets capital without resetting progress',
    () async {
      final progressed = engine
          .createNewGame('진행한 테스트 회사', initialCash: 0)
          .copyWith(day: 4, marketMinute: 9 * 60, decisions: const []);
      SharedPreferences.setMockInitialValues({
        GamePersistence.saveKey: jsonEncode(v8Json(progressed)),
      });
      final preferences = await SharedPreferences.getInstance();
      final persistence = GamePersistence(preferences: preferences);

      final migrated = await persistence.load();

      expect(migrated, isNotNull);
      expect(migrated!.cash, initialCompanyCash);
      expect(migrated.day, 4);
      expect(migrated.marketMinute, 9 * 60);
      expect(migrated.decisions, isEmpty);
    },
  );

  test(
    'a financially progressed zero-cash v8 save preserves its balance',
    () async {
      final progressed = engine
          .createNewGame('실제 진행한 테스트 회사', initialCash: 0)
          .copyWith(
            ledger: const [
              LedgerEntry(
                id: 'existing-expense',
                day: 1,
                amount: -1000,
                account: 'cash',
                counterAccount: 'expense',
                description: '기존 지출 기록',
                sourceId: 'existing-action',
              ),
            ],
          );
      SharedPreferences.setMockInitialValues({
        GamePersistence.saveKey: jsonEncode(v8Json(progressed)),
      });
      final preferences = await SharedPreferences.getInstance();
      final persistence = GamePersistence(preferences: preferences);

      final migrated = await persistence.load();

      expect(migrated, isNotNull);
      expect(migrated!.cash, 0);
      expect(migrated.ledger.single.id, 'existing-expense');
      final stored =
          jsonDecode(preferences.getString(GamePersistence.saveKey)!)
              as Map<String, dynamic>;
      expect(stored['version'], GameState.schemaVersion);
      expect(stored['cash'], 0);
    },
  );

  test('SharedPreferences false is surfaced as a save failure', () async {
    final preferences = await SharedPreferences.getInstance();
    var attempts = 0;
    final persistence = GamePersistence(
      preferences: preferences,
      saveString: (key, value) async {
        attempts += 1;
        return false;
      },
    );

    await expectLater(
      persistence.save(engine.createNewGame('저장 실패 테스트')),
      throwsA(isA<StateError>()),
    );
    expect(attempts, 1);
    expect(preferences.getString(GamePersistence.saveKey), isNull);
  });

  test('a failed migration write is not mistaken for a missing save', () async {
    final oldStart = engine.createNewGame('마이그레이션 실패 테스트', initialCash: 0);
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: jsonEncode(v8Json(oldStart)),
    });
    final preferences = await SharedPreferences.getInstance();
    final persistence = GamePersistence(
      preferences: preferences,
      saveString: (key, value) async => false,
    );

    await expectLater(persistence.load(), throwsA(isA<StateError>()));
  });

  testWidgets('restore failure preserves the raw save and retry can recover', (
    tester,
  ) async {
    final oldStart = engine.createNewGame('복원 재시도 테스트', initialCash: 0);
    final originalRaw = jsonEncode(v8Json(oldStart));
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: originalRaw,
    });
    final preferences = await SharedPreferences.getInstance();
    var saveAttempts = 0;
    final persistence = GamePersistence(
      preferences: preferences,
      saveString: (key, value) async {
        saveAttempts += 1;
        if (saveAttempts == 1) return false;
        return preferences.setString(key, value);
      },
    );

    await tester.pumpWidget(MillenniumCapitalApp(persistence: persistence));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('restore-failure-screen')), findsOneWidget);
    expect(find.byKey(const Key('restore-retry-button')), findsOneWidget);
    expect(find.byType(VisualNovelOnboardingScreen), findsNothing);
    expect(preferences.getString(GamePersistence.saveKey), originalRaw);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('restore-retry-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('restore-failure-screen')), findsNothing);
    expect(find.byKey(const Key('apartment-place-bedroom')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('company-header-title'))).data,
      '복원 재시도 테스트',
    );
    final stored =
        jsonDecode(preferences.getString(GamePersistence.saveKey)!)
            as Map<String, dynamic>;
    expect(saveAttempts, 2);
    expect(stored['version'], GameState.schemaVersion);
    expect(stored['cash'], initialCompanyCash);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed hour save never publishes the new clock to the UI', (
    tester,
  ) async {
    final state = engine
        .createNewGame('시계 저장 실패 테스트')
        .copyWith(decisions: const []);
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: jsonEncode(state.toJson()),
    });
    final preferences = await SharedPreferences.getInstance();
    final writeStarted = Completer<void>();
    final writeResult = Completer<bool>();
    final persistence = GamePersistence(
      preferences: preferences,
      saveString: (key, value) {
        if (!writeStarted.isCompleted) writeStarted.complete();
        return writeResult.future;
      },
    );

    await tester.pumpWidget(MillenniumCapitalApp(persistence: persistence));
    await tester.pumpAndSettle();
    expect(find.textContaining('08:00'), findsWidgets);

    await tester.tap(find.byKey(const Key('advance-hour-button')));
    await tester.pump();
    await writeStarted.future;
    expect(find.textContaining('08:00'), findsWidgets);
    expect(find.textContaining('09:00'), findsNothing);

    writeResult.complete(false);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('save-failure-message')), findsOneWidget);
    expect(find.textContaining('08:00'), findsWidgets);
    expect(find.textContaining('09:00'), findsNothing);
  });
}
