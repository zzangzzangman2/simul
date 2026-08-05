import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all runtime audio assets are present and non-empty', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/audio/bgm/'));
    expect(pubspec, contains('- assets/audio/sfx/'));

    const files = <String>[
      'assets/audio/bgm/title_gentle_theme.ogg',
      'assets/audio/bgm/story_hesitation.ogg',
      'assets/audio/bgm/story_piano_sad.ogg',
      'assets/audio/bgm/finance_sakuya.ogg',
      'assets/audio/bgm/hub_verdure.ogg',
      'assets/audio/bgm/relationship_raindrop.ogg',
      'assets/audio/bgm/market_portside_cafe.ogg',
      'assets/audio/bgm/action_strategy.ogg',
      'assets/audio/bgm/horse_racing_prairie4.ogg',
      'assets/audio/bgm/casino_taisho.ogg',
      'assets/audio/sfx/ui_click.ogg',
      'assets/audio/sfx/ui_confirm.ogg',
      'assets/audio/sfx/ui_error.ogg',
      'assets/audio/sfx/card_shuffle.ogg',
      'assets/audio/sfx/card_slide.ogg',
      'assets/audio/sfx/card_place.ogg',
      'assets/audio/sfx/chip_lay.ogg',
      'assets/audio/sfx/chips_handle.ogg',
      'assets/audio/sfx/chips_collide.ogg',
      'assets/audio/sfx/dice_shake.ogg',
      'assets/audio/sfx/dice_throw.ogg',
      'assets/audio/sfx/horse_gallop_loop.ogg',
      'assets/audio/sfx/crowd_ambience.ogg',
      'assets/audio/sfx/crowd_victory.ogg',
      'assets/audio/sfx/race_bell.ogg',
    ];

    for (final path in files) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Missing $path');
      expect(file.lengthSync(), greaterThan(1000), reason: 'Empty $path');
    }
  });

  test('all BGM paths share one non-overlapping player', () {
    final managerSource = File('lib/game_audio.dart').readAsStringSync();
    final storySource = File(
      'lib/visual_novel_onboarding.dart',
    ).readAsStringSync();

    expect(managerSource, contains('final AudioPlayer _bgmPlayer'));
    expect(managerSource, isNot(contains('_bgmPlayers')));
    expect(storySource, isNot(contains('_storyBgmPlayer')));
    expect(storySource, contains('GameAudio.instance.setDialogueBgm'));
  });

  test(
    'horse racing has dedicated music without changing other action BGM',
    () {
      final managerSource = File('lib/game_audio.dart').readAsStringSync();
      final appSource = File('lib/main.dart').readAsStringSync();

      expect(managerSource, contains('GameAudioScene.horseRacing'));
      expect(managerSource, contains('horse_racing_prairie4.ogg'));
      expect(
        managerSource,
        contains(
          'if (page is HorseRacingMiniGame) return GameAudioScene.horseRacing;',
        ),
      );
      expect(
        managerSource,
        contains('if (page is RiderMiniGame) return GameAudioScene.action;'),
      );
      expect(
        appSource,
        contains(
          'if (widget.horseRacePreviewMode) return GameAudioScene.horseRacing;',
        ),
      );
    },
  );

  test('canonical prologue has complete music and rich scene effects', () {
    final document =
        jsonDecode(
              File(
                'assets/dialogue/dialogue-editor-override.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final scenes = (document['scenes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    expect(scenes, hasLength(302));
    expect(
      scenes.every((scene) => (scene['bgm'] as String? ?? '').isNotEmpty),
      isTrue,
    );
    expect(
      scenes.where(
        (scene) => (scene['soundEffect'] as String? ?? '').isNotEmpty,
      ),
      hasLength(greaterThanOrEqualTo(80)),
    );

    for (final scene in scenes) {
      for (final key in const ['bgm', 'soundEffect']) {
        final path = scene[key] as String? ?? '';
        if (path.isEmpty) continue;
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '${scene['id']}: $path',
        );
      }
    }
  });

  test('license and attribution copy is not embedded in game UI source', () {
    final forbidden = RegExp(
      r'\b(?:PeriTune|Kenney|OpenGameArt|Creative Commons|CC BY|CC0)\b',
      caseSensitive: false,
    );
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      expect(
        forbidden.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: 'Attribution must stay out of game UI: ${file.path}',
      );
    }
  });
}
