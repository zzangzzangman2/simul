import 'dart:math' as math;

enum ShareholderRight {
  attendMeeting,
  submitQuestion,
  submitProposal,
  callExtraordinaryMeeting,
  nominateDirector,
  requestAudit,
  publishShareholderLetter,
  boardObserver,
  solicitProxies,
  launchTenderOffer,
  appointCeo,
  approveMajorRestructuring,
}

extension ShareholderRightLabel on ShareholderRight {
  String get label => switch (this) {
    ShareholderRight.attendMeeting => '주주총회 참석·의결권 행사',
    ShareholderRight.submitQuestion => '경영진 서면질의',
    ShareholderRight.submitProposal => '주주제안',
    ShareholderRight.callExtraordinaryMeeting => '임시주총 소집 요구',
    ShareholderRight.nominateDirector => '이사 후보 추천',
    ShareholderRight.requestAudit => '회계장부·감사 요구',
    ShareholderRight.publishShareholderLetter => '공개 주주서한·주주행동',
    ShareholderRight.boardObserver => '이사회 참관',
    ShareholderRight.solicitProxies => '의결권 위임 권유',
    ShareholderRight.launchTenderOffer => '공개매수·경영권 도전',
    ShareholderRight.appointCeo => 'CEO 선임·해임',
    ShareholderRight.approveMajorRestructuring => '합병·분할·핵심자산 재편',
  };
}

enum ListedControlTier {
  none,
  shareholder,
  proposal,
  significant,
  boardInfluence,
  strategic,
  blocking,
  controlled,
  supermajority,
  whollyOwned,
}

extension ListedControlTierLabel on ListedControlTier {
  String get label => switch (this) {
    ListedControlTier.none => '미보유',
    ListedControlTier.shareholder => '일반 주주',
    ListedControlTier.proposal => '주주제안권',
    ListedControlTier.significant => '주요 주주',
    ListedControlTier.boardInfluence => '이사회 영향력',
    ListedControlTier.strategic => '전략적 주주',
    ListedControlTier.blocking => '특별결의 저지 지분',
    ListedControlTier.controlled => '경영권 확보',
    ListedControlTier.supermajority => '특별결의 지배',
    ListedControlTier.whollyOwned => '완전자회사',
  };
}

enum SubsidiaryOperatingPolicy { growth, efficiency, people, dividend }

extension SubsidiaryOperatingPolicyLabel on SubsidiaryOperatingPolicy {
  String get label => switch (this) {
    SubsidiaryOperatingPolicy.growth => '성장 투자',
    SubsidiaryOperatingPolicy.efficiency => '수익성 개선',
    SubsidiaryOperatingPolicy.people => '고용·상생',
    SubsidiaryOperatingPolicy.dividend => '주주 환원',
  };
}

enum SubsidiaryLeadershipModel { founderLed, professionalCeo, jointManagement }

extension SubsidiaryLeadershipModelLabel on SubsidiaryLeadershipModel {
  String get label => switch (this) {
    SubsidiaryLeadershipModel.founderLed => '직접 경영',
    SubsidiaryLeadershipModel.professionalCeo => '전문경영인',
    SubsidiaryLeadershipModel.jointManagement => '공동 경영',
  };
}

enum ListedCeoDirective {
  researchAndDevelopment,
  salesAndBrand,
  automation,
  talentAndCulture,
  globalExpansion,
  debtReduction,
  shareholderReturn,
  compliance,
}

extension ListedCeoDirectiveLabel on ListedCeoDirective {
  String get label => switch (this) {
    ListedCeoDirective.researchAndDevelopment => 'R&D 집중투자',
    ListedCeoDirective.salesAndBrand => '영업·브랜드 강화',
    ListedCeoDirective.automation => '자동화·원가혁신',
    ListedCeoDirective.talentAndCulture => '핵심인재·조직개편',
    ListedCeoDirective.globalExpansion => '해외시장 진출',
    ListedCeoDirective.debtReduction => '부채상환·재무개선',
    ListedCeoDirective.shareholderReturn => '특별배당·주주환원',
    ListedCeoDirective.compliance => '준법·안전 투자',
  };

  String get description => switch (this) {
    ListedCeoDirective.researchAndDevelopment =>
      '연구개발 인력과 설비에 자본을 집중해 미래 제품과 기술격차를 만듭니다.',
    ListedCeoDirective.salesAndBrand =>
      '영업망·광고·고객경험을 동시에 강화해 매출과 브랜드 신뢰를 높입니다.',
    ListedCeoDirective.automation => '생산·물류·업무 시스템을 자동화해 장기 비용구조를 개선합니다.',
    ListedCeoDirective.talentAndCulture =>
      '핵심인재를 영입하고 성과·보상·조직구조를 CEO 책임 아래 재편합니다.',
    ListedCeoDirective.globalExpansion =>
      '현지법인과 판매망에 투자해 큰 성장과 큰 실행위험을 함께 감수합니다.',
    ListedCeoDirective.debtReduction => '회사 현금으로 차입금을 갚아 이자부담과 재무위험을 낮춥니다.',
    ListedCeoDirective.shareholderReturn =>
      '가용현금 일부를 특별배당해 주주에게 돌려주고 성장여력은 줄입니다.',
    ListedCeoDirective.compliance => '준법·품질·안전 체계를 강화해 사고와 규제위험을 낮춥니다.',
  };
}

