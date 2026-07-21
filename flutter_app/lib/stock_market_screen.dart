part of 'main.dart';

class StockMarketScreen extends StatefulWidget {
  const StockMarketScreen({super.key, required this.state});

  final GameState state;

  @override
  State<StockMarketScreen> createState() => _StockMarketScreenState();
}

class _StockMarketScreenState extends State<StockMarketScreen> {
  static const _stocks = [
    _StockDefinition(
      code: '005930',
      name: '삼성전자',
      sector: '반도체 · 전자',
      basePrice: 6100,
      summary: '메모리 반도체와 가전 수출을 함께 보는 대표 조사 종목입니다.',
      question: '반도체 가격이 내려가도 현금을 지킬 수 있을까?',
      accent: Color(0xFF4E78E8),
    ),
    _StockDefinition(
      code: '017670',
      name: 'SK텔레콤',
      sector: '이동통신',
      basePrice: 42800,
      summary: '휴대전화 가입자 증가와 통신망 투자비를 함께 살펴봐야 합니다.',
      question: '가입자는 늘지만 기지국 투자비도 너무 커지는 건 아닐까?',
      accent: Color(0xFFEF5A67),
    ),
    _StockDefinition(
      code: '005490',
      name: '포항제철',
      sector: '철강 · 수출',
      basePrice: 96000,
      summary: '자동차와 건설 경기에 민감한 한국의 대표 철강 기업입니다.',
      question: '경기가 식어도 수출과 원가 경쟁력을 지킬 수 있을까?',
      accent: Color(0xFF54798A),
    ),
    _StockDefinition(
      code: '015760',
      name: '한국전력',
      sector: '전력 · 공기업',
      basePrice: 32800,
      summary: '안정적인 전력 수요와 요금 정책을 함께 공부할 수 있습니다.',
      question: '안정적인 수요가 정책과 연료비 위험보다 클까?',
      accent: Color(0xFF5AA974),
    ),
    _StockDefinition(
      code: '005380',
      name: '현대자동차',
      sector: '자동차 · 수출',
      basePrice: 14800,
      summary: '환율, 수출, 신차 품질이 실적에 곧바로 연결되는 기업입니다.',
      question: '해외에서 한국 자동차의 품질을 인정받을 수 있을까?',
      accent: Color(0xFF4774B8),
    ),
    _StockDefinition(
      code: '035720',
      name: '다음커뮤니케이션',
      sector: '인터넷',
      basePrice: 48700,
      summary: '인터넷 이용자가 빠르게 늘지만 수익 모델은 아직 검증 중입니다.',
      question: '많은 방문자가 실제 이익으로 이어지는 시점은 언제일까?',
      accent: Color(0xFF7F64D9),
    ),
    _StockDefinition(
      code: '035610',
      name: '새롬기술',
      sector: '인터넷 전화',
      basePrice: 124000,
      summary: '큰 기대를 받는 만큼 가격 변동과 과열 위험이 매우 큽니다.',
      question: '기술의 가능성과 시장의 과열을 어떻게 구분할까?',
      accent: Color(0xFFFF8A45),
    ),
    _StockDefinition(
      code: '030520',
      name: '한글과컴퓨터',
      sector: '소프트웨어',
      basePrice: 18600,
      summary: '국산 문서 소프트웨어의 이용자 기반과 수익성을 조사합니다.',
      question: '좋은 프로그램을 꾸준한 매출로 연결할 수 있을까?',
      accent: Color(0xFF3FA5A0),
    ),
  ];

  static const _tickPattern = [
    0.0008,
    -0.0003,
    0.0005,
    -0.0007,
    0.0002,
    0.0009,
    -0.0004,
    0.0003,
  ];

  final _searchController = TextEditingController();
  final Map<String, ValueNotifier<_LiveStock>> _live = {};
  Timer? _timer;
  int _tick = 0;
  int _tab = 1;

