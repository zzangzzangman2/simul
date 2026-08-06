import 'stable_hash.dart';

const casinoUnlockDate = '2000-01-03';
const casinoMinimumStake = 500;
const casinoStakePercents = <int>[2, 5, 10, 30];
const casinoMaximumStakePercent = 30;
const casinoTestBankroll = 1000000;
const casinoRoundMinutes = 30;
const casinoDailyRoundLimit = 10;
const casinoHistoryLimit = 80;
const casinoSlotSymbols = <String>['체리', '레몬', '스타', 'BAR', '벨', '7'];
const casinoSlotTripleMultipliers = <int>[5, 8, 12, 18, 27, 95];
const casinoSlotTwoCherryMultiplier = 3;
const casinoSlotsTheoreticalRtp = 210 / 216;

enum CasinoGameType { baccarat, blackjack, roulette, craps, sicBo, slots }

enum CasinoBetType {
  baccaratPlayer,
  baccaratBanker,
  baccaratTie,
  baccaratPlayerPair,
  baccaratBankerPair,
  blackjackHand,
  rouletteRed,
  rouletteBlack,
  rouletteOdd,
  rouletteEven,
  rouletteLow,
  rouletteHigh,
  rouletteDozen1,
  rouletteDozen2,
  rouletteDozen3,
  rouletteColumn1,
  rouletteColumn2,
  rouletteColumn3,
  rouletteStraight,
  crapsPassLine,
  crapsDontPass,
  sicBoBig,
  sicBoSmall,
  sicBoOdd,
  sicBoEven,
  sicBoAnyTriple,
  sicBoSpecificTriple,
  sicBoTotal,
  slotsSpin,
}

enum BlackjackAction { hit, stand, doubleDown }

String casinoGameTitle(CasinoGameType game) => switch (game) {
  CasinoGameType.baccarat => '바카라',
  CasinoGameType.blackjack => '블랙잭',
  CasinoGameType.roulette => '유럽식 룰렛',
  CasinoGameType.craps => '크랩스',
  CasinoGameType.sicBo => '다이사이',
  CasinoGameType.slots => '클래식 3릴',
};

String casinoBetTitle(CasinoBetType type, {int? selection}) => switch (type) {
  CasinoBetType.baccaratPlayer => '플레이어',
  CasinoBetType.baccaratBanker => '뱅커',
  CasinoBetType.baccaratTie => '타이',
  CasinoBetType.baccaratPlayerPair => '플레이어 페어',
  CasinoBetType.baccaratBankerPair => '뱅커 페어',
  CasinoBetType.blackjackHand => '기본 핸드',
  CasinoBetType.rouletteRed => '레드',
  CasinoBetType.rouletteBlack => '블랙',
  CasinoBetType.rouletteOdd => '홀수',
  CasinoBetType.rouletteEven => '짝수',
  CasinoBetType.rouletteLow => '로우 1–18',
  CasinoBetType.rouletteHigh => '하이 19–36',
  CasinoBetType.rouletteDozen1 => '1st 12',
  CasinoBetType.rouletteDozen2 => '2nd 12',
  CasinoBetType.rouletteDozen3 => '3rd 12',
  CasinoBetType.rouletteColumn1 => '1열',
  CasinoBetType.rouletteColumn2 => '2열',
  CasinoBetType.rouletteColumn3 => '3열',
  CasinoBetType.rouletteStraight => '스트레이트 ${selection ?? 0}',
  CasinoBetType.crapsPassLine => '패스 라인',
  CasinoBetType.crapsDontPass => '돈트 패스',
  CasinoBetType.sicBoBig => '대',
  CasinoBetType.sicBoSmall => '소',
  CasinoBetType.sicBoOdd => '홀',
  CasinoBetType.sicBoEven => '짝',
  CasinoBetType.sicBoAnyTriple => '아무 트리플',
  CasinoBetType.sicBoSpecificTriple => '${selection ?? 1} 트리플',
  CasinoBetType.sicBoTotal => '합계 ${selection ?? 10}',
  CasinoBetType.slotsSpin => '3릴 스핀',
};