enum ListedCorporateActionType { merger, jointVenture, spinOff, assetSale }

extension ListedCorporateActionTypeLabel on ListedCorporateActionType {
  String get label => switch (this) {
    ListedCorporateActionType.merger => '합병',
    ListedCorporateActionType.jointVenture => '합작법인',
    ListedCorporateActionType.spinOff => '사업분할',
    ListedCorporateActionType.assetSale => '핵심자산 매각',
  };
}

enum ListedMergerStructure { absorption, holdingCompany, businessCombination }

extension ListedMergerStructureLabel on ListedMergerStructure {
  String get label => switch (this) {
    ListedMergerStructure.absorption => '흡수합병',
    ListedMergerStructure.holdingCompany => '지주회사 통합',
    ListedMergerStructure.businessCombination => '사업부 통합',
  };
}

enum ListedCorporateActionStatus { executing, succeeded, mixed, failed }

extension ListedCorporateActionStatusLabel on ListedCorporateActionStatus {
  String get label => switch (this) {
    ListedCorporateActionStatus.executing => '주총 승인·통합 진행 중',
    ListedCorporateActionStatus.succeeded => '통합 성공',
    ListedCorporateActionStatus.mixed => '부분 통합',
    ListedCorporateActionStatus.failed => '거래 무산',
  };
}

enum ShareholderMeetingStatus { scheduled, open, closed }

enum ShareholderAgendaType {
  dividend,
  directorElection,
  executivePay,
  capitalIncrease,
  merger,
  audit,
  strategy,
  labor,
  assetSale,
}

extension ShareholderAgendaTypeLabel on ShareholderAgendaType {
  String get label => switch (this) {
    ShareholderAgendaType.dividend => '배당 정책',
    ShareholderAgendaType.directorElection => '이사 선임',
    ShareholderAgendaType.executivePay => '임원 보수',
    ShareholderAgendaType.capitalIncrease => '신주 발행',
    ShareholderAgendaType.merger => '합병 승인',
    ShareholderAgendaType.audit => '감사위원 선임',
    ShareholderAgendaType.strategy => '중장기 전략',
    ShareholderAgendaType.labor => '고용·상생 정책',
    ShareholderAgendaType.assetSale => '핵심 자산 매각',
  };
}

enum ShareholderVoteChoice { support, oppose, abstain }

extension ShareholderVoteChoiceLabel on ShareholderVoteChoice {
  String get label => switch (this) {
    ShareholderVoteChoice.support => '찬성',
    ShareholderVoteChoice.oppose => '반대',
    ShareholderVoteChoice.abstain => '기권',
  };
}

enum ListedManagementDecisionStatus { executing, succeeded, mixed, failed }

extension ListedManagementDecisionStatusLabel
    on ListedManagementDecisionStatus {
  String get label => switch (this) {
    ListedManagementDecisionStatus.executing => '진행 중',
    ListedManagementDecisionStatus.succeeded => '성공',
    ListedManagementDecisionStatus.mixed => '부분 성공',
    ListedManagementDecisionStatus.failed => '실패',
  };
}

class ListedManagementDecisionRecord {
  const ListedManagementDecisionRecord({
    required this.id,
    required this.agendaId,
    required this.optionId,
    required this.title,
    required this.optionLabel,
    required this.summary,
    required this.decisionDay,
    required this.completionDay,
    required this.cashCost,
    required this.revenueDeltaBps,
    required this.expenseDeltaBps,
    required this.immediatePriceImpactBps,
    required this.successPriceImpactBps,
    required this.failurePriceImpactBps,
    required this.innovationDelta,
    required this.operationsDelta,
    required this.brandDelta,
    required this.workforceDelta,
    required this.successChancePct,
    this.status = ListedManagementDecisionStatus.executing,
    this.outcome = '',
    this.realizedPriceImpactBps = 0,
  });

  final String id;
  final String agendaId;
  final String optionId;
  final String title;
  final String optionLabel;
  final String summary;
  final int decisionDay;
  final int completionDay;
  final int cashCost;
  final int revenueDeltaBps;
  final int expenseDeltaBps;
  final int immediatePriceImpactBps;
  final int successPriceImpactBps;
  final int failurePriceImpactBps;
  final int innovationDelta;
  final int operationsDelta;
  final int brandDelta;
  final int workforceDelta;
  final double successChancePct;
  final ListedManagementDecisionStatus status;
  final String outcome;
  final int realizedPriceImpactBps;

  bool get isExecuting => status == ListedManagementDecisionStatus.executing;

  int sentimentImpactBpsAt(int day) {
    if (!isExecuting) return 0;
    final duration = math.max(1, completionDay - decisionDay);
    if (day <= decisionDay) return 0;
    final elapsed = (day - decisionDay - 1).clamp(0, duration);
    final remainingFactor = 1 - elapsed / duration * 0.8;
    return (immediatePriceImpactBps * remainingFactor).round();
  }

