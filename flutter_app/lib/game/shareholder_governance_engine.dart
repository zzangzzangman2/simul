import 'dart:math' as math;

import 'game_state.dart';
import 'listed_company_management.dart';
import 'market_data.dart';
import 'shareholder_governance.dart';
import 'stable_hash.dart';

class ShareholderGovernanceActionResult {
  const ShareholderGovernanceActionResult({
    required this.state,
    required this.success,
    required this.message,
  });

  final GameState state;
  final bool success;
  final String message;
}

class _CeoDirectivePlan {
  const _CeoDirectivePlan({
    required this.costRate,
    required this.durationDays,
    required this.successChancePct,
    required this.revenueDeltaBps,
    required this.expenseDeltaBps,
    required this.immediatePriceImpactBps,
    required this.successPriceImpactBps,
    required this.failurePriceImpactBps,
    required this.innovationDelta,
    required this.operationsDelta,
    required this.brandDelta,
    required this.workforceDelta,
  });

  final double costRate;
  final int durationDays;
  final double successChancePct;
  final int revenueDeltaBps;
  final int expenseDeltaBps;
  final int immediatePriceImpactBps;
  final int successPriceImpactBps;
  final int failurePriceImpactBps;
  final int innovationDelta;
  final int operationsDelta;
  final int brandDelta;
  final int workforceDelta;
}

class ShareholderGovernanceEngine {
  const ShareholderGovernanceEngine();

  GameState sync(GameState state, FictionalMarketUniverse universe) {
    final companies = <String, ListedCompanyGovernance>{
      ...state.shareholderGovernance.companies,
    };
    final positionUnits = <String, double>{};
    for (final position in state.positions) {
      positionUnits.update(
        position.assetId,
        (value) => value + position.units,
        ifAbsent: () => position.units,
      );
    }

    for (final asset in universe.assets) {
      final ownedShares = math.max(0.0, positionUnits[asset.id] ?? 0);
      final current = companies[asset.id];
      if (ownedShares <= 0 && current == null) continue;
      final outstanding =
          asset.sharesOutstandingAtOrBefore(state.currentDate) ??
          current?.sharesOutstanding ??
          asset.initialSharesOutstanding;
      final corporateActionScale =
          current != null && current.sharesOutstanding > 0
          ? outstanding / current.sharesOutstanding
          : 1.0;
      final tenderAcquiredShares = math.min(
        ownedShares,
        math.max(
          0.0,
          (current?.tenderAcquiredShares ?? 0) * corporateActionScale,
        ),
      );
      final financial = asset.financialAtOrBefore(state.currentDate);
      final initialRevenue = math.max(
        100000,
        financial == null ? outstanding ~/ 4 : financial.revenue ~/ 3,
      );
      final initialExpense = math.max(
        0,
        financial == null
            ? (initialRevenue * 0.88).round()
            : (financial.revenue - financial.operatingProfit) ~/ 3,
      );
      final rival =
          current?.rivalVotingPct ??
          (5 +
                  stableHash31('${state.simulationSeed}:${asset.id}:rival') %
                      1800) /
              100;
      final managementSeed = stableHash31(
        '${state.simulationSeed}:${asset.id}:management-baseline',
      );
      final base =
          current ??
          ListedCompanyGovernance(
            assetId: asset.id,
            symbol: asset.symbol,
            name: asset.name,
            market: asset.market,
            sharesOutstanding: outstanding,
            ownedShares: ownedShares,
            friendlyVotingPct: 0,
            rivalVotingPct: rival,
            boardSeats: 0,
            lastSyncedDay: state.day,
            subsidiaryCash: math.max(0, financial?.cash ?? initialRevenue * 2),
            subsidiaryDebt: math.max(0, financial?.debt ?? initialRevenue),
            monthlyRevenue: initialRevenue,
            monthlyExpense: initialExpense,
            retainedEarnings: 0,
            cumulativeDistribution: 0,
            operatingPolicy: SubsidiaryOperatingPolicy.growth,
            leadershipModel: SubsidiaryLeadershipModel.professionalCeo,
            lastOperationsMonth: '',
            history: const <String>[],
            sector: asset.sector,
            products: asset.products,
            innovation: 42 + managementSeed % 25,
            operations: 42 + (managementSeed ~/ 7) % 25,
            brandTrust: 42 + (managementSeed ~/ 13) % 25,
            workforce: 42 + (managementSeed ~/ 19) % 25,
          );
      final beforeControl = current?.isControlled ?? false;
      var updated = base.copyWith(
        symbol: asset.symbol,
        name: asset.name,
        market: asset.market,
        sharesOutstanding: outstanding,
        ownedShares: ownedShares,
        tenderAcquiredShares: tenderAcquiredShares,
        rivalVotingPct: rival,
        lastSyncedDay: state.day,
        sector: asset.sector,
        products: asset.products,
      );
      final entitlement = _boardSeatEntitlement(updated);
      updated = updated.copyWith(
        boardSeats: updated.ownershipPct < 3
            ? 0
            : math.max(updated.boardSeats, entitlement),
      );
      if (!beforeControl && updated.isControlled) {
        updated = updated.copyWith(
          acquiredControlDay: state.day,
          boardSeats: math.max(4, updated.boardSeats),
          history: _appendHistory(
            updated.history,
            '${_dateKey(state.currentDate)} 경영권 확보 · 의결권 ${updated.votingPowerPct.toStringAsFixed(2)}%',
          ),
        );
      } else if (beforeControl && !updated.isControlled) {
        updated = updated.copyWith(
          lostControlDay: state.day,
          boardSeats: entitlement,
          playerIsCeo: false,
          leadershipModel: SubsidiaryLeadershipModel.professionalCeo,
          history: _appendHistory(
            updated.history,
            '${_dateKey(state.currentDate)} 경영권 상실 · 의결권 ${updated.votingPowerPct.toStringAsFixed(2)}%',
          ),
        );
      }
      if (!updated.isControlled && updated.playerIsCeo) {
        updated = updated.copyWith(
          playerIsCeo: false,
          leadershipModel: SubsidiaryLeadershipModel.professionalCeo,
        );
      }
      companies[asset.id] = updated;
    }

    return state.copyWith(
      shareholderGovernance: state.shareholderGovernance.copyWith(
        companies: Map<String, ListedCompanyGovernance>.unmodifiable(companies),
      ),
    );
  }

  GameState processDay(GameState state, FictionalMarketUniverse universe) {
    var next = sync(state, universe);
    next = _ensureRegularMeetings(next);
    next = _updateMeetingWindows(next);
    next = _resolveManagementDecisions(next);
    next = _resolveCorporateActions(next);
    next = _settleControlledCompanies(next);
    return next;
  }

  ListedManagementAgenda? managementAgendaFor(
    GameState state,
    FictionalMarketAsset asset,
  ) {
    final company = state.shareholderGovernance.companyById(asset.id);
    if (company == null || !company.isControlled) return null;
    return ListedCompanyManagementCatalog.agendaFor(
      asset,
      company,
      state.currentDate,
    );
  }

  ShareholderGovernanceActionResult executeManagementDecision(
    GameState state, {
    required FictionalMarketAsset asset,
    required String optionId,
  }) {
    final company = state.shareholderGovernance.companyById(asset.id);
    if (company == null || !company.isControlled) {
      return _failure(state, '경영권을 확보한 회사만 이사회 결정을 내릴 수 있습니다.');
    }
    final agenda = ListedCompanyManagementCatalog.agendaFor(
      asset,
      company,
      state.currentDate,
    );
    if (company.lastManagementQuarter == agenda.quarterKey) {
      return _failure(state, '이번 분기 핵심 경영안건은 이미 결정했습니다.');
    }
    final matches = agenda.options.where((item) => item.id == optionId);
    final option = matches.isEmpty ? null : matches.first;
    if (option == null) return _failure(state, '선택한 경영안을 찾을 수 없습니다.');

    final cashUsed = math.min(company.subsidiaryCash, option.cashCost);
    final borrowed = math.max(0, option.cashCost - cashUsed);
    final record = ListedManagementDecisionRecord(
      id: '${agenda.id}-${option.id}-${state.day}',
      agendaId: agenda.id,
      optionId: option.id,
      title: agenda.title,
      optionLabel: option.label,
      summary: option.description,
      decisionDay: state.day,
      completionDay: math.min(
        GameState.maxCampaignDay,
        state.day + option.durationDays,
      ),
      cashCost: option.cashCost,
      revenueDeltaBps: option.revenueDeltaBps,
      expenseDeltaBps: option.expenseDeltaBps,
      immediatePriceImpactBps: option.immediatePriceImpactBps,
      successPriceImpactBps: option.successPriceImpactBps,
      failurePriceImpactBps: option.failurePriceImpactBps,
      innovationDelta: option.innovationDelta,
      operationsDelta: option.operationsDelta,
      brandDelta: option.brandDelta,
      workforceDelta: option.workforceDelta,
      successChancePct: option.successChancePct,
    );
    final decisions = <ListedManagementDecisionRecord>[
      ...company.managementDecisions,
      record,
    ];
    final updated = company.copyWith(
      subsidiaryCash: company.subsidiaryCash - cashUsed,
      subsidiaryDebt: company.subsidiaryDebt + borrowed,
      lastManagementQuarter: agenda.quarterKey,
      managementDecisions: decisions.length <= 256
          ? decisions
          : decisions.sublist(decisions.length - 256),
      history: _appendHistory(
        company.history,
        '${_dateKey(state.currentDate)} ${agenda.title}: ${option.label} · '
        '투자 ${_won(option.cashCost)}',
      ),
    );
    final reaction = option.immediatePriceImpactBps / 100;
    return ShareholderGovernanceActionResult(
      state: _withCompany(state, updated),
      success: true,
      message:
          '${company.name} 이사회가 「${option.label}」을 의결했습니다. '
          '다음 거래일 시장반응 ${reaction >= 0 ? '+' : ''}${reaction.toStringAsFixed(1)}% · '
          '${option.durationDays}일 뒤 성과가 확정됩니다.',
    );
  }