int casinoSlotPayoutMultiplier(List<int> reels) {
  if (reels.length != 3 ||
      reels.any((value) => value < 0 || value >= casinoSlotSymbols.length)) {
    throw ArgumentError.value(reels, 'reels', 'three valid reel indexes');
  }
  final triple = reels[0] == reels[1] && reels[1] == reels[2];
  if (triple) return casinoSlotTripleMultipliers[reels[0]];
  final cherries = reels.where((value) => value == 0).length;
  return cherries == 2 ? casinoSlotTwoCherryMultiplier : 0;
}

class CasinoBet {
  const CasinoBet({
    required this.game,
    required this.type,
    required this.stake,
    this.selection,
  });

  final CasinoGameType game;
  final CasinoBetType type;
  final int stake;
  final int? selection;
}

class CasinoRoundRecord {
  const CasinoRoundRecord({
    required this.id,
    required this.day,
    required this.minute,
    required this.game,
    required this.betLabel,
    required this.stake,
    required this.payout,
    required this.grossPayout,
    required this.nationalFee,
    required this.outcome,
    required this.detail,
  });

  final String id;
  final int day;
  final int minute;
  final CasinoGameType game;
  final String betLabel;
  final int stake;
  final int payout;
  final int grossPayout;
  final int nationalFee;
  final String outcome;
  final String detail;

  int get net => payout - stake;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'day': day,
    'minute': minute,
    'game': game.name,
    'betLabel': betLabel,
    'stake': stake,
    'payout': payout,
    'grossPayout': grossPayout,
    'nationalFee': nationalFee,
    'outcome': outcome,
    'detail': detail,
  };

  factory CasinoRoundRecord.fromJson(Map<String, dynamic> json) =>
      CasinoRoundRecord(
        id: json['id'] as String? ?? '',
        day: (json['day'] as num?)?.toInt() ?? 0,
        minute: (json['minute'] as num?)?.toInt() ?? 0,
        game: CasinoGameType.values.firstWhere(
          (value) => value.name == json['game'],
          orElse: () => CasinoGameType.baccarat,
        ),
        betLabel: json['betLabel'] as String? ?? '',
        stake: (json['stake'] as num?)?.toInt() ?? 0,
        payout: (json['payout'] as num?)?.toInt() ?? 0,
        grossPayout:
            (json['grossPayout'] as num?)?.toInt() ??
            (json['payout'] as num?)?.toInt() ??
            0,
        nationalFee: (json['nationalFee'] as num?)?.toInt() ?? 0,
        outcome: json['outcome'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
      );
}

class BlackjackHandState {
  const BlackjackHandState({
    required this.id,
    required this.day,
    required this.minute,
    required this.stake,
    required this.deck,
    required this.playerCards,
    required this.dealerCards,
    required this.nextCardIndex,
    required this.doubled,
  });

  final String id;
  final int day;
  final int minute;
  final int stake;
  final List<int> deck;
  final List<int> playerCards;
  final List<int> dealerCards;
  final int nextCardIndex;
  final bool doubled;

  BlackjackHandState copyWith({
    int? stake,
    List<int>? playerCards,
    List<int>? dealerCards,
    int? nextCardIndex,
    bool? doubled,
  }) => BlackjackHandState(
    id: id,
    day: day,
    minute: minute,
    stake: stake ?? this.stake,
    deck: deck,
    playerCards: playerCards ?? this.playerCards,
    dealerCards: dealerCards ?? this.dealerCards,
    nextCardIndex: nextCardIndex ?? this.nextCardIndex,
    doubled: doubled ?? this.doubled,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'day': day,
    'minute': minute,
    'stake': stake,
    'deck': deck,
    'playerCards': playerCards,
    'dealerCards': dealerCards,
    'nextCardIndex': nextCardIndex,
    'doubled': doubled,
  };

  factory BlackjackHandState.fromJson(Map<String, dynamic> json) =>
      BlackjackHandState(
        id: json['id'] as String? ?? '',
        day: (json['day'] as num?)?.toInt() ?? 0,
        minute: (json['minute'] as num?)?.toInt() ?? 0,
        stake: (json['stake'] as num?)?.toInt() ?? 0,
        deck: ((json['deck'] as List?) ?? const <dynamic>[])
            .whereType<num>()
            .map((value) => value.toInt())
            .where((value) => value >= 0 && value < 52)
            .toList(growable: false),
        playerCards: ((json['playerCards'] as List?) ?? const <dynamic>[])
            .whereType<num>()
            .map((value) => value.toInt())
            .where((value) => value >= 0 && value < 52)
            .toList(growable: false),
        dealerCards: ((json['dealerCards'] as List?) ?? const <dynamic>[])
            .whereType<num>()
            .map((value) => value.toInt())
            .where((value) => value >= 0 && value < 52)
            .toList(growable: false),
        nextCardIndex: (json['nextCardIndex'] as num?)?.toInt() ?? 4,
        doubled: json['doubled'] == true,
      );
}