  ListedManagementDecisionRecord copyWith({
    ListedManagementDecisionStatus? status,
    String? outcome,
    int? realizedPriceImpactBps,
  }) => ListedManagementDecisionRecord(
    id: id,
    agendaId: agendaId,
    optionId: optionId,
    title: title,
    optionLabel: optionLabel,
    summary: summary,
    decisionDay: decisionDay,
    completionDay: completionDay,
    cashCost: cashCost,
    revenueDeltaBps: revenueDeltaBps,
    expenseDeltaBps: expenseDeltaBps,
    immediatePriceImpactBps: immediatePriceImpactBps,
    successPriceImpactBps: successPriceImpactBps,
    failurePriceImpactBps: failurePriceImpactBps,
    innovationDelta: innovationDelta,
    operationsDelta: operationsDelta,
    brandDelta: brandDelta,
    workforceDelta: workforceDelta,
    successChancePct: successChancePct,
    status: status ?? this.status,
    outcome: outcome ?? this.outcome,
    realizedPriceImpactBps:
        realizedPriceImpactBps ?? this.realizedPriceImpactBps,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'agendaId': agendaId,
    'optionId': optionId,
    'title': title,
    'optionLabel': optionLabel,
    'summary': summary,
    'decisionDay': decisionDay,
    'completionDay': completionDay,
    'cashCost': cashCost,
    'revenueDeltaBps': revenueDeltaBps,
    'expenseDeltaBps': expenseDeltaBps,
    'immediatePriceImpactBps': immediatePriceImpactBps,
    'successPriceImpactBps': successPriceImpactBps,
    'failurePriceImpactBps': failurePriceImpactBps,
    'innovationDelta': innovationDelta,
    'operationsDelta': operationsDelta,
    'brandDelta': brandDelta,
    'workforceDelta': workforceDelta,
    'successChancePct': successChancePct,
    'status': status.name,
    'outcome': outcome,
    'realizedPriceImpactBps': realizedPriceImpactBps,
  };

  factory ListedManagementDecisionRecord.fromJson(Map<String, dynamic> json) =>
      ListedManagementDecisionRecord(
        id: json['id'] as String? ?? '',
        agendaId: json['agendaId'] as String? ?? '',
        optionId: json['optionId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        optionLabel: json['optionLabel'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        decisionDay: math.max(1, (json['decisionDay'] as num?)?.toInt() ?? 1),
        completionDay: math.max(
          1,
          (json['completionDay'] as num?)?.toInt() ?? 1,
        ),
        cashCost: math.max(0, (json['cashCost'] as num?)?.toInt() ?? 0),
        revenueDeltaBps: (json['revenueDeltaBps'] as num?)?.toInt() ?? 0,
        expenseDeltaBps: (json['expenseDeltaBps'] as num?)?.toInt() ?? 0,
        immediatePriceImpactBps:
            (json['immediatePriceImpactBps'] as num?)?.toInt() ?? 0,
        successPriceImpactBps:
            (json['successPriceImpactBps'] as num?)?.toInt() ?? 0,
        failurePriceImpactBps:
            (json['failurePriceImpactBps'] as num?)?.toInt() ?? 0,
        innovationDelta: (json['innovationDelta'] as num?)?.toInt() ?? 0,
        operationsDelta: (json['operationsDelta'] as num?)?.toInt() ?? 0,
        brandDelta: (json['brandDelta'] as num?)?.toInt() ?? 0,
        workforceDelta: (json['workforceDelta'] as num?)?.toInt() ?? 0,
        successChancePct: ((json['successChancePct'] as num?)?.toDouble() ?? 50)
            .clamp(0, 100)
            .toDouble(),
        status: ListedManagementDecisionStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => ListedManagementDecisionStatus.executing,
        ),
        outcome: json['outcome'] as String? ?? '',
        realizedPriceImpactBps:
            (json['realizedPriceImpactBps'] as num?)?.toInt() ?? 0,
      );
}

class ListedCorporateActionRecord {
  const ListedCorporateActionRecord({
    required this.id,
    required this.type,
    required this.leadAssetId,
    required this.leadName,
    required this.partnerAssetId,
    required this.partnerName,
    required this.strategy,
    required this.announcedDay,
    required this.completionDay,
    required this.cashCost,
    required this.successChancePct,
    required this.immediatePriceImpactBps,
    required this.successPriceImpactBps,
    required this.failurePriceImpactBps,
    this.status = ListedCorporateActionStatus.executing,
    this.outcome = '',
  });

  final String id;
  final ListedCorporateActionType type;
  final String leadAssetId;
  final String leadName;
  final String partnerAssetId;
  final String partnerName;
  final String strategy;
  final int announcedDay;
  final int completionDay;
  final int cashCost;
  final double successChancePct;
  final int immediatePriceImpactBps;
  final int successPriceImpactBps;
  final int failurePriceImpactBps;
  final ListedCorporateActionStatus status;
  final String outcome;

  bool get isExecuting => status == ListedCorporateActionStatus.executing;

  bool involves(String assetId) =>
      leadAssetId == assetId || partnerAssetId == assetId;

