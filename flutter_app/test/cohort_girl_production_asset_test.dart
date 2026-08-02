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

  test('Project Decimal dialogue keeps all eight approved identities', () {
    final decoded =
        jsonDecode(
              File(
                'assets/dialogue/dialogue-editor-override.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(decoded['appearanceVersion'], 15);
    expect(decoded['contentVersion'], 3);
    final scenes = (decoded['scenes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(scenes.length, 292);
    const speakerFolders = <String, String>{
      '김서아': 'kim_seoa',
      '이지안': 'lee_jian',
      '최이서': 'choi_iseo',
      '정아린': 'jung_arin',
      '박하은': 'park_haeun',
      '한수아': 'han_sua',
      '오지우': 'oh_jiwoo',
      '윤채아': 'yoon_chaea',
    };
    for (final entry in speakerFolders.entries) {
      final speakerScenes = scenes.where(
        (scene) => scene['speaker'] == entry.key,
      );
      expect(speakerScenes, isNotEmpty, reason: entry.key);
      final portraitScenes = speakerScenes.where(
        (scene) => (scene['character'] as String).isNotEmpty,
      );
      expect(portraitScenes, isNotEmpty, reason: entry.key);
      for (final scene in portraitScenes) {
        expect(
          scene['character'],
          contains('/production_soft_painted/${entry.value}/'),
          reason: scene['id'] as String,
        );
      }
    }
    final suaScenes = scenes.where(
      (scene) =>
          scene['speaker'] == '한수아' &&
          (scene['character'] as String).isNotEmpty,
    );
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

  test(
    'Project Decimal canon covers selection, boundaries, and first order',
    () {
      final decoded =
          jsonDecode(
                File(
                  'assets/dialogue/dialogue-editor-override.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final scenes = (decoded['scenes'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final joinedText = scenes
          .map(
            (scene) => <Object?>[
              scene['chapter'],
              scene['location'],
              scene['speaker'],
              scene['direction'],
              scene['line'],
            ].join('\n'),
          )
          .join('\n');
      for (final forbidden in <String>[
        '미래양성원',
        '제6기',
        'SEED',
        '선배',
        '후배',
        '선생님',
        '학생',
        '기숙사',
        '오리엔테이션',
      ]) {
        expect(joinedText, isNot(contains(forbidden)), reason: forbidden);
      }

      final speakerCounts = <String, int>{};
      for (final scene in scenes) {
        final speaker = scene['speaker'] as String;
        speakerCounts[speaker] = (speakerCounts[speaker] ?? 0) + 1;
      }
      for (final name in <String>[
        '{{playerName}}',
        '김학준',
        '김서아',
        '이지안',
        '최이서',
        '정아린',
        '박하은',
        '한수아',
        '오지우',
        '윤채아',
      ]) {
        expect(speakerCounts[name], greaterThanOrEqualTo(5), reason: name);
      }

      expect(
        scenes.singleWhere(
          (scene) => scene['id'] == 'decimal-final-ten-roster',
        )['line'],
        contains('함부로 넘지 말아야 할 선'),
      );
      expect(joinedText, contains('다음엔 먼저 물어볼게'));
      expect(joinedText, contains('생활 내기는 돈·식사·잠자리 금지'));
      expect(joinedText, contains('50,000원'));
      expect(
        scenes.last['background'],
        endsWith('bg_decimal_trading_floor_dawn_2000_v1.png'),
      );
    },
  );

  test(
    'all generated Decimal backgrounds are production portrait assets',
    () async {
      final decoded =
          jsonDecode(
                File(
                  'assets/dialogue/dialogue-editor-override.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final scenes = (decoded['scenes'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final decimalBackgrounds = scenes
          .map((scene) => scene['background'] as String)
          .where(
            (asset) =>
                asset.contains('/cinematic_soft_painted/decimal'),
          )
          .toSet();
      expect(decimalBackgrounds.length, greaterThanOrEqualTo(10));
      for (final asset in decimalBackgrounds) {
        final relative = asset.replaceFirst('/play/assets/', '');
        final file = File(relative);
        expect(file.existsSync(), isTrue, reason: relative);
        final codec = await ui.instantiateImageCodec(await file.readAsBytes());
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThanOrEqualTo(900), reason: relative);
        expect(
          frame.image.height,
          greaterThanOrEqualTo(1600),
          reason: relative,
        );
        expect(
          frame.image.height / frame.image.width,
          closeTo(16 / 9, 0.01),
          reason: relative,
        );
        frame.image.dispose();
        codec.dispose();
      }
    },
  );
}
