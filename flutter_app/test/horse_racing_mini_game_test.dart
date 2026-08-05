import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/horse_racing.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/main.dart';

void main() {
  Future<void> setPhoneSurface(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
  }

  Future<void> finishTellerTyping(WidgetTester tester) async {
    await tester.tapAt(const Offset(195, 150));
    await tester.pump();
  }

  Future<void> openHorseRaceBettingCard(WidgetTester tester) async {
    expect(
      find.byKey(const Key('horse-race-teller-welcome-screen')),
      findsOneWidget,
    );
    await finishTellerTyping(tester);
    await tester.tap(find.byKey(const Key('horse-race-teller-welcome-next')));
    await tester.pump();
    await finishTellerTyping(tester);
    await tester.tap(find.byKey(const Key('horse-race-teller-open-guide')));
    await tester.pump();
    expect(
      find.byKey(const Key('horse-race-teller-guide-screen')),
      findsOneWidget,
    );
    await finishTellerTyping(tester);
    await tester.tap(find.byKey(const Key('horse-race-teller-open-card')));
    await tester.pump();
  }

  testWidgets(
    'teller dialogue uses the story style and advances from the image',
    (tester) async {
      await setPhoneSurface(tester);
      final race = buildAfternoonHorseRace(
        simulationSeed: 'horse-widget-dialogue',
        day: 8,
      );
      await tester.pumpWidget(
        MaterialApp(home: HorseRacingMiniGame(race: race, availableCash: 5000)),
      );
      await tester.pump();

      await finishTellerTyping(tester);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('story-line-text')))
            .style
            ?.fontFamily,
        'Maplestory',
      );
      await tester.tapAt(const Offset(195, 150));
      await tester.pump();
      expect(
        find.byKey(const Key('horse-race-teller-open-guide-anywhere')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('horse-race-teller-welcome-screen')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('race is always online and offline requests PC power off', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final race = buildAfternoonHorseRace(
      simulationSeed: 'horse-widget-online-only',
      day: 8,
    );
    var powerOffCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HorseRacingMiniGame(
          race: race,
          availableCash: 5000,
          onPowerOff: () => powerOffCount += 1,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('국가망 경마 · 전자 마권 창구'), findsOneWidget);
    expect(find.text('국가망 · 온라인'), findsOneWidget);
    await openHorseRaceBettingCard(tester);
    expect(find.text('온라인'), findsOneWidget);
    expect(find.text('오프라인'), findsOneWidget);
    expect(find.text('PC 전원 끄기'), findsOneWidget);
    await tester.tap(find.byKey(const Key('horse-race-mode-offline')));
    await tester.pump();
    expect(powerOffCount, 1);
    expect(find.textContaining('현장'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horse race shows full paddock card and three bet types', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final race = buildAfternoonHorseRace(
      simulationSeed: 'horse-widget-card',
      day: 8,
    );
    await tester.pumpWidget(
      MaterialApp(home: HorseRacingMiniGame(race: race, availableCash: 5000)),
    );
    await tester.pump();
    await openHorseRaceBettingCard(tester);

    expect(find.byKey(const Key('horse-race-betting-screen')), findsOneWidget);
    expect(
      find.byKey(const Key('horse-race-access-mode-selector')),
      findsOneWidget,
    );
    expect(find.text('온라인'), findsOneWidget);
    expect(find.text('국가망 접속 중'), findsOneWidget);
    expect(find.text('오프라인'), findsOneWidget);
    expect(find.text('PC 전원 끄기'), findsOneWidget);
    expect(
      Theme.of(
        tester.element(find.byKey(const Key('horse-race-betting-screen'))),
      ).textTheme.bodyMedium?.fontFamily,
      'Maplestory',
    );
    expect(find.byKey(const Key('horse-race-venue-hero')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-ticket-slip')), findsOneWidget);
    expect(find.byKey(const Key('horse-bet-win')), findsOneWidget);
    expect(find.byKey(const Key('horse-bet-place')), findsOneWidget);
    expect(find.byKey(const Key('horse-bet-quinella')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-start')), findsOneWidget);
    expect(find.textContaining('적중 가정 국가 수수료'), findsOneWidget);
    for (final entrant in race.entrants) {
      expect(find.byKey(Key('horse-entry-${entrant.id}')), findsOneWidget);
    }

    await tester.ensureVisible(find.byKey(const Key('horse-bet-quinella')));
    await tester.tap(find.byKey(const Key('horse-bet-quinella')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('horse-race-start')))
          .onPressed,
      isNull,
    );
    final secondHorse = find.byKey(Key('horse-entry-${race.entrants[1].id}'));
    await tester.ensureVisible(secondHorse);
    await tester.tap(secondHorse);
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('horse-race-start')))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('adult weekday home PC exposes the one-bet horse racing app', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    const engine = GameEngine();
    final base = engine.createNewGame(
      '평일 경마 앱 테스트',
      worldSeed: 'horse-home-computer',
    );
    var day = base.day;
    while (base.dateForDay(day).isBefore(DateTime(2010, 1, 1)) ||
        base.dateForDay(day).weekday >= DateTime.saturday) {
      day += 1;
    }
    final state = base.copyWith(
      day: day,
      cash: base.cash + 5000,
      marketMinute: krxCloseMinute,
      decisions: const [],
    );
    var horseRaceOpenCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: HomeComputerScreen(
          state: state,
          onOpenStockMarket: (current) async => current,
          onOpenCompanyManagement: (current) async => current,
          onOpenRealEstate: (current) async => current,
          onOpenBusiness: (current) async => current,
          onOpenCasino: (current) async => current,
          onOpenHorseRace: (current) async {
            horseRaceOpenCount += 1;
            return current;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final app = find.byKey(const Key('computer-horse-racing-app'));
    expect(app, findsOneWidget);
    expect(find.text('베팅 0/1회'), findsOneWidget);
    await tester.tap(app);
    await tester.pumpAndSettle();
    expect(horseRaceOpenCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('eight animated horses run and produce an official result', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final race = buildAfternoonHorseRace(
      simulationSeed: 'horse-widget-live',
      day: 8,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HorseRacingMiniGame(
          race: race,
          availableCash: 5000,
          previewMode: true,
          raceDuration: const Duration(milliseconds: 700),
        ),
      ),
    );
    await tester.pump();
    await openHorseRaceBettingCard(tester);
    await tester.tap(find.byKey(const Key('horse-race-start')));
    await tester.pump();
    expect(
      find.byKey(const Key('horse-race-teller-acceptance-screen')),
      findsOneWidget,
    );
    await finishTellerTyping(tester);
    await tester.tap(find.byKey(const Key('horse-race-teller-confirm-ticket')));
    await tester.pump();
    expect(
      find.byKey(const Key('horse-race-teller-handover-screen')),
      findsOneWidget,
    );
    await finishTellerTyping(tester);
    await tester.tap(find.byKey(const Key('horse-race-teller-watch-race')));
    await tester.pump(const Duration(milliseconds: 145));

    expect(find.byKey(const Key('horse-race-running-screen')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-live-track')), findsOneWidget);
    expect(
      find.byKey(const Key('horse-race-straight-panorama')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('horse-race-straight-lanes')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-impact-layer')), findsNothing);
    expect(find.byKey(const Key('horse-race-announcer')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-winner-badge')), findsNothing);
    expect(find.byKey(const Key('horse-race-starting-gate')), findsOneWidget);
    for (final entrant in race.entrants) {
      expect(find.byKey(Key('horse-live-${entrant.id}')), findsOneWidget);
    }
    final laneCenters = race.entrants
        .map(
          (entrant) => tester
              .getRect(find.byKey(Key('horse-live-${entrant.id}')))
              .center
              .dy,
        )
        .toList(growable: false);
    final laneGaps = <double>[
      for (var index = 1; index < laneCenters.length; index++)
        laneCenters[index] - laneCenters[index - 1],
    ];
    for (final gap in laneGaps) {
      expect(gap, closeTo(laneGaps.first, 3.0));
    }
    final announcerRect = tester.getRect(
      find.byKey(const Key('horse-race-announcer')),
    );
    final firstLaneTop = tester
        .getRect(find.byKey(Key('horse-live-${race.entrants.first.id}')))
        .top;
    expect(announcerRect.bottom, lessThan(firstLaneTop));

    expect(find.byKey(const Key('horse-race-fixed-finish-line')), findsNothing);
    final trackRect = tester.getRect(
      find.byKey(const Key('horse-race-live-track')),
    );
    final liveDialogueRect = tester.getRect(
      find.byKey(const Key('horse-race-live-dialogue')),
    );
    expect(liveDialogueRect.top, greaterThanOrEqualTo(trackRect.bottom));
    const embeddedFinishCenterRatio = (0.843 + 0.860) / 2;
    final earlyPanoramaRect = tester.getRect(
      find.byKey(const Key('horse-race-straight-panorama')),
    );
    final earlyEmbeddedFinishX =
        earlyPanoramaRect.left +
        earlyPanoramaRect.width * embeddedFinishCenterRatio;
    expect(earlyPanoramaRect.width, closeTo(trackRect.width * 1.8, 1.0));
    expect(earlyEmbeddedFinishX, greaterThan(trackRect.right));
    expect(
      find.byKey(const Key('horse-race-finish-line-visibility')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 140));
    expect(find.byKey(const Key('horse-race-starting-gate')), findsNothing);
    expect(
      find.byKey(const Key('horse-race-straight-panorama')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('horse-race-course-label')), findsOneWidget);
    expect(find.textContaining('m 직선'), findsOneWidget);
    for (final entrant in race.entrants) {
      expect(find.byKey(Key('horse-live-${entrant.id}')), findsOneWidget);
    }
    final midPanoramaRect = tester.getRect(
      find.byKey(const Key('horse-race-straight-panorama')),
    );
    final midEmbeddedFinishX =
        midPanoramaRect.left +
        midPanoramaRect.width * embeddedFinishCenterRatio;
    expect(midEmbeddedFinishX, lessThan(earlyEmbeddedFinishX));
    expect(midEmbeddedFinishX, greaterThan(trackRect.right));

    await tester.pump(const Duration(milliseconds: 310));
    expect(
      find.byKey(const Key('horse-race-straight-panorama')),
      findsOneWidget,
    );
    final latePanoramaRect = tester.getRect(
      find.byKey(const Key('horse-race-straight-panorama')),
    );
    final lateEmbeddedFinishX =
        latePanoramaRect.left +
        latePanoramaRect.width * embeddedFinishCenterRatio;
    expect(lateEmbeddedFinishX, lessThan(midEmbeddedFinishX));
    expect(
      lateEmbeddedFinishX,
      greaterThan(trackRect.left + trackRect.width * 0.82),
    );
    expect(lateEmbeddedFinishX, lessThan(trackRect.right));
    final winnerBeforeCrossing = tester
        .getRect(find.byKey(Key('horse-live-${race.finishOrder.first}')))
        .right;
    expect(winnerBeforeCrossing, lessThan(lateEmbeddedFinishX));
    final lateRunnerRights =
        race.entrants
            .map(
              (entrant) => tester
                  .getRect(find.byKey(Key('horse-live-${entrant.id}')))
                  .right,
            )
            .toList(growable: false)
          ..sort();
    expect(
      lateRunnerRights.last - lateRunnerRights.first,
      greaterThan(trackRect.width * 0.20),
    );

    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump(const Duration(milliseconds: 25));
    final winnerAfterCrossing = tester
        .getRect(find.byKey(Key('horse-live-${race.finishOrder.first}')))
        .right;
    final afterCrossingPanoramaRect = tester.getRect(
      find.byKey(const Key('horse-race-straight-panorama')),
    );
    final afterCrossingFinishX =
        afterCrossingPanoramaRect.left +
        afterCrossingPanoramaRect.width * embeddedFinishCenterRatio;
    expect(afterCrossingFinishX, lessThan(lateEmbeddedFinishX));
    expect(
      afterCrossingFinishX,
      closeTo(trackRect.left + trackRect.width * 0.82, 1.0),
    );
    expect(winnerAfterCrossing, greaterThan(winnerBeforeCrossing));
    expect(winnerAfterCrossing, greaterThan(afterCrossingFinishX));
    expect(find.byKey(const Key('horse-race-winner-badge')), findsOneWidget);
    expect(find.text('1등!'), findsOneWidget);

    final lastHorseId = race.finishOrder.last;
    final lastHorseAfterCrossing = tester
        .getRect(find.byKey(Key('horse-live-$lastHorseId')))
        .right;
    expect(lastHorseAfterCrossing, greaterThan(afterCrossingFinishX));

    await tester.pump(const Duration(milliseconds: 28));
    final winnerRunOut = tester
        .getRect(find.byKey(Key('horse-live-${race.finishOrder.first}')))
        .right;
    final lastHorseRunOut = tester
        .getRect(find.byKey(Key('horse-live-$lastHorseId')))
        .right;
    expect(
      winnerRunOut,
      greaterThan(winnerAfterCrossing + trackRect.width * 0.05),
    );
    expect(lastHorseRunOut, greaterThan(lastHorseAfterCrossing + 5));

    await tester.pump(const Duration(milliseconds: 72));
    await tester.pump();
    expect(find.byKey(const Key('horse-race-result-screen')), findsOneWidget);
    expect(
      find.byKey(const Key('horse-race-teller-result-dialogue')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('horse-race-official-broadcast-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('horse-race-photo-finish-image')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('horse-race-official-record-board')),
      findsOneWidget,
    );
    final boardRect = tester.getRect(
      find.byKey(const Key('horse-race-official-record-board')),
    );
    expect(boardRect.height, closeTo(439, 2));
    expect(find.text('공식 경주 성적'), findsOneWidget);
    expect(find.text('공식 확정'), findsAtLeastNWidgets(1));
    expect(find.byKey(const Key('horse-race-winning-record')), findsOneWidget);
    expect(
      find.text(
        horseRaceRecordLabel(
          horseRaceFinishTimeSeconds(
            race: race,
            entrant: race.entrantById(race.finishOrder.first),
          ),
        ),
      ),
      findsAtLeastNWidgets(2),
    );
    for (final entrant in race.entrants) {
      expect(
        find.byKey(Key('horse-result-record-${entrant.id}')),
        findsOneWidget,
      );
      final rowRect = tester.getRect(
        find.byKey(Key('horse-result-record-${entrant.id}')),
      );
      expect(rowRect.top, greaterThan(boardRect.top));
      expect(rowRect.bottom, lessThan(boardRect.bottom));
    }
    await tester.scrollUntilVisible(
      find.byKey(const Key('horse-race-payout-card')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('horse-race-payout-card')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-confirm-result')), findsOneWidget);
    expect(find.text('메인으로 가기'), findsOneWidget);
    await tester.tap(find.byKey(const Key('horse-race-confirm-result')));
    await tester.pump();
    expect(find.byKey(const Key('horse-race-betting-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ImageGen race background and eight gallop sheets are bundled', (
    tester,
  ) async {
    const assets = [
      horseRaceBackgroundAsset,
      horseRacePhotoFinishAsset,
      horseRaceOfficialResultBoardAsset,
      horseRaceTellerWelcomeAsset,
      horseRaceTellerGuideAsset,
      horseRaceTellerAcceptAsset,
      horseRaceTellerHandoverAsset,
      horseRaceStraightTrackAsset,
      horseGallopChestnutAsset,
      horseGallopDarkBayAsset,
      horseGallopGrayAsset,
      horseGallopWhiteAsset,
      horseGallopBlackAsset,
      horseGallopPalominoAsset,
      horseGallopPintoAsset,
      horseGallopMahoganyAsset,
    ];
    for (final asset in assets) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(10000), reason: asset);
    }
  });
}
