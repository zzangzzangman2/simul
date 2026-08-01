import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const assets = <String>[
    'character_realtor_welcome_v1.png',
    'character_realtor_explain_v1.png',
    'character_realtor_finance_v1.png',
    'character_realtor_concerned_v1.png',
    'character_realtor_approve_v1.png',
    'character_realtor_negotiate_v1.png',
  ];

  test('realtor sprites share the canonical canvas and baseline', () async {
    for (final asset in assets) {
      final encoded = await File('assets/images/$asset').readAsBytes();
      final codec = await ui.instantiateImageCodec(encoded);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      expect(image.width, 1024, reason: asset);
      expect(image.height, 1536, reason: asset);

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(byteData, isNotNull, reason: asset);
      final rgba = byteData!.buffer.asUint8List();

      int alphaAt(int x, int y) => rgba[(y * image.width + x) * 4 + 3];

      expect(alphaAt(0, 0), 0, reason: asset);
      expect(alphaAt(image.width - 1, 0), 0, reason: asset);
      expect(alphaAt(0, image.height - 1), 0, reason: asset);
      expect(alphaAt(image.width - 1, image.height - 1), 0, reason: asset);

      var minimumY = image.height;
      var maximumY = -1;
      var footMinimumX = image.width;
      var footMaximumX = -1;
      for (var y = 0; y < image.height; y += 1) {
        for (var x = 0; x < image.width; x += 1) {
          if (alphaAt(x, y) == 0) continue;
          if (y < minimumY) minimumY = y;
          if (y > maximumY) maximumY = y;
          if (y >= 1250) {
            if (x < footMinimumX) footMinimumX = x;
            if (x > footMaximumX) footMaximumX = x;
          }
        }
      }

      expect(minimumY, 20, reason: asset);
      expect(maximumY, 1516, reason: asset);
      expect(footMinimumX, lessThan(footMaximumX), reason: asset);
      final footCenter = (footMinimumX + footMaximumX + 1) / 2;
      expect(footCenter, closeTo(512, 0.6), reason: asset);

      image.dispose();
      codec.dispose();
    }
  });
}
