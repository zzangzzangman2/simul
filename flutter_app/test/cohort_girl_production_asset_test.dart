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

  test('first-day cohort dialogue uses the approved production sprites', () {
    final decoded =
        jsonDecode(
              File(
                'assets/dialogue/dialogue-editor-override.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(decoded['appearanceVersion'], 11);
    final scenes = (decoded['scenes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final byId = <String, Map<String, dynamic>>{
      for (final scene in scenes) scene['id'] as String: scene,
    };
    const expected = <String, String>{
      'scene-dorm-intro-seoa': 'kim_seoa/09_explaining_ledger_v1.png',
      'scene-dorm-intro-jian': 'lee_jian/09_explaining_mechanism_v1.png',
      'scene-dorm-intro-iseo': 'choi_iseo/01_base_thread_v1.png',
      'scene-dorm-intro-arin': 'jung_arin/09_counting_explain_v1.png',
      'scene-dorm-intro-haeun': 'park_haeun/02_warm_smile_v1.png',
      'scene-dorm-intro-jiwoo': 'oh_jiwoo/09_explaining_report_v1.png',
      'scene-dorm-intro-chaea': 'yoon_chaea/09_explaining_v1.png',
      'scene-dorm-intro-sua': 'han_sua/08_explaining_v1.png',
      'scene-dorm-locker-conflict': 'choi_iseo/07_firm_boundary_v1.png',
      'scene-dorm-locker-apology': 'lee_jian/07_apologetic_boundary_v1.png',
      'scene-dorm-boundary-agreement': 'kim_seoa/08_determined_record_v1.png',
      'scene-dorm-joke': 'han_sua/03_bright_laugh_v1.png',
      'scene-dorm-laughter': 'oh_jiwoo/03_breaking_news_excited_v1.png',
      'scene-dorm-badge-sua': 'han_sua/05_worried_v1.png',
      'scene-dorm-badge-pact': 'han_sua/07_determined_v1.png',
    };
    for (final entry in expected.entries) {
      expect(
        byId[entry.key]?['character'],
        endsWith(entry.value),
        reason: entry.key,
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
    'first dormitory greetings keep all ten students seated in one circle',
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
      final byId = <String, Map<String, dynamic>>{
        for (final scene in scenes) scene['id'] as String: scene,
      };

      expect(
        byId['scene-dorm-intro-circle']?['direction'],
        contains('둥글게 나눠 앉았다'),
      );
      const seatedGreetingIds = <String>[
        'scene-dorm-intro-seoa',
        'scene-dorm-intro-jian',
        'scene-dorm-intro-iseo',
        'scene-dorm-intro-arin',
        'scene-dorm-intro-haeun',
        'scene-dorm-intro-jiwoo',
        'scene-dorm-intro-chaea',
        'scene-dorm-intro-sua',
        'scene-dorm-intro-hakjun',
        'scene-dorm-intro-player',
      ];
      for (final id in seatedGreetingIds) {
        final scene = byId[id];
        expect(scene, isNotNull, reason: id);
        final direction = scene!['direction'] as String;
        expect(
          direction.contains('앉') || direction.contains('걸터앉'),
          isTrue,
          reason: '$id must remain visibly seated',
        );
      }

      expect(byId['scene-dorm-intro-seoa']?['line'], startsWith('안녕'));
      expect(byId['scene-dorm-intro-seoa']?['line'], contains('내 옆'));
      expect(byId['scene-dorm-intro-jian']?['line'], contains('실 뭉치'));
      expect(byId['scene-dorm-intro-iseo']?['line'], contains('아린아'));
      expect(byId['scene-dorm-intro-arin']?['line'], contains('박하은'));
      expect(byId['scene-dorm-intro-haeun']?['line'], contains('지우'));
      expect(byId['scene-dorm-intro-jiwoo']?['line'], contains('윤채아'));
      expect(byId['scene-dorm-intro-chaea']?['line'], contains('수아'));
      expect(byId['scene-dorm-intro-sua']?['line'], contains('남자 둘'));
      expect(byId['scene-dorm-intro-hakjun']?['line'], contains('김학준'));
    },
  );
}
