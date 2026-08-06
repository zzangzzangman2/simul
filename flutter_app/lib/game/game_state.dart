import 'dart:math' as math;

import 'banking_state.dart';
import 'business_state.dart';
import 'cohort_investment_state.dart';
import 'home_improvement_state.dart';
import 'market_clock.dart';
import 'market_cost_rules.dart';
import 'player_progression.dart';
import 'organization_state.dart';
import 'personal_finance_state.dart';
import 'phone_messenger_state.dart';
import 'relationship_state.dart';
import 'shareholder_governance.dart';
import 'story_state.dart';

enum CompanyWorldMode { fictional }

enum DecisionStatus { pending, resolved }

enum PendingOrderSide { buy, sell }

class PendingTradeOrder {
  const PendingTradeOrder({
    required this.id,
    required this.side,
    required this.assetId,
    required this.symbol,
    required this.name,
    required this.market,
    required this.currency,
    required this.limitPrice,
    required this.originalQuantity,
    required this.remainingQuantity,
    required this.placedDate,
    required this.placedMinute,
    required this.placedSequence,
    this.queueAheadQuantity = 0,
    this.maximumPositionUnits,
    this.isIpoFirstTradingDay = false,
  });

  final String id;
  final PendingOrderSide side;
  final String assetId;
  final String symbol;
  final String name;
  final String market;
  final String currency;
  final double limitPrice;
  final double originalQuantity;
  final double remainingQuantity;
  final String placedDate;
  final int placedMinute;
  final int placedSequence;
  final double queueAheadQuantity;
  final int? maximumPositionUnits;
  final bool isIpoFirstTradingDay;

  double get filledQuantity => originalQuantity - remainingQuantity;

  PendingTradeOrder copyWith({
    double? remainingQuantity,
    double? queueAheadQuantity,
  }) => PendingTradeOrder(
    id: id,
    side: side,
    assetId: assetId,
    symbol: symbol,
    name: name,
    market: market,
    currency: currency,
    limitPrice: limitPrice,
    originalQuantity: originalQuantity,
    remainingQuantity: remainingQuantity ?? this.remainingQuantity,
    placedDate: placedDate,
    placedMinute: placedMinute,
    placedSequence: placedSequence,
    queueAheadQuantity: queueAheadQuantity ?? this.queueAheadQuantity,
    maximumPositionUnits: maximumPositionUnits,
    isIpoFirstTradingDay: isIpoFirstTradingDay,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'side': side.name,
    'assetId': assetId,
    'symbol': symbol,
    'name': name,
    'market': market,
    'currency': currency,
    'limitPrice': limitPrice,
    'originalQuantity': originalQuantity,
    'remainingQuantity': remainingQuantity,
    'placedDate': placedDate,
    'placedMinute': placedMinute,
    'placedSequence': placedSequence,
    'queueAheadQuantity': queueAheadQuantity,
    if (maximumPositionUnits != null)
      'maximumPositionUnits': maximumPositionUnits,
    if (isIpoFirstTradingDay) 'isIpoFirstTradingDay': isIpoFirstTradingDay,
  };

  factory PendingTradeOrder.fromJson(Map<String, dynamic> json) {
    final original = (json['originalQuantity'] as num?)?.toDouble() ?? 0;
    final remaining =
        (json['remainingQuantity'] as num?)?.toDouble() ?? original;
    final rawMaximumPositionUnits = json['maximumPositionUnits'];
    final parsedMaximumPositionUnits =
        rawMaximumPositionUnits is num && rawMaximumPositionUnits.isFinite
        ? rawMaximumPositionUnits.toInt()
        : null;
    return PendingTradeOrder(
      id: json['id'] as String? ?? '',
      side: PendingOrderSide.values.firstWhere(
        (value) => value.name == json['side'],
        orElse: () => PendingOrderSide.buy,
      ),
      assetId: json['assetId'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
      market: json['market'] as String? ?? '',
      currency: json['currency'] as String? ?? 'KRW',
      limitPrice: (json['limitPrice'] as num?)?.toDouble() ?? 0,
      originalQuantity: original,
      remainingQuantity: remaining,
      placedDate: json['placedDate'] as String? ?? '',
      placedMinute: (json['placedMinute'] as num?)?.toInt() ?? 0,
      placedSequence: (json['placedSequence'] as num?)?.toInt() ?? 0,
      queueAheadQuantity: (json['queueAheadQuantity'] as num?)?.toDouble() ?? 0,
      maximumPositionUnits:
          parsedMaximumPositionUnits != null && parsedMaximumPositionUnits > 0
          ? parsedMaximumPositionUnits
          : null,
      isIpoFirstTradingDay: json['isIpoFirstTradingDay'] == true,
    );
  }

  bool get isValid =>
      id.isNotEmpty &&
      assetId.isNotEmpty &&
      currency == 'KRW' &&
      limitPrice.isFinite &&
      limitPrice > 0 &&
      originalQuantity.isFinite &&
      originalQuantity > 0 &&
      remainingQuantity.isFinite &&
      remainingQuantity > 0 &&
      remainingQuantity <= originalQuantity &&
      queueAheadQuantity.isFinite &&
      queueAheadQuantity >= 0 &&
      (maximumPositionUnits == null || maximumPositionUnits! > 0) &&
      placedDate.length == 10 &&
      placedSequence >= 0;
}

enum ProjectStatus {
  proposal,
  development,
  launchReview,
  launched,
  cancelled,
  completed,
}

class GameState {
  GameState({
    required this.version,
    required this.companyName,
    required this.day,
    required this.marketMinute,
    required this.simulationSeed,
    required this.cash,
    required this.brokerageCash,
    required this.positions,
    required this.pendingOrders,
    required this.banking,
    required this.organization,
    required this.personalFinance,
    required this.progression,
    required this.story,
    required this.company,
    required this.project,
    required this.decisions,
    required this.scheduledEvents,
    required this.ledger,
    required this.processedEventIds,
    BusinessPortfolioState? businesses,
    HomeImprovementState? homeImprovements,
    RelationshipState? relationships,
    CohortInvestmentState? cohortInvestments,
    PhoneMessengerState? phoneMessenger,
    ShareholderGovernanceState? shareholderGovernance,
  }) : businesses = businesses ?? const BusinessPortfolioState.initial(),
       homeImprovements =
           homeImprovements ?? const HomeImprovementState.initial(),
       relationships = relationships ?? RelationshipState.initial(),
       cohortInvestments = cohortInvestments ?? CohortInvestmentState.initial(),
       phoneMessenger = phoneMessenger ?? PhoneMessengerState.initial(),
       shareholderGovernance =
           shareholderGovernance ?? const ShareholderGovernanceState();

