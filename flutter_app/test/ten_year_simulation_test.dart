import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/cohort_standing_events.dart';
import 'package:millennium_capital/game/cohort_withdrawal_crisis.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/life_calendar.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_news.dart';
import 'package:millennium_capital/game/progress_review.dart';
import 'package:millennium_capital/game/relationship_state.dart';
import 'package:millennium_capital/game/weekend_activity.dart';
import 'package:millennium_capital/game/weekly_portfolio_review.dart';

import 'support/market_fixture.dart';

void main() {
  const engine = GameEngine();

  test(
    'ten active years remain playable, varied, reviewable, and saveable',
    () {
      var state = engine.createNewGame(
        '10년 진행 검증',
        worldSeed: 'ten-year-audit',
        initialCash: 50000,
      );
      var tradingDayCount = 0;
      var executedTradeCount = 0;
      var activeWeekendCount = 0;
      var relationshipCount = 0;
      final relationshipSceneIds = <String>{};

      for (var elapsed = 0; elapsed < 3653; elapsed += 1) {
        var decisionGuard = 0;
        while (state.pendingDecisions.isNotEmpty) {
          final decision = state.pendingDecisions.first;
          final affordable = decision.options.where(
            (option) => option.cashCost <= state.bankCash,
          );
          expect(
            affordable,
            isNotEmpty,
            reason: '${state.currentDate} ${decision.id}에 진행 가능한 선택지가 없습니다.',
          );
          state = engine.resolveDecision(
            state,
            decision.id,
            affordable.first.id,
          );
          decisionGuard += 1;
          expect(decisionGuard, lessThan(100), reason: '결정 처리 루프가 끝나지 않습니다.');
        }

        final events = marketNewsEventsForState(state);
        final brief = buildDailyBrief(state);
        state = engine.archiveNews(
          state,
          headline: brief.title,
          eventIds: events.map((event) => event.id).toList(growable: false),
        );

        final isTradingDay = isMarketTradingDay(state.currentDate);
        if (isTradingDay) {
          tradingDayCount += 1;
          if (tradingDayCount % 20 == 0) {
            final holding = state.positions.any(
              (position) =>
                  position.assetId == 'hanbit_telecom' && position.units >= 1,
            );
            final result = engine.executeTrade(
              state.copyWith(marketMinute: krxOpenMinute),
              TradeOrder(
                side: holding ? TradeSide.sell : TradeSide.buy,
                assetId: 'hanbit_telecom',
                symbol: '1001',
                name: '한빛통신',
                market: fictionalMainMarket,
                currency: 'KRW',
                quantity: 1,
                unitPrice: 6110,
                quoteDate: marketDateKey(state.currentDate),
                marketMinute: krxOpenMinute,
                isTradingDay: true,
                previousClose: 6040,
              ),
            );
            expect(
              result.success,
              isTrue,
              reason: '${state.currentDate} 장기 매매 실패: ${result.message}',
            );
            state = result.state;
            executedTradeCount += 1;
          }

          state = state.copyWith(marketMinute: krxCloseMinute);
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
          final week = state.day ~/ 7;
          state = completeWeeklyPortfolioReview(
            state,
            action: week.isEven
                ? WeeklyPortfolioReviewAction.research
                : WeeklyPortfolioReviewAction.riskRule,
            assetId: week.isEven ? 'hanbit_telecom' : '',
            assetName: week.isEven ? '한빛통신' : '',
            riskLimitBps: 500,
          );
        }

        if (isWeekendOutingDay(state.currentDate)) {
          while (!weekendScheduleCompleteForState(state)) {
            final activityId = weekendActivityPointsRemaining(state) == 2
                ? 'market_study'
                : 'restaurant_dishes';
            final result = engine.completeWeekendActivity(
              state,
              WeekendActivityRequest(activityId: activityId),
            );
            expect(
              result.success,
              isTrue,
              reason: '${state.currentDate} 주말 활동 실패: ${result.message}',
            );
            state = result.state;
            activeWeekendCount += 1;
          }
        }

        if (state.currentDate.weekday == DateTime.wednesday &&
            !state.relationships.completedEveningForDay(state.day)) {
          final profile =
              cohortGirlProfiles[(state.day ~/ 7) % cohortGirlProfiles.length];
          final progress = state.relationships.progressFor(profile.id);
          final scene = relationshipSceneFor(
            profile: profile,
            activity: RelationshipActivity.conversation,
            day: state.day,
            interactionCount: progress.conversationCount,
            affection: progress.affection,
          );
          expect(
            relationshipSceneIds.add(scene.id),
            isTrue,
            reason: '${profile.name}의 장면 ${scene.id}가 10년 안에 반복됐습니다.',
          );
          final choice = scene.choices.reduce(
            (best, candidate) => candidate.affectionDelta > best.affectionDelta
                ? candidate
                : best,
          );
          final result = engine.completeRelationshipEvening(
            state,
            girlId: profile.id,
            activity: RelationshipActivity.conversation,
            choiceId: choice.id,
          );
          expect(result.success, isTrue);
          state = result.state;
          relationshipCount += 1;
        } else if (!state.relationships.completedEveningForDay(state.day)) {
          final rested = engine.restDuringRelationshipEvening(state);
          expect(rested.success, isTrue);
          state = rested.state;
        }

        final previousDay = state.day;
        final next = engine.advanceOneDay(state);
        expect(
          next.day,
          previousDay + 1,
          reason: '${state.currentDate}에서 다음 날로 진행하지 못했습니다.',
        );
        state = next.copyWith(marketMinute: marketDayStartMinute);
      }

      expect(state.currentDate, DateTime(2010, 1, 1));
      expect(executedTradeCount, greaterThan(120));
      expect(activeWeekendCount, greaterThan(2000));
      expect(relationshipCount, greaterThan(500));
      expect(relationshipSceneIds, hasLength(relationshipCount));

      final years = archivedPlayerProgressReviews(state);
      expect(years.map((review) => review.year), [
        2000,
        2001,
        2002,
        2003,
        2004,
        2005,
        2006,
        2007,
        2008,
        2009,
      ]);
      for (final review in years) {
        expect(review.tradingDays, inInclusiveRange(240, 270));
        expect(review.tradeDays, greaterThan(10));
        expect(review.researchCount, greaterThan(20));
        expect(review.relationshipMoments, greaterThan(45));
        expect(review.activeWeekendChoices, greaterThan(180));
      }

      final career = careerProgressReview(state);
      expect(career.years, 10);
      expect(career.yearsWithoutTrades, 0);
      expect(career.progressionLevel, greaterThanOrEqualTo(8));
      expect(career.tradeDays, executedTradeCount);
      expect(
        career.relationshipMoments,
        greaterThanOrEqualTo(relationshipCount),
      );
      expect(career.activeWeekendChoices, activeWeekendCount);

      expect(weeklyPortfolioReviewArchive(state), hasLength(260));
      expect(weekendActivityLogsForState(state), hasLength(730));
      expect(state.relationships.memories, hasLength(400));
      expect((state.story.storyFlags['newsArchive'] as List).length, 370);

      final restored = GameState.fromJson(state.toJson());
      expect(restored.currentDate, state.currentDate);
      expect(archivedPlayerProgressReviews(restored), hasLength(10));
      expect(careerProgressReview(restored).tradeDays, career.tradeDays);
      expect(restored.balanceSheetNetWorth(), state.balanceSheetNetWorth());
    },
  );
}
