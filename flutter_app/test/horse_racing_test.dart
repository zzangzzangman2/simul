import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/horse_racing.dart';
import 'package:millennium_capital/game/market_clock.dart';
import 'package:millennium_capital/game/weekday_activity.dart';

void main() {
  const engine = GameEngine();

  GameState weekdayState(String seed) {
    final base = engine.createNewGame('경마 테스트', worldSeed: seed);
    var day = base.day;
    while (base.dateForDay(day).isBefore(DateTime(2010, 1, 1)) ||
        base.dateForDay(day).weekday >= DateTime.saturday) {
      day += 1;
    }
    return base.copyWith(
      day: day,
      cash: base.cash + 10000,
      marketMinute: krxCloseMinute,
      decisions: const [],
    );
  }

  test('afternoon race card and finish order are deterministic', () {
    final first = buildAfternoonHorseRace(
      simulationSeed: 'deterministic-race',
      day: 8,
    );
    final second = buildAfternoonHorseRace(
      simulationSeed: 'deterministic-race',
      day: 8,
    );

    expect(first.entrants, hasLength(8));
    expect(first.finishOrder, second.finishOrder);
    expect(first.id, second.id);
    expect(first.finishOrder.toSet(), hasLength(8));
    expect(
      first.entrants.map((horse) => horse.spriteAsset).toSet(),
      hasLength(8),
    );

    final records = first.finishOrder
        .map(first.entrantById)
        .map(
          (entrant) =>
              horseRaceFinishTimeSeconds(race: first, entrant: entrant),
        )
        .toList(growable: false);
    expect(records.first, inInclusiveRange(70.0, 74.0));
    for (var index = 1; index < records.length; index++) {
      expect(records[index], greaterThan(records[index - 1]));
    }
    expect(horseRaceRecordLabel(records.first), matches(r'^1:\d{2}\.\d{2}$'));
    final finishMoments = first.finishOrder
        .map(first.entrantById)
        .map(
          (entrant) =>
              horseRaceBroadcastFinishAt(race: first, entrant: entrant),
        )
        .toList(growable: false);
    for (var index = 1; index < finishMoments.length; index++) {
      expect(finishMoments[index], greaterThan(finishMoments[index - 1]));
    }
    expect(
      records,
      second.finishOrder
          .map(second.entrantById)
          .map(
            (entrant) =>
                horseRaceFinishTimeSeconds(race: second, entrant: entrant),
          )
          .toList(growable: false),
    );
  });

  test('straight broadcast reveals early, middle, and late moves', () {
    final races = <HorseRaceCard>[
      for (var day = 1; day <= 20; day++)
        buildAfternoonHorseRace(simulationSeed: 'broadcast-pace', day: day),
    ];
    final styleRace = races.firstWhere(
      (race) =>
          race.entrants.any((entrant) => entrant.runningStyle == '선행') &&
          race.entrants.any((entrant) => entrant.runningStyle == '선입') &&
          race.entrants.any((entrant) => entrant.runningStyle == '추입'),
    );
    final frontRunner = styleRace.entrants.firstWhere(
      (entrant) => entrant.runningStyle == '선행',
    );
    final stalker = styleRace.entrants.firstWhere(
      (entrant) => entrant.runningStyle == '선입',
    );
    final closer = styleRace.entrants.firstWhere(
      (entrant) => entrant.runningStyle == '추입',
    );

    double progress(HorseRaceEntrant entrant, double time) =>
        horseRaceBroadcastProgress(
          race: styleRace,
          entrant: entrant,
          time: time,
        );

    expect(progress(frontRunner, 0.18), greaterThan(progress(closer, 0.18)));
    expect(
      progress(stalker, 0.52) - progress(stalker, 0.30),
      greaterThan(progress(stalker, 0.30) - progress(stalker, 0.08)),
    );
    expect(
      progress(closer, 0.92) - progress(closer, 0.70),
      greaterThan(progress(closer, 0.30) - progress(closer, 0.08)),
    );

    for (final entrant in styleRace.entrants) {
      var previous = 0.0;
      for (var step = 0; step <= 100; step++) {
        final current = progress(entrant, step / 100);
        expect(current, greaterThanOrEqualTo(previous));
        previous = current;
      }
      expect(progress(entrant, 1), 1);

      final finishRank = styleRace.finishOrder.indexOf(entrant.id);
      expect(finishRank, greaterThanOrEqualTo(0));
      final finishAt = horseRaceBroadcastFinishAt(
        race: styleRace,
        entrant: entrant,
      );
      final approachSpeed =
          progress(entrant, finishAt * 0.84) -
          progress(entrant, finishAt * 0.82);
      final finishSpeed =
          progress(entrant, finishAt * 0.90) -
          progress(entrant, finishAt * 0.88);
      expect(
        finishSpeed,
        greaterThan(approachSpeed * 0.70),
        reason: '${entrant.name} should not visibly halve speed near the line',
      );
    }

    final winner = styleRace.entrantById(styleRace.finishOrder.first);
    final runnerUp = styleRace.entrantById(styleRace.finishOrder[1]);
    final betweenFirstAndSecond =
        (horseRaceBroadcastFinishAt(race: styleRace, entrant: winner) +
            horseRaceBroadcastFinishAt(race: styleRace, entrant: runnerUp)) /
        2;
    expect(progress(winner, betweenFirstAndSecond), 1);
    expect(
      styleRace.finishOrder
          .skip(1)
          .map(styleRace.entrantById)
          .every((entrant) => progress(entrant, betweenFirstAndSecond) < 1),
      isTrue,
    );

    final previewRace = buildAfternoonHorseRace(
      simulationSeed: 'horse-race-preview-v1',
      day: 8,
    );
    final leaders = <String>{
      for (final time in <double>[0.10, 0.24, 0.40, 0.56, 0.72, 0.86, 0.94])
        ([...previewRace.entrants]..sort(
              (left, right) =>
                  horseRaceBroadcastProgress(
                    race: previewRace,
                    entrant: right,
                    time: time,
                  ).compareTo(
                    horseRaceBroadcastProgress(
                      race: previewRace,
                      entrant: left,
                      time: time,
                    ),
                  ),
            ))
            .first
            .id,
    };
    expect(leaders.length, greaterThan(1));
    expect(leaders, contains(previewRace.finishOrder.first));
  });

  test('official margins include close photos and visibly spread fields', () {
    var narrowestGap = double.infinity;
    var widestGap = 0.0;
    var widestField = 0.0;
    for (var day = 1; day <= 40; day++) {
      final race = buildAfternoonHorseRace(
        simulationSeed: 'realistic-finish-margins',
        day: day,
      );
      final records = race.finishOrder
          .map(race.entrantById)
          .map(
            (entrant) =>
                horseRaceFinishTimeSeconds(race: race, entrant: entrant),
          )
          .toList(growable: false);
      widestField = math.max(widestField, records.last - records.first);
      for (var index = 1; index < records.length; index++) {
        final gap = records[index] - records[index - 1];
        narrowestGap = math.min(narrowestGap, gap);
        widestGap = math.max(widestGap, gap);
      }
    }

    expect(narrowestGap, lessThanOrEqualTo(0.13));
    expect(widestGap, greaterThanOrEqualTo(0.88));
    expect(widestField, greaterThan(2.0));
    expect(horseRaceMarginLabel(0.05), '코');
    expect(horseRaceMarginLabel(0.09), '머리');
    expect(horseRaceMarginLabel(0.13), '목');
    expect(horseRaceMarginLabel(0.34), '2');
    expect(horseRaceMarginLabel(1.80), '대차');
  });

  test(
    'adjacent race days rotate the full field and keep every coat unique',
    () {
      final first = buildAfternoonHorseRace(
        simulationSeed: 'rotating-roster',
        day: 8,
      );
      final next = buildAfternoonHorseRace(
        simulationSeed: 'rotating-roster',
        day: 9,
      );

      expect(
        first.entrants.map((horse) => horse.spriteAsset).toSet(),
        hasLength(8),
      );
      expect(
        next.entrants.map((horse) => horse.spriteAsset).toSet(),
        hasLength(8),
      );
      expect(
        first.entrants
            .map((horse) => horse.id)
            .toSet()
            .intersection(next.entrants.map((horse) => horse.id).toSet()),
        isEmpty,
      );
    },
  );

  test('ability scores determine probability and all displayed odds', () {
    final race = buildAfternoonHorseRace(
      simulationSeed: 'ability-market',
      day: 8,
    );
    final probabilityTotal = race.entrants.fold<double>(
      0,
      (total, entrant) => total + entrant.winProbability,
    );

    expect(probabilityTotal, closeTo(1, 0.000001));
    expect(
      race.entrants.map((entrant) => entrant.winOdds).toSet(),
      hasLength(8),
    );
    expect(
      race.entrants.map((entrant) => entrant.placeOdds).toSet(),
      hasLength(8),
    );
    for (final entrant in race.entrants) {
      expect(entrant.speed, inInclusiveRange(70, 100));
      expect(entrant.acceleration, inInclusiveRange(70, 100));
      expect(entrant.stamina, inInclusiveRange(70, 100));
      expect(entrant.finishingKick, inInclusiveRange(70, 100));
      expect(entrant.consistency, inInclusiveRange(70, 100));
      expect(
        entrant.compositeScore,
        closeTo(
          horseRaceCompositeScore(
            speed: entrant.speed,
            acceleration: entrant.acceleration,
            stamina: entrant.stamina,
            finishingKick: entrant.finishingKick,
            consistency: entrant.consistency,
          ),
          0.000001,
        ),
      );
    }

    final marketOrder = [...race.entrants]
      ..sort(
        (left, right) => right.compositeScore.compareTo(left.compositeScore),
      );
    for (var index = 1; index < marketOrder.length; index++) {
      expect(
        marketOrder[index - 1].winProbability,
        greaterThan(marketOrder[index].winProbability),
      );
      expect(
        marketOrder[index - 1].winOdds,
        lessThan(marketOrder[index].winOdds),
      );
      expect(
        marketOrder[index - 1].placeOdds,
        lessThan(marketOrder[index].placeOdds),
      );
    }
  });

  test('strong favorites win more often while upsets remain possible', () {
    var favoriteWins = 0;
    var outsiderWins = 0;
    for (var day = 1; day <= 320; day++) {
      final race = buildAfternoonHorseRace(
        simulationSeed: 'ability-frequency',
        day: day,
      );
      final marketOrder = [...race.entrants]
        ..sort(
          (left, right) => right.winProbability.compareTo(left.winProbability),
        );
      if (race.finishOrder.first == marketOrder.first.id) favoriteWins++;
      if (race.finishOrder.first == marketOrder.last.id) outsiderWins++;
    }

    expect(favoriteWins, greaterThan(outsiderWins));
    expect(outsiderWins, greaterThan(0));
  });

  test('win, place, and quinella payouts follow the official finish', () {
    final race = buildAfternoonHorseRace(simulationSeed: 'payout', day: 8);
    final winner = race.finishOrder[0];
    final second = race.finishOrder[1];
    final last = race.finishOrder.last;

    expect(
      calculateHorseRacePayout(
        race: race,
        betType: HorseBetType.win,
        primaryHorseId: winner,
        stake: 1000,
      ),
      greaterThan(1000),
    );
    expect(
      calculateHorseRacePayout(
        race: race,
        betType: HorseBetType.place,
        primaryHorseId: second,
        stake: 1000,
      ),
      greaterThan(1000),
    );
    expect(
      calculateHorseRacePayout(
        race: race,
        betType: HorseBetType.quinella,
        primaryHorseId: winner,
        secondaryHorseId: second,
        stake: 1000,
      ),
      greaterThan(1000),
    );
    expect(
      calculateHorseRacePayout(
        race: race,
        betType: HorseBetType.win,
        primaryHorseId: last,
        stake: 1000,
      ),
      0,
    );
  });

  test('state takes 20 percent only from confirmed profit', () {
    expect(horseRaceStateProfitFee(stake: 500, grossPayout: 1400), 180);
    expect(horseRaceStateProfitFee(stake: 1000, grossPayout: 1000), 0);
    expect(horseRaceStateProfitFee(stake: 1000, grossPayout: 0), 0);
  });

  test(
    'engine settles one validated afternoon race and records its ledger',
    () {
      final state = weekdayState('engine-horse-race');
      final race = buildAfternoonHorseRace(
        simulationSeed: state.simulationSeed,
        day: state.day,
      );
      final winner = race.finishOrder.first;
      final payout = calculateHorseRacePayout(
        race: race,
        betType: HorseBetType.win,
        primaryHorseId: winner,
        stake: 1000,
      );
      final ticket = HorseRaceSessionResult(
        raceId: race.id,
        betType: HorseBetType.win,
        primaryHorseId: winner,
        stake: 1000,
        grossPayout: payout,
        finishOrder: race.finishOrder,
      );
      final settled = engine.completeHorseRace(state, ticket);

      final stateFee = horseRaceStateProfitFee(
        stake: 1000,
        grossPayout: payout,
        recoveryRateBps: state.story.stateRecoveryRateBps,
      );

      expect(settled.success, isTrue);
      expect(settled.cashDelta, payout - 1000 - stateFee);
      expect(settled.state.cash, state.cash + payout - 1000 - stateFee);
      expect(settled.state.marketMinute, marketDayEndMinute);
      expect(horseRaceBetsToday(settled.state), horseRaceDailyBetLimit);
      expect(horseRaceDailyLimitReached(settled.state), isTrue);
      expect(
        weekdayActivityLogsForDay(settled.state, state.day).single.activityId,
        'horse_racing',
      );
      expect(
        settled.state.ledger.where((entry) => entry.id.contains('horse-race')),
        hasLength(3),
      );
      expect(
        settled.state.ledger
            .singleWhere(
              (entry) => entry.counterAccount == 'state_horse_racing_fee',
            )
            .amount,
        -stateFee,
      );

      final repeated = engine.completeHorseRace(settled.state, ticket);
      expect(repeated.success, isFalse);
      expect(repeated.message, contains('한도 1회'));
    },
  );

  test('engine rejects a forged payout', () {
    final state = weekdayState('forged-horse-race');
    final race = buildAfternoonHorseRace(
      simulationSeed: state.simulationSeed,
      day: state.day,
    );
    final result = engine.completeHorseRace(
      state,
      HorseRaceSessionResult(
        raceId: race.id,
        betType: HorseBetType.win,
        primaryHorseId: race.finishOrder.first,
        stake: 1000,
        grossPayout: 999999,
        finishOrder: race.finishOrder,
      ),
    );
    expect(result.success, isFalse);
    expect(result.state.cash, state.cash);
  });

  test('casino and horse racing are mutually exclusive weekday actions', () {
    final state = weekdayState('horse-race-exclusive');
    final casino = engine.completeWeekdayActivity(state, 'casino');
    expect(casino.success, isTrue);

    final race = buildAfternoonHorseRace(
      simulationSeed: state.simulationSeed,
      day: state.day,
    );
    final blocked = engine.completeHorseRace(
      casino.state,
      HorseRaceSessionResult(
        raceId: race.id,
        betType: HorseBetType.win,
        primaryHorseId: race.finishOrder.first,
        stake: 1000,
        grossPayout: calculateHorseRacePayout(
          race: race,
          betType: HorseBetType.win,
          primaryHorseId: race.finishOrder.first,
          stake: 1000,
        ),
        finishOrder: race.finishOrder,
      ),
    );
    expect(blocked.success, isFalse);
  });
}
