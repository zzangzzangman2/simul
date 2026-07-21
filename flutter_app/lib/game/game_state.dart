import 'organization_state.dart';
import 'story_state.dart';

enum WorldMode { historical, diverged }

enum DecisionStatus { pending, resolved }

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
    required this.positions,
    required this.organization,
    required this.story,
    required this.company,
    required this.project,
    required this.decisions,
    required this.scheduledEvents,
    required this.ledger,
    required this.processedEventIds,
  });

  static const schemaVersion = 8;

  final int version;
  final String companyName;
  final int day;
  final int marketMinute;
  final String simulationSeed;
  final int cash;
  final List<PortfolioPosition> positions;
  final OrganizationState organization;
  final StoryState story;
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

  int portfolioValue(Map<String, double> prices) => positions.fold<int>(
    0,
    (sum, position) =>
        sum + ((prices[position.assetId] ?? 0) * position.units).round(),
  );

  int totalAum(Map<String, double> prices) => cash + portfolioValue(prices);

  DateTime get currentDate => DateTime(2000, 1, 1).add(Duration(days: day - 1));

  List<DecisionCardData> get pendingDecisions => decisions
      .where((decision) => decision.status == DecisionStatus.pending)
      .toList(growable: false);

  GameState copyWith({
    int? version,
    String? companyName,
    int? day,
    int? marketMinute,
    String? simulationSeed,
    int? cash,
    List<PortfolioPosition>? positions,
    OrganizationState? organization,
    StoryState? story,
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
      simulationSeed: simulationSeed ?? this.simulationSeed,
      cash: cash ?? this.cash,
      positions: positions ?? this.positions,
      organization: organization ?? this.organization,
      story: story ?? this.story,
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
    'simulationSeed': simulationSeed,
    'cash': cash,
    'positions': positions.map((position) => position.toJson()).toList(),
    'organization': organization.toJson(),
    'story': story.toJson(),
    'company': company.toJson(),
    'project': project?.toJson(),
    'decisions': decisions.map((item) => item.toJson()).toList(),
    'scheduledEvents': scheduledEvents.map((item) => item.toJson()).toList(),
    'ledger': ledger.map((item) => item.toJson()).toList(),
    'processedEventIds': processedEventIds,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      version: (json['version'] as num?)?.toInt() ?? schemaVersion,
      companyName: json['companyName'] as String? ?? '',
      day: ((json['day'] as num?)?.toInt() ?? 1).clamp(1, 4018),
      marketMinute: ((json['marketMinute'] as num?)?.toInt() ?? 480).clamp(
        480,
        1200,
      ),
      simulationSeed: json['simulationSeed'] as String? ?? 'simul-default',
      cash: (json['cash'] as num?)?.toInt() ?? 1000000,
      positions: PortfolioPosition.listFromJson(json['positions']),
      organization: OrganizationState.fromJson(
        (json['organization'] as Map?)?.cast<String, dynamic>() ?? const {},
        legacyTeamCount: (json['team'] as num?)?.toInt() ?? 1,
        familyRule: FamilyRule.values.firstWhere(
          (value) =>
              value.name == ((json['story'] as Map?)?['familyRule'] as String?),
          orElse: () => FamilyRule.reportLosses,
        ),
      ),
      story: StoryState.fromJson(
        (json['story'] as Map?)?.cast<String, dynamic>() ?? const {},
        companyName: json['companyName'] as String? ?? '',
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
    final legacyAsset = _legacyPortfolioAssets[assetId];
    final units = (json['units'] as num?)?.toDouble() ?? 0;
    return PortfolioPosition(
      assetId: assetId,
      symbol: (json['symbol'] as String? ?? legacyAsset?.symbol ?? assetId)
          .trim(),
      name: (json['name'] as String? ?? legacyAsset?.name ?? assetId).trim(),
      market: (json['market'] as String? ?? legacyAsset?.market ?? 'UNKNOWN')
          .trim(),
      currency: (json['currency'] as String? ?? legacyAsset?.currency ?? 'KRW')
          .trim(),
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

class _LegacyPortfolioAsset {
  const _LegacyPortfolioAsset({
    required this.symbol,
    required this.name,
    required this.market,
    required this.currency,
  });

  final String symbol;
  final String name;
  final String market;
  final String currency;
}

const _legacyPortfolioAssets = <String, _LegacyPortfolioAsset>{
  'apple': _LegacyPortfolioAsset(
    symbol: 'AAPL',
    name: 'Apple',
    market: 'NASDAQ',
    currency: 'USD',
  ),
  'microsoft': _LegacyPortfolioAsset(
    symbol: 'MSFT',
    name: 'Microsoft',
    market: 'NASDAQ',
    currency: 'USD',
  ),
  'cisco': _LegacyPortfolioAsset(
    symbol: 'CSCO',
    name: 'Cisco',
    market: 'NASDAQ',
    currency: 'USD',
  ),
  'toyota': _LegacyPortfolioAsset(
    symbol: '7203',
    name: 'Toyota',
    market: 'TSE',
    currency: 'JPY',
  ),
  'sony': _LegacyPortfolioAsset(
    symbol: '6758',
    name: 'Sony',
    market: 'TSE',
    currency: 'JPY',
  ),
  'softbank': _LegacyPortfolioAsset(
    symbol: '9984',
    name: 'SoftBank',
    market: 'TSE',
    currency: 'JPY',
  ),
};

class CompanyState {
  const CompanyState({
    required this.id,
    required this.name,
    required this.worldMode,
    required this.divergedAtDay,
    required this.divergenceReason,
    required this.votingOwnershipPct,
    required this.historicalPriceAtDivergence,
    required this.simulatedPrice,
    required this.monthlyRevenue,
    required this.brand,
    required this.technology,
    required this.morale,
    required this.risk,
  });

  final String id;
  final String name;
  final WorldMode worldMode;
  final int? divergedAtDay;
  final String? divergenceReason;
  final double votingOwnershipPct;
  final double? historicalPriceAtDivergence;
  final double? simulatedPrice;
  final int monthlyRevenue;
  final int brand;
  final int technology;
  final int morale;
  final int risk;

  bool get isControlled => votingOwnershipPct >= 50;

  CompanyState copyWith({
    WorldMode? worldMode,
    int? divergedAtDay,
    String? divergenceReason,
    double? votingOwnershipPct,
    double? historicalPriceAtDivergence,
    double? simulatedPrice,
    int? monthlyRevenue,
    int? brand,
    int? technology,
    int? morale,
    int? risk,
  }) {
    return CompanyState(
      id: id,
      name: name,
      worldMode: worldMode ?? this.worldMode,
      divergedAtDay: divergedAtDay ?? this.divergedAtDay,
      divergenceReason: divergenceReason ?? this.divergenceReason,
      votingOwnershipPct: votingOwnershipPct ?? this.votingOwnershipPct,
      historicalPriceAtDivergence:
          historicalPriceAtDivergence ?? this.historicalPriceAtDivergence,
      simulatedPrice: simulatedPrice ?? this.simulatedPrice,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      brand: (brand ?? this.brand).clamp(0, 100),
      technology: (technology ?? this.technology).clamp(0, 100),
      morale: (morale ?? this.morale).clamp(0, 100),
      risk: (risk ?? this.risk).clamp(0, 100),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'worldMode': worldMode.name,
    'divergedAtDay': divergedAtDay,
    'divergenceReason': divergenceReason,
    'votingOwnershipPct': votingOwnershipPct,
    'historicalPriceAtDivergence': historicalPriceAtDivergence,
    'simulatedPrice': simulatedPrice,
    'monthlyRevenue': monthlyRevenue,
    'brand': brand,
    'technology': technology,
    'morale': morale,
    'risk': risk,
  };

  factory CompanyState.fromJson(Map<String, dynamic> json) => CompanyState(
    id: json['id'] as String? ?? 'apple',
    name: json['name'] as String? ?? 'Apple',
    worldMode: json['worldMode'] == WorldMode.diverged.name
        ? WorldMode.diverged
        : WorldMode.historical,
    divergedAtDay: (json['divergedAtDay'] as num?)?.toInt(),
    divergenceReason: json['divergenceReason'] as String?,
    votingOwnershipPct: (json['votingOwnershipPct'] as num?)?.toDouble() ?? 0,
    historicalPriceAtDivergence: (json['historicalPriceAtDivergence'] as num?)
        ?.toDouble(),
    simulatedPrice: (json['simulatedPrice'] as num?)?.toDouble(),
    monthlyRevenue: (json['monthlyRevenue'] as num?)?.toInt() ?? 120000,
    brand: (json['brand'] as num?)?.toInt() ?? 42,
    technology: (json['technology'] as num?)?.toInt() ?? 48,
    morale: (json['morale'] as num?)?.toInt() ?? 55,
    risk: (json['risk'] as num?)?.toInt() ?? 20,
  );
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

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.day,
    required this.amount,
    required this.account,
    required this.counterAccount,
    required this.description,
    required this.sourceId,
  });

  final String id;
  final int day;
  final int amount;
  final String account;
  final String counterAccount;
  final String description;
  final String sourceId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day,
    'amount': amount,
    'account': account,
    'counterAccount': counterAccount,
    'description': description,
    'sourceId': sourceId,
  };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
    id: json['id'] as String,
    day: (json['day'] as num).toInt(),
    amount: (json['amount'] as num).toInt(),
    account: json['account'] as String? ?? 'cash',
    counterAccount: json['counterAccount'] as String? ?? 'expense',
    description: json['description'] as String? ?? '',
    sourceId: json['sourceId'] as String? ?? '',
  );
}