  ListedCorporateActionRecord copyWith({
    ListedCorporateActionStatus? status,
    String? outcome,
  }) => ListedCorporateActionRecord(
    id: id,
    type: type,
    leadAssetId: leadAssetId,
    leadName: leadName,
    partnerAssetId: partnerAssetId,
    partnerName: partnerName,
    strategy: strategy,
    announcedDay: announcedDay,
    completionDay: completionDay,
    cashCost: cashCost,
    successChancePct: successChancePct,
    immediatePriceImpactBps: immediatePriceImpactBps,
    successPriceImpactBps: successPriceImpactBps,
    failurePriceImpactBps: failurePriceImpactBps,
    status: status ?? this.status,
    outcome: outcome ?? this.outcome,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'leadAssetId': leadAssetId,
    'leadName': leadName,
    'partnerAssetId': partnerAssetId,
    'partnerName': partnerName,
    'strategy': strategy,
    'announcedDay': announcedDay,
    'completionDay': completionDay,
    'cashCost': cashCost,
    'successChancePct': successChancePct,
    'immediatePriceImpactBps': immediatePriceImpactBps,
    'successPriceImpactBps': successPriceImpactBps,
    'failurePriceImpactBps': failurePriceImpactBps,
    'status': status.name,
    'outcome': outcome,
  };

  factory ListedCorporateActionRecord.fromJson(Map<String, dynamic> json) =>
      ListedCorporateActionRecord(
        id: json['id'] as String? ?? '',
        type: ListedCorporateActionType.values.firstWhere(
          (value) => value.name == json['type'],
          orElse: () => ListedCorporateActionType.merger,
        ),
        leadAssetId: json['leadAssetId'] as String? ?? '',
        leadName: json['leadName'] as String? ?? '',
        partnerAssetId: json['partnerAssetId'] as String? ?? '',
        partnerName: json['partnerName'] as String? ?? '',
        strategy: json['strategy'] as String? ?? '',
        announcedDay: math.max(1, (json['announcedDay'] as num?)?.toInt() ?? 1),
        completionDay: math.max(
          1,
          (json['completionDay'] as num?)?.toInt() ?? 1,
        ),
        cashCost: math.max(0, (json['cashCost'] as num?)?.toInt() ?? 0),
        successChancePct: ((json['successChancePct'] as num?)?.toDouble() ?? 50)
            .clamp(0, 100)
            .toDouble(),
        immediatePriceImpactBps:
            (json['immediatePriceImpactBps'] as num?)?.toInt() ?? 0,
        successPriceImpactBps:
            (json['successPriceImpactBps'] as num?)?.toInt() ?? 0,
        failurePriceImpactBps:
            (json['failurePriceImpactBps'] as num?)?.toInt() ?? 0,
        status: ListedCorporateActionStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => ListedCorporateActionStatus.executing,
        ),
        outcome: json['outcome'] as String? ?? '',
      );
}

class ListedCompanyGovernance {
  const ListedCompanyGovernance({
    required this.assetId,
    required this.symbol,
    required this.name,
    required this.market,
    required this.sharesOutstanding,
    required this.ownedShares,
    this.tenderAcquiredShares = 0,
    required this.friendlyVotingPct,
    required this.rivalVotingPct,
    required this.boardSeats,
    required this.lastSyncedDay,
    required this.subsidiaryCash,
    required this.subsidiaryDebt,
    required this.monthlyRevenue,
    required this.monthlyExpense,
    required this.retainedEarnings,
    required this.cumulativeDistribution,
    required this.operatingPolicy,
    required this.leadershipModel,
    required this.lastOperationsMonth,
    required this.history,
    this.sector = '기타',
    this.products = const <String>[],
    this.innovation = 50,
    this.operations = 50,
    this.brandTrust = 50,
    this.workforce = 50,
    this.managementValueBps = 0,
    this.lastManagementQuarter = '',
    this.managementDecisions = const <ListedManagementDecisionRecord>[],
    this.playerIsCeo = false,
    this.ceoStartDay,
    this.ceoPerformance = 50,
    this.lastCeoActionMonth = '',
    this.lastShareholderQuestionMonth = '',
    this.lastShareholderLetterQuarter = '',
    this.acquiredControlDay,
    this.lostControlDay,
  });

  final String assetId;
  final String symbol;
  final String name;
  final String market;
  final int sharesOutstanding;
  final double ownedShares;
  final double tenderAcquiredShares;
  final double friendlyVotingPct;
  final double rivalVotingPct;
  final int boardSeats;
  final int lastSyncedDay;
  final int subsidiaryCash;
  final int subsidiaryDebt;
  final int monthlyRevenue;
  final int monthlyExpense;
  final int retainedEarnings;
  final int cumulativeDistribution;
  final SubsidiaryOperatingPolicy operatingPolicy;
  final SubsidiaryLeadershipModel leadershipModel;
  final String lastOperationsMonth;
  final List<String> history;
  final String sector;
  final List<String> products;
  final int innovation;
  final int operations;
  final int brandTrust;
  final int workforce;
  final int managementValueBps;
  final String lastManagementQuarter;
  final List<ListedManagementDecisionRecord> managementDecisions;
  final bool playerIsCeo;
  final int? ceoStartDay;
  final int ceoPerformance;
  final String lastCeoActionMonth;
  final String lastShareholderQuestionMonth;
  final String lastShareholderLetterQuarter;
  final int? acquiredControlDay;
  final int? lostControlDay;

  double get ownershipPct => sharesOutstanding <= 0
      ? 0
      : (ownedShares / sharesOutstanding * 100).clamp(0, 100).toDouble();

