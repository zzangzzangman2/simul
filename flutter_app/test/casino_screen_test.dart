import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/casino_state.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/main.dart';

Future<void> _advanceCasinoWelcome(
  WidgetTester tester, {
  required bool hasChips,
}) async {
  expect(find.byKey(const Key('story-dialogue-panel')), findsOneWidget);
  expect(find.text('이안'), findsOneWidget);
  expect(find.text('오빠, 오늘도 왔네.'), findsOneWidget);
  expect(find.textContaining('20세'), findsNothing);
  expect(find.byKey(const Key('casino-entry-continue')), findsNothing);
  final dialogueRect = tester.getRect(
    find.byKey(const Key('story-dialogue-panel')),
  );
  final screenRect = tester.getRect(find.byKey(const Key('casino-screen')));
  expect(dialogueRect.height, closeTo(154, 1));
  expect(dialogueRect.bottom, closeTo(screenRect.bottom - 44, 1));
  final backgroundTransform = tester.widget<Transform>(
    find.byKey(const Key('casino-background-transform')),
  );
  expect(backgroundTransform.transform.storage[0], closeTo(1.16, 0.001));
  expect(
    find.byKey(const Key('casino-welcome-fullscreen-continue')),
    findsOneWidget,
  );
  await tester.tapAt(screenRect.center);
  await tester.pumpAndSettle();
  expect(
    find.text(
      hasChips
          ? '보유 칩으로 온라인 테이블에 가거나, 국가계좌 돈을 칩으로 더 바꿀 수 있어.'
          : '지금은 칩이 하나도 없어. 먼저 국가계좌 돈을 칩으로 바꿔야 테이블에 들어갈 수 있어.',
    ),
    findsOneWidget,
  );
  expect(find.byKey(const Key('casino-entry-continue')), findsOneWidget);
  expect(find.byKey(const Key('casino-entry-exchange')), findsOneWidget);
  expect(find.text(hasChips ? '온라인 테이블' : '칩 교환 후 접속'), findsOneWidget);
  final tableButton = tester.widget<FilledButton>(
    find.byKey(const Key('casino-entry-continue')),
  );
  expect(tableButton.onPressed, hasChips ? isNotNull : isNull);
}

void _expectCasualDealerLine(WidgetTester tester) {
  final line = tester
      .widget<Text>(find.byKey(const Key('story-line-text')))
      .data!;
  expect(line.startsWith('오빠,'), isFalse);
  expect(
    RegExp(r'(주세요|드립니다|드릴게요|셨어요|셨네요|습니다|해요|네요|예요|이에요)').hasMatch(line),
    isFalse,
  );
}

