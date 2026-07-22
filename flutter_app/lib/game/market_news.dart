import 'dynamic_news.dart';
import 'game_state.dart';
import 'historical_events.dart';
import 'market_data.dart';
import 'market_clock.dart';

export 'historical_events.dart';

/// 하루 넘김을 의미 있게 만드는 소식 시스템.
///
/// 두 층으로 구성한다.
///  1. [kHistoricalNews] (historical_events.dart) : 실제 날짜에 걸린 굵직한
///     역사 사건 400여 건. 랜딩하면 속보로 뜬다.
///  2. [buildDailyBrief] : 사건이 없는 평범한 날에도 달력·계절·주말/휴장·가족을
///     기반으로 짧은 소식을 만들어 빈 날이 없게 한다.
///
/// 규칙: 여기서는 가짜 시세를 만들지 않는다(DO_NOTS). 숫자 가격 대신 상황·분위기만
/// 전한다. 사건은 실제 발생일 당일에만 노출하며 미래를 미리 흘리지 않는다.

/// 오늘 날짜에 걸린 역사 사건을 돌려준다. 같은 날 여러 건이면 목록 순서(날짜→제목)의
/// 첫 사건을 준다.
List<HistoricalNewsEvent> historicalNewsEventsForDate(DateTime date) =>
    kHistoricalNews
        .where((event) => event.matches(date))
        .toList(growable: false);

HistoricalNewsEvent? historicalNewsForDate(DateTime date) {
  final events = historicalNewsEventsForDate(date);
  return events.isEmpty ? null : events.first;
}

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

  /// 굵직한 역사 사건이 걸린 날에만 채워진다.
  final HistoricalNewsEvent? headline;
  final List<HistoricalNewsEvent> otherHeadlines;
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
  if (month == 12 || month <= 2) return '겨울 아침';
  if (month <= 5) return '봄 볕';
  if (month <= 8) return '여름 한낮';
  return '가을 바람';
}

int _daySince2000(DateTime date) =>
    date.difference(DateTime(2000, 1, 1)).inDays;

/// 사건이 없는 평범한 날의 짧은 소식. (제목, 부연) 순서.
const List<(String, String)> _weekdayWinter = [
  ('창문에 성에가 낀 아침', '따뜻한 물 한 잔을 두고 어제 적어둔 조사노트를 다시 펼쳤다.'),
  ('라디오에서 증시 소식이 흘러나왔다', '아직은 낯선 이름들이지만 하나씩 귀에 익어간다.'),
  ('저금장부의 잔액을 확인했다', '숫자는 작지만, 어디서 왔는지 전부 적혀 있어 든든하다.'),
  ('학교 갔다 온 뒤 책상에 앉았다', '오늘 시장이 왜 움직였는지 이유를 한 줄로 적어보기로 했다.'),
  ('가족 투자연구소의 하루가 시작됐다', '조급해하지 말자던 첫날의 약속을 떠올린다.'),
];

const List<(String, String)> _weekdaySpring = [
  ('창밖으로 봄볕이 들어왔다', '따뜻해진 날씨만큼 시장에도 기대가 감돈다.'),
  ('오늘도 관심 종목을 살펴봤다', '가격보다 회사가 무엇을 파는지를 먼저 보기로 했다.'),
  ('조사노트에 질문 하나를 더 적었다', '‘이 회사는 5년 뒤에도 필요할까?’'),
  ('점심시간에도 신문 경제면을 넘겼다', '모르는 단어는 동그라미를 쳐두고 나중에 물어보기로.'),
  ('연구소 책상을 정리했다', '어제의 판단과 오늘의 판단을 나란히 붙여 두었다.'),
];

const List<(String, String)> _weekdaySummer = [
  ('매미 소리 속에 시장이 열렸다', '더위에도 숫자는 쉬지 않고 오르내린다.'),
  ('선풍기 앞에서 차트를 들여다봤다', '짧은 출렁임에 흔들리지 않는 연습을 한다.'),
  ('오늘의 등락 이유를 적어봤다', '이유를 모르겠으면 ‘모름’이라고 정직하게 적는다.'),
  ('방학 숙제 옆에 조사노트를 폈다', '공부와 투자, 둘 다 조금씩 밀리지 않게.'),
  ('가족이 저녁에 뭘 샀는지 물어봤다', '우리 집 소비가 곧 어떤 회사의 매출이라는 걸 배운다.'),
];

const List<(String, String)> _weekdayFall = [
  ('선선한 바람에 마음이 차분해졌다', '급하게 사고팔지 않아도 괜찮다고 스스로 다독인다.'),
  ('반년 치 조사노트를 다시 읽었다', '맞은 판단보다 틀린 판단에서 배울 게 많았다.'),
  ('시장은 오늘도 조용히 흘러갔다', '큰 사건이 없는 날일수록 원칙을 지키기 쉽다.'),
  ('용돈과 일거리 수입을 나눠 적었다', '쓸 돈과 조사 예산을 섞지 않기로 했다.'),
  ('창가에 앉아 국내·해외 종목을 비교했다', '같은 산업이라도 나라마다 분위기가 다르다.'),
];

