import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/relationship_state.dart';

void main() {
  const engine = GameEngine();

  test('new game starts eight girls at affection 1', () {
    final state = engine.createNewGame('관계 테스트', worldSeed: 'relation-1');

    expect(state.relationships.girls.length, 8);
    expect(
      state.relationships.girls.values.map((item) => item.affection).toSet(),
      <int>{1},
    );
    expect(state.relationships.lastEveningEventDay, 0);
  });

  test('one conversation is saved once per day and uses authored outcome', () {
    final state = engine.createNewGame('관계 테스트', worldSeed: 'relation-2');
    final result = engine.completeRelationshipEvening(
      state,
      girlId: 'kim_seoa',
      activity: RelationshipActivity.conversation,
      choiceId: 'rebuild_together',
    );

    expect(result.success, isTrue);
    expect(result.affectionBefore, 1);
    expect(result.affectionAfter, 6);
    expect(result.affectionDelta, 5);
    expect(result.response, contains('확인하면서'));
    expect(result.state.relationships.lastEveningEventDay, state.day);
    expect(
      result.state.relationships.progressFor('kim_seoa').conversationCount,
      1,
    );

    final duplicate = engine.completeRelationshipEvening(
      result.state,
      girlId: 'han_sua',
      activity: RelationshipActivity.conversation,
      choiceId: 'test_story',
    );
    expect(duplicate.success, isFalse);
    expect(duplicate.state.toJson(), result.state.toJson());
  });

  test('affection is clamped to 1 and date stays locked below 20', () {
    final state = engine.createNewGame('관계 테스트', worldSeed: 'relation-3');
    final negative = engine.completeRelationshipEvening(
      state,
      girlId: 'kim_seoa',
      activity: RelationshipActivity.conversation,
      choiceId: 'ignore_record',
    );
    expect(negative.success, isTrue);
    expect(negative.affectionAfter, 1);
    expect(negative.affectionDelta, 0);

    final nextDay = state.copyWith(day: 2);
    final locked = engine.completeRelationshipEvening(
      nextDay,
      girlId: 'kim_seoa',
      activity: RelationshipActivity.date,
      choiceId: 'choose_together',
    );
    expect(locked.success, isFalse);
    expect(locked.message, contains('호감도 20'));
  });

  test('crossing 20 unlocks date and date count is persisted', () {
    final base = engine.createNewGame('관계 테스트', worldSeed: 'relation-4');
    final preparedGirls = <String, GirlRelationshipProgress>{
      ...base.relationships.girls,
      'kim_seoa': const GirlRelationshipProgress(affection: 19),
    };
    final prepared = base.copyWith(
      relationships: base.relationships.copyWith(girls: preparedGirls),
    );
    final unlocked = engine.completeRelationshipEvening(
      prepared,
      girlId: 'kim_seoa',
      activity: RelationshipActivity.conversation,
      choiceId: 'rebuild_together',
    );
    expect(unlocked.success, isTrue);
    expect(unlocked.dateJustUnlocked, isTrue);
    expect(unlocked.affectionAfter, 24);

    final dateResult = engine.completeRelationshipEvening(
      unlocked.state.copyWith(day: 2),
      girlId: 'kim_seoa',
      activity: RelationshipActivity.date,
      choiceId: 'choose_together',
    );
    expect(dateResult.success, isTrue);
    expect(dateResult.affectionAfter, 32);
    expect(dateResult.state.relationships.progressFor('kim_seoa').dateCount, 1);
    expect(
      dateResult.state.relationships.memories.last.activity,
      RelationshipActivity.date,
    );
  });

  test(
    'relationship state round-trips and old saves receive eight defaults',
    () {
      final base = engine.createNewGame('관계 테스트', worldSeed: 'relation-5');
      final result = engine.completeRelationshipEvening(
        base,
        girlId: 'park_haeun',
        activity: RelationshipActivity.conversation,
        choiceId: 'ask_need',
      );
      final restored = GameState.fromJson(result.state.toJson());
      expect(
        restored.relationships.toJson(),
        result.state.relationships.toJson(),
      );

      final oldJson = Map<String, dynamic>.from(base.toJson())
        ..remove('relationships')
        ..['version'] = 21;
      final migrated = engine.migrate(oldJson);
      expect(migrated.version, GameState.schemaVersion);
      expect(migrated.relationships.girls.length, 8);
      expect(migrated.relationships.progressFor('park_haeun').affection, 1);
    },
  );

  test('rest closes the evening without changing any affection', () {
    final state = engine.createNewGame('관계 테스트', worldSeed: 'relation-6');
    final result = engine.restDuringRelationshipEvening(state);

    expect(result.success, isTrue);
    expect(result.state.relationships.lastEveningEventDay, state.day);
    expect(
      result.state.relationships.girls.values
          .map((item) => item.affection)
          .toSet(),
      <int>{1},
    );
  });
}
