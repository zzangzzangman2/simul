import 'dynamic_news.dart';
import 'game_state.dart';
import 'market_data.dart';
import 'market_clock.dart';

export 'market_data.dart' show FictionalMarketEvent, NewsTone;

/// 조간신문은 전달이 끝난 전날 사건과 종가만 정리한다.
/// 오늘의 비공개 시나리오와 결과 방향은 이 계층에 전달하지 않는다.
List<FictionalMarketEvent> marketNewsEventsForState(
  GameState state, {
  DateTime? date,
}) => fictionalMarketEventsForDate(
  state.simulationSeed,
  date ?? state.currentDate,
);

/// 오늘 화면에 항상 채워 넣을 한 조각 소식.
class DailyBrief {
  const DailyBrief({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.marketClosed,
    required this.tone,
    this.headline,
    this.otherHeadlines = const [],
  });

  /// 가상 시장의 공개 사건이 걸린 날에만 채워진다.
  final FictionalMarketEvent? headline;
  final List<FictionalMarketEvent> otherHeadlines;
  final String eyebrow;
  final String title;
  final String body;
  final bool marketClosed;
  final NewsTone tone;

  bool get isBreaking => headline != null;
}

/// 움직이지 않는(양력 고정) 국내 휴장일만 이름으로 돌려준다. 음력 명절(설·추석)은
/// 해마다 날짜가 달라 여기서 다루지 않는다.
String? _fixedHoliday(DateTime date) {
  switch ((date.month, date.day)) {
    case (1, 1):
      return '신정';
    case (3, 1):
      return '삼일절';
    case (5, 5):
      return '어린이날';
    case (6, 6):
      return '현충일';
    case (8, 15):
      return '광복절';
    case (10, 3):
      return '개천절';
    case (12, 25):
      return '성탄절';
    default:
      return null;
  }
}

String _seasonTag(int month) {
  if (month == 12 || month <= 2) return '연초 시장';
  if (month <= 5) return '봄철 경제';
  if (month <= 8) return '여름 시장';
  return '연말 경제';
}

int _daySince2000(DateTime date) =>
    date.difference(DateTime(2000, 1, 1)).inDays;

/// 사건이 없는 평범한 날의 짧은 소식. (제목, 부연) 순서.
const List<(String, String)> _weekdayWinter = [
  ('연초 자금 흐름에 쏠린 시장의 눈', '증권가는 새해 자금이 어느 업종으로 향할지 차분히 살피고 있다.'),
  ('수출주와 내수주, 엇갈리는 기대', '환율과 소비 흐름에 따라 업종별 전망이 달라질 수 있다는 분석이다.'),
  ('금리 흐름 점검하는 채권·주식시장', '시장 참가자들은 기업의 자금조달 여건과 실적 전망을 함께 확인하고 있다.'),
  ('기업 실적 전망, 종목별 차별화 예고', '매출 성장뿐 아니라 부채와 현금흐름을 함께 봐야 한다는 목소리가 나온다.'),
  ('새해 투자계획 발표 앞둔 주요 기업', '설비투자와 연구개발 방향이 중장기 경쟁력을 가를 변수로 꼽힌다.'),
];

const List<(String, String)> _weekdaySpring = [
  ('연초 실적 윤곽에 관심 집중', '기업별 매출과 수익성의 차이가 주가 흐름을 가를 전망이다.'),
  ('소비 회복 여부에 유통업계 촉각', '가계 지출과 재고 흐름이 내수기업 실적의 주요 변수로 꼽힌다.'),
  ('수출기업, 환율과 해외수요 동시 점검', '업종마다 가격 경쟁력과 원재료 부담이 다르게 나타날 수 있다.'),
  ('주총철 맞은 기업들, 경영계획 공개', '시장에서는 배당보다 지속 가능한 이익과 투자계획을 함께 살피고 있다.'),
  ('고용과 물가 지표 기다리는 시장', '거시 지표가 금리 기대와 투자심리에 어떤 변화를 줄지 관심이 모인다.'),
];

