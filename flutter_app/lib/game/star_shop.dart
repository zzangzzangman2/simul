import 'game_state.dart';
import 'market_clock.dart';
import 'market_data.dart';

const starCashExchangeId = 'cash_10000';
const starMarketMoodId = 'market_mood';
const starStockHintId = 'stock_hint';
const starDeepReportId = 'deep_report';

class StarShopProduct {
  const StarShopProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.iconLabel,
    this.informationProduct = false,
  });

  final String id;
  final String title;
  final String description;
  final int cost;
  final String iconLabel;
  final bool informationProduct;
}

const starShopProducts = <StarShopProduct>[
  StarShopProduct(
    id: starCashExchangeId,
    title: '회사 지원금 1만원',
    description: '10스타를 회사 은행 계좌의 현금 10,000원으로 교환합니다.',
    cost: 10,
    iconLabel: '₩',
  ),
  StarShopProduct(
    id: starMarketMoodId,
    title: '내일의 시장 기상도',
    description: '다음 거래일에 힘이 실릴 가능성이 큰 업종을 알려줍니다.',
    cost: 2,
    iconLabel: '☀',
    informationProduct: true,
  ),
  StarShopProduct(
    id: starStockHintId,
    title: '유력 종목 힌트',
    description: '다음 거래일의 상승 후보 한 종목과 확인할 단서를 알려줍니다.',
    cost: 3,
    iconLabel: '↑',
    informationProduct: true,
  ),
  StarShopProduct(
    id: starDeepReportId,
    title: '심층 선행 리포트',
    description: '다음 거래일의 후보와 위험 신호를 함께 정리한 상세 메모입니다.',
    cost: 5,
    iconLabel: 'R',
    informationProduct: true,
  ),
];

StarShopProduct? starShopProductForId(String id) =>
    starShopProducts.where((product) => product.id == id).firstOrNull;

int starShopCost(GameState state, StarShopProduct product) {
  final skillDiscount =
      product.informationProduct &&
      state.progression.hasSkill('legendary_house');
  return skillDiscount
      ? (product.cost - 1).clamp(1, product.cost)
      : product.cost;
}

DateTime nextStarShopTradingDate(DateTime currentDate) {
  var date = currentDate.add(const Duration(days: 1));
  while (!isMarketTradingDay(date)) {
    date = date.add(const Duration(days: 1));
  }
  return date;
}

String starShopInformationPurchaseKey(String productId, DateTime targetDate) =>
    '$productId:${marketDateKey(targetDate)}';

String buildStarShopHint(
  GameState state,
  StarShopProduct product,
  DateTime targetDate,
) {
  final events = fictionalMarketEventsForDate(state.simulationSeed, targetDate);
  final companyEvents = events
      .where(
        (event) =>
            event.companyId != fictionalWholeMarketCompanyId &&
            event.companyName.trim().isNotEmpty,
      )
      .toList(growable: false);
  final positive =
      companyEvents
          .where((event) => event.impactPct > 0.004)
          .toList(growable: false)
        ..sort((left, right) => right.impactPct.compareTo(left.impactPct));
  final risks =
      companyEvents
          .where((event) => event.impactPct < -0.004)
          .toList(growable: false)
        ..sort((left, right) => left.impactPct.compareTo(right.impactPct));
  final dateLabel =
      '${targetDate.month}월 ${targetDate.day}일(${_weekdayLabel(targetDate)})';

  if (product.id == starMarketMoodId) {
    final sectorScores = <String, double>{};
    for (final event in events) {
      if (event.sector.trim().isNotEmpty) {
        sectorScores[event.sector] =
            (sectorScores[event.sector] ?? 0) + event.impactPct;
      }
      for (final entry in event.sectorImpactPcts.entries) {
        sectorScores[entry.key] = (sectorScores[entry.key] ?? 0) + entry.value;
      }
    }
    final ranked = sectorScores.entries.toList(growable: false)
      ..sort((left, right) => right.value.compareTo(left.value));
    final strongest = ranked.where((entry) => entry.value > 0.002).firstOrNull;
    if (strongest == null) {
      return '$dateLabel 시장 기상도\n'
          '뚜렷한 상승 선행 신호가 잡히지 않았습니다. 무리한 추격매수보다 현금을 남겨 두고 장중 공시를 확인하세요.\n\n'
          '※ 힌트는 가능성 분석이며 수익을 보장하지 않습니다.';
    }
    return '$dateLabel 시장 기상도\n'
        '${strongest.key} 업종에 상대적으로 따뜻한 바람이 불 가능성이 있습니다. '
        '관련 종목의 거래량과 첫 공시를 함께 확인하세요.\n\n'
        '※ 힌트는 가능성 분석이며 수익을 보장하지 않습니다.';
  }

  if (product.id == starStockHintId) {
    final candidate = positive.firstOrNull;
    if (candidate == null) {
      return '$dateLabel 유력 종목 힌트\n'
          '상승 우위로 특정할 종목이 없습니다. 이런 날은 “사지 않는 선택”도 좋은 투자입니다.\n\n'
          '※ 힌트는 가능성 분석이며 수익을 보장하지 않습니다.';
    }
    return '$dateLabel 유력 종목 힌트\n'
        '${candidate.companyName}(${candidate.sector})를 관심 목록에 올려 보세요. '
        '${candidate.reportHint}\n'
        '확인할 점: ${candidate.signal}\n\n'
        '※ 힌트는 가능성 분석이며 수익을 보장하지 않습니다.';
  }

  final candidateLines = positive
      .take(2)
      .map((event) => '• 상승 후보 ${event.companyName}: ${event.reportHint}');
  final riskLines = risks
      .take(1)
      .map((event) => '• 위험 관찰 ${event.companyName}: ${event.reportHint}');
  final lines = <String>[...candidateLines, ...riskLines];
  if (lines.isEmpty) {
    lines.add('• 강한 선행 신호 없음: 현금 비중을 유지하고 장중 공시를 기다리세요.');
  }
  return '$dateLabel 심층 선행 리포트\n'
      '${lines.join('\n')}\n\n'
      '여러 단서를 함께 확인한 뒤 분할 매수·손실 한도를 정하세요.\n'
      '※ 이 리포트는 가능성 분석이며 수익을 보장하지 않습니다.';
}

String _weekdayLabel(DateTime date) => switch (date.weekday) {
  DateTime.monday => '월',
  DateTime.tuesday => '화',
  DateTime.wednesday => '수',
  DateTime.thursday => '목',
  DateTime.friday => '금',
  DateTime.saturday => '토',
  _ => '일',
};

class StarShopPurchaseResult {
  const StarShopPurchaseResult({
    required this.state,
    required this.success,
    required this.message,
    this.hint,
    this.purchaseKey,
  });

  final GameState state;
  final bool success;
  final String message;
  final String? hint;
  final String? purchaseKey;
}
