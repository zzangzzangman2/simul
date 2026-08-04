import 'game_state.dart';
import 'relationship_state.dart';

/// 동기의 중단권 행사 위기다.
///
/// `DECIMAL_WORLD.md`의 핵심 장치는 거부권과 종료권인데 지금까지 대사에만 있었다.
/// 오래 잃은 동기가 그만두겠다고 말을 꺼내고, 플레이어가 며칠에 걸쳐 응답한다.
///
/// **열 명은 실제로 나가지 않는다.** 결과표는 항상 10행이어야 하고 여자 동기 8명의
/// 관계·데시멀톡 연결도 유지되어야 한다. 그래서 위기는 `남는 방식`이 갈리는 것으로
/// 끝난다. 프롤로그 5장에서 최종 선발 전 한 명이 차표를 택한 것과 달리, 이미 열 명이
/// 된 뒤에는 중단권이 `계속하는 이유를 다시 쓰는 권리`로 작동한다.
///
/// 위기 발생은 저장된 결과표에서 파생하므로 새 저장 필드가 필요 없다. 결과와 진행
/// 상태만 `storyFlags`에 남긴다.
const cohortWithdrawalLossThreshold = -12000;
const cohortWithdrawalStreakThreshold = 4;
const cohortWithdrawalWindowDays = 3;
const cohortWithdrawalFlag = 'cohortWithdrawalCrisis';
const cohortWithdrawalHistoryFlag = 'cohortWithdrawalHistory';
const cohortWithdrawalTrustGain = 4;
const cohortWithdrawalRespectGain = 3;

/// 위기에 응답하는 방식.
enum CohortWithdrawalResponse {
  /// 계속하자고 설득한다. 신뢰가 오르지만 그 애 방식을 바꾸라고 요구하지 않는다.
  persuade,

  /// 그만둘 권리를 인정하고 기다린다. 투자존중이 오른다.
  respectRight,

  /// 내 장부를 같이 보자고 제안한다. 신뢰와 투자존중이 함께 조금 오른다.
  shareLedger,
}

class CohortWithdrawalReason {
  const CohortWithdrawalReason({
    required this.girlId,
    required this.name,
    required this.opening,
    required this.persuadeReply,
    required this.respectReply,
    required this.shareReply,
  });

  final String girlId;
  final String name;

  /// 그 애가 먼저 꺼내는 말. 인물의 판단 출발점이 무너졌을 때 나오는 문장이다.
  final String opening;
  final String persuadeReply;
  final String respectReply;
  final String shareReply;

  String replyFor(CohortWithdrawalResponse response) => switch (response) {
    CohortWithdrawalResponse.persuade => persuadeReply,
    CohortWithdrawalResponse.respectRight => respectReply,
    CohortWithdrawalResponse.shareLedger => shareReply,
  };
}