  static const schemaVersion = 27;
  static const maxCampaignDay = 9862;

  final int version;
  final String companyName;
  final int day;
  final int marketMinute;
  final String simulationSeed;
  final int cash;
  final int brokerageCash;
  final List<PortfolioPosition> positions;
  final List<PendingTradeOrder> pendingOrders;
  final BankingState banking;
  final OrganizationState organization;
  final PersonalFinanceState personalFinance;
  final BusinessPortfolioState businesses;
  final PlayerProgressionState progression;
  final StoryState story;
  final HomeImprovementState homeImprovements;
  final RelationshipState relationships;
  final CohortInvestmentState cohortInvestments;
  final PhoneMessengerState phoneMessenger;
  final ShareholderGovernanceState shareholderGovernance;
  final CompanyState company;
  final ProjectState? project;
  final List<DecisionCardData> decisions;
  final List<ScheduledGameEvent> scheduledEvents;
  final List<LedgerEntry> ledger;
  final List<String> processedEventIds;

  /// Legacy-facing team size. The founder is counted as one person.
  int get team => 1 + organization.employees.length;

  int get portfolioCost =>
      positions.fold<int>(0, (sum, position) => sum + position.totalCost);

  int get bankCash => math.max(0, cash - brokerageCash);

  double get pendingOrderFeeMultiplier {
    final skillDiscount = progression.hasSkill('fee_sense') ? 0.9 : 1.0;
    return skillDiscount;
  }

  int get pendingBuyReservedCash {
    final reservationCeiling = math.max(0, brokerageCash);
    var reserved = 0;
    for (final order in pendingOrders.where(
      (order) => order.side == PendingOrderSide.buy,
    )) {
      final reservation =
          order.limitPrice *
          order.remainingQuantity *
          (1 + marketTradingFeeRate(currentDate) * pendingOrderFeeMultiplier);
      if (!reservation.isFinite) return reservationCeiling;
      if (reservation <= 0) continue;
      final remainingCash = reservationCeiling - reserved;
      if (remainingCash <= 0 || reservation >= remainingCash) {
        return reservationCeiling;
      }
      reserved += reservation.ceil();
    }
    return reserved;
  }

  int get availableBrokerageCash =>
      math.max(0, brokerageCash - pendingBuyReservedCash);

  bool get needsTradingRecovery =>
      story.marketTutorialSeen &&
      positions.isEmpty &&
      availableBrokerageCash < cohortPlayerRecoveryCashThreshold;

  DateTime _brokerageSettlementDateFor(LedgerEntry entry) {
    var date = dateForDay(entry.day);
    var remainingTradingDays = 2;
    while (remainingTradingDays > 0) {
      date = date.add(const Duration(days: 1));
      if (isMarketTradingDay(date)) remainingTradingDays -= 1;
    }
    return date;
  }

  /// Net sell proceeds that are usable for another order but not yet
  /// transferable to the company bank account under the market's T+2 rule.
  int get unsettledBrokerageSellProceeds => ledger
      .where(
        (entry) =>
            entry.tradeSide == 'sell' &&
            entry.amount > 0 &&
            entry.day <= day &&
            currentDate.isBefore(_brokerageSettlementDateFor(entry)),
      )
      .fold<int>(0, (sum, entry) {
        final remaining = 0x7fffffff - sum;
        return entry.amount >= remaining ? 0x7fffffff : sum + entry.amount;
      });

  /// Cash that may leave the brokerage account now.
  ///
  /// Pending buy reservations and unsettled sell proceeds remain part of
  /// buying power, but cannot be withdrawn.
  int get withdrawableBrokerageCash => math.max(
    0,
    brokerageCash - pendingBuyReservedCash - unsettledBrokerageSellProceeds,
  );

