import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/relationship_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const hanSuaV3Assets = <String>[
    '01_neutral_wavy_v3.png',
    '02_warm_smile_wave_v3.png',
    '03_bright_laugh_v3.png',
    '04_playful_wink_v3.png',
    '05_surprised_v3.png',
    '06_worried_v3.png',
    '07_annoyed_v3.png',
    '08_determined_v3.png',
    '09_explaining_v3.png',
  ];

  const expectedAssetCounts = <String, int>{
    'kim_seoa': 9,
    'lee_jian': 9,
    'choi_iseo': 13,
    'jung_arin': 13,
    'park_haeun': 13,
    'han_sua': 13,
    'oh_jiwoo': 9,
    'yoon_chaea': 13,
    'kim_hakjun': 9,
  };

  const nisCharacterAssets = <String>[
    'cha_eunjoo_selection_officer_v2.png',
    'do_yunseok_planning_coordinator_v1.png',
    'han_gyujin_nis_director_v1.png',
    'jo_mingyeong_rights_auditor_v1.png',
    'lim_seohee_economic_security_chief_v1.png',
    'oh_gyeongtae_facilities_manager_v2.png',
  ];

  test(
    'connected Decimal character sprites use clean production alpha',
    () async {
      Future<void> expectCleanCharacterAlpha(File file) async {
        final codec = await ui.instantiateImageCodec(await file.readAsBytes());
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

        var foregroundPixels = 0;
        var brightNeutralPixels = 0;
        for (var offset = 0; offset < rgba.length; offset += 4) {
          if (rgba[offset + 3] < 128) {
            continue;
          }
          foregroundPixels += 1;
          final red = rgba[offset];
          final green = rgba[offset + 1];
          final blue = rgba[offset + 2];
          final maxChannel = math.max(red, math.max(green, blue));
          final minChannel = math.min(red, math.min(green, blue));
          if (maxChannel - minChannel <= 12 &&
              (red + green + blue) / 3 >= 230) {
            brightNeutralPixels += 1;
          }
        }
        final pixelCount = image.width * image.height;
        expect(
          foregroundPixels / pixelCount,
          lessThan(0.30),
          reason: '${file.path} contains an opaque background field',
        );
        // Jian's approved casual athletic outfit intentionally contains a
        // large white shirt and white sneakers. Keep a narrow character-only
        // allowance while the alpha/background checks above still reject an
        // opaque white matte.
        final brightNeutralLimit = file.path.contains('lee_jian') ? 0.08 : 0.06;
        expect(
          brightNeutralPixels / pixelCount,
          lessThan(brightNeutralLimit),
          reason: '${file.path} contains a white/checker matte field',
        );

        image.dispose();
        codec.dispose();
      }

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
          await expectCleanCharacterAlpha(file);
        }
      }

      final nisDirectory = Directory(
        'assets/images/cinematic_soft_painted/decimal_nis_1999/characters',
      );
      final nisFiles = nisDirectory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.png'))
          .toList();
      expect(
        nisFiles.map((file) => file.uri.pathSegments.last).toSet(),
        nisCharacterAssets.toSet(),
      );
      for (final file in nisFiles) {
        await expectCleanCharacterAlpha(file);
      }

      await expectCleanCharacterAlpha(
        File(
          '../art_references/simul_polished_soft_render_vn_style_anchor_v3.png',
        ),
      );
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

  test('all Han Sua runtime consumers use the exact semantic v3 set', () {
    final sources = <String>[
      File('lib/visual_novel_onboarding.dart').readAsStringSync(),
      File('lib/stock_market_screen.dart').readAsStringSync(),
      File('lib/game/character_profile.dart').readAsStringSync(),
      File('lib/game/relationship_state.dart').readAsStringSync(),
      File('lib/game/organization_state.dart').readAsStringSync(),
      File('../app/editor/character-catalog.ts').readAsStringSync(),
      File('../scripts/build-decimal-dialogue.mjs').readAsStringSync(),
      File('assets/dialogue/dialogue-editor-override.json').readAsStringSync(),
    ].join('\n');
    final actualAssets =
        Directory('assets/images/production_soft_painted/han_sua')
            .listSync()
            .whereType<File>()
            .where(
              (file) =>
                  file.path.endsWith('.png') &&
                  !file.path
                      .split(Platform.pathSeparator)
                      .last
                      .startsWith('10_lobby_'),
            )
            .map((file) => file.path.split(Platform.pathSeparator).last)
            .toList()
          ..sort();
    expect(actualAssets, orderedEquals(hanSuaV3Assets));
    expect(
      RegExp(
        r'production_soft_painted/han_sua/0[1-9]_[^\s"\x27]*quality_v2\.png',
      ).allMatches(sources),
      isEmpty,
    );
    for (final asset in hanSuaV3Assets) {
      expect(sources, contains(asset), reason: asset);
    }
  });

  test('legacy Han Sua filenames migrate in both editor runtimes', () {
    final editor = File('../app/editor/page.tsx').readAsStringSync();
    final flutter = File('lib/visual_novel_onboarding.dart').readAsStringSync();
    const migrations = <String, String>{
      '01_neutral_quality_v2.png': '01_neutral_wavy_v3.png',
      '02_warm_smile_quality_v2.png': '02_warm_smile_wave_v3.png',
      '03_bright_laugh_quality_v2.png': '03_bright_laugh_v3.png',
      '04_surprised_quality_v2.png': '05_surprised_v3.png',
      '05_worried_quality_v2.png': '06_worried_v3.png',
      '06_annoyed_quality_v2.png': '07_annoyed_v3.png',
      '07_determined_quality_v2.png': '08_determined_v3.png',
      '08_explaining_quality_v2.png': '09_explaining_v3.png',
    };
    for (final entry in migrations.entries) {
      expect(editor, contains(entry.key), reason: entry.key);
      expect(editor, contains(entry.value), reason: entry.value);
      expect(flutter, contains(entry.key), reason: entry.key);
      expect(flutter, contains(entry.value), reason: entry.value);
    }
    expect(editor, contains('character: migrateHanSuaCharacterAsset'));
    expect(flutter, contains('_migrateHanSuaCharacterAsset(normalized)'));
  });

  test('Project Decimal dialogue keeps all eight approved identities', () {
    final decoded =
        jsonDecode(
              File(
                'assets/dialogue/dialogue-editor-override.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(decoded['appearanceVersion'], 19);
    expect(decoded['contentVersion'], 5);
    final scenes = (decoded['scenes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(scenes.length, 302);
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
        anyOf(
          endsWith('01_neutral_wavy_v3.png'),
          endsWith('03_bright_laugh_v3.png'),
        ),
        reason: scene['id'] as String,
      );
    }
    final playerScenes = scenes.where(
      (scene) => scene['speaker'] == '{{playerName}}',
    );
    expect(playerScenes, isNotEmpty);
    for (final scene in playerScenes) {
      expect(scene['character'], isEmpty, reason: scene['id'] as String);
    }
    final hakjunScenes = scenes.where((scene) => scene['speaker'] == '김학준');
    expect(hakjunScenes, isNotEmpty);
    final hakjunAssets = <String>{};
    for (final scene in hakjunScenes) {
      final asset = scene['character'] as String;
      expect(asset, contains('/production_soft_painted/kim_hakjun/'));
      hakjunAssets.add(asset.split('/').last);
    }
    expect(hakjunAssets, {
      '01_neutral_crosscheck_uniform_v4.png',
      '02_explaining_rules_uniform_v4.png',
      '03_skeptical_condition_check_uniform_v4.png',
      '04_surprised_hidden_clause_uniform_v4.png',
      '05_worried_unfair_loss_uniform_v4.png',
      '06_firm_objection_uniform_v4.png',
      '07_determined_verification_uniform_v4.png',
      '08_calculating_notes_uniform_v4.png',
      '09_restrained_team_smile_uniform_v4.png',
    });
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
          .where((asset) => asset.contains('/cinematic_soft_painted/decimal'))
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
