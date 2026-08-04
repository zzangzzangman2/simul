import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/story_state.dart';
import 'package:millennium_capital/main.dart';

Widget _testHub({
  required GameState state,
  required VoidCallback onOpenMarket,
  required VoidCallback onOpenRealEstate,
  required VoidCallback onOpenBank,
}) => MaterialApp(
  home: Scaffold(
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
);

void main() {
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
