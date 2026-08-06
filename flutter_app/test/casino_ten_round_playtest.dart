import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/casino_state.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/market_clock.dart';

const _engine = GameEngine();
// Bet fixtures describe only game/type/selection. The live wager is always
// recalculated from the current balance so the audit obeys the 2% preset and
// can complete all ten rounds without bypassing the monthly loss stop.
const _stake = 0;

int _stakeFor(GameState state) =>
    casinoStakeForChipPercent(state.personalFinance.casino.chipBalance, 2);

GameState _session(String seed) {
  final day = DateTime(2000, 1, 3).difference(DateTime(2000, 1, 1)).inDays + 1;
  final state = _engine
      .createNewGame('카지노 10판 실전 테스트', initialCash: 10000000, worldSeed: seed)
      .copyWith(day: day, marketMinute: krxCloseMinute, decisions: const []);
  return _engine.exchangeCasinoChips(state, 1000000).state;
}

GameState _advanceAfterRound(GameState state, CasinoActionResult result) {
  expect(result.success, isTrue, reason: result.message);
  expect(result.minutesElapsed, casinoRoundMinutes);
  return result.state.copyWith(
    marketMinute: advanceGameTime(state.marketMinute, result.minutesElapsed),
  );
}

void _verifyAndPrint(String label, GameState before, GameState after) {
  final casino = after.personalFinance.casino;
  final records = casino.history;
  expect(records, hasLength(10));
  expect(casino.totalRounds, 10);
  expect(casino.roundsToday, 10);
  expect(casino.activeBlackjack, isNull);
  expect(casino.activeCraps, isNull);
  expect(after.marketMinute, krxCloseMinute + casinoRoundMinutes * 10);

  final totalNet = records.fold<int>(0, (sum, record) => sum + record.net);
  final totalFee = records.fold<int>(
    0,
    (sum, record) => sum + record.nationalFee,
  );
  expect(
    after.personalFinance.casino.chipBalance -
        before.personalFinance.casino.chipBalance,
    totalNet,
  );
  expect(after.bankCash, before.bankCash);
  expect(casino.totalNationalFee, totalFee);
  for (final record in records) {
    expect(
      record.nationalFee,
      casinoNationalFee(grossPayout: record.grossPayout, stake: record.stake),
    );
  }

  final wins = records.where((record) => record.net > 0).length;
  final pushes = records.where((record) => record.net == 0).length;
  final losses = records.where((record) => record.net < 0).length;
  debugPrint(
    '[$label] 10판 · 승 $wins / 본전 $pushes / 패 $losses · '
    '손익 $totalNet칩 · 국가 수수료 $totalFee칩 · 종료 20:00',
  );
  for (var index = 0; index < records.length; index++) {
    final record = records[index];
    debugPrint(
      '  ${index + 1}. ${record.betLabel} · ${record.outcome} · '
      '${record.detail} · 베팅 ${record.stake}칩 · 손익 ${record.net}칩 · '
      '수수료 ${record.nationalFee}칩',
    );
  }
}

GameState _playFixedBets(String seed, List<CasinoBet> bets) {
  var state = _session(seed);
  final before = state;
  for (final bet in bets) {
    final result = _engine.playCasinoRound(
      state,
      CasinoBet(
        game: bet.game,
        type: bet.type,
        stake: _stakeFor(state),
        selection: bet.selection,
      ),
    );
    state = _advanceAfterRound(state, result);
  }
  _verifyAndPrint(casinoGameTitle(bets.first.game), before, state);
  return state;
}