void main() {
  const engine = GameEngine();

  testWidgets('home PC registers a casino visit after the stock close', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final day =
        DateTime(2000, 1, 3).difference(DateTime(2000, 1, 1)).inDays + 1;
    final state = engine
        .markNationalNetworkBriefingSeen(
          engine.markMarketTutorialSeen(
            engine.createNewGame(
              '카지노 PC 연결 테스트',
              initialCash: 1000000,
              worldSeed: 'casino-home-computer',
            ),
          ),
        )
        .copyWith(day: day, marketMinute: krxCloseMinute, decisions: const []);
    var casinoOpenCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: HomeComputerScreen(
          state: state,
          onOpenStockMarket: (current) async => current,
          onOpenCompanyManagement: (current) async => current,
          onOpenRealEstate: (current) async => current,
          onOpenBusiness: (current) async => current,
          onOpenCasino: (current) async {
            casinoOpenCount += 1;
            return current;
          },
          onOpenHorseRace: (current) async => current,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final app = find.byKey(const Key('computer-casino-live-app'));
    expect(app, findsOneWidget);
    expect(find.text('접속 가능 · 1판 30분'), findsOneWidget);
    await tester.tap(app);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('after-market-casino-gateway')),
      findsOneWidget,
    );
    expect(find.textContaining('현장 이동과 외부 결제는 없고'), findsOneWidget);
    expect(casinoOpenCount, 0);
    await tester.tap(find.byKey(const Key('after-market-casino-confirm')));
    await tester.pumpAndSettle();
    expect(casinoOpenCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('casino welcome advances from the character during typing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MillenniumCapitalApp(casinoTestMode: true));
    await tester.pump(const Duration(milliseconds: 60));
    final screenRect = tester.getRect(find.byKey(const Key('casino-screen')));
    await tester.tapAt(screenRect.center);
    await tester.pumpAndSettle();

    expect(
      find.text('지금은 칩이 하나도 없어. 먼저 국가계좌 돈을 칩으로 바꿔야 테이블에 들어갈 수 있어.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('casino-entry-exchange')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('casino fits 360px and exposes six real table games', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final day =
        DateTime(2000, 1, 3).difference(DateTime(2000, 1, 1)).inDays + 1;
    var state = engine
        .markNationalNetworkBriefingSeen(
          engine.createNewGame(
            '카지노 화면 테스트',
            initialCash: 10000000,
            worldSeed: 'casino-screen-test',
          ),
        )
        .copyWith(day: day, marketMinute: krxCloseMinute, decisions: const []);

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
          onExchangeChips: (amount) =>
              persist(engine.exchangeCasinoChips(state, amount)),
          onCashOutChips: () => persist(engine.cashOutCasinoChips(state)),
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
    await _advanceCasinoWelcome(tester, hasChips: false);
    expect(find.byKey(const Key('casino-game-baccarat')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('casino-entry-exchange')));
    await tester.tap(find.byKey(const Key('casino-entry-exchange')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('casino-exchange-confirm')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('casino-exchange-confirm')),
    );
    await tester.tap(find.byKey(const Key('casino-exchange-confirm')));
    await tester.pumpAndSettle();
    expect(state.personalFinance.casino.chipBalance, 100000);
    expect(find.byKey(const Key('casino-handover-accept')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('casino-handover-accept')));
    await tester.tap(find.byKey(const Key('casino-handover-accept')));
    await tester.pumpAndSettle();

    for (final game in CasinoGameType.values) {
      expect(find.byKey(Key('casino-game-${game.name}')), findsOneWidget);
    }
    expect(find.byKey(const Key('casino-go-offline')), findsOneWidget);
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
    expect(find.text('바카라'), findsOneWidget);
    expect(find.byKey(const Key('casino-header')), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const Key('casino-game-panel'))).dy,
      lessThanOrEqualTo(48),
    );
    final gameMoneyStatus = tester.widget<Text>(
      find.byKey(const Key('casino-game-money-status')),
    );
    expect(gameMoneyStatus.data, contains('15:00'));
    expect(gameMoneyStatus.data, contains('국가계좌 9,900,000원'));
    expect(gameMoneyStatus.data, contains('칩 100,000'));
    expect(find.byKey(const Key('casino-stake-2000')), findsOneWidget);
    expect(find.byKey(const Key('casino-stake-5000')), findsOneWidget);
    expect(find.byKey(const Key('casino-stake-10000')), findsOneWidget);
    expect(find.byKey(const Key('casino-stake-30000')), findsOneWidget);
    expect(find.text('2%'), findsOneWidget);
    expect(find.text('5%'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('500×4'), findsOneWidget);
    expect(find.text('1K×5'), findsOneWidget);
    expect(find.text('5K×2'), findsOneWidget);
    expect(find.text('10K×3'), findsOneWidget);
    expect(find.text('2,000칩'), findsWidgets);
    expect(find.text('보유 100,000칩 · 23개'), findsOneWidget);
    expect(find.byKey(const Key('casino-chip-pile-500-4')), findsOneWidget);
    expect(find.byKey(const Key('casino-chip-pile-1000-8')), findsOneWidget);
    expect(find.byKey(const Key('casino-chip-pile-5000-4')), findsOneWidget);
    expect(find.byKey(const Key('casino-chip-pile-10000-7')), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-stake-30000')));
    await tester.pump();
    expect(find.text('PLACE BET · 30,000칩'), findsOneWidget);
    expect(
      find.byKey(const Key('casino-table-chip-stack-10000-3')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('casino-play-round')), findsOneWidget);
    expect(find.byKey(const Key('casino-live-table-stage')), findsOneWidget);
    expect(
      find.byKey(const Key('casino-live-table-image-baccarat')),
      findsOneWidget,
    );
    expect(find.text('LIVE · 여성 딜러 CAM 03'), findsOneWidget);
    final gameDialogueRect = tester.getRect(
      find.byKey(const Key('story-dialogue-panel')),
    );
    final gameScreenRect = tester.getRect(
      find.byKey(const Key('casino-screen')),
    );
    final liveTableRect = tester.getRect(
      find.byKey(const Key('casino-live-table-stage')),
    );
    final gameScrollRect = tester.getRect(
      find.byKey(const Key('casino-scroll')),
    );
    final playButtonRect = tester.getRect(
      find.byKey(const Key('casino-play-round')),
    );
    expect(gameDialogueRect.height, lessThanOrEqualTo(112));
    expect(gameDialogueRect.bottom, closeTo(gameScreenRect.bottom, 1));
    expect(gameScrollRect.bottom, lessThanOrEqualTo(gameDialogueRect.top));
    expect(gameDialogueRect.top - gameScrollRect.bottom, lessThanOrEqualTo(12));
    expect(liveTableRect.top, lessThan(70));
    expect(liveTableRect.bottom, lessThan(gameDialogueRect.top));
    expect(playButtonRect.top, greaterThan(liveTableRect.bottom));
    expect(playButtonRect.top - liveTableRect.bottom, lessThanOrEqualTo(8));
    expect(playButtonRect.bottom, lessThan(gameDialogueRect.top));
    expect(find.text('딜러 메시지'), findsNothing);
    final dealerLineBefore = tester
        .widget<Text>(find.byKey(const Key('story-line-text')))
        .data;

    expect(
      tester.getBottomLeft(find.byKey(const Key('casino-play-round'))).dy,
      lessThanOrEqualTo(gameDialogueRect.top),
    );
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
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('카드를 나눠'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('casino-round-result-toast')), findsOneWidget);
    final playLabel = tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const Key('casino-play-round')),
            matching: find.byType(Text),
          ),
        )
        .data!;
    final displayedStake = int.parse(
      RegExp(r'([\d,]+)칩').firstMatch(playLabel)!.group(1)!.replaceAll(',', ''),
    );
    expect(
      isValidCasinoChipStake(
        displayedStake,
        state.personalFinance.casino.chipBalance,
      ),
      isTrue,
    );
    final dealerReaction = tester
        .widget<Text>(find.byKey(const Key('story-line-text')))
        .data;
    expect(dealerReaction, contains('칩'));
    expect(dealerReaction!.startsWith('오빠,'), isFalse);
    expect(dealerReaction, isNot(dealerLineBefore));
    expect(
      tester
          .getBottomLeft(find.byKey(const Key('casino-round-result-toast')))
          .dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('casino-chip-stack'))).dy,
      ),
    );
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.byKey(const Key('casino-round-result-toast')), findsNothing);
    expect(state.personalFinance.casino.totalRounds, 1);
    expect(state.marketMinute, krxCloseMinute + casinoRoundMinutes);
    final otherGamesRect = tester.getRect(
      find.byKey(const Key('casino-other-games')),
    );
    final offlineRect = tester.getRect(
      find.byKey(const Key('casino-go-offline')),
    );
    expect(find.text('다른 게임 하러가기'), findsOneWidget);
    expect(find.text('접속 종료'), findsOneWidget);
    expect(otherGamesRect.top, closeTo(offlineRect.top, 1));
    expect(otherGamesRect.width, closeTo(offlineRect.width, 1));
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
        DateTime(2000, 1, 3).difference(DateTime(2000, 1, 1)).inDays + 1;
    var state = engine
        .createNewGame(
          '블랙잭 화면 테스트',
          initialCash: 10000000,
          worldSeed: 'blackjack-screen-test',
        )
        .copyWith(day: day, marketMinute: krxCloseMinute, decisions: const []);
    state = engine.exchangeCasinoChips(state, 100000).state;

    Future<CasinoActionResult> apply(CasinoActionResult result) async {
      if (result.success) state = result.state;
      return result;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: CasinoScreen(
          state: state,
          testMode: true,
          onExchangeChips: (amount) =>
              apply(engine.exchangeCasinoChips(state, amount)),
          onCashOutChips: () => apply(engine.cashOutCasinoChips(state)),
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
    await _advanceCasinoWelcome(tester, hasChips: true);
    await tester.ensureVisible(find.byKey(const Key('casino-entry-continue')));
    await tester.tap(find.byKey(const Key('casino-entry-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-game-blackjack')));
    await tester.pumpAndSettle();
    _expectCasualDealerLine(tester);
    expect(
      find.byKey(const Key('casino-live-table-image-blackjack')),
      findsOneWidget,
    );
    expect(find.text('다른 게임 하러가기'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('casino-blackjack-deal')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-blackjack-deal')));
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.byKey(const Key('casino-dealer-deal-hand')), findsOneWidget);
    await tester.pumpAndSettle();

    expect(state.personalFinance.casino.activeBlackjack, isNotNull);
    expect(find.byKey(const Key('casino-blackjack-stand')), findsOneWidget);
    for (var index = 0; index < 3; index++) {
      final icon = find.byKey(Key('casino-blackjack-action-art-$index'));
      expect(icon, findsOneWidget);
      final image = tester.widget<Image>(
        find.descendant(of: icon, matching: find.byType(Image)),
      );
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/casino/blackjack_action_atlas_v1.png',
      );
    }
    final lockedOtherGames = tester.widget<OutlinedButton>(
      find.byKey(const Key('casino-blackjack-other-games')),
    );
    expect(lockedOtherGames.onPressed, isNull);
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
    expect(find.text('다른 게임 하러가기'), findsOneWidget);
    final blackjackResultLine = tester
        .widget<Text>(find.byKey(const Key('story-line-text')))
        .data!;
    expect(blackjackResultLine, contains('칩'));
    await tester.ensureVisible(
      find.byKey(const Key('casino-blackjack-other-games')),
    );
    await tester.tap(find.byKey(const Key('casino-blackjack-other-games')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('casino-game-baccarat')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each table uses a compact rail and opens exact selections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MillenniumCapitalApp(casinoTestMode: true));
    await tester.pumpAndSettle();

    await _advanceCasinoWelcome(tester, hasChips: false);
    await tester.ensureVisible(find.byKey(const Key('casino-entry-exchange')));
    await tester.tap(find.byKey(const Key('casino-entry-exchange')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('casino-exchange-confirm')),
    );
    await tester.tap(find.byKey(const Key('casino-exchange-confirm')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('casino-handover-accept')));
    await tester.tap(find.byKey(const Key('casino-handover-accept')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('casino-game-baccarat')));
    await tester.pumpAndSettle();
    _expectCasualDealerLine(tester);
    expect(
      find.byKey(const Key('casino-live-table-image-baccarat')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('casino-quick-bet-baccaratPlayer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('casino-quick-bet-baccaratTie')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('casino-quick-bet-baccaratPlayer')))
          .height,
      48,
    );
    expect(find.text('1.95×'), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-open-bet-picker-baccarat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('casino-bet-baccaratPlayer')), findsOneWidget);
    expect(find.byKey(const Key('casino-bet-baccaratTie')), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-confirm-bet-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-back')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('casino-game-roulette')));
    await tester.tap(find.byKey(const Key('casino-game-roulette')));
    await tester.pumpAndSettle();
    _expectCasualDealerLine(tester);
    expect(
      find.byKey(const Key('casino-live-table-image-roulette')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('casino-quick-bet-rouletteRed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('casino-open-bet-picker-roulette')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('casino-open-bet-picker-roulette')));
    await tester.pumpAndSettle();
    expect(find.text('룰렛 베팅 보드'), findsOneWidget);
    for (var index = 0; index < 6; index++) {
      final art = find.byKey(Key('casino-roulette-bet-art-$index'));
      expect(art, findsOneWidget);
      final image = tester.widget<Image>(
        find.descendant(of: art, matching: find.byType(Image)),
      );
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/casino/roulette_bet_icon_atlas_v1.png',
      );
    }
    expect(
      tester.getSize(find.byKey(const Key('casino-bet-rouletteLow'))).height,
      48,
    );
    await tester.ensureVisible(
      find.byKey(const Key('casino-bet-rouletteStraight')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-bet-rouletteStraight')));
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('casino-number-17'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    final numberSize = tester.getSize(
      find.byKey(const Key('casino-number-17')),
    );
    expect(numberSize.width, greaterThanOrEqualTo(48));
    expect(numberSize.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byKey(const Key('casino-number-17')));
    await tester.pumpAndSettle();
    expect(find.text('STRAIGHT UP · 17'), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-confirm-bet-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-back')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('casino-game-craps')));
    await tester.tap(find.byKey(const Key('casino-game-craps')));
    await tester.pumpAndSettle();
    _expectCasualDealerLine(tester);
    expect(
      find.byKey(const Key('casino-live-table-image-craps')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('casino-quick-bet-crapsPassLine')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('casino-quick-bet-crapsDontPass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('casino-quick-bet-crapsField')),
      findsOneWidget,
    );
    expect(find.textContaining('COME-OUT ROLL'), findsWidgets);
    await tester.tap(find.byKey(const Key('casino-back')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('casino-game-sicBo')));
    await tester.tap(find.byKey(const Key('casino-game-sicBo')));
    await tester.pumpAndSettle();
    _expectCasualDealerLine(tester);
    expect(
      find.byKey(const Key('casino-live-table-image-sicBo')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('casino-quick-bet-sicBoBig')), findsOneWidget);
    expect(
      find.byKey(const Key('casino-open-bet-picker-sicBo')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('casino-open-bet-picker-sicBo')));
    await tester.pumpAndSettle();
    expect(find.text('다이사이 배당판'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('casino-bet-sicBoSpecificTriple')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-bet-sicBoSpecificTriple')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('casino-number-6')), findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('casino-number-6'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-number-6')));
    await tester.pumpAndSettle();
    expect(find.text('SPECIFIC · 6'), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-confirm-bet-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-back')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('casino-game-slots')));
    await tester.tap(find.byKey(const Key('casino-game-slots')));
    await tester.pumpAndSettle();
    _expectCasualDealerLine(tester);
    expect(
      find.byKey(const Key('casino-live-table-image-slots')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('casino-open-slots-paytable')), findsOneWidget);
    expect(find.text('최고 95× · 1라인 배당'), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-open-slots-paytable')));
    await tester.pumpAndSettle();
    expect(find.text('1라인 페이테이블'), findsOneWidget);
    expect(find.text('95×'), findsOneWidget);
    expect(find.text('체리 2개'), findsOneWidget);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('casino-slot-pull')), findsOneWidget);
    expect(find.byKey(const Key('casino-play-round')), findsNothing);
    for (var index = 0; index < 3; index++) {
      final symbol = find.byKey(Key('casino-slot-symbol-$index'));
      expect(symbol, findsOneWidget);
      final image = tester.widget<Image>(
        find.descendant(of: symbol, matching: find.byType(Image)),
      );
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/casino/slot_symbol_atlas_v1.png',
      );
    }
    final slotLeverRect = tester.getRect(
      find.byKey(const Key('casino-slot-pull')),
    );
    final slotStageRect = tester.getRect(
      find.byKey(const Key('casino-live-table-stage')),
    );
    expect(slotLeverRect.right, lessThanOrEqualTo(slotStageRect.right));
    expect(slotLeverRect.top, greaterThan(slotStageRect.top));
    expect(slotLeverRect.bottom, lessThan(slotStageRect.bottom));
    final slotLever = tester.widget<InkWell>(
      find.byKey(const Key('casino-slot-pull')),
    );
    expect(slotLever.onTap, isNotNull);
    await tester.tap(find.byKey(const Key('casino-slot-pull')));
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.byKey(const Key('casino-dealer-chip-hand')), findsNothing);
    expect(find.byKey(const Key('casino-dealer-deal-hand')), findsNothing);
    expect(find.byKey(const Key('casino-dealer-collect-hand')), findsNothing);
    final pullingKnob = tester.widget<AnimatedPositioned>(
      find.descendant(
        of: find.byKey(const Key('casino-slot-pull')),
        matching: find.byType(AnimatedPositioned),
      ),
    );
    expect(pullingKnob.top, 46);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp(r'^[123]번 릴 (체리|레몬|스타|BAR|벨|7)$')),
      findsNWidgets(3),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('casino test entry requires cash to chip exchange first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MillenniumCapitalApp(casinoTestMode: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('casino-test-screen')), findsOneWidget);
    expect(find.text('데시멀 온라인 카지노 · TEST'), findsOneWidget);
    expect(find.text('15:00 · 국가계좌 1,000,000원 · 칩 0'), findsOneWidget);
    expect(find.byKey(const Key('casino-game-baccarat')), findsNothing);
    await _advanceCasinoWelcome(tester, hasChips: false);
    expect(find.text('칩 교환 후 접속'), findsOneWidget);
    expect(find.text('칩 교환'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('casino-entry-exchange')));
    await tester.tap(find.byKey(const Key('casino-entry-exchange')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('casino-exchange-confirm')),
    );
    await tester.tap(find.byKey(const Key('casino-exchange-confirm')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('casino-handover-accept')));
    await tester.tap(find.byKey(const Key('casino-handover-accept')));
    await tester.pumpAndSettle();

    expect(find.text('TABLE LIST'), findsOneWidget);
    expect(find.text('칩 100,000'), findsWidgets);
    expect(find.byKey(const Key('casino-game-baccarat')), findsOneWidget);

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

  testWidgets(
    'empty chips open Ian dialogue with exchange and offline choices',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final day =
          DateTime(2000, 1, 3).difference(DateTime(2000, 1, 1)).inDays + 1;
      var state = engine
          .createNewGame(
            '카지노 테스트',
            initialCash: 1000000,
            worldSeed: 'casino-live-test-v1',
          )
          .copyWith(
            day: day,
            marketMinute: krxCloseMinute,
            decisions: const [],
          );
      state = engine.exchangeCasinoChips(state, 10000).state;
      var wentOffline = false;

      Future<CasinoActionResult> apply(CasinoActionResult result) async {
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
            testMode: true,
            onExchangeChips: (amount) =>
                apply(engine.exchangeCasinoChips(state, amount)),
            onCashOutChips: () => apply(engine.cashOutCasinoChips(state)),
            onPlayRound: (bet) => apply(
              CasinoActionResult(
                state: state.copyWith(
                  personalFinance: state.personalFinance.copyWith(
                    casino: state.personalFinance.casino.copyWith(
                      chipBalance: 0,
                    ),
                  ),
                ),
                success: true,
                message: '테스트용 칩 소진',
              ),
            ),
            onStartBlackjack: (stake) =>
                apply(engine.startCasinoBlackjack(state, stake)),
            onBlackjackAction: (action) =>
                apply(engine.actCasinoBlackjack(state, action)),
            onCrapsRoll: () => apply(engine.rollCasinoCraps(state)),
            onGoOffline: () => wentOffline = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _advanceCasinoWelcome(tester, hasChips: true);
      await tester.tap(find.byKey(const Key('casino-entry-continue')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('casino-game-slots')));
      await tester.tap(find.byKey(const Key('casino-game-slots')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('casino-slot-pull')));
      await tester.pumpAndSettle();

      expect(state.personalFinance.casino.chipBalance, 0);
      final emptyLever = tester.widget<InkWell>(
        find.byKey(const Key('casino-slot-pull')),
      );
      expect(emptyLever.onTap, isNotNull);
      expect(find.text('칩 충전'), findsOneWidget);
      expect(find.text('베팅 가능한 칩이 부족해. 칩 교환소에서 더 충전해 줘.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('casino-slot-pull')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('casino-out-of-chips-sheet')),
        findsOneWidget,
      );
      expect(find.text('칩이 떨어졌네.'), findsOneWidget);
      expect(find.byKey(const Key('casino-no-chips-exchange')), findsNothing);

      final noChipDialogue = find.descendant(
        of: find.byKey(const Key('casino-out-of-chips-sheet')),
        matching: find.byKey(const Key('story-dialogue-panel')),
      );
      final dialogue = tester.getRect(noChipDialogue);
      await tester.tapAt(Offset(dialogue.right - 8, dialogue.bottom - 8));
      await tester.pumpAndSettle();
      expect(find.text('더 할 거면 칩 사러 가자. 오늘은 여기까지면 접속을 끝내면 돼.'), findsOneWidget);
      expect(find.text('칩 사러 가기'), findsOneWidget);
      expect(find.text('접속 종료'), findsWidgets);

      await tester.tap(find.byKey(const Key('casino-no-chips-offline')));
      await tester.pumpAndSettle();
      expect(wentOffline, isTrue);
      expect(find.byKey(const Key('casino-out-of-chips-sheet')), findsNothing);

      await tester.tap(find.byKey(const Key('casino-slot-pull')));
      await tester.pumpAndSettle();
      final repeatedNoChipDialogue = find.descendant(
        of: find.byKey(const Key('casino-out-of-chips-sheet')),
        matching: find.byKey(const Key('story-dialogue-panel')),
      );
      await tester.tapAt(
        tester.getRect(repeatedNoChipDialogue).bottomRight - const Offset(8, 8),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('casino-no-chips-exchange')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('casino-exchange-confirm')), findsOneWidget);
      expect(find.textContaining('국가계좌 990,000원 · 보유 칩 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('casino exit can keep persistent chips or cash them out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final day =
        DateTime(2000, 1, 3).difference(DateTime(2000, 1, 1)).inDays + 1;
    var state = engine
        .markNationalNetworkBriefingSeen(
          engine.createNewGame(
            '카지노 칩 보관 화면 테스트',
            initialCash: 1000000,
            worldSeed: 'casino-keep-chip-screen',
          ),
        )
        .copyWith(day: day, marketMinute: krxCloseMinute, decisions: const []);
    state = engine.exchangeCasinoChips(state, 100000).state;
    final offlineMinute = state.marketMinute;
    var wentOffline = false;

    Future<CasinoActionResult> apply(CasinoActionResult result) async {
      if (result.success) state = result.state;
      return result;
    }

    Widget buildScreen() => MaterialApp(
      home: CasinoScreen(
        state: state,
        onExchangeChips: (amount) =>
            apply(engine.exchangeCasinoChips(state, amount)),
        onCashOutChips: () => apply(engine.cashOutCasinoChips(state)),
        onPlayRound: (bet) => apply(engine.playCasinoRound(state, bet)),
        onStartBlackjack: (stake) =>
            apply(engine.startCasinoBlackjack(state, stake)),
        onBlackjackAction: (action) =>
            apply(engine.actCasinoBlackjack(state, action)),
        onCrapsRoll: () => apply(engine.rollCasinoCraps(state)),
        onGoOffline: () => wentOffline = true,
      ),
    );

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('casino-exit-sheet')), findsOneWidget);
    expect(find.text('현재 보유 칩 잔액 100,000'), findsOneWidget);
    expect(find.textContaining('국가계좌 100,000원으로 환전'), findsOneWidget);
    expect(find.text('칩 보관하고 나가기'), findsOneWidget);

    await tester.tap(find.byKey(const Key('casino-exit-cancel')));
    await tester.pumpAndSettle();
    expect(state.personalFinance.casino.chipBalance, 100000);

    await _advanceCasinoWelcome(tester, hasChips: true);
    final tableButton = tester.widget<FilledButton>(
      find.byKey(const Key('casino-entry-continue')),
    );
    expect(tableButton.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('casino-entry-continue')));
    await tester.pumpAndSettle();
    expect(find.text('TABLE LIST'), findsOneWidget);
    expect(state.personalFinance.casino.chipBalance, 100000);

    await tester.ensureVisible(find.byKey(const Key('casino-go-offline')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('casino-go-offline')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('casino-exit-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('casino-exit-keep-chips')));
    await tester.pumpAndSettle();
    expect(wentOffline, isTrue);
    expect(state.marketMinute, offlineMinute);
    expect(state.personalFinance.casino.chipBalance, 100000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blackjack split and insurance actions fit a 360px screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final day =
        DateTime(2000, 1, 3).difference(DateTime(2000, 1, 1)).inDays + 1;
    GameState? activeState;
    for (var index = 0; index < 1500; index++) {
      var candidate = engine
          .createNewGame(
            '블랙잭 모바일 액션 테스트',
            initialCash: 10000000,
            worldSeed: 'blackjack-mobile-actions-$index',
          )
          .copyWith(
            day: day,
            marketMinute: krxCloseMinute,
            decisions: const [],
          );
      candidate = engine.exchangeCasinoChips(candidate, 500000).state;
      final deal = engine.startCasinoBlackjack(candidate, 10000);
      final hand = deal.state.personalFinance.casino.activeBlackjack!;
      final pair =
          math.min(casinoCardRank(hand.playerCards[0]), 10) ==
          math.min(casinoCardRank(hand.playerCards[1]), 10);
      final dealerAce =
          blackjackHandValue(<int>[hand.dealerCards.first]).total == 11;
      if (pair && dealerAce) {
        activeState = deal.state;
        break;
      }
    }
    expect(activeState, isNotNull);
    var state = activeState!;

    Future<CasinoActionResult> persist(CasinoActionResult result) async {
      if (result.success) state = result.state;
      return result;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: CasinoScreen(
          state: state,
          testMode: true,
          onExchangeChips: (amount) =>
              persist(engine.exchangeCasinoChips(state, amount)),
          onCashOutChips: () => persist(engine.cashOutCasinoChips(state)),
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

    for (final key in const <Key>[
      Key('casino-blackjack-hit'),
      Key('casino-blackjack-insurance'),
      Key('casino-blackjack-split'),
      Key('casino-blackjack-stand'),
      Key('casino-blackjack-double'),
    ]) {
      expect(find.byKey(key), findsOneWidget);
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });
}
