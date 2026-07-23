import 'dart:math' as math;

import 'game_state.dart';
import 'market_clock.dart';
import 'market_data.dart';
import 'mission_progression.dart';
import 'organization_state.dart';
import 'personal_finance_state.dart';
import 'seed_money_content.dart';
import 'story_state.dart';

const initialCompanyCash = 10000;
const grandfatherNewYearGiftSourceId = 'grandfather-new-year-gift';
const gameTradingFeeRate = 0.0025;
const dailyMarketReportPrice = 1200;

int gameTradingFee(int notional) => (notional * gameTradingFeeRate).round();

double gameTradingFeeMultiplier(GameState state) {
  final helperDiscount =
      state.story.storyFlags['activeResearchHelper'] == 'mother' &&
      state.story.flagInt('activeResearchHelperDay', -1) == state.day;
  final skillDiscount = state.progression.hasSkill('fee_sense') ? 0.9 : 1.0;
  return (helperDiscount ? 0.9 : 1.0) * skillDiscount;
}

int gameTradingFeeForState(GameState state, int notional) =>
    (gameTradingFee(notional) * gameTradingFeeMultiplier(state)).round();

double gameTradingFeeRateForState(GameState state) =>
    gameTradingFeeRate * gameTradingFeeMultiplier(state);

enum TradeSide { buy, sell }

enum TradeOrderType { market, limit }

const gameMinimumOrderLiquidity = 5000000;
const gameMaximumOrderLiquidity = 2000000000;

int gameOrderAuthorityLimit(GameState state) =>
    switch (state.story.accountAuthorityLevel) {
      0 => 0,
      1 => 100000,
      2 => 250000,
      3 => ((state.cash + state.portfolioCost) * 0.25).round(),
      4 => 5000000,
      _ => gameMaximumOrderLiquidity,
    };

int gameMarketOrderNotionalLimit(double unitPrice) {
  if (!unitPrice.isFinite || unitPrice <= 0) return 0;
  return (unitPrice * 50000)
      .round()
      .clamp(gameMinimumOrderLiquidity, gameMaximumOrderLiquidity)
      .toInt();
}

double gameMarketImpactRate(int rawNotional) {
  if (rawNotional <= gameMinimumOrderLiquidity) return 0;
  final pressure = rawNotional / gameMinimumOrderLiquidity;
  return (math.log(pressure + 1) * 0.004).clamp(0, 0.04).toDouble();
}

int gameTradeNotional({
  required TradeSide side,
  required double unitPrice,
  required double quantity,
}) {
  final raw = (unitPrice * quantity).round();
  if (raw <= 0) return 0;
  final impact = gameMarketImpactRate(raw);
  final multiplier = side == TradeSide.buy ? 1 + impact : 1 - impact;
  return (raw * multiplier).round();
}

int gameMaxBuyQuantity(GameState state, double unitPrice) {
  if (!unitPrice.isFinite ||
      unitPrice <= 0 ||
      state.availableBrokerageCash <= 0 ||
      state.story.accountAuthorityLevel == 0) {
    return 0;
  }
  final rawLimit = math.min(
    gameOrderAuthorityLimit(state),
    gameMarketOrderNotionalLimit(unitPrice),
  );
  var low = 0;
  var high = math.min(
    (state.availableBrokerageCash / unitPrice).floor(),
    (rawLimit / unitPrice).floor(),
  );
  while (low < high) {
    final middle = (low + high + 1) ~/ 2;
    final rawNotional = (unitPrice * middle).round();
    final notional = gameTradeNotional(
      side: TradeSide.buy,
      unitPrice: unitPrice,
      quantity: middle.toDouble(),
    );
    final fee = gameTradingFeeForState(state, notional);
    if (rawNotional <= rawLimit &&
        notional + fee <= state.availableBrokerageCash) {
      low = middle;
    } else {
      high = middle - 1;
    }
  }
  return low;
}

int gameAvailableLimitFillUnits({
  required String assetId,
  required int day,
  required int minute,
  required double unitPrice,
}) {
  if (assetId.isEmpty || unitPrice <= 0 || !unitPrice.isFinite) return 0;
  var hash = day * 1009 + minute * 9176;
  for (final unit in assetId.codeUnits) {
    hash = ((hash * 31) ^ unit) & 0x7fffffff;
  }
  final base = 120 + hash % 1881;
  final auctionMultiplier =
      minute < krxOpenMinute + 5 || minute >= krxContinuousEndMinute ? 2 : 1;
  final notionalCap = gameMarketOrderNotionalLimit(unitPrice);
  return math.min(base * auctionMultiplier, notionalCap ~/ unitPrice);
}

class TradeOrder {
  const TradeOrder({
    required this.side,
    required this.assetId,
    required this.symbol,
    required this.name,
    required this.market,
    required this.currency,
    required this.quantity,
    required this.unitPrice,
    required this.quoteDate,
    required this.marketMinute,
    required this.isTradingDay,
    this.type = TradeOrderType.market,
    this.limitPrice,
    this.previousClose = 0,
  });

  final TradeSide side;
  final String assetId;
  final String symbol;
  final String name;
  final String market;
  final String currency;
  final double quantity;
  final double unitPrice;
  final String quoteDate;
  final int marketMinute;
  final bool isTradingDay;
  final TradeOrderType type;
  final double? limitPrice;
  final double previousClose;
}

class TradeExecutionResult {
  const TradeExecutionResult({
    required this.state,
    required this.success,
    required this.message,
    this.notional = 0,
    this.fee = 0,
    this.realizedPnl = 0,
    this.orderId,
    this.filledQuantity = 0,
    this.pendingQuantity = 0,
  });

  final GameState state;
  final bool success;
  final String message;
  final int notional;
  final int fee;
  final int realizedPnl;
  final String? orderId;
  final double filledQuantity;
  final double pendingQuantity;
}

class FinanceActionResult {
  const FinanceActionResult({
    required this.state,
    required this.success,
    required this.message,
    this.cashDelta = 0,
  });

  final GameState state;
  final bool success;
  final String message;
  final int cashDelta;
}

class MissionProgressView {
  const MissionProgressView({
    required this.mission,
    required this.current,
    required this.complete,
    required this.unlocked,
    required this.remainingDays,
  });

  final MissionDefinition mission;
  final int current;
  final bool complete;
  final bool unlocked;
  final int? remainingDays;

  double get ratio => (current / mission.target).clamp(0, 1).toDouble();
}

class MissionClaimResult {
  const MissionClaimResult({
    required this.state,
    required this.success,
    required this.message,
    this.cashReward = 0,
    this.experienceReward = 0,
    this.unlockedSkill,
  });

  final GameState state;
  final bool success;
  final String message;
  final int cashReward;
  final int experienceReward;
  final SkillDefinition? unlockedSkill;
}

class GameEngine {
  const GameEngine();

  static int _newGameSerial = 0;
  static final math.Random _worldSeedRandom = math.Random.secure();

  GameState createNewGame(
    String companyName, {
    StoryState? story,
    int initialCash = initialCompanyCash,
    String? worldSeed,
  }) {
    final seed =
        worldSeed ??
        'world-${DateTime.now().microsecondsSinceEpoch}-${_newGameSerial++}-${_worldSeedRandom.nextInt(0x7fffffff)}-${_stableHash(companyName.trim())}';
    final baseStory = story ?? StoryState.migratedDefault(companyName);
    final isGrandfatherGiftStart =
        initialCompanyCash > 0 && initialCash == initialCompanyCash;
    final storyState = isGrandfatherGiftStart
        ? baseStory.copyWith(
            accountAuthorityLevel: math.max(1, baseStory.accountAuthorityLevel),
            storyFlags: {
              ...baseStory.storyFlags,
              'startingSeedMoney': initialCompanyCash,
              'seedMoneySource': 'grandfather_new_year_gift',
              'firstSeedGoalReached': true,
            },
          )
        : initialCash > initialCompanyCash &&
              baseStory.accountAuthorityLevel == 0
        ? baseStory.copyWith(accountAuthorityLevel: 5)
        : baseStory;
    final company = const CompanyState(
      id: 'hanbit_telecom',
      name: '한빛통신',
      worldMode: CompanyWorldMode.fictional,
      worldStartedAtDay: 1,
      worldPremise: '처음부터 생성된 가상 세계',
      votingOwnershipPct: 0,
      worldReferencePrice: null,
      simulatedPrice: 28400,
      monthlyRevenue: 120000,
      brand: 42,
      technology: 48,
      morale: 55,
      risk: 20,
    );
    final state = GameState(
      version: GameState.schemaVersion,
      companyName: companyName.trim(),
      day: 1,
      marketMinute: marketDayStartMinute,
      simulationSeed: seed,
      cash: initialCash,
      brokerageCash: initialCash,
      positions: const [],
      pendingOrders: const [],
      organization: OrganizationState.initial(storyState.familyRule),
      personalFinance: PersonalFinanceState.initial(),
      progression: MissionProgressionState.initial(day: 1, cash: initialCash),
      story: storyState,
      company: company,
      project: null,
      decisions: [_firstResearchNote(1)],
      scheduledEvents: const [],
      ledger: isGrandfatherGiftStart
          ? const [
              LedgerEntry(
                id: grandfatherNewYearGiftSourceId,
                day: 1,
                amount: initialCompanyCash,
                account: 'brokerage_cash',
                counterAccount: 'family_gift',
                description: '외할아버지 세뱃돈 · 첫 투자금',
                sourceId: grandfatherNewYearGiftSourceId,
              ),
            ]
          : const [],
      processedEventIds: isGrandfatherGiftStart
          ? const [grandfatherNewYearGiftSourceId]
          : const [],
    );
    return prepareHiddenMarketScenario(state);
  }

  GameState migrate(Map<String, dynamic> json) {
    if (json['company'] != null) {
      final state = GameState.fromJson({
        ...json,
        'version': GameState.schemaVersion,
      });
      return _recoverLegacyMarketState(state);
    }
    final companyName = (json['companyName'] as String? ?? '').trim();
    // Legacy saves keep their recorded balance and must not receive the new
    // grandfather gift retroactively.
    final fresh = createNewGame(companyName, initialCash: 0);
    final currentDate = DateTime.tryParse(
      (json['currentDate'] as String? ?? '').trim(),
    );
    final migratedDay = currentDate == null
        ? ((json['day'] as num?)?.toInt() ?? 1)
        : currentDate.difference(DateTime(2000, 1, 1)).inDays + 1;
    return _recoverLegacyMarketState(
      fresh.copyWith(
        day: migratedDay.clamp(1, GameState.maxCampaignDay),
        cash: (json['cash'] as num?)?.toInt() ?? 0,
        brokerageCash: (json['cash'] as num?)?.toInt() ?? 0,
        positions: PortfolioPosition.listFromJson(json['positions']),
        organization: OrganizationState.fromJson(
          const {},
          legacyTeamCount: (json['team'] as num?)?.toInt() ?? 1,
          familyRule: fresh.story.familyRule,
        ),
      ),
    );
  }

  GameState _recoverLegacyMarketState(GameState state) {
    bool isCurrentWorldAsset(String assetId) =>
        isFictionalMarketAssetId(assetId, seed: state.simulationSeed);
    final invalid = state.positions
        .where((position) => !isCurrentWorldAsset(position.assetId))
        .toList(growable: false);
    final recovered = invalid.fold<int>(
      0,
      (sum, position) => sum + position.totalCost,
    );
    const sourceId = 'legacy-real-market-recovery-v14';
    final companyIsFictional = isCurrentWorldAsset(state.company.id);
    final migratedCompany = companyIsFictional
        ? state.company.copyWith(worldMode: CompanyWorldMode.fictional)
        : const CompanyState(
            id: 'hanbit_telecom',
            name: '한빛통신',
            worldMode: CompanyWorldMode.fictional,
            worldStartedAtDay: 1,
            worldPremise: 'v14 가상 시장 전환',
            votingOwnershipPct: 0,
            worldReferencePrice: null,
            simulatedPrice: 28400,
            monthlyRevenue: 120000,
            brand: 42,
            technology: 48,
            morale: 55,
            risk: 20,
          );
    var migrated = state.copyWith(
      version: GameState.schemaVersion,
      company: migratedCompany,
      cash: state.cash + recovered,
      brokerageCash: state.brokerageCash + recovered,
      positions: state.positions
          .where((position) => isCurrentWorldAsset(position.assetId))
          .toList(growable: false),
      ledger: <LedgerEntry>[
        ...state.ledger,
        if (invalid.isNotEmpty && !state.processedEventIds.contains(sourceId))
          LedgerEntry(
            id: sourceId,
            day: state.day,
            amount: recovered,
            account: 'brokerage_cash',
            counterAccount: 'legacy_position_recovery',
            description: '기존 실제 종목을 원가 기준 현금으로 전환',
            sourceId: sourceId,
          ),
      ],
      processedEventIds: <String>[
        ...state.processedEventIds,
        if (invalid.isNotEmpty && !state.processedEventIds.contains(sourceId))
          sourceId,
      ],
    );
    migrated = prepareHiddenMarketScenario(migrated);
    return migrated;
  }

  MissionProgressView? missionProgress(GameState state) {
    final mission = state.progression.activeMission;
    if (mission == null) return null;
    final unlocked = state.currentDate.year >= mission.requiredYear;
    final raw = mission.metric == 'cash_gain'
        ? state.cash - state.progression.missionStartCash
        : _rawMissionMetric(state, mission.metric);
    final current = mission.relative && mission.metric != 'cash_gain'
        ? raw - state.progression.missionStartCounter
        : raw;
    final remainingDays = mission.deadlineDays == null
        ? null
        : (mission.deadlineDays! -
                  (state.day - state.progression.missionStartedDay))
              .clamp(0, mission.deadlineDays!);
    return MissionProgressView(
      mission: mission,
      current: current.clamp(0, 1 << 62),
      complete: unlocked && current >= mission.target,
      unlocked: unlocked,
      remainingDays: remainingDays,
    );
  }

