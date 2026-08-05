import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/monthly_unlock_chapter.dart';
import 'package:millennium_capital/game/phone_messenger_state.dart';
import 'package:millennium_capital/game/relationship_state.dart';
import 'package:millennium_capital/game/story_state.dart';
import 'package:millennium_capital/game/weekday_activity.dart';

GameState _newMonthlyState({int day = 20}) {
  const engine = GameEngine();
  final story = StoryState.newDecimalPlayer(
    playerName: '민재',
    introChoice: 'stocks',
    startingTrait: StoryTrait.analysis,
    operatingPrinciple: OperatingPrinciple.reportLosses,
  );
  return engine
      .createNewGame(
        '월별 해금 테스트',
        story: story,
        worldSeed: 'monthly-unlock-test',
      )
      .copyWith(day: day, decisions: const []);
}

GameState _withProgress(GameState state, GirlRelationshipProgress progress) =>
    state.copyWith(
      relationships: state.relationships.copyWith(
        girls: <String, GirlRelationshipProgress>{
          ...state.relationships.girls,
          'kim_seoa': progress,
        },
      ),
    );

PhoneConversationMemory _memory({
  required String id,
  required int day,
  required String intent,
  required int affection,
  required int trust,
  required int closeness,
  int minute = 600,
}) => PhoneConversationMemory(
  id: id,
  contactId: 'kim_seoa',
  day: day,
  intent: intent,
  investmentSituation: 'flat',
  playerText: '테스트 메시지',
  replyText: '테스트 답장',
  affectionDelta: affection,
  trustDelta: trust,
  closenessDelta: closeness,
  marketMinute: minute,
);

void main() {
  test('monthly heroine tone resolves all five relationship states', () {
    final base = _newMonthlyState();

    expect(monthlyHeroineToneFor(base, 'kim_seoa'), MonthlyHeroineTone.awkward);

    final friendly = _withProgress(
      base,
      const GirlRelationshipProgress(
        affection: 30,
        trust: 20,
        closeness: 15,
        investmentRespect: 20,
      ),
    );
    expect(
      monthlyHeroineToneFor(friendly, 'kim_seoa'),
      MonthlyHeroineTone.friendly,
    );

    final close = _withProgress(
      base,
      const GirlRelationshipProgress(
        affection: 70,
        trust: 60,
        closeness: 50,
        investmentRespect: 45,
      ),
    );
    expect(monthlyHeroineToneFor(close, 'kim_seoa'), MonthlyHeroineTone.close);

    final strained = base.copyWith(
      phoneMessenger: base.phoneMessenger.copyWith(
        memories: <PhoneConversationMemory>[
          _memory(
            id: 'minor-conflict',
            day: 19,
            intent: 'boundary',
            affection: -1,
            trust: 0,
            closeness: 0,
          ),
        ],
      ),
    );
    expect(
      monthlyHeroineToneFor(strained, 'kim_seoa'),
      MonthlyHeroineTone.strained,
    );

    final fractured = base.copyWith(
      phoneMessenger: base.phoneMessenger.copyWith(
        memories: <PhoneConversationMemory>[
          _memory(
            id: 'major-conflict',
            day: 19,
            intent: 'boundary',
            affection: -2,
            trust: -3,
            closeness: -1,
          ),
        ],
      ),
    );
    expect(
      monthlyHeroineToneFor(fractured, 'kim_seoa'),
      MonthlyHeroineTone.fractured,
    );
  });

  test(
    'a later apology removes forced warmth and keeps a repaired awkward tone',
    () {
      final base = _newMonthlyState();
      final repaired = base.copyWith(
        phoneMessenger: base.phoneMessenger.copyWith(
          memories: <PhoneConversationMemory>[
            _memory(
              id: 'conflict',
              day: 18,
              intent: 'boundary',
              affection: -2,
              trust: -2,
              closeness: -1,
            ),
            _memory(
              id: 'apology',
              day: 19,
              intent: 'apology',
              affection: 1,
              trust: 1,
              closeness: 0,
            ),
          ],
        ),
      );

      expect(
        monthlyHeroineToneFor(repaired, 'kim_seoa'),
        MonthlyHeroineTone.awkward,
      );
    },
  );

  test('eight monthly chapters use eight heroines and five authored tones', () {
    expect(monthlyUnlockChapters, hasLength(8));
    expect(
      monthlyUnlockChapters.map((chapter) => chapter.heroineId).toSet(),
      hasLength(8),
    );
    for (final chapter in monthlyUnlockChapters) {
      expect(
        chapter.dialogueByTone.keys.toSet(),
        MonthlyHeroineTone.values.toSet(),
      );
      expect(
        chapter.dialogueByTone.values
            .map((dialogue) => dialogue.firstLine)
            .toSet(),
        hasLength(5),
      );
      expect(chapter.options, hasLength(3));
    }
  });

  test(
    'July operations and September rights choices stay locked until story',
    () {
      const engine = GameEngine();
      final initial = _newMonthlyState();
      expect(realEstateOperationsUnlocked(initial), isFalse);
      expect(advancedCorporateActionsUnlocked(initial), isFalse);
      expect(
        engine.renovateRealEstate(initial, 'missing-property').message,
        contains('7월'),
      );

      final july = monthlyUnlockChapters[5];
      final afterJuly = resolveMonthlyUnlockDecision(
        initial,
        monthlyUnlockDecisionId(july, MonthlyHeroineTone.awkward),
        monthlyUnlockOptionId(july, july.options.first.id),
      );
      expect(realEstateOperationsUnlocked(afterJuly), isTrue);
      expect(
        engine.renovateRealEstate(afterJuly, 'missing-property').message,
        isNot(contains('7월')),
      );

      final september = monthlyUnlockChapters[7];
      final afterSeptember = resolveMonthlyUnlockDecision(
        afterJuly,
        monthlyUnlockDecisionId(september, MonthlyHeroineTone.awkward),
        monthlyUnlockOptionId(september, september.options.first.id),
      );
      expect(advancedCorporateActionsUnlocked(afterSeptember), isTrue);
    },
  );

  test(
    'February chapter unlocks the bank and leaves a relationship-aware message',
    () {
      const engine = GameEngine();
      final januaryLast = _newMonthlyState(day: 31);
      expect(bankAccessUnlocked(januaryLast), isFalse);

      final februaryFirst = engine.advanceOneDay(januaryLast);
      final decision = februaryFirst.pendingDecisions.single;
      expect(decision.id, contains('-tone-awkward'));
      expect(decision.body, contains('장부 가져왔어'));

      final resolved = engine.resolveDecision(
        februaryFirst,
        decision.id,
        monthlyUnlockOptionId(
          monthlyUnlockChapters.first,
          'check_dates_together',
        ),
      );

      expect(bankAccessUnlocked(resolved), isTrue);
      expect(
        resolved.story.storyFlags['monthlyUnlockTone_2000-02-bank'],
        'awkward',
      );
      expect(
        resolved.relationships.progressFor('kim_seoa').trust,
        greaterThan(februaryFirst.relationships.progressFor('kim_seoa').trust),
      );
      expect(resolved.phoneMessenger.lastMessageFor('kim_seoa')!.read, isFalse);
      expect(
        resolved.phoneMessenger.lastMessageFor('kim_seoa')!.text,
        contains('다음에는'),
      );
    },
  );
}
