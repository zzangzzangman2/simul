import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/horse_racing.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/main.dart';

void main() {
  Future<void> setPhoneSurface(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
  }

  Future<void> finishTellerTyping(WidgetTester tester) async {
    await tester.tapAt(const Offset(195, 150));
    await tester.pump();
  }

  Future<void> openHorseRaceBettingCard(WidgetTester tester) async {
    expect(
      find.byKey(const Key('horse-race-teller-welcome-screen')),
      findsOneWidget,
    );
    await finishTellerTyping(tester);
    await tester.tap(find.byKey(const Key('horse-race-teller-welcome-next')));
    await tester.pump();
    await finishTellerTyping(tester);
    await tester.tap(find.byKey(const Key('horse-race-teller-open-guide')));
    await tester.pump();
    expect(
      find.byKey(const Key('horse-race-teller-guide-screen')),
      findsOneWidget,
    );
    await finishTellerTyping(tester);
    await tester.tap(find.byKey(const Key('horse-race-teller-open-card')));
    await tester.pump();
  }

  Future<void> startLiveRaceFromHandover(
    WidgetTester tester,
    HorseRaceCard race,
  ) async {
    await tester.tap(find.byKey(const Key('horse-race-teller-watch-race')));
    await tester.pump();
    expect(
      find.byKey(const Key('horse-race-broadcast-lineup')),
      findsOneWidget,
    );
    expect(find.text('최근 5전'), findsOneWidget);
    expect(find.text('단승'), findsOneWidget);
    for (final entrant in race.entrants) {
      expect(
        find.byKey(Key('horse-race-broadcast-runner-${entrant.id}')),
        findsOneWidget,
      );
    }
    await tester.tap(find.byKey(const Key('horse-race-broadcast-start-now')));
    await tester.pump();
    expect(find.byKey(const Key('horse-race-broadcast-lineup')), findsNothing);
    expect(find.byKey(const Key('horse-race-live-track')), findsOneWidget);
  }

  testWidgets(
    'teller dialogue uses the story style and advances from the image',
    (tester) async {
      await setPhoneSurface(tester);
      final race = buildAfternoonHorseRace(
        simulationSeed: 'horse-widget-dialogue',
        day: 8,
      );
      await tester.pumpWidget(
        MaterialApp(home: HorseRacingMiniGame(race: race, availableCash: 5000)),
      );
      await tester.pump();

      await finishTellerTyping(tester);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('story-line-text')))
            .style
            ?.fontFamily,
        'Maplestory',
      );
      await tester.tapAt(const Offset(195, 150));
      await tester.pump();
      expect(
        find.byKey(const Key('horse-race-teller-open-guide-anywhere')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('horse-race-teller-welcome-screen')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('race is always online and offline requests PC power off', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final race = buildAfternoonHorseRace(
      simulationSeed: 'horse-widget-online-only',
      day: 8,
    );
    var powerOffCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HorseRacingMiniGame(
          race: race,
          availableCash: 5000,
          onPowerOff: () => powerOffCount += 1,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('국가망 경마 · 전자 마권 창구'), findsOneWidget);
    expect(find.text('국가망 · 온라인'), findsOneWidget);
    await openHorseRaceBettingCard(tester);
    expect(find.text('온라인'), findsOneWidget);
    expect(find.text('오프라인'), findsOneWidget);
    expect(find.text('PC 전원 끄기'), findsOneWidget);
    await tester.tap(find.byKey(const Key('horse-race-mode-offline')));
    await tester.pump();
    expect(powerOffCount, 1);
    expect(find.textContaining('현장'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horse race shows full paddock card and three bet types', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final race = buildAfternoonHorseRace(
      simulationSeed: 'horse-widget-card',
      day: 8,
    );
    await tester.pumpWidget(
      MaterialApp(home: HorseRacingMiniGame(race: race, availableCash: 5000)),
    );
    await tester.pump();
    await openHorseRaceBettingCard(tester);

    expect(find.byKey(const Key('horse-race-betting-screen')), findsOneWidget);
    expect(
      find.byKey(const Key('horse-race-access-mode-selector')),
      findsOneWidget,
    );
    expect(find.text('온라인'), findsOneWidget);
    expect(find.text('국가망 접속 중'), findsOneWidget);
    expect(find.text('오프라인'), findsOneWidget);
    expect(find.text('PC 전원 끄기'), findsOneWidget);
    expect(
      Theme.of(
        tester.element(find.byKey(const Key('horse-race-betting-screen'))),
      ).textTheme.bodyMedium?.fontFamily,
      'Maplestory',
    );
    expect(find.byKey(const Key('horse-race-venue-hero')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-ticket-slip')), findsOneWidget);
    expect(find.byKey(const Key('horse-bet-win')), findsOneWidget);
    expect(find.byKey(const Key('horse-bet-place')), findsOneWidget);
    expect(find.byKey(const Key('horse-bet-quinella')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-start')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('horse-race-start')))
          .onPressed,
      isNull,
      reason: '소개 화면 연속 탭만으로 기본 마권이 접수되면 안 된다.',
    );
    expect(find.text('말·베팅액을 한 번 선택해 주세요'), findsOneWidget);
    expect(find.textContaining('적중 가정 국가 수수료'), findsOneWidget);
    expect(find.text('출전마 8두'), findsOneWidget);
    final selectedSpriteRect = tester.getRect(
      find.byKey(const Key('horse-selected-sprite')),
    );
    final selectedOddsRect = tester.getRect(
      find.byKey(const Key('horse-selected-win-odds')),
    );
    expect(
      selectedOddsRect.bottom,
      lessThanOrEqualTo(selectedSpriteRect.top),
      reason: 'The win-odds badge must not cover the selected horse art.',
    );
    for (final entrant in race.entrants) {
      expect(find.byKey(Key('horse-entry-${entrant.id}')), findsOneWidget);
      expect(find.byKey(Key('horse-detail-${entrant.id}')), findsOneWidget);
    }

    final firstDetails = find.byKey(
      Key('horse-detail-${race.entrants.first.id}'),
    );
    tester.widget<InkWell>(firstDetails).onTap!();
    await tester.pumpAndSettle();
    expect(
      find.byKey(Key('horse-detail-sheet-${race.entrants.first.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(Key('horse-signature-skill-${race.entrants.first.id}')),
      findsOneWidget,
    );
    expect(
      find.textContaining(horseRaceSignatureSkill(race.entrants.first).name),
      findsOneWidget,
    );
    final firstSkill = horseRaceSignatureSkill(race.entrants.first);
    expect(find.text('효과 · ${firstSkill.effectLabel}'), findsOneWidget);
    expect(find.text('조건 · ${firstSkill.triggerLabel}'), findsOneWidget);
    expect(
      find.text('발동 구간 ${firstSkill.phaseLabel}  ·  지속 약 2초  ·  실제 전개 반영'),
      findsOneWidget,
    );
    expect(find.text('최근 10회 상세 전적'), findsOneWidget);
    expect(
      find.byKey(Key('horse-performance-${race.entrants.first.id}-0')),
      findsOneWidget,
    );
    final lastPerformance = find.byKey(
      Key('horse-performance-${race.entrants.first.id}-9'),
    );
    await tester.scrollUntilVisible(
      lastPerformance,
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(lastPerformance, findsOneWidget);
    Navigator.of(tester.element(lastPerformance)).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('horse-bet-quinella')));
    await tester.tap(find.byKey(const Key('horse-bet-quinella')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('horse-race-start')))
          .onPressed,
      isNull,
    );
    final secondHorse = find.byKey(Key('horse-entry-${race.entrants[1].id}'));
    await tester.ensureVisible(secondHorse);
    await tester.tap(secondHorse);
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('horse-race-start')))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('stake buttons use 2, 5, 10, and 30 percent of available cash', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final race = buildAfternoonHorseRace(
      simulationSeed: 'horse-widget-stake-percent',
      day: 8,
    );
    await tester.pumpWidget(
      MaterialApp(home: HorseRacingMiniGame(race: race, availableCash: 50000)),
    );
    await tester.pump();
    await openHorseRaceBettingCard(tester);

    expect(find.byKey(const Key('horse-stake-1000')), findsOneWidget);
    expect(find.byKey(const Key('horse-stake-2500')), findsOneWidget);
    expect(find.byKey(const Key('horse-stake-5000')), findsOneWidget);
    expect(find.byKey(const Key('horse-stake-15000')), findsOneWidget);
    expect(find.text('2%'), findsOneWidget);
    expect(find.text('5%'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('horse-stake-15000')));
    await tester.pump();
    expect(find.text('15,000원 베팅하고 경주 보기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('high-value cash shows and applies the leisure stake cap', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final race = buildAfternoonHorseRace(
      simulationSeed: 'horse-widget-high-value-cap',
      day: 8,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HorseRacingMiniGame(race: race, availableCash: 100000000000),
      ),
    );
    await tester.pump();
    await openHorseRaceBettingCard(tester);

    expect(
      find.byKey(const Key('horse-race-leisure-stake-cap')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('horse-stake-1000000')), findsOneWidget);
    expect(find.byKey(const Key('horse-stake-2500000')), findsOneWidget);
    expect(find.byKey(const Key('horse-stake-5000000')), findsOneWidget);
    expect(find.byKey(const Key('horse-stake-15000000')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('2000 national-account PC exposes the one-bet horse racing app', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    const engine = GameEngine();
    final base = engine.createNewGame(
      '평일 경마 앱 테스트',
      worldSeed: 'horse-home-computer',
    );
    var day = base.day;
    while (base.dateForDay(day).weekday >= DateTime.saturday) {
      day += 1;
    }
    final state = engine
        .markNationalNetworkBriefingSeen(engine.markMarketTutorialSeen(base))
        .copyWith(
          day: day,
          cash: base.cash + 5000,
          marketMinute: krxCloseMinute,
          decisions: const [],
        );
    var horseRaceOpenCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: HomeComputerScreen(
          state: state,
          onOpenStockMarket: (current) async => current,
          onOpenCompanyManagement: (current) async => current,
          onOpenRealEstate: (current) async => current,
          onOpenBusiness: (current) async => current,
          onOpenCasino: (current) async => current,
          onOpenHorseRace: (current) async {
            horseRaceOpenCount += 1;
            return current;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final app = find.byKey(const Key('computer-horse-racing-app'));
    expect(app, findsOneWidget);
    expect(
      find.byKey(const Key('after-market-leisure-banner')),
      findsOneWidget,
    );
    expect(find.textContaining('장 마감 완료'), findsOneWidget);
    expect(find.text('베팅 0/1회'), findsOneWidget);
    await tester.tap(app);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('after-market-horse-gateway')), findsOneWidget);
    expect(find.textContaining('원격 패독'), findsOneWidget);
    expect(horseRaceOpenCount, 0);
    await tester.tap(find.byKey(const Key('after-market-horse-confirm')));
    await tester.pumpAndSettle();
    expect(horseRaceOpenCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('after-market leisure apps stay locked before the stock close', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    const engine = GameEngine();
    final base = engine.createNewGame(
      '마감 전 PC 잠금 테스트',
      worldSeed: 'after-market-pc-lock',
    );
    var day = base.day;
    while (base.dateForDay(day).weekday >= DateTime.saturday) {
      day += 1;
    }
    final state = engine
        .markNationalNetworkBriefingSeen(engine.markMarketTutorialSeen(base))
        .copyWith(
          day: day,
          cash: base.cash + 5000,
          marketMinute: krxCloseMinute - 1,
          decisions: const [],
        );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeComputerScreen(
          state: state,
          onOpenStockMarket: (current) async => current,
          onOpenCompanyManagement: (current) async => current,
          onOpenRealEstate: (current) async => current,
          onOpenBusiness: (current) async => current,
          onOpenCasino: (current) async => current,
          onOpenHorseRace: (current) async => current,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('주식장 마감 15:00 뒤 열림'), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(find.byKey(const Key('computer-horse-racing-app')))
          .onTap,
      isNull,
    );
    expect(
      tester
          .widget<InkWell>(find.byKey(const Key('computer-casino-live-app')))
          .onTap,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'teacher explains costs and state recovery before unlock effect',
    (tester) async {
      await setPhoneSurface(tester);
      const engine = GameEngine();
      final base = engine.createNewGame(
        '국가망 사전 안내 테스트',
        worldSeed: 'national-network-briefing',
      );
      var day = base.day;
      while (base.dateForDay(day).weekday >= DateTime.saturday) {
        day += 1;
      }
      var saved = engine
          .markMarketTutorialSeen(base)
          .copyWith(
            day: day,
            marketMinute: krxCloseMinute,
            decisions: const [],
          );

      await tester.pumpWidget(
        MaterialApp(
          home: HomeComputerScreen(
            state: saved,
            onOpenStockMarket: (current) async => current,
            onOpenCompanyManagement: (current) async => current,
            onOpenRealEstate: (current) async => current,
            onOpenBusiness: (current) async => current,
            onCompleteNationalNetworkBriefing: () async {
              saved = engine.markNationalNetworkBriefingSeen(saved);
              return saved;
            },
            onOpenCasino: (current) async => current,
            onOpenHorseRace: (current) async => current,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('national-network-briefing-dialog')),
        findsOneWidget,
      );
      expect(find.textContaining('현장에 가는 서비스가 아니라'), findsOneWidget);
      expect(
        find.byKey(const Key('national-network-unlock-effect')),
        findsNothing,
      );

      for (var page = 0; page < 4; page++) {
        if (page == 1) {
          expect(find.textContaining('최소는 500원'), findsOneWidget);
        }
        if (page == 2) {
          expect(find.textContaining('한 판은 30분'), findsOneWidget);
        }
        if (page == 3) {
          expect(find.textContaining('확정 이익에서만 20%'), findsOneWidget);
        }
        await tester.tap(
          find.byKey(const Key('national-network-briefing-next')),
        );
        await tester.pumpAndSettle();
      }

      expect(
        find.byKey(const Key('national-network-unlock-effect')),
        findsOneWidget,
      );
      expect(saved.story.nationalNetworkBriefingSeen, isFalse);
      await tester.tap(
        find.byKey(const Key('national-network-briefing-complete')),
      );
      await tester.pumpAndSettle();
      expect(saved.story.nationalNetworkBriefingSeen, isTrue);
      expect(
        find.byKey(const Key('national-network-briefing-dialog')),
        findsNothing,
      );
      expect(find.text('접속 가능 · 1판 30분'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('eight animated horses run and produce an official result', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final race = buildAfternoonHorseRace(
      simulationSeed: 'horse-widget-live',
      day: 8,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HorseRacingMiniGame(
          race: race,
          availableCash: 5000,
          previewMode: true,
          raceDuration: const Duration(milliseconds: 700),
        ),
      ),
    );
    await tester.pump();
    await openHorseRaceBettingCard(tester);
    await tester.tap(find.byKey(const Key('horse-stake-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('horse-race-start')));
    await tester.pump();
    expect(
      find.byKey(const Key('horse-race-teller-acceptance-screen')),
      findsOneWidget,
    );
    await finishTellerTyping(tester);
    await tester.tap(find.byKey(const Key('horse-race-teller-confirm-ticket')));
    await tester.pump();
    expect(
      find.byKey(const Key('horse-race-teller-handover-screen')),
      findsOneWidget,
    );
    await finishTellerTyping(tester);
    await startLiveRaceFromHandover(tester, race);

    expect(find.byKey(const Key('horse-race-running-screen')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-live-track')), findsOneWidget);
    expect(
      find.byKey(const Key('horse-race-straight-panorama')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('horse-race-straight-lanes')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-impact-layer')), findsNothing);
    expect(find.byKey(const Key('horse-race-announcer')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-winner-badge')), findsNothing);
    expect(find.byKey(const Key('horse-race-starting-gate')), findsOneWidget);
    for (final entrant in race.entrants) {
      expect(find.byKey(Key('horse-live-${entrant.id}')), findsOneWidget);
    }
    final laneCenters = race.entrants
        .map(
          (entrant) => tester
              .getRect(find.byKey(Key('horse-live-${entrant.id}')))
              .center
              .dy,
        )
        .toList(growable: false);
    final laneGaps = <double>[
      for (var index = 1; index < laneCenters.length; index++)
        laneCenters[index] - laneCenters[index - 1],
    ];
    for (final gap in laneGaps) {
      expect(gap, closeTo(laneGaps.first, 3.0));
    }
    final announcerRect = tester.getRect(
      find.byKey(const Key('horse-race-announcer')),
    );
    final firstLaneTop = tester
        .getRect(find.byKey(Key('horse-live-${race.entrants.first.id}')))
        .top;
    expect(announcerRect.bottom, lessThan(firstLaneTop));

    expect(find.byKey(const Key('horse-race-fixed-finish-line')), findsNothing);
    final trackRect = tester.getRect(
      find.byKey(const Key('horse-race-live-track')),
    );
    final liveDialogueRect = tester.getRect(
      find.byKey(const Key('horse-race-live-dialogue')),
    );
    expect(liveDialogueRect.top, greaterThanOrEqualTo(trackRect.bottom));
    const embeddedFinishCenterRatio = (0.843 + 0.860) / 2;
    final earlyPanoramaRect = tester.getRect(
      find.byKey(const Key('horse-race-straight-panorama')),
    );
    final earlyEmbeddedFinishX =
        earlyPanoramaRect.left +
        earlyPanoramaRect.width * embeddedFinishCenterRatio;
    expect(earlyPanoramaRect.width, closeTo(trackRect.width * 1.8, 1.0));
    expect(earlyEmbeddedFinishX, greaterThan(trackRect.right));
    expect(
      find.byKey(const Key('horse-race-finish-line-visibility')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 140));
    expect(find.byKey(const Key('horse-race-starting-gate')), findsNothing);
    expect(
      find.byKey(const Key('horse-race-straight-panorama')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('horse-race-course-label')), findsOneWidget);
    expect(find.textContaining('m 직선'), findsOneWidget);
    for (final entrant in race.entrants) {
      expect(find.byKey(Key('horse-live-${entrant.id}')), findsOneWidget);
    }
    final midPanoramaRect = tester.getRect(
      find.byKey(const Key('horse-race-straight-panorama')),
    );
    final midEmbeddedFinishX =
        midPanoramaRect.left +
        midPanoramaRect.width * embeddedFinishCenterRatio;
    expect(midEmbeddedFinishX, lessThan(earlyEmbeddedFinishX));
    expect(midEmbeddedFinishX, greaterThan(trackRect.right));

    await tester.pump(const Duration(milliseconds: 310));
    expect(
      find.byKey(const Key('horse-race-straight-panorama')),
      findsOneWidget,
    );
    final latePanoramaRect = tester.getRect(
      find.byKey(const Key('horse-race-straight-panorama')),
    );
    final lateEmbeddedFinishX =
        latePanoramaRect.left +
        latePanoramaRect.width * embeddedFinishCenterRatio;
    expect(lateEmbeddedFinishX, lessThan(midEmbeddedFinishX));
    expect(
      lateEmbeddedFinishX,
      greaterThan(trackRect.left + trackRect.width * 0.82),
    );
    expect(lateEmbeddedFinishX, lessThan(trackRect.right));
    final winnerBeforeCrossing = tester
        .getRect(find.byKey(Key('horse-live-${race.finishOrder.first}')))
        .right;
    expect(winnerBeforeCrossing, lessThan(lateEmbeddedFinishX));
    final lateRunnerRights =
        race.entrants
            .map(
              (entrant) => tester
                  .getRect(find.byKey(Key('horse-live-${entrant.id}')))
                  .right,
            )
            .toList(growable: false)
          ..sort();
    expect(
      lateRunnerRights.last - lateRunnerRights.first,
      greaterThan(trackRect.width * 0.14),
    );

    await tester.pump(const Duration(milliseconds: 170));
    await tester.pump(const Duration(milliseconds: 25));
    final winnerAfterCrossing = tester
        .getRect(find.byKey(Key('horse-live-${race.finishOrder.first}')))
        .right;
    final afterCrossingPanoramaRect = tester.getRect(
      find.byKey(const Key('horse-race-straight-panorama')),
    );
    final afterCrossingFinishX =
        afterCrossingPanoramaRect.left +
        afterCrossingPanoramaRect.width * embeddedFinishCenterRatio;
    expect(afterCrossingFinishX, lessThan(lateEmbeddedFinishX));
    expect(
      afterCrossingFinishX,
      closeTo(trackRect.left + trackRect.width * 0.82, 1.0),
    );
    expect(winnerAfterCrossing, greaterThan(winnerBeforeCrossing));
    expect(winnerAfterCrossing, greaterThan(afterCrossingFinishX));
    expect(find.byKey(const Key('horse-race-winner-badge')), findsOneWidget);
    expect(find.text('1등!'), findsOneWidget);

    final lastHorseId = race.finishOrder.last;
    final lastHorseAfterCrossing = tester
        .getRect(find.byKey(Key('horse-live-$lastHorseId')))
        .right;
    expect(lastHorseAfterCrossing, greaterThan(afterCrossingFinishX));

    await tester.pump(const Duration(milliseconds: 28));
    final winnerRunOut = tester
        .getRect(find.byKey(Key('horse-live-${race.finishOrder.first}')))
        .right;
    final lastHorseRunOut = tester
        .getRect(find.byKey(Key('horse-live-$lastHorseId')))
        .right;
    expect(
      winnerRunOut,
      greaterThan(winnerAfterCrossing + trackRect.width * 0.05),
    );
    expect(lastHorseRunOut, greaterThan(lastHorseAfterCrossing + 5));

    await tester.pump(const Duration(milliseconds: 72));
    await tester.pump();
    expect(find.byKey(const Key('horse-race-result-screen')), findsOneWidget);
    expect(
      find.byKey(const Key('horse-race-teller-result-dialogue')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('horse-race-official-broadcast-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('horse-race-photo-finish-image')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('horse-race-official-record-board')),
      findsOneWidget,
    );
    final boardRect = tester.getRect(
      find.byKey(const Key('horse-race-official-record-board')),
    );
    expect(boardRect.height, closeTo(439, 2));
    expect(find.text('공식 경주 성적'), findsOneWidget);
    expect(find.text('공식 확정'), findsAtLeastNWidgets(1));
    expect(find.byKey(const Key('horse-race-winning-record')), findsOneWidget);
    expect(
      find.text(
        horseRaceRecordLabel(
          horseRaceFinishTimeSeconds(
            race: race,
            entrant: race.entrantById(race.finishOrder.first),
          ),
        ),
      ),
      findsAtLeastNWidgets(2),
    );
    for (final entrant in race.entrants) {
      expect(
        find.byKey(Key('horse-result-record-${entrant.id}')),
        findsOneWidget,
      );
      final rowRect = tester.getRect(
        find.byKey(Key('horse-result-record-${entrant.id}')),
      );
      expect(rowRect.top, greaterThan(boardRect.top));
      expect(rowRect.bottom, lessThan(boardRect.bottom));
    }
    await tester.scrollUntilVisible(
      find.byKey(const Key('horse-race-payout-card')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('horse-race-payout-card')), findsOneWidget);
    expect(find.byKey(const Key('horse-race-confirm-result')), findsOneWidget);
    expect(find.text('메인으로 가기'), findsOneWidget);
    await tester.tap(find.byKey(const Key('horse-race-confirm-result')));
    await tester.pump();
    expect(find.byKey(const Key('horse-race-betting-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a real pace surge triggers the race activation presentation', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final race = buildAfternoonHorseRace(
      simulationSeed: 'horse-widget-surge',
      day: 12,
    );
    const raceDuration = Duration(milliseconds: 1600);
    final selected =
        ([...race.entrants]..sort(
              (left, right) =>
                  horseRaceBroadcastSurgeAt(
                    race: race,
                    entrant: left,
                  ).compareTo(
                    horseRaceBroadcastSurgeAt(race: race, entrant: right),
                  ),
            ))
            .first;
    await tester.pumpWidget(
      MaterialApp(
        home: HorseRacingMiniGame(
          race: race,
          availableCash: 5000,
          previewMode: true,
          raceDuration: raceDuration,
        ),
      ),
    );
    await tester.pump();
    await openHorseRaceBettingCard(tester);
    final selectedEntry = find.byKey(Key('horse-entry-${selected.id}'));
    tester
        .widget<InkWell>(
          find
              .descendant(of: selectedEntry, matching: find.byType(InkWell))
              .first,
        )
        .onTap!();
    await tester.pump();
    await tester.tap(find.byKey(const Key('horse-race-start')));
    await tester.pump();
    await finishTellerTyping(tester);
    await tester.tap(find.byKey(const Key('horse-race-teller-confirm-ticket')));
    await tester.pump();
    await finishTellerTyping(tester);
    await startLiveRaceFromHandover(tester, race);

    final surgeAt =
        horseRaceBroadcastSurgeAt(race: race, entrant: selected) * 0.84;
    await tester.pump(
      Duration(
        milliseconds: (raceDuration.inMilliseconds * surgeAt).round() + 18,
      ),
    );

    expect(find.byKey(Key('horse-race-surge-${selected.id}')), findsOneWidget);
    expect(
      find.byKey(Key('horse-race-skill-tag-${selected.id}')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('horse-race-surge-frame')), findsNothing);
    expect(find.byKey(const Key('horse-race-surge-banner')), findsNothing);
    expect(find.text(horseRaceSignatureSkill(selected).name), findsOneWidget);
    final selectedRunnerRect = tester.getRect(
      find.byKey(Key('horse-live-${selected.id}')),
    );
    final selectedSkillRect = tester.getRect(
      find.byKey(Key('horse-race-skill-tag-${selected.id}')),
    );
    expect(
      selectedSkillRect.overlaps(selectedRunnerRect),
      isFalse,
      reason: 'The signature tag must sit beside, not cover, its horse.',
    );
    for (final taggedEntrant in race.entrants) {
      final tagFinder = find.byKey(
        Key('horse-race-skill-tag-${taggedEntrant.id}'),
      );
      if (tagFinder.evaluate().isEmpty) continue;
      final tagRect = tester.getRect(tagFinder);
      for (final runner in race.entrants) {
        expect(
          tagRect.overlaps(
            tester.getRect(find.byKey(Key('horse-live-${runner.id}'))),
          ),
          isFalse,
          reason: '${taggedEntrant.name} skill tag must not cover any runner.',
        );
      }
    }

    final trackRect = tester.getRect(
      find.byKey(const Key('horse-race-live-track')),
    );
    var previousCenters = <String, double>{
      for (final entrant in race.entrants)
        entrant.id: tester
            .getRect(find.byKey(Key('horse-live-${entrant.id}')))
            .center
            .dx,
    };
    var elapsedMs = (raceDuration.inMilliseconds * surgeAt).round() + 18;
    while (elapsedMs < raceDuration.inMilliseconds * 0.84) {
      const frameMs = 20;
      await tester.pump(const Duration(milliseconds: frameMs));
      elapsedMs += frameMs;
      final currentCenters = <String, double>{
        for (final entrant in race.entrants)
          entrant.id: tester
              .getRect(find.byKey(Key('horse-live-${entrant.id}')))
              .center
              .dx,
      };
      for (final entrant in race.entrants) {
        expect(
          (currentCenters[entrant.id]! - previousCenters[entrant.id]!).abs(),
          lessThan(trackRect.width * 0.16),
          reason: '${entrant.name} must move continuously through a surge.',
        );
      }
      final visibleCount = currentCenters.values
          .where(
            (centerX) =>
                centerX >= trackRect.left - 60 &&
                centerX <= trackRect.right + 60,
          )
          .length;
      expect(
        visibleCount,
        greaterThanOrEqualTo(4),
        reason: 'A surge must never push the whole field off-screen.',
      );
      previousCenters = currentCenters;
    }
    expect(tester.takeException(), isNull);
  });

  test('gallop poses keep one pixel scale and one ground line', () {
    const canvasSize = Size(82, 48);
    const canonicalSourceSize = Size(384, 282);
    const poses = <Size>[
      Size(361, 282),
      Size(384, 282),
      Size(347, 281),
      Size(384, 262),
    ];

    double? stableScale;
    for (final pose in poses) {
      final destination = horseRaceStableFrameDestination(
        canvasSize: canvasSize,
        sourceSize: pose,
        canonicalSourceSize: canonicalSourceSize,
      );
      final scale = destination.width / pose.width;
      stableScale ??= scale;
      expect(scale, closeTo(stableScale, 0.000001));
      expect(destination.height / pose.height, closeTo(stableScale, 0.000001));
      expect(destination.bottom, canvasSize.height);
    }
    expect(horseRaceFrameCrossfadeProgress(2.58), closeTo(0, 0.000001));
    expect(horseRaceFrameCrossfadeProgress(2.79), closeTo(0.5, 0.000001));
    expect(horseRaceFrameCrossfadeProgress(2.999), greaterThan(0.999));
  });

  testWidgets('gate four advances on every live frame without a lane hitch', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final race = buildAfternoonHorseRace(
      simulationSeed: 'horse-widget-gate-four-continuity',
      day: 18,
    );
    final gateFour = race.entrants.singleWhere((entrant) => entrant.gate == 4);
    // Match the production broadcast duration. A 1.6-second synthetic race
    // multiplies the gait frequency by ten and measures jumps the live game
    // can never render.
    const raceDuration = Duration(seconds: 16);
    await tester.pumpWidget(
      MaterialApp(
        home: HorseRacingMiniGame(
          race: race,
          availableCash: 5000,
          previewMode: true,
          raceDuration: raceDuration,
        ),
      ),
    );
    await tester.pump();
    await openHorseRaceBettingCard(tester);
    await tester.tap(find.byKey(const Key('horse-stake-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('horse-race-start')));
    await tester.pump();
    await finishTellerTyping(tester);
    await tester.tap(find.byKey(const Key('horse-race-teller-confirm-ticket')));
    await tester.pump();
    await finishTellerTyping(tester);
    await startLiveRaceFromHandover(tester, race);
    await tester.pump(const Duration(milliseconds: 64));

    final gateFourFinder = find.byKey(Key('horse-live-${gateFour.id}'));
    var previous = tester.getRect(gateFourFinder);
    for (var frame = 0; frame < 76; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final current = tester.getRect(gateFourFinder);
      expect(
        current.center.dx,
        greaterThan(previous.center.dx + 0.01),
        reason: 'Gate four must advance on every sampled animation frame.',
      );
      expect(
        (current.center.dy - previous.center.dy).abs(),
        lessThan(4.5),
        reason: 'Gate four must not jump vertically between gait poses.',
      );
      expect(current.width, closeTo(previous.width, 0.01));
      expect(current.height, closeTo(previous.height, 0.01));
      previous = current;
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('every runner stays in its lane and exits after the finish', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    final race = buildAfternoonHorseRace(
      simulationSeed: 'horse-widget-run-out',
      day: 15,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HorseRacingMiniGame(
          race: race,
          availableCash: 5000,
          previewMode: true,
          raceDuration: const Duration(milliseconds: 1000),
        ),
      ),
    );
    await tester.pump();
    await openHorseRaceBettingCard(tester);
    await tester.tap(find.byKey(const Key('horse-stake-500')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('horse-race-start')));
    await tester.pump();
    await finishTellerTyping(tester);
    await tester.tap(find.byKey(const Key('horse-race-teller-confirm-ticket')));
    await tester.pump();
    await finishTellerTyping(tester);
    await startLiveRaceFromHandover(tester, race);
    await tester.pump(const Duration(milliseconds: 120));

    final laneCenters = <String, double>{
      for (final entrant in race.entrants)
        entrant.id: tester
            .getRect(find.byKey(Key('horse-live-${entrant.id}')))
            .center
            .dy,
    };
    final trackRect = tester.getRect(
      find.byKey(const Key('horse-race-live-track')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    var previousCenters = <String, double>{
      for (final entrant in race.entrants)
        entrant.id: tester
            .getRect(find.byKey(Key('horse-live-${entrant.id}')))
            .center
            .dx,
    };
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 25));
      final currentCenters = <String, double>{
        for (final entrant in race.entrants)
          entrant.id: tester
              .getRect(find.byKey(Key('horse-live-${entrant.id}')))
              .center
              .dx,
      };
      for (final entrant in race.entrants) {
        expect(
          currentCenters[entrant.id]!,
          greaterThan(previousCenters[entrant.id]! + 0.5),
          reason:
              '${entrant.name} must advance on every sampled finish-approach frame.',
        );
      }
      previousCenters = currentCenters;
    }
    await tester.pump(const Duration(milliseconds: 125));
    expect(find.byKey(const Key('horse-race-running-screen')), findsOneWidget);
    for (final entrant in race.entrants) {
      final runnerRect = tester.getRect(
        find.byKey(Key('horse-live-${entrant.id}')),
      );
      expect(
        runnerRect.left,
        greaterThan(trackRect.right),
        reason:
            '${entrant.name} must gallop fully off-screen after its finish.',
      );
      expect(
        runnerRect.center.dy,
        closeTo(laneCenters[entrant.id]!, 5.0),
        reason: '${entrant.name} must keep the same lane through the run-out.',
      );
    }
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.byKey(const Key('horse-race-result-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ImageGen race background and 24 gallop sheets are bundled', (
    tester,
  ) async {
    const assets = [
      horseRaceBackgroundAsset,
      horseRacePhotoFinishAsset,
      horseRaceOfficialResultBoardAsset,
      horseRaceTellerWelcomeAsset,
      horseRaceTellerGuideAsset,
      horseRaceTellerAcceptAsset,
      horseRaceTellerHandoverAsset,
      horseRaceStraightTrackAsset,
      ...horseRaceAllGallopAssets,
    ];
    for (final asset in assets) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(10000), reason: asset);
    }
  });
}