const List<(String, String)> _weekdaySummer = [
  ('반기 실적 앞두고 관망세', '매출 증가가 실제 이익과 현금흐름으로 이어졌는지가 관심사다.'),
  ('원자재 가격 변화에 업종별 희비', '비용을 제품 가격에 반영할 수 있는 기업의 대응력이 주목된다.'),
  ('수출 경기와 운송 수요에 관심', '세계 경기 변화가 제조업과 물류기업에 미칠 영향을 시장이 점검하고 있다.'),
  ('기술주, 성장성과 수익성 사이 줄다리기', '신사업 기대만큼 실제 사업 성과를 확인해야 한다는 분석이 나온다.'),
  ('내수업계, 여름 소비 흐름 점검', '일시적 성수기 효과와 지속 가능한 수요를 구분해야 한다는 평가다.'),
];

const List<(String, String)> _weekdayFall = [
  ('연말 실적 전망 조정하는 증권가', '기업별 수주와 비용 변화가 연간 이익 눈높이를 바꾸고 있다.'),
  ('내년 투자계획 세우는 산업계', '설비 확대가 수요 전망과 재무 여력에 맞는지 검토가 이어진다.'),
  ('배당 기대보다 현금창출력에 주목', '일회성 이익을 제외한 본업의 경쟁력이 중요하다는 분석이다.'),
  ('세계 경기 변화에 수출주 변동성', '국가와 업종에 따라 수요 회복 속도가 다를 수 있다는 전망이 나온다.'),
  ('기관·외국인 수급에 시장 촉각', '단기 매매 흐름과 기업의 장기 가치를 구분할 필요가 있다는 평가다.'),
];

const List<(String, String)> _weekend = [
  ('주말, 국내 증시 휴장', '거래는 쉬지만 국내외 경제 일정과 다음 주 기업 발표에 관심이 이어지고 있다.'),
  ('시장 휴장, 다음 거래일 준비', '증권가는 주말 사이 나온 경제·산업 소식이 개장 후 미칠 영향을 점검한다.'),
  ('주말 경제 일정에 시선', '다음 주 금리·물가·기업 실적 일정이 투자심리의 변수가 될 전망이다.'),
  ('거래 멈춘 주말, 기업 뉴스는 계속', '시장 참가자들은 공시와 산업 동향을 확인하며 다음 장을 준비하고 있다.'),
  ('한 주 마감한 증권시장', '이번 주 업종별 흐름과 거래량을 돌아보며 다음 주 변수를 정리할 시점이다.'),
];

const _fallbackAngles = <String>[
  '현금흐름 재점검',
  '수주잔고 확인',
  '재고와 가동률 비교',
  '환율 민감도 분석',
  '차입금 만기 점검',
  '원재료 부담 추적',
  '신규 투자 효율 검토',
  '기관·개인 수급 비교',
];

const _fallbackLenses = <String>[
  '매출 증가가 실제 영업현금으로 이어지는지 확인할 필요가 있다.',
  '발표 규모보다 계약 조건과 인도 일정을 함께 살펴야 한다.',
  '단기 주가보다 재고 회전과 생산 가동률 변화가 먼저 나타날 수 있다.',
  '원화 가치 변화가 수출 가격과 원재료 비용에 서로 다르게 반영될 전망이다.',
  '투자 확대가 차입 부담을 넘어설 만큼 수익을 만드는지가 관건이다.',
  '같은 업종 안에서도 가격 전가력에 따라 이익 흐름이 엇갈릴 수 있다.',
  '신사업 기대와 기존 사업의 현금창출력을 분리해서 볼 필요가 있다.',
  '거래량 급증이 장기 자금인지 단기 추격 매수인지 구분해야 한다.',
];

