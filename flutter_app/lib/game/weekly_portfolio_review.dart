import 'game_state.dart';
import 'market_clock.dart';
import 'market_data.dart';
import 'stable_hash.dart';

const weeklyPortfolioReviewCompletedKeyFlag =
    'weeklyPortfolioReviewCompletedKey';
const weeklyPortfolioReviewArchiveFlag = 'weeklyPortfolioReviewArchive';
const weeklyPortfolioReviewArchiveLimit = 260;

enum WeeklyPortfolioReviewAction { research, riskRule, trade }

String weeklyPortfolioReviewKey(DateTime date) {
  final monday = DateTime(
    date.year,
    date.month,
    date.day,
  ).subtract(Duration(days: date.weekday - DateTime.monday));
  return marketDateKey(monday);
}

bool weeklyPortfolioReviewCompleted(GameState state) {
  final key = weeklyPortfolioReviewKey(state.currentDate);
  if (state.story.storyFlags[weeklyPortfolioReviewCompletedKeyFlag] == key) {
    return true;
  }
  final monday = DateTime.parse(key);
  final mondayDay =
      state.day -
      state.currentDate.difference(monday).inDays.clamp(0, 6).toInt();
  return state.ledger.any(
    (entry) =>
        entry.day >= mondayDay &&
        entry.day <= state.day &&
        (entry.tradeSide == 'buy' || entry.tradeSide == 'sell'),
  );
}

bool weeklyPortfolioReviewDue(GameState state) =>
    isMarketTradingDay(state.currentDate) &&
    !weeklyPortfolioReviewCompleted(state);

class WeeklyPortfolioReviewEntry {
  const WeeklyPortfolioReviewEntry({
    required this.weekKey,
    required this.day,
    required this.action,
    required this.summary,
    this.assetId = '',
    this.assetName = '',
  });

  final String weekKey;
  final int day;
  final WeeklyPortfolioReviewAction action;
  final String summary;
  final String assetId;
  final String assetName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'weekKey': weekKey,
    'day': day,
    'action': action.name,
    'summary': summary,
    if (assetId.isNotEmpty) 'assetId': assetId,
    if (assetName.isNotEmpty) 'assetName': assetName,
  };

  factory WeeklyPortfolioReviewEntry.fromJson(Map<String, dynamic> json) =>
      WeeklyPortfolioReviewEntry(
        weekKey: json['weekKey'] as String? ?? '',
        day: ((json['day'] as num?)?.toInt() ?? 0).clamp(0, 0x7fffffff),
        action: WeeklyPortfolioReviewAction.values.firstWhere(
          (value) => value.name == json['action'],
          orElse: () => WeeklyPortfolioReviewAction.research,
        ),
        summary: json['summary'] as String? ?? '',
        assetId: json['assetId'] as String? ?? '',
        assetName: json['assetName'] as String? ?? '',
      );
}

List<WeeklyPortfolioReviewEntry> weeklyPortfolioReviewArchive(
  GameState state,
) =>
    ((state.story.storyFlags[weeklyPortfolioReviewArchiveFlag] as List?) ??
            const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) =>
              WeeklyPortfolioReviewEntry.fromJson(item.cast<String, dynamic>()),
        )
        .where((entry) => entry.weekKey.isNotEmpty && entry.day > 0)
        .toList(growable: false);

