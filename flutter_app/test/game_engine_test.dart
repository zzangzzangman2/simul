import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/market_tick.dart';
import 'package:millennium_capital/game/order_book.dart';
import 'package:millennium_capital/game/real_estate_rental.dart';
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

  int dayWithFutureMarketSignal(String seed) {
    for (var day = 3; day <= 370; day += 1) {
      final date = DateTime(2000, 1, 1).add(Duration(days: day - 1));
      if (isMarketTradingDay(date) &&
          fictionalMarketEventsForDate(
            seed,
            date,
          ).any((event) => event.revealMinute > marketDayStartMinute)) {
        return day;
      }
    }
    throw StateError('No reportable market signal found for $seed');
  }

  GameState advanceToControlOffer() {
    final base = engine.createNewGame(
      '경영권 기회 테스트',
      initialCash: 600000,
      worldSeed: 'control-system-world',
    );
    final triggerDate = DateTime(2005, 1, 1);
    final triggerDay =
        triggerDate.difference(base.campaignStartDate).inDays + 1;
    final ready = base.copyWith(
      day: triggerDay - 1,
      brokerageCash: 200000,
      decisions: const [],
      story: base.story.copyWith(
        storyFlags: {...base.story.storyFlags, 'firstOrderExecuted': true},
      ),
    );
    return engine.advanceOneDay(ready);
  }

  test('new game always starts with the Project Decimal state account', () {
    final story = StoryState.newPlayer(
      playerName: '민준',
      introChoice: 'computer',
      startingTrait: StoryTrait.analysis,
      operatingPrinciple: OperatingPrinciple.reportLosses,
    );
    final state = engine.createNewGame('별빛', story: story);

    expect(state.version, GameState.schemaVersion);
    expect(state.story.playerName, '민준');
    expect(state.cash, initialCompanyCash);
    expect(state.brokerageCash, initialCompanyCash);
    expect(state.story.startingSeedMoney, initialCompanyCash);
    expect(state.story.earnedSeedMoney, 0);
    expect(state.story.seedMoneyTotal, initialCompanyCash);
    expect(state.story.accountAuthorityLevel, 1);
    expect(state.story.stateAccountHolder, 'project_decimal_fund');
    expect(state.story.decimalProject, isTrue);
    expect(state.story.orphanageReboot, isTrue);
    expect(state.story.storyFlags['isLegalCompany'], isFalse);
    expect(state.story.marketTutorialEligible, isTrue);
    expect(state.story.marketTutorialSeen, isFalse);
    expect(state.story.storyFlags['seedMoneySource'], 'project_decimal_fund');
    expect(state.story.toJson(), isNot(contains('academyTuitionDebt')));
    expect(state.story.toJson(), isNot(contains('motherAffinity')));
    expect(state.story.toJson(), isNot(contains('fatherAffinity')));
    expect(state.ledger, hasLength(1));
    expect(state.ledger.single.amount, initialCompanyCash);
    expect(state.ledger.single.account, 'brokerage_cash');
    expect(state.ledger.single.counterAccount, 'state_seed_capital');
    expect(state.ledger.single.description, contains('데시멀 기금'));
    expect(state.story.flagBool('legacyMissionUiDisabled'), isTrue);
    expect(state.pendingDecisions, isEmpty);
  });

  test('Project Decimal starts with ten peers and an active state account', () {
    final story = StoryState.newDecimalPlayer(
      playerName: '명박',
      introChoice: 'stocks',
      startingTrait: StoryTrait.analysis,
      operatingPrinciple: OperatingPrinciple.reportLosses,
    );
    final state = engine.createNewGame('새천년투자연구소', story: story);

    expect(state.story.orphanageReboot, isTrue);
    expect(state.story.playerBirthYear, 1987);
    expect(state.story.ageOn(state.currentDate), 14);
    expect(state.story.stateAccountHolder, 'project_decimal_fund');
    expect(state.story.decimalProject, isTrue);
    expect(state.story.flagInt('finalCandidateCount'), 10);
    expect(state.story.flagInt('maleCandidateCount'), 2);
    expect(state.story.flagInt('femaleCandidateCount'), 8);
    expect(state.story.storyFlags['facility'], 'gangnam_hideout');
    expect(state.story.storyFlags, isNot(contains('futureDevelopmentCohort')));
    expect(state.story.storyFlags, isNot(contains('academyProgram')));
    expect(state.story.ageOn(DateTime(2005, 1, 2)), 19);
    expect(state.story.flagBool('stateAccountActive'), isTrue);
    expect(state.story.stateRecoveryRateBps, 2000);
    expect(state.story.stateRecoveryTotal, 0);
    expect(state.story.selfRelianceReserve, 0);
    expect(state.cash, initialCompanyCash);
    expect(state.brokerageCash, initialCompanyCash);
    expect(state.story.startingSeedMoney, initialCompanyCash);
    expect(state.story.storyFlags['seedMoneySource'], 'project_decimal_fund');
    expect(state.ledger, hasLength(1));
    expect(state.ledger.single.counterAccount, 'state_seed_capital');
    expect(state.processedEventIds, contains(stateAccountSeedCapitalSourceId));
  });

  test(
    'old reboot saves migrate to Project Decimal without academy tracks',
    () {
      final oldStory = StoryState.newOrphanagePlayer(
        playerName: '명박',
        introChoice: 'stocks',
        startingTrait: StoryTrait.analysis,
        operatingPrinciple: OperatingPrinciple.reportLosses,
      ).toJson()..['playerBirthYear'] = 1991;
      final oldFlags =
          Map<String, dynamic>.from(
              oldStory['storyFlags'] as Map<String, dynamic>,
            )
            ..remove('academyMaxLevel')
            ..remove('seedTrackStartAge')
            ..remove('seedTrackCompletionAge');
      oldStory['storyFlags'] = oldFlags;

      final migrated = StoryState.fromJson(oldStory, companyName: '이전 리부트 저장');

      expect(migrated.playerBirthYear, 1987);
      expect(migrated.ageOn(DateTime(2000, 1, 2)), 14);
      expect(migrated.decimalProject, isTrue);
      expect(migrated.stateAccountHolder, 'project_decimal_fund');
      expect(migrated.storyFlags, isNot(contains('academyLevel')));
      expect(migrated.storyFlags, isNot(contains('academyMaxLevel')));
      expect(migrated.storyFlags, isNot(contains('seedTrackCompletionAge')));
    },
  );

  test('market tutorial completion is stored in story state', () {
    final story = StoryState.newPlayer(
      playerName: '민재',
      introChoice: 'stocks',
      startingTrait: StoryTrait.analysis,
      operatingPrinciple: OperatingPrinciple.reportLosses,
    );
    final initial = engine
        .createNewGame('별빛 투자', story: story)
        .copyWith(day: 4);

    final completed = engine.markMarketTutorialSeen(initial);

    expect(completed.story.marketTutorialEligible, isTrue);
    expect(completed.story.marketTutorialSeen, isTrue);
    expect(completed.story.storyFlags['marketTutorialCompletedDay'], 4);
    expect(initial.story.marketTutorialSeen, isFalse);
  });

  test(
    'the 50000 won practice lasts one day and live trading starts next day',
    () {
      final initial = engine
          .createNewGame('하루 연습 계좌', worldSeed: 'one-day-practice')
          .copyWith(day: 3, marketMinute: krxOpenMinute);

      final completed = engine.completeInitialPracticeDay(initial);

      expect(completed.day, 4);
      expect(completed.marketMinute, marketDayStartMinute);
      expect(completed.cash, initialCompanyCash);
      expect(completed.brokerageCash, initialCompanyCash);
      expect(completed.story.marketTutorialSeen, isTrue);
      expect(completed.story.flagInt('practiceTradingDay'), 3);
      expect(completed.story.flagInt('liveTradingStartDay'), 4);
      expect(completed.story.flagBool('liveTradingStarted'), isTrue);
      expect(completed.pendingDecisions.single.id, 'first-research-note');
    },
  );

  test(
    'first research choice changes cohort trust and is applied only once',
    () {
      var state = engine.createNewGame('조사 연구소');
      final decisionId = state.pendingDecisions.first.id;
      final trustBefore = state.story.flagInt('cohortTrust', 30);
      state = engine.resolveDecision(state, decisionId, 'research_cashflow');
      final afterFirst = state;
      state = engine.resolveDecision(state, decisionId, 'research_cashflow');

      expect(afterFirst.story.flagInt('cohortTrust'), trustBefore + 1);
      expect(afterFirst.story.storyFlags['firstResearchFocus'], 'cashflow');
      expect(state.toJson(), afterFirst.toJson());
    },
  );

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
      throughDate: DateTime(2001, 12, 31),
    );
    final secondUniverse = await FictionalMarketUniverse.load(
      seed: second.simulationSeed,
      throughDate: DateTime(2001, 12, 31),
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
    final state = engine
        .createNewGame(
          '보고서 연구소',
          initialCash: 5000,
          worldSeed: 'report-world-seed',
        )
        .copyWith(
          day: dayWithFutureMarketSignal('report-world-seed'),
          brokerageCash: 0,
          marketMinute: marketDayStartMinute,
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

  test(
    'daily reports reject holidays, the close, and empty future signals',
    () {
      const seed = 'report-availability-world';
      final holiday = engine.createNewGame(
        '보고서 구매 시각',
        initialCash: 5000,
        worldSeed: seed,
      );
      final holidayResult = engine.purchaseDailyMarketReport(holiday);
      expect(holidayResult.success, isFalse);
      expect(holidayResult.message, contains('휴장일'));
      expect(holidayResult.state.toJson(), holiday.toJson());

      final reportDay = dayWithFutureMarketSignal(seed);
      final atClose = holiday.copyWith(
        day: reportDay,
        marketMinute: krxCloseMinute,
        brokerageCash: 0,
      );
      final closeResult = engine.purchaseDailyMarketReport(atClose);
      expect(closeResult.success, isFalse);
      expect(closeResult.message, contains('장이 끝나'));
      expect(closeResult.state.toJson(), atClose.toJson());

      final afterEveryReveal = atClose.copyWith(
        marketMinute: krxContinuousEndMinute - 1,
      );
      final emptyResult = engine.purchaseDailyMarketReport(afterEveryReveal);
      expect(emptyResult.success, isFalse);
      expect(emptyResult.message, contains('미공개'));
      expect(emptyResult.state.toJson(), afterEveryReveal.toJson());
    },
  );

  test('academy helper fatigue, daily limit, and recovery are persisted', () {
    var state = engine.createNewGame('제6기 연구소');
    state = resolveFirst(state, 'research_products');
    final helperBefore = state.organization.academyHelpers.first;

    state = engine.requestAcademyHelp(state, 'hakjun');
    final afterHelp = state.organization.academyHelpers.first;
    expect(afterHelp.fatigue, helperBefore.fatigue + 12);
    expect(afterHelp.helpCount, 1);
    expect(state.organization.helpLog, hasLength(1));

    final duplicate = engine.requestAcademyHelp(state, 'hakjun');
    expect(duplicate.toJson(), state.toJson());

    state = engine.advanceOneDay(state);
    final afterRest = state.organization.academyHelpers.first;
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
      expect(state.cash, 1430);
      expect(state.ledger.last.counterAccount, 'work_income');
      expect(state.story.storyFlags['earnedSeedMoney'], 1430);

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
      expect(state.cash, 5500);
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
    expect(state.story.playerName, '운용자');
    expect(state.story.stateAccountHolder, 'project_decimal_fund');
  });

  TradeOrder hanbitOrder({
    required TradeSide side,
    required double quantity,
    double unitPrice = 10000,
    String quoteDate = '2000-01-04',
    TradeOrderType type = TradeOrderType.market,
    double? limitPrice,
    double previousClose = 10000,
    double? previousTradePrice,
    int marketMinute = krxOpenMinute,
    int? maximumPositionUnits,
    bool isIpoFirstTradingDay = false,
    int microstructureFrame = 0,
    GameOrderBookSnapshot? displayedSnapshot,
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
    marketMinute: marketMinute,
    isTradingDay: true,
    type: type,
    limitPrice: limitPrice,
    previousClose: previousClose,
    previousTradePrice: previousTradePrice,
    maximumPositionUnits: maximumPositionUnits,
    isIpoFirstTradingDay: isIpoFirstTradingDay,
    microstructureFrame: microstructureFrame,
    displayedSnapshot: displayedSnapshot,
  );

  GameOrderBookSnapshot snapshotWithDepth(
    GameOrderBookSnapshot source, {
    required List<int> askQuantities,
    required List<int> bidQuantities,
    required int executionCapacity,
    int? liquidityPulse,
  }) {
    GameOrderBookLevel copyLevel(GameOrderBookLevel level, int quantity) =>
        GameOrderBookLevel(
          side: level.side,
          price: level.price,
          quantity: quantity,
          isWall: level.isWall,
          structuralKind: level.structuralKind,
          structuralStrength: level.structuralStrength,
          structuralHoldTicks: level.structuralHoldTicks,
          isStructuralWall: level.isStructuralWall,
          isStructuralBreached: level.isStructuralBreached,
          structuralVacuumMultiplier: level.structuralVacuumMultiplier,
          isPsychological: level.isPsychological,
          technicalPeriods: level.technicalPeriods,
          wasLiquidityPulseTouched: level.wasLiquidityPulseTouched,
        );

    final asks = <GameOrderBookLevel>[
      for (var index = 0; index < source.asks.length; index += 1)
        copyLevel(
          source.asks[index],
          index < askQuantities.length
              ? askQuantities[index]
              : source.asks[index].quantity,
        ),
    ];
    final bids = <GameOrderBookLevel>[
      for (var index = 0; index < source.bids.length; index += 1)
        copyLevel(
          source.bids[index],
          index < bidQuantities.length
              ? bidQuantities[index]
              : source.bids[index].quantity,
        ),
    ];
    return GameOrderBookSnapshot(
      asks: List<GameOrderBookLevel>.unmodifiable(asks),
      bids: List<GameOrderBookLevel>.unmodifiable(bids),
      turnoverEok: source.turnoverEok,
      executionCapacity: executionCapacity,
      totalAskQuantity: asks.fold(0, (sum, level) => sum + level.quantity),
      totalBidQuantity: bids.fold(0, (sum, level) => sum + level.quantity),
      tradeStrength: source.tradeStrength,
      liquidityPulse: liquidityPulse ?? source.liquidityPulse,
      adaptiveLiquidityPulses: source.adaptiveLiquidityPulses,
      rememberedLevels: source.rememberedLevels,
      sourceAssetId: source.sourceAssetId,
      sourceLiquidityDayKey: source.sourceLiquidityDayKey,
      sourceDateKey: source.sourceDateKey,
      sourceMarketMinute: source.sourceMarketMinute,
      sourceLastTradePrice: source.sourceLastTradePrice,
      sourceMarket: source.sourceMarket,
      sourceSimulationSeed: source.sourceSimulationSeed,
      appliedAskConsumptionByPrice: source.appliedAskConsumptionByPrice,
      appliedBidConsumptionByPrice: source.appliedBidConsumptionByPrice,
      appliedCapacityConsumptionUnits: source.appliedCapacityConsumptionUnits,
    );
  }

  test('modern IPO limit orders use the 60 to 400 percent first-day range', () {
    final base = engine.createNewGame('IPO 주문 가격제한 테스트', initialCash: 1000000);
    final listingDate = DateTime(2023, 6, 26);
    final listingDay =
        listingDate.difference(base.campaignStartDate).inDays + 1;
    final state = base.copyWith(day: listingDay, marketMinute: krxOpenMinute);
    final rejectedAsOrdinary = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 1,
        quoteDate: marketDateKey(listingDate),
        type: TradeOrderType.limit,
        limitPrice: 30000,
      ),
    );
    final acceptedAsIpo = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 1,
        quoteDate: marketDateKey(listingDate),
        type: TradeOrderType.limit,
        limitPrice: 30000,
        isIpoFirstTradingDay: true,
      ),
    );

    expect(rejectedAsOrdinary.success, isFalse);
    expect(rejectedAsOrdinary.message, contains('가격제한폭'));
    expect(acceptedAsIpo.success, isTrue);
  });

  test(
    'market buy consumes the displayed ask and persists its actual cost',
    () {
      final state = engine
          .createNewGame('거래 연구소', initialCash: 200000)
          .copyWith(day: 4, marketMinute: 9 * 60);
      final snapshot = buildGameOrderBookSnapshot(
        assetId: 'hanbit_telecom',
        day: marketLiquidityDayKey(state.currentDate),
        minute: state.marketMinute,
        currentPrice: 10000,
        previousClose: 10000,
        date: state.currentDate,
        market: fictionalMainMarket,
        simulationSeed: state.simulationSeed,
      );
      final result = engine.executeTrade(
        state,
        hanbitOrder(side: TradeSide.buy, quantity: 9),
      );
      final expectedNotional = (snapshot.asks.first.price * 9).round();
      final expectedFee = gameTradingFeeForState(state, expectedNotional);

      expect(result.success, isTrue);
      expect(result.notional, expectedNotional);
      expect(result.fee, expectedFee);
      expect(result.state.cash, 200000 - expectedNotional - expectedFee);
      expect(
        result.state.brokerageCash,
        200000 - expectedNotional - expectedFee,
      );
      expect(result.state.positions.single.units, 9);
      expect(
        result.state.positions.single.totalCost,
        expectedNotional + expectedFee,
      );
      expect(result.state.ledger.last.amount, -expectedNotional - expectedFee);
      expect(result.state.ledger.last.counterAccount, 'market_security');
      expect(result.state.ledger.last.orderType, TradeOrderType.market.name);
      expect(
        result.state.portfolioValue(const {'hanbit_telecom': 11000}),
        99000,
      );
      expect(
        result.state.totalAum(const {'hanbit_telecom': 11000}),
        299000 - expectedNotional - expectedFee,
      );
      final restored = GameState.fromJson(result.state.toJson());
      expect(restored.positions.single.units, 9);
      expect(
        restored.positions.single.totalCost,
        expectedNotional + expectedFee,
      );
    },
  );

  test('consecutive market orders consume the remaining absolute ask depth', () {
    final base = engine.createNewGame(
      'price depth ledger',
      initialCash: 1000000000,
    );
    final state = base.copyWith(
      day: 4,
      marketMinute: krxOpenMinute,
      story: base.story.copyWith(accountAuthorityLevel: 5),
    );
    final generated = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: marketLiquidityDayKey(state.currentDate),
      minute: state.marketMinute,
      currentPrice: 10000,
      previousClose: 10000,
      date: state.currentDate,
      market: fictionalMainMarket,
      simulationSeed: state.simulationSeed,
    );
    final rawDisplayed = snapshotWithDepth(
      generated,
      askQuantities: const [3, 7],
      bidQuantities: const [8, 8],
      executionCapacity: 20,
    );

    final first = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 2,
        displayedSnapshot: rawDisplayed,
      ),
    );
    final consumedAfterFirst = gameConsumedOrderBookUnitsByPrice(
      first.state,
      assetId: 'hanbit_telecom',
      marketMinute: krxOpenMinute,
      bookSide: GameOrderBookSide.ask,
    );
    final staleReplay = engine.executeTrade(
      first.state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 1,
        displayedSnapshot: rawDisplayed,
      ),
    );
    final secondDisplayed = gameOrderBookSnapshotAfterConsumption(
      snapshot: rawDisplayed,
      consumedAskByPrice: consumedAfterFirst,
      consumedCapacityUnits: gameConsumedOrderBookFillUnits(
        first.state,
        assetId: 'hanbit_telecom',
        marketMinute: krxOpenMinute,
        side: TradeSide.buy,
      ),
    );
    expect(
      secondDisplayed.asks.any(
        (level) => level.price == generated.asks[0].price,
      ),
      isFalse,
      reason:
          'A synthetic 1-share remainder is cancelled instead of being shown as a new wall.',
    );
    expect(secondDisplayed.asks.first.price, generated.asks[1].price);
    final second = engine.executeTrade(
      first.state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 3,
        displayedSnapshot: secondDisplayed,
      ),
    );

    expect(first.success, isTrue);
    expect(staleReplay.success, isFalse);
    expect(staleReplay.state.toJson(), first.state.toJson());
    expect(first.state.ledger.last.orderBookSide, 'ask');
    expect(first.state.ledger.last.orderBookFills, hasLength(1));
    expect(
      first.state.ledger.last.orderBookFills.single.price,
      generated.asks[0].price,
    );
    expect(first.state.ledger.last.orderBookFills.single.quantity, 2);
    expect(second.success, isTrue);
    expect(second.state.ledger.last.orderBookFills, hasLength(1));
    expect(
      second.state.ledger.last.orderBookFills.single.price,
      generated.asks[1].price,
    );
    expect(second.state.ledger.last.orderBookFills.single.quantity, 3);
    final consumed = gameConsumedOrderBookUnitsByPrice(
      second.state,
      assetId: 'hanbit_telecom',
      marketMinute: krxOpenMinute,
      bookSide: GameOrderBookSide.ask,
    );
    expect(consumed[generated.asks[0].price], 2);
    expect(consumed[generated.asks[1].price], 3);

    final restored = GameState.fromJson(second.state.toJson());
    expect(restored.ledger.last.orderBookSide, 'ask');
    expect(restored.ledger.last.orderBookFills, hasLength(1));
    expect(
      restored.ledger.last.orderBookFills.single.price,
      generated.asks[1].price,
    );
    expect(restored.ledger.last.orderBookFills.single.quantity, 3);
    expect(restored.ledger.last.orderBookCapacityUnits, 3);
  });

  test('displayed book is stale after shared minute capacity advances', () {
    final base = engine.createNewGame(
      'capacity watermark',
      initialCash: 100000000,
    );
    final state = base.copyWith(day: 4, marketMinute: krxOpenMinute);
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: marketLiquidityDayKey(state.currentDate),
      minute: state.marketMinute,
      currentPrice: 10000,
      previousClose: 10000,
      date: state.currentDate,
      market: fictionalMainMarket,
      simulationSeed: state.simulationSeed,
    );
    final marker = LedgerEntry(
      id: 'opposite-side-capacity-marker',
      day: state.day,
      amount: 0,
      account: 'brokerage_order',
      counterAccount: 'external_order_book_queue',
      description: 'shared capacity advanced',
      sourceId: 'opposite-side-capacity-marker',
      assetId: 'hanbit_telecom',
      marketMinute: state.marketMinute,
      orderBookCapacityUnits: 1,
    );
    final advanced = state.copyWith(ledger: [...state.ledger, marker]);

    final result = engine.executeTrade(
      advanced,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 1,
        displayedSnapshot: snapshot,
      ),
    );

    expect(result.success, isFalse);
    expect(result.state.toJson(), advanced.toJson());
  });

  test(
    'buy ask consumption leaves bid depth intact while sharing capacity',
    () {
      final base = engine.createNewGame(
        'two sided depth ledger',
        initialCash: 1000000000,
      );
      final state = base.copyWith(
        day: 4,
        marketMinute: krxOpenMinute,
        story: base.story.copyWith(accountAuthorityLevel: 5),
        positions: const [
          PortfolioPosition(
            assetId: 'hanbit_telecom',
            symbol: '1001',
            name: 'Hanbit Telecom',
            market: fictionalMainMarket,
            currency: 'KRW',
            units: 10,
            totalCost: 100000,
          ),
        ],
      );
      final generated = buildGameOrderBookSnapshot(
        assetId: 'hanbit_telecom',
        day: marketLiquidityDayKey(state.currentDate),
        minute: state.marketMinute,
        currentPrice: 10000,
        previousClose: 10000,
        date: state.currentDate,
        market: fictionalMainMarket,
        simulationSeed: state.simulationSeed,
      );
      final displayed = snapshotWithDepth(
        generated,
        askQuantities: const [10, 10],
        bidQuantities: const [10, 10],
        executionCapacity: 3,
      );
      final buy = engine.executeTrade(
        state,
        hanbitOrder(
          side: TradeSide.buy,
          quantity: 1,
          displayedSnapshot: displayed,
        ),
      );
      final bidConsumptionAfterBuy = gameConsumedOrderBookUnitsByPrice(
        buy.state,
        assetId: 'hanbit_telecom',
        marketMinute: krxOpenMinute,
        bookSide: GameOrderBookSide.bid,
      );
      final sellDisplayed = gameOrderBookSnapshotAfterConsumption(
        snapshot: displayed,
        consumedAskByPrice: gameConsumedOrderBookUnitsByPrice(
          buy.state,
          assetId: 'hanbit_telecom',
          marketMinute: krxOpenMinute,
          bookSide: GameOrderBookSide.ask,
        ),
        consumedBidByPrice: bidConsumptionAfterBuy,
        consumedCapacityUnits: gameConsumedOrderBookFillUnits(
          buy.state,
          assetId: 'hanbit_telecom',
          marketMinute: krxOpenMinute,
          side: TradeSide.sell,
        ),
      );
      final sell = engine.executeTrade(
        buy.state,
        hanbitOrder(
          side: TradeSide.sell,
          quantity: 5,
          displayedSnapshot: sellDisplayed,
        ),
      );

      expect(bidConsumptionAfterBuy, isEmpty);
      expect(sell.success, isTrue);
      expect(sell.filledQuantity, 2);
      expect(sell.state.ledger.last.orderBookSide, 'bid');
      expect(
        sell.state.ledger.last.orderBookFills.single.price,
        generated.bids[0].price,
      );
      expect(sell.state.ledger.last.orderBookFills.single.quantity, 2);
      expect(
        gameConsumedOrderBookFillUnits(
          sell.state,
          assetId: 'hanbit_telecom',
          marketMinute: krxOpenMinute,
          side: TradeSide.buy,
        ),
        3,
      );
    },
  );

  test('adaptive snapshot pulses do not revive consumed absolute prices', () {
    final base = engine.createNewGame(
      'adaptive depth ledger',
      initialCash: 1000000000,
    );
    final state = base.copyWith(
      day: 4,
      marketMinute: krxOpenMinute,
      story: base.story.copyWith(accountAuthorityLevel: 5),
    );
    final generated = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: marketLiquidityDayKey(state.currentDate),
      minute: state.marketMinute,
      currentPrice: 10000,
      previousClose: 10000,
      date: state.currentDate,
      market: fictionalMainMarket,
      simulationSeed: state.simulationSeed,
    );
    final pulseOne = snapshotWithDepth(
      generated,
      askQuantities: const [3, 7],
      bidQuantities: const [8, 8],
      executionCapacity: 20,
      liquidityPulse: 1,
    );
    final first = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 3,
        microstructureFrame: 1,
        displayedSnapshot: pulseOne,
      ),
    );
    final pulseTwoRaw = snapshotWithDepth(
      generated,
      askQuantities: const [3, 9],
      bidQuantities: const [8, 8],
      executionCapacity: 20,
      liquidityPulse: 2,
    );
    final pulseTwoDisplayed = gameOrderBookSnapshotAfterConsumption(
      snapshot: pulseTwoRaw,
      consumedAskByPrice: gameConsumedOrderBookUnitsByPrice(
        first.state,
        assetId: 'hanbit_telecom',
        marketMinute: krxOpenMinute,
        bookSide: GameOrderBookSide.ask,
      ),
      consumedCapacityUnits: gameConsumedOrderBookFillUnits(
        first.state,
        assetId: 'hanbit_telecom',
        marketMinute: krxOpenMinute,
        side: TradeSide.buy,
      ),
    );
    final second = engine.executeTrade(
      first.state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 1,
        microstructureFrame: 2,
        displayedSnapshot: pulseTwoDisplayed,
      ),
    );

    expect(first.success, isTrue);
    expect(second.success, isTrue);
    expect(
      second.state.ledger.last.orderBookFills.single.price,
      generated.asks[1].price,
    );
  });

  test('market orders share finite per-minute order-book capacity', () {
    final base = engine.createNewGame('시장가 용량 연구소', initialCash: 100000000);
    final state = base.copyWith(
      day: 4,
      marketMinute: 9 * 60,
      story: base.story.copyWith(accountAuthorityLevel: 5),
    );
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: marketLiquidityDayKey(state.currentDate),
      minute: state.marketMinute,
      currentPrice: 10000,
      previousClose: 10000,
      date: state.currentDate,
      market: fictionalMainMarket,
      simulationSeed: state.simulationSeed,
    );
    final liquidityLimit = gameMarketOrderNotionalLimit(
      10000,
      turnoverEok: snapshot.turnoverEok,
    );
    final expectedFirst = gameOrderBookLimitFillPlan(
      snapshot: snapshot,
      isBuy: true,
      requestedQuantity: snapshot.executionCapacity + 1.0,
      limitPrice: marketDailyPriceRange(
        previousClose: 10000,
        date: state.currentDate,
        market: fictionalMainMarket,
      ).upper,
      availableCapacity: snapshot.executionCapacity,
      maximumNotional: gameBuyNotionalBudget(
        state,
        maximumNotional: math.min(
          liquidityLimit,
          gameOrderAuthorityLimit(state),
        ),
      ),
    );
    final first = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: snapshot.executionCapacity + 1,
      ),
    );
    final second = engine.executeTrade(
      first.state,
      hanbitOrder(side: TradeSide.buy, quantity: 1),
    );

    expect(first.success, isTrue);
    expect(first.filledQuantity, expectedFirst.filledQuantity);
    expect(first.pendingQuantity, 0);
    expect(first.message, contains('즉시 취소'));
    expect(
      second.success,
      expectedFirst.filledQuantity < snapshot.executionCapacity,
    );
    expect(
      gameConsumedOrderBookFillUnits(
        second.state,
        assetId: 'hanbit_telecom',
        marketMinute: state.marketMinute,
        side: TradeSide.buy,
      ),
      lessThanOrEqualTo(snapshot.executionCapacity),
    );
  });

  test('buy and sell fills share one per-minute execution capacity', () {
    final base = engine.createNewGame('양방향 용량 연구소', initialCash: 100000000);
    final state = base.copyWith(
      day: 4,
      marketMinute: krxOpenMinute,
      positions: const [
        PortfolioPosition(
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: fictionalMainMarket,
          currency: 'KRW',
          units: 1,
          totalCost: 10000,
        ),
      ],
    );
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: marketLiquidityDayKey(state.currentDate),
      minute: state.marketMinute,
      currentPrice: 10000,
      previousClose: 10000,
      date: state.currentDate,
      market: fictionalMainMarket,
      simulationSeed: state.simulationSeed,
    );
    final buyCapacityConsumed = state.copyWith(
      ledger: [
        ...state.ledger,
        LedgerEntry(
          id: 'capacity-buy',
          day: state.day,
          amount: 0,
          account: 'brokerage_cash',
          counterAccount: 'market_security',
          description: 'capacity fixture',
          sourceId: 'capacity-buy',
          assetId: 'hanbit_telecom',
          tradeSide: TradeSide.buy.name,
          tradeQuantity: snapshot.executionCapacity.toDouble(),
          tradeUnitPrice: 10000,
          marketMinute: state.marketMinute,
          orderType: TradeOrderType.market.name,
        ),
      ],
    );

    expect(
      gameConsumedOrderBookFillUnits(
        buyCapacityConsumed,
        assetId: 'hanbit_telecom',
        marketMinute: state.marketMinute,
        side: TradeSide.sell,
      ),
      snapshot.executionCapacity,
    );
    final sell = engine.executeTrade(
      buyCapacityConsumed,
      hanbitOrder(side: TradeSide.sell, quantity: 1),
    );
    expect(sell.success, isFalse);
    expect(sell.state.toJson(), buyCapacityConsumed.toJson());
  });

  test('sell credits proceeds after fee and reduces units and cost basis', () {
    final base = engine.createNewGame('매도 연구소', initialCash: 200000);
    var state = base.copyWith(
      day: 4,
      marketMinute: 9 * 60,
      story: base.story.copyWith(accountAuthorityLevel: 2),
    );
    state = engine
        .executeTrade(state, hanbitOrder(side: TradeSide.buy, quantity: 10))
        .state;
    final costBeforeSale = state.positions.single.totalCost;
    final cashBeforeSale = state.cash;
    final result = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.sell,
        quantity: 4,
        unitPrice: 11000,
        quoteDate: state.currentDate.toIso8601String().split('T').first,
      ),
    );
    final disposedCost = (costBeforeSale * 4 / 10).round();
    final transactionTax = gameSecuritiesTransactionTax(
      state.currentDate,
      44000,
    );
    final tradingFee = gameTradingFeeForState(state, 44000);
    final proceeds = 44000 - tradingFee - transactionTax;

    expect(result.success, isTrue);
    expect(result.fee, tradingFee);
    expect(result.transactionTax, transactionTax);
    final realizedProfit = math.max(0, proceeds - disposedCost);
    expect(result.state.cash, cashBeforeSale + proceeds - realizedProfit);
    expect(
      result.state.brokerageCash,
      cashBeforeSale + proceeds - realizedProfit,
    );
    expect(
      result.state.story.stateRecoveryTotal +
          result.state.story.selfRelianceReserve,
      realizedProfit,
    );
    expect(result.state.positions.single.units, 6);
    expect(
      result.state.positions.single.totalCost,
      costBeforeSale - disposedCost,
    );
    final sellLedger = result.state.ledger.firstWhere(
      (entry) =>
          entry.counterAccount == 'market_security' &&
          entry.tradeSide == TradeSide.sell.name,
    );
    expect(sellLedger.amount, proceeds);
    expect(sellLedger.transactionTax, transactionTax);
    expect(result.realizedPnl, proceeds - disposedCost);
    expect(sellLedger.disposedCost, disposedCost);
    expect(sellLedger.realizedPnl, proceeds - disposedCost);
  });

  test('orphanage profitable sale splits profit into recovery and reserve', () {
    final story = StoryState.newOrphanagePlayer(
      playerName: '명박',
      introChoice: 'stocks',
      startingTrait: StoryTrait.analysis,
      operatingPrinciple: OperatingPrinciple.reportLosses,
    );
    final base = engine.createNewGame('새천년투자연구소', story: story);
    final state = base.copyWith(
      day: 4,
      marketMinute: 9 * 60,
      cash: 0,
      brokerageCash: 0,
      positions: const [
        PortfolioPosition(
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: fictionalMainMarket,
          currency: 'KRW',
          units: 4,
          totalCost: 30000,
        ),
      ],
      story: base.story.copyWith(accountAuthorityLevel: 2),
    );
    final result = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.sell,
        quantity: 4,
        unitPrice: 11000,
        quoteDate: state.currentDate.toIso8601String().split('T').first,
      ),
    );
    final transactionTax = gameSecuritiesTransactionTax(
      state.currentDate,
      44000,
    );
    final tradingFee = gameTradingFeeForState(state, 44000);
    final proceeds = 44000 - tradingFee - transactionTax;
    final realizedProfit = proceeds - 30000;
    final expectedRecovery = (realizedProfit * 0.2).round();
    final expectedReserve = realizedProfit - expectedRecovery;

    expect(result.success, isTrue, reason: result.message);
    expect(result.realizedPnl, realizedProfit);
    expect(result.state.cash, 30000);
    expect(result.state.brokerageCash, 30000);
    expect(result.state.story.stateRecoveryTotal, expectedRecovery);
    expect(result.state.story.selfRelianceReserve, expectedReserve);
    expect(
      result.state.ledger
          .where((entry) => entry.counterAccount == 'state_profit_recovery')
          .single
          .amount,
      -expectedRecovery,
    );
    expect(
      result.state.ledger
          .where((entry) => entry.counterAccount == 'self_reliance_reserve')
          .single
          .amount,
      -expectedReserve,
    );
  });

  test('live trading keeps 80 percent of net profit as reusable cash', () {
    final base = engine.createNewGame('실전 복리 테스트', initialCash: 0);
    final state = base.copyWith(
      day: 4,
      marketMinute: krxOpenMinute,
      cash: 0,
      brokerageCash: 0,
      positions: const [
        PortfolioPosition(
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: fictionalMainMarket,
          currency: 'KRW',
          units: 4,
          totalCost: 30000,
        ),
      ],
      story: base.story.copyWith(
        accountAuthorityLevel: 2,
        storyFlags: {
          ...base.story.storyFlags,
          'marketTutorialSeen': true,
          'liveTradingStarted': true,
        },
      ),
    );
    final result = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.sell,
        quantity: 4,
        unitPrice: 11000,
        quoteDate: state.currentDate.toIso8601String().split('T').first,
      ),
    );
    final recovery = (result.realizedPnl * 0.2).round();

    expect(result.success, isTrue, reason: result.message);
    expect(result.realizedPnl, greaterThan(0));
    expect(result.state.brokerageCash, 30000 + result.realizedPnl - recovery);
    expect(result.state.story.stateRecoveryTotal, recovery);
    expect(result.state.story.selfRelianceReserve, 0);
  });

  test('fractional market sell follows IOC partial-fill semantics', () {
    final base = engine.createNewGame('소수점 매도 연구소', initialCash: 100000);
    final marketState = base.copyWith(day: 4, marketMinute: krxOpenMinute);
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: marketLiquidityDayKey(marketState.currentDate),
      minute: marketState.marketMinute,
      currentPrice: 10000,
      previousClose: 10000,
      date: marketState.currentDate,
      market: fictionalMainMarket,
      simulationSeed: marketState.simulationSeed,
    );
    final requestedQuantity = snapshot.executionCapacity + 0.5;
    final state = marketState.copyWith(
      positions: [
        PortfolioPosition(
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: fictionalMainMarket,
          currency: 'KRW',
          units: requestedQuantity,
          totalCost: (requestedQuantity * 10000).round(),
        ),
      ],
    );

    final result = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.sell, quantity: requestedQuantity),
    );

    expect(result.success, isTrue);
    expect(result.filledQuantity, greaterThan(0));
    expect(result.filledQuantity, lessThan(requestedQuantity));
    expect(result.pendingQuantity, 0);
    expect(
      result.state.positions.single.units,
      closeTo(requestedQuantity - result.filledQuantity, 0.000001),
    );
    expect(result.message, contains('즉시 취소'));
  });

  test('trading fees and sell taxes follow the campaign era', () {
    expect(
      gameTradingFeeForState(engine.createNewGame('2000 비용'), 100000),
      500,
    );
    expect(gameSecuritiesTransactionTax(DateTime(2000), 100000), 300);
    expect(gameSecuritiesTransactionTax(DateTime(2026), 100000), 150);
  });

  test('positive trades always charge at least one won of fee and tax', () {
    final state = engine.createNewGame('최소 거래비용');

    expect(gameTradingFeeForState(state, 1), 1);
    expect(gameSecuritiesTransactionTax(DateTime(2026), 120), 1);
    expect(gameTradingFeeForState(state, 0), 0);
    expect(gameSecuritiesTransactionTax(DateTime(2026), 0), 0);
  });

  test('buys cannot exceed issued shares, including pending reservations', () {
    final base = engine.createNewGame(
      '발행주식 상한',
      initialCash: 1000000,
      worldSeed: 'issued-share-cap',
    );
    final state = base.copyWith(
      day: 4,
      marketMinute: krxOpenMinute,
      story: base.story.copyWith(accountAuthorityLevel: 5),
      positions: const [
        PortfolioPosition(
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: fictionalMainMarket,
          currency: 'KRW',
          units: 9,
          totalCost: 90000,
        ),
      ],
    );
    final excess = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.buy, quantity: 2, maximumPositionUnits: 10),
    );

    expect(excess.success, isFalse);
    expect(excess.message, contains('발행주식'));
    expect(excess.state.toJson(), state.toJson());

    final reserved = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 1,
        type: TradeOrderType.limit,
        limitPrice: 9000,
        maximumPositionUnits: 10,
      ),
    );
    expect(reserved.success, isTrue);
    expect(reserved.pendingQuantity, 1);
    expect(reserved.state.pendingOrders.single.maximumPositionUnits, 10);
    expect(
      PendingTradeOrder.fromJson(
        reserved.state.pendingOrders.single.toJson(),
      ).maximumPositionUnits,
      10,
    );

    final overReserved = engine.executeTrade(
      reserved.state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 1,
        type: TradeOrderType.limit,
        limitPrice: 8950,
        maximumPositionUnits: 10,
      ),
    );
    expect(overReserved.success, isFalse);
    expect(overReserved.message, contains('발행주식'));
  });

  test(
    'trade trust and profitable-sale reputation are awarded once per day',
    () {
      final base = engine.createNewGame(
        '보상 파밍 방지',
        initialCash: 100000,
        worldSeed: 'daily-trade-reward',
      );
      final state = base.copyWith(
        day: 4,
        marketMinute: krxOpenMinute,
        story: base.story.copyWith(
          accountAuthorityLevel: 5,
          storyFlags: {...base.story.storyFlags, 'reputation': 10},
        ),
        positions: const [
          PortfolioPosition(
            assetId: 'hanbit_telecom',
            symbol: '1001',
            name: '한빛통신',
            market: fictionalMainMarket,
            currency: 'KRW',
            units: 4,
            totalCost: 4000,
          ),
        ],
      );
      final first = engine.executeTrade(
        state,
        hanbitOrder(side: TradeSide.sell, quantity: 1),
      );
      final secondState = first.state.copyWith(marketMinute: krxOpenMinute + 1);
      final second = engine.executeTrade(
        secondState,
        hanbitOrder(
          side: TradeSide.sell,
          quantity: 1,
          marketMinute: krxOpenMinute + 1,
        ),
      );

      expect(first.success, isTrue);
      expect(second.success, isTrue);
      expect(
        first.state.story.flagInt('cohortTrust'),
        state.story.flagInt('cohortTrust') + 1,
      );
      expect(
        second.state.story.flagInt('cohortTrust'),
        first.state.story.flagInt('cohortTrust'),
      );
      expect(first.state.story.reputation, 13);
      expect(second.state.story.reputation, first.state.story.reputation);
    },
  );

  test(
    'authority limits are monotonic and levels three and five are reachable',
    () {
      final wealthy = engine.createNewGame(
        '권한 단조성',
        initialCash: 100000000,
        worldSeed: 'authority-monotonic',
      );
      final level3 = wealthy.copyWith(
        story: wealthy.story.copyWith(accountAuthorityLevel: 3),
      );
      final level4 = wealthy.copyWith(
        story: wealthy.story.copyWith(accountAuthorityLevel: 4),
      );
      expect(
        gameOrderAuthorityLimit(level4),
        greaterThanOrEqualTo(gameOrderAuthorityLimit(level3)),
      );

      final almostLevel3 = wealthy.copyWith(
        day: 4,
        marketMinute: krxOpenMinute,
        story: wealthy.story.copyWith(accountAuthorityLevel: 2),
        progression: wealthy.progression.record('trade_volume', 1995000),
      );
      final unlocked3 = engine.executeTrade(
        almostLevel3,
        hanbitOrder(side: TradeSide.buy, quantity: 1),
      );
      expect(unlocked3.success, isTrue);
      expect(unlocked3.state.story.accountAuthorityLevel, 3);

      final fundState = wealthy.copyWith(
        day: 4,
        marketMinute: krxOpenMinute,
        story: wealthy.story.copyWith(
          accountAuthorityLevel: 4,
          storyFlags: {
            ...wealthy.story.storyFlags,
            'fundLaunched': true,
            'reputation': 59,
          },
        ),
        positions: const [
          PortfolioPosition(
            assetId: 'hanbit_telecom',
            symbol: '1001',
            name: '한빛통신',
            market: fictionalMainMarket,
            currency: 'KRW',
            units: 1,
            totalCost: 1000,
          ),
        ],
      );
      final unlocked5 = engine.executeTrade(
        fundState,
        hanbitOrder(side: TradeSide.sell, quantity: 1),
      );
      expect(unlocked5.success, isTrue);
      expect(unlocked5.state.story.accountAuthorityLevel, 5);
    },
  );

  test(
    'non-marketable limit order reserves cash, persists, fills, and cancels',
    () {
      final state = engine
          .createNewGame('지정가 연구소', initialCash: 300000)
          .copyWith(day: 4, marketMinute: 9 * 60);
      final placed = engine.executeTrade(
        state,
        hanbitOrder(
          side: TradeSide.buy,
          quantity: 10,
          type: TradeOrderType.limit,
          limitPrice: 9000,
        ),
      );

      expect(placed.success, isTrue);
      expect(placed.filledQuantity, 0);
      expect(placed.pendingQuantity, 10);
      expect(placed.state.pendingOrders, hasLength(1));
      expect(
        placed.state.availableBrokerageCash,
        lessThan(state.brokerageCash),
      );
      final restored = GameState.fromJson(placed.state.toJson());
      expect(restored.pendingOrders.single.limitPrice, 9000);
      final legacyPendingJson = placed.state.toJson();
      final legacyPending =
          (legacyPendingJson['pendingOrders'] as List).single
              as Map<String, dynamic>;
      legacyPending.remove('placedSequence');
      final legacyPendingState = GameState.fromJson(legacyPendingJson);
      final collisionSafe = engine.executeTrade(
        legacyPendingState,
        hanbitOrder(
          side: TradeSide.buy,
          quantity: 1,
          type: TradeOrderType.limit,
          limitPrice: 9000,
        ),
      );
      expect(
        collisionSafe.state.pendingOrders.map((order) => order.id).toSet(),
        hasLength(2),
      );
      expect(
        collisionSafe.state.pendingOrders.last.queueAheadQuantity,
        collisionSafe.state.pendingOrders.first.queueAheadQuantity +
            collisionSafe.state.pendingOrders.first.remainingQuantity,
      );

      final filled = engine.processPendingOrdersAtQuote(
        restored,
        assetId: 'hanbit_telecom',
        unitPrice: 8900,
        marketMinute: 9 * 60 + 1,
        isTradingDay: true,
      );
      expect(filled.pendingOrders, isEmpty);
      expect(filled.positions.single.units, 10);
      expect(filled.ledger.last.orderBookSide, 'ask');
      expect(filled.ledger.last.orderBookFills, isNotEmpty);

      final second = engine.executeTrade(
        state,
        hanbitOrder(
          side: TradeSide.buy,
          quantity: 3,
          type: TradeOrderType.limit,
          limitPrice: 9000,
        ),
      );
      final cancelled = engine.cancelPendingOrder(
        second.state,
        second.state.pendingOrders.single.id,
      );
      expect(cancelled.success, isTrue);
      expect(cancelled.state.pendingOrders, isEmpty);
      expect(cancelled.state.availableBrokerageCash, state.brokerageCash);

      final replacement = engine.executeTrade(
        cancelled.state,
        hanbitOrder(
          side: TradeSide.buy,
          quantity: 3,
          type: TradeOrderType.limit,
          limitPrice: 9000,
        ),
      );
      expect(replacement.orderId, isNot(second.orderId));
    },
  );

  test('pending buys use price priority before placement sequence', () {
    final state = engine
        .createNewGame(
          '가격 우선 연구소',
          initialCash: 1000000000,
          worldSeed: 'pending-price-priority',
        )
        .copyWith(day: 4, marketMinute: 9 * 60);
    final nextMinuteSnapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: marketLiquidityDayKey(state.currentDate),
      minute: 9 * 60 + 1,
      currentPrice: 900,
      previousClose: 1000,
      date: state.currentDate,
      market: fictionalMainMarket,
      simulationSeed: state.simulationSeed,
    );
    final quantity = nextMinuteSnapshot.executionCapacity + 1.0;
    final lower = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: quantity,
        unitPrice: 1000,
        previousClose: 1000,
        type: TradeOrderType.limit,
        limitPrice: 900,
      ),
    );
    final higher = engine.executeTrade(
      lower.state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: quantity,
        unitPrice: 1000,
        previousClose: 1000,
        type: TradeOrderType.limit,
        limitPrice: 950,
      ),
    );
    final placedLowOrder = higher.state.pendingOrders.singleWhere(
      (order) => order.limitPrice == 900,
    );
    final placedHighOrder = higher.state.pendingOrders.singleWhere(
      (order) => order.limitPrice == 950,
    );

    final filled = engine.processPendingOrdersAtQuote(
      higher.state,
      assetId: 'hanbit_telecom',
      unitPrice: 900,
      marketMinute: 9 * 60 + 1,
      isTradingDay: true,
      previousClose: 1000,
    );
    expect(
      placedHighOrder.placedSequence,
      greaterThan(placedLowOrder.placedSequence),
    );
    final fills = filled.ledger
        .where(
          (entry) =>
              entry.assetId == 'hanbit_telecom' &&
              entry.marketMinute == 9 * 60 + 1 &&
              entry.tradeSide == TradeSide.buy.name,
        )
        .toList(growable: false);
    expect(fills, isNotEmpty);
    expect(fills.first.tradeUnitPrice, greaterThan(900));
    if (fills.length > 1) {
      expect(
        fills.first.tradeUnitPrice,
        greaterThanOrEqualTo(fills.last.tradeUnitPrice),
        reason: '더 높은 매수 지정가가 먼저 체결되어야 한다.',
      );
    }
  });

  test('marketable limit order can partially fill and leave a reservation', () {
    final base = engine.createNewGame(
      '부분 체결 연구소',
      initialCash: gameMaximumOrderLiquidity,
    );
    final state = base.copyWith(
      day: 4,
      marketMinute: 9 * 60,
      story: base.story.copyWith(accountAuthorityLevel: 5),
    );
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: marketLiquidityDayKey(state.currentDate),
      minute: state.marketMinute,
      currentPrice: 10000,
      previousClose: 10000,
      date: state.currentDate,
      market: fictionalMainMarket,
      simulationSeed: state.simulationSeed,
    );
    final requestedQuantity = snapshot.executionCapacity + 1.0;
    final result = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: requestedQuantity,
        type: TradeOrderType.limit,
        limitPrice: 10200,
      ),
    );
    final perFillLimit = gameMarketOrderNotionalLimit(
      10000,
      turnoverEok: gameEstimatedTurnoverEok(
        assetId: 'hanbit_telecom',
        day: marketLiquidityDayKey(state.currentDate),
        minute: state.marketMinute,
        unitPrice: 10000,
        previousClose: 10000,
        simulationSeed: state.simulationSeed,
      ),
    );

    expect(result.success, isTrue);
    expect(result.filledQuantity, greaterThan(0));
    expect(result.filledQuantity, lessThan(requestedQuantity));
    expect(result.pendingQuantity, requestedQuantity - result.filledQuantity);
    expect(result.state.pendingOrders, hasLength(1));
    expect(
      result.state.pendingOrders.single.remainingQuantity,
      result.pendingQuantity,
    );
    expect(result.state.positions.single.units, result.filledQuantity);
    expect(result.averageFillPrice, lessThanOrEqualTo(10200));
    expect(result.notional, lessThanOrEqualTo(perFillLimit));
    final fillEntry = result.state.ledger.lastWhere(
      (entry) => entry.tradeQuantity > 0,
    );
    expect(fillEntry.orderBookSide, 'ask');
    expect(fillEntry.orderBookFills, isNotEmpty);
    expect(
      fillEntry.orderBookFills.fold<double>(
        0,
        (sum, fill) => sum + fill.quantity,
      ),
      result.filledQuantity,
    );
  });

  test('limit fills use displayed asks without market impact', () {
    final state = engine
        .createNewGame('호가 체결가 연구소', initialCash: 100000000)
        .copyWith(day: 4, marketMinute: krxOpenMinute);
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: marketLiquidityDayKey(state.currentDate),
      minute: state.marketMinute,
      currentPrice: 10000,
      previousClose: 10000,
      date: state.currentDate,
      market: '미래시장',
      simulationSeed: state.simulationSeed,
    );
    final limitPrice = snapshot.asks.first.price;
    final result = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 5,
        type: TradeOrderType.limit,
        limitPrice: limitPrice,
      ),
    );

    expect(result.success, isTrue);
    expect(result.filledQuantity, 5);
    expect(result.averageFillPrice, limitPrice);
    expect(result.notional, (limitPrice * 5).round());
    expect(result.state.ledger.last.orderType, TradeOrderType.limit.name);
    expect(result.state.ledger.last.tradeQuantity, 5);
    expect(
      gameConsumedOrderBookFillUnits(
        result.state,
        assetId: 'hanbit_telecom',
        marketMinute: krxOpenMinute,
        side: TradeSide.buy,
      ),
      5,
    );
  });

  test('a displayed bid wall keeps a resting buy behind queue', () {
    final state = engine
        .createNewGame('매수벽 대기 연구소', initialCash: 100000000)
        .copyWith(day: 4, marketMinute: krxOpenMinute);
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: marketLiquidityDayKey(state.currentDate),
      minute: state.marketMinute,
      currentPrice: 10000,
      previousClose: 10000,
      date: state.currentDate,
      market: '미래시장',
      simulationSeed: state.simulationSeed,
    );
    final wall = snapshot.bids.firstWhere((level) => level.isWall);
    final placed = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 10,
        type: TradeOrderType.limit,
        limitPrice: wall.price,
      ),
    );
    final queued = placed.state.pendingOrders.single;
    expect(queued.queueAheadQuantity, wall.quantity);

    final processed = engine.processPendingOrdersAtQuote(
      placed.state,
      assetId: 'hanbit_telecom',
      unitPrice: wall.price,
      marketMinute: krxOpenMinute,
      isTradingDay: true,
      previousClose: 10000,
    );
    final waiting = processed.pendingOrders.single;
    expect(waiting.remainingQuantity, 10);
    expect(waiting.queueAheadQuantity, lessThan(queued.queueAheadQuantity));
    expect(waiting.queueAheadQuantity, greaterThan(0));
    final queueMarker = processed.ledger.last;
    expect(queueMarker.counterAccount, 'external_order_book_queue');
    expect(queueMarker.orderBookSide, GameOrderBookSide.bid.name);
    expect(queueMarker.orderBookFills, hasLength(1));
    expect(queueMarker.orderBookFills.single.price, wall.price);
    expect(
      queueMarker.orderBookFills.single.quantity,
      queueMarker.orderBookCapacityUnits,
    );
    expect(queueMarker.orderBookCapacityUnits, greaterThan(0));
    expect(
      gameConsumedOrderBookUnitsByPrice(
        processed,
        assetId: 'hanbit_telecom',
        marketMinute: krxOpenMinute,
        bookSide: GameOrderBookSide.bid,
      )[wall.price],
      queueMarker.orderBookFills.single.quantity,
    );

    final processedAgain = engine.processPendingOrdersAtQuote(
      processed,
      assetId: 'hanbit_telecom',
      unitPrice: wall.price,
      marketMinute: krxOpenMinute,
      isTradingDay: true,
      previousClose: 10000,
    );
    expect(
      processedAgain.pendingOrders.single.queueAheadQuantity,
      waiting.queueAheadQuantity,
    );
    expect(processedAgain.ledger, hasLength(processed.ledger.length));
  });

  test(
    'empty aggressive depth cannot queue-fill an unrepresented limit price',
    () {
      final base = engine
          .createNewGame('represented queue only', initialCash: 100000000)
          .copyWith(day: 4, marketMinute: krxOpenMinute);
      final snapshot = buildGameOrderBookSnapshot(
        assetId: 'hanbit_telecom',
        day: marketLiquidityDayKey(base.currentDate),
        minute: base.marketMinute,
        currentPrice: 10000,
        previousClose: 10000,
        date: base.currentDate,
        market: fictionalMainMarket,
        simulationSeed: base.simulationSeed,
      );
      final firstAsk = snapshot.asks.first;
      expect(snapshot.executionCapacity, greaterThan(1));
      expect(
        snapshot.bids.any(
          (level) => (level.price - firstAsk.price).abs() < 0.000001,
        ),
        isFalse,
      );
      final consumedAsk = LedgerEntry(
        id: 'consumed-best-ask-fixture',
        day: base.day,
        amount: 0,
        account: 'brokerage_cash',
        counterAccount: 'market_security',
        description: 'best ask already consumed',
        sourceId: 'consumed-best-ask-fixture',
        assetId: 'hanbit_telecom',
        tradeSide: TradeSide.buy.name,
        marketMinute: base.marketMinute,
        orderType: TradeOrderType.limit.name,
        orderBookSide: GameOrderBookSide.ask.name,
        orderBookFills: [
          LedgerOrderBookFill(
            price: firstAsk.price,
            quantity: firstAsk.quantity.toDouble(),
          ),
        ],
        orderBookCapacityUnits: 1,
      );
      final state = base.copyWith(
        ledger: [...base.ledger, consumedAsk],
        pendingOrders: [
          PendingTradeOrder(
            id: 'unrepresented-marketable-buy',
            side: PendingOrderSide.buy,
            assetId: 'hanbit_telecom',
            symbol: '1001',
            name: 'Hanbit Telecom',
            market: fictionalMainMarket,
            currency: 'KRW',
            limitPrice: firstAsk.price,
            originalQuantity: 1,
            remainingQuantity: 1,
            placedDate: marketDateKey(base.currentDate),
            placedMinute: base.marketMinute,
            placedSequence: 1,
          ),
        ],
      );

      final processed = engine.processPendingOrdersAtQuote(
        state,
        assetId: 'hanbit_telecom',
        unitPrice: 10000,
        marketMinute: base.marketMinute,
        isTradingDay: true,
        previousClose: 10000,
      );

      expect(processed.pendingOrders, hasLength(1));
      expect(processed.pendingOrders.single.remainingQuantity, 1);
      expect(processed.positions, isEmpty);
      expect(processed.ledger, hasLength(state.ledger.length));
    },
  );

  test('a deep displayed bid keeps a resting order behind external queue', () {
    final state = engine
        .createNewGame('깊은 호가 대기 연구소', initialCash: 100000000)
        .copyWith(day: 4, marketMinute: krxOpenMinute);
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: marketLiquidityDayKey(state.currentDate),
      minute: state.marketMinute,
      currentPrice: 10000,
      previousClose: 10000,
      date: state.currentDate,
      market: fictionalMainMarket,
      simulationSeed: state.simulationSeed,
    );
    final deepBid = snapshot.bids[7];

    final placed = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 10,
        type: TradeOrderType.limit,
        limitPrice: deepBid.price,
      ),
    );

    expect(snapshot.bids.length, greaterThanOrEqualTo(gameOrderBookLevelCount));
    expect(placed.success, isTrue);
    expect(placed.filledQuantity, 0);
    expect(
      placed.state.pendingOrders.single.queueAheadQuantity,
      deepBid.quantity,
    );
  });

  test('a buy limit stays unfilled when the price runs away above it', () {
    final state = engine
        .createNewGame('달아나는 호가 연구소', initialCash: 100000000)
        .copyWith(day: 4, marketMinute: 9 * 60);
    final placed = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 25,
        type: TradeOrderType.limit,
        limitPrice: 9000,
      ),
    );

    expect(placed.success, isTrue);
    expect(placed.filledQuantity, 0);
    expect(placed.state.pendingOrders, hasLength(1));

    final ranAway = engine.processPendingOrdersAtQuote(
      placed.state.copyWith(marketMinute: 9 * 60 + 1),
      assetId: 'hanbit_telecom',
      unitPrice: 10500,
      marketMinute: 9 * 60 + 1,
      isTradingDay: true,
    );

    expect(ranAway.pendingOrders.single.remainingQuantity, 25);
    expect(ranAway.positions, isEmpty);
    expect(ranAway.availableBrokerageCash, lessThan(ranAway.brokerageCash));
  });

  test('pending day orders expire at the historical 15:00 close', () {
    final state = engine
        .createNewGame('종가 주문 연구소', initialCash: 300000)
        .copyWith(day: 4, marketMinute: 9 * 60);
    final placed = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 2,
        type: TradeOrderType.limit,
        limitPrice: 9000,
      ),
    );
    final expired = engine.expirePendingOrders(
      placed.state.copyWith(marketMinute: krxCloseMinute),
    );

    expect(expired.pendingOrders, isEmpty);
    expect(expired.ledger.last.counterAccount, 'day_order_expiry');
    expect(
      expired.ledger.last.sourceId,
      'expire-${placed.state.pendingOrders.single.id}',
    );
    expect(expired.ledger.last.tradeQuantity, 0);
  });

  test('day advance replays pending orders before the close', () {
    final state = engine
        .createNewGame('하루 진행 주문 연구소', initialCash: 300000)
        .copyWith(
          day: 4,
          marketMinute: krxOpenMinute,
          decisions: const [],
          pendingOrders: const [
            PendingTradeOrder(
              id: 'replay-buy',
              side: PendingOrderSide.buy,
              assetId: 'hanbit_telecom',
              symbol: '1001',
              name: '한빛통신',
              market: fictionalMainMarket,
              currency: 'KRW',
              limitPrice: 9000,
              originalQuantity: 1,
              remainingQuantity: 1,
              placedDate: '2000-01-04',
              placedMinute: krxOpenMinute,
              placedSequence: 1,
            ),
          ],
        );
    final path = List<double>.generate(
      generatedSessionTicks + 1,
      (index) => index <= marketTickForMinute(krxOpenMinute) ? 10000 : 8900,
    );

    final advanced = engine.advanceOneDay(
      state,
      pendingOrderQuotePaths: {
        'hanbit_telecom': GamePendingOrderQuotePath(
          prices: path,
          previousClose: 10000,
          isTradingDay: true,
        ),
      },
    );

    expect(advanced.day, state.day + 1);
    expect(advanced.pendingOrders, isEmpty);
    expect(advanced.positions.single.units, 1);
    expect(
      advanced.ledger.where((entry) => entry.sourceId == 'replay-buy'),
      isEmpty,
    );
    expect(
      advanced.ledger.any(
        (entry) =>
            entry.assetId == 'hanbit_telecom' &&
            entry.tradeQuantity == 1 &&
            entry.counterAccount == 'market_security',
      ),
      isTrue,
    );
  });

  test('day advance rejects a partial pending-order quote map', () {
    final state = engine
        .createNewGame('누락 경로 연구소', initialCash: 300000)
        .copyWith(
          day: 4,
          marketMinute: krxOpenMinute,
          decisions: const [],
          pendingOrders: const [
            PendingTradeOrder(
              id: 'path-a',
              side: PendingOrderSide.buy,
              assetId: 'asset-a',
              symbol: '1001',
              name: 'A',
              market: fictionalMainMarket,
              currency: 'KRW',
              limitPrice: 9000,
              originalQuantity: 1,
              remainingQuantity: 1,
              placedDate: '2000-01-04',
              placedMinute: krxOpenMinute,
              placedSequence: 1,
            ),
            PendingTradeOrder(
              id: 'path-b',
              side: PendingOrderSide.buy,
              assetId: 'asset-b',
              symbol: '1002',
              name: 'B',
              market: fictionalMainMarket,
              currency: 'KRW',
              limitPrice: 9000,
              originalQuantity: 1,
              remainingQuantity: 1,
              placedDate: '2000-01-04',
              placedMinute: krxOpenMinute,
              placedSequence: 2,
            ),
          ],
        );

    expect(
      () => engine.advanceOneDay(
        state,
        pendingOrderQuotePaths: {
          'asset-a': GamePendingOrderQuotePath(
            prices: List<double>.filled(generatedSessionTicks + 1, 10000),
            previousClose: 10000,
            isTradingDay: true,
          ),
        },
      ),
      throwsArgumentError,
    );
  });

  test('pending replay rejects rewind and incomplete trading-day paths', () {
    final base = engine.createNewGame('주문 재생 검증 연구소', initialCash: 300000);
    final marketState = base.copyWith(day: 4, marketMinute: krxOpenMinute);
    final state = marketState.copyWith(
      pendingOrders: [
        PendingTradeOrder(
          id: 'future-buy',
          side: PendingOrderSide.buy,
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: fictionalMainMarket,
          currency: 'KRW',
          limitPrice: 9000,
          originalQuantity: 1,
          remainingQuantity: 1,
          placedDate: marketDateKey(marketState.currentDate),
          placedMinute: krxOpenMinute + 2,
          placedSequence: 1,
        ),
      ],
    );

    expect(
      () => engine.processPendingOrdersThroughMarketMinute(
        state,
        targetMinute: krxOpenMinute - 1,
        quotePaths: const {},
      ),
      throwsArgumentError,
    );
    expect(
      () => engine.processPendingOrdersThroughMarketMinute(
        state,
        targetMinute: krxOpenMinute + 1,
        quotePaths: const {},
      ),
      throwsArgumentError,
    );
    expect(
      () => engine.processPendingOrdersThroughMarketMinute(
        state,
        targetMinute: krxOpenMinute + 1,
        quotePaths: const {
          'hanbit_telecom': GamePendingOrderQuotePath(
            prices: [8900],
            previousClose: 10000,
            isTradingDay: true,
          ),
        },
      ),
      throwsArgumentError,
    );
    expect(
      () => engine.processPendingOrdersThroughMarketMinute(
        state,
        targetMinute: krxOpenMinute + 1,
        quotePaths: const {
          'hanbit_telecom': GamePendingOrderQuotePath(
            prices: [8900],
            previousClose: 10000,
            isTradingDay: false,
          ),
        },
      ),
      throwsArgumentError,
    );

    final beforePlacement = engine.processPendingOrdersThroughMarketMinute(
      state,
      targetMinute: krxOpenMinute + 1,
      quotePaths: {
        'hanbit_telecom': GamePendingOrderQuotePath(
          prices: List<double>.filled(generatedSessionTicks + 1, 8900),
          previousClose: 10000,
          isTradingDay: true,
        ),
      },
    );
    expect(beforePlacement.marketMinute, krxOpenMinute + 1);
    expect(beforePlacement.pendingOrders, hasLength(1));
    expect(beforePlacement.positions, isEmpty);
  });

  test('legacy non-positive issued-share caps normalize to unknown', () {
    final base = engine.createNewGame('구세이브 주문 연구소', initialCash: 300000);
    final state = base.copyWith(
      day: 4,
      pendingOrders: const [
        PendingTradeOrder(
          id: 'legacy-cap',
          side: PendingOrderSide.buy,
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: fictionalMainMarket,
          currency: 'KRW',
          limitPrice: 9000,
          originalQuantity: 1,
          remainingQuantity: 1,
          placedDate: '2000-01-04',
          placedMinute: krxOpenMinute,
          placedSequence: 1,
          maximumPositionUnits: 10,
        ),
      ],
    );

    for (final legacyMaximum in const [0, -1]) {
      final json = state.toJson();
      final pending =
          (json['pendingOrders'] as List).single as Map<String, dynamic>;
      pending['maximumPositionUnits'] = legacyMaximum;
      final restored = GameState.fromJson(json);
      expect(restored.pendingOrders, hasLength(1));
      expect(restored.pendingOrders.single.maximumPositionUnits, isNull);
    }
  });

  test('pending buy reservation handles multiplicative overflow safely', () {
    final base = engine.createNewGame('예약금 오버플로 연구소', initialCash: 1000);
    final state = base.copyWith(
      day: 4,
      brokerageCash: 123,
      pendingOrders: const [
        PendingTradeOrder(
          id: 'overflow-buy',
          side: PendingOrderSide.buy,
          assetId: 'hanbit_telecom',
          symbol: '1001',
          name: '한빛통신',
          market: fictionalMainMarket,
          currency: 'KRW',
          limitPrice: double.maxFinite,
          originalQuantity: 2,
          remainingQuantity: 2,
          placedDate: '2000-01-04',
          placedMinute: krxOpenMinute,
          placedSequence: 1,
        ),
      ],
    );

    expect(state.pendingBuyReservedCash, 123);
    expect(state.availableBrokerageCash, 0);
  });

  test('pre-v15 saves migrate with an empty pending-order book', () {
    final legacy = engine.createNewGame('주문 마이그레이션').toJson()
      ..remove('pendingOrders')
      ..['version'] = 14;

    final migrated = engine.migrate(legacy);

    expect(migrated.version, GameState.schemaVersion);
    expect(migrated.pendingOrders, isEmpty);
    expect(migrated.availableBrokerageCash, migrated.brokerageCash);
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
    expect(buyWithoutEnoughDeposit.success, isTrue);
    expect(buyWithoutEnoughDeposit.filledQuantity, 1);
    expect(buyWithoutEnoughDeposit.message, contains('즉시 취소'));
  });

  test('T+2 sell proceeds remain buying power but are not withdrawable', () {
    final base = engine
        .createNewGame('결제예정 예수금 연구소', initialCash: 100000)
        .copyWith(day: 4, marketMinute: krxOpenMinute, brokerageCash: 100000);
    final sold = base.copyWith(
      brokerageCash: 160000,
      cash: 160000,
      ledger: [
        ...base.ledger,
        LedgerEntry(
          id: 'trade-sell-settlement-test',
          day: base.day,
          amount: 60000,
          account: 'brokerage_cash',
          counterAccount: 'market_security',
          description: '테스트 매도',
          sourceId: 'trade-sell-settlement-test',
          notional: 60500,
          tradingFee: 100,
          transactionTax: 400,
          assetId: 'hanbit_telecom',
          tradeSide: TradeSide.sell.name,
          tradeQuantity: 10,
          tradeUnitPrice: 6050,
          marketMinute: krxOpenMinute,
          orderType: TradeOrderType.market.name,
        ),
      ],
    );

    expect(sold.availableBrokerageCash, 160000);
    expect(sold.unsettledBrokerageSellProceeds, 60000);
    expect(sold.withdrawableBrokerageCash, 100000);
    final rejected = engine.transferBrokerageCash(
      sold,
      amount: 100001,
      deposit: false,
    );
    expect(rejected.success, isFalse);

    final withdrawn = engine.transferBrokerageCash(
      sold,
      amount: 100000,
      deposit: false,
    );
    expect(withdrawn.success, isTrue);
    expect(withdrawn.state.brokerageCash, 60000);
    expect(withdrawn.state.withdrawableBrokerageCash, 0);

    var settlementDate = sold.currentDate;
    var tradingDays = 0;
    while (tradingDays < 2) {
      settlementDate = settlementDate.add(const Duration(days: 1));
      if (isMarketTradingDay(settlementDate)) tradingDays += 1;
    }
    final settled = sold.copyWith(
      day: settlementDate.difference(sold.campaignStartDate).inDays + 1,
    );
    expect(settled.unsettledBrokerageSellProceeds, 0);
    expect(settled.withdrawableBrokerageCash, 160000);
  });

  test(
    'dynamic VI blocks immediate and pending fills for the trigger minute',
    () {
      final state = engine
          .createNewGame('VI 주문 차단 연구소', initialCash: 1000000)
          .copyWith(day: 4, marketMinute: krxOpenMinute + 1);
      final immediate = engine.executeTrade(
        state,
        hanbitOrder(
          side: TradeSide.buy,
          quantity: 1,
          unitPrice: 10300,
          previousClose: 10000,
          previousTradePrice: 10000,
          marketMinute: krxOpenMinute + 1,
        ),
      );
      expect(immediate.success, isFalse);
      expect(immediate.message, contains('VI'));

      final pendingState = state.copyWith(
        pendingOrders: <PendingTradeOrder>[
          PendingTradeOrder(
            id: 'vi-pending',
            side: PendingOrderSide.buy,
            assetId: 'hanbit_telecom',
            symbol: '1001',
            name: '한빛통신',
            market: fictionalMainMarket,
            currency: 'KRW',
            limitPrice: 10300,
            originalQuantity: 1,
            remainingQuantity: 1,
            placedDate: marketDateKey(state.currentDate),
            placedMinute: krxOpenMinute,
            placedSequence: 1,
          ),
        ],
      );
      final processed = engine.processPendingOrdersAtQuote(
        pendingState,
        assetId: 'hanbit_telecom',
        unitPrice: 10300,
        marketMinute: krxOpenMinute + 1,
        isTradingDay: true,
        previousClose: 10000,
        previousTradePrice: 10000,
      );
      expect(processed.pendingOrders, hasLength(1));
      expect(processed.ledger, hasLength(pendingState.ledger.length));
    },
  );

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
    final nanQuantity = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.buy, quantity: double.nan),
    );
    final invalidLimitQuote = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 1,
        unitPrice: -1,
        type: TradeOrderType.limit,
        limitPrice: 10000,
      ),
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
    final spoofedClosingFill = engine.executeTrade(
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
        type: TradeOrderType.limit,
        limitPrice: 10000,
        isLimitFill: true,
        isClosingAuctionFill: true,
      ),
    );
    final spoofedInternalFill = engine.executeTrade(
      state,
      TradeOrder(
        side: TradeSide.buy,
        assetId: 'hanbit_telecom',
        symbol: '1001',
        name: '한빛통신',
        market: fictionalMainMarket,
        currency: 'KRW',
        quantity: 1,
        unitPrice: 1,
        quoteDate: '2000-01-04',
        marketMinute: krxOpenMinute,
        isTradingDay: true,
        type: TradeOrderType.limit,
        limitPrice: 1,
        previousClose: 10000,
        isLimitFill: true,
      ),
    );
    final excessSell = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.sell, quantity: 1),
    );

    expect(invalidQuantity.success, isFalse);
    expect(nanQuantity.success, isFalse);
    expect(invalidLimitQuote.success, isFalse);
    expect(closed.success, isFalse);
    expect(spoofedClosingFill.success, isFalse);
    expect(spoofedInternalFill.success, isFalse);
    expect(spoofedInternalFill.state.toJson(), state.toJson());
    expect(excessSell.success, isFalse);
    expect(excessSell.message, contains('보유'));
    expect(state.positions, isEmpty);
  });

  test(
    'React v3 date, fractional positions, cash, team, and businesses migrate',
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
      expect(GameState.schemaVersion, 26);
      expect(state.businesses.businesses, isEmpty);
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

    const expectedNotional = 21250;
    final expectedFee = gameTradingFeeForState(migrated, expectedNotional);
    final expectedTax = gameSecuritiesTransactionTax(
      migrated.currentDate,
      expectedNotional,
    );
    expect(result.success, isTrue);
    expect(result.notional, expectedNotional);
    expect(result.fee, expectedFee);
    expect(result.transactionTax, expectedTax);
    final expectedProceeds = expectedNotional - expectedFee - expectedTax;
    final expectedRealizedProfit = expectedProceeds - 15000;
    expect(result.state.cash, 1000 + 15000);
    expect(
      result.state.story.stateRecoveryTotal +
          result.state.story.selfRelianceReserve,
      expectedRealizedProfit,
    );
    expect(result.state.positions, isEmpty);
    final sellLedger = result.state.ledger.firstWhere(
      (entry) =>
          entry.counterAccount == 'market_security' &&
          entry.tradeSide == TradeSide.sell.name,
    );
    expect(sellLedger.description, contains('2.5주 매도'));
    expect(sellLedger.orderBookSide, 'bid');
    expect(sellLedger.orderBookFills, isNotEmpty);
    expect(
      sellLedger.orderBookFills.fold<double>(
        0,
        (sum, fill) => sum + fill.quantity,
      ),
      closeTo(2.5, 0.000001),
    );
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
          brokerageCash: 20000,
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
    expect(state.cash, 100846);
    expect(state.brokerageCash, 20846);
    expect(state.bankCash, 80000);
    expect(state.ledger.first.account, 'brokerage_cash');
    expect(state.ledger, hasLength(3));
    expect(
      state.ledger.any(
        (entry) => entry.counterAccount == 'dividend_withholding_tax',
      ),
      isTrue,
    );
    expect(state.processedEventIds, hasLength(2));
    expect(
      engine.applyCorporateActions(state, const [split, dividend]).toJson(),
      state.toJson(),
    );
  });

  test('closing-auction market conversion preserves issued-share cap', () {
    final base = engine.createNewGame('동시호가 상한 연구소', initialCash: 1000000);
    final state = base.copyWith(
      day: 4,
      marketMinute: krxContinuousEndMinute,
      story: base.story.copyWith(accountAuthorityLevel: 5),
    );

    final queued = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 1,
        marketMinute: krxContinuousEndMinute,
        maximumPositionUnits: 10,
      ),
    );

    expect(queued.success, isTrue);
    expect(queued.filledQuantity, 0);
    expect(queued.state.pendingOrders, hasLength(1));
    expect(queued.state.pendingOrders.single.maximumPositionUnits, 10);
  });

  test(
    'closing auction queues orders and clears once at the official close',
    () {
      final base = engine.createNewGame('동시호가 연구소', initialCash: 2000000000);
      final state = base.copyWith(
        day: 4,
        marketMinute: krxContinuousEndMinute,
        story: base.story.copyWith(accountAuthorityLevel: 5),
      );
      final placed = engine.executeTrade(
        state,
        hanbitOrder(
          side: TradeSide.buy,
          quantity: 100000,
          type: TradeOrderType.limit,
          limitPrice: 10000,
          marketMinute: krxContinuousEndMinute,
        ),
      );
      final closePath = List<double>.filled(generatedSessionTicks + 1, 10000)
        ..[marketTickForMinute(krxCloseMinute)] = 9900;
      final settled = engine.advanceOneDay(
        placed.state.copyWith(decisions: const []),
        pendingOrderQuotePaths: {
          'hanbit_telecom': GamePendingOrderQuotePath(
            prices: closePath,
            previousClose: 10000,
            isTradingDay: true,
          ),
        },
      );

      expect(placed.success, isTrue);
      expect(placed.filledQuantity, 0);
      expect(placed.pendingQuantity, 100000);
      expect(settled.pendingOrders, isEmpty);
      expect(settled.positions.single.units, greaterThan(0));
      expect(settled.positions.single.units, lessThan(100000));
      expect(
        settled.ledger.where(
          (entry) => entry.counterAccount == 'market_security',
        ),
        hasLength(1),
      );
      expect(
        settled.ledger.where(
          (entry) => entry.counterAccount == 'day_order_expiry',
        ),
        hasLength(1),
      );
    },
  );

  test('spinoff allocates cost and cancels affected pending orders', () {
    final base = engine.createNewGame('분할 정산 테스트', initialCash: 100000);
    final state = base.copyWith(
      day: 5,
      marketMinute: krxOpenMinute,
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
      pendingOrders: const [
        PendingTradeOrder(
          id: 'sample-pending-buy',
          side: PendingOrderSide.buy,
          assetId: 'sample',
          symbol: '000001',
          name: '샘플',
          market: fictionalMainMarket,
          currency: 'KRW',
          limitPrice: 9000,
          originalQuantity: 2,
          remainingQuantity: 2,
          placedDate: '2000-01-05',
          placedMinute: krxOpenMinute,
          placedSequence: 1,
        ),
      ],
    );
    const spinoff = MarketCorporateAction(
      id: 'sample-spinoff-2000-01-05',
      assetId: 'sample',
      type: MarketCorporateActionType.spinoff,
      date: '2000-01-05',
      numerator: 1,
      denominator: 5,
      amount: 5000,
      currency: 'KRW',
      source: 'test',
      referencePrice: 10000,
      relatedAssetId: 'sample_child',
      relatedSymbol: '000002',
      relatedName: '샘플자회사',
      relatedMarket: fictionalMainMarket,
    );

    final next = engine.applyCorporateActions(state, const [spinoff]);
    final parent = next.positions.singleWhere(
      (position) => position.assetId == 'sample',
    );
    final child = next.positions.singleWhere(
      (position) => position.assetId == 'sample_child',
    );

    expect(next.pendingOrders, isEmpty);
    expect(
      next.ledger.any(
        (entry) => entry.counterAccount == 'corporate_action_cancel',
      ),
      isTrue,
    );
    expect(child.units, 2);
    expect(parent.totalCost + child.totalCost, 50000);
    expect(child.totalCost, 5000);
  });

  test(
    'merger and share exchange carry cost while tender offer settles cash',
    () {
      final base = engine.createNewGame('기업결합 정산 테스트', initialCash: 100000);
      final sourceState = base.copyWith(
        day: 5,
        positions: const <PortfolioPosition>[
          PortfolioPosition(
            assetId: 'target',
            symbol: '000010',
            name: '피합병회사',
            market: fictionalMainMarket,
            currency: 'KRW',
            units: 10,
            totalCost: 50000,
          ),
        ],
        pendingOrders: const <PendingTradeOrder>[
          PendingTradeOrder(
            id: 'target-pending',
            side: PendingOrderSide.sell,
            assetId: 'target',
            symbol: '000010',
            name: '피합병회사',
            market: fictionalMainMarket,
            currency: 'KRW',
            limitPrice: 7000,
            originalQuantity: 2,
            remainingQuantity: 2,
            placedDate: '2000-01-05',
            placedMinute: krxOpenMinute,
            placedSequence: 1,
          ),
        ],
      );
      const merger = MarketCorporateAction(
        id: 'target-merger-2000-01-05',
        assetId: 'target',
        type: MarketCorporateActionType.merger,
        date: '2000-01-05',
        numerator: 1,
        denominator: 2,
        amount: 0,
        currency: 'KRW',
        source: 'test',
        relatedAssetId: 'buyer',
        relatedSymbol: '000020',
        relatedName: '존속회사',
        relatedMarket: fictionalMainMarket,
      );

      final merged = engine.applyCorporateActions(sourceState, const [merger]);
      expect(merged.pendingOrders, isEmpty);
      expect(merged.positions, hasLength(1));
      expect(merged.positions.single.assetId, 'buyer');
      expect(merged.positions.single.units, 5);
      expect(merged.positions.single.totalCost, 50000);
      expect(merged.ledger.last.counterAccount, 'corporate_merger');
      expect(
        engine.applyCorporateActions(merged, const [merger]).toJson(),
        merged.toJson(),
      );

      const tender = MarketCorporateAction(
        id: 'buyer-tender-2000-01-05',
        assetId: 'buyer',
        type: MarketCorporateActionType.tenderOffer,
        date: '2000-01-05',
        numerator: 1,
        denominator: 1,
        amount: 12000,
        currency: 'KRW',
        source: 'test',
      );
      final tendered = engine.applyCorporateActions(merged, const [tender]);
      expect(tendered.positions, isEmpty);
      expect(tendered.cash, merged.cash + 60000);
      expect(tendered.brokerageCash, merged.brokerageCash + 60000);
      expect(tendered.ledger.last.counterAccount, 'corporate_tender_offer');
      expect(tendered.ledger.last.realizedPnl, 10000);

      const exchange = MarketCorporateAction(
        id: 'target-exchange-2000-01-05',
        assetId: 'target',
        type: MarketCorporateActionType.shareExchange,
        date: '2000-01-05',
        numerator: 3,
        denominator: 2,
        amount: 0,
        currency: 'KRW',
        source: 'test',
        relatedAssetId: 'buyer',
        relatedSymbol: '000020',
        relatedName: '완전모회사',
        relatedMarket: fictionalMainMarket,
      );
      final exchanged = engine.applyCorporateActions(
        sourceState.copyWith(pendingOrders: const <PendingTradeOrder>[]),
        const [exchange],
      );
      expect(exchanged.positions.single.assetId, 'buyer');
      expect(exchanged.positions.single.units, 15);
      expect(exchanged.positions.single.totalCost, 50000);
      expect(exchanged.ledger.last.counterAccount, 'corporate_share_exchange');
    },
  );

  test('shareholder rights are sold once while units stay unchanged', () {
    final base = engine.createNewGame('유상증자 테스트', initialCash: 100000);
    final state = base.copyWith(
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
    const rightsIssue = MarketCorporateAction(
      id: 'sample-rights-2000-01-05',
      assetId: 'sample',
      type: MarketCorporateActionType.rightsIssue,
      date: '2000-01-05',
      numerator: 8,
      denominator: 100,
      amount: 8000,
      currency: 'KRW',
      source: 'test',
      referencePrice: 10000,
      sharesOutstandingBefore: 1000,
      sharesIssued: 80,
    );

    final next = engine.applyCorporateActions(state, const [rightsIssue]);
    final expectedRightsValue = (10 * (10000 - (10000 + 0.08 * 8000) / 1.08))
        .round();

    expect(next.positions.single.units, 10);
    expect(next.positions.single.totalCost, 50000);
    expect(next.cash, state.cash + expectedRightsValue);
    expect(next.brokerageCash, state.brokerageCash + expectedRightsValue);
    expect(next.ledger.last.amount, expectedRightsValue);
    expect(next.ledger.last.counterAccount, 'corporate_rights_sale');
    expect(next.ledger.last.description, contains('신주인수권 자동매각'));
    expect(next.ledger.last.description, contains('보유주식수 유지'));
    expect(next.ledger.last.description, contains('지분율 -7.41%'));
    expect(
      engine.applyCorporateActions(next, const [rightsIssue]).toJson(),
      next.toJson(),
    );
  });

  test(
    'shareholder rights can be subscribed with available brokerage cash',
    () {
      final base = engine.createNewGame('유상증자 청약 테스트', initialCash: 100000);
      final state = base.copyWith(
        day: 5,
        cash: 100000,
        brokerageCash: 100000,
        story: base.story.copyWith(
          storyFlags: {
            ...base.story.storyFlags,
            marketRightsIssuePreferenceFlag:
                marketRightsIssueSubscribePreference,
          },
        ),
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
      const rightsIssue = MarketCorporateAction(
        id: 'sample-rights-subscription-2000-01-05',
        assetId: 'sample',
        type: MarketCorporateActionType.rightsIssue,
        date: '2000-01-05',
        numerator: 8,
        denominator: 100,
        amount: 8000,
        currency: 'KRW',
        source: 'test',
        referencePrice: 10000,
        sharesOutstandingBefore: 1000,
        sharesIssued: 80,
      );

      final next = engine.applyCorporateActions(state, const [rightsIssue]);

      expect(next.positions.single.units, closeTo(10.8, 0.000001));
      expect(next.positions.single.totalCost, 56400);
      expect(next.cash, 93600);
      expect(next.brokerageCash, 93600);
      expect(next.ledger.last.amount, -6400);
      expect(next.ledger.last.counterAccount, 'corporate_rights_subscription');
      expect(next.ledger.last.description, contains('0.8주 배정'));
    },
  );

  test('rights subscription falls back to sale when cash is reserved', () {
    final base = engine.createNewGame('유상증자 예약금 테스트', initialCash: 100000);
    final state = base.copyWith(
      day: 5,
      cash: 100000,
      brokerageCash: 6500,
      story: base.story.copyWith(
        storyFlags: {
          ...base.story.storyFlags,
          marketRightsIssuePreferenceFlag: marketRightsIssueSubscribePreference,
        },
      ),
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
      pendingOrders: const [
        PendingTradeOrder(
          id: 'reserved-buy',
          side: PendingOrderSide.buy,
          assetId: 'other',
          symbol: '000002',
          name: '다른 종목',
          market: fictionalMainMarket,
          currency: 'KRW',
          limitPrice: 1000,
          originalQuantity: 1,
          remainingQuantity: 1,
          placedDate: '2000-01-05',
          placedMinute: krxOpenMinute,
          placedSequence: 1,
        ),
      ],
    );
    const rightsIssue = MarketCorporateAction(
      id: 'sample-rights-reserved-2000-01-05',
      assetId: 'sample',
      type: MarketCorporateActionType.rightsIssue,
      date: '2000-01-05',
      numerator: 8,
      denominator: 100,
      amount: 8000,
      currency: 'KRW',
      source: 'test',
      referencePrice: 10000,
      sharesOutstandingBefore: 1000,
      sharesIssued: 80,
    );

    final next = engine.applyCorporateActions(state, const [rightsIssue]);

    expect(next.positions.single.units, 10);
    expect(next.ledger.last.counterAccount, 'corporate_rights_sale');
    expect(next.ledger.last.description, contains('청약대금 부족'));
  });

  test('third-party rights issue dilutes without TERP or rights proceeds', () {
    final base = engine.createNewGame('제3자배정 테스트', initialCash: 100000);
    final state = base.copyWith(
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
    const thirdPartyIssue = MarketCorporateAction(
      id: 'sample-third-party-rights-2000-01-05',
      assetId: 'sample',
      type: MarketCorporateActionType.rightsIssue,
      date: '2000-01-05',
      numerator: 8,
      denominator: 100,
      amount: 8000,
      currency: 'KRW',
      source: 'test',
      referencePrice: 10000,
      sharesOutstandingBefore: 1000,
      sharesIssued: 80,
      allocationMethod: MarketRightsIssueAllocationMethod.thirdParty,
    );

    final next = engine.applyCorporateActions(state, const [thirdPartyIssue]);

    expect(thirdPartyIssue.theoreticalExRightsPrice, isNull);
    expect(next.positions.single.units, 10);
    expect(next.cash, state.cash);
    expect(next.brokerageCash, state.brokerageCash);
    expect(next.ledger.last.amount, 0);
    expect(next.ledger.last.counterAccount, 'corporate_rights_issue');
    expect(next.ledger.last.description, contains('제3자배정'));
    expect(next.ledger.last.description, contains('신주인수권 없음'));
  });

  test('earned seed money unlocks the first state-account order authority', () {
    final base = engine.createNewGame('종잣돈 권한 테스트', initialCash: 0);
    final state = base.copyWith(
      story: base.story.copyWith(
        storyFlags: {...base.story.storyFlags, 'earnedSeedMoney': 9500},
      ),
    );
    final next = engine.completeWorkSession(
      state,
      const WorkSessionResult(activityId: 'dishes', score: 100, maxScore: 100),
    );
    expect(next.story.startingSeedMoney, 0);
    expect(next.story.earnedSeedMoney, greaterThanOrEqualTo(10000));
    expect(next.story.accountAuthorityLevel, 1);
    expect(next.story.reputation, 3);
  });

  test('state-account authority enforces the displayed per-order limit', () {
    final funded = engine.createNewGame('주문 한도 테스트', initialCash: 300000);
    final state = funded.copyWith(
      day: 4,
      marketMinute: 9 * 60,
      story: funded.story.copyWith(accountAuthorityLevel: 1),
    );
    final result = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: 15,
        type: TradeOrderType.limit,
        limitPrice: 9000,
      ),
    );
    expect(result.success, isFalse);
    expect(result.message, contains('100000'));
  });

  test('hiring creates payroll and monthly research cash flow', () {
    final january31 =
        DateTime(2003, 1, 31).difference(DateTime(2000, 1, 1)).inDays + 1;
    var state = engine
        .createNewGame('채용 경제 테스트', initialCash: 500000)
        .copyWith(day: january31, brokerageCash: 0, decisions: const []);
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
        .copyWith(day: 1500, brokerageCash: 0, decisions: const []);
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
    expect(migrated.cash, initialCompanyCash);
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
          .copyWith(day: december31, brokerageCash: 0, decisions: const []);

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
          .copyWith(day: december31, brokerageCash: 0, decisions: const []);
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
      final januaryEnd = january.copyWith(
        day: DateTime(2007, 1, 31).difference(DateTime(2000, 1, 1)).inDays + 1,
      );
      final february = engine.advanceOneDay(januaryEnd);
      final earlySale = engine.sellRealEstate(january, asset.id);
      final eligible = january.copyWith(day: asset.acquiredDay + 30);
      final listed = engine.sellRealEstate(eligible, asset.id);
      final listedAsset = listed.state.personalFinance.realEstate.single;
      final offerState = listed.state.copyWith(
        day: listedAsset.saleOfferReadyDay,
      );
      final sale = engine.sellRealEstate(offerState, listedAsset.id);

      expect(purchase.success, isTrue);
      expect(january.personalFinance.monthlyPropertyCost, 40000);
      expect(
        january.ledger.any(
          (entry) => entry.counterAccount == 'property_maintenance',
        ),
        isFalse,
        reason: '월말 매입 다음 날에는 유지비를 즉시 청구하지 않는다.',
      );
      expect(
        february.ledger.any(
          (entry) => entry.counterAccount == 'property_maintenance',
        ),
        isTrue,
      );
      expect(
        january.ledger.any((entry) => entry.counterAccount == 'rent_expense'),
        isFalse,
      );
      expect(earlySale.success, isFalse);
      expect(listed.success, isTrue);
      expect(listed.cashDelta, 0);
      expect(sale.success, isTrue);
      expect(sale.state.personalFinance.realEstate, isEmpty);
      expect(sale.cashDelta, greaterThan(0));
    },
  );

  test('new commercial property starts vacant and charges carrying costs', () {
    final december31 =
        DateTime(2008, 12, 31).difference(DateTime(2000, 1, 1)).inDays + 1;
    final base = engine
        .createNewGame(
          '임대 자산 테스트',
          initialCash: 20000000,
          worldSeed: 'commercial-carrying-cost-test',
        )
        .copyWith(day: december31, brokerageCash: 0, decisions: const []);
    final legal = base.copyWith(
      story: base.story.copyWith(
        storyFlags: {...base.story.storyFlags, 'isLegalCompany': true},
      ),
    );
    final purchase = engine.purchaseSpendingOption(legal, 'commercial_unit');
    final january = engine.advanceOneDay(purchase.state);
    final januaryEnd = january.copyWith(
      day: DateTime(2009, 1, 31).difference(DateTime(2000, 1, 1)).inDays + 1,
    );
    final february = engine.advanceOneDay(januaryEnd);

    expect(purchase.success, isTrue);
    expect(
      purchase.state.personalFinance.realEstate.single.leaseType,
      RealEstateLeaseType.vacant,
    );
    expect(
      january.ledger.any(
        (entry) => entry.counterAccount == 'property_rent_income',
      ),
      isFalse,
    );
    expect(
      february.ledger
          .where(
            (entry) =>
                entry.counterAccount == 'property_maintenance' &&
                entry.amount < 0,
          )
          .single
          .amount,
      -25000,
    );
    expect(february.personalFinance.totalPropertyIncome, 0);
  });

  test(
    'chance entertainment is adult-only, capped, deterministic, and monthly',
    () {
      final january1 =
          DateTime(2010, 1, 1).difference(DateTime(2000, 1, 1)).inDays + 1;
      final adult = engine
          .createNewGame('확률 오락 테스트', initialCash: 10000000)
          .copyWith(day: january1, brokerageCash: 0, decisions: const []);
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

  test('simulation epoch precedes the Monday account opening at 08:00', () {
    final story = StoryState.newPlayer(
      playerName: '민준',
      introChoice: 'computer',
      startingTrait: StoryTrait.analysis,
      operatingPrinciple: OperatingPrinciple.reportLosses,
    );
    final initial = engine.createNewGame('일요일 시작 연구소', story: story);

    expect(initial.cash, initialCompanyCash);
    expect(initial.currentDate, DateTime(2000, 1, 1));
    expect(initial.currentDate.weekday, DateTime.saturday);
    expect(initial.marketMinute, marketDayStartMinute);

    final closed = initial.copyWith(
      decisions: const [],
      marketMinute: marketDayEndMinute,
    );
    final sunday = engine.advanceOneDay(closed);
    final monday = engine.advanceOneDay(
      sunday.copyWith(decisions: const [], marketMinute: marketDayEndMinute),
    );

    expect(sunday.currentDate, DateTime(2000, 1, 2));
    expect(monday.currentDate, DateTime(2000, 1, 3));
    expect(monday.currentDate.weekday, DateTime.monday);
    expect(isMarketTradingDay(monday.currentDate), isTrue);
    expect(monday.marketMinute, marketDayStartMinute);
  });

  test('market reports use bank cash and never drain brokerage cash', () {
    final funded = engine
        .createNewGame(
          '보고서 계정 분리 테스트',
          initialCash: 100000,
          worldSeed: 'report-account-world',
        )
        .copyWith(
          day: dayWithFutureMarketSignal('report-account-world'),
          marketMinute: marketDayStartMinute,
        );

    final rejected = engine.purchaseDailyMarketReport(funded);
    expect(rejected.success, isFalse);
    expect(rejected.message, contains('은행 잔고'));
    expect(rejected.state.toJson(), funded.toJson());

    final withdrawal = engine.transferBrokerageCash(
      funded,
      amount: dailyMarketReportPrice,
      deposit: false,
    );
    final purchased = engine.purchaseDailyMarketReport(withdrawal.state);

    expect(withdrawal.success, isTrue);
    expect(purchased.success, isTrue);
    expect(purchased.state.cash, 100000 - dailyMarketReportPrice);
    expect(purchased.state.brokerageCash, 100000 - dailyMarketReportPrice);
    expect(purchased.state.bankCash, 0);
    expect(purchased.state.ledger.last.account, 'company_bank');
  });

  test('monthly unpaid costs keep cash and ledger amounts reconciled', () {
    final january31 =
        DateTime(2000, 1, 31).difference(DateTime(2000, 1, 1)).inDays + 1;
    final base = engine.createNewGame('미지급금 테스트', initialCash: 100000);
    final state = base.copyWith(
      day: january31,
      brokerageCash: 90000,
      decisions: const [],
      story: base.story.copyWith(
        storyFlags: {...base.story.storyFlags, 'officeTier': 1},
      ),
    );
    final ledgerLength = state.ledger.length;

    final next = engine.advanceOneDay(state);
    final monthlyEntries = next.ledger.skip(ledgerLength).toList();
    final bookedCashDelta = monthlyEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.amount,
    );
    final payable = monthlyEntries.singleWhere(
      (entry) => entry.counterAccount == 'operating_expense_accrual',
    );

    expect(next.currentDate, DateTime(2000, 2, 1));
    expect(next.cash - state.cash, bookedCashDelta);
    expect(next.brokerageCash, state.brokerageCash);
    expect(next.bankCash, 0);
    expect(next.story.flagInt('unpaidOperatingCost'), payable.notional);
    expect(payable.amount, 0);
    expect(payable.notional, greaterThan(0));
  });

  test(
    'the first control opportunity opens in 2005 with three stake levels',
    () {
      final offered = advanceToControlOffer();

      expect(offered.currentDate, DateTime(2005, 1, 1));
      expect(offered.story.flagBool('controlOfferPresented'), isTrue);
      expect(offered.pendingDecisions, hasLength(1));
      expect(offered.pendingDecisions.single.id, startsWith('control-offer-'));
      expect(
        offered.pendingDecisions.single.options.map((option) => option.id),
        containsAll(<String>[
          'acquire_board_observer',
          'acquire_board_stake',
          'acquire_control',
          'review_control',
        ]),
      );
    },
  );

  test('minority stake preserves book value and can step up to control', () {
    final offered = advanceToControlOffer();
    final netWorthBefore = offered.balanceSheetNetWorth();
    final observer = engine.resolveDecision(
      offered,
      offered.pendingDecisions.single.id,
      'acquire_board_observer',
    );

    expect(observer.company.id, 'hanbit_components');
    expect(observer.company.name, '한빛전자부품');
    expect(observer.company.effectiveEconomicOwnershipPct, 18);
    expect(observer.company.votingOwnershipPct, 18);
    expect(observer.company.boardObserver, isTrue);
    expect(observer.company.boardSeats, 0);
    expect(observer.company.isControlled, isFalse);
    expect(observer.company.controlTierLabel, '이사회 관찰');
    expect(observer.company.investmentBookValue, 120000);
    expect(observer.company.monthlyOwnerDistribution, 1512);
    expect(observer.balanceSheetNetWorth(), netWorthBefore);
    expect(
      observer.ledger.last.counterAccount,
      'controlled_company_investment',
    );
    expect(observer.ledger.last.assetId, 'hanbit_components');
    expect(observer.scheduledEvents.single.type, 'control_stake_followup');

    final restored = GameState.fromJson(observer.toJson());
    expect(restored.company.effectiveEconomicOwnershipPct, 18);
    expect(restored.company.boardObserver, isTrue);
    expect(restored.company.investmentBookValue, 120000);

    final followUpEvent = observer.scheduledEvents.single;
    final waiting = observer.copyWith(
      day: followUpEvent.dueDay - 1,
      processedEventIds: [
        ...observer.processedEventIds,
        'era-technology-2005-spring',
      ],
    );
    final followUp = engine.advanceOneDay(waiting);
    expect(
      followUp.pendingDecisions.single.id,
      startsWith('control-stake-followup-'),
    );
    final beforeStepUp = followUp.balanceSheetNetWorth();
    final controlled = engine.resolveDecision(
      followUp,
      followUp.pendingDecisions.single.id,
      'complete_control',
    );

    expect(controlled.company.votingOwnershipPct, 55);
    expect(controlled.company.boardSeats, 4);
    expect(controlled.company.hasBoardMajority, isTrue);
    expect(controlled.company.isControlled, isTrue);
    expect(controlled.company.investmentBookValue, 350000);
    expect(controlled.balanceSheetNetWorth(), beforeStepUp);
    expect(
      controlled.pendingDecisions.single.id,
      startsWith('control-transition-'),
    );
  });

  test('direct control leads to leadership and factory strategy decisions', () {
    final offered = advanceToControlOffer();
    final netWorthBefore = offered.balanceSheetNetWorth();
    final controlled = engine.resolveDecision(
      offered,
      offered.pendingDecisions.single.id,
      'acquire_control',
    );

    expect(controlled.company.votingOwnershipPct, 55);
    expect(controlled.company.boardSeats, 4);
    expect(controlled.company.controlTierLabel, '경영권');
    expect(controlled.company.investmentBookValue, 300000);
    expect(controlled.balanceSheetNetWorth(), netWorthBefore);
    expect(controlled.pendingDecisions.single.category, '첫 이사회');

    final employeeCount = controlled.organization.employees.length;
    final leadership = engine.resolveDecision(
      controlled,
      controlled.pendingDecisions.single.id,
      'appoint_academy_advisor',
    );
    expect(
      leadership.company.leadershipModel,
      CompanyLeadershipModel.academyAdvisor,
    );
    expect(leadership.story.flagBool('academyOperationsAdvisor'), isTrue);
    expect(leadership.organization.employees.length, employeeCount);
    expect(leadership.pendingDecisions.single.category, '공장 운영계획');

    final beforeStrategy = leadership.balanceSheetNetWorth();
    final strategy = engine.resolveDecision(
      leadership,
      leadership.pendingDecisions.single.id,
      'protect_skilled_workforce',
    );
    expect(strategy.company.investmentBookValue, 390000);
    expect(strategy.company.monthlyRevenue, 175000);
    expect(strategy.company.monthlyOperatingCost, 140000);
    expect(strategy.company.monthlyOperatingProfit, 35000);
    expect(strategy.company.monthlyOwnerDistribution, 5775);
    final lossCompany = strategy.company.copyWith(monthlyOperatingCost: 200000);
    expect(lossCompany.monthlyOperatingProfit, -25000);
    expect(lossCompany.monthlyOwnerDistribution, 0);
    expect(strategy.balanceSheetNetWorth(), beforeStrategy);
    expect(strategy.ledger.last.counterAccount, 'controlled_company_capital');
    expect(
      strategy.story.storyFlags['controlledCompanyStrategy'],
      'skilled_workforce',
    );
  });

  test('legacy v20 control save gains safe governance defaults', () {
    final base = engine.createNewGame(
      'v20 경영권 복원',
      initialCash: 777777,
      worldSeed: 'legacy-control-world',
    );
    final json = Map<String, dynamic>.from(base.toJson());
    final company = Map<String, dynamic>.from(json['company'] as Map)
      ..['votingOwnershipPct'] = 55
      ..['worldStartedAtDay'] = 30
      ..remove('economicOwnershipPct')
      ..remove('boardObserver')
      ..remove('boardSeats')
      ..remove('totalBoardSeats')
      ..remove('investmentBookValue')
      ..remove('acquiredAtDay')
      ..remove('leadershipModel')
      ..remove('monthlyOperatingCost');
    json['version'] = 20;
    json['company'] = company;

    final migrated = engine.migrate(json);

    expect(migrated.version, GameState.schemaVersion);
    expect(migrated.cash, base.cash);
    expect(migrated.day, base.day);
    expect(migrated.company.votingOwnershipPct, 55);
    expect(migrated.company.effectiveEconomicOwnershipPct, 55);
    expect(migrated.company.boardSeats, 4);
    expect(migrated.company.totalBoardSeats, 7);
    expect(migrated.company.controlTierLabel, '경영권');
    expect(migrated.company.investmentBookValue, 0);
    expect(migrated.company.leadershipModel, CompanyLeadershipModel.unassigned);
  });

  test('semiannual era choices make the 20-decision mission attainable', () {
    var state = resolveFirst(
      engine.createNewGame(
        '시대 결정 테스트',
        initialCash: 0,
        worldSeed: 'era-decision-world',
      ),
      'research_products',
    );

    for (var year = 2000; year <= 2010; year++) {
      for (final triggerDate in [
        DateTime(year, 3, 31),
        DateTime(year, 9, 30),
      ]) {
        final day = triggerDate.difference(state.campaignStartDate).inDays + 1;
        state = state.copyWith(day: day, decisions: state.decisions);
        state = engine.advanceOneDay(state);
        expect(
          state.pendingDecisions.single.category,
          '시대 기술 검토',
          reason: '$year ${triggerDate.month}',
        );
        state = resolveFirst(state, 'era_observe');
      }
    }

    final resolved = state.decisions
        .where((decision) => decision.status == DecisionStatus.resolved)
        .length;
    expect(resolved, greaterThanOrEqualTo(20));
  });

  test(
    'prudent office milestone does not force rent, while expansion does',
    () {
      final initial = resolveFirst(
        engine.createNewGame('사무실 선택 테스트', initialCash: 1000000),
        'research_products',
      );
      final officeDate = DateTime(2004, 1, 2);
      final beforeOfficeDay = officeDate
          .difference(initial.campaignStartDate)
          .inDays;
      final offered = engine.advanceOneDay(
        initial.copyWith(day: beforeOfficeDay, decisions: initial.decisions),
      );

      final prudent = engine.resolveDecision(
        offered,
        offered.pendingDecisions.single.id,
        'milestone_prudent',
      );
      final bold = engine.resolveDecision(
        offered,
        offered.pendingDecisions.single.id,
        'milestone_bold',
      );

      expect(prudent.story.officeTier, 0);
      expect(prudent.story.flagBool('officePlanDeferred'), isTrue);
      expect(bold.story.officeTier, 1);
      expect(bold.story.flagBool('officeLeaseAccepted'), isTrue);

      final january31 =
          DateTime(2004, 1, 31).difference(initial.campaignStartDate).inDays +
          1;
      final prudentFebruary = engine.advanceOneDay(
        prudent.copyWith(
          day: january31,
          brokerageCash: 0,
          decisions: prudent.decisions,
        ),
      );
      final boldFebruary = engine.advanceOneDay(
        bold.copyWith(
          day: january31,
          brokerageCash: 0,
          decisions: bold.decisions,
        ),
      );
      expect(
        prudentFebruary.ledger.where(
          (entry) => entry.counterAccount == 'rent_expense',
        ),
        isEmpty,
      );
      expect(
        boldFebruary.ledger.any(
          (entry) => entry.counterAccount == 'rent_expense',
        ),
        isTrue,
      );
    },
  );

  test(
    'large market orders use finite depth and cancel the unfilled remainder',
    () {
      final state = engine
          .createNewGame('대량 주문 테스트', initialCash: 1000000000)
          .copyWith(day: 4, marketMinute: 9 * 60);
      final snapshot = buildGameOrderBookSnapshot(
        assetId: 'hanbit_telecom',
        day: marketLiquidityDayKey(state.currentDate),
        minute: state.marketMinute,
        currentPrice: 10000,
        previousClose: 10000,
        date: state.currentDate,
        market: fictionalMainMarket,
        simulationSeed: state.simulationSeed,
      );
      final liquidityLimit = gameMarketOrderNotionalLimit(
        10000,
        turnoverEok: snapshot.turnoverEok,
      );
      final requested = snapshot.executionCapacity * 2 + 1000;
      final expectedPlan = gameOrderBookLimitFillPlan(
        snapshot: snapshot,
        isBuy: true,
        requestedQuantity: requested.toDouble(),
        limitPrice: marketDailyPriceRange(
          previousClose: 10000,
          date: state.currentDate,
          market: fictionalMainMarket,
        ).upper,
        availableCapacity: snapshot.executionCapacity,
        maximumNotional: gameBuyNotionalBudget(
          state,
          maximumNotional: math.min(
            liquidityLimit,
            gameOrderAuthorityLimit(state),
          ),
        ),
      );

      final filled = engine.executeTrade(
        state,
        hanbitOrder(side: TradeSide.buy, quantity: requested.toDouble()),
      );

      expect(filled.success, isTrue);
      expect(filled.filledQuantity, expectedPlan.filledQuantity);
      expect(filled.notional, greaterThan(0));
      expect(filled.notional, lessThanOrEqualTo(liquidityLimit));
      expect(filled.message, contains('즉시 취소'));
      expect(gameMaxBuyQuantity(state, 10000), greaterThan(0));
    },
  );

  test('market order average price comes from consumed ask levels', () {
    final base = engine.createNewGame('시장가 호가 평균 테스트', initialCash: 1000000000);
    final state = base.copyWith(
      day: 4,
      marketMinute: 9 * 60,
      story: base.story.copyWith(accountAuthorityLevel: 5),
    );
    final snapshot = buildGameOrderBookSnapshot(
      assetId: 'hanbit_telecom',
      day: marketLiquidityDayKey(state.currentDate),
      minute: state.marketMinute,
      currentPrice: 252500,
      previousClose: 252500,
      date: state.currentDate,
      market: fictionalMainMarket,
      simulationSeed: state.simulationSeed,
    );
    final requested = math.min(1000, snapshot.executionCapacity);
    final range = marketDailyPriceRange(
      previousClose: 252500,
      date: state.currentDate,
      market: fictionalMainMarket,
    );
    final plan = gameOrderBookLimitFillPlan(
      snapshot: snapshot,
      isBuy: true,
      requestedQuantity: requested.toDouble(),
      limitPrice: range.upper,
      availableCapacity: snapshot.executionCapacity,
    );
    final result = engine.executeTrade(
      state,
      hanbitOrder(
        side: TradeSide.buy,
        quantity: requested.toDouble(),
        unitPrice: 252500,
        previousClose: 252500,
      ),
    );

    expect(result.success, isTrue);
    expect(result.filledQuantity, plan.filledQuantity);
    expect(result.averageFillPrice, plan.averagePrice);
    expect(result.notional, plan.notional);
    expect(
      result.averageFillPrice,
      greaterThanOrEqualTo(snapshot.asks.first.price),
    );
    expect(result.averageFillPrice, lessThanOrEqualTo(plan.worstPrice));
  });

  test('market IOC stays inside authority after walking to higher asks', () {
    final base = engine.createNewGame('시장가 권한 예산 테스트', initialCash: 100000000);
    final state = base.copyWith(
      day: 4,
      marketMinute: krxOpenMinute,
      story: base.story.copyWith(accountAuthorityLevel: 2),
    );
    final requested = gameMaxBuyQuantity(state, 10000);
    final result = engine.executeTrade(
      state,
      hanbitOrder(side: TradeSide.buy, quantity: requested.toDouble()),
    );

    expect(result.success, isTrue);
    expect(result.filledQuantity, greaterThan(0));
    expect(result.filledQuantity, lessThanOrEqualTo(requested));
    expect(result.notional, lessThanOrEqualTo(gameOrderAuthorityLimit(state)));
    expect(
      result.notional + result.fee,
      lessThanOrEqualTo(state.availableBrokerageCash),
    );
  });

  test('generated IPO positions survive a save migration intact', () async {
    const worldSeed = 'generated-ipo-save-world';
    final universe = await FictionalMarketUniverse.load(
      seed: worldSeed,
      throughDate: DateTime(2000, 12, 31),
    );
    final ipo = universe.assets.firstWhere(
      (asset) => asset.listedOn != null && asset.parentAssetId == null,
    );
    final original = engine
        .createNewGame('신규상장 저장 테스트', initialCash: 100000, worldSeed: worldSeed)
        .copyWith(
          positions: [
            PortfolioPosition(
              assetId: ipo.id,
              symbol: ipo.symbol,
              name: ipo.name,
              market: ipo.market,
              currency: ipo.currency,
              units: 7,
              totalCost: 77000,
            ),
          ],
        );

    final restored = engine.migrate(original.toJson());

    expect(restored.positions, hasLength(1));
    expect(restored.positions.single.assetId, ipo.id);
    expect(restored.positions.single.totalCost, 77000);
    expect(restored.cash, original.cash);
    expect(
      restored.ledger.where(
        (entry) => entry.counterAccount == 'legacy_position_recovery',
      ),
      isEmpty,
    );
  });

  test('the campaign cannot advance beyond 2026-12-31', () {
    final state = engine
        .createNewGame('캠페인 종료 테스트')
        .copyWith(day: GameState.maxCampaignDay, decisions: const []);
    final next = engine.advanceOneDay(state);
    expect(next.day, GameState.maxCampaignDay);
    expect(next.currentDate, DateTime(2026, 12, 31));
    expect(next.toJson(), state.toJson());
  });
}
