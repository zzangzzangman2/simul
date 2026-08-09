part of 'main.dart';

class OfficeScreen extends StatelessWidget {
  const OfficeScreen({
    super.key,
    required this.state,
    this.stateReader,
    required this.engine,
    this.stockOrderBookSessionCache,
    required this.activeSaveSlot,
    required this.lastSavedAt,
    required this.onManualSave,
    required this.onReturnToTitle,
    required this.onAdvanceDay,
    this.onAdvanceDays,
    required this.onSetMarketMinute,
    required this.onSaveMarketNotebook,
    this.onSetMarketRightsIssuePreference,
    required this.onResolveDecision,
    required this.onRequestAcademyHelp,
    this.onCompleteRelationshipEvening,
    this.onRestDuringRelationshipEvening,
    this.onCompleteWeekdayActivity,
    this.onCompleteWeeklyPortfolioReview,
    this.onCompleteWeekendActivity,
    this.onSettleCohortInvestmentDay,
    this.onLendToCohortInvestor,
    this.onBorrowFromCohortInvestor,
    this.onAcknowledgeCohortInvestmentReport,
    this.onSettleCohortDailyRollCall,
    this.onAcknowledgeCohortStandingEvent,
    this.onRespondToCohortWithdrawal,
    this.onMarkPhoneThreadRead,
    this.onSendPhoneMessage,
    this.onSendPhoneGift,
    this.phoneAiService,
    this.onHireEmployee,
    this.onLaunchFund,
    this.onPurchaseSpendingOption,
    this.onPurchaseHomeImprovement,
    this.onAcquireBusiness,
    this.onUpdateBusinessPolicy,
    this.onInvestInBusiness,
    this.onCloseBusiness,
    this.onChooseBusinessEvent,
    this.onSellRealEstate,
    this.onConfigureRealEstateLease,
    this.onCancelRealEstateSaleListing,
    this.onSaveRealEstateInvestmentNote,
    this.onRenovateRealEstate,
    this.onSetRealEstateInsurance,
    this.onRenewRealEstateMonthlyLease,
    this.onTerminateRealEstateMonthlyLeaseEarly,
    this.onPrepayRealEstateMortgage,
    this.onRefinanceRealEstateMortgage,
    this.onPlayChanceGame,
    this.onExchangeCasinoChips,
    this.onCashOutCasinoChips,
    this.onPlayCasinoRound,
    this.onStartCasinoBlackjack,
    this.onCasinoBlackjackAction,
    this.onCasinoCrapsRoll,
    this.onSettleHorseRace,
    this.onOpenTimeDeposit,
    this.onRedeemTimeDeposit,
    this.onTakeUnsecuredLoan,
    this.onRepayUnsecuredLoan,
    this.onPurchaseMarketReport,
    this.onCompleteHubTutorial,
    this.onCompleteMarketTutorial,
    this.onCompleteNationalNetworkBriefing,
    this.onCompleteBankDepositTutorial,
    this.onCompleteRealEstateTutorial,
    this.onArchiveNews,
    this.onBuildDailyNewspaper,
    required this.onCompleteWork,
    required this.onExecuteTrade,
    this.onSaveGovernanceState,
    this.onCancelPendingOrder,
    this.onTransferBrokerageCash,
  });

  final GameState state;
  final ValueGetter<GameState>? stateReader;
  final GameEngine engine;
  final StockOrderBookSessionCache? stockOrderBookSessionCache;
  final int activeSaveSlot;
  final DateTime? lastSavedAt;
  final Future<void> Function() onManualSave;
  final VoidCallback onReturnToTitle;
  final Future<GameState> Function() onAdvanceDay;
  final Future<GameState> Function(int days)? onAdvanceDays;
  final Future<GameState> Function(int) onSetMarketMinute;
  final Future<GameState> Function(Set<String>, Map<String, String>)
  onSaveMarketNotebook;
  final Future<GameState> Function(bool subscribe)?
  onSetMarketRightsIssuePreference;
  final Future<void> Function(String, String) onResolveDecision;
  final Future<GameState> Function(String) onRequestAcademyHelp;
  final Future<RelationshipActionResult> Function(
    String girlId,
    RelationshipActivity activity,
    String choiceId,
  )?
  onCompleteRelationshipEvening;
  final Future<RelationshipActionResult> Function()?
  onRestDuringRelationshipEvening;
  final Future<WeekdayActivityResult> Function(String activityId)?
  onCompleteWeekdayActivity;
  final Future<GameState> Function({
    required WeeklyPortfolioReviewAction action,
    required String assetId,
    required String assetName,
    required int riskLimitBps,
  })?
  onCompleteWeeklyPortfolioReview;
  final Future<WeekendActivityResult> Function(WeekendActivityRequest request)?
  onCompleteWeekendActivity;
  final Future<CohortInvestmentActionResult> Function()?
  onSettleCohortInvestmentDay;
  final Future<CohortInvestmentActionResult> Function(
    String borrowerId,
    int amount,
  )?
  onLendToCohortInvestor;
  final Future<CohortInvestmentActionResult> Function(
    String lenderId,
    int amount,
  )?
  onBorrowFromCohortInvestor;
  final Future<CohortInvestmentActionResult> Function()?
  onAcknowledgeCohortInvestmentReport;
  final Future<CohortRollCallActionResult> Function()?
  onSettleCohortDailyRollCall;

  /// 수익률 순위표가 촉발한 사건을 확인 처리한다.
  final Future<void> Function(CohortStandingEvent)?
  onAcknowledgeCohortStandingEvent;

  /// 동기가 꺼낸 중단권 이야기에 응답한다.
  final Future<CohortWithdrawalOutcome> Function(CohortWithdrawalResponse)?
  onRespondToCohortWithdrawal;
  final Future<PhoneMessengerActionResult> Function(String contactId)?
  onMarkPhoneThreadRead;
  final Future<PhoneMessengerActionResult> Function(
    String contactId,
    String text,
  )?
  onSendPhoneMessage;
  final Future<PhoneMessengerActionResult> Function(
    String contactId,
    String giftId,
  )?
  onSendPhoneGift;
  final PhoneAiService? phoneAiService;
  final Future<GameState> Function(String)? onHireEmployee;
  final Future<GameState> Function()? onLaunchFund;
  final Future<FinanceActionResult> Function(String optionId)?
  onPurchaseSpendingOption;
  final Future<FinanceActionResult> Function(String improvementId)?
  onPurchaseHomeImprovement;
  final BusinessAcquireCallback? onAcquireBusiness;
  final BusinessPolicyUpdateCallback? onUpdateBusinessPolicy;
  final BusinessInvestmentCallback? onInvestInBusiness;
  final BusinessCloseCallback? onCloseBusiness;
  final BusinessEventChoiceCallback? onChooseBusinessEvent;
  final Future<FinanceActionResult> Function(String assetId)? onSellRealEstate;
  final Future<FinanceActionResult> Function(
    String assetId,
    RealEstateLeaseType leaseType,
  )?
  onConfigureRealEstateLease;
  final Future<FinanceActionResult> Function(String assetId)?
  onCancelRealEstateSaleListing;
  final Future<FinanceActionResult> Function(String assetId, String note)?
  onSaveRealEstateInvestmentNote;
  final Future<FinanceActionResult> Function(String assetId)?
  onRenovateRealEstate;
  final Future<FinanceActionResult> Function(String assetId, bool active)?
  onSetRealEstateInsurance;
  final Future<FinanceActionResult> Function(String assetId)?
  onRenewRealEstateMonthlyLease;
  final Future<FinanceActionResult> Function(String assetId)?
  onTerminateRealEstateMonthlyLeaseEarly;
  final Future<FinanceActionResult> Function(String assetId, int amount)?
  onPrepayRealEstateMortgage;
  final Future<FinanceActionResult> Function(
    String assetId, {
    required bool variableRate,
    int? termMonths,
  })?
  onRefinanceRealEstateMortgage;
  final Future<FinanceActionResult> Function(int stake)? onPlayChanceGame;
  final Future<CasinoActionResult> Function(int amount)? onExchangeCasinoChips;
  final Future<CasinoActionResult> Function()? onCashOutCasinoChips;
  final Future<CasinoActionResult> Function(CasinoBet bet)? onPlayCasinoRound;
  final Future<CasinoActionResult> Function(int stake)? onStartCasinoBlackjack;
  final Future<CasinoActionResult> Function(BlackjackAction action)?
  onCasinoBlackjackAction;
  final Future<CasinoActionResult> Function()? onCasinoCrapsRoll;
  final Future<HorseRaceActionResult> Function(HorseRaceSessionResult session)?
  onSettleHorseRace;
  final BankOpenDepositCallback? onOpenTimeDeposit;
  final BankRedeemDepositCallback? onRedeemTimeDeposit;
  final BankTakeLoanCallback? onTakeUnsecuredLoan;
  final BankRepayLoanCallback? onRepayUnsecuredLoan;
  final Future<FinanceActionResult> Function()? onPurchaseMarketReport;
  final Future<void> Function()? onCompleteHubTutorial;
  final Future<GameState> Function()? onCompleteMarketTutorial;
  final Future<GameState> Function()? onCompleteNationalNetworkBriefing;
  final Future<GameState> Function()? onCompleteBankDepositTutorial;
  final Future<GameState> Function()? onCompleteRealEstateTutorial;
  final Future<void> Function(String headline, List<String> eventIds)?
  onArchiveNews;
  final Future<DailyMarketNewspaper> Function(GameState)? onBuildDailyNewspaper;
  final Future<GameState> Function(WorkSessionResult) onCompleteWork;
  final Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade;
  final Future<GameState> Function(GameState)? onSaveGovernanceState;
  final Future<FinanceActionResult> Function(String orderId)?
  onCancelPendingOrder;
  final Future<FinanceActionResult> Function(int amount, bool deposit)?
  onTransferBrokerageCash;

  GameState get _latestState => stateReader?.call() ?? state;