List<FictionalMarketAsset> weeklyPortfolioReviewCandidates(
  GameState state,
  FictionalMarketUniverse universe, {
  int maximum = 12,
}) {
  final limit = maximum.clamp(1, 24);
  final byId = <String, FictionalMarketAsset>{
    for (final asset in universe.assets.where((asset) => asset.isDomestic))
      asset.id: asset,
  };
  final pinnedIds = <String>[
    ...state.positions.map((position) => position.assetId),
    ...((state.story.storyFlags['marketFavoriteAssetIds'] as List?) ??
            const <dynamic>[])
        .whereType<String>(),
  ];
  final result = <FictionalMarketAsset>[];
  final seen = <String>{};
  for (final id in pinnedIds) {
    final asset = byId[id];
    if (asset != null && seen.add(id)) result.add(asset);
  }

  final rotating =
      byId.values
          .where((asset) => !seen.contains(asset.id))
          .toList(growable: false)
        ..sort((left, right) => left.id.compareTo(right.id));
  if (rotating.isNotEmpty) {
    final start =
        stableHash31(
          '${state.simulationSeed}:${weeklyPortfolioReviewKey(state.currentDate)}',
        ) %
        rotating.length;
    for (var offset = 0; offset < rotating.length; offset += 1) {
      if (result.length >= limit) break;
      final asset = rotating[(start + offset) % rotating.length];
      if (seen.add(asset.id)) result.add(asset);
    }
  }
  return List<FictionalMarketAsset>.unmodifiable(result.take(limit));
}

GameState completeWeeklyPortfolioReview(
  GameState state, {
  required WeeklyPortfolioReviewAction action,
  String assetId = '',
  String assetName = '',
  int riskLimitBps = 500,
  bool automatic = false,
}) {
  if (weeklyPortfolioReviewCompleted(state)) return state;
  final key = weeklyPortfolioReviewKey(state.currentDate);
  final normalizedRisk = riskLimitBps.clamp(100, 2000);
  final summary = switch (action) {
    WeeklyPortfolioReviewAction.research =>
      assetName.isEmpty
          ? '이번 주 공개 정보와 보유 종목 변화를 다시 확인했다.'
          : '$assetName의 가격·거래량·공시를 이번 주 관찰 대상으로 정했다.',
    WeeklyPortfolioReviewAction.riskRule =>
      '한 종목 손실이 -${(normalizedRisk / 100).toStringAsFixed(normalizedRisk % 100 == 0 ? 0 : 1)}%에 닿으면 이유부터 다시 확인한다.',
    WeeklyPortfolioReviewAction.trade =>
      automatic
          ? '실제 주문을 체결해 이번 주 판단을 장부에 남겼다.'
          : '실제 주문과 체결 결과를 이번 주 핵심 기록으로 남겼다.',
  };
  final archive = <WeeklyPortfolioReviewEntry>[
    ...weeklyPortfolioReviewArchive(state),
    WeeklyPortfolioReviewEntry(
      weekKey: key,
      day: state.day,
      action: action,
      summary: summary,
      assetId: assetId,
      assetName: assetName,
    ),
  ];
  final trimmed = archive.length <= weeklyPortfolioReviewArchiveLimit
      ? archive
      : archive.sublist(archive.length - weeklyPortfolioReviewArchiveLimit);
  final flags = <String, dynamic>{
    ...state.story.storyFlags,
    weeklyPortfolioReviewCompletedKeyFlag: key,
    weeklyPortfolioReviewArchiveFlag: trimmed
        .map((entry) => entry.toJson())
        .toList(growable: false),
    if (action == WeeklyPortfolioReviewAction.riskRule)
      'weeklyPortfolioRiskLimitBps': normalizedRisk,
  };
  if (action == WeeklyPortfolioReviewAction.research && assetId.isNotEmpty) {
    final notes = Map<String, String>.from(
      ((flags['marketResearchNotes'] as Map?) ?? const <dynamic, dynamic>{})
          .map((key, value) => MapEntry(key.toString(), value.toString())),
    );
    notes[assetId] = '${marketDateKey(state.currentDate)} · $summary';
    flags['marketResearchNotes'] = notes;
  }
  final experience = switch (action) {
    WeeklyPortfolioReviewAction.research => 3,
    WeeklyPortfolioReviewAction.riskRule => 3,
    WeeklyPortfolioReviewAction.trade => 2,
  };
  return state.copyWith(
    story: state.story.copyWith(storyFlags: flags),
    progression: state.progression.gainExperience(experience),
  );
}