const List<(String, String)> _weekend = [
  ('주말, 증시는 문을 닫았다', '쉬는 날엔 숫자 대신 가족과 시간을 보낸다.'),
  ('시장이 쉬는 날', '이번 주에 내가 왜 그렇게 판단했는지 되짚어 본다.'),
  ('느긋한 주말 아침', '급할 것 없다. 좋은 회사는 월요일에도 그 자리에 있다.'),
  ('가족과 함께한 하루', '외할아버지에게 조사노트를 보여드리고 이야기를 나눴다.'),
  ('주말엔 조사노트를 덮어두었다', '충분히 쉬어야 다음 주 판단이 흐려지지 않는다.'),
];

/// 계절/요일에 맞는 결정론적 소식 하나를 고른다.
(String, String) _flavorFor(DateTime date, {required bool weekend}) {
  if (weekend) {
    return _weekend[_daySince2000(date) % _weekend.length];
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
  return pool[_daySince2000(date) % pool.length];
}

/// 오늘 날짜와 게임 상태로 소식 한 조각을 만든다. 우선순위:
/// 역사 사건 > 고정 휴장일 > 주말 > 계절 소식. 시드머니 단계에는 살짝 다른 넛지를 준다.
DailyBrief buildDailyBrief(GameState state) {
  final date = state.currentDate;
  final weekend = date.weekday >= DateTime.saturday;
  final holiday = _fixedHoliday(date);
  final closed = !isMarketTradingDay(date);

  final events = historicalNewsEventsForDate(date);
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
    return DailyBrief(
      eyebrow: weekend ? '주말' : 'KRX 휴장',
      title: weekend ? '주말, 증시는 문을 닫았다' : '거래소가 쉬어가는 날',
      body: weekend
          ? '쉬는 날엔 숫자 대신 가족과 시간을 보내고 이번 주 판단을 되짚어 봅니다.'
          : '실제 국내 종가 달력에 거래가 없는 날입니다. 다음 거래일까지 조사노트를 정리합니다.',
      marketClosed: true,
      tone: weekend ? NewsTone.weekend : NewsTone.holiday,
    );
  }

  final flavor = _flavorFor(date, weekend: weekend);
  var title = flavor.$1;
  var body = flavor.$2;

  // 시드머니 단계(첫 조사예산 이전)에는 일거리 쪽으로 살짝 안내한다.
  if (!closed &&
      state.story.earnedSeedMoney < 10000 &&
      _daySince2000(date).isEven) {
    title = '아직 조사 예산이 부족하다';
    body = '방의 ‘일거리’로 설거지·문방구·벼룩장터를 하면 오늘도 종잣돈을 모을 수 있다.';
  }

  return DailyBrief(
    eyebrow: weekend ? '주말' : _seasonTag(date.month),
    title: title,
    body: body,
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
}

String _newsLimit(String value, int maxLength) => value.length <= maxLength
    ? value
    : '${value.substring(0, maxLength - 3)}...';

DynamicNewsRequest dynamicNewsRequestForState(
  GameState state,
  DailyBrief brief,
) {
  DecisionCardData? latestDecision;
  for (final decision in state.decisions.reversed) {
    if (decision.status == DecisionStatus.resolved) {
      latestDecision = decision;
      break;
    }
  }

  DecisionOptionData? selectedOption;
  if (latestDecision?.selectedOptionId != null) {
    for (final option in latestDecision!.options) {
      if (option.id == latestDecision.selectedOptionId) {
        selectedOption = option;
        break;
      }
    }
  }

  LedgerEntry? todayLedger;
  for (final entry in state.ledger.reversed) {
    if (entry.day == state.day) {
      todayLedger = entry;
      break;
    }
  }

  final action = todayLedger != null
      ? todayLedger.description
      : latestDecision != null && selectedOption != null
      ? '${latestDecision.title}에서 “${selectedOption.label}”을 선택함. ${selectedOption.description}'
      : '가족 투자연구소에서 시장 시세와 기업 조사노트를 검토함';
  final isCompanyDecision =
      latestDecision != null && latestDecision.id != 'first-research-note';
  final companyName = isCompanyDecision
      ? state.company.name
      : (state.companyName.trim().isEmpty ? '가족 투자연구소' : state.companyName);
  final extraEvents = brief.otherHeadlines
      .map((event) => event.title)
      .join(' · ');
  final megaTrend = brief.headline == null
      ? '${brief.eyebrow} · ${brief.title}'
      : '${brief.headline!.title} · ${brief.headline!.body}'
            '${extraEvents.isEmpty ? '' : ' · 그 외 소식: $extraEvents'}';

  return DynamicNewsRequest(
    year: state.currentDate.year,
    companyName: _newsLimit(companyName, 100),
    action: _newsLimit(action, 500),
    megaTrend: _newsLimit(megaTrend, 300),
  );
}

Future<DailyMarketNewspaper> buildDailyMarketNewspaper(
  GameState state, {
  DynamicNewsArticle? dynamicArticle,
}) async {
  final brief = buildDailyBrief(state);
  final universe = await HistoricalMarketUniverse.load();
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
          ? '오늘 증시는 휴장, 가족 투자연구소는 숨 고르기'
          : advancers >= decliners
          ? '국내 증시, 상승 종목이 더 많았다'
          : '국내 증시, 하락 종목 우세로 마감');
  final summary = movers.isEmpty
      ? '오늘 확인 가능한 국내 종가가 없습니다. 시장은 쉬고, 조사노트만 차분히 정리했습니다.'
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