  double get votingPowerPct =>
      (ownershipPct + friendlyVotingPct).clamp(0, 100).toDouble();

  bool get isControlled => votingPowerPct >= 50.01;

  double priceMultiplierAt(int day) {
    final recordedRealized = managementDecisions.fold<int>(
      0,
      (total, decision) => total + decision.realizedPriceImpactBps,
    );
    final realizedAtDay = managementDecisions.fold<int>(
      0,
      (total, decision) =>
          total +
          (decision.completionDay < day ? decision.realizedPriceImpactBps : 0),
    );
    final executingSentiment = managementDecisions.fold<int>(
      0,
      (total, decision) =>
          total +
          (day > decision.decisionDay && day <= decision.completionDay
              ? (decision.immediatePriceImpactBps *
                        (1 -
                            (day - decision.decisionDay - 1) /
                                math.max(
                                  1,
                                  decision.completionDay - decision.decisionDay,
                                ) *
                                0.8))
                    .round()
              : 0),
    );
    final baselineValue = managementValueBps - recordedRealized;
    return (1 + (baselineValue + realizedAtDay + executingSentiment) / 10000)
        .clamp(0.35, 2.5)
        .toDouble();
  }

  ListedControlTier get controlTier {
    if (ownershipPct >= 99.99) return ListedControlTier.whollyOwned;
    if (votingPowerPct >= 66.67) return ListedControlTier.supermajority;
    if (isControlled) return ListedControlTier.controlled;
    if (ownershipPct >= 33.34) return ListedControlTier.blocking;
    if (ownershipPct >= 20) return ListedControlTier.strategic;
    if (ownershipPct >= 10) return ListedControlTier.boardInfluence;
    if (ownershipPct >= 5) return ListedControlTier.significant;
    if (ownershipPct >= 1) return ListedControlTier.proposal;
    if (ownershipPct > 0) return ListedControlTier.shareholder;
    return ListedControlTier.none;
  }

  Set<ShareholderRight> get rights {
    final result = <ShareholderRight>{};
    if (ownershipPct > 0) {
      result
        ..add(ShareholderRight.attendMeeting)
        ..add(ShareholderRight.submitQuestion);
    }
    if (ownershipPct >= 1) result.add(ShareholderRight.submitProposal);
    if (ownershipPct >= 3) {
      result
        ..add(ShareholderRight.callExtraordinaryMeeting)
        ..add(ShareholderRight.nominateDirector);
    }
    if (ownershipPct >= 5) {
      result
        ..add(ShareholderRight.requestAudit)
        ..add(ShareholderRight.publishShareholderLetter);
    }
    if (ownershipPct >= 10) {
      result
        ..add(ShareholderRight.boardObserver)
        ..add(ShareholderRight.solicitProxies);
    }
    if (ownershipPct >= 20) result.add(ShareholderRight.launchTenderOffer);
    if (isControlled) result.add(ShareholderRight.appointCeo);
    if (votingPowerPct >= 66.67) {
      result.add(ShareholderRight.approveMajorRestructuring);
    }
    return result;
  }

