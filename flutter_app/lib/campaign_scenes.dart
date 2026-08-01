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
    this.onAdvanceDaysQuiet,
    required this.onSetMarketMinute,
    required this.onSaveMarketNotebook,
    this.onSetMarketRightsIssuePreference,
    required this.onResolveDecision,
    this.onClaimMission,
    this.onPurchaseStarShopItem,
    required this.onRequestAcademyHelp,
    this.onCompleteRelationshipEvening,
    this.onRestDuringRelationshipEvening,
    this.onSettleCohortInvestmentDay,
    this.onLendToCohortInvestor,
    this.onAcknowledgeCohortInvestmentReport,
    this.onMarkPhoneThreadRead,
    this.onSendPhoneMessage,
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
    this.onOpenTimeDeposit,
    this.onRedeemTimeDeposit,
    this.onTakeUnsecuredLoan,
    this.onRepayUnsecuredLoan,
    this.onPurchaseMarketReport,
    this.onCompleteHubTutorial,
    this.onCompleteMarketTutorial,
    this.onArchiveNews,
    this.onBuildDailyNewspaper,
    required this.onCompleteWork,
    required this.onExecuteTrade,
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
  final Future<GameState> Function(int days)? onAdvanceDaysQuiet;
  final Future<GameState> Function(int) onSetMarketMinute;
  final Future<GameState> Function(Set<String>, Map<String, String>)
  onSaveMarketNotebook;
  final Future<GameState> Function(bool subscribe)?
  onSetMarketRightsIssuePreference;
  final Future<void> Function(String, String) onResolveDecision;
  final Future<MissionClaimResult> Function()? onClaimMission;
  final Future<StarShopPurchaseResult> Function(String productId)?
  onPurchaseStarShopItem;
  final Future<GameState> Function(String) onRequestAcademyHelp;
  final Future<RelationshipActionResult> Function(
    String girlId,
    RelationshipActivity activity,
    String choiceId,
  )?
  onCompleteRelationshipEvening;
  final Future<RelationshipActionResult> Function()?
  onRestDuringRelationshipEvening;
  final Future<CohortInvestmentActionResult> Function()?
  onSettleCohortInvestmentDay;
  final Future<CohortInvestmentActionResult> Function(
    String borrowerId,
    int amount,
  )?
  onLendToCohortInvestor;
  final Future<CohortInvestmentActionResult> Function()?
  onAcknowledgeCohortInvestmentReport;
  final Future<PhoneMessengerActionResult> Function(String contactId)?
  onMarkPhoneThreadRead;
  final Future<PhoneMessengerActionResult> Function(
    String contactId,
    String text,
  )?
  onSendPhoneMessage;
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
  final BankOpenDepositCallback? onOpenTimeDeposit;
  final BankRedeemDepositCallback? onRedeemTimeDeposit;
  final BankTakeLoanCallback? onTakeUnsecuredLoan;
  final BankRepayLoanCallback? onRepayUnsecuredLoan;
  final Future<FinanceActionResult> Function()? onPurchaseMarketReport;
  final Future<void> Function()? onCompleteHubTutorial;
  final Future<GameState> Function()? onCompleteMarketTutorial;
  final Future<void> Function(String headline, List<String> eventIds)?
  onArchiveNews;
  final Future<DailyMarketNewspaper> Function(GameState)? onBuildDailyNewspaper;
  final Future<GameState> Function(WorkSessionResult) onCompleteWork;
  final Future<TradeExecutionResult> Function(TradeOrder) onExecuteTrade;
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
          onCancelPendingOrder: onCancelPendingOrder,
          onTransferCash: onTransferBrokerageCash,
          orderBookSessionCache: stockOrderBookSessionCache,
        ),
      ),
    );
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

  void _openBank(BuildContext context) {
    FinanceActionResult unavailableResult() => FinanceActionResult(
      state: state,
      success: false,
      message: '이 화면에서는 은행 거래를 저장할 수 없습니다.',
    );

    Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        BankScreen(
          state: state,
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
          onOpenRealEstate: (currentState) async {
            await _openRealEstateMarket(context, currentState);
            return _latestState;
          },
          onOpenBusiness: (currentState) =>
              _openBusinessMarket(context, currentState: currentState),
          onOpenStarShop: (currentState) =>
              _openStarShop(context, currentState),
        ),
      ),
    );
  }

  Future<GameState> _openStarShop(
    BuildContext context,
    GameState currentState,
  ) async {
    var latestState = currentState;
    await Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        StarShopScreen(
          state: latestState,
          onPurchase: (productId) async {
            final handler = onPurchaseStarShopItem;
            final result = handler == null
                ? StarShopPurchaseResult(
                    state: latestState,
                    success: false,
                    message: '이 화면에서는 별빛 상점 구매를 저장할 수 없습니다.',
                  )
                : await handler(productId);
            if (result.success) latestState = result.state;
            return result;
          },
        ),
      ),
    );
    return latestState;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF17130F),
    body: SafeArea(
      child: ApartmentHubScreen(
        state: state,
        onOpenDecisions: () => _openDecision(context),
        onOpenMarket: () => _openHomeComputer(context),
        onOpenBank: () => _openBank(context),
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
        onClaimMission: onClaimMission,
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
    if (onAdvanceDays == null) return;
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
                if (onAdvanceDaysQuiet != null)
                  ListTile(
                    key: const Key('advance-year-quiet-option'),
                    leading: const Icon(Icons.calendar_view_month_rounded),
                    title: const Text('1년 저개입 진행'),
                    subtitle: const Text('중요뉴스는 장부에 보관하고, 안건·캠페인 종료에서만 멈춥니다.'),
                    onTap: () => Navigator.pop(
                      sheetContext,
                      const _AdvanceMenuChoice(
                        days: 365,
                        stopOnImportantNews: false,
                      ),
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.event_available_rounded),
                  title: const Text('다음 결정까지 (최대 90일)'),
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
      final advance = selection.stopOnImportantNews
          ? onAdvanceDays
          : onAdvanceDaysQuiet;
      if (advance == null) return;
      final next = await advance(selection.days);
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
                ? '$advanced일 진행 후 새 안건 앞에서 멈췄습니다.'
                : '$advanced일 진행했습니다.',
          ),
        ),
      );
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
    final acknowledgeCohort = onAcknowledgeCohortInvestmentReport;
    if (settleCohort != null &&
        lendToCohort != null &&
        acknowledgeCohort != null) {
      if (!closingState.cohortInvestments.settledForDay(closingState.day)) {
        final settlement = await settleCohort();
        if (!settlement.success) {
          throw StateError(settlement.message);
        }
        closingState = settlement.state;
      }
      if (!closingState.cohortInvestments.acknowledgedForDay(
        closingState.day,
      )) {
        final completed = await navigator.push<bool>(
          _gameSceneRoute<bool>(
            CohortDailyResultScreen(
              state: closingState,
              onLend: lendToCohort,
              onAcknowledge: acknowledgeCohort,
            ),
          ),
        );
        if (completed != true || !context.mounted) return;
        closingState = _latestState;
      }
    }

    if (closingState.marketMinute < marketDayEndMinute) {
      closingState = await onSetMarketMinute(marketDayEndMinute);
    }
    if (!context.mounted) return;

    if (!closingState.relationships.completedEveningForDay(closingState.day)) {
      final completed = await navigator.push<bool>(
        _gameSceneRoute<bool>(
          RelationshipEveningScreen(
            state: closingState,
            onComplete:
                onCompleteRelationshipEvening ??
                (girlId, activity, choiceId) async => RelationshipActionResult(
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

      var advancedState = await onAdvanceDay();
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
    await navigator.push<bool>(
      _gameSceneRoute<bool>(KoreaEconomicNewspaperScene(newspaper: newspaper)),
    );
  }

  void _openDecision(BuildContext context) {
    Navigator.of(context).push<void>(
      _gameSceneRoute<void>(
        DecisionInboxScreen(
          state: state,
          onResolveDecision: onResolveDecision,
          onClaimMission:
              onClaimMission ??
              () async => MissionClaimResult(
                state: state,
                success: false,
                message: '이 화면에서는 미션 보상을 저장할 수 없습니다.',
              ),
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
        const SnackBar(content: Text('안건 저장에 실패했어요. 다시 선택해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isSubmitting,
    child: Scaffold(
      backgroundColor: const Color(0xFF22253A),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/historical_prologue/bg_orphanage_investment_room_2000_portrait_cartoon_v1.png',
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
                      location: '국립 미래양성원 · 제6기 연구회의',
                      caption: _isSubmitting
                          ? '선택을 투자노트에 저장하고 있다.'
                          : '제6기 동기와 담당 교사가 함께 검토합니다.',
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
              'assets/images/cinematic_soft_painted/dormitory_2000/bg_future_academy_dorm_shared_room_night_2000_v1.png',
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
                      location: '국립 미래양성원 · 투자실 · 오전 08:00',
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
            'assets/images/cinematic_soft_painted/dormitory_2000/bg_future_academy_dorm_shared_room_day_2000_v1.png',
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
                    location: '국립 미래양성원 · 투자실 · 조간신문',
                    caption: '제6기 연구회의가 전날 시장을 읽고 오늘의 선택을 준비한다.',
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
                  'DAY ${decision.dueDay}까지 선택',
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
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18, color: _ink),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '정답은 없어요 · 선택하면 +25 XP · 미션 +1',
                      style: TextStyle(
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
              final locked = option.cashCost > state.cash;
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
                                    ? '현금 부족 · ${_money(option.cashCost)}원 필요'
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
                  '제6기 의견 더 보기',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
            const Text(
              '등장 회사와 지분·거래 조건은 모두 게임 전용 가상 설정입니다. 선택 뒤 장부와 운영 결과를 함께 확인해 보세요.',
              style: TextStyle(
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
                      : 'SEED 01 RESEARCH DESK',
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
                : '계좌 명의: 대한민국 미래양성기금 · 생활비와 분리 · 대출·미수·신용 금지',
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
                        pending.isEmpty ? '시간을 보내도 좋아요' : '중요 안건에서 시간이 멈췄어요',
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
                ? '엔딩: 제6기와 원칙을 지킨 운용자'
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
