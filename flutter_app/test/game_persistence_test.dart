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

  test(
    'a pristine zero-cash legacy start remains at zero after migration',
    () async {
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
        reason: 'v12 saves must preserve an intentional zero balance',
      );
    },
  );

  test(
    'non-financial legacy progress preserves zero cash and story progress',
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
    'a financially progressed zero-cash legacy save preserves its balance',
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

  test('corrupt JSON is not mistaken for a missing save', () async {
    const originalRaw = '{not-valid-json';
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: originalRaw,
    });
    final preferences = await SharedPreferences.getInstance();
    final persistence = GamePersistence(preferences: preferences);
    await expectLater(persistence.load(), throwsA(isA<StateError>()));
    expect(preferences.getString(GamePersistence.saveKey), originalRaw);
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
    expect(find.byKey(const Key('game-title-screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('continue-game-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('load-save-slot-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('save-slot-screen')), findsOneWidget);
    expect(find.textContaining('불러오지 못했어요'), findsOneWidget);
    expect(find.byType(VisualNovelOnboardingScreen), findsNothing);
    expect(preferences.getString(GamePersistence.saveKey), originalRaw);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('load-save-slot-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('save-slot-screen')), findsNothing);
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

  test(
    'saving a new state preserves the previous valid state as a backup',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final persistence = GamePersistence(preferences: preferences);
      final original = engine.createNewGame('백업 테스트').copyWith(cash: 700000);
      final updated = original.copyWith(cash: 650000);

      await persistence.save(original);
      await persistence.save(updated);

      final backup =
          jsonDecode(preferences.getString(GamePersistence.backupSaveKey)!)
              as Map<String, dynamic>;
      expect(backup['cash'], 700000);
      expect((await persistence.load())!.cash, 650000);
    },
  );

  test(
    'a corrupt primary save recovers the backup and preserves the corrupt raw',
    () async {
      const corruptRaw = '{broken-primary';
      final backup = engine.createNewGame('자동 복구 테스트').copyWith(cash: 812345);
      SharedPreferences.setMockInitialValues({
        GamePersistence.saveKey: corruptRaw,
        GamePersistence.backupSaveKey: jsonEncode(backup.toJson()),
      });
      final preferences = await SharedPreferences.getInstance();
      final persistence = GamePersistence(preferences: preferences);

      final slot = (await persistence.listSlots()).first;
      expect(slot.canContinue, isTrue);
      expect(slot.state!.companyName, '자동 복구 테스트');

      final restored = await persistence.load();

      expect(restored!.companyName, '자동 복구 테스트');
      expect(restored.cash, 812345);
      expect(preferences.getString(GamePersistence.corruptSaveKey), corruptRaw);
      final primary =
          jsonDecode(preferences.getString(GamePersistence.saveKey)!)
              as Map<String, dynamic>;
      expect(primary['companyName'], '자동 복구 테스트');
    },
  );

  test('a blank company name is corrupt rather than a missing save', () async {
    final invalid = engine.createNewGame('임시 회사').toJson();
    invalid['companyName'] = '   ';
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: jsonEncode(invalid),
    });
    final preferences = await SharedPreferences.getInstance();

    await expectLater(
      GamePersistence(preferences: preferences).load(),
      throwsA(isA<StateError>()),
    );
  });

  test('five slots are the hard limit and a deleted slot is reused', () async {
    final preferences = await SharedPreferences.getInstance();
    final persistence = GamePersistence(preferences: preferences);

    for (var index = 1; index <= GamePersistence.slotCount; index++) {
      final slot = await persistence.createSlot(
        engine.createNewGame('$index번 회사'),
      );
      expect(slot, index);
    }

    expect(
      () => persistence.createSlot(engine.createNewGame('여섯 번째 회사')),
      throwsA(isA<StateError>()),
    );
    expect(
      (await persistence.listSlots()).where((slot) => slot.canContinue),
      hasLength(GamePersistence.slotCount),
    );
    expect(await persistence.getActiveSlot(), 5);

    await persistence.deleteSlot(3);
    final reused = await persistence.createSlot(engine.createNewGame('재사용 회사'));

    expect(reused, 3);
    expect(await persistence.getActiveSlot(), 3);
    expect((await persistence.load())!.companyName, '재사용 회사');
    expect(preferences.getString(GamePersistence.saveKey), isNotNull);
    expect(preferences.getString(GamePersistence.saveKeyFor(5)), isNotNull);
  });

  testWidgets('continue screen shows five slots and deletes a save', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final persistence = GamePersistence(preferences: preferences);
    await persistence.saveToSlot(engine.createNewGame('첫 회사'), 1);
    await persistence.saveToSlot(engine.createNewGame('삭제할 회사'), 2);
    await persistence.setActiveSlot(1);

    await tester.pumpWidget(MillenniumCapitalApp(persistence: persistence));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-game-button')));
    await tester.pumpAndSettle();

    for (var slot = 1; slot <= GamePersistence.slotCount; slot++) {
      expect(find.byKey(Key('save-slot-$slot')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('delete-save-slot-2')));
    await tester.pumpAndSettle();
    expect(find.text('2번 저장을 삭제할까요?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-slot-2')));
    await tester.pumpAndSettle();

    expect(preferences.getString(GamePersistence.saveKeyFor(2)), isNull);
    expect(find.text('저장 슬롯 1개'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('game menu performs a manual save in the active slot', (
    tester,
  ) async {
    final state = engine.createNewGame('수동저장 회사');
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: jsonEncode(state.toJson()),
    });
    final preferences = await SharedPreferences.getInstance();
    final savedAt = DateTime(2026, 7, 22, 14, 30);
    final persistence = GamePersistence(
      preferences: preferences,
      now: () => savedAt,
    );

    await tester.pumpWidget(MillenniumCapitalApp(persistence: persistence));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-game-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('load-save-slot-1')));
    await tester.pumpAndSettle();
    final tutorialDone = find.byKey(const Key('hub-tutorial-done'));
    if (tutorialDone.evaluate().isNotEmpty) {
      await tester.tap(tutorialDone);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('game-menu-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('하루 넘어갈 때마다 자동 저장'), findsOneWidget);
    await tester.tap(find.byKey(const Key('manual-save-button')));
    await tester.pumpAndSettle();

    expect(
      preferences.getString(GamePersistence.savedAtKeyFor(1)),
      savedAt.toIso8601String(),
    );
    expect(find.textContaining('1번 슬롯에 수동저장'), findsOneWidget);
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
    await tester.tap(find.byKey(const Key('continue-game-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('load-save-slot-1')));
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
