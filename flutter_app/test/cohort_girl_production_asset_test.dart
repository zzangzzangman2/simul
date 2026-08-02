import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/relationship_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expectedAssetCounts = <String, int>{
    'kim_seoa': 9,
    'lee_jian': 9,
    'choi_iseo': 9,
    'jung_arin': 9,
    'park_haeun': 9,
    'han_sua': 8,
    'oh_jiwoo': 9,
    'yoon_chaea': 9,
  };

  test(
    'newly connected cohort sprites use production canvas and alpha',
    () async {
      for (final entry in expectedAssetCounts.entries) {
        final directory = Directory(
          'assets/images/production_soft_painted/${entry.key}',
        );
        expect(directory.existsSync(), isTrue, reason: entry.key);
        final files =
            directory
                .listSync()
                .whereType<File>()
                .where((file) => file.path.endsWith('.png'))
                .toList()
              ..sort((left, right) => left.path.compareTo(right.path));
        expect(files.length, entry.value, reason: entry.key);

        for (final file in files) {
          final codec = await ui.instantiateImageCodec(
            await file.readAsBytes(),
          );
          final frame = await codec.getNextFrame();
          final image = frame.image;
          expect(image.width, 1024, reason: file.path);
          expect(image.height, 1536, reason: file.path);

          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          expect(byteData, isNotNull, reason: file.path);
          final rgba = byteData!.buffer.asUint8List();
          int alphaAt(int x, int y) => rgba[(y * image.width + x) * 4 + 3];
          expect(alphaAt(0, 0), 0, reason: file.path);
          expect(alphaAt(image.width - 1, 0), 0, reason: file.path);
          expect(alphaAt(0, image.height - 1), 0, reason: file.path);
          expect(
            alphaAt(image.width - 1, image.height - 1),
            0,
            reason: file.path,
          );

          image.dispose();
          codec.dispose();
        }
      }
    },
  );

  test('all eight relationship profiles use production portraits', () {
    expect(cohortGirlProfiles.length, 8);
    for (final profile in cohortGirlProfiles) {
      expect(profile.portraitAsset, isNotNull, reason: profile.name);
      expect(
        profile.portraitAsset,
        startsWith('assets/images/production_soft_painted/'),
        reason: profile.name,
      );
      expect(
        File(profile.portraitAsset!).existsSync(),
        isTrue,
        reason: profile.name,
      );
    }
  });

  test('all Han Sua runtime consumers use the full quality v2 set', () {
    final sources = <String>[
      File('lib/visual_novel_onboarding.dart').readAsStringSync(),
      File('lib/stock_market_screen.dart').readAsStringSync(),
      File('lib/game/relationship_state.dart').readAsStringSync(),
      File('../app/editor/character-catalog.ts').readAsStringSync(),
      File('assets/dialogue/dialogue-editor-override.json').readAsStringSync(),
    ].join('\n');
    expect(
      RegExp(
        r'production_soft_painted/han_sua/0[1-8]_[^\s"\x27]*_v1\.png',
      ).allMatches(sources),
      isEmpty,
    );
    const qualitySet = <String>[
      '01_neutral_quality_v2.png',
      '02_warm_smile_quality_v2.png',
      '03_bright_laugh_quality_v2.png',
      '04_surprised_quality_v2.png',
      '05_worried_quality_v2.png',
      '06_annoyed_quality_v2.png',
      '07_determined_quality_v2.png',
      '08_explaining_quality_v2.png',
    ];
    for (final asset in qualitySet) {
      expect(sources, contains(asset), reason: asset);
    }
  });

  test('first-day cohort dialogue uses the approved production sprites', () {
    final decoded =
        jsonDecode(
              File(
                'assets/dialogue/dialogue-editor-override.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(decoded['appearanceVersion'], 13);
    expect(decoded['contentVersion'], 1);
    final scenes = (decoded['scenes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    const speakerFolders = <String, String>{
      '김서아': 'kim_seoa',
      '이지안': 'lee_jian',
      '최이서': 'choi_iseo',
      '정아린': 'jung_arin',
      '박하은': 'park_haeun',
      '수아': 'han_sua',
      '오지우': 'oh_jiwoo',
      '윤채아': 'yoon_chaea',
    };
    for (final entry in speakerFolders.entries) {
      final speakerScenes = scenes.where(
        (scene) => scene['speaker'] == entry.key,
      );
      expect(speakerScenes, isNotEmpty, reason: entry.key);
      for (final scene in speakerScenes) {
        expect(
          scene['character'],
          contains('/production_soft_painted/${entry.value}/'),
          reason: scene['id'] as String,
        );
      }
    }
    final suaScenes = scenes.where((scene) => scene['speaker'] == '수아');
    for (final scene in suaScenes) {
      expect(
        scene['character'],
        endsWith('_quality_v2.png'),
        reason: scene['id'] as String,
      );
    }
    expect(
      scenes.where(
        (scene) => (scene['character'] as String).contains(
          'cinematic_soft_painted/sua/',
        ),
      ),
      isEmpty,
    );
  });

  test('first dormitory introductions grow out of the torn bag cleanup', () {
    final decoded =
        jsonDecode(
              File(
                'assets/dialogue/dialogue-editor-override.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final scenes = (decoded['scenes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final byId = <String, Map<String, dynamic>>{
      for (final scene in scenes) scene['id'] as String: scene,
    };
    expect(byId['scene-66']?['line'], contains('옆선이 결국 터졌다'));
    final introductionSpeakers = scenes
        .where(
          (scene) =>
              (scene['order'] as int) >= 69 && (scene['order'] as int) <= 95,
        )
        .map((scene) => scene['speaker'] as String)
        .toSet();
    expect(
      introductionSpeakers,
      containsAll(<String>[
        '김서아',
        '이지안',
        '최이서',
        '정아린',
        '박하은',
        '수아',
        '오지우',
        '윤채아',
        '김학준',
        '나',
      ]),
    );
    expect(
      byId['scene-86']?['character'],
      endsWith('08_explaining_quality_v2.png'),
    );
    expect(
      byId['scene-87']?['character'],
      endsWith('06_annoyed_quality_v2.png'),
    );
    expect(
      byId['scene-89']?['character'],
      endsWith('03_bright_laugh_quality_v2.png'),
    );
    expect(byId['scene-93']?['line'], '내 이름은 내일 말할게.');
    expect(byId['scene-102']?['line'], contains('갑자기 잡아당기면 싫어'));
    expect(
      byId['scene-102']?['character'],
      endsWith('07_firm_boundary_v1.png'),
    );
    expect(byId['scene-107']?['line'], contains('다음엔 먼저 물어볼게'));
    expect(byId['scene-111']?['line'], contains('3에서 5로 건너뛰어'));
    expect(byId['scene-125']?['line'], contains('5기 기록만 한 줄도 없어'));
  });

  test('scene 24 uses the generated bus transition background', () async {
    final decoded =
        jsonDecode(
              File(
                'assets/dialogue/dialogue-editor-override.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final scenes = (decoded['scenes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final scene = scenes.singleWhere((scene) => scene['order'] == 24);
    expect(scene['location'], contains('버스'));
    expect(
      scene['background'],
      endsWith('bg_bus_transition_seoul_outskirts_2000_portrait_v1.png'),
    );
    final file = File(
      'assets/images/historical_prologue/'
      'bg_bus_transition_seoul_outskirts_2000_portrait_v1.png',
    );
    expect(file.existsSync(), isTrue);
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 1024);
    expect(frame.image.height, 1536);
    frame.image.dispose();
    codec.dispose();
  });
}