  Future<void> _openStockMarket(
    BuildContext context,
    GameState currentState,
  ) async {
    await Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        StockMarketScreen(
          state: currentState,
          onSetMarketMinute: onSetMarketMinute,
          onSaveMarketNotebook: onSaveMarketNotebook,
          onSetRightsIssuePreference: onSetMarketRightsIssuePreference,
          onPurchaseReport: onPurchaseMarketReport,
          onCompleteTutorial: onCompleteMarketTutorial,
          onExecuteTrade: onExecuteTrade,
          onSaveGovernanceState: onSaveGovernanceState,
          onCancelPendingOrder: onCancelPendingOrder,
          onTransferCash: onTransferBrokerageCash,
          orderBookSessionCache: stockOrderBookSessionCache,
        ),
      ),
    );
  }

  Future<GameState> _openShareholderCompanyHub(
    BuildContext context,
    GameState currentState,
  ) async {
    final updated = await Navigator.of(context).push<GameState>(
      _gameSceneRoute<GameState>(
        ShareholderCompanyHubScreen(
          state: currentState,
          onSaveState: onSaveGovernanceState,
        ),
      ),
    );
    return updated ?? _latestState;
  }

  Future<void> _openRealEstateMarket(
    BuildContext context,
    GameState currentState,
  ) async {
    await Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        AssetSpendingScreen(
          state: currentState,
          realEstateOnly: true,
          onCompleteTutorial: onCompleteRealEstateTutorial,
          onPurchase:
              onPurchaseSpendingOption ??
              (optionId) async => FinanceActionResult(
                state: currentState,
                success: false,
                message: '이 화면에서는 저장 기능을 사용할 수 없습니다.',
              ),
          onSellRealEstate:
              onSellRealEstate ??
              (assetId) async => FinanceActionResult(
                state: currentState,
                success: false,
                message: '이 화면에서는 저장 기능을 사용할 수 없습니다.',
              ),
          onConfigureLease:
              onConfigureRealEstateLease ??
              (assetId, leaseType) async => FinanceActionResult(
                state: currentState,
                success: false,
                message: '이 화면에서는 저장 기능을 사용할 수 없습니다.',
              ),
          onCancelSaleListing: onCancelRealEstateSaleListing,
          onSaveInvestmentNote: onSaveRealEstateInvestmentNote,
          onRenovateRealEstate: onRenovateRealEstate,
          onSetRealEstateInsurance: onSetRealEstateInsurance,
          onRenewMonthlyLease: onRenewRealEstateMonthlyLease,
          onTerminateMonthlyLeaseEarly: onTerminateRealEstateMonthlyLeaseEarly,
          onPrepayMortgage: onPrepayRealEstateMortgage,
          onRefinanceMortgage: onRefinanceRealEstateMortgage,
          onPlayChanceGame:
              onPlayChanceGame ??
              (stake) async => FinanceActionResult(
                state: currentState,
                success: false,
                message: '이 화면에서는 저장 기능을 사용할 수 없습니다.',
              ),
        ),
      ),
    );
  }

  Future<void> _openBank(BuildContext context, GameState currentState) async {
    FinanceActionResult unavailableResult() => FinanceActionResult(
      state: currentState,
      success: false,
      message: '이 화면에서는 은행 거래를 저장할 수 없습니다.',
    );

    await Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        BankScreen(
          state: currentState,
          onCompleteTutorial: onCompleteBankDepositTutorial,
          onOpenDeposit:
              onOpenTimeDeposit ??
              (amount, termMonths) async => unavailableResult(),
          onRedeemDeposit:
              onRedeemTimeDeposit ?? (depositId) async => unavailableResult(),
          onTakeLoan:
              onTakeUnsecuredLoan ??
              (amount, termMonths) async => unavailableResult(),
          onRepayLoan:
              onRepayUnsecuredLoan ??
              (loanId, amount) async => unavailableResult(),
        ),
      ),
    );
  }

  Future<void> _openCasino(BuildContext context) async {
    final currentState = _latestState;
    CasinoActionResult unavailable() => CasinoActionResult(
      state: currentState,
      success: false,
      message: '이 화면에서는 카지노 결과를 저장할 수 없습니다.',
    );
    await Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        CasinoScreen(
          state: currentState,
          onExchangeChips:
              onExchangeCasinoChips ?? (amount) async => unavailable(),
          onCashOutChips: onCashOutCasinoChips ?? () async => unavailable(),
          onPlayRound: onPlayCasinoRound ?? (bet) async => unavailable(),
          onStartBlackjack:
              onStartCasinoBlackjack ?? (stake) async => unavailable(),
          onBlackjackAction:
              onCasinoBlackjackAction ?? (action) async => unavailable(),
          onCrapsRoll: onCasinoCrapsRoll ?? () async => unavailable(),
        ),
      ),
    );
  }

  Future<void> _openHorseRace(
    BuildContext context, {
    bool closeParentOnPowerOff = true,
  }) async {
    final currentState = _latestState;
    final navigator = Navigator.of(context);
    final session = await Navigator.of(context).push<HorseRaceSessionResult>(
      _gameSceneRoute<HorseRaceSessionResult>(
        HorseRacingMiniGame(
          race: buildAfternoonHorseRace(
            simulationSeed: currentState.simulationSeed,
            day: currentState.day,
          ),
          availableCash: currentState.availableBrokerageCash,
          stateRecoveryRateBps: currentState.story.stateRecoveryRateBps,
          onPowerOff: () {
            navigator.pop();
            if (closeParentOnPowerOff && navigator.canPop()) navigator.pop();
          },
        ),
      ),
    );
    if (session == null || !context.mounted) return;
    final settle = onSettleHorseRace;
    final result = settle == null
        ? HorseRaceActionResult(
            state: currentState,
            success: false,
            message: '이 화면에서는 경마 결과를 저장할 수 없습니다.',
          )
        : await settle(session);
    if (!context.mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('전자 마권 정산 완료'),
        content: Text(result.message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('20:00으로 돌아가기'),
          ),
        ],
      ),
    );
  }

  Future<WeekdayActivityResult> _runWeekdayAfternoonChoice(
    BuildContext context,
    String activityId,
  ) async {
    final activity = weekdayActivityById(activityId);
    final complete = onCompleteWeekdayActivity;
    WeekdayActivityResult failure(String message) => WeekdayActivityResult(
      state: _latestState,
      success: false,
      message: message,
      activity: activity,
    );
    if (activity == null) return failure('선택할 수 없는 오후 일정입니다.');
    if (complete == null) return failure('오후 일정을 저장할 수 없습니다.');
    if (!weekdayActivityUnlocked(_latestState, activityId)) {
      return failure(weekdayActivityLockReason(_latestState, activityId));
    }

    switch (activityId) {
      case 'casino':
        await _openCasino(context);
        break;
      case 'horse_racing':
        await _openHorseRace(context, closeParentOnPowerOff: false);
        break;
      case 'bank':
        await _openBank(context, _latestState);
        break;
      case 'real_estate':
        await _openRealEstateMarket(context, _latestState);
        break;
    }
    if (!context.mounted) return failure('오후 일정 화면을 닫았습니다.');

    final latest = _latestState;
    final existing = weekdayActivityLogsForDay(latest, latest.day).firstOrNull;
    if (existing != null) {
      return WeekdayActivityResult(
        state: latest,
        success: true,
        message: '${existing.title} 오후 일정이 완료됐습니다.',
        activity: activity,
        startMinute: existing.startMinute,
        endMinute: existing.endMinute,
      );
    }
    if (activityId == 'horse_racing') {
      return failure('전자 마권 정산을 마쳐야 경마 오후 일정이 완료됩니다.');
    }
    return complete(activityId);
  }

  bool _weekdayFacilityAvailable(BuildContext context, String activityId) {
    final current = _latestState;
    final available = switch (activityId) {
      'bank' => bankAccessUnlocked(current),
      'real_estate' => realEstateAccessUnlocked(current),
      _ => false,
    };
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activityId == 'bank'
                ? '2월 김서아·윤하린 예금 이야기를 마친 뒤 은행이 열립니다.'
                : '5월 윤채아·서하늘 매물 이야기를 마친 뒤 부동산 시장이 열립니다.',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _openBankForSchedule(BuildContext context) async {
    if (!_weekdayFacilityAvailable(context, 'bank')) return;
    await _openBank(context, _latestState);
  }

  Future<void> _openRealEstateForSchedule(BuildContext context) async {
    if (!_weekdayFacilityAvailable(context, 'real_estate')) return;
    await _openRealEstateMarket(context, _latestState);
  }

  Future<GameState> _openBusinessMarket(
    BuildContext context, {
    required GameState currentState,
    String? initialLinkedRealEstateId,
  }) async {
    var latestState = currentState;
    FinanceActionResult unavailableResult() => FinanceActionResult(
      state: latestState,
      success: false,
      message: '이 화면에서는 사업 거래를 저장할 수 없습니다.',
    );

    await Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        BusinessManagementScreen(
          state: latestState,
          initialLinkedRealEstateId: initialLinkedRealEstateId,
          onAcquire:
              ({
                required listingId,
                required businessName,
                required locationId,
                required premiseMode,
                linkedRealEstateId,
                required policy,
              }) async {
                final handler = onAcquireBusiness;
                final result = handler == null
                    ? unavailableResult()
                    : await handler(
                        listingId: listingId,
                        businessName: businessName,
                        locationId: locationId,
                        premiseMode: premiseMode,
                        linkedRealEstateId: linkedRealEstateId,
                        policy: policy,
                      );
                if (result.success) latestState = result.state;
                return result;
              },
          onUpdatePolicy: (businessId, policy) async {
            final handler = onUpdateBusinessPolicy;
            final result = handler == null
                ? unavailableResult()
                : await handler(businessId, policy);
            if (result.success) latestState = result.state;
            return result;
          },
          onInvest: (businessId, kind) async {
            final handler = onInvestInBusiness;
            final result = handler == null
                ? unavailableResult()
                : await handler(businessId, kind);
            if (result.success) latestState = result.state;
            return result;
          },
          onClose: (businessId) async {
            final handler = onCloseBusiness;
            final result = handler == null
                ? unavailableResult()
                : await handler(businessId);
            if (result.success) latestState = result.state;
            return result;
          },
          onChooseEvent: (eventId, choiceId) async {
            final handler = onChooseBusinessEvent;
            final result = handler == null
                ? unavailableResult()
                : await handler(eventId, choiceId);
            if (result.success) latestState = result.state;
            return result;
          },
        ),
      ),
    );
    return latestState;
  }

  Future<void> _openHomeImprovements(BuildContext context) async {
    var latestState = _latestState;
    await Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        HomeImprovementScreen(
          state: latestState,
          onPurchase: (improvementId) async {
            final handler = onPurchaseHomeImprovement;
            final result = handler == null
                ? FinanceActionResult(
                    state: latestState,
                    success: false,
                    message: '이 화면에서는 살림 구매를 저장할 수 없습니다.',
                  )
                : await handler(improvementId);
            if (result.success) latestState = result.state;
            return result;
          },
        ),
      ),
    );
  }

  void _openHomeComputer(BuildContext context) {
    Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        HomeComputerScreen(
          state: _latestState,
          onOpenStockMarket: (currentState) async {
            await _openStockMarket(context, currentState);
            return _latestState;
          },
          onOpenCompanyManagement: (currentState) =>
              _openShareholderCompanyHub(context, currentState),
          onOpenRealEstate: (currentState) async {
            await _openRealEstateForSchedule(context);
            return _latestState;
          },
          onOpenBusiness: (currentState) =>
              _openBusinessMarket(context, currentState: currentState),
          onCompleteNationalNetworkBriefing: onCompleteNationalNetworkBriefing,
          onOpenCasino: (currentState) async {
            await _openCasino(context);
            return _latestState;
          },
          onOpenHorseRace: (currentState) async {
            await _openHorseRace(context);
            return _latestState;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF17130F),
    body: SafeArea(
      child: ApartmentHubScreen(
        state: state,
        onOpenPendingChoice: () => _openPendingChoice(context),
        onOpenMarket: () => _openHomeComputer(context),
        onOpenRealEstate: () => _openRealEstateForSchedule(context),
        onOpenBank: () => _openBankForSchedule(context),
        onOpenLedger: () => _openLedger(context),
        onOpenHomeImprovements: () => _openHomeImprovements(context),
        onOpenOrganization: () => Navigator.of(context).push(
          _gameSceneRoute<void>(
            OrganizationScreen(
              state: state,
              onRequestAcademyHelp: onRequestAcademyHelp,
              onHireEmployee: onHireEmployee,
              onLaunchFund: onLaunchFund,
            ),
          ),
        ),
        onOpenRelationships: () => Navigator.of(context).push(
          _gameSceneRoute<void>(RelationshipStatusScreen(state: _latestState)),
        ),
        onOpenCalendar: () => Navigator.of(
          context,
        ).push(_gameSceneRoute<void>(LifeCalendarScreen(state: _latestState))),
        onOpenMessenger: () {
          final markRead = onMarkPhoneThreadRead;
          final send = onSendPhoneMessage;
          if (markRead == null || send == null) return;
          Navigator.of(context).push(
            _gameSceneRoute<void>(
              PhoneMessengerScreen(
                state: _latestState,
                onMarkRead: markRead,
                onSend: send,
                onSendGift: onSendPhoneGift,
                aiService: phoneAiService,
              ),
            ),
          );
        },
        onOpenWork: () => Navigator.of(context).push(
          _gameSceneRoute<void>(
            SeedMoneyHubScreen(state: state, onComplete: onCompleteWork),
          ),
        ),
        activeSaveSlot: activeSaveSlot,
        lastSavedAt: lastSavedAt,
        onOpenGameMenu: () => _showGameMenu(context),
        onAdvanceHour: () => _handleAdvanceHour(context),
        onAdvanceDay: () => _handleAdvanceDay(context),
        onAdvanceBatch: () => _showAdvanceMenu(context),
        onOpenEnding: () => Navigator.of(
          context,
        ).push(_gameSceneRoute<void>(CampaignEndingScreen(state: state))),
        onTutorialComplete: onCompleteHubTutorial,
      ),
    ),
  );
  Future<void> _showGameMenu(BuildContext context) async {
    final action = await showModalBottomSheet<_GameMenuAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF7F3EA),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B263A),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.save_rounded,
                      color: Color(0xFFFFD76A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$activeSaveSlot번 저장 슬롯',
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          lastSavedAt == null
                              ? '아직 저장 시각 정보가 없습니다'
                              : '최근 저장 ${_savedAtLabel(lastSavedAt)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2E8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.autorenew_rounded,
                      color: Color(0xFF3C7651),
                      size: 19,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '게임 날짜가 하루 넘어갈 때마다 자동 저장됩니다.',
                        style: TextStyle(
                          color: Color(0xFF315F42),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: const Key('manual-save-button'),
                onPressed: () =>
                    Navigator.pop(sheetContext, _GameMenuAction.save),
                icon: const Icon(Icons.save_rounded),
                label: const Text('지금 수동저장'),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                key: const Key('return-title-button'),
                onPressed: () =>
                    Navigator.pop(sheetContext, _GameMenuAction.title),
                icon: const Icon(Icons.home_outlined),
                label: const Text('타이틀로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == _GameMenuAction.save) {
      try {
        await onManualSave();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$activeSaveSlot번 슬롯에 수동저장했습니다.')),
        );
      } catch (_) {
        if (context.mounted) _showSaveFailure(context);
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('타이틀로 돌아갈까요?'),
        content: const Text('현재 진행은 이미 저장되어 있습니다. 필요하면 먼저 수동저장할 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('계속 플레이'),
          ),
          FilledButton(
            key: const Key('confirm-return-title-button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('타이틀로'),
          ),
        ],
      ),
    );
    if (confirmed == true) onReturnToTitle();
  }

  Future<void> _handleAdvanceHour(BuildContext context) async {
    final target = math.min(state.marketMinute + 60, marketDayEndMinute);
    final alreadyRevealed = engine
        .revealedMarketEvents(state)
        .map((event) => event.id)
        .toSet();
    try {
      final saved = await onSetMarketMinute(target);
      if (saved.marketMinute != target) return;
      final breaking = engine
          .revealedMarketEvents(saved)
          .where((event) => !alreadyRevealed.contains(event.id))
          .toList(growable: false);
      for (final event in breaking) {
        if (!context.mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              NewsBulletinSheet(event: event, date: saved.currentDate),
        );
      }
    } catch (_) {
      if (context.mounted) _showSaveFailure(context);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${marketTimeLabel(target)} · 아파트 시간이 1시간 흘렀어요.')),
    );
  }

  Future<void> _showAdvanceMenu(BuildContext context) async {
    final advanceDays = onAdvanceDays;
    if (advanceDays == null) return;
    final selection = await showModalBottomSheet<_AdvanceMenuChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '빠르게 진행',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text('모든 날짜를 하루씩 계산하므로 기업행동·월 비용·결정 이벤트를 건너뛰지 않습니다.'),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.next_plan_rounded),
                  title: const Text('다음 거래일까지'),
                  onTap: () {
                    var days = 1;
                    while (days < 14 &&
                        !isMarketTradingDay(
                          state.currentDate.add(Duration(days: days)),
                        )) {
                      days++;
                    }
                    Navigator.pop(sheetContext, _AdvanceMenuChoice(days: days));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.view_week_rounded),
                  title: const Text('1주 진행'),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    const _AdvanceMenuChoice(days: 7),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text('1개월 진행'),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    const _AdvanceMenuChoice(days: 30),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.event_available_rounded),
                  title: const Text('다음 중요 뉴스·선택까지 (최대 90일)'),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    const _AdvanceMenuChoice(days: 90),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selection == null || !context.mounted) return;
    try {
      final next = await advanceDays(selection.days);
      if (!context.mounted) return;
      final advanced = next.day - state.day;
      final stopReason =
          next.story.storyFlags['fastForwardStopReason'] as String?;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            stopReason != null
                ? '$advanced일 진행 · $stopReason'
                : next.pendingDecisions.isNotEmpty
                ? '$advanced일 진행 후 중요한 선택 앞에서 멈췄습니다.'
                : '$advanced일 진행했습니다.',
          ),
        ),
      );
      if (selection.days >= 30 && context.mounted) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) => FastForwardSummarySheet(
            state: next,
            advancedDays: advanced,
            stopReason: stopReason,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) _showSaveFailure(context);
    }
  }

  Future<void> _handleAdvanceDay(BuildContext context) async {
    try {
      await _advanceDayWithNewspaper(context);
    } catch (_) {
      if (context.mounted) _showSaveFailure(context);
    }
  }

  Future<void> _advanceDayWithNewspaper(BuildContext context) async {
    final navigator = Navigator.of(context);
    var closingState = _latestState;
    if (closingState.marketMinute < krxCloseMinute) {
      closingState = await onSetMarketMinute(krxCloseMinute);
    }
    if (!context.mounted) return;

    final settleCohort = onSettleCohortInvestmentDay;
    final lendToCohort = onLendToCohortInvestor;
    final borrowFromCohort = onBorrowFromCohortInvestor;
    final acknowledgeCohort = onAcknowledgeCohortInvestmentReport;
    if (isMarketTradingDay(closingState.currentDate) && settleCohort != null) {
      if (!closingState.cohortInvestments.settledForDay(closingState.day)) {
        final settlement = await settleCohort();
        if (!settlement.success) {
          throw StateError(settlement.message);
        }
        closingState = settlement.state;
      }
    }

    final completeWeeklyReview = onCompleteWeeklyPortfolioReview;
    if (completeWeeklyReview != null &&
        weeklyPortfolioReviewDue(closingState)) {
      final universe = await FictionalMarketUniverse.load(
        seed: closingState.simulationSeed,
        throughDate: closingState.currentDate,
      );
      if (!context.mounted) return;
      final completed = await navigator.push<bool>(
        _gameSceneRoute<bool>(
          WeeklyPortfolioReviewScreen(
            state: closingState,
            candidates: weeklyPortfolioReviewCandidates(
              closingState,
              universe.asOf(closingState.currentDate),
            ),
            onComplete: completeWeeklyReview,
          ),
        ),
      );
      if (completed != true || !context.mounted) return;
      closingState = _latestState;
    }

    final completeAfternoonActivity = onCompleteWeekdayActivity;
    if (completeAfternoonActivity != null &&
        closingState.currentDate.weekday < DateTime.saturday &&
        !weekdayEveningUsed(closingState) &&
        closingState.personalFinance.casino.roundsForDay(closingState.day) >
            0) {
      final completedCasino = await completeAfternoonActivity('casino');
      if (!completedCasino.success || !context.mounted) return;
      closingState = completedCasino.state;
    }
    if (completeAfternoonActivity != null &&
        weekdayAfternoonScheduleRequired(closingState)) {
      final completed = await navigator.push<bool>(
        _gameSceneRoute<bool>(
          WeekdayAfternoonScheduleScreen(
            state: closingState,
            onSelect: (activityId) =>
                _runWeekdayAfternoonChoice(context, activityId),
          ),
        ),
      );
      if (completed != true || !context.mounted) return;
      closingState = _latestState;
    }

    final completeWeekendActivity = onCompleteWeekendActivity;
    if (isWeekendOutingDay(closingState.currentDate) &&
        completeWeekendActivity != null &&
        !weekendScheduleCompleteForState(closingState)) {
      final completed = await navigator.push<bool>(
        _gameSceneRoute<bool>(
          WeekendScheduleScreen(
            state: closingState,
            onComplete: completeWeekendActivity,
          ),
        ),
      );
      if (completed != true || !context.mounted) return;
      closingState = _latestState;
    }

    if (closingState.marketMinute < marketDayEndMinute) {
      closingState = await onSetMarketMinute(marketDayEndMinute);
    }
    if (!context.mounted) return;

    // Roll call is the 20:00 group event. Personal messages and relationship
    // time deliberately follow it, leaving the familiar 20:00-22:00 wind-down.
    final settleRollCall = onSettleCohortDailyRollCall;
    if (settleRollCall != null) {
      if (closingState.cohortInvestments.rollCallReportForDay(
            closingState.day,
          ) ==
          null) {
        final settlement = await settleRollCall();
        if (!settlement.success || !context.mounted) return;
        closingState = settlement.state;
      }
      final report = closingState.cohortInvestments.rollCallReportForDay(
        closingState.day,
      );
      if (report != null) {
        final completed = await navigator.push<bool>(
          _gameSceneRoute<bool>(
            CohortDailyRollCallScreen(
              state: closingState,
              report: report,
              onOpenCohortFinance:
                  lendToCohort == null ||
                      borrowFromCohort == null ||
                      acknowledgeCohort == null ||
                      closingState.cohortInvestments.reportForDay(
                            closingState.day,
                          ) ==
                          null
                  ? null
                  : () async {
                      await navigator.push<bool>(
                        _gameSceneRoute<bool>(
                          CohortDailyResultScreen(
                            state: closingState,
                            onLend: lendToCohort,
                            onBorrow: borrowFromCohort,
                            onAcknowledge: acknowledgeCohort,
                            loanOnly: true,
                          ),
                        ),
                      );
                    },
            ),
          ),
        );
        if (completed != true || !context.mounted) return;
        closingState = _latestState;
      }
    }

    // Keep the internal stock report open during roll call so the optional
    // loan/recovery book can still transact. It is acknowledged only after
    // the group announcement closes, whether or not that book was opened.
    if (acknowledgeCohort != null &&
        closingState.cohortInvestments.reportForDay(closingState.day) != null &&
        !closingState.cohortInvestments.acknowledgedForDay(closingState.day)) {
      final acknowledged = await acknowledgeCohort();
      if (!acknowledged.success || !context.mounted) return;
      closingState = _latestState;
    }

    // Streak interviews and withdrawal conversations are consequences of the
    // announced result, so they now follow the 20:00 group roll call instead
    // of interrupting the start of the afternoon schedule.
    final acknowledgeStanding = onAcknowledgeCohortStandingEvent;
    if (acknowledgeStanding != null) {
      final standing = pendingCohortStandingEvent(closingState);
      if (standing != null) {
        final seen = await navigator.push<bool>(
          _gameSceneRoute<bool>(
            CohortStandingEventScreen(
              event: standing,
              onAcknowledge: () => acknowledgeStanding(standing),
            ),
          ),
        );
        if (seen != true || !context.mounted) return;
        closingState = _latestState;
      }
    }

    final respondWithdrawal = onRespondToCohortWithdrawal;
    if (respondWithdrawal != null &&
        activeCohortWithdrawalCrisis(closingState) != null) {
      final answered = await navigator.push<bool>(
        _gameSceneRoute<bool>(
          CohortWithdrawalCrisisScreen(
            state: closingState,
            onRespond: respondWithdrawal,
          ),
        ),
      );
      if (answered != true || !context.mounted) return;
      closingState = _latestState;
    }

    final markPhoneRead = onMarkPhoneThreadRead;
    final sendPhone = onSendPhoneMessage;
    if (!closingState.relationships.completedEveningForDay(closingState.day)) {
      final offersRelationshipChoice =
          closingState.currentDate.weekday == DateTime.wednesday ||
          isWeekendOutingDay(closingState.currentDate);
      if (offersRelationshipChoice) {
        final completed = await navigator.push<bool>(
          _gameSceneRoute<bool>(
            RelationshipEveningScreen(
              state: closingState,
              onOpenMessenger: markPhoneRead == null || sendPhone == null
                  ? null
                  : () async {
                      await navigator.push<void>(
                        _gameSceneRoute<void>(
                          PhoneMessengerScreen(
                            state: _latestState,
                            onMarkRead: markPhoneRead,
                            onSend: sendPhone,
                            onSendGift: onSendPhoneGift,
                            aiService: phoneAiService,
                          ),
                        ),
                      );
                      return _latestState;
                    },
              onComplete:
                  onCompleteRelationshipEvening ??
                  (girlId, activity, choiceId) async =>
                      RelationshipActionResult(
                        state: closingState,
                        success: false,
                        message: '이 화면에서는 호감도를 저장할 수 없습니다.',
                      ),
              onRest:
                  onRestDuringRelationshipEvening ??
                  () async => RelationshipActionResult(
                    state: closingState,
                    success: false,
                    message: '이 화면에서는 호감도를 저장할 수 없습니다.',
                  ),
            ),
          ),
        );
        if (completed != true || !context.mounted) return;
      } else {
        if (markPhoneRead != null && sendPhone != null) {
          final completed = await navigator.push<bool>(
            _gameSceneRoute<bool>(
              PostRollCallPhoneTimeScreen(
                state: closingState,
                onOpenMessenger: () async {
                  await navigator.push<void>(
                    _gameSceneRoute<void>(
                      PhoneMessengerScreen(
                        state: _latestState,
                        onMarkRead: markPhoneRead,
                        onSend: sendPhone,
                        onSendGift: onSendPhoneGift,
                        aiService: phoneAiService,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
          if (completed != true || !context.mounted) return;
          closingState = _latestState;
        }
        final rest = onRestDuringRelationshipEvening;
        if (rest != null) {
          final rested = await rest();
          if (!rested.success || !context.mounted) return;
        }
      }
      closingState = _latestState;
    }

    final morningDate = closingState.currentDate.add(const Duration(days: 1));
    final loadingRoute = _gameSceneRoute<void>(
      NewsGeneratingScene(date: morningDate),
    );
    navigator.push<void>(loadingRoute);
    final stopwatch = Stopwatch()..start();
    const newsCombinator = NewsCombinator();
    late DailyMarketNewspaper newspaper;
    late GameState advancedState;
    final closingDay = closingState.day;
    try {
      final baseNewspaper = onBuildDailyNewspaper == null
          ? await buildDailyMarketNewspaper(closingState)
          : await onBuildDailyNewspaper!(closingState);
      final article = newsCombinator.generate(
        newsCombinatorInputForState(
          closingState,
          baseNewspaper.brief,
          newspaper: baseNewspaper,
        ),
      );
      newspaper = baseNewspaper.withCombinatorialArticle(article);
      await onArchiveNews?.call(
        newspaper.headline,
        marketNewsEventsForState(
          closingState,
        ).map((event) => event.id).toList(growable: false),
      );

      final remaining = 350 - stopwatch.elapsedMilliseconds;
      if (remaining > 0) {
        await Future<void>.delayed(Duration(milliseconds: remaining));
      }
      if (!context.mounted) return;

      advancedState = await onAdvanceDay();
      if (advancedState.day <= closingDay) {
        throw StateError('다음 날 08:00 상태를 만들지 못했습니다.');
      }
      if (advancedState.marketMinute != marketDayStartMinute) {
        advancedState = await onSetMarketMinute(marketDayStartMinute);
      }
      if (advancedState.marketMinute != marketDayStartMinute) {
        throw StateError('다음 날 시작 시각을 08:00으로 저장하지 못했습니다.');
      }
    } finally {
      if (loadingRoute.isActive) navigator.removeRoute(loadingRoute);
    }
    if (!context.mounted) return;
    DecisionCardData? monthlyDecision;
    for (final decision in advancedState.pendingDecisions) {
      if (isMonthlyUnlockDecisionId(decision.id)) {
        monthlyDecision = decision;
        break;
      }
    }
    if (monthlyDecision != null) {
      final decision = monthlyDecision;
      await navigator.push<void>(
        _gameSceneRoute<void>(
          AcademyDecisionScene(
            state: advancedState,
            decision: decision,
            onSelect: (decisionContext, optionId) async {
              await onResolveDecision(decision.id, optionId);
              if (decisionContext.mounted) {
                Navigator.of(decisionContext).pop();
              }
            },
          ),
        ),
      );
      if (!context.mounted) return;
    }
    await navigator.push<bool>(
      _gameSceneRoute<bool>(
        DailyWrapUpScreen(
          closingState: closingState,
          morningState: advancedState,
          newspaper: newspaper,
        ),
      ),
    );
  }

  void _openPendingChoice(BuildContext context) {
    final current = _latestState;
    if (current.pendingDecisions.isEmpty) return;
    final decision = current.pendingDecisions.first;
    Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        AcademyDecisionScene(
          state: current,
          decision: decision,
          onSelect: (decisionContext, optionId) async {
            await onResolveDecision(decision.id, optionId);
            if (decisionContext.mounted) {
              Navigator.of(decisionContext).pop();
            }
          },
        ),
      ),
    );
  }

  void _openLedger(BuildContext context) {
    Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        PortfolioLedgerScreen(
          state: state,
          onPurchaseSpendingOption:
              onPurchaseSpendingOption ??
              (optionId) async => FinanceActionResult(
                state: state,
                success: false,
                message: '이 화면에서는 저장 기능을 사용할 수 없습니다.',
              ),
          onSellRealEstate:
              onSellRealEstate ??
              (assetId) async => FinanceActionResult(
                state: state,
                success: false,
                message: '이 화면에서는 저장 기능을 사용할 수 없습니다.',
              ),
          onConfigureRealEstateLease: onConfigureRealEstateLease,
          onCancelRealEstateSaleListing: onCancelRealEstateSaleListing,
          onSaveRealEstateInvestmentNote: onSaveRealEstateInvestmentNote,
          onRenovateRealEstate: onRenovateRealEstate,
          onSetRealEstateInsurance: onSetRealEstateInsurance,
          onRenewRealEstateMonthlyLease: onRenewRealEstateMonthlyLease,
          onTerminateRealEstateMonthlyLeaseEarly:
              onTerminateRealEstateMonthlyLeaseEarly,
          onPrepayRealEstateMortgage: onPrepayRealEstateMortgage,
          onRefinanceRealEstateMortgage: onRefinanceRealEstateMortgage,
          onPlayChanceGame:
              onPlayChanceGame ??
              (stake) async => FinanceActionResult(
                state: state,
                success: false,
                message: '이 화면에서는 저장 기능을 사용할 수 없습니다.',
              ),
        ),
      ),
    );
  }
}

SnackBar _saveFailureSnackBar() => const SnackBar(
  content: Text(
    '저장하지 못했어요. 이전 진행 상태를 그대로 유지했습니다.',
    key: Key('save-failure-message'),
  ),
);

void _showSaveFailure(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(_saveFailureSnackBar());
}

class _SceneClockStrip extends StatelessWidget {
  const _SceneClockStrip({
    required this.location,
    required this.caption,
    required this.minute,
    this.costLabel,
    this.onBack,
    this.dark = true,
  });

  final String location;
  final String caption;
  final int minute;
  final String? costLabel;
  final VoidCallback? onBack;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    final foreground = dark ? Colors.white : _ink;
    final secondary = dark ? const Color(0xFFCBD2E0) : const Color(0xFF6B7488);
    return Container(
      key: Key('scene-location-${location.hashCode}'),
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: dark ? const Color(0xE6263148) : const Color(0xF7FFF0D0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? const Color(0x556DD2FF) : const Color(0x6692693F),
          width: dark ? 1 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x33000000) : const Color(0x33432C17),
            blurRadius: dark ? 14 : 5,
            offset: Offset(0, dark ? 6 : 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            SizedBox(
              width: 44,
              height: 44,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(22),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: foreground,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
          ],
          Icon(
            Icons.location_on_rounded,
            color: dark ? _yellow : _coral,
            size: 19,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (costLabel != null && !compact) ...[
            Container(
              margin: const EdgeInsets.only(right: 7),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: dark ? const Color(0x334DB8E8) : const Color(0xFFF4D582),
                borderRadius: BorderRadius.circular(9),
                border: dark
                    ? null
                    : Border.all(color: const Color(0xFFB98345), width: 0.8),
              ),
              child: Text(
                costLabel!,
                style: TextStyle(
                  color: foreground,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          Text(
            marketTimeLabel(minute),
            key: const Key('scene-clock-time'),
            style: TextStyle(
              color: foreground,
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class AcademyDecisionScene extends StatefulWidget {
  const AcademyDecisionScene({
    super.key,
    required this.state,
    required this.decision,
    required this.onSelect,
  });
  final GameState state;
  final DecisionCardData decision;
  final Future<void> Function(BuildContext context, String optionId) onSelect;

  @override
  State<AcademyDecisionScene> createState() => _AcademyDecisionSceneState();
}

class _AcademyDecisionSceneState extends State<AcademyDecisionScene> {
  bool _isSubmitting = false;

  Future<void> _handleSelect(String optionId) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onSelect(context, optionId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택 저장에 실패했어요. 다시 선택해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyChapter = monthlyUnlockChapterForDecisionId(
      widget.decision.id,
    );
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: const Color(0xFF22253A),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/cinematic_soft_painted/decimal/bg_decimal_trading_floor_dawn_2000_v1.png',
                fit: BoxFit.cover,
              ),
            ),
            const Positioned.fill(child: ColoredBox(color: Color(0x8A171926))),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      _SceneClockStrip(
                        location:
                            monthlyChapter?.location ?? '프로젝트 데시멀 · 데시멀 전략회의',
                        caption: _isSubmitting
                            ? '선택을 투자노트에 저장하고 있다.'
                            : monthlyChapter == null
                            ? '데시멀 동기와 담당 운영관이 함께 검토합니다.'
                            : '${monthlyChapter.month}월 첫날 · 관계의 온도를 숨기지 않고 함께 시작합니다.',
                        minute: widget.state.marketMinute,
                        costLabel: _isSubmitting ? '저장 중' : '함께 고르기 · 30분',
                        onBack: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: AbsorbPointer(
                                absorbing: _isSubmitting,
                                child: DecisionSheet(
                                  state: widget.state,
                                  decision: widget.decision,
                                  onSelect: _handleSelect,
                                ),
                              ),
                            ),
                            if (_isSubmitting)
                              const Positioned(
                                left: 20,
                                right: 20,
                                bottom: 20,
                                child: _DecisionSavingIndicator(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionSavingIndicator extends StatelessWidget {
  const _DecisionSavingIndicator();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('decision-saving-indicator'),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0xF2FFF8E7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _ink, width: 2),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        SizedBox(width: 10),
        Text('투자노트에 저장 중…', style: TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class NewsGeneratingScene extends StatelessWidget {
  const NewsGeneratingScene({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      backgroundColor: const Color(0xFF24212B),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/cinematic_soft_painted/decimal/bg_decimal_trading_floor_dawn_2000_v1.png',
              fit: BoxFit.cover,
            ),
          ),
          const Positioned.fill(child: ColoredBox(color: Color(0xA3181620))),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    const _SceneClockStrip(
                      location: '프로젝트 데시멀 · 투자실 · 오전 08:00',
                      caption: '전날 공개된 시장 기록으로 조간신문을 조합하고 있다.',
                      minute: marketDayStartMinute,
                      costLabel: '로컬 조합',
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          key: const Key('news-generating-scene'),
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F0E4),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFF24211C),
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.newspaper_rounded,
                                color: Color(0xFF24211C),
                                size: 52,
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                '조간신문과 오늘의 시장을 준비 중입니다…',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF171512),
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${date.year}년 ${date.month}월 ${date.day}일 아침을 여는 중입니다.\n신문에는 전날 시장에서 확인된 사실만 담습니다.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF615B52),
                                  fontSize: 12,
                                  height: 1.55,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 22),
                              const SizedBox(
                                width: 34,
                                height: 34,
                                child: CircularProgressIndicator(
                                  strokeWidth: 4,
                                  color: Color(0xFFD45D52),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                '외부 연결 없이 저장된 시장 기록만으로 신문을 완성합니다.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF777168),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class WeekdayAfternoonScheduleScreen extends StatefulWidget {
  const WeekdayAfternoonScheduleScreen({
    super.key,
    required this.state,
    required this.onSelect,
  });

  final GameState state;
  final Future<WeekdayActivityResult> Function(String activityId) onSelect;

  @override
  State<WeekdayAfternoonScheduleScreen> createState() =>
      _WeekdayAfternoonScheduleScreenState();
}

class _WeekdayAfternoonScheduleScreenState
    extends State<WeekdayAfternoonScheduleScreen> {
  String? _busyActivityId;

  Future<void> _select(WeekdayActivityDefinition activity) async {
    if (_busyActivityId != null ||
        !weekdayActivityUnlocked(widget.state, activity.id)) {
      return;
    }
    setState(() => _busyActivityId = activity.id);
    final result = await widget.onSelect(activity.id);
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _busyActivityId = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  IconData _iconFor(String activityId) => switch (activityId) {
    'casino' => Icons.casino_rounded,
    'horse_racing' => Icons.emoji_events_rounded,
    'bank' => Icons.savings_rounded,
    'real_estate' => Icons.apartment_rounded,
    _ => Icons.schedule_rounded,
  };

  Color _colorFor(String activityId) => switch (activityId) {
    'casino' => const Color(0xFF9D4865),
    'horse_racing' => const Color(0xFF2E7D68),
    'bank' => const Color(0xFF386FB0),
    'real_estate' => const Color(0xFFB06B32),
    _ => const Color(0xFF657087),
  };

  @override
  Widget build(BuildContext context) {
    final availableCount = unlockedWeekdayActivities(widget.state).length;
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('weekday-afternoon-schedule-screen'),
        backgroundColor: const Color(0xFFF4ECDD),
        body: SafeArea(
          child: ListView(
            key: const Key('weekday-afternoon-schedule-scroll'),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(17, 16, 17, 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF172744),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFE4C36E),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 13,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '15:00 · 장 마감 후',
                      style: TextStyle(
                        color: Color(0xFFE4C36E),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '오후 일정을 선택하세요',
                      key: Key('weekday-afternoon-choice-message'),
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: _hubDisplayFont,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      '해금된 일정 중 하나를 이용할 수 있습니다. 쉬고 싶은 날에는 아무 시설도 이용하지 않고 바로 점호로 넘어가세요.',
                      style: TextStyle(
                        color: Color(0xFFD7DFEC),
                        fontSize: 10,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      key: const Key('weekday-afternoon-available-count'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF24395E),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '현재 $availableCount개 선택 가능 · 최대 4개',
                        style: const TextStyle(
                          color: Color(0xFFF2D782),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              for (final activity in weekdayActivities) ...[
                Builder(
                  builder: (context) {
                    final unlocked = weekdayActivityUnlocked(
                      widget.state,
                      activity.id,
                    );
                    final busy = _busyActivityId == activity.id;
                    final accent = _colorFor(activity.id);
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: unlocked ? 1 : 0.58,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: Key('weekday-afternoon-choice-${activity.id}'),
                          onTap: unlocked && _busyActivityId == null
                              ? () => _select(activity)
                              : null,
                          borderRadius: BorderRadius.circular(18),
                          child: Ink(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: unlocked
                                    ? accent
                                    : const Color(0xFFB1B5BC),
                                width: unlocked ? 1.7 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    unlocked
                                        ? _iconFor(activity.id)
                                        : Icons.lock_rounded,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activity.title,
                                        style: const TextStyle(
                                          color: Color(0xFF263451),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        unlocked
                                            ? activity.description
                                            : weekdayActivityLockReason(
                                                widget.state,
                                                activity.id,
                                              ),
                                        style: TextStyle(
                                          color: unlocked
                                              ? const Color(0xFF667087)
                                              : const Color(0xFF8B8F97),
                                          fontSize: 9,
                                          height: 1.35,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (busy)
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                      color: accent,
                                    ),
                                  )
                                else
                                  Icon(
                                    unlocked
                                        ? Icons.arrow_forward_ios_rounded
                                        : Icons.lock_outline_rounded,
                                    size: 17,
                                    color: unlocked
                                        ? accent
                                        : const Color(0xFF9CA2AB),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 9),
              ],
              const SizedBox(height: 5),
              OutlinedButton.icon(
                key: const Key('weekday-afternoon-skip-button'),
                onPressed: _busyActivityId == null
                    ? () => _select(weekdayAfternoonSkipActivity)
                    : null,
                icon: _busyActivityId == weekdayAfternoonSkipActivityId
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.nights_stay_rounded),
                label: const Text('오늘은 그냥 넘어가기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4E5E76),
                  side: const BorderSide(color: Color(0xFF8E9AAF)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                '오후 활동은 선택 사항입니다. 넘어가도 손해나 벌점은 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF68748A),
                  fontSize: 9,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostRollCallPhoneTimeScreen extends StatelessWidget {
  const PostRollCallPhoneTimeScreen({
    super.key,
    required this.state,
    required this.onOpenMessenger,
  });

  final GameState state;
  final Future<void> Function() onOpenMessenger;

  @override
  Widget build(BuildContext context) {
    final readOnly = state.marketMinute >= phoneMessengerBedtimeMinute;
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('post-roll-call-phone-time-screen'),
        backgroundColor: const Color(0xFF14223B),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F3E8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE6C46E),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFE467),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: Color(0xFF3A321F),
                          size: 31,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '점호 이후 · 자유 톡 시간',
                        style: TextStyle(
                          color: Color(0xFF263451),
                          fontFamily: _hubDisplayFont,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        readOnly
                            ? '지금은 ${marketTimeLabel(state.marketMinute)}예요. 22:00부터는 모두 취침해 지난 대화만 읽을 수 있습니다.'
                            : '20:00 점호가 끝났어요. 마지막 대화 시작은 21:30까지이고, 한 번 대화하면 30분이 흘러 22:00에 모두 취침합니다.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF667087),
                          fontSize: 10.5,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        '데시멀톡은 관계 선택을 소비하지 않아요. 오늘 이야기할 말이 없다면 바로 마무리해도 됩니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8A6A31),
                          fontSize: 9,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  key: const Key('post-roll-call-open-phone-button'),
                  onPressed: onOpenMessenger,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFFFFE467),
                    foregroundColor: const Color(0xFF3A321F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.phone_android_rounded),
                  label: Text(
                    readOnly ? '데시멀톡 읽기' : '데시멀톡 열기',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('post-roll-call-phone-finish-button'),
                  onPressed: () => Navigator.pop(context, true),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF90A0BE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '오늘은 마무리',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FastForwardSummarySheet extends StatelessWidget {
  const FastForwardSummarySheet({
    super.key,
    required this.state,
    required this.advancedDays,
    this.stopReason,
  });

  final GameState state;
  final int advancedDays;
  final String? stopReason;

  @override
  Widget build(BuildContext context) {
    final review = playerProgressReviewForYear(state, state.currentDate.year);
    final career = careerProgressReview(state);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '저개입 진행 기록',
              key: Key('fast-forward-summary-title'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              '$advancedDays일 진행 · ${state.currentDate.year}년 ${state.currentDate.month}월 ${state.currentDate.day}일 08:00',
              style: const TextStyle(
                color: Color(0xFF667080),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (stopReason != null) ...[
              const SizedBox(height: 10),
              Text(
                stopReason!,
                style: const TextStyle(
                  color: Color(0xFF9A4D37),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              review.headline,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '확정 투자손익 ${review.cumulativeInvestmentProfit >= 0 ? '+' : ''}${_money(review.cumulativeInvestmentProfit)}원\n'
              '실제 거래 ${review.tradeDays}/${review.tradingDays}일 · 회사 조사 ${review.researchCount}회\n'
              '관계 기록 ${review.relationshipMoments}회 · 주말 능동 선택 ${review.activeWeekendChoices}회',
              style: const TextStyle(height: 1.6, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              review.nextFocus,
              style: const TextStyle(
                color: Color(0xFF46556D),
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (advancedDays >= 365 && career.years > 1) ...[
              const SizedBox(height: 12),
              Text(
                '${career.years}년 누적 · 실제 거래 ${career.tradeDays}일 · '
                '성장 레벨 ${career.progressionLevel} · 기업 조사 ${career.researchCount}회\n'
                '관계 기록 ${career.relationshipMoments}회 · '
                '능동적 주말 ${career.activeWeekendChoices}회',
                style: const TextStyle(
                  color: Color(0xFF46556D),
                  height: 1.45,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('기록 확인'),
            ),
          ],
        ),
      ),
    );
  }
}

class DailyWrapUpScreen extends StatelessWidget {
  const DailyWrapUpScreen({
    super.key,
    required this.closingState,
    required this.morningState,
    required this.newspaper,
  });

  final GameState closingState;
  final GameState morningState;
  final DailyMarketNewspaper newspaper;

  @override
  Widget build(BuildContext context) {
    final closingDate = closingState.currentDate;
    final morningDate = morningState.currentDate;
    final events = lifeCalendarEventsOn(
      lifeCalendarEventsForState(closingState),
      closingDate,
    ).where((event) => event.title != '천천히 보내는 주말').toList();
    final report = closingState.cohortInvestments.reportForDay(
      closingState.day,
    );
    final player = report?.resultFor('player');
    final crossedMonth =
        closingDate.month != morningDate.month ||
        closingDate.year != morningDate.year;
    final crossedYear = closingDate.year != morningDate.year;
    final review = crossedMonth
        ? playerProgressReviewForYear(closingState, closingDate.year)
        : null;
    final career = crossedYear ? careerProgressReview(morningState) : null;
    final article =
        newspaper.combinatorialArticle?.content ?? newspaper.brief.body;

    return Scaffold(
      key: const Key('daily-wrap-up-screen'),
      backgroundColor: const Color(0xFF18233A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.nightlight_round,
                    color: Color(0xFFFFD56B),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '오늘 기록 · 내일 아침',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${closingDate.month}월 ${closingDate.day}일 20:00 → '
                          '${morningDate.month}월 ${morningDate.day}일 08:00',
                          style: const TextStyle(
                            color: Color(0xFFB8C6DA),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: const Key('daily-wrap-up-scroll'),
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 18),
                children: [
                  if (player != null)
                    _DailyWrapCard(
                      icon: Icons.show_chart_rounded,
                      eyebrow: '오늘 투자 결과',
                      title: player.traded
                          ? '${player.assetName} · ${player.profitLoss >= 0 ? '+' : ''}${_money(player.profitLoss)}원'
                          : '실제 거래 없음 · 보유 현황만 기록',
                      body:
                          '국가원금 대비 누적손익 ${player.cumulativeProfitLoss >= 0 ? '+' : ''}${_money(player.cumulativeProfitLoss)}원 · '
                          '오늘 순위 ${playerRankInReport(report!)}위',
                      accent: const Color(0xFF73C9EE),
                    ),
                  if (events.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DailyWrapCard(
                      icon: Icons.bookmark_added_rounded,
                      eyebrow: '오늘 남은 생활 기록 ${events.length}건',
                      title: events.first.title,
                      body: events.length == 1
                          ? events.first.body
                          : '${events.first.body}\n그 밖에 ${events.skip(1).map((event) => event.title).join(' · ')}',
                      accent: const Color(0xFFFF9A7C),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _DailyWrapCard(
                    icon: Icons.newspaper_rounded,
                    eyebrow:
                        '${newspaper.date.month}월 ${newspaper.date.day}일 조간',
                    title: newspaper.headline,
                    body: '$article\n${newspaper.summary}',
                    accent: const Color(0xFFFFD56B),
                  ),
                  if (review != null) ...[
                    const SizedBox(height: 10),
                    _DailyWrapCard(
                      key: Key(
                        crossedYear
                            ? 'annual-progress-review'
                            : 'monthly-progress-review',
                      ),
                      icon: crossedYear
                          ? Icons.workspace_premium_rounded
                          : Icons.calendar_month_rounded,
                      eyebrow: crossedYear
                          ? '${review.year}년 연말 회고'
                          : '${closingDate.month}월 월말 점검',
                      title: review.headline,
                      body:
                          '올해 투자손익 ${review.investmentProfitForYear >= 0 ? '+' : ''}${_money(review.investmentProfitForYear)}원 · '
                          '누적 ${review.cumulativeInvestmentProfit >= 0 ? '+' : ''}${_money(review.cumulativeInvestmentProfit)}원 · '
                          '회사 조사 ${review.researchCount}회 · 관계 기록 ${review.relationshipMoments}회 · '
                          '주말 능동 선택 ${review.activeWeekendChoices}회\n'
                          '현재 장부가 순자산 ${_money(review.netWorthAtCost)}원\n'
                          '성장 레벨 ${review.progressionLevel} · 경험 ${review.progressionExperience}\n'
                          '${review.nextFocus}',
                      accent: const Color(0xFFB69CF0),
                    ),
                  ],
                  if (career != null && career.years > 1) ...[
                    const SizedBox(height: 10),
                    _DailyWrapCard(
                      key: const Key('career-progress-review'),
                      icon: Icons.timeline_rounded,
                      eyebrow: '${career.years}년 장기 여정',
                      title: career.yearsWithoutTrades == 0
                          ? '모든 해에 직접 시장 판단을 남겼습니다.'
                          : '거래가 없었던 해 ${career.yearsWithoutTrades}년 · 다음 해 목표를 정해 보세요.',
                      body:
                          '실제 거래 ${career.tradeDays}일 · 기업 조사 ${career.researchCount}회 · '
                          '관계 기록 ${career.relationshipMoments}회 · 능동적 주말 ${career.activeWeekendChoices}회\n'
                          '성장 레벨 ${career.progressionLevel} · 현재 장부가 순자산 ${_money(career.netWorthAtCost)}원',
                      accent: const Color(0xFF6FD5B3),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF10192A),
                border: Border(top: BorderSide(color: Color(0xFF31425F))),
              ),
              child: FilledButton.icon(
                key: const Key('newspaper-next-day-button'),
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD56B),
                  foregroundColor: const Color(0xFF172238),
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.wb_sunny_rounded),
                label: const Text(
                  '다음 날 08:00 시작',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyWrapCard extends StatelessWidget {
  const _DailyWrapCard({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F4E9),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent, width: 2),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF263349), size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  color: Color.lerp(accent, const Color(0xFF1D2941), 0.46),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF202B3C),
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: const TextStyle(
                  color: Color(0xFF566071),
                  fontSize: 10.5,
                  height: 1.52,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class WeeklyPortfolioReviewScreen extends StatefulWidget {
  const WeeklyPortfolioReviewScreen({
    super.key,
    required this.state,
    required this.candidates,
    required this.onComplete,
  });

  final GameState state;
  final List<FictionalMarketAsset> candidates;
  final Future<GameState> Function({
    required WeeklyPortfolioReviewAction action,
    required String assetId,
    required String assetName,
    required int riskLimitBps,
  })
  onComplete;

  @override
  State<WeeklyPortfolioReviewScreen> createState() =>
      _WeeklyPortfolioReviewScreenState();
}

class _WeeklyPortfolioReviewScreenState
    extends State<WeeklyPortfolioReviewScreen> {
  FictionalMarketAsset? _selected;
  int _riskLimitBps = 500;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.candidates.firstOrNull;
    final storedRisk = widget.state.story
        .flagInt('weeklyPortfolioRiskLimitBps', 500)
        .clamp(100, 2000);
    _riskLimitBps = <int>[300, 500, 800].reduce(
      (left, right) => (left - storedRisk).abs() <= (right - storedRisk).abs()
          ? left
          : right,
    );
  }

  Future<void> _complete(WeeklyPortfolioReviewAction action) async {
    if (_saving) return;
    final selected = _selected;
    if (action == WeeklyPortfolioReviewAction.research && selected == null) {
      return;
    }
    setState(() => _saving = true);
    await widget.onComplete(
      action: action,
      assetId: selected?.id ?? '',
      assetName: selected?.name ?? '',
      riskLimitBps: _riskLimitBps,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final reports = widget.state.cohortInvestments.reports
        .where((report) => report.day <= widget.state.day)
        .toList(growable: false);
    final recent = reports.length <= 5
        ? reports
        : reports.sublist(reports.length - 5);
    final playerRows = recent
        .map((report) => report.resultFor('player'))
        .whereType<CohortDailyInvestmentResult>()
        .toList(growable: false);
    final weeklyPnl = playerRows.fold<int>(
      0,
      (sum, row) => sum + row.profitLoss,
    );
    final tradeDays = playerRows.where((row) => row.traded).length;
    return Scaffold(
      key: const Key('weekly-portfolio-review-screen'),
      backgroundColor: const Color(0xFF132135),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.fact_check_rounded,
                    color: Color(0xFFFFD46A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '이번 주 투자 복기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${weeklyPortfolioReviewKey(widget.state.currentDate)} 주간 · 매일이 아닌 주 1회',
                          style: const TextStyle(
                            color: Color(0xFFB9C8DC),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0E5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _WeeklyReviewMetric(
                            label: '최근 5거래일 손익',
                            value:
                                '${weeklyPnl >= 0 ? '+' : ''}${_money(weeklyPnl)}원',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WeeklyReviewMetric(
                            label: '실제 거래일',
                            value: '$tradeDays일',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '관찰할 회사를 하나 고르기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '보유·관심 종목을 먼저 두고, 나머지는 매주 순환합니다. 같은 12개만 반복하지 않습니다.',
                    style: TextStyle(
                      color: Color(0xFFB9C8DC),
                      fontSize: 10,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final asset in widget.candidates)
                        ChoiceChip(
                          key: Key('weekly-review-asset-${asset.id}'),
                          label: Text(asset.name),
                          selected: _selected?.id == asset.id,
                          onSelected: _saving
                              ? null
                              : (_) => setState(() => _selected = asset),
                          selectedColor: const Color(0xFFFFD46A),
                          backgroundColor: Colors.white,
                          labelStyle: const TextStyle(
                            color: Color(0xFF253246),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('weekly-review-research-button'),
                    onPressed: _selected == null || _saving
                        ? null
                        : () => _complete(WeeklyPortfolioReviewAction.research),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD46A),
                      foregroundColor: const Color(0xFF17253A),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.search_rounded),
                    label: const Text(
                      '이번 주 조사 대상으로 기록',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '또는 손실 확인선을 다시 적기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 300, label: Text('-3%')),
                      ButtonSegment(value: 500, label: Text('-5%')),
                      ButtonSegment(value: 800, label: Text('-8%')),
                    ],
                    selected: <int>{_riskLimitBps},
                    onSelectionChanged: _saving
                        ? null
                        : (selection) =>
                              setState(() => _riskLimitBps = selection.first),
                    style: const ButtonStyle(
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 9),
                  OutlinedButton.icon(
                    key: const Key('weekly-review-risk-button'),
                    onPressed: _saving
                        ? null
                        : () => _complete(WeeklyPortfolioReviewAction.riskRule),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF8FAAC8)),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.shield_outlined),
                    label: Text(
                      '-${(_riskLimitBps / 100).toStringAsFixed(0)}%에서 이유 다시 확인',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyReviewMetric extends StatelessWidget {
  const _WeeklyReviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6C7480),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: Color(0xFF202A39),
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class KoreaEconomicNewspaperScene extends StatelessWidget {
  const KoreaEconomicNewspaperScene({super.key, required this.newspaper});
  final DailyMarketNewspaper newspaper;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF24212B),
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/cinematic_soft_painted/decimal/bg_decimal_trading_floor_dawn_2000_v1.png',
            fit: BoxFit.cover,
          ),
        ),
        const Positioned.fill(child: ColoredBox(color: Color(0x83181620))),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  _SceneClockStrip(
                    location: '프로젝트 데시멀 · 투자실 · 조간신문',
                    caption: '데시멀 전략회의가 전날 시장을 읽고 오늘의 선택을 준비한다.',
                    minute: marketDayStartMinute,
                    costLabel: '하루 결산',
                    onBack: () => Navigator.of(context).pop(true),
                  ),
                  Expanded(
                    child: KoreaEconomicNewspaperSheet(newspaper: newspaper),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class DecisionSheet extends StatelessWidget {
  const DecisionSheet({
    super.key,
    required this.state,
    required this.decision,
    required this.onSelect,
  });

  final GameState state;
  final DecisionCardData decision;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final monthlyChapter = monthlyUnlockChapterForDecisionId(decision.id);
    final monthlyTone = monthlyUnlockToneForDecisionId(decision.id);
    final monthlyHeroine = monthlyChapter == null
        ? null
        : cohortGirlProfileById(monthlyChapter.heroineId);
    return DraggableScrollableSheet(
      initialChildSize: 0.96,
      minChildSize: 0.72,
      maxChildSize: 0.96,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: _ink, width: 3)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF9BA5B7),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Sticker(
                  icon: Icons.campaign_rounded,
                  label: decision.category,
                ),
                const Spacer(),
                Text(
                  monthlyChapter == null
                      ? 'DAY ${decision.dueDay}까지 선택'
                      : '${monthlyChapter.year}년 ${monthlyChapter.month}월 챕터',
                  style: const TextStyle(
                    color: _coral,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(decision.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(
              '이야기를 꺼낸 사람 · ${decision.proposer}',
              style: const TextStyle(
                color: Color(0xFF6E7890),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (monthlyChapter != null && monthlyHeroine != null) ...[
              const SizedBox(height: 10),
              _MonthlyUnlockHeroineCard(
                chapter: monthlyChapter,
                heroine: monthlyHeroine,
                tone: monthlyTone,
              ),
            ],
            const SizedBox(height: 12),
            Text(decision.body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Container(
              key: const Key('decision-reward-preview'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFDDF3FF),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _blue, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 18, color: _ink),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      monthlyChapter == null
                          ? '정답은 없어요 · 선택하면 +25 XP'
                          : '어떤 관계 상태여도 기능은 열려요 · 선택은 둘 사이의 반응만 바꿉니다.',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FactChip(
                    label: '좋아지는 점',
                    value: decision.benefit,
                    color: const Color(0xFFDFF7EF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FactChip(
                    label: '조심할 점',
                    value: decision.risk,
                    color: const Color(0xFFFFE3DF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '내 생각과 가까운 쪽은?',
              style: TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...decision.options.map((option) {
              final locked = option.cashCost > state.bankCash;
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: SizedBox(
                  height: 64,
                  child: ElevatedButton(
                    key: Key('decision-option-${option.id}'),
                    onPressed: locked ? null : () => onSelect(option.id),
                    style: ElevatedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: _ink,
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE5E7E8),
                      elevation: 0,
                      side: const BorderSide(color: _ink, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                locked
                                    ? '생활·회사 통장 부족 · ${_money(option.cashCost)}원 필요'
                                    : option.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                key: const Key('decision-advisor-opinions'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 6),
                title: const Text(
                  '같이 나눈 말 더 보기',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                initiallyExpanded: monthlyChapter != null,
                children: decision.advisorOpinions
                    .map(
                      (opinion) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '• $opinion',
                            style: const TextStyle(
                              color: Color(0xFF66718A),
                              fontSize: 11,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            Text(
              monthlyChapter == null
                  ? '등장 회사와 지분·거래 조건은 모두 게임 전용 가상 설정입니다. 선택 뒤 장부와 운영 결과를 함께 확인해 보세요.'
                  : '이 장면은 현재 호감도뿐 아니라 최근 톡과 관계 기록을 함께 읽습니다. 갈등 중에는 억지 미소나 자동 화해가 나오지 않습니다.',
              style: const TextStyle(
                color: Color(0xFF8A92A2),
                fontSize: 9,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyUnlockHeroineCard extends StatelessWidget {
  const _MonthlyUnlockHeroineCard({
    required this.chapter,
    required this.heroine,
    required this.tone,
  });

  final MonthlyUnlockChapterDefinition chapter;
  final CohortGirlProfile heroine;
  final MonthlyHeroineTone tone;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('monthly-unlock-heroine-card'),
    height: 132,
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0F4),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8A8BB), width: 1.5),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 106,
          child: ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(14),
            ),
            child: heroine.portraitAsset == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 56,
                    color: Color(0xFFB26C84),
                  )
                : Image.asset(
                    heroine.portraitAsset!,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.person_rounded,
                      size: 56,
                      color: Color(0xFFB26C84),
                    ),
                  ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${chapter.month}월은 ${heroine.name}와 함께',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${heroine.mbti} · ${heroine.role}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF756477),
                    fontSize: 10,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  key: Key('monthly-unlock-tone-${tone.name}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFFD7A7B5)),
                  ),
                  child: Text(
                    '지금의 거리 · ${tone.label}',
                    style: const TextStyle(
                      color: Color(0xFF8A4960),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _OfficeStatusCard extends StatelessWidget {
  const _OfficeStatusCard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final hasCompanyStake = state.company.hasOwnership;
    final authority = state.story.accountAuthorityLevel;
    final orderLimit = switch (authority) {
      0 => '관찰 전용',
      1 => '10만원',
      2 => '25만원',
      3 => '자산 25% · 최소 25만원',
      4 => '자산 25% · 최소 500만원',
      _ => '20억원',
    };
    return _OutlinedCard(
      color: const Color(0xF7FFFEF8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DAY ${state.day} · ${state.companyName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _coral,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: hasCompanyStake
                      ? const Color(0xFFFFE3DF)
                      : const Color(0xFFDFF7EF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  hasCompanyStake
                      ? '${state.company.controlTierLabel} · ${state.company.name}'
                      : 'DECIMAL 10 RESEARCH DESK',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _StatusValue(
                  label: '연구계좌 현금',
                  value: '${_money(state.cash)}원',
                ),
              ),
              Expanded(
                child: _StatusValue(
                  label: '공동체 신뢰',
                  value: '${state.story.flagInt('cohortTrust', 30)}',
                ),
              ),
              _StatusValue(label: '주문 한도', value: orderLimit),
              _StatusValue(label: '평판', value: '${state.story.reputation}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasCompanyStake
                ? '${state.company.name} · DAY ${state.company.acquiredAtDay} 취득 · ${state.company.worldPremise}'
                : '계좌 명의: 대한민국 프로젝트 데시멀 기금 · 생활비와 분리 · 대출·미수·신용 금지',
            style: const TextStyle(
              color: Color(0xFF7B849A),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hasCompanyStake) ...[
            const SizedBox(height: 8),
            Container(
              key: const Key('controlled-company-status'),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8C89B)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatusValue(
                          label: '경제적 지분',
                          value:
                              '${state.company.effectiveEconomicOwnershipPct.toStringAsFixed(1)}%',
                        ),
                      ),
                      Expanded(
                        child: _StatusValue(
                          label: '의결권',
                          value:
                              '${state.company.votingOwnershipPct.toStringAsFixed(1)}%',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _StatusValue(
                          label: '이사회',
                          value:
                              state.company.boardObserver &&
                                  state.company.boardSeats == 0
                              ? '관찰권'
                              : '${state.company.boardSeats}/${state.company.totalBoardSeats}석',
                        ),
                      ),
                      Expanded(
                        child: _StatusValue(
                          label: '투자 장부가치',
                          value:
                              '${_money(state.company.investmentBookValue)}원',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

typedef _NewsToneStyle = ({
  Color fill,
  Color accent,
  IconData icon,
  String tag,
});

_NewsToneStyle _newsToneStyle(NewsTone tone) => switch (tone) {
  NewsTone.breaking => (
    fill: const Color(0xFFFFF0EC),
    accent: _coral,
    icon: Icons.campaign_rounded,
    tag: '속보',
  ),
  NewsTone.shock => (
    fill: const Color(0xFFFFE6E1),
    accent: const Color(0xFFE0574B),
    icon: Icons.warning_amber_rounded,
    tag: '시장 충격',
  ),
  NewsTone.launch => (
    fill: const Color(0xFFE7F4FF),
    accent: const Color(0xFF3E8FD0),
    icon: Icons.rocket_launch_rounded,
    tag: '새 소식',
  ),
  NewsTone.milestone => (
    fill: const Color(0xFFFFF7DA),
    accent: const Color(0xFFE0A100),
    icon: Icons.auto_awesome_rounded,
    tag: '오늘의 소식',
  ),
  NewsTone.weekend => (
    fill: const Color(0xFFECEEF6),
    accent: const Color(0xFF7C86A0),
    icon: Icons.weekend_rounded,
    tag: '주말',
  ),
  NewsTone.holiday => (
    fill: const Color(0xFFEFEAF7),
    accent: const Color(0xFF8A6FC0),
    icon: Icons.celebration_rounded,
    tag: '휴장',
  ),
  NewsTone.calm => (
    fill: const Color(0xFFE7F5EC),
    accent: const Color(0xFF3AA982),
    icon: Icons.wb_sunny_rounded,
    tag: '오늘의 소식',
  ),
};

class _TodayNewsCard extends StatelessWidget {
  const _TodayNewsCard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final brief = buildDailyBrief(state);
    final pending = state.pendingDecisions;
    final project = state.project;
    final tone = _newsToneStyle(brief.tone);

    return _OutlinedCard(
      color: tone.fill,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tone.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tone.icon, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      brief.isBreaking ? tone.tag : '오늘의 소식',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  brief.eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7B849A),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _MarketStatusPill(closed: brief.marketClosed),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            brief.title,
            style: const TextStyle(
              color: _ink,
              fontSize: 15,
              height: 1.25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            brief.body,
            style: const TextStyle(
              color: Color(0xFF5E6883),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xF2FFFEF8),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0x2233405F), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  pending.isEmpty
                      ? Icons.schedule_rounded
                      : Icons.notifications_active_rounded,
                  color: pending.isEmpty ? const Color(0xFF3AA982) : _coral,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pending.isEmpty ? '시간을 보내도 좋아요' : '중요한 선택에서 시간이 멈췄어요',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        pending.isNotEmpty
                            ? pending.first.title
                            : project == null
                            ? '1시간씩 진행하고 오늘 신문에서 하루를 마쳐요.'
                            : 'Project Atlas · ${_projectLabel(project.status)} · 다음 변화 대기 중',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7B849A),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketStatusPill extends StatelessWidget {
  const _MarketStatusPill({required this.closed});

  final bool closed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: closed ? const Color(0xFFE7E9F0) : const Color(0xFFDFF7EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: closed ? const Color(0x3333405F) : const Color(0x333AA982),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: closed ? const Color(0xFF9AA2B5) : const Color(0xFF3AA982),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            closed ? '휴장' : '개장',
            style: TextStyle(
              color: closed ? const Color(0xFF6B7488) : const Color(0xFF2E8768),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class NewsBulletinSheet extends StatelessWidget {
  const NewsBulletinSheet({super.key, required this.event, required this.date});

  final FictionalMarketEvent event;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final tone = _newsToneStyle(event.tone);
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.42,
      maxChildSize: 0.9,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: _ink, width: 3)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF9BA5B7),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tone.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tone.icon, color: Colors.white, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '속보 · ${event.eyebrow}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Color(0xFF7B849A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 어느 종목 얘긴지 먼저 보여준다. companyName은 이벤트에 이미 있는데
            // 제목 문장 안에만 묻혀 있어서 한눈에 안 들어왔다.
            // 전체시장 사건은 종목이 없으므로 업종(=전체시장) 라벨만 쓴다.
            Row(
              children: [
                Flexible(
                  child: Text(
                    event.companyId == fictionalWholeMarketCompanyId
                        ? event.sector
                        : event.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (event.companyId != fictionalWholeMarketCompanyId) ...[
                  const SizedBox(width: 6),
                  Text(
                    event.sector,
                    style: const TextStyle(
                      color: Color(0xFF7B849A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${event.impactPct >= 0 ? '+' : ''}'
                  '${(event.impactPct * 100).toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: event.impactPct >= 0
                        ? const Color(0xFFD03A3A)
                        : const Color(0xFF1A62D6),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.title,
              style: const TextStyle(
                color: _ink,
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              event.body,
              style: const TextStyle(
                color: Color(0xFF515C77),
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7DA),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _ink, width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    color: Color(0xFFE0A100),
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '투자 메모',
                          style: TextStyle(
                            color: _coral,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          event.signal,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            height: 1.45,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                key: const Key('market-breaking-news-confirm'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('확인했어요'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: _ink,
                  backgroundColor: _yellow,
                  elevation: 0,
                  side: const BorderSide(color: _ink, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '실제 사건에서 착안한 게임용 소식입니다. 내부 수치·결과는 가상입니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF9AA2B5),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KoreaEconomicNewspaperSheet extends StatelessWidget {
  const KoreaEconomicNewspaperSheet({super.key, required this.newspaper});
  final DailyMarketNewspaper newspaper;

  @override
  Widget build(BuildContext context) {
    final date = newspaper.date;
    final dateLabel = '${date.year}년 ${date.month}월 ${date.day}일';
    return FractionallySizedBox(
      heightFactor: 0.94,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F0E4),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: Color(0xFF24211C), width: 3)),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Row(
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(color: Color(0xFF24211C), thickness: 1),
            const Text(
              '새천년경제',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF171512),
                fontSize: 31,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
            const Text(
              '2000~2026 시장 시뮬레이션 특별판',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
            const Divider(color: Color(0xFF24211C), thickness: 3),
            const SizedBox(height: 14),
            Text(
              newspaper.headline,
              style: const TextStyle(
                color: Color(0xFF171512),
                fontSize: 25,
                height: 1.18,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.1,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              newspaper.combinatorialArticle?.content ?? newspaper.brief.body,
              style: const TextStyle(
                color: Color(0xFF444039),
                fontSize: 13,
                height: 1.55,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (newspaper.brief.otherHeadlines.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFF1EBDD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '같은 날의 다른 소식',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    ...newspaper.brief.otherHeadlines.map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${event.title}',
                          style: const TextStyle(fontSize: 11, height: 1.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (newspaper.combinatorialArticle != null) ...[
              const SizedBox(height: 12),
              _CombinatorialNewsInfo(article: newspaper.combinatorialArticle!),
            ],
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF24211C), width: 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '오늘의 국내 증시',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    newspaper.summary,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _NewspaperStat(
                        label: '상승',
                        value: newspaper.advancers,
                        color: const Color(0xFFD83B45),
                      ),
                      _NewspaperStat(
                        label: '하락',
                        value: newspaper.decliners,
                        color: const Color(0xFF2D6FD2),
                      ),
                      _NewspaperStat(
                        label: '보합',
                        value: newspaper.unchanged,
                        color: const Color(0xFF6B6861),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            if (newspaper.topGainers.isNotEmpty) ...[
              const Text(
                '오늘 많이 오른 종목',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              ...newspaper.topGainers.map(
                (mover) => _NewspaperMoverRow(mover: mover),
              ),
              const SizedBox(height: 10),
            ],
            if (newspaper.topLosers.isNotEmpty) ...[
              const Text(
                '오늘 많이 내린 종목',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              ...newspaper.topLosers.map(
                (mover) => _NewspaperMoverRow(mover: mover),
              ),
              const SizedBox(height: 10),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFE7E0D0),
              child: Text(
                '시장 해설 · ${newspaper.brief.title}\n${newspaper.brief.body}',
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                key: const Key('newspaper-next-day-button'),
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.wb_sunny_rounded),
                label: const Text('신문 덮고 오늘 08:00 시작'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFDF68),
                  foregroundColor: const Color(0xFF24211C),
                  side: const BorderSide(color: Color(0xFF24211C), width: 2),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '모든 회사·시장·기사는 게임을 위해 생성된 가상 기록입니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF777168),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CombinatorialNewsInfo extends StatelessWidget {
  const _CombinatorialNewsInfo({required this.article});
  final CombinatorialNewsArticle article;

  @override
  Widget build(BuildContext context) {
    final positive = article.marketSentiment == 'POSITIVE';
    final negative = article.marketSentiment == 'NEGATIVE';
    final label = positive
        ? '긍정'
        : negative
        ? '부정'
        : '중립';
    final color = positive
        ? const Color(0xFFD83B45)
        : negative
        ? const Color(0xFF2D6FD2)
        : const Color(0xFF6B6861);
    return Container(
      key: const Key('combinatorial-news-info'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFECE4D4),
        border: Border.all(color: const Color(0xFFBDB29F)),
      ),
      child: Row(
        children: [
          Icon(Icons.newspaper_rounded, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '문장 조합 · 시장 흐름 $label',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '조합 #${article.variantId + 1}',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewspaperStat extends StatelessWidget {
  const _NewspaperStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _NewspaperMoverRow extends StatelessWidget {
  const _NewspaperMoverRow({required this.mover});
  final DailyMarketMover mover;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            mover.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          '${mover.changeRate >= 0 ? '+' : ''}${mover.changeRate.toStringAsFixed(2)}%',
          style: TextStyle(
            color: mover.changeRate >= 0
                ? const Color(0xFFD83B45)
                : const Color(0xFF2D6FD2),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class CampaignEndingScreen extends StatelessWidget {
  const CampaignEndingScreen({super.key, required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final realized = state.ledger.fold<int>(
      0,
      (sum, entry) => sum + entry.realizedPnl,
    );
    final fees = state.ledger.fold<int>(
      0,
      (sum, entry) => sum + entry.tradingFee + entry.transactionTax,
    );
    final resolved = state.decisions
        .where((decision) => decision.status == DecisionStatus.resolved)
        .length;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F1E5),
      appBar: AppBar(title: const Text('2026 최종 결산')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Icon(Icons.emoji_events_rounded, size: 72, color: _coral),
          const Text(
            '새천년 이후 27년을 완주했습니다',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          _EndingMetric(label: '최종 현금', value: '${_money(state.cash)}원'),
          _EndingMetric(
            label: '보유원가',
            value: '${_money(state.portfolioCost)}원',
          ),
          _EndingMarketSummary(state: state),
          _EndingMetric(
            label: '누적 실현손익',
            value: '${realized >= 0 ? '+' : ''}${_money(realized)}원',
          ),
          _EndingMetric(label: '누적 거래비용', value: '${_money(fees)}원'),
          _EndingMetric(
            label: '평판 / 공동체 신뢰',
            value:
                '${state.story.reputation} / ${state.story.flagInt('cohortTrust', 30)}',
          ),
          _EndingMetric(
            label: '직원 / 외부 AUM',
            value:
                '${state.organization.employees.length}명 / ${_money(state.story.externalAum)}원',
          ),
          _EndingMetric(
            label: '부동산 추정가 / 월 순현금',
            value:
                '${_money(state.personalFinance.estimatedPropertyValueAt(state.day))}원 / '
                '${_money(state.personalFinance.monthlyPropertyIncomeAt(state.currentDate) - state.personalFinance.monthlyPropertyCostAt(state.currentDate) - state.personalFinance.monthlyPropertyHoldingTaxAt(state.day, state.currentDate) - state.personalFinance.monthlyMortgagePayment)}원',
          ),
          _EndingMetric(
            label: '선택지출 / 확률 오락 손익',
            value:
                '${_money(state.personalFinance.totalSpent)}원 / ${state.personalFinance.chanceNet >= 0 ? '+' : ''}${_money(state.personalFinance.chanceNet)}원',
          ),
          _EndingMetric(label: '해결한 결정', value: '$resolved건'),
          const SizedBox(height: 16),
          Text(
            state.story.reputation >= 70
                ? '엔딩: 신뢰받는 장기 투자회사'
                : state.story.fundLaunched
                ? '엔딩: 첫 고객과 함께 성장한 운용사'
                : state.story.flagInt('cohortTrust', 30) >= 60
                ? '엔딩: 동기들과 원칙을 지킨 운용자'
                : '엔딩: 시장에서 배움을 이어가는 투자자',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _EndingMarketSummary extends StatelessWidget {
  const _EndingMarketSummary({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FictionalMarketUniverse>(
      future: FictionalMarketUniverse.load(
        seed: state.simulationSeed,
        throughDate: state.currentDate,
      ),
      builder: (context, snapshot) {
        final universe = snapshot.data;
        if (universe == null) {
          return const _EndingMetric(label: '시장 평가 계산', value: '불러오는 중');
        }
        final prices = <String, double>{};
        for (final asset in universe.assets) {
          final quote = asset.quoteAtOrBefore(state.currentDate);
          if (quote != null) prices[asset.id] = quote.close;
        }
        final portfolioValue = state.portfolioValue(prices);
        final unrealized = portfolioValue - state.portfolioCost;
        final totalAssets = state.balanceSheetGrossAssets(prices: prices);
        final totalLiabilities = state.totalKnownLiabilities;
        final netWorth = state.balanceSheetNetWorth(prices: prices);
        final benchmarkReturns = <double>[];
        for (final asset in universe.assets.where(
          (asset) => asset.isDomestic && asset.listedOn == null,
        )) {
          final start = asset.quoteAtOrBefore(state.campaignStartDate);
          final end = asset.quoteAtOrBefore(state.currentDate);
          final wasDelisted =
              asset.delistedOn != null &&
              marketDateKey(state.currentDate).compareTo(asset.delistedOn!) >=
                  0;
          if (start != null && start.close > 0 && wasDelisted) {
            benchmarkReturns.add(-1);
          } else if (start != null && end != null && start.close > 0) {
            benchmarkReturns.add(end.close / start.close - 1);
          }
        }
        final benchmarkRate = benchmarkReturns.isEmpty
            ? 0.0
            : benchmarkReturns.reduce((left, right) => left + right) /
                  benchmarkReturns.length *
                  100;
        return Column(
          children: [
            _EndingMetric(
              label: '보유주식 평가액',
              value: '${_money(portfolioValue)}원',
            ),
            _EndingMetric(
              label: '미실현손익',
              value: '${unrealized >= 0 ? '+' : ''}${_money(unrealized)}원',
            ),
            _EndingMetric(label: '최종 총자산', value: '${_money(totalAssets)}원'),
            _EndingMetric(
              label: '최종 총부채',
              value: '${_money(totalLiabilities)}원',
            ),
            _EndingMetric(label: '최종 순자산', value: '${_money(netWorth)}원'),
            _EndingMetric(
              label: '가상시장 동일가중 기준',
              value:
                  '${benchmarkRate >= 0 ? '+' : ''}${benchmarkRate.toStringAsFixed(1)}%',
            ),
          ],
        );
      },
    );
  }
}

class _EndingMetric extends StatelessWidget {
  const _EndingMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
  );
}