  ShareholderGovernanceActionResult askManagementQuestion(
    GameState state,
    String assetId,
  ) {
    final company = state.shareholderGovernance.companyById(assetId);
    if (company == null ||
        !company.rights.contains(ShareholderRight.submitQuestion)) {
      return _failure(state, '주식을 1주 이상 보유해야 경영진에게 질의할 수 있습니다.');
    }
    final month = _monthKey(state.currentDate);
    if (company.lastShareholderQuestionMonth == month) {
      return _failure(state, '이번 달 경영진 서면질의는 이미 답변을 받았습니다.');
    }
    final metrics = <String, int>{
      '기술·상품 경쟁력': company.innovation,
      '운영 효율': company.operations,
      '고객 신뢰': company.brandTrust,
      '조직 건강도': company.workforce,
    };
    final weakest = metrics.entries.reduce(
      (left, right) => left.value <= right.value ? left : right,
    );
    final marketEvent = _completedMarketEvent(
      state,
      id: 'question-$assetId-$month',
      title: '경영진 서면질의 답변',
      summary: '${weakest.key} 개선계획을 공개해 공시 투명성이 높아졌습니다.',
      priceImpactBps: 15,
    );
    final updated = company.copyWith(
      lastShareholderQuestionMonth: month,
      brandTrust: company.brandTrust + 1,
      managementValueBps: company.managementValueBps + 15,
      managementDecisions: _appendDecision(
        company.managementDecisions,
        marketEvent,
      ),
      history: _appendHistory(
        company.history,
        '${_dateKey(state.currentDate)} 주주 서면질의 · ${weakest.key} 개선계획 공개',
      ),
    );
    return ShareholderGovernanceActionResult(
      state: _withCompany(state, updated),
      success: true,
      message:
          '${company.name} 경영진이 ${weakest.key}(${weakest.value})를 최우선 개선과제로 답변했습니다. 공시 투명성이 높아졌습니다.',
    );
  }

