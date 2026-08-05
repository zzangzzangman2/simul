import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/listed_company_management.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_quote.dart';
import 'package:millennium_capital/game/shareholder_governance.dart';
import 'package:millennium_capital/game/shareholder_governance_engine.dart';

import 'support/market_fixture.dart';

void main() {
  const game = GameEngine();
  const engine = ShareholderGovernanceEngine();

  GameState controlledState() {
    final base = game.createNewGame(
      '업종별 경영 테스트',
      worldSeed: 'listed-company-management-test',
    );
    return base.copyWith(
      cash: 20000000000,
      brokerageCash: 0,
      positions: const <PortfolioPosition>[
        PortfolioPosition(
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: 'KSE',
          currency: 'KRW',
          units: 600000,
          totalCost: 3000000000,
        ),
      ],
    );
  }

  test('고정 상장사의 모든 업종에 전용 경영 플레이북과 회사별 선택지가 있다', () {
    final sectors = fixedFictionalCompanies
        .map((company) => company.sector)
        .toSet();
    expect(
      sectors.difference(ListedCompanyManagementCatalog.supportedSectors),
      isEmpty,
    );

    for (final definition in fixedFictionalCompanies) {
      final asset = FictionalMarketAsset(
        id: definition.id,
        symbol: definition.symbol,
        name: definition.name,
        market: definition.market,
        country: 'KR',
        sector: definition.sector,
        colorHex: definition.colorHex,
        currency: 'KRW',
        initialSharesOutstanding: 1000000,
        prices: const <String, double>{'2000-01-03': 5000},
        products: definition.products,
        summary: definition.summary,
        question: definition.question,
      );
      final company = ListedCompanyGovernance(
        assetId: definition.id,
        symbol: definition.symbol,
        name: definition.name,
        market: definition.market,
        sharesOutstanding: 1000000,
        ownedShares: 600000,
        friendlyVotingPct: 0,
        rivalVotingPct: 10,
        boardSeats: 4,
        lastSyncedDay: 1,
        subsidiaryCash: 1000000000,
        subsidiaryDebt: 0,
        monthlyRevenue: 100000000,
        monthlyExpense: 85000000,
        retainedEarnings: 0,
        cumulativeDistribution: 0,
        operatingPolicy: SubsidiaryOperatingPolicy.growth,
        leadershipModel: SubsidiaryLeadershipModel.professionalCeo,
        lastOperationsMonth: '',
        history: const <String>[],
        sector: definition.sector,
        products: definition.products,
      );
      final agenda = ListedCompanyManagementCatalog.agendaFor(
        asset,
        company,
        DateTime(2000, 1, 3),
      );
      expect(agenda.options, hasLength(3), reason: definition.name);
      expect(
        agenda.options.map((option) => option.label).toSet(),
        hasLength(3),
        reason: definition.name,
      );
      final companySpecificText = <String>[
        agenda.title,
        agenda.question,
        agenda.context,
        ...agenda.options.map((option) => option.description),
      ].join(' ');
      expect(
        companySpecificText.contains(definition.name) ||
            definition.products.any(companySpecificText.contains),
        isTrue,
        reason: '${definition.name} 안건이 회사 데이터와 연결되어야 합니다.',
      );
    }
  });

  test('이사회 결정 공시는 다음 날 실제 매매가격에 시장 기대가 반영된다', () {
    final universe = testMarketUniverse();
    var state = engine.processDay(controlledState(), universe);
    final asset = universe.assets.first;
    final before = resolveMarketTradeQuote(universe, state, asset.id)!;

    final result = engine.executeManagementDecision(
      state,
      asset: asset,
      optionId: 'aggressive',
    );
    expect(result.success, isTrue);
    state = result.state;
    final after = resolveMarketTradeQuote(universe, state, asset.id)!;
    final company = state.shareholderGovernance.companyById(asset.id)!;

    expect(after.unitPrice, before.unitPrice);
    expect(company.priceMultiplierAt(state.day), 1);
    expect(company.priceMultiplierAt(state.day + 1), closeTo(1.032, 0.000001));
    final nextDayState = state.copyWith(day: state.day + 1);
    final nextDayQuote = resolveMarketTradeQuote(
      universe,
      nextDayState,
      asset.id,
    )!;
    final rawNextDay = asset.quoteAtOrBefore(nextDayState.currentDate)!.close;
    expect(nextDayQuote.unitPrice, closeTo(rawNextDay * 1.032, 0.01));
    expect(company.subsidiaryCash, lessThan(800000000));
    expect(company.managementDecisions.single.isExecuting, isTrue);
    expect(company.lastManagementQuarter, '2000-Q1');
  });

  test('실행 종료일에 결과가 실적 KPI 장기 주가평가에 확정되고 저장된다', () {
    final universe = testMarketUniverse();
    var state = engine.processDay(controlledState(), universe);
    final asset = universe.assets.first;
    state = engine
        .executeManagementDecision(state, asset: asset, optionId: 'focused')
        .state;
    final before = state.shareholderGovernance.companyById(asset.id)!;
    final completionDay = before.managementDecisions.single.completionDay;

    state = engine.processDay(state.copyWith(day: completionDay), universe);
    final after = state.shareholderGovernance.companyById(asset.id)!;
    final decision = after.managementDecisions.single;

    expect(decision.isExecuting, isFalse);
    expect(decision.outcome, isNotEmpty);
    expect(after.monthlyRevenue, isNot(before.monthlyRevenue));
    expect(after.managementValueBps, decision.realizedPriceImpactBps);
    expect(
      after.priceMultiplierAt(completionDay + 1),
      closeTo(1 + decision.realizedPriceImpactBps / 10000, 0.000001),
    );

    final restored = GameState.fromJson(state.toJson());
    expect(
      restored.shareholderGovernance.companyById(asset.id)!.toJson(),
      after.toJson(),
    );
  });

  test('같은 분기에는 회사별 핵심 경영결정을 한 번만 내릴 수 있다', () {
    final universe = testMarketUniverse();
    var state = engine.processDay(controlledState(), universe);
    final asset = universe.assets.first;
    final first = engine.executeManagementDecision(
      state,
      asset: asset,
      optionId: 'defensive',
    );
    expect(first.success, isTrue);
    state = first.state;

    final second = engine.executeManagementDecision(
      state,
      asset: asset,
      optionId: 'aggressive',
    );
    expect(second.success, isFalse);
    expect(second.message, contains('이미 결정'));
  });
}
