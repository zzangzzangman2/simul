/// 네트워크나 외부 AI 없이 공개된 시장 정보만으로 신문 문장을 조합한다.
///
/// 조합 결과는 시뮬레이션 시드와 날짜가 같으면 모든 기기에서 동일하다.
class NewsCombinatorInput {
  const NewsCombinatorInput({
    required this.simulationSeed,
    required this.year,
    required this.date,
    required this.marketSummary,
    required this.marketTheme,
    required this.marketClosed,
    required this.advancers,
    required this.decliners,
    required this.unchanged,
  });

  final String simulationSeed;
  final int year;
  final String date;
  final String marketSummary;
  final String marketTheme;
  final bool marketClosed;
  final int advancers;
  final int decliners;
  final int unchanged;

  /// 저장·테스트용 공개 정보 묶음. 플레이어와 미래 사건 정보는 받지 않는다.
  Map<String, Object> toSafeSnapshot() => {
    'simulationSeed': simulationSeed,
    'year': year,
    'date': date,
    'marketSummary': marketSummary,
    'marketTheme': marketTheme,
    'marketClosed': marketClosed,
    'advancers': advancers,
    'decliners': decliners,
    'unchanged': unchanged,
  };
}

class CombinatorialNewsArticle {
  const CombinatorialNewsArticle({
    required this.headline,
    required this.content,
    required this.marketSentiment,
    required this.variantId,
  });

  final String headline;
  final String content;
  final String marketSentiment;
  final int variantId;
}

class NewsCombinator {
  const NewsCombinator();

  static const _headlineLeads = <String>[
    '장 마감',
    '오늘의 증시',
    '시장 결산',
    '거래일 점검',
    '증권가 마감 노트',
    '하루 증시 돌아보기',
    '종가로 본 시장',
    '수급으로 읽는 장세',
    '업종별 온도차',
    '투자자별 흐름',
    '마감 시황',
    '시장 한눈에 보기',
  ];

  static const _headlineFocuses = <String>[
    '수급과 업종 흐름에 시선',
    '상승·하락 종목 사이 온도차',
    '투자자 선택이 만든 하루',
    '거래 흐름 속 옥석 가리기',
    '종목별 차별화 뚜렷',
    '실적과 재료에 반응한 시장',
    '매수세와 매도세 팽팽',
    '주도 업종 찾기 이어져',
    '거래량 실린 종목에 관심',
    '다음 거래일 변수 점검',
  ];

  static const _summaryIntroductions = <String>[
    '시장 집계를 보면',
    '마감 수치를 살펴보면',
    '오늘 거래 결과는',
    '종목별 등락을 합산하면',
    '장 종료 뒤 집계에서는',
    '하루 흐름을 숫자로 정리하면',
    '국내 종목의 마감 성적은',
    '거래를 마친 시장에서는',
    '마감판에 남은 숫자를 보면',
    '오늘 장의 폭을 확인하면',
    '전체 종목 흐름을 보면',
    '시장 내부의 움직임은',
  ];

  static const _themeBridges = <String>[
    '시장 배경으로는',
    '오늘 투자자들이 살핀 재료는',
    '장중 시선이 모인 화두는',
    '종목 선택에 영향을 준 배경은',
    '증권가가 함께 점검한 변수는',
    '수급과 맞물린 재료로는',
    '오늘 장을 설명하는 단서는',
    '업종별 차이를 만든 배경은',
    '투자 판단에 참고할 흐름은',
    '시장이 소화한 주요 내용은',
  ];

  static const _interpretations = <String>[
    '{tone} 흐름이 나타났지만 종목마다 반응의 크기는 달랐다.',
    '전체적으로 {tone} 분위기였고 실적과 가격 부담에 따라 차별화가 이어졌다.',
    '{tone} 쪽에 무게가 실렸으나 단기 등락만으로 추세를 단정하기는 이르다.',
    '수치상 {tone} 장세였지만 거래량이 동반됐는지도 함께 볼 필요가 있다.',
    '{tone} 흐름 속에서도 업종과 기업별 재료에 따라 매수세가 엇갈렸다.',
    '시장은 {tone} 방향을 보였고 투자자들은 확인된 사실에 더 민감하게 반응했다.',
    '{tone} 분위기가 우세했지만 장중 변동 폭은 종목별로 크게 달랐다.',
    '마감 결과는 {tone} 흐름을 가리켰고 수급의 지속 여부가 다음 관건으로 남았다.',
    '{tone} 장세 속에서 가격보다 기업별 변화의 내용을 따져보는 움직임이 보였다.',
    '오늘은 {tone} 흐름이었으며 시장 전체보다 개별 종목 선택이 중요해졌다.',
    '집계는 {tone} 장세를 보여 줬지만 한 번의 마감만으로 방향을 확정할 수는 없다.',
    '{tone} 쪽이 우세한 가운데 다음 거래일에는 재료의 후속 확인이 필요하다.',
  ];

