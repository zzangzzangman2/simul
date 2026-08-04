import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/main.dart';

void main() {
  const engine = GameEngine();

  GameState newState() =>
      engine.createNewGame('부동산 중개사 UI 테스트', initialCash: 100000000);

  Widget buildScreen({
    required GameState state,
    required bool realEstateOnly,
    double textScale = 1,
    Future<GameState> Function()? onCompleteTutorial,
  }) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: AssetSpendingScreen(
      key: ValueKey('asset-spending-$realEstateOnly-$textScale'),
      state: state,
      realEstateOnly: realEstateOnly,
      onPurchase: (_) async => FinanceActionResult(
        state: state,
        success: false,
        message: '테스트에서는 매입하지 않습니다.',
      ),
      onSellRealEstate: (_) async => FinanceActionResult(
        state: state,
        success: false,
        message: '테스트에서는 매각하지 않습니다.',
      ),
      onPlayChanceGame: (_) async => FinanceActionResult(
        state: state,
        success: false,
        message: '테스트에서는 확률 게임을 실행하지 않습니다.',
      ),
      onCompleteTutorial: onCompleteTutorial,
    ),
  );

  String realtorAssetName(WidgetTester tester) {
    final imageFinder = find.descendant(
      of: find.byKey(const Key('real-estate-realtor-character')),
      matching: find.byType(Image),
    );
    expect(imageFinder, findsOneWidget);
    final provider = tester.widget<Image>(imageFinder).image;
    expect(provider, isA<AssetImage>());
    return (provider as AssetImage).assetName;
  }

  testWidgets('부동산 전용 화면에서 중개사가 welcome으로 등장하고 안내 후 explain 포즈로 바뀐다', (
    tester,
  ) async {
    final state = newState();

    await tester.pumpWidget(buildScreen(state: state, realEstateOnly: false));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('real-estate-realtor-slot')), findsNothing);

    await tester.pumpWidget(buildScreen(state: state, realEstateOnly: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('real-estate-realtor-slot')), findsOneWidget);
    expect(
      find.byKey(const Key('real-estate-realtor-character')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('real-estate-realtor-welcome')),
      findsOneWidget,
    );
    expect(
      realtorAssetName(tester),
      'assets/images/character_realtor_welcome_v1.png',
    );

    await tester.tap(find.byKey(const Key('real-estate-realtor-consult')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('real-estate-realtor-explain')),
      findsOneWidget,
    );
    expect(
      realtorAssetName(tester),
      'assets/images/character_realtor_explain_v1.png',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('360x800과 글자 1.2배에서 중개사 카드와 조작 버튼이 화면 안에 유지된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = newState();

    await tester.pumpWidget(
      buildScreen(state: state, realEstateOnly: true, textScale: 1.2),
    );
    await tester.pumpAndSettle();

    final slot = find.byKey(const Key('real-estate-realtor-slot'));
    final character = find.byKey(const Key('real-estate-realtor-character'));
    final consult = find.byKey(const Key('real-estate-realtor-consult'));
    final dismiss = find.byKey(const Key('real-estate-realtor-dismiss'));
    expect(slot, findsOneWidget);
    expect(character, findsOneWidget);
    expect(consult.hitTestable(), findsOneWidget);
    expect(dismiss.hitTestable(), findsOneWidget);

    final slotRect = tester.getRect(slot);
    expect(slotRect.left, greaterThanOrEqualTo(0));
    expect(slotRect.right, lessThanOrEqualTo(360));
    expect(slotRect.top, greaterThanOrEqualTo(0));
    expect(slotRect.bottom, lessThanOrEqualTo(800));
    expect(
      realtorAssetName(tester),
      'assets/images/character_realtor_welcome_v1.png',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('부동산 튜토리얼은 여섯 자세로 매물·자금·위험·협상을 안내하고 완료를 저장한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var latest = newState();

    await tester.pumpWidget(
      buildScreen(
        state: latest,
        realEstateOnly: true,
        textScale: 1.2,
        onCompleteTutorial: () async {
          latest = engine.markRealEstateTutorialSeen(latest);
          return latest;
        },
      ),
    );
    await tester.pumpAndSettle();

    String tutorialAsset() {
      final image = tester.widget<Image>(
        find.byKey(const Key('market-tutorial-student-upper-body')),
      );
      return (image.image as AssetImage).assetName;
    }

    Future<void> advanceStage({required bool usesTarget}) async {
      await tester.tap(find.byKey(const Key('real-estate-tutorial-next')));
      await tester.pumpAndSettle();
      final actionKey = usesTarget
          ? const Key('real-estate-tutorial-target')
          : const Key('real-estate-tutorial-next');
      expect(find.byKey(actionKey), findsOneWidget);
      await tester.tap(find.byKey(actionKey));
      await tester.pumpAndSettle();
    }

    expect(
      find.byKey(const Key('real-estate-tutorial-overlay')),
      findsOneWidget,
    );
    expect(tutorialAsset(), 'assets/images/character_realtor_welcome_v1.png');

    await advanceStage(usesTarget: false);
    expect(tutorialAsset(), 'assets/images/character_realtor_explain_v1.png');
    await advanceStage(usesTarget: true);
    expect(tutorialAsset(), 'assets/images/character_realtor_finance_v1.png');
    await advanceStage(usesTarget: true);
    expect(tutorialAsset(), 'assets/images/character_realtor_concerned_v1.png');
    await advanceStage(usesTarget: false);
    expect(tutorialAsset(), 'assets/images/character_realtor_negotiate_v1.png');
    await advanceStage(usesTarget: false);
    expect(tutorialAsset(), 'assets/images/character_realtor_approve_v1.png');
    await advanceStage(usesTarget: false);

    expect(latest.story.realEstateTutorialSeen, isTrue);
    expect(find.byKey(const Key('real-estate-tutorial-overlay')), findsNothing);
    expect(
      find.byKey(const Key('real-estate-realtor-approve')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
