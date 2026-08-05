import 'game_state.dart';
import 'cohort_investment_state.dart';
import 'weekly_portfolio_review.dart';

const playerProgressReviewArchiveFlag = 'playerProgressReviewArchive';
const playerProgressReviewArchiveLimit = 32;

class PlayerProgressReview {
  const PlayerProgressReview({
    required this.year,
    required this.tradingDays,
    required this.tradeDays,
    required this.cumulativeInvestmentProfit,
    required this.investmentProfitForYear,
    required this.researchCount,
    required this.relationshipMoments,
    required this.activeWeekendChoices,
    required this.netWorthAtCost,
    required this.progressionLevel,
    required this.progressionExperience,
    required this.headline,
    required this.nextFocus,
  });

  final int year;
  final int tradingDays;
  final int tradeDays;
  final int cumulativeInvestmentProfit;
  final int investmentProfitForYear;
  final int researchCount;
  final int relationshipMoments;
  final int activeWeekendChoices;
  final int netWorthAtCost;
  final int progressionLevel;
  final int progressionExperience;
  final String headline;
  final String nextFocus;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'year': year,
    'tradingDays': tradingDays,
    'tradeDays': tradeDays,
    'cumulativeInvestmentProfit': cumulativeInvestmentProfit,
    'investmentProfitForYear': investmentProfitForYear,
    'researchCount': researchCount,
    'relationshipMoments': relationshipMoments,
    'activeWeekendChoices': activeWeekendChoices,
    'netWorthAtCost': netWorthAtCost,
    'progressionLevel': progressionLevel,
    'progressionExperience': progressionExperience,
    'headline': headline,
    'nextFocus': nextFocus,
  };

  factory PlayerProgressReview.fromJson(
    Map<String, dynamic> json,
  ) => PlayerProgressReview(
    year: (json['year'] as num?)?.toInt() ?? 2000,
    tradingDays: (json['tradingDays'] as num?)?.toInt() ?? 0,
    tradeDays: (json['tradeDays'] as num?)?.toInt() ?? 0,
    cumulativeInvestmentProfit:
        (json['cumulativeInvestmentProfit'] as num?)?.toInt() ?? 0,
    investmentProfitForYear:
        (json['investmentProfitForYear'] as num?)?.toInt() ?? 0,
    researchCount: (json['researchCount'] as num?)?.toInt() ?? 0,
    relationshipMoments: (json['relationshipMoments'] as num?)?.toInt() ?? 0,
    activeWeekendChoices: (json['activeWeekendChoices'] as num?)?.toInt() ?? 0,
    netWorthAtCost: (json['netWorthAtCost'] as num?)?.toInt() ?? 0,
    progressionLevel: (json['progressionLevel'] as num?)?.toInt() ?? 1,
    progressionExperience:
        (json['progressionExperience'] as num?)?.toInt() ?? 0,
    headline: json['headline'] as String? ?? '',
    nextFocus: json['nextFocus'] as String? ?? '',
  );
}

List<PlayerProgressReview> archivedPlayerProgressReviews(GameState state) {
  final rows =
      ((state.story.storyFlags[playerProgressReviewArchiveFlag] as List?) ??
              const <dynamic>[])
          .whereType<Map>()
          .map(
            (row) => PlayerProgressReview.fromJson(row.cast<String, dynamic>()),
          )
          .where((review) => review.year >= 2000)
          .toList(growable: false)
        ..sort((left, right) => left.year.compareTo(right.year));
  return List<PlayerProgressReview>.unmodifiable(rows);
}

PlayerProgressReview? archivedPlayerProgressReviewForYear(
  GameState state,
  int year,
) {
  for (final review in archivedPlayerProgressReviews(state)) {
    if (review.year == year) return review;
  }
  return null;
}