  @override
  void initState() {
    super.initState();
    for (var index = 0; index < _stocks.length; index++) {
      final stock = _stocks[index];
      final dayDrift = ((widget.state.day + index * 3) % 11 - 5) / 500;
      final close = stock.basePrice * (1 + dayDrift);
      final points = List<double>.generate(
        18,
        (point) => close * (1 + ((point + index) % 7 - 3) / 700),
      );
      _live[stock.code] = ValueNotifier(
        _LiveStock(
          price: _roundedPrice(close),
          previousClose: _roundedPrice(stock.basePrice),
          open: _roundedPrice(points.first),
          high: _roundedPrice(points.reduce((a, b) => a > b ? a : b)),
          low: _roundedPrice(points.reduce((a, b) => a < b ? a : b)),
          history: points.map(_roundedPrice).toList(),
        ),
      );
    }
    _timer = Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => _update(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    for (final notifier in _live.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  double _roundedPrice(double value) => value >= 10000
      ? (value / 10).roundToDouble() * 10
      : value.roundToDouble();

  void _update() {
    _tick += 1;
    for (var index = 0; index < _stocks.length; index++) {
      final notifier = _live[_stocks[index].code]!;
      final current = notifier.value;
      final movement = _tickPattern[(_tick + index * 3) % _tickPattern.length];
      final nextPrice = _roundedPrice(current.price * (1 + movement));
      final history = [...current.history.skip(1), nextPrice];
      notifier.value = current.copyWith(
        price: nextPrice,
        high: nextPrice > current.high ? nextPrice : current.high,
        low: nextPrice < current.low ? nextPrice : current.low,
        history: history,
      );
    }
  }

  List<_StockDefinition> get _visibleStocks {
    final query = _searchController.text.trim().toLowerCase();
    final source = switch (_tab) {
      0 => _stocks.take(3),
      2 => _stocks.where(
        (stock) => const {'005930', '017670', '005490'}.contains(stock.code),
      ),
      _ => _stocks,
    };
    if (query.isEmpty) return source.toList();
    return source
        .where(
          (stock) =>
              stock.name.toLowerCase().contains(query) ||
              stock.code.contains(query) ||
              stock.sector.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SafeArea(
            child: Column(
              children: [
                _MarketHeader(onBack: () => Navigator.of(context).pop()),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                    children: [
                      _MarketBalanceCard(state: widget.state),
                      const SizedBox(height: 18),
                      TextField(
                        key: const Key('market-search-input'),
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: '회사명이나 종목코드 검색',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _MarketTabs(
                        selected: _tab,
                        onChanged: (value) => setState(() => _tab = value),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Text(
                            '실시간 인기 종목',
                            style: TextStyle(
                              color: Color(0xFF202632),
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                _LiveDot(),
                                SizedBox(width: 5),
                                Text(
                                  '게임 시세',
                                  style: TextStyle(
                                    color: Color(0xFF26845B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        '가격이 움직이는 종목을 눌러 자세히 살펴보세요.',
                        style: TextStyle(
                          color: Color(0xFF8A919E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._visibleStocks.map(
                        (stock) => _StockRow(
                          key: Key('stock-row-${stock.code}'),
                          definition: stock,
                          live: _live[stock.code]!,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _StockDetailScreen(
                                definition: stock,
                                live: _live[stock.code]!,
                                state: widget.state,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_visibleStocks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 50),
                          child: Center(child: Text('검색 결과가 없어요.')),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StockDetailScreen extends StatelessWidget {
  const _StockDetailScreen({
    required this.definition,
    required this.live,
    required this.state,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SafeArea(
            child: ValueListenableBuilder<_LiveStock>(
              valueListenable: live,
              builder: (context, quote, _) {
                final change = quote.price - quote.previousClose;
                final rate = change / quote.previousClose * 100;
                final color = _priceColor(change);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 14, 4),
                      child: Row(
                        children: [
                          IconButton(
                            key: const Key('close-stock-detail'),
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  definition.name,
                                  style: const TextStyle(
                                    color: Color(0xFF202632),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${definition.code} · ${definition.sector}',
                                  style: const TextStyle(
                                    color: Color(0xFF8A919E),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const _LiveDot(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                        children: [
                          Hero(
                            tag: 'stock-${definition.code}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                '${_money(quote.price.round())}원',
                                key: const Key('stock-detail-price'),
                                style: const TextStyle(
                                  color: Color(0xFF171B24),
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${change >= 0 ? '+' : ''}${_money(change.round())}원  ${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            height: 190,
                            child: CustomPaint(
                              painter: _SparklinePainter(
                                quote.history,
                                color,
                                fill: true,
                              ),
                              size: Size.infinite,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _RangeChip(label: '1일', selected: true),
                              _RangeChip(label: '1주'),
                              _RangeChip(label: '1달'),
                              _RangeChip(label: '1년'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _QuoteGrid(quote: quote),
                          const SizedBox(height: 28),
                          const Divider(color: Color(0xFFF0F1F3)),
                          const SizedBox(height: 20),
                          const Text(
                            '이 회사를 한 문장으로',
                            style: TextStyle(
                              color: Color(0xFF202632),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            definition.summary,
                            style: const TextStyle(
                              color: Color(0xFF5D6572),
                              fontSize: 14,
                              height: 1.55,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _HistoricalLeadershipSection(
                            companyCode: definition.code,
                            currentDate: state.currentDate,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7D8),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '오늘의 조사 질문',
                                  style: TextStyle(
                                    color: Color(0xFF8A6815),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  definition.question,
                                  style: const TextStyle(
                                    color: Color(0xFF403617),
                                    fontSize: 14,
                                    height: 1.45,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '실제 회사명을 사용하지만 가격과 설명은 DAY ${state.day}의 게임용 시뮬레이션입니다.',
                            style: const TextStyle(
                              color: Color(0xFF9A9FA8),
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x16000000),
                            blurRadius: 18,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('ask-family-button'),
                              onPressed: () => _showResearchMessage(
                                context,
                                '가족회의 질문에 추가했어요.',
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                foregroundColor: const Color(0xFF38404D),
                                side: const BorderSide(
                                  color: Color(0xFFD8DCE2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                '가족에게 묻기',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              key: const Key('write-research-note-button'),
                              onPressed: () => _showResearchMessage(
                                context,
                                '조사노트 초안을 만들었어요. 주문은 부모님 승인 후 가능해요.',
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                backgroundColor: const Color(0xFF3182F6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                '조사노트 쓰기',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static void _showResearchMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HistoricalLeadershipSection extends StatelessWidget {
  const _HistoricalLeadershipSection({
    required this.companyCode,
    required this.currentDate,
  });

  final String companyCode;
  final DateTime currentDate;

  @override
  Widget build(BuildContext context) {
    final executives = executivesForCompany(companyCode, currentDate);
    if (executives.isEmpty) return const SizedBox.shrink();
    final dateLabel =
        '${currentDate.year}.${currentDate.month.toString().padLeft(2, '0')}.${currentDate.day.toString().padLeft(2, '0')}';
    return Column(
      key: const Key('historical-executive-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '그날의 경영진',
                style: TextStyle(
                  color: Color(0xFF202632),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                dateLabel,
                style: const TextStyle(
                  color: Color(0xFF3774C7),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...executives.map(
          (executive) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HistoricalExecutiveCard(executive: executive),
          ),
        ),
        const Text(
          '이름·재임 직책은 실제 기록 기준이며, 초상은 게임용 AI 캐릭터 일러스트입니다. 게임 속 대사와 판단은 창작입니다.',
          style: TextStyle(
            color: Color(0xFF989FAA),
            fontSize: 9,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HistoricalExecutiveCard extends StatelessWidget {
  const _HistoricalExecutiveCard({required this.executive});

  final HistoricalExecutive executive;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('historical-executive-${executive.recordId}'),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFF5F8FC),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE4EAF2)),
    ),
    child: SizedBox(
      height: 148,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 108,
            child: Image.asset(
              executive.portraitAsset,
              key: Key('executive-portrait-${executive.personId}'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              semanticLabel: '${executive.nameKo} 상반신 게임 초상',
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    executive.roleKo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF3774C7),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    executive.nameKo,
                    style: const TextStyle(
                      color: Color(0xFF252B35),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${executive.nameEn} · ${executive.periodLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8A919E),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    executive.roleNote,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF56606E),
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MarketHeader extends StatelessWidget {
  const _MarketHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 5, 15, 6),
    child: Row(
      children: [
        IconButton(
          key: const Key('close-market-button'),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        const Expanded(
          child: Text(
            '주식',
            style: TextStyle(
              color: Color(0xFF202632),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Icon(Icons.notifications_none_rounded, color: Color(0xFF666D78)),
      ],
    ),
  );
}

class _MarketBalanceCard extends StatelessWidget {
  const _MarketBalanceCard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF3182F6), Color(0xFF5B9AF4)],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '가족 연구계좌',
                style: TextStyle(
                  color: Color(0xFFDDEBFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_money(state.cash)}원',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'DAY ${state.day}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MarketTabs extends StatelessWidget {
  const _MarketTabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['관심', '국내', '내 조사노트'];
    return Row(
      children: List.generate(
        labels.length,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 6),
            child: TextButton(
              onPressed: () => onChanged(index),
              style: TextButton.styleFrom(
                foregroundColor: selected == index
                    ? const Color(0xFF202632)
                    : const Color(0xFF949AA4),
                backgroundColor: selected == index
                    ? Colors.white
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: selected == index
                      ? FontWeight.w900
                      : FontWeight.w700,
                ),
              ),
              child: Text(labels[index]),
            ),
          ),
        ),
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({
    super.key,
    required this.definition,
    required this.live,
    required this.onTap,
  });

  final _StockDefinition definition;
  final ValueNotifier<_LiveStock> live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<_LiveStock>(
    valueListenable: live,
    builder: (context, quote, _) {
      final change = quote.price - quote.previousClose;
      final rate = change / quote.previousClose * 100;
      final color = _priceColor(change);
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: definition.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    definition.name.substring(0, 1),
                    style: TextStyle(
                      color: definition.accent,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        definition.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF252B35),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${definition.code} · ${definition.sector}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9A9FA8),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 58,
                  height: 34,
                  child: CustomPaint(
                    painter: _SparklinePainter(quote.history, color),
                  ),
                ),
                const SizedBox(width: 9),
                SizedBox(
                  width: 83,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Hero(
                        tag: 'stock-${definition.code}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            '${_money(quote.price.round())}원',
                            style: const TextStyle(
                              color: Color(0xFF252B35),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${rate >= 0 ? '+' : ''}${rate.toStringAsFixed(2)}%',
                        key: Key('stock-rate-${definition.code}'),
                        style: TextStyle(
                          color: color,
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
        ),
      );
    },
  );
}

class _QuoteGrid extends StatelessWidget {
  const _QuoteGrid({required this.quote});

  final _LiveStock quote;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        _QuoteValue(label: '전일', value: quote.previousClose),
        _QuoteValue(label: '시가', value: quote.open),
        _QuoteValue(label: '고가', value: quote.high),
        _QuoteValue(label: '저가', value: quote.low),
      ],
    ),
  );
}

class _QuoteValue extends StatelessWidget {
  const _QuoteValue({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF979DA6),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _money(value.round()),
          style: const TextStyle(
            color: Color(0xFF353B45),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFFEAF2FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: selected ? const Color(0xFF3182F6) : const Color(0xFF9399A3),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: const BoxDecoration(
      color: Color(0xFF36B37E),
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: Color(0x6636B37E), blurRadius: 5)],
    ),
  );
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter(this.values, this.color, {this.fill = false});

  final List<double> values;
  final Color color;
  final bool fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.isEmpty) return;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue == minValue ? 1.0 : maxValue - minValue;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y =
          size.height - ((values[index] - minValue) / range * size.height);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (fill) {
      final area = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size)
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = fill ? 2.5 : 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _StockDefinition {
  const _StockDefinition({
    required this.code,
    required this.name,
    required this.sector,
    required this.basePrice,
    required this.summary,
    required this.question,
    required this.accent,
  });

  final String code;
  final String name;
  final String sector;
  final double basePrice;
  final String summary;
  final String question;
  final Color accent;
}

class _LiveStock {
  const _LiveStock({
    required this.price,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.history,
  });

  final double price;
  final double previousClose;
  final double open;
  final double high;
  final double low;
  final List<double> history;

  _LiveStock copyWith({
    double? price,
    double? high,
    double? low,
    List<double>? history,
  }) => _LiveStock(
    price: price ?? this.price,
    previousClose: previousClose,
    open: open,
    high: high ?? this.high,
    low: low ?? this.low,
    history: history ?? this.history,
  );
}

Color _priceColor(double change) =>
    change >= 0 ? const Color(0xFFF04452) : const Color(0xFF3182F6);
