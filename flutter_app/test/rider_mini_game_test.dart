import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/main.dart';

void main() {
  test(
    'newspaper delivery score rewards coverage, accuracy, combo, and safety',
    () {
      final perfect = calculateNewspaperDeliveryScore(
        delivered: 7,
        totalTargets: 7,
        accuracyTotal: 700,
        bestCombo: 7,
        collisions: 0,
      );
      final rough = calculateNewspaperDeliveryScore(
        delivered: 4,
        totalTargets: 7,
        accuracyTotal: 250,
        bestCombo: 2,
        collisions: 2,
      );

      expect(perfect, 100);
      expect(rough, lessThan(perfect));
      expect(rough, greaterThan(0));
    },
  );

  testWidgets(
    'newspaper route clears seven targets and returns scored reward',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: RiderMiniGame(
            courseDuration: Duration(milliseconds: 350),
            spawnObstacles: false,
            autoDeliverTargets: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('rider-start-card')), findsOneWidget);
      expect(find.byKey(const Key('rider-course')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('rider-start')));
      await tester.tap(find.byKey(const Key('rider-start')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byKey(const Key('work-result-card')), findsOneWidget);
      expect(find.text('100점'), findsOneWidget);
      expect(find.textContaining('배달 7/7'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('newspaper delivery stays inside a 360px portrait surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: RiderMiniGame()));
    await tester.pump();

    expect(find.byKey(const Key('rider-course')), findsOneWidget);
    expect(find.byKey(const Key('newspaper-cyclist-image')), findsOneWidget);
    final cyclist = tester.widget<Image>(
      find.byKey(const Key('newspaper-cyclist-image')),
    );
    expect(cyclist.image, isA<ResizeImage>());
    expect(cyclist.filterQuality, FilterQuality.high);
    final background = tester.widget<Image>(
      find.byKey(const Key('newspaper-background')),
    );
    expect(background.image, isA<ResizeImage>());
    expect(background.filterQuality, FilterQuality.high);
    expect(find.byKey(const Key('rider-left')), findsOneWidget);
    expect(find.byKey(const Key('rider-right')), findsOneWidget);
    expect(find.byKey(const Key('newspaper-throw')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ImageGen rider and obstacle sprites are bundled', (
    tester,
  ) async {
    const assets = [
      'assets/images/minigames/rider_newspaper_cyclist_rear_v2.png',
      'assets/images/minigames/obstacle_puddle_winter_v2.png',
      'assets/images/minigames/obstacle_wood_crate_v2.png',
      'assets/images/minigames/obstacle_trash_bags_v2.png',
    ];
    for (final asset in assets) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(10000), reason: asset);
    }
  });

  testWidgets('road touch exposes ten fine steering positions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: RiderMiniGame(
          courseDuration: Duration(seconds: 34),
          spawnObstacles: false,
        ),
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('rider-start')));
    await tester.tap(find.byKey(const Key('rider-start')));
    await tester.pump();

    final road = find.byKey(const Key('newspaper-road'));
    final roadRect = tester.getRect(road);
    for (var slot = 0; slot < 10; slot++) {
      await tester.tapAt(
        Offset(
          roadRect.left + roadRect.width * ((slot + 0.5) / 10),
          roadRect.center.dy,
        ),
      );
      await tester.pump(const Duration(milliseconds: 90));
      expect(
        find.byKey(Key('rider-steering-$slot')),
        findsOneWidget,
        reason: 'touch should steer to slot ${slot + 1}/10',
      );
    }

    await tester.tap(find.byKey(const Key('rider-left')));
    await tester.pump(const Duration(milliseconds: 90));
    expect(find.byKey(const Key('rider-steering-8')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('player flicks a newspaper toward the first left mailbox', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: RiderMiniGame(
          courseDuration: Duration(seconds: 34),
          spawnObstacles: false,
        ),
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('rider-start')));
    await tester.tap(find.byKey(const Key('rider-start')));
    await tester.pump(const Duration(milliseconds: 5100));
    await tester.tap(find.byKey(const Key('rider-left')));
    await tester.pump();

    final throwPad = find.byKey(const Key('newspaper-throw'));
    final gesture = await tester.startGesture(tester.getCenter(throwPad));
    await gesture.moveBy(const Offset(-46, -10));
    await gesture.up();
    await tester.pump();

    expect(find.byKey(const Key('newspaper-feedback')), findsOneWidget);
    expect(find.textContaining(RegExp('PERFECT|GREAT|GOOD')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
