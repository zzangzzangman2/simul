import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/news_combinator.dart';

void main() {
  const combinator = NewsCombinator();
  const baseInput = NewsCombinatorInput(
    simulationSeed: '20000101',
    year: 2007,
    date: '2007-06-29',
    marketSummary: '국내 212개 종목 중 상승 112개, 하락 88개, 보합 12개로 마감했다.',
    marketTheme: '수출주 실적과 원자재 가격 변화가 투자자 관심을 모았다.',
    marketClosed: false,
    advancers: 112,
    decliners: 88,
    unchanged: 12,
  );

  test('문장 조합 수가 수만 가지를 충분히 넘는다', () {
    expect(NewsCombinator.theoreticalCombinationCount, greaterThan(100000));
  });

  test('같은 시드와 공개 정보는 항상 같은 기사를 만든다', () {
    final first = combinator.generate(baseInput);
    final second = combinator.generate(baseInput);

    expect(second.headline, first.headline);
    expect(second.content, first.content);
    expect(second.variantId, first.variantId);
    expect(first.marketSentiment, 'POSITIVE');
    expect(first.content, contains(baseInput.marketSummary));
    expect(first.content, contains(baseInput.marketTheme));
  });

  test('서로 다른 시드는 넓은 범위의 기사 조합을 사용한다', () {
    final variants = <int>{};
    for (var seed = 1; seed <= 2000; seed++) {
      variants.add(
        combinator
            .generate(
              NewsCombinatorInput(
                simulationSeed: '$seed',
                year: baseInput.year,
                date: baseInput.date,
                marketSummary: baseInput.marketSummary,
                marketTheme: baseInput.marketTheme,
                marketClosed: baseInput.marketClosed,
                advancers: baseInput.advancers,
                decliners: baseInput.decliners,
                unchanged: baseInput.unchanged,
              ),
            )
            .variantId,
      );
    }

    expect(variants.length, greaterThan(1900));
  });

  test('휴장과 상승·하락 종목 수만으로 시장 흐름을 판정한다', () {
    CombinatorialNewsArticle generate({
      required bool closed,
      required int advancers,
      required int decliners,
    }) => combinator.generate(
      NewsCombinatorInput(
        simulationSeed: baseInput.simulationSeed,
        year: baseInput.year,
        date: baseInput.date,
        marketSummary: baseInput.marketSummary,
        marketTheme: baseInput.marketTheme,
        marketClosed: closed,
        advancers: advancers,
        decliners: decliners,
        unchanged: 0,
      ),
    );

    expect(
      generate(closed: true, advancers: 200, decliners: 1).marketSentiment,
      'NEUTRAL',
    );
    expect(
      generate(closed: false, advancers: 20, decliners: 100).marketSentiment,
      'NEGATIVE',
    );
  });
}