  MissionClaimResult claimMission(GameState state) {
    final progress = missionProgress(state);
    if (progress == null) {
      return MissionClaimResult(
        state: state,
        success: false,
        message: '모든 장기 미션을 완료했습니다.',
      );
    }
    if (!progress.unlocked) {
      return MissionClaimResult(
        state: state,
        success: false,
        message: '${progress.mission.requiredYear}년부터 도전할 수 있습니다.',
      );
    }
    if (!progress.complete) {
      return MissionClaimResult(
        state: state,
        success: false,
        message: '목표를 아직 달성하지 못했습니다.',
      );
    }

    final beforeLevel = state.progression.level;
    final cashMultiplier = state.progression.hasSkill('legendary_house')
        ? 1.25
        : 1.0;
    final cashReward = (progress.mission.cashReward * cashMultiplier).round();
    final nextExperience =
        state.progression.experience + progress.mission.experienceReward;
    final flags = <String, dynamic>{
      ...state.story.storyFlags,
      'reputation': (state.story.reputation + progress.mission.reputationReward)
          .clamp(0, 100),
    };
    var rewarded = state.copyWith(
      cash: state.cash + cashReward,
      story: state.story.copyWith(
        familyTrust: state.story.familyTrust + progress.mission.trustReward,
        storyFlags: flags,
      ),
      ledger: cashReward == 0
          ? state.ledger
          : <LedgerEntry>[
              ...state.ledger,
              LedgerEntry(
                id: 'mission-${progress.mission.id}-${state.day}',
                day: state.day,
                amount: cashReward,
                account: 'company_bank',
                counterAccount: 'mission_reward',
                description: '${progress.mission.title} 완료 보상',
                sourceId: 'mission-${progress.mission.id}',
              ),
            ],
    );
    final nextIndex = state.progression.currentMissionIndex + 1;
    final nextMission = nextIndex < missionCatalog.length
        ? missionCatalog[nextIndex]
        : null;
    final nextBaseline = nextMission == null
        ? 0
        : _rawMissionMetric(rewarded, nextMission.metric);
    final claimed = <String>[
      ...state.progression.claimedMissionIds,
      if (!state.progression.claimedMissionIds.contains(progress.mission.id))
        progress.mission.id,
    ];
    rewarded = rewarded.copyWith(
      progression: state.progression.copyWith(
        experience: nextExperience,
        currentMissionIndex: nextIndex,
        missionStartedDay: state.day,
        missionStartCash: rewarded.cash,
        missionStartCounter: nextBaseline,
        claimedMissionIds: claimed,
      ),
    );
    final afterLevel = rewarded.progression.level;
    SkillDefinition? unlockedSkill;
    if (afterLevel > beforeLevel) {
      unlockedSkill = skillCatalog
          .where(
            (skill) => skill.level > beforeLevel && skill.level <= afterLevel,
          )
          .lastOrNull;
    }
    return MissionClaimResult(
      state: rewarded,
      success: true,
      message: unlockedSkill == null
          ? '${progress.mission.title} 완료! +${progress.mission.experienceReward} XP'
          : '레벨 $afterLevel 달성 · ${unlockedSkill.name} 스킬 해금!',
      cashReward: cashReward,
      experienceReward: progress.mission.experienceReward,
      unlockedSkill: unlockedSkill,
    );
  }

  int _rawMissionMetric(GameState state, String metric) {
    final counter = state.progression.counter(metric);
    int maxWithCounter(int value) => value > counter ? value : counter;
    return switch (metric) {
      'work_sessions' => maxWithCounter(state.story.flagInt('workSessions', 0)),
      'earned_seed' => state.story.seedMoneyTotal,
      'decisions_resolved' => maxWithCounter(
        state.decisions
            .where((decision) => decision.status == DecisionStatus.resolved)
            .length,
      ),
      'buy_orders' => maxWithCounter(
        state.ledger
            .where(
              (entry) =>
                  entry.counterAccount == 'market_security' &&
                  entry.description.contains('매수'),
            )
            .length,
      ),
      'shares_bought' => maxWithCounter(
        state.positions.fold<int>(
          0,
          (sum, position) => sum + position.units.floor(),
        ),
      ),
      'unique_assets' => state.positions.length,
      'days_advanced' => maxWithCounter(state.day - 1),
      'sell_orders' => maxWithCounter(
        state.ledger
            .where(
              (entry) =>
                  entry.counterAccount == 'market_security' &&
                  entry.description.contains('매도'),
            )
            .length,
      ),
      'profitable_sales' => maxWithCounter(
        state.ledger.where((entry) => entry.realizedPnl > 0).length,
      ),
      'realized_profit' => maxWithCounter(
        state.ledger.fold<int>(
          0,
          (sum, entry) => sum + (entry.realizedPnl > 0 ? entry.realizedPnl : 0),
        ),
      ),
      'family_help' => state.organization.researchHelpCount,
      'cash' => state.cash,
      'reputation' => state.story.reputation,
      'positive_months' => counter,
      'employees' => state.organization.employees.length,
      'research_income' => maxWithCounter(
        state.ledger
            .where((entry) => entry.counterAccount == 'research_income')
            .fold<int>(0, (sum, entry) => sum + entry.amount),
      ),
      'fund_launched' => state.story.fundLaunched ? 1 : 0,
      'external_aum' => state.story.externalAum,
      'finance_purchases' => maxWithCounter(
        state.personalFinance.permanentPurchases.length +
            state.personalFinance.lastPurchasePeriods.length,
      ),
      'properties' => state.personalFinance.realEstate.length,
      'trade_volume' => maxWithCounter(
        state.ledger.fold<int>(0, (sum, entry) => sum + entry.notional.abs()),
      ),
      'net_worth' =>
        state.cash +
            state.portfolioCost +
            state.personalFinance.propertyBookValue,
      'property_income' => state.personalFinance.totalPropertyIncome,
      'chance_plays' => state.personalFinance.chancePlayCount,
      _ => counter,
    };
  }

  GameState _refreshExpiredMissionWindow(GameState state) {
    final progress = missionProgress(state);
    if (progress == null ||
        progress.mission.deadlineDays == null ||
        progress.complete) {
      return state;
    }
    final elapsed = state.day - state.progression.missionStartedDay;
    if (elapsed <= progress.mission.deadlineDays!) return state;
    return state.copyWith(
      progression: state.progression.copyWith(
        missionStartedDay: state.day,
        missionStartCash: state.cash,
        missionStartCounter: _rawMissionMetric(state, progress.mission.metric),
      ),
    );
  }

