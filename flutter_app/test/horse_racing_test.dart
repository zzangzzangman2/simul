import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/horse_racing.dart';
import 'package:millennium_capital/game/weekend_activity.dart';

void main() {
  const engine = GameEngine();

  GameState weekendState(String seed) {
    final base = engine.createNewGame('경마 테스트', worldSeed: seed);
    var day = base.day;
    while (base.dateForDay(day).weekday != DateTime.saturday) {
      day += 1;
    }
    return base.copyWith(day: day, cash: base.cash + 10000);
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
    expect(
      first.entrants
          .map((horse) => horseRaceCurveGallopAssetFor(horse.spriteAsset))
          .toSet(),
      hasLength(8),
    );
    expect(horseRaceCurveGallopAssets.toSet(), hasLength(8));
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
      final state = weekendState('engine-horse-race');
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
      final settled = engine.completeWeekendActivity(
        state,
        WeekendActivityRequest(
          activityId: 'horse_racing',
          horseRaceResult: HorseRaceSessionResult(
            raceId: race.id,
            betType: HorseBetType.win,
            primaryHorseId: winner,
            stake: 1000,
            grossPayout: payout,
            finishOrder: race.finishOrder,
          ),
        ),
      );

      final stateFee = horseRaceStateProfitFee(
        stake: 1000,
        grossPayout: payout,
        recoveryRateBps: state.story.stateRecoveryRateBps,
      );

      expect(settled.success, isTrue);
      expect(settled.cashDelta, payout - 1000 - stateFee);
      expect(settled.state.cash, state.cash + payout - 1000 - stateFee);
      expect(horseRaceAlreadyPlayedToday(settled.state), isTrue);
      expect(
        weekendActivityLogsForDay(settled.state, state.day).single.kind,
        WeekendActivityKind.entertainment,
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

      final repeated = engine.completeWeekendActivity(
        settled.state,
        WeekendActivityRequest(
          activityId: 'horse_racing',
          horseRaceResult: HorseRaceSessionResult(
            raceId: race.id,
            betType: HorseBetType.win,
            primaryHorseId: winner,
            stake: 1000,
            grossPayout: payout,
            finishOrder: race.finishOrder,
          ),
        ),
      );
      expect(repeated.success, isFalse);
    },
  );

  test('engine rejects a forged payout', () {
    final state = weekendState('forged-horse-race');
    final race = buildAfternoonHorseRace(
      simulationSeed: state.simulationSeed,
      day: state.day,
    );
    final result = engine.completeWeekendActivity(
      state,
      WeekendActivityRequest(
        activityId: 'horse_racing',
        horseRaceResult: HorseRaceSessionResult(
          raceId: race.id,
          betType: HorseBetType.win,
          primaryHorseId: race.finishOrder.first,
          stake: 1000,
          grossPayout: 999999,
          finishOrder: race.finishOrder,
        ),
      ),
    );
    expect(result.success, isFalse);
    expect(result.state.cash, state.cash);
  });
}
