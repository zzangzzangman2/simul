import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/character_profile.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/relationship_state.dart';
import 'package:millennium_capital/main.dart';

void main() {
  const engine = GameEngine();

  Future<void> setPhoneSurface(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  test('character profiles keep ten distinct MBTI assignments', () {
    expect(cohortCharacterProfiles, hasLength(10));
    expect(
      cohortCharacterProfiles.map((profile) => profile.mbti).toSet(),
      hasLength(10),
    );
    expect(cohortCharacterProfileById('kim_hakjun')?.mbti, 'ISTJ');
    expect(cohortCharacterProfileById('han_seoyoon')?.mbti, 'INFJ');
    expect(cohortCharacterProfileById('kim_hakjun')?.age, 14);
    expect(cohortCharacterProfileById('han_seoyoon')?.age, 23);
    expect(cohortCharacterProfileById('kim_seoa')?.birthdayLabel, '1987.02.12');
    expect(
      cohortCharacterProfileById('kim_seoa')?.ageLabelAt(DateTime(2001, 1, 1)),
      '15살',
    );
    expect(
      cohortCharacterProfileById('han_seoyoon')?.birthdayLabel,
      '1978.04.09',
    );
  });

  testWidgets('character directory opens a card and portrait detail', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final state = engine.createNewGame('관계 UI', worldSeed: 'relation-ui-1');

    await tester.pumpWidget(
      MaterialApp(home: RelationshipStatusScreen(state: state)),
    );
    await tester.pumpAndSettle();

    expect(find.text('캐릭터'), findsOneWidget);
    expect(find.byKey(const Key('character-card-grid')), findsOneWidget);
    expect(find.byKey(const Key('character-card-kim_seoa')), findsOneWidget);
    final portraitZoom = tester.widget<Transform>(
      find.byKey(const Key('character-card-portrait-zoom-kim_seoa')),
    );
    expect(portraitZoom.transform.entry(0, 0), closeTo(1.42, 0.001));
    final portrait = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('character-card-portrait-zoom-kim_seoa')),
        matching: find.byType(Image),
      ),
    );
    expect(portrait.filterQuality, FilterQuality.high);
    expect(portrait.isAntiAlias, isTrue);
    final portraitRegion = tester.getRect(
      find.byKey(const Key('character-card-portrait-region-kim_seoa')),
    );
    final infoRegion = tester.getRect(
      find.byKey(const Key('character-card-info-kim_seoa')),
    );
    expect(portraitRegion.bottom, lessThanOrEqualTo(infoRegion.top));

    await tester.tap(find.byKey(const Key('character-card-kim_seoa')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('character-card-screen-kim_seoa')),
      findsOneWidget,
    );
    expect(find.text('초상화를 눌러 상세 프로필 보기'), findsOneWidget);
    expect(find.text('현재 나이'), findsOneWidget);
    expect(find.text('생일'), findsOneWidget);
    expect(find.text('현재 호감도'), findsOneWidget);
    expect(find.text('고유 능력'), findsOneWidget);
    expect(find.text('1987.02.12'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('relationship-affection-kim_seoa')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const Key('relationship-affection-kim_seoa')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('cohort-investor-assets-kim_seoa')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const Key('cohort-investor-assets-kim_seoa')),
      findsOneWidget,
    );

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('character-card-portrait-kim_seoa')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('character-detail-screen-kim_seoa')),
      findsOneWidget,
    );
    expect(find.text('성격'), findsOneWidget);
    expect(find.text('좋아하는 것'), findsOneWidget);
    expect(find.text('14살'), findsOneWidget);
    expect(find.text('1987.02.12'), findsOneWidget);
    expect(find.text('ISFJ'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('투자를 보는 기준'),
      260,
      scrollable: find.descendant(
        of: find.byKey(const Key('character-detail-list-kim_seoa')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('투자를 보는 기준'), findsOneWidget);
  });

  testWidgets('directory exposes Hakjun and teacher cards', (tester) async {
    await setPhoneSurface(tester);
    final state = engine.createNewGame('인물 카드 UI', worldSeed: 'character-ui-1');

    await tester.pumpWidget(
      MaterialApp(home: RelationshipStatusScreen(state: state)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('character-card-han_seoyoon')),
      260,
      scrollable: find.descendant(
        of: find.byKey(const Key('character-card-grid')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('character-card-kim_hakjun')), findsOneWidget);
    expect(find.byKey(const Key('character-card-han_seoyoon')), findsOneWidget);

    await tester.tap(find.byKey(const Key('character-card-han_seoyoon')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('character-card-screen-han_seoyoon')),
      findsOneWidget,
    );
    expect(find.text('INFJ'), findsWidgets);
    expect(find.text('23세'), findsWidgets);
    expect(find.text('1978.04.09'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('운영관은 10인 투자 순위 참가자가 아니어서 개인 자산을 공개하지 않습니다.'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('운영관은 10인 투자 순위 참가자가 아니어서 개인 자산을 공개하지 않습니다.'),
      findsOneWidget,
    );
  });

  testWidgets('ten character cards fit the 360 by 800 mobile minimum', (
    tester,
  ) async {
    await setPhoneSurface(tester, size: const Size(360, 800));
    final state = engine.createNewGame(
      '인물 카드 최소 화면',
      worldSeed: 'character-ui-360',
    );

    await tester.pumpWidget(
      MaterialApp(home: RelationshipStatusScreen(state: state)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('character-card-han_seoyoon')),
      240,
      scrollable: find.descendant(
        of: find.byKey(const Key('character-card-grid')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('character-card-han_seoyoon')), findsOneWidget);
    expect(tester.takeException(), isNull);
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
  testWidgets('messenger returns without consuming relationship time', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final state = engine.createNewGame(
      '메신저 관계 UI',
      worldSeed: 'relationship-messenger-ui',
    );
    var messengerOpens = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: RelationshipEveningScreen(
          state: state,
          onOpenMessenger: () async {
            messengerOpens += 1;
            return state;
          },
          onComplete: (girlId, activity, choiceId) async =>
              engine.completeRelationshipEvening(
                state,
                girlId: girlId,
                activity: activity,
                choiceId: choiceId,
              ),
          onRest: () async => engine.restDuringRelationshipEvening(state),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('relationship-open-messenger-button')),
    );
    await tester.pumpAndSettle();

    expect(messengerOpens, 1);
    expect(state.relationships.completedEveningForDay(state.day), isFalse);
    expect(find.byType(RelationshipEveningScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('affection 20 opens a public outing only on weekends', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final base = engine.createNewGame(
      '주말 외출 UI',
      worldSeed: 'relationship-weekend-ui',
    );
    var weekendDay = base.day;
    while (!relationshipOutingAvailableOn(base.dateForDay(weekendDay))) {
      weekendDay += 1;
    }
    var state = base.copyWith(
      day: weekendDay,
      relationships: base.relationships.copyWith(
        girls: <String, GirlRelationshipProgress>{
          ...base.relationships.girls,
          'kim_seoa': const GirlRelationshipProgress(affection: 20),
        },
      ),
    );

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

    expect(find.textContaining('주식시장이 쉬는 주말'), findsOneWidget);
    await tester.tap(find.byKey(const Key('relationship-select-kim_seoa')));
    await tester.pumpAndSettle();

    expect(find.text('주말 외출하기'), findsOneWidget);
    final outing = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const Key('relationship-date-button')),
        matching: find.byType(InkWell),
      ),
    );
    expect(outing.onTap, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
