part of 'main.dart';

enum _PracticalTradeTutorialPhase {
  failures,
  buy,
  priceMove,
  sell,
  summary,
  recovery,
  review,
  dismissal,
}

class _PracticalTradeTutorialSheet extends StatefulWidget {
  const _PracticalTradeTutorialSheet({
    required this.definition,
    required this.sourceLive,
    required this.sourceState,
    required this.initialBuyLimitPrice,
    required this.onCompleteTutorial,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> sourceLive;
  final GameState sourceState;
  final double? initialBuyLimitPrice;
  final Future<void> Function()? onCompleteTutorial;

  @override
  State<_PracticalTradeTutorialSheet> createState() =>
      _PracticalTradeTutorialSheetState();
}

class _PracticalTradeTutorialSheetState
    extends State<_PracticalTradeTutorialSheet> {
  static const _practiceSeedMoney = initialCompanyCash;
  static const _practiceMinute = krxOpenMinute + 10;
  static const _engine = GameEngine();

  late GameState _practiceState;
  late final ValueNotifier<_LiveStock> _practiceLive;
  late final ValueNotifier<int> _practiceMinuteNotifier;
  _PracticalTradeTutorialPhase _phase = _PracticalTradeTutorialPhase.failures;
  double _buyPrice = 0;
  double _sellPrice = 0;
  int _realizedPnl = 0;
  bool _finishing = false;
  bool _allowPop = false;
  Timer? _priceMoveTimer;
  List<double> _priceMovePath = const <double>[];
  int _priceMoveStep = 0;
  int _reviewBeat = 0;
  int _recoveryBeat = 0;
  bool _insufficientBalanceTried = false;
  bool _partialFillTried = false;
  String? _reviewChoice;

  bool get _priceMoveComplete =>
      _priceMovePath.isNotEmpty && _priceMoveStep >= _priceMovePath.length - 1;

  @override
  void initState() {
    super.initState();
    var practiceDay = widget.sourceState.day;
    for (var offset = 0; offset < 14; offset += 1) {
      if (isMarketTradingDay(widget.sourceState.dateForDay(practiceDay))) {
        break;
      }
      practiceDay += 1;
    }
    final sourceQuote = widget.sourceLive.value;
    final practiceDate = widget.sourceState.dateForDay(practiceDay);
    var practicePrice = sourceQuote.price;
    final selectedBuyPrice = widget.initialBuyLimitPrice;
    if (selectedBuyPrice != null &&
        selectedBuyPrice.isFinite &&
        selectedBuyPrice > 0) {
      final tickBelow = marketTickSize(
        math.max(0.000001, selectedBuyPrice - 0.000001),
        market: widget.definition.market,
      );
      final dailyRange = marketDailyPriceRange(
        previousClose: sourceQuote.previousClose,
        date: practiceDate,
        market: widget.definition.market,
        isIpoFirstTradingDay: widget.definition.asset.isIpoFirstTradingDay(
          practiceDate,
        ),
      );
      practicePrice = marketSnapPrice(
        (selectedBuyPrice - tickBelow)
            .clamp(dailyRange.lower, dailyRange.upper)
            .toDouble(),
        market: widget.definition.market,
      );
    }
    final practiceSessionHistory = sourceQuote.sessionHistory.isEmpty
        ? <double>[practicePrice]
        : <double>[
            ...sourceQuote.sessionHistory.take(
              sourceQuote.sessionHistory.length - 1,
            ),
            practicePrice,
          ];
    _practiceLive = ValueNotifier<_LiveStock>(
      _LiveStock(
        price: practicePrice,
        previousClose: sourceQuote.previousClose,
        officialClose: sourceQuote.officialClose,
        isTradingDay: true,
        open: sourceQuote.open,
        high: math.max(sourceQuote.high, practicePrice),
        low: math.min(sourceQuote.low, practicePrice),
        history: List<MarketPoint>.from(sourceQuote.history),
        sessionHistory: practiceSessionHistory,
        sessionPath: List<double>.from(sourceQuote.sessionPath),
      ),
    );
    _practiceMinuteNotifier = ValueNotifier<int>(_practiceMinute);
    _practiceState = widget.sourceState.copyWith(
      day: practiceDay,
      marketMinute: _practiceMinute,
      cash: _practiceSeedMoney,
      brokerageCash: _practiceSeedMoney,
      positions: const <PortfolioPosition>[],
      pendingOrders: const <PendingTradeOrder>[],
      story: widget.sourceState.story.copyWith(accountAuthorityLevel: 5),
      ledger: const <LedgerEntry>[],
    );
  }

  @override
  void dispose() {
    _priceMoveTimer?.cancel();
    _practiceLive.dispose();
    _practiceMinuteNotifier.dispose();
    super.dispose();
  }

  Future<TradeExecutionResult> _executePracticeOrder(TradeOrder order) async {
    final stateBeforeOrder = _practiceState;
    final result = _engine.executeTrade(stateBeforeOrder, order);
    if (result.success && result.filledQuantity + 0.000001 < order.quantity) {
      return TradeExecutionResult(
        state: stateBeforeOrder,
        success: false,
        message: '연습 주문이 체결되지 않았어요. 호가를 다시 확인해 주세요.',
      );
    }
    if (result.success && mounted) {
      setState(() {
        _practiceState = result.state;
        if (order.side == TradeSide.sell) {
          _realizedPnl = result.realizedPnl;
        }
      });
    }
    return result;
  }

  void _showPriceMove() {
    final position = _practiceState.positions
        .where((item) => item.assetId == widget.definition.id)
        .firstOrNull;
    _buyPrice = position?.averageCost ?? _practiceLive.value.price;
    const ratePath = <double>[1.0, 1.012, 1.006, 1.025, 1.041, 1.06];
    _priceMovePath = ratePath
        .map(
          (rate) => marketSnapPrice(
            _buyPrice * rate,
            market: widget.definition.market,
          ),
        )
        .toList(growable: false);
    _priceMoveStep = 0;
    _sellPrice = _priceMovePath.first;
    final openingQuote = _practiceLive.value;
    _practiceLive.value = openingQuote.copyWith(
      price: _sellPrice,
      high: math.max(openingQuote.high, _sellPrice),
      low: math.min(openingQuote.low, _sellPrice),
      sessionHistory: <double>[...openingQuote.sessionHistory, _sellPrice],
    );
    setState(() => _phase = _PracticalTradeTutorialPhase.priceMove);

    _priceMoveTimer?.cancel();
    _priceMoveTimer = Timer.periodic(const Duration(milliseconds: 800), (
      timer,
    ) {
      if (!mounted || _phase != _PracticalTradeTutorialPhase.priceMove) {
        timer.cancel();
        return;
      }
      final nextStep = _priceMoveStep + 1;
      if (nextStep >= _priceMovePath.length) {
        timer.cancel();
        return;
      }
      final nextPrice = _priceMovePath[nextStep];
      final nextMinute = _practiceMinute + nextStep * 5;
      final quote = _practiceLive.value;
      setState(() {
        _priceMoveStep = nextStep;
        _sellPrice = nextPrice;
        _practiceState = _practiceState.copyWith(marketMinute: nextMinute);
        _practiceMinuteNotifier.value = nextMinute;
        _practiceLive.value = quote.copyWith(
          price: nextPrice,
          high: math.max(quote.high, nextPrice),
          low: math.min(quote.low, nextPrice),
          sessionHistory: <double>[...quote.sessionHistory, nextPrice],
        );
      });
      if (_priceMoveComplete) timer.cancel();
    });
  }

  void _openSellPractice() {
    if (!_priceMoveComplete) return;
    _priceMoveTimer?.cancel();
    setState(() => _phase = _PracticalTradeTutorialPhase.sell);
  }

  void _showSummary() {
    setState(() => _phase = _PracticalTradeTutorialPhase.summary);
  }

  /// 확정손익에서 국가 환수 20%를 처음 떼는 장면. 데시멀 동기 리부트 저장에서만
  /// 열리며, 정산 카드와 선택형 복기 사이에 들어간다.
  void _showRecovery() {
    if (!widget.sourceState.story.orphanageReboot) {
      _showReview();
      return;
    }
    setState(() {
      _phase = _PracticalTradeTutorialPhase.recovery;
      _recoveryBeat = 0;
    });
  }

  void _advanceRecovery() {
    if (_recoveryBeat >= _recoveryBeatCount - 1) {
      _showReview();
      return;
    }
    setState(() => _recoveryBeat += 1);
  }

  void _showReview() {
    setState(() {
      _phase = _PracticalTradeTutorialPhase.review;
      _reviewBeat = 0;
      _reviewChoice = null;
    });
  }

  void _advanceReview() {
    if (_reviewBeat == 0 && _reviewChoice == null) return;
    if (_reviewBeat >= 3) {
      _showDismissal();
      return;
    }
    setState(() => _reviewBeat += 1);
  }

  void _chooseReview(String choice) {
    setState(() {
      _reviewChoice = choice;
      _reviewBeat = 1;
    });
  }

  void _showDismissal() {
    setState(() => _phase = _PracticalTradeTutorialPhase.dismissal);
  }

  Future<void> _finishTutorial() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await widget.onCompleteTutorial?.call();
      if (!mounted) return;
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('튜토리얼 완료 기록을 저장하지 못했어요. 다시 시도해 주세요.')),
        );
    }
  }

  Widget _failurePracticeView() {
    final unitPrice = marketSnapPrice(
      widget.initialBuyLimitPrice ?? _practiceLive.value.price,
      market: widget.definition.market,
    );
    final affordableUnits = unitPrice <= 0
        ? 0
        : (_practiceState.brokerageCash / unitPrice).floor();
    final attemptedUnits = math.max(affordableUnits + 1, 2).toInt();
    final attemptedTotal = (unitPrice * attemptedUnits).round();
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('tutorial-failure-practice'),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _practiceHeader(
              phaseLabel: '주문 전 실패 연습',
              description:
                  '실수해도 무엇이 바뀌고 무엇이 그대로인지 두 번 확인한 뒤 실제 한 주 주문으로 넘어갑니다.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '틀려 봐야 주문표가 보입니다',
                    style: TextStyle(
                      color: _marketInk,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '아래 두 상황은 주문 리허설이라 정식 국가계좌와 실제 실습 잔고를 바꾸지 않습니다.',
                    style: TextStyle(
                      color: _marketMuted,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TutorialFailureCard(
                    title: '잔액 부족 주문',
                    description:
                        '${_money(unitPrice.round())}원 × $attemptedUnits주 = ${_money(attemptedTotal)}원 주문을 눌러 봅니다.',
                    result: _insufficientBalanceTried
                        ? '접수 거절 · 주문 가능금 ${_money(_practiceState.brokerageCash)}원 그대로 · 빚이나 보유 주식 없음'
                        : null,
                    icon: Icons.account_balance_wallet_outlined,
                    buttonKey: const Key('tutorial-insufficient-funds-try'),
                    buttonLabel: _insufficientBalanceTried
                        ? '잔액 부족 결과 확인함'
                        : '잔액보다 크게 주문해 보기',
                    onPressed: () =>
                        setState(() => _insufficientBalanceTried = true),
                  ),
                  const SizedBox(height: 12),
                  _TutorialFailureCard(
                    title: '부분체결 주문',
                    description: '연습 호가에 2주만 보이는데 3주 매수를 낸 상황을 확인합니다.',
                    result: _partialFillTried
                        ? '2주만 체결 · 나머지 1주는 미체결에 대기 · 정정하거나 취소 가능'
                        : null,
                    icon: Icons.call_split_rounded,
                    buttonKey: const Key('tutorial-partial-fill-try'),
                    buttonLabel: _partialFillTried
                        ? '부분체결 결과 확인함'
                        : '보이는 잔량보다 1주 더 주문해 보기',
                    onPressed: () => setState(() => _partialFillTried = true),
                  ),
                  const SizedBox(height: 14),
                  const _TutorialDialogueCard(
                    speaker: '김학준',
                    message:
                        '돈이 없으면 아예 안 받고, 물건이 모자라면 있는 만큼만 사지는 거네. …두 개가 다른 거였구나.',
                    teacher: false,
                    characterAsset: _stockTutorialHakjunAsset,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    key: const Key('tutorial-failure-practice-complete'),
                    onPressed: _insufficientBalanceTried && _partialFillTried
                        ? () => setState(
                            () => _phase = _PracticalTradeTutorialPhase.buy,
                          )
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: _marketAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.checklist_rounded),
                    label: Text(
                      _insufficientBalanceTried && _partialFillTried
                          ? '실제 한 주 지정가 주문으로 이동'
                          : '두 실패 상황을 모두 눌러 보세요',
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

  Widget _practiceHeader({
    required String phaseLabel,
    required String description,
  }) => Container(
    key: const Key('tutorial-seed-balance'),
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 2),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: <Color>[Color(0xFFFFF7D6), Color(0xFFFFE49A)],
      ),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE7BE45)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            color: Color(0xFF715716),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phaseLabel,
                style: const TextStyle(
                  color: Color(0xFF715716),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF4E4325),
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              '국가 실습계좌',
              style: TextStyle(
                color: Color(0xFF8D762E),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${_money(_practiceState.brokerageCash)}원',
              style: const TextStyle(
                color: Color(0xFF3F351A),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                fontFeatures: _marketNumberFeatures,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _orderPractice({required bool isBuy}) => Column(
    key: Key(isBuy ? 'tutorial-buy-order' : 'tutorial-sell-order'),
    children: [
      _practiceHeader(
        phaseLabel: isBuy ? '국가계좌 실습 1 / 3 · 매수' : '국가계좌 실습 3 / 3 · 매도',
        description: isBuy
            ? widget.initialBuyLimitPrice == null
                  ? '한 주 사 볼까요? 노란 테두리의 매수 버튼만 눌러 보세요.'
                  : '호가창에서 고른 ${_money(widget.initialBuyLimitPrice!.round())}원이 '
                        '입력됐어요. 노란 테두리의 매수 버튼으로 한 주 사 볼까요?'
            : '가격이 움직였네요. 같은 한 주를 팔아 손익을 확정해 봅시다.',
      ),
      Expanded(
        child: _OrderSheet(
          key: ValueKey(isBuy ? 'practice-buy-sheet' : 'practice-sell-sheet'),
          definition: widget.definition,
          live: _practiceLive,
          isBuy: isBuy,
          state: _practiceState,
          minute: _practiceMinuteNotifier,
          onExecuteTrade: _executePracticeOrder,
          balanceLabel: isBuy ? '국가 실습계좌 주문 가능 예수금' : null,
          submitLabel: isBuy ? '지정가 매수 주문 실행' : '매도 주문 실행',
          successLabel: isBuy ? '시간별 계좌 변화 확인하기' : '운영관께 돌아가 결과 보기',
          forceActionHighlight: true,
          initialOrderType: isBuy && widget.initialBuyLimitPrice != null
              ? TradeOrderType.limit
              : null,
          initialLimitPrice: isBuy ? widget.initialBuyLimitPrice : null,
          onSuccessContinue: isBuy ? _showPriceMove : _showSummary,
        ),
      ),
    ],
  );

  Widget _priceMoveView() {
    final position = _practiceState.positions
        .where((item) => item.assetId == widget.definition.id)
        .firstOrNull;
    final units = position?.units ?? 0;
    final currentPrice = _practiceLive.value.price;
    final marketValue = (currentPrice * units).round();
    final totalCost = position?.totalCost ?? 0;
    final estimatedChange = marketValue - totalCost;
    final accountValue = _practiceState.brokerageCash + marketValue;
    final changeRate = _buyPrice <= 0
        ? 0.0
        : (currentPrice / _buyPrice - 1) * 100;
    final progress = _priceMovePath.length <= 1
        ? 1.0
        : _priceMoveStep / (_priceMovePath.length - 1);
    final currentMinute = _practiceMinuteNotifier.value;
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('tutorial-price-change'),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '국가계좌 실습 2 / 3 · 실시간 계좌',
              style: TextStyle(
                color: _marketAccent,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '매수 뒤 가격이 움직였어요',
              style: TextStyle(
                color: _marketInk,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '5분씩 시간이 흐를 때마다 현재가와 내 계좌 평가금이 함께 바뀌는 모습을 지켜보세요.',
              style: TextStyle(
                color: _marketMuted,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              key: const Key('tutorial-live-account-state'),
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _priceMoveComplete
                      ? const Color(0xFFFFC84F)
                      : const Color(0xFF8ED6B7),
                  width: _priceMoveComplete ? 3 : 1.5,
                ),
                boxShadow: _priceMoveComplete
                    ? const [
                        BoxShadow(
                          color: Color(0x66FFD85E),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ]
                    : const [],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF315D57),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          marketTimeLabel(currentMinute),
                          key: const Key('tutorial-live-market-time'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            fontFeatures: _marketNumberFeatures,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_priceMoveStep + 1} / ${_priceMovePath.length} 시세',
                        style: const TextStyle(
                          color: Color(0xFF52736D),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '현재가',
                        style: TextStyle(
                          color: _marketMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _displayPrice(currentPrice, 'KRW'),
                        key: const Key('tutorial-live-current-price'),
                        style: const TextStyle(
                          color: Color(0xFF168B5E),
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          fontFeatures: _marketNumberFeatures,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _signedPercent(changeRate),
                      style: TextStyle(
                        color: changeRate > 0
                            ? const Color(0xFF168B5E)
                            : changeRate < 0
                            ? const Color(0xFFB42332)
                            : _marketMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: const Color(0xFFD1E7DD),
                    color: const Color(0xFF20A675),
                  ),
                  const Divider(height: 26),
                  _PracticeSummaryRow(
                    label: '주문 가능 예수금',
                    value: '${_money(_practiceState.brokerageCash)}원',
                  ),
                  _PracticeSummaryRow(
                    label: '보유 주식',
                    value: '${_displayUnits(units)}주',
                  ),
                  _PracticeSummaryRow(
                    label: '현재 평가금',
                    value: '${_money(marketValue)}원',
                  ),
                  _PracticeSummaryRow(
                    label: '평가손익',
                    value:
                        '${estimatedChange >= 0 ? '+' : ''}${_money(estimatedChange)}원',
                    strong: true,
                  ),
                  _PracticeSummaryRow(
                    label: '실시간 내 계좌',
                    value: '${_money(accountValue)}원',
                    strong: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _priceMoveComplete
                  ? const _TutorialDialogueCard(
                      key: Key('tutorial-price-rise-teacher'),
                      speaker: '한서윤 운영관',
                      message: '화면의 이익은 아직 평가액이에요. 한 주를 팔아 결과를 확정해 볼까요?',
                      teacher: true,
                      characterAsset: _stockTeacherPoseEmphasize,
                    )
                  : _TutorialDialogueCard(
                      key: ValueKey<int>(_priceMoveStep),
                      speaker: '한서윤 운영관',
                      message:
                          '${marketTimeLabel(currentMinute)}이에요. 아직 팔지 말고 내 계좌 숫자가 어떻게 달라지는지 조금 더 지켜봐요.',
                      teacher: true,
                      characterAsset: _stockTeacherPoseListen,
                    ),
            ),
            const SizedBox(height: 14),
            Container(
              key: const Key('tutorial-sell-navigation-highlight'),
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: _priceMoveComplete
                      ? const Color(0xFFFFD85E)
                      : const Color(0xFFD5DBE3),
                  width: _priceMoveComplete ? 4 : 1,
                ),
                boxShadow: _priceMoveComplete
                    ? const [
                        BoxShadow(
                          color: Color(0x99FFD85E),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : const [],
              ),
              child: FilledButton(
                key: const Key('tutorial-price-change-continue'),
                onPressed: _priceMoveComplete ? _openSellPractice : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFFF04452),
                  disabledBackgroundColor: const Color(0xFFBCC3CD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _priceMoveComplete ? '한 주 팔고 결과 확정하기' : '가격 움직임 지켜보는 중…',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '보유 중 손익은 화면 속 평가손익이고, 실제로 팔아야 손익이 확정돼요.',
              style: TextStyle(
                color: _marketMuted,
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryView() => SafeArea(
    child: SingleChildScrollView(
      key: const Key('tutorial-trade-summary'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 64,
            color: Color(0xFF20A675),
          ),
          const SizedBox(height: 12),
          const Text(
            '매수부터 매도까지 완료!',
            style: TextStyle(
              color: _marketInk,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '모의 국가계좌로 한 주를 사고 다시 팔았습니다. 팔고 나서야 손익과 국가 환수액, 자립적립금이 함께 확정됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _marketMuted,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _PracticeSummaryRow(
                  label: '시작 국가원금',
                  value: '${_money(_practiceSeedMoney)}원',
                ),
                _PracticeSummaryRow(
                  label: '매도 후 주문 가능금',
                  value: '${_money(_practiceState.brokerageCash)}원',
                ),
                _PracticeSummaryRow(
                  label: '팔아서 확정된 손익',
                  value:
                      '${_realizedPnl >= 0 ? '+' : ''}${_money(_realizedPnl)}원',
                  strong: true,
                ),
                if (widget.sourceState.story.orphanageReboot) ...[
                  _PracticeSummaryRow(
                    label: '국가 환수 20%',
                    value:
                        '${_money(_practiceState.story.stateRecoveryTotal)}원',
                  ),
                  _PracticeSummaryRow(
                    label: '모의 자립적립금 80% · 오늘만 잠금',
                    value:
                        '${_money(_practiceState.story.selfRelianceReserve)}원',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '국가원금 50,000원으로 연습하는 날은 오늘 딱 하루입니다. 오늘 손익은 리허설에만 남고, 다음 거래일부터 같은 50,000원으로 실전 운용을 시작합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8B6F21),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('tutorial-summary-continue'),
              onPressed: _showRecovery,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: _marketAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '운영관과 거래 돌아보기',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  /// 확정손익에서 국가가 20%를 떼는 순간의 대사. 여덟 명이 같은 숫자를 보고
  /// 각자 다른 것을 발견한다. 운영관은 제도를 변호하지 않는다.
  List<_RecoveryBeat> get _recoveryBeats {
    final gained = _realizedPnl > 0;
    final pnl = _money(_realizedPnl.abs());
    final recovered = _money(_practiceState.story.stateRecoveryTotal);
    final reserved = _money(_practiceState.story.selfRelianceReserve);
    if (!gained) {
      return <_RecoveryBeat>[
        _RecoveryBeat(
          '한서윤 운영관',
          _stockTeacherPoseListen,
          '이번엔 $pnl원 잃었어요. 그러면 숫자 하나만 확인할게요.',
        ),
        _RecoveryBeat(
          '정아린',
          _stockTutorialArinAsset,
          '잃었으니까 국가가 떼 가는 것도 없는 거죠?',
        ),
        _RecoveryBeat(
          '한서윤 운영관',
          _stockTeacherPoseCompare,
          '없어요. 환수는 벌었을 때만 해요.',
        ),
        _RecoveryBeat(
          '이지안',
          _stockTutorialJianFocusAsset,
          '그럼 잃으면 국가도 20% 물어 줘요?',
        ),
        _RecoveryBeat('한서윤 운영관', _stockTeacherPoseCompare, '안 물어 줘요.'),
        _RecoveryBeat('이지안', _stockTutorialJianAsset, '…그건 공평한 거예요?'),
        _RecoveryBeat('한서윤 운영관', _stockTeacherPoseListen, '아니요.'),
        _RecoveryBeat('최이서', _stockTutorialIseoAsset, '…운영관이 아니라고 하니까 더 이상해요.'),
        _RecoveryBeat(
          '김서아',
          _stockTutorialSeoaRecordAsset,
          '적어 둘게. 1월 3일, $pnl원 잃음. 환수 없음. 이유는 내가 쓴 노트에.',
        ),
        _RecoveryBeat(
          '박하은',
          _stockTutorialHaeunAsset,
          '손실을 먼저 말한 사람한테 혼자 미안해하라고 하진 말자. 우리도 같은 화면을 보고 동의했잖아.',
        ),
        _RecoveryBeat(
          '한수아',
          _stockTutorialSuaExplainAsset,
          '아침엔 모두 한빛통신 얘기만 했어. 좋아서 산 건지, 다들 말해서 좋아 보인 건지도 적어 두자.',
        ),
        _RecoveryBeat(
          '윤채아',
          _stockTutorialChaeaNeutralAsset,
          '손실 한 번보다 어떤 전제가 깨졌는지가 중요해. 다음 주문 전에 그 조건부터 바꾸자.',
        ),
        _RecoveryBeat(
          '오지우',
          _stockTutorialJiwooCorrectAsset,
          '속보입니다. 데시멀 동기 첫 거래, 손실 $pnl원. …이건 방송 안 할게요.',
        ),
      ];
    }
    return <_RecoveryBeat>[
      _RecoveryBeat(
        '한서윤 운영관',
        _stockTeacherPoseListen,
        '$pnl원 벌었어요. 그럼 이제 숫자 하나만 더 볼게요.',
      ),
      _RecoveryBeat(
        '정아린',
        _stockTutorialArinAsset,
        '$pnl원에서 $recovered원 떼면 $reserved원이요. 근데 그 $reserved원 지금 쓸 수 있어요?',
      ),
      _RecoveryBeat('한서윤 운영관', _stockTeacherPoseCompare, '못 써요. 열아홉 살에요.'),
      _RecoveryBeat('정아린', _stockTutorialArinWorriedAsset, '…오 년이요?'),
      _RecoveryBeat('한서윤 운영관', _stockTeacherPoseCompare, '오 년이요.'),
      _RecoveryBeat('김학준', _stockTutorialHakjunAsset, '운영관, 이거 안내문 몇 쪽에 있어요?'),
      _RecoveryBeat('한서윤 운영관', _stockTeacherPoseBook, '안내문엔 없어요. 특별법에 있어요.'),
      _RecoveryBeat('김학준', _stockTutorialHakjunAsset, '…그건 제가 못 봤는데요.'),
      _RecoveryBeat('한서윤 운영관', _stockTeacherPoseListen, '아직 아무도 안 보여 줬으니까요.'),
      _RecoveryBeat('윤채아', _stockTutorialChaeaAsset, '왜 20%예요? 누가 정했어요?'),
      _RecoveryBeat('한서윤 운영관', _stockTeacherPoseCompare, '1981년에 어른 여섯 명이요.'),
      _RecoveryBeat('윤채아', _stockTutorialChaeaNeutralAsset, '…그 사람들 지금도 있어요?'),
      _RecoveryBeat('한서윤 운영관', _stockTeacherPoseListen, '그건 오늘 대답 안 할게요.'),
      _RecoveryBeat(
        '이지안',
        _stockTutorialJianFocusAsset,
        '운영관. 그럼 잃으면요? 국가도 20% 물어 줘요?',
      ),
      _RecoveryBeat('한서윤 운영관', _stockTeacherPoseCompare, '안 물어 줘요.'),
      _RecoveryBeat(
        '이지안',
        _stockTutorialJianAsset,
        '그럼 벌 때만 나눠 가지는 거예요? …그건 공평한 거예요?',
      ),
      _RecoveryBeat('한서윤 운영관', _stockTeacherPoseListen, '아니요.'),
      _RecoveryBeat('최이서', _stockTutorialIseoAsset, '…내가 벌었는데 내 돈이 아닌 거네요.'),
      _RecoveryBeat(
        '김서아',
        _stockTutorialSeoaRecordAsset,
        '적어 둘게. 1월 3일, $pnl원 벌었다. $recovered원 갔다. $reserved원은 오 년 뒤.',
      ),
      _RecoveryBeat(
        '박하은',
        _stockTutorialHaeunAsset,
        '이 규칙을 우리만 늦게 알면 안 돼. 다음 사람이 계좌를 받기 전에는 먼저 설명해 달라고 같이 요구하자.',
      ),
      _RecoveryBeat(
        '한수아',
        _stockTutorialSuaExplainAsset,
        '수익 났다고 이유까지 맞았다고 하진 말자. 오늘 사람들이 왜 몰렸는지는 반응이 식을 때 다시 보자.',
      ),
      _RecoveryBeat(
        '오지우',
        _stockTutorialJiwooCorrectAsset,
        '속보입니다. 데시멀 동기 첫 수익 $pnl원. 국가가 $recovered원 가져갔습니다. …이거 웃겨야 하는데 안 웃기네요.',
      ),
    ];
  }

  int get _recoveryBeatCount => _recoveryBeats.length;

  Widget _recoveryView() {
    final beats = _recoveryBeats;
    final index = _recoveryBeat.clamp(0, beats.length - 1);
    final beat = beats[index];
    final isTeacherBeat = beat.speaker == '한서윤 운영관';
    return GestureDetector(
      key: const Key('tutorial-state-recovery'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _activeNovelDialogueState?._handleExternalTap(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/cinematic_soft_painted/decimal/bg_decimal_trading_floor_dawn_2000_v1.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xB3000000),
                  Color(0x12000000),
                  Color(0xD9000000),
                ],
                stops: <double>[0, 0.5, 1],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC17233D),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0x66FFFFFF)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_balance_rounded,
                            size: 17,
                            color: Color(0xFFFFD36A),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '확정손익과 국가 환수',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${index + 1} / ${beats.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: -_storyCharacterBottomInset,
            bottom: _storyCharacterBottomInset,
            child: _OnboardingCharacterSlot(
              key: ValueKey<String>('tutorial-recovery-slot-${beat.asset}'),
              asset: beat.asset,
              alignment: Alignment.bottomCenter,
              characterKey: Key(
                isTeacherBeat
                    ? 'tutorial-recovery-teacher-character'
                    : 'tutorial-recovery-peer-character',
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: SafeArea(
              top: false,
              child: _NovelDialogue(
                key: ValueKey(('tutorial-recovery-dialogue', index)),
                speaker: beat.speaker,
                playerName: widget.sourceState.story.playerName,
                line: beat.message,
                onContinue: _advanceRecovery,
                continueKey: const Key('tutorial-recovery-continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewView() {
    final studentName = widget.sourceState.story.playerName.trim().isEmpty
        ? '나'
        : widget.sourceState.story.playerName.trim();
    final isTeacherBeat = _reviewBeat == 0 || _reviewBeat == 2;
    final speaker = switch (_reviewBeat) {
      0 || 2 => '한서윤 운영관',
      1 => studentName,
      _ => _reviewChoice == 'turnover' ? '김학준' : '수아',
    };
    final characterAsset = switch (_reviewBeat) {
      0 => _stockTeacherPoseListen,
      1 => '',
      2 =>
        _reviewChoice == 'ledger'
            ? _stockTeacherPoseBook
            : _stockTeacherPoseCompare,
      _ =>
        _reviewChoice == 'turnover'
            ? _stockTutorialHakjunAsset
            : _stockTutorialSuaAsset,
    };
    final message = switch (_reviewBeat) {
      0 => '첫 거래를 다시 본다면 무엇을 가장 먼저 확인해야 할까요? 직접 골라 보세요.',
      1 => switch (_reviewChoice) {
        'chase' => '한 번 벌었는데 다음엔 좀 더 크게 해도 되는 거 아니에요? 지금 될 것 같은 느낌인데.',
        'ledger' => '일단 투자노트부터 깔래요. 내가 매수 이유랑 매도 조건 말 바꿨는지 체크.',
        _ => '거래대금이랑 회전율 큰 종목만 타면 실패 확률 낮지 않아요?',
      },
      2 => switch (_reviewChoice) {
        'chase' =>
          '이번 수익은 과정이 옳았다는 증명이 아니에요. 운 좋게 오른 결과만 보고 수량을 늘리면 위험도 함께 커져요.',
        'ledger' => '좋아요. 수익 숫자보다 내가 적은 이유와 조건을 지켰는지 확인해야 다음 판단도 고칠 수 있어요.',
        _ => '거래대금과 회전율은 사람들이 활발히 손바꿈했다는 뜻이지, 회사가 이익을 냈거나 안전하다는 뜻이 아니에요.',
      },
      _ => switch (_reviewChoice) {
        'chase' => '나도 한 번 벌면 잘하는 줄 알았어. …운이었을 수도 있는 거네.',
        'ledger' => '적어 놓은 걸 지켰는지 보는 거구나. 그럼 나중에 말 바꾸기 어렵겠다.',
        _ => '아. 나 회전율이라는 이름한테 속았어. 많이 오간 거랑 잘 버는 건 다른 거였네.',
      },
    };
    return Stack(
      key: const Key('tutorial-post-trade-review'),
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/cinematic_soft_painted/decimal/bg_decimal_trading_floor_dawn_2000_v1.png',
          key: const Key('tutorial-review-academy-background'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xB3000000),
                Color(0x12000000),
                Color(0xD9000000),
              ],
              stops: <double>[0, 0.5, 1],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC17233D),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x66FFFFFF)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school_rounded,
                          size: 17,
                          color: Color(0xFFFFD36A),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '데시멀 첫 주문 복기',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_reviewBeat + 1} / 4',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (characterAsset.isNotEmpty)
          Positioned.fill(
            top: -_storyCharacterBottomInset,
            bottom: _storyCharacterBottomInset,
            child: _OnboardingCharacterSlot(
              key: ValueKey<String>('tutorial-review-slot-$characterAsset'),
              asset: characterAsset,
              alignment: Alignment.bottomCenter,
              characterKey: Key(
                isTeacherBeat
                    ? 'tutorial-review-teacher-character'
                    : 'tutorial-review-peer-character',
              ),
            ),
          ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 10,
          child: SafeArea(
            top: false,
            child: _NovelDialogue(
              key: ValueKey(('tutorial-review-dialogue', _reviewBeat)),
              speaker: speaker,
              playerName: widget.sourceState.story.playerName,
              line: message,
              choices: _reviewBeat == 0
                  ? <_NovelChoice>[
                      _NovelChoice(
                        key: const Key('tutorial-review-choice-chase'),
                        label: '한 번 벌었으니 다음엔 수량 더 세게 간다',
                        onTap: () => _chooseReview('chase'),
                      ),
                      _NovelChoice(
                        key: const Key('tutorial-review-choice-ledger'),
                        label: '투자노트부터 깐다: 이유·조건 체크',
                        onTap: () => _chooseReview('ledger'),
                      ),
                      _NovelChoice(
                        key: const Key('tutorial-review-choice-turnover'),
                        label: '거래대금 큰 종목만 타면 된다',
                        onTap: () => _chooseReview('turnover'),
                      ),
                    ]
                  : const <_NovelChoice>[],
              onContinue: _reviewBeat == 0 ? null : _advanceReview,
              continueKey: const Key('tutorial-review-continue'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dismissalView() {
    final studentName = widget.sourceState.story.playerName.trim().isEmpty
        ? '나'
        : widget.sourceState.story.playerName.trim();
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const Key('tutorial-school-dismissal'),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.wb_twilight_rounded,
                    size: 58,
                    color: Color(0xFFF2A93B),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '데시멀 첫 주문 실습 완료',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _marketInk,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _TutorialDialogueCard(
                    speaker: '한서윤 운영관',
                    message:
                        '오만 원 연습은 오늘 딱 하루로 끝이에요. 다음 거래일부터는 리허설이 아니라 실전입니다. 파산하면 주말 알바로 다시 만들거나 동기에게 높은 이자를 약속하고 빌릴 수 있어요.',
                    teacher: true,
                    characterAsset: _stockTeacherPoseBook,
                  ),
                  const SizedBox(height: 10),
                  _TutorialDialogueCard(
                    speaker: studentName,
                    message: '네. 실제 국가계좌에서는 산 이유와 철회 조건부터 장부에 쓰고 주문할게요.',
                  ),
                  const SizedBox(height: 14),
                  Container(
                    key: const Key('tutorial-stock-feature-map'),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F6FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFB8C9EA)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '주식 앱 기능 지도',
                          style: TextStyle(
                            color: Color(0xFF315FAD),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 10),
                        _TutorialFeatureRow(
                          label: '홈',
                          detail: '시장 지수 · 뉴스 · 종목 순위',
                        ),
                        _TutorialFeatureRow(
                          label: '주식',
                          detail: '검색 · 시장 분류 · 신규/관심 종목',
                        ),
                        _TutorialFeatureRow(
                          label: '종목',
                          detail: '호가 · 주문 · 차트 · 회사 정보/투자노트',
                        ),
                        _TutorialFeatureRow(
                          label: '내 투자',
                          detail: '예수금 · 보유 · 미체결 · 매매일지 · 기업행동',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7DF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEACB7B)),
                    ),
                    child: const Text(
                      '마감음이 짧게 울렸다. 50,000원 연습 계좌는 오늘로 닫혔다. 다음 거래일부터 손익과 빚이 저장되는 실전 계좌가 열린다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF5D4B21),
                        height: 1.55,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('market-practical-tutorial-complete'),
                onPressed: _finishing ? null : _finishTutorial,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: _marketAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _finishing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.directions_walk_rounded),
                label: Text(
                  _finishing ? '실전 계좌를 여는 중…' : '연습일 종료 · 다음 거래일부터 실전',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: _allowPop,
    child: KeyedSubtree(
      key: const Key('market-practical-tutorial'),
      child: switch (_phase) {
        _PracticalTradeTutorialPhase.failures => _failurePracticeView(),
        _PracticalTradeTutorialPhase.buy => _orderPractice(isBuy: true),
        _PracticalTradeTutorialPhase.priceMove => _priceMoveView(),
        _PracticalTradeTutorialPhase.sell => _orderPractice(isBuy: false),
        _PracticalTradeTutorialPhase.summary => _summaryView(),
        _PracticalTradeTutorialPhase.recovery => _recoveryView(),
        _PracticalTradeTutorialPhase.review => _reviewView(),
        _PracticalTradeTutorialPhase.dismissal => _dismissalView(),
      },
    ),
  );
}

class _TutorialFailureCard extends StatelessWidget {
  const _TutorialFailureCard({
    required this.title,
    required this.description,
    required this.result,
    required this.icon,
    required this.buttonKey,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String? result;
  final IconData icon;
  final Key buttonKey;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: result == null ? const Color(0xFFF5F7FA) : const Color(0xFFEAF8F2),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: result == null
            ? const Color(0xFFD9DEE7)
            : const Color(0xFF79C7A8),
        width: result == null ? 1 : 1.5,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: result == null ? _marketMuted : const Color(0xFF168B5E),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _marketInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          description,
          style: const TextStyle(
            color: _marketMuted,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 9),
          Text(
            result!,
            key: ValueKey<String>('tutorial-failure-result-$title'),
            style: const TextStyle(
              color: Color(0xFF176A50),
              height: 1.4,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
        const SizedBox(height: 11),
        OutlinedButton(
          key: buttonKey,
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            foregroundColor: result == null
                ? _marketAccent
                : const Color(0xFF176A50),
            side: BorderSide(
              color: result == null ? _marketAccent : const Color(0xFF79C7A8),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: Text(
            buttonLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

class _PracticeSummaryRow extends StatelessWidget {
  const _PracticeSummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                color: strong ? const Color(0xFF168B5E) : _marketInk,
                fontWeight: FontWeight.w900,
                fontFeatures: _marketNumberFeatures,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _TutorialDialogueCard extends StatelessWidget {
  const _TutorialDialogueCard({
    super.key,
    required this.speaker,
    required this.message,
    this.teacher = false,
    this.characterAsset,
  });

  final String speaker;
  final String message;
  final bool teacher;
  final String? characterAsset;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: teacher ? const Color(0xFFFFF5EE) : const Color(0xFFF2F6FF),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: teacher ? const Color(0xFFF2B49E) : const Color(0xFFAFC3E8),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (characterAsset case final asset?)
          SizedBox(
            key: ValueKey<String>('tutorial-dialogue-character-$asset'),
            width: 62,
            height: 94,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.high,
            ),
          )
        else
          CircleAvatar(
            radius: 18,
            backgroundColor: teacher
                ? const Color(0xFFF18775)
                : const Color(0xFF6688C7),
            child: Icon(
              teacher ? Icons.school_rounded : Icons.face_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                speaker,
                style: TextStyle(
                  color: teacher
                      ? const Color(0xFFB14F42)
                      : const Color(0xFF405F9B),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                message,
                style: const TextStyle(
                  color: _marketInk,
                  height: 1.5,
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

class _TutorialFeatureRow extends StatelessWidget {
  const _TutorialFeatureRow({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF315FAD),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: Text(
            detail,
            style: const TextStyle(
              color: _marketInk,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

/// 확정손익·국가 환수 장면의 한 박자. 화자·전신 자산·대사를 함께 묶어
/// 배열 길이가 어긋나는 실수를 구조적으로 막는다.
class _RecoveryBeat {
  const _RecoveryBeat(this.speaker, this.asset, this.message);

  final String speaker;
  final String asset;
  final String message;
}
