part of 'market_data.dart';

class _FictionalCorpusDailySample {
  const _FictionalCorpusDailySample({
    required this.largeReturn,
    required this.growthReturn,
    required this.largeRange,
    required this.growthRange,
    required this.largeGap,
    required this.growthGap,
    required this.largeVolatility,
    required this.growthVolatility,
  });

  final double largeReturn;
  final double growthReturn;
  final double largeRange;
  final double growthRange;
  final double largeGap;
  final double growthGap;
  final double largeVolatility;
  final double growthVolatility;
}

class _FictionalCorpusNarrative {
  const _FictionalCorpusNarrative({
    required this.id,
    required this.channel,
    required this.title,
    required this.body,
    required this.signal,
    this.prefersPositive,
  });

  final String id;
  final String channel;
  final String title;
  final String body;
  final String signal;
  final bool? prefersPositive;
}

/// 타임라인의 16개 충격 템플릿을 실명 없는 가상세계 문장으로 바꾼다.
const _fictionalCorpusNarratives = <_FictionalCorpusNarrative>[
  _FictionalCorpusNarrative(
    id: 'global_technology_selloff',
    channel: 'technology',
    title: '세계 기술주 급락, 성장기업 할인율 재평가',
    body: '해외 선행시장의 기술주 매도가 반도체·인터넷·바이오 기업의 자금조달 기대까지 흔들었다.',
    signal: '매출 성장률과 현금소진 속도, 차입 만기를 함께 확인해야 합니다.',
    prefersPositive: false,
  ),
  _FictionalCorpusNarrative(
    id: 'unexpected_rate_cut',
    channel: 'rates',
    title: '예상 밖 기준금리 인하, 유동성과 침체 신호 충돌',
    body: '중앙통화위원회의 완화 조치가 할인율을 낮췄지만 경기 둔화가 예상보다 깊다는 해석도 나왔다.',
    signal: '금리 방향보다 인하 이유와 실제 신용 공급을 확인해야 합니다.',
    prefersPositive: true,
  ),
  _FictionalCorpusNarrative(
    id: 'unexpected_rate_hike',
    channel: 'rates',
    title: '예상 밖 기준금리 인상, 차입비용 부담 확대',
    body: '물가와 과열을 막기 위한 긴축으로 성장주·부동산·증권 업종의 자금비용이 높아졌다.',
    signal: '부채 만기와 이자보상 능력, 은행의 신용비용을 나눠 봐야 합니다.',
    prefersPositive: false,
  ),
  _FictionalCorpusNarrative(
    id: 'border_tension',
    channel: 'geopolitics',
    title: '북방 국경 긴장 고조, 환율·운송시장 경계',
    body: '군사적 긴장이 높아지며 위험자금이 빠지고 방산·보안 수요 기대가 커졌다.',
    signal: '반복 경보와 실제 생산·교역 차질을 구분해야 합니다.',
    prefersPositive: false,
  ),
  _FictionalCorpusNarrative(
    id: 'military_conflict',
    channel: 'geopolitics',
    title: '국지 충돌 발생, 금융·물류 안전장치 가동',
    body: '실제 충돌로 외환과 운송 보험료가 급변하고 시장 안정조치 가능성이 제기됐다.',
    signal: '충돌 범위, 지속 기간, 항로와 생산시설 피해를 우선 확인해야 합니다.',
    prefersPositive: false,
  ),
  _FictionalCorpusNarrative(
    id: 'oil_price_shock',
    channel: 'commodity',
    title: '에너지 가격 급변, 업종별 원가와 판매가 엇갈려',
    body: '연료·원료 가격 변화가 정유와 자원기업, 항공·운송·화학·전력기업에 서로 다른 충격을 줬다.',
    signal: '재고, 헤지, 판매가격 전가 시차를 함께 확인해야 합니다.',
  ),
  _FictionalCorpusNarrative(
    id: 'semiconductor_upcycle',
    channel: 'technology',
    title: '메모리 주문 회복, 반도체 공급망 동반 강세',
    body: '재고 감소와 서버·PC 수요 회복 신호가 칩·장비·소재 기업의 신규 주문으로 번졌다.',
    signal: '현물가격보다 재고일수와 장기계약 물량을 확인해야 합니다.',
    prefersPositive: true,
  ),
  _FictionalCorpusNarrative(
    id: 'semiconductor_peak',
    channel: 'technology',
    title: '반도체 주문 둔화, 장비·소재부터 조정',
    body: '고객 재고와 설비투자 계획이 꺾이며 대형 칩기업보다 장비·소재 주문이 먼저 줄었다.',
    signal: '출하량, 재고평가손실, 설비 취소 순서를 확인해야 합니다.',
    prefersPositive: false,
  ),
  _FictionalCorpusNarrative(
    id: 'short_sale_ban',
    channel: 'market_structure',
    title: '공매도 긴급 제한, 단기 환매수 집중',
    body: '시장 안정조치 직후 빌린 주식을 되사는 주문이 몰렸지만 기업 실적은 바뀌지 않았다.',
    signal: '첫날 반등과 2~20거래일 뒤 가치 회귀를 구분해야 합니다.',
    prefersPositive: true,
  ),
  _FictionalCorpusNarrative(
    id: 'short_sale_resume',
    channel: 'market_structure',
    title: '공매도 재개, 고평가·적자 성장주 변동 확대',
    body: '거래제도 정상화와 함께 과열 종목에 매도가 집중되고 유동성은 업종별로 갈렸다.',
    signal: '지수보다 신용잔고와 밸류에이션이 높은 종목을 따로 봐야 합니다.',
    prefersPositive: false,
  ),
  _FictionalCorpusNarrative(
    id: 'political_crisis',
    channel: 'geopolitics',
    title: '대형 정치 불확실성, 외환시장 선행 반응',
    body: '정책 공백 우려로 원화와 외국계 수급이 먼저 흔들리고 시장 안정책 발표 여부가 쟁점이 됐다.',
    signal: '정치 뉴스 자체보다 정책 집행과 자금 이탈의 지속성을 봐야 합니다.',
    prefersPositive: false,
  ),
  _FictionalCorpusNarrative(
    id: 'pandemic_rotation',
    channel: 'pandemic',
    title: '신종 감염병 확산, 이동·소비·방역 수요 재편',
    body: '항공·여행·오프라인 소비가 위축되는 한편 진단·의약·온라인 서비스 수요가 급증했다.',
    signal: '확산률과 이동 제한, 생산능력, 수요 정상화 속도를 함께 봐야 합니다.',
    prefersPositive: false,
  ),
  _FictionalCorpusNarrative(
    id: 'credit_freeze',
    channel: 'credit',
    title: '프로젝트금융·회사채 경색, 차환 위험 확산',
    body: '담보가치 하락과 단기자금 회수가 증권·건설·보험·중소형 기업의 유동성 문제로 번졌다.',
    signal: '이익보다 현금, 담보, 보증, 만기구조를 먼저 확인해야 합니다.',
    prefersPositive: false,
  ),
  _FictionalCorpusNarrative(
    id: 'inflation_surprise',
    channel: 'currency',
    title: '물가 상방 충격, 금리·달러·원화 연쇄 변동',
    body: '예상보다 높은 물가가 해외 금리와 달러를 끌어올려 수입원가와 성장주 할인율을 동시에 압박했다.',
    signal: '환율 수혜 매출과 외화부채·수입원가를 같은 표에서 비교해야 합니다.',
    prefersPositive: false,
  ),
  _FictionalCorpusNarrative(
    id: 'trade_stimulus',
    channel: 'trade',
    title: '대륙권 경기부양 발표, 수출·소재 주문 기대',
    body: '인프라와 소비 부양책이 철강·화학·기계·화장품·상사 업종의 주문 기대를 높였다.',
    signal: '정책 발표 뒤 실제 신용과 소비·수입 지표가 따라오는지 확인해야 합니다.',
    prefersPositive: true,
  ),
  _FictionalCorpusNarrative(
    id: 'leveraged_liquidation',
    channel: 'market_structure',
    title: '레버리지 과열 청산, 지수 집중 종목 급변',
    body: '추종매수와 신용이 한쪽에 몰린 뒤 담보 부족과 자동주문이 비선형 매도를 만들었다.',
    signal: '기업가치 변화와 강제매도·얕은 호가가 만든 가격 왜곡을 분리해야 합니다.',
    prefersPositive: false,
  ),
];

