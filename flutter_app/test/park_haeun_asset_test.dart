import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const assets = <String>[
    '01_neutral_soft_v2.png',
    '02_bright_smile_wave_v2.png',
    '03_bright_laugh_v2.png',
    '04_playful_wink_v2.png',
    '05_surprised_v2.png',
    '06_worried_v2.png',
    '07_sulky_pout_v2.png',
    '08_determined_v2.png',
    '09_explaining_v2.png',
  ];

  test(
    'Park Haeun sprites share the production canvas and transparency',
    () async {
      for (final asset in assets) {
        final file = File(
          'assets/images/production_soft_painted/park_haeun/$asset',
        );
        expect(file.existsSync(), isTrue, reason: asset);

        final codec = await ui.instantiateImageCodec(await file.readAsBytes());
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

        image.dispose();
        codec.dispose();
      }
    },
  );
}
