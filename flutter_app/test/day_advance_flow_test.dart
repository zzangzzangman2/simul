import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_news.dart';
import 'package:millennium_capital/main.dart';

void main() {
  for (final closeMethod in ['신문 X', '상단 뒤로가기', '시스템 뒤로가기']) {
    testWidgets(
      'closing daily newspaper starts next day at 08:00: $closeMethod',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const engine = GameEngine();
        var currentState = engine
            .createNewGame('다음 날 시각 테스트', initialCash: 0)
            .copyWith(decisions: const [], marketMinute: marketDayStartMinute);
        final initialDay = currentState.day;
        late StateSetter updateHarness;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              updateHarness = setState;
              return MaterialApp(
                home: OfficeScreen(
                  state: currentState,
                  engine: engine,
                  activeSaveSlot: 1,
                  lastSavedAt: null,
                  onManualSave: () async {},
                  onReturnToTitle: () {},
                  onAdvanceDay: () async {
                    currentState = engine.advanceOneDay(currentState);
                    updateHarness(() {});
                    return currentState;
                  },
                  onSetMarketMinute: (minute) async {
                    currentState = currentState.copyWith(marketMinute: minute);
                    updateHarness(() {});
                    return currentState;
                  },
                  onSaveMarketNotebook: (_, _) async => currentState,
                  onBuildDailyNewspaper: (closingState) async =>
                      DailyMarketNewspaper(
                        date: closingState.currentDate,
                        brief: buildDailyBrief(closingState),
                        total: 0,
                        advancers: 0,
                        decliners: 0,
                        unchanged: 0,
                        topGainers: const [],
                        topLosers: const [],
                        headline: '하루 결산 테스트',
                        summary: '테스트 신문',
                      ),
                  onResolveDecision: (_, _) async {},
                  onRequestFamilyHelp: (_) async => currentState,
                  onCompleteWork: (_) async => currentState,
                  onExecuteTrade: (_) async => TradeExecutionResult(
                    state: currentState,
                    success: false,
                    message: 'test',
                  ),
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('advance-day-button')));
        for (
          var attempt = 0;
          attempt < 30 &&
              find.byType(KoreaEconomicNewspaperSheet).evaluate().isEmpty;
          attempt++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pump();

        expect(currentState.day, initialDay);
        expect(currentState.marketMinute, marketDayEndMinute);
        expect(find.byType(KoreaEconomicNewspaperSheet), findsOneWidget);

        if (closeMethod == '신문 X') {
          await tester.tap(find.byIcon(Icons.close_rounded).first);
        } else if (closeMethod == '상단 뒤로가기') {
          await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
        } else {
          await tester.binding.handlePopRoute();
        }
        for (
          var attempt = 0;
          attempt < 10 && currentState.day == initialDay;
          attempt++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        expect(currentState.day, initialDay + 1);
        expect(currentState.marketMinute, marketDayStartMinute);
        expect(find.textContaining('08:00'), findsOneWidget);
        expect(find.byType(KoreaEconomicNewspaperSheet), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