/// 계절/요일에 맞는 결정론적 소식 하나를 고른다.
(String, String) _flavorFor(DateTime date, {required bool weekend}) {
  final day = _daySince2000(date);
  if (weekend) {
    return _weekend[day % _weekend.length];
  }
  final List<(String, String)> pool;
  final month = date.month;
  if (month == 12 || month <= 2) {
    pool = _weekdayWinter;
  } else if (month <= 5) {
    pool = _weekdaySpring;
  } else if (month <= 8) {
    pool = _weekdaySummer;
  } else {
    pool = _weekdayFall;
  }
  final base = pool[day % pool.length];
  final angle = _fallbackAngles[(day ~/ pool.length) % _fallbackAngles.length];
  final lens =
      _fallbackLenses[(day ~/ (pool.length * _fallbackAngles.length)) %
          _fallbackLenses.length];
  return ('${base.$1} · $angle', '${base.$2} $lens');
}

/// 오늘 날짜와 게임 상태로 소식 한 조각을 만든다. 우선순위:
/// 공개된 시장 사건 > 고정 휴장일 > 주말 > 계절별 경제·시장 소식.
DailyBrief buildDailyBrief(GameState state) {
  final date = state.currentDate;
  final weekend = date.weekday >= DateTime.saturday;
  final holiday = _fixedHoliday(date);
  final closed = !isMarketTradingDay(date);

  final events = marketNewsEventsForState(state);
  final event = events.isEmpty ? null : events.first;
  if (event != null) {
    return DailyBrief(
      headline: event,
      otherHeadlines: events.skip(1).toList(growable: false),
      eyebrow: event.eyebrow,
      title: event.title,
      body: event.signal,
      marketClosed: closed,
      tone: event.tone,
    );
  }

  if (holiday != null) {
    return DailyBrief(
      eyebrow: '$holiday · 휴장',
      title: '$holiday, 시장이 쉬어간다',
      body: '오늘은 거래가 없습니다. 달력에 표시해두고 다음 거래일을 기다립니다.',
      marketClosed: true,
      tone: NewsTone.holiday,
    );
  }
  if (closed) {
    final flavor = _flavorFor(date, weekend: weekend);
    return DailyBrief(
      eyebrow: weekend ? '주말' : '미래거래소 휴장',
      title: weekend ? flavor.$1 : '거래소가 쉬어가는 날',
      body: weekend ? flavor.$2 : '가상 거래소 달력에 거래가 없는 날입니다. 다음 거래일 일정을 확인합니다.',
      marketClosed: true,
      tone: weekend ? NewsTone.weekend : NewsTone.holiday,
    );
  }

  final flavor = _flavorFor(date, weekend: weekend);

  return DailyBrief(
    eyebrow: weekend ? '주말' : _seasonTag(date.month),
    title: flavor.$1,
    body: flavor.$2,
    marketClosed: closed,
    tone: weekend ? NewsTone.weekend : NewsTone.calm,
  );
}

class DailyMarketMover {
  const DailyMarketMover({required this.name, required this.changeRate});
  final String name;
  final double changeRate;
}

class DailyMarketNewspaper {
  const DailyMarketNewspaper({
    required this.date,
    required this.brief,
    required this.total,
    required this.advancers,
    required this.decliners,
    required this.unchanged,
    required this.topGainers,
    required this.topLosers,
    required this.headline,
    required this.summary,
    this.dynamicArticle,
  });
  final DateTime date;
  final DailyBrief brief;
  final int total;
  final int advancers;
  final int decliners;
  final int unchanged;
  final List<DailyMarketMover> topGainers;
  final List<DailyMarketMover> topLosers;
  final String headline;
  final String summary;
  final DynamicNewsArticle? dynamicArticle;

  DailyMarketNewspaper withDynamicArticle(DynamicNewsArticle? article) {
    if (article == null) return this;
    return DailyMarketNewspaper(
      date: date,
      brief: brief,
      total: total,
      advancers: advancers,
      decliners: decliners,
      unchanged: unchanged,
      topGainers: topGainers,
      topLosers: topLosers,
      headline: article.headline,
      summary: summary,
      dynamicArticle: article,
    );
  }
}

