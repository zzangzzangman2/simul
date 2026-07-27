part of 'main.dart';

class StarShopScreen extends StatefulWidget {
  const StarShopScreen({
    super.key,
    required this.state,
    required this.onPurchase,
  });

  final GameState state;
  final Future<StarShopPurchaseResult> Function(String productId) onPurchase;

  @override
  State<StarShopScreen> createState() => _StarShopScreenState();
}

class _StarShopScreenState extends State<StarShopScreen> {
  late GameState _state = widget.state;
  String? _buyingId;
  String? _selectedHint;

  Future<void> _buy(StarShopProduct product) async {
    if (_buyingId != null) return;
    final targetDate = nextStarShopTradingDate(_state.currentDate);
    final purchaseKey = product.informationProduct
        ? starShopInformationPurchaseKey(product.id, targetDate)
        : null;
    final savedHint = purchaseKey == null
        ? null
        : _state.progression.starHints[purchaseKey];
    if (savedHint != null) {
      setState(() => _selectedHint = savedHint);
      return;
    }
    setState(() => _buyingId = product.id);
    try {
      final result = await widget.onPurchase(product.id);
      if (!mounted) return;
      if (result.success) {
        setState(() {
          _state = result.state;
          _selectedHint = result.hint ?? _selectedHint;
        });
      } else if (result.hint != null) {
        setState(() => _selectedHint = result.hint);
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    } finally {
      if (mounted) setState(() => _buyingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetDate = nextStarShopTradingDate(_state.currentDate);
    final targetLabel =
        '${targetDate.year}.${targetDate.month.toString().padLeft(2, '0')}.${targetDate.day.toString().padLeft(2, '0')}';
    final savedHints = _state.progression.starHints.entries.toList(
      growable: false,
    );
    return Scaffold(
      key: const Key('star-shop-screen'),
      backgroundColor: const Color(0xFF101934),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18254A),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          '별빛 상점',
          style: TextStyle(
            fontFamily: _hubDisplayFont,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF293B74), Color(0xFF513D7D)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x66FFF2B6)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Color(0x26FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFFFDE69),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '보유 스타',
                          style: TextStyle(
                            color: Color(0xFFC9D5FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '⭐ ${_state.progression.starBalance}',
                          key: const Key('star-balance'),
                          style: const TextStyle(
                            fontFamily: _hubDisplayFont,
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '미션 1개 완료 = ⭐ 1',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF1B284D),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '정보 상품은 다음 거래일($targetLabel) 기준이며 하루에 상품별 1번만 살 수 있어요. '
                '현금 교환액은 주식 계좌가 아닌 회사 은행 계좌로 들어옵니다.',
                style: const TextStyle(
                  color: Color(0xFFCBD6F2),
                  fontSize: 10.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '오늘의 상품',
              style: TextStyle(
                fontFamily: _hubDisplayFont,
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            ...starShopProducts.map((product) {
              final purchaseKey = product.informationProduct
                  ? starShopInformationPurchaseKey(product.id, targetDate)
                  : null;
              final savedHint = purchaseKey == null
                  ? null
                  : _state.progression.starHints[purchaseKey];
              final cost = starShopCost(_state, product);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StarShopProductCard(
                  product: product,
                  cost: cost,
                  balance: _state.progression.starBalance,
                  purchased: savedHint != null,
                  loading: _buyingId == product.id,
                  onTap: () => _buy(product),
                ),
              );
            }),
            if (_selectedHint != null) ...[
              const SizedBox(height: 8),
              _StarShopReportCard(
                hint: _selectedHint!,
                onClose: () => setState(() => _selectedHint = null),
              ),
            ],
            if (savedHints.isNotEmpty) ...[
              const SizedBox(height: 17),
              const Text(
                '구매한 정보',
                style: TextStyle(
                  fontFamily: _hubDisplayFont,
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...savedHints.reversed.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: OutlinedButton(
                    key: Key('star-saved-hint-${entry.key}'),
                    onPressed: () =>
                        setState(() => _selectedHint = entry.value),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFE18A),
                      side: const BorderSide(color: Color(0xFF4B5E91)),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                    ),
                    child: Text(
                      entry.value.split('\n').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StarShopProductCard extends StatelessWidget {
  const _StarShopProductCard({
    required this.product,
    required this.cost,
    required this.balance,
    required this.purchased,
    required this.loading,
    required this.onTap,
  });

  final StarShopProduct product;
  final int cost;
  final int balance;
  final bool purchased;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = purchased || balance >= cost;
    return Container(
      key: Key('star-product-${product.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: purchased ? const Color(0xFF8E73D7) : const Color(0xFF7E91C1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF263B70),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text(
              product.iconLabel,
              style: const TextStyle(
                color: Color(0xFFFFDE69),
                fontSize: 21,
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
                  product.title,
                  style: const TextStyle(
                    color: Color(0xFF23345E),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: const TextStyle(
                    color: Color(0xFF65708B),
                    fontSize: 9.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            height: 40,
            child: FilledButton(
              key: Key('star-buy-${product.id}'),
              onPressed: enabled && !loading ? onTap : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                backgroundColor: const Color(0xFF475FC1),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD0D5E3),
                disabledForegroundColor: const Color(0xFF7E8495),
              ),
              child: loading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      purchased ? '열기' : '⭐ $cost',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarShopReportCard extends StatelessWidget {
  const _StarShopReportCard({required this.hint, required this.onClose});

  final String hint;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('star-shop-report'),
    padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6D6),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE5B94E), width: 1.5),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lightbulb_rounded, color: Color(0xFFC68615), size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hint,
            style: const TextStyle(
              color: Color(0xFF3E4250),
              fontSize: 11,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: '리포트 닫기',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded, size: 18),
          color: const Color(0xFF6B6F7A),
        ),
      ],
    ),
  );
}
