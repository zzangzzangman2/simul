import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/cohort_investment_state.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/main.dart';

import 'support/market_fixture.dart';

void main() {
  const engine = GameEngine();

  Future<void> setPhoneSurface(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
  }

  testWidgets('daily result screen shows all ten ranked rows', (tester) async {
    await setPhoneSurface(tester);
    var state = engine
        .createNewGame(
          '제6기 결과 UI',
          worldSeed: 'cohort-ui-1',
          initialCash: 50000,
        )
        .copyWith(day: 2, marketMinute: krxCloseMinute);
    state = engine
        .settleCohortInvestmentDay(
          state,
          universe: testMarketUniverse(tradingDate: state.currentDate),
        )
        .state;

    await tester.pumpWidget(
      MaterialApp(
        home: CohortDailyResultScreen(
          state: state,
          onLend: (borrowerId, amount) async {
            final result = engine.lendToCohortInvestor(
              state,
              borrowerId: borrowerId,
              amount: amount,
            );
            state = result.state;
            return result;
          },
          onAcknowledge: () async {
            final result = engine.acknowledgeCohortInvestmentReport(state);
            state = result.state;
            return result;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('뚜둥!'), findsOneWidget);
    expect(find.text('오늘의 투자 결과'), findsOneWidget);
    expect(find.byKey(const Key('cohort-daily-result-list')), findsOneWidget);
    expect(find.byKey(const Key('cohort-result-row-player')), findsOneWidget);
    for (final profile in cohortNpcInvestorProfiles) {
      expect(
        find.byKey(Key('cohort-result-row-${profile.id}')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('eligible student can receive one preset loan before continue', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    var state = engine
        .createNewGame(
          '제6기 대여 UI',
          worldSeed: 'cohort-ui-2',
          initialCash: 50000,
        )
        .copyWith(day: 2, marketMinute: krxCloseMinute);
    state = engine
        .settleCohortInvestmentDay(
          state,
          universe: testMarketUniverse(tradingDate: state.currentDate),
        )
        .state;

    await tester.pumpWidget(
      MaterialApp(
        home: CohortDailyResultScreen(
          state: state,
          onLend: (borrowerId, amount) async {
            final result = engine.lendToCohortInvestor(
              state,
              borrowerId: borrowerId,
              amount: amount,
            );
            state = result.state;
            return result;
          },
          onAcknowledge: () async {
            final result = engine.acknowledgeCohortInvestmentReport(state);
            state = result.state;
            return result;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final borrowerButton = find.byKey(
      const Key('cohort-loan-borrower-kim_hakjun'),
    );
    await tester.scrollUntilVisible(
      borrowerButton,
      250,
      scrollable: find.descendant(
        of: find.byKey(const Key('cohort-daily-result-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.drag(
      find.byKey(const Key('cohort-daily-result-list')),
      const Offset(0, -140),
    );
    await tester.pumpAndSettle();
    await tester.tap(borrowerButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cohort-loan-amount-500')));
    await tester.pumpAndSettle();

    expect(state.cohortInvestments.loanedForDay(state.day), isTrue);
    expect(state.cohortInvestments.loans.single.principal, 500);
    expect(find.textContaining('대여 완료'), findsOneWidget);

    ScaffoldMessenger.of(
      tester.element(find.byKey(const Key('cohort-daily-result-screen'))),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    final finish = find.byKey(const Key('cohort-result-finish-button'));
    await tester.ensureVisible(finish);
    await tester.tap(finish);
    await tester.pumpAndSettle();
    expect(state.cohortInvestments.acknowledgedForDay(state.day), isTrue);
  });
}
