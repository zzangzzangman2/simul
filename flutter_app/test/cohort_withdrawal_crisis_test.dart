import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/cohort_investment_state.dart';
import 'package:millennium_capital/game/cohort_withdrawal_crisis.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/game_state.dart';
import 'package:millennium_capital/game/relationship_state.dart';

/// 결과표를 직접 만든다. 저장 복원이 10행만 살리므로 항상 플레이어와 동기 9명을 채운다.
CohortDailyInvestmentReport _report({
  required int day,
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
      row('player', '나', 0, isPlayer: true),
      for (final profile in cohortNpcInvestorProfiles)
        row(profile.id, profile.name, overrides[profile.id] ?? filler),
    ],
  );
}

GameState _withReports(GameState base, int days, Map<String, int> overrides) =>
    base.copyWith(
      cohortInvestments: base.cohortInvestments.copyWith(
        reports: <CohortDailyInvestmentReport>[
          for (var day = 4; day < 4 + days; day += 1)
            _report(day: day, filler: 500, overrides: overrides),
        ],
      ),
    );

void main() {
  const engine = GameEngine();
  final base = engine.createNewGame('중단권', worldSeed: 'withdrawal');

  test('every girl has a reason in her own voice', () {
    expect(cohortWithdrawalReasons, hasLength(8));
    for (final reason in cohortWithdrawalReasons) {
      expect(
        cohortGirlProfileById(reason.girlId),
        isNotNull,
        reason: '${reason.girlId}는 관계 정본에 없다',
      );
      expect(reason.opening, isNotEmpty);
      // 세 응답이 서로 다른 답을 받아야 선택에 의미가 있다.
      final replies = <String>{
        for (final response in CohortWithdrawalResponse.values)
          reason.replyFor(response),
      };
      expect(replies, hasLength(3), reason: '${reason.name} 응답이 겹친다');
    }
    // 남자 동기는 대상이 아니다.
    expect(cohortWithdrawalReasonFor('kim_hakjun'), isNull);
  });

  test('a short losing run does not open the crisis', () {
    final state = _withReports(base, cohortWithdrawalStreakThreshold - 1, {
      'han_sua': cohortWithdrawalLossThreshold - 1000,
    });
    expect(cohortWithdrawalCandidate(state), isNull);
  });

  test('a long deep losing run opens the crisis for that girl', () {
    final state = _withReports(base, cohortWithdrawalStreakThreshold, {
      'han_sua': cohortWithdrawalLossThreshold - 1000,
    });
    final candidate = cohortWithdrawalCandidate(state);
    expect(candidate, isNotNull);
    expect(candidate!.girlId, 'han_sua');
    expect(candidate.opening, contains('먼저 말한 게 계속 틀렸어'));
  });

  test('a shallow loss stays under the threshold', () {
    final state = _withReports(base, cohortWithdrawalStreakThreshold + 2, {
      'han_sua': cohortWithdrawalLossThreshold + 1,
    });
    expect(cohortWithdrawalCandidate(state), isNull);
  });

  test('one better day resets the run', () {
    var state = _withReports(base, cohortWithdrawalStreakThreshold, {
      'han_sua': cohortWithdrawalLossThreshold - 1000,
    });
    // 가장 최근 날만 회복하면 연속이 끊긴다.
    final reports = [...state.cohortInvestments.reports]
      ..removeLast()
      ..add(_report(day: 99, filler: 500));
    state = state.copyWith(
      cohortInvestments: state.cohortInvestments.copyWith(reports: reports),
    );
    expect(cohortWithdrawalCandidate(state), isNull);
  });

  test('deepest and then id order picks the same girl every time', () {
    final state = _withReports(base, cohortWithdrawalStreakThreshold, {
      'han_sua': cohortWithdrawalLossThreshold - 1000,
      'yoon_chaea': cohortWithdrawalLossThreshold - 1000,
    });
    // 연속 일수가 같으면 인물 ID 순으로 고정한다.
    expect(cohortWithdrawalCandidate(state)!.girlId, 'han_sua');
    expect(
      cohortWithdrawalCandidate(state)!.girlId,
      cohortWithdrawalCandidate(state)!.girlId,
    );
  });

  test('a resolved girl never opens the crisis again', () {
    var state = _withReports(base, cohortWithdrawalStreakThreshold, {
      'han_sua': cohortWithdrawalLossThreshold - 1000,
    });
    expect(cohortWithdrawalCandidate(state)!.girlId, 'han_sua');

    state = state.copyWith(
      story: state.story.copyWith(
        storyFlags: <String, dynamic>{
          ...state.story.storyFlags,
          cohortWithdrawalHistoryFlag: <dynamic>['han_sua'],
        },
      ),
    );
    expect(cohortWithdrawalHistory(state), <String>['han_sua']);
    expect(cohortWithdrawalCandidate(state), isNull);
  });

  test('crisis state round trips and tracks its deadline', () {
    const crisis = CohortWithdrawalCrisis(girlId: 'han_sua', openedDay: 10);
    expect(crisis.isResolved, isFalse);
    expect(crisis.deadlineDay, 10 + cohortWithdrawalWindowDays);
    expect(crisis.expiredOn(crisis.deadlineDay), isFalse);
    expect(crisis.expiredOn(crisis.deadlineDay + 1), isTrue);

    final restored = CohortWithdrawalCrisis.fromJson(crisis.toJson());
    expect(restored.girlId, 'han_sua');
    expect(restored.openedDay, 10);
    expect(restored.response, isNull);

    const answered = CohortWithdrawalCrisis(
      girlId: 'han_sua',
      openedDay: 10,
      respondedDay: 11,
      response: CohortWithdrawalResponse.shareLedger,
    );
    final answeredBack = CohortWithdrawalCrisis.fromJson(answered.toJson());
    expect(answeredBack.response, CohortWithdrawalResponse.shareLedger);
    expect(answeredBack.isResolved, isTrue);
    // 해결된 위기는 진행 중으로 잡히지 않는다.
    expect(answeredBack.expiredOn(999), isFalse);
  });

  test('active crisis reads from story flags only when unresolved', () {
    expect(activeCohortWithdrawalCrisis(base), isNull);

    GameState withCrisis(CohortWithdrawalCrisis crisis) => base.copyWith(
      story: base.story.copyWith(
        storyFlags: <String, dynamic>{
          ...base.story.storyFlags,
          cohortWithdrawalFlag: crisis.toJson(),
        },
      ),
    );

    final open = withCrisis(
      const CohortWithdrawalCrisis(girlId: 'han_sua', openedDay: 10),
    );
    expect(activeCohortWithdrawalCrisis(open)?.girlId, 'han_sua');
    expect(
      activeCohortWithdrawalCrisis(GameState.fromJson(open.toJson()))?.girlId,
      'han_sua',
      reason: '저장을 다시 불러도 진행 중 위기가 유지되어야 한다',
    );

    final closed = withCrisis(
      const CohortWithdrawalCrisis(
        girlId: 'han_sua',
        openedDay: 10,
        respondedDay: 11,
        response: CohortWithdrawalResponse.persuade,
      ),
    );
    expect(activeCohortWithdrawalCrisis(closed), isNull);
  });

  test('the crisis never removes anyone from the ten', () {
    final state = _withReports(base, cohortWithdrawalStreakThreshold, {
      'han_sua': cohortWithdrawalLossThreshold - 1000,
    });
    // 결과표는 항상 10행이고 여자 동기 8명의 관계도 유지된다.
    for (final report in state.cohortInvestments.reports) {
      expect(report.rows, hasLength(10));
    }
    expect(state.cohortInvestments.accounts, hasLength(9));
    expect(cohortGirlProfiles, hasLength(8));
    expect(cohortGirlProfileById('han_sua'), isNotNull);
  });

  test('opening a crisis is idempotent and picks the candidate', () {
    final ready = _withReports(base, cohortWithdrawalStreakThreshold, {
      'han_sua': cohortWithdrawalLossThreshold - 1000,
    });
    expect(activeCohortWithdrawalCrisis(ready), isNull);

    final opened = openCohortWithdrawalCrisis(ready);
    final crisis = activeCohortWithdrawalCrisis(opened);
    expect(crisis, isNotNull);
    expect(crisis!.girlId, 'han_sua');
    expect(crisis.openedDay, ready.day);
    // 두 번 열어도 같은 위기가 유지된다.
    expect(
      activeCohortWithdrawalCrisis(
        openCohortWithdrawalCrisis(opened),
      )!.openedDay,
      crisis.openedDay,
    );
    // 후보가 없으면 아무것도 열지 않는다.
    expect(
      activeCohortWithdrawalCrisis(openCohortWithdrawalCrisis(base)),
      isNull,
    );
  });

  test('each response moves a different relationship axis', () {
    final opened = openCohortWithdrawalCrisis(
      _withReports(base, cohortWithdrawalStreakThreshold, {
        'han_sua': cohortWithdrawalLossThreshold - 1000,
      }),
    );

    final persuade = respondToCohortWithdrawal(
      opened,
      CohortWithdrawalResponse.persuade,
    );
    expect(persuade.success, isTrue);
    expect(persuade.trustDelta, greaterThan(0));
    expect(persuade.investmentRespectDelta, 0);

    final respect = respondToCohortWithdrawal(
      opened,
      CohortWithdrawalResponse.respectRight,
    );
    expect(respect.trustDelta, 0);
    expect(respect.investmentRespectDelta, greaterThan(0));

    final share = respondToCohortWithdrawal(
      opened,
      CohortWithdrawalResponse.shareLedger,
    );
    expect(share.trustDelta, greaterThan(0));
    expect(share.investmentRespectDelta, greaterThan(0));

    // 세 응답이 서로 다른 말을 돌려준다.
    final replies = <String>{persuade.reply, respect.reply, share.reply};
    expect(replies, hasLength(3));
    for (final reply in replies) {
      expect(reply, isNotEmpty);
    }
  });

  test('answering closes the crisis for good and survives a save', () {
    final opened = openCohortWithdrawalCrisis(
      _withReports(base, cohortWithdrawalStreakThreshold, {
        'han_sua': cohortWithdrawalLossThreshold - 1000,
      }),
    );
    final answered = respondToCohortWithdrawal(
      opened,
      CohortWithdrawalResponse.shareLedger,
    ).state;

    expect(activeCohortWithdrawalCrisis(answered), isNull);
    expect(cohortWithdrawalHistory(answered), contains('han_sua'));
    // 같은 인물의 위기는 다시 열리지 않는다.
    expect(cohortWithdrawalCandidate(answered), isNull);
    expect(
      activeCohortWithdrawalCrisis(openCohortWithdrawalCrisis(answered)),
      isNull,
    );

    final restored = GameState.fromJson(answered.toJson());
    expect(cohortWithdrawalHistory(restored), contains('han_sua'));
    expect(
      restored.relationships.progressFor('han_sua').investmentRespect,
      greaterThan(base.relationships.progressFor('han_sua').investmentRespect),
    );
    expect(GameState.schemaVersion, 26);
  });

  test('responding with no open crisis is rejected', () {
    final result = respondToCohortWithdrawal(
      base,
      CohortWithdrawalResponse.persuade,
    );
    expect(result.success, isFalse);
    expect(result.state, base);
  });
}