class CrapsRoundState {
  const CrapsRoundState({
    required this.id,
    required this.day,
    required this.minute,
    required this.stake,
    required this.betType,
    required this.point,
    required this.rolls,
    required this.nextRollIndex,
  });

  final String id;
  final int day;
  final int minute;
  final int stake;
  final CasinoBetType betType;
  final int point;
  final List<List<int>> rolls;
  final int nextRollIndex;

  CrapsRoundState copyWith({
    int? point,
    List<List<int>>? rolls,
    int? nextRollIndex,
  }) => CrapsRoundState(
    id: id,
    day: day,
    minute: minute,
    stake: stake,
    betType: betType,
    point: point ?? this.point,
    rolls: rolls ?? this.rolls,
    nextRollIndex: nextRollIndex ?? this.nextRollIndex,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'day': day,
    'minute': minute,
    'stake': stake,
    'betType': betType.name,
    'point': point,
    'rolls': rolls,
    'nextRollIndex': nextRollIndex,
  };

  factory CrapsRoundState.fromJson(Map<String, dynamic> json) =>
      CrapsRoundState(
        id: json['id'] as String? ?? '',
        day: (json['day'] as num?)?.toInt() ?? 0,
        minute: (json['minute'] as num?)?.toInt() ?? 0,
        stake: (json['stake'] as num?)?.toInt() ?? 0,
        betType: CasinoBetType.values.firstWhere(
          (value) => value.name == json['betType'],
          orElse: () => CasinoBetType.crapsPassLine,
        ),
        point: (json['point'] as num?)?.toInt() ?? 0,
        rolls: ((json['rolls'] as List?) ?? const <dynamic>[])
            .whereType<List>()
            .map(
              (roll) => roll
                  .whereType<num>()
                  .map((value) => value.toInt())
                  .where((value) => value >= 1 && value <= 6)
                  .take(2)
                  .toList(growable: false),
            )
            .where((roll) => roll.length == 2)
            .toList(growable: false),
        nextRollIndex: (json['nextRollIndex'] as num?)?.toInt() ?? 1,
      );
}

const _casinoUnset = Object();

class CasinoState {
  const CasinoState({
    required this.chipBalance,
    required this.monthKey,
    required this.monthBankrollBasis,
    required this.monthlyStake,
    required this.monthlyPayout,
    required this.monthlyNationalFee,
    required this.lastPlayDay,
    required this.roundsToday,
    required this.roundSequence,
    required this.totalRounds,
    required this.totalStake,
    required this.totalPayout,
    required this.totalNationalFee,
    required this.history,
    required this.activeBlackjack,
    required this.activeCraps,
  });

  const CasinoState.initial()
    : chipBalance = 0,
      monthKey = '',
      monthBankrollBasis = 0,
      monthlyStake = 0,
      monthlyPayout = 0,
      monthlyNationalFee = 0,
      lastPlayDay = 0,
      roundsToday = 0,
      roundSequence = 0,
      totalRounds = 0,
      totalStake = 0,
      totalPayout = 0,
      totalNationalFee = 0,
      history = const <CasinoRoundRecord>[],
      activeBlackjack = null,
      activeCraps = null;

  /// 현금과 분리해 보관하는 카지노 전용 칩 잔액이다.
  final int chipBalance;
  final String monthKey;
  final int monthBankrollBasis;
  final int monthlyStake;
  final int monthlyPayout;
  final int monthlyNationalFee;
  final int lastPlayDay;
  final int roundsToday;
  final int roundSequence;
  final int totalRounds;
  final int totalStake;
  final int totalPayout;
  final int totalNationalFee;
  final List<CasinoRoundRecord> history;
  final BlackjackHandState? activeBlackjack;
  final CrapsRoundState? activeCraps;

