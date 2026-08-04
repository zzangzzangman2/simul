import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/cohort_briefing.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_data.dart';
import 'package:millennium_capital/game/relationship_state.dart';

import 'support/market_fixture.dart';

void main() {
  const engine = GameEngine();

  test('rotation covers all eight girls exactly once', () {
    expect(cohortBriefingRotation, hasLength(8));
    final ids = cohortBriefingRotation
        .map((definition) => definition.girlId)
        .toList(growable: false);
    expect(ids.toSet(), hasLength(8));
    for (final id in ids) {
      expect(
        cohortGirlProfileById(id),
        isNotNull,
        reason: '$id는 관계 정본에 없는 인물이다',
      );
      expect(cohortBriefingByGirlId(id)?.girlId, id);
    }
    // 남자 동기와 운영관은 이 로테이션에 들어가지 않는다.
    expect(ids, isNot(contains('kim_hakjun')));
  });

  test('every briefing offers a respect choice and a research choice', () {
    for (final definition in cohortBriefingRotation) {
      expect(definition.choices, hasLength(2));
      expect(definition.ability, isNotEmpty);
      expect(definition.headline, isNotEmpty);
      expect(definition.fallbackObservation, isNotEmpty);
      final rewards = definition.choices.map((choice) => choice.reward).toSet();
      expect(rewards, <CohortBriefingReward>{
        CohortBriefingReward.respect,
        CohortBriefingReward.researchCredit,
      }, reason: '${definition.name} 브리핑에 관계와 실익 선택이 모두 있어야 한다');
      for (final choice in definition.choices) {
        expect(definition.choiceById(choice.id)?.id, choice.id);
      }
    }
  });

  test('eight consecutive weekdays hand the briefing to eight people', () {
    final start = DateTime(2000, 1, 3);
    final seen = <String>[];
    var date = start;
    while (seen.length < 8) {
      if (date.weekday <= DateTime.friday) {
        final ordinal = cohortBriefingWeekdayOrdinal(start, date);
        seen.add(
          cohortBriefingRotation[ordinal % cohortBriefingRotation.length]
              .girlId,
        );
      }
      date = date.add(const Duration(days: 1));
    }

    // 월·화·수·목·금을 가로질러 여덟 명이 한 바퀴 돈다.
    expect(seen.toSet(), hasLength(8));
    expect(seen.first, cohortBriefingRotation.first.girlId);
  });

  test('weekday ordinal ignores weekends', () {
    final start = DateTime(2000, 1, 3);
    expect(cohortBriefingWeekdayOrdinal(start, start), 0);
    expect(cohortBriefingWeekdayOrdinal(start, DateTime(2000, 1, 4)), 1);
    expect(cohortBriefingWeekdayOrdinal(start, DateTime(2000, 1, 7)), 4);
    // 1월 8·9일은 주말이므로 순번을 소비하지 않는다.
    expect(cohortBriefingWeekdayOrdinal(start, DateTime(2000, 1, 10)), 5);
    expect(cohortBriefingWeekdayOrdinal(start, DateTime(2000, 1, 11)), 6);
  });

  test('weekends and closed days do not open a briefing', () {
    var state = engine.createNewGame('브리핑 테스트', worldSeed: 'briefing-1');
    for (var day = 1; day <= 40; day += 1) {
      final probe = state.copyWith(day: day);
      final briefing = cohortBriefingForState(probe);
      final date = probe.currentDate;
      if (date.weekday > DateTime.friday || !isMarketTradingDay(date)) {
        expect(briefing, isNull, reason: '$date는 브리핑이 열리지 않아야 한다');
      } else {
        expect(briefing, isNotNull, reason: '$date에 담당자가 없다');
      }
    }
  });

  test('same state always resolves the same briefing owner', () {
    final state = engine
        .createNewGame('브리핑 결정론', worldSeed: 'briefing-2')
        .copyWith(day: 4);
    final first = cohortBriefingForState(state);
    final second = cohortBriefingForState(state);
    expect(first?.girlId, second?.girlId);
    expect(first, isNotNull);
  });

  test('briefing log round trips and guards one per day', () {
    const log = CohortBriefingLog(
      day: 4,
      girlId: 'jung_arin',
      choiceId: 'arin_write_exit',
      reward: CohortBriefingReward.respect,
    );
    final restored = CohortBriefingLog.fromJson(log.toJson());
    expect(restored.day, 4);
    expect(restored.girlId, 'jung_arin');
    expect(restored.choiceId, 'arin_write_exit');
    expect(restored.reward, CohortBriefingReward.respect);

    var state = engine.createNewGame('브리핑 기록', worldSeed: 'briefing-3');
    expect(cohortBriefingCompletedForDay(state, 4), isFalse);
    state = state.copyWith(
      story: state.story.copyWith(
        storyFlags: <String, dynamic>{
          ...state.story.storyFlags,
          cohortBriefingLogFlag: <dynamic>[log.toJson()],
        },
      ),
    );
    expect(cohortBriefingLogsForState(state), hasLength(1));
    expect(cohortBriefingCompletedForDay(state, 4), isTrue);
    expect(cohortBriefingCompletedForDay(state, 5), isFalse);
  });

  test('briefing reads the real market and never today close', () {
    final state = engine
        .createNewGame('브리핑 시장', worldSeed: 'briefing-market')
        .copyWith(day: 4);
    // 08:00 브리핑은 직전 거래일까지만 읽는다. 오늘 종가는 입력이 아니다.
    final asOf = cohortBriefingPublicThrough(state.currentDate);
    expect(asOf.isBefore(state.currentDate), isTrue);
    expect(isMarketTradingDay(asOf), isTrue);

    final universe = testMarketUniverse(tradingDate: state.currentDate);
    final briefing = buildCohortBriefing(state, universe: universe);
    expect(briefing, isNotNull);
    expect(briefing!.observation, isNotEmpty);
    expect(briefing.name, briefing.definition.name);
  });

  test('each girl produces her own market sentence for the same day', () {
    var state = engine
        .createNewGame('브리핑 인물별', worldSeed: 'briefing-voices')
        .copyWith(day: 4);
    final universe = testMarketUniverse(
      tradingDate: state.currentDate,
      closeOverride: 6600,
    );
    // 결과표가 있어야 하은의 정보망 브리핑이 실제 수치를 읽는다.
    state = engine
        .settleCohortInvestmentDay(
          state.copyWith(marketMinute: krxCloseMinute),
          universe: universe,
        )
        .state;

    final sentences = <String, String>{};
    for (final definition in cohortBriefingRotation) {
      // 같은 날짜를 고정한 채 담당만 바꿔 인물별 문장을 확인한다.
      final ordinal = cohortBriefingRotation.indexOf(definition);
      final probe = state.copyWith(day: 4 + ordinal * 0);
      final briefing = buildCohortBriefing(probe, universe: universe);
      expect(briefing, isNotNull);
      sentences[definition.girlId] = _sentenceFor(definition, probe, universe);
    }

    // 여덟 명이 서로 다른 관찰을 내놓아야 한다.
    expect(sentences.values.toSet().length, sentences.length);
    for (final entry in sentences.entries) {
      expect(entry.value, isNotEmpty, reason: '${entry.key} 문장이 비었다');
    }

    // 기본 문장이 아니라 실제 시장에서 만들어진 문장이 대부분이어야 한다.
    final generated = sentences.entries
        .where((entry) {
          final fallback = cohortBriefingByGirlId(
            entry.key,
          )!.fallbackObservation;
          return entry.value != fallback;
        })
        .toList(growable: false);
    expect(
      generated.length,
      greaterThanOrEqualTo(5),
      reason:
          '시장 데이터로 생성된 브리핑이 ${generated.length}개뿐이다: '
          '${sentences.keys.where((id) => sentences[id] == cohortBriefingByGirlId(id)!.fallbackObservation).toList()}',
    );
    // 종목 이름이나 실제 수치가 들어간 문장이 있어야 한다.
    expect(sentences.values.where((line) => line.contains('한빛통신')), isNotEmpty);
    expect(sentences.values.where((line) => line.contains('%')), isNotEmpty);
  });

  test('market sentences change when the account changes', () {
    final base = engine
        .createNewGame('브리핑 계좌반응', worldSeed: 'briefing-account')
        .copyWith(day: 4);
    // 아린 차례는 첫 거래일이므로 그 직전 종가까지 들어 있는 기본 픽스처를 쓴다.
    final universe = testMarketUniverse();
    final arin = cohortBriefingByGirlId('jung_arin')!;

    final empty = _sentenceFor(arin, base, universe);
    final holding = _sentenceFor(
      arin,
      base.copyWith(
        positions: <PortfolioPosition>[
          PortfolioPosition(
            assetId: 'hanbit_telecom',
            symbol: '1001',
            name: '한빛통신',
            market: fictionalMainMarket,
            currency: 'KRW',
            units: 5,
            totalCost: 30200,
          ),
        ],
      ),
      universe,
    );

    // 보유가 없을 때와 있을 때 아린의 문장이 달라야 한다.
    expect(empty, isNot(holding));
    expect(holding, contains('한빛통신'));
    expect(holding, contains('주'));
  });
}

/// 특정 인물의 브리핑 문장만 뽑는다. 로테이션 순번과 무관하게 생성기를 직접 확인한다.
String _sentenceFor(
  CohortBriefingDefinition definition,
  GameState state,
  FictionalMarketUniverse universe,
) {
  final index = cohortBriefingRotation.indexOf(definition);
  final start = state.dateForDay(1);
  // 담당이 definition이 되는 첫 평일까지 날짜를 밀어 본다.
  for (var day = 1; day <= 400; day += 1) {
    final probe = state.copyWith(day: day);
    final owner = cohortBriefingForState(probe);
    if (owner == null) continue;
    final ordinal = cohortBriefingWeekdayOrdinal(start, probe.currentDate);
    if (ordinal % cohortBriefingRotation.length != index) continue;
    final briefing = buildCohortBriefing(probe, universe: universe);
    if (briefing != null && briefing.girlId == definition.girlId) {
      return briefing.observation;
    }
  }
  return '';
}