const cohortWithdrawalReasons = <CohortWithdrawalReason>[
  CohortWithdrawalReason(
    girlId: 'kim_seoa',
    name: '김서아',
    opening: '내 공책이 계속 틀린 걸 적고 있어. 기록하는 사람이 기록을 못 믿으면 여기 있을 이유가 없잖아.',
    persuadeReply: '틀린 것도 기록이라는 말은… 생각해 볼게. 대신 내가 그만두겠다고 한 것도 적어 둘 거야.',
    respectReply: '기다려 준다고 해 줘서 고마워. 그만둘 권리가 있다는 걸 잊고 있었어.',
    shareReply: '네 장부를 같이 보면… 내 공책이 어디서 어긋났는지는 알 수 있겠네. 그건 해 볼게.',
  ),
  CohortWithdrawalReason(
    girlId: 'lee_jian',
    name: '이지안',
    opening: '고칠 수 없는 걸 계속 보고 있어. 나는 고쳐지는 것만 만지고 싶었는데.',
    persuadeReply: '더 있어 보라니까 있어 볼게. 근데 억지로 붙잡는 건 아니었으면 좋겠어.',
    respectReply: '언제 그만둬도 된다고 해서 오히려 조금 편해졌어. 며칠 더 볼게.',
    shareReply: '네 원장 열어 보자. 화면 말고 실제로 뭐가 어긋났는지 보면 손이 다시 움직일지도.',
  ),
  CohortWithdrawalReason(
    girlId: 'choi_iseo',
    name: '최이서',
    opening: '숫자 보는 게 점점 싫어져. 억지로 하면 결이 더 안 보여.',
    persuadeReply: '조금만 더. 대신 싫어지면 그때는 진짜로 말할게.',
    respectReply: '싫다고 말해도 되는 거였네. 그럼 조금 쉬었다 볼게.',
    shareReply: '같이 보면 좀 낫겠어. 네가 급하게 판단한 자리를 내가 짚어 줄게.',
  ),
  CohortWithdrawalReason(
    girlId: 'jung_arin',
    name: '정아린',
    opening: '순서를 다 정해도 결과가 안 따라와. 실행이 안 통하면 내 역할이 없는 거야.',
    persuadeReply: '알았어. 대신 다음 달에도 이러면 그때는 내가 안건을 올릴 거야.',
    respectReply: '그만둘 수 있다고 말해 준 사람이 너뿐이야. 그래서 조금 더 해 볼래.',
    shareReply: '네 장부에 매도 조건부터 같이 적자. 내 방식이 통하는지 네 계좌로 확인해 볼게.',
  ),
  CohortWithdrawalReason(
    girlId: 'park_haeun',
    name: '박하은',
    opening: '다들 괜찮은 척하는 걸 내가 제일 먼저 알아채. 그게 매일 반복되면 좀 지쳐.',
    persuadeReply: '내가 필요하다는 말은 고마운데, 필요해서 남는 건 좀 무섭기도 해.',
    respectReply: '괜찮은지 안 물어봐 줘서 오히려 편했어. 조금 더 있을게.',
    shareReply: '너 장부부터 같이 보자. 내가 남 걱정만 하다가 내 숫자를 안 봤어.',
  ),
  CohortWithdrawalReason(
    girlId: 'han_sua',
    name: '한수아',
    opening: '내가 먼저 말한 게 계속 틀렸어. 먼저 말하는 애가 계속 틀리면 아무도 안 듣게 되잖아.',
    persuadeReply: '들어 준다고 해서 남는 거 아니야. 그냥… 조금 더 해 볼래.',
    respectReply: '그만둬도 된다니까 갑자기 안 그만두고 싶어졌어. 이상하지.',
    shareReply: '내가 들은 얘기랑 네 장부를 맞춰 보자. 어디서 먼저 어긋났는지 보고 싶어.',
  ),
  CohortWithdrawalReason(
    girlId: 'oh_jiwoo',
    name: '오지우',
    opening: '반례만 던지고 정작 아무것도 안 걸었습니다. 구경꾼은 여기 있을 자격이 없죠.',
    persuadeReply: '남으라고 하시니 남겠습니다. 다만 다음엔 제 돈을 걸겠습니다.',
    respectReply: '나갈 수 있다고 해 주시니 오히려 도망 같아서 못 나가겠네요.',
    shareReply: '좋습니다. 제 반례를 당신 장부에 실제로 걸어 보죠. 틀리면 제 기록에도 남습니다.',
  ),
  CohortWithdrawalReason(
    girlId: 'yoon_chaea',
    name: '윤채아',
    opening: '구조는 맞는데 결과가 계속 틀려. 그러면 내가 뭘 믿어야 하는지 모르겠어.',
    persuadeReply: '조금 더 표본을 모아 볼게. 네 말이 위로라서가 아니라 표본이 부족해서.',
    respectReply: '그만둘 조건을 내가 정할 수 있다는 걸 확인했어. 그러면 아직은 아니야.',
    shareReply: '네 계좌로 검증해 보자. 내 구조가 틀렸는지 시장이 틀렸는지는 갈라야 해.',
  ),
];