  FinanceActionResult transferBrokerageCash(
    GameState state, {
    required int amount,
    required bool deposit,
  }) {
    FinanceActionResult reject(String message) =>
        FinanceActionResult(state: state, success: false, message: message);
    if (amount <= 0) return reject('이체 금액은 0원보다 커야 합니다.');
    final available = deposit ? state.bankCash : state.availableBrokerageCash;
    if (amount > available) {
      return reject(deposit ? '회사 통장 잔액이 부족합니다.' : '출금 가능한 예수금이 부족합니다.');
    }
    final sourceId =
        'brokerage-${deposit ? 'deposit' : 'withdraw'}-${state.day}-'
        '${state.marketMinute}-${state.ledger.length + 1}';
    final nextBrokerageCash =
        state.brokerageCash + (deposit ? amount : -amount);
    final next = state.copyWith(
      brokerageCash: nextBrokerageCash,
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: 0,
          account: deposit ? 'brokerage_cash' : 'company_bank',
          counterAccount: deposit ? 'company_bank' : 'brokerage_cash',
          description: '증권계좌 ${deposit ? '입금' : '출금'} $amount원 · 총자산 변동 없음',
          sourceId: sourceId,
          notional: amount,
        ),
      ],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      message: '$amount원을 증권계좌에 ${deposit ? '입금' : '출금'}했습니다.',
    );
  }

  TradeExecutionResult _placeLimitOrder(GameState state, TradeOrder order) {
    TradeExecutionResult reject(String message) =>
        TradeExecutionResult(state: state, success: false, message: message);
    final limitPrice = order.limitPrice;
    if (limitPrice == null ||
        !limitPrice.isFinite ||
        limitPrice <= 0 ||
        !isValidMarketOrderPrice(limitPrice, market: order.market)) {
      return reject('지정가는 해당 시장의 호가단위에 맞춰 입력해 주세요.');
    }
    if (order.assetId.trim().isEmpty ||
        !order.quantity.isFinite ||
        order.quantity <= 0 ||
        order.quantity != order.quantity.roundToDouble()) {
      return reject('주문 수량은 1주 단위로 입력해 주세요.');
    }
    final stateDate = marketDateKey(state.currentDate);
    if (order.quoteDate != stateDate ||
        order.marketMinute != state.marketMinute ||
        order.currency != 'KRW') {
      return reject('시세가 바뀌었습니다. 주문창을 다시 확인해 주세요.');
    }
    final clock = marketClockAt(
      order.marketMinute,
      tradingDay: order.isTradingDay && isMarketTradingDay(state.currentDate),
    );
    if (!clock.tradable) return reject('현재는 주문 가능한 거래 시간이 아닙니다.');

    final reference = order.previousClose > 0
        ? order.previousClose
        : order.unitPrice;
    final range = marketDailyPriceRange(
      previousClose: reference,
      date: state.currentDate,
      market: order.market,
    );
    if (limitPrice < range.lower || limitPrice > range.upper) {
      return reject(
        '지정가는 오늘 가격제한폭 '
        '${range.lower.round()}~${range.upper.round()}원 안에서만 낼 수 있습니다.',
      );
    }

    final limitNotional = (limitPrice * order.quantity).round();
    if (order.side == TradeSide.buy) {
      final authorityLimit = gameOrderAuthorityLimit(state);
      if (state.story.accountAuthorityLevel == 0) {
        return reject('첫 주문 권한을 먼저 열어야 합니다.');
      }
      if (limitNotional > authorityLimit) {
        return reject('현재 계좌 권한의 1회 주문 한도를 넘었습니다.');
      }
      final reservation = (limitNotional * 1.003).ceil();
      if (reservation > state.availableBrokerageCash) {
        return reject('다른 미체결 주문을 제외한 주문 가능 예수금이 부족합니다.');
      }
    } else {
      PortfolioPosition? position;
      for (final item in state.positions) {
        if (item.assetId == order.assetId) {
          position = item;
          break;
        }
      }
      final available =
          (position?.units ?? 0) -
          state.pendingSellReservedUnits(order.assetId);
      if (available + 0.000001 < order.quantity) {
        return reject('다른 미체결 매도 주문을 제외한 보유 수량이 부족합니다.');
      }
    }

    final highestPendingSequence = state.pendingOrders.fold<int>(
      0,
      (highest, pending) => math.max(highest, pending.placedSequence),
    );
    var orderSequence =
        math.max(highestPendingSequence, state.ledger.length) + 1;
    late String orderId;
    do {
      orderId =
          'limit-${order.side.name}-${state.day}-${order.marketMinute}-'
          '${order.assetId}-$orderSequence';
      if (state.pendingOrders.every((pending) => pending.id != orderId)) break;
      orderSequence += 1;
    } while (true);
    final marketable = order.side == TradeSide.buy
        ? limitPrice >= order.unitPrice
        : limitPrice <= order.unitPrice;
    final capacity = marketable
        ? gameAvailableLimitFillUnits(
            assetId: order.assetId,
            day: state.day,
            minute: order.marketMinute,
            unitPrice: order.unitPrice,
          )
        : 0;
    final fillQuantity = math.min(order.quantity, capacity.toDouble());
    var nextState = state;
    var filledNotional = 0;
    var filledFee = 0;
    var realizedPnl = 0;
    if (fillQuantity > 0) {
      final fill = executeTrade(
        state,
        TradeOrder(
          side: order.side,
          assetId: order.assetId,
          symbol: order.symbol,
          name: order.name,
          market: order.market,
          currency: order.currency,
          quantity: fillQuantity,
          unitPrice: order.unitPrice,
          quoteDate: order.quoteDate,
          marketMinute: order.marketMinute,
          isTradingDay: order.isTradingDay,
          previousClose: order.previousClose,
        ),
      );
      if (!fill.success) return fill;
      nextState = fill.state;
      filledNotional = fill.notional;
      filledFee = fill.fee;
      realizedPnl = fill.realizedPnl;
    }

    final remaining = order.quantity - fillQuantity;
    if (remaining > 0.000001) {
      nextState = nextState.copyWith(
        pendingOrders: [
          ...nextState.pendingOrders,
          PendingTradeOrder(
            id: orderId,
            side: order.side == TradeSide.buy
                ? PendingOrderSide.buy
                : PendingOrderSide.sell,
            assetId: order.assetId,
            symbol: order.symbol,
            name: order.name,
            market: order.market,
            currency: order.currency,
            limitPrice: limitPrice,
            originalQuantity: order.quantity,
            remainingQuantity: remaining,
            placedDate: stateDate,
            placedMinute: order.marketMinute,
            placedSequence: orderSequence,
          ),
        ],
      );
    }
    final message = remaining <= 0.000001
        ? '${order.name} 지정가 ${_tradeUnits(fillQuantity)}주 전량 체결'
        : fillQuantity > 0
        ? '${order.name} ${_tradeUnits(fillQuantity)}주 체결 · '
              '${_tradeUnits(remaining)}주 미체결 대기'
        : '${order.name} ${_tradeUnits(remaining)}주 지정가 주문 접수';
    return TradeExecutionResult(
      state: nextState,
      success: true,
      message: message,
      notional: filledNotional,
      fee: filledFee,
      realizedPnl: realizedPnl,
      orderId: remaining > 0.000001 ? orderId : null,
      filledQuantity: fillQuantity,
      pendingQuantity: remaining,
    );
  }

  FinanceActionResult cancelPendingOrder(GameState state, String orderId) {
    final index = state.pendingOrders.indexWhere(
      (order) => order.id == orderId,
    );
    if (index < 0) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '취소할 미체결 주문을 찾지 못했습니다.',
      );
    }
    final order = state.pendingOrders[index];
    final pending = [...state.pendingOrders]..removeAt(index);
    final sourceId = 'cancel-$orderId';
    final next = state.copyWith(
      pendingOrders: pending,
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: 0,
          account: 'brokerage_order',
          counterAccount: 'order_cancel',
          description:
              '${order.name} ${_tradeUnits(order.remainingQuantity)}주 '
              '${order.side == PendingOrderSide.buy ? '매수' : '매도'} 주문 취소',
          sourceId: sourceId,
        ),
      ],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      message: '${order.name} 미체결 주문을 취소했습니다.',
    );
  }

  GameState processPendingOrdersAtQuote(
    GameState state, {
    required String assetId,
    required double unitPrice,
    required int marketMinute,
    required bool isTradingDay,
  }) {
    if (state.pendingOrders.every((order) => order.assetId != assetId)) {
      return state;
    }
    final clock = marketClockAt(
      marketMinute,
      tradingDay: isTradingDay && isMarketTradingDay(state.currentDate),
    );
    if (!clock.tradable) return state;
    var capacity = gameAvailableLimitFillUnits(
      assetId: assetId,
      day: state.day,
      minute: marketMinute,
      unitPrice: unitPrice,
    );
    if (capacity <= 0) return state;

    var next = state;
    final candidates =
        state.pendingOrders.where((order) => order.assetId == assetId).toList()
          ..sort((left, right) {
            if (left.side != right.side) {
              return left.side.index.compareTo(right.side.index);
            }
            final priceOrder = left.side == PendingOrderSide.buy
                ? right.limitPrice.compareTo(left.limitPrice)
                : left.limitPrice.compareTo(right.limitPrice);
            if (priceOrder != 0) return priceOrder;
            final minuteOrder = left.placedMinute.compareTo(right.placedMinute);
            if (minuteOrder != 0) return minuteOrder;
            final sequenceOrder = left.placedSequence.compareTo(
              right.placedSequence,
            );
            if (sequenceOrder != 0) return sequenceOrder;
            return left.id.compareTo(right.id);
          });
    for (final candidate in candidates) {
      if (capacity <= 0) break;
      final marketable = candidate.side == PendingOrderSide.buy
          ? candidate.limitPrice >= unitPrice
          : candidate.limitPrice <= unitPrice;
      if (!marketable) continue;
      final quantity = math.min(
        candidate.remainingQuantity,
        capacity.toDouble(),
      );
      final withoutCurrent = next.copyWith(
        pendingOrders: next.pendingOrders
            .where((order) => order.id != candidate.id)
            .toList(growable: false),
        marketMinute: marketMinute,
      );
      final fill = executeTrade(
        withoutCurrent,
        TradeOrder(
          side: candidate.side == PendingOrderSide.buy
              ? TradeSide.buy
              : TradeSide.sell,
          assetId: candidate.assetId,
          symbol: candidate.symbol,
          name: candidate.name,
          market: candidate.market,
          currency: candidate.currency,
          quantity: quantity,
          unitPrice: unitPrice,
          quoteDate: marketDateKey(state.currentDate),
          marketMinute: marketMinute,
          isTradingDay: isTradingDay,
          previousClose: unitPrice,
        ),
      );
      if (!fill.success) continue;
      next = fill.state;
      final remaining = candidate.remainingQuantity - quantity;
      if (remaining > 0.000001) {
        next = next.copyWith(
          pendingOrders: [
            ...next.pendingOrders,
            candidate.copyWith(remainingQuantity: remaining),
          ],
        );
      }
      capacity -= quantity.ceil();
    }
    return next;
  }

  GameState expirePendingOrders(GameState state) {
    if (state.pendingOrders.isEmpty) return state;
    final dateKey = marketDateKey(state.currentDate);
    final expired = state.pendingOrders
        .where(
          (order) =>
              order.placedDate != dateKey ||
              state.marketMinute >= krxCloseMinute,
        )
        .toList(growable: false);
    if (expired.isEmpty) return state;
    final ids = expired.map((order) => order.id).toSet();
    final sourceId = 'expire-orders-${state.day}-${state.marketMinute}';
    return state.copyWith(
      pendingOrders: state.pendingOrders
          .where((order) => !ids.contains(order.id))
          .toList(growable: false),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: 0,
          account: 'brokerage_order',
          counterAccount: 'day_order_expiry',
          description: '장 마감 · 미체결 ${expired.length}건 자동 취소',
          sourceId: sourceId,
        ),
      ],
    );
  }

  TradeExecutionResult executeTrade(GameState state, TradeOrder order) {
    if (order.type == TradeOrderType.limit) {
      return _placeLimitOrder(state, order);
    }
    TradeExecutionResult reject(String message) =>
        TradeExecutionResult(state: state, success: false, message: message);

    if (order.assetId.trim().isEmpty ||
        !order.quantity.isFinite ||
        order.quantity <= 0) {
      return reject('수량은 0보다 커야 합니다.');
    }
    if (order.side == TradeSide.buy &&
        order.quantity != order.quantity.roundToDouble()) {
      return reject('매수 수량은 1주 단위로 입력해 주세요.');
    }
    if (!order.unitPrice.isFinite || order.unitPrice <= 0) {
      return reject('유효한 현재가가 없습니다.');
    }
    final stateDate = state.currentDate.toIso8601String().split('T').first;
    if (order.quoteDate != stateDate) {
      return reject('시세 날짜가 바뀌었습니다. 주문창을 다시 확인해 주세요.');
    }
    if (order.currency != 'KRW') {
      return reject('해외 종목은 실제 환율 원장을 연결한 뒤 거래할 수 있습니다.');
    }
    if (order.marketMinute != state.marketMinute) {
      return reject('시세 시간이 바뀌었습니다. 주문창을 다시 확인해 주세요.');
    }
    final clock = marketClockAt(
      order.marketMinute,
      tradingDay: order.isTradingDay && isMarketTradingDay(state.currentDate),
    );
    if (!clock.tradable) {
      return reject('현재는 주문 가능한 거래 시간이 아닙니다.');
    }

    final rawNotional = (order.unitPrice * order.quantity).round();
    if (rawNotional <= 0) return reject('주문 금액이 올바르지 않습니다.');
    final liquidityLimit = gameMarketOrderNotionalLimit(order.unitPrice);
    if (rawNotional > liquidityLimit) {
      return reject('이 종목의 1회 체결 한도는 $liquidityLimit원입니다. 수량을 나눠 주문해 주세요.');
    }
    if (order.side == TradeSide.buy) {
      final authority = state.story.accountAuthorityLevel;
      final limit = gameOrderAuthorityLimit(state);
      if (authority == 0) {
        return reject('종잣돈 10,000원을 먼저 마련해 보호자 승인을 받아야 합니다.');
      }
      if (rawNotional > limit) {
        return reject('현재 계좌 권한의 1회 주문 한도는 $limit원입니다.');
      }
    }
    final notional = gameTradeNotional(
      side: order.side,
      unitPrice: order.unitPrice,
      quantity: order.quantity,
    );
    final fee = gameTradingFeeForState(state, notional);
    final index = state.positions.indexWhere(
      (position) => position.assetId == order.assetId,
    );
    final existing = index < 0 ? null : state.positions[index];
    final positions = [...state.positions];
    late int cashDelta;
    late int disposedCost;
    late int realizedPnl;
    late String description;

    if (order.side == TradeSide.buy) {
      final debit = notional + fee;
      if (debit > state.availableBrokerageCash) {
        return reject('미체결 주문을 제외한 주문 가능 예수금이 부족합니다.');
      }
      final nextPosition = existing == null
          ? PortfolioPosition(
              assetId: order.assetId,
              symbol: order.symbol,
              name: order.name,
              market: order.market,
              currency: order.currency,
              units: order.quantity.toDouble(),
              totalCost: debit,
            )
          : existing.copyWith(
              units: existing.units + order.quantity,
              totalCost: existing.totalCost + debit,
            );
      if (index < 0) {
        positions.add(nextPosition);
      } else {
        positions[index] = nextPosition;
      }
      cashDelta = -debit;
      disposedCost = 0;
      realizedPnl = 0;
      description =
          '${order.name} ${_tradeUnits(order.quantity)}주 매수 · 증권 수수료 $fee원';
    } else {
      final availableUnits =
          (existing?.units ?? 0) -
          state.pendingSellReservedUnits(order.assetId);
      if (existing == null || availableUnits + 0.000001 < order.quantity) {
        return reject('보유 수량이 부족합니다.');
      }
      final proceeds = notional - fee;
      final soldCost = order.quantity >= existing.units
          ? existing.totalCost
          : (existing.totalCost * order.quantity / existing.units).round();
      final remainingUnits = existing.units - order.quantity;
      if (remainingUnits <= 0.000001) {
        positions.removeAt(index);
      } else {
        positions[index] = existing.copyWith(
          units: remainingUnits,
          totalCost: existing.totalCost - soldCost,
        );
      }
      cashDelta = proceeds;
      disposedCost = soldCost;
      realizedPnl = proceeds - soldCost;
      description =
          '${order.name} ${_tradeUnits(order.quantity)}주 매도 · 증권 수수료 $fee원 · '
          '실현손익 ${realizedPnl >= 0 ? '+' : ''}$realizedPnl원';
    }

    final sideLabel = order.side == TradeSide.buy ? '매수' : '매도';
    final sourceId =
        'trade-${order.side.name}-${state.day}-${order.marketMinute}-'
        '${order.assetId}-${state.ledger.length + 1}';
    final flags = Map<String, dynamic>.from(state.story.storyFlags);
    var authority = state.story.accountAuthorityLevel;
    var reputation = state.story.reputation;
    var progression = state.progression.record('trade_volume', notional);
    if (!state.story.flagBool('firstOrderExecuted')) {
      flags['firstOrderExecuted'] = true;
      authority = authority < 2 ? 2 : authority;
      reputation += 2;
    }
    if (order.side == TradeSide.buy) {
      progression = progression
          .record('buy_orders')
          .record('shares_bought', order.quantity.round());
    } else {
      progression = progression.record('sell_orders');
    }
    if (order.side == TradeSide.sell && realizedPnl > 0) {
      reputation += state.progression.hasSkill('calm_exit') ? 2 : 1;
      progression = progression
          .record('profitable_sales')
          .record('realized_profit', realizedPnl);
    }
    flags['reputation'] = reputation.clamp(0, 100);
    final next = state.copyWith(
      marketMinute: order.marketMinute,
      brokerageCash: state.brokerageCash + cashDelta,
      cash: state.cash + cashDelta,
      positions: positions,
      progression: progression,
      story: state.story.copyWith(
        accountAuthorityLevel: authority,
        familyTrust: state.story.familyTrust + 1,
        storyFlags: flags,
      ),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: cashDelta,
          account: 'brokerage_cash',
          counterAccount: 'market_security',
          description: description,
          sourceId: sourceId,
          notional: notional,
          tradingFee: fee,
          disposedCost: disposedCost,
          realizedPnl: realizedPnl,
        ),
      ],
    );
    return TradeExecutionResult(
      state: next,
      success: true,
      message:
          '${order.name} ${_tradeUnits(order.quantity)}주 $sideLabel 완료 · 증권 수수료 $fee원'
          '${order.side == TradeSide.sell ? ' · 실현손익 ${realizedPnl >= 0 ? '+' : ''}$realizedPnl원' : ''}',
      notional: notional,
      fee: fee,
      realizedPnl: realizedPnl,
      filledQuantity: order.quantity,
    );
  }

  GameState applyCorporateActions(
    GameState state,
    List<MarketCorporateAction> actions,
  ) {
    var cash = state.cash;
    var brokerageCash = state.brokerageCash;
    var positions = [...state.positions];
    final ledger = [...state.ledger];
    final processed = {...state.processedEventIds};
    var changed = false;
    final dateKey = state.currentDate.toIso8601String().split('T').first;

    final orderedActions = [...actions]
      ..sort((left, right) {
        final typeOrder =
            (left.type == MarketCorporateActionType.dividend ? 0 : 1).compareTo(
              right.type == MarketCorporateActionType.dividend ? 0 : 1,
            );
        if (typeOrder != 0) return typeOrder;
        return left.id.compareTo(right.id);
      });
    for (final action in orderedActions) {
      final eventId = 'market-action-${action.id}';
      if (action.date != dateKey || processed.contains(eventId)) continue;
      final index = positions.indexWhere(
        (position) => position.assetId == action.assetId,
      );
      final position = index < 0 ? null : positions[index];
      if (position != null && action.type == MarketCorporateActionType.split) {
        final nextUnits = position.units * action.unitFactor;
        if (nextUnits.isFinite && nextUnits > 0) {
          positions[index] = position.copyWith(units: nextUnits);
          ledger.add(
            LedgerEntry(
              id: eventId,
              day: state.day,
              amount: 0,
              account: 'market_security',
              counterAccount: 'corporate_action',
              description:
                  '${position.name} 주식수 조정 · ${action.numerator}:${action.denominator}',
              sourceId: eventId,
            ),
          );
          changed = true;
        }
      } else if (position != null &&
          action.type == MarketCorporateActionType.dividend &&
          action.currency == 'KRW') {
        final dividend = (position.units * action.amount).round();
        if (dividend > 0) {
          cash += dividend;
          brokerageCash += dividend;
          ledger.add(
            LedgerEntry(
              id: eventId,
              day: state.day,
              amount: dividend,
              account: 'brokerage_cash',
              counterAccount: 'dividend_income',
              description: '${position.name} 배당금',
              sourceId: eventId,
            ),
          );
          changed = true;
        }
      } else if (position != null &&
          action.type == MarketCorporateActionType.spinoff &&
          action.relatedAssetId != null &&
          action.relatedSymbol != null &&
          action.relatedName != null &&
          action.relatedMarket != null) {
        final grantedUnits = position.units * action.unitFactor;
        if (grantedUnits.isFinite && grantedUnits > 0) {
          final relatedIndex = positions.indexWhere(
            (item) => item.assetId == action.relatedAssetId,
          );
          if (relatedIndex >= 0) {
            positions[relatedIndex] = positions[relatedIndex].copyWith(
              units: positions[relatedIndex].units + grantedUnits,
            );
          } else {
            positions.add(
              PortfolioPosition(
                assetId: action.relatedAssetId!,
                symbol: action.relatedSymbol!,
                name: action.relatedName!,
                market: action.relatedMarket!,
                currency: action.currency,
                units: grantedUnits,
                totalCost: 0,
              ),
            );
          }
          ledger.add(
            LedgerEntry(
              id: eventId,
              day: state.day,
              amount: 0,
              account: 'market_security',
              counterAccount: 'corporate_spinoff',
              description:
                  '${position.name} 분사 · ${action.relatedName} ${_tradeUnits(grantedUnits)}주 배정',
              sourceId: eventId,
            ),
          );
          changed = true;
        }
      } else if (position != null &&
          action.type == MarketCorporateActionType.materialSpinoff) {
        ledger.add(
          LedgerEntry(
            id: eventId,
            day: state.day,
            amount: 0,
            account: 'market_security',
            counterAccount: 'corporate_material_spinoff',
            description: '${position.name} 물적분할 · 신설법인 지분은 모회사가 보유',
            sourceId: eventId,
          ),
        );
        changed = true;
      } else if (position != null &&
          action.type == MarketCorporateActionType.rightsIssue) {
        ledger.add(
          LedgerEntry(
            id: eventId,
            day: state.day,
            amount: 0,
            account: 'market_security',
            counterAccount: 'corporate_rights_issue',
            description: '${position.name} 유상증자 · 보유지분 희석 가능성 발생',
            sourceId: eventId,
          ),
        );
        changed = true;
      } else if (position != null &&
          action.type == MarketCorporateActionType.delisting) {
        final payout = (position.units * action.amount).round();
        cash += payout;
        brokerageCash += payout;
        positions.removeAt(index);
        ledger.add(
          LedgerEntry(
            id: eventId,
            day: state.day,
            amount: payout,
            account: 'brokerage_cash',
            counterAccount: 'delisting_settlement',
            description: '${position.name} 상장폐지 정리매매·잔여가치 정산',
            sourceId: eventId,
            notional: payout,
            disposedCost: position.totalCost,
            realizedPnl: payout - position.totalCost,
          ),
        );
        changed = true;
      }
      processed.add(eventId);
    }

    if (!changed && processed.length == state.processedEventIds.length) {
      return state;
    }
    return state.copyWith(
      cash: cash,
      brokerageCash: brokerageCash,
      positions: positions,
      ledger: ledger,
      processedEventIds: processed.toList(growable: false),
    );
  }

  GameState completeWorkSession(GameState state, WorkSessionResult result) {
    final flags = Map<String, dynamic>.from(state.story.storyFlags);
    final recordedDay = (flags['workDay'] as num?)?.toInt();
    final sessionsToday = recordedDay == state.day
        ? (flags['workSessionsToday'] as num?)?.toInt() ?? 0
        : 0;
    if (sessionsToday >= 3) return state;

    final score = result.score.clamp(0, result.maxScore);
    final normalized = result.maxScore <= 0
        ? 0
        : (score * 100 ~/ result.maxScore);
    final baseReward = switch (result.activityId) {
      'dishes' => 500 + normalized * 8,
      'stationery' => 800 + normalized * 7,
      'flea_market' => 700 + normalized * 15,
      _ => 0,
    };
    final yearScale = state.currentDate.year >= 2006
        ? 6
        : state.currentDate.year >= 2003
        ? 3
        : 1;
    final traitBonus = switch (state.story.startingTrait) {
      StoryTrait.stability => 1.05,
      StoryTrait.innovation => 1.08,
      StoryTrait.analysis => 1.10,
      StoryTrait.control => 1.03,
    };
    final skillBonus = state.progression.hasSkill('work_rhythm') ? 1.10 : 1.0;
    final reward = (baseReward * yearScale * traitBonus * skillBonus).round();
    if (reward <= 0) return state;

    final activityLabel = switch (result.activityId) {
      'dishes' => '저녁 설거지',
      'stationery' => '문방구 재고 정리',
      'flea_market' => '가족 벼룩장터',
      _ => '일거리',
    };
    final sessionNumber = (flags['workSessions'] as num?)?.toInt() ?? 0;
    final sourceId =
        'work-${state.day}-${sessionNumber + 1}-${result.activityId}';
    if (state.processedEventIds.contains(sourceId)) return state;

    final earned = (flags['earnedSeedMoney'] as num?)?.toInt() ?? 0;
    final seedMoneyBefore = state.story.startingSeedMoney + earned;
    flags['earnedSeedMoney'] = earned + reward;
    flags['workSessions'] = sessionNumber + 1;
    flags['workDay'] = state.day;
    flags['workSessionsToday'] = sessionsToday + 1;
    flags['lastWorkActivity'] = result.activityId;
    flags['lastWorkScore'] = normalized;
    final reachedSeedGoal = seedMoneyBefore + reward >= 10000;
    final firstCompletion =
        reachedSeedGoal && !state.story.flagBool('firstSeedGoalReached');
    if (reachedSeedGoal) {
      flags['firstSeedGoalReached'] = true;
      if (firstCompletion) {
        flags['reputation'] = (state.story.reputation + 3).clamp(0, 100);
      }
    }

    final next = state.copyWith(
      cash: state.cash + reward,
      progression: state.progression.record('work_sessions'),
      story: state.story.copyWith(
        accountAuthorityLevel:
            reachedSeedGoal && state.story.accountAuthorityLevel < 1
            ? 1
            : state.story.accountAuthorityLevel,
        familyTrust: state.story.familyTrust + (firstCompletion ? 2 : 0),
        storyFlags: flags,
      ),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: reward,
          account: 'company_bank',
          counterAccount: 'work_income',
          description: '$activityLabel · 정확도 $normalized점',
          sourceId: sourceId,
        ),
      ],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
    return next;
  }

  GameState markHubTutorialSeen(GameState state) => state.copyWith(
    story: state.story.copyWith(
      storyFlags: {...state.story.storyFlags, 'hubTutorialSeen': true},
    ),
  );

  GameState requestFamilyHelp(GameState state, String helperId) {
    final organization = state.organization.requestFamilyHelp(
      helperId,
      state.day,
    );
    if (identical(organization, state.organization)) return state;
    final flags = <String, dynamic>{
      ...state.story.storyFlags,
      'activeResearchHelper': helperId,
      'activeResearchHelperDay': state.day,
      'researchBonusPct': helperId == 'mother'
          ? 10
          : helperId == 'father'
          ? 8
          : helperId == 'sister'
          ? 12
          : 15,
      'reputation': (state.story.reputation + 1).clamp(0, 100),
    };
    final story = switch (helperId) {
      'mother' => state.story.copyWith(
        motherAffinity: state.story.motherAffinity + 2,
        familyTrust: state.story.familyTrust + 1,
        storyFlags: flags,
      ),
      'father' => state.story.copyWith(
        fatherAffinity: state.story.fatherAffinity + 2,
        familyTrust: state.story.familyTrust + 1,
        storyFlags: flags,
      ),
      'sister' => state.story.copyWith(
        siblingAffinity: state.story.siblingAffinity + 2,
        storyFlags: flags,
      ),
      _ => state.story.copyWith(
        grandfatherAffinity: state.story.grandfatherAffinity + 2,
        familyTrust: state.story.familyTrust + 1,
        storyFlags: flags,
      ),
    };
    return state.copyWith(
      organization: organization,
      story: story,
      progression: state.progression.record('family_help'),
    );
  }

  GameState hireEmployee(GameState state, String candidateId) {
    if (state.currentDate.year < 2003) return state;
    final candidate = kHiringCandidates
        .where((item) => item.id == candidateId)
        .firstOrNull;
    if (candidate == null ||
        state.organization.employees.any((item) => item.id == candidateId)) {
      return state;
    }
    final baseJoiningCost = candidate.salaryMonthly ~/ 2;
    final joiningCost = state.progression.hasSkill('talent_network')
        ? (baseJoiningCost * 0.9).round()
        : baseJoiningCost;
    if (state.bankCash < joiningCost) return state;
    final sourceId = 'hire-$candidateId-${state.day}';
    return state.copyWith(
      cash: state.cash - joiningCost,
      organization: state.organization.hire(candidate, state.day),
      story: state.story.copyWith(
        storyFlags: {
          ...state.story.storyFlags,
          'reputation': (state.story.reputation + 4).clamp(0, 100),
        },
      ),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -joiningCost,
          account: 'company_bank',
          counterAccount: 'recruiting',
          description: '${candidate.name} 채용 계약금',
          sourceId: sourceId,
        ),
      ],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
  }

  GameState launchFund(GameState state) {
    if (state.currentDate.year < 2004 ||
        state.organization.employees.isEmpty ||
        state.story.reputation < 12 ||
        state.story.fundLaunched) {
      return state;
    }
    final externalAum = 5000000 + state.story.reputation * 200000;
    return state.copyWith(
      story: state.story.copyWith(
        accountAuthorityLevel: state.story.accountAuthorityLevel < 4
            ? 4
            : state.story.accountAuthorityLevel,
        storyFlags: {
          ...state.story.storyFlags,
          'fundLaunched': true,
          'externalAum': externalAum,
          'reputation': (state.story.reputation + 8).clamp(0, 100),
        },
      ),
    );
  }

  FinanceActionResult purchaseSpendingOption(GameState state, String optionId) {
    final option = spendingOptionById(optionId);
    if (option == null) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '존재하지 않는 소비 항목입니다.',
      );
    }
    if (state.currentDate.year < option.unlockYear) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '${option.unlockYear}년부터 선택할 수 있습니다.',
      );
    }
    if (option.requiresEmployee && state.organization.employees.isEmpty) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '정식 직원을 먼저 채용해야 합니다.',
      );
    }
    if (option.requiresLegalCompany &&
        !state.story.flagBool('isLegalCompany')) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '2006년 법인 설립 결정을 마친 뒤 진행할 수 있습니다.',
      );
    }
    final finance = state.personalFinance;
    if (option.isRealEstate && finance.ownsRealEstate(option.id)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '이미 보유한 부동산입니다.',
      );
    }
    if (option.repeat == SpendingRepeat.once &&
        !option.isRealEstate &&
        finance.hasPermanentPurchase(option.id)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '이미 완료한 지출입니다.',
      );
    }
    final period = switch (option.repeat) {
      SpendingRepeat.once => 'once',
      SpendingRepeat.monthly =>
        '${state.currentDate.year}-${state.currentDate.month.toString().padLeft(2, '0')}',
      SpendingRepeat.yearly => '${state.currentDate.year}',
    };
    if (option.repeat != SpendingRepeat.once &&
        finance.lastPurchasePeriods[option.id] == period) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: option.repeat == SpendingRepeat.monthly
            ? '이번 달에는 이미 선택했습니다.'
            : '올해는 이미 선택했습니다.',
      );
    }
    if (state.bankCash < option.cost) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '은행 잔고가 ${option.cost - state.bankCash}원 부족합니다.',
      );
    }

    final permanentPurchases = [...finance.permanentPurchases];
    if (!option.isRealEstate &&
        option.repeat == SpendingRepeat.once &&
        !permanentPurchases.contains(option.id)) {
      permanentPurchases.add(option.id);
    }
    final realEstate = [...finance.realEstate];
    if (option.isRealEstate) {
      realEstate.add(
        OwnedRealEstate(
          id: '${option.id}-${state.day}',
          optionId: option.id,
          name: option.title,
          purchasePrice: option.cost,
          acquiredDay: state.day,
          monthlyIncome: option.monthlyIncome,
          monthlyCost: option.monthlyCost,
        ),
      );
    }
    final periods = {...finance.lastPurchasePeriods, option.id: period};
    final nextFinance = finance.copyWith(
      realEstate: realEstate,
      permanentPurchases: permanentPurchases,
      lastPurchasePeriods: periods,
      totalSpent: finance.totalSpent + option.cost,
    );
    final flags = <String, dynamic>{
      ...state.story.storyFlags,
      'reputation': (state.story.reputation + option.reputationDelta).clamp(
        0,
        100,
      ),
    };
    final nextStory = state.story.copyWith(
      familyTrust: state.story.familyTrust + option.familyTrustDelta,
      motherAffinity:
          state.story.motherAffinity + (option.familyTrustDelta > 0 ? 1 : 0),
      fatherAffinity:
          state.story.fatherAffinity + (option.familyTrustDelta > 0 ? 1 : 0),
      siblingAffinity:
          state.story.siblingAffinity + (option.familyTrustDelta > 0 ? 1 : 0),
      storyFlags: flags,
    );
    final sourceId = 'spending-${option.id}-${state.day}-$period';
    final next = state.copyWith(
      cash: state.cash - option.cost,
      personalFinance: nextFinance,
      progression: state.progression.record('finance_purchases'),
      story: nextStory,
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -option.cost,
          account: 'company_bank',
          counterAccount: option.isRealEstate
              ? 'real_estate_asset'
              : 'discretionary_expense',
          description: option.title,
          sourceId: sourceId,
        ),
      ],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      message: '${option.title} 지출이 장부에 반영됐습니다.',
      cashDelta: -option.cost,
    );
  }

  FinanceActionResult sellRealEstate(GameState state, String assetId) {
    final assets = state.personalFinance.realEstate;
    final index = assets.indexWhere((asset) => asset.id == assetId);
    if (index < 0) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '보유 부동산을 찾지 못했습니다.',
      );
    }
    final asset = assets[index];
    if (state.day - asset.acquiredDay < 30) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '취득 후 30일이 지나야 매각할 수 있습니다.',
      );
    }
    final proceeds = asset.estimatedSaleValue(state.day);
    final sourceId = 'real-estate-sale-${asset.id}-${state.day}';
    final remaining = [...assets]..removeAt(index);
    final next = state.copyWith(
      cash: state.cash + proceeds,
      personalFinance: state.personalFinance.copyWith(realEstate: remaining),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: proceeds,
          account: 'company_bank',
          counterAccount: 'real_estate_sale',
          description: '${asset.name} 매각',
          sourceId: sourceId,
        ),
      ],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      message: '${asset.name}을 $proceeds원에 매각했습니다.',
      cashDelta: proceeds,
    );
  }

  FinanceActionResult playAdultChanceGame(GameState state, int stake) {
    final age = state.story.ageOn(state.currentDate);
    if (state.currentDate.isBefore(DateTime(2010, 1, 1)) || age < 20) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '성인이 되는 2010년부터만 이용할 수 있습니다.',
      );
    }
    final month =
        '${state.currentDate.year}-${state.currentDate.month.toString().padLeft(2, '0')}';
    if (state.personalFinance.lastChanceMonth == month) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '책임 있는 이용을 위해 월 1회로 제한됩니다.',
      );
    }
    final onePercent = state.bankCash ~/ 100;
    final maxStake = onePercent < 100000 ? onePercent : 100000;
    if (stake < 10000 || stake > maxStake || stake > state.bankCash) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '참가금은 1만원 이상, 현금의 1%와 10만원 중 작은 금액 이하여야 합니다.',
      );
    }
    final roll =
        _stableHash('${state.simulationSeed}:chance:$month:$stake') % 100;
    final payout = roll < 60
        ? 0
        : roll < 90
        ? (stake * 1.5).round()
        : stake * 3;
    final sourceId = 'adult-chance-$month';
    final entries = <LedgerEntry>[
      LedgerEntry(
        id: '$sourceId-stake',
        day: state.day,
        amount: -stake,
        account: 'company_bank',
        counterAccount: 'chance_entertainment',
        description: '성인 확률 오락 참가금',
        sourceId: sourceId,
      ),
      if (payout > 0)
        LedgerEntry(
          id: '$sourceId-payout',
          day: state.day,
          amount: payout,
          account: 'company_bank',
          counterAccount: 'chance_payout',
          description: '성인 확률 오락 지급금',
          sourceId: sourceId,
        ),
    ];
    final nextFinance = state.personalFinance.copyWith(
      totalSpent: state.personalFinance.totalSpent + stake,
      lastChanceMonth: month,
      chancePlayCount: state.personalFinance.chancePlayCount + 1,
      totalChanceStake: state.personalFinance.totalChanceStake + stake,
      totalChancePayout: state.personalFinance.totalChancePayout + payout,
    );
    final next = state.copyWith(
      cash: state.cash - stake + payout,
      personalFinance: nextFinance,
      ledger: [...state.ledger, ...entries],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
    final message = payout == 0
        ? '이번에는 지급금이 없습니다. 다음 달까지 이용이 잠깁니다.'
        : payout >= stake * 3
        ? '10% 결과에 당첨되어 $payout원을 받았습니다.'
        : '30% 결과에 당첨되어 $payout원을 받았습니다.';
    return FinanceActionResult(
      state: next,
      success: true,
      message: message,
      cashDelta: payout - stake,
    );
  }

  GameState archiveNews(
    GameState state, {
    required String headline,
    required List<String> eventIds,
  }) {
    final flags = Map<String, dynamic>.from(state.story.storyFlags);
    final archive = ((flags['newsArchive'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    archive.removeWhere((item) => item['day'] == state.day);
    archive.add({
      'day': state.day,
      'date': state.currentDate.toIso8601String(),
      'headline': headline,
      'eventIds': eventIds,
    });
    if (archive.length > 90) archive.removeRange(0, archive.length - 90);
    flags['newsArchive'] = archive;
    return state.copyWith(story: state.story.copyWith(storyFlags: flags));
  }

  GameState prepareHiddenMarketScenario(GameState state) {
    final flags = Map<String, dynamic>.from(state.story.storyFlags);
    final dateKey = marketDateKey(state.currentDate);
    final current = (flags['hiddenMarketScenario'] as Map?)
        ?.cast<String, dynamic>();
    if (current?['date'] == dateKey) return state;

    final archive = ((flags['marketScenarioArchive'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
    if (current != null) archive.add(current);
    if (archive.length > 32) {
      archive.removeRange(0, archive.length - 32);
    }
    flags['marketWorldVersion'] = 1;
    flags['marketScenarioArchive'] = archive;
    flags['hiddenMarketScenario'] = hiddenFictionalMarketScenario(
      state.simulationSeed,
      state.currentDate,
    );
    return state.copyWith(story: state.story.copyWith(storyFlags: flags));
  }

  FinanceActionResult purchaseDailyMarketReport(GameState state) {
    final dateKey = marketDateKey(state.currentDate);
    final flags = Map<String, dynamic>.from(state.story.storyFlags);
    final reports = <String, dynamic>{
      for (final entry
          in ((flags['dailyMarketReports'] as Map?) ?? const {}).entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
    if (reports.containsKey(dateKey)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '오늘의 시장 조사 보고서는 이미 구매했습니다.',
      );
    }
    if (state.bankCash < dailyMarketReportPrice) {
      return FinanceActionResult(
        state: state,
        success: false,
        message:
            '보고서 구매에 은행 잔고가 ${dailyMarketReportPrice - state.bankCash}원 부족합니다.',
      );
    }

    final events = fictionalMarketEventsForDate(
      state.simulationSeed,
      state.currentDate,
    );
    final signals = events
        .take(3)
        .map(
          (event) => <String, dynamic>{
            'companyName': event.companyName,
            'sector': event.sector,
            'hint': event.reportHint,
          },
        )
        .toList(growable: false);
    reports[dateKey] = signals.isEmpty
        ? <Map<String, dynamic>>[
            <String, dynamic>{
              'companyName': '시장 전체',
              'sector': '수급',
              'hint': '눈에 띄는 기업별 사전 징후가 적다. 거래대금과 업종 순환을 우선 확인할 필요가 있다.',
            },
          ]
        : signals;
    flags['dailyMarketReports'] = reports;
    final sourceId = 'market-report-$dateKey';
    final next = state.copyWith(
      cash: state.cash - dailyMarketReportPrice,
      story: state.story.copyWith(storyFlags: flags),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -dailyMarketReportPrice,
          account: 'company_bank',
          counterAccount: 'market_research_expense',
          description: '오늘의 시장 조사 보고서',
          sourceId: sourceId,
        ),
      ],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      message: '현장 징후를 정리한 보고서를 받았습니다. 결과와 방향은 보장하지 않습니다.',
      cashDelta: -dailyMarketReportPrice,
    );
  }

  List<FictionalMarketEvent> revealedMarketEvents(GameState state) =>
      fictionalMarketEventsForDate(
        state.simulationSeed,
        state.currentDate,
      ).where((event) => event.revealMinute <= state.marketMinute).toList();
  double generatedCompanyPriceForDay(int day) => 28400 + ((day - 1) * 1.5);

  double visiblePrice(GameState state) =>
      state.company.simulatedPrice ?? generatedCompanyPriceForDay(state.day);

  GameState resolveDecision(
    GameState state,
    String decisionId,
    String optionId,
  ) {
    final decision = state.decisions.firstWhere(
      (item) => item.id == decisionId,
    );
    if (decision.status != DecisionStatus.pending) return state;
    final option = decision.options.firstWhere((item) => item.id == optionId);
    if (option.cashCost > state.bankCash) return state;

    var decisions = state.decisions
        .map((item) => item.id == decisionId ? item.resolve(optionId) : item)
        .toList();
    var next = state.copyWith(
      decisions: decisions,
      progression: state.progression
          .record('decisions_resolved')
          .copyWith(experience: state.progression.experience + 25),
    );

    switch (optionId) {
      case 'research_products':
      case 'research_cashflow':
      case 'research_people':
      case 'research_price':
        final focus = optionId.replaceFirst('research_', '');
        next = next.copyWith(
          story: next.story.copyWith(
            familyTrust: next.story.familyTrust + 1,
            storyFlags: {
              ...next.story.storyFlags,
              'firstResearchFocus': focus,
              'researchNoteUnlocked': true,
            },
            seenStoryEventIds: [
              ...next.story.seenStoryEventIds,
              if (!next.story.seenStoryEventIds.contains('FIRST_RESEARCH_NOTE'))
                'FIRST_RESEARCH_NOTE',
            ],
          ),
        );
      case 'acquire_control':
      case 'acquire_control_followup':
        next = _spend(next, option.cashCost, decisionId, '한빛통신 경영권 시나리오 배정금');
        final continuityPrice = generatedCompanyPriceForDay(next.day);
        next = next.copyWith(
          company: next.company.copyWith(
            worldMode: CompanyWorldMode.fictional,
            worldStartedAtDay: next.day,
            worldPremise: '의결권 55% 확보',
            votingOwnershipPct: 55,
            worldReferencePrice: continuityPrice,
            simulatedPrice: continuityPrice,
          ),
          decisions: [...next.decisions, _productProposal(next.day)],
        );
      case 'review_control':
        next = _schedule(
          next,
          'control-followup-${next.day + 3}',
          'control_followup',
          3,
        );
      case 'pass_control':
        next = next.copyWith(
          decisions: [
            ...next.decisions,
            _endingCard(
              next.day,
              '경쟁 세력이 먼저 한빛통신 이사회를 장악했습니다. 다음 기회를 기다려야 해요.',
            ),
          ],
        );
      case 'approve_full':
        next = _startProject(
          next,
          option.cashCost,
          'full',
          24,
          58,
          54,
          6,
          8,
          decisionId,
        );
      case 'approve_prototype':
        next = _startProject(
          next,
          option.cashCost,
          'prototype',
          14,
          52,
          52,
          2,
          4,
          decisionId,
        );
      case 'approve_partner':
        next = _startProject(
          next,
          option.cashCost,
          'partner',
          12,
          52,
          58,
          -1,
          -4,
          decisionId,
        );
      case 'reject_project':
        next = next.copyWith(
          company: next.company.copyWith(
            morale: next.company.morale - 8,
            technology: next.company.technology - 3,
            brand: next.company.brand - 2,
          ),
          project: const ProjectState(
            id: 'project-aurora',
            codename: 'Project Aurora',
            status: ProjectStatus.cancelled,
            approvedBudget: 0,
            spentBudget: 0,
            progress: 0,
            quality: 50,
            marketFit: 50,
            path: 'rejected',
          ),
        );
        next = _schedule(
          next,
          'competitor-result-${next.day + 4}',
          'competitor_result',
          4,
        );
      case 'fix_quality':
        next = _spend(next, option.cashCost, decisionId, '시제품 품질 개선');
        next = next.copyWith(
          company: next.company.copyWith(
            morale: next.company.morale + 3,
            risk: next.company.risk - 5,
          ),
          project: next.project!.copyWith(
            progress: next.project!.progress + 15,
            quality: next.project!.quality + 16,
            spentBudget: next.project!.spentBudget + option.cashCost,
          ),
        );
        next = _schedule(
          next,
          'launch-review-${next.day + 4}',
          'launch_review',
          4,
        );
      case 'cut_scope':
        next = _spend(next, option.cashCost, decisionId, '기능 축소와 안정화');
        next = next.copyWith(
          company: next.company.copyWith(
            morale: next.company.morale - 2,
            risk: next.company.risk + 4,
          ),
          project: next.project!.copyWith(
            progress: next.project!.progress + 24,
            quality: next.project!.quality - 8,
            marketFit: next.project!.marketFit - 5,
            spentBudget: next.project!.spentBudget + option.cashCost,
          ),
        );
        next = _schedule(
          next,
          'launch-review-${next.day + 2}',
          'launch_review',
          2,
        );
      case 'delay_development':
        next = _spend(next, option.cashCost, decisionId, '개발 일정 연장');
        next = next.copyWith(
          company: next.company.copyWith(
            morale: next.company.morale - 1,
            risk: next.company.risk - 3,
          ),
          project: next.project!.copyWith(
            progress: next.project!.progress + 18,
            quality: next.project!.quality + 8,
            spentBudget: next.project!.spentBudget + option.cashCost,
          ),
        );
        next = _schedule(
          next,
          'launch-review-${next.day + 6}',
          'launch_review',
          6,
        );
      case 'cancel_development':
      case 'cancel_launch':
        next = next.copyWith(
          company: next.company.copyWith(
            morale: next.company.morale - 9,
            brand: next.company.brand - 3,
          ),
          project: next.project?.copyWith(status: ProjectStatus.cancelled),
        );
        next = _schedule(
          next,
          'cancel-result-${next.day + 2}',
          'cancel_result',
          2,
        );
      case 'launch_now':
      case 'launch_after_delay':
        next = next.copyWith(
          company: next.company.copyWith(
            risk: next.company.risk + (optionId == 'launch_now' ? 6 : 1),
          ),
          project: next.project!.copyWith(
            status: ProjectStatus.launched,
            progress: 100,
          ),
        );
        next = _schedule(
          next,
          'launch-result-${next.day + 4}',
          'launch_result',
          4,
        );
      case 'delay_launch':
        next = _spend(next, option.cashCost, decisionId, '출시 전 품질 보강');
        next = next.copyWith(
          company: next.company.copyWith(
            morale: next.company.morale - 2,
            risk: next.company.risk - 7,
          ),
          project: next.project!.copyWith(
            status: ProjectStatus.launchReview,
            quality: next.project!.quality + 12,
            marketFit: next.project!.marketFit - 4,
            spentBudget: next.project!.spentBudget + option.cashCost,
          ),
        );
        next = _schedule(
          next,
          'final-launch-review-${next.day + 3}',
          'final_launch_review',
          3,
        );
      case 'era_partner':
      case 'era_prototype':
        next = _spend(next, option.cashCost, decisionId, '시대 기술 실증 투자');
        final isPartner = optionId == 'era_partner';
        final resultEventId = 'era-result-$decisionId';
        next = next.copyWith(
          company: next.company.copyWith(
            technology: next.company.technology + (isPartner ? 5 : 3),
            brand: next.company.brand + (isPartner ? 3 : 1),
            risk: next.company.risk + (isPartner ? 3 : 1),
          ),
          story: next.story.copyWith(
            storyFlags: {
              ...next.story.storyFlags,
              'eraPath:$resultEventId': optionId,
              'eraTitle:$resultEventId': decision.title,
            },
          ),
        );
        next = _schedule(
          next,
          resultEventId,
          'era_technology_result',
          isPartner ? 45 : 30,
        );
      case 'era_observe':
        next = next.copyWith(
          story: next.story.copyWith(
            familyTrust: next.story.familyTrust + 1,
            storyFlags: {
              ...next.story.storyFlags,
              'lastObservedEraTechnology': decision.title,
            },
          ),
        );
      case 'milestone_prudent':
        next = _applyMilestoneResolution(
          next,
          decision,
          optionId: optionId,
          risk: -3,
          reputation: 2,
          trust: 2,
        );
      case 'milestone_bold':
        next = _applyMilestoneResolution(
          next,
          decision,
          optionId: optionId,
          risk: 3,
          reputation: 4,
          trust: 0,
        );
      case 'milestone_family':
        next = _applyMilestoneResolution(
          next,
          decision,
          optionId: optionId,
          risk: -1,
          reputation: 1,
          trust: 4,
        );
      case 'acknowledge':
        break;
    }
    if (state.progression.hasSkill('family_briefing')) {
      next = next.copyWith(
        story: next.story.copyWith(familyTrust: next.story.familyTrust + 1),
      );
    }
    return next;
  }

  GameState _applyMilestoneResolution(
    GameState state,
    DecisionCardData decision, {
    required String optionId,
    required int risk,
    required int reputation,
    required int trust,
  }) {
    final flags = Map<String, dynamic>.from(state.story.storyFlags);
    flags['reputation'] = (state.story.reputation + reputation).clamp(0, 100);
    var officeTier = state.story.officeTier;
    var roomLevel = state.story.roomLevel;
    var legal = state.story.flagBool('isLegalCompany');
    if (decision.id.contains('office-year')) {
      roomLevel = roomLevel < 2 ? 2 : roomLevel;
      if (optionId == 'milestone_bold') {
        officeTier = officeTier < 1 ? 1 : officeTier;
        flags['officeLeaseAccepted'] = true;
        flags.remove('officePlanDeferred');
      } else {
        flags['officePlanDeferred'] = true;
      }
    }
    if (decision.id.contains('incorporation-year')) {
      roomLevel = roomLevel < 3 ? 3 : roomLevel;
      legal = true;
      if (optionId == 'milestone_bold') {
        officeTier = officeTier < 2 ? 2 : officeTier;
        flags['officeExpansionAccepted'] = true;
      }
    }
    flags['officeTier'] = officeTier;
    flags['isLegalCompany'] = legal;
    return state.copyWith(
      story: state.story.copyWith(
        familyTrust: state.story.familyTrust + trust,
        motherAffinity: state.story.motherAffinity + (trust > 0 ? 1 : 0),
        fatherAffinity: state.story.fatherAffinity + (trust > 0 ? 1 : 0),
        siblingAffinity: state.story.siblingAffinity + (trust > 0 ? 1 : 0),
        grandfatherAffinity:
            state.story.grandfatherAffinity + (trust > 0 ? 1 : 0),
        roomLevel: roomLevel,
        storyFlags: flags,
      ),
      company: state.company.copyWith(
        risk: state.company.risk + risk,
        technology: state.company.technology + (risk > 0 ? 2 : 0),
      ),
    );
  }

  GameState advanceOneDay(GameState state) {
    if (state.pendingDecisions.isNotEmpty || state.campaignComplete) {
      return state;
    }
    final settled = expirePendingOrders(
      state.copyWith(marketMinute: krxCloseMinute),
    );
    var next = settled.copyWith(
      day: state.day + 1,
      marketMinute: marketDayStartMinute,
      progression: state.progression.record('days_advanced'),
      organization: state.organization.recoverOneDay(),
    );
    next = _refreshExpiredMissionWindow(next);
    if (next.company.worldMode == CompanyWorldMode.fictional) {
      final basePrice =
          next.company.simulatedPrice ??
          next.company.worldReferencePrice ??
          generatedCompanyPriceForDay(next.day - 1);
      final noise = _noise(
        next.simulationSeed,
        'price-${next.day}',
        -0.012,
        0.012,
      );
      final signal =
          (next.company.brand - 50) * 0.00015 +
          (next.company.technology - 50) * 0.00012 -
          next.company.risk * 0.00008;
      final change = (noise + signal).clamp(-0.15, 0.15);
      final price = (basePrice * (1 + change)).clamp(100, 1000000).toDouble();
      next = next.copyWith(
        company: next.company.copyWith(simulatedPrice: price),
      );
    }
    next = _applyMonthlyEconomy(next);
    next = _applyCampaignMilestones(next);
    next = _applyControlOpportunity(next);
    next = _applyEraTechnologyDecisions(next);
    if (next.day % 30 == 0 &&
        next.project?.status == ProjectStatus.development) {
      const burn = 10000;
      next = _spend(
        next,
        burn,
        'monthly-burn-${next.day}',
        'Project Aurora 월간 개발비',
      );
    }
    final processed = _processDueEvents(next);
    return prepareHiddenMarketScenario(processed);
  }

  GameState _applyMonthlyEconomy(GameState state) {
    if (state.currentDate.day != 1) return state;
    final sourceId =
        'monthly-economy-${state.currentDate.year}-${state.currentDate.month}';
    if (state.processedEventIds.contains(sourceId)) return state;
    final rent = state.personalFinance.ownsRealEstate('owner_office')
        ? 0
        : switch (state.story.officeTier) {
            0 => 0,
            1 => 50000,
            _ => 150000,
          };
    final payroll = state.organization.monthlyPayroll;
    final researchRevenue =
        state.organization.employees.length * 90000 +
        state.personalFinance.monthlyResearchBonusAt(
          state.currentDate.year,
          state.organization.employees.length,
        ) +
        (state.progression.hasSkill('research_habit') ? 20000 : 0);
    final basePropertyIncome = state.personalFinance.monthlyPropertyIncome;
    final propertyIncome = state.progression.hasSkill('property_operation')
        ? (basePropertyIncome * 1.1).round()
        : basePropertyIncome;
    final propertyCost = state.personalFinance.monthlyPropertyCost;
    final managementFee = state.story.fundLaunched
        ? (state.story.externalAum * 0.0005).round()
        : 0;
    final interestRate = state.progression.hasSkill('cash_management')
        ? 0.0015
        : 0.001;
    final interest = state.bankCash > 0
        ? (state.bankCash * interestRate).round()
        : 0;
    final controlledIncome = state.company.isControlled
        ? (state.company.monthlyRevenue * 0.05).round()
        : 0;
    final income =
        researchRevenue +
        managementFee +
        interest +
        controlledIncome +
        propertyIncome;
    final flags = Map<String, dynamic>.from(state.story.storyFlags);
    final priorUnpaid = state.story.flagInt('unpaidOperatingCost');
    final availableBank = state.bankCash + income;
    final currentExpenses = payroll + rent + propertyCost;
    final totalDue = priorUnpaid + currentExpenses;
    final paidTotal = math.min(availableBank, totalDue);
    var remainingPayment = paidTotal;
    final paidPrior = math.min(priorUnpaid, remainingPayment);
    remainingPayment -= paidPrior;
    final paidPayroll = math.min(payroll, remainingPayment);
    remainingPayment -= paidPayroll;
    final paidRent = math.min(rent, remainingPayment);
    remainingPayment -= paidRent;
    final paidPropertyCost = math.min(propertyCost, remainingPayment);
    final paidCurrent = paidPayroll + paidRent + paidPropertyCost;
    final unpaidCurrent = currentExpenses - paidCurrent;
    final unpaidOperatingCost = priorUnpaid - paidPrior + unpaidCurrent;
    final cashDelta = income - paidTotal;
    final endingCash = state.cash + cashDelta;
    final economicNet = income - currentExpenses;
    final history = ((flags['performanceHistory'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    history.add({
      'day': state.day,
      'cash': endingCash,
      'portfolioCost': state.portfolioCost,
      'realizedPnl': state.ledger.fold<int>(
        0,
        (sum, entry) => sum + entry.realizedPnl,
      ),
      'reputation': state.story.reputation,
    });
    if (history.length > 132) history.removeRange(0, history.length - 132);
    flags['performanceHistory'] = history;
    if (unpaidOperatingCost == 0 && economicNet >= 0) {
      flags.remove('unpaidOperatingCost');
      flags['reputation'] = (state.story.reputation + 1).clamp(0, 100);
    } else if (unpaidOperatingCost > 0) {
      flags['unpaidOperatingCost'] = unpaidOperatingCost;
      flags['reputation'] = (state.story.reputation - 2).clamp(0, 100);
    }
    final entries = <LedgerEntry>[];
    void addEntry(String suffix, int amount, String account, String label) {
      if (amount == 0) return;
      entries.add(
        LedgerEntry(
          id: '$sourceId-$suffix',
          day: state.day,
          amount: amount,
          account: 'company_bank',
          counterAccount: account,
          description: label,
          sourceId: sourceId,
        ),
      );
    }

    addEntry('research', researchRevenue, 'research_income', '월간 리서치 수입');
    addEntry('fee', managementFee, 'management_fee', '펀드 월간 운용보수');
    addEntry('interest', interest, 'interest_income', '예수금 이자');
    addEntry('company', controlledIncome, 'company_income', '지배회사 월간 배당');
    addEntry(
      'property-income',
      propertyIncome,
      'property_rent_income',
      '부동산 월 임대수입',
    );
    addEntry(
      'payable-payment',
      -paidPrior,
      'accounts_payable',
      '이전 미지급 운영비 지급',
    );
    addEntry('payroll', -paidPayroll, 'salary_expense', '직원 월 급여 지급');
    addEntry('rent', -paidRent, 'rent_expense', '사무실 월 임대료 지급');
    addEntry(
      'property-cost',
      -paidPropertyCost,
      'property_maintenance',
      '부동산 월 유지비 지급',
    );
    if (unpaidCurrent > 0) {
      entries.add(
        LedgerEntry(
          id: '$sourceId-payable-accrual',
          day: state.day,
          amount: 0,
          account: 'accounts_payable',
          counterAccount: 'operating_expense_accrual',
          description: '이번 달 미지급 운영비',
          sourceId: sourceId,
          notional: unpaidCurrent,
        ),
      );
    }
    var progression = state.progression.record(
      'research_income',
      researchRevenue,
    );
    if (unpaidOperatingCost == 0 && economicNet >= 0) {
      progression = progression.record('positive_months');
    }
    return state.copyWith(
      cash: endingCash,
      progression: progression,
      personalFinance: state.personalFinance.copyWith(
        totalPropertyIncome:
            state.personalFinance.totalPropertyIncome + propertyIncome,
      ),
      story: state.story.copyWith(storyFlags: flags),
      ledger: [...state.ledger, ...entries],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
  }

  GameState _applyControlOpportunity(GameState state) {
    if (state.pendingDecisions.isNotEmpty ||
        state.company.isControlled ||
        state.story.flagBool('controlOfferPresented') ||
        !state.story.flagBool('firstOrderExecuted') ||
        state.day < 30 ||
        state.bankCash < 300000) {
      return state;
    }
    final flags = Map<String, dynamic>.from(state.story.storyFlags)
      ..['controlOfferPresented'] = true;
    return state.copyWith(
      story: state.story.copyWith(storyFlags: flags),
      decisions: [
        ...state.decisions,
        _controlOffer(state.day, followUp: false),
      ],
    );
  }

  GameState _applyEraTechnologyDecisions(GameState state) {
    if (state.pendingDecisions.isNotEmpty) return state;
    final date = state.currentDate;
    final periods = <String>[
      if (date.month >= 4) 'spring',
      if (date.month >= 10) 'autumn',
    ];
    for (final period in periods) {
      final decisionId = 'era-technology-${date.year}-$period';
      if (state.decisions.any((decision) => decision.id == decisionId) ||
          state.processedEventIds.contains(decisionId)) {
        continue;
      }
      final candidates = fictionalEraTechnologies
          .where(
            (technology) =>
                technology.firstYear <= date.year &&
                technology.lastYear >= date.year,
          )
          .toList(growable: false);
      if (candidates.isEmpty) return state;
      final technology =
          candidates[_stableHash('${state.simulationSeed}:$decisionId') %
              candidates.length];
      final yearScale = date.year - 2000;
      final prototypeCost = 10000 + yearScale * 5000;
      final partnershipCost = prototypeCost * 2;
      return state.copyWith(
        decisions: [
          ...state.decisions,
          DecisionCardData(
            id: decisionId,
            category: '시대 기술 검토',
            title: '${technology.name}, 국내 협력 기회를 검토할까?',
            proposer: '국내 산업기술 협의회',
            body:
                '${technology.sectors.join('·')} 업종에서 ${technology.name} 실증 사업이 시작됩니다. '
                '먼저 뛰어들면 기술과 평판을 얻을 수 있지만 시제품이 실패하면 비용과 신뢰를 잃을 수 있습니다.',
            createdDay: state.day,
            dueDay: state.day + 14,
            requestedFunds: partnershipCost,
            benefit: '시대에 맞는 기술·브랜드·협력 경험',
            risk: '시제품 실패·비용 손실·기술 위험 증가',
            advisorOpinions: const [
              '기술자: 작은 시제품으로 먼저 검증하면 실패 비용을 줄일 수 있습니다.',
              '회계사: 협력비는 반드시 은행 잔고 안에서 집행해야 합니다.',
              '가족: 유행 이름보다 고객과 현금흐름을 함께 확인하자.',
            ],
            options: [
              DecisionOptionData(
                id: 'era_partner',
                label: '국내기업과 공동개발',
                description: '비용과 위험을 나누고 45일 뒤 실증 결과를 확인합니다.',
                cashCost: partnershipCost,
              ),
              DecisionOptionData(
                id: 'era_prototype',
                label: '소형 시제품부터 검증',
                description: '작은 비용으로 30일 동안 핵심 기능을 시험합니다.',
                cashCost: prototypeCost,
              ),
              const DecisionOptionData(
                id: 'era_observe',
                label: '자료만 모으며 관찰',
                description: '현금을 지키고 다음 기술 기회를 준비합니다.',
              ),
            ],
          ),
        ],
        processedEventIds: [...state.processedEventIds, decisionId],
      );
    }
    return state;
  }

  GameState _applyCampaignMilestones(GameState state) {
    final date = state.currentDate;
    final milestones =
        <({String id, DateTime date, String title, String body})>[
          (
            id: 'dotcom-reckoning',
            date: DateTime(2001, 3, 12),
            title: '닷컴 열풍 뒤의 첫 원칙 시험',
            body: '유행보다 현금흐름을 볼지, 기술의 장기 가능성을 더 조사할지 가족 앞에서 설명해야 합니다.',
          ),
          (
            id: 'september-eleven',
            date: DateTime(2001, 9, 12),
            title: '불확실성 속에서 지킬 것',
            body: '시장이 흔들리는 날, 계좌보다 가족과 원칙을 먼저 확인합니다.',
          ),
          (
            id: 'first-hiring-year',
            date: DateTime(2003, 1, 2),
            title: '첫 조사원을 맞을 준비',
            body: '이제 사람들 화면에서 후보를 면접하고 계약할 수 있습니다. 급여를 감당할 현금흐름도 함께 봐야 합니다.',
          ),
          (
            id: 'office-year',
            date: DateTime(2004, 1, 2),
            title: '아파트 밖 첫 사무실',
            body: '작은 사무실을 얻으면 신뢰가 오르지만 매달 임대료가 생깁니다.',
          ),
          (
            id: 'incorporation-year',
            date: DateTime(2006, 1, 2),
            title: '정식 회사로 가는 날',
            body: '준법과 회계를 갖춘 법인으로 전환할지 결정합니다.',
          ),
          (
            id: 'financial-crisis',
            date: DateTime(2008, 9, 16),
            title: '금융위기, 유동성 점검',
            body: '버틸 현금과 고객에게 설명할 원칙을 다시 적습니다.',
          ),
          (
            id: 'final-year',
            date: DateTime(2010, 1, 4),
            title: '마지막 해의 투자 서한',
            body: '10년의 선택을 정리하고 마지막 해에 지킬 기준을 고릅니다.',
          ),
        ];
    var next = state;
    for (final milestone in milestones) {
      final eventId = 'milestone-${milestone.id}';
      final isMilestoneDay =
          date.year == milestone.date.year &&
          date.month == milestone.date.month &&
          date.day == milestone.date.day;
      if (!isMilestoneDay ||
          next.processedEventIds.contains(eventId) ||
          next.decisions.any((item) => item.id == eventId)) {
        continue;
      }
      next = next.copyWith(
        decisions: [
          ...next.decisions,
          DecisionCardData(
            id: eventId,
            category: 'milestone',
            title: milestone.title,
            proposer: '가족 투자회의',
            body: milestone.body,
            createdDay: next.day,
            dueDay: next.day + 7,
            requestedFunds: milestone.id == 'office-year'
                ? 50000
                : milestone.id == 'incorporation-year'
                ? 150000
                : 0,
            benefit: '평판·가족 신뢰·조직 성장',
            risk: '선택에 따라 위험과 성장 속도가 달라집니다.',
            advisorOpinions: const [
              '엄마: 장부에 설명할 수 있는 선택이어야 해.',
              '외할아버지: 오래 버틸 수 있는 원칙부터 보자.',
            ],
            options: milestone.id == 'office-year'
                ? const [
                    DecisionOptionData(
                      id: 'milestone_prudent',
                      label: '작은방 사무실 유지',
                      description: '월 임대료 없이 현금과 원칙을 지킵니다.',
                    ),
                    DecisionOptionData(
                      id: 'milestone_bold',
                      label: '작은 사무실 계약',
                      description: '신뢰를 얻는 대신 다음 달부터 월 5만원 임대료가 생깁니다.',
                    ),
                    DecisionOptionData(
                      id: 'milestone_family',
                      label: '가족 공간부터 정비',
                      description: '재택 공간을 개선하고 가족 신뢰를 우선합니다.',
                    ),
                  ]
                : milestone.id == 'incorporation-year'
                ? const [
                    DecisionOptionData(
                      id: 'milestone_prudent',
                      label: '현재 공간에서 법인 전환',
                      description: '사무실을 넓히지 않고 준법·회계 체계부터 갖춥니다.',
                    ),
                    DecisionOptionData(
                      id: 'milestone_bold',
                      label: '법인 전환과 사무실 확장',
                      description: '조직 신뢰를 높이지만 다음 달부터 월 15만원 임대료가 생깁니다.',
                    ),
                    DecisionOptionData(
                      id: 'milestone_family',
                      label: '가족 회계 약속 후 전환',
                      description: '현재 공간을 유지하며 가족과 법인 원칙을 정합니다.',
                    ),
                  ]
                : const [
                    DecisionOptionData(
                      id: 'milestone_prudent',
                      label: '현금과 원칙 우선',
                      description: '위험을 낮추고 가족 신뢰를 높입니다.',
                    ),
                    DecisionOptionData(
                      id: 'milestone_bold',
                      label: '조사 후 과감히 전진',
                      description: '평판과 기술을 얻는 대신 위험이 조금 오릅니다.',
                    ),
                    DecisionOptionData(
                      id: 'milestone_family',
                      label: '가족과 함께 결정',
                      description: '관계와 장기 신뢰를 우선합니다.',
                    ),
                  ],
          ),
        ],
        processedEventIds: [...next.processedEventIds, eventId],
      );
      break;
    }
    return next;
  }

  GameState _processDueEvents(GameState state) {
    var next = state;
    final due =
        next.scheduledEvents
            .where(
              (event) =>
                  event.dueDay <= next.day &&
                  !next.processedEventIds.contains(event.id),
            )
            .toList()
          ..sort((a, b) => a.dueDay.compareTo(b.dueDay));
    for (final event in due) {
      if (next.pendingDecisions.isNotEmpty) break;
      final processed = [...next.processedEventIds, event.id];
      next = next.copyWith(processedEventIds: processed);
      switch (event.type) {
        case 'control_followup':
          next = next.copyWith(
            decisions: [
              ...next.decisions,
              _controlOffer(next.day, followUp: true),
            ],
          );
        case 'development_issue':
          next = next.copyWith(
            decisions: [...next.decisions, _developmentIssue(next.day)],
          );
        case 'launch_review':
          next = next.copyWith(
            project: next.project?.copyWith(status: ProjectStatus.launchReview),
            decisions: [
              ...next.decisions,
              _launchReview(next.day, finalReview: false),
            ],
          );
        case 'final_launch_review':
          next = next.copyWith(
            decisions: [
              ...next.decisions,
              _launchReview(next.day, finalReview: true),
            ],
          );
        case 'era_technology_result':
          next = _applyEraTechnologyResult(next, event.id);
        case 'launch_result':
          next = _applyLaunchResult(next);
        case 'competitor_result':
          next = next.copyWith(
            company: next.company.copyWith(
              brand: next.company.brand - 6,
              technology: next.company.technology - 5,
            ),
            decisions: [
              ...next.decisions,
              _endingCard(
                next.day,
                '경쟁사가 먼저 휴대형 기기를 공개했습니다. 현금을 지켰지만 기술과 브랜드가 뒤처졌어요.',
              ),
            ],
          );
        case 'cancel_result':
          next = next.copyWith(
            decisions: [
              ...next.decisions,
              _endingCard(
                next.day,
                '프로젝트는 정리됐습니다. 더 큰 손실은 막았지만 팀의 자신감이 흔들렸어요.',
              ),
            ],
          );
      }
    }
    return next;
  }

  GameState _applyEraTechnologyResult(GameState state, String eventId) {
    final path = state.story.storyFlags['eraPath:$eventId'] as String?;
    final title =
        state.story.storyFlags['eraTitle:$eventId'] as String? ?? '시대 기술 실증';
    if (path == null) return state;
    final partner = path == 'era_partner';
    final threshold = partner ? 56 : 48;
    final roll = _stableHash('${state.simulationSeed}:$eventId:result') % 100;
    final success = roll < threshold;
    final cashDelta = success ? (partner ? 90000 : 45000) : 0;
    final priceMultiplier = success
        ? (partner ? 1.14 : 1.08)
        : (partner ? 0.78 : 0.88);
    final message = success
        ? '$title 실증이 성공했습니다. 국내 협력사가 양산 검증을 통과해 기술과 브랜드, 후속 수입이 함께 늘었습니다.'
        : '$title 실증이 실패했습니다. 시제품 목표를 충족하지 못해 투자비를 잃고 기술 위험과 평판 부담이 커졌습니다.';
    final flags = Map<String, dynamic>.from(state.story.storyFlags)
      ..remove('eraPath:$eventId')
      ..remove('eraTitle:$eventId');
    return state.copyWith(
      cash: state.cash + cashDelta,
      company: state.company.copyWith(
        technology:
            state.company.technology + (success ? (partner ? 8 : 4) : -4),
        brand: state.company.brand + (success ? (partner ? 7 : 3) : -6),
        morale: state.company.morale + (success ? 4 : -5),
        risk: state.company.risk + (success ? -3 : (partner ? 9 : 5)),
        simulatedPrice:
            (state.company.simulatedPrice ??
                state.company.worldReferencePrice ??
                generatedCompanyPriceForDay(state.day)) *
            priceMultiplier,
      ),
      story: state.story.copyWith(
        storyFlags: {
          ...flags,
          'reputation': (state.story.reputation + (success ? 3 : -2)).clamp(
            0,
            100,
          ),
        },
      ),
      decisions: [...state.decisions, _endingCard(state.day, message)],
      ledger: [
        ...state.ledger,
        if (cashDelta > 0)
          LedgerEntry(
            id: '$eventId-income',
            day: state.day,
            amount: cashDelta,
            account: 'company_bank',
            counterAccount: 'technology_partnership_income',
            description: '시대 기술 실증 후속 수입',
            sourceId: eventId,
          ),
      ],
    );
  }

  GameState _applyLaunchResult(GameState state) {
    final project = state.project!;
    final roll = _noise(
      state.simulationSeed,
      'outcome-${project.path}',
      -15,
      15,
    ).round();
    final score =
        state.company.technology +
        state.company.brand +
        state.company.morale +
        project.quality +
        project.marketFit -
        state.company.risk +
        roll;
    late String message;
    late int revenueDelta;
    late int cashDelta;
    late int brandDelta;
    late int moraleDelta;
    late double priceMultiplier;
    if (score >= 235) {
      message =
          'Project Aurora가 예상 밖의 큰 호응을 얻었습니다. 한빛통신이 새로운 휴대기기 시장의 기준을 만들기 시작했어요.';
      revenueDelta = 260000;
      cashDelta = 180000;
      brandDelta = 16;
      moraleDelta = 10;
      priceMultiplier = 1.18;
    } else if (score >= 205) {
      message = '출시는 안정적으로 자리 잡았습니다. 폭발적 성공은 아니지만 다음 제품을 만들 기반을 얻었어요.';
      revenueDelta = 140000;
      cashDelta = 85000;
      brandDelta = 9;
      moraleDelta = 6;
      priceMultiplier = 1.09;
    } else if (score >= 175) {
      message = '초기 반응은 엇갈렸습니다. 매출은 늘었지만 품질 지원과 다음 개선에 돈이 더 필요해요.';
      revenueDelta = 60000;
      cashDelta = 25000;
      brandDelta = 3;
      moraleDelta = -2;
      priceMultiplier = 0.98;
    } else {
      message = '제품은 시장에 닿았지만 결함과 낮은 수요가 겹쳤습니다. 이 세계에서도 성공은 보장되지 않아요.';
      revenueDelta = -30000;
      cashDelta = -50000;
      brandDelta = -8;
      moraleDelta = -10;
      priceMultiplier = 0.82;
    }
    var next = state.copyWith(
      cash: state.cash + cashDelta,
      company: state.company.copyWith(
        monthlyRevenue: state.company.monthlyRevenue + revenueDelta,
        brand: state.company.brand + brandDelta,
        morale: state.company.morale + moraleDelta,
        simulatedPrice:
            (state.company.simulatedPrice ??
                state.company.worldReferencePrice ??
                generatedCompanyPriceForDay(state.day)) *
            priceMultiplier,
      ),
      project: project.copyWith(status: ProjectStatus.completed),
      decisions: [...state.decisions, _endingCard(state.day, message)],
    );
    next = next.copyWith(
      ledger: [
        ...next.ledger,
        LedgerEntry(
          id: 'launch-result-${next.day}',
          day: next.day,
          amount: cashDelta,
          account: 'company_bank',
          counterAccount: 'product_result',
          description: 'Project Aurora 초기 출시 결과',
          sourceId: 'launch_result',
        ),
      ],
    );
    return next;
  }

  GameState _startProject(
    GameState state,
    int cost,
    String path,
    int progress,
    int quality,
    int marketFit,
    int moraleDelta,
    int riskDelta,
    String sourceId,
  ) {
    var next = _spend(state, cost, sourceId, 'Project Aurora 1차 개발 승인');
    next = next.copyWith(
      company: next.company.copyWith(
        morale: next.company.morale + moraleDelta,
        risk: next.company.risk + riskDelta,
        technology: next.company.technology + (path == 'partner' ? 2 : 1),
      ),
      project: ProjectState(
        id: 'project-aurora',
        codename: 'Project Aurora',
        status: ProjectStatus.development,
        approvedBudget: cost,
        spentBudget: cost,
        progress: progress,
        quality: quality,
        marketFit: marketFit,
        path: path,
      ),
    );
    return _schedule(
      next,
      'development-issue-${next.day + 3}',
      'development_issue',
      3,
    );
  }

  GameState _spend(
    GameState state,
    int cost,
    String sourceId,
    String description,
  ) {
    if (cost == 0) return state;
    if (cost > state.bankCash) return state;
    final ledgerId = '$sourceId-${state.day}-$cost';
    if (state.ledger.any((entry) => entry.id == ledgerId)) return state;
    return state.copyWith(
      cash: state.cash - cost,
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: ledgerId,
          day: state.day,
          amount: -cost,
          account: 'company_bank',
          counterAccount: 'investment',
          description: description,
          sourceId: sourceId,
        ),
      ],
    );
  }

  GameState _schedule(
    GameState state,
    String id,
    String type,
    int daysFromNow,
  ) {
    if (state.scheduledEvents.any((event) => event.id == id) ||
        state.processedEventIds.contains(id)) {
      return state;
    }
    return state.copyWith(
      scheduledEvents: [
        ...state.scheduledEvents,
        ScheduledGameEvent(id: id, type: type, dueDay: state.day + daysFromNow),
      ],
    );
  }

  static DecisionCardData _firstResearchNote(int day) => DecisionCardData(
    id: 'first-research-note',
    category: '처음 배우기',
    title: '첫 미션: 회사 하나를 구경해 보자',
    proposer: '외할아버지',
    body:
        '아직 돈을 쓰지 않아도 괜찮아. 눈에 익은 회사 하나를 고르고, 무엇을 파는지부터 같이 살펴보자. 아래 네 가지 중 가장 쉬워 보이는 방법을 하나 고르면 돼.',
    createdDay: day,
    dueDay: day + 30,
    requestedFunds: 0,
    benefit: '회사 보는 첫 방법을 배우고 +25 XP 받기',
    risk: '한 가지만 보고 바로 사면 실수할 수 있음',
    advisorOpinions: const [
      '엄마: 이 회사가 무엇을 팔아 돈을 버는지부터 적어 보자.',
      '아빠: 우리가 써 본 제품부터 보면 이해하기 쉬워.',
      '누나: 주변 사람들이 정말 쓰는지도 찾아보자.',
    ],
    options: const [
      DecisionOptionData(
        id: 'research_products',
        label: '써 본 제품부터 보기',
        description: '집에서 써 본 물건을 떠올려 회사와 연결해 봅니다.',
      ),
      DecisionOptionData(
        id: 'research_cashflow',
        label: '회사가 돈 버는 법 보기',
        description: '누가 이 회사에 왜 돈을 내는지 한 줄로 적습니다.',
      ),
      DecisionOptionData(
        id: 'research_people',
        label: '회사를 운영하는 사람 보기',
        description: '대표와 직원이 어떤 목표로 일하는지 살펴봅니다.',
      ),
      DecisionOptionData(
        id: 'research_price',
        label: '가격부터 본다',
        description: '주가가 싼지 비싼지 다른 회사와 천천히 비교합니다.',
      ),
    ],
  );

  static DecisionCardData _controlOffer(
    int day, {
    required bool followUp,
  }) => DecisionCardData(
    id: followUp ? 'control-offer-followup-$day' : 'control-offer-$day',
    category: '회사 운영 체험',
    title: followUp ? '한빛통신 운영 체험, 마지막 선택' : '한빛통신 회사를 직접 운영해 볼까?',
    proposer: '시나리오 운영자 윤 실장',
    body: followUp
        ? '검토하는 사이 경쟁 세력이 이사회 표를 모았습니다. 시나리오 비용은 늘었고 오늘 결론이 필요해요.'
        : '첫 세로 슬라이스에서는 개발용 시나리오 계약으로 한빛통신 이사회 의결권 55%를 맡습니다. 실제 거래가격이나 내부정보가 아니며, 이후 세계는 우리의 선택으로 움직입니다.',
    createdDay: day,
    dueDay: day + (followUp ? 1 : 3),
    requestedFunds: followUp ? 350000 : 300000,
    benefit: '한빛통신 경영권과 이사회 과반 체험',
    risk: '게임 자금 감소 · 제품 성공 불확실',
    advisorOpinions: const [
      '운영자: 실제 인수가 아닌 가상 세계 체험용 조건입니다.',
      '기술자: 통합형 휴대기기 아이디어는 있으나 성공은 모릅니다.',
      '친구: 그래도 우리 게임 자금을 거의 3분의 1이나 쓰는 거야!',
    ],
    options: followUp
        ? const [
            DecisionOptionData(
              id: 'acquire_control_followup',
              label: '35만원으로 시나리오 시작',
              description: '비용은 올랐지만 지금 한빛통신 지배 시나리오를 시작합니다.',
              cashCost: 350000,
            ),
            DecisionOptionData(
              id: 'pass_control',
              label: '이번 기회 포기',
              description: '현금을 지키고 경쟁사의 선택을 지켜봅니다.',
            ),
          ]
        : const [
            DecisionOptionData(
              id: 'acquire_control',
              label: '30만원으로 시나리오 시작',
              description: '오늘의 개발용 기준지수에서 한빛통신 가상 세계를 시작합니다.',
              cashCost: 300000,
            ),
            DecisionOptionData(
              id: 'review_control',
              label: '3일 더 검토',
              description: '정보는 늘지만 가격과 경쟁 위험이 커집니다.',
            ),
          ],
  );

  static DecisionCardData _productProposal(int day) => DecisionCardData(
    id: 'product-proposal-$day',
    category: 'CEO 제안',
    title: '전화·음악·인터넷을 하나로 합칠까?',
    proposer: '한빛통신 CEO',
    body:
        '전화, 음악, 인터넷 기능을 하나의 터치 기기에 통합하고 싶습니다. 게임 속 내부 코드명만 표시하며 정답처럼 알려진 결과는 미리 알려주지 않습니다.',
    createdDay: day,
    dueDay: day + 3,
    requestedFunds: 180000,
    benefit: '새 시장 진입 · 기술과 브랜드 성장',
    risk: '배터리 · 생산수율 · 현금 부족',
    advisorOpinions: const [
      'CEO: 작게 시작해도 우리가 먼저 배워야 합니다.',
      '회계사: 전액 투자는 회사 현금을 빠르게 줄입니다.',
      '기술자: 핵심 부품은 준비됐지만 배터리는 불안합니다.',
    ],
    options: const [
      DecisionOptionData(
        id: 'approve_full',
        label: '18만원 전액 투자',
        description: '속도와 팀 사기는 오르지만 실행 위험도 큽니다.',
        cashCost: 180000,
      ),
      DecisionOptionData(
        id: 'approve_prototype',
        label: '7만원 시제품만 승인',
        description: '위험을 줄이고 다음 단계에서 다시 판단합니다.',
        cashCost: 70000,
      ),
      DecisionOptionData(
        id: 'approve_partner',
        label: '5만원 공동개발',
        description: '비용과 위험을 나누지만 주도권도 나눕니다.',
        cashCost: 50000,
      ),
      DecisionOptionData(
        id: 'reject_project',
        label: '제안 거절',
        description: '현금을 지키지만 팀과 기술 기회를 잃을 수 있습니다.',
      ),
    ],
  );

  static DecisionCardData _developmentIssue(int day) => DecisionCardData(
    id: 'development-issue-$day',
    category: '개발 문제',
    title: '시제품이 너무 뜨거워집니다',
    proposer: '기술책임자 미나',
    body: '오래 사용하면 배터리 온도가 안전 기준을 넘습니다. 출시 일정, 기능, 품질을 동시에 지킬 수는 없어요.',
    createdDay: day,
    dueDay: day + 2,
    requestedFunds: 80000,
    benefit: '품질 개선 또는 빠른 일정 유지',
    risk: '지연 · 기능 축소 · 개발비 증가',
    advisorOpinions: const [
      '기술자: 부품을 바꾸면 품질은 좋아지지만 시간이 듭니다.',
      'CEO: 핵심 기능을 줄이면 제품의 매력이 약해집니다.',
      '회계사: 추가 지출 뒤에도 비상금은 남겨야 합니다.',
    ],
    options: const [
      DecisionOptionData(
        id: 'fix_quality',
        label: '8만원 들여 부품 교체',
        description: '품질과 팀 사기는 오르지만 비용이 큽니다.',
        cashCost: 80000,
      ),
      DecisionOptionData(
        id: 'cut_scope',
        label: '2만원으로 기능 축소',
        description: '빠르게 가지만 품질과 시장성이 낮아집니다.',
        cashCost: 20000,
      ),
      DecisionOptionData(
        id: 'delay_development',
        label: '3만5천원 · 일정 연장',
        description: '품질을 보강하지만 경쟁사가 움직일 시간이 생깁니다.',
        cashCost: 35000,
      ),
      DecisionOptionData(
        id: 'cancel_development',
        label: '개발 중단',
        description: '추가 손실을 막지만 조직 충격이 큽니다.',
      ),
    ],
  );

  static DecisionCardData _launchReview(int day, {required bool finalReview}) =>
      DecisionCardData(
        id: '${finalReview ? 'final-' : ''}launch-review-$day',
        category: '출시 심사',
        title: finalReview ? '완성한 기기를 이제 출시할까?' : '새 휴대기기를 지금 팔기 시작할까?',
        proposer: '한빛통신 이사회',
        body: finalReview
            ? '품질 보강은 끝났지만 경쟁사의 소문이 커졌습니다. 이제 출시하거나 접어야 합니다.'
            : '시제품은 작동하지만 수요는 넓은 범위로만 추정됩니다. 지금 출시하면 빠르지만 품질 위험이 남습니다.',
        createdDay: day,
        dueDay: day + 2,
        requestedFunds: finalReview ? 0 : 40000,
        benefit: '첫 매출과 브랜드 기회',
        risk: '실제 성공은 보장되지 않음 · 출시 후 지원비',
        advisorOpinions: const [
          'CEO: 완벽하지 않아도 시장에서 배울 수 있습니다.',
          '기술자: 조금 더 다듬으면 결함 가능성을 낮출 수 있습니다.',
          '회계사: 연기할수록 현금과 선점 기회가 줄어듭니다.',
        ],
        options: finalReview
            ? const [
                DecisionOptionData(
                  id: 'launch_after_delay',
                  label: '보강한 제품 출시',
                  description: '개선된 품질로 시장 반응을 확인합니다.',
                ),
                DecisionOptionData(
                  id: 'cancel_launch',
                  label: '출시 취소',
                  description: '남은 위험을 피하지만 투자금과 기회를 잃습니다.',
                ),
              ]
            : const [
                DecisionOptionData(
                  id: 'launch_now',
                  label: '지금 출시',
                  description: '선점 기회가 크지만 품질 위험도 남습니다.',
                ),
                DecisionOptionData(
                  id: 'delay_launch',
                  label: '4만원 · 3일 연기',
                  description: '품질은 좋아지지만 비용과 경쟁 위험이 생깁니다.',
                  cashCost: 40000,
                ),
                DecisionOptionData(
                  id: 'cancel_launch',
                  label: '출시 취소',
                  description: '추가 위험은 막지만 팀과 브랜드가 흔들립니다.',
                ),
              ],
      );

  static DecisionCardData _endingCard(int day, String message) =>
      DecisionCardData(
        id: 'story-result-$day-${_stableHash(message)}',
        category: '결과 보고',
        title: '선택의 결과가 도착했어요',
        proposer: '시뮬레이션 기록실',
        body: message,
        createdDay: day,
        dueDay: day + 30,
        requestedFunds: 0,
        benefit: '이번 선택의 변화가 저장됩니다.',
        risk: '다음 선택에도 누적 영향을 줍니다.',
        advisorOpinions: const ['기록: 모든 회사명·수치·의견·결과는 게임용 가상 시나리오입니다.'],
        options: const [
          DecisionOptionData(
            id: 'acknowledge',
            label: '결과 확인',
            description: '가상 세계 기록을 닫고 사무실로 돌아갑니다.',
          ),
        ],
      );

  static int _stableHash(String input) {
    var hash = 2166136261;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  static double _noise(String seed, String key, double min, double max) {
    final normalized = _stableHash('$seed:$key') / 0x7fffffff;
    return min + (max - min) * normalized;
  }
}

String _tradeUnits(double units) => units == units.roundToDouble()
    ? units.toInt().toString()
    : units.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '');
