import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/shareholder_governance.dart';
import 'package:millennium_capital/game/shareholder_governance_engine.dart';

import 'support/market_fixture.dart';

void main() {
  const game = GameEngine();
  const governance = ShareholderGovernanceEngine();

  GameState stateWithStake(double shares, {int cash = 20000000000}) {
    final base = game.createNewGame(
      '주주권 테스트',
      worldSeed: 'shareholder-governance-test',
    );
    return base.copyWith(
      cash: cash,
      brokerageCash: 0,
      positions: <PortfolioPosition>[
        PortfolioPosition(
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: 'KSE',
          currency: 'KRW',
          units: shares,
          totalCost: (shares * 5000).round(),
        ),
      ],
    );
  }

  int dayFor(GameState state, DateTime date) =>
      date.difference(state.campaignStartDate).inDays + 1;

  test('실제 보유주식과 발행주식수로 모든 주주권 임계값을 계산한다', () {
    final universe = testMarketUniverse();
    final expectations = <(double, ShareholderRight?)>[
      (1, ShareholderRight.attendMeeting),
      (1, ShareholderRight.submitQuestion),
      (10000, ShareholderRight.submitProposal),
      (30000, ShareholderRight.nominateDirector),
      (50000, ShareholderRight.requestAudit),
      (50000, ShareholderRight.publishShareholderLetter),
      (100000, ShareholderRight.solicitProxies),
      (200000, ShareholderRight.launchTenderOffer),
      (510000, ShareholderRight.appointCeo),
      (670000, ShareholderRight.approveMajorRestructuring),
    ];

    for (final row in expectations) {
      final synced = governance.sync(stateWithStake(row.$1), universe);
      final company = synced.shareholderGovernance.companyById(
        'hanbit_telecom',
      )!;
      expect(company.ownedShares, row.$1);
      expect(company.sharesOutstanding, 1000000);
      expect(company.rights, contains(row.$2));
    }
  });

  test('주주총회 참석, 주주제안, 표결, 이사 선임이 저장 상태를 바꾼다', () {
    final universe = testMarketUniverse();
    var state = stateWithStake(400000);
    state = state.copyWith(day: dayFor(state, DateTime(2000, 3, 20)));
    state = governance.processDay(state, universe);
    final meeting = state.shareholderGovernance
        .meetingsFor('hanbit_telecom')
        .firstWhere((item) => item.status != ShareholderMeetingStatus.closed);

    final attended = governance.attendMeeting(state, meeting.id);
    expect(attended.success, isTrue);
    state = attended.state;

    final proposed = governance.nominateDirector(state, 'hanbit_telecom');
    expect(proposed.success, isTrue);
    state = proposed.state;
    final updatedMeeting = state.shareholderGovernance
        .meetingsFor('hanbit_telecom')
        .firstWhere((item) => item.id == meeting.id);
    final directorAgenda = updatedMeeting.agendas.lastWhere(
      (item) =>
          item.proposedByPlayer &&
          item.type == ShareholderAgendaType.directorElection,
    );
    final beforeSeats = state.shareholderGovernance
        .companyById('hanbit_telecom')!
        .boardSeats;
    final voted = governance.vote(
      state,
      meetingId: meeting.id,
      agendaId: directorAgenda.id,
      choice: ShareholderVoteChoice.support,
    );

    expect(voted.success, isTrue);
    expect(
      voted.state.shareholderGovernance
          .companyById('hanbit_telecom')!
          .priceMultiplierAt(state.day),
      1,
    );
    expect(
      voted.state.shareholderGovernance
          .companyById('hanbit_telecom')!
          .priceMultiplierAt(state.day + 1),
      isNot(1),
    );
    expect(
      voted.state.shareholderGovernance
          .companyById('hanbit_telecom')!
          .boardSeats,
      beforeSeats + 1,
    );
    expect(voted.message, contains('가결'));
  });

  test('5% 주주의 감사 요구는 일반 주주제안과 별도로 접수된다', () {
    final universe = testMarketUniverse();
    var state = governance.processDay(stateWithStake(50000), universe);
    final proposal = governance.submitProposal(
      state,
      assetId: 'hanbit_telecom',
      type: ShareholderAgendaType.strategy,
    );
    expect(proposal.success, isTrue);
    state = proposal.state;

    final audit = governance.requestAudit(state, 'hanbit_telecom');
    expect(audit.success, isTrue);
    final playerAgendas = audit.state.shareholderGovernance
        .meetingsFor('hanbit_telecom')
        .first
        .agendas
        .where((agenda) => agenda.proposedByPlayer)
        .toList();
    expect(
      playerAgendas.map((agenda) => agenda.type),
      containsAll(<Object>[
        ShareholderAgendaType.strategy,
        ShareholderAgendaType.audit,
      ]),
    );
  });

  test('20% 주주가 공개매수로 실제 주식과 경영권을 취득한다', () {
    final universe = testMarketUniverse();
    var state = governance.processDay(stateWithStake(200000), universe);
    final asset = universe.assets.first;
    final result = governance.launchTenderOffer(
      state,
      asset: asset,
      targetOwnershipPct: 51,
      premiumBps: 2500,
    );

    expect(result.success, isTrue);
    state = result.state;
    final company = state.shareholderGovernance.companyById('hanbit_telecom')!;
    expect(company.ownershipPct, greaterThanOrEqualTo(51));
    expect(company.isControlled, isTrue);
    expect(company.acquiredControlDay, state.day);
    expect(company.boardSeats, greaterThanOrEqualTo(4));
    expect(state.positions.single.units, greaterThanOrEqualTo(510000));
    expect(
      state.ledger.any((entry) => entry.tradeSide == 'tender_buy'),
      isTrue,
    );
  });

  test('공개매수는 발행주식을 넘기는 미체결 매수를 최신 주문부터 정리한다', () {
    final universe = testMarketUniverse();
    var state = governance.processDay(stateWithStake(200000), universe);
    final dateKey = state.currentDate.toIso8601String().split('T').first;
    state = state.copyWith(
      pendingOrders: <PendingTradeOrder>[
        PendingTradeOrder(
          id: 'pending-before-tender',
          side: PendingOrderSide.buy,
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: 'KSE',
          currency: 'KRW',
          limitPrice: 5000,
          originalQuantity: 800000,
          remainingQuantity: 800000,
          placedDate: dateKey,
          placedMinute: 600,
          placedSequence: 1,
          maximumPositionUnits: 1000000,
        ),
      ],
    );

    final result = governance.launchTenderOffer(
      state,
      asset: universe.assets.first,
      targetOwnershipPct: 51,
      premiumBps: 2500,
    );

    expect(result.success, isTrue);
    final company = result.state.shareholderGovernance.companyById(
      'hanbit_telecom',
    )!;
    expect(
      company.ownedShares +
          result.state.pendingBuyReservedUnits('hanbit_telecom'),
      lessThanOrEqualTo(company.sharesOutstanding),
    );
    expect(company.tenderAcquiredShares, greaterThan(0));
    final tenderEntry = result.state.ledger.lastWhere(
      (entry) => entry.tradeSide == 'tender_buy',
    );
    expect(tenderEntry.tradeQuantity, company.tenderAcquiredShares);
    expect(
      result.state.ledger.any(
        (entry) => entry.counterAccount == 'tender_position_limit',
      ),
      isTrue,
    );
    final restored = ListedCompanyGovernance.fromJson(company.toJson());
    expect(restored.tenderAcquiredShares, company.tenderAcquiredShares);
  });

  test('유상증자 희석 또는 매도로 의결권 과반이 깨지면 경영권을 상실한다', () {
    final original = testMarketUniverse();
    var state = governance.processDay(stateWithStake(600000), original);
    expect(
      state.shareholderGovernance.companyById('hanbit_telecom')!.isControlled,
      isTrue,
    );

    final source = original.assets.first;
    final diluted = FictionalMarketUniverse(
      schemaVersion: 14,
      sourceName: 'dilution-test',
      assets: <FictionalMarketAsset>[
        FictionalMarketAsset(
          id: source.id,
          symbol: source.symbol,
          name: source.name,
          market: source.market,
          country: source.country,
          sector: source.sector,
          colorHex: source.colorHex,
          currency: source.currency,
          initialSharesOutstanding: 2000000,
          prices: const <String, double>{
            '1999-12-30': 5920,
            '2000-01-03': 6110,
          },
        ),
      ],
    );
    state = governance.sync(state, diluted);
    final company = state.shareholderGovernance.companyById('hanbit_telecom')!;
    expect(company.ownershipPct, 30);
    expect(company.isControlled, isFalse);
    expect(company.lostControlDay, state.day);
    expect(company.history.last, contains('경영권 상실'));
  });

  test('복수 상장사를 자회사로 보유하고 월별 영업·배당·JSON을 보존한다', () {
    final universe = testMarketUniverse(includeKnownPartner: true);
    var state = stateWithStake(600000);
    state = state.copyWith(
      positions: <PortfolioPosition>[
        ...state.positions,
        const PortfolioPosition(
          assetId: 'widget_partner',
          symbol: '1002',
          name: '테스트부품',
          market: 'KSE',
          currency: 'KRW',
          units: 300000,
          totalCost: 100000000,
        ),
      ],
    );
    state = governance.processDay(state, universe);
    expect(state.shareholderGovernance.controlledCompanies, hasLength(2));

    for (final company in state.shareholderGovernance.controlledCompanies) {
      final result = governance.setOperatingPolicy(
        state,
        assetId: company.assetId,
        policy: SubsidiaryOperatingPolicy.dividend,
      );
      expect(result.success, isTrue);
      state = result.state;
    }
    state = state.copyWith(day: dayFor(state, DateTime(2000, 2, 1)));
    state = governance.processDay(state, universe);

    expect(
      state.shareholderGovernance.controlledCompanies.every(
        (company) => company.lastOperationsMonth == '2000-02',
      ),
      isTrue,
    );
    final restored = GameState.fromJson(state.toJson());
    expect(restored.shareholderGovernance.controlledCompanies, hasLength(2));
    expect(
      restored.shareholderGovernance.toJson(),
      state.shareholderGovernance.toJson(),
    );
    expect(GameState.schemaVersion, 27);
  });

  test('주주행동 공시는 당일 가격을 소급 변경하지 않고 다음 날부터 반영된다', () {
    final universe = testMarketUniverse();
    var state = governance.processDay(stateWithStake(50000), universe);
    final before = state.shareholderGovernance.companyById('hanbit_telecom')!;
    final result = governance.askManagementQuestion(state, 'hanbit_telecom');

    expect(result.success, isTrue);
    final after = result.state.shareholderGovernance.companyById(
      'hanbit_telecom',
    )!;
    expect(
      after.priceMultiplierAt(state.day),
      before.priceMultiplierAt(state.day),
    );
    expect(
      after.priceMultiplierAt(state.day + 1),
      greaterThan(after.priceMultiplierAt(state.day)),
    );
  });

  test('지배주주는 CEO로 취임해 월간 집행을 내리고 성과와 저장을 남긴다', () {
    final universe = testMarketUniverse();
    var state = governance.processDay(stateWithStake(600000), universe);

    final appointment = governance.appointPlayerAsCeo(state, 'hanbit_telecom');
    expect(appointment.success, isTrue);
    state = appointment.state;
    expect(
      state.shareholderGovernance.companyById('hanbit_telecom')!.playerIsCeo,
      isTrue,
    );

    final directive = governance.executeCeoDirective(
      state,
      assetId: 'hanbit_telecom',
      directive: ListedCeoDirective.researchAndDevelopment,
    );
    expect(directive.success, isTrue);
    state = directive.state;
    final company = state.shareholderGovernance.companyById('hanbit_telecom')!;
    expect(company.lastCeoActionMonth, '2000-01');
    expect(
      company.managementDecisions.any(
        (decision) =>
            decision.agendaId.startsWith('ceo:') && decision.isExecuting,
      ),
      isTrue,
    );
    expect(company.priceMultiplierAt(state.day), 1);
    expect(company.priceMultiplierAt(state.day + 1), greaterThan(1));

    final restored = GameState.fromJson(state.toJson());
    final restoredCompany = restored.shareholderGovernance.companyById(
      'hanbit_telecom',
    )!;
    expect(restoredCompany.playerIsCeo, isTrue);
    expect(restoredCompany.lastCeoActionMonth, '2000-01');
  });

  test('CEO는 두 특별결의 지배회사의 합병을 추진하고 다음 날 주가에 공시를 반영한다', () {
    final universe = testMarketUniverse(includeKnownPartner: true);
    var state = stateWithStake(700000);
    state = state.copyWith(
      positions: <PortfolioPosition>[
        ...state.positions,
        const PortfolioPosition(
          assetId: 'widget_partner',
          symbol: '1002',
          name: '테스트 부품',
          market: 'KSE',
          currency: 'KRW',
          units: 350000,
          totalCost: 100000000,
        ),
      ],
    );
    state = governance.processDay(state, universe);
    state = governance.appointPlayerAsCeo(state, 'hanbit_telecom').state;
    final before = state.shareholderGovernance.companyById('hanbit_telecom')!;

    final merger = governance.startCorporateAction(
      state,
      leadAssetId: 'hanbit_telecom',
      type: ListedCorporateActionType.merger,
      partnerAssetId: 'widget_partner',
      mergerStructure: ListedMergerStructure.absorption,
    );

    expect(merger.success, isTrue);
    state = merger.state;
    final action = state.shareholderGovernance.corporateActions.single;
    expect(action.type, ListedCorporateActionType.merger);
    expect(action.strategy, '흡수합병');
    expect(action.isExecuting, isTrue);
    final announced = state.shareholderGovernance.companyById(
      'hanbit_telecom',
    )!;
    expect(
      announced.priceMultiplierAt(state.day),
      before.priceMultiplierAt(state.day),
    );
    expect(
      announced.priceMultiplierAt(state.day + 1),
      greaterThan(announced.priceMultiplierAt(state.day)),
    );
    state = governance.processDay(
      state.copyWith(day: action.completionDay),
      universe,
    );
    final settledAction = state.shareholderGovernance.corporateActions.single;
    final settledCompany = state.shareholderGovernance.companyById(
      'hanbit_telecom',
    )!;
    expect(settledAction.isExecuting, isFalse);
    expect(settledAction.outcome, isNotEmpty);
    expect(
      settledCompany.priceMultiplierAt(action.completionDay + 1),
      isNot(settledCompany.priceMultiplierAt(action.completionDay)),
    );
    final restored = GameState.fromJson(state.toJson());
    expect(
      restored.shareholderGovernance.corporateActions.single.strategy,
      '흡수합병',
    );
  });

  test('과반만 확보한 CEO는 특별결의 지분 전까지 합병할 수 없다', () {
    final universe = testMarketUniverse(includeKnownPartner: true);
    var state = stateWithStake(600000);
    state = state.copyWith(
      positions: <PortfolioPosition>[
        ...state.positions,
        const PortfolioPosition(
          assetId: 'widget_partner',
          symbol: '1002',
          name: '테스트 부품',
          market: 'KSE',
          currency: 'KRW',
          units: 300000,
          totalCost: 100000000,
        ),
      ],
    );
    state = governance.processDay(state, universe);
    state = governance.appointPlayerAsCeo(state, 'hanbit_telecom').state;
    final merger = governance.startCorporateAction(
      state,
      leadAssetId: 'hanbit_telecom',
      type: ListedCorporateActionType.merger,
      partnerAssetId: 'widget_partner',
    );

    expect(merger.success, isFalse);
    expect(merger.message, contains('66.67%'));
    expect(merger.state.shareholderGovernance.corporateActions, isEmpty);
  });

  test('v26 저장은 빈 주주권 상태로 이관되고 보유주식에서 안전하게 재구성된다', () {
    final universe = testMarketUniverse();
    final original = stateWithStake(100000);
    final legacy = original.toJson()
      ..remove('shareholderGovernance')
      ..['version'] = 26;

    final migrated = game.migrate(legacy);
    expect(migrated.version, 27);
    expect(migrated.shareholderGovernance.companies, isEmpty);

    final rebuilt = governance.processDay(migrated, universe);
    expect(
      rebuilt.shareholderGovernance.companyById('hanbit_telecom')!.ownershipPct,
      10,
    );
  });
}
