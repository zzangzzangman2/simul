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

  Future<void> completeStoryOnboarding(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('story-intro-computer')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('player-name-input')), '민준');
    await tester.tap(find.byKey(const Key('story-trait-analysis')));
    final motivationNext = find.byKey(const Key('story-next-motivation'));
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    await tester.tap(motivationNext);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('family-rule-report-losses')));
    final familyNext = find.byKey(const Key('story-next-family-rule'));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    await tester.tap(familyNext);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('company-name-input')),
      '별빛 투자',
    );
    await tester.pump();
    final createButton = find.byKey(const Key('create-company-button'));
    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pump();
    await tester.tap(createButton);
    await tester.pumpAndSettle();
  }

  testWidgets('cold open appears before the research desk name', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MillenniumCapitalApp());
    await tester.pumpAndSettle();

    expect(find.text('새 천년,\n낡은 컴퓨터'), findsOneWidget);
    expect(find.byKey(const Key('company-name-input')), findsNothing);
    expect(find.byKey(const Key('story-intro-computer')), findsOneWidget);
  });

  testWidgets('story onboarding saves the family research desk', (
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
