import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/relationship_state.dart';
import 'package:millennium_capital/game/story_state.dart';
import 'package:millennium_capital/main.dart';

Widget _testHub({
  required GameState state,
  required VoidCallback onOpenMarket,
  required VoidCallback onOpenRealEstate,
  required VoidCallback onOpenBank,
  bool disableAnimations = false,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(
      body: ApartmentHubScreen(
        state: state,
        onOpenMarket: onOpenMarket,
        onOpenRealEstate: onOpenRealEstate,
        onOpenBank: onOpenBank,
        onOpenDecisions: () {},
        onOpenLedger: () {},
        onOpenOrganization: () {},
        onOpenRelationships: () {},
        onOpenMessenger: () {},
        onOpenCalendar: () {},
        onOpenHomeImprovements: () {},
        onOpenWork: () {},
        activeSaveSlot: 1,
        lastSavedAt: null,
        onOpenGameMenu: () {},
        onAdvanceHour: () {},
        onAdvanceDay: () {},
        onAdvanceBatch: () {},
        onOpenEnding: () {},
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'lounge rotates heroines daily and changes pose copy and motion by affection',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const engine = GameEngine();
      final story = StoryState.newDecimalPlayer(
        playerName: '민재',
        introChoice: 'stocks',
        startingTrait: StoryTrait.analysis,
        operatingPrinciple: OperatingPrinciple.reportLosses,
      );
      final lowState = engine
          .createNewGame(
            '일일 로비 테스트',
            story: story,
            worldSeed: 'daily-lobby-rotation',
          )
          .copyWith(day: 4, decisions: const []);

      await tester.pumpWidget(
        _testHub(
          state: lowState,
          onOpenMarket: () {},
          onOpenRealEstate: () {},
          onOpenBank: () {},
        ),
      );
      await tester.pumpAndSettle();

      final firstName = tester
          .widget<Text>(find.byKey(const Key('lobby-heroine-name')))
          .data!;
      final lowGreeting = tester
          .widget<Text>(find.byKey(const Key('lobby-heroine-greeting')))
          .data!;
      final lowDistance = tester
          .widget<AnimatedScale>(
            find.byKey(const Key('lobby-heroine-affection-distance')),
          )
          .scale;
      expect(find.text('새 동기'), findsOneWidget);
      expect(find.byKey(const Key('lobby-heroine-idle-image')), findsOneWidget);

      final closeRelationships = RelationshipState(
        girls: {
          for (final profile in cohortGirlProfiles)
            profile.id: const GirlRelationshipProgress(
              affection: 65,
              trust: 65,
              closeness: 65,
              investmentRespect: 65,
            ),
        },
      );
      final closeState = lowState.copyWith(relationships: closeRelationships);
      await tester.pumpWidget(
        _testHub(
          state: closeState,
          onOpenMarket: () {},
          onOpenRealEstate: () {},
          onOpenBank: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(const Key('lobby-heroine-name'))).data,
        firstName,
      );
      expect(find.text('마음을 아는 사이'), findsOneWidget);
      final closeDistance = tester
          .widget<AnimatedScale>(
            find.byKey(const Key('lobby-heroine-affection-distance')),
          )
          .scale;
      expect(closeDistance, greaterThan(lowDistance));
      expect(
        tester
            .widget<Text>(find.byKey(const Key('lobby-heroine-greeting')))
            .data,
        isNot(lowGreeting),
      );

      final profile = cohortGirlProfiles.singleWhere(
        (candidate) => candidate.name == firstName,
      );
      await tester.tap(find.byKey(Key('daily-lobby-heroine-${profile.id}')));
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        find.byKey(const Key('lobby-heroine-reaction-image')),
        findsOneWidget,
      );
      final motionBefore = tester
          .widget<Transform>(
            find.byKey(const Key('lobby-heroine-breathing-motion')),
          )
          .transform
          .storage
          .toList();
      await tester.pump(const Duration(milliseconds: 520));
      final motionAfter = tester
          .widget<Transform>(
            find.byKey(const Key('lobby-heroine-breathing-motion')),
          )
          .transform
          .storage
          .toList();
      expect(motionAfter, isNot(motionBefore));

      final nextDayState = closeState.copyWith(day: closeState.day + 1);
      await tester.pumpWidget(
        _testHub(
          state: nextDayState,
          onOpenMarket: () {},
          onOpenRealEstate: () {},
          onOpenBank: () {},
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('lobby-heroine-name'))).data,
        isNot(firstName),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all eight lobby heroines receive a fitted blink layer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const engine = GameEngine();
    final story = StoryState.newDecimalPlayer(
      playerName: '민재',
      introChoice: 'stocks',
      startingTrait: StoryTrait.analysis,
      operatingPrinciple: OperatingPrinciple.reportLosses,
    );
    final baseState = engine
        .createNewGame(
          'blink-layout-test',
          story: story,
          worldSeed: 'daily-lobby-eight-blinks',
        )
        .copyWith(day: 4, decisions: const []);
    final names = <String>{};

    for (var offset = 0; offset < cohortGirlProfiles.length; offset += 1) {
      await tester.pumpWidget(
        _testHub(
          state: baseState.copyWith(day: baseState.day + offset),
          onOpenMarket: () {},
          onOpenRealEstate: () {},
          onOpenBank: () {},
        ),
      );
      await tester.pump();
      names.add(
        tester.widget<Text>(find.byKey(const Key('lobby-heroine-name'))).data!,
      );
      expect(
        find.byKey(const Key('lobby-heroine-blink-overlay')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('lobby-heroine-touch-motion')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('lobby-heroine-affection-distance')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('lobby-heroine-idle-gesture-motion')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('lobby-heroine-gaze-motion')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('lobby-heroine-zone-reaction-motion')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('lobby-heroine-motion-frame-layer')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('lobby-ambient-background-motion')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('lobby-ambient-particles')), findsOneWidget);
      final profile = cohortGirlProfiles.singleWhere(
        (candidate) =>
            candidate.name ==
            tester
                .widget<Text>(find.byKey(const Key('lobby-heroine-name')))
                .data,
      );
      final motionSeed = profile.id.codeUnits.fold<int>(
        0,
        (value, unit) => (value * 31 + unit) & 0x7fffffff,
      );
      await tester.pump(Duration(milliseconds: 4200 + (motionSeed % 2800)));
      await tester.pump(const Duration(milliseconds: 520));
      final activeMotionAssets = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => image.image)
          .whereType<AssetImage>()
          .map((asset) => asset.assetName)
          .where((asset) => asset.contains('/10_lobby_'))
          .toList();
      expect(activeMotionAssets, isNotEmpty);
      expect(
        activeMotionAssets.every((asset) => asset.contains('/${profile.id}/')),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    }

    expect(names, hasLength(cohortGirlProfiles.length));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'heroine touch zones react differently and repeated taps set a boundary',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const engine = GameEngine();
      final story = StoryState.newDecimalPlayer(
        playerName: '민재',
        introChoice: 'stocks',
        startingTrait: StoryTrait.analysis,
        operatingPrinciple: OperatingPrinciple.reportLosses,
      );
      final state = engine
          .createNewGame(
            'lobby-touch-zone-test',
            story: story,
            worldSeed: 'lobby-touch-zones',
          )
          .copyWith(day: 4, decisions: const []);

      await tester.pumpWidget(
        _testHub(
          state: state,
          onOpenMarket: () {},
          onOpenRealEstate: () {},
          onOpenBank: () {},
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));

      final name = tester
          .widget<Text>(find.byKey(const Key('lobby-heroine-name')))
          .data!;
      final profile = cohortGirlProfiles.singleWhere(
        (candidate) => candidate.name == name,
      );
      final stageFinder = find.byKey(Key('daily-lobby-heroine-${profile.id}'));
      final rect = tester.getRect(stageFinder);

      await tester.tapAt(Offset(rect.center.dx, rect.top + rect.height * 0.2));
      await tester.pump(const Duration(milliseconds: 80));
      final faceLine = tester
          .widget<Text>(find.byKey(const Key('lobby-heroine-greeting')))
          .data!;
      expect(
        find.byKey(const Key('lobby-heroine-reaction-image')),
        findsOneWidget,
      );

      await tester.tapAt(Offset(rect.center.dx, rect.top + rect.height * 0.5));
      await tester.pump(const Duration(milliseconds: 80));
      final torsoLine = tester
          .widget<Text>(find.byKey(const Key('lobby-heroine-greeting')))
          .data!;
      expect(torsoLine, isNot(faceLine));

      final accessoryPoint = Offset(
        rect.center.dx,
        rect.top + rect.height * 0.82,
      );
      await tester.tapAt(accessoryPoint);
      await tester.pump(const Duration(milliseconds: 60));
      final accessoryLine = tester
          .widget<Text>(find.byKey(const Key('lobby-heroine-greeting')))
          .data!;
      expect(accessoryLine, isNot(torsoLine));
      await tester.tapAt(accessoryPoint);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(accessoryPoint);
      await tester.pump(const Duration(milliseconds: 60));
      final repeatedLine = tester
          .widget<Text>(find.byKey(const Key('lobby-heroine-greeting')))
          .data!;
      expect(repeatedLine, isNot(accessoryLine));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('blink timing is irregular and reduced motion keeps it still', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const engine = GameEngine();
    final story = StoryState.newDecimalPlayer(
      playerName: '민재',
      introChoice: 'stocks',
      startingTrait: StoryTrait.analysis,
      operatingPrinciple: OperatingPrinciple.reportLosses,
    );
    final state = engine
        .createNewGame(
          'blink-timing-test',
          story: story,
          worldSeed: 'lobby-blink-timing',
        )
        .copyWith(day: 4, decisions: const []);

    await tester.pumpWidget(
      _testHub(
        state: state,
        onOpenMarket: () {},
        onOpenRealEstate: () {},
        onOpenBank: () {},
      ),
    );
    await tester.pump();
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('lobby-heroine-blink-overlay')))
          .opacity,
      0,
    );
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('lobby-heroine-blink-overlay')))
          .opacity,
      greaterThan(0.7),
    );

    await tester.pumpWidget(
      _testHub(
        state: state,
        onOpenMarket: () {},
        onOpenRealEstate: () {},
        onOpenBank: () {},
        disableAnimations: true,
      ),
    );
    await tester.pump(const Duration(seconds: 7));
    expect(
      tester
          .widget<Opacity>(find.byKey(const Key('lobby-heroine-blink-overlay')))
          .opacity,
      0,
    );
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => image.image)
          .whereType<AssetImage>()
          .where((asset) => asset.assetName.contains('/10_lobby_')),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'new story shows bank and realtor as locked before introductions',
    (tester) async {
      const engine = GameEngine();
      final story = StoryState.newDecimalPlayer(
        playerName: '민재',
        introChoice: 'stocks',
        startingTrait: StoryTrait.analysis,
        operatingPrinciple: OperatingPrinciple.reportLosses,
      );
      final state = engine
          .createNewGame(
            '잠금 UI 테스트',
            story: story,
            worldSeed: 'facility-lock-ui',
          )
          .copyWith(day: 3, marketMinute: 15 * 60, decisions: const []);

      await tester.pumpWidget(
        _testHub(
          state: state,
          onOpenMarket: () {},
          onOpenRealEstate: () {},
          onOpenBank: () {},
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('apartment-day-guide')));
      await tester.pumpAndSettle();

      expect(find.textContaining('윤하린 은행원 소개 이야기 필요'), findsOneWidget);
      expect(find.textContaining('서하늘 공인중개사 소개 이야기 필요'), findsOneWidget);
      expect(
        tester
            .widget<InkWell>(find.byKey(const Key('weekday-evening-bank')))
            .onTap,
        isNull,
      );
      expect(
        tester
            .widget<InkWell>(
              find.byKey(const Key('weekday-evening-real_estate')),
            )
            .onTap,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('after close the hub offers only real-estate or bank', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const engine = GameEngine();
    final state = engine
        .createNewGame('평일 허브 테스트', worldSeed: 'weekday-hub')
        .copyWith(day: 3, marketMinute: 15 * 60 + 10, decisions: const []);
    var realEstateOpened = 0;

    await tester.pumpWidget(
      _testHub(
        state: state,
        onOpenMarket: () {},
        onOpenRealEstate: () => realEstateOpened += 1,
        onOpenBank: () {},
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('apartment-current-time')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('apartment-current-time'))).data,
      '15:10',
    );
    expect(find.textContaining('부동산 또는 은행'), findsOneWidget);

    await tester.tap(find.byKey(const Key('apartment-day-guide')));
    await tester.pumpAndSettle();

    expect(find.text('장 마감 후 저녁 업무'), findsOneWidget);
    expect(
      find.byKey(const Key('weekday-evening-real_estate')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('weekday-evening-bank')), findsOneWidget);
    expect(find.text('투자 원리 자율학습'), findsNothing);
    expect(find.text('생활공간 정리'), findsNothing);
    expect(find.text('짧은 산책과 휴식'), findsNothing);
    expect(find.textContaining('15:10 → 20:00'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('weekday-evening-real_estate')));
    await tester.pumpAndSettle();

    expect(realEstateOpened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('before close the guide opens the stock PC directly', (
    tester,
  ) async {
    const engine = GameEngine();
    final state = engine
        .createNewGame('장중 허브 테스트', worldSeed: 'weekday-stock')
        .copyWith(day: 3, marketMinute: 10 * 60, decisions: const []);
    var marketOpened = 0;

    await tester.pumpWidget(
      _testHub(
        state: state,
        onOpenMarket: () => marketOpened += 1,
        onOpenRealEstate: () {},
        onOpenBank: () {},
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('apartment-day-guide')));
    await tester.pump();

    expect(marketOpened, 1);
    expect(find.text('장 마감 후 저녁 업무'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening the bank from the evening choice commits 20:00 first', (
    tester,
  ) async {
    const engine = GameEngine();
    var latestState = engine
        .createNewGame('은행 저녁 연결 테스트', worldSeed: 'weekday-bank-route')
        .copyWith(day: 3, marketMinute: 15 * 60, decisions: const []);
    String? selectedActivity;

    await tester.pumpWidget(
      MaterialApp(
        home: OfficeScreen(
          state: latestState,
          stateReader: () => latestState,
          engine: engine,
          activeSaveSlot: 1,
          lastSavedAt: null,
          onManualSave: () async {},
          onReturnToTitle: () {},
          onAdvanceDay: () async => latestState,
          onSetMarketMinute: (_) async => latestState,
          onSaveMarketNotebook: (_, _) async => latestState,
          onResolveDecision: (_, _) async {},
          onRequestAcademyHelp: (_) async => latestState,
          onCompleteWeekdayActivity: (activityId) async {
            selectedActivity = activityId;
            final result = engine.completeWeekdayActivity(
              latestState,
              activityId,
            );
            latestState = result.state;
            return result;
          },
          onCompleteWork: (_) async => latestState,
          onExecuteTrade: (order) async =>
              engine.executeTrade(latestState, order),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('apartment-day-guide')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('weekday-evening-bank')));
    await tester.pumpAndSettle();

    expect(selectedActivity, 'bank');
    expect(latestState.marketMinute, 20 * 60);
    expect(find.byKey(const Key('bank-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
