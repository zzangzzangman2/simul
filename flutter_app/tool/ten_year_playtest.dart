// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:math' as math;

import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_news.dart';
import 'package:millennium_capital/game/seed_money_content.dart';
import 'package:millennium_capital/game/story_state.dart';

const _engine = GameEngine();
const _seed = 'codex-full-campaign-fair-play-v3';

GameState _checkedTransition(GameState before, GameState after, String action) {
  final ledgerDelta = after.ledger
      .skip(before.ledger.length)
      .fold<int>(0, (sum, entry) => sum + entry.amount);
  final cashDelta = after.cash - before.cash;
  if (cashDelta != ledgerDelta) {
    throw StateError(
      '$action cash/ledger mismatch: cash $cashDelta, ledger $ledgerDelta',
    );
  }
  if (after.cash < 0 ||
      after.brokerageCash < 0 ||
      after.brokerageCash > after.cash) {
    throw StateError(
      '$action invalid accounts: cash ${after.cash}, '
      'brokerage ${after.brokerageCash}',
    );
  }
  return after;
}

GameState _resolvePending(GameState state) {
  var next = state;
  while (next.pendingDecisions.isNotEmpty) {
    final decision = next.pendingDecisions.first;
    DecisionOptionData? selected;
    if (decision.category == '시대 기술 검토') {
      selected = decision.options.firstWhere(
        (option) =>
            option.id == 'era_prototype' &&
            option.cashCost + 100000 <= next.bankCash,
        orElse: () =>
            decision.options.firstWhere((option) => option.id == 'era_observe'),
      );
    } else if (decision.id.startsWith('milestone-')) {
      selected = decision.options.firstWhere(
        (option) => option.id == 'milestone_prudent',
      );
    } else if (decision.id.startsWith('control-offer-followup-')) {
      selected = decision.options.firstWhere(
        (option) =>
            option.id == 'acquire_control_followup' &&
            option.cashCost + 100000 <= next.bankCash,
        orElse: () => decision.options.firstWhere(
          (option) => option.id == 'pass_control',
        ),
      );
    } else if (decision.id.startsWith('control-offer-')) {
      selected = decision.options.firstWhere(
        (option) =>
            option.id == 'acquire_control' &&
            option.cashCost + 100000 <= next.bankCash,
        orElse: () => decision.options.firstWhere(
          (option) => option.id == 'review_control',
        ),
      );
    } else {
      final affordable = decision.options.where(
        (option) => option.cashCost <= next.bankCash,
      );
      selected = affordable.firstWhere(
        (option) => option.cashCost == 0,
        orElse: () =>
            affordable.isEmpty ? decision.options.last : affordable.first,
      );
    }
    final resolved = _engine.resolveDecision(next, decision.id, selected.id);
    if (resolved.toJson().toString() == next.toJson().toString()) {
      throw StateError(
        'Could not resolve ${decision.id} with ${selected.id} '
        '(bank ${next.bankCash})',
      );
    }
    next = _checkedTransition(next, resolved, 'decision ${decision.id}');
  }
  return next;
}

FictionalMarketAsset? _momentumLeader(
  FictionalMarketUniverse universe,
  DateTime date,
) {
  final yesterday = date.subtract(const Duration(days: 1));
  final lookback = date.subtract(const Duration(days: 31));
  FictionalMarketAsset? leader;
  var bestReturn = -double.infinity;
  for (final asset in universe.assets.where(
    (asset) => asset.isDomestic && asset.currency == 'KRW',
  )) {
    final recent = asset.quoteAtOrBefore(yesterday);
    final old = asset.quoteAtOrBefore(lookback);
    if (recent == null || old == null || old.close <= 0) continue;
    final score = recent.close / old.close - 1;
    if (score > bestReturn) {
      bestReturn = score;
      leader = asset;
    }
  }
  return leader;
}

