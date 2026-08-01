import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const assets = <String>[
    '01_neutral_tie_v1.png',
    '02_soft_smile_wave_v1.png',
    '03_delighted_laugh_v1.png',
    '04_shy_blush_v1.png',
    '05_surprised_v1.png',
    '06_worried_v1.png',
    '07_sulky_pout_v1.png',
    '08_determined_v1.png',
    '09_explaining_v1.png',
  ];

  test(
    'Yoon Chaea sprites share the production canvas and transparency',
    () async {
      for (final asset in assets) {
        final file = File(
          'assets/images/production_soft_painted/yoon_chaea/$asset',
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

  test('Yoon Chaea dialogue scenes use her production sprites', () {
    final raw = File(
      'assets/dialogue/dialogue-editor-override.json',
    ).readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    expect(decoded['appearanceVersion'], 11);

    final scenes = (decoded['scenes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((scene) => scene['speaker'] == '윤채아')
        .toList();
    expect(scenes.map((scene) => scene['order']), <int>[73, 87]);
    expect(scenes.map((scene) => scene['character']), <String>[
      '/play/assets/assets/images/production_soft_painted/yoon_chaea/09_explaining_v1.png',
      '/play/assets/assets/images/production_soft_painted/yoon_chaea/06_worried_v1.png',
    ]);
  });
}
