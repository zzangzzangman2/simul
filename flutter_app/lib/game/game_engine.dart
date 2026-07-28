import 'dart:math' as math;

import 'banking_state.dart';
import 'game_state.dart';
import 'market_clock.dart';
import 'market_cost_rules.dart';
import 'market_data.dart';
import 'market_technical_levels.dart';
import 'market_tick.dart';
import 'order_book.dart';
import 'mission_progression.dart';
import 'organization_state.dart';
import 'real_estate_financing.dart';
import 'real_estate_market.dart';
import 'real_estate_rental.dart';
import 'real_estate_world.dart';
import 'personal_finance_state.dart';
import 'seed_money_content.dart';
import 'star_shop.dart';
import 'story_state.dart';

const initialCompanyCash = 10000;
const grandfatherNewYearGiftSourceId = 'grandfather-new-year-gift';
const academyTuitionDebtAmount = 1000000;
const academyTuitionRepaymentSourceId = 'academy-tuition-repayment';
const gameDividendWithholdingTaxRate = 0.154;
const dailyMarketReportPrice = 1200;
const gameRealEstateInvestmentNoteMaxLength = 300;
const _staleDisplayedOrderBookMessage = '시세가 바뀌었습니다. 호가창을 다시 확인해 주세요.';

class GamePendingOrderQuotePath {
  const GamePendingOrderQuotePath({
    required this.prices,
    required this.previousClose,
    required this.isTradingDay,
    this.isIpoFirstTradingDay = false,
    this.technicalLevels = const <MarketTechnicalLevel>[],
  });

  final List<double> prices;
  final double previousClose;
  final bool isTradingDay;
  final bool isIpoFirstTradingDay;
  final List<MarketTechnicalLevel> technicalLevels;
}

double gameTradingFeeMultiplier(GameState state) {
  final helperDiscount =
      state.story.storyFlags['activeResearchHelper'] == 'mother' &&
      state.story.flagInt('activeResearchHelperDay', -1) == state.day;
  final skillDiscount = state.progression.hasSkill('fee_sense') ? 0.9 : 1.0;
  return (helperDiscount ? 0.9 : 1.0) * skillDiscount;
}

int gameTradingFeeForState(GameState state, int notional) {
  if (notional <= 0) return 0;
  final raw =
      notional *
      marketTradingFeeRate(state.currentDate) *
      gameTradingFeeMultiplier(state);
  return math.max(1, raw.round());
}

double gameTradingFeeRateForState(GameState state) =>
    marketTradingFeeRate(state.currentDate) * gameTradingFeeMultiplier(state);

double gameSecuritiesTransactionTaxRate(DateTime date) =>
    marketSecuritiesTransactionTaxRate(date);

int gameSecuritiesTransactionTax(DateTime date, int notional) {
  if (notional <= 0) return 0;
  return math.max(
    1,
    (notional * gameSecuritiesTransactionTaxRate(date)).round(),
  );
}

int gameQualifyingRecurringMonthlyIncome(GameState state) {
  final employeeResearchIncome =
      state.organization.employees.length * 90000 +
      state.personalFinance.monthlyResearchBonusAt(
        state.currentDate.year,
        state.organization.employees.length,
      ) +
      (state.progression.hasSkill('research_habit') ? 20000 : 0);
  final managementFee = state.story.fundLaunched
      ? (state.story.externalAum * 0.0005).round()
      : 0;
  final controlledIncome = state.company.isControlled
      ? (state.company.monthlyRevenue * 0.05).round()
      : 0;
  final recognizedRent =
      (state.personalFinance.monthlyPropertyIncomeAt(state.currentDate) * 0.70)
          .round();
  return math.max(
    0,
    employeeResearchIncome + managementFee + controlledIncome + recognizedRent,
  );
}

int gameRealEstateQualifyingMonthlyIncome(
  GameState state, {
  required int targetMonthlyRent,
}) =>
    gameQualifyingRecurringMonthlyIncome(state) +
    (math.max(0, targetMonthlyRent) * 0.75).round();

DateTime _addCalendarMonthsClamped(DateTime date, int months) {
  final firstOfTargetMonth = DateTime(date.year, date.month + months, 1);
  final firstOfFollowingMonth = DateTime(
    firstOfTargetMonth.year,
    firstOfTargetMonth.month + 1,
    1,
  );
  final lastDayOfTargetMonth = firstOfFollowingMonth
      .subtract(const Duration(days: 1))
      .day;
  return DateTime(
    firstOfTargetMonth.year,
    firstOfTargetMonth.month,
    math.min(date.day, lastDayOfTargetMonth),
  );
}

int _gameDayForDate(GameState state, DateTime date) =>
    date.difference(state.campaignStartDate).inDays + 1;

int _firstBankLoanPaymentDay(GameState state) {
  final earliest = state.currentDate.add(const Duration(days: 30));
  var dueDate = DateTime(earliest.year, earliest.month, 1);
  if (dueDate.isBefore(earliest)) {
    dueDate = DateTime(earliest.year, earliest.month + 1, 1);
  }
  return _gameDayForDate(state, dueDate);
}

int _followingMonthlyPaymentDay(GameState state) => _gameDayForDate(
  state,
  DateTime(state.currentDate.year, state.currentDate.month + 1, 1),
);

enum TradeSide { buy, sell }

enum TradeOrderType { market, limit }

const gameMinimumOrderLiquidity = 5000000;
const gameMaximumOrderLiquidity = 2000000000;

int gameOrderAuthorityLimit(GameState state) {
  final assetBasedLimit = math.max(
    250000,
    ((state.availableBrokerageCash + state.portfolioCost) * 0.25).round(),
  );
  return switch (state.story.accountAuthorityLevel) {
    0 => 0,
    1 => 100000,
    2 => 250000,
    3 => assetBasedLimit,
    4 => math.max(5000000, assetBasedLimit),
    _ => gameMaximumOrderLiquidity,
  };
}

int gameMarketOrderNotionalLimit(double unitPrice, {double? turnoverEok}) {
  if (!unitPrice.isFinite || unitPrice <= 0) return 0;
  // Legacy callers without a snapshot retain only the global safety ceiling.
  // Actual fills always pass the snapshot turnover and are depth-limited.
  if (turnoverEok == null) return gameMaximumOrderLiquidity;
  return gameOrderBookNotionalLimitForTurnover(
    turnoverEok: turnoverEok,
    minimum: gameMinimumOrderLiquidity,
    maximum: gameMaximumOrderLiquidity,
  );
}

int gameBuyNotionalBudget(GameState state, {required int maximumNotional}) {
  if (maximumNotional <= 0 ||
      state.availableBrokerageCash <= 0 ||
      state.story.accountAuthorityLevel == 0) {
    return 0;
  }
  var low = 0;
  var high = math.min(maximumNotional, state.availableBrokerageCash);
  while (low < high) {
    final middle = (low + high + 1) ~/ 2;
    if (middle + gameTradingFeeForState(state, middle) <=
        state.availableBrokerageCash) {
      low = middle;
    } else {
      high = middle - 1;
    }
  }
  return low;
}

int gameMaxBuyQuantity(
  GameState state,
  double unitPrice, {
  String market = '미래시장',
}) {
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
    final fee = gameTradingFeeForState(state, rawNotional);
    if (rawNotional <= rawLimit &&
        rawNotional + fee <= state.availableBrokerageCash) {
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
  double previousClose = 0,
  String simulationSeed = '',
}) {
  return gameOrderBookExecutionCapacity(
    assetId: assetId,
    day: day,
    minute: minute,
    unitPrice: unitPrice,
    previousClose: previousClose,
    simulationSeed: simulationSeed,
  );
}

/// [side] is retained for source compatibility. Minute execution capacity is
/// shared by both directions, so the returned quantity is always the combined
/// buy-and-sell consumption.
int gameConsumedOrderBookFillUnits(
  GameState state, {
  required String assetId,
  required int marketMinute,
  required TradeSide side,
}) => state.ledger
    .where((entry) {
      return entry.day == state.day &&
          entry.assetId == assetId &&
          entry.marketMinute == marketMinute;
    })
    .fold<int>(0, (sum, entry) {
      if (entry.orderBookCapacityUnits > 0) {
        return sum + entry.orderBookCapacityUnits;
      }
      final isTrade =
          entry.tradeSide == TradeSide.buy.name ||
          entry.tradeSide == TradeSide.sell.name;
      if (!isTrade ||
          !entry.tradeQuantity.isFinite ||
          entry.tradeQuantity <= 0) {
        return sum;
      }
      return sum + entry.tradeQuantity.ceil();
    });

/// Continuous-session depth already consumed at each absolute price.
///
/// Buy aggressors consume asks and sell aggressors consume bids. Entries
/// without a book side (auctions and legacy saves) do not reduce either
/// visible side, while their capacity units still count toward the
/// minute-wide shared execution budget.
Map<double, double> gameConsumedOrderBookUnitsByPrice(
  GameState state, {
  required String assetId,
  required int marketMinute,
  required GameOrderBookSide bookSide,
}) {
  final consumed = <double, double>{};
  for (final entry in state.ledger) {
    if (entry.day != state.day ||
        entry.assetId != assetId ||
        entry.marketMinute != marketMinute ||
        entry.orderBookSide != bookSide.name) {
      continue;
    }
    for (final fill in entry.orderBookFills) {
      if (!fill.price.isFinite ||
          fill.price <= 0 ||
          !fill.quantity.isFinite ||
          fill.quantity <= 0) {
        continue;
      }
      consumed.update(
        fill.price,
        (quantity) => quantity + fill.quantity,
        ifAbsent: () => fill.quantity,
      );
    }
  }
  return Map<double, double>.unmodifiable(consumed);
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
    this.previousTradePrice,
    this.sessionLow,
    this.sessionHigh,
    this.isLimitFill = false,
    this.isClosingAuctionFill = false,
    this.maximumPositionUnits,
    this.isIpoFirstTradingDay = false,
    this.technicalLevels = const <MarketTechnicalLevel>[],
    this.microstructureFrame = 0,
    this.displayedSnapshot,
    this.orderBookSide,
    this.orderBookFills = const <LedgerOrderBookFill>[],
    this.orderBookCapacityUnits = 0,
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
  final double? previousTradePrice;
  final double? sessionLow;
  final double? sessionHigh;

  /// 구 호출부 호환용 입력이다. 공개 체결 API는 이 값을 신뢰하지 않는다.
  final bool isLimitFill;

  /// 구 호출부 호환용 입력이다. 종가 체결 여부는 엔진 내부에서만 지정한다.
  final bool isClosingAuctionFill;
  final int? maximumPositionUnits;
  final bool isIpoFirstTradingDay;
  final List<MarketTechnicalLevel> technicalLevels;
  final int microstructureFrame;

  /// Exact local book shown when this immediate order was submitted.
  ///
  /// This object is intentionally not serialized. Pending-order replay uses
  /// its deterministic quote path, while immediate fills must consume the
  /// exact carried quantities the player saw. Callers must pass the net view
  /// returned by [gameOrderBookSnapshotAfterConsumption]; the engine only
  /// applies historical price consumption to snapshots it builds itself.
  final GameOrderBookSnapshot? displayedSnapshot;
  final GameOrderBookSide? orderBookSide;
  final List<LedgerOrderBookFill> orderBookFills;
  final int orderBookCapacityUnits;
}

List<LedgerOrderBookFill> _ledgerOrderBookFills(GameOrderBookFillPlan plan) =>
    List<LedgerOrderBookFill>.unmodifiable(
      plan.fills.map(
        (fill) => LedgerOrderBookFill(
          price: fill.price,
          quantity: fill.quantity.toDouble(),
        ),
      ),
    );

double _orderBookConsumedAtPrice(
  Map<double, double> consumedByPrice,
  double price,
) {
  final exact = consumedByPrice[price];
  if (exact != null) return exact;
  for (final entry in consumedByPrice.entries) {
    if ((entry.key - price).abs() < 0.000001) return entry.value;
  }
  return 0;
}

bool _orderBookConsumptionMapsMatch(
  Map<double, double> snapshotWatermark,
  Map<double, double> currentConsumption,
) {
  bool matchesEntries(Map<double, double> left, Map<double, double> right) {
    for (final entry in left.entries) {
      if (!entry.key.isFinite ||
          entry.key <= 0 ||
          !entry.value.isFinite ||
          entry.value <= 0) {
        continue;
      }
      if ((_orderBookConsumedAtPrice(right, entry.key) - entry.value).abs() >
          0.000001) {
        return false;
      }
    }
    return true;
  }

  return matchesEntries(snapshotWatermark, currentConsumption) &&
      matchesEntries(currentConsumption, snapshotWatermark);
}

class TradeExecutionResult {
  const TradeExecutionResult({
    required this.state,
    required this.success,
    required this.message,
    this.notional = 0,
    this.fee = 0,
    this.transactionTax = 0,
    this.realizedPnl = 0,
    this.orderId,
    this.filledQuantity = 0,
    this.pendingQuantity = 0,
    this.averageFillPrice = 0,
  });

  final GameState state;
  final bool success;
  final String message;
  final int notional;
  final int fee;
  final int transactionTax;
  final int realizedPnl;
  final String? orderId;
  final double filledQuantity;
  final double pendingQuantity;
  final double averageFillPrice;
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

class _RentalMonthPreparation {
  const _RentalMonthPreparation({
    required this.assets,
    required this.expiringAssetIds,
    required this.rentalIncome,
    required this.operatingCost,
    required this.repairCost,
    required this.insurancePremium,
    required this.entries,
  });

  final List<OwnedRealEstate> assets;
  final Set<String> expiringAssetIds;
  final int rentalIncome;
  final int operatingCost;
  final int repairCost;
  final int insurancePremium;
  final List<LedgerEntry> entries;
}

class _RealEstateDispositionPlan {
  const _RealEstateDispositionPlan({
    required this.grossMarketValue,
    required this.dispositionPrice,
    required this.saleCosts,
    required this.waterfall,
  });

