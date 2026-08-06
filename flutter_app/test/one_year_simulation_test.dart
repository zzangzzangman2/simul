import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/cohort_investment_state.dart';
import 'package:millennium_capital/game/cohort_standing_events.dart';
import 'package:millennium_capital/game/cohort_withdrawal_crisis.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/life_calendar.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_news.dart';
import 'package:millennium_capital/game/progress_review.dart';
import 'package:millennium_capital/game/weekend_activity.dart';
import 'package:millennium_capital/game/weekly_portfolio_review.dart';

import 'support/market_fixture.dart';

void main() {
  const engine = GameEngine();

  test('one low-intervention year advances without filler-screen blockers', () {
    var state = engine.createNewGame(
      '1년 진행 검증',
      worldSeed: 'one-year-audit',
      initialCash: 50000,
    );
    final startingDay = state.day;

    for (var elapsed = 0; elapsed < 365; elapsed += 1) {
      var decisionGuard = 0;
      while (state.pendingDecisions.isNotEmpty) {
        final decision = state.pendingDecisions.first;
        final affordable = decision.options.where(
          (option) => option.cashCost <= state.bankCash,
        );
        expect(
          affordable,
          isNotEmpty,
          reason: '${decision.id}에 감당 가능한 선택지가 없다',
        );
        state = engine.resolveDecision(state, decision.id, affordable.first.id);
        decisionGuard += 1;
        expect(decisionGuard, lessThan(100), reason: '결정 처리 루프가 끝나지 않는다');
      }

      final events = marketNewsEventsForState(state);
      final brief = buildDailyBrief(state);
      state = engine.archiveNews(
        state,
        headline: brief.title,
        eventIds: events.map((event) => event.id).toList(growable: false),
      );

      state = state.copyWith(marketMinute: krxCloseMinute);
      if (isMarketTradingDay(state.currentDate)) {
        final settlement = engine.settleCohortInvestmentDay(
          state,
          universe: testMarketUniverse(tradingDate: state.currentDate),
        );
        expect(settlement.success, isTrue);
        state = settlement.state;
        final acknowledged = engine.acknowledgeCohortInvestmentReport(state);
        expect(acknowledged.success, isTrue);
        state = acknowledged.state;
      }

      state = openCohortWithdrawalCrisis(state);
      final crisis = activeCohortWithdrawalCrisis(state);
      if (crisis != null && state.day >= crisis.deadlineDay) {
        final outcome = respondToCohortWithdrawal(
          state,
          CohortWithdrawalResponse.respectRight,
        );
        expect(outcome.success, isTrue);
        state = outcome.state;
      }
      final standing = pendingCohortStandingEvent(state);
      if (standing != null) {
        state = acknowledgeCohortStandingEvent(state, standing);
      }
      if (weeklyPortfolioReviewDue(state)) {
        state = completeWeeklyPortfolioReview(
          state,
          action: WeeklyPortfolioReviewAction.riskRule,
          riskLimitBps: 500,
          automatic: true,
        );
      }
      if (isWeekendOutingDay(state.currentDate) &&
          !weekendScheduleCompleteForState(state)) {
        final rested = engine.completeWeekendActivity(
          state,
          const WeekendActivityRequest(activityId: 'rest'),
        );
        expect(rested.success, isTrue);
        state = rested.state;
      }
      if (!state.relationships.completedEveningForDay(state.day)) {
        final rested = engine.restDuringRelationshipEvening(state);
        expect(rested.success, isTrue);
        state = rested.state;
      }

      final next = engine.advanceOneDay(state);
      expect(next.day, state.day + 1, reason: '${state.currentDate}에서 진행이 막혔다');
      state = next.copyWith(marketMinute: marketDayStartMinute);
    }

    expect(state.day, startingDay + 365);
    expect(state.currentDate, DateTime(2000, 12, 31));
    expect(
      state.cohortInvestments.reports.length,
      lessThanOrEqualTo(cohortInvestmentHistoryLimit),
    );
    expect(state.cohortInvestments.rollCallReports, hasLength(365));
    expect(
      state.cohortInvestments.rollCallReports.every(
        (report) => report.rows.length == 10,
      ),
      isTrue,
    );
    expect(
      weeklyPortfolioReviewArchive(state).length,
      inInclusiveRange(52, 53),
    );
    expect(
      weekendActivityLogsForState(state).length,
      greaterThanOrEqualTo(100),
    );
    expect((state.story.storyFlags['newsArchive'] as List).length, 365);

    final review = playerProgressReviewForYear(state, 2000);
    expect(review.tradeDays, 0);
    expect(review.headline, contains('실제 주문이 없었습니다'));
    expect(review.nextFocus, contains('작은 1주 주문'));

    final restored = GameState.fromJson(state.toJson());
    expect(restored.day, state.day);
    expect(
      restored.cohortInvestments.reports.length,
      state.cohortInvestments.reports.length,
    );
    expect(
      restored.cohortInvestments.rollCallReports.length,
      state.cohortInvestments.rollCallReports.length,
    );
    expect(
      weeklyPortfolioReviewArchive(restored).length,
      weeklyPortfolioReviewArchive(state).length,
    );
  });
}
