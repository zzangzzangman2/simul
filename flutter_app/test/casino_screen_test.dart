import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/casino_state.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/main.dart';

void main() {
  const engine = GameEngine();

  testWidgets('casino fits 360px and exposes six real table games', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final day =
        DateTime(2010, 1, 4).difference(DateTime(2000, 1, 1)).inDays + 1;
    var state = engine
        .createNewGame(
          '카지노 화면 테스트',
          initialCash: 10000000,
          worldSeed: 'casino-screen-test',
        )
        .copyWith(
          day: day,
          marketMinute: krxCloseMinute,
          brokerageCash: 0,
          decisions: const [],
        );

    Future<CasinoActionResult> persist(CasinoActionResult result) async {
      if (result.success) {
        state = result.state.copyWith(
          marketMinute: advanceGameTime(
            state.marketMinute,
            result.minutesElapsed,
          ),
        );
        return result.withState(state);
      }
      return result;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: CasinoScreen(
          state: state,
          onPlayRound: (bet) => persist(engine.playCasinoRound(state, bet)),
          onStartBlackjack: (stake) =>
              persist(engine.startCasinoBlackjack(state, stake)),
          onBlackjackAction: (action) =>
              persist(engine.actCasinoBlackjack(state, action)),
          onCrapsRoll: () => persist(engine.rollCasinoCraps(state)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('casino-screen')), findsOneWidget);
    for (final game in CasinoGameType.values) {
      expect(find.byKey(Key('casino-game-${game.name}')), findsOneWidget);
    }
    expect(find.byKey(const Key('casino-finish-evening')), findsNothing);
    expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('casino-rules')));
    await tester.pumpAndSettle();
    expect(find.textContaining('확정 이익의 20%'), findsOneWidget);
    expect(find.textContaining('반환 원금과 푸시에는 부과하지 않으며'), findsOneWidget);
    expect(find.text('게임별 핵심 규칙'), findsOneWidget);
    expect(find.textContaining('딜러는 17에 스탠드'), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-rules-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('casino-game-baccarat')));
    await tester.pumpAndSettle();
    expect(find.text('바카라'), findsWidgets);
    expect(find.byKey(const Key('casino-play-round')), findsOneWidget);
    expect(find.byKey(const Key('casino-live-table-stage')), findsOneWidget);
    expect(find.text('LIVE · 여성 딜러 CAM 03'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('casino-play-round')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-play-round')));
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byKey(const Key('casino-dealer-deal-hand')), findsOneWidget);
    expect(find.byKey(const Key('casino-flying-card')), findsOneWidget);
    final card = tester.widget<Positioned>(
      find.byKey(const Key('casino-flying-card')),
    );
    final hand = tester.widget<Positioned>(
      find.byKey(const Key('casino-dealer-deal-hand')),
    );
    expect(card.left! + 23, closeTo(hand.left! + 74, 0.5));
    expect(card.top! + 32, closeTo(hand.top! + 202, 0.5));
    await tester.pumpAndSettle();
    expect(state.personalFinance.casino.totalRounds, 1);
    expect(state.marketMinute, krxCloseMinute + casinoRoundMinutes);
    expect(find.byKey(const Key('casino-finish-evening')), findsOneWidget);
    expect(find.text('그만하고 20:00으로 이동'), findsOneWidget);
    expect(find.text('최근 게임 원장'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blackjack deals and settles an interactive saved hand', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final day =
        DateTime(2010, 1, 4).difference(DateTime(2000, 1, 1)).inDays + 1;
    var state = engine
        .createNewGame(
          '블랙잭 화면 테스트',
          initialCash: 10000000,
          worldSeed: 'blackjack-screen-test',
        )
        .copyWith(
          day: day,
          marketMinute: krxCloseMinute,
          brokerageCash: 0,
          decisions: const [],
        );

    Future<CasinoActionResult> apply(CasinoActionResult result) async {
      if (result.success) state = result.state;
      return result;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: CasinoScreen(
          state: state,
          onPlayRound: (bet) => apply(engine.playCasinoRound(state, bet)),
          onStartBlackjack: (stake) =>
              apply(engine.startCasinoBlackjack(state, stake)),
          onBlackjackAction: (action) =>
              apply(engine.actCasinoBlackjack(state, action)),
          onCrapsRoll: () => apply(engine.rollCasinoCraps(state)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-game-blackjack')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('casino-blackjack-deal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-blackjack-deal')));
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byKey(const Key('casino-dealer-deal-hand')), findsOneWidget);
    await tester.pumpAndSettle();

    expect(state.personalFinance.casino.activeBlackjack, isNotNull);
    expect(find.byKey(const Key('casino-blackjack-stand')), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('casino-blackjack-stand')), findsOneWidget);
    expect(find.textContaining('먼저 정산'), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-blackjack-stand')));
    await tester.pumpAndSettle();

    expect(state.personalFinance.casino.activeBlackjack, isNull);
    expect(
      state.personalFinance.casino.history.last.game,
      CasinoGameType.blackjack,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('each table exposes its own betting board and exact selections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MillenniumCapitalApp(casinoTestMode: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('casino-game-baccarat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('casino-bet-baccaratPlayer')), findsOneWidget);
    expect(find.byKey(const Key('casino-bet-baccaratTie')), findsOneWidget);
    expect(find.text('1.95×'), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('casino-game-roulette')));
    await tester.pumpAndSettle();
    expect(find.text('룰렛 베팅 보드'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('casino-bet-rouletteStraight')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-bet-rouletteStraight')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('casino-number-17')));
    await tester.tap(find.byKey(const Key('casino-number-17')));
    await tester.pumpAndSettle();
    expect(find.text('STRAIGHT UP · 17'), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('casino-game-craps')));
    await tester.pumpAndSettle();
    expect(find.text('라인에 칩을 놓으세요'), findsOneWidget);
    expect(find.byKey(const Key('casino-bet-crapsPassLine')), findsOneWidget);
    expect(find.byKey(const Key('casino-bet-crapsDontPass')), findsOneWidget);
    expect(find.textContaining('COME-OUT ROLL'), findsWidgets);
    await tester.tap(find.byKey(const Key('casino-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('casino-game-sicBo')));
    await tester.pumpAndSettle();
    expect(find.text('다이사이 배당판'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('casino-bet-sicBoSpecificTriple')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-bet-sicBoSpecificTriple')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('casino-number-6')), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-number-6')));
    await tester.pumpAndSettle();
    expect(find.text('SPECIFIC · 6'), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('casino-game-slots')));
    await tester.pumpAndSettle();
    expect(find.text('1라인 페이테이블'), findsOneWidget);
    expect(find.text('95×'), findsOneWidget);
    expect(find.text('체리 2개'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('casino test entry opens with isolated 100000 won test money', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MillenniumCapitalApp(casinoTestMode: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('casino-test-screen')), findsOneWidget);
    expect(find.text('데시멀 카지노 LIVE · TEST'), findsOneWidget);
    expect(find.text('15:00 · 테스트머니 100,000원'), findsOneWidget);
    expect(find.text('TEST MONEY'), findsOneWidget);

    await tester.tap(find.byKey(const Key('casino-game-baccarat')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('casino-play-round')));
    await tester.pumpAndSettle();

    final playButton = tester.widget<FilledButton>(
      find.byKey(const Key('casino-play-round')),
    );
    expect(playButton.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('casino-play-round')));
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byKey(const Key('casino-dealer-deal-hand')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('최근 게임 원장'), findsOneWidget);
    expect(find.textContaining('15:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