  ListedCompanyGovernance copyWith({
    String? symbol,
    String? name,
    String? market,
    int? sharesOutstanding,
    double? ownedShares,
    double? tenderAcquiredShares,
    double? friendlyVotingPct,
    double? rivalVotingPct,
    int? boardSeats,
    int? lastSyncedDay,
    int? subsidiaryCash,
    int? subsidiaryDebt,
    int? monthlyRevenue,
    int? monthlyExpense,
    int? retainedEarnings,
    int? cumulativeDistribution,
    SubsidiaryOperatingPolicy? operatingPolicy,
    SubsidiaryLeadershipModel? leadershipModel,
    String? lastOperationsMonth,
    List<String>? history,
    String? sector,
    List<String>? products,
    int? innovation,
    int? operations,
    int? brandTrust,
    int? workforce,
    int? managementValueBps,
    String? lastManagementQuarter,
    List<ListedManagementDecisionRecord>? managementDecisions,
    bool? playerIsCeo,
    int? ceoStartDay,
    int? ceoPerformance,
    String? lastCeoActionMonth,
    String? lastShareholderQuestionMonth,
    String? lastShareholderLetterQuarter,
    int? acquiredControlDay,
    int? lostControlDay,
  }) => ListedCompanyGovernance(
    assetId: assetId,
    symbol: symbol ?? this.symbol,
    name: name ?? this.name,
    market: market ?? this.market,
    sharesOutstanding: math.max(0, sharesOutstanding ?? this.sharesOutstanding),
    ownedShares: math.max(0, ownedShares ?? this.ownedShares),
    tenderAcquiredShares: math.min(
      math.max(0, ownedShares ?? this.ownedShares),
      math.max(0, tenderAcquiredShares ?? this.tenderAcquiredShares),
    ),
    friendlyVotingPct: (friendlyVotingPct ?? this.friendlyVotingPct)
        .clamp(0, 49.99)
        .toDouble(),
    rivalVotingPct: (rivalVotingPct ?? this.rivalVotingPct)
        .clamp(0, 49.99)
        .toDouble(),
    boardSeats: (boardSeats ?? this.boardSeats).clamp(0, 7),
    lastSyncedDay: math.max(0, lastSyncedDay ?? this.lastSyncedDay),
    subsidiaryCash: math.max(0, subsidiaryCash ?? this.subsidiaryCash),
    subsidiaryDebt: math.max(0, subsidiaryDebt ?? this.subsidiaryDebt),
    monthlyRevenue: math.max(0, monthlyRevenue ?? this.monthlyRevenue),
    monthlyExpense: math.max(0, monthlyExpense ?? this.monthlyExpense),
    retainedEarnings: retainedEarnings ?? this.retainedEarnings,
    cumulativeDistribution: math.max(
      0,
      cumulativeDistribution ?? this.cumulativeDistribution,
    ),
    operatingPolicy: operatingPolicy ?? this.operatingPolicy,
    leadershipModel: leadershipModel ?? this.leadershipModel,
    lastOperationsMonth: lastOperationsMonth ?? this.lastOperationsMonth,
    history: history ?? this.history,
    sector: sector ?? this.sector,
    products: products ?? this.products,
    innovation: (innovation ?? this.innovation).clamp(0, 100),
    operations: (operations ?? this.operations).clamp(0, 100),
    brandTrust: (brandTrust ?? this.brandTrust).clamp(0, 100),
    workforce: (workforce ?? this.workforce).clamp(0, 100),
    managementValueBps: (managementValueBps ?? this.managementValueBps).clamp(
      -6500,
      15000,
    ),
    lastManagementQuarter: lastManagementQuarter ?? this.lastManagementQuarter,
    managementDecisions: managementDecisions ?? this.managementDecisions,
    playerIsCeo: playerIsCeo ?? this.playerIsCeo,
    ceoStartDay: ceoStartDay ?? this.ceoStartDay,
    ceoPerformance: (ceoPerformance ?? this.ceoPerformance).clamp(0, 100),
    lastCeoActionMonth: lastCeoActionMonth ?? this.lastCeoActionMonth,
    lastShareholderQuestionMonth:
        lastShareholderQuestionMonth ?? this.lastShareholderQuestionMonth,
    lastShareholderLetterQuarter:
        lastShareholderLetterQuarter ?? this.lastShareholderLetterQuarter,
    acquiredControlDay: acquiredControlDay ?? this.acquiredControlDay,
    lostControlDay: lostControlDay ?? this.lostControlDay,
  );

  Map<String, dynamic> toJson() => {
    'assetId': assetId,
    'symbol': symbol,
    'name': name,
    'market': market,
    'sharesOutstanding': sharesOutstanding,
    'ownedShares': ownedShares,
    'tenderAcquiredShares': tenderAcquiredShares,
    'friendlyVotingPct': friendlyVotingPct,
    'rivalVotingPct': rivalVotingPct,
    'boardSeats': boardSeats,
    'lastSyncedDay': lastSyncedDay,
    'subsidiaryCash': subsidiaryCash,
    'subsidiaryDebt': subsidiaryDebt,
    'monthlyRevenue': monthlyRevenue,
    'monthlyExpense': monthlyExpense,
    'retainedEarnings': retainedEarnings,
    'cumulativeDistribution': cumulativeDistribution,
    'operatingPolicy': operatingPolicy.name,
    'leadershipModel': leadershipModel.name,
    'lastOperationsMonth': lastOperationsMonth,
    'history': history,
    'sector': sector,
    'products': products,
    'innovation': innovation,
    'operations': operations,
    'brandTrust': brandTrust,
    'workforce': workforce,
    'managementValueBps': managementValueBps,
    'lastManagementQuarter': lastManagementQuarter,
    'managementDecisions': managementDecisions
        .map((decision) => decision.toJson())
        .toList(),
    'playerIsCeo': playerIsCeo,
    if (ceoStartDay != null) 'ceoStartDay': ceoStartDay,
    'ceoPerformance': ceoPerformance,
    'lastCeoActionMonth': lastCeoActionMonth,
    'lastShareholderQuestionMonth': lastShareholderQuestionMonth,
    'lastShareholderLetterQuarter': lastShareholderLetterQuarter,
    if (acquiredControlDay != null) 'acquiredControlDay': acquiredControlDay,
    if (lostControlDay != null) 'lostControlDay': lostControlDay,
  };