  int get monthlyNet => monthlyPayout - monthlyStake;
  int get monthlyLoss => monthlyNet < 0 ? -monthlyNet : 0;
  int get lifetimeNet => totalPayout - totalStake;

  int roundsForDay(int day) => day == lastPlayDay ? roundsToday : 0;

  CasinoState forMonth(String key, int bankrollBasis) {
    if (monthKey == key) return this;
    return copyWith(
      monthKey: key,
      monthBankrollBasis: bankrollBasis,
      monthlyStake: 0,
      monthlyPayout: 0,
      monthlyNationalFee: 0,
    );
  }

  CasinoState copyWith({
    int? chipBalance,
    String? monthKey,
    int? monthBankrollBasis,
    int? monthlyStake,
    int? monthlyPayout,
    int? monthlyNationalFee,
    int? lastPlayDay,
    int? roundsToday,
    int? roundSequence,
    int? totalRounds,
    int? totalStake,
    int? totalPayout,
    int? totalNationalFee,
    List<CasinoRoundRecord>? history,
    Object? activeBlackjack = _casinoUnset,
    Object? activeCraps = _casinoUnset,
  }) => CasinoState(
    chipBalance: chipBalance ?? this.chipBalance,
    monthKey: monthKey ?? this.monthKey,
    monthBankrollBasis: monthBankrollBasis ?? this.monthBankrollBasis,
    monthlyStake: monthlyStake ?? this.monthlyStake,
    monthlyPayout: monthlyPayout ?? this.monthlyPayout,
    monthlyNationalFee: monthlyNationalFee ?? this.monthlyNationalFee,
    lastPlayDay: lastPlayDay ?? this.lastPlayDay,
    roundsToday: roundsToday ?? this.roundsToday,
    roundSequence: roundSequence ?? this.roundSequence,
    totalRounds: totalRounds ?? this.totalRounds,
    totalStake: totalStake ?? this.totalStake,
    totalPayout: totalPayout ?? this.totalPayout,
    totalNationalFee: totalNationalFee ?? this.totalNationalFee,
    history: history ?? this.history,
    activeBlackjack: identical(activeBlackjack, _casinoUnset)
        ? this.activeBlackjack
        : activeBlackjack as BlackjackHandState?,
    activeCraps: identical(activeCraps, _casinoUnset)
        ? this.activeCraps
        : activeCraps as CrapsRoundState?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'chipBalance': chipBalance,
    'monthKey': monthKey,
    'monthBankrollBasis': monthBankrollBasis,
    'monthlyStake': monthlyStake,
    'monthlyPayout': monthlyPayout,
    'monthlyNationalFee': monthlyNationalFee,
    'lastPlayDay': lastPlayDay,
    'roundsToday': roundsToday,
    'roundSequence': roundSequence,
    'totalRounds': totalRounds,
    'totalStake': totalStake,
    'totalPayout': totalPayout,
    'totalNationalFee': totalNationalFee,
    'history': history.map((record) => record.toJson()).toList(growable: false),
    if (activeBlackjack != null) 'activeBlackjack': activeBlackjack!.toJson(),
    if (activeCraps != null) 'activeCraps': activeCraps!.toJson(),
  };

