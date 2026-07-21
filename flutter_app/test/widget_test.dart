import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_persistence.dart';
import 'package:millennium_capital/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> advanceDialogue(WidgetTester tester, int count) async {
    for (var index = 0; index < count; index++) {
      await tester.tap(find.byKey(const Key('story-continue')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> completeStoryOnboarding(WidgetTester tester) async {
    await advanceDialogue(tester, 6);
    await tester.tap(find.byKey(const Key('story-intro-computer')));
    await tester.pumpAndSettle();

    await advanceDialogue(tester, 4);
    await tester.enterText(find.byKey(const Key('player-name-input')), '민준');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('story-next-name')));
    await tester.tap(find.byKey(const Key('story-next-name')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('story-trait-analysis')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('family-rule-report-losses')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('company-name-input')),
      '별빛 투자',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('create-company-button')));
    await tester.tap(find.byKey(const Key('create-company-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('prologue explains the setting before showing a choice', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MillenniumCapitalApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('새 천년을 세 분 앞둔 밤'), findsOneWidget);
    expect(find.textContaining('작은방'), findsOneWidget);
    expect(find.byKey(const Key('story-intro-computer')), findsNothing);
    expect(find.byKey(const Key('company-name-input')), findsNothing);

    await advanceDialogue(tester, 6);
    expect(find.byKey(const Key('story-intro-computer')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('visual novel onboarding saves the family research desk', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MillenniumCapitalApp());
    await tester.pumpAndSettle();

    await completeStoryOnboarding(tester);

    expect(find.textContaining('별빛 투자 투자연구소'), findsOneWidget);
    expect(find.text('FAMILY RESEARCH DESK'), findsOneWidget);
    expect(find.text('가족 신뢰'), findsOneWidget);
    expect(find.text('안건 열기'), findsOneWidget);
  });

  testWidgets('existing v1 save is restored with safe story defaults', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: jsonEncode({
        'version': 1,
        'companyName': '이어하기 연구소',
        'day': 8,
        'cash': 900000,
        'team': 1,
      }),
    });

    await tester.pumpWidget(const MillenniumCapitalApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('이어하기 연구소'), findsOneWidget);
    expect(find.textContaining('DAY 8'), findsWidgets);
    expect(find.text('가족 신뢰'), findsOneWidget);
  });

  testWidgets('first research sheet is one-hand operable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: jsonEncode({
        'version': 1,
        'companyName': '모바일 연구소',
        'day': 1,
        'cash': 1000000,
        'team': 1,
      }),
    });

    await tester.pumpWidget(const MillenniumCapitalApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-decisions-button')));
    await tester.pumpAndSettle();

    expect(find.text('첫 기업 조사노트'), findsWidgets);
    final option = find.byKey(const Key('decision-option-research_products'));
    expect(option, findsOneWidget);
    expect(tester.getSize(option).height, greaterThanOrEqualTo(44));

    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(find.text('시간을 보내도 좋아요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('market ticks and opens a stock detail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      GamePersistence.saveKey: jsonEncode({
        'version': 1,
        'companyName': '별빛 투자',
        'day': 1,
        'cash': 1000000,
        'team': 1,
      }),
    });

    await tester.pumpWidget(const MillenniumCapitalApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-market-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('실시간 인기 종목'), findsOneWidget);
    expect(find.byKey(const Key('stock-row-005930')), findsOneWidget);
    final before = tester
        .widget<Text>(find.byKey(const Key('stock-rate-005930')))
        .data;
    await tester.pump(const Duration(milliseconds: 950));
    final after = tester
        .widget<Text>(find.byKey(const Key('stock-rate-005930')))
        .data;
    expect(after, isNot(before));

    await tester.tap(find.byKey(const Key('stock-row-005930')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('삼성전자'), findsWidgets);
    expect(find.byKey(const Key('stock-detail-price')), findsOneWidget);
    expect(find.byKey(const Key('write-research-note-button')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('historical-executive-section')),
    );
    expect(find.text('그날의 경영진'), findsOneWidget);
    expect(find.text('이건희'), findsOneWidget);
    expect(find.text('윤종용'), findsOneWidget);
    expect(
      find.byKey(const Key('executive-portrait-lee_kun_hee')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'organization uses upper-body portrait and cards for assignment',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        GamePersistence.saveKey: jsonEncode({
          'version': 1,
          'companyName': '가족 배치 연구소',
          'day': 1,
          'cash': 1000000,
          'team': 1,
        }),
      });

      await tester.pumpWidget(const MillenniumCapitalApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('open-organization-button')),
      );
      await tester.tap(find.byKey(const Key('open-organization-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('employee-count-badge')), findsOneWidget);
      expect(find.text('정식 직원 0명'), findsOneWidget);
      expect(
        find.byKey(const Key('assignment-portrait-mother')),
        findsOneWidget,
      );

      final fatherCard = find.byKey(const Key('assignment-card-father'));
      await tester.ensureVisible(fatherCard);
      await tester.tap(fatherCard);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('assignment-portrait-father')),
        findsOneWidget,
      );

      final helpButton = find.byKey(const Key('family-help-father'));
      await tester.ensureVisible(helpButton);
      await tester.tap(helpButton);
      await tester.pumpAndSettle();
      expect(find.text('오늘 도움 완료'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'dish mini-game requires the full cleaning sequence before reward',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: DishwashingMiniGame()));
      await tester.pumpAndSettle();

      for (var dish = 0; dish < 5; dish++) {
        await tester.tap(find.byKey(const Key('dish-rinse')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('dish-scrub')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('dish-finish')));
        await tester.pump();
      }

      expect(find.byKey(const Key('work-result-card')), findsOneWidget);
      expect(find.text('100점'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'stationery mini-game sorts every item into its period shop shelf',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: StationerySortMiniGame()),
      );
      await tester.pumpAndSettle();

      for (final category in [
        'school',
        'school',
        'snack',
        'toy',
        'school',
        'snack',
        'toy',
        'school',
      ]) {
        await tester.tap(find.byKey(Key('sort-$category')));
        await tester.pump();
      }

      expect(find.byKey(const Key('work-result-card')), findsOneWidget);
      expect(find.text('100점'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('flea market mini-game checks real won change calculations', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: FleaMarketMiniGame()));
    await tester.pumpAndSettle();

    for (final change in [800, 2500, 3200, 6500, 5800]) {
      await tester.tap(find.byKey(Key('change-$change')));
      await tester.pump();
    }

    expect(find.byKey(const Key('work-result-card')), findsOneWidget);
    expect(find.text('100점'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'completed work adds cash and returns to the persistent work hub',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        GamePersistence.saveKey: jsonEncode({
          'version': 1,
          'companyName': '0원 연구소',
          'day': 1,
          'cash': 0,
          'team': 1,
        }),
      });

      await tester.pumpWidget(const MillenniumCapitalApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('open-work-button')));
      await tester.tap(find.byKey(const Key('open-work-button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('시간당 1,600원'), findsOneWidget);

      await tester.tap(find.byKey(const Key('work-activity-dishes')));
      await tester.pumpAndSettle();
      for (var dish = 0; dish < 5; dish++) {
        await tester.tap(find.byKey(const Key('dish-rinse')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('dish-scrub')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('dish-finish')));
        await tester.pump();
      }
      await tester.tap(find.byKey(const Key('claim-work-reward')));
      await tester.pumpAndSettle();

      final cash = tester.widget<Text>(
        find.byKey(const Key('seed-money-cash')),
      );
      expect(cash.data, '800원');
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [const Size(390, 844), const Size(360, 800)]) {
    testWidgets(
      'office has no layout exception at ${size.width}x${size.height}',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({
          GamePersistence.saveKey: jsonEncode({
            'version': 1,
            'companyName': '아주 긴 이름의 모바일 투자 연구소',
            'day': 1,
            'cash': 1000000,
            'team': 1,
          }),
        });

        await tester.pumpWidget(const MillenniumCapitalApp());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('advance-day-button')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