  double pendingSellReservedUnits(String assetId) => pendingOrders
      .where(
        (order) =>
            order.assetId == assetId && order.side == PendingOrderSide.sell,
      )
      .fold<double>(0, (sum, order) => sum + order.remainingQuantity);

  double pendingBuyReservedUnits(String assetId) => pendingOrders
      .where(
        (order) =>
            order.assetId == assetId && order.side == PendingOrderSide.buy,
      )
      .fold<double>(0, (sum, order) => sum + order.remainingQuantity);

  int portfolioValue(Map<String, double> prices) => positions.fold<int>(
    0,
    (sum, position) =>
        sum + ((prices[position.assetId] ?? 0) * position.units).round(),
  );

  int totalAum(Map<String, double> prices) => cash + portfolioValue(prices);

  int get totalKnownLiabilities =>
      banking.totalUnsecuredLoanBalance +
      cohortInvestments.outstandingLoanPayables +
      personalFinance.totalMortgageBalance +
      personalFinance.totalTenantDepositLiability +
      businesses.totalAccountsPayable +
      story.flagInt('mortgageDeficiencyDebt') +
      story.flagInt('tenantDepositDebt') +
      story.flagInt('unpaidOperatingCost');

  int balanceSheetGrossAssets({Map<String, double>? prices}) =>
      cash +
      story.selfRelianceReserve +
      personalFinance.casino.chipBalance +
      businesses.totalBookValue +
      company.investmentBookValue +
      banking.termDepositAssetValueAt(day) +
      cohortInvestments.outstandingLoanReceivables +
      (prices == null ? portfolioCost : portfolioValue(prices)) +
      personalFinance.estimatedPropertyValueAt(day);

  int balanceSheetNetWorth({Map<String, double>? prices}) =>
      balanceSheetGrossAssets(prices: prices) - totalKnownLiabilities;

