part of 'main.dart';

typedef BankOpenDepositCallback =
    Future<FinanceActionResult> Function(int amount, int termMonths);
typedef BankRedeemDepositCallback =
    Future<FinanceActionResult> Function(String depositId);
typedef BankTakeLoanCallback =
    Future<FinanceActionResult> Function(int amount, int termMonths);
typedef BankRepayLoanCallback =
    Future<FinanceActionResult> Function(String loanId, int amount);

enum _BankDeskTab { deposit, loan }

enum _BankClerkMood { welcome, explain, approve, concerned }

class BankScreen extends StatefulWidget {
  const BankScreen({
    super.key,
    required this.state,
    required this.onOpenDeposit,
    required this.onRedeemDeposit,
    required this.onTakeLoan,
    required this.onRepayLoan,
    this.onCompleteTutorial,
  });

  final GameState state;
  final BankOpenDepositCallback onOpenDeposit;
  final BankRedeemDepositCallback onRedeemDeposit;
  final BankTakeLoanCallback onTakeLoan;
  final BankRepayLoanCallback onRepayLoan;
  final Future<GameState> Function()? onCompleteTutorial;

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  late GameState _state = widget.state;
  _BankDeskTab _tab = _BankDeskTab.deposit;
  int _depositTermMonths = 12;
  int _loanTermMonths = 24;
  bool _introVisible = true;
  int _introBeat = 0;
  bool _busy = false;
  _BankClerkMood _clerkMood = _BankClerkMood.welcome;
  int? _tutorialStep;
  bool _tutorialCompleting = false;
  final GlobalKey _depositTermTutorialKey = GlobalKey();
  final GlobalKey _depositOpenTutorialKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.onCompleteTutorial != null &&
        !_state.story.bankDepositTutorialSeen) {
      _tutorialStep = 0;
      _introVisible = false;
      _clerkMood = _BankClerkMood.welcome;
    }
  }

  String get _clerkAsset => switch (_clerkMood) {
    _BankClerkMood.welcome =>
      'assets/images/character_bank_clerk_title_style_v2.png',
    _BankClerkMood.explain =>
      'assets/images/character_bank_clerk_explain_v2.png',
    _BankClerkMood.approve =>
      'assets/images/character_bank_clerk_approve_v2.png',
    _BankClerkMood.concerned =>
      'assets/images/character_bank_clerk_concerned_v2.png',
  };

  BankLoanOffer get _loanOffer => const GameEngine().unsecuredLoanOffer(
    _state,
    termMonths: _loanTermMonths,
  );

  GlobalKey? get _tutorialTargetKey => switch (_tutorialStep) {
    1 => _depositTermTutorialKey,
    2 => _depositOpenTutorialKey,
    _ => null,
  };

  void _advanceDepositTutorial() {
    final step = _tutorialStep;
    if (step == null || _tutorialCompleting) return;
    if (step >= 3) {
      unawaited(_completeDepositTutorial());
      return;
    }
    setState(() {
      _tutorialStep = step + 1;
      if (_tutorialStep == 1) {
        _depositTermMonths = 12;
        _clerkMood = _BankClerkMood.explain;
      } else if (_tutorialStep == 2) {
        _clerkMood = _BankClerkMood.concerned;
      } else {
        _clerkMood = _BankClerkMood.approve;
      }
    });
  }

  Future<void> _completeDepositTutorial() async {
    if (_tutorialCompleting) return;
    final complete = widget.onCompleteTutorial;
    if (complete == null) {
      if (mounted) setState(() => _tutorialStep = null);
      return;
    }
    setState(() => _tutorialCompleting = true);
    try {
      final next = await complete();
      if (!mounted) return;
      setState(() {
        _state = next;
        _tutorialStep = null;
        _tutorialCompleting = false;
        _introVisible = false;
        _clerkMood = _BankClerkMood.approve;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _tutorialCompleting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('예금 튜토리얼 저장에 실패했습니다. 다시 시도해 주세요.')),
        );
    }
  }

  Future<void> _apply(Future<FinanceActionResult> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await action();
      if (!mounted) return;
      setState(() {
        if (result.success) _state = result.state;
        _clerkMood = result.success
            ? _BankClerkMood.approve
            : _BankClerkMood.concerned;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<int?> _askAmount({
    required String title,
    required String description,
    required int maximum,
    required String confirmLabel,
    String Function(int amount)? previewBuilder,
  }) async {
    final safeMaximum = math.max(0, maximum);
    final controller = TextEditingController(
      text: safeMaximum <= 0 ? '' : safeMaximum.toString(),
    );
    final selected = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F3E8),
      builder: (sheetContext) {
        var error = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void submit() {
              final raw = controller.text.replaceAll(',', '').trim();
              final amount = int.tryParse(raw) ?? 0;
              if (amount <= 0 || amount > safeMaximum) {
                setSheetState(() {
                  error = safeMaximum <= 0
                      ? '지금 이용할 수 있는 금액이 없습니다.'
                      : '1원부터 ${_money(safeMaximum)}원까지 입력해 주세요.';
                });
                return;
              }
              Navigator.of(sheetContext).pop(amount);
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                18 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF687187),
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    key: const Key('bank-amount-input'),
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setSheetState(() => error = ''),
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: '금액',
                      suffixText: '원',
                      errorText: error.isEmpty ? null : error,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  if (safeMaximum > 0) ...[
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children:
                          <int>{
                                math.max(1, safeMaximum ~/ 4),
                                math.max(1, safeMaximum ~/ 2),
                                safeMaximum,
                              }
                              .map((amount) {
                                return ActionChip(
                                  label: Text(
                                    amount == safeMaximum
                                        ? '최대'
                                        : '${_money(amount)}원',
                                  ),
                                  onPressed: () {
                                    controller.text = amount.toString();
                                    setSheetState(() => error = '');
                                  },
                                );
                              })
                              .toList(growable: false),
                    ),
                  ],
                  if (previewBuilder != null) ...[
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final amount =
                            int.tryParse(
                              controller.text.replaceAll(',', '').trim(),
                            ) ??
                            0;
                        return Container(
                          key: const Key('bank-amount-preview'),
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFB9CBE1)),
                          ),
                          child: Text(
                            amount > 0 && amount <= safeMaximum
                                ? previewBuilder(amount)
                                : '금액을 입력하면 상환 일정을 미리 보여드려요.',
                            style: const TextStyle(
                              color: Color(0xFF52647B),
                              fontSize: 10.5,
                              height: 1.45,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      key: const Key('bank-amount-confirm'),
                      onPressed: safeMaximum <= 0 ? null : submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E5B85),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
    return selected;
  }

  Future<void> _openDeposit() async {
    final amount = await _askAmount(
      title: '$_depositTermMonths개월 정기예금',
      description:
          '회사 통장에서 예치하며 만기 전 해지하면 중도해지 이율이 적용됩니다. '
          '현재 출금 가능액 ${_money(_state.bankCash)}원',
      maximum: _state.bankCash,
      confirmLabel: '예금 가입',
    );
    if (amount == null) return;
    await _apply(() => widget.onOpenDeposit(amount, _depositTermMonths));
  }

  Future<void> _takeLoan() async {
    final offer = _loanOffer;
    final firstPaymentDate = _firstBankLoanPaymentDate(_state.currentDate);
    final amount = await _askAmount(
      title: '$_loanTermMonths개월 신용대출',
      description:
          '${offer.creditLabel} · 적용 연 ${(offer.annualInterestRate * 100).toStringAsFixed(2)}% · '
          '최대한도 ${_money(offer.maximumPrincipal)}원',
      maximum: offer.eligible ? offer.maximumPrincipal : 0,
      confirmLabel: '대출 실행',
      previewBuilder: (amount) {
        final monthlyPayment = offer.monthlyPaymentFor(amount);
        final totalPayment = monthlyPayment * _loanTermMonths;
        final totalInterest = math.max(0, totalPayment - amount);
        return '월 원리금 약 ${_money(monthlyPayment)}원\n'
            '총 예상이자 약 ${_money(totalInterest)}원 · '
            '첫 납부 ${_bankDate(firstPaymentDate)}';
      },
    );
    if (amount == null) return;
    await _apply(() => widget.onTakeLoan(amount, _loanTermMonths));
  }

  Future<void> _repayLoan(BankUnsecuredLoan loan) async {
    final amount = await _askAmount(
      title: '신용대출 상환',
      description:
          '대출잔액 ${_money(loan.balance)}원 · 회사 통장 ${_money(_state.bankCash)}원',
      maximum: math.min(loan.balance, _state.bankCash),
      confirmLabel: '상환하기',
    );
    if (amount == null) return;
    await _apply(() => widget.onRepayLoan(loan.id, amount));
  }

  Future<void> _redeemDeposit(BankTermDeposit deposit) async {
    final matured = deposit.maturedAt(_state.day);
    if (!matured) setState(() => _clerkMood = _BankClerkMood.concerned);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(matured ? '만기 예금을 받을까요?' : '예금을 중도 해지할까요?'),
        content: Text(
          matured
              ? '세후 이자를 포함해 ${_money(deposit.redemptionAmountAt(_state.day))}원이 회사 통장으로 들어옵니다.'
              : '약정금리 대신 중도해지 이율이 적용됩니다.\n'
                    '지금 수령액 ${_money(deposit.redemptionAmountAt(_state.day))}원',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('계속 보유'),
          ),
          FilledButton(
            key: const Key('bank-redeem-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(matured ? '만기 수령' : '중도 해지'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      if (mounted) setState(() => _clerkMood = _BankClerkMood.explain);
      return;
    }
    await _apply(() => widget.onRedeemDeposit(deposit.id));
  }

  void _startConsultation(_BankDeskTab tab) {
    setState(() {
      _tab = tab;
      _introVisible = false;
      _clerkMood = tab == _BankDeskTab.loan && !_loanOffer.eligible
          ? _BankClerkMood.concerned
          : _BankClerkMood.explain;
    });
  }

  void _continueIntroduction() {
    setState(() {
      _introBeat = 1;
      _clerkMood = _BankClerkMood.explain;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tutorialStep == null,
      child: Scaffold(
        key: const Key('bank-screen'),
        backgroundColor: const Color(0xFF172231),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final panelTop = math.max(326.0, constraints.maxHeight * 0.42);
            return Stack(
              fit: StackFit.expand,
              children: [
                const _LivingBackground(
                  asset:
                      'assets/images/bg_bank_branch_2000_portrait_cartoon_v2.png',
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x660A1728),
                        Color(0x080A1728),
                        Color(0xB80A1728),
                      ],
                      stops: [0, 0.48, 1],
                    ),
                  ),
                ),
                if (_tutorialStep == null)
                  Positioned.fill(
                    top: -_storyCharacterBottomInset,
                    bottom: _storyCharacterBottomInset,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _OnboardingCharacterSlot(
                          key: const Key('bank-clerk-slot'),
                          asset: _clerkAsset,
                          alignment: Alignment.bottomCenter,
                          characterKey: const Key('bank-clerk-character'),
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: SizedBox.shrink(
                            key: Key('bank-clerk-${_clerkMood.name}'),
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: _SceneClockStrip(
                      location: '새천년은행 · 개인금융 창구',
                      caption: '예금과 신용을 숫자로 확인하는 곳',
                      minute: _state.marketMinute,
                      costLabel: '통장 ${_money(_state.bankCash)}원',
                      onBack: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                if (_introVisible)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: SafeArea(
                      top: false,
                      child: _NovelDialogue(
                        key: const Key('bank-intro-dialogue'),
                        speaker: '윤하린 은행원',
                        line: _introBeat == 0
                            ? '어서 오세요. 예금과 신용 상담을 맡은 윤하린이에요.'
                            : '돈을 기간별로 맡기거나, 신용점수와 상환능력에 맞춰 대출을 받을 수 있어요.',
                        choices: _introBeat == 0
                            ? [
                                _NovelChoice(
                                  key: const Key('bank-intro-continue'),
                                  label: '상담을 부탁할게요',
                                  onTap: _continueIntroduction,
                                ),
                              ]
                            : [
                                _NovelChoice(
                                  key: const Key('bank-intro-deposit'),
                                  label: '예금부터 알아볼게요',
                                  onTap: () =>
                                      _startConsultation(_BankDeskTab.deposit),
                                ),
                                _NovelChoice(
                                  key: const Key('bank-intro-loan'),
                                  label: '제 신용과 대출한도를 볼게요',
                                  onTap: () =>
                                      _startConsultation(_BankDeskTab.loan),
                                ),
                              ],
                      ),
                    ),
                  )
                else
                  Positioned(
                    left: 8,
                    top: panelTop,
                    right: 8,
                    bottom: 8,
                    child: SafeArea(
                      top: false,
                      child: _BankConsultationPanel(
                        state: _state,
                        tab: _tab,
                        busy: _busy,
                        selectedDepositTerm: _depositTermMonths,
                        selectedLoanTerm: _loanTermMonths,
                        loanOffer: _loanOffer,
                        onTabChanged: (tab) {
                          setState(() {
                            _tab = tab;
                            _clerkMood =
                                tab == _BankDeskTab.loan && !_loanOffer.eligible
                                ? _BankClerkMood.concerned
                                : _BankClerkMood.explain;
                          });
                        },
                        onDepositTermChanged: (months) {
                          setState(() {
                            _depositTermMonths = months;
                            _clerkMood = _BankClerkMood.explain;
                          });
                        },
                        onLoanTermChanged: (months) {
                          setState(() {
                            _loanTermMonths = months;
                            _clerkMood =
                                const GameEngine()
                                    .unsecuredLoanOffer(
                                      _state,
                                      termMonths: months,
                                    )
                                    .eligible
                                ? _BankClerkMood.explain
                                : _BankClerkMood.concerned;
                          });
                        },
                        onOpenDeposit: _openDeposit,
                        onRedeemDeposit: _redeemDeposit,
                        onTakeLoan: _takeLoan,
                        onRepayLoan: _repayLoan,
                        onTalk: () {
                          setState(() {
                            _introVisible = true;
                            _introBeat = 0;
                            _clerkMood = _BankClerkMood.welcome;
                          });
                        },
                        tutorialTermKey: _tutorialStep == null
                            ? null
                            : _depositTermTutorialKey,
                        tutorialOpenKey: _tutorialStep == null
                            ? null
                            : _depositOpenTutorialKey,
                      ),
                    ),
                  ),
                if (_busy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x33000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                if (_tutorialStep case final step?)
                  Positioned.fill(
                    child: _BankDepositTutorialOverlay(
                      step: step,
                      targetKey: _tutorialTargetKey,
                      onAction: _advanceDepositTutorial,
                    ),
                  ),
                if (_tutorialStep != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _GuidedTutorialSkipButton(
                      buttonKey: const Key('bank-deposit-tutorial-skip'),
                      dialogKey: const Key('bank-deposit-tutorial-skip-dialog'),
                      cancelKey: const Key('bank-deposit-tutorial-skip-cancel'),
                      confirmKey: const Key(
                        'bank-deposit-tutorial-skip-confirm',
                      ),
                      description:
                          '건너뛰어도 예금 화면은 그대로 이용할 수 있고, 윤하린 은행원의 설명은 완료로 저장됩니다.',
                      onSkip: _completeDepositTutorial,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BankDepositTutorialOverlay extends StatelessWidget {
  const _BankDepositTutorialOverlay({
    required this.step,
    required this.targetKey,
    required this.onAction,
  });

  final int step;
  final GlobalKey? targetKey;
  final VoidCallback onAction;

  String get _asset => switch (step) {
    0 => 'assets/images/character_bank_clerk_title_style_v2.png',
    1 => 'assets/images/character_bank_clerk_explain_v2.png',
    2 => 'assets/images/character_bank_clerk_concerned_v2.png',
    _ => 'assets/images/character_bank_clerk_approve_v2.png',
  };

  List<String> get _messages => switch (step) {
    0 => const [
      '회사 통장에 남는 돈을 그냥 두지 않고, 정한 기간 동안 묶어 확정 이자를 받는 게 정기예금이에요.',
      '주식처럼 가격이 움직이지는 않지만 중간에 꺼내면 약정 이자를 다 받지 못해요. 쓸 시점을 먼저 정해야 해요.',
    ],
    1 => const [
      '6·12·24개월은 돈이 묶이는 기간이에요. 기간마다 화면에 표시된 게임 기준금리가 달라져요.',
      '우선 12개월을 눌러 금리와 기간을 비교해 볼까요? 아직 예금은 가입되지 않아요.',
    ],
    2 => const [
      '가입 전에는 운영자금과 저녁에 쓸 현금을 남겼는지 확인하세요. 예금 원금은 만기 전까지 바로 쓸 수 없어요.',
      '이 버튼을 누르면 금액 확인창이 한 번 더 나와요. 확인 전에는 돈이 움직이지 않습니다.',
    ],
    _ => const [
      '가입한 예금은 아래 보유 목록에서 원금·만기일·예상 수령액을 계속 확인할 수 있어요.',
      '만기에는 원금과 세후 이자가 회사 통장으로 들어옵니다. 이제 필요한 금액만 직접 선택해 보세요.',
    ],
  };

  @override
  Widget build(BuildContext context) => _StockTutorialGuideOverlay(
    overlayKey: const Key('bank-deposit-tutorial-overlay'),
    actionKey: const Key('bank-deposit-tutorial-next'),
    targetActionKey: const Key('bank-deposit-tutorial-target'),
    targetKey: targetKey,
    messageId: 'bank-deposit-tutorial-$step',
    speakers: const ['윤하린 은행원', '윤하린 은행원'],
    messages: _messages,
    actionLabel: step >= 3 ? '설명 마치기' : '다음 설명',
    teacherPoseAsset: _asset,
    characterAssets: [_asset, _asset],
    wrongTapFeedbacks: const [
      '윤하린: 노란 테두리 안의 항목부터 확인해 주세요.',
      '윤하린: 아직 돈은 움직이지 않았어요. 강조한 곳을 눌러볼까요?',
      '윤하린: 천천히 보셔도 괜찮아요. 안내한 항목만 누르면 됩니다.',
    ],
    onAction: onAction,
  );
}

class _BankConsultationPanel extends StatelessWidget {
  const _BankConsultationPanel({
    required this.state,
    required this.tab,
    required this.busy,
    required this.selectedDepositTerm,
    required this.selectedLoanTerm,
    required this.loanOffer,
    required this.onTabChanged,
    required this.onDepositTermChanged,
    required this.onLoanTermChanged,
    required this.onOpenDeposit,
    required this.onRedeemDeposit,
    required this.onTakeLoan,
    required this.onRepayLoan,
    required this.onTalk,
    this.tutorialTermKey,
    this.tutorialOpenKey,
  });

  final GameState state;
  final _BankDeskTab tab;
  final bool busy;
  final int selectedDepositTerm;
  final int selectedLoanTerm;
  final BankLoanOffer loanOffer;
  final ValueChanged<_BankDeskTab> onTabChanged;
  final ValueChanged<int> onDepositTermChanged;
  final ValueChanged<int> onLoanTermChanged;
  final VoidCallback onOpenDeposit;
  final ValueChanged<BankTermDeposit> onRedeemDeposit;
  final VoidCallback onTakeLoan;
  final ValueChanged<BankUnsecuredLoan> onRepayLoan;
  final VoidCallback onTalk;
  final GlobalKey? tutorialTermKey;
  final GlobalKey? tutorialOpenKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('bank-consultation-panel'),
      decoration: BoxDecoration(
        color: const Color(0xFAFFF9EC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9BE8D), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66081221),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E5B85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '새천년은행 상담',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '신용 ${state.banking.creditScore}점 · 통장 ${_money(state.bankCash)}원',
                        style: const TextStyle(
                          color: Color(0xFF6D7381),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('bank-talk-to-clerk'),
                  tooltip: '은행원과 다시 대화',
                  onPressed: onTalk,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SegmentedButton<_BankDeskTab>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _BankDeskTab.deposit,
                  icon: Icon(Icons.savings_rounded, size: 18),
                  label: Text('예금'),
                ),
                ButtonSegment(
                  value: _BankDeskTab.loan,
                  icon: Icon(Icons.credit_score_rounded, size: 18),
                  label: Text('대출'),
                ),
              ],
              selected: {tab},
              onSelectionChanged: (value) => onTabChanged(value.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: tab == _BankDeskTab.deposit
                ? _BankDepositDesk(
                    state: state,
                    selectedTerm: selectedDepositTerm,
                    busy: busy,
                    onTermChanged: onDepositTermChanged,
                    onOpen: onOpenDeposit,
                    onRedeem: onRedeemDeposit,
                    tutorialTermKey: tutorialTermKey,
                    tutorialOpenKey: tutorialOpenKey,
                  )
                : _BankLoanDesk(
                    state: state,
                    selectedTerm: selectedLoanTerm,
                    offer: loanOffer,
                    busy: busy,
                    onTermChanged: onLoanTermChanged,
                    onTake: onTakeLoan,
                    onRepay: onRepayLoan,
                  ),
          ),
        ],
      ),
    );
  }
}

class _BankDepositDesk extends StatelessWidget {
  const _BankDepositDesk({
    required this.state,
    required this.selectedTerm,
    required this.busy,
    required this.onTermChanged,
    required this.onOpen,
    required this.onRedeem,
    this.tutorialTermKey,
    this.tutorialOpenKey,
  });

  final GameState state;
  final int selectedTerm;
  final bool busy;
  final ValueChanged<int> onTermChanged;
  final VoidCallback onOpen;
  final ValueChanged<BankTermDeposit> onRedeem;
  final GlobalKey? tutorialTermKey;
  final GlobalKey? tutorialOpenKey;

  @override
  Widget build(BuildContext context) {
    final deposits = state.banking.termDeposits;
    return ListView(
      key: const Key('bank-deposit-list'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      children: [
        const Text(
          '기간을 정해 맡기기',
          style: TextStyle(
            color: _ink,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [6, 12, 24]
              .map((months) {
                final selected = months == selectedTerm;
                final rate = bankTermDepositAnnualRateAt(
                  state.currentDate,
                  months,
                  cashManagementSkill: state.progression.hasSkill(
                    'cash_management',
                  ),
                );
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: months == 24 ? 0 : 6),
                    child: KeyedSubtree(
                      key: months == 12 ? tutorialTermKey : null,
                      child: ChoiceChip(
                        key: Key('bank-deposit-term-$months'),
                        label: SizedBox(
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$months개월'),
                              Text(
                                '게임 기준금리 ${(rate * 100).toStringAsFixed(2)}%',
                                style: const TextStyle(
                                  fontSize: 7.7,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        selected: selected,
                        onSelected: busy ? null : (_) => onTermChanged(months),
                        selectedColor: const Color(0xFFCDE7DE),
                        labelStyle: const TextStyle(
                          color: _ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 7),
        KeyedSubtree(
          key: tutorialOpenKey,
          child: SizedBox(
            height: 43,
            child: FilledButton.icon(
              key: const Key('bank-open-deposit'),
              onPressed: busy || state.bankCash <= 0 ? null : onOpen,
              icon: const Icon(Icons.add_card_rounded, size: 18),
              label: Text(
                '$selectedTerm개월 · 게임 기준금리 '
                '${(bankTermDepositAnnualRateAt(state.currentDate, selectedTerm, cashManagementSkill: state.progression.hasSkill('cash_management')) * 100).toStringAsFixed(2)}% 가입',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2D7A67),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            const Expanded(
              child: Text(
                '보유 예금',
                style: TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '평가액 ${_money(state.banking.termDepositAssetValueAt(state.day))}원',
              style: const TextStyle(
                color: Color(0xFF52647B),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (deposits.isEmpty)
          const _BankEmptyCard(
            icon: Icons.savings_outlined,
            message: '가입한 정기예금이 없습니다.',
          )
        else
          ...deposits.map(
            (deposit) => _BankDepositCard(
              deposit: deposit,
              day: state.day,
              maturityDate: state.dateForDay(deposit.maturityDay),
              busy: busy,
              onRedeem: () => onRedeem(deposit),
            ),
          ),
      ],
    );
  }
}

class _BankDepositCard extends StatelessWidget {
  const _BankDepositCard({
    required this.deposit,
    required this.day,
    required this.maturityDate,
    required this.busy,
    required this.onRedeem,
  });

  final BankTermDeposit deposit;
  final int day;
  final DateTime maturityDate;
  final bool busy;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final matured = deposit.maturedAt(day);
    final daysLeft = math.max(0, deposit.maturityDay - day);
    return Container(
      key: Key('bank-deposit-${deposit.id}'),
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD9D5C9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${deposit.termMonths}개월 정기예금 · 게임 기준금리 ${(deposit.annualInterestRate * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '원금 ${_money(deposit.principal)}원 · '
                  '${matured ? '만기 도착' : '만기까지 $daysLeft일'}\n'
                  '만기일 ${_bankDate(maturityDate)} · '
                  '지금 수령 ${_money(deposit.redemptionAmountAt(day))}원',
                  style: const TextStyle(
                    color: Color(0xFF687187),
                    fontSize: 9.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            key: Key('bank-redeem-${deposit.id}'),
            onPressed: busy ? null : onRedeem,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(68, 38),
              padding: const EdgeInsets.symmetric(horizontal: 9),
            ),
            child: Text(matured ? '만기 수령' : '중도 해지'),
          ),
        ],
      ),
    );
  }
}

class _BankLoanDesk extends StatelessWidget {
  const _BankLoanDesk({
    required this.state,
    required this.selectedTerm,
    required this.offer,
    required this.busy,
    required this.onTermChanged,
    required this.onTake,
    required this.onRepay,
  });

  final GameState state;
  final int selectedTerm;
  final BankLoanOffer offer;
  final bool busy;
  final ValueChanged<int> onTermChanged;
  final VoidCallback onTake;
  final ValueChanged<BankUnsecuredLoan> onRepay;

  @override
  Widget build(BuildContext context) {
    final loans = state.banking.unsecuredLoans;
    final existingMonthlyDebtService =
        state.banking.monthlyUnsecuredDebtService +
        state.personalFinance.monthlyMortgagePayment;
    final currentDsr = offer.qualifyingMonthlyIncome <= 0
        ? 0.0
        : existingMonthlyDebtService / offer.qualifyingMonthlyIncome * 100;
    return ListView(
      key: const Key('bank-loan-list'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1FA),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFB9CBE1)),
          ),
          child: Row(
            children: [
              Container(
                width: 49,
                height: 49,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E5B85),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${state.banking.creditScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.creditLabel,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.eligible
                          ? '한도 ${_money(offer.maximumPrincipal)}원 · '
                                '기준금리 ${(bankRateEnvironmentAt(state.currentDate).unsecuredLoanBaseAnnualRate * 100).toStringAsFixed(2)}% · '
                                '적용 연 ${(offer.annualInterestRate * 100).toStringAsFixed(2)}%\n'
                                '월 인정소득 ${_money(offer.qualifyingMonthlyIncome)}원 · '
                                '현재 DSR ${currentDsr.toStringAsFixed(1)}% / 한도 40.0%'
                          : offer.reason,
                      style: TextStyle(
                        color: offer.eligible
                            ? const Color(0xFF52647B)
                            : const Color(0xFFB64B4B),
                        fontSize: 9.5,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [12, 24, 36]
              .map((months) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: months == 36 ? 0 : 6),
                    child: ChoiceChip(
                      key: Key('bank-loan-term-$months'),
                      label: SizedBox(
                        width: double.infinity,
                        child: Text('$months개월', textAlign: TextAlign.center),
                      ),
                      selected: selectedTerm == months,
                      onSelected: busy ? null : (_) => onTermChanged(months),
                      selectedColor: const Color(0xFFDCE8F6),
                      labelStyle: const TextStyle(
                        color: _ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 43,
          child: FilledButton.icon(
            key: const Key('bank-take-loan'),
            onPressed: busy || !offer.eligible || offer.maximumPrincipal <= 0
                ? null
                : onTake,
            icon: const Icon(Icons.request_quote_rounded, size: 18),
            label: Text('$selectedTerm개월 대출 신청'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E5B85),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            const Expanded(
              child: Text(
                '대출 상환',
                style: TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '잔액 ${_money(state.banking.totalUnsecuredLoanBalance)}원',
              style: const TextStyle(
                color: Color(0xFF52647B),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (loans.isEmpty)
          const _BankEmptyCard(
            icon: Icons.credit_score_outlined,
            message: '이용 중인 신용대출이 없습니다.',
          )
        else
          ...loans.map(
            (loan) => _BankLoanCard(
              loan: loan,
              day: state.day,
              bankCash: state.bankCash,
              busy: busy,
              onRepay: () => onRepay(loan),
            ),
          ),
      ],
    );
  }
}

class _BankLoanCard extends StatelessWidget {
  const _BankLoanCard({
    required this.loan,
    required this.day,
    required this.bankCash,
    required this.busy,
    required this.onRepay,
  });

  final BankUnsecuredLoan loan;
  final int day;
  final int bankCash;
  final bool busy;
  final VoidCallback onRepay;

  @override
  Widget build(BuildContext context) {
    final dueIn = math.max(0, loan.nextPaymentDay - day);
    return Container(
      key: Key('bank-loan-${loan.id}'),
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: loan.consecutiveMissedPayments > 0
            ? const Color(0xFFFFECE8)
            : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: loan.consecutiveMissedPayments > 0
              ? const Color(0xFFE39A8E)
              : const Color(0xFFD9D5C9),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '잔액 ${_money(loan.balance)}원 · 연 ${(loan.annualInterestRate * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '월 예정 ${_money(loan.dueAmount)}원 · '
                  '납부일까지 $dueIn일 · 남은 ${loan.remainingMonths}개월'
                  '${loan.consecutiveMissedPayments > 0 ? '\n연속 연체 ${loan.consecutiveMissedPayments}회' : ''}',
                  style: TextStyle(
                    color: loan.consecutiveMissedPayments > 0
                        ? const Color(0xFFB64B4B)
                        : const Color(0xFF687187),
                    fontSize: 9.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            key: Key('bank-repay-${loan.id}'),
            onPressed: busy || bankCash <= 0 ? null : onRepay,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(68, 38),
              padding: const EdgeInsets.symmetric(horizontal: 9),
            ),
            child: const Text('상환'),
          ),
        ],
      ),
    );
  }
}

class _BankEmptyCard extends StatelessWidget {
  const _BankEmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFF1EEE5),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF88909F)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF777E8C),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

DateTime _firstBankLoanPaymentDate(DateTime currentDate) {
  final earliest = currentDate.add(const Duration(days: 30));
  var dueDate = DateTime(earliest.year, earliest.month, 1);
  if (dueDate.isBefore(earliest)) {
    dueDate = DateTime(earliest.year, earliest.month + 1, 1);
  }
  return dueDate;
}

String _bankDate(DateTime date) =>
    '${date.year}.${date.month.toString().padLeft(2, '0')}.'
    '${date.day.toString().padLeft(2, '0')}';