  ShareholderGovernanceActionResult publishShareholderLetter(
    GameState state, {
    required String assetId,
    required int marketCap,
  }) {
    final company = state.shareholderGovernance.companyById(assetId);
    if (company == null ||
        !company.rights.contains(ShareholderRight.publishShareholderLetter)) {
      return _failure(state, '지분 5% 이상부터 공개 주주서한을 발표할 수 있습니다.');
    }
    final quarter = ListedCompanyManagementCatalog.quarterKey(
      state.currentDate,
    );
    if (company.lastShareholderLetterQuarter == quarter) {
      return _failure(state, '이번 분기에는 이미 공개 주주서한을 발표했습니다.');
    }
    final cost = math.max(100000, (math.max(0, marketCap) * 0.00012).round());
    if (state.bankCash < cost) {
      return _failure(state, '주주행동 자문·공시 비용 ${_won(cost)}이 부족합니다.');
    }
    final roll = stableHash31(
      '${state.simulationSeed}:$assetId:shareholder-letter:$quarter',
    );
    final supportGain = 1.5 + (roll % 251) / 100;
    final priceImpact = company.operations + company.brandTrust >= 110
        ? 90
        : 35;
    final ceiling = math.max(0.0, 49.99 - company.ownershipPct);
    final marketEvent = _completedMarketEvent(
      state,
      id: 'shareholder-letter-$assetId-$quarter',
      title: '공개 주주서한',
      summary: '지배구조와 사업개선 요구가 공개돼 시장과 다른 주주의 평가가 바뀌었습니다.',
      priceImpactBps: priceImpact,
    );
    final updated = company.copyWith(
      friendlyVotingPct: math.min(
        ceiling,
        company.friendlyVotingPct + supportGain,
      ),
      managementValueBps: company.managementValueBps + priceImpact,
      managementDecisions: _appendDecision(
        company.managementDecisions,
        marketEvent,
      ),
      lastShareholderLetterQuarter: quarter,
      history: _appendHistory(
        company.history,
        '${_dateKey(state.currentDate)} 공개 주주서한 · 우호 의결권 +${supportGain.toStringAsFixed(2)}%p',
      ),
    );
    final sourceId = 'shareholder-letter-$assetId-$quarter';
    final next = state.copyWith(
      cash: state.cash - cost,
      ledger: <LedgerEntry>[
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -cost,
          account: 'company_bank',
          counterAccount: 'shareholder_campaign_expense',
          description: '${company.name} 공개 주주서한·주주행동 비용',
          sourceId: sourceId,
          assetId: assetId,
        ),
      ],
    );
    return ShareholderGovernanceActionResult(
      state: _withCompany(next, updated),
      success: true,
      message:
          '공개 주주서한 발표 · 우호 의결권 +${supportGain.toStringAsFixed(2)}%p · 시장평가 +${(priceImpact / 100).toStringAsFixed(1)}%',
    );
  }

  ShareholderGovernanceActionResult appointPlayerAsCeo(
    GameState state,
    String assetId,
  ) {
    final company = state.shareholderGovernance.companyById(assetId);
    if (company == null ||
        !company.rights.contains(ShareholderRight.appointCeo) ||
        company.boardSeats < 4) {
      return _failure(state, '의결권 과반과 이사회 과반을 확보해야 CEO로 취임할 수 있습니다.');
    }
    if (company.playerIsCeo) return _failure(state, '이미 이 회사의 CEO입니다.');
    final marketEvent = _completedMarketEvent(
      state,
      id: 'ceo-appointment-$assetId-${state.day}',
      title: '대표이사 CEO 선임',
      summary: '지배주주의 직접 책임경영 선언이 공시됐습니다.',
      priceImpactBps: 120,
    );
    final updated = company.copyWith(
      playerIsCeo: true,
      ceoStartDay: state.day,
      leadershipModel: SubsidiaryLeadershipModel.founderLed,
      managementValueBps: company.managementValueBps + 120,
      managementDecisions: _appendDecision(
        company.managementDecisions,
        marketEvent,
      ),
      history: _appendHistory(
        company.history,
        '${_dateKey(state.currentDate)} 플레이어 CEO 취임 · 책임경영 선언',
      ),
    );
    return ShareholderGovernanceActionResult(
      state: _withCompany(state, updated),
      success: true,
      message: '${company.name} 이사회가 플레이어를 대표이사 CEO로 선임했습니다.',
    );
  }

  ShareholderGovernanceActionResult stepDownAsCeo(
    GameState state,
    String assetId,
  ) {
    final company = state.shareholderGovernance.companyById(assetId);
    if (company == null || !company.playerIsCeo) {
      return _failure(state, '현재 플레이어가 CEO인 회사가 아닙니다.');
    }
    final marketEvent = _completedMarketEvent(
      state,
      id: 'ceo-resignation-$assetId-${state.day}',
      title: '대표이사 CEO 사임',
      summary: 'CEO 교체와 전문경영인 선임이 공시됐습니다.',
      priceImpactBps: -60,
    );
    final updated = company.copyWith(
      playerIsCeo: false,
      leadershipModel: SubsidiaryLeadershipModel.professionalCeo,
      managementValueBps: company.managementValueBps - 60,
      managementDecisions: _appendDecision(
        company.managementDecisions,
        marketEvent,
      ),
      history: _appendHistory(
        company.history,
        '${_dateKey(state.currentDate)} CEO 사임 · 전문경영인 체제 전환',
      ),
    );
    return ShareholderGovernanceActionResult(
      state: _withCompany(state, updated),
      success: true,
      message: '${company.name} CEO에서 물러나고 전문경영인을 선임했습니다.',
    );
  }

  ShareholderGovernanceActionResult executeCeoDirective(
    GameState state, {
    required String assetId,
    required ListedCeoDirective directive,
  }) {
    final company = state.shareholderGovernance.companyById(assetId);
    if (company == null || !company.isControlled || !company.playerIsCeo) {
      return _failure(state, '이 회사의 CEO로 취임한 뒤 직접 집행할 수 있습니다.');
    }
    final month = _monthKey(state.currentDate);
    if (company.lastCeoActionMonth == month) {
      return _failure(state, '이번 달 CEO 핵심 집행은 이미 완료했습니다.');
    }

    if (directive == ListedCeoDirective.debtReduction) {
      final repayment = math.min(
        company.subsidiaryDebt,
        math.max(0, (company.subsidiaryCash * 0.25).round()),
      );
      if (repayment <= 0) return _failure(state, '상환할 부채 또는 사용할 회사 현금이 없습니다.');
      final record = _completedCeoDecision(
        state,
        directive,
        cashCost: repayment,
        priceImpactBps: 80,
        outcome: '차입금 ${_won(repayment)}을 상환해 이자와 재무위험을 낮췄습니다.',
      );
      final updated = company.copyWith(
        subsidiaryCash: company.subsidiaryCash - repayment,
        subsidiaryDebt: company.subsidiaryDebt - repayment,
        operations: company.operations + 2,
        managementValueBps: company.managementValueBps + 80,
        lastCeoActionMonth: month,
        ceoPerformance: company.ceoPerformance + 2,
        managementDecisions: _appendDecision(
          company.managementDecisions,
          record,
        ),
        history: _appendHistory(
          company.history,
          '${_dateKey(state.currentDate)} CEO 지시: ${directive.label} ${_won(repayment)}',
        ),
      );
      return ShareholderGovernanceActionResult(
        state: _withCompany(state, updated),
        success: true,
        message: record.outcome,
      );
    }

    if (directive == ListedCeoDirective.shareholderReturn) {
      final grossDividend = math.min(
        (company.subsidiaryCash * 0.15).round(),
        (company.monthlyRevenue * 0.08).round(),
      );
      if (grossDividend <= 0) return _failure(state, '특별배당에 사용할 회사 현금이 없습니다.');
      final playerDividend = (grossDividend * company.ownershipPct / 100)
          .round();
      final sourceId = 'ceo-special-dividend-$assetId-$month';
      final record = _completedCeoDecision(
        state,
        directive,
        cashCost: grossDividend,
        priceImpactBps: 110,
        outcome:
            '특별배당 총 ${_won(grossDividend)}을 결의해 플레이어 몫 ${_won(playerDividend)}을 지급했습니다.',
      );
      final updated = company.copyWith(
        subsidiaryCash: company.subsidiaryCash - grossDividend,
        cumulativeDistribution: company.cumulativeDistribution + playerDividend,
        managementValueBps: company.managementValueBps + 110,
        lastCeoActionMonth: month,
        ceoPerformance: company.ceoPerformance + 1,
        managementDecisions: _appendDecision(
          company.managementDecisions,
          record,
        ),
        history: _appendHistory(
          company.history,
          '${_dateKey(state.currentDate)} CEO 특별배당 ${_won(grossDividend)}',
        ),
      );
      final next = state.copyWith(
        cash: state.cash + playerDividend,
        ledger: <LedgerEntry>[
          ...state.ledger,
          if (playerDividend > 0)
            LedgerEntry(
              id: sourceId,
              day: state.day,
              amount: playerDividend,
              account: 'company_bank',
              counterAccount: 'subsidiary_dividend_income',
              description: '${company.name} CEO 특별배당',
              sourceId: sourceId,
              assetId: assetId,
            ),
        ],
      );
      return ShareholderGovernanceActionResult(
        state: _withCompany(next, updated),
        success: true,
        message: record.outcome,
      );
    }

    final plan = _ceoDirectivePlan(directive);
    final cost = math.max(
      100000,
      (company.monthlyRevenue * plan.costRate).round(),
    );
    final cashUsed = math.min(company.subsidiaryCash, cost);
    final borrowed = math.max(0, cost - cashUsed);
    final record = ListedManagementDecisionRecord(
      id: 'ceo-$assetId-${directive.name}-${state.day}',
      agendaId: 'ceo:${directive.name}:$month',
      optionId: directive.name,
      title: 'CEO 월간 집행',
      optionLabel: directive.label,
      summary: directive.description,
      decisionDay: state.day,
      completionDay: math.min(
        GameState.maxCampaignDay,
        state.day + plan.durationDays,
      ),
      cashCost: cost,
      revenueDeltaBps: plan.revenueDeltaBps,
      expenseDeltaBps: plan.expenseDeltaBps,
      immediatePriceImpactBps: plan.immediatePriceImpactBps,
      successPriceImpactBps: plan.successPriceImpactBps,
      failurePriceImpactBps: plan.failurePriceImpactBps,
      innovationDelta: plan.innovationDelta,
      operationsDelta: plan.operationsDelta,
      brandDelta: plan.brandDelta,
      workforceDelta: plan.workforceDelta,
      successChancePct: plan.successChancePct,
    );
    final updated = company.copyWith(
      subsidiaryCash: company.subsidiaryCash - cashUsed,
      subsidiaryDebt: company.subsidiaryDebt + borrowed,
      lastCeoActionMonth: month,
      managementDecisions: _appendDecision(company.managementDecisions, record),
      history: _appendHistory(
        company.history,
        '${_dateKey(state.currentDate)} CEO 지시: ${directive.label} · 투자 ${_won(cost)}',
      ),
    );
    return ShareholderGovernanceActionResult(
      state: _withCompany(state, updated),
      success: true,
      message:
          '${directive.label} 집행을 시작했습니다. 투자 ${_won(cost)}${borrowed > 0 ? ' · 신규차입 ${_won(borrowed)}' : ''} · ${plan.durationDays}일 뒤 성과가 확정됩니다.',
    );
  }

  ShareholderGovernanceActionResult startCorporateAction(
    GameState state, {
    required String leadAssetId,
    required ListedCorporateActionType type,
    String partnerAssetId = '',
    ListedMergerStructure mergerStructure =
        ListedMergerStructure.businessCombination,
  }) {
    final lead = state.shareholderGovernance.companyById(leadAssetId);
    if (lead == null || !lead.isControlled || !lead.playerIsCeo) {
      return _failure(state, '지배회사의 CEO로 취임해야 기업재편을 추진할 수 있습니다.');
    }
    final requiresSpecialResolution =
        type != ListedCorporateActionType.jointVenture;
    if (requiresSpecialResolution &&
        !lead.rights.contains(ShareholderRight.approveMajorRestructuring)) {
      return _failure(state, '합병·분할·핵심자산 재편은 의결권 66.67% 이상이 필요합니다.');
    }
    ListedCompanyGovernance? partner;
    if (type == ListedCorporateActionType.merger ||
        type == ListedCorporateActionType.jointVenture) {
      partner = state.shareholderGovernance.companyById(partnerAssetId);
      if (partner == null ||
          partner.assetId == leadAssetId ||
          !partner.isControlled) {
        return _failure(state, '함께 지배하고 있는 다른 회사를 거래 상대로 선택해야 합니다.');
      }
      if (type == ListedCorporateActionType.merger &&
          !partner.rights.contains(
            ShareholderRight.approveMajorRestructuring,
          )) {
        return _failure(state, '합병 상대 회사도 의결권 66.67% 이상을 확보해야 합니다.');
      }
    }
    final hasActive = state.shareholderGovernance.corporateActions.any(
      (action) =>
          action.isExecuting &&
          (action.involves(leadAssetId) ||
              (partner != null && action.involves(partner.assetId))),
    );
    if (hasActive) return _failure(state, '관련 회사에서 이미 기업재편을 진행하고 있습니다.');

    final duration = switch (type) {
      ListedCorporateActionType.merger => 120,
      ListedCorporateActionType.jointVenture => 75,
      ListedCorporateActionType.spinOff => 90,
      ListedCorporateActionType.assetSale => 60,
    };
    final successChance = switch (type) {
      ListedCorporateActionType.merger => 72.0,
      ListedCorporateActionType.jointVenture => 82.0,
      ListedCorporateActionType.spinOff => 78.0,
      ListedCorporateActionType.assetSale => 86.0,
    };
    final immediateImpact = switch (type) {
      ListedCorporateActionType.merger => 260,
      ListedCorporateActionType.jointVenture => 130,
      ListedCorporateActionType.spinOff => 80,
      ListedCorporateActionType.assetSale => 40,
    };
    final successImpact = switch (type) {
      ListedCorporateActionType.merger => 900,
      ListedCorporateActionType.jointVenture => 420,
      ListedCorporateActionType.spinOff => 350,
      ListedCorporateActionType.assetSale => 240,
    };
    final failureImpact = switch (type) {
      ListedCorporateActionType.merger => -1100,
      ListedCorporateActionType.jointVenture => -420,
      ListedCorporateActionType.spinOff => -520,
      ListedCorporateActionType.assetSale => -300,
    };
    final revenueBase = lead.monthlyRevenue + (partner?.monthlyRevenue ?? 0);
    final costRate = switch (type) {
      ListedCorporateActionType.merger => 0.12,
      ListedCorporateActionType.jointVenture => 0.07,
      ListedCorporateActionType.spinOff => 0.05,
      ListedCorporateActionType.assetSale => 0.01,
    };
    final cost = math.max(100000, (revenueBase * costRate).round());
    final cashUsed = math.min(lead.subsidiaryCash, cost);
    final borrowed = math.max(0, cost - cashUsed);
    final strategy = type == ListedCorporateActionType.merger
        ? mergerStructure.label
        : switch (type) {
            ListedCorporateActionType.jointVenture => '공동출자·공동경영',
            ListedCorporateActionType.spinOff => '독립 책임경영',
            ListedCorporateActionType.assetSale => '비핵심 현금화',
            ListedCorporateActionType.merger => mergerStructure.label,
          };
    final title = partner == null
        ? '${lead.name} ${type.label}'
        : '${lead.name}·${partner.name} ${type.label}';
    final action = ListedCorporateActionRecord(
      id: 'corporate-${type.name}-$leadAssetId-${partner?.assetId ?? 'none'}-${state.day}',
      type: type,
      leadAssetId: leadAssetId,
      leadName: lead.name,
      partnerAssetId: partner?.assetId ?? '',
      partnerName: partner?.name ?? '',
      strategy: strategy,
      announcedDay: state.day,
      completionDay: math.min(GameState.maxCampaignDay, state.day + duration),
      cashCost: cost,
      successChancePct: successChance,
      immediatePriceImpactBps: immediateImpact,
      successPriceImpactBps: successImpact,
      failurePriceImpactBps: failureImpact,
    );
    final companies = <String, ListedCompanyGovernance>{
      ...state.shareholderGovernance.companies,
    };
    final leadMarketEvent = _completedMarketEvent(
      state,
      id: '${action.id}:lead-announcement',
      title: '$title 발표',
      summary: '$strategy 기업재편 계획이 시장에 공시됐습니다.',
      priceImpactBps: immediateImpact,
    );
    companies[leadAssetId] = lead.copyWith(
      subsidiaryCash: lead.subsidiaryCash - cashUsed,
      subsidiaryDebt: lead.subsidiaryDebt + borrowed,
      managementValueBps: lead.managementValueBps + immediateImpact,
      managementDecisions: _appendDecision(
        lead.managementDecisions,
        leadMarketEvent,
      ),
      history: _appendHistory(
        lead.history,
        '${_dateKey(state.currentDate)} $title 발표 · $strategy',
      ),
    );
    if (partner != null) {
      final partnerImpact = (immediateImpact * 0.7).round();
      final partnerMarketEvent = _completedMarketEvent(
        state,
        id: '${action.id}:partner-announcement',
        title: '$title 발표',
        summary: '$strategy 기업재편 계획이 시장에 공시됐습니다.',
        priceImpactBps: partnerImpact,
      );
      companies[partner.assetId] = partner.copyWith(
        managementValueBps: partner.managementValueBps + partnerImpact,
        managementDecisions: _appendDecision(
          partner.managementDecisions,
          partnerMarketEvent,
        ),
        history: _appendHistory(
          partner.history,
          '${_dateKey(state.currentDate)} $title 발표 · $strategy',
        ),
      );
    }
    final actions = <ListedCorporateActionRecord>[
      ...state.shareholderGovernance.corporateActions,
      action,
    ];
    final next = state.copyWith(
      shareholderGovernance: state.shareholderGovernance.copyWith(
        companies: companies,
        corporateActions: actions.length <= 128
            ? actions
            : actions.sublist(actions.length - 128),
      ),
    );
    return ShareholderGovernanceActionResult(
      state: next,
      success: true,
      message:
          '$title 안을 승인하고 $strategy 통합에 착수했습니다. 비용 ${_won(cost)}${borrowed > 0 ? ' · 신규차입 ${_won(borrowed)}' : ''} · $duration일 뒤 결과가 확정됩니다.',
    );
  }

  ShareholderGovernanceActionResult attendMeeting(
    GameState state,
    String meetingId,
  ) {
    final meeting = _meetingById(state, meetingId);
    if (meeting == null) return _failure(state, '주주총회를 찾을 수 없습니다.');
    final company = state.shareholderGovernance.companyById(meeting.assetId);
    if (company == null ||
        !company.rights.contains(ShareholderRight.attendMeeting)) {
      return _failure(state, '기준일 현재 보유주식이 없어 참석할 수 없습니다.');
    }
    if (!_meetingActionable(state, meeting)) {
      return _failure(state, '현재 참석 가능한 주주총회가 아닙니다.');
    }
    final updated = meeting.copyWith(
      status: ShareholderMeetingStatus.open,
      attended: true,
    );
    return _meetingSuccess(state, updated, '${company.name} 주주총회에 참석했습니다.');
  }

  ShareholderGovernanceActionResult vote(
    GameState state, {
    required String meetingId,
    required String agendaId,
    required ShareholderVoteChoice choice,
  }) {
    final meeting = _meetingById(state, meetingId);
    if (meeting == null) return _failure(state, '주주총회를 찾을 수 없습니다.');
    if (!meeting.attended || !_meetingActionable(state, meeting)) {
      return _failure(state, '먼저 주주총회에 참석해야 의결권을 행사할 수 있습니다.');
    }
    final company = state.shareholderGovernance.companyById(meeting.assetId);
    if (company == null || company.ownershipPct <= 0) {
      return _failure(state, '행사할 의결권이 없습니다.');
    }
    final index = meeting.agendas.indexWhere((agenda) => agenda.id == agendaId);
    if (index < 0) return _failure(state, '안건을 찾을 수 없습니다.');
    if (meeting.agendas[index].vote != null) {
      return _failure(state, '이미 표결한 안건입니다.');
    }

    final agenda = _resolveAgenda(meeting.agendas[index], company, choice);
    final agendas = <ShareholderAgenda>[...meeting.agendas]..[index] = agenda;
    final closed = agendas.every((item) => item.vote != null);
    final updatedMeeting = meeting.copyWith(
      agendas: agendas,
      status: closed ? ShareholderMeetingStatus.closed : meeting.status,
    );
    var governance = state.shareholderGovernance;
    final marketImpactBps = _shareholderAgendaMarketImpactBps(agenda);
    final voteRecord = ListedManagementDecisionRecord(
      id: '${meeting.id}-${agenda.id}-vote-${state.day}',
      agendaId: agenda.id,
      optionId: choice.name,
      title: '주주총회 · ${agenda.title}',
      optionLabel: agenda.passed == true ? '가결' : '부결',
      summary: agenda.description,
      decisionDay: state.day,
      completionDay: state.day,
      cashCost: 0,
      revenueDeltaBps: 0,
      expenseDeltaBps: 0,
      immediatePriceImpactBps: 0,
      successPriceImpactBps: marketImpactBps,
      failurePriceImpactBps: marketImpactBps,
      innovationDelta: 0,
      operationsDelta: 0,
      brandDelta: 0,
      workforceDelta: 0,
      successChancePct: 100,
      status: agenda.passed == true
          ? ListedManagementDecisionStatus.succeeded
          : ListedManagementDecisionStatus.failed,
      outcome:
          '${agenda.finalSupportPct!.toStringAsFixed(1)}% 찬성으로 ${agenda.passed == true ? '가결' : '부결'}됐습니다.',
      realizedPriceImpactBps: marketImpactBps,
    );
    final voteDecisions = <ListedManagementDecisionRecord>[
      ...company.managementDecisions,
      voteRecord,
    ];
    var updatedCompany = company.copyWith(
      managementValueBps: company.managementValueBps + marketImpactBps,
      managementDecisions: voteDecisions.length <= 256
          ? voteDecisions
          : voteDecisions.sublist(voteDecisions.length - 256),
      history: _appendHistory(
        company.history,
        '${_dateKey(state.currentDate)} ${agenda.title} '
        '${agenda.passed == true ? '가결' : '부결'} · 시장평가 '
        '${marketImpactBps >= 0 ? '+' : ''}${(marketImpactBps / 100).toStringAsFixed(1)}%',
      ),
    );
    if (agenda.passed == true &&
        agenda.proposedByPlayer &&
        agenda.type == ShareholderAgendaType.directorElection) {
      updatedCompany = updatedCompany.copyWith(
        boardSeats: math.min(7, updatedCompany.boardSeats + 1),
        history: _appendHistory(
          updatedCompany.history,
          '${_dateKey(state.currentDate)} 주주 추천 이사 선임',
        ),
      );
    }
    governance = governance.copyWith(
      companies: <String, ListedCompanyGovernance>{
        ...governance.companies,
        company.assetId: updatedCompany,
      },
    );
    final next = _replaceMeeting(
      state.copyWith(shareholderGovernance: governance),
      updatedMeeting,
    );
    final outcome = agenda.passed == true ? '가결' : '부결';
    return ShareholderGovernanceActionResult(
      state: next,
      success: true,
      message:
          '${agenda.title}: $outcome (${agenda.finalSupportPct!.toStringAsFixed(1)}% 찬성) · '
          '시장반응 ${marketImpactBps >= 0 ? '+' : ''}${(marketImpactBps / 100).toStringAsFixed(1)}%',
    );
  }

  ShareholderGovernanceActionResult submitProposal(
    GameState state, {
    required String assetId,
    required ShareholderAgendaType type,
  }) {
    final company = state.shareholderGovernance.companyById(assetId);
    if (company == null ||
        !company.rights.contains(ShareholderRight.submitProposal)) {
      return _failure(state, '지분 1% 이상부터 주주제안을 제출할 수 있습니다.');
    }
    final meeting = _nextMeetingFor(state, assetId);
    if (meeting == null) return _failure(state, '제안을 접수할 주주총회가 없습니다.');
    if (meeting.agendas.any((agenda) => agenda.proposedByPlayer)) {
      return _failure(state, '이 주주총회에는 이미 주주제안을 제출했습니다.');
    }
    final proposal = _playerProposal(state, meeting, type, suffix: 'proposal');
    return _meetingSuccess(
      state,
      meeting.copyWith(
        agendas: <ShareholderAgenda>[...meeting.agendas, proposal],
      ),
      '${company.name}에 ${type.label} 주주제안을 접수했습니다.',
    );
  }

  ShareholderGovernanceActionResult nominateDirector(
    GameState state,
    String assetId,
  ) {
    final company = state.shareholderGovernance.companyById(assetId);
    if (company == null ||
        !company.rights.contains(ShareholderRight.nominateDirector)) {
      return _failure(state, '지분 3% 이상부터 이사 후보를 추천할 수 있습니다.');
    }
    final meeting = _nextMeetingFor(state, assetId);
    if (meeting == null) return _failure(state, '후보를 등록할 주주총회가 없습니다.');
    if (meeting.agendas.any(
      (agenda) =>
          agenda.proposedByPlayer &&
          agenda.type == ShareholderAgendaType.directorElection,
    )) {
      return _failure(state, '이미 주주 추천 이사 후보가 등록되어 있습니다.');
    }
    final proposal = _playerProposal(
      state,
      meeting,
      ShareholderAgendaType.directorElection,
      suffix: 'director',
    );
    return _meetingSuccess(
      state,
      meeting.copyWith(
        agendas: <ShareholderAgenda>[...meeting.agendas, proposal],
      ),
      '${company.name} 이사 후보를 추천했습니다.',
    );
  }

  ShareholderGovernanceActionResult requestAudit(
    GameState state,
    String assetId,
  ) {
    final company = state.shareholderGovernance.companyById(assetId);
    if (company == null ||
        !company.rights.contains(ShareholderRight.requestAudit)) {
      return _failure(state, '지분 5% 이상부터 감사를 요구할 수 있습니다.');
    }
    final meeting = _nextMeetingFor(state, assetId);
    if (meeting == null) return _failure(state, '감사 요구를 접수할 주주총회가 없습니다.');
    if (meeting.agendas.any(
      (agenda) =>
          agenda.proposedByPlayer && agenda.type == ShareholderAgendaType.audit,
    )) {
      return _failure(state, '이미 독립 감사 요구가 접수되어 있습니다.');
    }
    final proposal = _playerProposal(
      state,
      meeting,
      ShareholderAgendaType.audit,
      suffix: 'audit',
    );
    return _meetingSuccess(
      state,
      meeting.copyWith(
        agendas: <ShareholderAgenda>[...meeting.agendas, proposal],
      ),
      '${company.name}에 독립 감사·장부 열람 요구를 접수했습니다.',
    );
  }

  ShareholderGovernanceActionResult callExtraordinaryMeeting(
    GameState state,
    String assetId,
  ) {
    final company = state.shareholderGovernance.companyById(assetId);
    if (company == null ||
        !company.rights.contains(ShareholderRight.callExtraordinaryMeeting)) {
      return _failure(state, '지분 3% 이상부터 임시주총 소집을 요구할 수 있습니다.');
    }
    if (state.shareholderGovernance.meetings.any(
      (meeting) =>
          meeting.assetId == assetId &&
          meeting.extraordinary &&
          meeting.status != ShareholderMeetingStatus.closed,
    )) {
      return _failure(state, '이미 진행 중인 임시주총이 있습니다.');
    }
    final id = 'egm-$assetId-${state.day}';
    final meeting = ShareholderMeeting(
      id: id,
      assetId: assetId,
      year: state.currentDate.year,
      heldDay: state.day,
      deadlineDay: math.min(GameState.maxCampaignDay, state.day + 14),
      extraordinary: true,
      status: ShareholderMeetingStatus.open,
      attended: false,
      agendas: <ShareholderAgenda>[
        _playerProposal(
          state,
          ShareholderMeeting(
            id: id,
            assetId: assetId,
            year: state.currentDate.year,
            heldDay: state.day,
            deadlineDay: state.day + 14,
            extraordinary: true,
            status: ShareholderMeetingStatus.open,
            attended: false,
            agendas: const <ShareholderAgenda>[],
          ),
          ShareholderAgendaType.strategy,
          suffix: 'extraordinary',
        ),
      ],
    );
    final next = state.copyWith(
      shareholderGovernance: state.shareholderGovernance.copyWith(
        meetings: <ShareholderMeeting>[
          ...state.shareholderGovernance.meetings,
          meeting,
        ],
      ),
    );
    return ShareholderGovernanceActionResult(
      state: next,
      success: true,
      message: '${company.name} 임시주총 소집 요구가 접수되었습니다.',
    );
  }

  ShareholderGovernanceActionResult solicitProxies(
    GameState state, {
    required String assetId,
    required int marketCap,
  }) {
    final company = state.shareholderGovernance.companyById(assetId);
    if (company == null ||
        !company.rights.contains(ShareholderRight.solicitProxies)) {
      return _failure(state, '지분 10% 이상부터 의결권 위임을 권유할 수 있습니다.');
    }
    final cost = math.max(75000, (math.max(0, marketCap) * 0.0002).round());
    if (state.bankCash < cost) {
      return _failure(state, '위임장 권유 비용 ${_won(cost)}이 부족합니다.');
    }
    final gain =
        3 +
        (stableHash31('${state.simulationSeed}:$assetId:proxy:${state.day}') %
                701) /
            100;
    final ceiling = math.max(0.0, 49.99 - company.ownershipPct);
    final friendly = math.min(ceiling, company.friendlyVotingPct + gain);
    final updated = company.copyWith(
      friendlyVotingPct: friendly,
      history: _appendHistory(
        company.history,
        '${_dateKey(state.currentDate)} 위임장 확보 +${gain.toStringAsFixed(2)}%p',
      ),
    );
    final next = _withCompany(
      state.copyWith(
        cash: state.cash - cost,
        ledger: <LedgerEntry>[
          ...state.ledger,
          LedgerEntry(
            id: 'proxy-$assetId-${state.day}',
            day: state.day,
            amount: -cost,
            account: 'company_bank',
            counterAccount: 'shareholder_campaign_expense',
            description: '${company.name} 의결권 위임 권유',
            sourceId: 'proxy-$assetId-${state.day}',
            assetId: assetId,
          ),
        ],
      ),
      updated,
    );
    return ShareholderGovernanceActionResult(
      state: next,
      success: true,
      message:
          '우호 의결권이 ${updated.friendlyVotingPct.toStringAsFixed(2)}%로 늘었습니다. 비용 ${_won(cost)}',
    );
  }

  ShareholderGovernanceActionResult launchTenderOffer(
    GameState state, {
    required FictionalMarketAsset asset,
    required double targetOwnershipPct,
    required int premiumBps,
  }) {
    final company = state.shareholderGovernance.companyById(asset.id);
    if (company == null ||
        !company.rights.contains(ShareholderRight.launchTenderOffer)) {
      return _failure(state, '지분 20% 이상부터 공개매수를 시작할 수 있습니다.');
    }
    final target = targetOwnershipPct.clamp(20.01, 100).toDouble();
    if (company.ownershipPct >= target) {
      return _failure(state, '이미 목표 지분율을 확보했습니다.');
    }
    final rawPrice = asset.quoteAtOrBefore(state.currentDate)?.close ?? 0;
    final price = state.shareholderGovernance.adjustedPrice(
      asset.id,
      state.day,
      rawPrice,
    );
    if (price <= 0 || company.sharesOutstanding <= 0) {
      return _failure(state, '공개매수 기준가격을 계산할 수 없습니다.');
    }
    final requestedShares = math.max(
      1,
      (company.sharesOutstanding * target / 100 - company.ownedShares).ceil(),
    );
    final availableShares = math.max(
      0,
      company.sharesOutstanding - company.ownedShares.floor(),
    );
    final acceptanceRate = premiumBps >= 4000
        ? 0.92
        : premiumBps >= 2500
        ? 0.68
        : 0.42;
    final acceptedCapacity = (availableShares * acceptanceRate).floor();
    final acquiredShares = math.min(requestedShares, acceptedCapacity);
    if (acquiredShares <= 0) {
      return _failure(state, '매도 응모 물량이 없어 공개매수가 성립하지 않았습니다.');
    }
    final offerPrice = price * (1 + premiumBps / 10000);
    final cost = (offerPrice * acquiredShares).round();
    if (state.bankCash < cost) {
      return _failure(state, '공개매수 대금 ${_won(cost)}이 회사계좌에 부족합니다.');
    }

    final positions = <PortfolioPosition>[...state.positions];
    final positionIndex = positions.indexWhere(
      (position) => position.assetId == asset.id,
    );
    if (positionIndex < 0) {
      positions.add(
        PortfolioPosition(
          assetId: asset.id,
          symbol: asset.symbol,
          name: asset.name,
          market: asset.market,
          currency: asset.currency,
          units: acquiredShares.toDouble(),
          totalCost: cost,
        ),
      );
    } else {
      final position = positions[positionIndex];
      positions[positionIndex] = position.copyWith(
        units: position.units + acquiredShares,
        totalCost: position.totalCost + cost,
      );
    }
    final outstanding = company.sharesOutstanding;
    final nextOwned = company.ownedShares + acquiredShares;
    final remainingPendingCapacity = math.max(0.0, outstanding - nextOwned);
    var excessPendingBuy = math.max(
      0.0,
      state.pendingBuyReservedUnits(asset.id) - remainingPendingCapacity,
    );
    var canceledPendingShares = 0.0;
    final reconciledPending = <PendingTradeOrder>[...state.pendingOrders];
    final newestPendingBuys =
        reconciledPending
            .where(
              (order) =>
                  order.assetId == asset.id &&
                  order.side == PendingOrderSide.buy,
            )
            .toList(growable: false)
          ..sort((left, right) {
            final sequence = right.placedSequence.compareTo(
              left.placedSequence,
            );
            return sequence != 0 ? sequence : right.id.compareTo(left.id);
          });
    for (final target in newestPendingBuys) {
      if (excessPendingBuy <= 0.000001) break;
      final index = reconciledPending.indexWhere(
        (order) => order.id == target.id,
      );
      if (index < 0) continue;
      final currentOrder = reconciledPending[index];
      final reduction = math.min(
        excessPendingBuy,
        currentOrder.remainingQuantity,
      );
      if (reduction <= 0) continue;
      for (
        var otherIndex = 0;
        otherIndex < reconciledPending.length;
        otherIndex += 1
      ) {
        final other = reconciledPending[otherIndex];
        if (other.id == currentOrder.id ||
            other.assetId != currentOrder.assetId ||
            other.side != currentOrder.side ||
            (other.limitPrice - currentOrder.limitPrice).abs() >= 0.000001 ||
            other.placedSequence <= currentOrder.placedSequence) {
          continue;
        }
        reconciledPending[otherIndex] = other.copyWith(
          queueAheadQuantity: math.max(
            0.0,
            other.queueAheadQuantity - reduction,
          ),
        );
      }
      if (reduction + 0.000001 >= currentOrder.remainingQuantity) {
        reconciledPending.removeAt(index);
      } else {
        reconciledPending[index] = currentOrder.copyWith(
          remainingQuantity: currentOrder.remainingQuantity - reduction,
        );
      }
      excessPendingBuy -= reduction;
      canceledPendingShares += reduction;
    }

    final sourceId = 'tender-${asset.id}-${state.day}';
    var next = state.copyWith(
      cash: state.cash - cost,
      positions: positions,
      pendingOrders: reconciledPending,
      ledger: <LedgerEntry>[
        ...state.ledger,
        LedgerEntry(
          id: sourceId,
          day: state.day,
          amount: -cost,
          account: 'listed_equity_investment',
          counterAccount: 'company_bank',
          description:
              '${asset.name} 공개매수 ${_number(acquiredShares)}주 · 프리미엄 ${(premiumBps / 100).toStringAsFixed(0)}%',
          sourceId: sourceId,
          notional: cost,
          assetId: asset.id,
          tradeSide: 'tender_buy',
          tradeQuantity: acquiredShares.toDouble(),
          tradeUnitPrice: offerPrice,
        ),
        if (canceledPendingShares > 0.000001)
          LedgerEntry(
            id: '$sourceId-pending-reconcile',
            day: state.day,
            amount: 0,
            account: 'brokerage_order',
            counterAccount: 'tender_position_limit',
            description:
                '${asset.name} 공개매수 취득분 반영 · 미체결 매수 '
                '${_number(canceledPendingShares.round())}주 자동 감액/취소',
            sourceId: '$sourceId-pending-reconcile',
            assetId: asset.id,
            tradeSide: PendingOrderSide.buy.name,
          ),
      ],
    );
    var updatedCompany = company.copyWith(
      ownedShares: nextOwned,
      tenderAcquiredShares: company.tenderAcquiredShares + acquiredShares,
      lastSyncedDay: state.day,
      history: _appendHistory(
        company.history,
        '${_dateKey(state.currentDate)} 공개매수 ${_number(acquiredShares)}주',
      ),
    );
    if (updatedCompany.isControlled && !company.isControlled) {
      updatedCompany = updatedCompany.copyWith(
        acquiredControlDay: state.day,
        boardSeats: math.max(4, updatedCompany.boardSeats),
        history: _appendHistory(
          updatedCompany.history,
          '${_dateKey(state.currentDate)} 경영권 확보',
        ),
      );
    }
    next = _withCompany(next, updatedCompany);
    final resultingPct = nextOwned / outstanding * 100;
    return ShareholderGovernanceActionResult(
      state: next,
      success: true,
      message:
          '${asset.name} ${_number(acquiredShares)}주 공개매수 완료 · 보유 ${resultingPct.toStringAsFixed(2)}%'
          '${updatedCompany.isControlled ? ' · 경영권 확보' : ''}'
          '${canceledPendingShares > 0.000001 ? ' · 초과 미체결 매수 ${_number(canceledPendingShares.round())}주 정리' : ''}',
    );
  }

  ShareholderGovernanceActionResult setOperatingPolicy(
    GameState state, {
    required String assetId,
    required SubsidiaryOperatingPolicy policy,
  }) {
    final company = state.shareholderGovernance.companyById(assetId);
    if (company == null || !company.isControlled) {
      return _failure(state, '경영권을 확보한 회사만 운영 방침을 바꿀 수 있습니다.');
    }
    final updated = company.copyWith(
      operatingPolicy: policy,
      history: _appendHistory(
        company.history,
        '${_dateKey(state.currentDate)} 운영 방침: ${policy.label}',
      ),
    );
    return ShareholderGovernanceActionResult(
      state: _withCompany(state, updated),
      success: true,
      message: '${company.name} 운영 방침을 ${policy.label}(으)로 변경했습니다.',
    );
  }

  ShareholderGovernanceActionResult appointLeadership(
    GameState state, {
    required String assetId,
    required SubsidiaryLeadershipModel leadership,
  }) {
    final company = state.shareholderGovernance.companyById(assetId);
    if (company == null || !company.isControlled) {
      return _failure(state, '경영권을 확보한 회사만 대표 체제를 정할 수 있습니다.');
    }
    if (leadership == SubsidiaryLeadershipModel.founderLed &&
        !company.playerIsCeo) {
      return _failure(state, '직접 경영은 CEO 취임 절차를 통해 선택해야 합니다.');
    }
    if (company.playerIsCeo &&
        leadership != SubsidiaryLeadershipModel.founderLed) {
      return _failure(state, '먼저 CEO 사임 절차를 진행해야 대표 체제를 바꿀 수 있습니다.');
    }
    final updated = company.copyWith(
      leadershipModel: leadership,
      history: _appendHistory(
        company.history,
        '${_dateKey(state.currentDate)} 대표 체제: ${leadership.label}',
      ),
    );
    return ShareholderGovernanceActionResult(
      state: _withCompany(state, updated),
      success: true,
      message: '${company.name}을 ${leadership.label} 체제로 전환했습니다.',
    );
  }

  GameState _ensureRegularMeetings(GameState state) {
    final meetings = <ShareholderMeeting>[
      ...state.shareholderGovernance.meetings,
    ];
    for (final company in state.shareholderGovernance.companies.values) {
      if (company.ownershipPct <= 0) continue;
      var year = state.currentDate.year;
      final thisYearDeadline = _regularMeetingDate(
        year,
        company.assetId,
      ).add(const Duration(days: 7));
      if (state.currentDate.isAfter(thisYearDeadline)) year += 1;
      final id = 'agm-${company.assetId}-$year';
      if (meetings.any((meeting) => meeting.id == id)) continue;
      final heldDate = _regularMeetingDate(year, company.assetId);
      final heldDay = _dayFor(state, heldDate);
      meetings.add(
        ShareholderMeeting(
          id: id,
          assetId: company.assetId,
          year: year,
          heldDay: heldDay,
          deadlineDay: math.min(GameState.maxCampaignDay, heldDay + 7),
          extraordinary: false,
          status: state.day >= heldDay - 14
              ? ShareholderMeetingStatus.open
              : ShareholderMeetingStatus.scheduled,
          attended: false,
          agendas: _regularAgendas(state, company, year),
        ),
      );
    }
    meetings.sort((left, right) => left.heldDay.compareTo(right.heldDay));
    return state.copyWith(
      shareholderGovernance: state.shareholderGovernance.copyWith(
        meetings: meetings,
      ),
    );
  }

  GameState _updateMeetingWindows(GameState state) {
    final companies = state.shareholderGovernance.companies;
    final meetings = <ShareholderMeeting>[];
    for (final meeting in state.shareholderGovernance.meetings) {
      if (meeting.status == ShareholderMeetingStatus.closed) {
        meetings.add(meeting);
        continue;
      }
      if (state.day > meeting.deadlineDay) {
        final company = companies[meeting.assetId];
        final agendas = company == null
            ? meeting.agendas
            : meeting.agendas
                  .map(
                    (agenda) => agenda.vote == null
                        ? _resolveAgenda(
                            agenda,
                            company,
                            ShareholderVoteChoice.abstain,
                          )
                        : agenda,
                  )
                  .toList();
        meetings.add(
          meeting.copyWith(
            status: ShareholderMeetingStatus.closed,
            agendas: agendas,
          ),
        );
      } else if (state.day >= meeting.heldDay - 14) {
        meetings.add(meeting.copyWith(status: ShareholderMeetingStatus.open));
      } else {
        meetings.add(meeting);
      }
    }
    return state.copyWith(
      shareholderGovernance: state.shareholderGovernance.copyWith(
        meetings: meetings,
      ),
    );
  }

  GameState _resolveCorporateActions(GameState state) {
    final due = state.shareholderGovernance.corporateActions
        .where(
          (action) => action.isExecuting && action.completionDay <= state.day,
        )
        .toList(growable: false);
    if (due.isEmpty) return state;

    final companies = <String, ListedCompanyGovernance>{
      ...state.shareholderGovernance.companies,
    };
    final actions = <ListedCorporateActionRecord>[];
    for (final action in state.shareholderGovernance.corporateActions) {
      if (!action.isExecuting || action.completionDay > state.day) {
        actions.add(action);
        continue;
      }
      final roll =
          stableHash31('${state.simulationSeed}:${action.id}:outcome') %
          10000 /
          100;
      late final ListedCorporateActionStatus status;
      late final double effectScale;
      late final int priceImpact;
      late final String outcome;
      if (roll < action.successChancePct) {
        status = ListedCorporateActionStatus.succeeded;
        effectScale = 1;
        priceImpact = action.successPriceImpactBps;
        outcome = switch (action.type) {
          ListedCorporateActionType.merger =>
            '${action.strategy} 통합이 완료돼 중복비용을 줄이고 사업 시너지를 만들었습니다.',
          ListedCorporateActionType.jointVenture =>
            '합작법인이 계획대로 출범해 양사의 기술·고객망을 함께 활용합니다.',
          ListedCorporateActionType.spinOff =>
            '사업분할이 완료돼 각 사업부의 책임경영과 자본배분이 선명해졌습니다.',
          ListedCorporateActionType.assetSale =>
            '자산 매각을 완료해 현금을 확보하고 핵심사업 집중도를 높였습니다.',
        };
      } else if (roll < math.min(97, action.successChancePct + 18)) {
        status = ListedCorporateActionStatus.mixed;
        effectScale = 0.4;
        priceImpact = (action.successPriceImpactBps * 0.25).round();
        outcome = '거래는 마무리했지만 통합비용과 조직 충돌이 남아 성과가 제한됐습니다.';
      } else {
        status = ListedCorporateActionStatus.failed;
        effectScale = -0.3;
        priceImpact = action.failurePriceImpactBps;
        outcome = '주주·채권자·조직의 반발과 실사 문제로 거래가 무산됐습니다.';
      }

      final lead = companies[action.leadAssetId];
      if (lead != null) {
        var revenue = lead.monthlyRevenue;
        var expense = lead.monthlyExpense;
        var subsidiaryCash = lead.subsidiaryCash;
        var debt = lead.subsidiaryDebt;
        var innovation = lead.innovation;
        var operations = lead.operations;
        var brand = lead.brandTrust;
        var workforce = lead.workforce;
        switch (action.type) {
          case ListedCorporateActionType.merger:
            revenue = math.max(0, (revenue * (1 + 0.12 * effectScale)).round());
            expense = math.max(0, (expense * (1 - 0.05 * effectScale)).round());
            innovation += (6 * effectScale).round();
            operations += (8 * effectScale).round();
            brand += (4 * effectScale).round();
            workforce += (-3 * effectScale).round();
            break;
          case ListedCorporateActionType.jointVenture:
            revenue = math.max(0, (revenue * (1 + 0.07 * effectScale)).round());
            expense = math.max(
              0,
              (expense * (1 + 0.025 * effectScale)).round(),
            );
            innovation += (8 * effectScale).round();
            brand += (5 * effectScale).round();
            break;
          case ListedCorporateActionType.spinOff:
            revenue = math.max(
              0,
              (revenue * (1 - 0.12 * math.max(0, effectScale))).round(),
            );
            expense = math.max(
              0,
              (expense * (1 - 0.18 * math.max(0, effectScale))).round(),
            );
            if (effectScale > 0) {
              subsidiaryCash += (lead.monthlyRevenue * 0.22 * effectScale)
                  .round();
            }
            operations += (7 * effectScale).round();
            break;
          case ListedCorporateActionType.assetSale:
            revenue = math.max(
              0,
              (revenue * (1 - 0.08 * math.max(0, effectScale))).round(),
            );
            expense = math.max(
              0,
              (expense * (1 - 0.12 * math.max(0, effectScale))).round(),
            );
            if (effectScale > 0) {
              final proceeds = (lead.monthlyRevenue * 0.35 * effectScale)
                  .round();
              final repayment = math.min(debt, (proceeds * 0.5).round());
              debt -= repayment;
              subsidiaryCash += proceeds - repayment;
            }
            operations += (5 * effectScale).round();
            break;
        }
        final resultMarketEvent = _completedMarketEvent(
          state,
          id: '${action.id}:lead-result',
          title: '${action.type.label} 결과',
          summary: outcome,
          priceImpactBps: priceImpact,
        );
        companies[action.leadAssetId] = lead.copyWith(
          monthlyRevenue: revenue,
          monthlyExpense: expense,
          subsidiaryCash: subsidiaryCash,
          subsidiaryDebt: debt,
          innovation: innovation,
          operations: operations,
          brandTrust: brand,
          workforce: workforce,
          ceoPerformance:
              lead.ceoPerformance +
              switch (status) {
                ListedCorporateActionStatus.succeeded => 8,
                ListedCorporateActionStatus.mixed => 2,
                ListedCorporateActionStatus.failed => -10,
                ListedCorporateActionStatus.executing => 0,
              },
          managementValueBps: lead.managementValueBps + priceImpact,
          managementDecisions: _appendDecision(
            lead.managementDecisions,
            resultMarketEvent,
          ),
          history: _appendHistory(
            lead.history,
            '${_dateKey(state.currentDate)} ${action.type.label} ${status.label} · 시장평가 ${priceImpact >= 0 ? '+' : ''}${(priceImpact / 100).toStringAsFixed(1)}%',
          ),
        );
      }

      final partner = companies[action.partnerAssetId];
      if (partner != null) {
        final partnerRevenueImpact =
            action.type == ListedCorporateActionType.merger ? 0.08 : 0.05;
        final partnerPriceImpact = (priceImpact * 0.7).round();
        final partnerResultMarketEvent = _completedMarketEvent(
          state,
          id: '${action.id}:partner-result',
          title: '${action.type.label} 결과',
          summary: outcome,
          priceImpactBps: partnerPriceImpact,
        );
        companies[action.partnerAssetId] = partner.copyWith(
          monthlyRevenue: math.max(
            0,
            (partner.monthlyRevenue * (1 + partnerRevenueImpact * effectScale))
                .round(),
          ),
          monthlyExpense: math.max(
            0,
            (partner.monthlyExpense * (1 - 0.03 * effectScale)).round(),
          ),
          innovation: partner.innovation + (5 * effectScale).round(),
          operations: partner.operations + (6 * effectScale).round(),
          brandTrust: partner.brandTrust + (3 * effectScale).round(),
          workforce: partner.workforce + (-2 * effectScale).round(),
          managementValueBps: partner.managementValueBps + partnerPriceImpact,
          managementDecisions: _appendDecision(
            partner.managementDecisions,
            partnerResultMarketEvent,
          ),
          history: _appendHistory(
            partner.history,
            '${_dateKey(state.currentDate)} ${action.type.label} ${status.label} · 시장평가 ${partnerPriceImpact >= 0 ? '+' : ''}${(partnerPriceImpact / 100).toStringAsFixed(1)}%',
          ),
        );
      }
      actions.add(action.copyWith(status: status, outcome: outcome));
    }
    return state.copyWith(
      shareholderGovernance: state.shareholderGovernance.copyWith(
        companies: companies,
        corporateActions: actions,
      ),
    );
  }

  GameState _settleControlledCompanies(GameState state) {
    final month =
        '${state.currentDate.year.toString().padLeft(4, '0')}-${state.currentDate.month.toString().padLeft(2, '0')}';
    final companies = <String, ListedCompanyGovernance>{
      ...state.shareholderGovernance.companies,
    };
    var cash = state.cash;
    final ledger = <LedgerEntry>[...state.ledger];
    var changed = false;
    for (final company in companies.values.toList()) {
      if (!company.isControlled || company.lastOperationsMonth == month) {
        continue;
      }
      final pulse =
          (stableHash31(
                    '${state.simulationSeed}:${company.assetId}:operations:$month',
                  ) %
                  901 -
              450) /
          10000;
      final revenueFactor = switch (company.operatingPolicy) {
        SubsidiaryOperatingPolicy.growth => 1.06 + pulse,
        SubsidiaryOperatingPolicy.efficiency => 0.99 + pulse,
        SubsidiaryOperatingPolicy.people => 1.02 + pulse,
        SubsidiaryOperatingPolicy.dividend => 1.00 + pulse,
      };
      final expenseFactor = switch (company.operatingPolicy) {
        SubsidiaryOperatingPolicy.growth => 1.10,
        SubsidiaryOperatingPolicy.efficiency => 0.92,
        SubsidiaryOperatingPolicy.people => 1.06,
        SubsidiaryOperatingPolicy.dividend => 1.00,
      };
      final leadershipFactor = switch (company.leadershipModel) {
        SubsidiaryLeadershipModel.founderLed => 1.01,
        SubsidiaryLeadershipModel.professionalCeo => 1.025,
        SubsidiaryLeadershipModel.jointManagement => 1.015,
      };
      final revenue = math.max(
        0,
        (company.monthlyRevenue * revenueFactor * leadershipFactor).round(),
      );
      final expense = math.max(
        0,
        (company.monthlyExpense * expenseFactor).round(),
      );
      final profit = revenue - expense;
      var subsidiaryCash = company.subsidiaryCash + profit;
      var debt = company.subsidiaryDebt;
      if (subsidiaryCash < 0) {
        debt += -subsidiaryCash;
        subsidiaryCash = 0;
      }
      var distribution = 0;
      if (company.operatingPolicy == SubsidiaryOperatingPolicy.dividend &&
          profit > 0 &&
          subsidiaryCash > 0) {
        final grossDividend = math.min(
          (profit * 0.45).round(),
          (subsidiaryCash * 0.15).round(),
        );
        distribution = (grossDividend * company.ownershipPct / 100).round();
        subsidiaryCash -= grossDividend;
        cash += distribution;
        if (distribution > 0) {
          final sourceId =
              'listed-subsidiary-dividend-${company.assetId}-$month';
          ledger.add(
            LedgerEntry(
              id: sourceId,
              day: state.day,
              amount: distribution,
              account: 'company_bank',
              counterAccount: 'subsidiary_dividend_income',
              description: '${company.name} 지배주주 배당',
              sourceId: sourceId,
              assetId: company.assetId,
            ),
          );
        }
      }
      companies[company.assetId] = company.copyWith(
        monthlyRevenue: revenue,
        monthlyExpense: expense,
        subsidiaryCash: subsidiaryCash,
        subsidiaryDebt: debt,
        retainedEarnings: company.retainedEarnings + profit,
        cumulativeDistribution: company.cumulativeDistribution + distribution,
        lastOperationsMonth: month,
        history: _appendHistory(
          company.history,
          '$month 영업 ${profit >= 0 ? '이익' : '손실'} ${_won(profit.abs())}'
          '${distribution > 0 ? ' · 배당 ${_won(distribution)}' : ''}',
        ),
      );
      changed = true;
    }
    if (!changed) return state;
    return state.copyWith(
      cash: cash,
      ledger: ledger,
      shareholderGovernance: state.shareholderGovernance.copyWith(
        companies: companies,
      ),
    );
  }

  GameState _resolveManagementDecisions(GameState state) {
    final companies = <String, ListedCompanyGovernance>{
      ...state.shareholderGovernance.companies,
    };
    var changed = false;
    for (final company in companies.values.toList()) {
      final due = company.managementDecisions
          .where(
            (decision) =>
                decision.isExecuting && decision.completionDay <= state.day,
          )
          .toList(growable: false);
      if (due.isEmpty) continue;

      var revenue = company.monthlyRevenue;
      var expense = company.monthlyExpense;
      var innovation = company.innovation;
      var operations = company.operations;
      var brand = company.brandTrust;
      var workforce = company.workforce;
      var ceoPerformance = company.ceoPerformance;
      var managementValueBps = company.managementValueBps;
      var history = company.history;
      final decisions = <ListedManagementDecisionRecord>[];
      for (final decision in company.managementDecisions) {
        if (!decision.isExecuting || decision.completionDay > state.day) {
          decisions.add(decision);
          continue;
        }
        final roll =
            stableHash31(
              '${state.simulationSeed}:${company.assetId}:${decision.id}:outcome',
            ) %
            10000 /
            100;
        late final ListedManagementDecisionStatus status;
        late final double effectScale;
        late final int priceImpact;
        late final String outcome;
        if (roll < decision.successChancePct) {
          status = ListedManagementDecisionStatus.succeeded;
          effectScale = 1;
          priceImpact = decision.successPriceImpactBps;
          outcome = '계획한 성과를 달성해 매출과 시장 신뢰가 함께 개선됐습니다.';
        } else if (roll < math.min(98, decision.successChancePct + 18)) {
          status = ListedManagementDecisionStatus.mixed;
          effectScale = 0.45;
          priceImpact = (decision.successPriceImpactBps * 0.35).round();
          outcome = '일부 목표는 달성했지만 일정과 비용 부담이 남았습니다.';
        } else {
          status = ListedManagementDecisionStatus.failed;
          effectScale = -0.25;
          priceImpact = decision.failurePriceImpactBps;
          outcome = '실행 차질로 기대했던 성과가 나오지 않아 시장 신뢰가 하락했습니다.';
        }
        final revenueBps = (decision.revenueDeltaBps * effectScale).round();
        final expenseScale = status == ListedManagementDecisionStatus.failed
            ? (decision.expenseDeltaBps >= 0 ? 0.7 : 0.25)
            : status == ListedManagementDecisionStatus.mixed
            ? 0.7
            : 1.0;
        final expenseBps = (decision.expenseDeltaBps * expenseScale).round();
        revenue = math.max(0, (revenue * (1 + revenueBps / 10000)).round());
        expense = math.max(0, (expense * (1 + expenseBps / 10000)).round());
        innovation += (decision.innovationDelta * effectScale).round();
        operations += (decision.operationsDelta * effectScale).round();
        brand += (decision.brandDelta * effectScale).round();
        workforce += (decision.workforceDelta * effectScale).round();
        if (decision.agendaId.startsWith('ceo:')) {
          ceoPerformance += switch (status) {
            ListedManagementDecisionStatus.succeeded => 4,
            ListedManagementDecisionStatus.mixed => 1,
            ListedManagementDecisionStatus.failed => -5,
            ListedManagementDecisionStatus.executing => 0,
          };
        }
        managementValueBps += priceImpact;
        decisions.add(
          decision.copyWith(
            status: status,
            outcome: outcome,
            realizedPriceImpactBps: priceImpact,
          ),
        );
        history = _appendHistory(
          history,
          '${_dateKey(state.currentDate)} ${decision.title} ${status.label} · '
          '시장평가 ${(priceImpact / 100) >= 0 ? '+' : ''}${(priceImpact / 100).toStringAsFixed(1)}%',
        );
      }
      companies[company.assetId] = company.copyWith(
        monthlyRevenue: revenue,
        monthlyExpense: expense,
        innovation: innovation,
        operations: operations,
        brandTrust: brand,
        workforce: workforce,
        ceoPerformance: ceoPerformance,
        managementValueBps: managementValueBps,
        managementDecisions: decisions,
        history: history,
      );
      changed = true;
    }
    if (!changed) return state;
    return state.copyWith(
      shareholderGovernance: state.shareholderGovernance.copyWith(
        companies: companies,
      ),
    );
  }

  List<ShareholderAgenda> _regularAgendas(
    GameState state,
    ListedCompanyGovernance company,
    int year,
  ) {
    final seed = stableHash31(
      '${state.simulationSeed}:${company.assetId}:agm:$year',
    );
    final rotating = <ShareholderAgendaType>[
      ShareholderAgendaType.capitalIncrease,
      ShareholderAgendaType.executivePay,
      ShareholderAgendaType.strategy,
      ShareholderAgendaType.labor,
      ShareholderAgendaType.assetSale,
      ShareholderAgendaType.merger,
    ];
    final types = <ShareholderAgendaType>[
      ShareholderAgendaType.dividend,
      ShareholderAgendaType.directorElection,
      rotating[seed % rotating.length],
    ];
    return <ShareholderAgenda>[
      for (var index = 0; index < types.length; index += 1)
        _agenda(
          id: 'agm-${company.assetId}-$year-$index',
          type: types[index],
          hash: stableHash31('$seed:$index'),
        ),
    ];
  }

  ShareholderAgenda _agenda({
    required String id,
    required ShareholderAgendaType type,
    required int hash,
    bool proposedByPlayer = false,
  }) => ShareholderAgenda(
    id: id,
    type: type,
    title: type.label,
    description: _agendaDescription(type, proposedByPlayer),
    baseSupportPct: proposedByPlayer
        ? 28 + (hash % 1700) / 100
        : 38 + (hash % 2500) / 100,
    requiredApprovalPct:
        type == ShareholderAgendaType.merger ||
            type == ShareholderAgendaType.assetSale
        ? 66.67
        : 50,
    proposedByPlayer: proposedByPlayer,
  );

  ShareholderAgenda _playerProposal(
    GameState state,
    ShareholderMeeting meeting,
    ShareholderAgendaType type, {
    required String suffix,
  }) => _agenda(
    id: '${meeting.id}-$suffix-${meeting.agendas.length}',
    type: type,
    hash: stableHash31(
      '${state.simulationSeed}:${meeting.id}:$suffix:${state.day}',
    ),
    proposedByPlayer: true,
  );

  ShareholderAgenda _resolveAgenda(
    ShareholderAgenda agenda,
    ListedCompanyGovernance company,
    ShareholderVoteChoice choice,
  ) {
    final own = company.ownershipPct;
    final friendly = company.friendlyVotingPct;
    final otherVotingPool = math.max(0.0, 100 - own - friendly);
    var support = agenda.baseSupportPct / 100 * otherVotingPool;
    if (choice == ShareholderVoteChoice.support) support += own + friendly;
    if (choice == ShareholderVoteChoice.oppose && agenda.proposedByPlayer) {
      support += friendly * 0.25;
    }
    support = support.clamp(0, 100).toDouble();
    return agenda.copyWith(
      vote: choice,
      finalSupportPct: support,
      passed: support >= agenda.requiredApprovalPct,
    );
  }

  String _agendaDescription(ShareholderAgendaType type, bool player) {
    final prefix = player ? '주주가 제안한' : '이사회가 상정한';
    return switch (type) {
      ShareholderAgendaType.dividend => '$prefix 이익배당 및 잉여금 처분안입니다.',
      ShareholderAgendaType.directorElection => '$prefix 이사 선임안입니다.',
      ShareholderAgendaType.executivePay => '$prefix 임원 보수 한도 승인안입니다.',
      ShareholderAgendaType.capitalIncrease => '$prefix 성장자금 조달과 신주 발행안입니다.',
      ShareholderAgendaType.merger => '$prefix 회사 합병 승인안입니다.',
      ShareholderAgendaType.audit => '$prefix 독립 감사 및 장부 열람안입니다.',
      ShareholderAgendaType.strategy => '$prefix 중장기 투자·사업 전략안입니다.',
      ShareholderAgendaType.labor => '$prefix 고용 안정과 협력사 상생안입니다.',
      ShareholderAgendaType.assetSale => '$prefix 핵심 자산 매각 승인안입니다.',
    };
  }

  int _shareholderAgendaMarketImpactBps(ShareholderAgenda agenda) {
    final passedImpact = switch (agenda.type) {
      ShareholderAgendaType.dividend => 80,
      ShareholderAgendaType.directorElection => 70,
      ShareholderAgendaType.executivePay => -50,
      ShareholderAgendaType.capitalIncrease => -120,
      ShareholderAgendaType.merger => 180,
      ShareholderAgendaType.audit => 100,
      ShareholderAgendaType.strategy => 140,
      ShareholderAgendaType.labor => 60,
      ShareholderAgendaType.assetSale => -100,
    };
    if (agenda.passed == true) {
      return passedImpact + (agenda.proposedByPlayer ? 30 : 0);
    }
    return switch (agenda.type) {
      ShareholderAgendaType.executivePay ||
      ShareholderAgendaType.capitalIncrease ||
      ShareholderAgendaType.assetSale => math.max(30, -passedImpact ~/ 2),
      _ => -math.max(30, passedImpact.abs() ~/ 2),
    };
  }

  int _boardSeatEntitlement(ListedCompanyGovernance company) {
    if (company.isControlled) return 4;
    if (company.ownershipPct >= 33.34) return 3;
    if (company.ownershipPct >= 20) return 2;
    if (company.ownershipPct >= 10) return 1;
    return 0;
  }

  DateTime _regularMeetingDate(int year, String assetId) {
    final day = 20 + stableHash31('$assetId:$year:agm-date') % 9;
    var date = DateTime(year, 3, day);
    while (date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  int _dayFor(GameState state, DateTime date) =>
      date.difference(state.campaignStartDate).inDays + 1;

  bool _meetingActionable(GameState state, ShareholderMeeting meeting) =>
      meeting.status != ShareholderMeetingStatus.closed &&
      state.day >= meeting.heldDay - 14 &&
      state.day <= meeting.deadlineDay;

  ShareholderMeeting? _meetingById(GameState state, String meetingId) {
    for (final meeting in state.shareholderGovernance.meetings) {
      if (meeting.id == meetingId) return meeting;
    }
    return null;
  }

  ShareholderMeeting? _nextMeetingFor(GameState state, String assetId) {
    final candidates =
        state.shareholderGovernance.meetings
            .where(
              (meeting) =>
                  meeting.assetId == assetId &&
                  meeting.status != ShareholderMeetingStatus.closed,
            )
            .toList()
          ..sort((left, right) => left.heldDay.compareTo(right.heldDay));
    return candidates.isEmpty ? null : candidates.first;
  }

  ShareholderGovernanceActionResult _meetingSuccess(
    GameState state,
    ShareholderMeeting meeting,
    String message,
  ) => ShareholderGovernanceActionResult(
    state: _replaceMeeting(state, meeting),
    success: true,
    message: message,
  );

  GameState _replaceMeeting(GameState state, ShareholderMeeting updated) {
    final meetings = <ShareholderMeeting>[
      ...state.shareholderGovernance.meetings,
    ];
    final index = meetings.indexWhere((meeting) => meeting.id == updated.id);
    if (index >= 0) meetings[index] = updated;
    return state.copyWith(
      shareholderGovernance: state.shareholderGovernance.copyWith(
        meetings: meetings,
      ),
    );
  }

  GameState _withCompany(GameState state, ListedCompanyGovernance company) =>
      state.copyWith(
        shareholderGovernance: state.shareholderGovernance.copyWith(
          companies: <String, ListedCompanyGovernance>{
            ...state.shareholderGovernance.companies,
            company.assetId: company,
          },
        ),
      );

  ListedManagementDecisionRecord _completedCeoDecision(
    GameState state,
    ListedCeoDirective directive, {
    required int cashCost,
    required int priceImpactBps,
    required String outcome,
  }) => ListedManagementDecisionRecord(
    id: 'ceo-${directive.name}-${state.day}',
    agendaId: 'ceo:${directive.name}:${_monthKey(state.currentDate)}',
    optionId: directive.name,
    title: 'CEO 월간 집행',
    optionLabel: directive.label,
    summary: directive.description,
    decisionDay: state.day,
    completionDay: state.day,
    cashCost: cashCost,
    revenueDeltaBps: 0,
    expenseDeltaBps: 0,
    immediatePriceImpactBps: 0,
    successPriceImpactBps: priceImpactBps,
    failurePriceImpactBps: priceImpactBps,
    innovationDelta: 0,
    operationsDelta: 0,
    brandDelta: 0,
    workforceDelta: 0,
    successChancePct: 100,
    status: ListedManagementDecisionStatus.succeeded,
    outcome: outcome,
    realizedPriceImpactBps: priceImpactBps,
  );

  ListedManagementDecisionRecord _completedMarketEvent(
    GameState state, {
    required String id,
    required String title,
    required String summary,
    required int priceImpactBps,
  }) => ListedManagementDecisionRecord(
    id: id,
    agendaId: 'market-event:$id',
    optionId: 'announced',
    title: title,
    optionLabel: '공시',
    summary: summary,
    decisionDay: state.day,
    completionDay: state.day,
    cashCost: 0,
    revenueDeltaBps: 0,
    expenseDeltaBps: 0,
    immediatePriceImpactBps: 0,
    successPriceImpactBps: priceImpactBps,
    failurePriceImpactBps: priceImpactBps,
    innovationDelta: 0,
    operationsDelta: 0,
    brandDelta: 0,
    workforceDelta: 0,
    successChancePct: 100,
    status: priceImpactBps >= 0
        ? ListedManagementDecisionStatus.succeeded
        : ListedManagementDecisionStatus.failed,
    outcome: summary,
    realizedPriceImpactBps: priceImpactBps,
  );

  List<ListedManagementDecisionRecord> _appendDecision(
    List<ListedManagementDecisionRecord> decisions,
    ListedManagementDecisionRecord decision,
  ) {
    final updated = <ListedManagementDecisionRecord>[...decisions, decision];
    return updated.length <= 256
        ? updated
        : updated.sublist(updated.length - 256);
  }

  _CeoDirectivePlan _ceoDirectivePlan(ListedCeoDirective directive) =>
      switch (directive) {
        ListedCeoDirective.researchAndDevelopment => const _CeoDirectivePlan(
          costRate: 0.16,
          durationDays: 60,
          successChancePct: 70,
          revenueDeltaBps: 800,
          expenseDeltaBps: 500,
          immediatePriceImpactBps: 250,
          successPriceImpactBps: 650,
          failurePriceImpactBps: -700,
          innovationDelta: 14,
          operationsDelta: 2,
          brandDelta: 3,
          workforceDelta: 2,
        ),
        ListedCeoDirective.salesAndBrand => const _CeoDirectivePlan(
          costRate: 0.10,
          durationDays: 45,
          successChancePct: 78,
          revenueDeltaBps: 700,
          expenseDeltaBps: 250,
          immediatePriceImpactBps: 160,
          successPriceImpactBps: 420,
          failurePriceImpactBps: -350,
          innovationDelta: 1,
          operationsDelta: 2,
          brandDelta: 12,
          workforceDelta: 1,
        ),
        ListedCeoDirective.automation => const _CeoDirectivePlan(
          costRate: 0.14,
          durationDays: 60,
          successChancePct: 75,
          revenueDeltaBps: 250,
          expenseDeltaBps: -750,
          immediatePriceImpactBps: 100,
          successPriceImpactBps: 500,
          failurePriceImpactBps: -500,
          innovationDelta: 4,
          operationsDelta: 15,
          brandDelta: 1,
          workforceDelta: -5,
        ),
        ListedCeoDirective.talentAndCulture => const _CeoDirectivePlan(
          costRate: 0.09,
          durationDays: 45,
          successChancePct: 82,
          revenueDeltaBps: 300,
          expenseDeltaBps: 350,
          immediatePriceImpactBps: 90,
          successPriceImpactBps: 330,
          failurePriceImpactBps: -250,
          innovationDelta: 6,
          operationsDelta: 3,
          brandDelta: 3,
          workforceDelta: 14,
        ),
        ListedCeoDirective.globalExpansion => const _CeoDirectivePlan(
          costRate: 0.20,
          durationDays: 75,
          successChancePct: 62,
          revenueDeltaBps: 1400,
          expenseDeltaBps: 700,
          immediatePriceImpactBps: 300,
          successPriceImpactBps: 800,
          failurePriceImpactBps: -900,
          innovationDelta: 5,
          operationsDelta: 3,
          brandDelta: 10,
          workforceDelta: 4,
        ),
        ListedCeoDirective.compliance => const _CeoDirectivePlan(
          costRate: 0.07,
          durationDays: 40,
          successChancePct: 90,
          revenueDeltaBps: 120,
          expenseDeltaBps: 250,
          immediatePriceImpactBps: 40,
          successPriceImpactBps: 240,
          failurePriceImpactBps: -180,
          innovationDelta: 1,
          operationsDelta: 8,
          brandDelta: 8,
          workforceDelta: 5,
        ),
        ListedCeoDirective.debtReduction ||
        ListedCeoDirective.shareholderReturn => const _CeoDirectivePlan(
          costRate: 0,
          durationDays: 1,
          successChancePct: 100,
          revenueDeltaBps: 0,
          expenseDeltaBps: 0,
          immediatePriceImpactBps: 0,
          successPriceImpactBps: 0,
          failurePriceImpactBps: 0,
          innovationDelta: 0,
          operationsDelta: 0,
          brandDelta: 0,
          workforceDelta: 0,
        ),
      };

  String _monthKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  ShareholderGovernanceActionResult _failure(GameState state, String message) =>
      ShareholderGovernanceActionResult(
        state: state,
        success: false,
        message: message,
      );

  List<String> _appendHistory(List<String> history, String entry) {
    final updated = <String>[...history, entry];
    return updated.length <= 24
        ? updated
        : updated.sublist(updated.length - 24);
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _won(int amount) => '${_number(amount)}원';

  String _number(num value) {
    final digits = value.round().abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index += 1) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return '${value < 0 ? '-' : ''}$buffer';
  }
}