  final int grossMarketValue;
  final int dispositionPrice;
  final int saleCosts;
  final RealEstateDispositionWaterfall waterfall;
}

_RealEstateDispositionPlan _realEstateDispositionPlan({
  required GameState state,
  required OwnedRealEstate asset,
  int? voluntaryNetSaleBeforeTax,
  RealEstateForcedDispositionKind? forcedKind,
  int tenantDepositDue = 0,
}) {
  assert((voluntaryNetSaleBeforeTax != null) != (forcedKind != null));
  final grossMarketValue = asset.estimatedMarketValue(state.day);
  late final int dispositionPrice;
  late final int saleCosts;
  late final int netSaleBeforeTax;
  if (forcedKind != null) {
    dispositionPrice =
        (grossMarketValue * realEstateForcedDispositionRate(forcedKind))
            .round();
    saleCosts = asset.estimatedSaleCostsForPrice(state.day, dispositionPrice);
    netSaleBeforeTax = math.max(0, dispositionPrice - saleCosts);
  } else {
    netSaleBeforeTax = math.max(0, voluntaryNetSaleBeforeTax!);
    saleCosts = asset.estimatedSaleCostsForPrice(state.day, grossMarketValue);
    dispositionPrice = netSaleBeforeTax + saleCosts;
  }
  return _RealEstateDispositionPlan(
    grossMarketValue: grossMarketValue,
    dispositionPrice: dispositionPrice,
    saleCosts: saleCosts,
    waterfall: realEstateDispositionWaterfall(
      saleDate: state.currentDate,
      type: asset.assetType,
      ownedHousingCount: state.personalFinance.ownedHousingCount,
      holdingDays: state.day - asset.acquiredDay,
      netSaleBeforeTax: netSaleBeforeTax,
      purchaseCost: asset.purchasePrice,
      mortgageBalance: asset.mortgageBalance,
      tenantDepositDue: tenantDepositDue,
    ),
  );
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
    this.starReward = 0,
    this.experienceReward = 0,
    this.reputationReward = 0,
    this.trustReward = 0,
    this.unlockedSkill,
  });

  final GameState state;
  final bool success;
  final String message;
  final int starReward;
  final int experienceReward;
  final int reputationReward;
  final int trustReward;
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
      banking: BankingState.initial(),
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
    const starReward = 1;
    final nextExperience =
        state.progression.experience + progress.mission.experienceReward;
    final flags = <String, dynamic>{
      ...state.story.storyFlags,
      'reputation': (state.story.reputation + progress.mission.reputationReward)
          .clamp(0, 100),
    };
    var rewarded = state.copyWith(
      story: state.story.copyWith(
        familyTrust: state.story.familyTrust + progress.mission.trustReward,
        storyFlags: flags,
      ),
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
        starBalance: state.progression.starBalance + starReward,
        totalStarsEarned: state.progression.totalStarsEarned + starReward,
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
    final rewardMessages = <String>[
      '⭐ +$starReward',
      '+${progress.mission.experienceReward} XP',
      if (progress.mission.reputationReward > 0)
        '평판 +${progress.mission.reputationReward}',
      if (progress.mission.trustReward > 0)
        '가족 신뢰 +${progress.mission.trustReward}',
      if (unlockedSkill != null) 'LV.$afterLevel ${unlockedSkill.name} 해금',
    ];
    return MissionClaimResult(
      state: rewarded,
      success: true,
      message: '${progress.mission.title} 완료! ${rewardMessages.join(' · ')}',
      starReward: starReward,
      experienceReward: progress.mission.experienceReward,
      reputationReward: progress.mission.reputationReward,
      trustReward: progress.mission.trustReward,
      unlockedSkill: unlockedSkill,
    );
  }

  StarShopPurchaseResult purchaseStarShopItem(
    GameState state,
    String productId,
  ) {
    final product = starShopProductForId(productId);
    if (product == null) {
      return StarShopPurchaseResult(
        state: state,
        success: false,
        message: '존재하지 않는 별빛 상점 상품입니다.',
      );
    }
    final cost = starShopCost(state, product);
    if (state.progression.starBalance < cost) {
      return StarShopPurchaseResult(
        state: state,
        success: false,
        message:
            '스타가 부족합니다. 미션을 완료해 ⭐${cost - state.progression.starBalance}개를 더 모아 주세요.',
      );
    }

    if (product.id == starCashExchangeId) {
      final purchaseId =
          'star-cash-${state.day}-${state.progression.starPurchaseIds.length + 1}';
      final progression = state.progression.copyWith(
        starBalance: state.progression.starBalance - cost,
        starPurchaseIds: <String>[
          ...state.progression.starPurchaseIds,
          purchaseId,
        ],
      );
      final next = state.copyWith(
        cash: state.cash + 10000,
        progression: progression,
        ledger: <LedgerEntry>[
          ...state.ledger,
          LedgerEntry(
            id: purchaseId,
            day: state.day,
            amount: 10000,
            account: 'company_bank',
            counterAccount: 'star_exchange',
            description: '별빛 상점 회사 지원금',
            sourceId: purchaseId,
          ),
        ],
      );
      return StarShopPurchaseResult(
        state: next,
        success: true,
        message: '⭐$cost개를 사용해 회사 은행 계좌로 10,000원을 받았습니다.',
        purchaseKey: purchaseId,
      );
    }

    final targetDate = nextStarShopTradingDate(state.currentDate);
    final purchaseKey = starShopInformationPurchaseKey(product.id, targetDate);
    final savedHint = state.progression.starHints[purchaseKey];
    if (savedHint != null ||
        state.progression.starPurchaseIds.contains(purchaseKey)) {
      return StarShopPurchaseResult(
        state: state,
        success: false,
        message: '이 상품의 ${marketDateKey(targetDate)} 힌트는 이미 구매했습니다.',
        hint: savedHint,
        purchaseKey: purchaseKey,
      );
    }
    final hint = buildStarShopHint(state, product, targetDate);
    final next = state.copyWith(
      progression: state.progression.copyWith(
        starBalance: state.progression.starBalance - cost,
        starPurchaseIds: <String>[
          ...state.progression.starPurchaseIds,
          purchaseKey,
        ],
        starHints: <String, String>{
          ...state.progression.starHints,
          purchaseKey: hint,
        },
      ),
    );
    return StarShopPurchaseResult(
      state: next,
      success: true,
      message: '⭐$cost개로 ${product.title}을 구매했습니다.',
      hint: hint,
      purchaseKey: purchaseKey,
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
      'net_worth' => state.balanceSheetNetWorth(),
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

  BankLoanOffer unsecuredLoanOffer(GameState state, {required int termMonths}) {
    final banking = state.banking;
    final hasCreditBlockingDebt =
        banking.hasDelinquentLoan ||
        state.story.flagInt('mortgageDeficiencyDebt') > 0 ||
        state.story.flagInt('tenantDepositDebt') > 0 ||
        state.personalFinance.realEstate.any(
          (asset) => asset.mortgageMissedPayments > 0,
        );
    return assessUnsecuredLoanOffer(
      date: state.currentDate,
      creditScore: banking.creditScore,
      qualifyingMonthlyIncome: gameQualifyingRecurringMonthlyIncome(state),
      existingUnsecuredBalance: banking.totalUnsecuredLoanBalance,
      existingMonthlyDebtService:
          banking.monthlyUnsecuredDebtService +
          state.personalFinance.monthlyMortgagePayment,
      termMonths: termMonths,
      isAdult: state.story.ageOn(state.currentDate) >= 20,
      hasDelinquency: hasCreditBlockingDebt,
    );
  }

  FinanceActionResult openTimeDeposit(
    GameState state, {
    required int amount,
    required int termMonths,
  }) {
    FinanceActionResult reject(String message) =>
        FinanceActionResult(state: state, success: false, message: message);
    if (amount <= 0) return reject('예금액은 0원보다 커야 합니다.');
    if (!bankDepositTermMonths.contains(termMonths)) {
      return reject('예금 기간은 6개월, 12개월, 24개월 중에서 선택해야 합니다.');
    }
    if (amount > state.bankCash) return reject('회사 통장 잔액이 부족합니다.');
    final maturityDate = _addCalendarMonthsClamped(
      state.currentDate,
      termMonths,
    );
    final maturityDay = _gameDayForDate(state, maturityDate);
    if (maturityDay > GameState.maxCampaignDay) {
      return reject('캠페인 종료일 전에 만기가 오는 상품만 가입할 수 있습니다.');
    }
    final sequence = state.banking.nextContractSequence;
    final id = 'bank-deposit-${state.day}-$sequence';
    final annualRate = bankTermDepositAnnualRateAt(
      state.currentDate,
      termMonths,
      cashManagementSkill: state.progression.hasSkill('cash_management'),
    );
    final deposit = BankTermDeposit(
      id: id,
      principal: amount,
      annualInterestRate: annualRate,
      openedDay: state.day,
      maturityDay: maturityDay,
      termMonths: termMonths,
    );
    final sourceId = 'open-$id';
    final next = state.copyWith(
      cash: state.cash - amount,
      banking: state.banking.copyWith(
        nextContractSequence: sequence + 1,
        termDeposits: [...state.banking.termDeposits, deposit],
      ),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -amount,
          notional: amount,
          account: 'company_bank',
          counterAccount: 'bank_time_deposit',
          description:
              '$termMonths개월 정기예금 가입 · 연 ${(annualRate * 100).toStringAsFixed(2)}%',
          sourceId: sourceId,
        ),
      ],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      cashDelta: -amount,
      message:
          '$amount원을 $termMonths개월 정기예금에 넣었습니다. '
          '연 ${(annualRate * 100).toStringAsFixed(2)}% 고정금리입니다.',
    );
  }

  FinanceActionResult redeemTimeDeposit(GameState state, String depositId) {
    FinanceActionResult reject(String message) =>
        FinanceActionResult(state: state, success: false, message: message);
    final matches = state.banking.termDeposits
        .where((deposit) => deposit.id == depositId)
        .toList(growable: false);
    if (matches.isEmpty) return reject('해지할 정기예금을 찾지 못했습니다.');
    final deposit = matches.single;
    final matured = deposit.maturedAt(state.day);
    final payout = deposit.redemptionAmountAt(state.day);
    final interest = payout - deposit.principal;
    final sourceId =
        'bank-deposit-${matured ? 'maturity' : 'early'}-${deposit.id}';
    final next = state.copyWith(
      cash: state.cash + payout,
      banking: state.banking.copyWith(
        termDeposits: state.banking.termDeposits
            .where((item) => item.id != deposit.id)
            .toList(growable: false),
      ),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: payout,
          notional: deposit.principal,
          disposedCost: deposit.principal,
          realizedPnl: interest,
          account: 'company_bank',
          counterAccount: 'bank_time_deposit',
          description: matured
              ? '정기예금 만기 · 세후이자 $interest원'
              : '정기예금 중도해지 · 세후이자 $interest원',
          sourceId: sourceId,
        ),
      ],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      cashDelta: payout,
      message: matured
          ? '정기예금 만기로 원리금 $payout원을 받았습니다.'
          : '정기예금을 중도해지해 $payout원을 받았습니다.',
    );
  }

  FinanceActionResult takeUnsecuredLoan(
    GameState state, {
    required int amount,
    required int termMonths,
  }) {
    FinanceActionResult reject(String message) =>
        FinanceActionResult(state: state, success: false, message: message);
    if (amount <= 0) return reject('대출 신청액은 0원보다 커야 합니다.');
    final offer = unsecuredLoanOffer(state, termMonths: termMonths);
    if (!offer.eligible) return reject('대출 심사 거절: ${offer.reason}');
    if (amount > offer.maximumPrincipal) {
      return reject('현재 신용·DSR 기준 대출한도는 ${offer.maximumPrincipal}원입니다.');
    }
    final sequence = state.banking.nextContractSequence;
    final id = 'bank-loan-${state.day}-$sequence';
    final loan = BankUnsecuredLoan(
      id: id,
      originalPrincipal: amount,
      balance: amount,
      annualInterestRate: offer.annualInterestRate,
      termMonths: termMonths,
      remainingMonths: termMonths,
      scheduledMonthlyPayment: offer.monthlyPaymentFor(amount),
      nextPaymentDay: _firstBankLoanPaymentDay(state),
      consecutiveMissedPayments: 0,
      totalMissedPayments: 0,
    );
    final sourceId = 'open-$id';
    final next = state.copyWith(
      cash: state.cash + amount,
      banking: state.banking.copyWith(
        nextContractSequence: sequence + 1,
        unsecuredLoans: [...state.banking.unsecuredLoans, loan],
      ),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: amount,
          notional: amount,
          account: 'company_bank',
          counterAccount: 'bank_unsecured_loan',
          description:
              '신용대출 실행 · $termMonths개월 · 연 ${(offer.annualInterestRate * 100).toStringAsFixed(2)}%',
          sourceId: sourceId,
        ),
      ],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      cashDelta: amount,
      message:
          '$amount원 신용대출이 실행됐습니다. '
          '월 원리금 ${loan.scheduledMonthlyPayment}원입니다.',
    );
  }

  FinanceActionResult repayUnsecuredLoan(
    GameState state, {
    required String loanId,
    required int amount,
  }) {
    FinanceActionResult reject(String message) =>
        FinanceActionResult(state: state, success: false, message: message);
    final matches = state.banking.unsecuredLoans
        .where((loan) => loan.id == loanId)
        .toList(growable: false);
    if (matches.isEmpty) return reject('상환할 신용대출을 찾지 못했습니다.');
    if (amount <= 0) return reject('상환액은 0원보다 커야 합니다.');
    final loan = matches.single;
    if (amount > loan.balance) return reject('남은 대출잔액보다 많이 상환할 수 없습니다.');
    if (amount > state.bankCash) return reject('회사 통장 잔액이 부족합니다.');
    final updated = loan.repayPrincipal(amount);
    final paidOff = updated.balance == 0;
    final earnedPayoffCredit =
        paidOff &&
        loan.remainingMonths < loan.termMonths &&
        loan.totalMissedPayments == 0;
    final loans = <BankUnsecuredLoan>[
      for (final item in state.banking.unsecuredLoans)
        if (item.id != loan.id) item else if (!paidOff) updated,
    ];
    final sourceId =
        'bank-loan-repayment-${loan.id}-${state.day}-${loan.balance}';
    final next = state.copyWith(
      cash: state.cash - amount,
      banking: state.banking.copyWith(
        creditScore: state.banking.creditScore + (earnedPayoffCredit ? 5 : 0),
        unsecuredLoans: loans,
      ),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -amount,
          notional: amount,
          account: 'company_bank',
          counterAccount: 'bank_unsecured_loan',
          description: paidOff ? '신용대출 전액 상환' : '신용대출 일부 상환',
          sourceId: sourceId,
        ),
      ],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      cashDelta: -amount,
      message: earnedPayoffCredit
          ? '정상 납부 이력이 있는 신용대출을 모두 갚아 신용점수가 5점 올랐습니다.'
          : paidOff
          ? '신용대출을 모두 갚았습니다.'
          : '$amount원을 상환했습니다. 남은 잔액은 ${updated.balance}원입니다.',
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
    final available = deposit
        ? state.bankCash
        : state.withdrawableBrokerageCash;
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

  FinanceActionResult repayAcademyTuitionDebt(GameState state) {
    FinanceActionResult reject(String message) =>
        FinanceActionResult(state: state, success: false, message: message);
    final debt = state.story.academyTuitionDebt;
    if (debt <= 0) return reject('아빠에게 빌린 학원비는 이미 모두 갚았습니다.');
    if (state.processedEventIds.contains(academyTuitionRepaymentSourceId)) {
      return reject('학원비 상환 기록이 이미 처리되었습니다.');
    }
    if (state.bankCash < debt) {
      return reject('회사 통장 잔액이 ${debt - state.bankCash}원 부족합니다.');
    }

    final flags = Map<String, dynamic>.from(state.story.storyFlags)
      ..['academyTuitionDebt'] = 0
      ..['academyTuitionRepaidDay'] = state.day;
    final next = state.copyWith(
      cash: state.cash - debt,
      story: state.story.copyWith(
        fatherAffinity: state.story.fatherAffinity + 3,
        familyTrust: state.story.familyTrust + 2,
        storyFlags: flags,
      ),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: academyTuitionRepaymentSourceId,
          day: state.day,
          amount: -debt,
          account: 'company_bank',
          counterAccount: 'family_debt_repayment',
          description: '아빠 선납 주식학원비 상환',
          sourceId: academyTuitionRepaymentSourceId,
        ),
      ],
      processedEventIds: [
        ...state.processedEventIds,
        academyTuitionRepaymentSourceId,
      ],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      message: '아빠에게 학원비 1,000,000원을 모두 갚았습니다.',
      cashDelta: -debt,
    );
  }

  bool _wouldExceedIssuedShares(
    GameState state,
    TradeOrder order, {
    required bool includePendingBuys,
  }) {
    final maximum = order.maximumPositionUnits;
    if (order.side != TradeSide.buy || maximum == null) return false;
    if (maximum <= 0) return true;
    final owned = state.positions
        .where((position) => position.assetId == order.assetId)
        .fold<double>(0, (sum, position) => sum + position.units);
    final reserved = includePendingBuys
        ? state.pendingBuyReservedUnits(order.assetId)
        : 0.0;
    return owned + reserved + order.quantity > maximum + 0.000001;
  }

  bool _displayedOrderBookSnapshotMatchesOrder(
    GameState state,
    TradeOrder order,
  ) {
    final snapshot = order.displayedSnapshot;
    if (snapshot == null) return true;

    final sourcePrice = snapshot.sourceLastTradePrice;
    if (snapshot.sourceAssetId == null ||
        snapshot.sourceLiquidityDayKey == null ||
        snapshot.sourceDateKey == null ||
        snapshot.sourceMarketMinute == null ||
        sourcePrice == null ||
        !sourcePrice.isFinite ||
        snapshot.sourceMarket == null ||
        snapshot.sourceSimulationSeed == null) {
      return false;
    }

    final stateDateKey = marketDateKey(state.currentDate);
    final reference = order.previousClose.isFinite && order.previousClose > 0
        ? order.previousClose
        : order.unitPrice;
    final range = marketDailyPriceRange(
      previousClose: reference,
      date: state.currentDate,
      market: order.market,
      isIpoFirstTradingDay: order.isIpoFirstTradingDay,
    );
    final expectedLastTradePrice = marketSnapPrice(
      order.unitPrice.clamp(range.lower, range.upper).toDouble(),
      market: order.market,
    );
    final currentAskConsumption = gameConsumedOrderBookUnitsByPrice(
      state,
      assetId: order.assetId,
      marketMinute: order.marketMinute,
      bookSide: GameOrderBookSide.ask,
    );
    final currentBidConsumption = gameConsumedOrderBookUnitsByPrice(
      state,
      assetId: order.assetId,
      marketMinute: order.marketMinute,
      bookSide: GameOrderBookSide.bid,
    );
    final currentCapacityConsumption = gameConsumedOrderBookFillUnits(
      state,
      assetId: order.assetId,
      marketMinute: order.marketMinute,
      side: order.side,
    );
    return snapshot.sourceAssetId == order.assetId &&
        snapshot.sourceLiquidityDayKey ==
            marketLiquidityDayKey(state.currentDate) &&
        snapshot.sourceDateKey == stateDateKey &&
        snapshot.sourceDateKey == order.quoteDate &&
        snapshot.sourceMarketMinute == state.marketMinute &&
        snapshot.sourceMarketMinute == order.marketMinute &&
        (sourcePrice - expectedLastTradePrice).abs() < 0.000001 &&
        snapshot.sourceMarket == order.market &&
        snapshot.sourceSimulationSeed == state.simulationSeed &&
        snapshot.liquidityPulse == order.microstructureFrame &&
        snapshot.appliedCapacityConsumptionUnits ==
            currentCapacityConsumption &&
        _orderBookConsumptionMapsMatch(
          snapshot.appliedAskConsumptionByPrice,
          currentAskConsumption,
        ) &&
        _orderBookConsumptionMapsMatch(
          snapshot.appliedBidConsumptionByPrice,
          currentBidConsumption,
        );
  }

  TradeExecutionResult _placeLimitOrder(
    GameState state,
    TradeOrder order, {
    bool allowFractionalSellLiquidation = false,
  }) {
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
        (order.quantity != order.quantity.roundToDouble() &&
            !(allowFractionalSellLiquidation &&
                order.side == TradeSide.sell))) {
      return reject('주문 수량은 1주 단위로 입력해 주세요.');
    }
    if (!order.unitPrice.isFinite || order.unitPrice <= 0) {
      return reject('유효한 현재가가 없습니다.');
    }
    if (!_displayedOrderBookSnapshotMatchesOrder(state, order)) {
      return reject(_staleDisplayedOrderBookMessage);
    }
    if (_wouldExceedIssuedShares(state, order, includePendingBuys: true)) {
      return reject('보유·미체결 수량을 합쳐 발행주식 수를 넘길 수 없습니다.');
    }
    final stateDate = marketDateKey(state.currentDate);
    if (order.quoteDate != stateDate) {
      return reject('시세 날짜가 바뀌었습니다. 주문창을 다시 확인해 주세요.');
    }
    if (order.currency != 'KRW') {
      return reject('해외 종목은 실제 환율 원장과 연결한 뒤 거래할 수 있습니다.');
    }
    if (order.marketMinute != state.marketMinute) {
      return reject('시세 시간이 바뀌었습니다. 주문창을 다시 확인해 주세요.');
    }
    final clock = marketClockAt(
      order.marketMinute,
      tradingDay: order.isTradingDay && isMarketTradingDay(state.currentDate),
    );
    if (!clock.tradable) return reject('현재는 주문 가능한 거래 시간이 아닙니다.');
    if (marketDynamicVolatilityInterruptionActive(
      minute: order.marketMinute,
      previousTradePrice: order.previousTradePrice ?? order.unitPrice,
      currentPrice: order.unitPrice,
      tradingDay: order.isTradingDay && isMarketTradingDay(state.currentDate),
    )) {
      return reject('변동성완화장치(VI) 발동 중입니다. 다음 분 단일가 해제 후 주문해 주세요.');
    }
    if (marketMaterialNewsTradingHaltAt(
          simulationSeed: state.simulationSeed,
          date: state.currentDate,
          assetId: order.assetId,
          minute: order.marketMinute,
        ) !=
        null) {
      return reject('중대 공시로 거래정지 중입니다. 공시 후 5분 뒤 재개됩니다.');
    }

    final reference = order.previousClose > 0
        ? order.previousClose
        : order.unitPrice;
    final range = marketDailyPriceRange(
      previousClose: reference,
      date: state.currentDate,
      market: order.market,
      isIpoFirstTradingDay: order.isIpoFirstTradingDay,
    );
    if (limitPrice < range.lower || limitPrice > range.upper) {
      return reject(
        '지정가는 오늘 가격제한폭 '
        '${range.lower.round()}~${range.upper.round()}원 안에서만 낼 수 있습니다.',
      );
    }

    final limitNotionalValue = limitPrice * order.quantity;
    if (!limitNotionalValue.isFinite || limitNotionalValue <= 0) {
      return reject('주문 금액이 올바르지 않습니다.');
    }
    final limitNotional = limitNotionalValue.round();
    if (order.side == TradeSide.buy) {
      final authorityLimit = gameOrderAuthorityLimit(state);
      if (state.story.accountAuthorityLevel == 0) {
        return reject('첫 주문 권한을 먼저 열어야 합니다.');
      }
      if (limitNotional > authorityLimit) {
        return reject('현재 계좌 권한의 1회 주문 한도는 $authorityLimit원입니다.');
      }
      final reservation =
          (limitNotional * (1 + gameTradingFeeRateForState(state))).ceil();
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
      if (allowFractionalSellLiquidation &&
          order.quantity != order.quantity.roundToDouble() &&
          (available - order.quantity).abs() > 0.000001) {
        return reject('Fractional legacy positions must be sold in full.');
      }
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
    final snapshot =
        order.displayedSnapshot ??
        buildGameOrderBookSnapshot(
          assetId: order.assetId,
          day: marketLiquidityDayKey(state.currentDate),
          minute: order.marketMinute,
          currentPrice: order.unitPrice,
          previousClose: reference,
          previousTradePrice: order.previousTradePrice,
          sessionLow: order.sessionLow,
          sessionHigh: order.sessionHigh,
          date: state.currentDate,
          market: order.market,
          simulationSeed: state.simulationSeed,
          tradingDay: order.isTradingDay,
          sharesOutstanding: order.maximumPositionUnits,
          isIpoFirstTradingDay: order.isIpoFirstTradingDay,
          technicalLevels: order.technicalLevels,
          liquidityPulse: order.microstructureFrame,
          adaptiveLiquidityPulses: order.microstructureFrame > 0,
        );
    final consumed = gameConsumedOrderBookFillUnits(
      state,
      assetId: order.assetId,
      marketMinute: order.marketMinute,
      side: order.side,
    );
    final availableCapacity = math.max(
      0,
      snapshot.executionCapacity - consumed,
    );
    final consumedByPrice = gameConsumedOrderBookUnitsByPrice(
      state,
      assetId: order.assetId,
      marketMinute: order.marketMinute,
      bookSide: order.side == TradeSide.buy
          ? GameOrderBookSide.ask
          : GameOrderBookSide.bid,
    );
    final planConsumedByPrice = order.displayedSnapshot == null
        ? consumedByPrice
        : const <double, double>{};
    final plan = gameOrderBookLimitFillPlan(
      snapshot: snapshot,
      isBuy: order.side == TradeSide.buy,
      requestedQuantity: order.quantity,
      limitPrice: limitPrice,
      availableCapacity: clock.phase == MarketSessionPhase.closingAuction
          ? 0
          : availableCapacity,
      maximumNotional: gameMarketOrderNotionalLimit(
        order.unitPrice,
        turnoverEok: snapshot.turnoverEok,
      ),
      alreadyConsumedByPrice: planConsumedByPrice,
    );
    final fillQuantity = plan.filledQuantity.toDouble();
    var nextState = state;
    var filledNotional = 0;
    var filledFee = 0;
    var filledTransactionTax = 0;
    var realizedPnl = 0;
    if (plan.hasFill) {
      final fill = _executeFilledTrade(
        state,
        TradeOrder(
          side: order.side,
          assetId: order.assetId,
          symbol: order.symbol,
          name: order.name,
          market: order.market,
          currency: order.currency,
          quantity: fillQuantity,
          unitPrice: plan.averagePrice,
          quoteDate: order.quoteDate,
          marketMinute: order.marketMinute,
          isTradingDay: order.isTradingDay,
          type: TradeOrderType.limit,
          limitPrice: limitPrice,
          previousClose: order.previousClose,
          maximumPositionUnits: order.maximumPositionUnits,
          isIpoFirstTradingDay: order.isIpoFirstTradingDay,
          orderBookSide: plan.levelSide,
          orderBookFills: _ledgerOrderBookFills(plan),
          orderBookCapacityUnits: plan.filledQuantity,
        ),
      );
      if (!fill.success) return fill;
      nextState = fill.state;
      filledNotional = fill.notional;
      filledFee = fill.fee;
      filledTransactionTax = fill.transactionTax;
      realizedPnl = fill.realizedPnl;
    }

    final remaining = order.quantity - fillQuantity;
    if (remaining > 0.000001) {
      final samePriceOrders = nextState.pendingOrders
          .where(
            (pending) =>
                pending.assetId == order.assetId &&
                pending.side ==
                    (order.side == TradeSide.buy
                        ? PendingOrderSide.buy
                        : PendingOrderSide.sell) &&
                (pending.limitPrice - limitPrice).abs() < 0.000001,
          )
          .toList(growable: false);
      final queueAhead = plan.hasFill
          ? 0.0
          : gameOrderBookQueueAhead(
                  snapshot: snapshot,
                  isBuy: order.side == TradeSide.buy,
                  limitPrice: limitPrice,
                ) +
                samePriceOrders.fold<double>(
                  0,
                  (sum, pending) => sum + pending.remainingQuantity,
                );
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
            queueAheadQuantity: queueAhead,
            maximumPositionUnits: order.maximumPositionUnits,
            isIpoFirstTradingDay: order.isIpoFirstTradingDay,
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
      transactionTax: filledTransactionTax,
      realizedPnl: realizedPnl,
      orderId: remaining > 0.000001 ? orderId : null,
      filledQuantity: fillQuantity,
      pendingQuantity: remaining,
      averageFillPrice: plan.averagePrice,
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
    double previousClose = 0,
    double? previousTradePrice,
    double? sessionLow,
    double? sessionHigh,
    bool? isIpoFirstTradingDay,
    Iterable<MarketTechnicalLevel> technicalLevels =
        const <MarketTechnicalLevel>[],
  }) {
    if (marketMinute < state.marketMinute) {
      throw ArgumentError.value(
        marketMinute,
        'marketMinute',
        'Pending orders cannot be processed backwards in time.',
      );
    }
    final stateDate = marketDateKey(state.currentDate);
    final eligibleOrders = state.pendingOrders
        .where(
          (order) =>
              order.assetId == assetId &&
              order.placedDate == stateDate &&
              order.placedMinute <= marketMinute,
        )
        .toList(growable: false);
    if (eligibleOrders.isEmpty) {
      return state;
    }
    final clock = marketClockAt(
      marketMinute,
      tradingDay: isTradingDay && isMarketTradingDay(state.currentDate),
    );
    if (!clock.tradable || clock.phase == MarketSessionPhase.closingAuction) {
      return state;
    }
    if (marketDynamicVolatilityInterruptionActive(
      minute: marketMinute,
      previousTradePrice: previousTradePrice ?? unitPrice,
      currentPrice: unitPrice,
      tradingDay: isTradingDay && isMarketTradingDay(state.currentDate),
    )) {
      return state;
    }
    if (marketMaterialNewsTradingHaltAt(
          simulationSeed: state.simulationSeed,
          date: state.currentDate,
          assetId: assetId,
          minute: marketMinute,
        ) !=
        null) {
      return state;
    }
    final representativeOrder = eligibleOrders.first;
    final maximumPositionUnits = eligibleOrders
        .map((order) => order.maximumPositionUnits)
        .whereType<int>()
        .where((value) => value > 0)
        .fold<int?>(null, (maximum, value) {
          return maximum == null ? value : math.max(maximum, value);
        });
    final snapshot = buildGameOrderBookSnapshot(
      assetId: assetId,
      day: marketLiquidityDayKey(state.currentDate),
      minute: marketMinute,
      currentPrice: unitPrice,
      previousClose: previousClose > 0 ? previousClose : unitPrice,
      previousTradePrice: previousTradePrice,
      sessionLow: sessionLow,
      sessionHigh: sessionHigh,
      date: state.currentDate,
      market: representativeOrder.market,
      simulationSeed: state.simulationSeed,
      tradingDay: isTradingDay,
      sharesOutstanding: maximumPositionUnits,
      isIpoFirstTradingDay:
          isIpoFirstTradingDay ?? representativeOrder.isIpoFirstTradingDay,
      technicalLevels: technicalLevels,
    );
    if (snapshot.executionCapacity <= 0) return state;
    final perFillNotionalLimit = gameMarketOrderNotionalLimit(
      unitPrice,
      turnoverEok: snapshot.turnoverEok,
    );
    if (perFillNotionalLimit <= 0) return state;

    var next = state;
    final candidates = eligibleOrders.toList()
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
      final currentIndex = next.pendingOrders.indexWhere(
        (order) => order.id == candidate.id,
      );
      if (currentIndex < 0) continue;
      final current = next.pendingOrders[currentIndex];
      final isBuy = current.side == PendingOrderSide.buy;
      var capacity = math.max(
        0,
        snapshot.executionCapacity -
            gameConsumedOrderBookFillUnits(
              next,
              assetId: assetId,
              marketMinute: marketMinute,
              side: isBuy ? TradeSide.buy : TradeSide.sell,
            ),
      );
      if (capacity <= 0) continue;
      final consumedByPrice = gameConsumedOrderBookUnitsByPrice(
        next,
        assetId: assetId,
        marketMinute: marketMinute,
        bookSide: isBuy ? GameOrderBookSide.ask : GameOrderBookSide.bid,
      );

      final aggressivePlan = gameOrderBookLimitFillPlan(
        snapshot: snapshot,
        isBuy: isBuy,
        requestedQuantity: current.remainingQuantity,
        limitPrice: current.limitPrice,
        availableCapacity: capacity,
        maximumNotional: perFillNotionalLimit,
        alreadyConsumedByPrice: consumedByPrice,
      );
      var fillQuantity = aggressivePlan.filledQuantity.toDouble();
      var fillPrice = aggressivePlan.averagePrice;
      var queueAhead = current.queueAheadQuantity;

      if (!aggressivePlan.hasFill) {
        final sameSideRestingLevels = isBuy ? snapshot.bids : snapshot.asks;
        final representedRestingLevel = sameSideRestingLevels.any(
          (level) => (level.price - current.limitPrice).abs() < 0.000001,
        );
        if (!representedRestingLevel) continue;
        final touched = isBuy
            ? current.limitPrice >= unitPrice
            : current.limitPrice <= unitPrice;
        if (!touched) continue;
        final consumedQueue = math.min(queueAhead.ceil(), capacity);
        queueAhead = math.max(0, queueAhead - consumedQueue);
        capacity -= consumedQueue;
        if (consumedQueue > 0) {
          final markerId =
              'book-queue-${current.id}-$marketMinute-${next.ledger.length + 1}';
          next = next.copyWith(
            ledger: [
              ...next.ledger,
              LedgerEntry(
                id: markerId,
                day: next.day,
                amount: 0,
                account: 'brokerage_order',
                counterAccount: 'external_order_book_queue',
                description: '${current.name} 외부 대기수량 소진',
                sourceId: markerId,
                assetId: current.assetId,
                marketMinute: marketMinute,
                orderType: TradeOrderType.limit.name,
                orderBookCapacityUnits: consumedQueue,
                orderBookSide: isBuy
                    ? GameOrderBookSide.bid.name
                    : GameOrderBookSide.ask.name,
                orderBookFills: <LedgerOrderBookFill>[
                  LedgerOrderBookFill(
                    price: current.limitPrice,
                    quantity: consumedQueue.toDouble(),
                  ),
                ],
              ),
            ],
          );
        }
        if (queueAhead > 0 || capacity <= 0) {
          final pending = [...next.pendingOrders];
          pending[currentIndex] = current.copyWith(
            queueAheadQuantity: queueAhead,
          );
          next = next.copyWith(pendingOrders: pending);
          continue;
        }
        fillQuantity = math.min(
          math.min(current.remainingQuantity, capacity.toDouble()),
          (perFillNotionalLimit / current.limitPrice).floorToDouble(),
        );
        fillPrice = current.limitPrice;
      }
      if (fillQuantity <= 0 || fillPrice <= 0) continue;

      final withoutCurrent = next.copyWith(
        pendingOrders: next.pendingOrders
            .where((order) => order.id != current.id)
            .toList(growable: false),
        marketMinute: marketMinute,
      );
      final fill = _executeFilledTrade(
        withoutCurrent,
        TradeOrder(
          side: isBuy ? TradeSide.buy : TradeSide.sell,
          assetId: current.assetId,
          symbol: current.symbol,
          name: current.name,
          market: current.market,
          currency: current.currency,
          quantity: fillQuantity,
          unitPrice: fillPrice,
          quoteDate: marketDateKey(state.currentDate),
          marketMinute: marketMinute,
          isTradingDay: isTradingDay,
          type: TradeOrderType.limit,
          limitPrice: current.limitPrice,
          previousClose: previousClose > 0 ? previousClose : unitPrice,
          maximumPositionUnits: current.maximumPositionUnits,
          isIpoFirstTradingDay: current.isIpoFirstTradingDay,
          orderBookSide: aggressivePlan.hasFill
              ? aggressivePlan.levelSide
              : null,
          orderBookFills: aggressivePlan.hasFill
              ? _ledgerOrderBookFills(aggressivePlan)
              : const <LedgerOrderBookFill>[],
          orderBookCapacityUnits: fillQuantity.ceil(),
        ),
      );
      if (!fill.success) continue;
      next = fill.state;
      final remaining = current.remainingQuantity - fillQuantity;
      if (remaining > 0.000001) {
        next = next.copyWith(
          pendingOrders: [
            ...next.pendingOrders,
            current.copyWith(
              remainingQuantity: remaining,
              queueAheadQuantity: 0,
            ),
          ],
        );
      }
    }
    return next;
  }

  void _validatePendingOrderQuotePaths(
    GameState state,
    Map<String, GamePendingOrderQuotePath> quotePaths,
  ) {
    final pendingAssetIds = state.pendingOrders
        .map((order) => order.assetId)
        .toSet();
    for (final assetId in pendingAssetIds) {
      final quotePath = quotePaths[assetId];
      if (quotePath == null || quotePath.prices.isEmpty) {
        throw ArgumentError(
          'Pending orders require a deterministic quote path for $assetId.',
        );
      }
      final calendarTradingDay = isMarketTradingDay(state.currentDate);
      if (quotePath.isTradingDay != calendarTradingDay) {
        throw ArgumentError(
          'Pending-order quote path for $assetId has a trading-day mismatch.',
        );
      }
      if (calendarTradingDay &&
          quotePath.prices.length < generatedSessionTicks + 1) {
        throw ArgumentError(
          'Trading-day quote path for $assetId must contain at least '
          '${generatedSessionTicks + 1} ticks.',
        );
      }
      if (quotePath.prices.any((price) => !price.isFinite || price <= 0)) {
        throw ArgumentError(
          'Pending-order quote path for $assetId contains an invalid price.',
        );
      }
    }
  }

  GameState processPendingOrdersThroughMarketMinute(
    GameState state, {
    required int targetMinute,
    required Map<String, GamePendingOrderQuotePath> quotePaths,
  }) {
    if (targetMinute < state.marketMinute) {
      throw ArgumentError.value(
        targetMinute,
        'targetMinute',
        'Pending orders cannot be processed backwards in time.',
      );
    }
    final target = targetMinute.clamp(marketDayStartMinute, marketDayEndMinute);
    var next = state;
    if (target > state.marketMinute && state.pendingOrders.isNotEmpty) {
      _validatePendingOrderQuotePaths(state, quotePaths);
      final sessionLows = <String, double>{};
      final sessionHighs = <String, double>{};
      final initialPathIndex = marketTickForMinute(state.marketMinute);
      for (final entry in quotePaths.entries) {
        final path = entry.value;
        var low = path.previousClose;
        var high = path.previousClose;
        final visibleEnd = initialPathIndex.clamp(0, path.prices.length - 1);
        for (var index = 0; index <= visibleEnd; index += 1) {
          low = math.min(low, path.prices[index]);
          high = math.max(high, path.prices[index]);
        }
        sessionLows[entry.key] = low;
        sessionHighs[entry.key] = high;
      }
      for (var cursor = state.marketMinute + 1; cursor <= target; cursor += 1) {
        next = next.copyWith(marketMinute: cursor);
        final pendingAssetIds = next.pendingOrders
            .map((order) => order.assetId)
            .toSet();
        for (final assetId in pendingAssetIds) {
          final quotePath = quotePaths[assetId]!;
          final pathIndex = marketTickForMinute(
            cursor,
          ).clamp(0, quotePath.prices.length - 1);
          final previousPathPrice = pathIndex > 0
              ? quotePath.prices[pathIndex - 1]
              : quotePath.previousClose;
          final currentPathPrice = quotePath.prices[pathIndex];
          final sessionLow = math.min(
            sessionLows[assetId] ?? quotePath.previousClose,
            currentPathPrice,
          );
          final sessionHigh = math.max(
            sessionHighs[assetId] ?? quotePath.previousClose,
            currentPathPrice,
          );
          sessionLows[assetId] = sessionLow;
          sessionHighs[assetId] = sessionHigh;
          next = cursor == krxCloseMinute
              ? _processClosingAuctionOrdersAtQuote(
                  next,
                  assetId: assetId,
                  unitPrice: currentPathPrice,
                  previousTradePrice: previousPathPrice,
                  isTradingDay: quotePath.isTradingDay,
                  previousClose: quotePath.previousClose,
                  isIpoFirstTradingDay: quotePath.isIpoFirstTradingDay,
                  sessionLow: sessionLow,
                  sessionHigh: sessionHigh,
                  technicalLevels: quotePath.technicalLevels,
                )
              : processPendingOrdersAtQuote(
                  next,
                  assetId: assetId,
                  unitPrice: currentPathPrice,
                  marketMinute: cursor,
                  isTradingDay: quotePath.isTradingDay,
                  previousClose: quotePath.previousClose,
                  previousTradePrice: previousPathPrice,
                  sessionLow: sessionLow,
                  sessionHigh: sessionHigh,
                  isIpoFirstTradingDay: quotePath.isIpoFirstTradingDay,
                  technicalLevels: quotePath.technicalLevels,
                );
        }
      }
    } else if (target > state.marketMinute) {
      next = state.copyWith(marketMinute: target);
    }
    if (target >= krxCloseMinute) {
      next = expirePendingOrders(next.copyWith(marketMinute: target));
    }
    return next;
  }

  GameState _processClosingAuctionOrdersAtQuote(
    GameState state, {
    required String assetId,
    required double unitPrice,
    required double previousTradePrice,
    required bool isTradingDay,
    required double previousClose,
    required bool isIpoFirstTradingDay,
    double? sessionLow,
    double? sessionHigh,
    Iterable<MarketTechnicalLevel> technicalLevels =
        const <MarketTechnicalLevel>[],
  }) {
    if (!isTradingDay ||
        !isMarketTradingDay(state.currentDate) ||
        state.marketMinute != krxCloseMinute) {
      return state;
    }
    final stateDate = marketDateKey(state.currentDate);
    final candidates =
        state.pendingOrders
            .where(
              (order) =>
                  order.assetId == assetId &&
                  order.placedDate == stateDate &&
                  order.placedMinute <= krxCloseMinute,
            )
            .toList()
          ..sort((left, right) {
            if (left.side != right.side) {
              return left.side.index.compareTo(right.side.index);
            }
            final priceOrder = left.side == PendingOrderSide.buy
                ? right.limitPrice.compareTo(left.limitPrice)
                : left.limitPrice.compareTo(right.limitPrice);
            if (priceOrder != 0) return priceOrder;
            final sequenceOrder = left.placedSequence.compareTo(
              right.placedSequence,
            );
            return sequenceOrder != 0
                ? sequenceOrder
                : left.id.compareTo(right.id);
          });
    if (candidates.isEmpty) return state;

    final maximumPositionUnits = candidates
        .map((order) => order.maximumPositionUnits)
        .whereType<int>()
        .where((value) => value > 0)
        .fold<int?>(null, (maximum, value) {
          return maximum == null ? value : math.max(maximum, value);
        });
    final snapshot = buildGameOrderBookSnapshot(
      assetId: assetId,
      day: marketLiquidityDayKey(state.currentDate),
      minute: krxCloseMinute - 1,
      currentPrice: unitPrice,
      previousClose: previousClose > 0 ? previousClose : unitPrice,
      previousTradePrice: previousTradePrice,
      sessionLow: sessionLow,
      sessionHigh: sessionHigh,
      date: state.currentDate,
      market: candidates.first.market,
      simulationSeed: state.simulationSeed,
      tradingDay: true,
      sharesOutstanding: maximumPositionUnits,
      isIpoFirstTradingDay: isIpoFirstTradingDay,
      technicalLevels: technicalLevels,
    );
    var remainingCapacity = math.max(
      0,
      snapshot.executionCapacity -
          gameConsumedOrderBookFillUnits(
            state,
            assetId: assetId,
            marketMinute: krxCloseMinute,
            side: TradeSide.buy,
          ),
    );
    final perFillNotionalLimit = gameMarketOrderNotionalLimit(
      unitPrice,
      turnoverEok: snapshot.turnoverEok,
    );
    if (perFillNotionalLimit <= 0) return state;
    var next = state;
    for (final candidate in candidates) {
      final currentIndex = next.pendingOrders.indexWhere(
        (order) => order.id == candidate.id,
      );
      if (currentIndex < 0) continue;
      final current = next.pendingOrders[currentIndex];
      final isBuy = current.side == PendingOrderSide.buy;
      final crossed = isBuy
          ? current.limitPrice + 0.000001 >= unitPrice
          : current.limitPrice <= unitPrice + 0.000001;
      var capacity = remainingCapacity;
      if (!crossed || capacity <= 0) continue;
      final fillQuantity = math.min(
        math.min(current.remainingQuantity, capacity.toDouble()),
        (perFillNotionalLimit / unitPrice).floorToDouble(),
      );
      if (fillQuantity <= 0) continue;
      final withoutCurrent = next.copyWith(
        pendingOrders: next.pendingOrders
            .where((order) => order.id != current.id)
            .toList(growable: false),
      );
      final fill = _executeFilledTrade(
        withoutCurrent,
        TradeOrder(
          side: isBuy ? TradeSide.buy : TradeSide.sell,
          assetId: current.assetId,
          symbol: current.symbol,
          name: current.name,
          market: current.market,
          currency: current.currency,
          quantity: fillQuantity,
          unitPrice: unitPrice,
          quoteDate: marketDateKey(state.currentDate),
          marketMinute: krxCloseMinute,
          isTradingDay: true,
          type: TradeOrderType.limit,
          limitPrice: current.limitPrice,
          previousClose: previousClose,
          maximumPositionUnits: current.maximumPositionUnits,
          isIpoFirstTradingDay: current.isIpoFirstTradingDay,
        ),
        isClosingAuctionFill: true,
      );
      if (!fill.success) continue;
      next = fill.state;
      final remaining = current.remainingQuantity - fillQuantity;
      if (remaining > 0.000001) {
        next = next.copyWith(
          pendingOrders: [
            ...next.pendingOrders,
            current.copyWith(
              remainingQuantity: remaining,
              queueAheadQuantity: 0,
            ),
          ],
        );
      }
      capacity -= fillQuantity.ceil();
      remainingCapacity = capacity;
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
    return state.copyWith(
      pendingOrders: state.pendingOrders
          .where((order) => !ids.contains(order.id))
          .toList(growable: false),
      ledger: [
        ...state.ledger,
        for (final order in expired)
          LedgerEntry(
            id: 'expire-${order.id}',
            day: state.day,
            amount: 0,
            account: 'brokerage_order',
            counterAccount: 'day_order_expiry',
            description:
                '장 마감 · ${order.name} '
                '${_tradeUnits(order.remainingQuantity)}주 미체결 자동 취소',
            sourceId: 'expire-${order.id}',
            assetId: order.assetId,
            tradeSide: order.side.name,
            marketMinute: state.marketMinute,
            orderType: TradeOrderType.limit.name,
          ),
      ],
    );
  }

  TradeExecutionResult _placeMarketOrder(GameState state, TradeOrder order) {
    TradeExecutionResult reject(String message) =>
        TradeExecutionResult(state: state, success: false, message: message);

    if (order.assetId.trim().isEmpty ||
        !order.quantity.isFinite ||
        order.quantity <= 0 ||
        (order.side == TradeSide.buy &&
            order.quantity != order.quantity.roundToDouble())) {
      return reject('주문 수량은 1주 단위로 입력해 주세요.');
    }
    if (!order.unitPrice.isFinite || order.unitPrice <= 0) {
      return reject('유효한 현재가가 없습니다.');
    }
    if (!_displayedOrderBookSnapshotMatchesOrder(state, order)) {
      return reject(_staleDisplayedOrderBookMessage);
    }
    if (_wouldExceedIssuedShares(state, order, includePendingBuys: true)) {
      return reject('보유·미체결 수량을 합쳐 발행주식 수를 넘길 수 없습니다.');
    }
    final stateDate = marketDateKey(state.currentDate);
    if (order.quoteDate != stateDate) {
      return reject('시세 날짜가 바뀌었습니다. 주문창을 다시 확인해 주세요.');
    }
    if (order.currency != 'KRW') {
      return reject('해외 종목은 실제 환율 원장과 연결한 뒤 거래할 수 있습니다.');
    }
    if (order.marketMinute != state.marketMinute) {
      return reject('시세 시간이 바뀌었습니다. 주문창을 다시 확인해 주세요.');
    }
    final tradingDay =
        order.isTradingDay && isMarketTradingDay(state.currentDate);
    final clock = marketClockAt(order.marketMinute, tradingDay: tradingDay);
    if (!clock.tradable) {
      return reject('현재는 주문 가능한 거래 시간이 아닙니다.');
    }
    if (marketDynamicVolatilityInterruptionActive(
      minute: order.marketMinute,
      previousTradePrice: order.previousTradePrice ?? order.unitPrice,
      currentPrice: order.unitPrice,
      tradingDay: tradingDay,
    )) {
      return reject('변동성완화장치(VI) 발동 중입니다. 다음 분 단일가 해제 후 주문해 주세요.');
    }
    if (marketMaterialNewsTradingHaltAt(
          simulationSeed: state.simulationSeed,
          date: state.currentDate,
          assetId: order.assetId,
          minute: order.marketMinute,
        ) !=
        null) {
      return reject('중대 공시로 거래정지 중입니다. 공시 후 5분 뒤 재개됩니다.');
    }

    final requestedNotional = order.unitPrice * order.quantity;
    if (!requestedNotional.isFinite || requestedNotional <= 0) {
      return reject('주문 금액이 올바르지 않습니다.');
    }
    if (order.side == TradeSide.buy) {
      if (state.story.accountAuthorityLevel == 0) {
        return reject('첫 주문 권한을 먼저 열어야 합니다.');
      }
    } else {
      final position = state.positions
          .where((item) => item.assetId == order.assetId)
          .firstOrNull;
      final available =
          (position?.units ?? 0) -
          state.pendingSellReservedUnits(order.assetId);
      if (available + 0.000001 < order.quantity) {
        return reject('다른 미체결 매도 주문을 제외한 보유 수량이 부족합니다.');
      }
      if (order.quantity != order.quantity.roundToDouble() &&
          (available - order.quantity).abs() > 0.000001) {
        return reject('소수점 잔여 주식은 보유 수량 전부만 매도할 수 있습니다.');
      }
    }

    final reference = order.previousClose > 0
        ? order.previousClose
        : order.unitPrice;
    final range = marketDailyPriceRange(
      previousClose: reference,
      date: state.currentDate,
      market: order.market,
      isIpoFirstTradingDay: order.isIpoFirstTradingDay,
    );
    if (clock.phase == MarketSessionPhase.closingAuction) {
      final queued = _placeLimitOrder(
        state,
        TradeOrder(
          side: order.side,
          assetId: order.assetId,
          symbol: order.symbol,
          name: order.name,
          market: order.market,
          currency: order.currency,
          quantity: order.quantity,
          unitPrice: order.unitPrice,
          quoteDate: order.quoteDate,
          marketMinute: order.marketMinute,
          isTradingDay: order.isTradingDay,
          type: TradeOrderType.limit,
          limitPrice: order.side == TradeSide.buy ? range.upper : range.lower,
          previousClose: reference,
          previousTradePrice: order.previousTradePrice,
          sessionLow: order.sessionLow,
          sessionHigh: order.sessionHigh,
          maximumPositionUnits: order.maximumPositionUnits,
          isIpoFirstTradingDay: order.isIpoFirstTradingDay,
          technicalLevels: order.technicalLevels,
          microstructureFrame: order.microstructureFrame,
          displayedSnapshot: order.displayedSnapshot,
        ),
        allowFractionalSellLiquidation:
            order.side == TradeSide.sell &&
            order.quantity != order.quantity.roundToDouble(),
      );
      return TradeExecutionResult(
        state: queued.state,
        success: queued.success,
        message: queued.success
            ? '${order.name} 시장가 동시호가 주문 접수 · 15:00 단일가 체결'
            : queued.message,
        orderId: queued.orderId,
        filledQuantity: 0,
        pendingQuantity: queued.pendingQuantity,
      );
    }
    final snapshot =
        order.displayedSnapshot ??
        buildGameOrderBookSnapshot(
          assetId: order.assetId,
          day: marketLiquidityDayKey(state.currentDate),
          minute: order.marketMinute,
          currentPrice: order.unitPrice,
          previousClose: reference,
          previousTradePrice: order.previousTradePrice,
          sessionLow: order.sessionLow,
          sessionHigh: order.sessionHigh,
          date: state.currentDate,
          market: order.market,
          simulationSeed: state.simulationSeed,
          tradingDay: tradingDay,
          sharesOutstanding: order.maximumPositionUnits,
          isIpoFirstTradingDay: order.isIpoFirstTradingDay,
          technicalLevels: order.technicalLevels,
          liquidityPulse: order.microstructureFrame,
          adaptiveLiquidityPulses: order.microstructureFrame > 0,
        );
    final consumed = gameConsumedOrderBookFillUnits(
      state,
      assetId: order.assetId,
      marketMinute: order.marketMinute,
      side: order.side,
    );
    final availableCapacity = math.max(
      0,
      snapshot.executionCapacity - consumed,
    );
    final bookSide = order.side == TradeSide.buy
        ? GameOrderBookSide.ask
        : GameOrderBookSide.bid;
    final consumedByPrice = gameConsumedOrderBookUnitsByPrice(
      state,
      assetId: order.assetId,
      marketMinute: order.marketMinute,
      bookSide: bookSide,
    );
    final planConsumedByPrice = order.displayedSnapshot == null
        ? consumedByPrice
        : const <double, double>{};
    final liquidityLimit = gameMarketOrderNotionalLimit(
      order.unitPrice,
      turnoverEok: snapshot.turnoverEok,
    );
    if (liquidityLimit <= 0) {
      return reject('시장가 주문을 체결할 호가 잔량이 없습니다.');
    }
    if (order.side == TradeSide.sell &&
        order.quantity != order.quantity.roundToDouble()) {
      var fractionalRemaining = math.min(
        order.quantity,
        availableCapacity.toDouble(),
      );
      var fractionalFilledQuantity = 0.0;
      var fractionalNotional = 0.0;
      final fractionalFills = <LedgerOrderBookFill>[];
      for (final bid in snapshot.bids) {
        if (fractionalRemaining <= 0.000001) break;
        final remainingBudget = liquidityLimit - fractionalNotional;
        if (remainingBudget <= 0) break;
        final availableAtLevel = math.max(
          0.0,
          bid.quantity.toDouble() -
              _orderBookConsumedAtPrice(planConsumedByPrice, bid.price),
        );
        final fillAtLevel = math
            .min(
              math.min(fractionalRemaining, availableAtLevel),
              remainingBudget / bid.price,
            )
            .toDouble();
        if (fillAtLevel <= 0.000001) continue;
        fractionalFilledQuantity += fillAtLevel;
        fractionalRemaining -= fillAtLevel;
        fractionalNotional += bid.price * fillAtLevel;
        fractionalFills.add(
          LedgerOrderBookFill(price: bid.price, quantity: fillAtLevel),
        );
      }
      if (fractionalFilledQuantity <= 0.000001 ||
          !fractionalNotional.isFinite) {
        return reject('시장가 주문을 체결할 호가 잔량이 없습니다.');
      }
      final fill = _executeFilledTrade(
        state,
        TradeOrder(
          side: order.side,
          assetId: order.assetId,
          symbol: order.symbol,
          name: order.name,
          market: order.market,
          currency: order.currency,
          quantity: fractionalFilledQuantity,
          unitPrice: fractionalNotional / fractionalFilledQuantity,
          quoteDate: order.quoteDate,
          marketMinute: order.marketMinute,
          isTradingDay: order.isTradingDay,
          type: TradeOrderType.market,
          limitPrice: range.lower,
          previousClose: reference,
          maximumPositionUnits: order.maximumPositionUnits,
          isIpoFirstTradingDay: order.isIpoFirstTradingDay,
          orderBookSide: GameOrderBookSide.bid,
          orderBookFills: List<LedgerOrderBookFill>.unmodifiable(
            fractionalFills,
          ),
          orderBookCapacityUnits: fractionalFilledQuantity.ceil(),
        ),
      );
      return TradeExecutionResult(
        state: fill.state,
        success: fill.success,
        message: !fill.success
            ? fill.message
            : order.quantity - fill.filledQuantity > 0.000001
            ? '${order.name} ${_tradeUnits(fill.filledQuantity)}주 시장가 매도 체결 · '
                  '${_tradeUnits(order.quantity - fill.filledQuantity)}주 즉시 취소'
            : '${order.name} ${_tradeUnits(fill.filledQuantity)}주 매도 완료 · '
                  '시장가 전량 체결',
        notional: fill.notional,
        fee: fill.fee,
        transactionTax: fill.transactionTax,
        realizedPnl: fill.realizedPnl,
        filledQuantity: fill.filledQuantity,
        pendingQuantity: 0,
        averageFillPrice: fill.averageFillPrice,
      );
    }
    final plan = gameOrderBookLimitFillPlan(
      snapshot: snapshot,
      isBuy: order.side == TradeSide.buy,
      requestedQuantity: order.quantity,
      limitPrice: order.side == TradeSide.buy ? range.upper : range.lower,
      availableCapacity: availableCapacity,
      maximumNotional: order.side == TradeSide.buy
          ? gameBuyNotionalBudget(
              state,
              maximumNotional: math.min(
                liquidityLimit,
                gameOrderAuthorityLimit(state),
              ),
            )
          : liquidityLimit,
      alreadyConsumedByPrice: planConsumedByPrice,
    );
    if (!plan.hasFill) {
      if (order.side == TradeSide.buy &&
          snapshot.asks.isNotEmpty &&
          (snapshot.asks.first.price * (1 + gameTradingFeeRateForState(state)))
                  .ceil() >
              state.availableBrokerageCash) {
        return reject('다른 미체결 주문을 제외한 주문 가능 예수금이 부족합니다.');
      }
      return reject('시장가 주문을 체결할 호가 잔량이 없습니다.');
    }

    final fill = _executeFilledTrade(
      state,
      TradeOrder(
        side: order.side,
        assetId: order.assetId,
        symbol: order.symbol,
        name: order.name,
        market: order.market,
        currency: order.currency,
        quantity: plan.filledQuantity.toDouble(),
        unitPrice: plan.averagePrice,
        quoteDate: order.quoteDate,
        marketMinute: order.marketMinute,
        isTradingDay: order.isTradingDay,
        type: TradeOrderType.market,
        limitPrice: order.side == TradeSide.buy ? range.upper : range.lower,
        previousClose: reference,
        maximumPositionUnits: order.maximumPositionUnits,
        isIpoFirstTradingDay: order.isIpoFirstTradingDay,
        orderBookSide: plan.levelSide,
        orderBookFills: _ledgerOrderBookFills(plan),
        orderBookCapacityUnits: plan.filledQuantity,
      ),
    );
    if (!fill.success) return fill;

    final canceledQuantity = order.quantity - plan.filledQuantity;
    final sideLabel = order.side == TradeSide.buy ? '매수' : '매도';
    return TradeExecutionResult(
      state: fill.state,
      success: true,
      message: canceledQuantity > 0.000001
          ? '${order.name} ${plan.filledQuantity}주 시장가 $sideLabel 체결 · '
                '${_tradeUnits(canceledQuantity)}주 즉시 취소'
          : '${order.name} ${plan.filledQuantity}주 $sideLabel 완료 · '
                '시장가 전량 체결',
      notional: fill.notional,
      fee: fill.fee,
      transactionTax: fill.transactionTax,
      realizedPnl: fill.realizedPnl,
      filledQuantity: plan.filledQuantity.toDouble(),
      pendingQuantity: 0,
      averageFillPrice: plan.averagePrice,
    );
  }

  TradeExecutionResult executeTrade(GameState state, TradeOrder order) {
    return order.type == TradeOrderType.limit
        ? _placeLimitOrder(state, order)
        : _placeMarketOrder(state, order);
  }

  TradeExecutionResult _executeFilledTrade(
    GameState state,
    TradeOrder order, {
    bool isClosingAuctionFill = false,
  }) {
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
    if (_wouldExceedIssuedShares(state, order, includePendingBuys: true)) {
      return reject('보유·미체결 수량을 합쳐 발행주식 수를 넘길 수 없습니다.');
    }
    final limitPrice = order.limitPrice;
    if (limitPrice == null ||
        !limitPrice.isFinite ||
        limitPrice <= 0 ||
        (order.side == TradeSide.buy &&
            order.unitPrice > limitPrice + 0.000001) ||
        (order.side == TradeSide.sell &&
            order.unitPrice + 0.000001 < limitPrice)) {
      return reject('지정가 범위를 벗어난 체결은 처리할 수 없습니다.');
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
    if (isClosingAuctionFill &&
        (order.marketMinute != krxCloseMinute ||
            !order.isTradingDay ||
            !isMarketTradingDay(state.currentDate))) {
      return reject('종가 단일가 체결 상태가 올바르지 않습니다.');
    }
    if (!clock.tradable && !isClosingAuctionFill) {
      return reject('현재는 주문 가능한 거래 시간이 아닙니다.');
    }

    final rawNotionalValue = order.unitPrice * order.quantity;
    if (!rawNotionalValue.isFinite || rawNotionalValue <= 0) {
      return reject('주문 금액이 올바르지 않습니다.');
    }
    final rawNotional = rawNotionalValue.round();
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
    final notional = rawNotional;
    final fee = gameTradingFeeForState(state, notional);
    final transactionTax = order.side == TradeSide.sell
        ? gameSecuritiesTransactionTax(state.currentDate, notional)
        : 0;
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
      final proceeds = notional - fee - transactionTax;
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
          '거래세 $transactionTax원 · '
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
    final earnsDailyProfitReputation =
        order.side == TradeSide.sell &&
        realizedPnl > 0 &&
        state.story.flagInt('lastProfitableTradeRewardDay', -1) != state.day;
    if (order.side == TradeSide.sell && realizedPnl > 0) {
      if (earnsDailyProfitReputation) {
        reputation += state.progression.hasSkill('calm_exit') ? 2 : 1;
        flags['lastProfitableTradeRewardDay'] = state.day;
      }
      progression = progression
          .record('profitable_sales')
          .record('realized_profit', realizedPnl);
    }
    if (authority >= 2 &&
        authority < 3 &&
        progression.counter('trade_volume') >= 2000000) {
      authority = 3;
    }
    if (authority >= 4 &&
        authority < 5 &&
        state.story.fundLaunched &&
        reputation >= 60) {
      authority = 5;
    }
    final earnsDailyTrust =
        state.story.flagInt('lastTradeTrustRewardDay', -1) != state.day;
    if (earnsDailyTrust) flags['lastTradeTrustRewardDay'] = state.day;
    flags['reputation'] = reputation.clamp(0, 100);
    final next = state.copyWith(
      marketMinute: order.marketMinute,
      brokerageCash: state.brokerageCash + cashDelta,
      cash: state.cash + cashDelta,
      positions: positions,
      progression: progression,
      story: state.story.copyWith(
        accountAuthorityLevel: authority,
        familyTrust: state.story.familyTrust + (earnsDailyTrust ? 1 : 0),
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
          transactionTax: transactionTax,
          disposedCost: disposedCost,
          realizedPnl: realizedPnl,
          assetId: order.assetId,
          tradeSide: order.side.name,
          tradeQuantity: order.quantity,
          tradeUnitPrice: notional / order.quantity,
          marketMinute: order.marketMinute,
          orderType: order.type.name,
          orderBookSide: isClosingAuctionFill
              ? ''
              : order.orderBookSide?.name ?? '',
          orderBookFills: isClosingAuctionFill
              ? const <LedgerOrderBookFill>[]
              : order.orderBookFills,
          orderBookCapacityUnits: isClosingAuctionFill
              ? 0
              : math.max(0, order.orderBookCapacityUnits),
        ),
      ],
    );
    return TradeExecutionResult(
      state: next,
      success: true,
      message:
          '${order.name} ${_tradeUnits(order.quantity)}주 $sideLabel 완료 · 증권 수수료 $fee원'
          '${transactionTax > 0 ? ' · 거래세 $transactionTax원' : ''}'
          '${order.side == TradeSide.sell ? ' · 실현손익 ${realizedPnl >= 0 ? '+' : ''}$realizedPnl원' : ''}',
      notional: notional,
      fee: fee,
      transactionTax: transactionTax,
      realizedPnl: realizedPnl,
      filledQuantity: order.quantity,
      averageFillPrice: notional / order.quantity,
    );
  }

  GameState applyCorporateActions(
    GameState state,
    List<MarketCorporateAction> actions,
  ) {
    var cash = state.cash;
    var brokerageCash = state.brokerageCash;
    var positions = [...state.positions];
    var pendingOrders = [...state.pendingOrders];
    final ledger = [...state.ledger];
    final processed = {...state.processedEventIds};
    var changed = false;
    final dateKey = state.currentDate.toIso8601String().split('T').first;

    final orderedActions = [...actions]
      ..sort((left, right) {
        final typeOrder = marketCorporateActionOrder(
          left.type,
        ).compareTo(marketCorporateActionOrder(right.type));
        if (typeOrder != 0) return typeOrder;
        return left.id.compareTo(right.id);
      });
    for (final action in orderedActions) {
      final eventId = 'market-action-${action.id}';
      if (action.date != dateKey || processed.contains(eventId)) continue;
      final canceledOrders = pendingOrders
          .where((order) => order.assetId == action.assetId)
          .toList(growable: false);
      if (canceledOrders.isNotEmpty) {
        final canceledIds = canceledOrders.map((order) => order.id).toSet();
        pendingOrders = pendingOrders
            .where((order) => !canceledIds.contains(order.id))
            .toList(growable: false);
        for (final order in canceledOrders) {
          ledger.add(
            LedgerEntry(
              id: '$eventId-cancel-${order.id}',
              day: state.day,
              amount: 0,
              account: 'brokerage_order',
              counterAccount: 'corporate_action_cancel',
              description:
                  '${order.name} ${_tradeUnits(order.remainingQuantity)}주 '
                  '미체결 주문 · 기업행동으로 자동 취소',
              sourceId: '$eventId-cancel-${order.id}',
              assetId: order.assetId,
              tradeSide: order.side.name,
              marketMinute: state.marketMinute,
              orderType: TradeOrderType.limit.name,
            ),
          );
        }
        changed = true;
      }
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
        final grossDividend = (position.units * action.amount).round();
        if (grossDividend > 0) {
          final withholdingTax =
              (grossDividend * gameDividendWithholdingTaxRate).round();
          final netDividend = grossDividend - withholdingTax;
          cash += netDividend;
          brokerageCash += netDividend;
          ledger.add(
            LedgerEntry(
              id: eventId,
              day: state.day,
              amount: grossDividend,
              account: 'brokerage_cash',
              counterAccount: 'dividend_income',
              description: '${position.name} 배당금(세전)',
              sourceId: eventId,
            ),
          );
          if (withholdingTax > 0) {
            ledger.add(
              LedgerEntry(
                id: '$eventId-tax',
                day: state.day,
                amount: -withholdingTax,
                account: 'brokerage_cash',
                counterAccount: 'dividend_withholding_tax',
                description: '${position.name} 배당소득세 원천징수',
                sourceId: '$eventId-tax',
              ),
            );
          }
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
          final detachedValue = action.unitFactor * action.amount;
          final referencePrice = action.referencePrice;
          final allocationWeight =
              (referencePrice != null &&
                          referencePrice.isFinite &&
                          referencePrice > 0 &&
                          detachedValue.isFinite &&
                          detachedValue >= 0
                      ? (detachedValue / referencePrice).clamp(0.0, 1.0)
                      : (action.unitFactor / (1 + action.unitFactor)).clamp(
                          0.0,
                          1.0,
                        ))
                  .toDouble();
          final grantedCost = math.min(
            position.totalCost,
            math.max(0, (position.totalCost * allocationWeight).round()),
          );
          positions[index] = position.copyWith(
            totalCost: position.totalCost - grantedCost,
          );
          final relatedIndex = positions.indexWhere(
            (item) => item.assetId == action.relatedAssetId,
          );
          if (relatedIndex >= 0) {
            positions[relatedIndex] = positions[relatedIndex].copyWith(
              units: positions[relatedIndex].units + grantedUnits,
              totalCost: positions[relatedIndex].totalCost + grantedCost,
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
                totalCost: grantedCost,
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
        final dilutionPct = action.ownershipDilutionRate * 100;
        final isShareholderAllocation =
            action.allocationMethod ==
            MarketRightsIssueAllocationMethod.shareholder;
        final prefersSubscription =
            state.story.storyFlags[marketRightsIssuePreferenceFlag] ==
            marketRightsIssueSubscribePreference;
        final subscriptionUnits = position.units * action.rightsIssueRate;
        final subscriptionCost = (subscriptionUnits * action.amount).round();
        final availableForSubscription = state
            .copyWith(
              brokerageCash: brokerageCash,
              pendingOrders: pendingOrders,
            )
            .availableBrokerageCash;
        final hasExecutableSubscription =
            isShareholderAllocation &&
            prefersSubscription &&
            action.currency == position.currency &&
            subscriptionUnits.isFinite &&
            subscriptionUnits > 0 &&
            subscriptionCost > 0;

        if (hasExecutableSubscription &&
            subscriptionCost <= availableForSubscription) {
          cash -= subscriptionCost;
          brokerageCash -= subscriptionCost;
          positions[index] = position.copyWith(
            units: position.units + subscriptionUnits,
            totalCost: position.totalCost + subscriptionCost,
          );
          ledger.add(
            LedgerEntry(
              id: eventId,
              day: state.day,
              amount: -subscriptionCost,
              account: 'brokerage_cash',
              counterAccount: 'corporate_rights_subscription',
              description:
                  '${position.name} 주주배정 유상증자 청약 · '
                  '${_tradeUnits(subscriptionUnits)}주 배정 · '
                  '청약대금 $subscriptionCost원',
              sourceId: eventId,
              notional: subscriptionCost,
              assetId: action.assetId,
            ),
          );
          changed = true;
        } else {
          final theoreticalExRightsPrice = action.theoreticalExRightsPrice;
          final rightsValuePerShare =
              isShareholderAllocation &&
                  action.referencePrice != null &&
                  theoreticalExRightsPrice != null
              ? math.max(0, action.referencePrice! - theoreticalExRightsPrice)
              : 0.0;
          final rightsSaleProceeds = (position.units * rightsValuePerShare)
              .round();
          if (rightsSaleProceeds > 0) {
            cash += rightsSaleProceeds;
            brokerageCash += rightsSaleProceeds;
          }
          final subscriptionFallback =
              hasExecutableSubscription &&
              subscriptionCost > availableForSubscription;
          ledger.add(
            LedgerEntry(
              id: eventId,
              day: state.day,
              amount: rightsSaleProceeds,
              account: rightsSaleProceeds > 0
                  ? 'brokerage_cash'
                  : 'market_security',
              counterAccount: isShareholderAllocation
                  ? 'corporate_rights_sale'
                  : 'corporate_rights_issue',
              description: isShareholderAllocation
                  ? '${position.name} 주주배정 유상증자 · '
                        '${subscriptionFallback ? '청약대금 부족으로 ' : ''}'
                        '신주인수권 자동매각 $rightsSaleProceeds원 · '
                        '보유주식수 유지 · '
                        '지분율 -${dilutionPct.toStringAsFixed(2)}%'
                  : '${position.name} 제3자배정 유상증자 · 신주인수권 없음 · '
                        '보유주식수 유지 · 지분율 '
                        '-${dilutionPct.toStringAsFixed(2)}%',
              sourceId: eventId,
              notional: rightsSaleProceeds,
              assetId: action.assetId,
            ),
          );
          changed = true;
        }
      } else if (position != null &&
          (action.type == MarketCorporateActionType.merger ||
              action.type == MarketCorporateActionType.shareExchange) &&
          action.relatedAssetId != null &&
          action.relatedSymbol != null &&
          action.relatedName != null &&
          action.relatedMarket != null) {
        final receivedUnits = position.units * action.unitFactor;
        if (receivedUnits.isFinite && receivedUnits > 0) {
          positions.removeAt(index);
          final destinationIndex = positions.indexWhere(
            (item) => item.assetId == action.relatedAssetId,
          );
          if (destinationIndex >= 0) {
            final destination = positions[destinationIndex];
            positions[destinationIndex] = destination.copyWith(
              units: destination.units + receivedUnits,
              totalCost: destination.totalCost + position.totalCost,
            );
          } else {
            positions.add(
              PortfolioPosition(
                assetId: action.relatedAssetId!,
                symbol: action.relatedSymbol!,
                name: action.relatedName!,
                market: action.relatedMarket!,
                currency: action.currency,
                units: receivedUnits,
                totalCost: position.totalCost,
              ),
            );
          }
          final actionLabel = action.type == MarketCorporateActionType.merger
              ? '합병'
              : '포괄적 주식교환';
          ledger.add(
            LedgerEntry(
              id: eventId,
              day: state.day,
              amount: 0,
              account: 'market_security',
              counterAccount: action.type == MarketCorporateActionType.merger
                  ? 'corporate_merger'
                  : 'corporate_share_exchange',
              description:
                  '${position.name} $actionLabel · '
                  '${action.relatedName} ${_tradeUnits(receivedUnits)}주 수령 · '
                  '원가 ${position.totalCost}원 승계',
              sourceId: eventId,
              assetId: action.relatedAssetId!,
            ),
          );
          changed = true;
        }
      } else if (position != null &&
          action.type == MarketCorporateActionType.tenderOffer &&
          action.amount > 0) {
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
            counterAccount: 'corporate_tender_offer',
            description:
                '${position.name} 공개매수 참여 · '
                '${_tradeUnits(position.units)}주 ${action.amount.round()}원 정산',
            sourceId: eventId,
            notional: payout,
            assetId: action.assetId,
            disposedCost: position.totalCost,
            realizedPnl: payout - position.totalCost,
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
      pendingOrders: pendingOrders,
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
      'rider' => 700 + normalized * 15,
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
      'rider' => '동네 축제 킥보드 코스',
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

  GameState markMarketTutorialSeen(GameState state) => state.copyWith(
    story: state.story.copyWith(
      storyFlags: {
        ...state.story.storyFlags,
        'marketTutorialSeen': true,
        'marketTutorialCompletedDay': state.day,
      },
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
    final financingRequest = parseRealEstateFinancingRequest(optionId);
    final baseOptionId = financingRequest.baseOptionId;
    final listingRef = parseRealEstateListingOptionId(baseOptionId);
    final listing = listingRef == null
        ? null
        : realEstateListingByRefAt(
            listingRef,
            state.simulationSeed,
            state.currentDate,
            generatorVersion: realEstateWorldGeneratorVersion,
          );
    if (listingRef != null && listing == null) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '이 매물은 아직 공개되지 않았거나 이미 만료·계약되어 매입할 수 없습니다.',
      );
    }
    final option = listing == null
        ? spendingOptionById(baseOptionId)
        : spendingOptionById('market_${listing.asset.id}');
    final effectiveOptionId = listing?.optionId ?? baseOptionId;
    final effectiveTitle = listing?.displayName ?? option?.title ?? '부동산';
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
    final availableFrom =
        listing?.asset.availableFrom ?? option.marketAsset?.availableFrom;
    if (availableFrom != null && state.currentDate.isBefore(availableFrom)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '${availableFrom.year}년 ${availableFrom.month}월부터 선택할 수 있습니다.',
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
    final realEstateType =
        listing?.asset.type ??
        option.marketAsset?.type ??
        RealEstateAssetType.commercialUnit;
    final basePurchaseQuote =
        listing?.quoteAt(state.currentDate) ??
        option.quoteAt(state.currentDate);
    final purchaseQuote = basePurchaseQuote == null
        ? null
        : realEstatePortfolioAdjustedPurchaseQuote(
            baseQuote: basePurchaseQuote,
            date: state.currentDate,
            type: realEstateType,
            ownedHousingCount: finance.ownedHousingCount,
          );
    if (financingRequest.requestedLtvPercent > 0 &&
        (!option.isRealEstate || purchaseQuote == null)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '이 항목에는 부동산 담보대출을 사용할 수 없습니다.',
      );
    }
    final financingTerms = purchaseQuote == null
        ? const RealEstateFinancingTerms(
            maxLtvPercent: 0,
            annualInterestRate: 0,
            termMonths: 0,
            eraLabel: '현금 매입',
          )
        : realEstateFinancingTermsAt(state.currentDate, realEstateType);
    if (financingRequest.requestedLtvPercent > financingTerms.maxLtvPercent) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: financingTerms.available
            ? '현재 최대 LTV는 ${financingTerms.maxLtvPercent}%입니다.'
            : '현재는 이 매물에 담보대출을 사용할 수 없습니다.',
      );
    }
    final financingPlan = purchaseQuote == null
        ? null
        : financingTerms.planFor(
            purchaseQuote,
            financingRequest.requestedLtvPercent,
          );
    final purchaseCost =
        financingPlan?.cashRequired ?? purchaseQuote?.totalCash ?? option.cost;
    final purchaseBookValue = purchaseQuote?.totalCash ?? option.cost;
    if (financingPlan?.hasMortgage ?? false) {
      final targetMonthlyRent =
          listing?.monthlyRentAt(state.currentDate) ??
          option.monthlyIncomeAt(state.currentDate);
      final qualifyingMonthlyIncome = gameRealEstateQualifyingMonthlyIncome(
        state,
        targetMonthlyRent: targetMonthlyRent,
      );
      final assessment = assessRealEstateBorrowing(
        plan: financingPlan!,
        existingMortgageBalance: finance.totalMortgageBalance,
        existingNonMortgageDebt:
            state.totalKnownLiabilities - finance.totalMortgageBalance,
        existingMonthlyDebtService:
            finance.monthlyMortgagePayment +
            state.banking.monthlyUnsecuredDebtService,
        existingPropertyValue: finance.estimatedPropertyValueAt(state.day),
        targetPropertyValue: purchaseQuote!.marketPrice,
        existingPropertyCount: finance.realEstate.length,
        qualifyingMonthlyIncome: qualifyingMonthlyIncome.round(),
        creditScore: state.banking.creditScore,
        hasDelinquency:
            state.banking.hasDelinquentLoan ||
            state.story.flagInt('mortgageDeficiencyDebt') > 0 ||
            state.story.flagInt('tenantDepositDebt') > 0 ||
            state.personalFinance.realEstate.any(
              (asset) => asset.mortgageMissedPayments > 0,
            ),
        hasForeclosureHistory:
            state.story.flagInt('mortgageForeclosureCount') > 0 ||
            state.story.flagInt('tenantDepositAuctionCount') > 0,
      );
      if (!assessment.approved) {
        return FinanceActionResult(
          state: state,
          success: false,
          message: '대출 심사 거절: ${assessment.reason}',
        );
      }
    }
    if (option.isRealEstate && finance.ownsRealEstate(effectiveOptionId)) {
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
        finance.lastPurchasePeriods[effectiveOptionId] == period) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: option.repeat == SpendingRepeat.monthly
            ? '이번 달에는 이미 선택했습니다.'
            : '올해는 이미 선택했습니다.',
      );
    }
    if (state.bankCash < purchaseCost) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '은행 잔고가 ${purchaseCost - state.bankCash}원 부족합니다.',
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
          id: '$effectiveOptionId-${state.day}',
          optionId: effectiveOptionId,
          name: effectiveTitle,
          purchasePrice: purchaseBookValue,
          acquiredDay: state.day,
          monthlyIncome:
              listing?.monthlyRentAt(state.currentDate) ??
              option.monthlyIncomeAt(state.currentDate),
          monthlyCost:
              listing?.monthlyOperatingCostAt(state.currentDate) ??
              option.monthlyCostAt(state.currentDate),
          marketAssetId: listing?.asset.id ?? option.marketAssetId,
          marketPriceAtPurchase: purchaseQuote?.marketPrice ?? option.cost,
          acquisitionCosts: purchaseQuote?.acquisitionCosts ?? 0,
          purchaseDateIso: state.currentDate.toIso8601String(),
          marketListingIndex: listing?.index,
          realEstateWorldSeed: listing?.worldSeed ?? '',
          realEstateWorldVersion: realEstateWorldGeneratorVersion,
          propertyCondition: switch (listing?.condition) {
            RealEstateListingCondition.needsRepair => 45,
            RealEstateListingCondition.average => 70,
            RealEstateListingCondition.renovated => 90,
            null => 70,
          },
          cashInvestedAtPurchase: purchaseCost,
          mortgageOriginalPrincipal: financingPlan?.principal ?? 0,
          mortgageBalance: financingPlan?.principal ?? 0,
          mortgageAnnualInterestRate: financingPlan?.annualInterestRate ?? 0,
          mortgageTermMonths: financingPlan?.termMonths ?? 0,
          nextMortgagePaymentDay: financingPlan?.hasMortgage ?? false
              ? _firstBankLoanPaymentDay(state)
              : 0,
          leaseType: RealEstateLeaseType.vacant,
          nextRentalSettlementDay: _firstBankLoanPaymentDay(state),
          vacancyMonths: 0,
          lastRentalEvent: '매입 완료 · 세입자 모집을 시작했습니다.',
        ),
      );
    }
    final periods = {...finance.lastPurchasePeriods, effectiveOptionId: period};
    final nextFinance = finance.copyWith(
      realEstate: realEstate,
      permanentPurchases: permanentPurchases,
      lastPurchasePeriods: periods,
      totalSpent: finance.totalSpent + purchaseCost,
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
    final sourceId = 'spending-$effectiveOptionId-${state.day}-$period';
    final next = state.copyWith(
      cash: state.cash - purchaseCost,
      personalFinance: nextFinance,
      progression: state.progression.record('finance_purchases'),
      story: nextStory,
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -purchaseCost,
          notional: purchaseQuote?.marketPrice ?? option.cost,
          tradingFee: purchaseQuote?.acquisitionCosts ?? 0,
          account: 'company_bank',
          counterAccount: option.isRealEstate
              ? 'real_estate_asset'
              : 'discretionary_expense',
          description: effectiveTitle,
          sourceId: sourceId,
        ),
        if (financingPlan?.hasMortgage ?? false)
          LedgerEntry(
            id: '$sourceId-mortgage',
            day: state.day,
            amount: 0,
            notional: financingPlan!.principal,
            account: 'real_estate_asset',
            counterAccount: 'mortgage_payable',
            description:
                '$effectiveTitle 담보대출 LTV ${financingPlan.appliedLtvPercent}% · '
                '연 ${(financingPlan.annualInterestRate * 100).toStringAsFixed(2)}%',
            sourceId: sourceId,
          ),
      ],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      message: purchaseQuote == null
          ? '$effectiveTitle 지출이 장부에 반영됐습니다. 남은 현금 ${next.cash}원'
          : financingPlan?.hasMortgage ?? false
          ? '$effectiveTitle 매입: 현금 $purchaseCost원 + 대출 ${financingPlan!.principal}원'
                ' · 월 원리금 ${financingPlan.monthlyPayment}원 · 남은 현금 ${next.cash}원'
          : '$effectiveTitle 매입: 매매가 ${purchaseQuote.marketPrice}원'
                ' + 부대비용 ${purchaseQuote.acquisitionCosts}원 · 남은 현금 ${next.cash}원',
      cashDelta: -purchaseCost,
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
    if (asset.hasActiveLease) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '임대 계약이 끝나고 보증금을 정산한 뒤 매각할 수 있습니다.',
      );
    }
    if (state.day - asset.acquiredDay < 30) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '취득 후 30일이 지나야 매각할 수 있습니다.',
      );
    }
    if (asset.saleListedDay <= 0) {
      final listedWithoutOffer = asset.copyWith(saleListedDay: state.day);
      final offerIssuedDay = listedWithoutOffer.saleOfferReadyDay;
      final listed = listedWithoutOffer.copyWith(
        saleOfferAmount: listedWithoutOffer.estimatedSaleOfferValue(
          offerIssuedDay,
        ),
        saleOfferIssuedDay: offerIssuedDay,
        saleOfferExpiresDay: offerIssuedDay + realEstateSaleOfferValidityDays,
      );
      final nextAssets = [...assets]..[index] = listed;
      final sourceId = 'real-estate-listing-${asset.id}-${state.day}';
      final next = state.copyWith(
        personalFinance: state.personalFinance.copyWith(realEstate: nextAssets),
        ledger: [
          ...state.ledger,
          LedgerEntry(
            id: sourceId,
            day: state.day,
            amount: 0,
            account: 'real_estate_asset',
            counterAccount: 'property_sale_listing',
            description: '${asset.name} 매각 등록',
            sourceId: sourceId,
          ),
        ],
        processedEventIds: [...state.processedEventIds, sourceId],
      );
      return FinanceActionResult(
        state: next,
        success: true,
        message:
            '${asset.name}을 매물로 등록했습니다. '
            '${listed.saleListingDays}일 뒤 매수자 제안을 확인할 수 있습니다.',
      );
    }
    if (state.day < asset.saleOfferReadyDay) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '매수자 제안까지 ${asset.saleOfferReadyDay - state.day}일 남았습니다.',
      );
    }
    if (!asset.saleOfferActiveAt(state.day)) {
      final reset = asset.copyWith(
        saleListedDay: 0,
        saleOfferAmount: 0,
        saleOfferIssuedDay: 0,
        saleOfferExpiresDay: 0,
      );
      final nextAssets = [...assets]..[index] = reset;
      return FinanceActionResult(
        state: state.copyWith(
          personalFinance: state.personalFinance.copyWith(
            realEstate: nextAssets,
          ),
        ),
        success: true,
        message: '매수자 제안이 만료되었습니다. 매물을 다시 등록해 새 제안을 받아야 합니다.',
      );
    }
    final grossProceeds = asset.saleOfferAmount;
    final disposition = _realEstateDispositionPlan(
      state: state,
      asset: asset,
      voluntaryNetSaleBeforeTax: grossProceeds,
    );
    final waterfall = disposition.waterfall;
    final mortgagePayoff = waterfall.mortgagePaid;
    final mortgageShortfall = waterfall.mortgageDeficiency;
    final proceeds = waterfall.ownerProceeds - mortgageShortfall;
    if (mortgageShortfall > 0 && state.bankCash < mortgageShortfall) {
      return FinanceActionResult(
        state: state,
        success: false,
        message:
            '매각 순액이 부족합니다. 대출 상환 부족분 '
            '$mortgageShortfall원을 먼저 마련해야 합니다.',
      );
    }
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
          notional: disposition.dispositionPrice,
          disposedCost: asset.purchasePrice,
          realizedPnl:
              waterfall.netSaleBeforeTax -
              waterfall.capitalGainsTax -
              asset.purchasePrice,
          account: 'company_bank',
          counterAccount: 'real_estate_sale',
          description: '${asset.name} 매각',
          sourceId: sourceId,
        ),
        if (waterfall.capitalGainsTax > 0)
          LedgerEntry(
            id: '$sourceId-capital-gains-tax',
            day: state.day,
            amount: 0,
            notional: waterfall.capitalGainsTax,
            account: 'real_estate_sale',
            counterAccount: 'property_capital_gains_tax',
            description: '${asset.name} 양도소득세·단기매매 중과',
            sourceId: sourceId,
          ),
        if (mortgagePayoff > 0)
          LedgerEntry(
            id: '$sourceId-mortgage-payoff',
            day: state.day,
            amount: 0,
            notional: mortgagePayoff,
            account: 'mortgage_payable',
            counterAccount: 'real_estate_sale',
            description: '${asset.name} 매각과 동시에 담보대출 상환',
            sourceId: sourceId,
          ),
        if (disposition.saleCosts > 0)
          LedgerEntry(
            id: '$sourceId-sale-costs',
            day: state.day,
            amount: 0,
            notional: disposition.saleCosts,
            account: 'real_estate_sale',
            counterAccount: 'property_sale_cost',
            description: '${asset.name} 매각 중개·처분비용',
            sourceId: sourceId,
          ),
      ],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      message:
          '${asset.name} 매수자 제안 $grossProceeds원을 수락했습니다. '
          '대출 ${asset.mortgageBalance}원 · 양도세 '
          '${waterfall.capitalGainsTax}원을 정산해 '
          '순액 $proceeds원이 반영됐습니다.',
      cashDelta: proceeds,
    );
  }

  FinanceActionResult cancelRealEstateSaleListing(
    GameState state,
    String assetId,
  ) {
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
    if (asset.saleListedDay <= 0) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '현재 매각 등록된 자산이 아닙니다.',
      );
    }
    final reset = asset.copyWith(
      saleListedDay: 0,
      saleOfferAmount: 0,
      saleOfferIssuedDay: 0,
      saleOfferExpiresDay: 0,
    );
    final nextAssets = [...assets]..[index] = reset;
    final sourceId = 'real-estate-listing-cancel-${asset.id}-${state.day}';
    return FinanceActionResult(
      state: state.copyWith(
        personalFinance: state.personalFinance.copyWith(realEstate: nextAssets),
        ledger: [
          ...state.ledger,
          LedgerEntry(
            id: sourceId,
            day: state.day,
            amount: 0,
            account: 'real_estate_asset',
            counterAccount: 'property_sale_listing_cancel',
            description: '${asset.name} 매각 등록 취소',
            sourceId: sourceId,
          ),
        ],
        processedEventIds: [...state.processedEventIds, sourceId],
      ),
      success: true,
      message: '${asset.name} 매각 등록을 취소했습니다.',
    );
  }

  FinanceActionResult saveRealEstateInvestmentNote(
    GameState state,
    String assetId,
    String note,
  ) {
    final assets = state.personalFinance.realEstate;
    final index = assets.indexWhere((asset) => asset.id == assetId);
    if (index < 0) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '보유 부동산을 찾지 못했습니다.',
      );
    }
    final trimmed = note.trim();
    final normalized = trimmed.length <= gameRealEstateInvestmentNoteMaxLength
        ? trimmed
        : trimmed.substring(0, gameRealEstateInvestmentNoteMaxLength);
    final nextAssets = [...assets]
      ..[index] = assets[index].copyWith(investmentNote: normalized);
    return FinanceActionResult(
      state: state.copyWith(
        personalFinance: state.personalFinance.copyWith(realEstate: nextAssets),
      ),
      success: true,
      message: normalized.isEmpty ? '투자 메모를 지웠습니다.' : '투자 메모를 저장했습니다.',
    );
  }

  FinanceActionResult renovateRealEstate(GameState state, String assetId) {
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
    if (asset.isLandmarkFund) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '랜드마크 지분은 직접 리모델링할 수 없습니다.',
      );
    }
    if (asset.hasActiveLease) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '임대차 계약이 끝난 뒤 리모델링할 수 있습니다.',
      );
    }
    if (asset.propertyCondition >= 100) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '이미 최상 상태입니다.',
      );
    }
    final cost = realEstateRenovationCost(
      asset.estimatedMarketValue(state.day),
    );
    if (state.bankCash < cost) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '리모델링 비용이 ${cost - state.bankCash}원 부족합니다.',
      );
    }
    final conditionGain = math.min(25, 100 - asset.propertyCondition);
    final updated = asset.copyWith(
      propertyCondition: asset.propertyCondition + conditionGain,
      lastRentalEvent: '리모델링 완료 · 상태 +$conditionGain',
      saleListedDay: 0,
      saleOfferAmount: 0,
      saleOfferIssuedDay: 0,
      saleOfferExpiresDay: 0,
    );
    final nextAssets = [...assets]..[index] = updated;
    final sourceId = 'real-estate-renovation-${asset.id}-${state.day}';
    final next = state.copyWith(
      cash: state.cash - cost,
      personalFinance: state.personalFinance.copyWith(realEstate: nextAssets),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -cost,
          notional: cost,
          account: 'company_bank',
          counterAccount: 'property_renovation',
          description: '${asset.name} 리모델링 · 상태 +$conditionGain',
          sourceId: sourceId,
        ),
      ],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      cashDelta: -cost,
      message:
          '${asset.name} 리모델링을 마쳤습니다. '
          '상태 ${updated.propertyCondition}/100 · 비용 $cost원',
    );
  }

  FinanceActionResult setRealEstateInsurance(
    GameState state,
    String assetId,
    bool active,
  ) {
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
    if (asset.isLandmarkFund) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '랜드마크 지분의 보험은 운용사가 관리합니다.',
      );
    }
    if (asset.insuranceActive == active) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: active ? '이미 재산보험에 가입되어 있습니다.' : '가입된 재산보험이 없습니다.',
      );
    }
    final updated = asset.copyWith(insuranceActive: active);
    final nextAssets = [...assets]..[index] = updated;
    final sourceId =
        'real-estate-insurance-${active ? 'start' : 'stop'}-${asset.id}-${state.day}';
    return FinanceActionResult(
      state: state.copyWith(
        personalFinance: state.personalFinance.copyWith(realEstate: nextAssets),
        ledger: [
          ...state.ledger,
          LedgerEntry(
            id: sourceId,
            day: state.day,
            amount: 0,
            account: 'real_estate_asset',
            counterAccount: 'property_insurance_contract',
            description: '${asset.name} 재산보험 ${active ? '가입' : '해지'}',
            sourceId: sourceId,
          ),
        ],
        processedEventIds: [...state.processedEventIds, sourceId],
      ),
      success: true,
      message: active
          ? '재산보험에 가입했습니다. 다음 정산일부터 월 보험료가 청구됩니다.'
          : '재산보험을 해지했습니다.',
    );
  }

  FinanceActionResult configureRealEstateLease(
    GameState state,
    String assetId,
    RealEstateLeaseType leaseType,
  ) {
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
    if (leaseType == RealEstateLeaseType.automatic) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '기존 자동운영으로 되돌릴 수 없습니다.',
      );
    }
    if (asset.hasActiveLease && asset.leaseRemainingMonths > 0) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '현재 임대차 계약이 끝난 뒤에 운영 방식을 바꿀 수 있습니다.',
      );
    }
    if (asset.optionId == 'owner_office' ||
        asset.optionId == 'family_home_trust') {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '직접 사용하는 사무실·가족 주택은 임대할 수 없습니다.',
      );
    }
    final assetType =
        asset.marketAsset?.type ?? RealEstateAssetType.commercialUnit;
    if (!realEstateSupportsManagedLease(assetType)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '랜드마크 지분은 직접 임대차 계약을 맺을 수 없습니다.',
      );
    }
    if (leaseType == RealEstateLeaseType.jeonse &&
        !realEstateSupportsJeonse(assetType)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '전세는 주거·오피스텔 자산에서만 선택할 수 있습니다.',
      );
    }
    final listingRisk = asset.generatedListing?.riskFactorsAt(
      state.currentDate,
    );
    final tenantSearchMonths = realEstateTenantSearchMonths(
      worldSeed: asset.realEstateWorldSeed.isEmpty
          ? state.simulationSeed
          : asset.realEstateWorldSeed,
      assetId: asset.id,
      vacancyMultiplier: listingRisk?.vacancyMultiplier ?? 1,
    );
    if (leaseType != RealEstateLeaseType.vacant &&
        asset.vacancyMonths < tenantSearchMonths) {
      return FinanceActionResult(
        state: state,
        success: false,
        message:
            '세입자 모집이 ${tenantSearchMonths - asset.vacancyMonths}개월 남았습니다. '
            '현재 ${asset.vacancyMonths}/$tenantSearchMonths개월입니다.',
      );
    }
    final baseMarketRent =
        asset.generatedListing?.monthlyRentAt(state.currentDate) ??
        asset.marketAsset?.monthlyRentAt(state.currentDate) ??
        asset.monthlyIncome;
    final marketRent = (baseMarketRent * asset.conditionRentMultiplier).round();
    final terms = realEstateLeaseTermsAt(
      date: state.currentDate,
      type: assetType,
      leaseType: leaseType,
      marketValue: asset.estimatedMarketValue(state.day),
      marketMonthlyRent: marketRent,
      mortgageBalance: asset.mortgageBalance,
    );
    if (leaseType == RealEstateLeaseType.jeonse && terms.deposit <= 0) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '담보대출 잔액 때문에 받을 수 있는 전세보증금 한도가 없습니다.',
      );
    }
    if (leaseType != RealEstateLeaseType.vacant && assets.length > 1) {
      final existingDeposit = asset.hasActiveLease ? asset.leaseDeposit : 0;
      final afterLiabilities =
          state.totalKnownLiabilities - existingDeposit + terms.deposit;
      final portfolioValue = state.personalFinance.estimatedPropertyValueAt(
        state.day,
      );
      final maximumPortfolioDebt =
          (portfolioValue * realEstateAdditionalPropertyDebtRate).floor();
      if (afterLiabilities > maximumPortfolioDebt) {
        return FinanceActionResult(
          state: state,
          success: false,
          message:
              '임대보증금을 포함한 포트폴리오 총부채가 '
              '${(realEstateAdditionalPropertyDebtRate * 100).round()}% '
              '한도를 넘습니다.',
        );
      }
    }
    if (terms.initialCashDelta < 0 &&
        state.bankCash < -terms.initialCashDelta) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '임대 중개·입주 정비비를 낼 회사 통장 현금이 부족합니다.',
      );
    }
    final reliability = leaseType == RealEstateLeaseType.vacant
        ? 0
        : realEstateTenantReliability(
            worldSeed: asset.realEstateWorldSeed.isEmpty
                ? state.simulationSeed
                : asset.realEstateWorldSeed,
            assetId: asset.id,
            contractDate: state.currentDate,
            leaseType: leaseType,
          );
    final updated = asset.copyWith(
      leaseType: leaseType,
      leaseDeposit: terms.deposit,
      leaseMonthlyRent: terms.monthlyRent,
      leaseRemainingMonths: terms.contractMonths,
      nextRentalSettlementDay: _firstBankLoanPaymentDay(state),
      tenantReliability: reliability,
      rentArrearsMonths: 0,
      vacancyMonths: leaseType == RealEstateLeaseType.vacant
          ? asset.vacancyMonths
          : 0,
      lastRentalEvent: leaseType == RealEstateLeaseType.vacant
          ? '공실 전환 · 세입자 모집 ${asset.vacancyMonths}/$tenantSearchMonths개월'
          : '${leaseType.label} 계약 체결 · 담보+보증금 합산 한도 적용',
      saleListedDay: 0,
      saleOfferAmount: 0,
      saleOfferIssuedDay: 0,
      saleOfferExpiresDay: 0,
    );
    final nextAssets = [...assets]..[index] = updated;
    final sourceId =
        'real-estate-lease-${asset.id}-${leaseType.name}-${state.day}';
    final next = state.copyWith(
      cash: state.cash + terms.initialCashDelta,
      personalFinance: state.personalFinance.copyWith(realEstate: nextAssets),
      ledger: [
        ...state.ledger,
        if (terms.deposit > 0)
          LedgerEntry(
            id: '$sourceId-deposit',
            day: state.day,
            amount: terms.deposit,
            notional: terms.deposit,
            account: 'company_bank',
            counterAccount: 'tenant_deposit_payable',
            description: '${asset.name} ${leaseType.label} 보증금 수령',
            sourceId: sourceId,
          ),
        if (terms.placementFee > 0)
          LedgerEntry(
            id: '$sourceId-fee',
            day: state.day,
            amount: -terms.placementFee,
            account: 'company_bank',
            counterAccount: 'rental_placement_fee',
            description: '${asset.name} 임대 중개·입주 정비비',
            sourceId: sourceId,
          ),
      ],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      message: leaseType == RealEstateLeaseType.vacant
          ? '${asset.name}을 공실로 전환했습니다.'
          : '${asset.name} ${leaseType.label} 계약: 보증금 ${terms.deposit}원'
                '${terms.monthlyRent > 0 ? ' · 월세 ${terms.monthlyRent}원' : ''}'
                ' · ${terms.contractMonths}개월 · 세입자 신뢰도 $reliability'
                ' · 담보+보증금 ${(asset.mortgageBalance + terms.deposit) * 100 ~/ math.max(1, asset.estimatedMarketValue(state.day))}%',
      cashDelta: terms.initialCashDelta,
    );
  }

  FinanceActionResult renewRealEstateMonthlyLease(
    GameState state,
    String assetId,
  ) {
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
    if (asset.leaseType != RealEstateLeaseType.monthlyRent ||
        asset.leaseRemainingMonths <= 0) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '갱신할 활성 월세 계약이 없습니다.',
      );
    }
    if (asset.leaseRemainingMonths > 3) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '계약 만료 3개월 전부터 갱신할 수 있습니다.',
      );
    }
    if (asset.rentArrearsMonths > 0) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '밀린 월세를 먼저 정산해야 계약을 갱신할 수 있습니다.',
      );
    }
    final baseMarketRent =
        asset.generatedListing?.monthlyRentAt(state.currentDate) ??
        asset.marketAsset?.monthlyRentAt(state.currentDate) ??
        asset.monthlyIncome;
    final marketRent = (baseMarketRent * asset.conditionRentMultiplier).round();
    final terms = realEstateLeaseTermsAt(
      date: state.currentDate,
      type: asset.assetType,
      leaseType: RealEstateLeaseType.monthlyRent,
      marketValue: asset.estimatedMarketValue(state.day),
      marketMonthlyRent: marketRent,
      mortgageBalance: asset.mortgageBalance,
    );
    final depositDelta = terms.deposit - asset.leaseDeposit;
    final renewalFee = math.max(100000, terms.monthlyRent ~/ 2);
    final cashDelta = depositDelta - renewalFee;
    if (cashDelta < 0 && state.bankCash < -cashDelta) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '보증금 차액·갱신 비용이 ${-cashDelta - state.bankCash}원 부족합니다.',
      );
    }
    if (assets.length > 1) {
      final afterLiabilities =
          state.totalKnownLiabilities - asset.leaseDeposit + terms.deposit;
      final portfolioValue = state.personalFinance.estimatedPropertyValueAt(
        state.day,
      );
      if (afterLiabilities >
          (portfolioValue * realEstateAdditionalPropertyDebtRate).floor()) {
        return FinanceActionResult(
          state: state,
          success: false,
          message: '갱신 후 보증금을 포함한 포트폴리오 총부채가 60% 한도를 넘습니다.',
        );
      }
    }
    final updated = asset.copyWith(
      leaseDeposit: terms.deposit,
      leaseMonthlyRent: terms.monthlyRent,
      leaseRemainingMonths: terms.contractMonths,
      tenantReliability: math.min(100, asset.tenantReliability + 3),
      lastRentalEvent: '월세 계약 갱신 · ${terms.contractMonths}개월',
      saleListedDay: 0,
      saleOfferAmount: 0,
      saleOfferIssuedDay: 0,
      saleOfferExpiresDay: 0,
    );
    final nextAssets = [...assets]..[index] = updated;
    final sourceId = 'real-estate-lease-renewal-${asset.id}-${state.day}';
    final next = state.copyWith(
      cash: state.cash + cashDelta,
      personalFinance: state.personalFinance.copyWith(realEstate: nextAssets),
      ledger: [
        ...state.ledger,
        if (depositDelta != 0)
          LedgerEntry(
            id: '$sourceId-deposit',
            day: state.day,
            amount: depositDelta,
            notional: depositDelta.abs(),
            account: 'company_bank',
            counterAccount: 'tenant_deposit_payable',
            description: '${asset.name} 갱신 보증금 차액 정산',
            sourceId: sourceId,
          ),
        LedgerEntry(
          id: '$sourceId-fee',
          day: state.day,
          amount: -renewalFee,
          account: 'company_bank',
          counterAccount: 'rental_renewal_fee',
          description: '${asset.name} 월세 계약 갱신 비용',
          sourceId: sourceId,
        ),
      ],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      cashDelta: cashDelta,
      message:
          '${asset.name} 월세 계약을 ${terms.contractMonths}개월 갱신했습니다. '
          '월세 ${terms.monthlyRent}원 · 보증금 ${terms.deposit}원',
    );
  }

  FinanceActionResult terminateRealEstateMonthlyLeaseEarly(
    GameState state,
    String assetId,
  ) {
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
    if (asset.leaseType != RealEstateLeaseType.monthlyRent ||
        asset.leaseRemainingMonths <= 0) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '중도 종료할 활성 월세 계약이 없습니다.',
      );
    }
    final rentClaim = math.min(
      asset.leaseDeposit,
      asset.leaseMonthlyRent * asset.rentArrearsMonths,
    );
    final depositRefund = asset.leaseDeposit - rentClaim;
    final legalCost = realEstateEarlyLeaseTerminationLegalCost(
      asset.leaseMonthlyRent,
    );
    final totalCashRequired = depositRefund + legalCost;
    if (state.bankCash < totalCashRequired) {
      return FinanceActionResult(
        state: state,
        success: false,
        message:
            '보증금 반환·중도 종료 비용이 '
            '${totalCashRequired - state.bankCash}원 부족합니다.',
      );
    }
    final updated = asset.copyWith(
      leaseType: RealEstateLeaseType.vacant,
      leaseDeposit: 0,
      leaseMonthlyRent: 0,
      leaseRemainingMonths: 0,
      nextRentalSettlementDay: _firstBankLoanPaymentDay(state),
      tenantReliability: 0,
      rentArrearsMonths: 0,
      vacancyMonths: 0,
      lastRentalEvent: '임대인 중도 종료 · 보증금·법적비용 정산 · 공실 전환',
    );
    final nextAssets = [...assets]..[index] = updated;
    final sourceId = 'real-estate-lease-early-end-${asset.id}-${state.day}';
    final next = state.copyWith(
      cash: state.cash - totalCashRequired,
      personalFinance: state.personalFinance.copyWith(realEstate: nextAssets),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: '$sourceId-deposit',
          day: state.day,
          amount: -depositRefund,
          notional: asset.leaseDeposit,
          account: 'tenant_deposit_payable',
          counterAccount: 'company_bank',
          description: '${asset.name} 월세 계약 중도 종료 보증금 반환',
          sourceId: sourceId,
        ),
        if (rentClaim > 0)
          LedgerEntry(
            id: '$sourceId-rent-offset',
            day: state.day,
            amount: 0,
            notional: rentClaim,
            account: 'tenant_deposit_payable',
            counterAccount: 'rent_receivable',
            description: '${asset.name} 보증금에서 밀린 월세 상계',
            sourceId: sourceId,
          ),
        LedgerEntry(
          id: '$sourceId-legal',
          day: state.day,
          amount: -legalCost,
          notional: legalCost,
          account: 'company_bank',
          counterAccount: 'tenant_termination_legal_cost',
          description: '${asset.name} 임대인 중도 종료 법적·합의 비용',
          sourceId: sourceId,
        ),
      ],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      cashDelta: -totalCashRequired,
      message:
          '${asset.name} 월세 계약을 중도 종료했습니다. '
          '보증금 $depositRefund원 · 비용 $legalCost원을 정산했습니다.',
    );
  }

  FinanceActionResult prepayRealEstateMortgage(
    GameState state,
    String assetId,
    int amount,
  ) {
    final assets = state.personalFinance.realEstate;
    final index = assets.indexWhere((asset) => asset.id == assetId);
    if (index < 0 || amount <= 0) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: index < 0 ? '보유 부동산을 찾지 못했습니다.' : '상환액은 0원보다 커야 합니다.',
      );
    }
    final asset = assets[index];
    if (!asset.hasMortgage) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '상환할 담보대출이 없습니다.',
      );
    }
    final principalPayment = math.min(amount, asset.mortgageBalance);
    final fee = (principalPayment * realEstateMortgagePrepaymentFeeRate)
        .round();
    final totalCash = principalPayment + fee;
    if (state.bankCash < totalCash) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '은행 잔고가 ${totalCash - state.bankCash}원 부족합니다.',
      );
    }
    final remainingBalance = asset.mortgageBalance - principalPayment;
    final updated = asset.copyWith(
      mortgageBalance: remainingBalance,
      mortgageOriginalPrincipal: remainingBalance == 0
          ? 0
          : asset.mortgageOriginalPrincipal,
      mortgageAnnualInterestRate: remainingBalance == 0
          ? 0
          : asset.mortgageAnnualInterestRate,
      mortgageTermMonths: remainingBalance == 0 ? 0 : asset.mortgageTermMonths,
      nextMortgagePaymentDay: remainingBalance == 0
          ? 0
          : asset.nextMortgagePaymentDay,
      mortgageIsVariableRate: remainingBalance == 0
          ? false
          : asset.mortgageIsVariableRate,
      mortgageMissedPayments: 0,
    );
    final nextAssets = [...assets]..[index] = updated;
    final sourceId = 'mortgage-prepayment-${asset.id}-${state.day}';
    final next = state.copyWith(
      cash: state.cash - totalCash,
      personalFinance: state.personalFinance.copyWith(realEstate: nextAssets),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -totalCash,
          notional: principalPayment,
          tradingFee: fee,
          account: 'company_bank',
          counterAccount: 'mortgage_prepayment',
          description: '${asset.name} 담보대출 중도상환 · 수수료 $fee원',
          sourceId: sourceId,
        ),
      ],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      cashDelta: -totalCash,
      message:
          '담보대출 원금 $principalPayment원을 중도상환했습니다. '
          '남은 잔액 $remainingBalance원입니다.',
    );
  }

  FinanceActionResult refinanceRealEstateMortgage(
    GameState state,
    String assetId, {
    required bool variableRate,
    int? termMonths,
  }) {
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
    if (!asset.hasMortgage) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '대환할 담보대출이 없습니다.',
      );
    }
    final hasBlockingDebt =
        state.banking.hasDelinquentLoan ||
        asset.mortgageMissedPayments > 0 ||
        state.story.flagInt('mortgageDeficiencyDebt') > 0 ||
        state.story.flagInt('tenantDepositDebt') > 0;
    if (hasBlockingDebt ||
        state.banking.creditScore < realEstateMinimumMortgageCreditScore) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '연체·결손채무를 정리하고 신용점수 600점 이상을 회복해야 대환할 수 있습니다.',
      );
    }
    final terms = realEstateFinancingTermsAt(
      state.currentDate,
      asset.assetType,
    );
    if (!terms.available) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '현재 시기·자산 유형에는 대환 가능한 담보대출 상품이 없습니다.',
      );
    }
    final currentValue = asset.estimatedMarketValue(state.day);
    final maximumBalance = (currentValue * terms.maxLtvPercent / 100).floor();
    if (asset.mortgageBalance > maximumBalance) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '현재 LTV가 대환 한도를 초과합니다.',
      );
    }
    final resolvedTerm = (termMonths ?? terms.termMonths)
        .clamp(60, 360)
        .toInt();
    final newRate = math.max(
      0.001,
      terms.annualInterestRate -
          (variableRate ? realEstateVariableMortgageDiscountRate : 0),
    );
    final newPayment = mortgageMonthlyPayment(
      asset.mortgageBalance,
      newRate,
      resolvedTerm,
    );
    final otherDebtService =
        state.personalFinance.monthlyMortgagePayment -
        asset.monthlyMortgagePayment +
        state.banking.monthlyUnsecuredDebtService;
    final qualifyingIncome = gameQualifyingRecurringMonthlyIncome(state);
    if (otherDebtService + newPayment >
        (qualifyingIncome * realEstateMaximumDsrRate).floor()) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '대환 후 원리금이 DSR 45% 한도를 넘습니다.',
      );
    }
    final fee = math.max(100000, (asset.mortgageBalance * 0.005).round());
    if (state.bankCash < fee) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '대환 비용이 ${fee - state.bankCash}원 부족합니다.',
      );
    }
    final updated = asset.copyWith(
      mortgageOriginalPrincipal: asset.mortgageBalance,
      mortgageAnnualInterestRate: newRate,
      mortgageTermMonths: resolvedTerm,
      mortgagePaymentsMade: 0,
      mortgageMissedPayments: 0,
      nextMortgagePaymentDay: _firstBankLoanPaymentDay(state),
      mortgageIsVariableRate: variableRate,
    );
    final nextAssets = [...assets]..[index] = updated;
    final sourceId = 'mortgage-refinance-${asset.id}-${state.day}';
    final next = state.copyWith(
      cash: state.cash - fee,
      personalFinance: state.personalFinance.copyWith(realEstate: nextAssets),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -fee,
          notional: asset.mortgageBalance,
          tradingFee: fee,
          account: 'company_bank',
          counterAccount: 'mortgage_refinance',
          description:
              '${asset.name} 담보대출 대환 · '
              '${variableRate ? '변동' : '고정'}금리 '
              '${(newRate * 100).toStringAsFixed(2)}%',
          sourceId: sourceId,
        ),
      ],
      processedEventIds: [...state.processedEventIds, sourceId],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      cashDelta: -fee,
      message:
          '${asset.name} 담보대출을 '
          '${variableRate ? '변동' : '고정'}금리로 대환했습니다.',
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
    if (!isMarketTradingDay(state.currentDate)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '휴장일에는 당일 시장 조사 보고서를 구매할 수 없습니다.',
      );
    }
    if (state.marketMinute >= krxCloseMinute) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '오늘 장이 끝나 새로 조사할 장중 신호가 없습니다.',
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

    final preferredAssetIds = <String>{
      ...state.positions.map((position) => position.assetId),
      ...((flags['marketFavoriteAssetIds'] as List?) ?? const [])
          .whereType<String>(),
    };
    final events =
        fictionalMarketEventsForDate(
            state.simulationSeed,
            state.currentDate,
          ).where((event) => event.revealMinute > state.marketMinute).toList()
          ..sort((left, right) {
            final leftPreferred = preferredAssetIds.contains(left.companyId);
            final rightPreferred = preferredAssetIds.contains(right.companyId);
            if (leftPreferred != rightPreferred) {
              return leftPreferred ? -1 : 1;
            }
            final impactOrder = right.impactPct.abs().compareTo(
              left.impactPct.abs(),
            );
            if (impactOrder != 0) return impactOrder;
            final timeOrder = left.revealMinute.compareTo(right.revealMinute);
            return timeOrder != 0 ? timeOrder : left.id.compareTo(right.id);
          });
    if (events.isEmpty) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '현재 시각 이후에 조사할 미공개 시장 신호가 없습니다.',
      );
    }
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
    reports[dateKey] = signals;
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

  GameState _settleMatureBankDeposits(GameState state) {
    var next = state;
    final maturedIds = state.banking.termDeposits
        .where((deposit) => deposit.maturedAt(state.day))
        .map((deposit) => deposit.id)
        .toList(growable: false);
    for (final depositId in maturedIds) {
      final result = redeemTimeDeposit(next, depositId);
      if (result.success) next = result.state;
    }
    return next;
  }

  GameState advanceOneDay(
    GameState state, {
    Map<String, GamePendingOrderQuotePath> pendingOrderQuotePaths = const {},
  }) {
    if (state.pendingDecisions.isNotEmpty || state.campaignComplete) {
      return state;
    }
    if (state.pendingOrders.isNotEmpty) {
      final missingAssetIds = state.pendingOrders
          .map((order) => order.assetId)
          .toSet()
          .where(
            (assetId) =>
                pendingOrderQuotePaths[assetId] == null ||
                pendingOrderQuotePaths[assetId]!.prices.isEmpty,
          )
          .toList(growable: false);
      if (missingAssetIds.isNotEmpty) {
        throw ArgumentError(
          'Pending orders require non-empty deterministic quote paths: '
          '${missingAssetIds.join(', ')}',
        );
      }
    }
    final replayed =
        state.pendingOrders.isNotEmpty && pendingOrderQuotePaths.isNotEmpty
        ? processPendingOrdersThroughMarketMinute(
            state,
            targetMinute: krxCloseMinute,
            quotePaths: pendingOrderQuotePaths,
          )
        : state;
    final settled = replayed.copyWith(marketMinute: krxCloseMinute);
    var next = settled.copyWith(
      day: state.day + 1,
      marketMinute: marketDayStartMinute,
      progression: state.progression.record('days_advanced'),
      organization: state.organization.recoverOneDay(),
    );
    next = _refreshExpiredMissionWindow(next);
    next = _settleMatureBankDeposits(next);
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

  _RentalMonthPreparation _prepareRentalMonth(
    GameState state,
    String sourceId,
  ) {
    final assets = <OwnedRealEstate>[];
    final expiringAssetIds = <String>{};
    final entries = <LedgerEntry>[];
    var rentalIncome = 0;
    var operatingCost = 0;
    var repairCost = 0;
    var insurancePremium = 0;
    for (final asset in state.personalFinance.realEstate) {
      if (asset.nextRentalSettlementDay > state.day) {
        assets.add(asset);
        continue;
      }
      final followingSettlementDay = _followingMonthlyPaymentDay(state);
      operatingCost += asset.monthlyCostAt(state.currentDate);
      if (asset.insuranceActive) {
        final premium = realEstateMonthlyInsurancePremium(
          asset.estimatedMarketValue(state.day),
        );
        insurancePremium += premium;
        entries.add(
          LedgerEntry(
            id: '$sourceId-property-insurance-${asset.id}',
            day: state.day,
            amount: 0,
            notional: premium,
            account: 'property_insurance_expense',
            counterAccount: 'property_insurance_payable',
            description: '${asset.name} 재산보험 월 보험료',
            sourceId: sourceId,
          ),
        );
      }
      if (asset.isDirectUse) {
        assets.add(
          asset.copyWith(
            nextRentalSettlementDay: followingSettlementDay,
            lastRentalEvent: '직접 사용 중 · 공실 위험 없음',
            propertyCondition:
                (asset.propertyCondition -
                        (state.currentDate.month == 1 ? 1 : 0))
                    .clamp(0, 100)
                    .toInt(),
          ),
        );
        continue;
      }
      if (asset.isLandmarkFund) {
        final distribution = asset.monthlyIncomeAt(state.currentDate);
        rentalIncome += distribution;
        assets.add(
          asset.copyWith(
            nextRentalSettlementDay: followingSettlementDay,
            lastRentalEvent: distribution > 0
                ? '랜드마크 지분 월 분배금 $distribution원'
                : '랜드마크 지분 월 분배 없음',
          ),
        );
        continue;
      }
      if (asset.leaseType == RealEstateLeaseType.automatic) {
        final vacancyMonths = asset.vacancyMonths + 1;
        assets.add(
          asset.copyWith(
            leaseType: RealEstateLeaseType.vacant,
            leaseDeposit: 0,
            leaseMonthlyRent: 0,
            leaseRemainingMonths: 0,
            nextRentalSettlementDay: followingSettlementDay,
            tenantReliability: 0,
            rentArrearsMonths: 0,
            vacancyMonths: vacancyMonths,
            totalVacancyMonths: asset.totalVacancyMonths + 1,
            lastRentalEvent: '기존 자동운영 종료 · 공실 $vacancyMonths개월',
          ),
        );
        continue;
      }
      final listingRisk = asset.generatedListing?.riskFactorsAt(
        state.currentDate,
      );
      final marketValue = asset.estimatedMarketValue(state.day);
      final incident = realEstateRentalIncidentAt(
        worldSeed: asset.realEstateWorldSeed.isEmpty
            ? state.simulationSeed
            : asset.realEstateWorldSeed,
        assetId: asset.id,
        date: state.currentDate,
        tenantReliability: asset.tenantReliability,
        marketValue: marketValue,
        baseMonthlyCost: asset.monthlyCostAt(state.currentDate),
        rentBearing: asset.leaseType == RealEstateLeaseType.monthlyRent,
        repairProbabilityMultiplier:
            (listingRisk?.repairProbabilityMultiplier ?? 1) *
            asset.conditionRepairProbabilityMultiplier,
        repairCostMultiplier:
            (listingRisk?.repairCostMultiplier ?? 1) *
            asset.conditionRepairCostMultiplier,
      );
      var arrears = asset.rentArrearsMonths;
      var vacancyMonths = asset.vacancyMonths;
      var eventLabel = incident.incident.label;
      var forcedEviction = false;
      if (asset.leaseType == RealEstateLeaseType.vacant) {
        vacancyMonths += 1;
        eventLabel = incident.totalUnexpectedCost > 0
            ? '공실 $vacancyMonths개월 · ${incident.incident.label}'
            : '공실 $vacancyMonths개월';
      } else if (asset.leaseType == RealEstateLeaseType.monthlyRent) {
        if (incident.incident == RealEstateRentalIncident.tenantDefault) {
          arrears += 1;
          forcedEviction = true;
          eventLabel = '상습 연체 · 강제퇴거 · 월세 $arrears개월 미수';
          entries.add(
            LedgerEntry(
              id: '$sourceId-rent-default-${asset.id}',
              day: state.day,
              amount: 0,
              notional: asset.leaseMonthlyRent * arrears,
              account: 'rent_receivable',
              counterAccount: 'tenant_default_loss',
              description: '${asset.name} 상습 연체·강제퇴거',
              sourceId: sourceId,
            ),
          );
        } else if (incident.incident == RealEstateRentalIncident.lateRent) {
          arrears += 1;
          eventLabel = '월세 $arrears개월 연체';
          entries.add(
            LedgerEntry(
              id: '$sourceId-rent-arrears-${asset.id}',
              day: state.day,
              amount: 0,
              notional: asset.leaseMonthlyRent,
              account: 'rent_receivable',
              counterAccount: 'tenant_rent_arrears',
              description: '${asset.name} 월세 연체',
              sourceId: sourceId,
            ),
          );
        } else {
          final recoveredArrears = (asset.leaseMonthlyRent * arrears * 0.80)
              .round();
          final writtenOffArrears =
              asset.leaseMonthlyRent * arrears - recoveredArrears;
          rentalIncome += asset.leaseMonthlyRent + recoveredArrears;
          if (arrears > 0) {
            eventLabel =
                '밀린 월세 $arrears개월분 중 80% 회수'
                '${writtenOffArrears > 0 ? ' · $writtenOffArrears원 손실' : ''}';
          }
          if (writtenOffArrears > 0) {
            entries.add(
              LedgerEntry(
                id: '$sourceId-rent-writeoff-${asset.id}',
                day: state.day,
                amount: 0,
                notional: writtenOffArrears,
                account: 'bad_debt_expense',
                counterAccount: 'rent_receivable',
                description: '${asset.name} 밀린 월세 일부 회수불능',
                sourceId: sourceId,
              ),
            );
          }
          arrears = 0;
        }
      }
      final insuranceRecovery =
          asset.insuranceActive &&
              incident.incident == RealEstateRentalIncident.majorRepair
          ? realEstateMajorRepairInsuranceRecovery(
              marketValue: marketValue,
              repairCost: incident.repairCost,
            )
          : 0;
      final outOfPocketUnexpectedCost = math.max(
        0,
        incident.totalUnexpectedCost - insuranceRecovery,
      );
      if (incident.totalUnexpectedCost > 0) {
        repairCost += outOfPocketUnexpectedCost;
        entries.add(
          LedgerEntry(
            id: '$sourceId-repair-${asset.id}',
            day: state.day,
            amount: 0,
            notional: incident.totalUnexpectedCost,
            account: 'property_maintenance',
            counterAccount: incident.legalCost > 0
                ? 'tenant_eviction_legal_cost'
                : 'rental_repair_event',
            description: '${asset.name} ${incident.incident.label}',
            sourceId: sourceId,
          ),
        );
        if (insuranceRecovery > 0) {
          entries.add(
            LedgerEntry(
              id: '$sourceId-insurance-recovery-${asset.id}',
              day: state.day,
              amount: 0,
              notional: insuranceRecovery,
              account: 'insurance_claim_receivable',
              counterAccount: 'property_maintenance',
              description: '${asset.name} 대형수리 보험 보상',
              sourceId: sourceId,
            ),
          );
        }
      }
      final remainingMonths = forcedEviction
          ? 0
          : asset.hasActiveLease
          ? math.max(0, asset.leaseRemainingMonths - 1)
          : 0;
      final updated = asset.copyWith(
        leaseRemainingMonths: remainingMonths,
        nextRentalSettlementDay: followingSettlementDay,
        rentArrearsMonths: arrears,
        vacancyMonths: vacancyMonths,
        totalVacancyMonths:
            asset.totalVacancyMonths +
            (asset.leaseType == RealEstateLeaseType.vacant ? 1 : 0),
        lastRentalEvent: eventLabel,
        totalRepairCosts: asset.totalRepairCosts + outOfPocketUnexpectedCost,
        propertyCondition:
            (asset.propertyCondition -
                    (state.currentDate.month == 1 ? 1 : 0) -
                    (incident.incident == RealEstateRentalIncident.majorRepair
                        ? 5
                        : incident.incident ==
                              RealEstateRentalIncident.minorRepair
                        ? 2
                        : 0))
                .clamp(0, 100)
                .toInt(),
      );
      if (asset.hasActiveLease && (remainingMonths == 0 || forcedEviction)) {
        expiringAssetIds.add(asset.id);
      }
      assets.add(updated);
    }
    return _RentalMonthPreparation(
      assets: assets,
      expiringAssetIds: expiringAssetIds,
      rentalIncome: rentalIncome,
      operatingCost: operatingCost,
      repairCost: repairCost,
      insurancePremium: insurancePremium,
      entries: entries,
    );
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
    final rentalMonth = _prepareRentalMonth(state, sourceId);
    final basePropertyIncome = rentalMonth.rentalIncome;
    final propertyIncome = state.progression.hasSkill('property_operation')
        ? (basePropertyIncome * 1.1).round()
        : basePropertyIncome;
    final basePropertyCost =
        rentalMonth.operatingCost +
        rentalMonth.repairCost +
        rentalMonth.insurancePremium;
    final propertyHoldingTax = state.personalFinance
        .monthlyPropertyHoldingTaxAt(state.day, state.currentDate);
    final propertyCost = basePropertyCost + propertyHoldingTax;
    final propertyIncomeTax = realEstateRentalIncomeTax(
      date: state.currentDate,
      grossRent: propertyIncome,
      deductibleOperatingCost: basePropertyCost,
    );
    final netPropertyIncome = propertyIncome - propertyIncomeTax;
    final managementFee = state.story.fundLaunched
        ? (state.story.externalAum * 0.0005).round()
        : 0;
    final checkingAnnualRate = bankCheckingAnnualRateAt(
      state.currentDate,
      cashManagementSkill: state.progression.hasSkill('cash_management'),
    );
    final interest = state.bankCash > 0
        ? (state.bankCash * checkingAnnualRate / 12).round()
        : 0;
    final controlledIncome = state.company.isControlled
        ? (state.company.monthlyRevenue * 0.05).round()
        : 0;
    final income =
        researchRevenue +
        managementFee +
        interest +
        controlledIncome +
        netPropertyIncome;
    final flags = Map<String, dynamic>.from(state.story.storyFlags);
    final entries = <LedgerEntry>[...rentalMonth.entries];
    final priorUnpaid = state.story.flagInt('unpaidOperatingCost');
    final priorMortgageDeficiency = state.story.flagInt(
      'mortgageDeficiencyDebt',
    );
    final priorTenantDepositDebt = state.story.flagInt('tenantDepositDebt');
    final availableBank = state.bankCash + income;
    final currentExpenses = payroll + rent + propertyCost;
    var remainingBank = availableBank;
    final paidPrior = math.min(priorUnpaid, remainingBank);
    remainingBank -= paidPrior;
    final paidMortgageDeficiency = math.min(
      priorMortgageDeficiency,
      remainingBank,
    );
    remainingBank -= paidMortgageDeficiency;
    final paidTenantDepositDebt = math.min(
      priorTenantDepositDebt,
      remainingBank,
    );
    remainingBank -= paidTenantDepositDebt;

    final leaseReadyAssets = <OwnedRealEstate>[];
    var tenantAuctionMortgageDeficiency = 0;
    var newTenantDepositDebt = 0;
    var tenantAuctionCount = 0;
    for (final asset in rentalMonth.assets) {
      if (!rentalMonth.expiringAssetIds.contains(asset.id)) {
        leaseReadyAssets.add(asset);
        continue;
      }
      final rentClaim = math.min(
        asset.leaseDeposit,
        asset.leaseMonthlyRent * asset.rentArrearsMonths,
      );
      final depositDue = asset.leaseDeposit - rentClaim;
      if (remainingBank >= depositDue) {
        remainingBank -= depositDue;
        entries.add(
          LedgerEntry(
            id: '$sourceId-deposit-refund-${asset.id}',
            day: state.day,
            amount: -depositDue,
            notional: asset.leaseDeposit,
            account: 'tenant_deposit_payable',
            counterAccount: 'company_bank',
            description: '${asset.name} 계약 만료 보증금 반환',
            sourceId: sourceId,
          ),
        );
        if (rentClaim > 0) {
          entries.add(
            LedgerEntry(
              id: '$sourceId-deposit-rent-offset-${asset.id}',
              day: state.day,
              amount: 0,
              notional: rentClaim,
              account: 'tenant_deposit_payable',
              counterAccount: 'rent_receivable',
              description: '${asset.name} 보증금에서 밀린 월세 상계',
              sourceId: sourceId,
            ),
          );
        }
        leaseReadyAssets.add(
          asset.copyWith(
            leaseType: RealEstateLeaseType.vacant,
            leaseDeposit: 0,
            leaseMonthlyRent: 0,
            leaseRemainingMonths: 0,
            tenantReliability: 0,
            rentArrearsMonths: 0,
            vacancyMonths: 0,
            lastRentalEvent: '계약 만료 · 보증금 반환 완료 · 공실 전환',
          ),
        );
        continue;
      }

      tenantAuctionCount += 1;
      final disposition = _realEstateDispositionPlan(
        state: state,
        asset: asset,
        forcedKind: RealEstateForcedDispositionKind.tenantAuction,
        tenantDepositDue: depositDue,
      );
      final waterfall = disposition.waterfall;
      tenantAuctionMortgageDeficiency += waterfall.mortgageDeficiency;
      remainingBank += waterfall.ownerProceeds;
      final bankContribution = math.min(
        remainingBank,
        waterfall.tenantDepositDeficiency,
      );
      remainingBank -= bankContribution;
      final depositDeficiency =
          waterfall.tenantDepositDeficiency - bankContribution;
      newTenantDepositDebt += depositDeficiency;
      entries.addAll([
        LedgerEntry(
          id: '$sourceId-tenant-auction-${asset.id}',
          day: state.day,
          amount: waterfall.ownerProceeds,
          notional: disposition.dispositionPrice,
          disposedCost: asset.purchasePrice,
          realizedPnl:
              waterfall.netSaleBeforeTax -
              waterfall.capitalGainsTax -
              asset.purchasePrice,
          account: 'company_bank',
          counterAccount: 'tenant_deposit_auction_sale',
          description: '${asset.name} 보증금 반환 불능 경매',
          sourceId: sourceId,
        ),
        if (disposition.saleCosts > 0)
          LedgerEntry(
            id: '$sourceId-tenant-auction-sale-cost-${asset.id}',
            day: state.day,
            amount: 0,
            notional: disposition.saleCosts,
            account: 'tenant_deposit_auction_sale',
            counterAccount: 'property_sale_cost',
            description: '${asset.name} 경매 처분비용',
            sourceId: sourceId,
          ),
        if (waterfall.capitalGainsTax > 0)
          LedgerEntry(
            id: '$sourceId-tenant-auction-tax-${asset.id}',
            day: state.day,
            amount: 0,
            notional: waterfall.capitalGainsTax,
            account: 'tenant_deposit_auction_sale',
            counterAccount: 'property_capital_gains_tax',
            description: '${asset.name} 경매 양도소득세',
            sourceId: sourceId,
          ),
        if (waterfall.mortgagePaid > 0)
          LedgerEntry(
            id: '$sourceId-tenant-auction-mortgage-${asset.id}',
            day: state.day,
            amount: 0,
            notional: waterfall.mortgagePaid,
            account: 'mortgage_payable',
            counterAccount: 'tenant_deposit_auction_sale',
            description: '${asset.name} 경매대금 담보대출 상환',
            sourceId: sourceId,
          ),
        if (bankContribution > 0)
          LedgerEntry(
            id: '$sourceId-tenant-auction-bank-${asset.id}',
            day: state.day,
            amount: -bankContribution,
            account: 'tenant_deposit_payable',
            counterAccount: 'company_bank',
            description: '${asset.name} 보증금 반환 회사 통장 충당',
            sourceId: sourceId,
          ),
        LedgerEntry(
          id: '$sourceId-tenant-auction-deposit-${asset.id}',
          day: state.day,
          amount: 0,
          notional: waterfall.tenantDepositPaid + bankContribution + rentClaim,
          account: 'tenant_deposit_payable',
          counterAccount: 'tenant_deposit_auction_sale',
          description: '${asset.name} 경매대금 보증금 정산',
          sourceId: sourceId,
        ),
        if (waterfall.mortgageDeficiency > 0)
          LedgerEntry(
            id: '$sourceId-tenant-auction-mortgage-deficiency-${asset.id}',
            day: state.day,
            amount: 0,
            notional: waterfall.mortgageDeficiency,
            account: 'mortgage_deficiency',
            counterAccount: 'mortgage_payable',
            description: '${asset.name} 경매 후 담보대출 결손채무',
            sourceId: sourceId,
          ),
        if (depositDeficiency > 0)
          LedgerEntry(
            id: '$sourceId-tenant-auction-deficiency-${asset.id}',
            day: state.day,
            amount: 0,
            notional: depositDeficiency,
            account: 'tenant_deposit_debt',
            counterAccount: 'tenant_deposit_payable',
            description: '${asset.name} 경매 후 미반환 보증금',
            sourceId: sourceId,
          ),
      ]);
    }

    final paidPayroll = math.min(payroll, remainingBank);
    remainingBank -= paidPayroll;
    final paidRent = math.min(rent, remainingBank);
    remainingBank -= paidRent;
    final paidPropertyCost = math.min(propertyCost, remainingBank);
    remainingBank -= paidPropertyCost;
    final paidHoldingTax = math.min(propertyHoldingTax, paidPropertyCost);
    final paidMaintenance = paidPropertyCost - paidHoldingTax;
    final paidCurrent = paidPayroll + paidRent + paidPropertyCost;
    final unpaidCurrent = currentExpenses - paidCurrent;
    final unpaidOperatingCost = priorUnpaid - paidPrior + unpaidCurrent;

    final followingPaymentDay = _followingMonthlyPaymentDay(state);
    final updatedUnsecuredLoans = <BankUnsecuredLoan>[];
    var unsecuredLoanDue = 0;
    var paidUnsecuredLoanCount = 0;
    var missedUnsecuredLoanCount = 0;
    for (final loan in state.banking.unsecuredLoans) {
      if (!loan.dueAt(state.day)) {
        updatedUnsecuredLoans.add(loan);
        continue;
      }
      final due = loan.dueAmount;
      unsecuredLoanDue += due;
      if (remainingBank >= due) {
        remainingBank -= due;
        final updated = loan.recordScheduledPayment(followingPaymentDay);
        paidUnsecuredLoanCount += 1;
        entries.add(
          LedgerEntry(
            id: '$sourceId-bank-loan-${loan.id}',
            day: state.day,
            amount: -due,
            notional: loan.balance - updated.balance,
            tradingFee: loan.nextInterest,
            account: 'company_bank',
            counterAccount: 'bank_unsecured_loan',
            description: '신용대출 월 원리금 상환 · 이자 ${loan.nextInterest}원',
            sourceId: sourceId,
          ),
        );
        if (updated.balance > 0) updatedUnsecuredLoans.add(updated);
      } else {
        final updated = loan.recordMissedPayment(followingPaymentDay);
        missedUnsecuredLoanCount += 1;
        updatedUnsecuredLoans.add(updated);
        entries.add(
          LedgerEntry(
            id: '$sourceId-bank-loan-arrears-${loan.id}',
            day: state.day,
            amount: 0,
            notional: updated.balance - loan.balance,
            account: 'bank_unsecured_loan',
            counterAccount: 'bank_loan_arrears',
            description:
                '신용대출 연체 ${updated.consecutiveMissedPayments}회 · 이자·연체료 원금 가산',
            sourceId: sourceId,
          ),
        );
      }
    }

    final mortgageDue = leaseReadyAssets.fold<int>(
      0,
      (sum, asset) =>
          sum +
          (asset.mortgageDueAt(state.day) ? asset.monthlyMortgagePayment : 0),
    );
    final updatedRealEstate = <OwnedRealEstate>[];
    var newMortgageDeficiency = tenantAuctionMortgageDeficiency;
    var mortgageArrearsCount = 0;
    var paidMortgageCount = 0;
    var foreclosureCount = 0;
    for (final asset in leaseReadyAssets) {
      if (!asset.hasMortgage || !asset.mortgageDueAt(state.day)) {
        updatedRealEstate.add(asset);
        continue;
      }
      var payableAsset = asset;
      if (asset.mortgageIsVariableRate) {
        final terms = realEstateFinancingTermsAt(
          state.currentDate,
          asset.assetType,
        );
        if (terms.available) {
          payableAsset = asset.copyWith(
            mortgageAnnualInterestRate: math.max(
              0.001,
              terms.annualInterestRate - realEstateVariableMortgageDiscountRate,
            ),
          );
        }
      }
      final due = payableAsset.monthlyMortgagePayment;
      final beforeBalance = payableAsset.mortgageBalance;
      final interestPortion = payableAsset.nextMortgageInterest;
      late OwnedRealEstate updated;
      if (remainingBank >= due) {
        remainingBank -= due;
        updated = payableAsset.recordMortgagePayment(
          nextPaymentDay: followingPaymentDay,
        );
        paidMortgageCount += 1;
        entries.add(
          LedgerEntry(
            id: '$sourceId-mortgage-${asset.id}',
            day: state.day,
            amount: -due,
            notional: beforeBalance - updated.mortgageBalance,
            tradingFee: interestPortion,
            account: 'company_bank',
            counterAccount: 'mortgage_payment',
            description: '${asset.name} 월 원리금 상환',
            sourceId: sourceId,
          ),
        );
      } else {
        updated = payableAsset.recordMissedMortgagePayment(
          nextPaymentDay: followingPaymentDay,
        );
        mortgageArrearsCount += 1;
        entries.add(
          LedgerEntry(
            id: '$sourceId-mortgage-arrears-${asset.id}',
            day: state.day,
            amount: 0,
            notional: due,
            account: 'mortgage_payable',
            counterAccount: 'mortgage_arrears',
            description:
                '${asset.name} 원리금 연체 ${updated.mortgageMissedPayments}회',
            sourceId: sourceId,
          ),
        );
      }
      if (updated.mortgageMissedPayments < 3) {
        updatedRealEstate.add(updated);
        continue;
      }

      foreclosureCount += 1;
      final rentClaim = updated.hasActiveLease
          ? math.min(
              updated.leaseDeposit,
              updated.leaseMonthlyRent * updated.rentArrearsMonths,
            )
          : 0;
      final depositDue = updated.hasActiveLease
          ? updated.leaseDeposit - rentClaim
          : 0;
      final disposition = _realEstateDispositionPlan(
        state: state,
        asset: updated,
        forcedKind: RealEstateForcedDispositionKind.mortgageForeclosure,
        tenantDepositDue: depositDue,
      );
      final waterfall = disposition.waterfall;
      newMortgageDeficiency += waterfall.mortgageDeficiency;
      remainingBank += waterfall.ownerProceeds;
      final depositBankContribution = math.min(
        remainingBank,
        waterfall.tenantDepositDeficiency,
      );
      remainingBank -= depositBankContribution;
      final depositDeficiency =
          waterfall.tenantDepositDeficiency - depositBankContribution;
      newTenantDepositDebt += depositDeficiency;
      entries.addAll([
        LedgerEntry(
          id: '$sourceId-foreclosure-${asset.id}',
          day: state.day,
          amount: waterfall.ownerProceeds,
          notional: disposition.dispositionPrice,
          disposedCost: asset.purchasePrice,
          realizedPnl:
              waterfall.netSaleBeforeTax -
              waterfall.capitalGainsTax -
              asset.purchasePrice,
          account: 'company_bank',
          counterAccount: 'mortgage_foreclosure_sale',
          description: '${asset.name} 3회 연체 강제매각',
          sourceId: sourceId,
        ),
        if (disposition.saleCosts > 0)
          LedgerEntry(
            id: '$sourceId-foreclosure-sale-cost-${asset.id}',
            day: state.day,
            amount: 0,
            notional: disposition.saleCosts,
            account: 'mortgage_foreclosure_sale',
            counterAccount: 'property_sale_cost',
            description: '${asset.name} 강제매각 처분비용',
            sourceId: sourceId,
          ),
        if (waterfall.capitalGainsTax > 0)
          LedgerEntry(
            id: '$sourceId-foreclosure-tax-${asset.id}',
            day: state.day,
            amount: 0,
            notional: waterfall.capitalGainsTax,
            account: 'mortgage_foreclosure_sale',
            counterAccount: 'property_capital_gains_tax',
            description: '${asset.name} 강제매각 양도소득세',
            sourceId: sourceId,
          ),
        if (waterfall.mortgagePaid > 0)
          LedgerEntry(
            id: '$sourceId-foreclosure-payoff-${asset.id}',
            day: state.day,
            amount: 0,
            notional: waterfall.mortgagePaid,
            account: 'mortgage_payable',
            counterAccount: 'mortgage_foreclosure_sale',
            description: '${asset.name} 강제매각 대출 상환',
            sourceId: sourceId,
          ),
        if (waterfall.mortgageDeficiency > 0)
          LedgerEntry(
            id: '$sourceId-foreclosure-deficiency-${asset.id}',
            day: state.day,
            amount: 0,
            notional: waterfall.mortgageDeficiency,
            account: 'mortgage_deficiency',
            counterAccount: 'mortgage_payable',
            description: '${asset.name} 강제매각 후 결손채무',
            sourceId: sourceId,
          ),
        if (rentClaim > 0)
          LedgerEntry(
            id: '$sourceId-foreclosure-rent-offset-${asset.id}',
            day: state.day,
            amount: 0,
            notional: rentClaim,
            account: 'tenant_deposit_payable',
            counterAccount: 'rent_receivable',
            description: '${asset.name} 강제매각 전 보증금 월세 상계',
            sourceId: sourceId,
          ),
        if (depositDue > 0)
          LedgerEntry(
            id: '$sourceId-foreclosure-deposit-${asset.id}',
            day: state.day,
            amount: -depositBankContribution,
            notional: waterfall.tenantDepositPaid + depositBankContribution,
            account: 'tenant_deposit_payable',
            counterAccount: 'mortgage_foreclosure_sale',
            description: '${asset.name} 강제매각 세입자 보증금 정산',
            sourceId: sourceId,
          ),
        if (depositDeficiency > 0)
          LedgerEntry(
            id: '$sourceId-foreclosure-deposit-deficiency-${asset.id}',
            day: state.day,
            amount: 0,
            notional: depositDeficiency,
            account: 'tenant_deposit_debt',
            counterAccount: 'tenant_deposit_payable',
            description: '${asset.name} 강제매각 후 미반환 보증금',
            sourceId: sourceId,
          ),
      ]);
    }

    final paidCreditObligationCount =
        paidUnsecuredLoanCount + paidMortgageCount;
    final missedCreditObligationCount =
        missedUnsecuredLoanCount + mortgageArrearsCount;
    var creditScoreDelta = 0;
    if (paidCreditObligationCount > 0 && missedCreditObligationCount == 0) {
      creditScoreDelta += 2;
    }
    creditScoreDelta -= missedUnsecuredLoanCount * 45;
    creditScoreDelta -= mortgageArrearsCount * 35;
    creditScoreDelta -= foreclosureCount * 100;
    final updatedBanking = state.banking.copyWith(
      creditScore: state.banking.creditScore + creditScoreDelta,
      unsecuredLoans: updatedUnsecuredLoans,
      successfulPaymentMonths:
          state.banking.successfulPaymentMonths +
          (paidCreditObligationCount > 0 && missedCreditObligationCount == 0
              ? 1
              : 0),
      missedPaymentMonths:
          state.banking.missedPaymentMonths +
          (missedCreditObligationCount > 0 ? 1 : 0),
    );
    final endingCash = remainingBank;
    final economicNet =
        income - currentExpenses - unsecuredLoanDue - mortgageDue;
    final remainingMortgageDeficiency =
        priorMortgageDeficiency -
        paidMortgageDeficiency +
        newMortgageDeficiency;
    final remainingTenantDepositDebt =
        priorTenantDepositDebt - paidTenantDepositDebt + newTenantDepositDebt;
    final history = ((flags['performanceHistory'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    history.add({
      'day': state.day,
      'cash': state.brokerageCash + endingCash,
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
    if (remainingMortgageDeficiency > 0) {
      flags['mortgageDeficiencyDebt'] = remainingMortgageDeficiency;
    } else {
      flags.remove('mortgageDeficiencyDebt');
    }
    if (remainingTenantDepositDebt > 0) {
      flags['tenantDepositDebt'] = remainingTenantDepositDebt;
    } else {
      flags.remove('tenantDepositDebt');
    }
    if (tenantAuctionCount > 0) {
      flags['tenantDepositAuctionCount'] =
          state.story.flagInt('tenantDepositAuctionCount') + tenantAuctionCount;
    }
    if (mortgageArrearsCount > 0) {
      flags['mortgageArrearsCount'] = mortgageArrearsCount;
      final reputation =
          (flags['reputation'] as num?)?.toInt() ?? state.story.reputation;
      flags['reputation'] = (reputation - 1).clamp(0, 100);
    } else {
      flags.remove('mortgageArrearsCount');
    }
    if (foreclosureCount > 0) {
      final reputation =
          (flags['reputation'] as num?)?.toInt() ?? state.story.reputation;
      flags['reputation'] = (reputation - foreclosureCount * 10).clamp(0, 100);
      flags['mortgageForeclosureCount'] =
          state.story.flagInt('mortgageForeclosureCount') + foreclosureCount;
    }
    if (tenantAuctionCount > 0) {
      final reputation =
          (flags['reputation'] as num?)?.toInt() ?? state.story.reputation;
      flags['reputation'] = (reputation - tenantAuctionCount * 8).clamp(0, 100);
    }
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
      '부동산 월 임대·분배 수입',
    );
    addEntry(
      'property-income-tax',
      -propertyIncomeTax,
      'property_rental_income_tax',
      '부동산 임대소득세',
    );
    addEntry(
      'payable-payment',
      -paidPrior,
      'accounts_payable',
      '이전 미지급 운영비 지급',
    );
    addEntry(
      'mortgage-deficiency-payment',
      -paidMortgageDeficiency,
      'mortgage_deficiency',
      '강제매각 결손채무 상환',
    );
    addEntry(
      'tenant-deposit-debt-payment',
      -paidTenantDepositDebt,
      'tenant_deposit_debt',
      '미반환 세입자 보증금 상환',
    );
    addEntry('payroll', -paidPayroll, 'salary_expense', '직원 월 급여 지급');
    addEntry('rent', -paidRent, 'rent_expense', '사무실 월 임대료 지급');
    addEntry(
      'property-cost',
      -paidMaintenance,
      'property_maintenance',
      '부동산 월 유지비 지급',
    );
    addEntry(
      'property-holding-tax',
      -paidHoldingTax,
      'property_holding_tax',
      '부동산 보유세·다주택 중과 지급',
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
    if (unpaidOperatingCost == 0 &&
        remainingMortgageDeficiency == 0 &&
        remainingTenantDepositDebt == 0 &&
        mortgageArrearsCount == 0 &&
        missedUnsecuredLoanCount == 0 &&
        tenantAuctionCount == 0 &&
        economicNet >= 0) {
      progression = progression.record('positive_months');
    }
    return state.copyWith(
      cash: state.brokerageCash + endingCash,
      progression: progression,
      banking: updatedBanking,
      personalFinance: state.personalFinance.copyWith(
        realEstate: updatedRealEstate,
        totalPropertyIncome:
            state.personalFinance.totalPropertyIncome + netPropertyIncome,
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
            id: 'adult-investor-year',
            date: DateTime(2010, 1, 4),
            title: '성인 투자자의 첫 투자 서한',
            body: '지난 10년의 선택을 정리하고 성인이 된 뒤 지킬 장기 원칙을 고릅니다.',
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
