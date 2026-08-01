import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/main.dart';

void main() {
  const engine = GameEngine();

  Future<void> setPhoneSurface(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
  }

  testWidgets('status screen lists affection for the eight girls', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final state = engine.createNewGame('관계 UI', worldSeed: 'relation-ui-1');

    await tester.pumpWidget(
      MaterialApp(home: RelationshipStatusScreen(state: state)),
    );
    await tester.pumpAndSettle();

    expect(find.text('제6기 관계 기록'), findsOneWidget);
    expect(find.text('김서아 · ISFJ'), findsOneWidget);
    expect(find.byKey(const Key('relationship-status-list')), findsOneWidget);
    expect(
      find.byKey(const Key('relationship-affection-kim_seoa')),
      findsOneWidget,
    );
  });

  testWidgets('evening conversation applies choice and shows result', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    var state = engine.createNewGame('관계 UI', worldSeed: 'relation-ui-2');

    await tester.pumpWidget(
      MaterialApp(
        home: RelationshipEveningScreen(
          state: state,
          onComplete: (girlId, activity, choiceId) async {
            final result = engine.completeRelationshipEvening(
              state,
              girlId: girlId,
              activity: activity,
              choiceId: choiceId,
            );
            state = result.state;
            return result;
          },
          onRest: () async {
            final result = engine.restDuringRelationshipEvening(state);
            state = result.state;
            return result;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('relationship-select-lee_jian')));
    await tester.pumpAndSettle();

    final lockedDate = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const Key('relationship-date-button')),
        matching: find.byType(InkWell),
      ),
    );
    expect(lockedDate.onTap, isNull);

    await tester.tap(find.byKey(const Key('relationship-conversation-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('relationship-choice-test_signal')));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 → 6'), findsOneWidget);
    expect(find.textContaining('말보다 이게 빠르지'), findsOneWidget);
    expect(state.relationships.progressFor('lee_jian').affection, 6);
    expect(find.byKey(const Key('relationship-finish-button')), findsOneWidget);
  });
}