_FictionalCorpusDailySample _fictionalCorpusDailySampleForDate(
  String seed,
  DateTime date,
) {
  final sampleCount =
      fictionalCorpusDailySamples.length ~/ fictionalCorpusDailySampleStride;
  const blockLength = 42;
  final elapsed = math.max(0, date.difference(DateTime(2000, 1, 1)).inDays);
  final block = elapsed ~/ blockLength;
  final localDay = elapsed % blockLength;
  final availableStarts = math.max(1, sampleCount - blockLength);
  final start =
      _fictionalHash('$seed:corpus-daily-block:$block') % availableStarts;
  final sampleIndex = (start + localDay) % sampleCount;
  final offset = sampleIndex * fictionalCorpusDailySampleStride;
  double rate(int field) => fictionalCorpusDailySamples[offset + field] / 10000;
  return _FictionalCorpusDailySample(
    largeReturn: rate(0),
    growthReturn: rate(1),
    largeRange: rate(2),
    growthRange: rate(3),
    largeGap: rate(4),
    growthGap: rate(5),
    largeVolatility: rate(6),
    growthVolatility: rate(7),
  );
}

_FictionalCorpusNarrative _fictionalCorpusNarrativeFor(
  String seed,
  String planId,
  FictionalCorpusEventPattern pattern,
) {
  final averageDirection = pattern.largeDailyBps + pattern.growthDailyBps >= 0;
  var candidates = _fictionalCorpusNarratives
      .where(
        (narrative) =>
            narrative.channel == pattern.channel &&
            (narrative.prefersPositive == null ||
                narrative.prefersPositive == averageDirection),
      )
      .toList(growable: false);
  if (candidates.isEmpty) {
    candidates = _fictionalCorpusNarratives
        .where((narrative) => narrative.channel == pattern.channel)
        .toList(growable: false);
  }
  if (candidates.isEmpty) {
    candidates = const [
      _FictionalCorpusNarrative(
        id: 'demand_cycle',
        channel: 'demand',
        title: '세계 수요 전망 변화, 업종별 주문 재평가',
        body: '수출과 내수 주문이 기존 예상에서 벗어나며 재고와 설비계획이 조정됐다.',
        signal: '지수 방향보다 기업별 주문·재고·현금흐름을 확인해야 합니다.',
      ),
    ];
  }
  return candidates[_fictionalHash('$seed:$planId:narrative') %
      candidates.length];
}

