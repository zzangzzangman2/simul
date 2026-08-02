import 'package:flutter/material.dart';
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
          '시설 개선 테스트',
          initialCash: 0,
          worldSeed: 'academy-facility-test',
        )
        .copyWith(cash: cash, brokerageCash: brokerageCash);
  }

  test('old household purchase ids are discarded during migration', () {
    final state = fundedState();
    final json = state.toJson();
    json['homeImprovements'] = <String, dynamic>{
      'purchasedIds': <String>['bedroom_father_tools'],
      'purchaseDayById': <String, int>{'bedroom_father_tools': 1},
      'totalSpent': 30000,
    };

    final restored = GameState.fromJson(json);

    expect(restored.homeImprovements.completedCount, 0);
    expect(restored.homeImprovements.totalSpent, 0);
    expect(restored.toJson()['homeImprovements'], isA<Map<String, dynamic>>());
  });

  test('facility purchase spends bank cash and raises cohort state', () {
    final state = fundedState();
    final brokerageBefore = state.brokerageCash;
    final trustBefore = state.story.flagInt('cohortTrust', 30);
    final jianBefore = state.story.flagInt('jianAffinity', 30);
    final stabilityBefore = state.story.householdStability;

    final result = engine.purchaseHomeImprovement(state, 'dorm_repair_tools');

    expect(result.success, isTrue);
    expect(result.cashDelta, -30000);
    expect(result.state.cash, state.cash - 30000);
    expect(result.state.brokerageCash, brokerageBefore);
    expect(result.state.homeImprovements.has('dorm_repair_tools'), isTrue);
    expect(result.state.story.flagInt('cohortTrust'), trustBefore + 1);
    expect(result.state.story.flagInt('jianAffinity'), jianBefore + 4);
    expect(result.state.story.householdStability, stabilityBefore + 4);
    expect(
      result.state.story.seenStoryEventIds,
      contains('ACADEMY_DORM_REPAIR_TOOLS'),
    );
    expect(result.state.ledger.last.counterAccount, 'academy_facility');

    final restored = GameState.fromJson(result.state.toJson());
    expect(restored.homeImprovements.has('dorm_repair_tools'), isTrue);
    expect(
      restored.homeImprovements.purchaseDayById['dorm_repair_tools'],
      state.day,
    );
    expect(restored.homeImprovements.totalSpent, 30000);
  });

  test('brokerage cash is unavailable for academy facility purchases', () {
    final state = fundedState(cash: 0, brokerageCash: 500000);

    final result = engine.purchaseHomeImprovement(
      state,
      'common_room_winter_bedding',
    );

    expect(result.success, isFalse);
    expect(result.message, contains('회사 통장 잔고'));
    expect(result.state, same(state));
  });

  test('facility stages must be purchased in order and only once', () {
    final state = fundedState();

    final locked = engine.purchaseHomeImprovement(
      state,
      'dorm_shared_study_desks',
    );
    expect(locked.success, isFalse);
    expect(locked.message, contains(homeImprovementCatalog.first.title));

    final first = engine.purchaseHomeImprovement(state, 'dorm_repair_tools');
    final second = engine.purchaseHomeImprovement(
      first.state,
      'dorm_shared_study_desks',
    );
    final duplicate = engine.purchaseHomeImprovement(
      second.state,
      'dorm_shared_study_desks',
    );

    expect(second.success, isTrue);
    expect(
      second.state.homeImprovements.roomTier(HomeImprovementRoom.bedroom),
      2,
    );
    expect(duplicate.success, isFalse);
    expect(duplicate.state.cash, second.state.cash);
  });

  testWidgets('360px facility ledger buys sequential common-room upgrades', (
    tester,
  ) async {
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
            final result = engine.purchaseHomeImprovement(state, improvementId);
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
      find.byKey(const Key('buy-home-improvement-common_room_winter_bedding')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('home-story-common_room_winter_bedding')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('home-story-close')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('home-room-preview-livingRoom-tier-1')),
      findsOneWidget,
    );

    final secondUpgrade = find.byKey(
      const Key('buy-home-improvement-common_room_floor_curtains'),
    );
    await tester.ensureVisible(secondUpgrade);
    await tester.tap(secondUpgrade);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('home-story-common_room_floor_curtains')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
