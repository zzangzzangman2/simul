import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/home_improvement_state.dart';
import 'package:millennium_capital/main.dart';

void main() {
  const engine = GameEngine();

  GameState fundedState({int cash = 500000, int brokerageCash = 0}) {
    return engine
        .createNewGame(
          '살림 테스트',
          initialCash: 0,
          worldSeed: 'home-improvement-test',
        )
        .copyWith(cash: cash, brokerageCash: brokerageCash);
  }

  test('legacy saves restore with an empty home improvement state', () {
    final state = fundedState();
    final json = state.toJson()..remove('homeImprovements');

    final restored = GameState.fromJson(json);

    expect(restored.homeImprovements.completedCount, 0);
    expect(restored.homeImprovements.roomTier(HomeImprovementRoom.bedroom), 0);
    expect(restored.toJson()['homeImprovements'], isA<Map<String, dynamic>>());
  });

  test('purchase spends company bank cash and records family changes', () {
    final state = fundedState();
    final originalBrokerageCash = state.brokerageCash;
    final originalFatherAffinity = state.story.fatherAffinity;
    final originalStability = state.story.householdStability;

    final result = engine.purchaseHomeImprovement(
      state,
      'bedroom_father_tools',
    );

    expect(result.success, isTrue);
    expect(result.cashDelta, -30000);
    expect(result.state.cash, state.cash - 30000);
    expect(result.state.brokerageCash, originalBrokerageCash);
    expect(result.state.homeImprovements.has('bedroom_father_tools'), isTrue);
    expect(
      result.state.homeImprovements.roomTier(HomeImprovementRoom.bedroom),
      1,
    );
    expect(result.state.story.fatherAffinity, originalFatherAffinity + 4);
    expect(result.state.story.householdStability, originalStability + 4);
    expect(result.state.story.seenStoryEventIds, contains('HOME_FATHER_TOOLS'));
    expect(result.state.ledger.last.counterAccount, 'family_household');
    expect(result.state.ledger.last.amount, -30000);

    final restored = GameState.fromJson(result.state.toJson());
    expect(restored.homeImprovements.has('bedroom_father_tools'), isTrue);
    expect(
      restored.homeImprovements.purchaseDayById['bedroom_father_tools'],
      state.day,
    );
    expect(restored.homeImprovements.totalSpent, 30000);
  });

  test('brokerage cash is never available for household purchases', () {
    final state = fundedState(cash: 500000, brokerageCash: 500000);

    final result = engine.purchaseHomeImprovement(state, 'kitchen_mother_rice');

    expect(result.success, isFalse);
    expect(result.message, contains('회사 통장 잔고'));
    expect(result.state, same(state));
  });

  test('room upgrades require order and cannot be purchased twice', () {
    final state = fundedState();

    final locked = engine.purchaseHomeImprovement(state, 'bedroom_sister_desk');
    expect(locked.success, isFalse);
    expect(locked.message, contains('공구함'));

    final first = engine.purchaseHomeImprovement(state, 'bedroom_father_tools');
    final second = engine.purchaseHomeImprovement(
      first.state,
      'bedroom_sister_desk',
    );
    final duplicate = engine.purchaseHomeImprovement(
      second.state,
      'bedroom_sister_desk',
    );

    expect(second.success, isTrue);
    expect(
      second.state.homeImprovements.roomTier(HomeImprovementRoom.bedroom),
      2,
    );
    expect(duplicate.success, isFalse);
    expect(duplicate.state.cash, second.state.cash);
  });

  testWidgets('apartment map assets follow each room improvement tier', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var home = const HomeImprovementState.initial();
    for (final id in <String>[
      'bedroom_father_tools',
      'living_grandfather_bedding',
      'kitchen_mother_rice',
    ]) {
      home = home.recordPurchase(homeImprovementById(id)!, day: 1);
    }
    final state = fundedState().copyWith(homeImprovements: home);

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
          onSetMarketMinute: (_) async => state,
          onSaveMarketNotebook: (_, _) async => state,
          onResolveDecision: (_, _) async {},
          onRequestFamilyHelp: (_) async => state,
          onCompleteWork: (_) async => state,
          onExecuteTrade: (_) => throw UnimplementedError(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    AssetImage background(String key) {
      final image = tester.widget<Image>(find.byKey(Key(key)));
      return image.image as AssetImage;
    }

    expect(
      background('apartment-background-bedroom').assetName,
      'assets/images/gameplay_map/bg_gameplay_bedroom_tier1_2000_portrait_cartoon_v1.png',
    );
    expect(find.byKey(const Key('apartment-ambient-bedroom')), findsOneWidget);

    await tester.tap(find.byKey(const Key('apartment-go-living-room')));
    await tester.pumpAndSettle();
    expect(
      background('apartment-background-living-room').assetName,
      'assets/images/gameplay_map/bg_gameplay_living_room_tier1_2000_portrait_cartoon_v1.png',
    );
    expect(
      find.byKey(const Key('apartment-ambient-living-room')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('open-home-improvements-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('apartment-go-kitchen')));
    await tester.pumpAndSettle();
    expect(
      background('apartment-background-kitchen').assetName,
      'assets/images/gameplay_map/bg_gameplay_kitchen_tier1_2000_portrait_cartoon_v1.png',
    );
    expect(find.byKey(const Key('apartment-ambient-kitchen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('apartment-go-corridor')));
    await tester.pumpAndSettle();
    expect(
      background('apartment-background-corridor').assetName,
      'assets/images/gameplay_map/bg_gameplay_corridor_tier1_2000_portrait_cartoon_v1.png',
    );
    expect(find.byKey(const Key('apartment-ambient-corridor')), findsOneWidget);
    expect(find.byKey(const Key('ambient-corridor-cat')), findsOneWidget);
    expect(find.byKey(const Key('open-decisions-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('apartment-go-neighborhood')));
    await tester.pumpAndSettle();
    expect(
      background('apartment-background-neighborhood').assetName,
      startsWith('assets/images/gameplay_map/bg_gameplay_neighborhood_'),
    );
    expect(
      find.byKey(const Key('apartment-ambient-neighborhood')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('ambient-neighborhood-minibus')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('ambient-neighborhood-bicycle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('ambient-neighborhood-walkers')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('open-bank-button')), findsOneWidget);
    expect(find.byKey(const Key('open-work-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('ambient cartoon sprites are bundled as real transparent assets', (
    tester,
  ) async {
    for (final asset in const <String>[
      'assets/images/gameplay_ambient/ambient_corridor_cat_cartoon_v1.png',
      'assets/images/gameplay_ambient/ambient_neighborhood_minibus_cartoon_v1.png',
      'assets/images/gameplay_ambient/ambient_neighborhood_bicycle_cartoon_v1.png',
      'assets/images/gameplay_ambient/ambient_neighborhood_walkers_cartoon_v1.png',
    ]) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(5000), reason: asset);
    }
  });
  testWidgets(
    '360px home ledger purchases an upgrade and changes preview tier',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var state = fundedState();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeImprovementScreen(
            state: state,
            onPurchase: (improvementId) async {
              final result = engine.purchaseHomeImprovement(
                state,
                improvementId,
              );
              if (result.success) state = result.state;
              return result;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-improvement-screen')), findsOneWidget);
      expect(
        find.byKey(const Key('home-room-preview-livingRoom-tier-0')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const Key('buy-home-improvement-living_grandfather_bedding'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('home-story-living_grandfather_bedding')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('home-story-close')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('home-room-preview-livingRoom-tier-1')),
        findsOneWidget,
      );

      final secondUpgrade = find.byKey(
        const Key('buy-home-improvement-living_mother_floor'),
      );
      await tester.ensureVisible(secondUpgrade);
      await tester.tap(secondUpgrade);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('home-story-living_mother_floor')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('home-story-close')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('home-room-preview-livingRoom-tier-2')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
