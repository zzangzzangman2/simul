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
          onBorrow: (lenderId, amount) async {
            final result = engine.borrowFromCohortInvestor(
              state,
              lenderId: lenderId,
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
          onBorrow: (lenderId, amount) async {
            final result = engine.borrowFromCohortInvestor(
              state,
              lenderId: lenderId,
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

  testWidgets('bankrupt player can borrow from a peer at the displayed rate', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    var state = engine
        .createNewGame(
          '제6기 긴급 차입 UI',
          worldSeed: 'cohort-ui-borrow',
          initialCash: 5000,
        )
        .copyWith(day: 2, marketMinute: krxCloseMinute);
    state = state.copyWith(
      story: state.story.copyWith(
        storyFlags: {
          ...state.story.storyFlags,
          'marketTutorialSeen': true,
          'liveTradingStarted': true,
        },
      ),
    );
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
          onLend: (borrowerId, amount) async => engine.lendToCohortInvestor(
            state,
            borrowerId: borrowerId,
            amount: amount,
          ),
          onBorrow: (lenderId, amount) async {
            final result = engine.borrowFromCohortInvestor(
              state,
              lenderId: lenderId,
              amount: amount,
            );
            state = result.state;
            return result;
          },
          onAcknowledge: () async =>
              engine.acknowledgeCohortInvestmentReport(state),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final lenderButton = find.byKey(
      const Key('cohort-borrow-lender-kim_hakjun'),
    );
    await tester.scrollUntilVisible(
      lenderButton,
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
    await tester.ensureVisible(lenderButton);
    await tester.pumpAndSettle();
    await tester.tap(lenderButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('단리 12%'), findsWidgets);
    await tester.tap(find.byKey(const Key('cohort-borrow-amount-5000')));
    await tester.pumpAndSettle();

    expect(
      state.cohortInvestments.loans.single.direction,
      CohortLoanDirection.playerBorrows,
    );
    expect(state.cohortInvestments.loans.single.totalDue, 5600);
    expect(find.textContaining('만기 상환액'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ranking table publishes the return rate of all ten', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    var state = engine
        .createNewGame(
          '수익률 순위 UI',
          worldSeed: 'cohort-ui-rate',
          initialCash: 50000,
        )
        // 2000-01-04 화요일이라야 열 명이 실제로 거래한다.
        .copyWith(day: 4, marketMinute: krxCloseMinute);
    state = engine
        .settleCohortInvestmentDay(
          state,
          universe: testMarketUniverse(
            tradingDate: state.currentDate,
            closeOverride: 6600,
          ),
        )
        .state;
    final report = state.cohortInvestments.reportForDay(state.day)!;

    await tester.pumpWidget(
      MaterialApp(
        home: CohortDailyResultScreen(
          state: state,
          onLend: (borrowerId, amount) async => engine.lendToCohortInvestor(
            state,
            borrowerId: borrowerId,
            amount: amount,
          ),
          onBorrow: (lenderId, amount) async => engine.borrowFromCohortInvestor(
            state,
            lenderId: lenderId,
            amount: amount,
          ),
          onAcknowledge: () async =>
              engine.acknowledgeCohortInvestmentReport(state),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('총 수익률'), findsOneWidget);
    expect(find.text('수익률 1등'), findsOneWidget);
    for (final row in report.rows) {
      expect(
        find.byKey(Key('cohort-result-rate-${row.investorId}')),
        findsOneWidget,
        reason: '${row.name} 수익률 칸이 없습니다',
      );
    }

    // 화면에 그려진 순서가 수익률 내림차순이어야 한다.
    final rendered = tester
        .widgetList<Text>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                widget.key is ValueKey<String> &&
                (widget.key as ValueKey<String>).value.startsWith(
                  'cohort-result-rate-',
                ),
          ),
        )
        .map((text) => text.data!)
        .toList(growable: false);
    expect(rendered, hasLength(10));
    final values = rendered
        .map((label) => double.parse(label.replaceAll(RegExp(r'[+%]'), '')))
        .toList(growable: false);
    expect(
      values,
      orderedEquals(<double>[...values]..sort((a, b) => b.compareTo(a))),
    );
    expect(tester.takeException(), isNull);
  });
}