Map<String, double> _fictionalCorpusSectorImpacts(
  String channel,
  double marketImpact,
) {
  final same = marketImpact.abs().clamp(0.004, 0.055).toDouble();
  final direction = marketImpact < 0 ? -1.0 : 1.0;
  final aligned = same * direction;
  final opposite = -aligned;
  return switch (channel) {
    'technology' => {
      '반도체': aligned * 0.85,
      '반도체장비': aligned * 0.8,
      '인터넷': aligned * 0.7,
      '소프트웨어': aligned * 0.65,
      '첨단소재': aligned * 0.5,
      '바이오': aligned * 0.45,
    },
    'rates' => {
      '증권': aligned * 0.75,
      '건설': aligned * 0.65,
      '인터넷': aligned * 0.55,
      '금융': opposite * 0.25,
      '보험': opposite * 0.2,
    },
    'currency' => {
      '종합상사': opposite * 0.75,
      '자동차': opposite * 0.55,
      '전자·가전': opposite * 0.5,
      '항공운송': aligned * 0.75,
      '화학·소재': aligned * 0.45,
    },
    'commodity' => {
      '정유': opposite * 0.95,
      '자원개발': opposite * 0.85,
      '에너지': opposite * 0.6,
      '항공운송': aligned * 0.9,
      '물류': aligned * 0.55,
      '화학·소재': aligned * 0.55,
      '전력·유틸리티': aligned * 0.45,
    },
    'credit' => {
      '금융': aligned * 0.9,
      '증권': aligned * 0.95,
      '보험': aligned * 0.65,
      '소비자금융': aligned * 0.9,
      '건설': aligned * 0.8,
      '건자재': aligned * 0.55,
    },
    'trade' => {
      '철강': aligned * 0.8,
      '조선·기계': aligned * 0.65,
      '화학·소재': aligned * 0.65,
      '종합상사': aligned * 0.75,
      '화장품': aligned * 0.55,
      '해운': aligned * 0.5,
    },
    'pandemic' => {
      '항공운송': aligned * 1.05,
      '호텔·여행': aligned,
      '레저': aligned * 0.85,
      '유통': aligned * 0.6,
      '바이오': opposite * 0.9,
      '제약': opposite * 0.8,
      '의료기기': opposite * 0.7,
      '인터넷': opposite * 0.45,
    },
    'disaster' => {
      '항공운송': aligned * 0.7,
      '해운': aligned * 0.55,
      '보험': aligned * 0.65,
      '건설': opposite * 0.45,
      '환경': opposite * 0.55,
      '건자재': opposite * 0.4,
    },
    'geopolitics' => {
      '항공운송': aligned * 0.65,
      '해운': aligned * 0.55,
      '방산': opposite * 0.95,
      '정보보안': opposite * 0.55,
      '에너지': opposite * 0.35,
    },
    'market_structure' => {
      '증권': aligned * 0.95,
      '인터넷': aligned * 0.55,
      '바이오': aligned * 0.5,
      '게임': aligned * 0.5,
    },
    'environment' => {
      '환경': opposite * 0.9,
      '전지': opposite * 0.55,
      '전력기기': opposite * 0.5,
      '정유': aligned * 0.6,
      '화학·소재': aligned * 0.4,
    },
    'corporate' => {
      '금융': aligned * 0.45,
      '증권': aligned * 0.5,
      '소비자금융': aligned * 0.45,
    },
    _ => <String, double>{},
  };
}