TradeOrder _order({
  required GameState state,
  required FictionalMarketAsset asset,
  required TradeSide side,
  required double quantity,
  required double price,
}) => TradeOrder(
  side: side,
  assetId: asset.id,
  symbol: asset.symbol,
  name: asset.name,
  market: asset.market,
  currency: asset.currency,
  quantity: quantity,
  unitPrice: price,
  quoteDate: marketDateKey(state.currentDate),
  marketMinute: state.marketMinute,
  isTradingDay: true,
);

Future<void> main() async {
  final universe = await FictionalMarketUniverse.load(seed: _seed);
  var state = _engine.createNewGame(
    '27년 직접 플레이 연구소',
    initialCash: 0,
    worldSeed: _seed,
    story: StoryState.newPlayer(
      playerName: 'Codex',
      introChoice: 'computer',
      startingTrait: StoryTrait.analysis,
      familyRule: FamilyRule.reportLosses,
    ),
  );
  state = _resolvePending(state);

  var buys = 0;
  var sells = 0;
  var rejections = 0;
  final rejectionMessages = <String, int>{};
  var saveReloads = 0;
  var generatedIpoTrades = 0;
  var workedDays = 0;
  var peakAssets = 0;
  var peakAssetsDate = state.currentDate;
  var maxDrawdown = 0.0;
  var maxDrawdownPeakDate = state.currentDate;
  var maxDrawdownTroughDate = state.currentDate;
  var maxDrawdownPeakAssets = 0;
  var maxDrawdownTroughAssets = 0;
  final lastMarketCloses = <String, double>{};
  var equalWeightMarketIndex = 1.0;
  var marketPeakIndex = 1.0;
  var marketPeakDate = state.currentDate;
  var marketMaxDrawdown = 0.0;
  var marketMaxDrawdownPeakDate = state.currentDate;
  var marketMaxDrawdownTroughDate = state.currentDate;
  for (final asset in universe.assets) {
    final baseline = asset.quoteAtOrBefore(state.campaignStartDate);
    if (baseline != null) {
      lastMarketCloses[asset.id] = baseline.close;
    }
  }
  var lastRebalanceMonth = '';
  var lastSavedYear = state.currentDate.year;

  while (!state.campaignComplete) {
    state = _resolvePending(state);

    if (state.day <= 5) {
      final beforeWork = state;
      for (final activity in workActivities) {
        state = _engine.completeWorkSession(
          state,
          WorkSessionResult(activityId: activity.id, score: 100, maxScore: 100),
        );
      }
      if (state.cash != beforeWork.cash) workedDays++;
      state = _checkedTransition(beforeWork, state, 'daily work');
    }

    final monthKey =
        '${state.currentDate.year}-${state.currentDate.month.toString().padLeft(2, '0')}';
    if (isMarketTradingDay(state.currentDate) &&
        monthKey != lastRebalanceMonth) {
      lastRebalanceMonth = monthKey;
      state = state.copyWith(marketMinute: krxOpenMinute);

      for (final position in [...state.positions]) {
        final asset = universe.assets.singleWhere(
          (candidate) => candidate.id == position.assetId,
        );
        final price = asset.previousCloseBefore(
          marketDateKey(state.currentDate),
        );
        if (price == null || price <= 0) continue;
        var remaining = position.units;
        while (remaining > 0.000001) {
          final maxUnits = gameMarketOrderNotionalLimit(price) / price;
          final quantity = math.min(remaining, maxUnits);
          final result = _engine.executeTrade(
            state,
            _order(
              state: state,
              asset: asset,
              side: TradeSide.sell,
              quantity: quantity,
              price: price,
            ),
          );
          if (!result.success) {
            rejections++;
            rejectionMessages[result.message] =
                (rejectionMessages[result.message] ?? 0) + 1;
            break;
          }
          state = _checkedTransition(state, result.state, 'sell ${asset.id}');
          sells++;
          remaining -= result.filledQuantity;
          if (result.filledQuantity + 0.000001 < quantity) {
            // 시장가는 같은 분의 호가 용량만 먹는 IOC다. 남은 수량은
            // 다음 월 리밸런싱에서 다시 시도하고 같은 분에 연타하지 않는다.
            break;
          }
        }
      }

      final desiredBank = math.min(500000, state.cash ~/ 2);
      if (state.bankCash < desiredBank &&
          state.brokerageCash > desiredBank - state.bankCash) {
        final transfer = _engine.transferBrokerageCash(
          state,
          amount: desiredBank - state.bankCash,
          deposit: false,
        );
        if (transfer.success) {
          state = _checkedTransition(state, transfer.state, 'bank reserve');
        }
      } else if (state.bankCash > desiredBank + 50000) {
        final transfer = _engine.transferBrokerageCash(
          state,
          amount: state.bankCash - desiredBank,
          deposit: true,
        );
        if (transfer.success) {
          state = _checkedTransition(state, transfer.state, 'broker funding');
        }
      }

      final leader = _momentumLeader(universe, state.currentDate);
      if (leader != null) {
        final price = leader.previousCloseBefore(
          marketDateKey(state.currentDate),
        );
        if (price != null && price > 0) {
          final quantity = gameMaxBuyQuantity(state, price);
          if (quantity > 0) {
            final result = _engine.executeTrade(
              state,
              _order(
                state: state,
                asset: leader,
                side: TradeSide.buy,
                quantity: quantity.toDouble(),
                price: price,
              ),
            );
            if (result.success) {
              state = _checkedTransition(
                state,
                result.state,
                'buy ${leader.id}',
              );
              buys++;
              if (leader.listedOn != null && leader.parentAssetId == null) {
                generatedIpoTrades++;
              }
            } else {
              rejections++;
              rejectionMessages[result.message] =
                  (rejectionMessages[result.message] ?? 0) + 1;
            }
          }
        }
      }
    }

    final news = marketNewsEventsForState(state);
    state = _engine.archiveNews(
      state,
      headline: buildDailyBrief(state).title,
      eventIds: news.map((event) => event.id).toList(growable: false),
    );
    final beforeAdvance = state;
    state = _engine.advanceOneDay(state);
    state = _checkedTransition(beforeAdvance, state, 'advance one day');
    final beforeActions = state;
    state = _engine.applyCorporateActions(
      state,
      universe.corporateActionsOn(state.currentDate),
    );
    state = _checkedTransition(beforeActions, state, 'corporate actions');

    if (state.currentDate.year != lastSavedYear) {
      final restored = _engine.migrate(state.toJson());
      if (restored.positions.length != state.positions.length ||
          restored.cash != state.cash ||
          restored.brokerageCash != state.brokerageCash) {
        throw StateError('Annual save/reload changed assets in $lastSavedYear');
      }
      state = restored;
      saveReloads++;
      lastSavedYear = state.currentDate.year;
    }

    final prices = <String, double>{};
    final marketDailyReturns = <double>[];
    for (final asset in universe.assets) {
      final quote = asset.quoteAtOrBefore(state.currentDate);
      if (quote == null) continue;
      prices[asset.id] = quote.close;
      if (quote.isExactDate) {
        final previous = lastMarketCloses[asset.id];
        if (previous != null && previous > 0) {
          marketDailyReturns.add(quote.close / previous - 1);
        }
        lastMarketCloses[asset.id] = quote.close;
      }
    }
    if (marketDailyReturns.isNotEmpty) {
      final averageReturn =
          marketDailyReturns.fold<double>(0, (sum, value) => sum + value) /
          marketDailyReturns.length;
      equalWeightMarketIndex *= 1 + averageReturn;
      if (equalWeightMarketIndex > marketPeakIndex) {
        marketPeakIndex = equalWeightMarketIndex;
        marketPeakDate = state.currentDate;
      }
      final marketDrawdown =
          (marketPeakIndex - equalWeightMarketIndex) / marketPeakIndex;
      if (marketDrawdown > marketMaxDrawdown) {
        marketMaxDrawdown = marketDrawdown;
        marketMaxDrawdownPeakDate = marketPeakDate;
        marketMaxDrawdownTroughDate = state.currentDate;
      }
    }
    final assets =
        state.cash +
        state.portfolioValue(prices) +
        state.personalFinance.estimatedPropertyValueAt(state.day);
    if (assets > peakAssets) {
      peakAssets = assets;
      peakAssetsDate = state.currentDate;
    }
    if (peakAssets > 0) {
      final drawdown = (peakAssets - assets) / peakAssets;
      if (drawdown > maxDrawdown) {
        maxDrawdown = drawdown;
        maxDrawdownPeakDate = peakAssetsDate;
        maxDrawdownTroughDate = state.currentDate;
        maxDrawdownPeakAssets = peakAssets;
        maxDrawdownTroughAssets = assets;
      }
    }
  }

  state = _resolvePending(state);
  final prices = <String, double>{
    for (final asset in universe.assets)
      if (asset.quoteAtOrBefore(state.currentDate) case final quote?)
        asset.id: quote.close,
  };
  final resolvedDecisions = state.decisions
      .where((decision) => decision.status == DecisionStatus.resolved)
      .length;
  final result = <String, Object>{
    'start': state.campaignStartDate.toIso8601String().split('T').first,
    'end': state.currentDate.toIso8601String().split('T').first,
    'daysPlayed': state.day,
    'workedDays': workedDays,
    'buys': buys,
    'sells': sells,
    'orderRejections': rejections,
    'rejectionMessages': rejectionMessages,
    'saveReloads': saveReloads,
    'generatedIpoTrades': generatedIpoTrades,
    'resolvedDecisions': resolvedDecisions,
    'ledgerEntries': state.ledger.length,
    'cash': state.cash,
    'bankCash': state.bankCash,
    'brokerageCash': state.brokerageCash,
    'portfolioValue': state.portfolioValue(prices),
    'maxDrawdownPct': double.parse((maxDrawdown * 100).toStringAsFixed(2)),
    'maxDrawdownPeakDate': marketDateKey(maxDrawdownPeakDate),
    'maxDrawdownTroughDate': marketDateKey(maxDrawdownTroughDate),
    'maxDrawdownPeakAssets': maxDrawdownPeakAssets,
    'maxDrawdownTroughAssets': maxDrawdownTroughAssets,
    'marketMaxDrawdownPct': double.parse(
      (marketMaxDrawdown * 100).toStringAsFixed(2),
    ),
    'marketMaxDrawdownPeakDate': marketDateKey(marketMaxDrawdownPeakDate),
    'marketMaxDrawdownTroughDate': marketDateKey(marketMaxDrawdownTroughDate),
    'newsArchiveDays':
        ((state.story.storyFlags['newsArchive'] as List?) ?? const []).length,
    'unpaidOperatingCost': state.story.flagInt('unpaidOperatingCost'),
  };
  // 27년 동일가중 시장은 위기 국면이 체감될 만큼 하락하되 캠페인을
  // 사실상 복구 불가능하게 만들지는 않는 범위여야 한다.
  if (buys < 20 ||
      sells < 20 ||
      rejections != 0 ||
      saveReloads != fictionalCampaignEndYear - fictionalCampaignStartYear ||
      generatedIpoTrades == 0 ||
      resolvedDecisions < 20 ||
      maxDrawdown > 0.65 ||
      marketMaxDrawdown < 0.30 ||
      marketMaxDrawdown > 0.75 ||
      state.story.flagInt('unpaidOperatingCost') != 0) {
    throw StateError(
      'Full-campaign playtest regression: ${jsonEncode(result)}',
    );
  }
  print(const JsonEncoder.withIndent('  ').convert(result));
}
