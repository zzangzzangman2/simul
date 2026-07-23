import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/seed_money_content.dart';
import 'package:millennium_capital/game/story_state.dart';

void main() {
  const engine = GameEngine();

  GameState resolveFirst(GameState state, String optionId) {
    return engine.resolveDecision(
      state,
      state.pendingDecisions.first.id,
      optionId,
    );
  }

  test('new game starts as a guardian-approved family research desk', () {
    final story = StoryState.newPlayer(
      playerName: '민준',
      introChoice: 'computer',
      startingTrait: StoryTrait.analysis,
      familyRule: FamilyRule.reportLosses,
    );
    final state = engine.createNewGame('별빛', story: story);

    expect(state.version, GameState.schemaVersion);
    expect(state.story.playerName, '민준');
    expect(state.cash, initialCompanyCash);
    expect(state.story.guardianAccountHolder, 'mother');
    expect(state.story.storyFlags['guardianConsent'], isTrue);
    expect(state.story.storyFlags['isLegalCompany'], isFalse);
    expect(state.pendingDecisions.first.id, 'first-research-note');
  });

  test('first research choice changes trust and is applied only once', () {
    var state = engine.createNewGame('조사 연구소');
    final decisionId = state.pendingDecisions.first.id;
    final trustBefore = state.story.familyTrust;
    state = engine.resolveDecision(state, decisionId, 'research_cashflow');
    final afterFirst = state;
    state = engine.resolveDecision(state, decisionId, 'research_cashflow');

    expect(afterFirst.story.familyTrust, trustBefore + 1);
    expect(afterFirst.story.storyFlags['firstResearchFocus'], 'cashflow');
    expect(state.toJson(), afterFirst.toJson());
  });

  test('new games start with Hanbit Telecom in a fictional world', () {
    final state = engine.createNewGame(
      '테스트 연구소',
      worldSeed: 'fictional-start-fixture',
    );

    expect(state.company.id, 'hanbit_telecom');
    expect(state.company.name, '한빛통신');
    expect(state.company.worldMode, CompanyWorldMode.fictional);
    expect(state.company.worldStartedAtDay, 1);
    expect(state.simulationSeed, 'fictional-start-fixture');
  });

  test('same world seed produces the same hidden future', () async {
    final first = engine.createNewGame('같은 연구소', worldSeed: 'same-world-seed');
    final second = engine.createNewGame('같은 연구소', worldSeed: 'same-world-seed');
    final firstUniverse = await FictionalMarketUniverse.load(
      seed: first.simulationSeed,
    );
    final secondUniverse = await FictionalMarketUniverse.load(
      seed: second.simulationSeed,
    );
    final firstHanbit = firstUniverse.assets.firstWhere(
      (asset) => asset.id == 'hanbit_telecom',
    );
    final secondHanbit = secondUniverse.assets.firstWhere(
      (asset) => asset.id == 'hanbit_telecom',
    );

    expect(
      first.story.storyFlags['hiddenMarketScenario'],
      second.story.storyFlags['hiddenMarketScenario'],
    );
    expect(
      firstUniverse.assets.map((asset) => asset.name),
      secondUniverse.assets.map((asset) => asset.name),
    );
    expect(
      firstHanbit.quoteAtOrBefore(first.currentDate)?.close,
      secondHanbit.quoteAtOrBefore(second.currentDate)?.close,
    );
  });

  test('daily report reveals signals once without exposing outcomes', () {
    final state = engine.createNewGame(
      '보고서 연구소',
      initialCash: 5000,
      worldSeed: 'report-world-seed',
    );
    final purchased = engine.purchaseDailyMarketReport(state);
    final repeated = engine.purchaseDailyMarketReport(purchased.state);
    final reports =
        purchased.state.story.storyFlags['dailyMarketReports'] as Map;
    final items = reports[marketDateKey(state.currentDate)] as List;

    expect(purchased.success, isTrue);
    expect(purchased.state.cash, 5000 - dailyMarketReportPrice);
    expect(items, isNotEmpty);
    expect(items.toString(), isNot(contains('impactPct')));
    expect(items.toString(), isNot(contains('success')));
    expect(repeated.success, isFalse);
    expect(repeated.state.toJson(), purchased.state.toJson());
  });

  test('family helper fatigue, daily limit, and recovery are persisted', () {
    var state = engine.createNewGame('가족 연구소');
    state = resolveFirst(state, 'research_products');
    final motherBefore = state.organization.familyHelpers.first;

    state = engine.requestFamilyHelp(state, 'mother');
    final afterHelp = state.organization.familyHelpers.first;
    expect(afterHelp.fatigue, motherBefore.fatigue + 12);
    expect(afterHelp.helpCount, 1);
    expect(state.organization.helpLog, hasLength(1));

    final duplicate = engine.requestFamilyHelp(state, 'mother');
    expect(duplicate.toJson(), state.toJson());

    state = engine.advanceOneDay(state);
    final afterRest = state.organization.familyHelpers.first;
    expect(afterRest.fatigue, afterHelp.fatigue - 3);
  });
  test(
    'work sessions earn period-scale cash, write ledger, and stop at three per day',
    () {
      var state = engine.createNewGame('0원 연구소', initialCash: 0);
      expect(state.cash, 0);

      state = engine.completeWorkSession(
        state,
        const WorkSessionResult(
          activityId: 'dishes',
          score: 100,
          maxScore: 100,
        ),
      );
      expect(state.cash, 880);
      expect(state.ledger.last.counterAccount, 'work_income');
      expect(state.story.storyFlags['earnedSeedMoney'], 880);

      state = engine.completeWorkSession(
        state,
        const WorkSessionResult(
          activityId: 'stationery',
          score: 100,
          maxScore: 100,
        ),
      );
      state = engine.completeWorkSession(
        state,
        const WorkSessionResult(
          activityId: 'flea_market',
          score: 100,
          maxScore: 100,
        ),
      );
      final afterThree = state;
      state = engine.completeWorkSession(
        state,
        const WorkSessionResult(
          activityId: 'dishes',
          score: 100,
          maxScore: 100,
        ),
      );

      expect(state.toJson(), afterThree.toJson());
      expect(state.story.storyFlags['workSessionsToday'], 3);
      expect(state.cash, 3740);
    },
  );
  test('v1 save migrates without deleting company, cash, day, or story', () {
    final state = engine.migrate({
      'version': 1,
      'companyName': '옛 저장 연구소',
      'day': 17,
      'cash': 765432,
      'team': 2,
    });

    expect(state.version, GameState.schemaVersion);
    expect(state.companyName, '옛 저장 연구소');
    expect(state.day, 17);
    expect(state.cash, 765432);
    expect(state.team, 2);
    expect(state.story.playerName, '소년');
    expect(state.story.storyFlags['guardianConsent'], isTrue);
  });

  TradeOrder hanbitOrder({
    required TradeSide side,
    required double quantity,
    double unitPrice = 10000,
    String quoteDate = '2000-01-04',
  }) => TradeOrder(
    side: side,
    assetId: 'hanbit_telecom',
    symbol: '1001',
    name: '한빛통신',
    market: fictionalMainMarket,
    currency: 'KRW',
    quantity: quantity,
    unitPrice: unitPrice,
    quoteDate: quoteDate,
    marketMinute: 9 * 60,
    isTradingDay: true,
  );

  test(
    'buy debits the quoted current price plus fee and persists a position',
    () {
      final state = engine
          .createNewGame('거래 연구소', initialCash: 200000)
          .copyWith(day: 4, marketMinute: 9 * 60);
      final result = engine.executeTrade(
        state,
        hanbitOrder(side: TradeSide.buy, quantity: 10),
      );

      expect(result.success, isTrue);
      expect(result.notional, 100000);
      expect(result.fee, 250);
      expect(result.state.cash, 99750);
      expect(result.state.brokerageCash, 99750);
      expect(result.state.positions.single.units, 10);
      expect(result.state.positions.single.totalCost, 100250);
      expect(result.state.ledger.last.amount, -100250);
      expect(result.state.ledger.last.counterAccount, 'market_security');
      expect(
        result.state.portfolioValue(const {'hanbit_telecom': 11000}),
        110000,
      );
      expect(result.state.totalAum(const {'hanbit_telecom': 11000}), 209750);
      final restored = GameState.fromJson(result.state.toJson());
      expect(restored.positions.single.units, 10);
      expect(restored.positions.single.totalCost, 100250);
    },
  );

  test('sell credits proceeds after fee and reduces units and cost basis', () {
    var state = engine
        .createNewGame('매도 연구소', initialCash: 200000)
        .copyWith(day: 4, marketMinute: 9 * 60);
    state = engine
        .executeTrade(state, hanbitOrder(side: TradeSide.buy, quantity: 10))
        .state;
    final result = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.sell, quantity: 4, unitPrice: 11000),
    );

    expect(result.success, isTrue);
    expect(result.fee, 110);
    expect(result.state.cash, 143640);
    expect(result.state.brokerageCash, 143640);
    expect(result.state.positions.single.units, 6);
    expect(result.state.positions.single.totalCost, 60150);
    expect(result.state.ledger.last.amount, 43890);
    expect(result.realizedPnl, 3790);
    expect(result.state.ledger.last.disposedCost, 40100);
    expect(result.state.ledger.last.realizedPnl, 3790);
  });

  test('deposit and withdrawal move cash without changing total assets', () {
    final state = engine
        .createNewGame('증권 이체 연구소', initialCash: 100000)
        .copyWith(day: 4, marketMinute: 9 * 60, brokerageCash: 20000);

    expect(state.bankCash, 80000);
    final deposit = engine.transferBrokerageCash(
      state,
      amount: 50000,
      deposit: true,
    );
    expect(deposit.success, isTrue);
    expect(deposit.state.cash, 100000);
    expect(deposit.state.brokerageCash, 70000);
    expect(deposit.state.bankCash, 30000);
    expect(deposit.state.ledger.last.amount, 0);
    expect(deposit.state.ledger.last.notional, 50000);

    final withdrawal = engine.transferBrokerageCash(
      deposit.state,
      amount: 30000,
      deposit: false,
    );
    expect(withdrawal.success, isTrue);
    expect(withdrawal.state.cash, 100000);
    expect(withdrawal.state.brokerageCash, 40000);
    expect(withdrawal.state.bankCash, 60000);

    final excess = engine.transferBrokerageCash(
      withdrawal.state,
      amount: 50000,
      deposit: false,
    );
    expect(excess.success, isFalse);
    expect(excess.state.toJson(), withdrawal.state.toJson());

    final buyWithoutEnoughDeposit = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.buy, quantity: 3),
    );
    expect(buyWithoutEnoughDeposit.success, isFalse);
    expect(buyWithoutEnoughDeposit.message, contains('예수금'));
  });

  test('insufficient cash rejects a buy without mutating state', () {
    final state = engine
        .createNewGame('현금 부족 연구소', initialCash: 10000)
        .copyWith(day: 4, marketMinute: 9 * 60);
    final result = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.buy, quantity: 2),
    );

    expect(result.success, isFalse);
    expect(result.message, contains('예수금'));
    expect(result.state.toJson(), state.toJson());
  });

  test('invalid quantity, closed session, and excess sell are rejected', () {
    final state = engine
        .createNewGame('검증 연구소', initialCash: 200000)
        .copyWith(day: 4, marketMinute: 9 * 60);
    final invalidQuantity = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.buy, quantity: 0),
    );
    final closed = engine.executeTrade(
      state.copyWith(marketMinute: 20 * 60),
      TradeOrder(
        side: TradeSide.buy,
        assetId: 'hanbit_telecom',
        symbol: '1001',
        name: '한빛통신',
        market: fictionalMainMarket,
        currency: 'KRW',
        quantity: 1,
        unitPrice: 10000,
        quoteDate: '2000-01-04',
        marketMinute: 20 * 60,
        isTradingDay: true,
      ),
    );
    final excessSell = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.sell, quantity: 1),
    );

    expect(invalidQuantity.success, isFalse);
    expect(closed.success, isFalse);
    expect(excessSell.success, isFalse);
    expect(excessSell.message, contains('보유'));
    expect(state.positions, isEmpty);
  });

  test(
    'React v3 date, fractional positions, cash, and team migrate to v14',
    () {
      final state = engine.migrate({
        'version': 3,
        'companyName': '웹 저장 연구소',
        'currentDate': '2000-01-05',
        'cash': 765432,
        'team': 3,
        'positions': {
          'hanbit_telecom': {'units': 2.5, 'cost': 15000},
        },
      });

      expect(state.version, GameState.schemaVersion);
      expect(GameState.schemaVersion, 14);
      expect(state.day, 5);
      expect(state.cash, 765432);
      expect(state.brokerageCash, 765432);
      expect(state.team, 3);
      expect(state.positions.single.assetId, 'hanbit_telecom');
      expect(state.positions.single.units, 2.5);
      expect(state.positions.single.totalCost, 15000);
    },
  );

  test('unsupported legacy positions recover their cost into KRW cash', () {
    final state = engine.migrate({
      'version': 3,
      'companyName': '해외 복구 연구소',
      'currentDate': '2000-01-05',
      'cash': 1000,
      'team': 1,
      'positions': {
        'legacy_overseas_asset': {'units': 3.25, 'cost': 90000},
      },
    });

    expect(state.positions, isEmpty);
    expect(state.cash, 91000);
    expect(state.ledger.single.counterAccount, 'legacy_position_recovery');
  });

  test('a migrated fractional position can be sold completely', () {
    final migrated = engine
        .migrate({
          'version': 3,
          'companyName': '소수점 보유 연구소',
          'currentDate': '2000-01-05',
          'cash': 1000,
          'team': 1,
          'positions': {
            'hanbit_telecom': {'units': 2.5, 'cost': 15000},
          },
        })
        .copyWith(marketMinute: 9 * 60);

    final result = engine.executeTrade(
      migrated,
      hanbitOrder(
        side: TradeSide.sell,
        quantity: 2.5,
        unitPrice: 8000,
        quoteDate: '2000-01-05',
      ),
    );

    expect(result.success, isTrue);
    expect(result.notional, 20000);
    expect(result.fee, 50);
    expect(result.state.cash, 20950);
    expect(result.state.positions, isEmpty);
    expect(result.state.ledger.last.description, contains('2.5주 매도'));
  });

  test('fractional buy orders are rejected without mutating state', () {
    final state = engine
        .createNewGame('수량 검증 연구소', initialCash: 200000)
        .copyWith(day: 4, marketMinute: 9 * 60);
    final result = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.buy, quantity: 1.5),
    );

    expect(result.success, isFalse);
    expect(result.message, contains('1주 단위'));
    expect(result.state.toJson(), state.toJson());
  });

  test('an order with a stale quote date is rejected', () {
    final state = engine
        .createNewGame('날짜 검증 연구소', initialCash: 200000)
        .copyWith(day: 4, marketMinute: 9 * 60);
    final result = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.buy, quantity: 1, quoteDate: '2000-01-03'),
    );

    expect(result.success, isFalse);
    expect(result.message, contains('시세 날짜'));
    expect(result.state.toJson(), state.toJson());
  });

  test('an order with a stale market minute is rejected', () {
    final state = engine
        .createNewGame('시세 검증 연구소', initialCash: 200000)
        .copyWith(day: 4, marketMinute: 10 * 60);
    final result = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.buy, quantity: 1),
    );

    expect(result.success, isFalse);
    expect(result.message, contains('시세 시간'));
    expect(result.state.toJson(), state.toJson());
  });

  test('foreign-currency orders stay read-only until FX accounting exists', () {
    final state = engine
        .createNewGame('환율 검증 연구소', initialCash: 200000)
        .copyWith(day: 4, marketMinute: 9 * 60);
    final result = engine.executeTrade(
      state,
      const TradeOrder(
        side: TradeSide.buy,
        assetId: 'legacy_overseas_asset',
        symbol: 'LGCY',
        name: '해외 가상자산',
        market: '해외시장',
        currency: 'USD',
        quantity: 1,
        unitPrice: 1,
        quoteDate: '2000-01-04',
        marketMinute: 9 * 60,
        isTradingDay: true,
      ),
    );

    expect(result.success, isFalse);
    expect(result.message, contains('환율'));
    expect(result.state.toJson(), state.toJson());
  });

  test('split and KRW dividend actions update holdings exactly once', () {
    var state = engine
        .createNewGame('기업행동 테스트', initialCash: 100000)
        .copyWith(
          day: 5,
          positions: const [
            PortfolioPosition(
              assetId: 'sample',
              symbol: '000001',
              name: '샘플',
              market: fictionalMainMarket,
              currency: 'KRW',
              units: 10,
              totalCost: 50000,
            ),
          ],
        );
    const split = MarketCorporateAction(
      id: 'sample-split-2000-01-05',
      assetId: 'sample',
      type: MarketCorporateActionType.split,
      date: '2000-01-05',
      numerator: 2,
      denominator: 1,
      amount: 0,
      currency: 'KRW',
      source: 'test',
    );
    const dividend = MarketCorporateAction(
      id: 'sample-dividend-2000-01-05',
      assetId: 'sample',
      type: MarketCorporateActionType.dividend,
      date: '2000-01-05',
      numerator: 1,
      denominator: 1,
      amount: 100,
      currency: 'KRW',
      source: 'test',
    );
    state = engine.applyCorporateActions(state, const [split, dividend]);
    expect(state.positions.single.units, 20);
    expect(state.positions.single.totalCost, 50000);
    expect(state.cash, 101000);
    expect(state.ledger, hasLength(2));
    expect(state.processedEventIds, hasLength(2));
    expect(
      engine.applyCorporateActions(state, const [split, dividend]).toJson(),
      state.toJson(),
    );
  });

  test('earned seed money unlocks the first guardian order authority', () {
    final state = engine
        .createNewGame('종잣돈 권한 테스트')
        .copyWith(
          story: engine
              .createNewGame('종잣돈 권한 테스트')
              .story
              .copyWith(
                storyFlags: {
                  ...engine.createNewGame('종잣돈 권한 테스트').story.storyFlags,
                  'earnedSeedMoney': 9500,
                },
              ),
        );
    final next = engine.completeWorkSession(
      state,
      const WorkSessionResult(activityId: 'dishes', score: 100, maxScore: 100),
    );
    expect(next.story.earnedSeedMoney, greaterThanOrEqualTo(10000));
    expect(next.story.accountAuthorityLevel, 1);
    expect(next.story.reputation, 3);
  });

  test('guardian authority enforces the displayed per-order limit', () {
    final funded = engine.createNewGame('주문 한도 테스트', initialCash: 300000);
    final state = funded.copyWith(
      day: 4,
      marketMinute: 9 * 60,
      story: funded.story.copyWith(accountAuthorityLevel: 1),
    );
    final result = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.buy, quantity: 15),
    );
    expect(result.success, isFalse);
    expect(result.message, contains('100000'));
  });

  test('hiring creates payroll and monthly research cash flow', () {
    final january31 =
        DateTime(2003, 1, 31).difference(DateTime(2000, 1, 1)).inDays + 1;
    var state = engine
        .createNewGame('채용 경제 테스트', initialCash: 500000)
        .copyWith(day: january31, decisions: const []);
    state = engine.hireEmployee(state, 'candidate-hana');
    expect(state.organization.employees.single.name, '김하나');
    expect(state.cash, 460000);
    state = engine.advanceOneDay(state);
    expect(state.cash, 470460);
    expect(
      state.ledger.any((entry) => entry.counterAccount == 'salary_expense'),
      isTrue,
    );
    expect(
      state.ledger.any((entry) => entry.counterAccount == 'research_income'),
      isTrue,
    );
  });

  test('reputation and staff unlock an external capital fund', () {
    var state = engine
        .createNewGame('펀드 테스트', initialCash: 500000)
        .copyWith(day: 1500, decisions: const []);
    state = engine.hireEmployee(state, 'candidate-hana');
    state = state.copyWith(
      story: state.story.copyWith(
        storyFlags: {...state.story.storyFlags, 'reputation': 12},
      ),
    );
    state = engine.launchFund(state);
    expect(state.story.fundLaunched, isTrue);
    expect(state.story.externalAum, greaterThan(5000000));
    expect(state.story.accountAuthorityLevel, greaterThanOrEqualTo(4));
  });

  test('a fictional-world save without simulated price advances safely', () {
    final base = engine.createNewGame('분기 저장 방어').copyWith(decisions: const []);
    final state = base.copyWith(
      company: base.company.copyWith(
        worldMode: CompanyWorldMode.fictional,
        worldStartedAtDay: 10,
        worldReferencePrice: 1200,
      ),
    );
    final next = engine.advanceOneDay(state);
    expect(next.company.simulatedPrice, isNotNull);
    expect(next.company.simulatedPrice, greaterThan(0));
  });
  test('v10 saves migrate with an empty personal finance ledger', () {
    final legacy = engine.createNewGame('v10 재무 마이그레이션').toJson()
      ..remove('personalFinance')
      ..['version'] = 10;

    final migrated = engine.migrate(legacy);

    expect(migrated.version, GameState.schemaVersion);
    expect(migrated.cash, 0);
    expect(migrated.personalFinance.realEstate, isEmpty);
    expect(migrated.personalFinance.totalSpent, 0);
  });

  test(
    'spending is paid once and permanent research data adds monthly income',
    () {
      final december31 =
          DateTime(2004, 12, 31).difference(DateTime(2000, 1, 1)).inDays + 1;
      final base = engine
          .createNewGame('자료 소비 테스트', initialCash: 1000000)
          .copyWith(day: december31, decisions: const []);

      final purchase = engine.purchaseSpendingOption(base, 'data_archive');
      final duplicate = engine.purchaseSpendingOption(
        purchase.state,
        'data_archive',
      );
      final january = engine.advanceOneDay(purchase.state);

      expect(purchase.success, isTrue);
      expect(purchase.state.cash, 500000);
      expect(purchase.state.personalFinance.totalSpent, 500000);
      expect(duplicate.success, isFalse);
      expect(duplicate.state.toJson(), purchase.state.toJson());
      expect(
        january.ledger
            .where((entry) => entry.counterAccount == 'research_income')
            .last
            .amount,
        40000,
      );
    },
  );

  test(
    'owned office replaces rent with maintenance and can be sold after 30 days',
    () {
      final december31 =
          DateTime(2006, 12, 31).difference(DateTime(2000, 1, 1)).inDays + 1;
      final base = engine
          .createNewGame('자가 사무실 테스트', initialCash: 5000000)
          .copyWith(day: december31, decisions: const []);
      final legal = base.copyWith(
        story: base.story.copyWith(
          storyFlags: {
            ...base.story.storyFlags,
            'isLegalCompany': true,
            'officeTier': 2,
          },
        ),
      );

      final purchase = engine.purchaseSpendingOption(legal, 'owner_office');
      final january = engine.advanceOneDay(purchase.state);
      final asset = january.personalFinance.realEstate.single;
      final earlySale = engine.sellRealEstate(january, asset.id);
      final eligible = january.copyWith(day: asset.acquiredDay + 30);
      final sale = engine.sellRealEstate(eligible, asset.id);

      expect(purchase.success, isTrue);
      expect(january.personalFinance.monthlyPropertyCost, 40000);
      expect(
        january.ledger.any(
          (entry) => entry.counterAccount == 'property_maintenance',
        ),
        isTrue,
      );
      expect(
        january.ledger.any((entry) => entry.counterAccount == 'rent_expense'),
        isFalse,
      );
      expect(earlySale.success, isFalse);
      expect(sale.success, isTrue);
      expect(sale.state.personalFinance.realEstate, isEmpty);
      expect(sale.cashDelta, 2700000);
    },
  );

  test('commercial property income and costs settle separately each month', () {
    final december31 =
        DateTime(2008, 12, 31).difference(DateTime(2000, 1, 1)).inDays + 1;
    final base = engine
        .createNewGame('임대 자산 테스트', initialCash: 20000000)
        .copyWith(day: december31, decisions: const []);
    final legal = base.copyWith(
      story: base.story.copyWith(
        storyFlags: {...base.story.storyFlags, 'isLegalCompany': true},
      ),
    );
    final purchase = engine.purchaseSpendingOption(legal, 'commercial_unit');
    final january = engine.advanceOneDay(purchase.state);

    expect(purchase.success, isTrue);
    expect(
      january.ledger
          .where((entry) => entry.counterAccount == 'property_rent_income')
          .single
          .amount,
      110000,
    );
    expect(
      january.ledger
          .where((entry) => entry.counterAccount == 'property_maintenance')
          .single
          .amount,
      -25000,
    );
    expect(january.personalFinance.totalPropertyIncome, 110000);
  });

  test(
    'chance entertainment is adult-only, capped, deterministic, and monthly',
    () {
      final january1 =
          DateTime(2010, 1, 1).difference(DateTime(2000, 1, 1)).inDays + 1;
      final adult = engine
          .createNewGame('확률 오락 테스트', initialCash: 10000000)
          .copyWith(day: january1, decisions: const []);
      final beforeAdult = adult.copyWith(day: january1 - 366);

      final locked = engine.playAdultChanceGame(beforeAdult, 10000);
      final excessive = engine.playAdultChanceGame(adult, 100001);
      final first = engine.playAdultChanceGame(adult, 100000);
      final repeated = engine.playAdultChanceGame(first.state, 100000);
      final deterministic = engine.playAdultChanceGame(adult, 100000);

      expect(locked.success, isFalse);
      expect(excessive.success, isFalse);
      expect(first.success, isTrue);
      expect(first.state.personalFinance.totalChanceStake, 100000);
      expect(first.state.personalFinance.chancePlayCount, 1);
      expect(repeated.success, isFalse);
      expect(repeated.state.toJson(), first.state.toJson());
      expect(deterministic.state.toJson(), first.state.toJson());
    },
  );

  test(
    'new games start Sunday and day advance always opens at 08:00 Monday',
    () {
      final story = StoryState.newPlayer(
        playerName: '민준',
        introChoice: 'computer',
        startingTrait: StoryTrait.analysis,
        familyRule: FamilyRule.reportLosses,
      );
      final initial = engine.createNewGame('일요일 시작 연구소', story: story);

      expect(initial.cash, 0);
      expect(initial.currentDate, DateTime(2000, 1, 2));
      expect(initial.currentDate.weekday, DateTime.sunday);
      expect(initial.marketMinute, marketDayStartMinute);

      final closed = initial.copyWith(
        decisions: const [],
        marketMinute: marketDayEndMinute,
      );
      final monday = engine.advanceOneDay(closed);

      expect(monday.currentDate, DateTime(2000, 1, 3));
      expect(monday.currentDate.weekday, DateTime.monday);
      expect(monday.marketMinute, marketDayStartMinute);
    },
  );
  test('the campaign cannot advance beyond 2010-12-31', () {
    final state = engine
        .createNewGame('캠페인 종료 테스트')
        .copyWith(day: GameState.maxCampaignDay, decisions: const []);
    final next = engine.advanceOneDay(state);
    expect(next.day, GameState.maxCampaignDay);
    expect(next.currentDate, DateTime(2010, 12, 31));
    expect(next.toJson(), state.toJson());
  });
}