String _newsLimit(String value, int maxLength) => value.length <= maxLength
    ? value
    : '${value.substring(0, maxLength - 3)}...';

DynamicNewsRequest dynamicNewsRequestForState(
  GameState state,
  DailyBrief brief, {
  DailyMarketNewspaper? newspaper,
}) {
  final date = state.currentDate;
  final dateKey =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final extraEvents = brief.otherHeadlines
      .map((event) => event.title)
      .join(' · ');
  final megaTrend = brief.headline == null
      ? '${brief.eyebrow} · ${brief.title} · ${brief.body}'
      : '${brief.headline!.title} · ${brief.headline!.body}'
            '${extraEvents.isEmpty ? '' : ' · 그 외 소식: $extraEvents'}';

  String moverText(String label, List<DailyMarketMover> movers) {
    if (movers.isEmpty) return '';
    return '$label: ${movers.map((mover) => '${mover.name} ${mover.changeRate >= 0 ? '+' : ''}${mover.changeRate.toStringAsFixed(2)}%').join(', ')}.';
  }

  final marketSummary = newspaper == null
      ? brief.marketClosed
            ? '가상 증시는 휴장했다.'
            : '가상 증시는 정규 거래일을 마쳤다.'
      : [
          newspaper.summary,
          moverText('상승 상위', newspaper.topGainers),
          moverText('하락 상위', newspaper.topLosers),
        ].where((text) => text.isNotEmpty).join(' ');

  return DynamicNewsRequest(
    year: date.year,
    date: dateKey,
    marketSummary: _newsLimit(marketSummary, 700),
    megaTrend: _newsLimit(megaTrend, 300),
  );
}

Future<DailyMarketNewspaper> buildDailyMarketNewspaper(
  GameState state, {
  DynamicNewsArticle? dynamicArticle,
}) async {
  final brief = buildDailyBrief(state);
  final universe = await FictionalMarketUniverse.load(
    seed: state.simulationSeed,
  );
  final movers = <DailyMarketMover>[];
  for (final asset in universe.assets.where((asset) => asset.isDomestic)) {
    final quote = asset.quoteAtOrBefore(state.currentDate);
    if (quote == null || !quote.isExactDate) continue;
    final previous = asset.previousCloseBefore(quote.date);
    if (previous == null || previous <= 0) continue;
    movers.add(
      DailyMarketMover(
        name: asset.name,
        changeRate: (quote.close - previous) / previous * 100,
      ),
    );
  }
  movers.sort((left, right) => right.changeRate.compareTo(left.changeRate));
  final advancers = movers.where((mover) => mover.changeRate > 0.005).length;
  final decliners = movers.where((mover) => mover.changeRate < -0.005).length;
  final unchanged = movers.length - advancers - decliners;
  final topGainers = movers
      .where((mover) => mover.changeRate > 0)
      .take(3)
      .toList();
  final topLosers = movers.reversed
      .where((mover) => mover.changeRate < 0)
      .take(3)
      .toList();
  final headline =
      dynamicArticle?.headline ??
      brief.headline?.title ??
      (brief.marketClosed
          ? '가상 증시 휴장, 다음 거래일 일정 점검'
          : advancers >= decliners
          ? '가상 증시, 상승 종목이 더 많았다'
          : '가상 증시, 하락 종목 우세로 마감');
  final summary = movers.isEmpty
      ? '오늘 확인 가능한 가상 시장 종가가 없습니다. 휴장 여부와 다음 거래일 일정을 확인했습니다.'
      : '국내 ${movers.length}개 종목 중 상승 $advancers개, 하락 $decliners개, 보합 $unchanged개로 하루를 마쳤습니다.';
  return DailyMarketNewspaper(
    date: state.currentDate,
    brief: brief,
    total: movers.length,
    advancers: advancers,
    decliners: decliners,
    unchanged: unchanged,
    topGainers: topGainers,
    topLosers: topLosers,
    headline: headline,
    summary: summary,
    dynamicArticle: dynamicArticle,
  );
}