  DateTime get campaignStartDate {
    final encoded = story.storyFlags['campaignStartDate'];
    if (encoded is String) {
      final parsed = DateTime.tryParse(encoded);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return DateTime(2000, 1, 1);
  }

  DateTime dateForDay(int value) =>
      campaignStartDate.add(Duration(days: value - 1));

  DateTime get currentDate => dateForDay(day);
  bool get campaignComplete =>
      !currentDate.isBefore(DateTime(fictionalCampaignEndYear, 12, 31));

  List<DecisionCardData> get pendingDecisions => decisions
      .where((decision) => decision.status == DecisionStatus.pending)
      .toList(growable: false);

  GameState copyWith({
    int? version,
    String? companyName,
    int? day,
    int? marketMinute,
    int? brokerageCash,
    String? simulationSeed,
    int? cash,
    List<PortfolioPosition>? positions,
    List<PendingTradeOrder>? pendingOrders,
    BankingState? banking,
    OrganizationState? organization,
    PersonalFinanceState? personalFinance,
    BusinessPortfolioState? businesses,
    PlayerProgressionState? progression,
    StoryState? story,
    HomeImprovementState? homeImprovements,
    RelationshipState? relationships,
    CohortInvestmentState? cohortInvestments,
    PhoneMessengerState? phoneMessenger,
    ShareholderGovernanceState? shareholderGovernance,
    CompanyState? company,
    ProjectState? project,
    bool clearProject = false,
    List<DecisionCardData>? decisions,
    List<ScheduledGameEvent>? scheduledEvents,
    List<LedgerEntry>? ledger,
    List<String>? processedEventIds,
  }) {
    return GameState(
      version: version ?? this.version,
      companyName: companyName ?? this.companyName,
      day: day ?? this.day,
      marketMinute: marketMinute ?? this.marketMinute,
      brokerageCash: (brokerageCash ?? this.brokerageCash).clamp(
        0,
        math.max(0, cash ?? this.cash),
      ),
      simulationSeed: simulationSeed ?? this.simulationSeed,
      cash: cash ?? this.cash,
      positions: positions ?? this.positions,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      banking: banking ?? this.banking,
      organization: organization ?? this.organization,
      personalFinance: personalFinance ?? this.personalFinance,
      businesses: businesses ?? this.businesses,
      progression: progression ?? this.progression,
      story: story ?? this.story,
      homeImprovements: homeImprovements ?? this.homeImprovements,
      relationships: relationships ?? this.relationships,
      cohortInvestments: cohortInvestments ?? this.cohortInvestments,
      phoneMessenger: phoneMessenger ?? this.phoneMessenger,
      shareholderGovernance:
          shareholderGovernance ?? this.shareholderGovernance,
      company: company ?? this.company,
      project: clearProject ? null : project ?? this.project,
      decisions: decisions ?? this.decisions,
      scheduledEvents: scheduledEvents ?? this.scheduledEvents,
      ledger: ledger ?? this.ledger,
      processedEventIds: processedEventIds ?? this.processedEventIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': schemaVersion,
    'companyName': companyName,
    'day': day,
    'marketMinute': marketMinute,
    'currentDate': currentDate.toIso8601String().split('T').first,
    'brokerageCash': brokerageCash,
    'simulationSeed': simulationSeed,
    'cash': cash,
    'positions': positions.map((position) => position.toJson()).toList(),
    'pendingOrders': pendingOrders.map((order) => order.toJson()).toList(),
    'banking': banking.toJson(),
    'organization': organization.toJson(),
    'personalFinance': personalFinance.toJson(),
    'businesses': businesses.toJson(),
    'progression': progression.toJson(),
    'story': story.toJson(),
    'homeImprovements': homeImprovements.toJson(),
    'relationships': relationships.toJson(),
    'cohortInvestments': cohortInvestments.toJson(),
    'phoneMessenger': phoneMessenger.toJson(),
    'shareholderGovernance': shareholderGovernance.toJson(),
    'company': company.toJson(),
    'project': project?.toJson(),
    'decisions': decisions.map((item) => item.toJson()).toList(),
    'scheduledEvents': scheduledEvents.map((item) => item.toJson()).toList(),
    'ledger': ledger.map((item) => item.toJson()).toList(),
    'processedEventIds': processedEventIds,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final cash = (json['cash'] as num?)?.toInt() ?? 0;
    final brokerageCash = ((json['brokerageCash'] as num?)?.toInt() ?? cash)
        .clamp(0, math.max(0, cash))
        .toInt();
    return GameState(
      version: schemaVersion,
      companyName: json['companyName'] as String? ?? '',
      day: ((json['day'] as num?)?.toInt() ?? 1).clamp(1, maxCampaignDay),
      marketMinute: ((json['marketMinute'] as num?)?.toInt() ?? 480).clamp(
        marketDayStartMinute,
        phoneMessengerBedtimeMinute,
      ),
      simulationSeed: json['simulationSeed'] as String? ?? 'simul-default',
      cash: cash,
      brokerageCash: brokerageCash,
      positions: PortfolioPosition.listFromJson(json['positions']),
      pendingOrders: ((json['pendingOrders'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => PendingTradeOrder.fromJson(item.cast<String, dynamic>()),
          )
          .where((order) => order.isValid)
          .toList(growable: false),
      banking: BankingState.fromJson(
        (json['banking'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      organization: OrganizationState.fromJson(
        (json['organization'] as Map?)?.cast<String, dynamic>() ?? const {},
        legacyTeamCount: (json['team'] as num?)?.toInt() ?? 1,
        operatingPrinciple: OperatingPrinciple.values.firstWhere(
          (value) =>
              value.name ==
              ((json['story'] as Map?)?['operatingPrinciple'] as String?),
          orElse: () => OperatingPrinciple.reportLosses,
        ),
      ),
      personalFinance: PersonalFinanceState.fromJson(
        (json['personalFinance'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      businesses: BusinessPortfolioState.fromJson(
        (json['businesses'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      progression: PlayerProgressionState.fromJson(
        (json['progression'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      story: StoryState.fromJson(
        (json['story'] as Map?)?.cast<String, dynamic>() ?? const {},
        companyName: json['companyName'] as String? ?? '',
      ),
      homeImprovements: HomeImprovementState.fromJson(
        (json['homeImprovements'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      relationships: RelationshipState.fromJson(
        (json['relationships'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      cohortInvestments: CohortInvestmentState.fromJson(
        (json['cohortInvestments'] as Map?)?.cast<String, dynamic>() ??
            const {},
      ),
      phoneMessenger: PhoneMessengerState.fromJson(
        (json['phoneMessenger'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      shareholderGovernance: ShareholderGovernanceState.fromJson(
        (json['shareholderGovernance'] as Map?)?.cast<String, dynamic>() ??
            const {},
      ),
      company: CompanyState.fromJson(
        (json['company'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      project: json['project'] == null
          ? null
          : ProjectState.fromJson(
              (json['project'] as Map).cast<String, dynamic>(),
            ),
      decisions: ((json['decisions'] as List?) ?? const [])
          .map(
            (item) => DecisionCardData.fromJson(
              (item as Map).cast<String, dynamic>(),
            ),
          )
          .where((decision) => decision.category != '처음 배우기')
          .toList(),
      scheduledEvents: ((json['scheduledEvents'] as List?) ?? const [])
          .map(
            (item) => ScheduledGameEvent.fromJson(
              (item as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
      ledger: ((json['ledger'] as List?) ?? const [])
          .map(
            (item) =>
                LedgerEntry.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      processedEventIds: ((json['processedEventIds'] as List?) ?? const [])
          .cast<String>(),
    );
  }
}

class PortfolioPosition {
  const PortfolioPosition({
    required this.assetId,
    required this.symbol,
    required this.name,
    required this.market,
    required this.currency,
    required this.units,
    required this.totalCost,
  });

  final String assetId;
  final String symbol;
  final String name;
  final String market;
  final String currency;
  final double units;
  final int totalCost;

  double get averageCost => units <= 0 ? 0 : totalCost / units;

  PortfolioPosition copyWith({double? units, int? totalCost}) =>
      PortfolioPosition(
        assetId: assetId,
        symbol: symbol,
        name: name,
        market: market,
        currency: currency,
        units: units ?? this.units,
        totalCost: totalCost ?? this.totalCost,
      );

  Map<String, dynamic> toJson() => {
    'assetId': assetId,
    'symbol': symbol,
    'name': name,
    'market': market,
    'currency': currency,
    'units': units,
    'totalCost': totalCost,
  };

  factory PortfolioPosition.fromJson(
    Map<String, dynamic> json, {
    String? legacyAssetId,
  }) {
    final assetId = (json['assetId'] as String? ?? legacyAssetId ?? '').trim();
    final units = (json['units'] as num?)?.toDouble() ?? 0;
    return PortfolioPosition(
      assetId: assetId,
      symbol: (json['symbol'] as String? ?? assetId).trim(),
      name: (json['name'] as String? ?? assetId).trim(),
      market: (json['market'] as String? ?? 'UNKNOWN').trim(),
      currency: (json['currency'] as String? ?? 'KRW').trim(),
      units: units.isFinite && units > 0 ? units : 0,
      totalCost: ((json['totalCost'] ?? json['cost']) as num?)?.toInt() ?? 0,
    );
  }

  static List<PortfolioPosition> listFromJson(Object? raw) {
    final positions = <PortfolioPosition>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final position = PortfolioPosition.fromJson(
          item.cast<String, dynamic>(),
        );
        if (position.assetId.isNotEmpty &&
            position.units > 0 &&
            position.totalCost >= 0) {
          positions.add(position);
        }
      }
    } else if (raw is Map) {
      for (final entry in raw.entries) {
        if (entry.value is! Map) continue;
        final position = PortfolioPosition.fromJson(
          (entry.value as Map).cast<String, dynamic>(),
          legacyAssetId: entry.key.toString(),
        );
        if (position.assetId.isNotEmpty &&
            position.units > 0 &&
            position.totalCost >= 0) {
          positions.add(position);
        }
      }
    }
    return positions;
  }
}

enum CompanyLeadershipModel {
  unassigned,
  incumbent,
  academyAdvisor,
  professional,
}

class CompanyState {
  const CompanyState({
    required this.id,
    required this.name,
    required this.worldMode,
    required this.worldStartedAtDay,
    required this.worldPremise,
    required this.votingOwnershipPct,
    required this.worldReferencePrice,
    required this.simulatedPrice,
    required this.monthlyRevenue,
    required this.brand,
    required this.technology,
    required this.morale,
    required this.risk,
    this.economicOwnershipPct = 0,
    this.boardObserver = false,
    this.boardSeats = 0,
    this.totalBoardSeats = 7,
    this.investmentBookValue = 0,
    this.acquiredAtDay = 0,
    this.leadershipModel = CompanyLeadershipModel.unassigned,
    this.monthlyOperatingCost = 90000,
  });

  final String id;
  final String name;
  final CompanyWorldMode worldMode;
  final int? worldStartedAtDay;
  final String? worldPremise;
  final double votingOwnershipPct;
  final double? worldReferencePrice;
  final double? simulatedPrice;
  final int monthlyRevenue;
  final int brand;
  final int technology;
  final int morale;
  final int risk;
  final double economicOwnershipPct;
  final bool boardObserver;
  final int boardSeats;
  final int totalBoardSeats;
  final int investmentBookValue;
  final int acquiredAtDay;
  final CompanyLeadershipModel leadershipModel;
  final int monthlyOperatingCost;

  bool get isControlled => votingOwnershipPct >= 50;
  double get effectiveEconomicOwnershipPct =>
      economicOwnershipPct > 0 ? economicOwnershipPct : votingOwnershipPct;
  bool get hasOwnership =>
      effectiveEconomicOwnershipPct > 0 ||
      votingOwnershipPct > 0 ||
      investmentBookValue > 0;
  bool get hasBoardAccess => boardObserver || boardSeats > 0 || isControlled;
  bool get hasBoardMajority =>
      totalBoardSeats > 0 && boardSeats > totalBoardSeats / 2;
  int get monthlyOperatingProfit => monthlyRevenue - monthlyOperatingCost;
  int get monthlyOwnerDistribution => hasOwnership
      ? (math.max(0, monthlyOperatingProfit) *
                0.30 *
                effectiveEconomicOwnershipPct /
                100)
            .round()
      : 0;
  String get controlTierLabel {
    if (isControlled) return '경영권';
    if (votingOwnershipPct >= 33.4 || boardSeats >= 2) return '주요주주';
    if (hasBoardAccess) return '이사회 관찰';
    if (hasOwnership) return '소수지분';
    return '미보유';
  }

  CompanyState copyWith({
    String? id,
    String? name,
    CompanyWorldMode? worldMode,
    int? worldStartedAtDay,
    String? worldPremise,
    double? votingOwnershipPct,
    double? worldReferencePrice,
    double? simulatedPrice,
    int? monthlyRevenue,
    int? brand,
    int? technology,
    int? morale,
    int? risk,
    double? economicOwnershipPct,
    bool? boardObserver,
    int? boardSeats,
    int? totalBoardSeats,
    int? investmentBookValue,
    int? acquiredAtDay,
    CompanyLeadershipModel? leadershipModel,
    int? monthlyOperatingCost,
  }) {
    return CompanyState(
      id: id ?? this.id,
      name: name ?? this.name,
      worldMode: worldMode ?? this.worldMode,
      worldStartedAtDay: worldStartedAtDay ?? this.worldStartedAtDay,
      worldPremise: worldPremise ?? this.worldPremise,
      votingOwnershipPct: votingOwnershipPct ?? this.votingOwnershipPct,
      worldReferencePrice: worldReferencePrice ?? this.worldReferencePrice,
      simulatedPrice: simulatedPrice ?? this.simulatedPrice,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      brand: (brand ?? this.brand).clamp(0, 100),
      technology: (technology ?? this.technology).clamp(0, 100),
      morale: (morale ?? this.morale).clamp(0, 100),
      risk: (risk ?? this.risk).clamp(0, 100),
      economicOwnershipPct: (economicOwnershipPct ?? this.economicOwnershipPct)
          .clamp(0, 100),
      boardObserver: boardObserver ?? this.boardObserver,
      boardSeats: (boardSeats ?? this.boardSeats).clamp(
        0,
        totalBoardSeats ?? this.totalBoardSeats,
      ),
      totalBoardSeats: math.max(1, totalBoardSeats ?? this.totalBoardSeats),
      investmentBookValue: math.max(
        0,
        investmentBookValue ?? this.investmentBookValue,
      ),
      acquiredAtDay: math.max(0, acquiredAtDay ?? this.acquiredAtDay),
      leadershipModel: leadershipModel ?? this.leadershipModel,
      monthlyOperatingCost: math.max(
        0,
        monthlyOperatingCost ?? this.monthlyOperatingCost,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'worldMode': worldMode.name,
    'worldStartedAtDay': worldStartedAtDay,
    'worldPremise': worldPremise,
    'votingOwnershipPct': votingOwnershipPct,
    'worldReferencePrice': worldReferencePrice,
    'simulatedPrice': simulatedPrice,
    'monthlyRevenue': monthlyRevenue,
    'brand': brand,
    'technology': technology,
    'morale': morale,
    'risk': risk,
    'economicOwnershipPct': economicOwnershipPct,
    'boardObserver': boardObserver,
    'boardSeats': boardSeats,
    'totalBoardSeats': totalBoardSeats,
    'investmentBookValue': investmentBookValue,
    'acquiredAtDay': acquiredAtDay,
    'leadershipModel': leadershipModel.name,
    'monthlyOperatingCost': monthlyOperatingCost,
  };

  factory CompanyState.fromJson(Map<String, dynamic> json) {
    final votingOwnershipPct =
        (json['votingOwnershipPct'] as num?)?.toDouble() ?? 0;
    final totalBoardSeats = math.max(
      1,
      (json['totalBoardSeats'] as num?)?.toInt() ?? 7,
    );
    final defaultBoardSeats = votingOwnershipPct >= 50
        ? (totalBoardSeats ~/ 2) + 1
        : 0;
    final monthlyRevenue = (json['monthlyRevenue'] as num?)?.toInt() ?? 120000;
    return CompanyState(
      id: json['id'] as String? ?? 'hanbit_telecom',
      name: json['name'] as String? ?? '한빛통신',
      worldMode: CompanyWorldMode.fictional,
      worldStartedAtDay:
          ((json['worldStartedAtDay'] ?? json['divergedAtDay']) as num?)
              ?.toInt(),
      worldPremise:
          (json['worldPremise'] ?? json['divergenceReason']) as String?,
      votingOwnershipPct: votingOwnershipPct,
      worldReferencePrice:
          ((json['worldReferencePrice'] ?? json['historicalPriceAtDivergence'])
                  as num?)
              ?.toDouble(),
      simulatedPrice: (json['simulatedPrice'] as num?)?.toDouble(),
      monthlyRevenue: monthlyRevenue,
      brand: (json['brand'] as num?)?.toInt() ?? 42,
      technology: (json['technology'] as num?)?.toInt() ?? 48,
      morale: (json['morale'] as num?)?.toInt() ?? 55,
      risk: (json['risk'] as num?)?.toInt() ?? 20,
      economicOwnershipPct:
          (json['economicOwnershipPct'] as num?)?.toDouble() ??
          votingOwnershipPct,
      boardObserver: json['boardObserver'] as bool? ?? false,
      boardSeats: ((json['boardSeats'] as num?)?.toInt() ?? defaultBoardSeats)
          .clamp(0, totalBoardSeats),
      totalBoardSeats: totalBoardSeats,
      investmentBookValue: (json['investmentBookValue'] as num?)?.toInt() ?? 0,
      acquiredAtDay:
          (json['acquiredAtDay'] as num?)?.toInt() ??
          ((json['worldStartedAtDay'] ?? json['divergedAtDay']) as num?)
              ?.toInt() ??
          0,
      leadershipModel: CompanyLeadershipModel.values.firstWhere(
        (value) => value.name == json['leadershipModel'],
        orElse: () => CompanyLeadershipModel.unassigned,
      ),
      monthlyOperatingCost:
          (json['monthlyOperatingCost'] as num?)?.toInt() ??
          (monthlyRevenue * 0.75).round(),
    );
  }
}

class ProjectState {
  const ProjectState({
    required this.id,
    required this.codename,
    required this.status,
    required this.approvedBudget,
    required this.spentBudget,
    required this.progress,
    required this.quality,
    required this.marketFit,
    required this.path,
  });

  final String id;
  final String codename;
  final ProjectStatus status;
  final int approvedBudget;
  final int spentBudget;
  final int progress;
  final int quality;
  final int marketFit;
  final String path;

  ProjectState copyWith({
    ProjectStatus? status,
    int? approvedBudget,
    int? spentBudget,
    int? progress,
    int? quality,
    int? marketFit,
    String? path,
  }) => ProjectState(
    id: id,
    codename: codename,
    status: status ?? this.status,
    approvedBudget: approvedBudget ?? this.approvedBudget,
    spentBudget: spentBudget ?? this.spentBudget,
    progress: (progress ?? this.progress).clamp(0, 100),
    quality: (quality ?? this.quality).clamp(0, 100),
    marketFit: (marketFit ?? this.marketFit).clamp(0, 100),
    path: path ?? this.path,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'codename': codename,
    'status': status.name,
    'approvedBudget': approvedBudget,
    'spentBudget': spentBudget,
    'progress': progress,
    'quality': quality,
    'marketFit': marketFit,
    'path': path,
  };

  factory ProjectState.fromJson(Map<String, dynamic> json) => ProjectState(
    id: json['id'] as String? ?? 'project-atlas',
    codename: json['codename'] as String? ?? 'Project Atlas',
    status: ProjectStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => ProjectStatus.proposal,
    ),
    approvedBudget: (json['approvedBudget'] as num?)?.toInt() ?? 0,
    spentBudget: (json['spentBudget'] as num?)?.toInt() ?? 0,
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    quality: (json['quality'] as num?)?.toInt() ?? 50,
    marketFit: (json['marketFit'] as num?)?.toInt() ?? 50,
    path: json['path'] as String? ?? 'undecided',
  );
}

class DecisionCardData {
  const DecisionCardData({
    required this.id,
    required this.category,
    required this.title,
    required this.proposer,
    required this.body,
    required this.createdDay,
    required this.dueDay,
    required this.requestedFunds,
    required this.benefit,
    required this.risk,
    required this.advisorOpinions,
    required this.options,
    this.status = DecisionStatus.pending,
    this.selectedOptionId,
  });

  final String id;
  final String category;
  final String title;
  final String proposer;
  final String body;
  final int createdDay;
  final int dueDay;
  final int requestedFunds;
  final String benefit;
  final String risk;
  final List<String> advisorOpinions;
  final List<DecisionOptionData> options;
  final DecisionStatus status;
  final String? selectedOptionId;

  DecisionCardData resolve(String optionId) => DecisionCardData(
    id: id,
    category: category,
    title: title,
    proposer: proposer,
    body: body,
    createdDay: createdDay,
    dueDay: dueDay,
    requestedFunds: requestedFunds,
    benefit: benefit,
    risk: risk,
    advisorOpinions: advisorOpinions,
    options: options,
    status: DecisionStatus.resolved,
    selectedOptionId: optionId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'title': title,
    'proposer': proposer,
    'body': body,
    'createdDay': createdDay,
    'dueDay': dueDay,
    'requestedFunds': requestedFunds,
    'benefit': benefit,
    'risk': risk,
    'advisorOpinions': advisorOpinions,
    'options': options.map((item) => item.toJson()).toList(),
    'status': status.name,
    'selectedOptionId': selectedOptionId,
  };

  factory DecisionCardData.fromJson(Map<String, dynamic> json) =>
      DecisionCardData(
        id: json['id'] as String,
        category: json['category'] as String? ?? 'story',
        title: json['title'] as String? ?? '',
        proposer: json['proposer'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdDay: (json['createdDay'] as num?)?.toInt() ?? 1,
        dueDay: (json['dueDay'] as num?)?.toInt() ?? 1,
        requestedFunds: (json['requestedFunds'] as num?)?.toInt() ?? 0,
        benefit: json['benefit'] as String? ?? '',
        risk: json['risk'] as String? ?? '',
        advisorOpinions: ((json['advisorOpinions'] as List?) ?? const [])
            .cast<String>(),
        options: ((json['options'] as List?) ?? const [])
            .map(
              (item) => DecisionOptionData.fromJson(
                (item as Map).cast<String, dynamic>(),
              ),
            )
            .toList(),
        status: json['status'] == DecisionStatus.resolved.name
            ? DecisionStatus.resolved
            : DecisionStatus.pending,
        selectedOptionId: json['selectedOptionId'] as String?,
      );
}

class DecisionOptionData {
  const DecisionOptionData({
    required this.id,
    required this.label,
    required this.description,
    this.cashCost = 0,
  });

  final String id;
  final String label;
  final String description;
  final int cashCost;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'description': description,
    'cashCost': cashCost,
  };

  factory DecisionOptionData.fromJson(Map<String, dynamic> json) =>
      DecisionOptionData(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        description: json['description'] as String? ?? '',
        cashCost: (json['cashCost'] as num?)?.toInt() ?? 0,
      );
}

class ScheduledGameEvent {
  const ScheduledGameEvent({
    required this.id,
    required this.type,
    required this.dueDay,
  });

  final String id;
  final String type;
  final int dueDay;

  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'dueDay': dueDay};

  factory ScheduledGameEvent.fromJson(Map<String, dynamic> json) =>
      ScheduledGameEvent(
        id: json['id'] as String,
        type: json['type'] as String,
        dueDay: (json['dueDay'] as num).toInt(),
      );
}

class LedgerOrderBookFill {
  const LedgerOrderBookFill({required this.price, required this.quantity});

  final double price;
  final double quantity;

  Map<String, dynamic> toJson() => {'price': price, 'quantity': quantity};

  factory LedgerOrderBookFill.fromJson(Map<String, dynamic> json) =>
      LedgerOrderBookFill(
        price: (json['price'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      );
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.day,
    required this.amount,
    required this.account,
    required this.counterAccount,
    required this.description,
    required this.sourceId,
    this.notional = 0,
    this.tradingFee = 0,
    this.transactionTax = 0,
    this.disposedCost = 0,
    this.realizedPnl = 0,
    this.assetId = '',
    this.tradeSide = '',
    this.tradeQuantity = 0,
    this.tradeUnitPrice = 0,
    this.marketMinute = -1,
    this.orderType = '',
    this.orderBookSide = '',
    this.orderBookFills = const <LedgerOrderBookFill>[],
    this.orderBookCapacityUnits = 0,
  });

  final String id;
  final int day;
  final int amount;
  final String account;
  final String counterAccount;
  final String description;
  final String sourceId;
  final int notional;
  final int tradingFee;
  final int transactionTax;
  final int disposedCost;
  final int realizedPnl;
  final String assetId;
  final String tradeSide;
  final double tradeQuantity;
  final double tradeUnitPrice;
  final int marketMinute;
  final String orderType;
  final String orderBookSide;
  final List<LedgerOrderBookFill> orderBookFills;
  final int orderBookCapacityUnits;

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day,
    'amount': amount,
    'account': account,
    'counterAccount': counterAccount,
    'description': description,
    'sourceId': sourceId,
    'notional': notional,
    'tradingFee': tradingFee,
    if (transactionTax > 0) 'transactionTax': transactionTax,
    'disposedCost': disposedCost,
    'realizedPnl': realizedPnl,
    if (assetId.isNotEmpty) 'assetId': assetId,
    if (tradeSide.isNotEmpty) 'tradeSide': tradeSide,
    if (tradeQuantity > 0) 'tradeQuantity': tradeQuantity,
    if (tradeUnitPrice > 0) 'tradeUnitPrice': tradeUnitPrice,
    if (marketMinute >= 0) 'marketMinute': marketMinute,
    if (orderType.isNotEmpty) 'orderType': orderType,
    if (orderBookSide.isNotEmpty) 'orderBookSide': orderBookSide,
    if (orderBookFills.isNotEmpty)
      'orderBookFills': orderBookFills.map((fill) => fill.toJson()).toList(),
    if (orderBookCapacityUnits > 0)
      'orderBookCapacityUnits': orderBookCapacityUnits,
  };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    final rawOrderBookSide = json['orderBookSide'] as String? ?? '';
    final orderBookSide = rawOrderBookSide == 'ask' || rawOrderBookSide == 'bid'
        ? rawOrderBookSide
        : '';
    final orderBookFills =
        <LedgerOrderBookFill>[
              for (final rawFill
                  in (json['orderBookFills'] as List?) ?? const [])
                if (rawFill is Map)
                  LedgerOrderBookFill.fromJson(
                    Map<String, dynamic>.from(rawFill),
                  ),
            ]
            .where((fill) {
              return fill.price.isFinite &&
                  fill.price > 0 &&
                  fill.quantity.isFinite &&
                  fill.quantity > 0;
            })
            .toList(growable: false);
    return LedgerEntry(
      id: json['id'] as String,
      day: (json['day'] as num).toInt(),
      amount: (json['amount'] as num).toInt(),
      account: json['account'] as String? ?? 'cash',
      counterAccount: json['counterAccount'] as String? ?? 'expense',
      description: json['description'] as String? ?? '',
      sourceId: json['sourceId'] as String? ?? '',
      notional: (json['notional'] as num?)?.toInt() ?? 0,
      tradingFee: (json['tradingFee'] as num?)?.toInt() ?? 0,
      transactionTax: (json['transactionTax'] as num?)?.toInt() ?? 0,
      disposedCost: (json['disposedCost'] as num?)?.toInt() ?? 0,
      realizedPnl: (json['realizedPnl'] as num?)?.toInt() ?? 0,
      assetId: json['assetId'] as String? ?? '',
      tradeSide: json['tradeSide'] as String? ?? '',
      tradeQuantity: (json['tradeQuantity'] as num?)?.toDouble() ?? 0,
      tradeUnitPrice: (json['tradeUnitPrice'] as num?)?.toDouble() ?? 0,
      marketMinute: (json['marketMinute'] as num?)?.toInt() ?? -1,
      orderType: json['orderType'] as String? ?? '',
      orderBookSide: orderBookSide,
      orderBookFills: orderBookFills,
      orderBookCapacityUnits: math.max(
        0,
        (json['orderBookCapacityUnits'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