PlayerProgressReview playerProgressReviewForYear(GameState state, int year) {
  final archived = archivedPlayerProgressReviewForYear(state, year);
  if (archived != null && year != state.currentDate.year) return archived;
  final reports =
      state.cohortInvestments.reports
          .where((report) => state.dateForDay(report.day).year == year)
          .toList(growable: false)
        ..sort((left, right) => left.day.compareTo(right.day));
  final playerRows = reports
      .map((report) => report.resultFor('player'))
      .whereType<CohortDailyInvestmentResult>()
      .toList(growable: false);
  final tradeDays = playerRows.where((row) => row.traded == true).length;
  final cumulativeProfit = playerRows.isEmpty
      ? state.cohortInvestments.playerCumulativeProfitLoss
      : playerRows.last.cumulativeProfitLoss;
  final annualProfit = playerRows.fold<int>(
    0,
    (total, row) => total + row.profitLoss,
  );
  final researchCount = weeklyPortfolioReviewArchive(state).where((entry) {
    return state.dateForDay(entry.day).year == year &&
        entry.action == WeeklyPortfolioReviewAction.research;
  }).length;
  final relationshipMoments = state.relationships.memories
      .where((memory) => state.dateForDay(memory.day).year == year)
      .length;
  final weekendLogs =
      ((state.story.storyFlags['weekendActivityLog'] as List?) ??
              const <dynamic>[])
          .whereType<Map>()
          .where((entry) {
            final day = ((entry['day'] as num?)?.toInt() ?? 0);
            return day > 0 &&
                state.dateForDay(day).year == year &&
                entry['kind'] != 'rest';
          })
          .length;
  final headline = reports.isEmpty
      ? '$year년에는 아직 확정된 투자 결과가 없습니다.'
      : tradeDays == 0
      ? '$year년 ${reports.length}거래일 동안 실제 주문이 없었습니다.'
      : '$year년 ${reports.length}거래일 중 $tradeDays일에 실제 판단을 시장에 남겼습니다.';
  final nextFocus = tradeDays == 0
      ? '다음 기간에는 작은 1주 주문이라도 이유와 철회 조건을 함께 적어 보세요.'
      : researchCount == 0
      ? '거래 횟수보다 한 회사를 다시 조사해 가설이 바뀐 이유를 남겨 보세요.'
      : '수익만 보지 말고 가장 잘 지킨 손실 한도와 가장 늦게 철회한 판단을 비교해 보세요.';
  return PlayerProgressReview(
    year: year,
    tradingDays: reports.length,
    tradeDays: tradeDays,
    cumulativeInvestmentProfit: cumulativeProfit,
    investmentProfitForYear: annualProfit,
    researchCount: researchCount,
    relationshipMoments: relationshipMoments,
    activeWeekendChoices: weekendLogs,
    netWorthAtCost: state.balanceSheetNetWorth(),
    progressionLevel: state.progression.level,
    progressionExperience: state.progression.experience,
    headline: headline,
    nextFocus: nextFocus,
  );
}

GameState archivePlayerProgressReviewForClosingYear(GameState state) {
  final year = state.currentDate.year;
  final existing = archivedPlayerProgressReviews(state);
  if (existing.any((review) => review.year == year)) return state;
  final archive = <PlayerProgressReview>[
    ...existing,
    playerProgressReviewForYear(state, year),
  ];
  final trimmed = archive.length <= playerProgressReviewArchiveLimit
      ? archive
      : archive.sublist(archive.length - playerProgressReviewArchiveLimit);
  final flags = <String, dynamic>{
    ...state.story.storyFlags,
    playerProgressReviewArchiveFlag: trimmed
        .map((review) => review.toJson())
        .toList(growable: false),
  };
  return state.copyWith(story: state.story.copyWith(storyFlags: flags));
}

class CareerProgressReview {
  const CareerProgressReview({
    required this.years,
    required this.tradeDays,
    required this.researchCount,
    required this.relationshipMoments,
    required this.activeWeekendChoices,
    required this.yearsWithoutTrades,
    required this.latestCumulativeInvestmentProfit,
    required this.netWorthAtCost,
    required this.progressionLevel,
  });

  final int years;
  final int tradeDays;
  final int researchCount;
  final int relationshipMoments;
  final int activeWeekendChoices;
  final int yearsWithoutTrades;
  final int latestCumulativeInvestmentProfit;
  final int netWorthAtCost;
  final int progressionLevel;
}

CareerProgressReview careerProgressReview(GameState state) {
  final reviews = <PlayerProgressReview>[
    ...archivedPlayerProgressReviews(state),
  ];
  if (!reviews.any((review) => review.year == state.currentDate.year)) {
    final current = playerProgressReviewForYear(state, state.currentDate.year);
    final hasCurrentYearProgress =
        current.tradingDays > 0 ||
        current.researchCount > 0 ||
        current.relationshipMoments > 0 ||
        current.activeWeekendChoices > 0;
    if (reviews.isEmpty || hasCurrentYearProgress) reviews.add(current);
  }
  reviews.sort((left, right) => left.year.compareTo(right.year));
  final latest = reviews.isEmpty ? null : reviews.last;
  return CareerProgressReview(
    years: reviews.length,
    tradeDays: reviews.fold(0, (total, review) => total + review.tradeDays),
    researchCount: reviews.fold(
      0,
      (total, review) => total + review.researchCount,
    ),
    relationshipMoments: reviews.fold(
      0,
      (total, review) => total + review.relationshipMoments,
    ),
    activeWeekendChoices: reviews.fold(
      0,
      (total, review) => total + review.activeWeekendChoices,
    ),
    yearsWithoutTrades: reviews.where((review) => review.tradeDays == 0).length,
    latestCumulativeInvestmentProfit:
        latest?.cumulativeInvestmentProfit ??
        state.cohortInvestments.playerCumulativeProfitLoss,
    netWorthAtCost: state.balanceSheetNetWorth(),
    progressionLevel: state.progression.level,
  );
}
