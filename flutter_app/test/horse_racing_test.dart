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
    while (base.dateForDay(day).weekday >= DateTime.saturday) {
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
    for (final entrant in first.entrants) {
      expect(entrant.recentFinishes, hasLength(10));
      expect(entrant.recentPerformances, hasLength(10));
      expect(
        entrant.recentFinishes.every((rank) => rank >= 1 && rank <= 12),
        isTrue,
      );
      expect(entrant.recentWinCount, inInclusiveRange(0, 10));
      expect(entrant.recentTopThreeCount, inInclusiveRange(0, 10));
      expect(entrant.origin, anyOf('한국', '미국'));
      expect(entrant.sex, anyOf('수', '암', '거'));
      expect(entrant.age, inInclusiveRange(3, 6));
      expect(entrant.assignedWeight, inInclusiveRange(51.0, 58.0));
      expect(entrant.trainer, isNotEmpty);
      for (var index = 1; index < entrant.recentPerformances.length; index++) {
        expect(
          entrant.recentPerformances[index - 1].date.isAfter(
            entrant.recentPerformances[index].date,
          ),
          isTrue,
        );
      }
    }

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

  test('broadcast surge cues match each runner pace profile', () {
    final race = buildAfternoonHorseRace(
      simulationSeed: 'broadcast-surge-cues',
      day: 11,
    );
    final rebuilt = buildAfternoonHorseRace(
      simulationSeed: 'broadcast-surge-cues',
      day: 11,
    );

    for (final entrant in race.entrants) {
      final segment = horseRaceBroadcastBurstSegment(
        race: race,
        entrant: entrant,
      );
      final allowedSegments = switch (entrant.runningStyle) {
        '선행' => <int>{0, 1},
        '선입' => <int>{2, 3},
        '추입' => <int>{4, 5},
        '지구력' => <int>{3, 4},
        _ => <int>{1, 2, 3, 4},
      };
      expect(allowedSegments, contains(segment));
      final surgeAt = horseRaceBroadcastSurgeAt(race: race, entrant: entrant);
      expect(surgeAt, inInclusiveRange(0.0, 0.94));
      expect(horseRaceBroadcastSurgeLabel(entrant), isNotEmpty);
      final skill = horseRaceSignatureSkill(entrant);
      expect(skill.effectLabel, isNotEmpty);
      expect(skill.paceBoost, inInclusiveRange(0.22, 0.35));

      final rebuiltEntrant = rebuilt.entrantById(entrant.id);
      expect(
        horseRaceBroadcastSurgeAt(race: rebuilt, entrant: rebuiltEntrant),
        surgeAt,
      );
      expect(horseRaceSignatureSkill(rebuiltEntrant).name, skill.name);
      expect(
        horseRaceSignatureSkill(rebuiltEntrant).paceBoost,
        skill.paceBoost,
      );
    }
  });

  test('every runner keeps visible speed on the final approach', () {
    for (var day = 1; day <= 40; day++) {
      final race = buildAfternoonHorseRace(
        simulationSeed: 'final-approach-speed',
        day: day,
      );
      double progress(HorseRaceEntrant entrant, double time) =>
          horseRaceBroadcastProgress(
            race: race,
            entrant: entrant,
            time: math.max(0, time),
          );
      for (final entrant in race.entrants) {
        final finishAt = horseRaceBroadcastFinishAt(
          race: race,
          entrant: entrant,
        );
        final before = progress(entrant, finishAt - 0.08);
        expect(
          1 - before,
          greaterThan(0.24),
          reason:
              '${entrant.name} must still have a real galloping distance one second before its finish.',
        );
        expect(
          progress(entrant, finishAt - 0.02) -
              progress(entrant, finishAt - 0.04),
          greaterThan(0.06),
          reason:
              '${entrant.name} must accelerate through the line instead of crawling into its assigned place.',
        );
      }

      final winner = race.entrantById(race.finishOrder.first);
      final previewTime =
          horseRaceBroadcastFinishAt(race: race, entrant: winner) - 0.08;
      final previewProgress = race.entrants
          .map((entrant) => progress(entrant, previewTime))
          .toList(growable: false);
      expect(
        previewProgress.reduce(math.max) - previewProgress.reduce(math.min),
        greaterThan(0.10),
        reason:
            'The field must already be visibly spread before the winner reaches the stripe.',
      );
      final bestBottomHalfProgress = race.finishOrder
          .skip(4)
          .map(race.entrantById)
          .map((entrant) => progress(entrant, previewTime))
          .reduce(math.max);
      expect(
        progress(winner, previewTime) - bestBottomHalfProgress,
        greaterThan(0.06),
        reason:
            'Lower-ranked runners must lose ground before the line, not brake beside it.',
      );
    }
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

  test('the stable roster rests every horse for at least two weeks', () {
    final cards = <HorseRaceCard>[
      for (var day = 1; day <= 56; day++)
        buildAfternoonHorseRace(simulationSeed: 'rested-roster', day: day),
    ];
    final lastStartByHorse = <String, int>{};
    var returningHorseCount = 0;
    for (var index = 0; index < cards.length; index++) {
      final day = index + 1;
      for (final entrant in cards[index].entrants) {
        final previous = lastStartByHorse[entrant.id];
        if (previous != null) {
          expect(day - previous, greaterThanOrEqualTo(15));
          returningHorseCount += 1;
        }
        lastStartByHorse[entrant.id] = day;
      }
    }
    expect(lastStartByHorse.length, greaterThanOrEqualTo(160));
    expect(returningHorseCount, greaterThan(0));
  });

  test('224 horses rotate through 24 distinct visual identities', () {
    final horseIds = <String>{};
    final visualAssets = <String>{};
    final signatureSkills = <String>{};
    for (var day = 1; day <= 28; day++) {
      final race = buildAfternoonHorseRace(
        simulationSeed: 'visual-roster-coverage',
        day: day,
      );
      final familyIndexes = <int>{};
      for (final entrant in race.entrants) {
        horseIds.add(entrant.id);
        visualAssets.add(entrant.spriteAsset);
        signatureSkills.add(horseRaceSignatureSkill(entrant).name);
        familyIndexes.add(
          horseRaceGallopAssetFamilies.indexWhere(
            (family) => family.contains(entrant.spriteAsset),
          ),
        );
      }
      expect(familyIndexes, hasLength(8));
      expect(familyIndexes, isNot(contains(-1)));
    }

    expect(horseIds, hasLength(224));
    expect(visualAssets, horseRaceAllGallopAssets.toSet());
    expect(
      signatureSkills,
      hasLength(224),
      reason: 'Every stable horse needs one roster-wide unique skill name.',
    );
  });

  test('official results update recent form even when no wager was placed', () {
    const seed = 'persistent-world-results';
    final openingRace = buildAfternoonHorseRace(simulationSeed: seed, day: 1);
    final trackedHorse = openingRace.entrants.first;
    HorseRaceEntrant? returningHorse;

    for (var day = 2; day <= 56; day++) {
      final race = buildAfternoonHorseRace(simulationSeed: seed, day: day);
      final matches = race.entrants.where(
        (entrant) => entrant.id == trackedHorse.id,
      );
      if (matches.isNotEmpty) {
        returningHorse = matches.single;
        break;
      }
    }

    expect(returningHorse, isNotNull);
    expect(returningHorse!.recentPerformances.first.date, DateTime(2000, 1, 1));
    expect(
      returningHorse.recentPerformances.first.position,
      openingRace.finishPosition(trackedHorse.id),
    );

    final restoredCard = buildAfternoonHorseRace(simulationSeed: seed, day: 1);
    expect(restoredCard.finishOrder, openingRace.finishOrder);
  });

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

  test('favorite wins about one race in three while every rank can upset', () {
    const raceCount = 1600;
    final winsByMarketRank = List<int>.filled(8, 0);
    for (var day = 1; day <= raceCount; day++) {
      final race = buildAfternoonHorseRace(
        simulationSeed: 'ability-frequency',
        day: day,
      );
      final marketOrder = [...race.entrants]
        ..sort(
          (left, right) => right.winProbability.compareTo(left.winProbability),
        );
      final winnerRank = marketOrder.indexWhere(
        (entrant) => entrant.id == race.finishOrder.first,
      );
      winsByMarketRank[winnerRank]++;
    }

    final favoriteWinRate = winsByMarketRank.first / raceCount;
    expect(favoriteWinRate, inInclusiveRange(0.33, 0.40));
    expect(winsByMarketRank.first, greaterThan(winsByMarketRank[1]));
    expect(winsByMarketRank[1], greaterThan(winsByMarketRank[2]));
    expect(winsByMarketRank.last, greaterThan(0));
  });

  test('stake presets scale from 2 to 30 percent of available cash', () {
    expect(horseRaceStakeForCashPercent(50000, 2), 1000);
    expect(horseRaceStakeForCashPercent(50000, 5), 2500);
    expect(horseRaceStakeForCashPercent(50000, 10), 5000);
    expect(horseRaceStakeForCashPercent(50000, 30), 15000);
    expect(horseRaceMaximumStakeForCash(50000), 15000);
    expect(isValidHorseRaceStake(15000, 50000), isTrue);
    expect(isValidHorseRaceStake(15500, 50000), isFalse);
    expect(isValidHorseRaceStake(1250, 50000), isFalse);
  });

  test('high-value accounts use a capped leisure stake basis', () {
    const availableCash = 100000000000;
    expect(
      horseRaceStakeBasisForCash(availableCash),
      horseRaceLeisureStakeBasisCap,
    );
    expect(horseRaceStakeForCashPercent(availableCash, 2), 1000000);
    expect(horseRaceStakeForCashPercent(availableCash, 5), 2500000);
    expect(horseRaceStakeForCashPercent(availableCash, 10), 5000000);
    expect(horseRaceStakeForCashPercent(availableCash, 30), 15000000);
    expect(horseRaceMaximumStakeForCash(availableCash), 15000000);
    expect(isValidHorseRaceStake(15000000, availableCash), isTrue);
    expect(isValidHorseRaceStake(15000500, availableCash), isFalse);
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
      expect(
        settled.state.brokerageCash,
        state.brokerageCash + payout - 1000 - stateFee,
      );
      expect(settled.state.bankCash, state.bankCash);
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
            .where((entry) => entry.id.contains('horse-race'))
            .every((entry) => entry.account == 'brokerage_cash'),
        isTrue,
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

  test('engine rejects a ticket above 30 percent of available cash', () {
    final base = weekdayState('oversized-horse-race');
    final state = base.copyWith(cash: 50000, brokerageCash: 50000);
    final race = buildAfternoonHorseRace(
      simulationSeed: state.simulationSeed,
      day: state.day,
    );
    const stake = 15500;
    final result = engine.completeHorseRace(
      state,
      HorseRaceSessionResult(
        raceId: race.id,
        betType: HorseBetType.win,
        primaryHorseId: race.finishOrder.first,
        stake: stake,
        grossPayout: calculateHorseRacePayout(
          race: race,
          betType: HorseBetType.win,
          primaryHorseId: race.finishOrder.first,
          stake: stake,
        ),
        finishOrder: race.finishOrder,
      ),
    );

    expect(result.success, isFalse);
    expect(result.message, contains('30%'));
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

  test('winner gates rotate across the calendar', () {
    final winnerCounts = <int, int>{
      for (var gate = 1; gate <= 8; gate++) gate: 0,
    };
    for (var day = 1; day <= 240; day++) {
      final race = buildAfternoonHorseRace(
        simulationSeed: 'horse-race-preview-v1',
        day: day,
      );
      final winnerGate = race.entrantById(race.finishOrder.first).gate;
      winnerCounts[winnerGate] = winnerCounts[winnerGate]! + 1;
    }

    expect(winnerCounts.values.every((count) => count > 0), isTrue);
    final mostWins = winnerCounts.values.reduce(math.max);
    final fewestWins = winnerCounts.values.reduce(math.min);
    expect(mostWins - fewestWins, lessThan(30));
  });
}
