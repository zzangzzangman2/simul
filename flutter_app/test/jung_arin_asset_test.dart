import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const assets = <String>[
    '01_base_cheeky_v1.png',
    '02_confident_smile_v1.png',
    '03_cheeky_laugh_v1.png',
    '04_assigning_tasks_v1.png',
    '05_startled_v1.png',
    '06_schedule_worried_v1.png',
    '07_deadline_annoyed_v1.png',
    '08_determined_ready_v1.png',
    '09_counting_explain_v1.png',
  ];

  test(
    'Jung Arin sprites share the production canvas and transparency',
    () async {
      for (final asset in assets) {
        final file = File(
          'assets/images/production_soft_painted/jung_arin/$asset',
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