void main() {
  test('바카라를 서로 다른 베팅으로 10판 플레이한다', () {
    final types = <CasinoBetType>[
      CasinoBetType.baccaratPlayer,
      CasinoBetType.baccaratBanker,
      CasinoBetType.baccaratTie,
      CasinoBetType.baccaratPlayerPair,
      CasinoBetType.baccaratBankerPair,
      CasinoBetType.baccaratPlayer,
      CasinoBetType.baccaratBanker,
      CasinoBetType.baccaratTie,
      CasinoBetType.baccaratPlayerPair,
      CasinoBetType.baccaratBankerPair,
    ];
    _playFixedBets('ten-round-baccarat', [
      for (final type in types)
        CasinoBet(game: CasinoGameType.baccarat, type: type, stake: _stake),
    ]);
  });

  test('유럽식 룰렛을 서로 다른 베팅으로 10판 플레이한다', () {
    _playFixedBets('ten-round-roulette', const [
      CasinoBet(
        game: CasinoGameType.roulette,
        type: CasinoBetType.rouletteRed,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.roulette,
        type: CasinoBetType.rouletteBlack,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.roulette,
        type: CasinoBetType.rouletteOdd,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.roulette,
        type: CasinoBetType.rouletteEven,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.roulette,
        type: CasinoBetType.rouletteLow,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.roulette,
        type: CasinoBetType.rouletteHigh,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.roulette,
        type: CasinoBetType.rouletteDozen1,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.roulette,
        type: CasinoBetType.rouletteDozen2,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.roulette,
        type: CasinoBetType.rouletteColumn1,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.roulette,
        type: CasinoBetType.rouletteStraight,
        stake: _stake,
        selection: 17,
      ),
    ]);
  });

  test('다이사이를 서로 다른 베팅으로 10판 플레이한다', () {
    _playFixedBets('ten-round-sicbo', const [
      CasinoBet(
        game: CasinoGameType.sicBo,
        type: CasinoBetType.sicBoBig,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.sicBo,
        type: CasinoBetType.sicBoSmall,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.sicBo,
        type: CasinoBetType.sicBoOdd,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.sicBo,
        type: CasinoBetType.sicBoEven,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.sicBo,
        type: CasinoBetType.sicBoAnyTriple,
        stake: _stake,
      ),
      CasinoBet(
        game: CasinoGameType.sicBo,
        type: CasinoBetType.sicBoSpecificTriple,
        stake: _stake,
        selection: 1,
      ),
      CasinoBet(
        game: CasinoGameType.sicBo,
        type: CasinoBetType.sicBoSpecificTriple,
        stake: _stake,
        selection: 6,
      ),
      CasinoBet(
        game: CasinoGameType.sicBo,
        type: CasinoBetType.sicBoTotal,
        stake: _stake,
        selection: 4,
      ),
      CasinoBet(
        game: CasinoGameType.sicBo,
        type: CasinoBetType.sicBoTotal,
        stake: _stake,
        selection: 10,
      ),
      CasinoBet(
        game: CasinoGameType.sicBo,
        type: CasinoBetType.sicBoTotal,
        stake: _stake,
        selection: 17,
      ),
    ]);
  });

  test('클래식 3릴을 10판 플레이한다', () {
    _playFixedBets(
      'ten-round-slots',
      List<CasinoBet>.filled(
        10,
        const CasinoBet(
          game: CasinoGameType.slots,
          type: CasinoBetType.slotsSpin,
          stake: _stake,
        ),
      ),
    );
  });

  test('크랩스 라인·단판 프로포지션을 10판 플레이한다', () {
    var state = _session('ten-round-craps');
    final before = state;
    const betTypes = <CasinoBetType>[
      CasinoBetType.crapsPassLine,
      CasinoBetType.crapsDontPass,
      CasinoBetType.crapsField,
      CasinoBetType.crapsAnySeven,
      CasinoBetType.crapsAnyCraps,
    ];
    for (var round = 0; round < 10; round++) {
      var beforeAction = state;
      var result = _engine.playCasinoRound(
        state,
        CasinoBet(
          game: CasinoGameType.craps,
          type: betTypes[round % betTypes.length],
          stake: _stakeFor(state),
        ),
      );
      expect(result.success, isTrue, reason: result.message);
      var rollGuard = 0;
      while (result.state.personalFinance.casino.activeCraps != null) {
        state = result.state;
        beforeAction = state;
        result = _engine.rollCasinoCraps(state);
        expect(result.success, isTrue, reason: result.message);
        rollGuard++;
        expect(rollGuard, lessThan(100));
        if (result.state.personalFinance.casino.activeCraps != null) {
          expect(result.minutesElapsed, 0);
        }
      }
      state = _advanceAfterRound(beforeAction, result);
    }
    _verifyAndPrint('크랩스', before, state);
  });

  test('블랙잭을 기본 전략 판단으로 10판 플레이한다', () {
    var state = _session('ten-round-blackjack');
    final before = state;
    for (var round = 0; round < 10; round++) {
      final deal = _engine.startCasinoBlackjack(state, _stakeFor(state));
      expect(
        deal.success,
        isTrue,
        reason: 'deal ${round + 1}: ${deal.message}',
      );
      state = deal.state;

      var hand = state.personalFinance.casino.activeBlackjack!;
      final opening = blackjackHandValue(hand.playerCards);
      if (!opening.soft && (opening.total == 10 || opening.total == 11)) {
        final doubled = _engine.actCasinoBlackjack(
          state,
          BlackjackAction.doubleDown,
        );
        state = _advanceAfterRound(state, doubled);
        continue;
      }

      while (blackjackHandValue(hand.playerCards).total < 17) {
        final hit = _engine.actCasinoBlackjack(state, BlackjackAction.hit);
        expect(hit.success, isTrue, reason: hit.message);
        if (hit.state.personalFinance.casino.activeBlackjack == null) {
          state = _advanceAfterRound(state, hit);
          break;
        }
        state = hit.state;
        hand = state.personalFinance.casino.activeBlackjack!;
      }
      if (state.personalFinance.casino.activeBlackjack != null) {
        final stand = _engine.actCasinoBlackjack(state, BlackjackAction.stand);
        state = _advanceAfterRound(state, stand);
      }
    }
    _verifyAndPrint('블랙잭', before, state);
  });
}
