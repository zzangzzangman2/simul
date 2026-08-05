import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/weekly_portfolio_review.dart';

void main() {
  const engine = GameEngine();

  test('one meaningful review completes a week and updates research notes', () {
    var state = engine.createNewGame('주간 복기', worldSeed: 'weekly-review-state');
    while (!isMarketTradingDay(state.currentDate)) {
      state = state.copyWith(day: state.day + 1);
    }
    expect(weeklyPortfolioReviewDue(state), isTrue);

    final completed = completeWeeklyPortfolioReview(
      state,
      action: WeeklyPortfolioReviewAction.research,
      assetId: 'hanbit-telecom',
      assetName: '한빛통신',
    );

    expect(weeklyPortfolioReviewCompleted(completed), isTrue);
    expect(weeklyPortfolioReviewArchive(completed), hasLength(1));
    expect(completed.progression.experience, state.progression.experience + 3);
    expect(
      (completed.story.storyFlags['marketResearchNotes'] as Map).containsKey(
        'hanbit-telecom',
      ),
      isTrue,
    );
    expect(
      completeWeeklyPortfolioReview(
        completed,
        action: WeeklyPortfolioReviewAction.riskRule,
      ).toJson(),
      completed.toJson(),
    );
  });

  test('candidate roster rotates by week while keeping pins first', () async {
    final state = engine.createNewGame(
      '주간 후보',
      worldSeed: 'weekly-review-candidates',
    );
    final universe = await FictionalMarketUniverse.load(
      seed: state.simulationSeed,
      throughDate: state.currentDate.add(const Duration(days: 14)),
    );
    final first = weeklyPortfolioReviewCandidates(
      state,
      universe.asOf(state.currentDate),
    );
    final nextWeek = state.copyWith(day: state.day + 7);
    final second = weeklyPortfolioReviewCandidates(
      nextWeek,
      universe.asOf(nextWeek.currentDate),
    );

    expect(first, hasLength(12));
    expect(second, hasLength(12));
    expect(first.map((asset) => asset.id).toSet(), hasLength(12));
    expect(
      first.map((asset) => asset.id).toList(),
      isNot(second.map((asset) => asset.id).toList()),
    );
  });
}
