import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/cohort_investment_state.dart';
import 'package:millennium_capital/game/cohort_standing_events.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';

/// 결과표를 직접 만들어 순위를 고정한다. 순위 기준은 누적 수익률이므로
/// cumulativeProfitLoss로 등수를 만든다.
///
/// 저장 복원은 결과표가 정확히 10행일 때만 살리므로 항상 플레이어 1명과 동기 9명을
/// 채운다. [overrides]에 없는 동기는 [filler] 값을 쓴다.
CohortDailyInvestmentReport _report({
  required int day,
  required int playerCumulative,
  required int filler,
  Map<String, int> overrides = const <String, int>{},
}) {
  CohortDailyInvestmentResult row(
    String id,
    String name,
    int cumulative, {
    bool isPlayer = false,
  }) => CohortDailyInvestmentResult(
    investorId: id,
    name: name,
    assetId: 'hanbit_telecom',
    assetName: '한빛통신',
    investedAmount: 10000,
    profitLoss: 0,
    totalAmount: cohortInvestmentInitialBalance + cumulative,
    traded: true,
    isPlayer: isPlayer,
    cumulativeProfitLoss: cumulative,
  );

  return CohortDailyInvestmentReport(
    day: day,
    rows: <CohortDailyInvestmentResult>[
      row('player', '나', playerCumulative, isPlayer: true),
      for (final profile in cohortNpcInvestorProfiles)
        row(profile.id, profile.name, overrides[profile.id] ?? filler),
    ],
  );
}

GameState _withReports(
  GameState base,
  List<CohortDailyInvestmentReport> reports,
) => base.copyWith(
  cohortInvestments: base.cohortInvestments.copyWith(reports: reports),
);

void main() {
  const engine = GameEngine();
  final base = engine.createNewGame('순위 사건', worldSeed: 'standing-events');

  test('no reports means no streak and no event', () {
    final streak = cohortStandingStreakForState(base);
    expect(streak.isEmpty, isTrue);
    expect(cohortStandingEventForState(base), isNull);
  });

  test('three straight last places open the operator review', () {
    final state = _withReports(base, <CohortDailyInvestmentReport>[
      for (var day = 4; day <= 6; day += 1)
        _report(day: day, playerCumulative: -5000, filler: 100),
    ]);

    final streak = cohortStandingStreakForState(state);
    expect(streak.lastPlaceDays, 3);
    expect(streak.firstPlaceDays, 0);

    final event = cohortStandingEventForState(state);
    expect(event, isNotNull);
    expect(event!.kind, CohortStandingEventKind.operatorReview);
    expect(event.speaker, '한서윤 운영관');
    // 중단권 안내여야 하고 처벌 어조가 아니어야 한다.
    expect(event.body, contains('벌이 아니라'));
    expect(event.body, contains('그만둘 수 있고'));
  });

  test('a single better day breaks the last place streak', () {
    final state = _withReports(base, <CohortDailyInvestmentReport>[
      _report(day: 4, playerCumulative: -5000, filler: 100),
      _report(day: 5, playerCumulative: 900, filler: 100),
      _report(day: 6, playerCumulative: -5000, filler: 100),
    ]);

    // 가장 최근 하루만 꼴등이므로 연속은 1이다.
    expect(cohortStandingStreakForState(state).lastPlaceDays, 1);
    expect(cohortStandingEventForState(state), isNull);
  });

  test('three straight wins open the rights audit', () {
    final state = _withReports(base, <CohortDailyInvestmentReport>[
      for (var day = 4; day <= 6; day += 1)
        _report(day: day, playerCumulative: 9000, filler: 100),
    ]);

    final streak = cohortStandingStreakForState(state);
    expect(streak.firstPlaceDays, 3);

    final event = cohortStandingEventForState(state);
    expect(event!.kind, CohortStandingEventKind.rightsAudit);
    expect(event.speaker, '조민경 권익감사관');
    // 1위가 감점 사유가 되지 않는다는 안내가 있어야 한다.
    expect(event.body, contains('감점 사유가 되지는 않습니다'));
  });

  test('five straight losses to the same peer declare a rival', () {
    final state = _withReports(base, <CohortDailyInvestmentReport>[
      for (var day = 4; day <= 8; day += 1)
        _report(
          day: day,
          playerCumulative: 500,
          // 학준만 계속 앞서고 나머지는 뒤처져 꼴등 연속을 막는다.
          filler: -900,
          overrides: <String, int>{'kim_hakjun': 4000},
        ),
    ]);

    final streak = cohortStandingStreakForState(state);
    expect(streak.rivalId, 'kim_hakjun');
    expect(streak.rivalDays, 5);
    expect(streak.lastPlaceDays, 0);
    expect(streak.firstPlaceDays, 0);

    final event = cohortStandingEventForState(state);
    expect(event!.kind, CohortStandingEventKind.rivalDeclared);
    expect(event.rivalId, 'kim_hakjun');
    expect(event.body, contains('내 종목을 먼저 공개할게'));
  });

  test('last place review outranks the rival event', () {
    final state = _withReports(base, <CohortDailyInvestmentReport>[
      for (var day = 4; day <= 8; day += 1)
        _report(
          day: day,
          playerCumulative: -5000,
          filler: 100,
          overrides: <String, int>{'kim_hakjun': 4000},
        ),
    ]);

    final event = cohortStandingEventForState(state);
    expect(event!.kind, CohortStandingEventKind.operatorReview);
  });

  test('an event opens once and the log closes it', () {
    var state = _withReports(base, <CohortDailyInvestmentReport>[
      for (var day = 4; day <= 6; day += 1)
        _report(day: day, playerCumulative: -5000, filler: 100),
    ]);

    final event = pendingCohortStandingEvent(state);
    expect(event, isNotNull);
    expect(cohortStandingEventSeen(state, event!), isFalse);

    state = state.copyWith(
      story: state.story.copyWith(
        storyFlags: <String, dynamic>{
          ...state.story.storyFlags,
          cohortStandingEventLogFlag: <dynamic>[event.id],
        },
      ),
    );

    expect(cohortStandingEventSeen(state, event), isTrue);
    expect(pendingCohortStandingEvent(state), isNull);
    // 연속이 더 길어지면 새 사건 ID가 되어 다시 열린다.
    final longer = _withReports(state, <CohortDailyInvestmentReport>[
      for (var day = 4; day <= 7; day += 1)
        _report(day: day, playerCumulative: -5000, filler: 100),
    ]);
    expect(pendingCohortStandingEvent(longer), isNotNull);
  });

  test('streak is derived from the save with no new fields', () {
    final state = _withReports(base, <CohortDailyInvestmentReport>[
      for (var day = 4; day <= 6; day += 1)
        _report(day: day, playerCumulative: -5000, filler: 100),
    ]);
    final restored = GameState.fromJson(state.toJson());

    expect(GameState.schemaVersion, 26);
    expect(
      cohortStandingStreakForState(restored).lastPlaceDays,
      cohortStandingStreakForState(state).lastPlaceDays,
    );
    expect(
      cohortStandingEventForState(restored)?.id,
      cohortStandingEventForState(state)?.id,
    );
  });
}