  static const _cautions = <String>[
    '공개된 공시와 실제 거래량을 함께 확인하는 편이 안전하다.',
    '급한 추격보다 가격대별 잔량과 거래 흐름을 차분히 살필 필요가 있다.',
    '소문보다 공개된 사실과 기업의 기초 체력을 먼저 확인해야 한다.',
    '단기 급등락 종목은 주문 가격과 수량을 나눠 접근할 필요가 있다.',
    '시장 전체의 방향과 보유 종목의 사정은 다를 수 있다는 점에 유의해야 한다.',
    '한 가지 재료만 보지 말고 실적·재무·수급을 함께 비교하는 것이 좋다.',
    '거래가 뜸한 종목은 원하는 가격에 체결되지 않을 수 있다.',
    '변동성이 큰 날일수록 현금 여력과 손실 한도를 먼저 점검해야 한다.',
    '과거 흐름은 참고 자료일 뿐 다음 가격을 보장하지 않는다.',
    '다음 거래일에도 같은 수급이 이어지는지 확인한 뒤 판단할 필요가 있다.',
  ];

  static const int theoreticalCombinationCount = 12 * 10 * 12 * 10 * 12 * 10;

  CombinatorialNewsArticle generate(NewsCombinatorInput input) {
    final variantId =
        _stableHash(
          '${input.simulationSeed}|${input.date}|${input.marketSummary}|'
          '${input.marketTheme}|${input.advancers}|${input.decliners}|'
          '${input.unchanged}|${input.marketClosed}',
        ) %
        theoreticalCombinationCount;
    var cursor = variantId;

    String choose(List<String> values) {
      final value = values[cursor % values.length];
      cursor ~/= values.length;
      return value;
    }

    final headlineLead = choose(_headlineLeads);
    final headlineFocus = choose(_headlineFocuses);
    final summaryIntroduction = choose(_summaryIntroductions);
    final themeBridge = choose(_themeBridges);
    final interpretation = choose(_interpretations);
    final caution = choose(_cautions);
    final sentiment = _sentimentFor(input);
    final toneLabel = switch (sentiment) {
      'POSITIVE' => '상승 우위',
      'NEGATIVE' => '하락 우위',
      _ => input.marketClosed ? '휴장' : '혼조',
    };

    return CombinatorialNewsArticle(
      headline: input.marketClosed
          ? '$headlineLead, 휴장 속 $headlineFocus'
          : '$headlineLead, $toneLabel 속 $headlineFocus',
      content:
          '$summaryIntroduction ${_sentence(input.marketSummary)} '
          '$themeBridge ${_sentence(input.marketTheme)} '
          '${interpretation.replaceAll('{tone}', toneLabel)} $caution',
      marketSentiment: sentiment,
      variantId: variantId,
    );
  }

  String _sentimentFor(NewsCombinatorInput input) {
    if (input.marketClosed || input.advancers == input.decliners) {
      return 'NEUTRAL';
    }
    final spread = input.advancers - input.decliners;
    final threshold = ((input.advancers + input.decliners) * 0.08).ceil();
    if (spread.abs() < threshold) return 'NEUTRAL';
    return spread > 0 ? 'POSITIVE' : 'NEGATIVE';
  }

  String _sentence(String value) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return '확인된 시장 자료가 많지 않다.';
    if (RegExp(r'[.!?]$').hasMatch(cleaned)) return cleaned;
    return '$cleaned.';
  }

  int _stableHash(String value) {
    var hash = 0x13579b;
    for (final unit in value.codeUnits) {
      hash = (hash + unit) & 0x7fffffff;
      hash = (hash + ((hash << 10) & 0x7fffffff)) & 0x7fffffff;
      hash ^= hash >> 6;
    }
    hash = (hash + ((hash << 3) & 0x7fffffff)) & 0x7fffffff;
    hash ^= hash >> 11;
    hash = (hash + ((hash << 15) & 0x7fffffff)) & 0x7fffffff;
    return hash & 0x7fffffff;
  }
}
