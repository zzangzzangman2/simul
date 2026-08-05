import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/horse_racing.dart';
import 'package:millennium_capital/main.dart';

void main() {
  Future<void> setPhoneSurface(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
  }

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

    expect(find.byKey(const Key('horse-race-betting-screen')), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('horse-bet-quinella')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('horse-race-start')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(Key('horse-entry-${race.entrants[1].id}')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('horse-race-start')))
          .onPressed,
      isNotNull,
    );
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
    await tester.tap(find.byKey(const Key('horse-race-start')));
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.byKey(const Key('horse-race-running-screen')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-live-track')), findsOneWidget);
    expect(
      find.byKey(const Key('horse-race-straight-panorama')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('horse-race-straight-lanes')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-announcer')), findsOneWidget);
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

    final finishLine = find.byKey(const Key('horse-race-fixed-finish-line'));
    expect(finishLine, findsOneWidget);
    final trackRect = tester.getRect(
      find.byKey(const Key('horse-race-live-track')),
    );
    final hiddenFinishX = tester.getTopLeft(finishLine).dx;
    expect(hiddenFinishX, greaterThan(trackRect.right));

    await tester.pump(const Duration(milliseconds: 140));
    expect(find.byKey(const Key('horse-race-curve-track')), findsOneWidget);
    expect(
      find.byKey(const Key('horse-race-curve-background')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('horse-race-camera-label')), findsOneWidget);
    expect(finishLine, findsNothing);
    for (final entrant in race.entrants) {
      expect(find.byKey(Key('horse-curve-${entrant.id}')), findsOneWidget);
    }

    await tester.pump(const Duration(milliseconds: 310));
    expect(find.byKey(const Key('horse-race-curve-track')), findsNothing);
    expect(finishLine, findsOneWidget);
    final approachingFinishX = tester.getTopLeft(finishLine).dx;
    expect(approachingFinishX, lessThan(hiddenFinishX));

    await tester.pump(const Duration(milliseconds: 95));
    final fixedFinishX = tester.getTopLeft(finishLine).dx;
    expect(fixedFinishX, lessThan(trackRect.right));
    expect(fixedFinishX, lessThan(approachingFinishX));
    await tester.pump(const Duration(milliseconds: 55));
    expect(tester.getTopLeft(finishLine).dx, closeTo(fixedFinishX, 0.01));

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byKey(const Key('horse-race-result-screen')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-payout-card')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-winner-sprite')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-confirm-result')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ImageGen race background and eight gallop sheets are bundled', (
    tester,
  ) async {
    const assets = [
      horseRaceBackgroundAsset,
      horseRaceStraightTrackAsset,
      horseRaceCurveTrackAsset,
      horseGallopChestnutAsset,
      horseGallopDarkBayAsset,
      horseGallopGrayAsset,
      horseGallopWhiteAsset,
      horseGallopBlackAsset,
      horseGallopPalominoAsset,
      horseGallopPintoAsset,
      horseGallopMahoganyAsset,
      ...horseRaceCurveGallopAssets,
    ];
    for (final asset in assets) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(10000), reason: asset);
    }
  });
}