  factory ListedCompanyGovernance.fromJson(
    Map<String, dynamic> json,
  ) => ListedCompanyGovernance(
    assetId: json['assetId'] as String? ?? '',
    symbol: json['symbol'] as String? ?? '',
    name: json['name'] as String? ?? '',
    market: json['market'] as String? ?? '',
    sharesOutstanding: math.max(
      0,
      (json['sharesOutstanding'] as num?)?.toInt() ?? 0,
    ),
    ownedShares: math.max(0, (json['ownedShares'] as num?)?.toDouble() ?? 0),
    tenderAcquiredShares: math.max(
      0,
      (json['tenderAcquiredShares'] as num?)?.toDouble() ?? 0,
    ),
    friendlyVotingPct: ((json['friendlyVotingPct'] as num?)?.toDouble() ?? 0)
        .clamp(0, 49.99)
        .toDouble(),
    rivalVotingPct: ((json['rivalVotingPct'] as num?)?.toDouble() ?? 0)
        .clamp(0, 49.99)
        .toDouble(),
    boardSeats: ((json['boardSeats'] as num?)?.toInt() ?? 0).clamp(0, 7),
    lastSyncedDay: math.max(0, (json['lastSyncedDay'] as num?)?.toInt() ?? 0),
    subsidiaryCash: math.max(0, (json['subsidiaryCash'] as num?)?.toInt() ?? 0),
    subsidiaryDebt: math.max(0, (json['subsidiaryDebt'] as num?)?.toInt() ?? 0),
    monthlyRevenue: math.max(0, (json['monthlyRevenue'] as num?)?.toInt() ?? 0),
    monthlyExpense: math.max(0, (json['monthlyExpense'] as num?)?.toInt() ?? 0),
    retainedEarnings: (json['retainedEarnings'] as num?)?.toInt() ?? 0,
    cumulativeDistribution: math.max(
      0,
      (json['cumulativeDistribution'] as num?)?.toInt() ?? 0,
    ),
    operatingPolicy: SubsidiaryOperatingPolicy.values.firstWhere(
      (value) => value.name == json['operatingPolicy'],
      orElse: () => SubsidiaryOperatingPolicy.growth,
    ),
    leadershipModel: SubsidiaryLeadershipModel.values.firstWhere(
      (value) => value.name == json['leadershipModel'],
      orElse: () => SubsidiaryLeadershipModel.professionalCeo,
    ),
    lastOperationsMonth: json['lastOperationsMonth'] as String? ?? '',
    history: ((json['history'] as List?) ?? const [])
        .whereType<String>()
        .toList(),
    sector: json['sector'] as String? ?? '기타',
    products: ((json['products'] as List?) ?? const [])
        .whereType<String>()
        .toList(),
    innovation: ((json['innovation'] as num?)?.toInt() ?? 50).clamp(0, 100),
    operations: ((json['operations'] as num?)?.toInt() ?? 50).clamp(0, 100),
    brandTrust: ((json['brandTrust'] as num?)?.toInt() ?? 50).clamp(0, 100),
    workforce: ((json['workforce'] as num?)?.toInt() ?? 50).clamp(0, 100),
    managementValueBps: ((json['managementValueBps'] as num?)?.toInt() ?? 0)
        .clamp(-6500, 15000),
    lastManagementQuarter: json['lastManagementQuarter'] as String? ?? '',
    managementDecisions: ((json['managementDecisions'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => ListedManagementDecisionRecord.fromJson(
            item.cast<String, dynamic>(),
          ),
        )
        .toList(),
    playerIsCeo: json['playerIsCeo'] == true,
    ceoStartDay: (json['ceoStartDay'] as num?)?.toInt(),
    ceoPerformance: ((json['ceoPerformance'] as num?)?.toInt() ?? 50).clamp(
      0,
      100,
    ),
    lastCeoActionMonth: json['lastCeoActionMonth'] as String? ?? '',
    lastShareholderQuestionMonth:
        json['lastShareholderQuestionMonth'] as String? ?? '',
    lastShareholderLetterQuarter:
        json['lastShareholderLetterQuarter'] as String? ?? '',
    acquiredControlDay: (json['acquiredControlDay'] as num?)?.toInt(),
    lostControlDay: (json['lostControlDay'] as num?)?.toInt(),
  );
}

class ShareholderAgenda {
  const ShareholderAgenda({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.baseSupportPct,
    required this.requiredApprovalPct,
    required this.proposedByPlayer,
    this.vote,
    this.finalSupportPct,
    this.passed,
  });

  final String id;
  final ShareholderAgendaType type;
  final String title;
  final String description;
  final double baseSupportPct;
  final double requiredApprovalPct;
  final bool proposedByPlayer;
  final ShareholderVoteChoice? vote;
  final double? finalSupportPct;
  final bool? passed;

  ShareholderAgenda copyWith({
    ShareholderVoteChoice? vote,
    double? finalSupportPct,
    bool? passed,
  }) => ShareholderAgenda(
    id: id,
    type: type,
    title: title,
    description: description,
    baseSupportPct: baseSupportPct,
    requiredApprovalPct: requiredApprovalPct,
    proposedByPlayer: proposedByPlayer,
    vote: vote ?? this.vote,
    finalSupportPct: finalSupportPct ?? this.finalSupportPct,
    passed: passed ?? this.passed,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'description': description,
    'baseSupportPct': baseSupportPct,
    'requiredApprovalPct': requiredApprovalPct,
    'proposedByPlayer': proposedByPlayer,
    if (vote != null) 'vote': vote!.name,
    if (finalSupportPct != null) 'finalSupportPct': finalSupportPct,
    if (passed != null) 'passed': passed,
  };

  factory ShareholderAgenda.fromJson(Map<String, dynamic> json) =>
      ShareholderAgenda(
        id: json['id'] as String? ?? '',
        type: ShareholderAgendaType.values.firstWhere(
          (value) => value.name == json['type'],
          orElse: () => ShareholderAgendaType.strategy,
        ),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        baseSupportPct: ((json['baseSupportPct'] as num?)?.toDouble() ?? 50)
            .clamp(0, 100)
            .toDouble(),
        requiredApprovalPct:
            ((json['requiredApprovalPct'] as num?)?.toDouble() ?? 50)
                .clamp(0, 100)
                .toDouble(),
        proposedByPlayer: json['proposedByPlayer'] == true,
        vote: ShareholderVoteChoice.values
            .cast<ShareholderVoteChoice?>()
            .firstWhere(
              (value) => value?.name == json['vote'],
              orElse: () => null,
            ),
        finalSupportPct: (json['finalSupportPct'] as num?)?.toDouble(),
        passed: json['passed'] as bool?,
      );
}

class ShareholderMeeting {
  const ShareholderMeeting({
    required this.id,
    required this.assetId,
    required this.year,
    required this.heldDay,
    required this.deadlineDay,
    required this.extraordinary,
    required this.status,
    required this.attended,
    required this.agendas,
  });

  final String id;
  final String assetId;
  final int year;
  final int heldDay;
  final int deadlineDay;
  final bool extraordinary;
  final ShareholderMeetingStatus status;
  final bool attended;
  final List<ShareholderAgenda> agendas;

  bool get hasUnvotedAgenda => agendas.any((agenda) => agenda.vote == null);

  ShareholderMeeting copyWith({
    ShareholderMeetingStatus? status,
    bool? attended,
    List<ShareholderAgenda>? agendas,
  }) => ShareholderMeeting(
    id: id,
    assetId: assetId,
    year: year,
    heldDay: heldDay,
    deadlineDay: deadlineDay,
    extraordinary: extraordinary,
    status: status ?? this.status,
    attended: attended ?? this.attended,
    agendas: agendas ?? this.agendas,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'assetId': assetId,
    'year': year,
    'heldDay': heldDay,
    'deadlineDay': deadlineDay,
    'extraordinary': extraordinary,
    'status': status.name,
    'attended': attended,
    'agendas': agendas.map((agenda) => agenda.toJson()).toList(),
  };

  factory ShareholderMeeting.fromJson(Map<String, dynamic> json) =>
      ShareholderMeeting(
        id: json['id'] as String? ?? '',
        assetId: json['assetId'] as String? ?? '',
        year: (json['year'] as num?)?.toInt() ?? 2000,
        heldDay: math.max(1, (json['heldDay'] as num?)?.toInt() ?? 1),
        deadlineDay: math.max(1, (json['deadlineDay'] as num?)?.toInt() ?? 1),
        extraordinary: json['extraordinary'] == true,
        status: ShareholderMeetingStatus.values.firstWhere(
          (value) => value.name == json['status'],
          orElse: () => ShareholderMeetingStatus.scheduled,
        ),
        attended: json['attended'] == true,
        agendas: ((json['agendas'] as List?) ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  ShareholderAgenda.fromJson(item.cast<String, dynamic>()),
            )
            .toList(),
      );
}

class ShareholderGovernanceState {
  const ShareholderGovernanceState({
    this.companies = const <String, ListedCompanyGovernance>{},
    this.meetings = const <ShareholderMeeting>[],
    this.corporateActions = const <ListedCorporateActionRecord>[],
  });

  final Map<String, ListedCompanyGovernance> companies;
  final List<ShareholderMeeting> meetings;
  final List<ListedCorporateActionRecord> corporateActions;

  ListedCompanyGovernance? companyById(String assetId) => companies[assetId];

  double priceMultiplierFor(String assetId, int day) =>
      companies[assetId]?.priceMultiplierAt(day) ?? 1;

  double adjustedPrice(String assetId, int day, double rawPrice) =>
      rawPrice * priceMultiplierFor(assetId, day);

  List<ListedCompanyGovernance> get controlledCompanies => companies.values
      .where((company) => company.isControlled)
      .toList(growable: false);

  List<ShareholderMeeting> meetingsFor(String assetId) => meetings
      .where((meeting) => meeting.assetId == assetId)
      .toList(growable: false);

  List<ListedCorporateActionRecord> corporateActionsFor(String assetId) =>
      corporateActions
          .where((action) => action.involves(assetId))
          .toList(growable: false);

  ShareholderGovernanceState copyWith({
    Map<String, ListedCompanyGovernance>? companies,
    List<ShareholderMeeting>? meetings,
    List<ListedCorporateActionRecord>? corporateActions,
  }) => ShareholderGovernanceState(
    companies: companies ?? this.companies,
    meetings: meetings ?? this.meetings,
    corporateActions: corporateActions ?? this.corporateActions,
  );

  Map<String, dynamic> toJson() => {
    'companies': {
      for (final entry in companies.entries) entry.key: entry.value.toJson(),
    },
    'meetings': meetings.map((meeting) => meeting.toJson()).toList(),
    'corporateActions': corporateActions
        .map((action) => action.toJson())
        .toList(),
  };

  factory ShareholderGovernanceState.fromJson(Map<String, dynamic> json) {
    final rawCompanies = (json['companies'] as Map?) ?? const {};
    return ShareholderGovernanceState(
      companies: <String, ListedCompanyGovernance>{
        for (final entry in rawCompanies.entries)
          if (entry.value is Map)
            entry.key.toString(): ListedCompanyGovernance.fromJson(
              (entry.value as Map).cast<String, dynamic>(),
            ),
      },
      meetings: ((json['meetings'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => ShareholderMeeting.fromJson(item.cast<String, dynamic>()),
          )
          .toList(),
      corporateActions: ((json['corporateActions'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => ListedCorporateActionRecord.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }
}