CohortWithdrawalReason? cohortWithdrawalReasonFor(String girlId) {
  for (final reason in cohortWithdrawalReasons) {
    if (reason.girlId == girlId) return reason;
  }
  return null;
}

/// 오래 잃어 중단권을 떠올린 동기. 없으면 null이다.
///
/// 여자 동기 8명만 대상이다. 같은 인물의 위기는 캠페인 동안 한 번만 연다.
CohortWithdrawalReason? cohortWithdrawalCandidate(GameState state) {
  final reports = [...state.cohortInvestments.reports]
    ..sort((left, right) => right.day.compareTo(left.day));
  if (reports.length < cohortWithdrawalStreakThreshold) return null;
  final resolved = cohortWithdrawalHistory(state);

  final streak = <String, int>{};
  final open = <String, bool>{};
  for (final report in reports) {
    for (final row in report.rows) {
      if (row.isPlayer) continue;
      if (open[row.investorId] == false) continue;
      if (row.cumulativeProfitLoss <= cohortWithdrawalLossThreshold) {
        streak[row.investorId] = (streak[row.investorId] ?? 0) + 1;
      } else {
        open[row.investorId] = false;
      }
    }
  }

  // 가장 오래 버틴 쪽부터, 동률이면 인물 ID 순으로 고정해 결정론을 지킨다.
  final candidates =
      streak.entries
          .where(
            (entry) =>
                entry.value >= cohortWithdrawalStreakThreshold &&
                !resolved.contains(entry.key) &&
                cohortWithdrawalReasonFor(entry.key) != null &&
                cohortGirlProfileById(entry.key) != null,
          )
          .toList(growable: false)
        ..sort((left, right) {
          final byStreak = right.value.compareTo(left.value);
          return byStreak != 0 ? byStreak : left.key.compareTo(right.key);
        });
  if (candidates.isEmpty) return null;
  return cohortWithdrawalReasonFor(candidates.first.key);
}

/// 진행 중인 위기 상태. 열린 날과 응답 기한을 보관한다.
class CohortWithdrawalCrisis {
  const CohortWithdrawalCrisis({
    required this.girlId,
    required this.openedDay,
    this.respondedDay = 0,
    this.response,
  });

  final String girlId;
  final int openedDay;
  final int respondedDay;
  final CohortWithdrawalResponse? response;

  bool get isResolved => response != null;
  int get deadlineDay => openedDay + cohortWithdrawalWindowDays;
  bool expiredOn(int day) => !isResolved && day > deadlineDay;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'girlId': girlId,
    'openedDay': openedDay,
    'respondedDay': respondedDay,
    if (response != null) 'response': response!.name,
  };

  factory CohortWithdrawalCrisis.fromJson(Map<String, dynamic> json) =>
      CohortWithdrawalCrisis(
        girlId: json['girlId'] as String? ?? '',
        openedDay: ((json['openedDay'] as num?)?.toInt() ?? 0).clamp(
          0,
          0x7fffffff,
        ),
        respondedDay: ((json['respondedDay'] as num?)?.toInt() ?? 0).clamp(
          0,
          0x7fffffff,
        ),
        response: CohortWithdrawalResponse.values
            .where((value) => value.name == json['response'])
            .firstOrNull,
      );
}

CohortWithdrawalCrisis? activeCohortWithdrawalCrisis(GameState state) {
  final raw = state.story.storyFlags[cohortWithdrawalFlag];
  if (raw is! Map) return null;
  final crisis = CohortWithdrawalCrisis.fromJson(raw.cast<String, dynamic>());
  if (crisis.girlId.isEmpty || crisis.isResolved) return null;
  return crisis;
}

/// 위기를 끝낸 인물 목록. 같은 인물의 위기는 다시 열지 않는다.
List<String> cohortWithdrawalHistory(GameState state) =>
    ((state.story.storyFlags[cohortWithdrawalHistoryFlag] as List?) ??
            const <dynamic>[])
        .whereType<String>()
        .toList(growable: false);

GameState _withFlags(GameState state, Map<String, dynamic> patch) =>
    state.copyWith(
      story: state.story.copyWith(
        storyFlags: <String, dynamic>{...state.story.storyFlags, ...patch},
      ),
    );

