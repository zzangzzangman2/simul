import 'dart:math' as math;

import 'banking_state.dart';
import 'business_engine.dart';
import 'casino_state.dart';
import 'cohort_investment_state.dart';
import 'game_state.dart';
import 'home_improvement_state.dart';
import 'horse_racing.dart';
import 'market_clock.dart';
import 'market_cost_rules.dart';
import 'market_data.dart';
import 'market_technical_levels.dart';
import 'market_tick.dart';
import 'order_book.dart';
import 'player_progression.dart';
import 'monthly_unlock_chapter.dart';
import 'organization_state.dart';
import 'real_estate_financing.dart';
import 'real_estate_market.dart';
import 'real_estate_rental.dart';
import 'real_estate_world.dart';
import 'personal_finance_state.dart';
import 'phone_ability_hint.dart';
import 'phone_dialogue_composer.dart';
import 'phone_messenger_state.dart';
import 'phone_situation_context.dart';
import 'progress_review.dart';
import 'relationship_state.dart';
import 'seed_money_content.dart';
import 'stable_hash.dart';
import 'story_state.dart';
import 'weekend_activity.dart';
import 'weekday_activity.dart';

part 'game_engine_corporate_actions.dart';
part 'game_engine_story_decisions.dart';

// 프로젝트 데시멀 국가원금. 출발 종목 중 가장 싼 한 주도 살 수 있어야 첫 실습이
// 성립하므로, 한빛통신 28,400원을 기준으로 50,000원을 지급한다.
const initialCompanyCash = 50000;
const stateAccountSeedCapitalSourceId = 'state-account-seed-capital';
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
      state.story.storyFlags['activeResearchHelper'] == 'hakjun' &&
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
  final controlledIncome = state.company.monthlyOwnerDistribution;
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

class CasinoActionResult {
  const CasinoActionResult({
    required this.state,
    required this.success,
    required this.message,
    this.cashDelta = 0,
    this.minutesElapsed = 0,
  });

  final GameState state;
  final bool success;
  final String message;
  final int cashDelta;
  final int minutesElapsed;

  CasinoActionResult withState(GameState next) => CasinoActionResult(
    state: next,
    success: success,
    message: message,
    cashDelta: cashDelta,
    minutesElapsed: minutesElapsed,
  );
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

class RelationshipActionResult {
  const RelationshipActionResult({
    required this.state,
    required this.success,
    required this.message,
    this.girlId,
    this.activity,
    this.affectionBefore,
    this.affectionAfter,
    this.affectionDelta = 0,
    this.response,
    this.dateJustUnlocked = false,
    this.stageJustUnlocked,
  });

  final GameState state;
  final bool success;
  final String message;
  final String? girlId;
  final RelationshipActivity? activity;
  final int? affectionBefore;
  final int? affectionAfter;
  final int affectionDelta;
  final String? response;
  final bool dateJustUnlocked;
  final RelationshipStage? stageJustUnlocked;
}

class CohortInvestmentActionResult {
  const CohortInvestmentActionResult({
    required this.state,
    required this.success,
    required this.message,
    this.report,
    this.loan,
  });

  final GameState state;
  final bool success;
  final String message;
  final CohortDailyInvestmentReport? report;
  final CohortLoan? loan;
}

class PhoneMessengerActionResult {
  const PhoneMessengerActionResult({
    required this.state,
    required this.success,
    required this.message,
    this.reply,
    this.affectionDelta = 0,
    this.trustDelta = 0,
    this.closenessDelta = 0,
    this.investmentRespectDelta = 0,
    this.abilityHint,
  });

  final GameState state;
  final bool success;
  final String message;
  final PhoneMessage? reply;
  final int affectionDelta;
  final int trustDelta;
  final int closenessDelta;
  final int investmentRespectDelta;
  final PhoneAbilityHint? abilityHint;

  bool get relationshipChanged =>
      affectionDelta != 0 ||
      trustDelta != 0 ||
      closenessDelta != 0 ||
      investmentRespectDelta != 0;

  PhoneMessengerActionResult withState(GameState nextState) =>
      PhoneMessengerActionResult(
        state: nextState,
        success: success,
        message: message,
        reply: reply,
        affectionDelta: affectionDelta,
        trustDelta: trustDelta,
        closenessDelta: closenessDelta,
        investmentRespectDelta: investmentRespectDelta,
        abilityHint: abilityHint,
      );
}

class GameEngine {
  const GameEngine();

  static int _newGameSerial = 0;
  static final math.Random _worldSeedRandom = math.Random.secure();

  PhoneMessengerActionResult markPhoneThreadRead(
    GameState state, {
    required String contactId,
  }) {
    if (phoneContactById(contactId) == null) {
      return PhoneMessengerActionResult(
        state: state,
        success: false,
        message: '데시멀 연락처에 없는 동기입니다.',
      );
    }
    var changed = false;
    final messages = [
      for (final message in state.phoneMessenger.messages)
        if (message.contactId == contactId &&
            !message.isFromPlayer &&
            !message.read)
          (() {
            changed = true;
            return message.copyWith(read: true);
          })()
        else
          message,
    ];
    if (!changed) {
      return PhoneMessengerActionResult(
        state: state,
        success: true,
        message: '새 메시지를 모두 읽었습니다.',
      );
    }
    return PhoneMessengerActionResult(
      state: state.copyWith(
        phoneMessenger: state.phoneMessenger.copyWith(messages: messages),
      ),
      success: true,
      message: '새 메시지를 모두 읽었습니다.',
    );
  }

  PhoneMessengerActionResult sendPhoneGift(
    GameState state, {
    required String contactId,
    required String giftId,
  }) {
    final contact = phoneContactById(contactId);
    final profile = cohortGirlProfileById(contactId);
    final gift = weekendGiftById(giftId);
    if (contact == null || profile == null || gift == null) {
      return PhoneMessengerActionResult(
        state: state,
        success: false,
        message: '선물과 받을 동기를 다시 확인해 주세요.',
      );
    }
    if (kBeautyGiftAlreadyGivenToday(state)) {
      return PhoneMessengerActionResult(
        state: state,
        success: false,
        message: '선물은 매장과 톡을 합쳐 하루에 한 번만 보낼 수 있어요.',
      );
    }
    if (state.bankCash < gift.cost) {
      return PhoneMessengerActionResult(
        state: state,
        success: false,
        message: '생활비 통장에 ${gift.cost - state.bankCash}원이 부족합니다.',
      );
    }

    final repeatCount = kBeautyGiftMonthlyRepeatCount(
      state,
      girlId: profile.id,
      giftId: gift.id,
    );
    final progress = state.relationships.progressFor(profile.id);
    final requestedAffection = gift.affectionFor(
      profile.id,
      monthlyRepeatCount: repeatCount,
    );
    final requestedTrust = gift.trustFor(
      profile.id,
      monthlyRepeatCount: repeatCount,
    );
    final nextAffection = (progress.affection + requestedAffection)
        .clamp(relationshipMinAffection, relationshipMaxAffection)
        .toInt();
    final nextTrust = (progress.trust + requestedTrust)
        .clamp(relationshipDimensionMin, relationshipDimensionMax)
        .toInt();
    final nextCloseness =
        (progress.closeness + (requestedAffection > 0 ? 1 : 0))
            .clamp(relationshipDimensionMin, relationshipDimensionMax)
            .toInt();
    final affectionDelta = nextAffection - progress.affection;
    final trustDelta = nextTrust - progress.trust;
    final closenessDelta = nextCloseness - progress.closeness;
    final replyText = kBeautyGiftPhoneReaction(
      state,
      gift: gift,
      girlId: profile.id,
      monthlyRepeatCount: repeatCount,
    );
    final updatedProgress = progress.copyWith(
      affection: nextAffection,
      trust: nextTrust,
      closeness: nextCloseness,
      lastInteractionDay: state.day,
    );
    final relationshipMemory = RelationshipMemory(
      day: state.day,
      girlId: profile.id,
      activity: RelationshipActivity.gift,
      sceneId: 'phone_gift_${gift.id}',
      choiceId: gift.id,
      affectionDelta: affectionDelta,
      affectionAfter: nextAffection,
      trustDelta: trustDelta,
      closenessDelta: closenessDelta,
    );
    final relationshipMemories = <RelationshipMemory>[
      ...state.relationships.memories,
      relationshipMemory,
    ];
    final replyMinute = math.min(1439, state.marketMinute + 1);
    final playerText = '${gift.title} 선물을 보냈어요.';
    final playerMessage = PhoneMessage(
      id: 'phone-gift-${state.day}-${profile.id}-${gift.id}-me',
      contactId: profile.id,
      senderId: phoneMessengerPlayerId,
      text: playerText,
      day: state.day,
      marketMinute: state.marketMinute,
      read: true,
      giftId: gift.id,
    );
    final reply = PhoneMessage(
      id: 'phone-gift-${state.day}-${profile.id}-${gift.id}-reply',
      contactId: profile.id,
      senderId: profile.id,
      text: replyText,
      day: state.day,
      marketMinute: replyMinute,
      read: true,
    );
    final appendedMessages = <PhoneMessage>[
      for (final message in state.phoneMessenger.messages)
        if (message.contactId == profile.id &&
            !message.isFromPlayer &&
            !message.read)
          message.copyWith(read: true)
        else
          message,
      playerMessage,
      reply,
    ];
    final messages = retainPhoneMessages(appendedMessages);
    final phoneMemory = PhoneConversationMemory(
      id: 'phone-gift-memory-${state.day}-${profile.id}-${gift.id}',
      contactId: profile.id,
      day: state.day,
      intent: 'gift',
      investmentSituation: 'unavailable',
      playerText: playerText,
      replyText: replyText,
      affectionDelta: affectionDelta,
      trustDelta: trustDelta,
      closenessDelta: closenessDelta,
      importance: affectionDelta > 0 ? 3 : 2,
      marketMinute: replyMinute,
      situationSummary: '미라온 뷰티 톡 선물',
    );
    final phoneMemories = retainPhoneConversationMemories(
      <PhoneConversationMemory>[...state.phoneMessenger.memories, phoneMemory],
    );
    final sourceId = 'phone-gift-${state.day}-${profile.id}-${gift.id}';
    final next = state.copyWith(
      cash: state.cash - gift.cost,
      relationships: state.relationships.copyWith(
        girls: <String, GirlRelationshipProgress>{
          ...state.relationships.girls,
          profile.id: updatedProgress,
        },
        memories: relationshipMemories.length <= relationshipMemoryHistoryLimit
            ? relationshipMemories
            : relationshipMemories.sublist(
                relationshipMemories.length - relationshipMemoryHistoryLimit,
              ),
      ),
      phoneMessenger: state.phoneMessenger.copyWith(
        messages: messages,
        memories: phoneMemories,
      ),
      ledger: <LedgerEntry>[
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -gift.cost,
          account: 'company_bank',
          counterAccount: 'relationship_gift_expense',
          description: '${profile.name}에게 보낸 ${gift.title}',
          sourceId: sourceId,
        ),
      ],
      processedEventIds: <String>[...state.processedEventIds, sourceId],
    );
    return PhoneMessengerActionResult(
      state: next,
      success: true,
      message:
          '${profile.name}에게 선물을 보냈습니다. ${kBeautyGiftRepeatLabel(repeatCount)} · 호감도 +$affectionDelta',
      reply: reply,
      affectionDelta: affectionDelta,
      trustDelta: trustDelta,
      closenessDelta: closenessDelta,
    );
  }

  PhoneMessengerActionResult sendPhoneMessage(
    GameState state, {
    required String contactId,
    required String text,
    String? replyOverride,
    PhoneAbilityHint? abilityHint,
  }) {
    final contact = phoneContactById(contactId);
    if (contact == null) {
      return PhoneMessengerActionResult(
        state: state,
        success: false,
        message: '데시멀 연락처에 없는 동기입니다.',
      );
    }
    final content = text.trim();
    if (content.isEmpty) {
      return PhoneMessengerActionResult(
        state: state,
        success: false,
        message: '보낼 말을 입력해 주세요.',
      );
    }
    if (content.length > phoneMessengerMaxMessageLength) {
      return PhoneMessengerActionResult(
        state: state,
        success: false,
        message: '메시지는 $phoneMessengerMaxMessageLength자까지 보낼 수 있습니다.',
      );
    }
    if (state.marketMinute > phoneMessengerLastSendMinute) {
      return PhoneMessengerActionResult(
        state: state,
        success: false,
        message: state.marketMinute >= phoneMessengerBedtimeMinute
            ? '22:00가 되어 모두 잠들었습니다. 내일 아침에 다시 톡해요.'
            : '취침 전 30분 대화를 마칠 시간이 부족합니다. 내일 다시 톡해요.',
      );
    }
    final progress = state.phoneMessenger.progressFor(contactId);
    final exchangesToday = progress.exchangesForDay(state.day);
    if (exchangesToday >= phoneMessengerDailySendLimit) {
      return PhoneMessengerActionResult(
        state: state,
        success: false,
        message: '오늘은 이 친구와 충분히 이야기했습니다. 내일 다시 톡해요.',
      );
    }

    final sequence = progress.totalExchanges + 1;
    final replyMinute = state.marketMinute + phoneMessengerExchangeMinutes;
    final report = state.cohortInvestments.reportForDay(state.day);
    final playerRow = report?.resultFor('player');
    final contactRow = report?.resultFor(contactId);
    int rankFor(String investorId) {
      final rows = report?.rankedRows ?? const <CohortDailyInvestmentResult>[];
      for (var index = 0; index < rows.length; index++) {
        if (rows[index].investorId == investorId) return index + 1;
      }
      return 0;
    }

    final girlProfile = cohortGirlProfileById(contactId);
    final relationship = girlProfile == null
        ? null
        : state.relationships.progressFor(contactId);
    final phoneSituation = buildPhoneSituationContext(
      state,
      contactId: contactId,
      playerText: content,
    );
    final guardedAbilityHint = enforcePhoneAbilityHintForSend(
      state,
      contactId: contactId,
      playerIntent: classifyPhoneIntent(content).name,
      proposed: abilityHint,
    );
    final composed = composePhoneReply(
      PhoneDialogueContext(
        worldSeed: state.simulationSeed,
        day: state.day,
        marketMinute: state.marketMinute,
        contact: contact,
        progress: progress,
        relationship: relationship,
        investment: PhoneInvestmentConversationContext(
          hasCurrentReport: report != null,
          marketClosed: !isMarketTradingDay(state.currentDate),
          playerDailyProfitLoss: playerRow?.profitLoss ?? 0,
          playerCumulativeProfitLoss:
              state.cohortInvestments.playerCumulativeProfitLoss,
          playerTotal: playerRow?.totalAmount ?? 0,
          playerRank: rankFor('player'),
          contactDailyProfitLoss: contactRow?.profitLoss ?? 0,
          contactRank: rankFor(contactId),
        ),
        recentMemories: state.phoneMessenger.relevantMemoriesFor(
          contactId,
          queryText: content,
          currentDay: state.day,
        ),
        abilityHint: guardedAbilityHint,
        situation: phoneSituation,
      ),
      content,
    );
    final appliedAbilityHint = composed.abilityHintUsed
        ? guardedAbilityHint
        : null;
    final playerMessage = PhoneMessage(
      id: 'phone-${state.day}-${state.marketMinute}-$contactId-$sequence-me',
      contactId: contactId,
      senderId: phoneMessengerPlayerId,
      text: content,
      day: state.day,
      marketMinute: state.marketMinute,
      read: true,
    );
    final normalizedOverride = _normalizedPhoneReply(replyOverride);
    final safeOverride =
        normalizedOverride != null &&
            !phoneAiReplyViolatesSituationPolicy(
              normalizedOverride,
              situation: phoneSituation,
            )
        ? normalizedOverride
        : null;
    final reply = PhoneMessage(
      id: 'phone-${state.day}-$replyMinute-$contactId-$sequence-reply',
      contactId: contactId,
      senderId: contactId,
      text: safeOverride ?? composed.text,
      day: state.day,
      marketMinute: replyMinute,
      read: true,
    );
    final appended = [
      for (final message in state.phoneMessenger.messages)
        if (message.contactId == contactId &&
            !message.isFromPlayer &&
            !message.read)
          message.copyWith(read: true)
        else
          message,
      playerMessage,
      reply,
    ];
    final messages = retainPhoneMessages(appended);
    final nextProgress = <String, PhoneThreadProgress>{
      ...state.phoneMessenger.progressByContact,
      contactId: progress.recordExchange(
        state.day,
        intent: composed.intent.name,
      ),
    };
    var affectionDelta = 0;
    var trustDelta = 0;
    var closenessDelta = 0;
    var investmentRespectDelta = 0;
    var nextRelationships = state.relationships;
    if (relationship != null && composed.meaningful) {
      final nextAffection = (relationship.affection + composed.affectionDelta)
          .clamp(relationshipMinAffection, relationshipMaxAffection)
          .toInt();
      final nextTrust = (relationship.trust + composed.trustDelta)
          .clamp(relationshipDimensionMin, relationshipDimensionMax)
          .toInt();
      final nextCloseness = (relationship.closeness + composed.closenessDelta)
          .clamp(relationshipDimensionMin, relationshipDimensionMax)
          .toInt();
      final nextInvestmentRespect =
          (relationship.investmentRespect + composed.investmentRespectDelta)
              .clamp(relationshipDimensionMin, relationshipDimensionMax)
              .toInt();
      affectionDelta = nextAffection - relationship.affection;
      trustDelta = nextTrust - relationship.trust;
      closenessDelta = nextCloseness - relationship.closeness;
      investmentRespectDelta =
          nextInvestmentRespect - relationship.investmentRespect;
      final updated = relationship.copyWith(
        affection: nextAffection,
        trust: nextTrust,
        closeness: nextCloseness,
        investmentRespect: nextInvestmentRespect,
        lastInteractionDay: state.day,
        lastMeaningfulMessageDay: state.day,
        meaningfulMessageCount: relationship.meaningfulMessageCount + 1,
      );
      nextRelationships = state.relationships.copyWith(
        girls: <String, GirlRelationshipProgress>{
          ...state.relationships.girls,
          contactId: updated,
        },
      );
    }
    final memory = PhoneConversationMemory(
      id: 'phone-memory-${state.day}-$contactId-$sequence',
      contactId: contactId,
      day: state.day,
      intent: composed.intent.name,
      investmentSituation: composed.investmentSituation.name,
      playerText: content,
      replyText: reply.text,
      playerDailyProfitLoss: playerRow?.profitLoss ?? 0,
      playerCumulativeProfitLoss:
          state.cohortInvestments.playerCumulativeProfitLoss,
      contactDailyProfitLoss: contactRow?.profitLoss ?? 0,
      affectionDelta: affectionDelta,
      trustDelta: trustDelta,
      closenessDelta: closenessDelta,
      investmentRespectDelta: investmentRespectDelta,
      importance: math.max(
        appliedAbilityHint?.isStrong == true ? 4 : 1,
        phoneMemoryImportanceForIntent(
          composed.intent.name,
          affectionDelta: affectionDelta,
          trustDelta: trustDelta,
          closenessDelta: closenessDelta,
        ),
      ),
      abilityHintLevel: appliedAbilityHint?.level.name ?? '',
      abilityHintObservation: appliedAbilityHint?.observation ?? '',
      abilityHintUsedResearchCredit:
          appliedAbilityHint?.usesResearchCredit == true,
      marketMinute: replyMinute,
      situationSummary: phoneSituation.situationSummary,
      scheduleDecision: phoneSituation.scheduleDecision.name,
    );
    final appendedMemories = <PhoneConversationMemory>[
      ...state.phoneMessenger.memories,
      memory,
    ];
    final memories = retainPhoneConversationMemories(appendedMemories);
    var nextStory = state.story;
    if (appliedAbilityHint?.usesResearchCredit == true) {
      final flags = <String, dynamic>{...state.story.storyFlags};
      final credits =
          (flags[weekendMarketResearchCreditsFlag] as num?)?.toInt() ?? 0;
      flags[weekendMarketResearchCreditsFlag] = math.max(0, credits - 1);
      nextStory = state.story.copyWith(storyFlags: flags);
    }
    final next = state.copyWith(
      marketMinute: replyMinute,
      story: nextStory,
      relationships: nextRelationships,
      phoneMessenger: state.phoneMessenger.copyWith(
        messages: messages,
        progressByContact: nextProgress,
        memories: memories,
      ),
    );
    return PhoneMessengerActionResult(
      state: next,
      success: true,
      message: '${contact.name}에게 메시지를 보냈습니다.',
      reply: reply,
      affectionDelta: affectionDelta,
      trustDelta: trustDelta,
      closenessDelta: closenessDelta,
      investmentRespectDelta: investmentRespectDelta,
      abilityHint: appliedAbilityHint,
    );
  }