double _fictionalCorpusPatternImpact(
  FictionalCorpusEventPattern pattern,
  int stage,
  double strength,
) {
  final large = switch (stage) {
    0 => pattern.largeDailyBps,
    1 => pattern.large5Bps - pattern.largeDailyBps,
    _ => pattern.large20Bps - pattern.large5Bps,
  };
  final growth = switch (stage) {
    0 => pattern.growthDailyBps,
    1 => pattern.growth5Bps - pattern.growthDailyBps,
    _ => pattern.growth20Bps - pattern.growth5Bps,
  };
  final average = (large + growth) / 2 / 10000;
  final stageScale = <double>[0.42, 0.16, 0.09][stage];
  final stageLimit = <double>[0.055, 0.035, 0.025][stage];
  return (average * stageScale * strength)
      .clamp(-stageLimit, stageLimit)
      .toDouble();
}

List<FictionalMarketEvent> _corpusScenarioEventsForDate(
  String seed,
  DateTime date,
) {
  if (date.year < fictionalCampaignStartYear ||
      date.year > fictionalCampaignEndYear) {
    return const [];
  }
  final dateKey = marketDateKey(date);
  final events = <FictionalMarketEvent>[];
  const stageOffsets = <int>[0, 5, 21];
  for (final planYear in <int>[date.year - 1, date.year]) {
    if (planYear < fictionalCampaignStartYear ||
        planYear > fictionalCampaignEndYear) {
      continue;
    }
    for (var month = 1; month <= 12; month++) {
      final planId = '$planYear-${month.toString().padLeft(2, '0')}';
      final day = 2 + _fictionalHash('$seed:corpus-event-day:$planId') % 20;
      final startDate = DateTime(planYear, month, day);
      final pattern =
          fictionalCorpusEventPatterns[_fictionalHash(
                '$seed:corpus-event-pattern:$planId',
              ) %
              fictionalCorpusEventPatterns.length];
      final strength =
          (0.76 + _fictionalUnit(seed, 'corpus-event-strength:$planId') * 0.4) *
          (0.84 + pattern.confidence * 0.06);
      final narrative = _fictionalCorpusNarrativeFor(seed, planId, pattern);
      for (var stage = 0; stage < stageOffsets.length; stage++) {
        final stageDate = _nextFictionalTradingDay(
          startDate.add(Duration(days: stageOffsets[stage])),
        );
        if (marketDateKey(stageDate) != dateKey) continue;
        final impact = _fictionalCorpusPatternImpact(pattern, stage, strength);
        final positive = impact >= 0;
        final title = switch (stage) {
          0 => narrative.title,
          1 => '${narrative.title}, ${positive ? '정책·수급 반응 확인' : '후속 변동성 지속'}',
          _ => '${narrative.title}, ${positive ? '실물 지표 안정' : '실적·신용 여파 점검'}',
        };
        final body = switch (stage) {
          0 => narrative.body,
          1 => '첫 충격 뒤 환율·금리·외국계 수급과 업종 회전이 이어졌다. 초기 방향이 유지되는지는 아직 확정되지 않았다.',
          _ => '기업 주문·재고·차입 조건에 후속 영향이 나타났다. 시장 전체 움직임과 회사별 대응 성과가 갈리기 시작했다.',
        };
        events.add(
          FictionalMarketEvent(
            id: 'corpus-${narrative.id}-$planId-$stage',
            date: dateKey,
            companyId: fictionalWholeMarketCompanyId,
            companyName: '시장 전체',
            sector: '전체시장',
            stage: stage,
            eyebrow: '시드형 시장 충격',
            title: title,
            body: body,
            signal: narrative.signal,
            reportHint: stage == 0
                ? '해외 선행시장·환율·금리·원자재·수급과 업종별 민감도를 함께 확인해야 한다.'
                : '초기 충격 뒤 거래대금·변동성·신용잔고와 기업별 주문 변화가 갈리고 있다.',
            revealMinute:
                8 * 60 +
                10 +
                _fictionalHash('$seed:corpus-event-reveal:$planId:$stage') %
                    430,
            impactPct: impact,
            sectorImpactPcts: _fictionalCorpusSectorImpacts(
              pattern.channel,
              impact,
            ),
            tone: impact < 0
                ? NewsTone.shock
                : stage == 0
                ? NewsTone.breaking
                : NewsTone.milestone,
          ),
        );
      }
    }
  }
  return events;
}