  factory CasinoState.fromJson(Map<String, dynamic> json) {
    final parsedHistory = ((json['history'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => CasinoRoundRecord.fromJson(item.cast<String, dynamic>()))
        .where((record) => record.id.isNotEmpty && record.stake >= 0)
        .toList(growable: false);
    final history = parsedHistory.length <= casinoHistoryLimit
        ? parsedHistory
        : parsedHistory.sublist(parsedHistory.length - casinoHistoryLimit);
    final rawHand = json['activeBlackjack'];
    final hand = rawHand is Map
        ? BlackjackHandState.fromJson(rawHand.cast<String, dynamic>())
        : null;
    final rawCraps = json['activeCraps'];
    final craps = rawCraps is Map
        ? CrapsRoundState.fromJson(rawCraps.cast<String, dynamic>())
        : null;
    return CasinoState(
      chipBalance: ((json['chipBalance'] as num?)?.toInt() ?? 0)
          .clamp(0, 1 << 62)
          .toInt(),
      monthKey: json['monthKey'] as String? ?? '',
      monthBankrollBasis: (json['monthBankrollBasis'] as num?)?.toInt() ?? 0,
      monthlyStake: (json['monthlyStake'] as num?)?.toInt() ?? 0,
      monthlyPayout: (json['monthlyPayout'] as num?)?.toInt() ?? 0,
      monthlyNationalFee: (json['monthlyNationalFee'] as num?)?.toInt() ?? 0,
      lastPlayDay: (json['lastPlayDay'] as num?)?.toInt() ?? 0,
      roundsToday: (json['roundsToday'] as num?)?.toInt() ?? 0,
      roundSequence: (json['roundSequence'] as num?)?.toInt() ?? 0,
      totalRounds: (json['totalRounds'] as num?)?.toInt() ?? 0,
      totalStake: (json['totalStake'] as num?)?.toInt() ?? 0,
      totalPayout: (json['totalPayout'] as num?)?.toInt() ?? 0,
      totalNationalFee: (json['totalNationalFee'] as num?)?.toInt() ?? 0,
      history: history,
      activeBlackjack:
          hand != null && hand.deck.length == 52 && hand.id.isNotEmpty
          ? hand
          : null,
      activeCraps:
          craps != null &&
              craps.id.isNotEmpty &&
              craps.stake >= casinoMinimumStake &&
              <int>{4, 5, 6, 8, 9, 10}.contains(craps.point)
          ? craps
          : null,
    );
  }
}

int casinoMaximumStakeForChips(int chipBalance) {
  if (chipBalance <= 0) return 0;
  final proportional = chipBalance * casinoMaximumStakePercent ~/ 100;
  return (proportional ~/ casinoMinimumStake) * casinoMinimumStake;
}

int casinoStakeForChipPercent(int chipBalance, int percent) {
  if (!casinoStakePercents.contains(percent)) return 0;
  final proportional = chipBalance * percent ~/ 100;
  final rounded = (proportional ~/ casinoMinimumStake) * casinoMinimumStake;
  return rounded >= casinoMinimumStake ? rounded : 0;
}

bool isValidCasinoChipStake(int stake, int chipBalance) =>
    stake >= casinoMinimumStake &&
    stake % casinoMinimumStake == 0 &&
    stake <= casinoMaximumStakeForChips(chipBalance);

int casinoMonthlyLossLimitForBasis(int bankrollBasis) {
  final twoPercent = bankrollBasis ~/ 50;
  final bounded = twoPercent.clamp(50000, 1000000);
  return (bounded ~/ casinoMinimumStake) * casinoMinimumStake;
}

int casinoNationalFee({required int grossPayout, required int stake}) {
  final confirmedProfit = grossPayout - stake;
  return confirmedProfit > 0 ? confirmedProfit ~/ 5 : 0;
}

String casinoMonthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

List<int> casinoShuffledDeck(String key) {
  final cards = List<int>.generate(52, (index) => index);
  for (var index = cards.length - 1; index > 0; index--) {
    final swapIndex = stableRandomInt(
      '$key:shuffle-v2:position:$index',
      index + 1,
    );
    final current = cards[index];
    cards[index] = cards[swapIndex];
    cards[swapIndex] = current;
  }
  return List<int>.unmodifiable(cards);
}

int casinoCardRank(int card) => card % 13 + 1;
int casinoCardSuit(int card) => card ~/ 13;

String casinoCardLabel(int card) {
  const suits = <String>['♠', '♥', '♦', '♣'];
  final suit = casinoCardSuit(card);
  final rank = switch (casinoCardRank(card)) {
    1 => 'A',
    11 => 'J',
    12 => 'Q',
    13 => 'K',
    final value => '$value',
  };
  return '${suits[suit < 0
      ? 0
      : suit > 3
      ? 3
      : suit]}$rank';
}

({int total, bool soft}) blackjackHandValue(List<int> cards) {
  var total = 0;
  var aces = 0;
  for (final card in cards) {
    final rank = casinoCardRank(card);
    if (rank == 1) {
      aces++;
      total += 11;
    } else {
      total += rank > 10 ? 10 : rank;
    }
  }
  while (total > 21 && aces > 0) {
    total -= 10;
    aces--;
  }
  return (total: total, soft: aces > 0);
}

bool blackjackIsNatural(List<int> cards) =>
    cards.length == 2 && blackjackHandValue(cards).total == 21;