  String? _normalizedPhoneReply(String? raw) {
    if (raw == null) return null;
    final normalized = raw
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty || normalized.length > 160) return null;
    return normalized;
  }

  CohortInvestmentActionResult settleCohortInvestmentDay(
    GameState state, {
    required FictionalMarketUniverse universe,
  }) {
    final existing = state.cohortInvestments.reportForDay(state.day);
    if (state.cohortInvestments.settledForDay(state.day) && existing != null) {
      return CohortInvestmentActionResult(
        state: state,
        success: true,
        message: '오늘의 데시멀 투자 결과는 이미 확정됐습니다.',
        report: existing,
      );
    }
    if (state.marketMinute < krxCloseMinute) {
      return CohortInvestmentActionResult(
        state: state,
        success: false,
        message: '15:00 종가가 확정된 뒤 오늘의 결과를 계산할 수 있습니다.',
      );
    }

    final dateKey = marketDateKey(state.currentDate);
    final candidates =
        universe.assets
            .where((asset) {
              if (!asset.isDomestic) return false;
              final history = asset.historyThrough(state.currentDate, count: 2);
              return history.length >= 2 && history.last.date == dateKey;
            })
            .toList(growable: false)
          ..sort((left, right) => left.id.compareTo(right.id));

    var accounts = <String, CohortInvestorAccount>{
      ...state.cohortInvestments.accounts,
    };
    final npcRows = <CohortDailyInvestmentResult>[];
    for (final profile in cohortNpcInvestorProfiles) {
      final account = state.cohortInvestments.accountFor(profile.id);
      var previousCumulativeProfitLoss =
          account.balance - cohortInvestmentInitialBalance;
      for (final previousReport in state.cohortInvestments.reports.reversed) {
        final previousRow = previousReport.resultFor(profile.id);
        if (previousRow == null) continue;
        previousCumulativeProfitLoss = previousRow.cumulativeProfitLoss;
        break;
      }
      if (candidates.isEmpty || !isMarketTradingDay(state.currentDate)) {
        npcRows.add(
          CohortDailyInvestmentResult(
            investorId: profile.id,
            name: profile.name,
            assetId: '',
            assetName: '휴장 · 투자 없음',
            investedAmount: 0,
            profitLoss: 0,
            totalAmount: account.balance,
            traded: false,
            isPlayer: false,
            cumulativeProfitLoss: previousCumulativeProfitLoss,
          ),
        );
        continue;
      }
      final pick =
          _stableHash(
            '${state.simulationSeed}:cohort:${state.day}:${profile.id}',
          ) %
          candidates.length;
      final asset = candidates[pick];
      final history = asset.historyThrough(state.currentDate, count: 2);
      final previousClose = history[history.length - 2].close;
      final close = history.last.close;
      final investedAmount =
          (account.balance * profile.investmentRatioBps / 10000).round().clamp(
            0,
            account.balance,
          );
      final returnRate = previousClose <= 0
          ? 0.0
          : ((close - previousClose) / previousClose).clamp(-0.30, 0.30);
      final grossProfitLoss = (investedAmount * returnRate).round();
      final tradingCost = investedAmount <= 0
          ? 0
          : math.max(
              1,
              (investedAmount *
                      (marketTradingFeeRate(state.currentDate) * 2 +
                          marketSecuritiesTransactionTaxRate(
                            state.currentDate,
                          )))
                  .round(),
            );
      final netProfitLoss = grossProfitLoss - tradingCost;
      // 동기 9명도 플레이어와 같은 조건으로 확정 순이익을 국가에 환수한다. 한쪽만
      // 환수하면 수익률 순위표에서 플레이어가 구조적으로 불리해진다.
      final npcRecoveryRateBps = state.story.orphanageReboot
          ? state.story.stateRecoveryRateBps.clamp(0, 10000).toInt()
          : 0;
      final stateRecovery = netProfitLoss <= 0
          ? 0
          : (netProfitLoss * npcRecoveryRateBps / 10000)
                .round()
                .clamp(0, netProfitLoss)
                .toInt();
      final profitLoss = netProfitLoss - stateRecovery;
      final totalAmount = math.max(0, account.balance + profitLoss);
      accounts[profile.id] = account.copyWith(balance: totalAmount);
      npcRows.add(
        CohortDailyInvestmentResult(
          investorId: profile.id,
          name: profile.name,
          assetId: asset.id,
          assetName: asset.name,
          investedAmount: investedAmount,
          profitLoss: profitLoss,
          totalAmount: totalAmount,
          traded: true,
          isPlayer: false,
          cumulativeProfitLoss: previousCumulativeProfitLoss + profitLoss,
          stateRecovery: stateRecovery,
        ),
      );
    }

    var repaymentTotal = 0;
    var borrowingRepaymentTotal = 0;
    var incomingPrincipalRepayment = 0;
    var outgoingPrincipalRepayment = 0;
    var loanInterestIncome = 0;
    var loanInterestExpense = 0;
    final repaidLoans = <CohortLoan>[];
    final repaymentEntries = <LedgerEntry>[];
    for (final loan in state.cohortInvestments.loans) {
      if (loan.isRepaid || loan.dueDay > state.day) {
        repaidLoans.add(loan);
        continue;
      }
      final account = accounts[loan.borrowerId];
      if (account == null) {
        repaidLoans.add(loan);
        continue;
      }
      final affordable = loan.direction == CohortLoanDirection.playerLends
          ? math.max(0, account.balance - 1000)
          : math.max(
              0,
              state.withdrawableBrokerageCash +
                  repaymentTotal -
                  borrowingRepaymentTotal,
            );
      final repayment = math.min(loan.outstanding, affordable);
      if (repayment <= 0) {
        repaidLoans.add(loan);
        continue;
      }
      final interestPaid = math.min(repayment, loan.outstandingInterest);
      final principalPaid = repayment - interestPaid;
      accounts[loan.borrowerId] = account.copyWith(
        balance:
            account.balance +
            (loan.direction == CohortLoanDirection.playerLends
                ? -repayment
                : repayment),
      );
      final updatedLoan = loan.copyWith(
        repaidAmount: loan.repaidAmount + repayment,
      );
      repaidLoans.add(updatedLoan);
      if (loan.direction == CohortLoanDirection.playerLends) {
        repaymentTotal += repayment;
        incomingPrincipalRepayment += principalPaid;
        loanInterestIncome += interestPaid;
      } else {
        borrowingRepaymentTotal += repayment;
        outgoingPrincipalRepayment += principalPaid;
        loanInterestExpense += interestPaid;
      }
      repaymentEntries.add(
        LedgerEntry(
          id: '${loan.id}-repay-${state.day}',
          day: state.day,
          amount: loan.direction == CohortLoanDirection.playerLends
              ? repayment
              : -repayment,
          account: loan.direction == CohortLoanDirection.playerLends
              ? 'brokerage_cash'
              : 'cohort_loan_payable',
          counterAccount: loan.direction == CohortLoanDirection.playerLends
              ? 'cohort_loan_receivable'
              : 'brokerage_cash',
          description: loan.direction == CohortLoanDirection.playerLends
              ? '${loan.borrowerName} 동기 대여금 ${updatedLoan.isRepaid ? '상환 완료' : '일부 상환'} · 이자 $interestPaid원'
              : '${loan.borrowerName}에게 빌린 돈 ${updatedLoan.isRepaid ? '상환 완료' : '일부 상환'} · 이자 $interestPaid원',
          sourceId: '${loan.id}-repay-${state.day}',
          notional: repayment,
          realizedPnl: loan.direction == CohortLoanDirection.playerLends
              ? interestPaid
              : -interestPaid,
          marketMinute: krxCloseMinute,
        ),
      );
    }
    if (repaymentTotal > 0 || borrowingRepaymentTotal > 0) {
      for (var index = 0; index < npcRows.length; index++) {
        final account = accounts[npcRows[index].investorId];
        if (account != null) {
          npcRows[index] = npcRows[index].copyWith(
            totalAmount: account.balance,
          );
        }
      }
    }

    final afterRepayment = state.copyWith(
      cash: state.cash + repaymentTotal - borrowingRepaymentTotal,
      brokerageCash:
          state.brokerageCash + repaymentTotal - borrowingRepaymentTotal,
      ledger: [...state.ledger, ...repaymentEntries],
    );
    final closePrices = <String, double>{};
    for (final asset in universe.assets) {
      final quote = asset.quoteAtOrBefore(state.currentDate);
      if (quote != null) {
        closePrices[asset.id] = state.shareholderGovernance.adjustedPrice(
          asset.id,
          state.day,
          quote.close,
        );
      }
    }
    final playerTotal =
        afterRepayment.brokerageCash +
        afterRepayment.portfolioValue(closePrices);
    var netBrokerageFlow =
        incomingPrincipalRepayment - outgoingPrincipalRepayment;
    for (final entry in state.ledger.where((entry) => entry.day == state.day)) {
      if (entry.account == 'brokerage_cash' &&
          entry.counterAccount == 'company_bank') {
        netBrokerageFlow += entry.notional;
      } else if (entry.account == 'company_bank' &&
          entry.counterAccount == 'brokerage_cash') {
        netBrokerageFlow -= entry.notional;
      }
    }
    final previousPlayerTotal =
        state.cohortInvestments.previousPlayerCloseTotal ??
        (state.day == 1
            ? cohortInvestmentInitialBalance
            : playerTotal - netBrokerageFlow);
    final playerProfitLoss =
        playerTotal - previousPlayerTotal - netBrokerageFlow;
    final playerCumulativeProfitLoss =
        state.cohortInvestments.playerCumulativeProfitLoss + playerProfitLoss;
    final playerTradeEntries = state.ledger
        .where(
          (entry) =>
              entry.day == state.day &&
              (entry.tradeSide == 'buy' || entry.tradeSide == 'sell'),
        )
        .toList(growable: false);
    final tradedAssetIds = playerTradeEntries
        .map((entry) => entry.assetId)
        .where((assetId) => assetId.isNotEmpty)
        .toSet();
    String playerAssetName = '거래 없음';
    String playerAssetId = '';
    if (tradedAssetIds.length == 1) {
      playerAssetId = tradedAssetIds.single;
      for (final asset in universe.assets) {
        if (asset.id == playerAssetId) {
          playerAssetName = asset.name;
          break;
        }
      }
    } else if (tradedAssetIds.length > 1) {
      playerAssetName = '실제 포트폴리오 ${tradedAssetIds.length}종목';
    } else if (state.positions.isNotEmpty) {
      playerAssetName = '보유 포트폴리오';
    }
    final playerName = state.story.playerName.trim().isEmpty
        ? '나'
        : state.story.playerName.trim();
    final report = CohortDailyInvestmentReport(
      day: state.day,
      repaymentTotal: repaymentTotal,
      borrowingRepaymentTotal: borrowingRepaymentTotal,
      loanInterestIncome: loanInterestIncome,
      loanInterestExpense: loanInterestExpense,
      rows: [
        CohortDailyInvestmentResult(
          investorId: 'player',
          name: playerName,
          assetId: playerAssetId,
          assetName: playerAssetName,
          investedAmount: state.portfolioValue(closePrices),
          profitLoss: playerProfitLoss,
          totalAmount: playerTotal,
          traded: playerTradeEntries.isNotEmpty,
          isPlayer: true,
          cumulativeProfitLoss: playerCumulativeProfitLoss,
        ),
        ...npcRows,
      ],
    );
    final reports = [
      ...state.cohortInvestments.reports.where((item) => item.day != state.day),
      report,
    ];
    final trimmedReports = reports.length <= cohortInvestmentHistoryLimit
        ? reports
        : reports.sublist(reports.length - cohortInvestmentHistoryLimit);
    final next = afterRepayment.copyWith(
      progression: playerTradeEntries.isEmpty
          ? afterRepayment.progression
          : afterRepayment.progression.gainExperience(2),
      cohortInvestments: state.cohortInvestments.copyWith(
        accounts: accounts,
        reports: trimmedReports,
        loans: repaidLoans,
        lastSettledDay: state.day,
        previousPlayerCloseTotal: playerTotal,
        playerCumulativeProfitLoss: playerCumulativeProfitLoss,
      ),
    );
    return CohortInvestmentActionResult(
      state: next,
      success: true,
      message: '데시멀 동기 10명의 오늘 투자 결과가 확정됐습니다.',
      report: report,
    );
  }

  CohortInvestmentActionResult lendToCohortInvestor(
    GameState state, {
    required String borrowerId,
    required int amount,
  }) {
    final report = state.cohortInvestments.reportForDay(state.day);
    if (report == null || !state.cohortInvestments.settledForDay(state.day)) {
      return CohortInvestmentActionResult(
        state: state,
        success: false,
        message: '오늘의 투자 결과가 확정된 뒤 돈을 빌려줄 수 있습니다.',
      );
    }
    if (state.cohortInvestments.acknowledgedForDay(state.day)) {
      return CohortInvestmentActionResult(
        state: state,
        success: false,
        message: '오늘 결과표를 닫은 뒤에는 대여할 수 없습니다.',
        report: report,
      );
    }
    if (state.cohortInvestments.loanedForDay(state.day)) {
      return CohortInvestmentActionResult(
        state: state,
        success: false,
        message: '돈 빌려주기는 하루에 한 번만 가능합니다.',
        report: report,
      );
    }
    final profile = cohortNpcInvestorProfileById(borrowerId);
    final borrower = report.resultFor(borrowerId);
    final player = report.resultFor('player');
    if (profile == null || borrower == null || player == null) {
      return CohortInvestmentActionResult(
        state: state,
        success: false,
        message: '데시멀 결과표에 없는 동기입니다.',
        report: report,
      );
    }
    final maximum = math.min(
      state.withdrawableBrokerageCash,
      cohortPlayerBorrowingLimit,
    );
    if (amount <= 0 || amount > maximum) {
      return CohortInvestmentActionResult(
        state: state,
        success: false,
        message: maximum <= 0
            ? '지금 빌려줄 수 있는 국가계좌 현금이 없습니다.'
            : '오늘은 최대 $maximum원까지 빌려줄 수 있습니다.',
        report: report,
      );
    }

    final loan = CohortLoan(
      id: 'cohort-loan-${state.day}-$borrowerId',
      borrowerId: borrowerId,
      borrowerName: profile.name,
      issuedDay: state.day,
      dueDay: state.day + cohortLoanTermDays,
      principal: amount,
      direction: CohortLoanDirection.playerLends,
      interestRateBps: cohortLoanInterestRateBps,
    );
    final updatedRows = [
      for (final row in report.rows)
        if (row.investorId == 'player')
          row.copyWith(totalAmount: row.totalAmount - amount)
        else if (row.investorId == borrowerId)
          row.copyWith(totalAmount: row.totalAmount + amount)
        else
          row,
    ];
    final updatedReport = report.copyWith(rows: updatedRows);
    final reports = [
      for (final item in state.cohortInvestments.reports)
        if (item.day == state.day) updatedReport else item,
    ];
    final borrowerAccount = state.cohortInvestments.accountFor(borrowerId);
    final accounts = <String, CohortInvestorAccount>{
      ...state.cohortInvestments.accounts,
      borrowerId: borrowerAccount.copyWith(
        balance: borrowerAccount.balance + amount,
      ),
    };
    final sourceId = loan.id;
    final next = state.copyWith(
      cash: state.cash - amount,
      brokerageCash: state.brokerageCash - amount,
      cohortInvestments: state.cohortInvestments.copyWith(
        accounts: accounts,
        reports: reports,
        loans: [...state.cohortInvestments.loans, loan],
        lastLoanDay: state.day,
        previousPlayerCloseTotal: math.max(
          0,
          (state.cohortInvestments.previousPlayerCloseTotal ??
                  player.totalAmount) -
              amount,
        ),
      ),
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -amount,
          account: 'cohort_loan_receivable',
          counterAccount: 'brokerage_cash',
          description:
              '${profile.name} 동기 대여금 · $cohortLoanTermDays일 뒤 원금과 이자 ${loan.interest}원 상환',
          sourceId: sourceId,
          notional: amount,
          marketMinute: krxCloseMinute,
        ),
      ],
    );
    return CohortInvestmentActionResult(
      state: next,
      success: true,
      message:
          '${profile.name}에게 $amount원을 빌려줬습니다. $cohortLoanTermDays일 뒤 ${loan.totalDue}원 상환입니다.',
      report: updatedReport,
      loan: loan,
    );
  }

  CohortInvestmentActionResult borrowFromCohortInvestor(
    GameState state, {
    required String lenderId,
    required int amount,
  }) {
    final report = state.cohortInvestments.reportForDay(state.day);
    CohortInvestmentActionResult reject(String message) =>
        CohortInvestmentActionResult(
          state: state,
          success: false,
          message: message,
          report: report,
        );
    if (report == null || !state.cohortInvestments.settledForDay(state.day)) {
      return reject('오늘의 투자 결과가 확정된 뒤 동기에게 빌릴 수 있습니다.');
    }
    if (state.cohortInvestments.acknowledgedForDay(state.day)) {
      return reject('오늘 결과표를 닫은 뒤에는 빌릴 수 없습니다.');
    }
    if (state.cohortInvestments.hasOutstandingPlayerBorrowing) {
      return reject('먼저 기존 동기 차입금을 모두 갚아야 합니다.');
    }
    if (!state.needsTradingRecovery) {
      return reject('보유 주식이 없고 주문 가능금이 1만원 미만일 때만 긴급 차입할 수 있습니다.');
    }
    if (state.cohortInvestments.loanedForDay(state.day)) {
      return reject('돈을 빌리거나 빌려주는 행동은 하루에 한 번만 가능합니다.');
    }
    final profile = cohortNpcInvestorProfileById(lenderId);
    final lenderRow = report.resultFor(lenderId);
    final player = report.resultFor('player');
    if (profile == null || lenderRow == null || player == null) {
      return reject('데시멀 결과표에 없는 동기입니다.');
    }
    final lenderAccount = state.cohortInvestments.accountFor(lenderId);
    final maximum = math.min(
      cohortPlayerBorrowingLimit,
      math.max(0, lenderAccount.balance - cohortNpcEmergencyReserve),
    );
    if (amount <= 0 || amount > maximum) {
      return reject(
        maximum <= 0
            ? '${profile.name}도 지금 빌려줄 여유가 없습니다.'
            : '${profile.name}에게는 최대 $maximum원까지 빌릴 수 있습니다.',
      );
    }

    final loan = CohortLoan(
      id: 'cohort-borrow-${state.day}-$lenderId',
      borrowerId: lenderId,
      borrowerName: profile.name,
      issuedDay: state.day,
      dueDay: state.day + cohortLoanTermDays,
      principal: amount,
      direction: CohortLoanDirection.playerBorrows,
      interestRateBps: cohortLoanInterestRateBps,
    );
    final updatedRows = <CohortDailyInvestmentResult>[
      for (final row in report.rows)
        if (row.investorId == 'player')
          row.copyWith(totalAmount: row.totalAmount + amount)
        else if (row.investorId == lenderId)
          row.copyWith(totalAmount: math.max(0, row.totalAmount - amount))
        else
          row,
    ];
    final updatedReport = report.copyWith(rows: updatedRows);
    final reports = <CohortDailyInvestmentReport>[
      for (final item in state.cohortInvestments.reports)
        if (item.day == state.day) updatedReport else item,
    ];
    final sourceId = loan.id;
    final next = state.copyWith(
      cash: state.cash + amount,
      brokerageCash: state.brokerageCash + amount,
      cohortInvestments: state.cohortInvestments.copyWith(
        accounts: <String, CohortInvestorAccount>{
          ...state.cohortInvestments.accounts,
          lenderId: lenderAccount.copyWith(
            balance: lenderAccount.balance - amount,
          ),
        },
        reports: reports,
        loans: <CohortLoan>[...state.cohortInvestments.loans, loan],
        lastLoanDay: state.day,
        previousPlayerCloseTotal:
            (state.cohortInvestments.previousPlayerCloseTotal ??
                player.totalAmount) +
            amount,
      ),
      ledger: <LedgerEntry>[
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: amount,
          account: 'brokerage_cash',
          counterAccount: 'cohort_loan_payable',
          description:
              '${profile.name}에게 긴급 차입 · 원금 $amount원 · $cohortLoanTermDays일 뒤 이자 ${loan.interest}원 포함 상환',
          sourceId: sourceId,
          notional: amount,
          marketMinute: krxCloseMinute,
        ),
      ],
    );
    return CohortInvestmentActionResult(
      state: next,
      success: true,
      message:
          '${profile.name}에게 $amount원을 빌렸습니다. $cohortLoanTermDays일 뒤 ${loan.totalDue}원을 갚아야 합니다.',
      report: updatedReport,
      loan: loan,
    );
  }

  CohortInvestmentActionResult acknowledgeCohortInvestmentReport(
    GameState state,
  ) {
    final report = state.cohortInvestments.reportForDay(state.day);
    if (report == null || !state.cohortInvestments.settledForDay(state.day)) {
      return CohortInvestmentActionResult(
        state: state,
        success: false,
        message: '확인할 오늘의 투자 결과가 없습니다.',
      );
    }
    final next = state.copyWith(
      cohortInvestments: state.cohortInvestments.copyWith(
        lastAcknowledgedDay: state.day,
      ),
    );
    return CohortInvestmentActionResult(
      state: next,
      success: true,
      message: '오늘의 결과표를 확인했습니다.',
      report: report,
    );
  }

  RelationshipActionResult completeRelationshipEvening(
    GameState state, {
    required String girlId,
    required RelationshipActivity activity,
    required String choiceId,
  }) {
    if (state.relationships.completedEveningForDay(state.day)) {
      return RelationshipActionResult(
        state: state,
        success: false,
        message: '오늘의 관계 시간은 이미 보냈습니다.',
      );
    }
    final profile = cohortGirlProfileById(girlId);
    if (profile == null) {
      return RelationshipActionResult(
        state: state,
        success: false,
        message: '여자 동기 명단에 없는 인물입니다.',
      );
    }
    final progress = state.relationships.progressFor(girlId);
    if (activity == RelationshipActivity.date && !progress.dateUnlocked) {
      return RelationshipActionResult(
        state: state,
        success: false,
        girlId: girlId,
        activity: activity,
        affectionBefore: progress.affection,
        affectionAfter: progress.affection,
        message: '호감도 $relationshipDateUnlockAffection부터 데이트를 신청할 수 있습니다.',
      );
    }
    if (activity == RelationshipActivity.date &&
        !relationshipOutingAvailableOn(state.currentDate)) {
      return RelationshipActionResult(
        state: state,
        success: false,
        girlId: girlId,
        activity: activity,
        affectionBefore: progress.affection,
        affectionAfter: progress.affection,
        message: '센터 밖 외출은 주식시장이 쉬는 토·일요일에만 가능합니다.',
      );
    }

    final scene = relationshipSceneFor(
      profile: profile,
      activity: activity,
      day: state.day,
      interactionCount: activity == RelationshipActivity.date
          ? progress.dateCount
          : progress.conversationCount,
      affection: progress.affection,
    );
    RelationshipChoiceDefinition? choice;
    for (final candidate in scene.choices) {
      if (candidate.id == choiceId) {
        choice = candidate;
        break;
      }
    }
    if (choice == null) {
      return RelationshipActionResult(
        state: state,
        success: false,
        girlId: girlId,
        activity: activity,
        affectionBefore: progress.affection,
        affectionAfter: progress.affection,
        message: '이 장면에서 사용할 수 없는 선택지입니다.',
      );
    }

    final before = progress.affection;
    final after = (before + choice.affectionDelta)
        .clamp(relationshipMinAffection, relationshipMaxAffection)
        .toInt();
    final appliedDelta = after - before;
    final trustChoiceDelta = choice.affectionDelta >= 0
        ? (choice.affectionDelta + 1) ~/ 2
        : choice.affectionDelta;
    final closenessChoiceDelta = choice.affectionDelta >= 0
        ? choice.affectionDelta
        : -((-choice.affectionDelta + 1) ~/ 2);
    final nextTrust = (progress.trust + trustChoiceDelta)
        .clamp(relationshipDimensionMin, relationshipDimensionMax)
        .toInt();
    final nextCloseness = (progress.closeness + closenessChoiceDelta)
        .clamp(relationshipDimensionMin, relationshipDimensionMax)
        .toInt();
    final trustDelta = nextTrust - progress.trust;
    final closenessDelta = nextCloseness - progress.closeness;
    final beforeStage = relationshipStageFor(before);
    final afterStage = relationshipStageFor(after);
    final updatedProgress = progress.copyWith(
      affection: after,
      trust: nextTrust,
      closeness: nextCloseness,
      lastInteractionDay: state.day,
      conversationCount:
          progress.conversationCount +
          (activity == RelationshipActivity.conversation ? 1 : 0),
      dateCount:
          progress.dateCount + (activity == RelationshipActivity.date ? 1 : 0),
    );
    final updatedGirls = <String, GirlRelationshipProgress>{
      ...state.relationships.girls,
      girlId: updatedProgress,
    };
    final updatedMemories = <RelationshipMemory>[
      ...state.relationships.memories,
      RelationshipMemory(
        day: state.day,
        girlId: girlId,
        activity: activity,
        sceneId: scene.id,
        choiceId: choice.id,
        affectionDelta: appliedDelta,
        affectionAfter: after,
        trustDelta: trustDelta,
        closenessDelta: closenessDelta,
      ),
    ];
    final trimmedMemories =
        updatedMemories.length <= relationshipMemoryHistoryLimit
        ? updatedMemories
        : updatedMemories.sublist(
            updatedMemories.length - relationshipMemoryHistoryLimit,
          );
    final next = state.copyWith(
      relationships: state.relationships.copyWith(
        girls: updatedGirls,
        lastEveningEventDay: state.day,
        memories: trimmedMemories,
      ),
    );
    return RelationshipActionResult(
      state: next,
      success: true,
      message: '${profile.name}과의 저녁 시간을 보냈습니다.',
      girlId: girlId,
      activity: activity,
      affectionBefore: before,
      affectionAfter: after,
      affectionDelta: appliedDelta,
      response: choice.response,
      dateJustUnlocked:
          before < relationshipDateUnlockAffection &&
          after >= relationshipDateUnlockAffection,
      stageJustUnlocked: afterStage != beforeStage && after > before
          ? afterStage
          : null,
    );
  }

  RelationshipActionResult restDuringRelationshipEvening(GameState state) {
    if (state.relationships.completedEveningForDay(state.day)) {
      return RelationshipActionResult(
        state: state,
        success: false,
        message: '오늘의 관계 시간은 이미 보냈습니다.',
      );
    }
    final next = state.copyWith(
      relationships: state.relationships.copyWith(
        lastEveningEventDay: state.day,
      ),
    );
    return RelationshipActionResult(
      state: next,
      success: true,
      message: '오늘은 혼자 쉬며 하루를 정리했습니다.',
    );
  }

  WeekdayActivityResult completeWeekdayActivity(
    GameState state,
    String activityId,
  ) {
    final activity = weekdayActivityById(activityId);
    if (activity == null) {
      return WeekdayActivityResult(
        state: state,
        success: false,
        message: '선택할 수 없는 저녁 업무입니다.',
      );
    }
    if (state.currentDate.weekday >= DateTime.saturday) {
      return WeekdayActivityResult(
        state: state,
        success: false,
        message: '평일 저녁 업무는 월요일부터 금요일까지만 선택할 수 있습니다.',
      );
    }
    if (state.pendingDecisions.isNotEmpty) {
      return WeekdayActivityResult(
        state: state,
        success: false,
        message: '새 기록을 먼저 확인하고 결정을 마쳐야 저녁 업무를 볼 수 있습니다.',
      );
    }
    if (state.marketMinute < krxCloseMinute) {
      return WeekdayActivityResult(
        state: state,
        success: false,
        message: '15:00까지는 주식장 준비와 거래 시간입니다. 장 마감 후 이용하세요.',
      );
    }
    final finishingCasinoAtClose =
        activity.id == 'casino' &&
        state.marketMinute == marketDayEndMinute &&
        state.personalFinance.casino.roundsForDay(state.day) > 0;
    if (state.marketMinute >= marketDayEndMinute && !finishingCasinoAtClose) {
      return WeekdayActivityResult(
        state: state,
        success: false,
        message: '오늘 저녁 업무는 이미 끝났습니다. 다음 날로 넘어가세요.',
      );
    }
    if ((activity.id == 'casino' || activity.id == 'horse_racing') &&
        (state.currentDate.isBefore(DateTime(2010, 1, 1)) ||
            state.story.ageOn(state.currentDate) < 20)) {
      return WeekdayActivityResult(
        state: state,
        success: false,
        message: '카지노와 경마는 성인이 되는 2010년부터 선택할 수 있습니다.',
        activity: activity,
      );
    }
    if (activity.id == 'bank' && !bankAccessUnlocked(state)) {
      return WeekdayActivityResult(
        state: state,
        success: false,
        message: '윤하린 은행원 소개 이야기를 먼저 확인해야 은행 업무가 열립니다.',
        activity: activity,
      );
    }
    if (activity.id == 'real_estate' && !realEstateAccessUnlocked(state)) {
      return WeekdayActivityResult(
        state: state,
        success: false,
        message: '서하늘 공인중개사 소개 이야기를 먼저 확인해야 부동산 업무가 열립니다.',
        activity: activity,
      );
    }
    if (weekdayEveningUsed(state)) {
      return WeekdayActivityResult(
        state: state,
        success: false,
        message: '오늘의 저녁 행동은 이미 사용했습니다.',
        activity: activity,
      );
    }
    if (activity.id != 'casino' &&
        state.personalFinance.casino.roundsForDay(state.day) > 0) {
      return WeekdayActivityResult(
        state: state,
        success: false,
        message: '오늘은 이미 카지노를 선택해 저녁 시간을 사용했습니다.',
        activity: activity,
      );
    }

    final casinoRecords = state.personalFinance.casino.history
        .where((record) => record.day == state.day)
        .toList(growable: false);
    final startMinute = activity.id == 'casino' && casinoRecords.isNotEmpty
        ? casinoRecords.first.minute
        : state.marketMinute;
    const endMinute = marketDayEndMinute;
    final log = WeekdayActivityLog(
      day: state.day,
      activityId: activity.id,
      title: activity.title,
      startMinute: startMinute,
      endMinute: endMinute,
    );
    final flags = Map<String, dynamic>.from(state.story.storyFlags);
    final logs = <WeekdayActivityLog>[
      ...weekdayActivityLogsForState(state),
      log,
    ];
    final trimmed = logs.length <= weekdayActivityHistoryLimit
        ? logs
        : logs.sublist(logs.length - weekdayActivityHistoryLimit);
    flags[weekdayActivityLogFlag] = trimmed
        .map((entry) => entry.toJson())
        .toList(growable: false);
    final progression = state.progression.record(weekdayActivityCounterMetric);
    final next = state.copyWith(
      marketMinute: endMinute,
      progression: progression,
      story: state.story.copyWith(storyFlags: flags),
    );
    return WeekdayActivityResult(
      state: next,
      success: true,
      message:
          '${activity.title} · 오늘 저녁 사용 · ${marketTimeLabel(startMinute)} → 20:00',
      activity: activity,
      startMinute: startMinute,
      endMinute: endMinute,
    );
  }

  HorseRaceActionResult completeHorseRace(
    GameState state,
    HorseRaceSessionResult session,
  ) {
    HorseRaceActionResult failure(String message) =>
        HorseRaceActionResult(state: state, success: false, message: message);

    if (state.currentDate.weekday >= DateTime.saturday) {
      return failure('경마는 월요일부터 금요일까지 장 마감 뒤에만 이용할 수 있습니다.');
    }
    if (state.currentDate.isBefore(DateTime(2010, 1, 1)) ||
        state.story.ageOn(state.currentDate) < 20) {
      return failure('경마는 성인이 되는 2010년부터 이용할 수 있습니다.');
    }
    if (state.pendingDecisions.isNotEmpty) {
      return failure('새 기록의 결정을 먼저 마쳐야 경마 중계를 볼 수 있습니다.');
    }
    if (horseRaceDailyLimitReached(state)) {
      return failure('오늘의 경마 베팅 한도 $horseRaceDailyBetLimit회를 모두 사용했습니다.');
    }
    if (state.marketMinute < krxCloseMinute) {
      return failure('경마는 15:00 장 마감 뒤에 이용할 수 있습니다.');
    }
    if (state.marketMinute >= marketDayEndMinute) {
      return failure('오늘 경마 이용 시간은 끝났습니다. 다음 평일에 이용하세요.');
    }
    if (state.personalFinance.casino.roundsForDay(state.day) > 0) {
      return failure('오늘은 이미 카지노를 이용해 경마를 선택할 수 없습니다.');
    }
    if (weekdayEveningUsed(state)) {
      return failure('오늘의 저녁 행동은 이미 사용했습니다.');
    }
    if (session.stake < horseRaceMinStake ||
        session.stake > horseRaceMaxStake) {
      return failure('전자 마권 금액은 500원부터 5,000원까지 선택할 수 있습니다.');
    }
    if (state.bankCash < session.stake) {
      return failure('생활비 통장에 ${session.stake - state.bankCash}원이 부족합니다.');
    }

    final race = buildAfternoonHorseRace(
      simulationSeed: state.simulationSeed,
      day: state.day,
    );
    if (session.raceId != race.id) {
      return failure('현재 국가망 회차와 다른 전자 마권입니다. 경주표를 다시 확인해 주세요.');
    }
    final primary = race.entrants
        .where((entrant) => entrant.id == session.primaryHorseId)
        .firstOrNull;
    final secondary = session.secondaryHorseId == null
        ? null
        : race.entrants
              .where((entrant) => entrant.id == session.secondaryHorseId)
              .firstOrNull;
    if (primary == null ||
        (session.betType == HorseBetType.quinella && secondary == null)) {
      return failure('출전표에 없는 말을 선택한 전자 마권입니다.');
    }
    final grossPayout = calculateHorseRacePayout(
      race: race,
      betType: session.betType,
      primaryHorseId: session.primaryHorseId,
      secondaryHorseId: session.secondaryHorseId,
      stake: session.stake,
    );
    if (grossPayout != session.grossPayout ||
        session.finishOrder.join('|') != race.finishOrder.join('|')) {
      return failure('배당 또는 착순 정산값이 현재 경주 결과와 맞지 않습니다.');
    }
    final stateProfitFee = horseRaceStateProfitFee(
      stake: session.stake,
      grossPayout: grossPayout,
      recoveryRateBps: state.story.stateRecoveryRateBps,
    );
    final sourceId = 'horse-race-${state.day}-${race.id}';
    if (state.processedEventIds.contains(sourceId)) {
      return failure('이 경주의 전자 마권은 이미 정산했습니다.');
    }

    final netDelta = grossPayout - session.stake - stateProfitFee;
    final selectionLabel = session.betType == HorseBetType.quinella
        ? '${primary.name}·${secondary!.name}'
        : primary.name;
    final settled = state.copyWith(
      cash: state.cash + netDelta,
      ledger: <LedgerEntry>[
        ...state.ledger,
        LedgerEntry(
          id: '$sourceId-stake',
          day: state.day,
          amount: -session.stake,
          account: 'company_bank',
          counterAccount: 'horse_racing_wager_expense',
          description: '${session.betType.label} 전자 마권 · $selectionLabel',
          sourceId: sourceId,
        ),
        if (grossPayout > 0)
          LedgerEntry(
            id: '$sourceId-payout',
            day: state.day,
            amount: grossPayout,
            account: 'company_bank',
            counterAccount: 'horse_racing_payout_income',
            description: '경마 전자 마권 적중 배당',
            sourceId: sourceId,
          ),
        if (stateProfitFee > 0)
          LedgerEntry(
            id: '$sourceId-national-fee',
            day: state.day,
            amount: -stateProfitFee,
            account: 'company_bank',
            counterAccount: 'state_horse_racing_fee',
            description: '경마 확정 이익 국가 수수료 20%',
            sourceId: sourceId,
          ),
      ],
      processedEventIds: <String>[...state.processedEventIds, sourceId],
    );
    final evening = completeWeekdayActivity(settled, 'horse_racing');
    if (!evening.success) {
      return failure(evening.message);
    }
    final settlementMessage = grossPayout > 0
        ? '${session.betType.label} 적중 · 배당 $grossPayout원 · 국가 수수료 $stateProfitFee원 · 순이익 ${netDelta >= 0 ? '+' : ''}$netDelta원'
        : '${session.betType.label} 미적중 · 전자 마권 -${session.stake}원 · 국가 수수료 0원';
    return HorseRaceActionResult(
      state: evening.state,
      success: true,
      message:
          '$settlementMessage\n오늘 경마 $horseRaceDailyBetLimit/$horseRaceDailyBetLimit회 완료 · 20:00으로 이동',
      cashDelta: netDelta,
    );
  }

  WeekendActivityResult completeWeekendActivity(
    GameState state,
    WeekendActivityRequest request,
  ) {
    if (!relationshipOutingAvailableOn(state.currentDate)) {
      return WeekendActivityResult(
        state: state,
        success: false,
        message: '주말 일정은 토요일과 일요일에만 열립니다.',
      );
    }
    final remaining = weekendActivityPointsRemaining(state);
    if (remaining <= 0) {
      return WeekendActivityResult(
        state: state,
        success: false,
        message: '오늘의 주말 행동력은 모두 사용했습니다.',
      );
    }

    final job = weekendJobById(request.activityId);
    if (job != null) {
      if (job.requiresMiniGame &&
          (request.workScore == null || request.workMaxScore == null)) {
        return WeekendActivityResult(
          state: state,
          success: false,
          message: '신문배달 코스를 먼저 완주해야 수당을 정산할 수 있습니다.',
        );
      }
      final score =
          request.workScore ??
          72 +
              _stableHash(
                    '${state.simulationSeed}:${state.day}:weekend:${job.id}:'
                    '${weekendActivityPointsUsed(state)}',
                  ) %
                  27;
      final maxScore = request.workMaxScore ?? 100;
      final worked = completeWorkSession(
        state,
        WorkSessionResult(
          activityId: job.workActivityId,
          score: score,
          maxScore: maxScore,
        ),
      );
      final earned = worked.cash - state.cash;
      if (earned <= 0) {
        return WeekendActivityResult(
          state: state,
          success: false,
          message: '오늘 받을 수 있는 알바 수당을 이미 모두 정산했습니다.',
        );
      }
      final rescueFunded = state.needsTradingRecovery
          ? transferBrokerageCash(worked, amount: earned, deposit: true).state
          : worked;
      final next = _appendWeekendActivityLog(
        rescueFunded,
        WeekendActivityLog(
          day: state.day,
          kind: WeekendActivityKind.partTimeJob,
          activityId: job.id,
          title: job.title,
          body: state.needsTradingRecovery
              ? '${job.location}에서 ${job.requiresMiniGame ? '배달 정확도 ${score.clamp(0, maxScore)}점으로 ' : ''}$earned원을 벌어 실전 증권계좌에 바로 넣었다.'
              : '${job.location}에서 ${job.requiresMiniGame ? '배달 정확도 ${score.clamp(0, maxScore)}점으로 ' : ''}맡은 일을 마치고 $earned원을 벌었다.',
          markerLabel: '알바',
          accentValue: job.accentValue,
          imageAsset: job.imageAsset,
          cashDelta: earned,
        ),
      );
      return WeekendActivityResult(
        state: next,
        success: true,
        message: state.needsTradingRecovery
            ? '${job.title} 완료 · 수당 $earned원을 실전 증권계좌에 입금'
            : '${job.title} 완료 · 수당 +$earned원',
        cashDelta: earned,
      );
    }

    if (request.activityId == 'market_study') {
      final flags = Map<String, dynamic>.from(state.story.storyFlags);
      final credits =
          (flags[weekendMarketResearchCreditsFlag] as num?)?.toInt() ?? 0;
      flags[weekendMarketResearchCreditsFlag] = (credits + 1).clamp(0, 3);
      final prepared = state.copyWith(
        story: state.story.copyWith(storyFlags: flags),
      );
      final next = _appendWeekendActivityLog(
        prepared,
        WeekendActivityLog(
          day: state.day,
          kind: WeekendActivityKind.marketStudy,
          activityId: request.activityId,
          title: '도서관 시장 복기',
          body: '지난 신문과 장부를 대조해 다음 거래일 조사보고서 1회 이용권을 준비했다.',
          markerLabel: '공부',
          accentValue: 0xFF5C79A9,
          imageAsset: weekendLibraryAsset,
        ),
      );
      return WeekendActivityResult(
        state: next,
        success: true,
        message: '다음 거래일 조사보고서 1회 이용권을 준비했습니다.',
      );
    }

    if (request.activityId == 'gift') {
      final girlId = request.girlId;
      final giftId = request.giftId;
      final profile = girlId == null ? null : cohortGirlProfileById(girlId);
      final gift = giftId == null ? null : weekendGiftById(giftId);
      if (profile == null || gift == null) {
        return WeekendActivityResult(
          state: state,
          success: false,
          message: '선물과 받을 동기를 모두 골라야 합니다.',
        );
      }
      if (kBeautyGiftAlreadyGivenToday(state)) {
        return WeekendActivityResult(
          state: state,
          success: false,
          message: '선물은 매장과 톡을 합쳐 하루에 한 번만 줄 수 있어요.',
        );
      }
      if (state.bankCash < gift.cost) {
        return WeekendActivityResult(
          state: state,
          success: false,
          message: '생활비 통장에 ${gift.cost - state.bankCash}원이 부족합니다.',
        );
      }

      final repeatCount = kBeautyGiftMonthlyRepeatCount(
        state,
        girlId: profile.id,
        giftId: gift.id,
      );
      final progress = state.relationships.progressFor(profile.id);
      final requestedAffection = gift.affectionFor(
        profile.id,
        monthlyRepeatCount: repeatCount,
      );
      final nextAffection = (progress.affection + requestedAffection)
          .clamp(relationshipMinAffection, relationshipMaxAffection)
          .toInt();
      final affectionDelta = nextAffection - progress.affection;
      final nextTrust =
          (progress.trust +
                  gift.trustFor(profile.id, monthlyRepeatCount: repeatCount))
              .clamp(relationshipDimensionMin, relationshipDimensionMax)
              .toInt();
      final nextCloseness =
          (progress.closeness + (requestedAffection > 0 ? 1 : 0))
              .clamp(relationshipDimensionMin, relationshipDimensionMax)
              .toInt();
      final reaction = kBeautyGiftReaction(
        state,
        gift: gift,
        girlId: profile.id,
        monthlyRepeatCount: repeatCount,
      );
      final updatedProgress = progress.copyWith(
        affection: nextAffection,
        trust: nextTrust,
        closeness: nextCloseness,
        lastInteractionDay: state.day,
      );
      final memory = RelationshipMemory(
        day: state.day,
        girlId: profile.id,
        activity: RelationshipActivity.gift,
        sceneId: 'weekend_gift_${gift.id}',
        choiceId: gift.id,
        affectionDelta: affectionDelta,
        affectionAfter: nextAffection,
        trustDelta: nextTrust - progress.trust,
        closenessDelta: nextCloseness - progress.closeness,
      );
      final memories = <RelationshipMemory>[
        ...state.relationships.memories,
        memory,
      ];
      final sourceId = 'weekend-gift-${state.day}-${profile.id}-${gift.id}';
      final gifted = state.copyWith(
        cash: state.cash - gift.cost,
        relationships: state.relationships.copyWith(
          girls: <String, GirlRelationshipProgress>{
            ...state.relationships.girls,
            profile.id: updatedProgress,
          },
          memories: memories.length <= relationshipMemoryHistoryLimit
              ? memories
              : memories.sublist(
                  memories.length - relationshipMemoryHistoryLimit,
                ),
        ),
        ledger: <LedgerEntry>[
          ...state.ledger,
          LedgerEntry(
            id: sourceId,
            day: state.day,
            amount: -gift.cost,
            account: 'company_bank',
            counterAccount: 'relationship_gift_expense',
            description: '${profile.name}에게 건넬 ${gift.title}',
            sourceId: sourceId,
          ),
        ],
        processedEventIds: <String>[...state.processedEventIds, sourceId],
      );
      final next = _appendWeekendActivityLog(
        gifted,
        WeekendActivityLog(
          day: state.day,
          kind: WeekendActivityKind.gift,
          activityId: gift.id,
          title: '${profile.name}에게 고른 선물',
          body:
              '${gift.title}을 골라 건넸다. ${kBeautyGiftRepeatLabel(repeatCount)} · 생활비 -${gift.cost}원 · 호감도 +$affectionDelta. $reaction',
          markerLabel: '선물',
          accentValue: profile.accentValue,
          imageAsset: gift.imageAsset,
          cashDelta: -gift.cost,
          girlId: profile.id,
          affectionDelta: affectionDelta,
        ),
      );
      return WeekendActivityResult(
        state: next,
        success: true,
        message:
            '${profile.name}에게 ${gift.title}을 건넸습니다. ${kBeautyGiftRepeatLabel(repeatCount)} · 호감도 +$affectionDelta\n$reaction',
        cashDelta: -gift.cost,
        affectionDelta: affectionDelta,
      );
    }

    if (request.activityId == 'rest') {
      final cost = remaining;
      final next = _appendWeekendActivityLog(
        state,
        WeekendActivityLog(
          day: state.day,
          kind: WeekendActivityKind.rest,
          activityId: request.activityId,
          title: '천천히 보내는 주말',
          body: '남은 시간을 비워 두고 몸과 장부를 함께 정리했다.',
          markerLabel: '휴식',
          accentValue: 0xFF7B8DA8,
          imageAsset: weekendNeighborhoodAsset,
          actionPointCost: cost,
        ),
      );
      return WeekendActivityResult(
        state: next,
        success: true,
        message: '남은 주말 시간을 쉬면서 정리했습니다.',
      );
    }

    return WeekendActivityResult(
      state: state,
      success: false,
      message: '선택할 수 없는 주말 활동입니다.',
    );
  }

  GameState _appendWeekendActivityLog(GameState state, WeekendActivityLog log) {
    final flags = Map<String, dynamic>.from(state.story.storyFlags);
    final logs = <WeekendActivityLog>[
      ...weekendActivityLogsForState(state),
      log,
    ];
    final trimmed = logs.length <= weekendActivityHistoryLimit
        ? logs
        : logs.sublist(logs.length - weekendActivityHistoryLimit);
    flags[weekendActivityLogFlag] = trimmed
        .map((entry) => entry.toJson())
        .toList(growable: false);
    return state.copyWith(story: state.story.copyWith(storyFlags: flags));
  }

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
    final isStandardSeedStart =
        initialCompanyCash > 0 && initialCash == initialCompanyCash;
    final seedMoneySource = 'project_decimal_fund';
    const seedMoneySourceId = stateAccountSeedCapitalSourceId;
    final storyState = isStandardSeedStart
        ? baseStory.copyWith(
            accountAuthorityLevel: math.max(1, baseStory.accountAuthorityLevel),
            storyFlags: {
              ...baseStory.storyFlags,
              'startingSeedMoney': initialCompanyCash,
              'seedMoneySource': seedMoneySource,
              'firstSeedGoalReached': true,
            },
          )
        : initialCash > initialCompanyCash
        ? baseStory.copyWith(
            accountAuthorityLevel: math.max(5, baseStory.accountAuthorityLevel),
            storyFlags: {
              ...baseStory.storyFlags,
              'firstSeedGoalReached': initialCash >= 10000,
            },
          )
        : baseStory.copyWith(
            storyFlags: {
              ...baseStory.storyFlags,
              'firstSeedGoalReached':
                  baseStory.startingSeedMoney + baseStory.earnedSeedMoney >=
                  10000,
            },
          );
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
      organization: OrganizationState.initial(storyState.operatingPrinciple),
      personalFinance: PersonalFinanceState.initial(),
      progression: PlayerProgressionState.initial(),
      story: storyState,
      company: company,
      project: null,
      decisions: const [],
      scheduledEvents: const [],
      ledger: isStandardSeedStart
          ? [
              LedgerEntry(
                id: seedMoneySourceId,
                day: 1,
                amount: initialCompanyCash,
                account: 'brokerage_cash',
                counterAccount: 'state_seed_capital',
                description: '대한민국 데시멀 기금 · 국가계좌 원금',
                sourceId: seedMoneySourceId,
              ),
            ]
          : const [],
      processedEventIds: isStandardSeedStart ? [seedMoneySourceId] : const [],
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
    // Migrated saves keep their recorded balance and do not receive the
    // academy state-account principal a second time.
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
          operatingPrinciple: fresh.story.operatingPrinciple,
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
    final companyIsFictional =
        state.company.id == 'hanbit_components' ||
        isCurrentWorldAsset(state.company.id);
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

  double _playerOwnedUnits(GameState state, String assetId) => state.positions
      .where((position) => position.assetId == assetId)
      .fold<double>(0, (sum, position) => sum + position.units);

  double _playerTenderAcquiredUnits(GameState state, String assetId) =>
      state.shareholderGovernance.companyById(assetId)?.tenderAcquiredShares ??
      0;

  bool _exceedsMaximumQuoteQuantity(TradeOrder order) {
    final outstanding = order.maximumPositionUnits;
    if (outstanding == null || outstanding <= 0) return false;
    return order.quantity > gameMaximumQuoteQuantity(outstanding) + 0.000001;
  }

  bool _wouldExceedIssuedShares(
    GameState state,
    TradeOrder order, {
    required bool includePendingBuys,
  }) {
    final maximum = order.maximumPositionUnits;
    if (order.side != TradeSide.buy || maximum == null) return false;
    if (maximum <= 0) return true;
    final owned = _playerOwnedUnits(state, order.assetId);
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
    final maximumPositionUnits = order.maximumPositionUnits;
    final inventoryMatches =
        !snapshot.hasIssuedShareLedger ||
        (snapshot.ownershipIsConserved &&
            maximumPositionUnits != null &&
            snapshot.sharesOutstanding == maximumPositionUnits &&
            snapshot.playerOwnedShares ==
                _playerOwnedUnits(
                  state,
                  order.assetId,
                ).round().clamp(0, maximumPositionUnits) &&
            snapshot.playerTenderAcquiredShares ==
                _playerTenderAcquiredUnits(
                  state,
                  order.assetId,
                ).round().clamp(0, maximumPositionUnits));
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
        inventoryMatches &&
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
    if (_wouldExceedIssuedShares(state, order, includePendingBuys: true)) {
      return reject('보유·미체결 수량을 합쳐 발행주식 수를 넘길 수 없습니다.');
    }
    if (_exceedsMaximumQuoteQuantity(order)) {
      return reject('1회 주문은 상장주식의 5%와 1억 주 중 작은 수량까지만 가능합니다.');
    }
    if (!_displayedOrderBookSnapshotMatchesOrder(state, order)) {
      return reject(_staleDisplayedOrderBookMessage);
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
          playerOwnedUnits: _playerOwnedUnits(state, order.assetId),
          playerTenderAcquiredUnits: _playerTenderAcquiredUnits(
            state,
            order.assetId,
          ),
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

  List<PendingTradeOrder> _pendingOrdersAfterQueueRelease(
    Iterable<PendingTradeOrder> orders, {
    required PendingTradeOrder source,
    required double releasedQuantity,
    required bool removeSource,
  }) {
    final released = math.max(0.0, releasedQuantity);
    return <PendingTradeOrder>[
      for (final order in orders)
        if (order.id != source.id || !removeSource)
          order.id == source.id ||
                  released <= 0 ||
                  order.assetId != source.assetId ||
                  order.side != source.side ||
                  (order.limitPrice - source.limitPrice).abs() >= 0.000001 ||
                  order.placedSequence <= source.placedSequence
              ? order
              : order.copyWith(
                  queueAheadQuantity: math.max(
                    0.0,
                    order.queueAheadQuantity - released,
                  ),
                ),
    ];
  }

  List<PendingTradeOrder> _pendingOrdersInExchangePriority(
    Iterable<PendingTradeOrder> source,
  ) {
    int withinSide(PendingTradeOrder left, PendingTradeOrder right) {
      final priceOrder = left.side == PendingOrderSide.buy
          ? right.limitPrice.compareTo(left.limitPrice)
          : left.limitPrice.compareTo(right.limitPrice);
      if (priceOrder != 0) return priceOrder;
      final dateOrder = left.placedDate.compareTo(right.placedDate);
      if (dateOrder != 0) return dateOrder;
      final minuteOrder = left.placedMinute.compareTo(right.placedMinute);
      if (minuteOrder != 0) return minuteOrder;
      final sequenceOrder = left.placedSequence.compareTo(right.placedSequence);
      return sequenceOrder != 0 ? sequenceOrder : left.id.compareTo(right.id);
    }

    int chronological(PendingTradeOrder left, PendingTradeOrder right) {
      final dateOrder = left.placedDate.compareTo(right.placedDate);
      if (dateOrder != 0) return dateOrder;
      final minuteOrder = left.placedMinute.compareTo(right.placedMinute);
      if (minuteOrder != 0) return minuteOrder;
      final sequenceOrder = left.placedSequence.compareTo(right.placedSequence);
      return sequenceOrder != 0 ? sequenceOrder : left.id.compareTo(right.id);
    }

    final buys =
        source
            .where((order) => order.side == PendingOrderSide.buy)
            .toList(growable: true)
          ..sort(withinSide);
    final sells =
        source
            .where((order) => order.side == PendingOrderSide.sell)
            .toList(growable: true)
          ..sort(withinSide);
    final ordered = <PendingTradeOrder>[];
    var buyIndex = 0;
    var sellIndex = 0;
    while (buyIndex < buys.length || sellIndex < sells.length) {
      if (buyIndex >= buys.length) {
        ordered.add(sells[sellIndex++]);
      } else if (sellIndex >= sells.length) {
        ordered.add(buys[buyIndex++]);
      } else if (chronological(buys[buyIndex], sells[sellIndex]) <= 0) {
        ordered.add(buys[buyIndex++]);
      } else {
        ordered.add(sells[sellIndex++]);
      }
    }
    return ordered;
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
    final pending = _pendingOrdersAfterQueueRelease(
      state.pendingOrders,
      source: order,
      releasedQuantity: order.remainingQuantity,
      removeSource: true,
    );
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
      playerOwnedUnits: _playerOwnedUnits(state, assetId),
      playerTenderAcquiredUnits: _playerTenderAcquiredUnits(state, assetId),
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
    final candidates = _pendingOrdersInExchangePriority(eligibleOrders);

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
        pendingOrders: _pendingOrdersAfterQueueRelease(
          next.pendingOrders,
          source: current,
          releasedQuantity: fillQuantity,
          removeSource: true,
        ),
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
    final candidates = _pendingOrdersInExchangePriority(
      state.pendingOrders.where(
        (order) =>
            order.assetId == assetId &&
            order.placedDate == stateDate &&
            order.placedMinute <= krxCloseMinute,
      ),
    );
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
      playerOwnedUnits: _playerOwnedUnits(state, assetId),
      playerTenderAcquiredUnits: _playerTenderAcquiredUnits(state, assetId),
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
    if (_wouldExceedIssuedShares(state, order, includePendingBuys: true)) {
      return reject('보유·미체결 수량을 합쳐 발행주식 수를 넘길 수 없습니다.');
    }
    if (_exceedsMaximumQuoteQuantity(order)) {
      return reject('1회 주문은 상장주식의 5%와 1억 주 중 작은 수량까지만 가능합니다.');
    }
    if (!_displayedOrderBookSnapshotMatchesOrder(state, order)) {
      return reject(_staleDisplayedOrderBookMessage);
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
          playerOwnedUnits: _playerOwnedUnits(state, order.assetId),
          playerTenderAcquiredUnits: _playerTenderAcquiredUnits(
            state,
            order.assetId,
          ),
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
        return reject('종잣돈 10,000원을 먼저 마련해 국가계좌 승인을 받아야 합니다.');
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
    var stateRecovery = 0;
    var selfRelianceContribution = 0;
    var spendableCashDelta = cashDelta;
    if (state.story.orphanageReboot &&
        order.side == TradeSide.sell &&
        realizedPnl > 0) {
      final recoveryRateBps = state.story.stateRecoveryRateBps
          .clamp(0, 10000)
          .toInt();
      stateRecovery = (realizedPnl * recoveryRateBps / 10000)
          .round()
          .clamp(0, realizedPnl)
          .toInt();
      final liveTrading = state.story.flagBool('liveTradingStarted');
      selfRelianceContribution = liveTrading ? 0 : realizedPnl - stateRecovery;
      spendableCashDelta -= stateRecovery + selfRelianceContribution;
      flags['stateRecoveryTotal'] =
          state.story.stateRecoveryTotal + stateRecovery;
      flags['selfRelianceReserve'] =
          state.story.selfRelianceReserve + selfRelianceContribution;
      description =
          '$description · 국가 환수 $stateRecovery원 · '
          '${liveTrading ? '실전 재투자 가능 ${realizedPnl - stateRecovery}원' : '자립적립 $selfRelianceContribution원'}';
    }
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
    if (earnsDailyTrust) {
      flags['cohortTrust'] = state.story.flagInt('cohortTrust', 30) + 1;
    }
    final next = state.copyWith(
      marketMinute: order.marketMinute,
      brokerageCash: state.brokerageCash + spendableCashDelta,
      cash: state.cash + spendableCashDelta,
      positions: positions,
      progression: progression,
      story: state.story.copyWith(
        accountAuthorityLevel: authority,
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
        if (stateRecovery > 0)
          LedgerEntry(
            id: '$sourceId-state-recovery',
            day: state.day,
            amount: -stateRecovery,
            account: 'brokerage_cash',
            counterAccount: 'state_profit_recovery',
            description: '확정수익 국가 환수 20%',
            sourceId: '$sourceId-state-recovery',
            assetId: order.assetId,
            marketMinute: order.marketMinute,
          ),
        if (selfRelianceContribution > 0)
          LedgerEntry(
            id: '$sourceId-self-reliance',
            day: state.day,
            amount: -selfRelianceContribution,
            account: 'brokerage_cash',
            counterAccount: 'self_reliance_reserve',
            description: '만 19세까지 자립적립금 동결',
            sourceId: '$sourceId-self-reliance',
            assetId: order.assetId,
            marketMinute: order.marketMinute,
          ),
      ],
    );
    return TradeExecutionResult(
      state: next,
      success: true,
      message:
          '${order.name} ${_tradeUnits(order.quantity)}주 $sideLabel 완료 · 증권 수수료 $fee원'
          '${transactionTax > 0 ? ' · 거래세 $transactionTax원' : ''}'
          '${order.side == TradeSide.sell ? ' · 실현손익 ${realizedPnl >= 0 ? '+' : ''}$realizedPnl원' : ''}'
          '${stateRecovery > 0 ? ' · 국가 환수 $stateRecovery원${selfRelianceContribution > 0 ? ' · 자립적립 $selfRelianceContribution원' : ' · 나머지 실전 자금 유지'}' : ''}',
      notional: notional,
      fee: fee,
      transactionTax: transactionTax,
      realizedPnl: realizedPnl,
      filledQuantity: order.quantity,
      averageFillPrice: notional / order.quantity,
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
      'newspaper_delivery' => 900 + normalized * 16,
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
      'newspaper_delivery' => '강남 주택가 조간신문 배달',
      'dishes' => '식당 당번 실습',
      'stationery' => '교육자료 창고 정리',
      'flea_market' => '데시멀 교환장터',
      _ => '원내 실습',
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
        flags['cohortTrust'] = state.story.flagInt('cohortTrust', 30) + 2;
      }
    }

    final next = state.copyWith(
      cash: state.cash + reward,
      progression: state.progression.record('work_sessions').gainExperience(1),
      story: state.story.copyWith(
        accountAuthorityLevel:
            reachedSeedGoal && state.story.accountAuthorityLevel < 1
            ? 1
            : state.story.accountAuthorityLevel,
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
        'practiceTradingDay': state.day,
        'liveTradingStartDay': state.day + 1,
        'liveTradingStarted': false,
      },
    ),
  );

  GameState markBankDepositTutorialSeen(GameState state) => state.copyWith(
    story: state.story.copyWith(
      storyFlags: {
        ...state.story.storyFlags,
        'bankDepositTutorialSeen': true,
        'bankDepositTutorialCompletedDay': state.day,
      },
    ),
  );

  GameState markRealEstateTutorialSeen(GameState state) => state.copyWith(
    story: state.story.copyWith(
      storyFlags: {
        ...state.story.storyFlags,
        'realEstateTutorialSeen': true,
        'realEstateTutorialCompletedDay': state.day,
      },
    ),
  );

  GameState completeInitialPracticeDay(GameState state) {
    final marked = markMarketTutorialSeen(
      state.copyWith(marketMinute: krxCloseMinute),
    );
    // The first research card remains available after the paper-trading day,
    // but it must not trap the player on the practice date.
    final advanced = advanceOneDay(marked.copyWith(decisions: const []));
    return advanced.copyWith(
      decisions: <DecisionCardData>[...marked.decisions],
      story: advanced.story.copyWith(
        storyFlags: <String, dynamic>{
          ...advanced.story.storyFlags,
          'liveTradingStarted': true,
          'liveTradingStartDay': advanced.day,
        },
      ),
    );
  }

  GameState requestAcademyHelp(GameState state, String helperId) {
    final organization = state.organization.requestAcademyHelp(
      helperId,
      state.day,
    );
    if (identical(organization, state.organization)) return state;
    final flags = <String, dynamic>{
      ...state.story.storyFlags,
      'activeResearchHelper': helperId,
      'activeResearchHelperDay': state.day,
      'researchBonusPct': helperId == 'hakjun'
          ? 15
          : helperId == 'sua'
          ? 12
          : 10,
      'reputation': (state.story.reputation + 1).clamp(0, 100),
      'cohortTrust': state.story.flagInt('cohortTrust', 30) + 1,
    };
    if (helperId == 'hakjun') {
      flags['hakjunAffinity'] = state.story.flagInt('hakjunAffinity', 30) + 2;
    } else if (helperId == 'sua') {
      flags['suaAffinity'] = state.story.flagInt('suaAffinity', 30) + 2;
    } else {
      flags['teacherTrust'] = state.story.flagInt('teacherTrust', 30) + 2;
    }
    return state.copyWith(
      organization: organization,
      story: state.story.copyWith(storyFlags: flags),
      progression: state.progression.record('academy_help'),
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

  FinanceActionResult purchaseHomeImprovement(
    GameState state,
    String improvementId,
  ) {
    final improvement = homeImprovementById(improvementId);
    if (improvement == null) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '존재하지 않는 시설 항목입니다.',
      );
    }
    if (state.homeImprovements.has(improvement.id)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '이미 개선한 시설입니다.',
      );
    }
    final prerequisiteId = improvement.prerequisiteId;
    if (prerequisiteId != null && !state.homeImprovements.has(prerequisiteId)) {
      final prerequisite = homeImprovementById(prerequisiteId);
      return FinanceActionResult(
        state: state,
        success: false,
        message: '${prerequisite?.title ?? '앞 단계 시설'}부터 먼저 마련해야 합니다.',
      );
    }
    if (state.bankCash < improvement.cost) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '회사 통장 잔고가 ${improvement.cost - state.bankCash}원 부족합니다.',
      );
    }

    final nextHome = state.homeImprovements.recordPurchase(
      improvement,
      day: state.day,
    );
    final storyEventIds =
        state.story.seenStoryEventIds.contains(improvement.storyEventId)
        ? state.story.seenStoryEventIds
        : <String>[...state.story.seenStoryEventIds, improvement.storyEventId];
    final flags = Map<String, dynamic>.from(state.story.storyFlags)
      ..['cohortTrust'] =
          state.story.flagInt('cohortTrust', 30) +
          improvement.communityTrustDelta;
    final affinityKey = switch (improvement.communityMember) {
      HomeCommunityMember.hakjun => 'hakjunAffinity',
      HomeCommunityMember.sua => 'suaAffinity',
      HomeCommunityMember.seoa => 'seoaAffinity',
      HomeCommunityMember.jian => 'jianAffinity',
      HomeCommunityMember.cohort => 'cohortTrust',
    };
    flags[affinityKey] =
        state.story.flagInt(affinityKey, 30) + improvement.affinityDelta;
    final nextStory = state.story.copyWith(
      householdStability:
          state.story.householdStability + improvement.facilityStabilityDelta,
      storyFlags: flags,
      seenStoryEventIds: storyEventIds,
    );
    final sourceId = 'home-improvement-${improvement.id}';
    final next = state.copyWith(
      cash: state.cash - improvement.cost,
      homeImprovements: nextHome,
      story: nextStory,
      progression: state.progression
          .record('finance_purchases')
          .record('home_improvements'),
      ledger: <LedgerEntry>[
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -improvement.cost,
          account: 'company_bank',
          counterAccount: 'academy_facility',
          description: improvement.title,
          sourceId: sourceId,
        ),
      ],
      processedEventIds: state.processedEventIds.contains(sourceId)
          ? state.processedEventIds
          : <String>[...state.processedEventIds, sourceId],
    );
    return FinanceActionResult(
      state: next,
      success: true,
      message: '${improvement.title} 완료 · 회사 통장 ${next.bankCash}원',
      cashDelta: -improvement.cost,
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
    if (option.isRealEstate && !realEstateTransactionsUnlocked(state)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '6월 빈 점포 계약 이야기를 마친 뒤 실제 부동산을 매입할 수 있습니다.',
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
      'cohortTrust':
          state.story.flagInt('cohortTrust', 30) + option.communityTrustDelta,
    };
    final nextStory = state.story.copyWith(storyFlags: flags);
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
    if (state.businesses.usesRealEstate(asset.id)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '직영점이 영업 중입니다. 점포를 이전하거나 폐업한 뒤 매각할 수 있습니다.',
      );
    }
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
    if (!realEstateOperationsUnlocked(state)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '7월 박하은의 부동산 운영 이야기를 마친 뒤 사용할 수 있습니다.',
      );
    }
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
    if (state.businesses.usesRealEstate(asset.id)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '직영점 영업 중에는 건물 리모델링을 진행할 수 없습니다.',
      );
    }
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
    if (!realEstateOperationsUnlocked(state)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '7월 박하은의 부동산 운영 이야기를 마친 뒤 사용할 수 있습니다.',
      );
    }
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
    if (!realEstateOperationsUnlocked(state)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '7월 박하은의 부동산 운영 이야기를 마친 뒤 사용할 수 있습니다.',
      );
    }
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
    if (state.businesses.usesRealEstate(asset.id)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '직영점이 사용하는 상가입니다. 점포를 이전하거나 폐업한 뒤 임대할 수 있습니다.',
      );
    }
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
        asset.optionId == 'alumni_housing_trust') {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '직접 사용하는 사무실·수료생 공동주거는 임대할 수 없습니다.',
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
    if (!realEstateOperationsUnlocked(state)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '7월 박하은의 부동산 운영 이야기를 마친 뒤 사용할 수 있습니다.',
      );
    }
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
    if (!realEstateOperationsUnlocked(state)) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '7월 박하은의 부동산 운영 이야기를 마친 뒤 사용할 수 있습니다.',
      );
    }
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

  CasinoActionResult exchangeCasinoChips(GameState state, int amount) {
    final profile = _casinoProfileForCurrentMonth(state);
    final age = state.story.ageOn(state.currentDate);
    if (state.currentDate.isBefore(DateTime(2010, 1, 1)) || age < 20) {
      return CasinoActionResult(
        state: state,
        success: false,
        message: '카지노는 2010년부터 성인만 이용할 수 있습니다.',
      );
    }
    if (profile.activeBlackjack != null || profile.activeCraps != null) {
      return CasinoActionResult(
        state: state,
        success: false,
        message: '진행 중인 테이블을 먼저 정산한 뒤 칩을 교환하세요.',
      );
    }
    if (amount < casinoMinimumStake ||
        amount > state.bankCash ||
        amount % casinoMinimumStake != 0) {
      return CasinoActionResult(
        state: state,
        success: false,
        message: '칩은 1만원 단위로 은행 현금 잔액 안에서 교환할 수 있습니다.',
      );
    }
    final exchangeId =
        'casino-chip-exchange-${state.day}-${profile.roundSequence}-${state.ledger.length}';
    final nextProfile = profile.copyWith(
      chipBalance: profile.chipBalance + amount,
    );
    final next = state.copyWith(
      cash: state.cash - amount,
      personalFinance: state.personalFinance.copyWith(casino: nextProfile),
      ledger: <LedgerEntry>[
        ...state.ledger,
        LedgerEntry(
          id: exchangeId,
          day: state.day,
          amount: -amount,
          account: 'company_bank',
          counterAccount: 'casino_chips',
          description: '카지노 현금 → 테이블 칩 교환',
          sourceId: exchangeId,
        ),
      ],
      processedEventIds: <String>[...state.processedEventIds, exchangeId],
    );
    return CasinoActionResult(
      state: next,
      success: true,
      message: '$amount원어치 칩을 받았습니다.',
      cashDelta: -amount,
    );
  }

  CasinoActionResult cashOutCasinoChips(GameState state) {
    final profile = state.personalFinance.casino;
    if (profile.activeBlackjack != null || profile.activeCraps != null) {
      return CasinoActionResult(
        state: state,
        success: false,
        message: '진행 중인 테이블을 먼저 정산해야 칩을 환전할 수 있습니다.',
      );
    }
    final amount = profile.chipBalance;
    if (amount <= 0) {
      return CasinoActionResult(
        state: state,
        success: true,
        message: '환전할 칩이 없습니다.',
      );
    }
    final cashOutId =
        'casino-chip-cashout-${state.day}-${profile.roundSequence}-${state.ledger.length}';
    final next = state.copyWith(
      cash: state.cash + amount,
      personalFinance: state.personalFinance.copyWith(
        casino: profile.copyWith(chipBalance: 0),
      ),
      ledger: <LedgerEntry>[
        ...state.ledger,
        LedgerEntry(
          id: cashOutId,
          day: state.day,
          amount: amount,
          account: 'company_bank',
          counterAccount: 'casino_chips',
          description: '카지노 테이블 칩 → 현금 환전',
          sourceId: cashOutId,
        ),
      ],
      processedEventIds: <String>[...state.processedEventIds, cashOutId],
    );
    return CasinoActionResult(
      state: next,
      success: true,
      message: '남은 칩 $amount원을 현금으로 환전했습니다.',
      cashDelta: amount,
    );
  }

  CasinoActionResult playCasinoRound(GameState state, CasinoBet bet) {
    if (bet.game == CasinoGameType.blackjack) {
      return CasinoActionResult(
        state: state,
        success: false,
        message: '블랙잭은 카드를 받은 뒤 히트·스탠드·더블을 직접 선택합니다.',
      );
    }
    if (bet.game == CasinoGameType.craps) {
      return startCasinoCraps(state, bet);
    }
    final profile = _casinoProfileForCurrentMonth(state);
    final problem = _casinoPlayProblem(state, profile, bet.stake);
    if (problem != null) {
      return CasinoActionResult(state: state, success: false, message: problem);
    }
    if (!_casinoBetIsValid(bet)) {
      return CasinoActionResult(
        state: state,
        success: false,
        message: '이 테이블에서 받을 수 없는 베팅입니다.',
      );
    }

    final roundId =
        'casino-${state.day}-${profile.roundSequence}-${bet.game.name}';
    final outcomeKey =
        '${state.simulationSeed}:casino:${state.day}:${profile.roundSequence}:${bet.game.name}';
    final result = switch (bet.game) {
      CasinoGameType.baccarat => _resolveBaccaratBet(bet, outcomeKey),
      CasinoGameType.roulette => _resolveRouletteBet(bet, outcomeKey),
      CasinoGameType.sicBo => _resolveSicBoBet(bet, outcomeKey),
      CasinoGameType.slots => _resolveSlotsBet(bet, outcomeKey),
      CasinoGameType.craps => throw StateError('handled above'),
      CasinoGameType.blackjack => throw StateError('handled above'),
    };
    return _recordCasinoRound(
      state: state,
      profile: profile,
      roundId: roundId,
      game: bet.game,
      betLabel: casinoBetTitle(bet.type, selection: bet.selection),
      stake: bet.stake,
      payout: result.payout,
      outcome: result.outcome,
      detail: result.detail,
    );
  }

  CasinoActionResult startCasinoBlackjack(GameState state, int stake) {
    final profile = _casinoProfileForCurrentMonth(state);
    final problem = _casinoPlayProblem(state, profile, stake);
    if (problem != null) {
      return CasinoActionResult(state: state, success: false, message: problem);
    }
    final roundId = 'casino-${state.day}-${profile.roundSequence}-blackjack';
    final deck = casinoShuffledDeck(
      '${state.simulationSeed}:casino:${state.day}:${profile.roundSequence}:blackjack',
    );
    final hand = BlackjackHandState(
      id: roundId,
      day: state.day,
      minute: state.marketMinute,
      stake: stake,
      deck: deck,
      playerCards: <int>[deck[0], deck[2]],
      dealerCards: <int>[deck[1], deck[3]],
      nextCardIndex: 4,
      doubled: false,
    );
    final roundsToday = profile.lastPlayDay == state.day
        ? profile.roundsToday + 1
        : 1;
    final nextProfile = profile.copyWith(
      chipBalance: profile.chipBalance - stake,
      monthlyStake: profile.monthlyStake + stake,
      lastPlayDay: state.day,
      roundsToday: roundsToday,
      roundSequence: profile.roundSequence + 1,
      totalRounds: profile.totalRounds + 1,
      totalStake: profile.totalStake + stake,
      activeBlackjack: hand,
    );
    final nextFinance = state.personalFinance.copyWith(
      totalSpent: state.personalFinance.totalSpent + stake,
      chancePlayCount: state.personalFinance.chancePlayCount + 1,
      totalChanceStake: state.personalFinance.totalChanceStake + stake,
      casino: nextProfile,
    );
    final next = state.copyWith(
      personalFinance: nextFinance,
      ledger: <LedgerEntry>[
        ...state.ledger,
        LedgerEntry(
          id: '$roundId-stake',
          day: state.day,
          amount: -stake,
          account: 'casino_chips',
          counterAccount: 'casino_wager',
          description: '카지노 · 블랙잭 기본 핸드',
          sourceId: roundId,
        ),
      ],
      processedEventIds: <String>[...state.processedEventIds, roundId],
    );
    final playerValue = blackjackHandValue(hand.playerCards).total;
    return CasinoActionResult(
      state: next,
      success: true,
      message: playerValue == 21
          ? '블랙잭입니다. 결과 확인을 눌러 딜러 패와 정산을 확인하세요.'
          : '카드를 받았습니다. 히트·스탠드·더블 중 하나를 선택하세요.',
      cashDelta: -stake,
    );
  }

  CasinoActionResult actCasinoBlackjack(
    GameState state,
    BlackjackAction action,
  ) {
    final hand = state.personalFinance.casino.activeBlackjack;
    if (hand == null) {
      return CasinoActionResult(
        state: state,
        success: false,
        message: '진행 중인 블랙잭 핸드가 없습니다.',
      );
    }
    final playerValue = blackjackHandValue(hand.playerCards).total;
    if (playerValue >= 21 && action == BlackjackAction.hit) {
      return CasinoActionResult(
        state: state,
        success: false,
        message: '21 이상에서는 카드를 더 받을 수 없습니다. 결과를 확인하세요.',
      );
    }

    if (action == BlackjackAction.hit) {
      if (hand.nextCardIndex >= hand.deck.length) {
        return CasinoActionResult(
          state: state,
          success: false,
          message: '슈를 다시 준비해야 합니다. 스탠드로 정산해 주세요.',
        );
      }
      final playerCards = <int>[
        ...hand.playerCards,
        hand.deck[hand.nextCardIndex],
      ];
      final updated = hand.copyWith(
        playerCards: playerCards,
        nextCardIndex: hand.nextCardIndex + 1,
      );
      if (blackjackHandValue(playerCards).total >= 21) {
        return _settleCasinoBlackjack(state, updated);
      }
      final next = state.copyWith(
        personalFinance: state.personalFinance.copyWith(
          casino: state.personalFinance.casino.copyWith(
            activeBlackjack: updated,
          ),
        ),
      );
      return CasinoActionResult(
        state: next,
        success: true,
        message: '${casinoCardLabel(playerCards.last)} 카드를 받았습니다.',
      );
    }

    if (action == BlackjackAction.doubleDown) {
      if (hand.playerCards.length != 2 || hand.doubled) {
        return CasinoActionResult(
          state: state,
          success: false,
          message: '더블은 처음 두 장에서만 한 번 선택할 수 있습니다.',
        );
      }
      final profile = _casinoProfileForCurrentMonth(state);
      if (hand.stake > profile.chipBalance) {
        return CasinoActionResult(
          state: state,
          success: false,
          message: '더블에 필요한 추가 베팅 현금이 부족합니다.',
        );
      }
      final lossLimit = casinoMonthlyLossLimitForBasis(
        profile.monthBankrollBasis,
      );
      if (profile.monthlyLoss + hand.stake > lossLimit) {
        return CasinoActionResult(
          state: state,
          success: false,
          message: '이번 달 손실 중단선 때문에 더블을 선택할 수 없습니다.',
        );
      }
      final playerCards = <int>[
        ...hand.playerCards,
        hand.deck[hand.nextCardIndex],
      ];
      final doubled = hand.copyWith(
        stake: hand.stake * 2,
        playerCards: playerCards,
        nextCardIndex: hand.nextCardIndex + 1,
        doubled: true,
      );
      final profileWithDouble = profile.copyWith(
        chipBalance: profile.chipBalance - hand.stake,
        monthlyStake: profile.monthlyStake + hand.stake,
        totalStake: profile.totalStake + hand.stake,
        activeBlackjack: doubled,
      );
      final charged = state.copyWith(
        personalFinance: state.personalFinance.copyWith(
          totalSpent: state.personalFinance.totalSpent + hand.stake,
          totalChanceStake: state.personalFinance.totalChanceStake + hand.stake,
          casino: profileWithDouble,
        ),
        ledger: <LedgerEntry>[
          ...state.ledger,
          LedgerEntry(
            id: '${hand.id}-double',
            day: state.day,
            amount: -hand.stake,
            account: 'casino_chips',
            counterAccount: 'casino_wager',
            description: '카지노 · 블랙잭 더블다운 추가 베팅',
            sourceId: hand.id,
          ),
        ],
      );
      final settled = _settleCasinoBlackjack(charged, doubled);
      return CasinoActionResult(
        state: settled.state,
        success: settled.success,
        message: settled.message,
        cashDelta: settled.cashDelta - hand.stake,
        minutesElapsed: settled.minutesElapsed,
      );
    }

    return _settleCasinoBlackjack(state, hand);
  }

  CasinoActionResult _settleCasinoBlackjack(
    GameState state,
    BlackjackHandState hand,
  ) {
    final player = blackjackHandValue(hand.playerCards);
    var dealerCards = <int>[...hand.dealerCards];
    var nextIndex = hand.nextCardIndex;
    if (player.total <= 21) {
      while (true) {
        final dealer = blackjackHandValue(dealerCards);
        // This table uses the common S17 rule: the dealer stands on every 17,
        // including soft 17.
        if (dealer.total >= 17) break;
        if (nextIndex >= hand.deck.length) break;
        dealerCards.add(hand.deck[nextIndex]);
        nextIndex++;
      }
    }
    final dealer = blackjackHandValue(dealerCards);
    final playerNatural = blackjackIsNatural(hand.playerCards);
    final dealerNatural = blackjackIsNatural(dealerCards);
    late final int grossPayout;
    late final String outcome;
    if (player.total > 21) {
      grossPayout = 0;
      outcome = '버스트';
    } else if (playerNatural && !dealerNatural) {
      grossPayout = hand.stake + (hand.stake * 3 ~/ 2);
      outcome = '블랙잭 3:2';
    } else if (dealerNatural && !playerNatural) {
      grossPayout = 0;
      outcome = '딜러 블랙잭';
    } else if (player.total == dealer.total) {
      grossPayout = hand.stake;
      outcome = '푸시';
    } else if (dealer.total > 21 || player.total > dealer.total) {
      grossPayout = hand.stake * 2;
      outcome = '승리';
    } else {
      grossPayout = 0;
      outcome = '패배';
    }
    final detail =
        '플레이어 ${hand.playerCards.map(casinoCardLabel).join(' ')} (${player.total}) · '
        '딜러 ${dealerCards.map(casinoCardLabel).join(' ')} (${dealer.total})';
    final nationalFee = casinoNationalFee(
      grossPayout: grossPayout,
      stake: hand.stake,
    );
    final netPayout = grossPayout - nationalFee;
    final record = CasinoRoundRecord(
      id: hand.id,
      day: hand.day,
      minute: hand.minute,
      game: CasinoGameType.blackjack,
      betLabel: hand.doubled ? '더블다운' : '기본 핸드',
      stake: hand.stake,
      payout: netPayout,
      grossPayout: grossPayout,
      nationalFee: nationalFee,
      outcome: outcome,
      detail: detail,
    );
    final profile = state.personalFinance.casino;
    final history = _appendCasinoHistory(profile.history, record);
    final nextProfile = profile.copyWith(
      chipBalance: profile.chipBalance + netPayout,
      monthlyPayout: profile.monthlyPayout + netPayout,
      monthlyNationalFee: profile.monthlyNationalFee + nationalFee,
      totalPayout: profile.totalPayout + netPayout,
      totalNationalFee: profile.totalNationalFee + nationalFee,
      history: history,
      activeBlackjack: null,
    );
    final next = state.copyWith(
      personalFinance: state.personalFinance.copyWith(
        totalChancePayout: state.personalFinance.totalChancePayout + netPayout,
        casino: nextProfile,
      ),
      ledger: <LedgerEntry>[
        ...state.ledger,
        if (grossPayout > 0)
          LedgerEntry(
            id: '${hand.id}-payout',
            day: state.day,
            amount: grossPayout,
            account: 'casino_chips',
            counterAccount: 'casino_payout',
            description: '카지노 · 블랙잭 $outcome 총지급',
            sourceId: hand.id,
          ),
        if (nationalFee > 0)
          LedgerEntry(
            id: '${hand.id}-national-fee',
            day: state.day,
            amount: -nationalFee,
            account: 'casino_chips',
            counterAccount: 'state_casino_fee',
            description: '카지노 확정 이익 국가 수수료 20%',
            sourceId: hand.id,
          ),
      ],
    );
    return CasinoActionResult(
      state: next,
      success: true,
      message:
          '$outcome · $detail · ${_casinoSettlementText(grossPayout, nationalFee)}',
      cashDelta: netPayout,
      minutesElapsed: casinoRoundMinutes,
    );
  }

  CasinoActionResult startCasinoCraps(GameState state, CasinoBet bet) {
    if (bet.game != CasinoGameType.craps ||
        (bet.type != CasinoBetType.crapsPassLine &&
            bet.type != CasinoBetType.crapsDontPass)) {
      return CasinoActionResult(
        state: state,
        success: false,
        message: '크랩스는 패스 라인과 돈트 패스 베팅만 받습니다.',
      );
    }
    final profile = _casinoProfileForCurrentMonth(state);
    final problem = _casinoPlayProblem(state, profile, bet.stake);
    if (problem != null) {
      return CasinoActionResult(state: state, success: false, message: problem);
    }

    final roundId = 'casino-${state.day}-${profile.roundSequence}-craps';
    final firstRoll = _casinoCrapsRoll(state, roundId, 0);
    final sum = firstRoll[0] + firstRoll[1];
    final point = <int>{4, 5, 6, 8, 9, 10}.contains(sum) ? sum : 0;
    final round = CrapsRoundState(
      id: roundId,
      day: state.day,
      minute: state.marketMinute,
      stake: bet.stake,
      betType: bet.type,
      point: point,
      rolls: <List<int>>[firstRoll],
      nextRollIndex: 1,
    );
    final roundsToday = profile.lastPlayDay == state.day
        ? profile.roundsToday + 1
        : 1;
    final chargedProfile = profile.copyWith(
      chipBalance: profile.chipBalance - bet.stake,
      monthlyStake: profile.monthlyStake + bet.stake,
      lastPlayDay: state.day,
      roundsToday: roundsToday,
      roundSequence: profile.roundSequence + 1,
      totalRounds: profile.totalRounds + 1,
      totalStake: profile.totalStake + bet.stake,
      activeCraps: round,
    );
    final charged = state.copyWith(
      personalFinance: state.personalFinance.copyWith(
        totalSpent: state.personalFinance.totalSpent + bet.stake,
        chancePlayCount: state.personalFinance.chancePlayCount + 1,
        totalChanceStake: state.personalFinance.totalChanceStake + bet.stake,
        casino: chargedProfile,
      ),
      ledger: <LedgerEntry>[
        ...state.ledger,
        LedgerEntry(
          id: '$roundId-stake',
          day: state.day,
          amount: -bet.stake,
          account: 'casino_chips',
          counterAccount: 'casino_wager',
          description: '카지노 · 크랩스 ${casinoBetTitle(bet.type)}',
          sourceId: roundId,
        ),
      ],
      processedEventIds: <String>[...state.processedEventIds, roundId],
    );

    final pass = bet.type == CasinoBetType.crapsPassLine;
    if ((pass && (sum == 7 || sum == 11)) ||
        (!pass && (sum == 2 || sum == 3))) {
      final settled = _settleCasinoCraps(
        charged,
        round,
        grossPayout: bet.stake * 2,
        outcome: '컴아웃 승리',
      );
      return CasinoActionResult(
        state: settled.state,
        success: true,
        message: settled.message,
        cashDelta: settled.cashDelta - bet.stake,
        minutesElapsed: settled.minutesElapsed,
      );
    }
    if (!pass && sum == 12) {
      final settled = _settleCasinoCraps(
        charged,
        round,
        grossPayout: bet.stake,
        outcome: '컴아웃 12 · 푸시',
      );
      return CasinoActionResult(
        state: settled.state,
        success: true,
        message: settled.message,
        cashDelta: settled.cashDelta - bet.stake,
        minutesElapsed: settled.minutesElapsed,
      );
    }
    if ((pass && (sum == 2 || sum == 3 || sum == 12)) ||
        (!pass && (sum == 7 || sum == 11))) {
      final settled = _settleCasinoCraps(
        charged,
        round,
        grossPayout: 0,
        outcome: '컴아웃 패배',
      );
      return CasinoActionResult(
        state: settled.state,
        success: true,
        message: settled.message,
        cashDelta: -bet.stake,
        minutesElapsed: settled.minutesElapsed,
      );
    }

    return CasinoActionResult(
      state: charged,
      success: true,
      message:
          '컴아웃 ${firstRoll[0]}+${firstRoll[1]}=$sum · 포인트 $point가 설정됐습니다. 주사위를 다시 굴리세요.',
      cashDelta: -bet.stake,
    );
  }

  CasinoActionResult rollCasinoCraps(GameState state) {
    final round = state.personalFinance.casino.activeCraps;
    if (round == null) {
      return CasinoActionResult(
        state: state,
        success: false,
        message: '진행 중인 크랩스 포인트가 없습니다.',
      );
    }
    if (round.day != state.day) {
      return CasinoActionResult(
        state: state,
        success: false,
        message: '이전 날의 크랩스 라운드는 더 진행할 수 없습니다.',
      );
    }
    final roll = _casinoCrapsRoll(state, round.id, round.nextRollIndex);
    final sum = roll[0] + roll[1];
    final updated = round.copyWith(
      rolls: <List<int>>[...round.rolls, roll],
      nextRollIndex: round.nextRollIndex + 1,
    );
    final pass = round.betType == CasinoBetType.crapsPassLine;
    if (sum == round.point) {
      return _settleCasinoCraps(
        state,
        updated,
        grossPayout: pass ? round.stake * 2 : 0,
        outcome: pass ? '포인트 메이크 · 승리' : '포인트 메이크 · 패배',
      );
    }
    if (sum == 7) {
      return _settleCasinoCraps(
        state,
        updated,
        grossPayout: pass ? 0 : round.stake * 2,
        outcome: pass ? '세븐 아웃 · 패배' : '세븐 아웃 · 승리',
      );
    }
    final next = state.copyWith(
      personalFinance: state.personalFinance.copyWith(
        casino: state.personalFinance.casino.copyWith(activeCraps: updated),
      ),
    );
    return CasinoActionResult(
      state: next,
      success: true,
      message: '${roll[0]}+${roll[1]}=$sum · 포인트 ${round.point} 유지. 다시 굴리세요.',
    );
  }

  List<int> _casinoCrapsRoll(GameState state, String roundId, int rollIndex) =>
      <int>[
        stableRandomInt(
              '${state.simulationSeed}:$roundId:craps-v2:roll:$rollIndex:die:0',
              6,
            ) +
            1,
        stableRandomInt(
              '${state.simulationSeed}:$roundId:craps-v2:roll:$rollIndex:die:1',
              6,
            ) +
            1,
      ];

  CasinoActionResult _settleCasinoCraps(
    GameState state,
    CrapsRoundState round, {
    required int grossPayout,
    required String outcome,
  }) {
    final nationalFee = casinoNationalFee(
      grossPayout: grossPayout,
      stake: round.stake,
    );
    final netPayout = grossPayout - nationalFee;
    final rolls = round.rolls
        .map((roll) => '${roll[0]}+${roll[1]}=${roll[0] + roll[1]}')
        .join(' → ');
    final detail = round.point == 0
        ? '컴아웃 $rolls'
        : '포인트 ${round.point} · $rolls';
    final record = CasinoRoundRecord(
      id: round.id,
      day: round.day,
      minute: round.minute,
      game: CasinoGameType.craps,
      betLabel: casinoBetTitle(round.betType),
      stake: round.stake,
      payout: netPayout,
      grossPayout: grossPayout,
      nationalFee: nationalFee,
      outcome: outcome,
      detail: detail,
    );
    final profile = state.personalFinance.casino;
    final nextProfile = profile.copyWith(
      chipBalance: profile.chipBalance + netPayout,
      monthlyPayout: profile.monthlyPayout + netPayout,
      monthlyNationalFee: profile.monthlyNationalFee + nationalFee,
      totalPayout: profile.totalPayout + netPayout,
      totalNationalFee: profile.totalNationalFee + nationalFee,
      history: _appendCasinoHistory(profile.history, record),
      activeCraps: null,
    );
    final next = state.copyWith(
      personalFinance: state.personalFinance.copyWith(
        totalChancePayout: state.personalFinance.totalChancePayout + netPayout,
        casino: nextProfile,
      ),
      ledger: <LedgerEntry>[
        ...state.ledger,
        if (grossPayout > 0)
          LedgerEntry(
            id: '${round.id}-payout',
            day: state.day,
            amount: grossPayout,
            account: 'casino_chips',
            counterAccount: 'casino_payout',
            description: '카지노 · 크랩스 $outcome 총지급',
            sourceId: round.id,
          ),
        if (nationalFee > 0)
          LedgerEntry(
            id: '${round.id}-national-fee',
            day: state.day,
            amount: -nationalFee,
            account: 'casino_chips',
            counterAccount: 'state_casino_fee',
            description: '카지노 확정 이익 국가 수수료 20%',
            sourceId: round.id,
          ),
      ],
    );
    return CasinoActionResult(
      state: next,
      success: true,
      message:
          '$outcome · $detail · ${_casinoSettlementText(grossPayout, nationalFee)}',
      cashDelta: netPayout,
      minutesElapsed: casinoRoundMinutes,
    );
  }

  CasinoState _casinoProfileForCurrentMonth(GameState state) =>
      state.personalFinance.casino.forMonth(
        casinoMonthKey(state.currentDate),
        state.bankCash + state.personalFinance.casino.chipBalance,
      );

  String? _casinoPlayProblem(GameState state, CasinoState profile, int stake) {
    final age = state.story.ageOn(state.currentDate);
    if (state.currentDate.isBefore(DateTime(2010, 1, 1)) || age < 20) {
      return '성인이 되는 2010년부터 이용할 수 있습니다.';
    }
    if (state.currentDate.weekday >= DateTime.saturday) {
      return '카지노는 평일 장 마감 뒤 저녁 행동으로 이용할 수 있습니다.';
    }
    if (state.pendingDecisions.isNotEmpty) {
      return '새 기록의 결정을 먼저 마쳐야 카지노에 입장할 수 있습니다.';
    }
    if (weekdayEveningUsed(state)) {
      return '오늘의 저녁 행동은 이미 사용했습니다.';
    }
    if (state.marketMinute < krxCloseMinute) {
      return '카지노는 15:00 장 마감 뒤에 입장할 수 있습니다.';
    }
    if (state.marketMinute > marketDayEndMinute - casinoRoundMinutes) {
      return '마지막 게임 시작은 19:30입니다. 오늘은 장부만 확인할 수 있습니다.';
    }
    if (profile.activeBlackjack != null) {
      return '진행 중인 블랙잭 핸드를 먼저 마쳐야 합니다.';
    }
    if (profile.activeCraps != null) {
      return '진행 중인 크랩스 포인트를 먼저 정산해야 합니다.';
    }
    if (profile.roundsForDay(state.day) >= casinoDailyRoundLimit) {
      return '오늘의 테이블 이용 한도 $casinoDailyRoundLimit판을 모두 사용했습니다.';
    }
    final bankroll = state.bankCash + profile.chipBalance;
    final maxStake = casinoMaximumStakeForCash(bankroll);
    if (stake < casinoMinimumStake ||
        stake > maxStake ||
        stake > profile.chipBalance ||
        stake % casinoMinimumStake != 0) {
      return '베팅은 1만원 단위이며, 현금의 1%와 10만원 중 작은 금액 이하여야 합니다.';
    }
    final lossLimit = casinoMonthlyLossLimitForBasis(
      profile.monthBankrollBasis,
    );
    if (profile.monthlyLoss + stake > lossLimit) {
      return '이번 달 손실 중단선 $lossLimit원에 도달해 추가 베팅이 잠겼습니다.';
    }
    return null;
  }

  bool _casinoBetIsValid(CasinoBet bet) {
    final validType = switch (bet.game) {
      CasinoGameType.baccarat => <CasinoBetType>{
        CasinoBetType.baccaratPlayer,
        CasinoBetType.baccaratBanker,
        CasinoBetType.baccaratTie,
        CasinoBetType.baccaratPlayerPair,
        CasinoBetType.baccaratBankerPair,
      }.contains(bet.type),
      CasinoGameType.roulette => bet.type.name.startsWith('roulette'),
      CasinoGameType.craps =>
        bet.type == CasinoBetType.crapsPassLine ||
            bet.type == CasinoBetType.crapsDontPass,
      CasinoGameType.sicBo => bet.type.name.startsWith('sicBo'),
      CasinoGameType.slots => bet.type == CasinoBetType.slotsSpin,
      CasinoGameType.blackjack => bet.type == CasinoBetType.blackjackHand,
    };
    if (!validType) return false;
    if (bet.type == CasinoBetType.rouletteStraight) {
      return bet.selection != null &&
          bet.selection! >= 0 &&
          bet.selection! <= 36;
    }
    if (bet.type == CasinoBetType.sicBoSpecificTriple) {
      return bet.selection != null &&
          bet.selection! >= 1 &&
          bet.selection! <= 6;
    }
    if (bet.type == CasinoBetType.sicBoTotal) {
      return bet.selection != null &&
          bet.selection! >= 4 &&
          bet.selection! <= 17;
    }
    return true;
  }

  CasinoActionResult _recordCasinoRound({
    required GameState state,
    required CasinoState profile,
    required String roundId,
    required CasinoGameType game,
    required String betLabel,
    required int stake,
    required int payout,
    required String outcome,
    required String detail,
  }) {
    final grossPayout = payout;
    final nationalFee = casinoNationalFee(
      grossPayout: grossPayout,
      stake: stake,
    );
    final netPayout = grossPayout - nationalFee;
    final record = CasinoRoundRecord(
      id: roundId,
      day: state.day,
      minute: state.marketMinute,
      game: game,
      betLabel: betLabel,
      stake: stake,
      payout: netPayout,
      grossPayout: grossPayout,
      nationalFee: nationalFee,
      outcome: outcome,
      detail: detail,
    );
    final roundsToday = profile.lastPlayDay == state.day
        ? profile.roundsToday + 1
        : 1;
    final nextProfile = profile.copyWith(
      chipBalance: profile.chipBalance - stake + netPayout,
      monthlyStake: profile.monthlyStake + stake,
      monthlyPayout: profile.monthlyPayout + netPayout,
      monthlyNationalFee: profile.monthlyNationalFee + nationalFee,
      lastPlayDay: state.day,
      roundsToday: roundsToday,
      roundSequence: profile.roundSequence + 1,
      totalRounds: profile.totalRounds + 1,
      totalStake: profile.totalStake + stake,
      totalPayout: profile.totalPayout + netPayout,
      totalNationalFee: profile.totalNationalFee + nationalFee,
      history: _appendCasinoHistory(profile.history, record),
    );
    final nextFinance = state.personalFinance.copyWith(
      totalSpent: state.personalFinance.totalSpent + stake,
      chancePlayCount: state.personalFinance.chancePlayCount + 1,
      totalChanceStake: state.personalFinance.totalChanceStake + stake,
      totalChancePayout: state.personalFinance.totalChancePayout + netPayout,
      casino: nextProfile,
    );
    final next = state.copyWith(
      personalFinance: nextFinance,
      ledger: <LedgerEntry>[
        ...state.ledger,
        LedgerEntry(
          id: '$roundId-stake',
          day: state.day,
          amount: -stake,
          account: 'casino_chips',
          counterAccount: 'casino_wager',
          description: '카지노 · ${casinoGameTitle(game)} $betLabel',
          sourceId: roundId,
        ),
        if (grossPayout > 0)
          LedgerEntry(
            id: '$roundId-payout',
            day: state.day,
            amount: grossPayout,
            account: 'casino_chips',
            counterAccount: 'casino_payout',
            description: '카지노 · ${casinoGameTitle(game)} $outcome 총지급',
            sourceId: roundId,
          ),
        if (nationalFee > 0)
          LedgerEntry(
            id: '$roundId-national-fee',
            day: state.day,
            amount: -nationalFee,
            account: 'casino_chips',
            counterAccount: 'state_casino_fee',
            description: '카지노 확정 이익 국가 수수료 20%',
            sourceId: roundId,
          ),
      ],
      processedEventIds: <String>[...state.processedEventIds, roundId],
    );
    return CasinoActionResult(
      state: next,
      success: true,
      message:
          '$outcome · $detail · ${_casinoSettlementText(grossPayout, nationalFee)}',
      cashDelta: netPayout - stake,
      minutesElapsed: casinoRoundMinutes,
    );
  }

  List<CasinoRoundRecord> _appendCasinoHistory(
    List<CasinoRoundRecord> history,
    CasinoRoundRecord record,
  ) {
    final next = <CasinoRoundRecord>[...history, record];
    return next.length <= casinoHistoryLimit
        ? next
        : next.sublist(next.length - casinoHistoryLimit);
  }

  String _casinoSettlementText(int grossPayout, int nationalFee) =>
      '총지급 $grossPayout원 · 국가 수수료 $nationalFee원 · '
      '실수령 ${grossPayout - nationalFee}원';

  ({int payout, String outcome, String detail}) _resolveBaccaratBet(
    CasinoBet bet,
    String key,
  ) {
    final deck = casinoShuffledDeck('$key:baccarat');
    final player = <int>[deck[0], deck[2]];
    final banker = <int>[deck[1], deck[3]];
    var nextIndex = 4;
    int value(Iterable<int> cards) => cards.fold<int>(
      0,
      (sum, card) =>
          (sum + (casinoCardRank(card) >= 10 ? 0 : casinoCardRank(card))) % 10,
    );
    var playerTotal = value(player);
    var bankerTotal = value(banker);
    int? playerThirdValue;
    if (playerTotal < 8 && bankerTotal < 8) {
      if (playerTotal <= 5) {
        final card = deck[nextIndex++];
        player.add(card);
        playerThirdValue = casinoCardRank(card) >= 10
            ? 0
            : casinoCardRank(card);
        playerTotal = value(player);
      }
      final bankerDraws = playerThirdValue == null
          ? bankerTotal <= 5
          : bankerTotal <= 2 ||
                (bankerTotal == 3 && playerThirdValue != 8) ||
                (bankerTotal == 4 &&
                    playerThirdValue >= 2 &&
                    playerThirdValue <= 7) ||
                (bankerTotal == 5 &&
                    playerThirdValue >= 4 &&
                    playerThirdValue <= 7) ||
                (bankerTotal == 6 &&
                    playerThirdValue >= 6 &&
                    playerThirdValue <= 7);
      if (bankerDraws) {
        banker.add(deck[nextIndex]);
        bankerTotal = value(banker);
      }
    }
    final playerPair = casinoCardRank(player[0]) == casinoCardRank(player[1]);
    final bankerPair = casinoCardRank(banker[0]) == casinoCardRank(banker[1]);
    final winner = playerTotal == bankerTotal
        ? '타이'
        : playerTotal > bankerTotal
        ? '플레이어'
        : '뱅커';
    final won = switch (bet.type) {
      CasinoBetType.baccaratPlayer => winner == '플레이어',
      CasinoBetType.baccaratBanker => winner == '뱅커',
      CasinoBetType.baccaratTie => winner == '타이',
      CasinoBetType.baccaratPlayerPair => playerPair,
      CasinoBetType.baccaratBankerPair => bankerPair,
      _ => false,
    };
    final payout = !won
        ? 0
        : switch (bet.type) {
            CasinoBetType.baccaratPlayer => bet.stake * 2,
            CasinoBetType.baccaratBanker => bet.stake + bet.stake * 95 ~/ 100,
            CasinoBetType.baccaratTie => bet.stake * 9,
            CasinoBetType.baccaratPlayerPair ||
            CasinoBetType.baccaratBankerPair => bet.stake * 12,
            _ => 0,
          };
    return (
      payout: payout,
      outcome: won ? '$winner 적중' : '$winner · 미적중',
      detail:
          'P ${player.map(casinoCardLabel).join(' ')} ($playerTotal) · B ${banker.map(casinoCardLabel).join(' ')} ($bankerTotal)',
    );
  }

  ({int payout, String outcome, String detail}) _resolveRouletteBet(
    CasinoBet bet,
    String key,
  ) {
    const redNumbers = <int>{
      1,
      3,
      5,
      7,
      9,
      12,
      14,
      16,
      18,
      19,
      21,
      23,
      25,
      27,
      30,
      32,
      34,
      36,
    };
    final number = stableRandomInt('$key:roulette-v2:wheel', 37);
    final isRed = redNumbers.contains(number);
    final won = switch (bet.type) {
      CasinoBetType.rouletteRed => number != 0 && isRed,
      CasinoBetType.rouletteBlack => number != 0 && !isRed,
      CasinoBetType.rouletteOdd => number != 0 && number.isOdd,
      CasinoBetType.rouletteEven => number != 0 && number.isEven,
      CasinoBetType.rouletteLow => number >= 1 && number <= 18,
      CasinoBetType.rouletteHigh => number >= 19 && number <= 36,
      CasinoBetType.rouletteDozen1 => number >= 1 && number <= 12,
      CasinoBetType.rouletteDozen2 => number >= 13 && number <= 24,
      CasinoBetType.rouletteDozen3 => number >= 25 && number <= 36,
      CasinoBetType.rouletteColumn1 => number != 0 && (number - 1) % 3 == 0,
      CasinoBetType.rouletteColumn2 => number != 0 && (number - 2) % 3 == 0,
      CasinoBetType.rouletteColumn3 => number != 0 && number % 3 == 0,
      CasinoBetType.rouletteStraight => number == bet.selection,
      _ => false,
    };
    final multiplier = switch (bet.type) {
      CasinoBetType.rouletteStraight => 36,
      CasinoBetType.rouletteDozen1 ||
      CasinoBetType.rouletteDozen2 ||
      CasinoBetType.rouletteDozen3 ||
      CasinoBetType.rouletteColumn1 ||
      CasinoBetType.rouletteColumn2 ||
      CasinoBetType.rouletteColumn3 => 3,
      _ => 2,
    };
    final color = number == 0
        ? '그린'
        : isRed
        ? '레드'
        : '블랙';
    return (
      payout: won ? bet.stake * multiplier : 0,
      outcome: won ? '$number $color 적중' : '$number $color · 미적중',
      detail: '유럽식 싱글 제로 · 당첨 번호 $number',
    );
  }

  ({int payout, String outcome, String detail}) _resolveSicBoBet(
    CasinoBet bet,
    String key,
  ) {
    final dice = <int>[
      stableRandomInt('$key:sicbo-v2:die:0', 6) + 1,
      stableRandomInt('$key:sicbo-v2:die:1', 6) + 1,
      stableRandomInt('$key:sicbo-v2:die:2', 6) + 1,
    ];
    final total = dice.fold<int>(0, (sum, value) => sum + value);
    final triple = dice[0] == dice[1] && dice[1] == dice[2];
    final won = switch (bet.type) {
      CasinoBetType.sicBoBig => !triple && total >= 11 && total <= 17,
      CasinoBetType.sicBoSmall => !triple && total >= 4 && total <= 10,
      CasinoBetType.sicBoOdd => !triple && total.isOdd,
      CasinoBetType.sicBoEven => !triple && total.isEven,
      CasinoBetType.sicBoAnyTriple => triple,
      CasinoBetType.sicBoSpecificTriple => triple && dice[0] == bet.selection,
      CasinoBetType.sicBoTotal => total == bet.selection,
      _ => false,
    };
    final multiplier = switch (bet.type) {
      CasinoBetType.sicBoAnyTriple => 26,
      CasinoBetType.sicBoSpecificTriple => 151,
      CasinoBetType.sicBoTotal => switch (bet.selection) {
        4 || 17 => 51,
        5 || 16 => 19,
        6 || 15 => 15,
        7 || 14 => 13,
        8 || 13 => 9,
        9 || 12 => 7,
        10 || 11 => 7,
        _ => 0,
      },
      _ => 2,
    };
    return (
      payout: won ? bet.stake * multiplier : 0,
      outcome: won ? '적중' : '미적중',
      detail: '주사위 ${dice.join(' · ')} · 합계 $total${triple ? ' · 트리플' : ''}',
    );
  }

  ({int payout, String outcome, String detail}) _resolveSlotsBet(
    CasinoBet bet,
    String key,
  ) {
    final reels = <int>[
      stableRandomInt('$key:slots-v2:reel:0', casinoSlotSymbols.length),
      stableRandomInt('$key:slots-v2:reel:1', casinoSlotSymbols.length),
      stableRandomInt('$key:slots-v2:reel:2', casinoSlotSymbols.length),
    ];
    final multiplier = casinoSlotPayoutMultiplier(reels);
    final detail = reels.map((value) => casinoSlotSymbols[value]).join('  |  ');
    return (
      payout: bet.stake * multiplier,
      outcome: multiplier > 0 ? '$multiplier배 당첨' : '미당첨',
      detail: '$detail · 공개 이론 지급률 97.2%',
    );
  }

  // 구형 저장과 기록 호환을 위한 이전 월 1회 확률 오락 API. 신규 UI는 위의
  // 테이블별 카지노 API만 사용한다.
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
    if (archive.length > 370) archive.removeRange(0, archive.length - 370);
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
    final researchCredits =
        (flags[weekendMarketResearchCreditsFlag] as num?)?.toInt() ?? 0;
    final effectivePrice = researchCredits > 0 ? 0 : dailyMarketReportPrice;
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
    if (state.bankCash < effectivePrice) {
      return FinanceActionResult(
        state: state,
        success: false,
        message: '보고서 구매에 은행 잔고가 ${effectivePrice - state.bankCash}원 부족합니다.',
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
    if (researchCredits > 0) {
      flags[weekendMarketResearchCreditsFlag] = researchCredits - 1;
    }
    final sourceId = 'market-report-$dateKey';
    final next = state.copyWith(
      cash: state.cash - effectivePrice,
      story: state.story.copyWith(storyFlags: flags),
      ledger: [
        ...state.ledger,
        if (effectivePrice > 0)
          LedgerEntry(
            id: sourceId,
            day: state.day,
            amount: -effectivePrice,
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
      message: researchCredits > 0
          ? '주말에 준비한 조사권으로 보고서를 받았습니다. 결과와 방향은 보장하지 않습니다.'
          : '현장 징후를 정리한 보고서를 받았습니다. 결과와 방향은 보장하지 않습니다.',
      cashDelta: -effectivePrice,
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

    if (isMonthlyUnlockDecisionId(decisionId)) {
      return resolveMonthlyUnlockDecision(next, decisionId, optionId);
    }

    switch (optionId) {
      case 'meet_bank_clerk_deposit':
      case 'meet_bank_clerk_credit':
        next = next.copyWith(
          story: next.story.copyWith(
            storyFlags: {
              ...next.story.storyFlags,
              bankAccessUnlockedFlag: true,
              'bankAccessUnlockedDay': next.day,
              'bankIntroductionFocus': optionId == 'meet_bank_clerk_deposit'
                  ? 'deposit'
                  : 'credit',
            },
            seenStoryEventIds: [
              ...next.story.seenStoryEventIds,
              if (!next.story.seenStoryEventIds.contains(
                'BANK_CLERK_YOON_HARIN_INTRODUCED',
              ))
                'BANK_CLERK_YOON_HARIN_INTRODUCED',
            ],
          ),
        );
      case 'meet_realtor_home':
      case 'meet_realtor_cashflow':
        next = next.copyWith(
          story: next.story.copyWith(
            storyFlags: {
              ...next.story.storyFlags,
              realEstateAccessUnlockedFlag: true,
              'realEstateAccessUnlockedDay': next.day,
              'realtorIntroductionFocus': optionId == 'meet_realtor_home'
                  ? 'home'
                  : 'cashflow',
            },
            seenStoryEventIds: [
              ...next.story.seenStoryEventIds,
              if (!next.story.seenStoryEventIds.contains(
                'REALTOR_SEO_HANEUL_INTRODUCED',
              ))
                'REALTOR_SEO_HANEUL_INTRODUCED',
            ],
          ),
        );
      case 'acquire_board_observer':
        next = _acquireCompanyStake(
          next,
          decisionId,
          option,
          targetOwnershipPct: 18,
          boardObserver: true,
          boardSeats: 0,
        );
      case 'acquire_board_stake':
      case 'expand_board_stake':
        next = _acquireCompanyStake(
          next,
          decisionId,
          option,
          targetOwnershipPct: 34,
          boardObserver: false,
          boardSeats: 2,
        );
      case 'acquire_control':
      case 'acquire_control_followup':
      case 'complete_control':
        next = _acquireCompanyStake(
          next,
          decisionId,
          option,
          targetOwnershipPct: 55,
          boardObserver: false,
          boardSeats: 4,
        );
      case 'hold_company_stake':
        next = next.copyWith(
          story: next.story.copyWith(
            storyFlags: {...next.story.storyFlags, 'controlStakeHeld': true},
          ),
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
              '경쟁 세력이 한빛전자부품의 우호지분을 먼저 모았습니다. 보유 지분은 유지되지만 이번 경영권 기회는 끝났어요.',
            ),
          ],
        );
      case 'retain_incumbent_ceo':
        next = _assignControlLeadership(
          next,
          CompanyLeadershipModel.incumbent,
          moraleDelta: 6,
          technologyDelta: 0,
          riskDelta: -2,
        );
      case 'appoint_academy_advisor':
        next = _assignControlLeadership(
          next,
          CompanyLeadershipModel.academyAdvisor,
          moraleDelta: 4,
          technologyDelta: 4,
          riskDelta: -3,
        );
      case 'appoint_professional_ceo':
        next = _assignControlLeadership(
          next,
          CompanyLeadershipModel.professional,
          moraleDelta: -2,
          technologyDelta: 3,
          riskDelta: 1,
        );
      case 'factory_automation':
        next = _applyFactoryStrategy(
          next,
          decisionId,
          option,
          strategy: 'automation',
          revenueDelta: 35000,
          operatingCostDelta: -12000,
          technologyDelta: 9,
          moraleDelta: -6,
          riskDelta: 5,
        );
      case 'protect_skilled_workforce':
        next = _applyFactoryStrategy(
          next,
          decisionId,
          option,
          strategy: 'skilled_workforce',
          revenueDelta: 15000,
          operatingCostDelta: 8000,
          technologyDelta: 4,
          moraleDelta: 9,
          riskDelta: -3,
        );
      case 'premium_components':
        next = _applyFactoryStrategy(
          next,
          decisionId,
          option,
          strategy: 'premium_components',
          revenueDelta: 28000,
          operatingCostDelta: 15000,
          technologyDelta: 8,
          moraleDelta: 3,
          riskDelta: 2,
        );
      case 'stabilize_existing_lines':
        next = _applyFactoryStrategy(
          next,
          decisionId,
          option,
          strategy: 'stabilize',
          revenueDelta: 5000,
          operatingCostDelta: -5000,
          technologyDelta: 1,
          moraleDelta: 4,
          riskDelta: -5,
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
            storyFlags: {
              ...next.story.storyFlags,
              'lastObservedEraTechnology': decision.title,
              'cohortTrust': next.story.flagInt('cohortTrust', 30) + 1,
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
      case 'milestone_cohort':
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
    if (state.progression.hasSkill('cohort_briefing')) {
      final flags = Map<String, dynamic>.from(next.story.storyFlags)
        ..['cohortTrust'] = next.story.flagInt('cohortTrust', 30) + 1;
      next = next.copyWith(story: next.story.copyWith(storyFlags: flags));
    }
    return next;
  }

  GameState _acquireCompanyStake(
    GameState state,
    String sourceId,
    DecisionOptionData option, {
    required double targetOwnershipPct,
    required bool boardObserver,
    required int boardSeats,
  }) {
    final firstAcquisition = !state.company.hasOwnership;
    var next = _spend(
      state,
      option.cashCost,
      sourceId,
      '한빛전자부품 지분 취득',
      counterAccount: 'controlled_company_investment',
      assetId: 'hanbit_components',
    );
    final controlled = targetOwnershipPct >= 50;
    final premise = controlled
        ? '의결권 55% · 이사회 4/7석'
        : targetOwnershipPct >= 33.4
        ? '의결권 34% · 이사회 2/7석'
        : '지분 18% · 이사회 관찰권';
    final company = next.company.copyWith(
      id: 'hanbit_components',
      name: '한빛전자부품',
      worldMode: CompanyWorldMode.fictional,
      worldStartedAtDay: firstAcquisition
          ? next.day
          : next.company.worldStartedAtDay,
      worldPremise: premise,
      votingOwnershipPct: targetOwnershipPct,
      economicOwnershipPct: targetOwnershipPct,
      boardObserver: boardObserver,
      boardSeats: boardSeats,
      totalBoardSeats: 7,
      investmentBookValue: next.company.investmentBookValue + option.cashCost,
      acquiredAtDay: firstAcquisition ? next.day : next.company.acquiredAtDay,
      leadershipModel: controlled
          ? CompanyLeadershipModel.unassigned
          : next.company.leadershipModel,
      monthlyRevenue: firstAcquisition ? 160000 : next.company.monthlyRevenue,
      monthlyOperatingCost: firstAcquisition
          ? 132000
          : next.company.monthlyOperatingCost,
      brand: firstAcquisition ? 38 : next.company.brand,
      technology: firstAcquisition ? 44 : next.company.technology,
      morale: firstAcquisition ? 57 : next.company.morale,
      risk: firstAcquisition ? 29 : next.company.risk,
    );
    final flags = Map<String, dynamic>.from(next.story.storyFlags)
      ..['controlTargetCompanyId'] = company.id
      ..['controlOwnershipPct'] = targetOwnershipPct
      ..['controlBoardSeats'] = boardSeats
      ..['controlAcquiredAtDay'] = company.acquiredAtDay;
    if (controlled) {
      flags['controlEstablished'] = true;
      next = next.copyWith(
        company: company,
        story: next.story.copyWith(storyFlags: flags),
        decisions: [...next.decisions, _controlTransitionDecision(next.day)],
      );
      return next;
    }
    next = next.copyWith(
      company: company,
      story: next.story.copyWith(storyFlags: flags),
    );
    return _schedule(
      next,
      'control-stake-followup-${next.day + 90}',
      'control_stake_followup',
      90,
    );
  }

  GameState _assignControlLeadership(
    GameState state,
    CompanyLeadershipModel model, {
    required int moraleDelta,
    required int technologyDelta,
    required int riskDelta,
  }) {
    final flags = Map<String, dynamic>.from(state.story.storyFlags)
      ..['controlledCompanyLeadership'] = model.name;
    if (model == CompanyLeadershipModel.academyAdvisor) {
      flags
        ..['academyOperationsAdvisor'] = true
        ..['cohortTrust'] = state.story.flagInt('cohortTrust', 30) + 2
        ..['teacherTrust'] = state.story.flagInt('teacherTrust', 30) + 3;
    }
    return state.copyWith(
      company: state.company.copyWith(
        leadershipModel: model,
        morale: state.company.morale + moraleDelta,
        technology: state.company.technology + technologyDelta,
        risk: state.company.risk + riskDelta,
      ),
      story: state.story.copyWith(storyFlags: flags),
      decisions: [...state.decisions, _factoryStrategyDecision(state.day)],
    );
  }

  GameState _applyFactoryStrategy(
    GameState state,
    String sourceId,
    DecisionOptionData option, {
    required String strategy,
    required int revenueDelta,
    required int operatingCostDelta,
    required int technologyDelta,
    required int moraleDelta,
    required int riskDelta,
  }) {
    var next = _spend(
      state,
      option.cashCost,
      sourceId,
      '한빛전자부품 운영계획 출자',
      counterAccount: 'controlled_company_capital',
      assetId: state.company.id,
    );
    next = next.copyWith(
      company: next.company.copyWith(
        investmentBookValue: next.company.investmentBookValue + option.cashCost,
        monthlyRevenue: next.company.monthlyRevenue + revenueDelta,
        monthlyOperatingCost:
            next.company.monthlyOperatingCost + operatingCostDelta,
        technology: next.company.technology + technologyDelta,
        morale: next.company.morale + moraleDelta,
        risk: next.company.risk + riskDelta,
      ),
      story: next.story.copyWith(
        storyFlags: {
          ...next.story.storyFlags,
          'controlledCompanyStrategy': strategy,
          'controlledCompanyStrategyDay': next.day,
        },
      ),
    );
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
    flags['cohortTrust'] = state.story.flagInt('cohortTrust', 30) + trust;
    return state.copyWith(
      story: state.story.copyWith(roomLevel: roomLevel, storyFlags: flags),
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
    state = _forfeitOpenCasinoBlackjack(state);
    state = _forfeitOpenCasinoCraps(state);
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
    if (state.currentDate.month == DateTime.december &&
        state.currentDate.day == 31) {
      state = archivePlayerProgressReviewForClosingYear(state);
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
    final accrued = const LocalBusinessEngine().accrueCurrentDay(settled).state;
    var next = accrued.copyWith(
      day: state.day + 1,
      marketMinute: marketDayStartMinute,
      progression: state.progression.record('days_advanced'),
      organization: state.organization.recoverOneDay(),
    );
    next = _settleMatureBankDeposits(next);
    next = const LocalBusinessEngine().advanceOneDay(next).state;
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
    next = const LocalBusinessEngine().reconcilePremises(next).state;
    // Month-opening heroine chapters take narrative priority on their exact
    // start date; other decision cards can resume on the following day.
    next = _applyFacilityUnlockStories(next);
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
    final payableRepayment = const LocalBusinessEngine()
        .repayDisposedBusinessPayablesForDay(processed);
    return prepareHiddenMarketScenario(payableRepayment.state);
  }

  GameState _forfeitOpenCasinoBlackjack(GameState state) {
    final profile = state.personalFinance.casino;
    final hand = profile.activeBlackjack;
    if (hand == null) return state;
    final player = blackjackHandValue(hand.playerCards).total;
    final record = CasinoRoundRecord(
      id: hand.id,
      day: hand.day,
      minute: hand.minute,
      game: CasinoGameType.blackjack,
      betLabel: hand.doubled ? '더블다운' : '기본 핸드',
      stake: hand.stake,
      payout: 0,
      grossPayout: 0,
      nationalFee: 0,
      outcome: '시간 종료 · 몰수',
      detail:
          '플레이어 ${hand.playerCards.map(casinoCardLabel).join(' ')} ($player) · 다음 날 진행으로 핸드 종료',
    );
    return state.copyWith(
      personalFinance: state.personalFinance.copyWith(
        casino: profile.copyWith(
          history: _appendCasinoHistory(profile.history, record),
          activeBlackjack: null,
        ),
      ),
    );
  }

  GameState _forfeitOpenCasinoCraps(GameState state) {
    final profile = state.personalFinance.casino;
    final round = profile.activeCraps;
    if (round == null) return state;
    final rolls = round.rolls
        .map((roll) => '${roll[0]}+${roll[1]}=${roll[0] + roll[1]}')
        .join(' → ');
    final record = CasinoRoundRecord(
      id: round.id,
      day: round.day,
      minute: round.minute,
      game: CasinoGameType.craps,
      betLabel: casinoBetTitle(round.betType),
      stake: round.stake,
      payout: 0,
      grossPayout: 0,
      nationalFee: 0,
      outcome: '시간 종료 · 몰수',
      detail: '포인트 ${round.point} · $rolls · 다음 날 진행으로 라운드 종료',
    );
    return state.copyWith(
      personalFinance: state.personalFinance.copyWith(
        casino: profile.copyWith(
          history: _appendCasinoHistory(profile.history, record),
          activeCraps: null,
        ),
      ),
    );
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
      final linkedBusiness = state.businesses.activeBusinesses.where(
        (business) => business.linkedRealEstateId == asset.id,
      );
      if (asset.isDirectUse || linkedBusiness.isNotEmpty) {
        assets.add(
          asset.copyWith(
            nextRentalSettlementDay: followingSettlementDay,
            lastRentalEvent: linkedBusiness.isNotEmpty
                ? '${linkedBusiness.first.name} 직영점 사용 중 · 공실 위험 없음'
                : '직접 사용 중 · 공실 위험 없음',
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
    final controlledIncome = state.company.monthlyOwnerDistribution;
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
    addEntry('company', controlledIncome, 'company_income', '지분회사 월간 배당');
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
      progression = progression.gainExperience(5);
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
        state.company.hasOwnership ||
        state.story.flagBool('controlOfferPresented') ||
        !state.story.flagBool('firstOrderExecuted') ||
        state.currentDate.isBefore(DateTime(2005, 1, 1)) ||
        state.bankCash < 120000) {
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

  GameState _applyFacilityUnlockStories(GameState state) {
    final decision = nextMonthlyUnlockDecision(state);
    return decision == null
        ? state
        : state.copyWith(
            decisions: <DecisionCardData>[...state.decisions, decision],
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
              '데시멀 전략회의: 유행 이름보다 고객과 현금흐름을 함께 확인하자.',
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
            body: '유행보다 현금흐름을 볼지, 기술의 장기 가능성을 더 조사할지 데시멀 전략회의에서 설명해야 합니다.',
          ),
          (
            id: 'september-eleven',
            date: DateTime(2001, 9, 12),
            title: '불확실성 속에서 지킬 것',
            body: '시장이 흔들리는 날, 계좌보다 공동체와 기록 원칙을 먼저 확인합니다.',
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
            title: '데시멀 센터 밖 첫 사무실',
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
            proposer: '데시멀 전략회의',
            body: milestone.body,
            createdDay: next.day,
            dueDay: next.day + 7,
            requestedFunds: milestone.id == 'office-year'
                ? 50000
                : milestone.id == 'incorporation-year'
                ? 150000
                : 0,
            benefit: '평판·공동체 신뢰·조직 성장',
            risk: '선택에 따라 위험과 성장 속도가 달라집니다.',
            advisorOpinions: const [
              '한서윤: 장부에 설명할 수 있는 선택이어야 합니다.',
              '김학준: 오래 버틸 수 있는 원칙부터 보자.',
            ],
            options: milestone.id == 'office-year'
                ? const [
                    DecisionOptionData(
                      id: 'milestone_prudent',
                      label: '원내 투자실 유지',
                      description: '월 임대료 없이 현금과 원칙을 지킵니다.',
                    ),
                    DecisionOptionData(
                      id: 'milestone_bold',
                      label: '작은 사무실 계약',
                      description: '신뢰를 얻는 대신 다음 달부터 월 5만원 임대료가 생깁니다.',
                    ),
                    DecisionOptionData(
                      id: 'milestone_cohort',
                      label: '공동시설부터 정비',
                      description: '데시멀 생활환경을 개선하고 공동체 신뢰를 우선합니다.',
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
                      id: 'milestone_cohort',
                      label: '공동 회계 약속 후 전환',
                      description: '현재 공간을 유지하며 공동체와 법인 원칙을 정합니다.',
                    ),
                  ]
                : const [
                    DecisionOptionData(
                      id: 'milestone_prudent',
                      label: '현금과 원칙 우선',
                      description: '위험을 낮추고 공동체 신뢰를 높입니다.',
                    ),
                    DecisionOptionData(
                      id: 'milestone_bold',
                      label: '조사 후 과감히 전진',
                      description: '평판과 기술을 얻는 대신 위험이 조금 오릅니다.',
                    ),
                    DecisionOptionData(
                      id: 'milestone_cohort',
                      label: '동기들과 함께 결정',
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
        case 'control_stake_followup':
          if (next.company.hasOwnership && !next.company.isControlled) {
            next = next.copyWith(
              decisions: [
                ...next.decisions,
                _controlStakeFollowUp(next.day, next.company),
              ],
            );
          }
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
    String description, {
    String counterAccount = 'investment',
    String assetId = '',
  }) {
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
          counterAccount: counterAccount,
          description: description,
          sourceId: sourceId,
          assetId: assetId,
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

  static int _stableHash(String input) {
    var hash = 2166136261;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = multiplyFnvPrime31Exact(hash);
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
