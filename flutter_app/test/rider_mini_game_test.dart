import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/main.dart';

void main() {
  testWidgets(
    'rider starts, clears three checkpoints, and returns scored reward',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: RiderMiniGame(
            courseDuration: Duration(milliseconds: 350),
            spawnObstacles: false,
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
      expect(find.text('79점'), findsOneWidget);
      expect(find.textContaining('배달 3/3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rider stays inside a 360px portrait surface', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: RiderMiniGame()));
    await tester.pump();

    expect(find.byKey(const Key('rider-course')), findsOneWidget);
    expect(find.byKey(const Key('rider-player-sprite')), findsOneWidget);
    final sprite = tester.widget<Image>(
      find.byKey(const Key('rider-player-sprite')),
    );
    expect(
      (sprite.image as AssetImage).assetName,
      'assets/images/minigames/rider_hero_pixel_v1.png',
    );
    expect(sprite.filterQuality, FilterQuality.none);
    expect(find.byKey(const Key('rider-left')), findsOneWidget);
    expect(find.byKey(const Key('rider-right')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