/// 위기를 연다. 이미 진행 중이면 그대로 둔다.
GameState openCohortWithdrawalCrisis(GameState state) {
  if (activeCohortWithdrawalCrisis(state) != null) return state;
  final candidate = cohortWithdrawalCandidate(state);
  if (candidate == null) return state;
  return _withFlags(state, <String, dynamic>{
    cohortWithdrawalFlag: CohortWithdrawalCrisis(
      girlId: candidate.girlId,
      openedDay: state.day,
    ).toJson(),
  });
}

class CohortWithdrawalOutcome {
  const CohortWithdrawalOutcome({
    required this.state,
    required this.success,
    required this.message,
    this.reply = '',
    this.trustDelta = 0,
    this.investmentRespectDelta = 0,
  });

  final GameState state;
  final bool success;
  final String message;

  /// 그 애가 돌려준 말.
  final String reply;
  final int trustDelta;
  final int investmentRespectDelta;
}

/// 위기에 응답한다. 관계가 바뀌고 그 인물의 위기는 캠페인 동안 다시 열리지 않는다.
///
/// 아무도 명단에서 빠지지 않는다. 바뀌는 것은 `남는 방식`이다.
CohortWithdrawalOutcome respondToCohortWithdrawal(
  GameState state,
  CohortWithdrawalResponse response,
) {
  final crisis = activeCohortWithdrawalCrisis(state);
  if (crisis == null) {
    return CohortWithdrawalOutcome(
      state: state,
      success: false,
      message: '지금은 응답할 이야기가 없습니다.',
    );
  }
  final reason = cohortWithdrawalReasonFor(crisis.girlId);
  if (reason == null) {
    return CohortWithdrawalOutcome(
      state: state,
      success: false,
      message: '데시멀 동기가 아닙니다.',
    );
  }

  // 설득은 신뢰를, 권리 인정은 투자존중을, 장부 공유는 둘을 조금씩 올린다.
  final (trustGain, respectGain) = switch (response) {
    CohortWithdrawalResponse.persuade => (cohortWithdrawalTrustGain, 0),
    CohortWithdrawalResponse.respectRight => (0, cohortWithdrawalRespectGain),
    CohortWithdrawalResponse.shareLedger => (
      cohortWithdrawalTrustGain - 2,
      cohortWithdrawalRespectGain - 1,
    ),
  };

  var relationships = state.relationships;
  var trustDelta = 0;
  var respectDelta = 0;
  final progress = relationships.progressFor(crisis.girlId);
  final nextTrust = (progress.trust + trustGain)
      .clamp(relationshipDimensionMin, relationshipDimensionMax)
      .toInt();
  final nextRespect = (progress.investmentRespect + respectGain)
      .clamp(relationshipDimensionMin, relationshipDimensionMax)
      .toInt();
  trustDelta = nextTrust - progress.trust;
  respectDelta = nextRespect - progress.investmentRespect;
  relationships = relationships.copyWith(
    girls: <String, GirlRelationshipProgress>{
      ...relationships.girls,
      crisis.girlId: progress.copyWith(
        trust: nextTrust,
        investmentRespect: nextRespect,
        lastInteractionDay: state.day,
      ),
    },
  );

  final resolved = <String>{
    ...cohortWithdrawalHistory(state),
    crisis.girlId,
  }.toList(growable: false);

  return CohortWithdrawalOutcome(
    state: _withFlags(state.copyWith(relationships: relationships), {
      cohortWithdrawalFlag: CohortWithdrawalCrisis(
        girlId: crisis.girlId,
        openedDay: crisis.openedDay,
        respondedDay: state.day,
        response: response,
      ).toJson(),
      cohortWithdrawalHistoryFlag: resolved,
    }),
    success: true,
    message: '${reason.name}와 이야기를 마쳤습니다.',
    reply: reason.replyFor(response),
    trustDelta: trustDelta,
    investmentRespectDelta: respectDelta,
  );
}
