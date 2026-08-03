import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/banking_state.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_persistence.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/story_state.dart';
import 'package:millennium_capital/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _skipCampaignWorldPreparation(
  GameState state,
  WorldLoadProgressCallback onProgress,
) async {}

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
    'order-book fill breakdown round-trips and legacy entries stay empty',
    () {
      const entry = LedgerEntry(
        id: 'trade-depth',
        day: 4,
        amount: -30000,
        account: 'brokerage_cash',
        counterAccount: 'market_security',
        description: 'depth fill',
        sourceId: 'trade-depth',
        assetId: 'hanbit_telecom',
        tradeSide: 'buy',
        tradeQuantity: 3,
        tradeUnitPrice: 10000,
        marketMinute: 540,
        orderType: 'market',
        orderBookSide: 'ask',
        orderBookFills: [
          LedgerOrderBookFill(price: 10000, quantity: 2),
          LedgerOrderBookFill(price: 10050, quantity: 1),
        ],
        orderBookCapacityUnits: 3,
      );
      final restored = LedgerEntry.fromJson(entry.toJson());

      expect(restored.orderBookSide, 'ask');
      expect(restored.orderBookFills, hasLength(2));
      expect(restored.orderBookFills[0].price, 10000);
      expect(restored.orderBookFills[0].quantity, 2);
      expect(restored.orderBookFills[1].price, 10050);
      expect(restored.orderBookCapacityUnits, 3);

      final legacyJson = Map<String, dynamic>.from(entry.toJson())
        ..remove('orderBookSide')
        ..remove('orderBookFills')
        ..remove('orderBookCapacityUnits');
      final legacy = LedgerEntry.fromJson(legacyJson);
      expect(legacy.orderBookSide, isEmpty);
      expect(legacy.orderBookFills, isEmpty);
      expect(legacy.orderBookCapacityUnits, 0);
    },
  );

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
      expect(migrated!.cash, 0);
      expect(migrated.story.orphanageReboot, isTrue);
      expect(migrated.story.storyFlags, isNot(contains('academyTuitionDebt')));
      expect(
        migrated.story.storyFlags,
        isNot(contains('academyTuitionOriginal')),
      );
      expect(migrated.story.marketTutorialEligible, isFalse);
      expect(migrated.story.marketTutorialSeen, isTrue);
      expect(migrated.version, GameState.schemaVersion);
      final stored =
          jsonDecode(preferences.getString(GamePersistence.saveKey)!)
              as Map<String, dynamic>;
      expect(stored['version'], GameState.schemaVersion);
      expect(stored['cash'], 0);

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
      expect(migrated!.cash, 0);
      expect(migrated.day, 4);
      expect(migrated.marketMinute, 9 * 60);
      expect(migrated.decisions, isEmpty);
    },
  );

  test('v16 save migrates with a safe empty banking state', () async {
    final original = engine.createNewGame('은행 마이그레이션 테스트', initialCash: 500000);
    final legacy = original.toJson()
      ..remove('banking')
      ..['version'] = 16;
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: jsonEncode(legacy),
    });
    final preferences = await SharedPreferences.getInstance();
    final persistence = GamePersistence(preferences: preferences);

    final migrated = await persistence.load();

    expect(migrated, isNotNull);
    expect(migrated!.version, GameState.schemaVersion);
    expect(migrated.banking.creditScore, bankInitialCreditScore);
    expect(migrated.banking.termDeposits, isEmpty);
    expect(migrated.banking.unsecuredLoans, isEmpty);
    final stored =
        jsonDecode(preferences.getString(GamePersistence.saveKey)!)
            as Map<String, dynamic>;
    expect(stored['version'], GameState.schemaVersion);
    expect(stored['banking'], isA<Map<String, dynamic>>());
  });

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

  test('a generated IPO holding survives save and reload', () async {
    const seed = 'generated-ipo-persistence-test';
    final universe = await FictionalMarketUniverse.load(
      seed: seed,
      throughDate: DateTime(2000, 12, 31),
    );
    final ipo = universe.assets.firstWhere(
      (asset) => asset.generation == 1 && asset.id.startsWith('ipo_'),
    );
    final state = engine
        .createNewGame('생성 IPO 저장 테스트', initialCash: 500000, worldSeed: seed)
        .copyWith(
          positions: [
            PortfolioPosition(
              assetId: ipo.id,
              symbol: ipo.symbol,
              name: ipo.name,
              market: ipo.market,
              currency: ipo.currency,
              units: 7,
              totalCost: 123400,
            ),
          ],
        );
    final preferences = await SharedPreferences.getInstance();
    final persistence = GamePersistence(preferences: preferences);

    await persistence.save(state);
    final loaded = await persistence.load();

    expect(loaded, isNotNull);
    expect(loaded!.positions, hasLength(1));
    expect(loaded.positions.single.assetId, ipo.id);
    expect(loaded.positions.single.units, 7);
    expect(loaded.positions.single.totalCost, 123400);
    expect(loaded.cash, 500000);
    expect(loaded.brokerageCash, 500000);
    expect(
      loaded.processedEventIds,
      isNot(contains('legacy-real-market-recovery-v14')),
    );
  });

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

    await tester.pumpWidget(
      MillenniumCapitalApp(
        persistence: persistence,
        campaignWorldPreparer: _skipCampaignWorldPreparation,
      ),
    );
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
    expect(stored['cash'], 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('이어하기는 세계 예열 Future가 끝나기 전 게임 화면을 열지 않고 진행률을 표시하며, 완료 후 연다', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final persistence = GamePersistence(preferences: preferences);
    final savedState = engine.createNewGame('세계 예열 테스트');
    await persistence.saveToSlot(savedState, 1);
    await persistence.setActiveSlot(1);

    final preparationStarted = Completer<void>();
    final preparationGate = Completer<void>();
    GameState? preparedState;

    Future<void> delayedWorldPreparation(
      GameState state,
      WorldLoadProgressCallback onProgress,
    ) async {
      preparedState = state;
      onProgress(const WorldLoadProgress(0.37, '주식시장과 부동산 세계를 구성 중입니다…'));
      preparationStarted.complete();
      await preparationGate.future;
    }

    await tester.pumpWidget(
      MillenniumCapitalApp(
        persistence: persistence,
        campaignWorldPreparer: delayedWorldPreparation,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-game-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('load-save-slot-1')));
    await tester.pump();
    await tester.runAsync(
      () => preparationStarted.future.timeout(const Duration(seconds: 5)),
    );
    await tester.pump();

    expect(find.byKey(const Key('campaign-loading-screen')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('campaign-loading-status')))
          .data,
      '주식시장과 부동산 세계를 구성 중입니다…',
    );
    expect(find.text('37%'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('campaign-loading-progress')),
          )
          .value,
      0.37,
    );
    expect(find.byKey(const Key('apartment-place-bedroom')), findsNothing);
    expect(find.byKey(const Key('company-header-title')), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const Key('campaign-loading-screen')), findsOneWidget);
    expect(find.byKey(const Key('apartment-place-bedroom')), findsNothing);

    preparationGate.complete();
    await tester.pumpAndSettle();

    expect(preparedState?.companyName, savedState.companyName);
    expect(find.byKey(const Key('campaign-loading-screen')), findsNothing);
    expect(find.byKey(const Key('apartment-place-bedroom')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('company-header-title'))).data,
      '세계 예열 테스트',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('처음하기는 프롤로그보다 먼저 세계를 구성하고 같은 시드를 새 저장에 사용한다', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final persistence = GamePersistence(preferences: preferences);
    final preparationStarted = Completer<void>();
    final preparationGate = Completer<void>();
    String? preparedSeed;

    Future<void> delayedWorldPreparation(
      GameState state,
      WorldLoadProgressCallback onProgress,
    ) async {
      preparedSeed = state.simulationSeed;
      onProgress(const WorldLoadProgress(0.41, '27년 주식시장 세계를 구성 중입니다…'));
      preparationStarted.complete();
      await preparationGate.future;
    }

    await tester.pumpWidget(
      MillenniumCapitalApp(
        persistence: persistence,
        campaignWorldPreparer: delayedWorldPreparation,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-game-button')));
    await tester.pump();
    await tester.runAsync(
      () => preparationStarted.future.timeout(const Duration(seconds: 5)),
    );
    await tester.pump();

    expect(find.byKey(const Key('campaign-loading-screen')), findsOneWidget);
    expect(find.text('새 캠페인 세계를 구성하고 있어요'), findsOneWidget);
    expect(find.text('27년 주식시장 세계를 구성 중입니다…'), findsOneWidget);
    expect(find.text('41%'), findsOneWidget);
    expect(find.byType(VisualNovelOnboardingScreen), findsNothing);
    expect(preferences.getString(GamePersistence.saveKeyFor(1)), isNull);

    preparationGate.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campaign-loading-screen')), findsNothing);
    expect(find.byType(VisualNovelOnboardingScreen), findsOneWidget);
    final checkpoint = await persistence.loadSlot(1, activate: false);
    expect(checkpoint, isNotNull);
    expect(checkpoint!.simulationSeed, preparedSeed);
    expect(checkpoint.story.flagBool('prologueInProgress'), isTrue);

    final onboarding = tester.widget<VisualNovelOnboardingScreen>(
      find.byType(VisualNovelOnboardingScreen),
    );
    await tester.runAsync(
      () => onboarding
          .onCreate(
            const NewGameSetup(
              playerName: '민재',
              companyName: '시드 유지 연구소',
              introChoice: 'stocks',
              startingTrait: StoryTrait.analysis,
              operatingPrinciple: OperatingPrinciple.reportLosses,
            ),
            (_) {},
          )
          .timeout(const Duration(seconds: 15)),
    );
    final saved = await persistence.loadSlot(1, activate: false);

    expect(saved, isNotNull);
    expect(saved!.simulationSeed, preparedSeed);
    expect(saved.companyName, '시드 유지 연구소');
    expect(tester.takeException(), isNull);
  });

  testWidgets('이어하기 예열 중 다른 슬롯 탭은 무시하고 화면과 활성 저장을 같은 슬롯으로 유지한다', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final persistence = GamePersistence(preferences: preferences);
    await persistence.saveToSlot(engine.createNewGame('먼저 누른 회사'), 1);
    await persistence.saveToSlot(engine.createNewGame('나중에 누른 회사'), 2);
    await persistence.setActiveSlot(2);

    final preparationStarted = Completer<void>();
    final preparationGate = Completer<void>();
    final preparedCompanies = <String>[];

    Future<void> delayedWorldPreparation(
      GameState state,
      WorldLoadProgressCallback onProgress,
    ) async {
      preparedCompanies.add(state.companyName);
      if (!preparationStarted.isCompleted) preparationStarted.complete();
      await preparationGate.future;
    }

    await tester.pumpWidget(
      MillenniumCapitalApp(
        persistence: persistence,
        campaignWorldPreparer: delayedWorldPreparation,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-game-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('load-save-slot-1')));
    await tester.tap(find.byKey(const Key('load-save-slot-2')));
    await tester.pump();
    await tester.runAsync(
      () => preparationStarted.future.timeout(const Duration(seconds: 5)),
    );

    expect(preparedCompanies, ['먼저 누른 회사']);
    expect(await persistence.getActiveSlot(), 2);
    expect(find.byKey(const Key('campaign-loading-screen')), findsOneWidget);

    preparationGate.complete();
    await tester.pumpAndSettle();

    expect(await persistence.getActiveSlot(), 1);
    expect(
      tester.widget<Text>(find.byKey(const Key('company-header-title'))).data,
      '먼저 누른 회사',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('세계 예열 실패는 기존 활성 슬롯을 바꾸지 않는다', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final persistence = GamePersistence(preferences: preferences);
    await persistence.saveToSlot(engine.createNewGame('실패할 회사'), 1);
    await persistence.saveToSlot(engine.createNewGame('기존 활성 회사'), 2);
    await persistence.setActiveSlot(2);

    Future<void> failingWorldPreparation(
      GameState state,
      WorldLoadProgressCallback onProgress,
    ) async {
      throw StateError('world preparation failed');
    }

    await tester.pumpWidget(
      MillenniumCapitalApp(
        persistence: persistence,
        campaignWorldPreparer: failingWorldPreparation,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-game-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('load-save-slot-1')));
    await tester.pumpAndSettle();

    expect(await persistence.getActiveSlot(), 2);
    expect(find.byKey(const Key('save-slot-screen')), findsOneWidget);
    expect(find.textContaining('불러오지 못했어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('신규 세계 예열 실패는 프롤로그와 저장 생성 전에 제목 화면으로 복구한다', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final persistence = GamePersistence(preferences: preferences);
    await persistence.saveToSlot(engine.createNewGame('기존 회사'), 2);
    await persistence.setActiveSlot(2);

    Future<void> failingWorldPreparation(
      GameState state,
      WorldLoadProgressCallback onProgress,
    ) async {
      throw StateError('new world preparation failed');
    }

    await tester.pumpWidget(
      MillenniumCapitalApp(
        persistence: persistence,
        campaignWorldPreparer: failingWorldPreparation,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-game-button')));
    await tester.pumpAndSettle();

    expect(await persistence.getActiveSlot(), 2);
    expect(find.byKey(const Key('game-title-screen')), findsOneWidget);
    expect(find.byType(VisualNovelOnboardingScreen), findsNothing);
    expect(preferences.getString(GamePersistence.saveKeyFor(1)), isNull);
    expect(find.textContaining('새 세계를 구성하지 못했어요'), findsOneWidget);
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

    await tester.pumpWidget(
      MillenniumCapitalApp(
        persistence: persistence,
        campaignWorldPreparer: _skipCampaignWorldPreparation,
      ),
    );
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

  testWidgets(
    'a slot deleted from a full save list starts a new game when tapped',
    (tester) async {
      final preferences = await SharedPreferences.getInstance();
      final persistence = GamePersistence(preferences: preferences);
      for (var slot = 1; slot <= GamePersistence.slotCount; slot++) {
        await persistence.saveToSlot(engine.createNewGame('$slot번 회사'), slot);
      }

      await tester.pumpWidget(
        MillenniumCapitalApp(
          persistence: persistence,
          campaignWorldPreparer: _skipCampaignWorldPreparation,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new-game-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save-slot-screen')), findsOneWidget);
      await tester.tap(find.byKey(const Key('delete-save-slot-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-delete-slot-3')));
      await tester.pumpAndSettle();

      expect(find.text('빈 슬롯'), findsOneWidget);
      expect(find.text('이 슬롯을 눌러 바로 새 게임을 시작하세요.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('load-save-slot-3')));
      await tester.pumpAndSettle();

      expect(find.byType(VisualNovelOnboardingScreen), findsOneWidget);
      expect(find.byKey(const Key('save-slot-screen')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

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

    await tester.pumpWidget(
      MillenniumCapitalApp(
        persistence: persistence,
        campaignWorldPreparer: _skipCampaignWorldPreparation,
      ),
    );
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
    final initialState = engine.createNewGame('시계 저장 실패 테스트');
    final state = initialState.copyWith(
      decisions: const [],
      story: initialState.story.copyWith(
        storyFlags: {...initialState.story.storyFlags, 'hubTutorialSeen': true},
      ),
    );
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

    await tester.pumpWidget(
      MillenniumCapitalApp(
        persistence: persistence,
        campaignWorldPreparer: _skipCampaignWorldPreparation,
      ),
    );
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
