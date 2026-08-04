import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const assets = <String>[
    'character_realtor_welcome_v2.png',
    'character_realtor_explain_v2.png',
    'character_realtor_finance_v2.png',
    'character_realtor_concerned_v2.png',
    'character_realtor_approve_v2.png',
    'character_realtor_negotiate_v2.png',
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
      var transparentRgbResidue = 0;
      var semitransparentPixels = 0;
      for (var y = 0; y < image.height; y += 1) {
        for (var x = 0; x < image.width; x += 1) {
          final offset = (y * image.width + x) * 4;
          final alpha = rgba[offset + 3];
          if (alpha == 0) {
            if (rgba[offset] != 0 ||
                rgba[offset + 1] != 0 ||
                rgba[offset + 2] != 0) {
              transparentRgbResidue += 1;
            }
            continue;
          }
          if (alpha < 255) semitransparentPixels += 1;
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
      expect(transparentRgbResidue, 0, reason: asset);
      expect(semitransparentPixels, greaterThan(0), reason: asset);
      expect(footMinimumX, lessThan(footMaximumX), reason: asset);
      final footCenter = (footMinimumX + footMaximumX + 1) / 2;
      expect(footCenter, closeTo(512, 0.6), reason: asset);

      image.dispose();
      codec.dispose();
    }
  });
}
